#ifndef lint
static char rcsid_h[] = "$Id: ptcl.h,v 1.5 1996/03/20 21:26:22 ilya Exp $";
#endif

#include "tcl.h"

#define REAL_TCL
#define TK_CONFIG_CALLBACK	TK_CONFIG_STRING
#define TK_CONFIG_LANGARG	TK_CONFIG_STRING
#define TK_CONFIG_SCALARVAR	TK_CONFIG_STRING
#define TK_CONFIG_HASHVAR	TK_CONFIG_STRING
#define TK_CONFIG_ARRAYVAR	TK_CONFIG_STRING
#define TK_CONFIG_IMAGE	TK_CONFIG_STRING
#define Lang_SplitList(interp, arg, numTagsPtr, tagNamesPtr, freeProcPtr) \
		((*(freeProcPtr) = &LangFreeSplitProc), \
		Tcl_SplitList((interp), (arg), (numTagsPtr), (tagNamesPtr)))
#define LangString(arg) (arg)
#define args argv
#define LangSetString(charPtrPtr,string) (*(charPtrPtr) = (string))
#define LangSetDefault(charPtrPtr,string) (*(charPtrPtr) = (string))
#define LangSetInt(argPtr,num) sprintf(*(argPtr), "%d", (num))
#define LangSetDouble(argPtr,num) sprintf(*(argPtr), "%g", (num))
#define LangWidgetArg(interp,tkwin) Tk_PathName(tkwin)
#define Tcl_ArgResult(interp, arg) Tcl_AppendElement((interp),(arg))
#define LangCallbackArg(command) (command)
#define LangSaveVar(interp, varName, varPtr, type) \
	(*(varPtr) = (varName), TCL_OK)
#define LangFreeVar(var) 

#define Lang_RegExpCompile(interp, pattern, noCase) \
		Tcl_RegExpCompile(interp, pattern)
#define Lang_RegExpExec Tcl_RegExpExec
#define Lang_FreeRegExp(regexp)

#define LangCmpOpt strncmp

#define Tk_CreateWidget(interp, tkwin, proc, clientData, deleteProc) \
	Tcl_CreateCommand((interp), Tk_PathName(tkwin), (proc), \
			  (clientData), (deleteProc))
#define Tk_DeleteWidget(interp, tkwin) \
	Tcl_DeleteCommand((interp), Tk_PathName(tkwin))
#define Tk_WidgetResult(interp,tkwin) \
	((interp)->result = Tk_PathName(tkwin)) 
#define Tcl_GetResult(interp) ((interp)->result)
#define Tcl_ResultArg Tcl_GetResult

typedef char * Var;
typedef char * Arg;
typedef char LangCallback;
typedef void (LangFreeProc)(int, Arg*);

void LangFreeSplitProc _ANSI_ARGS_((int num, Arg* args));
void LangFreeArg _ANSI_ARGS_((Arg arg, Tcl_FreeProc *freeProc));

#ifdef lint
void Tcl_DoubleResults _ANSI_ARGS_((Tcl_Interp *interp, int count, int append, ...));
void Tcl_IntResults _ANSI_ARGS_((Tcl_Interp *interp, int count, int append, ...));
int LangDoCallback _ANSI_ARGS_((Tcl_Interp *interp, LangCallback *cmd, int result, int count, ...));
#else
void Tcl_DoubleResults _ANSI_ARGS_(VARARGS);
void Tcl_IntResults _ANSI_ARGS_(VARARGS);
int LangDoCallback _ANSI_ARGS_(VARARGS);
#endif /* !defined(lint) */

/* From this moment on this is unsupported from under Perl. */

#define LangDouble atof
#define LangInt atoi
#define LangLong atol
#define LangIsList(arg) (strchr(arg,' ') != NULL)

typedef Tcl_DString ListFactory;

#define ListFactoryInit Tcl_DStringInit
#define ListFactoryFinish(lfPtr)
#define ListFactoryFree Tcl_DStringFree
#define ListFactoryArg Tcl_DStringValue
#define ListFactoryAppend Tcl_DStringAppendElement
#define ListFactoryAppendCopy Tcl_DStringAppendElement
#define ListFactoryAppendList(lfPtr,arg) \
  ((Tcl_DStringLength(lfPtr) && Tcl_DStringAppend(lfPtr," ",1)), \
   Tcl_DStringAppend(lfPtr,arg,-1))
#define ListFactoryNewLevel(lfPtr) (Tcl_DStringStartSublist(lfPtr), lfPtr)
#define ListFactoryNewLevelWithType(lfPtr,type) \
  (Tcl_DStringStartSublist(lfPtr), ListFactoryAppend(lfPtr, type), lfPtr)
#define ListFactoryEndLevel(lfPtr) (Tcl_DStringEndSublist(lfPtr), lfPtr)
#define ListFactoryEndLevelWithType ListFactoryEndLevel
#define ListFactoryResult Tcl_DStringResult

void ListFactoryAppendCopyWithType _ANSI_ARGS_((ListFactory *lfPtr,
						Arg arg, char *type));

/* These guys were not discussed yet. */

#define dArgBuffer char argBuffer_[TCL_DOUBLE_SPACE]
#define LangSetBuffer(argPtr,buffer) (*(argPtr) = (buffer))
#define LangSetDefaultBuffer(argPtr) (*(argPtr) = argBuffer_)
#define LangArgEval(interp, arg) Tcl_VarEval((interp), (arg), NULL)
#define LANG_DYNAMIC NULL
