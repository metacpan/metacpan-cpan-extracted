#ifndef TK_LOCALE_H
#define TK_LOCALE_H

/* A locale's calendar names, formats and zone names, as CLDR has them.
 * English is compiled in (tk_locale_en.h); every other locale is a section
 * of share/locales.tkd, read the first time it is used (tk_locale_load.h).
 * Strings are UTF-8.
 *
 * Context 0 is the format form (inside a date: "15 October"), 1 the
 * stand-alone form (alone: "October"). Width 0 is wide ("October"), 1
 * abbreviated ("Oct"), 2 narrow ("O"); days have a fourth, short ("Tu").
 * Days run Monday to Sunday, as ISO numbers them. */

enum { TK_CTX_FORMAT, TK_CTX_STANDALONE, TK_CTX_COUNT };
enum { TK_W_WIDE, TK_W_ABBR, TK_W_NARROW, TK_W_COUNT };
#define TK_W_SHORT 3
enum { TK_LEN_FULL, TK_LEN_LONG, TK_LEN_MEDIUM, TK_LEN_SHORT, TK_LEN_COUNT };

/* Day periods: am and pm, then CLDR's named periods for b and B. */
enum {
    TK_DP_AM, TK_DP_PM, TK_DP_MIDNIGHT, TK_DP_NOON, TK_DP_MORNING1, TK_DP_MORNING2,
    TK_DP_AFTERNOON1, TK_DP_AFTERNOON2, TK_DP_EVENING1, TK_DP_EVENING2, TK_DP_NIGHT1,
    TK_DP_NIGHT2, TK_DP_COUNT
};

/* The zone formats: "+HH:mm;-HH:mm", "GMT{0}", "GMT", "{0} Time",
 * "{0} Daylight Time", "{0} Standard Time", "{1} ({0})". */
enum {
    TK_ZF_HOUR, TK_ZF_GMT, TK_ZF_GMT_ZERO, TK_ZF_REGION, TK_ZF_REGION_DAYLIGHT,
    TK_ZF_REGION_STANDARD, TK_ZF_FALLBACK, TK_ZF_COUNT
};

/* A zone's or metazone's names: long, then short, each generic, standard
 * and daylight; then a zone's exemplar city. */
enum {
    TK_ZN_LONG_GENERIC, TK_ZN_LONG_STANDARD, TK_ZN_LONG_DAYLIGHT,
    TK_ZN_SHORT_GENERIC, TK_ZN_SHORT_STANDARD, TK_ZN_SHORT_DAYLIGHT,
    TK_ZN_CITY, TK_ZN_COUNT
};

/* Every slot of this struct is a string, in the order tools/cldrcompile
 * writes them, so a section fills it as one array. */
typedef struct tk_locale_strings {
    const char *months[TK_CTX_COUNT][TK_W_COUNT][12];
    const char *days[TK_CTX_COUNT][TK_W_COUNT + 1][7];
    const char *quarters[TK_CTX_COUNT][TK_W_COUNT][4];
    const char *eras[TK_W_COUNT][2];          /* 0 before Christ, 1 after */
    const char *periods[TK_W_COUNT][TK_DP_COUNT];
    const char *date_formats[TK_LEN_COUNT];
    const char *time_formats[TK_LEN_COUNT];
    const char *datetime_formats[TK_LEN_COUNT];  /* {1} the date, {0} the time */
    const char *zone_formats[TK_ZF_COUNT];
    const char *digits[10];
} tk_locale_strings;

#define TK_LOCALE_SLOTS (sizeof(tk_locale_strings) / sizeof(const char *))

typedef struct tk_pair {
    const char *key;
    const char *value;
} tk_pair;

typedef struct tk_zone_names {
    uint16_t    id;                   /* into tk_cldr_zones or tk_metazones */
    const char *s[TK_ZN_COUNT];
} tk_zone_names;

typedef struct tk_terr_name {
    uint16_t    id;                   /* into tk_territories */
    const char *name;
} tk_terr_name;

typedef struct tk_period_rule {
    uint8_t  period;
    uint16_t from, before;            /* minutes of the day; equal for "at" */
} tk_period_rule;

typedef struct tk_locale_data {
    const char        *id;
    tk_locale_strings  s;
    uint8_t            first_day;     /* 1 Monday .. 7 Sunday */
    uint8_t            min_days;      /* in the first week of a year */
    uint8_t            hour_cycle_24; /* the locale writes 24-hour times */
    uint8_t            ascii_digits;
    uint16_t           n_skeletons, n_zones, n_metazones, n_territories, n_rules;
    const tk_pair        *skeletons;  /* sorted by key */
    const tk_zone_names  *zones;      /* sorted by id */
    const tk_zone_names  *metazones;  /* sorted by id */
    const tk_terr_name   *territories;/* sorted by id */
    const tk_period_rule *rules;
} tk_locale_data;

/* The tables tools/cldrcompile writes into tk_locale_table.h. */
typedef struct tk_locale_code {
    const char *code;
    uint16_t    blob;
    const char *name;                 /* in English */
    const char *native;               /* in itself */
    const char *parts[12];            /* language, script, territory, variant codes; their
                                         names in English; their names in itself */
} tk_locale_code;

typedef struct tk_locale_alias {
    const char *key;
    uint16_t    id;
} tk_locale_alias;

typedef struct tk_cldr_zone {
    const char *name;
    const char *iana;                 /* the name IANA gives it now */
    const char *bcp47;
    int16_t     territory;            /* into tk_territories, or -1 */
    uint8_t     only;                 /* the only zone of its territory, or its primary one */
    uint16_t    mz_first, mz_count;   /* into tk_mz_periods */
} tk_cldr_zone;

typedef struct tk_mz_period {
    uint16_t mz;
    int64_t  from, to;                /* UTC seconds, [from, to) */
} tk_mz_period;

#endif
