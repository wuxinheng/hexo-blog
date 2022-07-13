# 使用Node.js作为基础镜像
FROM node:latest

# 设置工作目录
WORKDIR /app

# 将 package.json 和 package-lock.json 拷贝到工作目录
COPY package*.json ./

# 安装项目依赖
RUN npm install
# 安装 hexo
RUN npm install hexo-cli -g

# 拷贝整个项目到工作目录
COPY . .

# 运行 hexo generate 命令生成静态网站
RUN hexo generate

# 指定容器启动时要执行的命令
CMD ["hexo", "server"]