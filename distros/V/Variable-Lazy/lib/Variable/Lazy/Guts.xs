#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int call_remove(pTHX_ SV* var, MAGIC* magic) {
	sv_unmagic(var, PERL_MAGIC_ext);
}

static int call_get(pTHX_ SV* var, MAGIC* magic) {
	dSP;
	int i;
	AV* arguments = (AV*)magic->mg_ptr;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	for(i = 0; i < av_len(arguments); i++)
		XPUSHs(*av_fetch(arguments, i, FALSE));
	PUTBACK;
	call_sv(magic->mg_obj, G_SCALAR);
	SPAGAIN;
	call_remove(aTHX_ var, magic);
	sv_setsv_mg(var, POPs);
	FREETMPS;
	LEAVE;
}

static const MGVTBL magic_table  = { call_get, call_remove, 0, call_remove, 0};

MODULE = Variable::Lazy::Guts				PACKAGE = Variable::Lazy::Guts

SV*
lazy(variable, arguments, subref)
	SV* variable;
	SV* arguments = SvRV(ST(1));
	SV* subref;
	CODE:
		SvREFCNT_inc(arguments);
		call_remove(aTHX_ variable, NULL);
		sv_magicext(variable, (SV*)subref, PERL_MAGIC_ext, &magic_table, (char*)arguments, HEf_SVKEY);
		/* Returns its own first argument */
