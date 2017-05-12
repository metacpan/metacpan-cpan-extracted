#ifndef PZK_DISPATCHER_H_
#define PZK_DISPATCHER_H_
#include "pzk_channel.h"
#include <zookeeper/zookeeper.h>

struct pzk_dispatcher {
    pzk_channel_t* channel;
    void (*notify) (struct pzk_dispatcher*);
};
typedef struct pzk_dispatcher pzk_dispatcher_t;

typedef void (*pzk_dispatcher_notify_fn) (struct pzk_dispatcher*);

typedef struct {
    pzk_dispatcher_t* dispatcher;
    void*             ctx;
} pzk_watcher_t;

typedef struct pzk_event {
    int   type;
    int   state;
    char* path;
    void* arg;

    void (*destroy) (struct pzk_event*);
} pzk_event_t;

void pzk_watcher_cb(
    zhandle_t*  zh,
    int         type,
    int         state,
    const char* path,
    void*       watcherCtx
);

void pzk_auth_cb(int ret, const void* data);

pzk_event_t* new_pzk_event(
    int         type,
    int         state,
    const char* path,
    void*       arg
);

#endif // ifndef PZK_DISPATCHER_H_
