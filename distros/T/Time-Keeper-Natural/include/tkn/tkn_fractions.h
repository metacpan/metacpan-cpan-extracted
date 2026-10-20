#ifndef TKN_FRACTIONS_H
#define TKN_FRACTIONS_H

/* A count with a decimal fraction, "1.5 hours", "1,5 Stunden", "in 2.5
 * days", read where the plain reading failed. The decimal sign is the
 * locale's (and the full stop where the locale's is not ASCII, as Arabic's
 * ٫); a group separator is never one, so "1,500 seconds" in English stays
 * what 0.01 made of it. The text is read with whole counts in the fraction's
 * place, two a unit apart; their difference is one of the unit, and the
 * fraction of it is added exactly, so no unit word or plural rule is looked
 * at. A month, a quarter or a year has no fixed length and dies; so does a
 * fraction finer than a nanosecond. */

typedef struct {
    SV *pre, *post;     /* the text before and after the number */
    IV a;               /* the whole part */
    IV b;               /* the fraction's digits as a number */
    int n;              /* how many of them */
} tkn_frac;

static SV *
tkn_decimal_sign(pTHX_ tkn_lexicon *L)
{
    tkn_number_signs(aTHX_ L);
    return L->decimal;
}

/* The one decimal number in the text, its digits ASCII; 0 if there is none
 * or more than one. */
static int
tkn_frac_find(pTHX_ tkn_lexicon *L, SV *text, tkn_frac *f)
{
    SV *raw = tkn_ascii_digits(aTHX_ text, L->has_digits ? L->digits : NULL), *dec = tkn_decimal_sign(aTHX_ L);
    STRLEN rl, dl, i, found = 0;
    const char *rb = tkn_utf8_bytes(aTHX_ raw, &rl), *db = tkn_utf8_bytes(aTHX_ dec, &dl);
    int ascii_too = (U8)db[0] >= 0x80;
    for (i = 0; i < rl; i++) {
        STRLEN a0, a1, sl = 0, b1;
        if (!isDIGIT_A(rb[i]) || (i && (isDIGIT_A(rb[i - 1]) || rb[i - 1] == '.' || rb[i - 1] == ',')))
            continue;
        a0 = i;
        a1 = i;
        while (a1 < rl && isDIGIT_A(rb[a1]))
            a1++;
        if (a1 + dl < rl && memEQ(rb + a1, db, dl))
            sl = dl;
        else if (ascii_too && a1 + 1 < rl && rb[a1] == '.')
            sl = 1;
        if (!sl || !isDIGIT_A(rb[a1 + sl]))
            continue;
        b1 = a1 + sl;
        while (b1 < rl && isDIGIT_A(rb[b1]))
            b1++;
        if (b1 < rl && (rb[b1] == '.' || rb[b1] == ',' || (b1 + dl <= rl && memEQ(rb + b1, db, dl))) && b1 + 1 < rl && isDIGIT_A(rb[b1 + 1]))
            return 0;
        if (found++ || a1 - a0 > 9 || b1 - a1 - sl > 18)
            return 0;
        f->pre = sv_2mortal(newSVpvn(rb, a0));
        f->post = sv_2mortal(newSVpvn(rb + b1, rl - b1));
        SvUTF8_on(f->pre);
        SvUTF8_on(f->post);
        f->a = (IV)atol(SvPVX(sv_2mortal(newSVpvn(rb + a0, a1 - a0))));
        f->n = (int)(b1 - a1 - sl);
        {
            STRLEN j;
            IV b = 0;
            for (j = a1 + sl; j < b1; j++)
                b = b * 10 + (rb[j] - '0');
            f->b = b;
        }
        i = b1;
    }
    return found == 1;
}

static SV *
tkn_frac_with(pTHX_ const tkn_frac *f, IV k)
{
    SV *t = sv_2mortal(newSVsv(f->pre));
    sv_catpvf(t, "%" IVdf, k);
    sv_catsv(t, f->post);
    SvUTF8_on(t);
    return t;
}

/* The fraction of a unit of u nanoseconds, exactly; 0 when it is finer than
 * a nanosecond. */
static int
tkn_frac_of(const tkn_frac *f, int64_t u, int64_t *out)
{
    int64_t p = 1;
    int i;
    int64_t au = u < 0 ? -u : u;
    for (i = 0; i < f->n; i++) {
        if (p > INT64_MAX / 10)
            return 0;
        p *= 10;
    }
    if (au % p)
        return 0;
    *out = (u / p) * (int64_t)f->b;
    return 1;
}

static const IV tkn_frac_tries[] = { -1, 2, 3, 5, 10, 11, 21 };

static void
tkn_frac_reason(pTHX_ HV *info, const char *what, SV *text)
{
    (void)hv_stores(info, "reason", newSVpv(what, 0));
    (void)hv_stores(info, "token", newSVsv(tkn_first_token(aTHX_ text)));
}

