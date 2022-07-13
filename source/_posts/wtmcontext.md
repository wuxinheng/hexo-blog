---
title: wtmcontext
author: wuxinheng
date: 2022-08-24 22:19:47
description: wtmcontext介绍
tags:
- efcore
- saas
- 多租户
- dotnet
- wtm
categories:
- dotnet
---
WTMContext.cs做了什么

1. 在`FrameworkServiceExtension.cs`

   1. 拓展方法`AddWtmContext` 

      1. 使用委托初始化`WtmContextOption`
      2. 使用`WtmContextOption`对象给系统变量赋值
      3. 使用`AddScoped`注入`WTMContext`

   2. 拓展方法`UseWtmContext`

      1. 获取了系统加载运行的基本对象，包括：

         1. 配置信息`IOptionsMonitor<Configs>`

         2. 链接生成器`LinkGenerator`

         3. 全局变量`GlobalData`

         4. 所有程序集`List<Assembly>`，拿到程序集很多东西通过反射可以拿到更多的东西

            1. 通过程序集获取所有的的类，判断类是否实现`IBaseController`接口并且不是抽象类，从而获取所有的控制器。

            2. 通过现有的的控制器对特性进行筛分

            3. 然后筛选出用户可以访问的`urls`

            4. 获取现在的用户类

            5. 初始化菜单

            6. 初始化文件操作

               