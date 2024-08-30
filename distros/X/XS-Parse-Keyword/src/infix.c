/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "infix.h"

#include "perl-backcompat.c.inc"
#include "optree-additions.c.inc"

#include "force_list_keeping_pushmark.c.inc"
#include "make_argcheck_ops.c.inc"
#include "newOP_CUSTOM.c.inc"
#include "op_sibling_splice.c.inc"

#if HAVE_PERL_VERSION(5,37,7)
#  define HAVE_PL_INFIX_PLUGIN
#endif

#if HAVE_PERL_VERSION(5,32,0)
#  define HAVE_OP_ISA
#endif

#if HAVE_PERL_VERSION(5,22,0)
   /* assert() can be used as an expression */
#  define HAVE_ASSERT_AS_EXPRESSION
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

#ifndef XS_INTERNAL
/* copypasta from perl-v5.16.0/XSUB.h */
#  if defined(__CYGWIN__) && defined(USE_DYNAMIC_LOADING)
#    define XS_INTERNAL(name) STATIC XSPROTO(name)
#  endif
#  if defined(__SYMBIAN32__)
#    define XS_INTERNAL(name) EXPORT_C STATIC XSPROTO(name)
#  endif
#  ifndef XS_INTERNAL
#    if defined(HASATTRIBUTE_UNUSED) && !defined(__cplusplus)
#      define XS_INTERNAL(name) STATIC void name(pTHX_ CV* cv __attribute__unused__)
#    else
#      ifdef __cplusplus
#        define XS_INTERNAL(name) static XSPROTO(name)
#      else
#        define XS_INTERNAL(name) STATIC XSPROTO(name)
#      endif
#    endif
#  endif
#endif

struct HooksAndData {
  const struct XSParseInfixHooks *hooks;
  void *data;
};

enum OperandShape {
  SHAPE_SCALARSCALAR,
  SHAPE_SCALARLIST,
  SHAPE_LISTLIST,
  SHAPE_LISTASSOC_SCALARS,
  SHAPE_LISTASSOC_LISTS,
};

static enum OperandShape operand_shape(const struct HooksAndData *hd)
{
  U8 lhs_gimme;
  switch(hd->hooks->lhs_flags & 0x07) {
    case 0:
      lhs_gimme = G_SCALAR;
      break;

    case XPI_OPERAND_TERM_LIST:
    case XPI_OPERAND_LIST:
      lhs_gimme = G_LIST;
      break;

    default:
      croak("TODO: Unsure how to classify operand shape of .lhs_flags=%02X\n",
          hd->hooks->lhs_flags & 0x07);
  }

  if(hd->hooks->flags & XPI_FLAG_LISTASSOC) {
    switch(lhs_gimme) {
      case G_SCALAR:
        return SHAPE_LISTASSOC_SCALARS;

      case G_LIST:
        return SHAPE_LISTASSOC_LISTS;
    }
  }

  U8 rhs_gimme;
  switch(hd->hooks->rhs_flags & 0x07) {
    case 0:
      rhs_gimme = G_SCALAR;
      break;

    case XPI_OPERAND_TERM_LIST:
    case XPI_OPERAND_LIST:
      rhs_gimme = G_LIST;
      break;

    default:
      croak("TODO: Unsure how to classify operand shape of .rhs_flags=%02X\n",
          hd->hooks->rhs_flags & 0x07);
  }

  switch((lhs_gimme << 4) | (rhs_gimme)) {
    /* scalar OP scalar */
    case (G_SCALAR<<4) | G_SCALAR:
      return SHAPE_SCALARSCALAR;

    /* scalar OP list */
    case (G_SCALAR<<4) | G_LIST:
      return SHAPE_SCALARLIST;

    /* list OP list */
    case (G_LIST<<4) | G_LIST:
      return SHAPE_LISTLIST;

    default:
      croak("TODO: Unsure how to classify operand shape of lhs_gimme=%d rhs_gimme=%d\n",
          lhs_gimme, rhs_gimme);
      break;
  }
}

struct Registration;
struct Registration {
#ifdef HAVE_PL_INFIX_PLUGIN
  struct Perl_custom_infix def; /* must be first */
#endif

  struct Registration *next;
  struct XSParseInfixInfo info;

  STRLEN      oplen;

  struct HooksAndData hd;

  STRLEN permit_hintkey_len;

  int opname_is_WIDE : 1;
  int opname_is_ident : 1;
  int opname_is_fq : 1;
};

static struct Registration *registrations,   /* for legacy-style global key-enabled ones */
                           *fqregistrations; /* for new lexically named ones */

