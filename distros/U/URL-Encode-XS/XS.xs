#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

static SV *
url_decode(pTHX_ const char *s, const STRLEN len, SV *dsv) {
    #define __ 0xFF
    static const U8 hexval[0x100] = {
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 00-0F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 10-1F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 20-2F */
         0, 1, 2, 3, 4, 5, 6, 7, 8, 9,__,__,__,__,__,__, /* 30-3F */
        __,10,11,12,13,14,15,__,__,__,__,__,__,__,__,__, /* 40-4F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 50-5F */
        __,10,11,12,13,14,15,__,__,__,__,__,__,__,__,__, /* 60-6F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 70-7F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 80-8F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* 90-9F */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* A0-AF */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* B0-BF */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* C0-CF */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* D0-DF */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* E0-EF */
        __,__,__,__,__,__,__,__,__,__,__,__,__,__,__,__, /* F0-FF */
    };
    #undef __
    const char *e;
    char *d;

    if (!dsv)
        dsv = sv_newmortal();

    SvUPGRADE(dsv, SVt_PV);
    d = SvGROW(dsv, len + 1);

    e = s + len - 2;
    for (; s < e; s++, d++) {
        const U8 c = *s;
        if (c == '+')
            *d = ' ';
        else if (c != '%')
            *d = c;
        else {
            const U8 v1 = hexval[(U8)*++s];
            const U8 v2 = hexval[(U8)*++s];
            if ((v1 | v2) != 0xFF)
                *d = (v1 << 4) | v2;
            else
                *d = c, s -= 2;
        }
    }

    e += 2;
    for (; s < e; s++, d++) {
        const U8 c = *s;
        if (c == '+')
            *d = ' ';
        else
            *d = c;
    }

    *d = 0;
    SvCUR_set(dsv, d - SvPVX(dsv));
    SvPOK_only(dsv);
    return dsv;
}

static SV *
url_decode_utf8(pTHX_ const char *s, const STRLEN len, SV *dsv) {
    dsv = url_decode(aTHX_ s, len, dsv);
    if (!sv_utf8_decode(dsv))
        croak("Malformed UTF-8 in URL decoded string");
    return dsv;
}

static SV *
url_encode(pTHX_ const char *s, const STRLEN len, SV *dsv) {
    static const char xdigit[0x10] = "0123456789ABCDEF";
    static const U8 url_unreserved[0x100] = {
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0x00-0x0F */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0x10-0x1F */
        0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0, /* 0x20-0x2F */
        1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0, /* 0x30-0x3F */
        0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* 0x40-0x4F */
        1,1,1,1,1,1,1,1,1,1,1,0,0,0,0,1, /* 0x50-0x5F */
        0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, /* 0x60-0x6F */
        1,1,1,1,1,1,1,1,1,1,1,0,0,0,1,0, /* 0x70-0x7F */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0x80-0x8F */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0x90-0x9F */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0xA0-0xAF */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0xB0-0xBF */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0xC0-0xCF */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0xD0-0xDF */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0xE0-0xEF */
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, /* 0xF0-0xFF */
    };
    const char *e = s + len;
    char *d;

    if (!dsv)
        dsv = sv_newmortal();

    SvUPGRADE(dsv, SVt_PV);
    d = SvGROW(dsv, len * 3 + 1);

    for (; s < e; s++) {
        const U8 c = *s;
        if (url_unreserved[c])
            *d++ = *s;
        else if (c == ' ')
            *d++ = '+';
        else {
            *d++ = '%';
            *d++ = xdigit[c >> 4];
            *d++ = xdigit[c & 15];
        }
    }
    *d = 0;
    SvCUR_set(dsv, d - SvPVX(dsv));
    SvPOK_only(dsv);
    return dsv;
}

static bool
url_encoded(const char *s, const STRLEN len) {
    const char *e = s + len;
    for (; s < e; s++) {
        switch (*s) {
            case '+':
            case '%':
                return TRUE;
        }
    }
    return FALSE;
}

