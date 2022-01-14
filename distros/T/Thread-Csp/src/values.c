#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#define NEED_mg_findext
#include "ppport.h"

#ifndef sv_derived_from_pvn
#define sv_derived_from_pvn(sv, name, namelen, flags) sv_derived_from(sv, name)
#endif

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

SV* S_object_to_sv(pTHX_ void* object, HV* stash, const MGVTBL* magic_table, UV flags) {
	SV* referent = newSV(0);
	MAGIC* magic = sv_magicext(referent, NULL, PERL_MAGIC_ext, magic_table, object, 0);
	magic->mg_flags |= flags;
	return sv_bless(newRV_noinc(referent), stash);
}

MAGIC* S_sv_to_magic(pTHX_ SV* sv, const char* name, STRLEN namelen, const MGVTBL* magic_table) {
	if (!sv_derived_from_pvn(sv, name, namelen, 0))
		Perl_croak(aTHX_ "Object is not a %s", name);
	MAGIC* magic = SvMAGICAL(SvRV(sv)) ? mg_findext(SvRV(sv), PERL_MAGIC_ext, magic_table) : NULL;
	if (magic)
		return magic;
	else
		Perl_croak(aTHX_ "%s object is lacking magic", name);
}
