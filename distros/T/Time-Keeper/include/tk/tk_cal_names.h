#ifndef TK_CAL_NAMES_H
#define TK_CAL_NAMES_H

/* The calendars' names and formats: CLDR's month and era names, the
 * Chinese leap-month patterns and cyclic year names, and the date formats,
 * for a locale in a calendar other than the Gregorian. und and en are
 * compiled in (tk_cal_en.h); every other locale is read from
 * share/calendars.tkd, which holds for each (locale, calendar) only what
 * differs from the parent locale's set, the parents ending at und. A name
 * that equals the locale's Gregorian one is not stored at all: a NULL slot
 * means the Gregorian set's. A set is resolved once a process and kept, as
 * locales are. */

#include "tk/tk_cal_en.h"

typedef struct tk_cal_names {
    const char **slot;              /* TK_CN_FIXED + 3 * n_eras */
    unsigned     n_slots;
    tk_pair     *skeletons;         /* sorted by key */
    unsigned     n_skeletons;
} tk_cal_names;

typedef struct tk_cn_entry {
    const tk_locale_data *loc;
    int cal;
    tk_cal_names *names;
} tk_cn_entry;

static tk_cn_entry *tk_cn_cache = NULL;
static unsigned tk_cn_count = 0, tk_cn_room = 0;
static char *tk_cn_path = NULL;
static unsigned char *tk_cn_index = NULL;      /* the archive's index and parent table, kept */
static uint32_t tk_cn_sections = 0, tk_cn_parents = 0;

/* The calendar whose names a calendar uses: the Hijri variants share islamic's. */
static int
tk_cn_names_cal(int cal)
{
    unsigned k;
    for (k = 0; k < sizeof tk_cal_names_alias / sizeof tk_cal_names_alias[0]; k++)
        if (strEQ(tk_cal_names_alias[k][0], tk_calendars[cal].id)) {
            int a = tk_cal_find(tk_cal_names_alias[k][1], strlen(tk_cal_names_alias[k][1]));
            return a < 0 ? cal : a;
        }
    return cal;
}

static uint32_t
tk_cn_fnv(const char *s, size_t len)
{
    uint32_t h = 0x811c9dc5u;
    size_t i;
    for (i = 0; i < len; i++) {
        h ^= (unsigned char)s[i];
        h *= 0x01000193u;
    }
    return h;
}

static uint32_t tk_cn_u32(const unsigned char *p) { return (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24); }
static unsigned tk_cn_u16(const unsigned char *p) { return (unsigned)p[0] | ((unsigned)p[1] << 8); }

/* The file, found beside locales.tkd. Called with the lock held. */
static void
tk_cn_open(pTHX)
{
    PerlIO *f;
    unsigned char head[32];
    size_t len;
    if (tk_cn_index)
        return;
    if (!tk_locale_path)
        tk_locale_path = tk_locale_file(aTHX);
    if (!tk_locale_path) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: cannot find its locale data, Time/Keeper/locales.tkd, in @INC");
    }
    {
        size_t l = strlen(tk_locale_path);
        Newx(tk_cn_path, l + 4, char);
        memcpy(tk_cn_path, tk_locale_path, l + 1);
        /* .../locales.tkd -> .../calendars.tkd */
        strcpy(tk_cn_path + l - 11, "calendars.tkd");
    }
    f = PerlIO_open(tk_cn_path, "rb");
    if (!f) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: cannot open %s: %s", tk_cn_path, Strerror(errno));
    }
    if (PerlIO_read(f, head, 32) != 32 || memNE(head, "TKC1", 4)) {
        PerlIO_close(f);
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: %s is not its calendar names", tk_cn_path);
    }
    tk_cn_sections = tk_cn_u32(head + 4);
    if (tk_cn_u32(head + 8) != TK_CAL_NAMES_STAMP) {
        PerlIO_close(f);
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: %s is from a different build of Time::Keeper", tk_cn_path);
    }
    tk_cn_parents = tk_cn_u32(head + 28);
    len = 12 * (size_t)tk_cn_sections + 32 * (size_t)tk_cn_parents;
    Newx(tk_cn_index, len + 1, unsigned char);
    if ((size_t)PerlIO_read(f, tk_cn_index, len) != len) {
        PerlIO_close(f);
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: %s is cut short", tk_cn_path);
    }
    PerlIO_close(f);
}

