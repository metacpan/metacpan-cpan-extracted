#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "tie_orderedhash.h"
#include "oh_core.h"

/* ---- helpers shared between XSUBs ----------------------------- */

/* Trusted-fast accessors for the FIRSTKEY/NEXTKEY hot path. */
PERL_STATIC_INLINE AV *
xs_keys_av_fast(pTHX_ SV *self)
{
    AV *av = (AV *)SvRV(self);
    return (AV *)SvRV(AvARRAY(av)[1]);
}

PERL_STATIC_INLINE SV *
xs_cursor_sv_fast(pTHX_ SV *self)
{
    AV *av = (AV *)SvRV(self);
    return AvARRAY(av)[3];
}

MODULE = Tie::OrderedHash    PACKAGE = Tie::OrderedHash    PREFIX = oh_

PROTOTYPES: DISABLE

# ---- tied-hash interface ------------------------------------------

# TIEHASH(class, ...) -- construct fresh, then Push any (k,v) pairs.
SV *
oh_TIEHASH(class, ...)
    const char *class
PREINIT:
    SV *self;
    int i;
CODE:
    PERL_UNUSED_VAR(class);
    self = tie_oh_new(aTHX);
    if ((items - 1) % 2 != 0) {
        SvREFCNT_dec(self);
        croak("Tie::OrderedHash::TIEHASH: odd number of arguments");
    }
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN klen;
        const char *key = SvPV(ST(i), klen);
        SV *val = newSVsv(ST(i + 1));
        tie_oh_store(aTHX_ self, key, klen, val);
    }
    RETVAL = self;
OUTPUT:
    RETVAL

SV *
oh_FETCH(self, key)
    SV *self
    SV *key
PREINIT:
    HV *idx; AV *keys; AV *vals;
    HE *he;
    SV **vslot;
    SSize_t pos;
CODE:
    /* Fast-path FETCH: bypass the public-ABI wrapper, walk the AV
     * directly.  Share the internal value SV (SvREFCNT_inc rather
     * than newSVsv) so `$h{a}->{nested} = 1` autoviv lands back in
     * our storage - matches both Tie::IxHash and plain-HV semantics. */
    oh_resolve_fast(aTHX_ self, &idx, &keys, &vals);
    he = hv_fetch_ent(idx, key, 0, 0);
    if (!he) {
        RETVAL = newSV(0);
    } else {
        pos = (SSize_t)SvIV(HeVAL(he));
        vslot = av_fetch(vals, pos, 0);
        if (vslot && *vslot) {
            RETVAL = *vslot;
            SvREFCNT_inc_simple_void_NN(RETVAL);
        } else {
            RETVAL = newSV(0);
        }
    }
OUTPUT:
    RETVAL

void
oh_STORE(self, key, value)
    SV *self
    SV *key
    SV *value
PREINIT:
    HV *idx; AV *keys; AV *vals;
    HE *he;
    SV *vcopy;
CODE:
    oh_resolve_fast(aTHX_ self, &idx, &keys, &vals);
    /* hv_fetch_ent with our input key SV reuses any cached hash. */
    he = hv_fetch_ent(idx, key, 0, 0);
    if (he) {
        /* Existing key: overwrite the value SV in place if we can.
         * sv_setsv on the existing slot avoids a fresh SV alloc per
         * overwrite - meaningful in update-heavy workloads.  Falls
         * back to a fresh av_store if the slot SV has any unusual
         * state (eg readonly, frozen). */
        SSize_t pos = (SSize_t)SvIV(HeVAL(he));
        SV **vslot = av_fetch(vals, pos, 0);
        if (vslot && *vslot && !SvREADONLY(*vslot)) {
            sv_setsv(*vslot, value);
        } else {
            vcopy = newSVsv(value);
            if (!av_store(vals, pos, vcopy))
                SvREFCNT_dec(vcopy);
        }
    } else {
        /* New key: append, then record index in idx HV. */
        STRLEN klen;
        const char *kpv = SvPV(key, klen);
        SV *key_sv = newSVpvn(kpv, klen);
        SV *idx_sv;
        SSize_t newpos;
        vcopy = newSVsv(value);
        av_push(keys, key_sv);
        newpos = av_len(keys);
        if (!av_store(vals, newpos, vcopy))
            SvREFCNT_dec(vcopy);
        idx_sv = newSViv((IV)newpos);
        if (!hv_store_ent(idx, key_sv, idx_sv, 0))
            SvREFCNT_dec(idx_sv);
    }

