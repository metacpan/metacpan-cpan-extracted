#ifndef TKR_ICAL_H
#define TKR_ICAL_H

/* iCalendar text in and out: the recurrence properties of one component
 * (DTSTART, RRULE, RDATE, EXDATE, EXRULE), folded lines unfolded, a TZID
 * read as an IANA name or a Windows name, VALUE=DATE for whole days, a
 * PERIOD refused. Everything else in the text is ignored. The writer gives
 * the lines back strictly: CRLF ends, folded at 75 octets, RRULE, RDATE and
 * EXDATE but never EXRULE, UNTIL and UTC values with Z. The frozen forms
 * of a rule and a set (FREEZE, Storable) are text too, and defined here:
 * a rule is one line, a set is a header line and its iCalendar lines with
 * the EXRULEs kept and every cron written as an X-TKR-CRON line. */

#define TKR_ICAL_FOLD 75

typedef struct tkr_ical_line {
    const char *name, *params, *value;
    size_t nlen, plen, vlen;
} tkr_ical_line;

/* The text with its folds removed, in a new buffer freed with the scope. */
static char *
tkr_ical_unfold(pTHX_ const char *s, size_t len, size_t *outlen)
{
    char *buf, *w;
    size_t i;
    Newx(buf, len + 1, char);
    w = buf;
    for (i = 0; i < len; i++) {
        if (s[i] == '\r' && i + 2 < len && s[i + 1] == '\n' && (s[i + 2] == ' ' || s[i + 2] == '\t')) { i += 2; continue; }
        if (s[i] == '\n' && i + 1 < len && (s[i + 1] == ' ' || s[i + 1] == '\t')) { i += 1; continue; }
        *w++ = s[i];
    }
    *w = 0;
    *outlen = (size_t)(w - buf);
    return buf;
}

/* The next content line: name, parameters (between the first ; and the :
 * outside quotes) and value. 0 at the end. */
static int
tkr_ical_next_line(const char *s, size_t len, size_t *pos, tkr_ical_line *l)
{
    size_t i = *pos, start, colon = 0, semi = 0;
    int quoted = 0;
    while (i < len && (s[i] == '\r' || s[i] == '\n')) i++;
    if (i >= len) return 0;
    start = i;
    while (i < len && s[i] != '\r' && s[i] != '\n') {
        if (s[i] == '"') quoted = !quoted;
        else if (!quoted && s[i] == ':' && !colon) colon = i;
        else if (!quoted && s[i] == ';' && !semi && !colon) semi = i;
        i++;
    }
    *pos = i;
    l->name = s + start;
    if (!colon) {
        l->nlen = semi ? semi - start : i - start;
        l->params = l->value = s + i;
        l->plen = l->vlen = 0;
        return 1;
    }
    l->nlen = semi ? semi - start : colon - start;
    l->params = semi ? s + semi + 1 : s + colon;
    l->plen = semi ? colon - semi - 1 : 0;
    l->value = s + colon + 1;
    l->vlen = i - colon - 1;
    return 1;
}

/* A parameter's value, quotes removed; 0 when absent. */
static int
tkr_ical_param(const tkr_ical_line *l, const char *name, const char **v, size_t *vlen)
{
    size_t i = 0, nlen = strlen(name);
    while (i < l->plen) {
        size_t ns = i, ne, vs, ve;
        int quoted = 0;
        while (i < l->plen && l->params[i] != '=' && l->params[i] != ';') i++;
        ne = i;
        if (i < l->plen && l->params[i] == '=') i++;
        vs = i;
        while (i < l->plen && (quoted || l->params[i] != ';')) {
            if (l->params[i] == '"') quoted = !quoted;
            i++;
        }
        ve = i;
        if (i < l->plen) i++;
        if (ne - ns == nlen && tkr_ieq(l->params + ns, name, nlen)) {
            if (ve > vs && l->params[vs] == '"' && l->params[ve - 1] == '"') { vs++; ve--; }
            *v = l->params + vs;
            *vlen = ve - vs;
            return 1;
        }
    }
    return 0;
}

