#ifndef PZK_PIPE_DISPATCHER_H_
#define PZK_PIPE_DISPATCHER_H_
#include "pzk_dispatcher.h"

struct pzk_pipe_dispatcher {
    pzk_dispatcher_t base;
    int fd[2];
    int (*read_pipe)  (struct pzk_pipe_dispatcher*);
    int (*write_pipe) (struct pzk_pipe_dispatcher*);
    void (*destroy)   (struct pzk_pipe_dispatcher*);
};
typedef struct pzk_pipe_dispatcher pzk_pipe_dispatcher_t;

pzk_pipe_dispatcher_t* new_pzk_pipe_dispatcher(pzk_channel_t*);

#endif // ifndef PZK_PIPE_DISPATCHER_H_
