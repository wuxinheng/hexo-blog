---
title: centos一键安装jenkins
description: 在centos中通过执行shell脚本自动化在docker部署jenkins
author: wuxinheng
tags:
  - docker
  - jenkins
  - shell
  - 脚本
  - sh
  - deploy
categories:
  - jenkins
date: 2022-07-15 22:59:00
---

## jenkins

```shell

# 前提：服务器docker已经运行，当前服务器是centos
#!/bin/bash

echo "开始拉取镜像"
docker pull jenkins/jenkins:lts
echo "拉取镜像完毕"

echo "创建本地文件夹"
if [ ! -d "/data/jenkins_home" ];then
  mkdir /data/jenkins_home
  echo "本地文件夹创建完成"
  else
  echo "本地文件夹已存在"
fi

echo "本地文件夹赋权"
chmod 777 /data/jenkins_home
echo "赋权完成"

if [[ "$(docker inspect [jenkins] 2> /dev/null | grep '"Name": "/[jenkins]"')" == "" ]]; then
  echo "已存在名为jenkins的容器"
  echo "准备停止删除"
  docker stop jenkins
  echo "停止成功"
  docker rm jenkins
  echo "删除成功"
fi


echo "运行jenkins"
docker run -d --name jenkins -p 8081:8080 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/bin/docker -v /data/jenkins_home:/var/jenkins_home -d jenkins/jenkins:lts
echo "运行完成"

jenkins_pwd1="#!/bin/bash" 
jenkins_pwd2="echo 'jenkins 初始密码:'" 
jenkins_pwd3="cat /var/jenkins_home/secrets/initialAdminPassword"  
jenkins_pwd4="exit"

echo ${jenkins_pwd1}>jenkins.sh
echo ${jenkins_pwd2}>>jenkins.sh
echo ${jenkins_pwd3}>>jenkins.sh
echo ${jenkins_pwd4}>>jenkins.sh

echo "复制文件"
docker cp  jenkins.sh jenkins:/jenkins.sh
rm -f  jenkins.sh

echo "进入容器"
docker exec -u 0 -it jenkins /bin/bash /jenkins.sh

echo "添加用户组"
groupadd docker
echo "添加用户到用户组(root:根据实际场景)"
sudo usermod -a -G docker root
echo "修改文件权限"
cd /var/run
echo "允许读写和执行"
chmod 777 docker.sock
timedatectl set-timezone Asia/Shanghai
echo "修复jenkins时区"

jenkins_time1="#!/bin/bash" 
jenkins_time2="echo '替换时区文件'" 
jenkins_time3="cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime"  
jenkins_time4="exit"

echo ${jenkins_time1}>jenkins.sh
echo ${jenkins_time2}>>jenkins.sh
echo ${jenkins_time3}>>jenkins.sh
echo ${jenkins_time4}>>jenkins.sh

echo "复制文件"
docker cp  jenkins.sh jenkins:/jenkins.sh
rm -f  jenkins.sh
echo "进入容器"
docker exec -u 0 -it jenkins /bin/bash /jenkins.sh


echo "安装完毕"
echo "请执行下面站点操作！对时间没有强制要求可以不执行"
echo "站点操作："
echo "[站点地址]/restart"
echo "jenkins上[系统管理》脚本命令行]运行:"
echo "System.setProperty('org.apache.commons.jelly.tags.fmt.timeZone', 'Asia/Shanghai')"

```

