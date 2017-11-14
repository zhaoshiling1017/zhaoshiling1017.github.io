---
layout: post
title: Java Stream流
category: thinking
---


## 1. Stream简介

#### 1.1 Stream定义
&emsp;&emsp;官方对Stream的定义：

&emsp;&emsp;A sequence of elements supporting sequential and parallel aggregate operations.

- Stream是元素的序列
- 顺序和并行的对Stream进行操作

#### 1.2 集合和流

&emsp;&emsp;集合是内存中的数据结构，集合中的每个元素都是计算完成后添加到集合中，集合的每个元素都是存放在内存里。

&emsp;&emsp;流中的元素是按需计算的，是一个延迟创建的集合，在消费的时候才会计算其值。

#### 1.3 （java.util.stream.Stream）举例:
```
List<String> mList = Arrays.asList("a", "bc", "def", "ghi", "jklm", "nopqr");

List<String> result = mList.stream()
        .filter(s -> s.length() > 3)
        .map(String::toUpperCase)
        .limit(2)
        //.forEach(System.out::println)
        .collect(Collectors.toList());
        
//遍历result集合----JKLM和NOPQR
result.forEach(System.out::println);
```


#### 1.4 Stream特点

##### 1.4.1 Stream只能被消费一次
##### 1.4.2 Stream使用流程
* 数据源
* 中间操作（Intermediate）
* 终端操作（Terminal）

##2. 常用Stream操作

==在一次聚合操作中，可以有多个中间操作，但是有且只有一个终端操作==

> **filter**：中间类型，参数为Predicate&lt;T&gt;，函数描述符： T -> boolean，作用：过滤掉流中不满足谓词条件的元素。

> **map**：中间类型， 参数为Function&lt;T, R&gt;，函数描述符为：T -> R，
作用：对流中的每个元素进行计算返回一个新类型的流。

> **flatMap**：中间类型，参数为Function&lt;T, R&gt;，函数描述符为：T -> R，作用：将一个流中的每个值都转成流，然后再将这些流扁平化成为一个流。

> **limit**：中间类型，指定返回流中的元素个数。

> **skip**：中间类型，和limit相反，跳过前n个元素后返回后续的元素。

> **sorted**： 中间类型， 参数为Comparator&lt;T&gt;，函数描述符为：(T, T) -> int，作用：进行排序，得到一个新的流。

> **distinct**：中间类型，作用：去重后得到一个新的流。

> **peek**：中间类型，参数为Consumer&lt;T&gt;，函数描述符为：T -> void，作用：返回原来的流保持不变，一般用作调试，观察流中的每个元素。

> **unordered**：如果数据源是有序的，那么流也就是有序的，在使用并行流的时候允许流是无序可以死获得性能上的提升，unordered()方法来指定无序行为。

> **sequential**：将并行流转换成一个顺序流。 

> **forEach**，终端类型，参数类型为Consumer&lt;T&gt;，返回void，作用：遍历。

> **count**：终端类型，作用：统计元素个数，返回值为long。

> **collect**：终端类型，归约流成一个集合。

## 3. Collectors（）
&emsp;&emsp;java.util.stream.Collectors类的工厂方法提供了很多预定义收集器。

### 3.1 归约

#### 3.1.1 counting
```
long l = mList.stream().collect(Collectors.counting());
```
#### 3.1.2 maxBy、minBy
```
Optional<Integer> opt = mList.stream()
                .collect(Collectors.maxBy(Comparator.comparingInt(Integer::intValue)));
```
#### 3.1.3 summingInt、averagingInt（Long、Double）
```
double value = mList.stream().collect(Collectors.averagingInt(Integer::intValue));

int value = mList.stream().collect(Collectors.summingInt(Integer::intValue));
```
#### 3.1.4 summarizingInt(Long、Double)
```
IntSummaryStatistics iss = mList.stream().collect(Collectors.summarizingInt(Integer::intValue));

打印iss结果：IntSummaryStatistics{count=5, sum=15, min=1, average=3.000000, max=5}
```
#### 3.1.5 joining
```
String str = mList.stream().collect(Collectors.joining());
```

