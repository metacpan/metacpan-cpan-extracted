typedef message queue_node;

typedef struct {
#ifdef USE_ITHREADS
	perl_mutex mutex;
	perl_cond condvar;
#endif
	message* front;
	message* back;
	IV refcount;
} message_queue;

void queue_init(message_queue*);
void S_queue_enqueue(pTHX_ message_queue* queue, const message* message);
#define queue_enqueue(queue, message) S_queue_enqueue(aTHX_ queue, message)
const message* S_queue_dequeue(pTHX_ message_queue* queue);
#define queue_dequeue(queue) S_queue_dequeue(aTHX_ queue)
const message* S_queue_dequeue_nb(pTHX_ message_queue* queue);
#define queue_dequeue_nb(queue) S_queue_dequeue_nb(aTHX_ queue)
void S_queue_destroy(pTHX_ message_queue*);
#define queue_destroy(queue) S_queue_destroy(aTHX_ queue)
