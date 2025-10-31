import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents the authorization status for a given camera lens.
enum CameraPermissionStatus {
  /// Permission has not been checked yet.
  unknown,

  /// The permission has been granted and the camera can be used.
  granted,

  /// The permission has been denied but can still be requested.
  denied,

  /// The permission has been denied and the user must enable it manually
  /// from the system settings screen.
  permanentlyDenied,
}

/// Handles camera permission requests for both front and rear lenses.
class CameraPermissionService {
  const CameraPermissionService();

  /// Requests the camera permission for the provided [lensDirection].
  ///
  /// Even though mobile operating systems do not expose permissions per lens,
  /// requesting it separately allows the UI to show contextual messages to the
  /// user when each lens is needed.
  Future<CameraPermissionStatus> requestPermissionForLens(
    CameraLensDirection _lensDirection,
  ) async {
    if (kIsWeb) {
      return CameraPermissionStatus.granted;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      return CameraPermissionStatus.granted;
    }

    PermissionStatus status = await Permission.camera.status;

    if (_isPermissionGranted(status)) {
      return CameraPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }

    status = await Permission.camera.request();

    if (_isPermissionGranted(status)) {
      return CameraPermissionStatus.granted;
    }

    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }

    return CameraPermissionStatus.denied;
  }

  /// Opens the application settings screen so the user can manually grant the
  /// camera permission when it has been permanently denied.
  Future<void> openSystemSettings() async {
    await openAppSettings();
  }

  bool _isPermissionGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }
}
