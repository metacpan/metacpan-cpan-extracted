/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk
 */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"
#include "XSParseInfix.h"

#include "keyword.h"
#include "infix.h"

#include "perl-backcompat.c.inc"

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#include "lexer-additions.c.inc"

/* yycroak() is a long function and hard to emulate or copy-paste for our
 * purposes; we'll reïmplement a smaller version of it
 *
 * ours will croak instead of warn
 */

#define LEX_IGNORE_UTF8_HINTS   0x00000002

#define PL_linestr (PL_parser->linestr)

#ifdef USE_UTF8_SCRIPTS
#   define UTF cBOOL(!IN_BYTES)
#elif HAVE_PERL_VERSION(5, 16, 0)
#   define UTF cBOOL((PL_linestr && DO_UTF8(PL_linestr)) || ( !(PL_parser->lex_flags & LEX_IGNORE_UTF8_HINTS) && (PL_hints & HINT_UTF8)))
#else
#   define UTF cBOOL((PL_linestr && DO_UTF8(PL_linestr)) || (PL_hints & HINT_UTF8))
#endif

#if HAVE_PERL_VERSION(5, 20, 0)
#  define HAVE_UTF8f
#endif

#define yycroak(s)  S_yycroak(aTHX_ s)
static void S_yycroak(pTHX_ const char *s)
{
  SV *message = sv_2mortal(newSVpvs_flags("", 0));

  char *context = PL_parser->oldbufptr;
  STRLEN contlen = PL_parser->bufptr - PL_parser->oldbufptr;

  sv_catpvf(message, "%s at %s line %" IVdf,
      s, OutCopFILE(PL_curcop), (IV)CopLINE(PL_curcop));

  if(context)
#ifdef HAVE_UTF8f
    sv_catpvf(message, ", near \"%" UTF8f "\"", UTF8fARG(UTF, contlen, context));
#else
    sv_catpvf(message, ", near \"%" SVf "\"", SVfARG(newSVpvn_flags(context, contlen, SVs_TEMP | (UTF ? SVf_UTF8 : 0))));
#endif

  sv_catpvf(message, "\n");

  PL_parser->error_count++;
  croak_sv(message);
}

#define yycroakf(fmt, ...) yycroak(Perl_form(aTHX_ fmt, __VA_ARGS__))

#define lex_expect_unichar(c)  MY_lex_expect_unichar(aTHX_ c)
void MY_lex_expect_unichar(pTHX_ int c)
{
  if(lex_peek_unichar(0) != c)
    /* TODO: A slightly different message if c == '\'' */
    yycroakf("Expected '%c'", c);

  lex_read_unichar(0);
}

#define CHECK_PARSEFAIL      \
  if(PL_parser->error_count) \
    croak("parse failed--compilation aborted")

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
    yycroakf("Expected \"%s\"", s);

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

/* version 1's struct did not have the line on it */
typedef struct
{
  union {
    OP *op;
    CV *cv;
    SV *sv;
    int i;
    struct { SV *name; SV *value; } attr;
    PADOFFSET padix;
  };
} XSParseKeywordPiece_v1;

static bool probe_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece, void *hookdata);
static void parse_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece, void *hookdata);
static void parse_pieces(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *pieces, void *hookdata);

