### 目的
了解linux0.11的设计思想

### 阅读教程

[闪客新系列！你管这破玩意叫操作系统](https://mp.weixin.qq.com/s?__biz=Mzk0MjE3NDE0Ng==&mid=2247499207&idx=1&sn=f00bf7653ae57faa6266bfd18287e6bb&chksm=c2c5876af5b20e7cdf5094696d266ee3fa09514601b021ce602ecaf0ec79857045b43e286a58&scene=178&cur_album_id=2123743679373688834#rd)

[闪客新系列！目录](https://mp.weixin.qq.com/mp/appmsgalbum?__biz=Mzk0MjE3NDE0Ng==&action=getalbum&album_id=2123743679373688834&subscene=159&subscene=178&scenenote=https%3A%2F%2Fmp.weixin.qq.com%2Fs%3F__biz%3DMzk0MjE3NDE0Ng%3D%3D%26mid%3D2247499207%26idx%3D1%26sn%3Df00bf7653ae57faa6266bfd18287e6bb%26chksm%3Dc2c5876af5b20e7cdf5094696d266ee3fa09514601b021ce602ecaf0ec79857045b43e286a58%26scene%3D178%26cur_album_id%3D2123743679373688834%23rd&nolastread=1#wechat_redirect)

**系列整体布局**：

第一部分：进入内核前的苦力活

第二部分：大战前期的初始化工作

第三部分：一个新进程的诞生

第四部分：shell 程序的到来

第五部分：从一个命令的执行看操作系统各模块的运作

第六部分：操作系统哲学与思想



![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204021607476.png)

### 笔记

#### 系统上电后跳转至nios

当系统启动或者重置时，处理器在已知位置执行代码。在笔记本（PC）中，此位置位于BIOS（Base input/output System，基本输入/输出系统），该系统存储在主板的bios芯片中。

当系统启动或重置时，处理器会默认跳转到bios中执行代码。为什么？

首先我们要了解CPU上电后运行在实模式下，在实模式下CPU的寻址方式为:$CS*4 + IP$，而上电后$CS$默认值为`0xffff`,$IP$默认值为`0x0000`。所以上电后CPU会到$CS*16+IP=0xffff << 4 + 0x0 = 0xffff0$处执行第一条指令。但在20位地址下，最大访问空间也就是`1Mb`（`0xfffff`），此处仅有16字节，空间太小以至于无法存储bios的代码，所以一般此处都为一个跳转指令。跳转到真正的bios处执行代码。

#### bios完成后跳转0x7c00处

在bios中，首先完成*POST*（Power On Self Test，上电自检），bios对计算机各部件进行初始化，如果有错误则报警提示。下一步在外部存储设备中寻找操作系统，找到第一个可启动设备。将第一个可启动存储设备（第一个扇区最后两字节为`0x55`、`0xaa`）的第一个扇区（512字节）原封不动的复制到`0x7c00`，然后跳转到`0x7c00`处，去执行相应的代码。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204021631675.png)

在linux0.11中，就是用Intel汇编语法写的`bootsect.asm`，通过编译，这个`bootsect.asm`被编译成二进制文件，放到启动区的第一扇区。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204021638456.png)

之后，CPU便跳转至0x7c00处继续执行代码。

#### 拷贝第一个扇区数据到0x90000处

从代码来看

```assembly
_start:
	mov	ax,0x7c00	; 给寄存器ax赋值0x7c00
	mov	ds,ax		; 给寄存器ds赋值为ax 也就是0x7c00
	mov	ax,0x9000	; 给寄存器ax赋值0x9000
	mov	es,ax		; 给寄存器es赋值为ax 也就是0x9000
	mov	cx,256		; 给寄存器cx赋值为256
	sub	si,si		; 寄存器si清0，
	sub	di,di		; 寄存器di清0
	rep 			; 重复以下指令cx次（256次）
	movsw			; 从源地址拷贝数据（数据大小，word）到目的地址
```

疑问1？为什么不直接给ds赋值，Intel不允许**直接**给ds赋值

