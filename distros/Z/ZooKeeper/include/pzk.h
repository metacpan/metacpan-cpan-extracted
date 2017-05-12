#ifndef PZK_H_
#define PZK_H_
#include <unistd.h>
#include <zookeeper/zookeeper.h>

typedef struct pzk {
    zhandle_t* handle;
    pid_t      pid;
    void (*close)   (struct pzk*);
    void (*destroy) (struct pzk*);
} pzk_t;

pzk_t* new_pzk(zhandle_t*);

#endif // ifndef PZK_H_
