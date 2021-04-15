#ifndef __XS_PARSE_KEYWORD_H__
#define __XS_PARSE_KEYWORD_H__

#define XSPARSEKEYWORD_ABI_VERSION 0

struct XSParseKeywordPieceType;
struct XSParseKeywordPieceType {
  int type;
  union {
    char                                  c;      /* LITERALCHAR */
    const char                           *str;    /* LITERALSTR */
    const struct XSParseKeywordPieceType *pieces; /* SCOPEs */
  } u;
};

enum {
  /* skip zero */
  XS_PARSE_KEYWORD_BLOCK = 1,     /* op */
  XS_PARSE_KEYWORD_ANONSUB,       /* cv */
  /* TODO: XS_PARSE_KEYWORD_ARITHEXPR = 3 */
  XS_PARSE_KEYWORD_TERMEXPR = 4,  /* op */
  XS_PARSE_KEYWORD_LISTEXPR,      /* op */
  /* TODO: XS_PARSE_KEYWORD_FULLEXPR = 6 */
  XS_PARSE_KEYWORD_IDENT = 7,     /* sv */
  XS_PARSE_KEYWORD_PACKAGENAME,   /* sv */
  XS_PARSE_KEYWORD_LITERALCHAR = 0x10,
  XS_PARSE_KEYWORD_LITERALSTR,
  XS_PARSE_KEYWORD_OPTIONAL = 0x20,
  XS_PARSE_KEYWORD_REPEATED,
  XS_PARSE_KEYWORD_CHOICE,
  XS_PARSE_KEYWORD_TAGGEDCHOICE,
  XS_PARSE_KEYWORD_FAILURE = 0x2f,
  XS_PARSE_KEYWORD_PARENSCOPE = 0x30, /* (...) */
  XS_PARSE_KEYWORD_BRACKETSCOPE,      /* [...] */
  XS_PARSE_KEYWORD_BRACESCOPE,        /* {...} */
  XS_PARSE_KEYWORD_CHEVRONSCOPE,      /* <...> */
};

#define XPK_BLOCK    {.type = XS_PARSE_KEYWORD_BLOCK}
#define XPK_ANONSUB  {.type = XS_PARSE_KEYWORD_ANONSUB}
#define XPK_TERMEXPR {.type = XS_PARSE_KEYWORD_TERMEXPR}
#define XPK_LISTEXPR {.type = XS_PARSE_KEYWORD_LISTEXPR}
#define XPK_IDENT    {.type = XS_PARSE_KEYWORD_IDENT}
#define XPK_PACKAGENAME {.type = XS_PARSE_KEYWORD_PACKAGENAME}

#define XPK_COLON {.type = XS_PARSE_KEYWORD_LITERALCHAR, .u.c = ':'}

#define XPK_STRING(s) {.type = XS_PARSE_KEYWORD_LITERALSTR, .u.str = (const char *)s}

/* First piece of these must be something probe-able */
#define XPK_OPTIONAL(...) \
  {.type = XS_PARSE_KEYWORD_OPTIONAL, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}
#define XPK_REPEATED(...) \
  {.type = XS_PARSE_KEYWORD_REPEATED, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}
/* Every piece must be probeable */
#define XPK_CHOICE(...) \
  {.type = XS_PARSE_KEYWORD_CHOICE, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}
/* Every piece must be probeable, and followed by XPK_TAG */
#define XPK_TAGGEDCHOICE(...) \
  {.type = XS_PARSE_KEYWORD_TAGGEDCHOICE, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0, 0 }}
#define XPK_TAG(val) \
  {.type = val}

#define XPK_FAILURE(s) {.type = XS_PARSE_KEYWORD_FAILURE, .u.str = (const char *)s}

#define XPK_PARENSCOPE(...) \
  {.type = XS_PARSE_KEYWORD_PARENSCOPE, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}
#define XPK_BRACKETSCOPE(...) \
  {.type = XS_PARSE_KEYWORD_BRACKETSCOPE, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}
#define XPK_BRACESCOPE(...) \
  {.type = XS_PARSE_KEYWORD_BRACESCOPE, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}
#define XPK_CHEVRONSCOPE(...) \
  {.type = XS_PARSE_KEYWORD_CHEVRONSCOPE, .u.pieces = (const struct XSParseKeywordPieceType []){ __VA_ARGS__, 0 }}

typedef union {
  OP *op;
  CV *cv;
  SV *sv;
  int i;
} XSParseKeywordPiece;

struct XSParseKeywordHooks {
  U32 flags; /* not used yet but reserves the space without breaking ABI later */

  /* used by build1 */
  struct XSParseKeywordPieceType piece1;
  /* alternatively, used by build */
  const struct XSParseKeywordPieceType *pieces;

  /* These two hooks are ANDed together; both must pass, if present */
  const char *permit_hintkey;
  bool (*permit) (pTHX_ void *hookdata);

  void (*check)(pTHX_ void *hookdata);

  /* These are alternatives; the first one defined is used */
  int (*parse)(pTHX_ OP **opp, void *hookdata);
  int (*build)(pTHX_ OP **out, XSParseKeywordPiece *pieces, size_t npieces, void *hookdata);
  int (*build1)(pTHX_ OP **out, XSParseKeywordPiece arg0, void *hookdata);
};

static void (*register_xs_parse_keyword_func)(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata);
#define register_xs_parse_keyword(kwname, hooks, hookdata)  S_register_xs_parse_keyword(aTHX_ kwname, hooks, hookdata)
static void S_register_xs_parse_keyword(pTHX_ const char *kwname, const struct XSParseKeywordHooks *hooks, void *hookdata)
{
  if(!register_xs_parse_keyword_func)
    croak("Must call boot_xs_parse_keyword() first");

  return (*register_xs_parse_keyword_func)(aTHX_ kwname, hooks, hookdata);
}

#define boot_xs_parse_keyword(ver) S_boot_xs_parse_keyword(aTHX_ ver)
static void S_boot_xs_parse_keyword(pTHX_ double ver) {
  SV **svp;
  SV *versv = ver ? newSVnv(ver) : NULL;

  load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("XS::Parse::Keyword"), versv, NULL);

  svp = hv_fetchs(PL_modglobal, "XS::Parse::Keyword/ABIVERSION", 0);
  if(!svp)
    croak("XS::Parse::Keyword ABI version missing");
  int abi_version = SvIV(*svp);
  if(abi_version != XSPARSEKEYWORD_ABI_VERSION)
    croak("XS::Parse::Keyword ABI version mismatch - library provides %d, compiled for %d",
        abi_version, XSPARSEKEYWORD_ABI_VERSION);

  register_xs_parse_keyword_func = INT2PTR(void (*)(pTHX_ const char *, const struct XSParseKeywordHooks *, void *),
      SvUV(*hv_fetchs(PL_modglobal, "XS::Parse::Keyword/register()", 0)));
}

#endif
