#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "qrencode.h"

#ifdef UNDER_LIBQRENCODE_1_0_2
QRcode *encode(const char *text,
               int version,
               QRecLevel level,
               QRencodeMode mode,
               int casesensitive)
{
    QRcode *code;

    if(casesensitive) {
        code = QRcode_encodeStringCase(text, version, level);
    } else {
        code = QRcode_encodeString(text, version, level, mode);
    }

    return code;
}
#else
QRcode *encode(const char *text,
               int version,
               QRecLevel level,
               QRencodeMode mode,
               int casesensitive)
{
    QRcode *code = QRcode_encodeString(text, version, level, mode, casesensitive);
    return code;
}

QRcode *encode_8bit(const char *text,
                    int version,
                    QRecLevel level)
{
    QRcode *code = QRcode_encodeString8bit(text, version, level);
    return code;
}
#endif

void generate(AV *map_av,
              QRcode *qrcode)
{
    unsigned char *p, *q;
    int x, y;
    AV *line_av;

    /* data */
    p = qrcode->data;
    q = p;
    for(y=0; y<qrcode->width; y++) {
        line_av = (AV*)sv_2mortal((SV*)newAV());
        for(x=0; x<qrcode->width; x++) {
            av_store(line_av, x, (*q & 1) ? newSVpv("*", 1) : newSVpv(" ", 1));
            q++;
        }
        av_store(map_av, y, newRV((SV*)line_av));
    }
}

AV *_plot(char *text, HV *hv)
{
    AV *map_av = newAV();
    QRcode *qrcode;
    SV **svp;
    STRLEN len;
    char *ptr;
    int version       = 0;
    int casesensitive = 0;
    QRencodeMode mode = QR_MODE_8;
    QRecLevel level   = QR_ECLEVEL_L;

    if ((svp = hv_fetch(hv, "level", 5, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        switch (*ptr) {
        case 'l':
        case 'L':
            level = QR_ECLEVEL_L;
            break;
        case 'm':
        case 'M':
            level = QR_ECLEVEL_M;
            break;
        case 'q':
        case 'Q':
            level = QR_ECLEVEL_Q;
            break;
        case 'h':
        case 'H':
            level = QR_ECLEVEL_H;
            break;
        default:
            level = QR_ECLEVEL_L;
        }
    }
    if ((svp = hv_fetch(hv, "version", 7, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        if (ptr >= 0)
            version = atoi(ptr);
    }
    if ((svp = hv_fetch(hv, "mode", 4, 0)) && *svp && SvOK(*svp)) {
        ptr = SvPV(*svp, len);
        if (strcmp(ptr, "numerical") == 0) {
            mode = QR_MODE_NUM;
        }
        else if (strcmp(ptr, "alpha-numerical") == 0) {
            mode = QR_MODE_AN;
        }
        else if (strcmp(ptr, "8-bit") == 0) {
            mode = QR_MODE_8;
        }
        else if (strcmp(ptr, "kanji") == 0) {
            mode = QR_MODE_KANJI;
        }
        else {
            croak("Invalid mode: XS error");
        }
    }
    if ((svp = hv_fetch(hv, "casesensitive", 13, 0)) && *svp) {
        casesensitive = SvTRUE(*svp);
    }

#ifdef UNDER_LIBQRENCODE_1_0_2
    qrcode = encode(text, version, level, mode, casesensitive);
#else
    if (mode == QR_MODE_8)
        qrcode = encode_8bit(text, version, level);
    else
        qrcode = encode(text, version, level, mode, casesensitive);
#endif
    if (qrcode == NULL)
        croak("Failed to encode the input data: XS error");

    generate(map_av, qrcode);
    QRcode_free(qrcode);

    return map_av;
}

MODULE = Text::QRCode   PACKAGE = Text::QRCode

PROTOTYPES: ENABLE

AV *
_plot(text, hv)
        char *text
        HV *hv
    CODE:
        RETVAL = _plot(text, hv);
    OUTPUT:
        RETVAL
