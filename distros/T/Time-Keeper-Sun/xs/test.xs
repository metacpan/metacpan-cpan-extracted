# Doors for the tests only.

MODULE = Time::Keeper::Sun    PACKAGE = Time::Keeper::Sun

# The version of Time::Keeper's table this needs.
IV
_tk_abi_built()
    CODE:
        RETVAL = TKS_TK_ABI_NEEDS;
    OUTPUT:
        RETVAL

# The version of the Time::Keeper header this was compiled against.
IV
_tk_abi_header()
    CODE:
        RETVAL = TIME_KEEPER_ABI_VERSION;
    OUTPUT:
        RETVAL

# Finds the table, as the first method to need it will, and gives its
# version.
IV
_tk_abi_version()
    CODE:
        RETVAL = tks_tk(aTHX)->abi_version;
    OUTPUT:
        RETVAL

# Lets go of the table, so the next method looks for it again.
void
_tk_abi_forget()
    CODE:
        tks_tk_table = NULL;

# Whether the table has been looked for yet, without looking.
IV
_tk_abi_resolved()
    CODE:
        RETVAL = tks_tk_table ? 1 : 0;
    OUTPUT:
        RETVAL

# The current time through the table: the one entry that proves a call
# goes through, in this phase.
void
_tk_now()
    PREINIT:
        time_keeper_instant t;
    PPCODE:
        if ((tks_tk(aTHX)->now)(&t) != TIME_KEEPER_OK)
            croak("Time::Keeper's now refused");
        EXTEND(SP, 2);
        mPUSHn((NV)t.sec);
        mPUSHi(t.nsec);

# ---- Phase 02: the time scales ----------------------------------------

NV
_jd(t)
        SV *t
    PREINIT:
        time_keeper_instant in;
    CODE:
        tks_instant_arg(aTHX_ t, &in, "_jd");
        RETVAL = tks_jd_ut(&in);
    OUTPUT:
        RETVAL

NV
_jde(t)
        SV *t
    PREINIT:
        time_keeper_instant in;
    CODE:
        tks_instant_arg(aTHX_ t, &in, "_jde");
        RETVAL = tks_jde(aTHX_ &in);
    OUTPUT:
        RETVAL

# The instant of a JD: seconds and nanoseconds, exact; or rounded to the
# second as results are.
void
_instant_from_jd(jd, round = 0)
        NV jd
        IV round
    PREINIT:
        time_keeper_instant out;
    PPCODE:
        if (round)
            tks_instant_from_jd_second((double)jd, &out);
        else
            tks_instant_from_jd((double)jd, &out);
        EXTEND(SP, 2);
        mPUSHn((NV)out.sec);
        mPUSHi(out.nsec);

NV
_delta_t_poly(y)
        NV y
    CODE:
        RETVAL = tks_delta_t_poly((double)y);
    OUTPUT:
        RETVAL

NV
_decimal_year(t)
        SV *t
    PREINIT:
        time_keeper_instant in;
    CODE:
        tks_instant_arg(aTHX_ t, &in, "_decimal_year");
        RETVAL = tks_decimal_year(tks_jd_ut(&in));
    OUTPUT:
        RETVAL

# Mean and apparent sidereal time at Greenwich, degrees.
void
_sidereal(t)
        SV *t
    PREINIT:
        time_keeper_instant in;
        double jd;
    PPCODE:
        tks_instant_arg(aTHX_ t, &in, "_sidereal");
        jd = tks_jd_ut(&in);
        EXTEND(SP, 2);
        mPUSHn(tks_sidereal_mean(jd));
        mPUSHn(tks_sidereal_apparent(jd, tks_jde(aTHX_ &in)));

# The nutation in longitude and in obliquity, arcseconds, at the TT of the
# instant.
void
_nutation(t)
        SV *t
    PREINIT:
        time_keeper_instant in;
        double dpsi, deps;
    PPCODE:
        tks_instant_arg(aTHX_ t, &in, "_nutation");
        tks_nutation(tks_T(tks_jde(aTHX_ &in)), &dpsi, &deps);
        EXTEND(SP, 2);
        mPUSHn(dpsi);
        mPUSHn(deps);

