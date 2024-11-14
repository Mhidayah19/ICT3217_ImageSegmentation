#!/bin/bash

# Folder ID from Google Drive
FOLDER_ID="1jpocvOx3MR-P3d85xIKgn2hkmqieJX8F"
DEST_FOLDER="./assets/"

# Check if Python is installed
if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
    echo "Python is not installed. Please install Python first."
    exit 1
fi

# Check if gdown is installed
if ! python3 -m pip show gdown &> /dev/null && ! python -m pip show gdown &> /dev/null; then
    echo "gdown is not installed. Installing gdown..."
    python3 -m pip install gdown || python -m pip install gdown
    if [ $? -ne 0 ]; then
        echo "Failed to install gdown. Please install it manually with 'pip install gdown'."
        exit 1
    fi
fi

# Download the entire folder
gdown --folder "https://drive.google.com/drive/folders/$FOLDER_ID" -O $DEST_FOLDER

echo "All files downloaded from the folder!"
