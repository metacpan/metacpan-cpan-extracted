#ifndef _XH_WRITER_H_
#define _XH_WRITER_H_

#include "xh_config.h"
#include "xh_core.h"

#define XH_WRITER_RESIZE_BUFFER(w, b, l)                                \
    if (((l) + 1) > (size_t) (b->end - b->cur)) {                       \
        xh_writer_resize_buffer(w, (l) + 1);                            \
    }

typedef struct _xh_writer_t xh_writer_t;
struct _xh_writer_t {
#ifdef XH_HAVE_ENCODER
    xh_encoder_t          *encoder;
    xh_perl_buffer_t       enc_buf;
#endif
    PerlIO                *perl_io;
    SV                    *perl_obj;
    xh_perl_buffer_t       main_buf;
    xh_int_t               indent;
    xh_int_t               indent_count;
    xh_bool_t              trim;
};

SV *xh_writer_flush_buffer(xh_writer_t *writer, xh_perl_buffer_t *buf);
SV *xh_writer_flush(xh_writer_t *writer);
void xh_writer_resize_buffer(xh_writer_t *writer, size_t inc);
void xh_writer_destroy(xh_writer_t *writer);
void xh_writer_init(xh_writer_t *writer, xh_char_t *encoding, void *output, size_t size, xh_uint_t indent, xh_bool_t trim);

XH_INLINE void
xh_writer_write_to_perl_obj(xh_perl_buffer_t *buf, SV *perl_obj)
{
    size_t len = buf->cur - buf->start;

    if (len > 0) {
        dSP;

        *buf->cur = '\0';
        SvCUR_set(buf->scalar, len);

        ENTER;
        SAVETMPS;

        PUSHMARK(SP);
        EXTEND(SP, 2);
        PUSHs((SV *) perl_obj);
        PUSHs(buf->scalar);
        PUTBACK;

        call_method("PRINT", G_DISCARD);

        FREETMPS;
        LEAVE;

        buf->cur = buf->start;
    }
}

XH_INLINE void
xh_writer_write_to_perl_io(xh_perl_buffer_t *buf, PerlIO *perl_io)
{
    size_t len = buf->cur - buf->start;

    if (len > 0) {
        *buf->cur = '\0';
        SvCUR_set(buf->scalar, len);

        PerlIO_write(perl_io, buf->start, len);

        buf->cur = buf->start;
    }
}

XH_INLINE SV *
xh_writer_write_to_perl_scalar(xh_perl_buffer_t *buf)
{
    *buf->cur = '\0';
    SvCUR_set(buf->scalar, buf->cur - buf->start);

    return buf->scalar;
}

#endif /* _XH_WRITER_H_ */
