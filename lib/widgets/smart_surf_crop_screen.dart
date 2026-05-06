import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';

class SmartSurfCropScreen extends StatefulWidget {
  final File image;
  final bool isSpanish;

  const SmartSurfCropScreen({
    super.key,
    required this.image,
    required this.isSpanish,
  });

  @override
  State<SmartSurfCropScreen> createState() => _SmartSurfCropScreenState();
}

class _SmartSurfCropScreenState extends State<SmartSurfCropScreen> {
  final _cropController = CropController();
  late Uint8List _imageData;
  bool _isLoaded = false;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.image.readAsBytes();
    if (mounted) {
      setState(() {
        _imageData = bytes;
        _isLoaded = true;
      });
    }
  }

  String _t(String en, String es) => widget.isSpanish ? es : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            _t("Cancel", "Cancelar"),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        leadingWidth: 80,
        actions: [
          if (_isLoaded)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _isCropping ? null : () {
                  setState(() => _isCropping = true);
                  _cropController.crop();
                },
                child: Text(
                  _isCropping ? "..." : _t("Done", "Hecho"),
                  style: const TextStyle(
                    color: Color(0xFF38BDF8), // Ocean Blue
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoaded
          ? Crop(
              image: _imageData,
              controller: _cropController,
              onCropped: (result) async {
                // In version 2.0.0, result is a CropSuccess or CropFailure object
                if (result is CropSuccess) {
                  final image = result.croppedImage;
                  // Save to temp file
                  final tempDir = await Directory.systemTemp.createTemp();
                  final file = await File('${tempDir.path}/cropped_profile.jpg').create();
                  await file.writeAsBytes(image);
                  if (mounted) {
                    Navigator.pop(context, file);
                  }
                } else {
                  setState(() => _isCropping = false);
                  debugPrint("ERROR: Cropping failed");
                }
              },
              aspectRatio: 1 / 1,
              interactive: true,
              withCircleUi: true,
              baseColor: Colors.black,
              maskColor: Colors.black.withOpacity(0.8),
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
