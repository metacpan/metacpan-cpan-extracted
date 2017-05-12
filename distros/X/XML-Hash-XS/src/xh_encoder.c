#include "xh_config.h"
#include "xh_core.h"

#ifdef XH_HAVE_ENCODER

#ifdef XH_HAVE_ICU
static void
xh_encoder_uconv_destroy(UConverter *uconv)
{
    if (uconv != NULL) {
        ucnv_close(uconv);
    }
}

static UConverter *
xh_encoder_uconv_create(xh_char_t *encoding, xh_bool_t toUnicode)
{
    UConverter *uconv;
    UErrorCode  status = U_ZERO_ERROR;

    uconv = ucnv_open((char *) encoding, &status);
    if ( U_FAILURE(status) ) {
        return NULL;
    }

    if (toUnicode) {
        ucnv_setToUCallBack(uconv, UCNV_TO_U_CALLBACK_STOP,
                            NULL, NULL, NULL, &status);
    }
    else {
        ucnv_setFromUCallBack(uconv, UCNV_FROM_U_CALLBACK_STOP,
                              NULL, NULL, NULL, &status);
    }

    return uconv;
}
#endif

void
xh_encoder_destroy(xh_encoder_t *encoder)
{
    if (encoder != NULL) {
#ifdef XH_HAVE_ICONV
        if (encoder->iconv != NULL) {
            xh_log_debug0("destroy iconv encoder");
            iconv_close(encoder->iconv);
        }
#endif

#ifdef XH_HAVE_ICU
        if (encoder->uconv_from != NULL) {
            xh_log_debug0("destroy icu encoder");
            xh_encoder_uconv_destroy(encoder->uconv_from);
            xh_encoder_uconv_destroy(encoder->uconv_to);
        }
#endif
        free(encoder);
    }
}

xh_encoder_t *
xh_encoder_create(xh_char_t *tocode, xh_char_t *fromcode)
{
    xh_encoder_t *encoder;

    encoder = malloc(sizeof(xh_encoder_t));
    if (encoder == NULL) {
        return NULL;
    }
    memset(encoder, 0, sizeof(xh_encoder_t));

    xh_str_copy(encoder->tocode, tocode, XH_PARAM_LEN);
    xh_str_copy(encoder->fromcode, fromcode, XH_PARAM_LEN);

#ifdef XH_HAVE_ICONV
    xh_log_debug2("create iconv encoder from: '%s' to: '%s'", fromcode, tocode);
    encoder->iconv = iconv_open((char *) tocode, (char *) fromcode);
    if (encoder->iconv != (iconv_t) -1) {
        encoder->type = XH_ENC_ICONV;
        return encoder;
    }
    encoder->iconv = NULL;
#endif

#ifdef XH_HAVE_ICU
    xh_log_debug2("create icu encoder from: '%s' to: '%s'", fromcode, tocode);
    encoder->uconv_to = xh_encoder_uconv_create(tocode, 1);
    if (encoder->uconv_to != NULL) {
        encoder->uconv_from = xh_encoder_uconv_create(fromcode, 0);
        if (encoder->uconv_from != NULL) {
            encoder->type        = XH_ENC_ICU;
            encoder->pivotSource = encoder->pivotTarget = encoder->pivotStart = encoder->pivotBuffer;
            encoder->pivotLimit  = encoder->pivotBuffer + sizeof(encoder->pivotBuffer) / sizeof(encoder->pivotBuffer[0]);
            return encoder;
        }
    }
#endif

    xh_encoder_destroy(encoder);

    return NULL;
}

void
xh_encoder_encode_perl_buffer(xh_encoder_t *encoder, xh_perl_buffer_t *main_buf, xh_perl_buffer_t *enc_buf)
{
    xh_char_t *src  = main_buf->start;

#ifdef XH_HAVE_ICONV
    if (encoder->type == XH_ENC_ICONV) {
        size_t in_left  = main_buf->cur - main_buf->start;
        size_t out_left = enc_buf->end - enc_buf->cur;

        size_t converted = iconv(encoder->iconv, (char **) &src, &in_left, (char **) &enc_buf->cur, &out_left);
        if (converted == (size_t) -1) {
            croak("Encoding error");
        }
        return;
    }
#endif

#ifdef XH_HAVE_ICU
    UErrorCode  err  = U_ZERO_ERROR;
    ucnv_convertEx(encoder->uconv_to, encoder->uconv_from, (char **) &enc_buf->cur, (char *) enc_buf->end,
                   (const char **) &src, (char *) main_buf->cur, NULL, NULL, NULL, NULL,
                   FALSE, TRUE, &err);

    if ( U_FAILURE(err) ) {
        croak("Encoding error: %d", err);
    }
#endif
}

void
xh_encoder_encode_string(xh_encoder_t *encoder, xh_char_t **src, size_t *src_left, xh_char_t **dst, size_t *dst_left)
{
#ifdef XH_HAVE_ICONV
    if (encoder->type == XH_ENC_ICONV) {
        size_t converted = iconv(encoder->iconv, (char **) src, src_left, (char **) dst, dst_left);
        if (converted == (size_t) -1) {
            switch (errno) {
                case EILSEQ:
                    croak("Encoding error: invalid char found");
                case E2BIG:
                    encoder->state = XH_ENC_BUFFER_OVERFLOW;
                    break;
                case EINVAL:
                    encoder->state = XH_ENC_TRUNCATED_CHAR_FOUND;
                    break;
                default:
                    croak("Encoding error");
            }
        }
        else {
            encoder->state = XH_ENC_OK;
        }
        return;
    }
#endif

#ifdef XH_HAVE_ICU
    UErrorCode  err = U_ZERO_ERROR;
    xh_char_t  *old_src = *src;
    xh_char_t  *old_dst = *dst;

    ucnv_convertEx(encoder->uconv_to, encoder->uconv_from, (char **) dst, (char *) (*dst + *dst_left),
                   (const char **) src, (char *) (*src + *src_left), encoder->pivotStart, &encoder->pivotSource, &encoder->pivotTarget, encoder->pivotLimit,
                   FALSE, FALSE, &err);

    *src_left -= *src - old_src;
    *dst_left -= *dst - old_dst;

    if ( U_FAILURE(err) ) {
        switch (err) {
            case U_INVALID_CHAR_FOUND:
                croak("Encoding error: invalid char found");
            case U_BUFFER_OVERFLOW_ERROR:
                encoder->state = XH_ENC_BUFFER_OVERFLOW;
                break;
            case U_TRUNCATED_CHAR_FOUND:
                encoder->state = XH_ENC_TRUNCATED_CHAR_FOUND;
                break;
            default:
                croak("Encoding error: %d", err);
        }
    }
    else {
        encoder->state = XH_ENC_OK;
    }
#endif
}

#endif /* XH_HAVE_ENCODER */
