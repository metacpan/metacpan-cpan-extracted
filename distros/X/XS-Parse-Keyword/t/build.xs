/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static int build(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  /* concat the exprs together */
  *out = newBINOP(OP_CONCAT, 0,
    newBINOP(OP_CONCAT, 0, args[0]->op, newSVOP(OP_CONST, 0, newSVpvs("|"))),
    args[1]->op);

  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_build = {
  .permit_hintkey = "t::build/permit",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_BLOCK,
    XPK_TERMEXPR,
    {0}
  },
  .build = &build,
};

MODULE = t::build  PACKAGE = t::build

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("build", &hooks_build, NULL);