疑问2？给寄存器si清零，为什么不采用 `mov si,0`,mov指令长度较sub长 

>**movsw**：数据传送指令，从源地址向目的地址传送数据
>
>在16位模式下，源地址`DS:SI` ，目的地址`ES:DI`
>
>在32位模式下，源地址`DS:ESI`，目的地址`ES:EDI`
>
>movsb、movsw、movsd 区别，b字节、w字、d双字，也即传递一个字节、一个字、一个双字。

所以这段代码的作用就是将从`DS:SI`（`0x7c0:0x0`即`0x7c00`）处开始，大小为256字，即512字节的数据拷贝到`ES:DI`(`0x9000:0x0`即`0x90000`处。

也就是将从硬盘中拷贝过来的第一个扇区在上电后拷贝到`0x7c00`处，之后又从`0x7c00`拷贝到`0x90000`处。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204021712542.png)

#### 跳转至0x90000处对内存分配

接着，一个远跳 跳转至go处，继续执行。

>短跳：可跳至距当前位置128字节内以内的范围（CS不变，(E)IP 变化）
>
>近跳：可跳转至当前段内的任意位置（CS不变，(E)IP 变化）
>
>远跳：可跳转至任意位置（CS变，(E)IP变）

```assembly
	jmp	0x9000:go	
go:	mov	ax,cs
	mov	ds,ax
	mov	es,ax
; put stack at 0x9ff00.
	mov	ss,ax
	mov	sp,0xFF00		; arbitrary value >>512
```

接着阅读下面代码，都是mov操作，将ax的值给ds、es和ss寄存器，而ax等于多少呢？由上一条远跳指令可知，cs寄存器值被更改为0x9000，所以ds、es、ss值均为0x9000。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204022109389.png)

ss为栈段寄存器，后面要配合栈基址寄存器sp来表示此时的栈顶地址。而此时sp寄存器被赋为0xFF00,所以目前栈顶地址就是ss:ip所指向的地址0x9FF00。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204022115634.png)



![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204022146298.png)

#### 将硬盘剩余部分也放到内存中

```assembly
load_setup:
	mov	dx,0x0000		; drive 0, head 0
	mov	cx,0x0002		; sector 2, track 0
	mov	bx,0x0200		; address = 512, in INITSEG
	mov	ax,0x0200+4  	; service 2, nr of sectors
	int	0x13			; read it
	jnc	ok_load_setup	; ok - continue
	mov	dx,0x0000
	mov	ax,0x0000		; reset the diskette
	int	0x13
	jmp	load_setup

ok_load_setup:
	...
```

此处int为中断，`int 0x13`，发起`0x13`号中断。

当中断发生后，CPU会根据中断编号去找对应的中断函数入口地址并跳转过去执行，相当于此处执行了一个函数。而ax、bx、cx、dx作为参数。具体可解释为**从硬盘的第 2 个扇区开始，把数据加载到内存 0x90200 处，共加载 4 个扇区**

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204022205260.png)

这段代码主功能是将从硬盘第6个分区开始往后的240个扇区，加载到`0x10000`处

```assembly
ok_load_setup:
    ...
    mov ax,#0x1000
    mov es,ax       ; segment of 0x10000
    call read_it
    ...
    jmpi 0,0x9020
```

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204022213359.png)

硬盘中数据是怎么分区的呢

通过Makefile和build.c配合完成，其中

- bootsect.s编译成bootsect，放在第1扇区

- setup.s编译成setup，放在2~5扇区

- 将剩下的head.s和其他代码编译成system，放在随后的240个扇区

    ![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204022233895.png)

#### setup修改内存布局

从源码来看，通过i=t 0x10中断将数据从bios中读出，依次写入到以0x90000起始的内存处。然后关闭中断，将从0x10000起始到0x90000结束的数据复制到从0开始到0x80000结束的地方。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204031107523.png)

整理后内存分区如下图

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204031147192.png)

#### 模式转换

那么是如何从实模式（16位）切换到保护模式（32位）的呢？