static OP *new_op(pTHX_ const struct HooksAndData hd, U32 flags, OP *lhs, OP *rhs, SV **parsedata)
{
  if(hd.hooks->new_op) {
    if(hd.hooks->flags & (1<<15)) {
      OP *(*new_op_v1)(pTHX_ U32, OP *, OP *, void *) = (OP *(*)(pTHX_ U32, OP *, OP *, void *))hd.hooks->new_op;
      return (*new_op_v1)(aTHX_ flags, lhs, rhs, hd.data); /* no parsedata */
    }

    return (*hd.hooks->new_op)(aTHX_ flags, lhs, rhs, parsedata, hd.data);
  }

  assert(hd.hooks->ppaddr);

  OP *ret;
  if(hd.hooks->flags & XPI_FLAG_LISTASSOC) {
    OP *listop = lhs;
    /* Skip an ex-list + pushmark structure */
    if(listop->op_type == OP_NULL && cUNOPx(listop)->op_first &&
        cUNOPx(listop)->op_first->op_type == OP_PUSHMARK)
      listop = OpSIBLING(cUNOPx(listop)->op_first);

    if(listop &&
        listop->op_type == OP_CUSTOM && listop->op_ppaddr == hd.hooks->ppaddr &&
        !(listop->op_flags & OPf_PARENS)) {
      /* combine new operand with existing listop */
      if(listop->op_private == 255)
        croak("TODO: Unable to handle a list-associative infix operator with > 255 operands");

      OP *last = cLISTOPx(listop)->op_last;
      OpMORESIB_set(last, rhs);
      cLISTOPx(listop)->op_last = rhs;
      OpLASTSIB_set(rhs, listop);

      listop->op_private++;

      ret = lhs;
    }
    else {
      /* base case */
      ret = newLISTOP_CUSTOM(hd.hooks->ppaddr, flags, lhs, rhs);
      ret->op_private = 2;
    }
  }
  else
    ret = newBINOP_CUSTOM(hd.hooks->ppaddr, flags, lhs, rhs);

  /* TODO: opchecker? */

  return ret;
}

static bool op_extract_onerefgen(OP *o, OP **kidp)
{
  OP *first;
  switch(o->op_type) {
    case OP_SREFGEN:
      first = cUNOPo->op_first;
      if(first->op_type == OP_NULL && first->op_targ == OP_LIST &&
          (*kidp = cLISTOPx(first)->op_first))
        return TRUE;
      break;

    case OP_REFGEN:
      first = cUNOPo->op_first;
      if(first->op_type == OP_NULL && first->op_targ == OP_LIST &&
#ifdef HAVE_ASSERT_AS_EXPRESSION
          (assert(cLISTOPx(first)->op_first->op_type == OP_PUSHMARK), 1) &&
#endif
          (*kidp = OpSIBLING(cLISTOPx(first)->op_first)) &&
          !OpSIBLING(*kidp))
        return TRUE;

      op_dump(first);
  }

  return FALSE;
}

#define unwrap_list(o, may_unwrap_anonlist)  S_unwrap_list(aTHX_ o, may_unwrap_anonlist)
static OP *S_unwrap_list(pTHX_ OP *o, bool may_unwrap_anonlist)
{
  OP *kid;

  /* Look out for some sort of \THING */
  if(op_extract_onerefgen(o, &kid)) {
    if(kid->op_type == OP_PADAV) {
      /* \@padav can just yield the array directly */
      cLISTOPx(cUNOPo->op_first)->op_first = NULL;
      cLISTOPx(cUNOPo->op_first)->op_flags &= ~OPf_KIDS;
      op_free(o);

      kid->op_flags &= ~(OPf_MOD|OPf_REF);
      return force_list_keeping_pushmark(kid);
    }
    if(kid->op_type == OP_RV2AV) {
      /* we can just yield this op directly at this point. It might be \@pkgav
       * or something else, but whatever it is we might as well do it
       */
      cLISTOPx(cUNOPo->op_first)->op_first = NULL;
      cLISTOPx(cUNOPo->op_first)->op_flags &= ~OPf_KIDS;
      op_free(o);

      kid->op_flags &= ~(OPf_MOD|OPf_REF);
      return force_list_keeping_pushmark(kid);
    }
  }

  /* We might be permitted to unwrap a [THING] */
  if(may_unwrap_anonlist &&
      o->op_type == OP_ANONLIST) {
    /* Just turn it into a list and we're already done */
    o->op_type = OP_LIST;
    return force_list_keeping_pushmark(o);
  }

  return force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, o));
}

enum {
  FINDREG_SKIP_BUILTIN = (1<<0),
};

