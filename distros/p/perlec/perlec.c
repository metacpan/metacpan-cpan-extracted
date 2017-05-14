/* ----------------------------------------------------------------------------
 * perlec.c - Perl Easy Call.
 * ----------------------------------------------------------------------------
 * Mastering programmed by YAMASHINA Hio
 *
 * Copyright 2007 YAMASHINA Hio
 * ----------------------------------------------------------------------------
 * $Id: /mirror/erlang/perlre/perlec/perlec.c 474 2007-06-11T06:46:56.918908Z hio  $
 * ------------------------------------------------------------------------- */

#ifdef HAVE_CONFIG_H
#  include <config.h>
#endif

#include "perlec.h"
#include <embed.h>
#include <proto.h>
#include <string.h>
#undef assert
#include <assert.h>

#if 0
#define DEBUG(cmd) cmd
#else
#define DEBUG(cmd)
#endif

#ifdef PERL_IMPLICIT_CONTEXT
#define d_my_perl PerlInterpreter* my_perl = perlec->my_perl
#endif

static const char arg_eval[] = 
	""
	;
static const char* embed_arg[] = { "", "-e", arg_eval, NULL };

static void _xs_init(pTHX);

static const int rxflag_map[16] = 
{
	/* .... */ 0,
	/* m... */ PMf_MULTILINE,
	/* .s.. */ PMf_SINGLELINE,
	/* ms . */ PMf_MULTILINE|PMf_SINGLELINE,
	/* ..i. */ PMf_FOLD,
	/* m.i. */ PMf_MULTILINE|PMf_FOLD,
	/* .si. */ PMf_SINGLELINE|PMf_FOLD,
	/* msi. */ PMf_MULTILINE|PMf_SINGLELINE|PMf_FOLD,
	/* ...x */ PMf_EXTENDED,
	/* m..x */ PMf_MULTILINE|PMf_EXTENDED,
	/* .s.x */ PMf_SINGLELINE|PMf_EXTENDED,
	/* ms x */ PMf_MULTILINE|PMf_SINGLELINE|PMf_EXTENDED,
	/* ..ix */ PMf_FOLD|PMf_EXTENDED,
	/* m.ix */ PMf_MULTILINE|PMf_FOLD|PMf_EXTENDED,
	/* .six */ PMf_SINGLELINE|PMf_FOLD|PMf_EXTENDED,
	/* msix */ PMf_MULTILINE|PMf_SINGLELINE|PMf_FOLD|PMf_EXTENDED,
};

/* ----------------------------------------------------------------------------
 * perlec_init(&perlec_buf);
 *  initialize.
 * ------------------------------------------------------------------------- */
void perlec_init(perlec_t* perlec)
{
	PerlInterpreter* my_perl;
	
	DEBUG(fprintf(stdout, "perlec:init\r\n"));
	my_perl = perl_alloc();
	perlec->my_perl = my_perl;
	perl_construct(my_perl);
	PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
	perl_parse(my_perl, &_xs_init, 3, (char**)embed_arg, NULL);
	perl_run(my_perl);
	
	perlec->cv_match   = eval_pv("sub{ my$x=[$_[0]=~$_[1]];@->1?$x:@-&&[] }",0);
	perlec->cv_gsub    = eval_pv("sub{ my $x=$_[0];$x=~s/$_[1]/$_[2]/g?$x:undef }", 0);
	perlec->cv_eval    = eval_pv("sub{ eval shift }", 0);
	perlec->cv_regcheck = eval_pv("sub{ qr/$_[0]/ }",0);
	
	return;
}

static void _xs_init(pTHX)
{
#if 1
	EXTERN_C void boot_DynaLoader(pTHX_ CV* cv);
	char *file = __FILE__;
	/* DynaLoader is a special case */
	newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
#endif
}

/* ----------------------------------------------------------------------------
 * perlec_discard(&perlec_buf);
 *  discard.
 * ------------------------------------------------------------------------- */
void perlec_discard(perlec_t* perlec)
{
	perl_destruct(perlec->my_perl);
	perl_free(perlec->my_perl);
	perlec->my_perl = NULL;
	return;
}

/* ----------------------------------------------------------------------------
 * rx_obj = perlec_compile(perlec, re, re-len).
 *  re :: const char*
 * ------------------------------------------------------------------------- */
