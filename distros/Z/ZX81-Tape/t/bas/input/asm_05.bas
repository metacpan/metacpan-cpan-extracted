#ASM
print_hello:
	ld hl, hello
loop:
	ld a, (hl)
	inc a
	ret z
	
	dec a
	rst 0x10
	inc hl
	jr loop
#ENDASM
	RAND USR &print_hello

#ASM
hello:
	defm "HELLO", 0xFF
#ENDASM
