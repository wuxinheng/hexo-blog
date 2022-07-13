# Hexo NexT Valine

![Theme Version](https://img.shields.io/badge/NexT-v8.2.0+-blue?style=flat-square)
![Package Version](https://img.shields.io/github/package-json/v/next-theme/hexo-next-valine?style=flat-square)

[Valine](https://github.com/xCss/Valine) comment system for NexT. Valine is a fast, simple & efficient Leancloud based no back end comment system.

> **⚠️ WARNING**  
> Valine is no longer open source, and it is reported to have XSS vulnerabilities and data security issues. Use at your own risk.

## Install

```bash
npm install next-theme/hexo-next-valine
```

## Register

1. Create an account or log into [LeanCloud](https://www.leancloud.cn/dashboard/login.html#/signin), and then click on the bottom left corner to [create the application](https://www.leancloud.cn/dashboard/applist.html#/newapp) in [dashboard](https://www.leancloud.cn/dashboard/applist.html#/apps).
    ![Valine](https://theme-next.js.org/images/valine-1.png)
2. Go to the application you just created, select `Settings → App Keys` in the lower left corner, and you will see your APP ID and APP Key.
    ![Valine](https://theme-next.js.org/images/valine-2.png)

## Configure

Set the value `enable` to `true`, add the obtained APP ID (`appId`) and APP Key (`appKey`), and edit other configurations in `valine` section in the config file as following. You can config those in both **hexo** or **theme** `_config.yml`:

```yml next/_config.yml
# Valine
# For more information: https://valine.js.org, https://github.com/xCss/Valine
valine:
  enable: false
  appId:  # your leancloud application appid
  appKey:  # your leancloud application appkey
  serverURLs: # When the custom domain name is enabled, fill it in here
  placeholder: Just go go # comment box placeholder
  avatar: mm # gravatar style
  meta: [nick, mail, link] # Custom comment header
  pageSize: 10 # pagination size
  visitor: false # leancloud-counter-security is not supported for now. When visitor is set to be true, appid and appkey are recommended to be the same as leancloud_visitors' for counter compatibility. Article reading statistic https://valine.js.org/visitor.html
  comment_count: true # If false, comment count will only be displayed in post page, not in home page
  recordIP: false # Whether to record the commenter IP
```
