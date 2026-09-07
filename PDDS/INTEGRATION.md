# Integrating the ML Model into the Flutter App

Step-by-step, from the trained model to a running app.

---

## The contract between the two halves

Everything below exists to keep these five things in sync. If the app ever
predicts nonsense, one of these is broken:

| # | Property | Value | Set in notebook | Read in app |
|---|----------|-------|-----------------|-------------|
| 1 | Input size | `224` | `IMG_SIZE` (§1) | `ClassifierService.inputSize` |
| 2 | Input range | raw `0–255` float | `preprocess_input` is inside the graph | `_preprocessInIsolate` does **no** scaling |
| 3 | Input shape | `[1, 224, 224, 3]` | model definition (§8) | `flat.reshape([1, 224, 224, 3])` |
| 4 | Output shape | `[1, numClasses]` softmax | `Dense(..., activation='softmax')` | `List.filled(...).reshape([1, n])` |
| 5 | Label order | alphabetical | `labels.txt` from `class_names` | `labels.txt` read line by line |

---

## Step 1 — Train and export

Run `Plant_Disease_Detection_Colab.ipynb` on Colab with a T4 GPU (Runtime →
Run all). Section 16 downloads `flutter_model_assets.zip` containing:

```
plant_disease_model.tflite    ~5 MB, float16 quantized
labels.txt                    one class name per line
model_meta.json               reference only, not used by the app
```

Before moving on, confirm section 15 printed **agreement 8/8** — that is the
check that the exported TFLite model still matches the Keras model.

---

## Step 2 — Create the Flutter project

```bash
flutter create --org com.yourname plant_disease_detector
cd plant_disease_detector
```

Delete the generated `lib/main.dart`, then copy in the provided `lib/` folder
and `pubspec.yaml`.

---

## Step 3 — Drop in the model assets

```bash
mkdir -p assets/models
unzip ~/Downloads/flutter_model_assets.zip -d assets/models/
ls assets/models/
# plant_disease_model.tflite  labels.txt  model_meta.json
```

The file names must match exactly — they are referenced as constants in
`lib/services/classifier_service.dart`:

```dart
static const String modelAsset = 'assets/models/plant_disease_model.tflite';
static const String labelsAsset = 'assets/models/labels.txt';
```

`pubspec.yaml` already declares both:

```yaml
flutter:
  assets:
    - assets/models/plant_disease_model.tflite
    - assets/models/labels.txt
```

---

## Step 4 — Install dependencies

```bash
flutter pub get
```

---

## Step 5 — Android configuration

**`android/app/build.gradle`** — inside the `android { }` block:

```gradle
android {
    // ...
    defaultConfig {
        minSdkVersion 21          // tflite_flutter requires 21+
        // ...
    }

    // Critical: Gradle compresses assets by default, which corrupts the
    // .tflite file. Without this the interpreter fails to load at runtime.
    androidResources {
        noCompress 'tflite'
    }
}
```

> On older Gradle plugin versions use `aaptOptions { noCompress "tflite" }`
> instead. If both are rejected, your AGP version wants the `androidResources`
> form.

---

## Step 6 — iOS configuration

**`ios/Runner/Info.plist`** — add inside the top-level `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Take photos of plant leaves to detect disease.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Select plant photos from your library to detect disease.</string>
```

**`ios/Podfile`** — ensure the platform line is uncommented:

```ruby
platform :ios, '12.0'
```

Then:

```bash
cd ios && pod install && cd ..
```

---

## Step 7 — Run

```bash
flutter run --release
```

Use `--release` when benchmarking. Debug builds run inference several times
slower because the Dart VM is not optimising.

---

## How a scan flows through the code

```
HomeScreen._scan()
  └─ ImagePicker.pickImage()                     → file path
      └─ ClassifierService.classify(File)
          ├─ compute(_preprocessInIsolate)        ← background isolate
          │    ├─ decodeImage(bytes)
          │    ├─ bakeOrientation()               ← fixes EXIF rotation
          │    ├─ copyResize(224 × 224)
          │    └─ Float32List of raw 0-255 values
          ├─ flat.reshape([1, 224, 224, 3])
          ├─ interpreter.run(input, output)
          └─ sort scores → List<Prediction>
              └─ ResultScreen
                  └─ DiseaseLibrary.lookup(rawLabel) → treatment guidance
```

Preprocessing runs in a background isolate via `compute()`, so decoding a
12-megapixel photo never blocks the UI thread. The interpreter itself runs on
the main isolate — MobileNetV2 inference is ~30–80 ms, fast enough not to drop
frames.

---

## Verifying the integration works

1. **Model loads** — the header shows `38 conditions · on-device` and an
   `OFFLINE READY` chip. If instead you see a red error panel, the assets are
   missing or mis-named.
2. **Class count is right** — that number must equal the class count printed
   by the notebook. `ClassifierService.load()` throws a descriptive
   `StateError` if the model and `labels.txt` disagree.
3. **Predictions are sane** — photograph a clearly healthy leaf. You should get
   a `Healthy` result above ~90%. Uniform noise or a wall should produce low
   confidence across the board.
4. **Camera and gallery agree** — photograph a leaf, then import the same file
   from the gallery. Both must give the same class. If they differ, EXIF
   orientation handling is broken.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `The method 'UnmodifiableUint8ListView' isn't defined for the type 'Tensor'` | tflite_flutter 0.10.x calls an API removed from `dart:typed_data` in Dart 3.4 | Use `tflite_flutter: ^0.12.1`, then `flutter clean && flutter pub get`. No Dart code changes needed — the public API is identical. |
| `Didn't find op for builtin opcode 'X' version 'N'` | Bundled TFLite runtime older than the ops in your model | Rare with MobileNetV2. If hit, in `~/AppData/Local/Pub/Cache/hosted/pub.dev/tflite_flutter-*/android/build.gradle` raise `def tflite_version` to `2.16.1` |
| `Unable to load asset ... .tflite` | Asset not declared or path typo | Check `pubspec.yaml`, then `flutter clean && flutter pub get` |
| Loads on iOS, fails on Android | Gradle compressed the model | Add `noCompress 'tflite'` (Step 5) |
| Every prediction ~ same low % | Double normalization | Do not divide pixels by 255 in Dart — the model already scales internally |
| Confident but always wrong class | Label order mismatch | Re-export `.tflite` **and** `labels.txt` together from the same run |
| Camera right, gallery wrong (or vice-versa) | EXIF rotation | Keep `img.bakeOrientation()` in the preprocessing step |
| `Model/label mismatch` StateError | Files from different training runs | Re-download both from the same notebook execution |
| Build fails: `minSdkVersion 16 cannot be smaller than 21` | Default Android config | Set `minSdkVersion 21` (Step 5) |
| Very slow inference | Debug build | Run with `--release` |

---

## Extending it

- **Swap in a new model** — retrain, drop in the new `.tflite` + `labels.txt`.
  No Dart changes are needed as long as input size and output format hold.
- **Add a disease** — add an entry to `DiseaseLibrary._entries`. The key is
  matched fuzzily against the label, so `'early blight'` catches
  `Tomato___Early_blight` and `Potato___Early_blight` alike.
- **Persist history** — `_history` in `HomeScreen` is in-memory only. Add
  `shared_preferences` or `sqflite` and serialise `ScanResult`.
- **Live camera inference** — add the `camera` package, stream frames, and
  reuse `ClassifierService`. Consider `IsolateInterpreter` at that point so
  inference also leaves the main isolate.
