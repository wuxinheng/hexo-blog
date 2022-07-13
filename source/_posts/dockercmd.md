---
title: dockercmd
author: wuxinheng
date: 2022-08-24 22:24:49
description: docker 常用命令
categories:
  - docker
tags:
- cmd
---
| 命令                                                         | 备注                         |
| ------------------------------------------------------------ | ---------------------------- |
| sudo systemctl start docker                                  | 启动docker                   |
| sudo systemctl stop docker                                   | 停止docker                   |
| sudo systemctl restart docker                                | 重启docker                   |
| sudo systemctl daemon-reload;sudo systemctl restart docker   | 重新加载配置文件，启动docker |
| docker rm 容器名称\容器ID                                    | 移除容器                     |
| docker stop 容器名称\容器ID                                  | 停止容器                     |
| docker rmi 镜像名称\镜像ID                                   | 移除镜像                     |
| docker build  -t 镜像名称 .                                  | 打包镜像                     |
| docker run  --rm --name 容器名称 -d -p 5555:80  镜像名称     | 构建容器                     |
| docker search 包名                                           | docker搜索                   |
| docker pull 包名:版本                                        | docker拉取                   |
| docker version                                               | docker版本                   |
| docker ps                                                    | 正在运行的容器               |
| docker images                                                | docker的镜像                 |
| docker exec -it -u root 容器名称 /bin/bash                   | 进入容器                     |
| docker --help                                                | docker帮助                   |
| docker info                                                  | docker信息                   |
| docker start 容器名称\容器ID                                 | 启动容器                     |
| docker stop 容器名称\容器ID                                  | 停止容器                     |
| docker restart 容器名称\容器ID                               | 重启容器                     |
| docker kill 容器名称\容器ID                                  | 强制停止容器                 |
| docker logs 容器名称\容器ID                                  | 查看容器日志                 |
| docker stop $(docker ps -a -q)                               | 停止所有容器                 |
| docker  rm $(docker ps -a -q)                                | 删除所有容器                 |
| docker update --restart=always 容器名称\容器ID               | 修改容器配置                 |
| docker rmi -f $(docker images -qa) | 删除所有镜像                 |
| docker network create newnetwork                             | docker创建网络环境           |
| docker network rm newnetwork                                 | docker删除网络环境           |
| docker network ls                                            | docker网络环境列表           |
| docker run -v [本地文件路径]:[容器文件路径]                  | docker 卷的映射，数据持久化  |