static bool probe_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece, void *hookdata)
{
  int argi = *argidx;

  if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
    SvGROW(argsv, SvLEN(argsv) * 2);

#define THISARG ((XSParseKeywordPiece *)SvPVX(argsv))[argi]

  THISARG.line = 
#if HAVE_PERL_VERSION(5, 20, 0)
    /* on perl 5.20 onwards, CopLINE(PL_curcop) is only set at runtime; during
     * parse the parser stores the line number directly */
    (PL_parser->preambling != NOLINE) ? PL_parser->preambling :
#endif
    CopLINE(PL_curcop);

  U32 type = piece->type & 0xFFFF;

  switch(type) {
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
      yycroak(piece->u.str);
      NOT_REACHED;

    case XS_PARSE_KEYWORD_BLOCK:
      if(lex_peek_unichar(0) != '{')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece, hookdata);
      return TRUE;

    case XS_PARSE_KEYWORD_IDENT:
      THISARG.sv = lex_scan_ident();
      if(!THISARG.sv)
        return FALSE;
      (*argidx)++;
      return TRUE;

    case XS_PARSE_KEYWORD_PACKAGENAME:
      THISARG.sv = lex_scan_packagename();
      if(!THISARG.sv)
        return FALSE;
      (*argidx)++;
      return TRUE;

    case XS_PARSE_KEYWORD_VSTRING:
      THISARG.sv = lex_scan_version(PARSE_OPTIONAL);
      if(!THISARG.sv)
        return FALSE;

      (*argidx)++;
      return TRUE;

    case XS_PARSE_KEYWORD_INFIX:
    {
      if(!XSParseInfix_parse(aTHX_ piece->u.c, &THISARG.infix))
        return FALSE;
      (*argidx)++;
      return TRUE;
    }

    case XS_PARSE_KEYWORD_SETUP:
      croak("ARGH probe_piece() should never see XS_PARSE_KEYWORD_SETUP!");

    case XS_PARSE_KEYWORD_SEQUENCE:
    {
      const struct XSParseKeywordPieceType *pieces = piece->u.pieces;

      if(!probe_piece(aTHX_ argsv, argidx, pieces++, hookdata))
        return FALSE;

      parse_pieces(aTHX_ argsv, argidx, pieces, hookdata);
      return TRUE;
    }

    case XS_PARSE_KEYWORD_CHOICE:
    {
      const struct XSParseKeywordPieceType *choices = piece->u.pieces;
      THISARG.i = 0;
      (*argidx)++; /* tentative */
      while(choices->type) {
        if(probe_piece(aTHX_ argsv, argidx, choices + 0, hookdata)) {
          return TRUE;
        }
        choices++;
        THISARG.i++;
      }
      (*argidx)--;
      return FALSE;
    }

    case XS_PARSE_KEYWORD_TAGGEDCHOICE:
    {
      const struct XSParseKeywordPieceType *choices = piece->u.pieces;
      (*argidx)++; /* tentative */
      while(choices->type) {
        if(probe_piece(aTHX_ argsv, argidx, choices + 0, hookdata)) {
          THISARG.i = choices[1].type;
          return TRUE;
        }
        choices += 2;
      }
      (*argidx)--;
      return FALSE;
    }

    case XS_PARSE_KEYWORD_SEPARATEDLIST:
    {
      const struct XSParseKeywordPieceType *pieces = piece->u.pieces;
      (*argidx)++; /* tentative */
      if(!probe_piece(aTHX_ argsv, argidx, pieces + 1, hookdata)) {
        (*argidx)--;
        return FALSE;
      }
      /* we're now committed */
      THISARG.i = 1;
      if(pieces[2].type)
        parse_pieces(aTHX_ argsv, argidx, pieces + 2, hookdata);

      if(!probe_piece(aTHX_ argsv, argidx, pieces + 0, hookdata))
        return TRUE;

      while(1) {
        parse_pieces(aTHX_ argsv, argidx, pieces + 1, hookdata);
        THISARG.i++;

        if(!probe_piece(aTHX_ argsv, argidx, pieces + 0, hookdata))
          break;
      }
      return TRUE;
    }

    case XS_PARSE_KEYWORD_PARENSCOPE:
      if(lex_peek_unichar(0) != '(')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece, hookdata);
      return TRUE;

    case XS_PARSE_KEYWORD_BRACKETSCOPE:
      if(lex_peek_unichar(0) != '[')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece, hookdata);
      return TRUE;

    case XS_PARSE_KEYWORD_BRACESCOPE:
      if(lex_peek_unichar(0) != '{')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece, hookdata);
      return TRUE;

    case XS_PARSE_KEYWORD_CHEVRONSCOPE:
      if(lex_peek_unichar(0) != '<')
        return FALSE;

      parse_piece(aTHX_ argsv, argidx, piece, hookdata);
      return TRUE;
  }

  croak("TODO: probe_piece on type=%d\n", type);
}

