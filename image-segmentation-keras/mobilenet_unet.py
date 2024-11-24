import tensorflow as tf
from tensorflow.keras.layers import Reshape, UpSampling2D, ZeroPadding2D
from tensorflow.keras.models import Model
from keras_segmentation.models.unet import vgg_unet, mobilenet_unet

# Define your vgg_unet model with the desired input shape and number of classes
model = mobilenet_unet(n_classes=21, input_height=256, input_width=256)

EPOCH = 15
# model.train(
#     train_images="dataset1/dataset1/images_prepped_train/",
#     train_annotations="dataset1/dataset1/annotations_prepped_train/",
#     checkpoints_path="mobilenet_unet_/vgg_unet_1", epochs=5
# )

model.train(
    train_images="data/images/",
    train_annotations="data/masks/",
    checkpoints_path="mobilenet_unet_/mobilenet_unet__2",
    epochs=EPOCH
)

model.train(
    train_images="data/augmented_images/",
    train_annotations="data/augmented_masks/",
    checkpoints_path="mobilenet_unet_/mobilenet_unet__3",
    epochs=EPOCH
)

# this is submean, not  sub_and_divide. rename the file later
model_name = f"mobilenet_unet_{EPOCH}epoch_submean"
#TODO: AS OF NOW, ONLY vggnet_15epoch_512steps_augmentation.tflite works nicely, try see what is the problem

# Need to do the following inorder to match 257, 257 which is what is required for inference
# Get the last layer of the model, which has an output shape of (None, 16384, 21)
output_layer = model.output

# Reshape to (128, 128, 21) to prepare for upsampling
reshaped_output = Reshape((128, 128, 21))(output_layer)

# Upsample to (256, 256, 21)
upsampled_output = UpSampling2D(size=(2, 2))(reshaped_output)

# Add padding to reach 257x257
padded_output = ZeroPadding2D(padding=((0, 1), (0, 1)))(upsampled_output)

# Ensure the final output shape is exactly (1, 256, 256, 21) by adding an extra dimension if needed
final_output = Reshape((257, 257, 21))(padded_output)

# Wrap up into the model
model = Model(inputs=model.input, outputs=final_output)

# Compile the model if needed
model.compile(optimizer='adam', loss='categorical_crossentropy')


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
