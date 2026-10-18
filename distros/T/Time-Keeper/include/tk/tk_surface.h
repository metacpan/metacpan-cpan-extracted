#ifndef TK_SURFACE_H
#define TK_SURFACE_H

/* SvNV_nomg arrived in perl 5.14. Magic has been got already wherever it
 * is used, so on older perls a second get is all the fallback costs. */
#ifndef SvNV_nomg
#  define SvNV_nomg(sv) SvNV(sv)
#endif

/* Helpers for the Perl surface: options, numbers in and out, the ISO 8601
 * form and zone names. */

static int
tk_opt_gap(pTHX_ SV *sv, const char *what)
{
    const char *s = SvPV_nolen(sv);
    if (strEQ(s, "croak"))    return TKZ_GAP_CROAK;
    if (strEQ(s, "forward"))  return TKZ_GAP_FORWARD;
    if (strEQ(s, "backward")) return TKZ_GAP_BACKWARD;
    croak("%s: gap is 'croak', 'forward' or 'backward', not '%s'", what, s);
    return 0;
}

static int
tk_opt_overlap(pTHX_ SV *sv, const char *what)
{
    const char *s = SvPV_nolen(sv);
    if (strEQ(s, "earlier")) return TKZ_OVERLAP_EARLIER;
    if (strEQ(s, "later"))   return TKZ_OVERLAP_LATER;
    croak("%s: overlap is 'earlier' or 'later', not '%s'", what, s);
    return 0;
}

/* An integer field, range-checked and named in the croak. */
static int64_t
tk_opt_int(pTHX_ SV *sv, const char *what, const char *name, int64_t lo, int64_t hi)
{
    int64_t v;
    if (!tk_sv_to_i64(aTHX_ sv, &v))
        croak("%s: %s is not an integer", what, name);
    if (v < lo || v > hi)
        croak("%s: %s %" IVdf " is out of range", what, name, (IV)v);
    return v;
}

/* K2: an IV where it fits, else an NV (exact to 2**53, which every epoch
 * in range is not, but every one since the Big Bang is). */
static SV *
tk_newSVi64_nv(pTHX_ int64_t v)
{
    if (v >= (int64_t)IV_MIN && v <= (int64_t)IV_MAX)
        return newSViv((IV)v);
    return newSVnv((NV)v);
}

/* "+05:30", "-08:00", "+05:45:12" */
static int
tk_fmt_offset(char *buf, int32_t off, int colon)
{
    int32_t a = off < 0 ? -off : off;
    int n = sprintf(buf, colon ? "%c%02d:%02d" : "%c%02d%02d", off < 0 ? '-' : '+',
                    (int)(a / 3600), (int)(a / 60 % 60));
    if (a % 60)
        n += sprintf(buf + n, colon ? ":%02d" : "%02d", (int)(a % 60));
    return n;
}

/* Nanoseconds as a fraction: none when zero, else 3, 6 or 9 digits,
 * whichever is the fewest that is exact. */
static int
tk_fmt_fraction(char *buf, int32_t nsec)
{
    if (nsec == 0)
        return 0;
    if (nsec % 1000000 == 0)
        return sprintf(buf, ".%03d", (int)(nsec / 1000000));
    if (nsec % 1000 == 0)
        return sprintf(buf, ".%06d", (int)(nsec / 1000));
    return sprintf(buf, ".%09d", (int)nsec);
}

static int
tk_fmt_year(char *buf, int32_t y)
{
    if (y >= 0 && y <= 9999)
        return sprintf(buf, "%04d", (int)y);
    return sprintf(buf, "%c%06ld", y < 0 ? '-' : '+', (long)(y < 0 ? -(long)y : (long)y));
}

/* ISO 8601: 2026-10-15T09:00:00.25+09:00, Z for UTC, no offset when
 * floating. Years past 9999 or before 0 take ISO's expanded form. */
static int
tk_iso8601(tk_value *v, char *buf)
{
    const tk_civil *c = tk_value_civil(v);
    int n = tk_fmt_year(buf, c->year);
    n += sprintf(buf + n, "-%02u-%02uT%02u:%02u:%02u",
                 (unsigned)c->month, (unsigned)c->day, (unsigned)c->hour,
                 (unsigned)c->minute, (unsigned)c->second);
    n += tk_fmt_fraction(buf + n, c->nsec);
    if (v->zone == TK_ZONE_UTC)
        buf[n++] = 'Z';
    else if (v->zone != TK_ZONE_FLOATING)
        n += tk_fmt_offset(buf + n, v->utoff, 1);
    buf[n] = '\0';
    return n;
}

