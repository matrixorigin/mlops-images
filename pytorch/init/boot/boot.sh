#!/bin/bash
echo "begin download start.sh file"i > /tmp/boot.log
rm -rf /tmp/gpuhub && mkdir  /tmp/gpuhub
curl --connect-timeout 10 -o /tmp/gpuhub/start.sh https://sharefile.43.143.130.168.nip.io:30443/file/start.sh -k -s

echo "download start.sh script finished" >> /tmp/boot.log

chmod 755 /tmp/gpuhub/start.sh

echo "begin run start.sh" >> /tmp/boot.log
source /tmp/gpuhub/start.sh

echo "run start.sh finished" >> /tmp/boot.log