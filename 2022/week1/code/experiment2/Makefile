all: clean build mount_ update_ umount_


build:
	@echo -e "\E[1;35mbuild $<... \E[0m"
	nasm boot.asm -o boot.bin
	dd if=/dev/zero of=floppy.img bs=1024 count=1440
	dd if=boot.bin of=floppy.img bs=512 count=1 conv=notrunc
	nasm loader.asm -o loader.bin

clean:
	@echo -e "\E[1;35mclean $<... \E[0m"
	rm -rf boot.bin
	rm -rf floppy.img
	rm -rf loader.bin
	
qemu:
	qemu  -fda floppy.img  -boot a
	
debug:
	qemu  -fda floppy.img  -boot a -S -s &
	gdb 

update_:
	@echo -e "\E[1;35mupdate_ $<... \E[0m"
	sudo cp -r loader.bin /mnt/kernel
	# sudo touch /mnt/kernel/kernel.bin

mount_:
	@echo -e "\E[1;35mmount_ $<... \E[0m"
	sudo mount floppy.img /mnt/kernel

umount_:
	@echo -e "\E[1;35mumount_ $<... \E[0m"
	sudo umount /mnt/kernel