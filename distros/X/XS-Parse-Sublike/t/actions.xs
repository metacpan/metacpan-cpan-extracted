/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static void action_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  const char *namestr = SvPVX(ctx->name);

  if(strchr(namestr, 'i'))
    ctx->actions &= ~XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
  if(strchr(namestr, 'R'))
    ctx->actions |= XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE;
  if(strchr(namestr, 'E'))
    ctx->actions |= XS_PARSE_SUBLIKE_ACTION_RET_EXPR;
}

static const struct XSParseSublikeHooks parse_action_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::actions/action",
  .flags         = XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS,
  .require_parts = XS_PARSE_SUBLIKE_PART_NAME,

  .pre_subparse = action_pre_subparse,
};

MODULE = t::actions  PACKAGE = t::actions

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("action", &parse_action_hooks, NULL);
