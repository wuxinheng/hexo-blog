---
title: doker使用
author: wuxinheng
description: 本文从具体使用角度简单介绍了如何去使用docker
categories:
  - docker
tags:
  - docker
date: 2022-07-14 22:45:00
---
# docker

## 安装
#### yum下载缓慢

安装yum-utils、lvm2

```
sudo yum install -y yum-utils \device-mapper-persistent-data \lvm2
```

设置包源,不然搜不到docker-ce

```
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
```

官方：`https://download.docker.com/linux/centos/docker-ce.repo`

阿里云：`http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo`

清华：`https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo`

```shell
sudo yum install docker-ce
```

启动

```shell
sudo systemctl start docker
```

验证

```shell
sudo docker version
```

## 使用

- 构建流程

  生成镜像（build images）>运行并配置容器（run container）

- 镜像

  - 查询

    ```shell
    docker search <imagesId/imagesName>
    ```

  - 拉取

    > 拉去镜像不带版本号的话默认拉去最新的。版本号显示latest

    ```
    docker pull <imagesId/imagesName>:version
    ```

  - 删除

    > 镜像没有被使用才可以删除。

    ```
    docker rmi <imagesId/imagesName>
    ```
    
  - 打包

    > 依赖dockerfile文件

    ```
    docker build -t baget .
    ```

- 容器

  - 运行

    ```shell
    # 容器部分以此为例
    docker run --name nginx  -d --net=host  -v /var/nginx/html:/usr/share/nginx/html -v /var/nginx/log:/var/log/nginx/ -v /var/nginx/conf:/etc/nginx nginx:latest
    ```

  - 查询

    ```shell
    # 查询正在运行的容器
    docker ps
    # 查询所有的容器
    docker ps -a
    ```

  - 删除

    ```shell
    docker rm <containerId/containerName>
    ```

  - 修改

    ```shell
    docker container update --restart=always redis
    ```

  - 进入容器

    ```shell
    docker exec -it <containerId/containerName> /bin/bash
    ```

  - 端口

    ```shell
    # 1888为主机端口，8888为容器端口
    docker run --name redis -p 1888:8888 redis:latest
    ```

  - 网络

    ```shell
    # 需要提前创建网络环境，通过--network\net 设置网络
    docker run --rm -d --network host --name my_nginx nginx
    ```

  - 卷（共享文件系统）

    > 常用于数据持久性，有多种使用方式：卷、绑定挂载、tmpfs挂载、管道

    ```shell
    docker run -v [host-src]:[container-src]
    ```
    > 容器与主机文件交互
    ```shell
    docker cp <host-src> <containerId/containerName>:<container-src>
    docker cp <containerId/containerName>:<container-src> <host-src> 
    ```

  - 容器重启策略

    ```shell
    # always表示容器退出时，docker将对容器进行重启
    docker run --restart=always redis
    # on-failure:10表示容器退出时，docker将对容器进行重启最大次数
    docker run --restart=on-failure:10 redis
    ```

- 网络

  > 网络环境有非常多个功能。我用的比较少

  - 新增

    ```shell
    docker network create elastic
    ```

  - 删除

    ```shell
    docker network rm alpine-net
    ```

  - 查看

    ```shell
    docker network ls
    ```

- 卷

  > 卷有很多种方式。我目前主要用的绑定挂载。使用卷的优势可以更方便操作、备份。
  
  - 新建
  
    ```shell
    docker volume create hello
    ```
  
  - 使用
  
    ```shell
    docker run -d -v hello:/world busybox ls /world
    ```
  
  - 删除
  
    ```shell
    # 删除没有使用的卷
    docker volume prune
    # 删除一个卷
    docker volume rm hello
    ```
  
  - 检查
  
    ```shell
    docker volume inspect hello
    ```
  
  - 查看
  
    ```shell
    docker volume ls
    ```
  
- 日志

  > 日志只能监控容器层面。一些程序上的bug无法监测

  ```shell
  docker logs <containerId/containerName>
  ```

- 检查

  > 元数据是容器的配置信息

  ```shell
  # 获取检查进行镜像或者容器信息
  docker inspect <containerId/containerName>|<imagesId/imagesName>
  # -f 允许通过对象方式获取属性信息
  docker inspect -f "{.State.StartedAt}" <containerId/containerName>|<imagesId/imagesName>
  ```