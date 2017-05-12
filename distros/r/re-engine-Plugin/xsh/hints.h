#ifndef XSH_HINTS_H
#define XSH_HINTS_H 1

#include "caps.h" /* XSH_HAS_PERL(), XSH_THREADSAFE, tTHX */
#include "mem.h"  /* XSH_SHARED_*() */

#ifdef XSH_THREADS_H
# error threads.h must be loaded at the very end
#endif

#define XSH_HINTS_KEY     XSH_PACKAGE
#define XSH_HINTS_KEY_LEN (sizeof(XSH_HINTS_KEY)-1)

#ifndef XSH_WORKAROUND_REQUIRE_PROPAGATION
# define XSH_WORKAROUND_REQUIRE_PROPAGATION !XSH_HAS_PERL(5, 10, 1)
#endif

#ifndef XSH_HINTS_ONLY_COMPILE_TIME
# define XSH_HINTS_ONLY_COMPILE_TIME 1
#endif

#ifdef XSH_HINTS_TYPE_UV
# ifdef XSH_HINTS_TYPE_VAL
#  error hint type can only be set once
# endif
# undef  XSH_HINTS_TYPE_UV
# define XSH_HINTS_TYPE_UV         1
# define XSH_HINTS_TYPE_STRUCT     UV
# define XSH_HINTS_TYPE_COMPACT    UV
# define XSH_HINTS_NEED_STRUCT     0
# define XSH_HINTS_VAL_STRUCT_REF  0
# define XSH_HINTS_VAL_NONE        0
# define XSH_HINTS_VAL_PACK(T, V)  INT2PTR(T, (V))
# define XSH_HINTS_VAL_UNPACK(V)   ((XSH_HINTS_TYPE_VAL) PTR2UV(V))
# define XSH_HINTS_VAL_INIT(HV, V) ((HV) = (V))
# undef  XSH_HINTS_VAL_CLONE
# undef  XSH_HINTS_VAL_DEINIT
#endif

#ifdef XSH_HINTS_TYPE_SV
# ifdef XSH_HINTS_TYPE_VAL
#  error hint type can only be set once
# endif
# undef  XSH_HINTS_TYPE_SV
# define XSH_HINTS_TYPE_SV         1
# define XSH_HINTS_TYPE_STRUCT     SV *
# define XSH_HINTS_TYPE_COMPACT    SV
# define XSH_HINTS_NEED_STRUCT     0
# define XSH_HINTS_VAL_STRUCT_REF  0
# define XSH_HINTS_VAL_NONE        NULL
# define XSH_HINTS_VAL_PACK(T, V)  (V)
# define XSH_HINTS_VAL_UNPACK(V)   (V)
# define XSH_HINTS_VAL_INIT(HV, V) ((HV) = (((V) != XSH_HINTS_VAL_NONE) ? SvREFCNT_inc(V) : XSH_HINTS_VAL_NONE))
# define XSH_HINTS_VAL_CLONE(N, O) ((N) = xsh_dup_inc((O), ud->params))
# define XSH_HINTS_VAL_DEINIT(V)   SvREFCNT_dec(V)
#endif

#ifdef XSH_HINTS_TYPE_USER
# ifdef XSH_HINTS_TYPE_VAL
#  error hint type can only be set once
# endif
# undef  XSH_HINTS_TYPE_USER
# define XSH_HINTS_TYPE_USER         1
# define XSH_HINTS_TYPE_STRUCT       xsh_hints_user_t
# undef  XSH_HINTS_TYPE_COMPACT      /* not used */
# define XSH_HINTS_NEED_STRUCT       1
# define XSH_HINTS_VAL_STRUCT_REF    1
# define XSH_HINTS_VAL_NONE          NULL
# define XSH_HINTS_VAL_PACK(T, V)    (V)
# define XSH_HINTS_VAL_UNPACK(V)     (V)
# define XSH_HINTS_VAL_INIT(HV, V)   xsh_hints_user_init(aTHX_ (HV), (V))
# define XSH_HINTS_VAL_CLONE(NV, OV) xsh_hints_user_clone(aTHX_ (NV), (OV), ud->params)
# define XSH_HINTS_VAL_DEINIT(V)     xsh_hints_user_deinit(aTHX_ (V))
#endif

