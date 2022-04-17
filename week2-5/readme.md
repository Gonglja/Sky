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

#### 系统上电后跳转至bios

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

#### 实模式转到保护模式（分段）

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204041906123.png)

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

#### 分页机制

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

分段机制将**逻辑地址**转变**为线性地址**

分页机制在分段机制的基础上将**线性地址转为物理地址**

分页机制将一个32位线性地址分为三部分：

 10位 ： 10 位 ： 12 位，分别为页目录表：页表：页内偏移。

通过高10位去页目录表中找出索引对应的页目录项，在该目录项内 中10位找出索引对应的页表项，其对应的值在加上页内偏移就是实际的物理地址。

这一切的操作由一个计算机硬件MMU（Memory Management Unit，内存管理单元）将线性地址（虚拟地址）转换为物理地址

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204061938387.png)

这个页表方案叫二级页表，第一级叫**页目录表 PDE**，第二级叫**页表 PTE**，结构如下

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204062005230.png)

然后将CR0寄存器的PG（31位）置1，即可开启分页机制，之后MMU就可以帮我们进行分页的转换了。

此后指令中的内存地址，就先要经过分段机制的转换，在经过分页机制的转换，最终变成物理地址。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204062031578.png)

```assembly
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

前面我们了解到前4行代码是**从0开始，将前 1024\*5\*4 字节空间清零**

接着往下走，四个movl指令将**\$pg0+7**这个地址给到\_pg\_dir（0地址处），后面依次将pg1、pg2、pg3地址给\_pg\_dir + 4、8、12处，构建页目录表。

而pg0、1、2、3分别为0x1000、0x2000、0x3000、0x4000

```assembly
.org 0x1000
pg0:

.org 0x2000
pg1:

.org 0x3000
pg2:

.org 0x4000
pg3:

.org 0x5000
```

所以页目录表中存储的数据也就为0x1007、0x2007、0x3007、0x3007，对应页表地址为1、2、3、4（0x1007 >> 12）

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204070903895.png)

接着往下走 给edi赋值pg3+4092 也就是0x4ffc，为什么是这个？没搞清楚

给eax赋值 0xfff007，对应的也就是最大4096个4k，也就是16M内存，然后一个std;stosl命令表示以edi为起始位置 0x4ffc，每次减小4字节，将对应的4k地址写入到页表中。然后eax减掉一个4k，jge大于等于转移，然后跳转到执行stosl，这样就将16M内的4k空间地址写入到页表中。

```assembly
	xorl %eax,%eax		/* pg_dir is at 0x0000 */
	movl %eax,%cr3		/* cr3 - page directory start */
	movl %cr0,%eax
	orl $0x80000000,%eax
	movl %eax,%cr0		/* set paging (PG) bit */
	ret			/* this also flushes prefetch-queue */
```

先给eax清0，然后设置cr3，设置页目录表地址。

接着就是将cr0的第31位置1，写回cr0，开启分页机制。

#### 跳转到c语言中

head.s中还有最后一点代码，我们接着分析。

```assembly
after_page_tables:
	pushl $0		# These are the parameters to main :-)
	pushl $0
	pushl $0
	pushl $L6		# return address for main, if it decides to.
	pushl $_start
	jmp setup_paging
...
setup_paging:
    ...
    ret
