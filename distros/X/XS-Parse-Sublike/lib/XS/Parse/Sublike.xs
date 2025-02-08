/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* We need to be able to see FEATURE_*_IS_ENABLED */
#define PERL_EXT
#include "feature.h"

#include "XSParseSublike.h"

#define HAVE_PERL_VERSION(R, V, S) \
    (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#if HAVE_PERL_VERSION(5, 37, 10)
/* feature 'class' first became available in 5.37.9 but it wasn't until
 * 5.37.10 that we could pass CVf_IsMETHOD to start_subparse()
 */
#  define HAVE_FEATURE_CLASS
#endif

#if HAVE_PERL_VERSION(5, 18, 0)
#  define HAVE_LEXICAL_SUB
#endif

/* We always need this included to get the struct and function definitions
 * visible, even though we won't be calling it
 */
#include "parse_subsignature_ex.h"

#if HAVE_PERL_VERSION(5, 26, 0)
#  include "make_argcheck_aux.c.inc"

#  if !HAVE_PERL_VERSION(5, 31, 3)
#    define parse_subsignature(flags)  parse_subsignature_ex(0, NULL, NULL, 0) /* ignore core flags as there are none */
#  endif

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

#define QUOTED_PVNf             "\"%.*s\"%s"
#define QUOTED_PVNfARG(pv,len)  ((len) <= 255 ? (int)(len) : 255), (pv), ((len) <= 255 ? "" : "...")

/* Non-documented internal flags we use for our own purposes */
enum {
  XS_PARSE_SUBLIKE_ACTION_CVf_IsMETHOD = (1<<31),  /* do we set CVf_IsMETHOD? */
};

static int parse(pTHX_
  struct HooksAndData hooksanddata[],
  size_t nhooks,
  OP **op_ptr)
{
  /* We need to reserve extra space in here for the sigctx pointer. To
   * simplify much code here lets just pretend `ctx` is the actual context
   * struct stored within
   */
  struct XPSContextWithPointer ctx_with_ptr = { 0 };
#define ctx  (ctx_with_ptr.ctx)

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
    ctx.name = lex_scan_packagename();
    lex_read_space(0);
  }
  if((require_parts & XS_PARSE_SUBLIKE_PART_NAME) && !ctx.name)
    croak("Expected name for sub-like construction");

  if(ctx.name && strstr(SvPV_nolen(ctx.name), "::")) {
    FOREACH_HOOKS_FORWARD {
      if(hooks->flags & XS_PARSE_SUBLIKE_FLAG_ALLOW_PKGNAME)
        continue;

      croak("Declaring this sub-like function in another package is not permitted");
    }
  }

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

  /* TODO: We should find a way to put this in the main ctx structure, but we
   * can't easily change that without breaking ABI compat.
   */
  PADOFFSET lexname_padix = 0;

  if(ctx.name && (ctx.actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL)) {
    SV *ampname = newSVpvf("&%" SVf, SVfARG(ctx.name));
    SAVEFREESV(ampname);
    lexname_padix = pad_add_name_sv(ampname, 0, NULL, NULL);
  }

  I32 floor_ix = start_subparse(FALSE, subparse_flags);
  SAVEFREESV(PL_compcv);

#ifdef HAVE_LEXICAL_SUB
  if(ctx.actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL)
    /* Lexical subs always have CVf_CLONE */
    CvCLONE_on(PL_compcv);
#endif

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
        if(hooks->filter_attr)
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

    if(require_parts & XS_PARSE_SUBLIKE_PART_SIGNATURE) {
#if HAVE_PERL_VERSION(5, 41, 8)
      SAVEFEATUREBITS();
      PL_compiling.cop_features.bits[FEATURE_SIGNATURES_INDEX] |= FEATURE_SIGNATURES_BIT;
#elif HAVE_PERL_VERSION(5, 32, 0)
      SAVEI32(PL_compiling.cop_features);
      PL_compiling.cop_features |= FEATURE_SIGNATURES_BIT;
#else
      /* So far this is only used by the "method" keyword hack for perl 5.38
       * onwards so this doesn't technically matter. Yet...
       */
      croak("TODO: import_pragma(\"feature\", \"signatures\")");
#endif
    }

    U32 flags = 0;
    bool have_sighooks = false;
    FOREACH_HOOKS_FORWARD {
      if(hooks->flags & XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS)
        flags |= PARSE_SUBSIGNATURE_NAMED_PARAMS;
      if(hooks->flags & XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES)
        flags |= PARSE_SUBSIGNATURE_PARAM_ATTRIBUTES;
      if(hooks->ver >= 7 && (hooks->start_signature || hooks->finish_signature))
        have_sighooks = true;
    }

    if(flags || have_sighooks)
      sigop = parse_subsignature_ex(flags, &ctx_with_ptr, hooksanddata, nhooks);
    else {
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
      if(ctx.name) {
        ctx.actions |= XS_PARSE_SUBLIKE_ACTION_SET_CVNAME;
        if(!(ctx.actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL))
          ctx.actions |= XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
      }
      else
        ctx.actions &= ~(XS_PARSE_SUBLIKE_ACTION_SET_CVNAME|XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL);
    }

    /* If we want both SET_CVNAME and INSTALL_SYMBOL actions we might as well
     * let newATTRSUB() do it. If we only wanted one we need to be more subtle
     */
    bool action_set_cvname      = ctx.actions & XS_PARSE_SUBLIKE_ACTION_SET_CVNAME;
    bool action_install_symbol  = ctx.actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
    bool action_install_lexical = ctx.actions & XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL;
    if(action_install_symbol && action_install_lexical)
      croak("Cannot both ACTION_INSTALL_SYMBOL and ACTION_INSTALL_LEXICAL");

    OP *nameop = NULL;
    if(ctx.name && action_set_cvname && action_install_symbol)
      nameop = newSVOP(OP_CONST, 0, SvREFCNT_inc(ctx.name));

    if(!nameop && action_install_symbol)
      warn("Setting XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL without _ACTION_SET_CVNAME is nonsensical");

    if(action_install_lexical) {
#ifdef HAVE_LEXICAL_SUB
      assert(lexname_padix);
      nameop = newOP(OP_PADANY, 0);
      nameop->op_targ = lexname_padix;

      ctx.cv = newMYSUB(floor_ix, nameop, NULL, ctx.attrs, ctx.body);
#else
      PERL_UNUSED_VAR(lexname_padix);
      croak("XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL is not supported on this version of Perl");
#endif
    }
    else
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
#undef ctx
}

