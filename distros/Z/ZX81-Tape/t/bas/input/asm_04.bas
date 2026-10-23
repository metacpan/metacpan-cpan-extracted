#ASM
start:
	ld hl, patch_line
	ld de, 6
	add hl, de
	ld (hl), 'H'
	inc hl
	ld (hl), 'E'
	inc hl
	ld (hl), 'L'
	inc hl
	ld (hl), 'L'
	inc hl
	ld (hl), 'O'
	inc hl
	ret
#ENDASM
	RAND USR &start
@patch_line:
	PRINT "XXXXX"
