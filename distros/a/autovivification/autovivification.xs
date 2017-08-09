/* This file is part of the autovivification Perl module.
 * See http://search.cpan.org/dist/autovivification/ */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* --- XS helpers ---------------------------------------------------------- */

#define XSH_PACKAGE "autovivification"

#include "xsh/caps.h"
#include "xsh/util.h"
#include "xsh/ops.h"
#include "xsh/peep.h"

/* ... Lexical hints ....................................................... */

/* Used both for hints and op flags */
#define A_HINT_STRICT 1
#define A_HINT_WARN   2
#define A_HINT_FETCH  4
#define A_HINT_STORE  8
#define A_HINT_KEYS   16
#define A_HINT_VALUES 32
#define A_HINT_EXISTS 64
#define A_HINT_DELETE 128
#define A_HINT_NOTIFY (A_HINT_STRICT|A_HINT_WARN)
#define A_HINT_DO     (A_HINT_FETCH|A_HINT_STORE|A_HINT_KEYS|A_HINT_VALUES|A_HINT_EXISTS|A_HINT_DELETE)
#define A_HINT_MASK   (A_HINT_NOTIFY|A_HINT_DO)

/* Only used in op flags */
#define A_HINT_ROOT   256
#define A_HINT_SECOND 512
#define A_HINT_DEREF  1024

#define XSH_HINTS_TYPE_UV 1

#include "xsh/hints.h"

#define a_hint() xsh_hints_detag(xsh_hints_fetch())

/* ... Thread-local storage ................................................ */

#define XSH_THREADS_COMPILE_TIME_PROTECTION 1
#define XSH_THREADS_USER_CONTEXT            0

#include "xsh/threads.h"

/* --- Compatibility wrappers ---------------------------------------------- */

#ifndef HvNAME_get
# define HvNAME_get(H) HvNAME(H)
#endif

#ifndef HvNAMELEN_get
# define HvNAMELEN_get(H) strlen(HvNAME_get(H))
#endif

#ifndef A_HAS_MULTIDEREF
# define A_HAS_MULTIDEREF XSH_HAS_PERL(5, 21, 7)
#endif

#ifndef A_HAS_SCALARKEYS_OPT
# define A_HAS_SCALARKEYS_OPT XSH_HAS_PERL(5, 27, 3)
#endif

/* ... Our vivify_ref() .................................................... */

/* Perl_vivify_ref() is not exported, so we have to reimplement it. */

#if A_HAS_MULTIDEREF

static SV *a_vivify_ref(pTHX_ SV *sv, int to_hash) {
#define a_vivify_ref(S, TH) a_vivify_ref(aTHX_ (S), (TH))
 SvGETMAGIC(sv);

 if (!SvOK(sv)) {
  SV *val;

  if (SvREADONLY(sv))
   Perl_croak_no_modify();

  /* Inlined prepare_SV_for_RV() */
  if (SvTYPE(sv) < SVt_PV && SvTYPE(sv) != SVt_IV) {
   sv_upgrade(sv, SVt_IV);
  } else if (SvTYPE(sv) >= SVt_PV) {
   SvPV_free(sv);
   SvLEN_set(sv, 0);
   SvCUR_set(sv, 0);
  }

  val = to_hash ? MUTABLE_SV(newHV()) : MUTABLE_SV(newAV());
  SvRV_set(sv, val);
  SvROK_on(sv);
  SvSETMAGIC(sv);
  SvGETMAGIC(sv);
 }

 if (SvGMAGICAL(sv)) {
  SV *msv = sv_newmortal();
  sv_setsv_nomg(msv, sv);
  return msv;
 }

 return sv;
}

#endif /* A_HAS_MULTIDEREF */

/* --- op => info map ------------------------------------------------------ */

typedef struct {
 OP   *(*old_pp)(pTHX);
 void   *next;
 UV      flags;
} a_op_info;

#define PTABLE_NAME             ptable_map
#define PTABLE_VAL_FREE(V)      XSH_SHARED_FREE((V), 1, a_op_info)
#define PTABLE_VAL_NEED_CONTEXT 0
#define PTABLE_NEED_DELETE      1
#define PTABLE_NEED_WALK        0

#include "xsh/ptable.h"

#define ptable_map_store(T, K, V) ptable_map_store(aPMS_ (T), (K), (V))
#define ptable_map_delete(T, K)   ptable_map_delete(aPMS_ (T), (K))
#define ptable_map_free(T)        ptable_map_free(aPMS_ (T))

static ptable *a_op_map = NULL;

#ifdef USE_ITHREADS

#define dA_MAP_THX a_op_info a_op_map_tmp_oi

static perl_mutex a_op_map_mutex;

static const a_op_info *a_map_fetch(const OP *o, a_op_info *oi) {
 const a_op_info *val;

 XSH_LOCK(&a_op_map_mutex);

 val = ptable_fetch(a_op_map, o);
 if (val) {
  *oi = *val;
  val = oi;
 }

 XSH_UNLOCK(&a_op_map_mutex);

 return val;
}

#define a_map_fetch(O) a_map_fetch((O), &a_op_map_tmp_oi)

#else /* USE_ITHREADS */

#define dA_MAP_THX dNOOP

#define a_map_fetch(O) ptable_fetch(a_op_map, (O))

#endif /* !USE_ITHREADS */