static void parse_piece(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *piece, void *hookdata)
{
  int argi = *argidx;

  if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
    SvGROW(argsv, SvLEN(argsv) * 2);

#define THISARG ((XSParseKeywordPiece *)SvPVX(argsv))[argi]

  THISARG.line = 
#if HAVE_PERL_VERSION(5, 20, 0)
    /* on perl 5.20 onwards, CopLINE(PL_curcop) is only set at runtime; during
     * parse the parser stores the line number directly */
    (PL_parser->preambling != NOLINE) ? PL_parser->preambling :
#endif
    CopLINE(PL_curcop);

  bool is_optional = !!(piece->type & XPK_TYPEFLAG_OPT);
  bool is_special  = !!(piece->type & XPK_TYPEFLAG_SPECIAL);
  U8 want = 0;
  switch(piece->type & (3 << 18)) {
    case XPK_TYPEFLAG_G_VOID:   want = G_VOID;   break;
    case XPK_TYPEFLAG_G_SCALAR: want = G_SCALAR; break;
    case XPK_TYPEFLAG_G_LIST:   want = G_LIST;   break;
  }
  bool is_enterleave = !!(piece->type & XPK_TYPEFLAG_ENTERLEAVE);

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
      yycroak(piece->u.str);
      NOT_REACHED;

    case XS_PARSE_KEYWORD_BLOCK:
    {
      if(is_enterleave)
        ENTER;

      I32 save_ix = block_start(1);

      if(piece->u.pieces) {
        /* The prefix pieces */
        const struct XSParseKeywordPieceType *pieces = piece->u.pieces;

        while(pieces->type) {
          if(pieces->type == XS_PARSE_KEYWORD_SETUP)
            (pieces->u.callback)(aTHX_ hookdata);
          else {
            parse_piece(aTHX_ argsv, argidx, pieces, hookdata);
            lex_read_space(0);
          }

          pieces++;
        }

        if(*argidx > argi) {
          argi = *argidx;

          if(argi >= (SvLEN(argsv) / sizeof(XSParseKeywordPiece)))
            SvGROW(argsv, SvLEN(argsv) * 2);

          intro_my();  /* in case any of the pieces was XPK_LEXVAR_MY */
        }
      }

      /* TODO: Can we name the syntax keyword here to make a better message? */
      if(lex_peek_unichar(0) != '{')
        yycroak("Expected a block");

      OP *body = parse_block(0);
      CHECK_PARSEFAIL;

      THISARG.op = block_end(save_ix, body);

      if(is_special)
        THISARG.op = op_scope(THISARG.op);

      if(want)
        THISARG.op = op_contextualize(THISARG.op, want);

      (*argidx)++;

      if(is_enterleave)
        LEAVE;

      return;
    }

    case XS_PARSE_KEYWORD_ANONSUB:
    {
      I32 floor_ix = start_subparse(FALSE, CVf_ANON);
      SAVEFREESV(PL_compcv);

      I32 save_ix = block_start(0);
      OP *body = parse_block(0);
      CHECK_PARSEFAIL;

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
        CHECK_PARSEFAIL;

        lex_read_space(0);

        lex_expect_unichar(')');
      }
      else {
        THISARG.op = parse_termexpr(0);
        CHECK_PARSEFAIL;
      }

      if(want)
        THISARG.op = op_contextualize(THISARG.op, want);

      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_LISTEXPR:
      THISARG.op = parse_listexpr(0);
      CHECK_PARSEFAIL;

      if(want)
        THISARG.op = op_contextualize(THISARG.op, want);

      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_IDENT:
      THISARG.sv = lex_scan_ident();
      if(!THISARG.sv && !is_optional)
        yycroak("Expected an identifier");
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_PACKAGENAME:
      THISARG.sv = lex_scan_packagename();
      if(!THISARG.sv && !is_optional)
        yycroak("Expected a package name");
      (*argidx)++;
      return;

    case XS_PARSE_KEYWORD_LEXVARNAME:
    case XS_PARSE_KEYWORD_LEXVAR:
    {
      /* name vs. padix begin with similar structure */
      SV *varname = lex_scan_lexvar();
      switch(SvPVX(varname)[0]) {
        case '$':
          if(!(piece->u.c & XPK_LEXVAR_SCALAR))
            yycroak("Lexical scalars are not permitted");
          break;
        case '@':
          if(!(piece->u.c & XPK_LEXVAR_ARRAY))
            yycroak("Lexical arrays are not permitted");
          break;
        case '%':
          if(!(piece->u.c & XPK_LEXVAR_HASH))
            yycroak("Lexical hashes are not permitted");
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
        yycroakf("Can't use global %s in \"my\"", SvPVX(varname));

      if(is_special)
        THISARG.padix = pad_add_name_pvn(SvPVX(varname), SvCUR(varname), 0, NULL, NULL);
      else
        yycroak("TODO: XS_PARSE_KEYWORD_LEXVAR without LEXVAR_MY");

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

    case XS_PARSE_KEYWORD_INFIX:
    {
      if(!XSParseInfix_parse(aTHX_ piece->u.c, &THISARG.infix))
        yycroak("Expected an infix operator");
      (*argidx)++;
      return;
    }

    case XS_PARSE_KEYWORD_SETUP:
      croak("ARGH parse_piece() should never see XS_PARSE_KEYWORD_SETUP!");

    case XS_PARSE_KEYWORD_SEQUENCE:
    {
      const struct XSParseKeywordPieceType *pieces = piece->u.pieces;

      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(!probe_piece(aTHX_ argsv, argidx, pieces, hookdata))
          return;
        THISARG.i++;
        pieces++;
      }

      parse_pieces(aTHX_ argsv, argidx, pieces, hookdata);
      return;
    }

    case XS_PARSE_KEYWORD_REPEATED:
      THISARG.i = 0;
      (*argidx)++;
      while(probe_piece(aTHX_ argsv, argidx, piece->u.pieces + 0, hookdata)) {
        THISARG.i++;
        parse_pieces(aTHX_ argsv, argidx, piece->u.pieces + 1, hookdata);
      }
      return;

    case XS_PARSE_KEYWORD_CHOICE:
    case XS_PARSE_KEYWORD_TAGGEDCHOICE:
      if(!probe_piece(aTHX_ argsv, argidx, piece, hookdata)) {
        THISARG.i = -1;
        (*argidx)++;
      }
      return;

    case XS_PARSE_KEYWORD_SEPARATEDLIST:
      THISARG.i = 0;
      (*argidx)++;
      while(1) {
        parse_pieces(aTHX_ argsv, argidx, piece->u.pieces + 1, hookdata);
        THISARG.i++;

        if(!probe_piece(aTHX_ argsv, argidx, piece->u.pieces + 0, hookdata))
          break;
      }
      return;

    case XS_PARSE_KEYWORD_PARENSCOPE:
      if(is_optional) {
        THISARG.i = 0;
        (*argidx)++;
        if(lex_peek_unichar(0) != '(') return;
        THISARG.i++;
      }

      lex_expect_unichar('(');
      lex_read_space(0);

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces, hookdata);

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

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces, hookdata);

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

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces, hookdata);

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

      parse_pieces(aTHX_ argsv, argidx, piece->u.pieces, hookdata);

      lex_expect_unichar('>');

      return;
  }

  croak("TODO: parse_piece on type=%d\n", type);
}

