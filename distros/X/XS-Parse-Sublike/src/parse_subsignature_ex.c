/* vi: set ft=c : */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#include "XSParseSublike.h"

/* Skip this entire file on perls older than OP_ARGCHECK */
#if HAVE_PERL_VERSION(5, 26, 0)

#define PERL_EXT
/* We need to be able to see FEATURE_*_IS_ENABLED */
#include "feature.h"
/* Also need KEY_sigvar */
#include "keywords.h"

#include "parse_subsignature_ex.h"

#include "lexer-additions.c.inc"

#include "croak_from_caller.c.inc"
#include "make_argcheck_aux.c.inc"
#include "newSV_with_free.c.inc"

#ifdef XOPf_xop_dump
#  define HAVE_XOP_DUMP
#endif

#ifndef av_count
#  define av_count(av)  (1 + AvFILL(av))
#endif

#define newSVpvx(ptr)  S_newSVpvx(aTHX_ ptr)
static SV *S_newSVpvx(pTHX_ void *ptr)
{
  SV *sv = newSV(0);
  sv_upgrade(sv, SVt_PV);
  SvPVX(sv) = ptr;
  return sv;
}

/*
 * Need to grab some things that aren't quite core perl API
 */

/* yyerror() is a long function and hard to emulate or copy-paste for our
 * purposes; we'll reïmplement a smaller version of it
 */

#define LEX_IGNORE_UTF8_HINTS   0x00000002

#define PL_linestr (PL_parser->linestr)

#ifdef USE_UTF8_SCRIPTS
#   define UTF cBOOL(!IN_BYTES)
#else
#   define UTF cBOOL((PL_linestr && DO_UTF8(PL_linestr)) || ( !(PL_parser->lex_flags & LEX_IGNORE_UTF8_HINTS) && (PL_hints & HINT_UTF8)))
#endif

#define yyerror(s)  S_yyerror(aTHX_ s)
void S_yyerror(pTHX_ const char *s)
{
  SV *message = sv_2mortal(newSVpvs_flags("", 0));

  char *context = PL_parser->oldbufptr;
  STRLEN contlen = PL_parser->bufptr - PL_parser->oldbufptr;

  sv_catpvf(message, "%s at %s line %" IVdf,
      s, OutCopFILE(PL_curcop), (IV)CopLINE(PL_curcop));

  if(context)
    sv_catpvf(message, ", near \"%" UTF8f "\"",
        UTF8fARG(UTF, contlen, context));

  sv_catpvf(message, "\n");

  PL_parser->error_count++;
  warn_sv(message);
}

/* Stolen from op.c */
#ifndef OpTYPE_set
#  define OpTYPE_set(op, type)         \
    STMT_START {                       \
      op->op_type   = (OPCODE)type;    \
      op->op_ppaddr = PL_ppaddr[type]; \
    } STMT_END
#endif

#define alloc_LOGOP(a,b,c)  S_alloc_LOGOP(aTHX_ a,b,c)
static LOGOP *S_alloc_LOGOP(pTHX_ I32 type, OP *first, OP* other)
{
  dVAR;
  LOGOP *logop;
  OP *kid = first;
  NewOp(1101, logop, 1, LOGOP);
  OpTYPE_set(logop, type);
  logop->op_first = first;
  logop->op_other = other;
  if (first)
    logop->op_flags = OPf_KIDS;
  while (kid && OpHAS_SIBLING(kid))
    kid = OpSIBLING(kid);
  if (kid)
    OpLASTSIB_set(kid, (OP*)logop);
  return logop;
}

/* copypaste from core's pp.c */
static SV *
S_find_runcv_name(pTHX)
{
  CV *cv;
  GV *gv;
  SV *sv;

  cv = find_runcv(0);
  if (!cv)
    return &PL_sv_no;

  gv = CvGV(cv);
  if (!gv)
    return &PL_sv_no;

  sv = sv_newmortal();
  gv_fullname4(sv, gv, NULL, TRUE);
  return sv;
}

