/* vi: set ft=c : */

#ifndef parse_subsignature

#define PERL_EXT
#include "feature.h"

#include "make_argcheck_aux.c.inc"

#include "LOGOP_ANY.c.inc"

/* Some experimental extension flags. Not (currently) part of core perl API
*/
enum {
  PARSE_SUBSIGNATURE_NAMED_PARAMS = (1<<0),
  /* Permits ( :$foo, :$bar, :$splot = "default" )  named params
   * They are accumulated into a slurpy hash then extracted afterwards
   * As with positional params, any param without a defaulting expression is
   * required; an error is thrown if the caller did not provide it
   */
};

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

static OP *pp_namedargdefelem(pTHX)
{
  dSP;
  ANY *op_any = cLOGOP_ANY->op_any;
  SV *keysv = op_any[0].any_sv;
  HV *slurpy_hv = (HV *)PAD_SVl(op_any[1].any_iv);

  assert(slurpy_hv && SvTYPE(slurpy_hv) == SVt_PVHV);

  /* TODO: we could precompute the hash and store it in the ANY vector */
  SV *value = hv_delete_ent(slurpy_hv, keysv, 0, 0);

  if(value) {
    EXTEND(SP, 1);
    PUSHs(value);
    RETURN;
  }

  if(cLOGOP->op_other)
    return cLOGOP->op_other;

  croak("Missing argument '%" SVf "' for subroutine %" SVf,
    SVfARG(keysv), SVfARG(S_find_runcv_name(aTHX)));
}

static OP *pp_checknomorenamed(pTHX)
{
  HV *slurpy_hv = (HV *)PAD_SVl(PL_op->op_targ);

  if(!hv_iterinit(slurpy_hv))
    return NORMAL;

  /* There are remaining named arguments; concat their names into a message */

  HE *he = hv_iternext(slurpy_hv);

  SV *keynames = newSVpvn("", 0);
  SAVEFREESV(keynames);

  sv_catpvf(keynames, "'%" SVf "'", SVfARG(HeSVKEY_force(he)));

  IV nkeys = 1;

  while((he = hv_iternext(slurpy_hv)))
    sv_catpvf(keynames, ", '%" SVf "'", SVfARG(HeSVKEY_force(he))), nkeys++;

  croak("Unrecognised %s %" SVf " for subroutine %" SVf,
    nkeys > 1 ? "arguments" : "argument",
    SVfARG(keynames), SVfARG(S_find_runcv_name(aTHX)));
}

#define OP_IS_NAMED_PARAM(o)  (o->op_type == OP_ARGELEM && cUNOPx(o)->op_first && \
                                cUNOPx(o)->op_first->op_type == OP_CUSTOM && \
                                cUNOPx(o)->op_first->op_ppaddr == &pp_namedargdefelem)

#define parse_sigelem(flags)  S_parse_sigelem(aTHX_ flags)
static OP *S_parse_sigelem(pTHX_ U32 flags)
{
  yy_parser *parser = PL_parser;

  int c = lex_peek_unichar(0);
  int private;
  bool is_named = false;

  if((flags & PARSE_SUBSIGNATURE_NAMED_PARAMS) && c == ':') {
    lex_read_unichar(0);
    lex_read_space(0);

    is_named = true;
    c = lex_peek_unichar(0);
  }

  switch(c) {
    case '$': private = OPpARGELEM_SV; break;
    case '@': private = OPpARGELEM_AV; break;
    case '%': private = OPpARGELEM_HV; break;
    default:
      croak("Expected a signature element at <%s>\n", parser->bufptr);
  }

  char *lexname = parser->bufptr;
  OP *varop = NULL, *defop = NULL;

  /* Consume sigil */
  lex_read_unichar(0);

  char *lexname_end;

  if(isIDFIRST_uni(lex_peek_unichar(0))) {
    lex_read_unichar(0);
    while(isALNUM_uni(lex_peek_unichar(0)))
      lex_read_unichar(0);

    varop = newUNOP_AUX(OP_ARGELEM, 0, NULL, INT2PTR(UNOP_AUX_item *, (parser->sig_elems)));
    varop->op_private |= private;

    lexname_end = PL_parser->bufptr;
    varop->op_targ = pad_add_name_pvn(lexname, lexname_end - lexname, 0, NULL, NULL);

    lex_read_space(0);
  }

  if(c == '$') {
    SV *argname;

    if(is_named) {
      parser->sig_slurpy = '+';
      argname = newSVpvn(lexname + 1, lexname_end - lexname - 1);
    }
    else {
      if(parser->sig_slurpy)
        yyerror("Slurpy parameters not last");

      parser->sig_elems++;
    }

    if(lex_peek_unichar(0) == '=') {
      lex_read_unichar(0);
      lex_read_space(0);

      if(!is_named)
        parser->sig_optelems++;

      OP *defexpr = parse_termexpr(0);

      if(is_named) {
        defop = (OP *)alloc_LOGOP_ANY(OP_CUSTOM, defexpr, LINKLIST(defexpr));
        defop->op_ppaddr = &pp_namedargdefelem;
      }
      else {
        defop = (OP *)alloc_LOGOP(OP_ARGDEFELEM, defexpr, LINKLIST(defexpr));
        defop->op_targ = (PADOFFSET)(parser->sig_elems - 1);
      }

      varop->op_flags |= OPf_STACKED;
      op_sibling_splice(varop, NULL, 0, defop);
      defop = op_contextualize(defop, G_SCALAR);

      LINKLIST(varop);

      varop->op_next = defop;
      defexpr->op_next = varop;
    }
    else {
      if(parser->sig_optelems)
        yyerror("Mandatory parameter follows optional parameter");
    }

    if(is_named) {
      if(!defop) {
        defop = (OP *)alloc_LOGOP_ANY(OP_CUSTOM, NULL, NULL);
        defop->op_ppaddr = &pp_namedargdefelem;

        varop->op_flags |= OPf_STACKED;
        op_sibling_splice(varop, NULL, 0, defop);

        LINKLIST(varop);

        varop->op_next = defop;
      }

      ANY *op_any;
      Newx(op_any, 2, ANY);

      op_any[0].any_sv = argname;
      /* [1] is filled in later */

      cLOGOP_ANYx(defop)->op_any = op_any;
    }
  }
  else {
    if(is_named)
      yyerror("Slurpy parameters may not be named");
    if(parser->sig_slurpy && parser->sig_slurpy != '+')
      yyerror("Multiple slurpy parameters not allowed");

    parser->sig_slurpy = c;

    if(lex_peek_unichar(0) == '=')
      yyerror("A slurpy parameter may not have a default value");
  }

  return varop ? newSTATEOP(0, NULL, varop) : NULL;
}

