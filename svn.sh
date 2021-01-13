#!/bin/bash
echo '
>>> SVN初始用户：xunyou
>>> SVN初始密码：xunyou'


svn --version &> /dev/null
if [ $? != 0 ] ;then
	num=1
else
	num=2
fi

echo
case $num in
1)
	echo '#SVN尚未安装，将自动执行安装#'
	svnPath='/var/svn'
	read -p"开启SVN的端口号(默认3690):" svnPort
	[ -z $svnPort ] && svnPort=3690
	read -p"创建的版本库名称：" svnName
	read -ep"需要版本化的目录：" webPath
	[[ $webPath =~ .*/$ ]] && webPath=`echo $webPath |sed 's@/$@@'`
	if [ ! -d $svnPath ] ;then
		mkdir $svnPath
		echo "$svnPath目录已自动创建！"
	else
		echo "$svnPath目录已存在！"
	fi
	yum install -y subversion
	svnserve -dr $svnPath --listen-port $svnPort
	[ $? != 0 ] && echo "错误：请检查是否 ${svnPort} 端口已被占用！" && exit
	svnadmin create ${svnPath}/${svnName}
	
	cat>${svnPath}/${svnName}/conf/svnserve.conf<<-EOF
	[general]
	anon-access = none
	auth-access = write
	password-db = passwd
	authz-db = authz
	realm = $svnName
	[sasl]
	EOF

	cat>>${svnPath}/${svnName}/conf/passwd<<-EOF
	xunyou = xunyou
	EOF

	cat>${svnPath}/${svnName}/conf/authz<<-EOF
	[aliases]
	
	[groups]
	admin = xunyou
	
	[/]
	@admin = rw
	EOF

	svn co svn://127.0.0.1:${svnPort}/${svnName} ${webPath}
	svn add ${webPath}/* --force
	svn ci ${webPath} -m "${svnName}"
	[ $? != 0 ] && echo '添加失败！退出...' && exit
	chmod -R 777 ${webPath}
	cat>${svnPath}/${svnName}/hooks/post-commit<<-EOF
	#!/bin/sh
	export LANG=en_US.UTF-8
	svn update ${webPath} --username xunyou --password xunyou
	EOF
	chmod +x ${svnPath}/${svnName}/hooks/post-commit
;;

2)
	svnPort=`ss -anp | grep svnserve | awk '{print $5}' | awk -F: '{print $NF}'`
	[ -z $svnPort ] && echo "[svnserve]未启动，请启动后再重试！" && exit
	svnPath=`ps -x | grep svnserve | grep -v grep | sed "s@.*\s\(/[^\ ]*\)\s*.*@\1@"`
	[[ $svnPath =~ .*/$ ]] && svnPath=`echo $svnPath |sed 's@/$@@'`
	read -p"将要新建的版本库名称：" svnName
	read -ep"需要版本化的路径：" webPath
	[[ $webPath =~ .*/$ ]] && webPath=`echo $webPath |sed 's@/$@@'`
	svnadmin create ${svnPath}/${svnName}

	cat>${svnPath}/${svnName}/conf/svnserve.conf<<-EOF
	[general]
	anon-access = none
	auth-access = write
	password-db = passwd
	authz-db = authz
	realm = $svnName
	[sasl]
	EOF

	cat>>${svnPath}/${svnName}/conf/passwd<<-EOF
	xunyou = xunyou
	EOF

	cat>${svnPath}/${svnName}/conf/authz<<-EOF
	[aliases]

	[groups]
	admin = xunyou

	[/]
	@admin = rw
	EOF

	svn co svn://127.0.0.1:${svnPort}/${svnName} ${webPath}
	svn add ${webPath}/* --force
	svn ci ${webPath} -m "${svnName}"
	[ $? != 0 ] && echo '添加失败！退出...' && exit
	cat>${svnPath}/${svnName}/hooks/post-commit<<-EOF
	#!/bin/sh
	export LANG=en_US.UTF-8
	svn update ${webPath} --username xunyou --password xunyou
	EOF

	chmod +x ${svnPath}/${svnName}/hooks/post-commit

;;
*)
	echo "错误的输入！"
	exit
esac
echo -e "\e[32m 添加完成！\e[0m" 

IP=`curl  -s httpbin.org/ip | awk -F'"' '/origin/{print $4}'`
if echo $IP | grep ','; then
	IP=`echo $IP | awk -F',' '{print $1}'`
fi

port=''
if [ $svnPort != 3690 ] ; then
	port=":${svnPort}"
fi

echo -e "\e[33m 
	SVN地址：svn://${IP}${port}/${svnName}
	配置路径：${svnPath}/${svnName}
\e[0m"
