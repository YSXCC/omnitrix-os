TOP_PATH = $(shell pwd)
SRC_PATH = $(TOP_PATH)/src
BIN_PATH = $(TOP_PATH)/src/build

export SRC_PATH
export BIN_PATH

BOOT_BIN := $(BIN_PATH)/boot.bin
LDR_BIN := $(BIN_PATH)/loader.bin

DD = dd
IMG := $(TOP_PATH)/omnitrix.img

LOADER_LOGICAL_SECTOR   =     2
# load默认占4个扇区,共2kb
LOADER_SECTOR_COUNTS    =     4

all: binary
	$(DD) if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	$(DD) if=$(LDR_BIN) of=$(IMG) bs=512 count=$(LOADER_SECTOR_COUNTS) seek=$(LOADER_LOGICAL_SECTOR) conv=notrunc

binary:
ifeq ($(BIN_PATH), $(wildcard $(BIN_PATH)))
	@echo  $(BIN_PATH) exist
else
	@echo "Create directory $(BIN_PATH)" 
	mkdir -p $(BIN_PATH)
endif
	$(MAKE) -C src/boot

.PHONY: clean bochs

bochs:
	bochs -q -f bochs/bochsrc-linux

clean:
	rm -rf $(BIN_PATH)
	$(MAKE) -C src/boot clean