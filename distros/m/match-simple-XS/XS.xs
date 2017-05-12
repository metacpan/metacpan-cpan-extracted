#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#define sv_defined(sv) (sv && (SvIOK(sv) || SvNOK(sv) || SvPOK(sv) || SvROK(sv)))

#ifndef SvRXOK

#define SvRXOK(sv) is_regexp(aTHX_ sv)

STATIC int
is_regexp (pTHX_ SV* sv) {
	SV* tmpsv;
	
	if (SvMAGICAL(sv))
	{
		mg_get(sv);
	}
	
	if (SvROK(sv)
	&& (tmpsv = (SV*) SvRV(sv))
	&& SvTYPE(tmpsv) == SVt_PVMG 
	&& (mg_find(tmpsv, PERL_MAGIC_qr)))
	{
		return TRUE;
	}
	
	return FALSE;
}

#endif

bool
_match (SV *const a, SV *const b)
{
	if (!sv_defined(b))
	{
		return !sv_defined(a);
	}
	
	if (!SvROK(b))
	{
		return sv_eq(a, b);
	}
	
	if (SvRXOK(b))
	{
		dSP;
		int count;
		bool r;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(a);
		XPUSHs(b);
		PUTBACK;
		count = call_pv("match::simple::XS::_regexp", G_SCALAR);
		SPAGAIN;
		r = POPi;
		PUTBACK;
		FREETMPS;
		LEAVE;
		return (r != 0);
	}
	
	if (sv_isobject(b))
	{
		if (sv_derived_from(b, "Type::Tiny"))
		{
			dSP;
			int count;
			SV *ret;
			bool ret_truth;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			XPUSHs(b);
			XPUSHs(a);
			PUTBACK;
			count = call_method("check", G_SCALAR);
			SPAGAIN;
			ret = POPs;
			ret_truth = SvTRUE(ret);
			PUTBACK;
			FREETMPS;
			LEAVE;
			return ret_truth;
		}
		
		dSP;
		int count;
		SV *ret;
		bool can;
		SV *method_name = newSVpv("MATCH", 0);
		
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(b);
		XPUSHs(method_name);
		PUTBACK;
		count = call_method("can", G_SCALAR);
		SPAGAIN;
		ret = POPs;
		can = SvTRUE(ret);
		PUTBACK;
		FREETMPS;
		LEAVE;
		
		if (can)
		{
			bool ret_truth;
			
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			XPUSHs(b);
			XPUSHs(a);
			PUTBACK;
			count = call_method("MATCH", G_SCALAR);
			SPAGAIN;
			ret = POPs;
			ret_truth = SvTRUE(ret);
			PUTBACK;
			FREETMPS;
			LEAVE;
			return ret_truth;
		}
		
		bool r;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(a);
		XPUSHs(b);
		PUTBACK;
		count = call_pv("match::simple::XS::_smartmatch", G_SCALAR);
		SPAGAIN;
		r = POPi;
		PUTBACK;
		FREETMPS;
		LEAVE;
		return (r != 0);
	}
	
	SV *sv_b = SvRV(b);
	
	if (SvTYPE(sv_b) == SVt_PVCV)
	{
		dSP;
		int count;
		SV *ret;
		bool ret_truth;
		
		SAVESPTR(GvSV(PL_defgv));
		
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(a);
		PUTBACK;
		GvSV(PL_defgv) = a;
		count = call_sv(b, G_SCALAR);
		SPAGAIN;
		ret = POPs;
		ret_truth = SvTRUE(ret);
		PUTBACK;
		FREETMPS;
		LEAVE;
		return ret_truth;
	}
	
	if (SvTYPE(sv_b) == SVt_PVAV)
	{
		AV *b_arr;
		int top_index;
		int i;
		
		b_arr = (AV*) SvRV(b);
		top_index = av_len(b_arr);
		
		for (i = 0; i <= top_index; i++)
		{
			SV *item = *av_fetch(b_arr, i, 1);
			if (_match(a, item))
				return TRUE;
		}
		
		return FALSE;
	}
	
	croak("match::simple::XS cannot match");
}

MODULE = match::simple::XS		PACKAGE = match::simple::XS

INCLUDE: const-xs.inc

bool
match (a, b)
	SV *a
	SV *b
CODE:
	RETVAL = _match(a, b);
OUTPUT:
	RETVAL
