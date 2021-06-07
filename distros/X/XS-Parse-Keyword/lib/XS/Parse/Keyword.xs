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

  int apiver;
  const struct XSParseKeywordHooks *hooks;
  void *hookdata;

  STRLEN permit_hintkey_len;
};

static bool probe_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece);
static void parse_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece);
static void parse_pieces(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *pieces);

static bool probe_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece)
{
  int argi = *argidx;

  if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
    SvGROW(argsv, SvLEN(argsv) * 2);

#define THISARG ((XSParseKeywordPiece *)SvPVX(argsv))[argi]

  switch(piece->type) {
    case XS_PARSE_KEYWORD_LITERALCHAR:
      if(lex_peek_unichar(0) != piece->u.c)
        return FALSE;

      lex_read_unichar(0);
      lex_read_space(0);
      return TRUE;

    case XS_PARSE_KEYWORD_LITERALSTR:
    {
      STRLEN len = lex_probe_str(piece->u.str);
      if(!len)
        return FALSE;

      lex_read_to(PL_parser->bufptr + len);
      lex_read_space(0);
      return TRUE;
    }

    case XS_PARSE_KEYWORD_FAILURE:
      croak("%s", piece->u.str);
      NOT_REACHED;

    case XS_PARSE_KEYWORD_SEQUENCE:
      if(!probe_piece(aTHX_ argsv, argidx, piece->u.pieces + 0))
        return FALSE;

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces + 1);
      return TRUE;

    case XS_PARSE_KEYWORD_VSTRING:
      THISARG.sv = lex_scan_version(PARSE_OPTIONAL);
      if(!THISARG.sv)
        return FALSE;

      (*argidx)++;
      return TRUE;

    case XS_PARSE_KEYWORD_PARENSCOPE:
      if(lex_peek_unichar(0) != '(')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece);
      return TRUE;

    case XS_PARSE_KEYWORD_BRACKETSCOPE:
      if(lex_peek_unichar(0) != '[')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece);
      return TRUE;

    case XS_PARSE_KEYWORD_BRACESCOPE:
      if(lex_peek_unichar(0) != '{')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece);
      return TRUE;

    case XS_PARSE_KEYWORD_CHEVRONSCOPE:
      if(lex_peek_unichar(0) != '<')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece);
      return TRUE;
  }

  croak("TODO: probe_piece on type=%d\n", piece->type);
}

