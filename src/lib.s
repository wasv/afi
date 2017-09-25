.include            "src/macros.i"

    defvar "LATEST",6,,LATEST,name_WORD
    .global var_S0
    defvar "S0",2,,SZ

    defconst "R0",2,,RZ,return_stack_top

.text

/* Read, lookup, and execute each word. */
    defcode "INTERPRET",9,,INTERPRET
1:  // Read and lookup codeword.
    BL      _WORD       // Read word.
    BL      _FIND       // Find in dictionary
    TST     R0,R0       // Check if found
    BEQ     2f          // If not found, check if literal.

    // Translate and execute codeword.
    BL      _TCFA       // Translate to codeword
    ADD     R0,R0,#8
    LDR     R1,[R0]
    BX      R1          // Execute.

2:  // Literal?
    BL      _NUMBER     // Translate word to number.
    TST     R5,R5       // Test if valid number was found.
    BNE     3f          // Error if not.

    // Execute literal
    PUSH   {R0}
    NEXT

3:  // Error: Invalid word.
    MOV     R0,#'!'
    BL      _EMIT
    B       1b

/* Used to quit to interpreter within a Forth word. */
    .global QUIT
    defword "QUIT",4,,QUIT
    .int RZ,RSPSTORE        // clear the return stack
    .int INTERPRET          // interpret the next word
    .int BRANCH,-8          // and loop (indefinitely)

/* Replace the return stack pointer with the top value of the stack */
    defcode "RSP!",4,,RSPSTORE
    POP    {R6}
    NEXT

/* Increment the top of the stack by 4. */
    defcode "4+",2,,INCR4
    POP    {R0}
    ADD     R0,R0,#4
    PUSH   {R0}
    NEXT

/* Drop top of the stack. */
    defcode "DROP",4,,DROP
    POP    {R0}
    NEXT

/* Swap top two elements fo the stack. */
    defcode "SWAP",4,,SWAP
    POP    {R0}
    POP    {R1}
    PUSH   {R0}
    PUSH   {R1}
    NEXT

/* Duplicate top of the stack. */
    defcode "DUP",3,,DUP
    LDR     R0,[SP]
    PUSH   {R0}
    NEXT

