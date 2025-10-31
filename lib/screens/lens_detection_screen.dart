import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../services/camera_permission_service.dart';

class LensDetectionScreenArguments {
  const LensDetectionScreenArguments(this.lensDirection);

  final CameraLensDirection lensDirection;
}

class LensDetectionScreen extends StatefulWidget {
  const LensDetectionScreen({
    super.key,
    required this.lensDirection,
  });

  static const routeName = '/detection/lens';

  final CameraLensDirection lensDirection;

  @override
  State<LensDetectionScreen> createState() => _LensDetectionScreenState();
}

class _LensDetectionScreenState extends State<LensDetectionScreen> {
  final CameraPermissionService _permissionService =
      const CameraPermissionService();

  CameraDescription? _description;
  CameraController? _controller;
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.unknown;
  bool _isLoadingCamera = true;
  bool _isInitializing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCamera();
  }

  Future<void> _loadCamera() async {
    setState(() {
      _isLoadingCamera = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      CameraDescription? description;
      for (final camera in cameras) {
        if (camera.lensDirection == widget.lensDirection) {
          description = camera;
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _description = description;
        if (description == null) {
          _errorMessage =
              'Aucune caméra ${_lensDisplayName()} n\'a été détectée sur cet appareil.';
        }
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Impossible de récupérer la caméra : ${error.description ?? error.code}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Impossible de récupérer la caméra : $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCamera = false;
        });
      }
    }
  }

  Future<void> _startDetection() async {
    final description = _description;
    if (description == null) {
      return;
    }

    final permission =
        await _permissionService.requestPermissionForLens(widget.lensDirection);

    if (!mounted) {
      return;
    }

    setState(() {
      _permissionStatus = permission;
    });

    if (permission != CameraPermissionStatus.granted) {
      setState(() {
        _errorMessage = _buildPermissionErrorMessage(permission);
      });
      return;
    }

    final previousController = _controller;
    setState(() {
      _controller = null;
      _errorMessage = null;
      _isInitializing = true;
    });

    await previousController?.dispose();

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
        _controller = controller;
      });
    } on CameraException catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Impossible d\'initialiser la caméra ${_lensDisplayName()} : ${error.description ?? error.code}';
      });
    } catch (error) {
      await controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage =
            'Impossible d\'initialiser la caméra ${_lensDisplayName()} : $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _stopDetection() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    setState(() {
      _controller = null;
    });

    await controller.dispose();
  }

  Future<void> _openSettings() async {
    await _permissionService.openSystemSettings();
  }

  String _lensDisplayName() {
    switch (widget.lensDirection) {
      case CameraLensDirection.front:
        return 'avant';
      case CameraLensDirection.back:
        return 'arrière';
      case CameraLensDirection.external:
        return 'externe';
    }
  }

  String? _buildPermissionErrorMessage(CameraPermissionStatus status) {
    final lensName = _lensDisplayName();

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
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCameraReady = _controller?.value.isInitialized == true;
    final bool isStartDisabled =
        _isLoadingCamera || _isInitializing || _description == null;
    final bool showOpenSettingsButton =
        _permissionStatus == CameraPermissionStatus.permanentlyDenied;

    final String statusLabel;
    final Color statusColor;

    if (_isLoadingCamera) {
      statusLabel =
          'Statut : 🟡 Recherche de la caméra ${_lensDisplayName()}…';
      statusColor = theme.colorScheme.tertiary;
    } else if (_isInitializing) {
      statusLabel =
          'Statut : 🟡 Initialisation de la caméra ${_lensDisplayName()}…';
      statusColor = theme.colorScheme.tertiary;
    } else if (isCameraReady) {
      statusLabel = 'Statut : 🟢 Caméra ${_lensDisplayName()} active';
      statusColor = theme.colorScheme.primary;
    } else if (_description == null) {
      statusLabel =
          'Statut : 🔴 Aucune caméra ${_lensDisplayName()} détectée sur cet appareil.';
      statusColor = theme.colorScheme.error;
    } else if (_permissionStatus == CameraPermissionStatus.permanentlyDenied) {
      statusLabel =
          'Statut : 🔴 L\'accès à la caméra ${_lensDisplayName()} est bloqué. Activez-le depuis les paramètres système.';
      statusColor = theme.colorScheme.error;
    } else if (_permissionStatus == CameraPermissionStatus.denied) {
      statusLabel =
          'Statut : 🔴 Autorisez la caméra ${_lensDisplayName()} pour démarrer la détection.';
      statusColor = theme.colorScheme.error;
    } else if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      statusLabel = 'Statut : 🔴 ${_errorMessage!}';
      statusColor = theme.colorScheme.error;
    } else {
      statusLabel =
          'Statut : ⚪ Appuyez sur « Démarrer la détection » pour lancer la caméra ${_lensDisplayName()}.';
      statusColor = theme.colorScheme.onSurfaceVariant;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text('Caméra ${_lensDisplayName()}'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.black),
                child: isCameraReady
                    ? CameraPreview(_controller!)
                    : _CameraPlaceholder(
                        message: _buildPlaceholderMessage(),
                      ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isCameraReady)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: _stopDetection,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text('Stop detection'),
                    )
                  else
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: isStartDisabled ? null : _startDetection,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start detection'),
                    ),
                  if (!isCameraReady && showOpenSettingsButton) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      onPressed: _openSettings,
                      child: const Text('Open system settings'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildPlaceholderMessage() {
    if (_isLoadingCamera) {
      return 'Recherche de la caméra ${_lensDisplayName()}…';
    }

    if (_description == null) {
      return 'Cette caméra ${_lensDisplayName()} n\'est pas disponible sur cet appareil.';
    }

    if (_permissionStatus == CameraPermissionStatus.permanentlyDenied) {
      return 'L\'accès à la caméra ${_lensDisplayName()} est bloqué. Activez-le depuis les paramètres système.';
    }

    if (_permissionStatus == CameraPermissionStatus.denied) {
      return 'Autorisez la caméra ${_lensDisplayName()} pour démarrer la détection.';
    }

    if (_isInitializing) {
      return 'Initialisation du flux vidéo…';
    }

    if (_errorMessage != null && _errorMessage!.isNotEmpty) {
      return _errorMessage!;
    }

    return 'Appuyez sur « Démarrer la détection » pour lancer la caméra ${_lensDisplayName()}.';
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.4,
            letterSpacing: 0.1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
