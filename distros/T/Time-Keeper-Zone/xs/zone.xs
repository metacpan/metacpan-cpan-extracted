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
