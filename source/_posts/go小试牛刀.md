---
title: go小试牛刀
author: wuxinheng
description: go小试牛刀
date: 2022-09-05 22:14:22
tags:
categories:
- go
---
#### 下载安装[GoLand](https://www.jetbrains.com.cn/go/)

goland 会自动安装golang，但是不会设置全局环境变量。需要手动设置，在goland中找到sdk地址。

#### 安装beego

```bash
# 设置网络环境
go env -w GOPROXY=https://goproxy.io,direct
go env -w GO111MODULE=on

# 安装bee
go get -u github.com/astaxie/beego
go get -u github.com/beego/bee

# 检查bee 
bee version

# bee如果失败，需要手动打包bee
# 查看环境变量
go env  
GOPATH=C:\Users\Administrator\go
# 找到bee地址
C:\Users\Administrator\go\src\github.com\beego\bee
# 三种任意一种都行，都试一下吧，不太确定是哪个。我记得是前两个，第三个是我网上看见的。不一定生成bee.exe,也有可能是main.exe,名字改一下bee.exe,配置一下环境变量就好了，
go build 
go build main.go
go install
```

#### 新建api

```bash
# 最开始我是这样的，发现不对
bee new bee-api
# 正确命令
bee api bee-api
# 需要修改swagger/index.html, 
#SwaggerUIBundle url值:https://petstore.swagger.io/v2/swagger.json》swagger.json,不然不会显示正确的文档
# 访问：http://localhost:8080/swagger
# 程序配置信息修改在conf/app.conf文件
```

#### 运行项目

```bash
bee run -gendoc=true -downdoc=true
```

#### 照葫芦画瓢写接口

> 还好提供了参照

##### controllers\demo.go

```go
package controllers

import (
	"demo-go-api/models"
	"encoding/json"
	"fmt"
	"github.com/astaxie/beego/orm"
	beego "github.com/beego/beego/v2/server/web"
)

// demo控制器
type DemoController struct {
	beego.Controller
}

// @Title GetAll
// @Description 接口介绍
// @Failure 403 uid is empty
// @router /GetAll [get]
func (s *DemoController) GetAll() {}

// @Title GetStr
// @Description GetStrInfo
// @Success 200 {string} delete success!
// @Failure 403 uid is empty
// @router /GetStr [Post]
func (s *DemoController) GetStr() {
	var o orm.Ormer
	o = orm.NewOrm() // 创建一个 Ormer

	log := new(models.Log)
	log.Id = 1
	log.Title = "测试"
	fmt.Println(o.Insert(log)) // 插入对象

	log1 := models.Log{Id: 1}

	err := o.Read(&log1) // 查询

	if err == orm.ErrNoRows {
		fmt.Println("查询不到")
	} else if err == orm.ErrMissPK {
		fmt.Println("找不到主键")
	} else {
		fmt.Println(log1.Id, log1.Title)
	}

	if o.Read(&log1) == nil {
		log1.Title = "MyName"
        // 修改
		if num, err := o.Update(&log1); err == nil {
			fmt.Println(num)
		}
	}
	// 删除
	if num, err := o.Delete(&models.Log{Id: 1}); err == nil {
		fmt.Println(num)
	}

	users := models.GetAllUsers()
	s.Data["json"] = users
	s.ServeJSON()

}

// @Title GetStr1
// @Description 
// @Param	body		body 	models.Log	true		"The object content"
// @Success 200 {string} delete success!
// @Failure 403 uid is empty
// @router /GetStr1 [Post]
func (s *DemoController) GetStr1() {
	var ob models.Log
    // 获取body
	json.Unmarshal(s.Ctx.Input.RequestBody, &ob)
	users := models.GetAllUsers()
	s.Data["json"] = users
	s.ServeJSON()

}

```

##### controllers\user.go

