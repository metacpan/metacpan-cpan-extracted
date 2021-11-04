/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#include "sv_setrv.c.inc"

static bool stage_permit(pTHX_ void *_)
{
  if(!hv_fetchs(GvHV(PL_hintgv), "t::stages/permit", 0))
    return FALSE;

  return TRUE;
}

static void stage_pre_subparse(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  if(hv_fetchs(GvHV(PL_hintgv), "t::stages/pre_subparse-capture", 0)) {
    sv_setsv(get_sv("t::stages::captured", GV_ADD), get_sv("main::VAR", 0));
  }
}

static void stage_post_blockstart(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  if(hv_fetchs(GvHV(PL_hintgv), "t::stages/post_blockstart-capture", 0)) {
    sv_setsv(get_sv("t::stages::captured", GV_ADD), get_sv("main::VAR", 0));
  }
}

static void stage_pre_blockend(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  if(hv_fetchs(GvHV(PL_hintgv), "t::stages/pre_blockend-capture", 0)) {
    sv_setsv(get_sv("t::stages::captured", GV_ADD), get_sv("main::VAR", 0));
  }
}

static void stage_post_newcv(pTHX_ struct XSParseSublikeContext *ctx, void *_)
{
  if(hv_fetchs(GvHV(PL_hintgv), "t::stages/post_newcv-capture-cv", 0)) {
    sv_setrv_inc(get_sv("t::stages::captured", GV_ADD), (SV *)ctx->cv);
  }
}

static bool stage_filter_attr(pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *value, void *_)
{
  if(!hv_fetchs(GvHV(PL_hintgv), "t::stages/filter_attr-capture", 0))
    return FALSE;

  AV *av = newAV();
  av_push(av, SvREFCNT_inc(attr));
  av_push(av, SvREFCNT_inc(value));

  sv_setrv_noinc(get_sv("t::stages::captured", GV_ADD), (SV *)av);
  return TRUE;
}

static const struct XSParseSublikeHooks parse_stages_hooks = {
  .flags           = XS_PARSE_SUBLIKE_FLAG_FILTERATTRS,
  .permit          = stage_permit,
  .pre_subparse    = stage_pre_subparse,
  .post_blockstart = stage_post_blockstart,
  .pre_blockend    = stage_pre_blockend,
  .post_newcv      = stage_post_newcv,

  .filter_attr     = stage_filter_attr,
};

MODULE = t::stages  PACKAGE = t::stages

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("stages", &parse_stages_hooks, NULL);
