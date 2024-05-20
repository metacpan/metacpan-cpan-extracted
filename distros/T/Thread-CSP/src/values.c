#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>

SV* S_clone_value(pTHX_ SV* original) {
	dSP;
	PUSHSTACKi(PERLSI_MAGIC);
	ENTER;
	CLONE_PARAMS params = { 0 };
	params.flags = CLONEf_JOIN_IN;
	SAVEPPTR(PL_ptr_table);
	PL_ptr_table = ptr_table_new();
	SAVEDESTRUCTOR_X(Perl_ptr_table_free, PL_ptr_table);
	SV* result = sv_dup_inc(original, &params);
	LEAVE;
	POPSTACK;
	return result;
}
