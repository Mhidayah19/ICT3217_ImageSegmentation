from keras.models import Model
from keras.layers import Input, Conv2D, BatchNormalization, Activation, MaxPooling2D
from keras.layers import UpSampling2D, concatenate, GlobalAveragePooling2D, Dense, Multiply, Add, Reshape
from keras.layers import Lambda
from .model_utils import get_segmentation_model
from .mobilenet import get_mobilenet_encoder
import tensorflow as tf


def _bisenet(n_classes, encoder, input_height=416, input_width=608, channels=3):
    """
    BiSeNet implementation using get_segmentation_model.
    """

    # Get the encoder feature maps (backbone)
    img_input, levels = encoder(input_height=input_height, input_width=input_width, channels=channels)
    [f1, f2, f3, f4, f5] = levels  # Extracted feature maps from encoder

    # Spatial Path (Captures high-resolution spatial details)
    spatial = Conv2D(64, (7, 7), strides=2, padding='same', activation='relu', name="spatial_conv1")(img_input)
    spatial = BatchNormalization()(spatial)
    spatial = Conv2D(64, (3, 3), strides=2, padding='same', activation='relu', name="spatial_conv2")(spatial)
    spatial = BatchNormalization()(spatial)
    spatial = Conv2D(64, (3, 3), strides=2, padding='same', activation='relu', name="spatial_conv3")(spatial)
    spatial = BatchNormalization()(spatial)

    # Context Path (Captures rich contextual details)
    # Global Average Pooling for the deepest layer
    global_context = GlobalAveragePooling2D()(f5)
    global_context = Reshape((1, 1, global_context.shape[-1]))(global_context)
    global_context = Conv2D(128, (1, 1), activation='relu', name="global_context_conv")(global_context)
    global_context = BatchNormalization()(global_context)
    global_context = UpSampling2D(size=(f5.shape[1], f5.shape[2]), name="global_context_upsample")(global_context)

    # Combine global context with f5
    f5_reduced = Conv2D(128, (1, 1), activation='relu', name="f5_reduce_conv")(f5)
    f5_reduced = BatchNormalization()(f5_reduced)
    context = Add(name="context_add")([global_context, f5_reduced])

    # UpSample and combine f4 and context
    context = UpSampling2D((2, 2), name="context_upsample1")(context)
    f4_reduced = Conv2D(128, (1, 1), activation='relu', name="f4_reduce_conv")(f4)
    f4_reduced = BatchNormalization()(f4_reduced)
    context = Add(name="context_add_f4")([context, f4_reduced])

    # Upsample context output to final resolution
    context_upsampled = UpSampling2D(size=(4, 4), name="context_upsample_to_final")(context)  # Assuming final size is 128x128

    # Upsample spatial output to match context resolution
    spatial_upsampled = UpSampling2D(
        size=(context_upsampled.shape[1] // spatial.shape[1], context_upsampled.shape[2] // spatial.shape[2]),
        name="spatial_upsample_to_context"
    )(spatial)

    # Feature Fusion Module
    fusion = concatenate([spatial_upsampled, context_upsampled], axis=-1, name="fusion_concat")
    fusion = Conv2D(128, (1, 1), activation='relu', name="fusion_conv")(fusion)
    fusion = BatchNormalization()(fusion)

    # Channel Attention
    # attention = GlobalAveragePooling2D()(fusion)
    # attention = Dense(128, activation='relu', name="attention_dense1")(attention)
    # attention = Dense(128, activation='sigmoid', name="attention_dense2")(attention)
    # attention = Multiply(name="attention_mul")([fusion, attention])
    
    # Modified Channel Attention without Dense layers
    attention = GlobalAveragePooling2D()(fusion)
    attention = Reshape((1, 1, attention.shape[-1]))(attention)
    attention = Conv2D(128, (1, 1), activation='relu', name="attention_conv1")(attention)
    attention = Conv2D(128, (1, 1), activation='sigmoid', name="attention_conv2")(attention)
    attention = Multiply(name="attention_mul")([fusion, attention])

    # Final segmentation head
    o = Conv2D(n_classes, (1, 1), activation='softmax', padding='same', name="output_layer")(attention)

    # Create the segmentation model
    model = get_segmentation_model(img_input, o)

    return model




def mobilenet_bisenet(n_classes, input_height=224, input_width=224, channels=3):
    """
    Mobilenet-based BiSeNet model.
    """
    model = _bisenet(n_classes, get_mobilenet_encoder,
                     input_height=input_height, input_width=input_width, channels=channels)
    model.model_name = "mobilenet_bisenet"
    return model


# Example Usage
if __name__ == "__main__":
    # Instantiate the BiSeNet model
    model = mobilenet_bisenet(n_classes=21, input_height=224, input_width=224)
    model.summary()  # Display model architecture
