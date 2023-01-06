<!--
 * @Author: Acoollib
 * @Date: 2022-03-21 18:56:40
 * @LastEditTime: 2022-03-22 15:26:41
 * @LastEditors: Please set LastEditors
 * @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 * @FilePath: /os2/readme.md
-->
## 编译boot.asm
`nasm boot.asm -o boot.bin`

使用命令`hexdump -C boot.bin`查看大小和最后两字节是否为 `0xaa 0x55`
 
## 创建1.44M软盘
`dd if=/dev/zero of=floppy bs=1024 count=1440`


## bios功能介绍
https://wiki.osdev.org/BIOS



## reference
1.[软盘镜像的制作](https://www.cnblogs.com/image-eye/archive/2011/08/19/2145398.html)
2.[FAT12软盘映像文件的制作](https://www.jianshu.com/p/bfdc4682eaef)

