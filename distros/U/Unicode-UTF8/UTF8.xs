#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags
#include "ppport.h"

#include "utf8_dfa32.h"
#include "utf8_valid.h"

static inline STRLEN
xs_utf8_check(const U8 *src, STRLEN len) {
  STRLEN off;
  utf8_check_ascii((const char *)src, len, &off);
  return off;
};

static void
xs_report_unmappable(pTHX_ const UV cp, const STRLEN pos) {
    const char *fmt;
    U32 cat;

    if (cp > 0x10FFFF) {
        fmt = "Can't represent super code point \\x{%"UVXf"} in position %"UVuf;
        cat = WARN_NON_UNICODE;
    }
    else if ((cp & 0xF800) == 0xD800) {
        fmt = "Can't represent surrogate code point U+%"UVXf" in position %"UVuf;
        cat = WARN_SURROGATE;
    }
    else {
        fmt = "Can't represent code point U+%04"UVXf" in position %"UVuf;
        cat = WARN_UTF8;
    }

#if PERL_REVISION == 5 && PERL_VERSION >= 14
    Perl_ck_warner_d(aTHX_ packWARN(cat), fmt, cp, (UV)pos);
#else
    Perl_warner(aTHX_ packWARN(cat), fmt, cp, (UV)pos);
#endif
}

static void
xs_report_illformed(pTHX_ const U8 *s, STRLEN len, const char *enc, STRLEN pos, const bool fatal) {
    static const char *fmt = "Can't decode ill-formed %s octet sequence <%s> in position %"UVuf;
    static const char *hex = "0123456789ABCDEF";
    char seq[20 * 3 + 4];
    char *d = seq, *dstop = d + sizeof(seq) - 4;

    while (len-- > 0) {
        const U8 c = *s++;
        *d++ = hex[c >> 4];
        *d++ = hex[c & 15];
        if (len) {
            *d++ = ' ';
            if (d == dstop) {
                *d++ = '.', *d++ = '.', *d++ = '.';
                break;
            }
        }
    }
    *d = 0;

    if (fatal)
        Perl_croak(aTHX_ fmt, enc, seq, (UV)pos);
    else
        Perl_warner(aTHX_ packWARN(WARN_UTF8), fmt, enc, seq, (UV)pos);
}

static void
xs_utf8_encode_native(pTHX_ SV *, const U8 *, STRLEN, const bool);

static void
xs_handle_fallback(pTHX_ SV *dsv, CV *fallback, SV *val, UV usv, STRLEN pos) {
    dSP;
    SV *str;
    const char *src;
    STRLEN len;
    int count;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 2);
    mPUSHs(val);
    mPUSHu(usv);
    mPUSHu((UV)pos);
    PUTBACK;

    count = call_sv((SV *)fallback, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("expected 1 return value from fallback sub, got %d\n", count);

    str = POPs;
    src = SvPV_const(str, len);
    if (SvUTF8(str))
        sv_catpvn_nomg(dsv, src, len); /* XXX validate? */
    else
        xs_utf8_encode_native(aTHX_ dsv, (const U8 *)src, len, TRUE);

    PUTBACK;
    FREETMPS;
    LEAVE;
}

static void
xs_utf8_decode_replace(pTHX_ SV *dsv, const U8 *src, STRLEN len, STRLEN off, CV *fallback) {
    const bool do_warn = ckWARN_d(WARN_UTF8);

    STRLEN pos = 0;
    STRLEN skip;

    (void)SvUPGRADE(dsv, SVt_PV);
    (void)SvGROW(dsv, off + 1);
    SvCUR_set(dsv, 0);
    SvPOK_only(dsv);

    do {
        src += off;
        len -= off;
        pos += off;

        skip = utf8_maximal_subpart((const char *)src, len);

        if (do_warn) {
            xs_report_illformed(aTHX_ src, skip, "UTF-8", pos, FALSE);
        }

        sv_catpvn_nomg(dsv, (const char *)src - off, off);

        if (fallback) {
            SV *octets = newSVpvn((const char *)src, skip);
            xs_handle_fallback(aTHX_ dsv, fallback, octets, 0, pos);
        }
        else
            sv_catpvn_nomg(dsv, "\xEF\xBF\xBD", 3);

        src += skip;
        len -= skip;
        pos += skip;

        off = xs_utf8_check(src, len);
        if (off == len) {
            sv_catpvn_nomg(dsv, (const char *)src, off);
            break;
        }
    } while (len);
}

