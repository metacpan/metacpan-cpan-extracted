#if PERL_VERSION >= 24

#define MY_PUSHBLOCK(cONtExT) cONtExT = cx_pushblock(CXt_EVAL|CXp_TRYBLOCK, G_VOID, PL_stack_sp, PL_savestack_ix)
#define MY_PUSHEVAL(cONtExT) cx_pusheval(cONtExT, PL_op, NULL)

#else

#define MY_PUSHBLOCK(cONtExT)\
	int gimme = G_VOID;\
	PUSHBLOCK(cONtExT, CXt_EVAL|CXp_TRYBLOCK, PL_stack_sp);

#define MY_PUSHEVAL(cONtExT) PUSHEVAL(cONtExT, NULL)

#define CX_POP(cONtExT) cxstack_ix--

#define CX_LEAVE_SCOPE(cx)\
	PMOP* pmop;\
	SV** newsp;\
	I32 optype;\
	POPEVAL(cx);\
	POPBLOCK(cx, pmop);

#endif

#define TRY \
	PERL_CONTEXT *cONtExT;\
	MY_PUSHBLOCK(cONtExT);\
	SAVEPPTR(PL_op);\
	PL_op = newOP(OP_NULL, 0);\
	SAVEFREEOP(PL_op);\
	MY_PUSHEVAL(cONtExT);\
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
