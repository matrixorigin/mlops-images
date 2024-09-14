###############################################################
# Dockerfile that builds 'yanwk/comfyui-boot:cu121'
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
# Using CUDA 12.1 & Python 3.11
################################################################################
ARG BASE_IMAGE

#ARG PIP_SOURCE=https://pypi.mirrors.ustc.edu.cn/simple

FROM ${BASE_IMAGE}

# 使用APT来安装软件包并缓存
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8

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

# pip安装jupyterLab、tensorboard，tensorboard依赖的numpy版本需要小于2.0
RUN pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard && \
    rm -r /root/.cache/pip

# 暴露 JupyterLab、TensorBoard的端口
EXPOSE 8888 6006

# 安装 xFormers、Torchvision 和 Torchaudio
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install xformers torchvision torchaudio

# 安装常用依赖
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
    -r https://raw.githubusercontent.com/crystian/ComfyUI-Crystools/main/requirements.txt \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_essentials/main/requirements.txt \
    -r https://raw.githubusercontent.com/Fannovel16/comfyui_controlnet_aux/main/requirements.txt \
    -r https://raw.githubusercontent.com/jags111/efficiency-nodes-comfyui/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Pack/Main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Subpack/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Inspire-Pack/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt


RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install \
    cmake \
    onnxruntime \
    insightface \
    color_matcher \
    onnxruntime-gpu \
    torch \
    numpy \
    einops \
    opencv-contrib-python \
    kornia \
    scipy \
    Pillow \
    torchvision \
    tqdm \
    pandas \
    numexpr \
    'pillow>=10.3.0' \
    matplotlib \
    huggingface_hub \
    mss \
    opencv-python \
    'qrcode[pil]' \
    requirements-parser \
    rembg \
    imageio_ffmpeg \
    rich \
    rich_argparse \
    ninja \
    PyGithub \
    requests \
    'nerfacc>=0.5.3' \
    slangtorch \
    'diffusers>=0.26.1' \
    'transformers>=4.36.2' \
    safetensors \
    open_clip_torch \
    torchmetrics \
    pytorch_msssim \
    pytorch-lightning \
    trimesh \
    plyfile \
    pygltflib \
    xatlas \
    pymeshlab \
    gpytoolbox \
    PyMCubes \
    torchtyping \
    jaxtyping \
    packaging \
    OmegaConf \
    pyhocon \
    segment_anything \
    timm \
    addict \
    yapf \
    cupy-cuda12x \
    accelerate \
    compel \
    lark \
    torchdiffeq \
    fairscale \
    python-ffmpeg \
    boost

RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 install  dlib


# 修复 ONNX Runtime 的 CUDA 支持和 MediaPipe 的依赖问题
RUN --mount=type=cache,target=/root/.cache/pip \
    pip3.11 uninstall --yes \
    onnxruntime-gpu && \
    pip3.11 install --no-cache-dir onnxruntime-gpu --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-12/pypi/simple/ \
    --extra-index-url https://pypi.org/simple && pip3.11 install mediapipe

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

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    openssh-server

# Create a low-privilege user
RUN mkdir /var/run/sshd && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "source /etc/profile" >> /root/.bashrc && \
    echo "source /etc/matrixdc-motd" >> /root/.bashrc

RUN mkdir -p /init/

EXPOSE 22 3000
# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

#ENTRYPOINT ["bash", "/init/boot/boot.sh"]
RUN mkdir -p /runner-scripts/
COPY ./runner-scripts/ /runner-scripts/
WORKDIR /root/data
# ENV CLI_ARGS=""

RUN mkdir -p /etc/supervisord
RUN echo "[program:comfyui]" >> /etc/supervisord/supervisor-other.ini
RUN echo "command=bash /runner-scripts/start-comfy.sh" >> /etc/supervisord/supervisor-other.ini

CMD ["bash", "/init/boot/boot.sh"]