static const a_op_info *a_map_store_locked(pPMS_ const OP *o, OP *(*old_pp)(pTHX), void *next, UV flags) {
#define a_map_store_locked(O, PP, N, F) a_map_store_locked(aPMS_ (O), (PP), (N), (F))
 a_op_info *oi;

 if (!(oi = ptable_fetch(a_op_map, o))) {
  XSH_SHARED_ALLOC(oi, 1, a_op_info);
  ptable_map_store(a_op_map, o, oi);
 }

 oi->old_pp = old_pp;
 oi->next   = next;
 oi->flags  = flags;

 return oi;
}

static void a_map_store(pTHX_ const OP *o, OP *(*old_pp)(pTHX), void *next, UV flags) {
#define a_map_store(O, PP, N, F) a_map_store(aTHX_ (O), (PP), (N), (F))
 XSH_LOCK(&a_op_map_mutex);

 a_map_store_locked(o, old_pp, next, flags);

 XSH_UNLOCK(&a_op_map_mutex);
}

static void a_map_delete(pTHX_ const OP *o) {
#define a_map_delete(O) a_map_delete(aTHX_ (O))
 XSH_LOCK(&a_op_map_mutex);

 ptable_map_delete(a_op_map, o);

 XSH_UNLOCK(&a_op_map_mutex);
}

static const OP *a_map_descend(const OP *o) {
 switch (PL_opargs[o->op_type] & OA_CLASS_MASK) {
  case OA_BASEOP:
  case OA_UNOP:
  case OA_BINOP:
  case OA_BASEOP_OR_UNOP:
   return cUNOPo->op_first;
  case OA_LIST:
  case OA_LISTOP:
   return cLISTOPo->op_last;
 }

 return NULL;
}

static void a_map_store_root(pTHX_ const OP *root, OP *(*old_pp)(pTHX), UV flags) {
#define a_map_store_root(R, PP, F) a_map_store_root(aTHX_ (R), (PP), (F))
 const a_op_info *roi;
 a_op_info *oi;
 const OP *o = root;

 XSH_LOCK(&a_op_map_mutex);

 roi = a_map_store_locked(o, old_pp, (OP *) root, flags | A_HINT_ROOT);

 while (o->op_flags & OPf_KIDS) {
  o = a_map_descend(o);
  if (!o)
   break;
  if ((oi = ptable_fetch(a_op_map, o))) {
   oi->flags &= ~A_HINT_ROOT;
   oi->next   = (a_op_info *) roi;
   break;
  }
 }

 XSH_UNLOCK(&a_op_map_mutex);

 return;
}

static void a_map_update_flags_topdown(const OP *root, UV mask, UV flags) {
 a_op_info *oi;
 const OP *o = root;

 XSH_LOCK(&a_op_map_mutex);

 mask  |= A_HINT_ROOT;
 flags &= ~mask;

 do {
  if ((oi = ptable_fetch(a_op_map, o)))
   oi->flags = (oi->flags & mask) | flags;
  if (!(o->op_flags & OPf_KIDS))
   break;
  o = a_map_descend(o);
 } while (o);

 XSH_UNLOCK(&a_op_map_mutex);

 return;
}

static void a_map_update_flags_bottomup(const OP *o, UV flags, UV rflags) {
 a_op_info *oi;

 XSH_LOCK(&a_op_map_mutex);

 flags  &= ~A_HINT_ROOT;
 rflags |=  A_HINT_ROOT;

 oi = ptable_fetch(a_op_map, o);
 while (!(oi->flags & A_HINT_ROOT)) {
  oi->flags = flags;
  oi        = oi->next;
 }
 oi->flags = rflags;

 XSH_UNLOCK(&a_op_map_mutex);

 return;
}

/* ... Decide whether this expression should be autovivified or not ........ */

static UV a_map_resolve(const OP *o, const a_op_info *oi) {
 UV flags = 0, rflags;
 const OP *root;
 const a_op_info *roi = oi;

 while (!(roi->flags & A_HINT_ROOT))
  roi = roi->next;
 if (!roi)
  goto cancel;

 rflags = roi->flags & ~A_HINT_ROOT;
 if (!rflags)
  goto cancel;

 root = roi->next;
 if (root->op_flags & OPf_MOD) {
  if (rflags & A_HINT_STORE)
   flags = (A_HINT_STORE|A_HINT_DEREF);
 } else {
  if (rflags & (A_HINT_FETCH|A_HINT_KEYS|A_HINT_VALUES))
   flags = (rflags|A_HINT_DEREF);
 }

 if (!flags) {
cancel:
  a_map_update_flags_bottomup(o, 0, 0);
  return 0;
 }

 flags |= (rflags & A_HINT_NOTIFY);
 a_map_update_flags_bottomup(o, flags, 0);

 return oi->flags & A_HINT_ROOT ? 0 : flags;
}

/* ... Inspired from pp_defined() .......................................... */

static int a_undef(pTHX_ SV *sv) {
#define a_undef(S) a_undef(aTHX_ (S))
 switch (SvTYPE(sv)) {
  case SVt_NULL:
   return 1;
  case SVt_PVAV:
   if (AvMAX(sv) >= 0 || SvGMAGICAL(sv)
                      || (SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_tied)))
    return 0;
   break;
  case SVt_PVHV:
   if (HvARRAY(sv) || SvGMAGICAL(sv)
                   || (SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_tied)))
    return 0;
   break;
  default:
   SvGETMAGIC(sv);
   if (SvOK(sv))
    return 0;
 }

 return 1;
}

/* --- PP functions -------------------------------------------------------- */

/* Be aware that we restore PL_op->op_ppaddr from the pointer table old_pp
 * value, another extension might have saved our pp replacement as the ppaddr
 * for this op, so this doesn't ensure that our function will never be called
 * again. That's why we don't remove the op info from our map, so that it can
 * still run correctly if required. */

