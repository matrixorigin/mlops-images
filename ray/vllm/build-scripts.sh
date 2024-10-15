#!/bin/bash

RAY_VERSION=2.36.1
VLLM_VERSION=v0.6.1.post2
MODEL=Qwen/Qwen2-0.5B-Instruct

BASE_IMAGE=rayproject/ray:${RAY_VERSION}-py310-cpu

# CPU
DOCKERFILE_BASE=./Dockerfile.cpu
IMAGE_TAG_BASE=${RAY_VERSION}-py310-cpu-vllm
RAY_IMAGE=rayproject/ray:${RAY_VERSION}-py310-cpu

# GPU
# DOCKERFILE_BASE=./Dockerfile.cuda
# IMAGE_TAG_BASE=${RAY_VERSION}-py310-cu123-vllm
# IMAGE_TAG_MODEL="${RAY_VERSION}-py310-cu123-vllm-$(echo "${MODEL}" | sed 's/[\/]/_/g; s/[-]/_/g; s/\./_/g; s/[A-Z]/\L&/g')"
# RAY_IMAGE=rayproject/ray:${RAY_VERSION}-py310-cu123

REGISTRY=${REGISTRY:-images.neolink-ai.com/matrixdc}

DOCKER_BUILDKIT=1

EXTRA_ARGS="$@"

BOLD_YELLOW='\033[1;33m'
RESET="\033[0m"

echo -e "${BOLD_YELLOW}Building image ${REGISTRY}/ray:${IMAGE_TAG_BASE} ...${RESET}"

docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_IMAGE=${RAY_IMAGE} \
    --build-arg VLLM_VERSION=${VLLM_VERSION} \
    $EXTRA_ARGS \
    -t ${REGISTRY}/ray:${IMAGE_TAG_BASE} \
    -f ${DOCKERFILE_BASE} \
    .
