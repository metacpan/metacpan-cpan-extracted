/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019-2021 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "XSParseSublike.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 37, 10)
/* feature 'class' first became available in 5.37.9 but it wasn't until
 * 5.37.10 that we could pass CVf_IsMETHOD to start_subparse()
 */
#  define HAVE_FEATURE_CLASS
#endif

#if HAVE_PERL_VERSION(5, 26, 0)
#  if HAVE_PERL_VERSION(5, 31, 3)
    /* We're going to need to have access to *both* core and haxlib's
     * parse_subsignature(). In order to do that we'll do some fairly fun
     * hackery here
     */
#    define CORE_parse_subsignature(flags)  S_CORE_parse_subsignature(aTHX_ flags)
    static OP *S_CORE_parse_subsignature(pTHX_ U32 flags)
    {
      return parse_subsignature(flags);
    }
#    undef parse_subsignature
#  endif
#  include "parse_subsignature.c.inc"

#  define HAX_parse_subsignature(flags)  S_HAX_parse_subsignature(aTHX_ flags)
  static OP *S_HAX_parse_subsignature(pTHX_ U32 flags)
  {
    return parse_subsignature(flags);
  }

#  if HAVE_PERL_VERSION(5, 31, 3)
#    undef parse_subsignature
#    define parse_subsignature CORE_parse_subsignature
#  endif

#  include "make_argcheck_aux.c.inc"

#  define HAVE_PARSE_SUBSIGNATURE
#endif

#if !HAVE_PERL_VERSION(5, 22, 0)
#  include "block_start.c.inc"
#  include "block_end.c.inc"
#endif

#ifndef wrap_keyword_plugin
#  include "wrap_keyword_plugin.c.inc"
#endif

#include "lexer-additions.c.inc"

struct HooksAndData {
  const struct XSParseSublikeHooks *hooks;
  void *data;
};

#define FOREACH_HOOKS_FORWARD \
  for(hooki = 0; \
    (hooki < nhooks) && (hooks = hooksanddata[hooki].hooks, hookdata = hooksanddata[hooki].data), (hooki < nhooks); \
    hooki++)

#define FOREACH_HOOKS_REVERSE \
  for(hooki = nhooks - 1; \
    (hooki >= 0) && (hooks = hooksanddata[hooki].hooks, hookdata = hooksanddata[hooki].data), (hooki >= 0); \
    hooki--)

/* Non-documented internal flags we use for our own purposes */
enum {
  XS_PARSE_SUBLIKE_ACTION_CVf_IsMETHOD = (1<<31),  /* do we set CVf_IsMETHOD? */
};

