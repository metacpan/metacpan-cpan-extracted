#define PERL_NO_GET_CONTEXT 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef newSVpvs
# define newSVpvs(string) newSVpvn(""string"", sizeof(string)-1)
#endif /* !newSVpvs */

#ifndef hv_stores
# define hv_stores(hv, keystr, val) \
		hv_store(hv, ""keystr"", sizeof(keystr)-1, val, 0)
#endif /* !hv_stores */

#ifndef mPUSHs
# define mPUSHs(s) PUSHs(sv_2mortal(s))
#endif /* !mPUSHs */

#ifndef mPUSHi
# define mPUSHi(i) sv_setiv_mg(PUSHs(sv_newmortal()), (IV)(i))
#endif /* !mPUSHi */

#ifndef mPUSHn
# define mPUSHn(n) sv_setnv_mg(PUSHs(sv_newmortal()), (NV)(n))
#endif /* !mPUSHn */

#ifndef START_MY_CXT
# ifdef PERL_IMPLICIT_CONTEXT
#  define START_MY_CXT
#  define dMY_CXT_SV \
	SV *my_cxt_sv = *hv_fetch(PL_modglobal, \
				MY_CXT_KEY, sizeof(MY_CXT_KEY)-1, 1)
#  define dMY_CXT \
	dMY_CXT_SV; my_cxt_t *my_cxtp = INT2PTR(my_cxt_t*, SvUV(my_cxt_sv))
#  define MY_CXT_INIT \
	dMY_CXT_SV; \
	my_cxt_t *my_cxtp = (my_cxt_t*)SvPVX(newSV(sizeof(my_cxt_t)-1)); \
	Zero(my_cxtp, 1, my_cxt_t); \
	sv_setuv(my_cxt_sv, PTR2UV(my_cxtp))
#  define MY_CXT (*my_cxtp)
# else /* !PERL_IMPLICIT_CONTEXT */
#  define START_MY_CXT static my_cxt_t my_cxt;
#  define dMY_CXT dNOOP
#  define MY_CXT_INIT NOOP
#  define MY_CXT my_cxt
# endif /* !PERL_IMPLICIT_CONTEXT */
#endif /* !START_MY_CXT */

#ifndef MY_CXT_CLONE
# ifdef PERL_IMPLICIT_CONTEXT
#  define MY_CXT_CLONE \
	dMY_CXT_SV; \
	my_cxt_t *my_cxtp = (my_cxt_t*)SvPVX(newSV(sizeof(my_cxt_t)-1)); \
	Copy(INT2PTR(my_cxt_t*, SvUV(my_cxt_sv)), my_cxtp, 1, my_cxt_t); \
	sv_setuv(my_cxt_sv, PTR2UV(my_cxtp))
# else /* !PERL_IMPLICIT_CONTEXT */
#  define MY_CXT_CLONE NOOP
# endif /* !PERL_IMPLICIT_CONTEXT */
#endif /* !MY_CXT_CLONE */

#define TAI_EPOCH_MJD 36204

#define UNIX_EPOCH_MJD 40587
#define UNIX_EPOCH_DAYNO (UNIX_EPOCH_MJD - TAI_EPOCH_MJD)

#define MY_CXT_KEY "Time::UTC::Now::_guts"XS_VERSION
typedef struct {
	bool loaded_math_bigrat;
	bool loaded_time_unix;
} my_cxt_t;
START_MY_CXT

/*
 * multi-mechanism protocol
 *
 * The various try_* functions attempt to acquire the current UTC time in
 * various ways.  They take one argument, a pointer to a struct nowtime.
 * They return the time they determine by filling in the structure.
 * If they can determine the time at all, they must populate dayno, tod_s,
 * and tod_ns.  If they can additionally determine an inaccuracy bound,
 * they must also fill bound_s and bound_ns.  Where time or inaccuracy
 * bound cannot be determined, the corresponding fields do not need to
 * be filled.  The functions return a flag indicating what they could
 * achieve.
 *
 * Each mechanism that is available in the build provides a struct
 * mechanism initialiser, in a macro, for the table of mechanisms to
 * iterate over.
 */

