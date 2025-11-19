#ifndef __XS_PARSE_SUBLIKE_H__
#define __XS_PARSE_SUBLIKE_H__

#define XSPARSESUBLIKE_ABI_VERSION 8

struct XSParseSublikeContext {
  SV *name;  /* may be NULL for anon subs */
  /* STAGE pre_subparse */
  OP *attrs; /* may be NULL */
  /* STAGE post_blockstart */
  OP *body;
  /* STAGE pre_blockend */
  CV *cv;
  /* STAGE post_newcv */

  U32 actions;

  /* Unused by XS::Parse::Sublike itself but can be handy for modules to store
   * data in between stages */
  HV *moddata;
};

enum {
  XS_PARSE_SUBLIKE_FLAG_FILTERATTRS   = 1<<0, /* API v4 flag, no longer used */
  XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL = 1<<1,
  XS_PARSE_SUBLIKE_FLAG_PREFIX        = 1<<2,

  XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS = 1<<3,
  XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES = 1<<4,

  XS_PARSE_SUBLIKE_FLAG_ALLOW_PKGNAME = 1<<5,

  XS_PARSE_SUBLIKE_FLAG_SIGNATURE_REFALIAS = 1<<6,

  /* Back-compat flags we hope to remove in the next ABI version */
  XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS = 1<<15,
};

enum {
  XS_PARSE_SUBLIKE_PART_NAME      = 1<<0,
  XS_PARSE_SUBLIKE_PART_ATTRS     = 1<<1,
  XS_PARSE_SUBLIKE_PART_SIGNATURE = 1<<2,
  XS_PARSE_SUBLIKE_PART_BODY      = 1<<3,
};

enum {
  XS_PARSE_SUBLIKE_ACTION_CVf_ANON        = (1<<0),  /* should start_subparse() take CVf_ANON ? */
  XS_PARSE_SUBLIKE_ACTION_SET_CVNAME      = (1<<1),  /* do we set a CvNAME? */
  XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL  = (1<<2),  /* do we install the new CV into the symbol table? */
  XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE = (1<<3),  /* do we emit OP_REFGEN of OP_ANONCODE, or simply OP_NULL ? */
  XS_PARSE_SUBLIKE_ACTION_RET_EXPR        = (1<<4),  /* do we return KEYWORD_PLUGIN_EXPR, or KEYWORD_PLUGIN_STMT ? */
  XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL = (1<<5),  /* do we install the new CV into the current lexical pad? (Perl 5.18+) */
};

struct XSParseSublikeHooks {
  U32  ver;  /* caller must initialise to XSPARSESUBLIKE_ABI_VERSION */
  U16  flags;
  U8   require_parts;
  U8   skip_parts;

  /* These two hooks are ANDed together; both must pass, if present */
  const char *permit_hintkey;
  bool (*permit)(pTHX_ void *hookdata);

  void (*pre_subparse)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  bool (*filter_attr)    (pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *val, void *hookdata);
  void (*post_blockstart)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*pre_blockend)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_newcv)     (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);

  /* if ver >= 7: */
  void (*start_signature) (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*finish_signature)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
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

/* arguments to the signature_add_param function */
struct XPSSignatureParamDetails {
  U32  ver;  /* caller must initialise to XSPARSESUBLIKE_ABI_VERSION */

  /* TODO: Right now this is entirely ABI-unstable and prone to change between versions
   * For now this can only add mandatory positional scalar, or final slurpy
   * params whose pad variable has already been declared, and that have no
   * attributes attached.
   */
  char sigil;
  PADOFFSET padix;
};

static void (*signature_add_param_func)(pTHX_ struct XSParseSublikeContext *ctx, struct XPSSignatureParamDetails *details);
#define xps_signature_add_param(ctx, details)  S_xps_signature_add_param(aTHX_ ctx, details)
static void S_xps_signature_add_param(pTHX_ struct XSParseSublikeContext *ctx, struct XPSSignatureParamDetails *details)
{
  if(!signature_add_param_func)
    croak("Must call boot_xs_parse_sublike() first");

  (*signature_add_param_func)(aTHX_ ctx, details);
}

/* Easier to define one query function that takes a `q` parameter, that
 * indicates which question we are asking. This saves us having to export
 * lots of functions. This is internal implementation detail, not exposed
 * API.
 */
static IV (*signature_query_func)(pTHX_ struct XSParseSublikeContext *ctx, int q);
#define xps_signature_query_params(ctx)     S_xps_signature_query(aTHX_ ctx, 0)
#define xps_signature_query_optparams(ctx)  S_xps_signature_query(aTHX_ ctx, 1)
#define xps_signature_query_slurpy(ctx)     ((char)S_xps_signature_query(aTHX_ ctx, 2))
static IV S_xps_signature_query(pTHX_ struct XSParseSublikeContext *ctx, int q)
{
  if(!signature_query_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*signature_query_func)(aTHX_ ctx, q);
}

/* Experimental support for subroutine parameter attributes.
 * Only supported on Perl v5.26 or later
 */

struct XPSSignatureParamContext {
  bool is_named;
  PADOFFSET padix;
  OP *varop;
  /* apply phase runs here */
  OP *defop;
  OP *op;
  /* post_defop phase runs here */

  /* TODO: in next ABI-breaking change, move this to the top */
  char sigil;
  const char *namepv;
  STRLEN namelen;

  bool is_refalias;
};

struct XPSSignatureAttributeFuncs {
  U32 ver;  /* caller must initialise to XSPARSESUBLIKE_ABI_VERSION */
  U32 flags;
  const char *permit_hintkey;

  void (*apply)(pTHX_ struct XPSSignatureParamContext *ctx, SV *attrvalue, void **attrdata_ptr, void *funcdata);
  void (*post_defop)(pTHX_ struct XPSSignatureParamContext *ctx, void *attrdata, void *funcdata);

  void (*free)(pTHX_ void *attrdata, void *funcdata);
};

static void (*register_xps_signature_attribute_func)(pTHX_ const char *name, const struct XPSSignatureAttributeFuncs *funcs, void *funcdata);
#define register_xps_signature_attribute(name, funcs, funcdata) S_register_xps_signature_attribute(aTHX_ name, funcs, funcdata)
static void S_register_xps_signature_attribute(pTHX_ const char *name, const struct XPSSignatureAttributeFuncs *funcs, void *funcdata)
{
  if(!register_xps_signature_attribute_func)
    croak("Must call boot_xs_parse_sublike() first");

  (*register_xps_signature_attribute_func)(aTHX_ name, funcs, funcdata);
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
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parse()@6", 0)));

  register_xs_parse_sublike_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseSublikeHooks *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register()@6", 0)));

  parseany_xs_parse_sublike_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, void *, OP**),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parseany()@6", 0)));

  register_xps_signature_attribute_func = INT2PTR(void (*)(pTHX_ const char *, const struct XPSSignatureAttributeFuncs *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register_sigattr()@5", 0)));

  signature_add_param_func = INT2PTR(void (*)(pTHX_ struct XSParseSublikeContext *ctx, struct XPSSignatureParamDetails *details),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/signature_add_param()@7", 0)));

  signature_query_func = INT2PTR(IV (*)(pTHX_ struct XSParseSublikeContext *ctx, int q),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/signature_query()@8", 0)));
}

#endif
