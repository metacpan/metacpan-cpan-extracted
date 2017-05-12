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

MODULE = threads::tbb::for_int_method	PACKAGE = threads::tbb::for_int_method

PROTOTYPES: DISABLE

perl_for_int_method*
new( CLASS, context, inv_sv, methodname )
	char* CLASS;
	perl_tbb_init* context;
	SV* inv_sv;
	std::string methodname;
  CODE:
	RETVAL = new perl_for_int_method( my_perl, context, inv_sv, methodname );
  OUTPUT:
	RETVAL

void
parallel_for(self, range)
	perl_for_int_method* self;
	perl_tbb_blocked_int* range;
  CODE:
	perl_tbb_blocked_int range_copy = perl_tbb_blocked_int(*range);
	perl_for_int_method body_copy = perl_for_int_method(*self);
	parallel_for( range_copy, body_copy );

void
perl_for_int_method::DESTROY()
CODE:
	IF_DEBUG_LEAK("for_int_method::DESTROY; %x", THIS);
	if (THIS != NULL)
		THIS->free();
		delete THIS;
