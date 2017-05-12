
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include "tbb.h"
#include "interpreter_pool.h"
//static bool aTHX;

// a parallel_for body class that works with blocked_int range type
// only.
void perl_for_int_array_func::operator()( const perl_tbb_blocked_int& r ) const {
	perl_interpreter_pool::accessor interp;
	raw_thread_id thread_id = get_raw_thread_id();
	tbb_interpreter_pool.grab( interp, this->context );

	SV *isv, *range, *array_sv;
	perl_tbb_blocked_int r_copy = r;
	perl_concurrent_vector* array = xarray;
	IF_DEBUG_LEAK("my perl_tbb_blocked_int: %x", &r);

	// this declares and loads 'my_perl' variables from TLS
	dTHX;

	// declare and copy the stack pointer from global
	dSP;

	// if we are to be creating temporary values, we need these:
	ENTER;
	SAVETMPS;

	//   // take a mental note of the current stack pointer
	PUSHMARK(SP);

	isv = newSV(0);
	range = sv_setref_pv(isv, "threads::tbb::blocked_int", &r_copy );
	XPUSHs(range);

	isv = newSV(0);
	array_sv = sv_setref_pv(isv, "threads::tbb::concurrent::array", array );
	array->refcnt++;
	sv_2mortal(array_sv);
	XPUSHs(array_sv);

	//   // set the global stack pointer to the same as our local copy
	PUTBACK;

	IF_DEBUG_THR("calling %s with [%d,%d)",
		     this->funcname.c_str(), r.begin(), r.end() );
	call_pv(this->funcname.c_str(), G_VOID|G_EVAL);
	//   // in case stack was re-allocated
	SPAGAIN;

	//   // remember to PUTBACK; if we remove values from the stack

	if (SvTRUE(ERRSV)) {
		warn( "error processing range [%d,%d); %s",
		      r.begin(), r.end(), SvPV_nolen(ERRSV) );
		POPs;
		PUTBACK;
	}

	sv_setiv(SvRV(range), 0);
	SvREFCNT_dec(range);
	//   // free up those temps & PV return value
	FREETMPS;
	LEAVE;

	IF_DEBUG_PERLCALL( "done processing range [%d,%d)",
			   r.begin(), r.end() );
};