int
oh_EXISTS(self, key)
    SV *self
    SV *key
PREINIT:
    HV *idx; AV *keys; AV *vals;
CODE:
    oh_resolve_fast(aTHX_ self, &idx, &keys, &vals);
    RETVAL = hv_exists_ent(idx, key, 0) ? 1 : 0;
OUTPUT:
    RETVAL

SV *
oh_DELETE(self, key)
    SV *self
    SV *key
PREINIT:
    STRLEN klen;
    const char *kpv;
    SV *got;
CODE:
    kpv = SvPV(key, klen);
    got = tie_oh_delete(aTHX_ self, kpv, klen);
    RETVAL = got ? newSVsv(got) : newSV(0);
OUTPUT:
    RETVAL

void
oh_CLEAR(self)
    SV *self
CODE:
    tie_oh_clear(aTHX_ self);

SV *
oh_FIRSTKEY(self)
    SV *self
PREINIT:
    AV *keys;
    SV *cursor;
    SV **kslot;
CODE:
    keys   = xs_keys_av_fast(aTHX_ self);
    cursor = xs_cursor_sv_fast(aTHX_ self);
    if (av_len(keys) < 0) {
        sv_setiv(cursor, 0);
        XSRETURN_UNDEF;
    }
    kslot = av_fetch(keys, 0, 0);
    if (!kslot || !*kslot) {
        sv_setiv(cursor, 0);
        XSRETURN_UNDEF;
    }
    sv_setiv(cursor, 1);
    SvREFCNT_inc_simple_void_NN(*kslot);
    RETVAL = *kslot;
OUTPUT:
    RETVAL

SV *
oh_NEXTKEY(self, lastkey)
    SV *self
    SV *lastkey
PREINIT:
    AV *keys;
    SV *cursor;
    SSize_t pos;
    SV **kslot;
CODE:
    PERL_UNUSED_VAR(lastkey);
    keys   = xs_keys_av_fast(aTHX_ self);
    cursor = xs_cursor_sv_fast(aTHX_ self);
    pos    = (SSize_t)SvIV(cursor);
    if (pos < 0 || pos > av_len(keys)) XSRETURN_UNDEF;
    kslot = av_fetch(keys, pos, 0);
    if (!kslot || !*kslot) XSRETURN_UNDEF;
    sv_setiv(cursor, pos + 1);
    SvREFCNT_inc_simple_void_NN(*kslot);
    RETVAL = *kslot;
OUTPUT:
    RETVAL

int
oh_SCALAR(self)
    SV *self
CODE:
    RETVAL = tie_oh_count(aTHX_ self) > 0 ? 1 : 0;
OUTPUT:
    RETVAL

# ---- OO interface (class methods) ---------------------------------

SV *
oh_new(class, ...)
    const char *class
PREINIT:
    SV *self;
    int i;
CODE:
    PERL_UNUSED_VAR(class);
    self = tie_oh_new(aTHX);
    if ((items - 1) % 2 != 0) {
        SvREFCNT_dec(self);
        croak("Tie::OrderedHash::new: odd number of arguments");
    }
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN klen;
        const char *key = SvPV(ST(i), klen);
        SV *val = newSVsv(ST(i + 1));
        tie_oh_store(aTHX_ self, key, klen, val);
    }
    RETVAL = self;
OUTPUT:
    RETVAL

# Push -- in-order insert/update of (k,v) pairs.  Returns post-count.
int
oh_Push(self, ...)
    SV *self
PREINIT:
    int i;
