/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseInfix.h"

#include "perl-backcompat.c.inc"

static const char hintkey[] = "t::infix/permit";

XOP xop_add;

OP *pp_add(pTHX)
{
  dSP;
  SV *right = POPs;
  SV *left  = POPs;
  mPUSHi(SvIV(left) + SvIV(right));
  RETURN;
}

static const struct XSParseInfixHooks hooks_add = {
  .cls = XPI_CLS_ADD_MISC,
  .permit_hintkey = hintkey,

  .wrapper_func_name = "t::infix::addfunc",

  .ppaddr = &pp_add,
};

OP *pp_mul(pTHX)
{
  croak("TODO"); /* We never actually call code with this so it doesn't matter */
}

static const struct XSParseInfixHooks hooks_mul = {
  .cls = XPI_CLS_MUL_MISC,
  .permit_hintkey = hintkey,

  .ppaddr = &pp_mul,
};

OP *pp_xor(pTHX)
{
  dSP;
  SV *right = POPs;
  SV *left  = POPs;
  mPUSHi(SvIV(left) ^ SvIV(right));
  RETURN;
}

static const struct XSParseInfixHooks hooks_xor = {
  .cls = XPI_CLS_ADD_MISC,
  .permit_hintkey = hintkey,

  .ppaddr = &pp_xor,
};

OP *pp_intersperse(pTHX)
{
  /* This isn't a very efficient implementation but we're not going for
   * efficiency here in this unit test
   */
  dSP;
  I32 markidx = POPMARK;
  I32 items = SP - PL_stack_base - markidx;

  SP -= items;
  SV *sep = *SP;

  AV *list = av_make(items, SP+1);
  SAVEFREESV((SV *)list);

  SP--;

  if(!items)
    RETURN;

  EXTEND(SP, 2*items - 1);
  PUSHs(*av_fetch(list, 0, TRUE));

  I32 i;
  for(i = 1; i < items; i++) {
    PUSHs(sv_mortalcopy(sep));
    PUSHs(*av_fetch(list, i, TRUE));
  }
  RETURN;
}

static const struct XSParseInfixHooks hooks_intersperse = {
  .cls = XPI_CLS_ADD_MISC,
  .rhs_flags = XPI_OPERAND_LIST,
  .permit_hintkey = hintkey,

  .wrapper_func_name = "t::infix::interspersefunc",

  .ppaddr = &pp_intersperse,
};

OP *pp_addpairs(pTHX)
{
  dSP;
  U32 rhs_mark = POPMARK;
  U32 lhs_mark = POPMARK;

  U32 rhs_count = SP - (PL_stack_base + rhs_mark);
  U32 lhs_count = rhs_mark - lhs_mark;

  SP = PL_stack_base + lhs_mark;

  SV **lhs = PL_stack_base + lhs_mark + 1;
  SV **rhs = PL_stack_base + rhs_mark + 1;

  PUSHMARK(SP);

  while(lhs_count || rhs_count) {
    IV val = SvIV(*lhs) + SvIV(*rhs);
    mPUSHi(val);

    lhs++; lhs_count--;
    rhs++; rhs_count--;
  }

  RETURN;
}

static const struct XSParseInfixHooks hooks_addpairs = {
  .cls = XPI_CLS_ADD_MISC,
  .lhs_flags = XPI_OPERAND_LIST,
  .rhs_flags = XPI_OPERAND_LIST|XPI_OPERAND_ONLY_LOOK, /* only on RHS so we can test the logic */
  .permit_hintkey = hintkey,

  .wrapper_func_name = "t::infix::addpairsfunc",

  .ppaddr = &pp_addpairs,
};

OP *pp_cat(pTHX)
{
  dSP;
  int n = (PL_op->op_flags & OPf_STACKED) ? POPu : PL_op->op_private;

  SV *ret = newSVpvs("^");
  SV **args = SP - n + 1;
  for(int i = 0; i < n; i++)
    sv_catsv(ret, args[i]);

  sv_catpvs(ret, "^");

  SP -= n;
  mPUSHs(ret);

  RETURN;
}

static const struct XSParseInfixHooks hooks_cat = {
  .cls = XPI_CLS_ADD_MISC,
  .flags = XPI_FLAG_LISTASSOC,
  .permit_hintkey = hintkey,

  .wrapper_func_name = "t::infix::catfunc",

  .ppaddr = &pp_cat,
};

OP *pp_LL(pTHX)
{
  dSP;
  int n = (PL_op->op_flags & OPf_STACKED) ? POPu : PL_op->op_private;

  if(n > 2)
    croak("TODO: unit test cannot cope with n > 2");

  U32 counts[2];
  SV **args[2];
  for(int listi = n-1; listi >= 0; listi--) {
    SV **mark = PL_stack_base + POPMARK;
    counts[listi] = SP - mark;
    args[listi] = mark + 1;
    SP = mark;
  }

  SV *ret = newSVpvs("(");

  for(int listi = 0; listi < n; listi++) {
    sv_catpvs(ret, "[");

    for(int argi = 0; argi < counts[listi]; argi++)
      sv_catsv(ret, args[listi][argi]);

    sv_catpvs(ret, "]");
  }

  sv_catpvs(ret, ")");

  mPUSHs(ret);
  RETURN;
}

static const struct XSParseInfixHooks hooks_LL = {
  .cls = XPI_CLS_ADD_MISC,
  .flags = XPI_FLAG_LISTASSOC,
  .lhs_flags = XPI_OPERAND_LIST|XPI_OPERAND_ONLY_LOOK,
  .rhs_flags = XPI_OPERAND_LIST|XPI_OPERAND_ONLY_LOOK,
  .permit_hintkey = hintkey,

  .wrapper_func_name = "t::infix::LLfunc",

  .ppaddr = &pp_LL,
};

OP *pp_fqadd(pTHX)
/* Like pp_add but we need a second address so as not to upset the deparse tests */
{
  return pp_add(aTHX);
}

static const struct XSParseInfixHooks hooks_fqadd = {
  .cls = XPI_CLS_ADD_MISC,
  .ppaddr = &pp_fqadd,
};

MODULE = t::infix  PACKAGE = t::infix

BOOT:
  boot_xs_parse_infix(0);

  register_xs_parse_infix("add", &hooks_add, NULL);
  register_xs_parse_infix("mul", &hooks_mul, NULL);

  register_xs_parse_infix("⊕", &hooks_xor, NULL);

  register_xs_parse_infix("intersperse", &hooks_intersperse, NULL);

  register_xs_parse_infix("addpairs", &hooks_addpairs, NULL);

  register_xs_parse_infix("cat", &hooks_cat, NULL);
  register_xs_parse_infix("LL", &hooks_LL, NULL);

  register_xs_parse_infix("t::infix::fqadd", &hooks_fqadd, NULL);