#define TKR_ICAL_DATE     0
#define TKR_ICAL_FLOATING 1
#define TKR_ICAL_UTC      2

/* A DATE or DATE-TIME value as wall seconds (as if UTC) and its kind. */
static int
tkr_ical_value(const char *v, size_t len, int64_t *wall, int *kind)
{
    long y, mo, d, h = 0, mi = 0, s = 0;
    int neg;
    size_t i;
    if (len == 8) *kind = TKR_ICAL_DATE;
    else if (len == 15 && v[8] == 'T') *kind = TKR_ICAL_FLOATING;
    else if (len == 16 && v[8] == 'T' && (v[15] == 'Z' || v[15] == 'z')) *kind = TKR_ICAL_UTC;
    else return 0;
    for (i = 0; i < len; i++)
        if (i != 8 && i != 15 && !isDIGIT(v[i]))
            return 0;
    y = tkr_num(v, 4, 0, &neg); mo = tkr_num(v + 4, 2, 0, &neg); d = tkr_num(v + 6, 2, 0, &neg);
    if (*kind != TKR_ICAL_DATE) {
        h = tkr_num(v + 9, 2, 0, &neg); mi = tkr_num(v + 11, 2, 0, &neg); s = tkr_num(v + 13, 2, 0, &neg);
    }
    if (mo < 1 || mo > 12 || d < 1 || (unsigned)d > tkr_days_in_month(y, (unsigned)mo) || h > 23 || mi > 59 || s > 60)
        return 0;
    *wall = tkr_days_from_civil(y, (unsigned)mo, (unsigned)d) * 86400 + h * 3600 + mi * 60 + s;
    return 1;
}

/* A TZID: an IANA name as Time::Keeper reads one, with or without a leading
 * slash, or a Windows name through Time::Keeper::Zone's table. */
static void
tkr_ical_zone(pTHX_ const char *tz, size_t len, time_keeper_zone *out, const char *what)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    SV *got = NULL;
    if (len && tz[0] == '/') { tz++; len--; }
    if ((T->zone_parse)(aTHX_ tz, len, out) == TIME_KEEPER_OK)
        return;
    tkr_tkz(aTHX);
    {
        dSP;
        int n;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpvs("Time::Keeper::Zone")));
        XPUSHs(sv_2mortal(newSVpvn(tz, len)));
        PUTBACK;
        n = call_method("windows_zone", G_SCALAR);
        SPAGAIN;
        if (n == 1) {
            SV *r = POPs;
            if (SvOK(r))
                got = newSVsv(r);
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    if (got) {
        STRLEN glen;
        const char *g = SvPV(got, glen);
        int rc = (T->zone_parse)(aTHX_ g, glen, out);
        SvREFCNT_dec(got);
        if (rc == TIME_KEEPER_OK)
            return;
    }
    croak("%s: TZID=%" SVf " is not a time zone", what, SVfARG(sv_2mortal(newSVpvn(tz, len))));
}

/* The lines, into the parts of a set. DTSTART is read first wherever it
 * stands, since every other property is read in its zone. */
