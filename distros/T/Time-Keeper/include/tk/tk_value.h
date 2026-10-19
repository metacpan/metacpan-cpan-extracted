#ifndef TK_VALUE_H
#define TK_VALUE_H

/* A Time::Keeper value: a blessed reference to a read-only string holding
 * one tk_value. Values never change once made (K1): every method that
 * would change one returns a new one. The civil fields are worked out the
 * first time one is read and kept in the struct, which is safe because the
 * instant they come from never changes.
 *
 * A zone is one of four kinds. UTC, floating and fixed offsets are the
 * core's own and never load Time::Keeper::Zone; a named zone is
 * TK_ZONE_NAMED plus Zone's id for the name. */

#define TK_ZONE_UTC      0
#define TK_ZONE_FLOATING 1
#define TK_ZONE_FIXED    2
#define TK_ZONE_NAMED    3

#define TK_F_CIVIL 0x01   /* civil holds the local fields */
#define TK_F_DST   0x02
#define TK_F_CAL   0x04   /* cal holds the fields read in the value's calendar */

#define TK_MAX_FIXED_OFFSET (24 * 3600 - 1)

/* The fields of a day read in the value's calendar, packed: a year fits
 * int32 (years run to a thousand million), the rest in a byte or two. Filled
 * once, like civil, since the instant, zone and calendar never change; a copy
 * that changes its calendar drops it (tk_value_set_calendar). */
typedef struct tk_calcache {
    int32_t  year;
    int32_t  era_year;
    uint16_t doy;
    uint16_t days_in_year;
    uint8_t  month;             /* ordinal */
    uint8_t  day;
    uint8_t  month_number;      /* the number in the month code */
    uint8_t  era;
    uint8_t  months_in_year;
    uint8_t  days_in_month;
    uint8_t  flags;             /* TK_CC_* */
    uint8_t  pad;
} tk_calcache;
#define TK_CC_LEAP_MONTH 0x01
#define TK_CC_LEAP_YEAR  0x02

typedef struct tk_value {
    tk_instant inst;    /* UTC; for a floating value, the wall time read as UTC */
    int32_t    utoff;   /* seconds east of UTC at inst; 0 for UTC and floating */
    uint16_t   zone;
    uint16_t   locale;  /* Phase 10; 0 is English */
    uint8_t    flags;
    uint8_t    kind;     /* TK_KIND_*: 0 for a Time::Keeper value */
    uint8_t    calendar; /* TK_CAL_*: 0 is the Gregorian */
    uint8_t    pad;
    tk_civil   civil;
    tk_calcache cal;    /* the calendar's fields, filled on the first read (R14a) */
} tk_value;

/* The plain classes share the struct: a floating value at midnight of the
 * day it names, blessed into its own class, telling its kind here. */
#define TK_KIND_DATETIME   0
#define TK_KIND_DATE       1
#define TK_KIND_TIME       2
#define TK_KIND_YEAR_MONTH 3
#define TK_KIND_MONTH_DAY  4
#define TK_KIND_COUNT      5

typedef struct tk_zone_spec {
    uint16_t zone;
    int32_t  fixed;     /* the offset of a TK_ZONE_FIXED zone */
} tk_zone_spec;

/* The gap and overlap choices, as Zone's ABI numbers them. Defaults are
 * the owner's (K3): a gap croaks, an overlap takes the earlier instant. */
#define TK_GAP_DEFAULT     TKZ_GAP_CROAK
#define TK_OVERLAP_DEFAULT TKZ_OVERLAP_EARLIER

/* ---- per-interpreter state --------------------------------------------- */

#define MY_CXT_KEY "Time::Keeper::_guts" XS_VERSION
typedef struct {
    HV *stash;          /* Time::Keeper's, for the common case of no subclass */
    HV *dstash;         /* Time::Keeper::Duration's */
    HV *pstash[TK_KIND_COUNT];   /* the plain classes', by kind; [0] unused */
    GV *clock;          /* *Time::Keeper::CLOCK; its scalar is read on each call */
    int in_clock;       /* set while the clock's code ref runs */
} my_cxt_t;
START_MY_CXT