[LGDT/LIDT](https://www.felixcloutier.com/x86/lgdt:lidt)

LGDT/LIDT 根据操作数的值大小确定LGDT/LIDT 寄存器的结构



> 在16位操作数下：IDTR(Limit) <- SRC[0:15],IDTR(Base) <- SRC[16:47] & 00FFFFFFH;
>
> 在32位操作数下：IDTR(Limit) <- SRC[0:15],IDTR(Base) <- SRC[16:47];
>
> 在64位操作数下：IDTR(Limit) <- SRC[0:15],IDTR(Base) <- SRC[16:79];
>
> 那么IDTR寄存器是多么大的呢？



```assembly
lidt	[idt_48]		; load idt with 0,0
lgdt	[gdt_48]		; load gdt with whatever appropriate
```

`lidt	[idt_48]`汇编指令将 `idt_48` 处的**48**字节加载至 ldtr 寄存器中

`lgdt	[gdt_48]`汇编指令将 `gdt_48` 处的**48**字节加载至 lgtr 寄存器中

```assembly
idt_48:
	dw	0			; idt limit=0
	dw	0,0			; idt base=0L

gdt_48:
    dw	0x800		; gdt limit=2048, 256 GDT entries
    dw	512+gdt,0x9	; gdt base = 0X9xxxx  0x9 << 32 + (512 +gdt(gdt为在此文件中的偏移))
	
```

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204040902532.png)

gdt处便为全局描述符在内存中的位置了，可以看出，一共有三段，第一段为dummy，第二段为代码段描述符（可读可执行），第三段为数据段描述符（可读可写）

```assembly
gdt:
	dw	0,0,0,0		; dummy

	dw	0x07FF		; 8Mb - limit=2047 (2048*4096=8Mb)
	dw	0x0000		; base address=0
	dw	0x9A00		; code read/exec
	dw	0x00C0		; granularity=4096, 386

DATA_DESCRIPTOR:
	dw	0x07FF		; 8Mb - limit=2047 (2048*4096=8Mb)
	dw	0x0000		; base address=0
	dw	0x9200		; data read/write
	dw	0x00C0		; granularity=4096, 386
```

其中一个描述符的格式如下，根据段描述符结构我们可以看出三个段基址均为0

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204040913252.png)

内存中的分布如下，

栈顶地址 0x9ff00 

硬盘的第2-5个扇区在0x90200处，其中gdt和idt放在0x90200开始的某一个地方，地址（0x90200 + gdt/idt偏移）存储在gdtr/idtr寄存器中

0x90000存放的是从bios中读取的临时存放的变量

0x0~0x80000 存放的是操作系统的全部代码

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204040918662.png)

后面**却换到保护模式后，段寄存器（cs,ds,ss）中存储的是段选择子，段选择子去全局描述符中寻找段描述符，从中取出段基址**

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204040934036.png)

```assembly
    mov	al,0xD1		; command write
    out	0x64,al

    mov	al,0xDF		; A20 on
    out	0x60,al
```

这段代码的意思是打开A20地址线，那么问题来了，什么是A20地址线？为什么要开？

A20地址线是为了突破20位地址线的限制，变成32位可用，所以即使地址线有32位了，但是你如果不手动开启，还是会限制20位可用。现在的CPU位数都32位、64位，为了兼容以前的20位地址总线，便有了此选项。



接着往下走，这一堆代码是**对可变成中断控制器8259芯片的编程**。

```assembly
	mov	al,0x11		; initialization sequence
	out	0x20,al		; send it to 8259A-1
	dw	0x00eb,0x00eb		; jmp $+2, jmp $+2
	out	0xA0,al		; and to 8259A-2
	dw	0x00eb,0x00eb
	mov	al,0x20		; start of hardware int's (0x20)
	out	0x21,al
	dw	0x00eb,0x00eb
	mov	al,0x28		; start of hardware int's 2 (0x28)
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0x04		; 8259-1 is master
	out	0x21,al
	dw	0x00eb,0x00eb
	mov	al,0x02		; 8259-2 is slave
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0x01		; 8086 mode for both
	out	0x21,al
	dw	0x00eb,0x00eb
	out	0xA1,al
	dw	0x00eb,0x00eb
	mov	al,0xFF		; mask off all interrupts for now
	out	0x21,al
	dw	0x00eb,0x00eb
	out	0xA1,al
```

