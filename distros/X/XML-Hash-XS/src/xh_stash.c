#include "xh_config.h"
#include "xh_core.h"

void
xh_stash_clean(xh_stack_t *stash)
{
    SV **value;
    while ((value = xh_stack_pop(stash)) != NULL) {
        SvREFCNT_dec(*value);
    }

    xh_stack_destroy(stash);
}
