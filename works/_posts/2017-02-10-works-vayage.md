---
title: Voyage
category: works
icon: code-fork
tags: [Java]
link: "https://github.com/zhaoshiling1017/voyage"
public: false
---


#Overview

采用Java实现的基于netty轻量的高性能分布式RPC服务框架。实现了RPC的基本功能，开发者也可以自定义扩展，简单，易用，高效。

# Features

>
* 服务端支持注解配置
* 客户端实现Filter机制，可以自定义Filter
* 基于netty3.x实现，后期会升级至netty4.x，充分利用netty的高性能
* 数据层提供protostuff和hessian的实现，可以自定义扩展ISerializer接口
* 负载均衡算法采用LRU算法，可以自定义扩展ILoadBlance接口
* 客户端支持服务的同步或异步调用
