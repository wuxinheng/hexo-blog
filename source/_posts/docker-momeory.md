---
title: docker-momeory
author: wuxinheng
date: 2022-07-24 23:02:12
description: docker容器的内存动态把控
categories:
  - docker
tags:
  - momeory
  - 容器内存控制
---

### docker内存控制

docker容器默认继承主机所有内存这样非常不好。当内存足就会自动kill掉容器

实际使用中发现jenkins容器多次被系统终止，因为是自己的服务器只有2G运存。我决定对服务其上的容器进行内存限制

```shell
docker run -d --name jenkins -p 8081:8080 -m 512m --memory-swap 512m  -v /var/run/docker.sock:/var/run/docker.sock -v $(which docker):/bin/docker -v /data/jenkins_home:/var/jenkins_home -d jenkins/jenkins:lts
```

| 名称、简写             | 默认 | 描述                                                         |
| ---------------------- | ---- | ------------------------------------------------------------ |
| `--memory`,`-m`        |      | 内存限制                                                     |
| `--memory-reservation` |      | 内存软限制，单位和-m一致。当设置了这个参数以后，如果宿主机系统内存不足，有新的内存请求时刻，那么linux会尝试从设置了此参数的容器里回收内存，回收的办法就是swap了。那么如果此容器还在继续使用内存，那么此容器会遇到很大的性能下降。 |
| `--memory-swap`        |      | 交换限制等于内存加交换：“-1”以启用无限制交换，配置容器可以设置的swap大小。此值为-m值加上能达到的swap区大小 |
| `--memory-swappiness`  | `-1` | 调整容器内存交换（0 到 100）                                 |

查看容器性能

```shell
docker stats
```