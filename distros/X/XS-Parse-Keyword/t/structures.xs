/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static const char hintkey[] = "t::structures/permit";

static int build_op(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  *out = args[0]->op;
  return KEYWORD_PLUGIN_EXPR;
}

static int build_constiv(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  /* npieces should always be 1 because XPK_LITERAL() does not yield args */
  *out = newSVOP(OP_CONST, 0, newSViv(args[0]->i));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_constsv(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, args[0]->sv);
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_sequence = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_SEQUENCE(
      XPK_LITERAL("part"),
      XPK_TERMEXPR
    ),
    {0}
  },
  .build = &build_op,
};

static const struct XSParseKeywordHooks hooks_optional = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_OPTIONAL(
      XPK_LITERAL("part")
    ),
    {0}
  },
  .build = &build_constiv,
};

static const struct XSParseKeywordHooks hooks_repeated = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_REPEATED(
      XPK_LITERAL("part")
    ),
    {0}
  },
  .build = &build_constiv,
};

static const struct XSParseKeywordHooks hooks_choice = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []) {
    XPK_CHOICE(
      XPK_LITERAL("zero"),
      XPK_LITERAL("one"),
      XPK_LITERAL("two"),
      XPK_BLOCK
    ),
    {0}
  },
  .build = &build_constiv,
};

static const struct XSParseKeywordHooks hooks_tagged = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_TAGGEDCHOICE(
      XPK_LITERAL("one"),   XPK_TAG(1),
      XPK_LITERAL("two"),   XPK_TAG(2),
      XPK_LITERAL("three"), XPK_TAG(3)
    ),
    {0}
  },
  .build = &build_constiv,
};

static const struct XSParseKeywordHooks hooks_commalist = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_COMMALIST( XPK_LITERAL("item") ),
    {0}
  },
  .build = &build_constiv,
};

static const struct XSParseKeywordHooks hooks_parens = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PARENS( XPK_TERMEXPR ),
    {0}
  },
  .build = &build_op,
};

static const struct XSParseKeywordHooks hooks_args = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_ARGS( XPK_TERMEXPR ),
    {0}
  },
  .build = &build_op,
};

static const struct XSParseKeywordHooks hooks_brackets = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_BRACKETS( XPK_TERMEXPR ),
    {0}
  },
  .build = &build_op,
};

static const struct XSParseKeywordHooks hooks_braces = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_BRACES( XPK_TERMEXPR ),
    {0}
  },
  .build = &build_op,
};

static const struct XSParseKeywordHooks hooks_chevrons = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    /* A TERMEXPR inside chevrons is ambiguous, because of the < 2 > 1 > problem */
    XPK_CHEVRONS( XPK_IDENT ),
    {0}
  },
  .build = &build_constsv,
};

MODULE = t::structures  PACKAGE = t::structures

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("structsequence", &hooks_sequence, NULL);
  register_xs_parse_keyword("structoptional", &hooks_optional, NULL);
  register_xs_parse_keyword("structrepeat", &hooks_repeated, NULL);
  register_xs_parse_keyword("structchoice", &hooks_choice, NULL);
  register_xs_parse_keyword("structtagged", &hooks_tagged, NULL);
  register_xs_parse_keyword("structcommalist", &hooks_commalist, NULL);

  register_xs_parse_keyword("parens",   &hooks_parens,   NULL);
  register_xs_parse_keyword("args",     &hooks_args,     NULL);
  register_xs_parse_keyword("brackets", &hooks_brackets, NULL);
  register_xs_parse_keyword("braces",   &hooks_braces,   NULL);
  register_xs_parse_keyword("chevrons", &hooks_chevrons, NULL);
