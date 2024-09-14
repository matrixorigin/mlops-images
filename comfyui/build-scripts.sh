#!/bin/sh

# 设置基础镜像
BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04
# 构建后的镜像 tag

IMAGE_TAG=comfyui-megapack-base-cu12.1-cudnn8-ubuntu22.04

# Docker build 命令
docker buildx build --platform linux/amd64 \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    -t ${IMAGE_TAG} \
    .