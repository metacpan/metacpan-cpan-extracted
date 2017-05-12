#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "nedtrie.h"

#define MAX_MAP_SIZE    0x2ffff
#define SFX_SIGNATURE   0x4c9da21d

#ifndef MAX_TRIE_SIZE
#define MAX_TRIE_SIZE   (1 << 19)
#endif

typedef struct {
    U32 length;
    U32 code_table[];
} SpeedyFx;
typedef SpeedyFx *Text__SpeedyFx;

typedef struct sfxaa_s sfxaa_t;
struct sfxaa_s {
    NEDTRIE_ENTRY(sfxaa_s) link;
    U32 key;
    U32 val;
};
typedef struct sfxaa_tree_s sfxaa_tree_t;
NEDTRIE_HEAD(sfxaa_tree_s, sfxaa_s);

U32 sfxaakeyfunct(const sfxaa_t *r) {
    return r->key;
}

NEDTRIE_GENERATE(static, sfxaa_tree_s, sfxaa_s, link, sfxaakeyfunct, NEDTRIE_NOBBLEONES(sfxaa_tree_s))

typedef struct {
    U32 signature;
    U32 count;
    sfxaa_tree_t root;
    sfxaa_t *last;
    sfxaa_t index[MAX_TRIE_SIZE];
} SpeedyFxResult;
typedef SpeedyFxResult *Text__SpeedyFx__Result;

SV *result_init () {
    SV *res;
    int count;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("Text::SpeedyFx::Result", 0)));
    PUTBACK;

    count = call_method("new", G_SCALAR);
    SPAGAIN;

    if (count != 1)
        croak("couldn't construct new Text::SpeedyFx::Result object");

    res = newSVsv(POPs);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return res;
}

SpeedyFxResult *result_addr (SV *self) {
    SV *hash;
    MAGIC *magic;
    SV *attr;
    SpeedyFxResult *pSpeedyFxResult = NULL;

    hash = SvRV(self);
    if (SvRMAGICAL((SV *) hash)) {
        if ((magic = mg_find((SV *) hash, PERL_MAGIC_tied)) != NULL) {
            attr = magic->mg_obj;
            if (SvROK(attr)) {
                pSpeedyFxResult = (SpeedyFxResult *) SvIV(SvRV(attr));
                if (pSpeedyFxResult->signature != SFX_SIGNATURE) {
                    pSpeedyFxResult = NULL;
                }
            }
        }
    }

    return pSpeedyFxResult;
}

#if PERL_VERSION >= 16
#define ChrCode(u, v, len) (U32) utf8_to_uvchr_buf(u, v, len);
#else
#define ChrCode(u, v, len) (U32) utf8_to_uvchr(u, len)
#endif

#define SetBit(a, b)    (((U8 *) a)[(b) >> 3] |= (1 << ((b) & 7)))
#define FastMin(x, y)   (y ^ ((x ^ y) & -(x < y)))

#define _SPEEDYFX_INIT                                                          \
    U32 code, c;                                                                \
    U32 wordhash = 0;                                                           \
    STRLEN len;                                                                 \
    U32 length = pSpeedyFx->length;                                             \
    U32 *code_table = pSpeedyFx->code_table;                                    \
    U8 *s, *se;                                                                 \
    s = (U8 *) SvPV(str, len);                                                  \
    se = s + len;

#define _WALK_LATIN1    c = *s++
#define _WALK_UTF8      c = ChrCode(s, se, &len); s += len

#define _SPEEDYFX(_STORE, _WALK, _LENGTH)                                       \
    STMT_START {                                                                \
        while (*s) {                                                            \
            _WALK;                                                              \
            if ((code = code_table[c % _LENGTH]) != 0)                          \
                wordhash = (wordhash >> 1) + code;                              \
            else if (wordhash) {                                                \
                _STORE;                                                         \
                wordhash = 0;                                                   \
            }                                                                   \
        }                                                                       \
        if (wordhash) {                                                         \
            _STORE;                                                             \
        }                                                                       \
    } STMT_END

#define _NEDTRIE_STORE                                                          \
    tmp.key = wordhash;                                                         \
    if ((p = NEDTRIE_FIND(sfxaa_tree_s, root, &tmp)) != 0)                      \
        p->val++;                                                               \
    else {                                                                      \
        if ((p = slot++) == end)                                                \
            croak("too many unique tokens in a single data chunk");             \
        p->key = wordhash;                                                      \
        p->val = 1;                                                             \
        NEDTRIE_INSERT(sfxaa_tree_s, root, p);                                  \
    }

MODULE = Text::SpeedyFx::Result PACKAGE = Text::SpeedyFx::Result

PROTOTYPES: ENABLE

SV *
new (package, ...)
    char *package;
PREINIT:
    SpeedyFxResult *pSpeedyFxResult;
    HV *thingy;
    HV *stash;
    SV *tie;
