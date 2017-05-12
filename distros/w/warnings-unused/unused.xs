/* warnings-unused/unused.xs */

/*
See also:
	op.h
	op.c
	pad.h
	pad.c
	pp.h
	pp.c
	toke.c
	perlguts.pod
	perlhack.pod
	perlapi.pod
*/

#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <keywords.h> /* KEY_my, KEY_our */

#include "ppport.h"


/* Since these APIs are not public, the definitions are a little complicated */

#if  PERL_BCDVERSION >= 0x5010000
#	undef  PL_tokenbuf /* defined in ppport.h */
#   undef  PL_in_my    /* defined in ppport.h */
#	define PL_tokenbuf (PL_parser->tokenbuf)
#	define PL_in_my    (PL_parser->in_my)
#else
#	ifndef PL_tokenbuf
#		define PL_tokenbuf PL_Itokenbuf
#		define PL_in_my    PL_Iin_my
#	endif
#endif

#define HINT_KEY "warnings::unused"

#define SCOPE_KEY ((UV)PL_savestack_ix)

#define MY_CXT_KEY "warnings::unused::_guts" XS_VERSION /* for backward compatibility */

#define WARN_UNUSED WARN_ONCE


#define MESSAGE "Unused variable %s %s at %s line %"IVdf".\n"

typedef struct{
	AV* vars;
	SV* scope_depth;
	U32 scope_depth_hash;

	bool global;
} my_cxt_t;
START_MY_CXT;

#ifdef WU_DEBUGGING
#define dump_vars() wl_dump_vars(aTHX)
static void
wl_dump_vars(pTHX){
	dMY_CXT;
	I32 const len = av_len(MY_CXT.vars)+1;
	I32 i;

	PerlIO_printf(PerlIO_stderr(), "vars at %s line %"IVdf".\n", OutCopFILE(PL_curcop), (IV)CopLINE(PL_curcop));
	for(i = 1; i < len; i++){
		HV* const hv = (HV*)SvRV(*av_fetch(MY_CXT.vars, i, FALSE));
		HE* he;

		PerlIO_printf(PerlIO_stderr(), "  var table:\n");
		hv_iterinit(hv);
		while((he = hv_iternext(hv))){
			if(SvOK(HeVAL(he))){
				if(SvPOK(HeVAL(he))){
					PerlIO_printf(PerlIO_stderr(), "    %s unused\n", HeKEY(he));
				}
				else{
					PerlIO_printf(PerlIO_stderr(), "    %s=%"UVuf"\n", HeKEY(he), SvUVX(HeVAL(he)));
				}
			}
			else{
				PerlIO_printf(PerlIO_stderr(), "    %s\n", HeKEY(he));
			}
		}
	}
}
#else /* !WU_DEBUGGING */
#define dump_vars() NOOP
#endif

#define wl_enabled() (ckWARN(WARN_UNUSED) && wl_scope_enabled(aTHX_ aMY_CXT))

