.include            "src/macros.i"
.include            "src/lib.s"
@ --- equates
.equ RETURN_STACK_SIZE, 1024

.text
.global afi_main
afi_main:
    LDR   R6, =return_stack_top //initialize return stack.
    LDR   R0, =var_S0
    STR   SP, [R0]
    LDR   R7, =cold_start
    NEXT

    .section .rodata
cold_start:
    .int QUIT

.bss
.align 10
return_stack:   .space  RETURN_STACK_SIZE
.global return_stack_top
return_stack_top:
