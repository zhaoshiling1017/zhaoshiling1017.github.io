---
layout: post
title: Java Lambda表达式
category: thinking
---


## 1. 为什么要学Java8
- Java8让你的编程变得更容易
- 充分稳定的利用计算机硬件资源

## 2. Lambda
#### 2.1 Lambda介绍
&emsp;&emsp;lambda具有以下几个特点：


1. 匿名 — 它没有方法名。
2. 函数 - 它和方法一样，具有参数列表、函数体、返回值类型，还可能有可以抛出的异常。
3. 传递 - Lambda表达式可以作为参数传递给方法或者存储在变量中。
4. 简洁 - 无需像匿名类那样写很多代码模版。

#### 2.2 Lambda语法
* **(parameters） -> expression**
* **(parameters) -> { statements; }**

#### 2.3 函数式接口
&emsp;&emsp;函数式接口就是仅定义一个抽象方法的接口（默认方法除外），Lambda表达式允许我们直接以内联的形式为函数式接口的抽象方法提供实现，并把整个表达式作为函数式接口的的实例，例如：

    /** 使用匿名类 */
    Runnable r1 = new Runnable() {
        @Override
        public void run() {
            System.out.println("Hello Java8");
        }
    };
    
    /** 使用Lambda */
    Runnable r2 = () -> System.out.println("Hello Java8");
如果我们有个函数中有个参数为Runnable类型，那么我们可以直接传递Lambda表达式，例如：

    函数定义：
    public void process(Runnable r){
        /** 函数体 */
    }
    函数调用：
    process(() -> System.out.println("Hello World"));
    
    

新版的Java API带有@FunctionInterface注解的接口表示该接口被设计为函数式接口，如果用@FunctionInterface定义了一个接口却有多个抽象方法，那么编译器会报错。


#### 2.4 函数描述符
&emsp;&emsp;函数式接口中唯一的抽象方法的签名就是Lambda表达式的签名，这种抽象方法就叫做函数描述符，例如，Runnable就是一个什么也不接受什么也不返回的签名，所以我们可以用 () -> 来描述参数列表为空返回也为空的函数。

#### 2.5 使用函数式接口
&emsp;&emsp;&emsp;&emsp;新版的Java API已经为我们提供了很多函数式接口，在java.util.function包下，下面我们举例介绍几个常用的接口。

##### 1. Predicate (java.util.function.Predicate&lt;T&gt;)
###### Predicate定义了一个名为test的抽象方法，接收范型T对象，返回一个boolean值

    /** 接口定义 */
    @FunctionInterface
    public interface Predicate<T>{
        boolean test(T t);
    }
    
    /** Example */
    public static <T> List<T> process(List<T> mList, Predicate<T> condition) {
        List<T> results = new ArrayList<>();
        for (T t : mList) {
            if (condition.test(t)) {
                results.add(t);
            }
        }
        return results;
    }
    
##### 2. Consumer (java.util.function.Consumer&lt;T&gt;)\
###### Consumer定义了一个名为accept的抽象方法接收范型T对象，没有返回值(void)

    /** 接口定义 */
    @FunctionInterface
    public interface Consumer<T>{
        void accept(T t);
    }
    
    /** Example */
    public static <T> void process(List<T> mList, Consumer<T> c) {\
        for (T t : mList) {
            c.accept(t);
        }
    }
    
    /** 调用 */
    public static void main(String[] args) {
        List mList = Arrays.asList(1, 2, 3, 4, 5);
        forEach(mList, (Integer i) -> System.out.println(i));
    }
    
    /** Example */
    Consumer<String> consumer = (x) -> System.out.println(x);  
    consumer.accept("hello world");

##### 3. Function (java.util.function.Function&lt;T, R&gt;)
###### Function定义了一个名为apply的抽象方法，接收范型T对象，返回一个范型R对象

    /** 接口定义 */
    @FunctionInterface\
    public interface Function <T, R>{
        R apply(T t);
    }
    
    /** Example */
    public static <T, R> List<R> process(List<T> mList, Function<T, R> f) {
        List<R> results = new ArrayList<>();
        for (T t : mList) {
            results.add(f.apply(t));
        }
        return results;
    }
    
    /** 调用 */
    public static void main(String[] args) {
        List mList = Arrays.asList(1, 2, 3, 4, 5);
        List<Integer> result = process(mList, (String s) -> s.length());
    }
    
        /** Example */
        Function<String, Integer> function = (x) -> x.length();  //{return x.length();};
        System.out.println(function.apply("Hello Java8"));
    
##### 4. Supplier (java.util.function.Supplier&lt;T&gt;)
######Supplier定义了一个名为get的抽象方法，不接受任何参数，返回一个范型T对象

    /** 接口定义 */
    @FunctionalInterface
    public interface Supplier<T> {
        T get();
    }
    
    /** Example */
    Supplier<String> supplier = () -> {return "Hello Java8";};  
    System.out.println(supp.get()); //Hello Java8

##### 5. BinaryOperator<T>
###### (T,&emsp;T) -> T

##### 6. BiPredicate<T, U>
###### (T,&emsp;U) -> boolean

##### 7. BiConsumer<T, U>
###### (T,&emsp;U) -> void

##### 8. BiFunction<T, U, R>
###### (T,&emsp;U) -> R

>注意：Java中的数据类型可分为引用类型（Byte、Integer、List等）和原始类型（byte、int、float、char等）。Java中提供装箱和拆箱的机制，例如装箱就是把原始类型包装后放到堆上，所以装箱后需要更多的内存，所以Java8为大多数函数式接口提供了相应的版本来避免这个问题，例如：

1. IntPredicate、LongPredicate、DoublePredicate
2. IntConsumer、LongConsumer、DoubleConsumer
3. etc.

#### 2.6 类型检查、类型推断
```
这里不做详述
```
#### 2.7 方法引用
&emsp;&emsp;&emsp;&emsp;在Java8中，我们可以直接通过方法引用来简写Lambda表达式中已经存在的方法，这种特性就叫做方法引用。方法引用主要有三类：

* 指向静态方法: lassName::staticMethod  

* 指向任意类型的实例方法: ClassName::instanceMethod

* 指向任意现有对象的实例方法: instanceName::instanceMethod
 
 >针对构造函数、数组构造函数和父类调用一些特殊语法的方法引用:
 
 >1. ClassName::new
 
 >  1.1 Example1:
 
 >   Supplier&lt;Person&gt; supplier = Person::new;
 
 >  Person person = supplier.get();
 
  >  1.2 Example2:
 
 >  Function&lt;String, Person&gt; function = Person::new;
 
 >  Person person = function.apply("myName");
 
 
#### 2.8 Lambda常见应用场景

##### 2.8.1匿名类转Lambda

&emsp;&emsp;如上面的Runnable接口例子。

##### 2.8.2Lambda转方法引用

Lambda非常适合需要传递代码段的场景，但方法引用更能体现代码的可读性，因为相比起Lambda的可以没有参数类型的参数列表，方法名能更直观的体现代码的意图，所以推荐大家使用方法引用。

##### 2.8.3集合遍历
传统集合遍历：

```
final List<String> mList = Arrays.asList("1111", "2222", "3333", "4444");
for (int i = 0; i < mList.size(); i++) {
    System.out.println(mList.get(i));
}   
        
```
增强for循环:

```
for(String str : mList) {
    System.out.println(str);
}    
```

Java8中Iterable接口拥有一个forEach方法用来实现内部遍历器:
\
```
mList.forEach(new Consumer<String>() {
    public void accept(final String str) {
        System.out.println(str);
    }
});  
```
Lambda:

```
mList.forEach((final String str) -> System.out.println(str));

mList.forEach(str -> System.out.println(str));

mList.forEach(System.out::println);
```

##### 2.8.4集合变换
&emsp;&emsp;将集合通过某种变换得到另一个集合也是Lambda的常见使用场景，例如，我们截取集合中的字符串列表中每一项的前两个字符：

```
List<String> mList = Arrays.asList("aaa", "bbb", "ccc", "ddd");

List<String> results = new ArrayList<String>();
for(String str : mList) {
    results.add(str.substring(0, 2));
}
```