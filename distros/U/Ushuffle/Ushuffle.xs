#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>

#include "ushufflelib/ushuffle.h"

/*
 * The uShuffle library keeps the k-let graph of a single sequence in
 * file-level statics. Every Shuffler therefore owns a copy of its sequence,
 * and loaded_id records whose graph the library currently holds, so that the
 * graph is rebuilt when another Shuffler or a plain shuffle() call has
 * replaced it in the meantime. Ids start at 1 and are never reused; 0 means
 * "no Shuffler".
 *
 * The same statics, and the random number generator, are shared by all
 * interpreter threads of the process. LIBRARY_LOCK serializes every use of
 * them. Nothing that can croak may run while the lock is held.
 */

typedef struct {
	char *seq;
	int len;
	int k;
	UV id;
} shuffler;

typedef shuffler *Ushuffle__Shuffler;

static UV next_id = 1;
static UV loaded_id = 0;
static int booted = 0;

#ifdef USE_ITHREADS
static perl_mutex library_mutex;
#define LIBRARY_LOCK_INIT MUTEX_INIT(&library_mutex)
#define LIBRARY_LOCK      MUTEX_LOCK(&library_mutex)
#define LIBRARY_UNLOCK    MUTEX_UNLOCK(&library_mutex)
#else
#define LIBRARY_LOCK_INIT NOOP
#define LIBRARY_LOCK      NOOP
#define LIBRARY_UNLOCK    NOOP
#endif

/* a tied or otherwise magical argument is fetched exactly once */
static SV *fetched(pTHX_ SV *sv) {
	return SvGMAGICAL(sv) ? sv_2mortal(newSVsv(sv)) : sv;
}

static const char *checked_sequence(pTHX_ SV *sv, int *len) {
	const char *s;
	STRLEN n;

	sv = fetched(aTHX_ sv);
	if (!SvOK(sv))
		croak("Ushuffle: sequence is undefined");
	s = SvPVbyte(sv, n);
	if (n > (STRLEN) INT_MAX)
		croak("Ushuffle: sequence is too long");
	/* the library compares k-lets with strncmp */
	if (memchr(s, '\0', n))
		croak("Ushuffle: sequence contains a NUL byte");
	*len = (int) n;
	return s;
}

static int checked_k(pTHX_ SV *sv) {
	IV k;

	sv = fetched(aTHX_ sv);
	k = SvOK(sv) ? SvIV(sv) : 0;
	if (k < 1)
		croak("Ushuffle: k must be a positive integer");
	return k > INT_MAX ? INT_MAX : (int) k;
}

/*
 * One shuffle of seq. id is that of the Shuffler owning seq, whose graph is
 * reused if the library still holds it, or 0 for a sequence without one.
 */
static SV *next_shuffle(pTHX_ const char *seq, int len, int k, UV id) {
	SV *t;

	if (len == 0)
		return newSVpvn("", 0);
	t = newSV(len);
	SvPOK_only(t);
	LIBRARY_LOCK;
	if (id == 0 || loaded_id != id) {
		shuffle1(seq, len, k);
		loaded_id = id;
	}
	shuffle2(SvPVX(t));
	LIBRARY_UNLOCK;
	SvPVX(t)[len] = '\0';
	SvCUR_set(t, len);
	return t;
}

static void seed_from_clock(pTHX) {
	struct timeval tv;

	gettimeofday(&tv, NULL);
	srandom((unsigned int) ((unsigned long) tv.tv_sec
		^ ((unsigned long) tv.tv_usec << 12)
		^ ((unsigned long) PerlProc_getpid() << 16)));
}

MODULE = Ushuffle		PACKAGE = Ushuffle

PROTOTYPES: DISABLE

BOOT:
	/* runs again in a thread that loads the module its parent had not loaded */
	if (!booted) {
		LIBRARY_LOCK_INIT;
		seed_from_clock(aTHX);
		booted = 1;
	}

SV *
shuffle(sequence, k)
	SV *sequence
	SV *k
    PREINIT:
	const char *s;
	int len, let;
    CODE:
	let = checked_k(aTHX_ k);
	s = checked_sequence(aTHX_ sequence, &len);
	RETVAL = next_shuffle(aTHX_ s, len, let, 0);
    OUTPUT:
	RETVAL

void
set_seed(seed)
	UV seed
    CODE:
	LIBRARY_LOCK;
	srandom((unsigned int) seed);
	LIBRARY_UNLOCK;

MODULE = Ushuffle		PACKAGE = Ushuffle::Shuffler

SV *
new(class, sequence, k)
	SV *class
	SV *sequence
	SV *k
    PREINIT:
	shuffler *self;
	const char *name, *s;
	int len, let;
    CODE:
	/* called on an object, new makes another object of the same class */
	if (SvROK(class) && SvOBJECT(SvRV(class)))
		name = HvNAME(SvSTASH(SvRV(class)));
	else
		name = SvOK(class) ? SvPV_nolen(class) : NULL;
	if (!name || !*name)
		croak("Ushuffle::Shuffler::new: class name expected");
	let = checked_k(aTHX_ k);
	s = checked_sequence(aTHX_ sequence, &len);
	Newx(self, 1, shuffler);
	self->seq = savepvn(s, len);
	self->len = len;
	self->k = let;
	LIBRARY_LOCK;
	self->id = next_id++;
	LIBRARY_UNLOCK;
	RETVAL = sv_setref_pv(newSV(0), name, (void *) self);
    OUTPUT:
	RETVAL

SV *
shuffle(self)
	Ushuffle::Shuffler self
    CODE:
	RETVAL = next_shuffle(aTHX_ self->seq, self->len, self->k, self->id);
    OUTPUT:
	RETVAL

SV *
sequence(self)
	Ushuffle::Shuffler self
    CODE:
	RETVAL = newSVpvn(self->seq, self->len);
    OUTPUT:
	RETVAL

int
k(self)
	Ushuffle::Shuffler self
    CODE:
	RETVAL = self->k;
    OUTPUT:
	RETVAL

void
DESTROY(object)
	SV *object
    PREINIT:
	SV *referent;
	shuffler *self;
    CODE:
	/* tolerant, since it also runs during global destruction; the pointer
	 * is zeroed so that an explicit DESTROY call cannot free twice */
	if (!SvROK(object) || !sv_derived_from(object, "Ushuffle::Shuffler"))
		XSRETURN_EMPTY;
	referent = SvRV(object);
	self = INT2PTR(shuffler *, SvIV(referent));
	if (self) {
		Safefree(self->seq);
		Safefree(self);
		sv_setiv(referent, 0);
	}

int
CLONE_SKIP(...)
    CODE:
	/* a Shuffler is a bare pointer; cloning it into a thread would free it twice */
	RETVAL = 1;
    OUTPUT:
	RETVAL
