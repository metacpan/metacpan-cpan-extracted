# Time::Keeper::Locale: what CLDR says of each locale.

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Locale

void
codes(class)
        SV *class
    PREINIT:
        unsigned i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        EXTEND(SP, TK_LOCALE_COUNT);
        for (i = 0; i < TK_LOCALE_COUNT; i++)
            mPUSHs(newSVpv(tk_locale_codes[i].code, 0));

SV *
cldr_version(class)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = newSVpvs(TK_CLDR_VERSION);
    OUTPUT:
        RETVAL

SV *
code(class, locale)
        SV *class
        SV *locale
    ALIAS:
        name = 1
        native_name = 2
    PREINIT:
        int id = -1;
        const char *s;
    CODE:
        PERL_UNUSED_VAR(class);
        if (ix == 0) {
            STRLEN len;
            const char *p;
            if (!SvOK(locale))
                XSRETURN_UNDEF;
            p = SvPV(locale, len);
            id = tk_locale_find(p, len);
            if (id < 0)
                XSRETURN_UNDEF;
        }
        else
            id = tk_locale_id_from_sv(aTHX_ locale, ix == 1 ? "Time::Keeper::Locale->name" : "Time::Keeper::Locale->native_name");
        s = ix == 0 ? tk_locale_codes[id].code : ix == 1 ? tk_locale_codes[id].name : tk_locale_codes[id].native;
        RETVAL = newSVpv(s, 0);
        if (!tk_is_ascii(s))
            SvUTF8_on(RETVAL);
    OUTPUT:
        RETVAL

IV
first_day_of_week(class, locale)
        SV *class
        SV *locale
    ALIAS:
        min_days_in_first_week = 1
        prefers_24_hour_time = 2
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper::Locale->first_day_of_week", "Time::Keeper::Locale->min_days_in_first_week",
            "Time::Keeper::Locale->prefers_24_hour_time"
        };
        const tk_locale_data *d;
    CODE:
        PERL_UNUSED_VAR(class);
        d = tk_locale_get(aTHX_ tk_locale_id_from_sv(aTHX_ locale, whats[ix]));
        RETVAL = ix == 0 ? d->first_day : ix == 1 ? d->min_days : d->hour_cycle_24;
    OUTPUT:
        RETVAL

void
names(class, locale, what, ...)
        SV *class
        SV *locale
        const char *what
    PREINIT:
        const char *w = "wide", *ctx = "format";
        const char *me = "Time::Keeper::Locale->names";
        const tk_locale_data *d;
        int wi, ci, k, n = 0;
        const char *list[TK_DP_COUNT > 12 ? TK_DP_COUNT : 12];
    PPCODE:
        PERL_UNUSED_VAR(class);
        d = tk_locale_get(aTHX_ tk_locale_id_from_sv(aTHX_ locale, me));
        if (items > 3) w = SvPV_nolen(ST(3));
        if (items > 4) ctx = SvPV_nolen(ST(4));
        if (items > 5)
            croak("%s: the arguments are the locale, what, a width and a context", me);
        wi = strEQ(w, "wide") ? TK_W_WIDE : strEQ(w, "abbreviated") ? TK_W_ABBR
           : strEQ(w, "narrow") ? TK_W_NARROW : strEQ(w, "short") ? TK_W_SHORT : -1;
        ci = strEQ(ctx, "format") ? TK_CTX_FORMAT : strEQ(ctx, "stand-alone") ? TK_CTX_STANDALONE : -1;
        if (wi < 0 || (wi == TK_W_SHORT && strNE(what, "days")))
            croak("%s: the width is 'wide', 'abbreviated' or 'narrow' ('short' too for days), not '%s'", me, w);
        if (ci < 0)
            croak("%s: the context is 'format' or 'stand-alone', not '%s'", me, ctx);
        if (strEQ(what, "months"))
            for (k = 0; k < 12; k++) list[n++] = d->s.months[ci][wi][k];
        else if (strEQ(what, "days"))
            for (k = 0; k < 7; k++) list[n++] = d->s.days[ci][wi][k];
        else if (strEQ(what, "quarters"))
            for (k = 0; k < 4; k++) list[n++] = d->s.quarters[ci][wi][k];
        else if (strEQ(what, "eras"))
            for (k = 0; k < 2; k++) list[n++] = d->s.eras[wi][k];
        else if (strEQ(what, "am_pm"))
            for (k = 0; k < 2; k++) list[n++] = d->s.periods[wi][k];
        else
            croak("%s: what is 'months', 'days', 'quarters', 'eras' or 'am_pm', not '%s'", me, what);
        EXTEND(SP, n);
        for (k = 0; k < n; k++) {
            SV *sv = newSVpv(list[k], 0);
            if (!tk_is_ascii(list[k]))
                SvUTF8_on(sv);
            mPUSHs(sv);
        }