/*****************************
 * Named arguments extension *
 *****************************

Signature handling of named arguments proceeds initially as with regular perl,
with the addition of one big op that handles all the named arguments at once.

The generated optree will have additional steps after the OP_ARGCHECK +
OP_ARGELEM ops of positional parameters. Any CV with named parameters will
have a single OP_CUSTOM/pp_argelems_named that stands in place of any
OP_ARGELEM that would have been used for a final slurpy element, if present.
This stores details of all the named arguments in an array in its ->op_aux,
and processes all of the named arguments and the slurpy element all at once.
Following this will be a small optree per optional named parameter, consisting
of an OP_CUSTOM/pp_namedargexists, OP_CUSTOM/pp_namedargassign and the
defaulting expression.

Temporarily during processing we make use of the SvPADSTALE flag on every pad
variable used to store a named parameter, to remember that no value has yet
been assigned into it. This is how we can detect required but missing named
parameters once argument processing is finished, and how the optional
parameters can have default expressions assigned into them.

*/

enum {
  OPp_NAMEDARGDEFELEM_IF_UNDEF = 1,
  OPp_NAMEDARGDEFELEM_IF_FALSE = 2,
};

static XOP xop_namedargexists;
static OP *pp_namedargexists(pTHX)
{
  dSP;
  dTARGET;

  bool ok = false;
  switch(PL_op->op_private & 3) {
    case 0:
      ok = TARG && !SvPADSTALE(TARG);
      break;

    case OPp_NAMEDARGDEFELEM_IF_UNDEF:
      ok = TARG && SvOK(TARG);
      break;

    case OPp_NAMEDARGDEFELEM_IF_FALSE:
      ok = TARG && SvTRUE(TARG);
      break;
  }

  if(!ok)
    return cLOGOP->op_other;

  RETURN;
}

static XOP xop_namedargassign;
static OP *pp_namedargassign(pTHX)
{
  dSP;
  dTARGET;
  SV *value = POPs;

  SvPADSTALE_off(TARG);
  SvSetMagicSV(TARG, value);

  RETURN;
}

struct ArgElemsNamedParam {
  U32 flags;
  PADOFFSET padix;
  U32 namehash;
  Size_t namelen;
  const char *namepv;
};
enum {
  NAMEDPARAMf_REQUIRED = (1<<0),
  NAMEDPARAMf_UTF8     = (1<<1),
};

static int cmp_argelemsnamedparam(const void *_a, const void *_b)
{
  const struct ArgElemsNamedParam *a = _a, *b = _b;
  if(a->namehash < b->namehash)
    return -1;
  if(a->namehash > b->namehash)
    return 1;
  return 0;
}

struct ArgElemsNamedAux {
  UV start_argix;
  Size_t n_params;
  struct ArgElemsNamedParam params[0];
};