static int parse(pTHX_
  struct HooksAndData hooksanddata[],
  size_t nhooks,
  OP **op_ptr)
{
  struct XSParseSublikeContext ctx = { 0 };

  IV hooki;
  const struct XSParseSublikeHooks *hooks;
  void *hookdata;

  U8 require_parts = 0, skip_parts = 0;
  bool have_dynamic_actions = FALSE;

  ENTER_with_name("parse_sublike");
  /* From here onwards any `return` must be prefixed by LEAVE_with_name() */
  U32 was_scopestack_ix = PL_scopestack_ix;

  ctx.moddata = newHV();
  SAVEFREESV(ctx.moddata);

  FOREACH_HOOKS_FORWARD {
    require_parts |= hooks->require_parts;
    skip_parts    |= hooks->skip_parts;
    if(!(hooks->flags & XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL))
      require_parts |= XS_PARSE_SUBLIKE_PART_BODY;
    if(hooks->flags & XS_PARSE_SUBLIKE_COMPAT_FLAG_DYNAMIC_ACTIONS)
      have_dynamic_actions = TRUE;
  }

  if(!(skip_parts & XS_PARSE_SUBLIKE_PART_NAME)) {
    ctx.name = lex_scan_ident();
    lex_read_space(0);
  }
  if((require_parts & XS_PARSE_SUBLIKE_PART_NAME) && !ctx.name)
    croak("Expected name for sub-like construction");

  /* Initial idea of actions are determined by whether we have a name */
  ctx.actions = ctx.name
    ? /* named */ XS_PARSE_SUBLIKE_ACTION_SET_CVNAME|XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL
    : /* anon  */ XS_PARSE_SUBLIKE_ACTION_CVf_ANON|XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE|XS_PARSE_SUBLIKE_ACTION_RET_EXPR;

  FOREACH_HOOKS_FORWARD {
    if(hooks->pre_subparse)
      (*hooks->pre_subparse)(aTHX_ &ctx, hookdata);
  }

#ifdef DEBUGGING
  if(PL_scopestack_ix != was_scopestack_ix)
    croak("ARGH: pre_subparse broke the scopestack (was %d, now %d)\n",
      was_scopestack_ix, PL_scopestack_ix);
#endif

  if(!have_dynamic_actions) {
    if(ctx.name)
      ctx.actions &= ~XS_PARSE_SUBLIKE_ACTION_CVf_ANON;
    else
      ctx.actions |= XS_PARSE_SUBLIKE_ACTION_CVf_ANON;
  }

  int subparse_flags = 0;
  if(ctx.actions & XS_PARSE_SUBLIKE_ACTION_CVf_ANON)
    subparse_flags |= CVf_ANON;
#ifdef HAVE_FEATURE_CLASS
  if(ctx.actions & XS_PARSE_SUBLIKE_ACTION_CVf_IsMETHOD)
    subparse_flags |= CVf_IsMETHOD;
#endif

  I32 floor_ix = start_subparse(FALSE, subparse_flags);
  SAVEFREESV(PL_compcv);

  if(!(skip_parts & XS_PARSE_SUBLIKE_PART_ATTRS) && (lex_peek_unichar(0) == ':')) {
    lex_read_unichar(0);
    lex_read_space(0);

    ctx.attrs = newLISTOP(OP_LIST, 0, NULL, NULL);

    while(1) {
      SV *attr = newSV(0);
      SV *val  = newSV(0);
      if(!lex_scan_attrval_into(attr, val))
        break;
      lex_read_space(0);
      if(lex_peek_unichar(0) == ':') {
        lex_read_unichar(0);
        lex_read_space(0);
      }

      bool handled = FALSE;

      FOREACH_HOOKS_FORWARD {
        if((hooks->flags & XS_PARSE_SUBLIKE_FLAG_FILTERATTRS) && (hooks->filter_attr))
          handled |= (*hooks->filter_attr)(aTHX_ &ctx, attr, val, hookdata);
      }

      if(handled) {
        SvREFCNT_dec(attr);
        SvREFCNT_dec(val);
        continue;
      }

      if(strEQ(SvPVX(attr), "lvalue")) {
        CvLVALUE_on(PL_compcv);
        continue;
      }

      if(SvPOK(val))
        sv_catpvf(attr, "(%" SVf ")", val);
      SvREFCNT_dec(val);

      ctx.attrs = op_append_elem(OP_LIST, ctx.attrs, newSVOP(OP_CONST, 0, attr));
    }
  }

  PL_hints |= HINT_LOCALIZE_HH;
  I32 save_ix = block_start(TRUE);

  FOREACH_HOOKS_FORWARD {
    if(hooks->post_blockstart)
      (*hooks->post_blockstart)(aTHX_ &ctx, hookdata);
  }

#ifdef DEBUGGING
  if(PL_scopestack_ix != was_scopestack_ix)
    croak("ARGH: post_blockstart broke the scopestack (was %d, now %d)\n",
      was_scopestack_ix, PL_scopestack_ix);
#endif

#ifdef HAVE_PARSE_SUBSIGNATURE
  OP *sigop = NULL;
  if(!(skip_parts & XS_PARSE_SUBLIKE_PART_SIGNATURE) && (lex_peek_unichar(0) == '(')) {
    lex_read_unichar(0);
    lex_read_space(0);

#if HAVE_PERL_VERSION(5, 31, 3)
    /* core's parse_subsignature doesn't seem able to handle empty sigs
     *   RT132284
     *   https://github.com/Perl/perl5/issues/17689
     */
    if(lex_peek_unichar(0) == ')') {
      /* Inject an empty OP_ARGCHECK much as core would do if it encountered
       * an empty signature */
      UNOP_AUX_item *aux = make_argcheck_aux(0, 0, 0);

      sigop = op_prepend_elem(OP_LINESEQ, newSTATEOP(0, NULL, NULL),
        newUNOP_AUX(OP_ARGCHECK, 0, NULL, aux));

      /* a nextstate at the end handles context correctly for an empty
       * sub body */
      sigop = op_append_elem(OP_LINESEQ, sigop, newSTATEOP(0, NULL, NULL));

#if HAVE_PERL_VERSION(5,31,5)
      /* wrap the list of arg ops in a NULL aux op.  This serves two
       * purposes. First, it makes the arg list a separate subtree
       * from the body of the sub, and secondly the null op may in
       * future be upgraded to an OP_SIGNATURE when implemented. For
       * now leave it as ex-argcheck
       */
      sigop = newUNOP_AUX(OP_ARGCHECK, 0, sigop, NULL);
      op_null(sigop);
#endif
    }
    else
#endif
    {
      bool signature_named_params = false;
      FOREACH_HOOKS_FORWARD {
        if(hooks->flags & XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS)
          signature_named_params = true;
      }

      if(signature_named_params)
        sigop = HAX_parse_subsignature(PARSE_SUBSIGNATURE_NAMED_PARAMS);
      else
        sigop = parse_subsignature(0);

      if(PL_parser->error_count) {
        assert(PL_scopestack_ix == was_scopestack_ix);
        LEAVE_with_name("parse_sublike");
        return 0;
      }
    }

    if(lex_peek_unichar(0) != ')')
      croak("Expected ')'");
    lex_read_unichar(0);
    lex_read_space(0);
  }
#endif

  if(lex_peek_unichar(0) == '{') {
    /* TODO: technically possible to have skip body flag */
    ctx.body = parse_block(0);
    SvREFCNT_inc(PL_compcv);
  }
  else if(require_parts & XS_PARSE_SUBLIKE_PART_BODY)
    croak("Expected '{' for block body");
  else if(lex_peek_unichar(0) == ';') {
    /* nothing to be done */
  }
  else
    croak("Expected '{' for block body or ';'");

#ifdef HAVE_PARSE_SUBSIGNATURE
  if(ctx.body && sigop) {
    /* parse_block() returns an empy block as a stub op.
     * no need to keep that if we we have a signature.
     */
    if (ctx.body->op_type == OP_STUB) {
      op_free(ctx.body);
      ctx.body = NULL;
    }
    ctx.body = op_append_list(OP_LINESEQ, sigop, ctx.body);
  }
#endif

  if(PL_parser->error_count) {
    /* parse_block() still sometimes returns a valid body even if a parse
     * error happens.
     * We need to destroy this partial body before returning a valid(ish)
     * state to the keyword hook mechanism, so it will find the error count
     * correctly
     *   See https://rt.cpan.org/Ticket/Display.html?id=130417
     */
    op_free(ctx.body);

    /* REALLY??! Do I really have to do this??
     * See also:
     *   https://www.nntp.perl.org/group/perl.perl5.porters/2021/06/msg260642.html
     */
    while(PL_scopestack_ix > was_scopestack_ix)
      LEAVE;

    *op_ptr = newOP(OP_NULL, 0);
    if(ctx.name) {
      SvREFCNT_dec(ctx.name);
      assert(PL_scopestack_ix == was_scopestack_ix);
      LEAVE_with_name("parse_sublike");
      return KEYWORD_PLUGIN_STMT;
    }
    else {
      assert(PL_scopestack_ix == was_scopestack_ix);
      LEAVE_with_name("parse_sublike");
      return KEYWORD_PLUGIN_EXPR;
    }
  }

  FOREACH_HOOKS_REVERSE {
    if(hooks->pre_blockend)
      (*hooks->pre_blockend)(aTHX_ &ctx, hookdata);
  }

#ifdef DEBUGGING
  if(PL_scopestack_ix != was_scopestack_ix)
    croak("ARGH: pre_blockend broke the scopestack (was %d, now %d)\n",
      was_scopestack_ix, PL_scopestack_ix);
#endif

  if(ctx.body) {
    ctx.body = block_end(save_ix, ctx.body);

    if(!have_dynamic_actions) {
      if(ctx.name)
        ctx.actions |= XS_PARSE_SUBLIKE_ACTION_SET_CVNAME|XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
      else
        ctx.actions &= ~(XS_PARSE_SUBLIKE_ACTION_SET_CVNAME|XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL);
    }

    /* If we want both SET_CVNAME and INSTALL_SYMBOL actions we might as well
     * let newATTRSUB() do it. If we only wanted one we need to be more subtle
     */
    bool action_set_cvname     = ctx.actions & XS_PARSE_SUBLIKE_ACTION_SET_CVNAME;
    bool action_install_symbol = ctx.actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
    OP *nameop = NULL;
    if(ctx.name && action_set_cvname && action_install_symbol)
      nameop = newSVOP(OP_CONST, 0, SvREFCNT_inc(ctx.name));

    if(!nameop && action_install_symbol)
      warn("Setting XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL without _ACTION_SET_CVNAME is nonsensical");

    ctx.cv = newATTRSUB(floor_ix, nameop, NULL, ctx.attrs, ctx.body);

    if(!nameop && action_set_cvname) {
#if HAVE_PERL_VERSION(5,22,0)
      STRLEN namelen;
      const char *name = SvPV_const(ctx.name, namelen);
      U32 hash;
      PERL_HASH(hash, name, namelen);

/* Core's CvNAME_HEK_set macro uses unshare_hek() which isn't exposed. But we
 * likely don't need it here */
#ifndef unshare_hek
#  define unshare_hek(h)  (void)0
#endif
      assert(!CvNAME_HEK(ctx.cv));

      CvNAME_HEK_set(ctx.cv,
        share_hek(name, SvUTF8(ctx.name) ? -namelen : namelen, hash));
#endif
    }

    ctx.attrs = NULL;
    ctx.body = NULL;
  }

  FOREACH_HOOKS_FORWARD {
    if(hooks->post_newcv)
      (*hooks->post_newcv)(aTHX_ &ctx, hookdata);
  }

  assert(PL_scopestack_ix == was_scopestack_ix);
  LEAVE_with_name("parse_sublike");

  if(!have_dynamic_actions) {
    if(!ctx.name)
      ctx.actions |= XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE;
    else
      ctx.actions &= ~XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE;
  }

  if(!(ctx.actions & XS_PARSE_SUBLIKE_ACTION_REFGEN_ANONCODE)) {
    *op_ptr = newOP(OP_NULL, 0);

    SvREFCNT_dec(ctx.name);
  }
  else {
    *op_ptr = newUNOP(OP_REFGEN, 0,
      newSVOP(OP_ANONCODE, 0, (SV *)ctx.cv));
  }

  if(!have_dynamic_actions) {
    if(!ctx.name)
      ctx.actions |= XS_PARSE_SUBLIKE_ACTION_RET_EXPR;
    else
      ctx.actions &= ~XS_PARSE_SUBLIKE_ACTION_RET_EXPR;
  }

  return (ctx.actions & XS_PARSE_SUBLIKE_ACTION_RET_EXPR) ? KEYWORD_PLUGIN_EXPR : KEYWORD_PLUGIN_STMT;
}

