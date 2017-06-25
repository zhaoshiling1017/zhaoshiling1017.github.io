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

```
	int res = select(maxfd+1, &readfds, NULL, NULL, 120);  
	if (res > 0)  
	{  
    	for (int i = 0; i < MAX_CONNECTION; i++)  
    	{  
        	if (FD_ISSET(allConnection[i], &readfds))  
        	{  
            	handleEvent(allConnection[i]);  
        	}  
    	}  
	}  
```

Epol 不仅会告诉应用程序有IO事件到来，还会告诉应用程序相关信息，这些信息是应用程序填充的，因为根据这些信息应用程序就能直接定位到事件，而不必遍历整个FD集合。

```
	int res = epoll_wait(epfd, events, 20, 120);
	for (int i = 0; i < res;i++)  
	{  
    	handleEvent(events[n]);  
	}
```

# Epoll数据结构

其关键数据结构如下：

```
	struct epoll_event {  
    	__uint32_t events;      // Epoll events  
    	epoll_data_t data;      // User data variable  
	};  
	typedef union epoll_data {  
    	void *ptr;  
    	int fd;  
    	__uint32_t u32;  
   		 __uint64_t u64;  
	} epoll_data_t;  
```

可见 `epoll_data` 是一个 union 结构体 , 借助于它应用程序可以保存很多类型的信息：fd 、指针等等。有了它，应用程序就可以直接定位目标了。

# 使用Epoll

既然 Epoll 相比 select 这么好，那么用起来如何呢？会不会很繁琐啊 … 先看看下面的三个函数吧，就知道 Epoll 的易用了。

```
	int epoll_create(int size);
```

生成一个  Epoll 专用的文件描述符，其实是申请一个内核空间，用来存放你想关注的 socket fd 上是否发生以及发生了什么事件。 size 就是你在这个 Epoll fd 上能关注的最大 socket fd 数，大小自定，只要内存足够。

```
	int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event );
```

控制某个  Epoll 文件描述符上的事件：注册、修改、删除。其中参数 epfd 是 epoll_create() 创建 Epoll 专用的文件描述符。相对于 select 模型中的 FD_SET 和 FD_CLR 宏。

```
	int epoll_wait(int epfd,struct epoll_event * events,int maxevents,int timeout);
```

等待 I/O 事件的发生；参数说明：

epfd: 由 epoll_create() 生成的 Epoll 专用的文件描述符；

epoll_event: 用于回传代处理事件的数组；

maxevents: 每次能处理的事件数；

timeout: 等待 I/O 事件发生的超时值；

返回发生事件数。

相对于 select 模型中的 select 函数。

# 例子程序

下面是一个简单 `Echo Server` 的例子程序，麻雀虽小，五脏俱全，还包含了一个简单的超时检查机制，简洁起见没有做错误处理。

