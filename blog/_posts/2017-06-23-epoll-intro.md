---
layout: post
title: Linux下select/poll/epoll模型介绍
category: thinking
---

# Epoll介绍
`Epoll`在Linux2.6内核中正式引入，和`select`相似，都属于IO多路复用技术。在Linux下设计并发网络程序，除了上述方法，还有：典型Apache模型(Process Per Connection 简称：PPC )，TPC(Thread Per Connection 简称：TPC)，以及`poll`模型。

# 常用模型缺点
1. **PPC/TPC 模型**
这两种模型思想相似，就是每个到来的连接一边自己做事，只是PPC是它开一个进程而TPC开一个线程。当连接过多，会造成频繁的进程/线程切换，造成很大开销。因此这类模型接受的最大连接数有限，一般在几百个左右。
2. **select 模型**
* 最大并发限制；因为一个进程所打开的FD(文件描述符)是有限的，由`FD_SETSIZE`设置。默认值是1024/2048。因此，`select`模型的最大并发数被相应的限制。
* 效率问题；`select`每次调用都会线性扫描全部的FD集合，这样导致效率会呈现线性下降。
* 内存/用户空间；内存拷贝问题，如何让内核把FD消息通知给用户空间，在这个问题上，select采取了内存拷贝方法。
3. **poll模型**
效率基本上和`select`是相同的，`select`第2、3点都没有改掉。
4. **Epoll模型**
* `Epoll`没有最大并发的限制，上限是最大可以打开的文件数目，这个数字一般远大于2048，一般来说这个数目和系统内存关系很大，具体数目可以通过`cat /proc/sys/fs/file-max`查看。
* `select`模型，当IO事件到来时，`select`会通知应用程序事件到来，然后应用程序必须轮询所有的FD集合，测试每个FD是否有事件发生，并处理事件，代码如下：

 	int res = select(maxfd+1, &readfds, NULL, NULL, 120);  
	
