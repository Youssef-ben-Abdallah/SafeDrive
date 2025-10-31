import 'dart:math' as math;

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
  CameraController? _frontCameraController;
  CameraController? _rearCameraController;
  ResolutionPreset? _activeResolutionPreset;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isPictureInPictureMode = false;
  bool _isFrontCameraPrimary = true;
  CameraPermissionStatus _frontPermissionStatus =
      CameraPermissionStatus.unknown;
  CameraPermissionStatus _rearPermissionStatus =
      CameraPermissionStatus.unknown;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
      _activeResolutionPreset = null;
    });

    CameraController? frontController;
    CameraController? rearController;

    try {
      final frontPermission = await _cameraPermissionService
          .requestPermissionForLens(CameraLensDirection.front);
      final rearPermission = await _cameraPermissionService
          .requestPermissionForLens(CameraLensDirection.back);

      if (!mounted) {
        return;
      }

      if (frontPermission != CameraPermissionStatus.granted ||
          rearPermission != CameraPermissionStatus.granted) {
        await _frontCameraController?.dispose();
        await _rearCameraController?.dispose();

        if (!mounted) {
          return;
        }

        setState(() {
          _frontCameraController = null;
          _rearCameraController = null;
          _frontPermissionStatus = frontPermission;
          _rearPermissionStatus = rearPermission;
          _isInitializing = false;
          _errorMessage =
              _buildPermissionErrorMessage(frontPermission, rearPermission);
        });
        return;
      }

      setState(() {
        _frontPermissionStatus = frontPermission;
        _rearPermissionStatus = rearPermission;
        _errorMessage = null;
      });

      final cameras = await availableCameras();

      CameraDescription? frontCamera;
      CameraDescription? rearCamera;

      CameraDescription? selectCamera(
        Iterable<CameraDescription> preferred,
        Set<CameraDescription> used,
      ) {
        for (final camera in preferred) {
          if (!used.contains(camera)) {
            used.add(camera);
            return camera;
          }
        }

        for (final camera in cameras) {
          if (!used.contains(camera)) {
            used.add(camera);
            return camera;
          }
        }

        return null;
      }

      final usedCameras = <CameraDescription>{};

      final frontPreferences = [
        ...cameras.where((camera) => camera.lensDirection == CameraLensDirection.front),
        ...cameras.where((camera) => camera.lensDirection == CameraLensDirection.external),
      ];
      final rearPreferences = [
        ...cameras.where((camera) => camera.lensDirection == CameraLensDirection.back),
        ...cameras.where((camera) => camera.lensDirection == CameraLensDirection.external),
      ];

      frontCamera = selectCamera(frontPreferences, usedCameras);
      rearCamera = selectCamera(rearPreferences, usedCameras);

      if (frontCamera == null || rearCamera == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _errorMessage =
              'Impossible d\'initialiser les caméras avant et arrière simultanément sur cet appareil.';
        });
        return;
      }

      final presetsToTry = <ResolutionPreset>[
        ResolutionPreset.high,
        ResolutionPreset.medium,
        ResolutionPreset.low,
      ];

      ResolutionPreset? successfulPreset;

      for (final preset in presetsToTry) {
        frontController = CameraController(
          frontCamera,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        rearController = CameraController(
          rearCamera,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );

        try {
          await frontController.initialize();

          // Initializing multiple camera controllers in parallel can cause
          // permission dialogs to overlap which results in a
          // `CameraPermissionsRequestOngoing` error on some Android devices.
          // Request the second controller only after the first one has
          // completed its initialization to ensure the plugin processes the
          // permission flow sequentially.
          await rearController.initialize();
          successfulPreset = preset;
          break;
        } on CameraException catch (error) {
          final shouldRetry =
              preset != presetsToTry.last && _shouldRetryWithLowerPreset(error);

          await frontController.dispose();
          await rearController.dispose();
          frontController = null;
          rearController = null;

          if (!shouldRetry) {
            rethrow;
          }
        }
      }

      if (successfulPreset == null || frontController == null || rearController == null) {
        throw CameraException(
          'SafeDriveMultiCameraInitializationFailed',
          'Impossible d\'initialiser simultanément les caméras avant et arrière.',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _frontCameraController = frontController;
        _rearCameraController = rearController;
        _activeResolutionPreset = successfulPreset;
      });

      frontController = null;
      rearController = null;
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        if (error.code == 'CameraPermissionsRequestOngoing') {
          _errorMessage =
              'Une demande d\'autorisation de la caméra est déjà en cours. Veuillez patienter quelques secondes puis réessayer.';
        } else {
          _errorMessage =
              'Échec de l\'initialisation des caméras : ${error.description ?? error.code}';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Échec de l\'initialisation des caméras : $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      await frontController?.dispose();
      await rearController?.dispose();
    }
  }

  @override
  void dispose() {
    _frontCameraController?.dispose();
    _rearCameraController?.dispose();
    super.dispose();
  }

  void _togglePictureInPictureMode() {
    setState(() {
      _isPictureInPictureMode = !_isPictureInPictureMode;
    });
  }

  void _swapPrimaryCamera() {
    setState(() {
      _isFrontCameraPrimary = !_isFrontCameraPrimary;
    });
  }

  Future<void> _handlePermissionRequest(CameraLensDirection lensDirection) async {
    final status =
        await _cameraPermissionService.requestPermissionForLens(lensDirection);

    if (!mounted) {
      return;
    }

    setState(() {
      if (lensDirection == CameraLensDirection.front) {
        _frontPermissionStatus = status;
      } else {
        _rearPermissionStatus = status;
      }
      _errorMessage =
          _buildPermissionErrorMessage(_frontPermissionStatus, _rearPermissionStatus);
    });

    if (_frontPermissionStatus == CameraPermissionStatus.granted &&
        _rearPermissionStatus == CameraPermissionStatus.granted) {
      await _initializeCameras();
    }
  }

  void _openCameraSettings() {
    _cameraPermissionService.openSystemSettings();
  }

  String? _buildPermissionErrorMessage(
    CameraPermissionStatus frontStatus,
    CameraPermissionStatus rearStatus,
  ) {
    final missing = <String>[];

    if (frontStatus != CameraPermissionStatus.granted) {
      missing.add('avant');
    }
    if (rearStatus != CameraPermissionStatus.granted) {
      missing.add('arrière');
    }

    if (missing.isEmpty) {
      return null;
    }

    if (missing.length == 2) {
      return 'Autorisez les caméras avant et arrière pour démarrer la détection.';
    }

    return 'Autorisez la caméra ${missing.first} pour démarrer la détection.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String statusLabel;
    final Color statusColor;

    if (_errorMessage != null) {
      statusLabel = 'Statut : 🔴 ${_errorMessage!}';
      statusColor = theme.colorScheme.error;
    } else if (_isInitializing) {
      statusLabel = 'Statut : 🟡 Initialisation des caméras…';
      statusColor = theme.colorScheme.tertiary;
    } else {
      final presetLabel = _activeResolutionPreset == null
          ? ''
          : ' – qualité ${_describeResolutionPreset(_activeResolutionPreset!)}';
      statusLabel = 'Statut : 🟢 Détection active$presetLabel';
      statusColor = theme.colorScheme.primary;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeDrive AI'),
        actions: [
          IconButton(
            onPressed: _togglePictureInPictureMode,
            tooltip: _isPictureInPictureMode
                ? 'Afficher les caméras en mosaïque'
                : 'Afficher en mode image dans l\'image',
            icon: Icon(
              _isPictureInPictureMode
                  ? Icons.grid_view_rounded
                  : Icons.picture_in_picture_alt_rounded,
            ),
          ),
          if (_isPictureInPictureMode)
            IconButton(
              onPressed: _swapPrimaryCamera,
              tooltip: 'Inverser les caméras',
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _isPictureInPictureMode
                    ? _PictureInPictureLayout(
                        key: const ValueKey('pip-layout'),
                        isFrontCameraPrimary: _isFrontCameraPrimary,
                        frontCameraController: _frontCameraController,
                        rearCameraController: _rearCameraController,
                        frontPermissionStatus: _frontPermissionStatus,
                        rearPermissionStatus: _rearPermissionStatus,
                        isInitializing: _isInitializing,
                        errorMessage: _errorMessage,
                        swapPrimaryCamera: _swapPrimaryCamera,
                        requestFrontPermission: () {
                          _handlePermissionRequest(CameraLensDirection.front);
                        },
                        requestRearPermission: () {
                          _handlePermissionRequest(CameraLensDirection.back);
                        },
                        openSettings: _openCameraSettings,
                      )
                    : _SplitCameraLayout(
                        key: const ValueKey('split-layout'),
                        frontCameraController: _frontCameraController,
                        rearCameraController: _rearCameraController,
                        frontPermissionStatus: _frontPermissionStatus,
                        rearPermissionStatus: _rearPermissionStatus,
                        isInitializing: _isInitializing,
                        errorMessage: _errorMessage,
                        requestFrontPermission: () {
                          _handlePermissionRequest(CameraLensDirection.front);
                        },
                        requestRearPermission: () {
                          _handlePermissionRequest(CameraLensDirection.back);
                        },
                        openSettings: _openCameraSettings,
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  String _describeResolutionPreset(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return 'basse';
      case ResolutionPreset.medium:
        return 'moyenne';
      case ResolutionPreset.high:
        return 'haute';
      case ResolutionPreset.veryHigh:
        return 'très haute';
      case ResolutionPreset.ultraHigh:
        return 'ultra';
      case ResolutionPreset.max:
        return 'maximale';
    }
  }

  bool _shouldRetryWithLowerPreset(CameraException error) {
    final code = error.code.toLowerCase();
    final description = (error.description ?? '').toLowerCase();

    if (code.contains('maxcamerasinuse')) {
      return true;
    }

    const retryPhrases = [
      'max cameras in use',
      'maximum number of cameras',
      'multiple simultaneous cameras not supported',
      'already in use',
      'too many requests to open camera',
    ];

    return retryPhrases.any(description.contains);
  }
}

class _PictureInPictureLayout extends StatelessWidget {
  const _PictureInPictureLayout({
    super.key,
    required this.isFrontCameraPrimary,
    required this.frontCameraController,
    required this.rearCameraController,
    required this.frontPermissionStatus,
    required this.rearPermissionStatus,
    required this.isInitializing,
    required this.errorMessage,
    required this.swapPrimaryCamera,
    required this.requestFrontPermission,
    required this.requestRearPermission,
    required this.openSettings,
  });

  final bool isFrontCameraPrimary;
  final CameraController? frontCameraController;
  final CameraController? rearCameraController;
  final CameraPermissionStatus frontPermissionStatus;
  final CameraPermissionStatus rearPermissionStatus;
  final bool isInitializing;
  final String? errorMessage;
  final VoidCallback swapPrimaryCamera;
  final VoidCallback requestFrontPermission;
  final VoidCallback requestRearPermission;
  final VoidCallback openSettings;

  @override
  Widget build(BuildContext context) {
    final primaryController =
        isFrontCameraPrimary ? frontCameraController : rearCameraController;
    final secondaryController =
        isFrontCameraPrimary ? rearCameraController : frontCameraController;

    final primaryLabel = _cameraLensLabel(
      primaryController,
      isFrontCameraPrimary ? 'Caméra avant' : 'Caméra arrière',
    );
    final secondaryLabel = _cameraLensLabel(
      secondaryController,
      isFrontCameraPrimary ? 'Caméra arrière' : 'Caméra avant',
    );
    final primaryPermissionStatus =
        isFrontCameraPrimary ? frontPermissionStatus : rearPermissionStatus;
    final secondaryPermissionStatus =
        isFrontCameraPrimary ? rearPermissionStatus : frontPermissionStatus;
    final requestPrimaryPermission =
        isFrontCameraPrimary ? requestFrontPermission : requestRearPermission;
    final requestSecondaryPermission =
        isFrontCameraPrimary ? requestRearPermission : requestFrontPermission;
    final primaryLensDirection =
        isFrontCameraPrimary ? CameraLensDirection.front : CameraLensDirection.back;
    final secondaryLensDirection =
        isFrontCameraPrimary ? CameraLensDirection.back : CameraLensDirection.front;

    final overlayWidth = math.min(
      240.0,
      MediaQuery.of(context).size.width * 0.45,
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: Tooltip(
              message: primaryLabel,
              preferBelow: false,
              child: _CameraSection(
                controller: primaryController,
                isInitializing: isInitializing,
                errorMessage: errorMessage,
                lensDirection: primaryLensDirection,
                permissionStatus: primaryPermissionStatus,
                onRequestPermission: requestPrimaryPermission,
                onOpenSettings: openSettings,
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: SizedBox(
              width: overlayWidth,
              child: Tooltip(
                message: secondaryLabel,
                child: Stack(
                  children: [
                    _CameraSection(
                      controller: secondaryController,
                      isInitializing: isInitializing,
                      errorMessage: errorMessage,
                      isCompact: true,
                      onTap: swapPrimaryCamera,
                      lensDirection: secondaryLensDirection,
                      permissionStatus: secondaryPermissionStatus,
                      onRequestPermission: requestSecondaryPermission,
                      onOpenSettings: openSettings,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraSection extends StatelessWidget {
  const _CameraSection({
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
    required this.lensDirection,
    required this.permissionStatus,
    required this.onRequestPermission,
    required this.onOpenSettings,
    this.isCompact = false,
    this.onTap,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;
  final CameraLensDirection lensDirection;
  final CameraPermissionStatus permissionStatus;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;
  final bool isCompact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCameraReady = controller?.value.isInitialized == true;

    final borderRadius = BorderRadius.circular(isCompact ? 14 : 18);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            color: Colors.black,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isCameraReady)
                Positioned.fill(
                  child: CameraPreview(controller!),
                )
              else
                _CameraPlaceholder(
                  isInitializing: isInitializing,
                  errorMessage: errorMessage,
                  lensDirection: lensDirection,
                  permissionStatus: permissionStatus,
                  onRequestPermission: onRequestPermission,
                  onOpenSettings: onOpenSettings,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cameraLensLabel(CameraController? controller, String fallback) {
  final lensDirection = controller?.description.lensDirection;

  if (lensDirection == null) {
    return fallback;
  }

  switch (lensDirection) {
    case CameraLensDirection.front:
      return 'Caméra avant';
    case CameraLensDirection.back:
      return 'Caméra arrière';
    case CameraLensDirection.external:
      return 'Caméra externe';
  }

  return fallback;
}

class _CameraPanel extends StatelessWidget {
  const _CameraPanel({
    required this.fallbackLabel,
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
    required this.lensDirection,
    required this.permissionStatus,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final String fallbackLabel;
  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;
  final CameraLensDirection lensDirection;
  final CameraPermissionStatus permissionStatus;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _cameraLensLabel(controller, fallbackLabel);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _CameraSection(
            controller: controller,
            isInitializing: isInitializing,
            errorMessage: errorMessage,
            lensDirection: lensDirection,
            permissionStatus: permissionStatus,
            onRequestPermission: onRequestPermission,
            onOpenSettings: onOpenSettings,
          ),
        ),
      ],
    );
  }
}

class _SplitCameraLayout extends StatelessWidget {
  const _SplitCameraLayout({
    super.key,
    required this.frontCameraController,
    required this.rearCameraController,
    required this.frontPermissionStatus,
    required this.rearPermissionStatus,
    required this.isInitializing,
    required this.errorMessage,
    required this.requestFrontPermission,
    required this.requestRearPermission,
    required this.openSettings,
  });

  final CameraController? frontCameraController;
  final CameraController? rearCameraController;
  final CameraPermissionStatus frontPermissionStatus;
  final CameraPermissionStatus rearPermissionStatus;
  final bool isInitializing;
  final String? errorMessage;
  final VoidCallback requestFrontPermission;
  final VoidCallback requestRearPermission;
  final VoidCallback openSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: _CameraPanel(
              fallbackLabel: 'Caméra avant',
              controller: frontCameraController,
              isInitializing: isInitializing,
              errorMessage: errorMessage,
              lensDirection: CameraLensDirection.front,
              permissionStatus: frontPermissionStatus,
              onRequestPermission: requestFrontPermission,
              onOpenSettings: openSettings,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: _CameraPanel(
              fallbackLabel: 'Caméra arrière',
              controller: rearCameraController,
              isInitializing: isInitializing,
              errorMessage: errorMessage,
              lensDirection: CameraLensDirection.back,
              permissionStatus: rearPermissionStatus,
              onRequestPermission: requestRearPermission,
              onOpenSettings: openSettings,
            ),
          ),
        ),
      ],
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.isInitializing,
    required this.errorMessage,
    required this.lensDirection,
    required this.permissionStatus,
    required this.onRequestPermission,
    required this.onOpenSettings,
  });

  final bool isInitializing;
  final String? errorMessage;
  final CameraLensDirection lensDirection;
  final CameraPermissionStatus permissionStatus;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lensName = () {
      switch (lensDirection) {
        case CameraLensDirection.front:
          return 'caméra avant';
        case CameraLensDirection.back:
          return 'caméra arrière';
        case CameraLensDirection.external:
          return 'caméra externe';
      }
    }();

    final Widget message;
    if (permissionStatus == CameraPermissionStatus.permanentlyDenied) {
      message = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'L\'accès à la $lensName est désactivé. Activez-la depuis les paramètres système.',
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
            'SafeDrive a besoin d\'accéder à la $lensName pour démarrer la détection.',
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
    } else if (errorMessage != null) {
      message = Text(
        errorMessage!,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
        textAlign: TextAlign.center,
      );
    } else if (isInitializing) {
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
            'Initialisation des flux caméra…',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      message = const Text(
        'Caméra indisponible',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: message,
      ),
    );
  }
}
