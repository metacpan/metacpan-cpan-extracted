#include "promise.h"
void global_init(pTHX);
Promise* S_thread_spawn(pTHX_ AV* to_run);
#define thread_spawn(to_run) S_thread_spawn(aTHX_ to_run)
