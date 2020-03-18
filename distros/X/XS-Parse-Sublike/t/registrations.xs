/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static bool red_permit(pTHX)
{
  if(!hv_fetchs(GvHV(PL_hintgv), "t::registrations/red", 0))
    return false;

  return true;
}

static OP *red_pre_blockend(pTHX_ OP *body)
{
  /* Throw away the entire function body; replace it with a constant */
  op_free(body);
  return newSVOP(OP_CONST, 0, newSVpv("red", 0));
}

static const struct XSParseSublikeHooks parse_red_hooks = {
  .permit       = red_permit,
  .pre_blockend = red_pre_blockend,
};

static bool blue_permit(pTHX)
{
  if(!hv_fetchs(GvHV(PL_hintgv), "t::registrations/blue", 0))
    return false;

  return true;
}

static OP *blue_pre_blockend(pTHX_ OP *body)
{
  /* Throw away the entire function body; replace it with a constant */
  op_free(body);
  return newSVOP(OP_CONST, 0, newSVpv("blue", 0));
}

static const struct XSParseSublikeHooks parse_blue_hooks = {
  .permit       = blue_permit,
  .pre_blockend = blue_pre_blockend,
};

MODULE = t::registrations  PACKAGE = t::registrations

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_red_hooks);
  register_xs_parse_sublike("func", &parse_blue_hooks);
