#ifndef TKN_SURFACE_H
#define TKN_SURFACE_H

/* The parser object: a blessed hash of its options (now, zone, locale,
 * bare_hour, prefer), checked by new; the anchor; the locale's lexicon
 * and word table; the public methods around the readers. */

static const char *const tkn_options[7] = { "now", "zone", "locale", "bare_hour", "prefer", "keep_zone", "calendar" };

static SV *
tkn_opt(pTHX_ SV *self, const char *key)
{
    SV **e;
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        return NULL;
    e = hv_fetch((HV *)SvRV(self), key, (I32)strlen(key), 0);
    return e ? *e : NULL;
}

/* "at FILE line N." and its newline taken off a death. */
static SV *
tkn_strip_at(pTHX_ SV *err)
{
    STRLEN len;
    const char *b = SvPV_const(err, len), *e = b + len, *p;
    SV *out;
    if (e > b && e[-1] == '\n')
        e--;
    p = e;
    if (p > b && p[-1] == '.')
        p--;
    {
        const char *d = p;
        while (d > b && isDIGIT_A(d[-1]))
            d--;
        if (d < p && d - b >= 6 && memEQ(d - 6, " line ", 6)) {
            const char *f = d - 6, *s = f;
            while (s > b && !isSPACE_A(s[-1]))
                s--;
            if (s < f && s - b >= 4 && memEQ(s - 4, " at ", 4))
                e = s - 4;
        }
    }
    out = sv_2mortal(newSVpvn(b, (STRLEN)(e - b)));
    if (SvUTF8(err))
        SvUTF8_on(out);
    return out;
}

/* new: a parser with these options over the invocant's. */
static SV *
tkn_new(pTHX_ SV *klass, SV **args, I32 n)
{
    static const char *const me = "Time::Keeper::Natural->new";
    HV *opt = newHV(), *seen = (HV *)sv_2mortal((SV *)newHV());
    SV *obj = sv_2mortal(newRV_noinc((SV *)opt)), *v;
    I32 i;
    if (n % 2)
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: the options are name and value pairs", me)));
    if (SvROK(klass) && SvTYPE(SvRV(klass)) == SVt_PVHV) {
        HE *he;
        hv_iterinit((HV *)SvRV(klass));
        while ((he = hv_iternext((HV *)SvRV(klass))))
            (void)hv_store_ent(opt, hv_iterkeysv(he), newSVsv(HeVAL(he)), 0);
    }
    for (i = 0; i + 1 < n; i += 2) {
        SV *k = args[i], *val = args[i + 1];
        const char *ks = SvOK(k) ? SvPV_nolen(k) : NULL;
        int x, known = 0;
        for (x = 0; ks && x < 7; x++)
            if (strEQ(ks, tkn_options[x]))
                known = 1;
        if (!known)
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: '%s' is not an option; the options are now, zone, locale, bare_hour, prefer, keep_zone and calendar",
                                                              me, ks ? ks : "")));
        if (hv_exists(seen, ks, (I32)strlen(ks)))
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: %s is given twice", me, ks)));
        (void)hv_store(seen, ks, (I32)strlen(ks), &PL_sv_yes, 0);
        if (SvOK(val))
            (void)hv_store(opt, ks, (I32)strlen(ks), newSVsv(val), 0);
        else
            (void)hv_delete(opt, ks, (I32)strlen(ks), G_DISCARD);
    }
    if ((v = tkn_opt(aTHX_ obj, "now")) && !(sv_isobject(v) && sv_derived_from(v, "Time::Keeper")))
        tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: now is a Time::Keeper value", me)));
    if ((v = tkn_opt(aTHX_ obj, "zone"))) {
        dSP;
        SV *why = NULL;
        ENTER;
        SAVETMPS;
        save_scalar(PL_errgv);
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Time::Keeper")));
        XPUSHs(sv_2mortal(newSVpvs("zone")));
        XPUSHs(v);
        PUTBACK;
        (void)call_method("now", G_SCALAR | G_EVAL | G_DISCARD);
        SPAGAIN;
        if (SvTRUE(ERRSV))
            why = newSVsv(ERRSV);
        PUTBACK;
        FREETMPS;
        LEAVE;
        if (why) {
            STRLEN wl;
            const char *wb;
            SV *w;
            sv_2mortal(why);
            wb = SvPV_const(why, wl);
            if (wl >= 19 && memEQ(wb, "Time::Keeper->now: ", 19)) {
                w = sv_2mortal(newSVpvn(wb + 19, wl - 19));
                if (SvUTF8(why))
                    SvUTF8_on(w);
            }
            else
                w = why;
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: %" SVf, me, SVfARG(tkn_strip_at(aTHX_ w)))));
        }
    }
    if ((v = tkn_opt(aTHX_ obj, "locale"))) {
        SV *code;
        /* a -u-ca- extension names the calendar, unless calendar does: the
           id runs to the next key, a hyphen and two characters ("-nu-"), so
           islamic-umalqura keeps its own hyphen */
        const char *ca = strstr(SvPV_nolen(v), "-u-ca-");
        if (ca && !hv_exists(seen, "calendar", 8)) {
            const char *s2 = ca + 6, *end = s2;
            while (*end && !(end[0] == '-' && end[1] && end[2] && (end[3] == '-' || !end[3])))
                end++;
            if (end > s2)
                (void)hv_stores(opt, "calendar", newSVpvn(s2, (STRLEN)(end - s2)));
        }
        code = tkn_call1(aTHX_ TKN_LOC, "code", &v, 1);
        if (!SvOK(code))
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: there is no locale '%" SVf "'", me, SVfARG(v))));
        (void)hv_stores(opt, "locale", newSVsv(code));
    }
    if ((v = tkn_opt(aTHX_ obj, "calendar")))
        (void)hv_stores(opt, "calendar", newSVsv(tkn_canonical_calendar(aTHX_ me, v)));
    if ((v = tkn_opt(aTHX_ obj, "bare_hour"))) {
        const char *s = SvPV_nolen(v);
        if (!(strEQ(s, "am") || strEQ(s, "pm") || strEQ(s, "next")))
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: bare_hour is 'am', 'pm' or 'next', not '%" SVf "'", me, SVfARG(v))));
    }
    if ((v = tkn_opt(aTHX_ obj, "prefer"))) {
        const char *s = SvPV_nolen(v);
        if (!(strEQ(s, "future") || strEQ(s, "past")))
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("%s: prefer is 'future' or 'past', not '%" SVf "'", me, SVfARG(v))));
    }
    sv_bless(obj, SvROK(klass) ? SvSTASH(SvRV(klass)) : gv_stashsv(klass, GV_ADD));
    return obj;
}

