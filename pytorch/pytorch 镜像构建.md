本文档旨在说明pytorch镜像构建过程。目标pytorch镜像的要求是：支持ssh登录、root密码、中文支持、中国CST时区、支持moniconda、支持python3.8、支持Jupyterlab、支持tensorboard。
对于pytorch不同版本来说，此构建过程是通用的。只要将构建镜像脚本中传入的基础镜像、各个版本参数改成自己需要的，即可按需构建不同版本的，支持GPU的或者仅支持CPU的镜像。具体参数详见“构建镜像”章节。

# 1 前置条件
已安装docker，docker  version v19.03+
# 2 Dockerfile文件
Dockerfile文件内容如下：

```dockerfile
# 阶段1：基础镜像 + SSH及登录提示 + CST时区 + 中文支持
ARG BASE_IMAGE

FROM ${BASE_IMAGE}

# 设置工作目录
WORKDIR /root 

RUN apt-get update && DEBIAN_FRONTEND=noninteracti apt-get install -y openssh-server locales tzdata curl vim supervisor && apt-get clean && rm -rf /var/lib/apt/lists/*

# 设置时区为 Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
ENV TZ=Asia/Shanghai

# 设置中文
RUN locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8

# SSH支持
RUN mkdir /var/run/sshd && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

# SSH登录后提示信息
COPY matrixdc-motd /etc/matrixdc-motd
RUN echo "source /etc/profile" >> /root/.bashrc && echo "source /etc/matrixdc-motd" >> /root/.bashrc

# 暴露 SSH 端口
EXPOSE 22

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

# 通过conda安装python
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

# pip安装jupyterLab、tensorboard
RUN pip install jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard && \
    rm -r /root/.cache/pip

# 暴露 JupyterLab、TensorBoard的端口
EXPOSE 8888 6006

# 创建目录
RUN mkdir -p /init/boot

# 拷贝启动脚本
COPY boot.sh /init/boot/boot.sh
RUN chmod +x /init/boot/boot.sh

#启动服务
CMD ["bash", "/init/boot/boot.sh"]

# 阶段3：安装深度学习框架pytorch
ARG PYTORCH_VERSION
ARG PYTORCH_VERSION_SUFFIX
ARG TORCHVISION_VERSION
ARG TORCHVISION_VERSION_SUFFIX
ARG TORCHAUDIO_VERSION
ARG TORCHAUDIO_VERSION_SUFFIX
ARG PYTORCH_DOWNLOAD_URL

RUN if [ ! $TORCHAUDIO_VERSION ]; \
    then \
        TORCHAUDIO=; \
    else \
        TORCHAUDIO=torchaudio==${TORCHAUDIO_VERSION}${TORCHAUDIO_VERSION_SUFFIX}; \
    fi && \
    if [ ! $PYTORCH_DOWNLOAD_URL ]; \
    then \
        pip install \
            torch==${PYTORCH_VERSION}${PYTORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCHVISION_VERSION_SUFFIX} \
            ${TORCHAUDIO}; \
    else \
        pip install \
            torch==${PYTORCH_VERSION}${PYTORCH_VERSION_SUFFIX} \
            torchvision==${TORCHVISION_VERSION}${TORCHVISION_VERSION_SUFFIX} \
            ${TORCHAUDIO} \
            --index-url ${PYTORCH_DOWNLOAD_URL}; \
    fi && \
    rm -r /root/.cache/pip
```

# 3 Dockerfile中引用的文件
Dockerfile中涉及到2个其他文件：分别是：
<pre>
matrixdc-motd     ：SSH登录后提示信息。   
boot.sh           ：Dockerfile CMD启动文件
</pre>

## 3.1 matrixdc-motd
matrixdc-motd文件与Dockerfile放在同级目录下，此文件里定义root ssh连接后终端提示信息。  
matrixdc-motd文件内容如下：