/* ... pp_rv2av ............................................................ */

static OP *a_pp_rv2av(pTHX) {
 dA_MAP_THX;
 const a_op_info *oi;
 dSP;

 oi = a_map_fetch(PL_op);

 if (oi->flags & A_HINT_DEREF) {
  if (a_undef(TOPs)) {
   /* We always need to push an empty array to fool the pp_aelem() that comes
    * later. */
   SV *av;
   (void) POPs;
   av = sv_2mortal((SV *) newAV());
   PUSHs(av);
   RETURN;
  }
 }

 return oi->old_pp(aTHX);
}

/* ... pp_rv2hv ............................................................ */

static OP *a_pp_rv2hv_simple(pTHX) {
 dA_MAP_THX;
 const a_op_info *oi;
 dSP;

 oi = a_map_fetch(PL_op);

 if (oi->flags & A_HINT_DEREF) {
  if (a_undef(TOPs))
   RETURN;
 }

 return oi->old_pp(aTHX);
}

static OP *a_pp_rv2hv(pTHX) {
 dA_MAP_THX;
 const a_op_info *oi;
 dSP;

 oi = a_map_fetch(PL_op);

 if (oi->flags & A_HINT_DEREF) {
  if (a_undef(TOPs)) {
   SV *hv;
   (void) POPs;
   hv = sv_2mortal((SV *) newHV());
   PUSHs(hv);
   RETURN;
  }
 }

 return oi->old_pp(aTHX);
}

#if A_HAS_SCALARKEYS_OPT

static OP *a_pp_rv2hv_dokeys(pTHX) {
 dA_MAP_THX;
 const a_op_info *oi;
 dSP;

 oi = a_map_fetch(PL_op);

 if (oi->flags & A_HINT_KEYS) {
  if (a_undef(TOPs)) {
   dTARGET;
   (void) POPs;
   PUSHi(0);
   RETURN;
  }
 }

 return oi->old_pp(aTHX);
}

#endif

/* ... pp_deref (aelem,helem,rv2sv,padsv) .................................. */

static void a_cannot_vivify(pTHX_ UV flags) {
#define a_cannot_vivify(F) a_cannot_vivify(aTHX_ (F))
 if (flags & A_HINT_STRICT)
  croak("Reference vivification forbidden");
 else if (flags & A_HINT_WARN)
  warn("Reference was vivified");
 else /* A_HINT_STORE */
  croak("Can't vivify reference");
}

static OP *a_pp_deref(pTHX) {
 dA_MAP_THX;
 const a_op_info *oi;
 UV flags;
 dSP;

 oi = a_map_fetch(PL_op);

 flags = oi->flags;
 if (flags & A_HINT_DEREF) {
  OP *o;

  o = oi->old_pp(aTHX);

  if (flags & (A_HINT_NOTIFY|A_HINT_STORE)) {
   SPAGAIN;
   if (a_undef(TOPs))
    a_cannot_vivify(flags);
  }

  return o;
 }

 return oi->old_pp(aTHX);
}

/* ... pp_root (exists,delete,keys,values) ................................. */

static OP *a_pp_root_unop(pTHX) {
 dSP;

 if (a_undef(TOPs)) {
  (void) POPs;
  /* Can only be reached by keys or values */
  if (GIMME_V == G_SCALAR) {
   dTARGET;
   PUSHi(0);
  }
  RETURN;
 }

 {
  dA_MAP_THX;
  const a_op_info *oi = a_map_fetch(PL_op);
  return oi->old_pp(aTHX);
 }
}

static OP *a_pp_root_binop(pTHX) {
 dSP;

 if (a_undef(TOPm1s)) {
  (void) POPs;
  (void) POPs;
  if (PL_op->op_type == OP_EXISTS)
   RETPUSHNO;
  else
   RETPUSHUNDEF;
 }

 {
  dA_MAP_THX;
  const a_op_info *oi = a_map_fetch(PL_op);
  return oi->old_pp(aTHX);
 }
}

#if A_HAS_MULTIDEREF

/* ... pp_multideref ....................................................... */

/* This pp replacement is actually only called for topmost exists/delete ops,
 * because we hijack the [ah]elem check functions and this disables the
 * optimization for lvalue and rvalue dereferencing. In particular, the
 * OPf_MOD branches should never be covered. In the future, the multideref
 * optimization might also be disabled for custom exists/delete check functions,
 * which will make this section unnecessary. However, the code tries to be as
 * general as possible in case I think of a way to reenable the multideref
 * optimization even when this module is in use. */

static UV a_do_multideref(const OP *o, UV flags) {
 UV isexdel, other_flags;

 XSH_ASSERT(o->op_type == OP_MULTIDEREF);

 other_flags = flags & ~A_HINT_DO;

 isexdel = o->op_private & (OPpMULTIDEREF_EXISTS|OPpMULTIDEREF_DELETE);
 if (isexdel) {
  if (isexdel & OPpMULTIDEREF_EXISTS) {
   flags &= A_HINT_EXISTS;
  } else {
   flags &= A_HINT_DELETE;
  }
 } else {
  if (o->op_flags & OPf_MOD) {
   flags &= A_HINT_STORE;
  } else {
   flags &= A_HINT_FETCH;
  }
 }

 return flags ? (flags | other_flags) : 0;
}

static SV *a_do_fake_pp(pTHX_ OP *op) {
#define a_do_fake_pp(O) a_do_fake_pp(aTHX_ (O))
 {
  OP *o = PL_op;
  ENTER;
  SAVEOP();
  PL_op = op;
  PL_op->op_ppaddr(aTHX);
  PL_op = o;
  LEAVE;
 }

 {
  SV *ret;
  dSP;
  ret = POPs;
  PUTBACK;
  return ret;
 }
}

