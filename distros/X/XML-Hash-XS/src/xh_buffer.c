#include "xh_config.h"
#include "xh_core.h"

void
xh_buffer_init(xh_buffer_t *buf, size_t size)
{
    buf->start = buf->cur = malloc(size);
    if (buf->start == NULL) {
        croak("Memory allocation error");
    }
    buf->end = buf->start + size;

    xh_log_debug2("buf: %p size: %lu", buf->start, size);
}

void
xh_buffer_grow(xh_buffer_t *buf, size_t inc)
{
    size_t size, use;

    if (inc <= (size_t) (buf->end - buf->cur)) {
        return;
    }

    size = buf->end - buf->start;
    use  = buf->cur - buf->start;

    xh_log_debug2("old buf: %p size: %lu", buf->start, size);

    size += inc < size ? size : inc;

    buf->start = realloc(buf->start, size);
    if (buf->start == NULL) {
        croak("Memory allocation error");
    }
    buf->cur   = buf->start + use;
    buf->end   = buf->start + size;

    xh_log_debug2("new buf: %p size: %lu", buf->start, size);
}
