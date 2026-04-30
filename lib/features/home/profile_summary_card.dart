import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/permission_service.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/spacing.dart';
import '../session_log/firebase_service.dart';
import '../../ui_system/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../passport/shared_profile_edit_sheet.dart';
import 'quick_surfer_edit_sheet.dart';
import 'package:smart_surf/models/surf_dashboard_data.dart';

class ProfileSummaryCard extends StatefulWidget {
  final bool isSpanish;
  final String displayName;
  final String? profilePhotoPath;
  final String stance;
  final String height;
  final String weight;
  final String location;
  final String age;
  final String surferSummary;
  
  final bool stanceVisibleToCoach;
  final bool stanceVisibleOnDashboard;
  final bool heightVisibleToCoach;
  final bool heightVisibleOnDashboard;
  final bool weightVisibleToCoach;
  final bool weightVisibleOnDashboard;
  final bool locationVisibleToCoach;
  final bool locationVisibleOnDashboard;
  final bool ageVisibleToCoach;
  final bool ageVisibleOnDashboard;

  // New fields for canonical form
  final String levelEnTitle;
  final String levelEnDesc;
  final String comfortEn;
  final String boardEn;
  final List<String> focusEn;
  final String units;

  final Function({
    required String displayName,
    required String? profilePhotoPath,
    required String stance,
    required String height,
    required String weight,
    required String location,
    required String age,
    required String surferSummary,
    required bool stanceVisibleToCoach,
    required bool stanceVisibleOnDashboard,
    required bool heightVisibleToCoach,
    required bool heightVisibleOnDashboard,
    required bool weightVisibleToCoach,
    required bool weightVisibleOnDashboard,
    required bool locationVisibleToCoach,
    required bool locationVisibleOnDashboard,
    required bool ageVisibleToCoach,
    required bool ageVisibleOnDashboard,
    required String levelEnTitle,
    required String levelEnDesc,
    required String comfortEn,
    required String boardEn,
    required List<String> focusEn,
  }) onUpdate;

  const ProfileSummaryCard({
    super.key,
    required this.isSpanish,
    required this.displayName,
    this.profilePhotoPath,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.age,
    required this.surferSummary,
    required this.stanceVisibleToCoach,
    required this.stanceVisibleOnDashboard,
    required this.heightVisibleToCoach,
    required this.heightVisibleOnDashboard,
    required this.weightVisibleToCoach,
    required this.weightVisibleOnDashboard,
    required this.locationVisibleToCoach,
    required this.locationVisibleOnDashboard,
    required this.ageVisibleToCoach,
    required this.ageVisibleOnDashboard,
    required this.levelEnTitle,
    required this.levelEnDesc,
    required this.comfortEn,
    required this.boardEn,
    required this.focusEn,
    required this.units,
    required this.onUpdate,
  });

  @override
  State<ProfileSummaryCard> createState() => ProfileSummaryCardState();
}

class ProfileSummaryCardState extends State<ProfileSummaryCard> {
  String _t(String en, String es) => widget.isSpanish ? es : en;

  String _debugStatus = "Ready";

