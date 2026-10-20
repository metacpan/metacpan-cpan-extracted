#ifndef TKS_INT_H
#define TKS_INT_H

/* What every header here shares: the interpreter-local state and the
 * macros that keep an ABI call from being read as one of XSUB.h's
 * function-like macros on a perl built with PERL_IMPLICIT_SYS. */

#define MY_CXT_KEY "Time::Keeper::Sky::_guts" XS_VERSION

typedef struct {
    HV *stash;          /* Time::Keeper::Sky's */
    HV *pstash;         /* the class of the places a Day hands back, Time::Keeper::Sun */
    HV *dstash;         /* Time::Keeper::Sun::Day */
    HV *mstash;         /* Time::Keeper::Moon::Day */
    HV *ystash;         /* Time::Keeper::Planet::Day */
    HV *sstash;         /* Time::Keeper::Star::Day */
    HV *estash;         /* Time::Keeper::Eclipse */
    HV *lstash;         /* Time::Keeper::Eclipse::Local */
    double cons_jq;     /* the half day the constellations' matrix is for, or 0 */
    double cons_m[3][3];
} my_cxt_t;

START_MY_CXT

/* SvNV_nomg came in perl 5.14: before it, an SV whose magic was fetched
 * holds its number privately, and sv_2nv reads it (fetching the magic once
 * more, as the dist's other number reads do). */
#ifndef SvNV_nomg
#define SvNV_nomg(sv) (SvNOK(sv) ? SvNVX(sv) : sv_2nv(sv))
#endif

#endif
