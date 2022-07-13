---
title: wtm多租户实现_查询
author: wuxinheng
description: EF实现多租户查询过滤
tags:
  - efcore
  - saas
  - 多租户
  - EF数据过滤
  - dotnet
  - wtm
categories:
  - dotnet
date: 2022-07-22 22:54:39
---
感谢：[说都不会话了(sharding-core作者)](https://github.com/dotnetcore/sharding-core)
参考：[![返回主页](https://www.cnblogs.com/skins/custom/images/logo.gif)](https://www.cnblogs.com/clis/)[芦荟柚子茶](https://www.cnblogs.com/clis/p/16501586.html)

> 准确来说是EF的全局过滤器使用

一直以来我是错的。DataContext的OnModelCreating其实是在初始化的时候执行。我还以为我每次调用db都会执行，唉~
TenantCode获取请看wtm源码解读1、2

```C#
protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // 基本注册
            //builder.Entity<TestDelete>().HasQueryFilter(e => !e.IsDeleted);
            
            // 获取model中的类获取程序集，因为model跟datacontext不在一个文件夹下
            Assembly assembly = typeof(AuditLog).Assembly;
            // 通过model获取所有的实体类，并进行过滤
            List<Type> entityTypes = assembly.GetTypes()
                .Where(t => t.IsSubclassOf(typeof(BasePoco)) && !t.IsAbstract)
                .ToList();

            // 获取ConfigureFilters方法
            MethodInfo? configureFilters = typeof(DataContext).GetMethod(
                nameof(ConfigureFilters),
                BindingFlags.Instance | BindingFlags.NonPublic
            );

            if (configureFilters == null) throw new ArgumentNullException(nameof(configureFilters));
            // 循环注册
            foreach (var entityType in entityTypes)
            {
                // 注册实体
                modelBuilder.Entity(entityType);

                // 注册筛选器
                configureFilters
                    .MakeGenericMethod(entityType)
                    .Invoke(this, new object[] { modelBuilder, entityType });
            }
        }
// 控制对象的是否忽略过滤，这句应该放在FrameworkContext中或者等级更高的基类中。
public bool IgnoreDeleteFilter { get; set; } = false;

// 拼接表达式对象，进行注册筛选器。
protected virtual void ConfigureFilters<TEntity>(ModelBuilder builder, Type entityType)
           where TEntity : class
        {
            // 剩下的是表达式树，我跟芦荟柚子茶一样，不太了解不敢乱说
            // 重要的概念是@说都不会话了 跟我说的关键信息：
            // 1.expression是延迟计算的
            // 2.e只要expression用了局部变量
            // 3.每次执行sql的时候局部变量是重新计算的
            // 表达式短路（第一次听别人说。还是得跟大佬多接触，新奇）
            // 在这还是非常感谢@说都不会话了
            Expression<Func<TEntity, bool>>? expression = null;

            if (typeof(IPersistPoco).IsAssignableFrom(entityType))
            {
                // 表达式短路
                expression = e => IgnoreDeleteFilter || EF.Property<bool>(e, "IsValid");
            }

            if (typeof(IHasTentant).IsAssignableFrom(entityType))
            {
                // 表达式短路
                Expression<Func<TEntity, bool>> tenantExpression = e =>IgnoreDeleteFilter || EF.Property<string>(e, "TenantCode") == TenantCode;
                expression = expression == null ? tenantExpression : CombineExpressions(expression, tenantExpression);
            }

            if (expression == null) return;

            builder.Entity<TEntity>().HasQueryFilter(expression);
        }

protected virtual Expression<Func<T, bool>> CombineExpressions<T>(Expression<Func<T, bool>> expression1, Expression<Func<T, bool>> expression2)
        {
            var parameter = Expression.Parameter(typeof(T));

            var leftVisitor = new ReplaceExpressionVisitor(expression1.Parameters[0], parameter);
            var left = leftVisitor.Visit(expression1.Body);

            var rightVisitor = new ReplaceExpressionVisitor(expression2.Parameters[0], parameter);
            var right = rightVisitor.Visit(expression2.Body);

            return Expression.Lambda<Func<T, bool>>(Expression.AndAlso(left, right), parameter);
        }
class ReplaceExpressionVisitor : ExpressionVisitor
{
    private readonly Expression _oldValue;
    private readonly Expression _newValue;

    public ReplaceExpressionVisitor(Expression oldValue, Expression newValue)
    {
        _oldValue = oldValue;
        _newValue = newValue;
    }

    public override Expression Visit(Expression? node)
    {
        if (node == _oldValue)
        {
            return _newValue;
        }

        return base.Visit(node)!;
    }
}
```

表达式短路,有意思

```sql
where 1=1 or tenant_id='123' 租户id不会生效
where 1=2 or tenant_id='123' 租户id会生效
--这里其实是通过IgnoreDeleteFilter来进行短路操作，默认为false sql：
--false
select id,name,IsValid,TenantCode where (false or IsValid=1) and  (false or TenantCode=1)
--true 
select id,name,IsValid,TenantCode where (true or IsValid=1) and  (true or TenantCode=1)
```

