---
title: wtm源码解读_2
author: wuxinheng
date: 2022-07-22 22:53:35
description: wtm源码解读_2
tags:
- efcore
- saas
- 多租户
- dotnet
- wtm
categories:
- dotnet
---
### wtm第一次创建DC

1. 找到DC

   WTMContext.cs

   ```C#
   // 这个代码让我回到了19刚出来工作写的VB.net
   // 具体不清楚为什么要这么写，可能是之前的代码懒得改。
   // public IDataContext DC{get;set;} 有什么区别吗？大学老师也是这么教的。
   // 大佬懂得求指教。
   private IDataContext _dc;
   public IDataContext DC
   {
       get
       {
           if (_dc == null)
           {
               _dc = this.CreateDC(); // 进入话题，看CreateDC()
           }
           return _dc;
       }
       set
       {
           _dc = value;
       }
   }
   
   ```

   CreateDC()：这里贴的是最新版的代码

   ```C#
   public virtual IDataContext CreateDC(bool isLog = false, string cskey = null, bool logerror = true)
   {
       string cs = cskey ?? CurrentCS;
       string tenantCode = null;
   	// 获取所有的租户
       var tenants = GlobaInfo.AllTenant ?? new List<FrameworkTenant>();
       string tc = _loginUserInfo?.CurrentTenant;
       // 通过域名来获取租户
       if (tc == null && HttpContext?.Request?.Host != null)
               {
                   tc = tenants.Where(x => x.TDomain != null && x.TDomain.ToLower() == HttpContext.Request.Host.ToString().ToLower()).Select(x => x.TCode).FirstOrDefault();
               }
       // 通过_loginUserInfo来获取租户，这里因该是考虑到域名下其他租户的登录
       // 我现在需要的就是这一步。_loginUserInfo.TenantCode已经有了，但是代入数据库，数据库初始化有点问题
       if (tc != null)
               {
                   var item = tenants.Where(x => x.TCode == tc).FirstOrDefault();
                   tenantCode = tc;
                   //如果租户指定了数据库，则返回
                   if (string.IsNullOrEmpty(cs) && item?.IsUsingDB == true)
                   {
                       return item.CreateDC(this);
                   }
               }
   
       if (isLog == true)
               {
                   if (ConfigInfo.Connections?.Where(x => x.Key.ToLower() == "defaultlog").FirstOrDefault() != null)
                   {
                       cs = "defaultlog";
                   }
               }
       if (string.IsNullOrEmpty(cs))
       {
           cs = "default";
       }
       // 在原来的代码里面没有上面的内容。这里就怎么说呢，讲究人做讲究事。哈哈
       // 我事直接通过CreateDC()传参来传递tenantCode，进而实例化
       // 这里就是比较优雅通过对象的来进行操作，后面我也该成这样了
       var rv = ConfigInfo.Connections.Where(x => x.Key.ToLower() == cs.ToLower()).FirstOrDefault().CreateDC();
       rv.IsDebug = ConfigInfo.IsQuickDebug;
       // 设置tenantCode给DataContext _tenantCode赋值,这里成功把值传到dbcontext
       rv.SetTenantCode(tenantCode);
       if (logerror == true)
       {
           rv.SetLoggerFactory(_loggerFactory);
       }
       return rv;
   }
   ```