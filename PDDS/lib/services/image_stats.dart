import 'dart:math' as math;

/// Colour statistics used to decide whether an image plausibly shows plant
/// material before its prediction is trusted.
///
/// Thresholds were tuned against representative palettes for leaves (healthy,
/// yellowing, brown-spotted, dark blight) and non-plants (skin, fur, vehicles,
/// sky, interiors). Colour reliably rejects the obvious cases; a green-painted
/// object still passes, which is what the trained reject class in
/// `NOT_A_PLANT_TRAINING.md` is for.
class ImageStats {
  /// Fraction of pixels in the yellow-green to green hue band.
  final double greenFraction;

  /// Mean Excess Green index (2G − R − B), a standard vegetation index.
  final double meanExcessGreen;

  /// Mean HSV saturation — flat grey/white scenes score near zero.
  final double meanSaturation;

  const ImageStats({
    required this.greenFraction,
    required this.meanExcessGreen,
    required this.meanSaturation,
  });

  // Tuned thresholds. Lower them if real leaves are being rejected.
  static const double minGreenFraction = 0.25;
  static const double minExcessGreen = 15.0;

  bool get looksLikeVegetation =>
      greenFraction >= minGreenFraction && meanExcessGreen >= minExcessGreen;

  /// Marginal cases: some plant colour, but less than a clear leaf shot.
  bool get isBorderline =>
      !looksLikeVegetation &&
      greenFraction >= minGreenFraction * 0.6 &&
      meanExcessGreen >= minExcessGreen * 0.4;

  @override
  String toString() => 'green=${(greenFraction * 100).toStringAsFixed(0)}% '
      'exg=${meanExcessGreen.toStringAsFixed(1)} '
      'sat=${meanSaturation.toStringAsFixed(2)}';
}

/// Accumulates per-pixel colour statistics in a single pass.
class ImageStatsAccumulator {
  int _count = 0;
  int _greenCount = 0;
  double _exgSum = 0;
  double _satSum = 0;

  /// Feed one pixel, channels in the 0–255 range.
  void add(double r, double g, double b) {
    _count++;
    _exgSum += 2 * g - r - b;

    final maxC = math.max(r, math.max(g, b));
    final minC = math.min(r, math.min(g, b));
    final delta = maxC - minC;

    final saturation = maxC <= 0 ? 0.0 : delta / maxC;
    _satSum += saturation;

    if (delta <= 0) return; // pure grey has no hue

    // Hue in degrees.
    double hue;
    if (maxC == r) {
      hue = 60 * (((g - b) / delta) % 6);
    } else if (maxC == g) {
      hue = 60 * (((b - r) / delta) + 2);
    } else {
      hue = 60 * (((r - g) / delta) + 4);
    }
    if (hue < 0) hue += 360;

    // 55°–175° spans yellow-green through green. Skin tones sit near 35°
    // and orange fur near 25°, so both fall outside deliberately.
    final value = maxC / 255.0;
    if (hue >= 55 && hue <= 175 && saturation >= 0.15 && value >= 0.08) {
      _greenCount++;
    }
  }

  ImageStats build() {
    if (_count == 0) {
      return const ImageStats(
        greenFraction: 0,
        meanExcessGreen: 0,
        meanSaturation: 0,
      );
    }
    return ImageStats(
      greenFraction: _greenCount / _count,
      meanExcessGreen: _exgSum / _count,
      meanSaturation: _satSum / _count,
    );
  }
}

/// Softmax-based uncertainty measures.
///
/// A closed-set classifier always distributes probability across its known
/// classes, so an unfamiliar image typically produces a flat, low-margin
/// distribution rather than an explicit "unknown".
class SoftmaxStats {
  /// Highest class probability.
  final double topProbability;

  /// Gap between the top two classes — small means the model is torn.
  final double margin;

  /// Shannon entropy normalised to 0–1; high means near-uniform guessing.
  final double normalisedEntropy;

  const SoftmaxStats({
    required this.topProbability,
    required this.margin,
    required this.normalisedEntropy,
  });

  factory SoftmaxStats.fromScores(List<double> scores) {
    if (scores.isEmpty) {
      return const SoftmaxStats(
        topProbability: 0,
        margin: 0,
        normalisedEntropy: 1,
      );
    }

    final sorted = List<double>.from(scores)..sort((a, b) => b.compareTo(a));
    final top = sorted.first;
    final second = sorted.length > 1 ? sorted[1] : 0.0;

    var entropy = 0.0;
    for (final p in scores) {
      if (p > 1e-12) entropy -= p * math.log(p);
    }
    final maxEntropy = math.log(scores.length.toDouble());
    final normalised = maxEntropy > 0 ? entropy / maxEntropy : 1.0;

    return SoftmaxStats(
      topProbability: top,
      margin: top - second,
      normalisedEntropy: normalised.clamp(0.0, 1.0),
    );
  }

  /// Distribution so flat the model is effectively guessing.
  bool get isGuessing => topProbability < 0.45 || normalisedEntropy > 0.65;

  /// Plausible, but not confident enough to present without a caveat.
  bool get isWeak => topProbability < 0.70 || margin < 0.15;
}
