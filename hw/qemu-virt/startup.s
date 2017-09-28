@ -*- mode:asm -*-
.text
.align  4
.global _Reset
_Reset:
	LDR	SP, =stack_top
	BL 	main
	B 	.
