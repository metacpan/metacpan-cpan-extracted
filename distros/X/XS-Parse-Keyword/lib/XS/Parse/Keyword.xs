/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#include "lexer-additions.c.inc"

#define lex_expect_unichar(c)  MY_lex_expect_unichar(aTHX_ c)
void MY_lex_expect_unichar(pTHX_ int c)
{
  if(lex_peek_unichar(0) != c)
    /* TODO: A slightly different message if c == '\'' */
    croak("Expected '%c'", c);

  lex_read_unichar(0);
}

/* TODO: Only ASCII */
#define lex_probe_str(s)   MY_lex_probe_str(aTHX_ s)
STRLEN MY_lex_probe_str(pTHX_ const char *s)
{
  STRLEN i;
  for(i = 0; s[i]; i++) {
    if(s[i] != PL_parser->bufptr[i])
      return 0;
  }

  return i;
}

#define lex_expect_str(s)  MY_lex_expect_str(aTHX_ s)
void MY_lex_expect_str(pTHX_ const char *s)
{
  STRLEN len = lex_probe_str(s);
  if(!len)
    croak("Expected \"%s\"", s);

  lex_read_to(PL_parser->bufptr + len);
}

struct Registration;
struct Registration {
  struct Registration *next;
  const char *kwname;
  STRLEN      kwlen;

  const struct XSParseKeywordHooks *hooks;
  void *hookdata;

  STRLEN permit_hintkey_len;
};

static void parse_pieces(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *pieces);

static bool probe_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece)
{
  STRLEN len;

  switch(piece->type) {
    case XS_PARSE_KEYWORD_LITERALSTR:
      len = lex_probe_str(piece->u.str);
      if(!len)
        return FALSE;

      lex_read_to(PL_parser->bufptr + len);
      lex_read_space(0);
      return TRUE;

    case XS_PARSE_KEYWORD_FAILURE:
      croak("%s", piece->u.str);
      NOT_REACHED;
  }

  croak("TODO: probe_piece on type=%d\n", piece->type);
}

static void parse_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece)
{
  int argi = *argidx;

  if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
    SvGROW(argsv, SvLEN(argsv) * 2);

#define THISARG ((XSParseKeywordPiece *)SvPVX(argsv))[argi]

  switch(piece->type) {
    case 0:
      return;

    case XS_PARSE_KEYWORD_BLOCK:
    {
      /* TODO: Can we name the syntax keyword here to make a better message? */
      if(lex_peek_unichar(0) != '{')
        croak("Expected a block");

      I32 save_ix = block_start(0);
      OP *body = parse_block(0);
      THISARG.op = block_end(save_ix, body);
      (*argidx)++;
      return;
    }

    case XS_PARSE_KEYWORD_ANONSUB:
    {
      I32 floor_ix = start_subparse(FALSE, CVf_ANON);
      SAVEFREESV(PL_compcv);

      I32 save_ix = block_start(0);
      OP *body = parse_block(0);
      SvREFCNT_inc(PL_compcv);
      body = block_end(save_ix, body);

      THISARG.cv = newATTRSUB(floor_ix, NULL, NULL, NULL, body);
      (*argidx)++;
      return;
    }

    case XS_PARSE_KEYWORD_TERMEXPR:
      /* TODO: This auto-parens behaviour ought to be tuneable, depend on how
       * many args, open at i=0 and close at i=MAX, etc...
       */
      if(lex_peek_unichar(0) == '(') {
        /* consume a fullexpr and stop at the close paren */
        lex_read_unichar(0);

        THISARG.op = parse_fullexpr(0);
        lex_read_space(0);

        lex_expect_unichar(')');
      }
      else
        THISARG.op = parse_termexpr(0);
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_LISTEXPR:
      THISARG.op = parse_listexpr(0);
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_IDENT:
      THISARG.sv = lex_scan_ident();
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_PACKAGENAME:
      THISARG.sv = lex_scan_packagename();
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_LITERALCHAR:
      lex_expect_unichar(piece->u.c);
      return;

    case XS_PARSE_KEYWORD_LITERALSTR:
      lex_expect_str(piece->u.str);
      return;

    case XS_PARSE_KEYWORD_OPTIONAL:
      THISARG.i = 0;
      (*argidx)++;
      if(probe_piece(aTHX_ argsv, argidx, piece->u.pieces + 0)) {
        THISARG.i++;
        parse_pieces(aTHX_ argsv, argidx, piece->u.pieces + 1);
      }
      return;

    case XS_PARSE_KEYWORD_REPEATED:
      THISARG.i = 0;
      (*argidx)++;
      while(probe_piece(aTHX_ argsv, argidx, piece->u.pieces + 0)) {
        THISARG.i++;
        parse_pieces(aTHX_ argsv, argidx, piece->u.pieces + 1);
      }
      return;

    case XS_PARSE_KEYWORD_CHOICE:
    {
      const struct XSParseKeywordPieceType *choices = piece->u.pieces;
      THISARG.i = 0;
      (*argidx)++;
      while(choices->type) {
        if(probe_piece(aTHX_ argsv, argidx, choices + 0))
          return;
        choices++;
        THISARG.i++;
      }
      THISARG.i = -1;
      return;
    }

    case XS_PARSE_KEYWORD_TAGGEDCHOICE:
    {
      const struct XSParseKeywordPieceType *choices = piece->u.pieces;
      THISARG.i = 0;
      (*argidx)++;
      while(choices->type) {
        if(probe_piece(aTHX_ argsv, argidx, choices + 0)) {
          THISARG.i = choices[1].type;
          return;
        }
        choices += 2;
      }
      THISARG.i = -1;
      return;
    }

    case XS_PARSE_KEYWORD_FAILURE:
      croak("%s", piece->u.str);
      NOT_REACHED;

    case XS_PARSE_KEYWORD_PARENSCOPE:
      lex_expect_unichar('(');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar(')');

      return;

    case XS_PARSE_KEYWORD_BRACKETSCOPE:
      lex_expect_unichar('[');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar(']');

      return;

    case XS_PARSE_KEYWORD_BRACESCOPE:
      lex_expect_unichar('{');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar('}');

      return;

    case XS_PARSE_KEYWORD_CHEVRONSCOPE:
      lex_expect_unichar('<');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar('>');

      return;
  }

  croak("TODO: parse_piece on type=%d\n", piece->type);
}

