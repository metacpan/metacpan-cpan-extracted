#ifndef TKR_ABI_IMPL_H
#define TKR_ABI_IMPL_H

/* The table time_keeper_recurrence_abi.h declares. A handle holds a
 * reference to a rule or set object, so compile goes through the Perl
 * constructors (under G_EVAL, their words becoming err) and every check
 * they make is kept; next and previous, cron_next and rrule_next run the
 * walk directly. Every entry returns a code. */

#define TKR_HANDLE_MAGIC 0x484b5254u

struct time_keeper_recurrence {
    uint32_t magic;
    int      is_set;
    SV      *obj;                /* a reference to the rule or set */
};

static void
tkra_err(char *err, size_t errlen, const char *fmt, ...)
{
    va_list ap;
    if (!err || !errlen)
        return;
    va_start(ap, fmt);
    vsnprintf(err, errlen, fmt, ap);
    va_end(ap);
}

/* A die's words without its " at FILE line N." */
static void
tkra_err_from_sv(pTHX_ SV *e, char *err, size_t errlen)
{
    STRLEN len;
    const char *s = SvPV(e, len), *at;
    while (len && (s[len - 1] == '\n' || s[len - 1] == '.'))
        len--;
    for (at = s + len; at > s; at--)
        if (at + 4 <= s + len && memcmp(at, " at ", 4) == 0)
            break;
    if (at > s) {
        const char *ln = at;
        while (ln + 6 <= s + len && memcmp(ln, " line ", 6) != 0)
            ln++;
        if (ln + 6 <= s + len) {
            const char *d = ln + 6;
            while (d < s + len && isDIGIT(*d)) d++;
            if (d == s + len || *d == ',')
                len = (STRLEN)(at - s);
        }
    }
    tkra_err(err, errlen, "%.*s", (int)len, s);
}

static time_keeper_recurrence *
tkra_handle_new(pTHX_ SV *obj)
{
    time_keeper_recurrence *h;
    Newx(h, 1, time_keeper_recurrence);
    h->magic = TKR_HANDLE_MAGIC;
    h->is_set = sv_derived_from(obj, "Time::Keeper::Recurrence::Set");
    h->obj = newSVsv(obj);
    return h;
}

static int
tkra_handle_ok(const time_keeper_recurrence *h)
{
    return h && h->magic == TKR_HANDLE_MAGIC && h->obj && SvROK(h->obj);
}