struct nowtime {
	I32 dayno;
	I32 tod_s, tod_ns;
	I32 bound_s, bound_ns;
};

#define GOT_NOTHING   0 /* failed to get time */
#define GOT_TIME      1 /* got UTC time but no inaccuracy bound */
#define GOT_BOUND     2 /* got UTC time and inaccuracy bound */

struct mechanism {
	char const *name;
	int (*THX_try)(pTHX_ struct nowtime *);
	int max_got;
};

/*
 * use of ntp_adjtime()
 *
 * The kernel variables returned by ntp_adjtime() and ntp_gettime()
 * don't necessarily behave the way they're supposed to.  The
 * variables we're interested in are:
 *
 * ntv.time      Unix time number, as seconds plus microseconds
 * leap_state    leap second state
 * ntv.maxerror  alleged maximum possible error, in microseconds
 * tx.offset     offset being applied to clock, in microsecods
 * tx.tolerance  possible inaccuracy of clock rate, in scaled ppm
 *
 * The leap second state can be:
 *   TIME_OK:  normal, no leap second nearby
 *   TIME_INS: leap second is to be inserted at the end of this day
 *   TIME_DEL: leap second is to be deleted at the end of this day
 *   TIME_OOP: the current second is a leap second being inserted
 *   TIME_WAIT: leap occured in the recent past
 *
 * The state goes from TIME_OK to TIME_{INS,DEL} some time during
 * the UTC day that will have a leap at the end.  This happens by
 * the STA_{INS,DEL} flags being set from user space.  After the
 * leap the TIME_WAIT state persists until the STA_{INS,DEL} flags
 * are cleared.
 *
 * Behaviour across midnight is nominally thus:
 *
 *   398 TIME_DEL     398 TIME_OK      398 TIME_INS
 *   400 TIME_WAIT    399 TIME_OK      399 TIME_INS
 *   401 TIME_WAIT    400 TIME_OK      399 TIME_OOP
 *   402 TIME_WAIT    401 TIME_OK      400 TIME_WAIT
 *
 * So to decode that all we have to do is recognise state TIME_OOP
 * as indicating 86400 s of the current day and otherwise split up
 * ntv.time.tv_sec conventionally.  We wouldn't need to recognise
 * the other leap second states.  Note that the second *before*
 * midnight is being repeated in the Unix time number, which is
 * contrary to POSIX, but this is standard behaviour for
 * ntp_adjtime() as defined by [KERN-MODEL].
 *
 * What actually happens in Linux (as of 2.4.19) is rather messier.
 * The leap second processing does not occur atomically along with
 * the rollover of the second.  There's a delay (5 ms on my machine)
 * after the seconds counter increments before the leap second state
 * changes and the counter gets warped.  So we see this:
 *
 *   398.5 TIME_DEL     398.5 TIME_OK      398.5 TIME_INS
 *   399.0 TIME_DEL     399.0 TIME_OK      399.0 TIME_INS
 *   400.5 TIME_WAIT    399.5 TIME_OK      399.5 TIME_INS
 *   401.0 TIME_WAIT    400.0 TIME_OK      400.0 TIME_INS
 *   401.5 TIME_WAIT    400.5 TIME_OK      399.5 TIME_OOP
 *   402.0 TIME_WAIT    401.0 TIME_OK      400.0 TIME_OOP
 *   402.5 TIME_WAIT    401.5 TIME_OK      400.5 TIME_WAIT
 *
 * So the time that is deleted or repeated on the Unix time number
 * is not exactly an integer-delimited second, but is some second
 * encompassing midnight, roughly [399.005, 400.005].  Naive
 * decoding of the seconds counter gives non-existent times
 * when a second is deleted, and jumps around when a second is
 * inserted.  [KERN-MODEL] admits this possibility.
 *
 * Fortunately the leap second state change *does* occur atomically
 * with the second warp.  It is therefore possible to fix up the
 * values returned by the kernel by an understanding of all the
 * states of the leap second machine.  If the kernel does the job
 * properly (in a hypothetical future version) then the extra fixup
 * code will never execute and everything will still work.
 *
 * There's another complication.  If the clock is in an
 * "unsynchronised" condition then ntp_adjtime() gives us the
 * error value TIME_ERROR in leap_state, instead of the leap
 * second state. The leap second state machine still operates
 * in this condition (at least on Linux), we just can't see
 * its state variable.  Annoyingly, we could have picked up the
 * unsynchronised condition (which we do care about) from the
 * STA_UNSYNCH status flag instead, so the leap state is being
 * gratuitously squashed.  The upshot is that we can't decode
 * properly around leap seconds if the clock is unsynchronised,
 * but that's not a disaster because we're not claiming accuracy
 * in that case anyway.
 *
 * The possible error in the clock value is supposedly in
 * ntv.maxerror.  However, this has a couple of problems.  It is
 * updated in chunks at intervals of 1 s, rather than keeping
 * step with the time, so it might not reflect the possible
 * inaccuracy developed in the last second.  We add on an
 * adjustment based on tx.tolerance to fix this.
 *
 * Also, according to my understanding of the ntpd source, it seems
 * that ntv.maxerror is based on the time that the clock would show
 * after the current offset adjustment is completed, not what it
 * currently shows.  (ntpd seems to completely ignore the fact that
 * the offset adjustment is not instantaneous!)  In principle we
 * could apply the offset ourselves to get a more precise time, but
 * this causes non-monotonicity even in a synchronised clock (and
 * also more leap second joy if the offset is negative).  Therefore
 * we just treat the pending offset as another source of error.
 *
 * An additional microsecond is added to the error bound to
 * account for possible rounding down of the time value in the
 * kernel.
 *
 * reference:
 * [KERN-MODEL] David L. Mills, "A Kernel Model for Precision
 * Timekeeping", 31 January 1996, <http://www.eecis.udel.edu/~mills/
 * database/memos/memo96b.ps>.
 */