static void parse_pieces(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *pieces)
{
  size_t idx;
  for(idx = 0; pieces[idx].type; idx++) {
    parse_piece(aTHX_ argsv, argidx, pieces + idx);
    lex_read_space(0);
  }
}

static int parse(pTHX_ OP **op, struct Registration *reg)
{
  const struct XSParseKeywordHooks *hooks = reg->hooks;

  if(hooks->parse)
    return (*hooks->parse)(aTHX_ op, reg->hookdata);

  /* parse in pieces */

  /* use the PV buffer of this SV as a growable array of args */
  size_t maxargs = 4;
  SV *argsv = newSV(maxargs * sizeof(XSParseKeywordPiece));
  SAVEFREESV(argsv);

  size_t argidx = 0;
  if(hooks->build) {
    parse_pieces(aTHX_ argsv, &argidx, hooks->pieces);
    XSParseKeywordPiece *args = (XSParseKeywordPiece *)SvPVX(argsv);
    return (*hooks->build)(aTHX_ op, args, argidx, reg->hookdata);
  }
  else {
    parse_piece(aTHX_ argsv, &argidx, &hooks->piece1);
    XSParseKeywordPiece *args = (XSParseKeywordPiece *)SvPVX(argsv);
    return (*hooks->build1)(aTHX_ op, args[0], reg->hookdata);
  }
}

static struct Registration *registrations;

static void IMPL_register(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  if(!hooks->build1 && !hooks->build && !hooks->parse)
    croak("struct XSParseKeywordHooks requires either a .build1, a .build, or .parse stage");

  struct Registration *reg;
  Newx(reg, 1, struct Registration);

  reg->kwname = savepv(kwname);
  reg->kwlen  = strlen(kwname);

  reg->hooks    = hooks;
  reg->hookdata = hookdata;

  if(hooks->permit_hintkey)
    reg->permit_hintkey_len = strlen(hooks->permit_hintkey);

  {
    reg->next = registrations;
    registrations = reg;
  }
}

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op)
{
  if(PL_parser && PL_parser->error_count)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);

  HV *hints = GvHV(PL_hintgv);

  struct Registration *reg;
  for(reg = registrations; reg; reg = reg->next) {
    if(reg->kwlen != kwlen || !strEQ(reg->kwname, kw))
      continue;

    if(reg->hooks->permit_hintkey &&
      (!hints || !hv_fetch(hints, reg->hooks->permit_hintkey, reg->permit_hintkey_len, 0)))
      continue;

    if(reg->hooks->permit &&
      !(*reg->hooks->permit)(aTHX_ reg->hookdata))
      continue;

    if(reg->hooks->check)
      (*reg->hooks->check)(aTHX_ reg->hookdata);

    *op = NULL;

    lex_read_space(0);

    int ret = parse(aTHX_ op, reg);

    lex_read_space(0);

    if(ret && !*op)
      *op = newOP(OP_NULL, 0);

    return ret;
  }

  return (*next_keyword_plugin)(aTHX_ kw, kwlen, op);
}

MODULE = XS::Parse::Keyword    PACKAGE = XS::Parse::Keyword

BOOT:
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION", 1), XSPARSEKEYWORD_ABI_VERSION);

  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/register()", 1), PTR2UV(&IMPL_register));

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
