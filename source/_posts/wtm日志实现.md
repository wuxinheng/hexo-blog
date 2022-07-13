---
title: wtm日志实现
author: wuxinheng
date: 2022-07-22 23:08:00
description: 实现自己的系统日志
tags:
- 日志
- dotnet
- wtm
categories:
- dotnet
---
## wtm日志实现

##### 日志

命名空间：[Microsoft.Extensions.Logging](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.extensions.logging?view=dotnet-plat-ext-6.0&viewFallbackFrom=net-6.0)

> 他们的关系是先由ILoggingBuilder配置日志程序,ILoggerFactory 根据日志类型（categoryName）调用 对应的 ILoggerProvider 获取 ILogger

[ILogger](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.extensions.logging.ilogger?view=dotnet-plat-ext-6.0)

[ILoggerProvider](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.extensions.logging.iloggerprovider?view=dotnet-plat-ext-6.0)

[ILoggerFactory](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.extensions.logging.iloggerfactory?view=dotnet-plat-ext-6.0)

[ILoggingBuilder](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.extensions.logging.iloggingbuilder?view=dotnet-plat-ext-6.0)



##### 过滤器（过滤器管道）

> 过滤器也是一种特殊的管道

![](../images/管道示意图.png)

命名空间：[Microsoft.AspNetCore.Mvc.Filters](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.aspnetcore.mvc.filters?view=aspnetcore-6.0)

> OnAuthorization→OnResourceExecuting→创建控制器→OnActionExecuting→执行action业务→OnActionExecuted→OnResultExecuting→页面渲染加载→OnResultExecuted→OnResourceExecuted（不包括异常过滤器的情况下）

[IAuthorizationFilter](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.aspnetcore.mvc.filters.iauthorizationfilter?view=aspnetcore-6.0)

[IResourceFilter](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.aspnetcore.mvc.filters.iresourcefilter?view=aspnetcore-6.0)

[IActionFilter](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.aspnetcore.mvc.filters.iactionfilter?view=aspnetcore-6.0)

[IResultFilter](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.aspnetcore.mvc.filters.iresultfilter?view=aspnetcore-6.0)

[IExceptionFilter](https://docs.microsoft.com/zh-cn/dotnet/api/microsoft.aspnetcore.mvc.filters.iexceptionfilter?view=aspnetcore-6.0)

startup

```C#
public void ConfigureServices(IServiceCollection services)
{
    services.AddMvc(x =>
	{
    	x.Filters.Add<MyFilter>();
	});

    services.AddLogging(builder =>
    {
        builder.ClearProviders();//清除系统日志
        builder.AddMyLogger();//添加自己的日志
    });
}
```

过滤器记录

```C#
public class MyFilter : IActionFilter, IResultFilter
{
    public void OnActionExecuted(ActionExecutedContext context)
    {

    }

    public void OnActionExecuting(ActionExecutingContext context)
        {
            if (context.HttpContext.Items.ContainsKey("actionstarttime") == false)
            {
                context.HttpContext.Items.Add("actionstarttime", DateTime.Now);
            }

        }

    public void OnResultExecuted(ResultExecutedContext context)
    {

        var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<MyLog>>();
        var type = (context.ActionDescriptor as ControllerActionDescriptor).ControllerTypeInfo.AsType();
        //方法信息
        var method = (context.ActionDescriptor as ControllerActionDescriptor).MethodInfo;

        MyLog myLog = new MyLog()
        {
            Message = new StringBuilder()
                .Append(@$"{type?.FullName ?? ""}")
                .Append(@$"{method?.Name ?? ""}")
                .ToString(),
            CurrentDateTime = DateTime.Now,
            LogLevel = LogLevel.Debug,
        };
        var starttime = context.HttpContext.Items["actionstarttime"] as DateTime?;
        if (starttime != null)
        {
          var s = DateTime.Now.Subtract(starttime.Value).TotalSeconds;
        }
        if (logger != null)
        {
            logger.Log<MyLog>(LogLevel.Information, new EventId(), myLog, null, (a, b) =>
            {
                return a.ToString();
            });

        }
    }

    public void OnResultExecuting(ResultExecutingContext context)
    {

    }

```

日志实现

```c#
    public static class LoggerExtensions
    {
        public static ILoggingBuilder AddMyLogger(this ILoggingBuilder builder)
        {
            builder.AddConfiguration();
            builder.Services.TryAddEnumerable(ServiceDescriptor.Singleton<ILoggerProvider, MyLoggerProvider>());
            return builder;
        }
    }
    public class MyLogger : ILogger
    {

        private readonly string categoryName;
        private IServiceProvider sp;
        private LoggerFilterOptions logConfig;

        public MyLogger(string categoryName, LoggerFilterOptions logConfig, IServiceProvider sp)
        {
            this.categoryName = categoryName;
            this.logConfig = logConfig;
            this.sp = sp;
        }
        public IDisposable BeginScope<TState>(TState state) => null;

        public bool IsEnabled(LogLevel logLevel)
        {
            return false;
        }

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception exception, Func<TState, Exception, string> formatter)
        {
            MyLog log = null;
            // 如果泛型类型不是ActionLog
            if (typeof(TState) != typeof(MyLog))
            {

                log = new MyLog
                {
                    Message = formatter?.Invoke(state, exception),
                    CurrentDateTime = DateTime.Now,
                    LogLevel = logLevel
                };
            }
            else
            {
                // 隐式转换
                log = state as MyLog;
            }
        }
    }

    public class MyLoggerProvider : ILoggerProvider
    {
        private IServiceProvider sp = null;
        private LoggerFilterOptions logConfig;

        public MyLoggerProvider(IOptionsMonitor<LoggerFilterOptions> _logConfig, IServiceProvider sp)
        {
            this.sp = sp;
            logConfig = _logConfig.CurrentValue;
        }
        public ILogger CreateLogger(string categoryName)
        {
            return new MyLogger(categoryName, logConfig, sp);

        }

        public void Dispose() { }
    }
```

