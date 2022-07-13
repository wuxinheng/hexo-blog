---
title: docker-pack
author: wuxinheng
date: 2022-07-24 23:01:47
description: docker容器的打包成镜像，以及镜像的上传
categories:
  - docker
tags:
  - docker-pack
  - 镜像制作
---
### docker打包

将容器打包到镜像

```shell
# docker commit [-m="提交的描述信息"] [-a="创建者"] 容器名称|容器ID 生成的镜像名[:标签名]
docker commit -m="use nginx deploy my-hexo-blog" -a="wuxinheng" hexo-blog wxh-hexo:1.0
```

保存镜像到本地

```shell
# docker save -o 保存的PathName 镜像名:标签
docker save -o /wxh-hexo.tar wxh-hexo:1.0
```

加载镜像文件

```shell
# docker load -i 镜像备份文件
docker load -i /wxh-hexo.tar
```

docker登录

```shell
# 用户名就真是是用户名，不是邮箱
docker login
# 验证
docker images ls
```

提交到镜像仓库

```shell
# 修改标签，会创建一个新的镜像
docker tag wxh-hexo:1.0  wuxinheng/wxh-hexo
# 提交镜像，网络不好可能会出现408,多请求就好了，需要把镜像提交到 [用户名]/images
docker push wuxinheng/wxh-hexo:latest
```

拉取镜像

```shell
# 网络不好可能会出现408,多请求就好了
docker pull wuxinheng/wxh-hexo:latest
```

运行镜像

```C#
docker run -d --name hexo -p 4000:80 wuxinheng/wxh-hexo:latest
```

[Docker发布镜像时报错denied: requested access to the resource is denied解决办法_刺客765的博客-CSDN博客](https://blog.csdn.net/Florine113/article/details/121748462)

[解决Error response from daemon: Get https://registry-1.docker.io/v2/library/hello-world/manifests/问题_权权qxj的博客-CSDN博客](https://blog.csdn.net/quanqxj/article/details/79479943)

[Docker 容器创建镜像并提交到Docker hub_xinaml的博客-CSDN博客_docker 镜像提交](https://blog.csdn.net/xinaml/article/details/77573644)