#include <pzk_interrupt_dispatcher.h>
#include <stdlib.h>

static void pzk_interrupt_dispatcher_notify(pzk_dispatcher_t*);
static void destroy_pzk_interrupt_dispatcher(pzk_interrupt_dispatcher_t*);

pzk_interrupt_dispatcher_t* new_pzk_interrupt_dispatcher(pzk_channel_t* channel, interrupt_fn cb, void* arg) {
    pzk_interrupt_dispatcher_t* dispatcher = (pzk_interrupt_dispatcher_t*) calloc(1, sizeof(pzk_interrupt_dispatcher_t));
    dispatcher->base.channel  = channel;
    dispatcher->base.notify   = pzk_interrupt_dispatcher_notify;
    dispatcher->interrupt_cb  = cb;
    dispatcher->interrupt_arg = arg;
    dispatcher->destroy       = destroy_pzk_interrupt_dispatcher;

    return dispatcher;
}

void destroy_pzk_interrupt_dispatcher(pzk_interrupt_dispatcher_t* dispatcher) {
    free(dispatcher);
}

void pzk_interrupt_dispatcher_notify(pzk_dispatcher_t* _dispatcher) {
    pzk_interrupt_dispatcher_t* dispatcher = (pzk_interrupt_dispatcher_t*) _dispatcher;
    dispatcher->interrupt_cb(dispatcher->interrupt_arg, 0);
}

