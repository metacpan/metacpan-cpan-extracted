#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#include "notification.h"

void notification_init(Notification* notification) {
	*notification = -1;
}

static SV* S_io_fdopen(pTHX_ int fd, const char* packagename) {
    PerlIO* pio = PerlIO_fdopen(fd, "r");
    GV* gv = newGVgen(packagename);
    SV* ret = newRV_noinc((SV*)gv);
    IO* io = GvIOn(gv);
    IoTYPE(io) = '<';
    IoIFP(io) = pio;
    IoOFP(io) = pio;
    return ret;
}
#define io_fdopen(fd, packagename) S_io_fdopen(aTHX_ fd, packagename)

SV* S_notification_create(pTHX_ Notification* notification) {
	if (*notification != -1)
		Perl_croak(aTHX_ "Notification already set");
	int fds[2];
	if (PerlProc_pipe(fds) == -1)
		Perl_croak(aTHX_ "Could not pipe: %s", strerror(errno));
	*notification = fds[1];
	return io_fdopen(fds[0], "Thread::Csp");
}

void notification_trigger(Notification* notification) {
	if (*notification == -1)
		return;
	if (write(*notification, "\377", 1) != 1)
		warn("Could not write pipe: %d", *notification);
}

void notification_unset(Notification* notification) {
	if (*notification != -1) {
		close(*notification);
		*notification = -1;
	}
}
