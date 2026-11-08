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
