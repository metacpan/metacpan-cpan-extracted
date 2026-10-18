# The public surface: class methods, since a zone is a name and not an
# object. Each takes the class as its first argument and ignores it.

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

SV *
tzdata_version(...)
    CODE:
        RETVAL = newSVpvs(TKZ_TZDATA_VERSION);
    OUTPUT:
        RETVAL

void
names(...)
    PREINIT:
        int i;
    PPCODE:
        EXTEND(SP, TKZ_ZONE_COUNT);
        for (i = 0; i < TKZ_ZONE_COUNT; i++)
            mPUSHp(tkz_names + tkz_zones[i].name, strlen(tkz_names + tkz_zones[i].name));

void
links(...)
    PREINIT:
        int i;
    PPCODE:
        EXTEND(SP, TKZ_LINK_COUNT * 2);
        for (i = 0; i < TKZ_LOOKUP_COUNT; i++) {
            const char *n, *c;
            if (!tkz_lookup[i].is_link)
                continue;
            n = tkz_id_name(i);
            c = tkz_id_canonical(i);
            mPUSHp(n, strlen(n));
            mPUSHp(c, strlen(c));
        }

bool
is_valid(class, name)
        SV *class
        SV *name
    PREINIT:
        STRLEN len;
        const char *p;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(name))
            XSRETURN_NO;
        p = SvPV(name, len);
        RETVAL = tkz_lookup_name(p, len) >= 0;
    OUTPUT:
        RETVAL

SV *
name(class, name)
        SV *class
        SV *name
    ALIAS:
        canonical_name = 1
    PREINIT:
        STRLEN len;
        const char *p;
        int id;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(name))
            XSRETURN_UNDEF;
        p = SvPV(name, len);
        id = tkz_lookup_name(p, len);
        if (id < 0)
            XSRETURN_UNDEF;
        p = ix ? tkz_id_canonical(id) : tkz_id_name(id);
        RETVAL = newSVpv(p, 0);
    OUTPUT:
        RETVAL

SV *
local_name(...)
    PREINIT:
        SV **tz;
        STRLEN len = 0;
        const char *p = NULL;
    CODE:
        tz = hv_fetchs(GvHVn(PL_envgv), "TZ", 0);
        if (tz && SvOK(*tz))
            p = SvPV(*tz, len);
        RETVAL = newSVpv(tkz_id_name(tkz_local_zone(p, len)), 0);
    OUTPUT:
        RETVAL

void
countries(...)
    PREINIT:
        int i;
    PPCODE:
        EXTEND(SP, TKZ_COUNTRY_COUNT * 2);
        for (i = 0; i < TKZ_COUNTRY_COUNT; i++) {
            mPUSHp(tkz_countries[i].code, 2);
            mPUSHp(tkz_country_names + tkz_countries[i].name,
                   strlen(tkz_country_names + tkz_countries[i].name));
        }

void
zones_for_country(class, code)
        SV *class
        SV *code
    PREINIT:
        STRLEN len;
        const char *p;
        char cc[3];
        int lo = 0, hi = TKZ_COUNTRY_COUNT - 1, i;
    PPCODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(code))
            XSRETURN_EMPTY;
        p = SvPV(code, len);
        if (len != 2)
            XSRETURN_EMPTY;
        cc[0] = toUPPER(p[0]);
        cc[1] = toUPPER(p[1]);
        cc[2] = '\0';
        while (lo <= hi) {
            int mid = lo + (hi - lo) / 2;
            int c = strcmp(tkz_countries[mid].code, cc);
            if (c == 0) {
                const tkz_country *k = &tkz_countries[mid];
                EXTEND(SP, k->n);
                for (i = 0; i < k->n; i++) {
                    const char *n = tkz_id_name(tkz_country_zones[k->first + i]);
                    mPUSHp(n, strlen(n));
                }
                break;
            }
            if (c < 0) lo = mid + 1; else hi = mid - 1;
        }

SV *
windows_zone(class, name)
        SV *class
        SV *name
    PREINIT:
        int id;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(name))
            XSRETURN_UNDEF;
        id = tkz_windows_lookup(SvPV_nolen(name));
        if (id < 0)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(tkz_id_name(id), 0);
    OUTPUT:
        RETVAL

