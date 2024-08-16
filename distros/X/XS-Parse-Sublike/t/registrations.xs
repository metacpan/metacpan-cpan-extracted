/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static void red_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  /* Throw away the entire function body; replace it with a constant */
  op_free(ctx->body);
  ctx->body = newSVOP(OP_CONST, 0, newSVpv("red", 0));
}

static const struct XSParseSublikeHooks parse_red_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::registrations/red",
  .pre_blockend = red_pre_blockend,
};

static void blue_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  /* Throw away the entire function body; replace it with a constant */
  op_free(ctx->body);
  ctx->body = newSVOP(OP_CONST, 0, newSVpv("blue", 0));
}

static const struct XSParseSublikeHooks parse_blue_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::registrations/blue",
  .pre_blockend = blue_pre_blockend,
};

MODULE = t::registrations  PACKAGE = t::registrations

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_red_hooks, NULL);
  register_xs_parse_sublike("func", &parse_blue_hooks, NULL);
