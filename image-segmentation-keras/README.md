Link to the full blog post with tutorial : https://divamgupta.com/image-segmentation/2019/06/06/deep-learning-semantic-segmentation-keras.html

Git Clone this project

This is to enable long path if you face any error that says long path disabled
On PowerShell (Administrator):
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
-Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

On Command Prompt (Administrator):

- cd image-segmentation-keras
- python -m venv venv
- venv\Scripts\activate
- pip install .
- pip install --upgrade pip
- pip uninstall tensorflow
- pip install tensorflow --no-cache-dir
- pip install --upgrade numpy pandas
- pip install opencv-python
- pip install matplotlib

To Train model
python mobilenet_unet.py
python mobilenet_bisenet.py

To do Inference on model
python infer_model.py
