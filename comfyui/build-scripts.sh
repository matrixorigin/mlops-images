#!/bin/sh

# 设置基础镜像
BASE_IMAGE=nvidia/cuda:12.1.0-runtime-ubuntu22.04
# 构建后的镜像 tag

PYTHON_VERSION=3.11
# miniconda的安装包均放在：https://repo.anaconda.com/miniconda/。根据要安装的python版本、操作系统，选择对应的miniconda安装包。
MINICONDA_PKG=Miniconda3-py311_24.7.1-0-Linux-x86_64.sh

# 构建后的镜像tag，需要体现pytorch、python、基础镜像版本信息
IMAGE_TAG=comfyui-${PYTHON_VERSION}-cuda12.1.0-runtime-ubuntu22.04

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