static int IMPL_xs_parse_sublike_v4(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)
{
  struct HooksAndData hd = { .hooks = hooks, .data = hookdata };
  return parse(aTHX_ &hd, 1, op_ptr);
}

static int IMPL_xs_parse_sublike_v3(pTHX_ const void *hooks, void *hookdata, OP **op_ptr)
{
  croak("XS::Parse::Sublike ABI v3 is no longer supported; the caller should be rebuilt to use v4");
}

struct Registration;
struct Registration {
  int ver;
  struct Registration *next;
  const char *kw;
  STRLEN      kwlen;
  union {
    const struct XSParseSublikeHooks *hooks;
  };
  void       *hookdata;

  STRLEN permit_hintkey_len;
};

#define REGISTRATIONS_LOCK   OP_CHECK_MUTEX_LOCK
#define REGISTRATIONS_UNLOCK OP_CHECK_MUTEX_UNLOCK

static struct Registration *registrations;

static void register_sublike(pTHX_ const char *kw, const void *hooks, void *hookdata, int ver)
{
  struct Registration *reg;
  Newx(reg, 1, struct Registration);

  reg->kw = savepv(kw);
  reg->kwlen = strlen(kw);
  reg->ver = ver;
  reg->hooks = hooks;
  reg->hookdata = hookdata;

  if(reg->ver >= 4 && reg->hooks->permit_hintkey)
    reg->permit_hintkey_len = strlen(reg->hooks->permit_hintkey);
  else
    reg->permit_hintkey_len = 0;

  REGISTRATIONS_LOCK;
  {
    reg->next = registrations;
    registrations = reg;
  }
  REGISTRATIONS_UNLOCK;
}

