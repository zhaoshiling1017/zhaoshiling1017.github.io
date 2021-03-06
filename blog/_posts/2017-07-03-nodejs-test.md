---
layout: post
title: NodeJs测试介绍
category: thinking
---

# 单元测试

单元测试在软件项目中扮演着举足轻重的角色，是几种软件质量保证的方法中投入产出比最高的一种。尽管在过去的JavaScript开发中，绝大多数人都忽视这个环节，但今天Node的盛行让我们不得不重新审视这块领域。

编写可测试代码需要遵循以下几个原则：

* 单一原则
* 抽象接口
* 层次分离

单元测试主要包括断言、测试框架、测试用例、测试覆盖率、mock、持续集成等几个方面，由于Node的特殊性，它还会加入异步代码测试和私有方法的测试这两部分。

* 断言

在程序设计中，断言是一种放在程序中的一阶逻辑(如一个结果为真或者为假的逻辑判断式)，目的是为了标示程序开发着预期的结果，当程序运行到断言的位置时，对应的断言应该为真。若断言不为真，程序会中止运行，并出现错误信息。

在断言规范中，我们定义了以下几种检测方法：
`ok()`：判断结果是否为真。
`equal()`：判断实际值与期望值是否相等。
`notEqual()`：判断实际值与期望值是否不相等。
`deepEqual()`：判断实际值与期望值是否深度相等(对象或数组的元素是否相等)。
`notDeepEqual()`：判断实际值与期望值是否深度不相等。
`strictEqual()`：判断实际值与期望值是否严格相等(相 于 === )。
`notStrictEqual()`：判断实际值与期望值是否严格不相等(相 于 !== )。
`throws()`：判断代码是否有异常抛出。

* 测试框架

前面提到断言一旦检查失败，将会抛出异常停止整个应用，这对于做大规模断言检查时并不友好。更通用的做法是，记录抛下的异常并继续执行，最后生成测试报告，这个任务的承担着就是测试框架，如 `mocha`等。

# 基准测试

基准测试要统计的就是在多少时间内执行了多少次某个方法。为了增强可比性，一般会以次数作为参照物，然后比较时间，以此来判别性能的差距。

# 压力测试

除了对基本的方法进行基准测试外，通常还会对网络接口进行压力测试以判断网络接口的性能。对网络接口做压力测试需要考察的几个指标有吞吐量、响应时间和并发数，这些指标反应了服务器的并发处理能力。最常用的工具有ab、siege、http_load等。

