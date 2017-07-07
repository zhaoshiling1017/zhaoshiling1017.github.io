---
layout: post
title: 经典shell题目
category: communication
---

# 取出/etc/passwd文件中shell出现的次数

```
avahi-autoipd:x:104:114:Avahi autoip daemon,,,:/var/lib/avahi-autoipd:/bin/false
avahi:x:111:118:Avahi mDNS daemon,,,:/var/run/avahi-daemon:/bin/false
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
beanstalkd:x:124:128:Beanstalk Server,,,:/var/lib/beanstalkd:/bin/false
bin:x:2:2:bin:/bin:/usr/sbin/nologin
colord:x:114:124:colord colour management daemon,,,:/var/lib/colord:/bin/false
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
debian-spamd:x:118:129::/var/lib/spamassassin:/bin/sh
dnsmasq:x:103:65534:dnsmasq,,,:/var/lib/misc:/bin/false
freeswitch:x:999:999:FreeSWITCH:/var/lib/freeswitch:/bin/false
games:x:5:60:games:/usr/games:/usr/sbin/nologin
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/usr/sbin/nologin
hplip:x:115:7:HPLIP system user,,,:/var/run/hplip:/bin/false
irc:x:39:39:ircd:/var/run/ircd:/usr/sbin/nologin
kernoops:x:106:65534:Kernel Oops Tracking Daemon,,,:/:/bin/false
lenzhao:x:1000:1000:lenzhao,,,:/home/lenzhao:/usr/bin/fish
lightdm:x:112:119:Light Display Manager:/var/lib/lightdm:/bin/false
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
messagebus:x:101:105::/var/run/dbus:/bin/false
mongodb:x:122:65534::/var/lib/mongodb:/bin/false
munin:x:119:130:munin application user,,,:/var/lib/munin:/bin/false
mysql:x:117:127:MySQL Server,,,:/nonexistent:/bin/false
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
postgres:x:116:126:PostgreSQL administrator,,,:/var/lib/postgresql:/bin/bash
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
pulse:x:113:122:PulseAudio daemon,,,:/var/run/pulse:/bin/false
rabbitmq:x:123:134:RabbitMQ messaging server,,,:/var/lib/rabbitmq:/bin/false
root:x:0:0:root:/root:/bin/bash
rtkit:x:107:115:RealtimeKit,,,:/proc:/bin/false
saned:x:108:116::/home/saned:/bin/false
sbt:x:998:997:sbt daemon-user:/home/sbt:/bin/false
smmsp:x:121:132:Mail Submission Program,,,:/var/lib/sendmail:/bin/false
smmta:x:120:131:Mail Transfer Agent,,,:/var/lib/sendmail:/bin/false
speech-dispatcher:x:105:29:Speech Dispatcher,,,:/var/run/speech-dispatcher:/bin/false
sync:x:4:65534:sync:/bin:/bin/sync
syslog:x:100:103::/home/syslog:/bin/false
sys:x:3:3:sys:/dev:/usr/sbin/nologin
usbmux:x:109:46:usbmux daemon,,,:/var/lib/usbmux:/bin/false
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
uuidd:x:102:107::/run/uuidd:/bin/false
whoopsie:x:110:117::/nonexistent:/bin/false
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
```

参考答案：

```
awk -F ":" '{a[$7]++} END {for(i in a){print a[i]" "i;}}' /etc/passwd
```
```
cat /etc/passwd | awk -F ":" '{print $7}' | sort | uniq -c
```

结果：

```
1 /bin/sync
2 /bin/bash
1 /bin/sh
1 /usr/bin/fish
25 /bin/false
16 /usr/sbin/nologin
```

其中：`uniq` 命令读取由 InFile 参数指定的标准输入或文件，该命令首先比较相邻的行，然后除去第二行和该行的后续副本；
`uniq -c` 在输出行前面加上每行在输入文件中出现的次数；
`uniq -u` 只显示不重复的行；
`uniq -d` 只显示重复的行。

# 文件处理

`employee`文件中记录了工号和姓名
```
100 Jason Smith   
200 John Doe   
300 Sanjay Gupta   
400 Ashok Sharma   
```

`bonus`文件中记录工号和工资
```
100 $5,000   
200 $500   
300 $3,000   
400 $1,250  
```

要求把两个文件合并并输出如下
处理结果：
```
400 ashok sharma $1,250  
100 jason smith  $5,000  
200 john doe  $500  
300 sanjay gupta  $3,000 
```

参考答案：

```
paste -d " " employee.txt  bonus.txt  | awk '{print  $1,$2,$3,$5}' | tr '[:upper:]' '[:lower:]' | sort -k 2
```

结果：
```
400 ashok sharma $1,250
100 jason smith $5,000
200 john doe $500
300 sanjay gupta $3,000
```

其中：paste命令用于合并多个文件的同行数据，可以使用-d指定合并时加入的符号，tr命令用于将字符串中所有大写字符转换为小写字符。sort命令对字符排序。sort -k 2表示按文件第2个域排序，这里第二个域为姓名，所以是按姓名升序排序。如果要降序排列，则要用sort -k 2r。


# 打印本机交换分区大小

打印本机交换分区大小，输出如下：
```
Swap:1024M
```

参考答案：

```
free -m | grep Swap | awk '{print $1,$2"M"}'
```

# 用户清理

清除本机除了当前登陆用户以外的所有用户：

参考答案：

```
kill $(who -u|grep -v `whoami`|awk '{print $6}'|sort -u)
```

# 面试题

写脚本实现，可以用shell、perl等。在目录/tmp下找到100个以abc开头的文件，然后把这些文件的第一行保存到文件new中。

参考答案1：

```
#!/bin/sh  
for filename in `find /tmp -type f -name "abc*"|head -n 100`  
do  
sed -n '1p' $filename >> new  
done  
```

```
find /tmp -type f -name “abc*” | head -n 100 | xargs head -q -n 1 >> new  
```

其中`head -q`不显示包含给定文件名的文件头。

```
==> ./subwaydb0512.sql <==
-- MySQL dump 10.13  Distrib 5.6.27, for Linux (x86_64)

==> ./subwaydb20160721.sql <==
-- MySQL dump 10.13  Distrib 5.5.43, for debian-linux-gnu (x86_64)

==> ./subwaydb20160504.sql <==
-- MySQL dump 10.13  Distrib 5.6.27, for Linux (x86_64)
```

```
-- MySQL dump 10.13  Distrib 5.6.27, for Linux (x86_64)
-- MySQL dump 10.13  Distrib 5.5.43, for debian-linux-gnu (x86_64)
-- MySQL dump 10.13  Distrib 5.6.27, for Linux (x86_64)
```

写脚本实现，可以用shell、perl等。把文件b中有的，但是文件a中没有的所有行，保存为文件c，并统计c的行数。

参考答案：

```
grep -vxFf a b | tee c | wc -l
```

其中grep选取-v表示不选择匹配的行，-x 显示与指定模式精确匹配而不含其他字符的行，-F表示匹配的模式按行分割，-f a表示匹配模式来自文件a，最后表示目标文件b。即grep命令从b中选取a中不存在的行。tee c命令读取标准输入的数据生成文件c，wc -l命令统计行数。