/* parse_duration's fraction. */
static SV *
tkn_frac_duration(pTHX_ tkn_lexicon *L, SV *text, HV *info)
{
    tkn_frac f;
    size_t t;
    if (!tkn_frac_find(aTHX_ L, text, &f))
        return NULL;
    for (t = 0; t < sizeof tkn_frac_tries / sizeof tkn_frac_tries[0]; t++) {
        IV k = tkn_frac_tries[t] < 0 ? f.a : tkn_frac_tries[t];
        HV *s1 = (HV *)sv_2mortal((SV *)newHV()), *s2 = (HV *)sv_2mortal((SV *)newHV());
        SV *t1 = tkn_frac_with(aTHX_ &f, k), *t2 = tkn_frac_with(aTHX_ &f, k + 1), *d1, *d2;
        time_keeper_parts p1, p2, out;
        int64_t unit, extra;
        (void)hv_stores(s1, "assumed", newRV_noinc((SV *)newAV()));
        (void)hv_stores(s2, "assumed", newRV_noinc((SV *)newAV()));
        d1 = tkn_duration_value(aTHX_ L, tkn_key_sv(aTHX_ L, t1), t1, s1);
        d2 = d1 ? tkn_duration_value(aTHX_ L, tkn_key_sv(aTHX_ L, t2), t2, s2) : NULL;
        if (!d1 || !d2 || (TKN_TK->duration_from_sv)(aTHX_ d1, &p1) != TIME_KEEPER_OK
            || (TKN_TK->duration_from_sv)(aTHX_ d2, &p2) != TIME_KEEPER_OK)
            continue;
        if (p2.years != p1.years || p2.months != p1.months) {
            /* a duration keeps a year as twelve months */
            int64_t m = (p2.years - p1.years) * 12 + (p2.months - p1.months);
            tkn_frac_reason(aTHX_ info, m % 12 == 0 ? "a year has no fixed length" : m == 3 ? "a quarter has no fixed length" : "a month has no fixed length", text);
            return NULL;
        }
        unit = ((p2.weeks - p1.weeks) * 7 + (p2.days - p1.days)) * INT64_C(86400000000000) + (p2.hours - p1.hours) * INT64_C(3600000000000)
             + (p2.minutes - p1.minutes) * INT64_C(60000000000) + (p2.seconds - p1.seconds) * INT64_C(1000000000) + (p2.nanoseconds - p1.nanoseconds);
        if (unit <= 0)
            continue;
        if (!tkn_frac_of(&f, unit, &extra)) {
            tkn_frac_reason(aTHX_ info, "a fraction finer than a nanosecond", text);
            return NULL;
        }
        extra += (int64_t)(f.a - k) * unit;
        out = p1;
        out.days += extra / INT64_C(86400000000000);
        extra %= INT64_C(86400000000000);
        out.hours += extra / INT64_C(3600000000000);
        extra %= INT64_C(3600000000000);
        out.minutes += extra / INT64_C(60000000000);
        extra %= INT64_C(60000000000);
        out.seconds += extra / INT64_C(1000000000);
        out.nanoseconds += extra % INT64_C(1000000000);
        {
            SV *d = (TKN_TK->new_duration_sv)(aTHX_ &out);
            return d ? sv_2mortal(d) : NULL;
        }
    }
    return NULL;
}

/* A relative phrase's fraction: "in 1.5 hours", "2.5 days ago". Only a
 * phrase the relative reader reads, so a time written with a full stop
 * ("3.30 pm") is not taken for a count. */
static SV *
tkn_frac_phrase(pTHX_ SV *self, tkn_lexicon *L, SV *text, HV *info)
{
    tkn_frac f;
    size_t t;
    if (!tkn_frac_find(aTHX_ L, text, &f))
        return NULL;
    for (t = 0; t < sizeof tkn_frac_tries / sizeof tkn_frac_tries[0]; t++) {
        IV k = tkn_frac_tries[t] < 0 ? f.a : tkn_frac_tries[t];
        HV *s1 = tkn_info_new(aTHX), *s2 = tkn_info_new(aTHX);
        SV *t1 = tkn_frac_with(aTHX_ &f, k), *t2 = tkn_frac_with(aTHX_ &f, k + 1), *v1, *v2;
        time_keeper_point a, b;
        int64_t unit, extra, total;
        v1 = tkn_relative(aTHX_ self, L, tkn_key_sv(aTHX_ L, t1), s1, NULL);
        v2 = v1 ? tkn_relative(aTHX_ self, L, tkn_key_sv(aTHX_ L, t2), s2, NULL) : NULL;
        if (!v1 || !v2)
            continue;
        tkn_pt(aTHX_ v1, &a);
        tkn_pt(aTHX_ v2, &b);
        unit = (b.inst.sec - a.inst.sec) * INT64_C(1000000000) + (b.inst.nsec - a.inst.nsec);
        if (!unit)
            continue;
        if (unit >= INT64_C(28) * 86400 * 1000000000 || unit <= -INT64_C(28) * 86400 * 1000000000) {
            int64_t days = (unit < 0 ? -unit : unit) / INT64_C(86400000000000);
            tkn_frac_reason(aTHX_ info, days >= 360 ? "a year has no fixed length" : days >= 85 ? "a quarter has no fixed length" : "a month has no fixed length", text);
            return NULL;
        }
        if (!tkn_frac_of(&f, unit, &extra)) {
            tkn_frac_reason(aTHX_ info, "a fraction finer than a nanosecond", text);
            return NULL;
        }
        total = (int64_t)(f.a - k) * unit + extra;
        {
            SV *args[4];
            int64_t at = total < 0 ? -total : total;
            args[0] = sv_2mortal(newSVpvs("seconds"));
            args[1] = sv_2mortal(newSViv((IV)(at / 1000000000)));
            args[2] = sv_2mortal(newSVpvs("nanoseconds"));
            args[3] = sv_2mortal(newSViv((IV)(at % 1000000000)));
            tkn_info_set(aTHX_ info, s1);
            return tkn_method(aTHX_ v1, total < 0 ? "minus" : "plus", args, 4);
        }
    }
    return NULL;
}

#endif
