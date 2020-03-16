#ifndef __XS_PARSE_SUBLIKE_H__
#define __XS_PARSE_SUBLIKE_H__

struct XSParseSublikeHooks {
  void (*post_blockstart)(pTHX);
  OP * (*pre_blockend)   (pTHX_ OP *body);
  void (*post_newcv)     (pTHX_ CV *cv);
};

#define xs_parse_sublike(hooks, op_ptr)  S_xs_parse_sublike(aTHX_ hooks, op_ptr)
static int S_xs_parse_sublike(pTHX_ struct XSParseSublikeHooks *hooks, OP **op_ptr)
{
  SV *sv = get_sv("XS::Parse::Sublike::PARSE", 0);
  if(!sv)
    croak("Cannot find $XS::Parse::Sublike::PARSE - is it loaded?");

  int (*func)(pTHX_ struct XSParseSublikeHooks *hooks, OP **op_ptr)
    = INT2PTR(int (*)(pTHX_ struct XSParseSublikeHooks *, OP**), SvUV(sv));

  return (*func)(aTHX_ hooks, op_ptr);
}

#define boot_xs_parse_sublike() \
  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Sublike"), NULL, NULL)

#endif