&emsp;&emsp;对于上面的操作，我们都可以用reducing来实现。
```
int sum = mList.stream().collect(Collectors.reducing(0, Integer::intValue, (i ,j) -> i+j));
```

### 3.2 查找匹配
anyMatch(参数为Predicate类型)：
```
if(mList.stream().anyMatch(s -> s.length() > 2)){
}
```

noneMatch、allMatch类似。

findFirst、findAny：

```
Optional<String> str1 = mList.stream()
    .filter(s -> s.length() > 2)
    .findAny();
    
Optional<String> str2 = mList.stream()
    .filter(s -> s.length() > 2)
    .findFirst();
```
> 区别：同样都是返回一个满足条件的元素，但findFirst在并行上有限制，所以如果不关心返回的是第几个，应该使用findAny，因为它更适合并行操作。

### 3.3 分组
&emsp;&emsp;Collectors.groupingBy
```
Map<Person.Sex, List<Person>> map = persons.stream().collect(Collectors.groupingBy(Person::getSex));
```
> 执行结果:{FEMALE=[Lily], MALE=[Tom]}

### 3.4 分区
```
Map<Boolean, List<Person>> map2 = persons.stream().collect(Collectors.partitioningBy(Person::isYoung));
```
> 执行结果:{false=[Tom], true=[Lily]}

### 3.5 Collector接口
```
public interface Collector<T, A, R>{
    Supplier<A> supplier();
    BiConsumer<A, T> accumulator();
    Function<A, R> finisher();
    BinaryOperator<A> combiner();
    Set<Characteristics> characteristics();
}

简单举例：
//创建结果容器
public Supplier<List<T>> supplier(){
  return ArrayList::new
}

//将元素添加至容器
public BiConsumer<<T>, T> accumulator(){
  //retun (list, item) -> list.add(item);
  return List:add;
}

//将结果容器转换为操作的最终结果，这里T -> T
public Function<List<T>, List<T>> finisher(){
  return Function.identity(); //return t -> t
}

//容器合并
public BinaryOperator<List<T>> combiner(){
  return (list1, list2) -> {
    list1.addAll(list2);
    return list1;
  }
}

characteristics:
UNORDERED：无序
CONCURRENT：可以多个线程同时调用accumulator方法并可以并行归约，如果满足UNORDERED可以并行调用，如果没有指定，则只有在是无序的源时才可以并行归约。
```


## 4. 并行流
### 4.1 并行流介绍
&emsp;&emsp;并行流就是把流分为多块，用多个线程并行得去执行，可以 i充分得利用处理器的多核。

&emsp;&emsp;并行流内部使用了jdk1.7新加的Fork/Join框架，默认的线程数量为处理器的核数，我们可以通过以下方式获取：

```
int coreCount = Runtime.getRuntime().availableProcessors();
```

&emsp;&emsp;如果我们需要自己指定线程数可以通过以下方式指定：

```
System.getProperty("java.util.concurrent.ForkJoinPool.common.parallelism", "16");
```

我们求前n个数的和：

```
for(long i = 1L; i <= n; i++){
  result += i;
}
return result;
```
&emsp;&emsp;如果n很大时我们该怎么提高计算性能：
```
return Stream.iterate(1L, i -> i+1)
             .limit(n)
             .parallel()
             .reduce(0L, Long::sum);
```

 ---------------------------------------------------
* iterate生成的是装箱后的对象，再经历拆箱，这会带来额外的内存开销。
* 每次执行都需要依赖上一次执行的结果导致任务很难被拆分，因为无法有效的利用并行来处理，反而增加了线程上下文切换的开销。

&emsp;&emsp;所以我们可以从以下几方面考虑是否有必要使用并行流：

