#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"

#include "message.h"
#include "queue.h"

/*
 * Message queues
 */

typedef struct {
	message_queue parent;
	perl_mutex mutex;
	perl_cond condvar;
	message* front;
	message* back;
} message_queue_impl ;

static void node_unshift(message** position, message* new_node) {
	new_node->next = *position;
	*position = new_node;
}

static const message* node_shift(message** position) {
	message* ret = *position;
	*position = (*position)->next;
	ret->next = NULL;
	return ret;
}

static void node_push(message** end, message* new_node) {
	message** cur = end;
	while(*cur)
		cur = &(*cur)->next;
	*end = *cur = new_node;
	new_node->next = NULL;
}

static void S_node_destroy(pTHX_ message** current) {
	while (*current != NULL) {
		message** next = &(*current)->next;
		destroy_message(*current);
		*current = NULL;
		current = next;
	}
}
#define node_destroy(current) S_node_destroy(aTHX_ current)

static void S_queue_enqueue(pTHX_ message_queue* _queue, const message* message_, perl_mutex* external_lock) {
	message_queue_impl* queue = (message_queue_impl*) _queue;
	message* new_entry;
	MUTEX_LOCK(&queue->mutex);
	if (external_lock)
		MUTEX_UNLOCK(external_lock);

	node_push(&queue->back, (message*)message_);
	if (queue->front == NULL)
		queue->front = queue->back;

	COND_SIGNAL(&queue->condvar);
	MUTEX_UNLOCK(&queue->mutex);
}

static const message* queue_shift(message_queue_impl* _queue) {
	message_queue_impl* queue = (message_queue_impl*) _queue;
	const message* ret = node_shift(&queue->front);

	if (queue->front == NULL)
		queue->back = NULL;
	return ret;
}

static const message* S_queue_dequeue(pTHX_ message_queue* _queue, perl_mutex* external_lock) {
	message_queue_impl* queue = (message_queue_impl*) _queue;
	const message* ret;
	MUTEX_LOCK(&queue->mutex);
	if (external_lock)
		MUTEX_UNLOCK(external_lock);

	while (!queue->front)
		COND_WAIT(&queue->condvar, &queue->mutex);

	ret = queue_shift(queue);
	MUTEX_UNLOCK(&queue->mutex);

	return ret;
}

static const message* S_queue_dequeue_nb(pTHX_ message_queue* _queue, perl_mutex* external_lock) {
	message_queue_impl* queue = (message_queue_impl*) _queue;
	MUTEX_LOCK(&queue->mutex);
	if (external_lock)
		MUTEX_UNLOCK(external_lock);

	if (queue->front) {
		const message* ret = queue_shift(queue);

		MUTEX_UNLOCK(&queue->mutex);
		return ret;
	}
	else {
		MUTEX_UNLOCK(&queue->mutex);
		return NULL;
	}
}

static void S_queue_destroy(pTHX_ message_queue* _queue) {
	message_queue_impl* queue = (message_queue_impl*) _queue;
	MUTEX_LOCK(&queue->mutex);
	node_destroy(&queue->front);
	COND_DESTROY(&queue->condvar);
	MUTEX_UNLOCK(&queue->mutex);
	MUTEX_DESTROY(&queue->mutex);
	PerlMemShared_free(queue);
}

const message_queue_vtable simple_table = {
	S_queue_enqueue,
	S_queue_dequeue,
	S_queue_dequeue_nb,
	S_queue_destroy
};

message_queue* S_queue_simple_alloc(pTHX) {
	message_queue_impl* ret = PerlMemShared_calloc(1, sizeof(message_queue_impl));
	Zero(ret, 1, message_queue);
	ret->parent.table = &simple_table;
	MUTEX_INIT(&ret->mutex);
	COND_INIT(&ret->condvar);
	return (message_queue*)ret;
}