static SV *
tkn_self_of(pTHX_ SV *self)
{
    return SvROK(self) ? self : tkn_new(aTHX_ self, NULL, 0);
}

static SV *tkn_now_plain(pTHX_ SV *self);

/* A value in the parser's calendar, where it has one other than the
 * Gregorian: arithmetic on it counts that calendar's months and years. */
static SV *
tkn_in_cal(pTHX_ SV *self, SV *v)
{
    SV *cal = SvROK(self) ? tkn_opt(aTHX_ self, "calendar") : NULL;
    if (!cal || !v || !SvOK(v) || !sv_isobject(v) || !sv_derived_from(v, "Time::Keeper") || sv_derived_from(v, "Time::Keeper::Duration"))
        return v;
    return tkn_method(aTHX_ v, "in_calendar", &cal, 1);
}

/* now: the anchor, in the parser's calendar. */
static SV *
tkn_now(pTHX_ SV *self)
{
    self = tkn_self_of(aTHX_ self);
    return tkn_in_cal(aTHX_ self, tkn_now_plain(aTHX_ self));
}

static SV *
tkn_now_plain(pTHX_ SV *self)
{
    SV *a, *z, *l;
    z = tkn_opt(aTHX_ self, "zone");
    l = tkn_opt(aTHX_ self, "locale");
    if ((a = tkn_opt(aTHX_ self, "now"))) {
        if (z)
            a = tkn_method(aTHX_ a, "in_zone", &z, 1);
        if (l)
            a = tkn_method(aTHX_ a, "in_locale", &l, 1);
        return a;
    }
    {
        SV *args[4];
        int n = 0;
        if (z) {
            args[n++] = sv_2mortal(newSVpvs("zone"));
            args[n++] = z;
        }
        if (l) {
            args[n++] = sv_2mortal(newSVpvs("locale"));
            args[n++] = l;
        }
        return tkn_class_call(aTHX_ "Time::Keeper", "now", args, n, 0);
    }
}

static SV *
tkn_zone_of(pTHX_ SV *self)
{
    SV *z;
    self = tkn_self_of(aTHX_ self);
    if ((z = tkn_opt(aTHX_ self, "zone")))
        return z;
    return tkn_method(aTHX_ tkn_now(aTHX_ self), "zone_name", NULL, 0);
}

static SV *
tkn_locale_of(pTHX_ SV *self)
{
    SV *l;
    self = tkn_self_of(aTHX_ self);
    if ((l = tkn_opt(aTHX_ self, "locale")))
        return l;
    return tkn_method(aTHX_ tkn_now(aTHX_ self), "locale", NULL, 0);
}

/* The locale's lexicon in a calendar (NULL the Gregorian) and its word table
 * (or undef). */
static void
tkn_lex_words_cal(pTHX_ SV *self, SV *cal, SV **lexsv, SV **words)
{
    SV *loc = tkn_locale_of(aTHX_ self);
    *lexsv = tkn_lexicon_for_cal(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Lexicon")), loc, cal);
    *words = tkn_words_for(aTHX_ sv_2mortal(newSVpvs("Time::Keeper::Natural::Words")), tkn_lex(aTHX_ *lexsv)->code);
}

/* _lex_words: the lexicon of the parser's locale and calendar. */
static void
tkn_lex_words(pTHX_ SV *self, SV **lexsv, SV **words)
{
    tkn_lex_words_cal(aTHX_ self, SvROK(self) ? tkn_opt(aTHX_ self, "calendar") : NULL, lexsv, words);
}

/* _invocant: the parser a method was called on, or one made from the
 * options after the text when it was called on the class. */
static SV *
tkn_invocant(pTHX_ const char *method, SV *self, SV **opts, I32 n)
{
    if (SvROK(self)) {
        if (n > 0)
            tkn_carp(aTHX_ "Carp::croak", sv_2mortal(newSVpvf("Time::Keeper::Natural->%s: options go to new, not to %s", method, method)));
        return self;
    }
    return tkn_new(aTHX_ self, opts, n);
}

#endif
