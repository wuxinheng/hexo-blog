---
title: k8s部署,简单了解
author: wuxinheng
description: k8s部署,可能并不太好
date: 2022-09-05 22:13:37
tags:
- deploy
categories:
- k8s
---
# Kubeadm

Kubeadm 是一个提供了 `kubeadm init` 和 `kubeadm join` 的工具， 作为创建 Kubernetes 集群的 “快捷途径” 的最佳实践。

kubeadm 通过执行必要的操作来启动和运行最小可用集群。 按照设计，它只关注启动引导，而非配置机器。同样的， 安装各种 “锦上添花” 的扩展，例如 Kubernetes Dashboard、 监控方案、以及特定云平台的扩展，都不在讨论范围内。

### 废弃

> 可以忽略

相反，我们希望在 kubeadm 之上构建更高级别以及更加合规的工具， 理想情况下，使用 kubeadm 作为所有部署工作的基准将会更加易于创建一致性集群。

```shell
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

# 将 SELinux 设置为 permissive 模式（相当于将其禁用）
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl start  kubelet
sudo systemctl enable --now kubelet
```

[安装 kubeadm | Kubernetes](https://kubernetes.io/zh-cn/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

[【kubernetes入门学习】使用kubeadm搭建k8s集群 - 静水楼台/Java部落阁 - 博客园 (cnblogs.com)](https://www.cnblogs.com/rouqinglangzi/p/11760469.html#_lab2_1_2)

中间出现：Connection timed out after 30001 milliseconds

替换成阿里云地址

```shell
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```

[CentOS7 yum 安装 k8s 报错 - 豌里个豆 - 博客园 (cnblogs.com)](https://www.cnblogs.com/wandoupeas/p/15682838.html)

kubelet kubeadm kubectl需要版本一致

```shell
kubeadm version
kubectl version --client
kubelet --version
```

[安装指定版本的kubeadm - 简书 (jianshu.com)](https://www.jianshu.com/p/75091ad364c1)

master初始化

```shell
kubeadm init \
--apiserver-advertise-address=192.168.126.128 \
--kubernetes-version=1.25.0 \
--image-repository registry.aliyuncs.com/google_containers \
--service-cidr=10.96.0.0/16 \
--pod-network-cidr=10.244.0.0/16
```

参数解释：

- --kubernetes-version：指定kubernetes的版本，与上面kubelet，kubeadm，kubectl工具版本保持一致。
- --apiserver-advertise-address：apiserver所在的节点(master)的ip。
- --image-repository=registry.aliyuncs.com/google_containers：由于国外地址无法访问，所以使用阿里云仓库地址
- --server-cidr：service之间访问使用的网络ip段
- --pod-network-cidr：pod之间网络访问使用的网络ip,与下文部署的CNI网络组件yml中保持一致

[ Kubeadm初始化报错：ERROR CRI container runtime is not running:_困的一批的博客-CSDN博客](https://blog.csdn.net/qq_43580215/article/details/125153959)

查看日志

```
journalctl -u kubelet
```

[kubeadmin 初始化或者节点加入k8s集群时报错_周易不易的博客-CSDN博客](https://blog.csdn.net/m0_61237221/article/details/125223937)

经过几次尝试一直卡在拉取必要镜像哪里。

我在技术群里，群友发了个地址，我重新部署上了，中间也遇到问题，不过都是百度可以解决的。

[Kubernetes部署（Docker为运行时） - Layzer - 博客园 (cnblogs.com)](https://www.cnblogs.com/layzer/articles/kubernetes_docker.html)

### 教程

> 直接看这里

#### 环境

```shell
三台主机
IP:  10.0.0.10     主机名：master    系统： centos 7.9      配置： 4C 2G
IP:  10.0.0.11     主机名：node1     系统： centos 7.9      配置： 2C 2G
IP:  10.0.0.12     主机名：node2     系统： centos 7.9      配置： 2C 2G
```

#### 基础配置

```shell
1、所以节点关闭防火墙
systemctl stop firewalld
systemctl disable firewalld

2、所以节点关闭selinux
sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
setenforce 0

3、所以节点关闭swap
swapoff -a  # 临时关闭
vi /etc/fstab 注释到swap那一行 # 永久关闭
sed -i 's/.*swap.*/#&/g' /etc/fstab

4、所有节点添加主机名与IP对应关系
cat >> /etc/hosts << EOF
10.0.0.10 k8s-master
10.0.0.11 k8s-node1
10.0.0.12 k8s-node2
EOF
# 配置Hostname
hostnamectl set-hostname k8s-master
hostnamectl set-hostname k8s-node1
hostnamectl set-hostname k8s-node2

5、将桥接的IPv4流量传递到iptables的链（所有机器执行）、
cat > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

6、所有节点安装docker
# 配置Docker源和kubernetes源
yum install -y yum-utils
yum-config-manager \
    --add-repo \
    http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# 配置阿里云加速kubernetes源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum -y install docker-ce
# 启动docker
systemctl start docker
systemctl enable docker
# 配置加速
# 配置加速，并设置驱动
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://6ze43vnb.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# 加载daemon并重启docker
systemctl daemon-reload
systemctl restart docker
```

#### 安装Kubeadm以及初始化Kubernetes集群

```shell
1：所有节点安装kubeadm，kubelet和kubectl
yum install -y kubelet-1.23.1 kubeadm-1.23.1 kubectl-1.23.1
systemctl enable kubelet --now

2：初始化master节点
- 只在master节点执行
- 由于默认拉取镜像地址k8s.gcr.io国内无法访问，这里指定阿里云镜像仓库地址
- 执行成功以后最后结果会输出
kubeadm init \
  --apiserver-advertise-address=10.0.0.10 \
  --image-repository registry.aliyuncs.com/google_containers \
  --kubernetes-version v1.23.1 \
  --pod-network-cidr=100.1.0.0/16 \
  --service-cidr=172.1.0.0/16
  
3：kubeadm join 10.0.0.10:6443 --token bs9ygy.iudr36522p081nny \
	--discovery-token-ca-cert-hash sha256:4de71c2d7ae5b6f985992dee0fd31dc550244604e8aa618850a494b65dc14902
	
4：设置kubectl默认访问的api
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc

5：部署calico网络插件 #可能有问题，我没试，群友给了一个新的方式
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml

#新
wget https://docs.projectcalico.org/v3.14/manifests/calico.yaml --no-check-certificate
```

#### 查看集群

```shell
# 查看node以及网络插件方面
[root@k8s-master ~]# kubectl get pod -A
NAMESPACE     NAME                                       READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-85b5b5888d-g6d5g   1/1     Running   0          5m52s
kube-system   calico-node-67lp5                          1/1     Running   0          12m
kube-system   calico-node-f5mgs                          1/1     Running   0          14m
kube-system   calico-node-f69mb                          1/1     Running   0          12m
kube-system   coredns-6d8c4cb4d-rpxhq                    1/1     Running   0          21m
kube-system   coredns-6d8c4cb4d-vc7g6                    1/1     Running   0          21m
kube-system   etcd-k8s-master                            1/1     Running   0          21m
kube-system   kube-apiserver-k8s-master                  1/1     Running   0          21m
kube-system   kube-controller-manager-k8s-master         1/1     Running   0          21m
kube-system   kube-proxy-cwgpd                           1/1     Running   0          21m
kube-system   kube-proxy-rn5w9                           1/1     Running   0          17m
kube-system   kube-proxy-xb4kj                           1/1     Running   0          18m
kube-system   kube-scheduler-k8s-master                  1/1     Running   0          21m
```

#### kubectl命令例子

##### 查看类命令

```shell
# 获取节点和服务版本信息
kubectl get nodes

# 获取节点和服务版本信息，并查看附加信息
kubectl get nodes -o wide # 获取pod信息，默认是default名称空间
kubectl get pod

# 获取pod信息，默认是default名称空间，并查看附加信息【如：pod的IP及在哪个节点运行】
kubectl get pod -o wide

# 获取指定名称空间的pod
kubectl get pod -n kube-system

# 获取指定名称空间中的指定pod
kubectl get pod -n kube-system podName

# 获取所有名称空间的pod
kubectl get pod -A

# 查看pod的详细信息，以yaml格式或json格式显示
kubectl get pods -o yaml
kubectl get pods -o json # 查看pod的标签信息
kubectl get pod -A --show-labels

# 根据Selector（label query）来查询pod
kubectl get pod -A --selector="k8s-app=kube-dns" # 查看运行pod的环境变量
kubectl exec podName env

# 查看指定pod的日志
kubectl logs -f --tail 500 -n kube-system kube-apiserver-k8s-master # 查看所有名称空间的service信息
kubectl get svc -A

# 查看指定名称空间的service信息
kubectl get svc -n kube-system # 查看componentstatuses信息
kubectl get cs

# 查看所有configmaps信息
kubectl get cm -A

# 查看所有serviceaccounts信息
kubectl get sa -A

# 查看所有daemonsets信息
kubectl get ds -A

# 查看所有deployments信息
kubectl get deploy -A

# 查看所有replicasets信息
kubectl get rs -A

# 查看所有statefulsets信息
kubectl get sts -A

# 查看所有jobs信息
kubectl get jobs -A

# 查看所有ingresses信息
kubectl get ing -A

# 查看有哪些名称空间
kubectl get ns # 查看pod的描述信息
kubectl describe pod podName
kubectl describe pod -n kube-system kube-apiserver-k8s-master

# 查看指定名称空间中指定deploy的描述信息
kubectl describe deploy -n kube-system coredns # 查看node或pod的资源使用情况
# 需要heapster 或metrics-server支持
kubectl top node
kubectl top pod # 查看集群信息
kubectl cluster-info   或  kubectl cluster-info dump

# 查看各组件信息【172.16.1.110为master机器】
kubectl -s https://172.16.1.110:6443 get componentstatuses
```

##### 操作类命令

```shell
# 创建资源
kubectl create -f xxx.yaml # 应用资源
kubectl apply -f xxx.yaml # 应用资源，该目录下的所有 .yaml, .yml, 或 .json 文件都会被使用
kubectl apply -f <directory> # 创建test名称空间
kubectl create namespace test # 删除资源
kubectl delete -f xxx.yaml
kubectl delete -f <directory> # 删除指定的pod
kubectl delete pod podName # 删除指定名称空间的指定pod
kubectl delete pod -n test podName # 删除其他资源
kubectl delete svc svcName
kubectl delete deploy deployName
kubectl delete ns nsName # 强制删除
kubectl delete pod podName -n nsName --grace-period=0 --force
kubectl delete pod podName -n nsName --grace-period=1
kubectl delete pod podName -n nsName --now # 编辑资源
kubectl edit pod podName
```

##### 进阶命令操作

```shell
# kubectl exec：进入pod启动的容器
kubectl exec -it podName -n nsName /bin/sh    #进入容器
kubectl exec -it podName -n nsName /bin/bash  #进入容器 # kubectl label：添加label值
kubectl label nodes k8s-node01 zone=north  #为指定节点添加标签
kubectl label nodes k8s-node01 zone-       #为指定节点删除标签
kubectl label pod podName -n nsName role-name=test    #为指定pod添加标签
kubectl label pod podName -n nsName role-name=dev --overwrite  #修改lable标签值
kubectl label pod podName -n nsName role-name-        #删除lable标签 # kubectl滚动升级； 通过 kubectl apply -f myapp-deployment-v1.yaml 启动deploy
kubectl apply -f myapp-deployment-v2.yaml     #通过配置文件滚动升级
kubectl set image deploy/myapp-deployment myapp="registry.cn-beijing.aliyuncs.com/google_registry/myapp:v3"   #通过命令滚动升级
kubectl rollout undo deploy/myapp-deployment 或者 kubectl rollout undo deploy myapp-deployment    #pod回滚到前一个版本
kubectl rollout undo deploy/myapp-deployment --to-revision=2  #回滚到指定历史版本 # kubectl scale：动态伸缩
kubectl scale deploy myapp-deployment --replicas=5  # 动态伸缩
kubectl scale --replicas=8 -f myapp-deployment-v2.yaml  #动态伸缩【根据资源类型和名称伸缩，其他配置「如：镜像版本不同」不生效】
```

### 可视化面板

[手动快速部署 | Rancher文档](https://docs.rancher.cn/docs/rancher2.5/quick-start-guide/deployment/quickstart-manual-setup/_index)

```shell
docker run -d --privileged --restart=unless-stopped \
  -p 80:80 -p 443:443 \
  rancher/rancher:latest
```

