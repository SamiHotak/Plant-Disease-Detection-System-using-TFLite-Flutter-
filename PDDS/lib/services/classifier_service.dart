import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/prediction.dart';
import 'image_stats.dart';

/// Arguments passed into the background isolate.
///
/// Must contain only sendable values — a file path and an int, not an
/// Interpreter (native pointers cannot cross isolate boundaries).
class _PreprocessRequest {
  final String imagePath;
  final int inputSize;
  const _PreprocessRequest(this.imagePath, this.inputSize);
}

/// Tensor plus the colour statistics gathered while building it.
class _PreprocessOutput {
  final Float32List tensor;
  final ImageStats stats;
  const _PreprocessOutput(this.tensor, this.stats);
}

/// Decode → orient → resize → flatten, off the UI thread.
///
/// Returns raw pixel values in the 0–255 range. The MobileNetV2
/// `preprocess_input` step is baked into the exported graph, so scaling here
/// would apply it twice and wreck the predictions.
///
/// Vegetation statistics are accumulated in the same pass, so the
/// out-of-distribution check costs essentially nothing extra.
_PreprocessOutput _preprocessInIsolate(_PreprocessRequest req) {
  final bytes = File(req.imagePath).readAsBytesSync();

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Unsupported or corrupt image file');
  }

  // Phone cameras store rotation in EXIF rather than rotating the pixels.
  // Without this, camera captures and gallery picks classify differently.
  final oriented = img.bakeOrientation(decoded);

  final resized = img.copyResize(
    oriented,
    width: req.inputSize,
    height: req.inputSize,
    interpolation: img.Interpolation.linear,
  );

  final buffer = Float32List(req.inputSize * req.inputSize * 3);
  final accumulator = ImageStatsAccumulator();

  var i = 0;
  for (var y = 0; y < req.inputSize; y++) {
    for (var x = 0; x < req.inputSize; x++) {
      final pixel = resized.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      buffer[i++] = r;
      buffer[i++] = g;
      buffer[i++] = b;

      accumulator.add(r, g, b);
    }
  }

  return _PreprocessOutput(buffer, accumulator.build());
}

/// Loads the TFLite model and runs inference.
///
/// Contract with the training notebook:
///   * input  — [1, 224, 224, 3] float32, raw 0–255 values
///   * output — [1, numClasses] float32 softmax probabilities
///   * labels — one class name per line, in the model's output order
class ClassifierService {
  static const String modelAsset = 'assets/models/plant_disease_model.tflite';
  static const String labelsAsset = 'assets/models/labels.txt';

  /// Must equal IMG_SIZE from the training notebook.
  static const int inputSize = 224;

  /// Label used by an optional trained reject class. If `labels.txt` contains
  /// this entry, a top prediction matching it is treated as "not a plant"
  /// rather than shown as a disease.
  static const String rejectLabel = 'Not_a_plant';

  Interpreter? _interpreter;
  List<String> _labels = <String>[];

  bool get isReady => _interpreter != null && _labels.isNotEmpty;
  int get numClasses => _labels.length;

  /// Classes shown to the user, excluding any reject class.
  List<String> get labels => List.unmodifiable(
        _labels.where((l) => !_isRejectLabel(l)).toList(),
      );

  bool get hasRejectClass => _labels.any(_isRejectLabel);

  static bool _isRejectLabel(String label) {
    final n = label.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    return n.contains('notaplant') ||
        n.contains('notplant') ||
        n.contains('background') ||
        n == 'unknown' ||
        n == 'other';
  }

  /// Loads model + labels. Safe to call more than once.
  Future<void> load() async {
    if (isReady) return;

    final options = InterpreterOptions()..threads = 4;
    _interpreter = await Interpreter.fromAsset(modelAsset, options: options);

    final raw = await rootBundle.loadString(labelsAsset);
    _labels = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (_labels.isEmpty) {
      throw StateError('labels.txt is empty or missing from assets.');
    }

    // Fail loudly at startup rather than silently mispredicting later.
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final modelClasses = outputShape.last;
    if (modelClasses != _labels.length) {
      throw StateError(
        'Model/label mismatch: the model outputs $modelClasses classes but '
        'labels.txt contains ${_labels.length} lines. Re-export both files '
        'together from the training notebook.',
      );
    }

    final inputShape = _interpreter!.getInputTensor(0).shape;
    if (inputShape.length == 4 && inputShape[1] != inputSize) {
      throw StateError(
        'Input size mismatch: the model expects ${inputShape[1]}px but '
        'ClassifierService.inputSize is $inputSize. Set them to the same value '
        'as IMG_SIZE in the notebook.',
      );
    }
  }

  /// Classifies [imageFile], returning predictions together with a verdict on
  /// whether the image should be trusted as a plant leaf at all.
  Future<AnalysisResult> analyse(File imageFile, {int topK = 3}) async {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('ClassifierService.load() must complete first.');
    }

    // Heavy pixel work runs off the UI thread so the app never janks.
    final pre = await compute(
      _preprocessInIsolate,
      _PreprocessRequest(imageFile.path, inputSize),
    );

    // ---- Gate 1: colour. Cheap, and rejects clear non-plants before the
    // model is even consulted.
    if (!pre.stats.looksLikeVegetation && !pre.stats.isBorderline) {
      return AnalysisResult(
        predictions: const <Prediction>[],
        imageStats: pre.stats,
        softmaxStats: const SoftmaxStats(
          topProbability: 0,
          margin: 0,
          normalisedEntropy: 1,
        ),
        verdict: ScanVerdict.notAPlant,
        rejectionReason:
            'This image does not appear to contain plant material. Point the '
            'camera at a single leaf and try again.',
      );
    }

    final input = pre.tensor.reshape(<int>[1, inputSize, inputSize, 3]);
    final output = List<double>.filled(_labels.length, 0.0)
        .reshape(<int>[1, _labels.length]);

    interpreter.run(input, output);

    final scores = (output[0] as List).cast<double>();
    final softmax = SoftmaxStats.fromScores(scores);

    final ranked = List<int>.generate(scores.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));

    // ---- Gate 2: a trained reject class, when the model has one.
    if (_isRejectLabel(_labels[ranked.first])) {
      return AnalysisResult(
        predictions: const <Prediction>[],
        imageStats: pre.stats,
        softmaxStats: softmax,
        verdict: ScanVerdict.notAPlant,
        rejectionReason:
            'The model classified this as something other than a plant leaf.',
      );
    }

    // Drop any reject class from the visible ranking.
    final visible = ranked.where((i) => !_isRejectLabel(_labels[i])).toList();
    final count = math.min(topK, visible.length);
    final predictions = List<Prediction>.generate(
      count,
      (i) => Prediction(
        rawLabel: _labels[visible[i]],
        confidence: scores[visible[i]],
      ),
    );

    // ---- Gate 3: the distribution itself. A near-uniform softmax means the
    // image resembles nothing the model was trained on.
    if (softmax.isGuessing) {
      return AnalysisResult(
        predictions: predictions,
        imageStats: pre.stats,
        softmaxStats: softmax,
        verdict: ScanVerdict.notAPlant,
        rejectionReason:
            'The model could not confidently match this image to any known '
            'plant condition, which usually means the subject is not a leaf '
            'it was trained on.',
      );
    }

    return AnalysisResult(
      predictions: predictions,
      imageStats: pre.stats,
      softmaxStats: softmax,
      verdict: softmax.isWeak || pre.stats.isBorderline
          ? ScanVerdict.uncertain
          : ScanVerdict.plantDetected,
      rejectionReason: null,
    );
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = <String>[];
  }
}