```

在after_page_tables 中连着5个push，将数据依次压入栈，最后的结构如下

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204070938950.png)

注意setup_paging的最后一条命令是ret，ret被叫做返回指令，返回指令的话肯定得有返回的地址，计算机会机械的把栈顶的元素当作返回地址。在具体的说，就是将esp寄存器的值给到eip中，而cs:eip就是CPU要执行的下一条指令的地址。而栈顶此时存放的为main(start)函数的地址，所以ret后就会跳转到main(start)中了。其中**L6会作为main的返回值**，但main(start)是不会返回的，其它**三个值本意是作为main(start)函数的参数**，但没有用到。

到此，汇编部分就结束了。主要有如下操作，

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071044648.png)

整个内存分布如下：![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071045115.png)

#### 进入c语言的世界

进入c语言后，先看一看start函数主要干了什么。

主要有四部分 

1. 参数的取值和计算
2. 各种初始化
3. 切换到用户态模式
4. 死循环，如果没有任何任务运行，程序会一直陷入此死循环

```c
void start(void)
{
 	ROOT_DEV = 0x301;
 	drive_info = DRIVE_INFO;
	memory_end = (1<<20) + (EXT_MEM_K<<10);
	memory_end &= 0xfffff000;
	if (memory_end > 16*1024*1024)
		memory_end = 16*1024*1024;
	if (memory_end > 12*1024*1024) 
		buffer_memory_end = 4*1024*1024;
	else if (memory_end > 6*1024*1024)
		buffer_memory_end = 2*1024*1024;
	else
		buffer_memory_end = 1*1024*1024;
	main_memory_start = buffer_memory_end;
#ifdef RAMDISK
	main_memory_start += rd_init(main_memory_start, RAMDISK*1024);
#endif
	mem_init(main_memory_start,memory_end);
	trap_init();
	blk_dev_init();
	chr_dev_init();
	tty_init();
	time_init();
	sched_init();
	buffer_init(buffer_memory_end);
	hd_init();
	floppy_init();
	sti();
	move_to_user_mode();
	if (!fork()) {
		init();
	}
	for(;;) pause();
}
```

#### 参数的取值和计算

看一下第一段代码

```c
void start(void)
{
 	...
	memory_end = (1<<20) + (EXT_MEM_K<<10);
	memory_end &= 0xfffff000;
	if (memory_end > 16*1024*1024)
		memory_end = 16*1024*1024;
	if (memory_end > 12*1024*1024) 
		buffer_memory_end = 4*1024*1024;
	else if (memory_end > 6*1024*1024)
		buffer_memory_end = 2*1024*1024;
	else
		buffer_memory_end = 1*1024*1024;
	main_memory_start = buffer_memory_end;
#ifdef RAMDISK
	main_memory_start += rd_init(main_memory_start, RAMDISK*1024);
#endif
	...
}
```

仔细看这一坨代码比较乱，但是他只是用来计算三个变量

**memory_end**

**buffer_memory_end**

**main_memory_start**

在仔细看 在最后一行，main_memory_start = buffer_memory_end;，其实就是计算两个变量**memory_end、main_memory_start**。这段代码的意思是针对不同的内存大小，设置不同的边界。

比如内存为8M，则memory_end 就是8\*1024\*1024，buffer_memory_end就是2\*1024\*1024，main_memory_start 就是2\*1024\*1024

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071110037.png)

剩下的要看管理和分配的函数了。

用来分配主内存

```c
void main(void) {
    ...
    mem_init(main_memory_start, memory_end);
    ...
}
```

用来分配和管理缓冲区

```c
void main(void) {
    ...
    buffer_init(buffer_memory_end);
    ...
}
```

#### mem_init

```c
#define LOW_MEM 0x100000
#define PAGING_MEMORY (15*1024*1024)
// 右移12位，也即4k为一个单位
#define PAGING_PAGES (PAGING_MEMORY>>12) 
#define MAP_NR(addr) (((addr)-LOW_MEM)>>12)
#define USED 100

static long HIGH_MEMORY = 0;
static unsigned char mem_map[PAGING_PAGES] = { 0, };

