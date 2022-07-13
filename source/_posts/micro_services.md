---
title: .net core中consul与ocelot使用
author: wuxinheng
description: 通过本文可简单对微服务中所用的技术进行探秘，了解微服务实际的一些技术情况。
date: 2022-07-15 20:48:00
tags:
- consul
- ocelot
- nginx
- 微服务
- dotnet
categories:
- 微服务
---

### consul

#### 启动

```sh
consul agent -dev -node=127.0.0.1
```

#### .Net Core 使用Consul

添加Nuget Consul 1.6.10.4

```c#
// 通过staup.configuration 调用
public static void UseConsul(this IConfiguration configuration)
{
	// 通过配置项获取ip、port、weight信息
    var ip = configuration["ip"];
    var port = configuration["port"];
    int weight = string.IsNullOrEmpty(configuration["weight"]) ? 1 : int.Parse(configuration["weight"]);
    
    // 声明consul客户端
    ConsulClient consulClient = new ConsulClient(x =>
 	{
        // 指定consul服务地址
        x.Address = new System.Uri("http://localhost:8500");
        x.Datacenter = "dcl";
     });
    
    // 服务注册
     consulClient.Agent.ServiceRegister(new AgentServiceRegistration()
                                        {
                                            // 实例id
                                            ID = "Service " + Guid.NewGuid().ToString(),
                                            // 实例地址
                                            Address = ip,
                                            // 实例端口
                                            Port = int.Parse(port),
                                            // 实例名称
                                            Name = "Services",
                                            // 标签
                                            Tags = new string[] { weight.ToString() },
                                            // 健康检查
                                            Check = new AgentServiceCheck()
                                            {
                                                // 间隔
                                                Interval = TimeSpan.FromSeconds(12),
                                                // 检验地址
                                                HTTP = $"HTTP://{ip}:{port}/api/Home/health",
                                                // 检查服务名
                                                Name = "ConsulService",
                                                // 超时时间
                                                Timeout = TimeSpan.FromSeconds(5),
                                                // 注销服务
                                                DeregisterCriticalServiceAfter = TimeSpan.FromSeconds(12),
                                            }
            						});
}
```

##### 启动程序

通过cmd进入bin目录输入

```bash
dotnet [项目名].dll urls="http:127.0.0.1:8080" ip="127.0.0.1" port="8080" weight="1"
```



### ocelot

Ocelot

Ocelot.Cache.CacheManager

Ocelot.Provider.Consul

Ocelot.Provider.Polly

Startup.cs

```c#
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Ocelot.Cache;
using Ocelot.Cache.CacheManager;
using Ocelot.DependencyInjection;
using Ocelot.Middleware;
using Ocelot.Provider.Consul;
using Ocelot.Provider.Polly;


namespace Demo_Geteway
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            // 添加Ocelot中间件
            services.AddOcelot()
                // 使用Consul
                .AddConsul()
                // 使用缓存管理
                .AddCacheManager(m =>
                {
                    m.WithDictionaryHandle();//默认字典存储
        		})
                // 使用故障处理机制
                .AddPolly();
            //这里的IOcelotCache<CachedResponse>是默认缓存的约束--准备替换成自定义的
            services.AddSingleton<IOcelotCache<CachedResponse>, CustomeCache>();
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }
            app.UseOcelot().Wait();
        }
    }
}
```

Program

```c#
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace Demo_Geteway
{
    public class Program
    {
        public static void Main(string[] args)
        {
            // 接收命令行参数
            new ConfigurationBuilder()
                .AddCommandLine(args);
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                }).ConfigureAppConfiguration(configure =>
                {
                    // 使用指定json文件
                    configure.AddJsonFile("ocelot.json", false, true);
                });
    }
}
```

#### 单地址多服务

```json
{
    "Routes": [
        {
            "// DownstreamPathTemplate": "下游地址。{url}上有地址变量。万能模板写法:/{url}",
            "DownstreamPathTemplate": "/api/{url}",
            "// DownstreamScheme": "协议",
            "DownstreamScheme": "http",
            "// DownstreamHostAndPorts": "下游访问的主机和端口，可以为单个，设置多个时需要设置LoadBalancerOptions",
            "DownstreamHostAndPorts": [
                {
                    "Host": "127.0.0.1",
                    "Port": 6003
                },
                {
                    "Host": "127.0.0.1",
                    "Port": 6004
                },
                {
                    "Host": "127.0.0.1",
                    "Port": 6002
                }
            ],
            "// UpstreamPathTemplate": "上游地址路径,{url}会传递给下游地址。万能模板写法:/{url}",
            "UpstreamPathTemplate": "/to/{url}",
            "// UpstreamHttpMethod": "上游请求类型",
            "UpstreamHttpMethod": [
                "Get",
                "Post"
            ],
            "// LoadBalancerOptions": "负载均衡策略",
            "LoadBalancerOptions": {
                "// Type": {
                    "// RoundRobin": "轮询",
                    "// LeastConnection": "最少连接数，跟踪发现现在有最少请求或处理的可用服务",
                    "// NoLoadBalancer": "不使用负载均衡，直接访问config配置或者服务发现的第一个可用服务",
                    "// CookieStickySession":"会话粘滞"
                },
                "Type": "RoundRobin",
            }
        }
    ],
    "// GlobalConfiguration": "全局配置",
    "GlobalConfiguration": {
        "// BaseUrl": "根地址",
        "BaseUrl": "https://127.0.0.1:6005"
    }
}
```

