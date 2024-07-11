# -*- coding: utf-8 -*-
import os
import logging
import requests
# update
motd_doc_v1 = '''#!/bin/bash

printf "+----------------------------------------------------------------------------------------------------------------+\n"
printf "\033[32m目录说明:\033[0m\n"
printf "╔═════════════════╦════════╦════╦═════════════════════════════════════════════════════════════════════════╗\n"
printf "║目录             ║名称    ║速度║说明                                                                     ║\n"
printf "╠═════════════════╬════════╬════╬═══════════════════════════════════════════════════════���═════════════════╣\n"
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
jupyter_config = '''c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False

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

c.ServerApp.allow_remote_access = True
c.ServerApp.base_url='/jupyter/'
c.ServerApp.allow_origin='*'
'''

supervisor_conf = '''[supervisord]
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
command=/root/miniconda3/bin/jupyter-lab --allow-root --config=/root/.jupyter/jupyter_config.py
directory=/root
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
redirect_stderr=true

[program:tensorboard]
command=/root/miniconda3/bin/tensorboard --host 0.0.0.0 --port 6006 --logdir /root/tensorboard-logs --path_prefix /monitor
directory=/root
autostart=true
autorestart=true
stderr_logfile=/tmp/tensorboard.err.log
stdout_logfile=/tmp/tensorboard.out.log
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
    with open("/root/.jupyter/jupyter_config.py", "w") as fo:
        fo.write(jupyter_config)


@try_catch
def init_supervisor():
    supervisor_ini_path = "/init/supervisor"
    if not os.path.exists(supervisor_ini_path):
        os.makedirs(supervisor_ini_path)
    with open(os.path.join(supervisor_ini_path, "supervisor.ini"), "w") as fo:
        fo.write(supervisor_conf)


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
            init_supervisor()
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