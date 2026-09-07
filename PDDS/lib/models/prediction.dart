import '../services/image_stats.dart';

/// A single class score returned by the TFLite model.
///
/// Raw labels follow the PlantVillage convention `Plant___Disease_name`,
/// e.g. `Tomato___Early_blight` or `Apple___healthy`.
class Prediction {
  final String rawLabel;
  final double confidence;

  const Prediction({required this.rawLabel, required this.confidence});

  /// Text before the `___` separator: "Tomato", "Bell Pepper".
  String get plant {
    final parts = rawLabel.split('___');
    return _prettify(parts.first);
  }

  /// Text after the `___` separator: "Early blight", "Healthy".
  String get disease {
    final parts = rawLabel.split('___');
    final tail = parts.length > 1 ? parts.last : parts.first;
    return _prettify(tail);
  }

  bool get isHealthy => disease.toLowerCase().contains('healthy');

  /// Percentage string for display, e.g. "94.2%".
  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';

  /// How much to trust this result.
  ConfidenceLevel get level {
    if (confidence >= 0.85) return ConfidenceLevel.high;
    if (confidence >= 0.60) return ConfidenceLevel.moderate;
    return ConfidenceLevel.low;
  }

  static String _prettify(String raw) {
    final cleaned = raw
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'Unknown';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  @override
  String toString() => '$rawLabel (${confidencePercent})';
}

enum ConfidenceLevel { high, moderate, low }

extension ConfidenceLevelInfo on ConfidenceLevel {
  String get label {
    switch (this) {
      case ConfidenceLevel.high:
        return 'High confidence';
      case ConfidenceLevel.moderate:
        return 'Moderate confidence';
      case ConfidenceLevel.low:
        return 'Low confidence';
    }
  }

  String get advice {
    switch (this) {
      case ConfidenceLevel.high:
        return 'The model is confident in this identification.';
      case ConfidenceLevel.moderate:
        return 'Consider taking another photo in better light to confirm.';
      case ConfidenceLevel.low:
        return 'This result is uncertain. Retake the photo with the leaf '
            'filling the frame against a plain background.';
    }
  }
}

/// One completed analysis, kept for the session history list.
class ScanResult {
  final String imagePath;
  final List<Prediction> predictions;
  final DateTime timestamp;
  final int inferenceMs;
  final ScanVerdict verdict;

  const ScanResult({
    required this.imagePath,
    required this.predictions,
    required this.timestamp,
    required this.inferenceMs,
    this.verdict = ScanVerdict.plantDetected,
  });

  Prediction get top => predictions.first;
  bool get hasPredictions => predictions.isNotEmpty;
}

/// Whether a scan should be trusted.
///
/// A softmax classifier is closed-set: it distributes probability across the
/// classes it knows and can never output "none of these". These verdicts come
/// from checks layered around the model, not from the model itself.
enum ScanVerdict {
  /// Looks like a leaf and the model is confident.
  plantDetected,

  /// Plausible, but low confidence or ambiguous — show with a caveat.
  uncertain,

  /// Rejected: the subject does not appear to be a plant the model knows.
  notAPlant,
}

/// Full output of one analysis, including the diagnostics behind the verdict.
class AnalysisResult {
  final List<Prediction> predictions;
  final ImageStats imageStats;
  final SoftmaxStats softmaxStats;
  final ScanVerdict verdict;
  final String? rejectionReason;

  const AnalysisResult({
    required this.predictions,
    required this.imageStats,
    required this.softmaxStats,
    required this.verdict,
    this.rejectionReason,
  });

  bool get accepted => verdict != ScanVerdict.notAPlant;
}
