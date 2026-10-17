#ifndef TK_ARGS_H
#define TK_ARGS_H

/* Named arguments, as the constructors and `with` take them. Each method
 * says which keys it allows; any other key, or a key given twice, croaks
 * by name. */

enum {
    TK_A_YEAR, TK_A_MONTH, TK_A_DAY, TK_A_HOUR, TK_A_MINUTE, TK_A_SECOND,
    TK_A_NANOSECOND, TK_A_ZONE, TK_A_GAP, TK_A_OVERLAP, TK_A_DAY_OF_YEAR,
    TK_A_WEEK, TK_A_LOCALE, TK_A_COUNT
};

static const char *const tk_arg_names[TK_A_COUNT] = {
    "year", "month", "day", "hour", "minute", "second",
    "nanosecond", "zone", "gap", "overlap", "day_of_year", "week", "locale"
};

#define TK_A(bit) (1u << (bit))
#define TK_A_TIME (TK_A(TK_A_HOUR) | TK_A(TK_A_MINUTE) | TK_A(TK_A_SECOND) | TK_A(TK_A_NANOSECOND))
#define TK_A_RESOLVE (TK_A(TK_A_ZONE) | TK_A(TK_A_GAP) | TK_A(TK_A_OVERLAP))

/* The locale asked for, or English. */
#define tk_args_locale(a, what) ((a)->v[TK_A_LOCALE] ? tk_locale_id_from_sv(aTHX_ (a)->v[TK_A_LOCALE], what) : 0)

typedef struct tk_args {
    SV *v[TK_A_COUNT];
} tk_args;

static void
tk_args_parse(pTHX_ SV **st, I32 n, unsigned allowed, tk_args *a, const char *what)
{
    I32 i;
    Zero(a, 1, tk_args);
    if (n % 2)
        croak("%s: arguments come in name => value pairs", what);
    for (i = 0; i < n; i += 2) {
        STRLEN len;
        const char *k = SvPV(st[i], len);
        int j, found = -1;
        for (j = 0; j < TK_A_COUNT; j++)
            if (strlen(tk_arg_names[j]) == len && memEQ(k, tk_arg_names[j], len)) {
                found = j;
                break;
            }
        if (found < 0 || !(allowed & TK_A(found)))
            croak("%s: unknown argument '%s'", what, k);
        if (a->v[found])
            croak("%s: %s given twice", what, k);
        a->v[found] = st[i + 1];
    }
}

static int64_t
tk_args_int(pTHX_ const tk_args *a, int which, int64_t dflt, int64_t lo, int64_t hi, const char *what)
{
    if (!a->v[which])
        return dflt;
    return tk_opt_int(aTHX_ a->v[which], what, tk_arg_names[which], lo, hi);
}

/* The time of day from the arguments; second may be 60 (a leap second). */
static void
tk_args_time(pTHX_ const tk_args *a, int64_t *h, int64_t *mi, int64_t *s, int32_t *ns, const char *what)
{
    *h  = tk_args_int(aTHX_ a, TK_A_HOUR, 0, 0, 23, what);
    *mi = tk_args_int(aTHX_ a, TK_A_MINUTE, 0, 0, 59, what);
    *s  = tk_args_int(aTHX_ a, TK_A_SECOND, 0, 0, 60, what);
    *ns = (int32_t)tk_args_int(aTHX_ a, TK_A_NANOSECOND, 0, 0, TK_NSECS_PER_SEC - 1, what);
}

static void
tk_args_resolve(pTHX_ const tk_args *a, tk_zone_spec *z, int *gap, int *overlap, const char *what)
{
    tk_zone_spec_from_sv(aTHX_ a->v[TK_A_ZONE], z, what);
    *gap = a->v[TK_A_GAP] ? tk_opt_gap(aTHX_ a->v[TK_A_GAP], what) : TK_GAP_DEFAULT;
    *overlap = a->v[TK_A_OVERLAP] ? tk_opt_overlap(aTHX_ a->v[TK_A_OVERLAP], what) : TK_OVERLAP_DEFAULT;
}

#endif