static int
wl_scope_enabled(pTHX_ pMY_CXT){
	if(MY_CXT.global){
		return TRUE;
	}

#if   PERL_BCDVERSION >= 0x5014000
	if(PL_curcop->cop_hints_hash){
		SV* const sv = Perl_refcounted_he_fetch_pvn(aTHX_
				PL_curcop->cop_hints_hash,
				HINT_KEY, sizeof(HINT_KEY)-1, 0U, 0);
		return sv && SvTRUE(sv);
	}
#elif PERL_BCDVERSION >= 0x5010000
	if(PL_curcop->cop_hints_hash){
		SV* const sv = Perl_refcounted_he_fetch(aTHX_
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

static UV
wl_fetch_scope_depth(pTHX_ pMY_CXT_ HV* const tab){
	HE* const he = hv_fetch_ent(tab, MY_CXT.scope_depth, FALSE, MY_CXT.scope_depth_hash);
	assert(he);

	return SvUVX(HeVAL(he));
}

static HV*
wl_push_scope(pTHX_ pMY_CXT_ UV const key){
	HV* const hv = newHV();

	(void)hv_store_ent(hv, MY_CXT.scope_depth, newSVuv(key), MY_CXT.scope_depth_hash);
	av_push(MY_CXT.vars, newRV_noinc((SV*)hv));

	return hv;
}

static void
wl_flush(pTHX_ UV const key){
	dMY_CXT;
	IV i = av_len(MY_CXT.vars) + 1;
	while(--i > 0){
		SV* const hvref = *av_fetch(MY_CXT.vars, i, FALSE);
		HV* const tab   = (HV*)SvRV(hvref);
		HE* he;

		assert(SvTYPE(tab) == SVt_PVHV);

		if(wl_fetch_scope_depth(aTHX_ aMY_CXT_ tab) <= key){
			break;
		}

		/* each and warn */
		hv_iterinit(tab);

		while( (he = hv_iternext(tab)) ){
			if(SvPOK(HeVAL(he))){
				Perl_warner(aTHX_ WARN_UNUSED, "%" SVf, HeVAL(he));
			}
		}

		av_pop(MY_CXT.vars);

		SvREFCNT_dec(hvref);
	}
}

static HV*
wl_fetch_tab(pTHX_ pMY_CXT_ UV const key){
	SV* top = *av_fetch(MY_CXT.vars, -1, FALSE);
	HV* tab;
	UV top_depth;

	assert(SvROK(top));
	assert(SvTYPE(SvRV(top)) == SVt_PVHV);

	tab = (HV*)SvRV(top);

	top_depth = wl_fetch_scope_depth(aTHX_ aMY_CXT_ tab);

	if(top_depth < key){
		tab = wl_push_scope(aTHX_ aMY_CXT_ key);
	}
	else{ /*top_depth >= key */

		/* pop scope if needed */
		while(top_depth > key){
			HE* he;

			hv_iterinit(tab);

			while( (he = hv_iternext(tab)) ){
				if(SvPOK(HeVAL(he))){ /* skip the SCOPE_DEPTH meta data */
					Perl_warner(aTHX_ WARN_UNUSED, "%" SVf, HeVAL(he));
				}
			}

			av_pop(MY_CXT.vars);
			SvREFCNT_dec(top);

			top = *av_fetch(MY_CXT.vars, -1, FALSE);
			tab = (HV*)SvRV(top);
			top_depth = wl_fetch_scope_depth(aTHX_ aMY_CXT_ tab);
		}
	}

	assert(SvTYPE(tab) == SVt_PVHV);

	return tab;
}

static Perl_check_t old_ck_padsv  = NULL;
static Perl_check_t old_ck_padany = NULL;
static OP*
wl_ck_padany(pTHX_ OP* const o){
	if(PL_in_my != KEY_our){
		dMY_CXT;
		const char* const name = PL_tokenbuf;
		STRLEN const namelen = strlen(name);
		HV* hv = wl_fetch_tab(aTHX_ aMY_CXT_ SCOPE_KEY);

#if 0
		/* NOTE: The last resort is to consider PL_hints */
		PerlIO_printf(PerlIO_stderr(),
			"[%d] $^H=0x%x at %s line %"IVdf".\n",
			(int)SCOPE_KEY, (unsigned)PL_hints, OutCopFILE(PL_curcop), (IV)CopLINE(PL_curcop));
#endif
		/* declaration */
		if(PL_in_my){
			SV** const svp = hv_fetch(hv, name, namelen, FALSE);
			SV* msg;

			if(svp && SvOK(*svp)){ /* shadowing */
				Perl_warner(aTHX_ WARN_UNUSED, "%" SVf, *svp);
			}

			if(wl_enabled()){

				msg = Perl_newSVpvf(aTHX_
					MESSAGE,
					PL_in_my == KEY_my ? "my" : "state",
					name,
					OutCopFILE(PL_curcop), (IV)CopLINE(PL_curcop));
			}
			else{
				msg = &PL_sv_undef; /* marks but doesn't complain about it */
			}

			(void)hv_store(hv, name, namelen, msg, 0U);
		}
		/* use */
		else{
			SV** svp;
			I32 i = av_len(MY_CXT.vars)+1;

			/* search for the variable until it's found */
			while(!(svp = hv_fetch(hv, name, namelen, FALSE))){
				if(i <= 0) break;

				--i;
				hv = (HV*)SvRV( AvARRAY(MY_CXT.vars)[i] );
			}

			if(svp && SvOK(*svp)){ /* found */
				SvREFCNT_dec(*svp);
				*svp = &PL_sv_undef; /* mark as used */
			}

		}

		//dump_vars();
	}
	return o->op_type == OP_PADSV
		? old_ck_padsv (aTHX_ o)
		: old_ck_padany(aTHX_ o);
}

static Perl_check_t old_ck_leaveloop = NULL;
static Perl_check_t old_ck_leavesub  = NULL;
static Perl_check_t old_ck_leaveeval = NULL;

/* flush on the end of the scope */
static OP*
wl_ck_leave(pTHX_ OP* const o){
	Perl_check_t ck_proc;

	wl_flush(aTHX_ SCOPE_KEY);

	switch(o->op_type){
	case OP_LEAVELOOP:
		ck_proc = old_ck_leaveloop;
		break;
	case OP_LEAVESUB:
		ck_proc = old_ck_leavesub;
		break;
	case OP_LEAVEEVAL:
		ck_proc = old_ck_leaveeval;
		break;
	default:
		ck_proc = NULL;
	}
	assert(ck_proc);

	//PerlIO_printf(PerlIO_stderr(), "[%s] at %s line %"IVdf".\n", OP_NAME(o), OutCopFILE(PL_curcop), (IV)CopLINE(PL_curcop));

	return ck_proc(aTHX_ o);
}

MODULE = warnings::unused		PACKAGE = warnings::unused

PROTOTYPES: DISABLE

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.vars = newAV();
	MY_CXT.scope_depth = newSVpvs("scope_depth");
	PERL_HASH(MY_CXT.scope_depth_hash, "scope_depth", sizeof("scope_depth")-1);
	MY_CXT.global = FALSE;
	/* the stack of varible tables */
	/* the root variable table */
	wl_push_scope(aTHX_ aMY_CXT_ (UV)1);
	/* install check hooks */
	{
		old_ck_padany = PL_check[OP_PADANY];
		PL_check[OP_PADANY] = wl_ck_padany;

		old_ck_padsv = PL_check[OP_PADSV];
		PL_check[OP_PADSV] = wl_ck_padany;

		/* leave scope */
		old_ck_leavesub = PL_check[OP_LEAVESUB];
		PL_check[OP_LEAVESUB] = wl_ck_leave;

		old_ck_leaveeval = PL_check[OP_LEAVEEVAL];
		PL_check[OP_LEAVEEVAL] = wl_ck_leave;

		old_ck_leaveloop = PL_check[OP_LEAVELOOP];
		PL_check[OP_LEAVELOOP] = wl_ck_leave;
	}
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


void
END(...)
CODE:
	PERL_UNUSED_VAR(items);
	wl_flush(aTHX_ 0);
