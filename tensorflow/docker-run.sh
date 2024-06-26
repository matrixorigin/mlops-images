#!/bin/bash
# tensorflow:xxx需替换成构建好的实际镜像地址。
# 运行tensorflow容器，映射ssh 22端口为2222，jupyter端口为8888，tensorboard端口为6006
docker run  -d  -ti \
--restart=always \
--name pytorch-test \
--gpus all --ipc=host \
-p 2220:22 \
-p 8880:8888 \
-p 6007:6006 \
tensorflow:2.15.0-python3.8-cuda12.1.0-cudnn8-devel-ubuntu22.04