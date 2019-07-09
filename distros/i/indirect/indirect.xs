/* This file is part of the indirect Perl module.
 * See http://search.cpan.org/dist/indirect/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* --- XS helpers ---------------------------------------------------------- */

#define XSH_PACKAGE "indirect"

#include "xsh/caps.h"
#include "xsh/util.h"
#include "xsh/mem.h"
#include "xsh/ops.h"

/* ... op => source position map ........................................... */

typedef struct {
 char   *buf;
 STRLEN  pos;
 STRLEN  size;
 STRLEN  len;
 line_t  line;
} indirect_op_info_t;

#define PTABLE_NAME        ptable
#define PTABLE_VAL_FREE(V) if (V) { indirect_op_info_t *oi = (V); XSH_LOCAL_FREE(oi->buf, oi->size, char); XSH_LOCAL_FREE(oi, 1, indirect_op_info_t); }
#define PTABLE_NEED_DELETE 1
#define PTABLE_NEED_WALK   0

#include "xsh/ptable.h"

/* XSH_LOCAL_FREE() always need aTHX */
#define ptable_store(T, K, V) ptable_store(aTHX_ (T), (K), (V))
#define ptable_delete(T, K)   ptable_delete(aTHX_ (T), (K))
#define ptable_clear(T)       ptable_clear(aTHX_ (T))
#define ptable_free(T)        ptable_free(aTHX_ (T))

/* ... Lexical hints ....................................................... */

#define XSH_HINTS_TYPE_SV 1

#include "xsh/hints.h"

/* ... Thread-local storage ................................................ */

typedef struct {
 ptable *map;
 SV     *global_code;
} xsh_user_cxt_t;

#define XSH_THREADS_USER_CONTEXT            1
#define XSH_THREADS_USER_CLONE_NEEDS_DUP    1
#define XSH_THREADS_COMPILE_TIME_PROTECTION 1

#if XSH_THREADSAFE

static void xsh_user_clone(pTHX_ const xsh_user_cxt_t *old_cxt, xsh_user_cxt_t *new_cxt, CLONE_PARAMS *params) {
 new_cxt->map         = ptable_new(32);
 new_cxt->global_code = xsh_dup_inc(old_cxt->global_code, params);

 return;
}

#endif /* XSH_THREADSAFE */

#include "xsh/threads.h"

/* ... Lexical hints, continued ............................................ */

static SV *indirect_hint(pTHX) {
#define indirect_hint() indirect_hint(aTHX)
 SV *hint;

#if XSH_HAS_PERL(5, 10, 0) || defined(PL_parser)
 if (!PL_parser)
  return NULL;
#endif

 hint = xsh_hints_fetch();
 if (hint && SvOK(hint)) {
  return xsh_hints_detag(hint);
 } else {
  dXSH_CXT;
  if (xsh_is_loaded(&XSH_CXT))
   return XSH_CXT.global_code;
  else
   return NULL;
 }
}

/* --- Compatibility wrappers ---------------------------------------------- */

#ifndef SvPV_const
# define SvPV_const SvPV
#endif

#ifndef SvPV_nolen_const
# define SvPV_nolen_const SvPV_nolen
#endif

#ifndef SvPVX_const
# define SvPVX_const SvPVX
#endif

#ifndef SvREFCNT_inc_simple_void_NN
# ifdef SvREFCNT_inc_simple_NN
#  define SvREFCNT_inc_simple_void_NN SvREFCNT_inc_simple_NN
# else
#  define SvREFCNT_inc_simple_void_NN SvREFCNT_inc
# endif
#endif

#ifndef sv_catpvn_nomg
# define sv_catpvn_nomg sv_catpvn
#endif

#ifndef mPUSHp
# define mPUSHp(P, L) PUSHs(sv_2mortal(newSVpvn((P), (L))))
#endif

#ifndef mPUSHu
# define mPUSHu(U) PUSHs(sv_2mortal(newSVuv(U)))
#endif

#ifndef HvNAME_get
# define HvNAME_get(H) HvNAME(H)
#endif

#ifndef HvNAMELEN_get
# define HvNAMELEN_get(H) strlen(HvNAME_get(H))
#endif

