#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int S_in_final_destruct(pTHX_ SV* var) {
	int ret = PL_dirty && !sv_isobject(var);
	if (ret)
		Perl_warn(aTHX_ "Can't call destructor for non-object 0x%p in global destruction\n", var);
	return ret;
}
#define in_final_destruct(var) S_in_final_destruct(aTHX_ var)

static int weak_set(pTHX_ SV* var, MAGIC* magic) {
	dSP;
	if (SvOK(var))
		return 0;
	if (in_final_destruct(var))
		return 1;
	PUSHMARK(SP);
	call_sv(magic->mg_obj, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
	return 0;
}

static int strong_free(pTHX_ SV* var, MAGIC* magic) {
	dSP;
	if (in_final_destruct(var))
		return 1;
	PUSHMARK(SP);
	call_sv(magic->mg_obj, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
	return 0;
}

static const MGVTBL weak_magic = { NULL, weak_set, NULL, NULL, NULL };
static const MGVTBL strong_magic = { NULL, NULL, NULL, NULL, strong_free };

MODULE = Variable::OnDestruct::Scoped				PACKAGE = Variable::OnDestruct::Scoped

SV*
on_destruct(reference, subref)
	SV* reference;
	CV* subref;
	PROTOTYPE: \[$@%&*]&
	CODE:
		if (GIMME_V == G_VOID) {
			sv_magicext(reference, (SV*)subref, PERL_MAGIC_ext, &strong_magic, NULL, 0);
			RETVAL = &PL_sv_undef;
		}
		else {
			SV* canary = newSVsv(reference);
			sv_rvweaken(canary);
			SvREADONLY_on(canary);
			sv_magicext(canary, (SV*)subref, PERL_MAGIC_ext, &weak_magic, NULL, 0);
			RETVAL = newRV_noinc(canary);
		}
	OUTPUT:
		RETVAL
