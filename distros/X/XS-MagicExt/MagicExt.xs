#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#include "magic_ext.h"

MAGIC*
magic_ext_mgx_attach(pTHX_ SV* const sv, MGVTBL* const vtbl, SV* const obj, void* const ptr, I32 const len){
	MAGIC* mg;

	assert(sv != NULL);
	assert(vtbl != NULL);

	mg = sv_magicext(sv, obj, PERL_MAGIC_ext, vtbl, ptr, len);

	if(obj){
		SvREFCNT_dec(obj);
	}

	if(ptr && len == HEf_SVKEY){
		SvREFCNT_dec((SV*)ptr);
	}

	return mg;
}

MAGIC*
magic_ext_mgx_find(pTHX_ SV* const sv, const MGVTBL* const vtbl, I32 const flags){
	MAGIC* mg;

	assert(sv != NULL);
	assert(vtbl != NULL);

	for(mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic){
		if(mg->mg_virtual == vtbl){
			assert(mg->mg_type == PERL_MAGIC_ext);
			return mg;
		}
	}

	if(flags & MGXf_CROAK_IF_NOT_FOUND){
		croak("MAGIC(0x%p) not found", vtbl);
	}
	return NULL;
}

void
magic_ext_mgx_detach(pTHX_ SV* const sv, const MGVTBL* const vtbl){
	MAGIC*  mg;
	MAGIC** mgp;

	assert(sv != NULL);
	assert(vtbl != NULL);

	if (!SvMAGICAL(sv)){
		return;
	}

	mgp = &SvMAGIC(sv);
	for (mg = *mgp; mg; mg = *mgp) {
		if (mg->mg_virtual == vtbl) {
			const MGVTBL* const vtbl = mg->mg_virtual;
			assert(mg->mg_type == PERL_MAGIC_ext);

			if (vtbl && vtbl->svt_free){
				CALL_FPTR(vtbl->svt_free)(aTHX_ sv, mg);
			}

			if (mg->mg_ptr) {
				if (mg->mg_len > 0){
					Safefree(mg->mg_ptr);
				}
				else if (mg->mg_len == HEf_SVKEY){
					SvREFCNT_dec((SV*)mg->mg_ptr);
				}
			}
			if (mg->mg_flags & MGf_REFCOUNTED)
				SvREFCNT_dec(mg->mg_obj);

			*mgp = mg->mg_moremagic;
			Safefree(mg);
		}
		else{
			mgp = &mg->mg_moremagic;
		}
	}
	if (!SvMAGIC(sv)) {
		SvMAGICAL_off(sv);
		SvFLAGS(sv) |= (SvFLAGS(sv) & (SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
	}
}

MODULE = XS::MagicExt	PACKAGE = XS::MagicExt

PROTOTYPES: DISABLE
