/* vi: set ft=c : */

struct logop_any {
  BASEOP
  OP *op_first;
  OP *op_other;
  ANY *op_any;
};

typedef struct logop_any LOGOP_ANY;

#define cLOGOP_ANYx(o)  ((LOGOP_ANY *)o)
#define cLOGOP_ANY      cLOGOP_ANYx(PL_op)
#define cLOGOP_ANYo     cLOGOP_ANYx(o)

#ifndef OpTYPE_set
#  define OpTYPE_set(op, type)         \
    STMT_START {                       \
      op->op_type   = (OPCODE)type;    \
      op->op_ppaddr = PL_ppaddr[type]; \
    } STMT_END
#endif

#define alloc_LOGOP_ANY(type, first, other)  MY_alloc_LOGOP_ANY(aTHX_ type, first, other)
static LOGOP_ANY *MY_alloc_LOGOP_ANY(pTHX_ I32 type, OP *first, OP *other)
{
  dVAR;
  LOGOP_ANY *logop;
  OP *kid = first;
  NewOp(1101, logop, 1, LOGOP_ANY);
  OpTYPE_set(logop, type);
  logop->op_first = first;
  logop->op_other = other;
  if (first)
    logop->op_flags = OPf_KIDS;
  while (kid && OpHAS_SIBLING(kid))
    kid = OpSIBLING(kid);
  if (kid)
    OpLASTSIB_set(kid, (OP*)logop);
  return logop;
}
