RootDirSectors			equ	14	; 根目录占用分区数 =（根目录可容纳的目录项数 * 32 + 每扇区字节数-1）/每扇区字节数 =(224*32+512-1)/512=14
SectorNumOfRootDirStart	equ	19	; 保留分区数 + 每FAT扇区数 * FAT表份数 --> 1+9*2=19
SectorNumOfFAT1Start	equ	1	; FAT1表的其实扇区号
SectorBalance			equ	17	; 用于平衡文件的其实簇号与数据区起始簇号的差值

		
	BS_OEMName		db	"MINEBoot"	;生产厂商名
	BPB_BytesPerSec	dw	512			;每扇区字节数
	BPB_SecPerClus	db	1			;每簇扇区数
	BPB_RsvdSecCnt	dw	1			;保留扇区数
	BPB_NumFATs		db	2			;FAT表的份数
	BPB_RootEntCnt	dw	224			;根目录可容纳的目录项数
	BPB_TotSec16	dw	2880		;总扇区
	BPB_Media		db	0xF0		;介质描述符
	BPB_FATSz16		dw	9			;每FAT扇区数
	BPB_SecPerTrk	dw	18			;每磁道扇区数
	BPB_NumHeads	dw	2			;磁头数
	BPB_HiddSec		dd	0			;隐藏扇区数
	BPB_TotSec32	dd	0			;如果BPB_TotSec16值为0，则由这个值记录扇区数
	BS_DrvNum		db	0			;int 13h的驱动器号
	BS_Reserved1	db	0			;未使用
	BS_BootSig		db	0x29		;扩展引导标记(29h)
	BS_VolID		dd	0			;卷序列号
	BS_VolLab		db	"boot loader";卷标
	BS_FileSysType	dq	"FAT12"	;文件系统类型
	times	12 - ($ - BS_FileSysType) db 0