ARG BASE_IMAGE

FROM ghcr.io/open-webui/open-webui AS open-webui
FROM ollama/ollama AS ollama
# Stage 2: Final image
FROM ${BASE_IMAGE}

# 设置工作目录
WORKDIR /root 

ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates \
  openssh-server \
  locales \
  tzdata \
  curl \
  vim \
  tmux \
  wget \
  git \
  git-lfs \
  python3 \
  python3-pip \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

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
# 下载并安装 Miniconda，安装路径 /opt/miniconda3
ARG MINICONDA_PKG
RUN echo ${MINICONDA_PKG}
ENV PATH=/opt/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
  bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
  rm /tmp/miniconda.sh && \
  echo "PATH=$PATH" >> /etc/profile && \
  conda init

# pip安装jupyterLab、tensorboard，tensorboard依赖的numpy版本需要小于2.0
RUN pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard

COPY --from=ollama /usr/bin/ollama /usr/bin/ollama

# Copy built WebUI from the builder stage
# Copy the open-webui files from the open-webui stage
COPY --from=open-webui /app /app
WORKDIR /app
RUN ls -al
# Install WebUI backend dependencies
RUN pip install -r ./backend/requirements.txt -U

# 创建目录
RUN mkdir -p /init/
# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

# 暴露 SSH、JupyterLab、TensorBoard, Ollama, WebUI的端口
EXPOSE 22 8888 6006 3000 11434
# Set environment variable for Open WebUI
ENV OLLAMA_BASE_URL=0.0.0.0:11434
# Let ollama serve at all IPs
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_MODELS=/root/data

# supervisor配置文件放入ollama的启动命令
RUN mkdir -p /etc/supervisord
RUN echo "[program:ollama]" >> /etc/supervisord/supervisor-other.ini
RUN echo "command=ollama serve" >> /etc/supervisord/supervisor-other.ini

# Add WebUI service to supervisord
RUN echo "[program:webui]" >> /etc/supervisord/supervisor-other.ini
RUN echo "command=/bin/bash -c 'cd /app/backend && export PORT=3000 && ./start.sh'" >> /etc/supervisord/supervisor-other.ini
RUN echo "directory=/app/backend" >> /etc/supervisord/supervisor-other.ini

CMD ["bash", "/init/boot/boot.sh"]
