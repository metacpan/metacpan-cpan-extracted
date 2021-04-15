/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

static const char hintkey[] = "t::pieces/permit";

static int build_expr(pTHX_ OP **out, XSParseKeywordPiece arg0, void *hookdata)
{
  /* wrap the result in "("...")" parens so we can unit-test how it parsed */
  *out = newBINOP(OP_CONCAT, 0,
    newBINOP(OP_CONCAT, 0, newSVOP(OP_CONST, 0, newSVpvs("(")), op_scope(arg0.op)),
    newSVOP(OP_CONST, 0, newSVpvs(")")));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_anonsub(pTHX_ OP **out, XSParseKeywordPiece arg0, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, newRV_noinc((SV *)cv_clone(arg0.cv)));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_list(pTHX_ OP **out, XSParseKeywordPiece arg0, void *hookdata)
{
  OP *list = arg0.op;

  /* TODO: Consider always doing this? */
  if(list->op_type != OP_LIST)
    list = newLISTOP(OP_LIST, 0, list, NULL);

  /* unshift $sep */
#if HAVE_PERL_VERSION(5, 22, 0)
  op_sibling_splice(list, cUNOPx(list)->op_first, 0, newSVOP(OP_CONST, 0, newSVpvs(",")));
#else
  {
    OP *o = newSVOP(OP_CONST, 0, newSVpvs(","));
    o->op_sibling = cUNOPx(list)->op_first->op_sibling;
    cUNOPx(list)->op_first->op_sibling = o;
  }
#endif

  *out = op_convert_list(OP_JOIN, 0, list);

  return KEYWORD_PLUGIN_EXPR;
}

static int build_constsv(pTHX_ OP **out, XSParseKeywordPiece arg0, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, arg0.sv);
  return KEYWORD_PLUGIN_EXPR;
}

static int build_literal(pTHX_ OP **out, XSParseKeywordPiece arg0, void *hookdata)
{
  /* ignore arg0 */

  *out = newSVOP(OP_CONST, 0, (SV *)hookdata);

  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_block = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_BLOCK,
  .build1 = &build_expr,
};

static const struct XSParseKeywordHooks hooks_anonsub = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_ANONSUB,
  .build1 = &build_anonsub,
};

static const struct XSParseKeywordHooks hooks_termexpr = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_TERMEXPR,
  .build1 = &build_expr,
};

static const struct XSParseKeywordHooks hooks_listexpr = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LISTEXPR,
  .build1 = &build_list,
};

static const struct XSParseKeywordHooks hooks_ident = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_IDENT,
  .build1 = &build_constsv,
};

static const struct XSParseKeywordHooks hooks_packagename = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_PACKAGENAME,
  .build1 = &build_constsv,
};

static const struct XSParseKeywordHooks hooks_colon = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_COLON,
  .build1 = &build_literal,
};

static const struct XSParseKeywordHooks hooks_str = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_STRING("foo"),
  .build1 = &build_literal,
};

MODULE = t::pieces  PACKAGE = t::pieces

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("pieceblock", &hooks_block, NULL);
  register_xs_parse_keyword("pieceanonsub", &hooks_anonsub, NULL);
  register_xs_parse_keyword("piecetermexpr", &hooks_termexpr, NULL);
  register_xs_parse_keyword("piecelistexpr", &hooks_listexpr, NULL);

  register_xs_parse_keyword("pieceident", &hooks_ident, NULL);
  register_xs_parse_keyword("piecepkg", &hooks_packagename, NULL);

  register_xs_parse_keyword("piececolon", &hooks_colon, newSVpvs("colon"));

  register_xs_parse_keyword("piecestr", &hooks_str, newSVpvs("foo"));
