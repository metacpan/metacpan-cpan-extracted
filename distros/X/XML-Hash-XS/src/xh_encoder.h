#ifndef _XH_ENCODER_H_
#define _XH_ENCODER_H_

#include "xh_config.h"
#include "xh_core.h"

#ifdef XH_HAVE_ENCODER

#ifdef XH_HAVE_ICONV
#if defined(__MINGW32__) || defined(_WIN32)
#define LIBICONV_STATIC
#endif
#include <iconv.h>
#endif
#ifdef XH_HAVE_ICU
#include <unicode/utypes.h>
#include <unicode/ucnv.h>
#endif

typedef enum {
    XH_ENC_ICONV,
    XH_ENC_ICU
} xh_encoder_type_t;

typedef enum {
    XH_ENC_OK = 0,
    XH_ENC_BUFFER_OVERFLOW,
    XH_ENC_TRUNCATED_CHAR_FOUND
} xh_encoder_state_t;

typedef struct _xh_encoder_t xh_encoder_t;
struct _xh_encoder_t {
    xh_encoder_type_t  type;
    xh_encoder_state_t state;
    xh_char_t          fromcode[XH_PARAM_LEN];
    xh_char_t          tocode[XH_PARAM_LEN];
#ifdef XH_HAVE_ICONV
    iconv_t            iconv;
#endif
#ifdef XH_HAVE_ICU
    UConverter        *uconv_from;
    UConverter        *uconv_to;
    UChar              pivotBuffer[1024];
    const UChar       *pivotLimit;
    UChar             *pivotSource, *pivotTarget, *pivotStart;
#endif
};

void xh_encoder_destroy(xh_encoder_t *encoder);
xh_encoder_t *xh_encoder_create(xh_char_t *tocode, xh_char_t *fromcode);
void xh_encoder_encode_perl_buffer(xh_encoder_t *encoder, xh_perl_buffer_t *main_buf, xh_perl_buffer_t *enc_buf);
void xh_encoder_encode_string(xh_encoder_t *encoder, xh_char_t **src, size_t *src_left, xh_char_t **dst, size_t *dst_left);

#endif /* XH_HAVE_ENCODER */

#endif /* _XH_ENCODER_H_ */