static void
tkr_ical_parse(pTHX_ const char *text, size_t len, tkr_set_parts *p, const char *what)
{
    size_t ulen, pos;
    char *buf = tkr_ical_unfold(aTHX_ text, len, &ulen);
    tkr_ical_line l;
    int seen_start = 0, rule_lines = 0;
    const char *tz;
    size_t tzlen;
    time_keeper_zone z;
    int64_t wall;
    int kind;
    char err[TKR_ERR];
    SAVEFREEPV(buf);
    tkr_parts_init(p);
    p->zone.kind = TIME_KEEPER_ZONE_FLOATING;
    for (pos = 0; tkr_ical_next_line(buf, ulen, &pos, &l); ) {
        if (l.nlen != 7 || !tkr_ieq(l.name, "DTSTART", 7))
            continue;
        if (seen_start++) {
            
            croak("%s: two DTSTART lines", what);
        }
        if (!tkr_ical_value(l.value, l.vlen, &wall, &kind)) {
            
            croak("%s: DTSTART:%" SVf " is not a date or a date and time", what, SVfARG(sv_2mortal(newSVpvn(l.value, l.vlen))));
        }
        if (kind == TKR_ICAL_UTC)
            p->zone.kind = TIME_KEEPER_ZONE_UTC;
        else if (tkr_ical_param(&l, "TZID", &tz, &tzlen)) {
            tkr_ical_zone(aTHX_ tz, tzlen, &z, what);
            p->zone = z;
        }
        p->has_start = 1;
        p->start_is_day = kind == TKR_ICAL_DATE;
        p->start.sec = tkr_zone_instant(aTHX_ &p->zone, wall, what);
        p->start.nsec = 0;
    }
    for (pos = 0; tkr_ical_next_line(buf, ulen, &pos, &l); ) {
        int ex = 0, is_rule = 0, is_cron = 0;
        if ((l.nlen == 5 && tkr_ieq(l.name, "RRULE", 5)) || (l.nlen == 6 && tkr_ieq(l.name, "EXRULE", 6))) {
            is_rule = 1;
            ex = l.nlen == 6;
        }
        else if (l.nlen == 10 && tkr_ieq(l.name, "X-TKR-CRON", 10))
            is_cron = 1;
        else if ((l.nlen == 5 && tkr_ieq(l.name, "RDATE", 5)) || (l.nlen == 6 && tkr_ieq(l.name, "EXDATE", 6)))
            ex = l.nlen == 6;
        else
            continue;
        if (is_rule || is_cron) {
            tkr_rule r;
            rule_lines++;
            tkr_rule_init(&r);
            if (ex)
                r.flags |= TKR_F_EXRULE;
            r.zone = p->zone;
            r.gap = (uint8_t)p->gap;
            r.overlap = (uint8_t)p->overlap;
            if (is_cron) {
                if (!tkr_cron_parse(l.value, l.vlen, &r, err)) {
                    tkr_parts_free(p);
                    croak("%s: X-TKR-CRON: %s", what, err);
                }
                if (p->has_start) {
                    r.start = p->start;
                    r.flags |= TKR_F_HAS_START;
                }
            }
            else {
                if (!p->has_start) {
                    tkr_parts_free(p);
                    croak("%s: an %s needs a DTSTART", what, ex ? "EXRULE" : "RRULE");
                }
                r.start = p->start;
                r.flags |= TKR_F_HAS_START;
                if (!tkr_rrule_parse(l.value, l.vlen, &r, err)) {
                    tkr_parts_free(p);
                    croak("%s: %s: %s", what, ex ? "EXRULE" : "RRULE", err);
                }
                if (r.until_kind == TKR_UNTIL_FLOATING && r.zone.kind != TIME_KEEPER_ZONE_FLOATING) {
                    tkr_parts_free(p);
                    croak("%s: %s: UNTIL must be in UTC (end in Z) when DTSTART has a zone", what, ex ? "EXRULE" : "RRULE");
                }
                if (r.until_kind == TKR_UNTIL_UTC && r.zone.kind == TIME_KEEPER_ZONE_FLOATING) {
                    tkr_parts_free(p);
                    croak("%s: %s: UNTIL must be floating (no Z) when DTSTART is", what, ex ? "EXRULE" : "RRULE");
                }
            }
            if (!tkr_can_fire(aTHX_ &r, is_cron ? tkr_now_sec(aTHX) : 0, err)) {
                tkr_parts_free(p);
                croak("%s: %s:%" SVf " %s", what, is_cron ? "X-TKR-CRON" : ex ? "EXRULE" : "RRULE", SVfARG(sv_2mortal(newSVpvn(l.value, l.vlen))), err);
            }
            tkr_parts_add_rule(aTHX_ p, &r, ex, what);
        }
        else {
            const char *v, *vend;
            size_t vl;
            int want_date = 0;
            time_keeper_zone lz = p->zone;
            if (tkr_ical_param(&l, "VALUE", &v, &vl)) {
                if (vl == 6 && tkr_ieq(v, "PERIOD", 6)) {
                    tkr_parts_free(p);
                    croak("%s: %s;VALUE=PERIOD is not supported: a period is not an occurrence", what, ex ? "EXDATE" : "RDATE");
                }
                if (vl == 4 && tkr_ieq(v, "DATE", 4))
                    want_date = 1;
            }
            if (tkr_ical_param(&l, "TZID", &tz, &tzlen))
                tkr_ical_zone(aTHX_ tz, tzlen, &lz, what);
            v = l.value;
            vend = l.value + l.vlen;
            while (v < vend) {
                const char *e = v;
                while (e < vend && *e != ',') e++;
                if (!tkr_ical_value(v, (size_t)(e - v), &wall, &kind) || (want_date && kind != TKR_ICAL_DATE)) {
                    tkr_parts_free(p);
                    croak("%s: %s:%" SVf " is not a %s", what, ex ? "EXDATE" : "RDATE", SVfARG(sv_2mortal(newSVpvn(v, (STRLEN)(e - v)))),
                          want_date ? "date (YYYYMMDD)" : "date or a date and time");
                }
                if (kind == TKR_ICAL_DATE)
                    tkr_parts_add_date(aTHX_ p, ex, wall, 1, what);
                else if (kind == TKR_ICAL_UTC)
                    tkr_parts_add_raw(aTHX_ p, ex, wall, 0, what);
                else
                    tkr_parts_add_raw(aTHX_ p, ex, tkr_zone_instant(aTHX_ &lz, wall, what), 0, what);
                v = e + 1;
            }
        }
    }
    
    if (!rule_lines && !p->n_rdates) {
        if (p->has_start)
            tkr_parts_add_raw(aTHX_ p, 0, p->start.sec, 0, what);
        else {
            tkr_parts_free(p);
            croak("%s: nothing recurs: no DTSTART, RRULE or RDATE", what);
        }
    }
}

