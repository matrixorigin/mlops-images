本文档旨在说明miniconda镜像构建过程。目标miniconda镜像的要求是：支持ssh登录、root密码、中文支持、中国CST时区，内置Jupyterlab、TensorBoard。
对于miniconda不同conda、python版本来说，此构建过程是通用的，只需将构建镜像脚本中传入的基础镜像、各个版本参数改成自己需要的即可。

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
# 下载并安装 Miniconda，安装路径 /opt/miniconda3
ARG MINICONDA_PKG
ENV PATH=/opt/miniconda3/bin:$PATH
RUN curl -o /tmp/miniconda.sh -LO https://repo.anaconda.com/miniconda/${MINICONDA_PKG} && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm /tmp/miniconda.sh && \
    echo "PATH=$PATH" >> /etc/profile && \
    conda init
    
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
```

# 3 Dockerfile中引用的文件
Dockerfile中引用了init文件夹下。
init文件夹存放在github的common目录下：https://github.com/matrix-dc/mlops-images/tree/main/common/   

注意：构建镜像时，init整个文件夹与Dockerfile放在同级目录下。    
文件夹目录结构如下：
<pre>
/init/
├── bin
│   └── supervisord   #supervisor二进制bin文件，静态文件
├── boot
    └── boot.sh       # CMD启动脚本，静态文件

</pre>

## 3.1 /init/bin/supervisord
/init/bin/supervisord是个bin文件，后续用此supervisord启动服务。  

## 3.2 /init/boot/boot.sh
/init/boot/boot.sh是CMD启动脚本，此脚本中通过curl的方式获取在线文件start.sh，start.sh脚本中其中一个步骤是通过curl获取在线文件init.py，这样组织的好处是：start.sh、init.py文件内容有变化时无需重新Build镜像。        
1、start.sh    
start.sh文件存放在github：https://github.com/matrix-dc/mlops-images/blob/main/common/online-files/start.sh              
start.sh在线地址：https://sharefile.43.143.130.168.nip.io:30443/file/start.sh               
2、init.py   
init.py文件存放在github：https://github.com/matrix-dc/mlops-images/blob/main/common/online-files/init.py                 
init.py在线地址：https://sharefile.43.143.130.168.nip.io:30443/file/init.py                

# 4 构建镜像
build-scripts.sh文件与Dockerfile放在同级目录下。此文件定义镜像构建过程，按需修改版本参数。    
build-scripts.sh内容如下：

```shell
#!/bin/sh

# 按照自己的需要，是否支持GPU/CUDA版本等选择基础镜像
# 如果是用构建支持GPU的，使用nvidia/cuda作为基础镜像；如果仅支持CPU，ubuntu作为基础镜像
# 例如：GPU的：nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04，仅支持CPU的：ubuntu22.04

BASE_IMAGE=nvidia/cuda:12.1.0-cudnn8-devel-ubuntu22.04

PYTHON_VERSION=3.10
MINICONDA_VERSION=3
# miniconda的安装包均放在：https://repo.anaconda.com/miniconda/。根据要安装的miniconda版本、python版本、操作系统，选择对应的miniconda安装包。
MINICONDA_PKG=Miniconda3-py310_24.5.0-0-Linux-x86_64.sh

# 构建后的镜像tag，需要体现pytorch、python、基础镜像版本信息
IMAGE_TAG=conda${MINICONDA_VERSION}-python${PYTHON_VERSION}-cuda12.1.0-cudnn8-devel-ubuntu22.04

docker build \
    --build-arg BASE_IMAGE=${BASE_IMAGE} \
    --build-arg MINICONDA_PKG=${MINICONDA_PKG} \
    -t miniconda:${IMAGE_TAG}\
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
运行容器脚本参考run-example目录下的docker-run.sh（docker直接启动）、k8s-run-deployment.yaml（k8s启动的deployment）。
docker-run.sh文件内容如下:

```shell
#!/bin/bash
# pytorch:xxx需替换成构建好的实际镜像地址。
# 运行pytorch容器，映射ssh 22端口为2222，jupyter端口为8888，tensorboard端口为6006
docker run  -d  -ti \
--restart=always \
--name miniconda-test \
--gpus all \
-p 2222:22 \
-p 8888:8888 \
-p 6006:6006 \
miniconda:conda3-python3.10-cuda12.1.0-cudnn8-devel-ubuntu22.04
```

# 6 验证镜像功能
## 6.1 支持SSH登录成功，登录后有友好提示
<img src=".\pictures\ssh.png">

## 6.2 支持中文，中文不乱码
<img src=".\pictures\language.png">

## 6.3 中国标准时间CST
<img src=".\pictures\timezone.png">

## 6.4 支持Jupyterlab
<img src=".\pictures\jupyterlab.png">

## 6.5 支持Tensorboard
<img src=".\pictures\tensorboard.png">

# 7 镜像目录路径说明
1、登录容器默认进入目录：/root，ssh  root用户默认密码：123456       
2、Jupyterlab工作目录：/root，访问根路径：/jupyter     
3、TensorBoard日志目录：/root/tensorboard-logs，访问根路径：/monitor   