/* ---- zones -------------------------------------------------------------- */

/* +HH, +HHMM, +HH:MM, +HHMMSS, +HH:MM:SS, with + or -. */
static int
tk_parse_offset(const char *s, STRLEN len, int32_t *off)
{
    int sign, h, m = 0, sec = 0;
    STRLEN i = 1;
    if (len < 3 || (s[0] != '+' && s[0] != '-'))
        return 0;
    sign = s[0] == '-' ? -1 : 1;
#define TK_DIG2(at) (isDIGIT(s[at]) && isDIGIT(s[at + 1]) ? (s[at] - '0') * 10 + (s[at + 1] - '0') : -1)
    if ((h = TK_DIG2(i)) < 0) return 0;
    i += 2;
    if (i < len) {
        if (s[i] == ':') i++;
        if (i + 2 > len || (m = TK_DIG2(i)) < 0) return 0;
        i += 2;
        if (i < len) {
            if (s[i] == ':') i++;
            if (i + 2 > len || (sec = TK_DIG2(i)) < 0) return 0;
            i += 2;
        }
    }
#undef TK_DIG2
    if (i != len || m > 59 || sec > 59)
        return 0;
    *off = sign * (h * 3600 + m * 60 + sec);
    return *off >= -TK_MAX_FIXED_OFFSET && *off <= TK_MAX_FIXED_OFFSET;
}

static int
tk_ieq(const char *a, STRLEN alen, const char *b)
{
    STRLEN i;
    for (i = 0; i < alen; i++)
        if (!b[i] || toLOWER(a[i]) != toLOWER(b[i]))
            return 0;
    return b[alen] == '\0';
}

static int tk_is_value(pTHX_ SV *sv);
static const tk_value *tk_value_of(pTHX_ SV *sv, const char *what);

/* A zone argument: undef (UTC, K9), "UTC", "GMT" or "Z", "floating",
 * "local", an offset, a zone name, or another value (its zone). */
static void
tk_zone_spec_from_sv(pTHX_ SV *sv, tk_zone_spec *z, const char *what)
{
    STRLEN len;
    const char *s;
    int id;

    z->fixed = 0;
    if (!sv || !SvOK(sv)) {
        z->zone = TK_ZONE_UTC;
        return;
    }
    if (tk_is_value(aTHX_ sv)) {
        const tk_value *v = tk_value_of(aTHX_ sv, what);
        z->zone = v->zone;
        z->fixed = v->zone == TK_ZONE_FIXED ? v->utoff : 0;
        return;
    }
    if (SvROK(sv))
        croak("%s: a time zone is a name, an offset or a Time::Keeper value", what);
    s = SvPV(sv, len);
    if (tk_ieq(s, len, "UTC") || tk_ieq(s, len, "GMT") || tk_ieq(s, len, "Z")) {
        z->zone = TK_ZONE_UTC;
        return;
    }
    if (tk_ieq(s, len, "floating")) {
        z->zone = TK_ZONE_FLOATING;
        return;
    }
    if (tk_parse_offset(s, len, &z->fixed)) {
        z->zone = z->fixed == 0 ? TK_ZONE_UTC : TK_ZONE_FIXED;
        return;
    }
    if (len && (s[0] == '+' || s[0] == '-'))
        croak("%s: '%" SVf "' is not an offset: +HH, +HH:MM or +HH:MM:SS, under 24 hours",
              what, SVfARG(sv));
    if (tk_ieq(s, len, "local")) {
        SV **tz = hv_fetchs(GvHVn(PL_envgv), "TZ", 0);
        STRLEN tzlen = 0;
        const char *tzs = NULL;
        if (tz && SvOK(*tz))
            tzs = SvPV(*tz, tzlen);
        id = (tk_zone_abi(aTHX)->local_zone)(tzs, tzlen);
    }
    else
        id = (tk_zone_abi(aTHX)->lookup)(s, len);
    if (id < 0)
        croak("%s: no time zone named '%" SVf "'", what, SVfARG(sv));
    z->zone = (uint16_t)(TK_ZONE_NAMED + id);
}