static void
xs_utf8_encode_replace(pTHX_ SV *dsv, const U8 *src, STRLEN len, STRLEN off, CV *fallback) {
#if PERL_REVISION == 5 && PERL_VERSION >= 14
    const bool do_warn = ckWARN4_d(WARN_UTF8, WARN_NONCHAR, WARN_SURROGATE, WARN_NON_UNICODE);
#else
    const bool do_warn = ckWARN_d(WARN_UTF8);
#endif
    STRLEN pos = 0;
    STRLEN skip;
    UV v;

    (void)SvUPGRADE(dsv, SVt_PV);
    (void)SvGROW(dsv, off + 1);
    SvCUR_set(dsv, 0);
    SvPOK_only(dsv);

    do {
        src += off;
        len -= off;
        pos += utf8_length(src - off, src);

        v = utf8n_to_uvuni(src, len, &skip, (UTF8_ALLOW_ANYUV|UTF8_CHECK_ONLY) & ~UTF8_ALLOW_LONG);
        if (skip == (STRLEN) -1) {
            skip = 1;
            if (UTF8_IS_START(*src)) {
                STRLEN n = UTF8SKIP(src);
                if (n > len)
                    n = len;
                while (skip < n && UTF8_IS_CONTINUATION(src[skip]))
                    skip++;
            }
            xs_report_illformed(aTHX_ src, skip, "UTF-X", pos, TRUE);
        }
        if (do_warn)
            xs_report_unmappable(aTHX_ v, pos);

        sv_catpvn_nomg(dsv, (const char *)src - off, off);

        if (fallback) {
            SV *codepoint = newSVuv(v);
            UV usv = (v <= 0x10FFFF && (v & 0xF800) != 0xD800) ? v : 0;
            xs_handle_fallback(aTHX_ dsv, fallback, codepoint, usv, pos);
        }
        else
            sv_catpvn_nomg(dsv, "\xEF\xBF\xBD", 3);

        src += skip;
        len -= skip;
        pos += 1;

        off = xs_utf8_check(src, len);
        if (off == len) {
            sv_catpvn_nomg(dsv, (const char *)src, off);
            break;
        }
    } while (len);
}

static void
xs_utf8_encode_native(pTHX_ SV *dsv, const U8 *src, STRLEN len, const bool append) {
    const U8 *end = src + len;
    U8 *d;
    STRLEN off = 0;

    if (append)
        off = SvCUR(dsv);

    (void)SvUPGRADE(dsv, SVt_PV);
    (void)SvGROW(dsv, off + len * 2 + 1);
    d = (U8 *)SvPVX(dsv) + off;

    for (; src < end; src++) {
        const U8 c = *src;
        if (c < 0x80)
            *d++ = c;
        else {
            *d++ = (U8)(0xC0 | ((c >> 6) & 0x1F));
            *d++ = (U8)(0x80 | ((c     ) & 0x3F));
        }
    }
    *d = 0;
    SvCUR_set(dsv, d - (U8 *)SvPVX(dsv));
    SvPOK_only(dsv);
}

static void
xs_utf8_encode_native_inplace(pTHX_ SV *sv, const U8 *s, STRLEN len) {
    const U8 *p = s;
    const U8 *e = s + len;

    while (p < e && *p < 0x80)
        p++;

    if (p != e) {
        STRLEN size, off;
        U8 *d;

        off = p - s;
        size = len;
        while (p < e)
            size += (*p++ > 0x7F);

        if (SvLEN(sv) < size + 1) {
            (void)sv_grow(sv, size + 1);
            s = (const U8 *)SvPVX(sv);
            e = s + len;
        }
        d = (U8 *)SvPVX(sv) + size;
        *d = 0;
        for (s += off, e--; e >= s; e--) {
            const U8 c = *e;
            if (c < 0x80)
                *--d = c;
            else {
                *--d = (U8)(0x80 | ((c     ) & 0x3F));
                *--d = (U8)(0xC0 | ((c >> 6) & 0x1F));
            }
        }
        SvCUR_set(sv, size);
    }
    SvPOK_only(sv);
}

