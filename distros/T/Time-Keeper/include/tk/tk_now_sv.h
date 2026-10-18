#ifndef TK_NOW_SV_H
#define TK_NOW_SV_H

/* The clock the constructors read: the system's, unless
 * $Time::Keeper::CLOCK is defined. A value or an epoch pins the clock; a
 * code ref is called for each reading and gives a value or an epoch. While
 * the code ref runs the system clock is read, so it may call now itself.
 * The glob is held, not its scalar: `local` puts a new scalar in the glob
 * and restores the old one after the block. */

static void
tk_clock_instant(pTHX_ SV *sv, tk_instant *t, const char *what)
{
    if (tk_is_value(aTHX_ sv)) {
        *t = tk_value_of(aTHX_ sv, "Time::Keeper::CLOCK")->inst;
        return;
    }
    if (!SvOK(sv) || SvROK(sv))
        croak("%s must be a Time::Keeper value, an epoch or a code ref returning one", what);
    tk_epoch_from_sv(aTHX_ sv, t, what);
    if (!tk_instant_valid(t))
        croak("%s: out of range", what);
}

static void
tk_now_sv(pTHX_ tk_instant *t)
{
    dMY_CXT;
    SV *clock = MY_CXT.clock ? GvSV(MY_CXT.clock) : NULL;
    if (!clock || !SvOK(clock) || MY_CXT.in_clock) {
        tk_now(t);
        return;
    }
    if (SvROK(clock) && SvTYPE(SvRV(clock)) == SVt_PVCV) {
        dSP;
        ENTER;
        SAVETMPS;
        SAVEINT(MY_CXT.in_clock);
        MY_CXT.in_clock = 1;
        PUSHMARK(SP);
        PUTBACK;
        call_sv(clock, G_SCALAR);
        SPAGAIN;
        tk_clock_instant(aTHX_ POPs, t, "the code ref in $Time::Keeper::CLOCK");
        PUTBACK;
        FREETMPS;
        LEAVE;
        return;
    }
    tk_clock_instant(aTHX_ clock, t, "$Time::Keeper::CLOCK");
}

#endif
