#ifndef PZK_DEQUEUE_H_
#define PZK_DEQUEUE_H_
#include <stdlib.h>
#include <pthread.h>

struct pzk_dequeue_node {
    struct pzk_dequeue_node* prev;
    struct pzk_dequeue_node* next;
    void*                    value;
};
typedef struct pzk_dequeue_node pzk_dequeue_node_t;

typedef struct pzk_dequeue {
    pzk_dequeue_node_t* first;
    pzk_dequeue_node_t* last;
    size_t              size;
    pthread_mutex_t*    mutex;

    int   (*push)    (struct pzk_dequeue*, void*);
    void* (*pop)     (struct pzk_dequeue*);
    int   (*unshift) (struct pzk_dequeue*, void*);
    void* (*shift)   (struct pzk_dequeue*);
    void  (*destroy) (struct pzk_dequeue*);
} pzk_dequeue_t;

pzk_dequeue_t* new_pzk_dequeue();
#endif // ifndef PZK_DEQUEUE_H_
