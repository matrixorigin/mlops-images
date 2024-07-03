#!/bin/sh

# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04

BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

PYTHON_VERSION=3.8

#根据官方对应pytorch pip安装命令中指定https://pytorch.org/get-started/previous-versions/
# PYTORCH参数
PYTORCH_VERSION=2.3.0
PYTORCH_VERSION_SUFFIX=
TORCHVISION_VERSION=0.18.0
TORCHVISION_VERSION_SUFFIX=
TORCHAUDIO_VERSION=2.3.0
TORCHAUDIO_VERSION_SUFFIX=
PYTORCH_DOWNLOAD_URL=https://download.pytorch.org/whl/cu121

# 构建后的镜像tag，需要体现pytorch、python、基础镜像版本信息
IMAGE_TAG=${PYTORCH_VERSION}-python${PYTHON_VERSION}-cuda12.1.0-cudnn8-devel-ubuntu22.04

docker build \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
    --build-arg PYTORCH_VERSION=${PYTORCH_VERSION} \
    --build-arg PYTORCH_VERSION_SUFFIX=${PYTORCH_VERSION_SUFFIX} \
    --build-arg TORCHVISION_VERSION=${TORCHVISION_VERSION} \
    --build-arg TORCHVISION_VERSION_SUFFIX=${TORCHVISION_VERSION_SUFFIX} \
    --build-arg TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION} \
    --build-arg TORCHAUDIO_VERSION_SUFFIX=${TORCHAUDIO_VERSION_SUFFIX} \
    --build-arg PYTORCH_DOWNLOAD_URL=${PYTORCH_DOWNLOAD_URL} \
    -t pytorch:${IMAGE_TAG} \
    -f ./Dockerfile \
    .
