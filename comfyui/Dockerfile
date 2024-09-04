################################################################################
# Dockerfile that builds 'yanwk/comfyui-boot:cu121'
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
# Using CUDA 12.1 & Python 3.11
################################################################################
ARG BASE_IMAGE

FROM ${BASE_IMAGE}

# 使用APT来安装软件包并缓存
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV TZ=Asia/Shanghai

RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        g++ make curl libopencv-dev ffmpeg libx264-dev libx265-dev \
        libglib2.0-0 \
        git aria2 \
        mesa-utils \
        fonts-noto-cjk fonts-noto-color-emoji

# 添加 Python 3.11 的 PPA 并安装 Python 3.11
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y --no-install-recommends \
        python3.11 python3.11-dev python3.11-venv python3.11-distutils && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 100 && \
    rm -rf /var/lib/apt/lists/*

# 使用缓存的 PIP 目录并升级 PIP
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install --upgrade pip wheel setuptools

# 安装 xFormers、Torchvision 和 Torchaudio
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install \
        xformers torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu121 \
        --extra-index-url https://pypi.org/simple

# 安装常用依赖
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install \
        -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
        -r https://raw.githubusercontent.com/crystian/ComfyUI-Crystools/main/requirements.txt \
        -r https://raw.githubusercontent.com/cubiq/ComfyUI_essentials/main/requirements.txt \
        -r https://raw.githubusercontent.com/Fannovel16/comfyui_controlnet_aux/main/requirements.txt \
        -r https://raw.githubusercontent.com/jags111/efficiency-nodes-comfyui/main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Pack/Main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Subpack/main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Inspire-Pack/main/requirements.txt \
        -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt

# 安装其他依赖
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install \
        -r https://raw.githubusercontent.com/cubiq/ComfyUI_FaceAnalysis/main/requirements.txt \
        -r https://raw.githubusercontent.com/cubiq/ComfyUI_InstantID/main/requirements.txt \
        -r https://raw.githubusercontent.com/Fannovel16/ComfyUI-Frame-Interpolation/main/requirements-no-cupy.txt \
        cupy-cuda12x \
        -r https://raw.githubusercontent.com/FizzleDorf/ComfyUI_FizzNodes/main/requirements.txt \
        -r https://raw.githubusercontent.com/kijai/ComfyUI-KJNodes/main/requirements.txt \
        -r https://raw.githubusercontent.com/melMass/comfy_mtb/main/requirements.txt \
        -r https://raw.githubusercontent.com/MrForExample/ComfyUI-3D-Pack/main/requirements.txt \
        -r https://raw.githubusercontent.com/storyicon/comfyui_segment_anything/main/requirements.txt \
        -r https://raw.githubusercontent.com/ZHO-ZHO-ZHO/ComfyUI-InstantID/main/requirements.txt \
        compel lark torchdiffeq fairscale \
        python-ffmpeg

# 修复 ONNX Runtime 的 CUDA 支持和 MediaPipe 的依赖问题
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 uninstall --yes \
        onnxruntime-gpu && \
    pip3.11 install --no-cache-dir \
        onnxruntime-gpu \
        --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/ \
        --extra-index-url https://pypi.org/simple && \
    pip3.11 install \
        mediapipe

# 设置时区为 Asia/Shanghai 并安装和配置 locales
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV TZ=Asia/Shanghai

ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8

# Fix for libs (.so files)
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
:/usr/local/lib64/python3.11/site-packages/torch/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cuda_cupti/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cuda_runtime/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cudnn/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cufft/lib"

# More libs (not necessary, just in case)
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}\
:/usr/local/lib/python3.11/site-packages/nvidia/cublas/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cuda_nvrtc/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/curand/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cusolver/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/cusparse/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/nccl/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/nvjitlink/lib\
:/usr/local/lib/python3.11/site-packages/nvidia/nvtx/lib"

# Create a low-privilege user
RUN mkdir /var/run/sshd && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "source /etc/profile" >> /root/.bashrc && \
    echo "source /etc/matrixdc-motd" >> /root/.bashrc

RUN mkdir -p /init/

# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*


ENTRYPOINT ["bash", "/init/boot/boot.sh"]

USER runner:runner
VOLUME /home/runner
WORKDIR /home/runner
EXPOSE 22
ENV CLI_ARGS=""
# 启动服务
CMD ["bash", "/home/scripts/start.sh"]
