#ifndef TKS_INT_H
#define TKS_INT_H

/* What every header here shares: the interpreter-local state and the
 * macros that keep an ABI call from being read as one of XSUB.h's
 * function-like macros on a perl built with PERL_IMPLICIT_SYS. */

#define MY_CXT_KEY "Time::Keeper::Sun::_guts" XS_VERSION

typedef struct {
    HV *stash;          /* Time::Keeper::Sun's */
    HV *pstash;         /* the place class, Time::Keeper::Sun itself */
    HV *dstash;         /* Time::Keeper::Sun::Day */
    HV *mstash;         /* Time::Keeper::Moon::Day */
} my_cxt_t;

START_MY_CXT

#endif
