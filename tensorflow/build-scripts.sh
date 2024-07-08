#!/bin/sh
# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04

BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

PYTHON_VERSION=3.10
# miniconda的安装包均放在：https://repo.anaconda.com/miniconda/。根据要安装的python版本、操作系统，选择对应的miniconda安装包。
MINICONDA_PKG=Miniconda3-py310_24.5.0-0-Linux-x86_64.sh

# tensorRT pip安装tensorRT后，需要指定软连接到/usr/lib下，否则会报tensorRT not found
TENSORRT_VERSION=8.6.1
CU_VERSION='' # 如果不填默认-cu12，也可指定-cu11

# 从 TensorFlow 2.1 开始，pip 包 tensorflow 即同时包含 GPU 支持，无需通过特定的 pip 包 tensorflow-gpu 安装 GPU 版本。
# 如果安装tensorflow-gpu:1.x版本,则TENSORFLOW_TYPE设为tensorflow-gpu，TENSORFLOW_VERSION设为1.x
TENSORFLOW_TYPE=tensorflow
TENSORFLOW_VERSION=2.15.0


# 构建后的镜像tag，需要体现tensorflow、python、基础镜像版本信息
IMAGE_TAG=${TENSORFLOW_VERSION}-python${PYTHON_VERSION}-cuda12.1.0-cudnn8-devel-ubuntu22.04

docker build \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
    --build-arg MINICONDA_PKG=${MINICONDA_PKG} \
    --build-arg TENSORRT_VERSION=${TENSORRT_VERSION} \
    --build-arg CU_VERSION=${CU_VERSION} \
    --build-arg TENSORFLOW_TYPE=${TENSORFLOW_TYPE} \
    --build-arg TENSORFLOW_VERSION=${TENSORFLOW_VERSION} \
    -t tensorflow:${IMAGE_TAG} \
    -f ./Dockerfile \
    .