/* This file is part of the re::engine::Hooks Perl module.
 * See http://search.cpan.org/dist/re-engine-Hooks/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define __PACKAGE__     "re::engine::Hooks"
#define __PACKAGE_LEN__ (sizeof(__PACKAGE__)-1)

/* --- Compatibility wrappers ---------------------------------------------- */

#define REH_HAS_PERL(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))

#ifndef SvPV_const
# define SvPV_const(S, L) SvPV(S, L)
#endif

/* ... Thread safety and multiplicity ...................................... */

#ifndef REH_MULTIPLICITY
# if defined(MULTIPLICITY) || defined(PERL_IMPLICIT_CONTEXT)
#  define REH_MULTIPLICITY 1
# else
#  define REH_MULTIPLICITY 0
# endif
#endif

#ifdef USE_ITHREADS
# define REH_LOCK(M)   MUTEX_LOCK(M)
# define REH_UNLOCK(M) MUTEX_UNLOCK(M)
#else
# define REH_LOCK(M)   NOOP
# define REH_UNLOCK(M) NOOP
#endif

/* --- Lexical hints ------------------------------------------------------- */

STATIC U32 reh_hash = 0;

STATIC SV *reh_hint(pTHX) {
#define reh_hint() reh_hint(aTHX)
 SV *hint;

#ifdef cop_hints_fetch_pvn
 hint = cop_hints_fetch_pvn(PL_curcop, __PACKAGE__, __PACKAGE_LEN__,
                                       reh_hash, 0);
#elif REH_HAS_PERL(5, 9, 5)
 hint = Perl_refcounted_he_fetch(aTHX_ PL_curcop->cop_hints_hash,
                                       NULL,
                                       __PACKAGE__, __PACKAGE_LEN__,
                                       0,
                                       reh_hash);
#else
 SV **val = hv_fetch(GvHV(PL_hintgv), __PACKAGE__, __PACKAGE_LEN__, 0);
 if (!val)
  return 0;
 hint = *val;
#endif

 return hint;
}

/* --- Public API ---------------------------------------------------------- */

#include "re_engine_hooks.h"

typedef struct reh_action {
 struct reh_action *next;
 reh_config         cbs;
 const char        *key;
 STRLEN             klen;
} reh_action;

STATIC reh_action *reh_action_list = 0;

#ifdef USE_ITHREADS

STATIC perl_mutex reh_action_list_mutex;

#endif /* USE_ITHREADS */

#undef reh_register
void reh_register(pTHX_ const char *key, reh_config *cfg) {
 reh_action *a;
 char       *key_dup;
 STRLEN      i, len;

 len = strlen(key);
 for (i = 0; i < len; ++i)
  if (!isALNUM(key[i]) && key[i] != ':')
   croak("Invalid key");
 key_dup = PerlMemShared_malloc(len + 1);
 memcpy(key_dup, key, len);
 key_dup[len] = '\0';

 a       = PerlMemShared_malloc(sizeof *a);
 a->cbs  = *cfg;
 a->key  = key_dup;
 a->klen = len;

 REH_LOCK(&reh_action_list_mutex);
 a->next         = reh_action_list;
 reh_action_list = a;
 REH_UNLOCK(&reh_action_list_mutex);

 return;
}

/* --- Custom regexp engine ------------------------------------------------ */

#if PERL_VERSION <= 10
# define rxREGEXP(RX)  (RX)
#else
# define rxREGEXP(RX)  (SvANY(RX))
#endif

#if PERL_VERSION <= 10
EXTERN_C REGEXP *reh_re_compile(pTHX_ const SV * const, const U32);
#else
EXTERN_C REGEXP *reh_re_compile(pTHX_ SV * const, U32);
#endif
EXTERN_C I32     reh_regexec_flags(pTHX_ REGEXP * const, char *, char *, char *, I32, SV *, void *, U32);
EXTERN_C char *  reh_re_intuit_start(pTHX_ REGEXP * const, SV *, char *, char *, U32, re_scream_pos_data *);
EXTERN_C SV *    reh_re_intuit_string(pTHX_ REGEXP * const);
EXTERN_C void    reh_re_free(pTHX_ REGEXP * const);
EXTERN_C void    reh_reg_numbered_buff_fetch(pTHX_ REGEXP * const,
                                                   const I32, SV * const);
EXTERN_C void    reh_reg_numbered_buff_store(pTHX_ REGEXP * const,
                                                   const I32, SV const * const);