static void
xs_utf8_downgrade(pTHX_ SV *dsv, const U8 *s, STRLEN len) {
    const U8 *e = s + len - 1;
    U8 *d, c, v;

    (void)SvUPGRADE(dsv, SVt_PV);
    (void)SvGROW(dsv, len + 1);
    d = (U8 *)SvPVX(dsv);

    while (s < e) {
        c = *s++;
        if (c < 0x80)
            *d++ = c;
        else {
            if ((c & 0xFE) != 0xC2)
                goto error;
            v = (c & 0x1F) << 6;
            c = *s++;
            if ((c & 0xC0) != 0x80)
                goto error;
            *d++ = (U8)(v | (c & 0x3F));
        }
    }
    if (s < e + 1) {
        if (*s < 0x80)
            *d++ = *s;
        else {
          error:
            croak("Can't decode a wide character string");
        }
    }
    *d = 0;
    SvCUR_set(dsv, d - (U8 *)SvPVX(dsv));
    SvPOK_only(dsv);
}

/* SVt_PV, SVt_PVIV, SVt_PVNV, SVt_PVMG */
#define SvPV_stealable(sv) \
  ((SvFLAGS(sv) & ~(SVTYPEMASK|SVf_UTF8)) == (SVs_TEMP|SVf_POK|SVp_POK) && \
   (SvTYPE(sv) >= SVt_PV && SvTYPE(sv) <= SVt_PVMG) && SvREFCNT(sv) == 1)

MODULE = Unicode::UTF8    PACKAGE = Unicode::UTF8

PROTOTYPES: DISABLE

void
decode_utf8(octets, fallback=NULL)
    SV *octets
    CV *fallback
  PREINIT:
    const U8 *src;
    STRLEN len, off;
    bool reuse_sv;
  PPCODE:
    src = (const U8 *)SvPV_const(octets, len);
    reuse_sv = SvPV_stealable(octets);
    if (SvUTF8(octets)) {
        if (!reuse_sv) {
            octets = sv_newmortal();
            reuse_sv = TRUE;
        }
        xs_utf8_downgrade(aTHX_ octets, src, len);
        if (SvCUR(octets) == len) {
            ST(0) = octets;
            SvUTF8_on(octets);
            XSRETURN(1);
        }
        src = (const U8 *)SvPV_const(octets, len);
    }
    if (utf8_check_ascii((const char *)src, len, &off)) {
        if (reuse_sv) {
            ST(0) = octets;
            SvUTF8_on(octets);
            XSRETURN(1);
        }
        else {
            dXSTARG;
            sv_setpvn(TARG, (const char *)src, len);
            SvUTF8_on(TARG);
            PUSHTARG;
        }
    }
    else {
        dXSTARG;
        xs_utf8_decode_replace(aTHX_ TARG, src, len, off, fallback);
        SvUTF8_on(TARG);
        PUSHTARG;
    }

void
encode_utf8(string, fallback=NULL)
    SV *string
    CV *fallback
  PREINIT:
    const U8 *src;
    STRLEN len;
    bool reuse_sv;
  PPCODE:
    src = (const U8 *)SvPV_const(string, len);
    reuse_sv = SvPV_stealable(string);
    if (!SvUTF8(string)) {
        if (reuse_sv) {
            xs_utf8_encode_native_inplace(aTHX_ string, src, len);
            ST(0) = string;
            XSRETURN(1);
        }
        else {
            dXSTARG;
            xs_utf8_encode_native(aTHX_ TARG, src, len, FALSE);
            SvTAINT(TARG);
            PUSHTARG;
        }
    }
    else {
        STRLEN off;
        if (utf8_check_ascii((const char *)src, len, &off)) {
            if (reuse_sv) {
                ST(0) = string;
                SvUTF8_off(string);
                XSRETURN(1);
            }
            else {
                dXSTARG;
                sv_setpvn(TARG, (const char *)src, len);
                SvUTF8_off(TARG);
                PUSHTARG;
            }
        }
        else {
            dXSTARG;
            xs_utf8_encode_replace(aTHX_ TARG, src, len, off, fallback);
            PUSHTARG;
        }
    }

void
valid_utf8(octets)
    SV *octets
  PREINIT:
    const char *src;
    STRLEN len;
  PPCODE:
    src = SvPV_const(octets, len);
    if (SvUTF8(octets)) {
        octets = sv_mortalcopy(octets);
        if (!sv_utf8_downgrade(octets, TRUE))
            croak("Can't validate a wide character string");
        src = SvPV_const(octets, len);
    }
    ST(0) = boolSV(utf8_valid_ascii(src, len));
    XSRETURN(1);

