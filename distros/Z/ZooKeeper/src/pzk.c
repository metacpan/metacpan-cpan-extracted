#include <pzk.h>
#include <stdlib.h>

static void close_pzk(pzk_t* pzk) {
   if (!pzk->handle) return;

   if (pzk->pid == getpid()) {
        zookeeper_close(pzk->handle);
   } else {
       // if this is the child after a fork
       // never call zookeeper_close
       // it might try to use mutexes from a prefork thread and hang
       // instead just close the socket the handle was using
       int fd = ((int*)pzk->handle)[0];
        close(fd);
   }
   pzk->handle = NULL;
}

static void destroy_pzk(pzk_t* pzk) {
    pzk->close(pzk);
    free(pzk);
}

pzk_t* new_pzk(zhandle_t* handle) {
    pzk_t* pzk   = (pzk_t*) calloc(1, sizeof(pzk_t));
    pzk->handle  = handle;
    pzk->pid     = getpid();

    pzk->close   = close_pzk;
    pzk->destroy = destroy_pzk;
    return pzk;
}