#ifdef QHAVE_NTP_ADJTIME

# include <sys/timex.h>

/* there are several names for the error state returned by ntp_adjtime() */
# ifndef TIME_ERROR
#  ifdef TIME_ERR
#   define TIME_ERROR TIME_ERR
#  elif defined(TIME_BAD)
#   define TIME_ERROR TIME_BAD
#  endif
# endif

/* this might not be in the user-space version of the header */
# ifndef SHIFT_USEC
#  define SHIFT_USEC 16
# endif

/* time structures may be struct timeval or struct timespec */
# ifdef QHAVE_STRUCT_TIMEX_TIME_TV_NSEC
#  define TIMEX_SUBSEC tv_nsec
# else
#  define TIMEX_SUBSEC tv_usec
# endif
# ifdef QHAVE_STRUCT_NTPTIMEVAL_TIME_TV_NSEC
#  define NTPTIMEVAL_SUBSEC tv_nsec
# else
#  define NTPTIMEVAL_SUBSEC tv_usec
# endif

/* this state flag might not exist */
# ifndef STA_NANO
#  define STA_NANO 0
# endif

static int THX_try_ntpadjtime(pTHX_ struct nowtime *nt)
{
	int state;
	struct timex tx;
	long dayno, secs;
# ifdef QHAVE_STRUCT_TIMEX_TIME
#  define ntv tx
#  define NTV_SUBSEC TIMEX_SUBSEC
# else /* !QHAVE_STRUCT_TIMEX_TIME */
	struct ntptimeval ntv;
#  define NTV_SUBSEC NTPTIMEVAL_SUBSEC
	struct timex txx;
# endif /* !QHAVE_STRUCT_TIMEX_TIME */
	long maxerr, offset, err_s, err_ns;
# if defined(QHAVE_STRUCT_TIMEX_TIME) ? \
	defined(QHAVE_STRUCT_TIMEX_TIME_STATE) : \
	defined(QHAVE_STRUCT_NTPTIMEVAL_TIME_STATE)
#  define leap_state ntv.time_state
# else
#  define leap_state state
# endif
#ifdef QHAVE_STRUCT_TIMEX_TIME
	Zero(&tx, 1, struct timex);
	state = ntp_adjtime(&tx);
#else /* !QHAVE_STRUCT_TIMEX_TIME */
	/*
	 * ntp_adjtime() doesn't give us the actual current time, only the
	 * auxiliary time variables.  (D'oh!)  We need a correlated set of
	 * variables, so this is a problem.  We take the auxiliary
	 * variables once, then proceed to get the time, and then get the
	 * auxiliary variables again.  We work with the worst values from
	 * the two sets of auxiliary variables.
	 *
	 * This can theoretically produce wrong results if the clock
	 * state is adjusted (by ntpd) between our syscalls.  For example,
	 * if we read a small tx.offset, then ntpd adjusts the clock by
	 * initiating a larger offset and resets maxerror to be small,
	 * then we read the time with a small maxerror, then the offset
	 * ticks down, then we read the reduced tx.offset.  In that case
	 * we'd never see a tx.offset value as large as that which truly
	 * applies to the time value that we read.  The potential error
	 * in this sort of case is quite small, fortunately.
	 *
	 * We also need a consistent state of the STA_NANO flag, which is
	 * only available from ntp_adjtime().  If it changes between the
	 * two calls then we try again.  If it gets changed twice then we
	 * could get a time value that is inconsistent with the flag state
	 * that we consistently see.  There is no way to prevent this
	 * happening.  Fortunately, it's even less likely than the
	 * failure mode described in the previous paragraph.
	 *
	 * In case it's not clear from the above: memo to OS implementors:
	 * please include the current time in struct timex, so that the
	 * entire clock state can be acquired atomically and thus
	 * coherently.
	 */
	do {
		Zero(&tx, 1, struct timex);
		Zero(&txx, 1, struct timex);
		if(ntp_adjtime(&tx) == -1)
			return GOT_NOTHING;
		state = ntp_gettime(&ntv);
		if(ntp_adjtime(&txx) == -1)
			return GOT_NOTHING;
	} while((tx.status & STA_NANO) != (txx.status & STA_NANO));
	if(txx.offset > tx.offset)
		tx.offset = txx.offset;
	if(txx.tolerance > tx.tolerance)
		tx.tolerance = txx.tolerance;
#endif /* !QHAVE_STRUCT_TIMEX_TIME */
	if(state == -1 || ntv.time.tv_sec < 0) return GOT_NOTHING;
	dayno = UNIX_EPOCH_DAYNO + ntv.time.tv_sec / 86400;
	secs = ntv.time.tv_sec % 86400;
	switch(leap_state) {
		case TIME_OK: case TIME_WAIT: {
			/* no extra leap second processing required */
		} break;
		case TIME_DEL: {
			if(secs == 86399) {
				/*
				 * we're apparently in the second being
				 * deleted, and so must delete it ourselves
				 */
				dayno++;
				secs = 0;
			}
		} break;
		case TIME_INS: {
			if(secs == 0) {
				/*
				 * the kernel was supposed to have inserted
				 * a second, but it hasn't got round to it,
				 * so we must do it ourselves
				 */
				dayno--;
				secs = 86400;
			}
		} break;
		case TIME_OOP: {
			if(secs == 86399) {
				/* we're in the leap second */
				secs++;
			} else {
				/*
				 * leap second has actually finished, time
				 * decodes correctly
				 */
			}
		} break;
	}
	nt->dayno = dayno;
	nt->tod_s = secs;
	nt->tod_ns = (tx.status & STA_NANO) ?
			ntv.time.NTV_SUBSEC :
			ntv.time.NTV_SUBSEC * 1000;
	if(leap_state == TIME_ERROR) return GOT_TIME;
	maxerr = ntv.maxerror + (tx.tolerance >> SHIFT_USEC) + 1;
	offset = tx.offset < 0 ? -tx.offset : tx.offset;
	err_s = maxerr / 1000000;
	maxerr -= err_s * 1000000;
	if(tx.status & STA_NANO) {
		long offset_s = offset / 1000000000;
		offset -= offset_s * 1000000000;
		err_s += offset_s;
		err_ns = offset + maxerr*1000;
	} else {
		long offset_s = offset / 1000000;
		offset -= offset_s * 1000000;
		err_s += offset_s;
		err_ns = (offset + maxerr) * 1000;
	}
	if(err_ns >= 1000000000) {
		err_s++;
		err_ns -= 1000000000;
	}
	nt->bound_s = err_s;
	nt->bound_ns = err_ns;
	return GOT_BOUND;
}