#if XSH_HAS_PERL(5, 10, 0) || defined(PL_parser)
# ifndef PL_linestr
#  define PL_linestr PL_parser->linestr
# endif
# ifndef PL_bufptr
#  define PL_bufptr PL_parser->bufptr
# endif
# ifndef PL_oldbufptr
#  define PL_oldbufptr PL_parser->oldbufptr
# endif
# ifndef PL_lex_inwhat
#  define PL_lex_inwhat PL_parser->lex_inwhat
# endif
# ifndef PL_multi_close
#  define PL_multi_close PL_parser->multi_close
# endif
#else
# ifndef PL_linestr
#  define PL_linestr PL_Ilinestr
# endif
# ifndef PL_bufptr
#  define PL_bufptr PL_Ibufptr
# endif
# ifndef PL_oldbufptr
#  define PL_oldbufptr PL_Ioldbufptr
# endif
# ifndef PL_lex_inwhat
#  define PL_lex_inwhat PL_Ilex_inwhat
# endif
# ifndef PL_multi_close
#  define PL_multi_close PL_Imulti_close
# endif
#endif

/* ... Safe version of call_sv() ........................................... */

static I32 indirect_call_sv(pTHX_ SV *sv, I32 flags) {
#define indirect_call_sv(S, F) indirect_call_sv(aTHX_ (S), (F))
 I32          ret, cxix;
 PERL_CONTEXT saved_cx;
 SV          *saved_errsv = NULL;

 if (SvTRUE(ERRSV)) {
  if (IN_PERL_COMPILETIME && PL_errors)
   sv_catsv(PL_errors, ERRSV);
  else
   saved_errsv = newSVsv(ERRSV);
  SvCUR_set(ERRSV, 0);
 }

 cxix     = (cxstack_ix < cxstack_max) ? (cxstack_ix + 1) : Perl_cxinc(aTHX);
 /* The last popped context will be reused by call_sv(), but our callers may
  * still need its previous value. Back it up so that it isn't clobbered. */
 saved_cx = cxstack[cxix];

 ret = call_sv(sv, flags | G_EVAL);

 cxstack[cxix] = saved_cx;

 if (SvTRUE(ERRSV)) {
  /* Discard the old ERRSV, and reuse the variable to temporarily store the
   * new one. */
  if (saved_errsv)
   sv_setsv(saved_errsv, ERRSV);
  else
   saved_errsv = newSVsv(ERRSV);
  SvCUR_set(ERRSV, 0);
  /* Immediately flush all errors. */
  if (IN_PERL_COMPILETIME) {
#if XSH_HAS_PERL(5, 10, 0) || defined(PL_parser)
   if (PL_parser)
    ++PL_parser->error_count;
#elif defined(PL_error_count)
   ++PL_error_count;
#else
   ++PL_Ierror_count;
#endif
   if (PL_errors) {
    sv_setsv(ERRSV, PL_errors);
    SvCUR_set(PL_errors, 0);
   }
  }
  sv_catsv(ERRSV, saved_errsv);
  SvREFCNT_dec(saved_errsv);
  croak(NULL);
 } else if (saved_errsv) {
  /* If IN_PERL_COMPILETIME && PL_errors, then the old ERRSV has already been
   * added to PL_errors. Otherwise, just restore it to ERRSV, as if no eval
   * block has ever been executed. */
  sv_setsv(ERRSV, saved_errsv);
  SvREFCNT_dec(saved_errsv);
 }

 return ret;
}

/* --- Check functions ----------------------------------------------------- */

/* ... op => source position map, continued ................................ */

static void indirect_map_store(pTHX_ const OP *o, STRLEN pos, SV *sv, line_t line) {
#define indirect_map_store(O, P, N, L) indirect_map_store(aTHX_ (O), (P), (N), (L))
 indirect_op_info_t *oi;
 const char *s;
 STRLEN len;
 dXSH_CXT;

 /* No need to check for XSH_CXT.map != NULL because this code path is always
  * guarded by indirect_hint(). */

 if (!(oi = ptable_fetch(XSH_CXT.map, o))) {
  XSH_LOCAL_ALLOC(oi, 1, indirect_op_info_t);
  ptable_store(XSH_CXT.map, o, oi);
  oi->buf  = NULL;
  oi->size = 0;
 }

 if (sv) {
  s = SvPV_const(sv, len);
 } else {
  s   = "{";
  len = 1;
 }

 if (len > oi->size) {
  XSH_LOCAL_REALLOC(oi->buf, oi->size, len, char);
  oi->size = len;
 }
 if (oi->buf)
  Copy(s, oi->buf, len, char);

 oi->len  = len;
 oi->pos  = pos;
 oi->line = line;
}

static const indirect_op_info_t *indirect_map_fetch(pTHX_ const OP *o) {
#define indirect_map_fetch(O) indirect_map_fetch(aTHX_ (O))
 dXSH_CXT;

 /* No need to check for XSH_CXT.map != NULL because this code path is always
  * guarded by indirect_hint(). */

 return ptable_fetch(XSH_CXT.map, o);
}

static void indirect_map_delete(pTHX_ const OP *o) {
#define indirect_map_delete(O) indirect_map_delete(aTHX_ (O))
 dXSH_CXT;

 if (xsh_is_loaded(&XSH_CXT) && XSH_CXT.map)
  ptable_delete(XSH_CXT.map, o);
}

/* ... Heuristics for finding a string in the source buffer ................ */

static int indirect_find(pTHX_ SV *name_sv, const char *line_bufptr, STRLEN *name_pos) {
#define indirect_find(NSV, LBP, NP) indirect_find(aTHX_ (NSV), (LBP), (NP))
 STRLEN      name_len, line_len;
 const char *name, *name_end;
 const char *line, *line_end;
 const char *p;

 line     = SvPV_const(PL_linestr, line_len);
 line_end = line + line_len;

 name = SvPV_const(name_sv, name_len);
 if (name_len >= 1 && *name == '$') {
  ++name;
  --name_len;
  while (line_bufptr < line_end && *line_bufptr != '$')
   ++line_bufptr;
  if (line_bufptr >= line_end)
   return 0;
 }
 name_end = name + name_len;

 p = line_bufptr;
 while (1) {
  p = ninstr(p, line_end, name, name_end);
  if (!p)
   return 0;
  if (!isALNUM(p[name_len]))
   break;
  /* p points to a word that has name as prefix, skip the rest of the word */
  p += name_len + 1;
  while (isALNUM(*p))
   ++p;
 }

 *name_pos = p - line;

 return 1;
}

/* ... ck_const ............................................................ */

static OP *(*indirect_old_ck_const)(pTHX_ OP *) = 0;

static OP *indirect_ck_const(pTHX_ OP *o) {
 o = indirect_old_ck_const(aTHX_ o);

 if (indirect_hint()) {
  SV *sv = cSVOPo_sv;

  if (SvPOK(sv) && (SvTYPE(sv) >= SVt_PV)) {
   STRLEN pos;
   const char *bufptr;

   bufptr = PL_multi_close == '<' ? PL_bufptr : PL_oldbufptr;

   if (indirect_find(sv, bufptr, &pos)) {
    STRLEN len;

    /* If the constant is equal to the current package name, try to look for
     * a "__PACKAGE__" coming before what we got. We only need to check this
     * when we already had a match because __PACKAGE__ can only appear in
     * direct method calls ("new __PACKAGE__" is a syntax error). */
    len = SvCUR(sv);
    if (PL_curstash
        && len == (STRLEN) HvNAMELEN_get(PL_curstash)
        && memcmp(SvPVX(sv), HvNAME_get(PL_curstash), len) == 0) {
     STRLEN pos_pkg;
     SV    *pkg = sv_newmortal();
     sv_setpvn(pkg, "__PACKAGE__", sizeof("__PACKAGE__")-1);

     if (indirect_find(pkg, PL_oldbufptr, &pos_pkg) && pos_pkg < pos) {
      sv  = pkg;
      pos = pos_pkg;
     }
    }

    indirect_map_store(o, pos, sv, CopLINE(&PL_compiling));
    return o;
   }
  }
 }

 indirect_map_delete(o);
 return o;
}

/* ... ck_rv2sv ............................................................ */

static OP *(*indirect_old_ck_rv2sv)(pTHX_ OP *) = 0;

static OP *indirect_ck_rv2sv(pTHX_ OP *o) {
 if (indirect_hint()) {
  OP *op = cUNOPo->op_first;
  SV *sv;
  const char *name = NULL;
  STRLEN pos, len;
  OPCODE type = (OPCODE) op->op_type;

  switch (type) {
   case OP_GV:
   case OP_GVSV: {
    GV *gv = cGVOPx_gv(op);
    name = GvNAME(gv);
    len  = GvNAMELEN(gv);
    break;
   }
   default:
    if ((PL_opargs[type] & OA_CLASS_MASK) == OA_SVOP) {
     SV *nsv = cSVOPx_sv(op);
     if (SvPOK(nsv) && (SvTYPE(nsv) >= SVt_PV))
      name = SvPV_const(nsv, len);
    }
  }
  if (!name)
   goto done;

  sv = sv_2mortal(newSVpvn("$", 1));
  sv_catpvn_nomg(sv, name, len);
  if (!indirect_find(sv, PL_oldbufptr, &pos)) {
   /* If it failed, retry without the current stash */
   const char *stash = HvNAME_get(PL_curstash);
   STRLEN stashlen = HvNAMELEN_get(PL_curstash);

   if ((len < stashlen + 2) || strnNE(name, stash, stashlen)
       || name[stashlen] != ':' || name[stashlen+1] != ':') {
    /* Failed again ? Try to remove main */
    stash = "main";
    stashlen = 4;
    if ((len < stashlen + 2) || strnNE(name, stash, stashlen)
        || name[stashlen] != ':' || name[stashlen+1] != ':')
     goto done;
   }

   sv_setpvn(sv, "$", 1);
   stashlen += 2;
   sv_catpvn_nomg(sv, name + stashlen, len - stashlen);
   if (!indirect_find(sv, PL_oldbufptr, &pos))
    goto done;
  }

  o = indirect_old_ck_rv2sv(aTHX_ o);

  indirect_map_store(o, pos, sv, CopLINE(&PL_compiling));
  return o;
 }

done:
 o = indirect_old_ck_rv2sv(aTHX_ o);

 indirect_map_delete(o);
 return o;
}

/* ... ck_padany ........................................................... */

static OP *(*indirect_old_ck_padany)(pTHX_ OP *) = 0;

static OP *indirect_ck_padany(pTHX_ OP *o) {
 o = indirect_old_ck_padany(aTHX_ o);

 if (indirect_hint()) {
  SV *sv;
  const char *s = PL_oldbufptr, *t = PL_bufptr - 1;

  while (s < t && isSPACE(*s)) ++s;
  if (*s == '$' && ++s <= t) {
   while (s < t && isSPACE(*s)) ++s;
   while (s < t && isSPACE(*t)) --t;
   sv = sv_2mortal(newSVpvn("$", 1));
   sv_catpvn_nomg(sv, s, t - s + 1);
   indirect_map_store(o, s - SvPVX_const(PL_linestr),
                         sv, CopLINE(&PL_compiling));
   return o;
  }
 }

 indirect_map_delete(o);
 return o;
}

/* ... ck_scope ............................................................ */

static OP *(*indirect_old_ck_scope)  (pTHX_ OP *) = 0;
static OP *(*indirect_old_ck_lineseq)(pTHX_ OP *) = 0;

static OP *indirect_ck_scope(pTHX_ OP *o) {
 OP *(*old_ck)(pTHX_ OP *) = 0;

 switch (o->op_type) {
  case OP_SCOPE:   old_ck = indirect_old_ck_scope;   break;
  case OP_LINESEQ: old_ck = indirect_old_ck_lineseq; break;
 }
 o = old_ck(aTHX_ o);

 if (indirect_hint()) {
  indirect_map_store(o, PL_oldbufptr - SvPVX_const(PL_linestr),
                        NULL, CopLINE(&PL_compiling));
  return o;
 }

 indirect_map_delete(o);
 return o;
}