// start_mem = 2 * 1024 * 1024
// end_mem = 8 * 1024 * 1024
void mem_init(long start_mem, long end_mem)
{
	int i;

	HIGH_MEMORY = end_mem;
	for (i=0 ; i<PAGING_PAGES ; i++)// 0~3840:USED
		mem_map[i] = USED;
	i = MAP_NR(start_mem);// 0x100000>>12 = 512
	end_mem -= start_mem; // 6*1024*1024
	end_mem >>= 12;		  // 1536
	while (end_mem-->0)	  // 512~1536:0
		mem_map[i++]=0;
}
```

其实折腾来折腾去，就是给一个mem_map数组的各个位置上赋值USED，表示内存被使用，剩下还有一部分赋为0，表示内存未被使用。**通过使用一个表，记录哪些内存被使用，哪些内存未被使用。**

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071324217.png)

> 1M 以下的内存这个数组干脆没有记录，这里的内存是无需管理的，或者换个说法是无权管理的，也就是没有权利申请和释放，因为这个区域是内核代码所在的地方，不能被“污染”。
>
> 1M 到 2M 这个区间是**缓冲区**，2M 是缓冲区的末端，缓冲区的开始在哪里之后再说，这些地方不是主内存区域，因此直接标记为 USED，产生的效果就是无法再被分配了。
>
> 2M 以上的空间是**主内存区域**，而主内存目前没有任何程序申请，所以初始化时统统都是零，未来等着应用程序去申请和释放这里的内存资源。

#### trap_init

```c
void trap_init(void)
{
	int i;

	set_trap_gate(0,&divide_error);
	set_trap_gate(1,&debug);
	set_trap_gate(2,&nmi);
	set_system_gate(3,&int3);	/* int3-5 can be called from all */
	set_system_gate(4,&overflow);
	set_system_gate(5,&bounds);
	set_trap_gate(6,&invalid_op);
	set_trap_gate(7,&device_not_available);
	set_trap_gate(8,&double_fault);
	set_trap_gate(9,&coprocessor_segment_overrun);
	set_trap_gate(10,&invalid_TSS);
	set_trap_gate(11,&segment_not_present);
	set_trap_gate(12,&stack_segment);
	set_trap_gate(13,&general_protection);
	set_trap_gate(14,&page_fault);
	set_trap_gate(15,&reserved);
	set_trap_gate(16,&coprocessor_error);
	for (i=17;i<48;i++)
		set_trap_gate(i,&reserved);
	set_trap_gate(45,&irq13);
	outb_p(inb_p(0x21)&0xfb,0x21);
	outb(inb_p(0xA1)&0xdf,0xA1);
	set_trap_gate(39,&parallel_interrupt);
}
```

上来直接看代码，说简单也简单，都是对set_trap_gate、set_system_gate的调用，我们只要弄清楚这个就可以了。又是内嵌汇编

```c
#define _set_gate(gate_addr,type,dpl,addr) \
__asm__ ("movw %%dx,%%ax\n\t" \
	"movw %0,%%dx\n\t" \
	"movl %%eax,%1\n\t" \
	"movl %%edx,%2" \
	: \
	: "i" ((short) (0x8000+(dpl<<13)+(type<<8))), \
	"o" (*((char *) (gate_addr))), \
	"o" (*(4+(char *) (gate_addr))), \
	"d" ((char *) (addr)),"a" (0x00080000))

#define set_intr_gate(n,addr) \
	_set_gate(&idt[n],14,0,addr)

#define set_trap_gate(n,addr) \
	_set_gate(&idt[n],15,0,addr)

#define set_system_gate(n,addr) \
	_set_gate(&idt[n],15,3,addr)