1. **分析任务是否可独立分解**

2. **留意装箱、拆箱带来的额外开销**

3. **注意有些像limit、findFirst等操作并不适合并行执行**

4. **分析流的数据结构分解的性能**

5. **分析最终的终端操作合并时候的性能开销**

6. **比较小的数据量不适合并行运算**

分析：ArrayList、LinkedList、Stream.iterate


> 注意：当我们调用parallel方法后stream并没有任何变化，只是程序在内部设置了一个boolean类型的标记，表示你想让parallel方法后的操作都并行执行。

> 我们可以用parallel、sequential来精确控制顺序执行和并行执行的切换。


### 4.2 Spliterator

```
public interface Spliterator<T>{
  boolean tryAdvance(Consumer<? super T> action);
  SPliterator<T> trySPlit();
  long estimateSize();
  int characteristics();
}
```
&emsp;&emsp;任务拆分是一个递归过程，tryAdvance会一个个的遍历Spliterator中的元素，如果下面还有元素需要遍历则返回true，trySplite方法则会拆分一部分元素给第二个Spliterator并行的进行处理。estimateSize方法会估算剩下多少元素需要遍历尽量保证拆分均匀。

&emsp;&emsp;首先对Spliterator掉用trySplit方法将任务分解生成两个Spliterator，再继续掉用trySplit方法拆分为四个，以此类推，直到返回null，任务分解的过程受characteristics方法中声明的特性影响。


## 5.Optional&lt;T&gt;
&emsp;&emsp;它是一个可以为null的容器类，表示一个值存在或者不存在，它给我们提供了几个方法：

* empty：创建一个空的Optional对象。
* of：将传入的值用Optional封装后返回，如果值为空，则抛出NullPointerException。
* ofNullable：将传入的值用Optional封装后返回，值可以为空且不抛出异常。
* filter：如果值存在切满足给定的条件则返回Optional对象，否则返回一个空的Optional对象。
* get：如果值存在，则封装成Optional返回，否则抛出NoSuchElementException。
* isPresent：判断值是否存在，如果存在返回true，不存在返回false；
* ifPresent：如果值存在，将值封装成Optional返回，否则不执行任何动作。
* orElse：如果值存在则返回，否则返回一个默认值，补抛出异常。
* orElseGet：如果值存在则返回，否则返回一个Supplier接口生成的值。
* orElseThrow：如果值存在则返回，否则返回一个Supplier接口生成的异常。
* map：对Optional实例的值执行一系列操作，操作通过Function接口的lambda表达式传入。
* flatMap：和map方法类似，但map返回值是T，系统会自动包装成Optional，flatMap的返回值必须为Optional类型，所以区别在于区别在于传入方法的lambda表达式的返回类型。

1. 尽量避免使用isPresent、get方法。 
2. Optional类型避免作为属性和参数传递，因为==Optional不支持序列化==。
3. Optional也提供了OptionalInt、OptionalLong等基础类型的Optional，但由于Optional只能封装一个值，所以考虑装箱、拆箱的成本一般并不高，而且这些Optional没有map、flatmap等方法，所以看实际情况使用。
4. map举例：

```
if (null != person) {
  String name = persion.getName();
  if (null != name) {
    return "Mr." + name;
  } else {
    return null;
  }
  return null;
}

 |----------------------------------------------|

return person.map(p -> p.getName())
             .map(name -> "Mr." + name)
             .orElse(null);
```
<br/>
5. 提倡使用方式：

```
//存在值即返回，不存在返回默认值
return opt.orElse(DEFAULT_VALUE);
 
//存在值即返回，不存在则doSomething生成后返回
return opt.orElseGet(()- > doSomething);
 
//条件判断执行（提倡使用方式）
opt.ifPresent(System.out::println);
 
//条件判断执行（避免使用方式）
if(opt.isPresent()){
  doSomething();
}
```