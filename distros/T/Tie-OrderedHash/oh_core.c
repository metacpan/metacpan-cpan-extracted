/*
 * oh_core.c -- core implementation of Tie::OrderedHash.
 *
 * Storage: blessed AV-of-4 mirroring Tie::IxHash's shape.
 *
 *   $self = bless [
 *       $idx_hv,   # [0] HV mapping key -> index (IV stored in SV)
 *       $keys_av,  # [1] AV of keys in insertion order
 *       $vals_av,  # [2] AV of values
 *       $iter,     # [3] IV: cursor used by Perl FIRSTKEY/NEXTKEY
 *   ] => 'Tie::OrderedHash';
 *
 * Perl-level users see a tied hash; the AV layout is internal but
 * matches Tie::IxHash so power users who poked $ixhash->[1] for keys
 * still get the right answer.  Document the right way: call ->Keys.
 *
 * Filename note: this is "oh_core.c" rather than "orderedhash.c"
 * because xsubpp generates "OrderedHash.c" from OrderedHash.xs and
 * macOS's case-insensitive filesystem collapses the two.  Same trap
 * we hit on File-Raw-JSON (json.c vs JSON.c).
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "tie_orderedhash.h"
#include "oh_core.h"

/* ---- internals ------------------------------------------------- */

/* Build a key SV from raw bytes, marking the UTF-8 flag when the
 * bytes are valid UTF-8.  Used both for the SVs we store in the
 * keys AV and for the mortal lookup-key SVs we feed to
 * hv_fetch_ent / hv_delete_ent.
 *
 * Why this matters: callers that pass UTF-8 bytes (eg
 * File::Raw::JSON's ordered=>1 path, where yyjson's strings are
 * native UTF-8) want `$h->{"\x{00e9}"}` lookups to match the
 * key they stored.  Without sv_utf8_decode, the stored key has
 * raw bytes [0xC3, 0xA9] and no UTF-8 flag; a wide-char literal
 * comes through as character "\x{e9}" (one char) and the byte
 * comparison misses.  sv_utf8_decode validates the bytes and
 * sets the flag iff they're proper UTF-8 - safe no-op for ASCII
 * and for non-UTF-8 binary keys. */
PERL_STATIC_INLINE SV *
oh_make_key_sv(pTHX_ const char *key, STRLEN klen)
{
    SV *sv = newSVpvn(key, klen);
    sv_utf8_decode(sv);
    return sv;
}

