---
title: nginx使用
author: wuxinheng
description: 本文说明了nginx的使用和如何部署，怎么进行负载均衡、ssl设置。
date: 2022-07-11 20:32:35
tags:
- nginx代理
- nginx负载均衡
- nginx配置ssl
- nginx
categories:
- docker
---

# Nginx 介绍

> 很多时候是可以选择nginx可视化管理工具的。但是我没有选择使用。原因是我觉得理解和学会配置nginx更重要。

详细文档 [恩金克斯 (nginx.org)](https://nginx.org/en/)

nginx 热门的轻量级服务器。轻量级服务器、支持负载均衡，对静态文件友好。

nginx 中重要的三部分：

静态文件：需要部署静态文件

配置文件：配置nginx的配置文件

日志：nginx的日志文件

# 使用

## docker

### 安装

```shell
# 拉取nginx镜像
docker pull nginx
```

```shell
# docker运行nginx
docker run --name nginx -d -p 80:80 nginx:latest
```

```shell
# 进入nginx容器
docker exec -it nginx /bin/bash	
```



### 路径

docker 容器内 nginx 相关文件路径

配置文件：`/etc/nginx/nginx.conf`

静态文件：`/usr/share/nginx/html`

日志文件：`/var/log/nginx`



### 持久化

```shell
mkdir -p /var/nginx/html
mkdir -p /var/nginx/log
mkdir -p /var/nginx/conf
chmod 777 /var/nginx
```

```shell
docker cp nginx:/usr/share/nginx/html/. /var/nginx/html
docker cp nginx:/var/log/nginx/. /var/nginx/log
docker cp nginx:/etc/nginx/. /var/nginx/conf
```

> 启动容器时请使用--net=host参数, 直接映射本机端口, 因为内部nginx可能使用任意一个端口, 所以必须映射本机所有端口.——[nginxWebUI](https://gitee.com/cym1102/nginxWebUI.git)

```shell
# 原来呢我端口这里是 -p 80:80 -p 443:443,如果需要监听其他端口就需要添加如：-p 1234:1200。不符合实际需求应该映射本机端口：--net=host
docker run --name nginx  -d --net=host  -v /var/nginx/html:/usr/share/nginx/html -v /var/nginx/log:/var/log/nginx/ -v /var/nginx/conf:/etc/nginx nginx:latest
```

### ssl

ssl 证书放在/etc/nginx/conf.d/ssl文件夹下

```ini
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    #gzip  on;
    
	# 上游代理
	upstream xblogs {					
		server 10.0.4.16:3000; # 可以在此处添加多个server来进行负载均衡。和其他配置
	}
	
	server {
        # 监听端口
        listen       80;
        server_name  localhost;
        
        # 使用
        location / {
            proxy_pass http://xblogs;
        }
        
        error_page   500 502 503 504  /50x.html;
        
        location = /50x.html {
            root   html;
        }
        
    }
	
	server {
        # 监听端口
        listen       443 ssl;
        server_name  xblogs.net www.xblogs.net;
        ssl_certificate /etc/nginx/conf.d/ssl/server.crt;
        ssl_certificate_key /etc/nginx/conf.d/ssl/server.key; 
        ssl_session_cache shared:ssl:10m;
        ssl_session_timeout 10m; 
        #ssl_ciphers high:!anull:!md5;
        #ssl_prefer_server_ciphers on;、
        
        # 使用
        location / {
            proxy_pass http://xblogs;
        }
        
        error_page   500 502 503 504  /50x.html;
        
        location = /50x.html {
            root   html;
        }
        
    }
    # http重写为https
    server {
        # 监听端口
		listen       12345;
        server_name  xblogs.net www.xblogs.net;
        rewrite ^(.*)$ https://${server_name}$1 permanent;
    }
    
    # include /etc/nginx/conf.d/*.conf; 	#原本模块化代码注释了
    
}
```



### 踩坑

nginx 在docker中的部署之后中间出现的疑惑和问题

- 容器内部与windows nginx文件夹不一样。

  起初我对这个很疑惑。后来反应这个docker容器的特性。

- nginx的配置文件有两个

  /etc/nginx/nginx.conf 和/etc/nginx/conf.d/default.conf两个配置文件。由于我是在19年第一次接触nginx接触次数不多。中间版本迭代。nginx把文件拆分了。这里以编程的角度就是模块化思想。nginx把具体的server拆分到default.conf这里可以选择新写一个文件也可以在nginx.conf上配置。

## windows

### 启动

下载nginx之后在在文件夹中执行：nginx.exe 或者 start nginx,这个过程中可能出现端口被占用的错误。那就需要修改nginx.conf 监听的80端口。或者暂停现有占用80端口的进程或站点。

### 负载均衡

19年使用wcf+nginx初探。

```ini
#我是使用时是成功代理的，以下代码仅供参考
#负载均衡是在内网下完成的，在外网请求的是代理服务器地址监听的是9000端口，再由代理服务器向后端服务器发送请求
#均衡负载，测试工具：apache-jmeter-5.2.1 

upstream GQWcf  {                                #代理名称，下面是两台轮询地址如果与一台服务器宕机另外一台还可以提供服务

         #ip_hash;                               #如果用户已经访问了某台服务器，当用户再次访问时将该请求通过哈希算法自动定位到该台服务器
                                                 #这样访客固定访问一台后端服务器可以解决session问题避免会话丢失但是可能会造成分配不均。
                                                 #url  hash跟ip_hash类似根据url的hash值进行分配，将URL分配到同一个否端服务器，
                                                 #当服务器存在缓存时比较有效
         server 192.168.1.180:8000  weight=10;   #代理地址，在服务器上确保端口开放   weight:权重与访问率成正比，权重越大访问率越大
         server 192.168.1.252:8000  weight=70;   #代理地址也就是wcf的地址  
         #fair；                                 #(第三方插件)：根据服务器响应时间进行分配，响应快的优先分配

} 
server {
 
        listen       9000  default_server;       #监听默认服务器9000端口
        server_name  127.0.0.1;                  #默认本机
 
        location / {
                   proxy_pass  http://GQWcf$request_uri;      #$request_uri有没有不影响，GQWcf：代理名称
                   proxy_redirect off;
                   proxy_set_header Host $host:$server_port;  #:$server_port非常重要不然会出代理成功后无法再转向真实ip的下一级
        }

        error_page   500 502 503 504  /50x.html;              #发生错误显示预定义的URL,"/50x.html"指下面的地址

        location = /50x.html {
            root   html;                                      #发生错误返回的地址
        }
 
  }
```

