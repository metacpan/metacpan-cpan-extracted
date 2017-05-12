/* Selected functions borrowed from perl's ext/Opcode/Opcode.xs */

/* PL_maxo shouldn't differ from MAXO but leave room anyway (see BOOT:)	*/
#define OP_MASK_BUF_SIZE (MAXO + 100)
#define opset_len   ((PL_maxo + 7) / 8)

static void
opmask_add(pTHX_ char *bitmask, STRLEN len)
{
    int i,j;
    int myopcode = 0;

    if (len != opset_len)
	croak("Invalid opset: wrong size");

    if (!PL_op_mask)		/* caller must ensure PL_op_mask exists	*/
	croak("Can't add to uninitialised PL_op_mask");

    /* OPCODES ALREADY MASKED ARE NEVER UNMASKED. See opmask_addlocal()	*/

    for (i=0; i < opset_len; i++) {
	U16 bits = bitmask[i];
	if (!bits) {	/* optimise for sparse masks */
	    myopcode += 8;
	    continue;
	}
	for (j=0; j < 8 && myopcode < PL_maxo; )
	    PL_op_mask[myopcode++] |= bits & (1 << j++);
    }
}

static void
opmask_addlocal(pTHX_ char *bitmask, STRLEN len, char *op_mask_buf)
{
    char *orig_op_mask = PL_op_mask;
    SAVEVPTR(PL_op_mask);
    PL_op_mask = &op_mask_buf[0];
    if (orig_op_mask)
	Copy(orig_op_mask, PL_op_mask, PL_maxo, char);
    else
	Zero(PL_op_mask, PL_maxo, char);
    opmask_add(aTHX_ bitmask, len);
}
