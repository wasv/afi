ENTRY(_Reset)
SECTIONS
{
 . = 0x10000;
 .text : { *(.text) }
 .data : { *(.data) }

 . = 0x40000000;
 .bss : { *(.bss COMMON) }
 . = ALIGN(8);
 . = . + 0x1000; /* 4kB of stack memory */
 stack_top = .;
}
