/*
 * tie_orderedhash.h -- public C ABI for Tie::OrderedHash
 *
 * Lets C-level callers manipulate a Tie::OrderedHash impl object
 * directly, without going through Perl method dispatch.  Pulled in
 * by dependent dists via ExtUtils::Depends:
 *
 *     my $oh = ExtUtils::Depends->new('Foo', 'Tie::OrderedHash');
 *
 * after which #include "tie_orderedhash.h" Just Works.
 */

#ifndef TIE_ORDEREDHASH_H
#define TIE_ORDEREDHASH_H

#include "EXTERN.h"
#include "perl.h"

#define TIE_ORDEREDHASH_ABI 1

/*
 * All functions take the blessed impl SV (the return value of
 * Tie::OrderedHash->new or TIEHASH).  The SV is *not* the tied %h
 * itself; it's the underlying object.  When you have a tied HV, you
 * pull the impl SV out via mg_find(hv, PERL_MAGIC_tied)->mg_obj.
 */

/* ---- construction ---------------------------------------------- */

/* refcount=1 blessed RV; caller owns it.  Free with SvREFCNT_dec. */
SV *tie_oh_new(pTHX);

/* ---- mutation -------------------------------------------------- */

/* Store (key, val) into self.  TAKES OWNERSHIP of `val`'s refcount;
 * the AV stores it directly with no extra inc/dec.  If you need to
 * keep a reference yourself, SvREFCNT_inc before calling. */
void tie_oh_store(pTHX_ SV *self,
                  const char *key, STRLEN klen,
                  SV *val);

/* Remove `key` from self.  Returns the deleted value as a mortal,
 * or NULL if the key wasn't present. */
SV *tie_oh_delete(pTHX_ SV *self, const char *key, STRLEN klen);

/* Drop everything; equivalent to a fresh tie_oh_new contents. */
void tie_oh_clear(pTHX_ SV *self);

/* ---- accessors ------------------------------------------------- */

/* Returns the value SV as a mortal (you don't own a refcount), or
 * NULL if absent.  Note: NULL distinguishes "not present" from
 * "stored undef" - the latter returns a mortal &PL_sv_undef-equivalent. */
SV *tie_oh_fetch(pTHX_ SV *self, const char *key, STRLEN klen);

int tie_oh_exists(pTHX_ SV *self, const char *key, STRLEN klen);

SSize_t tie_oh_count(pTHX_ SV *self);

/* ---- iteration ------------------------------------------------- */

/* Caller-owned cursor.  Lets multiple iterators run concurrently
 * without trampling each other - the Perl FIRSTKEY/NEXTKEY path
 * uses $self->[3] for its cursor, which would conflict if a C
 * caller iterated while a Perl `each %h` was half-walked. */
typedef struct {
    SSize_t pos;
    SSize_t end;
} tie_oh_iter_t;

void tie_oh_iter_init(pTHX_ SV *self, tie_oh_iter_t *iter);

/* Advance the cursor.  Returns 1 if a value was produced, 0 at end.
 * `*out_key`/`*out_klen` point into storage owned by `self` and are
 * valid until the next mutation.  `*out_val` is a non-mortal SV
 * (you don't own a refcount); mortalise if you need one. */
int tie_oh_iter_next(pTHX_ SV *self, tie_oh_iter_t *iter,
                     const char **out_key, STRLEN *out_klen,
                     SV **out_val);

/* ---- type guard ------------------------------------------------ */

/* Returns 1 if `sv` is a blessed RV to our impl AV, 0 otherwise.
 * Cheap: a single string compare on the stash name.  Use this
 * before calling the rest of the ABI on a tie object whose class
 * you don't otherwise know. */
int tie_oh_is_instance(pTHX_ SV *sv);

#endif /* TIE_ORDEREDHASH_H */
