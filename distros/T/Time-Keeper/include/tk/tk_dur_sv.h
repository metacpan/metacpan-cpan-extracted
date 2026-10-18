#ifndef TK_DUR_SV_H
#define TK_DUR_SV_H

/* Durations as Perl values: a blessed reference to a read-only string of
 * one tk_duration, made and checked as values are. */

static SV *
tk_dur_new_sv(pTHX_ HV *stash, const tk_duration *d)
{
    SV *inner = newSVpvn((const char *)d, sizeof *d);
    SV *ref = sv_bless(newRV_noinc(inner), stash);
    return ref;
}

static HV *
tk_dur_stash_for(pTHX_ SV *class_or_obj)
{
    dMY_CXT;
    if (SvROK(class_or_obj) && SvOBJECT(SvRV(class_or_obj)))
        return SvSTASH(SvRV(class_or_obj));
    if (SvPOK(class_or_obj) && SvCUR(class_or_obj) == 22
        && memEQ(SvPVX(class_or_obj), "Time::Keeper::Duration", 22))
        return MY_CXT.dstash;
    return gv_stashsv(class_or_obj, GV_ADD);
}

static int
tk_is_dur(pTHX_ SV *sv)
{
    SV *in;
    dMY_CXT;
    if (!SvROK(sv))
        return 0;
    in = SvRV(sv);
    if (!SvOBJECT(in) || SvROK(in) || !SvPOK(in) || SvCUR(in) != sizeof(tk_duration))
        return 0;
    return SvSTASH(in) == MY_CXT.dstash || sv_derived_from(sv, "Time::Keeper::Duration");
}

static const tk_duration *
tk_dur_of(pTHX_ SV *sv, const char *what)
{
    const tk_duration *d;
    if (!tk_is_dur(aTHX_ sv))
        croak("%s: not a Time::Keeper::Duration", what);
    d = (const tk_duration *)SvPVX(SvRV(sv));
    if (!tk_dur_in_range(d->months) || !tk_dur_in_range(d->days)
        || !tk_dur_in_range(d->minutes) || !tk_dur_in_range(d->seconds)
        || d->nsec <= -TK_NSECS_PER_SEC || d->nsec >= TK_NSECS_PER_SEC
        || (d->seconds > 0 && d->nsec < 0) || (d->seconds < 0 && d->nsec > 0)
        || d->eom > TK_EOM_PRESERVE)
        croak("%s: a damaged Time::Keeper::Duration", what);
    return d;
}

/* The stash a new duration made from a value's method is blessed into. */
static HV *
tk_dur_stash(pTHX)
{
    dMY_CXT;
    return MY_CXT.dstash;
}

/* A duration frozen as text: "tkd1 months days minutes seconds nsec eom". */
static SV *
tk_dur_freeze_sv(pTHX_ const tk_duration *d)
{
    static const char *const eoms[] = { "wrap", "limit", "preserve" };
    SV *out = newSVpvs("tkd1 ");
    sv_catsv(out, sv_2mortal(tk_newSVi64(aTHX_ d->months)));
    sv_catpvs(out, " ");
    sv_catsv(out, sv_2mortal(tk_newSVi64(aTHX_ d->days)));
    sv_catpvs(out, " ");
    sv_catsv(out, sv_2mortal(tk_newSVi64(aTHX_ d->minutes)));
    sv_catpvs(out, " ");
    sv_catsv(out, sv_2mortal(tk_newSVi64(aTHX_ d->seconds)));
    sv_catpvf(out, " %ld %s", (long)d->nsec, eoms[d->eom < 3 ? d->eom : 0]);
    return out;
}

static void
tk_dur_thaw(pTHX_ SV *frozen, tk_duration *d, const char *what)
{
    STRLEN len;
    const char *s = SvPV(frozen, len), *end = s + len, *p;
    int64_t parts[5];
    int i;

    if (len < 5 || memNE(s, "tkd1 ", 5))
        croak("%s: not a frozen Time::Keeper::Duration", what);
    p = s + 5;
    for (i = 0; i < 5; i++) {
        const char *q = p;
        while (q < end && *q != ' ')
            q++;
        if (q == p || !tk_sv_to_i64(aTHX_ sv_2mortal(newSVpvn(p, q - p)), &parts[i]) || q == end)
            croak("%s: not a frozen Time::Keeper::Duration", what);
        p = q + 1;
    }
    Zero(d, 1, tk_duration);
    d->months = parts[0];
    d->days = parts[1];
    d->minutes = parts[2];
    d->seconds = parts[3];
    if (parts[4] < -TK_NSECS_PER_SEC || parts[4] > TK_NSECS_PER_SEC
        || !tk_dur_normalize(d, parts[4]))
        croak("%s: not a frozen Time::Keeper::Duration", what);
    d->eom = (uint8_t)tk_opt_eom(aTHX_ sv_2mortal(newSVpvn(p, end - p)), what);
}

#endif