/* An epoch: an integer; a string "-12.345" read exactly, to the
 * nanosecond; or a number, rounded to the microsecond, as DateTime rounds
 * it (a double holds no more than that at today's epoch). */
static void
tk_epoch_from_sv(pTHX_ SV *sv, tk_instant *t, const char *what)
{
    int64_t i;
    SvGETMAGIC(sv);
    if (tk_sv_to_i64(aTHX_ sv, &i)) {
        t->sec = i;
        t->nsec = 0;
        return;
    }
    if (SvPOK(sv) && !SvROK(sv)) {
        STRLEN len, k = 0;
        const char *s = SvPV_nomg(sv, len);
        int neg = 0, digits = 0;
        uint64_t whole = 0;
        int32_t frac = 0, scale = 100000000;
        if (k < len && (s[k] == '-' || s[k] == '+')) neg = s[k++] == '-';
        while (k < len && isDIGIT(s[k])) {
            if (whole > (uint64_t)INT64_MAX / 10) croak("%s: epoch out of range", what);
            whole = whole * 10 + (s[k++] - '0');
            digits++;
        }
        if (k < len && s[k] == '.') {
            k++;
            while (k < len && isDIGIT(s[k])) {
                if (!scale) croak("%s: an epoch has at most nine decimal places", what);
                frac += (s[k++] - '0') * scale;
                scale /= 10;
                digits++;
            }
        }
        if (k != len || !digits)
            croak("%s: '%s' is not a number", what, s);
        t->sec = neg ? -(int64_t)whole : (int64_t)whole;
        t->nsec = frac;
        if (neg && frac) {
            t->sec -= 1;
            t->nsec = TK_NSECS_PER_SEC - frac;
        }
        return;
    }
    if (SvNIOK(sv) || looks_like_number(sv)) {
        NV nv = SvNV_nomg(sv);
        NV fl;
        int64_t micros;
        if (nv != nv || nv < -9.2e18 || nv > 9.2e18)
            croak("%s: epoch out of range", what);
        fl = Perl_floor(nv);
        micros = (int64_t)Perl_floor((nv - fl) * 1e6 + 0.5);
        t->sec = (int64_t)fl;
        if (micros >= 1000000) {
            t->sec += 1;
            micros -= 1000000;
        }
        t->nsec = (int32_t)(micros * 1000);
        return;
    }
    croak("%s: an epoch is a number", what);
}

/* ---- the epoch in milliseconds, microseconds and nanoseconds ------------- */

/* The scale of a unit of `digits` decimal places: 1000, 1000000, 1e9. */
#define TK_SCALE(digits) ((digits) == 3 ? (int64_t)1000 : (digits) == 6 ? (int64_t)1000000 : (int64_t)TK_NSECS_PER_SEC)

/* (s, n) as a whole number of the unit, the fraction below it dropped
 * (towards minus infinity). An IV where one fits; past that an NV when
 * nv_ok (exact below 2**53), else, or beyond int64 at all, a string of
 * digits, exact. */
static SV *
tk_epoch_scaled(pTHX_ int64_t s, int32_t n, int digits, int nv_ok)
{
    int64_t scale = TK_SCALE(digits);
    int64_t f = n / (TK_NSECS_PER_SEC / scale);
    SV *sv;
    char frac[12];
    int neg = 0;

    if (s < INT64_MAX / scale && s > INT64_MIN / scale) {
        int64_t v = s * scale + f;
        return nv_ok ? tk_newSVi64_nv(aTHX_ v) : tk_newSVi64(aTHX_ v);
    }
    /* beyond int64: the decimal built from the two parts; before 1970 the
     * whole part is one nearer zero and the fraction counts back from it */
    if (s < 0 && f > 0) {
        neg = 1;
        s += 1;
        f = scale - f;
    }
    sv = newSVpvs("");
    if (s == 0) {
        if (neg)
            sv_catpvs(sv, "-");
        sv_catsv(sv, sv_2mortal(tk_newSVi64(aTHX_ f)));
        return sv;
    }
    sv_catsv(sv, sv_2mortal(tk_newSVi64(aTHX_ s)));
    sprintf(frac, "%0*d", digits, (int)f);
    sv_catpvn(sv, frac, (STRLEN)digits);
    return sv;
}