void
oh_resolve(pTHX_ SV *self, HV **out_idx, AV **out_keys, AV **out_vals)
{
    AV *av;
    SV **slot;

    if (!self || !SvROK(self) || !SvOBJECT(SvRV(self)))
        croak("Tie::OrderedHash: not an object");
    if (SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Tie::OrderedHash: impl is not an array ref");
    av = (AV *)SvRV(self);
    if (av_len(av) < 2)
        croak("Tie::OrderedHash: impl has fewer than 3 slots");

    slot = av_fetch(av, 0, 0);
    if (!slot || !*slot || !SvROK(*slot) || SvTYPE(SvRV(*slot)) != SVt_PVHV)
        croak("Tie::OrderedHash: slot 0 is not a hash ref");
    *out_idx = (HV *)SvRV(*slot);

    slot = av_fetch(av, 1, 0);
    if (!slot || !*slot || !SvROK(*slot) || SvTYPE(SvRV(*slot)) != SVt_PVAV)
        croak("Tie::OrderedHash: slot 1 is not an array ref");
    *out_keys = (AV *)SvRV(*slot);

    slot = av_fetch(av, 2, 0);
    if (!slot || !*slot || !SvROK(*slot) || SvTYPE(SvRV(*slot)) != SVt_PVAV)
        croak("Tie::OrderedHash: slot 2 is not an array ref");
    *out_vals = (AV *)SvRV(*slot);
}

SSize_t
oh_perl_iter_get(pTHX_ SV *self)
{
    AV *av = (AV *)SvRV(self);
    SV **slot = av_fetch(av, 3, 0);
    if (!slot || !*slot) return 0;
    return (SSize_t)SvIV(*slot);
}

void
oh_perl_iter_set(pTHX_ SV *self, SSize_t pos)
{
    AV *av = (AV *)SvRV(self);
    SV **slot = av_fetch(av, 3, 1);
    if (slot && *slot)
        sv_setiv(*slot, (IV)pos);
}

/* ---- public C ABI ---------------------------------------------- */

SV *
tie_oh_new(pTHX)
{
    AV *av = newAV();
    HV *stash = gv_stashpv(TIE_OH_CLASS, GV_ADD);
    SV *rv;

    av_extend(av, 3);
    av_push(av, newRV_noinc((SV *)newHV()));   /* [0] idx hv  */
    av_push(av, newRV_noinc((SV *)newAV()));   /* [1] keys av */
    av_push(av, newRV_noinc((SV *)newAV()));   /* [2] vals av */
    av_push(av, newSViv(0));                   /* [3] cursor  */

    rv = newRV_noinc((SV *)av);
    sv_bless(rv, stash);
    return rv;
}

void
tie_oh_store(pTHX_ SV *self, const char *key, STRLEN klen, SV *val)
{
    HV *idx; AV *keys; AV *vals;
    HE *he;
    SV *key_sv;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);

    he = hv_fetch_ent(idx, sv_2mortal(oh_make_key_sv(aTHX_ key, klen)), 0, 0);
    if (he) {
        /* Existing key: replace value, preserve position. */
        SSize_t pos = (SSize_t)SvIV(HeVAL(he));
        if (!av_store(vals, pos, val))
            SvREFCNT_dec(val);
        return;
    }

    /* New key: append to keys+vals, record index in idx. */
    key_sv = oh_make_key_sv(aTHX_ key, klen);
    av_push(keys, key_sv);
    if (!av_store(vals, av_len(keys), val)) {
        SvREFCNT_dec(val);
    }
    {
        SV *idx_sv = newSViv((IV)av_len(keys));
        if (!hv_store_ent(idx, key_sv, idx_sv, 0))
            SvREFCNT_dec(idx_sv);
    }
}

SV *
tie_oh_fetch(pTHX_ SV *self, const char *key, STRLEN klen)
{
    HV *idx; AV *keys; AV *vals;
    HE *he;
    SSize_t pos;
    SV **vslot;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);

    he = hv_fetch_ent(idx, sv_2mortal(oh_make_key_sv(aTHX_ key, klen)), 0, 0);
    if (!he) return NULL;
    pos = (SSize_t)SvIV(HeVAL(he));

    vslot = av_fetch(vals, pos, 0);
    if (!vslot || !*vslot) return sv_mortalcopy(&PL_sv_undef);
    return sv_mortalcopy(*vslot);
}

int
tie_oh_exists(pTHX_ SV *self, const char *key, STRLEN klen)
{
    HV *idx; AV *keys; AV *vals;
    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    return hv_exists_ent(idx,
        sv_2mortal(oh_make_key_sv(aTHX_ key, klen)), 0) ? 1 : 0;
}

/* av_remove_at -- like Perl's `splice @arr, pos, 1`.  av_delete
 * leaves a hole (NULL slot, length unchanged); we want to actually
 * shift everything after `pos` down by one and shrink. */
static void
av_remove_at(pTHX_ AV *av, SSize_t pos)
{
    SSize_t i, top = av_len(av);
    SV *trailing;

    /* Shift [pos+1..top] down to [pos..top-1].  av_store at slot i
     * frees the existing SV there; at i==pos that's the value
     * being removed (caller has already grabbed any return copy). */
    for (i = pos; i < top; i++) {
        SV **src = av_fetch(av, i + 1, 0);
        if (src && *src) {
            SvREFCNT_inc(*src);
            if (!av_store(av, i, *src))
                SvREFCNT_dec(*src);
        }
    }
    /* Trim the trailing duplicate slot. */
    trailing = av_pop(av);
    if (trailing) SvREFCNT_dec(trailing);
}