```go
package controllers

import (
	"demo-go-api/models"
	"encoding/json"

	beego "github.com/beego/beego/v2/server/web"
)

// Operations about Users
type UserController struct {
	beego.Controller
}

// @Title CreateUser
// @Description create users
// @Param	body		body 	models.User	true		"body for user content"
// @Success 200 {int} models.User.Id
// @Failure 403 body is empty
// @router / [post]
func (u *UserController) Post() {
	var user models.User
	json.Unmarshal(u.Ctx.Input.RequestBody, &user)
	uid := models.AddUser(user)
	u.Data["json"] = map[string]string{"uid": uid}
	u.ServeJSON()
}

// @Title GetAll
// @Description get all Users
// @Success 200 {object} models.User
// @router / [get]
func (u *UserController) GetAll() {
	users := models.GetAllUsers()
	u.Data["json"] = users
	u.ServeJSON()
}

// @Title Get
// @Description get user by uid
// @Param	uid		path 	string	true		"The key for staticblock"
// @Success 200 {object} models.User
// @Failure 403 :uid is empty
// @router /:uid [get]
func (u *UserController) Get() {
	uid := u.GetString(":uid")
	if uid != "" {
		user, err := models.GetUser(uid)
		if err != nil {
			u.Data["json"] = err.Error()
		} else {
			u.Data["json"] = user
		}
	}
	u.ServeJSON()
}

// @Title Update
// @Description update the user
// @Param	uid		path 	string	true		"The uid you want to update"
// @Param	body		body 	models.User	true		"body for user content"
// @Success 200 {object} models.User
// @Failure 403 :uid is not int
// @router /:uid [put]
func (u *UserController) Put() {
	uid := u.GetString(":uid")
	if uid != "" {
		var user models.User
		json.Unmarshal(u.Ctx.Input.RequestBody, &user)
		uu, err := models.UpdateUser(uid, &user)
		if err != nil {
			u.Data["json"] = err.Error()
		} else {
			u.Data["json"] = uu
		}
	}
	u.ServeJSON()
}

// @Title Delete
// @Description delete the user
// @Param	uid		path 	string	true		"The uid you want to delete"
// @Success 200 {string} delete success!
// @Failure 403 uid is empty
// @router /:uid [delete]
func (u *UserController) Delete() {
	uid := u.GetString(":uid")
	models.DeleteUser(uid)
	u.Data["json"] = "delete success!"
	u.ServeJSON()
}

// @Title Login
// @Description Logs user into the system
// @Param	username		query 	string	true		"The username for login"
// @Param	password		query 	string	true		"The password for login"
// @Success 200 {string} login success
// @Failure 403 user not exist
// @router /login [get]
func (u *UserController) Login() {
    // 获取单个参数
	username := u.GetString("username")
	password := u.GetString("password")
	if models.Login(username, password) {
		u.Data["json"] = "login success"
	} else {
		u.Data["json"] = "user not exist"
	}
	u.ServeJSON()
}

// @Title logout
// @Description Logs out current logged in user session
// @Success 200 {string} logout success
// @router /logout [get]
func (u *UserController) Logout() {
	u.Data["json"] = "logout success"
	u.ServeJSON()
}


```

##### router\router.go

```go
// Package routers @APIVersion 1.0.0
// @Title beego Test API
// @Description beego has a very cool tools to autogenerate documents for your API
// @Contact astaxie@gmail.com
// @TermsOfServiceUrl http://beego.me/
// @License Apache 2.0
// @LicenseUrl http://www.apache.org/licenses/LICENSE-2.0.html
package routers

import (
	"demo-go-api/controllers"

	beego "github.com/beego/beego/v2/server/web"
)

func init() {
	ns := beego.NewNamespace("/v1",
		beego.NSNamespace("/object",
			beego.NSInclude(
				&controllers.ObjectController{},
			),
		),
		beego.NSNamespace("/user",
			beego.NSInclude(
				&controllers.UserController{},
			),
		),
		beego.NSNamespace("/demo",
			beego.NSInclude(
				&controllers.DemoController{},
			),
		),
	)
	beego.AddNamespace(ns)
}
```

