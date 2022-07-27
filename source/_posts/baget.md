---
title: 在docker中部署私有化NuGet
description: 本文介绍了如何在docker中部署私有化nuget。已经nuget使用
author: wuxinheng
date: 2022-07-15 20:48:00
tags:
- deploy
- docker
- 批量上传nupkg
- bat
- NuGet私有化
- dotnet
categories:
- dotnet
---

> 私有化NuGet

#### 创建项目配置文件

项目的根目录创建`baget.env`文件，文件内容如下

```nginx
# 以下配置是用于发布包的 API Key。
# 你应该把它改成一个秘密值来保护你的服务器。
ApiKey=你的秘钥

#文件存储方式和路径
Storage__Type=FileSystem
Storage__Path=/var/baget/packages

#数据存储的方式和路径，此处配置要和appsettings.json一致
#Database__Type=Sqlite
#Database__ConnectionString=Data Source=/var/baget/baget.db
Database__Type=MySql
Database__ConnectionString=Server=127.0.0.1;Database=BaGet;Uid=root;Pwd=123456;

#查询的类型
Search__Type=Database
```

#### 打包

```shell
docker build  -t baget .
```

#### 运行

```shell
docker run  --rm --name baget -d -p 5555:80 --env-file baget.env -v "$(pwd)/baget-data:/var/baget" loicsharma/baget:latest
```

#### 注意

1. 下面三处的`ApiKey`需要一致

- 代码工程的`appsettings.json`的`ApiKey`
- `baget.env`文件`ApiKey`
- 上传包`--api-key`

1. 数据存储方式配置一致
   `baget.env`文件要和appsettings.json一致

#### NuGet

##### 上传

```shell
# 进入nupkg所在文件夹，使用命令行。
dotnet nuget push -s http://ip:5555/v3/index.json XXX.nupkg -k apiKey
```

##### 删除

```shell
dotnet nuget delete ShuWen.Common 1.0.0 --non-interactive -s http://ip:5555/v3/index.json -k shuwenNuGet
```

> 编辑：配置nupkg版本和其他信息使用`NuGetPackageExplorer`工具

##### git仓库地址

```shell
# NuGetPackageExplorer编辑器代码仓库
https://github.com/NuGetPackageExplorer/NuGetPackageExplorer.git
# BaGet代码仓库
https://github.com/loic-sharma/BaGet.git
```

##### 设置visual studio包源

```shell
# 命令行,设置完成之后重启
dotnet nuget add source http://ip:5555/v3/index.json -n name_xx
```

##### 批处理上传

将所有的nupkg放在同一的文件夹下，新建bat文件，复制下面内容运行根据自己的地址进行修改。

```bash
:: close echo
@echo off
:: init params
set url=http://ip:5555/v3/index.json
set deployFile=*.nupkg
set apikey=shuwenNuGet
echo Searching nupkg file...
rem 启用"延缓环境变量扩充"
SETLOCAL ENABLEDELAYEDEXPANSION
for %%f in (%deployFile%) do (
   set name=%%f
   echo !name! to deploy to %url%
   rem deploy to server
   dotnet nuget push -s %url%  !name!  -k %apikey%
)

pause
```

