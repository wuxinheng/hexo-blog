---
title: wtm多租户实现_增删改
author: wuxinheng
description: EF实现多租户操作数据填充
tags:
  - efcore
  - saas
  - 多租户
  - EF数据过滤
  - dotnet
  - wtm
categories:
  - dotnet
date: 2022-07-22 22:54:54
---
wtm源码解读_3.md 中数据补充有些其他问题。就是写代码的人不遵守wtm的原则来写可能会逃避掉数据补充方法。
我们这里处理的方式可能粗暴点，直接重写datacontext中SaveChanges()

```C#
public override int SaveChanges()
{
    // 多端数据过滤判断
    if (!string.IsNullOrEmpty(TenantCode) && TenantCode != "0")
        UpdateTenantCode();

    return base.SaveChanges();
}

public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default(CancellationToken))
{
    //多端数据过滤判断
    if (!string.IsNullOrEmpty(TenantCode) && TenantCode != "0")
        UpdateTenantCode();

    return await base.SaveChangesAsync(cancellationToken);
}
private void UpdateTenantCode()
{

    // 获取所有新增、更新、删除的实体
    var entities = ChangeTracker.Entries().Where(u => u.State == EntityState.Added || u.State == EntityState.Modified || u.State == EntityState.Deleted);

    foreach (var entity in entities)
    {
        if (typeof(IHasTentant).IsAssignableFrom(entity.Entity.GetType())
            && string.IsNullOrEmpty((entity.Entity as IHasTentant).TenantCode))
        {
            switch (entity.State)
            {
                // 自动设置租户Id
                case EntityState.Added:
                    entity.Property(nameof(IHasTentant.TenantCode)).CurrentValue = TenantCode;
                    break;
                // 排除租户Id
                case EntityState.Modified:
                    entity.Property(nameof(IHasTentant.TenantCode)).IsModified = false;
                    break;
                // 删除处理
                case EntityState.Deleted:
                    break;
            }
        }
    }
}
```