/* The parent code of a code, from the archive's table; "" for und. */
static const char *
tk_cn_parent(const char *code)
{
    const unsigned char *t = tk_cn_index + 12 * (size_t)tk_cn_sections;
    uint32_t lo = 0, hi = tk_cn_parents;
    while (lo < hi) {
        uint32_t mid = (lo + hi) / 2;
        int c = strcmp((const char *)t + 32 * mid, code);
        if (c == 0)
            return (const char *)t + 32 * mid + 16;
        if (c < 0) lo = mid + 1; else hi = mid;
    }
    return NULL;
}

/* One section's bytes, or NULL when the (code, calendar) has none. Called with the lock held. */
static unsigned char *
tk_cn_section(pTHX_ const char *code, const char *cal, size_t *len)
{
    char key[64];
    size_t klen = strlen(code);
    uint32_t h, lo = 0, hi = tk_cn_sections;
    if (klen + strlen(cal) + 1 >= sizeof key)
        return NULL;
    memcpy(key, code, klen);
    key[klen] = '\0';
    strcpy(key + klen + 1, cal);
    h = tk_cn_fnv(key, klen + 1 + strlen(cal));
    while (lo < hi) {
        uint32_t mid = (lo + hi) / 2, mh = tk_cn_u32(tk_cn_index + 12 * mid);
        if (mh == h) {
            uint32_t off = tk_cn_u32(tk_cn_index + 12 * mid + 4), n = tk_cn_u32(tk_cn_index + 12 * mid + 8);
            unsigned char *buf;
            PerlIO *f = PerlIO_open(tk_cn_path, "rb");
            if (!f) {
                TK_LOCALE_UNLOCK;
                croak("Time::Keeper: cannot open %s: %s", tk_cn_path, Strerror(errno));
            }
            Newx(buf, n + 1, unsigned char);
            if (PerlIO_seek(f, (Off_t)off, SEEK_SET) < 0 || (size_t)PerlIO_read(f, buf, n) != n) {
                PerlIO_close(f);
                Safefree(buf);
                TK_LOCALE_UNLOCK;
                croak("Time::Keeper: %s is cut short", tk_cn_path);
            }
            PerlIO_close(f);
            buf[n] = 0;
            *len = n;
            return buf;
        }
        if (mh < h) lo = mid + 1; else hi = mid;
    }
    return NULL;
}

static int
tk_cn_pair_cmp(const void *a, const void *b)
{
    return strcmp(((const tk_pair *)a)->key, ((const tk_pair *)b)->key);
}

/* A section applied over a set: a slot's pool offset, or 0xFFFE for NULL. */
static void
tk_cn_apply(pTHX_ tk_cal_names *n, const unsigned char *b, size_t len)
{
    unsigned npairs, nskel, k;
    const unsigned char *pool;
    size_t pool_len;
    if (len < 8 || memNE(b, "TKS1", 4)) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: a calendar names section is damaged");
    }
    npairs = tk_cn_u16(b + 4);
    nskel = tk_cn_u16(b + 6);
    pool = b + 8 + 4 * (size_t)npairs + 4 * (size_t)nskel;
    if ((size_t)(pool - b) > len) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: a calendar names section is cut short");
    }
    pool_len = len - (size_t)(pool - b);
    for (k = 0; k < npairs; k++) {
        unsigned slot = tk_cn_u16(b + 8 + 4 * k), off = tk_cn_u16(b + 10 + 4 * k);
        if (slot >= n->n_slots || (off != 0xFFFE && off >= pool_len)) {
            TK_LOCALE_UNLOCK;
            croak("Time::Keeper: a calendar names section is damaged");
        }
        n->slot[slot] = off == 0xFFFE ? NULL : savepv((const char *)pool + off);
    }
    for (k = 0; k < nskel; k++) {
        unsigned koff = tk_cn_u16(b + 8 + 4 * npairs + 4 * k), voff = tk_cn_u16(b + 10 + 4 * npairs + 4 * k);
        const char *key;
        unsigned i;
        if (koff >= pool_len || (voff != 0xFFFE && voff >= pool_len)) {
            TK_LOCALE_UNLOCK;
            croak("Time::Keeper: a calendar names section is damaged");
        }
        key = (const char *)pool + koff;
        for (i = 0; i < n->n_skeletons; i++)
            if (strEQ(n->skeletons[i].key, key))
                break;
        if (voff == 0xFFFE) {
            if (i < n->n_skeletons) {
                n->skeletons[i] = n->skeletons[n->n_skeletons - 1];
                n->n_skeletons--;
            }
            continue;
        }
        if (i == n->n_skeletons) {
            Renew(n->skeletons, n->n_skeletons + 1, tk_pair);
            n->skeletons[i].key = savepv(key);
            n->n_skeletons++;
        }
        n->skeletons[i].value = savepv((const char *)pool + voff);
    }
}

