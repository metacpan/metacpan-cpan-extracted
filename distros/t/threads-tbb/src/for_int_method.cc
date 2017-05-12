
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include "tbb.h"
#include "interpreter_pool.h"

// this function might be made into a helper / base class at some point...
SV* perl_for_int_method::get_invocant( pTHX_ int worker ) {
	IF_DEBUG_PERLCALL( "getting invocant for worker %d; copied=%x", worker, copied );
	copied->grow_to_at_least(worker+1);
	perl_concurrent_slot x = (*copied)[worker];
	if (!x.thingy || (x.owner != my_perl)) {
		IF_DEBUG_PERLCALL( "time to clone!" );
	  
		(*copied)[worker] = perl_concurrent_slot( my_perl, invocant.clone( my_perl ) );
		x = (*copied)[worker];
	}
	return x.dup( my_perl );
}

// body function for for_int_method
void perl_for_int_method::operator()( const perl_tbb_blocked_int& r ) const {

	perl_interpreter_pool::accessor interp;
	tbb_interpreter_pool.grab( interp, this->context );
	IF_DEBUG_PERLCALL("processing range [%d,%d)", r.begin(), r.end());

	SV *isv, *inv, *range;
	perl_for_int_method body_copy = *this;
	perl_tbb_blocked_int r_copy = r;

	// this declares and loads 'my_perl' variables from TLS
	dTHX;

	// declare and copy the stack pointer from global
	dSP;
	IF_DEBUG_PERLCALL( "(dSP ok)" );

	// if we are to be creating temporary values, we need these:
	ENTER;
	SAVETMPS;
	IF_DEBUG_PERLCALL( "(ENTER/SAVETMPS ok)" );

	// take a mental note of the current stack pointer
	PUSHMARK(SP);
	IF_DEBUG_PERLCALL( "(PUSHMARK ok)" );

	isv = newSV(0);
	inv = body_copy.get_invocant( my_perl, interp->second );
	IF_DEBUG_PERLCALL( "got invocant: %x", inv );
	sv_2mortal(inv);
	XPUSHs(inv);
#ifdef DEBUG_PERLCALL_PEEK
	PUTBACK;
	call_pv("Devel::Peek::Dump", G_VOID);
#else
	IF_DEBUG_PERLCALL( "(map_int_body ok)" );

	isv = newSV(0);
	range = sv_setref_pv(isv, "threads::tbb::blocked_int", &r_copy );
	XPUSHs(range);
	IF_DEBUG_PERLCALL( "(blocked_int ok)" );

	//   // set the global stack pointer to the same as our local copy
	PUTBACK;
	IF_DEBUG_PERLCALL( "(PUTBACK ok)" );

	IF_DEBUG_PERLCALL("calling method %s", this->methodname.c_str() );
	call_method(this->methodname.c_str(), G_VOID|G_EVAL);
	//   // in case stack was re-allocated
#endif
	SPAGAIN;
	IF_DEBUG_PERLCALL( "(SPAGAIN ok)" );

	//   // remember to PUTBACK; if we remove values from the stack

	if (SvTRUE(ERRSV)) {
		warn( "error processing range [%d,%d); %s",
		      r.begin(), r.end(), SvPV_nolen(ERRSV) );
		POPs;
		PUTBACK;
	}
	IF_DEBUG_PERLCALL( "($@ ok)" );

	// manual FREETMPS
	sv_setiv(SvRV(range), 0);
	SvREFCNT_dec(range);
	//   // free up those temps & PV return value
	FREETMPS;
	IF_DEBUG_PERLCALL( "(FREETMPS ok)" );
	LEAVE;
	IF_DEBUG_PERLCALL( "(LEAVE ok)" );

	IF_DEBUG_PERLCALL( "done processing range [%d,%d)",
			   r.begin(), r.end() );
};

void perl_for_int_method::free() {
	this->invocant.free();
	delete this->copied;
	this->copied = 0;
}