/* ---- the writer ----------------------------------------------------------- */

static void
tkr_ical_wall_text(SV *out, int64_t wall, int day_only, int utc)
{
    int64_t days = tkr_floor_div(wall, 86400), rem = wall - days * 86400, y;
    unsigned m, d;
    tkr_civil_from_days(days, &y, &m, &d);
    if (day_only)
        sv_catpvf(out, "%04" IVdf "%02u%02u", (IV)y, m, d);
    else
        sv_catpvf(out, "%04" IVdf "%02u%02uT%02d%02d%02d%s", (IV)y, m, d, (int)(rem / 3600), (int)(rem % 3600 / 60), (int)(rem % 60), utc ? "Z" : "");
}

/* One content line, folded at 75 octets, CRLF ended. */
static void
tkr_ical_fold(pTHX_ SV *out, SV *line)
{
    STRLEN len, i = 0;
    const char *s = SvPV(line, len);
    while (len - i > TKR_ICAL_FOLD) {
        sv_catpvn(out, s + i, i ? TKR_ICAL_FOLD - 1 : TKR_ICAL_FOLD);
        i += i ? TKR_ICAL_FOLD - 1 : TKR_ICAL_FOLD;
        sv_catpvs(out, "\r\n ");
    }
    sv_catpvn(out, s + i, len - i);
    sv_catpvs(out, "\r\n");
}

/* The zone's TZID parameter, or none for UTC and floating. */
static void
tkr_ical_tzid(pTHX_ SV *line, const time_keeper_zone *z)
{
    tkr_rule probe;
    SV *name;
    if (z->kind == TIME_KEEPER_ZONE_UTC || z->kind == TIME_KEEPER_ZONE_FLOATING)
        return;
    tkr_rule_init(&probe);
    probe.zone = *z;
    name = sv_2mortal(tkr_zone_name_sv(aTHX_ &probe));
    if (strchr(SvPV_nolen(name), ':'))
        sv_catpvf(line, ";TZID=\"%" SVf "\"", SVfARG(name));
    else
        sv_catpvf(line, ";TZID=%" SVf, SVfARG(name));
}

