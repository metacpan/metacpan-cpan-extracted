#ifndef PZK_INTERRUPT_DISPATCHER_H_
#define PZK_INTERRUPT_DISPATCHER_H_
#include "pzk_dispatcher.h"

typedef void (*interrupt_fn) (void*, int);

typedef struct pzk_interrupt_dispatcher {
    pzk_dispatcher_t base;
    void*            interrupt_arg;
    interrupt_fn     interrupt_cb;
    void (*destroy) (struct pzk_interrupt_dispatcher*);
} pzk_interrupt_dispatcher_t;

pzk_interrupt_dispatcher_t* new_pzk_interrupt_dispatcher(pzk_channel_t*, interrupt_fn, void*);

#endif // ifndef PZK_INTERRUPT_DISPATCHER_H_