##### models\models.go

```go
package models

import (
	"fmt"
	"time"

	"github.com/astaxie/beego"
	"github.com/astaxie/beego/orm"
	_ "github.com/go-sql-driver/mysql"
)

type Store struct {
	Id              int64
	Title           string
	Created         time.Time `orm:"index"`
	Views           int64     `orm:"index"`
	TopicTime       time.Time `orm:"index"`
	TopicCount      int64
	TopicLastUserId int64
}

type Log struct {
	Id    int64
	Title string
}

type Customer struct {
	Id              int64
	Uid             int64
	Title           string
	Content         string `orm:"size(5000)"`
	Attachment      string
	Created         time.Time `orm:"index"`
	Updated         time.Time `orm:"index"`
	Views           int64     `orm:"index"`
	Author          string
	ReplyTime       time.Time `orm:"index"`
	ReplyCount      int64
	ReplyLastUserId int64
}

//这个是个模版方法，搭配 app.conf 使用

func RegisterDB() {
	//注册 model
	orm.RegisterModel(new(Store), new(Customer), new(Log))
	//注册驱动
	orm.RegisterDriver("mysql", orm.DRMySQL)
	//注册默认数据库
	host := beego.AppConfig.String("db::host")
	port := beego.AppConfig.String("db::port")
	dbname := beego.AppConfig.String("db::databaseName")
	user := beego.AppConfig.String("db::userName")
	pwd := beego.AppConfig.String("db::password")

	dbcon := user + ":" + pwd + "@tcp(" + host + ":" + port + ")/" + dbname + "?charset=utf8"
	fmt.Print(dbcon)
	orm.RegisterDataBase("default", "mysql", dbcon) //密码为空格式
	//自动创建表 参数二为是否开启创建表   参数三是否更新表
	orm.RunSyncdb("default", true, true)
	/*"root:root@tcp(localhost:3306)/test"*/
}

```

##### main.go

```go
package main

import (
	"demo-go-api/models"
	_ "demo-go-api/routers"
	"github.com/astaxie/beego/orm"
	beego "github.com/beego/beego/v2/server/web"
)

// 引入数据模型
func init() {
	// 注册数据库
	models.RegisterDB()

}

func main() {
	if beego.BConfig.RunMode == "dev" {
		beego.BConfig.WebConfig.DirectoryIndex = true
		beego.BConfig.WebConfig.StaticDir["/swagger"] = "swagger"
	}
	//// 开启 ORM 调试模式
	orm.Debug = true
	// 自动建表

	orm.RunSyncdb("default", false, true)

	beego.Run()
}
```

##### orm可能需要获取

```bash
go get github.com/astaxie/beego/orm
```

#### 部署到docker

```dockerfile
FROM golang:latest


ENV GOPROXY https://goproxy.cn,direct
WORKDIR $GOPATH/src/github.com/test/demo-go-api
COPY . $GOPATH/src/github.com/test/demo-go-api
RUN go build .


EXPOSE 8000
ENTRYPOINT ["./demo-go-api"]
```

```shell
docker build -t go-api .
docker run -d --name go-api go-api:latest
```

#### goland调试

新增运行调试配置如下

![](..\images\goland调试配置.png)

#### 问题及文档

[beego框架出现的问题-----panic: ./ippanichandle.exe flag redefined: graceful_Studying！！！的博客-CSDN博客](https://blog.csdn.net/qwerty1372431588/article/details/119244413)

[前景 · Go语言中文文档 (topgoer.com)](https://www.topgoer.com/)

[Beego 连接mysql 数据库 - 灰信网（软件开发博客聚合） (freesion.com)](https://www.freesion.com/article/59991204179/)

[如何使用GoLand调试beego项目 - 简书 (jianshu.com)](https://www.jianshu.com/p/fe89dbde6a99)