/* pmruntime requires PERL_CORE. */
#if !defined(PERL_IMPLICIT_CONTEXT)
#define pmruntime(a,b,c) Perl_pmruntime(a,b,c)
#else
#define pmruntime(a,b,c)  Perl_pmruntime(aTHX_ a,b,c)
#endif
static int perlec_regcheck(perlec_t* perlec, const char* re, int re_len)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	dSP;
	int count;
	SV* sv;
	int ret;
	
	ENTER;
	SAVETMPS;
	
	DEBUG(printf("regcheck enter\n"));
	DEBUG(printf("re  = [%s] (%d)\n", re,  re_len));
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpvn(re, re_len)));
	PUTBACK;
	
	count = call_sv(perlec->cv_regcheck, G_SCALAR|G_EVAL);
	assert( count==1 );
	SPAGAIN;
	
	sv = POPs;
	ret = SvTRUE(sv);
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	DEBUG(printf("regcheck leave\n"));
	return ret;
}
void* perlec_compile(perlec_t* perlec, const char* re, int re_len, int rx_flags)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	SV* re_sv;
	OP* re_op;
	PMOP* pm_op;
	regexp* rx;
	
	DEBUG(fprintf(stdout, "perlec:compile\r\n"));
	if( perlec_regcheck(perlec, re, re_len) )
	{
		re_sv  = newSVpvn(re, re_len);
		re_op  = newSVOP(OP_CONST, 0, re_sv);
		DEBUG(fprintf(stdout, "make OP...\r\n"));
		pm_op  = (PMOP*)pmruntime(newPMOP(OP_MATCH, 0), re_op, Nullop);
		if( rx_flags )
		{
			pm_op->op_pmflags = rxflag_map[rx_flags&15];
			pm_op->op_pmpermflags = pm_op->op_pmflags;
			if( rx_flags & PERLEC_ROPT_UTF8 )
			{
				pm_op->op_pmdynflags |= PMdf_CMP_UTF8;
				SvUTF8_on(re_sv);
			}
			DEBUG(fprintf(stdout, "pmflags = %x\r\n", (int)pm_op->op_pmflags));
			DEBUG(fprintf(stdout, "pmdynflags = %x\r\n", pm_op->op_pmdynflags));
		}
		DEBUG(fprintf(stdout, "do compile...\r\n"));
		rx = pregcomp((char*)re, (char*)re+re_len, pm_op);
		PM_SETRE(pm_op, rx);
	}else
	{
		DEBUG(fprintf(stdout, "regcheck failed\r\n"));
		pm_op = NULL;
	}
	
	return pm_op;
}

/* ----------------------------------------------------------------------------
 * array_obj = perlec_match_rx(perlec, str, str_len, rx_obj, rx_flags).
 *  str :: const char*
 * ------------------------------------------------------------------------- */
void* perlec_match_rx(perlec_t* perlec, const char* str, int str_len, void* re_obj, int rx_flags)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	PMOP* const pm_op = re_obj;
	regexp* rx = pm_op!=NULL ? PM_GETRE(pm_op) : NULL;
	
	SV* str_sv;
	STRLEN len;
	char* str_beg;
	char* str_end;
	char* truebase;
	int flags;
	int minmatch;
	int match;
	void* ret;
	
	assert( rx!=NULL );
	str_sv = newSVpvn(str, str_len);
	
	if( rx_flags & PERLEC_ROPT_UTF8 || pm_op->op_pmdynflags & PMdf_CMP_UTF8 )
	{
		SvUTF8_on(str_sv);
		RX_MATCH_UTF8_set(rx, 1);
	}
	
	str_beg = SvPV(str_sv, len);
	str_end = str_beg + len;
	truebase = str_beg;
	flags = 0;
	minmatch = 0;
	
	match = CALLREGEXEC(aTHX_ rx, str_beg, str_end, truebase, minmatch, str_sv, NULL, flags);
	
	if( match )
	{
		int i;
		if( rx->nparens )
		{
			int guessed_size;
			guessed_size = 0;
			for( i=0; i<rx->nparens; ++i )
			{
				if( rx->startp[i]!=-1 && rx->endp[i]!=-1 )
				{
					int len = rx->endp[i] - rx->startp[i];
					guessed_size += len;
				}
			}
			ret = (*perlec->array_new)(perlec, rx->nparens, guessed_size);
			for( i=1; i<=rx->nparens; ++i )
			{
				if( rx->startp[i]!=-1 && rx->endp[i]!=-1 )
				{
					int len = rx->endp[i] - rx->startp[i];
					const char* s = truebase + rx->startp[i];
					(*perlec->array_store)(ret, i-1, s, len);
				}else
				{
					(*perlec->array_store)(ret, i-1, NULL, 0);
				}
			}
		}else
		{
			ret = (*perlec->array_new)(perlec, 0, 0);
		}
		return ret;
	}else
	{
		ret = NULL;
		return ret;
	}
}