# Each change from `from` to `to`, both included, as
# [epoch, offset before, offset after, abbreviation after, is DST after].
void
transitions(class, name, from, to)
        SV *class
        SV *name
        SV *from
        SV *to
    PREINIT:
        int id;
        int64_t t, t0, t1;
    PPCODE:
        PERL_UNUSED_VAR(class);
        id = tkz_sv_zone(aTHX_ name);
        t0 = tkz_sv_epoch(aTHX_ from);
        t1 = tkz_sv_epoch(aTHX_ to);
        if (t1 < t0)
            croak("Time::Keeper::Zone: transitions: the end is before the start");
        if (t1 - t0 > INT64_C(31557600000))
            croak("Time::Keeper::Zone: transitions: the span is over 1,000 years");
        t = t0 - 1;
        while ((t = tkz_next_change(id, t)) != TKZ_NO_CHANGE && t <= t1) {
            int32_t before, after;
            int isdst;
            const char *abbr;
            AV *row = newAV();
            tkz_offset_at(id, t - 1, &before, NULL, NULL);
            tkz_offset_at(id, t, &after, &isdst, &abbr);
            av_extend(row, 4);
            av_push(row, tkz_newSVi64(aTHX_ t));
            av_push(row, newSViv(before));
            av_push(row, newSViv(after));
            av_push(row, newSVpv(abbr, 0));
            av_push(row, newSViv(isdst));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)row)));
        }

SV *
next_transition(class, name, epoch)
        SV *class
        SV *name
        SV *epoch
    ALIAS:
        previous_transition = 1
    PREINIT:
        int id;
        int64_t t;
    CODE:
        PERL_UNUSED_VAR(class);
        id = tkz_sv_zone(aTHX_ name);
        t = tkz_sv_epoch(aTHX_ epoch);
        t = ix ? tkz_prev_change(id, t) : tkz_next_change(id, t);
        if (t == TKZ_NO_CHANGE)
            XSRETURN_UNDEF;
        RETVAL = tkz_newSVi64(aTHX_ t);
    OUTPUT:
        RETVAL

void
offset_at(class, name, epoch)
        SV *class
        SV *name
        SV *epoch
    PREINIT:
        int id, isdst;
        int32_t utoff;
        const char *abbr;
    PPCODE:
        PERL_UNUSED_VAR(class);
        id = tkz_sv_zone(aTHX_ name);
        tkz_offset_at(id, tkz_sv_epoch(aTHX_ epoch), &utoff, &isdst, &abbr);
        if (GIMME_V != G_LIST) {
            mXPUSHi(utoff);
            XSRETURN(1);
        }
        EXTEND(SP, 3);
        mPUSHi(utoff);
        mPUSHi(isdst);
        mPUSHp(abbr, strlen(abbr));

IV
standard_offset_at(class, name, epoch)
        SV *class
        SV *name
        SV *epoch
    PREINIT:
        int32_t utoff;
    CODE:
        PERL_UNUSED_VAR(class);
        tkz_standard_offset_at(tkz_sv_zone(aTHX_ name), tkz_sv_epoch(aTHX_ epoch), &utoff);
        RETVAL = utoff;
    OUTPUT:
        RETVAL

# Whether the DST flag changes in the year, the year as the zone's own
# wall clock counts it.
bool
has_dst(class, name, year)
        SV *class
        SV *name
        IV year
    PREINIT:
        int id, was;
        int64_t u[2], t, end;
        int32_t o[2];
    CODE:
        PERL_UNUSED_VAR(class);
        id = tkz_sv_zone(aTHX_ name);
        if (year < -999999999 || year > 999999999)
            croak("Time::Keeper::Zone: has_dst: year %" IVdf " is out of range", year);
        tkz_resolve_local_all(id, tkz_days_from_civil(year, 1, 1) * 86400, u, o);
        t = u[0];
        tkz_resolve_local_all(id, tkz_days_from_civil(year + 1, 1, 1) * 86400, u, o);
        end = u[0];
        tkz_offset_at(id, t, NULL, &was, NULL);
        RETVAL = 0;
        while ((t = tkz_next_change(id, t)) != TKZ_NO_CHANGE && t < end) {
            int isdst;
            tkz_offset_at(id, t, NULL, &isdst, NULL);
            if (isdst != was) {
                RETVAL = 1;
                break;
            }
        }
    OUTPUT:
        RETVAL

SV *
country_of(class, name)
        SV *class
        SV *name
    ALIAS:
        windows_name = 1
    PREINIT:
        STRLEN len;
        const char *p;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(name))
            XSRETURN_UNDEF;
        p = SvPV(name, len);
        p = ix ? tkz_windows_name(tkz_lookup_name(p, len)) : tkz_country_of(tkz_lookup_name(p, len));
        if (!p)
            XSRETURN_UNDEF;
        RETVAL = newSVpv(p, 0);
    OUTPUT:
        RETVAL