SV *
tie_oh_delete(pTHX_ SV *self, const char *key, STRLEN klen)
{
    HV *idx; AV *keys; AV *vals;
    SV *deleted_idx;
    SV *deleted_val = NULL;
    SSize_t pos;
    SSize_t i, n;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);

    deleted_idx = hv_delete_ent(idx,
        sv_2mortal(oh_make_key_sv(aTHX_ key, klen)), 0, 0);
    if (!deleted_idx) return NULL;
    pos = (SSize_t)SvIV(deleted_idx);

    {
        SV **vslot = av_fetch(vals, pos, 0);
        deleted_val = (vslot && *vslot) ? sv_mortalcopy(*vslot)
                                        : sv_mortalcopy(&PL_sv_undef);
    }

    av_remove_at(aTHX_ vals, pos);
    av_remove_at(aTHX_ keys, pos);

    /* Renumber: every key whose index was > pos moved down by one. */
    n = av_len(keys) + 1;
    for (i = pos; i < n; i++) {
        SV **kslot = av_fetch(keys, i, 0);
        HE *he;
        if (!kslot || !*kslot) continue;
        he = hv_fetch_ent(idx, *kslot, 0, 0);
        if (he && HeVAL(he)) sv_setiv(HeVAL(he), (IV)i);
    }

    {
        SSize_t cur = oh_perl_iter_get(aTHX_ self);
        if (cur > n) oh_perl_iter_set(aTHX_ self, n);
    }

    return deleted_val;
}

void
tie_oh_clear(pTHX_ SV *self)
{
    AV *av;
    SV **slot;

    if (!self || !SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Tie::OrderedHash: not an impl object");
    av = (AV *)SvRV(self);

    slot = av_fetch(av, 0, 1);
    if (slot) sv_setsv(*slot, sv_2mortal(newRV_noinc((SV *)newHV())));
    slot = av_fetch(av, 1, 1);
    if (slot) sv_setsv(*slot, sv_2mortal(newRV_noinc((SV *)newAV())));
    slot = av_fetch(av, 2, 1);
    if (slot) sv_setsv(*slot, sv_2mortal(newRV_noinc((SV *)newAV())));
    slot = av_fetch(av, 3, 1);
    if (slot) sv_setiv(*slot, 0);
}

SSize_t
tie_oh_count(pTHX_ SV *self)
{
    HV *idx; AV *keys; AV *vals;
    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    return av_len(keys) + 1;
}

void
tie_oh_iter_init(pTHX_ SV *self, tie_oh_iter_t *iter)
{
    HV *idx; AV *keys; AV *vals;
    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    iter->pos = 0;
    iter->end = av_len(keys) + 1;
}

int
tie_oh_iter_next(pTHX_ SV *self, tie_oh_iter_t *iter,
                 const char **out_key, STRLEN *out_klen,
                 SV **out_val)
{
    HV *idx; AV *keys; AV *vals;
    SV **kslot, **vslot;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    if (iter->pos >= iter->end) return 0;
    if (iter->pos > av_len(keys)) return 0;

    kslot = av_fetch(keys, iter->pos, 0);
    if (!kslot || !*kslot) return 0;
    *out_key  = SvPV(*kslot, *out_klen);

    vslot = av_fetch(vals, iter->pos, 0);
    *out_val = (vslot && *vslot) ? *vslot : &PL_sv_undef;

    iter->pos++;
    return 1;
}

int
tie_oh_is_instance(pTHX_ SV *sv)
{
    HV *stash;
    const char *name;

    if (!sv || !SvROK(sv) || !SvOBJECT(SvRV(sv))) return 0;
    if (SvTYPE(SvRV(sv)) != SVt_PVAV) return 0;
    stash = SvSTASH(SvRV(sv));
    if (!stash) return 0;
    name = HvNAME_get(stash);
    if (!name) return 0;
    return strEQ(name, TIE_OH_CLASS) ? 1 : 0;
}

/* ---- internal helpers used by the OO XSUBs --------------------- */

SV *
oh_pop(pTHX_ SV *self, SV **out_key)
{
    HV *idx; AV *keys; AV *vals;
    SV *kpop, *vpop;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    if (av_len(keys) < 0) {
        if (out_key) *out_key = NULL;
        return NULL;
    }

    kpop = av_pop(keys);
    vpop = av_pop(vals);
    if (kpop) hv_delete_ent(idx, kpop, G_DISCARD, 0);

    if (out_key) *out_key = kpop ? sv_2mortal(kpop) : NULL;
    return vpop ? sv_2mortal(vpop) : NULL;
}

SV *
oh_shift(pTHX_ SV *self, SV **out_key)
{
    HV *idx; AV *keys; AV *vals;
    SV *kshift, *vshift;
    SSize_t i, n;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    if (av_len(keys) < 0) {
        if (out_key) *out_key = NULL;
        return NULL;
    }

    kshift = av_shift(keys);
    vshift = av_shift(vals);
    if (kshift) hv_delete_ent(idx, kshift, G_DISCARD, 0);

    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **kslot = av_fetch(keys, i, 0);
        HE *he;
        if (!kslot || !*kslot) continue;
        he = hv_fetch_ent(idx, *kslot, 0, 0);
        if (he && HeVAL(he)) sv_setiv(HeVAL(he), (IV)i);
    }

    if (out_key) *out_key = kshift ? sv_2mortal(kshift) : NULL;
    return vshift ? sv_2mortal(vshift) : NULL;
}