# define MECH_NTPADJTIME { "ntp_adjtime", THX_try_ntpadjtime, GOT_BOUND },

#else /* !QHAVE_NTP_ADJTIME */
# define MECH_NTPADJTIME
#endif /* !QHAVE_NTP_ADJTIME */

/*
 * use of GetSystemTimeAsFileTime()
 *
 * This is a Win32 native function.  There is no leap second
 * handling or error bound.  The function returns the number
 * of non-leap seconds since 1601-01-01T00Z, as a 64-bit
 * integer (in two 32-bit halves) in units of 10^-7 s.
 */

#ifdef QHAVE_GETSYSTEMTIMEASFILETIME

# include <windows.h>

# define WINDOWS_EPOCH_MJD (-94187)
# define WINDOWS_EPOCH_DAYNO (WINDOWS_EPOCH_MJD - TAI_EPOCH_MJD)

# if !(defined(HAS_QUAD) && defined(UINT64_C))
static U16 div_u64_u16(U32 *hi_p, U32 *lo_p, U16 d)
{
	U32 hq = *hi_p / d;
	U32 hr = *hi_p % d;
	U32 mid = (hr << 16) | (*lo_p >> 16);
	U32 mq = mid / d;
	U32 mr = mid % d;
	U32 low = (mr << 16) | (*lo_p & 0xffff);
	U32 lq = low / d;
	U32 lr = low % d;
	*lo_p = lq | (mq << 16);
	*hi_p = hq;
	return lr;
}
# endif /* !(HAS_QUAD && UINT64_C) */