static void a_do_fake_pp_unop_init(pTHX_ UNOP *unop, U32 type, U32 flags) {
#define a_do_fake_pp_unop_init(O, T, F) a_do_fake_pp_unop_init(aTHX_ (O), (T), (F))
 unop->op_type    = type;
 unop->op_flags   = OPf_WANT_SCALAR | (~OPf_WANT & flags);
 unop->op_private = 0;
 unop->op_first   = NULL;
 unop->op_ppaddr  = PL_ppaddr[type];
}

static SV *a_do_fake_pp_unop_arg1(pTHX_ U32 type, U32 flags, SV *arg) {
#define a_do_fake_pp_unop_arg1(T, F, A) a_do_fake_pp_unop_arg1(aTHX_ (T), (F), (A))
 UNOP unop;
 dSP;

 a_do_fake_pp_unop_init(&unop, type, flags);

 EXTEND(SP, 1);
 PUSHs(arg);
 PUTBACK;

 return a_do_fake_pp((OP *) &unop);
}

static SV *a_do_fake_pp_unop_arg2(pTHX_ U32 type, U32 flags, SV *arg1, SV *arg2) {
#define a_do_fake_pp_unop_arg2(T, F, A1, A2) a_do_fake_pp_unop_arg2(aTHX_ (T), (F), (A1), (A2))
 UNOP unop;
 dSP;

 a_do_fake_pp_unop_init(&unop, type, flags);

 EXTEND(SP, 2);
 PUSHs(arg1);
 PUSHs(arg2);
 PUTBACK;

 return a_do_fake_pp((OP *) &unop);
}

#define a_do_pp_rv2av(R)        a_do_fake_pp_unop_arg1(OP_RV2AV,  OPf_REF,     (R))
#define a_do_pp_afetch(A, I)    a_do_fake_pp_unop_arg2(OP_AELEM,  0,           (A), (I))
#define a_do_pp_afetch_lv(A, I) a_do_fake_pp_unop_arg2(OP_AELEM,  OPf_MOD,     (A), (I))
#define a_do_pp_aexists(A, I)   a_do_fake_pp_unop_arg2(OP_EXISTS, OPf_SPECIAL, (A), (I))
#define a_do_pp_adelete(A, I)   a_do_fake_pp_unop_arg2(OP_DELETE, OPf_SPECIAL, (A), (I))

#define a_do_pp_rv2hv(R)        a_do_fake_pp_unop_arg1(OP_RV2HV,  OPf_REF, (R))
#define a_do_pp_hfetch(H, K)    a_do_fake_pp_unop_arg2(OP_HELEM,  0,       (H), (K))
#define a_do_pp_hfetch_lv(H, K) a_do_fake_pp_unop_arg2(OP_HELEM,  OPf_MOD, (H), (K))
#define a_do_pp_hexists(H, K)   a_do_fake_pp_unop_arg2(OP_EXISTS, 0,  (H), (K))
#define a_do_pp_hdelete(H, K)   a_do_fake_pp_unop_arg2(OP_DELETE, 0,  (H), (K))