#define find_reg(op, oplen, regp, flags)  S_find_reg(aTHX_ op, oplen, regp, flags)
static STRLEN S_find_reg(pTHX_ const char *op, STRLEN oplen, struct Registration **regp, U32 flags)
{
  HV *hints = GvHV(PL_hintgv);

  /* New-style lexically named operators */
  {
    bool opname_is_ident = isIDFIRST_utf8_safe(op, op + oplen);

    SV *keysv = sv_newmortal();
    for(int len = oplen; len > 0; len--) {
      sv_setpvf(keysv, "XS::Parse::Infix/%.*s", len, op);
      HE *ophe = hv_fetch_ent(hints, keysv, 0, 0);
      if(!ophe && opname_is_ident)
        break;
      if(!ophe)
        continue;

      /* We found something suitable. Commit to this or fail */

      char *fqop     = SvPVX(HeVAL(ophe));
      STRLEN fqoplen = SvCUR(HeVAL(ophe));

      for(struct Registration *reg = fqregistrations; reg; reg = reg->next) {
        if(!reg->hd.hooks)
          continue;

        if(reg->oplen != fqoplen || !strEQ(reg->info.opname, fqop))
          continue;

        if(reg->hd.hooks->permit &&
          !(*reg->hd.hooks->permit)(aTHX_ reg->hd.data))
          continue;

        *regp = reg;
        return len;
      }

      croak("XS::Parse::Infix does not know of a registered infix operator named '%" SVf "'",
            SVfARG(HeVAL(ophe)));
    }
  }

  /* Legacy hinthash-enabled global operators */
  struct Registration *reg, *bestreg = NULL;
  for(reg = registrations; reg; reg = reg->next) {
    /* custom registrations have hooks, builtin ones do not */
    if((flags & FINDREG_SKIP_BUILTIN) && !reg->hd.hooks)
      continue;

    if(reg->oplen > oplen || !strnEQ(reg->info.opname, op, reg->oplen))
      continue;
    /* names like identifiers must match the whole length */
    if(reg->opname_is_ident && reg->oplen != oplen)
      continue;

    if(reg->hd.hooks && reg->hd.hooks->permit_hintkey &&
        (!hints || !hv_fetch(hints, reg->hd.hooks->permit_hintkey, reg->permit_hintkey_len, 0)))
      continue;

    if(reg->hd.hooks && reg->hd.hooks->permit &&
        !(*reg->hd.hooks->permit)(aTHX_ reg->hd.data))
      continue;

    /* This is a candidate and the best one, unless we already have something
     * longer
     */
    if(bestreg && bestreg->oplen > reg->oplen)
      continue;

    bestreg = reg;
  }

  if(!bestreg)
    return 0;

  *regp = bestreg;
  return bestreg->oplen;
}

#ifdef HAVE_PL_INFIX_PLUGIN

static void parse(pTHX_ SV **parsedata, struct Perl_custom_infix *def)
{
  struct Registration *reg = (struct Registration *)def;

  (*reg->hd.hooks->parse)(aTHX_ 0, parsedata, reg->hd.data);
}

static OP *build_op(pTHX_ SV **parsedata, OP *lhs, OP *rhs, struct Perl_custom_infix *def)
{
  struct Registration *reg = (struct Registration *)def;

  switch(reg->hd.hooks->lhs_flags & 0x07) {
    case 0:
      break;

    case XPI_OPERAND_TERM_LIST:
    case XPI_OPERAND_LIST:
      lhs = force_list_keeping_pushmark(lhs);
      break;
  }

  /* TODO: maybe operator has a 'parse' hook? */

  switch(reg->hd.hooks->rhs_flags & 0x07) {
    case 0:
      break;

    case XPI_OPERAND_TERM_LIST:
    case XPI_OPERAND_LIST:
      rhs = force_list_keeping_pushmark(rhs);
      break;
  }

  return new_op(aTHX_ reg->hd, 0, lhs, rhs, parsedata);
}

static STRLEN (*next_infix_plugin)(pTHX_ char *, STRLEN, struct Perl_custom_infix **);

static STRLEN my_infix_plugin(pTHX_ char *op, STRLEN oplen, struct Perl_custom_infix **def)
{
  if(PL_parser && PL_parser->error_count)
    return (*next_infix_plugin)(aTHX_ op, oplen, def);

  struct Registration *reg = NULL;
  STRLEN consumed = find_reg(op, oplen, &reg, FINDREG_SKIP_BUILTIN);
  if(!consumed)
    return (*next_infix_plugin)(aTHX_ op, oplen, def);

  *def = &reg->def;
  return consumed;
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

  const char *op = PL_parser->bufptr, *opend;

  if(isIDFIRST_utf8_safe(op, PL_parser->bufend)) {
    /* If the operator name is an identifer then we don't want to capture a
     * longer identifier from the incoming source of which this is just a
     * prefix
     */
    opend = op + UTF8SKIP(op);
    while(opend < PL_parser->bufend && isIDCONT_utf8_safe(opend, PL_parser->bufend))
      opend += UTF8SKIP(opend);
  }
  else {
    opend = PL_parser->bufend;
  }

  struct Registration *reg = NULL;
  STRLEN consumed = find_reg(op, opend - op, &reg, 0);
  if(!consumed)
    return FALSE;

  if(!(selection & (1 << reg->info.cls)))
    return FALSE;

  *infop = &reg->info;

  lex_read_to(PL_parser->bufptr + consumed);
  return TRUE;
}

OP *XSParseInfix_new_op(pTHX_ const struct XSParseInfixInfo *info, U32 flags, OP *lhs, OP *rhs)
{
  if(info->opcode == OP_CUSTOM)
    return new_op(aTHX_ (struct HooksAndData) {
        .hooks = info->hooks,
        .data  = info->hookdata,
      }, flags, lhs, rhs, NULL);

  return newBINOP(info->opcode, flags, lhs, rhs);
}

