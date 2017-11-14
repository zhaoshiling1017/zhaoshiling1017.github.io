---
layout: post
title: synchronized如何实现
category: thinking
---


# 对象头 Mark

锁就保存在对象头中，对象头分为两部分信息，第一部分用于存储对象自身运行时的数据，如HashCode，GC分代年龄等，另一部分用于存储指向方法区类型数据（Class）的指针。

# 偏向锁

偏向锁实际上是一种优化锁，其目的是为了减少数据在无竞争情况下的性能损耗。其核心思想就是锁会偏向第一个获取它的线程，在接下来的执行过程中该锁没有其他的线程获取，则持有偏向锁的线程永远不需要同步。

# 轻量级锁

在没有多线程竞争的前提下，减少传统的重量级锁使用操作系统互斥量产生的性能损耗。

# 自旋锁

sychronized锁是一种重量级锁，在互斥状态下，没有得到锁的线程会被挂起阻塞，而挂起线程和恢复线程的操作都需要转入内核态中完成。所谓自旋锁，就是让没有获得锁的进程自己运行一段时间自循环（默认开启），但是不挂起线程的代价就是该线程会一直占用处理器，如果锁占用的时间很短，自旋等待的效果很好，反之，自旋锁会消耗大量处理器资源，因此，自旋的等待时间必须有一定限度，超过限度还没有获得锁，就要挂起线程。

# 锁的升级过程

为了减少获得锁和释放锁带来的性能消耗，这几个状态会随着竞争情况逐渐升级，状态依次是无状态锁、偏向锁、轻量级锁、自旋锁和重量级锁。锁只能升级不能降级。

# synchronized用法

修饰方法和代码块：某个线程得到了对象锁，但是另一个线程还是可以访问没有进行同步的方法或者代码，进行了同步的方法和没有进行同步的方法是互不影响的，一个线程进入了同步方法，得到了对象锁，其他线程还是可以访问那些没有同步的方法，两个被加锁的对象方法具有互斥性。同时修饰静态方法和实例方法，却可以交替进行互不干扰。

# synchronized的缺陷

当某个线程进入同步方法获得对象锁，那么其他线程访问这里对象的同步方法时，必须等待或者阻塞，对高并发系统是致命的。如果某个线程在同步方法里面发生了死循环，那么永远不会释放对象锁，其他线程就要永远等待。

synchronized块具有优势，同步操作的内容可以与同步对象无关。


# 事务介绍

事务的四个属性：持久性、原子性、隔离性、一致性。其中一致性是最基本的属性，其他三个属性都是为了保证一致性二存在的。所谓一致性是指数据处于一种有意义的状态，这种状态是语义上的而不是语法上的。例如转账过程中的一致性。
在数据库实现场景中，一致性可以分为数据库外部一致性和数据库内部一致性。前者由外部应用的编码来保证，即某个应用在执行转账的数据库操作时，必须在同一个事务内部调用对账户A和账户B的操作，是数据库本身能解决的。后者有数据库来保证，即在同一个事务内部的一组操作必须全部执行成功，这是事务处理的原子性。

为了实现原子性，需要通过日志，将所有对数据库的更新操作都写入日志，如果一个事务中的一部分操作成功，但以后的操作无法继续，则通过回溯日志，将已经操作成功的操作撤销，从而达到全部操作失败的目的。典型场景是，数据库系统崩溃后重启，此时数据库处于不一致的状态，必须先执行一个crash recovery的过程，读取日志进行redo（重演将所有已经执行但未成功写入到磁盘的操作，保证持久性），再对所有到崩溃时尚未成功提交的事务进行undo（撤销所有执行了一部分但尚未提交的操作，保证原子性）。crash recovery结束后，数据库恢复到一致性状态。

在多个事务并行进行的情况下，即时保证了每一个事务的原子性，仍然可能导致数据的不一致的结果。对此引入了隔离性，即保证每一个事务能够看到的数据总是一致的，好像其他并发事务并不存在一样。实现隔离性有两种典型锁：

一种是**悲观锁**，即当前事务将所有涉及w操作的对象加锁，操作完成后释放给其他对象使用。为了尽可能提高性能。发明了各种粒度，各种性质的锁，为了解决死锁问题，又发明了两阶段锁协议等一些列技术。

乐观锁（ Optimistic Locking ） 相对悲观锁而言，乐观锁假设认为数据一般情况下不会造成冲突，所以在数据进行提交更新的时候，才会正式对数据的冲突与否进行检测，如果发现冲突了，则返回用户错误的信息，让用户决定如何去做。相对于悲观锁，在对数据库进行处理的时候，乐观锁并不会使用数据库提供的锁机制。一般的实现乐观锁的方式就是记录数据版本。数据版本，为数据增加的一个版本标识。当读取数据时，将版本标识的值一同读出，数据每更新一次，同时对版本标识进行更新。当我们提交更新的时候，判断数据库表对应记录的当前版本信息与第一次取出来的版本标识进行比对，如果数据库表当前版本号与第一次取出来的版本标识值相等，则予以更新，否则认为是过期数据。实现数据版本有两种方式，第一种是使用版本号，第二种是使用时间戳。