static XOP xop_argelems_named;
static OP *pp_argelems_named(pTHX)
{
  struct ArgElemsNamedAux *aux = (struct ArgElemsNamedAux *)cUNOP_AUX->op_aux;
  AV *defav = GvAV(PL_defgv);

  HV *slurpy_hv = NULL;
  AV *slurpy_av = NULL;
  bool slurpy_ignore = false;

  if(PL_op->op_targ) {
    /* We have a slurpy of some kind */
    save_clearsv(&PAD_SVl(PL_op->op_targ));
  }

  if(PL_op->op_private & OPpARGELEM_HV) {
    if(PL_op->op_targ) {
      slurpy_hv = (HV *)PAD_SVl(PL_op->op_targ);
      assert(SvTYPE(slurpy_hv) == SVt_PVHV);
      assert(HvKEYS(slurpy_hv) == 0);
    }
    else {
      slurpy_ignore = true;
    }
  }
  else if(PL_op->op_private & OPpARGELEM_AV) {
    if(PL_op->op_targ) {
      slurpy_av = (AV *)PAD_SVl(PL_op->op_targ);
      assert(SvTYPE(slurpy_av) == SVt_PVAV);
      assert(av_count(slurpy_av) == 0);
    }
    else {
      slurpy_ignore = true;
    }
  }

  UV argix = aux->start_argix;
  UV argc  = av_count(defav);

  U32 parami;
  UV n_params = aux->n_params;

  /* Before we process the incoming args we need to prepare *all* the param
   * variable pad slots.
   */
  for(parami = 0; parami < n_params; parami++) {
    struct ArgElemsNamedParam *param = &aux->params[parami];

    SV **padentry = &PAD_SVl(param->padix);
    assert(padentry);
    save_clearsv(padentry);

    /* A slight abuse of the PADSTALE flag so we can detect which parameters
     * not been assigned to afterwards
     */
    SvPADSTALE_on(*padentry);
  }

  SV *unrecognised_keynames = NULL;
  UV n_unrecognised = 0;

  while(argix < argc) {
    /* TODO: do we need av_fetch or can we cheat around it? */
    SV *name = *av_fetch(defav, argix, 0);
    argix++;
    SV *val  = argix < argc ? *av_fetch(defav, argix, 0) : &PL_sv_undef;
    argix++;

    STRLEN namelen;
    const char *namepv = SvPV(name, namelen);

    U32 namehash;
    PERL_HASH(namehash, namepv, namelen);

    PADOFFSET param_padix = 0;

    /* In theory we would get better performance at runtime by binary
     * searching for a good starting index. In practice only actually starts
     * saving measurable time once we start to get to literally hundreds of
     * named parameters. This simple linear search is actually very quick per
     * rejected element.
     * If your perl function wants to declare hundreds of different named
     * parameters you probably want to rethink your strategy. ;)
     */
    for(parami = 0; parami < n_params; parami++) {
      struct ArgElemsNamedParam *param = &aux->params[parami];

      /* Since the params are stored in hash key order, if we are already
       * past it then we know we are done
       */
      if(param->namehash > namehash)
        break;
      if(param->namehash != namehash)
        continue;

      /* TODO: This will be wrong for UTF-8 comparisons */
      if(namelen != param->namelen)
        continue;
      if(!strnEQ(namepv, param->namepv, namelen))
        continue;

      param_padix = param->padix;
      break;
    }

    if(param_padix) {
      SV *targ = PAD_SVl(param_padix);

      /* This has to do all the work normally done by pp_argelem */
      assert(TAINTING_get || !TAINT_get);
      if(UNLIKELY(TAINT_get) && !SvTAINTED(val))
        TAINT_NOT;
      SvPADSTALE_off(targ);
      SvSetMagicSV(targ, val);
    }
    else if(slurpy_hv) {
      hv_store_ent(slurpy_hv, name, newSVsv(val), 0);
    }
    else if(slurpy_av) {
      av_push(slurpy_av, newSVsv(name));
      if(argix <= argc)
        av_push(slurpy_av, newSVsv(val));
    }
    else if(!slurpy_ignore) {
      if(!unrecognised_keynames) {
        unrecognised_keynames = newSVpvn("", 0);
        SAVEFREESV(unrecognised_keynames);
      }

      if(SvCUR(unrecognised_keynames))
        sv_catpvs(unrecognised_keynames, ", ");
      sv_catpvf(unrecognised_keynames, "'%" SVf "'", SVfARG(name));
      n_unrecognised++;
    }
  }

  if(n_unrecognised) {
    croak_from_caller("Unrecognised %s %" SVf " for subroutine %" SVf,
      n_unrecognised > 1 ? "arguments" : "argument",
      SVfARG(unrecognised_keynames), SVfARG(S_find_runcv_name(aTHX)));
  }

  SV *missing_keynames = NULL;
  UV n_missing = 0;

  for(parami = 0; parami < n_params; parami++) {
    struct ArgElemsNamedParam *param = &aux->params[parami];
    SV *targ = PAD_SVl(param->padix);

    if(!SvPADSTALE(targ))
      continue;
    if(!(param->flags & NAMEDPARAMf_REQUIRED))
      continue;

    if(!missing_keynames) {
      missing_keynames = newSVpvn("", 0);
      SAVEFREESV(missing_keynames);
    }

    if(SvCUR(missing_keynames))
      sv_catpvs(missing_keynames, ", ");
    sv_catpvf(missing_keynames, "'%s'", param->namepv);
    n_missing++;
  }

  if(n_missing) {
    croak_from_caller("Missing %s %" SVf " for subroutine %" SVf,
      n_missing > 1 ? "arguments" : "argument",
      SVfARG(missing_keynames), SVfARG(S_find_runcv_name(aTHX)));
  }

  return NORMAL;
}