#ifndef XSH_HINTS_TYPE_STRUCT
# error hint type was not set
#endif

#if XSH_HINTS_VAL_STRUCT_REF
# define XSH_HINTS_TYPE_VAL XSH_HINTS_TYPE_STRUCT *
#else
# define XSH_HINTS_TYPE_VAL XSH_HINTS_TYPE_STRUCT
#endif

#if XSH_WORKAROUND_REQUIRE_PROPAGATION
# undef  XSH_HINTS_NEED_STRUCT
# define XSH_HINTS_NEED_STRUCT 1
#endif

#if XSH_THREADSAFE && (defined(XSH_HINTS_VAL_CLONE) || XSH_WORKAROUND_REQUIRE_PROPAGATION)
# define XSH_HINTS_NEED_CLONE 1
#else
# define XSH_HINTS_NEED_CLONE 0
#endif

#if XSH_WORKAROUND_REQUIRE_PROPAGATION

static UV xsh_require_tag(pTHX) {
#define xsh_require_tag() xsh_require_tag(aTHX)
 const CV *cv, *outside;

 cv = PL_compcv;

 if (!cv) {
  /* If for some reason the pragma is operational at run-time, try to discover
   * the current cv in use. */
  const PERL_SI *si;

  for (si = PL_curstackinfo; si; si = si->si_prev) {
   I32 cxix;

   for (cxix = si->si_cxix; cxix >= 0; --cxix) {
    const PERL_CONTEXT *cx = si->si_cxstack + cxix;

    switch (CxTYPE(cx)) {
     case CXt_SUB:
     case CXt_FORMAT:
      /* The propagation workaround is only needed up to 5.10.0 and at that
       * time format and sub contexts were still identical. And even later the
       * cv members offsets should have been kept the same. */
      cv = cx->blk_sub.cv;
      goto get_enclosing_cv;
     case CXt_EVAL:
      cv = cx->blk_eval.cv;
      goto get_enclosing_cv;
     default:
      break;
    }
   }
  }

  cv = PL_main_cv;
 }

get_enclosing_cv:
 for (outside = CvOUTSIDE(cv); outside; outside = CvOUTSIDE(cv))
  cv = outside;

 return PTR2UV(cv);
}

#endif /* XSH_WORKAROUND_REQUIRE_PROPAGATION */

#if XSH_HINTS_NEED_STRUCT

typedef struct {
 XSH_HINTS_TYPE_STRUCT val;
#if XSH_WORKAROUND_REQUIRE_PROPAGATION
 UV                    require_tag;
#endif
} xsh_hints_t;

#if XSH_HINTS_VAL_STRUCT_REF
# define XSH_HINTS_VAL_GET(H) (&(H)->val)
#else
# define XSH_HINTS_VAL_GET(H) ((H)->val)
#endif

#define XSH_HINTS_VAL_SET(H, V) XSH_HINTS_VAL_INIT(XSH_HINTS_VAL_GET(H), (V))

#ifdef XSH_HINTS_VAL_DEINIT
# define XSH_HINTS_FREE(H) \
   if (H) XSH_HINTS_VAL_DEINIT(XSH_HINTS_VAL_GET(((xsh_hints_t *) (H)))); \
   XSH_SHARED_FREE((H), 1, xsh_hints_t)
#else
# define XSH_HINTS_FREE(H) XSH_SHARED_FREE((H), 1, xsh_hints_t)
#endif

#else  /*  XSH_HINTS_NEED_STRUCT */

typedef XSH_HINTS_TYPE_COMPACT xsh_hints_t;