/* ----------------------------------------------------------------------------
 * array_obj = perlec_match(perlec, str, str_len, re, re_len).
 *  str, re :: const char*
 * ------------------------------------------------------------------------- */
void* perlec_match(perlec_t* perlec, const char* str, int str_len, const char* re, int re_len, int rx_flags)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	dSP;
	int count;
	SV* sv;
	SV* str_sv;
	SV* re_sv;
	AV* av;
	void* ret;
	int i;
	
	ENTER;
	SAVETMPS;
	
	DEBUG(printf("match enter\n"));
	DEBUG(printf("str = [%.*s] (%d)\n", str_len, str, str_len));
	DEBUG(printf("re  = [%.*s] (%d)\n", re_len,  re,  re_len));
	DEBUG(printf("flg = [%x]\n", rx_flags));
	
	PUSHMARK(SP);
	XPUSHs(str_sv=sv_2mortal(newSVpvn(str,str_len)));
	XPUSHs(re_sv=sv_2mortal(newSVpvn(re, re_len)));
	PUTBACK;
	
	if( rx_flags!=0 )
	{
		char buf[10];
		char* p = &buf[0];
		*p++ = '(';
		*p++ = '?';
		if( rx_flags & PERLEC_ROPT_MULTILINE )
		{
			*p++ = 'm';
		}
		if( rx_flags & PERLEC_ROPT_SINGLELINE )
		{
			*p++ = 's';
		}
		if( rx_flags & PERLEC_ROPT_IGNORECASE )
		{
			*p++ = 'i';
		}
		if( rx_flags & PERLEC_ROPT_EXTENDED )
		{
			*p++ = 'x';
		}
		if( p!=buf+2 )
		{
			*p++ = ')';
			sv_insert(re_sv, 0, 0, buf, p-buf);
			DEBUG(printf("rx_flags = [%.*s]\n", p-buf, buf));
		}
		if( rx_flags & PERLEC_ROPT_UTF8 )
		{
			SvUTF8_on(str_sv);
			SvUTF8_on(re_sv);
		}
	}
	
	count = call_sv(perlec->cv_match, G_SCALAR|G_EVAL);
	assert( count==1 );
	SPAGAIN;
	
	sv = POPs;
	if( SvTRUE(sv) )
	{
		int guessed_size;
		av = (AV*)SvRV(sv);
		
		DEBUG(printf("array_new(%p) elems=%ld.\n", perlec->array_new, av_len(av)+1));
		guessed_size = 0;
		for( i=0; i<=av_len(av); ++i )
		{
			SV** sv = av_fetch(av, i, 0);
			if( sv!=NULL )
			{
				STRLEN len = SvLEN(*sv);
				guessed_size += len;
			}
		}
		ret = perlec->array_new(perlec, av_len(av)+1, guessed_size);
		for( i=0; i<=av_len(av); ++i )
		{
			SV** sv = av_fetch(av, i, 0);
			if( sv==NULL )
			{
				perlec->array_store(ret, i, NULL, 0);
			}else
			{
				STRLEN len;
				const char* str = SvPV(*sv, len);
				perlec->array_store(ret, i, str, len);
			}
		}
	}else
	{
		ret = NULL;
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	DEBUG(printf("match leave\n"));
	return ret;
}

/* ----------------------------------------------------------------------------
 * scalar_obj = perlec_replacement(perlec, str, str_len, re, re_len, repl, repl_len).
 *  str, re, repl :: const char*
 * ------------------------------------------------------------------------- */
