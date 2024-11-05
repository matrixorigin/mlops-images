## 如何构建镜像
1. 将模型文件放到 yolo 目录下的 weights/detection 子目录内，比如：
- "yolov8n.pt",
- "yolov8s.pt",
- "yolov11n.pt",
- "best.pt"
因此模型文件在镜像内的位置为：/root/yolo/weights/detection/，根据自己的需要下载模型到该位置。

2. 在 Dockerfile 所在目录运行构建脚本，比如
```
docker build -t images.neolink-ai.com/matrixdc/yolo:11-ultralytics-v8.3.27 .
```
启动镜像时，会在 /root/yolo 目录，运行 streamlit run app.py 来启动 streamlit 应用。


## 基本工作方式
### 推理测试页面,yolo文件夹内运行
streamlit run app.py 
### 此镜像环境包含Ultralytics库中的所有模型均可以使用
### 若使用自己训练的yolo模型需要修改config.py里面的配置
DETECTION_MODEL_DIR = ROOT / 'weights' / 'detection'
YOLOv8n = DETECTION_MODEL_DIR / "yolov8n.pt"
YOLOv8s = DETECTION_MODEL_DIR / "yolov8s.pt"
YOLOv11n = DETECTION_MODEL_DIR / "yolov11n.pt"

DETECTION_MODEL_LIST = [
    "yolov8n.pt",
    "yolov8s.pt",
    "yolov11n.pt"
    ]
* 写入路径，默认模型文件置于weights/detection
