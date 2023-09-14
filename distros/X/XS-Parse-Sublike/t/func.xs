/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020-2023 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#if PERL_REVISION > 5 || (PERL_REVISION == 5 && PERL_VERSION >= 26)
#  define HAVE_SUB_PARAM_ATTRIBUTES
#endif

static const struct XSParseSublikeHooks parse_func_hooks = {
  .permit_hintkey = "t::func/func",
};

static const struct XSParseSublikeHooks parse_nfunc_hooks = {
  .permit_hintkey = "t::func/nfunc",
  .flags = XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS,
};

static const struct XSParseSublikeHooks parse_afunc_hooks = {
  .permit_hintkey = "t::func/afunc",
  .flags = XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES,
};

#ifdef HAVE_SUB_PARAM_ATTRIBUTES
static void apply_Attribute(pTHX_ struct XPSSignatureParamContext *ctx, SV *attrvalue, void **attrdata_ptr, void *funcdata)
{
  /* TODO: maybe the context should store a lexname string? */
  PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[ctx->padix];

  AV *av = get_av("main::ATTRIBUTE_APPLIED", GV_ADD);

  av_push(av, newSVsv(PadnameSV(pn)));
  av_push(av, newSVsv(attrvalue));
}

static const struct XPSSignatureAttributeFuncs attr_funcs = {
  .ver = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/Attribute",

  .apply = apply_Attribute,
};
#endif

MODULE = t::func  PACKAGE = t::func

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_func_hooks, NULL);
  register_xs_parse_sublike("nfunc", &parse_nfunc_hooks, NULL);
  register_xs_parse_sublike("afunc", &parse_afunc_hooks, NULL);
#ifdef HAVE_SUB_PARAM_ATTRIBUTES
  register_xps_signature_attribute("Attribute", &attr_funcs, NULL);
#endif
