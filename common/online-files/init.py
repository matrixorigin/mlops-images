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
printf "╠═════════════════╬════════╬════╬═════════════════════════════════════════════════════════════════════════╣\n"
printf "║/                ║系 统 盘║快  ║一般系统依赖以及Python安装包都会安装在系统盘下，也可以存放代码等小容量的 ║\n"
printf "║                 ║        ║    ║数据；实例关机可选择将已有环境和数据保存到镜像中，下次开机数据可恢复。   ║\n"
printf "╠═════════════════╣════════╣════╣═════════════════════════════════════════════════════════════════════════╣\n"
printf "║用户定义的路径   ║数 据 盘║快  ║数据盘挂载路径默认是/root/data，用户可自定义。可以存放数据。             ║\n"
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
  memory="$((limit_in_bytes / 1024 / 1024 / 1024)) G"
  printf "\033[32m内存\033[0m：%s\n" "${memory}"
else
  cores=$(cat /sys/fs/cgroup/cpu.max | awk '{print $1/$2}')
  printf "\033[32mCPU\033[0m ：%s 核心\n" ${cores}

  limit_in_bytes=$(cat /sys/fs/cgroup/memory.max)
  memory="$((limit_in_bytes / 1024 / 1024 / 1024)) G"
  printf "\033[32m内存\033[0m：%s\n" "${memory}"
fi

if type nvidia-smi >/dev/null 2>&1; then
  gpu=$(nvidia-smi -i 0 --query-gpu=name,count --format=csv,noheader)
  printf "\033[32mGPU \033[0m：%s\n" "${gpu}"
fi

df_stats=`df -ah`
printf "\033[32m存储\033[0m：\n"

# 处理系统盘展示
disk=$(echo "$df_stats" | grep "/$" | awk '{print $5" "$3"/"$2}')
printf "\033[32m  系统盘 /\033[0m：%s\n" "${disk}"

# 处理数据盘展示
# 分别处理两个模式
disk_data_juicefs=$(echo "$df_stats" | grep "JuiceFS:system-juicefs" | awk '{print $6" : "$5" "$3"/"$2}')
disk_data_neo=$(echo "$df_stats" | grep "neo-fileserver:/shared-files" | awk '{print $6" : "$5" "$3"/"$2}')

# 合并两个结果
disk_data="$disk_data_juicefs"
disk_data+="
$disk_data_neo"

# 使用 IFS 设置换行符作为字段分隔符，并读取到数组中
IFS=$'\n' read -d '' -r -a data_disks <<< "$disk_data"

# 遍历数组并打印每一条记录
for line in "${data_disks[@]}"; do
  # 分割 line 以获取路径和其余信息
  IFS=' : ' read -r path rest <<< "$line"
  # 使用绿色输出数据盘信息，保持其余信息默认颜色
  printf "\033[32m  数据盘 %s\033[0m：%s\n" "$path" "$rest"
done

printf "+----------------------------------------------------------------------------------------------------------------+\n"

alias sudo=""
'''


jupyter_config = '''c = get_config()

c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
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

# 从 ENV JUPYTER_TOKEN 中获取 Jupyter token，如果无此 ENV，则不指定 token
import os
jupyter_token = os.environ.get('JUPYTER_TOKEN')
print(f"JUPYTER_TOKEN value: {jupyter_token}")
if jupyter_token:
    c.IdentityProvider.token = jupyter_token
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


# 设置不打印hami日志
hami_log_level = '''export LIBCUDA_LOG_LEVEL=0'''


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
def init_profile():
    with open("/etc/profile", "r") as fo:
        lines = fo.readlines()
    # 检查行是否已经存在
    if hami_log_level not in lines:
        # 如果不存在，打开文件并追加行
        with open("/etc/profile", 'a') as fo:
            fo.write(hami_log_level + '\n')

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
        fo.write('''[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
        ''')


@try_catch
def init_apt_source():
    if not os.path.exists("/etc/apt/source.list.bak"):
        command = "cp -a /etc/apt/source.list /etc/apt/source.list.bak"
        os.system(command)
    with open("/etc/apt/source.list", "w") as fo:
        fo.write('''
deb [arch=amd64] http://172.24.162.98/ubuntu/ jammy main restricted universe multiverse
deb [arch=amd64] http://172.24.162.98/ubuntu/ jammy-security main restricted universe multiverse
deb [arch=amd64] http://172.24.162.98/ubuntu/ jammy-updates main restricted universe multiverse
deb [arch=amd64] http://172.24.162.98/ubuntu/ jammy-proposed main restricted universe multiverse
deb [arch=amd64] http://172.24.162.98/ubuntu/ jammy-backports main restricted universe multiverse
        ''')


if __name__ == '__main__':
    flag_file = "/etc/matrixdc-init"
    if not os.path.exists(flag_file):
        try:
            init_jupyter()
            init_supervisor()
            init_motd()
            init_profile()
            init_shutdown()
            init_conda_source()
            init_pip_source()
            init_apt_source()
            with open(flag_file, 'w') as fo:
                pass
        except Exception as e:
            logging.exception("Exception happened. detail: {}".format(e))
    else:
        print("Ignore...")
