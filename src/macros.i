@ -*- mode:asm -*-
.macro NEXT
	LDR R0,[R7],#4
	BX  R0
.endm

.macro PUSHRSP reg
	SUB R6,R6,#4
	STR \reg,[R6]
.endm

.macro POPRSP reg
	LDR \reg,[R6]
	ADD R6,R6,#4
.endm

.set F_IMMED,0x80
.set F_HIDDEN,0x20
.set F_LENMASK,0x1f     // length mask

// Store the chain of links.
.set link,0

.macro defword name, namelen, flags=0, label
    .section .rodata
    .align 4
    .globl name_\label
name_\label :
    .int link               // link
    .set link,name_\label
    .byte \flags+\namelen   // flags + length byte
    .ascii "\name"          // the name
    .align 4                // padding to next 4 byte boundary
    .globl \label
\label :
    .int DOCOL              // codeword - the interpreter
    // list of word pointers follow
.endm

.macro defcode name, namelen, flags=0, label
    .section .rodata
    .align 4
    .globl name_\label
name_\label :
    .int link               // link
    .set link,name_\label
    .byte \flags+\namelen   // flags + length byte
    .ascii "\name"          // the name
    .align 4                // padding to next 4 byte boundary
    .globl \label
\label :
    .int code_\label        // codeword
    .text
    //.align 4
    .globl code_\label
code_\label :                   // assembler code follows
.endm
