#ifndef TK_ARITH_SV_H
#define TK_ARITH_SV_H

/* What plus and minus are given: a duration (and gap and overlap), or the
 * units of one by name. */
static void
tk_plus_args(pTHX_ SV **st, I32 n, tk_duration *d, int *gap, int *overlap, const char *what)
{
    tk_dur_args a;
    if (n >= 1 && tk_is_dur(aTHX_ st[0])) {
        *d = *tk_dur_of(aTHX_ st[0], what);
        tk_dur_args_parse(aTHX_ st + 1, n - 1, TK_D(TK_D_GAP) | TK_D(TK_D_OVERLAP), &a, what);
    }
    else {
        tk_dur_args_parse(aTHX_ st, n, TK_D_UNITS | TK_D(TK_D_GAP) | TK_D(TK_D_OVERLAP), &a, what);
        tk_dur_from_args(aTHX_ &a, d, what);
    }
    *gap = a.v[TK_D_GAP] ? tk_opt_gap(aTHX_ a.v[TK_D_GAP], what) : TK_GAP_DEFAULT;
    *overlap = a.v[TK_D_OVERLAP] ? tk_opt_overlap(aTHX_ a.v[TK_D_OVERLAP], what) : TK_OVERLAP_DEFAULT;
}

static void
tk_dur_negate(tk_duration *d, int eom_given)
{
    d->months = -d->months;
    d->days = -d->days;
    d->minutes = -d->minutes;
    d->seconds = -d->seconds;
    d->nsec = -d->nsec;
    if (!eom_given)
        d->eom = tk_dur_default_eom(d->months);
}

/* Order two values as the comparison operators do: by instant, or by wall
 * clock when either is floating. */
static int
tk_value_cmp(const tk_value *x, const tk_value *y)
{
    int64_t xs = x->inst.sec, ys = y->inst.sec;
    if (x->zone == TK_ZONE_FLOATING || y->zone == TK_ZONE_FLOATING) {
        xs += x->utoff;
        ys += y->utoff;
    }
    if (xs != ys)
        return xs < ys ? -1 : 1;
    return x->inst.nsec < y->inst.nsec ? -1 : x->inst.nsec > y->inst.nsec;
}

#endif