CODE:
    Newx(pSpeedyFxResult, 1, SpeedyFxResult);
    pSpeedyFxResult->signature = SFX_SIGNATURE;
    pSpeedyFxResult->count = 0;

    NEDTRIE_INIT(&(pSpeedyFxResult->root));

    thingy = newHV();
    tie = newRV_noinc(newSViv(PTR2IV(pSpeedyFxResult)));
    stash = gv_stashpv(package, GV_ADD);
    sv_bless(tie, stash);
    hv_magic(thingy, (GV *) tie, PERL_MAGIC_tied);
    sv_free(tie);

    RETVAL = newRV_noinc((SV *) thingy);
OUTPUT:
    RETVAL

void
FETCH (pSpeedyFxResult, key)
    Text::SpeedyFx::Result pSpeedyFxResult
    SV *key
INIT:
    sfxaa_t *p, tmp;
PPCODE:
    tmp.key = SvNV(key);
    if ((p = NEDTRIE_FIND(sfxaa_tree_s, &(pSpeedyFxResult->root), &tmp)) == 0) {
        XSRETURN_UNDEF;
    } else {
        ST(0) = sv_2mortal(newSVnv(p->val));
        XSRETURN(1);
    }

void
STORE (pSpeedyFxResult, key, value)
    Text::SpeedyFx::Result pSpeedyFxResult
    SV *key
    SV *value
INIT:
    sfxaa_t *p, tmp;
PPCODE:
    tmp.key = SvNV(key);
    tmp.val = SvNV(value);
    if ((p = NEDTRIE_FIND(sfxaa_tree_s, &(pSpeedyFxResult->root), &tmp)) != 0)
        p->val = tmp.val;
    else {
        if (pSpeedyFxResult->count++ >= MAX_TRIE_SIZE)
            croak("too many unique tokens in a single data chunk");
        p = &(pSpeedyFxResult->index[pSpeedyFxResult->count]);
        p->key = tmp.key;
        p->val = tmp.val;
        NEDTRIE_INSERT(sfxaa_tree_s, &(pSpeedyFxResult->root), p);
    }

void
DELETE (pSpeedyFxResult, key)
    Text::SpeedyFx::Result pSpeedyFxResult
    SV *key
INIT:
    sfxaa_t *p, tmp;
PPCODE:
    tmp.key = SvNV(key);
    if ((p = NEDTRIE_FIND(sfxaa_tree_s, &(pSpeedyFxResult->root), &tmp)) == 0) {
        XSRETURN_UNDEF;
    } else {
        ST(0) = sv_2mortal(newSVnv(p->val));
        NEDTRIE_REMOVE(sfxaa_tree_s, &(pSpeedyFxResult->root), p);
        XSRETURN(1);
    }

void
CLEAR (pSpeedyFxResult)
    Text::SpeedyFx::Result pSpeedyFxResult
PPCODE:
    NEDTRIE_INIT(&(pSpeedyFxResult->root));
    pSpeedyFxResult->count = 0;

void
EXISTS (pSpeedyFxResult, key)
    Text::SpeedyFx::Result pSpeedyFxResult
    SV *key
INIT:
    sfxaa_t *p, tmp;
PPCODE:
    tmp.key = SvNV(key);
    if ((p = NEDTRIE_FIND(sfxaa_tree_s, &(pSpeedyFxResult->root), &tmp)) == 0) {
        XSRETURN_NO;
    } else {
        XSRETURN_YES;
    }

void
FIRSTKEY (pSpeedyFxResult)
    Text::SpeedyFx::Result pSpeedyFxResult
INIT:
    sfxaa_t *p;
PPCODE:
    if ((p = NEDTRIE_MIN(sfxaa_tree_s, &(pSpeedyFxResult->root))) == 0) {
        XSRETURN_UNDEF;
    } else {
        pSpeedyFxResult->last = p;

        ST(0) = sv_2mortal(newSVnv(p->key));
        XSRETURN(1);
    }

void
NEXTKEY (pSpeedyFxResult, ...)
    Text::SpeedyFx::Result pSpeedyFxResult
INIT:
    sfxaa_t *p;
PPCODE:
    if ((p = NEDTRIE_NEXT(sfxaa_tree_s, &(pSpeedyFxResult->root), pSpeedyFxResult->last)) == 0) {
        XSRETURN_UNDEF;
    } else {
        pSpeedyFxResult->last = p;

        ST(0) = sv_2mortal(newSVnv(p->key));
        XSRETURN(1);
    }

void
SCALAR (pSpeedyFxResult)
    Text::SpeedyFx::Result pSpeedyFxResult
PPCODE:
    ST(0) = sv_2mortal(newSVpvf("%d/%d", pSpeedyFxResult->count, MAX_TRIE_SIZE));
    XSRETURN(1);

void
UNTIE (...)
PPCODE:
    croak("not implemented");

void
DESTROY (pSpeedyFxResult)
    Text::SpeedyFx::Result pSpeedyFxResult
PPCODE:
    Safefree(pSpeedyFxResult);

MODULE = Text::SpeedyFx PACKAGE = Text::SpeedyFx

PROTOTYPES: ENABLE

