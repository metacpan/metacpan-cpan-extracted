/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

static bool permit_stages(pTHX_ void *hookdata)
{
  HV *hints = GvHV(PL_hintgv);
  if(hv_fetchs(hints, "t::stages/permitfunc", 0))
    return TRUE;

  return FALSE;
}

static void check_stages(pTHX_ void *hookdata)
{
  if(hv_fetchs(GvHV(PL_hintgv), "t::stages/check-capture", 0)) {
    sv_setsv(get_sv("t::stages::captured", GV_ADD), get_sv("main::VAR", 0));
  }
}

static int parse_stages(pTHX_ OP **out, void *hookdata)
{
  /* Parse and ignore a block */
  OP *block = parse_block(0);
  op_free(block);

  *out = newSVOP(OP_CONST, 0, newSVpvs("STAGE"));
  return KEYWORD_PLUGIN_EXPR;
}

static const struct XSParseKeywordHooks hooks_stages = {
  .permit_hintkey = "t::stages/permitkey",
  .permit = &permit_stages,

  .check = &check_stages,

  .parse = &parse_stages,
};

MODULE = t::stages  PACKAGE = t::stages

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("stages", &hooks_stages, NULL);
