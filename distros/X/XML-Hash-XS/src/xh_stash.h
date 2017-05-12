#ifndef _XH_STASH_H_
#define _XH_STASH_H_

#include "xh_config.h"
#include "xh_core.h"

XH_INLINE void
xh_stash_push(xh_stack_t *stash, SV *value)
{
    SV **stash_item;
    stash_item = xh_stack_push(stash);
    *stash_item = value;
}

void xh_stash_clean(xh_stack_t *stash);

#endif /* _XH_STASH_H_ */