# The mean and true obliquity, degrees.
void
_obliquity(t)
        SV *t
    PREINIT:
        time_keeper_instant in;
        double T;
    PPCODE:
        tks_instant_arg(aTHX_ t, &in, "_obliquity");
        T = tks_T(tks_jde(aTHX_ &in));
        EXTEND(SP, 2);
        mPUSHn(tks_obliquity_mean(T));
        mPUSHn(tks_obliquity_true(T));

NV
_deg_norm(d)
        NV d
    CODE:
        RETVAL = tks_deg_norm((double)d);
    OUTPUT:
        RETVAL

# ---- Phase 03: the sun --------------------------------------------------

# The sun at a JDE, for the book's examples, which are given in TD.
void
_sun_at_jde(jde)
        NV jde
    PREINIT:
        tks_sunpos s;
    PPCODE:
        tks_sun_at((double)jde, &s);
        EXTEND(SP, 10);
        mPUSHn(s.T);
        mPUSHn(s.L0);
        mPUSHn(s.M);
        mPUSHn(s.e);
        mPUSHn(s.lon_true);
        mPUSHn(s.lon);
        mPUSHn(s.ra);
        mPUSHn(s.dec);
        mPUSHn(s.R);
        mPUSHn(s.eot);

# Altitude, azimuth from the north and the hour angle of a body at an
# apparent (ra, dec) in degrees, from (lat, east lon), at a UT instant.
void
_altaz(t, lat, lon, ra, dec)
        SV *t
        NV lat
        NV lon
        NV ra
        NV dec
    PREINIT:
        time_keeper_instant in;
        double alt, az, H;
    PPCODE:
        tks_instant_arg(aTHX_ t, &in, "_altaz");
        tks_altaz(tks_jd_ut(&in), tks_jde(aTHX_ &in), (double)lat, (double)lon, (double)ra, (double)dec, &alt, &az, &H);
        EXTEND(SP, 3);
        mPUSHn(alt);
        mPUSHn(az);
        mPUSHn(H);

NV
_refraction(h)
        NV h
    CODE:
        RETVAL = tks_refraction((double)h);
    OUTPUT:
        RETVAL

IV
_place_size()
    CODE:
        RETVAL = (IV)sizeof(tks_place);
    OUTPUT:
        RETVAL

# ---- Phase 04: the horizon ----------------------------------------------

NV
_horizon(place)
        SV *place
    CODE:
        RETVAL = tks_horizon(tks_place_of(aTHX_ place, "_horizon"));
    OUTPUT:
        RETVAL

# Whether an epoch second lies in a day's window, by the engine's own test.
IV
_day_holds(day, sec)
        SV *day
        NV sec
    CODE:
        RETVAL = tks_in_window(tks_day_of(aTHX_ day, "_day_holds"), (int64_t)sec);
    OUTPUT:
        RETVAL

# ---- Phase 05: the moon ---------------------------------------------------

NV
_phase_snap(year, which)
        NV year
        IV which
    CODE:
        RETVAL = tks_phase_snap((double)year, (int)which);
    OUTPUT:
        RETVAL

NV
_phase_mean_jde(k)
        NV k
    CODE:
        RETVAL = tks_phase_mean_jde((double)k);
    OUTPUT:
        RETVAL

# The JDE (TT) of the true phase k: the book's examples are in TD.
NV
_phase_jde(k)
        NV k
    CODE:
        RETVAL = tks_phase_jde((double)k);
    OUTPUT:
        RETVAL

# Elongation, phase angle and illuminated fraction at a JDE, by 48.4.
void
_moon_at_jde(jde)
        NV jde
    PREINIT:
        double e;
    PPCODE:
        tks_moon_angles((double)jde, &e);
        EXTEND(SP, 3);
        mPUSHn(e);
        mPUSHn(e <= 180.0 ? 180.0 - e : e - 180.0);
        mPUSHn((1.0 - cos(tks_rad(e))) / 2.0);

IV
_moonday_holds(day, sec)
        SV *day
        NV sec
    CODE:
        RETVAL = tks_moonday_in(tks_moonday_of(aTHX_ day, "_moonday_holds"), (int64_t)sec);
    OUTPUT:
        RETVAL

# ---- Phase 06: the seasons ------------------------------------------------