/* A constructor called as Perl would, with its die caught. */
static int
tkra_construct(pTHX_ const char *method, SV **args, int nargs, SV **out, char *err, size_t errlen)
{
    dSP;
    int count, i, rc = TIME_KEEPER_RECURRENCE_BAD;
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpvs("Time::Keeper::Recurrence")));
    for (i = 0; i < nargs; i++)
        XPUSHs(args[i]);
    PUTBACK;
    count = call_method(method, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        tkra_err_from_sv(aTHX_ ERRSV, err, errlen);
    else if (count == 1) {
        SV *got = POPs;
        if (SvROK(got)) {
            *out = newSVsv(got);
            rc = TIME_KEEPER_RECURRENCE_OK;
        }
        else
            tkra_err(err, errlen, "%s gave no rule", method);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return rc;
}

static int
tkra_compile(pTHX_ int kind, const char *spec, size_t len, const time_keeper_zone *zone,
             const time_keeper_instant *start, int gap, int overlap,
             time_keeper_recurrence **out, char *err, size_t errlen)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    time_keeper_zone utc;
    SV *args[10], *obj = NULL;
    int n = 0, rc;
    if (err && errlen)
        err[0] = '\0';
    if (!spec || !out) {
        tkra_err(err, errlen, "compile: no spec or no place for the handle");
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    if (gap < -1 || gap > 3 || overlap < -1 || overlap > 2) {
        tkra_err(err, errlen, "compile: gap is -1 to 3 and overlap -1 to 2");
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    utc.kind = TIME_KEEPER_ZONE_UTC;
    utc.value = 0;
    if (!zone)
        zone = &utc;
    ENTER;
    SAVETMPS;
    switch (kind) {
    case TIME_KEEPER_RECURRENCE_RRULE:
    case TIME_KEEPER_RECURRENCE_CRON: {
        if (kind == TIME_KEEPER_RECURRENCE_RRULE && !start) {
            tkra_err(err, errlen, "compile: an RRULE needs a start");
            rc = TIME_KEEPER_RECURRENCE_BAD;
            goto done;
        }
        if (kind == TIME_KEEPER_RECURRENCE_CRON)
            args[n++] = sv_2mortal(newSVpvn(spec, len));
        else {
            args[n++] = sv_2mortal(newSVpvs("rrule"));
            args[n++] = sv_2mortal(newSVpvn(spec, len));
        }
        if (start) {
            SV *s = (T->new_sv)(aTHX_ start, zone, 0);
            if (!s) {
                tkra_err(err, errlen, "compile: the start is outside the years Time::Keeper holds");
                rc = TIME_KEEPER_RECURRENCE_RANGE;
                goto done;
            }
            args[n++] = sv_2mortal(newSVpvs("start"));
            args[n++] = sv_2mortal(s);
        }
        else {
            tkr_rule probe;
            tkr_rule_init(&probe);
            probe.zone = *zone;
            args[n++] = sv_2mortal(newSVpvs("zone"));
            args[n++] = sv_2mortal(tkr_zone_name_sv(aTHX_ &probe));
        }
        if (gap >= 0) {
            args[n++] = sv_2mortal(newSVpvs("gap"));
            args[n++] = sv_2mortal(newSVpv(tkr_gap_names[gap], 0));
        }
        if (overlap >= 0) {
            args[n++] = sv_2mortal(newSVpvs("overlap"));
            args[n++] = sv_2mortal(newSVpv(tkr_overlap_names[overlap], 0));
        }
        rc = tkra_construct(aTHX_ kind == TIME_KEEPER_RECURRENCE_CRON ? "cron" : "new", args, n, &obj, err, errlen);
        break;
    }
    case TIME_KEEPER_RECURRENCE_ICAL:
        args[n++] = sv_2mortal(newSVpvn(spec, len));
        rc = tkra_construct(aTHX_ "parse_ical", args, n, &obj, err, errlen);
        break;
    default:
        tkra_err(err, errlen, "compile: kind %d is not RRULE, CRON or ICAL", kind);
        rc = TIME_KEEPER_RECURRENCE_BAD;
    }
  done:
    FREETMPS;
    LEAVE;
    if (rc == TIME_KEEPER_RECURRENCE_OK) {
        *out = tkra_handle_new(aTHX_ obj);
        SvREFCNT_dec(obj);
    }
    return rc;
}

static int
tkra_rc(int rc)
{
    switch (rc) {
    case TKR_W_GOT:  return TIME_KEEPER_RECURRENCE_OK;
    case TKR_W_FAIL: return TIME_KEEPER_RECURRENCE_GAP;
    default:         return TIME_KEEPER_RECURRENCE_NONE;
    }
}

/* next (dir 0) or previous (dir 1) on a handle. */
static int
tkra_walk(pTHX_ const time_keeper_recurrence *h, const time_keeper_instant *from, time_keeper_instant *out, int dir)
{
    int64_t got = 0;
    int rc;
    int32_t nsec;
    if (!tkra_handle_ok(h) || !from || !out)
        return TIME_KEEPER_RECURRENCE_BAD;
    if (h->is_set) {
        const tkr_set *s = tkr_set_of(aTHX_ h->obj, "Time::Keeper::Recurrence ABI");
        if (dir)
            rc = tkr_set_previous(aTHX_ h->obj, from->sec, &got, NULL);
        else {
            tkr_setiter it;
            rc = tkr_setiter_init(aTHX_ &it, h->obj, from->sec, 0, 0);
            if (rc == TKR_W_GOT)
                rc = tkr_setiter_next(aTHX_ &it, &got);
            tkr_setiter_free(aTHX_ &it);
        }
        nsec = tkr_set_nsec(s);
    }
    else {
        const tkr_rule *r = tkr_rule_of(aTHX_ h->obj, "Time::Keeper::Recurrence ABI");
        if (r->flags & TKR_F_EVERY) {
            got = dir ? from->sec - r->every_sec : from->sec + r->every_sec;
            rc = TKR_W_GOT;
        }
        else
            rc = dir ? tkr_previous_before(aTHX_ r, from->sec, &got, NULL) : tkr_next_after(aTHX_ r, from->sec, 0, &got, NULL);
        nsec = tkr_occurrence_nsec(r);
    }
    if (rc != TKR_W_GOT)
        return tkra_rc(rc);
    out->sec = got;
    out->nsec = nsec;
    return TIME_KEEPER_RECURRENCE_OK;
}

static int
tkra_next(pTHX_ const time_keeper_recurrence *h, const time_keeper_instant *from, time_keeper_instant *out)
{
    return tkra_walk(aTHX_ h, from, out, 0);
}

static int
tkra_previous(pTHX_ const time_keeper_recurrence *h, const time_keeper_instant *from, time_keeper_instant *out)
{
    return tkra_walk(aTHX_ h, from, out, 1);
}

static void
tkra_release(time_keeper_recurrence *h)
{
    dTHX;
    if (!h || h->magic != TKR_HANDLE_MAGIC)
        return;
    h->magic = 0;
    SvREFCNT_dec(h->obj);
    h->obj = NULL;
    Safefree(h);
}

/* An epoch as seconds and nanoseconds; 0 outside the years Time::Keeper holds. */
static int
tkra_epoch_in(double e, int64_t *sec, int32_t *nsec)
{
    double f;
    if (!(e == e) || e > 3.15e16 || e < -3.15e16)
        return 0;
    f = floor(e);
    *sec = (int64_t)f;
    *nsec = (int32_t)((e - f) * 1e9 + 0.5);
    if (*nsec >= 1000000000) { *sec += 1; *nsec -= 1000000000; }
    return 1;
}

static int
tkra_zone_in(pTHX_ const char *zone, size_t zlen, time_keeper_zone *z, char *err, size_t errlen)
{
    z->kind = TIME_KEEPER_ZONE_UTC;
    z->value = 0;
    if (!zone || !zlen)
        return 1;
    if ((tkr_tk(aTHX)->zone_parse)(aTHX_ zone, zlen, z) == TIME_KEEPER_OK)
        return 1;
    tkra_err(err, errlen, "'%.*s' is not a time zone", (int)(zlen < 60 ? zlen : 60), zone);
    return 0;
}

static int
tkra_cron_next(pTHX_ const char *expr, size_t elen, const char *zone, size_t zlen,
               double from, double *out, char *err, size_t errlen)
{
    tkr_rule r;
    char e[TKR_ERR];
    int64_t f, got;
    int32_t fn;
    int rc;
    if (err && errlen)
        err[0] = '\0';
    if (!expr || !out) {
        tkra_err(err, errlen, "cron_next: no expression or no place for the answer");
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    if (!tkra_epoch_in(from, &f, &fn))
        return TIME_KEEPER_RECURRENCE_RANGE;
    tkr_rule_init(&r);
    r.gap = TKR_GAP_SKIP;
    r.overlap = TKR_OVERLAP_BOTH;
    if (!tkra_zone_in(aTHX_ zone, zlen, &r.zone, err, errlen))
        return TIME_KEEPER_RECURRENCE_BAD;
    if (!tkr_cron_parse(expr, elen, &r, e)) {
        tkra_err(err, errlen, "%s", e);
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    if (r.flags & TKR_F_EVERY) {
        *out = from + (double)r.every_sec;
        return TIME_KEEPER_RECURRENCE_OK;
    }
    rc = tkr_next_after(aTHX_ &r, f, 0, &got, NULL);
    if (rc != TKR_W_GOT)
        return tkra_rc(rc);
    *out = (double)got;
    return TIME_KEEPER_RECURRENCE_OK;
}

static int
tkra_rrule_next(pTHX_ const char *rrule, size_t rlen, const char *zone, size_t zlen,
                double start, double from, double *out, char *err, size_t errlen)
{
    tkr_rule r;
    char e[TKR_ERR];
    int64_t f, got;
    int32_t fn;
    int rc;
    time_keeper_calfields cf;
    if (err && errlen)
        err[0] = '\0';
    if (!rrule || !out) {
        tkra_err(err, errlen, "rrule_next: no rule or no place for the answer");
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    tkr_rule_init(&r);
    r.gap = TKR_GAP_FORWARD;
    r.overlap = TKR_OVERLAP_EARLIER;
    if (!tkra_epoch_in(start, &r.start.sec, &r.start.nsec) || !tkra_epoch_in(from, &f, &fn))
        return TIME_KEEPER_RECURRENCE_RANGE;
    r.flags |= TKR_F_HAS_START;
    if (!tkra_zone_in(aTHX_ zone, zlen, &r.zone, err, errlen))
        return TIME_KEEPER_RECURRENCE_BAD;
    if (!tkr_rrule_parse(rrule, rlen, &r, e)) {
        tkra_err(err, errlen, "%s", e);
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    if (r.until_kind == TKR_UNTIL_FLOATING && r.zone.kind != TIME_KEEPER_ZONE_FLOATING) {
        tkra_err(err, errlen, "UNTIL must be in UTC (end in Z) when the start has a zone");
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    if (r.until_kind == TKR_UNTIL_UTC && r.zone.kind == TIME_KEEPER_ZONE_FLOATING) {
        tkra_err(err, errlen, "UNTIL must be floating (no Z) when the start is");
        return TIME_KEEPER_RECURRENCE_BAD;
    }
    if ((r.flags & TKR_F_RSCALE) && (tkr_tk(aTHX)->cal_fields)(aTHX_ &r.start, &r.zone, r.calendar, &cf) != TIME_KEEPER_OK)
        return TIME_KEEPER_RECURRENCE_RANGE;
    rc = tkr_next_after(aTHX_ &r, f, 0, &got, NULL);
    if (rc != TKR_W_GOT)
        return tkra_rc(rc);
    *out = (double)got + (double)r.start.nsec / 1e9;
    return TIME_KEEPER_RECURRENCE_OK;
}

static SV *
tkra_new_sv(pTHX_ const time_keeper_recurrence *h)
{
    if (!tkra_handle_ok(h))
        return NULL;
    return newSVsv(h->obj);
}

static int
tkra_from_sv(pTHX_ SV *sv, time_keeper_recurrence **out)
{
    if (!sv || !out || !SvROK(sv) || !sv_isobject(sv)
        || !(sv_derived_from(sv, "Time::Keeper::Recurrence") || sv_derived_from(sv, "Time::Keeper::Recurrence::Set")))
        return TIME_KEEPER_RECURRENCE_BAD;
    *out = tkra_handle_new(aTHX_ sv);
    return TIME_KEEPER_RECURRENCE_OK;
}

static const time_keeper_recurrence_abi TKR_ABI = {
    TIME_KEEPER_RECURRENCE_ABI_VERSION,
    tkra_compile,
    tkra_next,
    tkra_previous,
    tkra_release,
    tkra_cron_next,
    tkra_rrule_next,
    tkra_new_sv,
    tkra_from_sv,
};

#endif
