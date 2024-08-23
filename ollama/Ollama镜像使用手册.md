# Ollama+WebUI镜像使用手册

...

# 一、镜像概览

Ollama+WebUI 包含以下核心组建

- **TensorFlow**：一个广泛使用的开源机器学习框架，支持多种类型的神经网络和深度学习模型。
- **SSH服务**：提供安全的远程登录功能，便于您在不同的机器上管理和运行容器。
- **Miniconda**：一个轻量级的conda环境，让您轻松管理Python环境和安装所需的第三方库。
- **Python**：科学计算和数据分析的标准编程语言。
- **Ollama**:  基于Golang和llama.cpp 的大语言模型运行时框架,兼容 OpenAI API 以及Phi3, Gemma2, Llama 系列大模型.
- **Open WebUI**: 基于 Ollama 接口的大模型交换界面。

# 三、使用指南

## 3.1. 启动 Ollama+WebUI

1. 在Terminal下通过`ollama serve`启动ollama服务，可以通过{URL}:11434访问到
2. 访问JupyterLab：打开JupyterLab 的 Terminal 界面
3. 进入`/app/backend`, 通过`export PORT=3000;./start.sh`即可启动webui服务。默认端口为3000, 可以通过修改PORT ENV来暴露不同端口
4. 如何访问: ssh -v -L 3000:0.0.0.0:3000 -p {容器暴露的ssh端口} root@{实例的HOST}
