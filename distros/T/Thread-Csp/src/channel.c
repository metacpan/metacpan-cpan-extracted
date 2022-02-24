#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#include "refcount.h"
#include "values.h"
#include "notification.h"

#include "channel.h"

/*
 * Message channels
 */

enum state { HAS_NOTHING, HAS_READER, HAS_WRITER, HAS_MESSAGE, CLOSED };
static const char* state_names[] = { "nothing", "has-reader", "has-writer", "has-message" };

struct channel {
	perl_mutex data_mutex;
	perl_mutex reader_mutex;
	perl_mutex writer_mutex;
	perl_cond  data_condvar;

	Refcount refcount;
	enum state state;
	SV* message;
	Notification read_notification;
	Notification write_notification;
};

Channel* channel_alloc(UV refcount) {
	Channel* ret = calloc(1, sizeof(Channel));
	MUTEX_INIT(&ret->data_mutex);
	MUTEX_INIT(&ret->reader_mutex);
	MUTEX_INIT(&ret->writer_mutex);
	COND_INIT(&ret->data_condvar);
	refcount_init(&ret->refcount, refcount);
	notification_init(&ret->read_notification);
	notification_init(&ret->write_notification);
	return ret;
}

void channel_send(Channel* channel, SV* message) {
	MUTEX_LOCK(&channel->writer_mutex);
	MUTEX_LOCK(&channel->data_mutex);

	channel->message = message;
	notification_trigger(&channel->read_notification);
	if (channel->state == HAS_READER) {
		channel->state = HAS_MESSAGE;
		COND_SIGNAL(&channel->data_condvar);
	}
	else {
		assert(channel->state == HAS_NOTHING);
		channel->state = HAS_WRITER;
	}

	do COND_WAIT(&channel->data_condvar, &channel->data_mutex);
	while (channel->state != HAS_NOTHING && channel->state != HAS_READER && channel->state != CLOSED);

	MUTEX_UNLOCK(&channel->data_mutex);
	MUTEX_UNLOCK(&channel->writer_mutex);
}

SV* S_channel_receive(pTHX_ Channel* channel) {
	MUTEX_LOCK(&channel->reader_mutex);
	MUTEX_LOCK(&channel->data_mutex);

	notification_trigger(&channel->write_notification);
	if (channel->state == HAS_NOTHING) {
		channel->state = HAS_READER;
		do COND_WAIT(&channel->data_condvar, &channel->data_mutex);
		while (channel->state != HAS_MESSAGE && channel->state != CLOSED);
	}
	else
		assert(channel->state == HAS_WRITER || channel->state == CLOSED);

	SV* result;
	if (channel->state != CLOSED) {
		result = clone_value(channel->message);
		channel->state = HAS_NOTHING;
	}
	else
		result = &PL_sv_undef;

	channel->message = NULL;
	COND_SIGNAL(&channel->data_condvar);

	MUTEX_UNLOCK(&channel->data_mutex);
	MUTEX_UNLOCK(&channel->reader_mutex);

	return result;
}

SV* S_channel_receive_ready_fh(pTHX_ Channel* channel) {
	MUTEX_LOCK(&channel->data_mutex);

	SV* result = notification_create(&channel->write_notification);
	if (channel->state == HAS_READER)
		notification_trigger(&channel->read_notification);

	MUTEX_UNLOCK(&channel->data_mutex);

	return result;
}

SV* S_channel_send_ready_fh(pTHX_ Channel* channel) {
	MUTEX_LOCK(&channel->data_mutex);

	SV* result = notification_create(&channel->write_notification);
	if (channel->state == HAS_WRITER)
		notification_trigger(&channel->write_notification);

	MUTEX_UNLOCK(&channel->data_mutex);

	return result;
}

void channel_close(Channel* channel) {
	MUTEX_LOCK(&channel->data_mutex);

	notification_unset(&channel->read_notification);
	channel->state = CLOSED;
	COND_SIGNAL(&channel->data_condvar);

	MUTEX_UNLOCK(&channel->data_mutex);
}

void channel_refcount_dec(Channel* channel) {
	if (refcount_dec(&channel->refcount) == 1) {
		notification_unset(&channel->read_notification);
		notification_unset(&channel->write_notification);
		COND_DESTROY(&channel->data_condvar);
		MUTEX_DESTROY(&channel->writer_mutex);
		MUTEX_DESTROY(&channel->reader_mutex);
		MUTEX_DESTROY(&channel->data_mutex);
		free(channel);
	}
}

static int channel_magic_destroy(pTHX_ SV* sv, MAGIC* magic) {
	channel_refcount_dec((Channel*)magic->mg_ptr);
	return 0;
}

static int channel_magic_dup(pTHX_ MAGIC* magic, CLONE_PARAMS* param) {
	Channel* channel = (Channel*)magic->mg_ptr;
	refcount_inc(&channel->refcount);
	return 0;
}

static const MGVTBL channel_magic = { 0, 0, 0, 0, channel_magic_destroy, 0, channel_magic_dup };

SV* S_channel_to_sv(pTHX_ Channel* channel, SV* stash_name) {
	object_to_sv(channel, gv_stashsv(stash_name, 0), &channel_magic, MGf_DUP);
}

Channel* S_sv_to_channel(pTHX_ SV* sv) {
	return sv_to_object(sv, "Thread::Csp::Channel", &channel_magic);
}
