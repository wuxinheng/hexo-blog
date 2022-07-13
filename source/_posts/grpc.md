---
title: grpc
author: wuxinheng
date: 2022-08-02 14:37:01
description: 我个人在使用上而言，grpc、webapi、webservice、wcf这几个的区别。grpc可能更倾向内网，采用http2更安全。唯一不方便的地方是.proto文件共享的问题。webapi，遵循http规范。get、post、delete、put,然而这些是webservice缺少的。wcf跟grpc很相似。多语言之间的共同性都是通过协议来实现相关类。
categories:
  - grpc
tags:
  - dotnet
---
grpc

> 我个人在使用上而言，grpc、webapi、webservice、wcf这几个的区别。
> grpc可能更倾向内网，采用http2更安全。唯一不方便的地方是.proto文件共享的问题
> webapi，遵循http规范。get、post、delete、put,然而这些是webservice缺少的。
> wcf跟grpc很相似。多语言之间的共同性都是通过协议来实现相关类。

1.新建 `ASP.NET Core gRPC 服务`

2.项目文件中默认有个`Protos`文件夹，文件夹中默认有一个`.proto`文件

3.`.proto`可以理解问接口文件或者定义文件。其他语言也是通过`.proto`文件来使用`grpc`

4.`.proto`在项目中默认会生成一个类里面是当前语言的定义。也是我们要使用的基类

5.如果需要自己重新实现代码。就需要自己重新这个方法。

服务端 .proto示例

```protobuf
syntax = "proto3"; //版本

import "google/protobuf/empty.proto";  // google.protobuf.Empty 定义文件

option csharp_namespace = "Demo_GrpcService";  // 命名空间

package tmessage; // 类

// 服务定义
service MessageService {
  // 方法定义
  rpc Add (MessageRequest) returns (MessageResult);
  rpc Update (MessageRequest) returns (MessageResult);
  rpc Delete (MessageRequest) returns (MessageResult);
  rpc Query(MessageRequest) returns (MessageResult);
  rpc Test (google.protobuf.Empty) returns (google.protobuf.Empty); // 无参，无返
}

// 请求体
message MessageRequest
{
		string Content =1;
}
// 返回体
message MessageResult
{
	string Msg =1;
	string Code =2;
}
```

客户端也是一样的，但是不同的地方是项目文件中的配置

```xml
  <ItemGroup>
    <!--.proto文件路径，当前grpc的声明Server、Client-->
    <Protobuf Include="Protos\message.proto" GrpcServices="Server" />  
    <Protobuf Include="Protos\greet.proto" GrpcServices="Server" />
  </ItemGroup>
```

控制台使用grpc服务

```C#
static void Main(string[] args)
        {
            AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true); // 允许https未加密的支持
            string url = "http://localhost:5054";

            //string url = "https://localhost:7054";

            using (var channel = GrpcChannel.ForAddress(url))
            {
                var client = new MessageService.MessageServiceClient(channel);
                var reply = client.Add(new MessageRequest()
                {
                    Content = "ceshi"
                });

                Console.WriteLine($"结果:{reply.Code},message:{reply.Msg}");
            }
            
            Console.ReadKey();
        }
```

webapi使用grpc

```C#
public void ConfigureServices(IServiceCollection services)
{

    services.AddControllers();
    services.AddSwaggerGen(c =>
    {
        c.SwaggerDoc("v1", new OpenApiInfo { Title = "WebApplication", Version = "v1" });
    });
    services.AddGrpcClient<MessageService.MessageServiceClient>(options =>
    {
        options.Address = new Uri("https://localhost:7054");
    });
}
```

控制器

```C#
[ApiController]
[Route("[controller]")]
public class WeatherForecastController : ControllerBase
{
    private static readonly string[] Summaries = new[]
    {
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
    };

    private readonly ILogger<WeatherForecastController> _logger;
    private readonly MessageService.MessageServiceClient _messageService;

    public WeatherForecastController(ILogger<WeatherForecastController> logger, 
                                     MessageService.MessageServiceClient messageService = null)
    {
        _logger = logger;
        _messageService = messageService;
    }

    [HttpGet]
    public IEnumerable<WeatherForecast> Get()
    {
      var s=   _messageService.Add(new MessageRequest() { Content="api调用grpc"});
        var rng = new Random();
        return Enumerable.Range(1, 5).Select(index => new WeatherForecast
        {
            Date = DateTime.Now.AddDays(index),
            TemperatureC = rng.Next(-20, 55),
            Summary = Summaries[rng.Next(Summaries.Length)]
        })
        .ToArray();
    }
}
```

文档：[.NET 中的 gRPC 客户端工厂集成 | Microsoft Docs](https://docs.microsoft.com/zh-cn/aspnet/core/grpc/clientfactory?view=aspnetcore-6.0)
