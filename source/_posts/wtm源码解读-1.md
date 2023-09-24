---
title: wtm源码解读_1
author: wuxinheng
date: 2022-07-22 22:53:08
description: wtm源码解读_1
tags:
- efcore
- saas
- 多租户
- dotnet
- wtm
categories:
- dotnet 
---
## wtm初始化激活

1. 利用Startup.cs通过IServiceCollection对象的AddMvc()的MvcOptions对象来添加过滤器。

   Startup.cs

   ```c#
   public void ConfigureServices(IServiceCollection services)
   {
       services.AddMvc(options =>
       {
           options.UseWtmMvcOptions();
       });
   }
   ```

   MvcOptionExtension.cs

   ```c#
   public static void UseWtmMvcOptions(this MvcOptions options)
   {
       // Filters
       options.Filters.Add(new DataContextFilter());// 读写分离过滤
       options.Filters.Add(new PrivilegeFilter());// 权限过滤
       options.Filters.Add(new FrameworkFilter()); // 激活展示层面、VM层面WTMContext、FC对象
   }
   ```

2. 通过FrameworkFilter.cs激活框架关键对象、添加审计日志

   FrameworkFilter.cs

   ```C#
   public override void OnActionExecuting(ActionExecutingContext context)
   {
       var ctrl = context.Controller as IBaseController; // 逆变获取IBaseController对象
       if (ctrl == null)
       {
           base.OnActionExecuting(context);
           return;
       }
       // 给控制器层面上WTM初始化
       context.SetWtmContext();
       // 开始记录审计日志的开始时间
       if (context.HttpContext.Items.ContainsKey("actionstarttime") == false)
       {
           context.HttpContext.Items.Add("actionstarttime", DateTime.Now);
       }
       var ctrlActDesc = context.ActionDescriptor as ControllerActionDescriptor;
       var log = new SimpleLog();// 初始化log备用
       var ctrlDes = ctrlActDesc.ControllerTypeInfo.GetCustomAttributes(typeof(ActionDescriptionAttribute), false).Cast<ActionDescriptionAttribute>().FirstOrDefault();
       var actDes = ctrlActDesc.MethodInfo.GetCustomAttributes(typeof(ActionDescriptionAttribute), false).Cast<ActionDescriptionAttribute>().FirstOrDefault();
       var postDes = ctrlActDesc.MethodInfo.GetCustomAttributes(typeof(HttpPostAttribute), false).Cast<HttpPostAttribute>().FirstOrDefault();
       var validpostonly = ctrlActDesc.MethodInfo.GetCustomAttributes(typeof(ValidateFormItemOnlyAttribute), false).Cast<ValidateFormItemOnlyAttribute>().FirstOrDefault();
   
       log.ITCode = ctrl.Wtm.LoginUserInfo?.ITCode ?? string.Empty;
       //给日志的多语言属性赋值
       log.ModuleName = ctrlDes?.GetDescription(ctrl) ?? ctrlActDesc.ControllerName;
       log.ActionName = actDes?.GetDescription(ctrl) ?? ctrlActDesc.ActionName + (postDes == null ? string.Empty : "[P]");
       log.ActionUrl = ctrl.BaseUrl;
       log.IP = context.HttpContext.Connection.RemoteIpAddress.ToString();
   
       ctrl.Wtm.Log = log; //通过Wtm来传递Log
       //初始化参数，简介给vm.wtm、以及其他属性赋值。妙！
       foreach (var item in context.ActionArguments)
       {
           if (item.Value is BaseVM)
           {
               var model = item.Value as BaseVM;
               model.Wtm = ctrl.Wtm;
               model.FC = new Dictionary<string, object>();
               model.CreatorAssembly = this.GetType().Assembly.FullName;
               model.ControllerName = context.HttpContext.Request.Path;
               try
               {
                   var f = context.HttpContext.Request.Form;
                   foreach (var key in f.Keys)
                   {
                       if (model.FC.Keys.Contains(key) == false)
                       {
                           model.FC.Add(key, f[key]);
                       }
                   }
                   if (context.HttpContext.Request.QueryString != QueryString.Empty)
                   {
                       foreach (var key in context.HttpContext.Request.Query.Keys)
                       {
                           if (model.FC.Keys.Contains(key) == false)
                           {
                               model.FC.Add(key, context.HttpContext.Request.Query[key]);
                           }
                       }
                   }
               }
               catch { }
   
               if (ctrl is BaseApiController apictrl)
               {
                   //apictrl.TryValidateModel(model);
                   if (context.HttpContext.Items.ContainsKey("DONOTUSE_REQUESTBODY"))
                   {
                       string body = context.HttpContext.Items["DONOTUSE_REQUESTBODY"].ToString();
                       var joption = new JsonSerializerOptions();
                       joption.Converters.Add(new BodyConverter());
                       try
                       {
                           var obj = JsonSerializer.Deserialize<PostedBody>(body, joption);
                           foreach (var field in obj.ProNames)
                           {
   
                               model.FC.Add(field, "");
                           }
                       }
                       catch { }
                   }
               }
               //如果ViewModel T继承自IBaseBatchVM<BaseVM>，则自动为其中的ListVM和EditModel初始化数据
               if (model is IBaseBatchVM<BaseVM> temp)
               {
                   if (temp.ListVM != null)
                   {
                       temp.ListVM.CopyContext(model);
                       temp.ListVM.Ids = temp.Ids == null ? new List<string>() : temp.Ids.ToList();
                       temp.ListVM.SearcherMode = ListVMSearchModeEnum.Batch;
                       temp.ListVM.NeedPage = false;
                   }
                   if (temp.LinkedVM != null)
                   {
                       temp.LinkedVM.CopyContext(model);
                   }
                   if (temp.ListVM != null)
                   {
                       //绑定ListVM的OnAfterInitList事件，当ListVM的InitList完成时，自动将操作列移除
                       temp.ListVM.OnAfterInitList += (self) =>
                       {
                           self.RemoveActionColumn();
                           self.RemoveAction();
                           self.AddErrorColumn();
                       };
                       if (temp.ListVM.Searcher != null)
                       {
                           var searcher = temp.ListVM.Searcher;
                           searcher.CopyContext(model);
                       }
                       temp.ListVM.DoInitListVM();
                   }
                   temp.LinkedVM?.DoInit();
               }
               if (model is IBaseImport<BaseTemplateVM> tvm)
               {
                   var template = tvm.Template;
                   template.CopyContext(model);
                   template.DoReInit();
                   var errorlist = tvm.ErrorListVM;
                   errorlist.CopyContext(model);
               }
               if (model is IBasePagedListVM<TopBasePoco, ISearcher> lvm)
               {
                   var searcher = lvm.Searcher;
                   searcher.CopyContext(lvm);
                   if (ctrl is BaseController)
                   {
                       searcher.DoInit();
                   }
               }
               model.Validate();
               var invalid = ctrl.ModelState.Where(x => x.Value.ValidationState == Microsoft.AspNetCore.Mvc.ModelBinding.ModelValidationState.Invalid).Select(x => x.Key).ToList();
               if ((ctrl as ControllerBase).Request.Method.ToLower() == "put" || validpostonly != null)
               {
                   foreach (var v in invalid)
                   {
                       if (v?.StartsWith("Entity.") == true)
                       {
                           Regex r = new Regex("(.*?)\\[.*?\\](.*?$)");
                           var m = r.Match(v);
                           var check = v;
                           if (m.Success)
                           {
                               check = m.Groups[1] + "[0]" + m.Groups[2];
                           }
                           if (model.FC.Keys.Any(x=>x.ToLower() == check.ToLower()) == false)
                           {
                               ctrl.ModelState.Remove(v);
                           }
                       }
                   }
               }
               if (ctrl is BaseController)
               {
                   var reinit = model.GetType().GetTypeInfo().GetCustomAttributes(typeof(ReInitAttribute), false).Cast<ReInitAttribute>().SingleOrDefault();
                   if (ctrl.ModelState.IsValid)
                   {
                       if (reinit != null && (reinit.ReInitMode == ReInitModes.SUCCESSONLY || reinit.ReInitMode == ReInitModes.ALWAYS))
                       {
                           model.DoReInit();
                       }
                   }
                   else
                   {
                       if (reinit == null || (reinit.ReInitMode == ReInitModes.FAILEDONLY || reinit.ReInitMode == ReInitModes.ALWAYS))
                       {
                           model.DoReInit();
                       }
                   }
               }
   
               //如果是子表外键验证错误，例如Entity.Majors[0].SchoolId为空这种错误，则忽略。因为框架会在添加修改的时候自动给外键赋值
               var toremove = ctrl.ModelState.Select(x => x.Key).Where(x => Regex.IsMatch(x, ".*?\\[.*?\\]\\..*?id", RegexOptions.IgnoreCase));
               foreach (var r in toremove)
               {
                   ctrl.ModelState.Remove(r);
               }
           }
   
           if(item.Value is BaseSearcher se)
           {
               se.FC = new Dictionary<string, object>();
               se.Wtm = ctrl.Wtm;
               se.Validate();
           }
       }
   
       //忽略绑定List<xxx>由于前台传递空字符串造成的错误
       base.OnActionExecuting(context);
   }
   
   // 对请求之后的操作。我没细看，大该是对页面和样式做个处理
   public override void OnActionExecuted(ActionExecutedContext context)
           {
               var ctrl = context.Controller as BaseController;
               if (ctrl == null)
               {
                   base.OnActionExecuted(context);
                   return;
               }
               ctrl.ViewData["DONOTUSE_COOKIEPRE"] = ctrl.Wtm.ConfigInfo.CookiePre;
               var ctrlActDesc = context.ActionDescriptor as ControllerActionDescriptor;
               //get viewname
               string viewName = "";
               if(context.Result is PartialViewResult pvr)
               {
                   viewName = pvr.ViewName??"";
                   if (viewName?.StartsWith("/") == false)
                   {
                       var viewEngine = context.HttpContext.RequestServices.GetRequiredService<ICompositeViewEngine>();
                       viewName = viewEngine.FindView(context, string.IsNullOrEmpty(viewName) ? ctrlActDesc.ActionName : viewName, false)?.View?.Path;
                   }
               }
               if (context.Result is ViewResult vr)
               {
                   viewName = vr.ViewName??"";
                   if (viewName?.StartsWith("/") == false)
                   {
                       var viewEngine = context.HttpContext.RequestServices.GetRequiredService<ICompositeViewEngine>();
                       viewName = viewEngine.FindView(context, string.IsNullOrEmpty(viewName) ? ctrlActDesc.ActionName : viewName, false)?.View?.Path;
                   }
               }
               if (context.Result is PartialViewResult)
               {
                   var model = (context.Result as PartialViewResult).ViewData?.Model as BaseVM;
                   if (model == null && (context.Result as PartialViewResult).Model == null && (context.Result as PartialViewResult).ViewData != null)
                   {
                       model = ctrl.Wtm.CreateVM<BaseVM>();
                       model.CurrentView = viewName;
                       (context.Result as PartialViewResult).ViewData.Model = model;
                   }
                   // 为所有 PartialView 加上最外层的 Div
                   if (model != null)
                   {
                       model.CurrentView = viewName;
                       string pagetitle = string.Empty;
                       var menu = Utils.FindMenu(context.HttpContext.Request.Path,ctrl.GlobaInfo.AllMenus);
                       if (menu == null)
                       {
                           var ctrlDes = ctrlActDesc.ControllerTypeInfo.GetCustomAttributes(typeof(ActionDescriptionAttribute), false).Cast<ActionDescriptionAttribute>().FirstOrDefault();
                           var actDes = ctrlActDesc.MethodInfo.GetCustomAttributes(typeof(ActionDescriptionAttribute), false).Cast<ActionDescriptionAttribute>().FirstOrDefault();
                           if (actDes != null)
                           {
                               if (ctrlDes != null)
                               {
                                   pagetitle = ctrlDes.GetDescription(ctrl) + " - ";
                               }
                               pagetitle += actDes.GetDescription(ctrl);
                           }
                       }
                       else
                       {
                           if (menu.ParentId != null)
                           {
                               var pmenu = ctrl.GlobaInfo.AllMenus.Where(x => x.ID == menu.ParentId).FirstOrDefault();
                               if (pmenu != null)
                               {
                                       pmenu.PageName = Core.CoreProgram._localizer?[pmenu.PageName];
   
                                   pagetitle = pmenu.PageName + " - ";
                               }
                           }
                               menu.PageName = Core.CoreProgram._localizer?[menu.PageName];
                           pagetitle += menu.PageName;
                       }
                       if (string.IsNullOrEmpty(pagetitle) == false)
                       {
                           context.HttpContext.Response.Headers.Add("X-wtm-PageTitle", Convert.ToBase64String(Encoding.UTF8.GetBytes(pagetitle)));
                       }
                       context.HttpContext.Response.Cookies.Append("divid", model.ViewDivId);
                   }
               }
               if (context.Result is ViewResult)
               {
                   var model = (context.Result as ViewResult).ViewData?.Model as BaseVM;
                   if (model == null && (context.Result as ViewResult).Model == null && (context.Result as ViewResult).ViewData != null)
                   {
                       model = ctrl.Wtm.CreateVM<BaseVM>();
                       model.CurrentView = viewName;
                       (context.Result as ViewResult).ViewData.Model = model;
                   }
                  if (model != null)
                   {
                       model.CurrentView = viewName;
                       context.HttpContext.Response.Cookies.Append("divid", model?.ViewDivId);
                   }
               }
               base.OnActionExecuted(context);
           }
   
   // 对对日志其他信息进行补全，和日志记录
   public override void OnResultExecuted(ResultExecutedContext context)
   {
       var ctrl = context.Controller as IBaseController;
       if (ctrl == null)
       {
           base.OnResultExecuted(context);
           return;
       }
       var ctrlActDesc = context.ActionDescriptor as ControllerActionDescriptor;
       var nolog = ctrlActDesc.MethodInfo.IsDefined(typeof(NoLogAttribute), false) || ctrlActDesc.ControllerTypeInfo.IsDefined(typeof(NoLogAttribute), false);
   
       BaseVM model = null;
       if (context.Result is ViewResult vr)
       {
           model = vr.Model as BaseVM;
       }
       if (context.Result is PartialViewResult pvr)
       {
           model = pvr.Model as BaseVM;
           context.HttpContext.Response.WriteAsync($"<script>ff.ResizeChart('{model?.ViewDivId}')</script>");
       }
   
       //如果是来自Error，则已经记录过日志，跳过
       if (ctrlActDesc.ControllerName == "_Framework" && ctrlActDesc.ActionName == "Error")
       {
           return;
       }
       if ( nolog == false)
       {
               var log = new ActionLog();
               var ctrlDes = ctrlActDesc.ControllerTypeInfo.GetCustomAttributes(typeof(ActionDescriptionAttribute), false).Cast<ActionDescriptionAttribute>().FirstOrDefault();
               var actDes = ctrlActDesc.MethodInfo.GetCustomAttributes(typeof(ActionDescriptionAttribute), false).Cast<ActionDescriptionAttribute>().FirstOrDefault();
               var postDes = ctrlActDesc.MethodInfo.GetCustomAttributes(typeof(HttpPostAttribute), false).Cast<HttpPostAttribute>().FirstOrDefault();
   
               log.LogType = context.Exception == null ? ActionLogTypesEnum.Normal : ActionLogTypesEnum.Exception;
               log.ActionTime = DateTime.Now;
               log.ITCode = ctrl.Wtm?.LoginUserInfo?.ITCode ?? string.Empty;
               // 给日志的多语言属性赋值
               log.ModuleName = ctrlDes?.GetDescription(ctrl) ?? ctrlActDesc.ControllerName;
               log.ActionName = actDes?.GetDescription(ctrl) ?? ctrlActDesc.ActionName + (postDes == null ? string.Empty : "[P]");
               log.ActionUrl = context.HttpContext.Request.Path;
               log.IP = context.HttpContext.GetRemoteIpAddress();
               log.Remark = context.Exception?.ToString() ?? string.Empty;
               if (string.IsNullOrEmpty(log.Remark) == false && log.Remark.Length > 2000)
               {
                   log.Remark = log.Remark.Substring(0, 2000);
               }
           	// 这里非常好，反正我没想到。利用请求上下文来记录action开始时间。保持了一致性。我之前是通过私有变量来计算，可能会存在问题。起码异步的时候有问题。
               var starttime = context.HttpContext.Items["actionstarttime"] as DateTime?;
               if (starttime != null)
               {
                   log.Duration = DateTime.Now.Subtract(starttime.Value).TotalSeconds;
               }
               try
               {
               var logger = context.HttpContext.RequestServices.GetRequiredService<ILogger<ActionLog>>();
               if (logger != null)
               {
                   // 此处用的是.net core的系统日志来实现。具体使用我在疫情期间也看过，具体文档可看：wtm日志实现.md
                   logger.Log<ActionLog>(LogLevel.Information, new EventId(), log, null, (a, b) =>
                   {
                       return a.GetLogString();
                   });
               }
               }
               catch { }
       }
       if (context.Exception != null)
       {
           context.ExceptionHandled = true;
           if (ctrl.Wtm.ConfigInfo.IsQuickDebug == true)
           {
               context.HttpContext.Response.WriteAsync(context.Exception.ToString());
           }
           else
           {
               context.HttpContext.Response.WriteAsync(MvcProgram._localizer["Sys.PageError"]);
           }
       }
       base.OnResultExecuted(context);
   }
   ```

