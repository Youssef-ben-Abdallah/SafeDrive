import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  static const routeName = '/detection';

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  CameraController? _frontCameraController;
  CameraController? _rearCameraController;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    CameraController? frontController;
    CameraController? rearController;

    try {
      final cameras = await availableCameras();

      CameraDescription? frontCamera;
      CameraDescription? rearCamera;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front && frontCamera == null) {
          frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back && rearCamera == null) {
          rearCamera = camera;
        }
      }

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

      frontController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      rearController = CameraController(
        rearCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await Future.wait([
        frontController.initialize(),
        rearController.initialize(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _frontCameraController = frontController;
        _rearCameraController = rearController;
      });

      frontController = null;
      rearController = null;
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
      statusLabel = 'Statut : 🟢 Détection active';
      statusColor = theme.colorScheme.primary;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeDrive AI'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: _CameraSection(
                  title: 'FRONT CAMERA (Caméra avant)',
                  highlights: const [
                    'Détection du visage et des yeux',
                    'Détection du bâillement (somnolence)',
                    '→ Indicateurs visuels : yeux fermés, fatigue',
                  ],
                  controller: _frontCameraController,
                  isInitializing: _isInitializing,
                  errorMessage: _errorMessage,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                child: _CameraSection(
                  title: 'REAR CAMERA (Caméra arrière)',
                  highlights: const [
                    'Détection d\'objets et de mouvement',
                    'Suivi des véhicules, piétons ou obstacles',
                    '→ Avertissements visuels en cas de danger',
                  ],
                  controller: _rearCameraController,
                  isInitializing: _isInitializing,
                  errorMessage: _errorMessage,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
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
}

class _CameraSection extends StatelessWidget {
  const _CameraSection({
    required this.title,
    required this.highlights,
    required this.controller,
    required this.isInitializing,
    required this.errorMessage,
  });

  final String title;
  final List<String> highlights;
  final CameraController? controller;
  final bool isInitializing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isCameraReady = controller?.value.isInitialized == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
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
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...highlights.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Expanded(
                            child: Text(
                              item,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.isInitializing,
    required this.errorMessage,
  });

  final bool isInitializing;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Widget message;
    if (errorMessage != null) {
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