static OP *a_pp_multideref(pTHX) {
 UNOP_AUX_item *items;
 UV  actions;
 UV  flags = 0;
 SV *sv    = NULL;
 dSP;

 {
  dA_MAP_THX;
  const a_op_info *oi = a_map_fetch(PL_op);
  XSH_ASSERT(oi);
  flags = a_do_multideref(PL_op, oi->flags);
  if (!flags)
   return oi->old_pp(aTHX);
 }

 items   = cUNOP_AUXx(PL_op)->op_aux;
 actions = items->uv;

 PL_multideref_pc = items;

 while (1) {
  switch (actions & MDEREF_ACTION_MASK) {
   case MDEREF_reload:
    actions = (++items)->uv;
    continue;
   case MDEREF_AV_padav_aelem: /* $lex[...] */
    sv = PAD_SVl((++items)->pad_offset);
    if (a_undef(sv))
     goto ret_undef;
    goto do_AV_aelem;
   case MDEREF_AV_gvav_aelem: /* $pkg[...] */
    sv = UNOP_AUX_item_sv(++items);
    XSH_ASSERT(isGV_with_GP(sv));
    sv = (SV *) GvAVn((GV *) sv);
    if (a_undef(sv))
     goto ret_undef;
    goto do_AV_aelem;
   case MDEREF_AV_pop_rv2av_aelem: /* expr->[...] */
    sv = POPs;
    if (a_undef(sv))
     goto ret_undef;
    goto do_AV_rv2av_aelem;
   case MDEREF_AV_gvsv_vivify_rv2av_aelem: /* $pkg->[...] */
    sv = UNOP_AUX_item_sv(++items);
    XSH_ASSERT(isGV_with_GP(sv));
    sv = GvSVn((GV *) sv);
    if (a_undef(sv))
     goto ret_undef;
    goto do_AV_vivify_rv2av_aelem;
   case MDEREF_AV_padsv_vivify_rv2av_aelem: /* $lex->[...] */
    sv = PAD_SVl((++items)->pad_offset);
    /* FALLTHROUGH */
   case MDEREF_AV_vivify_rv2av_aelem: /* vivify, ->[...] */
    if (a_undef(sv))
     goto ret_undef;
do_AV_vivify_rv2av_aelem:
    sv = a_vivify_ref(sv, 0);
do_AV_rv2av_aelem:
    sv = a_do_pp_rv2av(sv);
do_AV_aelem:
    {
     SV *esv;
     XSH_ASSERT(SvTYPE(sv) == SVt_PVAV);
     switch (actions & MDEREF_INDEX_MASK) {
      case MDEREF_INDEX_none:
       goto finish;
      case MDEREF_INDEX_const:
       esv = sv_2mortal(newSViv((++items)->iv));
       break;
      case MDEREF_INDEX_padsv:
       esv = PAD_SVl((++items)->pad_offset);
       goto check_elem;
      case MDEREF_INDEX_gvsv:
       esv = UNOP_AUX_item_sv(++items);
       XSH_ASSERT(isGV_with_GP(esv));
       esv = GvSVn((GV *) esv);
check_elem:
       if (UNLIKELY(SvROK(esv) && !SvGAMAGIC(esv) && ckWARN(WARN_MISC)))
        Perl_warner(aTHX_ packWARN(WARN_MISC),
                          "Use of reference \"%"SVf"\" as array index",
                          SVfARG(esv));
       break;
     }
     PL_multideref_pc = items;
     if (actions & MDEREF_FLAG_last) {
      switch (flags & A_HINT_DO) {
       case A_HINT_FETCH:
        sv = a_do_pp_afetch(sv, esv);
        break;
       case A_HINT_STORE:
        sv = a_do_pp_afetch_lv(sv, esv);
        break;
       case A_HINT_EXISTS:
        sv = a_do_pp_aexists(sv, esv);
        break;
       case A_HINT_DELETE:
        sv = a_do_pp_adelete(sv, esv);
        break;
      }
      goto finish;
     }
     sv = a_do_pp_afetch(sv, esv);
     break;
    }
   case MDEREF_HV_padhv_helem: /* $lex{...} */
    sv = PAD_SVl((++items)->pad_offset);
    if (a_undef(sv))
     goto ret_undef;
    goto do_HV_helem;
   case MDEREF_HV_gvhv_helem: /* $pkg{...} */
    sv = UNOP_AUX_item_sv(++items);
    XSH_ASSERT(isGV_with_GP(sv));
    sv = (SV *) GvHVn((GV *) sv);
    if (a_undef(sv))
     goto ret_undef;
    goto do_HV_helem;
   case MDEREF_HV_pop_rv2hv_helem: /* expr->{...} */
    sv = POPs;
    if (a_undef(sv))
     goto ret_undef;
    goto do_HV_rv2hv_helem;
   case MDEREF_HV_gvsv_vivify_rv2hv_helem: /* $pkg->{...} */
    sv = UNOP_AUX_item_sv(++items);
    XSH_ASSERT(isGV_with_GP(sv));
    sv = GvSVn((GV *) sv);
    if (a_undef(sv))
     goto ret_undef;
    goto do_HV_vivify_rv2hv_helem;
   case MDEREF_HV_padsv_vivify_rv2hv_helem: /* $lex->{...} */
    sv = PAD_SVl((++items)->pad_offset);
    /* FALLTHROUGH */
   case MDEREF_HV_vivify_rv2hv_helem: /* vivify, ->{...} */
    if (a_undef(sv))
     goto ret_undef;
do_HV_vivify_rv2hv_helem:
    sv = a_vivify_ref(sv, 1);
do_HV_rv2hv_helem:
    sv = a_do_pp_rv2hv(sv);
do_HV_helem:
    {
     SV *key;
     XSH_ASSERT(SvTYPE(sv) == SVt_PVHV);
     switch (actions & MDEREF_INDEX_MASK) {
      case MDEREF_INDEX_none:
       goto finish;
      case MDEREF_INDEX_const:
       key = UNOP_AUX_item_sv(++items);
       break;
      case MDEREF_INDEX_padsv:
       key = PAD_SVl((++items)->pad_offset);
       break;
      case MDEREF_INDEX_gvsv:
       key = UNOP_AUX_item_sv(++items);
       XSH_ASSERT(isGV_with_GP(key));
       key = GvSVn((GV *) key);
       break;
     }
     PL_multideref_pc = items;
     if (actions & MDEREF_FLAG_last) {
      switch (flags & A_HINT_DO) {
       case A_HINT_FETCH:
        sv = a_do_pp_hfetch(sv, key);
        break;
       case A_HINT_STORE:
        sv = a_do_pp_hfetch_lv(sv, key);
        break;
       case A_HINT_EXISTS:
        sv = a_do_pp_hexists(sv, key);
        break;
       case A_HINT_DELETE:
        sv = a_do_pp_hdelete(sv, key);
        break;
       default:
        break;
      }
      goto finish;
     }
     sv = a_do_pp_hfetch(sv, key);
     break;
    }
  }

  actions >>= MDEREF_SHIFT;
 }

ret_undef:
 if (flags & (A_HINT_NOTIFY|A_HINT_STORE))
  a_cannot_vivify(flags);
 if (flags & A_HINT_EXISTS)
  sv = &PL_sv_no;
 else
  sv = &PL_sv_undef;
finish:
 XPUSHs(sv);
 RETURN;
}

#endif /* A_HAS_MULTIDEREF */

/* --- Check functions ----------------------------------------------------- */

static void a_recheck_rv2xv(pTHX_ OP *o, OPCODE type, OP *(*new_pp)(pTHX)) {
#define a_recheck_rv2xv(O, T, PP) a_recheck_rv2xv(aTHX_ (O), (T), (PP))

 if (o->op_type == type && o->op_ppaddr != new_pp
                        && cUNOPo->op_first->op_type != OP_GV) {
  dA_MAP_THX;
  const a_op_info *oi = a_map_fetch(o);
  if (oi) {
   a_map_store(o, o->op_ppaddr, oi->next, oi->flags);
   o->op_ppaddr = new_pp;
  }
 }

 return;
}

