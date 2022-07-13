---
title: linux 虚拟机没有ens33网卡信息
description: linux 虚拟机没有ens33网卡信息，重启网络服务解决
author: wuxinheng
tags:
  - 虚拟机网络
categories: 
  - 虚拟机
date: 2022-07-19 21:36:00
---
使用ifconfig遇到没有ens33网络信息

电脑上VMware 创建了三台虚拟机。其中一台无法连接网络我更改了网络连接设置为NAT模式，然后重启还是不行。
参照网友@[白天不懂夜的美♂](https://blog.csdn.net/weixin_53685939/article/details/119732919)


```shell
systemctl stop NetworkManager
systemctl restart network.service
service network restart
```

成功恢复！