static void IMPL_register_xs_parse_sublike_v4(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata)
{
  register_sublike(aTHX_ kw, hooks, hookdata, 4);
}

static void IMPL_register_xs_parse_sublike_v3(pTHX_ const char *kw, const void *hooks, void *hookdata)
{
  croak("XS::Parse::Sublike ABI v3 is no longer supported; the caller should be rebuilt to use v4");
}

static const struct Registration *find_permitted(pTHX_ const char *kw, STRLEN kwlen)
{
  const struct Registration *reg;

  HV *hints = GvHV(PL_hintgv);

  for(reg = registrations; reg; reg = reg->next) {
    if(reg->kwlen != kwlen || !strEQ(reg->kw, kw))
      continue;

    if(reg->hooks->permit_hintkey &&
      (!hints || !hv_fetch(hints, reg->hooks->permit_hintkey, reg->permit_hintkey_len, 0)))
      continue;

    if(reg->hooks->permit &&
      !(*reg->hooks->permit)(aTHX_ reg->hookdata))
      continue;

    return reg;
  }

  return NULL;
}

static int IMPL_xs_parse_sublike_any_v4(pTHX_ const struct XSParseSublikeHooks *hooksA, void *hookdataA, OP **op_ptr)
{
  SV *kwsv = lex_scan_ident();
  if(!kwsv || !SvCUR(kwsv))
    croak("Expected a keyword to introduce a sub or sub-like construction");

  const char *kw = SvPV_nolen(kwsv);
  STRLEN kwlen = SvCUR(kwsv);

  lex_read_space(0);

  const struct Registration *reg = NULL;
  /* We permit 'sub' as a NULL set of hooks; anything else should be a registered keyword */
  if(kwlen != 3 || !strEQ(kw, "sub")) {
    reg = find_permitted(aTHX_ kw, kwlen);
    if(!reg)
      croak("Expected a keyword to introduce a sub or sub-like construction, found \"%.*s\"",
        kwlen, kw);
  }

  SvREFCNT_dec(kwsv);

  struct HooksAndData hd[] = {
    { .hooks = hooksA, .data = hookdataA },
    { 0 }
  };
  struct XSParseSublikeHooks hooks;

  if(reg) {
    hd[1].hooks = reg->hooks;
    hd[1].data  = reg->hookdata;
  }

  return parse(aTHX_ hd, 1 + !!reg, op_ptr);
}

