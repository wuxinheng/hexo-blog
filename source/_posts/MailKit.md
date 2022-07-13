---
title: MailKit
author: wuxinheng
date: 2022-08-24 22:21:27
description: abp使用
categories:
  - abp
tags:
- dotnet
---
## MailKit

1、在`Domain`模块使用设置系统来进行配置：继承`SettingDefinitionProvider`重写`Define`方法更具文档上添加需要的信息。

```
public class xblogsSettingDefinitionProvider : SettingDefinitionProvider
{
    public override void Define(ISettingDefinitionContext context)
    {
        // Eail Setting Infomation
        context.Add(new SettingDefinition(EmailSettingNames.Smtp.Host, "smtp.qq.com"),
                new SettingDefinition(EmailSettingNames.Smtp.Port, "465"),
                new SettingDefinition(EmailSettingNames.Smtp.UserName, "934041144@qq.com"),
                new SettingDefinition(EmailSettingNames.Smtp.Password, "12345"),
                new SettingDefinition(EmailSettingNames.Smtp.Domain),
                new SettingDefinition(EmailSettingNames.Smtp.EnableSsl, "true"),
                new SettingDefinition(EmailSettingNames.Smtp.UseDefaultCredentials, "false"),
                new SettingDefinition(EmailSettingNames.DefaultFromAddress, "934041144@qq.com"),
                new SettingDefinition(EmailSettingNames.DefaultFromDisplayName, "xblogs"));

    }
}
```

2、在`Domain`模块新建模块。

```
    /// <summary>
    /// MailKit模块
    /// </summary>
    [DependsOn(
    typeof(AbpMailKitModule)
    )]
    public class MailKitModule : AbpModule
    {
        public override void ConfigureServices(ServiceConfigurationContext context)
        {

            Configure<AbpMailKitOptions>(options =>
            {
                options.SecureSocketOption = SecureSocketOptions.SslOnConnect;
            });

        }

    }
```

3、在`DomainModule`注册我们的`MailKitModule`

```
[DependsOn(
    typeof(MailKitModule)
)]
public class xblogsDomainModule : AbpModule
{
    public override void ConfigureServices(ServiceConfigurationContext context)
    {
        Configure<AbpMultiTenancyOptions>(options =>
        {
            options.IsEnabled = MultiTenancyConsts.IsEnabled;
        });
    }
}
```

> 这里有个概念非常好模块化。我在这里纠结了很长时间abp理念是模块化，减少冗余。可以简单理解为拼积木。请看`模块化`
>
> 我当然非常愿意学习一个东西时先看文档。但是文档这个东西很难说每个人的理解能力也不一样。我没有看懂abp这一块的文档。我就直接上手操作。不对就换方法。当自己的摸索出来了之后就可以跟着自己的理解去看文档和写代码了。