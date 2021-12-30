#ifndef CX_LEAVE_SCOPE
#define CX_LEAVE_SCOPE(cx) LEAVE_SCOPE(cx->cx_u.cx_blk.blku_old_savestack_ix)
#endif

#define TRY \
	PERL_CONTEXT *cONtExT = cx_pushblock(CXt_EVAL|CXp_TRYBLOCK, G_VOID, PL_stack_sp, PL_savestack_ix);\
	SAVEPPTR(PL_op);\
	PL_op = newOP(OP_NULL, 0);\
	SAVEFREEOP(PL_op);\
	cx_pusheval(cONtExT, PL_op, NULL);\
	SAVEIV(PL_in_eval);\
	PL_in_eval = 1;\
	dJMPENV;\
	int rEtV = 0;\
	JMPENV_PUSH(rEtV);\
	if (rEtV == 0)

#define CATCH\
	JMPENV_POP;\
	CX_LEAVE_SCOPE(cONtExT);\
	if (rEtV == 0) {\
		CX_POP(cONtExT);\
	} else
