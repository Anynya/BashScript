#!/bin/bash

# 手动修改以下信息
#-#-#-#-#
NAME=""
PROJECT="讯有商城"
SITE="www.xunyoutest.com"
#-#-#-#-#


# 检查所需软件
rpm -q sysstat &> /dev/null || yum -y install sysstat
rpm -q wget &> /dev/null || yum -y install wget


# 获取本机公网IP
IP=`curl  -s httpbin.org/ip | awk -F'"' '/origin/{print $4}'`
if echo $IP | grep ','; then
	IP=`echo $IP | awk -F',' '{print $1}'`
fi


# CPU状态
cpu_num=`nproc` 
cpu_usage=`sar -u 1 1 | tail -n1 | awk '{printf "%s%",$3}'`


#内存状态
mem_total=`free -h | awk '/^Mem/{printf "%s",$2}'`
mem_free=`free -h | awk '/^Mem/{printf "%s",$NF}'`
mem_total_m=`free -m | awk '/^Mem/{printf "%d",$2}'`
mem_free_m=`free -m | awk '/^Mem/{printf "%d",$NF}'`
mem_used_m=$[ $mem_total_m - $mem_free_m ]
mem_usage=`echo "$mem_used_m $mem_total_m" | awk '{printf "%d%",$1*100/$2}'`


# 硬盘状态
disk=`df -h | awk '/^\/dev\/[sv]/{i++ ;printf "disk%d:(%s/%s) | ",i,$4,$2}' | sed 's/..$//'`


# WEB状态
if lnmp nginx status | grep running &> /dev/null; then
	WEB="Nginx(正常)"
elif systemctl status nginx &> /dev/null; then
	WEB="Nginx(正常)"
elif systemctl status httpd &> /dev/null; then
	WEB="Apache(正常)"
elif ! ss -lt | grep http | grep -v grep &> /dev/null; then
	WEB="(关闭)"
else
	WEB="unknown"
fi


# 数据库状态
if lnmp mysql status | grep SUCCESS &> /dev/null; then
	ver=`mysql --version | awk -F',' '{print $1}'| awk '{print $NF}'`
	MYSQL="MySQL-${ver}(正常)"
elif systemctl status mysql &> /dev/null; then
	ver=`mysql --version | awk -F',' '{print $1}'| awk '{print $NF}'`
	MYSQL="MySQL-${ver}(正常)"
elif systemctl status mariadb &> /dev/null; then
	ver=`mysql --version | awk -F'-' '{print $1}'| awk '{print $NF}'`
	MYSQL="MariaDB-${ver}(正常)"
elif ! ss -lt | grep mysql | grep -v grep &> /dev/null; then
	MYSQL="(关闭)"
else
	MYSQL="unknown"
fi


# 获取时间
TIME=`date +%F' '%T`


# 推送信息
[ ! -z $NAME ] &&\
wget --output-document=/dev/null "http://shop.xunyoutest.com/service.php?site=${SITE}&ip=${IP}&name=${NAME}&project=${PROJECT}&cpu=${cpu_usage}(${cpu_num}%E6%A0%B8)&mem=${mem_free}/${mem_total}&disk=${disk}&web=${WEB}&mysql=${MYSQL}&update=${TIME}"