static int THX_try_getsystemtimeasfiletime(pTHX_ struct nowtime *nt)
{
	FILETIME fts;
# if defined(HAS_QUAD) && defined(UINT64_C)
	U64 ftv;
# else /* !(HAS_QUAD && UINT64_C) */
	U32 ft_hi, ft_lo;
	U16 clunks, msec, dasec;
# endif /* !(HAS_QUAD && UINT64_C) */
	fts.dwHighDateTime = 0xffffffff;
	GetSystemTimeAsFileTime(&fts);
	if(fts.dwHighDateTime & 0x80000000)
		/* this appears to be the only way to indicate error */
		return GOT_NOTHING;
# if defined(HAS_QUAD) && defined(UINT64_C)
	ftv = (((U64)fts.dwHighDateTime) << 32) | ((U64)fts.dwLowDateTime);
	if(ftv < -WINDOWS_EPOCH_DAYNO * UINT64_C(864000000000))
		return GOT_NOTHING;
	nt->dayno = WINDOWS_EPOCH_DAYNO + ftv / UINT64_C(864000000000);
	ftv %= UINT64_C(864000000000);
	nt->tod_s = ftv / UINT64_C(10000000);
	nt->tod_ns = ((U32)(ftv % UINT64_C(10000000))) * 100;
# else /* !(HAS_QUAD && UINT64_C) */
	ft_hi = fts.dwHighDateTime;
	ft_lo = fts.dwLowDateTime;
	clunks = div_u64_u16(&ft_hi, &ft_lo, 10000);
	msec = div_u64_u16(&ft_hi, &ft_lo, 10000);
	dasec = div_u64_u16(&ft_hi, &ft_lo, 8640);
	if(ft_lo < -WINDOWS_EPOCH_DAYNO)
		return GOT_NOTHING;
	nt->dayno = WINDOWS_EPOCH_DAYNO + ft_lo;
	nt->tod_s = ((U32)dasec) * 10 + ((U32)msec)/1000;
	nt->tod_ns = (((U32)msec)%1000) * 1000000 + ((U32)clunks) * 100;
# endif /* !(HAS_QUAD && UINT64_C) */
	return GOT_TIME;
}

# define MECH_GETSYSTEMTIMEASFILETIME \
	{ \
		"GetSystemTimeAsFileTime", \
		THX_try_getsystemtimeasfiletime, \
		GOT_TIME \
	},

