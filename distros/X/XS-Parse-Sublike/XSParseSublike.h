#ifndef __XS_PARSE_SUBLIKE_H__
#define __XS_PARSE_SUBLIKE_H__

#define XSPARSESUBLIKE_ABI_VERSION 4

struct XSParseSublikeContext {
  SV *name;  /* may be NULL for anon subs */
  /* STAGE pre_subparse */
  OP *attrs; /* may be NULL */
  /* STAGE post_blockstart */
  OP *body;
  /* STAGE pre_blockend */
  CV *cv;
  /* STAGE post_newcv */
};

enum {
  XS_PARSE_SUBLIKE_FLAG_FILTERATTRS   = 1<<0,
  XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL = 1<<1,
  XS_PARSE_SUBLIKE_FLAG_PREFIX        = 1<<2,
};

enum {
  XS_PARSE_SUBLIKE_PART_NAME      = 1<<0,
  XS_PARSE_SUBLIKE_PART_ATTRS     = 1<<1,
  XS_PARSE_SUBLIKE_PART_SIGNATURE = 1<<2,
  XS_PARSE_SUBLIKE_PART_BODY      = 1<<3,
};

struct XSParseSublikeHooks {
  U16  flags;
  U8   require_parts;
  U8   skip_parts;

  /* These two hooks are ANDed together; both must pass, if present */
  const char *permit_hintkey;
  bool (*permit)(pTHX_ void *hookdata);

  void (*pre_subparse)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_blockstart)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*pre_blockend)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_newcv)     (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);

  /* if flags & XS_PARSE_SUBLIKE_FLAG_FILTERATTRS */
  bool (*filter_attr)    (pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *val, void *hookdata);
};

static int (*parse_xs_parse_sublike_func)(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr);
#define xs_parse_sublike(hooks, hookdata, op_ptr)  S_xs_parse_sublike(aTHX_ hooks, hookdata, op_ptr)
static int S_xs_parse_sublike(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)
{
  if(!parse_xs_parse_sublike_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*parse_xs_parse_sublike_func)(aTHX_ hooks, hookdata, op_ptr);
}

static void (*register_xs_parse_sublike_func)(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata);
#define register_xs_parse_sublike(kw, hooks, hookdata) S_register_xs_parse_sublike(aTHX_ kw, hooks, hookdata)
static void S_register_xs_parse_sublike(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata)
{
  if(!register_xs_parse_sublike_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*register_xs_parse_sublike_func)(aTHX_ kw, hooks, hookdata);
}

static int (*parseany_xs_parse_sublike_func)(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr);
#define xs_parse_sublike_any(hooks, hookdata, op_ptr)  S_xs_parse_sublike_any(aTHX_ hooks, hookdata, op_ptr)
static int S_xs_parse_sublike_any(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)
{
  if(!parseany_xs_parse_sublike_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*parseany_xs_parse_sublike_func)(aTHX_ hooks, hookdata, op_ptr);
}

#define boot_xs_parse_sublike(ver) S_boot_xs_parse_sublike(aTHX_ ver)
static void S_boot_xs_parse_sublike(pTHX_ double ver) {
  SV **svp;
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Sublike"), versv, NULL);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Sublike/ABIVERSION_MIN", 0);
  if(!svp)
    croak("XS::Parse::Sublike ABI minimum version missing");
  int abi_ver = SvIV(*svp);
  if(abi_ver > XSPARSESUBLIKE_ABI_VERSION)
    croak("XS::Parse::Sublike ABI version mismatch - library supports >= %d, compiled for %d",
        abi_ver, XSPARSESUBLIKE_ABI_VERSION);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Sublike/ABIVERSION_MAX", 0);
  abi_ver = SvIV(*svp);
  if(abi_ver < XSPARSESUBLIKE_ABI_VERSION)
    croak("XS::Parse::Sublike ABI version mismatch - library supports <= %d, compiled for %d",
        abi_ver, XSPARSESUBLIKE_ABI_VERSION);

  parse_xs_parse_sublike_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, void *, OP**),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parse()@4", 0)));

  register_xs_parse_sublike_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseSublikeHooks *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register()@4", 0)));

  parseany_xs_parse_sublike_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, void *, OP**),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parseany()@4", 0)));
}

#endif
