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

MODULE = threads::tbb::for_int_array_func	PACKAGE = threads::tbb::for_int_array_func

PROTOTYPES: DISABLE

perl_for_int_array_func*
perl_for_int_array_func::new( context, array, funcname )
	perl_tbb_init* context;
	perl_concurrent_vector* array;
	std::string funcname;

perl_concurrent_vector*
perl_for_int_array_func::get_array()
CODE:
	RETVAL = THIS->get_array();
	RETVAL->refcnt++;
OUTPUT:
	RETVAL

void
parallel_for(self, range)
        perl_for_int_array_func* self;
        perl_tbb_blocked_int* range;
  CODE:
        perl_tbb_blocked_int range_copy = perl_tbb_blocked_int(*range);
        perl_for_int_array_func body_copy = perl_for_int_array_func(*self);
        parallel_for( range_copy, body_copy );

void
perl_for_int_array_func::DESTROY()
CODE:
	IF_DEBUG_LEAK("for_int_array_func::DESTROY; %x", THIS);
	if (THIS != NULL)
		delete THIS;



