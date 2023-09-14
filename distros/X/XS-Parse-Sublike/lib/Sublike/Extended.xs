/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

static struct XSParseSublikeHooks hooks_extended = {
  .permit_hintkey = "Sublike::Extended/extended",
  .flags = XS_PARSE_SUBLIKE_FLAG_PREFIX|
    XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS|
    XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES,

  /* No hooks */
};

MODULE = Sublike::Extended    PACKAGE = Sublike::Extended

BOOT:
  boot_xs_parse_sublike(0); // TODO

  register_xs_parse_sublike("extended", &hooks_extended, NULL);
