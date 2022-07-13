---
title: modules
author: wuxinheng
date: 2022-08-24 22:21:11
description: abp使用
categories:
  - abp
tags:
- dotnet
---
## 模块化

概念：简单来说模块化就是将功能拆分，需要用的时候拿来用。

abp中的模块：我是这么理解我将框架基础功能的配置拆分在不同模块中，但这个也是根据不同的需求和场景来完成的。我们可以将功能模块化配置的尽可能的零散些。在Application 中我们可以新建模块，不同的模块注入不同的功能模块类。再将自己的新建的模块类注入到ApplicationModule中，这里需要的注意的是ApplicationModule中默认注入了DomainModule。所以在配置MailKit时只是注入了MailKitModule。我在实现邮件功能的时候也尝试将MailKitModule写在Application项目中。但是出现错误。我觉得可能是注入的问题，我就选择写在Domain项目中。这里其实还可以再去钻研的。ApplicationModule是整个程序的主入口。他就像个大水池不断有水流入。我就把ApplicationModule中的内容清空了，让这个类主要来负责程序的注入。