---
title: wtm源码解读_3
author: wuxinheng
date: 2022-07-22 22:54:13
description: wtm源码解读_3
tags:
- efcore
- saas
- 多租户
- dotnet
- wtm
categories:
- dotnet
---
wtm根据模型会生成一下几个vm对象，vm可能就是mvc、mvvm、里面的模型、试图。
这里可以简单理解为支撑视图的基本类

BaseBatchVM：批量修改

```C#
 public class BaseBatchVM<TModel, TLinkModel> : BaseVM, IBaseBatchVM<TLinkModel> where TModel : TopBasePoco,new() 
where TLinkModel : BaseVM
```

BaseImportVM：导入

```C#
    public class BaseImportVM<T, P> : BaseVM, IBaseImport<T>
        where T : BaseTemplateVM, new()
        where P : TopBasePoco, new()
```

BasePagedListVM：列表

```C#
public class BasePagedListVM<TModel, TSearcher> : BaseVM, IBasePagedListVM<TModel, TSearcher>
        where TModel : TopBasePoco
        where TSearcher : BaseSearcher
```

BaseSearcher：查询对象

BaseCRUDVM：CRUD对象

```C#
public class BaseCRUDVM<TModel> : BaseVM, IBaseCRUDVM<TModel> where TModel : TopBasePoco, new()
```

因为需要对CRUD进行修改，这里对BaseCRUDVM来进行查看，继承BaseCRUDVM的类，并自动进行重写

```C#
protected override void InitVM()
{
	// 初始化数据，可供页面使用
}

public override void DoAdd()
{
    base.DoAdd();
}

public override void DoEdit(bool updateAllFields = false)
{
    base.DoEdit(updateAllFields);
}

public override void DoDelete()
{
    base.DoDelete();
}
```

DoAdd

```C#
public virtual void DoAdd()
{
	// 对实体进行操作，补充审计字段、租户id
    DoAddPrepare();
    //删除不需要的附件
    if (DeletedFileIds != null && DeletedFileIds.Count > 0 && Wtm.ServiceProvider != null)
    {
        var fp = Wtm.ServiceProvider.GetRequiredService<WtmFileProvider>();

        foreach (var item in DeletedFileIds)
        {
            fp.DeleteFile(item.ToString(), DC);
        }
    }
    DC.SaveChanges();
}
```

DoEdit

```C#
/// <summary>
/// 修改，进行默认的修改操作。子类如有自定义操作应重载本函数
/// </summary>
/// <param name="updateAllFields">为true时，框架会更新当前Entity的全部值，为false时，框架会检查Request.Form里的key，只更新表单提交的字段</param>
public virtual void DoEdit(bool updateAllFields = false)
        {
    	    // 应该和DoAdd, 对实体进行操作，补充审计字段
            DoEditPrepare(updateAllFields);

            try
            {
                DC.SaveChanges();
            }
            catch
            {
                MSD.AddModelError(" ", Localizer["Sys.EditFailed"]);
            }
            //删除不需要的附件
            if (DeletedFileIds != null && DeletedFileIds.Count > 0 && Wtm.ServiceProvider != null)
            {
                var fp = Wtm.ServiceProvider.GetRequiredService<WtmFileProvider>();

                foreach (var item in DeletedFileIds)
                {
                    fp.DeleteFile(item.ToString(), DC.ReCreate());
                }
            }

        }
```

DoDelete

```C#
/// <summary>
/// 删除，进行默认的删除操作。子类如有自定义操作应重载本函数
/// </summary>
public virtual void DoDelete()
{
    //如果是PersistPoco，则把IsValid设为false，并不进行物理删除
    if (typeof(IPersistPoco).IsAssignableFrom(typeof(TModel)))
    {
        FC.Add("Entity.IsValid", 0);
        (Entity as IPersistPoco).IsValid = false;

        var pros = typeof(TModel).GetAllProperties();
        //如果包含List<PersistPoco>，将子表IsValid也设置为false
        var fas = pros.Where(x => typeof(IEnumerable<IPersistPoco>).IsAssignableFrom(x.PropertyType)).ToList();
        foreach (var f in fas)
        {
            f.SetValue(Entity, f.PropertyType.GetConstructor(Type.EmptyTypes).Invoke(null));
        }

        DoEditPrepare(false);
        DC.SaveChanges();
    }
    //如果是普通的TopBasePoco，则进行物理删除
    else if (typeof(TModel).GetTypeInfo().IsSubclassOf(typeof(TopBasePoco)))
    {
        DoRealDelete();
    }
}
```

