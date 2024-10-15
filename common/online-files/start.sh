#!/bin/bash

# 配置文件和路径
LOG_FILE="/tmp/boot.log"

# 函数: 捕获异常
function try_catch() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "Exception happened. detail: $?"
    fi
}

# 初始化 Jupyter 配置
function init_jupyter() {
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/terminal-extension
    mkdir -p /root/.jupyter/lab/user-settings/@jupyterlab/translation-extension

    echo '{"theme": "dark"}' > /root/.jupyter/lab/user-settings/@jupyterlab/terminal-extension/plugin.jupyterlab-settings
    echo '{"locale": "zh_CN"}' > /root/.jupyter/lab/user-settings/@jupyterlab/translation-extension/plugin.jupyterlab-settings

    cat << EOF > /root/.jupyter/jupyter_config.py
c = get_config()

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

import os
jupyter_token = os.environ.get('JUPYTER_TOKEN')
print(f"JUPYTER_TOKEN value: {jupyter_token}")
if jupyter_token:
    c.IdentityProvider.token = jupyter_token
EOF
}

# 初始化 Supervisor 配置
function init_supervisor() {
    mkdir -p /init/supervisor

    cat << EOF > /init/supervisor/supervisor.ini
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
command=jupyter-lab --allow-root --config=/root/.jupyter/jupyter_config.py
directory=/root
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
redirect_stderr=true

[program:tensorboard]
command=tensorboard --host 0.0.0.0 --port 6006 --logdir /root/tensorboard-logs --path_prefix /monitor
directory=/root
autostart=true
autorestart=true
stderr_logfile=/tmp/tensorboard.err.log
stdout_logfile=/tmp/tensorboard.out.log

EOF

    if code-server --version > /dev/null 2>&1; then
        cat << EOF >> /init/supervisor/supervisor.ini
[program:code-server]
command=/usr/bin/code-server --bind-addr 0.0.0.0:8889 --disable-telemetry --disable-update-check --disable-workspace-trust --disable-getting-started-override /root
environment=PASSWORD=%(ENV_CODESERVER_PASSWORD)s
autostart=true
autorestart=true
stderr_logfile=/tmp/code-server.err.log

EOF
    fi

    if ray --version > /dev/null 2>&1; then
        cat << EOF >> /init/supervisor/supervisor.ini
[program:ray]
command=bash -c 'if [ -n "\$KUBERAY_GEN_RAY_START_CMD" ]; then bash -lc "ulimit -n 65536; \$KUBERAY_GEN_RAY_START_CMD"; else bash -c "ulimit -n 65536; ray start --head --block --port=6379"; fi'
autostart=true
autorestart=true
stderr_logfile=/tmp/ray.err.log

EOF
    fi

    cat << EOF >> /init/supervisor/supervisor.ini
[include]
files=/etc/supervisord/supervisor-other.ini
EOF
}

