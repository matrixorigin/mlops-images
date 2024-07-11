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
运行容器脚本参考run-example目录下的docker-run.sh（docker直接启动）、k8s-run-deployment.yaml（k8s启动的deployment）。
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

# 7 镜像目录路径说明
1、登录容器默认进入目录：/root，ssh  root用户默认密码：123456       
2、Jupyterlab工作目录：/root，浏览器访问根路径：/jupyter     
3、TensorBoard日志目录：/root/tensorboard-logs，浏览器访问根路径：/monitor   