在对8259芯片重新编程后，PIC请求号和中断号的对应关系如下：

| PIC 请求号 | 中断号 |     用途     |
| :--------: | :----: | :----------: |
|    IRQ0    |  0x20  |   时钟中断   |
|    IRQ1    |  0x21  |   键盘中断   |
|    IRQ2    |  0x22  |  接连从芯片  |
|    IRQ3    |  0x23  |    串口2     |
|    IRQ4    |  0x24  |    串口1     |
|    IRQ5    |  0x25  |    并口2     |
|    IRQ6    |  0x26  |  软盘驱动器  |
|    IRQ7    |  0x27  |    并口1     |
|    IRQ8    |  0x28  |  实时钟中断  |
|    IRQ9    |  0x29  |     保留     |
|   IRQ10    |  0x2a  |     保留     |
|   IRQ11    |  0x2b  |     保留     |
|   IRQ12    |  0x2c  |   鼠标中断   |
|   IRQ13    |  0x2d  | 数学协处理器 |
|   IRQ14    |  0x2e  |   硬盘中断   |
|   IRQ15    |  0x2f  |     保留     |



```assembly
	mov	ax,0x0001	; protected mode (PE) bit
	lmsw	ax		; This is it;
	jmp	8:0			; jmp offset 0 of segment 8 (cs)
```

前两行，将cr0这个寄存器的位0置1，模式就从是模式切换到保护模式了。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204040953220.png)

继续，后面一个远跳，操作数为**8:0**

在上面两行代码结束后，此时已经是保护模式了，保护模式下寻址方式变了，段寄存器中的值为段选择子，段选择的结构如下![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204040957062.png)

0x8，二进制 1000， 对应着 描述符的索引为 1，也就是去全局描述符gdt中找索引为1的段描述符。但是呢，在前面我们分析过，全局描述符中的有三项，第一项都为0，第二三项段基址都为0，所以段基址为0，偏移也是0，所以这个跳转指令，**就是跳转到内存地址的0地址处**。

0地址处存放的是我们system这个大模块，而system这个模块由head.s、main.c及其余模块的操作系统代码合并来的（如何知道的，查看Makefile中 tools/system 可看到由 head.o和main.o还有其余模块组成）。

#### 重新设置ldt/gdt

接着就开始研究head.s了。此处汇编风格变为AT&T

```assembly
_pg_dir:
.globl startup_32
startup_32:
	movl $0x10,%eax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%fs
	mov %ax,%gs
	lss _stack_start,%esp
```

此处注意`_pg_dir`,这一段代码的意思是先给eax赋值0x10,借助eax配置ds、es、fs、gs值为0x10，根据段描述符结构解析，表示这几个段寄存器的值为指向全局描述符表中的第二个段描述符，也就是数据段描述符

最后lss命令相当于ss:esp 这个栈顶指针指向了\_stack_start这个标号的位置。（之前是0x9ff00，现在要换到\_stack_start）

stack_start这个标号在sched.c中，（关于为什么是start_start 而不是\_stack_start这个是因为cdecl调用规约中第4条:编译后的函数名前缀以一个下划线字符开始）

接着往下走

```assembly
	call _setup_idt
	call _setup_gdt
	movl $0x10,%eax		# reload all the segment registers
	mov %ax,%ds		# after changing gdt. CS was already
	mov %ax,%es		# reloaded in 'setup_gdt'
	mov %ax,%fs
	mov %ax,%gs
	lss _stack_start,%esp
```

前两行是调用设置idt和gdt，下面的代码跟上面是一致的，为什么又要再来一遍呢？因为上面修改了gdt，所以需要重新配置。调用查看\_setup_gdt发现最后代码设置与我们在setup.asm中设置的是一样的？为什么要重新设置呢？因为原来的位置之后要被冲掉

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204041145317.png)

