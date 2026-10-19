#ifndef TKR_SET_SV_H
#define TKR_SET_SV_H

/* The set's ends in Perl: values out, dates in from with(), the words for
 * a set that cannot go on, and the iterator's state on its code ref. */

static int32_t
tkr_set_nsec(const tkr_set *s)
{
    return s->has_start ? s->start.nsec : 0;
}

static SV *
tkr_set_value_sv(pTHX_ const tkr_set *s, int64_t sec, const char *what)
{
    time_keeper_instant t;
    SV *sv;
    t.sec = sec;
    t.nsec = tkr_set_nsec(s);
    if (s->n_rules && (tkr_set_rules(s)[0].flags & TKR_F_RSCALE))
        sv = (tkr_tk(aTHX)->new_sv_cal)(aTHX_ &t, &s->zone, s->locale, tkr_set_rules(s)[0].calendar);
    else
        sv = (tkr_tk(aTHX)->new_sv)(aTHX_ &t, &s->zone, s->locale);
    if (!sv)
        croak("%s: an occurrence outside the years Time::Keeper holds", what);
    return sv;
}

/* A whole day as a Time::Keeper::Date. */
static SV *
tkr_date_sv(pTHX_ int64_t days, int locale)
{
    dSP;
    SV *got = NULL;
    int n;
    PERL_UNUSED_VAR(locale);
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Time::Keeper::Date")));
    XPUSHs(sv_2mortal(newSViv((IV)days)));
    PUTBACK;
    n = call_method("from_epoch_days", G_SCALAR);
    SPAGAIN;
    if (n == 1) {
        SV *r = POPs;
        got = SvREFCNT_inc_simple_NN(r);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return got ? got : &PL_sv_undef;
}

/* A Time::Keeper::Date's day number. */
static int
tkr_date_days_of(pTHX_ SV *sv, int64_t *days)
{
    dSP;
    int n, ok = 0;
    if (!SvROK(sv) || !sv_derived_from(sv, "Time::Keeper::Date"))
        return 0;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv);
    PUTBACK;
    n = call_method("epoch_days", G_SCALAR);
    SPAGAIN;
    if (n == 1) {
        SV *r = POPs;
        if (SvOK(r)) {
            *days = (int64_t)SvIV(r);
            ok = 1;
        }
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return ok;
}

/* One value to with(): a date added or removed (a Time::Keeper value, a
 * Time::Keeper::Date or a YYYY-MM-DD string for a whole day), or a rule. */
static void
tkr_with_one(pTHX_ tkr_set_parts *p, int ex, SV *v, const char *what)
{
    time_keeper_instant in;
    int64_t days;
    STRLEN len;
    const char *s;
    if (ex == 2) {
        const tkr_rule *r;
        if (!v || !SvROK(v) || !sv_derived_from(v, "Time::Keeper::Recurrence") || sv_derived_from(v, "Time::Keeper::Recurrence::Set")) {
            tkr_parts_free(p);
            croak("%s: rule takes Time::Keeper::Recurrence rules", what);
        }
        r = tkr_rule_of(aTHX_ v, what);
        tkr_parts_join_rule(aTHX_ p, r, what);
        return;
    }
    if (v && SvROK(v) && tkr_date_days_of(aTHX_ v, &days)) {
        tkr_parts_add_date(aTHX_ p, ex, days * 86400, 1, what);
        return;
    }
    if (v && SvROK(v) && (tkr_tk(aTHX)->from_sv)(aTHX_ v, &in, NULL, NULL) == TIME_KEEPER_OK) {
        tkr_parts_add_raw(aTHX_ p, ex, in.sec, 0, what);
        return;
    }
    if (v && SvOK(v) && !SvROK(v)) {
        int64_t wall;
        int kind;
        char compact[9];
        s = SvPV(v, len);
        if (len == 10 && s[4] == '-' && s[7] == '-') {
            memcpy(compact, s, 4); memcpy(compact + 4, s + 5, 2); memcpy(compact + 6, s + 8, 2);
            if (tkr_ical_value(compact, 8, &wall, &kind)) {
                tkr_parts_add_date(aTHX_ p, ex, wall, 1, what);
                return;
            }
        }
    }
    tkr_parts_free(p);
    croak("%s: %s takes Time::Keeper values, Time::Keeper::Date values or YYYY-MM-DD strings for whole days", what, ex ? "exdate" : "rdate");
}

/* with()'s key and value pairs, into the parts. */
static void
tkr_with_args(pTHX_ tkr_set_parts *p, SV **st, I32 n, const char *what)
{
    I32 i;
    if (n % 2) {
        tkr_parts_free(p);
        croak("%s: the arguments are key and value pairs", what);
    }
    for (i = 0; i < n; i += 2) {
        const char *k = SvPV_nolen(st[i]);
        SV *v = st[i + 1];
        int ex;
        if (strEQ(k, "rdate") || strEQ(k, "rdates")) ex = 0;
        else if (strEQ(k, "exdate") || strEQ(k, "exdates")) ex = 1;
        else if (strEQ(k, "rule") || strEQ(k, "rules")) ex = 2;
        else {
            tkr_parts_free(p);
            croak("%s: unknown argument '%s'", what, k);
        }
        if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) {
            AV *av = (AV *)SvRV(v);
            I32 j, m = av_len(av) + 1;
            for (j = 0; j < m; j++) {
                SV **e = av_fetch(av, j, 0);
                tkr_with_one(aTHX_ p, ex, e ? *e : &PL_sv_undef, what);
            }
        }
        else
            tkr_with_one(aTHX_ p, ex, v, what);
    }
}

static void
tkr_set_rc_croak(pTHX_ int rc, const tkr_set *s, int64_t wall, const char *what)
{
    tkr_rule probe;
    tkr_rule_init(&probe);
    probe.zone = s->zone;
    if (s->n_rules && (tkr_set_rules(s)[0].flags & TKR_F_CRON))
        probe.flags |= TKR_F_CRON;
    tkr_rc_croak(aTHX_ rc, &probe, wall, what);
}

static int
tkr_setiter_mg_free(pTHX_ SV *sv, MAGIC *mg)
{
    tkr_setiter *it = (tkr_setiter *)SvPVX(mg->mg_obj);
    PERL_UNUSED_VAR(sv);
    tkr_setiter_free(aTHX_ it);
    return 0;
}

static MGVTBL tkr_setiter_vtbl = { 0, 0, 0, 0, tkr_setiter_mg_free, 0, 0, 0 };

static tkr_setiter *
tkr_setiter_of(pTHX_ CV *cv, const char *what)
{
    MAGIC *mg;
    for (mg = SvMAGIC((SV *)cv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tkr_setiter_vtbl)
            return (tkr_setiter *)SvPVX(mg->mg_obj);
    croak("%s: not an iterator", what);
    return NULL;
}

#endif
