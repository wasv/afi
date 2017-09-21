.include            "src/macros.i"

.text

    defvar "STATE",5,,STATE
    defvar "HERE",4,,HERE
    defvar "LATEST",6,,LATEST,name_WORD // SYSCALL0 must be last in built-in dictionary
    defvar "S0",2,,SZ
    defvar "BASE",4,,BASE,10

.text
/* Starts the execution of a Forth word. */
.global DOCOL
DOCOL:
    PUSHRSP R7
    ADD     R0, R0, #0x04
    MOV     R0, R7
	NEXT

    defcode "NUMBER",6,,NUMBER
/* Reads a base 10 number from stdin.
 * Requires:
 *  (1) R5 - Length of string to read.
 *  (2) R4 - Start address of string.
 * Returns:
 *  (2) R0 - Number read.
 *  (1) R5 - Number of unparsed characters.
 */
    POP    {R5}                 @ length of string
    POP    {R4}                 @ start address of string
    BL      _NUMBER
    PUSH   {R0}                 @ number read
    PUSH   {R5}                 @ number of unparsed characters (0 = no error)
    NEXT

.global _NUMBER
_NUMBER:
    @ Init
    PUSH   {LR}
    TST     R5,R5               @ Is Length 0? If so, return.
    BEQ     4f

    MOV     R0,#0               @ Push zero onto stack
    PUSH   {R0}
    
    @ Check for negative.
    LDRB    R1,[R4],#1
    CMP     R1,#'-'             @ Is number negative?
    BNE     2f                  @ If not, start parsing.

    POP    {R0}                 @ If negative, take zero off stack...
    PUSH   {R1}                 @ And push a non-zero value to indicate negative.

    SUBS    R5,R5,#1            @ Decrement character count...
    BNE     1f                  @ And start parsing (if not already at end).

    MOV     R5,#1               @ If at end already, indicate error...
    B       4f                  @ And return.

1:  @ Read next character
    MOV     R1,#10              @ Multiply current value by 10.
    MOV     R3,R0
    MUL     R0,R3,R1

    LDRB    R1,[R4],#1          @ Read next character into R1.

2:  @ Parse character
    SUBS    R1,R1,#'0'          @ Subtract 0x30 (ASCII '0') from R1.
    BLT     3f                  @ If negative, out of bounds. Return.
    CMP     R1,#10              @ Check if greater R1 greater than 10.
    BGT     3f                  @ If so, out of bounds. Return.

    ADD     R0,R0,R1
    SUBS    R5,R5,#1
    BNE     1b
        
3:  @ Negate and exit.
    POP    {R1}                 @ Check if top of stack is zero.
    TST     R1,R1
    BEQ     4f                  @ If so, no need to negate.

    NEG     R0,R0               @ Negate

4:  POP    {PC}                 @ Return
    
        
 
    defcode "EXIT",4,,EXIT
/* Exits from a Forth word
 *
 */
    POPRSP  R7              @ pop return stack into R7
    NEXT

/* Pushes a literal from the return stack onto the parameter stack.
 * Assumes that the next object in the return stack is a literal.
 * Returns:
 * (1) R0 - literal on top of the return stack.
 */
    defcode "LIT",3,,LIT
    LDR      R0,[R7],#4
    PUSH    {R0}            @ push the literal number on to stack
    NEXT
    
/*  Reads a character from stdin.
 *  Returns:
 *  (1) R0 - character read.
 */
    defcode "KEY",3,,KEY
    BL      _KEY
    PUSH   {R0}
    NEXT

.global _KEY
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
 *  (1) R0 - character to print.
 */
    defcode "EMIT",4,,EMIT
    POP    {R0}
    BL      _EMIT
    NEXT

.global _EMIT
_EMIT:
    PUSH   {LR}
    BL      putc
    POP    {PC}

/*  Reads a word from stdin.
 *  Returns:
 *  (2) R4 - address of word read.
 *  (1) R5 - length of word read.
 */
    defcode "WORD",4,,WORD
    BL      _WORD
    PUSH   {R4}
    PUSH   {R5}
    NEXT

.global _WORD
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

.bss
.align 5
word_buffer:    .space  32

.text
/** String IO **/
.global gets
/* gets - Reads characters from UART, stored as a null terminated string
 * R0 - Pointer to string.
 * R1 - Max length of buffer.
 */
gets:
        PUSH {LR}
        PUSH {R0-R4}

        MOVS  R2,#0       @ Init loop counter
        MOVS  R3, R0      @ R3 points to start of string buffer
1:		@ Start of gets loop
		BL    getc     	  @ Read char into R0
        MOVS  R4,#0x0D
        CMP   R0, R4
        BEQ   2f		  @ If newline, return  
        MOVS  R4,#0x20
        CMP   R0, R4
        BLT   1b	      @ Check lower ASCII bound
        MOVS  R4,#0x7F
        CMP   R0, R4
        BHS   1b	      @ Check upper ASCII bound
        CMP   R1, R2      @ Check if index past buffer
        BLS   1b	      @ If so, dont echo or store
        BL    putc
        STRB  R0,[R3,R2]  @ Store byte.
        ADDS  R2, R2,#1
        B     1b
2:		@ End of gets loop
        MOVS  R0,#0
        STRB  R0,[R3,R2]  @ Null terminate string
        MOVS  R0,#0x0D
        BL    putc        @ Advance to next line
        MOVS  R0,#0x0A
        BL    putc        @ Advance to next line
        POP  {R0-R4}
        POP  {PC}

.global puts
puts:
/* Prints a null terminated string.
 * R0 - Pointer to string
 * R1 - Max length of buffer.
 */
        PUSH {LR}
        PUSH {R0-R2}

        ADDS  R1, R1, R0  @ R1 Points to end of buffer
        MOVS  R2, R0      @ R2 Points to start of string
1:		@ Start of puts loop
		LDRB  R0,[R2, #0] @ Load char from string
        TST   R0, R0
        BEQ   2f          @ Break if char == 0
        BL    putc		  @ Else, print char
        ADDS  R2, R2, #1  @ Increment counter
        CMP   R1, R2      @ If at end of buffer, exit
        BHS   1b
2:      @ End of puts loop
        POP  {R0-R2}
        POP  {PC}