static int IMPL_xs_parse_sublike_v6(pTHX_ const struct XSParseSublikeHooks *hooks, void *hookdata, OP **op_ptr)
{
  struct HooksAndData hd = { .hooks = hooks, .data = hookdata };
  return parse(aTHX_ &hd, 1, op_ptr);
}

struct Registration;
struct Registration {
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

static void register_sublike(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata, int ver)
{
  if(ver < 4)
    croak("Mismatch in sublike keyword registration ABI version field: module wants %u; we require >= 4\n",
      ver);
  if(ver > XSPARSESUBLIKE_ABI_VERSION)
    croak("Mismatch in sublike keyword registration ABI version field: module wants %u; we support <= %d\n",
      ver, XSPARSESUBLIKE_ABI_VERSION);

  struct Registration *reg;
  Newx(reg, 1, struct Registration);

  reg->kw = savepv(kw);
  reg->kwlen = strlen(kw);
  reg->hooks = hooks;
  reg->hookdata = hookdata;

  if(reg->hooks->permit_hintkey)
    reg->permit_hintkey_len = strlen(reg->hooks->permit_hintkey);
  else
    reg->permit_hintkey_len = 0;

  if(!reg->hooks->permit && !reg->hooks->permit_hintkey)
    croak("Third-party sublike keywords require a permit callback or hinthash key");

  REGISTRATIONS_LOCK;
  {
    reg->next = registrations;
    registrations = reg;
  }
  REGISTRATIONS_UNLOCK;
}

static void IMPL_register_xs_parse_sublike_v6(pTHX_ const char *kw, const struct XSParseSublikeHooks *hooks, void *hookdata)
{
  int ver = hooks->ver;
  if(!ver)
    /* Caller forgot to set .ver but for source-level compat we'll presume they
     * wanted version 6, the first ABI version that added the .ver field
     */
    ver = 6;

  register_sublike(aTHX_ kw, hooks, hookdata, ver);
}

static const struct Registration *find_permitted(pTHX_ const char *kw, STRLEN kwlen)
{
  const struct Registration *reg;

  HV *hints = GvHV(PL_hintgv);

  for(reg = registrations; reg; reg = reg->next) {
    if(reg->kwlen != kwlen || !strnEQ(reg->kw, kw, kwlen))
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

static int IMPL_xs_parse_sublike_any_v6(pTHX_ const struct XSParseSublikeHooks *hooksA, void *hookdataA, OP **op_ptr)
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
      croak("Expected a keyword to introduce a sub or sub-like construction, found " QUOTED_PVNf,
        QUOTED_PVNfARG(kw, kwlen));
  }

  SvREFCNT_dec(kwsv);

  struct HooksAndData hd[] = {
    { .hooks = hooksA, .data = hookdataA },
    { 0 }
  };

  if(reg) {
    hd[1].hooks = reg->hooks;
    hd[1].data  = reg->hookdata;
  }

  return parse(aTHX_ hd, 1 + !!reg, op_ptr);
}

static void IMPL_register_xps_signature_attribute(pTHX_ const char *name, const struct XPSSignatureAttributeFuncs *funcs, void *funcdata)
{
  if(funcs->ver < 5)
    croak("Mismatch in signature param attribute ABI version field: module wants %u; we require >= 5\n",
      funcs->ver);
  if(funcs->ver > XSPARSESUBLIKE_ABI_VERSION)
    croak("Mismatch in signature param attribute ABI version field: module wants %u; we support <= %d\n",
      funcs->ver, XSPARSESUBLIKE_ABI_VERSION);

  if(!name || !(name[0] >= 'A' && name[0] <= 'Z'))
    croak("Signature param attribute names must begin with a capital letter");

  if(!funcs->permit_hintkey)
    croak("Signature param attributes require a permit hinthash key");

  register_subsignature_attribute(name, funcs, funcdata);
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
  .ver           = XSPARSESUBLIKE_ABI_VERSION,
  .permit        = &permit_core_method,
  .pre_subparse  = &pre_subparse_core_method,
  .require_parts = XS_PARSE_SUBLIKE_PART_SIGNATURE, /* enable signatures feature */
};
#endif

#ifdef HAVE_LEXICAL_SUB
static void pre_subparse_lexical_sub(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata)
{
  ctx->actions &= ~XS_PARSE_SUBLIKE_ACTION_INSTALL_SYMBOL;
  ctx->actions |=  XS_PARSE_SUBLIKE_ACTION_INSTALL_LEXICAL;
}

static const struct XSParseSublikeHooks hooks_lexical_sub = {
  .ver = XSPARSESUBLIKE_ABI_VERSION,
  /* no permit needed */
  .pre_subparse = &pre_subparse_lexical_sub,
};
#endif

/* Sublike::Extended */

static struct XSParseSublikeHooks hooks_extended = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "Sublike::Extended/extended",
  .flags = XS_PARSE_SUBLIKE_FLAG_PREFIX|
    XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL|
    XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS|
    XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES,

