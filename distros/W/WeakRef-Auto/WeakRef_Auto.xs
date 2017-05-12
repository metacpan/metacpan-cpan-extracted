#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef SV* SVREF;

static int
autoweak_set(pTHX_ SV* const sv, MAGIC* const mg){
	PERL_UNUSED_ARG(mg);

	if(!SvWEAKREF(sv)){
		sv_rvweaken(sv);
	}

	return 0; /* success */
}

const MGVTBL autoweaker_vtbl = {
	NULL, /* get */
	autoweak_set,
	NULL, /* len */
	NULL, /* clear */
	NULL, /* free */
	NULL, /* copy */
	NULL, /* dup */
#ifdef MGf_LOCAL
	NULL,  /* local */
#endif
};


static bool
isautoweak(pTHX_ SV* const sv){
	if(SvMAGICAL(sv)){
		const MAGIC* mg;
		for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
			if(mg->mg_virtual == &autoweaker_vtbl){
				return TRUE;
			}
		}
	}
	return FALSE;
}

MODULE = WeakRef::Auto	PACKAGE = WeakRef::Auto

PROTOTYPES: DISABLE

void
autoweaken(SVREF value)
PROTOTYPE: \$
CODE:
	SvGETMAGIC(value);

	if(SvREADONLY(value)){
		Perl_croak(aTHX_ PL_no_modify);
	}

	if(!isautoweak(aTHX_ value)){
		if(SvTIED_mg(value, PERL_MAGIC_tiedscalar) || SvTIED_mg(value, PERL_MAGIC_tiedelem)){
			if(ckWARN(WARN_MISC))
				Perl_warner(aTHX_ packWARN(WARN_MISC), "autoweaken() does not work with tied variables");
			XSRETURN_EMPTY;
		}

		sv_magicext(value, NULL, PERL_MAGIC_ext, &autoweaker_vtbl, NULL, 0);
		SvSETMAGIC(value);
	}
