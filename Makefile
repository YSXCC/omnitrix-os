TOP_PATH = $(shell pwd)
BOOT_PATH = $(TOP_PATH)/src/boot
BUILD_PATH = $(TOP_PATH)/src/build

BOOT_BIN := $(BOOT_PATH)/boot.bin
LDR_BIN := $(BOOT_PATH)/loader.bin
KERNEL_ELF := $(BUILD_PATH)/kernel.elf

DD = dd
IMG := $(TOP_PATH)/omnitrix.img
# IMG := $(TOP_PATH)/hd60M.img

LOADER_LOGICAL_SECTOR   =     2
# load默认占4个扇区,共2kb
LOADER_SECTOR_COUNTS    =     4

# 逻辑扇区编号 这里从9开始（个人心情）
KERNEL_LOGICAL_SECTOR   =     9
# kernel.elf默认占200个扇区,共100kb
KERNEL_SECTOR_COUNTS    =     200

all: binary
	$(DD) if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(LDR_BIN) of=$(IMG) bs=512 count=$(LOADER_SECTOR_COUNTS) seek=$(LOADER_LOGICAL_SECTOR) conv=notrunc
	$(DD) if=$(KERNEL_ELF) of=$(IMG) bs=512 count=$(KERNEL_SECTOR_COUNTS) seek=$(KERNEL_LOGICAL_SECTOR) conv=notrunc

binary:
	$(MAKE) -C src/boot
	$(MAKE) -C src all

.PHONY: clean bochs

bochs:
	bochs -q -f bochs/bochsrc-linux

clean:
	$(MAKE) -C src/boot clean
	$(MAKE) -C src clean