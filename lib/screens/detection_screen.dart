import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camera_permission_service.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  static const routeName = '/detection';

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final CameraPermissionService _cameraPermissionService =
      const CameraPermissionService();

  CameraController? _cameraController;
  CameraDescription? _frontCamera;
  CameraDescription? _rearCamera;
  CameraLensDirection? _activeLens;
  CameraLensDirection? _pendingLens;
  CameraPermissionStatus _frontPermissionStatus =
      CameraPermissionStatus.unknown;
  CameraPermissionStatus _rearPermissionStatus =
      CameraPermissionStatus.unknown;
  bool _isLoadingAvailableCameras = true;
  bool _isCameraInitializing = false;

  final Map<CameraLensDirection, String?> _lensErrors = {
    CameraLensDirection.front: null,
    CameraLensDirection.back: null,
  };

  @override
  void initState() {
    super.initState();
    _loadAvailableCameras();
  }

  Future<void> _loadAvailableCameras() async {
    setState(() {
      _isLoadingAvailableCameras = true;
      _lensErrors[CameraLensDirection.front] = null;
      _lensErrors[CameraLensDirection.back] = null;
    });

    try {
      final cameras = await availableCameras();

      CameraDescription? front;
      CameraDescription? back;

      for (final camera in cameras) {
        switch (camera.lensDirection) {
          case CameraLensDirection.front:
            front ??= camera;
            break;
          case CameraLensDirection.back:
            back ??= camera;
            break;
          case CameraLensDirection.external:
            // Ignore external cameras for now.
            break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _frontCamera = front;
        _rearCamera = back;
        _lensErrors[CameraLensDirection.front] = front == null
            ? 'Aucune caméra avant détectée sur cet appareil.'
            : null;
        _lensErrors[CameraLensDirection.back] = back == null
            ? 'Aucune caméra arrière détectée sur cet appareil.'
            : null;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      final message =
          'Impossible de récupérer la liste des caméras : ${error.description ?? error.code}';
      setState(() {
        _lensErrors[CameraLensDirection.front] = message;
        _lensErrors[CameraLensDirection.back] = message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message =
          'Impossible de récupérer la liste des caméras : $error';
      setState(() {
        _lensErrors[CameraLensDirection.front] = message;
        _lensErrors[CameraLensDirection.back] = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAvailableCameras = false;
        });
      }
    }
  }

  Future<void> _startCamera(CameraLensDirection lens) async {
    final description = lens == CameraLensDirection.front
        ? _frontCamera
        : _rearCamera;

    if (description == null) {
      setState(() {
        _lensErrors[lens] =
            'Aucune caméra ${_lensDisplayName(lens)} n\'a été détectée sur cet appareil.';
      });
      return;
    }

    final permission =
        await _cameraPermissionService.requestPermissionForLens(lens);

    if (!mounted) {
      return;
    }

    setState(() {
      _setPermissionStatus(lens, permission);
    });

    if (permission != CameraPermissionStatus.granted) {
      setState(() {
        _pendingLens = null;
        _lensErrors[lens] = _buildPermissionErrorMessage(lens, permission);
      });
      return;
    }

    await _stopCamera();

    setState(() {
      _pendingLens = lens;
      _isCameraInitializing = true;
      _lensErrors[lens] = null;
    });

    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _activeLens = lens;
        _pendingLens = null;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _lensErrors[lens] =
            'Impossible d\'initialiser la caméra ${_lensDisplayName(lens)} : ${error.description ?? error.code}';
        _activeLens = null;
        _pendingLens = null;
      });
    } catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _lensErrors[lens] =
            'Impossible d\'initialiser la caméra ${_lensDisplayName(lens)} : $error';
        _activeLens = null;
        _pendingLens = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
        });
      }
    }
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    if (controller != null) {
      setState(() {
        _cameraController = null;
        _activeLens = null;
        _pendingLens = null;
      });
      await controller.dispose();
    }
  }

  Future<void> _requestPermission(CameraLensDirection lens) async {
    final status =
        await _cameraPermissionService.requestPermissionForLens(lens);

    if (!mounted) {
      return;
    }

    setState(() {
      _setPermissionStatus(lens, status);
      if (status == CameraPermissionStatus.granted) {
        _lensErrors[lens] = null;
      } else {
        _lensErrors[lens] = _buildPermissionErrorMessage(lens, status);
      }
    });
  }

  void _openCameraSettings() {
    _cameraPermissionService.openSystemSettings();
  }

  void _setPermissionStatus(
    CameraLensDirection lens,
    CameraPermissionStatus status,
  ) {
    if (lens == CameraLensDirection.front) {
      _frontPermissionStatus = status;
    } else {
      _rearPermissionStatus = status;
    }
  }

  String _lensDisplayName(CameraLensDirection lens) {
    switch (lens) {
      case CameraLensDirection.front:
        return 'avant';
      case CameraLensDirection.back:
        return 'arrière';
      case CameraLensDirection.external:
        return 'externe';
    }
  }

  String? _buildPermissionErrorMessage(
    CameraLensDirection lens,
    CameraPermissionStatus status,
  ) {
    final lensName = _lensDisplayName(lens);

    switch (status) {
      case CameraPermissionStatus.granted:
        return null;
      case CameraPermissionStatus.denied:
        return 'Autorisez la caméra $lensName pour démarrer la détection.';
      case CameraPermissionStatus.permanentlyDenied:
        return 'L\'accès à la caméra $lensName est bloqué. Activez-le depuis les paramètres système.';
      case CameraPermissionStatus.unknown:
        return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCameraReady = _cameraController?.value.isInitialized == true;
    final activeError =
        _activeLens == null ? null : _lensErrors[_activeLens!];
    final fallbackError = activeError ??
        _lensErrors[CameraLensDirection.front] ??
        _lensErrors[CameraLensDirection.back];

    final String statusLabel;
    final Color statusColor;

    if (_isLoadingAvailableCameras) {
      statusLabel =
          'Statut : 🟡 Recherche des caméras disponibles…';
      statusColor = theme.colorScheme.tertiary;
    } else if (_isCameraInitializing) {
      final lensName =
          _pendingLens == null ? 'en cours' : _lensDisplayName(_pendingLens!);
      statusLabel =
          'Statut : 🟡 Initialisation de la caméra $lensName…';
      statusColor = theme.colorScheme.tertiary;
    } else if (_activeLens != null && isCameraReady) {
      statusLabel =
          'Statut : 🟢 Caméra ${_lensDisplayName(_activeLens!)} active';
      statusColor = theme.colorScheme.primary;
    } else if (fallbackError != null && fallbackError.isNotEmpty) {
      statusLabel = 'Statut : 🔴 $fallbackError';
      statusColor = theme.colorScheme.error;
    } else {
      statusLabel = 'Statut : ⚪ Aucune caméra active';
      statusColor = theme.colorScheme.onSurfaceVariant;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeDrive AI'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _LensSection(
                    title: 'Caméra avant',
                    lensDirection: CameraLensDirection.front,
                    controller: _activeLens == CameraLensDirection.front
                        ? _cameraController
                        : null,
                    hasCamera: _frontCamera != null,
                    permissionStatus: _frontPermissionStatus,
                    errorMessage: _lensErrors[CameraLensDirection.front],
                    isActive: _activeLens == CameraLensDirection.front,
                    isLoadingAvailable: _isLoadingAvailableCameras,
                    isInitializing: _isCameraInitializing &&
                        (_pendingLens == CameraLensDirection.front),
                    isBusy: _isCameraInitializing &&
                        (_pendingLens != null &&
                            _pendingLens != CameraLensDirection.front),
                    isAnotherCameraActive: _activeLens != null &&
                        _activeLens != CameraLensDirection.front,
                    onStart: () {
                      _startCamera(CameraLensDirection.front);
                    },
                    onStop: _stopCamera,
                    onRequestPermission: () {
                      _requestPermission(CameraLensDirection.front);
                    },
                    onOpenSettings: _openCameraSettings,
                  ),
                  const SizedBox(height: 20),
                  _LensSection(
                    title: 'Caméra arrière',
                    lensDirection: CameraLensDirection.back,
                    controller: _activeLens == CameraLensDirection.back
                        ? _cameraController
                        : null,
                    hasCamera: _rearCamera != null,
                    permissionStatus: _rearPermissionStatus,
                    errorMessage: _lensErrors[CameraLensDirection.back],
                    isActive: _activeLens == CameraLensDirection.back,
                    isLoadingAvailable: _isLoadingAvailableCameras,
                    isInitializing: _isCameraInitializing &&
                        (_pendingLens == CameraLensDirection.back),
                    isBusy: _isCameraInitializing &&
                        (_pendingLens != null &&
                            _pendingLens != CameraLensDirection.back),
                    isAnotherCameraActive: _activeLens != null &&
                        _activeLens != CameraLensDirection.back,
                    onStart: () {
                      _startCamera(CameraLensDirection.back);
                    },
                    onStop: _stopCamera,
                    onRequestPermission: () {
                      _requestPermission(CameraLensDirection.back);
                    },
                    onOpenSettings: _openCameraSettings,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                statusLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LensSection extends StatelessWidget {
  const _LensSection({
    required this.title,
    required this.lensDirection,
    required this.controller,
    required this.hasCamera,
    required this.permissionStatus,
    required this.errorMessage,
    required this.isActive,
    required this.isLoadingAvailable,
    required this.isInitializing,
    required this.isBusy,
    required this.isAnotherCameraActive,
    required this.onStart,
    required this.onStop,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final String title;
  final CameraLensDirection lensDirection;
  final CameraController? controller;
  final bool hasCamera;
  final CameraPermissionStatus permissionStatus;
  final String? errorMessage;
  final bool isActive;
  final bool isLoadingAvailable;
  final bool isInitializing;
  final bool isBusy;
  final bool isAnotherCameraActive;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCameraReady = controller?.value.isInitialized == true;
    final aspectRatio = isCameraReady ? controller!.value.aspectRatio : 16 / 9;
    final bool isStartDisabled =
        !hasCamera || isInitializing || isLoadingAvailable || isBusy;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: isCameraReady
                      ? CameraPreview(controller!)
                      : _LensPlaceholder(
                          lensDirection: lensDirection,
                          hasCamera: hasCamera,
                          permissionStatus: permissionStatus,
                          errorMessage: errorMessage,
                          isActive: isActive,
                          isInitializing: isInitializing,
                          isBusy: isBusy,
                          isLoadingAvailable: isLoadingAvailable,
                          isAnotherCameraActive: isAnotherCameraActive,
                          onRequestPermission: onRequestPermission,
                          onOpenSettings: onOpenSettings,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isActive && isCameraReady)
              FilledButton.icon(
                onPressed: onStop,
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Arrêter la caméra'),
              )
            else
              FilledButton.icon(
                onPressed: isStartDisabled ? null : onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Activer la caméra'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LensPlaceholder extends StatelessWidget {
  const _LensPlaceholder({
    required this.lensDirection,
    required this.hasCamera,
    required this.permissionStatus,
    required this.errorMessage,
    required this.isActive,
    required this.isInitializing,
    required this.isBusy,
    required this.isLoadingAvailable,
    required this.isAnotherCameraActive,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final CameraLensDirection lensDirection;
  final bool hasCamera;
  final CameraPermissionStatus permissionStatus;
  final String? errorMessage;
  final bool isActive;
  final bool isInitializing;
  final bool isBusy;
  final bool isLoadingAvailable;
  final bool isAnotherCameraActive;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  String get _lensName {
    switch (lensDirection) {
      case CameraLensDirection.front:
        return 'caméra avant';
      case CameraLensDirection.back:
        return 'caméra arrière';
      case CameraLensDirection.external:
        return 'caméra externe';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget message;

    if (!hasCamera) {
      message = Text(
        'Cette $_lensName n\'est pas disponible sur cet appareil.',
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        textAlign: TextAlign.center,
      );
    } else if (isLoadingAvailable) {
      message = Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            'Recherche des caméras disponibles…',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (permissionStatus == CameraPermissionStatus.permanentlyDenied) {
      message = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'L\'accès à la $_lensName est bloqué. Activez-la depuis les paramètres système.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onOpenSettings,
            child: const Text('Ouvrir les paramètres'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRequestPermission,
            child: const Text('Réessayer'),
          ),
        ],
      );
    } else if (permissionStatus == CameraPermissionStatus.denied) {
      message = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SafeDrive a besoin d\'accéder à la $_lensName pour démarrer la détection.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRequestPermission,
            child: const Text('Autoriser la caméra'),
          ),
        ],
      );
    } else if (isInitializing && isActive) {
      message = Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            'Initialisation du flux vidéo…',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (isBusy) {
      message = Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: Colors.white70),
          ),
          SizedBox(height: 12),
          Text(
            'Veuillez patienter…',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (errorMessage != null && errorMessage!.isNotEmpty) {
      message = Text(
        errorMessage!,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        textAlign: TextAlign.center,
      );
    } else if (isAnotherCameraActive) {
      message = Text(
        'Une autre caméra est actuellement active. Arrêtez-la pour utiliser cette $_lensName.',
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        textAlign: TextAlign.center,
      );
    } else {
      message = const Text(
        'Appuyez sur « Activer la caméra » pour démarrer le flux.',
        style: TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: message,
      ),
    );
  }
}

