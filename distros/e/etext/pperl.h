/*
 * pperl.h --
 *
 *	Perl/Tk glue for the eText widget.  This header adapts the
 *	Tk-b9-era "Lang" portability layer that the eText sources were
 *	written against to the API of a modern Perl/Tk (Tk 804.0xx).
 *
 * Copyright (c) 1996 Ilya Zakharevich.
 * Modernization for Tk 804 (c) 2026.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the same terms as Perl itself.
 */

#ifndef _ETEXT_PPERL_H
#define _ETEXT_PPERL_H

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

/*
 * tkGlue.def (installed with Tk) identifies the Tcl types with their
 * Perl implementations: Tcl_Obj is an SV, Tcl_Interp an HV, etc.
 */
#include "tkGlue.def"

/* pTk headers (installed with Tk under .../Tk/pTk) */
#include "Lang.h"
#include "tkPort.h"
#ifndef _TK
#include "tk.h"
#endif

#ifndef panic
#define panic Tcl_Panic
#endif

/*
 * Keep internal symbols distinct from those of Tk's own text widget,
 * which lives in Tk.so and uses the very same names for its internal
 * procedures (TkBTreeCreate, TkTextGetIndex, ...).
 */
#include "eTextSyms.h"

/*
 * In Tk-b9 "Arg" was the opaque per-language argument type.  In Tk 804 a
 * Tcl_Obj is an SV, so Arg is simply a Tcl_Obj pointer.
 */
typedef Tcl_Obj *Arg;

/* Tk-b9's Lang_SplitList() handed back a release procedure. */
typedef void (LangFreeProc) _ANSI_ARGS_((int argc, Arg *args));

#define LangString(sv)	Tcl_GetString((Tcl_Obj *)(sv))
#define LangDouble(sv)	SvNV((SV*)(sv))
#define LangInt(sv)	((int)SvIV((SV*)(sv)))
#define LangLong(sv)	((long)SvIV((SV*)(sv)))
#define LangIsList(arg)	(SvROK((SV*)(arg)) \
			 && SvTYPE(SvRV((SV*)(arg))) == SVt_PVAV)

/*
 * Results.  Note that Tk 804's Tcl_SetObjResult() copies the value
 * and then releases the object it was handed, i.e. it takes ownership.
 * Tcl_ResultArg() therefore returns a new reference which the caller
 * has to release with LangFreeArg().
 */
#define Tcl_ArgResult(interp,arg)	Tcl_SetObjResult((interp),(arg))
#define Tcl_GetResult(interp)		Tcl_GetStringResult(interp)
#define Tcl_ResultArg(interp)		((Arg) SvREFCNT_inc(Tcl_GetObjResult(interp)))

/*
 * Lists.  Tcl_ListObjGetElements() returns a pointer into the list's
 * own storage, so there is nothing to release afterwards.
 */
#define Lang_SplitList(interp, arg, argcPtr, argvPtr, freeProcPtr) \
	((*(freeProcPtr) = (LangFreeProc *) NULL), \
	 Tcl_ListObjGetElements((interp), (arg), (argcPtr), (argvPtr)))

/*
 * Callbacks and widgets as arguments.  Tk 804's LangCallbackArg() is a
 * deprecated variant that returns a borrowed reference (and complains
 * on stderr); LangCallbackObj() and LangWidgetObj() return references
 * owned by the caller, which is what the eText code expects (it
 * releases them with LangFreeArg()).
 */
#ifdef LangCallbackArg
#undef LangCallbackArg
#endif
#define LangCallbackArg(cb)		LangCallbackObj(cb)
#ifdef LangWidgetArg
#undef LangWidgetArg
#endif
#define LangWidgetArg(interp,tkwin)	LangWidgetObj((interp),(tkwin))

#define LANG_DYNAMIC	TCL_DYNAMIC

/*
 * Regular expressions: Tk 804 compiles Perl regexps from a Tcl_Obj.
 */