EXTERN_C I32     reh_reg_numbered_buff_length(pTHX_ REGEXP * const,
                                                   const SV * const, const I32);
EXTERN_C SV *    reh_reg_named_buff(pTHX_ REGEXP * const, SV * const,
                                          SV * const, const U32);
EXTERN_C SV *    reh_reg_named_buff_iter(pTHX_ REGEXP * const,
                                               const SV * const, const U32);
EXTERN_C SV *    reh_reg_qr_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *  reh_re_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
#if REH_HAS_PERL(5, 17, 1)
EXTERN_C REGEXP *reh_re_op_compile(pTHX_ SV ** const, int, OP *, const regexp_engine*, REGEXP *VOL, bool *, U32, U32);
#endif

const struct regexp_engine reh_regexp_engine = {
 reh_re_compile,
 reh_regexec_flags,
 reh_re_intuit_start,
 reh_re_intuit_string,
 reh_re_free,
 reh_reg_numbered_buff_fetch,
 reh_reg_numbered_buff_store,
 reh_reg_numbered_buff_length,
 reh_reg_named_buff,
 reh_reg_named_buff_iter,
 reh_reg_qr_package
#if defined(USE_ITHREADS)
 , reh_re_dupe
#endif
#if REH_HAS_PERL(5, 17, 1)
 , reh_re_op_compile
#endif
};

/* --- Internal regexp structure -> hook list inside-out mapping ----------- */

typedef struct {
 size_t            count;
 const reh_config *cbs;
 U32               refcount;
} reh_private;

STATIC void reh_private_free(pTHX_ reh_private *priv) {
#define reh_private_free(P) reh_private_free(aTHX_ (P))
 if (priv->refcount <= 1) {
  PerlMemShared_free((void *) priv->cbs);
  PerlMemShared_free(priv);
 } else {
  --priv->refcount;
 }
}

#define PTABLE_NAME        ptable_private
#define PTABLE_VAL_FREE(V) reh_private_free(V)

#define pPTBL  pTHX
#define pPTBL_ pTHX_
#define aPTBL  aTHX
#define aPTBL_ aTHX_

#include "ptable.h"

#define ptable_private_store(T, K, V) ptable_private_store(aTHX_ (T), (K), (V))
#define ptable_private_delete(T, K)   ptable_private_delete(aTHX_ (T), (K))
#define ptable_private_clear(T)       ptable_private_clear(aTHX_ (T))
#define ptable_private_free(T)        ptable_private_free(aTHX_ (T))

STATIC ptable *reh_private_map;

#ifdef USE_ITHREADS

STATIC perl_mutex reh_private_map_mutex;

#endif /* USE_ITHREADS */

#define REH_PRIVATE_MAP_FOREACH(C) STMT_START {      \
 reh_private *priv;                                  \
 REH_LOCK(&reh_private_map_mutex);                   \
 priv = ptable_fetch(reh_private_map, rx->pprivate); \
 if (priv) {                                         \
  const reh_config *cbs = priv->cbs;                 \
  if (cbs) {                                         \
   const reh_config *end = cbs + priv->count;        \
   for (; cbs < end; ++cbs) {                        \
    (C);                                             \
   }                                                 \
  }                                                  \
 }                                                   \
 REH_UNLOCK(&reh_private_map_mutex);                 \
} STMT_END

STATIC void reh_private_map_store(pTHX_ void *ri, reh_private *priv) {
#define reh_private_map_store(R, P) reh_private_map_store(aTHX_ (R), (P))
 REH_LOCK(&reh_private_map_mutex);
 ptable_private_store(reh_private_map, ri, priv);
 REH_UNLOCK(&reh_private_map_mutex);

 return;
}

STATIC void reh_private_map_copy(pTHX_ void *ri_from, void *ri_to) {
#define reh_private_map_copy(F, T) reh_private_map_copy(aTHX_ (F), (T))
 reh_private *priv;

 REH_LOCK(&reh_private_map_mutex);
 priv = ptable_fetch(reh_private_map, ri_from);
 if (priv) {
  ++priv->refcount;
  ptable_private_store(reh_private_map, ri_to, priv);
 }
 REH_UNLOCK(&reh_private_map_mutex);
}

STATIC void reh_private_map_delete(pTHX_ void *ri) {
#define reh_private_map_delete(R) reh_private_map_delete(aTHX_ (R))
 REH_LOCK(&reh_private_map_mutex);
 ptable_private_delete(reh_private_map, ri);
 REH_UNLOCK(&reh_private_map_mutex);

 return;
}

