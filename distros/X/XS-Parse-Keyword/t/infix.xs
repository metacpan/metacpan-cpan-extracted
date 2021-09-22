/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
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
  .permit_hintkey = hintkey,
  .cls = 0,

  .wrapper_func_name = "t::infix::addfunc",

  .ppaddr = &pp_add,
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
  .permit_hintkey = hintkey,
  .cls = 0,

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
  .rhs_flags = XPI_OPERAND_LIST,
  .permit_hintkey = hintkey,
  .cls = 0,

  .wrapper_func_name = "t::infix::interspersefunc",

  .ppaddr = &pp_intersperse,
};

MODULE = t::infix  PACKAGE = t::infix

BOOT:
  boot_xs_parse_infix(0);

  register_xs_parse_infix("add", &hooks_add, NULL);

  register_xs_parse_infix("⊕", &hooks_xor, NULL);

  register_xs_parse_infix("intersperse", &hooks_intersperse, NULL);
