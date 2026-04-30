import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../storage/app_storage.dart';
import '../../models/surf_dashboard_data.dart';
import 'session_log_entry.dart';
import '../../firebase_options.dart';

class RecentLoginRequiredException implements Exception {
  final String message;
  RecentLoginRequiredException([this.message = 'Recent login required for this operation.']);
  @override
  String toString() => message;
}

/// Centralized service to handle Firebase operations
/// specifically tailored to sync Profile and Session Media
/// via HTTPS Storage links into the local AppStorage architecture.
class FirebaseUploadResult {
  final String? url;
  final String? path;
  final String? errorCode;
  final String? errorMessage;
  final bool success;

  FirebaseUploadResult({
    this.url,
    this.path,
    this.errorCode,
    this.errorMessage,
    required this.success,
  });

  factory FirebaseUploadResult.success(String url, String path) => 
      FirebaseUploadResult(url: url, path: path, success: true);

  factory FirebaseUploadResult.error(String code, String message) => 
      FirebaseUploadResult(errorCode: code, errorMessage: message, success: false);
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;
  String? _initError;
  Completer<void>? _initCompleter;
  
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  String? get currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Call this inside main() to guarantee Firebase is ready and the user has a stable UID.
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<void>();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      _initialized = true;
      await analytics.logEvent(name: 'app_initialized');
      _initCompleter!.complete();
    } catch (e) {
      final errorText = e.toString();

      if (errorText.contains('duplicate-app') ||
          errorText.contains('already exists')) {
        _initialized = true;
        _initCompleter!.complete();
        return;
      }

      _initCompleter!.completeError(e);
      rethrow;
    }
  }

  /// Ensures Firebase is ready before any operation
  Future<void> _ensureReady() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Uploads media bytes to Firebase Storage and returns the permanent HTTPS Download URL 
  /// alongside the precise Storage Path for future modifications.
  Future<FirebaseUploadResult?> uploadMedia({
    required String localPath,
    required bool isProfile,
    required bool isVideo,
    String? sessionId,
    Uint8List? webBytes,
  }) async {
    await _ensureReady();

    final uid = currentUid;
    if (uid == null) {
      return FirebaseUploadResult.error(
        'auth-failed',
        'No authenticated user (UID is null).',
      );
    }

    if (!isProfile && (sessionId == null || sessionId.isEmpty)) {
      return FirebaseUploadResult.error(
        'missing-session-id',
        'Session media upload requires a real sessionId.',
      );
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final String extension = isVideo ? 'mp4' : 'jpg';
      final String storageLocation = isProfile
          ? 'users/$uid/profile/profile.$extension'
          : 'users/$uid/sessions/$sessionId/${timestamp}_media.$extension';

      debugPrint('DEBUG STORAGE UPLOAD');
      debugPrint('- uid: $uid');
      debugPrint('- storagePath: $storageLocation');
      debugPrint('- isProfile: $isProfile');
      debugPrint('- isVideo: $isVideo');
      debugPrint('- localPath: $localPath');

      final ref = FirebaseStorage.instance.ref().child(storageLocation);

      final metadata = SettableMetadata(
        contentType: isVideo ? 'video/mp4' : 'image/jpeg',
        customMetadata: {
          'uid': uid,
          'sessionId': sessionId ?? '',
          'source': kIsWeb ? 'web_debug_upload' : 'mobile_debug_upload',
        },
      );

      late final TaskSnapshot snapshot;

      if (kIsWeb && webBytes != null) {
        snapshot = await ref.putData(webBytes, metadata);
      } else {
        final file = File(localPath);
        final exists = await file.exists();
        if (!exists) {
          return FirebaseUploadResult.error(
            'file-not-found',
            'Local file not found: $localPath',
          );
        }

        snapshot = await ref.putFile(file, metadata);
      }

      debugPrint('Firebase upload complete');
      debugPrint('- fullPath: ${snapshot.ref.fullPath}');
      debugPrint('- bucket: ${snapshot.ref.bucket}');
      debugPrint('- bytesTransferred: ${snapshot.bytesTransferred}');

      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Firebase download URL: $downloadUrl');

      return FirebaseUploadResult.success(downloadUrl, snapshot.ref.fullPath);
    } on FirebaseException catch (e) {
      debugPrint('Firebase ERROR [${e.code}]: ${e.message}');
      return FirebaseUploadResult.error(
        e.code,
        e.message ?? 'Unknown Firebase error',
      );
    } catch (e) {
      debugPrint('Failed to upload media to Firebase: $e');
      return FirebaseUploadResult.error('unknown', e.toString());
    }
  }

  static bool isStableUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    // Must be a valid HTTPS URL and originate from Firebase Storage
    return url.startsWith('https://firebasestorage.googleapis.com') || 
           url.contains('googleapi') || 
           (url.startsWith('http') && !url.contains('localhost') && !url.contains('127.0.0.1'));
  }

  /// Updates the root user document with full profile data.
  Future<void> saveFullProfile(SurfDashboardData data) async {
    await _ensureReady();
    if (currentUid == null) return;

    try {
      final docPath = "users/$currentUid";
      debugPrint("Firebase: SAVING full profile to Firestore doc: $docPath...");
      
      Map<String, dynamic> firestoreData = data.toJson();
      firestoreData['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance.collection('users').doc(currentUid).set(
        firestoreData, 
        SetOptions(merge: true)
      ).timeout(const Duration(seconds: 10));
      
      debugPrint("Firebase: Full profile save SUCCESS for $docPath");
    } catch (e) {
      debugPrint("Firebase ERROR saving full profile to Firestore: $e");
    }
  }

  /// Legacy helper for just the photo
  Future<void> syncProfileToFirestore({
    required String photoUrl,
    required String storagePath,
  }) async {
    await _ensureReady();
    if (currentUid == null) return;
    
    if (!FirebaseService.isStableUrl(photoUrl)) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).set({
        'profilePhotoUrl': photoUrl,
        'profilePhotoStoragePath': storagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Firebase ERROR syncing profile photo: $e");
    }
  }
  
  /// Pushes the full session object to Firestore
  Future<void> saveSessionToFirestore(SessionLogEntry entry) async {
    await _ensureReady();
    final uid = currentUid;
    if (uid == null) {
      debugPrint("Firebase: ABORTING session save. No authenticated user (UID is null).");
      return;
    }

    final docPath = "users/$uid/sessions/${entry.id}";
    debugPrint("----------------------------");
    debugPrint("FIRESTORE SESSION SAVE START");
    debugPrint("Path: $docPath");
    
    try {
      final json = entry.toJson();
      json['updatedAt'] = FieldValue.serverTimestamp();
      
      debugPrint("Payload: $json");

      await FirebaseFirestore.instance.doc(docPath).set(
        json, 
        SetOptions(merge: true)
      ).timeout(const Duration(seconds: 30));

      debugPrint("FIRESTORE SESSION SAVE SUCCESS");
      debugPrint("----------------------------");
    } on FirebaseException catch (e) {
      debugPrint("FIRESTORE SESSION SAVE ERROR [${e.code}]: ${e.message}");
      debugPrint("----------------------------");
      rethrow;
    } catch (e) {
      debugPrint("FIRESTORE SESSION SAVE FAILED: $e");
      debugPrint("----------------------------");
      rethrow;
    }
  }

  /// Deletes a session document from Firestore
  Future<void> deleteSessionFromFirestore(String sessionId) async {
    await _ensureReady();
    final uid = currentUid;
    if (uid == null) return;

    final docPath = "users/$uid/sessions/$sessionId";
    debugPrint("FIRESTORE SESSION DELETE START: $docPath");
    
    try {
      await FirebaseFirestore.instance.doc(docPath).delete()
          .timeout(const Duration(seconds: 15));
      debugPrint("FIRESTORE SESSION DELETE SUCCESS");
    } catch (e) {
      debugPrint("FIRESTORE SESSION DELETE ERROR: $e");
    }
  }

  /// Pushes session media metadata straight to Firestore.
  Future<void> syncSessionMediaToFirestore({
    required String sessionId,
    required String photoUrl,
    required String storagePath,
    required bool isVideo,
  }) async {
    await _ensureReady();
    final uid = currentUid;
    if (uid == null) return;

    if (!FirebaseService.isStableUrl(photoUrl)) {
      debugPrint("Firebase GUARDRAIL: Rejected transient session URL: $photoUrl");
      return;
    }

    try {
      final docId = sessionId;
      final writeData = {
        'mediaUrl': photoUrl,
        'mediaStoragePath': storagePath,
        'mediaType': isVideo ? 'video' : 'photo',
        'mediaContentType': isVideo ? 'video/mp4' : 'image/jpeg',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      final docPath = "users/$uid/sessions/$docId";
      debugPrint("FIRESTORE MEDIA SYNC START: $docPath");
      
      await FirebaseFirestore.instance.doc(docPath).set(
        writeData, 
        SetOptions(merge: true)
      ).timeout(const Duration(seconds: 30));
      
      debugPrint("FIRESTORE MEDIA SYNC SUCCESS");
    } catch (e) {
      debugPrint("Firebase ERROR syncing session media: $e");
      rethrow;
    }
  }

  /// Downloads the master HTTPS media mappings and FULL profile from Firestore
  Future<AppStorageData> hydrateLocalsFromFirestore(AppStorageData localData) async {
    await _ensureReady();
    if (currentUid == null) return localData;
    
    SurfDashboardData hydratedProgress = localData.progress;
    List<SessionLogEntry> hydratedSessions = List.from(localData.sessions);

    try {
      // 1. Hydrate Full Profile from users/{uid}
      debugPrint("Firebase: Attempting to hydrate full profile for $currentUid");
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          debugPrint("Firebase: Firestore users/$currentUid found. Hydrating all fields.");
          
          // Merge Firestore fields into local progress
          hydratedProgress = SurfDashboardData(
            levelTitle: data['levelTitle'] as String? ?? hydratedProgress.levelTitle,
            levelDesc: data['levelDesc'] as String? ?? hydratedProgress.levelDesc,
            comfortZone: data['comfortZone'] as String? ?? hydratedProgress.comfortZone,
            board: data['board'] as String? ?? hydratedProgress.board,
            focusSkills: (data['focusSkills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? hydratedProgress.focusSkills,
            age: data['age'] as String? ?? hydratedProgress.age,
            displayName: data['displayName'] as String? ?? hydratedProgress.displayName,
            profilePhotoPath: data['profilePhotoUrl'] as String? ?? data['profilePhotoPath'] as String? ?? hydratedProgress.profilePhotoPath,
            stance: data['stance'] as String? ?? hydratedProgress.stance,
            height: data['height'] as String? ?? hydratedProgress.height,
            weight: data['weight'] as String? ?? hydratedProgress.weight,
            location: data['location'] as String? ?? hydratedProgress.location,
            surferSummary: data['surferSummary'] as String? ?? hydratedProgress.surferSummary,
            stanceVisibleToCoach: data['stanceVisibleToCoach'] as bool? ?? hydratedProgress.stanceVisibleToCoach,
            stanceVisibleOnDashboard: data['stanceVisibleOnDashboard'] as bool? ?? hydratedProgress.stanceVisibleOnDashboard,
            heightVisibleToCoach: data['heightVisibleToCoach'] as bool? ?? hydratedProgress.heightVisibleToCoach,
            heightVisibleOnDashboard: data['heightVisibleOnDashboard'] as bool? ?? hydratedProgress.heightVisibleOnDashboard,
            weightVisibleToCoach: data['weightVisibleToCoach'] as bool? ?? hydratedProgress.weightVisibleToCoach,
            weightVisibleOnDashboard: data['weightVisibleOnDashboard'] as bool? ?? hydratedProgress.weightVisibleOnDashboard,
            locationVisibleToCoach: data['locationVisibleToCoach'] as bool? ?? hydratedProgress.locationVisibleToCoach,
            locationVisibleOnDashboard: data['locationVisibleOnDashboard'] as bool? ?? hydratedProgress.locationVisibleOnDashboard,
            latestMediaPath: data['latestMediaPath'] as String? ?? hydratedProgress.latestMediaPath,
            latestMediaType: data['latestMediaType'] as String? ?? hydratedProgress.latestMediaType,
            ageVisibleToCoach: data['ageVisibleToCoach'] as bool? ?? hydratedProgress.ageVisibleToCoach,
            ageVisibleOnDashboard: data['ageVisibleOnDashboard'] as bool? ?? hydratedProgress.ageVisibleOnDashboard,
            email: data['email'] as String? ?? hydratedProgress.email,
          );
        }
      } else {
        debugPrint("Firebase: No Firestore record for $currentUid. Keeping local state as is.");
        // If this is a brand new anonymous user, main.dart will call _clearProfileState() 
        // during the "Skip for now" onboarding flow to clear any stale disk cache.
      }
      
      // 2. Hydrate Session Entries
      final sessionsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .collection('sessions')
          .get();
          
      for (var doc in sessionsSnap.docs) {
        final docId = doc.id;
        final data = doc.data();
        final mediaUrl = data['mediaUrl'] as String?;
        final mediaType = data['mediaType'] as String?;
        
        if (FirebaseService.isStableUrl(mediaUrl)) {
           final cacheIndex = hydratedSessions.indexWhere((s) => s.id == docId);
           if (cacheIndex != -1) {
              final cached = hydratedSessions[cacheIndex];
              hydratedSessions[cacheIndex] = cached.copyWith(
                  mediaPath: mediaUrl,
                  mediaType: mediaType ?? cached.mediaType,
              );
              
              if (hydratedProgress.latestMediaPath != null && 
                  (hydratedProgress.latestMediaPath == cached.mediaPath || 
                   !FirebaseService.isStableUrl(hydratedProgress.latestMediaPath))) {
                   hydratedProgress = hydratedProgress.copyWith(
                        latestMediaPath: mediaUrl,
                        latestMediaType: mediaType ?? hydratedProgress.latestMediaType,
                   );
              }
           }
        }
      }
    } catch (e) {
      debugPrint("Failed querying Firestore for full hydration: $e");
      return localData; 
    }

    return AppStorageData(
      settings: localData.settings,
      progress: hydratedProgress,
      sessions: hydratedSessions,
      spots: localData.spots,
      reflections: localData.reflections,
      aiAnalyses: localData.aiAnalyses,
    );
  }

  /// Centralized logic to log MVP analytics events
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _ensureReady();
    try {
      await analytics.logEvent(name: name, parameters: parameters?.cast<String, Object>());
      debugPrint("Analytics: Logged event '$name' with params: $parameters");
    } catch (e) {
      debugPrint("Analytics ERROR: Failed to log event '$name': $e");
    }
  }

  /// Apple Requirement: Full Account Deletion
  Future<void> deleteUserAccount() async {
    await _ensureReady();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (user == null || uid == null) return;

    try {
      debugPrint("Firebase: INITIATING account deletion for $uid");

      // 1. Delete Firestore Data (Subcollections first if possible, though deleting doc is primary)
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      
      // Delete sessions
      final sessions = await userRef.collection('sessions').get();
      for (var doc in sessions.docs) {
        await doc.reference.delete();
      }

      // Delete ai_analyses
      final analyses = await userRef.collection('ai_analyses').get();
      for (var doc in analyses.docs) {
        await doc.reference.delete();
      }

      // Delete spots
      final spots = await userRef.collection('spots').get();
      for (var doc in spots.docs) {
        await doc.reference.delete();
      }

      // Delete main user document
      await userRef.delete();
      debugPrint("Firebase: Firestore data deleted for $uid");

      // 2. Delete Profile Photo from Storage (Best effort)
      try {
        final profileRef = FirebaseStorage.instance.ref().child('users/$uid/profile/profile.jpg');
        await profileRef.delete();
      } catch (_) {}
      try {
        final profileRefPng = FirebaseStorage.instance.ref().child('users/$uid/profile/profile.png');
        await profileRefPng.delete();
      } catch (_) {}

      // 3. Delete Firebase Auth User
      // This may throw logic-specific errors like 'requires-recent-login'
      await user.delete();
      debugPrint("Firebase: Auth user deleted for $uid. Flow complete.");

    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase DELETE Auth Error [${e.code}]: ${e.message}");
      if (e.code == 'requires-recent-login') {
         throw RecentLoginRequiredException();
      }
      rethrow;
    } catch (e) {
      debugPrint("Firebase DELETE ERROR: $e");
      rethrow;
    }
  }

  /// Re-authenticates the current user using the provided credential.
  Future<void> reauthenticate(AuthCredential credential) async {
    await _ensureReady();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'No user signed in.';

    try {
      debugPrint("Firebase: RE-AUTHENTICATING user...");
      await user.reauthenticateWithCredential(credential);
      debugPrint("Firebase: Re-authentication SUCCESS.");
    } catch (e) {
      debugPrint("Firebase: Re-authentication FAILED: $e");
      rethrow;
    }
  }
}
