#include <signal.h>

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef USE_ITHREADS
#define sigmask_func pthread_sigmask
#else
#define sigmask_func sigprocmask
#endif

sigset_t* S_sv_to_sigset(pTHX_ SV* sigmask, const char* name) {
	if (!SvOK(sigmask))
		return NULL;
	if (!SvROK(sigmask) || !sv_derived_from(sigmask, "POSIX::SigSet"))
		Perl_croak(aTHX_ "%s is not of type POSIX::SigSet");
#if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
	return (sigset_t *) SvPV_nolen(SvRV(sigmask));
#else
	IV tmp = SvIV((SV*)SvRV(sigmask));
	return INT2PTR(sigset_t*, tmp);
#endif
}
#define sv_to_sigset(sigmask, name) S_sv_to_sigset(aTHX_ sigmask, name)

#define undef &PL_sv_undef

MODULE = Thread::SigMask				PACKAGE = Thread::SigMask

SV*
sigmask(how, set, oldset = undef)
	int how;
	SV* set;
	SV* oldset;
	PREINIT:
		int ret;
	CODE:
		ret = sigmask_func(how, sv_to_sigset(set, "set"), sv_to_sigset(oldset, "oldset"));
		if (ret == 0)
			XSRETURN_PV("0 but true");
		else
			XSRETURN_EMPTY;

