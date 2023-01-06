# zynq 板级配置

## u-boot

### env 环境变量

```shell
Zynq> printenv         
arch=arm
baudrate=115200
bitstream_image=system.bit.bin
board=zynq
board_name=zynq
boot_a_script=load ${devtype} ${devnum}:${distro_bootpart} ${scriptaddr} ${prefix}${script}; source ${scriptaddr}
boot_efi_binary=if fdt addr ${fdt_addr_r}; then bootefi bootmgr ${fdt_addr_r};else bootefi bootmgr ${fdtcontroladdr};fi;load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} efi/boot/bootarm.efi; if fdt addr ${fdt_addr_r}; then bootefi ${kernel_addr_r} ${fdt_addr_r};else bootefi ${kernel_addr_r} ${fdtcontroladdr};fi
boot_extlinux=sysboot ${devtype} ${devnum}:${distro_bootpart} any ${scriptaddr} ${prefix}extlinux/extlinux.conf
boot_image=BOOT.bin
boot_prefixes=/ /boot/
boot_script_dhcp=boot.scr.uimg
boot_scripts=boot.scr.uimg boot.scr
boot_size=0xF00000
boot_targets=mmc0 pxe dhcp 
bootcmd=run $modeboot || run distro_bootcmd
bootcmd_dhcp=if dhcp ${scriptaddr} ${boot_script_dhcp}; then source ${scriptaddr}; fi;setenv efi_fdtfile ${fdtfile}; if test -z "${fdtfile}" -a -n "${soc}"; then setenv efi_fdtfile ${soc}-${board}${boardver}.dtb; fi; setenv efi_old_vci ${bootp_vci};setenv efi_old_arch ${bootp_arch};setenv bootp_vci PXEClient:Arch:00010:UNDI:003000;setenv bootp_arch 0xa;if dhcp ${kernel_addr_r}; then tftpboot ${fdt_addr_r} dtb/${efi_fdtfile};if fdt addr ${fdt_addr_r}; then bootefi ${kernel_addr_r} ${fdt_addr_r}; else bootefi ${kernel_addr_r} ${fdtcontroladdr};fi;fi;setenv bootp_vci ${efi_old_vci};setenv bootp_arch ${efi_old_arch};setenv efi_fdtfile;setenv efi_old_arch;setenv efi_old_vci;
bootcmd_mmc0=setenv devnum 0; run mmc_boot
bootcmd_pxe=dhcp; if pxe get; then pxe boot; fi
bootdelay=2
bootenv=uEnv.txt
bootfile=boot.scr.uimg
cpu=armv7
devicetree_image=devicetree.dtb
devicetree_load_address=0x2000000
devicetree_size=0x20000
devnum=0
devplist=1
devtype=mmc
distro_bootcmd=for target in ${boot_targets}; do run bootcmd_${target}; done
efi_dtb_prefixes=/ /dtb/ /dtb/current/
ethact=ethernet@e000b000
ethaddr=00:0a:35:00:01:22
fdt_high=0x20000000
fdtcontroladdr=1ffa80b0
importbootenv=echo Importing environment from SD ...; env import -t ${loadbootenv_addr} $filesize
initrd_high=0x20000000
jtagboot=echo TFTPing Linux to RAM... && tftpboot ${kernel_load_address} ${kernel_image} && tftpboot ${devicetree_load_address} ${devicetree_image} && tftpboot ${ramdisk_load_address} ${ramdisk_image} && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
kernel_image=uImage
kernel_load_address=0x2080000
kernel_size=0x500000
load_efi_dtb=load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} ${prefix}${efi_fdtfile}
loadbit_addr=0x100000
loadbootenv=load mmc 0 ${loadbootenv_addr} ${bootenv}
loadbootenv_addr=0x2000000
mmc_boot=if mmc dev ${devnum}; then setenv devtype mmc; run scan_dev_for_boot_part; fi
mmc_loadbit=echo Loading bitstream from SD/MMC/eMMC to RAM.. && mmcinfo && load mmc 0 ${loadbit_addr} ${bitstream_image} && fpga load 0 ${loadbit_addr} ${filesize}
modeboot=qspiboot
nandboot=echo Copying Linux from NAND flash to RAM... && nand read ${kernel_load_address} 0x100000 ${kernel_size} && nand read ${devicetree_load_address} 0x600000 ${devicetree_size} && echo Copying ramdisk... && nand read ${ramdisk_load_address} 0x620000 ${ramdisk_size} && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
norboot=echo Copying Linux from NOR flash to RAM... && cp.b 0xE2100000 ${kernel_load_address} ${kernel_size} && cp.b 0xE2600000 ${devicetree_load_address} ${devicetree_size} && echo Copying ramdisk... && cp.b 0xE2620000 ${ramdisk_load_address} ${ramdisk_size} && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
preboot=if test $modeboot = sdboot && env run sd_uEnvtxt_existence_test; then if env run loadbootenv; then env run importbootenv; fi; fi; 
qspiboot=echo Copying Linux from QSPI flash to RAM... && sf probe 0 0 0 && sf read ${kernel_load_address} 0x100000 ${kernel_size} && sf read ${devicetree_load_address} 0x600000 ${devicetree_size} && echo Copying ramdisk... && sf read ${ramdisk_load_address} 0x620000 ${ramdisk_size} && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
ramdisk_image=uramdisk.image.gz
ramdisk_load_address=0x4000000
ramdisk_size=0x5E0000
rsa_jtagboot=echo TFTPing Image to RAM... && tftpboot 0x100000 ${boot_image} && zynqrsa 0x100000 && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
rsa_nandboot=echo Copying Image from NAND flash to RAM... && nand read 0x100000 0x0 ${boot_size} && zynqrsa 0x100000 && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
rsa_norboot=echo Copying Image from NOR flash to RAM... && cp.b 0xE2100000 0x100000 ${boot_size} && zynqrsa 0x100000 && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
rsa_qspiboot=echo Copying Image from QSPI flash to RAM... && sf probe 0 0 0 && sf read 0x100000 0x0 ${boot_size} && zynqrsa 0x100000 && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
rsa_sdboot=echo Copying Image from SD to RAM... && load mmc 0 0x100000 ${boot_image} && zynqrsa 0x100000 && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}
scan_dev_for_boot=echo Scanning ${devtype} ${devnum}:${distro_bootpart}...; for prefix in ${boot_prefixes}; do run scan_dev_for_extlinux; run scan_dev_for_scripts; done;run scan_dev_for_efi;
scan_dev_for_boot_part=part list ${devtype} ${devnum} -bootable devplist; env exists devplist || setenv devplist 1; for distro_bootpart in ${devplist}; do if fstype ${devtype} ${devnum}:${distro_bootpart} bootfstype; then run scan_dev_for_boot; fi; done
scan_dev_for_efi=setenv efi_fdtfile ${fdtfile}; if test -z "${fdtfile}" -a -n "${soc}"; then setenv efi_fdtfile ${soc}-${board}${boardver}.dtb; fi; for prefix in ${efi_dtb_prefixes}; do if test -e ${devtype} ${devnum}:${distro_bootpart} ${prefix}${efi_fdtfile}; then run load_efi_dtb; fi;done;if test -e ${devtype} ${devnum}:${distro_bootpart} efi/boot/bootarm.efi; then echo Found EFI removable media binary efi/boot/bootarm.efi; run boot_efi_binary; echo EFI LOAD FAILED: continuing...; fi; setenv efi_fdtfile
scan_dev_for_extlinux=if test -e ${devtype} ${devnum}:${distro_bootpart} ${prefix}extlinux/extlinux.conf; then echo Found ${prefix}extlinux/extlinux.conf; run boot_extlinux; echo SCRIPT FAILED: continuing...; fi
scan_dev_for_scripts=for script in ${boot_scripts}; do if test -e ${devtype} ${devnum}:${distro_bootpart} ${prefix}${script}; then echo Found U-Boot script ${prefix}${script}; run boot_a_script; echo SCRIPT FAILED: continuing...; fi; done
sd_uEnvtxt_existence_test=test -e mmc 0 /uEnv.txt
sdboot=if mmcinfo; then run uenvboot; echo Copying Linux from SD to RAM... && load mmc 0 ${kernel_load_address} ${kernel_image} && load mmc 0 ${devicetree_load_address} ${devicetree_image} && load mmc 0 ${ramdisk_load_address} ${ramdisk_image} && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}; fi
soc=zynq
stderr=serial@e0001000
stdin=serial@e0001000
stdout=serial@e0001000
uenvboot=if run loadbootenv; then echo Loaded environment from ${bootenv}; run importbootenv; fi; if test -n $uenvcmd; then echo Running uenvcmd ...; run uenvcmd; fi
usbboot=if usb start; then run uenvboot; echo Copying Linux from USB to RAM... && load usb 0 ${kernel_load_address} ${kernel_image} && load usb 0 ${devicetree_load_address} ${devicetree_image} && load usb 0 ${ramdisk_load_address} ${ramdisk_image} && bootm ${kernel_load_address} ${ramdisk_load_address} ${devicetree_load_address}; fi
vendor=xilinx

Environment size: 7744/131068 bytes
```