  /* No hooks */
};

static struct XSParseSublikeHooks hooks_extended_sub = {
  .ver            = XSPARSESUBLIKE_ABI_VERSION,
  .permit_hintkey = "Sublike::Extended/extended-sub",
  .flags = XS_PARSE_SUBLIKE_FLAG_BODY_OPTIONAL|
    XS_PARSE_SUBLIKE_FLAG_SIGNATURE_NAMED_PARAMS|
    XS_PARSE_SUBLIKE_FLAG_SIGNATURE_PARAM_ATTRIBUTES,

  /* No hooks */
};

/* keyword plugin */

static int (*next_keyword_plugin)(pTHX_ char *, STRLEN, OP **);

static int my_keyword_plugin(pTHX_ char *kw, STRLEN kwlen, OP **op_ptr)
{
  char *orig_kw = kw;
  STRLEN orig_kwlen = kwlen;

#ifdef HAVE_LEXICAL_SUB
  char *was_parser_bufptr = PL_parser->bufptr;

  bool is_lexical_sub = false;

  if(kwlen == 2 && strEQ(kw, "my")) {
    lex_read_space(0);

    I32 c = lex_peek_unichar(0);
    if(!isIDFIRST_uni(c))
      goto next_keyword;

    kw = PL_parser->bufptr;

    lex_read_unichar(0);
    while((c = lex_peek_unichar(0)) && isALNUM_uni(c))
      lex_read_unichar(0);

    kwlen = PL_parser->bufptr - kw;

    is_lexical_sub = true;
  }
#endif

  const struct Registration *reg = find_permitted(aTHX_ kw, kwlen);

  if(!reg) {
#ifdef HAVE_LEXICAL_SUB
    if(PL_parser->bufptr > was_parser_bufptr)
      PL_parser->bufptr = was_parser_bufptr;
next_keyword:
#endif
    return (*next_keyword_plugin)(aTHX_ orig_kw, orig_kwlen, op_ptr);
  }

  lex_read_space(0);

  /* We'll abuse the SvPVX storage of an SV to keep an array of HooksAndData
   * structures
   */
  SV *hdlsv = newSV(4 * sizeof(struct HooksAndData));
  SAVEFREESV(hdlsv);
  struct HooksAndData *hd = (struct HooksAndData *)SvPVX(hdlsv);
  size_t nhooks = 0;

#ifdef HAVE_LEXICAL_SUB
  if(is_lexical_sub) {
    hd[nhooks].hooks = &hooks_lexical_sub;
    hd[nhooks].data  = NULL;
    nhooks++;
  }
#endif

  struct XSParseSublikeHooks *hooks = (struct XSParseSublikeHooks *)reg->hooks;

  hd[nhooks].hooks = hooks;
  hd[nhooks].data  = reg->hookdata;
  nhooks++;

  while(hooks->flags & XS_PARSE_SUBLIKE_FLAG_PREFIX) {
    /* After a prefixing keyword, expect another one */
    SV *kwsv = lex_scan_ident();
    SAVEFREESV(kwsv);

    if(!kwsv || !SvCUR(kwsv))
      croak("Expected a keyword to introduce a sub or sub-like construction");

    kw = SvPV_nolen(kwsv);
    kwlen = SvCUR(kwsv);

    lex_read_space(0);

    reg = find_permitted(aTHX_ kw, kwlen);

    /* We permit 'sub' as a NULL set of hooks; anything else should be a registered keyword */
    if(!reg && kwlen == 3 && strEQ(kw, "sub"))
      break;
    if(!reg)
      croak("Expected a keyword to introduce a sub or sub-like construction, found " QUOTED_PVNf,
        QUOTED_PVNfARG(kw, kwlen));

    hooks = (struct XSParseSublikeHooks *)reg->hooks;

    if(SvLEN(hdlsv) < (nhooks + 1) * sizeof(struct HooksAndData)) {
      SvGROW(hdlsv, SvLEN(hdlsv) * 2);
      hd = (struct HooksAndData *)SvPVX(hdlsv);
    }
    hd[nhooks].hooks = hooks;
    hd[nhooks].data  = reg->hookdata;
    nhooks++;
  }

  /* See if Sublike::Extended wants to claim this one. If it wanted 'sub' it
   * has already claimed that above */
  if(kwlen != 3 || !strEQ(kw, "sub")) {
    HV *hints = GvHV(PL_hintgv);
    SV *keysv = sv_2mortal(newSVpvf("Sublike::Extended/extended-%.*s", (int)kwlen, kw));
    if(hints && hv_exists_ent(hints, keysv, 0)) {
      if(SvLEN(hdlsv) < (nhooks + 1) * sizeof(struct HooksAndData)) {
        SvGROW(hdlsv, SvLEN(hdlsv) * 2);
        hd = (struct HooksAndData *)SvPVX(hdlsv);
      }
      /* This hook has the prefix flag set, but it doesn't matter because
       * we've finished processing those already
       */
      hd[nhooks].hooks = &hooks_extended;
      hd[nhooks].data  = NULL;
      nhooks++;
    }
  }

  return parse(aTHX_ hd, nhooks, op_ptr);
}

