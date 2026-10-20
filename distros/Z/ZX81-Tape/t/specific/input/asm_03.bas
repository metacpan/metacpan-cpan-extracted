#ASM
start:
	ld hl, patch_line
	ld de, 6
	add hl, de
	ld (hl), 0x2d ; H
	inc hl
	ld (hl), 0x2a ; E
	inc hl
	ld (hl), 0x31 ; L
	inc hl
	ld (hl), 0x31 ; L
	inc hl
	ld (hl), 0x34 ; O
	inc hl
	ret
#ENDASM
	RAND USR &start
@patch_line:
	PRINT "XXXXX"
