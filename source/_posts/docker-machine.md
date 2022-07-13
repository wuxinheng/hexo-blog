---
title: 'docker-machine[官方弃用]'
author: wuxinheng
description: >-
  好消息，在我写这篇文档得时候，最有一个问题一直没有解决。我就去了github上发现这个项目21年8月已经停更了。微软将docker
  desktop做为替代品。因为这篇文章记录怎么解决了电脑开启虚拟化cpu问题我选择保留这篇文章。docker系列在这也算短暂的完结。
categories:
  - docker
tags:
  - docker-machine
  - 电脑开启虚拟换CPU
  - VT-x
  - VT-d
  - vm
  - 虚拟机
date: 2022-07-25 16:39:00
---
## docker-machine[官方弃用]

> 好消息，在我写这篇文档得时候，最有一个问题一直没有解决。我就去了github上发现这个项目21年8月已经停更了。微软将docker desktop做为替代品。
> 因为这篇文章记录怎么解决了电脑开启虚拟化cpu问题我选择保留这篇文章

安装

```shell
curl -L https://github.com/docker/machine/releases/download/v0.12.0/docker-machine-`uname -s`-`uname -m` > /tmp/docker-machine
chmod +x /tmp/docker-machine
sudo mv /tmp/docker-machine /usr/local/bin/docker-machine
```

验证

```shell
docker-machine -v
```

安装virtualbox

1.在/etc/yum.repos.d/目录下新建virtualbox.repo并写入如下内容

[virtualbox]
name=Oracle Linux / RHEL / CentOS-$releasever / $basearch - VirtualBox
baseurl=http://download.virtualbox.org/virtualbox/rpm/el/$releasever/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.virtualbox.org/download/oracle_vbox.asc

2.更新yum缓存

yum clean all

yum makecache

3.安装virtualbox

yum install VirtualBox-6.1

4.下载boot2docker.iso

boot2docker.iso 必须是命令行提示的版本

参考：[Docker 三剑客之 Docker Swarm - 田园里的蟋蟀 - 博客园 (cnblogs.com)](https://www.cnblogs.com/xishuai/p/docker-swarm.html)

创建

```
docker-machine create -d virtualbox default
```

启动

> 启动出现设置网络被拒绝，暂时还没解决，先到这

```shell
docker-machine start default
```

暂停

```
docker-machine stop default
```



### docker-machine 常用命令

| 命令                   | 说明                                        |
| ---------------------- | ------------------------------------------- |
| docker-machine create  | 创建一个 Docker 主机（常用`-d virtualbox`） |
| docker-machine ls      | 查看所有的 Docker 主机                      |
| docker-machine ssh     | SSH 到主机上执行命令                        |
| docker-machine env     | 显示连接到某个主机需要的环境变量            |
| docker-machine inspect | 输出主机更多信息                            |
| docker-machine kill    | 停止某个主机                                |
| docker-machine restart | 重启某台主机                                |
| docker-machine rm      | 删除某台主机                                |
| docker-machine scp     | 在主机之间复制文件                          |
| docker-machine start   | 启动一个主机                                |
| docker-machine status  | 查看主机状态                                |
| docker-machine stop    | 停止一个主机                                |

[docker创建本地主机实例Virtualbox 驱动出错 - JK_night - 博客园 (cnblogs.com)](https://www.cnblogs.com/effortday/p/15026423.html)

没有再深化了,创建虚拟机提示virtualbox不存在，不过我也看见有人使用其他的虚拟机驱动是可以的具体没试过。我用自己的电脑开启VTD之后还是不行。服务器也试过了。这一块等有机会吧再补充吧。

补充：

这里有很多地方需要修改才能启动vm虚拟化引擎

1.修改BOIS
2.关闭Hyper-V
3.关闭Windows沙盒
4.关闭Windows虚拟机监控程序平台
5.内核隔离关闭

中间可能需要多次重启。需要停掉虚拟机才能修改，挂起是不行的

[win11系统vmware虚拟机报错“不支持嵌套虚拟化”问题解决方案汇总_小へ斌斌丶呀~的博客-CSDN博客_vmware在此主机上不支持嵌套虚拟化](https://blog.csdn.net/qq_44777532/article/details/124662130)