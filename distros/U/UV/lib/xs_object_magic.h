#ifndef __XS_OBJECT_MAGIC_H__
#define __XS_OBJECT_MAGIC_H__

#include "perl.h"
#define NEED_newRV_noinc
#include "ppport.h"

START_EXTERN_C

void xs_object_magic_attach_struct (pTHX_ SV *obj, void *ptr);
int  xs_object_magic_detach_struct (pTHX_ SV *obj, void *ptr);
int  xs_object_magic_detach_struct_rv (pTHX_ SV *obj, void *ptr);
int xs_object_magic_has_struct (pTHX_ SV *sv);
int xs_object_magic_has_struct_rv (pTHX_ SV *sv);
void *xs_object_magic_get_struct (pTHX_ SV *sv);
void *xs_object_magic_get_struct_rv (pTHX_ SV *sv);
void *xs_object_magic_get_struct_rv_pretty (pTHX_ SV *sv, const char *name);
MAGIC *xs_object_magic_get_struct_mg (pTHX_ SV *sv);

SV *xs_object_magic_create (pTHX_ void *ptr, HV *stash);

STATIC MGVTBL null_mg_vtbl = {
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    NULL, /* free */
#if MGf_COPY
    NULL, /* copy */
#endif /* MGf_COPY */
#if MGf_DUP
    NULL, /* dup */
#endif /* MGf_DUP */
#if MGf_LOCAL
    NULL, /* local */
#endif /* MGf_LOCAL */
};

void xs_object_magic_attach_struct (pTHX_ SV *sv, void *ptr) {
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &null_mg_vtbl, ptr, 0 );
}

int xs_object_magic_detach_struct (pTHX_ SV *sv, void *ptr) {
    MAGIC *mg, *prevmagic, *moremagic = NULL;
    int removed = 0;

    if (SvTYPE(sv) < SVt_PVMG)
        return 0;

    /* find our magic, remembering the magic before and the magic after */
    for (prevmagic = NULL, mg = SvMAGIC(sv); mg; prevmagic = mg, mg = moremagic) {
        moremagic = mg->mg_moremagic;
        if (mg->mg_type == PERL_MAGIC_ext &&
            mg->mg_virtual == &null_mg_vtbl &&
            ( ptr == NULL || mg->mg_ptr == ptr )) {

            if(prevmagic != NULL) {
                prevmagic->mg_moremagic = moremagic;
            }
            else {
                SvMAGIC_set(sv, moremagic);
            }

            mg->mg_moremagic = NULL;
            Safefree(mg);

            mg = prevmagic;
            removed++;
        }

    }

    return removed;
}

int xs_object_magic_detach_struct_rv (pTHX_ SV *sv, void *ptr){
    if(sv && SvROK(sv)) {
        sv = SvRV(sv);
        return xs_object_magic_detach_struct(aTHX_ sv, ptr);
    }
    return 0;
}

SV *xs_object_magic_create (pTHX_ void *ptr, HV *stash) {
	HV *hv = newHV();
	SV *obj = newRV_noinc((SV *)hv);

	sv_bless(obj, stash);

	xs_object_magic_attach_struct(aTHX_ (SV *)hv, ptr);

	return obj;
}

STATIC MAGIC *xs_object_magic_get_mg (pTHX_ SV *sv) {
    MAGIC *mg;

    if (SvTYPE(sv) >= SVt_PVMG) {
        for (mg = SvMAGIC(sv); mg; mg = mg->mg_moremagic) {
			if (
				(mg->mg_type == PERL_MAGIC_ext)
					&&
				(mg->mg_virtual == &null_mg_vtbl)
			) {
				return mg;
			}
        }
    }

    return NULL;
}

int xs_object_magic_has_struct (pTHX_ SV *sv) {
        MAGIC *mg = xs_object_magic_get_mg(aTHX_ sv);
        return mg ? 1 : 0;
}

int xs_object_magic_has_struct_rv (pTHX_ SV *sv) {
        if( sv && SvROK(sv) ){
                sv = SvRV(sv);
                MAGIC *mg = xs_object_magic_get_mg(aTHX_ sv);
                return mg ? 1 : 0;
        }
        return 0;
}

void *xs_object_magic_get_struct (pTHX_ SV *sv) {
	MAGIC *mg = xs_object_magic_get_mg(aTHX_ sv);

	if ( mg )
		return mg->mg_ptr;
	else
		return NULL;
}

void *xs_object_magic_get_struct_rv_pretty (pTHX_ SV *sv, const char *name) {
	if ( sv && SvROK(sv) ) {
		MAGIC *mg = xs_object_magic_get_mg(aTHX_ SvRV(sv));

		if ( mg )
			return mg->mg_ptr;
		else
			croak("%s does not have a struct associated with it", name);
	} else {
		croak("%s is not a reference", name);
	}
}

void *xs_object_magic_get_struct_rv (pTHX_ SV *sv) {
	return xs_object_magic_get_struct_rv_pretty(aTHX_ sv, "argument");
}

END_EXTERN_C

#endif
