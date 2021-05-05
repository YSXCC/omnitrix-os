;------------------------------启动和加载代码的堆栈信息-------------------------------------------------;
BootStackTop                EQU	    0x7C00      ; Boot区栈顶
LoaderStack                 EQU     0xFFFF      ; Loader区堆栈段地址
SetupStack                  EQU     0xFFFF      ; Setup区堆栈段地址
;----------------------------------------------------------------------------------------------------;

LOADER_START_SECTOR         EQU     0x2         ; loader逻辑扇区号
LOADER_BASE_ADDR            EQU     0x900       ; loader写入的地址
LOADER_SECTOR_COUNTS        EQU     0x4         ; load默认占4个扇区,共2kb

;------------------------------内核代码的信息----------------------------------------------------------;
KERNEL_BASE_ADDRESS         EQU     0x70000     ; kernel.elf地址
KERNEL_START_SECTOR         EQU     0x9         ; 逻辑扇区编号，这里从9开始（个人心情）
KERNEL_SECTOR_COUNTS        EQU     200         ; kernel.elf默认占200个扇区,共100kb
KERNEL_ENTRY_POINT          EQU     0xC0001500  ; 内核入口地址

PT_NULL                     EQU     0