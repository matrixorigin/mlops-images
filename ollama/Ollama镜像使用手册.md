# Ollama+WebUI镜像使用手册

...

# 一、镜像概览

Ollama+WebUI 包含以下核心组建

- **TensorFlow**：一个广泛使用的开源机器学习框架，支持多种类型的神经网络和深度学习模型。
- **SSH服务**：提供安全的远程登录功能，便于您在不同的机器上管理和运行容器。
- **Miniconda**：一个轻量级的conda环境，让您轻松管理Python环境和安装所需的第三方库。
- **Python**：科学计算和数据分析的标准编程语言。
- **JupyterLab**：一个交互式的开发环境，支持Notebook、文本编辑器、终端等多组件，非常适合数据探索和实验。
- **TensorBoard**：TensorFlow的可视化工具，用于监控训练过程、模型性能和数据分布。
- **Ollama**:  基于Golang和llama.cpp 的大语言模型运行时框架,兼容 OpenAI API 以及Phi3, Gemma2, Llama 系列大模型.
- **Open WebUI**: 基于 Ollama 接口的大模型交换界面。

# 二、

# 三、使用指南

## 3.1. JupyterLab使用

1. 访问JupyterLab：在浏览器中输入`http://host:8888`即可访问JupyterLab（请将host替换成您所使用的ip或域名）。
2. 登录：首次访问时，您需要输入密码。密码可以在启动容器时的输出日志中找到，通常是一串随机生成的字符串。
3. 使用：登录后，您可以开始使用JupyterLab编写和运行Python代码，管理文件等。

## 3.2. 启动 Ollama+WebUI

1. 镜像默认通过`ollama serve`启动ollama服务，可以通过{URL}:11434访问到
1. 访问JupyterLab：打开JupyterLab 的 Terminal 界面
2. 进入`/app/backend`, 通过`./start.sh`即可启动webui服务。默认端口为3000
