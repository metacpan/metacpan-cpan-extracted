#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_mg_findext
#include "ppport.h"

static int call_free_lifo(pTHX_ SV* var, MAGIC* magic) {
	dSP;
	if (PL_dirty && !sv_isobject(var)) {
		Perl_warn(aTHX_ "Can't call destructor for non-object 0x%p in global destruction\n", var);
		return 1;
	}
	PUSHSTACKi(PERLSI_MAGIC);
	PUSHMARK(SP);
	call_sv(magic->mg_obj, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
	POPSTACK;
	return 0;
}

static int call_free_fifo(pTHX_ SV* var, MAGIC* magic) {
	dSP;
	if (PL_dirty && !sv_isobject(var)) {
		Perl_warn(aTHX_ "Can't call destructor for non-object 0x%p in global destruction\n", var);
		return 1;
	}
	AV* list = (AV*)magic->mg_obj;
	UV counter = 0;
	UV length = av_len(list) + 1;
	PUSHSTACKi(PERLSI_MAGIC);
	for (counter = 0; counter < length; ++counter) {
		SV** current = av_fetch(list, counter, 0);
		if (current && *current) {
			PUSHMARK(SP);
			call_sv(*current, G_VOID | G_DISCARD | G_EVAL | G_KEEPERR);
		}
	}
	POPSTACK;
	return 0;
}

static int call_local(pTHX_ SV* var, MAGIC* magic) {
	return 0;
}

static const MGVTBL lifo_table  = { NULL, NULL, NULL, NULL, call_free_lifo, NULL, NULL, call_local };

static const MGVTBL fifo_table  = { NULL, NULL, NULL, NULL, call_free_fifo, NULL, NULL, call_local };

MODULE = Variable::OnDestruct				PACKAGE = Variable::OnDestruct

void on_destruct(SV* variable, CV* subref)
	PROTOTYPE: \[$@%&*]&
	CODE:
	if (!SvROK(variable))
		Perl_croak(aTHX_ "Invalid argument!");
	MAGIC* magic = sv_magicext(SvRV(variable), (SV*)subref, PERL_MAGIC_ext, &lifo_table, NULL, 0);
	magic->mg_flags |= MGf_LOCAL;


void on_destruct_fifo(SV* variable, CV* subref)
	PROTOTYPE: \[$@%&*]&
	CODE:
	if (!SvROK(variable))
		Perl_croak(aTHX_ "Invalid argument!");
	MAGIC* magic = NULL;
	if (SvMAGICAL(SvRV(variable)) && (magic = mg_findext(SvRV(variable), PERL_MAGIC_ext, &fifo_table)))
		av_push((AV*)magic->mg_obj, SvREFCNT_inc((SV*)subref));
	else {
		AV* list = newAV();
		av_push(list, SvREFCNT_inc((SV*)subref));
		magic = sv_magicext(SvRV(variable), (SV*)list, PERL_MAGIC_ext, &fifo_table, NULL, 0);
		magic->mg_flags |= MGf_LOCAL;
	}
