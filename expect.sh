#!/bin/bash
while read line
do
ip=`echo $line | awk '{print $1}'`
ps=`echo $line | awk '{print $2}'`
{
expect <<-EOF
set timeout 5
spawn  scp /push_status.sh root@$ip:/etc/cron.hourly/
expect eof
EOF
}&
[ $? == 0  ] && echo $ip >> push_ok.txt
done < hosts_id.txt
