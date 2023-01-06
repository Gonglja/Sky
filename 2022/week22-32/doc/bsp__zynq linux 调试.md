# Zynq Linux 调试

## 环境搭建

Archlinux + Docker + ubuntu 16.04

下载三件套 [kernel-xlnx](https://github.com/Xilinx/linux-xlnx/archive/refs/tags/xilinx-v2018.3.zip)+ [u-boot-xlnx](https://github.com/Xilinx/u-boot-xlnx/archive/refs/tags/xilinx-v2018.3.zip) + `petalinux`（也可以直接在此下 https://www.aliyundrive.com/s/6M8gVUaGm5g 提取码：XYVK）。

> 注意：三件套最好选择同一版本，不同版本不要交叉使用，这里统一采用 v2018.3版本。
>
> 另外，v2019.1之后的petalinux版本不带交叉编译器，只能选择安装 Vivado 进行编译。



### 安装 petalinux 依赖

```shell
sudo apt-get install -y tofrodos iproute2 gawk gcc g++ git make net-tools libncurses5-dev \
	tftpd libssl-dev flex bison libselinux1 gnupg wget diffstat chrpath socat \
	xterm autoconf libtool tar unzip texinfo zlib1g-dev gcc-multilib build-essential \
	libsdl1.2-dev libglib2.0-dev screen pax gzip automake u-boot-tools cpio
```



如果报错，最后安装 `zlib1g:i386`

```shell
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y zlib1g:i386
```



### 安装 petalinux


创建非root用户

```shell
# 添加用户名为u的用户，接着继续配置密码，按两次确定，更多信息默认
adduser u
```

赋予新创建用户root权限
```shell

apt install vim sudo 
sudo vim /etc/sudoers
# 在root用户下新增一行
root    ALL=(ALL:ALL) ALL
u       ALL=(ALL:ALL) ALL

# 按 wq! 退出
```

```shell
chmod  +x *.run
# 注意 *.run 后跟安装路径，为空则默认当前路径，不支持root运行，不支持安装到系统目录，比如/opt
# 一般情况下 都会将工具类安装到 /opt 下，我们可以将/opt 更改为当前用户所属，那么就可以安装在此了。
# 最后还是安装到当前目录下了，因为在docker中安装东西是占用在系统中的，而我系统本身空间分配较小
# sudo chown -R $USER:$USER /opt 
mkdir  petalinux-v2018.3
./petalinux-v2018.3-final-installer.run  ./petalinux-v2018.3
```

嗯，装着装着，报错了, 按照指示，打开文件看一下

```shell
u@7aa1d34a1fe6:/home/data/os/zynq$ ./petalinux-v2018.3-final-installer.run ./petalinux-v2018.3
INFO: Checking installation environment requirements...
Usage: grep [OPTION]... PATTERN [FILE]...
Try 'grep --help' for more information.
WARNING: This is not a supported OS
INFO: Checking free disk space
INFO: Checking installed tools
INFO: Checking installed development libraries
INFO: Checking network and other services
WARNING: No tftp server found - please refer to "PetaLinux SDK Installation Guide" for its impact and solution
INFO: Checking installer checksum...
INFO: Extracting PetaLinux installer...




LICENSE AGREEMENTS

PetaLinux SDK contains software from a number of sources.  Please review
the following licenses and indicate your acceptance of each to continue.

You do not have to accept the licenses, however if you do not then you may 
not use PetaLinux SDK.

Use PgUp/PgDn to navigate the license viewer, and press 'q' to close

Press Enter to display the license agreementsDo you accept Xilinx End User License Agreement? [y/N] > y
Do you accept Webtalk Terms and Conditions? [y/N] > y
Do you accept Third Party End User License Agreement? [y/N] > y
INFO: Installing PetaLinux...
INFO: Checking PetaLinux installer integrity...
INFO: Installing PetaLinux SDK to "./petalinux-v2018.3/."
INFO: Installing aarch64 Yocto SDK to "./petalinux-v2018.3/./components/yocto/source/aarch64"...
*********************************************
ERROR: Failed to install Yocto SDK for aarch64.
*********************************************

Please refer to the PetaLinux Tools Installation Guide.

Check the troubleshooting guide at the end of that manual, and if you are
unable to resolve the issue please contact customer support with file:
   /home/data/os/zynq/petalinux_installation_log

```

发现是缺少语言包, 缺少语言环境, 直接命令安装 `sudo apt install language-pack-en`

```shell
u@7aa1d34a1fe6:/home/data/os/zynq$ vim /home/data/os/zynq/petalinux_installation_log


INFO: Checking installation environment requirements...
INFO: Checking installer checksum...
INFO: Extracting PetaLinux installer...
INFO: Installing PetaLinux...
INFO: Checking PetaLinux installer integrity...
INFO: Installing PetaLinux SDK to "./petalinux-v2018.3/."
.......................................................................................................................................................................................................................................................................INFO: Installing aarch64 Yocto SDK to "./petalinux-v2018.3/./components/yocto/source/aarch64"...
PetaLinux Extensible SDK installer version 2018.3
=================================================
locale: Cannot set LC_CTYPE to default locale: No such file or directory
locale: Cannot set LC_MESSAGES to default locale: No such file or directory
locale: Cannot set LC_COLLATE to default locale: No such file or directory
ERROR: the installer requires the en_US.UTF-8 locale to be installed (but not selected), please install it first
*********************************************
ERROR: Failed to install Yocto SDK for aarch64.
*********************************************
Please refer to the PetaLinux Tools Installation Guide.

Check the troubleshooting guide at the end of that manual, and if you are
unable to resolve the issue please contact customer support with file:
   /home/data/os/zynq/petalinux_installation_log

```

安装完语言包重新执行安装 petalinux 的命令。

安装日志如下：

```shell
u@7aa1d34a1fe6:/home/data/os/zynq$ ./petalinux-v2018.3-final-installer.run ./petalinux-v2018.3
INFO: Checking installation environment requirements...
Usage: grep [OPTION]... PATTERN [FILE]...
Try 'grep --help' for more information.
WARNING: This is not a supported OS
INFO: Checking free disk space
INFO: Checking installed tools
INFO: Checking installed development libraries
INFO: Checking network and other services
WARNING: No tftp server found - please refer to "PetaLinux SDK Installation Guide" for its impact and solution
INFO: Checking installer checksum...
INFO: Extracting PetaLinux installer...

LICENSE AGREEMENTS

PetaLinux SDK contains software from a number of sources.  Please review
the following licenses and indicate your acceptance of each to continue.

You do not have to accept the licenses, however if you do not then you may 
not use PetaLinux SDK.

Use PgUp/PgDn to navigate the license viewer, and press 'q' to close

Press Enter to display the license agreements  
Do you accept Xilinx End User License Agreement? [y/N] > y
Do you accept Webtalk Terms and Conditions? [y/N] > y
Do you accept Third Party End User License Agreement? [y/N] > y
INFO: Installing PetaLinux...
*********************************************
WARNING: PetaLinux installation directory: ./petalinux-v2018.3/. is not empty!
*********************************************
Please input "y" to continue to install PetaLinux in that directory?[n]y
INFO: Checking PetaLinux installer integrity...
INFO: Installing PetaLinux SDK to "./petalinux-v2018.3/."
INFO: Installing aarch64 Yocto SDK to "./petalinux-v2018.3/./components/yocto/source/aarch64"...
INFO: Installing arm Yocto SDK to "./petalinux-v2018.3/./components/yocto/source/arm"...
INFO: Installing microblaze_full Yocto SDK to "./petalinux-v2018.3/./components/yocto/source/microblaze_full"...
INFO: Installing microblaze_lite Yocto SDK to "./petalinux-v2018.3/./components/yocto/source/microblaze_lite"...
INFO: PetaLinux SDK has been installed to ./petalinux-v2018.3/.

```

## 构建

zynq 上可以跑系统，也可以跑裸机，以下是跑裸机与 Linux 系统的图，其中 `BOOT.bin` 由 `fsbl.elf` 、`pl.bit[optional]`、`app.elf`组成

![](https://note-1251905184.cos.ap-shanghai.myqcloud.com/img/202208172053729.png)



###  petalinux 构建



设计流程简介

| 设计流程步骤                          | 工具/工作流程                         |
| ------------------------------------- | ------------------------------------- |
| 硬件平台创建(仅用于定制硬件)          | Vivado设计工具                        |
| 创建 Petalinux 工程                   | petalinux-create -t project           |
| 初始化 Petalinux 工程(仅用于定制硬件) | petalinux-config --get-hw-description |
| 设置系统级选项                        | petalinux-config                      |
| 创建用户组件                          | petalinux-create -t COMPONENT         |
| 设置linux 内核                        | petalinux-config -c kernel            |
| 设置根文件系统                        | petalinux-config -c rootfs            |
| 构建系统                              | petalinux-build                       |
| 部署系统的封装                        | petalinux-package                     |
| 启动系统并测试                        | petalinux-boot                        |



在构建之前导入环境变量

```shell
source ../petalinux-v2018.3/settings.sh
```



#### 创建工程

通过命令 petalinux-create 创建一个 zynq 工程

```shell
petalinux-create -t project -s xilinx-zc702-v2018.3-final.bsp -n xilinx-zc702-22.08.22
```

- -t <TYPE>  	构建类型：有三种可用的类型，分别为 project: PetaLinux 工程; apps: linux用户应用; modules: linux用户模块
- -s <SOURCE>    构建源码：使用一个已经存在的bsp包作为工程的源码
- -n <COMPONENT_NAME> 组件的名称，也就是生成的工程/应用/模块的文件夹名



#### 配置工程

通过命令 petalinux-config 可以配置 u-boot、linux、rootfs

```shell
petalinux-config -c  u-boot
petalinux-config -c  kernel
petalinux-config -c  rootfs # 尽量不要修改
```



在配置过程中可能会出现如下错误，通过命令`sudo chmod 777 /dev/pts/*`即可修复

```shell
u@7aa1d34a1fe6:/home/data/os/zynq/xilinx-zc702-22.08.22$ petalinux-config -c u-boot
[INFO] generating Kconfig for project
[INFO] sourcing bitbake
[INFO] generating plnxtool conf
[INFO] generating meta-plnx-generated layer
[INFO] configuring: u-boot
[INFO] generating u-boot configuration files
[INFO] bitbake virtual/bootloader -c menuconfig
Parsing recipes: 100% |#######################################################################################################################################################| Time: 0:01:06
Parsing of 2569 .bb files complete (0 cached, 2569 parsed). 3445 targets, 148 skipped, 0 masked, 0 errors.
NOTE: Resolving any missing task queue dependencies
Initialising tasks: 100% |####################################################################################################################################################| Time: 0:00:08
Checking sstate mirror object availability: 100% |############################################################################################################################| Time: 0:00:44
NOTE: Executing SetScene Tasks
NOTE: Executing RunQueue Tasks
Currently  1 running tasks (452 of 452)  99% |############################################################################################################################################# |
0: u-boot-xlnx-v2018.01-xilinx-v2018.3+gitAUTOINC+d8fc4b3b70-r0 do_menuconfig - 0s (pid 8968)
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
Trying to run: screen -r devshell_8968
Cannot open your terminal '/dev/pts/1' - please check.
```



#### 编译工程

```shell
# 编译完整工程
petalinux-build

# 查看帮助
petalinux-build --help

# 编译指定组件  -c ，比如rootfs
petalinux-build -c rootfs 

# 清除指定组件中的 -x distclean
petalinux-build -c rootfs  -x distclean
```

在编译过程中，如果修改 rootfs 配置后，可能需要下载源码包，此时需要科学上网，配置虚拟机为net模式，如果主机可以ping通虚拟机，但是虚拟机ping不通主机，去关闭windows防火墙，详见[参考](#参考)8。



### 单独构建（传统方式）

一定要注意，fsbl 文件是否为最新的，因为其 包含硬件初始化信息，如果不是最新的，即便通过jtag或者其它工具烧录进去，网口等其它口也不一定通。

#### 安装编译依赖

```shell
sudo apt install bc
```

#### 构建 u-boot

详见[仓库](https://github.com/FuntionTeam/u-boot-xlnx-xilinx-v2018.3)

```shell
# 0. 导入编译环境

# 1. 配置编译链为交叉编译，架构为arm
export CROSS_COMPILE=arm-linux-gnueabihf-
export ARCH=arm

# 2.
make distclean 

make zynq_zc702_my_defconfig 

make menuconfig 

make -j12

make dtbs

mv u-boot u-boot.elf 

cp -vrf u-boot.elf ../bsp/pre-built/linux/images/.
cp -vrf arch/arm/dts/zynq-zc702-my.dtb ../bsp/pre-built/linux/images/system.dtb
```



构建状态

- [x] uart 已通
- [x] eth Microchip ksz9031 已通, 需要注意电压为 1.8v
- [x] ddr 512MB 已通
  - IS43TR16128C-125KBLI 128M*16 
- [x] qspi 64MB 已通
  - S25FL512SAGMFIG11
- [x] mmc 已通



#### 构建 kernel

详见[仓库](https://github.com/FuntionTeam/linux-xlnx-xilinx-v2018.3)

```shell
# 导入环境
source ../petalinux-v2018.3/settings.sh

# 编译
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- xilinx_zynq_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j16
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- UIMAGE_LOADADDR=0x8000 uImage

# 拷贝
cp ./arch/arm/boot/uImage ./
cp ./arch/arm/boot/dts/zynq-zc702.dtb .

```





### 调试



#### 串口打印卡住

串口打印，到这边就不输出了

```shell
console [ttyPS0] enabled
bootconsole [earlycon0] disabled
bootconsole [earlycon0] disabled

```

未知原因..., 后来使用传统方式移植 u-boot



#### 网卡调试

phy 识别，不能ping通



先查 phy 地址

看手册发现 `PHY address` 跟 35、15、17三个pin脚有关，三个pin脚不同上下拉状态可组成8种状态，分别是 000-111，对应下述原理图可得到实际 `PHY address` 为 0

![](https://note-1251905184.cos.ap-shanghai.myqcloud.com/img/202208281700607.png)

![](https://note-1251905184.cos.ap-shanghai.myqcloud.com/img/202208281701331.png)



此时可以识别到网口，但是无法 ping 通，在[AM335x网络分析+KSZ9031分析（uboot中ping不通问题）](https://blog.csdn.net/qq_20753873/article/details/89139365)，

MDIO类似于I2C，均为两根线。RGMII接口是用来数据传输的、而MDIO是负责配置phy芯片的

![](https://note-1251905184.cos.ap-shanghai.myqcloud.com/img/202208281716301.png)

在 uboot 中可通过`mdio list`查看eth0已经连接到``ethernet@e000b000`

或者通过`dm tree`查看（` eth        [ + ]   zynq_gem        |-- ethernet@e000b000`）

发现 phy 已经被驱动;

另外通过 `mii dump`命令可以读出 `PHY` 寄存器值，如下日志，其ID与手册一一对应。

![](https://note-1251905184.cos.ap-shanghai.myqcloud.com/img/202208301621711.png)

```shell
U-Boot 2018.01 (Aug 30 2022 - 13:54:55 +0800) Xilinx Zynq ZC702 MY

Model: My Zynq ZC702 Development Board
Board: Xilinx Zynq
Silicon: v3.1
I2C:   ready
DRAM:  ECC disabled 512 MiB
MMC:   sdhci_transfer_data: Error detected in status(0x208000)!
sdhci@e0101000: 0 (eMMC)
SF: Detected s25fl512s_256k with page size 512 Bytes, erase size 256 KiB, total 64 MiB
*** Warning - bad CRC, using default environment

In:    serial@e0001000
Out:   serial@e0001000
Err:   serial@e0001000
Net:   ZYNQ GEM: e000b000, phyaddr 0, interface rgmii-id
eth0: ethernet@e000b000
Hit any key to stop autoboot:  0 
Copying Linux from QSPI flash to RAM...
SF: Detected s25fl512s_256k with page size 512 Bytes, erase size 256 KiB, total 64 MiB
device 0 offset 0x100000, size 0x500000
SF: 5242880 bytes @ 0x100000 Read: OK
device 0 offset 0x600000, size 0x20000
SF: 131072 bytes @ 0x600000 Read: OK
Copying ramdisk...
device 0 offset 0x620000, size 0x5e0000
SF: 6160384 bytes @ 0x620000 Read: OK
Wrong Image Format for bootm command
ERROR: can't get kernel image!
sdhci_transfer_data: Error detected in status(0x208000)!
switch to partitions #0, OK
mmc0(part 0) is current device
** No partition table - mmc 0 **
BOOTP broadcast 1
...
BOOTP broadcast 17

Retry time exceeded
Zynq> set ipaddr 10.0.0.234
Zynq> ping 10.0.0.1
Using ethernet@e000b000 device

ARP Retry count exceeded; starting again
ping failed; host 10.0.0.1 is not alive

Zynq> mdio 
mdio - MDIO utility commands

Usage:
mdio list			- List MDIO buses
mdio read <phydev> [<devad>.]<reg> - read PHY's register at <devad>.<reg>
mdio write <phydev> [<devad>.]<reg> <data> - write PHY's register at <devad>.<reg>
mdio rx <phydev> [<devad>.]<reg> - read PHY's extended register at <devad>.<reg>
mdio wx <phydev> [<devad>.]<reg> <data> - write PHY's extended register at <devad>.<reg>
<phydev> may be:
   <busname>  <addr>
   <addr>
   <eth name>
<addr> <devad>, and <reg> may be ranges, e.g. 1-5.4-0x1f.

Zynq> mdio list
eth0:
0 - Micrel ksz9031 <--> ethernet@e000b000

Zynq> mii info     
PHY 0x00: OUI = 0x0885, Model = 0x22, Rev = 0x02, 1000baseT, FDX

Zynq> mii dump 0 0
0.     (1140)                 -- PHY control register --
  (8000:0000) 0.15    =     0    reset
  (4000:0000) 0.14    =     0    loopback
  (2040:0040) 0. 6,13 =   b10    speed selection = 1000 Mbps
  (1000:1000) 0.12    =     1    A/N enable
  (0800:0000) 0.11    =     0    power-down
  (0400:0000) 0.10    =     0    isolate
  (0200:0000) 0. 9    =     0    restart A/N
  (0100:0100) 0. 8    =     1    duplex = full
  (0080:0000) 0. 7    =     0    collision test enable
  (003f:0000) 0. 5- 0 =     0    (reserved)

Zynq> mii dump 0 1
1.     (796d)                 -- PHY status register --
  (8000:0000) 1.15    =     0    100BASE-T4 able
  (4000:4000) 1.14    =     1    100BASE-X  full duplex able
  (2000:2000) 1.13    =     1    100BASE-X  half duplex able
  (1000:1000) 1.12    =     1    10 Mbps    full duplex able
  (0800:0800) 1.11    =     1    10 Mbps    half duplex able
  (0400:0000) 1.10    =     0    100BASE-T2 full duplex able
  (0200:0000) 1. 9    =     0    100BASE-T2 half duplex able
  (0100:0100) 1. 8    =     1    extended status
  (0080:0000) 1. 7    =     0    (reserved)
  (0040:0040) 1. 6    =     1    MF preamble suppression
  (0020:0020) 1. 5    =     1    A/N complete
  (0010:0000) 1. 4    =     0    remote fault
  (0008:0008) 1. 3    =     1    A/N able
  (0004:0004) 1. 2    =     1    link status
  (0002:0000) 1. 1    =     0    jabber detect
  (0001:0001) 1. 0    =     1    extended capabilities

Zynq> mii dump 0 2
2.     (0022)                 -- PHY ID 1 register --
  (ffff:0022) 2.15- 0 =    34    OUI portion

Zynq> mii dump 0 3
3.     (1622)                 -- PHY ID 2 register --
  (fc00:1400) 3.15-10 =     5    OUI portion
  (03f0:0220) 3. 9- 4 =    34    manufacturer part number
  (000f:0002) 3. 3- 0 =     2    manufacturer rev. number

Zynq> mii dump 0 5
5.     (cde1)                 -- Autonegotiation partner abilities register --
  (8000:8000) 5.15    =     1    next page able
  (4000:4000) 5.14    =     1    acknowledge
  (2000:0000) 5.13    =     0    remote fault
  (1000:0000) 5.12    =     0    (reserved)
  (0800:0800) 5.11    =     1    asymmetric pause able
  (0400:0400) 5.10    =     1    pause able
  (0200:0000) 5. 9    =     0    100BASE-T4 able
  (0100:0100) 5. 8    =     1    100BASE-X full duplex able
  (0080:0080) 5. 7    =     1    100BASE-TX able
  (0040:0040) 5. 6    =     1    10BASE-T full duplex able
  (0020:0020) 5. 5    =     1    10BASE-T able
  (001f:0001) 5. 4- 0 =     1    selector = IEEE 802.3

Zynq> mii dump 0 6
The MII dump command only formats the standard MII registers, 0-5.
Zynq> mii dump 0 5
5.     (cde1)                 -- Autonegotiation partner abilities register --
  (8000:8000) 5.15    =     1    next page able
  (4000:4000) 5.14    =     1    acknowledge
  (2000:0000) 5.13    =     0    remote fault
  (1000:0000) 5.12    =     0    (reserved)
  (0800:0800) 5.11    =     1    asymmetric pause able
  (0400:0400) 5.10    =     1    pause able
  (0200:0000) 5. 9    =     0    100BASE-T4 able
  (0100:0100) 5. 8    =     1    100BASE-X full duplex able
  (0080:0080) 5. 7    =     1    100BASE-TX able
  (0040:0040) 5. 6    =     1    10BASE-T full duplex able
  (0020:0020) 5. 5    =     1    10BASE-T able
  (001f:0001) 5. 4- 0 =     1    selector = IEEE 802.3

Zynq> bdinfo
arch_number = 0x00000000
boot_params = 0x00000000
DRAM bank   = 0x00000000
-> start    = 0x00000000
-> size     = 0x20000000
baudrate    = 115200 bps
TLB addr    = 0x1FFF0000
relocaddr   = 0x1FF47000
reloc off   = 0x1BF47000
irq_sp      = 0x1EB26ED0
sp start    = 0x1EB26EC0
ARM frequency = 666 MHz
DSP frequency = 0 MHz
DDR frequency = 399 MHz
Early malloc usage: 5a4 / 800
fdt_blob = 1ffa8140

Zynq> dm
dm - Driver model low level access

Usage:
dm tree         Dump driver model tree ('*' = activated)
dm uclass        Dump list of instances for each uclass
dm devres        Dump list of device resources for each device
Zynq> dm tree
 Class      Probed  Driver      Name
----------------------------------------
 root       [ + ]   root_drive  root_driver
 rsa_mod_ex [   ]   mod_exp_sw  |-- mod_exp_sw
 simple_bus [ + ]   generic_si  `-- amba
 gpio       [   ]   gpio_zynq       |-- gpio@e000a000
 serial     [ + ]   serial_zyn      |-- serial@e0001000
 spi        [ + ]   zynq_qspi       |-- spi@e000d000
 spi_flash  [ + ]   spi_flash_      |   `-- spi_flash@0:0
 eth        [ + ]   zynq_gem        |-- ethernet@e000b000
 mmc        [ + ]   arasan_sdh      |-- sdhci@e0101000
 blk        [ + ]   mmc_blk         |   `-- sdhci@e0101000.blk
 simple_bus [ + ]   generic_si      `-- slcr@f8000000
 clk        [ + ]   zynq_clk            `-- clkc@100


Zynq> mdio read 0 0
0 is not a known ethernet
Reading from bus eth0
PHY at address 0:
0 - 0x1140
Zynq> mdio read 0 1
0 is not a known ethernet
Reading from bus eth0
PHY at address 0:
1 - 0x796d
Zynq> mdio read 0 2
0 is not a known ethernet
Reading from bus eth0
PHY at address 0:
2 - 0x22
Zynq> mdio read 0 3
0 is not a known ethernet
Reading from bus eth0
PHY at address 0:
3 - 0x1622
Zynq> mdio read  3 
Reading from bus eth0
PHY at address 0:
3 - 0x1622
Zynq> mdio read  2
Reading from bus eth0
PHY at address 0:
2 - 0x22
Zynq> mdio read  2
Reading from bus eth0
PHY at address 0:
2 - 0x22
Zynq> mdio read  3
Reading from bus eth0
PHY at address 0:
3 - 0x1622
Zynq> 


```

最终比对查找发现是电压问题，将 `Bank1 2.5v`改为`Bank1 1.8v`就可以了。



#### qspi 烧录报错

错误日志如下，刚开始以为是flash芯片不被支持，差一点按照[这个方法](https://blog.csdn.net/weixin_40293570/article/details/118520693)去做，后来在[AR 59174](https://support.xilinx.com/s/article/59174?language=ja)中根据步骤一步步排除，其芯片是被支持的（从[此](https://support.xilinx.com/s/article/50991?language=en_US)可以看出该芯片**S25FL512S**是支持的）。 

```c
Connected to hw_server @ TCP:127.0.0.1:3121
Available targets and devices:
Target 0 : jsn-JTAG-HS3-210299813518
	Device 0: jsn-JTAG-HS3-210299813518-4ba00477-0

Retrieving Flash info...

Initialization done, programming the memory
===== mrd->addr=0xF800025C, data=0x00000001 =====
BOOT_MODE REG = 0x00000001
WARNING: [Xicom 50-100] The current boot mode is QSPI.
If flash programming fails, configure device for JTAG boot mode and try again.
===== mrd->addr=0xF8007080, data=0x30800100 =====
===== mrd->addr=0xF8000B18, data=0x00000000 =====
Downloading FSBL...
Running FSBL...
Finished running FSBL.
===== mrd->addr=0xF8000110, data=0x00177EA0 =====
READ: ARM_PLL_CFG (0xF8000110) = 0x00177EA0
===== mrd->addr=0xF8000100, data=0x0001A008 =====
READ: ARM_PLL_CTRL (0xF8000100) = 0x0001A008
===== mrd->addr=0xF8000120, data=0x1F000400 =====
READ: ARM_CLK_CTRL (0xF8000120) = 0x1F000400
===== mrd->addr=0xF8000118, data=0x00177EA0 =====
READ: IO_PLL_CFG (0xF8000118) = 0x00177EA0
===== mrd->addr=0xF8000108, data=0x0001A008 =====
READ: IO_PLL_CTRL (0xF8000108) = 0x0001A008
Info:  Remapping 256KB of on-chip-memory RAM memory to 0xFFFC0000.
===== mrd->addr=0xF8000008, data=0x00000000 =====
===== mwr->addr=0xF8000008, data=0x0000DF0D =====
MASKWRITE: addr=0xF8000008, mask=0x0000FFFF, newData=0x0000DF0D
===== mwr->addr=0xF8000910, data=0x000001FF =====
===== mrd->addr=0xF8000004, data=0x00000000 =====
===== mwr->addr=0xF8000004, data=0x0000767B =====
MASKWRITE: addr=0xF8000004, mask=0x0000FFFF, newData=0x0000767B


U-Boot 2018.01-00073-g63efa8c-dirty (Oct 04 2018 - 08:22:22 -0600)

Model: Zynq CSE QSPI Board
Board: Xilinx Zynq
Silicon: v3.1
DRAM:  256 KiB
WARNING: Caches not enabled
Using default environment

In:    dcc
Out:   dcc
Err:   dcc
Zynq> sf probe 0 0 0

SF: unrecognized JEDEC id bytes: 00, 00, 00
Failed to initialize SPI flash at 0:0 (error -2)
Zynq> ERROR: [Xicom 50-186] Error while detecting SPI flash device - unrecognized JEDEC id bytes: 00, 00, 00
Problem in running uboot
Flash programming initialization failed.

ERROR: Flash Operation Failed
```



[解决方案](https://www.uisrc.com/forum.php?mod=viewthread&tid=1660&highlight=2017.4)， 也就是在 fsbl 的 main.c 中添加

```c
	/*
	 * Read bootmode register
	 */
	BootModeRegister = Xil_In32(BOOT_MODE_REG);
	BootModeRegister &= BOOT_MODES_MASK;
+       BootModeRegister = JTAG_MODE;
```





### 驱动代码编写

#### 参考

1. [ZYNQ下Linux驱动代码的编写](https://blog.csdn.net/qq_40063466/article/details/106048819)
1. [ZYNQ+PetaLinux控制AXI GPIO实现LED灯亮灭](https://blog.csdn.net/u011239266/article/details/108947559)



### UIO 

#### 参考

1. [ZYNQ Linux 使用UIO中断](https://blog.csdn.net/jin787730090/article/details/108717353)
2. 









## 从0开始到进入系统

#### 参考

参考以下优秀博文，没有这些优秀大佬的努力是不可能这么块弄好的，感谢！！！

1. [ZYNQ FLASH+EMMC手动移植LINUX启动](https://www.cnblogs.com/kingstacker/p/15064798.html)
2. [ZYNQ petalinux将系统启动文件固化到EMMC](https://blog.csdn.net/wangjie36/article/details/104740448)
3. [BusyBox下tftp命令的使用 ](https://www.cnblogs.com/amanlikethis/p/6837206.html)
4. [zynq7000从emmc启动，使用ext4文件系统](https://blog.csdn.net/tianyake_1/article/details/119389118)
5. [【Zynq】【uboot应用】使用uEnv.txt导入uboot环境变量](http://www.corecourse.cn/forum.php?mod=viewthread&tid=28695)
6. [捡了个便宜的高级ZYNQ XC7Z010 开发板玩玩](https://whycan.com/t_2297.html)



#### 主要步骤

1. 创建 `vivado` 工程

2. 编译构建生成 `bitstream` 文件，`export` 导出 `hdf` 文件

3. `Launch SDK`，创建 `FSBL` 工程

4. SDK 中使用 `Create Boot Image` 创建 `UBOOT.bin` 文件(需要 fsbl + bit文件 + u-boot.elf )

5. `Program flash`，烧录之后断电重启进入 u-boot(烧录时在v2018.x版本存在bug, 需要先创建一个fsbl_load去强制设备从Jtag启动，BOOT中的呢，又需要是读取默认引脚电平的)

6. 使用 tftpd 创建 tftp 服务，通过命令进入临时系统

   ```shell
   set ipaddr 192.168.1.10;set serverip 192.168.1.100
   tftpboot 0x03000000 uImage
   tftpboot 0x02A00000 system.dtb
   tftpboot 0x02000000 rootfs.cpio.gz.u-boot
   bootm 0x3000000 0x2000000 0x2A00000
   ```

7. 进入临时系统格式化 mmc、分为两个区 前者为fat2、后者为ext4(如果不能格式化为 ext4,可直接使用dd命令将 rootfs*.ext4 写入到第二个分区)

8. 在第一个分区创建 uEnvs.txt，里面存储的命令如下

   ```shell
   bootargs=console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlyprintk rootfstype=ext4 rootwait
   load_image=fatload mmc 0 ${kernel_load_address} ${kernel_image} && fatload mmc 0 ${devicetree_load_address} ${devicetree_image}
   uenvcmd=echo Copying Linux from SD to RAM... && mmcinfo &&  run load_image && bootm ${kernel_load_address} - ${devicetree_load_address}
   ```

9. u-boot 中 使用 make menuconfig 修改为 sdboot 启动，就可以默认直接从 mmc 启动了。



## 参考

1. [第五章Petalinux的安装-领航者ZYNQ之linux开发指南](https://zhuanlan.zhihu.com/p/228431934)
2. [EBAZ4205 ZYNQ 7Z010 u-boot & Linux 生成方法记录](https://www.jianshu.com/p/370f95f0068f)
3. [捡了个便宜的高级ZYNQ XC7Z010 开发板玩玩](https://whycan.com/t_2297.html)
4. [Ubuntu增加一个用户并给普通用户赋予root权限的方法](https://www.cnblogs.com/qypt2015/p/6918336.html)
5. [Vivado 2018.3下载安装和HelloWorld](https://blog.csdn.net/qq_38113006/article/details/121580393)
6. [用petalinux工具制作linux系统启动映像](https://blog.csdn.net/asd1147170607/article/details/105600572)
7. [petalinux2020.1版本QSPI FLASH启动linux教程](https://blog.csdn.net/founderHAN/article/details/110523723)
8. [Win10中VMware虚拟机NET模式Ping不通主机](https://blog.csdn.net/zhaochenzzz/article/details/119109404)
9. [VMware虚拟机怎么使用主机代理？](https://www.zhihu.com/question/495148700)
10. [使用Petalinux定制Linux系统](https://www.cnblogs.com/Mike2019/p/14293018.html)
11. [ZYNQ+linux网口调试笔记（1）PS-GEM0](https://www.jianshu.com/p/a4e25e8b2f5e)
12. [zynq linux 双网卡实现](https://www.cnblogs.com/huakaimanlin/p/9292084.html)
13. https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/189530183/Zynq-7000