void
oh_unshift_pair(pTHX_ SV *self, SV *key_sv, SV *val)
{
    HV *idx; AV *keys; AV *vals;
    HE *he;
    STRLEN klen;
    const char *key;
    SSize_t i, n;

    oh_resolve(aTHX_ self, &idx, &keys, &vals);
    key = SvPV(key_sv, klen);

    he = hv_fetch_ent(idx, key_sv, 0, 0);
    if (he) {
        SSize_t pos = (SSize_t)SvIV(HeVAL(he));
        if (!av_store(vals, pos, val)) SvREFCNT_dec(val);
        return;
    }

    n = av_len(keys) + 1;
    av_unshift(keys, 1);
    av_unshift(vals, 1);
    {
        SV *kdup = oh_make_key_sv(aTHX_ key, klen);
        if (!av_store(keys, 0, kdup)) SvREFCNT_dec(kdup);
        if (!av_store(vals, 0, val))  SvREFCNT_dec(val);
    }
    /* Renumber existing keys up by one. */
    for (i = 1; i <= n; i++) {
        SV **kslot = av_fetch(keys, i, 0);
        HE *he2;
        if (!kslot || !*kslot) continue;
        he2 = hv_fetch_ent(idx, *kslot, 0, 0);
        if (he2 && HeVAL(he2)) sv_setiv(HeVAL(he2), (IV)i);
    }
    /* Record idx 0 for the new key. */
    {
        SV **kslot = av_fetch(keys, 0, 0);
        SV *idx_sv = newSViv(0);
        SV *kdup = (kslot && *kslot) ? *kslot : key_sv;
        if (!hv_store_ent(idx, kdup, idx_sv, 0))
            SvREFCNT_dec(idx_sv);
    }
}

void
oh_push_pair(pTHX_ SV *self, SV *key_sv, SV *val)
{
    STRLEN klen;
    const char *key = SvPV(key_sv, klen);
    tie_oh_store(aTHX_ self, key, klen, val);
}
