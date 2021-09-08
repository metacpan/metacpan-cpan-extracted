/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "infix.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "make_argcheck_ops.c.inc"
#include "newOP_CUSTOM.c.inc"

#if HAVE_PERL_VERSION(5,32,0)
#  define HAVE_OP_ISA
#endif

/* These only became full API macros at perl v5.22, but they're available as
 * the full Perl_... name before that
 */
#ifndef block_start
#  define block_start(a)         Perl_block_start(aTHX_ a)
#endif

#ifndef block_end
#  define block_end(a,b)         Perl_block_end(aTHX_ a,b)
#endif


#ifndef OpSIBLING
#  define OpSIBLING(op)  (op->op_sibling)
#endif

#ifndef OpMORESIB_set
#  define OpMORESIB_set(op,sib)  ((op)->op_sibling = (sib))
#endif

struct HooksAndData {
  const struct XSParseInfixHooks *hooks;
  void *data;
};

struct Registration;
struct Registration {
#ifdef HAVE_PL_INFIX_PLUGIN
  struct Perl_custom_infix def; /* must be first */
#endif

  struct Registration *next;
  struct XSParseInfixInfo info;

  STRLEN      oplen;
  enum XSParseInfixClassification cls;

  struct HooksAndData hd;

  STRLEN permit_hintkey_len;
};

static struct Registration *registrations;

static OP *new_op(pTHX_ const struct HooksAndData hd, U32 flags, OP *lhs, OP *rhs)
{
  if(hd.hooks->new_op)
    return (*hd.hooks->new_op)(aTHX_ flags, lhs, rhs, hd.data);

  OP *ret = newBINOP_CUSTOM(hd.hooks->ppaddr, flags, lhs, rhs);

  /* TODO: opchecker? */

  return ret;
}

#ifdef HAVE_PL_INFIX_PLUGIN
OP *parse(pTHX_ OP *lhs, struct Perl_custom_infix *def)
{
  struct Registration *reg = (struct Registration *)def;

  /* TODO: maybe operator has a 'parse' hook? */

  lex_read_space(0);
  OP *rhs = parse_termexpr(0);

  return new_op(aTHX_ reg->hd, 0, lhs, rhs);
}

static STRLEN (*next_infix_plugin)(pTHX_ char *, STRLEN, struct Perl_custom_infix **);

static STRLEN my_infix_plugin(pTHX_ char *op, STRLEN oplen, struct Perl_custom_infix **def)
{
  if(PL_parser && PL_parser->error_count)
    return (*next_infix_plugin)(aTHX_ op, oplen, def);

  HV *hints = GvHV(PL_hintgv);

  struct Registration *reg;
  for(reg = registrations; reg; reg = reg->next) {
    /* custom registrations have hooks, builtin ones do not */
    if(!reg->hd.hooks)
      continue;

    if(reg->oplen != oplen || !strEQ(reg->info.opname, op))
      continue;

    if(reg->hd.hooks->permit_hintkey &&
      (!hints || !hv_fetch(hints, reg->hd.hooks->permit_hintkey, reg->permit_hintkey_len, 0)))
      continue;

    if(reg->hd.hooks->permit &&
      !(*reg->hd.hooks->permit)(aTHX_ reg->hd.data))
      continue;

    *def = &reg->def;
    return oplen;
  }

  return (*next_infix_plugin)(aTHX_ op, oplen, def);
}
#endif

/* What classifications are included in what selections? */
static const U32 infix_selections[] = {
  [XPI_SELECT_ANY]       = 0xFFFFFFFF,

  [XPI_SELECT_PREDICATE] = (1<<XPI_CLS_PREDICATE)|(1<<XPI_CLS_RELATION)|(1<<XPI_CLS_EQUALITY),
  [XPI_SELECT_RELATION]  =                        (1<<XPI_CLS_RELATION)|(1<<XPI_CLS_EQUALITY),
  [XPI_SELECT_EQUALITY]  =                                              (1<<XPI_CLS_EQUALITY),

  [XPI_SELECT_ORDERING]  = (1<<XPI_CLS_ORDERING),

  [XPI_SELECT_MATCH_NOSMART] = (1<<XPI_CLS_EQUALITY)|(1<<XPI_CLS_MATCHRE)|(1<<XPI_CLS_ISA)|(1<<XPI_CLS_MATCH_MISC),
  [XPI_SELECT_MATCH_SMART]   = (1<<XPI_CLS_EQUALITY)|(1<<XPI_CLS_MATCHRE)|(1<<XPI_CLS_ISA)|(1<<XPI_CLS_MATCH_MISC)|
                                  (1<<XPI_CLS_SMARTMATCH),
};

