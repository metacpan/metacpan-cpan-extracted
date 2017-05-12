#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"

#include "message.h"
#include "queue.h"
#include "mthread.h"
#include "resources.h"

#include "tables.h"

#ifdef __MSVC__
#define __thread __declspec(thread)
#endif

/*
 * !!! global data !!!
 */

bool inited = 0;

static thread_table* threads;
static perl_mutex threads_lock;
static queue_table* queues;
static perl_mutex queues_lock;

static struct {
	perl_mutex mutex;
	perl_cond condvar;
	int count;
} counter;

static void wait_for_all_other_threads() {
	MUTEX_LOCK(&counter.mutex);
	while (counter.count > 1)
		COND_WAIT(&counter.condvar, &counter.mutex);

	MUTEX_UNLOCK(&counter.mutex);
	MUTEX_DESTROY(&counter.mutex);
	COND_DESTROY(&counter.condvar);
}

static XSPROTO(end_locker) {
	dVAR; dXSARGS;
	perl_mutex* mutex;

	wait_for_all_other_threads();
	thread_db_free(threads);

	mutex = get_shutdown_mutex();
	MUTEX_LOCK(mutex);
	XSRETURN_EMPTY;
}

static void end_unlocker() {
	perl_mutex* mutex = get_shutdown_mutex();
	MUTEX_UNLOCK(mutex);
}

void global_init(pTHX) {
	if (!inited) {
		mthread* ret;

		inited = TRUE;

		MUTEX_INIT(&counter.mutex);
		COND_INIT(&counter.condvar);
		counter.count = 0;

		threads = thread_db_new(TRUE);
		MUTEX_INIT(&threads_lock);
		queues = queue_db_new(TRUE);
		MUTEX_INIT(&queues_lock);
		ret = mthread_alloc(aTHX);
		ret->interp = my_perl;
		store_self(aTHX, ret);

		/* This is a nasty trick to make sure locking is performed during part of the destruct */
		newXS("END", end_locker, __FILE__);
		atexit(end_unlocker);
	}
}

static __thread thread_table* threads_local;
mthread* mthread_alloc(PerlInterpreter* my_perl) {
	mthread* ret;
	UV id;

	MUTEX_LOCK(&counter.mutex);
	id = generator();
	counter.count++;
	MUTEX_UNLOCK(&counter.mutex);

	ret = PerlMemShared_calloc(1, sizeof *ret);
	ret->queue = queue_simple_alloc();

	thread_db_store(threads, id, ret);
	ret->id = id;
	ret->interp = NULL;
	ret->cache = NULL;
	ret->alive = 1;
	MUTEX_INIT(&ret->lock);
	return ret;
}

void mthread_destroy(mthread* thread) {
	PerlInterpreter* my_perl = thread->interp;
	MUTEX_LOCK(&thread->lock);
	thread->alive = 0;
	queue_destroy(thread->queue);
	MUTEX_UNLOCK(&thread->lock);

	MUTEX_DESTROY(&thread->lock);

	MUTEX_LOCK(&counter.mutex);
	counter.count--;
	COND_SIGNAL(&counter.condvar);
	MUTEX_UNLOCK(&counter.mutex);
}

static mthread* S_get_thread(pTHX_ UV id) {
	mthread* ret;
	if (threads_local == NULL);
		threads_local = thread_db_new(FALSE);
	ret = thread_db_fetch(threads_local, id);
	if (!ret) {
		MUTEX_LOCK(&threads_lock);
		ret = thread_db_fetch(threads, id);
		if (ret)
			thread_db_incref(threads, id);
		MUTEX_UNLOCK(&threads_lock);
		if (!ret)
			Perl_croak(aTHX_  "Thread %"UVuf" doesn't exist", id);
	}
	if (!ret->alive)
		Perl_croak(aTHX_ "Thread is no longer alive");
	return ret;
}

#define get_thread(id) S_get_thread(aTHX_ id)

UV S_queue_alloc(pTHX) {
	message_queue* queue = queue_simple_alloc();
	UV id = generator();
	queue_db_store(queues, id, queue);
	return id;
}

#define get_queue(id) queue_db_fetch(queues, id)

#define THREAD_TRY \
	XCPT_TRY_START

#define THREAD_CATCH_FINALLY(catch, finally) \
	XCPT_TRY_END;\
	finally;\
	XCPT_CATCH { catch; XCPT_RETHROW; }

#define THREAD_CATCH(undo) THREAD_CATCH_FINALLY(undo, 0)

#define THREAD_FINALLY(undo) THREAD_CATCH_FINALLY(0, undo)


void S_thread_send(pTHX_ UV thread_id, const message* message) {
	dXCPT;

	mthread* thread = get_thread(thread_id);
	queue_enqueue(thread->queue, message, NULL);
}

void S_queue_send(pTHX_ UV queue_id, const message* message) {
	dXCPT;

	MUTEX_LOCK(&queues_lock);
	THREAD_TRY {
		message_queue* queue = get_queue(queue_id);
		queue_enqueue(queue, message, &queues_lock);
	} THREAD_CATCH( MUTEX_UNLOCK(&queues_lock) );
}

const message* S_queue_receive(pTHX_ UV queue_id) {
	dXCPT;
	const message* ret;

	MUTEX_LOCK(&queues_lock);
	THREAD_TRY {
		message_queue* queue = get_queue(queue_id);
		ret = queue_dequeue(queue, &queues_lock);
	} THREAD_CATCH( MUTEX_UNLOCK(&queues_lock) );

	return ret;
}

const message* S_queue_receive_nb(pTHX_ UV queue_id) {
	dXCPT;
	const message* ret;

	MUTEX_LOCK(&queues_lock);
	THREAD_TRY {
		message_queue* queue = get_queue(queue_id);
		ret = queue_dequeue_nb(queue, &queues_lock);
	} THREAD_CATCH( MUTEX_UNLOCK(&queues_lock) );
	return ret;
}

void S_send_listeners(pTHX_ mthread* thread, const message* mess) {
	int i;
	dXCPT;

	MUTEX_LOCK(&thread->lock);
	for (i = 0; i < thread->listeners.head; ++i) {
		const message* clone;
		UV thread_id;
		mthread* receptient;

		MUTEX_LOCK(&threads_lock); /* unlocked by queue_enqueue */
		thread_id = thread->listeners.list[i];
		receptient = thread_db_fetch(threads, thread_id);
		if (receptient == NULL)
			continue;
		clone = message_clone(mess);
		queue_enqueue(receptient->queue, clone, &threads_lock);
	}
	MUTEX_UNLOCK(&thread->lock);
}

#define send_listeners(thread, message) S_send_listeners(aTHX_ thread, message)

void thread_add_listener(pTHX, UV talker, UV listener) {
	dXCPT;

	mthread* thread = get_thread(talker);
	MUTEX_LOCK(&thread->lock);
	THREAD_TRY {
		if (thread->listeners.alloc == thread->listeners.head) {
			thread->listeners.alloc = thread->listeners.alloc ? thread->listeners.alloc * 2 : 1;
			thread->listeners.list = PerlMemShared_realloc(thread->listeners.list, sizeof(IV) * thread->listeners.alloc);
		}
		thread->listeners.list[thread->listeners.head++] = listener;
	} THREAD_FINALLY( MUTEX_UNLOCK(&thread->lock) );
}

