#!/bin/bash
echo "init.py init begin, source /etc/profile" >> /tmp/boot.log
source /etc/profile || true
echo $PATH >> /tmp/boot.log

# 设置SSH登录密码
echo "begin set passwd" >> /tmp/boot.log
[ -f /sync/root-passwd ] && root_passwd=$(cat /sync/root-passwd) && echo "root:$root_passwd" | chpasswd && rm /sync/root-passwd
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
mkdir -p /run/sshd || true
echo "passwd set finished" >> /tmp/boot.log

# 拷贝supervisor bin脚本
echo "begin copy supervisord if /bin/supervisor no exist" >> /tmp/boot.log
if [ -f "/bin/supervisord" ]; then
  echo "/bin/supervisord文件存在" >> /tmp/boot.log
else
  cp -f /init/bin/* /bin/
  [ -f /bin/supervisord ] && echo "supervisord bin set finished" >> /tmp/boot.log 
fi

echo "begin download init script" >> /tmp/boot.log 
curl --connect-timeout 10 -o /tmp/gpuhub/init.py http://sharefile.neolink.com/file/init-h100.py -k -s
echo "download init script finished" >> /tmp/boot.log

mkdir -p /root/tensorboard-logs
echo "create tensorboard dir finished" >> /tmp/boot.log

echo "begin run init script" >> /tmp/boot.log
python /tmp/gpuhub/init-h100.py
rm -rf /tmp/gpuhub
echo "run init script finished" >> /tmp/boot.log


echo "pre cmd finished" >> /tmp/boot.log

echo "supervisord begin" >> /tmp/boot.log
/bin/supervisord -c /init/supervisor/supervisor.ini