#!/bin/sh

# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04
BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

PYTHON_VERSION=3.10
# miniconda的安装包均放在：https://repo.anaconda.com/miniconda/。根据要安装的python版本、操作系统，选择对应的miniconda安装包。
MINICONDA_PKG=Miniconda3-py310_24.5.0-0-Linux-x86_64.sh

# 构建后的镜像tag，需要体现pytorch、python、基础镜像版本信息
IMAGE_TAG=python${PYTHON_VERSION}-cuda12.1.0-cudnn8-devel-ubuntu22.04

# 复制init 文件
cp -r ../common/init ./init

docker build \
  --build-arg BASE_IMAGE=${BASE_IMAGE} \
  --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
  --build-arg MINICONDA_PKG=${MINICONDA_PKG} \
  -t ollama-webui:${IMAGE_TAG} \
  -f ./Dockerfile \
  .

#  移出init
rm -rf ./init
