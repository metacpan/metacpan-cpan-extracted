#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


MODULE = WeakRef		PACKAGE = WeakRef		

void
weaken(sv)
	SV *sv
CODE:
	sv_rvweaken(sv);

SV *
isweak(sv)
	SV *sv
CODE:
	ST(0) = sv_newmortal();
	if( SvROK(sv) && SvWEAKREF(sv) ) {
		sv_setiv( ST(0), 1 );
	}