#define XSH_HINTS_VAL_GET(H)    XSH_HINTS_VAL_UNPACK(H)
#define XSH_HINTS_VAL_SET(H, V) STMT_START { XSH_HINTS_TYPE_VAL tmp; XSH_HINTS_VAL_INIT(tmp, (V)); (H) = XSH_HINTS_VAL_PACK(xsh_hints_t *, tmp); } STMT_END

#undef XSH_HINTS_FREE

#endif /* !XSH_HINTS_NEED_STRUCT */

/* ... Thread safety ....................................................... */

#if XSH_HINTS_NEED_CLONE

#ifdef XSH_HINTS_FREE
# define PTABLE_NAME        ptable_hints
# define PTABLE_VAL_FREE(V) XSH_HINTS_FREE(V)
#else
# define PTABLE_USE_DEFAULT 1
#endif

#define PTABLE_NEED_WALK    1
#define PTABLE_NEED_DELETE  0

#include "ptable.h"

#if PTABLE_WAS_DEFAULT
# define ptable_hints_store(T, K, V) ptable_default_store(aPTBL_ (T), (K), (V))
# define ptable_hints_free(T)        ptable_default_free(aPTBL_ (T))
#else
# define ptable_hints_store(T, K, V) ptable_hints_store(aPTBL_ (T), (K), (V))
# define ptable_hints_free(T)        ptable_hints_free(aPTBL_ (T))
#endif

#define XSH_THREADS_HINTS_CONTEXT 1

typedef struct {
 ptable *tbl; /* It really is a ptable_hints */
 tTHX    owner;
} xsh_hints_cxt_t;

static xsh_hints_cxt_t *xsh_hints_get_cxt(pTHX);

static void xsh_hints_local_setup(pTHX_ xsh_hints_cxt_t *cxt) {
 cxt->tbl   = ptable_new(4);
 cxt->owner = aTHX;
}

static void xsh_hints_local_teardown(pTHX_ xsh_hints_cxt_t *cxt) {
 ptable_hints_free(cxt->tbl);
 cxt->owner = NULL;
}

typedef struct {
 ptable       *tbl; /* It really is a ptable_hints */
 CLONE_PARAMS *params;
} xsh_ptable_clone_ud;

static void xsh_ptable_clone(pTHX_ ptable_ent *ent, void *ud_) {
 xsh_ptable_clone_ud *ud = ud_;
 xsh_hints_t         *h1 = ent->val;
 xsh_hints_t         *h2;

#if XSH_HINTS_NEED_STRUCT
 XSH_SHARED_ALLOC(h2, 1, xsh_hints_t);
# if XSH_WORKAROUND_REQUIRE_PROPAGATION
 h2->require_tag = PTR2UV(xsh_dup_inc(INT2PTR(SV *, h1->require_tag), ud->params));
# endif
#endif  /*  XSH_HINTS_NEED_STRUCT */

#ifdef XSH_HINTS_VAL_CLONE
 XSH_HINTS_VAL_CLONE(XSH_HINTS_VAL_GET(h2), XSH_HINTS_VAL_GET(h1));
#endif /* defined(XSH_HINTS_VAL_CLONE) */

 ptable_hints_store(ud->tbl, ent->key, h2);
}

static void xsh_hints_clone(pTHX_ const xsh_hints_cxt_t *old_cxt, xsh_hints_cxt_t *new_cxt, CLONE_PARAMS *params) {
 xsh_ptable_clone_ud ud;

 new_cxt->tbl   = ptable_new(4);
 new_cxt->owner = aTHX;

 ud.tbl    = new_cxt->tbl;
 ud.params = params;

 ptable_walk(old_cxt->tbl, xsh_ptable_clone, &ud);
}

#endif /* XSH_HINTS_NEED_CLONE */

/* ... tag hints ........................................................... */

