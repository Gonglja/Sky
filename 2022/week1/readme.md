# 第1周 研究hurlex 小内核

> 第一次写，时间太紧张了，都是借鉴的大部分写的好的博客，后面在慢慢回顾补全，转变为自己理解的。

主要知识点

- [x] x86寄存器体系
- [x] **Intel** & **AT&T** 汇编
- [ ] ld 链接器文件
- [x] 计算机启动过程
- [ ] 操作系统
    - [学习路线](https://zhuanlan.zhihu.com/p/37810839)

## 基础

### x86寄存器体系

下图描述了一个IA-32提供给我们的一个基本环境中包含的硬件单元。

![image-20220317201528500](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/image-20220317201528500.png)

该架构主要提供以下功能

- 内存管理
- 软件模块的保护
- 多任务处理
- 异常和中断处理
- 多核
- 缓存管理
- 硬件资源和电源管理
- 调试和性能监视



几个地址

- 逻辑地址（logical address）：段基址 加上 段内偏移

- 线性地址（linear address）：段基址与段内偏移合成后的地址

- 物理地址（physical address）：如果没有分页，线性地址就是物理地址；有分页，则需要经过分页机制的转换才能得到物理地址。

    

IA-32处理器运行模式

- 实模式：处理器开机/重启后一开始处于的模式，最大可访问内存为1Mb

- 保护模式：现代处理器支持的原生模式，上电后，处理器开机进入实模式后，从实模式跳转至保护模式。

- 系统管理模式（SMM）：主要供os进行电源管理和OEM差异功能的实现

- 虚拟8086模式：可以在保护模式下运行8086程序

    Intel64架构支持IA-32的所有运行模式和IA-32e模式（简单来说，就是64位对32位的兼容）


-----

转自 [Howard](https://www.zhihu.com/people/he-cheng-chen-59) [Linux内核浅析-X86体系结构](https://zhuanlan.zhihu.com/p/73937048)

#### CPU核心功能 

输入数据 + 指令 = 计算结果。

那么就要解决几个问题：1、获取指令，2、获取输入数据，3、运算，4、存储输出结果

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202203270852774.png)

一个进程能够看到的内存地址是逻辑地址，最后操作时会映射到物理地址，一个进程的内存逻辑地址又分为以下几个Segment。

- Text Segment：存放进程运行的数据
- Data Segment：存放已经初始化的变量。Bss存放未初始化的变量
- Heap：堆，用于进行内存的动态分配
- Stack：栈，函数运行时的栈

#### x86的寻址

在CPU的视角看，是**段基址+段偏移**地址

段基址寄存器

- CS：存储代码段的基址
- DS：存放数据段的基址
- SS：存放运行栈的基址

段偏移地址寄存器

- IP：指令指针寄存器，根据CS+IP获取到的指令存储在EIP（指令寄存器）中，供ALU使用

- EBP：栈基指针寄存器

- ESP：栈顶指针寄存器

- 数据段的偏移一般存储在通用寄存器中，获取到的数据一般也存到通用寄存器中，供ALU使用。

有寻址方式后，CPU直接将地址发送到地址总线上，即可从数据总线收到数据。



#### 分段内存管理

IA32标准：

寻址方式 **线性地址 -> 逻辑地址（分段模式）-> 物理地址**，保存分段模式

内存中有两个存储段地址的表（table）GDT和LDT。

- GDT（Global Descriptor Table，全局描述表），存储内核程序的段基址，由寄存器GDTR保存GDT入口地址

- LDT（Local Descriptor Table，本地描述表），存放各个用户进程的段基址，由寄存器LDTR指向LDT入口地址。

table中的item存储段描述符，其中包括段基址、段界限和权限相关信息。

CS、DS等段基址寄存器仍然为16位，但改为存储**段选择子**，即table的index，这样段基址就存储于内存中。段基址寄存器存储地址时叫“实模式”，存储段选择子时称为“保护模式”。系统启动后先处于实模式，之后切换到保护模式。



#### 函数调用栈帧

Stack Segment处于线性地址的高地址，且向下扩展，所以ESP栈顶指针是向低地址值扩展的，栈基地址反而处于高地址

当 A -> B函数时，会进行以下操作：

- push eip：保存当前的EIP（指向A函数的某条指令），然后通过jmp或ret指令将EIP设置为B函数的起始地址。这样当B函数返回时，再将该EIP的值pop到EIP寄存器中，使得A函数可以继续运行以下的指令。
- push ebp：将A当前的ebp压栈，有两个作用：1）方便B函数获取其入参 2）当B函数返回时，将ebp指向A的栈基址
- mov esp,ebp：将当前esp复制给ebp，相当于ebp从指向A的栈基址变成指向B的栈基址

当前函数的入参，是在上一个调用函数的栈帧中，通过本栈帧中保存的调用者的ebp和参数的size计算入参的地址。



#### 状态寄存器

eflags是状态寄存器，控制单元会根据其值变更执行逻辑。比如IF是中断标志，当陷入中断时，会通过eflags.if标志来关中断。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202203270943556.png)