以上代码补充少量注释

重点看一下DoAdd()中的DoAddPrepare()

```c#
private void DoAddPrepare()
        {
            var pros = typeof(TModel).GetAllProperties();
            //将所有TopBasePoco的属性赋空值，防止添加关联的重复内容
            if (typeof(TModel) != typeof(FileAttachment))
            {
                foreach (var pro in pros)
                {
                    if (pro.PropertyType.GetTypeInfo().IsSubclassOf(typeof(TopBasePoco)))
                    {
                        pro.SetValue(Entity, null);
                    }
                }
            }
            //自动设定添加日期和添加人
            if (typeof(IBasePoco).IsAssignableFrom(typeof(TModel)))
            {
                IBasePoco ent = Entity as IBasePoco;
                if (ent.CreateTime == null)
                {
                    ent.CreateTime = DateTime.Now;
                }
                if (string.IsNullOrEmpty(ent.CreateBy))
                {
                    ent.CreateBy = LoginUserInfo?.ITCode;
                }
            }
            //自动设定租户id,这也是我在新版代码中看到的，根据我项目实际情况改了下判断继承类型
            if (typeof(IHasTentant).IsAssignableFrom(typeof(TModel)))
            {
                IHasTentant ent = Entity as IHasTentant;
                ent.TenantCode = LoginUserInfo?.TenantCode;
            }
            if (typeof(IPersistPoco).IsAssignableFrom(typeof(TModel)))
            {
                (Entity as IPersistPoco).IsValid = true;
            }

            #region 更新子表
            foreach (var pro in pros)
            {
                //找到类型为List<xxx>的字段
                if (pro.PropertyType.GenericTypeArguments.Count() > 0)
                {
                    //获取xxx的类型
                    var ftype = pro.PropertyType.GenericTypeArguments.First();
                    //如果xxx继承自TopBasePoco
                    if (ftype.IsSubclassOf(typeof(TopBasePoco)))
                    {
                        //界面传过来的子表数据
                        IEnumerable<TopBasePoco> list = pro.GetValue(Entity) as IEnumerable<TopBasePoco>;
                        if (list != null && list.Count() > 0)
                        {
                            string fkname = DC.GetFKName<TModel>(pro.Name);
                            var itemPros = ftype.GetAllProperties();

                            bool found = false;
                            foreach (var newitem in list)
                            {
                                foreach (var itempro in itemPros)
                                {
                                    if (itempro.PropertyType.IsSubclassOf(typeof(TopBasePoco)))
                                    {
                                        itempro.SetValue(newitem, null);
                                    }
                                    if (!string.IsNullOrEmpty(fkname))
                                    {
                                        if (itempro.Name.ToLower() == fkname.ToLower())
                                        {
                                            try
                                            {
                                                itempro.SetValue(newitem, Entity.GetID());
                                                found = true;
                                            }
                                            catch { }
                                        }
                                    }
                                }
                            }
                            //如果没有找到相应的外建字段，则可能是多对多的关系，或者做了特殊的设定，这种情况框架无法支持，直接退出本次循环
                            if (found == false)
                            {
                                continue;
                            }
                            //循环页面传过来的子表数据,自动设定添加日期和添加人
                            foreach (var newitem in list)
                            {
                                var subtype = newitem.GetType();
                                if (typeof(IBasePoco).IsAssignableFrom(subtype))
                                {
                                    IBasePoco ent = newitem as IBasePoco;
                                    if (ent.CreateTime == null)
                                    {
                                        ent.CreateTime = DateTime.Now;
                                    }
                                    if (string.IsNullOrEmpty(ent.CreateBy))
                                    {
                                        ent.CreateBy = LoginUserInfo?.ITCode;
                                    }
                                }
                                // 同样
                                if (typeof(IHasTentant).IsAssignableFrom(typeof(TModel)))
                                {
                                    IHasTentant ent = Entity as IHasTentant;
                                    ent.TenantCode = LoginUserInfo?.TenantCode;
                                }
                            }
                        }
                    }
                }
            }
            #endregion


            //添加数据
            DC.Set<TModel>().Add(Entity);

        }
```

这里已经看到了一部分的数据补充。但是感觉还是不全。这个我们项目中重写了SaveChanges(),详见《wtm多租户实现_增删改》.md