typedef struct _ust ust_t;
struct _ust {
    SV * (*decode) (pTHX_ const char *, const STRLEN, SV *);
    void (*cb)     (pTHX_ const ust_t *, const char *, STRLEN, bool, const char *, STRLEN);
    SV *sv;
};

static void
url_params_each(pTHX_ const char *cur, const STRLEN len, const ust_t *u) {
    const char * const end = cur + len;
    const char *key, *val;
    STRLEN klen, vlen;
    SV *tmpsv = NULL;
    bool is_utf8 = FALSE;

    while (cur < end) {
        for (key = cur; cur < end; cur++) {
            const char c = *cur;
            if (c == '=' || c == '&' || c == ';')
                break;
        }
        klen = cur - key;
        if (*cur != '=') {
            val  = NULL;
            vlen = 0;
        }
        else {
            for (val = ++cur; cur < end; cur++) {
                const char c = *cur;
                if (c == '&' || c == ';')
                    break;
            }
            vlen = cur - val;
        }

        if (u->decode == &url_decode_utf8 || url_encoded(key, klen)) {
            tmpsv   = u->decode(aTHX_ key, klen, tmpsv);
            key     = (const char *)SvPVX(tmpsv);
            klen    = SvCUR(tmpsv);
            if (u->decode == &url_decode_utf8)
                is_utf8 = SvUTF8(tmpsv);
        }
        u->cb(aTHX_ u, key, klen, is_utf8, val, vlen);
        cur++;
    }

    if (len) {
        const char c = end[-1];
        if (c == '&' || c == ';')
            u->cb(aTHX_ u, "", 0, FALSE, NULL, 0);
    }
}

static void
url_params_mixed_cb(pTHX_ const ust_t *u, const char *k, STRLEN klen, bool is_utf8, const char *v, STRLEN vlen) {
    SV **svp, *sv;

    if (!hv_exists((HV *)u->sv, k, is_utf8 ? -klen : klen)) {
        svp = hv_fetch((HV *)u->sv, k, is_utf8 ? -klen : klen, 1);
        if (v)
            u->decode(aTHX_ v, vlen, *svp);
    }
    else {
        SV *val = newSV(0);
        AV *av;

        svp = hv_fetch((HV *)u->sv, k, is_utf8 ? -klen : klen, 0);
        if (SvROK(*svp))
            av = (AV *)SvRV(*svp);
        else {
            sv = *svp;
            av = newAV();
            *svp = newRV_noinc((SV *)av);
            av_push(av, sv);
        }
        av_push(av, val);
        if (v)
            u->decode(aTHX_ v, vlen, val);
    }
}

static void
url_params_multi_cb(pTHX_ const ust_t *u, const char *k, STRLEN klen, bool is_utf8, const char *v, STRLEN vlen) {
    SV **svp, *val;
    AV *av;

    svp = hv_fetch((HV *)u->sv, k, is_utf8 ? -klen : klen, 1);
    val = newSV(0);

    if (SvROK(*svp))
        av = (AV *)SvRV(*svp);
    else {
        av = newAV();
        SvREFCNT_dec(*svp);
        *svp = newRV_noinc((SV *)av);
    }
    av_push(av, val);
    if (v)
        u->decode(aTHX_ v, vlen, val);
}

static void
url_params_flat_cb(pTHX_ const ust_t *u, const char *k, STRLEN klen, bool is_utf8, const char *v, STRLEN vlen) {
    SV *key, *val;

    key = newSVpvn(k, klen);
    val = newSV(0);

    if (is_utf8)
        SvUTF8_on(key);

    av_push((AV *)u->sv, key);
    av_push((AV *)u->sv, val);
    if (v)
        u->decode(aTHX_ v, vlen, val);
}

