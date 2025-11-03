import 'dart:math';
import 'dart:typed_data';

import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';

class SegmentationAnalysis {
  SegmentationAnalysis({
    required this.averageConfidence,
    required this.foregroundCoverage,
    required this.timestamp,
  });

  final double averageConfidence;
  final double foregroundCoverage;
  final DateTime timestamp;
}

class SelfieSegmentationService {
  SelfieSegmentationService() : _segmenter = SelfieSegmenter();

  final SelfieSegmenter _segmenter;
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

    await _segmenter.close();
    _isInitialized = false;
  }

  Future<SegmentationAnalysis?> processImage(InputImage image) async {
    if (!_isInitialized) {
      return null;
    }

    final mask = await _segmenter.processImage(image);
    if (mask == null) {
      return null;
    }

    final floats = _extractMaskValues(mask);

    if (floats == null || floats.isEmpty) {
      return null;
    }

    double sum = 0;
    int foregroundCount = 0;
    for (final value in floats) {
      final clamped = value.clamp(0.0, 1.0);
      sum += clamped;
      if (clamped > 0.35) {
        foregroundCount += 1;
      }
    }

    final average = sum / floats.length;
    final coverage = foregroundCount / max(1, floats.length);

    return SegmentationAnalysis(
      averageConfidence: average,
      foregroundCoverage: coverage,
      timestamp: DateTime.now(),
    );
  }
}

Float32List? _extractMaskValues(SegmentationMask mask) {
  final dynamic dynamicMask = mask;
  final getters = [
    () => dynamicMask.buffer,
    () => dynamicMask.confidenceMask,
    () => dynamicMask.mask,
    () => dynamicMask.maskValues,
    () => dynamicMask.data,
  ];

  for (final getter in getters) {
    final result = _tryGetFloat32List(getter);
    if (result != null) {
      return result;
    }
  }

  return null;
}

Float32List? _tryGetFloat32List(dynamic Function() getter) {
  try {
    final value = getter();
    if (value == null) {
      return null;
    }

    if (value is Float32List) {
      return value;
    }

    if (value is ByteBuffer) {
      return value.asFloat32List();
    }

    if (value is List<double>) {
      return Float32List.fromList(value);
    }
  } catch (_) {
    return null;
  }

  return null;
}