/* The offset and DST flag of a zone at a UTC instant. */
static void
tk_zone_offset(pTHX_ const tk_zone_spec *z, const tk_instant *t, int32_t *utoff, int *isdst)
{
    *isdst = 0;
    switch (z->zone) {
    case TK_ZONE_UTC:
    case TK_ZONE_FLOATING:
        *utoff = 0;
        break;
    case TK_ZONE_FIXED:
        *utoff = z->fixed;
        break;
    default:
        (tk_zone_abi(aTHX)->offset_at)(z->zone - TK_ZONE_NAMED, t->sec, utoff, isdst, NULL);
        break;
    }
}

/* ---- values ------------------------------------------------------------- */

static void
tk_value_init(pTHX_ tk_value *v, const tk_instant *t, const tk_zone_spec *z)
{
    int isdst;
    Zero(v, 1, tk_value);
    v->inst = *t;
    v->zone = z->zone;
    tk_zone_offset(aTHX_ z, t, &v->utoff, &isdst);
    if (isdst)
        v->flags |= TK_F_DST;
}

static void
tk_value_zone(const tk_value *v, tk_zone_spec *z)
{
    z->zone = v->zone;
    z->fixed = v->zone == TK_ZONE_FIXED ? v->utoff : 0;
}

/* The local fields, worked out once. */
static const tk_civil *
tk_value_civil(tk_value *v)
{
    if (!(v->flags & TK_F_CIVIL)) {
        tk_instant local = v->inst;
        local.sec += v->utoff;
        tk_civil_from_instant(&local, &v->civil);
        v->flags |= TK_F_CIVIL;
    }
    return &v->civil;
}

static HV *
tk_stash_for(pTHX_ SV *class_or_obj)
{
    dMY_CXT;
    if (SvROK(class_or_obj) && SvOBJECT(SvRV(class_or_obj)))
        return SvSTASH(SvRV(class_or_obj));
    if (SvPOK(class_or_obj) && SvCUR(class_or_obj) == 12
        && memEQ(SvPVX(class_or_obj), "Time::Keeper", 12))
        return MY_CXT.stash;
    return gv_stashsv(class_or_obj, GV_ADD);
}

static SV *
tk_value_new_sv(pTHX_ HV *stash, const tk_value *v)
{
    SV *inner = newSVpvn((const char *)v, sizeof *v);
    /* The referent is not made read-only: bless croaks on a read-only
     * referent, and CBOR::XS and JSON::XS re-bless a value before calling
     * its FREEZE. The API keeps a value immutable; tk_value_of checks the
     * bytes on every read. */
    return sv_bless(newRV_noinc(inner), stash);
}

static int
tk_is_value(pTHX_ SV *sv)
{
    SV *in;
    dMY_CXT;
    if (!SvROK(sv))
        return 0;
    in = SvRV(sv);
    if (!SvOBJECT(in) || SvROK(in) || !SvPOK(in) || SvCUR(in) != sizeof(tk_value))
        return 0;
    return SvSTASH(in) == MY_CXT.stash || sv_derived_from(sv, "Time::Keeper");
}

/* The struct inside a value, checked: its bytes are its own, and a forged
 * string of the right length must not lead the engine astray. */
static const tk_value *
tk_value_of(pTHX_ SV *sv, const char *what)
{
    tk_value *v;
    if (!tk_is_value(aTHX_ sv))
        croak("%s: not a Time::Keeper value", what);
    v = (tk_value *)SvPVX(SvRV(sv));
    if (!tk_instant_valid(&v->inst)
        || (v->zone >= TK_ZONE_NAMED && v->zone - TK_ZONE_NAMED >= (tk_zone_abi(aTHX)->zone_count)())
        || (v->zone == TK_ZONE_FIXED && (v->utoff < -TK_MAX_FIXED_OFFSET || v->utoff > TK_MAX_FIXED_OFFSET))
        || (v->zone < TK_ZONE_FIXED && v->utoff != 0)
        || v->kind != TK_KIND_DATETIME || v->calendar >= TK_CAL_COUNT)
        croak("%s: a damaged Time::Keeper value", what);
    return v;
}

