/*
 * pperlGlue.c --
 *
 *	Perl-specific helpers for the eText widget.
 *
 * Copyright (c) 1996 Ilya Zakharevich.
 * Modernization for Tk 804 (c) 2026.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#include "pperl.h"
#include "tkVMacro.h"

/*
 *----------------------------------------------------------------------
 *
 * LangArgEval --
 *
 *	Invoke a callback assembled by a ListFactory: the first element
 *	of the array is the code to call (or the callback object), the
 *	rest are its arguments.  The values returned by the callback
 *	are left in the interpreter result as a list, one element per
 *	returned value.
 *
 * Results:
 *	A standard Tcl result.
 *
 *----------------------------------------------------------------------
 */

int
LangArgEval(interp, av)
     Tcl_Interp *interp;
     Arg	av;				/* Really an AV *. */
{
    dTHX;
    SV *rv = newRV_inc((SV *) av);
    int res;

    res = LangDoCallback(interp, rv, 2 /* G_ARRAY */, 0);
    SvREFCNT_dec(rv);
    if (res == TCL_OK) {
	/*
	 * LangDoCallback() stores a single returned value as the result
	 * itself rather than as a one-element list.  The layout protocol
	 * returns a list of rows (each row a flat list of numbers), so a
	 * result whose first element is not a reference is a lone row:
	 * wrap it.
	 */

	SV *result = Tcl_GetObjResult(interp);

	if (SvROK(result) && SvTYPE(SvRV(result)) == SVt_PVAV) {
	    AV *rowAv = (AV *) SvRV(result);
	    SV **first = av_fetch(rowAv, 0, 0);

	    if (first != NULL && !SvROK(*first)) {
		AV *listAv = newAV();

		av_push(listAv, newSVsv(result));
		Tcl_SetObjResult(interp, newRV_noinc((SV *) listAv));
	    }
	}
    }
    return res;
}

/*
 *----------------------------------------------------------------------
 *
 * LangDumpArg --
 *
 *	Debugging aid: Devel::Peek::Dump() an argument.
 *
 *----------------------------------------------------------------------
 */

void
LangDumpArg(arg, count)
    Arg arg;
    I32 count;
{
    dTHX;
    dSP;

    ENTER;
    SAVETMPS;
    PUSHMARK(sp);
    EXTEND(sp, 2);
    PUSHs((SV*)arg);
    PUSHs(sv_2mortal(newSViv(count)));
    PUTBACK;
    call_pv("Devel::Peek::Dump", G_DISCARD | G_EVAL);
    FREETMPS;
    LEAVE;
}

/*
 *----------------------------------------------------------------------
 *
 * DestroyingObject --
 *
 *	The object whose DESTROY method is the innermost one running:
 *	Perl calls a DESTROY method on a stack of its own (PERLSI_DESTROY),
 *	whose first subroutine frame is the method, called with a
 *	reference to the object as its first argument.  The argument is
 *	read where caller() finds it for @DB::args, so that a DESTROY
 *	method that has shifted @_ is found too.
 *
 * Results:
 *	The reference (borrowed: it lives while the method runs), or NULL
 *	if no DESTROY method written in Perl is running, or its @_ holds
 *	nothing.
 *
 *----------------------------------------------------------------------
 */

static SV *
DestroyingObject(pTHX)
{
    PERL_SI *si;

    for (si = PL_curstackinfo; si != NULL; si = si->si_prev) {
	I32 i;

	if (si->si_type != PERLSI_DESTROY) {
	    continue;
	}
	for (i = 0; i <= si->si_cxix; i++) {
	    PERL_CONTEXT *cx = &si->si_cxstack[i];
	    AV *args;

	    if (CxTYPE(cx) != CXt_SUB) {
		continue;
	    }
	    if (!CxHASARGS(cx)) {
		return NULL;
	    }
#if PERL_REVISION == 5 && PERL_VERSION < 24
	    args = cx->blk_sub.argarray;
#else
	    args = MUTABLE_AV(AvARRAY(MUTABLE_AV(PadlistARRAY(
		    CvPADLIST(cx->blk_sub.cv))[cx->blk_sub.olddepth + 1]))[0]);
#endif
	    if ((args == NULL) || (AvALLOC(args) == NULL)
		    || (AvFILLp(args) + (AvARRAY(args) - AvALLOC(args)) < 0)) {
		return NULL;
	    }
	    return AvALLOC(args)[0];
	}

	/*
	 * No Perl frame on this stack: a DESTROY written in C, which
	 * cannot have made the change; look further out.
	 */
    }
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * LangDestroyMult --
 *
 *	Ask the object whose DESTROY method is the innermost one running
 *	(DestroyingObject) how many more rounds of freeing values it
 *	needs: $object->DESTROYmult($n, $limit), in scalar context, if it
 *	is a blessed object that can('DESTROYmult').  $@ is left as it
 *	was.
 *
 * Results:
 *	TCL_OK, with *morePtr the answer if it is a positive integer
 *	(no larger than INT_MAX - limit), else 0 (also when there is no
 *	such object or method); TCL_ERROR if the method (or can) died,
 *	with *morePtr 0 and the error in the interpreter's result.
 *
 *----------------------------------------------------------------------
 */

int
LangDestroyMult(interp, n, limit, morePtr)
    Tcl_Interp *interp;
    int n;				/* The request: 1, 2, ... */
    int limit;				/* The current limit. */
    int *morePtr;			/* Where to put the answer. */
{
    dTHX;
    dSP;
    SV *obj = DestroyingObject(aTHX);
    SV *answer;
    int count, code = TCL_OK;

    *morePtr = 0;
    if ((obj == NULL) || !sv_isobject(obj)) {
	return TCL_OK;
    }
    ENTER;
    SAVETMPS;
    save_scalar(PL_errgv);		/* local $@ */
    PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(obj);
    PUSHs(sv_2mortal(newSVpv("DESTROYmult", 0)));
    PUTBACK;
    count = call_method("can", G_SCALAR | G_EVAL);
    SPAGAIN;
    answer = (count > 0) ? POPs : &PL_sv_undef;
    PUTBACK;
    if (!SvTRUE(ERRSV) && SvTRUE(answer)) {
	PUSHMARK(SP);
	EXTEND(SP, 3);
	PUSHs(obj);
	mPUSHi(n);
	mPUSHi(limit);
	PUTBACK;
	count = call_method("DESTROYmult", G_SCALAR | G_EVAL);
	SPAGAIN;
	answer = (count > 0) ? POPs : &PL_sv_undef;
	PUTBACK;
	if (!SvTRUE(ERRSV) && SvOK(answer) && looks_like_number(answer)) {
	    NV nv = SvNV(answer);

	    if (nv >= (NV) (INT_MAX - limit)) {
		*morePtr = INT_MAX - limit;
	    } else if ((nv >= 1) && (nv == (NV) (int) nv)) {
		*morePtr = (int) nv;
	    }
	}
    }
    if (SvTRUE(ERRSV)) {
	Tcl_SetObjResult(interp, newSVsv(ERRSV));
	code = TCL_ERROR;
    }
    FREETMPS;
    LEAVE;
    return code;
}
