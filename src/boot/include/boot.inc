;------------------------------启动和加载代码的堆栈信息-------------------------------------------------;
BootStackTop                EQU	    0x7C00  ;Boot区栈顶
LoaderStack                 EQU     0xFFFF  ;Loader区堆栈段地址
SetupStack                  EQU     0xFFFF  ;Setup区堆栈段地址
;----------------------------------------------------------------------------------------------------;

LOADER_START_SECTOR         EQU     0x2     ;loader逻辑扇区号
LOADER_BASE_ADDR            EQU     0x900   ;loader写入的地址
LOADER_SECTOR_COUNTS        EQU     0x4     ;load默认占4个扇区,共2kb