static bool op_yields_oneval(OP *o)
{
  if(OP_GIMME(o, 0) == G_SCALAR)
    return TRUE;

  if(PL_opargs[o->op_type] & OA_RETSCALAR)
    return TRUE;

  /* It might still yield a single value, we'll just have to check harder */
  switch(o->op_type) {
    case OP_REFGEN:
    {
      OP *list = cUNOPo->op_first;
      OP *kid;
      assert(cLISTOPx(list)->op_first->op_type == OP_PUSHMARK);
      if((kid = OpSIBLING(cLISTOPx(list)->op_first)) &&
         !OpSIBLING(kid) &&
         (kid->op_flags & OPf_REF))
        return TRUE;
    }
  }

  return FALSE;
}

static bool extract_wrapper2_args(pTHX_ OP *op, OP **leftp, OP **rightp)
{
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
    return FALSE;
  if(!op_yields_oneval(left))
    return FALSE;

  OP *right = OpSIBLING(left);
  if(!right)
    return FALSE;
  if(!op_yields_oneval(right))
    return FALSE;

  kid = OpSIBLING(right);
  if(!kid)
    return FALSE;
  if(OpSIBLING(kid))
    return FALSE;

  /* Check that kid is now OP_NULL[ OP_GV ] */
  if(kid->op_type != OP_NULL || kid->op_targ != OP_RV2CV)
    return FALSE;
  if(cUNOPx(kid)->op_first->op_type != OP_GV)
    return FALSE;

  /* Splice out these two args and throw away the old optree */
  OpMORESIB_set(left, NULL);
  OpMORESIB_set(right, NULL);
  OpMORESIB_set(pushmark, kid);
  op_free(op);

  OpLASTSIB_set(left, NULL);
  OpLASTSIB_set(right, NULL);

  *leftp  = left;
  *rightp = right;
  return TRUE;
}

static OP *ckcall_wrapper_func_scalarscalar(pTHX_ OP *op, GV *namegv, SV *ckobj)
{
  struct HooksAndData *hd = NUM2PTR(struct HooksAndData *, SvUV(ckobj));

  OP *left, *right;
  if(!extract_wrapper2_args(aTHX_ op, &left, &right))
    return op;

  return new_op(aTHX_ *hd, 0, left, right, NULL);
}

static OP *ckcall_wrapper_func_listlist(pTHX_ OP *op, GV *namegv, SV *ckobj)
{
  struct HooksAndData *hd = NUM2PTR(struct HooksAndData *, SvUV(ckobj));

  OP *left, *right;
  if(!extract_wrapper2_args(aTHX_ op, &left, &right))
    return op;

  return new_op(aTHX_ *hd, 0,
      unwrap_list(left,  hd->hooks->lhs_flags & XPI_OPERAND_ONLY_LOOK),
      unwrap_list(right, hd->hooks->rhs_flags & XPI_OPERAND_ONLY_LOOK),
      NULL);
}

static OP *ckcall_wrapper_func_listassoc_scalars(pTHX_ OP *op, GV *namegv, SV *ckobj)
{
  struct HooksAndData *hd = NUM2PTR(struct HooksAndData *, SvUV(ckobj));

  /* We'll convert this if it looks like a compiletime-constant number of 
   * scalar arguments
   */
  assert(op->op_type == OP_ENTERSUB);

  OP *kid = cUNOPx(op)->op_first;
  /* The first kid is usually an ex-list whose ->op_first begins the actual args list */
  if(kid->op_type == OP_NULL && kid->op_targ == OP_LIST)
    kid = cUNOPx(kid)->op_first;

  assert(kid->op_type == OP_PUSHMARK);
  OP *pushmark = kid;

  kid = OpSIBLING(kid);
  OP *firstarg = kid, *lastarg;

  int argcount = 0;
  OP *nextkid;
  while(kid && (nextkid = OpSIBLING(kid))) {
    if(!op_yields_oneval(kid))
      goto no_wrapper;

    argcount++;
    lastarg = kid;
    kid = nextkid;
  }
  /* kid now points at final op which is the gvop of the OP_ENTERSUB */

  if(!argcount) {
    op_free(op);
    return newLISTOP_CUSTOM(hd->hooks->ppaddr, 0, NULL, NULL);
  }

  /* Splice out the args list and throw away the old optree */
  OpMORESIB_set(pushmark, kid);
  op_free(op);

  /* newLISTOP_CUSTOM doesn't quite handle already created child op chains. We
   * must pass in NULL then set the child ops manually */
  op = newLISTOP_CUSTOM(hd->hooks->ppaddr, 0, NULL, NULL);
  op->op_private = argcount;

  op->op_flags |= OPf_KIDS;
  cLISTOPx(op)->op_first = firstarg;
  cLISTOPx(op)->op_last  = lastarg;
  OpLASTSIB_set(lastarg, op);

  return op;

no_wrapper:
  op = ck_entersub_args_proto_or_list(op, namegv, &PL_sv_undef);
  return op;
}