static int IMPL_xs_parse_sublike_any_v3(pTHX_ const void *hooksA, void *hookdataA, OP **op_ptr)
{
  croak("XS::Parse::Sublike ABI v3 is no longer supported; the caller should be rebuilt to use v4");
}

#ifdef HAVE_FEATURE_CLASS
static bool permit_core_method(pTHX_ void *hookdata)
{
  return FEATURE_CLASS_IS_ENABLED;
}

static void pre_subparse_core_method(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  ctx->actions |= XS_PARSE_SUBLIKE_ACTION_CVf_IsMETHOD;
}

static const struct XSParseSublikeHooks hooks_core_method = {
  .permit = &permit_core_method,
  .pre_subparse = &pre_subparse_core_method,
};
#endif

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
  const struct Registration *reg = find_permitted(aTHX_ kw, kwlen);

  if(!reg)
    return (*next_keyword_plugin)(aTHX_ kw, kwlen, op_ptr);

  lex_read_space(0);

  /* We'll abuse the SvPVX storage of an SV to keep an array of HooksAndData
   * structures
   */
  SV *hdlsv = newSV(4 * sizeof(struct HooksAndData));
  SAVEFREESV(hdlsv);
  struct HooksAndData *hd = (struct HooksAndData *)SvPVX(hdlsv);
  size_t nhooks = 1;

  struct XSParseSublikeHooks *hooks = (struct XSParseSublikeHooks *)reg->hooks;
  hd[0].hooks = hooks;
  hd[0].data  = reg->hookdata;

  while(hooks->flags & XS_PARSE_SUBLIKE_FLAG_PREFIX) {
    /* After a prefixing keyword, expect another one */
    SV *kwsv = lex_scan_ident();
    SAVEFREESV(kwsv);

    if(!kwsv || !SvCUR(kwsv))
      croak("Expected a keyword to introduce a sub or sub-like construction");

    kw = SvPV_nolen(kwsv);
    kwlen = SvCUR(kwsv);

    lex_read_space(0);

    /* We permit 'sub' as a NULL set of hooks; anything else should be a registered keyword */
    if(kwlen == 3 && strEQ(kw, "sub"))
      break;

    reg = find_permitted(aTHX_ kw, kwlen);
    if(!reg)
      croak("Expected a keyword to introduce a sub or sub-like construction, found \"%.*s\"",
          kwlen, kw);

    hooks = (struct XSParseSublikeHooks *)reg->hooks;

    if(SvLEN(hdlsv) < (nhooks + 1) * sizeof(struct HooksAndData)) {
      SvGROW(hdlsv, SvLEN(hdlsv) * 2);
      hd = (struct HooksAndData *)SvPVX(hdlsv);
    }
    hd[nhooks].hooks = hooks;
    hd[nhooks].data  = reg->hookdata;
    nhooks++;
  }

  return parse(aTHX_ hd, nhooks, op_ptr);
}

