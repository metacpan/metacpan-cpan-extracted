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

static void func_post_blockstart(pTHX)
{
  sv_catpvs(get_sv("main::LOG", 0), "Ef");
}

static OP *func_pre_blockend(pTHX_ OP *body)
{
  sv_catpvs(get_sv("main::LOG", 0), "Lf");
  return body;
}

static void func_post_newcv(pTHX_ CV *cv)
{
  sv_catpvs(get_sv("main::LOG", 0), "Nf");
}

static const struct XSParseSublikeHooks parse_func_hooks = {
  .post_blockstart = func_post_blockstart,
  .pre_blockend    = func_pre_blockend,
  .post_newcv      = func_post_newcv,
};

static void prefixed_post_blockstart(pTHX)
{
  sv_catpvs(get_sv("main::LOG", 0), "Ep");
}

static OP *prefixed_pre_blockend(pTHX_ OP *body)
{
  sv_catpvs(get_sv("main::LOG", 0), "Lp");
  return body;
}

static void prefixed_post_newcv(pTHX_ CV *cv)
{
  sv_catpvs(get_sv("main::LOG", 0), "Np");
}

static const struct XSParseSublikeHooks parse_prefixed_hooks = {
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

  return xs_parse_sublike_any(&parse_prefixed_hooks, op_ptr);
}

MODULE = t::any  PACKAGE = t::any

BOOT:
  boot_xs_parse_sublike(0);

  register_xs_parse_sublike("func", &parse_func_hooks);

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