```
	//   
// a simple echo server using epoll in linux  
//   
// 2009-11-05  
// by sparkling  
//   
#include <sys/socket.h>  
#include <sys/epoll.h>  
#include <netinet/in.h>  
#include <arpa/inet.h>  
#include <fcntl.h>  
#include <unistd.h>  
#include <stdio.h>  
#include <errno.h>  
#include <iostream>  
using namespace std;  
#define MAX_EVENTS 500  
struct myevent_s  
{  
    int fd;  
    void (*call_back)(int fd, int events, void *arg);  
    int events;  
    void *arg;  
    int status; // 1: in epoll wait list, 0 not in  
    char buff[128]; // recv data buffer  
    int len;  
    long last_active; // last active time  
};  
// set event  
void EventSet(myevent_s *ev, int fd, void (*call_back)(int, int, void*), void *arg)  
{  
    ev->fd = fd;  
    ev->call_back = call_back;  
    ev->events = 0;  
    ev->arg = arg;  
    ev->status = 0;  
    ev->last_active = time(NULL);  
}  
// add/mod an event to epoll  
void EventAdd(int epollFd, int events, myevent_s *ev)  
{  
    struct epoll_event epv = {0, {0}};  
    int op;  
    epv.data.ptr = ev;  
    epv.events = ev->events = events;  
    if(ev->status == 1){  
        op = EPOLL_CTL_MOD;  
    }  
    else{  
        op = EPOLL_CTL_ADD;  
        ev->status = 1;  
    }  
    if(epoll_ctl(epollFd, op, ev->fd, &epv) < 0)  
        printf("Event Add failed[fd=%d]/n", ev->fd);  
    else  
        printf("Event Add OK[fd=%d]/n", ev->fd);  
}  
// delete an event from epoll  
void EventDel(int epollFd, myevent_s *ev)  
{  
    struct epoll_event epv = {0, {0}};  
    if(ev->status != 1) return;  
    epv.data.ptr = ev;  
    ev->status = 0;  
    epoll_ctl(epollFd, EPOLL_CTL_DEL, ev->fd, &epv);  
}  
int g_epollFd;  
myevent_s g_Events[MAX_EVENTS+1]; // g_Events[MAX_EVENTS] is used by listen fd  
void RecvData(int fd, int events, void *arg);  
void SendData(int fd, int events, void *arg);  
// accept new connections from clients  
void AcceptConn(int fd, int events, void *arg)  
{  
    struct sockaddr_in sin;  
    socklen_t len = sizeof(struct sockaddr_in);  
    int nfd, i;  
    // accept  
    if((nfd = accept(fd, (struct sockaddr*)&sin, &len)) == -1)  
    {  
        if(errno != EAGAIN && errno != EINTR)  
        {  
            printf("%s: bad accept", __func__);  
        }  
        return;  
    }  
    do  
    {  
        for(i = 0; i < MAX_EVENTS; i++)  
        {  
            if(g_Events[i].status == 0)  
            {  
                break;  
            }  
        }  
        if(i == MAX_EVENTS)  
        {  
            printf("%s:max connection limit[%d].", __func__, MAX_EVENTS);  
            break;  
        }  
        // set nonblocking  
        if(fcntl(nfd, F_SETFL, O_NONBLOCK) < 0) break;  
        // add a read event for receive data  
        EventSet(&g_Events[i], nfd, RecvData, &g_Events[i]);  
        EventAdd(g_epollFd, EPOLLIN|EPOLLET, &g_Events[i]);  
        printf("new conn[%s:%d][time:%d]/n", inet_ntoa(sin.sin_addr), ntohs(sin.sin_port), g_Events[i].last_active);  
    }while(0);  
}  
// receive data  
void RecvData(int fd, int events, void *arg)  
{  
    struct myevent_s *ev = (struct myevent_s*)arg;  
    int len;  
    // receive data  
    len = recv(fd, ev->buff, sizeof(ev->buff)-1, 0);    
    EventDel(g_epollFd, ev);  
    if(len > 0)  
    {  
        ev->len = len;  
        ev->buff[len] = '/0';  
        printf("C[%d]:%s/n", fd, ev->buff);  
        // change to send event  
        EventSet(ev, fd, SendData, ev);  
        EventAdd(g_epollFd, EPOLLOUT|EPOLLET, ev);  
    }  
    else if(len == 0)  
    {  
        close(ev->fd);  
        printf("[fd=%d] closed gracefully./n", fd);  
    }  
    else  
    {  
        close(ev->fd);  
        printf("recv[fd=%d] error[%d]:%s/n", fd, errno, strerror(errno));  
    }  
}  
// send data  
void SendData(int fd, int events, void *arg)  
{  
    struct myevent_s *ev = (struct myevent_s*)arg;  
    int len;  
    // send data  
    len = send(fd, ev->buff, ev->len, 0);  
    ev->len = 0;  
    EventDel(g_epollFd, ev);  
    if(len > 0)  
    {  
        // change to receive event  
        EventSet(ev, fd, RecvData, ev);  
        EventAdd(g_epollFd, EPOLLIN|EPOLLET, ev);  
    }  
    else  
    {  
        close(ev->fd);  
        printf("recv[fd=%d] error[%d]/n", fd, errno);  
    }  
}  
void InitListenSocket(int epollFd, short port)  
{  
    int listenFd = socket(AF_INET, SOCK_STREAM, 0);  
    fcntl(listenFd, F_SETFL, O_NONBLOCK); // set non-blocking  
    printf("server listen fd=%d/n", listenFd);  
    EventSet(&g_Events[MAX_EVENTS], listenFd, AcceptConn, &g_Events[MAX_EVENTS]);  
    // add listen socket  
    EventAdd(epollFd, EPOLLIN|EPOLLET, &g_Events[MAX_EVENTS]);  
    // bind & listen  
    sockaddr_in sin;  
    bzero(&sin, sizeof(sin));  
    sin.sin_family = AF_INET;  
    sin.sin_addr.s_addr = INADDR_ANY;  
    sin.sin_port = htons(port);  
    bind(listenFd, (const sockaddr*)&sin, sizeof(sin));  
    listen(listenFd, 5);  
}  
int main(int argc, char **argv)  
{  
    short port = 12345; // default port  
    if(argc == 2){  
        port = atoi(argv[1]);  
    }  
    // create epoll  
    g_epollFd = epoll_create(MAX_EVENTS);  
    if(g_epollFd <= 0) printf("create epoll failed.%d/n", g_epollFd);  
    // create & bind listen socket, and add to epoll, set non-blocking  
    InitListenSocket(g_epollFd, port);  
    // event loop  
    struct epoll_event events[MAX_EVENTS];  
    printf("server running:port[%d]/n", port);  
    int checkPos = 0;  
    while(1){  
        // a simple timeout check here, every time 100, better to use a mini-heap, and add timer event  
        long now = time(NULL);  
        for(int i = 0; i < 100; i++, checkPos++) // doesn't check listen fd  
        {  
            if(checkPos == MAX_EVENTS) checkPos = 0; // recycle  
            if(g_Events[checkPos].status != 1) continue;  
            long duration = now - g_Events[checkPos].last_active;  
            if(duration >= 60) // 60s timeout  
            {  
                close(g_Events[checkPos].fd);  
                printf("[fd=%d] timeout[%d--%d]./n", g_Events[checkPos].fd, g_Events[checkPos].last_active, now);  
                EventDel(g_epollFd, &g_Events[checkPos]);  
            }  
        }  
        // wait for events to happen  
        int fds = epoll_wait(g_epollFd, events, MAX_EVENTS, 1000);  
        if(fds < 0){  
            printf("epoll_wait error, exit/n");  
            break;  
        }  
        for(int i = 0; i < fds; i++){  
            myevent_s *ev = (struct myevent_s*)events[i].data.ptr;  
            if((events[i].events&EPOLLIN)&&(ev->events&EPOLLIN)) // read event  
            {  
                ev->call_back(ev->fd, events[i].events, ev->arg);  
            }  
            if((events[i].events&EPOLLOUT)&&(ev->events&EPOLLOUT)) // write event  
            {  
                ev->call_back(ev->fd, events[i].events, ev->arg);  
            }  
        }  
    }  
    // free resource  
    return 0;  
} 
```