bool XSParseInfix_parse(pTHX_ enum XSParseInfixSelection select, struct XSParseInfixInfo **infop)
{
  /* PL_parser->bufptr now points exactly at where we expect to find an operator name */

  int selection = infix_selections[select];

  HV *hints = GvHV(PL_hintgv);

  const char *buf = PL_parser->bufptr;
  const STRLEN buflen = PL_parser->bufend - PL_parser->bufptr;

  struct Registration *reg;
  for(reg = registrations; reg; reg = reg->next) {
    if(reg->oplen > buflen)
      continue;
    if(!strnEQ(buf, reg->info.opname, reg->oplen))
      continue;

    if(!(selection & (1 << reg->cls)))
      continue;

    if(reg->hd.hooks && reg->hd.hooks->permit_hintkey &&
      (!hints || !hv_fetch(hints, reg->hd.hooks->permit_hintkey, reg->permit_hintkey_len, 0)))
      continue;

    if(reg->hd.hooks && reg->hd.hooks->permit &&
      !(*reg->hd.hooks->permit)(aTHX_ reg->hd.data))
      continue;

    *infop = &reg->info;

    lex_read_to(PL_parser->bufptr + reg->oplen);
    return TRUE;
  }

  return FALSE;
}

OP *XSParseInfix_new_op(pTHX_ const struct XSParseInfixInfo *info, U32 flags, OP *lhs, OP *rhs)
{
  if(info->opcode == OP_CUSTOM)
    return new_op(aTHX_ (struct HooksAndData) {
        .hooks = info->hooks,
        .data  = info->hookdata,
      }, flags, lhs, rhs);

  return newBINOP(info->opcode, flags, lhs, rhs);
}

static OP *ckcall_wrapper_func(pTHX_ OP *op, GV *namegv, SV *ckobj)
{
  struct HooksAndData *hd = NUM2PTR(struct HooksAndData *, SvUV(ckobj));

  assert(op->op_type == OP_ENTERSUB);

  /* Attempt to extract the LHS and RHS operands, if we can find them */

  OP *kid = cUNOPx(op)->op_first;
  /* The first kid is usually an ex-list whose ->op_first begins the actual args list */
  if(kid->op_type == OP_NULL && kid->op_targ == OP_LIST)
    kid = cUNOPx(kid)->op_first;

  assert(kid->op_type == OP_PUSHMARK);
  OP *pushmark = kid;

  OP *left = OpSIBLING(kid);
  if(!left)
    return op;
  if(OP_GIMME(left, 0) != G_SCALAR)
    return op;

  OP *right = OpSIBLING(left);
  if(!right)
    return op;
  if(OP_GIMME(right, 0) != G_SCALAR)
    return op;

  kid = OpSIBLING(right);
  if(!kid)
    return op;
  if(OpSIBLING(kid))
    return op;

  /* Check that kid is now OP_NULL[ OP_GV ] */
  if(kid->op_type != OP_NULL || kid->op_targ != OP_RV2CV)
    return op;
  if(cUNOPx(kid)->op_first->op_type != OP_GV)
    return op;

  /* Splice out these two args and throw away the old optree */
  OpMORESIB_set(left, NULL);
  OpMORESIB_set(right, NULL);
  OpMORESIB_set(pushmark, kid);
  op_free(op);

  /* Now build a new optree */
  op = new_op(aTHX_ *hd, 0, left, right);
  return op;
}

static void make_wrapper_func(pTHX_ const struct HooksAndData *hd)
{
  /* Prepare to make a new optree-based CV */
  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  SV *funcname = newSVpvn(hd->hooks->wrapper_func_name, strlen(hd->hooks->wrapper_func_name));

  I32 save_ix = block_start(TRUE);

  OP *body = NULL;

  body = op_append_list(OP_LINESEQ, body,
      make_argcheck_ops(2, 0, 0, funcname));

  /* Body of the function is just  shift() OP shift() */
  body = op_append_list(OP_LINESEQ, body,
      new_op(aTHX_ *hd, 0, newOP(OP_SHIFT, OPf_SPECIAL), newOP(OP_SHIFT, OPf_SPECIAL)));

  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, funcname), NULL, NULL, body);

  cv_set_call_checker(cv, &ckcall_wrapper_func, newSVuv(PTR2UV(hd)));
}

