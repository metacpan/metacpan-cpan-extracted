#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>

SV* S_clone_value(pTHX_ SV* original, PerlInterpreter* from) {
	dSP;
	PUSHSTACKi(PERLSI_MAGIC);
	ENTER;
	CLONE_PARAMS* params = Perl_clone_params_new(aTHX, from);
	params->flags = CLONEf_JOIN_IN;
	SAVEPPTR(PL_ptr_table);
	PL_ptr_table = ptr_table_new();
	SAVEDESTRUCTOR_X(Perl_ptr_table_free, PL_ptr_table);
	SAVEDESTRUCTOR(Perl_clone_params_del, params);
	SV* result = sv_dup_inc(original, params);
	LEAVE;
	POPSTACK;
	return result;
}