static OP *ckcall_wrapper_func_listassoc_lists(pTHX_ OP *op, GV *namegv, SV *ckobj)
{
  struct HooksAndData *hd = NUM2PTR(struct HooksAndData *, SvUV(ckobj));

  /* We'll convert this if it looks like a compiletime-constant number of 
   * scalar arguments
   */
  assert(op->op_type == OP_ENTERSUB);

  OP *kid = cUNOPx(op)->op_first;
  /* The first kid is usually an ex-list whose ->op_first begins the actual args list */
  if(kid->op_type == OP_NULL && kid->op_targ == OP_LIST)
    kid = cUNOPx(kid)->op_first;

  assert(kid->op_type == OP_PUSHMARK);
  OP *pushmark = kid;

  kid = OpSIBLING(kid);
  OP *firstarg = kid, *lastarg;

  int argcount = 0;
  OP *nextkid;
  while(kid && (nextkid = OpSIBLING(kid))) {
    if(!op_yields_oneval(kid))
      goto no_wrapper;

    argcount++;
    lastarg = kid;
    kid = nextkid;
  }
  /* kid now points at final op which is the gvop of the OP_ENTERSUB */

  if(!argcount) {
    op_free(op);
    return newLISTOP_CUSTOM(hd->hooks->ppaddr, 0, NULL, NULL);
  }

  /* Splice out the args list and throw away the old optree */
  OpMORESIB_set(pushmark, kid);
  OpLASTSIB_set(lastarg, NULL);
  op_free(op);

  /* We now need to unwrap_list() on each of the args ops */

  kid = firstarg;
  firstarg = NULL;
  lastarg = NULL;
  while(kid) {
    OP *nextkid = OpSIBLING(kid);
    OpLASTSIB_set(kid, NULL);

    OP *newkid = unwrap_list(kid, hd->hooks->lhs_flags & XPI_OPERAND_ONLY_LOOK);

    if(lastarg)
      OpMORESIB_set(lastarg, newkid);

    if(!firstarg)
      firstarg = newkid;
    lastarg = newkid;

    kid = nextkid;
  }

  /* newLISTOP_CUSTOM doesn't quite handle already created child op chains. We
   * must pass in NULL and then set the child ops manually */
  op = newLISTOP_CUSTOM(hd->hooks->ppaddr, 0, NULL, NULL);
  op->op_private = argcount;

  op->op_flags |= OPf_KIDS;
  cLISTOPx(op)->op_first = firstarg;
  cLISTOPx(op)->op_last  = lastarg;
  OpLASTSIB_set(lastarg, op);

  return op;

no_wrapper:
  op = ck_entersub_args_proto_or_list(op, namegv, &PL_sv_undef);
  return op;
}

static OP *pp_push_defav_with_count(pTHX)
{
  dSP;
  AV *defav = GvAV(PL_defgv);
  bool explode = (PL_op->op_flags & OPf_SPECIAL);

  U32 count = av_count(defav);
  SV **svp = AvARRAY(defav);
  if(!explode)
    EXTEND(SP, count);
  for(U32 i = 0; i < count; i++)
    if(explode) {
      if(!SvRV(svp[i]) || SvTYPE(SvRV(svp[i])) != SVt_PVAV)
        croak("Expected an ARRAY reference, got %" SVf, SVfARG(svp[i]));
      AV *av = (AV *)SvRV(svp[i]);
      PUSHMARK(SP);
      U32 acount = av_count(av);
      SV **asvp = AvARRAY(av);
      EXTEND(SP, acount);
      for(U32 i = 0; i < acount; i++)
        PUSHs(asvp[i]);
    }
    else
      PUSHs(svp[i]);

  mXPUSHu(count);

  RETURN;
}

