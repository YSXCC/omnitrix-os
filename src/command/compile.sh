#!bash

if [[ ! -d "../lib" || ! -d "../build" ]];then
    echo "dependent dir don\`t exist!"
    cwd=$(pwd)
    cwd=${cwd##*/}
    cwd=${cwd%/}
    if [[ $cwd != "command" ]];then
        echo -e "you\`d better in command dir\n"
    fi 
    exit
fi

BIN="cat"
AR="i686-elf-ar"
GCC="i686-elf-gcc"
CFLAGS=" -Wall -m32 -fno-stack-protector -c -fno-builtin -W -Wstrict-prototypes -Wmissing-prototypes -ffreestanding"
LIBS="-I ../lib/ -I ../lib/kernel/ -I ../lib/user/ -I \
      ../kernel/ -I ../device/ -I ../thread/ -I \
      ../userprog/ -I ../fs/ -I ../shell/"
OBJS="../build/string.o ../build/syscall.o \
      ../build/stdio.o ../build/assert.o start.o"
DD_IN=$BIN
DD_OUT="/home/ysxcc/omnitrix/omnitrix.img" 

nasm -f elf ./start.asm -o ./start.o
$AR -rcs crt.a $OBJS
$GCC $CFLAGS $LIBS -o $BIN".o" $BIN".c"
$GCC -nostdlib -ffreestanding -lgcc $BIN".o" crt.a -o $BIN

SEC_CNT=$(ls -l $BIN|awk '{printf("%d", ($5+511)/512)}')

if [[ -f $BIN ]];then
    dd if=./$DD_IN of=$DD_OUT bs=512 \
    count=$SEC_CNT seek=300 conv=notrunc
fi