static void
tkr_ical_dates(pTHX_ SV *out, const tkr_set *s, const tkr_date *d, unsigned n, const char *prop)
{
    unsigned i, days = 0, times = 0;
    SV *line;
    for (i = 0; i < n; i++)
        if (d[i].is_day) days++; else times++;
    if (times) {
        int utc = s->zone.kind == TIME_KEEPER_ZONE_UTC;
        unsigned k = 0;
        line = sv_2mortal(newSVpv(prop, 0));
        tkr_ical_tzid(aTHX_ line, &s->zone);
        sv_catpvs(line, ":");
        for (i = 0; i < n; i++) {
            if (d[i].is_day) continue;
            if (k++) sv_catpvs(line, ",");
            tkr_ical_wall_text(line, utc ? d[i].at : tkr_zone_wall(aTHX_ &s->zone, d[i].at), 0, utc);
        }
        tkr_ical_fold(aTHX_ out, line);
    }
    if (days) {
        unsigned k = 0;
        line = sv_2mortal(newSVpv(prop, 0));
        sv_catpvs(line, ";VALUE=DATE:");
        for (i = 0; i < n; i++) {
            if (!d[i].is_day) continue;
            if (k++) sv_catpvs(line, ",");
            /* an added day was resolved to its midnight; a removed one is kept as the day */
            tkr_ical_wall_text(line, prop[0] == 'R' ? tkr_zone_wall(aTHX_ &s->zone, d[i].at) : d[i].at, 1, 0);
        }
        tkr_ical_fold(aTHX_ out, line);
    }
}

/* The set as iCalendar lines. For a frozen form the EXRULEs are kept and
 * every cron is an X-TKR-CRON line; otherwise a cron is written as the RRULE
 * it is, and one with no RRULE spelling dies. */
static void
tkr_ical_write(pTHX_ const tkr_set *s, SV *out, int frozen, const char *what)
{
    unsigned i, nr = s->n_rules + (frozen ? s->n_exrules : 0);
    SV *line;
    char err[TKR_ERR];
    if (s->has_start) {
        line = sv_2mortal(newSVpvs("DTSTART"));
        if (s->start_is_day && s->zone.kind == TIME_KEEPER_ZONE_FLOATING) {
            sv_catpvs(line, ";VALUE=DATE:");
            tkr_ical_wall_text(line, s->start.sec, 1, 0);
        }
        else {
            int utc = s->zone.kind == TIME_KEEPER_ZONE_UTC;
            tkr_ical_tzid(aTHX_ line, &s->zone);
            sv_catpvs(line, ":");
            tkr_ical_wall_text(line, utc ? s->start.sec : tkr_zone_wall(aTHX_ &s->zone, s->start.sec), 0, utc);
        }
        tkr_ical_fold(aTHX_ out, line);
    }
    for (i = 0; i < nr; i++) {
        const tkr_rule *r = &tkr_set_rules(s)[i];
        if ((r->flags & TKR_F_CRON) && frozen) {
            line = sv_2mortal(newSVpvs(""));
            if (!tkr_cron_write(aTHX_ r, line, err))
                croak("%s: %s", what, err);
            {
                SV *whole = sv_2mortal(newSVpvs("X-TKR-CRON:"));
                sv_catsv(whole, line);
                tkr_ical_fold(aTHX_ out, whole);
            }
            continue;
        }
        if (r->flags & TKR_F_EVERY)
            croak("%s: an @every cron is an interval from the last occurrence, which no RRULE says", what);
        if (r->flags & TKR_F_VIXIE)
            croak("%s: a cron with both day fields set fires on either, which no RRULE says", what);
        line = sv_2mortal(newSVpvs(""));
        tkr_rrule_write(aTHX_ r, line);
        {
            SV *whole = sv_2mortal(newSVpv(i < s->n_rules ? "RRULE:" : "EXRULE:", 0));
            sv_catsv(whole, line);
            tkr_ical_fold(aTHX_ out, whole);
        }
    }
    tkr_ical_dates(aTHX_ out, s, tkr_set_rdates(s), s->n_rdates, "RDATE");
    tkr_ical_dates(aTHX_ out, s, tkr_set_exdates(s), s->n_exdates, "EXDATE");
}

/* ---- the frozen forms ------------------------------------------------------ */

