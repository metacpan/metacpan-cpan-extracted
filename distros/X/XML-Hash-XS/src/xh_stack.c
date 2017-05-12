#include "xh_config.h"
#include "xh_core.h"

void
xh_stack_init(xh_stack_t *st, xh_uint_t nelts, size_t size)
{
    if ((st->elts = malloc(nelts * size)) == NULL) {
        croak("Memory allocation error");
    }
    st->size  = size;
    st->nelts = nelts;
    st->top   = 0;
}

void
xh_stack_destroy(xh_stack_t *st)
{
    free(st->elts);
}
