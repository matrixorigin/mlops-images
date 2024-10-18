## ComfyUI 镜像

源码地址Matrix空间仓库：https://github.com/matrixorigin/comfyui/blob/main/README.md

基于comfyui megapack打包。为了降低镜像的大小，在`./runner-scripts/download.sh`注释了部分可下载的comfyui插件，用户可以根据自己的需求，在镜像实例启动后选择性下载。

### 打包镜像:

本地`bash ./build-scripts.sh`

## 使用构建好的镜像启动容器，

映射 SSH 端口为 22, jupypter 8888, tensorflow 6006, comfyui 3000

```
docker run -d -ti \
--restart=always \
--name comfyui \
--gpus all \
-p 22:22 \
-p 6006:6006 \
-p 8888:8888 \
-p 3000:3000 \
comfyui-megapack-base-cu12.1-cudnn8-ubuntu22.04
```