/* ... ck_pad{any,sv} ...................................................... */

/* Sadly, the padsv OPs we are interested in don't trigger the padsv check
 * function, but are instead manually mutated from a padany. So we store
 * the op entry in the op map in the padany check function, and we set their
 * op_ppaddr member in our peephole optimizer replacement below. */

static OP *(*a_old_ck_padany)(pTHX_ OP *) = 0;

static OP *a_ck_padany(pTHX_ OP *o) {
 UV hint;

 o = a_old_ck_padany(aTHX_ o);

 hint = a_hint();
 if (hint & A_HINT_DO)
  a_map_store_root(o, o->op_ppaddr, hint);
 else
  a_map_delete(o);

 return o;
}

static OP *(*a_old_ck_padsv)(pTHX_ OP *) = 0;

static OP *a_ck_padsv(pTHX_ OP *o) {
 UV hint;

 o = a_old_ck_padsv(aTHX_ o);

 hint = a_hint();
 if (hint & A_HINT_DO) {
  a_map_store_root(o, o->op_ppaddr, hint);
  o->op_ppaddr = a_pp_deref;
 } else
  a_map_delete(o);

 return o;
}

/* ... ck_deref (aelem,helem,rv2sv) ........................................ */

/* Those ops appear both at the root and inside an expression but there's no
 * way to distinguish both situations. Worse, we can't even know if we are in a
 * modifying context, so the expression can't be resolved yet. It will be at the
 * first invocation of a_pp_deref() for this expression. */

static OP *(*a_old_ck_aelem)(pTHX_ OP *) = 0;
static OP *(*a_old_ck_helem)(pTHX_ OP *) = 0;
static OP *(*a_old_ck_rv2sv)(pTHX_ OP *) = 0;

static OP *a_ck_deref(pTHX_ OP *o) {
 OP * (*old_ck)(pTHX_ OP *o) = 0;
 UV hint = a_hint();

 switch (o->op_type) {
  case OP_AELEM:
   old_ck = a_old_ck_aelem;
   if ((hint & A_HINT_DO) && !(hint & A_HINT_STRICT))
    a_recheck_rv2xv(cUNOPo->op_first, OP_RV2AV, a_pp_rv2av);
   break;
  case OP_HELEM:
   old_ck = a_old_ck_helem;
   if ((hint & A_HINT_DO) && !(hint & A_HINT_STRICT))
    a_recheck_rv2xv(cUNOPo->op_first, OP_RV2HV, a_pp_rv2hv_simple);
   break;
  case OP_RV2SV:
   old_ck = a_old_ck_rv2sv;
   break;
 }
 o = old_ck(aTHX_ o);

#if A_HAS_MULTIDEREF
 if (old_ck == a_old_ck_rv2sv && o->op_flags & OPf_KIDS) {
  OP *kid = cUNOPo->op_first;
  if (kid && kid->op_type == OP_GV) {
   if (hint & A_HINT_DO)
    a_map_store(kid, kid->op_ppaddr, NULL, hint);
   else
    a_map_delete(kid);
  }
 }
#endif

 if (hint & A_HINT_DO) {
  a_map_store_root(o, o->op_ppaddr, hint);
  o->op_ppaddr = a_pp_deref;
 } else
  a_map_delete(o);

 return o;
}

/* ... ck_rv2xv (rv2av,rv2hv) .............................................. */

/* Those ops also appear both inisde and at the root, hence the caveats for
 * a_ck_deref() still apply here. Since a padsv/rv2sv must appear before a
 * rv2[ah]v, resolution is handled by the first call to a_pp_deref() in the
 * expression. */

static OP *(*a_old_ck_rv2av)(pTHX_ OP *) = 0;
static OP *(*a_old_ck_rv2hv)(pTHX_ OP *) = 0;

static OP *a_ck_rv2xv(pTHX_ OP *o) {
 OP * (*old_ck)(pTHX_ OP *o) = 0;
 OP * (*new_pp)(pTHX)        = 0;
 UV hint;

 switch (o->op_type) {
  case OP_RV2AV: old_ck = a_old_ck_rv2av; new_pp = a_pp_rv2av; break;
  case OP_RV2HV: old_ck = a_old_ck_rv2hv; new_pp = a_pp_rv2hv_simple; break;
 }
 o = old_ck(aTHX_ o);

 if (cUNOPo->op_first->op_type == OP_GV)
  return o;

 hint = a_hint();
 if (hint & A_HINT_DO && !(hint & A_HINT_STRICT)) {
  a_map_store_root(o, o->op_ppaddr, hint);
  o->op_ppaddr = new_pp;
 } else
  a_map_delete(o);

 return o;
}

/* ... ck_xslice (aslice,hslice) ........................................... */

/* I think those are only found at the root, but there's nothing that really
 * prevent them to be inside the expression too. We only need to update the
 * root so that the rest of the expression will see the right context when
 * resolving. That's why we don't replace the ppaddr. */

static OP *(*a_old_ck_aslice)(pTHX_ OP *) = 0;
static OP *(*a_old_ck_hslice)(pTHX_ OP *) = 0;

