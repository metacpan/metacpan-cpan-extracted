# Doors onto the TZ string evaluator, for the tests only: a rule, or a
# whole footer, made up by the test rather than taken from a zone, so the
# forms no zone uses today are tested too.

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

# Local seconds of a rule in a year. kind: M, J or n.
SV *
_rule_local(kind, month, week, wday, day, time, year)
        const char *kind
        int month
        int week
        int wday
        int day
        int time
        SV *year
    PREINIT:
        tkz_rule r;
    CODE:
        r.kind = kind[0] == 'M' ? TKZ_RULE_MONTH : kind[0] == 'J' ? TKZ_RULE_JULIAN : TKZ_RULE_DAY;
        r.month = (uint8_t)month;
        r.week = (uint8_t)week;
        r.wday = (uint8_t)wday;
        r.day = (uint16_t)day;
        r.time = time;
        RETVAL = tkz_newSVi64(aTHX_ tkz_rule_local(&r, tkz_sv_i64(aTHX_ year)));
    OUTPUT:
        RETVAL

# A footer of the test's own, evaluated at t. Returns whether it is DST
# and the next change, the latter missing when there is none. start and
# end are [kind, month, week, wday, day, time].
void
_footer_eval(std_utoff, dst_utoff, start, end, t)
        int std_utoff
        int dst_utoff
        AV *start
        AV *end
        SV *t
    PREINIT:
        tkz_footer f;
        int64_t next;
        uint16_t ty;
        int k;
    PPCODE:
        Zero(&f, 1, tkz_footer);
        f.std_utoff = std_utoff;
        f.dst_utoff = dst_utoff;
        f.std_type = 1;
        f.dst_type = 2;
        for (k = 0; k < 2; k++) {
            AV *a = k ? end : start;
            tkz_rule *r = k ? &f.end : &f.start;
            const char *kd = SvPV_nolen(*av_fetch(a, 0, 0));
            r->kind = kd[0] == 'M' ? TKZ_RULE_MONTH : kd[0] == 'J' ? TKZ_RULE_JULIAN : TKZ_RULE_DAY;
            r->month = (uint8_t)SvIV(*av_fetch(a, 1, 0));
            r->week = (uint8_t)SvIV(*av_fetch(a, 2, 0));
            r->wday = (uint8_t)SvIV(*av_fetch(a, 3, 0));
            r->day = (uint16_t)SvIV(*av_fetch(a, 4, 0));
            r->time = (int32_t)SvIV(*av_fetch(a, 5, 0));
        }
        ty = tkz_footer_at(&f, tkz_sv_i64(aTHX_ t), &next);
        EXTEND(SP, 2);
        mPUSHi(ty == 2);
        if (next == TKZ_NO_CHANGE)
            PUSHs(&PL_sv_undef);
        else
            mPUSHs(tkz_newSVi64(aTHX_ next));