# 初始化 MOTD
function init_motd() {
    cat << EOF > /etc/matrixdc-motd
#!/bin/bash

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
  cfs_quota_us=\$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
  cfs_period_us=\$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
  if [ \$cfs_quota_us -ge \$cfs_period_us ]; then
      cores=\$((cfs_quota_us / cfs_period_us))
  else
      cores=0.\$((cfs_quota_us * 10 / cfs_period_us))
  fi
  printf "\033[32mCPU\033[0m ：%s 核心\n" \${cores}

  limit_in_bytes=\$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
  memory="\$((limit_in_bytes / 1024 / 1024 / 1024)) G"
  printf "\033[32m内存\033[0m：%s\n" "\${memory}"
else
  cores=\$(cat /sys/fs/cgroup/cpu.max | awk '{print \$1/\$2}')
  printf "\033[32mCPU\033[0m ：%s 核心\n" \${cores}

  limit_in_bytes=\$(cat /sys/fs/cgroup/memory.max)
  memory="\$((limit_in_bytes / 1024 / 1024 / 1024)) G"
  printf "\033[32m内存\033[0m：%s\n" "\${memory}"
fi

if type nvidia-smi >/dev/null 2>&1; then
  gpu=\$(nvidia-smi -i 0 --query-gpu=name,count --format=csv,noheader)
  printf "\033[32mGPU \033[0m：%s\n" "\${gpu}"
fi

df_stats=\`df -ah\`
printf "\033[32m存储\033[0m：\n"

# 处理系统盘展示
disk=\$(echo "\$df_stats" | grep "/\$" | awk '{print \$5" "\$3"/"\$2}')
printf "\033[32m  系统盘 /\033[0m：%s\n" "\${disk}"

# 处理数据盘展示
disk_data_juicefs=\$(echo "\$df_stats" | grep "JuiceFS:system-juicefs" | awk '{print \$6" : "\$5" "\$3"/"\$2}')
disk_data_neo=\$(echo "\$df_stats" | grep "neo-fileserver:/shared-files" | awk '{print \$6" : "\$5" "\$3"/"\$2}')

disk_data="\$disk_data_juicefs"
disk_data+="
\$disk_data_neo"

IFS=\$'\n' read -d '' -r -a data_disks <<< "\$disk_data"

for line in "\${data_disks[@]}"; do
  IFS=' : ' read -r path rest <<< "\$line"
  printf "\033[32m  数据盘 %s\033[0m：%s\n" "\$path" "\$rest"
done

printf "+----------------------------------------------------------------------------------------------------------------+\n"
EOF
}

# 初始化 profile
function init_profile() {
    hami_log_level="export LIBCUDA_LOG_LEVEL=0"

    if ! grep -Fxq "$hami_log_level" /etc/profile; then
        echo "$hami_log_level" >> /etc/profile
        echo "export HF_ENDPOINT=https://hf.neolink-ai.com" >> /etc/profile
    fi
}

# 初始化 shutdown 脚本
function init_shutdown() {
    if [ -e /usr/sbin/shutdown ]; then
        rm /usr/sbin/shutdown
    fi

    cat << EOF > /usr/bin/shutdown
#!/bin/bash
rm -rf /root/.local/share/Trash
ps -ef | grep supervisord | grep -v grep | awk '{print \$2}' | xargs kill
EOF
    chmod 755 /usr/bin/shutdown
}

# 初始化 Conda 源
function init_conda_source() {
    cat << EOF > /root/.condarc
channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
  - defaults
show_channel_urls: true
EOF
}

# 初始化 pip 源
function init_pip_source() {
    cat << EOF > /etc/pip.conf
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
}

# 初始化 apt 源
function init_apt_source() {
    # 如果 /etc/apt/sources.list.d 目录存在，则备份它
    if [ -d /etc/apt/sources.list.d ]; then
        mv /etc/apt/sources.list.d /etc/apt/sources.list.d.bak
    fi

    # 检查sources.list.bak备份文件是否存在
    if [ ! -e /etc/apt/sources.list.bak ]; then
        # 如果 /etc/apt/sources.list 文件存在，则备份它
        if [ -e /etc/apt/sources.list ]; then
            cp -a /etc/apt/sources.list /etc/apt/sources.list.bak
        fi
    fi
    # 写入新的 apt 源配置
    cat <<EOF > /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ jammy-backports main restricted universe multiverse
EOF

    # 更新 apt 包列表
    # apt update
}

# 初始化 SSH 配置
function init_ssh_config() {
    config_lines=(
        "PermitRootLogin yes"
        "PasswordAuthentication yes"
        "ClientAliveInterval 60"
        "ClientAliveCountMax 5"
    )

    for line in "${config_lines[@]}"; do
        if ! grep -Fxq "$line" /etc/ssh/sshd_config; then
            echo "$line" >> /etc/ssh/sshd_config
        fi
    done
}

# 函数: 写入日志
function log_info() {
    echo "$1" >> "$LOG_FILE"
}

# 函数: 初始化环境
function initialize_environment() {
    log_info "init.py init begin, source /etc/profile"
    source /etc/profile || true
    log_info "$PATH"
}

# 函数: 设置 SSH 密码
function set_ssh_password() {
    log_info "begin set passwd"
    if ! grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi

    mkdir -p /run/sshd || true

    if [ -f "/sync/root-passwd" ]; then
        local root_passwd
        root_passwd=$(cat "/sync/root-passwd")
        echo "root:$root_passwd" | chpasswd
        rm "/sync/root-passwd"
        log_info "passwd set finished"
    else
        log_info "Error: /sync/root-passwd file not found."
    fi
}

# 函数: 创建 TensorBoard 日志目录
function create_tensorboard_dir() {
    mkdir -p "/root/tensorboard-logs"
    log_info "create tensorboard dir finished"
}

# 函数: 启动 supervisord
function start_supervisord() {
    # 如果supervisord bin文件被被人删了，需要重新拷贝
    log_info "begin copy supervisord if /bin/supervisor no exist"
    if [ ! -f "/bin/supervisord" ]; then
        cp -f /init/bin/* /bin/
        if [ -f "/bin/supervisord" ]; then
            log_info "supervisord bin set finished"
        else
            log_info "supervisord bin not found"
        fi
    else
        log_info "/bin/supervisord文件存在"
    fi

    log_info "run supervisord begin"
    /bin/supervisord -c /init/supervisor/supervisor.ini
}

# 主程序
function main() {
    initialize_environment
    set_ssh_password
    create_tensorboard_dir

    flag_file="/etc/matrixdc-init"

    if [ ! -e "$flag_file" ]; then
        try_catch init_jupyter
        try_catch init_supervisor
        try_catch init_motd
        try_catch init_profile
        try_catch init_ssh_config
        try_catch init_shutdown
        try_catch init_conda_source
        try_catch init_pip_source
        try_catch init_apt_source

        touch "$flag_file"

    else
        echo "Ignore..."
    fi

    start_supervisord
}

# 执行主程序
main
