import 'dart:math';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../models/detection_event.dart';

class PoseDetectionService {
  PoseDetectionService()
      : _poseDetector = PoseDetector(
          options: PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
          ),
        );

  final PoseDetector _poseDetector;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
  }

  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }

    await _poseDetector.close();
    _isInitialized = false;
  }

  Future<DetectionEvent?> processImage(
    InputImage image, {
    double? segmentationCoverage,
  }) async {
    if (!_isInitialized) {
      return null;
    }

    if (segmentationCoverage != null && segmentationCoverage < 0.08) {
      return null;
    }

    final poses = await _poseDetector.processImage(image);
    if (poses.isEmpty) {
      return null;
    }

    final primaryPose = poses.first;

    final PoseLandmark? nose =
        primaryPose.landmarks[PoseLandmarkType.nose];
    final PoseLandmark? leftShoulder =
        primaryPose.landmarks[PoseLandmarkType.leftShoulder];
    final PoseLandmark? rightShoulder =
        primaryPose.landmarks[PoseLandmarkType.rightShoulder];

    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return null;
    }

    final shoulderWidth =
        (rightShoulder.x - leftShoulder.x).abs().clamp(1.0, double.infinity);
    final shoulderMidX = (rightShoulder.x + leftShoulder.x) / 2;
    final horizontalOffset = (nose.x - shoulderMidX).abs() / shoulderWidth;

    final averageShoulderY = (rightShoulder.y + leftShoulder.y) / 2;
    final verticalOffset = (nose.y - averageShoulderY) / shoulderWidth;

    final bool leaning = horizontalOffset > 0.55;
    final bool nodding = verticalOffset > 0.45;

    if (!leaning && !nodding) {
      return null;
    }

    final severity = max(horizontalOffset - 0.55, verticalOffset - 0.45);
    final confidence = (severity * 2).clamp(0.0, 1.0);

    final String reason;
    final String tag;
    if (leaning && nodding) {
      reason =
          'Driver posture unsafe — leaning and head dropped from steering position.';
      tag = 'pose_combined';
    } else if (leaning) {
      reason =
          'Driver posture unsafe — leaning away from the steering wheel.';
      tag = 'pose_leaning';
    } else {
      reason = 'Driver posture unsafe — nodding off detected.';
      tag = 'pose_nodding';
    }

    return DetectionEvent(
      timestamp: DateTime.now(),
      type: DetectionEventType.posture,
      confidence: confidence,
      reason: reason,
      label: 'Unsafe posture',
      metadata: {
        'tag': tag,
        'horizontalOffset': horizontalOffset,
        'verticalOffset': verticalOffset,
        'segmentationCoverage': segmentationCoverage,
        'minObservations': 3,
        'minDurationMs': 1200,
      },
    );
  }
}
