ENTRY(main)
SECTIONS
{
    . = 0xc0001500;
    .text : { *(.text) }
    .data : { *(.data) }
    .bss  : { *(.bss) }
}