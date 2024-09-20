ARG BASE_IMAGE

# Ollama stage
FROM ollama/ollama AS ollama

# Stage 1: Build stage
FROM ${BASE_IMAGE} AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
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

# Set timezone and locale
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8

# Configure SSH
RUN mkdir /var/run/sshd && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# Install Miniconda
ARG MINICONDA_PKG
ENV PATH=/opt/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm /tmp/miniconda.sh && \
    conda init

# Install Python packages
RUN pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard open-webui

# Stage 2: Final image
FROM ${BASE_IMAGE}

# Copy installed packages and configurations from builder
COPY --from=builder /opt/miniconda3 /opt/miniconda3
COPY --from=builder /usr/local /usr/local
COPY --from=builder /etc/ssh /etc/ssh
COPY --from=builder /var/run/sshd /var/run/sshd
COPY --from=builder /etc/timezone /etc/timezone
COPY --from=builder /etc/localtime /etc/localtime
COPY --from=builder /etc/locale.gen /etc/locale.gen
COPY --from=builder /etc/default/locale /etc/default/locale

# Set environment variables
ENV PATH=/opt/miniconda3/bin:$PATH
ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8
ENV OLLAMA_BASE_URL=0.0.0.0:11434
ENV OLLAMA_HOST=0.0.0.0
ENV OLLAMA_MODELS=/root/data
ENV HF_ENDPOINT=https://hf-mirror.com

# Copy Ollama binary
COPY --from=ollama /usr/bin/ollama /usr/bin/ollama

# Set up workspace
WORKDIR /root
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

# Configure supervisord
RUN mkdir -p /etc/supervisord && \
    echo "[supervisord]\nnodaemon=true\nuser=root\n[include]\nfiles = /etc/supervisord/*.ini" > /etc/supervisord/supervisord.conf && \
    echo "[program:ollama]\ncommand=ollama serve" > /etc/supervisord/supervisor-other.ini && \
    echo "[program:webui]\ncommand=open-webui serve --port 3000" >> /etc/supervisord/supervisor-other.ini

# Expose ports
EXPOSE 22 8888 6006 3000 11434

# Set entrypoint
CMD ["bash", "/init/boot/boot.sh"]