/* The compiled set for und or en, or NULL. */
static const tk_cn_builtin *
tk_cn_builtin_for(const char *code, const char *cal)
{
    unsigned k;
    for (k = 0; k < sizeof tk_cn_builtins / sizeof tk_cn_builtins[0]; k++)
        if (strEQ(tk_cn_builtins[k].code, code) && strEQ(tk_cn_builtins[k].calendar, cal))
            return &tk_cn_builtins[k];
    return NULL;
}

/* The set for a code, resolved down the chain. Called with the lock held. */
static void
tk_cn_resolve(pTHX_ tk_cal_names *n, const char *code, const char *cal, int depth)
{
    const tk_cn_builtin *bi = tk_cn_builtin_for(code, cal);
    if (depth > 8) {
        TK_LOCALE_UNLOCK;
        croak("Time::Keeper: the locale %s's parents loop", code);
    }
    if (bi) {
        unsigned k;
        /* resolved already: the whole set */
        for (k = 0; k < n->n_slots && k < bi->n_slots; k++)
            n->slot[k] = bi->slots[k];
        n->n_skeletons = 0;
        if (bi->n_skeletons) {
            Renew(n->skeletons, bi->n_skeletons, tk_pair);
            for (k = 0; k < bi->n_skeletons; k++)
                n->skeletons[k] = bi->skeletons[k];
            n->n_skeletons = bi->n_skeletons;
        }
        return;
    }
    {
        const char *parent;
        unsigned char *b;
        size_t len;
        char cut[32];
        tk_cn_open(aTHX);
        parent = tk_cn_parent(code);
        if (!parent) {
            /* a code the table lists no parent for inherits by truncation,
               as CLDR's does: ca-ES-valencia's parent ca-ES, then ca */
            const char *dash = strrchr(code, '-');
            if (!dash || (size_t)(dash - code) >= sizeof cut) {
                TK_LOCALE_UNLOCK;
                croak("Time::Keeper: the locale %s has no calendar names", code);
            }
            memcpy(cut, code, (size_t)(dash - code));
            cut[dash - code] = '\0';
            parent = cut;
        }
        if (*parent)
            tk_cn_resolve(aTHX_ n, parent, cal, depth + 1);
        else
            tk_cn_resolve(aTHX_ n, "und", cal, depth + 1);
        b = tk_cn_section(aTHX_ code, cal, &len);
        if (b) {
            tk_cn_apply(aTHX_ n, b, len);
            Safefree(b);
        }
    }
}

static const tk_cal_names *
tk_cal_names_get(pTHX_ const tk_locale_data *loc, int cal)
{
    unsigned k;
    tk_cal_names *n;
    const tk_calendar *c;
    cal = tk_cn_names_cal(cal);
    c = &tk_calendars[cal];
    TK_LOCALE_LOCK;
    for (k = 0; k < tk_cn_count; k++)
        if (tk_cn_cache[k].loc == loc && tk_cn_cache[k].cal == cal) {
            n = tk_cn_cache[k].names;
            TK_LOCALE_UNLOCK;
            return n;
        }
    Newxz(n, 1, tk_cal_names);
    n->n_slots = TK_CN_FIXED + 3 * c->n_eras;
    Newxz(n->slot, n->n_slots, const char *);
    n->skeletons = NULL;
    n->n_skeletons = 0;
    tk_cn_resolve(aTHX_ n, loc->id, c->id, 0);
    if (n->n_skeletons > 1)
        qsort(n->skeletons, n->n_skeletons, sizeof(tk_pair), tk_cn_pair_cmp);
    if (tk_cn_count == tk_cn_room) {
        tk_cn_room = tk_cn_room ? tk_cn_room * 2 : 16;
        Renew(tk_cn_cache, tk_cn_room, tk_cn_entry);
    }
    tk_cn_cache[tk_cn_count].loc = loc;
    tk_cn_cache[tk_cn_count].cal = cal;
    tk_cn_cache[tk_cn_count].names = n;
    tk_cn_count++;
    TK_LOCALE_UNLOCK;
    return n;
}

/* ---- what the formatter asks ------------------------------------------- */

/* CLDR's slot of the month: the Hebrew Nisan is 8 in every year. */
static unsigned
tk_cal_month_slot(const tk_calendar *cal, const tk_calfields *f)
{
    if (cal == &tk_calendars[TK_CAL_HEBREW])
        return f->leap_year || f->month <= 5 ? f->month : f->month + 1;
    if (cal == &tk_calendars[TK_CAL_CHINESE] || cal == &tk_calendars[TK_CAL_DANGI])
        return f->month_number;
    return f->month;
}