#else /* !QHAVE_GETSYSTEMTIMEASFILETIME */
# define MECH_GETSYSTEMTIMEASFILETIME
#endif /* !QHAVE_GETSYSTEMTIMEASFILETIME */

/*
 * use of gettimeofday()
 *
 * There is no leap second handling or error bound here.  It is presumed
 * that any non-Unix OS implementing the Unix-style gettimeofday()
 * will use the Unix epoch for this interface, unlike for time().
 */

#ifdef QHAVE_GETTIMEOFDAY

# include <sys/time.h>

static int THX_try_gettimeofday(pTHX_ struct nowtime *nt)
{
	struct timeval tv;
	if(-1 == gettimeofday(&tv, NULL) || tv.tv_sec < 0)
		return GOT_NOTHING;
	nt->dayno = UNIX_EPOCH_DAYNO + tv.tv_sec / 86400;
	nt->tod_s = tv.tv_sec % 86400;
	nt->tod_ns = tv.tv_usec * 1000;
	return GOT_TIME;
}

# define MECH_GETTIMEOFDAY { "gettimeofday", THX_try_gettimeofday, GOT_TIME },

#else /* !QHAVE_GETTIMEOFDAY */
# define MECH_GETTIMEOFDAY
#endif /* !QHAVE_GETTIMEOFDAY */

/*
 * use of Time::Unix::time()
 *
 * This only gives a resolution of 1 s, and no leap second handling
 * or error bound, but ought to be possible everywhere.  Raw time()
 * doesn't have a consistent epoch across OSes, so we use the
 * Time::Unix wrapper which exists to resolve this.
 */

static int THX_try_timeunixtime(pTHX_ struct nowtime *nt)
{
	dMY_CXT;
	IV secs;
	if(!MY_CXT.loaded_time_unix) {
		load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Time::Unix"),
			newSVnv((NV)1.02));
		MY_CXT.loaded_time_unix = 1;
	}
	{
		SV *sv;
		dSP;
		PUSHMARK(SP);
		PUTBACK;
		call_pv("Time::Unix::time", G_SCALAR|G_NOARGS);
		SPAGAIN;
		sv = POPs;
		PUTBACK;
		secs = SvIV(sv);
	}
	if(secs < 0) return GOT_NOTHING;
	nt->dayno = UNIX_EPOCH_DAYNO + secs / 86400;
	nt->tod_s = secs % 86400;
	nt->tod_ns = 500000000;
	return GOT_TIME;
}

#define MECH_TIMEUNIXTIME \
	{ "Time::Unix::time", THX_try_timeunixtime, GOT_TIME },

/*
 * iteration over mechanisms
 *
 * now_utc_best() returns the best available result from all the available
 * mechanisms.  It tries each mechanism in turn, where they have the
 * potential to improve on the best so far.  It prefers a result with a
 * higher `got' value: i.e., it prefers having an inaccuracy bound over
 * not, and prefers to have time over not having it at all.  For equal
 * `got' values, it prefers the result from the earliest mechanism in
 * the table: they are sorted by desirability.  The logic also relies
 * on the table being sorted by descending max_got, but this is easily
 * changed if such sorting can't be maintained in the future.  As an
 * optimisation, the caller can indicate the minimum `got' value that
 * would be useful; if it would otherwise produce less than that then
 * it will instead return GOT_NOTHING.
 *
 * now_utc_autodie() returns the best available result, but croaks if
 * the best isn't good enough.  What is good enough is controlled by
 * the "demanding accuracy" flag, as used in the Perl interfaces of
 * this module.
 */

static struct mechanism const mechanisms[] = {
	MECH_NTPADJTIME
	MECH_GETSYSTEMTIMEASFILETIME
	MECH_GETTIMEOFDAY
	MECH_TIMEUNIXTIME
};

#define MECH_COUNT (sizeof(mechanisms)/sizeof(mechanisms[0]))

