/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static void no_body_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  if(ctx->body)
    croak("Expected no_body to have ctx->body == NULL");
  if(ctx->cv)
    croak("Expected no_body to have ctx->cv == NULL");

  sv_setsv(get_sv("t::flags::captured_name", GV_ADD), ctx->name);
}

static const struct XSParseSublikeHooks parse_no_body_hooks = {
  .permit_hintkey = "t::flags/no_body",
  .flags = XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL,

  .post_newcv = no_body_post_newcv,
};

MODULE = t::flags  PACKAGE = t::flags

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("no_body", &parse_no_body_hooks, NULL);
