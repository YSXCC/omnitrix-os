%include "boot.inc"
%include "gdt.inc"

ORG LOADER_BASE_ADDR
    
LOADER_STACK_TOP EQU LOADER_BASE_ADDR

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

times 60 dq 0

SELECTOR_CODE      EQU     (0x0001 << 3) | TI_GDT | RPL_0
SELECTOR_DATA      EQU     (0x0002 << 3) | TI_GDT | RPL_0
SELECTOR_VIDEO     EQU     (0x0003 << 3) | TI_GDT | RPL_0


total_mem_bytes dd 0        ; 此处偏移Loader.bin 0x200字节 物理地址为0xb00 占4字节

GDT_REG:                    ; 占48位 6字节
    dw  (GDT_LENGTH - 1)
    dd  GDT_TABLE

ards_buf times 244 db 0     ; ards结构体位置 手动对齐 占244字节
ards_nr  dw  0              ; ards结构体数 占2字节 在此以上至total_mem_bytes包括此共占256字节

loader_start:
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

    call get_memory_info        ;获取内存信息

    jmp set_protect_mode        ;设置保护模式 

;----------------------------------------
;   读取内存信息为之后分页做准备
;----------------------------------------
get_memory_info:
    xor ebx, ebx                ; 初始为0，后续会变化
    mov edx, 0534D4150h	        ; edx = 'SMAP' 循环中不会变化
    mov di, ards_buf            ; ards结构缓冲区
.e820_mem_get_loop:	            ; 循环获取每个ARDS内存范围描述结构
    mov eax, 0x0000e820	        ; 执行INT 0x15H后 eax的值会变为0x534D4150
    mov ecx, 20	                ; ARDS大小
    int 0x15
    jc .e820_failed_so_try_e801 ; 若cf位为1则有错误发生，尝试0xe801子功能
    add di, cx                  ; 使di增加20字节 地址向前移动
    inc word [ards_nr]          ; 记录ARDS数量
    cmp ebx, 0                  ; 若ebx为0且cf不为1,这说明ards全部返回，当前已是最后一个
    jnz .e820_mem_get_loop

;在所有ards结构中，找出(base_add_low + length_low)的最大值，即内存的容量。
    mov cx, [ards_nr]           ; 遍历每一个ARDS结构体,循环次数是ARDS的数量
    mov ebx, ards_buf 
    xor edx, edx                ; edx为最大的内存容量,在此先清0
.find_max_mem_area:             ; 无须判断type是否为1,最大的内存块一定是可被使用
    mov eax, [ebx]              ; base_add_low
    add eax, [ebx+8]            ; length_low
    add ebx, 20                 ; 指向缓冲区中下一个ARDS结构
    cmp edx, eax                ; 冒泡排序，找出最大,edx寄存器始终是最大的内存容量
    jge .next_ards
    mov edx, eax                ; edx为总内存大小
.next_ards:
    loop .find_max_mem_area
    jmp .mem_get_ok

;----------------------------------------
; int 15h ax = E801h 获取内存大小,最大支持4G
; 返回后, ax cx 值一样,以KB为单位,bx dx值一样
; 以64KB为单位,在ax和cx寄存器中为低16M在bx和
; dx寄存器中为16MB到4G。
;----------------------------------------
.e820_failed_so_try_e801:
    mov ax, 0xe801
    int 0x15
    jc .e801_failed_so_try88    ; 若当前e801方法失败,就尝试0x88方法

;1 先算出低15M的内存,ax和cx中是以KB为单位的内存数量,将其转换为以byte为单位
    mov cx, 0x400                ; cx和ax值一样,cx用做乘数
    mul cx 
    shl edx, 16
    and eax, 0x0000FFFF
    or edx, eax
    add edx, 0x100000           ; ax只是15MB,故要加1MB
    mov esi, edx                ; 先把低15MB的内存容量存入esi寄存器备份

;2 再将16MB以上的内存转换为byte为单位,寄存器bx和dx中是以64KB为单位的内存数量
    xor eax,eax
    mov ax,bx
    mov ecx, 0x10000            ; 0x10000十进制为64KB
    mul ecx                     ; 32位乘法,默认的被乘数是eax,积为64位,高32位存入edx,低32位存入eax.
    add esi, eax                ; 由于此方法只能测出4G以内的内存,故32位eax足够了
    mov edx, esi                ; edx为总内存大小
    jmp .mem_get_ok

;----------------------------------------
; int 15h ah = 0x88 获取内存大小
; 只能获取64M之内
;----------------------------------------
.e801_failed_so_try88: 
   ;int 15后，ax存入的是以kb为单位的内存容量
   mov  ah, 0x88
   int  0x15
   jc .error_hlt
   and eax, 0x0000FFFF
      
   ;16位乘法，被乘数是ax,积为32位.积的高16位在dx中，积的低16位在ax中
   mov cx, 0x400                ; 0x400等于1024,将ax中的内存容量换为以byte为单位
   mul cx
   shl edx, 16                  ; 把dx移到高16位
   or edx, eax                  ; 把积的低16位组合到edx,为32位的积
   add edx, 0x100000            ; 0x88子功能只会返回1MB以上的内存,故实际内存大小要加上1MB

.mem_get_ok:
    mov [total_mem_bytes], edx  ; 将内存换为byte单位后存入total_mem_bytes处。
    ret

.error_hlt:                     ; 出错则挂起
    hlt

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
