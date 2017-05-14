/* 	$Id: pperl.h,v 1.3 1996/03/08 23:10:47 ilya Exp $	 */
#include "EXTERN.h"
#include <perl.h>
#include <Lang.h>

#include "tkPort.h"
#include "tkVMacro.h"

#ifndef NEW_TK
# define Tk_Cursor Cursor
# define TkRegion Region
# define Tcl_TimerToken Tk_TimerToken
# define TkUnionRectWithRegion XUnionRectWithRegion
# define Tcl_CreateTimerHandler Tk_CreateTimerHandler
# define Tcl_DeleteTimerHandler Tk_DeleteTimerHandler
# define Tcl_Release Tk_Release 
# define Tcl_Preserve Tk_Preserve
# define TkCreateRegion XCreateRegion
# define TkRectInRegion XRectInRegion
# define Tcl_DoWhenIdle Tk_DoWhenIdle
# define TkDestroyRegion XDestroyRegion
# define Tcl_CancelIdleCall Tk_CancelIdleCall
# define Tcl_EventuallyFree Tk_EventuallyFree
# define TkClipBox XClipBox
# define Tcl_BackgroundError Tk_BackgroundError
/* #define TkScrollWindow XScrollWindow */
/* #define Tcl_FreeProc Tk_FreeProc */
#endif

#define LangDouble(sv) SvNV((SV*)sv)
#define LangInt(sv) ((int)SvIV((SV*)sv))
#define LangLong(sv) ((long)SvIV((SV*)sv))
#define LangIsList(arg) (SvROK((SV*)arg) && SvTYPE(SvRV((SV*)arg)) == SVt_PVAV)

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
			     sv_bless(newRV(newSVsv((SV*)arg)),	\
				      gv_stashpv(type, TRUE)) :	\
			     newSVsv((SV*)arg))
#define ListFactoryAppendList(lfPtr,arg) \
	do {   AV *av = (AV*)(arg); \
	       int i, l; \
	       if (SvROK(av)) av = (AV*)SvRV((SV*)av); \
	       l = av_len(av); \
	       for (i=0;i <= l;i++) { \
		 ListFactoryAppendPure((lfPtr), \
				       newSVsv((SV*)*av_fetch(av,i,0))); \
	       } \
	    } while (0)
#define ListFactoryNewLevel(lfPtr) ( \
        (lfPtr)->child = malloc(sizeof(ListFactory)), \
        ListFactoryInit((lfPtr)->child), \
	(lfPtr)->child->parent = (lfPtr), \
	av_push((lfPtr)->av, newRV((SV*)(lfPtr)->child->av)),\
	SvREFCNT_dec((SV*)(lfPtr)->child->av), \
	(lfPtr)->child)
#define ListFactoryNewLevelWithType(lfPtr,type) ( \
        (lfPtr)->child = malloc(sizeof(ListFactory)), \
        ListFactoryInit((lfPtr)->child), \
	(lfPtr)->child->parent = (lfPtr), \
	av_push((lfPtr)->av, sv_bless(newRV((SV*)(lfPtr)->child->av),	\
				      gv_stashpv(type, TRUE))),\
	SvREFCNT_dec((SV*)(lfPtr)->child->av), \
	(lfPtr)->child)
#define ListFactoryEndLevel(lfPtr) ((lfPtr) = (lfPtr)->parent, \
	free((lfPtr)->child), lfPtr)
#define ListFactoryEndLevelWithType ListFactoryEndLevel
#define ListFactoryResult(interpr,lfPtr) \
	Tcl_AppendArg((interpr), ListFactoryArg(lfPtr))

/* These guys were not discussed yet. */

#define LangNewArg(argPtr, freeProcPtr) ( \
	*(argPtr) = (Arg)newSV(0), *(freeProcPtr) = NULL)
#define LangSetBuffer(argPtr,buffer)
#define dArgBuffer char argBuffer_
#define LangSetDefaultBuffer(argPtr)
#define LANG_DYNAMIC	((Tcl_FreeProc *) sv_free)


int LangArgEval _ANSI_ARGS_ ((Tcl_Interp *interp, Arg av));
void LangDumpArg _ANSI_ARGS_ ((Arg arg, I32 count));
