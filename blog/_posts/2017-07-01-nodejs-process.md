---
layout: post
title: NodeJs进程介绍
category: thinking
---

Node在选型时决定在V8引擎之上构建，也就意味着它的模型与浏览器类似。我们的JavaScript将会运行在单个进程的单个线程上。它带来的好处是，程序状态是单一的，在没有多线程的情况下没有锁、线程同步问题，操作系统在调度时也因为较少上下文的切换，可以很好地提高CPU的使用率。

# 多进程架构

面对单进程单线程对多核使用不足的问题，前人的经验是启动多进程即可。理想状态下每个进程各自利用一个CPU，以此实现多核CPU的利用。所幸，Node提供child_process模块，并且也提供了child_process.fork()函数供我们实现进程的复制。

通过fork()复制的进程都是一个独立的进程，这个进程中有着独立而全新的V8实例。它需要至少30毫秒的启动时间和至少10M的内存。尽管Node提供了fork()供我们复制进程使每个CPU内核都使用上，但是依然要切记fork()进程是昂贵的。

# 创建子进程

`child_process`模块给予Node可以随意创建子进程的能力，它提供了四个方法用于创建进程。

* `spawn()`：启动一个子进程来执行命令。
* `exec()`：启动一个子进程来执行命令，与`spawn()`不同的是其接口不同，它有一个回调函数获知子进程的状况。
* `execFile()`：启动一个子进程来执行可执行文件。
* `fork()`：与`spawn()`类似，不同点在于它创建Node的子进程只需指定要执行的JavaScript文件模块即可。

```
var cp = require('child_process');
cp.spawn('node', ['worker.js']);
cp.exec('node worker.js', function (err, stdout, stderr) {
// some code
});
cp.execFile('worker.js', function (err, stdout, stderr) {
// some code
});
cp.fork('./worker.js');
```