#define Lang_RegExpCompile(interp, patObj, noCase) \
	Tcl_GetRegExpFromObj((interp), (patObj), \
			     ((noCase) ? TCL_REG_NOCASE : 0) | TCL_REG_ADVANCED)
#define Lang_RegExpExec Tcl_RegExpExec

/*
 * ListFactory: incremental construction of (possibly nested, possibly
 * blessed) Perl lists, used for the "object-oriented dump" and for
 * the argument list of the block layout callback.
 */
typedef struct ListFactory {
  AV* av;
  struct ListFactory *parent;
  struct ListFactory *child;		/* To simplify macros only. */
} ListFactory;

#define ListFactoryInit(lfPtr) ((lfPtr)->av = newAV(), \
				(lfPtr)->parent = NULL,  \
				(lfPtr)->child = NULL)
#define ListFactoryFinish(lfPtr)
#define ListFactoryFree(lfPtr) (SvREFCNT_dec((SV*)(lfPtr)->av))
#define ListFactoryArg(lfPtr) ((Arg)(lfPtr)->av)
#define ListFactoryAppendPure(lfPtr,sv) \
	av_push((lfPtr)->av, sv)
#define ListFactoryAppend(lfPtr,arg) \
	ListFactoryAppendPure((lfPtr),SvREFCNT_inc((SV*)arg))
#define ListFactoryAppendCopy(lfPtr,arg) \
	ListFactoryAppendPure((lfPtr),newSVsv((SV*)arg))
#define ListFactoryAppendCopyWithType(lfPtr,arg,type)		\
	ListFactoryAppendPure((lfPtr), 				\
			     (type) ?				\
			     sv_bless(newRV_noinc(newSVsv((SV*)arg)),	\
				      gv_stashpv(type, TRUE)) :	\
			     newSVsv((SV*)arg))
#define ListFactoryAppendList(lfPtr,arg) \
	do {   AV *av = (AV*)(arg); \
	       int i, l; \
	       if (SvROK(av)) av = (AV*)SvRV((SV*)av); \
	       l = av_len(av); \
	       for (i=0;i <= l;i++) { \
		 SV **svp_ = av_fetch(av,i,0); \
		 ListFactoryAppendPure((lfPtr), \
				       svp_ ? newSVsv(*svp_) : newSV(0)); \
	       } \
	    } while (0)
#define ListFactoryNewLevel(lfPtr) ( \
        (lfPtr)->child = (ListFactory *) ckalloc(sizeof(ListFactory)), \
        ListFactoryInit((lfPtr)->child), \
	(lfPtr)->child->parent = (lfPtr), \
	av_push((lfPtr)->av, newRV_noinc((SV*)(lfPtr)->child->av)),\
	(lfPtr)->child)
#define ListFactoryNewLevelWithType(lfPtr,type) ( \
        (lfPtr)->child = (ListFactory *) ckalloc(sizeof(ListFactory)), \
        ListFactoryInit((lfPtr)->child), \
	(lfPtr)->child->parent = (lfPtr), \
	av_push((lfPtr)->av, sv_bless(newRV_noinc((SV*)(lfPtr)->child->av),	\
				      gv_stashpv(type, TRUE))),\
	(lfPtr)->child)
#define ListFactoryEndLevel(lfPtr) ((lfPtr) = (lfPtr)->parent, \
	ckfree((char *)(lfPtr)->child), (lfPtr)->child = NULL, lfPtr)
#define ListFactoryEndLevelWithType ListFactoryEndLevel
/*
 * Hand the list over as the command result.  Tcl_SetObjResult() copies
 * the reference and releases the one it is given.
 */
#define ListFactoryResult(interp,lfPtr) \
	Tcl_SetObjResult((interp), newRV_inc((SV*)(lfPtr)->av))

int LangArgEval _ANSI_ARGS_ ((Tcl_Interp *interp, Arg av));
void LangDumpArg _ANSI_ARGS_ ((Arg arg, I32 count));
int LangDestroyMult _ANSI_ARGS_ ((Tcl_Interp *interp, int n, int limit,
				 int *morePtr));

#endif /* _ETEXT_PPERL_H */
