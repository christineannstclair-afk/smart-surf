import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../session_log/firebase_service.dart';
import '../../ui_system/app_theme.dart';


class ProfileInfoEditSheet extends StatefulWidget {
  final bool isSpanish;
  final String stance;
  final String height;
  final String weight;
  final String location;
  final String age;
  final String surferSummary;
  final String displayName;
  final String? profilePhotoPath;


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

  final void Function({
    required String stance,
    required String height,
    required String weight,
    required String location,
    required String age,
    required String surferSummary,
    required String displayName,
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
    required String? profilePhotoPath,

  }) onUpdate;

  const ProfileInfoEditSheet({
    super.key,
    required this.isSpanish,
    required this.stance,
    required this.height,
    required this.weight,
    required this.location,
    required this.age,
    required this.surferSummary,
    required this.displayName,
    this.profilePhotoPath,

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

  static void show(BuildContext context, {
    required bool isSpanish,
    required String stance,
    required String height,
    required String weight,
    required String location,
    required String age,
    required String surferSummary,
    required String displayName,
    String? profilePhotoPath,

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
    required void Function({
      required String stance,
      required String height,
      required String weight,
      required String location,
      required String age,
      required String surferSummary,
      required String displayName,
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
      required String? profilePhotoPath,

    }) onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ProfileInfoEditSheet(
        isSpanish: isSpanish,
        stance: stance,
        height: height,
        weight: weight,
        location: location,
        age: age,
        surferSummary: surferSummary,
        displayName: displayName,
        profilePhotoPath: profilePhotoPath,

        stanceVisibleToCoach: stanceVisibleToCoach,
        stanceVisibleOnDashboard: stanceVisibleOnDashboard,
        heightVisibleToCoach: heightVisibleToCoach,
        heightVisibleOnDashboard: heightVisibleOnDashboard,
        weightVisibleToCoach: weightVisibleToCoach,
        weightVisibleOnDashboard: weightVisibleOnDashboard,
        locationVisibleToCoach: locationVisibleToCoach,
        locationVisibleOnDashboard: locationVisibleOnDashboard,
        ageVisibleToCoach: ageVisibleToCoach,
        ageVisibleOnDashboard: ageVisibleOnDashboard,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<ProfileInfoEditSheet> createState() => _ProfileInfoEditSheetState();
}

class _ProfileInfoEditSheetState extends State<ProfileInfoEditSheet> {
  late TextEditingController heightCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController ageCtrl;
  late TextEditingController summaryCtrl;
  late TextEditingController nameCtrl;
  String? currentPhotoPath;

  
  late String currentStance;

  late bool stanceVisibleToCoach;
  late bool stanceVisibleOnDashboard;
  late bool heightVisibleToCoach;
  late bool heightVisibleOnDashboard;
  late bool weightVisibleToCoach;
  late bool weightVisibleOnDashboard;
  late bool locationVisibleToCoach;
  late bool locationVisibleOnDashboard;
  late bool ageVisibleToCoach;
  late bool ageVisibleOnDashboard;

  @override
  void initState() {
    super.initState();
    heightCtrl = TextEditingController(text: widget.height);
    weightCtrl = TextEditingController(text: widget.weight);
    locationCtrl = TextEditingController(text: widget.location);
    ageCtrl = TextEditingController(text: widget.age);
    summaryCtrl = TextEditingController(text: widget.surferSummary);
    nameCtrl = TextEditingController(text: widget.displayName);
    currentPhotoPath = widget.profilePhotoPath;

    
    currentStance = widget.stance;

    stanceVisibleToCoach = widget.stanceVisibleToCoach;
    stanceVisibleOnDashboard = widget.stanceVisibleOnDashboard;
    heightVisibleToCoach = widget.heightVisibleToCoach;
    heightVisibleOnDashboard = widget.heightVisibleOnDashboard;
    weightVisibleToCoach = widget.weightVisibleToCoach;
    weightVisibleOnDashboard = widget.weightVisibleOnDashboard;
    locationVisibleToCoach = widget.locationVisibleToCoach;
    locationVisibleOnDashboard = widget.locationVisibleOnDashboard;
    ageVisibleToCoach = widget.ageVisibleToCoach;
    ageVisibleOnDashboard = widget.ageVisibleOnDashboard;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: widget.isSpanish ? 'Recortar Foto' : 'Crop Photo',
            toolbarColor: const Color(0xFF0F172A),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: widget.isSpanish ? 'Recortar Foto' : 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            doneButtonTitle: widget.isSpanish ? 'Hecho' : 'Done',
            cancelButtonTitle: widget.isSpanish ? 'Cancelar' : 'Cancel',
          ),
        ],
      );

      if (croppedFile != null) {
        // 1. Show loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uploading photo..."), duration: Duration(seconds: 1)),
          );
        }
        
        // 2. Upload
        final fbResult = await FirebaseService().uploadMedia(
          localPath: croppedFile.path,
          isProfile: true,
          isVideo: false,
        );

        if (fbResult != null && fbResult.success) {
          setState(() => currentPhotoPath = fbResult.url);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload failed: ${fbResult?.errorCode ?? 'unknown'}")),
            );
          }
        }
      }
    }
  }


  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Theme(
          data: Theme.of(context).copyWith(
            brightness: Brightness.light,
            textTheme: const TextTheme(
              titleLarge: TextStyle(color: Color(0xFF1E293B)),
              bodyMedium: TextStyle(color: Color(0xFF475569)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_t("Profile Info", "Información de Perfil"), 
                    style: const TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    )
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_t("Optional personal details.", "Detalles personales opcionales."),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                _t("Name", "Nombre"),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 16),
                decoration: InputDecoration(
                  hintText: _t("What's your name?", "¿Cómo te llamas?"),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          image: currentPhotoPath != null 
                            ? DecorationImage(
                                image: currentPhotoPath!.startsWith('http') 
                                  ? NetworkImage(currentPhotoPath!) 
                                  : FileImage(File(currentPhotoPath!)) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                        ),
                        child: currentPhotoPath == null ? const Icon(Icons.person, size: 50, color: Color(0xFF94A3B8)) : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                _t("Toggle what you want visible on your surf passport", "Activa lo que quieras que sea visible en tu pasaporte de surf"),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),

              _buildDropdownFieldWithToggle(
                label: _t("Stance", "Posición"),
                value: ["Regular", "Goofy"].contains(currentStance) ? currentStance : null,
                items: [
                  DropdownMenuItem(value: "Regular", child: Text(_t("Regular", "Regular"))),
                  DropdownMenuItem(value: "Goofy", child: Text(_t("Goofy", "Goofy"))),
                ],
                onChanged: (v) => setState(() => currentStance = v ?? ""),
                isVisibleOnDashboard: stanceVisibleOnDashboard,
                onDashboardVisibilityChanged: (v) => setState(() => stanceVisibleOnDashboard = v),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextFieldWithToggle(
                      controller: ageCtrl,
                      label: _t("Age", "Edad"),
                      keyboardType: TextInputType.number,
                      isVisibleOnDashboard: ageVisibleOnDashboard,
                      onDashboardVisibilityChanged: (v) => setState(() => ageVisibleOnDashboard = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFieldWithToggle(
                      controller: heightCtrl,
                      label: _t("Height", "Altura"),
                      isVisibleOnDashboard: heightVisibleOnDashboard,
                      onDashboardVisibilityChanged: (v) => setState(() => heightVisibleOnDashboard = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextFieldWithToggle(
                      controller: weightCtrl,
                      label: _t("Weight", "Peso"),
                      isVisibleOnDashboard: weightVisibleOnDashboard,
                      onDashboardVisibilityChanged: (v) => setState(() => weightVisibleOnDashboard = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()), // Empty slot for grid alignment
                ],
              ),
              const SizedBox(height: 16),

              _buildTextFieldWithToggle(
                controller: locationCtrl,
                label: _t("Location", "Ubicación"),
                isVisibleOnDashboard: locationVisibleOnDashboard,
                onDashboardVisibilityChanged: (v) => setState(() => locationVisibleOnDashboard = v),
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: summaryCtrl,
                label: _t("Surfer Summary", "Resumen de Surfer"),
                maxLines: 3,
                hint: _t("A brief bio...", "Una breve biografía..."),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    widget.onUpdate(
                      stance: currentStance,
                      height: heightCtrl.text,
                      weight: weightCtrl.text,
                      location: locationCtrl.text,
                      age: ageCtrl.text,
                      surferSummary: summaryCtrl.text,
                      displayName: nameCtrl.text,
                      stanceVisibleToCoach: stanceVisibleToCoach,
                      stanceVisibleOnDashboard: stanceVisibleOnDashboard,
                      heightVisibleToCoach: heightVisibleToCoach,
                      heightVisibleOnDashboard: heightVisibleOnDashboard,
                      weightVisibleToCoach: weightVisibleToCoach,
                      weightVisibleOnDashboard: weightVisibleOnDashboard,
                      locationVisibleToCoach: locationVisibleToCoach,
                      locationVisibleOnDashboard: locationVisibleOnDashboard,
                      ageVisibleToCoach: ageVisibleToCoach,
                      ageVisibleOnDashboard: ageVisibleOnDashboard,
                      profilePhotoPath: currentPhotoPath,
                    );

                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_t("Save Profile Info", "Guardar Información"), 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldHeader(String label, bool isVisible, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            SizedBox(
              height: 20,
              width: 36,
              child: Transform.scale(
                scale: 0.65,
                child: Switch(
                  value: isVisible,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF0F172A),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextFieldWithToggle({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    required bool isVisibleOnDashboard,
    required Function(bool) onDashboardVisibilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(label, isVisibleOnDashboard, onDashboardVisibilityChanged),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFieldWithToggle({
    required String label, 
    required String? value, 
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required bool isVisibleOnDashboard,
    required Function(bool) onDashboardVisibilityChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldHeader(label, isVisibleOnDashboard, onDashboardVisibilityChanged),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.any((item) => item.value == value) ? value : null,
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w500, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}
