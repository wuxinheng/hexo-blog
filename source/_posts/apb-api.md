---
title: apb-api
author: wuxinheng
date: 2022-08-24 22:24:26
description: abp使用
categories:
  - abp
tags:
- dotnet
---
## API

### 自动api控制器

**必要条件**：`Application` 项目中的 `Service` 必须实现`IApplicationService`

**规范**：`Application.Contracts` 项目定义`Application`中`Service`需要实现的接口，接口可以直接实现`IApplicationService`

**具体操作**：在`Application`项目中`ApplicationModule`类`ConfigureServices`方法加入以下代码

> 并不是ApplicationModule.cs，是与实际项目中*ProjectName*ApplicationModule.cs,下面代码也是如此。

```c#
Configure<AbpAspNetCoreMvcOptions>(options =>
        {
            options
                .ConventionalControllers
                .Create(typeof(ApplicationModule).Assembly);
        });
```

### 动态C# API客户端

**必要条件**：在`xblogs.HttpApi.Client`项目中`AbpModule`派生类`ConfigureServices`方法中加入以下代码：

> 并不是ApplicationContractsModule.cs，是与实际Application.Contracts项目中*ProjectName*ApplicationContractsModule.cs,下面代码也是如此。

```C#
// 创建动态客户端代理
context.Services.AddHttpClientProxies(
     typeof(ApplicationContractsModule).Assembly
);
```

**具体操作**：`xblogs.HttpApi`项目中正常写控制器，正常开发就可以了。