```shell
#!/bin/bash
# 打印的文字颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
# NC用来重置颜色
NC='\033[0m'
printf "+----------------------------------------------------------------------------------------------------------------+
"
printf "${GREEN}目录说明:${NC}
"
printf "╔═════════════════╦════════╦════╦═════════════════════════════════════════════════════════════════════════╗
"
printf "║目录             ║名称    ║速度║说明                                                                     ║
"
printf "╠═════════════════╬════════╬════╬═════════════════════════════════════════════════════════════════════════╣
"
printf "║/                ║系 统 盘║一般║实例关机数据不会丢失，可存放代码等。会随保存镜像一起保存。               ║
"
printf "╚═════════════════╩════════╩════╩═════════════════════════════════════════════════════════════════════════╝
"

if test -f "/sys/fs/cgroup/cpu/cpu.cfs_quota_us"; then
  cfs_quota_us=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
  cfs_period_us=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
  if [ $cfs_quota_us -ge $cfs_period_us ];then
      cores=$((cfs_quota_us / cfs_period_us))
  else
      cores=0.$((cfs_quota_us * 10 / cfs_period_us))
  fi
  printf "${GREEN}CPU${NC} ：%s 核
" ${cores}

  limit_in_bytes=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
  memory="$((limit_in_bytes / 1024 / 1024 / 1024)) GB"
  printf "${GREEN}内存${NC}：%s
" "${memory}"
else
  cores=$(cat /sys/fs/cgroup/cpu.max | awk '{print $1/$2}')
  printf "${GREEN}CPU${NC} ：%s 核
" ${cores}

  limit_in_bytes=$(cat /sys/fs/cgroup/memory.max)
  memory="$((limit_in_bytes / 1024 / 1024 / 1024)) GB"
  printf "${GREEN}内存${NC}：%s
" "${memory}"
fi

if type nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi -i 0 --query-gpu=name,count --format=csv,noheader)
  printf "${GREEN}GPU${NC} ：%s
" "${gpu}"
fi

df_stats=`df -ah`
printf "${GREEN}存储${NC}：
"
disk=$(echo "$df_stats" | grep "/$" | awk '{print $5" "$3"/"$2}')
printf "  ${GREEN}/${NC}               ：%s
" "${disk}"


printf "+----------------------------------------------------------------------------------------------------------------+
"
printf "${RED}*注意: 
"
printf "${RED}1.清理系统盘请参考文档${NC}
"

alias sudo=""
```

## 3.2 boot.sh
boot.sh文件放在Dockerfile同级目录中，此文件定义要启动的服务，并用supervisor管理服务进程。  
boot.sh文件内容如下：

```shell
#!/bin/bash

# 创建/init/jupyter，用来存放jupyterlab的配置文件
mkdir -p /init/jupyter

# 创建/init/supervisor，用来存放supervisor.ini文件
mkdir -p /init/supervisor

# 创建/root/tensorboard-logs，用来存放tensorboard日志
mkdir -p /root/tensorboard-logs

# 创建/init/jupyter/jupyter_config.py配置文件
cat > /init/jupyter/jupyter_config.py <<EOF
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
# jupyter token设置
c.ServerApp.token = ""
c.NotebookApp.open_browser = False

# 0.5.1版本前创建的容器还使用/ 作为root dir
import os
c.ServerApp.root_dir = "/root"
c.MultiKernelManager.default_kernel_name = 'python3'
c.NotebookNotary.db_file = ':memory:'
c.ServerApp.tornado_settings = {
    'headers': {
        'Content-Security-Policy': "frame-ancestors * 'self' "
    }
}
c.NotebookApp.allow_remote_access = True
c.NotebookApp.base_url='/jupyter/'
c.NotebookApp.allow_origin='*'

c.ServerApp.allow_remote_access = True
c.ServerApp.base_url='/jupyter/'
c.ServerApp.allow_origin='*'

EOF


# 创建/init/supervisor/supervisor.ini文件
cat > /init/supervisor/supervisor.ini <<EOF
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid


[program:sshd]
command=/usr/sbin/sshd
directory=/root
autostart=true
autorestart=true
redirect_stderr=true

[program:jupyterlab]
command=jupyter-lab --allow-root --config=/init/jupyter/jupyter_config.py
directory=/root
autostart=true
autorestart=true
redirect_stderr=true

[program:tensorboard]
command=tensorboard --host 0.0.0.0 --port 6006 --logdir /root/tensorboard-logs --path_prefix /monitor
directory=/root
autostart=true
autorestart=true
redirect_stderr=true

EOF


# 启动supervisord
supervisord -c /init/supervisor/supervisor.ini
```

