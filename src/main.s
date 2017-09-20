@ --- Equates
.equ BUFF_LENGTH, 80
.text
.global main
main:
/* Prints ASCII characters from 0x21 (!) - 0x7A (z) over UART0
 */
        LDR   R0, =Buffer
		MOVS  R1, #0x00
		STRB  R1, [R0]
        MOVS  R1, #BUFF_LENGTH
     	BL    gets                    @ Advance to next character.
        BL    puts
        SUBS  R2, R2, #1              @ Decrement counter.
        MOVS  R0, #0x0D
        BL    putc
        MOVS  R0, #0x0A
        BL    putc
        B     main
        B     .

.bss
.align 4
Buffer:         .space  BUFF_LENGTH
