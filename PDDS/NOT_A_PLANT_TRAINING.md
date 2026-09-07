# Rejecting non-plant images

## Why the model does this

A softmax classifier is **closed-set**. Its final layer produces one score per
known class and those scores are forced to sum to 1. There is no output for
"none of these" — so a photo of a cat is squeezed into the 38 plant classes,
and one of them necessarily wins. The confidence figure is a *relative* rank
among plants, not evidence that the image contains a plant at all.

Three defences are layered around this, cheapest first.

---

## Layer 1 — Colour gate (already active, no retraining)

Implemented in `lib/services/image_stats.dart`, computed during the existing
preprocessing pass so it costs nothing extra.

Two measures per image:

| Measure | Meaning |
|---|---|
| `greenFraction` | Share of pixels with hue 55°–175° (yellow-green → green), saturation ≥ 0.15 |
| `meanExcessGreen` | Mean of `2G − R − B`, a standard precision-agriculture vegetation index |

An image is treated as plant material when `greenFraction ≥ 0.25` **and**
`meanExcessGreen ≥ 15`.

Tested against representative palettes:

| Subject | green% | ExG | Result |
|---|---|---|---|
| Healthy leaf | 100% | 146 | accept |
| Brown-spotted leaf | 40% | 59 | accept |
| Yellowing leaf | 60% | 100 | accept |
| Dark blight leaf | 100% | 38 | accept |
| Leaf on grey background | 60% | 95 | accept |
| Human face | 0% | 2.8 | **reject** |
| Orange cat | 0% | −2 | **reject** |
| Red / blue car | 0% | −94 / −62 | **reject** |
| Sky | 0% | 15.4 | **reject** |
| Indoor room | 0% | 2.0 | **reject** |
| Green-painted car | 60% | 119 | *accepted — see Layer 3* |

The hue band starts at 55° specifically to exclude skin (~35°) and orange fur
(~25°). Brown lesions sit near 29° and would be missed on their own, but
diseased leaves retain enough green area to clear the threshold.

**Tuning:** if real leaves are rejected, lower `minGreenFraction` toward 0.15.
If non-plants get through, raise it toward 0.35. Both constants live at the top
of `ImageStats`, and the Diagnostics card on the rejection screen shows the
measured values so you can calibrate against real failures.

---

## Layer 2 — Distribution checks (already active, no retraining)

Even when colour passes, the shape of the softmax output is informative. An
unfamiliar image usually produces a flat distribution rather than a decisive
peak.

| Measure | Rejection rule |
|---|---|
| Top probability | `< 0.45` → reject |
| Normalised entropy | `> 0.65` → reject |
| Top probability | `< 0.70` → show, flagged uncertain |
| Top-1 minus top-2 margin | `< 0.15` → show, flagged uncertain |

Entropy is the useful one: 38 classes at roughly `1/38` each gives entropy near
1.0, an unambiguous signal of guessing that a single top-probability threshold
would miss.

**Limitation to be aware of:** neural networks are known to be *overconfident*
on out-of-distribution inputs. A green object can produce a genuinely high
softmax score, which is why Layers 1 and 2 cannot be complete on their own.

---

## Layer 3 — Train a reject class (the real fix)

Add a 39th class of non-plant images. This is the only approach that teaches
the model what "not a plant" actually looks like, rather than inferring it.

The app already supports this: `ClassifierService._isRejectLabel()` recognises
a class named `Not_a_plant` (also `background`, `unknown`, `other`) and routes
it to the rejection screen instead of displaying it as a disease. **No Dart
changes are needed** — retrain, drop in the new `.tflite` and `labels.txt`, done.

### Notebook changes

**A. Keep the background class instead of deleting it.** In section 3, remove
this block:

```python
for junk in ['Background_without_leaves', 'background_without_leaves']:
    p = os.path.join(DATA_DIR, junk)
    if os.path.isdir(p):
        shutil.rmtree(p)
```

Those ~1,100 images of bare soil and hands are useful negatives.

**B. Add general non-plant images.** Insert a new cell after section 3.
CIFAR-100 ships with Keras and needs no download credentials:

```python
import numpy as np, os
from PIL import Image
import tensorflow as tf

NEG_DIR = os.path.join(DATA_DIR, 'Not_a_plant')
os.makedirs(NEG_DIR, exist_ok=True)

(x_train, y_train), _ = tf.keras.datasets.cifar100.load_data(label_mode='fine')

# CIFAR-100 fine-label indices that are plants or plant parts. Excluded so the
# reject class never contains the very thing we are trying to detect.
PLANT_LIKE = {
    47, 52, 56, 59, 96,   # maple, oak, palm, pine, willow trees
    54, 62, 70, 82, 92,   # orchid, poppy, rose, sunflower, tulip
    0, 53, 57, 83,        # apple, orange, pear, sweet pepper
    51,                   # mushroom
}

kept = 0
for img_arr, label in zip(x_train, y_train.flatten()):
    if label in PLANT_LIKE:
        continue
    # Upscale 32x32 -> 224x224. Low source resolution is a known weakness of
    # this shortcut; see "Better negatives" below.
    Image.fromarray(img_arr).resize((224, 224), Image.BICUBIC).save(
        os.path.join(NEG_DIR, f'cifar_{kept}.jpg'), quality=90)
    kept += 1
    if kept >= 1200:
        break

print(f'Wrote {kept} negative images to {NEG_DIR}')
```

Then **re-run section 4 onward**. The class count becomes 39, `labels.txt`
gains a `Not_a_plant` line, and everything downstream adapts automatically.

**C. Balance it.** `MAX_IMAGES_PER_CLASS = 600` already caps the reject class
alongside the others, and `compute_class_weight` handles the remainder. No
extra work needed.

### Better negatives

CIFAR-100 upscaled from 32×32 is blurry, and the model may partly learn
"blurry = not a plant" rather than the semantics. Two stronger options:

1. **Photograph your own.** 200–400 phone photos of whatever the app will
   actually be pointed at by mistake — hands, faces, desks, floors, walls,
   sky, packaging. This matches deployment conditions better than any public
   dataset and is usually the single highest-value improvement.
2. **Add non-leaf plant parts.** Soil, bark, whole plants at distance, plastic
   plants. These are the realistic near-misses in field use.

Aim for roughly 600–1000 reject images, mixed across sources.

---

## What to expect

| Input | L1+L2 only | With reject class |
|---|---|---|
| Leaf, good photo | correct diagnosis | correct diagnosis |
| Face, cat, car, sky, room | rejected | rejected |
| Green non-plant object | *may pass* | rejected |
| Blurry / distant leaf | flagged uncertain | flagged uncertain |
| Plant not among the 38 | often flagged uncertain | more reliably rejected |

Layers 1 and 2 are active right now and handle the everyday cases. Layer 3
closes the remaining gap and is worth doing before any real deployment.
