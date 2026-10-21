# The C ABI's Perl-visible ends: the table's address, its version, and the
# self-test that calls every entry as a consumer would.

MODULE = Time::Keeper    PACKAGE = Time::Keeper

# Unsigned, not IV: a 32-bit perl may map the table above 0x7fffffff.
UV
_abi_ptr()
    CODE:
        RETVAL = PTR2UV(&TK_ABI);
    OUTPUT:
        RETVAL

IV
_abi_version()
    CODE:
        RETVAL = TK_ABI.abi_version;
    OUTPUT:
        RETVAL

void
_abi_selftest(ptr)
        UV ptr
    PREINIT:
        SV *made = NULL;
        int step;
    PPCODE:
        step = tk_abi_selftest(aTHX_ INT2PTR(const time_keeper_abi *, ptr), &made);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(step)));
        PUSHs(made ? sv_2mortal(made) : &PL_sv_undef);

# The ABI's guard: runs a C function the table hands it under the eval its
# caller set up, so the core's croaking code states a result or a reason
# and the table returns it. Private: nothing but the table calls it.
void
_abi_guard(ptr)
        UV ptr
    CODE:
        {
            tka_guarded *g = INT2PTR(tka_guarded *, ptr);
            g->fn(aTHX_ g->arg);
        }

