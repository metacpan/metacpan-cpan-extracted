/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static const struct XSParseSublikeHooks parse_func_hooks = {
  /* empty */
};

static const struct XSParseSublikeHooks parse_nfunc_hooks = {
  .flags = XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS,
};

MODULE = t::func  PACKAGE = t::func

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_func_hooks, NULL);
  register_xs_parse_sublike("nfunc", &parse_nfunc_hooks, NULL);
