#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"

#include "message.h"
#include "queue.h"

static int queue_destructor(pTHX_ SV* queue_object, MAGIC* mg) {
	message_queue* queue = (message_queue*)mg->mg_ptr;
	int alive;
	MUTEX_LOCK(&queue->mutex);
	alive = --queue->refcount;
	MUTEX_UNLOCK(&queue->mutex);
	if (!alive) {
		queue_destroy(queue);
		PerlMemShared_free(queue);
	}
	return 0;
}

static int queue_duplicator(pTHX_ MAGIC* mg, CLONE_PARAMS* params) {
	message_queue* queue = (message_queue*)mg->mg_ptr;
	MUTEX_LOCK(&queue->mutex);
	queue->refcount++;
	MUTEX_UNLOCK(&queue->mutex);
	return 0;
}

static const MGVTBL queue_magic = { NULL, NULL, NULL, NULL, queue_destructor, NULL, queue_duplicator, NULL };

#ifndef mg_findext
#define mg_findext(sv, magic, ptr) mg_find(sv, magic)
#endif

static message_queue* S_get_queue(pTHX_ SV* queue_object) {
	if (!sv_isobject(queue_object) || !sv_derived_from(queue_object, "Thread::Channel"))
		Perl_croak(aTHX_ "Something is very wrong, this is not a queue object\n");
	MAGIC* mg = mg_findext(SvRV(queue_object), PERL_MAGIC_ext, &queue_magic);
	return (message_queue*) mg->mg_ptr;
}
#define get_queue(object) S_get_queue(aTHX_ object)

MODULE = Thread::Channel             PACKAGE = Thread::Channel

PROTOTYPES: DISABLED

SV*
new(class)
	SV* class;
	PREINIT:
		message_queue* queue;
		SV* referent;
		MAGIC* mg;
	CODE:
		queue = PerlMemShared_calloc(1, sizeof(message_queue));
		queue_init(queue);
		referent = newSV(0);
		mg = sv_magicext(referent, NULL, PERL_MAGIC_ext, &queue_magic, (const char*)queue, 0);
		mg->mg_flags |= MGf_DUP|MGf_COPY;
		RETVAL = newRV_noinc(referent);
		sv_bless(RETVAL, gv_stashsv(class, FALSE));
	OUTPUT:
		RETVAL

void
enqueue(object, ...)
	SV* object;
	PREINIT:
		message_queue* queue;
		const message* message;
	CODE:
		queue = get_queue(object);
		if (items == 1)
			Perl_croak(aTHX_ "Can't send an empty list\n");
		PUSHMARK(MARK + 2);
		message_from_stack(message, MARK + 1);
		queue_enqueue(queue, message);

void
dequeue(object)
	SV* object;
	PREINIT:
		message_queue* queue;
		const message* message;
	PPCODE:
		queue = get_queue(object);
		message = queue_dequeue(queue);
		message_to_stack(message, GIMME_V);
		destroy_message(message);


void
dequeue_nb(object)
	SV* object;
	PREINIT:
		message_queue* queue;
		const message* message;
	PPCODE:
		queue = get_queue(object);
		if (message = queue_dequeue_nb(queue)) {
			message_to_stack(message, GIMME_V);
			destroy_message(message);
		}
		else
			XSRETURN_EMPTY;
