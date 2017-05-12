/* method.xs */

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "ppport.h"

#define HINT_KEY "warnings::method"
#define MESSAGE  "Method %s::%s() called as a function"

#define MY_CXT_KEY "warnings::method::_guts" XS_VERSION


typedef struct{
	int global;
} my_cxt_t;
START_MY_CXT;

typedef OP* (*ck_t)(pTHX_ OP*);
static ck_t old_ck_entersub = NULL;


static int
my_scope_enabled(pTHX_ pMY_CXT){
	if(MY_CXT.global){
		return TRUE;
	}

#if PERL_REVISION == 5 && PERL_VERSION >= 10
	if(PL_curcop->cop_hints_hash){
		SV* sv = Perl_refcounted_he_fetch(aTHX_
				PL_curcop->cop_hints_hash, Nullsv,
				HINT_KEY, sizeof(HINT_KEY)-1, FALSE, 0);
		return sv && SvTRUE(sv);
	}

#else
	/* XXX: It may not work with other modules that use HINT_LOCALIZE_HH */
	if(PL_hints & HINT_LOCALIZE_HH){
		//SV** svp = hv_fetchs(GvHV(PL_hintgv), HINT_KEY, FALSE);

		return TRUE; //svp && SvTRUE(*svp);
	}
#endif
	return FALSE;
}

static OP*
method_ck_entersub(pTHX_ OP* o){
	dVAR;
	dMY_CXT;
	register OP* kid;
	if(!(ckWARN(WARN_SYNTAX) && my_scope_enabled(aTHX_ aMY_CXT))){
		goto end;
	}
	kid = cUNOPo->op_first;
	if(kid->op_type != OP_NULL){
		goto end;
	}
	kid = kUNOP->op_first;
	assert(kid->op_type == OP_PUSHMARK);

	/* skip args */
	while(kid->op_sibling){
		kid = kid->op_sibling;
	}

	if(kid->op_type == OP_RV2CV && (kid = kUNOP->op_first)->op_type == OP_GV){
		GV* gv = kGVOP_gv;
		CV* cv;

		assert(gv != NULL);
		assert(SvTYPE(gv) == SVt_PVGV);

		if((cv = GvCV(gv)) && CvMETHOD(cv)){
			gv = CvGV(cv);
			Perl_warner(aTHX_ WARN_SYNTAX,
				MESSAGE,
				HvNAME(GvSTASH(gv)), GvNAME(gv));
		}
	}
	end:
	return old_ck_entersub(aTHX_ o);
}

MODULE = warnings::method		PACKAGE = warnings::method

PROTOTYPES: DISABLE

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.global = FALSE;
	/* install my ck_entersub */
	old_ck_entersub = PL_check[OP_ENTERSUB];
	PL_check[OP_ENTERSUB] = method_ck_entersub;
}

void
_set_mode(mode)
	const char* mode
PREINIT:
	dMY_CXT;
CODE:
	if(strEQ(mode, "-global")){
		MY_CXT.global = TRUE;
	}
	else if(strEQ(mode, "-lexical")){
		MY_CXT.global = FALSE;
	}
	else{
		Perl_croak(aTHX_ "Unknown mode %s", mode);
	}
