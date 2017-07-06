---
layout: post
title: AWK统计日志中相同IP的次数
category: thinking
---

`cat a.log`：

```
client1|127.0.0.1|2017
client1|127.0.0.1|2016
client1|127.0.1.1|2014
client1|127.0.1.1|2012
client1|127.1.0.1|2012
client1|127.1.0.1|2014
client1|127.0.1.1|2016
client1|127.0.1.1|2017
```

* 统计得到每个IP的次数

`awk -F "|" '{a[$2]++} END {for(i in a){print a[i]" "i}}' a.log | sort`

```
2 127.0.0.1
2 127.1.0.1
4 127.0.1.1
```

* 获取IP次数最高的记录

`awk -F "|" '{a[$2]++} END {for(i in a){print a[i]" "i}}' a.log | sort | awk '{last=$0} END {print last}'`

```
4 127.0.1.1
```