```assembly
_setup_idt:
	lea ignore_int,%edx
	movl $0x00080000,%eax
	movw %dx,%ax		/* selector = 0x0008 = cs */
	movw $0x8E00,%dx	/* interrupt gate - dpl=0, present */

	lea _idt,%edi
	mov $256,%ecx
rp_sidt:
	movl %eax,(%edi)
	movl %edx,4(%edi)
	addl $8,%edi
	dec %ecx
	jne rp_sidt
	lidt idt_descr
	ret
	
idt_descr:
	.word 256*8-1		# idt contains 256 entries
	.long _idt
	
_idt:	.fill 256,8,0		# idt is uninitialized
```

中断描述符表 idt 里面存储着一个个中断描述符，每一个中断号就对应着一个中断描述符，而中断描述符里面存储着主要是中断程序的地址，这样一个中断号过来后，CPU 就会自动寻找相应的中断程序，然后去执行它。

那这段程序的作用就是，**设置了 256 个中断描述符**，并且让每一个中断描述符中的中断程序例程都指向一个 **ignore_int** 的函数地址，这个是个**默认的中断处理程序**，之后会逐渐被各个具体的中断程序所覆盖。比如之后键盘模块会将自己的键盘中断处理程序，覆盖过去。

那现在，产生任何中断都会指向这个默认的函数 ignore_int。

#### 分页

配置完idt和gdt后，接着继续往下走，跳转到`after_page_tables`后，先是几个`push`，其中包含了c语言的世界的地址，然后一个跳转到`setup_paging`，给`ecx`分配大小为5\*1024（5pages）,然后将eax清零，edi清零。接着将al中的数据（0）填充到edi起始的位置（0）处，方向为正向，大小为5\*1024\*4。（也就是说 **从零地址开始前20k内存清零**）

> cld;rep;stosl
> cld设置edi或同esi为递增方向，rep做(%ecx)次重复操作，stosl表示edi每次增加4,这条语句达到按4字节清空前5\*1024\*4字节地址空间的目的。

```assembly
	jmp after_page_tables
after_page_tables:
	pushl $0		# These are the parameters to main :-)
	pushl $0
	pushl $0
	pushl $L6		# return address for main, if it decides to.
	pushl $_start
	jmp setup_paging
L6:
	jmp L6			# main should never return here, but
				# just in case, we know what happens.
				
setup_paging:
	movl $1024*5,%ecx		/* 5 pages - pg_dir+4 page tables */
	xorl %eax,%eax
	xorl %edi,%edi			/* pg_dir is at 0x000 */
	cld;rep;stosl
	movl $pg0+7,_pg_dir		/* set present bit/user r/w */
	movl $pg1+7,_pg_dir+4		/*  --------- " " --------- */
	movl $pg2+7,_pg_dir+8		/*  --------- " " --------- */
	movl $pg3+7,_pg_dir+12		/*  --------- " " --------- */
	movl $pg3+4092,%edi
	movl $0xfff007,%eax		/*  16Mb - 4096 + 7 (r/w user,p) */
	std
1:	stosl			/* fill pages backwards - more efficient :-) */
	subl $0x1000,%eax
	jge 1b
	xorl %eax,%eax		/* pg_dir is at 0x0000 */
	movl %eax,%cr3		/* cr3 - page directory start */
	movl %cr0,%eax
	orl $0x80000000,%eax
	movl %eax,%cr0		/* set paging (PG) bit */
	ret			/* this also flushes prefetch-queue */

```

接着了解一下分页，在保护模式下开启分段机制后，在代码中给出一个内存地址，在保护模式下要先经过分段机制的转换，才能得到最终的物理地址。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204061044176.png)

这个是没有开启分页机制的情况下，开启分页后又会**多一步转换**

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204061044464.png)

分段机制将逻辑地址转变为线性地址

分页机制在分段机制的基础上将线性地址转为物理地址

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204041906123.png)





## 参考

1. [linux0.11完全注释](https://github.com/beride/linux0.11-1)