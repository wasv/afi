.text
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
/* PutStringSB - Prints a null terminated string.
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

