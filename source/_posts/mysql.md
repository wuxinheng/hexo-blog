---
title: 在docker中部署mysql
author: wuxinheng
description: 本文介绍了centos docker部署持久化mysql。
date: 2022-07-15 20:48:00
tags:
- mysql
- 数据库
- deploy
categories:
- docker
---

### mysql 安装

#### 拉取镜像

```shell
docker pull mysql:5.7
```

#### 构建容器

```shell
docker run --restart=always -d -p 3306:3306 --privileged=true -v /docker/mysql/conf/my.cnf:/etc/my.cnf -v /docker/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --name mysql mysql:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci
```

#### 修改密码

```shell
# 进入容器
docker exec -it mysql bash
# 登录mysql
mysql -uroot -p
# 输入密码后, 执行下面命令创建新用户 (用户名: root , 密码: 123456)
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION;
```

#### 版本升级

与普通安装相似，需要先暂停原有的mysql容器，记得先备份。然后拉取新版本mysql,运行修改密码。然后重启。原来旧版本的mysql镜像可以删除。