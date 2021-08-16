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

static const char hintkey[] = "t::probing/permit";

static int build_constbool(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, boolSV(args[0]->i));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_repeatcount(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, newSViv(args[0]->i ? args[1]->i : 0));
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_colon = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_COLON ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_literal = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_LITERAL("literal") ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_block = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_BLOCK ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_ident = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_IDENT ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_packagename = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_PACKAGENAME ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_vstring = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_VSTRING ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_choice = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_CHOICE(
      XPK_LITERAL("x"),
      XPK_LITERAL("z")
    ) ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_taggedchoice = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_TAGGEDCHOICE(
      XPK_LITERAL("x"), XPK_TAG('x'),
      XPK_LITERAL("z"), XPK_TAG('z')
    ) ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_commalist = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []) {
    XPK_OPTIONAL( XPK_COMMALIST( XPK_IDENT ) ),
    {0},
  },
  .build = &build_repeatcount,
};

static const struct XSParseKeywordHooks hooks_parens = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_PARENSCOPE( XPK_TERMEXPR ) ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_brackets = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_BRACKETSCOPE( XPK_TERMEXPR ) ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_braces = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_BRACESCOPE( XPK_TERMEXPR ) ),
    {0}
  },
  .build = &build_constbool,
};

static const struct XSParseKeywordHooks hooks_chevrons = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL( XPK_CHEVRONSCOPE( XPK_IDENT ) ),
    {0}
  },
  .build = &build_constbool,
};

MODULE = t::probing  PACKAGE = t::probing

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("probecolon", &hooks_colon, NULL);
  register_xs_parse_keyword("probeliteral", &hooks_literal, NULL);

  register_xs_parse_keyword("probeblock", &hooks_block, NULL);
  register_xs_parse_keyword("probeident", &hooks_ident, NULL);
  register_xs_parse_keyword("probepackagename", &hooks_packagename, NULL);
  register_xs_parse_keyword("probevstring", &hooks_vstring, NULL);

  register_xs_parse_keyword("probechoice", &hooks_choice, NULL);
  register_xs_parse_keyword("probetaggedchoice", &hooks_taggedchoice, NULL);

  register_xs_parse_keyword("probecommalist", &hooks_commalist, NULL);

  register_xs_parse_keyword("probeparens", &hooks_parens, NULL);
  register_xs_parse_keyword("probebrackets", &hooks_brackets, NULL);
  register_xs_parse_keyword("probebraces", &hooks_braces, NULL);
  register_xs_parse_keyword("probechevrons", &hooks_chevrons, NULL);
