#ifndef TKZ_TYPES_H
#define TKZ_TYPES_H

/* The shapes of the tables tools/tzcompile writes into tkz_data.h.
 *
 * A zone is a run of transitions (seconds since 1970 UTC, ascending) and
 * the local time type each one starts. Before the first transition the
 * zone is in its initial type. After the last, its footer (a POSIX TZ
 * string, parsed) says what happens, or with no footer the last type
 * holds for ever.
 *
 * Types, abbreviations and footers are shared between zones. */

typedef struct tkz_type {
    int32_t  utoff;      /* seconds east of UTC */
    uint8_t  isdst;
    uint16_t abbr;       /* offset into tkz_abbrs */
} tkz_type;

enum {
    TKZ_RULE_NONE   = 0,
    TKZ_RULE_MONTH  = 1, /* Mm.w.d: day d (0 = Sunday) of week w (5 = last) of month m */
    TKZ_RULE_JULIAN = 2, /* Jn: day n of 1 .. 365, 29 February never counted */
    TKZ_RULE_DAY    = 3  /* n: day n of 0 .. 365, 29 February counted */
};

typedef struct tkz_rule {
    uint8_t  kind;
    uint8_t  month;
    uint8_t  week;
    uint8_t  wday;
    uint16_t day;
    int32_t  time;       /* seconds after local midnight, may be negative or past 24h */
} tkz_rule;

typedef struct tkz_footer {
    uint16_t text;       /* offset into tkz_footer_text: the TZ string itself */
    int32_t  std_utoff;  /* seconds east of UTC */
    int32_t  dst_utoff;  /* equal to std_utoff when there is no daylight time */
    uint16_t std_type;   /* the tkz_types entry for each */
    uint16_t dst_type;   /* 0xFFFF when there is no daylight time */
    tkz_rule start;      /* daylight time starts, in standard local time */
    tkz_rule end;        /* and ends, in daylight local time */
} tkz_footer;

#define TKZ_NO_FOOTER 0xFFFF

typedef struct tkz_zone {
    uint32_t name;       /* offset into tkz_names */
    uint32_t first_trans;
    uint32_t n_trans;
    uint16_t initial_type;
    uint16_t footer;     /* index into tkz_footers, or TKZ_NO_FOOTER */
} tkz_zone;

/* Every name, zones and links together, sorted case-blind. */
typedef struct tkz_lookup_entry {
    uint32_t name;
    uint16_t zone;
    uint8_t  is_link;
} tkz_lookup_entry;

typedef struct tkz_windows_entry {
    uint32_t name;       /* offset into tkz_windows_names */
    uint16_t zone;
} tkz_windows_entry;

/* A country, from iso3166.tab, and the zones zone.tab gives it: a run of
 * tkz_country_zones, each a tkz_lookup index. */
typedef struct tkz_country {
    char     code[3];
    uint32_t name;       /* offset into tkz_country_names */
    uint16_t first;
    uint16_t n;
} tkz_country;

/* tkz_lookup_country[] holds, for every name, the tkz_countries index of
 * the country zone.tab gives it; a link zone.tab does not list takes its
 * zone's. tkz_zone_windows[] holds, for every zone, the tkz_windows index
 * of its Windows name. */
#define TKZ_NO_COUNTRY 0xFF
#define TKZ_NO_WINDOWS 0xFFFF

#endif
