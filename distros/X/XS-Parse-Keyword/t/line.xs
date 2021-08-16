/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static int build_line(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, newSViv(args[0]->line));
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_line = {
  .permit_hintkey = "t::line/permit",

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_IDENT,
    {0}
  },
  .build = &build_line,
};

MODULE = t::line  PACKAGE = t::line

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("line", &hooks_line, NULL);