Text::SpeedyFx
new (...)
PREINIT:
    U32 seed = 1;
    U8 bits = 18;
    static U32 fold_init = 0;
    static U32 fold_table[MAX_MAP_SIZE];
INIT:
    U32 i;
    U8 s[8];
    U8 *t;
    U8 u[8], *v;
    UV c;
    STRLEN len;
    U32 length, *code_table;
    U32 rand_table[MAX_MAP_SIZE];
CODE:
    if (items > 1)
        seed = SvNV(ST(1));
    if (items > 2)
        bits = SvNV(ST(2));

    if (seed == 0)
        croak("seed must be not 0!");

    if (bits <= 8)
        length = 256;
    else if (bits > 17)
        length = MAX_MAP_SIZE;
    else
        length = 1 << bits;

    SpeedyFx *pSpeedyFx;
    Newxc(pSpeedyFx, 1 + length, U32, SpeedyFx);

    pSpeedyFx->length = length;
    code_table = pSpeedyFx->code_table;

    fold_table[0] = 0;
    if (fold_init < length) {
        for (i = fold_init + 1; i < length; i++) {
            if (i >= 0xd800 && i <= 0xdfff)         // high/low-surrogate code points
                c = 0;
            else if (i >= 0xfdd0 && i <= 0xfdef)    // noncharacters
                c = 0;
            else if ((i & 0xffff) == 0xfffe)        // noncharacters
                c = 0;
            else if ((i & 0xffff) == 0xffff)        // noncharacters
                c = 0;
            else {
                t = uvchr_to_utf8(s, (UV) i);
                *t = '\0';

                if (isALNUM_utf8(s)) {
                    (void) toLOWER_utf8(s, u, &len);
                    *(u + len) = '\0';
                    v = u + len;

                    c = ChrCode(u, v, &len);

                    // grow the tables, if necessary
                    if (length < c)
                        length = c;
                } else
                    c = 0;
            }
            fold_table[i] = c;
        }
        fold_init = length;
    }

    if (pSpeedyFx->length != length) {
        Renewc(pSpeedyFx, 1 + length, U32, SpeedyFx);

        pSpeedyFx->length = length;
        code_table = pSpeedyFx->code_table;
    }
    Zero(code_table, length, U32);

    rand_table[0] = seed;
    for (i = 1; i < length; i++)
        rand_table[i]
            = (
                rand_table[i - 1]
                * 0x10a860c1
            ) % 0xfffffffb;

    for (i = 0; i < length; i++)
        if (fold_table[i])
            code_table[i] = rand_table[fold_table[i]];

    RETVAL = pSpeedyFx;
OUTPUT:
    RETVAL

void
hash (pSpeedyFx, str)
    Text::SpeedyFx pSpeedyFx
    SV *str
INIT:
    _SPEEDYFX_INIT;
    SV *res;
    SpeedyFxResult *pSpeedyFxResult;
    sfxaa_tree_t *root;
    sfxaa_t *p, *slot, *end, tmp;
PPCODE:
    res = result_init();
    if ((pSpeedyFxResult = result_addr(res)) == NULL)
        croak("TARFU");

    root    = &(pSpeedyFxResult->root);
    slot    = &(pSpeedyFxResult->index[0]);
    end     = &(pSpeedyFxResult->index[MAX_TRIE_SIZE]);

    if (length > 256) {
        _SPEEDYFX(_NEDTRIE_STORE, _WALK_UTF8, length);
    } else {
        _SPEEDYFX(_NEDTRIE_STORE, _WALK_LATIN1, 256);
    }

    pSpeedyFxResult->count = (slot - pSpeedyFxResult->index) / sizeof(sfxaa_t);

    ST(0) = sv_2mortal(res);
    XSRETURN(1);

void
DESTROY (pSpeedyFx)
    Text::SpeedyFx pSpeedyFx
PPCODE:
    Safefree(pSpeedyFx);
    XSRETURN(0);

void
hash_fv (pSpeedyFx, str, n)
    Text::SpeedyFx pSpeedyFx
    SV *str
    U32 n
INIT:
    _SPEEDYFX_INIT;
    U32 size = ceil((float) n / 8.0);
    char *fv;
PPCODE:
    Newxz(fv, size, char);

    if (length > 256) {
        _SPEEDYFX(SetBit(fv, wordhash % n), _WALK_UTF8, length);
    } else {
        _SPEEDYFX(SetBit(fv, wordhash % n), _WALK_LATIN1, 256);
    }

    ST(0) = sv_2mortal(newSVpv(fv, size));
    Safefree(fv);
    XSRETURN(1);

void
hash_min (pSpeedyFx, str)
    Text::SpeedyFx pSpeedyFx
    SV *str
INIT:
    _SPEEDYFX_INIT;
    U32 min = 0xffffffff;
PPCODE:
    if (length > 256) {
        _SPEEDYFX(min = FastMin(min, wordhash), _WALK_UTF8, length);
    } else {
        _SPEEDYFX(min = FastMin(min, wordhash), _WALK_LATIN1, 256);
    }

    ST(0) = sv_2mortal(newSVnv(min));
    XSRETURN(1);
