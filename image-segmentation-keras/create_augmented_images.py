import albumentations as A
import cv2
import os
from tqdm import tqdm

# Augmentation function using Albumentations
augmentation = A.Compose([
    A.HorizontalFlip(p=0.5),
    A.VerticalFlip(p=0.5),
    A.RandomRotate90(p=0.5),
    A.RandomBrightnessContrast(
        brightness_limit=0.2, contrast_limit=0.2, p=0.5),
    A.RandomGamma(p=0.5),
    A.CLAHE(p=0.5),
    A.GaussNoise(var_limit=(10.0, 50.0), p=0.5),
    A.GaussianBlur(p=0.5),
    A.MotionBlur(p=0.5),
    A.Rotate(limit=45, p=0.5),
    A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.1,
                       rotate_limit=45, p=0.5),
    A.GridDistortion(p=0.5),
    A.OpticalDistortion(p=0.5),
    A.ElasticTransform(p=0.5),
    A.HueSaturationValue(p=0.5),
    A.ChannelShuffle(p=0.5),
    A.Resize(height=256, width=256, always_apply=True),
], additional_targets={'mask': 'mask'})


def augment_and_save(input_images_dir, input_masks_dir, output_images_dir, output_masks_dir, num_augmentations=5):
    os.makedirs(output_images_dir, exist_ok=True)
    os.makedirs(output_masks_dir, exist_ok=True)

    image_files = os.listdir(input_images_dir)
    for image_file in tqdm(image_files):
        image_path = os.path.join(input_images_dir, image_file)
        # Assuming masks have the same names
        mask_path = os.path.join(input_masks_dir, image_file)

        # Read image and mask
        image = cv2.imread(image_path)
        mask = cv2.imread(mask_path, 0)  # Mask in grayscale

        # Check if image and mask are loaded correctly
        if image is None or mask is None:
            print(
                f"Warning: Could not read {image_file} or its mask. Skipping.")
            continue

        # Save original image and mask
        cv2.imwrite(os.path.join(output_images_dir, image_file), image)
        cv2.imwrite(os.path.join(output_masks_dir, image_file), mask)

        # Apply augmentation multiple times
        for i in range(num_augmentations):
            augmented = augmentation(image=image, mask=mask)
            augmented_image = augmented['image']
            augmented_mask = augmented['mask']

            # Generate new file names for augmented images and masks
            base_name, ext = os.path.splitext(image_file)
            augmented_image_name = f"{base_name}_aug_{i}{ext}"
            augmented_mask_name = f"{base_name}_aug_{i}{ext}"

            # Save augmented image and mask
            cv2.imwrite(os.path.join(output_images_dir,
                        augmented_image_name), augmented_image)
            cv2.imwrite(os.path.join(output_masks_dir,
                        augmented_mask_name), augmented_mask)


# Paths for augmented dataset
augmented_images_dir = "data/augmented_images/"
augmented_masks_dir = "data/augmented_masks/"

# Augment the dataset
augment_and_save("data/images/", "data/masks/",
                 augmented_images_dir, augmented_masks_dir, num_augmentations=5)
