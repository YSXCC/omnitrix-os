#ifndef __KERNEL_DEBUG_H
#define __KERNEL_DEBUG_H
/**
 * @brief 内核错误(用于调试)
 * @param filename 文件名
 * @param line 行号
 * @param func 函数
 * @param condition 错误字符串
 */ 
void panic_spin(char* filename, int line, const char* func, const char* condition);

#define PANIC(...) panic_spin(__FILE__, __LINE__, __func__, __VA_ARGS__)

#ifdef NDEBUG
    #define ASSERT(CONDITION) ((void)0)
#else
    #define ASSERT(CONDITION)               \
            if (CONDITION) {}               \
            else {PANIC(#CONDITION);}
#endif  // _NDEBUG

#endif  // __KERNEL_DEBUG_H
