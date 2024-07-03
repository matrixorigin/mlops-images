本文档旨在说明pytorch镜像运行起来后，如何操作使用。
pytorch镜像内置了SSH登录、miniconda、Jupyterlab、TensorBoard。这里主要介绍这些内置工具的操作使用。
# 1、镜像运行
一般有2种镜像运行方式，一是直接通过docker运行，二是在k8s上运行deploy。
具体运行示例可参考：https://github.com/matrix-dc/mlops-images/tree/main/pytorch/run-example

此镜像涉及到3个端口22（SSH端口）、8888(Jupyterlab)、6006(tensorboard)
在镜像运行后，获取到这3个服务的访问方式。

# 2、SSH 使用
pytorch镜像内置了SSH登录，内置的登录信息：root/123456     
使用xshell等SSH工具进行SSH连接登录。    
SSH登录命令示例：    
ssh -p port root@ip    
这里的ip、port需要替换成实际的。

# 3、miniconda 使用
pytorch镜像内置了miniconda（miniconda已包含python），安装路径为/root/miniconda3/。   
conda常用命令：
```
# 创建虚拟环境
conda create -n test python=3.8           # 构建一个虚拟环境，名为：test
conda init bash && source /root/.bashrc # 更新bashrc中的环境变量
conda activate test                       # 切换到创建的虚拟环境：test

# 安装软件依赖
# 切换conda虚拟环境后
conda install {xxx}={version}    #这里的{xxx}、{version}指的软件名及版本

....
```

# 4、Jupyterlab 使用
JupyterLab是一个交互式的开发环境，是Jupyter Notebook的下一代产品，可以使用它编写Notebook、操作终端、编辑MarkDown文本、打开交互模式、查看csv文件及图片等功能。

pytorch镜像内置了Jupyterlab，其根访问路径是/jupyter。 jupyterlab进入的默认目录是/root。    

用浏览器打开jupyterlab访问方式：http://ip:port/jupyter。    
这里的ip、port需要替换成实际的。 
jupyterlab默认目录是/root。  

首次访问jupyterlab，需要按照访问页面的指引，获得token设置密码。
<img src='.\pictures\jupyterlab使用-1.png'>
使用jupyterlab:   
<img src='.\pictures\jupyterlab-1.png'>

# 6、TensorBoard 使用
pytorch镜像内置了TensorBoard，TensorBoard可对训练结果进行可视化展示。可以使用torch.utils.tensorboard.SummaryWriter来记录训练过程中的信息，训练过程中的信息需要放到tensorboard的logdir目录。   

pytorch镜像内置了TensorBoard，其根访问路径是/monitor，logdir目录是/root/tensorboard-logs
 
用浏览器打开tensorboard访问方式：http://ip:port/monitor。    
这里的ip、port需要替换成实际的。 