/* The number a numeric M or L writes: the ordinal month, as ICU writes
 * it (the Hebrew Iyar is 8 in a common year and 9 in a leap year), save
 * that the Chinese calendars write the number in the month code, the leap
 * month wrapped in the leap pattern by the caller. */
static unsigned
tk_cal_month_numeric(const tk_calendar *cal, const tk_calfields *f)
{
    if (cal == &tk_calendars[TK_CAL_CHINESE] || cal == &tk_calendars[TK_CAL_DANGI])
        return f->month_number;
    return f->month;
}

/* A month's name in the calendar, or the Gregorian set's where the calendar
 * has none of its own. The Hebrew slot 7 is Adar II in a leap year. */
static const char *
tk_cal_month_name(const tk_cal_names *n, const tk_locale_data *loc, const tk_calendar *cal, const tk_calfields *f, int ctx, int w)
{
    unsigned slot = tk_cal_month_slot(cal, f);
    const char *s = NULL;
    if (cal == &tk_calendars[TK_CAL_HEBREW] && f->leap_year && slot == 7)
        s = n->slot[TK_CN_MONTHS_LEAP + ctx * 3 + w];
    if (!s)
        s = n->slot[TK_CN_MONTHS + (ctx * 3 + w) * 13 + slot - 1];
    if (!s && slot <= 12)
        s = loc->s.months[ctx][w][slot - 1];
    return s ? s : "";
}

static const char *
tk_cal_era_name(const tk_cal_names *n, const tk_calendar *cal, unsigned era, int w)
{
    const char *s = era < cal->n_eras ? n->slot[TK_CN_FIXED + w * cal->n_eras + era] : NULL;
    /* a calendar whose eras CLDR does not name (the Chinese) writes nothing */
    return s ? s : "";
}

/* The leap pattern ("{0}bis", "閏{0}") of the Chinese calendars, or NULL. */
static const char *
tk_cal_leap_pattern(const tk_cal_names *n, int ctx, int w, int numeric)
{
    const char *s = numeric ? n->slot[TK_CN_LEAP_NUMERIC] : n->slot[TK_CN_LEAP_PATTERN + ctx * 3 + w];
    if (!s && !numeric)
        s = n->slot[TK_CN_LEAP_NUMERIC];
    return s;
}

static const char *
tk_cal_cyclic_name(const tk_cal_names *n, int cycle, int w)
{
    const char *s = n->slot[TK_CN_CYCLIC + w * 60 + cycle - 1];
    return s ? s : "";
}

static const char *
tk_cal_date_format(const tk_cal_names *n, const tk_locale_data *loc, int len, int datetime)
{
    const char *s = n->slot[(datetime ? TK_CN_DATETIME_FORMATS : TK_CN_DATE_FORMATS) + len];
    return s ? s : datetime ? loc->s.datetime_formats[len] : loc->s.date_formats[len];
}

/* One sorted skeleton table searched. */
static const char *
tk_skel_find(const tk_pair *t, unsigned count, const char *skel)
{
    int lo = 0, hi = (int)count - 1;
    while (lo <= hi) {
        int mid = lo + (hi - lo) / 2;
        int c = strcmp(t[mid].key, skel);
        if (c == 0)
            return t[mid].value;
        if (c < 0) lo = mid + 1; else hi = mid - 1;
    }
    return NULL;
}

/* The skeleton's pattern in the calendar, else the Gregorian's, else NULL.
 * The calendars key their year skeletons as yyyy and ICU matches a y to
 * them, so a skeleton with a shorter y is tried that way too. */
static const char *
tk_cal_skeleton_pattern(const tk_cal_names *n, const tk_locale_data *loc, const char *skel)
{
    const char *s = tk_skel_find(n->skeletons, n->n_skeletons, skel);
    if (!s) {
        const char *y = strchr(skel, 'y');
        STRLEN len = strlen(skel);
        if (y && len + 4 < 32 && !(y[1] == 'y' && y[2] == 'y' && y[3] == 'y')) {
            char wide[32];
            const char *e = y;
            STRLEN pre = (STRLEN)(y - skel);
            while (*e == 'y')
                e++;
            memcpy(wide, skel, pre);
            memcpy(wide + pre, "yyyy", 4);
            strcpy(wide + pre + 4, e);
            s = tk_skel_find(n->skeletons, n->n_skeletons, wide);
        }
    }
    if (!s)
        s = tk_skel_find(loc->skeletons, loc->n_skeletons, skel);
    return s;
}


#endif