static SV *xsh_hints_tag(pTHX_ XSH_HINTS_TYPE_VAL val) {
#define xsh_hints_tag(V) xsh_hints_tag(aTHX_ (V))
 xsh_hints_t *h;

 if (val == XSH_HINTS_VAL_NONE)
  return newSVuv(0);

#if XSH_HINTS_NEED_STRUCT
 XSH_SHARED_ALLOC(h, 1, xsh_hints_t);
# if XSH_WORKAROUND_REQUIRE_PROPAGATION
 h->require_tag = xsh_require_tag();
# endif
#endif /* XSH_HINTS_NEED_STRUCT */

 XSH_HINTS_VAL_SET(h, val);

#if XSH_HINTS_NEED_CLONE
 /* We only need for the key to be an unique tag for looking up the value later
  * Allocated memory provides convenient unique identifiers, so that's why we
  * use the hint as the key itself. */
 {
  xsh_hints_cxt_t *cxt = xsh_hints_get_cxt(aTHX);
  XSH_ASSERT(cxt->tbl);
  ptable_hints_store(cxt->tbl, h, h);
 }
#endif /* !XSH_HINTS_NEED_CLONE */

 return newSVuv(PTR2UV(h));
}

/* ... detag hints ......................................................... */

#define xsh_hints_2uv(H) \
    ((H) \
     ? (SvIOK(H) \
        ? SvUVX(H) \
        : (SvPOK(H) \
           ? sv_2uv(SvLEN(H) ? (H) : sv_mortalcopy(H)) \
           : 0 \
          ) \
       ) \
     : 0)

static XSH_HINTS_TYPE_VAL xsh_hints_detag(pTHX_ SV *hint) {
#define xsh_hints_detag(H) xsh_hints_detag(aTHX_ (H))
 xsh_hints_t *h;
 UV           hint_uv;

 hint_uv = xsh_hints_2uv(hint);
 h       = INT2PTR(xsh_hints_t *, hint_uv);
 if (!h)
  return XSH_HINTS_VAL_NONE;

#if XSH_HINTS_NEED_CLONE
 {
  xsh_hints_cxt_t *cxt = xsh_hints_get_cxt(aTHX);
  XSH_ASSERT(cxt->tbl);
  h = ptable_fetch(cxt->tbl, h);
 }
#endif /* XSH_HINTS_NEED_CLONE */

#if XSH_WORKAROUND_REQUIRE_PROPAGATION
 if (xsh_require_tag() != h->require_tag)
  return XSH_HINTS_VAL_NONE;
#endif

 return XSH_HINTS_VAL_GET(h);
}

/* ... fetch hints ......................................................... */

#if !defined(cop_hints_fetch_pvn) && XSH_HAS_PERL(5, 9, 5)
# define cop_hints_fetch_pvn(COP, PKG, PKGLEN, PKGHASH, FLAGS) \
   Perl_refcounted_he_fetch(aTHX_ (COP)->cop_hints_hash, NULL, \
                                  (PKG), (PKGLEN), (FLAGS), (PKGHASH))
#endif

#ifdef cop_hints_fetch_pvn

static U32 xsh_hints_key_hash = 0;
# define xsh_hints_global_setup(my_perl) \
         PERL_HASH(xsh_hints_key_hash, XSH_HINTS_KEY, XSH_HINTS_KEY_LEN)

#else /* defined(cop_hints_fetch_pvn) */

# define xsh_hints_global_setup(my_perl)

#endif /* !defined(cop_hints_fetch_pvn) */

#define xsh_hints_global_teardown(my_perl)

static SV *xsh_hints_fetch(pTHX) {
#define xsh_hints_fetch() xsh_hints_fetch(aTHX)
#if XSH_HINTS_ONLY_COMPILE_TIME
 if (IN_PERL_RUNTIME)
  return NULL;
#endif

#ifdef cop_hints_fetch_pvn
 return cop_hints_fetch_pvn(PL_curcop, XSH_HINTS_KEY, XSH_HINTS_KEY_LEN,
                                       xsh_hints_key_hash, 0);
#else
 {
  SV **val = hv_fetch(GvHV(PL_hintgv), XSH_HINTS_KEY, XSH_HINTS_KEY_LEN, 0);
  return val ? *val : NULL;
 }
#endif
}

#endif /* XSH_HINTS_H */
