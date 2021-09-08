/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"
#include "XSParseInfix.h"

#include "keyword.h"
#include "infix.h"

/* v0 hooks lacked wrapper_func_name */
struct XSParseInfixHooks_v0 {
  U32 flags;
  enum XSParseInfixClassification cls;

  const char *permit_hintkey;
  bool (*permit) (pTHX_ void *hookdata);

  OP *(*new_op)(pTHX_ U32 flags, OP *lhs, OP *rhs, void *hookdata);
  OP *(*ppaddr)(pTHX);
};

static void XSParseInfix_register_v0(pTHX_ const char *opname, const struct XSParseInfixHooks_v0 *hooks_v0, void *hookdata)
{
  struct XSParseInfixHooks *hooks;
  Newx(hooks, 1, struct XSParseInfixHooks);

  hooks->flags = hooks_v0->flags;
  hooks->cls   = hooks_v0->cls;

  hooks->wrapper_func_name = NULL;

  hooks->permit_hintkey = hooks_v0->permit_hintkey;
  hooks->permit         = hooks_v0->permit;
  hooks->new_op         = hooks_v0->new_op;
  hooks->ppaddr         = hooks_v0->ppaddr;

  XSParseInfix_register(aTHX_ opname, hooks, hookdata);
}

MODULE = XS::Parse::Keyword    PACKAGE = XS::Parse::Keyword

BOOT:
  /* legacy version0 support */
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION", 1), XSPARSEKEYWORD_ABI_VERSION);

  /* newer versions */
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION_MIN", 1), 1);
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION_MAX", 1), XSPARSEKEYWORD_ABI_VERSION);

  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/register()@1", 1), PTR2UV(&XSParseKeyword_register_v1));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/register()@2", 1), PTR2UV(&XSParseKeyword_register_v2));

  XSParseKeyword_boot(aTHX);


  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/ABIVERSION_MIN", 1), 0);
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/ABIVERSION_MAX", 1), XSPARSEINFIX_ABI_VERSION);

  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/new_op()@0", 1), PTR2UV(&XSParseInfix_new_op));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/register()@0", 1), PTR2UV(&XSParseInfix_register_v0));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/register()@1", 1), PTR2UV(&XSParseInfix_register));

  XSParseInfix_boot(aTHX);
