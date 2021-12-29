typedef struct {
	int fd;
	const char* buffer;
	size_t buffer_size;
} Notification;

void notification_init(Notification* notification);
void S_notification_set(pTHX_ Notification*, PerlIO*, SV* value);
#define notification_set(notification, handle, value) S_notification_set(aTHX_ notification, handle, value)
void notification_trigger(Notification*);
void notification_unset(Notification*);
