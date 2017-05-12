#include <pzk_dequeue.h>

static pzk_dequeue_node_t* _new_pzk_dequeue_node(void* val) {
    pzk_dequeue_node_t* node = (pzk_dequeue_node_t*) calloc(1, sizeof(pzk_dequeue_node_t));
    node->value = val;
    return node;
}
static void _destroy_pzk_dequeue_node(pzk_dequeue_node_t* node) {
    if (node) free(node);
}

static int pzk_dequeue_push(pzk_dequeue_t* dq, void* val) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* new = _new_pzk_dequeue_node(val);    

    pzk_dequeue_node_t* last = dq->last;
    if (last) {
        last->next = new;
        new->prev  = last;
        dq->last = new;
    } else {
        dq->first = dq->last = new;
    }
    dq->size++;

    pthread_mutex_unlock(dq->mutex);
    return 0;
}

static int pzk_dequeue_unshift(pzk_dequeue_t* dq, void* val) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* new = _new_pzk_dequeue_node(val);    

    pzk_dequeue_node_t* first = dq->first;
    if (first) {
        first->prev = new;
        new->next   = first;
        dq->first = new;
    } else {
        dq->first = dq->last = new;
    }
    dq->size++;

    pthread_mutex_unlock(dq->mutex);
    return 0;
}

static void* pzk_dequeue_pop(pzk_dequeue_t* dq) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* node;
    pzk_dequeue_node_t* last = dq->last;
    if (!last) {
        pthread_mutex_unlock(dq->mutex);
        return NULL;
    }

    pzk_dequeue_node_t* prev = last->prev;
    if (prev) {
        prev->next = NULL;
        dq->last = prev;
    } else {
        dq->first = dq->last = NULL;
    }

    void* value = last->value;
    _destroy_pzk_dequeue_node(last);

    dq->size--;
    pthread_mutex_unlock(dq->mutex);
    return value;
}

static void* pzk_dequeue_shift(pzk_dequeue_t* dq) {
    pthread_mutex_lock(dq->mutex);
    pzk_dequeue_node_t* node;
    pzk_dequeue_node_t* first = dq->first;
    if (!first) {
        pthread_mutex_unlock(dq->mutex);
        return NULL;
    }

    pzk_dequeue_node_t* next = first->next;
    if (next) {
        next->prev = NULL;
        dq->first  = next;
    } else {
        dq->first = dq->last = NULL;
    }

    void* value = first->value;
    _destroy_pzk_dequeue_node(first);

    dq->size--;
    pthread_mutex_unlock(dq->mutex);
    return value;
}

static void destroy_pzk_dequeue(pzk_dequeue_t* dq) {
    size_t size = dq->size;
    pzk_dequeue_node_t* node;

    if (size) {
        int i;
        for (i = 0, node = dq->first; i < size; i++) {
            pzk_dequeue_node_t* next = node->next;
            _destroy_pzk_dequeue_node(node);
            node = next;
        }
    }

    if (dq->mutex) {
        pthread_mutex_destroy(dq->mutex);
        free(dq->mutex);
    }

    free(dq);
}

pzk_dequeue_t* new_pzk_dequeue() {
    pzk_dequeue_t* dq = (pzk_dequeue_t*) calloc(1, sizeof(pzk_dequeue_t));
    dq->mutex = (pthread_mutex_t*) calloc(1, sizeof(pthread_mutex_t));
    pthread_mutex_init(dq->mutex, NULL);

    dq->push    = pzk_dequeue_push;
    dq->pop     = pzk_dequeue_pop;
    dq->unshift = pzk_dequeue_unshift;
    dq->shift   = pzk_dequeue_shift;
    dq->destroy = destroy_pzk_dequeue;

    return dq;
}

