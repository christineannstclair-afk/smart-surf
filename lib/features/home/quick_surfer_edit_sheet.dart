import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/smart_surf_crop_screen.dart';
import '../../ui_system/app_theme.dart';
import '../session_log/firebase_service.dart';


class QuickSurferEditSheet extends StatefulWidget {
  final bool isSpanish;
  final String displayName;
  final String? profilePhotoPath;
  final void Function({
    required String displayName,
    required String? profilePhotoPath,
  }) onUpdate;

  const QuickSurferEditSheet({
    super.key,
    required this.isSpanish,
    required this.displayName,
    required this.profilePhotoPath,
    required this.onUpdate,
  });

  static void show(BuildContext context, {
    required bool isSpanish,
    required String displayName,
    required String? profilePhotoPath,
    required void Function({
      required String displayName,
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
      builder: (ctx) => QuickSurferEditSheet(
        isSpanish: isSpanish,
        displayName: displayName,
        profilePhotoPath: profilePhotoPath,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<QuickSurferEditSheet> createState() => _QuickSurferEditSheetState();
}

class _QuickSurferEditSheetState extends State<QuickSurferEditSheet> {
  late TextEditingController nameCtrl;
  String? currentPhotoPath;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.displayName);
    currentPhotoPath = widget.profilePhotoPath;
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (picked != null) {
      debugPrint("DEBUG: Image picked. Waiting for picker to dismiss...");
      await Future.delayed(const Duration(milliseconds: 1000));
      
      debugPrint("DEBUG: Crop screen opening...");
      final File? croppedFile = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => SmartSurfCropScreen(
            image: File(picked.path),
            isSpanish: widget.isSpanish,
          ),
        ),
      );

      if (croppedFile != null) {
        debugPrint("DEBUG: Crop done tapped. Cropped path: ${croppedFile.path}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Uploading photo..."), duration: Duration(seconds: 1)),
          );
        }

        final fbResult = await FirebaseService().uploadMedia(
          localPath: croppedFile.path,
          isProfile: true,
          isVideo: false,
        );

        if (fbResult != null && fbResult.success) {
          debugPrint("DEBUG: Cropped image saved and uploaded. URL: ${fbResult.url}");
          setState(() => currentPhotoPath = fbResult.url);
          debugPrint("DEBUG: Crop screen dismissed (via image_cropper internal flow)");
        } else {
          debugPrint("DEBUG: Upload failed after crop: ${fbResult?.errorCode}");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload failed: ${fbResult?.errorCode ?? 'unknown'}")),
            );
          }
        }
      } else {
        debugPrint("DEBUG: Crop cancel tapped");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_t("Edit Surfer", "Editar Surfer"), 
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))
          ),
          const SizedBox(height: 32),
          
          GestureDetector(
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
          const SizedBox(height: 32),
          
          TextField(
            controller: nameCtrl,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: _t("Display Name", "Nombre para mostrar"),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            width: double.infinity,
            height: 60,
            child: FilledButton(
              onPressed: () {
                widget.onUpdate(
                  displayName: nameCtrl.text.trim(),
                  profilePhotoPath: currentPhotoPath,
                );
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(_t("Save Changes", "Guardar Cambios"), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
