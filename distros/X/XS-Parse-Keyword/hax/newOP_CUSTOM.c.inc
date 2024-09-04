/* vi: set ft=c : */

/* Before perl 5.22 under -DDEBUGGING, various new*OP() functions throw assert
 * failures on OP_CUSTOM.
 *   https://rt.cpan.org/Ticket/Display.html?id=128562
 */

#define newOP_CUSTOM(func, flags)                    S_newOP_CUSTOM(aTHX_ func, flags)
#define newUNOP_CUSTOM(func, flags, first)           S_newUNOP_CUSTOM(aTHX_ func, flags, first)
#if HAVE_PERL_VERSION(5, 22, 0)
#  define newUNOP_AUX_CUSTOM(func, flags, first, aux)  S_newUNOP_AUX_CUSTOM(aTHX_ func, flags, first, aux)
#endif
#define newSVOP_CUSTOM(func, flags, sv)              S_newSVOP_CUSTOM(aTHX_ func, flags, sv)
#define newBINOP_CUSTOM(func, flags, first, last)    S_newBINOP_CUSTOM(aTHX_ func, flags, first, last)
#define newLISTOP_CUSTOM(func, flags, first, last)   S_newLISTOP_CUSTOM(aTHX_ func, flags, first, last)
#define newLOGOP_CUSTOM(func, flags, first, other)   S_newLOGOP_CUSTOM(aTHX_ func, flags, first, other)

static OP *S_newOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags)
{
  OP *op = newOP(OP_CUSTOM, flags);
  op->op_ppaddr = func;
  return op;
}

static OP *S_newUNOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first)
{
  UNOP *unop;
#if HAVE_PERL_VERSION(5,22,0)
  unop = (UNOP *)newUNOP(OP_CUSTOM, flags, first);
#else
  NewOp(1101, unop, 1, UNOP);
  unop->op_type = (OPCODE)OP_CUSTOM;
  unop->op_first = first;
  unop->op_flags = (U8)(flags | OPf_KIDS);
  unop->op_private = (U8)(1 | (flags >> 8));
#endif
  unop->op_ppaddr = func;
  return (OP *)unop;
}

#if HAVE_PERL_VERSION(5, 22, 0)
static OP *S_newUNOP_AUX_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, UNOP_AUX_item *aux)
{
  UNOP_AUX *unop;
#if HAVE_PERL_VERSION(5,22,0)
  unop = (UNOP_AUX *)newUNOP_AUX(OP_CUSTOM, flags, first, aux);
#else
  croak("TODO: create newUNOP_AUX_CUSTOM");
#endif
  unop->op_ppaddr = func;
  return (OP *)unop;
}
#endif

static OP *S_newSVOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, SV *sv)
{
  SVOP *svop;
#if HAVE_PERL_VERSION(5,22,0)
  svop = (SVOP *)newSVOP(OP_CUSTOM, flags, sv);
#else
  NewOp(1101, svop, 1, SVOP);
  svop->op_type = (OPCODE)OP_CUSTOM;
  svop->op_sv = sv;
  svop->op_next = (OP *)svop;
  svop->op_flags = 0;
  svop->op_private = 0;
#endif
  svop->op_ppaddr = func;
  return (OP *)svop;
}

static OP *S_newBINOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *last)
{
  BINOP *binop;
#if HAVE_PERL_VERSION(5,22,0)
  binop = (BINOP *)newBINOP(OP_CUSTOM, flags, first, last);
#else
  NewOp(1101, binop, 1, BINOP);
  binop->op_type = (OPCODE)OP_CUSTOM;
  binop->op_first = first;
  first->op_sibling = last;
  binop->op_last = last;
  binop->op_flags = (U8)(flags | OPf_KIDS);
  binop->op_private = (U8)(2 | (flags >> 8));
#endif
  binop->op_ppaddr = func;
  return (OP *)binop;
}

static OP *S_newLISTOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *last)
{
  LISTOP *listop;
#if HAVE_PERL_VERSION(5,22,0)
  listop = (LISTOP *)newLISTOP(OP_CUSTOM, flags, first, last);
#else
  NewOp(1101, listop, 1, LISTOP);
  listop->op_type = (OPCODE)OP_CUSTOM;
  listop->op_first = first;
  if(first)
    first->op_sibling = last;
  listop->op_last = last;
  listop->op_flags = (U8)(flags | OPf_KIDS);
  if(last)
    listop->op_private = (U8)(2 | (flags >> 8));
  else if(first)
    listop->op_private = (U8)(1 | (flags >> 8));
  else
    listop->op_private = (U8)(flags >> 8);
#endif
  listop->op_ppaddr = func;
  return (OP *)listop;
}

static OP *S_newLOGOP_CUSTOM(pTHX_ OP *(*func)(pTHX), U32 flags, OP *first, OP *other)
{
  OP *o;
#if HAVE_PERL_VERSION(5,22,0)
  o = newLOGOP(OP_CUSTOM, flags, first, other);
#else
  /* Parts of this code copypasted from perl 5.20.0's op.c S_new_logop()
   */
  LOGOP *logop;

  first = op_contextualize(first, G_SCALAR);

  NewOp(1101, logop, 1, LOGOP);

  logop->op_type = (OPCODE)OP_CUSTOM;
  logop->op_ppaddr = NULL; /* Because caller only overrides it anyway */
  logop->op_first = first;
  logop->op_flags = (U8)(flags | OPf_KIDS);
  logop->op_other = LINKLIST(other);
  logop->op_private = (U8)(1 | (flags >> 8));

  /* Link in postfix order */
  logop->op_next = LINKLIST(first);
  first->op_next = (OP *)logop;
  first->op_sibling = other;

  /* No CHECKOP for OP_CUSTOM */
  o = newUNOP(OP_NULL, 0, (OP *)logop);
  other->op_next = o;
#endif

  /* the returned op is actually an UNOP that's either NULL or NOT; the real
   * logop is the op_next of it
   */
  cUNOPx(o)->op_first->op_ppaddr = func;

  return o;
}