#### consul服务治理

```json
{
    "Routes": [
        {
            "DownstreamPathTemplate": "/api/{url}",
            "DownstreamScheme": "http",
            "UpstreamPathTemplate": "/to/{url}",
            "UpstreamHttpMethod": ["Get","Post"],
            "// UseServiceDiscovery":"使用服务发现",
            "UseServiceDiscovery": true,
            "// ServiceName":"Consul服务名称",
            "ServiceName": "Services",
            "LoadBalancerOptions": {
                "Type": "RoundRobin"
            },
            "// FileCacheOptions":"使用缓存",
            "FileCacheOptions": {
                "// TtlSeconds":"过期时间",
                "TtlSeconds": 15,
                "// Region","可以调用Api清理",
                "Region": "UserCache"
            },
            "// RateLimitOptions":"限流",
            "RateLimitOptions": {
                "// ClientWhitelist":"白名单 ClientId区分大小写",
                "ClientWhitelist": [
                    "Microservice",
                    "Attempt"
                ],
                "EnableRateLimiting": true,
                "// Period":"5m 1h 1d",
                "Period": "1s", 
                "// PeriodTimespan":"多少秒之后客户端可以重试",
                "PeriodTimespan": 5,
                "// Limit": "统计时间段内允许的最大请求数",
                "Limit": 5
            },
            "// QoSOptions":"熔断",
            "QoSOptions": {
                "// ExceptionsAllowedBeforeBreaking":"熔断之前允许多少个异常请求",
                "ExceptionsAllowedBeforeBreaking": 3,
                "// DurationOfBreak":"熔断的时间,单位为ms.超过这个时间可再请求",
                "DurationOfBreak": 10000,
                "// TimeoutValue":"如果下游请求的处理时间超过多少则将请求设置为超时  默认90秒",
                "TimeoutValue": 4000
            }
        }
    ],
    "GlobalConfiguration": {
        "BaseUrl": "http://127.0.0.1:6005",
        "// ServiceDiscoveryProvider":"服务发现配置",
        "ServiceDiscoveryProvider": {
            "Host": "localhost",
            "Port": 8500,
            "// Type":"由Consul提供服务发现,每次请求去Consul,PollConsul每次获取最新的Consul",
            "Type": "PollConsul",
            "// PollingInterval":"请求最新的consul时间",
            "PollingInterval": 100
        },
        "// RateLimitOptions":"限流配置",
        "RateLimitOptions": {
            "// QuotaExceededMessage":"限流时返回的消息",
            "QuotaExceededMessage": "Customize Tips!",
            "// HttpStatusCode":"限流时返回的code",
            "HttpStatusCode": 999
        }
    }
}
```

### nginx

#### .Net Core Api

```dockerfile
worker_processes  1;
events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    # 服务名
    upstream Microservice {
        server 127.0.0.1:8001;
        server 127.0.0.1:8002;
        server 127.0.0.1:8003;
    }

    server {
        # 监听端口
        listen       8080;
        server_name  localhost;
        # 使用
        location / {
            proxy_pass http://Microservice;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```



#### WCF

```dockerfile
# 负载均衡是在内网下完成的，在外网请求的是代理服务器地址监听的是9000端口，再由代理服务器向后端服务器发送请求
# 均衡负载，测试工具：apache-jmeter-5.2.1 

# 代理名称，下面是两台轮询地址如果与一台服务器宕机另外一台还可以提供服务
upstream GQWcf  {
         # 如果用户已经访问了某台服务器，当用户再次访问时将该请求通过哈希算法自动定位到该台服务器，这样访客固定访问一台后端服务器可以解决session问题避免会话丢失。url  hash
         ip_hash;
         
         # 代理地址，在服务器上确保端口开放   weight:权重与访问率成正比，权重越大访问率越大
         server 192.168.1.180:8000  weight=10;
         
         # 代理地址也就是wcf的地址
         server 192.168.1.252:8000 weight=70; 
         
         # (第三方插件)：根据服务器响应时间进行分配，响应快的优先分配
         fair；  
      } 
      
# 服务
server {
        #监听默认服务器9000端口
        listen       9000  default_server;       

        #默认本机
        server_name  127.0.0.1;                  
 
        location / {
                   # $request_uri有没有不影响，GQWcf：代理名称
                   proxy_pass  http://GQWcf$request_uri;
                   proxy_redirect off;
                   # $server_port非常重要不然会出代理成功后无法再转向真实ip的下一级
                   proxy_set_header Host $host:$server_port;  
        }
        
        # 发生错误显示预定义的URL,"/50x.html"指下面的地址
        error_page   500 502 503 504  /50x.html; 

		# 发生错误返回的地址
        location = /50x.html {
            root   html;                                      
        }
  }
```

 