/* API v3 back-compat */

static int IMPL_xs_parse_sublike_v3(pTHX_ const void *hooks, void *hookdata, OP **op_ptr)
{
  croak("XS::Parse::Sublike ABI v3 is no longer supported; the caller should be rebuilt to use v4");
}

static void IMPL_register_xs_parse_sublike_v3(pTHX_ const char *kw, const void *hooks, void *hookdata)
{
  croak("XS::Parse::Sublike ABI v3 is no longer supported; the caller should be rebuilt to use v4");
}

static int IMPL_xs_parse_sublike_any_v3(pTHX_ const void *hooksA, void *hookdataA, OP **op_ptr)
{
  croak("XS::Parse::Sublike ABI v3 is no longer supported; the caller should be rebuilt to use v4");
}

/* API v4 back-compat */

struct XSParseSublikeHooks_v4 {
  U16  flags;
  U8   require_parts;
  U8   skip_parts;
  const char *permit_hintkey;
  bool (*permit)(pTHX_ void *hookdata);
  void (*pre_subparse)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_blockstart)(pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*pre_blockend)   (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  void (*post_newcv)     (pTHX_ struct XSParseSublikeContext *ctx, void *hookdata);
  bool (*filter_attr)    (pTHX_ struct XSParseSublikeContext *ctx, SV *attr, SV *val, void *hookdata);
};

