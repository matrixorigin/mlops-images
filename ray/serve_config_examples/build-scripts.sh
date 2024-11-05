#!/bin/bash

RAY_VERSION=2.35.0
BASE_IMAGE=rayproject/ray:${RAY_VERSION}-py310-cpu

#REGISTRY=images.neolink-ai.com/matrixdc
REGISTRY=ghcr.io/bincherry

DOCKER_BUILDKIT=1

EXTRA_ARGS="$@"

docker buildx build \
    --platform=linux/amd64 \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    $EXTRA_ARGS \
    -t ${REGISTRY}/ray:text_ml \
    -f ./Dockerfile \
    .
