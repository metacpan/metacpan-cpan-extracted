#ifndef _XH_READER_H_
#define _XH_READER_H_

#include "xh_config.h"
#include "xh_core.h"

typedef enum {
    XH_READER_STRING_TYPE,
    XH_READER_FILE_TYPE,
    XH_READER_MMAPED_FILE_TYPE
} xh_reader_type_t;

typedef struct _xh_reader_t xh_reader_t;
struct _xh_reader_t {
    xh_reader_type_t  type;
    SV               *input;
    xh_char_t        *str;
    size_t            len;
    xh_char_t        *file;
    int               fd;
    PerlIO           *perl_io;
    SV               *perl_obj;
#ifdef WIN32
    HANDLE            fm, fh;
#endif
#ifdef XH_HAVE_ENCODER
    xh_encoder_t     *encoder;
    xh_buffer_t       enc_buf;
#endif
    xh_buffer_t       main_buf;
    xh_perl_buffer_t  perl_buf;
    xh_char_t        *fake_read_pos;
    size_t            fake_read_len;
    size_t            buf_size;
    void              (*init)            (xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size);
    size_t            (*read)            (xh_reader_t *reader, xh_char_t **buf, xh_char_t *preserve, size_t *off);
    void              (*switch_encoding) (xh_reader_t *reader, xh_char_t *encoding, xh_char_t **buf, size_t *len);
    void              (*destroy)         (xh_reader_t *reader);
};

void xh_reader_destroy(xh_reader_t *reader);
void xh_reader_init(xh_reader_t *reader, SV *input, xh_char_t *encoding, size_t buf_size);

#endif /* _XH_READER_H_ */
