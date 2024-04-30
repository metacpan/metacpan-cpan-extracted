#ifdef __cplusplus
extern "C" {
#endif

#include "ulib/util.h"

#ifdef __cplusplus
}
#endif

static NV uu_time_v1(const struct_uu_t *in) {
  U64   sum;
  NV    rv;

  sum = ((U64)in->v1.time_high_and_version & 0x0fff) << 48
    | ((U64)in->v1.time_mid) << 32
    | (U64)in->v1.time_low;
  sum -= 122192928000000000ULL;
  rv = (NV)sum / 10000000.0;

  return rv;
}

static NV uu_time_v4(const struct_uu_t *in) {
  return 0.0;
}

static NV uu_time_v6(const struct_uu_t *in) {
  U64   sum;
  NV    rv;

  sum = ((U64)in->v6.time_high) << 28
    | ((U64)in->v6.time_mid) << 12
    | ((U64)in->v6.time_low_and_version & 0x0fff);
  sum -= 122192928000000000ULL;
  rv = (NV)sum / 10000000.0;

  return rv;
}

static NV uu_time_v7(const struct_uu_t *in) {
  U64   sum;
  NV    rv;

  sum = ((U64)in->v7.time_high) << 16
    | (U64)in->v7.time_low;
  rv = (NV)sum / 1000.0;

  return rv;
}


NV uu_time(const struct_uu_t *in) {
  int version;

  version = in->v1.time_high_and_version >> 12;

  switch(version) {
    case 1: return uu_time_v1(in);
    case 4: return uu_time_v4(in);
    case 6: return uu_time_v6(in);
    case 7: return uu_time_v7(in);
  }
  return 0;
}

/* a.k.a. version */
UV uu_type(const struct_uu_t *in) {
  UV  type;

  type = in->v1.time_high_and_version >> 12;

  if (type <= 8)
    return type;
  return 0;
}

UV uu_variant(const struct_uu_t *in) {
  U16 variant;

  variant = in->v1.clock_seq_and_variant;

  if ((variant & 0x8000) == 0) return 0;
  if ((variant & 0x4000) == 0) return 1;
  if ((variant & 0x2000) == 0) return 2;
  return 3;
}

/******************************************************************************
 * all for croak_caller before 5.13.4.
*/
#define PERL_ARGS_ASSERT_DOPOPTOSUB_AT assert(cxstk)

#ifdef PERL_GLOBAL_STRUCT
#  define dVAR          pVAR    = (struct perl_vars*)PERL_GET_VARS()
#else
#  define dVAR          dNOOP
#endif

#ifndef dopoptosub
#define dopoptosub(plop)        dopoptosub_at(cxstack, (plop))
#endif

#ifndef dopoptosub_at
#if !defined(PERL_IMPLICIT_CONTEXT)
#  define dopoptosub_at           my_dopoptosub_at
#else
#  define dopoptosub_at(a,b)      my_dopoptosub_at(aTHX_ a,b)
#endif
#endif

STATIC I32
my_dopoptosub_at(pTHX_ const PERL_CONTEXT *cxstk, I32 startingblock)
{
    dVAR;
    I32 i;

    PERL_ARGS_ASSERT_DOPOPTOSUB_AT;

    for (i = startingblock; i >= 0; i--) {
        register const PERL_CONTEXT * const cx = &cxstk[i];
        switch (CxTYPE(cx)) {
        default:
            continue;
        case CXt_EVAL:
        case CXt_SUB:
        case CXt_FORMAT:
            DEBUG_l( Perl_deb(aTHX_ "(dopoptosub_at(): found sub at cx=%ld)\n", (long)i));
            return i;
        }
    }
    return i;
}

const PERL_CONTEXT *
my_caller_cx(pTHX_ I32 count, const PERL_CONTEXT **dbcxp)
{
    register I32 cxix = dopoptosub(cxstack_ix);
    register const PERL_CONTEXT *cx;
    register const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;

    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0 && top_si->si_type != PERLSI_MAIN) {
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = dopoptosub_at(ccstack, top_si->si_cxix);
        }
        if (cxix < 0)
            return NULL;
        /* caller() should not report the automatic calls to &DB::sub */
        if (PL_DBsub && GvCV(PL_DBsub) && cxix >= 0 &&
                ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))
            count++;
        if (!count--)
            break;
        cxix = dopoptosub_at(ccstack, cxix - 1);
    }

    cx = &ccstack[cxix];
    if (dbcxp) *dbcxp = cx;

    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
        const I32 dbcxix = dopoptosub_at(ccstack, cxix - 1);
        /* We expect that ccstack[dbcxix] is CXt_SUB, anyway, the
           field below is defined for any cx. */
        /* caller() should not report the automatic calls to &DB::sub */
        if (PL_DBsub && GvCV(PL_DBsub) && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub))
            cx = &ccstack[dbcxix];
    }

    return cx;
}

void my_croak_caller(const char *pat, ...)  {
  dTHX;
  va_list args;
  const PERL_CONTEXT *cx = my_caller_cx(aTHX_ 0, NULL);

  /* make error appear at call site */
  assert(cx);
  PL_curcop = cx->blk_oldcop;

  va_start(args, pat);
  vcroak(pat, &args);
  NOT_REACHED; /* NOTREACHED */
  va_end(args);
}
/******************************************************************************/

/* ex:set ts=2 sw=2 itab=spaces: */