static void reg_builtin(pTHX_ const char *opname, enum XSParseInfixClassification cls, OPCODE opcode)
{
  struct Registration *reg;
  Newx(reg, 1, struct Registration);

  reg->info.opname = savepv(opname);
  reg->info.opcode = opcode;
  reg->info.hooks  = NULL;

  reg->oplen  = strlen(opname);
  reg->cls    = cls;

  reg->hd.hooks = NULL;
  reg->hd.data  = NULL;

  reg->permit_hintkey_len = 0;

  {
    reg->next = registrations;
    registrations = reg;
  }
}

void XSParseInfix_register(pTHX_ const char *opname, const struct XSParseInfixHooks *hooks, void *hookdata)
{
  struct Registration *reg;
  Newx(reg, 1, struct Registration);

#ifdef HAVE_PL_INFIX_PLUGIN
  reg->def.parse = &parse;
#endif

  reg->info.opname = savepv(opname);
  reg->info.opcode = OP_CUSTOM;
  reg->info.hooks    = hooks;
  reg->info.hookdata = hookdata;

  reg->oplen  = strlen(opname);
  reg->cls    = hooks->cls;

  reg->hd.hooks = hooks;
  reg->hd.data  = hookdata;

  if(hooks->permit_hintkey)
    reg->permit_hintkey_len = strlen(hooks->permit_hintkey);
  else
    reg->permit_hintkey_len = 0;

  {
    reg->next = registrations;
    registrations = reg;
  }

  if(hooks->wrapper_func_name)
    make_wrapper_func(aTHX_ &reg->hd);
}

void XSParseInfix_boot(pTHX)
{
  /* stringy relations */
  reg_builtin(aTHX_ "eq", XPI_CLS_EQUALITY, OP_SEQ);
  reg_builtin(aTHX_ "ne", XPI_CLS_RELATION, OP_SNE);
  reg_builtin(aTHX_ "lt", XPI_CLS_RELATION, OP_SLT);
  reg_builtin(aTHX_ "le", XPI_CLS_RELATION, OP_SLE);
  reg_builtin(aTHX_ "ge", XPI_CLS_RELATION, OP_SGE);
  reg_builtin(aTHX_ "gt", XPI_CLS_RELATION, OP_SGT);
  reg_builtin(aTHX_ "cmp", XPI_CLS_ORDERING, OP_SCMP);

  /* numerical relations */
  reg_builtin(aTHX_ "==", XPI_CLS_EQUALITY, OP_EQ);
  reg_builtin(aTHX_ "!=", XPI_CLS_RELATION, OP_NE);
  reg_builtin(aTHX_ "<",  XPI_CLS_RELATION, OP_LT);
  reg_builtin(aTHX_ "<=", XPI_CLS_RELATION, OP_LE);
  reg_builtin(aTHX_ ">=", XPI_CLS_RELATION, OP_GE);
  reg_builtin(aTHX_ ">",  XPI_CLS_RELATION, OP_GT);
  reg_builtin(aTHX_ "<=>", XPI_CLS_ORDERING, OP_NCMP);

  /* other predicates */
  reg_builtin(aTHX_ "~~", XPI_CLS_SMARTMATCH, OP_SMARTMATCH);
  reg_builtin(aTHX_ "=~", XPI_CLS_MATCHRE, OP_MATCH);
  /* TODO: !~ */
#ifdef HAVE_OP_ISA
  reg_builtin(aTHX_ "isa", XPI_CLS_ISA, OP_ISA);
#endif

  /* TODO:
   * Other numerics
   *   + - * / % **
   *   << >>
   *
   * Bitwise
   *   & | ^
   * Stringwise
   *   &. |. ^.
   *
   * Boolean
   *   && || //
   */

  HV *stash = gv_stashpvs("XS::Parse::Infix", TRUE);
  newCONSTSUB(stash, "HAVE_PL_INFIX_PLUGIN", boolSV(
#ifdef HAVE_PL_INFIX_PLUGIN
      TRUE
#else
      FALSE
#endif
  ));

#ifdef HAVE_PL_INFIX_PLUGIN
  OP_CHECK_MUTEX_LOCK;
  if(!next_infix_plugin) {
    next_infix_plugin = PL_infix_plugin;
    PL_infix_plugin = &my_infix_plugin;
  }
  OP_CHECK_MUTEX_UNLOCK;
#endif
}