static void make_wrapper_func(pTHX_ const struct HooksAndData *hd)
{
  SV *funcname = newSVpvn(hd->hooks->wrapper_func_name, strlen(hd->hooks->wrapper_func_name));

  GV *gv;
  if((gv = gv_fetchsv(funcname, 0, 0)) && GvCV(gv)) {
    /* The wrapper function already exists. We presume this is due to a duplicate
     * registration of identical hooks under a different name and just skip
     */
    return;
  }

  /* Prepare to make a new optree-based CV */
  I32 floor_ix = start_subparse(FALSE, 0);
  SAVEFREESV(PL_compcv);

  I32 save_ix = block_start(TRUE);

  OP *body = NULL;
  OP *(*ckcall)(pTHX_ OP *, GV *, SV *) = NULL;

  switch(operand_shape(hd)) {
    case SHAPE_SCALARSCALAR:
      body = op_append_list(OP_LINESEQ, body,
          make_argcheck_ops(2, 0, 0, funcname));

      body = op_append_list(OP_LINESEQ, body,
          newSTATEOP(0, NULL, NULL));

      /* Body of the function is just  $_[0] OP $_[1] */
      body = op_append_list(OP_LINESEQ, body,
          new_op(aTHX_ *hd, 0, newSLUGOP(0), newSLUGOP(1), NULL));

      ckcall = &ckcall_wrapper_func_scalarscalar;
      break;

    case SHAPE_SCALARLIST:
      body = op_append_list(OP_LINESEQ, body,
          make_argcheck_ops(1, 0, '@', funcname));

      body = op_append_list(OP_LINESEQ, body,
          newSTATEOP(0, NULL, NULL));

      /* Body of the function is just  shift OP @_ */
      body = op_append_list(OP_LINESEQ, body,
          new_op(aTHX_ *hd, 0,
            newOP(OP_SHIFT, 0),
            force_list_keeping_pushmark(newUNOP(OP_RV2AV, OPf_WANT_LIST, newGVOP(OP_GV, 0, PL_defgv))),
            NULL));

      /* no ckcall */
      break;

    case SHAPE_LISTLIST:
      body = op_append_list(OP_LINESEQ, body,
          make_argcheck_ops(2, 0, 0, funcname));

      body = op_append_list(OP_LINESEQ, body,
          newSTATEOP(0, NULL, NULL));

      /* Body of the function is  @{ $_[0] } OP @{ $_[1] } */
      body = op_append_list(OP_LINESEQ, body,
          new_op(aTHX_ *hd, 0,
            force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, newSLUGOP(0))),
            force_list_keeping_pushmark(newUNOP(OP_RV2AV, 0, newSLUGOP(1))),
            NULL));

      ckcall = &ckcall_wrapper_func_listlist;
      break;

    case SHAPE_LISTASSOC_SCALARS:
      if(hd->hooks->new_op)
        croak("TODO: Cannot make wrapper func for list-associative operator that has hooks->new_op");

      body = op_append_list(OP_LINESEQ, body,
          newSTATEOP(0, NULL, NULL));

      /* Body of the function invokes the op with the values from @_, and an extra IV giving the count */
      body = op_append_list(OP_LINESEQ, body,
          newLISTOP_CUSTOM(hd->hooks->ppaddr, OPf_STACKED,
            newOP_CUSTOM(&pp_push_defav_with_count, 0),
            NULL));

      ckcall = &ckcall_wrapper_func_listassoc_scalars;
      break;

    case SHAPE_LISTASSOC_LISTS:
      if(hd->hooks->new_op)
        croak("TODO: Cannot make wrapper func for list-associative operator that has hooks->new_op");

      body = op_append_list(OP_LINESEQ, body,
          newSTATEOP(0, NULL, NULL));

      /* Body of the function invokes the op with the values from all the 
       * ARRAYs refed by @_, plus marks on the markstack, and an extra IV
       * giving the count */
      body = op_append_list(OP_LINESEQ, body,
          newLISTOP_CUSTOM(hd->hooks->ppaddr, OPf_STACKED /* explode */,
            newOP_CUSTOM(&pp_push_defav_with_count, OPf_SPECIAL),
            NULL));

      ckcall = &ckcall_wrapper_func_listassoc_lists;
      break;
  }

  SvREFCNT_inc(PL_compcv);
  body = block_end(save_ix, body);

  CV *cv = newATTRSUB(floor_ix, newSVOP(OP_CONST, 0, funcname), NULL, NULL, body);

  if(ckcall)
    cv_set_call_checker(cv, ckcall, newSVuv(PTR2UV(hd)));
}

XS_INTERNAL(deparse_infix);
XS_INTERNAL(deparse_infix)
{
  dXSARGS;
  struct Registration *reg = XSANY.any_ptr;

  SV *deparseobj = ST(0);
  SV *ret;

#ifdef HAVE_PL_INFIX_PLUGIN
  SV **hinthashsvp = hv_fetchs(MUTABLE_HV(SvRV(deparseobj)), "hinthash", 0);
  HV *hinthash = hinthashsvp ? MUTABLE_HV(SvRV(*hinthashsvp)) : NULL;

  SV *opnamesv;

  bool infix_is_visible = FALSE;
  /* Operator visibility rules differ for fully-qualified operator names */
  if(reg->opname_is_fq) {
    hv_iterinit(hinthash);
    HE *he;
    while((he = hv_iternext(hinthash))) {
#define PREFIXLEN 17
      STRLEN len;
      if(!strnEQ(HePV(he, len), "XS::Parse::Infix/", PREFIXLEN))
        continue;

      if(!strEQ(SvPV_nolen(HeVAL(he)), reg->info.opname))
        continue;

      infix_is_visible = TRUE;
      opnamesv = newSVpvn_flags(HePV(he, len) + PREFIXLEN, len - PREFIXLEN, HeUTF8(he) ? SVf_UTF8 : 0);
      break;
    }
  }
  else {
    infix_is_visible = (hinthash && hv_fetch(hinthash, reg->hd.hooks->permit_hintkey, reg->permit_hintkey_len, 0));
    opnamesv = newSVpvn_flags(reg->info.opname, reg->oplen, reg->opname_is_WIDE ? SVf_UTF8 : 0);
  }

  if(infix_is_visible) {
    ENTER;
    SAVETMPS;

    EXTEND(SP, 4);
    PUSHMARK(SP);
    PUSHs(deparseobj);
    mPUSHs(opnamesv);
    PUSHs(ST(1));
    PUSHs(ST(2));
    PUTBACK;

    call_method("_deparse_infix_named", G_SCALAR);

    SPAGAIN;
    ret = SvREFCNT_inc(POPs);

    FREETMPS;
    LEAVE;
  }
  else
#endif
  {
    ENTER;
    SAVETMPS;

    EXTEND(SP, 4);
    PUSHMARK(SP);
    PUSHs(deparseobj);
    mPUSHp(reg->hd.hooks->wrapper_func_name, strlen(reg->hd.hooks->wrapper_func_name));
    PUSHs(ST(1));
    PUSHs(ST(2));
    PUTBACK;

    switch(operand_shape(&reg->hd)) {
      case SHAPE_SCALARSCALAR:
      case SHAPE_SCALARLIST: /* not really */
        call_method("_deparse_infix_wrapperfunc_scalarscalar", G_SCALAR);
        break;

      case SHAPE_LISTLIST:
        call_method("_deparse_infix_wrapperfunc_listlist", G_SCALAR);
        break;
    }

    SPAGAIN;
    ret = SvREFCNT_inc(POPs);

    FREETMPS;
    LEAVE;
  }

  ST(0) = sv_2mortal(ret);
  XSRETURN(1);
}

