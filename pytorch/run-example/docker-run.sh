#!/bin/bash
# pytorch:xxx需替换成构建好的实际镜像地址。
# 运行pytorch容器，映射ssh 22端口为2222，jupyter端口为8888，tensorboard端口为6006
docker run  -d  -ti \
--restart=always \
--name pytorch-test \
--gpus all --ipc=host \
-p 2222:22 \
-p 8888:8888 \
-p 6006:6006 \
pytorch:2.3.0-python3.8-cuda12.1.0-cudnn8-devel-ubuntu22.04
