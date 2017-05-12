/* This file is part of the re::engine::Plugin Perl module.
 * See http://search.cpan.org/dist/re-engine-Plugin/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* --- Helpers ------------------------------------------------------------- */

#define XSH_PACKAGE "re::engine::Plugin"

#include "xsh/caps.h"
#include "xsh/util.h"

/* ... Lexical hints ....................................................... */

typedef struct {
 SV *comp;
 SV *exec;
 SV *free;
} xsh_hints_user_t;

static SV *rep_validate_callback(SV *code) {
 if (!SvROK(code))
  return NULL;

 code = SvRV(code);
 if (SvTYPE(code) < SVt_PVCV)
  return NULL;

 return SvREFCNT_inc_simple_NN(code);
}

static void xsh_hints_user_init(pTHX_ xsh_hints_user_t *hv, xsh_hints_user_t *v) {
 hv->comp = rep_validate_callback(v->comp);
 hv->exec = rep_validate_callback(v->exec);
 hv->free = rep_validate_callback(v->free);

 return;
}

#if XSH_THREADSAFE

static void xsh_hints_user_clone(pTHX_ xsh_hints_user_t *nv, xsh_hints_user_t *ov, CLONE_PARAMS *params) {
 nv->comp = xsh_dup_inc(ov->comp, params);
 nv->exec = xsh_dup_inc(ov->exec, params);
 nv->free = xsh_dup_inc(ov->free, params);

 return;
}

#endif /* XSH_THREADSAFE */

static void xsh_hints_user_deinit(pTHX_ xsh_hints_user_t *hv) {
 SvREFCNT_dec(hv->comp);
 SvREFCNT_dec(hv->exec);
 SvREFCNT_dec(hv->free);

 return;
}

#define rep_hint() xsh_hints_detag(xsh_hints_fetch())

#define XSH_HINTS_TYPE_USER         1
#define XSH_HINTS_ONLY_COMPILE_TIME 0

#include "xsh/hints.h"

/* ... Thread-local storage ................................................ */

#define XSH_THREADS_USER_CONTEXT            0
#define XSH_THREADS_USER_LOCAL_SETUP        0
#define XSH_THREADS_USER_LOCAL_TEARDOWN     0
#define XSH_THREADS_USER_GLOBAL_TEARDOWN    0
#define XSH_THREADS_COMPILE_TIME_PROTECTION 0

#include "xsh/threads.h"

/* --- Custom regexp engine ------------------------------------------------ */

/* re__engine__Plugin self; SELF_FROM_PPRIVATE(self,rx->pprivate) */
#define SELF_FROM_PPRIVATE(self, pprivate) \
 if (sv_isobject(pprivate)) {              \
  SV *ref = SvRV((SV *) pprivate);         \
  IV  tmp = SvIV((SV *) ref);              \
  self = INT2PTR(re__engine__Plugin, tmp); \
 } else {                                  \
  Perl_croak(aTHX_ "Not an object");       \
 }

#if XSH_HAS_PERL(5, 19, 4)
# define REP_ENG_EXEC_MINEND_TYPE SSize_t
#else
# define REP_ENG_EXEC_MINEND_TYPE I32
#endif

START_EXTERN_C
EXTERN_C const regexp_engine engine_plugin;
#if XSH_HAS_PERL(5, 11, 0)
EXTERN_C REGEXP * Plugin_comp(pTHX_ SV * const, U32);
#else
EXTERN_C REGEXP * Plugin_comp(pTHX_ const SV * const, const U32);
#endif
EXTERN_C I32      Plugin_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, REP_ENG_EXEC_MINEND_TYPE, SV *, void *, U32);
#if XSH_HAS_PERL(5, 19, 1)
EXTERN_C char *   Plugin_intuit(pTHX_ REGEXP * const, SV *, const char * const,
                                char *, char *, U32, re_scream_pos_data *);
#else
EXTERN_C char *   Plugin_intuit(pTHX_ REGEXP * const, SV *, char *,
                                char *, U32, re_scream_pos_data *);
#endif
EXTERN_C SV *     Plugin_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     Plugin_free(pTHX_ REGEXP * const);
EXTERN_C void *   Plugin_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
EXTERN_C void     Plugin_numbered_buff_FETCH(pTHX_ REGEXP * const,
                                             const I32, SV * const);
