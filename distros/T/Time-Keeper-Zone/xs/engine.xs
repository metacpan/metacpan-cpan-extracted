# Doors onto the engine, for the tests only.

MODULE = Time::Keeper::Zone    PACKAGE = Time::Keeper::Zone

# (utoff, isdst, abbreviation) at a UTC instant.
void
_offset_at(name, t)
        const char *name
        SV *t
    PREINIT:
        int id;
        int32_t utoff;
        int isdst;
        const char *abbr;
    PPCODE:
        id = tkz_lookup_name(name, strlen(name));
        if (!tkz_offset_at(id, tkz_sv_i64(aTHX_ t), &utoff, &isdst, &abbr))
            croak("no such zone");
        EXTEND(SP, 3);
        mPUSHi(utoff);
        mPUSHi(isdst);
        mPUSHp(abbr, strlen(abbr));

SV *
_next_change(name, t)
        const char *name
        SV *t
    PREINIT:
        int id;
        int64_t n;
    CODE:
        id = tkz_lookup_name(name, strlen(name));
        if (id < 0)
            croak("no such zone");
        n = tkz_next_change(id, tkz_sv_i64(aTHX_ t));
        if (n == TKZ_NO_CHANGE)
            XSRETURN_UNDEF;
        RETVAL = tkz_newSVi64(aTHX_ n);
    OUTPUT:
        RETVAL

# Every real change from t0 up to and including t1, each as
# [at, utoff, isdst, abbreviation].
void
_changes(name, t0, t1)
        const char *name
        SV *t0
        SV *t1
    PREINIT:
        int id;
        int64_t t, end;
    PPCODE:
        id = tkz_lookup_name(name, strlen(name));
        if (id < 0)
            croak("no such zone");
        t = tkz_sv_i64(aTHX_ t0);
        end = tkz_sv_i64(aTHX_ t1);
        while ((t = tkz_next_change(id, t)) != TKZ_NO_CHANGE && t <= end) {
            int32_t utoff;
            int isdst;
            const char *abbr;
            AV *row = newAV();
            tkz_offset_at(id, t, &utoff, &isdst, &abbr);
            av_push(row, tkz_newSVi64(aTHX_ t));
            av_push(row, newSViv(utoff));
            av_push(row, newSViv(isdst));
            av_push(row, newSVpv(abbr, 0));
            XPUSHs(sv_2mortal(newRV_noinc((SV *)row)));
        }

# (result, utc or undef). gap: 0 croak, 1 forward, 2 backward; overlap: 0
# later, 1 earlier.
void
_resolve_local(name, local, gap, overlap)
        const char *name
        SV *local
        int gap
        int overlap
    PREINIT:
        int id, r;
        int64_t utc = 0;
    PPCODE:
        id = tkz_lookup_name(name, strlen(name));
        if (id < 0)
            croak("no such zone");
        r = tkz_resolve_local(id, tkz_sv_i64(aTHX_ local), gap, overlap, &utc);
        EXTEND(SP, 2);
        mPUSHi(r);
        if (r == TKZ_LOCAL_GAP && gap == TKZ_GAP_CROAK)
            PUSHs(&PL_sv_undef);
        else
            mPUSHs(tkz_newSVi64(aTHX_ utc));

# The local zone's name from a TZ value (undef for unset) and files of the
# test's own; undef for any file skips it.
SV *
_local_zone_from(tz, link, tzfile, clock)
        SV *tz
        SV *link
        SV *tzfile
        SV *clock
    PREINIT:
        STRLEN len = 0;
        const char *p = NULL;
    CODE:
        if (SvOK(tz))
            p = SvPV(tz, len);
        RETVAL = newSVpv(tkz_id_name(tkz_local_zone_from(p, len,
                     SvOK(link) ? SvPV_nolen(link) : NULL,
                     SvOK(tzfile) ? SvPV_nolen(tzfile) : NULL,
                     SvOK(clock) ? SvPV_nolen(clock) : NULL)), 0);
    OUTPUT:
        RETVAL

# The ABI table, called through its pointers, for t/04-abi.t.
void
_abi_call(what, ...)
        const char *what
    PREINIT:
        const tkz_abi *a = &TKZ_ABI;
    PPCODE:
        if (strEQ(what, "lookup")) {
            STRLEN len;
            const char *p = SvPV(ST(1), len);
            mXPUSHi((a->lookup)(p, len));
        }
        else if (strEQ(what, "name")) {
            const char *n = (a->name)((int)SvIV(ST(1)));
            XPUSHs(n ? sv_2mortal(newSVpv(n, 0)) : &PL_sv_undef);
        }
        else if (strEQ(what, "canonical_name")) {
            const char *n = (a->canonical_name)((int)SvIV(ST(1)));
            XPUSHs(n ? sv_2mortal(newSVpv(n, 0)) : &PL_sv_undef);
        }
        else if (strEQ(what, "is_link"))
            mXPUSHi((a->is_link)((int)SvIV(ST(1))));
        else if (strEQ(what, "offset_at")) {
            int32_t u; int d; const char *ab;
            int ok = (a->offset_at)((int)SvIV(ST(1)), tkz_sv_i64(aTHX_ ST(2)), &u, &d, &ab);
            mXPUSHi(ok);
            if (ok) { mXPUSHi(u); mXPUSHi(d); mXPUSHs(newSVpv(ab, 0)); }
        }
        else if (strEQ(what, "next_change")) {
            int64_t n = (a->next_change)((int)SvIV(ST(1)), tkz_sv_i64(aTHX_ ST(2)));
            XPUSHs(n == TKZ_NO_CHANGE ? &PL_sv_undef : sv_2mortal(tkz_newSVi64(aTHX_ n)));
        }
        else if (strEQ(what, "resolve_local")) {
            int64_t u = 0;
            int r = (a->resolve_local)((int)SvIV(ST(1)), tkz_sv_i64(aTHX_ ST(2)),
                                       (int)SvIV(ST(3)), (int)SvIV(ST(4)), &u);
            mXPUSHi(r);
            mXPUSHs(tkz_newSVi64(aTHX_ u));
        }
        else if (strEQ(what, "local_zone")) {
            STRLEN len = 0;
            const char *p = SvOK(ST(1)) ? SvPV(ST(1), len) : NULL;
            mXPUSHi((a->local_zone)(p, len));
        }
        else if (strEQ(what, "tzdata_version"))
            mXPUSHs(newSVpv((a->tzdata_version)(), 0));
        else if (strEQ(what, "zone_count"))
            mXPUSHi((a->zone_count)());
        else
            croak("no ABI entry %s", what);
