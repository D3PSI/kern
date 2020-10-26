CP := cp
RM := rm -rf
MKDIR := mkdir -pv

BIN = kern
CFG = grub.cfg
ISO_PATH := iso
BOOT_PATH := $(ISO_PATH)/boot
GRUB_PATH := $(BOOT_PATH)/grub

.PHONY: all
all: bootloader kern linker iso
	@echo kernOS has successfully been built 

bootloader: boot.asm
	nasm -f elf32 boot.asm -o boot.o

kern: kern.c
	gcc -m32 -c kern.c -o kern.o

linker: linker.ld boot.o kern.o
	ld -m elf_i386 -T linker.ld -o kern boot.o kern.o

iso: kern
	$(MKDIR) $(BOOT_PATH)
	$(MKDIR) $(GRUB_PATH)
	$(CP) $(BIN) $(BOOT_PATH)
	$(CP) $(CFG) $(GRUB_PATH)
	grub-file --is-x86-multiboot $(BOOT_PATH)/$(BIN)
	grub-mkrescue -o kern.iso $(ISO_PATH)

.PHONY: clean
clean:
	$(RM) *.o $(BIN) *iso
