/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019-2020 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 31, 3)
#  define HAVE_PARSE_SUBSIGNATURE
#elif HAVE_PERL_VERSION(5, 26, 0)
#  include "parse_subsignature.c.inc"
#  define HAVE_PARSE_SUBSIGNATURE
#endif

#ifndef block_end
#define block_end(a,b)         Perl_block_end(aTHX_ a,b)
#endif

#ifndef block_start
#define block_start(a)         Perl_block_start(aTHX_ a)
#endif

#include "lexer-additions.c.inc"

static int IMPL_xs_parse_sublike(pTHX_ struct XSParseSublikeHooks *hooks, OP **op_ptr)
{
  SV *name = lex_scan_ident();
  lex_read_space(0);

  ENTER_with_name("parse_block");
  /* From here onwards any `return` must be prefixed by LEAVE_with_name() */

  I32 floor_ix = start_subparse(FALSE, name ? 0 : CVf_ANON);
  SAVEFREESV(PL_compcv);

  OP *attrs = NULL;
  if(lex_peek_unichar(0) == ':') {
    lex_read_unichar(0);

    attrs = lex_scan_attrs(PL_compcv);
  }

  PL_hints |= HINT_LOCALIZE_HH;
  I32 save_ix = block_start(TRUE);

  if(hooks->post_blockstart)
    (*hooks->post_blockstart)(aTHX);

#ifdef HAVE_PARSE_SUBSIGNATURE
  OP *sigop = NULL;
  if(lex_peek_unichar(0) == '(') {
    lex_read_unichar(0);

    sigop = parse_subsignature(0);
    lex_read_space(0);

    if(PL_parser->error_count) {
      LEAVE_with_name("parse_block");
      return 0;
    }

    if(lex_peek_unichar(0) != ')')
      croak("Expected ')'");
    lex_read_unichar(0);
    lex_read_space(0);
  }
#endif

  OP *body = parse_block(0);
  SvREFCNT_inc(PL_compcv);

#ifdef HAVE_PARSE_SUBSIGNATURE
  if(sigop)
    body = op_append_list(OP_LINESEQ, sigop, body);
#endif

  if(PL_parser->error_count) {
    /* parse_block() still sometimes returns a valid body even if a parse
     * error happens.
     * We need to destroy this partial body before returning a valid(ish)
     * state to the keyword hook mechanism, so it will find the error count
     * correctly
     *   See https://rt.cpan.org/Ticket/Display.html?id=130417
     */
#ifdef HAVE_PARSE_SUBSIGNATURE
    if(sigop)
      op_free(sigop);
#endif
    op_free(body);
    *op_ptr = newOP(OP_NULL, 0);
    if(name) {
      SvREFCNT_dec(name);
      LEAVE_with_name("parse_block");
      return KEYWORD_PLUGIN_STMT;
    }
    else {
      LEAVE_with_name("parse_block");
      return KEYWORD_PLUGIN_EXPR;
    }
  }

  if(hooks->pre_blockend)
    body = (*hooks->pre_blockend)(aTHX_ body);

  body = block_end(save_ix, body);

  CV *cv = newATTRSUB(floor_ix,
    name ? newSVOP(OP_CONST, 0, SvREFCNT_inc(name)) : NULL,
    NULL,
    attrs,
    body);

  if(hooks->post_newcv)
    (*hooks->post_newcv)(aTHX_ cv);

  LEAVE_with_name("parse_block");

  if(name) {
    *op_ptr = newOP(OP_NULL, 0);

    SvREFCNT_dec(name);
    return KEYWORD_PLUGIN_STMT;
  }
  else {
    *op_ptr = newUNOP(OP_REFGEN, 0,
      newSVOP(OP_ANONCODE, 0, (SV *)cv));

    return KEYWORD_PLUGIN_EXPR;
  }
}

MODULE = XS::Parse::Sublike    PACKAGE = XS::Parse::Sublike

BOOT:
  sv_setuv(get_sv("XS::Parse::Sublike::PARSE", GV_ADD), PTR2UV(&IMPL_xs_parse_sublike));
