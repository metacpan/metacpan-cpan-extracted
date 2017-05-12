/* -*- c -*- */

#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Support older versions of perl. */
#ifndef Newxz
#define Newxz(ptr, n, type) Newz(704, ptr, n, type)
#endif

struct trie {
    U16 bits;
    U16 has_unicode;
};

typedef struct trie *Text__Match__FastAlternatives;

struct pool {
    void *buf;
    void *curr;
};

static struct pool pool_create(size_t n) {
    struct pool pool;
    Newxz(pool.buf, n, char);
    pool.curr = pool.buf;
    return pool;
}

static void *pool_alloc(struct pool *pool, size_t n) {
    unsigned char *region = pool->curr;
    /* Ensure every allocation is on an even boundary, thus freeing up the
     * low-order bit of a pseudo-pointer for other purposes, even when each
     * pseudo-pointer is only 8 bits */
    if ((n & 1u))
        n++;
    pool->curr = region + n;
    return region;
}

static size_t pool_offset(const struct pool *pool, void *obj) {
    return ((U8 *)obj) - ((U8 *)pool->buf);
}

static int
array_has_unicode(pTHX_ AV *keywords) {
    I32 i, n = av_len(keywords);
    for (i = 0;  i <= n;  i++) {
        SV *sv = *av_fetch(keywords, i, 0);
        STRLEN len;
        char *s = SvPV(sv, len);
        const U8 *p = (const U8 *) s, *end = p + len;
        while (p < end)
            if (*p++ & 0x80u)
                return 1;
    }
    return 0;
}

#if PTRSIZE >= 8
#define BITS 64
#include "trie.c"
#endif

#define BITS 32
#include "trie.c"

#define BITS 16
#include "trie.c"

#define BITS 8
#include "trie.c"

#define NM_(x, y) x ## _ ## y
#define NM(name, bits) NM_(name, bits)
#if PTRSIZE >= 8
#define CALL(trie, name, arglist) \
    ( ((trie)->bits ==  8 ? (NM(name,  8)arglist) \
    : ((trie)->bits == 16 ? (NM(name, 16)arglist) \
    : ((trie)->bits == 32 ? (NM(name, 32)arglist) \
    :                       (NM(name, 64)arglist)))))
#else
#define CALL(trie, name, arglist) \
    ( ((trie)->bits ==  8 ? (NM(name,  8)arglist) \
    : ((trie)->bits == 16 ? (NM(name, 16)arglist) \
    :                       (NM(name, 32)arglist))))
#endif

static int utf8_valid(const U8 *s, STRLEN len) {
    static const U8 width[] = { /* start at 0xC2 */
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,     /* 0xC2 .. 0xCF; two bytes */
        2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, /* 0xD0 .. 0xDF; two bytes */
        3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3, /* 0xE0 .. 0xEF; three bytes */
        4,4,4,4,4,0,0,0,0,0,0,0,0,0,0,0, /* 0xF0 .. 0xF4; four bytes */
    };
    static const U8 mask[] = {  /* data bitmask for leading byte of N-byte unit */
        0u, 0u, 0x1Fu, 0x0Fu, 7u,
    };
    static const U32 min[] = {  /* lowest permissible value for an N-byte unit */
        0u, 0u, 0x80u, 0x800u, 0x10000u,
    };
    const U8 *p = s, *end = s + len;
    while (p < end) {
        if (*p < 0x80u)
            p++;                /* plain ASCII */
        else if (*p < 0xC2u)
            return 0;           /* 0x80 .. 0xC1 are impossible leading bytes */
        else {
            U8 w = width[*p - 0xC2u], i;
            U32 c;
            if (w == 0)
                return 0;       /* invalid leading byte */
            else if (end - p < w)
                return 0;       /* string too short for continuation bytes */
            c = *p & mask[w];
            for (i = 1;  i < w;  i++)
                if ((p[i] & 0xC0u) != 0x80u)
                    return 0;   /* continuation byte not in range */
                else
                    c = (c << 6u) | (p[i] & 0x3Fu);
            if (c < min[w])
                return 0;       /* sequence overlong */
            if (c >= 0xD800u && c < 0xE000u)
                return 0;       /* UTF-16 surrogate */
            p += w;
        }
    }

    return 1;
}