static void parse_pieces(pTHX_ SV *argsv, size_t *argidx, const struct XSParseKeywordPieceType *pieces, void *hookdata)
{
  size_t idx;
  for(idx = 0; pieces[idx].type; idx++) {
    parse_piece(aTHX_ argsv, argidx, pieces + idx, hookdata);
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
    parse_pieces(aTHX_ argsv, &argidx, hooks->pieces, reg->hookdata);
  else
    parse_piece(aTHX_ argsv, &argidx, &hooks->piece1, reg->hookdata);

  if(hooks->flags & XPK_FLAG_AUTOSEMI) {
    lex_read_space(0);

    int c = lex_peek_unichar(0);
    if(c == ';')
      lex_read_unichar(0);
    else if(!c || c == '}')
      ; /* all is good */
    else
      yycroak("Expected: ';' or end of block");
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
  else if(reg->apiver < 2) {
    /* version 1 ->build1 used to take a struct directly, not a pointer thereto */
    int (*v1_build1)(pTHX_ OP **out, XSParseKeywordPiece_v1 arg0, void *hookdata) =
      (int (*)())hooks->build1;
    XSParseKeywordPiece_v1 arg0_v1;
    Copy(args + 0, &arg0_v1, 1, XSParseKeywordPiece_v1);
    ret = (*v1_build1)(aTHX_ op, arg0_v1, reg->hookdata);
  }
  else
    ret = (*hooks->build1)(aTHX_ op, args + 0, reg->hookdata);

  switch(hooks->flags & (XPK_FLAG_EXPR|XPK_FLAG_STMT)) {
    case XPK_FLAG_EXPR:
      if(ret && (ret != KEYWORD_PLUGIN_EXPR))
        yycroakf("Expected parse function for '%s' keyword to return KEYWORD_PLUGIN_EXPR but it did not",
          reg->kwname);

    case XPK_FLAG_STMT:
      if(ret && (ret != KEYWORD_PLUGIN_STMT))
        yycroakf("Expected parse function for '%s' keyword to return KEYWORD_PLUGIN_STMT but it did not",
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

void XSParseKeyword_register_v1(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  reg(aTHX_ kwname, 1, hooks, hookdata);
}

void XSParseKeyword_register_v2(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  reg(aTHX_ kwname, 2, hooks, hookdata);
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

void XSParseKeyword_boot(pTHX)
{
  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
}