#ifdef HAVE_XOP_DUMP
static void opdump_argelems_named(pTHX_ const OP *o, struct Perl_OpDumpContext *ctx)
{
  struct ArgElemsNamedAux *aux = (struct ArgElemsNamedAux *)cUNOP_AUXo->op_aux;

  opdump_printf(ctx, "START_ARGIX = %" UVuf "\n", aux->start_argix);
  opdump_printf(ctx, "PARAMS = (%" UVuf ")\n", aux->n_params);

  U32 parami;
  for(parami = 0; parami < aux->n_params; parami++) {
    struct ArgElemsNamedParam *param = &aux->params[parami];

    opdump_printf(ctx, "  [%d] = {.name=\"%s\", .namehash=%u .padix=%u, .flags=(",
        parami,
        param->namepv,
        param->namehash,
        (unsigned int)param->padix);

    bool need_comma = false;
    if(param->flags & NAMEDPARAMf_UTF8)
      opdump_printf(ctx, "%sUTF8", need_comma?",":""), need_comma = true;
    if(param->flags & NAMEDPARAMf_REQUIRED)
      opdump_printf(ctx, "%sREQUIRED", need_comma?",":""), need_comma = true;

    opdump_printf(ctx, ")}\n");
  }
}
#endif

/* Parameter attribute extensions */
typedef struct SignatureAttributeRegistration SignatureAttributeRegistration;

struct SignatureAttributeRegistration {
  SignatureAttributeRegistration *next;

  const char *name;
  STRLEN permit_hintkeylen;

  const struct XPSSignatureAttributeFuncs *funcs;
  void *funcdata;
};

static SignatureAttributeRegistration *sigattrs = NULL;

#define find_registered_attribute(name)  S_find_registered_attribute(aTHX_ name)
static SignatureAttributeRegistration *S_find_registered_attribute(pTHX_ const char *name)
{
  HV *hints = GvHV(PL_hintgv);

  SignatureAttributeRegistration *reg;
  for(reg = sigattrs; reg; reg = reg->next) {
    if(!strEQ(name, reg->name))
      continue;

    if(reg->funcs->permit_hintkey &&
        (!hints || !hv_fetch(hints, reg->funcs->permit_hintkey, reg->permit_hintkeylen, 0)))
      continue;

    return reg;
  }

  croak("Unrecognised signature parameter attribute :%s", name);
}

struct PendingSignatureFunc {
  const struct XPSSignatureAttributeFuncs *funcs;
  void *funcdata;
  void *attrdata;
};

#define PENDING_FROM_SV(sv)  ((struct PendingSignatureFunc *)SvPVX(sv))

static void pending_free(pTHX_ SV *sv)
{
  struct PendingSignatureFunc *p = PENDING_FROM_SV(sv);

  if(p->funcs->free)
    (*p->funcs->free)(aTHX_ p->attrdata, p->funcdata);
}

#define NEW_SV_PENDING()  newSV_with_free(sizeof(struct PendingSignatureFunc), &pending_free)

struct NamedParamDetails {
  PADOFFSET padix;
  bool is_required;
};
struct SignatureParsingContext {
  OP *positional_elems;  /* OP_LINESEQ of every positional element, in order */
  OP *named_elem_defops; /* OP_LINESEQ of those named elements that have defaulting expressions */
  HV *named_details;     /* SV ptrs to NamedParamDetails of every named parameter */
  OP *slurpy_elem;
};