static int _sv_defined(perlec_t* perlec, SV* sv)
{
#ifdef PERL_IMPLICIT_CONTEXT
    d_my_perl;
#endif
    if (!sv || !SvANY(sv))
        return 0;
    switch (SvTYPE(sv)) {
    case SVt_PVAV:
        if (AvMAX(sv) >= 0 || SvGMAGICAL(sv)
                || (SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_tied)))
            return 1;
        break;
    case SVt_PVHV:
        if (HvARRAY(sv) || SvGMAGICAL(sv)
                || (SvRMAGICAL(sv) && mg_find(sv, PERL_MAGIC_tied)))
            return 1;
        break;
    case SVt_PVCV:
        if (CvROOT(sv) || CvXSUB(sv))
            return 1;
        break;
    default:
        if (SvGMAGICAL(sv))
            mg_get(sv);
        if (SvOK(sv))
            return 1;
    }
    return 0;
}

void* perlec_replacement(perlec_t* perlec, const char* s1, int s1_len, const char* re, int re_len, const char* repl, int repl_len)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	dSP;
	int count;
	SV* sv;
	void* ret;
	
	ENTER;
	SAVETMPS;
	
	DEBUG(printf("replacement enter\r\n"));
	DEBUG(printf("s1 = [%s] (%d)\r\n", s1, s1_len));
	DEBUG(printf("re = [%s] (%d)\r\n", re, re_len));
	DEBUG(printf("repl = [%s] (%d)\r\n", repl, repl_len));
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpvn(s1,s1_len)));
	XPUSHs(sv_2mortal(newSVpvn(re,re_len)));
	XPUSHs(sv_2mortal(newSVpvn(repl,repl_len)));
	PUTBACK;
	
	count = call_sv(perlec->cv_gsub, G_SCALAR|G_EVAL);
	assert( count==1 );
	SPAGAIN;
	
	sv = POPs;
	if( _sv_defined(perlec, sv) )
	{
		STRLEN len;
		const char* str = SvPV(sv, len);
		ret = perlec->scalar_new(perlec, str, len);
	}else
	{
		ret = NULL;
	}
	DEBUG(printf("ret = %p\r\n", ret));
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	DEBUG(printf("replacement leave\r\n"));
	return ret;
}

/* ----------------------------------------------------------------------------
 * scalar_obj = perlec_eval(perlec, str, str_len).
 *  str :: const char*
 * ------------------------------------------------------------------------- */
void* perlec_eval(perlec_t* perlec, const char* str, int str_len)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	dSP;
	int count;
	SV* sv;
	void* ret;
	
	ENTER;
	SAVETMPS;
	
	DEBUG(printf("eval enter\n"));
	DEBUG(printf("str = [%s] (%d)\n", str, str_len));
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newSVpvn(str,str_len)));
	PUTBACK;
	
	// eval_xv doues not set errsv?
	count = call_sv(perlec->cv_eval, G_SCALAR|G_EVAL|G_KEEPERR);
	assert( count==1 );
	SPAGAIN;
	
	sv = POPs;
	
	if( !SvTRUE(ERRSV) )
	{
		STRLEN len;
		const char* str = SvPV(sv, len);
		ret = perlec->scalar_new(perlec, str, len);
	}else
	{
		ret = NULL;
	}
	
	PUTBACK;
	FREETMPS;
	LEAVE;
	
	DEBUG(printf("eval leave\n"));
	return ret;
}

/* ----------------------------------------------------------------------------
 * ret = perlec_errmsg(perlec);
 * ret :: perlec_scalar
 * ------------------------------------------------------------------------- */
void* perlec_errmsg(perlec_t* perlec)
{
#ifdef PERL_IMPLICIT_CONTEXT
	d_my_perl;
#endif
	void* ret;
	STRLEN len;
	char* str;
	
	DEBUG(printf("errmsg enter\n"));
	
	if( SvTRUE(ERRSV) )
	{
		str = SvPV(ERRSV, len);
		ret = perlec->scalar_new(perlec, str, len);
	}else
	{
		ret = NULL;
	}
	
	DEBUG(printf("errmsg leave\n"));
	
	return ret;
}

/* ----------------------------------------------------------------------------
 * Copyright (C) 2007 YAMASHINA Hio
 * This program is free software; you can redistribute it and/or modify it
 * under the same terms as Perl itself.
 * ----------------------------------------------------------------------------
 * End of File.
 * ------------------------------------------------------------------------- */
