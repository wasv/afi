ENTRY(_Reset)
SECTIONS
{
 . = 0x10000;
 .text : { *(.text) }
 . = 0x40000000;
 .data : { *(.data) }
 .bss : { *(.bss COMMON) }
 . = ALIGN(8);
 . = . + 0x0800; /* 2kB of stack memory */
 stack_top = .;
}
