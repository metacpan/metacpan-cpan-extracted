#if defined linux
#	ifndef _GNU_SOURCE
#		define _GNU_SOURCE
#	endif
#	define GNU_STRERROR_R
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
//#include "ppport.h"

static pthread_t* S_get_pthread(pTHX_ SV* thread_handle) {
	SV* tmp;
	dSP;
	PUSHMARK(SP);
	PUSHs(thread_handle);
	PUTBACK;
	call_method("_handle", G_SCALAR);
	SPAGAIN;
	tmp = POPs;
	return INT2PTR(pthread_t* ,SvUV(tmp));
}
#define get_pthread(handle) S_get_pthread(aTHX_ handle)

static void get_sys_error(char* buffer, size_t buffer_size) {
#if _POSIX_VERSION >= 200112L
#	ifdef GNU_STRERROR_R
	const char* message = strerror_r(errno, buffer, buffer_size);
	if (message != buffer)
		memcpy(buffer, message, buffer_size);
#	else
	strerror_r(errno, buffer, buffer_size);
#	endif
#else
	const char* message = strerror(errno);
	strncpy(buffer, message, buffer_size - 1);
	buffer[buffer_size - 1] = '\0';
#endif
}

static void die_sys(pTHX_ const char* format) {
	char buffer[128];
	get_sys_error(buffer, sizeof buffer);
	Perl_croak(aTHX_ format, buffer);
}

MODULE = threads::posix				PACKAGE = threads::posix

SV*
kill(self, signal)
	SV* self;
	SV* signal;
	PREINIT:
		int ret;
	CODE:
		ret = pthread_kill(*get_pthread(self), SvIOK(signal) && SvIV(signal) ? SvIV(signal) : whichsig(SvPV_nolen(signal)));
		if (ret < 0)
			die_sys(aTHX_ "Couldn't kill thread: %s");

void
cancel(self)
	SV* self;
	PREINIT:
		pthread_t* handle;
	CODE:
		pthread_cancel(*get_pthread(self));

