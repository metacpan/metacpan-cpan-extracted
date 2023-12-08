/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2021-2022 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseKeyword.h"
#include "XSParseInfix.h"

#include "perl-backcompat.c.inc"

static const char hintkey[] = "t::pieces/permit";

static int build_expr(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *expr = arg0->op;

  if(!expr) {
    *out = newOP(OP_STUB, 0);
    return KEYWORD_PLUGIN_EXPR;
  }

  /* wrap the result in "("...")" parens so we can unit-test how it parsed */
  *out = newBINOP(OP_CONCAT, 0,
    newBINOP(OP_CONCAT, 0, newSVOP(OP_CONST, 0, newSVpvs("(")), op_scope(expr)),
    newSVOP(OP_CONST, 0, newSVpvs(")")));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_prefixedblock(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  PADOFFSET padix = args[0]->padix;
  OP *value       = args[1]->op;
  OP *body        = args[2]->op;

  OP *padsvop = newOP(OP_PADSV, OPf_MOD|(OPpLVAL_INTRO<<8));
  padsvop->op_targ = padix;

  *out = op_prepend_elem(OP_LINESEQ,
    newBINOP(OP_SASSIGN, 0, value, padsvop),
    body);

  return KEYWORD_PLUGIN_EXPR;
}

static int build_anonsub(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  *out = newUNOP(OP_REFGEN, 0,
    newSVOP(OP_ANONCODE, 0, (SV *)arg0->cv));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_list(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  OP *list = arg0->op;

  if(!list) {
    *out = newOP(OP_STUB, 0);
    return KEYWORD_PLUGIN_EXPR;
  }

  /* TODO: Consider always doing this? */
  if(list->op_type != OP_LIST)
    list = newLISTOP(OP_LIST, 0, list, NULL);

  /* unshift $sep */
#if HAVE_PERL_VERSION(5, 22, 0)
  op_sibling_splice(list, cUNOPx(list)->op_first, 0, newSVOP(OP_CONST, 0, newSVpvs(",")));
#else
  {
    OP *o = newSVOP(OP_CONST, 0, newSVpvs(","));
    o->op_sibling = cUNOPx(list)->op_first->op_sibling;
    cUNOPx(list)->op_first->op_sibling = o;
  }
#endif

  *out = op_convert_list(OP_JOIN, 0, list);

  return KEYWORD_PLUGIN_EXPR;
}

static int build_constsv(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, arg0->sv);
  return KEYWORD_PLUGIN_EXPR;
}

static int build_constsv_or_undef(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  if(arg0->sv)
    *out = newSVOP(OP_CONST, 0, arg0->sv);
  else
    *out = newOP(OP_UNDEF, OPf_WANT_SCALAR);
  return KEYWORD_PLUGIN_EXPR;
}

static int build_constpadix(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  *out = newSVOP(OP_CONST, 0, newSVuv(arg0->padix));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_literal(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  /* ignore arg0 */

  *out = newSVOP(OP_CONST, 0, SvREFCNT_inc((SV *)hookdata));

  return KEYWORD_PLUGIN_EXPR;
}

static int build_attrs(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  int nattrs = args[0]->i;

  SV *retsv = newSV(0);
  sv_setpvs(retsv, "");

  int argi;
  for(argi = 0; argi < nattrs; argi++)
    sv_catpvf(retsv, ":%s(%s)",
      SvPV_nolen(args[argi+1]->attr.name),
      SvPOK(args[argi+1]->attr.value) ? SvPV_nolen(args[argi+1]->attr.value) : "");

  *out = newSVOP(OP_CONST, 0, retsv);
  return KEYWORD_PLUGIN_EXPR;
}

static int build_infix_opname(pTHX_ OP **out, XSParseKeywordPiece *arg0, void *hookdata)
{
  const char *opname = PL_op_name[arg0->infix->opcode];
  *out = newSVOP(OP_CONST, 0, newSVpvn(opname, strlen(opname)));
  return KEYWORD_PLUGIN_EXPR;
}

static int build_lexvar_intro(pTHX_ OP **out, XSParseKeywordPiece *args[], size_t nargs, void *hookdata)
{
  PADOFFSET padix = args[0]->padix;
  OP *expr = args[1]->op;

  OP *varop = newOP(OP_PADSV, OPf_MOD|OPf_REF | (OPpLVAL_INTRO << 8));
  varop->op_targ = padix;

  OP *assignop = newASSIGNOP(OPf_WANT_VOID, varop, 0, newSVOP(OP_CONST, 0, newSViv(1)));

  *out = newLISTOP(OP_LINESEQ, 0, assignop, expr);
  return KEYWORD_PLUGIN_EXPR;
}

static void setup_block_VAR(pTHX_ void *hookdata)
{
  char *varname = hookdata;
  PADOFFSET padix = pad_add_name_pvn(varname, strlen(varname), 0, NULL, NULL);
  intro_my();

  sv_setpvs(PAD_SVl(padix), "Hello");
}

static void callback_catpv_stages(pTHX_ const char *pv)
{
  SV *sv = get_sv("main::STAGES", GV_ADD);
  if(!SvPOK(sv))
    sv_setpvs(sv, "");

  if(SvCUR(sv))
    sv_catpvs(sv, ",");

  sv_catpv(sv, pv);
}

static void callback_PREPARE(pTHX_ void *hookdata)
{
  callback_catpv_stages(aTHX_ "PREPARE");
}

static void callback_START(pTHX_ void *hookdata)
{
  callback_catpv_stages(aTHX_ "START");
}

static OP *callback_END(pTHX_ OP *o, void *hookdata)
{
  callback_catpv_stages(aTHX_ "END");
  return o;
}

static OP *callback_WRAP(pTHX_ OP *o, void *hookdata)
{
  callback_catpv_stages(aTHX_ "WRAP");
  return o;
}

static const struct XSParseKeywordHooks hooks_block = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_BLOCK,
  .build1 = &build_expr,
};
static const struct XSParseKeywordHooks hooks_block_scalar = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_BLOCK_SCALARCTX,
  .build1 = &build_list,
};
static const struct XSParseKeywordHooks hooks_block_list = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_BLOCK_LISTCTX,
  .build1 = &build_list,
};

