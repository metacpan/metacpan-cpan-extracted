/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"

#include "perl-backcompat.c.inc"
#include "perl-additions.c.inc"

#include "newSVop.c.inc"

struct XPKFPHookdata {
  /* Phase callbacks */
  CV *permitcv;
  CV *checkcv;
  CV *buildcv;

  SV *hookdata;
};

static const struct XSParseKeywordPieceType piece_zero = {0};

#define make_pieces_array(piecesav)  S_make_pieces_array(aTHX_ piecesav)
static const struct XSParseKeywordPieceType *S_make_pieces_array(pTHX_ AV *piecesav)
{
  U32 npieces = av_count(piecesav);
  if(!npieces)
    return NULL;

  SV *arraypv = newSVpvn("", 0);
  for(U32 i = 0; i < npieces; i++) {
    dSP;
    ENTER;
    SAVETMPS;

    EXTEND(SP, 1);
    PUSHMARK(SP);
    PUSHs(AvARRAY(piecesav)[i]);
    PUTBACK;

    call_method("to_array", G_SCALAR);

    SPAGAIN;

    sv_catsv(arraypv, POPs);

    PUTBACK;

    FREETMPS;
    LEAVE;
  }

  sv_catpvn(arraypv, (char *)&piece_zero, sizeof(piece_zero));

  return (struct XSParseKeywordPieceType *)SvPVX(arraypv); SvLEN(arraypv) = 0; /* steal */
}

static bool cb_permit(pTHX_ void *hookdata)
{
  struct XPKFPHookdata *data = hookdata;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  if(data->hookdata)
    XPUSHs(sv_mortalcopy(data->hookdata));
  else
    XPUSHs(&PL_sv_undef);
  PUTBACK;

  call_sv((SV *)data->permitcv, G_SCALAR);

  SPAGAIN;
  bool ret = SvTRUEx(POPs);

  FREETMPS;
  LEAVE;

  return ret;
}

static void cb_check(pTHX_ void *hookdata)
{
  struct XPKFPHookdata *data = hookdata;

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  if(data->hookdata)
    XPUSHs(sv_mortalcopy(data->hookdata));
  else
    XPUSHs(&PL_sv_undef);
  PUTBACK;

  call_sv((SV *)data->checkcv, G_VOID);

  FREETMPS;
  LEAVE;
}

static int cb_build(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  struct XPKFPHookdata *data = hookdata;

  dSP;
  SV *outsv = newSV(0);
  AV *argsav = newAV();

  for(U32 i = 0; i < nargs; i++) {
    SV *argsv = newSV(0);
    sv_setiv(newSVrv(argsv, "XS::Parse::Keyword::FromPerl::_Arg"), PTR2IV(args[i]));
    av_push(argsav, argsv);
  }

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHs(newRV_noinc(outsv));
  mPUSHs(newRV_noinc((SV *)argsav));
  if(data->hookdata)
    PUSHs(sv_mortalcopy(data->hookdata));
  else
    PUSHs(&PL_sv_undef);
  PUTBACK;

  call_sv((SV *)data->buildcv, G_SCALAR);

  SPAGAIN;
  int ret = POPu;

  if(SvOK(outsv)) {
    *out = SvOPo(outsv);
  }

  FREETMPS;
  LEAVE;

  return ret;
}