/* The locale's code: a value in it knows. */
static SV *
tkr_locale_code_sv(pTHX_ const time_keeper_zone *z, int locale)
{
    const time_keeper_abi *T = tkr_tk(aTHX);
    time_keeper_instant t;
    SV *val, *code = NULL;
    dSP;
    int n;
    t.sec = 0; t.nsec = 0;
    val = (T->new_sv)(aTHX_ &t, z, locale);
    if (!val)
        return newSVpvs("en");
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(val));
    PUTBACK;
    n = call_method("locale", G_SCALAR);
    SPAGAIN;
    if (n == 1) {
        SV *r = POPs;
        if (SvOK(r))
            code = newSVsv(r);
    }
    PUTBACK;
    FREETMPS;
    LEAVE;
    return code ? code : newSVpvs("en");
}

static int
tkr_locale_of_code(pTHX_ const char *code, size_t len)
{
    int id = (tkr_tk(aTHX)->locale_find)(code, len);
    return id < 0 ? 0 : id;
}

/* A rule: "tkr1 <zone> <locale> <start seconds or -> <nanoseconds> <gap> <overlap> rrule|cron <text>". */
static SV *
tkr_rule_freeze_sv(pTHX_ const tkr_rule *r, const char *what)
{
    SV *out = newSVpvs("tkr1 "), *zone = sv_2mortal(tkr_zone_name_sv(aTHX_ r)), *code = sv_2mortal(tkr_locale_code_sv(aTHX_ &r->zone, r->locale));
    SV *text = sv_2mortal(newSVpvs(""));
    char err[TKR_ERR];
    sv_catsv(out, zone);
    sv_catpvs(out, " ");
    sv_catsv(out, code);
    if (r->flags & TKR_F_HAS_START)
        sv_catpvf(out, " %" IVdf " %d", (IV)r->start.sec, (int)r->start.nsec);
    else
        sv_catpvs(out, " - 0");
    sv_catpvf(out, " %s %s ", tkr_gap_names[r->gap], tkr_overlap_names[r->overlap]);
    if (r->flags & TKR_F_CRON) {
        if (!tkr_cron_write(aTHX_ r, text, err))
            croak("%s: %s", what, err);
        sv_catpvs(out, "cron ");
    }
    else {
        tkr_rrule_write(aTHX_ r, text);
        sv_catpvs(out, "rrule ");
    }
    sv_catsv(out, text);
    return out;
}

/* A signed whole number of any length an epoch needs. */
static int
tkr_i64(const char *s, size_t len, int64_t *out)
{
    int64_t v = 0;
    int neg = 0;
    size_t i = 0;
    if (len && (s[0] == '-' || s[0] == '+')) { neg = s[0] == '-'; i = 1; }
    if (i >= len || len - i > 18) return 0;
    for (; i < len; i++) {
        if (!isDIGIT(s[i])) return 0;
        v = v * 10 + (s[i] - '0');
    }
    *out = neg ? -v : v;
    return 1;
}

static const char *
tkr_word(const char *p, const char *end, size_t *len)
{
    const char *s;
    while (p < end && *p == ' ') p++;
    s = p;
    while (p < end && *p != ' ' && *p != '\r' && *p != '\n') p++;
    *len = (size_t)(p - s);
    return s;
}

