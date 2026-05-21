/*
 * oh_core.h -- private declarations shared between oh_core.c (the
 * C implementation) and OrderedHash.xs (the XSUB layer).
 *
 * Public ABI lives in include/tie_orderedhash.h.
 *
 * Filename note: not "orderedhash.h" because xsubpp generates
 * OrderedHash.c from OrderedHash.xs, and macOS's case-insensitive
 * filesystem collapses "OrderedHash.c" and "orderedhash.c" into the
 * same path.
 */

#ifndef TIE_ORDEREDHASH_PRIVATE_H
#define TIE_ORDEREDHASH_PRIVATE_H

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "tie_orderedhash.h"

#define TIE_OH_CLASS "Tie::OrderedHash"

/* Resolve $self->[0..2] (idx HV, keys AV, values AV).  Croaks if the
 * SV doesn't look like one of our impl objects.  $self->[3] (iter
 * cursor) is fetched separately via oh_iter_cursor when needed -
 * the FIRSTKEY/NEXTKEY path is the only consumer. */
void oh_resolve(pTHX_ SV *self,
                HV **out_idx, AV **out_keys, AV **out_vals);

/* Fast resolve: trusts that `self` is one of our impl objects.
 * No type checks, no croaks.  Called on hot paths from XSUBs that
 * are reached only through tie magic dispatch on our class. */
PERL_STATIC_INLINE void
oh_resolve_fast(pTHX_ SV *self, HV **out_idx, AV **out_keys, AV **out_vals)
{
    AV *av = (AV *)SvRV(self);
    SV **slots = AvARRAY(av);
    *out_idx  = (HV *)SvRV(slots[0]);
    *out_keys = (AV *)SvRV(slots[1]);
    *out_vals = (AV *)SvRV(slots[2]);
}

/* Internal helpers used by the OO methods (Pop / Shift / Unshift /
 * Push) but not part of the public C ABI. */
SV *oh_pop(pTHX_ SV *self,  SV **out_key);
SV *oh_shift(pTHX_ SV *self, SV **out_key);
void oh_unshift_pair(pTHX_ SV *self, SV *key_sv, SV *val);
void oh_push_pair(pTHX_ SV *self, SV *key_sv, SV *val);

/* $self->[3] iterator cursor accessors for FIRSTKEY/NEXTKEY. */
SSize_t oh_perl_iter_get(pTHX_ SV *self);
void    oh_perl_iter_set(pTHX_ SV *self, SSize_t pos);

#endif /* TIE_ORDEREDHASH_PRIVATE_H */
