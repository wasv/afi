@ --- equates
.equ RETURN_STACK_SIZE, 1024

.text
.global main
main:
    LDR   R6, =return_stack_top   @ intialize the return stack.
repl:
/* repl - tokenizes and executes the string in r0. */
    BL      _WORD
    BL      _NUMBER
    TST     R5,R5
    BNE     repl
    BL      _EMIT
    B       repl

.bss
.align 10
return_stack:   .space  RETURN_STACK_SIZE
return_stack_top:
