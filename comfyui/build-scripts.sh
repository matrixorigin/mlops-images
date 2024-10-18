#!/bin/sh

# 设置基础镜像
BASE_IMAGE=nvidia/cuda:12.1.0-runtime-ubuntu22.04
# 构建后的镜像 tag
IMAGE_TAG=comfyui-cuda:12.1.0-runtime-ubuntu22.04

if [ ! -f ./sd_xl_base_1.0_0.9vae.safetensors ]; then
  wget -c https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0_0.9vae.safetensors
fi
if [ ! -f ./flux1-dev-fp8.safetensors ]; then
  wget -c https://huggingface.co/Comfy-Org/flux1-dev/resolve/main/flux1-dev-fp8.safetensors
fi

# 复制init 文件
cp -r ../common/init ./init

SD_IMAGE_TAG=images.neolink-ai.com/18588960404/comfyui:0.22-SDXL-python3.11-pytorch2.4.1-cuda12.1.0-ubuntu22.04
FLUX_IMAGE_TAG=images.neolink-ai.com/18588960404/comfyui:0.22-Flux.1-python3.11-pytorch2.4.1-cuda12.1.0-ubuntu22.04

# Docker build 命令 for SD
if ! docker images | grep "$SD_IMAGE_TAG" > /dev/null; then
    docker build --platform linux/amd64 \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg MODEL_TYPE=MGSD \
    --build-arg MODEL_VERSION=sd_xl_base_1.0_0.9vae.safetensors \
    -t ${IMAGE_TAG} \
    .
    docker tag comfyui-cuda:12.1.0-runtime-ubuntu22.04 "$SD_IMAGE_TAG"
    docker push "$SD_IMAGE_TAG"
fi

# Docker build 命令 for FLUX
if ! docker images | grep "$FLUX_IMAGE_TAG" > /dev/null; then
    docker build --platform linux/amd64 \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg MODEL_TYPE=MGFLUX \
    --build-arg MODEL_VERSION=flux1-dev-fp8.safetensors \
    -t ${IMAGE_TAG} \
    .
  docker tag comfyui-cuda:12.1.0-runtime-ubuntu22.04 "$FLUX_IMAGE_TAG"
  docker push "$FLUX_IMAGE_TAG"
fi

#  移出init
rm -rf ./init
