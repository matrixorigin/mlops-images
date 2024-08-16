#!/bin/bash
echo "begin download start.sh file" > /tmp/boot.log
rm -rf /tmp/gpuhub && mkdir  /tmp/gpuhub
# 如果是要跑在h100机器上，http://sharefile.neolink.com/file/start.sh需要改成http://sharefile.neolink.com/file/start-h100.sh
curl --connect-timeout 10 -o /tmp/gpuhub/start.sh http://sharefile.neolink.com/file/start.sh -k -s

echo "download start.sh script finished" >> /tmp/boot.log

chmod 755 /tmp/gpuhub/start.sh

echo "begin run start.sh" >> /tmp/boot.log
source /tmp/gpuhub/start.sh

echo "run start.sh finished" >> /tmp/boot.log