---
title: docker-compose
author: wuxinheng
date: 2022-07-18 23:37:38
description: 本文从具体使用角度简单介绍了如何去使用docker-compose 部署项目和修改项目文件
categories:
  - docker
tags:
  - docker-compose
  - dotnet
---

### 编写docker-compose.yml

> 项目文件结构本来不是现在这个样子。由于使用的是dotnet Wtm开发框架，生成代码的原因。对文件结构进行了改动。
>
> Dockerfile是在没有移动之前就创建了。如果解决方案文件在目标项目文件目录中，或者低于其他引用的项目文件VS提示无法添加。但是，不要慌！
> 这根本不是问题。我们自己可以仿写一个Dockerfile。这个过程中需要注意两点。1、修改目标项目需要的文件复制信息（包括引用文件）和项目信息2、打包容器是否需要指定Dockerfile文件。
> 可以在Dokcerfile中指定国内镜像。方便安装一些其他插件
>
> Docker-compose。应为好像也跟Dockerfile一样的原因。可能提示你失败之后文件出现在目标项目文件夹中。但是肯定不对！
> 我是自己新建一个项目创建的Docker-compose。然后把项目文件和.yml文件粘贴到整个项目文件夹中。然后到vs添加docker-compse项目
>
> 然后根据自己需求修改配置文件即可。

#### 演示项目文件目录说明

```shell
C:.
├─Property  # 多租户
│  ├─ShuWen.Property # 展示层
│  │ ├─Dockerfile # 构建镜像的文本文件
│  │ ├─appsettings.json # 应用程序配置文件
│  │ ├─nuget.config # 私有化nuget配置文件
│  │ ├─ShuWen.Property.sln # ShuWen.Property 解决方案
│  └─ShuWen.Property.ViewModel # 业务逻辑
├─PropertyHost # 管理平台
│  ├─Shuwen.Property.Host # 展示层
│  │ ├─Dockerfile # 构建镜像的文本文件
│  │ ├─appsettings.json # 应用程序配置文件
│  │ ├─nuget.config # 私有化nuget配置文件
│  │ ├─ShuWen.Property.Host.sln # ShuWen.Property.Host 解决方案
│  └─Shuwen.Property.Host.ViewModel # 业务逻辑
├─ShuWen.Property.DataAccess # 数据访问
├─ShuWen.Property.Model # 通用实体
├─src # 框架源代码
├─docker-compose.dcproj # 不是dotnet开发可以忽略
├─docker-compose.override.yml # 编排文件，override 开发应该都懂
└─docker-compose.yml # 编排文件
```

##### ShuWen.Property/Dockerfile

```ini
FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base

# 更新 apt-get,简单的说容器内核基于Ubuntu。
RUN apt-get update 
# 更换国内镜像
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
  echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib" >/etc/apt/sources.list && \
  echo "deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib" >>/etc/apt/sources.list && \
  echo "deb http://mirrors.aliyun.com/debian-security buster/updates main" >>/etc/apt/sources.list && \
  echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main" >>/etc/apt/sources.list && \
  echo "deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/sources.list && \
  echo "deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/sources.list && \
  echo "deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >>/etc/apt/sources.list && \
  echo "deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >>/etc/apt/sources.list
# Linux上是没有GDI+，于是 Mono 团队使用C语言实现了 GDI+ 接口，提供对非 Windows 系统的 GDI+ 接口访问能力，这个就是libgdiplus
RUN  apt-get update && apt-get install -y apt-utils libgdiplus libc6-dev

WORKDIR /app
EXPOSE 80
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build

WORKDIR /src
COPY ["Property/ShuWen.Property/ShuWen.Property.csproj", "Property/ShuWen.Property/"]
COPY ["Property/ShuWen.Property/nuget.config", "Property/ShuWen.Property/"]

COPY ["src/WalkingTec.Mvvm.TagHelpers.LayUI/WalkingTec.Mvvm.TagHelpers.LayUI.csproj", "src/WalkingTec.Mvvm.TagHelpers.LayUI/"]
COPY ["src/WalkingTec.Mvvm.Core/WalkingTec.Mvvm.Core.csproj", "src/WalkingTec.Mvvm.Core/"]
COPY ["src/WalkingTec.Mvvm.Mvc/WalkingTec.Mvvm.Mvc.csproj", "src/WalkingTec.Mvvm.Mvc/"]


COPY ["ShuWen.Property.DataAccess/ShuWen.Property.DataAccess.csproj", "ShuWen.Property.DataAccess/"]

COPY ["ShuWen.Property.Model/ShuWen.Property.Model.csproj", "ShuWen.Property.Model/"]

COPY ["Property/ShuWen.Property.ViewModel/ShuWen.Property.ViewModel.csproj", "Property/ShuWen.Property.ViewModel/"]

RUN dotnet restore "Property/ShuWen.Property/ShuWen.Property.csproj"  --configfile "Property/ShuWen.Property/nuget.config"

COPY . .
WORKDIR "Property/ShuWen.Property/"
RUN dotnet build "ShuWen.Property.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "ShuWen.Property.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "ShuWen.Property.dll"]
```

##### nuget.config

```
<?xml version="1.0" encoding="utf-8"?>
<configuration>
	<packageSources>
		<add key="Nuget.org" value="https://api.nuget.org/v3/index.json" />
		<add key="Baget" value="http://ip:5555/v3/index.json" />
	</packageSources>
</configuration>
```

##### docker-compose.yml

```shell
version: '3.4'

services:
  shuwen.property:
    image: ${DOCKER_REGISTRY-}shuwen.property # 镜像名称
    build:
      context: .
      dockerfile: Property/ShuWen.Property/Dockerfile #docker文件地址
    ports: 
      - "5001:80"	# 主机端口：容器端口
      
  shuwen.property.host:
    image: ${DOCKER_REGISTRY-}shuwen.property.host
    build:
      context: .
      dockerfile: PropertyHost/Shuwen.Property.Host/Dockerfile
    ports: 
      - "5002:80"

```

##### docker-compose.override.yml

```shell
version: '3.4'

services:
  shuwen.property:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_URLS=http://+:80	# 运行地址,加上443要求使用ssl，我就删除了，后期通过nginx来处理吧
      # - ASPNETCORE_URLS=https://+:443;http://+:80
    ports: 
      - "5001:80" # 主机端口：容器端口
    volumes:
      - ${APPDATA}/Microsoft/UserSecrets:/root/.microsoft/usersecrets:ro
      - ${APPDATA}/ASP.NET/Https:/root/.aspnet/https:ro
  shuwen.property.host:
    environment:
      - ASPNETCORE_ENVIRONMENT=Development
      - ASPNETCORE_URLS=http://+:80
      # - ASPNETCORE_URLS=https://+:443;http://+:80
    ports: 
      - "5002:80"
    volumes:
      - ${APPDATA}/Microsoft/UserSecrets:/root/.microsoft/usersecrets:ro
      - ${APPDATA}/ASP.NET/Https:/root/.aspnet/https:ro
```

### 安装

> 不建议使用pip安装，经常报错。能解决报错除外！

```shell
# github太慢使用下面daocloud地址
sudo curl -L https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
# daocloud地址
sudo curl -L https://get.daocloud.io/docker/compose/releases/download/1.25.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
# 添加可执行权限
sudo chmod +x /usr/local/bin/docker-compose
# 验证
docker-compose --version
```

### 打包

```shell
docker-compose build
```

### 运行

```shell
docker-compose up -d
```