/* For the accessors, which fill the civil cache. */
#define tk_value_rw(sv, what) ((tk_value *)tk_value_of(aTHX_ (sv), (what)))

/* ---- from a wall-clock time ---------------------------------------------- */

/* The value whose wall-clock time in zone z is the local fields given. A
 * second of 60 is a leap second: resolved as :59 and moved on a second,
 * then refused unless it names one. */
#define TK_LOCAL_OK      0
#define TK_LOCAL_IN_GAP  1   /* gap was croak and the time fell in one */
#define TK_LOCAL_NO_LEAP 2   /* second 60 where there was no leap second */
#define TK_LOCAL_RANGE   3

/* As tk_value_from_local, but saying what went wrong instead of croaking:
 * arithmetic needs to know a wall time fell in a gap and try another. */
static int
tk_value_from_local_rc(pTHX_ tk_value *v, const tk_zone_spec *z,
                       int64_t y, unsigned m, unsigned d,
                       int64_t hour, int64_t minute, int64_t second, int32_t nsec,
                       int gap, int overlap)
{
    tk_instant local, t;
    int leap = second == 60;

    if (y < TK_YEAR_MIN || y > TK_YEAR_MAX)
        return TK_LOCAL_RANGE;
    tk_instant_from_civil(y, m, d, hour, minute, leap ? 59 : second, nsec, &local);
    t = local;
    switch (z->zone) {
    case TK_ZONE_UTC:
    case TK_ZONE_FLOATING:
        break;
    case TK_ZONE_FIXED:
        t.sec -= z->fixed;
        break;
    default: {
        int64_t utc = 0;
        int r = (tk_zone_abi(aTHX)->resolve_local)(z->zone - TK_ZONE_NAMED, local.sec, gap, overlap, &utc);
        if (r == TKZ_LOCAL_GAP && gap == TKZ_GAP_CROAK)
            return TK_LOCAL_IN_GAP;
        t.sec = utc;
        break;
    }
    }
    if (leap)
        t.nsec += TK_NSECS_PER_SEC;
    if (!tk_instant_valid(&t))
        return leap ? TK_LOCAL_NO_LEAP : TK_LOCAL_RANGE;
    tk_value_init(aTHX_ v, &t, z);
    return TK_LOCAL_OK;
}

static void
tk_value_from_local(pTHX_ tk_value *v, const tk_zone_spec *z,
                    int64_t y, unsigned m, unsigned d,
                    int64_t hour, int64_t minute, int64_t second, int32_t nsec,
                    int gap, int overlap, const char *what)
{
    int r = tk_value_from_local_rc(aTHX_ v, z, y, m, d, hour, minute, second, nsec, gap, overlap);
    if (r == TK_LOCAL_IN_GAP)
        croak("%s: %04" IVdf "-%02u-%02u %02" IVdf ":%02" IVdf ":%02" IVdf
              " did not happen in %s: the clocks went forward over it (gap => 'forward' or 'backward' takes it anyway)",
              what, (IV)y, m, d, (IV)hour, (IV)minute, (IV)second,
              (tk_zone_abi(aTHX)->name)(z->zone - TK_ZONE_NAMED));
    if (r == TK_LOCAL_NO_LEAP)
        croak("%s: there was no leap second at %04" IVdf "-%02u-%02u %02" IVdf ":%02" IVdf ":60",
              what, (IV)y, m, d, (IV)hour, (IV)minute);
    if (r == TK_LOCAL_RANGE)
        croak("%s: out of range", what);
}

/* Midnight at the start of v's day in its zone, or the first moment of
 * the day that happened when the clocks jumped over midnight: today never
 * dies. */
static void
tk_value_start_of_day(pTHX_ tk_value *nv, tk_value *v, const char *what)
{
    tk_zone_spec z;
    const tk_civil *c = tk_value_civil(v);
    tk_value_zone(v, &z);
    tk_value_from_local(aTHX_ nv, &z, c->year, c->month, c->day, 0, 0, 0, 0,
                        TKZ_GAP_FORWARD, TK_OVERLAP_DEFAULT, what);
}

#endif
