#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

#include "refcount.h"
#include "values.h"
#include "notification.h"

#include "promise.h"

enum state { HAS_NOTHING, HAS_READER, HAS_WRITER, HAS_BOTH, ABANDONED, DONE };
enum value_type { VALUE, EXCEPTION };

struct promise {
	perl_mutex mutex;
	perl_cond condvar;
	PerlInterpreter* owner;
	SV* value;
	enum value_type type;
	enum state state;
	Refcount refcount;
	Notification notification;
};

Promise* promise_alloc(UV refcount) {
	Promise* result = calloc(1, sizeof(Promise));
	MUTEX_INIT(&result->mutex);
	COND_INIT(&result->condvar);
	refcount_init(&result->refcount, refcount);
	notification_init(&result->notification);
	return result;
}

SV* S_promise_get(pTHX_ Promise* promise) {
	MUTEX_LOCK(&promise->mutex);

	SV* result;
	switch (promise->state) {
		case HAS_NOTHING:
			promise->state = HAS_READER;
			do COND_WAIT(&promise->condvar, &promise->mutex);
			while (promise->state != HAS_BOTH);
		case HAS_WRITER:
			promise->value = clone_value(promise->value);
			promise->state = DONE;
			promise->owner = aTHX;
			COND_SIGNAL(&promise->condvar);
		case DONE:
			result = SvREFCNT_inc(promise->value);
			break;

		default:
			result = &PL_sv_undef;
			break;
	}

	enum value_type type = promise->type;
	MUTEX_UNLOCK(&promise->mutex);

	if (type == EXCEPTION)
		croak_sv(result);
	else
		return result;
}

static void promise_set(Promise* promise, SV* value, enum value_type type) {
	MUTEX_LOCK(&promise->mutex);

	if (promise->state != DONE && promise->state != ABANDONED) {
		promise->value = value;
		promise->type = type;

		if (promise->state == HAS_READER) {
			promise->state = HAS_BOTH;
			COND_SIGNAL(&promise->condvar);
		}
		else {
			assert(promise->state == HAS_NOTHING);
			promise->state = HAS_WRITER;
			notification_trigger(&promise->notification);
		}

		do COND_WAIT(&promise->condvar, &promise->mutex);
		while (promise->state != DONE && promise->state != ABANDONED);
	}
	MUTEX_UNLOCK(&promise->mutex);
}

void promise_set_value(Promise* promise, SV* value) {
	promise_set(promise, value, VALUE);
}
void promise_set_exception(Promise* promise, SV* value) {
	promise_set(promise, value, EXCEPTION);
}

bool promise_is_finished(Promise* promise) {
	MUTEX_LOCK(&promise->mutex);
	bool result = promise->state == DONE || promise->state == HAS_WRITER;
	MUTEX_UNLOCK(&promise->mutex);
	return result;
}

void promise_refcount_dec(Promise* promise) {
	if (refcount_dec(&promise->refcount) == 1) {
		COND_DESTROY(&promise->condvar);
		MUTEX_DESTROY(&promise->mutex);
		refcount_destroy(&promise->refcount);
		free(promise);
	}
}

static int promise_destroy(pTHX_ SV* sv, MAGIC* magic) {
	Promise* promise = (Promise*)magic->mg_ptr;
	MUTEX_LOCK(&promise->mutex);
	if (promise->owner == aTHX) {
		notification_unset(&promise->notification);
		switch(promise->state) {
			case HAS_WRITER:
				COND_SIGNAL(&promise->condvar);
			case HAS_NOTHING:
				promise->state = ABANDONED;
				break;

			case DONE:
				SvREFCNT_dec(promise->value);
				break;
		}
	}
	MUTEX_UNLOCK(&promise->mutex);
	promise_refcount_dec(promise);
	return 0;
}

static const MGVTBL promise_magic = { 0, 0, 0, 0, promise_destroy };

static PerlIO* S_sv_to_handle(pTHX_ SV* handle) {
	if (!SvROK(handle) || SvTYPE(SvRV(handle)) != SVt_PVGV)
		Perl_croak(aTHX_ "");

	return IoOFP(sv_2io(handle));
}
#define sv_to_handle(handle) S_sv_to_handle(aTHX_ handle)

void S_promise_set_notify(pTHX_ SV* promise_sv, SV* handle, SV* value) {
	MAGIC* magic = sv_to_magic(promise_sv, "Thread::Csp::Promise", &promise_magic);
	Promise* promise = magic_to_object(magic);

	MUTEX_LOCK(&promise->mutex);

	notification_set(&promise->notification, sv_to_handle(handle), value);
	if (promise->state == HAS_WRITER || promise->state == DONE)
		notification_trigger(&promise->notification);

	MUTEX_UNLOCK(&promise->mutex);

	magic->mg_obj = SvREFCNT_inc(handle);
	magic->mg_flags |= MGf_REFCOUNTED;
}

SV* S_promise_to_sv(pTHX_ Promise* promise) {
	return object_to_sv(promise, gv_stashpvs("Thread::Csp::Promise", 0), &promise_magic, 0);
}

Promise* S_sv_to_promise(pTHX_ SV* sv) {
	return sv_to_object(sv, "Thread::Csp::Promise", &promise_magic);
}
