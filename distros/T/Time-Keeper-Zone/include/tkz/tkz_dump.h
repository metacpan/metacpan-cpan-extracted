#ifndef TKZ_DUMP_H
#define TKZ_DUMP_H

/* Perl views of table entries, for the test doors. */

static SV *
tkz_newSVi64(pTHX_ int64_t v)
{
#if IVSIZE >= 8
    return newSViv((IV)v);
#else
    if (v >= IV_MIN && v <= IV_MAX)
        return newSViv((IV)v);
    return newSVnv((NV)v);   /* transition times are under 2**53: exact */
#endif
}

/* A time for a door: an integer, or a number with no fraction, within
 * what an NV holds exactly. */
static int64_t
tkz_sv_i64(pTHX_ SV *sv)
{
    if (SvIOK(sv) && !SvIsUV(sv))
        return (int64_t)SvIV(sv);
    return (int64_t)SvNV(sv);
}

/* [utoff, isdst, abbreviation] */
static SV *
tkz_type_av(pTHX_ uint16_t i)
{
    const tkz_type *t = &tkz_types[i];
    AV *av = newAV();
    av_push(av, newSViv(t->utoff));
    av_push(av, newSVuv(t->isdst));
    av_push(av, newSVpv(tkz_abbrs + t->abbr, 0));
    return newRV_noinc((SV *)av);
}

static SV *
tkz_rule_hv(pTHX_ const tkz_rule *r)
{
    HV *hv = newHV();
    static const char *const kinds[] = { "none", "M", "J", "n" };
    (void)hv_stores(hv, "kind", newSVpv(kinds[r->kind], 0));
    (void)hv_stores(hv, "month", newSVuv(r->month));
    (void)hv_stores(hv, "week", newSVuv(r->week));
    (void)hv_stores(hv, "wday", newSVuv(r->wday));
    (void)hv_stores(hv, "day", newSVuv(r->day));
    (void)hv_stores(hv, "time", newSViv(r->time));
    return newRV_noinc((SV *)hv);
}

#endif
