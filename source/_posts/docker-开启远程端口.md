---
title: docker 开启远程端口
author: wuxinheng
date: 2022-08-11 23:09:50
description: docker 开启远程端口，引起病毒感染。事件全过程
categories:
  - docker
tags:
- docker
- remote api
---
### docker 开启远程端口

在不连接服务器的前提下。docker也提供了一种远程api进行操作docker.

> 这里需要注意的是开启docker remote api 安全性大大下降。建议：
>
> 采用https、更换默认端口等操作。

我这里只演示最简单的开启

```shell
systemctl show --property=FragmentPath docker
```

```shell
vi /usr/lib/systemd/system/docker.service
```

```shell
# 大概14行左右的位置。我服务器上显示一大串。我在后面补上没有效果。我直接替换了，原代码注释
ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock
```

```shell
systemctl daemon-reload
```

```shell
systemctl restart docker
```

验证

访问：http:{ip}:2375,会显示json数据则成功。

有坑！会中毒！

