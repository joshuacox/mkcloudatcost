#!/bin/bash
date -I > /tmp/restarted.txt
echo 'start' >> /tmp/restarted.txt
cd /root/mkFreeIPA
make rmall
make prod
make jabber
cd /root/mkRedmine
make run
cd /root/mknginx
make rmall
make prod
echo 'finished' >> /tmp/restarted.txt
