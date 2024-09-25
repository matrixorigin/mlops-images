ARG BASE_IMAGE

FROM ${BASE_IMAGE}

# Set working directory
WORKDIR /root 

ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8

# Install system dependencies and dev tools
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

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set locale
RUN locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8

# Configure SSH
RUN mkdir /var/run/sshd && \
  echo "root:123456" | chpasswd && \
  sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
  echo "source /etc/profile" >> /root/.bashrc && \
  echo "source /etc/matrixdc-motd" >> /root/.bashrc

# Install Miniconda
ARG MINICONDA_PKG
RUN echo ${MINICONDA_PKG}
ENV PATH=/opt/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
  bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
  rm /tmp/miniconda.sh && \
  echo "PATH=$PATH" >> /etc/profile && \
  conda init

# Install Python packages
RUN pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install web ui
RUN pip install open-webui

# Copy init files
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

# Expose ports
EXPOSE 22 8888 6006 3000 11434

# Set environment variables
ENV OLLAMA_BASE_URL=http://127.0.0.1:11435
ENV OLLAMA_HOST=0.0.0.0:11435
ENV OLLAMA_MODELS=/root/data
ENV HF_ENDPOINT=https://hf-mirror.com

RUN echo "export OLLAMA_HOST=0.0.0.0:11435" >> /etc/profile
# due to limitation with ingress proxy with nginx
RUN apt-get --allow-unauthenticated update && apt-get install -y nginx

COPY ./ollama-nginx.conf /etc/nginx/conf.d/default.conf
RUN sed -i 's/worker_processes auto;/worker_processes 2;/' /etc/nginx/nginx.conf

# Configure supervisord
RUN mkdir -p /tmp/log/ollama /tmp/log/open-webui /tmp/log/nginx
RUN mkdir -p /etc/supervisord && \
  echo "[program:ollama]" > /etc/supervisord/supervisor-other.ini && \
  echo "command=/usr/local/bin/ollama serve" >> /etc/supervisord/supervisor-other.ini && \
  echo "stdout_logfile=/tmp/log/ollama/ollama.log" >> /etc/supervisord/supervisor-other.ini && \
  echo "stderr_logfile=/tmp/log/ollama/ollama.log" >> /etc/supervisord/supervisor-other.ini && \
  echo "redirect_stderr=true" >> /etc/supervisord/supervisor-other.ini && \
  echo "[program:webui]" >> /etc/supervisord/supervisor-other.ini && \
  echo "command=open-webui serve --port 3000" >> /etc/supervisord/supervisor-other.ini && \
  echo "stdout_logfile=/tmp/log/open-webui/webui.log" >> /etc/supervisord/supervisor-other.ini && \
  echo "stderr_logfile=/tmp/log/open-webui/webui.log" >> /etc/supervisord/supervisor-other.ini && \
  echo "redirect_stderr=true" >> /etc/supervisord/supervisor-other.ini && \
  echo "[program:nginx]" >> /etc/supervisord/supervisor-other.ini && \
  echo "command=nginx -g 'daemon off;'" >> /etc/supervisord/supervisor-other.ini && \
  echo "stdout_logfile=/tmp/log/nginx/nginx.log" >> /etc/supervisord/supervisor-other.ini && \
  echo "stderr_logfile=/tmp/log/nginx/nginx.log" >> /etc/supervisord/supervisor-other.ini && \
  echo "redirect_stderr=true" >> /etc/supervisord/supervisor-other.ini

# Set entrypoint (unchanged from your original)
CMD ["bash", "/init/boot/boot.sh"]

