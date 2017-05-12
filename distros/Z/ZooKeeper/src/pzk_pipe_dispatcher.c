#include <pzk_pipe_dispatcher.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

static void pzk_pipe_dispatcher_notify(pzk_dispatcher_t*);
static int  pzk_pipe_dispatcher_read(pzk_pipe_dispatcher_t*);
static int  pzk_pipe_dispatcher_write(pzk_pipe_dispatcher_t*);
static void destroy_pzk_pipe_dispatcher(pzk_pipe_dispatcher_t*);

pzk_pipe_dispatcher_t* new_pzk_pipe_dispatcher(pzk_channel_t* channel) {
    pzk_pipe_dispatcher_t* dispatcher = (pzk_pipe_dispatcher_t*) calloc(1, sizeof(pzk_pipe_dispatcher_t));
    dispatcher->base.channel = channel;
    dispatcher->base.notify  = pzk_pipe_dispatcher_notify;
    dispatcher->read_pipe    = pzk_pipe_dispatcher_read;
    dispatcher->write_pipe   = pzk_pipe_dispatcher_write;
    dispatcher->destroy      = destroy_pzk_pipe_dispatcher;

    if (pipe(dispatcher->fd) >= 0) {
        fcntl(dispatcher->fd[0], F_SETFL, O_NONBLOCK);
        fcntl(dispatcher->fd[1], F_SETFL, O_NONBLOCK);
    } else {
        free(dispatcher);
        return NULL;
    }

    return dispatcher;
}

void destroy_pzk_pipe_dispatcher(pzk_pipe_dispatcher_t* dispatcher) {
    close(dispatcher->fd[0]);
    close(dispatcher->fd[1]);
    free(dispatcher);
}

void pzk_pipe_dispatcher_notify(pzk_dispatcher_t* _dispatcher) {
    pzk_pipe_dispatcher_t* dispatcher = (pzk_pipe_dispatcher_t*) _dispatcher;
    dispatcher->write_pipe(dispatcher);
}

int pzk_pipe_dispatcher_read(pzk_pipe_dispatcher_t* dispatcher) {
    char buf[1];
    return read(dispatcher->fd[0], buf, 1);
}

int pzk_pipe_dispatcher_write(pzk_pipe_dispatcher_t* dispatcher) {
   return write(dispatcher->fd[1], "", sizeof(char));
}