static const struct XSParseKeywordHooks hooks_prefixedblock = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_PREFIXED_BLOCK( XPK_LEXVAR_MY(XPK_LEXVAR_SCALAR), XPK_EQUALS, XPK_TERMEXPR_SCALARCTX, XPK_COMMA ),
    {0}
  },
  .build = &build_prefixedblock,
};

static const struct XSParseKeywordHooks hooks_prefixedblock_VAR = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_PREFIXED_BLOCK( XPK_SETUP(&setup_block_VAR) ),
  .build1 = &build_expr,
};

static const struct XSParseKeywordHooks hooks_anonsub = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_ANONSUB,
  .build1 = &build_anonsub,
};

static const struct XSParseKeywordHooks hooks_stagedanonsub = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_STAGED_ANONSUB(
    XPK_ANONSUB_PREPARE(&callback_PREPARE),
    XPK_ANONSUB_START(&callback_START),
    XPK_ANONSUB_START(&setup_block_VAR),
    XPK_ANONSUB_END(&callback_END),
    XPK_ANONSUB_WRAP(&callback_WRAP)
  ),
  .build1 = &build_anonsub,
};

static const struct XSParseKeywordHooks hooks_arithexpr = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_ARITHEXPR,
  .build1 = &build_expr,
};
static const struct XSParseKeywordHooks hooks_arithexpr_opt = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_ARITHEXPR_OPT,
  .build1 = &build_expr,
};

static const struct XSParseKeywordHooks hooks_termexpr = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_TERMEXPR,
  .build1 = &build_expr,
};
static const struct XSParseKeywordHooks hooks_termexpr_opt = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_TERMEXPR_OPT,
  .build1 = &build_expr,
};

static const struct XSParseKeywordHooks hooks_prefixedtermexpr_VAR = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_PREFIXED_TERMEXPR_ENTERLEAVE( XPK_SETUP(&setup_block_VAR) ),
  .build1 = &build_expr,
};

static const struct XSParseKeywordHooks hooks_listexpr = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LISTEXPR,
  .build1 = &build_list,
};
static const struct XSParseKeywordHooks hooks_listexpr_opt = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LISTEXPR_OPT,
  .build1 = &build_list,
};

static const struct XSParseKeywordHooks hooks_ident = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_IDENT,
  .build1 = &build_constsv,
};

static const struct XSParseKeywordHooks hooks_ident_opt = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_IDENT_OPT,
  .build1 = &build_constsv_or_undef,
};

static const struct XSParseKeywordHooks hooks_packagename = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_PACKAGENAME,
  .build1 = &build_constsv,
};

static const struct XSParseKeywordHooks hooks_lexvar_name = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LEXVARNAME(XPK_LEXVAR_ANY),
  .build1 = &build_constsv,
};

static const struct XSParseKeywordHooks hooks_lexvar = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LEXVAR(XPK_LEXVAR_ANY),
  .build1 = &build_constpadix,
};

static const struct XSParseKeywordHooks hooks_lexvar_my = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LEXVAR_MY(XPK_LEXVAR_ANY),
  .build1 = &build_constpadix,
};

static const struct XSParseKeywordHooks hooks_lexvar_my_intro = {
  .flags = XPK_FLAG_BLOCKSCOPE,
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_LEXVAR_MY(XPK_LEXVAR_ANY),
    XPK_KEYWORD("in"),
    XPK_INTRO_MY,
    XPK_TERMEXPR,
    0
  },
  .build = &build_lexvar_intro,
};

