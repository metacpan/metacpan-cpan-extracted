#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int call_free(pTHX_ SV* var, MAGIC* magic) {
	dSP;
	PUSHMARK(SP);
	if (SvTYPE(var) < SVt_PVGV) {
		PUSHs(var);
		PUTBACK;
	}
	call_sv(magic->mg_obj, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
	return 0;
}

static const MGVTBL magic_table  = { 0, 0, 0, 0, call_free };

MODULE = Variable::OnDestruct				PACKAGE = Variable::OnDestruct

void
on_destruct(variable, subref)
	SV* variable;
	CV* subref;
	PROTOTYPE: \[$@%&*]&
	CODE:
	if (!SvROK(variable))
		Perl_croak(aTHX_ "Invalid argument!");
	sv_magicext(SvRV(variable), (SV*)subref, PERL_MAGIC_ext, &magic_table, NULL, 0);
