/// Everything shown on the About and Developer screens lives here, so you can
/// edit your details in one file without touching any UI code.
library;

class DeveloperInfo {
  DeveloperInfo._();

  // ===========================================================
  // EDIT THESE WITH YOUR OWN DETAILS
  // ===========================================================
  static const String name = 'Sami Hotak';
  static const String role = 'ML & DL Engineer& Developer';
  static const String organisation = 'Ghalib University';
  static const String location = 'Herat, Afghanistan';
  static const String phone = '+93 777724870';
  static const String email = 'samiullahhotak2002@gmail.com';
  static const String website = '';

  /// Portrait shown at the top of the Developer screen.
  ///
  /// Put your photo at `assets/images/developer.jpg`. If the file is missing
  /// the screen falls back to your initials, so the app still builds and runs
  /// without it.
  static const String photoAsset = 'assets/images/developer.jpg';

  static const String bio =
      'Computer Science student focused on applied machine learning and '
      'mobile development. This project combines a convolutional neural '
      'network trained on leaf imagery with an offline-first Flutter '
      'application, so growers can diagnose crop disease in the field '
      'without a network connection.';

  /// Initials used when no photo asset is bundled.
  static String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class TechItem {
  final String name;
  final String role;
  final String category;
  const TechItem(this.name, this.role, this.category);
}

class TechStack {
  TechStack._();

  static const List<TechItem> items = <TechItem>[
    // Machine learning
    TechItem('TensorFlow / Keras', 'Model training and export', 'ml'),
    TechItem('MobileNetV2', 'CNN backbone, ImageNet pretrained', 'ml'),
    TechItem('Transfer Learning', 'Frozen head, then fine-tuning', 'ml'),
    TechItem('scikit-learn', 'Stratified split and evaluation metrics', 'ml'),
    TechItem('Pandas', 'Dataset inventory and analysis', 'ml'),
    TechItem('Matplotlib', 'Distribution plots and confusion matrix', 'ml'),
    TechItem('TensorFlow Lite', 'Float16 quantization for mobile', 'ml'),
    TechItem('Google Colab', 'GPU training environment (NVIDIA T4)', 'ml'),

    // Mobile
    TechItem('Flutter', 'Cross-platform UI framework', 'app'),
    TechItem('Dart', 'Application language', 'app'),
    TechItem('tflite_flutter', 'On-device inference via FFI', 'app'),
     TechItem('image', 'Decoding, EXIF orientation, resizing', 'app'),
    TechItem('image_picker', 'Camera and gallery capture', 'app'),
    TechItem('Material 3', 'Design system foundation', 'app'),
  ];

  static List<TechItem> get ml =>
      items.where((t) => t.category == 'ml').toList();
  static List<TechItem> get app =>
      items.where((t) => t.category == 'app').toList();
}

class DatasetInfo {
  DatasetInfo._();

  // ===========================================================
  // Update these from your own notebook output if you change
  // MAX_IMAGES_PER_CLASS or retrain on a different dataset.
  // ===========================================================
  static const String name = 'PlantVillage';
  static const String source = 'Mendeley Data / Penn State University';
  static const String licence = 'Open access, research use';

  /// Full dataset size before subsampling.
  static const int totalImages = 54303;

  /// Number of disease + healthy classes.
  static const int totalClasses = 38;

  /// Number of distinct crop species covered.
  static const int totalSpecies = 14;

  /// Cap applied per class during training (`MAX_IMAGES_PER_CLASS`).
  static const int imagesPerClassCap = 600;

  /// Roughly how many images the training run actually used.
  static const int imagesUsed = 20000;

  static const int trainSplitPercent = 80;
  static const int valSplitPercent = 20;

  /// Validation accuracy reported in section 12 of the notebook.
  /// Replace with the figure your own run printed.
  static const String reportedAccuracy = '97%+';

  static const String description =
      'PlantVillage is a public research dataset of leaf photographs captured '
      'under controlled lighting against plain backgrounds. Each image is '
      'labelled with its crop species and either a specific disease or a '
      'healthy status.';

  static const String preprocessing =
      'Images were capped at $imagesPerClassCap per class to keep training '
      'time practical, filtered for unreadable files, then split '
      '$trainSplitPercent/$valSplitPercent with stratification so every class '
      'appears in both sets. Training applied random flips, rotation, zoom and '
      'contrast shifts.';
}

class AppInfo {
  AppInfo._();

  /// Short name — shown in the header, the launcher and the window title.
  static const String name = 'PDDS';

  /// What the acronym stands for. Shown directly under the name.
  static const String fullName = 'Plant Disease Detection System';

  static const String version = '1.0.0';

  /// Subtitle line. Uses the expansion so the acronym is always explained.
  static const String tagline = fullName;

  static const String description =
      'PDDS stands for Plant Disease Detection System. It identifies crop '
      'disease from a photograph of a single leaf. The neural network runs '
      'entirely on your device, so it works with no internet connection and '
      'no image ever leaves your phone.';

  static const List<String> pipelineSteps = <String>[
    'You photograph a leaf, or pick an existing image.',
    'The photo is rotated upright using its EXIF data, then resized to '
        '224 × 224 pixels.',
    'Pixel values are passed to the MobileNetV2 model as a '
        '224 × 224 × 3 tensor.',
    'The network outputs a probability for each of the classes it knows.',
    'The three highest-scoring classes are shown, with treatment guidance '
        'for the top result.',
  ];

  static const List<String> captureTips = <String>[
    'Fill the frame with one leaf rather than the whole plant.',
    'Use bright, even, indirect daylight — avoid harsh shadow.',
    'Photograph against a plain background where possible.',
    'Hold steady and focus; blur reduces accuracy noticeably.',
    'Capture the side showing symptoms most clearly.',
  ];

  static const List<String> limitations = <String>[
    'It recognises only the crops and diseases listed on this screen — an '
        'unlisted plant will still return a result, but a meaningless one.',
    'Training images were shot against plain backgrounds, so cluttered field '
        'photos are less reliable.',
    'It cannot judge severity, nor distinguish disease from nutrient '
        'deficiency or physical damage.',
    'Treat low-confidence results as a prompt to retake the photo, not as a '
        'diagnosis.',
    'Confirm with a qualified agronomist before applying chemical treatment.',
  ];
}
