/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static bool parts_permit(pTHX_ void *_);

static struct XSParseSublikeHooks parse_parts_hooks = {
  .permit = parts_permit,
};

static bool parts_permit(pTHX_ void *_)
{
  parse_parts_hooks.require_parts = 0;
  parse_parts_hooks.skip_parts     = 0;

  if(hv_fetchs(GvHV(PL_hintgv), "t::parts/require-name", 0))
    parse_parts_hooks.require_parts |= XS_PARSE_SUBLIKE_PART_NAME;
  if(hv_fetchs(GvHV(PL_hintgv), "t::parts/skip-name", 0))
    parse_parts_hooks.skip_parts |= XS_PARSE_SUBLIKE_PART_NAME;

  if(hv_fetchs(GvHV(PL_hintgv), "t::parts/skip-attrs", 0))
    parse_parts_hooks.skip_parts |= XS_PARSE_SUBLIKE_PART_ATTRS;

  if(hv_fetchs(GvHV(PL_hintgv), "t::parts/skip-signature", 0))
    parse_parts_hooks.skip_parts |= XS_PARSE_SUBLIKE_PART_SIGNATURE;

  return TRUE;
}

MODULE = t::parts  PACKAGE = t::parts

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("parts", &parse_parts_hooks, NULL);
