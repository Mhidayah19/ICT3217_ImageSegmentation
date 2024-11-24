import numpy as np
import cv2
import tensorflow as tf
import matplotlib.pyplot as plt
from collections import Counter
from tensorflow.keras.models import load_model

# replace this with whatever model that is created
TFLITE_MODEL = "models/mobilenet_unet_10epoch_submean.tflite"
IMAGE_PATH = "data/excess_images/road.png"
INFER_OPTION = "all"    # Either 'all' or 'specific'

# Load the TFLite model
# tflite_model_path = "models/mobilenet_unet_10epoch_submean.tflite"
tflite_model_path = TFLITE_MODEL
interpreter = tf.lite.Interpreter(model_path=tflite_model_path)
interpreter.allocate_tensors()

# Get model input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("Input Details: ", input_details)
print("Output Details: ", output_details)


# Preprocessing function
def preprocess_image(image_path, input_size):
    image = cv2.imread(image_path)
    resized_image = cv2.resize(image, (input_size[1], input_size[2]))
    resized_image = resized_image.astype(np.float32)
    # this is because we are using sub_mean in data_loader.py get_image_array
    resized_image[:, :, 0] -= 103.939
    resized_image[:, :, 1] -= 116.779
    resized_image[:, :, 2] -= 123.68
    return np.expand_dims(resized_image, axis=0), image

# Load and preprocess the input image
image_path = IMAGE_PATH
input_size = input_details[0]['shape']
preprocessed_image, original_image = preprocess_image(image_path, input_size)

# Set input tensor and run inference
interpreter.set_tensor(input_details[0]['index'], preprocessed_image)
interpreter.invoke()

# Get the output tensor
output_data = interpreter.get_tensor(output_details[0]['index'])
segmentation_map = np.argmax(output_data, axis=-1).squeeze()

# Log the unique classes inferred in the segmentation map
unique_classes = np.unique(segmentation_map)
class_counts = Counter(segmentation_map.flatten())

print("Unique classes detected in the segmentation map:", unique_classes)
print("Class counts:", dict(class_counts))

# Map class indices to class names
class_names = [
    "sidewalk",
    "road",
    "pole",
    "egovehicle",
    "person",
    "sky",
    "vegetation",
    "trafficlight",
    "building",
    "trafficsign",
    "fence",
    "car",
    "guardrail",
    "static",
    "parking",
    "bus",
    "outofroi",
    "adversarial",
    "truck",
    "bridge",
    "terrain"
]

for class_id in unique_classes:
    if class_id < len(class_names):
        print(
            f"Class {class_id}: {class_names[class_id]} - Count: {class_counts[class_id]}")

# Define the mode: 'specific' for a specific class, 'all' for all labels
mode = INFER_OPTION

if mode == "specific":
    # Infer for a specific class (e.g., "road")
    desired_class = "road"
    desired_class_index = class_names.index(desired_class)

    # Create a mask for the desired class
    filtered_segmentation_map = np.where(
        segmentation_map == desired_class_index, 1, 0
    )

    # Resize the filtered segmentation map to match the original image
    filtered_segmentation_map_resized = cv2.resize(
        filtered_segmentation_map.astype(np.uint8),
        (original_image.shape[1], original_image.shape[0]),
        interpolation=cv2.INTER_NEAREST,
    )

    # Overlay the filtered segmentation map on the original image
    overlay = original_image.copy()
    alpha = 0.5  # Transparency factor
    color_map = np.zeros_like(original_image)

    # Assign a color for the desired class (e.g., green for "road")
    color_map[filtered_segmentation_map_resized == 1] = [0, 255, 0]  # RGB for green

    # Create the overlay
    overlay = cv2.addWeighted(original_image, 1 - alpha, color_map, alpha, 0)

    # Visualization
    plt.figure(figsize=(10, 10))
    plt.imshow(cv2.cvtColor(overlay, cv2.COLOR_BGR2RGB))
    plt.title(f"Filtered Segmentation Map: {desired_class}")
    plt.axis("off")
    plt.show()

elif mode == "all":
    # Overlay all classes on the original image
    overlay = original_image.copy()
    alpha = 0.5  # Transparency factor
    color_map = np.zeros_like(original_image)

    # Dictionary to store colors for each class
    class_colors = {}

    # Loop through all unique classes and assign random colors
    for class_id in np.unique(segmentation_map):
        if class_id < len(class_names):
            # Generate a random color for the class
            random_color = np.random.randint(0, 255, size=(3,), dtype=np.uint8)

            # Save the random color for the legend
            class_colors[class_id] = random_color

            # Create a mask for the current class
            class_mask = (segmentation_map == class_id).astype(np.uint8)

            # Resize the mask to match the original image
            class_mask_resized = cv2.resize(
                class_mask, 
                (original_image.shape[1], original_image.shape[0]), 
                interpolation=cv2.INTER_NEAREST
            )

            # Assign the random color to the class in the color map
            color_map[class_mask_resized == 1] = random_color

    # Create the overlay
    overlay = cv2.addWeighted(original_image, 1 - alpha, color_map, alpha, 0)

    # Visualization
    plt.figure(figsize=(10, 10))
    plt.imshow(cv2.cvtColor(overlay, cv2.COLOR_BGR2RGB))
    plt.title("Segmentation Map: All Classes")
    plt.axis("off")
    plt.show()