```

\_set\_gate的一个参数为中断号，第二参数为配置8~11位 14用二进制表示1110b，对应的是中断门；15 1111b，对应的是陷阱门；第三个参数为特权级别；第四个参数为调用函数的地址。

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071419572.png)

也就是说，当配置好中断号和中断函数后，当中断到来的时候，CPU就会根据中断号在idt中找到对应的中断处理函数。

设置0号中断，对应的中断处理是divide_error

`set_trap_gate(0,&divide_error);`

等CPU执行了一条除零指令的时候，会从硬件层面发起一个0号异常中断，然后执行由我们操作系统定义的divide_error除法异常处理程序，执行完之后返回。

> TIPS：这个 system 与 trap 的区别仅仅在于，设置的中断描述符的特权级不同，前者是 0（内核态），后者是 3（用户态），这块展开将会是非常严谨的、绕口的、复杂的特权级相关的知识，不明白的话先不用管，就理解为都是设置一个中断号和中断处理程序的对应关系就好了。

整段代码执行下来，内存中的idt位置就会变成这个样子![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071441072.png)



接着我们看一下键盘是什么时候生效的？键盘对应的中断号是0x21,此时这个中断号对应的还是一个临时中断处理函数&reserved()。

我们接着往下看，在main主函数中有一个`tty_init()`，其中调用`con_init()`，`con_init()` 中`set_trap_gate(0x21,&keyboard_interrupt);`，而这一个正是配置0x21号对应的中断处理函数为`&keyboard_interrupt`，但是在此处配置结束后，中断还不会生效。需要main.c中执行完sti() 表示允许中断，允许中断后，中断才真正生效。

```c
void main(){
    ...
	trap_init();
    ...
	tty_init();
    ...
    sti();
    ...
}

void tty_init(void)
{
	rs_init();
	con_init();
}

void con_init(void)
{
    ...
    set_trap_gate(0x21,&keyboard_interrupt);
    ...
}
```

#### blk_dev_init

看了这初始化代码直接懵逼，这么简单，什么意思嘛？就是将数组request[i]的结构体中的dev、next分别初始化为-1、NULL。

```c
void blk_dev_init(void)
{
	int i;

	for (i=0 ; i<32 ; i++) {
		request[i].dev = -1;
		request[i].next = NULL;
	}
}
```

接着我们了解一下request的这个结构

```c
struct request {
	int dev;					//dev 表示设备号，-1 就表示空闲。
	int cmd;					//cmd 表示命令，其实就是 READ 还是 WRITE，也就表示本次操作是读还是写。
	int errors;					//errors 表示操作时产生的错误次数。
	unsigned long sector;		//sector 表示起始扇区。
	unsigned long nr_sectors;	//nr_sectors 表示扇区数。
	char * buffer;				//buffer 表示数据缓冲区，也就是读盘之后的数据放在内存中的什么位置。
	struct task_struct * waiting;//waiting 是个 task_struct 结构，这可以表示一个进程，也就表示是哪个进程发起了这个请求
	struct buffer_head * bh;	//bh 是缓冲区头指针，这个后面讲完缓冲区就懂了，因为这个 request 是需要与缓冲区挂钩的。
	struct request * next;		//next 指向了下一个请求项。
};
```

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071517774.png)

初始化这部分就完事了，分析sys_readchar

#### chr_dev_init

空

#### tty_init

```c
void main(){
    ...
	tty_init();
    ...
}

void tty_init(void)
{
	rs_init();
	con_init();
}

