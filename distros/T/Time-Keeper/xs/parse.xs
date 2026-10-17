# Parsing: any of the standard forms, strptime, CLDR patterns, intervals and
# durations.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

SV *
parse(class, text, ...)
        SV *class
        SV *text
    ALIAS:
        strptime = 1
        parse_cldr = 2
    PREINIT:
        static const char *const whats[] = {
            "Time::Keeper->parse", "Time::Keeper->strptime", "Time::Keeper->parse_cldr"
        };
        const char *what = whats[ix];
        tk_cursor c;
        tk_fields f;
        tk_args a;
        tk_value v;
        SV *t, *scan, *pat = NULL;
        STRLEN len, plen = 0;
        const char *s, *p = NULL;
        int first = ix ? 3 : 2, gap, overlap, ok;
        uint16_t lid;
    CODE:
        if (ix) {
            if (items < 3)
                croak("%s: a pattern was wanted after the text", what);
            pat = tk_utf8_text(aTHX_ ST(2));
            p = SvPV(pat, plen);
        }
        tk_args_parse(aTHX_ &ST(first), items - first, TK_A_RESOLVE | TK_A(TK_A_LOCALE), &a, what);
        lid = tk_args_locale(&a, what);
        gap = a.v[TK_A_GAP] ? tk_opt_gap(aTHX_ a.v[TK_A_GAP], what) : TK_GAP_DEFAULT;
        overlap = a.v[TK_A_OVERLAP] ? tk_opt_overlap(aTHX_ a.v[TK_A_OVERLAP], what) : TK_OVERLAP_DEFAULT;
        if (!SvOK(text))
            croak("%s: no text", what);
        t = tk_utf8_text(aTHX_ text);
        scan = ix ? tk_ascii_digits(aTHX_ t) : t;
        s = SvPV(scan, len);
        tk_cursor_init(&c, s, len);
        Zero(&f, 1, tk_fields);
        if (ix == 0)
            ok = tk_parse_any(&c, &f);
        else if (ix == 1)
            ok = tk_strptime(&c, &f, tk_locale_get(aTHX_ lid), p, plen);
        else
            ok = tk_parse_cldr(&c, &f, tk_locale_get(aTHX_ lid), p, plen) && (tk_at_end(&c) || tk_fail(&c, "text was left over"));
        if (!ok)
            tk_parse_croak(aTHX_ what, t, scan, &c);
        tk_fields_to_value(aTHX_ &v, &f, a.v[TK_A_ZONE], gap, overlap, what, SvPV_nolen(t));
        v.locale = lid;
        RETVAL = tk_value_new_sv(aTHX_ tk_stash_for(aTHX_ class), &v);
    OUTPUT:
        RETVAL

SV *
try_parse(class, ...)
        SV *class
    ALIAS:
        try_strptime = 1
        try_parse_cldr = 2
    PREINIT:
        static const char *const methods[] = { "parse", "strptime", "parse_cldr" };
        int count;
        I32 i;
    CODE:
        PERL_UNUSED_VAR(class);
        {
            dSP;
            ENTER;
            SAVETMPS;
            save_scalar(PL_errgv);
            PUSHMARK(SP);
            for (i = 0; i < items; i++)
                XPUSHs(ST(i));
            PUTBACK;
            count = call_method(methods[ix], G_SCALAR | G_EVAL);
            SPAGAIN;
            if (count == 1 && !SvTRUE(ERRSV))
                RETVAL = newSVsv(POPs);
            else {
                if (count) (void)POPs;
                RETVAL = &PL_sv_undef;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
    OUTPUT:
        RETVAL

void
parse_interval(class, text, ...)
        SV *class
        SV *text
    PREINIT:
        const char *what = "Time::Keeper->parse_interval";
        SV *t;
        STRLEN len, slash;
        const char *s;
        tk_args a;
        int gap, overlap, k;
        tk_value ends[2];
        int is_dur[2];
        tk_duration durs[2];
        HV *stash;
    PPCODE:
        tk_args_parse(aTHX_ &ST(2), items - 2, TK_A_RESOLVE | TK_A(TK_A_LOCALE), &a, what);
        gap = a.v[TK_A_GAP] ? tk_opt_gap(aTHX_ a.v[TK_A_GAP], what) : TK_GAP_DEFAULT;
        overlap = a.v[TK_A_OVERLAP] ? tk_opt_overlap(aTHX_ a.v[TK_A_OVERLAP], what) : TK_OVERLAP_DEFAULT;
        t = tk_utf8_text(aTHX_ text);
        s = SvPV(t, len);
        for (slash = 0; slash < len && s[slash] != '/'; slash++)
            ;
        if (slash >= len)
            croak("%s: an interval is two parts with a / between", what);
        for (k = 0; k < 2; k++) {
            tk_cursor c;
            const char *part = k ? s + slash + 1 : s;
            STRLEN plen = k ? len - slash - 1 : slash;
            tk_cursor_init(&c, part, plen);
            is_dur[k] = plen && (part[0] == 'P' || part[0] == 'p' || ((part[0] == '-' || part[0] == '+') && plen > 1 && (part[1] == 'P' || part[1] == 'p')));
            if (is_dur[k]) {
                if (!tk_parse_duration_text(&c, &durs[k]) || !tk_at_end(&c)) {
                    c.err_at += k ? slash + 1 : 0;
                    tk_parse_croak(aTHX_ what, t, t, &c);
                }
            }
            else {
                tk_fields f;
                Zero(&f, 1, tk_fields);
                if (!tk_parse_any(&c, &f)) {
                    c.err_at += k ? slash + 1 : 0;
                    tk_parse_croak(aTHX_ what, t, t, &c);
                }
                tk_fields_to_value(aTHX_ &ends[k], &f, a.v[TK_A_ZONE], gap, overlap, what, SvPV_nolen(t));
            }
        }
        if (is_dur[0] && is_dur[1])
            croak("%s: '%" SVf "' is two durations and no time", what, SVfARG(t));
        if (is_dur[1])
            tk_value_plus(aTHX_ &ends[1], &ends[0], &durs[1], gap, overlap, what);
        else if (is_dur[0]) {
            tk_dur_negate(&durs[0], 0);
            tk_value_plus(aTHX_ &ends[0], &ends[1], &durs[0], gap, overlap, what);
        }
        ends[0].locale = ends[1].locale = tk_args_locale(&a, what);
        stash = tk_stash_for(aTHX_ class);
        EXTEND(SP, 2);
        mPUSHs(tk_value_new_sv(aTHX_ stash, &ends[0]));
        mPUSHs(tk_value_new_sv(aTHX_ stash, &ends[1]));

MODULE = Time::Keeper    PACKAGE = Time::Keeper::Duration

SV *
parse(class, text)
        SV *class
        SV *text
    PREINIT:
        tk_cursor c;
        tk_duration d;
        STRLEN len;
        const char *s;
        SV *t;
    CODE:
        t = tk_utf8_text(aTHX_ text);
        s = SvPV(t, len);
        tk_cursor_init(&c, s, len);
        if (!tk_parse_duration_text(&c, &d) || (!tk_at_end(&c) && tk_fail(&c, "text was left over") == 0))
            tk_parse_croak(aTHX_ "Time::Keeper::Duration->parse", t, t, &c);
        RETVAL = tk_dur_new_sv(aTHX_ tk_dur_stash_for(aTHX_ class), &d);
    OUTPUT:
        RETVAL
