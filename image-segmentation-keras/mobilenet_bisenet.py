import tensorflow as tf
from tensorflow.keras.layers import Reshape, UpSampling2D, ZeroPadding2D
from tensorflow.keras.models import Model
from keras_segmentation.models.bisenet import mobilenet_bisenet

# Define your vgg_unet model with the desired input shape and number of classes
model = mobilenet_bisenet(n_classes=21, input_height=256, input_width=256)

EPOCH = 15
# model.train(
#     train_images="dataset1/dataset1/images_prepped_train/",
#     train_annotations="dataset1/dataset1/annotations_prepped_train/",
#     checkpoints_path="mobilenet_bisenet/vgg_unet_1", epochs=5
# )

model.train(
    train_images="data/images/",
    train_annotations="data/masks/",
    checkpoints_path="mobilenet_bisenet/mobilenet_bisenet_2",
    epochs=EPOCH,
)
# steps_per_epoch=159,
#     val_steps_per_epoch=159,
model.train(
    train_images="data/augmented_images/",
    train_annotations="data/augmented_masks/",
    checkpoints_path="mobilenet_bisenet/mobilenet_bisenet_3",
    epochs=EPOCH
)

# this is submean, not  sub_and_divide. rename the file later
model_name = f"mobilenet_bisenet_{EPOCH}epoch_submean"
#TODO: AS OF NOW, ONLY vggnet_15epoch_512steps_augmentation.tflite works nicely, try see what is the problem

# ======= Revised Code Starts Here =======

# Get the last layer of the model
output_layer = model.output  # Shape: (None, 4096, 21)

# Reshape back to (64, 64, 21)
reshaped_output = Reshape((64, 64, 21))(output_layer)  # Now shape is (None, 64, 64, 21)

# Upsample to (128, 128, 21)
upsampled_output = UpSampling2D(size=(2, 2))(reshaped_output)  # Shape: (None, 128, 128, 21)

# Upsample again to (256, 256, 21)
upsampled_output = UpSampling2D(size=(2, 2))(upsampled_output)  # Shape: (None, 256, 256, 21)

# Add padding to reach (257, 257, 21) if required
final_output = ZeroPadding2D(padding=((0, 1), (0, 1)))(upsampled_output)  # Shape: (None, 257, 257, 21)

# Ensure the final output shape is exactly (1, 256, 256, 21) by adding an extra dimension if needed
final_output = Reshape((257, 257, 21))(final_output)

# Create the new model with the adjusted output
model = Model(inputs=model.input, outputs=final_output)

# Compile the model
model.compile(optimizer='adam', loss='categorical_crossentropy')

# ======= Revised Code Ends Here =======


print(model.summary())
print("===============Output shape: " + str(model.output_shape))


# Save the model in .h5 format
model.save(f"models/{model_name}.h5")
print(f"Keras model saved successfully as {model_name}.h5")

# Convert to TFLite and enforce the shape
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Save the TFLite model
with open(f"models/{model_name}.tflite", "wb") as f:
    f.write(tflite_model)

print(f"TFLite model saved successfully as models/{model_name}.tflite")
