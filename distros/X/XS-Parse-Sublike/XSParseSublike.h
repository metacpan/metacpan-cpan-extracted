#ifndef __XS_PARSE_SUBLIKE_H__
#define __XS_PARSE_SUBLIKE_H__

#define XSPARSESUBLIKE_ABI_VERSION 1

struct XSParseSublikeHooks {
  U32  flags;   /* undocumented but reserved for ABI back-compat later */
  bool (*permit)         (pTHX);
  void (*post_blockstart)(pTHX);
  OP * (*pre_blockend)   (pTHX_ OP *body);
  void (*post_newcv)     (pTHX_ CV *cv);
};

static int (*parse_func)(pTHX_ const struct XSParseSublikeHooks *hooks, OP **op_ptr);
#define xs_parse_sublike(hooks, op_ptr)  S_xs_parse_sublike(aTHX_ hooks, op_ptr)
static int S_xs_parse_sublike(pTHX_ const struct XSParseSublikeHooks *hooks, OP **op_ptr)
{
  if(!parse_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*parse_func)(aTHX_ hooks, op_ptr);
}

static void (*register_func)(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks);
#define register_xs_parse_sublike(kw, hooks) S_register_xs_parse_sublike(aTHX_ kw, hooks)
static void S_register_xs_parse_sublike(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks)
{
  if(!register_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*register_func)(aTHX_ kw, hooks);
}

static int (*parseany_func)(pTHX_ const struct XSParseSublikeHooks *hooks, OP **op_ptr);
#define xs_parse_sublike_any(hooks, op_ptr)  S_xs_parse_sublike_any(aTHX_ hooks, op_ptr)
static int S_xs_parse_sublike_any(pTHX_ const struct XSParseSublikeHooks *hooks, OP **op_ptr)
{
  if(!parseany_func)
    croak("Must call boot_xs_parse_sublike() first");

  return (*parseany_func)(aTHX_ hooks, op_ptr);
}

#define boot_xs_parse_sublike(ver) S_boot_xs_parse_sublike(aTHX_ ver)
static void S_boot_xs_parse_sublike(pTHX_ double ver) {
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Sublike"), versv, NULL);

  int abi_version = SvIV(get_sv("XS::Parse::Sublike::ABIVERSION", 0));
  if(abi_version != XSPARSESUBLIKE_ABI_VERSION)
    croak("XS::Parse::Sublike ABI version mismatch - library provides %d, compiled for %d",
        abi_version, XSPARSESUBLIKE_ABI_VERSION);

  parse_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, OP**),
      SvUV(get_sv("XS::Parse::Sublike::PARSE", 0)));

  register_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseSublikeHooks *),
      SvUV(get_sv("XS::Parse::Sublike::REGISTER", 0)));

  parseany_func = INT2PTR(int (*)(pTHX_ const struct XSParseSublikeHooks *, OP**),
      SvUV(get_sv("XS::Parse::Sublike::PARSEANY", 0)));
}

#endif
