BOOT_ASM = $(wildcard ./*.asm)
BOOT_BIN  = $(patsubst %.asm, %.bin, $(BOOT_ASM))
AS	:= nasm
ASFLAGS = -I include/

all: $(BOOT_BIN)

# $@ 目标文件，$^ 所有的依赖文件，$< 第一个依赖文件
%.bin: %.asm
	$(AS) $(ASFLAGS) $< -o $@

.PHONY : all clean

clean:
	rm -f $(BOOT_BIN)