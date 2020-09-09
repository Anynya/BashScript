#!/bin/bash
ss -atu | grep 'TIME-WAIT' | grep -v '127.0.0.1' | awk '{print $2"#"$6}'| awk -F: '{print $1 }'| sort | uniq -c |\
while read line
do
	#echo $line
	wait_num=`echo $line | awk '{print $1}'`
	if [ $wait_num -gt 250  ] ;
	then
		ban_ip=`echo $line | awk '{print $2}' | awk -F'#' '{print $2}'`	
		iptables -I INPUT -p tcp -s $ban_ip -j DROP
	fi
done
