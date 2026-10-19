#ifndef TKR_WALK_SV_H
#define TKR_WALK_SV_H

/* The walk's ends in Perl: instants in and values out, the words for a
 * rule that can never fire or a skipped wall time it will not have, and
 * the iterator's state on its code ref. */

static int64_t
tkr_instant_arg(pTHX_ SV *sv, const char *what)
{
    time_keeper_instant in;
    if (!sv || !SvOK(sv) || (tkr_tk(aTHX)->from_sv)(aTHX_ sv, &in, NULL, NULL) != TIME_KEEPER_OK)
        croak("%s: a Time::Keeper value is wanted", what);
    return in.sec;
}

static int64_t
tkr_now_sec(pTHX)
{
    time_keeper_instant t;
    (tkr_tk(aTHX)->now)(&t);
    return t.sec;
}

/* An occurrence carries the start's fraction of a second; a cron's is 0. */
static int32_t
tkr_occurrence_nsec(const tkr_rule *r)
{
    return (r->flags & TKR_F_HAS_START) && !(r->flags & TKR_F_CRON) ? r->start.nsec : 0;
}

static SV *
tkr_occurrence_sv(pTHX_ const tkr_rule *r, int64_t sec, const char *what)
{
    time_keeper_instant t;
    SV *sv;
    t.sec = sec;
    t.nsec = tkr_occurrence_nsec(r);
    sv = (r->flags & TKR_F_RSCALE) ? (tkr_tk(aTHX)->new_sv_cal)(aTHX_ &t, &r->zone, r->locale, r->calendar)
                                   : (tkr_tk(aTHX)->new_sv)(aTHX_ &t, &r->zone, r->locale);
    if (!sv)
        croak("%s: an occurrence outside the years Time::Keeper holds", what);
    return sv;
}

static void
tkr_rc_croak(pTHX_ int rc, const tkr_rule *r, int64_t wall, const char *what)
{
    if (rc == TKR_W_NEVER)
        croak("%s: the rule can never fire (no occurrence within %s)", what,
              (r->flags & TKR_F_CRON) ? "five years" : "fifty years");
    if (rc == TKR_W_FAIL) {
        int64_t days = tkr_floor_div(wall, 86400), rem = wall - days * 86400, y;
        unsigned m, d;
        SV *zone = sv_2mortal(tkr_zone_name_sv(aTHX_ r));
        tkr_civil_from_days(days, &y, &m, &d);
        croak("%s: the clocks of %" SVf " skipped %04" IVdf "-%02u-%02u %02d:%02d:%02d, and the rule says fail", what,
              SVfARG(zone), (IV)y, m, d, (int)(rem / 3600), (int)(rem % 3600 / 60), (int)(rem % 60));
    }
}

/* An iterator: a walk, and the moment its occurrences must follow. */
typedef struct tkr_iter {
    tkr_walk w;
    int64_t  from;
    int      inclusive;
} tkr_iter;

static int
tkr_iter_free(pTHX_ SV *sv, MAGIC *mg)
{
    tkr_iter *it = (tkr_iter *)SvPVX(mg->mg_obj);
    PERL_UNUSED_VAR(sv);
    tkr_walk_free(&it->w);
    return 0;
}

static MGVTBL tkr_iter_vtbl = { 0, 0, 0, 0, tkr_iter_free, 0, 0, 0 };

static tkr_iter *
tkr_iter_of(pTHX_ CV *cv, const char *what)
{
    MAGIC *mg;
    for (mg = SvMAGIC((SV *)cv); mg; mg = mg->mg_moremagic)
        if (mg->mg_type == PERL_MAGIC_ext && mg->mg_virtual == &tkr_iter_vtbl)
            return (tkr_iter *)SvPVX(mg->mg_obj);
    croak("%s: not an iterator", what);
    return NULL;
}

#endif
