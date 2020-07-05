/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

static void func_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Sf");
}

static void func_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Ef");
}

static void func_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Lf");
}

static void func_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Nf");
}

static const struct XSParseSublikeHooks parse_func_hooks = {
  .pre_subparse    = func_pre_subparse,
  .post_blockstart = func_post_blockstart,
  .pre_blockend    = func_pre_blockend,
  .post_newcv      = func_post_newcv,
};

static void prefixed_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Sp");
}

static void prefixed_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Ep");
}

static void prefixed_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Lp");
}

static void prefixed_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *_logsv)
{
  SV *logsv = _logsv;
  sv_catpvs(logsv, "Np");
}

static const struct XSParseSublikeHooks parse_prefixed_hooks = {
  .pre_subparse    = prefixed_pre_subparse,
  .post_blockstart = prefixed_post_blockstart,
  .pre_blockend    = prefixed_pre_blockend,
  .post_newcv      = prefixed_post_newcv,
};

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
  if(kwlen != 8 || !strEQ(kw, "prefixed"))
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);

  lex_read_space(0);

  return xs_parse_sublike_any(&parse_prefixed_hooks, SvREFCNT_inc(get_sv("main::LOG", 0)),
    op_ptr);
}

MODULE = t::any  PACKAGE = t::any

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_func_hooks, SvREFCNT_inc(get_sv("main::LOG", GV_ADD)));

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
