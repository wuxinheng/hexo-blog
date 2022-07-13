---
title: 在docker中部署wtm
author: wuxinheng
description: 本文说明了dotnet快速开发框架wtm如何在docker中部署，以及项目文件结构变化大之后Dockerfile应该如何更改，验证码无法显示、指定nuget源等问题具体解决办法。
date: 2022-07-15 20:48:00
tags:
- docker
- wtm
- dotnet
- linux验证码
- gdip
- System.Drawing 兼容问题
- deploy
categories:
- dotnet
---

#### 拉取镜像

```shell
docker pull mcr.microsoft.com/dotnet/sdk:5.0
```

#### 验证

```shell
# 输入
docker images
# 结果
mcr.microsoft.com/dotnet/sdk     5.0
mcr.microsoft.com/dotnet/aspnet  5.0
```

#### 创建doccker配置文件

`Visual Studio`右键项目创建`Docker`支持

#### 打包项目镜像

- 使用Dockerfile打包镜像

  ```shell
  # 当前文件夹打包镜像
  docker build -t 镜像名称 .
  # 当前文件夹使用指定文件打包镜像
  docker build -f xxx/Dockerfile -t 镜像名称 .
  ```

#### 构建容器

```shell
docker run --name 容器名称 -p 2022:80 --restart=always 镜像名称
```

#### 解决问题

##### System.Drawing 兼容问题

###### 验证码不显示

修改Dockerfile

```shell
# 更新包
RUN apt-get update
# 安装apt-get 安装 libc6-dev , libgdiplus  用于支持system.drawing 组件绘制,默认ubuntu命令
#RUN apt-get update && apt-get install -y apt-utils libgdiplus libc6-dev
# 配置apt的资源，采用阿里云资源仓库 必须是debian 10 buster版本
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
   echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib" >/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb http://mirrors.aliyun.com/debian-security buster/updates main" >>/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main" >>/etc/apt/sources.list && \
   echo "deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >>/etc/apt/sources.list
RUN  apt-get update && apt-get install -y apt-utils libgdiplus libc6-dev
```

##### Dockerfiled修改

> 当前项目后期我们进行的大范围改动，包括项目文件夹的移动、使用封装之后通用类库的Nuget包。
>
> 过程中发我使用jenkins发现。无法使用原有dockerfile进行安装。我对dockerfile进行了修改。

###### 文件路径修改

见下面

###### 指定Nuget 包源

```dockerfile
# 指定项目基于什么框架
FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
# 更新apt-ger
RUN apt-get update
# 设置包源
RUN mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
   echo "deb http://mirrors.aliyun.com/debian/ buster main non-free contrib" >/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian/ buster main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb http://mirrors.aliyun.com/debian-security buster/updates main" >>/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian-security buster/updates main" >>/etc/apt/sources.list && \
   echo "deb http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian/ buster-updates main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >>/etc/apt/sources.list && \
   echo "deb-src http://mirrors.aliyun.com/debian/ buster-backports main non-free contrib" >>/etc/apt/sources.list
# 安装库，此处是支持gdip
RUN  apt-get update && apt-get install -y apt-utils libgdiplus libc6-dev
# 进入指定目录
WORKDIR /app
# 指定端口
EXPOSE 80
# 指定基于5.0生成
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
# 此处复制相关项目的依赖，如果项目后期改动，会导致后期打包失败，项目目录根据实际情况来
COPY ["Property/ShuWen.Property/ShuWen.Property.csproj", "Property/ShuWen.Property/"]
COPY ["Property/ShuWen.Property/nuget.config", "Property/ShuWen.Property/"]
COPY ["src/WalkingTec.Mvvm.TagHelpers.LayUI/WalkingTec.Mvvm.TagHelpers.LayUI.csproj", "src/WalkingTec.Mvvm.TagHelpers.LayUI/"]
COPY ["src/WalkingTec.Mvvm.Core/WalkingTec.Mvvm.Core.csproj", "src/WalkingTec.Mvvm.Core/"]
COPY ["src/WalkingTec.Mvvm.Mvc/WalkingTec.Mvvm.Mvc.csproj", "src/WalkingTec.Mvvm.Mvc/"]
COPY ["Common/ShuWen.Common.csproj", "Common/"]
COPY ["ShuWen.Property.DataAccess/ShuWen.Property.DataAccess.csproj", "ShuWen.Property.DataAccess/"]
COPY ["ShuWen.Property.Model/ShuWen.Property.Model.csproj", "ShuWen.Property.Model/"]
COPY ["Property/ShuWen.Property.ViewModel/ShuWen.Property.ViewModel.csproj", "Property/ShuWen.Property.ViewModel/"]
# 此步跟启动vs项目前的生成或者第一次打开项目生成项目很像nuget包还原。实际也做得是nuget包还原。此处需要指定包源。我的包源写在nuget.config中
RUN dotnet restore "Property/ShuWen.Property/ShuWen.Property.csproj"  --configfile "Property/ShuWen.Property/nuget.config"
COPY . .
WORKDIR "Property/ShuWen.Property/"
# 对项目进行打包
RUN dotnet build "ShuWen.Property.csproj" -c Release -o /app/build
FROM build AS publish
# 发布项目
RUN dotnet publish "ShuWen.Property.csproj" -c Release -o /app/publish
FROM base AS final
WORKDIR /app
# 将项目复制到指定的文件夹
COPY --from=publish /app/publish .
# 运行项目
ENTRYPOINT ["dotnet", "ShuWen.Property.dll"]
```

nuget.config 内容：

```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
	<packageSources>
		<add key="Nuget.org" value="https://api.nuget.org/v3/index.json" />
		<add key="Baget" value="http://47.100.94.46:5555/v3/index.json" />
	</packageSources>
</configuration>
```

