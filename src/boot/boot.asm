%include "boot.inc"

ORG 0x7C00                      ;偏移地址CS:IP=0000:7C00

entry:
    mov ax, cs                  ; 初始化代码段和数据段
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax                  
    mov sp, BootStackTop
    mov ax, 0xb800
	mov gs, ax

    call clean_screen

    ; show 'BOOT'
    mov byte [gs:0],'B'
    mov byte [gs:1],0x07
    mov byte [gs:2],'O'
    mov byte [gs:3],0x07
    mov byte [gs:4],'O'
    mov byte [gs:5],0x07
    mov byte [gs:6],'T'
    mov byte [gs:7],0x07

    mov eax, LOADER_START_SECTOR
    mov bx, LOADER_BASE_ADDR
    mov cx, LOADER_SECTOR_COUNTS
    call read_disk_mode_16

    jmp LOADER_BASE_ADDR + 0x300    ; 因为在loader.bin前0x300存放了gdt和mem部分信息

;----------------------------------------
;   清屏函数,设置显示模式可清屏80*25  16色
;   input:  no
;   output: no
;----------------------------------------
clean_screen:
    mov ax, 0x02
    int 0x10
    ret

;----------------------------------------
;   在16位模式下读取硬盘
;   input:  
;         LOADER_START_SECTOR    --> eax
;         LOADER_BASE_ADDR       --> bx
;         LOADER_SECTOR_COUNTS   --> cx
;   output:
;         no
;----------------------------------------
read_disk_mode_16:
    mov esi,eax
    mov di,cx
    ;设置要读取的扇区数
    mov dx,0x1f2
    mov al,cl
    out dx,al            ;读取的扇区数

    mov eax,esi	         ;恢复ax

    ;将LBA地址存入0x1f3 ~ 0x1f6
    ;LBA地址7~0位写入端口0x1f3
    mov dx,0x1f3
    out dx,al

    ;LBA地址15~8位写入端口0x1f4
    mov cl,8
    shr eax,cl
    mov dx,0x1f4
    out dx,al

    ;LBA地址23~16位写入端口0x1f5
    shr eax,cl
    mov dx,0x1f5
    out dx,al

    shr eax,cl
    and al,0x0f	   ;lba第24~27位
    or al,0xe0	   ; 设置7～4位为1110,表示lba模式
    mov dx,0x1f6
    out dx,al

    ;向0x1f7端口写入读命令，0x20
    mov dx,0x1f7
    mov al,0x20                        
    out dx,al

    ;检测硬盘状态
.not_ready:
    ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
    nop
    in al,dx
    and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输，第7位为1表示硬盘忙
    cmp al,0x08
    jnz .not_ready	   ;若未准备好，继续等

;从0x1f0端口读数据
    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax	    ; di为要读取的扇区数，每次读入一个字，共需di*512/2次

    mov dx, 0x1f0
.go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2		  
    loop .go_on_read
    ret


times   510 - ($ - $$)    db 	0
db  0x55
db  0xAA