static OP *a_ck_xslice(pTHX_ OP *o) {
 OP * (*old_ck)(pTHX_ OP *o) = 0;
 UV hint = a_hint();

 switch (o->op_type) {
  case OP_ASLICE:
   old_ck = a_old_ck_aslice;
   break;
  case OP_HSLICE:
   old_ck = a_old_ck_hslice;
   if (hint & A_HINT_DO)
    a_recheck_rv2xv(OpSIBLING(cUNOPo->op_first), OP_RV2HV, a_pp_rv2hv);
   break;
 }
 o = old_ck(aTHX_ o);

 if (hint & A_HINT_DO) {
  a_map_store_root(o, 0, hint);
 } else
  a_map_delete(o);

 return o;
}

/* ... ck_root (exists,delete,keys,values) ................................. */

/* Those ops are only found at the root of a dereferencing expression. We can
 * then resolve at compile time if vivification must take place or not. */

static OP *(*a_old_ck_exists)(pTHX_ OP *) = 0;
static OP *(*a_old_ck_delete)(pTHX_ OP *) = 0;
static OP *(*a_old_ck_keys)  (pTHX_ OP *) = 0;
static OP *(*a_old_ck_values)(pTHX_ OP *) = 0;

static OP *a_ck_root(pTHX_ OP *o) {
 OP * (*old_ck)(pTHX_ OP *o) = 0;
 OP * (*new_pp)(pTHX)        = 0;
 int enabled = 0;
 UV hint = a_hint();

 switch (o->op_type) {
  case OP_EXISTS:
   old_ck  = a_old_ck_exists;
   new_pp  = a_pp_root_binop;
   enabled = hint & A_HINT_EXISTS;
   break;
  case OP_DELETE:
   old_ck  = a_old_ck_delete;
   new_pp  = a_pp_root_binop;
   enabled = hint & A_HINT_DELETE;
   break;
  case OP_KEYS:
   old_ck  = a_old_ck_keys;
   new_pp  = a_pp_root_unop;
   enabled = hint & A_HINT_KEYS;
   break;
  case OP_VALUES:
   old_ck  = a_old_ck_values;
   new_pp  = a_pp_root_unop;
   enabled = hint & A_HINT_VALUES;
   break;
 }
 o = old_ck(aTHX_ o);

 if (hint & A_HINT_DO) {
  if (enabled) {
#if A_HAS_SCALARKEYS_OPT
   if ((enabled == A_HINT_KEYS) && (o->op_flags & OPf_KIDS)) {
    OP *kid = cUNOPo->op_first;
    if (kid->op_type == OP_RV2HV) {
     dA_MAP_THX;
     const a_op_info *koi = a_map_fetch(kid);
     a_map_store(kid, koi ? koi->old_pp : kid->op_ppaddr, NULL,
                      hint | A_HINT_SECOND);
     if (!koi)
      kid->op_ppaddr = a_pp_rv2hv;
    }
   }
#endif
   a_map_update_flags_topdown(o, A_HINT_SECOND, hint | A_HINT_DEREF);
   a_map_store_root(o, o->op_ppaddr, hint);
   o->op_ppaddr = new_pp;
  } else {
   a_map_update_flags_topdown(o, 0, 0);
  }
 } else
  a_map_delete(o);

 return o;
}

/* --- Our peephole optimizer ---------------------------------------------- */

static void xsh_peep_rec(pTHX_ OP *o, ptable *seen) {
 for (; o; o = o->op_next) {
  dA_MAP_THX;
  const a_op_info *oi = NULL;
  UV flags = 0;

  if (xsh_peep_seen(o, seen))
   break;

  switch (o->op_type) {
   case OP_PADSV:
    if (o->op_ppaddr != a_pp_deref) {
     oi = a_map_fetch(o);
     if (oi && (oi->flags & A_HINT_DO)) {
      a_map_store(o, o->op_ppaddr, oi->next, oi->flags);
      o->op_ppaddr = a_pp_deref;
     }
    }
    /* FALLTHROUGH */
   case OP_AELEM:
   case OP_AELEMFAST:
   case OP_HELEM:
   case OP_RV2SV:
    if (o->op_ppaddr != a_pp_deref)
     break;
    oi = a_map_fetch(o);
    if (!oi)
     break;
    flags = oi->flags;
    if (!(flags & A_HINT_DEREF)
        && (flags & A_HINT_DO)
        && (o->op_private & OPpDEREF || flags & A_HINT_ROOT)) {
     /* Decide if the expression must autovivify or not. */
     flags = a_map_resolve(o, oi);
    }
    if (flags & A_HINT_DEREF)
     o->op_private = ((o->op_private & ~OPpDEREF) | OPpLVAL_DEFER);
    else
     o->op_ppaddr  = oi->old_pp;
    break;
   case OP_RV2AV:
    if (o->op_ppaddr != a_pp_rv2av)
     break;
    oi = a_map_fetch(o);
    if (!oi)
     break;
    if (!(oi->flags & A_HINT_DEREF))
     o->op_ppaddr = oi->old_pp;
    break;
   case OP_RV2HV:
    if (o->op_ppaddr != a_pp_rv2hv && o->op_ppaddr != a_pp_rv2hv_simple)
     break;
    oi = a_map_fetch(o);
    if (!oi)
     break;
    if (!(oi->flags & A_HINT_DEREF)) {
     o->op_ppaddr = oi->old_pp;
     break;
    }
#if A_HAS_SCALARKEYS_OPT
    flags = oi->flags;
    if ((flags & A_HINT_KEYS) && (flags & A_HINT_SECOND)) {
     U8 want = o->op_flags & OPf_WANT;
     if (want == OPf_WANT_VOID || want == OPf_WANT_SCALAR)
      o->op_ppaddr = a_pp_rv2hv_dokeys;
     else if (oi->old_pp == a_pp_rv2hv || oi->old_pp == a_pp_rv2hv_simple)
      o->op_ppaddr = oi->old_pp;
    }
#endif
    break;
#if A_HAS_MULTIDEREF
   case OP_MULTIDEREF:
    if (o->op_ppaddr != a_pp_multideref) {
     oi = a_map_fetch(cUNOPo->op_first);
     if (!oi)
      break;
     flags = oi->flags;
     if (a_do_multideref(o, flags)) {
      a_map_store_root(o, o->op_ppaddr, flags & ~A_HINT_DEREF);
      o->op_ppaddr = a_pp_multideref;
     }
    }
    break;
#endif
   default:
    xsh_peep_maybe_recurse(o, seen);
    break;
  }
 }
}