EXTERN_C void     Plugin_numbered_buff_STORE(pTHX_ REGEXP * const,
                                             const I32, SV const * const);
EXTERN_C I32      Plugin_numbered_buff_LENGTH(pTHX_ REGEXP * const,
                                              const SV * const, const I32);
EXTERN_C SV *     Plugin_named_buff(pTHX_ REGEXP * const, SV * const,
                                    SV * const, const U32);
EXTERN_C SV *     Plugin_named_buff_iter(pTHX_ REGEXP * const, const SV * const,
                                         const U32);
EXTERN_C SV *     Plugin_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   Plugin_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif

EXTERN_C const regexp_engine engine_plugin;
END_EXTERN_C

#define RE_ENGINE_PLUGIN (&engine_plugin)
const regexp_engine engine_plugin = {
 Plugin_comp,
 Plugin_exec,
 Plugin_intuit,
 Plugin_checkstr,
 Plugin_free,
 Plugin_numbered_buff_FETCH,
 Plugin_numbered_buff_STORE,
 Plugin_numbered_buff_LENGTH,
 Plugin_named_buff,
 Plugin_named_buff_iter,
 Plugin_package
#if defined(USE_ITHREADS)
 , Plugin_dupe
#endif
#if XSH_HAS_PERL(5, 17, 0)
 , 0
#endif
};

typedef struct replug {
 /* Pointer back to the containing regexp struct so that accessors
  * can modify nparens, gofs, etc... */
 struct regexp *rx;

 /* A copy of the pattern given to comp, for ->pattern */
 SV *pattern;

 /* A copy of the string being matched against, for ->str */
 SV *str;

 /* The ->stash */
 SV *stash;

 /* Callbacks */
 SV *cb_exec;
 SV *cb_free;

 /* ->num_captures */
 SV *cb_num_capture_buff_FETCH;
 SV *cb_num_capture_buff_STORE;
 SV *cb_num_capture_buff_LENGTH;
} *re__engine__Plugin;

#if XSH_HAS_PERL(5, 11, 0)
# define rxREGEXP(RX)  (SvANY(RX))
# define newREGEXP(RX) ((RX) = ((REGEXP *) newSV_type(SVt_REGEXP)))
#else
# define rxREGEXP(RX)  (RX)
# define newREGEXP(RX) (Newxz((RX), 1, struct regexp))
#endif

REGEXP *
#if XSH_HAS_PERL(5, 11, 0)
Plugin_comp(pTHX_ SV * const pattern, U32 flags)
#else
Plugin_comp(pTHX_ const SV * const pattern, const U32 flags)
#endif
{
 const xsh_hints_user_t *h;
 REGEXP            *RX;
 struct regexp     *rx;
 re__engine__Plugin re;
 char  *pbuf;
 STRLEN plen;
 SV    *obj;

 h = rep_hint();
 if (!h) /* This looks like a pragma leak. Apply the default behaviour */
  return re_compile(pattern, flags);

 /* exp/xend version of the pattern & length */
 pbuf = SvPV((SV *) pattern, plen);

 /* Our blessed object */
 obj = newSV(0);
 XSH_LOCAL_ALLOC(re, 1, struct replug);
 sv_setref_pv(obj, XSH_PACKAGE, (void *) re);

 newREGEXP(RX);
 rx = rxREGEXP(RX);

 re->rx       = rx;               /* Make the rx accessible from self->rx */
 rx->intflags = flags;            /* Flags for internal use */
 rx->extflags = flags;            /* Flags for perl to use */
 rx->engine   = RE_ENGINE_PLUGIN; /* Compile to use this engine */

#if !XSH_HAS_PERL(5, 11, 0)
 rx->refcnt   = 1;                /* Refcount so we won't be destroyed */

 /* Precompiled pattern for pp_regcomp to use */
 rx->prelen   = plen;
 rx->precomp  = savepvn(pbuf, rx->prelen);

 /* Set up qr// stringification to be equivalent to the supplied
  * pattern, this should be done via overload eventually */
 rx->wraplen  = rx->prelen;
 Newx(rx->wrapped, rx->wraplen, char);
 Copy(rx->precomp, rx->wrapped, rx->wraplen, char);
#endif

 /* Store our private object */
 rx->pprivate = obj;

 /* Store the pattern for ->pattern */
 re->pattern  = (SV *) pattern;
 SvREFCNT_inc_simple_void(re->pattern);

 re->str   = NULL;
 re->stash = NULL;

 /* Store the default exec callback (which may be NULL) into the regexp
  * object. */
 re->cb_exec = h->exec;
 SvREFCNT_inc_simple_void(h->exec);

 /* Same goes for the free callback. */
 re->cb_free = h->free;
 SvREFCNT_inc_simple_void(h->free);

 re->cb_num_capture_buff_FETCH  = NULL;
 re->cb_num_capture_buff_STORE  = NULL;
 re->cb_num_capture_buff_LENGTH = NULL;

 /* Call our callback function if one was defined, if not we've already set up
  * all the stuff we're going to to need for subsequent exec and other calls */
 if (h->comp) {
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(obj);
  PUTBACK;

  call_sv(h->comp, G_DISCARD);

  FREETMPS;
  LEAVE;
 }

 /* If any of the comp-time accessors were called we'll have to
  * update the regexp struct with the new info */
 Newxz(rx->offs, rx->nparens + 1, regexp_paren_pair);

 return RX;
}

