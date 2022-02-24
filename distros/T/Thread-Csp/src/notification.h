typedef int Notification;

void notification_init(Notification* notification);
SV* S_notification_create(pTHX_ Notification* notification);
#define notification_create(notification) S_notification_create(aTHX_ notification)
void notification_trigger(Notification*);
void notification_unset(Notification*);
