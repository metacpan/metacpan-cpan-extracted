struct _message_queue;
typedef struct _message_queue message_queue;

typedef struct {
	void (*enqueue)(pTHX_ message_queue* queue, const message* message, perl_mutex* lock);
	const message* (*dequeue)(pTHX_ message_queue* queue, perl_mutex* lock);
	const message* (*dequeue_nb)(pTHX_ message_queue* queue, perl_mutex* lock);
	void (*destroy)(pTHX_ message_queue*);
} message_queue_vtable;

struct _message_queue {
	const message_queue_vtable* table;
};

message_queue* S_queue_simple_alloc(pTHX);
#define queue_simple_alloc() S_queue_simple_alloc(aTHX)
#define queue_enqueue(queue, message, lock) ((queue)->table->enqueue)(aTHX_ queue, message, lock)
#define queue_dequeue(queue, lock) ((queue)->table->dequeue)(aTHX_ queue, lock)
#define queue_dequeue_nb(queue, lock) ((queue)->table->dequeue_nb)(aTHX_ queue, lock)
#define queue_destroy(queue) ((queue)->table->destroy)(aTHX_ queue)
