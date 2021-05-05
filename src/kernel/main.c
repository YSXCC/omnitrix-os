#include "init.h"
#include "print.h"
#include "memory.h"

int main() {
    put_str("Omnitrix\n");
    init_all();
    // asm volatile("sti");
    void* addr = get_kernel_pages(3);
    put_str("\n get_kernel_page start vaddr is ");
    put_int((uint32_t)addr);
    put_str("\n");
    while (1) {

    }
    return 0;
}