static void S_setup_constants(pTHX)
{
  HV *stash;
  AV *export;

#define DO_CONSTANT(c) \
  newCONSTSUB(stash, #c, newSViv(c)); \
  av_push(export, newSVpv(#c, 0))

  stash = gv_stashpvs("XS::Parse::Keyword::FromPerl", TRUE);
  export = get_av("XS::Parse::Keyword::FromPerl::EXPORT_OK", TRUE);

  DO_CONSTANT(KEYWORD_PLUGIN_EXPR);
  DO_CONSTANT(KEYWORD_PLUGIN_STMT);

  DO_CONSTANT(XPK_FLAG_EXPR);
  DO_CONSTANT(XPK_FLAG_STMT);
  DO_CONSTANT(XPK_FLAG_AUTOSEMI);
  DO_CONSTANT(XPK_FLAG_BLOCKSCOPE);

  DO_CONSTANT(XPK_LEXVAR_SCALAR);
  DO_CONSTANT(XPK_LEXVAR_ARRAY);
  DO_CONSTANT(XPK_LEXVAR_HASH);
  DO_CONSTANT(XPK_LEXVAR_ANY);
}

MODULE = XS::Parse::Keyword::FromPerl    PACKAGE = XS::Parse::Keyword::FromPerl::_Arg

SV *line(SV *self)
  ALIAS:
    op = 1
    cv = 2
    sv = 3
    has_sv = 4
    i  = 5
    padix = 6
    line = 7
  CODE:
    XSParseKeywordPiece *arg = NUM2PTR(XSParseKeywordPiece *, SvIV(SvRV(self)));
    switch(ix) {
      case 1: RETVAL = newSVop(arg->op); break;
      case 2: RETVAL = newRV_inc((SV *)arg->cv); break;
      case 3: RETVAL = arg->sv ? SvREFCNT_inc(arg->sv) : &PL_sv_undef; break;
      case 4: RETVAL = arg->sv ? &PL_sv_yes : &PL_sv_no; break;
      case 5: RETVAL = newSViv(arg->i); break;
      case 6: RETVAL = newSVuv(arg->padix); break;
      case 7: RETVAL = newSViv(arg->line); break;
    }
  OUTPUT:
    RETVAL

MODULE = XS::Parse::Keyword::FromPerl    PACKAGE = XS::Parse::Keyword::FromPerl::_Piece

SV *to_array(SV *self)
  CODE:
    AV *selfav = AV_FROM_REF(self);
    SV **svp = AvARRAY(selfav);
    char *type = SvPV_nolen(svp[0]);

    struct XSParseKeywordPieceType piece;
    /* Simple */
    if     (strEQ(type, "XPK_BLOCK"))           piece = (struct XSParseKeywordPieceType)XPK_BLOCK;
    else if(strEQ(type, "XPK_ANONSUB"))         piece = (struct XSParseKeywordPieceType)XPK_ANONSUB;
    else if(strEQ(type, "XPK_ARITHEXPR"))       piece = (struct XSParseKeywordPieceType)XPK_ARITHEXPR;
    else if(strEQ(type, "XPK_TERMEXPR"))        piece = (struct XSParseKeywordPieceType)XPK_TERMEXPR;
    else if(strEQ(type, "XPK_LISTEXPR"))        piece = (struct XSParseKeywordPieceType)XPK_LISTEXPR;
    else if(strEQ(type, "XPK_IDENT"))           piece = (struct XSParseKeywordPieceType)XPK_IDENT;
    else if(strEQ(type, "XPK_IDENT_OPT"))       piece = (struct XSParseKeywordPieceType)XPK_IDENT_OPT;
    else if(strEQ(type, "XPK_PACKAGENAME"))     piece = (struct XSParseKeywordPieceType)XPK_PACKAGENAME;
    else if(strEQ(type, "XPK_PACKAGENAME_OPT")) piece = (struct XSParseKeywordPieceType)XPK_PACKAGENAME_OPT;
    else if(strEQ(type, "XPK_VSTRING"))         piece = (struct XSParseKeywordPieceType)XPK_VSTRING;
    else if(strEQ(type, "XPK_VSTRING_OPT"))     piece = (struct XSParseKeywordPieceType)XPK_VSTRING_OPT;
    else if(strEQ(type, "XPK_COMMA"))           piece = (struct XSParseKeywordPieceType)XPK_COMMA;
    else if(strEQ(type, "XPK_COLON"))           piece = (struct XSParseKeywordPieceType)XPK_COLON;
    else if(strEQ(type, "XPK_EQUALS"))          piece = (struct XSParseKeywordPieceType)XPK_EQUALS;
    else if(strEQ(type, "XPK_INTRO_MY"))        piece = (struct XSParseKeywordPieceType)XPK_INTRO_MY;
    /* Single-SV parametric */
    else if(strEQ(type, "XPK_LEXVARNAME"))
      piece = (struct XSParseKeywordPieceType)XPK_LEXVARNAME(SvUV(svp[1]));
    else if(strEQ(type, "XPK_LEXVAR"))
      piece = (struct XSParseKeywordPieceType)XPK_LEXVAR(SvUV(svp[1]));
    else if(strEQ(type, "XPK_LEXVAR_MY"))
      piece = (struct XSParseKeywordPieceType)XPK_LEXVAR_MY(SvUV(svp[1]));
    else if(strEQ(type, "XPK_LITERAL"))
      piece = (struct XSParseKeywordPieceType)XPK_LITERAL(savepv(SvPV_nolen(svp[1])));
    else if(strEQ(type, "XPK_KEYWORD"))
      piece = (struct XSParseKeywordPieceType)XPK_KEYWORD(savepv(SvPV_nolen(svp[1])));
    else if(strEQ(type, "XPK_FAILURE"))
      piece = (struct XSParseKeywordPieceType)XPK_FAILURE(savepv(SvPV_nolen(svp[1])));
    /* Structural */
    else if(strEQ(type, "XPK_SEQUENCE"))
      piece = (struct XSParseKeywordPieceType)XPK_SEQUENCE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_OPTIONAL"))
      piece = (struct XSParseKeywordPieceType)XPK_OPTIONAL_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_REPEATED"))
      piece = (struct XSParseKeywordPieceType)XPK_REPEATED_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_CHOICE"))
      piece = (struct XSParseKeywordPieceType)XPK_CHOICE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_PARENS"))
      piece = (struct XSParseKeywordPieceType)XPK_PARENS_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_ARGS"))
      piece = (struct XSParseKeywordPieceType)XPK_ARGS_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_BRACKETS"))
      piece = (struct XSParseKeywordPieceType)XPK_BRACKETS_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_BRACES"))
      piece = (struct XSParseKeywordPieceType)XPK_BRACES_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_CHEVRONS"))
      piece = (struct XSParseKeywordPieceType)XPK_CHEVRONS_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else
      croak("Unrecognised type name %s", type);

    RETVAL = newSVpvn((char *)&piece, sizeof(piece));
  OUTPUT:
    RETVAL

MODULE = XS::Parse::Keyword::FromPerl    PACKAGE = XS::Parse::Keyword::FromPerl

void
register_xs_parse_keyword(const char *name, ...)
  CODE:
    dKWARG(1);

    struct XPKFPHookdata data = {0};
    U32 flags = 0;
    SV *permit_hintkeysv = NULL;
    const struct XSParseKeywordPieceType *pieces = NULL;

    static const char *args[] = {
      "flags",
      "pieces",
      "permit_hintkey",
      "permit",
      "check",
      /* TODO: parse? */
      "build",
      "hookdata",
    };
    while(KWARG_NEXT(args))
      switch(kwarg) {
        case 0: /* flags */
          flags = SvUV(kwval);
          break;

        case 1: /* pieces */
        {
          if(!SvROK(kwval) || SvTYPE(SvRV(kwval)) != SVt_PVAV)
            croak("Expected 'pieces' to be an array ref");
          pieces = make_pieces_array(AV_FROM_REF(kwval));
          break;
        }

        case 2: /* permit_hintkey */
          permit_hintkeysv = kwval;
          break;

        case 3: /* permit */
          if(!SvROK(kwval) || SvTYPE(SvRV(kwval)) != SVt_PVCV)
            croak("Expected 'permit' to be a CODE ref");
          data.permitcv = (CV *)SvREFCNT_inc((SV *)CV_FROM_REF(kwval));
          break;

        case 4: /* check */
          if(!SvROK(kwval) || SvTYPE(SvRV(kwval)) != SVt_PVCV)
            croak("Expected 'check' to be a CODE ref");
          data.checkcv = (CV *)SvREFCNT_inc((SV *)CV_FROM_REF(kwval));
          break;

        case 5: /* build */
          if(!SvROK(kwval) || SvTYPE(SvRV(kwval)) != SVt_PVCV)
            croak("Expected 'build' to be a CODE ref");
          data.buildcv = (CV *)SvREFCNT_inc((SV *)CV_FROM_REF(kwval));
          break;

        case 6: /* hookdata */
          data.hookdata = newSVsv(kwval);
          break;
      }

    if(!data.buildcv)
      croak("Require 'build' for register");
    if(!permit_hintkeysv && !data.permitcv)
      croak("Require at least one of 'permit_hintkey' or 'permit'");

    if(!pieces) {
      pieces = &piece_zero;
    }

    struct XSParseKeywordHooks *hooksptr;
    Newx(hooksptr, 1, struct XSParseKeywordHooks);

    *hooksptr = (struct XSParseKeywordHooks){
      .flags  = flags,
      .pieces = pieces,
    };
    if(permit_hintkeysv)
      hooksptr->permit_hintkey = savepv(SvPV_nolen(permit_hintkeysv));
    if(data.permitcv)
      hooksptr->permit = &cb_permit;
    if(data.checkcv)
      hooksptr->check = &cb_check;
    if(data.buildcv)
      hooksptr->build = &cb_build;

    struct XPKFPHookdata *dataptr;
    Newx(dataptr, 1, struct XPKFPHookdata);
    *dataptr = data;

    register_xs_parse_keyword(savepv(name), hooksptr, dataptr);

BOOT:
  boot_xs_parse_keyword(0.35);

  S_setup_constants(aTHX);
