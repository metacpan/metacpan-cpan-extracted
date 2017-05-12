#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "message.h"
#include "queue.h"
#include "mthread.h"
#include "resources.h"

int S_return_elements(pTHX_ AV* values, U32 context) {
	dSP;
	UV count;
	if (context == G_SCALAR) {
		SV** ret = av_fetch(values, 0, FALSE);
		PUSHs(ret ? *ret : &PL_sv_undef);
		count = 1;
	}
	else if (context == G_ARRAY) {
		count = av_len(values) + 1;
		EXTEND(SP, count);
		Copy(AvARRAY(values), SP + 1, count, SV*);
		SP += count;
	}
	PUTBACK;
	return count;
}

#define return_elements(entry, context) S_return_elements(aTHX_ entry, context)

MODULE = threads::lite             PACKAGE = threads::lite

PROTOTYPES: DISABLED

BOOT:
	global_init(aTHX);

SV*
spawn(options, startup)
	SV* options;
	SV* startup;
	INIT:
		HV* real_options;
	PPCODE:
		PUTBACK;
		real_options = SvROK(options) && SvTYPE(SvRV(options)) == SVt_PVHV ? (HV*) SvRV(options) : (HV*)sv_2mortal((SV*)newHV());
		create_push_threads(real_options, startup);
		SPAGAIN;


SV*
_receive()
	PREINIT:
		AV* ret;
	CODE:
		mthread* thread = get_self();
		const message* message = queue_dequeue(thread->queue, NULL);
		ret = message_to_array(message);
		destroy_message(message);
		RETVAL = newRV_noinc((SV*)ret);
	OUTPUT:
		RETVAL
	
SV*
_receive_nb()
	PREINIT:
		AV* ret;
	CODE:
		mthread* thread = get_self();
		const message* message = queue_dequeue_nb(thread->queue, NULL);
		if (message) {
			ret = message_to_array(message);
			destroy_message(message);
			RETVAL = newRV_noinc((SV*)ret);
		}
		else
			XSRETURN_EMPTY;
	OUTPUT:
		RETVAL

SV*
self()
	CODE:
		mthread* thread = get_self();
		SV** ret = hv_fetch(PL_modglobal, "threads::lite::self", 19, FALSE);
		RETVAL = SvREFCNT_inc_NN(*ret);
	OUTPUT:
		RETVAL

void
_return_elements(arg)
	SV* arg;
	PREINIT:
		AV* values;
	PPCODE:
		values = (AV*)SvRV(arg);
		if (GIMME_V == G_SCALAR) {
			SV** ret = av_fetch(values, 0, FALSE);
			PUSHs(ret ? *ret : &PL_sv_undef);
		}
		else if (GIMME_V == G_ARRAY) {
			UV count = av_len(values) + 1;
			EXTEND(SP, count);
			Copy(AvARRAY(values), SP + 1, count, SV*);
			SP += count;
		}

void
send_to(tid, ...)
	SV* tid;
	INIT:
		const message* message;
		UV thread_id;
	CODE:
		if (items == 1)
			Perl_croak(aTHX_ "Can't send an empty list\n");
		thread_id = SvUV(tid);
		message_from_stack(message, MARK + 1);
		thread_send(thread_id, message);

MODULE = threads::lite             PACKAGE = threads::lite::tid

PROTOTYPES: DISABLED

void
send(object, ...)
	SV* object;
	INIT:
		const message* message ;
		UV thread_id;
	CODE:
		if (items == 1)
			Perl_croak(aTHX_ "Can't send an empty list\n");
		thread_id = SvUV(SvRV(object));
		message_from_stack(message, MARK + 1);
		thread_send(thread_id, message);

void monitor(object)
	SV* object;
	CODE:
		thread_add_listener(aTHX, SvUV(SvRV(object)), get_self()->id);

MODULE = threads::lite             PACKAGE = threads::lite::queue

PROTOTYPES: DISABLED

SV*
new(class)
	SV* class;
	INIT:
		UV queue_id;
	CODE:
		queue_id = queue_alloc();
		RETVAL = newRV_noinc(newSVuv(queue_id));
		sv_bless(RETVAL, gv_stashsv(class, FALSE));
	OUTPUT:
		RETVAL

void
enqueue(object, ...)
	SV* object;
	INIT:
		const message* message;
		UV queue_id;
	CODE:
		if (items == 1)
			Perl_croak(aTHX_ "Can't send an empty list\n");
		queue_id = SvUV(SvRV(object));
		message_from_stack(message, MARK + 1);
		queue_send(queue_id, message);

void
dequeue(object)
	SV* object;
	INIT:
		const message* message;
		UV queue_id;
	PPCODE:
		queue_id = SvUV(SvRV(object));
		message = queue_receive(queue_id);
		message_to_stack(message, GIMME_V);
		destroy_message(message);

void
dequeue_nb(object)
	SV* object;
	INIT:
		const message* message;
		UV queue_id;
	PPCODE:
		queue_id = SvUV(SvRV(object));
		if (message = queue_receive_nb(queue_id)) {
			message_to_stack(message, GIMME_V);
			destroy_message(message);
		}
		else
			XSRETURN_EMPTY;