### 如何下载

```shell
# 配置 ip
set ipaddr 192.168.1.10
# 配置tftp服务器ip
set serverip 192.168.1.100

# 将uImage传输到 0x03000000 处
tftpboot 0x03000000 uImage
# 将devicetree.dtb传输到 0x02A00000 处
tftpboot 0x02A00000 devicetree.dtb
# 将rootfs.cpio.gz.u-boot文件系统 传输到 0x02000000 处
tftpboot 0x02000000 rootfs.cpio.gz.u-boot
# 启动
bootm 0x3000000 0x2000000 0x2A00000
```

参考分区： https://blog.csdn.net/vacajk/article/details/53908666

### uEnv

U-boot 支持多种方式启动，本板硬件环境是`flash` + `mmc`, 所以使用 `sdroot` 启动，`mmc`也就是被当成`sd`使用

分区则是如下

- flash 中存放 fsbl.bif + pl.bit + u-boot.elf (也就是 BOOT.bin, 可以通过SDK工具合成)
- mmc 分为两部分
  - 第一部分格式fat, 存放 uEnv.txt devicetree.dtb uImage
  - 第二部分格式最好为ext4, 存放rootfs及应用

第一部分则是可以直接通过jtag直接下载 BOOT.bin
此后可通过网络更新第一分区里面的设备树和内核, 第二部分也通过网络更新

