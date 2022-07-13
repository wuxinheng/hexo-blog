---
title: textbox自动补全
author: wuxinheng
description: textbox自动补全
date: 2022-09-05 22:15:01
tags:
- textbox
categories:
- winform
---
#### textbox自动补全

```
textBox1.AutoCompleteMode = AutoCompleteMode.Suggest;
textBox1.AutoCompleteSource = AutoCompleteSource.CustomSource;
textBox1.AutoCompleteCustomSource = new AutoCompleteStringCollection()
{
    "应对伏秋连旱防范旱涝急转" ,
    "应123转" ,
    "1无人机航拍宣传 渔民误作敌机击落热" ,
    "2公司不聘用手机号倒数第5位是5的人热" ,
    "神十四乘组首次出舱官方预告" ,
    "气象局回应南昌现不明飞行物"

};
```

