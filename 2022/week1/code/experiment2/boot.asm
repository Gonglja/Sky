		org	0x7c00
BaseOfStack	equ 	0x7c00

BaseOfLoader	equ	0x1000
OffsetOfLoader	equ	0x00

RootDirSectors			equ	14	; 根目录占用分区数 =（根目录可容纳的目录项数 * 32 + 每扇区字节数-1）/每扇区字节数 =(224*32+512-1)/512=14
SectorNumOfRootDirStart	equ	19	; 保留分区数 + 每FAT扇区数 * FAT表份数 --> 1+9*2=19
SectorNumOfFAT1Start	equ	1	; FAT1表的其实扇区号
SectorBalance			equ	17	; 用于平衡文件的其实簇号与数据区起始簇号的差值


	jmp 	short Start				;跳转指令
	nop				
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


Start:
	mov 	ax,cs
	mov		ds,ax
	mov		es,ax
	mov		ss,ax
	mov     sp,BaseOfStack

;============== clear screen 
ClearScreen:
	mov		ax,0x0600
	mov		bx,0x0700
	mov 	cx,0
	mov 	dx,0x184f
	int		0x10

;============== set focus
	mov 	ax,0x0200
	mov 	bx,0x0000
	mov 	dx,0x0000
	int 	0x10

	jmp 	DisplayStrToScreen
; ;============== display char*
; DisplayCharToScreen:
; 	mov 	ah,0x0e
; 	mov 	al,'H'
; 	int 	0x10
; 	mov 	al,'e'
; 	int 	0x10
; 	mov 	al,'l'
; 	int 	0x10
; 	mov 	al,'l'
; 	int 	0x10
; 	mov 	al,'o'
; 	int 	0x10
; 	mov 	al,','
; 	int 	0x10
; 	mov 	al,'W'
; 	int 	0x10
; 	mov 	al,'o'
; 	int 	0x10
; 	mov 	al,'r'
; 	int 	0x10
; 	mov 	al,'l'
; 	int 	0x10
; 	mov 	al,'d'
; 	int 	0x10
; 	mov 	al,'!'
; 	int 	0x10
; 	;jmp     hlt
	
;==============	dispaly on screen: Start Booting...
DisplayStrToScreen:
	mov 	ax,0x1301
	mov 	bx,0x0007
	mov		dx,0x0000
	mov		cx,MsgLen
	push 	ax
	mov 	ax,ds
	mov 	es,ax
	pop 	ax
	mov 	bp,StartBootMessage
	int 	0x10
	;jmp 	hlt

;============== reset floppy
ResetFloppy:
	xor 	ah,ah
	xor 	dl,dl
	int 	0x13


;=======	search loader.bin
	mov	word	[SectorNo],	SectorNumOfRootDirStart

SearchInRootDirBegin:
	cmp	word	[RootDirSizeForLoop],	0
	jz			NoLoaderBin
	dec	word	[RootDirSizeForLoop]	
	mov			ax,	00h
	mov			es,	ax
	mov			bx,	8000h
	mov			ax,	[SectorNo]
	mov			cl,	1
	call		ReadOneSector
	mov			si,	LoaderFileName
	mov			di,	8000h
	cld
	mov			dx,	10h
	
SearchForLoaderBin:
	cmp			dx,	0
	jz			GotoNextSectorInRootDir
	dec			dx
	mov			cx,	11

CmpFileName:
	cmp			cx,	0
	jz			FileNameFound
	dec			cx
	lodsb	
	cmp			al,	byte	[es:di]
	jz			GoOn
	jmp			Different

GoOn:	
	inc			di
	jmp			CmpFileName

Different:
	and			di,	0ffe0h
	add			di,	20h
	mov			si,	LoaderFileName
	jmp			SearchForLoaderBin

GotoNextSectorInRootDir:
	add	word	[SectorNo],	1
	jmp			SearchInRootDirBegin
	
;=======	display on screen : ERROR:No LOADER Found

NoLoaderBin:
	mov			ax,	1301h
	mov			bx,	008ch
	mov			dx,	0100h
	mov			cx,	21
	push		ax
	mov			ax,	ds
	mov			es,	ax
	pop			ax
	mov			bp,	NoLoaderMessage
	int			10h
	jmp			$

;=======	found loader.bin name in root director struct
FileNameFound:
	mov			ax,	RootDirSectors
	and			di,	0ffe0h
	add			di,	01ah
	mov			cx,	word	[es:di]
	push		cx
	add			cx,	ax
	add			cx,	SectorBalance
	mov			ax,	BaseOfLoader
	mov			es,	ax
	mov			bx,	OffsetOfLoader
	mov			ax,	cx

GoOnLoadingFile:
	push		ax
	push		bx
	mov			ah,	0eh
	mov			al,	'.'
	mov			bl,	0fh
	int			10h
	pop			bx
	pop			ax

	mov			cl,	1
	call		ReadOneSector
	pop			ax
	call		GetFATEntry
	cmp			ax,	0fffh
	jz			FileLoaded
	push		ax
	mov			dx,	RootDirSectors
	add			ax,	dx
	add			ax,	SectorBalance
	add			bx,	[BPB_BytesPerSec]
	jmp			GoOnLoadingFile

FileLoaded:
	jmp			BaseOfLoader:OffsetOfLoader

;=======	read one sector from floppy
ReadOneSector:	
	push		bp
	mov			bp,	sp
	sub			esp,	2
	mov	byte	[bp - 2],	cl
	push		bx
	mov			bl,	[BPB_SecPerTrk]
	div			bl
	inc			ah
	mov			cl,	ah
	mov			dh,	al
	shr			al,	1
	mov			ch,	al
	and			dh,	1
	pop			bx
	mov			dl,	[BS_DrvNum]

GoOnReading:
	mov			ah,	2
	mov			al,	byte	[bp - 2]
	int			13h
	jc			GoOnReading
	add			esp,2
	pop			bp
	ret

;=======	get FAT Entry
GetFATEntry:
	push		es
	push		bx
	push		ax
	mov			ax,	00
	mov			es,	ax
	pop			ax
	mov			byte	[Odd],	0
	mov			bx,	3
	mul			bx
	mov			bx,	2
	div			bx
	cmp			dx,	0
	jz			Even
	mov	byte	[Odd],	1

Even:
	xor			dx,	dx
	mov			bx,	[BPB_BytesPerSec]
	div			bx
	push		dx
	mov			bx,	8000h
	add			ax,	SectorNumOfFAT1Start
	mov			cl,	2
	call		ReadOneSector
	
	pop			dx
	add			bx,	dx
	mov			ax,	[es:bx]
	cmp	byte	[Odd],	1
	jnz	Even2
	shr	ax,	4

Even2:
	and			ax,	0fffh
	pop			bx
	pop			es
	ret

;=======	tmp variable

RootDirSizeForLoop	dw	RootDirSectors
SectorNo			dw	0
Odd					db	0

;=======	display messages

StartBootMessage:	db	"Start Boot..."
MsgLen: 	  		equ $ - StartBootMessage
NoLoaderMessage:	db	"ERROR:No LOADER Found"
LoaderFileName:		db	"LOADER  BIN",0

;==============	hlt
hlt:
	jmp	$



;============= file zero until whole sector
times	510 - ($ - $$) db 0
	dw	0xaa55