```shell
ifconfig eth0 192.168.1.10
rm -rf uImage devicetree.dtb
tftp -gl uImage 192.168.1.100
tftp -gl devicetree.dtb 192.168.1.100
sync
```

通过查看 [Env-环境变量](#env-环境变量) preroot 可得，如果uEnv.txt 存在，则会load该文件。

```shell
bootargs=console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlyprintk rootfstype=ext4 rootwait
load_image=fatload mmc 0 ${kernel_load_address} ${kernel_image} && fatload mmc 0 ${devicetree_load_address} ${devicetree_image}
uenvcmd=echo Copying Linux from SD to RAM... && mmcinfo &&  run load_image && bootm ${kernel_load_address} - ${devicetree_load_address}
```

## kernel

### 网络配置

涉及文件 `/etc/network/interfaces`
其中eth0 则为我们的网卡名，下面是将网卡配置为静态分配ip，ip为`192.168.1.10`

```bash
root@zynq:~# cat /etc/network/interfaces 
# /etc/network/interfaces -- configuration file for ifup(8), ifdown(8)

# The loopback interface
auto lo
iface lo inet loopback
#
auto eth0
iface eth0 inet static
	address 192.168.1.10
	netmask 255.255.255.0
	gateway 192.168.1.1
root@zynq:~# 

```

### UIO 中断

PL与PS中断[^1] [^2]

[^1]: https://blog.csdn.net/h244259402/article/details/83993524

[^2]: https://www.cnblogs.com/schips/p/a_little_lament_when_debug_irq_in_zynq_linux.html

### App

**默认不支持cpp, 需要将对应的库拷贝至对应位置**

板子rootfs上无 cpp 运行环境，需要将 `libgcc_s.so` `libstdc++.so` 从 宿主机的交叉编译工具链（`/home/u/workspace/os/zynq/petalinux-v2018.3/tools/linux-i386/gcc-arm-linux-gnueabi/arm-linux-gnueabihf/libc/lib`） 下拷贝到板子的 `/lib`下