/* --- Module setup/teardown ----------------------------------------------- */

static void xsh_user_global_setup(pTHX) {
 a_op_map = ptable_new(32);

#ifdef USE_ITHREADS
 MUTEX_INIT(&a_op_map_mutex);
#endif

 xsh_ck_replace(OP_PADANY, a_ck_padany, &a_old_ck_padany);
 xsh_ck_replace(OP_PADSV,  a_ck_padsv,  &a_old_ck_padsv);

 xsh_ck_replace(OP_AELEM,  a_ck_deref,  &a_old_ck_aelem);
 xsh_ck_replace(OP_HELEM,  a_ck_deref,  &a_old_ck_helem);
 xsh_ck_replace(OP_RV2SV,  a_ck_deref,  &a_old_ck_rv2sv);

 xsh_ck_replace(OP_RV2AV,  a_ck_rv2xv,  &a_old_ck_rv2av);
 xsh_ck_replace(OP_RV2HV,  a_ck_rv2xv,  &a_old_ck_rv2hv);

 xsh_ck_replace(OP_ASLICE, a_ck_xslice, &a_old_ck_aslice);
 xsh_ck_replace(OP_HSLICE, a_ck_xslice, &a_old_ck_hslice);

 xsh_ck_replace(OP_EXISTS, a_ck_root,   &a_old_ck_exists);
 xsh_ck_replace(OP_DELETE, a_ck_root,   &a_old_ck_delete);
 xsh_ck_replace(OP_KEYS,   a_ck_root,   &a_old_ck_keys);
 xsh_ck_replace(OP_VALUES, a_ck_root,   &a_old_ck_values);

 return;
}

static void xsh_user_local_setup(pTHX) {
 HV *stash;

 stash = gv_stashpvn(XSH_PACKAGE, XSH_PACKAGE_LEN, 1);
 newCONSTSUB(stash, "A_HINT_STRICT", newSVuv(A_HINT_STRICT));
 newCONSTSUB(stash, "A_HINT_WARN",   newSVuv(A_HINT_WARN));
 newCONSTSUB(stash, "A_HINT_FETCH",  newSVuv(A_HINT_FETCH));
 newCONSTSUB(stash, "A_HINT_STORE",  newSVuv(A_HINT_STORE));
 newCONSTSUB(stash, "A_HINT_KEYS",   newSVuv(A_HINT_KEYS));
 newCONSTSUB(stash, "A_HINT_VALUES", newSVuv(A_HINT_VALUES));
 newCONSTSUB(stash, "A_HINT_EXISTS", newSVuv(A_HINT_EXISTS));
 newCONSTSUB(stash, "A_HINT_DELETE", newSVuv(A_HINT_DELETE));
 newCONSTSUB(stash, "A_HINT_MASK",   newSVuv(A_HINT_MASK));
 newCONSTSUB(stash, "A_THREADSAFE",  newSVuv(XSH_THREADSAFE));
 newCONSTSUB(stash, "A_FORKSAFE",    newSVuv(XSH_FORKSAFE));

 return;
}

static void xsh_user_local_teardown(pTHX) {
 return;
}

static void xsh_user_global_teardown(pTHX) {
 xsh_ck_restore(OP_PADANY, &a_old_ck_padany);
 xsh_ck_restore(OP_PADSV,  &a_old_ck_padsv);

 xsh_ck_restore(OP_AELEM,  &a_old_ck_aelem);
 xsh_ck_restore(OP_HELEM,  &a_old_ck_helem);
 xsh_ck_restore(OP_RV2SV,  &a_old_ck_rv2sv);

 xsh_ck_restore(OP_RV2AV,  &a_old_ck_rv2av);
 xsh_ck_restore(OP_RV2HV,  &a_old_ck_rv2hv);

 xsh_ck_restore(OP_ASLICE, &a_old_ck_aslice);
 xsh_ck_restore(OP_HSLICE, &a_old_ck_hslice);

 xsh_ck_restore(OP_EXISTS, &a_old_ck_exists);
 xsh_ck_restore(OP_DELETE, &a_old_ck_delete);
 xsh_ck_restore(OP_KEYS,   &a_old_ck_keys);
 xsh_ck_restore(OP_VALUES, &a_old_ck_values);

 ptable_map_free(a_op_map);
 a_op_map = NULL;

#ifdef USE_ITHREADS
 MUTEX_DESTROY(&a_op_map_mutex);
#endif

 return;
}

/* --- XS ------------------------------------------------------------------ */

MODULE = autovivification      PACKAGE = autovivification

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
_tag(SV *hint)
PROTOTYPE: $
CODE:
 RETVAL = xsh_hints_tag(SvOK(hint) ? SvUV(hint) : 0);
OUTPUT:
 RETVAL

SV *
_detag(SV *tag)
PROTOTYPE: $
CODE:
 if (!SvOK(tag))
  XSRETURN_UNDEF;
 RETVAL = newSVuv(xsh_hints_detag(tag));
OUTPUT:
 RETVAL