static void parse_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece)
{
  int argi = *argidx;

  if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
    SvGROW(argsv, SvLEN(argsv) * 2);

#define THISARG ((XSParseKeywordPiece *)SvPVX(argsv))[argi]

  bool is_optional = !!(piece->type & XPK_TYPEFLAG_OPT);
  bool is_special  = !!(piece->type & XPK_TYPEFLAG_SPECIAL);
  U8 want = 0;
  switch(piece->type & (3 << 18)) {
    case XPK_TYPEFLAG_G_VOID:   want = G_VOID; break;
    case XPK_TYPEFLAG_G_SCALAR: want = G_SCALAR; break;
    case XPK_TYPEFLAG_G_LIST:   want = G_ARRAY; break;
  }

  U32 type = piece->type & 0xFFFF;

  switch(type) {
    case 0:
      return;

    case XS_PARSE_KEYWORD_LITERALCHAR:
      lex_expect_unichar(piece->u.c);
      return;

    case XS_PARSE_KEYWORD_LITERALSTR:
      lex_expect_str(piece->u.str);
      return;

    case XS_PARSE_KEYWORD_FAILURE:
      croak("%s", piece->u.str);
      NOT_REACHED;

    case XS_PARSE_KEYWORD_BLOCK:
    {
      I32 save_ix = block_start(1);

      if(piece->u.pieces) {
        /* The prefix pieces */
        parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

        if(*argidx > argi) {
          argi = *argidx;

          if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
            SvGROW(argsv, SvLEN(argsv) * 2);

          intro_my();  /* in case any of the pieces was XPK_LEXVAR_MY */
        }
      }

      /* TODO: Can we name the syntax keyword here to make a better message? */
      if(lex_peek_unichar(0) != '{')
        croak("Expected a block");

      OP *body = parse_block(0);
      THISARG.op = block_end(save_ix, body);

      if(is_special)
        THISARG.op = op_scope(THISARG.op);

      if(want)
        THISARG.op = op_contextualize(THISARG.op, want);

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

      if(want)
        THISARG.op = op_contextualize(THISARG.op, want);

      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_LISTEXPR:
      THISARG.op = parse_listexpr(0);

      if(want)
        THISARG.op = op_contextualize(THISARG.op, want);

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

    case XS_PARSE_KEYWORD_LEXVARNAME:
    case XS_PARSE_KEYWORD_LEXVAR:
    {
      /* name vs. padix begin with similar structure */
      SV *varname = lex_scan_lexvar();
      switch(SvPVX(varname)[0]) {
        case '$':
          if(!piece->u.c & XPK_LEXVAR_SCALAR)
            croak("Lexical scalars are not permitted");
          break;
        case '@':
          if(!piece->u.c & XPK_LEXVAR_ARRAY)
            croak("Lexical arrays are not permitted");
          break;
        case '%':
          if(!piece->u.c & XPK_LEXVAR_HASH)
            croak("Lexical hashes are not permitted");
          break;
      }
      if(type == XS_PARSE_KEYWORD_LEXVARNAME) {
        THISARG.sv = varname;
        (*argidx)++;
        return;
      }

      SAVEFREESV(varname);

      /* Forbid $_ / @_ / %_ */
      if(SvCUR(varname) == 2 && SvPVX(varname)[1] == '_')
        croak("Can't use global %s in \"my\"", SvPVX(varname));

      if(is_special)
        THISARG.padix = pad_add_name_pvn(SvPVX(varname), SvCUR(varname), 0, NULL, NULL);
      else
        croak("TODO: XS_PARSE_KEYWORD_LEXVAR without LEXVAR_MY");

      (*argidx)++;
      return;
    }

    case XS_PARSE_KEYWORD_ATTRS:
    {
      THISARG.i = 0;
      (*argidx)++;

      if(lex_peek_unichar(0) == ':') {
        lex_read_unichar(0);
        lex_read_space(0);

        SV *attrname = newSV(0), *attrval = newSV(0);
        SAVEFREESV(attrname); SAVEFREESV(attrval);

        while(lex_scan_attrval_into(attrname, attrval)) {
          lex_read_space(0);

          if(*argidx >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
            SvGROW(argsv, SvLEN(argsv) * 2);

          XSParseKeywordPiece *arg = &((XSParseKeywordPiece *)SvPVX(argsv))[*argidx];
          arg->attr.name  = newSVsv(attrname);
          arg->attr.value = newSVsv(attrval);

          THISARG.i++;
          (*argidx)++;

          /* Accept additional colons to prefix additional attrs, but do not require them */
          if(lex_peek_unichar(0) == ':') {
            lex_read_unichar(0);
            lex_read_space(0);
          }
        }
      }

      return;
    }

    case XS_PARSE_KEYWORD_VSTRING:
      THISARG.sv = lex_scan_version(is_optional ? PARSE_OPTIONAL : 0);
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_SEQUENCE:
    {
      const struct XSParseKeywordPieceType *pieces = piece->u.pieces;

      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(!probe_piece(aTHX_ argsv, argidx, pieces))
          return;
        THISARG.i++;
        pieces++;
      }

      parse_pieces(aTHX_ argsv, argidx, pieces);
      return;
    }

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

    case XS_PARSE_KEYWORD_SEPARATEDLIST:
    {
      THISARG.i = 0;
      (*argidx)++;
      while(1) {
        parse_pieces(aTHX_ argsv, argidx, piece->u.pieces + 1);
        THISARG.i++;

        if(!probe_piece(aTHX_ argsv, argidx, piece->u.pieces + 0))
          break;
      }
      return;
    }

    case XS_PARSE_KEYWORD_PARENSCOPE:
      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(lex_peek_unichar(0) != '(') return;
        THISARG.i++;
      }

      lex_expect_unichar('(');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar(')');

      return;

    case XS_PARSE_KEYWORD_BRACKETSCOPE:
      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(lex_peek_unichar(0) != '[') return;
        THISARG.i++;
      }

      lex_expect_unichar('[');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar(']');

      return;

    case XS_PARSE_KEYWORD_BRACESCOPE:
      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(lex_peek_unichar(0) != '{') return;
        THISARG.i++;
      }

      lex_expect_unichar('{');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar('}');

      return;

    case XS_PARSE_KEYWORD_CHEVRONSCOPE:
      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(lex_peek_unichar(0) != '<') return;
        THISARG.i++;
      }

      lex_expect_unichar('<');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces);

      lex_expect_unichar('>');

      return;
  }

  croak("TODO: parse_piece on type=%d\n", type);
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
  if(hooks->build)
    parse_pieces(aTHX_ argsv, &argidx, hooks->pieces);
  else
    parse_piece(aTHX_ argsv, &argidx, &hooks->piece1);

  if(hooks->flags & XPK_FLAG_AUTOSEMI) {
    lex_read_space(0);

    int c = lex_peek_unichar(0);
    if(c == ';')
      lex_read_unichar(0);
    else if(!c || c == '}')
      ; /* all is good */
    else
      croak("Expected: ';' or end of block");
  }

  XSParseKeywordPiece *args = (XSParseKeywordPiece *)SvPVX(argsv);

  int ret;
  if(hooks->build) {
    /* build function takes an array of pointers to piece structs, so we can
     * add new fields to the end of them without breaking back-compat. */
    SV *ptrssv = newSV(argidx * sizeof(XSParseKeywordPiece *));
    XSParseKeywordPiece **argptrs = (XSParseKeywordPiece **)SvPVX(ptrssv);
    SAVEFREESV(ptrssv);

    int i;
    for(i = 0; i < argidx; i++)
      argptrs[i] = &args[i];

    ret = (*hooks->build)(aTHX_ op, argptrs, argidx, reg->hookdata);
  }
  else
    ret = (*hooks->build1)(aTHX_ op, args[0], reg->hookdata);

  switch(hooks->flags & (XPK_FLAG_EXPR|XPK_FLAG_STMT)) {
    case XPK_FLAG_EXPR:
      if(ret != KEYWORD_PLUGIN_EXPR)
        croak("Expected parse function for '%s' keyword to return KEYWORD_PLUGIN_EXPR but it did not",
          reg->kwname);

    case XPK_FLAG_STMT:
      if(ret != KEYWORD_PLUGIN_STMT)
        croak("Expected parse function for '%s' keyword to return KEYWORD_PLUGIN_STMT but it did not",
          reg->kwname);
  }

  return ret;
}

static struct Registration *registrations;

static void reg(pTHX_ const char *kwname, int apiver, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  if(!hooks->build1 && !hooks->build && !hooks->parse)
    croak("struct XSParseKeywordHooks requires either a .build1, a .build, or .parse stage");

  struct Registration *reg;
  Newx(reg, 1, struct Registration);

  reg->kwname = savepv(kwname);
  reg->kwlen  = strlen(kwname);

  reg->apiver   = apiver;
  reg->hooks    = hooks;
  reg->hookdata = hookdata;

  if(hooks->permit_hintkey)
    reg->permit_hintkey_len = strlen(hooks->permit_hintkey);

  {
    reg->next = registrations;
    registrations = reg;
  }
}

static void IMPL_register_v1(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  reg(aTHX_ kwname, 1, hooks, hookdata);
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
  /* legacy version0 support */
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION", 1), XSPARSEKEYWORD_ABI_VERSION);

  /* newer versions */
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION_MIN", 1), XSPARSEKEYWORD_ABI_VERSION);
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION_MAX", 1), 1);

  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/register()@1", 1), PTR2UV(&IMPL_register_v1));

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