static void
tkr_rule_thaw(pTHX_ SV *frozen, tkr_rule *r, const char *what)
{
    STRLEN len;
    const char *s = SvPV(frozen, len), *end = s + len, *w, *p;
    size_t wl;
    char err[TKR_ERR];
    int neg, i;
    tkr_rule_init(r);
    w = tkr_word(s, end, &wl);
    if (wl != 4 || memcmp(w, "tkr1", 4) != 0)
        croak("%s: not a frozen Time::Keeper::Recurrence", what);
    w = tkr_word(w + wl, end, &wl);
    if ((tkr_tk(aTHX)->zone_parse)(aTHX_ w, wl, &r->zone) != TIME_KEEPER_OK)
        croak("%s: '%" SVf "' is not a time zone this build knows", what, SVfARG(sv_2mortal(newSVpvn(w, wl))));
    w = tkr_word(w + wl, end, &wl);
    r->locale = tkr_locale_of_code(aTHX_ w, wl);
    w = tkr_word(w + wl, end, &wl);
    if (!(wl == 1 && w[0] == '-')) {
        if (!tkr_i64(w, wl, &r->start.sec))
            croak("%s: a damaged frozen rule", what);
        r->flags |= TKR_F_HAS_START;
    }
    w = tkr_word(w + wl, end, &wl);
    r->start.nsec = (int32_t)tkr_num(w, wl, 0, &neg);
    w = tkr_word(w + wl, end, &wl);
    for (i = 0; i < 4; i++) if (strlen(tkr_gap_names[i]) == wl && memcmp(w, tkr_gap_names[i], wl) == 0) break;
    if (i == 4) croak("%s: a damaged frozen rule", what);
    r->gap = (uint8_t)i;
    w = tkr_word(w + wl, end, &wl);
    for (i = 0; i < 3; i++) if (strlen(tkr_overlap_names[i]) == wl && memcmp(w, tkr_overlap_names[i], wl) == 0) break;
    if (i == 3) croak("%s: a damaged frozen rule", what);
    r->overlap = (uint8_t)i;
    w = tkr_word(w + wl, end, &wl);
    p = w + wl;
    while (p < end && *p == ' ') p++;
    if (wl == 4 && memcmp(w, "cron", 4) == 0) {
        if (!tkr_cron_parse(p, (size_t)(end - p), r, err))
            croak("%s: %s", what, err);
    }
    else if (wl == 5 && memcmp(w, "rrule", 5) == 0) {
        if (!tkr_rrule_parse(p, (size_t)(end - p), r, err))
            croak("%s: %s", what, err);
    }
    else
        croak("%s: a damaged frozen rule", what);
}

/* A set: "tkrs1 <gap> <overlap> <locale> <start_is_day>" then the lines. */
static SV *
tkr_set_freeze_sv(pTHX_ const tkr_set *s, const char *what)
{
    SV *code = sv_2mortal(tkr_locale_code_sv(aTHX_ &s->zone, s->locale));
    SV *out = newSVpvf("tkrs1 %s %s %" SVf " %d\r\n", tkr_gap_names[s->gap], tkr_overlap_names[s->overlap], SVfARG(code), (int)s->start_is_day);
    tkr_ical_write(aTHX_ s, out, 1, what);
    return out;
}

static void
tkr_set_thaw(pTHX_ SV *frozen, tkr_set_parts *p, const char *what)
{
    STRLEN len;
    const char *s = SvPV(frozen, len), *end = s + len, *w, *nl;
    size_t wl;
    int gap, overlap, i, locale, is_day, neg;
    w = tkr_word(s, end, &wl);
    if (wl != 5 || memcmp(w, "tkrs1", 5) != 0)
        croak("%s: not a frozen Time::Keeper::Recurrence::Set", what);
    w = tkr_word(w + wl, end, &wl);
    for (i = 0; i < 4; i++) if (strlen(tkr_gap_names[i]) == wl && memcmp(w, tkr_gap_names[i], wl) == 0) break;
    if (i == 4) croak("%s: a damaged frozen set", what);
    gap = i;
    w = tkr_word(w + wl, end, &wl);
    for (i = 0; i < 3; i++) if (strlen(tkr_overlap_names[i]) == wl && memcmp(w, tkr_overlap_names[i], wl) == 0) break;
    if (i == 3) croak("%s: a damaged frozen set", what);
    overlap = i;
    w = tkr_word(w + wl, end, &wl);
    locale = tkr_locale_of_code(aTHX_ w, wl);
    w = tkr_word(w + wl, end, &wl);
    is_day = tkr_num(w, wl, 0, &neg) == 1;
    nl = w + wl;
    while (nl < end && *nl != '\n') nl++;
    tkr_ical_parse(aTHX_ nl, (size_t)(end - nl), p, what);
    p->gap = gap;
    p->overlap = overlap;
    p->locale = locale;
    p->start_is_day = is_day;
    for (i = 0; i < (int)(p->n_rules + p->n_exrules); i++) {
        p->rules[i].gap = (uint8_t)gap;
        p->rules[i].overlap = (uint8_t)overlap;
    }
}

#endif
