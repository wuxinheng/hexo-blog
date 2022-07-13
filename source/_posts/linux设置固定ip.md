---
title: linux设置固定ip
author: wuxinheng
description: linux设置固定ip
date: 2022-09-05 22:13:05
tags:
- 虚拟机
categories:
- linux
---
#### linux设置固定ip

查看网卡

```shell
ifconfig
```

编辑配置文件

```shell
# 这里需要根据实际网卡来进行修改，虚拟机一般是ens33
vim /etc/sysconfig/network-scripts/ifcfg-ens33
```

文件内容

```ini
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="static"  # 原来是dhcp
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="ens33"
UUID="c282b057-0dc8-4c9d-8f51-21fb50fdb2d4"
DEVICE="ens33"
ONBOOT="yes" # yes
IPADDR=192.168.126.128  # 静态地址
GATEWAY=192.168.126.2 # 网关
DNS1=192.168.126.2 # DNS默认和网关一样
```

