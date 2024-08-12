# 阶段1：基础镜像 + SSH及登录提示 + CST时区 + 中文支持
# 基于nvidia/cuda镜像开始构建（已包含cuda和cudnn）
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# 设置工作目录
WORKDIR /root

# 设置必要环境变量
ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam

# 安装必要的工具
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    curl \
    vim \
    tmux \
    wget \
    locales \
    git \
    git-lfs \
    iputils-ping \
    tzdata && apt-get clean && rm -rf /var/lib/apt/lists/*
    
# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 设置中文
RUN locale-gen zh_CN.UTF-8
RUN echo 'export LANG=zh_CN.UTF-8' >> /root/.bashrc

# SSH支持，SSH登录提示信息放在/etc/matrixdc-motd
RUN mkdir /var/run/sshd && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "source /etc/profile" >> /root/.bashrc && \
    echo "source /etc/matrixdc-motd" >> /root/.bashrc
    
# 暴露 SSH 端口
EXPOSE 22

# 阶段2：安装miniconda3(已内置指定python)、jupyterlab、tensorboard
# 下载并安装 Miniconda，安装路径 /opt/miniconda3
ARG MINICONDA_PKG
ENV PATH=/opt/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm /tmp/miniconda.sh && \
    echo "PATH=$PATH" >> /etc/profile && \
    conda init

# pip安装jupyterLab、tensorboard，tensorboard依赖的numpy版本需要小于2.0
RUN pip install --upgrade pip && pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard

# pip安装tensorrt
ARG TENSORRT_VERSION
ARG CU_VERSION
RUN pip install wheel && \
        pip install --upgrade tensorrt${CU_VERSION}==${TENSORRT_VERSION} && \
        pip install --upgrade tensorrt_lean && \
        pip install --upgrade tensorrt_dispatch && \
    rm -r /root/.cache/pip && \
    ln $(find / -name libnvinfer.so*) /usr/lib/libnvinfer.so.${TENSORRT_VERSION} && \
    ln $(find / -name libnvinfer_plugin.so.*) /usr/lib/libnvinfer_plugin.so.${TENSORRT_VERSION}

# 暴露 JupyterLab、TensorBoard的端口
EXPOSE 8888 6006

# 创建目录
RUN mkdir -p /init/

# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

#启动服务
CMD ["bash", "/init/boot/boot.sh"]


# 阶段3：安装深度学习框架tensorflow
ARG TENSORFLOW_TYPE
ARG TENSORFLOW_VERSION
RUN pip install ${TENSORFLOW_TYPE}==${TENSORFLOW_VERSION}