static void reg_builtin(pTHX_ const char *opname, enum XSParseInfixClassification cls, OPCODE opcode)
{
  struct Registration *reg;
  Newx(reg, 1, struct Registration);

  reg->info.opname = savepv(opname);
  reg->info.opcode = opcode;
  reg->info.hooks  = NULL;
  reg->info.cls    = cls;

  reg->oplen  = strlen(opname);
  reg->opname_is_ident = isIDFIRST_utf8_safe(opname, opname + strlen(opname));

  reg->hd.hooks = NULL;
  reg->hd.data  = NULL;

  reg->permit_hintkey_len = 0;

  {
    reg->next = registrations;
    registrations = reg;
  }
}

bool XSParseInfix_check_opname(pTHX_ const char *opname, STRLEN oplen)
{
  const char *opname_end = opname + oplen;

  bool opname_is_fq = strstr(opname, "::") != NULL;
  bool opname_is_ident = !opname_is_fq && isIDFIRST_utf8_safe(opname, opname_end);

  const char *s = opname;
  s += UTF8SKIP(s);

  while(s < opname_end) {
    if(opname_is_ident) {
      if(!isIDCONT_utf8_safe(s, opname_end))
        // name that starts with an identifier may not have non-identifier characters in it
        return FALSE;
    }
    else {
      if(isIDFIRST_utf8_safe(s, opname_end))
        // name that does not start with an identifer may not have identifier characters in it
        return FALSE;
    }
    s += UTF8SKIP(s);
  }

  return TRUE;
}

