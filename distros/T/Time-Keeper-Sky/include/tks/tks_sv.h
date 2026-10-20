#ifndef TKS_SV_H
#define TKS_SV_H

/* Reading an instant from what a caller passes: a Time::Keeper value, or
 * an epoch as a number (a fraction allowed, kept to the nanosecond the
 * double holds). */
static void
tks_instant_arg(pTHX_ SV *sv, time_keeper_instant *out, const char *what)
{
    if (sv)
        SvGETMAGIC(sv);
    if (!sv || !SvOK(sv))
        croak("%s needs a Time::Keeper value or an epoch", what);
    if (SvROK(sv)) {
        if ((tks_tk(aTHX)->from_sv)(aTHX_ sv, out, NULL, NULL) != TIME_KEEPER_OK)
            croak("%s: not a Time::Keeper value", what);
        return;
    }
    if (!looks_like_number(sv))
        croak("%s: '%" SVf "' is neither a Time::Keeper value nor an epoch", what, SVfARG(sv));
    {
        NV n = SvNV(sv);
        double f = floor((double)n);
        out->sec = (int64_t)f;
        out->nsec = (int32_t)(((double)n - f) * 1e9 + 0.5);
        if (out->nsec >= 1000000000) {
            out->sec++;
            out->nsec -= 1000000000;
        }
    }
}

#endif