void
formats(class, locale, kind)
        SV *class
        SV *locale
        const char *kind
    PREINIT:
        const char *me = "Time::Keeper::Locale->formats";
        const tk_locale_data *d;
        const char *const *f;
        int k;
    PPCODE:
        PERL_UNUSED_VAR(class);
        d = tk_locale_get(aTHX_ tk_locale_id_from_sv(aTHX_ locale, me));
        if (strEQ(kind, "date")) f = d->s.date_formats;
        else if (strEQ(kind, "time")) f = d->s.time_formats;
        else if (strEQ(kind, "datetime")) f = d->s.datetime_formats;
        else croak("%s: the kind is 'date', 'time' or 'datetime', not '%s'", me, kind);
        EXTEND(SP, TK_LEN_COUNT);
        for (k = 0; k < TK_LEN_COUNT; k++) {
            SV *sv = newSVpv(f[k], 0);
            if (!tk_is_ascii(f[k]))
                SvUTF8_on(sv);
            mPUSHs(sv);
        }

SV *
available_formats(class, locale)
        SV *class
        SV *locale
    PREINIT:
        const tk_locale_data *d;
        HV *hv;
        unsigned k;
    CODE:
        PERL_UNUSED_VAR(class);
        d = tk_locale_get(aTHX_ tk_locale_id_from_sv(aTHX_ locale, "Time::Keeper::Locale->available_formats"));
        hv = newHV();
        for (k = 0; k < d->n_skeletons; k++) {
            SV *sv = newSVpv(d->skeletons[k].value, 0);
            if (!tk_is_ascii(d->skeletons[k].value))
                SvUTF8_on(sv);
            (void)hv_store(hv, d->skeletons[k].key, (I32)strlen(d->skeletons[k].key), sv, 0);
        }
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

void
digits(class, locale)
        SV *class
        SV *locale
    PREINIT:
        const tk_locale_data *d;
        int k;
    PPCODE:
        PERL_UNUSED_VAR(class);
        d = tk_locale_get(aTHX_ tk_locale_id_from_sv(aTHX_ locale, "Time::Keeper::Locale->digits"));
        EXTEND(SP, 10);
        for (k = 0; k < 10; k++) {
            SV *sv = newSVpv(d->s.digits[k], 0);
            if (!tk_is_ascii(d->s.digits[k]))
                SvUTF8_on(sv);
            mPUSHs(sv);
        }

SV *
parts(class, locale)
        SV *class
        SV *locale
    PREINIT:
        static const char *const keys[12] = {
            "language", "script", "territory", "variant",
            "language_name", "script_name", "territory_name", "variant_name",
            "native_language_name", "native_script_name", "native_territory_name", "native_variant_name"
        };
        const tk_locale_code *lc;
        HV *hv;
        int k;
    CODE:
        PERL_UNUSED_VAR(class);
        lc = &tk_locale_codes[tk_locale_id_from_sv(aTHX_ locale, "Time::Keeper::Locale->parts")];
        hv = newHV();
        for (k = 0; k < 12; k++) {
            SV *sv;
            if (lc->parts[k]) {
                sv = newSVpv(lc->parts[k], 0);
                if (!tk_is_ascii(lc->parts[k]))
                    SvUTF8_on(sv);
            }
            else
                sv = newSV(0);
            (void)hv_store(hv, keys[k], (I32)strlen(keys[k]), sv, 0);
        }
        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL
