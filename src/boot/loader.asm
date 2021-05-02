%include "boot.inc"
%include "gdt.inc"

ORG LOADER_BASE_ADDR
    
LOADER_STACK_TOP EQU LOADER_BASE_ADDR

    ; show 'LOADER'
    mov byte [gs:160+0],'L'
    mov byte [gs:160+1],0x07
    mov byte [gs:160+2],'O'
    mov byte [gs:160+3],0x07
    mov byte [gs:160+4],'A'
    mov byte [gs:160+5],0x07
    mov byte [gs:160+6],'D'
    mov byte [gs:160+7],0x07
    mov byte [gs:160+8],'E'
    mov byte [gs:160+9],0x07
    mov byte [gs:160+10],'R'
    mov byte [gs:160+11],0x07


    jmp set_protect_mode

;----------------------------------------
;   GDT相关信息
;   各段描述，GDT长度，载入的寄存器需要的数据
;   描述    -->   GDT_TABLE
;   长度    -->   GDT_LENGTH 
;   数据    -->   GDT_REG
;----------------------------------------
GDT_TABLE:
;GDT属性                            段基址       段界限       段属性
GDT_BASE:         Descriptor        0,          0,          0            ;空描述符
CODE_DESC:        Descriptor        0,          0xFFFFF,    DA_CODE32 
DATA_DESC:        Descriptor        0,          0xFFFFF,    DA_DATA
VIDEO_DESC:       Descriptor      0xB8000,      0x7,        DA_VIDEO 

GDT_LENGTH        EQU     $   -   GDT_TABLE

GDT_REG:
    dw  (GDT_LENGTH - 1)
    dd  GDT_TABLE

times 60 dq 0

SELECTOR_CODE      EQU     (0x0001 << 3) | TI_GDT | RPL_0
SELECTOR_DATA      EQU     (0x0002 << 3) | TI_GDT | RPL_0
SELECTOR_VIDEO     EQU     (0x0003 << 3) | TI_GDT | RPL_0

;----------------------------------------
;   设置保护模式代码
;   1、关中断
;   2、初始化GDT
;   3、开启A20地址线
;   4、设置CR0，确认为保护模式
;   5、远跳转，清空CPU流水线
;----------------------------------------
set_protect_mode:
    cli                     ; 关中断
    lgdt    [GDT_REG]       ; 初始化并加载GDT

    ; 开启A20地址线
    in al, 0x92
    or al, 0000_0010B
    out 0x92, al

    ; 设置CR0
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 远跳转清空CPU流水线
    jmp dword SELECTOR_CODE: protect_mode_start

[bits 32]
protect_mode_start:
    mov ax, SELECTOR_DATA       ;the data selector
    mov ds, ax 
    mov es, ax 
    mov ss, ax 
    mov esp, LOADER_STACK_TOP
    mov ax, SELECTOR_VIDEO    
    mov gs, ax
    mov byte [gs:160+14],'P'
    mov byte [gs:160+15],0x07

    jmp $