/* Copy second item of stack onto top of stack. */
    defcode "OVER",4,,OVER
    LDR     R0,[SP,#4]
    PUSH   {R0}
    NEXT

/* Rotate the top three values on the stack. */
    defcode "ROT",3,,ROT
    POP    {R0}
    POP    {R1}
    POP    {R2}

    PUSH   {R1}
    PUSH   {R0}
    PUSH   {R2}
    NEXT

/* Rotate the top three values on the stack. */
    defcode "-ROT",4,,NROT
    POP    {R0}
    POP    {R1}
    POP    {R2}

    PUSH   {R0}
    PUSH   {R2}
    PUSH   {R1}
    NEXT

/* Add 1st value on stack to 2nd. Then push the result. */
    defcode "+",1,,ADD
    POP {R0}
    POP {R1}
    ADD R1,R0,R1
    PUSH {R1}
    NEXT

/* Subtract 1st value on stack to 2nd. Then push the result. */
    defcode "-",1,,SUB
    POP {R0}
    POP {R1}
    SUB R1,R1,R0
    PUSH {R1}
    NEXT

/* Multiply the 1st value on stack by 2nd. Then push the result. */
    defcode "*",1,,MUL
    POP {R0}
    POP {R1}
    MUL R1,R0,R1
    PUSH {R1}
    NEXT

/* Jump a certain offset away from current codeword pointer */
    defcode "BRANCH",6,,BRANCH
    LDR     R0, [R7]
    ADD     R7, R7, R0
    NEXT

/* Branch only if top of stack is zero. */
    defcode "0BRANCH",7,,ZBRANCH
    POP    {R0}
    TST     R0, R0
    BEQ     code_BRANCH
    ADD     R7, R7, #4
    NEXT

/* Starts the execution of a Forth word. */
.global DOCOL
DOCOL:
    PUSHRSP R7
    ADD     R0, R0, #4
    MOV     R7, R0
    NEXT

/* Convert a codeword pointer to a pointer to the first data field.
 * Requires:
 *  (1) - Pointer to a dictionary entry.
 * Returns:
 *  (1) - Pointer to the corresponding codeword.
 */
    defword ">DFA",4,,TDFA
    .int TCFA               // >CFA         (get code field address)
    .int INCR4              // 4+           (add 4 to it to get to next word)
    .int EXIT               // EXIT         (return from FORTH word)

/* Convert a dictionary entry pointer to codeword pointer.
 * Requires:
 *  R0 - Pointer to a dictionary entry.
 * Returns:
 *  R0 - Pointer to the corresponding codeword.
 */
    defcode ">CFA",4,,TCFA
    POP    {R0}
    BL      _TCFA
    PUSH   {R0}
    NEXT

_TCFA:
    PUSH   {LR}
    MOV     R1,#0
    ADD     R0,R0,#4
    LDRB    R1,[R5]
    ADD     R0,R0,#1
    MOV     R2,#(F_HIDDEN|F_LENGTH)
    AND     R2,R1,R2
    ADD     R0,R0,R2

    ADD     R0,R0,#3
    MVN     R2,#3
    AND     R0,R0,R2
    POP    {PC}

/* Matches a string to the corresponding dictionary entry.
 * Requires:
 *  (1) R5 - length of string.
 *  (2) R4 - Addresss of string.
 * Returns:
    (1) R0 - Address of dictionary entry.
 */
    defcode "FIND",4,,FIND
    POP    {R5}                 // length of string
    POP    {R4}                 // address of string
    BL      _FIND
    PUSH   {R0}                 // Address of dictionary entry
    NEXT

.global _FIND
_FIND:
    PUSH   {LR}
    PUSH   {R6}                 // Need an extra register.
    LDR     R0,=var_LATEST
    LDR     R0,[R0]             // Load head of dictionary linked list.

1:  TST     R0,R0               // Check if 0 (end of Linked List)
    BEQ     4f

    LDRB    R1,[R0,#OFF_FLAG]   // R1 holds flag byte for entry
    MOV     R2,#(F_HIDDEN|F_LENGTH)
    AND     R1,R1,R2
    CMP     R1,R5
    BNE     3f

    SUB     R3,R5,#1
    ADD     R6,R0,#OFF_NAME

2:
    LDRB    R1,[R6,R3]          // Load character of entry name.
    LDRB    R2,[R4,R3]          // Load character of search name.
    CMP     R1,R2               // If mismatch, try next entry.
    BNE     3f

    SUBS    R3,R3,#1            // Decrement character count
    BLT     5f                  // If no characters left, it's a match!
    B       2b                  // If not done, keep checking.

3:
    LDR     R0,[R0]             // Advance to next entry
    B       1b

4:  // Not found.
    MOV     R0,#0

5:  // Return
    POP    {R6}
    POP    {PC}

/* Prints the top of the stack with a newline.
 * Requires:
 *  (1) R0 - Number to print. (preserved)
 */
    defword ".",1,,DOT
    .int DUP
    .int TD
    .int CR
    .int EXIT

/* Prints the top of the stack with a newline.
 * Requires:
 *  (1) R0 - Number to print. (preserved)
 */
    defword ".H",2,,DOTX
    .int DUP
    .int TH
    .int CR
    .int EXIT

/* Prints the word on top of the stack as a base 16 number.
 * Requires:
 *  (1) R0 - Number to print.
 */
    defcode ">H",2,F_HIDDEN,TH
    POP     {R0}
    BL      _TH
    BL      puts
    NEXT

.global _TH
_TH:
    PUSH   {LR}
    MOV     R2,R0
    MOV     R1,#0
    LDR     R0,=hexstr
    LDR     R3,=hextbl
1:  // Start of conversion loop
    MOV     R4,#0x0f    // Mask out current nibble.
    ROR     R2,R2,#28
    AND     R4,R2,R4

    LDRB    R4,[R3,R4]  // Lookup nibble in hextbl
    STRB    R4,[R0,R1]  // Store result in hexstr.

    ADD     R1,R1,#1    //Advance to next nibble.
    CMP     R1,#8
    BNE     1b
    POP    {PC}


.bss
hexstr:
    .space 8

    .section .rodata
hextbl:
        .ascii "0123456789ABCDEF"

/* Prints the word on top of the stack as a base 10 number.
 * Requires:
 *  (1) R0 - Number to print.
 */
    defcode ">D",2,F_HIDDEN,TD
    POP     {R0}
    BL      _TD
    BL      puts
    NEXT

.global _TD
_TD:
    PUSH   {LR}
    LDR     R3,=decstr
    MOV     R4,#0x80
    LSL     R4,R4,#24           // Make sign bit mask.
    ANDS    R4,R0,R4            // Check for negative.
    NEGNE   R0,R0

    MOV     R2,#10
1:  // Start of conversion loop
    BL      _DIV10              // Divides R0 by 10,
                                //  stores remainder in R1.

    ADD     R1,R1,#'0'          // R1 = R1 + '0'
    STRB    R1,[R3,R2]          // Store result in hexstr.

    TST     R0,R0               // Is R0 0?
    BEQ     2f                  // If so, finish.

    SUBS    R2,R2,#1            // Advance to next digit.
    BGE     1b

2:  MOV     R1,#'+'             // First character is sign.
    TST     R4,R4
    MOVNE   R1,#'-'             // If negative, replace sign.
    SUB     R2,R2,#1            // Advance to next digit.
    STRB    R1,[R3,R2]          // Store sign.

    ADD     R0,R3,R2
    RSB     R1,R2,#12           // len = 10 - R2

    POP    {PC}

.bss
decstr:
    .space 12

/* Reads a base 10 number from stdin.
 * Requires:
 *  (1) R5 - Length of string to read.
 *  (2) R4 - Start address of string.
 * Returns:
 *  (2) R0 - Number read.
 *  (1) R5 - Number of unparsed characters.
 */
    defcode "NUMBER",6,,NUMBER
    POP    {R5}                 // length of string
    POP    {R4}                 // start address of string
    BL      _NUMBER
    PUSH   {R0}                 // number read
    PUSH   {R5}                 // number of unparsed characters (0 = no error)
    NEXT

.global _NUMBER
_NUMBER:
    // Init
    PUSH   {LR}
    TST     R5,R5               // Is Length 0? If so, return.
    BEQ     4f

    MOV     R0,#0               // Push zero onto stack
    PUSH   {R0}

    // Check for negative.
    LDRB    R1,[R4],#1
    CMP     R1,#'-'             // Is number negative?
    BNE     2f                  // If not, start parsing.

    POP    {R0}                 // If negative, take zero off stack...
    PUSH   {R1}                 // And push a non-zero value to indicate negative.

    SUBS    R5,R5,#1            // Decrement character count...
    BNE     1f                  // And start parsing (if not already at end).

    MOV     R5,#1               // If at end already, indicate error...
    B       4f                  // And return.

1:  // Read next character
    MOV     R1,#10              // Multiply current value by 10.
    MOV     R3,R0
    MUL     R0,R3,R1

    LDRB    R1,[R4],#1          // Read next character into R1.

2:  // Parse character
    SUBS    R1,R1,#'0'          // Subtract 0x30 (ASCII '0') from R1.
    BLT     3f                  // If negative, out of bounds. Return.
    CMP     R1,#10              // Check if greater R1 greater than 10.
    BGT     3f                  // If so, out of bounds. Return.

    ADD     R0,R0,R1
    SUBS    R5,R5,#1
    BNE     1b

3:  // Negate and exit.
    POP    {R1}                 // Check if top of stack is zero.
    TST     R1,R1
    NEGNE   R0,R0               // Negate result if zero.

4:  POP    {PC}                 // Return


/* Divide by 10, without hardware division.
 * Bitshifting method courtesy of:
 *  https://stackoverflow.com/questions/5558492/divide-by-10-using-bit-shifts
 *    and
 *  http://www.hackersdelight.org/divcMore.pdf
 * Actually divides by 0.0999999999767. Accurate up to ~1*10^8.
 * Requires:
 * (1) R0 - Value to divide.
 * Returns:
 * (1) R0 - Result of division.
 * (2) R1 - Remainder of division.
 */
    defcode "/10",3,,DIV10
    POP    {R0}
    BL      _DIV10
    PUSH   {R1}
    PUSH   {R0}
    NEXT

.global _DIV10
_DIV10:
    PUSH   {LR}
    PUSH   {R2-R3}
    LSR     R1,R0,#1
    LSR     R2,R0,#2
    ADD     R1,R1,R2            // q=(n>>1)+(n>>2)   q=(3/4)*n

    LSR     R2,R1,#4
    ADD     R1,R1,R2            // q=q+(q>>4)        q=(17/16)*q

    LSR     R2,R1,#8
    ADD     R1,R1,R2            // q=q+(q>>8)        q=(257/256)*q

    LSR     R2,R1,#16
    ADD     R1,R1,R2            // q=q+(q>>16)       q=.799999999814*n

    LSR     R1,R1,#3            // q=(1/8)*q         q=.0999999999767*n

    LSL     R2,R1,#2
    ADD     R2,R2,R1
    LSL     R2,R2,#1            // r = q*10

    SUB     R2,R0,R2            // r = n - q*10 (r = remainder)

    ADD     R3,R2,#6
    LSRS    R3,R3,#4            // c = 1 if difference was > 9
    SUBNE   R2,R2,#10

    ADD     R0,R1,R3            // R0 = n/10.
    MOV     R1,R2               // R1 = n%10.

    POP    {R2-R3}
    POP    {PC}

/* Exits from a Forth word
 *
 */
    defcode "EXIT",4,,EXIT
    POPRSP  R7              // pop return stack into R7
    NEXT

/* Pushes a literal from the return stack onto the parameter stack.
 * Assumes that the next object in the return stack is a literal.
 * Returns:
 * (1) R0 - literal on top of the return stack.
 */
    defcode "LIT",3,,LIT
    LDR      R0,[R7],#4
    PUSH    {R0}            // push the literal number on to stack
    NEXT

/* Print a newline */
    defword "CR",2,,CR
    .int LIT,10,EMIT
    .int LIT,13,EMIT
    .int EXIT

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
    BL      getc      // Read character

    MOVS    R1,#0x20
    CMP     R0, R1
    BLT     1f        // Check lower ASCII bound
    MOVS    R1,#0x7F
    CMP     R0, R1
    BHS     1f        // Check upper ASCII bound

    BL      putc      // Echo character
1:
    POP    {R1}
    POP    {PC}

/*  Prints a character to stdout.
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
 *   Uses a static 32 byte buffer to store each word.
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
1:  // Seek to start of word.
    BL      _KEY            // Get character
    CMP     R0,#'\\'
    BEQ     3f
    CMP     R0,#0x0D        // Check for EOL.
    BEQ     4f
    CMP     R0,#' '         // Trim leading spaces.
    BEQ     1b

    LDR     R4,=word_buffer
    MOV     R5,#0
2:  // Read word by character.
    STR     R0,[R4,R5]      // Store character
    ADD     R5,R5,#1

    BL      _KEY            // Read next character
    CMP     R0,#'/'
    BEQ     3f
    CMP     R0,#0x0D        // Check for EOL.
    BEQ     4f
    CMP     R0,#' '         // Check for space.
    BEQ     5f

    B       2b

3:  // Seek to end of line for comments.
    BL      _KEY            // Read next character
    CMP     R0,#0x0D        // Check for EOL.
    BNE     3b

4:  // Print newline
    MOV     R0,#0x0A
    BL      _EMIT
    MOV     R0,#0x0D
    BL      _EMIT

5:  // Return
    POP     {PC}


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

        MOVS  R2,#0       // Init loop counter
        MOVS  R3, R0      // R3 points to start of string buffer
1:		// Start of gets loop
        BL    getc        // Read char into R0
        MOVS  R4,#0x0D
        CMP   R0, R4
        BEQ   2f          // If newline, return
        MOVS  R4,#0x20
        CMP   R0, R4
        BLT   1b          // Check lower ASCII bound
        MOVS  R4,#0x7F
        CMP   R0, R4
        BHS   1b          // Check upper ASCII bound
        CMP   R1, R2      // Check if index past buffer
        BLS   1b          // If so, dont echo or store
        BL    putc
        STRB  R0,[R3,R2]  // Store byte.
        ADDS  R2, R2,#1
        B     1b
2:		// End of gets loop
        MOVS  R0,#0
        STRB  R0,[R3,R2]  // Null terminate string
        MOVS  R0,#0x0D
        BL    putc        // Advance to next line
        MOVS  R0,#0x0A
        BL    putc        // Advance to next line
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

        ADDS  R1, R1, R0  // R1 Points to end of buffer
        MOVS  R2, R0      // R2 Points to start of string
1:		// Start of puts loop
        LDRB  R0,[R2, #0] // Load char from string
        TST   R0, R0
        BEQ   2f          // Break if char == 0
        BL    putc        // Else, print char
        ADDS  R2, R2, #1  // Increment counter
        CMP   R1, R2      // If at end of buffer, exit
        BHS   1b
2:      // End of puts loop
        POP  {R0-R2}
        POP  {PC}