static void
url_params_each_cb(pTHX_ const ust_t *u, const char *k, STRLEN klen, bool is_utf8, const char *v, STRLEN vlen) {
    SV *key, *val;
    dSP;

    key = sv_2mortal(newSVpvn(k, klen));
    val = sv_2mortal(newSV(0));

    if (v)
        u->decode(aTHX_ v, vlen, val);

    if (is_utf8)
        SvUTF8_on(key);

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(key);
    PUSHs(val);
    PUTBACK;

    call_sv(u->sv, G_DISCARD);

    FREETMPS;
    LEAVE;
}


MODULE = URL::Encode::XS   PACKAGE = URL::Encode::XS

PROTOTYPES: DISABLE

void
url_decode(octets)
    SV *octets
  ALIAS:
    URL::Encode::XS::url_decode      = 0
    URL::Encode::XS::url_decode_utf8 = 1
    URL::Encode::XS::url_encode      = 2
  PREINIT:
    dXSTARG;
    const char *s;
    STRLEN len;
  PPCODE:
    SvGETMAGIC(octets);
    if (SvUTF8(octets)) {
        octets = sv_mortalcopy(octets);
        if (!sv_utf8_downgrade(octets, 1))
            croak("Wide character in octet string");
    }
    s = SvPV_nomg_const(octets, len);
    switch (ix) {
        case 0:
            url_decode(aTHX_ s, len, TARG);
            break;
        case 1:
            url_decode_utf8(aTHX_ s, len, TARG);
            break;
        case 2:
            url_encode(aTHX_ s, len, TARG);
            break;
    }
    PUSHTARG;

void
url_encode_utf8(string)
    SV *string
  PREINIT:
    dXSTARG;
    const char *s;
    STRLEN len;
  PPCODE:
    SvGETMAGIC(string);
    if (!SvUTF8(string)) {
        string = sv_mortalcopy(string);
        sv_utf8_encode(string);
    }
    s = SvPV_nomg_const(string, len);
    url_encode(aTHX_ s, len, TARG);
    PUSHTARG;

void
url_params_flat(octets, utf8=FALSE)
    SV *octets
    bool utf8
  ALIAS:
    URL::Encode::XS::url_params_flat  = 0
    URL::Encode::XS::url_params_mixed = 1
    URL::Encode::XS::url_params_multi = 2
  PREINIT:
    const char *s;
    STRLEN len;
    ust_t u;
  PPCODE:
    SvGETMAGIC(octets);
    if (SvUTF8(octets)) {
        octets = sv_mortalcopy(octets);
        if (!sv_utf8_downgrade(octets, 1))
            croak("Wide character in octet string");
    }

    u.decode = utf8 ? &url_decode_utf8 : &url_decode;
    switch(ix) {
        case 0:
            u.cb = &url_params_flat_cb;
            u.sv = (SV *)newAV();
            break;
        case 1:
            u.cb = &url_params_mixed_cb;
            u.sv = (SV *)newHV();
            break;
        case 2:
            u.cb = &url_params_multi_cb;
            u.sv = (SV *)newHV();
            break;
    }
    s = SvPV_nomg_const(octets, len);
    ST(0) = sv_2mortal(newRV_noinc(u.sv));
    url_params_each(aTHX_ s, len, &u);
    XSRETURN(1);


void
url_params_each(octets, callback, utf8=FALSE)
    SV *octets
    CV *callback
    bool utf8
  PREINIT:
    const char *s;
    STRLEN len;
    ust_t u;
  PPCODE:
    SvGETMAGIC(octets);
    if (SvUTF8(octets)) {
        octets = sv_mortalcopy(octets);
        if (!sv_utf8_downgrade(octets, 1))
            croak("Wide character in octet string");
    }
    s = SvPV_nomg_const(octets, len);
    u.decode = utf8 ? &url_decode_utf8 : &url_decode;
    u.cb     = &url_params_each_cb;
    u.sv     = (SV *)callback;
    url_params_each(aTHX_ s, len, &u);


