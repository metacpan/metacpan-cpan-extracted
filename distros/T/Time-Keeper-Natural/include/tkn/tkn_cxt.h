#ifndef TKN_CXT_H
#define TKN_CXT_H

/* What Time::Keeper::Natural keeps in C: Time::Keeper's table, which is the
 * same for every interpreter in the process (it is a constant in
 * Time::Keeper's shared object), and the per-interpreter caches, which a
 * new thread starts without (CLONE) since they hold its own Perl values. */

/* What perls before 5.14 (isSPACE_A, isDIGIT_A, isALPHA_A) and 5.10.0 (newSVpvn_flags,
 * 5.10.1's) lack; the dist's floor is 5.10.0. */
#ifndef isSPACE_A
#  define isSPACE_A(c) ((c) == ' ' || (c) == '\t' || (c) == '\n' || (c) == '\r' || (c) == '\f')
#endif
#ifndef isDIGIT_A
#  define isDIGIT_A(c) ((c) >= '0' && (c) <= '9')
#endif
#ifndef isALPHA_A
#  define isALPHA_A(c) (((c) >= 'a' && (c) <= 'z') || ((c) >= 'A' && (c) <= 'Z'))
#endif
#ifndef isPUNCT_A
#  define isPUNCT_A(c) ((c) >= 0x21 && (c) <= 0x7E && !isALNUM(c))
#endif
/* perl 5.42's UTF8_MAXBYTES_CASE calls MAX, which perl.h defines only for the core and
 * where the system headers do (not MinGW). */
#ifndef MAX
#  define MAX(a,b) ((a) > (b) ? (a) : (b))
#endif
#ifndef newSVpvn_flags
static SV *
tkn_newSVpvn_flags(pTHX_ const char *s, STRLEN len, U32 flags)
{
    SV *sv = newSVpvn(s, len);
    if (flags & SVf_UTF8)
        SvUTF8_on(sv);
    return (flags & SVs_TEMP) ? sv_2mortal(sv) : sv;
}
#  define newSVpvn_flags(s, len, flags) tkn_newSVpvn_flags(aTHX_ (s), (len), (flags))
#endif

/* av_make of n SVs; an empty array's AvARRAY is NULL, which a DEBUGGING perl's
 * av_make asserts against even when n is 0. */
#define tkn_av_copy(n, from) ((n) > 0 ? av_make((n), (from)) : newAV())

/* A character class through Perl's engine, with \p{Cn} added: a script newer
 * than the running perl's Unicode (Adlam before 5.26) is unassigned there,
 * and its letters are letters still. */
#define TKN_RX_LETTER "qr/[\\p{L}\\p{Cn}]/"
#define TKN_RX_WORD   "qr/[\\w\\p{Cn}]/"
#define TKN_RX_LNS    "qr/[\\p{L}\\p{N}\\p{Cn}\\s]/"

#define MY_CXT_KEY "Time::Keeper::Natural::_guts" XS_VERSION

typedef struct tkn_cache {
    HV *lexicons;       /* a locale's compiled words, by canonical code (Phase 04) */
    HV *words;          /* a locale's word table (Phase 05) */
    HV *numbers;        /* a locale's number words (Phase 05) */
    IV  generation;     /* bumped by CLONE, so a test can see a thread started empty */
    SV *re_letter;      /* qr/\p{L}/, compiled on first use (Phase 07) */
    SV *reasons;        /* the sixteen reasons' patterns, on first use (Phase 10) */
    HV *zone_abbrs;     /* every zone's tzdata abbreviations, on first use (0.02) */
    HV *zone_words;     /* a locale's zone names' first words, by code, on first use (0.02) */
    HV *known;          /* the words find takes as part of a mention, by code, on first use (0.04) */
    HV *memo;           /* CLDR facts a reader asks for on every read, by code (0.04) */
    int quiet;          /* find is reading: a reader that cannot read returns, not dies (0.04) */
} my_cxt_t;

START_MY_CXT

static const time_keeper_abi *TKN_TK = NULL;

#define TKN_ABI_NEED 3

/* Time::Keeper's table, version 3 or later, found once; a croak naming what
 * is needed when it is absent or older. */
static void
tkn_abi_resolve(pTHX)
{
    SV *sv, *err;
    const time_keeper_abi *t;
    if (TKN_TK)
        return;
    sv = eval_pv("require Time::Keeper; Time::Keeper::_abi_ptr()", 0);
    err = get_sv("@", 0);
    if (!sv || !SvOK(sv) || (err && SvTRUE(err)))
        croak("Time::Keeper::Natural needs Time::Keeper 0.07 or later: %" SVf, SVfARG(err ? err : &PL_sv_undef));
    t = INT2PTR(const time_keeper_abi *, SvUV(sv));
    if (!t || t->abi_version < TKN_ABI_NEED)
        croak("Time::Keeper::Natural needs Time::Keeper 0.07 or later (its C interface version %d, this needs %d)",
              t ? t->abi_version : 0, TKN_ABI_NEED);
    TKN_TK = t;
}

static void
tkn_cxt_init(pTHX_ my_cxt_t *cxt)
{
    cxt->lexicons = newHV();
    cxt->words = newHV();
    cxt->numbers = newHV();
    cxt->generation = 0;
    cxt->re_letter = NULL;
    cxt->reasons = NULL;
    cxt->zone_abbrs = NULL;
    cxt->zone_words = newHV();
    cxt->known = newHV();
    cxt->quiet = 0;
    cxt->memo = newHV();
}

#endif
