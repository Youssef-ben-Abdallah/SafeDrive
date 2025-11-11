import 'dart:math';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../models/detection_event.dart';

class FaceDetectionService {
  FaceDetectionService();

  static final FaceDetectorOptions _options = FaceDetectorOptions(
    enableClassification: true,
    enableContours: true,
    enableLandmarks: true,
    performanceMode: FaceDetectorMode.accurate,
  );

  FaceDetector? _faceDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _faceDetector = FaceDetector(options: _options);
    _isInitialized = true;
  }

  Future<void> dispose() async {
    if (!_isInitialized) return;

    await _faceDetector?.close();
    _faceDetector = null;
    _isInitialized = false;
  }

  Future<DetectionEvent?> processImage(InputImage image) async {
    if (!_isInitialized) {
      return null;
    }

    final faceDetector = _faceDetector;
    if (faceDetector == null) {
      return null;
    }

    final faces = await faceDetector.processImage(image);
    if (faces.isEmpty) {
      return null;
    }

    final primaryFace = faces.reduce((a, b) {
      final areaA = a.boundingBox.width * a.boundingBox.height;
      final areaB = b.boundingBox.width * b.boundingBox.height;
      return areaA >= areaB ? a : b;
    });

    final DetectionEvent? eyesEvent = _detectEyesClosed(primaryFace);
    final DetectionEvent? yawnEvent = _detectYawning(primaryFace);

    if (eyesEvent != null && yawnEvent != null) {
      final confidence =
          max(eyesEvent.confidence, yawnEvent.confidence).clamp(0.0, 1.0).toDouble();
      return DetectionEvent(
        timestamp: DateTime.now(),
        type: DetectionEventType.drowsiness,
        confidence: confidence,
        reason: 'Driver appears drowsy (eyes closed & yawning)',
        label: 'Drowsiness (eyes & yawn)',
        metadata: const {
          'tag': 'drowsiness_combined',
        },
      );
    }

    return eyesEvent ?? yawnEvent;
  }

  DetectionEvent? _detectEyesClosed(Face face) {
    final leftOpenProbability = face.leftEyeOpenProbability;
    final rightOpenProbability = face.rightEyeOpenProbability;

    if (leftOpenProbability == null || rightOpenProbability == null) {
      return null;
    }

    const closedThreshold = 0.45;
    final averageOpen = (leftOpenProbability + rightOpenProbability) / 2;
    if (averageOpen >= closedThreshold) {
      return null;
    }

    final confidence =
        ((closedThreshold - averageOpen) / closedThreshold).clamp(0.0, 1.0).toDouble();
    return DetectionEvent(
      timestamp: DateTime.now(),
      type: DetectionEventType.drowsiness,
      confidence: confidence,
      reason: 'Driver appears drowsy (eyes closed)',
      label: 'Eyes closed',
      metadata: const {
        'tag': 'drowsiness_eyes_closed',
      },
    );
  }

  DetectionEvent? _detectYawning(Face face) {
    final mouthRatio = _estimateMouthOpenRatio(face);
    if (mouthRatio == null) {
      return null;
    }

    const yawnThreshold = 0.32;
    if (mouthRatio <= yawnThreshold) {
      return null;
    }

    final confidence =
        ((mouthRatio - yawnThreshold) / yawnThreshold).clamp(0.0, 1.0).toDouble();
    return DetectionEvent(
      timestamp: DateTime.now(),
      type: DetectionEventType.drowsiness,
      confidence: confidence,
      reason: 'Driver appears fatigued (yawning)',
      label: 'Yawning',
      metadata: const {
        'tag': 'drowsiness_yawn',
      },
    );
  }

  double? _estimateMouthOpenRatio(Face face) {
    final upperLipBottom = face.contours[FaceContourType.upperLipBottom];
    final lowerLipTop = face.contours[FaceContourType.lowerLipTop];

    if (upperLipBottom == null || lowerLipTop == null) {
      return null;
    }

    final verticalPairs = min(upperLipBottom.points.length, lowerLipTop.points.length);
    if (verticalPairs == 0) {
      return null;
    }

    double verticalDistanceSum = 0.0;
    for (var i = 0; i < verticalPairs; i++) {
      final upperPoint = upperLipBottom.points[i];
      final lowerPoint = lowerLipTop.points[i];
      verticalDistanceSum += (lowerPoint.y - upperPoint.y).abs();
    }

    final averageVerticalDistance = verticalDistanceSum / verticalPairs;

    final upperLipTop = face.contours[FaceContourType.upperLipTop];
    final lowerLipBottom = face.contours[FaceContourType.lowerLipBottom];

    double horizontalDistance = 0.0;
    if (upperLipTop != null && upperLipTop.points.length >= 2) {
      horizontalDistance =
          (upperLipTop.points.last.x - upperLipTop.points.first.x).abs().toDouble();
    } else if (lowerLipBottom != null && lowerLipBottom.points.length >= 2) {
      horizontalDistance =
          (lowerLipBottom.points.last.x - lowerLipBottom.points.first.x).abs().toDouble();
    }

    if (horizontalDistance == 0) {
      return null;
    }

    return averageVerticalDistance / horizontalDistance;
  }

  bool get isInitialized => _isInitialized;
}
