import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../storage/app_storage.dart';
import '../../models/surf_dashboard_data.dart';
import 'session_log_entry.dart';
import '../../firebase_options.dart';

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
      
      // Rename profilePhotoPath to profilePhotoUrl for Firestore consistency if needed, 
      // but let's stick to the json mapping or keep it explicit.
      // Current model uses 'profilePhotoPath' in toJson.
      
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
  
  /// Pushes session media metadata straight to Firestore.
  Future<void> syncSessionMediaToFirestore({
    required String sessionId,
    required String photoUrl,
    required String storagePath,
    required bool isVideo,
  }) async {
    await _ensureReady();
    if (currentUid == null) return;

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
      debugPrint("FIRESTORE WRITE START...");
      await FirebaseFirestore.instance.collection('users').doc(currentUid).collection('sessions').doc(docId).set(
        writeData, 
        SetOptions(merge: true)
      ).timeout(const Duration(seconds: 30));
      debugPrint("Firebase: Session media sync SUCCESS");
      debugPrint("FIRESTORE WRITE SUCCESS");
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
          );
        }
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
}
