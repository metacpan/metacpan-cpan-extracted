#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"

#include "message.h"
#include "queue.h"

/*
 * Message queues
 */

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

void queue_init(message_queue* queue) {
	Zero(queue, 1, message_queue);
	MUTEX_INIT(&queue->mutex);
	COND_INIT(&queue->condvar);
	queue->refcount = 1;
}

void S_queue_enqueue(pTHX_ message_queue* queue, const message* message_) {
	message* new_entry;
	MUTEX_LOCK(&queue->mutex);

	node_push(&queue->back, (message*)message_);
	if (queue->front == NULL)
		queue->front = queue->back;

	COND_SIGNAL(&queue->condvar);
	MUTEX_UNLOCK(&queue->mutex);
}

static const message* queue_shift(message_queue* queue) {
	const message* ret = node_shift(&queue->front);

	if (queue->front == NULL)
		queue->back = NULL;
	return ret;
}

const message* S_queue_dequeue(pTHX_ message_queue* queue) {
	const message* ret;
	MUTEX_LOCK(&queue->mutex);

	while (!queue->front)
		COND_WAIT(&queue->condvar, &queue->mutex);

	ret = queue_shift(queue);
	MUTEX_UNLOCK(&queue->mutex);

	return ret;
}

const message* S_queue_dequeue_nb(pTHX_ message_queue* queue) {
	MUTEX_LOCK(&queue->mutex);

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

void S_queue_destroy(pTHX_ message_queue* queue) {
	MUTEX_LOCK(&queue->mutex);
	node_destroy(&queue->front);
	COND_DESTROY(&queue->condvar);
	MUTEX_UNLOCK(&queue->mutex);
	MUTEX_DESTROY(&queue->mutex);
}
