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
# c.ServerApp.token = ""
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
command=tensorboard --host 0.0.0.0 --port 6006 --logdir /root/tensorboard-logs
directory=/root
autostart=true
autorestart=true
redirect_stderr=true

EOF


# 启动supervisord
supervisord -c /init/supervisor/supervisor.ini