import numpy as np
import matplotlib.pyplot as plt
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.metrics import classification_report, confusion_matrix
import seaborn as sns

def main():
    # 1. Load the MNIST dataset
    print("Loading MNIST dataset...")
    (x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()

    # 2. Preprocess the data
    # Normalize pixel values to be between 0 and 1
    x_train = x_train.astype("float32") / 255.0
    x_test = x_test.astype("float32") / 255.0

    # Expand dimensions to be (batch, height, width, channels)
    x_train = np.expand_dims(x_train, -1)
    x_test = np.expand_dims(x_test, -1)
    
    print(f"x_train shape: {x_train.shape} - {x_train.shape[0]} train samples")
    print(f"x_test shape: {x_test.shape} - {x_test.shape[0]} test samples")

    # 3. Build the Neural Network Model
    print("\nBuilding model...")
    model = keras.Sequential(
        [
            keras.Input(shape=(28, 28, 1)),
            layers.Conv2D(32, kernel_size=(3, 3), activation="relu"),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Conv2D(64, kernel_size=(3, 3), activation="relu"),
            layers.MaxPooling2D(pool_size=(2, 2)),
            layers.Flatten(),
            layers.Dropout(0.5),
            layers.Dense(10, activation="softmax"),
        ]
    )

    model.summary()

    # 4. Compile the model
    print("\nCompiling model...")
    model.compile(
        loss="sparse_categorical_crossentropy",
        optimizer="adam",
        metrics=["accuracy"]
    )

    # 5. Train the model
    print("\nTraining model...")
    batch_size = 128
    epochs = 5

    history = model.fit(
        x_train, y_train, 
        batch_size=batch_size, 
        epochs=epochs, 
        validation_split=0.1
    )

    # 6. Evaluate the model on test set
    print("\nEvaluating model on test set...")
    score = model.evaluate(x_test, y_test, verbose=0)
    print("Test loss:", score[0])
    print("Test accuracy:", score[1])

    # 7. Generate detailed metrics using sklearn
    print("\nGenerating detailed metrics...")
    y_pred_probs = model.predict(x_test)
    y_pred_classes = np.argmax(y_pred_probs, axis=1)

    print("\nClassification Report (Precision, Recall, F1-Score for each class):")
    print(classification_report(y_test, y_pred_classes))

    # 8. Optional: Confusion Matrix
    print("Generating Confusion Matrix...")
    cm = confusion_matrix(y_test, y_pred_classes)
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.xlabel('Predicted Label')
    plt.ylabel('True Label')
    plt.title('Confusion Matrix')
    
    # Save the figure instead of showing it to avoid blocking execution in headless environments
    plt.savefig('confusion_matrix.png')
    print("Saved confusion matrix as 'confusion_matrix.png'")

if __name__ == "__main__":
    main()