/* We don't need to clean the map entries for leave ops because they can only
 * be created by mutating from a lineseq. */

/* ... ck_method ........................................................... */

static OP *(*indirect_old_ck_method)(pTHX_ OP *) = 0;

static OP *indirect_ck_method(pTHX_ OP *o) {
 if (indirect_hint()) {
  OP *op = cUNOPo->op_first;

  /* Indirect method call is only possible when the method is a bareword, so
   * don't trip up on $obj->$meth. */
  if (op && op->op_type == OP_CONST) {
   const indirect_op_info_t *oi = indirect_map_fetch(op);
   STRLEN pos;
   line_t line;
   SV *sv;

   if (!oi)
    goto done;

   sv   = sv_2mortal(newSVpvn(oi->buf, oi->len));
   pos  = oi->pos;
   /* Keep the old line so that we really point to the first line of the
    * expression. */
   line = oi->line;

   o = indirect_old_ck_method(aTHX_ o);
   /* o may now be a method_named */

   indirect_map_store(o, pos, sv, line);
   return o;
  }
 }

done:
 o = indirect_old_ck_method(aTHX_ o);

 indirect_map_delete(o);
 return o;
}

/* ... ck_method_named ..................................................... */

/* "use foo/no foo" compiles its call to import/unimport directly to a
 * method_named op. */

static OP *(*indirect_old_ck_method_named)(pTHX_ OP *) = 0;

static OP *indirect_ck_method_named(pTHX_ OP *o) {
 if (indirect_hint()) {
  STRLEN pos;
  line_t line;
  SV *sv;

  sv = cSVOPo_sv;
  if (!SvPOK(sv) || (SvTYPE(sv) < SVt_PV))
   goto done;
  sv = sv_mortalcopy(sv);

  if (!indirect_find(sv, PL_oldbufptr, &pos))
   goto done;
  line = CopLINE(&PL_compiling);

  o = indirect_old_ck_method_named(aTHX_ o);

  indirect_map_store(o, pos, sv, line);
  return o;
 }

done:
 o = indirect_old_ck_method_named(aTHX_ o);

 indirect_map_delete(o);
 return o;
}

/* ... ck_entersub ......................................................... */

static OP *(*indirect_old_ck_entersub)(pTHX_ OP *) = 0;

static OP *indirect_ck_entersub(pTHX_ OP *o) {
 SV *code = indirect_hint();

 o = indirect_old_ck_entersub(aTHX_ o);

 if (code) {
  const indirect_op_info_t *moi, *ooi;
  OP     *mop, *oop;
  LISTOP *lop;

  oop = o;
  do {
   lop = (LISTOP *) oop;
   if (!(lop->op_flags & OPf_KIDS))
    goto done;
   oop = lop->op_first;
  } while (oop->op_type != OP_PUSHMARK);
  oop = OpSIBLING(oop);
  mop = lop->op_last;

  if (!oop)
   goto done;

  switch (oop->op_type) {
   case OP_CONST:
   case OP_RV2SV:
   case OP_PADSV:
   case OP_SCOPE:
   case OP_LEAVE:
    break;
   default:
    goto done;
  }

  if (mop->op_type == OP_METHOD)
   mop = cUNOPx(mop)->op_first;
  else if (mop->op_type != OP_METHOD_NAMED)
   goto done;

  moi = indirect_map_fetch(mop);
  if (!moi)
   goto done;

  ooi = indirect_map_fetch(oop);
  if (!ooi)
   goto done;

  /* When positions are identical, the method and the object must have the
   * same name. But it also means that it is an indirect call, as "foo->foo"
   * results in different positions. */
  if (   moi->line < ooi->line
      || (moi->line == ooi->line && moi->pos <= ooi->pos)) {
   SV *file;
   dSP;

   ENTER;
   SAVETMPS;

#ifdef USE_ITHREADS
   file = sv_2mortal(newSVpv(CopFILE(&PL_compiling), 0));
#else
   file = sv_mortalcopy(CopFILESV(&PL_compiling));
#endif

   PUSHMARK(SP);
   EXTEND(SP, 4);
   mPUSHp(ooi->buf, ooi->len);
   mPUSHp(moi->buf, moi->len);
   PUSHs(file);
   mPUSHu(moi->line);
   PUTBACK;

   indirect_call_sv(code, G_VOID);

   PUTBACK;

   FREETMPS;
   LEAVE;
  }
 }

done:
 return o;
}