/* --- Private API --------------------------------------------------------- */

void reh_call_comp_begin_hook(pTHX_ regexp *rx) {
 SV *hint = reh_hint();

 if (hint && SvPOK(hint)) {
  STRLEN      len;
  const char *keys  = SvPV_const(hint, len);
  size_t      count = 0;

  reh_private *priv;
  reh_config  *cbs = NULL;
  reh_action  *a, *root;

  REH_LOCK(&reh_action_list_mutex);
  root = reh_action_list;
  REH_UNLOCK(&reh_action_list_mutex);

  for (a = root; a; a = a->next) {
   char *p = strstr(keys, a->key);

   if (p && (p + a->klen <= keys + len) && p[a->klen] == ' ')
    ++count;
  }

  if (count) {
   size_t i = 0;

   cbs = PerlMemShared_malloc(count * sizeof *cbs);

   for (a = root; a; a = a->next) {
    char *p = strstr(keys, a->key);

    if (p && (p + a->klen <= keys + len) && p[a->klen] == ' ')
     cbs[i++] = a->cbs;
   }
  }

  priv = PerlMemShared_malloc(sizeof *priv);
  priv->count    = count;
  priv->cbs      = cbs;
  priv->refcount = 1;

  rx->engine = &reh_regexp_engine;

  reh_private_map_store(rx->pprivate, priv);
 }
}

void reh_call_comp_node_hook(pTHX_ regexp *rx, regnode *node) {
 REH_PRIVATE_MAP_FOREACH(cbs->comp_node(aTHX_ rx, node));
}

void reh_call_exec_node_hook(pTHX_ regexp *rx, regnode *node, regmatch_info *reginfo, regmatch_state *st) {
 REH_PRIVATE_MAP_FOREACH(cbs->exec_node(aTHX_ rx, node, reginfo, st));
}

EXTERN_C void reh_regfree_internal(pTHX_ REGEXP * const);

void reh_re_free(pTHX_ REGEXP * const RX) {
 regexp *rx = rxREGEXP(RX);

 reh_private_map_delete(rx->pprivate);

 reh_regfree_internal(aTHX_ RX);
}

#ifdef USE_ITHREADS

EXTERN_C void *reh_regdupe_internal(pTHX_ REGEXP * const, CLONE_PARAMS *);

void *reh_re_dupe(pTHX_ REGEXP * const RX, CLONE_PARAMS *param) {
 regexp *rx = rxREGEXP(RX);
 void   *new_ri;

 new_ri = reh_regdupe_internal(aTHX_ RX, param);

 reh_private_map_copy(rx->pprivate, new_ri);

 return new_ri;
}

#endif

STATIC void reh_teardown(pTHX_ void *root) {
#if REH_MULTIPLICITY
 if (aTHX != root)
  return;
#endif

 ptable_private_free(reh_private_map);
}

/* --- XS ------------------------------------------------------------------ */

MODULE = re::engine::Hooks          PACKAGE = re::engine::Hooks

PROTOTYPES: ENABLE

BOOT:
{
 reh_private_map = ptable_new();
#ifdef USE_ITHREADS
 MUTEX_INIT(&reh_action_list_mutex);
 MUTEX_INIT(&reh_private_map_mutex);
#endif
 PERL_HASH(reh_hash, __PACKAGE__, __PACKAGE_LEN__);
#if REH_MULTIPLICITY
 call_atexit(reh_teardown, aTHX);
#else
 call_atexit(reh_teardown, NULL);
#endif
}

void
_ENGINE()
PROTOTYPE:
PPCODE:
 XPUSHs(sv_2mortal(newSViv(PTR2IV(&reh_regexp_engine))));

void
_registered(SV *key)
PROTOTYPE: $
PREINIT:
 SV         *ret = NULL;
 reh_action *a;
 STRLEN      len;
 const char *s;
PPCODE:
 REH_LOCK(&reh_action_list_mutex);
 a = reh_action_list;
 REH_UNLOCK(&reh_action_list_mutex);
 s = SvPV_const(key, len);
 while (a && !ret) {
  if (a->klen == len && memcmp(a->key, s, len) == 0)
   ret = &PL_sv_yes;
  a = a->next;
 }
 if (!ret)
  ret = &PL_sv_no;
 EXTEND(SP, 1);
 PUSHs(ret);
 XSRETURN(1);
