---
layout: post
title: 命令模式详解
category: thinking
---

# 概述

将一个请求封装为一个对象(即我们创建的Command对象），从而使你可用不同的请求对客户进行参数化; 对请求排队或记录请求日志，以及支持可撤销的操作。

# 解决的问题

在软件系统中，行为请求者与行为实现者通常是一种紧耦合的关系，但某些场合，比如需要对行为进行记录、撤销或重做、事务等处理时，这种无法抵御变化的紧耦合的设计就不太合适。

# 模式中角色

* 抽象命令（Command）：定义命令的接口，声明执行的方法。
* 具体命令（ConcreteCommand）：具体命令，实现要执行的方法，它通常是“虚”的实现；通常会有接收者，并调用接收者的功能来完成命令要执行的操作。
* 接收者（Receiver）：真正执行命令的对象。任何类都可能成为一个接收者，只要能实现命令要求实现的相应功能。
* 调用者（Invoker）：要求命令对象执行请求，通常会持有命令对象，可以持有很多的命令对象。这个是客户端真正触发命令并要求命令执行相应操作的地方，也就是说相当于使用命令对象的入口。
* 客户端（Client）：命令由客户端来创建，并设置命令的接收者。

# 模式解读

* 命令模式的类图

![](http://orxw8wy2g.bkt.clouddn.com/command.jpg)

*  命令模式的实现代码

`Receiver`：接收者类，知道如何实施与执行一个请求相关的操作，任何类都可能作为一个接收者。
```
public class Receiver {
        // 真正的命令实现
        public void Action() {
            System.out.println("Execute request!");
        }
}
```

`ICommand`：抽象命令类，用来声明执行操作的接口。
```
public interface ICommand {
        void Execute();
}
```

`ConcreteCommand`：具体命令类，实现具体命令。
```
public class ConcreteCommand implements ICommand {
        // 具体命令类包含有一个接收者，将这个接收者对象绑定于一个动作
        private Receiver receiver;

        public ConcreteCommand(Receiver receiver) {
            this.receiver = receiver;
        }

        // 说这个实现是“虚”的，因为它是通过调用接收者相应的操作来实现Execute的
        public void Execute() {
            receiver.Action();
        }
}
```

`Invoker`：调度类，要求该命令执行这个请求。
```
public class Invoker {
        private ICommand command;
        /// 设置命令
        public void SetCommand(ICommand command) {
            this.command = command;
        }

        /// 执行命令
        public void ExecuteCommand() {
            command.Execute();
        }
}
```

`Program`：客户端代码。
```
public class Program {
        static void Main(string[] args) {
            Receiver receiver = new Receiver();
            ICommand command = new ConcereteCommand(receiver);
            Invoker invoker = new Invoker();

            invoker.SetCommand(command);
            invoker.ExecuteCommand();
        }
}
```
# 模式分析

* 本质：对命令进行封装，将发出命令与执行命令的责任分开。
* 每一个命令都是一个操作：请求的一方发出请求，要求执行一个操作；接收的一方收到请求，并执行操作。
* 请求方和接收方独立开来，使得请求的一方不必知道接收请求的一方的接口，更不必知道请求是怎么被接收，以及操作是否被执行、何时被执行，以及是怎么被执行的。
* 使请求本身成为一个对象，这个对象和其它对象一样可以被存储和传递。
* 命令模式的关键在于引入了抽象命令接口，且发送者针对抽象命令接口编程，只有实现了抽象命令接口的具体命令才能与接收者相关联。　

# 模式总结

## 优点

* 解除了请求者与实现者(接收者)之间的耦合，降低了系统的耦合度。
* 对请求排队或记录请求日志，支持撤销操作。
* 可以容易地设计一个组合命令。
* 新命令可以容易地加入到系统中。

## 缺点

* 因为针对每一个命令都需要设计一个具体命令类，使用命令模式可能会导致系统有过多的具体命令类。

## 适用场景

* 当需要对行为进行“记录、撤销/重做”等处理时。
* 系统需要将请求者和接收者解耦，使得调用者和接收者不直接交互。
* 系统需要在不同时间指定请求、请求排队和执行请求。
* 系统需要将一组操作组合在一起，即支持宏命令。

# 应用举例

## 银行帐号的存款、提款

* 类图

![](http://orxw8wy2g.bkt.clouddn.com/bankAccount.jpg)