/* --- Module setup/teardown ----------------------------------------------- */

static void xsh_user_global_setup(pTHX) {
 xsh_ck_replace(OP_CONST,   indirect_ck_const,  &indirect_old_ck_const);
 xsh_ck_replace(OP_RV2SV,   indirect_ck_rv2sv,  &indirect_old_ck_rv2sv);
 xsh_ck_replace(OP_PADANY,  indirect_ck_padany, &indirect_old_ck_padany);
 xsh_ck_replace(OP_SCOPE,   indirect_ck_scope,  &indirect_old_ck_scope);
 xsh_ck_replace(OP_LINESEQ, indirect_ck_scope,  &indirect_old_ck_lineseq);

 xsh_ck_replace(OP_METHOD,       indirect_ck_method,
                                 &indirect_old_ck_method);
 xsh_ck_replace(OP_METHOD_NAMED, indirect_ck_method_named,
                                 &indirect_old_ck_method_named);
 xsh_ck_replace(OP_ENTERSUB,     indirect_ck_entersub,
                                 &indirect_old_ck_entersub);

 return;
}

static void xsh_user_local_setup(pTHX_ xsh_user_cxt_t *cxt) {
 HV *stash;

 stash = gv_stashpvn(XSH_PACKAGE, XSH_PACKAGE_LEN, 1);
 newCONSTSUB(stash, "I_THREADSAFE", newSVuv(XSH_THREADSAFE));
 newCONSTSUB(stash, "I_FORKSAFE",   newSVuv(XSH_FORKSAFE));

 cxt->map         = ptable_new(32);
 cxt->global_code = NULL;

 return;
}

static void xsh_user_local_teardown(pTHX_ xsh_user_cxt_t *cxt) {
 SvREFCNT_dec(cxt->global_code);
 cxt->global_code = NULL;

 ptable_free(cxt->map);
 cxt->map         = NULL;

 return;
}

static void xsh_user_global_teardown(pTHX) {
 xsh_ck_restore(OP_CONST,   &indirect_old_ck_const);
 xsh_ck_restore(OP_RV2SV,   &indirect_old_ck_rv2sv);
 xsh_ck_restore(OP_PADANY,  &indirect_old_ck_padany);
 xsh_ck_restore(OP_SCOPE,   &indirect_old_ck_scope);
 xsh_ck_restore(OP_LINESEQ, &indirect_old_ck_lineseq);

 xsh_ck_restore(OP_METHOD,       &indirect_old_ck_method);
 xsh_ck_restore(OP_METHOD_NAMED, &indirect_old_ck_method_named);
 xsh_ck_restore(OP_ENTERSUB,     &indirect_old_ck_entersub);

 return;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = indirect      PACKAGE = indirect

PROTOTYPES: ENABLE

BOOT:
{
 xsh_setup();
}

#if XSH_THREADSAFE

void
CLONE(...)
PROTOTYPE: DISABLE
PPCODE:
 xsh_clone();
 XSRETURN(0);

#endif /* XSH_THREADSAFE */

SV *
_tag(SV *code)
PROTOTYPE: $
CODE:
 if (!SvOK(code))
  code = NULL;
 else if (SvROK(code))
  code = SvRV(code);
 RETVAL = xsh_hints_tag(code);
OUTPUT:
 RETVAL

void
_global(SV *code)
PROTOTYPE: $
PPCODE:
 if (!SvOK(code))
  code = NULL;
 else if (SvROK(code))
  code = SvRV(code);
 {
  dXSH_CXT;
  SvREFCNT_dec(XSH_CXT.global_code);
  XSH_CXT.global_code = SvREFCNT_inc(code);
 }
 XSRETURN(0);
