
from pathlib import Path
import sys

# Get the absolute path of the current file
file_path = Path(__file__).resolve()

# Get the parent directory of the current file
root_path = file_path.parent

# Add the root path to the sys.path list if it is not already there
if root_path not in sys.path:
    sys.path.append(str(root_path))

# Get the relative path of the root directory with respect to the current working directory
ROOT = root_path.relative_to(Path.cwd())

# Source
SOURCES_LIST = ["Image", "Video", "Webcam"]
import os

# 文件夹路径，替换为包含.pt文件的文件夹路径
models_dir = "/root/yolo/weights/detection/"

DETECTION_MODEL_LIST = [
    "yolov8n.pt",
    "yolov8s.pt",
    "yolov11n.pt",
    "best.pt"
]

# 检查文件夹是否存在
if os.path.exists(models_dir):
    # 列出文件夹中所有的.pt文件
    DETECTION_MODEL_LIST = [f for f in os.listdir(models_dir) if f.endswith('.pt')]
    
    # 如果文件夹为空或没有.pt文件，提示用户
    if not DETECTION_MODEL_LIST:
        print("未找到任何.pt文件，请检查路径。")
else:
    print(f"文件夹 {models_dir} 不存在，请检查路径。")

# 输出模型列表
print("检测到的模型文件：", DETECTION_MODEL_LIST)

# DL model config
DETECTION_MODEL_DIR = ROOT / 'weights' / 'detection'
# YOLOv8n = DETECTION_MODEL_DIR / "yolov8n.pt"
# YOLOv8s = DETECTION_MODEL_DIR / "yolov8s.pt"
# YOLOv11n = DETECTION_MODEL_DIR / "yolov11n.pt"
# YOLOv11n = DETECTION_MODEL_DIR / "best.pt"
