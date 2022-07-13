---
title: docker-swarm
author: wuxinheng
date: 2022-07-24 23:01:27
description: docker编排
categories:
  - docker
tags:
  - docker-swarm
---
### docker-swarm

准备三台虚拟机，同一个网络环境

192.168.85.131

```shell
hostnamectl set-hostname manager01
```

192.168.85.132

```shell
hostnamectl set-hostname node01
```

192.168.85.133

```shell
hostnamectl set-hostname node02
```

初始化swarm

```shell
docker swarm init --advertise-addr 192.168.85.131
```

加入集群的方式

```shell
docker swarm join --token SWMTKN-1-4qqtadhn8y0iwkrnl44bsdarokkw9teofoieyn01vnduj88zje-5trtkf44l8w5uft8dkyb26lf9 192.168.85.131:2377
```

查看节点信息

```shell
# 都可以查看
docker info
docker node ls
```

修改节点状态

> drain、active两个状态，设置为drain容器自动删除，并运行在其他节点上。

```shell
docker node update --availability drain manater01
# --availability 是否可用
```

部署服务

```shell
docker service create --replicas 1 --network nginx_net --name my_nginx -p 80:80 nginx
# --replicas 设置服务实例个数。
```

查看正在运行的服务

```shell
docker service ls
```

查看运行服务的节点

```shell
docker service ps my_nginx
```

删除服务

```shell
docker service rm my_nginx
```

查看服务信息

```shell
docker service inspect --pretty my_nginx
# --pretty 人性化打印信息
```

动态设置服务实例

```shell
# 都可以实现
docker service scale my_nginx=4
docker service update --replicas 3 my_nginx
```

升级服务镜像

```shell
docker service update --image nginx:new my_nginx
# nginx:new [new]新版本或指定版本
```

常用命令

### docker swarm 常用命令

| 命令                            | 说明                 |
| ------------------------------- | -------------------- |
| docker swarm init               | 初始化集群           |
| docker swarm join-token worker  | 查看工作节点的 token |
| docker swarm join-token manager | 查看管理节点的 token |
| docker swarm join               | 加入集群中           |

### docker node 常用命令

| 命令                | 说明                               |
| ------------------- | ---------------------------------- |
| docker node ls      | 查看所有集群节点                   |
| docker node rm      | 删除某个节点（`-f`强制删除）       |
| docker node inspect | 查看节点详情                       |
| docker node demote  | 节点降级，由管理节点降级为工作节点 |
| docker node promote | 节点升级，由工作节点升级为管理节点 |
| docker node update  | 更新节点                           |
| docker node ps      | 查看节点中的 Task 任务             |

### docker service 常用命令

| 命令                   | 说明                         |
| ---------------------- | ---------------------------- |
| docker service create  | 部署服务                     |
| docker service inspect | 查看服务详情                 |
| docker service logs    | 产看某个服务日志             |
| docker service ls      | 查看所有服务详情             |
| docker service rm      | 删除某个服务（`-f`强制删除） |
| docker service scale   | 设置某个服务个数             |
| docker service update  | 更新某个服务                 |

### docker stack 常用命令

| 命令                  | 说明                         |
| --------------------- | ---------------------------- |
| docker stack deploy   | 部署新的堆栈或更新现有堆栈   |
| docker stack ls       | 列出现有堆栈                 |
| docker stack ps       | 列出堆栈中的任务             |
| docker stack rm       | 删除堆栈                     |
| docker stack services | 列出堆栈中的服务             |
| docker stack down     | 移除某个堆栈（不会删除数据） |

参考

[Docker Swarm_程涯的博客-CSDN博客_docker swarm](https://blog.csdn.net/Olivier0611/article/details/123447725)

[Docker 三剑客之 Docker Swarm - 田园里的蟋蟀 - 博客园 (cnblogs.com)](https://www.cnblogs.com/xishuai/p/docker-swarm.html)