# 4 构建镜像
build-scripts.sh文件与Dockerfile放在同级目录下。此文件定义镜像构建过程，按需修改版本参数。构建出的镜像名称示例：pytorch:2.3.0-python3.8-cuda12.1.0-cudnn8-devel-ubuntu22.04

注意：在给版本参数赋值时，参考对应pytorch版本pip安装命令（https://pytorch.org/get-started/previous-versions/）
!<img src=".\images\pytorch_install.png">
    
build-scripts.sh内容如下：

```shell
#!/bin/sh

# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04

BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

PYTHON_VERSION=3.8

#根据官方对应pytorch pip安装命令中指定https://pytorch.org/get-started/previous-versions/
# PYTORCH参数
PYTORCH_VERSION=2.3.0
PYTORCH_VERSION_SUFFIX=
TORCHVISION_VERSION=0.18.0
TORCHVISION_VERSION_SUFFIX=
TORCHAUDIO_VERSION=2.3.0
TORCHAUDIO_VERSION_SUFFIX=
PYTORCH_DOWNLOAD_URL=https://download.pytorch.org/whl/cu121

# 构建后的镜像tag，需要体现pytorch、python、基础镜像版本信息
IMAGE_TAG=${PYTORCH_VERSION}-python${PYTHON_VERSION}-cuda12.1.0-cudnn8-devel-ubuntu22.04

docker build \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
    --build-arg PYTORCH_VERSION=${PYTORCH_VERSION} \
    --build-arg PYTORCH_VERSION_SUFFIX=${PYTORCH_VERSION_SUFFIX} \
    --build-arg TORCHVISION_VERSION=${TORCHVISION_VERSION} \
    --build-arg TORCHVISION_VERSION_SUFFIX=${TORCHVISION_VERSION_SUFFIX} \
    --build-arg TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION} \
    --build-arg TORCHAUDIO_VERSION_SUFFIX=${TORCHAUDIO_VERSION_SUFFIX} \
    --build-arg PYTORCH_DOWNLOAD_URL=${PYTORCH_DOWNLOAD_URL} \
    -t pytorch:${IMAGE_TAG} \
    -f ./Dockerfile \
    .
```

执行镜像构建
```shell
# 执行以下命令，即开始构建镜像
chmod +x build-scripts.sh
sh build-scripts.sh
```

# 5 运行容器
运行容器脚本参考run-examplem目录下的docker-run.sh（docker直接启动）、k8s-run-deployment（k8s启动的deployment）。
docker-run.sh文件内容如下:

```shell
#!/bin/bash
# pytorch:xxx需替换成构建好的实际镜像地址。
# 运行pytorch容器，映射ssh 22端口为2222，jupyter端口为8888，tensorboard端口为6006
docker run  -d  -ti \
--restart=always \
--name pytorch-test \
--gpus all --ipc=host \
-p 2222:22 \
-p 8888:8888 \
-p 6006:6006 \
pytorch:2.3.0-python3.8-cuda12.1.0-cudnn8-devel-ubuntu22.04
```

# 6 验证镜像功能
## 6.1 支持SSH登录成功，登录后有友好提示
<img src=".\images\SSH.png">

## 6.2 支持中文，中文不乱码
<img src=".\images\Chinese.png">


## 6.3 中国标准时间CST
<img src=".\images\timezone.png">

## 6.4 支持Jupyterlab
Jupyterlab安装了汉化插件：
<img src=".\images\jupyterlab-1.png">

Jupyterlab进入终端也显示提示信息：
<img src=".\images\jupyterlab-2.png">

## 6.5 支持Tensorboard
无数据时：
<img src=".\images\tensorboard-1.png">

有数据时：
<img src=".\images\tensorboard-2.png">

## 6.6 查看安装的pytorch、cuda、cudnn等版本
<img src=".\images\cuda.png">

# 7 镜像目录说明
1、登录容器默认进入目录：/root    
2、Jupyterlab工作目录：/root    
3、TensorBoard日志目录：/root/tensorboard-logs