static int get_byte_offset(pTHX_ SV *sv, int pos) {
    STRLEN len;
    const unsigned char *s, *p;
    if (!SvUTF8(sv))
        return pos;
    s = (const unsigned char *) SvPV(sv, len);
    for (p = s;  pos > 0;  pos--) {
        /* Skip the sole byte (ASCII char) or leading byte (top >=2 bits set) */
        p++;
        /* Skip any continuation bytes (top bit set but not next bit) */
        while ((*p & 0xC0u) == 0x80u)
            p++;
    }
    return p - s;
}

/* If the trie used Unicode, make sure that the target string uses the same
 * encoding.  But if the trie didn't use Unicode, it doesn't matter what
 * encoding the target uses for any supra-ASCII characters it contains,
 * because they'll never be found in the trie.
 *
 * A pleasing performance enhancement would be as follows: delay upgrading a
 * byte-encoded SV until such time as we're actually looking at a
 * supra-ASCII character; then upgrade the SV, and start again from the
 * current offset in the string.  (Since by definition there are't any
 * supra-ASCII characters before the current offset, it's guaranteed to be
 * safe to use the old characters==bytes-style offset as a byte-oriented one
 * for the upgraded SV.)  It seems a little tricky to arrange that sort of
 * switcheroo, though; the inner loop is in a function that knows nothing of
 * SVs or encodings. */
#define GET_TARGET(trie, sv, len) \
    ((unsigned char *) (trie->has_unicode ? SvPVutf8(sv, len) : SvPV(sv, len)))

MODULE = Text::Match::FastAlternatives      PACKAGE = Text::Match::FastAlternatives

PROTOTYPES: DISABLE

Text::Match::FastAlternatives
new_instance(package, keywords)
    char *package
    AV *keywords
    PREINIT:
        struct trie *trie;
        HV *limits;
        HE *he;
        STRLEN maxlen = 0;
        I32 i, n, nodes;
        size_t dyn_ptrs = 0, odd_arrays = 0;
    CODE:
        /* Ensure all the arguments are acceptable */
        n = av_len(keywords);
        for (i = 0;  i <= n;  i++) {
            SV **sv = av_fetch(keywords, i, 0);
            char *s;
            STRLEN len;
            if (!sv || !SvOK(*sv))
                croak("Undefined element in %s->new", package);
            s = SvPVutf8(*sv, len);
            if (!utf8_valid((const U8 *) s, len))
                croak("Malformed or non-Unicode UTF-8 in %s->new", package);
            if (len > maxlen)
                maxlen = len;
        }

        /* For each possibly-improper prefix of each keyword, find the
         * minimum and maximum byte values for edges onwards from the node
         * which will represent that prefix.  The minimum and maximum are
         * encoded in a UV (min as the lowest-order byte, max as the next
         * byte up) and stored in a hash with the prefix as the key. */
        limits = newHV();
        for (i = 0;  i <= n;  i++) {
            STRLEN pos, len;
            SV *sv = *av_fetch(keywords, i, 0);
            char *s = SvPVutf8(sv, len);
            for (pos = 0;  pos <= len;  pos++) {
                U8 c = ((U8 *) s)[pos];
                SV *entry = *hv_fetch(limits, s, pos, 1);
                if (!SvIOK(entry)) /* sv_setuv() might give you an IOK-but-not-UOK sv */
                    sv_setuv(entry, (c << 8u) | c);
                else {
                    UV lim = SvUV(entry);
                    UV min = lim & 0xFFu, max = (lim & 0xFF00u) >> 8u;
                    if (c < min)
                        min = c;
                    else if (c > max)
                        max = c;
                    else        /* no change; don't bother doing sv_setuv() */
                        continue;
                    sv_setuv(entry, (max << 8u) | min);
                }
            }
        }

        /* Count nodes and dynamically-allocated pointers in limits */
        nodes = hv_iterinit(limits);
        while ((he = hv_iternext(limits))) {
            UV lim = SvUV(HeVAL(he));
            UV min = lim & 0xFFu, max = (lim & 0xFF00u) >> 8u;
            UV n = max - min;
            dyn_ptrs += n;
            /* For the 8-bit implementation, we'll need to allocate an extra
             * byte for every node that would otherwise be an odd number of
             * bytes long */
            if ((n & 1u))
                odd_arrays++;
        }

        /* Ensure we get a root node, even if there are no keywords */
        if (nodes == 0) {
            nodes++;
            hv_store(limits, "", 0, newSVuv(0u), 0);
        }

        /* Create the trie */
        if      (trie_data_fits_8( nodes, dyn_ptrs, odd_arrays))
            trie = trie_create_8( aTHX_ keywords, limits, maxlen, nodes, dyn_ptrs, odd_arrays);
        else if (trie_data_fits_16(nodes, dyn_ptrs, odd_arrays))
            trie = trie_create_16(aTHX_ keywords, limits, maxlen, nodes, dyn_ptrs, odd_arrays);
        else if (trie_data_fits_32(nodes, dyn_ptrs, odd_arrays))
            trie = trie_create_32(aTHX_ keywords, limits, maxlen, nodes, dyn_ptrs, odd_arrays);