#define now_utc_best(nt, min_got) THX_now_utc_best(aTHX_ nt, min_got)
static int THX_now_utc_best(pTHX_ struct nowtime *nt, int min_got)
{
	int best_got = GOT_NOTHING;
	struct nowtime ntt;
	int i;
	if(min_got < GOT_TIME) min_got = GOT_TIME;
	for(i = 0; i != MECH_COUNT; i++) {
		if(mechanisms[i].max_got < min_got) break;
		int got = mechanisms[i].THX_try(aTHX_ &ntt);
		if(got >= min_got) {
			*nt = ntt;
			if(got == GOT_BOUND) return got;
			best_got = got;
			min_got = got + 1;
		}
	}
	return best_got;
}

#define now_utc_autodie(nt, da) THX_now_utc_autodie(aTHX_ nt, da)
static int THX_now_utc_autodie(pTHX_ struct nowtime *nt, bool da)
{
	int got = now_utc_best(nt, da ? GOT_BOUND : GOT_TIME);
	if(got == GOT_NOTHING)
		croak(da ?
			"can't find time accurately" :
			"can't find time at all");
	return got;
}

/*
 * conversions for output
 */

#define build_rat(unit, nano) THX_build_rat(aTHX_ unit, nano)
static SV *THX_build_rat(pTHX_ I32 unit, I32 nano)
{
	dMY_CXT;
	SV *ref;
	if(!MY_CXT.loaded_math_bigrat) {
		load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Math::BigRat"),
			newSVnv((NV)0.13));
		MY_CXT.loaded_math_bigrat = 1;
	}
	{
		dSP;
		PUSHMARK(SP);
		mPUSHs(newSVpvs("Math::BigRat"));
		mPUSHs(newSVpvf("%ld.%09ld", (long)unit, (long)nano));
		PUTBACK;
		call_method("new", G_SCALAR);
		SPAGAIN;
		ref = POPs;
		PUTBACK;
	}
	return ref;
}

#define build_sna(s, ns) THX_build_sna(aTHX_ s, ns)
static SV *THX_build_sna(pTHX_ I32 s, I32 ns)
{
	AV *sna = newAV();
	av_extend(sna, 2);
	av_store(sna, 0, newSViv(s));
	av_store(sna, 1, newSViv(ns));
	av_store(sna, 2, newSViv(0));
	return sv_2mortal(newRV_noinc((SV*)sna));
}

static NV flt_additional_uncertainty;

#define flt_setup() THX_flt_setup(aTHX)
static void THX_flt_setup(pTHX)
{
	/*
	 * In now_utc_flt(), the floating-point seconds value is
	 * inaccurate due to rounding for binary representation.
	 * (With the resolution currently possible (1 ns), the conversion
	 * to IEEE 754 double doesn't actually lose information, but the
	 * value still isn't converted exactly.)  Not trusting rounding to
	 * be correct, we allow for 1 ulp of additional error, for values
	 * on the order of 86400 (exponent +16).  This is added onto
	 * the uncertainty.  We also add 1 ulp at 3600 (exponent +11) to
	 * cover rounding in conversion of the uncertainty value itself.
	 */
	NV significand_step;
	for(significand_step = 1; ; ) {
		NV try_step = significand_step * ((NV)0.5);
		if((((NV)1.0) + try_step) - ((NV)1.0) != try_step)
			break;
		significand_step = try_step;
	}
	flt_additional_uncertainty =
		(significand_step * ((NV)65536)) +
		(significand_step * ((NV)2048));
}

#define build_dec(s, ns) THX_build_dec(aTHX_ s, ns)
static SV *THX_build_dec(pTHX_ I32 s, I32 ns)
{
	SV *decsv = sv_2mortal(newSVpvf("%ld.%09ld", (long)s, (long)ns));
	char *pv = SvPVX(decsv);
	int pos = SvCUR(decsv);
	while(pv[pos-1] == '0') pos--;
	if(pv[pos-1] == '.') pos--;
	pv[pos] = 0;
	SvCUR_set(decsv, pos);
	return decsv;
}

MODULE = Time::UTC::Now PACKAGE = Time::UTC::Now

PROTOTYPES: DISABLE

BOOT:
	{ MY_CXT_INIT; (void)MY_CXT; }
	flt_setup();

void CLONE(...)
CODE:
	PERL_UNUSED_VAR(items);
	{ MY_CXT_CLONE; }

