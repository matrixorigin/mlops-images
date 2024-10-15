#!/bin/sh

# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04

PYTHON_VERSION=3.10
RAY_VERSION=2.36.1
# miniconda的安装包均放在：https://repo.anaconda.com/miniconda/。根据要安装的miniconda版本、python版本、操作系统，选择对应的miniconda安装包。
MINICONDA_PKG=Miniconda3-py310_24.5.0-0-Linux-x86_64.sh

# BASE_IMAGE=ubuntu:22.04
BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# 构建后的镜像tag，需要体现pytorch、python、基础镜像版本信息
IMAGE_TAG_HEAD=workspace-${RAY_VERSION}-python${PYTHON_VERSION}-cuda12.4.1
# TODO there is no cu124 image under docker.io/rayproject for now
IMAGE_TAG_WORKER=2.36.1-py310-cu123

REGISTRY=${REGISTRY:-images.neolink-ai.com/matrixdc}

DOCKER_BUILDKIT=1

EXTRA_ARGS="$@"

# Build head
echo "\e[1;33mBuilding ${REGISTRY}/ray:${IMAGE_TAG_HEAD}\e[0m"

docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg MINICONDA_PKG=${MINICONDA_PKG} \
    --build-arg RAY_VERSION=${RAY_VERSION} \
    $EXTRA_ARGS \
    -t ${REGISTRY}/ray:${IMAGE_TAG_HEAD} \
    -f ./Dockerfile \
    .

if [ $? -ne 0 ]; then
    echo "build ${IMAGE_TAG_HEAD} failed, exiting."
    exit 1
fi

echo "\e[1;33mBuilding ${REGISTRY}/ray:${IMAGE_TAG_HEAD}-torch\e[0m"

docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_IMAGE=${REGISTRY}/ray:${IMAGE_TAG_HEAD} \
    $EXTRA_ARGS \
    -t ${REGISTRY}/ray:${IMAGE_TAG_HEAD}-torch \
    -f ./Dockerfile.torch \
    .

if [ $? -ne 0 ]; then
    echo "build ${IMAGE_TAG_HEAD}-torch failed, exiting."
    exit 1
fi

# Build worker
echo "\e[1;33mBuilding ${REGISTRY}/ray:${IMAGE_TAG_WORKER}-torch\e[0m"

docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_IMAGE=rayproject/ray:${IMAGE_TAG_WORKER} \
    $EXTRA_ARGS \
    -t ${REGISTRY}/ray:${IMAGE_TAG_WORKER}-torch \
    -f ./Dockerfile.torch \
    .
