@echo off

:: Folder ID from your shared Google Drive link
set FOLDER_ID=1jpocvOx3MR-P3d85xIKgn2hkmqieJX8F

:: Destination folder in your Flutter project (relative path)
set DEST_FOLDER=.\assets\models

:: Check if Python is installed
where python >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Python is not installed. Please install Python first.
    exit /b 1
)

:: Check if gdown is installed
pip show gdown >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo gdown is not installed. Installing gdown...
    pip install gdown
    if %ERRORLEVEL% neq 0 (
        echo Failed to install gdown. Please install it manually with 'pip install gdown'.
        exit /b 1
    )
)

:: Create the destination folder if it doesn't exist
if not exist %DEST_FOLDER% (
    mkdir %DEST_FOLDER%
)

:: Download the entire folder to the specified destination
gdown --folder "https://drive.google.com/drive/folders/%FOLDER_ID%" -O %DEST_FOLDER%

:: Check if the download was successful
if %ERRORLEVEL% neq 0 (
    echo Download failed. Please check your folder link and permissions.
    exit /b 1
)

echo All files downloaded to %DEST_FOLDER%
pause