void
now_utc_rat(bool demanding_accuracy = 0)
PROTOTYPE: ;$
PREINIT:
	struct nowtime nt = { -1, -1, -1, -1, -1 };
	int got;
	SV *dayno_rat, *tod_rat, *bound_rat;
PPCODE:
	PUTBACK;
	got = now_utc_autodie(&nt, demanding_accuracy);
	dayno_rat = build_rat(nt.dayno, 0);
	tod_rat = build_rat(nt.tod_s, nt.tod_ns);
	bound_rat = got == GOT_BOUND ?
		build_rat(nt.bound_s, nt.bound_ns) : &PL_sv_undef;
	SPAGAIN;
	EXTEND(SP, 3);
	PUSHs(dayno_rat);
	PUSHs(tod_rat);
	PUSHs(bound_rat);

void
now_utc_sna(bool demanding_accuracy = 0)
PROTOTYPE: ;$
PREINIT:
	struct nowtime nt = { -1, -1, -1, -1, -1 };
	int got;
PPCODE:
	PUTBACK;
	got = now_utc_autodie(&nt, demanding_accuracy);
	SPAGAIN;
	EXTEND(SP, 3);
	mPUSHi(nt.dayno);
	PUSHs(build_sna(nt.tod_s, nt.tod_ns));
	PUSHs(got == GOT_BOUND ?
		build_sna(nt.bound_s, nt.bound_ns) : &PL_sv_undef);

void
now_utc_flt(bool demanding_accuracy = 0)
PROTOTYPE: ;$
PREINIT:
	struct nowtime nt = { -1, -1, -1, -1, -1 };
	int got;
PPCODE:
	PUTBACK;
	got = now_utc_autodie(&nt, demanding_accuracy);
	SPAGAIN;
	EXTEND(SP, 3);
	mPUSHi(nt.dayno);
	mPUSHn(((NV)nt.tod_s) + ((NV)nt.tod_ns)/((NV)1e9));
	if(got == GOT_BOUND) {
		mPUSHn(((NV)nt.bound_s) + ((NV)nt.bound_ns)/((NV)1e9) +
			flt_additional_uncertainty);
	} else {
		PUSHs(&PL_sv_undef);
	}

void
now_utc_dec(bool demanding_accuracy = 0)
PROTOTYPE: ;$
PREINIT:
	struct nowtime nt = { -1, -1, -1, -1, -1 };
	int got;
PPCODE:
	PUTBACK;
	got = now_utc_autodie(&nt, demanding_accuracy);
	SPAGAIN;
	EXTEND(SP, 3);
	mPUSHi(nt.dayno);
	PUSHs(build_dec(nt.tod_s, nt.tod_ns));
	PUSHs(got == GOT_BOUND ?
		build_dec(nt.bound_s, nt.bound_ns) : &PL_sv_undef);

AV *
_try_all()
PROTOTYPE:
PREINIT:
	struct nowtime nt = { -1, -1, -1, -1, -1 };
	int i;
CODE:
	PUTBACK;
	RETVAL = (AV*)sv_2mortal((SV*)newAV());
	av_extend(RETVAL, MECH_COUNT-1);
	for(i = 0; i != MECH_COUNT; i++) {
		HV *mhv = newHV();
		int got;
		av_store(RETVAL, i, newRV_noinc((SV*)mhv));
		(void) hv_stores(mhv, "name", newSVpv(mechanisms[i].name, 0));
		(void) hv_stores(mhv, "max_got",
			newSViv(mechanisms[i].max_got));
		got = mechanisms[i].THX_try(aTHX_ &nt);
		(void) hv_stores(mhv, "got", newSViv(got));
		if(got >= GOT_TIME) {
			(void) hv_stores(mhv, "dayno", newSViv(nt.dayno));
			(void) hv_stores(mhv, "tod",
				SvREFCNT_inc(build_dec(nt.tod_s, nt.tod_ns)));
		}
		if(got >= GOT_BOUND) {
			(void) hv_stores(mhv, "bound",
				SvREFCNT_inc(
					build_dec(nt.bound_s, nt.bound_ns)));
		}
	}
	SPAGAIN;
	SvREFCNT_inc((SV*)RETVAL);
OUTPUT:
	RETVAL
