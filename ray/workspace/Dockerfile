# 阶段1：基础镜像 + SSH及登录提示 + CST时区 + 中文支持
ARG BASE_IMAGE

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
  libjemalloc-dev \
  cmake \
  g++ \
  zlib1g-dev \
  screen \
  rsync \
  netbase \
  gnupg \
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

# 暴露 SSH 端口
EXPOSE 22

# 阶段2：安装miniconda3(已内置指定python)
# 这里不安装jupyterlab、tensorboard，放到阶段4
# 下载并安装 Miniconda，安装路径 /opt/miniconda3
ARG MINICONDA_PKG
ARG PYTHON_VERSION=3.10
ENV PATH=/opt/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
  bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
  rm /tmp/miniconda.sh && \
  echo "PATH=$PATH" >> /etc/profile && \
  conda init && \
  conda install -y libgcc-ng python=$PYTHON_VERSION && \
  conda install -y -c conda-forge libffi=3.4.2 && \
  conda clean -y --all

# 创建目录
RUN mkdir -p /init/

# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

# 阶段3：安装vscode
# https://github.com/kubeflow/kubeflow/blob/v1.9.0/components/example-notebook-servers/codeserver/Dockerfile
ARG TARGETARCH
SHELL ["/bin/bash", "-c"]

RUN CODESERVER_VERSION=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
  && curl -fsSL "https://github.com/coder/code-server/releases/download/${CODESERVER_VERSION}/code-server_${CODESERVER_VERSION/v/}_${TARGETARCH}.deb" -o /tmp/code-server.deb \
  && dpkg -i /tmp/code-server.deb \
  && rm -f /tmp/code-server.deb \
  && code-server --install-extension "ms-python.python" --force \
  && code-server --list-extensions --show-versions

EXPOSE 8889

# 阶段4：安装ray
ARG RAY_VERSION
RUN curl -fsSL https://raw.githubusercontent.com/ray-project/ray/refs/tags/ray-${RAY_VERSION}/python/requirements_compiled.txt -o requirements_compiled.txt 

# TODO jupyterlab在requirements_compiled.txt中的版本强制为3.6.1，比最新版(4.x)落后很多
# Refer: https://github.com/ray-project/ray/blob/master/docker/base-deps/Dockerfile
RUN pip install --no-cache-dir \
      flatbuffers \
      cython==0.29.37 \
      # Necessary for Dataset to work properly.
      numpy\>=1.20 \
      psutil \
      # Required a recent version of setuptools to be compatible with python 3.12+.
      setuptools==70.0.0 \
  # To avoid the following error on Jenkins:
  # AttributeError: 'numpy.ufunc' object has no attribute '__module__'
  && pip uninstall -y dask \
  && pip --no-cache-dir install \
      "redis>=3.5.0,<4.0.0" \
      six==1.13.0 \
      boto3==1.26.76 \
      pyOpenSSL==22.1.0 \
      cryptography==38.0.1 \
      google-api-python-client==1.7.8 \
      google-oauth \
      azure-cli-core==2.40.0 \
      azure-identity==1.10.0 \
      azure-mgmt-compute==23.1.0 \
      azure-mgmt-network==19.0.0 \
      azure-mgmt-resource==20.0.0 \
      msrestazure==0.6.4 \
  && pip install --no-cache-dir 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments ipywidgets tensorboard -c requirements_compiled.txt

RUN pip --no-cache-dir install ray[all]==${RAY_VERSION} -c requirements_compiled.txt

# 暴露 JupyterLab、TensorBoard的端口
EXPOSE 8888 6006

# 暴露 Ray的端口
EXPOSE 6379 8265 10001 8080

#启动服务
CMD ["bash", "/init/boot/boot.sh"]