/* A whole number of the unit, from an integer or a string of digits of any
 * length, to (s, n). Negative numbers count back from the epoch. */
static void
tk_epoch_scaled_from_sv(pTHX_ SV *sv, int digits, tk_instant *t, const char *what)
{
    int64_t scale = TK_SCALE(digits), v;
    SvGETMAGIC(sv);
    if (tk_sv_to_i64(aTHX_ sv, &v)) {
        t->sec = tk_floor_div(v, scale);
        t->nsec = (int32_t)(tk_floor_mod(v, scale) * (TK_NSECS_PER_SEC / scale));
        return;
    }
    if (SvPOK(sv) && !SvROK(sv)) {
        STRLEN len, k = 0;
        const char *s = SvPV_nomg(sv, len);
        int neg = 0;
        uint64_t whole = 0;
        int64_t f = 0;
        if (k < len && (s[k] == '-' || s[k] == '+'))
            neg = s[k++] == '-';
        if (k == len || len - k <= (STRLEN)digits)
            croak("%s: '%s' is not a whole number", what, s);
        for (; k < len - digits; k++) {
            if (!isDIGIT(s[k]))
                croak("%s: '%s' is not a whole number", what, s);
            if (whole > (uint64_t)INT64_MAX / 10)
                croak("%s: out of range", what);
            whole = whole * 10 + (s[k] - '0');
        }
        for (; k < len; k++) {
            if (!isDIGIT(s[k]))
                croak("%s: '%s' is not a whole number", what, s);
            f = f * 10 + (s[k] - '0');
        }
        if (whole > (uint64_t)INT64_MAX)
            croak("%s: out of range", what);
        t->sec = neg ? -(int64_t)whole : (int64_t)whole;
        t->nsec = (int32_t)(f * (TK_NSECS_PER_SEC / scale));
        if (neg && f) {
            t->sec -= 1;
            t->nsec = TK_NSECS_PER_SEC - t->nsec;
        }
        return;
    }
    if (SvNIOK(sv) || looks_like_number(sv))
        croak("%s takes a whole number; from_epoch takes a fraction", what);
    croak("%s: a number is needed", what);
}

/* The zone's name: as given for a named zone (a link keeps its own),
 * "UTC", "floating", or the offset of a fixed one. */
static SV *
tk_zone_name_sv(pTHX_ const tk_value *v)
{
    char buf[16];
    switch (v->zone) {
    case TK_ZONE_UTC:      return newSVpvs("UTC");
    case TK_ZONE_FLOATING: return newSVpvs("floating");
    case TK_ZONE_FIXED:    return newSVpvn(buf, tk_fmt_offset(buf, v->utoff, 1));
    default:               return newSVpv((tk_zone_abi(aTHX)->name)(v->zone - TK_ZONE_NAMED), 0);
    }
}

static SV *
tk_zone_abbr_sv(pTHX_ const tk_value *v)
{
    char buf[16];
    const char *abbr = NULL;
    switch (v->zone) {
    case TK_ZONE_UTC:      return newSVpvs("UTC");
    case TK_ZONE_FLOATING: return newSVpvs("");
    case TK_ZONE_FIXED:    return newSVpvn(buf, tk_fmt_offset(buf, v->utoff, 1));
    default:
        (tk_zone_abi(aTHX)->offset_at)(v->zone - TK_ZONE_NAMED, v->inst.sec, NULL, NULL, &abbr);
        return newSVpv(abbr, 0);
    }
}

/* The text Storable keeps for a value: a version, seconds, nanoseconds and
 * the zone by name, never by id, since ids belong to one tzdata release. */
static SV *
tk_freeze_sv(pTHX_ const tk_value *v)
{
    SV *out = newSVpvs("tk1 ");
    SV *zone = sv_2mortal(tk_zone_name_sv(aTHX_ v));
    sv_catsv(out, sv_2mortal(tk_newSVi64(aTHX_ v->inst.sec)));
    sv_catpvf(out, " %ld ", (long)v->inst.nsec);
    sv_catsv(out, zone);
    return out;
}

#endif