MODULE = XS::Parse::Sublike    PACKAGE = XS::Parse::Sublike

BOOT:
  /* Legacy lookup mechanism using perl symbol table */
  sv_setiv(get_sv("XS::Parse::Sublike::ABIVERSION", GV_ADDMULTI), 4);
  sv_setuv(get_sv("XS::Parse::Sublike::PARSE",      GV_ADDMULTI), PTR2UV(&IMPL_xs_parse_sublike_v3));
  sv_setuv(get_sv("XS::Parse::Sublike::REGISTER",   GV_ADDMULTI), PTR2UV(&IMPL_register_xs_parse_sublike_v3));
  sv_setuv(get_sv("XS::Parse::Sublike::PARSEANY",   GV_ADDMULTI), PTR2UV(&IMPL_xs_parse_sublike_any_v3));

  /* Newer mechanism */
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/ABIVERSION_MIN", 1), 4);
  sv_setiv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/ABIVERSION_MAX", 1), XSPARSESUBLIKE_ABI_VERSION);
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parse()@4",    1), PTR2UV(&IMPL_xs_parse_sublike_v4));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register()@4", 1), PTR2UV(&IMPL_register_xs_parse_sublike_v4));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parseany()@4", 1), PTR2UV(&IMPL_xs_parse_sublike_any_v4));
#ifdef HAVE_FEATURE_CLASS
  register_sublike(aTHX_ "method", &hooks_core_method, NULL, 4);
#endif

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);
