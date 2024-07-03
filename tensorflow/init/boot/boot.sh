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
