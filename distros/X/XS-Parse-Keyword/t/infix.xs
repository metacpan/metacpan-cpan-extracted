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

MODULE = t::infix  PACKAGE = t::infix

BOOT:
  boot_xs_parse_infix(0);

  register_xs_parse_infix("add", &hooks_add, NULL);

  XopENTRY_set(&xop_add, xop_class, OA_BINOP);
  Perl_custom_op_register(aTHX_ &pp_add, &xop_add);