#if PTRSIZE >= 8
        else if (trie_data_fits_64(nodes, dyn_ptrs, odd_arrays))
            trie = trie_create_64(aTHX_ keywords, limits, maxlen, nodes, dyn_ptrs, odd_arrays);
#endif

        SvREFCNT_dec(limits);

        if (!trie)
            croak("Sorry, too much data for %s", package);

        RETVAL = trie;
    OUTPUT:
        RETVAL

void
DESTROY(trie)
    Text::Match::FastAlternatives trie
    PREINIT:
        void *buf;
    CODE:
        buf = trie;
        Safefree(buf);

int
match(trie, targetsv)
    Text::Match::FastAlternatives trie
    SV *targetsv
    PREINIT:
        STRLEN target_len;
        const unsigned char *target;
    INIT:
        SvGETMAGIC(targetsv);
        if (!SvOK(targetsv))
            croak("Target is not a defined scalar");
    CODE:
        target = GET_TARGET(trie, targetsv, target_len);
        if (CALL(trie, trie_match,(trie, target, target_len)))
            XSRETURN_YES;
        XSRETURN_NO;

int
match_at(trie, targetsv, pos)
    Text::Match::FastAlternatives trie
    SV *targetsv
    int pos
    PREINIT:
        STRLEN target_len;
        const unsigned char *target;
    INIT:
        SvGETMAGIC(targetsv);
        if (!SvOK(targetsv))
            croak("Target is not a defined scalar");
    CODE:
        target = GET_TARGET(trie, targetsv, target_len);
        pos = get_byte_offset(aTHX_ targetsv, pos);
        if (pos <= (int) target_len) {
            target_len -= pos;
            target += pos;
            if (CALL(trie, trie_match_anchored,(trie, target, target_len)))
                XSRETURN_YES;
        }
        XSRETURN_NO;

int
exact_match(trie, targetsv)
    Text::Match::FastAlternatives trie
    SV *targetsv
    PREINIT:
        STRLEN target_len;
        const unsigned char *target;
    INIT:
        SvGETMAGIC(targetsv);
        if (!SvOK(targetsv))
            croak("Target is not a defined scalar");
    CODE:
        target = GET_TARGET(trie, targetsv, target_len);
        if (CALL(trie, trie_match_exact,(trie, target, target_len)))
            XSRETURN_YES;
        XSRETURN_NO;

int
pointer_length(trie)
    Text::Match::FastAlternatives trie
    CODE:
        /* This is not part of the public API; it merely exposes an
         * implementation detail for testing */
        RETVAL = trie->bits;
    OUTPUT:
        RETVAL

void
dump(trie)
    Text::Match::FastAlternatives trie
    CODE:
        CALL(trie, trie_dump,("", 0, trie, 0));

int
utf8_valid(package, sv)
    char *package
    SV *sv
    PREINIT:
        STRLEN len;
        char *s;
    CODE:
        /* This is not part of the public API; it merely exposes an
         * implementation detail for testing */
        s = SvPV(sv, len);
        RETVAL = utf8_valid(s, len);
    OUTPUT:
        RETVAL
