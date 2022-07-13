---
title: .Net Core Api 自动不充Result中包含的枚举Display、Description等说明性文字信息字段
author: wuxinheng
date: 2022-07-27 17:47:04
description: 代码片段
tags:
- 我爱写代码
- dotnet
- 代码片段
categories:
- 代码片段
---

```C#
using Microsoft.AspNetCore.Mvc;

using Newtonsoft.Json.Linq;

using System;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Reflection;

namespace WebApplication
{
    /// <summary>
    /// .Net Core Api 自动不充Result中包含的枚举Display、Description等说明性文字信息字段
    /// 字段命名规则为Property+Text,如果存在将会跳过,
    /// </summary>
    public static class ResultTextAutoCompletion
    {
        #region Init Method
        public static IActionResult ResultTextInit<T>(IActionResult actionResult)
            where T : class
        {
            var result = actionResult as ObjectResult;
            if (result.IsInvalid())
                return actionResult;

            JObject obj = new JObject();

            try
            {
                PollingObject<T>(result.Value, obj);
            }
            catch (Exception)
            {
                return actionResult;
            }

            ContentResult contentResult = new ContentResult()
            {
                ContentType = "application/json",
                Content = obj.ToString(),
            };

            return contentResult;
        }
        public static IActionResult ResultTextInit(IActionResult actionResult, AttributeMode mode = AttributeMode.Display)
        {
            Mode = mode;
            var result = actionResult as ObjectResult;
            if (result.IsInvalid())
                return actionResult;

            JObject obj = new JObject();

            try
            {
                PollingObject(result.Value, obj);
            }
            catch (Exception)
            {
                return actionResult;
            }

            ContentResult contentResult = new ContentResult()
            {
                ContentType = "application/json",
                Content = obj.ToString(),
            };

            return contentResult;
        }
        #endregion

        #region Main Method

        private static void PollingObject(object value, JObject ob, string pName = "")
        {
            if (value.IsInvalid())
                ob.AddOrEdit(pName, "");
            else
            {
                var type = value.GetType();
                var properties = type.GetProperties();// 获取所有的属性
                // 如果属性个数是0,说明当前需要保存的属性到底了
                if (properties.Length == 0)
                {
                    if (value is Enum @enum)
                    {
                        ob.AddOrEdit(pName, JToken.FromObject(value)); // 保存属性名称
                        ob.AddOrEdit(pName + "Text", JToken.FromObject(GetText(value)));  // Text值为DisplayAttribute Name
                    }
                    else
                        ob.AddOrEdit(pName, JToken.FromObject(value));// 不是枚举正常保存
                }
                else if (value is string str1)
                    ob.AddOrEdit(pName, str1);
                else if (value is DateTime date1)
                    ob.AddOrEdit(pName, JToken.FromObject(date1));
                else if (value is IEnumerable arr)
                {
                    var Jarray = new JArray();
                    foreach (var item in arr)
                    {
                        Dictionary<string, object> map = null;
                        if (item is Enum @enum)
                        {
                            map = new Dictionary<string, object>(2);
                            map.Add("Key", item);
                            map.Add("Value", GetText(@enum));
                            Jarray.Add(JToken.FromObject(map));
                        }
                        else
                        {
                            // 如果不是枚举,说明是其他集合或数组对象
                            JObject obs = new JObject();
                            PollingObject(item, obs);
                            Jarray.Add(JToken.FromObject(obs));
                        }

                    }

                    if (pName.IsInvalid())
                        ob.AddOrEdit("list", Jarray);
                    else
                        ob.AddOrEdit(pName, Jarray);

                }
                // properties.Length>0
                else
                {

                    if (pName.IsNotInvalid()) //初始对象，对象为引用类型
                    {
                        JObject newJobj = new JObject(); // 需要初始化一个新的对象来保存
                        properties.PollingProperties(x =>
                        {
                            PollingObject(x.GetValue(value), newJobj, x.Name);
                        });
                        ob.AddOrEdit(pName, newJobj);
                    }
                    else
                    {
                        properties.PollingProperties(x =>
                        {
                            if (x.GetValue(value) is DateTime date)
                                ob.AddOrEdit(x.Name, JToken.FromObject(date));
                            else if (x.GetValue(value) is string str)
                                ob.AddOrEdit(x.Name, str);
                            else
                                PollingObject(x.GetValue(value), ob, x.Name);
                        });
                    }
                }
            }
        }
        private static void PollingObject<T>(object value, JObject ob, string pName = "")
            where T : class
        {
            if (value.IsInvalid())
                ob.AddOrEdit(pName, "");
            else
            {
                var type = value.GetType();
                var properties = type.GetProperties();// 获取所有的属性
                // 如果属性个数是0,说明当前需要保存的属性到底了
                if (properties.Length == 0)
                {
                    if (value is Enum @enum)
                    {
                        ob.AddOrEdit(pName, JToken.FromObject(value)); // 保存属性名称
                        ob.AddOrEdit(pName + "Text", JToken.FromObject(GetAttributeText<T>(value)));  // Text值为DisplayAttribute Name
                    }
                    else
                        ob.AddOrEdit(pName, JToken.FromObject(value));// 不是枚举正常保存
                }
                else if (value is string str1)
                    ob.AddOrEdit(pName, str1);
                else if (value is DateTime date1)
                    ob.AddOrEdit(pName, JToken.FromObject(date1));
                else if (value is IEnumerable arr)
                {
                    var Jarray = new JArray();
                    foreach (var item in arr)
                    {
                        Dictionary<string, object> map = null;
                        if (item is Enum @enum)
                        {
                            map = new Dictionary<string, object>(2);
                            map.Add("Key", item);
                            map.Add("Value", GetAttributeText<T>(@enum));
                            Jarray.Add(JToken.FromObject(map));
                        }
                        else
                        {
                            // 如果不是枚举,说明是其他集合或数组对象
                            JObject obs = new JObject();
                            PollingObject(item, obs);
                            Jarray.Add(JToken.FromObject(obs));
                        }

                    }

                    if (pName.IsInvalid())
                        ob.AddOrEdit("list", Jarray);
                    else
                        ob.AddOrEdit(pName, Jarray);

                }
                // properties.Length>0
                else
                {

                    if (pName.IsNotInvalid()) //初始对象，对象为引用类型
                    {
                        JObject newJobj = new JObject(); // 需要初始化一个新的对象来保存
                        properties.PollingProperties(x =>
                        {
                            PollingObject(x.GetValue(value), newJobj, x.Name);
                        });
                        ob.AddOrEdit(pName, newJobj);
                    }
                    else
                    {
                        properties.PollingProperties(x =>
                        {
                            if (x.GetValue(value) is DateTime date)
                                ob.AddOrEdit(x.Name, JToken.FromObject(date));
                            else if (x.GetValue(value) is string str)
                                ob.AddOrEdit(x.Name, str);
                            else
                                PollingObject(x.GetValue(value), ob, x.Name);
                        });
                    }
                }
            }
        }
        #endregion

        #region Select Provider
        private static string GetText(object obj)
        {
            switch (ResultTextAutoCompletion.Mode)
            {
                case AttributeMode.Display:
                    return GetDisplay(obj);
                case AttributeMode.Description:
                    return GetDescription(obj);
                default:
                    return GetDisplay(obj);
            }
        }
        #endregion

        #region GetText Method
        private static string GetAttributeText<T>(object obj)
    where T : class
        {
            var result = "";
            var type = obj.GetType();
            FieldInfo fi = type.GetField(obj.ToString());
            var t = fi.GetCustomAttribute(typeof(T), true) as T;

            var tType = t.GetType();
            var propertyInfos = tType.GetProperties();
            result = propertyInfos.PollingProperties<string>(x =>
            {
                if (x.GetCustomAttribute(typeof(ResultTextAutoCompletionPropertyAttribute), true) is ResultTextAutoCompletionPropertyAttribute)
                    return x?.GetValue(t).ToString() ?? "";
                else
                    return "";
            });
            return result;
        }
        private static string GetDescription(object obj)
        {
            if (obj.IsInvalid()) return "";
            var type = obj.GetType();
            FieldInfo fi = type.GetField(obj.ToString());
            DescriptionAttribute description = fi.GetCustomAttribute(typeof(DescriptionAttribute), true) as DescriptionAttribute;
            return description?.Description ?? obj.ToString();
        }
        private static string GetDisplay(object obj)
        {
            if (obj.IsInvalid()) return "";
            var type = obj.GetType();
            FieldInfo fi = type.GetField(obj.ToString());
            DisplayAttribute display = fi.GetCustomAttribute(typeof(DisplayAttribute), true) as DisplayAttribute;
            return display?.Name ?? obj.ToString();
        }
        private static string GetComment(object obj)
        {
            return "";
        }
        #endregion

        #region Expand Method

        private static bool IsInvalid(this string str) => string.IsNullOrEmpty(str);
        private static bool IsInvalid(this object obj) => obj == null;
        private static bool IsNotInvalid(this object obj) => obj != null;
        private static bool IsNotInvalid(this string str) => !string.IsNullOrEmpty(str);
        private static void AddOrEdit(this JObject obj, string name, JToken? jToken)
        {
            if (obj.GetValue(name).IsNotInvalid())
            {
                obj.Remove(name);
                obj.Add(name, jToken);
            }
            else
                obj.Add(name, jToken);
        }

        #endregion

        #region PollingProperties Method
        private static void PollingProperties(this PropertyInfo[] infos, Action<PropertyInfo> action)
        {
            foreach (var item in infos)
            {
                action.Invoke(item);
            }
        }
        private static T PollingProperties<T>(this PropertyInfo[] infos, Func<PropertyInfo, T> action)
        {
            T result = default(T);
            foreach (var item in infos)
            {
                result = action.Invoke(item);
                if (result.ToString().IsNotInvalid())
                    return result;
            }
            return result;
        }
        #endregion

        #region Private

        /// <summary>
        /// 当前使用模式，默认Display
        /// </summary>
        private static AttributeMode? Mode { get; set; }

        #endregion

        #region Public

        /// <summary>
        /// 默认支持的特性
        /// </summary>
        public enum AttributeMode
        {
            Display = 0,
            Description = 1,
        }

        /// <summary>
        /// 允许使用自定义特性，标记属性是否负责记录
        /// </summary>
        [System.AttributeUsage(System.AttributeTargets.Property)]
        public class ResultTextAutoCompletionPropertyAttribute : System.Attribute
        {
        }

        #endregion


    }
}

```