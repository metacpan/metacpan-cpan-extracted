#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "mro_compat.h"

#if MRO_COMPAT

#define ISA_CACHE "::XS::MRO::Compat::"

/* call &mro::get_linear_isa */
AV*
mro_compat_mro_get_linear_isa(pTHX_ HV* const stash){
	dVAR;
	GV* cachegv;
	AV* isa;  /* linearized ISA cache */
	SV* gen;  /* package generation */

	assert(stash != NULL);
	assert(SvTYPE(stash) == SVt_PVHV);

	cachegv = *(GV**)hv_fetchs(stash, ISA_CACHE, TRUE);
	if(!isGV(cachegv))
		gv_init(cachegv, stash, ISA_CACHE, sizeof(ISA_CACHE)-1, GV_ADD);

	isa = GvAVn(cachegv);
	gen = GvSVn(cachegv);

	if(SvIOK(gen) && SvIVX(gen) == (IV)mro_get_pkg_gen(stash)){
		return isa; /* returns the cache if available */
	}

	SvREADONLY_off(isa); /* unlock */
	av_clear(isa);


	{
		SV* avref;
		dSP;

		ENTER;
		SAVETMPS;

		PUSHMARK(SP);
		mXPUSHp(HvNAME_get(stash), HvNAMELEN_get(stash));
		PUTBACK;

		call_pv("mro::get_linear_isa", G_SCALAR);

		SPAGAIN;
		avref = POPs;
		PUTBACK;

		if(SvROK(avref) && SvTYPE(SvRV(avref)) == SVt_PVAV){
			AV* const av   = (AV*)SvRV(avref);
			SV** svp       = AvARRAY(av);
			SV** const end = svp + AvFILLp(av) + 1;

			while(svp != end){
				HV* const st = gv_stashsv(*svp, FALSE);
				if(st)
					av_push(isa, newSVpv(HvNAME_get(st), 0));

				svp++;
			}
		}
		else{
			Perl_croak(aTHX_ "panic: mro::get_linear_isa() didn't return an ARRAY reference");
		}

		FREETMPS;
		LEAVE;
	}

	SvREADONLY_on(isa); /* lock */

	sv_setuv(gen, (UV)mro_get_pkg_gen(stash));
	return isa;
}

/* call &mro::method_changed_in */
void
mro_compat_mro_method_changed_in(pTHX_ HV* const stash){
	dVAR;
	dSP;

	assert(stash != NULL);
	assert(SvTYPE(stash) == SVt_PVHV);

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	mXPUSHp(HvNAME_get(stash), HvNAMELEN_get(stash));
	PUTBACK;

	call_pv("mro::method_changed_in", G_VOID | G_DISCARD);

	FREETMPS;
	LEAVE;
}

#endif /* !MRO_COMPAT */

MODULE = XS::MRO::Compat	PACKAGE = XS::MRO::Compat

PROTOTYPES: DISABLE

