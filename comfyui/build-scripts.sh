#!/bin/sh

# 设置基础镜像

# 构建后的镜像 tag
IMAGE_TAG=comfyui-cu121-megapak

# Docker build 命令
docker buildx build --platform linux/amd64 \
    -t ${IMAGE_TAG} \
    .