void rs_init(void)
{
	set_intr_gate(0x24,rs1_interrupt);// 设置串行口1的中断门向量（IRQ4信号）
	set_intr_gate(0x23,rs2_interrupt);// 设置串行口2的中断门向量（IRQ3信号）
	init(tty_table[1].read_q.data);	  // 初始化串行口1（.data是端口基地址）
	init(tty_table[2].read_q.data);	  // 初始化串行口2
	outb(inb_p(0x21)&0xE7,0x21);	  // 允许8295A相应IRQ3、IRQ4中断请求
}
```

rs_init 在初始化函数中，设置了默认的串行通信参数，并设置串行端口的中断陷阱门。这部分不继续往下分析了。

接着看con_init，代码非常多，先写出大体框架

```c
void con_init(void) {
    ...
    if (ORIG_VIDEO_MODE == 7) {
        ...
        if ((ORIG_VIDEO_EGA_BX & 0xff) != 0x10) {...}
        else {...}
    } else {
        ...
        if ((ORIG_VIDEO_EGA_BX & 0xff) != 0x10) {...}
        else {...}
    }
    ...
}
```

可以看出，有非常多的if else，其实是为了应对不同的显示模式，来分配不同的值，我们找出其中一个来阅读。

[显示模式](https://www.cnblogs.com/mlzrq/p/10223020.html)有两种，文本模式和图形模式

计算机加电之后，会将显示初始化为80x25的文本模式，文本模式下只能显示字符无法显示图形。

文本模式下显示字符有两种

- 直接修改显存数据的方式来显示字符
- 通过BIOS中断来显示字符

第一种比较方便，直接修改内存处的数据即可，我们直接使用这一种。显存地址在哪呢？0xB8000 - 0xBFFFF 共32K，其中每完整的一个字符有2字节组成，第一个字节是数据，第二个字节为颜色，第二字节高四位对应的为背景色，低四位对应前景色。

![image-20220407180350476](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071803898.png)

![](https://cdn.jsdelivr.net/gh/Gonglja/imgur/img/202204071753114.png)

填写数据到显存区域，第二个display_ptr++ 为跳过颜色设置，使用默认设置。

```c
display_ptr = ((char *)video_mem_start) + video_size_row - 8;
while (*display_desc)
{
	*display_ptr++ = *display_desc++;
	display_ptr++;
} 
```

还有就是我们知道了每行可显示的长度，那么就可以通过x,y,pos三个值去指定位置写数据。

x 表示光标在哪一列

y 表示光标在哪一行

pos 根据行列计算出来的内存指针，也就是可以直接往这个pos地址写数据

```c
gotoxy(ORIG_X,ORIG_Y);

static inline void gotoxy(unsigned int new_x,unsigned int new_y)
{
	if (new_x > video_num_columns || new_y >= video_num_lines)
		return;
	x=new_x;
	y=new_y;
	pos=origin + y*video_size_row + (x<<1);
}
```







#### time_init

我们接着查看time_init ，看看系统是怎么获取时间的。

```c
void main(){
    ...
	time_init();
    ...
}
```

```c
#define CMOS_READ(addr) ({ \
outb_p(0x80|addr,0x70); \
inb_p(0x71); \
})

#define BCD_TO_BIN(val) ((val)=((val)&15) + ((val)>>4)*10)

static void time_init(void)
{
	struct tm time;

	do {
		time.tm_sec = CMOS_READ(0);
		time.tm_min = CMOS_READ(2);
		time.tm_hour = CMOS_READ(4);
		time.tm_mday = CMOS_READ(7);
		time.tm_mon = CMOS_READ(8);
		time.tm_year = CMOS_READ(9);
	} while (time.tm_sec != CMOS_READ(0));
	BCD_TO_BIN(time.tm_sec);
	BCD_TO_BIN(time.tm_min);
	BCD_TO_BIN(time.tm_hour);
	BCD_TO_BIN(time.tm_mday);
	BCD_TO_BIN(time.tm_mon);
	BCD_TO_BIN(time.tm_year);
	time.tm_mon--;
	startup_time = kernel_mktime(&time);
}
```

通过代码可以看到，最终调用都是CMOS_READ，通过读取不同的端口获取不同的数据，然后在BCD码转换为二进制。

#### sched_init



#### buffer_init



#### hd_init



#### floppy_init



#### move_to_user_mode



#### fork



#### init



## 参考

1. [linux0.11完全注释](https://github.com/beride/linux0.11-1)
1. [闪客新系列！你管这破玩意叫操作系统](https://mp.weixin.qq.com/s?__biz=Mzk0MjE3NDE0Ng==&mid=2247499207&idx=1&sn=f00bf7653ae57faa6266bfd18287e6bb&chksm=c2c5876af5b20e7cdf5094696d266ee3fa09514601b021ce602ecaf0ec79857045b43e286a58&scene=178&cur_album_id=2123743679373688834#rd)
1. linux内核完全注释v3.0书签版