#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#include "notification.h"

void notification_init(Notification* notification) {
	notification->fd = -1;
}

void S_notification_set(pTHX_ Notification* notification, PerlIO* handle, SV* value) {
	if (notification->fd != -1)
		Perl_croak(aTHX_ "Notification already set");
	notification->fd = PerlIO_fileno(handle);
	const char* buffer = SvPV(value, notification->buffer_size);
	notification->buffer = savepvn(buffer, notification->buffer_size);
}

void notification_trigger(Notification* notification) {
	if (notification->fd == -1)
		return;
	if (write(notification->fd, notification->buffer, notification->buffer_size) != notification->buffer_size)
		warn("Could not write pipe: %d", notification->fd);
}

void notification_unset(Notification* notification) {
	if (notification->fd != -1) {
		Safefree(notification->buffer);
		notification->fd = -1;
		notification->buffer = NULL;
		notification->buffer_size = 0;
	}
}
