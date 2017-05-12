#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}
#endif

/* include your class headers here */
#include "tbb.h"
#include "interpreter_pool.h"

static ptr_to_int tbb_refcounter_count;

MODULE = threads::tbb::refcounter	PACKAGE = threads::tbb::refcounter

PROTOTYPES: DISABLE

void
pvmg_rc_inc( thingy )
	SV* thingy;
CODE:
	if (SvROK(thingy) && SvTYPE(SvRV(thingy)) == SVt_PVMG) {
		void* xs_ptr = (void*)SvIV((SV*)SvRV(thingy));
		IF_DEBUG_REFCOUNTER("increasing refcount of %x", xs_ptr);
		ptr_to_int::accessor objlock;
		bool found = tbb_refcounter_count.find( objlock, xs_ptr );
		if (!found) {
			IF_DEBUG_REFCOUNTER("inserting entry for %x", xs_ptr);
			tbb_refcounter_count.insert( objlock, xs_ptr );
			(*objlock).second = 0;
		}
		(*objlock).second++;
		IF_DEBUG_REFCOUNTER("refcount is now %d", (*objlock).second);
		XSRETURN_IV(42);
	}

void
pvmg_rc_dec( thingy )
	SV* thingy;
PREINIT:
	bool call_destroy = true;
CODE:
	if (SvROK(thingy) && SvTYPE(SvRV(thingy)) == SVt_PVMG) {
		void* xs_ptr = (void*)SvIV((SV*)SvRV(thingy));
		IF_DEBUG_REFCOUNTER("decreasing refcount of %x", xs_ptr);
		ptr_to_int::accessor objlock;
		bool found = tbb_refcounter_count.find( objlock, xs_ptr );
		int rc = 0;
		if (found) {
			IF_DEBUG_REFCOUNTER("refcount was %d", (*objlock).second);
			rc = --( (*objlock).second );
			if (rc <= 0) {
				IF_DEBUG_REFCOUNTER("removing entry from hash");
				tbb_refcounter_count.erase( objlock );
			}
		}
		if (rc > 0) {
			IF_DEBUG_REFCOUNTER("not chaining old DESTROY for %x", xs_ptr);
			call_destroy = false;
		}
		else {
			IF_DEBUG_REFCOUNTER("chaining old DESTROY for %x", xs_ptr);
		}
	}
	else {
	}
	if (call_destroy) {
		PUSHMARK(SP);
		XPUSHs( thingy );
		PUTBACK;

		IF_DEBUG_REFCOUNTER("calling _DESTROY_tbbrc on %x", (void*)SvRV(thingy));
		call_method("_DESTROY_tbbrc", G_DISCARD);
	}

void
refcount( thingy )
	SV* thingy;
PREINIT:
	int rc = -1337;
CODE:
	if (SvROK(thingy) && SvTYPE(SvRV(thingy)) == SVt_PVMG) {
		void* xs_ptr = (void*)SvIV((SV*)SvRV(thingy));
		IF_DEBUG_REFCOUNTER("fetching refcount for %x", xs_ptr);
		ptr_to_int::const_accessor objlock;
		bool found = tbb_refcounter_count.find( objlock, xs_ptr );
		if (found) {
			rc = (*objlock).second;
			IF_DEBUG_REFCOUNTER("refcount for %x is %d", xs_ptr, rc);
		}
		else {
			IF_DEBUG_REFCOUNTER("no refcount found for %x", xs_ptr);
		}
	}
	else {
		IF_DEBUG_REFCOUNTER("refcount called on non-PVMG object %x", thingy);
	}
	if (rc == -1337) {
		XSRETURN_UNDEF;
	}
	else {
		XSRETURN_IV(rc);
	}