#define STRUCT_XSPARSESUBLIKEHOOKS_FROM_v4(hooks_v4)     \
  (struct XSParseSublikeHooks){                          \
        .ver             = 4,                            \
        .flags           = hooks_v4->flags,              \
        .require_parts   = hooks_v4->require_parts,      \
        .skip_parts      = hooks_v4->skip_parts,         \
        .permit_hintkey  = hooks_v4->permit_hintkey,     \
        .permit          = hooks_v4->permit,             \
        .pre_subparse    = hooks_v4->pre_subparse,       \
        .filter_attr     = (hooks_v4->flags & XS_PARSE_SUBLIKE_FLAG_FILTERATTRS)  \
                             ? hooks_v4->filter_attr     \
                             : NULL,                     \
        .post_blockstart = hooks_v4->post_blockstart,    \
        .pre_blockend    = hooks_v4->pre_blockend,       \
        .post_newcv      = hooks_v4->post_newcv,         \
      }

static int IMPL_xs_parse_sublike_v4(pTHX_ const struct XSParseSublikeHooks_v4 *hooks_v4, void *hookdata, OP **op_ptr)
{
  return IMPL_xs_parse_sublike_v6(aTHX_
    &STRUCT_XSPARSESUBLIKEHOOKS_FROM_v4(hooks_v4),
    hookdata,
    op_ptr);
}

static void IMPL_register_xs_parse_sublike_v4(pTHX_ const char *kw, const struct XSParseSublikeHooks_v4 *hooks_v4, void *hookdata)
{
  struct XSParseSublikeHooks *hooks;
  Newx(hooks, 1, struct XSParseSublikeHooks);
  *hooks = STRUCT_XSPARSESUBLIKEHOOKS_FROM_v4(hooks_v4);

  register_sublike(aTHX_ kw, hooks, hookdata, 4);
}

static int IMPL_xs_parse_sublike_any_v4(pTHX_ const struct XSParseSublikeHooks_v4 *hooksA_v4, void *hookdataA, OP **op_ptr)
{
  return IMPL_xs_parse_sublike_any_v6(aTHX_
    &STRUCT_XSPARSESUBLIKEHOOKS_FROM_v4(hooksA_v4),
    hookdataA,
    op_ptr);
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
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parse()@6",    1), PTR2UV(&IMPL_xs_parse_sublike_v6));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register()@6", 1), PTR2UV(&IMPL_register_xs_parse_sublike_v6));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register()@4", 1), PTR2UV(&IMPL_register_xs_parse_sublike_v4));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parseany()@4", 1), PTR2UV(&IMPL_xs_parse_sublike_any_v4));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/parseany()@6", 1), PTR2UV(&IMPL_xs_parse_sublike_any_v6));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/signature_add_param()@7", 1), PTR2UV(&XPS_signature_add_param));
  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/signature_query()@8", 1),     PTR2UV(&XPS_signature_query));

  sv_setuv(*hv_fetchs(PL_modglobal, "XS::Parse::Sublike/register_sigattr()@5", 1), PTR2UV(&IMPL_register_xps_signature_attribute));
#ifdef HAVE_FEATURE_CLASS
  register_sublike(aTHX_ "method", &hooks_core_method, NULL, 4);
#endif

  wrap_keyword_plugin(&my_keyword_plugin, &next_keyword_plugin);

  register_sublike(aTHX_ "extended", &hooks_extended,     NULL, 4);
  register_sublike(aTHX_ "sub",      &hooks_extended_sub, NULL, 4);

  boot_parse_subsignature_ex();
