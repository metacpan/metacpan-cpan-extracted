#ifndef TK_SV_H
#define TK_SV_H

/* 64-bit integers to and from Perl scalars, exact on a perl whose IV is
 * 32 bits: a value that does not fit an IV goes out as its decimal string,
 * and a string comes in through its digits, never through an NV. */

static SV *
tk_newSVi64(pTHX_ int64_t v)
{
    char buf[24];
    char *p;
    uint64_t u;
    if (v >= (int64_t)IV_MIN && v <= (int64_t)IV_MAX)
        return newSViv((IV)v);
    u = v < 0 ? (uint64_t)0 - (uint64_t)v : (uint64_t)v;
    p = buf + sizeof buf;
    *--p = '\0';
    do { *--p = (char)('0' + (int)(u % 10)); u /= 10; } while (u);
    if (v < 0)
        *--p = '-';
    return newSVpv(p, 0);
}

/* 1 and *out set for an integer that fits int64_t, 0 for anything else:
 * a fraction, a number too large, a string that is not all digits. */
static int
tk_sv_to_i64(pTHX_ SV *sv, int64_t *out)
{
    SvGETMAGIC(sv);
    if (SvIOK(sv) && !SvPOK(sv)) {
        if (SvIsUV(sv)) {
            if ((uint64_t)SvUVX(sv) > (uint64_t)INT64_MAX)
                return 0;
            *out = (int64_t)SvUVX(sv);
        }
        else
            *out = (int64_t)SvIVX(sv);
        return 1;
    }
    if (SvNOK(sv) && !SvPOK(sv)) {
        NV nv = SvNVX(sv);
        if (nv != nv || nv < -9223372036854775808.0 || nv >= 9223372036854775808.0)
            return 0;
        if ((NV)(int64_t)nv != nv)
            return 0;
        *out = (int64_t)nv;
        return 1;
    }
    if (SvOK(sv) && !SvROK(sv)) {
        STRLEN len, i = 0;
        const char *s = SvPV_nomg(sv, len);
        int neg = 0;
        uint64_t u = 0;
        if (len && (s[0] == '-' || s[0] == '+')) {
            neg = s[0] == '-';
            i = 1;
        }
        if (i == len)
            return 0;
        for (; i < len; i++) {
            unsigned dig;
            if (s[i] < '0' || s[i] > '9')
                return 0;
            dig = (unsigned)(s[i] - '0');
            if (u > ((uint64_t)INT64_MAX + 1 - dig) / 10)
                return 0;
            u = u * 10 + dig;
        }
        if (!neg && u > (uint64_t)INT64_MAX)
            return 0;
        *out = neg ? (int64_t)(0 - u) : (int64_t)u;
        return 1;
    }
    return 0;
}

static int64_t
tk_arg_i64(pTHX_ SV *sv, const char *what)
{
    int64_t v;
    if (!tk_sv_to_i64(aTHX_ sv, &v))
        croak("%s is not an integer", what);
    return v;
}

#endif
