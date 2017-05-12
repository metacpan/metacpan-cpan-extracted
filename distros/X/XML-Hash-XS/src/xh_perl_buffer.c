#include "xh_config.h"
#include "xh_core.h"

void
xh_perl_buffer_init(xh_perl_buffer_t *buf, size_t size)
{
    buf->scalar = newSV(size);
    sv_setpv(buf->scalar, "");

    buf->start = buf->cur = XH_CHAR_CAST SvPVX(buf->scalar);
    buf->end   = buf->start + size;

    xh_log_debug2("buf: %p size: %lu", buf->start, size);
}

void
xh_perl_buffer_grow(xh_perl_buffer_t *buf, size_t inc)
{
    size_t size, use;

    if (inc <= (size_t) (buf->end - buf->cur))
        return;

    size = buf->end - buf->start;
    use  = buf->cur - buf->start;

    xh_log_debug2("old buf: %p size: %lu", buf->start, size);

    size += inc < size ? size : inc;

    SvCUR_set(buf->scalar, use);
    SvGROW(buf->scalar, size);

    buf->start = XH_CHAR_CAST SvPVX(buf->scalar);
    buf->cur   = buf->start + use;
    buf->end   = buf->start + size;

    xh_log_debug2("new buf: %p size: %lu", buf->start, size);
}

void
xh_perl_buffer_sync(xh_perl_buffer_t *buf)
{
    size_t use  = buf->cur - buf->start;
    size_t size = SvLEN(buf->scalar);

    buf->start  = XH_CHAR_CAST SvPVX(buf->scalar);
    buf->end    = buf->start + size;
    buf->cur    = buf->start + use;

    xh_log_debug2("buf: %p size: %lu", buf->start, size);
}