I32
Plugin_exec(pTHX_ REGEXP * const RX, char *stringarg, char *strend,
            char *strbeg, REP_ENG_EXEC_MINEND_TYPE minend,
            SV *sv, void *data, U32 flags)
{
 struct regexp     *rx;
 re__engine__Plugin self;
 I32 matched;

 rx = rxREGEXP(RX);
 SELF_FROM_PPRIVATE(self, rx->pprivate);

 if (self->cb_exec) {
  SV *ret;
  dSP;

  /* Store the current str for ->str */
  SvREFCNT_dec(self->str);
  self->str = sv;
  SvREFCNT_inc_simple_void(self->str);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(rx->pprivate);
  XPUSHs(sv);
  PUTBACK;

  call_sv(self->cb_exec, G_SCALAR);

  SPAGAIN;

  ret = POPs;
  if (SvTRUE(ret))
   matched = 1;
  else
   matched = 0;

  PUTBACK;
  FREETMPS;
  LEAVE;
 } else {
  matched = 0;
 }

 return matched;
}

char *
#if XSH_HAS_PERL(5, 19, 1)
Plugin_intuit(pTHX_ REGEXP * const RX, SV *sv, const char * const strbeg,
              char *strpos, char *strend, U32 flags, re_scream_pos_data *data)
#else
Plugin_intuit(pTHX_ REGEXP * const RX, SV *sv, char *strpos,
              char *strend, U32 flags, re_scream_pos_data *data)
#endif
{
 PERL_UNUSED_ARG(RX);
 PERL_UNUSED_ARG(sv);
#if XSH_HAS_PERL(5, 19, 1)
 PERL_UNUSED_ARG(strbeg);
#endif
 PERL_UNUSED_ARG(strpos);
 PERL_UNUSED_ARG(strend);
 PERL_UNUSED_ARG(flags);
 PERL_UNUSED_ARG(data);

 return NULL;
}

SV *
Plugin_checkstr(pTHX_ REGEXP * const RX)
{
 PERL_UNUSED_ARG(RX);

 return NULL;
}

void
Plugin_free(pTHX_ REGEXP * const RX)
{
 struct regexp     *rx;
 re__engine__Plugin self;
 SV *callback;

 if (PL_dirty)
  return;

 rx = rxREGEXP(RX);
 SELF_FROM_PPRIVATE(self, rx->pprivate);

 callback = self->cb_free;

 if (callback) {
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(rx->pprivate);
  PUTBACK;

  call_sv(callback, G_DISCARD);

  PUTBACK;
  FREETMPS;
  LEAVE;
 }

 SvREFCNT_dec(self->pattern);
 SvREFCNT_dec(self->str);
 SvREFCNT_dec(self->stash);

 SvREFCNT_dec(self->cb_exec);

 SvREFCNT_dec(self->cb_num_capture_buff_FETCH);
 SvREFCNT_dec(self->cb_num_capture_buff_STORE);
 SvREFCNT_dec(self->cb_num_capture_buff_LENGTH);

 self->rx = NULL;

 XSH_LOCAL_FREE(self, 1, struct replug);

 SvREFCNT_dec(rx->pprivate);

 return;
}