#define parse_subsignature(flags)  S_parse_subsignature(aTHX_ flags)
static OP *S_parse_subsignature(pTHX_ int flags)
{
  /* Mostly reconstructed logic from perl 5.28.0's toke.c and perly.y
   */
  yy_parser *parser = PL_parser;

  bool permit_named_params = flags & PARSE_SUBSIGNATURE_NAMED_PARAMS;

  assert((flags & ~(PARSE_SUBSIGNATURE_NAMED_PARAMS)) == 0);

  ENTER;
  SAVEIV(parser->sig_elems);
  SAVEIV(parser->sig_optelems);
  SAVEI8(parser->sig_slurpy);

  parser->sig_elems = 0;
  parser->sig_optelems = 0;
  parser->sig_slurpy = 0;

  OP *elems = NULL;
  OP *namedelems = NULL;
  OP *final_elem = NULL;

  while(lex_peek_unichar(0) != ')') {
    lex_read_space(0);
    OP *elem = parse_sigelem(flags);

    /* placeholder anonymous elems are NULL */
    if(elem) {
      /* elem should be an OP_LINESEQ[ OP_NEXTSTATE. actual elem ] */
      assert(elem->op_type == OP_LINESEQ);
      assert(cLISTOPx(elem)->op_first);
      assert(OpSIBLING(cLISTOPx(elem)->op_first));

      final_elem = OpSIBLING(cLISTOPx(elem)->op_first);

      assert(final_elem->op_type == OP_ARGELEM);

      if(OP_IS_NAMED_PARAM(final_elem))
        namedelems = op_append_list(OP_LIST, namedelems, elem);
      else
        elems = op_append_list(OP_LINESEQ, elems, elem);
    }

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

  bool allow_extras_after_named = true;
  if(namedelems) {
    switch(PL_parser->sig_slurpy) {
      case 0:
      case '@':
        NOT_REACHED;
      case '+':
        {
          /* Pretend we have a new, unnamed slurpy hash */
          OP *varop = newUNOP_AUX(OP_ARGELEM, 0, NULL, NULL);
          varop->op_private |= OPpARGELEM_HV;
          varop->op_targ = pad_add_name_pvs("%(params)", 0, NULL, NULL);

          final_elem = varop;

          OP *elem = newSTATEOP(0, NULL, varop);
          elems = op_append_list(OP_LINESEQ, elems, elem);

          PL_parser->sig_slurpy = '%';
          allow_extras_after_named = false;
        }
        break;
      case '%':
        break;
    }
  }

  UNOP_AUX_item *aux = make_argcheck_aux(
    parser->sig_elems, parser->sig_optelems, parser->sig_slurpy);

  OP *checkop = newUNOP_AUX(OP_ARGCHECK, 0, NULL, aux);

  OP *ops = op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL),
      op_prepend_elem(OP_LINESEQ, checkop, elems));

  if(namedelems) {
    assert(final_elem->op_type == OP_ARGELEM);
    assert(final_elem->op_private == OPpARGELEM_HV);

    PADOFFSET slurpy_padix = final_elem->op_targ;

    /* Tell all the pp_namedargdefelem()s where to find the slurpy hash */
    for(OP *o = namedelems; o; o = OpSIBLING(o)) {
      assert(o->op_type == OP_LINESEQ);
      assert(cLISTOPo->op_first->op_type == OP_NEXTSTATE);

      OP *elemop = OpSIBLING(cLISTOPo->op_first);
      assert(elemop);
      assert(OP_IS_NAMED_PARAM(elemop));

      ANY *op_any = cLOGOP_ANYx(cUNOPx(elemop)->op_first)->op_any;
      op_any[1].any_iv = slurpy_padix;
    }

    ops = op_append_list(OP_LINESEQ, ops,
      namedelems);

    if(!allow_extras_after_named) {
      ops = op_append_list(OP_LINESEQ, ops,
        newSTATEOP(0, NULL, checkop = newOP(OP_CUSTOM, 0)));
      checkop->op_ppaddr = &pp_checknomorenamed;
      checkop->op_targ = slurpy_padix;
    }
  }

  /* a nextstate at the end handles context correctly for an empty
   * sub body */
  ops = op_append_elem(OP_LINESEQ, ops, newSTATEOP(0, NULL, NULL));

  LEAVE;

  return ops;
}

#endif