# A door for the tests: one version 3 entry, called through the table as a
# consumer calls it. Returns the entry's code, its result as a Perl value
# (or undef) and its reason (or undef): for next_change, the offsets
# either side of the change.
void
_abi_v3(op, ...)
        const char *op
    PREINIT:
        const time_keeper_abi *t = &TK_ABI;
        time_keeper_point in, out;
        char err[256];
        int code = TIME_KEEPER_BAD, have_out = 0, i;
        SV *made = NULL;
        int64_t iv[12];
    PPCODE:
        err[0] = '\0';
        if (strEQ(op, "parse_cldr")) {
            STRLEN tl, pl;
            const char *tx = SvPVutf8(ST(1), tl), *pt = SvPVutf8(ST(2), pl);
            int kind = (int)SvIV(ST(3)), lid, cal;
            time_keeper_zone z, *zp = NULL;
            time_keeper_civil clock;
            if (items > 4 && SvOK(ST(4))) {
                STRLEN zl;
                const char *zn = SvPV(ST(4), zl);
                if ((t->zone_parse)(aTHX_ zn, zl, &z) == TIME_KEEPER_OK)
                    zp = &z;
            }
            {
                STRLEN ll;
                const char *ln = SvPV(ST(5), ll);
                lid = (t->locale_find)(ln, ll);
            }
            {
                STRLEN cl;
                const char *cn = SvPV(ST(6), cl);
                cal = (t->calendar_find)(cn, cl);
            }
            code = (t->parse_cldr)(aTHX_ tx, tl, pt, pl, kind, zp, lid, cal, (int)SvIV(ST(7)), (int)SvIV(ST(8)),
                                    &out, &clock, err, sizeof err);
            if (code == TIME_KEEPER_OK) {
                if (kind == TIME_KEEPER_KIND_VALUE)
                    made = (t->new_sv_cal)(aTHX_ &out.inst, &out.zone, out.locale, out.calendar);
                else
                    made = newSVpvf("%04" IVdf "-%02d-%02d %02d:%02d:%02d.%09d", (IV)clock.year, clock.month,
                                    clock.day, clock.hour, clock.minute, clock.second, (int)clock.nanosecond);
            }
        }
        else if (strEQ(op, "duration")) {
            time_keeper_parts p;
            p.years = tk_arg_i64(aTHX_ ST(1), "years"); p.months = tk_arg_i64(aTHX_ ST(2), "months");
            p.weeks = tk_arg_i64(aTHX_ ST(3), "weeks"); p.days = tk_arg_i64(aTHX_ ST(4), "days");
            p.hours = tk_arg_i64(aTHX_ ST(5), "hours"); p.minutes = tk_arg_i64(aTHX_ ST(6), "minutes");
            p.seconds = tk_arg_i64(aTHX_ ST(7), "seconds"); p.nanoseconds = tk_arg_i64(aTHX_ ST(8), "nanoseconds");
            p.end_of_month = (int)SvIV(ST(9));
            made = (t->new_duration_sv)(aTHX_ &p);
            code = made ? TIME_KEEPER_OK : TIME_KEEPER_RANGE;
        }
        else if (strEQ(op, "duration_from_sv")) {
            time_keeper_parts p;
            code = (t->duration_from_sv)(aTHX_ ST(1), &p);
            if (code == TIME_KEEPER_OK)
                made = newSVpvf("%" SVf " %" SVf " %" SVf " %" SVf " %" SVf " %d",
                                SVfARG(sv_2mortal(tk_newSVi64(aTHX_ p.months))), SVfARG(sv_2mortal(tk_newSVi64(aTHX_ p.days))),
                                SVfARG(sv_2mortal(tk_newSVi64(aTHX_ p.minutes))), SVfARG(sv_2mortal(tk_newSVi64(aTHX_ p.seconds))),
                                SVfARG(sv_2mortal(tk_newSVi64(aTHX_ p.nanoseconds))), p.end_of_month);
        }
        else if (strEQ(op, "locale_code")) {
            const char *c = NULL;
            code = (t->locale_code)((int)SvIV(ST(1)), &c);
            if (code == TIME_KEEPER_OK)
                made = newSVpv(c, 0);
        }
        else if (strEQ(op, "date_from_sv")) {
            int kind = -1, lid = -1;
            int64_t days = 0;
            code = (t->date_from_sv)(aTHX_ ST(1), &kind, &days, &lid);
            if (code == TIME_KEEPER_OK) {
                const char *lc = "?";
                (t->locale_code)(lid, &lc);
                made = newSVpvf("%d %" SVf " %s", kind, SVfARG(sv_2mortal(tk_newSVi64(aTHX_ days))), lc);
            }
        }
        else if (strEQ(op, "new_date_sv")) {
            HV *st = items > 4 && SvOK(ST(4)) ? gv_stashsv(ST(4), GV_ADD) : NULL;
            STRLEN ll;
            const char *ln = SvPV(ST(3), ll);
            made = (t->new_date_sv)(aTHX_ (int)SvIV(ST(1)), tk_arg_i64(aTHX_ ST(2), "days"), (t->locale_find)(ln, ll), st);
            code = made ? TIME_KEEPER_OK : TIME_KEEPER_BAD;
        }
        else if (strEQ(op, "locale_weekend")) {
            int s = 0, e = 0;
            STRLEN ll;
            const char *ln = SvPV(ST(1), ll);
            code = (t->locale_weekend)(aTHX_ (t->locale_find)(ln, ll), &s, &e, err, sizeof err);
            if (code == TIME_KEEPER_OK)
                made = newSVpvf("%d %d", s, e);
        }
        else if (strEQ(op, "next_change")) {
            time_keeper_instant at;
            int32_t before = 0, after = 0;
            if ((t->from_sv_cal)(aTHX_ ST(1), &in.inst, &in.zone, &in.locale, &in.calendar) != TIME_KEEPER_OK)
                croak("_abi_v3: not a Time::Keeper value");
            code = (t->next_change)(aTHX_ &in.inst, &in.zone, &at, &before, &after);
            if (code == TIME_KEEPER_OK) {
                made = (t->new_sv_cal)(aTHX_ &at, &in.zone, in.locale, in.calendar);
                my_snprintf(err, sizeof err, "%d %d", (int)before, (int)after);
            }
        }
        else {
            for (i = 0; i < 12; i++)
                iv[i] = items > i + 2 && SvOK(ST(i + 2)) ? tk_arg_i64(aTHX_ ST(i + 2), "an argument") : 0;
            if ((t->from_sv_cal)(aTHX_ ST(1), &in.inst, &in.zone, &in.locale, &in.calendar) != TIME_KEEPER_OK)
                croak("_abi_v3: not a Time::Keeper value");
            if (strEQ(op, "plus")) {
                time_keeper_parts p;
                p.years = iv[0]; p.months = iv[1]; p.weeks = iv[2]; p.days = iv[3]; p.hours = iv[4];
                p.minutes = iv[5]; p.seconds = iv[6]; p.nanoseconds = iv[7]; p.end_of_month = (int)iv[8];
                code = (t->plus)(aTHX_ &in, &p, (int)iv[9], (int)iv[10], &out, err, sizeof err);
            }
            else if (strEQ(op, "truncate"))
                code = (t->truncate)(aTHX_ &in, (int)iv[0], (int)iv[1], &out, err, sizeof err);
            else if (strEQ(op, "end_of"))
                code = (t->end_of)(aTHX_ &in, (int)iv[0], (int)iv[1], &out, err, sizeof err);
            else if (strEQ(op, "adjust_dow"))
                code = (t->adjust_dow)(aTHX_ &in, (int)iv[0], (int)iv[1], (int)iv[2], (int)iv[3], (int)iv[4], &out, err, sizeof err);
            else if (strEQ(op, "nth_in_month"))
                code = (t->nth_in_month)(aTHX_ &in, (int)iv[0], (int)iv[1], (int)iv[2], (int)iv[3], &out, err, sizeof err);
            else if (strEQ(op, "with_time"))
                code = (t->with_time)(aTHX_ &in, (int)iv[0], (int)iv[1], (int)iv[2], (int32_t)iv[3], (int)iv[4], (int)iv[5],
                                       &out, err, sizeof err);
            else
                croak("_abi_v3: no entry '%s'", op);
            have_out = 1;
        }
        if (have_out && code == TIME_KEEPER_OK)
            made = (t->new_sv_cal)(aTHX_ &out.inst, &out.zone, out.locale, out.calendar);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(code)));
        PUSHs(made ? sv_2mortal(made) : &PL_sv_undef);
        PUSHs(err[0] ? sv_2mortal(newSVpv(err, 0)) : &PL_sv_undef);
