.include            "src/macros.i"
@ --- equates
.equ BUFF_LENGTH, 80
.equ RETURN_STACK_SIZE, 1024
.equ QUIT, main

.text
.global main
main:
    LDR   R6, =return_stack_top   @ intialize the return stack.
repl:
/* repl - tokenizes and executes the string in r0. */
    BL      _WORD
    MOV     R0,R4
    MOV     R1,R5
    BL      puts
    B       repl

DOCOL:
    PUSHRSP R7
    ADD     R0, R0, #0x04
    MOV     R0, R7
	NEXT

.section .rodata
cold_start:
    .int    QUIT

/*  Reads a character from stdin.
 *  Returns:
 *      R0 - character read.
 */
    defcode "KEY",3,,KEY
    BL      _KEY
    PUSH   {R0}
    NEXT
_KEY:   
    PUSH   {LR}
    PUSH   {R1}
    BL      getc      @ Read character

    MOVS    R1,#0x20
    CMP     R0, R1
    BLT     1f	      @ Check lower ASCII bound
    MOVS    R1,#0x7F
    CMP     R0, R1
    BHS     1f	      @ Check upper ASCII bound

    BL      putc      @ Echo character
1:
    POP    {R1}
    POP    {PC}

/*  Prints a character to stdin.
 *  Requires:
 *      R0 - character to print.
 */
    defcode "EMIT",4,,EMIT
    POP    {R0}
    BL      _EMIT
    NEXT
_EMIT:
    PUSH   {LR}
    BL      putc
    POP    {PC}

/*  Reads a word from stdin.
 *  Returns:
 *      R4 - address of word read.
 *      R5 - length of word read.
 */
    defcode "WORD",4,,WORD
    BL      _WORD
    PUSH   {R4,R5}
    NEXT
_WORD:
    PUSH {LR}
    LDR     R4,=word_buffer
    MOV     R5,#0
    STR     R5,[R4]
1:  @ Seek to start of word.
    BL      _KEY            @ Get character
    CMP     R0,#'/'
    BEQ     3f
    CMP     R0,#0x0D        @ Check for EOL.
    BEQ     4f
    CMP     R0,#' '         @ Trim leading spaces.
    BEQ     1b

    LDR     R4,=word_buffer
    MOV     R5,#0
2:  @ Read word by character.
    STR     R0,[R4,R5]      @ Store character
    ADD     R5,R5,#1

    BL      _KEY            @ Read next character
    CMP     R0,#'/'
    BEQ     3f
    CMP     R0,#0x0D        @ Check for EOL.
    BEQ     4f
    CMP     R0,#' '         @ Check for space.
    BEQ     5f

    B       2b

3:  @ Seek to end of line for comments.
    BL      _KEY            @ Read next character
    CMP     R0,#0x0D        @ Check for EOL.
    BNE     3b

4:  @ Print newline
    MOV     R0,#0x0A
    BL      _EMIT
    MOV     R0,#0x0D
    BL      _EMIT

5:  @ Return
    POP {PC}

.data
word_buffer:    .space  32

.bss
.align 10
return_stack:   .space  RETURN_STACK_SIZE
return_stack_top:
.align 4
buffer:         .space  BUFF_LENGTH
