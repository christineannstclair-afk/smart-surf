import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../ui_system/app_card.dart';
import '../../ui_system/spacing.dart';
import '../session_log/firebase_service.dart';
import '../../ui_system/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
    required this.onUpdate,
  });

  @override
  State<ProfileSummaryCard> createState() => _ProfileSummaryCardState();
}

class _ProfileSummaryCardState extends State<ProfileSummaryCard> {
  String _t(String en, String es) => widget.isSpanish ? es : en;

  String _debugStatus = "Ready";

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
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

    if (source != null) {
      setState(() => _debugStatus = "Picker: Source $source selected.");
      debugPrint("Profile: Picker starting for source: $source");
      final picked = await picker.pickImage(source: source, maxWidth: 800);
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
    );
  }

  void _showEditModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ProfileEditSheet(
        isSpanish: widget.isSpanish,
        displayName: widget.displayName,
        stance: widget.stance,
        height: widget.height,
        weight: widget.weight,
        location: widget.location,
        age: widget.age,
        surferSummary: widget.surferSummary,
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
        onUpdate: _callUpdate,
      ),
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
      onTap: _showEditModal,
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
                  onTap: _pickImage,
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
                  children: [
                    if (widget.stanceVisibleOnDashboard && widget.stance.isNotEmpty)
                      _miniTag(Icons.directions_run_rounded, _t(widget.stance, widget.stance)),
                  ],
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

class _ProfileEditSheet extends StatefulWidget {
  final bool isSpanish;
  final String displayName;
  final String stance;
  final String height;
  final String weight;
  final String location;
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
  final String age;
  final String surferSummary;
  final Function({
    String? displayName,
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
  }) onUpdate;

  const _ProfileEditSheet({
    required this.isSpanish,
    required this.displayName,
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
    required this.onUpdate,
  });

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController heightCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController ageCtrl;
  late TextEditingController summaryCtrl;
  late String currentStance;
  
  late bool sDash, sCoach, hDash, hCoach, wDash, wCoach, lDash, lCoach, aDash, aCoach;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.displayName);
    heightCtrl = TextEditingController(text: widget.height);
    weightCtrl = TextEditingController(text: widget.weight);
    locationCtrl = TextEditingController(text: widget.location);
    ageCtrl = TextEditingController(text: widget.age);
    summaryCtrl = TextEditingController(text: widget.surferSummary);
    currentStance = widget.stance;
    
    sDash = widget.stanceVisibleOnDashboard;
    sCoach = widget.stanceVisibleToCoach;
    hDash = widget.heightVisibleOnDashboard;
    hCoach = widget.heightVisibleToCoach;
    wDash = widget.weightVisibleOnDashboard;
    wCoach = widget.weightVisibleToCoach;
    lDash = widget.locationVisibleOnDashboard;
    lCoach = widget.locationVisibleToCoach;
    aDash = widget.ageVisibleOnDashboard;
    aCoach = widget.ageVisibleToCoach;
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _t("Edit Profile Summary", "Editar Resumen de Perfil"),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: _t("Display Name", "Nombre para mostrar"),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => widget.onUpdate(displayName: v),
            ),
            const SizedBox(height: 16),
            
            _buildFieldGroup(
              label: _t("Stance", "Posición"),
              child: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: "Regular", label: Text(_t("Regular", "Regular"))),
                  ButtonSegment(value: "Goofy", label: Text(_t("Goofy", "Goofy"))),
                ],
                selected: {currentStance},
                onSelectionChanged: (set) {
                  setState(() => currentStance = set.first);
                  widget.onUpdate(stance: set.first);
                },
              ),
              dash: sDash,
              coach: sCoach,
              onDash: (v) { setState(() => sDash = v); widget.onUpdate(stanceVisibleOnDashboard: v); },
              onCoach: (v) { setState(() => sCoach = v); widget.onUpdate(stanceVisibleToCoach: v); },
            ),
            
            _buildEditField(
              label: _t("Height", "Altura"),
              controller: heightCtrl,
              dash: hDash,
              coach: hCoach,
              onDash: (v) { setState(() => hDash = v); widget.onUpdate(heightVisibleOnDashboard: v); },
              onCoach: (v) { setState(() => hCoach = v); widget.onUpdate(heightVisibleToCoach: v); },
              onChanged: (v) => widget.onUpdate(height: v),
            ),
            
            _buildEditField(
              label: _t("Weight", "Peso"),
              controller: weightCtrl,
              dash: wDash,
              coach: wCoach,
              onDash: (v) { setState(() => wDash = v); widget.onUpdate(weightVisibleOnDashboard: v); },
              onCoach: (v) { setState(() => wCoach = v); widget.onUpdate(weightVisibleToCoach: v); },
              onChanged: (v) => widget.onUpdate(weight: v),
            ),
            
            _buildEditField(
              label: _t("Location", "Ubicación"),
              controller: locationCtrl,
              dash: lDash,
              coach: lCoach,
              onDash: (v) { setState(() => lDash = v); widget.onUpdate(locationVisibleOnDashboard: v); },
              onCoach: (v) { setState(() => lCoach = v); widget.onUpdate(locationVisibleToCoach: v); },
              onChanged: (v) => widget.onUpdate(location: v),
            ),
            
            _buildEditField(
              label: _t("Age", "Edad"),
              controller: ageCtrl,
              dash: aDash,
              coach: aCoach,
              onDash: (v) { setState(() => aDash = v); widget.onUpdate(ageVisibleOnDashboard: v); },
              onCoach: (v) { setState(() => aCoach = v); widget.onUpdate(ageVisibleToCoach: v); },
              onChanged: (v) => widget.onUpdate(age: v),
            ),

            TextField(
              controller: summaryCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _t("Surfer Summary / Coach Description", "Resumen de Surfer / Descripción para Coach"),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => widget.onUpdate(surferSummary: v),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t("Done", "Listo")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGroup({required String label, required Widget child, required bool dash, required bool coach, required ValueChanged<bool> onDash, required ValueChanged<bool> onCoach}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 4),
        Row(
          children: [
            _toggleItem(Icons.dashboard_outlined, _t("On Dash", "En Dash"), dash, onDash),
            const SizedBox(width: 12),
            _toggleItem(Icons.badge_outlined, _t("To Coach", "Para Coach"), coach, onCoach),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEditField({required String label, required TextEditingController controller, required bool dash, required bool coach, required ValueChanged<bool> onDash, required ValueChanged<bool> onCoach, required ValueChanged<String> onChanged}) {
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _toggleItem(Icons.dashboard_outlined, _t("On Dash", "En Dash"), dash, onDash),
            const SizedBox(width: 12),
            _toggleItem(Icons.badge_outlined, _t("To Coach", "Para Coach"), coach, onCoach),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _toggleItem(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: value ? AppTheme.primary : AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: value ? AppTheme.primary : AppTheme.textMuted,
                fontWeight: value ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 14,
              width: 14,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