void XSParseInfix_register(pTHX_ const char *opname, const struct XSParseInfixHooks *hooks, void *hookdata)
{
  STRLEN oplen = strlen(opname);
  const char *opname_end = opname + oplen;
  bool opname_is_fq = strstr(opname, "::") != NULL;
  bool opname_is_ident = !opname_is_fq && isIDFIRST_utf8_safe(opname, opname_end);

  if(!opname_is_fq) {
    if(!XSParseInfix_check_opname(aTHX_ opname, oplen))
      croak("Infix operator name is invalid; must be an identifier or entirely non-identifier characters");
  }

  bool is_listassoc = hooks->flags & XPI_FLAG_LISTASSOC;
  if(hooks->flags & ~(XPI_FLAG_LISTASSOC | (1<<15)))
    /* (1<<15) == undocumented internal flag to indicate v1-compatible ->new_op hook function */
    croak("Unrecognised XSParseInfixHooks.flags value 0x%X", hooks->flags);

  switch(hooks->lhs_flags & ~(XPI_OPERAND_ONLY_LOOK)) {
    case 0:
    case XPI_OPERAND_TERM_LIST:
    case XPI_OPERAND_LIST:
      break;
    default:
      croak("Unrecognised XSParseInfixHooks.lhs_flags value 0x%X", hooks->lhs_flags);
  }

  switch(hooks->rhs_flags & ~(XPI_OPERAND_ONLY_LOOK)) {
    case 0:
    case XPI_OPERAND_TERM_LIST:
    case XPI_OPERAND_LIST:
      break;
    default:
      croak("Unrecognised XSParseInfixHooks.rhs_flags value 0x%X", hooks->rhs_flags);

    case (1 << 7) /* was XPI_OPERAND_CUSTOM */:
      croak("TODO: Currently XPI_OPERAND_CUSTOM is not supported");
  }

  if(is_listassoc) {
    if(hooks->lhs_flags != hooks->rhs_flags)
      croak("Cannot register a list-associative infix operator with lhs_flags=%02X not equal to rhs_flags=%02X",
          hooks->lhs_flags, hooks->rhs_flags);
  }

#ifdef HAVE_PL_INFIX_PLUGIN
  enum Perl_custom_infix_precedence prec = 0;

  switch(hooks->cls) {
    case 0:
      warn("Unspecified operator classification for %s; treating it as RELATION for precedence", opname);
    case XPI_CLS_RELATION:
    case XPI_CLS_EQUALITY:
    case XPI_CLS_MATCH_MISC:
      prec = INFIX_PREC_REL;
      break;

    case XPI_CLS_LOW_MISC:
      prec = INFIX_PREC_LOW;
      break;

    case XPI_CLS_LOGICAL_OR_LOW_MISC:
      prec = INFIX_PREC_LOGICAL_OR_LOW;
      break;

    case XPI_CLS_LOGICAL_AND_LOW_MISC:
      prec = INFIX_PREC_LOGICAL_AND_LOW;
      break;

    case XPI_CLS_ASSIGN_MISC:
      prec = INFIX_PREC_ASSIGN;
      break;

    case XPI_CLS_LOGICAL_OR_MISC:
      prec = INFIX_PREC_LOGICAL_OR;
      break;

    case XPI_CLS_LOGICAL_AND_MISC:
      prec = INFIX_PREC_LOGICAL_AND;
      break;

    case XPI_CLS_ADD_MISC:
      prec = INFIX_PREC_ADD;
      break;

    case XPI_CLS_MUL_MISC:
      prec = INFIX_PREC_MUL;
      break;

    case XPI_CLS_POW_MISC:
      prec = INFIX_PREC_POW;
      break;

    case XPI_CLS_HIGH_MISC:
      prec = INFIX_PREC_HIGH;
      break;

    default:
      croak("TODO: need to write code for hooks->cls == %d\n", hooks->cls);
  }
#endif

  if(!hooks->new_op && !hooks->ppaddr)
    croak("Cannot register third-party infix operator without at least one of .new_op or .ppaddr");

  struct Registration *reg;
  Newx(reg, 1, struct Registration);

#ifdef HAVE_PL_INFIX_PLUGIN
  reg->def.prec  = prec;
  if(hooks->parse)
    reg->def.parse = &parse;
  else
    reg->def.parse = NULL;
  reg->def.build_op = &build_op;
#endif

  reg->info.opname = savepv(opname);
  reg->info.opcode = OP_CUSTOM;
  reg->info.hooks    = hooks;
  reg->info.hookdata = hookdata;
  reg->info.cls      = hooks->cls;

  reg->oplen           = oplen;
  reg->opname_is_ident = opname_is_ident;
  reg->opname_is_fq    = opname_is_fq;

  reg->hd.hooks = hooks;
  reg->hd.data  = hookdata;

  reg->opname_is_WIDE = FALSE;
  int i;
  for(i = 0; i < reg->oplen; i++) {
    if(opname[i] & 0x80) {
      reg->opname_is_WIDE = TRUE;
      break;
    }
  }

  if(hooks->permit_hintkey)
    reg->permit_hintkey_len = strlen(hooks->permit_hintkey);
  else
    reg->permit_hintkey_len = 0;

  if(opname_is_fq) {
    reg->next = fqregistrations;
    fqregistrations = reg;
  }
  else {
    reg->next = registrations;
    registrations = reg;
  }

  if(hooks->wrapper_func_name) {
    make_wrapper_func(aTHX_ &reg->hd);
  }

  if(hooks->ppaddr) {
    XOP *xop;
    Newx(xop, 1, XOP);

    /* Use both the opname for human-readability, and the address of its
     * ppfunc for disambiguating in case of name clashes
     */
    SV *namesv = newSVpvf("B::Deparse::pp_infix_%s_0x%p", opname, hooks->ppaddr);
    {
      char *doublecolon;
      while((doublecolon = strstr(SvPVX(namesv)+sizeof("B::Deparse::pp::"), "::")))
        /* Turn '::' into '__', a length-preserving operation */
        doublecolon[0] = '_', doublecolon[1] = '_';
    }
    if(reg->opname_is_WIDE)
      SvUTF8_on(namesv);
    SAVEFREESV(namesv);

    XopENTRY_set(xop, xop_name, savepv(SvPVX(namesv) + sizeof("B::Deparse::pp")));
    XopENTRY_set(xop, xop_desc, "custom infix operator");
    XopENTRY_set(xop, xop_class, is_listassoc ? OA_LISTOP : OA_BINOP);
    XopENTRY_set(xop, xop_peep, NULL);

    Perl_custom_op_register(aTHX_ hooks->ppaddr, xop);

    CV *cv = newXS(SvPVX(namesv), deparse_infix, __FILE__);
    CvXSUBANY(cv).any_ptr = reg;
  }
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
#ifdef OP_SMARTMATCH /* removed in perl 5.41.3 */
  reg_builtin(aTHX_ "~~", XPI_CLS_SMARTMATCH, OP_SMARTMATCH);
#endif
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
  wrap_infix_plugin(&my_infix_plugin, &next_infix_plugin);
#endif
}