static void free_parsing_ctx(pTHX_ void *_ctx)
{
  struct SignatureParsingContext *ctx = _ctx;
  /* TODO the rest */
  if(ctx->named_details)
    SvREFCNT_dec((SV *)ctx->named_details);
}

#define parse_sigelem(ctx, flags)  S_parse_sigelem(aTHX_ ctx, flags)
static void S_parse_sigelem(pTHX_ struct SignatureParsingContext *ctx, U32 flags)
{
  bool permit_attributes = flags & PARSE_SUBSIGNATURE_PARAM_ATTRIBUTES;

  yy_parser *parser = PL_parser;

  int c = lex_peek_unichar(0);
  int private;
  struct XPSSignatureParamContext paramctx = { 0 };

  AV *pending = NULL;

  if((flags & PARSE_SUBSIGNATURE_NAMED_PARAMS) && c == ':') {
    lex_read_unichar(0);
    lex_read_space(0);

    paramctx.is_named = true;
    c = lex_peek_unichar(0);
  }

  char sigil = c;
  switch(sigil) {
    case '$': private = OPpARGELEM_SV; break;
    case '@': private = OPpARGELEM_AV; break;
    case '%': private = OPpARGELEM_HV; break;
    case ':':
      croak("Named signature elements are not permitted");
    default:
      croak("Expected a signature element at <%s>\n", parser->bufptr);
  }

  char *lexname = parser->bufptr;

  /* Consume sigil */
  lex_read_unichar(0);

  STRLEN lexname_len = 0;
  struct NamedParamDetails *details = NULL;

  if(isIDFIRST_uni(lex_peek_unichar(0))) {
    lex_read_unichar(0);
    while(isALNUM_uni(lex_peek_unichar(0)))
      lex_read_unichar(0);

    ENTER;
    SAVEI16(PL_parser->in_my);
    PL_parser->in_my = KEY_sigvar;

    lexname_len = PL_parser->bufptr - lexname;
    paramctx.padix = pad_add_name_pvn(lexname, lexname_len, 0, NULL, NULL);

    if(paramctx.is_named) {
      if(!ctx->named_details)
        ctx->named_details = newHV();

      Newx(details, 1, struct NamedParamDetails);
      *details = (struct NamedParamDetails){
        .padix       = paramctx.padix,
        .is_required = true,
      };

      hv_store(ctx->named_details, lexname + 1, lexname_len - 1, newSVpvx(details), 0);
    }
    else {
      paramctx.varop = newUNOP_AUX(OP_ARGELEM, 0, NULL, INT2PTR(UNOP_AUX_item *, (parser->sig_elems)));
      paramctx.varop->op_private |= private;
      paramctx.varop->op_targ = paramctx.padix;
    }

    LEAVE;

    lex_read_space(0);
  }

  if(permit_attributes && lex_peek_unichar(0) == ':') {
    lex_read_unichar(0);
    lex_read_space(0);

    SV *attrname = sv_newmortal(), *attrval = sv_newmortal();

    while(lex_scan_attrval_into(attrname, attrval)) {
      lex_read_space(0);

      SignatureAttributeRegistration *reg = find_registered_attribute(SvPV_nolen(attrname));

      void *attrdata = NULL;
      if(reg->funcs->apply)
        (*reg->funcs->apply)(aTHX_ &paramctx, attrval, &attrdata, reg->funcdata);

      if(attrdata || reg->funcs->post_defop) {
        if(!pending) {
          pending = newAV();
          SAVEFREESV(pending);
        }

        SV *psv;
        av_push(pending, psv = NEW_SV_PENDING());

        PENDING_FROM_SV(psv)->funcs    = reg->funcs;
        PENDING_FROM_SV(psv)->funcdata = reg->funcdata;
        PENDING_FROM_SV(psv)->attrdata = attrdata;
      }

      if(lex_peek_unichar(0) == ':') {
        lex_read_unichar(0);
        lex_read_space(0);
      }
    }
  }

  if(sigil == '$') {
    if(paramctx.is_named) {
    }
    else {
      if(parser->sig_slurpy)
        yyerror("Slurpy parameters not last");

      parser->sig_elems++;
    }

    bool default_if_undef = false, default_if_false = false;
    if(lex_consume("=") ||
        (default_if_undef = lex_consume("//=")) ||
        (default_if_false = lex_consume("||="))) {
      if(!paramctx.is_named)
        parser->sig_optelems++;

      OP *defexpr = parse_termexpr(0);

      if(paramctx.is_named) {
        OP *assignop = newUNOP(OP_CUSTOM, 0, defexpr);
        assignop->op_ppaddr = &pp_namedargassign;
        assignop->op_targ = paramctx.padix;

        OP *existsop = (OP *)alloc_LOGOP(OP_CUSTOM, assignop, LINKLIST(assignop));
        existsop->op_ppaddr = &pp_namedargexists;
        existsop->op_targ = paramctx.padix;
        existsop->op_private =
          default_if_undef ? OPp_NAMEDARGDEFELEM_IF_UNDEF :
          default_if_false ? OPp_NAMEDARGDEFELEM_IF_FALSE :
                            0;

        OP *defop = newUNOP(OP_NULL, 0, existsop);

        LINKLIST(defop);

        defop->op_next = existsop; /* start of this fragment */
        assignop->op_next = defop; /* after assign, stop this fragment */

        details->is_required = false;
        ctx->named_elem_defops = op_append_elem(OP_LINESEQ, ctx->named_elem_defops,
            defop);
      }
      else {
        U8 private = 0;
#ifdef OPpARG_IF_UNDEF
        if(default_if_undef) private |= OPpARG_IF_UNDEF;
        if(default_if_false) private |= OPpARG_IF_FALSE;
#else
        if(default_if_undef || default_if_false)
          /* TODO: This would be possible with a custom op but we'd basically
           * have to copy the behaviour of pp_argdefelem in that case
           */
          yyerror("This Perl version cannot handle if_undef/if_false defaulting expressions on positional parameters");
#endif

        OP *defop = (OP *)alloc_LOGOP(OP_ARGDEFELEM, defexpr, LINKLIST(defexpr));
        defop->op_targ = (PADOFFSET)(parser->sig_elems - 1);
        defop->op_private = private;

        paramctx.varop->op_flags |= OPf_STACKED;
        op_sibling_splice(paramctx.varop, NULL, 0, defop);
        defop = op_contextualize(defop, G_SCALAR);

        LINKLIST(paramctx.varop);

        paramctx.varop->op_next = defop;
        defexpr->op_next = paramctx.varop;
      }
    }
    else {
      if(parser->sig_optelems)
        yyerror("Mandatory parameter follows optional parameter");
    }

    if(!paramctx.is_named)
      /* This call to newSTATEOP() must come AFTER parsing the defaulting
       * expression because it involves an implicit intro_my() and so we must
       * not introduce the new parameter variable beforehand (RT155630)
       */
      ctx->positional_elems = op_append_list(OP_LINESEQ, ctx->positional_elems,
          newSTATEOP(0, NULL, paramctx.varop));
  }
  else {
    if(paramctx.is_named)
      yyerror("Slurpy parameters may not be named");
    if(parser->sig_slurpy)
      yyerror("Multiple slurpy parameters not allowed");

    ctx->slurpy_elem = newSTATEOP(0, NULL, paramctx.varop);

    parser->sig_slurpy = sigil;

    if(lex_peek_unichar(0) == '=')
      yyerror("A slurpy parameter may not have a default value");
  }

  if(pending) {
    for(int i = 0; i <= AvFILL(pending); i++) {
      struct PendingSignatureFunc *p = PENDING_FROM_SV(AvARRAY(pending)[i]);

      if(p->funcs->post_defop)
        (*p->funcs->post_defop)(aTHX_ &paramctx, p->attrdata, p->funcdata);
    }
  }
}

