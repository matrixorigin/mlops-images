# 阶段1：基础镜像 + SSH及登录提示 + CST时区 + 中文支持
# 基于nvidia/cuda镜像开始构建（已包含cuda和cudnn）
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# 设置工作目录
WORKDIR /root

# 安装必要的工具
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    openssh-server \
    curl \
    vim \
    locales \
    supervisor \
    tzdata && apt-get clean && rm -rf /var/lib/apt/lists/*

# 设置ssh
RUN mkdir /var/run/sshd
RUN echo "root:111111" | chpasswd
RUN echo -n "111111" | base64 > /tmp/.secretpw
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config 

# 设置ssh登入提示信息
COPY matrixdc-motd /etc/matrixdc-motd
RUN echo 'source /etc/matrixdc-motd' >> /etc/bash.bashrc

# 暴露 SSH 端口
EXPOSE 22

# 设置时区
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone

# 设置中文
RUN locale-gen zh_CN.UTF-8
RUN echo 'export LANG=zh_CN.UTF-8' >> /root/.bashrc

# 设置必要环境变量
ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam

# 阶段2：安装miniconda3、python、jupyterlab、tensorboard
# 下载并安装 Miniconda，安装路径 /root/miniconda3
ENV PATH=/root/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash /tmp/miniconda.sh -b -p /root/miniconda3 && \
    rm /tmp/miniconda.sh && \
    echo "PATH=$PATH" >> /etc/profile

# 通过conda安装一个python
ARG PYTHON_VERSION
RUN conda install -y python=${PYTHON_VERSION}  && \
    conda clean -ya && \
    echo "export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt" >> /etc/profile

# conda/pip增加国内源
RUN conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ && \
    conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/ && \
    conda config --set show_channel_urls yes && \
    pip config set global.index-url http://mirrors.aliyun.com/pypi/simple/ && \
    pip config set global.trusted-host mirrors.aliyun.com

# 安装Python库
RUN pip install --upgrade pip \
    && pip install --no-cache-dir \
    jupyterlab \
    jupyterlab-language-pack-zh-CN \
    jupyterlab_pygments \
    tensorboard \
    && rm -r /root/.cache/pip
    
# 暴露 JupyterLab、TensorBoard的端口
EXPOSE 8888 6006

# 创建目录
RUN mkdir -p /init/boot

# 拷贝启动脚本
COPY boot.sh /init/boot/boot.sh
RUN chmod +x /init/boot/boot.sh

#启动服务
CMD ["bash", "/init/boot/boot.sh"]


# 阶段3：安装深度学习框架tensorflow
ARG TENSORFLOW_TYPE
ARG TENSORFLOW_VERSION
RUN pip install ${TENSORFLOW_TYPE}==${TENSORFLOW_VERSION}

