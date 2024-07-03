本文档旨在说明pytorch镜像构建过程。目标pytorch镜像的要求是：支持ssh登录、root密码、中文支持、中国CST时区，内置miniconda、python3.8、Jupyterlab、TensorBoard。
对于pytorch不同版本来说，此构建过程是通用的，只需将构建镜像脚本中传入的基础镜像、各个版本参数改成自己需要的，即可按需构建不同版本的，支持GPU的或者仅支持CPU的镜像。具体参数详见“构建镜像”章节。

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

ENV SHELL=/bin/bash
ENV USER=root
ENV MOTD_SHOWN=pam

RUN apt-get update && DEBIAN_FRONTEND=noninteracti apt-get install -y --no-install-recommends openssh-server locales tzdata curl vim tmux wget  && apt-get clean && rm -rf /var/lib/apt/lists/*

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

# 阶段2：安装miniconda3(已内置指定python)、jupyterlab、tensorboard
# 下载并安装 Miniconda，安装路径 /root/miniconda3
ARG MINICONDA_PKG
ENV PATH=/root/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
    bash /tmp/miniconda.sh -b -p /root/miniconda3 && \
    rm /tmp/miniconda.sh && \
    echo "PATH=$PATH" >> /etc/profile

    
# pip安装jupyterLab、tensorboard，tensorboard依赖的numpy版本需要小于2.0
RUN pip install 'numpy<2.0' jupyterlab jupyterlab-language-pack-zh-CN jupyterlab_pygments tensorboard && \
    rm -r /root/.cache/pip

# 暴露 JupyterLab、TensorBoard的端口
EXPOSE 8888 6006

# 创建目录
RUN mkdir -p /init/

# 拷贝启动涉及到的文件
COPY ./init/ /init/
RUN chmod 755 /init/boot/*.sh && chmod 755 /init/bin/*

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
Dockerfile中引用了./init/文件夹下，/init文件夹与Dockerfile放在同级目录下。
文件夹目录结构如下：
<pre>
./init/
├── bin
│   └── supervisord   #supervisor二进制bin文件，静态文件
├── boot
│   └── boot.sh       # CMD启动脚本，静态文件
├── jupyter
│   └── jupyter_config.py # Jupyterlab配置文件，静态文件
└── supervisor
    └── supervisor.ini    # supervisor配置文件，静态文件
</pre>

## 3.1 ./init/bin/supervisord
./init/bin/supervisord是个bin文件，在boot.sh中用此supervisord启动服务。  

## 3.2 ./init/boot/boot.sh
./init/boot/boot.sh是CMD启动脚本，此脚本中通过curl的方式获取在线文件init.py，init.py中存放的是后续可能有变化的内容，这样组织的好处是：init.py文件内容有变化时无需重新Build镜像。        
boot.sh文件内容：    
```shell
#!/bin/bash
echo "init begin, source /etc/profile"

source /etc/profile || true
echo $PATH

# 设置SSH登录密码
[ -f /sync/root-passwd ] && cat /sync/root-passwd | chpasswd && rm /sync/root-passwd
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
mkdir -p /run/sshd || true
echo "passwd set finished"

# 拷贝supervisor 等bin文件
cp -fv /init/bin/* /bin/
ls -alh /init/bin/
ls -alh /bin/ | grep -E "super"
echo "bin file set finished"


rm -rf /tmp/gpuhub && mkdir /tmp/gpuhub
curl --connect-timeout 5 -o /tmp/gpuhub/init.py https://sharefile.43.143.130.168.nip.io:30443/file/init.py -k || true

echo "download init script finished"

mkdir -p /root/tensorboard-logs


python /tmp/gpuhub/init.py || true
rm -rf /tmp/gpuhub
echo "run init script finished"


echo "pre cmd finished"

echo "supervisord begin"
/bin/supervisord -c /init/supervisor/supervisor.ini
```
https://sharefile.43.143.130.168.nip.io:30443/file/init.py文件内容：   
```python
# -*- coding: utf-8 -*-
import os
import logging
import requests

motd_doc_v1 = '''#!/bin/bash

printf "+----------------------------------------------------------------------------------------------------------------+\n"
printf "\033[32m目录说明:\033[0m\n"
printf "╔═════════════════╦════════╦════╦═════════════════════════════════════════════════════════════════════════╗\n"
printf "║目录             ║名称    ║速度║说明                                                                     ║\n"
printf "╠═════════════════╬════════╬════╬═════════════════════════════════════════════════════════════════════════╣\n"
printf "║/                ║系 统 盘║一般║实例关机数据不会丢失，可存放代码等。会随保存镜像一起保存。               ║\n"
printf "╚═════════════════╩════════╩════╩═════════════════════════════════════════════════════════════════════════╝\n"

if test -f "/sys/fs/cgroup/cpu/cpu.cfs_quota_us"; then
  cfs_quota_us=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
  cfs_period_us=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
  if [ $cfs_quota_us -ge $cfs_period_us ];then
      cores=$((cfs_quota_us / cfs_period_us))
  else
      cores=0.$((cfs_quota_us * 10 / cfs_period_us))
  fi
  printf "\033[32mCPU\033[0m ：%s 核心\n" ${cores}

  limit_in_bytes=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
  memory="$((limit_in_bytes / 1024 / 1024 / 1024)) GB"
  printf "\033[32m内存\033[0m：%s\n" "${memory}"
else
  cores=$(cat /sys/fs/cgroup/cpu.max | awk '{print $1/$2}')
  printf "\033[32mCPU\033[0m ：%s 核心\n" ${cores}

  limit_in_bytes=$(cat /sys/fs/cgroup/memory.max)
  memory="$((limit_in_bytes / 1024 / 1024 / 1024)) GB"
  printf "\033[32m内存\033[0m：%s\n" "${memory}"
fi

if type nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi -i 0 --query-gpu=name,count --format=csv,noheader)
  printf "\033[32mGPU \033[0m：%s\n" "${gpu}"
fi

df_stats=`df -ah`
printf "\033[32m存储\033[0m：\n"
disk=$(echo "$df_stats" | grep "/$" | awk '{print $5" "$3"/"$2}')
printf "\033[32m  系 统 盘/               \033[0m：%s\n" "${disk}"


printf "+----------------------------------------------------------------------------------------------------------------+\n"

alias sudo=""
'''


def try_catch(func):
    def fn():
        try:
            func()
        except Exception as e:
            logging.exception("Exception happened. detail: {}".format(e))

    return fn


@try_catch
def init_jupyter():
    terminal_setting_path = "/root/.jupyter/lab/user-settings/@jupyterlab/terminal-extension"
    lang_setting_path = "/root/.jupyter/lab/user-settings/@jupyterlab/translation-extension"
    if not os.path.exists(terminal_setting_path):
        os.makedirs(terminal_setting_path)
    if not os.path.exists(lang_setting_path):
        os.makedirs(lang_setting_path)
    with open(os.path.join(terminal_setting_path, "plugin.jupyterlab-settings"), "w") as fo:
        fo.write('''{"theme": "dark"}
        ''')
    with open(os.path.join(lang_setting_path, "plugin.jupyterlab-settings"), "w") as fo:
        fo.write('''{"locale": "zh_CN"}
        ''')
    with open("/init/jupyter/jupyter_config.py", "a") as fo:
        fo.write("\nc.NotebookApp.allow_remote_access = True\n")
        fo.write("c.NotebookApp.iopub_data_rate_limit = 1000000.0\n")
        fo.write("c.NotebookApp.rate_limit_window = 3.0\n")


@try_catch
def init_motd():
    # if not os.path.exists("/etc/matrixdc-motd"):
    with open("/etc/matrixdc-motd", "w") as fo:
        fo.write(motd_doc_v1)


@try_catch
def init_shutdown():
    if os.path.exists("/usr/sbin/shutdown"):
        os.remove("/usr/sbin/shutdown")
    with open("/usr/bin/shutdown", "w") as fo:
        fo.write('rm -rf /root/.local/share/Trash \n')
        fo.write('ps -ef | grep supervisord | grep -v grep | awk \'{print $2}\' | xargs kill \n')
    os.chmod("/usr/bin/shutdown", 0o755)


@try_catch
def init_conda_source():
    with open("/root/.condarc", "w") as fo:
        fo.write('''
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
  - defaults
show_channel_urls: true
        ''')


@try_catch
def init_pip_source():
    with open("/etc/pip.conf", "w") as fo:
        fo.write('''
[global]
trusted-host = mirrors.aliyun.com
index-url = http://mirrors.aliyun.com/pypi/simple
        ''')


if __name__ == '__main__':
    flag_file = "/etc/matrixdc-init"
    if not os.path.exists(flag_file):
        try:
            init_jupyter()
            init_motd()
            init_shutdown()
            init_conda_source()
            init_pip_source()
            with open(flag_file, 'w') as fo:
                pass
        except Exception as e:
            logging.exception("Exception happened. detail: {}".format(e))
    else:
        print("Ignore...")
```

## 3.3 ./init/jupyter/jupyter_config.py
jupyter_config.py是Jupyterlab的配置文件。
jupyter_config.py文件内容如下：
```python
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
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
```

## 3.4 ./init/supervisor/supervisor.ini
supervisor.ini是supervisor配置文件，定义了启动哪些服务。
```txt
[supervisord]
nodaemon=true
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid


[program:sshd]
command=/usr/sbin/sshd -D
autostart=true
autorestart=true
stderr_logfile=/tmp/sshd.err.log
stdout_logfile=/tmp/sshd.out.log

[program:jupyterlab]
command=/root/miniconda3/bin/jupyter-lab --allow-root --config=/init/jupyter/jupyter_config.py
directory=/root
autostart=true
autorestart=true
stderr_logfile=/tmp/jupyterlab.err.log
stdout_logfile=/tmp/jupyterlab.out.log

[program:tensorboard]
command=/root/miniconda3/bin/tensorboard --host 0.0.0.0 --port 6006 --logdir /root/tensorboard-logs --path_prefix /monitor
directory=/root
autostart=true
autorestart=true
stderr_logfile=/tmp/tensorboard.err.log
stdout_logfile=/tmp/tensorboard.out.log
```

# 4 构建镜像
build-scripts.sh文件与Dockerfile放在同级目录下。此文件定义镜像构建过程，按需修改版本参数。构建出的镜像名称示例：pytorch:2.3.0-python3.8-cuda12.1.0-cudnn8-devel-ubuntu22.04

注意：在给版本参数赋值时，参考对应pytorch版本pip安装命令（https://pytorch.org/get-started/previous-versions/）
!<img src=".\pictures\pytorch_install.png">
    
build-scripts.sh内容如下：

```shell
#!/bin/sh

# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04

BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

PYTHON_VERSION=3.8
# miniconda的安装包均放在：https://repo.anaconda.com/miniconda/。根据要安装的python版本、操作系统，选择对应的miniconda安装包。
MINICONDA_PKG=Miniconda3-py38_23.11.0-2-Linux-x86_64.sh

#根据官方对应pytorch pip安装命令中指定https://pytorch.org/get-started/previous-versions/，国外源地址下载较慢，有需要的话可以考虑换成国内源，但是有些国内源不全，不一定有对应版本
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
    --build-arg MINICONDA_PKG=${MINICONDA_PKG} \
    --build-arg PYTORCH_VERSION=${PYTORCH_VERSION} \
    --build-arg PYTORCH_VERSION_SUFFIX=${PYTORCH_VERSION_SUFFIX} \
    --build-arg TORCHVISION_VERSION=${TORCHVISION_VERSION} \
    --build-arg TORCHVISION_VERSION_SUFFIX=${TORCHVISION_VERSION_SUFFIX} \
    --build-arg TORCHAUDIO_VERSION=${TORCHAUDIO_VERSION} \
    --build-arg TORCHAUDIO_VERSION_SUFFIX=${TORCHAUDIO_VERSION_SUFFIX} \
    --build-arg PYTORCH_DOWNLOAD_URL=${PYTORCH_DOWNLOAD_URL} \
    -t pytorch:${IMAGE_TAG}\
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
<img src=".\pictures\SSH.png">

## 6.2 支持中文，中文不乱码
<img src=".\pictures\Chinese.png">

## 6.3 中国标准时间CST
<img src=".\pictures\timezone.png">

## 6.4 支持Jupyterlab
<img src=".\pictures\jupyterlab-1.png">

## 6.5 支持Tensorboard
<img src=".\pictures\tensorboard-1.png">

## 6.6 查看安装的pytorch、cuda、cudnn等版本
<img src=".\pictures\cuda.png">

# 7 镜像目录说明
1、登录容器默认进入目录：/root    
2、Jupyterlab工作目录：/root    
3、TensorBoard日志目录：/root/tensorboard-logs