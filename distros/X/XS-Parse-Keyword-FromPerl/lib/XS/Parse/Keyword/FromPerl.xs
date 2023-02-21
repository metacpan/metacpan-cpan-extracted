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

/* Wrappers between OP * and B::OP-blessed SVs */
#define newSVop(o)  S_newSVop(aTHX_ o)
static SV *S_newSVop(pTHX_ OP *o)
{
  SV *ret = newSV(0);

  const char *opclassname;
  switch(op_class(o)) {
    case OPclass_BASEOP:   opclassname = "B::OP";       break;
    case OPclass_UNOP:     opclassname = "B::UNOP";     break;
    case OPclass_BINOP:    opclassname = "B::BINOP";    break;
    case OPclass_LOGOP:    opclassname = "B::LOGOP";    break;
    case OPclass_LISTOP:   opclassname = "B::LISTOP";   break;
    case OPclass_PMOP:     opclassname = "B::PMOP";     break;
    case OPclass_SVOP:     opclassname = "B::SVOP";     break;
    case OPclass_PADOP:    opclassname = "B::PADOP";    break;
    case OPclass_PVOP:     opclassname = "B::PVOP";     break;
    case OPclass_LOOP:     opclassname = "B::LOOP";     break;
    case OPclass_COP:      opclassname = "B::COP";      break;
    case OPclass_METHOP:   opclassname = "B::METHOP";   break;
    case OPclass_UNOP_AUX: opclassname = "B::UNOP_AUX"; break;
    default:
      croak("TODO: handle opclass=%d\n", op_class(o));
  }

  sv_setiv(newSVrv(ret, opclassname), PTR2IV(o));
  return ret;
}

#define SvOPo(sv)  S_SvOPo(aTHX_ sv)
static OP *S_SvOPo(pTHX_ SV *sv)
{
  if(!SvOK(sv))
    croak("Expected a B::OP instance, found <undef>");
  if(!SvROK(sv) || !sv_derived_from(sv, "B::OP"))
    croak("Expected a B::OP instance, found %" SVf, SVfARG(sv));

  return NUM2PTR(OP *, SvIV(SvRV(sv)));
}

#define maySvOPo(sv)  (sv && SvOK(sv) ? SvOPo(sv) : NULL)

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

#define ENTER_and_setup_pad(name)  S_ENTER_and_setup_pad(aTHX_ name)
static void S_ENTER_and_setup_pad(pTHX_ const char *name)
{
  if(!PL_compcv)
    croak("Cannot call %s while not compiling a subroutine", name);

  ENTER;

  PAD_SET_CUR(CvPADLIST(PL_compcv), 1);

  SAVESPTR(PL_comppad_name);
  PL_comppad_name = PadlistNAMES(CvPADLIST(PL_compcv));
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

  DO_CONSTANT(OPf_WANT);
  DO_CONSTANT(OPf_WANT_VOID);
  DO_CONSTANT(OPf_WANT_SCALAR);
  DO_CONSTANT(OPf_WANT_LIST);
  DO_CONSTANT(OPf_KIDS);
  DO_CONSTANT(OPf_PARENS);
  DO_CONSTANT(OPf_REF);
  DO_CONSTANT(OPf_MOD);
  DO_CONSTANT(OPf_STACKED);
  DO_CONSTANT(OPf_SPECIAL);

  DO_CONSTANT(XPK_FLAG_EXPR);
  DO_CONSTANT(XPK_FLAG_STMT);
  DO_CONSTANT(XPK_FLAG_AUTOSEMI);

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
    else if(strEQ(type, "XPK_PARENSCOPE"))
      piece = (struct XSParseKeywordPieceType)XPK_PARENSCOPE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_ARGSCOPE"))
      piece = (struct XSParseKeywordPieceType)XPK_ARGSCOPE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_BRACKETSCOPE"))
      piece = (struct XSParseKeywordPieceType)XPK_BRACKETSCOPE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_BRACESCOPE"))
      piece = (struct XSParseKeywordPieceType)XPK_BRACESCOPE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else if(strEQ(type, "XPK_CHEVRONSCOPE"))
      piece = (struct XSParseKeywordPieceType)XPK_CHEVRONSCOPE_pieces(
        make_pieces_array(AV_FROM_REF(svp[1]))
      );
    else
      croak("Unrecognised type name %s", type);

    RETVAL = newSVpvn((char *)&piece, sizeof(piece));
  OUTPUT:
    RETVAL

MODULE = XS::Parse::Keyword::FromPerl    PACKAGE = XS::Parse::Keyword::FromPerl

I32 opcode(const char *opname)
  CODE:
    for(RETVAL = 0; RETVAL < OP_max; RETVAL++)
      if(strEQ(opname, PL_op_name[RETVAL]))
        goto found;
    croak("Unrecognised opcode(\"%s\")", opname);
found:
    ;
  OUTPUT:
    RETVAL

SV *
newOP(I32 type, I32 flags)
  CODE:
    ENTER_and_setup_pad("newOP");
    RETVAL = newSVop(newOP(type, flags));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newBINOP(I32 type, I32 flags, SV *first, SV *last)
  CODE:
    ENTER_and_setup_pad("newBINOP");
    RETVAL = newSVop(newBINOP(type, flags, SvOPo(first), SvOPo(last)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newFOROP(I32 flags, SV *sv, SV *expr, SV *block, SV *cont)
  CODE:
    ENTER_and_setup_pad("newFOROP");
    RETVAL = newSVop(newFOROP(flags, maySvOPo(sv), SvOPo(expr), SvOPo(block), maySvOPo(cont)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newGVOP(I32 type, I32 flags, SV *gv)
  CODE:
    if(!SvROK(gv) || SvTYPE(SvRV(gv)) != SVt_PVGV)
      croak("Expected a GLOB ref to newGVOP");
    ENTER_and_setup_pad("newGVOP");
    RETVAL = newSVop(newGVOP(type, flags, (GV *)SvRV(gv)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newLISTOP(I32 type, I32 flags, ...)
  CODE:
    ENTER_and_setup_pad("newLISTOP");
    OP *o = newLISTOP(OP_LIST, 0, NULL, NULL);
    for(U32 i = 2; i < items; i++)
      o = op_append_elem(OP_LIST, o, SvOPo(ST(i)));
    if(type != OP_LIST)
      o = op_convert_list(type, flags, o);
    RETVAL = newSVop(o);
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newLOGOP(I32 type, I32 flags, SV *first, SV *other)
  CODE:
    ENTER_and_setup_pad("newLOGOP");
    RETVAL = newSVop(newLOGOP(type, flags, SvOPo(first), SvOPo(other)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newPADxVOP(I32 type, I32 flags, U32 padoffset)
  CODE:
    ENTER_and_setup_pad("newPADxVOP");
    RETVAL = newSVop(newPADxVOP(type, flags, padoffset));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newSVOP(I32 type, I32 flags, SV *sv)
  CODE:
    ENTER_and_setup_pad("newSVOP");
    RETVAL = newSVop(newSVOP(type, flags, newSVsv(sv)));
    LEAVE;
  OUTPUT:
    RETVAL

SV *
newUNOP(I32 type, I32 flags, SV *first)
  CODE:
    ENTER_and_setup_pad("newUNOP");
    RETVAL = newSVop(newUNOP(type, flags, SvOPo(first)));
    LEAVE;
  OUTPUT:
    RETVAL

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
  boot_xs_parse_keyword(0.33);

  S_setup_constants(aTHX);