CODE:
    if ((items - 1) % 2 != 0)
        croak("Tie::OrderedHash::Push: odd number of arguments");
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN klen;
        const char *key = SvPV(ST(i), klen);
        SV *val = newSVsv(ST(i + 1));
        tie_oh_store(aTHX_ self, key, klen, val);
    }
    RETVAL = (int)tie_oh_count(aTHX_ self);
OUTPUT:
    RETVAL

# Pop -- remove last pair, return (key, value).  Empty list on empty.
void
oh_Pop(self)
    SV *self
PREINIT:
    SV *kpop, *vpop;
PPCODE:
    vpop = oh_pop(aTHX_ self, &kpop);
    if (!kpop || !vpop) XSRETURN_EMPTY;
    EXTEND(SP, 2);
    PUSHs(kpop);
    PUSHs(vpop);

# Shift -- same but front.
void
oh_Shift(self)
    SV *self
PREINIT:
    SV *kshift, *vshift;
PPCODE:
    vshift = oh_shift(aTHX_ self, &kshift);
    if (!kshift || !vshift) XSRETURN_EMPTY;
    EXTEND(SP, 2);
    PUSHs(kshift);
    PUSHs(vshift);

# Unshift -- prepend (k,v) pairs.  Per Tie::IxHash, existing keys
# are updated in place without changing position.
int
oh_Unshift(self, ...)
    SV *self
PREINIT:
    int i;
CODE:
    if ((items - 1) % 2 != 0)
        croak("Tie::OrderedHash::Unshift: odd number of arguments");
    /* Walk the trailing args in REVERSE so the supplied list ends
     * up in source order at the front of the hash.  Tie::IxHash's
     * Unshift documents this behaviour. */
    for (i = items - 2; i >= 1; i -= 2) {
        SV *val = newSVsv(ST(i + 1));
        oh_unshift_pair(aTHX_ self, ST(i), val);
    }
    RETVAL = (int)tie_oh_count(aTHX_ self);
OUTPUT:
    RETVAL

# Keys: with no args, return the whole keys list in order.  With
# args, return keys at those indices (negative offsets supported).
void
oh_Keys(self, ...)
    SV *self
PREINIT:
    HV *idx; AV *keys; AV *vals;
    SSize_t i, n;
PPCODE:
    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    n = av_len(keys) + 1;
    if (items == 1) {
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **slot = av_fetch(keys, i, 0);
            PUSHs(slot && *slot ? sv_mortalcopy(*slot) : &PL_sv_undef);
        }
    } else {
        int j;
        EXTEND(SP, items - 1);
        for (j = 1; j < items; j++) {
            IV want = SvIV(ST(j));
            SSize_t pos = want < 0 ? n + want : want;
            if (pos < 0 || pos >= n) {
                PUSHs(&PL_sv_undef);
            } else {
                SV **slot = av_fetch(keys, pos, 0);
                PUSHs(slot && *slot ? sv_mortalcopy(*slot) : &PL_sv_undef);
            }
        }
    }

void
oh_Values(self, ...)
    SV *self
PREINIT:
    HV *idx; AV *keys; AV *vals;
    SSize_t i, n;
PPCODE:
    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    n = av_len(vals) + 1;
    if (items == 1) {
        EXTEND(SP, n);
        for (i = 0; i < n; i++) {
            SV **slot = av_fetch(vals, i, 0);
            PUSHs(slot && *slot ? sv_mortalcopy(*slot) : &PL_sv_undef);
        }
    } else {
        int j;
        EXTEND(SP, items - 1);
        for (j = 1; j < items; j++) {
            IV want = SvIV(ST(j));
            SSize_t pos = want < 0 ? n + want : want;
            if (pos < 0 || pos >= n) {
                PUSHs(&PL_sv_undef);
            } else {
                SV **slot = av_fetch(vals, pos, 0);
                PUSHs(slot && *slot ? sv_mortalcopy(*slot) : &PL_sv_undef);
            }
        }
    }

int
oh_Length(self)
    SV *self
CODE:
    RETVAL = (int)tie_oh_count(aTHX_ self);
OUTPUT:
    RETVAL

void
oh_Clear(self)
    SV *self
CODE:
    tie_oh_clear(aTHX_ self);