# The JDE (TT) of a season's event: 0 March, 1 June, 2 September, 3 December.
NV
_season_jde(year, which)
        IV year
        IV which
    CODE:
        RETVAL = tks_season_jde((int64_t)year, (int)which);
    OUTPUT:
        RETVAL

# ---- 0.02 Phase 01: the layout --------------------------------------------

# How many times a day's transits have been walked, and the count reset.
IV
_day_walks()
    CODE:
        RETVAL = tks_day_walks;
        tks_day_walks = 0;
    OUTPUT:
        RETVAL

# Which depths a day has computed, as a bit mask.
IV
_day_done(day)
        SV *day
    CODE:
        RETVAL = tks_day_of(aTHX_ day, "_day_done")->done;
    OUTPUT:
        RETVAL

# The sizes of the structs a place and a day hold.
void
_sizes()
    PPCODE:
        EXTEND(SP, 3);
        mPUSHi((IV)sizeof(tks_place));
        mPUSHi((IV)sizeof(tks_day));
        mPUSHi((IV)sizeof(tks_moonday));

# The interned names: their count, and a name's id.
IV
_name_count()
    CODE:
        TKS_NAMES_LOCK;
        RETVAL = tks_names_n;
        TKS_NAMES_UNLOCK;
    OUTPUT:
        RETVAL

IV
_name_id(name)
        SV *name
    PREINIT:
        STRLEN len;
        const char *s;
    CODE:
        s = SvPV(name, len);
        RETVAL = tks_name_id(aTHX_ s, len);
    OUTPUT:
        RETVAL

SV *
_name_str(id)
        IV id
    CODE:
        RETVAL = tks_name_sv(aTHX_ (int)id);
    OUTPUT:
        RETVAL

# ---- 0.02 Phase 02: the moon's place -----------------------------------------

# The moon at a JDE: geometric longitude, latitude, distance, parallax,
# apparent longitude, right ascension, declination.
void
_moon_place_jde(jde)
        NV jde
    PREINIT:
        tks_moonplace m;
    PPCODE:
        tks_moon_place((double)jde, &m);
        EXTEND(SP, 7);
        mPUSHn(m.lon_geo);
        mPUSHn(m.lat);
        mPUSHn(m.distance);
        mPUSHn(m.parallax);
        mPUSHn(m.lon);
        mPUSHn(m.ra);
        mPUSHn(m.dec);

void
_parallax_constants(lat, height)
        NV lat
        NV height
    PREINIT:
        double rs, rc;
    PPCODE:
        tks_parallax_constants((double)lat, (double)height, &rs, &rc);
        EXTEND(SP, 2);
        mPUSHn(rs);
        mPUSHn(rc);

void
_topocentric(H, dec, pi, rs, rc)
        NV H
        NV dec
        NV pi
        NV rs
        NV rc
    PREINIT:
        double Ht, dect;
    PPCODE:
        tks_topocentric((double)H, (double)dec, (double)pi, (double)rs, (double)rc, &Ht, &dect);
        EXTEND(SP, 2);
        mPUSHn(Ht);
        mPUSHn(dect);

# The moon from a place at an instant: geocentric hour angle, the geocentric
# altitude and azimuth, the topocentric declination, altitude, apparent
# altitude and azimuth.
void
_moon_view(place, t)
        SV *place
        SV *t
    PREINIT:
        time_keeper_instant in;
        tks_moonview v;
    PPCODE:
        tks_instant_arg(aTHX_ t, &in, "_moon_view");
        tks_moon_view(aTHX_ tks_place_of(aTHX_ place, "_moon_view"), &in, &v);
        EXTEND(SP, 7);
        mPUSHn(v.H);
        mPUSHn(v.alt_geo);
        mPUSHn(v.az_geo);
        mPUSHn(v.dect);
        mPUSHn(v.alt);
        mPUSHn(v.app_alt);
        mPUSHn(v.az);

# ---- 0.02 Phase 03: the exact fraction ----------------------------------------

# Elongation, phase angle and fraction at a JDE by 48.2 and 48.3.
void
_moon_exact_jde(jde)
        NV jde
    PREINIT:
        double e, i;
    PPCODE:
        tks_moon_exact((double)jde, &e, &i);
        EXTEND(SP, 3);
        mPUSHn(e);
        mPUSHn(i);
        mPUSHn((1.0 + cos(tks_rad(i))) / 2.0);