### Intel & AT&T 汇编语法

CSAPP 中使用的是 AT&T 语法，但Intel 相对简洁，所以一起了解下。

 [汇编语言入门](./reference/汇编语言入门教程%20-%20阮一峰的网络日志.mhtml)

#### 两种语法区别

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/%E4%B8%A4%E7%A7%8D%E6%B1%87%E7%BC%96%E8%AF%AD%E6%B3%95%E5%8C%BA%E5%88%AB.png)

#### AT&T语法

[AT&T Style Syntax](./reference/x86%20Assembly%20Programming.mhtml)

#### Intel语法

[Intel Style Syntax](./reference/Guide%20to%20x86%20Assembly.mhtml)



---

### 计算机启动过程

参考以下，后面在详细整理

https://wiki.osdev.org/Boot_Sequence

https://developer.ibm.com/articles/l-linuxboot/



## 实验

### 实验1 调试hurlex

目的：对启动的时序加深印象

`make debug` 进入调试模式，我们通过阅读以上知识了解到，CPU 地址：$$ cs * 16 + eip$$。

在CPU上电后，通过命令`info registers` 查看寄存器数据，其中 cs寄存器和eip寄存器分别被初始化为`0xf000`、`0xfff0`（见图一），实际访问地址为 `0xffff0`，但在20位地址（实模式）下，最大访问空间也就是`1Mb`（`0xfffff`）,此处仅有16字节，空间太小以至于无法存储bios的代码，所以一般此处为一个跳转指令（使用命令`x/16xb 0xffff0`，结果见图二），跳转bios真正的代码处，然后去执行bios中代码。

在bios中，首先完成*POST*（Power On Self Test，上电自检），bios对计算机各部件进行初始化，如果有错误则报警提示。下一步在外部存储设备中寻找操作系统，找到第一个可启动设备。将第一个可启动存储设备（第一个扇区最后两字节为`0x55aa`）的第一个扇区（512字节）加载至`0x7c00`，然后跳转到`0x7c00`处，去执行相应的代码。所以我们在`0x7c00`处打个断点（`b *0x7c00`），跳转后，查看`0x7c00` 处的最后两字节是否为`0x55 0xaa`（使用命令 `x/512xb 0x7c00`，结果如图3）。

此处执行结束后跳转至 `_start`汇编代码处，此时才真正进入到我们的代码中，在`_kern_entry` 处打断点，进入到我们c语言的世界。

c语言的代码类似`printf("hello,world!!!");`，实际上就是把数据写入到`0xb8000`处。图4和图5为显示不同的内容。



![实验图1](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/20220326154553.png)

![实验图2](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/image-20220317212753122.png)

![实验图3](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/image-20220317205721853.png)

![实验图4](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/image-20220317213140312.png)

![实验图5](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/image-20220317213313188.png)

![实验图6](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/image-20220317213601910.png)



### 实验2 调试一个64位操作系统的设计与实现

TODO

## Q&A







## 参考

1. [intel 汇编](https://www.cs.virginia.edu/~evans/cs216/guides/x86.html)
2. [AT&T 汇编](http://staff.ustc.edu.cn/~xlanchen/cailiao/x86%20Assembly%20Programming.htm) 
3. [汇编语言入门教程](https://www.ruanyifeng.com/blog/2018/01/assembly-language-primer.html) 
3. [启动时序](https://wiki.osdev.org/Boot_Sequence)
3. [Linux内核浅析-X86体系结构](https://zhuanlan.zhihu.com/p/73937048)