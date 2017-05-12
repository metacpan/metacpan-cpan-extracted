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

MODULE = threads::tbb::blocked_int		PACKAGE = threads::tbb::blocked_int

PROTOTYPES: DISABLE

perl_tbb_blocked_int*
perl_tbb_blocked_int::new( low, high, grain )
	int low;
	int high;
	int grain;
CODE:
	RETVAL = new perl_tbb_blocked_int(low, high, grain);
	IF_DEBUG_LEAK("blocked_int::new; %x", RETVAL);
OUTPUT:
	RETVAL

void
perl_tbb_blocked_int::DESTROY( )
CODE:
	IF_DEBUG_LEAK("blocked_int::DESTROY; %x", THIS);
	if (THIS != NULL)
		delete THIS;

int
perl_tbb_blocked_int::size( )

int
perl_tbb_blocked_int::grainsize( )

int
perl_tbb_blocked_int::begin( )

int
perl_tbb_blocked_int::end( )

bool
perl_tbb_blocked_int::empty( )

bool
perl_tbb_blocked_int::is_divisible( )

