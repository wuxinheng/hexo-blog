---
title: ssh无法链接
author: wuxinheng
date: 2022-08-24 22:19:09
description: ssh无法链接
categories:
  - linux
tags:
- ssh
---
## ssh无法链接

描述：`xftp` 无法与"`目标IP`"连接

原因：`OpenSSH`升级导致

解决办法：

1. 查看服务地址

   ```shell
   # 输入
   find / -name sftp-server
   # 结果
   /usr/local/openssh/libexec/sftp-server #像
   /home/EGS-B1101.17.1.211222/openssh8.8p1/openssh-8.8p1/sftp-server #不像
   ```

2. 设置正确的地址

   ```shell
   vim /etc/ssh/sshd_config
   ```

   查看`Subsystem`的值，比对第一步服务地址。

   修改正确的路径。

3. 重启

   ```shell
   systemctl restart sshd
   ```