OP *XPS_parse_subsignature_ex(pTHX_ int flags)
{
  /* Mostly reconstructed logic from perl 5.28.0's toke.c and perly.y
   */
  yy_parser *parser = PL_parser;
  struct SignatureParsingContext ctx = { 0 };

  assert((flags & ~(PARSE_SUBSIGNATURE_NAMED_PARAMS|PARSE_SUBSIGNATURE_PARAM_ATTRIBUTES)) == 0);

  ENTER;
  SAVEDESTRUCTOR_X(&free_parsing_ctx, &ctx);

  SAVEIV(parser->sig_elems);
  SAVEIV(parser->sig_optelems);
  SAVEI8(parser->sig_slurpy);

  parser->sig_elems = 0;
  parser->sig_optelems = 0;
  parser->sig_slurpy = 0;

  while(lex_peek_unichar(0) != ')') {
    lex_read_space(0);
    parse_sigelem(&ctx, flags);

    if(PL_parser->error_count) {
      LEAVE;
      return NULL;
    }

    lex_read_space(0);
    switch(lex_peek_unichar(0)) {
      case ')': goto endofelems;
      case ',': break;
      default:
        fprintf(stderr, "ARGH unsure how to proceed parse_subsignature at <%s>\n",
            parser->bufptr);
        croak("ARGH");
        break;
    }

    lex_read_unichar(0);
    lex_read_space(0);
  }
endofelems:

  if (!FEATURE_SIGNATURES_IS_ENABLED)
    croak("Experimental subroutine signatures not enabled");

#if !HAVE_PERL_VERSION(5, 37, 0)
  Perl_ck_warner_d(aTHX_ packWARN(WARN_EXPERIMENTAL__SIGNATURES),
    "The signatures feature is experimental");
#endif

  char sig_slurpy = parser->sig_slurpy;
  if(!sig_slurpy && ctx.named_details)
    sig_slurpy = '%';

  UNOP_AUX_item *aux = make_argcheck_aux(
    parser->sig_elems,
    parser->sig_optelems,
    sig_slurpy);

  OP *checkop = newUNOP_AUX(OP_ARGCHECK, 0, NULL, aux);

  OP *ops = op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL),
      op_prepend_elem(OP_LINESEQ, checkop, ctx.positional_elems));

  if(ctx.named_details) {
    UV n_params = HvKEYS(ctx.named_details);

    struct ArgElemsNamedAux *aux = safemalloc(
      sizeof(struct ArgElemsNamedAux) + n_params * sizeof(struct ArgElemsNamedParam)
    );

    aux->start_argix = parser->sig_elems;
    aux->n_params    = n_params;

    struct ArgElemsNamedParam *param = &aux->params[0];

    hv_iterinit(ctx.named_details);
    HE *iter;
    while((iter = hv_iternext(ctx.named_details))) {
      STRLEN namelen;
      const char *namepv = HePV(iter, namelen);
      struct NamedParamDetails *details = (struct NamedParamDetails *)SvPVX(HeVAL(iter));

      *param = (struct ArgElemsNamedParam){
        .flags =
          (HeUTF8(iter)         ? NAMEDPARAMf_UTF8     : 0) |
          (details->is_required ? NAMEDPARAMf_REQUIRED : 0),
        .padix = details->padix,
        .namehash = HeHASH(iter),
        .namepv = savepvn(namepv, namelen),
        .namelen = namelen,
      };
      param++;
    }

    if(aux->n_params > 1) {
      /* Sort the params by hash value */
      qsort(&aux->params, aux->n_params, sizeof(aux->params[0]),
          &cmp_argelemsnamedparam);
    }

    OP *argelems_named_op = newUNOP_AUX(OP_CUSTOM, 0, NULL, (UNOP_AUX_item *)aux);
    argelems_named_op->op_ppaddr = &pp_argelems_named;
    if(PL_parser->sig_slurpy) {
      assert(ctx.slurpy_elem);
      if(ctx.slurpy_elem->op_type == OP_LINESEQ) {
        /* A real named slurpy variable */
        OP *o = OpSIBLING(cLISTOPx(ctx.slurpy_elem)->op_first);
        assert(o);
        assert(o->op_type == OP_ARGELEM);

        /* Steal the slurpy's targ and private flags */
        argelems_named_op->op_targ    = o->op_targ;
        argelems_named_op->op_private |= o->op_private & OPpARGELEM_MASK;
      }
      else {
        /* The slurpy is unnamed. Don't steal its targ but still set the
         * private flags
         */
        argelems_named_op->op_targ    = 0;
        argelems_named_op->op_private = (PL_parser->sig_slurpy == '%') ? OPpARGELEM_HV :
                                        (PL_parser->sig_slurpy == '@') ? OPpARGELEM_AV :
                                                                         0;
      }

      op_free(ctx.slurpy_elem);
      ctx.slurpy_elem = NULL;
    }

    ops = op_append_list(OP_LINESEQ, ops,
        newSTATEOP(0, NULL, NULL));
    ops = op_append_list(OP_LINESEQ, ops,
        argelems_named_op);

    if(ctx.named_elem_defops)
      /* TODO: append each elem individually */
      ops = op_append_list(OP_LINESEQ, ops,
          ctx.named_elem_defops);
  }
  else if(ctx.slurpy_elem) {
    ops = op_append_list(OP_LINESEQ, ops, ctx.slurpy_elem);
  }

  /* a nextstate at the end handles context correctly for an empty
   * sub body */
  ops = op_append_elem(OP_LINESEQ, ops, newSTATEOP(0, NULL, NULL));

  LEAVE;

  return ops;
}