void *
Plugin_dupe(pTHX_ REGEXP * const RX, CLONE_PARAMS *param)
{
 struct regexp *rx = rxREGEXP(RX);

 Perl_croak(aTHX_ "dupe not supported yet");

 return rx->pprivate;
}


void
Plugin_numbered_buff_FETCH(pTHX_ REGEXP * const RX, const I32 paren,
                           SV * const sv)
{
 struct regexp     *rx;
 re__engine__Plugin self;
 SV *callback;

 rx = rxREGEXP(RX);
 SELF_FROM_PPRIVATE(self, rx->pprivate);

 callback = self->cb_num_capture_buff_FETCH;

 if (callback) {
  I32 items;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(rx->pprivate);
  mXPUSHi(paren);
  PUTBACK;

  items = call_sv(callback, G_SCALAR);

  if (items == 1) {
   SV *ret;
   SPAGAIN;
   ret = POPs;
   sv_setsv(sv, ret);
  } else {
   sv_setsv(sv, &PL_sv_undef);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;
 } else {
  sv_setsv(sv, &PL_sv_undef);
 }
}

void
Plugin_numbered_buff_STORE(pTHX_ REGEXP * const RX, const I32 paren,
                           SV const * const value)
{
 struct regexp     *rx;
 re__engine__Plugin self;
 SV *callback;

 rx = rxREGEXP(RX);
 SELF_FROM_PPRIVATE(self, rx->pprivate);

 callback = self->cb_num_capture_buff_STORE;

 if (callback) {
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(rx->pprivate);
  mXPUSHi(paren);
  XPUSHs((SV *) value);
  PUTBACK;

  call_sv(callback, G_DISCARD);

  PUTBACK;
  FREETMPS;
  LEAVE;
 }
}

I32
Plugin_numbered_buff_LENGTH(pTHX_ REGEXP * const RX, const SV * const sv,
                            const I32 paren)
{
 struct regexp     *rx;
 re__engine__Plugin self;
 SV *callback;

 rx = rxREGEXP(RX);
 SELF_FROM_PPRIVATE(self, rx->pprivate);

 callback = self->cb_num_capture_buff_LENGTH;

 if (callback) {
  IV ret;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(rx->pprivate);
  mXPUSHi(paren);
  PUTBACK;

  call_sv(callback, G_SCALAR);

  SPAGAIN;

  ret = POPi;

  PUTBACK;
  FREETMPS;
  LEAVE;

  return (I32) ret;
 } else {
  /* TODO: call FETCH and get the length on that value */
  return 0;
 }
}

SV *
Plugin_named_buff(pTHX_ REGEXP * const RX, SV * const key, SV * const value,
                  const U32 flags)
{
 return NULL;
}

SV *
Plugin_named_buff_iter(pTHX_ REGEXP * const RX, const SV * const lastkey,
                       const U32 flags)
{
 return NULL;
}

SV *
Plugin_package(pTHX_ REGEXP * const RX)
{
 PERL_UNUSED_ARG(RX);

 return newSVpvs(XSH_PACKAGE);
}

static void xsh_user_global_setup(pTHX) {
 HV *stash;

 stash = gv_stashpvn(XSH_PACKAGE, XSH_PACKAGE_LEN, 1);
 newCONSTSUB(stash, "REP_THREADSAFE", newSVuv(XSH_THREADSAFE));
 newCONSTSUB(stash, "REP_FORKSAFE",   newSVuv(XSH_FORKSAFE));

 return;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = re::engine::Plugin       PACKAGE = re::engine::Plugin

PROTOTYPES: DISABLE

BOOT:
{
 xsh_setup();
}

#if XSH_THREADSAFE

void
CLONE(...)
PPCODE:
 xsh_clone();
 XSRETURN(0);

#endif /* XSH_THREADSAFE */

void
pattern(re::engine::Plugin self, ...)
PPCODE:
 XPUSHs(self->pattern);
 XSRETURN(1);

void
str(re::engine::Plugin self, ...)
PPCODE:
 XPUSHs(self->str);
 XSRETURN(1);

void
mod(re::engine::Plugin self)
PREINIT:
 U32 flags;
 char mods[5 + 1];
 int n = 0, i;
PPCODE:
 flags = self->rx->intflags;
 if (flags & PMf_FOLD)         /* /i */
  mods[n++] = 'i';
 if (flags & PMf_MULTILINE)    /* /m */
  mods[n++] = 'm';
 if (flags & PMf_SINGLELINE)   /* /s */
  mods[n++] = 's';
 if (flags & PMf_EXTENDED)     /* /x */
  mods[n++] = 'x';
 if (flags & RXf_PMf_KEEPCOPY) /* /p */
  mods[n++] = 'p';
 mods[n] = '\0';
 EXTEND(SP, 2 * n);
 for (i = 0; i < n; ++i) {
  mPUSHp(mods + i, 1);
  PUSHs(&PL_sv_yes);
 }
 XSRETURN(2 * n);

void
stash(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  SvREFCNT_dec(self->stash);
  self->stash = ST(1);
  SvREFCNT_inc_simple_void(self->stash);
  XSRETURN_EMPTY;
 } else {
  XPUSHs(self->stash);
  XSRETURN(1);
 }

void
minlen(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  self->rx->minlen = (I32)SvIV(ST(1));
  XSRETURN_EMPTY;
 } else if (self->rx->minlen) {
  mXPUSHi(self->rx->minlen);
  XSRETURN(1);
 } else {
  XSRETURN_UNDEF;
 }

void
gofs(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  self->rx->gofs = (U32)SvIV(ST(1));
  XSRETURN_EMPTY;
 } else if (self->rx->gofs) {
  mXPUSHu(self->rx->gofs);
  XSRETURN(1);
 } else {
  XSRETURN_UNDEF;
 }

void
nparens(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  self->rx->nparens = (U32)SvIV(ST(1));
  XSRETURN_EMPTY;
 } else if (self->rx->nparens) {
  mXPUSHu(self->rx->nparens);
  XSRETURN(1);
 } else {
  XSRETURN_UNDEF;
 }

void
_exec(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  SvREFCNT_dec(self->cb_exec);
  self->cb_exec = ST(1);
  SvREFCNT_inc_simple_void(self->cb_exec);
 }
 XSRETURN(0);

void
_free(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  SvREFCNT_dec(self->cb_free);
  self->cb_free = ST(1);
  SvREFCNT_inc_simple_void(self->cb_free);
 }
 XSRETURN(0);

void
_num_capture_buff_FETCH(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  SvREFCNT_dec(self->cb_num_capture_buff_FETCH);
  self->cb_num_capture_buff_FETCH = ST(1);
  SvREFCNT_inc_simple_void(self->cb_num_capture_buff_FETCH);
 }
 XSRETURN(0);

void
_num_capture_buff_STORE(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  SvREFCNT_dec(self->cb_num_capture_buff_STORE);
  self->cb_num_capture_buff_STORE = ST(1);
  SvREFCNT_inc_simple_void(self->cb_num_capture_buff_STORE);
 }
 XSRETURN(0);

void
_num_capture_buff_LENGTH(re::engine::Plugin self, ...)
PPCODE:
 if (items > 1) {
  SvREFCNT_dec(self->cb_num_capture_buff_LENGTH);
  self->cb_num_capture_buff_LENGTH = ST(1);
  SvREFCNT_inc_simple_void(self->cb_num_capture_buff_LENGTH);
 }
 XSRETURN(0);

SV *
_tag(SV *comp, SV *exec, SV *free)
PREINIT:
 xsh_hints_user_t arg;
CODE:
 arg.comp = comp;
 arg.exec = exec;
 arg.free = free;
 RETVAL = xsh_hints_tag(&arg);
OUTPUT:
 RETVAL

void
ENGINE()
PPCODE:
 mXPUSHi(PTR2IV(&engine_plugin));
 XSRETURN(1);
