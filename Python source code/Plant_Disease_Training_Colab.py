{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "0ac638df",
   "metadata": {},
   "source": [
    "# 🌿 Plant Disease Detection — Training Notebook (Colab)\n",
    "\n",
    "Trains a MobileNetV2 CNN on the **PlantVillage** dataset and exports a **TFLite** model for the Flutter app.\n",
    "\n",
    "**Stack:** Pandas (EDA) · Matplotlib (visualization) · TensorFlow/Keras (model) · scikit-learn (evaluation) · TFLite (mobile export)\n",
    "\n",
    "> ⚡ **Before running:** Runtime → Change runtime type → **T4 GPU**\n",
    "\n",
    "**Outputs (downloaded at the end):**\n",
    "- `plant_disease_model.tflite` → copy to `flutter_app/assets/models/`\n",
    "- `labels.txt` → copy to `flutter_app/assets/models/`"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "2f47bc0c",
   "metadata": {},
   "source": [
    "## 1. Setup & Dataset Download (Kaggle)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "222fb190",
   "metadata": {},
   "outputs": [],
   "source": [
    "import tensorflow as tf\n",
    "print(\"TensorFlow:\", tf.__version__)\n",
    "print(\"GPU:\", tf.config.list_physical_devices('GPU'))"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "e965c3bc",
   "metadata": {},
   "source": [
    "**Get your Kaggle API key:** [kaggle.com/settings](https://www.kaggle.com/settings) → *Create New Token* → downloads `kaggle.json`.\n",
    "\n",
    "Run the next cell and upload that file when prompted."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "606357b7",
   "metadata": {},
   "outputs": [],
   "source": [
    "from google.colab import files\n",
    "import os\n",
    "\n",
    "# Upload kaggle.json\n",
    "uploaded = files.upload()\n",
    "\n",
    "os.makedirs('/root/.kaggle', exist_ok=True)\n",
    "os.replace('kaggle.json', '/root/.kaggle/kaggle.json')\n",
    "os.chmod('/root/.kaggle/kaggle.json', 0o600)\n",
    "print(\"Kaggle credentials configured ✓\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "20115825",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Download and unzip PlantVillage (~330 MB)\n",
    "!kaggle datasets download -d emmarex/plantdisease -p /content --unzip -q\n",
    "\n",
    "# The dataset unzips to /content/PlantVillage\n",
    "DATA_DIR = '/content/PlantVillage'\n",
    "!ls {DATA_DIR} | head -20"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "e10dcb43",
   "metadata": {},
   "source": [
    "## 2. EDA — Pandas + Matplotlib"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "faefa2e7",
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "import numpy as np\n",
    "from pathlib import Path\n",
    "\n",
    "rows = []\n",
    "for class_dir in sorted(Path(DATA_DIR).iterdir()):\n",
    "    if class_dir.is_dir():\n",
    "        rows.append({'class': class_dir.name,\n",
    "                     'count': len(list(class_dir.glob('*')))})\n",
    "\n",
    "df = pd.DataFrame(rows)\n",
    "print(f\"Total classes : {len(df)}\")\n",
    "print(f\"Total images  : {df['count'].sum()}\")\n",
    "print(f\"Imbalance ratio (max/min): {df['count'].max() / df['count'].min():.2f}\")\n",
    "df.sort_values('count', ascending=False)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "a38497ff",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Class distribution\n",
    "plt.figure(figsize=(10, 7))\n",
    "d = df.sort_values('count')\n",
    "plt.barh(d['class'], d['count'], color='seagreen')\n",
    "plt.xlabel('Number of images')\n",
    "plt.title('PlantVillage Class Distribution')\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "3c60179e",
   "metadata": {},
   "source": [
    "## 3. Load Datasets (80/20 train/val split)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "36d4eb16",
   "metadata": {},
   "outputs": [],
   "source": [
    "IMG_SIZE = 224   # must match inputSize in tflite_service.dart\n",
    "BATCH_SIZE = 32\n",
    "SEED = 42\n",
    "\n",
    "train_ds = tf.keras.utils.image_dataset_from_directory(\n",
    "    DATA_DIR, validation_split=0.2, subset='training', seed=SEED,\n",
    "    image_size=(IMG_SIZE, IMG_SIZE), batch_size=BATCH_SIZE)\n",
    "\n",
    "val_ds = tf.keras.utils.image_dataset_from_directory(\n",
    "    DATA_DIR, validation_split=0.2, subset='validation', seed=SEED,\n",
    "    image_size=(IMG_SIZE, IMG_SIZE), batch_size=BATCH_SIZE)\n",
    "\n",
    "class_names = train_ds.class_names\n",
    "NUM_CLASSES = len(class_names)\n",
    "print(f\"\\n{NUM_CLASSES} classes:\")\n",
    "class_names"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "1a8467a6",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Sample images\n",
    "plt.figure(figsize=(12, 12))\n",
    "for images, labels in train_ds.take(1):\n",
    "    for i in range(16):\n",
    "        plt.subplot(4, 4, i + 1)\n",
    "        plt.imshow(images[i].numpy().astype('uint8'))\n",
    "        plt.title(class_names[labels[i]], fontsize=8)\n",
    "        plt.axis('off')\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "fc5885a4",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Performance: cache + prefetch\n",
    "AUTOTUNE = tf.data.AUTOTUNE\n",
    "train_ds = train_ds.cache().shuffle(1000).prefetch(AUTOTUNE)\n",
    "val_ds = val_ds.cache().prefetch(AUTOTUNE)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "19a10573",
   "metadata": {},
   "source": [
    "## 4. Build Model — MobileNetV2 Transfer Learning\n",
    "\n",
    "Normalization (`preprocess_input`) is **inside the graph**, so the Flutter app feeds raw 0-255 pixels."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "c80371ae",
   "metadata": {},
   "outputs": [],
   "source": [
    "data_augmentation = tf.keras.Sequential([\n",
    "    tf.keras.layers.RandomFlip('horizontal'),\n",
    "    tf.keras.layers.RandomRotation(0.15),\n",
    "    tf.keras.layers.RandomZoom(0.15),\n",
    "    tf.keras.layers.RandomContrast(0.1),\n",
    "])\n",
    "\n",
    "base = tf.keras.applications.MobileNetV2(\n",
    "    input_shape=(IMG_SIZE, IMG_SIZE, 3),\n",
    "    include_top=False, weights='imagenet')\n",
    "base.trainable = False  # Phase 1: frozen backbone\n",
    "\n",
    "inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))\n",
    "x = data_augmentation(inputs)\n",
    "x = tf.keras.applications.mobilenet_v2.preprocess_input(x)  # scales to [-1, 1]\n",
    "x = base(x, training=False)\n",
    "x = tf.keras.layers.GlobalAveragePooling2D()(x)\n",
    "x = tf.keras.layers.Dropout(0.3)(x)\n",
    "outputs = tf.keras.layers.Dense(NUM_CLASSES, activation='softmax')(x)\n",
    "\n",
    "model = tf.keras.Model(inputs, outputs)\n",
    "model.compile(optimizer=tf.keras.optimizers.Adam(1e-3),\n",
    "              loss='sparse_categorical_crossentropy',\n",
    "              metrics=['accuracy'])\n",
    "model.summary()"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "3874287d",
   "metadata": {},
   "source": [
    "## 5. Phase 1 — Train with Frozen Backbone"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "c194b80a",
   "metadata": {},
   "outputs": [],
   "source": [
    "EPOCHS = 10\n",
    "\n",
    "callbacks = [\n",
    "    tf.keras.callbacks.EarlyStopping(patience=3, restore_best_weights=True),\n",
    "    tf.keras.callbacks.ReduceLROnPlateau(patience=2, factor=0.5),\n",
    "]\n",
    "\n",
    "history1 = model.fit(train_ds, validation_data=val_ds,\n",
    "                     epochs=EPOCHS, callbacks=callbacks)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "db86b098",
   "metadata": {},
   "source": [
    "## 6. Phase 2 — Fine-tune Top Layers"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "03be4e84",
   "metadata": {},
   "outputs": [],
   "source": [
    "FINE_TUNE_EPOCHS = 5\n",
    "\n",
    "base.trainable = True\n",
    "for layer in base.layers[:-40]:   # only top 40 layers trainable\n",
    "    layer.trainable = False\n",
    "\n",
    "model.compile(optimizer=tf.keras.optimizers.Adam(1e-5),  # low LR!\n",
    "              loss='sparse_categorical_crossentropy',\n",
    "              metrics=['accuracy'])\n",
    "\n",
    "history2 = model.fit(train_ds, validation_data=val_ds,\n",
    "                     epochs=FINE_TUNE_EPOCHS)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "514d33af",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Training curves (both phases combined)\n",
    "h = {k: history1.history[k] + history2.history[k]\n",
    "     for k in history1.history}\n",
    "hist_df = pd.DataFrame(h)\n",
    "\n",
    "fig, axes = plt.subplots(1, 2, figsize=(12, 4))\n",
    "axes[0].plot(hist_df['accuracy'], label='train')\n",
    "axes[0].plot(hist_df['val_accuracy'], label='val')\n",
    "axes[0].axvline(len(history1.history['accuracy']) - 1, ls='--', c='gray')\n",
    "axes[0].set_title('Accuracy'); axes[0].legend()\n",
    "axes[1].plot(hist_df['loss'], label='train')\n",
    "axes[1].plot(hist_df['val_loss'], label='val')\n",
    "axes[1].axvline(len(history1.history['loss']) - 1, ls='--', c='gray')\n",
    "axes[1].set_title('Loss'); axes[1].legend()\n",
    "plt.tight_layout()\n",
    "plt.show()\n",
    "\n",
    "print(f\"Final val accuracy: {hist_df['val_accuracy'].iloc[-1]:.4f}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "87d1862f",
   "metadata": {},
   "source": [
    "## 7. Evaluation — scikit-learn"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "21b27066",
   "metadata": {},
   "outputs": [],
   "source": [
    "from sklearn.metrics import classification_report, confusion_matrix\n",
    "\n",
    "y_true, y_pred = [], []\n",
    "for images, labels in val_ds:\n",
    "    preds = model.predict(images, verbose=0)\n",
    "    y_true.extend(labels.numpy())\n",
    "    y_pred.extend(np.argmax(preds, axis=1))\n",
    "\n",
    "print(classification_report(y_true, y_pred, target_names=class_names))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "1643a725",
   "metadata": {},
   "outputs": [],
   "source": [
    "cm = confusion_matrix(y_true, y_pred)\n",
    "plt.figure(figsize=(12, 10))\n",
    "plt.imshow(cm, cmap='Greens')\n",
    "plt.colorbar()\n",
    "ticks = np.arange(NUM_CLASSES)\n",
    "plt.xticks(ticks, class_names, rotation=90, fontsize=7)\n",
    "plt.yticks(ticks, class_names, fontsize=7)\n",
    "plt.xlabel('Predicted'); plt.ylabel('True')\n",
    "plt.title('Confusion Matrix')\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "9c4ed631",
   "metadata": {},
   "source": [
    "## 8. Export TFLite Model (float16 quantized)\n",
    "\n",
    "This is the file the Flutter app loads."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "db26eee1",
   "metadata": {},
   "outputs": [],
   "source": [
    "converter = tf.lite.TFLiteConverter.from_keras_model(model)\n",
    "converter.optimizations = [tf.lite.Optimize.DEFAULT]\n",
    "converter.target_spec.supported_types = [tf.float16]\n",
    "tflite_model = converter.convert()\n",
    "\n",
    "with open('plant_disease_model.tflite', 'wb') as f:\n",
    "    f.write(tflite_model)\n",
    "\n",
    "with open('labels.txt', 'w') as f:\n",
    "    f.write('\\n'.join(class_names))\n",
    "\n",
    "print(f\"TFLite size: {len(tflite_model)/1e6:.1f} MB\")\n",
    "print(f\"Labels: {NUM_CLASSES} classes written to labels.txt\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "327dbf33",
   "metadata": {},
   "outputs": [],
   "source": [
    "# Sanity check: run one inference with the TFLite interpreter\n",
    "interpreter = tf.lite.Interpreter(model_content=tflite_model)\n",
    "interpreter.allocate_tensors()\n",
    "inp = interpreter.get_input_details()[0]\n",
    "out = interpreter.get_output_details()[0]\n",
    "print(\"Input :\", inp['shape'], inp['dtype'])\n",
    "print(\"Output:\", out['shape'], out['dtype'])\n",
    "\n",
    "# test with one validation image (raw 0-255 floats, like the Flutter app sends)\n",
    "for images, labels in val_ds.take(1):\n",
    "    test_img = images[0:1].numpy().astype(np.float32)\n",
    "    interpreter.set_tensor(inp['index'], test_img)\n",
    "    interpreter.invoke()\n",
    "    scores = interpreter.get_tensor(out['index'])[0]\n",
    "    print(f\"\\nTrue     : {class_names[labels[0]]}\")\n",
    "    print(f\"Predicted: {class_names[np.argmax(scores)]} ({scores.max():.2%})\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "9df16404",
   "metadata": {},
   "source": [
    "## 9. Download Files for the Flutter App\n",
    "\n",
    "Copy both files into `flutter_app/assets/models/` then run `flutter pub get && flutter run`."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "53fff00f",
   "metadata": {},
   "outputs": [],
   "source": [
    "from google.colab import files\n",
    "files.download('plant_disease_model.tflite')\n",
    "files.download('labels.txt')"
   ]
  }
 ],
 "metadata": {
  "accelerator": "GPU",
  "colab": {
   "gpuType": "T4",
   "provenance": []
  },
  "kernelspec": {
   "display_name": "Python 3",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