void XPS_register_subsignature_attribute(pTHX_ const char *name, const struct XPSSignatureAttributeFuncs *funcs, void *funcdata)
{
  SignatureAttributeRegistration *reg;
  Newx(reg, 1, struct SignatureAttributeRegistration);

  *reg = (struct SignatureAttributeRegistration){
    .name     = name,
    .funcs    = funcs,
    .funcdata = funcdata,
  };

  if(funcs->permit_hintkey)
    reg->permit_hintkeylen = strlen(funcs->permit_hintkey);

  reg->next = sigattrs;
  sigattrs = reg;
}

void XPS_boot_parse_subsignature_ex(pTHX)
{
  XopENTRY_set(&xop_namedargexists, xop_name, "namedargexists");
  XopENTRY_set(&xop_namedargexists, xop_desc, "named argument element exists test");
  XopENTRY_set(&xop_namedargexists, xop_class, OA_LOGOP);
  Perl_custom_op_register(aTHX_ &pp_namedargexists, &xop_namedargexists);

  XopENTRY_set(&xop_namedargassign, xop_name, "namedargassign");
  XopENTRY_set(&xop_namedargassign, xop_desc, "named argument element assignment");
  XopENTRY_set(&xop_namedargassign, xop_class, OA_UNOP);
  Perl_custom_op_register(aTHX_ &pp_namedargassign, &xop_namedargassign);

  XopENTRY_set(&xop_argelems_named, xop_name, "argelems_named");
  XopENTRY_set(&xop_argelems_named, xop_desc, "named parameter elements");
  XopENTRY_set(&xop_argelems_named, xop_class, OA_UNOP_AUX);
#ifdef HAVE_XOP_DUMP
  XopENTRY_set(&xop_argelems_named, xop_dump, &opdump_argelems_named);
#endif
  Perl_custom_op_register(aTHX_ &pp_argelems_named, &xop_argelems_named);
}

#else /* !HAVE_PERL_VERSION(5, 26, 0) */

void XPS_register_subsignature_attribute(pTHX_ const char *name, const struct XPSSignatureAttributeFuncs *funcs, void *funcdata)
{
  croak("Custom subroutine signature attributes are not supported on this verison of Perl");
}

void XPS_boot_parse_subsignature_ex(pTHX)
{
}
#endif
