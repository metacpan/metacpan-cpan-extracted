/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2024 -- leonerd@leonerd.org.uk
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"
#include "XSParseInfix.h"

#include "keyword.h"
#include "infix.h"

/* v1 hooks.newop did not pass parsedata */
struct XSParseInfixHooks_v1 {
  U16 flags;
  U8 lhs_flags, rhs_flags;
  enum XSParseInfixClassification cls;

  const char *wrapper_func_name;

  const char *permit_hintkey;
  bool (*permit) (pTHX_ void *hookdata);

  OP *(*new_op)(pTHX_ U32 flags, OP *lhs, OP *rhs, void *hookdata);
  OP *(*ppaddr)(pTHX);

  OP *(*parse_rhs)(pTHX_ void *hookdata);
};

static void XSParseInfix_register_v1(pTHX_ const char *opname, const struct XSParseInfixHooks_v1 *hooks_v1, void *hookdata)
{
  if(hooks_v1->rhs_flags & (1 << 7) /* was XPI_OPERAND_CUSTOM */)
    croak("XPI_OPERAND_CUSTOM is no longer supported");
  if(hooks_v1->parse_rhs)
    croak("XSParseInfixHooks.parse_rhs is no longer supported");

  struct XSParseInfixHooks *hooks;
  Newx(hooks, 1, struct XSParseInfixHooks);

  hooks->flags     = hooks_v1->flags | (1<<15) /* NO_PARSEDATA */;
  hooks->lhs_flags = hooks_v1->lhs_flags;
  hooks->rhs_flags = hooks_v1->rhs_flags;
  hooks->cls       = hooks_v1->cls;

  hooks->wrapper_func_name = hooks_v1->wrapper_func_name;

  hooks->permit_hintkey = hooks_v1->permit_hintkey;
  hooks->permit         = hooks_v1->permit;
  hooks->new_op         = (OP *(*)(pTHX_ U32, OP *, OP *, SV **, void *))hooks_v1->new_op;
  hooks->ppaddr         = hooks_v1->ppaddr;
  hooks->parse          = NULL;

  XSParseInfix_register(aTHX_ opname, hooks, hookdata);
}

MODULE = XS::Parse::Keyword    PACKAGE = XS::Parse::Infix

bool check_opname(SV *opname)
  CODE:
  {
    STRLEN namelen;
    const char *namepv = SvPV(opname, namelen);
    RETVAL = XSParseInfix_check_opname(aTHX_ namepv, namelen);
  }
  OUTPUT:
    RETVAL

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


  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/ABIVERSION_MIN", 1), 1);
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/ABIVERSION_MAX", 1), XSPARSEINFIX_ABI_VERSION);

  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/parse()@2", 1), PTR2UV(&XSParseInfix_parse));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/new_op()@0", 1), PTR2UV(&XSParseInfix_new_op));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/register()@1", 1), PTR2UV(&XSParseInfix_register_v1));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Infix/register()@2", 1), PTR2UV(&XSParseInfix_register));

  XSParseInfix_boot(aTHX);
