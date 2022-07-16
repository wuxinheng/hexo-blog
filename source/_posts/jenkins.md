---
title: jenkins使用
author: wuxinheng
description: 本文介绍了centos docker和windows中安装jenkins,以及具体的使用。
date: 2022-07-13 22:21:14
tags:
- CI/CD
- docker构建jenkins
- jenkis部署.netcore
- jenkis部署uniapp
- uniapp自动推送微信
- jenkis
categories:
- jenkins
---

# `docker`构建`jenkins` 容器

## `jenkins` 安装

### 拉取镜像

```shell
docker pull jenkins/jenkins:lts
```

### 构建容器

创建文件夹存储数据

```
mkdir /data/jenkins_home
```

给文件夹授权

```
chmod 777 /data/jenkins_home
```

一定要映射到卷，不然后面无法使用`docker`命令

```shell
docker run -d --name jenkins -p 8081:8080 -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/bin/docker -v /data/jenkins_home:/var/jenkins_home -d jenkins/jenkins:lts
```

### 查看`jenkins`密码

```shell
# 查看容器
docker ps -a
# 进入容器
docker exec -u 0 -it 21ee4816aac1 /bin/bash
# 查看指定文件内容
cat /var/jenkins_home/secrets/initialAdminPassword #密码
```

### 使用及问题

第一次运行成功，后续无法启动，状态显示Exited，需要设置文件夹权限，获取到`Jenkins`的`uid`，进行赋权

```
sudo chown 1000:1000 /data/jenkins_home
```

虽然映射到卷，`jenkis`使用`docker`可以，但是其他`docker` 命令不行。还需要将当前用户添加到用户组

```shell
# 添加用户组
groupadd docker
# 添加用户到用户组(root:根据实际场景)
sudo usermod -a -G docker root
# 上面类容还不行，就修改文件权限
cd /var/run
# 允许读写和执行
chmod 777 docker.sock
```

`jenkins`执行`shell`只执行第一句

```
# shell 第一句加上这个，指定解释器，下面"#"非注释，也可#!/bin/sh
#!/bin/bash
```

时区不对

```shell
# 修复Linux时区，查看上海时区
# 输入
timedatectl list-timezones |grep Shanghai
# 输出
Asia/Shanghai
# 修改时区
timedatectl set-timezone Asia/Shanghai
# 修复jenkins时区
docker exec -it -u root my_jenkins /bin/bash
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo Asia/Shanghai > /etc/timezone
# 站点重启
http://localhost:8080/restart
```

到此时间格式是改变了，还有其他细节上的时间没有改过来少8个小时。在`jenkins`上`系统管理》脚本命令行`运行

```shell
System.setProperty('org.apache.commons.jelly.tags.fmt.timeZone', 'Asia/Shanghai')
```

### 自动化部署`.net core`

```shell
#!/bin/bash
docker stop xblogs_api
docker rm xblogs_api
docker rmi xblogs_api
cp src/xblogs.HttpApi.Host/Dockerfile $PWD
docker build -t xblogs_api .
docker run -v /root/data:/app/inetpub --name xblogs_api -d -p 2022:80 --restart=always xblogs_api 
```

# `Windows`安装

> 前提是已经安装`Jdk 1.8`
> 正常安装`exe`或者`msi`，中间需要选择`jdk`目录，和服务端口。

## 使用场景

### 自动部署`.net core`

正常命令行

```
dotnet publish -c:Release --self-contained false --output D:\wwwroot\wy2\8000
```

集成到`Jenkins`

```

@echo 停止应用程序池
C:\Windows\System32\inetsrv\appcmd.exe stop apppool "wy2"

@echo 删除应用程序池
C:\Windows\System32\inetsrv\appcmd.exe delete apppool "wy2"

@echo 停止站点
C:\Windows\System32\inetsrv\appcmd.exe stop site "wy2"

@echo 删除站点
C:\Windows\System32\inetsrv\appcmd.exe delete site "wy2"

@echo 进入项目目录
cd "%WORKSPACE%\ShuWen.Property\"

@echo 生成项目到指定文件夹
dotnet publish -c:Release --self-contained false --output D:\wwwroot\wy2\8000


@echo 新增应用程序池
C:\Windows\System32\inetsrv\appcmd.exe add apppool /name:"wy2" /managedRuntimeVersion:"v4.0"

@echo 新增站点
C:\Windows\System32\inetsrv\appcmd.exe add site /name:"wy2" /bindings:http/*:8000: /applicationDefaults.applicationPool:"wy2" /physicalPath:"D:\wwwroot\wy2\8000"

@echo 停止应用程序池
@echo C:\Windows\System32\inetsrv\appcmd.exe stop apppool "wy2"

@echo 启动应用程序池
@echo C:\Windows\System32\inetsrv\appcmd.exe start apppool "wy2"

@echo 停止站点
C:\Windows\System32\inetsrv\appcmd.exe stop site "wy2"

@echo 启动站点
C:\Windows\System32\inetsrv\appcmd.exe start site "wy2"

```
思路

Git （pull）==> Localhost（Docker build）==> Images（Run Imgage）==> Container

实现

```
docker stop wuye
docker rm wuye
docker rmi wuye
cd /var/jenkins_mount/workspace/wuye2_dev
docker build -t wuye .
docker run --name wuye -p 2022:80 --restart=always wuye
echo "success"
```


### `uniapp`自动打包推送微信平台

正常命令行

- 运行HBuilderX

> 【坑】HBuilderX 3.3.7-alpha，支持使用CLI发行微信小程序。`注意版本`
> uni-app发行 - 微信小程序 - HBuilderX 文档 (dcloud.net.cn)

```
e: # 进入e盘
cd E:\HBuilderX.3.3.10.20220124.full\HBuilderX # 进入指定目录
start HBuilderX.exe #
```

> 【坑】运行HBuilderX，一定要先运行这是前提条件，命令行是以此应用程序为服务，否则会提示无服务等问题。`运行编辑器`

- 操作项目

```
# 关闭项目,当前版本存在bug,关闭路径需要'/'
cli project close --path D:\Projects\wuye_wechat_wy\jiushi-property-side-applet
# 打开项目
cli project open --path D:\Projects\wuye_wechat_wy\jiushi-property-side-applet
```

- 编译上传

```
# 仅编译uni-app项目到微信小程序，不发行
cli publish --platform mp-weixin --project jiushi-property-side-applet
# 编译uni-app项目到微信小程序，并发行小程序到微信平台
cli publish --platform mp-weixin --project jiushi-property-side-applet --upload true --appid wxe95734bb5d9a1665 --description uniapp-cli发布 --version 2.0.2 --privatekey D:\private.wxe95734bb5d9a1665.key
```

> 【坑】设置ip白名单(提示管道信息是因为微信检验ip白名单没有通过，要么设置白名单，要么不要关闭白名单)

- privatekey 小程序上传密钥文件

```
开发》开发管理》开发设置》小程序代码上传》生成指定秘钥文件
```

集成到`Jenkins`

```
e: 
cd E:\HBuilderX.3.3.10.20220124.full\HBuilderX
start HBuilderX.exe 
cli project close --path C:/ProgramData/Jenkins/.jenkins/workspace/uniapp_wy/
cli project open --path C:\ProgramData\Jenkins\.jenkins\workspace\uniapp_wy\
cli publish --platform mp-weixin --project uniapp_wy --upload true --appid wxe95734bb5d9a1665 --description uniapp-cli发布1 --privatekey D:\wuxinheng\private.wxe95734bb5d9a1665.key
```