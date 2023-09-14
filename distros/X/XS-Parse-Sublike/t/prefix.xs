/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

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
  .permit_hintkey = "t::prefix/func",
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
  .flags = XS_PARSE_SUBLIKE_FLAG_PREFIX,
  .permit_hintkey = "t::prefix/prefixed",

  .pre_subparse    = prefixed_pre_subparse,
  .post_blockstart = prefixed_post_blockstart,
  .pre_blockend    = prefixed_pre_blockend,
  .post_newcv      = prefixed_post_newcv,
};

MODULE = t::prefix  PACKAGE = t::prefix

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_func_hooks, SvREFCNT_inc(get_sv("main::LOG", GV_ADD)));
  register_xs_parse_sublike("prefixed", &parse_prefixed_hooks, SvREFCNT_inc(get_sv("main::LOG", GV_ADD)));
