import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

enum PermissionResult { granted, denied, permanentlyDenied, restricted, limited }

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Requests and checks the appropriate permission for the given ImageSource.
  /// source: camera or gallery
  Future<PermissionResult> handleImageSourcePermission(ImageSource source) async {
    // START STRICT SEPARATION
    Permission permission = (source == ImageSource.camera) 
        ? Permission.camera 
        : Permission.photos;

    debugPrint('[PermissionService] ACTION: Check/Request for Source: $source');
    debugPrint('[PermissionService] TARGET Permission: ${permission.toString()}');

    PermissionStatus status = await permission.status;
    debugPrint('[PermissionService] PRE-CHECK Status: $status');

    if (status.isPermanentlyDenied) {
      debugPrint('[PermissionService] CACHE: Permanently Denied.');
      return PermissionResult.permanentlyDenied;
    }

    if (status.isGranted) {
      debugPrint('[PermissionService] CACHE: Already Granted.');
      return PermissionResult.granted;
    }

    if (status.isLimited) {
      debugPrint('[PermissionService] CACHE: Already Limited (Private Access).');
      return PermissionResult.limited;
    }

    // Request
    debugPrint('[PermissionService] REQ: Triggering system request for $permission...');
    status = await permission.request();
    debugPrint('[PermissionService] REQ Result: $status');

    if (status.isGranted) {
      return PermissionResult.granted;
    } else if (status.isLimited) {
      return PermissionResult.limited;
    } else if (status.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    } else if (status.isRestricted) {
      return PermissionResult.restricted;
    } else {
      return PermissionResult.denied;
    }
  }

  /// Special case for capturing video which may need Microphone.
  /// Returns a complex status to help UI decide if it should show Settings.
  Future<PermissionResult> requestCameraAndMicrophone() async {
    debugPrint('[PermissionService] ACTION: Multi-Request (Camera + Mic)');

    // 1. Check current status
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;
    debugPrint('[PermissionService] PRE-CHECK: Camera: $cameraStatus, Mic: $micStatus');

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      debugPrint('[PermissionService] CACHE: One or more permanently denied.');
      return PermissionResult.permanentlyDenied;
    }

    if (cameraStatus.isGranted && micStatus.isGranted) {
      debugPrint('[PermissionService] CACHE: Both already granted.');
      return PermissionResult.granted;
    }

    // 2. Request
    debugPrint('[PermissionService] REQ: Triggering system request for Camera and Mic...');
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();
    
    final resCamera = statuses[Permission.camera]!;
    final resMic = statuses[Permission.microphone]!;
    debugPrint('[PermissionService] REQ Results: Camera: $resCamera, Mic: $resMic');

    if (resCamera.isGranted && resMic.isGranted) {
      return PermissionResult.granted;
    } else if (resCamera.isPermanentlyDenied || resMic.isPermanentlyDenied) {
      return PermissionResult.permanentlyDenied;
    } else if (resCamera.isRestricted || resMic.isRestricted) {
      return PermissionResult.restricted;
    } else {
      return PermissionResult.denied;
    }
  }
}
