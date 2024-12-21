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
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/func",
  .flags          = XS_PARSE_SUBLIKE_FLAG_ALLOW_PKGNAME,
};

static const struct XSParseSublikeHooks parse_nfunc_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/nfunc",
  .flags = XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS,
};

static const struct XSParseSublikeHooks parse_afunc_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/afunc",
  .flags = XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES,
};

static const struct XSParseSublikeHooks parse_nafunc_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/nafunc",
  .flags = XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS|XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES,
};

static const struct XSParseSublikeHooks parse_nopkgfunc_hooks = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/func",
};

#ifdef HAVE_SUB_PARAM_ATTRIBUTES
static void apply_Attribute(pTHX_ struct XPSSignatureParamContext *ctx, SV *attrvalue, void **attrdata_ptr, void *funcdata)
{
  /* TODO: maybe the context should store a lexname string? */
  PADNAME *pn = PadnamelistARRAY(PL_comppad_name)[ctx->padix];

  AV *av = get_av("main::ATTRIBUTE_APPLIED", GV_ADD);

  av_push(av, newSVpvf("%s%" SVf,
    ctx->is_named ? ":" : "", PadnameSV(pn)));
  av_push(av, newSVsv(attrvalue));
}


static void post_defop_Attribute(pTHX_ struct XPSSignatureParamContext *ctx, void *attrdata, void *funcdata)
{
  /* OP* pointer values won't mean much to pureperl code, but we can at least
   * store UVs and assert them not zero
   */

  HV *n = newHV();
  hv_stores(n, "op",    newSVuv(PTR2UV(ctx->op)));
  hv_stores(n, "varop", newSVuv(PTR2UV(ctx->varop)));
  hv_stores(n, "defop", newSVuv(PTR2UV(ctx->defop)));

  AV *av = get_av("main::ATTRIBUTE_SAW_OPTREES", GV_ADD);

  av_push(av, newRV_noinc((SV *)n));

  /* Give the attribute a runtime side-effect so we can test that our returned
   * optree is invoked
   */
  GV *countergv = gv_fetchpvs("main::ATTRIBUTE_INVOKED", GV_ADD, SVt_IV);
  OP *incop = newUNOP(OP_PREINC, 0,
    newUNOP(OP_RV2SV, 0,
      newGVOP(OP_GV, 0, (GV *)SvREFCNT_inc(countergv))));

  ctx->op = op_append_elem(OP_LINESEQ, ctx->op, incop);
}

static const struct XPSSignatureAttributeFuncs attr_funcs = {
  .ver = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "t::func/Attribute",

  .apply      = apply_Attribute,
  .post_defop = post_defop_Attribute,
};
#endif

MODULE = t::func  PACKAGE = t::func

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func",   &parse_func_hooks,   NULL);
  register_xs_parse_sublike("nfunc",  &parse_nfunc_hooks,  NULL);
  register_xs_parse_sublike("afunc",  &parse_afunc_hooks,  NULL);
  register_xs_parse_sublike("nafunc", &parse_nafunc_hooks, NULL);

  register_xs_parse_sublike("nopkgfunc",   &parse_nopkgfunc_hooks,   NULL);
#ifdef HAVE_SUB_PARAM_ATTRIBUTES
  register_xps_signature_attribute("Attribute", &attr_funcs, NULL);
#endif
