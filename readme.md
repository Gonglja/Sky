这里将定期记录着[Gonglja](https://github.com/Gonglja) 在学习过程中的一些笔记

### 第1周（2022.3.21-2022.3.27）

- 主要任务：[研究 hurlex](./week1/readme.md) 

- 后续安排，研究 一个64位操作系统的设计与实现(未看完)

    

### 第2周-第6周（2022.3.28 - 2022.5.1）

- [x] 这段时间在研究 u-boot，代码分析的差不多了，后面根据具体情况具体分析。链接如下：[u-boot-2014.04源码分析](https://gonglja.github.io/posts/f88e6d17/) 



### 第6周-第10周（2022.4.25 - 2022.5.29）

- [x] [准备软考](https://www.zhixi.com/view/4f83310b)
  
    - 终于完事了，~~选择题一些准备的没考上，大题考上的没准备，过应该问题不大~~
    
      ![](https://note-1251905184.cos.ap-shanghai.myqcloud.com/img/202207240034994.png)
    
- [x] 成功从 vmware 大户迁移到 docker 了，如何使用，[查看](https://gonglja.github.io/posts/6c58185/)



### 第11周（2022.5.30 - 2022.6.5）

- [x] 要开始忙 imx8 相关的 bsp 构建了（[yocto使用笔记](https://note.youdao.com/s/9agRyOgp)）

    

### 第12-19周（2022.6.6 - 2022.7.31）

- [x] 研究 linux0.11 内核，输出笔记([linux0.11 内核研究](./week2-5/readme.md))，准备[重新写一个](https://gonglja.github.io/posts/ca3a0e2a/)，前面大部分借鉴**[闪客](https://github.com/sunym1993)**的博文，感谢闪客大佬	

    - [x] 完成了汇编部分

近期有点忙，进度严重滞后。

这两周的算法进度也是滞后。

另外跟硬件同事搞了一个[双路 100w+18w 桌面电源](https://github.com/Gonglja/yds-charger)，[原方案](https://github.com/liaozhelin/yds-charger)，预计7月底出来，100w芯片读写已完成，硬件工程师设计中...



### 第20-21周（2022.8.1 - 2022.8.14）



- [x] 基于`STM32F042`的高频`RFID`标签读卡器

  - [x] 支持主动上传、查询模式
  - [x] 支持修改地址
  - [x] 修改通信频率
  - [x] 支持PC上位机配置

  

另外主力虚拟机又从`ubuntu2204`切回了`archlinux`，ubuntu 依赖问题是真的操蛋，直接把虚拟机给干崩了，还好有如下救援方法:

- [VM虚拟机挂了不能启动，想提取里面的文件怎么办？](https://blog.csdn.net/qq_33475105/article/details/109282420)

- [如何打开VMware的vmdk虚拟磁盘文件](https://blog.csdn.net/u013401853/article/details/53088974)

总结一下：**Windows下，可以使用`Diskgenius`中的 `打开虚拟硬盘文件`直接打开虚拟机硬盘，此时可将数据拷出，但需注意软链、文件格式问题；**

**Linux 下，使用另外一个可进入系统的 Linux 虚拟机，在 Vmware 中添加已存在的硬盘，在 Linux 中使用 mount 命令挂载，之后就可以拷贝数据了，推荐使用这种方法。**



### 第22-32周（2022.8.15 - 2022.10.30）

- [ ] 调试 `EBAZ4205` zynq 开发板的 PS(Processor System)侧 `u-boot-linx`、`kernel-linx`、`petalinux`，完成最小系统启动，基础外围器件驱动调试
  - [ ] boot 启动过程
  - [ ] vivado 使用
  - [ ] u-boot 移植
  - [ ] kernel 移植
  - [ ] 最小系统启动
  - [ ] 基础外围器件调试
  - [ ] etc.

- [ ] zynq 上一个复杂应用的开发

- [ ] zynq 中 PS 与 PL的通信

  

### 持续性任务

暂时又没有时间了....

- [ ] 研究 linux0.11 内核，输出笔记([linux0.11 内核研究](./week2-5/readme.md))

  - [ ] 其他部分

- [ ] s5pv210 芯片 smart210 板卡

  - [ ] Arm Linux 驱动开发学习

    仓库：[内核](https://github.com/Gonglja/linux)、[驱动](https://github.com/Gonglja/linux-driver)、[驱动进度](https://github.com/Gonglja/linux-driver/tree/master/01_char/README.md)

  - [ ] subsystem 学习
    - [ ] gpio 子系统
    - [ ] pinctrl 子系统
    - [ ] usb 子系统
    - [ ] etc.





### 后续要完成的

- [ ] 下半年（**11.5 ~ 6**）系统架构师考试，历年报名时间 **8.25 ~ 9.05**
  - [ ] 报名，[报名地址](https://bm.ruankao.org.cn/sign/welcome) , 湖北省还没出, 其他省份陆陆续续已经出来了, 近期要多关注下
  - [ ] 准备考试

- [ ] STL 源码阅读（侯捷STL剖析）
- [ ] 刷算法（labuladong的算法小抄）
