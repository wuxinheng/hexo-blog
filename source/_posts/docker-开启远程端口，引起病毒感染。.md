---
title: docker 开启远程端口，引起病毒感染。
author: wuxinheng
date: 2022-08-11 23:10:16
description: docker 开启远程端口，引起病毒感染。事件全过程
categories:
  - docker
tags:
- docker
- 病毒
---
## docker 开启远程端口，引起病毒感染

8月7号下午：学了java springboot实现的了一个简单的接口。看了idea有docker相关的功能，就产生了部署springboot到docker想法。

8月7号晚上：springboot打包镜像一直报错。经过几番百度加尝试还是不行。

8月8号中午：找到了一个说是需要打开docker 远程端口的博客。之所以觉得这个博客说的比较对是因为。docker-maven-plugin配置并没有配置ssh，而是一个端口。之前使用docker也看过类似的帖子。因为常用工具是vs和docker desktop。没太在意。

8月8号下午：我修改了docker配置。开启了2375端口。其实在开启远程端口的时候我就在想应该需要配置https访问，当时想法想的是通过nginx。但是因为就是想部署一个java的项目上去玩玩，就忽略了。

8月8号晚上：腾讯云给我发来慰问：一个病毒程序正在扫描端口，突然又来一条：一个病毒程序正在删除文件。当时我在地铁上快到家了，下地铁的过程中。还收到了好几条。我当时心情感觉就不太好。虽然是自己的服务器，但是上面有我部署的服务，重新配置的话还挺麻烦的。到家之后。我尝试在linux上安装杀毒软件ClamAV经过几番周折还是不太好装。我就找了个安装脚本进行杀毒。

8月9号下午：本来以为好了问题应该不大。突然又收到腾讯云发来的问候。我又跑到服务器进行病毒查杀。结果是什么都没有发现。

8月11号下午：博客的公安网备通过了。正在打算通过jenkins发布呢。结果jenkins访问不到了。docker ps开始执行卡了一下。我还以为我的网络问题。结果看见的是满屏的容器。这不用猜了jenkins肯定是内存不够被kill了。我就在想这些容器是哪来的。我起初怀疑破解版idea的问题。后面我又以为是shell工具。哪里存在信息泄露？但是感觉中国人不骗中国人。我突然想到服务是近期才不稳定的。近期服务器只做了开放docker远程端口。我开始删除我的这些没用的容器。重新部署服务还好jenkins做了文件挂载。然后我开始处理2375端口不安全问题。最开始我在网上找到了一篇解决安全问题的博客。内容是自己创建ca证书。我并没有立即采用这种办法。应为觉得麻烦。后面我尝试用nginx使用ssl端口代理2375把2375外网访问关闭掉。只允许从127.0.0.1或者localhost的方式进行访问。几经测试能力尚浅没有实现。时间问题，我选择了尝试那个篇博客的上的方法。成功的把http://ip:2375改成了https。下面我在解决问题过程的关键的博客。最后一篇的病毒和我的是一模一样。

### 自建证书

创建存放证书文件夹

```shell
mkdir /var/lib/docker-ca && cd /var/lib/docker-ca
```

证书这一块的知识参见第二个文档。

创建CA证书私钥，期间需要输入两次用户名和密码，生成文件为ca-key.pem；

```shell
openssl genrsa -aes256 -out ca-key.pem 4096
```

根据私钥创建CA证书，期间需要输入上一步设置的私钥密码，生成文件为ca.pem；

```shell
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -subj "/CN=*" -out ca.pem
```

创建服务端私钥，生成文件为server-key.pem；

```shell
openssl genrsa -out server-key.pem 4096
```

创建服务端证书签名请求文件，用于CA证书给服务端证书签名，生成文件server.csr；

```shell
openssl req -subj "/CN=*" -sha256 -new -key server-key.pem -out server.csr
```

创建CA证书签名好的服务端证书，期间需要输入CA证书私钥密码，生成文件为server-cert.pem；

```shell
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
```

创建客户端私钥，生成文件为key.pem；

```shell
openssl genrsa -out key.pem 4096
```

创建客户端证书签名请求文件，用于CA证书给客户证书签名，生成文件client.csr；

```shell
openssl req -subj "/CN=client" -new -key key.pem -out client.csr
```

为了让秘钥适合客户端认证，创建一个扩展配置文件extfile-client.cnf；

```shell
# 这一块没太明白。执行好像没有效果。我执行了两次然后直接忽略了
echo extendedKeyUsage = clientAuth > extfile-client.cnf
```

创建CA证书签名好的客户端证书，期间需要输入CA证书私钥密码，生成文件为cert.pem；

```shell
openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out cert.pem -extfile extfile-client.cnf
```

删除创建过程中多余的文件；

```shell
rm -rf ca.srl server.csr client.csr extfile-client.cnf
```

生成得文件如下

```
ca.pem CA证书
ca-key.pem CA证书私钥
server-cert.pem 服务端证书
server-key.pem 服务端证书私钥
cert.pem 客户端证书
key.pem 客户端证书私钥
```

修改docker配置文件

```shell
vi /usr/lib/systemd/system/docker.service
```

这里的配置使用decker命令会报错：`-H unix://var/run/docker.sock`，那就在下面加入`-H unix://var/run/docker.sock`

```ini
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock --tlsverify --tlscacert=/mydata/docker-ca/ca.pem --tlscert=/mydata/docker-ca/server-cert.pem --tlskey=/mydata/docker-ca/server-key.pem 
```

重新加载docker和启动

```shell
systemctl daemon-reload && systemctl restart docker
```

将生成得证书文件放在java开发电脑我的地址：`C:\\docker-ca`

```tex
ca.pem CA证书
cert.pem 客户端证书
key.pem 客户端证书私钥
```

pom.xml docker-maven-plugin 配置

```xml
<plugin>
    <groupId>com.spotify</groupId>
    <artifactId>docker-maven-plugin</artifactId>
    <version>1.2.2</version>
    <executions>
        <execution>
            <id>build-image</id>
            <phase>package</phase>
            <goals>
                <goal>build</goal>
            </goals>
        </execution>
    </executions>
    <configuration>
        <imageName>mall-tiny/${project.artifactId}:${project.version}</imageName>
        <dockerHost>https://ip:2375</dockerHost>
        <baseImage>java:8</baseImage>
        <entryPoint>["java", "-jar","/${project.build.finalName}.jar"]
        </entryPoint>
        <dockerCertPath>C:\\docker-ca</dockerCertPath>
        <resources>
            <resource>
                <targetPath>/</targetPath>
                <directory>${project.build.directory}</directory>
                <include>${project.build.finalName}.jar</include>
            </resource>
        </resources>
    </configuration>
</plugin>
```

[如何保证docker2375端口的安全_LY破晓的博客-CSDN博客_docker2375安全设置](https://blog.csdn.net/qq_40321119/article/details/107951712)

[HTTPS安全证书访问连接知识讲解_weixin_34061482的博客-CSDN博客](https://blog.csdn.net/weixin_34061482/article/details/92717907)

[Cetus：针对 Docker daemons 的加密劫持蠕虫_黑客技术 (hackdig.com)](http://www.hackdig.com/08/hack-124456.htm)