# 阶段1：基础镜像 + SSH及登录提示 + CST时区 + 中文支持
ARG BASE_IMAGE

FROM ${BASE_IMAGE}

# 设置工作目录
WORKDIR /root 

ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam

RUN apt-get update && DEBIAN_FRONTEND=noninteracti apt-get install -y --no-install-recommends openssh-server locales tzdata curl vim tmux wget git git-lfs iputils-ping && apt-get clean && rm -rf /var/lib/apt/lists/*

# 设置时区为 Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV TZ=Asia/Shanghai

# 设置中文
RUN locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8

# SSH支持，SSH登录提示信息放在/etc/matrixdc-motd
RUN mkdir /var/run/sshd && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "source /etc/profile" >> /root/.bashrc && \
    echo "source /etc/matrixdc-motd" >> /root/.bashrc

# 阶段2：安装miniconda3(已内置指定python)、jupyterlab、tensorboard
# 下载并安装 Miniconda，安装路径 /root/miniconda3
ARG MINICONDA_PKG
ENV PATH=/root/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
    bash /tmp/miniconda.sh -b -p /root/miniconda3 && \
    rm /tmp/miniconda.sh && \
    echo "PATH=$PATH" >> /etc/profile


# pip安装jupyterLab、tensorboard，tensorboard依赖的numpy版本需要小于2.0
RUN pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard

# Build Open WebUI
COPY build-webui.sh /tmp/build-webui.sh
RUN chmod +x /tmp/build-webui.sh && /tmp/build-webui.sh && \
    rm -r /root/.cache/pip

# 创建目录
RUN mkdir -p /init/
# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*


# 暴露 JupyterLab、TensorBoard, Ollama, WebUI的端口
EXPOSE 22 8888 6006 3000 11434
# Set environment variable for Open WebUI
ENV OLLAMA_BASE_URL=http://localhost:11434

#启动服务
CMD ["bash", "/init/boot/boot.sh"]