static const struct XSParseKeywordHooks hooks_attrs = {
  .permit_hintkey = hintkey,

  .pieces = (const struct XSParseKeywordPieceType []){
    XPK_ATTRIBUTES,
    {0},
  },
  .build = &build_attrs,
};

static const struct XSParseKeywordHooks hooks_vstring = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_VSTRING,
  .build1 = &build_constsv,
};

static const struct XSParseKeywordHooks hooks_vstring_opt = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_VSTRING_OPT,
  .build1 = &build_constsv_or_undef,
};

static const struct XSParseKeywordHooks hooks_infix_relation = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_INFIX_RELATION,
  .build1 = &build_infix_opname,
};

static const struct XSParseKeywordHooks hooks_infix_equality = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_INFIX_EQUALITY,
  .build1 = &build_infix_opname,
};

static const struct XSParseKeywordHooks hooks_colon = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_COLON,
  .build1 = &build_literal,
};

static const struct XSParseKeywordHooks hooks_str = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_LITERAL("foo"),
  .build1 = &build_literal,
};

static const struct XSParseKeywordHooks hooks_kw = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_KEYWORD("bar"),
  .build1 = &build_literal,
};

static const struct XSParseKeywordHooks hooks_autosemi = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_AUTOSEMI,
  .build1 = &build_literal,
};

static const struct XSParseKeywordHooks hooks_warning = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_WARNING("A warning here\n"),
  .build1 = &build_literal,
};

static const struct XSParseKeywordHooks hooks_warning_deprecated = {
  .permit_hintkey = hintkey,

  .piece1 = XPK_WARNING_DEPRECATED("A deprecated warning here\n"),
  .build1 = &build_literal,
};

MODULE = t::pieces  PACKAGE = t::pieces

BOOT:
  boot_xs_parse_keyword(0);

  register_xs_parse_keyword("pieceblock", &hooks_block, NULL);
  register_xs_parse_keyword("pieceblock_scalar", &hooks_block_scalar, NULL);
  register_xs_parse_keyword("pieceblock_list",   &hooks_block_list,   NULL);

  register_xs_parse_keyword("pieceprefixedblock", &hooks_prefixedblock, NULL);
  register_xs_parse_keyword("pieceprefixedblock_VAR", &hooks_prefixedblock_VAR, "$VAR");

  register_xs_parse_keyword("pieceanonsub", &hooks_anonsub, NULL);

  register_xs_parse_keyword("piecestagedanonsub", &hooks_stagedanonsub, "$VAR");

  register_xs_parse_keyword("piecearithexpr",     &hooks_arithexpr,     NULL);
  register_xs_parse_keyword("piecearithexpr_opt", &hooks_arithexpr_opt, NULL);
  register_xs_parse_keyword("piecetermexpr",      &hooks_termexpr,      NULL);
  register_xs_parse_keyword("piecetermexpr_opt",  &hooks_termexpr_opt,  NULL);
  register_xs_parse_keyword("piecelistexpr",      &hooks_listexpr,      NULL);
  register_xs_parse_keyword("piecelistexpr_opt",  &hooks_listexpr_opt,  NULL);

  register_xs_parse_keyword("pieceprefixedtermexpr_VAR", &hooks_prefixedtermexpr_VAR, "$VAR");

  register_xs_parse_keyword("pieceident", &hooks_ident, NULL);
  register_xs_parse_keyword("pieceident_opt", &hooks_ident_opt, NULL);
  register_xs_parse_keyword("piecepkg", &hooks_packagename, NULL);

  register_xs_parse_keyword("piecelexvarname", &hooks_lexvar_name, NULL);
  register_xs_parse_keyword("piecelexvar",     &hooks_lexvar,      NULL);
  register_xs_parse_keyword("piecelexvarmy",   &hooks_lexvar_my,   NULL);
  register_xs_parse_keyword("piecelexvarmyintro", &hooks_lexvar_my_intro, NULL);

  register_xs_parse_keyword("pieceattrs", &hooks_attrs, NULL);

  register_xs_parse_keyword("piecevstring",     &hooks_vstring,     NULL);
  register_xs_parse_keyword("piecevstring_opt", &hooks_vstring_opt, NULL);

  register_xs_parse_keyword("pieceinfix",   &hooks_infix_relation, NULL);
  register_xs_parse_keyword("pieceinfixeq", &hooks_infix_equality, NULL);

  register_xs_parse_keyword("piececolon", &hooks_colon, newSVpvs("colon"));

  register_xs_parse_keyword("piecestr", &hooks_str, newSVpvs("foo"));
  register_xs_parse_keyword("piecekw",  &hooks_kw,  newSVpvs("bar"));

  register_xs_parse_keyword("pieceautosemi", &hooks_autosemi, newSVpvs("EOS"));

  register_xs_parse_keyword("piecewarning", &hooks_warning, &PL_sv_undef);
  register_xs_parse_keyword("piecewarndep", &hooks_warning_deprecated, &PL_sv_undef);
