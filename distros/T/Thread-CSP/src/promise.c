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
	PerlInterpreter* from;
	SV* value;
	SV* notifier;
	enum value_type type;
	enum state state;
	Refcount refcount;
	Notification notification;
};

struct promise* S_promise_alloc(pTHX_ UV refcount) {
	struct promise* result = PerlMemShared_calloc(1, sizeof(struct promise));
	MUTEX_INIT(&result->mutex);
	COND_INIT(&result->condvar);
	refcount_init(&result->refcount, refcount);
	notification_init(&result->notification);
	return result;
}

SV* S_promise_get(pTHX_ struct promise* promise) {
	MUTEX_LOCK(&promise->mutex);

	SV* result;
	switch (promise->state) {
		case HAS_NOTHING:
			promise->state = HAS_READER;
			do COND_WAIT(&promise->condvar, &promise->mutex);
			while (promise->state != HAS_BOTH);
		case HAS_WRITER:
			promise->value = clone_value(promise->value, promise->from);
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

static void S_promise_set(pTHX_ struct promise* promise, SV* value, enum value_type type) {
	MUTEX_LOCK(&promise->mutex);

	if (promise->state != DONE && promise->state != ABANDONED) {
		promise->value = value;
		promise->type = type;
		promise->from = aTHX;

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
		promise->from = NULL;
	}
	MUTEX_UNLOCK(&promise->mutex);
}
#define promise_set(promise, value, type) S_promise_set(aTHX_ promise, value, type)

void S_promise_set_value(pTHX_ struct promise* promise, SV* value) {
	promise_set(promise, value, VALUE);
}
void S_promise_set_exception(pTHX_ struct promise* promise, SV* value) {
	promise_set(promise, value, EXCEPTION);
}

bool promise_is_finished(struct promise* promise) {
	MUTEX_LOCK(&promise->mutex);
	bool result = promise->state == DONE || promise->state == HAS_WRITER;
	MUTEX_UNLOCK(&promise->mutex);
	return result;
}

void S_promise_refcount_dec(pTHX_ struct promise* promise) {
	if (refcount_dec(&promise->refcount) == 1) {
		COND_DESTROY(&promise->condvar);
		MUTEX_DESTROY(&promise->mutex);
		refcount_destroy(&promise->refcount);
		PerlMemShared_free(promise);
	}
}

static int promise_destroy(pTHX_ SV* sv, MAGIC* magic) {
	struct promise* promise = (struct promise*)magic->mg_ptr;
	MUTEX_LOCK(&promise->mutex);
	notification_unset(&promise->notification);
	if (promise->owner == aTHX) {
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
		if (promise->notifier)
			SvREFCNT_dec(promise->notifier);
	}
	MUTEX_UNLOCK(&promise->mutex);
	promise_refcount_dec(promise);
	return 0;
}

const MGVTBL Thread__CSP__Promise_magic = {
	.svt_free = promise_destroy
};


static PerlIO* S_sv_to_handle(pTHX_ SV* handle) {
	if (!SvROK(handle) || SvTYPE(SvRV(handle)) != SVt_PVGV)
		Perl_croak(aTHX_ "");

	return IoOFP(sv_2io(handle));
}
#define sv_to_handle(handle) S_sv_to_handle(aTHX_ handle)

SV* S_promise_finished_fh(pTHX_ struct promise* promise) {
	MUTEX_LOCK(&promise->mutex);

	if (!promise->notifier) {
		promise->notifier = notification_create(&promise->notification);
		if (promise->state == HAS_WRITER || promise->state == DONE)
			notification_trigger(&promise->notification);
	}

	MUTEX_UNLOCK(&promise->mutex);

	return promise->notifier;
}
