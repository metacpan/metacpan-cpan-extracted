#ifndef _XH_BUFFER_H_
#define _XH_BUFFER_H_

#include "xh_config.h"
#include "xh_core.h"

typedef struct _xh_buffer_t xh_buffer_t;
struct _xh_buffer_t {
    xh_char_t *start;
    xh_char_t *cur;
    xh_char_t *end;
};

void xh_buffer_init(xh_buffer_t *buf, size_t size);
void xh_buffer_grow(xh_buffer_t *buf, size_t inc);

XH_INLINE void
xh_buffer_destroy(xh_buffer_t *buf)
{
    if (buf->start != NULL) {
        xh_log_debug1("free enc buf: %p", buf->start);
        free(buf->start);
    }
}

#define xh_buffer_avail(b)    ((b)->end - (b)->cur)
#define xh_buffer_start(b)    ((b)->start)
#define xh_buffer_pos(b)      ((b)->cur)
#define xh_buffer_end(b)      ((b)->end)
#define xh_buffer_size(b)     ((b)->end - (b)->start)
#define xh_buffer_seek(b, p)  (b)->cur = p
#define xh_buffer_seek_eof(b) (b)->cur = (b)->end
#define xh_buffer_seek_top(b) (b)->cur = (b)->start
#define xh_buffer_grow50(b)   xh_buffer_grow((b), xh_buffer_size(b) / 2)

#endif /* _XH_BUFFER_H_ */
