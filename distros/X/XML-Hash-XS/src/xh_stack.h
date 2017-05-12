#ifndef _XH_STACK_H_
#define _XH_STACK_H_

#include "xh_config.h"
#include "xh_core.h"

typedef struct {
    void             *elts;
    size_t            size;
    size_t            nelts;
    size_t            top;
} xh_stack_t;

XH_INLINE void *
xh_stack_push(xh_stack_t *st)
{
    if (st->top >= st->nelts) {
        st->nelts *= 2;
        if ((st->elts = realloc(st->elts, st->nelts * st->size)) == NULL) {
            croak("Memory allocation error");
        }
    }
    return (void *) (XH_CHAR_CAST st->elts + st->top++ * st->size);
}

XH_INLINE void *
xh_stack_pop(xh_stack_t *st)
{
    return st->top == 0 ? NULL : (void *) (XH_CHAR_CAST st->elts + --st->top * st->size);
}

XH_INLINE xh_bool_t
xh_stack_empty(xh_stack_t *st)
{
    return st->top == 0 ? TRUE : FALSE;
}

void xh_stack_init(xh_stack_t *st, xh_uint_t nelts, size_t size);
void xh_stack_destroy(xh_stack_t *st);

#endif /* _XH_STACK_H_ */