  Future<void> _pickImage() async {
    // 1. Permission Check
    final picker = ImagePicker();
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(_t("Choose Photo", "Elegir foto")),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(_t("Take Photo", "Tomar foto")),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    // Explicitly check permissions before invoking picker to prevent iPad crashes
    final result = await PermissionService().handleImageSourcePermission(source);
    
    if (result == PermissionResult.granted || result == PermissionResult.limited) {
      if (result == PermissionResult.limited && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_t(
              "Photo library access is limited. You can manage permitted photos in iOS Settings.",
              "El acceso a la biblioteca está limitado. Puedes gestionar las fotos permitidas en los Ajustes de iOS."
            )),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      // Proceed to picker
    } else {
      if (mounted) {
        final isCamera = source == ImageSource.camera;
        String title = isCamera ? _t("Camera Permission", "Permiso de Cámara") : _t("Photos Permission", "Permiso de Fotos");
        
        String message = "";
        if (result == PermissionResult.permanentlyDenied) {
          message = isCamera
            ? _t("Camera access is permanently disabled. Please enable it in Settings to take a profile photo.", "El acceso a la cámara está desactivado permanentemente. Por favor, actívalo en Ajustes para tomar una foto.")
            : _t("Photo library access is permanently disabled. Please enable it in Settings to choose a photo.", "El acceso a la biblioteca está desactivado permanentemente. Por favor, actívalo en Ajustes para elegir una foto.");
        } else {
          message = isCamera
            ? _t("Camera access is required to take a profile photo.", "Se requiere acceso a la cámara para tomar una foto de perfil.")
            : _t("Photo library access is required to choose a profile photo.", "Se requiere acceso a la biblioteca para elegir una foto de perfil.");
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
              if (result == PermissionResult.permanentlyDenied)
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    openAppSettings();
                  },
                  child: Text(_t("Settings", "Ajustes")),
                ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Interaction
    try {
      setState(() => _debugStatus = "Picker: Source $source selected.");
      debugPrint("Profile: Picker starting for source: $source");
      
      final picked = await picker.pickImage(
        source: source, 
        maxWidth: 800,
        imageQuality: 80,
      );

      if (picked != null) {
        setState(() => _debugStatus = "Picker: Image selected (${picked.name}).");
        final bytesCount = kIsWeb ? (await picked.readAsBytes()).length : -1;
        debugPrint("Profile: Image picked. Path: ${picked.path}, Name: ${picked.name}, Mime: ${picked.mimeType}, Size: $bytesCount bytes (web)");
        setState(() => _debugStatus = "Uploading ${bytesCount > 0 ? bytesCount : ''} bytes...");
        
        String? pathToSave;
        Uint8List? bytes;
        if (kIsWeb) {
          setState(() => _debugStatus = "Web: Reading file bytes...");
          bytes = await picked.readAsBytes();
          setState(() => _debugStatus = "Web: Bytes read (${bytes?.length}). Initializing Firebase Upload...");
        }

        debugPrint("Profile: Calling FirebaseService().uploadMedia... UID: ${FirebaseService().currentUid}");
        final fbResult = await FirebaseService().uploadMedia(
            localPath: picked.path,
            isProfile: true,
            isVideo: false,
            webBytes: bytes,
        );
        
        if (fbResult != null && fbResult.success) {
            debugPrint("Profile: Firebase upload SUCCESS. URL: ${fbResult.url}, StoragePath: ${fbResult.path}");
            setState(() => _debugStatus = "Syncing Firestore Profile...");
            
            debugPrint("Profile: Calling syncProfileToFirestore...");
            await FirebaseService().syncProfileToFirestore(
                photoUrl: fbResult.url!,
                storagePath: fbResult.path!,
            );
            
            debugPrint("Profile: syncProfileToFirestore returned. Calling _callUpdate with stable URL.");
            setState(() => _debugStatus = "Profile Photo Saved!");
            pathToSave = fbResult.url;
            _callUpdate(profilePhotoPath: pathToSave);
        } else {
            final errorMsg = fbResult?.errorCode ?? "unknown";
            debugPrint("Profile ERROR: Firebase upload failed. Code: $errorMsg");
            setState(() => _debugStatus = "Error: $errorMsg (Path: ${fbResult?.path ?? 'evaluating...'})");
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_t("Upload failed:", "Error al subir:") + " $errorMsg")),
              );
            }
        }
      } else {
        debugPrint("Profile: Picker dismissed or failed.");
        setState(() => _debugStatus = "Picker: No image selected.");
      }
    } catch (e) {
      debugPrint("Profile: Crash safety caught error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t("Could not open camera/gallery: ", "No se pudo abrir la cámara/galería: ") + e.toString())),
        );
      }
    }
  }

  void _callUpdate({
    String? displayName,
    String? profilePhotoPath,
    String? stance,
    String? height,
    String? weight,
    String? location,
    String? age,
    String? surferSummary,
    bool? stanceVisibleToCoach,
    bool? stanceVisibleOnDashboard,
    bool? heightVisibleToCoach,
    bool? heightVisibleOnDashboard,
    bool? weightVisibleToCoach,
    bool? weightVisibleOnDashboard,
    bool? locationVisibleToCoach,
    bool? locationVisibleOnDashboard,
    bool? ageVisibleToCoach,
    bool? ageVisibleOnDashboard,
    String? levelEnTitle,
    String? levelEnDesc,
    String? comfortEn,
    String? boardEn,
    List<String>? focusEn,
  }) {
    widget.onUpdate(
      displayName: displayName ?? widget.displayName,
      profilePhotoPath: profilePhotoPath ?? widget.profilePhotoPath,
      stance: stance ?? widget.stance,
      height: height ?? widget.height,
      weight: weight ?? widget.weight,
      location: location ?? widget.location,
      age: age ?? widget.age,
      surferSummary: surferSummary ?? widget.surferSummary,
      stanceVisibleToCoach: stanceVisibleToCoach ?? widget.stanceVisibleToCoach,
      stanceVisibleOnDashboard: stanceVisibleOnDashboard ?? widget.stanceVisibleOnDashboard,
      heightVisibleToCoach: heightVisibleToCoach ?? widget.heightVisibleToCoach,
      heightVisibleOnDashboard: heightVisibleOnDashboard ?? widget.heightVisibleOnDashboard,
      weightVisibleToCoach: weightVisibleToCoach ?? widget.weightVisibleToCoach,
      weightVisibleOnDashboard: weightVisibleOnDashboard ?? widget.weightVisibleOnDashboard,
      locationVisibleToCoach: locationVisibleToCoach ?? widget.locationVisibleToCoach,
      locationVisibleOnDashboard: locationVisibleOnDashboard ?? widget.locationVisibleOnDashboard,
      ageVisibleToCoach: ageVisibleToCoach ?? widget.ageVisibleToCoach,
      ageVisibleOnDashboard: ageVisibleOnDashboard ?? widget.ageVisibleOnDashboard,
      levelEnTitle: levelEnTitle ?? widget.levelEnTitle,
      levelEnDesc: levelEnDesc ?? widget.levelEnDesc,
      comfortEn: comfortEn ?? widget.comfortEn,
      boardEn: boardEn ?? widget.boardEn,
      focusEn: focusEn ?? widget.focusEn,
    );
  }

  void showQuickEdit() {
    QuickSurferEditSheet.show(
      context,
      isSpanish: widget.isSpanish,
      displayName: widget.displayName,
      profilePhotoPath: widget.profilePhotoPath,
      onUpdate: ({required displayName, required profilePhotoPath}) {
        _callUpdate(
          displayName: displayName,
          profilePhotoPath: profilePhotoPath,
        );
      },
    );
  }



  @override
    Widget build(BuildContext context) {
    debugPrint("Profile Rendering: Path: ${widget.profilePhotoPath}");
    final bool isVideoProfile = widget.profilePhotoPath?.toLowerCase().endsWith('.mp4') == true ||
                                widget.profilePhotoPath?.toLowerCase().endsWith('.mov') == true ||
                                widget.profilePhotoPath?.startsWith('video:') == true;

    final bool isStable = FirebaseService.isStableUrl(widget.profilePhotoPath);
    debugPrint("Profile Rendering: isStable: $isStable");

    final ImageProvider? profileImage = (isStable && !isVideoProfile)
        ? NetworkImage(widget.profilePhotoPath!)
        : null;

    return InkWell(
      onTap: showQuickEdit,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16), // AppSpacing.md fallback
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.surfaceVariant,
                backgroundImage: profileImage,
                onBackgroundImageError: profileImage != null
                    ? (exception, stackTrace) => debugPrint("Profile photo error: $exception")
                    : null,
                child: profileImage == null
                    ? const Icon(Icons.person, size: 32, color: AppTheme.primary)
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: GestureDetector(
                  onTap: showQuickEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.displayName.isEmpty ? _t("Surfer", "Surfer") : widget.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: SurfDashboardData(
                    levelTitle: widget.levelEnTitle,
                    levelDesc: widget.levelEnDesc,
                    comfortZone: widget.comfortEn,
                    board: widget.boardEn,
                    focusSkills: widget.focusEn,
                    age: widget.age,
                    displayName: widget.displayName,
                    profilePhotoPath: widget.profilePhotoPath,
                    surferSummary: widget.surferSummary,
                    stance: widget.stance,
                    height: widget.height,
                    weight: widget.weight,
                    location: widget.location,
                    stanceVisibleToCoach: widget.stanceVisibleToCoach,
                    stanceVisibleOnDashboard: widget.stanceVisibleOnDashboard,
                    heightVisibleToCoach: widget.heightVisibleToCoach,
                    heightVisibleOnDashboard: widget.heightVisibleOnDashboard,
                    weightVisibleToCoach: widget.weightVisibleToCoach,
                    weightVisibleOnDashboard: widget.weightVisibleOnDashboard,
                    locationVisibleToCoach: widget.locationVisibleToCoach,
                    locationVisibleOnDashboard: widget.locationVisibleOnDashboard,
                    ageVisibleToCoach: widget.ageVisibleToCoach,
                    ageVisibleOnDashboard: widget.ageVisibleOnDashboard,
                  ).getVisibleProfileFields(widget.isSpanish).map((field) {
                    IconData icon = Icons.info_outline;
                    switch (field['label']?.toLowerCase()) {
                      case 'stance': 
                      case 'posición':
                        icon = Icons.directions_run_rounded; break;
                      case 'location': 
                      case 'ubicación':
                      case 'local':
                        icon = Icons.location_on_outlined; break;
                      case 'height': 
                      case 'altura':
                        icon = Icons.straighten_rounded; break;
                      case 'weight': 
                      case 'peso':
                        icon = Icons.monitor_weight_outlined; break;
                      case 'age': 
                      case 'edad':
                        icon = Icons.cake_outlined; break;
                    }
                    return _miniTag(icon, field['value'] ?? '');
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
      ),
    );
  }

  Widget _miniTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.9)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


