#ASM
	ld hl, hello
loop:
	ld a, (hl)
	inc a
	ret z
	
	dec a
	rst 0x10
	inc hl
	jr loop
hello:
	defm "HELLO", 0xFF
#ENDASM
	RAND USR 0x4082
