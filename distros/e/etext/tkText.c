/* 
 * tkText.c --
 *
 *	This module provides a big chunk of the implementation of
 *	multi-line editable text widgets for Tk.  Among other things,
 *	it provides the Tcl command interfaces to text widgets and
 *	the display code.  The B-tree representation of text is
 *	implemented elsewhere.
 *
 * Copyright (c) 1992-1994 The Regents of the University of California.
 * Copyright (c) 1994-1996 Sun Microsystems, Inc.
 * Copyright (c) 1995 Ilya Zakharevich.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tkText.c 1.90 96/04/13 16:49:59
 */
#define NO_COREXT

/* @(#) tkText.c 1.82 95/08/21 11:46:27 */

#include "pperl.h"
#include "default.h"
#include "tkPort.h"
#include "tkInt.h"

#ifdef MAC_TCL
#define Style TkStyle
#define DInfo TkDInfo
#endif

#include "tkText.h"

/* $Id: tkText.c,v 1.24 1996/03/20 21:27:06 ilya Exp $ */

#if TK_TEXT_DATA_ARRAYS
long eText_TkTextDataLive = 0;	/* Data blocks not yet freed (see
				 * tkTextData.h). */
#endif

/*
 * Information used to parse text configuration options:
 */

static Tk_ConfigSpec configSpecs[] = {
    {TK_CONFIG_BOOLEAN, "-autoseparators", "autoSeparators",
	"AutoSeparators", "1", Tk_Offset(TkText, autoSeparators), 0},
    {TK_CONFIG_BORDER, "-background", "background", "Background",
	DEF_TEXT_BG_COLOR, Tk_Offset(TkText, border), TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_BORDER, "-background", "background", "Background",
	DEF_TEXT_BG_MONO, Tk_Offset(TkText, border), TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_SYNONYM, "-bd", "borderWidth",          NULL,
	         NULL, 0, 0},
    {TK_CONFIG_SYNONYM, "-bg", "background",          NULL,
	         NULL, 0, 0},
    {TK_CONFIG_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
	DEF_TEXT_BORDER_WIDTH, Tk_Offset(TkText, borderWidth), 0},
    {TK_CONFIG_ACTIVE_CURSOR, "-cursor", "cursor", "Cursor",
	DEF_TEXT_CURSOR, Tk_Offset(TkText, cursor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-exportselection", "exportSelection",
	"ExportSelection", DEF_TEXT_EXPORT_SELECTION,
	Tk_Offset(TkText, exportSelection), 0},
    {TK_CONFIG_SYNONYM, "-fg", "foreground",          NULL,
	         NULL, 0, 0},
    {TK_CONFIG_FONT, "-font", "font", "Font",
	DEF_TEXT_FONT, Tk_Offset(TkText, tkfont), 0},
    {TK_CONFIG_COLOR, "-foreground", "foreground", "Foreground",
	DEF_TEXT_FG, Tk_Offset(TkText, fgColor), 0},
    {TK_CONFIG_INT, "-getflags", "getflags", "getFlags",
	0, Tk_Offset(TkText, getFlags), 0},
    {TK_CONFIG_PIXELS, "-height", "height", "Height",
	DEF_TEXT_HEIGHT, Tk_Offset(TkText, height), 0},
    {TK_CONFIG_COLOR, "-highlightbackground", "highlightBackground",
	"HighlightBackground", DEF_TEXT_HIGHLIGHT_BG,
	Tk_Offset(TkText, highlightBgColorPtr), 0},
    {TK_CONFIG_COLOR, "-highlightcolor", "highlightColor", "HighlightColor",
	DEF_TEXT_HIGHLIGHT, Tk_Offset(TkText, highlightColorPtr), 0},
    {TK_CONFIG_PIXELS, "-highlightthickness", "highlightThickness",
	"HighlightThickness",
	DEF_TEXT_HIGHLIGHT_WIDTH, Tk_Offset(TkText, highlightWidth), 0},
    {TK_CONFIG_BORDER, "-insertbackground", "insertBackground", "Foreground",
	DEF_TEXT_INSERT_BG, Tk_Offset(TkText, insertBorder), 0},
    {TK_CONFIG_PIXELS, "-insertborderwidth", "insertBorderWidth", "BorderWidth",
	DEF_TEXT_INSERT_BD_COLOR, Tk_Offset(TkText, insertBorderWidth),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_PIXELS, "-insertborderwidth", "insertBorderWidth", "BorderWidth",
	DEF_TEXT_INSERT_BD_MONO, Tk_Offset(TkText, insertBorderWidth),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_INT, "-insertofftime", "insertOffTime", "OffTime",
	DEF_TEXT_INSERT_OFF_TIME, Tk_Offset(TkText, insertOffTime), 0},
    {TK_CONFIG_INT, "-insertontime", "insertOnTime", "OnTime",
	DEF_TEXT_INSERT_ON_TIME, Tk_Offset(TkText, insertOnTime), 0},
    {TK_CONFIG_PIXELS, "-insertwidth", "insertWidth", "InsertWidth",
	DEF_TEXT_INSERT_WIDTH, Tk_Offset(TkText, insertWidth), 0},
    {TK_CONFIG_INT, "-maxundo", "maxUndo", "MaxUndo",
	"0", Tk_Offset(TkText, maxUndo), 0},
    {TK_CONFIG_BOOLEAN, "-ornamentproportional", "ornamentProportional",
	"OrnamentProportional", "0", Tk_Offset(TkText, ornProportional), 0},
    {TK_CONFIG_PIXELS, "-padx", "padX", "Pad",
	DEF_TEXT_PADX, Tk_Offset(TkText, padX), 0},
    {TK_CONFIG_PIXELS, "-pady", "padY", "Pad",
	DEF_TEXT_PADY, Tk_Offset(TkText, padY), 0},
    {TK_CONFIG_RELIEF, "-relief", "relief", "Relief",
	DEF_TEXT_RELIEF, Tk_Offset(TkText, relief), 0},
    {TK_CONFIG_BORDER, "-selectbackground", "selectBackground", "Foreground",
	DEF_TEXT_SELECT_COLOR, Tk_Offset(TkText, selBorder),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_BORDER, "-selectbackground", "selectBackground", "Foreground",
	DEF_TEXT_SELECT_MONO, Tk_Offset(TkText, selBorder),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_STRING, "-selectborderwidth", "selectBorderWidth", "BorderWidth",
	DEF_TEXT_SELECT_BD_COLOR, Tk_Offset(TkText, selBdString),
	TK_CONFIG_COLOR_ONLY|TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-selectborderwidth", "selectBorderWidth", "BorderWidth",
	DEF_TEXT_SELECT_BD_MONO, Tk_Offset(TkText, selBdString),
	TK_CONFIG_MONO_ONLY|TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-selectforeground", "selectForeground", "Background",
	DEF_TEXT_SELECT_FG_COLOR, Tk_Offset(TkText, selFgColorPtr),
	TK_CONFIG_COLOR_ONLY},
    {TK_CONFIG_COLOR, "-selectforeground", "selectForeground", "Background",
	DEF_TEXT_SELECT_FG_MONO, Tk_Offset(TkText, selFgColorPtr),
	TK_CONFIG_MONO_ONLY},
    {TK_CONFIG_BOOLEAN, "-setgrid", "setGrid", "SetGrid",
	DEF_TEXT_SET_GRID, Tk_Offset(TkText, setGrid), 0},
    {TK_CONFIG_PIXELS, "-spacing1", "spacing1", "Spacing",
	DEF_TEXT_SPACING1, Tk_Offset(TkText, spacing1),
	TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_PIXELS, "-spacing2", "spacing2", "Spacing",
	DEF_TEXT_SPACING2, Tk_Offset(TkText, spacing2),
	TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_PIXELS, "-spacing3", "spacing3", "Spacing",
	DEF_TEXT_SPACING3, Tk_Offset(TkText, spacing3),
	TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_UID, "-state", "state", "State",
	DEF_TEXT_STATE, Tk_Offset(TkText, state), 0},
    {TK_CONFIG_LANGARG, "-tabs", "tabs", "Tabs",
	DEF_TEXT_TABS, Tk_Offset(TkText, tabOptionString), TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-takefocus", "takeFocus", "TakeFocus",
	DEF_TEXT_TAKE_FOCUS, Tk_Offset(TkText, takeFocus),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-undo", "undo", "Undo",
	"0", Tk_Offset(TkText, undo), 0},
    {TK_CONFIG_CALLBACK, "-valuecommand", "valueCommand", "ValueCommand",
	"", Tk_Offset(TkText, valueCmd), TK_CONFIG_NULL_OK},
    {TK_CONFIG_INT, "-width", "width", "Width",
	DEF_TEXT_WIDTH, Tk_Offset(TkText, width), 0},
    {TK_CONFIG_UID, "-wrap", "wrap", "Wrap",
	DEF_TEXT_WRAP, Tk_Offset(TkText, wrapMode), 0},
    {TK_CONFIG_CALLBACK, "-xscrollcommand", "xScrollCommand", "ScrollCommand",
	DEF_TEXT_XSCROLL_COMMAND, Tk_Offset(TkText, xScrollCmd),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_CALLBACK, "-yscrollcommand", "yScrollCommand", "ScrollCommand",
	DEF_TEXT_YSCROLL_COMMAND, Tk_Offset(TkText, yScrollCmd),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_END,          NULL,          NULL,          NULL,
	         NULL, 0, 0}
};

/*
 * Tk_Uid's used to represent text states:
 */

Tk_Uid tkTextCharUid = NULL;
Tk_Uid tkTextDisabledUid = NULL;
Tk_Uid tkTextNoneUid = NULL;
Tk_Uid tkTextNormalUid = NULL;
Tk_Uid tkTextWordUid = NULL;

/*
 * Boolean variable indicating whether or not special debugging code
 * should be executed.
 */

int tkTextDebug = 0;

/*
 * A tag switched on in a list being re-created for undo, waiting for
 * its off-toggle (see InsertListElements):
 */

typedef struct PendingTag {
    TkTextTag *tagPtr;			/* The tag. */
    char mark[40];			/* A left-gravity mark where it was
					 * switched on. */
} PendingTag;

/*
 * What InsertListElements carries along while re-creating a list:
 */

typedef struct InsertState {
    PendingTag *pending;		/* Tags switched on but not yet off
					 * (an array that may grow). */
    int numPending;			/* How many of them. */
    int maxPending;			/* Room in the array. */
    char **rightMarks;			/* The right-gravity marks re-created
					 * so far.  They get left gravity for
					 * the time of the insertion (text
					 * inserted at an index goes before
					 * the right-gravity marks there, so
					 * they would drift to the end of it
					 * all) and their own at the end. */
    int numRight;			/* How many of them. */
    int maxRight;			/* Room in the array. */
    TkTextTag **tags;			/* The tags the list switches on or
					 * off somewhere (see ScanListTags). */
    char *tagOn;			/* For each: whether it is on at the
					 * point of the list reached. */
    int numTags;			/* How many of them. */
    int useDefects;			/* Whether the list's leaf defects
					 * (the pairs [depth, defect] of its
					 * separators) are given back. */
    TkTextLine **defectLines;		/* The leaves re-created with a
					 * defect, which they get once
					 * everything is in (an array that may
					 * grow); meanwhile they are real all
					 * the way up, so that the separators
					 * after them cut the stored tree at
					 * their own levels only. */
    int *defects;			/* Their defects. */
    int numDefects;			/* How many. */
    int maxDefects;			/* Room in the arrays. */
} InsertState;

/*
 * Forward declarations for procedures defined later in this file:
 */

static int		ConfigureText _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, int argc, Arg *args, int flags));
static int		DeleteChars _ANSI_ARGS_((TkText *textPtr,
			    char *index1String, char *index2String));
static void		DestroyText _ANSI_ARGS_((char *memPtr));
static void		InsertChars _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, char *string));
static int		SplitChars _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, int level));
static void		TextBlinkProc _ANSI_ARGS_((ClientData clientData));
static void		TextCmdDeletedProc _ANSI_ARGS_((
			    ClientData clientData));
static void		TextEventProc _ANSI_ARGS_((ClientData clientData,
			    XEvent *eventPtr));
static int		TextFetchSelection _ANSI_ARGS_((ClientData clientData,
			    int offset, char *buffer, int maxBytes));
static int		TextSearchCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
static int		TextEditCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
static int		TextEditUndo _ANSI_ARGS_((TkText *textPtr));
static int		TextEditRedo _ANSI_ARGS_((TkText *textPtr));
static void		TextGetText _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    Tcl_DString *dsPtr));
static void		GenerateModifiedEvent _ANSI_ARGS_((TkText *textPtr));
static Tcl_Obj *	TextGetList _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr));
static void		InsertList _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, Tcl_Obj *listObj));
static void		NoteLeafDefect _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, int defect,
			    struct InsertState *statePtr));
static int		CheckListDefects _ANSI_ARGS_((AV *av, int first,
			    int depth));
static void		SeparatorPair _ANSI_ARGS_((SV *inner, int *depthPtr,
			    int *defectPtr));
static void		WrapsChanged _ANSI_ARGS_((TkText *textPtr,
			    int *wraps));
static void		InsertListElements _ANSI_ARGS_((TkText *textPtr,
			    char *markName, char *startMark, AV *av, int first,
			    InsertState *statePtr));
static void		ScanListTags _ANSI_ARGS_((TkText *textPtr, AV *av,
			    int first, InsertState *statePtr));
static void		InsertListText _ANSI_ARGS_((TkText *textPtr,
			    char *markName, TkTextIndex *indexPtr, char *string,
			    InsertState *statePtr));
static char *		ListTagName _ANSI_ARGS_((SV *inner));
static void		InsertEmbedded _ANSI_ARGS_((TkText *textPtr,
			    char *markName, AV *av, int isImage));
static int		MarkOp _ANSI_ARGS_((TkText *textPtr, char *op,
			    char *name, char *extra));
static void		UpdateDirtyFlag _ANSI_ARGS_((TkText *textPtr));
static int		Abbrev _ANSI_ARGS_((Arg arg, char *word, size_t min));
static void		NotOnDummyLine _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr));
static TkTextUndoAtom *	PushEdit _ANSI_ARGS_((TkText *textPtr, int mode,
			    int type, char *index1, char *index2,
			    Tcl_Obj *string));
static int		Sprout _ANSI_ARGS_((TkText *textPtr, char *i1,
			    char *i2, int startMade, int endMade,
			    int doValues, int *raisedPtr,
			    int *rootWrappedPtr));
static int		SproutLeafIndex _ANSI_ARGS_((TkText *textPtr,
			    char *i1, int startMade, TkTextIndex *indexPtr));
static int		Flatten _ANSI_ARGS_((TkText *textPtr, void *nodePtr));
static void		PullOutStep _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr));
static void		EditOther _ANSI_ARGS_((TkText *textPtr,
			    TkTextUndoAtom *atomPtr, int revert));
static void		EditFinish _ANSI_ARGS_((TkText *textPtr,
			    char *markIndex));
static void		RecordTagChange _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    TkTextTag *tagPtr, int add, int mode));
static void		TagWithRedraw _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    TkTextTag *tagPtr, int add));
static int		KeepViewForBlock _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    int *lineOffsetPtr));
static void		ResetViewForBlock _ANSI_ARGS_((TkText *textPtr,
			    int line, int offset));
static void		DeletionSeparator _ANSI_ARGS_((TkText *textPtr));
static void		VcBegin _ANSI_ARGS_((TkText *textPtr, int argc,
			    Arg *args));
static int		VcFinish _ANSI_ARGS_((TkText *textPtr));
static int		VcSamePlace _ANSI_ARGS_((Tcl_Obj *a, Tcl_Obj *b));
static int		ModifyingCommand _ANSI_ARGS_((TkText *textPtr,
			    int argc, Arg *args));
static int		TextWidgetCmd _ANSI_ARGS_((ClientData clientData,
			    Tcl_Interp *interp, int argc, Arg *args));
static void		FlushValues _ANSI_ARGS_((TkText *textPtr));
static int		MoreFreeRounds _ANSI_ARGS_((TkText *textPtr));
#if TK_TEXT_DATA_ARRAYS
static int		DataSlotCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
#endif
static int		BlockDataParse _ANSI_ARGS_((ClientData clientData,
			    Tcl_Interp *interp, Tk_Window tkwin, Arg value,
			    char *widgRec, int offset));
static Arg		BlockDataPrint _ANSI_ARGS_((ClientData clientData,
			    Tk_Window tkwin, char *widgRec, int offset,
			    Tcl_FreeProc **freeProcPtr));
static void		DeleteBlock _ANSI_ARGS_((TkText *textPtr,
			    TkTextBlock *blockPtr));
static int		TextDumpCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
static void		DumpLine _ANSI_ARGS_((Tcl_Interp *interp, 
			    TkText *textPtr, int what, TkTextLine *linePtr,
			    TkTextLine *extLinePtr, int base, int start, int end,
			    LangCallback *command));
static int		DumpSegment _ANSI_ARGS_((Tcl_Interp *interp, char *key,
			    char *value, LangCallback *command,
			    TkTextIndex *indexPtr, int what, Arg data));


/*
 *--------------------------------------------------------------
 *
 * Tk_eTextCmd --
 *
 *	This procedure is invoked to process the "text" Tcl command.
 *	See the user documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *--------------------------------------------------------------
 */

/*
 * While a change that can be undone runs, the values it drops go to
 * the list of its undo atom (see TkTextValue): textPtr->valueCapture,
 * with the addresses of the nodes as they are before the change
 * (textPtr->valueAddresses, from TkBTreeSnapshotValues).
 */

typedef struct CaptureState {
    TkTextValue **oldCapture;
    Tcl_HashTable *oldAddresses;
    Tcl_HashTable addresses;
    int snapshot;
} CaptureState;

static void
CaptureStart(textPtr, csPtr, listPtr, index1Ptr, index2Ptr)
    TkText *textPtr;
    CaptureState *csPtr;
    TkTextValue **listPtr;		/* Where the values go. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range whose blocks' nodes
					 * may lose values, or NULL (runs
					 * only). */
{
    csPtr->oldCapture = textPtr->valueCapture;
    csPtr->oldAddresses = textPtr->valueAddresses;
    csPtr->snapshot = 0;
    textPtr->valueCapture = listPtr;
    textPtr->valueAddresses = NULL;
    if ((index1Ptr != NULL) && textPtr->haveValues) {
	TkBTreeSnapshotValues(textPtr, index1Ptr, index2Ptr,
		&csPtr->addresses);
	textPtr->valueAddresses = &csPtr->addresses;
	csPtr->snapshot = 1;
    }
}

static void
CaptureEnd(textPtr, csPtr)
    TkText *textPtr;
    CaptureState *csPtr;
{
    if (csPtr->snapshot) {
	TkBTreeFreeSnapshot(&csPtr->addresses);
    }
    textPtr->valueCapture = csPtr->oldCapture;
    textPtr->valueAddresses = csPtr->oldAddresses;
}

int
Tk_eTextCmd(clientData, interp, argc, args)
    ClientData clientData;	/* Main window associated with
				 * interpreter. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    Arg *args;		/* Argument strings. */
{
    Tk_Window tkwin = (Tk_Window) clientData;
    Tk_Window new;
    register TkText *textPtr;
    TkTextIndex startIndex;

    if (argc < 2) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		LangString(args[0]), " pathName ?options?\"",          NULL);
	return TCL_ERROR;
    }

    /*
     * Perform once-only initialization:
     */

    if (tkTextNormalUid == NULL) {
	tkTextCharUid = Tk_GetUid("char");
	tkTextDisabledUid = Tk_GetUid("disabled");
	tkTextNoneUid = Tk_GetUid("none");
	tkTextNormalUid = Tk_GetUid("normal");
	tkTextWordUid = Tk_GetUid("word");
    }

    /*
     * Create the window.
     */

    new = Tk_CreateWindowFromPath(interp, tkwin, LangString(args[1]),          NULL);
    if (new == NULL) {
	return TCL_ERROR;
    }

    textPtr = (TkText *) ckalloc(sizeof(TkText));
    textPtr->tkwin = new;
    textPtr->display = Tk_Display(new);
    textPtr->interp = interp;
    textPtr->widgetCmd = Lang_CreateWidget(interp,textPtr->tkwin, (Tcl_ObjCmdProc *) TextWidgetCmd, (ClientData) textPtr, TextCmdDeletedProc);


    textPtr->tree = TkBTreeCreate(textPtr);
    Tcl_InitHashTable(&textPtr->tagTable, TCL_STRING_KEYS);
    textPtr->numTags = 0;
    Tcl_InitHashTable(&textPtr->markTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&textPtr->windowTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&textPtr->blockTable, TCL_STRING_KEYS);
    Tcl_InitHashTable(&textPtr->imageTable, TCL_STRING_KEYS);
    textPtr->numDLines = 0;
    textPtr->dlinePtrs = NULL;
    textPtr->ornInfoPtr = NULL;
    textPtr->state = tkTextNormalUid;
    textPtr->border = NULL;
    textPtr->borderWidth = 0;
    textPtr->padX = 0;
    textPtr->padY = 0;
    textPtr->relief = TK_RELIEF_FLAT;
    textPtr->highlightWidth = 0;
    textPtr->highlightBgColorPtr = NULL;
    textPtr->highlightColorPtr = NULL;
    textPtr->cursor = None;
    textPtr->fgColor = NULL;
    textPtr->tkfont = NULL;
    textPtr->charWidth = 1;
    textPtr->spacing1 = 0;
    textPtr->spacing2 = 0;
    textPtr->spacing3 = 0;
    textPtr->tabOptionString = NULL;
    textPtr->tabArrayPtr = NULL;
    textPtr->wrapMode = tkTextCharUid;
    textPtr->width = 0;
    textPtr->height = 0;
    textPtr->setGrid = 0;
    textPtr->prevWidth = Tk_Width(new);
    textPtr->prevHeight = Tk_Height(new);
    TkTextCreateDInfo(textPtr);
    TkTextMakeByteIndex(textPtr->tree, 0, 0, &startIndex);
    TkTextSetYView(textPtr, &startIndex, 0);
    textPtr->selTagPtr = NULL;
    textPtr->selBorder = NULL;
    textPtr->selBdString = NULL;
    textPtr->selFgColorPtr = NULL;
    textPtr->exportSelection = 1;
    textPtr->abortSelections = 0;
    textPtr->insertMarkPtr = NULL;
    textPtr->insertBorder = NULL;
    textPtr->insertWidth = 0;
    textPtr->insertBorderWidth = 0;
    textPtr->insertOnTime = 0;
    textPtr->insertOffTime = 0;
    textPtr->insertBlinkHandler = (Tcl_TimerToken) NULL;
    textPtr->bindingTable = NULL;
    textPtr->currentMarkPtr = NULL;
    textPtr->pickEvent.type = LeaveNotify;
    textPtr->pickEvent.xcrossing.x = 0;
    textPtr->pickEvent.xcrossing.y = 0;
    textPtr->numCurTags = 0;
    textPtr->curTagArrayPtr = NULL;
    textPtr->takeFocus = NULL;
    textPtr->xScrollCmd = NULL;
    textPtr->yScrollCmd = NULL;
    textPtr->getFlags = 0;
    textPtr->flags = 0;
    textPtr->undoStack = TkTextUndoInitStack(0);
    textPtr->undoStack->textPtr = textPtr;
    textPtr->cmdDepth = 0;
    textPtr->haveValues = 0;
    textPtr->freeValues = NULL;
    textPtr->lastFreeValue = NULL;
    textPtr->valueCapture = NULL;
    textPtr->valueAddresses = NULL;
    textPtr->editValues = NULL;
    textPtr->editAtom = NULL;
    textPtr->rootLog = NULL;
    textPtr->freeingValues = 0;
    textPtr->freeLimit = TK_TEXT_FREE_DEPTH;
    textPtr->freeAsks = 0;
    textPtr->freeAsking = 0;
    textPtr->valueCmd = NULL;
    textPtr->vcPtr = NULL;
    textPtr->vcInCallback = 0;
    textPtr->vcTagDone = 0;
    textPtr->undo = 0;
    textPtr->maxUndo = 0;
    textPtr->autoSeparators = 1;
    textPtr->modifiedSet = 0;
    textPtr->isDirty = 0;
    textPtr->isDirtyIncrement = 1;
    textPtr->lastEditMode = TK_TEXT_EDIT_OTHER;

    /*
     * Create the "sel" tag and the "current" and "insert" marks.
     */

    textPtr->selTagPtr = TkTextCreateTag(textPtr, "sel");
    textPtr->selTagPtr->reliefString = (char *) ckalloc(7);
    strcpy(textPtr->selTagPtr->reliefString, "raised");
    textPtr->selTagPtr->relief = TK_RELIEF_RAISED;
    textPtr->currentMarkPtr = TkTextSetMark(textPtr, "current", &startIndex);
    textPtr->insertMarkPtr = TkTextSetMark(textPtr, "insert", &startIndex);

    Tk_SetClass(new, TEXT_Class);
    Tk_CreateEventHandler(textPtr->tkwin,
	    ExposureMask|StructureNotifyMask|FocusChangeMask,
	    TextEventProc, (ClientData) textPtr);
    Tk_CreateEventHandler(textPtr->tkwin, KeyPressMask|KeyReleaseMask
	    |ButtonPressMask|ButtonReleaseMask|EnterWindowMask
	    |LeaveWindowMask|PointerMotionMask, TkTextBindProc,
	    (ClientData) textPtr);
    Tk_CreateSelHandler(textPtr->tkwin, XA_PRIMARY, XA_STRING,
	    TextFetchSelection, (ClientData) textPtr, XA_STRING);
    if (ConfigureText(interp, textPtr, argc-2, args+2, 0) != TCL_OK) {
	Tk_DestroyWindow(textPtr->tkwin);
	return TCL_ERROR;
    }
    Tcl_ArgResult(interp,LangWidgetArg(interp,textPtr->tkwin));

    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * TextWidgetCmd --
 *
 *	This procedure is invoked to process the Tcl command
 *	that corresponds to a text widget.  See the user
 *	documentation for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *--------------------------------------------------------------
 */

static int
TextWidgetCmd(clientData, interp, argc, args)
    ClientData clientData;	/* Information about text widget. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    Arg *args;		/* Argument strings. */
{
    register TkText *textPtr = (TkText *) clientData;
    int result = TCL_OK;
    size_t length;
    int c, ownStep = 0;
    TkTextIndex index1, index2;

    if (argc < 2) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		LangString(args[0]), " option ?arg arg ...?\"",          NULL);
	return TCL_ERROR;
    }
    if (textPtr->vcInCallback && ModifyingCommand(textPtr, argc, args)) {
	Tcl_AppendResult(interp, "cannot modify ", LangString(args[0]),
		" while its -valuecommand runs", NULL);
	return TCL_ERROR;
    }
    Tcl_Preserve((ClientData) textPtr);
    if (textPtr->freeingValues && ModifyingCommand(textPtr, argc, args)) {
	/*
	 * A DESTROY method changes the widget while the values a command
	 * dropped are being freed (FlushValues): allowed, as a change of
	 * its own for the undo, unless the chain of such changes has
	 * reached the limit of this freeing pass (TK_TEXT_FREE_DEPTH, or
	 * more if DESTROYmult raised it) and DESTROYmult does not raise
	 * it now.
	 */

	if ((textPtr->freeingValues >= textPtr->freeLimit)
		&& !MoreFreeRounds(textPtr)) {
	    char buffer[TCL_INTEGER_SPACE];

	    sprintf(buffer, "%d", textPtr->freeLimit);
	    Tcl_AppendResult(interp, "cannot modify ", LangString(args[0]),
		    " while its values are being freed, ", buffer,
		    " changes deep", NULL);
	    Tcl_Release((ClientData) textPtr);
	    return TCL_ERROR;
	}
	ownStep = 1;
    }
    if (ownStep && textPtr->undo) {
	TkTextUndoInsertUndoSeparator(textPtr->undoStack);
    }
    if ((textPtr->cmdDepth == 0) && (textPtr->valueCmd != NULL)
	    && (textPtr->vcPtr == NULL)) {
	VcBegin(textPtr, argc, args);
    }
    textPtr->cmdDepth++;
    c = LangString(args[1])[0];
    length = strlen(LangString(args[1]));
    if ((c == 'b') && (strncmp(LangString(args[1]), "bbox", length) == 0) 
	&& (length >= 2)) {
	int x, y, width, height;

	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " bbox index\"",          NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[2]), &index1) != TCL_OK) {
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextCharBbox(textPtr, &index1, &x, &y, &width, &height) == 0) {
	    Tcl_IntResults(interp,4,0, x, y, width, height);
	}
    } else if ((c == 'b') && (strncmp(LangString(args[1]), "block", length) == 0)
	    && (length >= 2)) {
	result = TkTextBlockCmd(textPtr, interp, argc, args);
    } else if ((c == 'c') && (strncmp(LangString(args[1]), "cget", length) == 0)
	    && (length >= 2)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " cget option\"",
		             NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	result = Tk_ConfigureValue(interp, textPtr->tkwin, configSpecs,
		(char *) textPtr, LangString(args[2]), 0);
    } else if ((c == 'c') && (strncmp(LangString(args[1]), "compare", length) == 0)
	    && (length >= 3)) {
	int relation, value;
	char *p;

	if (argc != 5) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " compare index1 op index2\"",          NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if ((TkTextGetIndex(interp, textPtr, LangString(args[2]), &index1) != TCL_OK)
		|| (TkTextGetIndex(interp, textPtr, LangString(args[4]), &index2)
		!= TCL_OK)) {
	    result = TCL_ERROR;
	    goto done;
	}
	relation = TkTextIndexCmp(&index1, &index2);
	p = LangString(args[3]);
	if (p[0] == '<') {
		value = (relation < 0);
	    if ((p[1] == '=') && (p[2] == 0)) {
		value = (relation <= 0);
	    } else if (p[1] != 0) {
		compareError:
		Tcl_AppendResult(interp, "bad comparison operator \"",
			LangString(args[3]), "\": must be <, <=, ==, >=, >, or !=",
			         NULL);
		result = TCL_ERROR;
		goto done;
	    }
	} else if (p[0] == '>') {
		value = (relation > 0);
	    if ((p[1] == '=') && (p[2] == 0)) {
		value = (relation >= 0);
	    } else if (p[1] != 0) {
		goto compareError;
	    }
	} else if ((p[0] == '=') && (p[1] == '=') && (p[2] == 0)) {
	    value = (relation == 0);
	} else if ((p[0] == '!') && (p[1] == '=') && (p[2] == 0)) {
	    value = (relation != 0);
	} else {
	    goto compareError;
	}
	Tcl_SetResult(interp, (value) ? "1" : "0",TCL_STATIC);
    } else if ((c == 'c') && (strncmp(LangString(args[1]), "configure", length) == 0)
	    && (length >= 3)) {
	if (argc == 2) {
	    result = Tk_ConfigureInfo(interp, textPtr->tkwin, configSpecs,
		    (char *) textPtr,          NULL, 0);
	} else if (argc == 3) {
	    result = Tk_ConfigureInfo(interp, textPtr->tkwin, configSpecs,
		    (char *) textPtr, LangString(args[2]), 0);
	} else {
	    result = ConfigureText(interp, textPtr, argc-2, args+2,
		    TK_CONFIG_ARGV_ONLY);
	}
    } else if ((c == 'd') && (strncmp(LangString(args[1]), "debug", length) == 0)
	    && (length >= 3)) {
	if (argc > 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " debug boolean\"",          NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (argc == 2) {
	    Tcl_SetResult(interp, (tkBTreeDebug) ? "1" : "0",TCL_STATIC);
	} else {
	    if (Tcl_GetBooleanFromObj(interp, args[2], &tkBTreeDebug) != TCL_OK) {
		result = TCL_ERROR;
		goto done;
	    }
	    tkTextDebug = tkBTreeDebug;
	}
    } else if ((c == 'd') && (strncmp(LangString(args[1]), "delete", length) == 0)
	    && (length >= 3)) {
	if ((argc != 3) && (argc != 4)) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " delete index1 ?index2?\"",          NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (textPtr->state == tkTextNormalUid) {
	    result = DeleteChars(textPtr, LangString(args[2]),
		    (argc == 4) ? LangString(args[3]) :          NULL);
	}
    } else if ((c == 'd') && (strncmp(LangString(args[1]), "dlineinfo", length) == 0)
	    && (length >= 2)) {
	int x, y, width, height, base;

	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " dlineinfo index\"",          NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[2]), &index1) != TCL_OK) {
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextDLineInfo(textPtr, &index1, &x, &y, &width, &height, &base)
		== 0) {
	    Tcl_IntResults(interp,5,0, x, y, width,
		    height, base);
	}
    } else if ((c == 'e') && (strncmp(LangString(args[1]), "edit", length) == 0)) {
	result = TextEditCmd(textPtr, interp, argc, args);
    } else if ((c == 'g') && (strncmp(LangString(args[1]), "get", length) == 0)) {
        Tcl_DString dstring;
	TkTextLine *linePtr;
	int offset;

	if ((argc != 3) && (argc != 4)) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " get index1 ?index2?\"",          NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[2]), &index1) != TCL_OK) {
	    result = TCL_ERROR;
	    goto done;
	}
	if (argc == 3) {
	    index2 = index1;
	    TkTextIndexForwChars(&index2, 1, &index2);
	} else if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index2)
		!= TCL_OK) {
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextIndexCmp(&index1, &index2) >= 0) {
	    goto done;
	}
	linePtr = index1.linePtr;
	offset = index1.byteIndex; 
	Tcl_DStringInit(&dstring);
	while (linePtr != index2.linePtr) {
	  TkBTreeLineTextAppend(textPtr, linePtr, offset, -1, 
				(void*)&dstring, 
				TkTextUserGetFlags(textPtr) | TKT_GET_DSTRING, NULL);
	  offset = -1;			/* Report all of the rest */
	  linePtr = TkBTreeNextLine(linePtr);
	}
	TkBTreeLineTextAppend(textPtr, linePtr, offset, index2.byteIndex,
			      (void*)&dstring, 
			      TkTextUserGetFlags(textPtr) | TKT_GET_DSTRING, NULL);
	Tcl_AppendResult(interp, Tcl_DStringValue(&dstring),          NULL);
	Tcl_DStringFree(&dstring);
    } else if ((c == 'i') && (strncmp(LangString(args[1]), "image", length) == 0)
	    && (length >= 2)) {
	result = TkTextImageCmd(textPtr, interp, argc, args);
    } else if ((c == 'i') && (strncmp(LangString(args[1]), "index", length) == 0)
	    && (length >= 3)) {
        char buffer[80];
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " index index\"",
		             NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[2]), &index1) != TCL_OK) {
	    result = TCL_ERROR;
	    goto done;
	}

	TkTextPrintIndex(&index1, buffer);
        Tcl_SetResult(interp,buffer,TCL_VOLATILE);
    } else if ((c == 'i') && (strncmp(LangString(args[1]), "insert", length) == 0)
	    && (length >= 3)) {
	int i, j, numTags;
	Arg *tagNames;
	TkTextTag **oldTagArrayPtr;

	if (argc < 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]),
		    " insert index chars ?tagList chars tagList ...?\"",
		             NULL);
	    result = TCL_ERROR;
	    goto done;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[2]), &index1) != TCL_OK) {
	    result = TCL_ERROR;
	    goto done;
	}
	if (textPtr->state == tkTextNormalUid) {
	    for (j = 3;  j < argc; j += 2) {
		InsertChars(textPtr, &index1, LangString(args[j]));
		if (argc > (j+1)) {
		    LangFreeProc *freeProc = NULL;
		    TkTextIndexForwBytes(&index1, (int) strlen(LangString(args[j])),
			    &index2);
		    oldTagArrayPtr = TkBTreeGetTags(&index1, &numTags);
		    if (oldTagArrayPtr != NULL) {
			for (i = 0; i < numTags; i++) {
			    TkBTreeTag(&index1, &index2, oldTagArrayPtr[i], 0);
			}
			ckfree((char *) oldTagArrayPtr);
		    }
		    if (Lang_SplitList(interp, args[j+1], &numTags, &tagNames, &freeProc)
			    != TCL_OK) {
			result = TCL_ERROR;
			goto done;
		    }
		    for (i = 0; i < numTags; i++) {
			TkBTreeTag(&index1, &index2,
				TkTextCreateTag(textPtr, LangString(tagNames[i])), 1);
		    }
		    if (freeProc)
			(*freeProc) (numTags, tagNames);
		    index1 = index2;
		}
	    }
	}
    } else if ((c == 'd') && (strncmp(LangString(args[1]), "dump", length) == 0)) {
	result = TextDumpCmd(textPtr, interp, argc, args);
    } else if ((c == 'o') && (strncmp(LangString(args[1]), "ornament", length) == 0)) {
	result = TkTextOrnamentCmd(textPtr, interp, argc, args);
    } else if ((c == 'm') && (strncmp(LangString(args[1]), "mark", length) == 0)) {
	result = TkTextMarkCmd(textPtr, interp, argc, args);
    } else if ((c == 's') && (strcmp(LangString(args[1]), "scan") == 0) && (length >= 2)) {
	result = TkTextScanCmd(textPtr, interp, argc, args);
    } else if ((c == 's') && (strcmp(LangString(args[1]), "search") == 0)
	    && (length >= 3)) {
	result = TextSearchCmd(textPtr, interp, argc, args);
    } else if ((c == 's') && (strcmp(LangString(args[1]), "see") == 0) && (length >= 3)) {
	result = TkTextSeeCmd(textPtr, interp, argc, args);
    } else if ((c == 't') && (strcmp(LangString(args[1]), "tag") == 0)) {
	result = TkTextTagCmd(textPtr, interp, argc, args);
    } else if ((c == 'w') && (strncmp(LangString(args[1]), "window", length) == 0)) {
	result = TkTextWindowCmd(textPtr, interp, argc, args);
    } else if ((c == 'x') && (strncmp(LangString(args[1]), "xview", length) == 0)) {
	result = TkTextXviewCmd(textPtr, interp, argc, args);
    } else if ((c == 'y') && (strncmp(LangString(args[1]), "yview", length) == 0)
	    && (length >= 2)) {
	result = TkTextYviewCmd(textPtr, interp, argc, args);
#if TK_TEXT_DATA_ARRAYS
    } else if (strcmp(LangString(args[1]), "_dataslot") == 0) {
	result = DataSlotCmd(textPtr, interp, argc, args);
#endif
    } else {
	Tcl_AppendResult(interp, "bad option \"", LangString(args[1]),
		"\": must be bbox, block, cget, compare, configure, debug, delete, ",
		"dlineinfo, edit, get, image, index, insert, mark, ornament, scan, search, see, ",
		"tag, window, xview, or yview",
		         NULL);
	result = TCL_ERROR;
    }

    done:
    /*
     * What the -valuecommand is told at the end of the command (values
     * of discarded undo steps, detaches not foreseen); then the values
     * the command dropped are freed now that the text is consistent
     * again (a value's DESTROY method may use the widget).
     */

    if ((textPtr->cmdDepth == 1) && (textPtr->vcPtr != NULL)
	    && (VcFinish(textPtr) != TCL_OK)) {
	result = TCL_ERROR;
    }
    if (ownStep && textPtr->undo) {
	TkTextUndoInsertUndoSeparator(textPtr->undoStack);
	textPtr->lastEditMode = TK_TEXT_EDIT_OTHER;
    }

    /*
     * Not while values are being freed: those this command dropped (a
     * DESTROY method changed the widget) join the list being freed.
     */

    if ((--textPtr->cmdDepth == 0) && (textPtr->freeValues != NULL)
	    && !textPtr->freeingValues) {
	FlushValues(textPtr);
    }
    Tcl_Release((ClientData) textPtr);
    return result;
}

/*
 *--------------------------------------------------------------
 *
 * ModifyingCommand --
 *
 *	Whether a widget command would modify the widget: its text,
 *	tags, marks, blocks, embedded images and windows, values, the
 *	configuration of the widget, its tags, blocks, images and
 *	windows, the undo history or the modified flag, or would create
 *	a tag or a block type (a query of tag configure, tag bind or
 *	block configure of one that does not exist).  Commands that
 *	only read, or only change the view (see, xview, yview, scan) or
 *	the B-tree check (debug), do not.
 *
 *	Such commands are refused while the -valuecommand runs (the
 *	command that called it has not made its change yet).  While the
 *	values a command dropped are being freed (FlushValues), they are
 *	allowed, each as a change of its own for the undo, up to
 *	TK_TEXT_FREE_DEPTH rounds deep unless DESTROYmult allows more
 *	(MoreFreeRounds; in 2.04 they were refused there
 *	too, a stopgap until -valuecommand told the program where a
 *	value was before it was detached).
 *
 * Results:
 *	Non-zero if the command modifies the widget.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
Abbrev(arg, word, min)
    Arg arg;			/* The word given. */
    char *word;			/* The full name of the subcommand. */
    size_t min;			/* The shortest abbreviation accepted. */
{
    char *s = LangString(arg);
    size_t length = strlen(s);

    if (min < 1) {
	min = 1;
    }
    return (length >= min) && (strncmp(s, word, length) == 0);
}

static int
ModifyingCommand(textPtr, argc, args)
    TkText *textPtr;		/* The widget. */
    int argc;			/* Number of arguments. */
    Arg *args;			/* Argument strings. */
{
    Arg *sub = args + 2;

    if (Abbrev(args[1], "delete", 3) || Abbrev(args[1], "insert", 3)) {
	return 1;
    }
    if (Abbrev(args[1], "configure", 3)) {
	return argc > 3;
    }
    if (argc < 3) {
	return 0;
    }
    if (Abbrev(args[1], "block", 2)) {
	if (Abbrev(*sub, "configure", 2)) {
	    /*
	     * A query is allowed if the type exists (it would create it
	     * otherwise).
	     */

	    return (argc > 5) || ((argc >= 4)
		    && (Tcl_FindHashEntry(&textPtr->blockTable,
			    LangString(args[3])) == NULL));
	}
	if (Abbrev(*sub, "data", 2)) {
	    return argc == 5;
	}
	if (Abbrev(*sub, "nodedata", 2)) {
	    return argc == 6;
	}
	if (strcmp(LangString(*sub), "delete") == 0) {
	    return 1;
	}
	return Abbrev(*sub, "trim", 1) || Abbrev(*sub, "insert", 1)
		|| Abbrev(*sub, "split", 1) || Abbrev(*sub, "sprout", 3)
		|| Abbrev(*sub, "flatten", 1)
		|| Abbrev(*sub, "addline", 2)
		|| ((strlen(LangString(*sub)) > 6)
			&& Abbrev(*sub, "deletelines", 7));
    }
    if (Abbrev(args[1], "edit", 1)) {
	if (Abbrev(*sub, "modified", 1)) {
	    return argc > 3;
	}
	return Abbrev(*sub, "redo", 3) || Abbrev(*sub, "reset", 3)
		|| Abbrev(*sub, "separator", 1) || Abbrev(*sub, "undo", 1);
    }
    if (Abbrev(args[1], "image", 2) || Abbrev(args[1], "window", 1)) {
	if (Abbrev(*sub, "configure", 2)) {
	    return argc > 5;
	}
	return Abbrev(*sub, "create", 2);
    }
    if (Abbrev(args[1], "mark", 1)) {
	if (Abbrev(*sub, "data", 1) || Abbrev(*sub, "gravity", 1)) {
	    return argc > 4;
	}
	return Abbrev(*sub, "set", 1) || Abbrev(*sub, "unset", 1);
    }
    if (strcmp(LangString(args[1]), "tag") == 0) {
	if (Abbrev(*sub, "configure", 2) || Abbrev(*sub, "bind", 1)) {
	    /*
	     * A query is allowed if the tag exists (it would create it
	     * otherwise).
	     */

	    return (argc > 5) || ((argc >= 4)
		    && (Tcl_FindHashEntry(&textPtr->tagTable,
			    LangString(args[3])) == NULL));
	}
	if (Abbrev(*sub, "data", 2)) {
	    return argc > 5;
	}
	return Abbrev(*sub, "add", 1) || Abbrev(*sub, "remove", 2)
		|| Abbrev(*sub, "delete", 1) || Abbrev(*sub, "raise", 3)
		|| Abbrev(*sub, "lower", 1);
    }
    return 0;
}

/*
 *======================================================================
 *
 * -valuecommand: telling the program which values a change detaches.
 *
 *	A value (of a node, a run, a mark, a block: see "Values" in the
 *	manual) leaves its place by a change: it is dropped (freed when
 *	the widget command ends), stashed in an undo step, or moved to
 *	another owner by a merge.  With a -valuecommand, every widget
 *	command keeps a table of what it was told and what happened
 *	(TkTextVcState, from VcBegin to VcFinish, keyed by the value's
 *	Lang part, which keeps its identity while the containers move):
 *
 *	- before each change that may detach values, its look-ahead
 *	  (TkBTreeVcPredict... in tkTextBTree.c, or the command itself
 *	  for setting and unsetting) records each value it will detach
 *	  (TkTextVcPredict), with the place it has, and TkTextVcNotify
 *	  calls the callback for each while the text is unchanged;
 *	- the change reports what it does (TkTextVcSeen: from the free
 *	  list, the undo records, the merges); an undo or a redo that
 *	  gives a value back calls the callback ("restore",
 *	  TkTextVcRestored) once the value is back; values of discarded
 *	  undo steps are reported at the end ("discard",
 *	  TkTextVcDiscarded);
 *	- at the end, a value that was detached without having been
 *	  foreseen is reported "late", with the place it had if the
 *	  look-ahead saw it (TkTextVcCandidate), and under "debug" the
 *	  command fails (as for a foreseen detach that did not happen),
 *	  so that tests catch the look-ahead's mistakes.
 *
 *	The callback runs with the widget readable but not modifiable
 *	(vcInCallback, see TextWidgetCmd); an error in it is reported as
 *	a background error.  Without the option nothing of this runs.
 *
 *======================================================================
 */

typedef struct TkTextVcEntry {
    Arg id;				/* The value (its Lang part). */
    int kind;				/* TK_TEXT_VC_NODE... */
    int predicted;			/* The event the callback was told
					 * before the change, or 0. */
    int actual;				/* What happened last, or 0. */
    int predictedMask;			/* All the events foreseen (1 << event):
					 * a value that "block sprout" shares
					 * between owners may be foreseen to go
					 * from each in another way. */
    int pending;			/* Told nothing yet. */
    Tcl_Obj *where;			/* Its place, before the change (and,
					 * for a move, the new one), or NULL. */
    struct TkTextVcEntry *nextPtr;	/* All entries, in order. */
} TkTextVcEntry;

typedef struct TkTextVcPost {
    int event, kind;
    Tcl_Obj *where;			/* Owned, or NULL. */
    Arg value;				/* A reference of its own. */
    struct TkTextVcPost *nextPtr;
} TkTextVcPost;

typedef struct TkTextVcPending {
    TkTextVcEntry *entryPtr;		/* The value. */
    int event;				/* For another owner of a shared value: */
    Tcl_Obj *where;			/* its event and place (owned); NULL for
					 * the entry's own. */
} TkTextVcPending;

typedef struct TkTextVcState {
    Tcl_HashTable table;		/* Arg -> TkTextVcEntry. */
    TkTextVcEntry *first, *last;
    TkTextVcPending *pending;		/* To tell (TkTextVcNotify). */
    int numPending, maxPending;
    TkTextVcPost *post, *lastPost;	/* To tell at the end. */
    char *cause;			/* The command. */
    int noNew;				/* An undo or a redo: what it
					 * re-creates is not told "new". */
} TkTextVcState;

static char *vcEvents[] = {
    "", "drop", "stash", "move", "restore", "discard", "late", "copy", "new"
};
static char *vcKinds[] = {
    "", "node", "run", "mark", "block"
};

/*
 * The cause given to the callback: the command, or "set" for the
 * commands that set a value (block nodedata, block data, tag data, mark
 * data) and "unset" for mark unset.
 */

static char *
VcCause(argc, args)
    int argc;
    Arg *args;
{
    if (Abbrev(args[1], "delete", 3)) {
	return "delete";
    }
    if (Abbrev(args[1], "insert", 3)) {
	return "insert";
    }
    if ((strcmp(LangString(args[1]), "tag") == 0) && (argc > 2)) {
	if (Abbrev(args[2], "add", 1)) {
	    return "tag add";
	}
	if (Abbrev(args[2], "remove", 2)) {
	    return "tag remove";
	}
	if (Abbrev(args[2], "delete", 1)) {
	    return "tag delete";
	}
	return Abbrev(args[2], "data", 2) ? "set" : "tag";
    }
    if (Abbrev(args[1], "mark", 1) && (argc > 2)) {
	if (Abbrev(args[2], "unset", 1)) {
	    return "unset";
	}
	return Abbrev(args[2], "data", 1) ? "set" : "mark";
    }
    if (Abbrev(args[1], "block", 2) && (argc > 2)) {
	if (Abbrev(args[2], "insert", 1)) {
	    return "block insert";
	}
	if (Abbrev(args[2], "trim", 1)) {
	    return "block trim";
	}
	if (Abbrev(args[2], "sprout", 3)) {
	    return "block sprout";
	}
	if (Abbrev(args[2], "flatten", 1)) {
	    return "block flatten";
	}
	if (Abbrev(args[2], "split", 1)) {
	    return "block split";
	}
	if (Abbrev(args[2], "data", 2) || Abbrev(args[2], "nodedata", 2)) {
	    return "set";
	}
	return "block";
    }
    if (Abbrev(args[1], "edit", 1) && (argc > 2)) {
	if (Abbrev(args[2], "undo", 1)) {
	    return "undo";
	}
	if (Abbrev(args[2], "redo", 3)) {
	    return "redo";
	}
	if (Abbrev(args[2], "reset", 3)) {
	    return "reset";
	}
	if (Abbrev(args[2], "separator", 1)) {
	    return "separator";
	}
	return "edit";
    }
    if (Abbrev(args[1], "configure", 3)) {
	return "configure";
    }
    return LangString(args[1]);
}

static void
VcBegin(textPtr, argc, args)
    TkText *textPtr;
    int argc;
    Arg *args;
{
    TkTextVcState *vcPtr = (TkTextVcState *) ckalloc(sizeof(TkTextVcState));
    char *cause = VcCause(argc, args);

    Tcl_InitHashTable(&vcPtr->table, TCL_ONE_WORD_KEYS);
    vcPtr->first = vcPtr->last = NULL;
    vcPtr->pending = NULL;
    vcPtr->numPending = vcPtr->maxPending = 0;
    vcPtr->post = vcPtr->lastPost = NULL;
    vcPtr->cause = ckalloc((unsigned) (strlen(cause) + 1));
    strcpy(vcPtr->cause, cause);
    vcPtr->noNew = (strcmp(cause, "undo") == 0) || (strcmp(cause, "redo") == 0);
    textPtr->vcPtr = vcPtr;
}

static TkTextVcEntry *
VcEntry(vcPtr, id, kind)
    TkTextVcState *vcPtr;
    Arg id;
    int kind;
{
    int new;
    Tcl_HashEntry *hPtr = Tcl_CreateHashEntry(&vcPtr->table, (char *) id,
	    &new);
    TkTextVcEntry *entryPtr;

    if (!new) {
	entryPtr = (TkTextVcEntry *) Tcl_GetHashValue(hPtr);
	if (kind != 0) {
	    entryPtr->kind = kind;
	}
	return entryPtr;
    }
    entryPtr = (TkTextVcEntry *) ckalloc(sizeof(TkTextVcEntry));
    entryPtr->id = id;
    entryPtr->kind = kind;
    entryPtr->predicted = entryPtr->actual = entryPtr->pending = 0;
    entryPtr->predictedMask = 0;
    entryPtr->where = NULL;
    entryPtr->nextPtr = NULL;
    if (vcPtr->last == NULL) {
	vcPtr->first = entryPtr;
    } else {
	vcPtr->last->nextPtr = entryPtr;
    }
    vcPtr->last = entryPtr;
    Tcl_SetHashValue(hPtr, entryPtr);
    return entryPtr;
}

/*
 * Call the callback: ($widget, $event, $kind, $where, $value, $cause).
 * The interpreter's result is kept; an error is a background error.
 */

static void
VcCall(textPtr, event, kind, where, value)
    TkText *textPtr;
    int event, kind;
    Tcl_Obj *where;
    Arg value;
{
    Tcl_Interp *interp = textPtr->interp;
    Tcl_Obj *resultPtr;
    Arg widget;
    int code;

    if ((textPtr->valueCmd == NULL) || (textPtr->tkwin == NULL)
	    || (textPtr->vcPtr == NULL)) {
	return;
    }
    resultPtr = Tcl_GetObjResult(interp);
    resultPtr = (resultPtr != NULL) ? newSVsv(resultPtr) : NULL;
    widget = LangWidgetObj(interp, textPtr->tkwin);
    textPtr->vcInCallback++;
    code = LangDoCallback(interp, textPtr->valueCmd, 0, 6,
	    "%_ %s %s %_ %_ %s", widget, vcEvents[event], vcKinds[kind],
	    where, value, textPtr->vcPtr->cause);
    textPtr->vcInCallback--;
    if (code != TCL_OK) {
	Tcl_AddErrorInfo(interp, "\n    (-valuecommand of text widget)");
	Tcl_BackgroundError(interp);
    }
    Tcl_DecrRefCount(widget);
    if (resultPtr != NULL) {
	Tcl_SetObjResult(interp, resultPtr);
    } else {
	Tcl_ResetResult(interp);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextVcNodePlace, TkTextVcRunPlace, TkTextVcMarkPlace,
 * TkTextVcBlockPlace --
 *
 *	The places given to the callback ($where): [index, level] for a
 *	node (the position where its first leaf starts, as "line.char",
 *	and its level, 0 for a leaf), [tag, start, end] for a run
 *	([tag, start] if the end is not known), [name, index] for a mark,
 *	[index] for a block (of its head).  A position is converted with
 *	the text as it is now; a line that does not exist any more (a
 *	discarded undo step) gives "line.byte" as recorded.
 *
 * Results:
 *	A new list (owned by the caller).
 *
 *----------------------------------------------------------------------
 */

static Tcl_Obj *
VcPosition(textPtr, line, byteIndex)
    TkText *textPtr;
    int line, byteIndex;
{
    TkTextIndex index;
    char buffer[TK_POS_CHARS + 2 * TCL_INTEGER_SPACE];

    if ((line >= 0) && (byteIndex >= 0)
	    && (line < TkBTreeNumLines(textPtr->tree))) {
	TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &index);
	TkTextPrintIndex(&index, buffer);
    } else {
	sprintf(buffer, "%d.%d", line + 1, byteIndex);
    }
    return Tcl_NewStringObj(buffer, -1);
}

static Tcl_Obj *
VcIndex(indexPtr)
    TkTextIndex *indexPtr;
{
    char buffer[TK_POS_CHARS];

    TkTextPrintIndex(indexPtr, buffer);
    return Tcl_NewStringObj(buffer, -1);
}

Tcl_Obj *
TkTextVcNodePlace(textPtr, line, byteIndex, level)
    TkText *textPtr;
    int line, byteIndex, level;
{
    Tcl_Obj *listPtr = Tcl_NewListObj(0, NULL);

    Tcl_ListObjAppendElement(NULL, listPtr,
	    VcPosition(textPtr, line, byteIndex));
    Tcl_ListObjAppendElement(NULL, listPtr, Tcl_NewIntObj(level));
    return listPtr;
}

Tcl_Obj *
TkTextVcRunPlace(textPtr, tagName, startPtr, endPtr)
    TkText *textPtr;
    char *tagName;
    TkTextIndex *startPtr, *endPtr;	/* endPtr may be NULL. */
{
    Tcl_Obj *listPtr = Tcl_NewListObj(0, NULL);

    Tcl_ListObjAppendElement(NULL, listPtr, Tcl_NewStringObj(tagName, -1));
    Tcl_ListObjAppendElement(NULL, listPtr, VcIndex(startPtr));
    if (endPtr != NULL) {
	Tcl_ListObjAppendElement(NULL, listPtr, VcIndex(endPtr));
    }
    return listPtr;
}

Tcl_Obj *
TkTextVcMarkPlace(textPtr, markName, indexPtr)
    TkText *textPtr;
    char *markName;
    TkTextIndex *indexPtr;
{
    Tcl_Obj *listPtr = Tcl_NewListObj(0, NULL);

    Tcl_ListObjAppendElement(NULL, listPtr, Tcl_NewStringObj(markName, -1));
    Tcl_ListObjAppendElement(NULL, listPtr, VcIndex(indexPtr));
    return listPtr;
}

Tcl_Obj *
TkTextVcBlockPlace(textPtr, line, byteIndex)
    TkText *textPtr;
    int line, byteIndex;
{
    Tcl_Obj *listPtr = Tcl_NewListObj(0, NULL);

    Tcl_ListObjAppendElement(NULL, listPtr,
	    VcPosition(textPtr, line, byteIndex));
    return listPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextVcPredict, TkTextVcCandidate, TkTextVcNotify --
 *
 *	The look-ahead's results: a value the change will detach (the
 *	event: TK_TEXT_VC_DROP, _STASH or _MOVE, with the new place for
 *	a move, which goes at the end of $where); a value it looked at
 *	and that stays (only its place is kept, for a late report); then
 *	the calls of the callback for the values predicted, in order.
 *
 * Side effects:
 *	where and to are consumed.
 *
 *----------------------------------------------------------------------
 */

void
TkTextVcPredict(textPtr, value, event, kind, where, to)
    TkText *textPtr;
    TkTextData value;
    int event, kind;
    Tcl_Obj *where, *to;
{
    TkTextVcState *vcPtr = TkTextVcOn(textPtr) ? textPtr->vcPtr : NULL;
    TkTextVcEntry *entryPtr;
    Arg id = TkTextDataGetLang(value);

    if ((vcPtr == NULL) || (id == NULL)) {
	if (where != NULL) {
	    Tcl_DecrRefCount(where);
	}
	if (to != NULL) {
	    Tcl_DecrRefCount(to);
	}
	return;
    }
    entryPtr = VcEntry(vcPtr, id, kind);
    if ((to != NULL) && (where != NULL)) {
	Tcl_ListObjAppendElement(NULL, where, to);
    } else if (to != NULL) {
	Tcl_DecrRefCount(to);
    }
    entryPtr->predictedMask |= 1 << event;
    if (vcPtr->numPending >= vcPtr->maxPending) {
	TkTextVcPending *grown;

	vcPtr->maxPending = 2 * vcPtr->maxPending + 16;
	grown = (TkTextVcPending *) ckalloc((unsigned)
		(vcPtr->maxPending * sizeof(TkTextVcPending)));
	if (vcPtr->numPending > 0) {
	    memcpy(grown, vcPtr->pending,
		    vcPtr->numPending * sizeof(TkTextVcPending));
	}
	if (vcPtr->pending != NULL) {
	    ckfree((char *) vcPtr->pending);
	}
	vcPtr->pending = grown;
    }
    if (entryPtr->pending && !VcSamePlace(entryPtr->where, where)) {
	/*
	 * Another owner of the same value (shared by block sprout):
	 * told too, with its own place.
	 */

	TkTextVcPending *pPtr = &vcPtr->pending[vcPtr->numPending++];

	pPtr->entryPtr = entryPtr;
	pPtr->event = event;
	pPtr->where = where;
	if ((event == TK_TEXT_VC_DROP) || (event == TK_TEXT_VC_STASH)) {
	    entryPtr->predicted = event;
	}
	return;
    }
    if (entryPtr->where != NULL) {
	Tcl_DecrRefCount(entryPtr->where);
    }
    entryPtr->where = where;
    entryPtr->predicted = event;
    entryPtr->actual = 0;
    if (!entryPtr->pending) {
	vcPtr->pending[vcPtr->numPending].entryPtr = entryPtr;
	vcPtr->pending[vcPtr->numPending].event = 0;
	vcPtr->pending[vcPtr->numPending++].where = NULL;
	entryPtr->pending = 1;
    }
}

/*
 * Whether two places (as TkTextVcNodePlace and the others make them)
 * name the same owner: their first two elements are the same.
 */

static int
VcSamePlace(a, b)
    Tcl_Obj *a, *b;
{
    Tcl_Obj **av, **bv;
    int ac, bc, i;

    if ((a == NULL) || (b == NULL)) {
	return (a == b);
    }
    if ((Tcl_ListObjGetElements(NULL, a, &ac, &av) != TCL_OK)
	    || (Tcl_ListObjGetElements(NULL, b, &bc, &bv) != TCL_OK)) {
	return 1;
    }
    for (i = 0; i < 2; i++) {
	if ((i >= ac) || (i >= bc)) {
	    return (ac == bc);
	}
	if (strcmp(Tcl_GetString(av[i]), Tcl_GetString(bv[i])) != 0) {
	    return 0;
	}
    }
    return 1;
}

void
TkTextVcCandidate(textPtr, value, kind, where)
    TkText *textPtr;
    TkTextData value;
    int kind;
    Tcl_Obj *where;
{
    TkTextVcState *vcPtr = TkTextVcOn(textPtr) ? textPtr->vcPtr : NULL;
    TkTextVcEntry *entryPtr;
    Arg id = TkTextDataGetLang(value);

    if ((vcPtr == NULL) || (id == NULL)) {
	if (where != NULL) {
	    Tcl_DecrRefCount(where);
	}
	return;
    }
    entryPtr = VcEntry(vcPtr, id, kind);
    if (entryPtr->where == NULL) {
	entryPtr->where = where;
    } else if (where != NULL) {
	Tcl_DecrRefCount(where);
    }
}

void
TkTextVcNotify(textPtr)
    TkText *textPtr;
{
    TkTextVcState *vcPtr = TkTextVcOn(textPtr) ? textPtr->vcPtr : NULL;
    int i, num;

    if (vcPtr == NULL) {
	return;
    }
    num = vcPtr->numPending;
    vcPtr->numPending = 0;
    for (i = 0; i < num; i++) {
	TkTextVcPending *pPtr = &vcPtr->pending[i];
	TkTextVcEntry *entryPtr = pPtr->entryPtr;

	entryPtr->pending = 0;
	if (pPtr->where != NULL) {
	    VcCall(textPtr, pPtr->event, entryPtr->kind, pPtr->where,
		    entryPtr->id);
	    Tcl_DecrRefCount(pPtr->where);
	} else {
	    VcCall(textPtr, entryPtr->predicted, entryPtr->kind,
		    entryPtr->where, entryPtr->id);
	}
    }
}

/*
 * TkTextVcTell: tell the callback at once, outside the table of what
 * is foreseen and checked at the end: a change of a value's place that
 * detaches nothing (the WRAP and PULL OUT of ragged trees change the
 * levels in the addresses of the nodes above, "move"), and the copies
 * of "block sprout" ("copy").  where is consumed.
 */

void
TkTextVcTell(textPtr, event, kind, where, value)
    TkText *textPtr;
    int event, kind;
    Tcl_Obj *where;
    Arg value;
{
    if (TkTextVcOn(textPtr) && (value != NULL)) {
	VcCall(textPtr, event, kind, where, value);
    }
    if (where != NULL) {
	Tcl_DecrRefCount(where);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextVcNew, TkTextVcNewOn, TkTextVcCharPlace, TkTextVcIndexPlace --
 *
 *	(Provisional, decision O5.)  The event "new": a node or a leaf
 *	that a change creates without a value (block split, a newline in
 *	a block, block insert, block sprout, a WRAP, the leaves a
 *	dissolved block leaves in the enclosing one, a root that becomes
 *	real), told before the change, at once (outside the table of
 *	detaches), with the place the node will have after the change
 *	and the value undef.  The look-ahead (TkBTreeVcNew... in
 *	tkTextBTree.c) computes those places while the text is as it
 *	was: TkTextVcCharPlace and TkTextVcIndexPlace give [index,
 *	level] for a position now (a line and a byte offset in the
 *	outermost tree, or an index) moved by a number of characters on
 *	its line (a change inside a block keeps everything on one line).
 *	What an undo or a redo re-creates is not told (TkTextVcNewOn is
 *	0): such a node gets its value back ("restore") if it had one.
 *	where is consumed.
 *
 *----------------------------------------------------------------------
 */

int
TkTextVcNewOn(textPtr)
    TkText *textPtr;
{
    return TkTextVcOn(textPtr) && !textPtr->vcPtr->noNew;
}

void
TkTextVcNew(textPtr, where)
    TkText *textPtr;
    Tcl_Obj *where;
{
    if (TkTextVcNewOn(textPtr)) {
	Tcl_Obj *undef = Tcl_NewObj();

	VcCall(textPtr, TK_TEXT_VC_NEW, TK_TEXT_VC_NODE, where, undef);
	Tcl_DecrRefCount(undef);
    }
    if (where != NULL) {
	Tcl_DecrRefCount(where);
    }
}

static Tcl_Obj *
VcShifted(position, chars, level)
    Tcl_Obj *position;			/* "line.char", consumed. */
    int chars, level;
{
    Tcl_Obj *listPtr = Tcl_NewListObj(0, NULL);
    int line, ch;

    if ((chars != 0)
	    && (sscanf(Tcl_GetString(position), "%d.%d", &line, &ch) == 2)) {
	char buffer[2 * TCL_INTEGER_SPACE + 2];

	sprintf(buffer, "%d.%d", line, ch + chars);
	Tcl_DecrRefCount(position);
	position = Tcl_NewStringObj(buffer, -1);
    }
    Tcl_ListObjAppendElement(NULL, listPtr, position);
    Tcl_ListObjAppendElement(NULL, listPtr, Tcl_NewIntObj(level));
    return listPtr;
}

Tcl_Obj *
TkTextVcCharPlace(textPtr, line, byteIndex, chars, level)
    TkText *textPtr;
    int line, byteIndex;		/* A position now. */
    int chars, level;
{
    return VcShifted(VcPosition(textPtr, line, byteIndex), chars, level);
}

Tcl_Obj *
TkTextVcIndexPlace(textPtr, indexPtr, chars, level)
    TkText *textPtr;
    TkTextIndex *indexPtr;		/* A position now. */
    int chars, level;
{
    return VcShifted(VcIndex(indexPtr), chars, level);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextVcSeen, TkTextVcRestored, TkTextVcDiscarded --
 *
 *	What a change does to a value: detaches it (TK_TEXT_VC_DROP: to
 *	the list of values to free, _STASH: into an undo record, _MOVE:
 *	to another owner by a merge), gives it back from an undo step
 *	(the callback is called at once, with its place now), or frees it
 *	with a discarded undo step (told at the end of the command).
 *
 * Side effects:
 *	where is consumed.
 *
 *----------------------------------------------------------------------
 */

void
TkTextVcSeen(textPtr, value, event)
    TkText *textPtr;
    TkTextData value;
    int event;
{
    Arg id;

    if (!TkTextVcOn(textPtr) || ((id = TkTextDataGetLang(value)) == NULL)) {
	return;
    }
    VcEntry(textPtr->vcPtr, id, 0)->actual = event;
}

void
TkTextVcRestored(textPtr, value, kind, where)
    TkText *textPtr;
    TkTextData value;
    int kind;
    Tcl_Obj *where;
{
    Arg id;

    if (!TkTextVcOn(textPtr) || ((id = TkTextDataGetLang(value)) == NULL)) {
	if (where != NULL) {
	    Tcl_DecrRefCount(where);
	}
	return;
    }
    VcEntry(textPtr->vcPtr, id, kind)->actual = TK_TEXT_VC_RESTORE;
    VcCall(textPtr, TK_TEXT_VC_RESTORE, kind, where, id);
    if (where != NULL) {
	Tcl_DecrRefCount(where);
    }
}

static void
VcPostLater(vcPtr, event, kind, where, value)
    TkTextVcState *vcPtr;
    int event, kind;
    Tcl_Obj *where;			/* Consumed. */
    Arg value;
{
    TkTextVcPost *postPtr = (TkTextVcPost *) ckalloc(sizeof(TkTextVcPost));

    postPtr->event = event;
    postPtr->kind = kind;
    postPtr->where = where;
    postPtr->value = value;
    Tcl_IncrRefCount(value);
    postPtr->nextPtr = NULL;
    if (vcPtr->lastPost == NULL) {
	vcPtr->post = postPtr;
    } else {
	vcPtr->lastPost->nextPtr = postPtr;
    }
    vcPtr->lastPost = postPtr;
}

void
TkTextVcDiscarded(textPtr, value, kind, where)
    TkText *textPtr;
    TkTextData value;
    int kind;
    Tcl_Obj *where;
{
    Arg id;

    if (!TkTextVcOn(textPtr) || ((id = TkTextDataGetLang(value)) == NULL)) {
	if (where != NULL) {
	    Tcl_DecrRefCount(where);
	}
	return;
    }
    VcEntry(textPtr->vcPtr, id, kind)->actual = TK_TEXT_VC_DISCARD;
    VcPostLater(textPtr->vcPtr, TK_TEXT_VC_DISCARD, kind, where, id);
}

/*
 *----------------------------------------------------------------------
 *
 * VcFinish --
 *
 *	The end of a widget command run with a -valuecommand: check what
 *	happened against what the callback was told, report the detaches
 *	not foreseen ("late"), tell the discards and the late ones, and
 *	forget the command's table.
 *
 * Results:
 *	TCL_OK; under "debug", TCL_ERROR (with a message in the
 *	interpreter) if a detach was not foreseen or one foreseen did
 *	not happen as told.
 *
 *----------------------------------------------------------------------
 */

static int
VcFinish(textPtr)
    TkText *textPtr;
{
    TkTextVcState *vcPtr = textPtr->vcPtr;
    TkTextVcEntry *entryPtr, *nextPtr;
    TkTextVcPost *postPtr, *nextPostPtr;
    Tcl_DString message;
    int wrong = 0;

    Tcl_DStringInit(&message);
    for (entryPtr = vcPtr->first; entryPtr != NULL;
	 entryPtr = entryPtr->nextPtr) {
	int actual = entryPtr->actual, predicted = entryPtr->predicted;
	char *problem = NULL;

	if ((actual == TK_TEXT_VC_DROP) || (actual == TK_TEXT_VC_STASH)
		|| (actual == TK_TEXT_VC_MOVE)) {
	    if (predicted == 0) {
		problem = "not foreseen";
		VcPostLater(vcPtr, TK_TEXT_VC_LATE, entryPtr->kind,
			entryPtr->where, entryPtr->id);
		entryPtr->where = NULL;
	    } else if ((predicted != actual)
		    && !(entryPtr->predictedMask & (1 << actual))) {
		problem = "foreseen as another event";
	    }
	} else if ((predicted != 0) && (actual == 0)) {
	    problem = "foreseen, did not happen";
	}
	if ((problem != NULL) && (wrong++ == 0)) {
	    Tcl_DStringAppend(&message, "-valuecommand: ", -1);
	    Tcl_DStringAppend(&message, vcKinds[entryPtr->kind], -1);
	    Tcl_DStringAppend(&message, " value ", -1);
	    Tcl_DStringAppend(&message, vcEvents[actual ? actual : predicted],
		    -1);
	    Tcl_DStringAppend(&message, " ", -1);
	    Tcl_DStringAppend(&message, problem, -1);
	    if (predicted != 0) {
		Tcl_DStringAppend(&message, " (told ", -1);
		Tcl_DStringAppend(&message, vcEvents[predicted], -1);
		Tcl_DStringAppend(&message, ")", -1);
	    }
	    Tcl_DStringAppend(&message, " in ", -1);
	    Tcl_DStringAppend(&message, vcPtr->cause, -1);
	}
    }
    for (postPtr = vcPtr->post; postPtr != NULL; postPtr = postPtr->nextPtr) {
	VcCall(textPtr, postPtr->event, postPtr->kind, postPtr->where,
		postPtr->value);
    }
    for (postPtr = vcPtr->post; postPtr != NULL; postPtr = nextPostPtr) {
	nextPostPtr = postPtr->nextPtr;
	if (postPtr->where != NULL) {
	    Tcl_DecrRefCount(postPtr->where);
	}
	Tcl_DecrRefCount(postPtr->value);
	ckfree((char *) postPtr);
    }
    for (entryPtr = vcPtr->first; entryPtr != NULL; entryPtr = nextPtr) {
	nextPtr = entryPtr->nextPtr;
	if (entryPtr->where != NULL) {
	    Tcl_DecrRefCount(entryPtr->where);
	}
	ckfree((char *) entryPtr);
    }
    Tcl_DeleteHashTable(&vcPtr->table);
    if (vcPtr->pending != NULL) {
	int i;

	for (i = 0; i < vcPtr->numPending; i++) {
	    if (vcPtr->pending[i].where != NULL) {
		Tcl_DecrRefCount(vcPtr->pending[i].where);
	    }
	}
	ckfree((char *) vcPtr->pending);
    }
    ckfree(vcPtr->cause);
    ckfree((char *) vcPtr);
    textPtr->vcPtr = NULL;
    if (wrong && tkBTreeDebug) {
	Tcl_ResetResult(textPtr->interp);
	Tcl_AppendResult(textPtr->interp, Tcl_DStringValue(&message), NULL);
	Tcl_DStringFree(&message);
	return TCL_ERROR;
    }
    Tcl_DStringFree(&message);
    return TCL_OK;
}

#if TK_TEXT_DATA_ARRAYS
/*
 *--------------------------------------------------------------
 *
 * DataSlotCmd --
 *
 *	A hook for the tests of representation B (t/data-slots.t), not
 *	an interface: it exists only in a widget built with
 *	TK_TEXT_DATA_ARRAYS, and is not documented in the manual.  It
 *	reads and sets the TK_TEXT_DATA_INT slot of the data of a node,
 *	a mark, a run or a block, which the Perl interface cannot reach:
 *
 *	    .t _dataslot node index level ?int?
 *	    .t _dataslot mark markName ?int?
 *	    .t _dataslot run tagName index ?int?
 *	    .t _dataslot block index ?int?
 *	    .t _dataslot live
 *
 *	Without an int: the slot's value, or nothing (undef) if there
 *	is none.  An int sets the slot; undef or an empty string
 *	removes it (the container goes with its last slot).  Setting a
 *	slot counts as setting a value (haveValues, hasRunValues), as
 *	it must for the changes to look after it.  "live" gives the
 *	number of data blocks allocated and not yet freed, in the whole
 *	process.
 *
 * Results:
 *	A standard Tcl result.
 *
 *--------------------------------------------------------------
 */

static int
DataSlotCmd(textPtr, interp, argc, args)
    TkText *textPtr;		/* The widget. */
    Tcl_Interp *interp;		/* For the result. */
    int argc;			/* Number of arguments. */
    Arg *args;			/* Argument strings. */
{
    TkTextData *dataPtr = NULL;
    TkTextTag *tagPtr = NULL;
    TkTextIndex index;
    TkTextDataSlot slot;
    Tcl_HashEntry *hPtr;
    char *what = (argc > 2) ? LangString(args[2]) : "";
    int nargs;			/* Arguments that name the place. */
    char buffer[TCL_INTEGER_SPACE * 2];

    if (strcmp(what, "live") == 0) {
	sprintf(buffer, "%ld", eText_TkTextDataLive);
	Tcl_SetResult(interp, buffer, TCL_VOLATILE);
	return TCL_OK;
    }
    if (strcmp(what, "node") == 0) {
	nargs = 2;
    } else if (strcmp(what, "mark") == 0) {
	nargs = 1;
    } else if (strcmp(what, "run") == 0) {
	nargs = 2;
    } else if (strcmp(what, "block") == 0) {
	nargs = 1;
    } else {
	Tcl_AppendResult(interp, "bad _dataslot kind \"", what,
		"\": must be node, mark, run, block or live", NULL);
	return TCL_ERROR;
    }
    if ((argc != 3 + nargs) && (argc != 4 + nargs)) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		LangString(args[0]), " _dataslot ", what, " place... ?int?\"",
		NULL);
	return TCL_ERROR;
    }
    if (what[0] == 'n') {
	if ((TkTextGetIndex(interp, textPtr, LangString(args[3]), &index)
		!= TCL_OK)
		|| (TkBTreeNodeValue(textPtr, &index, LangString(args[3]),
			args[4], &dataPtr) != TCL_OK)) {
	    return TCL_ERROR;
	}
    } else if (what[0] == 'm') {
	hPtr = TkTextIsPrivateMarkName(LangString(args[3])) ? NULL
		: Tcl_FindHashEntry(&textPtr->markTable, LangString(args[3]));
	if (hPtr == NULL) {
	    Tcl_AppendResult(interp, "there is no mark named \"",
		    LangString(args[3]), "\"", NULL);
	    return TCL_ERROR;
	}
	dataPtr = &((TkTextSegment *) Tcl_GetHashValue(hPtr))
		->body.mark.value;
    } else if (what[0] == 'r') {
	hPtr = Tcl_FindHashEntry(&textPtr->tagTable, LangString(args[3]));
	if (hPtr == NULL) {
	    Tcl_AppendResult(interp, "tag \"", LangString(args[3]),
		    "\" isn't defined in text widget", NULL);
	    return TCL_ERROR;
	}
	tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);
	if ((TkTextGetIndex(interp, textPtr, LangString(args[4]), &index)
		!= TCL_OK)
		|| (TkBTreeRunValue(textPtr, tagPtr, &index,
			LangString(args[4]), &dataPtr) != TCL_OK)) {
	    return TCL_ERROR;
	}
    } else {
	TkTextSegment *segPtr, *startPtr;

	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index)
		!= TCL_OK) {
	    return TCL_ERROR;
	}
	segPtr = TkIBTreeAt(&index, 1);	/* As "block data" finds it. */
	startPtr = TkIBTreeAt(&index, 0);
	if ((startPtr != NULL)
		&& ((segPtr == NULL) || (startPtr->body.itree.tree == NULL))) {
	    segPtr = startPtr;
	}
	if (segPtr == NULL) {
	    Tcl_AppendResult(interp, "not inside a block", NULL);
	    return TCL_ERROR;
	}
	dataPtr = &segPtr->body.itree.data;
    }
    if (argc == 3 + nargs) {
	if (TkTextDataGet(*dataPtr, TK_TEXT_DATA_INT, &slot)) {
	    sprintf(buffer, "%ld", slot.i);
	    Tcl_SetResult(interp, buffer, TCL_VOLATILE);
	}
	return TCL_OK;
    }
    if (LangNull(args[3 + nargs])) {
	TkTextDataRemove(dataPtr, TK_TEXT_DATA_INT);
	return TCL_OK;
    }
    if (Tcl_GetLongFromObj(interp, args[3 + nargs], &slot.i) != TCL_OK) {
	return TCL_ERROR;
    }
    TkTextDataSet(dataPtr, TK_TEXT_DATA_INT, slot);
    textPtr->haveValues = 1;
    if (tagPtr != NULL) {
	tagPtr->hasRunValues = 1;
    }
    return TCL_OK;
}
#endif /* TK_TEXT_DATA_ARRAYS */

/*
 *--------------------------------------------------------------
 *
 * FlushValues --
 *
 *	Free the values (see TkTextValue) the widget command just
 *	finished has dropped, in the order they were dropped.  A DESTROY
 *	method may change the widget meanwhile (see TextWidgetCmd): the
 *	values that change drops join the list, and are freed in the
 *	next round of the same loop.  freeingValues is the round: the
 *	values the command dropped are freed in round 1, those dropped
 *	by a change made from their DESTROY methods in round 2, and so
 *	on; changes are refused in round freeLimit, which ends chains
 *	of DESTROY methods that change the widget forever.  The limit
 *	starts at TK_TEXT_FREE_DEPTH; when a change is about to be made
 *	at the limit, the object whose DESTROY method makes it may raise
 *	it (MoreFreeRounds).  The limit and the count of such requests
 *	belong to this pass and are reset with it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Perl code may run; the interpreter's result is preserved.
 *
 *--------------------------------------------------------------
 */

static void
FlushValues(textPtr)
    TkText *textPtr;		/* Information about text widget. */
{
    Tcl_Interp *interp = textPtr->interp;
    Tcl_Obj *resultPtr = Tcl_GetObjResult(interp);
    TkTextValue *listPtr;

    resultPtr = (resultPtr != NULL) ? newSVsv(resultPtr) : NULL;
    textPtr->freeingValues = 0;
    textPtr->freeLimit = TK_TEXT_FREE_DEPTH;
    textPtr->freeAsks = 0;
    while (textPtr->freeValues != NULL) {
	listPtr = textPtr->freeValues;
	textPtr->freeValues = textPtr->lastFreeValue = NULL;
	textPtr->freeingValues++;
	TkTextReleaseValues(listPtr);
    }
    textPtr->freeingValues = 0;
    textPtr->freeLimit = TK_TEXT_FREE_DEPTH;
    textPtr->freeAsks = 0;
    if (resultPtr != NULL) {
	Tcl_SetObjResult(interp, resultPtr);
    }
}

/*
 *--------------------------------------------------------------
 *
 * MoreFreeRounds --
 *
 *	A DESTROY method run by FlushValues is about to change the
 *	widget in round freeLimit.  Ask the object whose DESTROY method
 *	is the innermost one running (the value being freed, or an
 *	object nested in it whose DESTROY runs meanwhile) for more
 *	rounds: $object->DESTROYmult($n, $limit), $n counting the
 *	requests of this freeing pass from 1, $limit the current limit
 *	(see LangDestroyMult in pperlGlue.c).  A positive integer
 *	$more raises the limit by $more; anything else, no such object
 *	or method, or a method that dies (a background error, as for
 *	-valuecommand) leaves it, and the change is refused.  While
 *	DESTROYmult runs, a change it attempts is refused without asking
 *	again.
 *
 * Results:
 *	Non-zero if the limit was raised (the change may be made).
 *
 * Side effects:
 *	Perl code may run.  The interpreter's result is reset.
 *
 *--------------------------------------------------------------
 */

static int
MoreFreeRounds(textPtr)
    TkText *textPtr;		/* Information about text widget. */
{
    Tcl_Interp *interp = textPtr->interp;
    int more = 0;

    if (textPtr->freeAsking) {
	return 0;
    }
    textPtr->freeAsking = 1;
    textPtr->freeAsks++;
    if (LangDestroyMult(interp, textPtr->freeAsks, textPtr->freeLimit,
	    &more) != TCL_OK) {
	Tcl_AddErrorInfo(interp,
		"\n    (DESTROYmult of a value freed by a text widget)");
	Tcl_BackgroundError(interp);
	more = 0;
    }
    textPtr->freeAsking = 0;
    Tcl_ResetResult(interp);
    if ((more <= 0) || (textPtr->tkwin == NULL)) {	/* Destroyed. */
	return 0;
    }
    textPtr->freeLimit += more;
    return 1;
}

/*
 *----------------------------------------------------------------------
 *
 * DestroyText --
 *
 *	This procedure is invoked by Tcl_EventuallyFree or Tcl_Release
 *	to clean up the internal structure of a text at a safe time
 *	(when no-one is using it anymore).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Everything associated with the text is freed up.
 *
 *----------------------------------------------------------------------
 */

static void
DestroyText(memPtr)
    char *memPtr;		/* Info about text widget. */
{
    register TkText *textPtr = (TkText *) memPtr;
    Tcl_HashSearch search;
    Tcl_HashEntry *hPtr;
    TkTextTag *tagPtr;
    TkTextValue *valuesPtr;

    /*
     * Free up all the stuff that requires special handling, then
     * let Tk_FreeOptions handle all the standard option-related
     * stuff.  Special note:  free up display-related information
     * before deleting the B-tree, since display-related stuff
     * may refer to stuff in the B-tree.
     *
     * In fact we have chicken and egg problem: blocks can refer to
     * DLines, and tree can refer to blocks. We delete blocks first,
     * and it looks like the block information is not used during
     * deletion of IBTree.
     */

    if (textPtr->dlinePtrs) {
      int i;

      for (i = 0; i < textPtr->numDLines; i++) {
	TkTextFreeDLine(textPtr, textPtr->dlinePtrs[i]);
      }
      ckfree((char*)textPtr->dlinePtrs);
    }
    TkTextOrnFreeAll(textPtr);
    TkTextFreeDInfo(textPtr);
    TkBTreeDestroy(textPtr->tree);
    for (hPtr = Tcl_FirstHashEntry(&textPtr->blockTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	DeleteBlock(textPtr, (TkTextBlock *) Tcl_GetHashValue(hPtr));
    }
    Tcl_DeleteHashTable(&textPtr->blockTable);
    Tcl_DeleteHashTable(&textPtr->imageTable);
    for (hPtr = Tcl_FirstHashEntry(&textPtr->tagTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);
	TkTextFreeTag(textPtr, tagPtr);
    }
    Tcl_DeleteHashTable(&textPtr->tagTable);
    for (hPtr = Tcl_FirstHashEntry(&textPtr->markTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	TkTextSegment *markPtr = (TkTextSegment *) Tcl_GetHashValue(hPtr);

	TkTextFreeValueLater(textPtr, markPtr->body.mark.value);
	ckfree((char *) markPtr);
    }
    Tcl_DeleteHashTable(&textPtr->markTable);
    if (textPtr->tabArrayPtr != NULL) {
	ckfree((char *) textPtr->tabArrayPtr);
    }
    if (textPtr->insertBlinkHandler != NULL) {
	Tcl_DeleteTimerHandler(textPtr->insertBlinkHandler);
    }
    if (textPtr->bindingTable != NULL) {
	Tk_DeleteBindingTable(textPtr->bindingTable);
    }

    /*
     * NOTE: do NOT free up selBorder, selBdString, or selFgColorPtr:
     * they are duplicates of information in the "sel" tag, which was
     * freed up as part of deleting the tags above.
     */

    textPtr->selBorder = NULL;
    textPtr->selBdString = NULL;
    TkTextUndoFreeStack(textPtr->undoStack);
    TkTextRootLogReset(textPtr);
    textPtr->selFgColorPtr = NULL;
    Tk_FreeOptions(configSpecs, (char *) textPtr, textPtr->display, 0);

    /*
     * The values of the nodes and of the undo atoms are freed once the
     * widget is gone.
     */

    valuesPtr = textPtr->freeValues;
    ckfree((char *) textPtr);
    TkTextReleaseValues(valuesPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * ConfigureText --
 *
 *	This procedure is called to process an args/argc list, plus
 *	the Tk option database, in order to configure (or
 *	reconfigure) a text widget.
 *
 * Results:
 *	The return value is a standard Tcl result.  If TCL_ERROR is
 *	returned, then Tcl_GetResult(interp) contains an error message.
 *
 * Side effects:
 *	Configuration information, such as text string, colors, font,
 *	etc. get set for textPtr;  old resources get freed, if there
 *	were any.
 *
 *----------------------------------------------------------------------
 */

static int
ConfigureText(interp, textPtr, argc, args, flags)
    Tcl_Interp *interp;		/* Used for error reporting. */
    register TkText *textPtr;	/* Information about widget;  may or may
				 * not already have values for some fields. */
    int argc;			/* Number of valid entries in args. */
    Arg *args;		/* Arguments. */
    int flags;			/* Flags to pass to Tk_ConfigureWidget. */
{
    Tk_FontMetrics fm;
    int oldExport = textPtr->exportSelection;
    int charHeight;

    if (Tk_ConfigureWidget(interp, textPtr->tkwin, configSpecs,
	    argc, args, (char *) textPtr, flags) != TCL_OK) {
	return TCL_ERROR;
    }

    /*
     * A few other options also need special processing, such as parsing
     * the geometry and setting the background from a 3-D border.
     */

    if ((textPtr->state != tkTextNormalUid)
	    && (textPtr->state != tkTextDisabledUid)) {
	Tcl_AppendResult(interp, "bad state value \"", textPtr->state,
		"\": must be normal or disabled",          NULL);
	textPtr->state = tkTextNormalUid;
	return TCL_ERROR;
    }

    if ((textPtr->wrapMode != tkTextCharUid)
	    && (textPtr->wrapMode != tkTextNoneUid)
	    && (textPtr->wrapMode != tkTextWordUid)) {
	Tcl_AppendResult(interp, "bad wrap mode \"", textPtr->wrapMode,
		"\": must be char, none, or word",          NULL);
	textPtr->wrapMode = tkTextCharUid;
	return TCL_ERROR;
    }

    Tk_SetBackgroundFromBorder(textPtr->tkwin, textPtr->border);
    TkTextUndoSetDepth(textPtr->undoStack, textPtr->maxUndo);

    /*
     * Don't allow negative spacings.
     */

    if (textPtr->spacing1 < 0) {
	textPtr->spacing1 = 0;
    }
    if (textPtr->spacing2 < 0) {
	textPtr->spacing2 = 0;
    }
    if (textPtr->spacing3 < 0) {
	textPtr->spacing3 = 0;
    }

    /*
     * Parse tab stops.
     */

    if (textPtr->tabArrayPtr != NULL) {
	ckfree((char *) textPtr->tabArrayPtr);
	textPtr->tabArrayPtr = NULL;
    }
    if (textPtr->tabOptionString != NULL) {
	textPtr->tabArrayPtr = TkTextGetTabs(interp, textPtr->tkwin,
		textPtr->tabOptionString);
	if (textPtr->tabArrayPtr == NULL) {
	    Tcl_AddErrorInfo(interp,"\n    (while processing -tabs option)");
	    return TCL_ERROR;
	}
    }

    /*
     * Make sure that configuration options are properly mirrored
     * between the widget record and the "sel" tags.  NOTE: we don't
     * have to free up information during the mirroring;  old
     * information was freed when it was replaced in the widget
     * record.
     */

    textPtr->selTagPtr->border = textPtr->selBorder;
    if (textPtr->selTagPtr->bdString != textPtr->selBdString) {
	textPtr->selTagPtr->bdString = textPtr->selBdString;
	if (textPtr->selBdString != NULL) {
	    if (Tk_GetPixels(interp, textPtr->tkwin, textPtr->selBdString,
		    &textPtr->selTagPtr->borderWidth) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (textPtr->selTagPtr->borderWidth < 0) {
		textPtr->selTagPtr->borderWidth = 0;
	    }
	}
    }
    textPtr->selTagPtr->fgColor = textPtr->selFgColorPtr;
    textPtr->selTagPtr->affectsDisplay = 0;
    if ((textPtr->selTagPtr->border != NULL)
	    || (textPtr->selTagPtr->bdString != NULL)
	    || (textPtr->selTagPtr->reliefString != NULL)
	    || (textPtr->selTagPtr->bgStipple != None)
	    || (textPtr->selTagPtr->fgColor != NULL)
	    || (textPtr->selTagPtr->tkfont != NULL)
	    || (textPtr->selTagPtr->fgStipple != None)
	    || (textPtr->selTagPtr->justifyString != NULL)
	    || (textPtr->selTagPtr->lMargin1String != NULL)
	    || (textPtr->selTagPtr->lMargin2String != NULL)
	    || (textPtr->selTagPtr->offsetString != NULL)
	    || (textPtr->selTagPtr->overstrikeString != NULL)
	    || (textPtr->selTagPtr->rMarginString != NULL)
	    || (textPtr->selTagPtr->spacing1String != NULL)
	    || (textPtr->selTagPtr->spacing2String != NULL)
	    || (textPtr->selTagPtr->spacing3String != NULL)
	    || (textPtr->selTagPtr->tabString != NULL)
	    || (textPtr->selTagPtr->underlineString != NULL)
	    || (textPtr->selTagPtr->wrapMode != NULL)) {
	textPtr->selTagPtr->affectsDisplay = 1;
    }
    TkTextRedrawTag(textPtr, (TkTextIndex *) NULL, (TkTextIndex *) NULL,
	    textPtr->selTagPtr, 1);

    /*
     * Claim the selection if we've suddenly started exporting it and there
     * are tagged characters.
     */

    if (textPtr->exportSelection && (!oldExport)) {
	TkTextSearch search;
	TkTextIndex first, last;

	TkTextMakeByteIndex(textPtr->tree, 0, 0, &first);
	TkTextMakeByteIndex(textPtr->tree,
		TkBTreeNumLines(textPtr->tree), 0, &last);
	TkBTreeStartSearch(&first, &last, textPtr->selTagPtr, &search);
	if (TkBTreeCharTagged(&first, textPtr->selTagPtr)
		|| TkBTreeNextTag(&search)) {
	    Tk_OwnSelection(textPtr->tkwin, XA_PRIMARY, TkTextLostSelection,
		    (ClientData) textPtr);
	    textPtr->flags |= GOT_SELECTION;
	}
    }

    /*
     * Register the desired geometry for the window, and arrange for
     * the window to be redisplayed.
     */

    if (textPtr->width <= 0) {
	textPtr->width = 1;
    }
    if (textPtr->height <= 0) {
	textPtr->height = 1;
    }
    textPtr->charWidth = Tk_TextWidth(textPtr->tkfont, "0", 1);
    if (textPtr->charWidth <= 0) {
	textPtr->charWidth = 1;
    }
    Tk_GetFontMetrics(textPtr->tkfont, &fm);
    charHeight = fm.linespace;
    Tk_GeometryRequest(textPtr->tkwin,
	    textPtr->width * textPtr->charWidth + 2*textPtr->borderWidth
		    + 2*textPtr->padX + 2*textPtr->highlightWidth,
	    textPtr->height * charHeight + 2*textPtr->borderWidth
		    + 2*textPtr->padY + 2*textPtr->highlightWidth);
    Tk_SetInternalBorder(textPtr->tkwin,
	    textPtr->borderWidth + textPtr->highlightWidth);
    if (textPtr->setGrid) {
	Tk_SetGrid(textPtr->tkwin, textPtr->width, textPtr->height,
		textPtr->charWidth, charHeight);
    } else {
	Tk_UnsetGrid(textPtr->tkwin);
    }

    TkTextRelayoutWindow(textPtr);
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * TextEventProc --
 *
 *	This procedure is invoked by the Tk dispatcher on
 *	structure changes to a text.  For texts with 3D
 *	borders, this procedure is also invoked for exposures.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	When the window gets deleted, internal structures get
 *	cleaned up.  When it gets exposed, it is redisplayed.
 *
 *--------------------------------------------------------------
 */

static void
TextEventProc(clientData, eventPtr)
    ClientData clientData;	/* Information about window. */
    register XEvent *eventPtr;	/* Information about event. */
{
    register TkText *textPtr = (TkText *) clientData;
    TkTextIndex index, index2;

    if (eventPtr->type == Expose) {
	TkTextRedrawRegion(textPtr, eventPtr->xexpose.x,
		eventPtr->xexpose.y, eventPtr->xexpose.width,
		eventPtr->xexpose.height);
    } else if (eventPtr->type == ConfigureNotify) {
	if ((textPtr->prevWidth != Tk_Width(textPtr->tkwin))
		|| (textPtr->prevHeight != Tk_Height(textPtr->tkwin))) {
	    TkTextRelayoutWindow(textPtr);
	    textPtr->prevWidth = Tk_Width(textPtr->tkwin);
	    textPtr->prevHeight = Tk_Height(textPtr->tkwin);
	}
    } else if (eventPtr->type == DestroyNotify) {
	if (textPtr->setGrid) {
	    Tk_UnsetGrid(textPtr->tkwin);
	}
	if (textPtr->tkwin != NULL) {
	    textPtr->tkwin = NULL;
	    Lang_DeleteWidget(textPtr->interp,textPtr->widgetCmd);


	}
	Tcl_EventuallyFree((ClientData) textPtr, DestroyText);
    } else if ((eventPtr->type == FocusIn) || (eventPtr->type == FocusOut)) {
	if (eventPtr->xfocus.detail != NotifyInferior) {
	    Tcl_DeleteTimerHandler(textPtr->insertBlinkHandler);
	    if (eventPtr->type == FocusIn) {
		textPtr->flags |= GOT_FOCUS | INSERT_ON;
		if (textPtr->insertOffTime != 0) {
		    textPtr->insertBlinkHandler = Tcl_CreateTimerHandler(
			    textPtr->insertOnTime, TextBlinkProc,
			    (ClientData) textPtr);
		}
	    } else {
		textPtr->flags &= ~(GOT_FOCUS | INSERT_ON);
		textPtr->insertBlinkHandler = (Tcl_TimerToken) NULL;
	    }
	    TkTextMarkSegToIndex(textPtr, textPtr->insertMarkPtr, &index);
	    TkTextIndexForwChars(&index, 1, &index2);
	    TkTextChanged(textPtr, &index, &index2);
	    if (textPtr->highlightWidth > 0) {
		TkTextRedrawRegion(textPtr, 0, 0, textPtr->highlightWidth,
			textPtr->highlightWidth);
	    }
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TextCmdDeletedProc --
 *
 *	This procedure is invoked when a widget command is deleted.  If
 *	the widget isn't already in the process of being destroyed,
 *	this command destroys it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The widget is destroyed.
 *
 *----------------------------------------------------------------------
 */

static void
TextCmdDeletedProc(clientData)
    ClientData clientData;	/* Pointer to widget record for widget. */
{
    TkText *textPtr = (TkText *) clientData;
    Tk_Window tkwin = textPtr->tkwin;

    /*
     * This procedure could be invoked either because the window was
     * destroyed and the command was then deleted (in which case tkwin
     * is NULL) or because the command was deleted, and then this procedure
     * destroys the widget.
     */

    if (tkwin != NULL) {
	textPtr->tkwin = NULL;
	Tk_DestroyWindow(tkwin);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * InsertChars --
 *
 *	This procedure implements most of the functionality of the
 *	"insert" widget command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The characters in "string" get added to the text just before
 *	the character indicated by "indexPtr".
 *
 *----------------------------------------------------------------------
 */

static void
InsertChars(textPtr, indexPtr, string)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *indexPtr;	/* Where to insert new characters.  May be
				 * modified and/or invalidated. */
    char *string;		/* Null-terminated string containing new
				 * information to add to text. */
{
    int lineIndex, resetView, offset;
    TkTextIndex newTop;

    /*
     * Don't allow insertions on the last (dummy) line of the text.
     */

    lineIndex = TkBTreeLineIndex(indexPtr->linePtr);
    if (lineIndex == TkBTreeNumLines(textPtr->tree)) {
	lineIndex--;
	TkTextMakeByteIndex(textPtr->tree, lineIndex, 1000000, indexPtr);
    }

    /*
     * Notify the display module that lines are about to change, then do
     * the insertion.  If the insertion occurs on the top line of the
     * widget (textPtr->topIndex), then we have to recompute topIndex
     * after the insertion, since the insertion could invalidate it.
     */

    resetView = offset = 0;
    if (indexPtr->linePtr == textPtr->topIndex.linePtr) {
	resetView = 1;
	offset = textPtr->topIndex.byteIndex;
	if (offset > indexPtr->byteIndex) {
	    offset += strlen(string);
	}
    }
    TkBTreeVcNewInsert(textPtr, indexPtr, string);
    TkTextChanged(textPtr, indexPtr, indexPtr);
    TkTextRootLogReset(textPtr);
    TkBTreeInsertChars(indexPtr, string);

    /*
     * Record the insertion for "edit undo", and account for it in the
     * modified flag.  A newline in a block that was a single leaf made
     * its root real: the undo makes it padding again (roots).
     */

    if (textPtr->undo) {
	TkTextIndex toIndex;
	char index1[TK_POS_CHARS], index2[TK_POS_CHARS];
	TkTextUndoAtom *atomPtr;

	if (textPtr->autoSeparators
		&& (textPtr->lastEditMode != TK_TEXT_EDIT_INSERT)) {
	    TkTextUndoInsertUndoSeparator(textPtr->undoStack);
	}
	textPtr->lastEditMode = TK_TEXT_EDIT_INSERT;
	TkTextPrintIndex(indexPtr, index1);
	TkTextIndexForwBytes(indexPtr, (int) strlen(string), &toIndex);
	TkTextPrintIndex(&toIndex, index2);
	atomPtr = TkTextUndoPushAction(textPtr->undoStack,
		TK_TEXT_UNDO_INSERT, index1, index2,
		Tcl_NewStringObj(string, -1), (Tcl_Obj *) NULL,
		(char *) NULL, 0);
	atomPtr->roots = TkTextRootLogTake(textPtr);
    }
    UpdateDirtyFlag(textPtr);
    if (resetView) {
	TkTextMakeByteIndex(textPtr->tree, lineIndex, 0, &newTop);
	TkTextIndexForwBytes(&newTop, offset, &newTop);
	TkTextSetYView(textPtr, &newTop, 0);
    }

    /*
     * Invalidate any selection retrievals in progress.
     */

    textPtr->abortSelections = 1;
}

/*
 *----------------------------------------------------------------------
 *
 * SplitChars --
 *
 *	This procedure implements the "block split" widget command: a
 *	newline (or an interleaf separator) goes in at the index, and
 *	inside a block the tree may change (TkIBTreeSplit).
 *
 * Results:
 *	What TkIBTreeSplit returns.
 *
 * Side effects:
 *	As for InsertChars: the display forgets the lines it had laid
 *	out there and, if the split is on the top line, the view is
 *	set again.  Without that, the display lines and the top index
 *	kept byte offsets into a line the newline had cut short, and the
 *	next redisplay walked off its end (a crash, typically in the
 *	"see" of an undo that followed).
 *
 *----------------------------------------------------------------------
 */

static int
SplitChars(textPtr, indexPtr, level)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *indexPtr;	/* Where to split.  May be modified and/or
				 * invalidated. */
    int level;			/* As for "block split". */
{
    int lineIndex, resetView = 0, offset = 0;
    TkTextIndex newTop;

    lineIndex = TkBTreeLineIndex(indexPtr->linePtr);
    if (indexPtr->linePtr == textPtr->topIndex.linePtr) {
	resetView = 1;
	offset = textPtr->topIndex.byteIndex;
	if (offset > indexPtr->byteIndex) {
	    offset++;
	}
    }
    TkTextChanged(textPtr, indexPtr, indexPtr);
    level = TkIBTreeSplit(indexPtr, level);
    if (resetView) {
	TkTextMakeByteIndex(textPtr->tree, lineIndex, 0, &newTop);
	TkTextIndexForwBytes(&newTop, offset, &newTop);
	TkTextSetYView(textPtr, &newTop, 0);
    }
    textPtr->abortSelections = 1;
    return level;
}

/*
 *----------------------------------------------------------------------
 *
 * Sprout --
 *
 *	The changes of "block sprout" (see TkIBTreeSproutRange), right
 *	to left: a separator at index2 if an end piece is made, one at
 *	index1 if a start piece is made (as "block split" at level 0:
 *	in a leaf with padding the new leaves get padding chains of their
 *	own, siblings of the leaf), then the WRAP of the middle piece,
 *	which starts just after index1.  With doValues, the former
 *	leaf's value goes to the new node and to the end piece (the
 *	command; its redo gets the values back from the undo atom).
 *
 * Results:
 *	The number of separators put in; *raisedPtr: whether the stored
 *	tree was made one level higher.
 *
 * Side effects:
 *	The text and the block's tree change, the display is told.
 *
 *----------------------------------------------------------------------
 */

static int
Sprout(textPtr, i1, i2, startMade, endMade, doValues, raisedPtr,
	rootWrappedPtr)
    TkText *textPtr;
    char *i1, *i2;			/* The range, as given. */
    int startMade, endMade;		/* The pieces to make. */
    int doValues;			/* See above. */
    int *raisedPtr;			/* Filled in. */
    int *rootWrappedPtr;		/* Filled in: whether the block was a
					 * single leaf, given a real root. */
{
    Tcl_Interp *interp = textPtr->interp;
    TkTextIndex index, mid, head, end;
    TkTextSegment *segPtr;

    *raisedPtr = 0;
    *rootWrappedPtr = 0;

    /*
     * A block that is a single leaf first gets a real root (the WRAP of
     * its leaf), so that the pieces are its children.
     */

    if (SproutLeafIndex(textPtr, i1, startMade, &index)
	    && TkIBTreeSingleLeaf(&index)) {
	TkIBTreeWrap(textPtr, &index);
	*rootWrappedPtr = 1;
    }
    if (endMade && (TkTextGetIndex(interp, textPtr, i2, &index) == TCL_OK)) {
	SplitChars(textPtr, &index, 0);
    }
    if (startMade && (TkTextGetIndex(interp, textPtr, i1, &index) == TCL_OK)) {
	SplitChars(textPtr, &index, 0);
    }
    if (TkTextGetIndex(interp, textPtr, i1, &index) != TCL_OK) {
	Tcl_ResetResult(interp);
	return 0;
    }
    TkTextIndexForwChars(&index, 1, &mid);
    *raisedPtr = (TkIBTreeWrap(textPtr, &mid) > 0);
    if (doValues) {
	TkIBTreeSproutValues(textPtr, &mid, startMade, endMade);
    }
    if ((segPtr = TkIBTreeAt(&mid, 1)) != NULL) {
	TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	TkTextIndexForwBytes(&head, segPtr->size, &end);
	TkTextChanged(textPtr, &head, &end);
    }
    textPtr->abortSelections = 1;
    return startMade + endMade;
}

/*
 *----------------------------------------------------------------------
 *
 * Flatten, PullOutStep --
 *
 *	The changes of "block flatten" (see TkIBTreeFlattenStep): until
 *	the node has a single leaf, the JOIN of the rightmost separator
 *	inside it whose two leaves are equally deep below their common
 *	ancestor (the deletion of the separator, as "delete" does it:
 *	recorded as a deletion, told to -valuecommand as today's join),
 *	else the PULL OUT of the deepest node inside it with a single
 *	child that is a leaf (the rightmost among equally deep ones);
 *	then the PULL OUT of the node itself (the root too: the block is
 *	then a single leaf).  Each PULL OUT makes the stored tree lower
 *	while every lowest node is padding.  With -undo, every step is
 *	an atom of one undo step, of a kind of its own for
 *	-autoseparators (TK_TEXT_EDIT_FLATTEN): the undo is the inverse
 *	steps in reverse order, the redo the steps again.
 *
 * Results:
 *	Flatten: the number of separators deleted.
 *
 * Side effects:
 *	The text and the block's tree change, the display is told.
 *
 *----------------------------------------------------------------------
 */

static int
Flatten(textPtr, nodePtr)
    TkText *textPtr;
    void *nodePtr;			/* The node (TkIBTreeFlattenTarget). */
{
    TkTextIndex pos, head, end;
    TkTextSegment *segPtr;
    char sep[TK_POS_CHARS];
    int joined = 0, kind, steps = 0;

    if (textPtr->undo && textPtr->autoSeparators
	    && (textPtr->lastEditMode != TK_TEXT_EDIT_FLATTEN)) {
	TkTextUndoInsertUndoSeparator(textPtr->undoStack);
    }
    do {
	kind = TkIBTreeFlattenStep(textPtr, nodePtr, &pos);
	if ((segPtr = TkIBTreeAt(&pos, 1)) != NULL) {
	    TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	    TkTextIndexForwBytes(&head, segPtr->size, &end);
	    TkTextChanged(textPtr, &head, &end);
	}
	if (kind == TK_IBTREE_FLATTEN_JOIN) {
	    /*
	     * The deletion is in the same undo step: it must not start
	     * one of its own (DeletionSeparator).
	     */

	    TkTextPrintIndex(&pos, sep);
	    if (textPtr->undo) {
		textPtr->lastEditMode = TK_TEXT_EDIT_DELETE;
	    }
	    if (DeleteChars(textPtr, sep, (char *) NULL) != TCL_OK) {
		Tcl_ResetResult(textPtr->interp);
		break;
	    }
	    joined++;
	} else if (kind != 0) {
	    PullOutStep(textPtr, &pos);
	}
    } while ((kind != 0) && (kind != TK_IBTREE_FLATTEN_SELF)
	    && (++steps < 100000));
    if (textPtr->undo) {
	textPtr->lastEditMode = TK_TEXT_EDIT_FLATTEN;
    }
    textPtr->abortSelections = 1;
    return joined;
}

static void
PullOutStep(textPtr, indexPtr)
    TkText *textPtr;
    TkTextIndex *indexPtr;		/* The start of the leaf. */
{
    CaptureState cs;
    TkTextUndoAtom *atomPtr = NULL;
    char i1[TK_POS_CHARS];
    int lowered;

    if (textPtr->undo) {
	TkTextPrintIndex(indexPtr, i1);
	textPtr->lastEditMode = TK_TEXT_EDIT_FLATTEN;
	atomPtr = PushEdit(textPtr, TK_TEXT_EDIT_FLATTEN, TK_TEXT_UNDO_PULLOUT,
		i1, i1, (Tcl_Obj *) NULL);
	CaptureStart(textPtr, &cs, &atomPtr->values, indexPtr, indexPtr);
    }
    lowered = TkIBTreePullOutNode(textPtr, indexPtr, 1, -1);
    if (atomPtr != NULL) {
	CaptureEnd(textPtr, &cs);
	atomPtr->added = (lowered > 0) ? lowered : 0;
    }
}

/*
 * A position inside the leaf "block sprout" works on, before it does:
 * index1, or the start of the leaf if index1 is the delimiter before it
 * (no start piece).
 */

static int
SproutLeafIndex(textPtr, i1, startMade, indexPtr)
    TkText *textPtr;
    char *i1;				/* index1 as given. */
    int startMade;			/* Whether a start piece is made. */
    TkTextIndex *indexPtr;		/* Filled in. */
{
    if (TkTextGetIndex(textPtr->interp, textPtr, i1, indexPtr) != TCL_OK) {
	Tcl_ResetResult(textPtr->interp);
	return 0;
    }
    if (!startMade) {
	TkTextIndexForwChars(indexPtr, 1, indexPtr);
    }
    return 1;
}

/*
 * A deletion is an edit of its own kind (-autoseparators): the separator
 * goes before everything it records.
 */

static void
DeletionSeparator(textPtr)
    TkText *textPtr;
{
    if (textPtr->undo) {
	if (textPtr->autoSeparators
		&& (textPtr->lastEditMode != TK_TEXT_EDIT_DELETE)) {
	    TkTextUndoInsertUndoSeparator(textPtr->undoStack);
	}
	textPtr->lastEditMode = TK_TEXT_EDIT_DELETE;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DeleteChars --
 *
 *	This procedure implements most of the functionality of the
 *	"delete" widget command.
 *
 * Results:
 *	Returns a standard Tcl result, and leaves an error message
 *	in textPtr->interp if there is an error.
 *
 * Side effects:
 *	Characters get deleted from the text.
 *
 *----------------------------------------------------------------------
 */

static int
DeleteChars(textPtr, index1String, index2String)
    TkText *textPtr;		/* Overall information about text widget. */
    char *index1String;		/* String describing location of first
				 * character to delete. */
    char *index2String;		/* String describing location of last
				 * character to delete.  NULL means just
				 * delete the one character given by
				 * index1String. */
{
    int line1, line2, line, byteIndex, resetView, *wraps;
    TkTextIndex index1, index2;
    TkTextUndoAtom *recordPtr = NULL;	/* The atom recorded, if any. */
    TkTextValue **captureList = NULL, **oldCapture;
    Tcl_HashTable addresses, *oldAddresses;

    /*
     * Parse the starting and stopping indices.
     */

    if (TkTextGetIndex(textPtr->interp, textPtr, index1String, &index1)
	    != TCL_OK) {
	return TCL_ERROR;
    }
    if (index2String != NULL) {
	if (TkTextGetIndex(textPtr->interp, textPtr, index2String, &index2)
		!= TCL_OK) {
	    return TCL_ERROR;
	}
    } else {
	index2 = index1;
	TkTextIndexForwChars(&index2, 1, &index2);
    }

    /*
     * Make sure there's really something to delete.
     */

    if (TkTextIndexCmp(&index1, &index2) >= 0) {
	return TCL_OK;
    }

    /*
     * The code below is ugly, but it's needed to make sure there
     * is always a dummy empty line at the end of the text.  If the
     * final newline of the file (just before the dummy line) is being
     * deleted, then back up index to just before the newline.  If
     * there is a newline just before the first character being deleted,
     * then back up the first index too, so that an even number of lines
     * gets deleted.  Furthermore, remove any tags that are present on
     * the newline that isn't going to be deleted after all (this simulates
     * deleting the newline and then adding a "clean" one back again).
     */

    line1 = TkBTreeLineIndex(index1.linePtr);
    line2 = TkBTreeLineIndex(index2.linePtr);
    if (line2 == TkBTreeNumLines(textPtr->tree)) {
	TkTextTag **arrayPtr;
	int arraySize = 0, i, content, empty;
	TkTextIndex oldIndex2;

	oldIndex2 = index2;
	TkTextIndexBackChars(&oldIndex2, 1, &index2);
	line2--;
	if ((index1.byteIndex == 0) && (line1 != 0)) {
	    TkTextIndexBackChars(&index1, 1, &index1);
	    line1--;
	}

	/*
	 * The tags taken off the final newline are recorded for undo
	 * (in the same step, before the deletion), so that the undo
	 * puts them back on it.  If they are all there is to change
	 * (the range is empty now: the final newline alone), and there
	 * are none, nothing is done, nor recorded.
	 */

	arrayPtr = TkBTreeGetTags(&index2, &arraySize);
	content = 0;			/* A tag other than sel? */
	for (i = 0; i < arraySize; i++) {
	    if (arrayPtr[i] != textPtr->selTagPtr) {
		content = 1;
	    }
	}
	empty = (TkTextIndexCmp(&index1, &index2) >= 0);
	if (!empty || content) {
	    DeletionSeparator(textPtr);
	}
	if (arrayPtr != NULL) {
	    for (i = 0; i < arraySize; i++) {
		RecordTagChange(textPtr, &index2, &oldIndex2, arrayPtr[i], 0,
			-1);
	    }
	    ckfree((char *) arrayPtr);
	}
	if (empty) {
	    /*
	     * Only tags changed, if any: recorded, and counted for the
	     * modified flag, unless only the selection (not content).
	     */

	    if (content) {
		UpdateDirtyFlag(textPtr);
	    }
	    return TCL_OK;
	}
    } else {
	DeletionSeparator(textPtr);
    }

    /*
     * In a block with leaves of different depths, the two leaves the
     * deletion joins are first made equally deep (WRAPs of the
     * shallower one: no text changes, -valuecommand is told).  Their
     * record goes to the undo atom (below), or to the atom an undo or
     * a redo applies (editAtom): undoing the deletion pulls them out
     * again (TkIBTreeUndoWraps).
     */

    wraps = TkBTreeEqualizeDelete(textPtr, &index1, &index2);
    if (textPtr->editAtom != NULL) {
	if (textPtr->editAtom->wraps != NULL) {
	    ckfree((char *) textPtr->editAtom->wraps);
	}
	textPtr->editAtom->wraps = wraps;
	textPtr->editAtom = NULL;
	wraps = NULL;
    }

    /*
     * With a -valuecommand: the values the deletion will detach, while
     * the text is unchanged (they go to the undo step if it can be
     * undone, see below).
     */

    if (TkTextVcOn(textPtr)) {
	TkBTreeVcPredictDelete(textPtr, &index1, &index2,
		((textPtr->undo || (textPtr->editValues != NULL))
			&& textPtr->haveValues)
		? TK_TEXT_VC_STASH : TK_TEXT_VC_DROP);
	TkBTreeVcNewDissolve(textPtr, &index1, &index2);
    }

    /*
     * Tell the display what's about to happen so it can discard
     * obsolete display information, then do the deletion.  Also,
     * if the deletion involves the top line on the screen, then
     * we have to reset the view (the deletion will invalidate
     * textPtr->topIndex).  Compute what the new first character
     * will be, then do the deletion, then reset the view.
     */

    TkTextChanged(textPtr, &index1, &index2);
    resetView = line = byteIndex = 0;
    if (TkTextIndexCmp(&index2, &textPtr->topIndex) >= 0) {
	if (TkTextIndexCmp(&index1, &textPtr->topIndex) <= 0) {
	    /*
	     * Deletion range straddles topIndex: use the beginning
	     * of the range as the new topIndex.
	     */

	    resetView = 1;
	    line = line1;
	    byteIndex = index1.byteIndex;
	} else if (index1.linePtr == textPtr->topIndex.linePtr) {
	    /*
	     * Deletion range starts on top line but after topIndex.
	     * Use the current topIndex as the new one.
	     */

	    resetView = 1;
	    line = line1;
	    byteIndex = textPtr->topIndex.byteIndex;
	}
    } else if (index2.linePtr == textPtr->topIndex.linePtr) {
	/*
	 * Deletion range ends on top line but before topIndex.
	 * Figure out what will be the new character index for
	 * the character currently pointed to by topIndex.
	 */

	resetView = 1;
	line = line2;
	byteIndex = textPtr->topIndex.byteIndex;
	if (index1.linePtr != index2.linePtr) {
	    byteIndex -= index2.byteIndex;
	} else {
	    byteIndex -= (index2.byteIndex - index1.byteIndex);
	}
    }
    /*
     * Record the deletion for "edit undo" (its text as "get" reports it,
     * its structure as "block list" does), and account for it in the
     * modified flag.
     */

    if (textPtr->undo) {
	Tcl_DString ds;
	Tcl_Obj *list;
	TkTextIndex ext1, ext2;
	int remains;
	char i1[TK_POS_CHARS], i2[TK_POS_CHARS], i3[TK_POS_CHARS];
	TkTextUndoAtom *atomPtr;

	TkTextPrintIndex(&index1, i1);
	TkTextPrintIndex(&index2, i2);
	TextGetText(textPtr, &index1, &index2, &ds);

	/*
	 * The blocks, tags and marks of the range are re-created on undo
	 * from what "block list" reports.  If both ends of the range are
	 * in the same block (or both outside blocks) the range holds only
	 * whole blocks and the list of the range itself will do.
	 * Otherwise the deletion cuts blocks, which the widget dissolves:
	 * the list covers the smallest enclosing range that cuts none,
	 * and the undo first takes out what the dissolution left of the
	 * cut blocks (TkIBTreeCutRange).
	 */

	if (TkIBTreeCutRange(&index1, &index2, &ext1, &ext2, &remains) == 0) {
	    ext1 = index1;
	    ext2 = index2;
	    remains = 0;
	}
	list = TextGetList(textPtr, &ext1, &ext2);
	TkTextPrintIndex(&ext1, i3);
	atomPtr = TkTextUndoPushAction(textPtr->undoStack, TK_TEXT_UNDO_DELETE,
		i1, i2,
		Tcl_NewStringObj(Tcl_DStringValue(&ds), Tcl_DStringLength(&ds)),
		list, i3, remains);
	if (remains > 0) {
	    atomPtr->cuts = TkIBTreeCutPositions(&index1, &index2, &ext1,
		    &atomPtr->numHeads, &atomPtr->numTails);
	}
	atomPtr->wraps = wraps;
	wraps = NULL;
	captureList = &atomPtr->values;
	recordPtr = atomPtr;
	Tcl_DStringFree(&ds);
    } else if (textPtr->editValues != NULL) {
	/*
	 * An undo or a redo is deleting text: the atom it applies keeps
	 * the values the deletion drops.
	 */

	captureList = textPtr->editValues;
	textPtr->editValues = NULL;
    }
    if (wraps != NULL) {
	ckfree((char *) wraps);		/* Not recorded. */
    }
    UpdateDirtyFlag(textPtr);

    /*
     * The values the deletion drops from nodes of blocks go to its undo
     * atom, with the addresses of their nodes as they are now, which
     * are their addresses again once the deletion is undone.
     */

    oldCapture = textPtr->valueCapture;
    oldAddresses = textPtr->valueAddresses;
    if ((captureList != NULL) && textPtr->haveValues) {
	TkBTreeSnapshotValues(textPtr, &index1, &index2, &addresses);
	textPtr->valueCapture = captureList;
	textPtr->valueAddresses = &addresses;
    }
    TkTextRootLogReset(textPtr);
    TkTextOrnBeforeDelete(textPtr, &index1, &index2);
    TkBTreeDeleteChars(&index1, &index2, 1, 1);
    TkTextOrnAfterDelete(textPtr);
    if (recordPtr != NULL) {
	/*
	 * The leaves of a block dissolved in a block that was a single
	 * leaf made its root real: the undo makes it padding again.
	 */

	recordPtr->roots = TkTextRootLogTake(textPtr);
    }
    if (textPtr->valueAddresses == &addresses) {
	TkBTreeFreeSnapshot(&addresses);
    }
    textPtr->valueCapture = oldCapture;
    textPtr->valueAddresses = oldAddresses;
    if (resetView) {
	TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &index1);
	TkTextSetYView(textPtr, &index1, 0);
    }

    /*
     * Invalidate any selection retrievals in progress.
     */

    textPtr->abortSelections = 1;

    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TextFetchSelection --
 *
 *	This procedure is called back by Tk when the selection is
 *	requested by someone.  It returns part or all of the selection
 *	in a buffer provided by the caller.
 *
 * Results:
 *	The return value is the number of non-NULL bytes stored
 *	at buffer.  Buffer is filled (or partially filled) with a
 *	NULL-terminated string containing part or all of the selection,
 *	as given by offset and maxBytes.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
TextFetchSelection(clientData, offset, buffer, maxBytes)
    ClientData clientData;		/* Information about text widget. */
    int offset;				/* Offset within selection of first
					 * character to be returned. */
    char *buffer;			/* Location in which to place
					 * selection. */
    int maxBytes;			/* Maximum number of bytes to place
					 * at buffer, not including terminating
					 * NULL character. */
{
    register TkText *textPtr = (TkText *) clientData;
    TkTextIndex eof;
    int count, startOff, endOff;
    TkTextSearch search;
    TkTextLine *linePtr;

    if (!textPtr->exportSelection) {
	return -1;
    }

    /*
     * Find the beginning of the next range of selected text.  Note:  if
     * the selection is being retrieved in multiple pieces (offset != 0)
     * and some modification has been made to the text that affects the
     * selection then reject the selection request (make 'em start over
     * again).
     */

    if (offset == 0) {
	TkTextMakeByteIndex(textPtr->tree, 0, 0, &textPtr->selIndex);
	textPtr->abortSelections = 0;
	textPtr->selRest = 0;
    } else if (textPtr->abortSelections) {
	return 0;
    } else {
      TkTextIndexToExternalIndex(textPtr->tree, 
				 &textPtr->selIndex, &textPtr->selIndex);
    }
    TkTextMakeByteIndex(textPtr->tree, TkBTreeNumLines(textPtr->tree), 0, &eof);
    TkBTreeStartSearch(&textPtr->selIndex, &eof, textPtr->selTagPtr, &search);
    if (!TkBTreeCharTagged(&textPtr->selIndex, textPtr->selTagPtr)) {
	if (!TkBTreeNextTag(&search)) {
	    if (offset == 0) {
		return -1;
	    } else {
		return 0;
	    }
	}
	textPtr->selIndex = search.extIndex;
    }

    /*
     * Each iteration through the outer loop below scans one selected range.
     * Each iteration through the inner loop scans one segment in the
     * selected range.
     */

    count = 0;
    if (textPtr->selRest) {	/* Need to skip first several characters. */
        Tcl_DString dString;
	int i;
	char *s;

	Tcl_DStringInit(&dString);
	TkBTreeLineTextAppend(textPtr,
			      textPtr->selIndex.linePtr,
			      textPtr->selIndex.byteIndex,
			      textPtr->selIndex.byteIndex + 1, 
			      (void*)&dString, 
			      TkTextUserGetFlags(textPtr) | TKT_GET_NOELIDE | TKT_GET_DSTRING,
			      NULL);
	s = Tcl_DStringValue(&dString) + textPtr->selRest;
	i = Tcl_DStringLength(&dString) - textPtr->selRest;
	if (i > maxBytes) {
	  textPtr->selRest += maxBytes;
	  i = maxBytes;
	} else {
	  textPtr->selRest = 0;
	  textPtr->selIndex.byteIndex++;
	}
	maxBytes -= i;
	count += i;
	while (i--) {
	  *buffer++ = *s++;
	}
	textPtr->selRest = maxBytes;
	Tcl_DStringFree(&dString);
    }
    while (1) {
	/*
	 * Find the end of the current range of selected text.
	 */

	if (!TkBTreeNextTag(&search)) {
	    panic("TextFetchSelection couldn't find end of range");
	}

	/*
	 * Copy information from character lines into the buffer
	 * until either we run out of space in the buffer or we get
	 * to the end of this range of text.
	 */

	linePtr =  textPtr->selIndex.linePtr;
	startOff = textPtr->selIndex.byteIndex;
	endOff = -1;
	while (1) {
	    int pos, m = maxBytes;

	    if (maxBytes == 0) {
		goto done;
	    }
	    if (linePtr == search.extIndex.linePtr) {
	      endOff = search.extIndex.byteIndex;
	    }
	    pos = TkBTreeLineTextAppend(textPtr, linePtr, startOff, endOff,
					(void *)buffer, 
					TkTextUserGetFlags(textPtr) | TKT_GET_NOELIDE | TKT_GET_BUFFER,
					&maxBytes);
	    buffer += m - maxBytes;
	    count  += m - maxBytes;
	    /* Need to check the status: could reach the end of line,
	     * or the end of buffer (some place may been left in buffer
	     * if the representation of the last character takes more
	     * than 1 byte). */
	    if (pos == endOff) {	/* Done with this range */
	      break;
	    } else if (pos == TkBTreeCharsInLine(linePtr)) { /* End of line */
	      linePtr = TkBTreeNextLine(linePtr);
	      startOff = 0;
	      continue;
	    } else {		/* Did not reach the end of line */
	      if (maxBytes) {	/* Next index takes several bytes in
				 * string representation. */
		Tcl_DString dString;
		int i = maxBytes;
		char *s;

		Tcl_DStringInit(&dString);
		TkBTreeLineTextAppend(textPtr, linePtr, pos, pos + 1, 
				      (void*)&dString, 
				      TkTextUserGetFlags(textPtr) | TKT_GET_NOELIDE | TKT_GET_DSTRING,
				      NULL);
		s = Tcl_DStringValue(&dString);
		while (i--) {
		  *buffer++ = *s++;
		}
		textPtr->selRest = maxBytes;
		Tcl_DStringFree(&dString);
	      }
	      textPtr->selIndex.linePtr = linePtr;
	      textPtr->selIndex.byteIndex = pos;
	      goto done;
	    }
	}

	/*
	 * Find the beginning of the next range of selected text.
	 */

	if (!TkBTreeNextTag(&search)) {
	    break;
	}
	textPtr->selIndex = search.extIndex;
    }

    done:
    *buffer = 0;
    return count;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextLostSelection --
 *
 *	This procedure is called back by Tk when the selection is
 *	grabbed away from a text widget.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The "sel" tag is cleared from the window.
 *
 *----------------------------------------------------------------------
 */

void
TkTextLostSelection(clientData)
    ClientData clientData;		/* Information about text widget. */
{
    register TkText *textPtr = (TkText *) clientData;
    TkTextIndex start, end;

    if (!textPtr->exportSelection) {
	return;
    }

    /*
     * Just remove the "sel" tag from everything in the widget.
     */

    TkTextMakeByteIndex(textPtr->tree, 0, 0, &start);
    TkTextMakeByteIndex(textPtr->tree, TkBTreeNumLines(textPtr->tree), 0, &end);
    TkTextRedrawTag(textPtr, &start, &end, textPtr->selTagPtr, 1);
    TkBTreeTag(&start, &end, textPtr->selTagPtr, 0);
    textPtr->flags &= ~GOT_SELECTION;
}

/*
 *----------------------------------------------------------------------
 *
 * TextBlinkProc --
 *
 *	This procedure is called as a timer handler to blink the
 *	insertion cursor off and on.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The cursor gets turned on or off, redisplay gets invoked,
 *	and this procedure reschedules itself.
 *
 *----------------------------------------------------------------------
 */

static void
TextBlinkProc(clientData)
    ClientData clientData;	/* Pointer to record describing text. */
{
    register TkText *textPtr = (TkText *) clientData;
    TkTextIndex index, index2;

    if (!(textPtr->flags & GOT_FOCUS) || (textPtr->insertOffTime == 0)) {
	return;
    }
    if (textPtr->flags & INSERT_ON) {
	textPtr->flags &= ~INSERT_ON;
	textPtr->insertBlinkHandler = Tcl_CreateTimerHandler(
		textPtr->insertOffTime, TextBlinkProc, (ClientData) textPtr);
    } else {
	textPtr->flags |= INSERT_ON;
	textPtr->insertBlinkHandler = Tcl_CreateTimerHandler(
		textPtr->insertOnTime, TextBlinkProc, (ClientData) textPtr);
    }
    TkTextMarkSegToIndex(textPtr, textPtr->insertMarkPtr, &index);
    TkTextIndexForwChars(&index, 1, &index2);
    TkTextChanged(textPtr, &index, &index2);
}

/*
 *----------------------------------------------------------------------
 *
 * TextSearchCmd --
 *
 *	This procedure is invoked to process the "search" widget command
 *	for text widgets.  See the user documentation for details on what
 *	it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static int
TextSearchCmd(textPtr, interp, argc, args)
    TkText *textPtr;		/* Information about text widget. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    Arg *args;		/* Argument strings. */
{
    int backwards, exact, c, i, argsLeft, noCase;
    int searchElide, elideFlag, matchStrLength;
    size_t length;
    int numLines, startingLine, startingChar, lineNum, firstChar, lastChar;
    int code, matchLength, matchChar, passes, stopLine, searchWholeText;
    int patLength;
    char *arg, *pattern, *p, *startOfLine;
    Arg varName, patObj;
    char buffer[20];
    TkTextIndex index, stopIndex;
    Tcl_DString line;
    Tcl_DString patDString;
    TkTextLine *linePtr;
    Tcl_RegExp regExp = NULL;		/* Initialization needed only to
					 * prevent compiler warning. */

    /*
     * Parse switches and other arguments.
     */

    exact = 1;
    backwards = 0;
    noCase = 0;
    searchElide = 0;
    matchStrLength = 0;
    varName = NULL;
    for (i = 2; i < argc; i++) {
	arg = LangString(args[i]);
	if (arg[0] != '-') {
	    break;
	}
	length = strlen(arg);
	if (length < 2) {
	    badSwitch:
	    Tcl_AppendResult(interp, "bad switch \"", arg,
		    "\": must be -forward, -backward, -exact, -regexp, ",
		    "-nocase, -count, -elide, or --",          NULL);
	    return TCL_ERROR;
	}
	c = arg[1];
	if ((c == 'b') &&  LangCmpOpt("-backwards",LangString(args[i]),length) == 0 ) {
	    backwards = 1;
	} else if ((c == 'c') &&  LangCmpOpt("-count",LangString(args[i]),length) == 0 ) {
	    if (i >= (argc-1)) {
		Tcl_SetResult(interp, "no value given for \"-count\" option",TCL_STATIC);
		return TCL_ERROR;
	    }
	    i++;
	    varName = args[i];
	} else if ((c == 'e') &&  LangCmpOpt("-elide",LangString(args[i]),length) == 0 ) {
	    searchElide = 1;
	} else if ((c == 'e') &&  LangCmpOpt("-exact",LangString(args[i]),length) == 0 ) {
	    exact = 1;
	} else if ((c == 'f') &&  LangCmpOpt("-forwards",LangString(args[i]),length) == 0 ) {
	    backwards = 0;
	} else if ((c == 'n') &&  LangCmpOpt("-nocase",LangString(args[i]),length) == 0 ) {
	    noCase = TKT_GET_NOCASE;
	} else if ((c == 'r') &&  LangCmpOpt("-regexp",LangString(args[i]),length) == 0 ) {
	    exact = 0;
	} else if ((c == '-') &&  LangCmpOpt("--",LangString(args[i]),length) == 0 ) {
	    i++;
	    break;
	} else {
	    goto badSwitch;
	}
    }
    argsLeft = argc - (i+2);
    if ((argsLeft != 0) && (argsLeft != 1)) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		LangString(args[0]), " search ?switches? pattern index ?stopIndex?",
		         NULL);
	return TCL_ERROR;
    }
    pattern = LangString(args[i]);
    patObj = args[i];

    /*
     * Elided text is not searched unless -elide was given (as in Tk 8.4).
     */

    elideFlag = searchElide ? 0 : TKT_GET_NOELIDE;

    /*
     * Convert the pattern to lower-case if we're supposed to ignore case
     * (the text is extracted in lower case in that case, see
     * TKT_GET_NOCASE; regexps get TCL_REG_NOCASE instead).
     */

    if (noCase && exact) {
	Tcl_DStringInit(&patDString);
	Tcl_DStringAppend(&patDString, pattern, -1);
	pattern = Tcl_DStringValue(&patDString);
	TkTextUtfToLowerSameLength(pattern, Tcl_DStringLength(&patDString));
    }

    if (TkTextGetIndex(interp, textPtr, LangString(args[i+1]), &index) != TCL_OK) {
	if (noCase && exact) {
	    Tcl_DStringFree(&patDString);
	}
	return TCL_ERROR;
    }
    numLines = TkBTreeNumLines(textPtr->tree);
    startingLine = TkBTreeLineIndex(index.linePtr);
    startingChar = index.byteIndex;
    if (startingLine >= numLines) {
	if (backwards) {
	    startingLine = TkBTreeNumLines(textPtr->tree) - 1;
	    startingChar = TkBTreeCharsInLine(TkBTreeFindLine(textPtr->tree,
		    startingLine));
	} else {
	    startingLine = 0;
	    startingChar = 0;
	}
    }
    if (argsLeft == 1) {
	if (TkTextGetIndex(interp, textPtr, LangString(args[i+2]), &stopIndex) != TCL_OK) {
	    if (noCase && exact) {
		Tcl_DStringFree(&patDString);
	    }
	    return TCL_ERROR;
	}
	stopLine = TkBTreeLineIndex(stopIndex.linePtr);
	if (!backwards && (stopLine == numLines)) {
	    stopLine = numLines-1;
	}
	searchWholeText = 0;
    } else {
	stopLine = 0;
	searchWholeText = 1;
    }

    /*
     * Scan through all of the lines of the text circularly, starting
     * at the given index.
     */

    matchLength = patLength = 0;	/* Only needed to prevent compiler
					 * warnings. */
    if (exact) {
	patLength = strlen(pattern);
    } else {
	regExp = Lang_RegExpCompile(interp, patObj, noCase);
	if (regExp == NULL) {
	    return TCL_ERROR;
	}
    }
    lineNum = startingLine;
    code = TCL_OK;
    Tcl_DStringInit(&line);
    for (passes = 0; passes < 2; ) {
	if (lineNum >= numLines) {
	    /*
	     * Don't search the dummy last line of the text.
	     */

	    goto nextLine;
	}

	/*
	 * Extract the text from the line.  If we're doing regular
	 * expression matching, drop the newline from the line, so
	 * that "$" can be used to match the end of the line.
	 */

	linePtr = TkBTreeFindLine(textPtr->tree, lineNum);

	/*
	 * The starting line is tricky: the first time we see it
	 * we check one part of the line, and the second pass through
	 * we check the other part of the line.  
	 */

	if (lineNum == startingLine) {
	    passes++;
	    TkBTreeLineTextAppend(textPtr, linePtr, 0, startingChar, (void*)&line, 
				  TkTextUserGetFlags(textPtr) | noCase | elideFlag | TKT_GET_DSTRING,
				  NULL);
	    firstChar = Tcl_DStringLength(&line);
	    TkBTreeLineTextAppend(textPtr, linePtr, startingChar, -1, (void*)&line, 
				  TkTextUserGetFlags(textPtr) | noCase | elideFlag | TKT_GET_DSTRING,
				  NULL);
	    if ((passes == 1) ^ backwards) {
		lastChar = INT_MAX;
	    } else {
	      lastChar = firstChar;
	      firstChar = 0;
	    }
	} else {
	    TkBTreeLineTextAppend(textPtr, linePtr, 0, -1, (void*)&line, 
				  TkTextUserGetFlags(textPtr) | noCase | elideFlag | TKT_GET_DSTRING,
				  NULL);
	    firstChar = 0;
	    lastChar = INT_MAX;
	}
	if (!exact) {
	    Tcl_DStringSetLength(&line, Tcl_DStringLength(&line)-1);
	}
	startOfLine = Tcl_DStringValue(&line);

	/*
	 * If we're ignoring case, convert the line to lower case.
	 */

#if 0
	if (noCase) {
	    for (p = Tcl_DStringValue(&line); *p != 0; p++) {
		if (isupper(UCHAR(*p))) {
		    *p = tolower(UCHAR(*p));
		}
	    }
	}
#endif

	/*
	 * Check for matches within the current line.  If so, and if we're
	 * searching backwards, repeat the search to find the last match
	 * in the line.
	 */

	matchChar = -1;
	do {
	    int thisLength;
	    Tcl_UniChar ch;

	    if (exact) {
		p = strstr(startOfLine + firstChar, pattern);
		if (p == NULL) {
		    break;
		}
		i = p - startOfLine;
		thisLength = patLength;
	    } else {
		char *start, *end;
		int match;

		match = Lang_RegExpExec(interp, regExp,
			startOfLine + firstChar, startOfLine);
		if (match < 0) {
		    code = TCL_ERROR;
		    goto done;
		}
		if (!match) {
		    break;
		}
		Tcl_RegExpRange(regExp, 0, &start, &end);
		i = start - startOfLine;
		thisLength = end - start;
	    }
	    if (i >= lastChar) {
		break;
	    }
	    matchChar = i;
	    matchLength = thisLength;
	    matchStrLength = thisLength;
	    firstChar = matchChar + Tcl_UtfToUniChar(startOfLine + matchChar, &ch);
	} while (backwards);

	/*
	 * If we found a match then we're done.  Make sure that
	 * the match occurred before the stopping index, if one was
	 * specified.
	 */

	if (matchChar >= 0) {
	    /*
	     * The index information returned by the regular expression
	     * parser considers string representation. Now find the
	     * position in the text widget.
	     */

	    int offset = matchChar;
	    int posStart = TkBTreeLineTextAppend(textPtr, linePtr, 0, -1, NULL,
						 TkTextUserGetFlags(textPtr) | elideFlag | TKT_GET_OFFSET,
						 &offset);

	    offset += matchLength;
	    matchLength = TkBTreeLineTextAppend(textPtr, linePtr, posStart, -1, NULL,
						TkTextUserGetFlags(textPtr) | elideFlag | TKT_GET_OFFSET,
						&offset) 
	      - posStart;
	    if (offset) matchLength++; /* Include partially matched
					* character. */
	    TkTextMakeByteIndex(textPtr->tree, lineNum, posStart, &index);
	    if (!searchWholeText) {
		if (!backwards && (TkTextIndexCmp(&index, &stopIndex) >= 0)) {
		    goto done;
		}
		if (backwards && (TkTextIndexCmp(&index, &stopIndex) < 0)) {
		    goto done;
		}
	    }
	    if (varName != NULL) {
		Tcl_Obj *temp;

		/*
		 * Report the length of the match in characters: those of the
		 * matched text (which leaves out elided text, as in Tk 8.4).
		 */

		temp = Tcl_NewIntObj(Tcl_NumUtfChars(startOfLine + matchChar,
			matchStrLength));

		if (Tcl_ObjSetVar2(interp, varName, NULL, temp,
			TCL_LEAVE_ERR_MSG) == NULL) {
		    code = TCL_ERROR;
		    Tcl_DecrRefCount(temp);
		    goto done;
		}
		Tcl_DecrRefCount(temp);
	    }
	    TkTextPrintIndex(&index, buffer);
	    Tcl_SetResult(interp,buffer,TCL_VOLATILE);
	    goto done;
	}

	/*
	 * Go to the next (or previous) line;
	 */

	nextLine:
	if (backwards) {
	    lineNum--;
	    if (!searchWholeText) {
		if (lineNum < stopLine) {
		    break;
		}
	    } else if (lineNum < 0) {
		lineNum = numLines-1;
	    }
	} else {
	    lineNum++;
	    if (!searchWholeText) {
		if (lineNum > stopLine) {
		    break;
		}
	    } else if (lineNum >= numLines) {
		lineNum = 0;
	    }
	}
	Tcl_DStringSetLength(&line, 0);
    }
    done:
    Tcl_DStringFree(&line);
    if (noCase && exact) {
	Tcl_DStringFree(&patDString);
    }
    if (regExp) {
	Lang_FreeRegExp(regExp);
    }
    return code;
}

static Tk_ConfigSpec blockConfigSpecs[] = {
    {TK_CONFIG_CALLBACK, "-layoutcmd",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, layoutCmd),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_LANGARG, "-layoutwidths",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, widthsStr),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_INT, "-layoutdepth",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, depth),
		TK_CONFIG_DONT_SET_DEFAULT | TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-empty",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, empty),
		TK_CONFIG_DONT_SET_DEFAULT | TK_CONFIG_NULL_OK},
    {TK_CONFIG_CALLBACK, "-deletecallback",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, deleteCallBack),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_CALLBACK, "-leafdeletecallback",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, leafDeleteCallBack),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_CALLBACK, "-leafaddcallback",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, leafAddCallBack),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_CALLBACK, "-leafemptycallback",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, leafEmptyCallBack),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_LANGARG, "-ornaments",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextBlock, ornamentsArg),
		TK_CONFIG_NULL_OK},
    {TK_CONFIG_END,          NULL,          NULL,          NULL,
	         NULL, 0, 0}
};
/*
 * The instance data of a block ("block data") is the Lang part of the
 * container TkTextITree.data: a custom option that does to the Lang
 * part what TK_CONFIG_LANGARG did to a bare Arg (TK_CONFIG_NULL_OK:
 * undef or an empty string removes it).
 */

static Tk_CustomOption blockDataOption = {
    BlockDataParse, BlockDataPrint, (ClientData) NULL
};

static Tk_ConfigSpec blockInstanceConfigSpecs[] = {
    {TK_CONFIG_CUSTOM, "-instancedata",          NULL,          NULL,
	         NULL, Tk_Offset(TkTextITree, data),
		TK_CONFIG_NULL_OK, &blockDataOption},
    {TK_CONFIG_END,          NULL,          NULL,          NULL,
	         NULL, 0, 0}
};

/*
 *--------------------------------------------------------------
 *
 * BlockDataParse, BlockDataPrint --
 *
 *	Set and read the Lang part of the instance data of a block,
 *	leaving the other slots of the container alone.
 *
 *	The value replaced goes to the widget's list of values to free
 *	when the widget command ends, as every other value (it was
 *	freed at once, as Tk_ConfigureWidget freed a TK_CONFIG_LANGARG
 *	option, so that its DESTROY ran inside the command: BUGS 22).  Both callers (block data, and the
 *	instance data of a block list being inserted) run inside the
 *	widget command, which flushes the list.  The read gives the
 *	stored scalar itself with one more reference, as
 *	Tk_ConfigureValue did.
 *
 *--------------------------------------------------------------
 */

static int
BlockDataParse(clientData, interp, tkwin, value, widgRec, offset)
    ClientData clientData;	/* Not used. */
    Tcl_Interp *interp;		/* Not used. */
    Tk_Window tkwin;		/* Not used. */
    Arg value;			/* The new value. */
    char *widgRec;		/* The TkTextITree. */
    int offset;			/* Where its data is. */
{
    TkTextData *dataPtr = (TkTextData *) (widgRec + offset);
    TkTextBlock *blockPtr = ((TkTextITree *) widgRec)->blockPtr;
    Arg old;

    if (LangNull(value)) {
	old = TkTextDataTakeLang(dataPtr);
    } else {
	old = TkTextDataPutLang(dataPtr, LangCopyArg(value));
	if ((blockPtr != NULL) && (blockPtr->textPtr != NULL)) {
	    /*
	     * The deletions that can be undone record it (it is a value
	     * like the others: TK_TEXT_VALUE_BLOCK).
	     */

	    blockPtr->textPtr->haveValues = 1;
	}
    }
    TkTextFreeValueLater((blockPtr != NULL) ? blockPtr->textPtr : NULL,
	    TkTextDataFromLang(old));
    return TCL_OK;
}

static Arg
BlockDataPrint(clientData, tkwin, widgRec, offset, freeProcPtr)
    ClientData clientData;	/* Not used. */
    Tk_Window tkwin;		/* Not used. */
    char *widgRec;		/* The TkTextITree. */
    int offset;			/* Where its data is. */
    Tcl_FreeProc **freeProcPtr;	/* Not used: the result is a new
				 * reference. */
{
    Arg data = TkTextDataGetLang(*(TkTextData *) (widgRec + offset));
    Arg result = NULL;

    if (data != NULL) {
	Tcl_IncrRefCount(data);
    }
    LangSetObj(&result, data);
    return result;
}


/*
 *--------------------------------------------------------------
 *
 * TkTextBlockCmd --
 *
 *	This procedure is invoked to process the "block" options of
 *	the widget command for text widgets. See the user documentation
 *	for details on what it does.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *--------------------------------------------------------------
 */

int
TkTextBlockCmd(textPtr, interp, argc, args)
    register TkText *textPtr;	/* Information about text widget. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    Arg *args;		/* Argument strings.  Someone else has already
				 * parsed this command enough to know that
				 * LangString(args[1]) is "mark". */
{
    TkTextIndex index1, index2;
    int length, i;
    char c;
    TkTextBlock *blockPtr;
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;
    int new;


    if (argc < 3) {
        Tcl_AppendResult(interp, "wrong # args: should be \"",
			 LangString(args[0]), " block option ?arg arg ...?\"",
			          NULL);
	return TCL_ERROR;
    }
    c = LangString(args[2])[0];
    length = strlen(LangString(args[2]));
    if ((c == 'c') && (strncmp(LangString(args[2]), "cget", length) == 0)
	    && (length >= 2)) {
	if (argc != 5) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block cget blockName option\"",
		             NULL);
	    return TCL_ERROR;
	}
	hPtr = Tcl_FindHashEntry(&textPtr->blockTable, LangString(args[3]));
	if (hPtr == NULL) {
	    Tcl_AppendResult(interp, "there is no block named \"",
		    LangString(args[3]), "\"",          NULL);
	    return TCL_ERROR;
	}
	blockPtr = (TkTextBlock *) Tcl_GetHashValue(hPtr);
	return Tk_ConfigureValue(interp, textPtr->tkwin, blockConfigSpecs,
		(char *) blockPtr, LangString(args[4]), 0);
    } else if ((c == 'c') && (strncmp(LangString(args[2]), "configure", length) == 0)
	    && (length >= 2)) {
        if (argc < 4) {
	  Tcl_AppendResult(interp, "wrong # args: should be \"",
			   LangString(args[0]), " block configure blockName ?arg arg ...?\"",
			            NULL);
	  return TCL_ERROR;
	}
	hPtr = Tcl_CreateHashEntry(&textPtr->blockTable, 
				   LangString(args[3]), &new);
	if (new) {
	  blockPtr = (TkTextBlock *) ckalloc(sizeof(TkTextBlock));
	  Tcl_SetHashValue(hPtr, blockPtr);
	  blockPtr->name = Tcl_GetHashKey(&textPtr->blockTable, hPtr);
	  blockPtr->layoutCmd = NULL;
	  blockPtr->deleteCallBack = NULL;
	  blockPtr->leafDeleteCallBack = NULL;
	  blockPtr->leafAddCallBack = NULL;
	  blockPtr->leafEmptyCallBack = NULL;
	  blockPtr->textPtr = textPtr;
	  blockPtr->count = 0;
	  blockPtr->depth = -1;		/* As documented: no simulated depth. */
	  blockPtr->empty = 0;
	  blockPtr->widthsNum = 0;
	  blockPtr->widthsMin = NULL;
	  blockPtr->widthsMax = NULL;
	  blockPtr->widthsStr = NULL;
	  blockPtr->ornamentsArg = NULL;
	  blockPtr->ornTemplates = NULL;
	} else {
	  blockPtr = (TkTextBlock *) Tcl_GetHashValue(hPtr);
	}
	if (argc == 4) {
	    return Tk_ConfigureInfo(interp, textPtr->tkwin, blockConfigSpecs,
		    (char *) blockPtr,          NULL, 0);
	} else if (argc == 5) {
	    return Tk_ConfigureInfo(interp, textPtr->tkwin, blockConfigSpecs,
		    (char *) blockPtr, LangString(args[4]), 0);
	} else {
	    int result;
	    char *w = LangString(args[0]);
	    Arg oldOrnaments = blockPtr->ornamentsArg;

	    /*
	     * -ornaments: parsed into templates (tkTextOrn.c); a value
	     * that does not parse leaves the old one.
	     */

	    if (oldOrnaments != NULL) {
		oldOrnaments = LangCopyArg(oldOrnaments);
	    }
	    result = Tk_ConfigureWidget(interp, textPtr->tkwin, blockConfigSpecs,
		    argc-4, args+4, (char *) blockPtr, 0);
	    if (result == TCL_OK) {
		struct TkTextOrnTemplates *templPtr;

		if (TkTextOrnTemplatesParse(interp, textPtr,
			blockPtr->ornamentsArg, &templPtr) == TCL_OK) {
		    TkTextOrnTemplatesRelease(textPtr, blockPtr->ornTemplates);
		    blockPtr->ornTemplates = templPtr;
		} else {
		    if (blockPtr->ornamentsArg != NULL) {
			LangFreeArg(blockPtr->ornamentsArg, LANG_DYNAMIC);
		    }
		    blockPtr->ornamentsArg = oldOrnaments;
		    oldOrnaments = NULL;
		    result = TCL_ERROR;
		}
	    }
	    if (oldOrnaments != NULL) {
		LangFreeArg(oldOrnaments, LANG_DYNAMIC);
	    }
	    blockPtr->widthsNum = 0;
	    if (blockPtr->widthsStr) {
              int argc, code, count;
	      Arg *args;
	      LangFreeProc *freeProc = NULL;
	      
	      if (blockPtr->widthsMin) {
		ckfree((char*)blockPtr->widthsMin);
	      }
	      if (blockPtr->widthsMax) {
		ckfree((char*)blockPtr->widthsMax);
	      }
              code = Lang_SplitList(interp, blockPtr->widthsStr, 
				    &argc, &args, &freeProc);
	      if (code == TCL_ERROR) {
		blockPtr->widthsNum = 0;
		Tcl_AppendResult(interp, " \"", LangString(blockPtr->widthsStr), 
				 "\" in \"", w, " block configure\" command",
				          NULL);
		return TCL_ERROR;
	      }
	      blockPtr->widthsMin = (int*) ckalloc(argc*sizeof(int));
	      blockPtr->widthsMax = (int*) ckalloc(argc*sizeof(int));
	      for (count = 0; count < argc; count++) {
		int min, max;

		if (LangIsList(args[count])) {
		  int argc1;
		  Arg *args1;
		  LangFreeProc *freeProc1 = NULL;

		  code = Lang_SplitList(interp, args[count],
					&argc1, &args1, &freeProc1);
		  if ((code != TCL_OK) || (argc1 != 2)) {
		    Tcl_AppendResult(interp, "wrong format of ",
				     "\"-layoutwidths\" element \"",
				     LangString(args[count]),
				     "\": expect a list of length 2",
				              NULL);
		    if (args1 != NULL && freeProc) (*freeProc1)(argc1,args1);
		    if (args != NULL && freeProc) (*freeProc)(argc,args);
		    return TCL_ERROR;
		  }
		  min = LangInt(args1[0]);
		  max = LangInt(args1[1]);
		  if (args1 != NULL && freeProc) (*freeProc1)(argc1,args1);
		} else {
		  max = min = LangInt(args[count]);
		}
		blockPtr->widthsMin[count] = min;
		blockPtr->widthsMax[count] = max;
	      }
	      blockPtr->widthsNum = argc;
	      if (args != NULL && freeProc) (*freeProc)(argc,args);
 	    }
	    TkTextRelayoutWindow(textPtr);
	    return result;
	}
    } else if ((c == 'd') && (strncmp(LangString(args[2]), "data", length) == 0)
	    && (length >= 2)) {
        Arg arga[2];
	int result;
	TkTextSegment *segPtr;

	arga[0] = NULL;
	arga[1] = NULL;
        if ((argc < 4) || (argc > 5)) {
	  Tcl_AppendResult(interp, "wrong # args: should be \"",
			   LangString(args[0]), " block data index ?data?\"",
			            NULL);
	  return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	    return TCL_ERROR;
	}
	/*
	 * The block enclosing the index; failing that (and for an empty
	 * block, which has no inside), the block starting at the index.
	 */

	segPtr = TkIBTreeAt(&index1, 1);
	{
	    TkTextSegment *startPtr = TkIBTreeAt(&index1, 0);

	    if ((startPtr != NULL)
		    && ((segPtr == NULL) || (startPtr->body.itree.tree == NULL))) {
		segPtr = startPtr;
	    }
	}
	if (!segPtr) {
	  Tcl_AppendResult(interp, "block data issued not inside a block.",
			            NULL);
	  return TCL_ERROR;
	}
	LangSetString(&(arga[0]), "-instancedata");
	if (argc == 4) {
	    result = Tk_ConfigureValue(interp, textPtr->tkwin, 
				       blockInstanceConfigSpecs,
				       (char *) &segPtr->body.itree,
				       LangString(arga[0]), 0);
	} else {
	    if (TkTextVcOn(textPtr)
		    && (TkTextDataGetLang(segPtr->body.itree.data) != NULL)) {
		TkTextIndex head;

		TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
		TkTextVcPredict(textPtr, segPtr->body.itree.data,
			TK_TEXT_VC_DROP, TK_TEXT_VC_BLOCK,
			TkTextVcBlockPlace(textPtr,
				TkBTreeLineIndex(head.linePtr), head.byteIndex),
			NULL);
		TkTextVcNotify(textPtr);
	    }
	    arga[1] = args[4];		/* Should work with TCL and Perl. */
	    result = Tk_ConfigureWidget(interp, textPtr->tkwin, 
					blockInstanceConfigSpecs, 2, arga, 
					(char *) &segPtr->body.itree, 0);
	    TkTextRelayoutWindow(textPtr);
	}
	LangFreeArg(arga[0], LANG_DYNAMIC);
	return result;
    } else if ((c == 't') && (strncmp(LangString(args[2]), "trim", length) == 0)) {
        TkTextSegment *segPtr;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block trim index\"",
		             NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	    return TCL_ERROR;
	}
	segPtr = TkIBTreeAt(&index1, 1);
	if (segPtr) {
	    TkTextIndex head, end;
	    TkTextValue *captured = NULL;
	    CaptureState cs;
	    int result, rootValue;
	    char i1[TK_POS_CHARS];

	    /*
	     * Recorded for undo (TK_TEXT_UNDO_TRIM): the block by the
	     * position of its head, and whether the root had a value
	     * (which the trim gives to the new root).
	     */

	    TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	    TkTextPrintIndex(&head, i1);
	    rootValue = TkIBTreeRootHasValue(segPtr);
	    TkBTreeVcPredictTrim(textPtr, segPtr, textPtr->undo
		    ? TK_TEXT_VC_STASH : TK_TEXT_VC_DROP);
	    if (textPtr->undo) {
		CaptureStart(textPtr, &cs, &captured, &head, &head);
	    }
	    result = TkIBTreeTrim(textPtr, segPtr);
	    if (textPtr->undo) {
		CaptureEnd(textPtr, &cs);
		if (result == TCL_OK) {
		    TkTextUndoAtom *atomPtr = PushEdit(textPtr,
			    TK_TEXT_EDIT_TRIM, TK_TEXT_UNDO_TRIM, i1, i1,
			    (Tcl_Obj *) NULL);

		    atomPtr->added = rootValue;
		    atomPtr->values = captured;
		} else {
		    TkTextFreeValueList(textPtr, captured);
		}
	    }
	    if (result == TCL_OK) {
		TkTextIndexForwBytes(&head, segPtr->size, &end);
		TkTextChanged(textPtr, &head, &end);
		UpdateDirtyFlag(textPtr);
	    }
	    return result;
	} else {
	    Tcl_AppendResult(interp, "Cannot trim outside of block",
			              NULL);
	    return TCL_ERROR;
	}
    } else if ((c == 'a') && (strncmp(LangString(args[2]), "at", length) == 0)
	       && (length >= 2)) {
        TkTextSegment *segPtr;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block at index\"",
		             NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	    return TCL_ERROR;
	}
	segPtr = TkIBTreeAt(&index1, 0);
	if (segPtr) {
	  ListFactory listFactory;

	  ListFactoryInit(&listFactory);
	  TkIBTreeInfo(segPtr, &listFactory);
	  ListFactoryResult(textPtr->interp, &listFactory);
	  ListFactoryFree(&listFactory);
	}
    } else if ((c == 'a') && (strncmp(LangString(args[2]), "addline", length) == 0)
	       && (length >= 2)) {
        struct DLine **dlPtrs;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block addline index\"",
		             NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	    return TCL_ERROR;
	}
	dlPtrs = (struct DLine **) ckalloc(sizeof(struct DLine*) * (textPtr->numDLines + 1));
	i = 0;
	if (textPtr->dlinePtrs) {
	  for (i = 0; i < textPtr->numDLines; i++) {
	    dlPtrs[i] = textPtr->dlinePtrs[i];
	  }
	  ckfree((char*)textPtr->dlinePtrs);
	} 
	textPtr->dlinePtrs = dlPtrs;
	textPtr->dlinePtrs[textPtr->numDLines++] 
	  = TkTextGetDLine(textPtr, &index1);
	Tcl_SetObjResult(interp, Tcl_NewIntObj(textPtr->numDLines));
	TkTextRelayoutWindow(textPtr);
    } else if ((c == 'o') && (strncmp(LangString(args[2]), "of", length) == 0)) {
        TkTextSegment *segPtr;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block of index\"",
		             NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	    return TCL_ERROR;
	}
	segPtr = TkIBTreeAt(&index1, 1);
	if (segPtr) {
	  ListFactory listFactory;

	  ListFactoryInit(&listFactory);
	  TkIBTreeInfo(segPtr, &listFactory);
	  ListFactoryResult(textPtr->interp, &listFactory);
	  ListFactoryFree(&listFactory);
	}
    } else if ((c == 'd') && (strncmp(LangString(args[2]), "delete", length) == 0)
	       && (length == 6)) {
        int result = TCL_OK;

	for (i = 3; i < argc; i++) {
	    hPtr = Tcl_FindHashEntry(&textPtr->blockTable, LangString(args[i]));
	    if (hPtr != NULL) {
		blockPtr = (TkTextBlock *) Tcl_GetHashValue(hPtr);
		if (blockPtr->count) {
		  Tcl_AppendResult(interp, "Cannot delete block \"", LangString(args[i]), 
				   "\" that is in use",
				            NULL);
		  result = TCL_ERROR;
		  continue;
		}
		Tcl_DeleteHashEntry(hPtr);
		DeleteBlock(textPtr, blockPtr);
	    } else {
		  Tcl_AppendResult(interp, "Unknown block \"", LangString(args[i]), 
				   "\"",
				            NULL);
		  result = TCL_ERROR;
	    }
	}
	return result;
    } else if ((c == 'd') && (strncmp(LangString(args[2]), "deletelines", length) == 0)
	       && (length > 6)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block deletelines\"",
		             NULL);
	    return TCL_ERROR;
	}
        if (textPtr->dlinePtrs) {
	  int i;

	  for (i = 0; i < textPtr->numDLines; i++) {
	    TkTextFreeDLine(textPtr, textPtr->dlinePtrs[i]);
	  }
	  ckfree((char*)textPtr->dlinePtrs);
	  textPtr->numDLines = 0;
	  textPtr->dlinePtrs = NULL;
	  TkTextRelayoutWindow(textPtr);
	}
    } else if ((c == 'i') && (strncmp(LangString(args[2]), "insert", length) ==
			      0)) {
        int lineIndex, numLines;

	if ((argc < 5) || (argc > 6)) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block insert blockName position ?position?",
		             NULL);
	    return TCL_ERROR;
	}
        if ((TkTextGetIndex(interp, textPtr, LangString(args[4]), &index1) != TCL_OK)
	    || (argc >= 6 
		&& TkTextGetIndex(interp, textPtr, LangString(args[5]), &index2)
		!= TCL_OK)) {
	  return TCL_ERROR;
	}
	lineIndex = TkBTreeLineIndex(index1.linePtr);
	if (lineIndex == (numLines = TkBTreeNumLines(textPtr->tree))) {
	    lineIndex--;
	    TkTextMakeByteIndex(textPtr->tree, lineIndex, 1000000, &index1);
	}
	if (argc < 6) {
	    index2 = index1;
	} else {
	        lineIndex = TkBTreeLineIndex(index2.linePtr);
		if (lineIndex == numLines) {
		    lineIndex--;
		    TkTextMakeByteIndex(textPtr->tree, lineIndex, 1000000, &index2);
		}
	}

	if (TkTextIndexCmp(&index1, &index2) > 0) {
	    Tcl_AppendResult(interp, "block insert: index \"",
		    LangString(args[5]), "\" is before \"",
		    LangString(args[4]), "\"", NULL);
	    return TCL_ERROR;
	}
	hPtr = Tcl_FindHashEntry(&textPtr->blockTable, LangString(args[3]));
	if (hPtr == NULL) {
	    Tcl_AppendResult(interp, "there is no block named \"",
		    LangString(args[3]), "\"",          NULL);
	    return TCL_ERROR;
	}
	blockPtr = (TkTextBlock *) Tcl_GetHashValue(hPtr);
	if (blockPtr->empty && ((index1.linePtr != index2.linePtr) 
				|| (index1.byteIndex != index2.byteIndex))) {
	    Tcl_AppendResult(interp, "Attempt to create empty block \"",
		    LangString(args[3]), "\" with contents",          NULL);
	    return TCL_ERROR;
	}
	{
	    TkTextValue *captured = NULL;
	    CaptureState cs;
	    int result, topLine, topOffset, *levels = NULL, numLevels = 0;
	    int *defects = NULL, numDefects = 0;
	    char i1[TK_POS_CHARS], i2[TK_POS_CHARS];

	    /*
	     * Recorded for undo (TK_TEXT_UNDO_BLOCK) with the range as
	     * given; the values it drops (merge losers, emptied nodes) go
	     * to the atom with their addresses before the change, and,
	     * inside a block, the levels of the separators it flattens.
	     */

	    TkTextPrintIndex(&index1, i1);
	    TkTextPrintIndex(&index2, i2);
	    TkBTreeVcPredictBlock(textPtr, &index1, &index2, textPtr->undo
		    ? TK_TEXT_VC_STASH : TK_TEXT_VC_DROP);
	    if (!blockPtr->empty) {
		TkBTreeVcNewBlock(textPtr, &index1, &index2);
	    }
	    if (textPtr->undo) {
		levels = TkIBTreeSeparatorLevels(&index1, &index2,
			&numLevels);
		defects = TkIBTreeLeafDefects(&index1, &index2, &numDefects);
		CaptureStart(textPtr, &cs, &captured, &index1, &index2);
	    }
	    TkTextChanged(textPtr, &index1, &index2);

	    /*
	     *  Invalidate any selection retrievals in progress.
	     */

	    textPtr->selOffset = -1;

	    topLine = KeepViewForBlock(textPtr, &index1, &index2, &topOffset);
	    result = TkBTreeMakeBlock(textPtr, &index1, &index2, blockPtr);
	    if (topLine >= 0) {
		ResetViewForBlock(textPtr, topLine, topOffset);
	    }
	    if (textPtr->undo) {
		CaptureEnd(textPtr, &cs);
		if (result == TCL_OK) {
		    TkTextUndoAtom *atomPtr = PushEdit(textPtr,
			    TK_TEXT_EDIT_BLOCK, TK_TEXT_UNDO_BLOCK, i1, i2,
			    Tcl_NewStringObj(blockPtr->name, -1));

		    atomPtr->values = captured;
		    atomPtr->levels = levels;
		    atomPtr->numLevels = numLevels;
		    atomPtr->defects = defects;
		    atomPtr->numDefects = numDefects;
		} else {
		    TkTextFreeValueList(textPtr, captured);
		    if (levels != NULL) {
			ckfree((char *) levels);
		    }
		    if (defects != NULL) {
			ckfree((char *) defects);
		    }
		}
	    }
	    if (result == TCL_OK) {
		UpdateDirtyFlag(textPtr);
	    }
	    return result;
	}
    } else if ((c == 'n') && (strncmp(LangString(args[2]), "nodedata", length) == 0)
	    && (length >= 2)) {
	TkTextData *dataPtr;

	if ((argc != 5) && (argc != 6)) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block nodedata index level ?value?\"",
		    NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (TkBTreeNodeValue(textPtr, &index1, LangString(args[3]), args[4],
		&dataPtr) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (argc == 5) {
	    Arg copy = TkTextDataCopyLang(*dataPtr);

	    if (copy != NULL) {
		Tcl_SetObjResult(interp, copy);
	    }
	} else {
	    if (TkTextVcOn(textPtr)
		    && (TkTextDataGetLang(*dataPtr) != NULL)) {
		TkTextVcPredict(textPtr, *dataPtr, TK_TEXT_VC_DROP,
			TK_TEXT_VC_NODE,
			TkBTreeVcNodePlace(textPtr, &index1, args[4]), NULL);
		TkTextVcNotify(textPtr);
	    }
	    TkBTreeSetValue(textPtr, dataPtr, args[5]);
	}
    } else if ((c == 'n') && (strncmp(LangString(args[2]), "names", length) == 0)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block names\"",          NULL);
	    return TCL_ERROR;
	}
	for (hPtr = Tcl_FirstHashEntry(&textPtr->blockTable, &search);
		hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	    Tcl_AppendElement(interp,
		    Tcl_GetHashKey(&textPtr->blockTable, hPtr));
	}
    } else if ((c == 'l') && (strncmp(LangString(args[2]), "list", length) == 0)) {
        ListFactory listFactory;
	TkTextLine *linePtr;
	int offset;
	Arg arg = NULL;

	if (argc != 5) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block list index1 index2\"",          NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK
	    || TkTextGetIndex(interp, textPtr, LangString(args[4]), &index2) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (TkTextIndexCmp(&index1, &index2) >= 0) {
	    return TCL_OK;
	}
	linePtr = index1.linePtr;
	offset = index1.byteIndex; 
	ListFactoryInit(&listFactory);
	LangSetString(&arg, "");
	while (linePtr != index2.linePtr) {
	  TkBTreeLineTextAppend(textPtr, linePtr, offset, -1, 
				(void*)&listFactory, TkTextUserGetFlags(textPtr)
				| TKT_GET_LIST, NULL);
	  offset = -1;			/* Report all of the rest */
	  ListFactoryAppendCopyWithType(&listFactory, arg, 
					IdType("NL",
					       "Tk::Text::NewLine"));
	  linePtr = TkBTreeNextLine(linePtr);
	}
	TkBTreeLineTextAppend(textPtr, linePtr, offset, index2.byteIndex,
			      (void*)&listFactory, TkTextUserGetFlags(textPtr)
			      | TKT_GET_LIST, NULL);
	ListFactoryResult(textPtr->interp, &listFactory);
	ListFactoryFree(&listFactory);
	LangFreeArg(arg, LANG_DYNAMIC);
    } else if ((c == 'f')
	    && (strncmp(LangString(args[2]), "flatten", length) == 0)) {
	void *nodePtr;
	int joined = 0;

	if (argc != 5) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block flatten index level\"", NULL);
	    return TCL_ERROR;
	}
	if ((TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1)
		!= TCL_OK)
		|| (TkIBTreeFlattenTarget(textPtr, &index1, LangString(args[3]),
			args[4], &nodePtr) != TCL_OK)) {
	    return TCL_ERROR;
	}
	if (nodePtr != NULL) {
	    joined = Flatten(textPtr, nodePtr);
	    UpdateDirtyFlag(textPtr);
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(joined));
    } else if ((c == 's') && (length >= 3)
	    && (strncmp(LangString(args[2]), "sprout", length) == 0)) {
	int startMade, endMade, raised, rootWrapped, oneIndex = (argc == 4);
	char i1[TK_POS_CHARS], i2[TK_POS_CHARS];

	if ((argc != 4) && (argc != 5)) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block sprout index1 ?index2?\"",
		    NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1)
		!= TCL_OK) {
	    return TCL_ERROR;
	}
	if (oneIndex) {
	    /*
	     * One index (decision O8): the WRAP of the leaf it names, as
	     * the range from the delimiter before the leaf to just after
	     * the one after it (which, for the only leaf of a block, the
	     * two-index form cannot name).
	     */

	    index2 = index1;
	    if (TkIBTreeSproutLeaf(textPtr, &index2, &index1, &index2)
		    != TCL_OK) {
		return TCL_ERROR;
	    }
	    startMade = endMade = 0;
	} else if ((TkTextGetIndex(interp, textPtr, LangString(args[4]),
		&index2) != TCL_OK)
		|| (TkIBTreeSproutRange(textPtr, &index1, &index2, &startMade,
			&endMade) != TCL_OK)) {
	    return TCL_ERROR;
	}
	TkTextPrintIndex(&index1, i1);
	TkTextPrintIndex(&index2, i2);
	TkBTreeVcNewSprout(textPtr, &index1, &index2, startMade, endMade);
	Sprout(textPtr, i1, i2, startMade, endMade, 1, &raised, &rootWrapped);

	/*
	 * Recorded for undo (TK_TEXT_UNDO_SPROUT): the range as given,
	 * the pieces made, whether the tree was made higher, whether the
	 * block was a single leaf.  It drops no values.
	 */

	if (textPtr->undo) {
	    TkTextUndoAtom *atomPtr = PushEdit(textPtr, TK_TEXT_EDIT_SPROUT,
		    TK_TEXT_UNDO_SPROUT, i1, i2, (Tcl_Obj *) NULL);

	    atomPtr->level = startMade + 2 * endMade + 4 * rootWrapped
		    + 8 * oneIndex;
	    atomPtr->added = raised;
	}
	UpdateDirtyFlag(textPtr);
	Tcl_SetObjResult(interp, Tcl_NewIntObj(startMade + endMade));
    } else if ((c == 's') && (strncmp(LangString(args[2]), "split", length) == 0)) {
        int level = 0;

	if (argc != 4 && argc != 5) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " block split index ?level?\"",          NULL);
	    return TCL_ERROR;
	}
        if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index1) != TCL_OK) {
	  return TCL_ERROR;
	}
	if (argc == 5) {
	  level = LangInt(args[4]);
	}
	{
	    char i1[TK_POS_CHARS], i2[TK_POS_CHARS];
	    int asked = level;

	    NotOnDummyLine(textPtr, &index1);
	    TkTextPrintIndex(&index1, i1);
	    TkBTreeVcNewSplit(textPtr, &index1, level);
	    TkTextRootLogReset(textPtr);
	    level = SplitChars(textPtr, &index1, level);

	    /*
	     * Recorded for undo (TK_TEXT_UNDO_SPLIT): the separator at i1,
	     * the level asked for, the levels added above the root.  It
	     * drops no values (new nodes start without one).
	     */

	    if (textPtr->undo
		    && (TkTextGetIndex(interp, textPtr, i1, &index1) == TCL_OK)) {
		TkTextUndoAtom *atomPtr;

		TkTextIndexForwChars(&index1, 1, &index2);
		TkTextPrintIndex(&index2, i2);
		atomPtr = PushEdit(textPtr, TK_TEXT_EDIT_SPLIT,
			TK_TEXT_UNDO_SPLIT, i1, i2, (Tcl_Obj *) NULL);
		atomPtr->level = asked;
		atomPtr->added = (level > 0) ? level : 0;
		atomPtr->roots = TkTextRootLogTake(textPtr);
	    }
	    UpdateDirtyFlag(textPtr);
	}
	Tcl_SetObjResult(interp, Tcl_NewIntObj(level));
    } else {
	Tcl_AppendResult(interp, "bad block option \"", LangString(args[2]),
		"\":  must be at, addline, cget, configure, data, delete, ",
		"deletelines, flatten, insert, list, names, nodedata, of, ",
		"split, sprout or trim",
		         NULL);
	return TCL_ERROR;
    }
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * DeleteBlock --
 *
 *	Deletes the given block type. No error checking is done.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Memory is freed.
 *
 *--------------------------------------------------------------
 */

static void
DeleteBlock(textPtr, blockPtr)
    TkText *textPtr;			/* Text widget that contains
					 * the block. */
    TkTextBlock *blockPtr;		/* Block to delete. */
{
  Tk_FreeOptions(blockConfigSpecs, (char *) blockPtr, textPtr->display, 0);
  TkTextOrnTemplatesRelease(textPtr, blockPtr->ornTemplates);
  if (blockPtr->widthsMin) {
    ckfree((char*)blockPtr->widthsMin);
  }
  if (blockPtr->widthsMax) {
    ckfree((char*)blockPtr->widthsMax);
  }
  ckfree((char*)blockPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextGetTabs --
 *
 *	Parses a string description of a set of tab stops.
 *
 * Results:
 *	The return value is a pointer to a malloc'ed structure holding
 *	parsed information about the tab stops.  If an error occurred
 *	then the return value is NULL and an error message is left in
 *	Tcl_GetResult(interp).
 *
 * Side effects:
 *	Memory is allocated for the structure that is returned.  It is
 *	up to the caller to free this structure when it is no longer
 *	needed.
 *
 *----------------------------------------------------------------------
 */

TkTextTabArray *
TkTextGetTabs(interp, tkwin, arg)
    Tcl_Interp *interp;			/* Used for error reporting. */
    Tk_Window tkwin;			/* Window in which the tabs will be
					 * used. */
    Arg arg;				/* Description of the tab stops.  See
					 * the text manual entry for details. */
{
    int argc, i, count, c;
    Arg *args;
    TkTextTabArray *tabArrayPtr;
    TkTextTab *tabPtr;
     LangFreeProc *freeProc = NULL;

    if (Lang_SplitList(interp, arg, &argc, &args, &freeProc) != TCL_OK) {
	return NULL;
    }

    /*
     * First find out how many entries we need to allocate in the
     * tab array.
     */

    count = 0;
    for (i = 0; i < argc; i++) {
	c = LangString(args[i])[0];
	if ((c != 'l') && (c != 'r') && (c != 'c') && (c != 'n')) {
	    count++;
	}
    }

    /*
     * Parse the elements of the list one at a time to fill in the
     * array.
     */

    tabArrayPtr = (TkTextTabArray *) ckalloc((unsigned)
	    (sizeof(TkTextTabArray) + (count-1)*sizeof(TkTextTab)));
    tabArrayPtr->numTabs = 0;
    for (i = 0, tabPtr = &tabArrayPtr->tabs[0]; i  < argc; i++, tabPtr++) {
	if (Tk_GetPixels(interp, tkwin, LangString(args[i]), &tabPtr->location)
		!= TCL_OK) {
	    goto error;
	}
	tabArrayPtr->numTabs++;

	/*
	 * See if there is an explicit alignment in the next list
	 * element.  Otherwise just use "left".
	 */

	tabPtr->alignment = LEFT;
	if ((i+1) == argc) {
	    continue;
	}
	c = UCHAR(LangString(args[i+1])[0]);
	if (!isalpha(c)) {
	    continue;
	}
	i += 1;
	if ((c == 'l') && (strncmp(LangString(args[i]), "left",
		strlen(LangString(args[i]))) == 0)) {
	    tabPtr->alignment = LEFT;
	} else if ((c == 'r') && (strncmp(LangString(args[i]), "right",
		strlen(LangString(args[i]))) == 0)) {
	    tabPtr->alignment = RIGHT;
	} else if ((c == 'c') && (strncmp(LangString(args[i]), "center",
		strlen(LangString(args[i]))) == 0)) {
	    tabPtr->alignment = CENTER;
	} else if ((c == 'n') && (strncmp(LangString(args[i]),
		"numeric", strlen(LangString(args[i]))) == 0)) {
	    tabPtr->alignment = NUMERIC;
	} else {
	    Tcl_AppendResult(interp, "bad tab alignment \"",
		    LangString(args[i]), "\": must be left, right, center, or numeric",
		             NULL);
	    goto error;
	}
    }
    if (freeProc)
      (*freeProc)(argc,args);
    return tabArrayPtr;

    error:
    ckfree((char *) tabArrayPtr);
    if (freeProc)
      (*freeProc)(argc,args);
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * TextDumpCmd --
 *
 *	Return information about the text, tags, marks, and embedded windows
 *	in a text widget.  See the man page for the description of the
 *	text dump operation for all the details.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	Memory is allocated for the result, if needed (standard Tcl result
 *	side effects).
 *
 *----------------------------------------------------------------------
 */

static int
TextDumpCmd(textPtr, interp, argc, args)
    register TkText *textPtr;	/* Information about text widget. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    Arg *args;		/* Argument strings.  Someone else has already
				 * parsed this command enough to know that
				 * LangString(args[1]) is "dump". */
{
    TkTextIndex index1, index2;
    int arg;
    int what = 0;		/* bitfield to select segment types */
    int atEnd;			/* True if dumping up to logical end */
    TkTextLine *linePtr;
    LangCallback *command = NULL;	/* Script callback to apply to segments */
#define TK_DUMP_TEXT	0x1
#define TK_DUMP_MARK	0x2
#define TK_DUMP_TAG	0x4
#define TK_DUMP_WIN	0x8
#define TK_DUMP_IMG	0x10
#define TK_DUMP_BLOCK	0x20
#define TK_DUMP_ALL	(TK_DUMP_TEXT|TK_DUMP_MARK|TK_DUMP_TAG|TK_DUMP_WIN|TK_DUMP_IMG|TK_DUMP_BLOCK)
#define TK_DUMP_VALUES	0x40	/* -values: a fourth field, the value of a
				 * mark or of the run a tagon starts (see
				 * DumpSegment); not part of -all. */

    for (arg = 2; arg < argc; arg++) {
	size_t len;
	if (LangString(args[arg])[0] != '-') {
	    break;
	}
	len = strlen(LangString(args[arg]));
	if (strncmp("-all", LangString(args[arg]), len) == 0) {
	    what = TK_DUMP_ALL;
	} else if (strncmp("-text", LangString(args[arg]), len) == 0) {
	    what |= TK_DUMP_TEXT;
	} else if (strncmp("-tag", LangString(args[arg]), len) == 0) {
	    what |= TK_DUMP_TAG;
	} else if (strncmp("-mark", LangString(args[arg]), len) == 0) {
	    what |= TK_DUMP_MARK;
	} else if (strncmp("-window", LangString(args[arg]), len) == 0) {
	    what |= TK_DUMP_WIN;
	} else if (strncmp("-image", LangString(args[arg]), len) == 0) {
	    what |= TK_DUMP_IMG;
	} else if (strncmp("-block", LangString(args[arg]), len) == 0) {
	    what |= TK_DUMP_BLOCK;
	} else if ((len >= 2)
		&& (strncmp("-values", LangString(args[arg]), len) == 0)) {
	    what |= TK_DUMP_VALUES;
	} else if (strncmp("-command", LangString(args[arg]), len) == 0) {
	    arg++;
	    if (arg >= argc || command != (LangCallback *) NULL) {
		Tcl_AppendResult(interp, "Usage: ", LangString(args[0]), " dump ?-all -text -mark -tag -window -image -block -values? ?-command script? index ?index2?", NULL);
		goto error;
	    }
	    command = LangMakeCallback(args[arg]);
	} else {
	    Tcl_AppendResult(interp, "Usage: ", LangString(args[0]), " dump ?-all -text -mark -tag -window -image -block -values? ?-command script? index ?index2?", NULL);
	    goto error;
	}
    }
    if (arg >= argc) {
	Tcl_AppendResult(interp, "Usage: ", LangString(args[0]), " dump ?-all -text -mark -tag -window -image -block -values? ?-command script? index ?index2?", NULL);
	goto error;
    }
    if ((what & ~TK_DUMP_VALUES) == 0) {
	what |= TK_DUMP_ALL;
    }
    if (TkTextGetIndex(interp, textPtr, LangString(args[arg]), &index1) != TCL_OK) {
	goto error;
    }
    arg++;
    atEnd = 0;
    if (argc == arg) {
	TkTextIndexForwChars(&index1, 1, &index2);
    } else {
	if (TkTextGetIndex(interp, textPtr, LangString(args[arg]), &index2) != TCL_OK) {
	    goto error;
	}
	if (strncmp(LangString(args[arg]), "end", strlen(LangString(args[arg]))) == 0) {
	    atEnd = 1;
	}
    }
    if (TkTextIndexCmp(&index1, &index2) >= 0) {
	goto ok;
    }
    if (index1.linePtr == index2.linePtr) {
	DumpLine(interp, textPtr, what, index1.linePtr, index1.linePtr, 0,
		index1.byteIndex, index2.byteIndex, command);
    } else {
	DumpLine(interp, textPtr, what, index1.linePtr, index1.linePtr, 0,
		index1.byteIndex, 32000000, command);
	linePtr = index1.linePtr;
	while ((linePtr = TkBTreeNextLine(linePtr)) != (TkTextLine *)NULL) {
	    if (linePtr == index2.linePtr) {
		break;
	    }
	    DumpLine(interp, textPtr, what, linePtr, linePtr, 0, 0, 32000000,
		    command);
	}
	DumpLine(interp, textPtr, what, index2.linePtr, index2.linePtr, 0, 0,
		index2.byteIndex, command);
    }
    /*
     * Special case to get the leftovers hiding at the end mark.
     */
    if (atEnd) {
	DumpLine(interp, textPtr, what & ~TK_DUMP_TEXT, index2.linePtr,
		index2.linePtr, 0, 0, 1, command);
    }
ok:
    if (command != (LangCallback *) NULL)
	LangFreeCallback(command);
    return TCL_OK;
error:
    if (command != (LangCallback *) NULL)
	LangFreeCallback(command);
    return TCL_ERROR;
}

/*
 * DumpLine
 * 	Return information about a given text line from character
 *	position "start" up to, but not including, "end".  Blocks are
 *	entered: their internal lines are dumped in turn, with external
 *	indices, between a "block" and a "blockend" element (if asked
 *	for with -block).
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	None, but see DumpSegment.
 */
static void
DumpLine(interp, textPtr, what, linePtr, extLinePtr, base, start, end, command)
    Tcl_Interp *interp;
    TkText *textPtr;
    int what;			/* bit flags to select segment types */
    TkTextLine *linePtr;	/* The line whose segments are dumped (may
				 * be an internal line of a block) */
    TkTextLine *extLinePtr;	/* The outermost line containing it, for
				 * the indices */
    int base;			/* External offset of the start of linePtr */
    int start, end;		/* Range to dump, as offsets in linePtr */
    LangCallback *command;	/* Script to apply to the segment */
{
    int offset;
    TkTextSegment *segPtr;
    TkTextIndex index;

    index.tree = textPtr->tree;
    index.linePtr = extLinePtr;
    /*
     * Must loop through line looking at its segments.
     * character
     * toggleOn, toggleOff
     * mark
     * window, image
     * block
     */
    for (offset = 0, segPtr = linePtr->segPtr ;
	    (offset < end) && (segPtr != (TkTextSegment *)NULL) ;
	    offset += segPtr->size, segPtr = segPtr->nextPtr) {

	index.byteIndex = base + offset;
	if ((what & TK_DUMP_TEXT) && (segPtr->typePtr == &tkTextCharType) &&
		(offset + segPtr->size > start)) {
	    char savedChar;			/* Last char used in the seg */
	    int last = segPtr->size;		/* Index of savedChar */
	    int first = 0;			/* Index of first char in seg */
	    if (offset + segPtr->size > end) {
		last = end - offset;
	    }
	    if (start > offset) {
		first = start - offset;
	    }
	    savedChar = segPtr->body.chars[last];
	    segPtr->body.chars[last] = '\0';
	    index.byteIndex = base + offset + first;
	    DumpSegment(interp, "text", segPtr->body.chars + first,
		    command, &index, what, (Arg) NULL);
	    segPtr->body.chars[last] = savedChar;
	} else if ((segPtr->typePtr == &tkTextIBTreeType)
		&& (offset + segPtr->size > start)) {
	    TkTextLine *innerPtr;
	    int ioff, len, s, e;
	    char *name = segPtr->body.itree.blockPtr->name;

	    if ((what & TK_DUMP_BLOCK) && (offset >= start)) {
		DumpSegment(interp, "block", name, command, &index,
			what, (Arg) NULL);
	    }

	    /*
	     * The internal lines follow the dummy position of the block;
	     * the last internal line is a dummy outside the index space.
	     */

	    ioff = 1;
	    if (segPtr->body.itree.tree != NULL) {
		for (innerPtr = TkIBTreeFirstLine(segPtr);
			(innerPtr != NULL) && (ioff < segPtr->size);
			innerPtr = TkBTreeNextLine(innerPtr)) {
		    len = TkBTreeCharsInLine(innerPtr);
		    s = start - (offset + ioff);
		    e = end - (offset + ioff);
		    if (s < 0) {
			s = 0;
		    }
		    if (e > len) {
			e = len;
		    }
		    if (s < e) {
			DumpLine(interp, textPtr, what, innerPtr, extLinePtr,
				base + offset + ioff, s, e, command);
		    }
		    ioff += len;
		}
	    }
	    if ((what & TK_DUMP_BLOCK) && (offset + segPtr->size <= end)) {
		index.byteIndex = base + offset + segPtr->size;
		DumpSegment(interp, "blockend", name, command,
			&index, what, (Arg) NULL);
	    }
	} else if ((offset >= start)) {
	    if ((what & TK_DUMP_MARK) && (segPtr->typePtr->name[0] == 'm')
		    && !TkTextIsPrivateMark(textPtr, segPtr)) {
		TkTextMark *markPtr = (TkTextMark *)&segPtr->body;
		char *name = Tcl_GetHashKey(&textPtr->markTable, markPtr->hPtr);
		DumpSegment(interp, "mark", name,
			command, &index, what,
			TkTextDataGetLang(markPtr->value));
	    } else if ((what & TK_DUMP_TAG) &&
			(segPtr->typePtr == &tkTextToggleOnType)) {
		DumpSegment(interp, "tagon",
			segPtr->body.toggle.tagPtr->name,
			command, &index, what,
			TkTextDataGetLang(segPtr->body.toggle.value));
	    } else if ((what & TK_DUMP_TAG) && 
			(segPtr->typePtr == &tkTextToggleOffType)) {
		DumpSegment(interp, "tagoff",
			segPtr->body.toggle.tagPtr->name,
			command, &index, what, (Arg) NULL);
	    } else if ((what & TK_DUMP_WIN) && 
			(segPtr->typePtr->name[0] == 'w')) {
		TkTextEmbWindow *ewPtr = (TkTextEmbWindow *)&segPtr->body;
		char *pathname;
		if (ewPtr->tkwin == (Tk_Window) NULL) {
		    pathname = "";
		} else {
		    pathname = Tk_PathName(ewPtr->tkwin);
		}
		DumpSegment(interp, "window", pathname,
			command, &index, what, (Arg) NULL);
	    } else if ((what & TK_DUMP_IMG) &&
			(strcmp(segPtr->typePtr->name, "image") == 0)) {
		TkTextEmbImage *eiPtr = (TkTextEmbImage *)&segPtr->body;
		char *name = (eiPtr->name == NULL) ? "" : eiPtr->name;
		DumpSegment(interp, "image", name,
			command, &index, what, (Arg) NULL);
	    }
	}
    }
}

/*
 * DumpSegment
 *	Either append information about the current segment to the result,
 *	or make a script callback with that information as arguments.
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Either evals the callback or appends elements to the result string.
 */
static int
DumpSegment(interp, key, value, command, indexPtr, what, data)
    Tcl_Interp *interp;
    char *key;			/* Segment type key */
    char *value;		/* Segment value */
    LangCallback *command;	/* Script callback */
    TkTextIndex *indexPtr;	/* Position of the segment */
    int what;			/* Look for the TK_DUMP_VALUES bit */
    Arg data;			/* With -values: the value of the mark or of
				 * the run (NULL if none, and for the other
				 * kinds of entries). */
{
    char buffer[TK_POS_CHARS];

    TkTextPrintIndex(indexPtr, buffer);
    if (command == (LangCallback *) NULL) {
	Tcl_AppendElement(interp, key);
	Tcl_AppendElement(interp, value);
	Tcl_AppendElement(interp, buffer);
	if (what & TK_DUMP_VALUES) {
	    /*
	     * Every entry has a fourth field, so that the list stays a
	     * list of entries of one length: a copy of the value, or
	     * undef (an empty string in Tcl).
	     */

	    Tcl_ListObjAppendElement(interp, Tcl_GetObjResult(interp),
		    (data != NULL) ? (Tcl_Obj *) newSVsv((SV *) data)
		    : (Tcl_Obj *) newSV(0));
	}
	return TCL_OK;
    } else if (what & TK_DUMP_VALUES) {
	return LangDoCallback(interp, command, 1, 4, "%s %s %s %_", key,
		value, buffer, (SV *) data);
    } else {
	return LangDoCallback(interp, command, 1, 3, "%s %s %s", key, value,
		buffer);
    }
}


/*
 *----------------------------------------------------------------------
 *
 * TextGetText --
 *
 *	Collect the text between two indices into a DString, in the
 *	form that "get" reports it (so that blocks become their textual
 *	representation).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The DString is initialized and filled; the caller frees it.
 *
 *----------------------------------------------------------------------
 */

static void
TextGetText(textPtr, index1Ptr, index2Ptr, dsPtr)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *index1Ptr;	/* Start of the range. */
    TkTextIndex *index2Ptr;	/* End of the range (not included). */
    Tcl_DString *dsPtr;		/* Where to put the text. */
{
    TkTextLine *linePtr = index1Ptr->linePtr;
    int offset = index1Ptr->byteIndex;
    int flags = TkTextUserGetFlags(textPtr) | TKT_GET_DSTRING;

    Tcl_DStringInit(dsPtr);
    if (TkTextIndexCmp(index1Ptr, index2Ptr) >= 0) {
	return;
    }
    while (linePtr != index2Ptr->linePtr) {
	TkBTreeLineTextAppend(textPtr, linePtr, offset, -1, (void *) dsPtr,
		flags, NULL);
	offset = -1;
	linePtr = TkBTreeNextLine(linePtr);
    }
    TkBTreeLineTextAppend(textPtr, linePtr, offset, index2Ptr->byteIndex,
	    (void *) dsPtr, flags, NULL);
}

/*
 *----------------------------------------------------------------------
 *
 * GenerateModifiedEvent, UpdateDirtyFlag --
 *
 *	Keep the modified flag ("edit modified") up to date, and tell the
 *	application through the <<Modified>> virtual event when it
 *	changes between clean and dirty.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Bindings of <<Modified>> may run.
 *
 *----------------------------------------------------------------------
 */

static void
GenerateModifiedEvent(textPtr)
    TkText *textPtr;		/* Information about text widget. */
{
    XEvent event;

    if (textPtr->tkwin == NULL) {
	return;
    }
    memset((VOID *) &event, 0, sizeof(event));
    event.xany.type = VirtualEvent;
    event.xany.serial = NextRequest(Tk_Display(textPtr->tkwin));
    event.xany.send_event = False;
    event.xany.window = Tk_WindowId(textPtr->tkwin);
    event.xany.display = Tk_Display(textPtr->tkwin);
    ((XVirtualEvent *) &event)->name = Tk_GetUid("Modified");
    Tk_HandleEvent(&event);
}

static void
UpdateDirtyFlag(textPtr)
    TkText *textPtr;		/* Information about text widget. */
{
    int oldDirtyFlag;

    if (textPtr->modifiedSet || (textPtr->isDirtyIncrement == 0)) {
	return;
    }
    oldDirtyFlag = textPtr->isDirty;
    textPtr->isDirty += textPtr->isDirtyIncrement;
    if ((textPtr->isDirty == 0) || (oldDirtyFlag == 0)) {
	GenerateModifiedEvent(textPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextEditAction --
 *
 *	Apply (redo) or revert (undo) one recorded change: an insertion
 *	or a deletion.  The insertion cursor goes to the end of the text
 *	put in, or to the place of the text taken out, and is made
 *	visible.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The text changes.  Nothing is recorded (the caller has switched
 *	recording off), but the modified flag is updated.
 *
 *----------------------------------------------------------------------
 */

void
TkTextEditAction(textPtr, atomPtr, revert)
    TkText *textPtr;		/* Information about text widget. */
    TkTextUndoAtom *atomPtr;	/* The change. */
    int revert;			/* Non-zero means undo it, zero means
				 * do it again. */
{
    Tcl_Interp *interp = textPtr->interp;
    TkTextIndex index;
    char *markIndex;
    int doInsert, increment, ok = 1;

    if (textPtr->state != tkTextNormalUid) {
	return;
    }
    if (atomPtr->type >= TK_TEXT_UNDO_SPLIT) {
	EditOther(textPtr, atomPtr, revert);
	return;
    }

    /*
     * The modified flag is updated once per atom, below, however many
     * insertions re-creating a structure takes.
     */

    increment = textPtr->isDirtyIncrement;
    textPtr->isDirtyIncrement = 0;
    doInsert = (atomPtr->type == TK_TEXT_UNDO_INSERT) ? !revert : revert;
    if (doInsert) {
	TkTextValue *remainsValues = NULL;
	TkTextRemainsMap map;

	map.atomPtr = atomPtr;
	map.starts = NULL;

	if (atomPtr->list != NULL) {
	    /*
	     * A deletion that cut blocks left their remains where the
	     * list goes back (see TkTextUndoAtom): take them out first,
	     * the list has everything.  The values that takes out of the
	     * remains (of blocks nested there) go back to the same nodes
	     * once the list is in (TkBTreeRestoreValues finds them
	     * there); a value set on the remains after the deletion finds
	     * no node there, and waits in the atom for the redo.
	     */

	    if ((atomPtr->remains > 0)
		    && (TkTextGetIndex(interp, textPtr, atomPtr->listIndex,
			    &index) == TCL_OK)) {
		TkTextIndex end;
		char endString[TK_POS_CHARS];

		TkTextIndexForwBytes(&index, atomPtr->remains, &end);
		TkTextPrintIndex(&end, endString);
		if (textPtr->haveValues) {
		    TkTextLine *linePtr = index.linePtr;
		    int k;

		    map.line = TkBTreeLineIndex(index.linePtr);
		    map.numLines = TkBTreeLineIndex(end.linePtr) - map.line;
		    map.starts = (int *) ckalloc((unsigned)
			    ((map.numLines + 1) * sizeof(int)));
		    map.starts[0] = -index.byteIndex;
		    for (k = 1; k <= map.numLines; k++) {
			map.starts[k] = map.starts[k - 1]
				+ TkBTreeCharsInLine(linePtr);
			linePtr = TkBTreeNextLine(linePtr);
		    }
		}
		remainsValues = TkBTreeTakeCrossingRunValues(textPtr, &index,
			&end);
		textPtr->editValues = &remainsValues;
		DeleteChars(textPtr, atomPtr->listIndex, endString);
		textPtr->editValues = NULL;
	    }
	    if (TkTextGetIndex(interp, textPtr, atomPtr->listIndex, &index)
		    != TCL_OK) {
		ok = 0;
	    } else {
		void *held = TkBTreeHoldRunValues(textPtr, &index);

		InsertList(textPtr, &index, atomPtr->list);
		TkBTreeReleaseRunValues(textPtr, held);
	    }
	} else if (TkTextGetIndex(interp, textPtr, atomPtr->index1, &index)
		!= TCL_OK) {
	    ok = 0;
	} else {
	    InsertChars(textPtr, &index, Tcl_GetString(atomPtr->string));
	}

	/*
	 * The text is back: so are the values the change dropped, at
	 * their addresses (the most recent change undone first).
	 */

	if (ok) {
	    /*
	     * A value found at an address (set there after the change)
	     * is displaced into the atom, to come back when the change
	     * is applied again.
	     */

	    TkTextDiscardValueList(textPtr, atomPtr->displaced);
	    atomPtr->displaced = NULL;
	    TkBTreeRestoreValues(textPtr, remainsValues,
		    (map.starts != NULL) ? &map : NULL, &atomPtr->displaced, 2);
	    TkBTreeRestoreValues(textPtr, atomPtr->values, NULL,
		    &atomPtr->displaced, 1);

	    /*
	     * The deletion made the leaves it joined equally deep first
	     * (WRAPs): now that the text, its structure and the values
	     * are back as they were after those, they are undone (PULL
	     * OUTs, in reverse order).
	     */

	    if (atomPtr->wraps != NULL) {
		WrapsChanged(textPtr, atomPtr->wraps);
		TkIBTreeUndoWraps(textPtr, atomPtr->wraps,
			&atomPtr->displaced);
	    }

	    /*
	     * Blocks that were single leaves before the deletion (whose
	     * roots the leaves of blocks dissolved in them made real) are
	     * single leaves again.
	     */

	    if (atomPtr->type == TK_TEXT_UNDO_DELETE) {
		TkIBTreeRepadRoots(textPtr, atomPtr->roots,
			&atomPtr->displaced);
	    }
	} else {
	    TkTextFreeValueList(textPtr, remainsValues);
	    TkTextDiscardValueList(textPtr, atomPtr->values);
	}
	atomPtr->values = NULL;
	if (map.starts != NULL) {
	    ckfree((char *) map.starts);
	}
	markIndex = atomPtr->index2;
    } else {
	/*
	 * Undoing an insertion: record what is there in block-list form,
	 * as a deletion records what it deletes, so that the redo puts it
	 * back exactly (tags, the separators of a block, marks, and, once
	 * the list is in, the values; see TkTextUndoAtom).  The range is
	 * exactly as the insertion left it: the later changes recorded
	 * have been undone before.  If it cuts blocks (indices made
	 * stale by changes not recorded) the redo inserts the string.
	 */

	if (atomPtr->type == TK_TEXT_UNDO_INSERT) {
	    TkTextIndex i1, i2, ext1, ext2;
	    int remains;

	    if (atomPtr->list != NULL) {
		Tcl_DecrRefCount(atomPtr->list);
		atomPtr->list = NULL;
	    }
	    if (atomPtr->wraps != NULL) {
		ckfree((char *) atomPtr->wraps);
		atomPtr->wraps = NULL;
	    }
	    if ((TkTextGetIndex(interp, textPtr, atomPtr->index1, &i1)
		    == TCL_OK)
		    && (TkTextGetIndex(interp, textPtr, atomPtr->index2, &i2)
			== TCL_OK)
		    && (TkTextIndexCmp(&i1, &i2) < 0)
		    && (TkIBTreeCutRange(&i1, &i2, &ext1, &ext2, &remains)
			== 0)) {
		/*
		 * The deletion's WRAPs first (if the leaves it joins are
		 * not equally deep), so that the list is taken from the
		 * tree the redo restores before pulling them out.
		 */

		atomPtr->wraps = TkBTreeEqualizeDelete(textPtr, &i1, &i2);
		atomPtr->list = TextGetList(textPtr, &i1, &i2);
	    }
	    Tcl_ResetResult(interp);
	    strcpy(atomPtr->listIndex, atomPtr->index1);
	    atomPtr->remains = 0;
	}

	/*
	 * The values this deletion drops go to the atom.
	 */

	TkTextDiscardValueList(textPtr, atomPtr->values);
	atomPtr->values = NULL;
	textPtr->editValues = &atomPtr->values;
	if (atomPtr->type == TK_TEXT_UNDO_DELETE) {
	    textPtr->editAtom = atomPtr;	/* Its WRAPs, done again. */
	}
	if (DeleteChars(textPtr, atomPtr->index1, atomPtr->index2) != TCL_OK) {
	    ok = 0;
	}
	textPtr->editValues = NULL;
	textPtr->editAtom = NULL;

	/*
	 * The values the last undo (or redo) displaced come back; what
	 * they find at their addresses goes to the atom, as values this
	 * change drops (their addresses are before the change, so the
	 * same in the text with and without it).
	 */

	if (ok) {
	    TkTextValue *displaced = atomPtr->displaced;

	    atomPtr->displaced = NULL;
	    TkBTreeRestoreValues(textPtr, displaced, NULL, &atomPtr->values,
		    1);

	    /*
	     * The undo of an insertion whose newline made the root of a
	     * block that was a single leaf real: padding again.
	     */

	    if (atomPtr->type == TK_TEXT_UNDO_INSERT) {
		TkIBTreeRepadRoots(textPtr, atomPtr->roots, &atomPtr->values);
	    }
	}
	markIndex = atomPtr->index1;
    }
    textPtr->isDirtyIncrement = increment;
    if (!ok) {
	Tcl_ResetResult(interp);
	return;
    }
    UpdateDirtyFlag(textPtr);
    EditFinish(textPtr, markIndex);
}

/*
 * Before the undo of a deletion's WRAPs: the block they are in is laid
 * out again.
 */

static void
WrapsChanged(textPtr, wraps)
    TkText *textPtr;		/* Information about text widget. */
    int *wraps;			/* See TkBTreeEqualizeDelete. */
{
    TkTextIndex index, head, end;
    TkTextSegment *segPtr;

    if ((wraps[1] < 0) || (wraps[1] >= TkBTreeNumLines(textPtr->tree))) {
	return;
    }
    TkTextMakeByteIndex(textPtr->tree, wraps[1], wraps[2], &index);
    if ((segPtr = TkIBTreeAt(&index, 1)) != NULL) {
	TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	TkTextIndexForwBytes(&head, segPtr->size, &end);
	TkTextChanged(textPtr, &head, &end);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EditFinish --
 *
 *	After an undo or a redo: the insertion cursor goes to the given
 *	index (if any), and is made visible.
 *
 *----------------------------------------------------------------------
 */

static void
EditFinish(textPtr, markIndex)
    TkText *textPtr;		/* Information about text widget. */
    char *markIndex;		/* Where the cursor goes, or NULL. */
{
    Tcl_Interp *interp = textPtr->interp;
    TkTextIndex index;
    Arg argv[3];

    if (markIndex == NULL) {
	Tcl_ResetResult(interp);
	return;
    }
    if (TkTextGetIndex(interp, textPtr, markIndex, &index) == TCL_OK) {
	TkTextSetMark(textPtr, "insert", &index);
    }
    argv[0] = argv[1] = argv[2] = NULL;
    LangSetString(&argv[0], Tk_PathName(textPtr->tkwin));
    LangSetString(&argv[1], "see");
    LangSetString(&argv[2], "insert");
    TkTextSeeCmd(textPtr, interp, 3, argv);
    LangFreeArg(argv[0], LANG_DYNAMIC);
    LangFreeArg(argv[1], LANG_DYNAMIC);
    LangFreeArg(argv[2], LANG_DYNAMIC);
    Tcl_ResetResult(interp);
}

/*
 *----------------------------------------------------------------------
 *
 * EditOther --
 *
 *	Apply (redo) or revert (undo) a recorded block insert, block
 *	split, block trim, tag add or tag remove (see TkTextUndoAtom):
 *
 *	block split	undone by deleting its separator (the deletion
 *			joins the leaves, and the nodes the split cut up
 *			to their common ancestor), then removing the
 *			levels it added above the root (block trim);
 *	block insert	undone by dissolving the block (deleting its
 *			head); the values of the leaves it had moved
 *			whole go back to them first, its instance data
 *			is kept for the redo;
 *	block trim	undone by adding the root again (TkIBTreeAddRoot);
 *	tag add		undone by removing the tag from the gaps
 *			between the ranges it had in the range;
 *	tag remove	undone by adding it again on those ranges.
 *
 *	A redo does the change again.  Values travel as for insertions
 *	and deletions: what either direction drops goes to the atom,
 *	with addresses valid before it; once the other direction has
 *	been applied, they are given back (TkBTreeRestoreValues), and
 *	what they find at their addresses waits in the atom's displaced
 *	list for the next application.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The text changes; the modified flag is updated.
 *
 *----------------------------------------------------------------------
 */

static void
EditOther(textPtr, atomPtr, revert)
    TkText *textPtr;		/* Information about text widget. */
    TkTextUndoAtom *atomPtr;	/* The change. */
    int revert;			/* Non-zero means undo it, zero means
				 * do it again. */
{
    Tcl_Interp *interp = textPtr->interp;
    TkTextValue *restore = atomPtr->values, *displaced = atomPtr->displaced;
    TkTextValue *moved = NULL;
    TkTextIndex index1, index2, end;
    TkTextSegment *segPtr;
    CaptureState cs;
    char markIndex[TK_POS_CHARS], *mark = NULL;
    int increment, ok = 1, i, topOffset;

    increment = textPtr->isDirtyIncrement;
    textPtr->isDirtyIncrement = 0;
    atomPtr->values = NULL;
    atomPtr->displaced = NULL;
    if ((TkTextGetIndex(interp, textPtr, atomPtr->index1, &index1) != TCL_OK)
	    || (TkTextGetIndex(interp, textPtr, atomPtr->index2, &index2)
		!= TCL_OK)) {
	ok = 0;
	goto done;
    }
    switch (atomPtr->type) {
    case TK_TEXT_UNDO_SPLIT:
	if (revert) {
	    textPtr->editValues = &atomPtr->values;
	    DeleteChars(textPtr, atomPtr->index1, (char *) NULL);
	    textPtr->editValues = NULL;
	    if ((atomPtr->added > 0) && (TkTextGetIndex(interp, textPtr,
		    atomPtr->index1, &index1) == TCL_OK)
		    && ((segPtr = TkIBTreeAt(&index1, 1)) != NULL)) {
		TkTextIndex head;

		TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
		CaptureStart(textPtr, &cs, &atomPtr->values, &head, &head);
		for (i = 0; i < atomPtr->added; i++) {
		    TkTextIndex leaf;

		    /*
		     * In a block that was a single leaf, the last level to
		     * take away is the root the split added above it: its
		     * only child is the leaf's padding (a PULL OUT of the
		     * root: the block is a single leaf again).
		     */

		    TkTextIndexForwBytes(&head, 1, &leaf);
		    if ((i == atomPtr->added - 1)
			    && TkIBTreeRootOverPadding(segPtr)) {
			if (TkIBTreePullOutNode(textPtr, &leaf, 1, -1) < 0) {
			    break;
			}
			continue;
		    }
		    TkBTreeVcPredictTrim(textPtr, segPtr, TK_TEXT_VC_STASH);
		    if (TkIBTreeTrim(textPtr, segPtr) != TCL_OK) {
			break;
		    }
		}
		CaptureEnd(textPtr, &cs);
		TkTextIndexForwBytes(&head, segPtr->size, &end);
		TkTextChanged(textPtr, &head, &end);
	    }
	    if ((atomPtr->roots != NULL) && (TkTextGetIndex(interp, textPtr,
		    atomPtr->index1, &index1) == TCL_OK)) {
		TkIBTreeRepadRoots(textPtr, atomPtr->roots, &atomPtr->values);
	    }
	    mark = atomPtr->index1;
	} else {
	    NotOnDummyLine(textPtr, &index1);
	    SplitChars(textPtr, &index1, atomPtr->level);
	    mark = atomPtr->index2;
	}
	break;
    case TK_TEXT_UNDO_BLOCK:
	if (revert) {
	    segPtr = TkIBTreeAt(&index1, 0);
	    if ((segPtr == NULL) || (strcmp(segPtr->body.itree.blockPtr->name,
		    Tcl_GetString(atomPtr->string)) != 0)) {
		ok = 0;			/* Not there: stale indices. */
		break;
	    }
	    if (!TkTextDataIsEmpty(atomPtr->data)) {
		TkTextDiscardValue(textPtr, atomPtr->data, TK_TEXT_VALUE_BLOCK,
			TkBTreeLineIndex(index1.linePtr), index1.byteIndex, -1,
			NULL);
		TkTextDataInit(atomPtr->data);
	    }

	    /*
	     * The block's instance data goes into the atom, for the redo.
	     */

	    if (TkTextVcOn(textPtr)
		    && (TkTextDataGetLang(segPtr->body.itree.data) != NULL)) {
		TkTextVcPredict(textPtr, segPtr->body.itree.data,
			TK_TEXT_VC_STASH, TK_TEXT_VC_BLOCK,
			TkTextVcBlockPlace(textPtr,
				TkBTreeLineIndex(index1.linePtr),
				index1.byteIndex), NULL);
		TkTextVcNotify(textPtr);
		TkTextVcSeen(textPtr, segPtr->body.itree.data,
			TK_TEXT_VC_STASH);
	    }
	    TkTextDataMove(&atomPtr->data, &segPtr->body.itree.data);
	    moved = TkBTreeTakeMovedLeafValues(textPtr, segPtr, &index1);
	    textPtr->editValues = &atomPtr->values;
	    DeleteChars(textPtr, atomPtr->index1, (char *) NULL);
	    textPtr->editValues = NULL;

	    /*
	     * Inside a block, the dissolution spliced the leaves back with
	     * separators of level 0: they get their levels back, so that
	     * the nodes are those before the block insert, before the
	     * values come back to them (BUGS 18).
	     */

	    if ((atomPtr->levels != NULL) && (TkTextGetIndex(interp, textPtr,
		    atomPtr->index1, &index1) == TCL_OK)
		    && ((segPtr = TkIBTreeAt(&index1, 1)) != NULL)) {
		TkTextIndex head;

		TkIBTreeSetSeparatorLevels(textPtr, &index1, atomPtr->levels,
			atomPtr->numLevels, atomPtr->defects,
			atomPtr->numDefects);
		TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
		TkTextIndexForwBytes(&head, segPtr->size, &end);
		TkTextChanged(textPtr, &head, &end);
	    } else if ((atomPtr->defects != NULL) && (TkTextGetIndex(interp,
		    textPtr, atomPtr->index1, &index1) == TCL_OK)
		    && ((segPtr = TkIBTreeAt(&index1, 1)) != NULL)) {
		TkTextIndex head;

		/*
		 * In a ragged tree the leaves get their defects back (the
		 * dissolution gave them the padding of the first).
		 */

		TkIBTreeSetLeafDefects(textPtr, &index1, atomPtr->defects,
			atomPtr->numDefects);
		TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
		TkTextIndexForwBytes(&head, segPtr->size, &end);
		TkTextChanged(textPtr, &head, &end);
	    }
	    mark = atomPtr->index1;
	} else {
	    Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&textPtr->blockTable,
		    Tcl_GetString(atomPtr->string));
	    TkTextBlock *blockPtr;

	    if (hPtr == NULL) {
		ok = 0;			/* The block type was deleted. */
		break;
	    }
	    blockPtr = (TkTextBlock *) Tcl_GetHashValue(hPtr);
	    if (TkTextIndexCmp(&index1, &index2) > 0) {
		ok = 0;
		break;
	    }

	    /*
	     * What the command checks, the redo checks again: the type
	     * may have been made -empty since (TkBTreeMakeBlock does not
	     * check it, and a block of such a type with contents crashes
	     * the display).  The redo then does nothing.
	     */

	    if (blockPtr->empty && (TkTextIndexCmp(&index1, &index2) != 0)) {
		ok = 0;
		break;
	    }
	    NotOnDummyLine(textPtr, &index1);
	    NotOnDummyLine(textPtr, &index2);
	    if (atomPtr->levels != NULL) {
		ckfree((char *) atomPtr->levels);
	    }
	    atomPtr->levels = TkIBTreeSeparatorLevels(&index1, &index2,
		    &atomPtr->numLevels);
	    if (atomPtr->defects != NULL) {
		ckfree((char *) atomPtr->defects);
	    }
	    atomPtr->defects = TkIBTreeLeafDefects(&index1, &index2,
		    &atomPtr->numDefects);
	    TkBTreeVcPredictBlock(textPtr, &index1, &index2,
		    TK_TEXT_VC_STASH);
	    CaptureStart(textPtr, &cs, &atomPtr->values, &index1, &index2);
	    TkTextChanged(textPtr, &index1, &index2);
	    textPtr->selOffset = -1;
	    i = KeepViewForBlock(textPtr, &index1, &index2, &topOffset);
	    if (TkBTreeMakeBlock(textPtr, &index1, &index2, blockPtr)
		    != TCL_OK) {
		ok = 0;
	    }
	    if (i >= 0) {
		ResetViewForBlock(textPtr, i, topOffset);
	    }
	    CaptureEnd(textPtr, &cs);
	    if (ok && (TkTextGetIndex(interp, textPtr, atomPtr->index1,
		    &index1) == TCL_OK)
		    && ((segPtr = TkIBTreeAt(&index1, 0)) != NULL)) {
		TkTextDataMove(&segPtr->body.itree.data, &atomPtr->data);
		TkTextVcRestored(textPtr, segPtr->body.itree.data,
			TK_TEXT_VC_BLOCK, TkTextVcBlockPlace(textPtr,
				TkBTreeLineIndex(index1.linePtr),
				index1.byteIndex));
		TkTextIndexForwBytes(&index1, segPtr->size, &end);
		TkTextPrintIndex(&end, markIndex);
		mark = markIndex;
	    }
	}
	break;
    case TK_TEXT_UNDO_SPROUT: {
	int startMade = atomPtr->level & 1, endMade = (atomPtr->level & 2) != 0;
	int rootWrapped = (atomPtr->level & 4) != 0;
	TkTextIndex mid, head;

	if (revert) {
	    /*
	     * In a block that was a single leaf, a value set on the root
	     * the sprout made real goes aside first (for the redo).
	     */

	    if (rootWrapped && (TkTextGetIndex(interp, textPtr,
		    atomPtr->index1, &mid) == TCL_OK)) {
		TkTextIndexForwChars(&mid, 1, &mid);
		TkIBTreeDisplaceRoot(textPtr, &mid, &atomPtr->displaced);
	    }

	    /*
	     * The inverse steps, right to left: the new node is pulled
	     * out (the middle leaf takes its value), the tree made lower
	     * again if the sprout made it higher, then the separator
	     * after the middle leaf and the one before it are deleted
	     * (joins: the start side keeps its value, the other goes to
	     * the atom; the redo gets them all back).
	     */

	    TkTextIndexForwChars(&index1, 1, &mid);
	    if ((segPtr = TkIBTreeAt(&mid, 1)) == NULL) {
		ok = 0;
		break;
	    }
	    TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	    TkTextIndexForwBytes(&head, segPtr->size, &end);
	    TkTextChanged(textPtr, &head, &end);
	    CaptureStart(textPtr, &cs, &atomPtr->values, &mid, &mid);
	    TkIBTreePullOut(textPtr, &mid, atomPtr->added);
	    CaptureEnd(textPtr, &cs);
	    if (endMade) {
		char sep[TK_POS_CHARS];

		TkTextIndexForwChars(&index2, startMade, &end);
		TkTextPrintIndex(&end, sep);
		textPtr->editValues = &atomPtr->values;
		DeleteChars(textPtr, sep, (char *) NULL);
		textPtr->editValues = NULL;
	    }
	    if (startMade) {
		textPtr->editValues = &atomPtr->values;
		DeleteChars(textPtr, atomPtr->index1, (char *) NULL);
		textPtr->editValues = NULL;
	    }

	    /*
	     * The block is a single leaf again: its root padding.
	     */

	    if (rootWrapped && SproutLeafIndex(textPtr, atomPtr->index1,
		    startMade, &mid)) {
		TkIBTreeRepadRootIn(textPtr, &mid, &atomPtr->displaced);
	    }
	} else {
	    int raised, s0, e0, oneIndex = (atomPtr->level & 8) != 0;

	    if (oneIndex) {
		TkTextIndex a, b;

		/*
		 * The one-index form: the leaf after index1 must still
		 * go from just after index1 to just before index2.
		 */

		TkTextIndexForwChars(&index1, 1, &a);
		if ((TkIBTreeSproutLeaf(textPtr, &a, &a, &b) != TCL_OK)
			|| (TkTextIndexCmp(&a, &index1) != 0)
			|| (TkTextIndexCmp(&b, &index2) != 0)) {
		    Tcl_ResetResult(interp);
		    ok = 0;		/* Not there: stale indices. */
		    break;
		}
	    } else if ((TkIBTreeSproutRange(textPtr, &index1, &index2, &s0,
		    &e0) != TCL_OK) || (s0 != startMade) || (e0 != endMade)) {
		ok = 0;			/* Not there: stale indices. */
		break;
	    }
	    Sprout(textPtr, atomPtr->index1, atomPtr->index2, startMade,
		    endMade, 0, &raised, &rootWrapped);
	    atomPtr->added = raised;
	    atomPtr->level = startMade + 2 * endMade + 4 * rootWrapped
		    + 8 * oneIndex;
	}
	mark = atomPtr->index1;
	break;
    }
    case TK_TEXT_UNDO_PULLOUT: {
	TkTextIndex head;

	/*
	 * A PULL OUT of block flatten.  Undone by a WRAP of the leaf (its
	 * topmost padding node becomes real, after the stored tree is
	 * made as high as before); the values come back below (the
	 * node's from the leaf, the leaf's own).  Redone by the PULL OUT
	 * again.
	 */

	if ((segPtr = TkIBTreeAt(&index1, 1)) == NULL) {
	    ok = 0;
	    break;
	}
	TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	TkTextIndexForwBytes(&head, segPtr->size, &end);
	TkTextChanged(textPtr, &head, &end);
	if (revert) {
	    TkIBTreeRaise(&index1, atomPtr->added);
	    if (TkIBTreeWrap(textPtr, &index1) < 0) {
		ok = 0;
	    }
	} else {
	    int lowered;

	    CaptureStart(textPtr, &cs, &atomPtr->values, &index1, &index1);
	    lowered = TkIBTreePullOutNode(textPtr, &index1, 1, -1);
	    CaptureEnd(textPtr, &cs);
	    if (lowered < 0) {
		ok = 0;
	    } else {
		atomPtr->added = lowered;
	    }
	}
	mark = atomPtr->index1;
	break;
    }
    case TK_TEXT_UNDO_TRIM:
	segPtr = TkIBTreeAt(&index1, 0);
	if ((segPtr == NULL) || (segPtr->body.itree.tree == NULL)) {
	    ok = 0;
	    break;
	}
	if (revert) {
	    TkIBTreeAddRoot(segPtr, atomPtr->added);
	} else {
	    /*
	     * Whether the root has a value now: it may have been set or
	     * unset since the trim was first done.
	     */

	    atomPtr->added = TkIBTreeRootHasValue(segPtr);
	    TkBTreeVcPredictTrim(textPtr, segPtr, TK_TEXT_VC_STASH);
	    CaptureStart(textPtr, &cs, &atomPtr->values, &index1, &index1);
	    if (TkIBTreeTrim(textPtr, segPtr) != TCL_OK) {
		ok = 0;
	    }
	    CaptureEnd(textPtr, &cs);
	}
	TkTextIndexForwBytes(&index1, segPtr->size, &end);
	TkTextChanged(textPtr, &index1, &end);
	mark = atomPtr->index1;
	break;
    case TK_TEXT_UNDO_TAG: {
	TkTextTag *tagPtr = TkTextCreateTag(textPtr,
		Tcl_GetString(atomPtr->string));

	CaptureStart(textPtr, &cs, &atomPtr->values, (TkTextIndex *) NULL,
		(TkTextIndex *) NULL);
	if (revert && atomPtr->added) {
	    /*
	     * The undo of tag add: the tag comes off the gaps between the
	     * ranges it had (not off the whole range: a run that tag add
	     * extended keeps its value on the part that remains).
	     */

	    TkTextIndex from = index1, to;

	    for (i = 0; i <= atomPtr->numRanges; i++) {
		char *r = atomPtr->ranges + 2 * i * TK_POS_CHARS;

		to = index2;
		if ((i < atomPtr->numRanges) && (TkTextGetIndex(interp,
			textPtr, r, &to) != TCL_OK)) {
		    break;
		}
		if (TkTextIndexCmp(&from, &to) < 0) {
		    TagWithRedraw(textPtr, &from, &to, tagPtr, 0);
		}
		if ((i < atomPtr->numRanges) && (TkTextGetIndex(interp,
			textPtr, r + TK_POS_CHARS, &from) != TCL_OK)) {
		    break;
		}
	    }
	} else if (revert) {
	    /*
	     * The undo of tag remove: the tag goes back on the ranges it
	     * had.
	     */

	    for (i = 0; i < atomPtr->numRanges; i++) {
		char *r = atomPtr->ranges + 2 * i * TK_POS_CHARS;

		if ((TkTextGetIndex(interp, textPtr, r, &index1) == TCL_OK)
			&& (TkTextGetIndex(interp, textPtr, r + TK_POS_CHARS,
				&index2) == TCL_OK)
			&& (TkTextIndexCmp(&index1, &index2) < 0)) {
		    TagWithRedraw(textPtr, &index1, &index2, tagPtr, 1);
		}
	    }
	} else {
	    TagWithRedraw(textPtr, &index1, &index2, tagPtr, atomPtr->added);
	}
	CaptureEnd(textPtr, &cs);
	break;
    }
    }

    /*
     * The values the other direction dropped come back, then (for the
     * undo of block insert) those of the leaves it had moved whole;
     * the values displaced last time come back too, and what they
     * find goes to the atom as values this change drops.
     */

    done:
    if (ok) {
	TkBTreeRestoreValues(textPtr, restore, NULL, &atomPtr->displaced, 1);
	TkBTreeRestoreValues(textPtr, moved, NULL, &atomPtr->displaced, 0);
	TkBTreeRestoreValues(textPtr, displaced, NULL, &atomPtr->values, 1);
    } else {
	TkTextDiscardValueList(textPtr, restore);
	TkTextFreeValueList(textPtr, moved);
	TkTextDiscardValueList(textPtr, displaced);
    }
    textPtr->isDirtyIncrement = increment;
    if (!ok) {
	Tcl_ResetResult(interp);
	return;
    }
    UpdateDirtyFlag(textPtr);
    EditFinish(textPtr, mark);
}

/*
 *----------------------------------------------------------------------
 *
 * KeepViewForBlock, ResetViewForBlock --
 *
 *	A block insert over several lines moves the lines after the
 *	first into the new block, out of the text's tree.  If the first
 *	line on display (textPtr->topIndex) is one of them, or the first
 *	line after the start of the range, topIndex would point into a
 *	line that is no longer there (the next redisplay crashed).
 *	KeepViewForBlock, called before, says whether that is the case
 *	and gives the line and the offset to show first afterwards: the
 *	same place if it is before the range, else the start of the
 *	first line; ResetViewForBlock, called after, sets it, as
 *	insertions and deletions do.
 *
 * Results:
 *	KeepViewForBlock: -1 if the view need not change, else the line
 *	index to show first (*lineOffsetPtr: the byte offset in it).
 *
 * Side effects:
 *	ResetViewForBlock changes the view.
 *
 *----------------------------------------------------------------------
 */

static int
KeepViewForBlock(textPtr, index1Ptr, index2Ptr, lineOffsetPtr)
    TkText *textPtr;
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range of block insert. */
    int *lineOffsetPtr;
{
    int top, line1, line2;

    if (textPtr->topIndex.linePtr == NULL) {
	return -1;
    }
    top = TkBTreeLineIndex(textPtr->topIndex.linePtr);
    line1 = TkBTreeLineIndex(index1Ptr->linePtr);
    line2 = TkBTreeLineIndex(index2Ptr->linePtr);
    if ((top < line1) || (top > line2)) {
	return -1;
    }
    if ((top == line1)
	    && (textPtr->topIndex.byteIndex <= index1Ptr->byteIndex)) {
	*lineOffsetPtr = textPtr->topIndex.byteIndex;
    } else {
	*lineOffsetPtr = 0;
    }
    return line1;
}

static void
ResetViewForBlock(textPtr, line, offset)
    TkText *textPtr;
    int line, offset;
{
    TkTextIndex newTop;

    TkTextMakeByteIndex(textPtr->tree, line, offset, &newTop);
    TkTextSetYView(textPtr, &newTop, 0);
}

/*
 *----------------------------------------------------------------------
 *
 * NotOnDummyLine, PushEdit, TagWithRedraw --
 *
 *	NotOnDummyLine moves an index on the last (dummy) line, which
 *	must stay empty, to the end of the line before it, as "insert"
 *	does.  PushEdit records a change (see TkTextUndoAtom) after a
 *	separator if -autoseparators is on and the last change was of
 *	another kind (Tk's rule).  TagWithRedraw adds or removes a tag
 *	and has the display follow, as "tag add" and "tag remove" do.
 *
 *----------------------------------------------------------------------
 */

static void
NotOnDummyLine(textPtr, indexPtr)
    TkText *textPtr;
    TkTextIndex *indexPtr;
{
    int lineIndex = TkBTreeLineIndex(indexPtr->linePtr);

    if (lineIndex == TkBTreeNumLines(textPtr->tree)) {
	TkTextMakeByteIndex(textPtr->tree, lineIndex - 1, 1000000, indexPtr);
    }
}

static TkTextUndoAtom *
PushEdit(textPtr, mode, type, index1, index2, string)
    TkText *textPtr;
    int mode;				/* TK_TEXT_EDIT_... */
    int type;				/* TK_TEXT_UNDO_... */
    char *index1, *index2;
    Tcl_Obj *string;			/* Consumed; or NULL. */
{
    if (textPtr->autoSeparators && (textPtr->lastEditMode != mode)) {
	TkTextUndoInsertUndoSeparator(textPtr->undoStack);
    }
    textPtr->lastEditMode = mode;
    return TkTextUndoPushAction(textPtr->undoStack, type, index1, index2,
	    string, (Tcl_Obj *) NULL, (char *) NULL, 0);
}

static void
TagWithRedraw(textPtr, index1Ptr, index2Ptr, tagPtr, add)
    TkText *textPtr;
    TkTextIndex *index1Ptr, *index2Ptr;
    TkTextTag *tagPtr;
    int add;
{
    if (TkTextVcOn(textPtr) && tagPtr->hasRunValues) {
	/*
	 * The look-ahead before the redisplay is told (the callback may
	 * use the display); TkBTreeTag does not do it again.
	 */

	TkBTreeVcPredictTag(textPtr, index1Ptr, index2Ptr, tagPtr, add);
	textPtr->vcTagDone = 1;
    }
    if (tagPtr->affectsDisplay) {
	TkTextRedrawTag(textPtr, index1Ptr, index2Ptr, tagPtr, !add);
    } else {
	TkTextEventuallyRepick(textPtr);
    }
    TkBTreeTag(index1Ptr, index2Ptr, tagPtr, add);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextTagChange --
 *
 *	"tag add" and "tag remove" over one range: TkBTreeTag, recorded
 *	for undo (TK_TEXT_UNDO_TAG) with the ranges the tag had in the
 *	range before, unless the tag is "sel" (the selection is not part
 *	of the text's content) or the change changes nothing (an empty
 *	range included).  Without -undo, a change that changes something
 *	(and is not of "sel") is not recorded but counts for the
 *	modified flag.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The tag changes; values of runs may be dropped (into the atom).
 *
 *----------------------------------------------------------------------
 */

void
TkTextTagChange(textPtr, index1Ptr, index2Ptr, tagPtr, add)
    TkText *textPtr;		/* Information about text widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range. */
    TkTextTag *tagPtr;		/* The tag. */
    int add;			/* 1 to add the tag, 0 to remove it. */
{
    RecordTagChange(textPtr, index1Ptr, index2Ptr, tagPtr, add,
	    add ? TK_TEXT_EDIT_TAGADD : TK_TEXT_EDIT_TAGREMOVE);
}

static void
RecordTagChange(textPtr, index1Ptr, index2Ptr, tagPtr, add, mode)
    TkText *textPtr;		/* Information about text widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range. */
    TkTextTag *tagPtr;		/* The tag. */
    int add;			/* 1 to add the tag, 0 to remove it. */
    int mode;			/* The kind of edit (TK_TEXT_EDIT_...) for
				 * -autoseparators, or -1 for part of a
				 * deletion (no separator, mode unchanged). */
{
    TkTextSearch search;
    TkTextIndex start;
    TkTextValue *captured = NULL;
    TkTextUndoAtom *atomPtr;
    CaptureState cs;
    char i1[TK_POS_CHARS], i2[TK_POS_CHARS], *ranges = NULL;
    int on, num = 0, max = 0, whole;

    if (TkTextIndexCmp(index1Ptr, index2Ptr) >= 0) {
	return;				/* An empty range: nothing changes. */
    }
    if (tagPtr == textPtr->selTagPtr) {
	TagWithRedraw(textPtr, index1Ptr, index2Ptr, tagPtr, add);
	return;
    }

    /*
     * Without -undo, nothing is recorded, but a change that changes
     * something counts for the modified flag, as insertions do.  Kept
     * cheap (programs that highlight add tags a lot): the tag changes
     * the range unless its state at the start is the one wanted and
     * it toggles nowhere before the end.
     */

    if (!textPtr->undo) {
	on = TkBTreeCharTagged(index1Ptr, tagPtr);
	whole = (add != 0) == (on != 0);
	if (whole) {
	    TkBTreeStartSearch(index1Ptr, index2Ptr, tagPtr, &search);
	    if (TkBTreeNextTag(&search)
		    && (TkTextIndexCmp(&search.extIndex, index2Ptr) < 0)) {
		whole = 0;
	    }
	}
	TagWithRedraw(textPtr, index1Ptr, index2Ptr, tagPtr, add);
	if (!whole && (mode >= 0)) {
	    UpdateDirtyFlag(textPtr);
	}
	return;
    }

    /*
     * The ranges the tag has in the range now.
     */

    TkTextPrintIndex(index1Ptr, i1);
    TkTextPrintIndex(index2Ptr, i2);
    on = TkBTreeCharTagged(index1Ptr, tagPtr);
    start = *index1Ptr;
    TkBTreeStartSearch(index1Ptr, index2Ptr, tagPtr, &search);
    while (1) {
	int more = TkBTreeNextTag(&search);
	TkTextIndex *atPtr = more ? &search.extIndex : index2Ptr;

	if (more && (search.segPtr->typePtr == &tkTextToggleOnType)) {
	    if (!on) {
		start = search.extIndex;
		on = 1;
	    }
	    continue;
	}
	if (on && (TkTextIndexCmp(&start, atPtr) < 0)) {
	    if (num >= max) {
		char *grown;

		max = 2 * max + 4;
		grown = ckalloc((unsigned) (2 * max * TK_POS_CHARS));
		if (num > 0) {
		    memcpy(grown, ranges, (size_t) (2 * num * TK_POS_CHARS));
		    ckfree(ranges);
		}
		ranges = grown;
	    }
	    TkTextPrintIndex(&start, ranges + 2 * num * TK_POS_CHARS);
	    TkTextPrintIndex(atPtr, ranges + (2 * num + 1) * TK_POS_CHARS);
	    num++;
	}
	on = 0;
	if (!more) {
	    break;
	}
    }

    /*
     * Nothing to change: not recorded.
     */

    whole = (num == 1) && (strcmp(ranges, i1) == 0)
	    && (strcmp(ranges + TK_POS_CHARS, i2) == 0);
    if ((add && whole) || (!add && (num == 0))) {
	if (ranges != NULL) {
	    ckfree(ranges);
	}
	TagWithRedraw(textPtr, index1Ptr, index2Ptr, tagPtr, add);
	return;
    }

    CaptureStart(textPtr, &cs, &captured, (TkTextIndex *) NULL,
	    (TkTextIndex *) NULL);
    TagWithRedraw(textPtr, index1Ptr, index2Ptr, tagPtr, add);
    CaptureEnd(textPtr, &cs);
    if (mode >= 0) {
	atomPtr = PushEdit(textPtr, mode, TK_TEXT_UNDO_TAG, i1, i2,
		Tcl_NewStringObj(tagPtr->name, -1));
    } else {
	atomPtr = TkTextUndoPushAction(textPtr->undoStack, TK_TEXT_UNDO_TAG,
		i1, i2, Tcl_NewStringObj(tagPtr->name, -1), (Tcl_Obj *) NULL,
		(char *) NULL, 0);
    }
    atomPtr->added = add;
    atomPtr->numRanges = num;
    atomPtr->ranges = ranges;
    atomPtr->values = captured;
    UpdateDirtyFlag(textPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TextEditUndo, TextEditRedo --
 *
 *	Undo or redo one compound action, with recording switched off
 *	meanwhile (and the modified flag counting down while undoing).
 *
 * Results:
 *	TCL_OK, or TCL_ERROR if there was nothing to undo or redo.
 *
 * Side effects:
 *	The text changes.
 *
 *----------------------------------------------------------------------
 */

static int
TextEditUndo(textPtr)
    TkText *textPtr;		/* Overall information about text widget. */
{
    int status;

    if (!textPtr->undo) {
	return TCL_OK;
    }
    textPtr->undo = 0;
    textPtr->isDirtyIncrement = -1;
    status = TkTextUndoRevert(textPtr);
    textPtr->isDirtyIncrement = 1;
    textPtr->undo = 1;
    return status;
}

static int
TextEditRedo(textPtr)
    TkText *textPtr;		/* Overall information about text widget. */
{
    int status;

    if (!textPtr->undo) {
	return TCL_OK;
    }
    textPtr->undo = 0;
    status = TkTextUndoApply(textPtr);
    textPtr->undo = 1;
    return status;
}

/*
 *----------------------------------------------------------------------
 *
 * TextEditCmd --
 *
 *	Handle the subcommands of "$text edit ...": modified, redo,
 *	reset, separator and undo.  See the user documentation.
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	See the user documentation.
 *
 *----------------------------------------------------------------------
 */

static int
TextEditCmd(textPtr, interp, argc, args)
    TkText *textPtr;		/* Information about text widget. */
    Tcl_Interp *interp;		/* Current interpreter. */
    int argc;			/* Number of arguments. */
    Arg *args;			/* Argument strings; args[1] is "edit". */
{
    int c, setModified;
    size_t length;

    if (argc < 3) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		LangString(args[0]), " edit option ?arg arg ...?\"", NULL);
	return TCL_ERROR;
    }
    c = LangString(args[2])[0];
    length = strlen(LangString(args[2]));
    if ((c == 'm') && (strncmp(LangString(args[2]), "modified", length) == 0)) {
	if (argc == 3) {
	    Tcl_SetObjResult(interp, Tcl_NewBooleanObj(textPtr->isDirty));
	} else if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " edit modified ?boolean?\"", NULL);
	    return TCL_ERROR;
	} else {
	    if (Tcl_GetBooleanFromObj(interp, args[3], &setModified) != TCL_OK) {
		return TCL_ERROR;
	    }

	    /*
	     * Set or reset the dirty info and trigger a Modified event.
	     */

	    if (setModified) {
		textPtr->isDirty = 1;
		textPtr->modifiedSet = 1;
	    } else {
		textPtr->isDirty = 0;
		textPtr->modifiedSet = 0;
	    }
	    GenerateModifiedEvent(textPtr);
	}
    } else if ((c == 'r') && (strncmp(LangString(args[2]), "redo", length) == 0)
	    && (length >= 3)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " edit redo\"", NULL);
	    return TCL_ERROR;
	}
	if (TextEditRedo(textPtr) != TCL_OK) {
	    Tcl_AppendResult(interp, "nothing to redo", NULL);
	    return TCL_ERROR;
	}
	/* The next edit starts a step of its own (see "edit undo"). */
	textPtr->lastEditMode = TK_TEXT_EDIT_OTHER;
    } else if ((c == 'r') && (strncmp(LangString(args[2]), "reset", length) == 0)
	    && (length >= 3)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " edit reset\"", NULL);
	    return TCL_ERROR;
	}
	TkTextUndoClearStacks(textPtr->undoStack);
	textPtr->lastEditMode = TK_TEXT_EDIT_OTHER;
    } else if ((c == 's') && (strncmp(LangString(args[2]), "separator", length) == 0)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " edit separator\"", NULL);
	    return TCL_ERROR;
	}
	TkTextUndoInsertUndoSeparator(textPtr->undoStack);
    } else if ((c == 'u') && (strncmp(LangString(args[2]), "undo", length) == 0)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " edit undo\"", NULL);
	    return TCL_ERROR;
	}
	if (TextEditUndo(textPtr) != TCL_OK) {
	    Tcl_AppendResult(interp, "nothing to undo", NULL);
	    return TCL_ERROR;
	}
	/*
	 * The next edit starts a step of its own.  Otherwise a deletion
	 * after the undo of a deletion would see "the same kind as the
	 * last edit", insert no separator, and join whatever step is now
	 * on top of the undo stack (an earlier insertion, say), which a
	 * second undo would then take back as well.
	 */
	textPtr->lastEditMode = TK_TEXT_EDIT_OTHER;
    } else {
	Tcl_AppendResult(interp, "bad edit option \"", LangString(args[2]),
		"\": must be modified, redo, reset, separator or undo", NULL);
	return TCL_ERROR;
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TextGetList --
 *
 *	Collect the contents of a range the way "block list" reports
 *	them: strings, tag toggles, marks, blocks with their structure,
 *	windows and images, as a list of blessed objects; for the undo,
 *	so without the node values (which the undo atom records with
 *	their addresses, see TkTextValue: a copy in the list would keep
 *	a value alive after its node has let it go).
 *
 * Results:
 *	A new reference to the list (to be released by the caller).
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static Tcl_Obj *
TextGetList(textPtr, index1Ptr, index2Ptr)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *index1Ptr;	/* Start of the range. */
    TkTextIndex *index2Ptr;	/* End of the range (not included). */
{
    ListFactory listFactory;
    TkTextLine *linePtr = index1Ptr->linePtr;
    int offset = index1Ptr->byteIndex;
    Tcl_Obj *result;
    Arg arg = NULL;

    ListFactoryInit(&listFactory);
    LangSetString(&arg, "");

    /*
     * A tag that ends exactly at the start of the range has its
     * off-toggle there, which belongs to the text on its left and is
     * not listed: the list would not mention the tag, and the undo
     * would let the text it re-inserts take the tag if the tag is on
     * again after the range (Tk's insertion rule).  An off-toggle at
     * the start of the list says that the text has it off.
     */

    {
	TkTextIndex intIndex;
	TkTextSegment *segPtr;
	int count = 0;

	TkTextIndexToInternalSeg(index1Ptr, &intIndex, (int *) NULL);
	for (segPtr = intIndex.linePtr->segPtr;
		(segPtr != NULL) && (count <= intIndex.byteIndex);
		count += segPtr->size, segPtr = segPtr->nextPtr) {
	    if ((count == intIndex.byteIndex) && (segPtr->size > 0)) {
		break;
	    }
	    if ((count == intIndex.byteIndex)
		    && (segPtr->typePtr == &tkTextToggleOffType)) {
		LangSetString(&arg, segPtr->body.toggle.tagPtr->name);
		ListFactoryAppendCopyWithType(&listFactory, arg,
			"Tk::Text::TagOff");
	    }
	}
	LangSetString(&arg, "");
    }
    while (linePtr != index2Ptr->linePtr) {
	TkBTreeLineTextAppend(textPtr, linePtr, offset, -1,
		(void *) &listFactory, TkTextUserGetFlags(textPtr) | TKT_GET_LIST
		| TKT_GET_NOVALUES | TKT_GET_PRIVATE, NULL);
	offset = -1;
	ListFactoryAppendCopyWithType(&listFactory, arg, "Tk::Text::NewLine");
	linePtr = TkBTreeNextLine(linePtr);
    }
    TkBTreeLineTextAppend(textPtr, linePtr, offset, index2Ptr->byteIndex,
	    (void *) &listFactory, TkTextUserGetFlags(textPtr) | TKT_GET_LIST
	    | TKT_GET_NOVALUES | TKT_GET_PRIVATE, NULL);
    LangFreeArg(arg, LANG_DYNAMIC);
    result = newRV_inc((SV *) ListFactoryArg(&listFactory));
    ListFactoryFree(&listFactory);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * MarkOp --
 *
 *	Run "mark op name ?extra?" on the widget (gravity, unset).
 *
 * Results:
 *	A standard Tcl result.
 *
 * Side effects:
 *	Whatever the mark command does.
 *
 *----------------------------------------------------------------------
 */

static int
MarkOp(textPtr, op, name, extra)
    TkText *textPtr;		/* Overall information about text widget. */
    char *op;			/* "gravity" or "unset". */
    char *name;			/* The mark. */
    char *extra;		/* The gravity, or NULL. */
{
    Arg argv[5];
    int argc = 4, i, result;

    if (TkTextIsPrivateMarkName(name)) {
	/*
	 * A private mark (see InsertListElements), which the mark command
	 * does not know: only its gravity is set here.
	 */

	Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&textPtr->markTable, name);

	if ((hPtr != NULL) && (strcmp(op, "gravity") == 0)) {
	    TkTextSetMarkGravity(textPtr,
		    (TkTextSegment *) Tcl_GetHashValue(hPtr),
		    extra[0] == 'l');
	}
	return TCL_OK;
    }
    argv[0] = argv[1] = argv[2] = argv[3] = argv[4] = NULL;
    LangSetString(&argv[0], Tk_PathName(textPtr->tkwin));
    LangSetString(&argv[1], "mark");
    LangSetString(&argv[2], op);
    LangSetString(&argv[3], name);
    if (extra != NULL) {
	LangSetString(&argv[4], extra);
	argc = 5;
    }
    result = TkTextMarkCmd(textPtr, textPtr->interp, argc, argv);
    for (i = 0; i < argc; i++) {
	LangFreeArg(argv[i], LANG_DYNAMIC);
    }
    Tcl_ResetResult(textPtr->interp);
    return result;
}

/*
 *----------------------------------------------------------------------
 *
 * InsertList, InsertListElements --
 *
 *	Re-create at a position the contents of a range as "block list"
 *	reported them (see TextGetList): the text with its tags, the
 *	marks (except "insert" and "current"), the blocks with their
 *	structure and instance data (the lists of the undo have none:
 *	TK_TEXT_VALUE_BLOCK records give it back), and the embedded
 *	images and windows (see InsertEmbedded; Tk's text widget does
 *	not restore those).
 *	The insertion point is a right-gravity mark, so that it stays
 *	after everything inserted; a block is created empty and filled
 *	through a mark just inside it, the way the demo loads documents.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The text changes.
 *
 *----------------------------------------------------------------------
 */

static int undoMarkCount = 0;

static void
InsertList(textPtr, indexPtr, listObj)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *indexPtr;	/* Where to insert. */
    Tcl_Obj *listObj;		/* The list (a reference to an array). */
{
    InsertState state;
    int i;
    char markName[40], startMark[40];
    TkTextIndex index1, index2;

    if (!SvROK((SV *) listObj) || (SvTYPE(SvRV((SV *) listObj)) != SVt_PVAV)) {
	return;
    }
    state.pending = NULL;
    state.numPending = state.maxPending = 0;
    state.rightMarks = NULL;
    state.numRight = state.maxRight = 0;
    state.tags = NULL;
    state.tagOn = NULL;
    state.numTags = 0;
    state.defectLines = NULL;
    state.defects = NULL;
    state.numDefects = state.maxDefects = 0;
    ScanListTags(textPtr, (AV *) SvRV((SV *) listObj), 0, &state);

    /*
     * The leaf defects of a list of the undo must be those of a tree
     * that follows the rules of padding (O7): at a separator of stored
     * depth s, both leaves have defects of at most s.  Else they are
     * not given back (a panic under "debug": the list was not made
     * from such a tree).
     */

    state.useDefects = CheckListDefects((AV *) SvRV((SV *) listObj), 0,
	    -1);
    if (!state.useDefects && tkBTreeDebug) {
	panic("InsertList: leaf defects deeper than their separators");
    }

    /*
     * Two marks: a right-gravity one that stays after everything
     * inserted (the insertion point), a left-gravity one that stays at
     * the start of it all (for tags whose on-toggle was before the
     * range).
     */

    sprintf(markName, "#undo%d", undoMarkCount++);
    TkTextSetMark(textPtr, markName, indexPtr);
    sprintf(startMark, "#undoS%d", undoMarkCount++);
    TkTextSetMark(textPtr, startMark, indexPtr);
    MarkOp(textPtr, "gravity", startMark, "left");
    InsertListElements(textPtr, markName, startMark,
	    (AV *) SvRV((SV *) listObj), 0, &state);

    /*
     * Tags whose off-toggle was beyond the range extend to the end of
     * what was inserted.
     */

    if ((TkTextMarkNameToIndex(textPtr, markName, &index2) == TCL_OK)) {
	for (i = 0; i < state.numPending; i++) {
	    if (TkTextMarkNameToIndex(textPtr, state.pending[i].mark, &index1)
		    == TCL_OK && (TkTextIndexCmp(&index1, &index2) < 0)) {
		TkBTreeTag(&index1, &index2, state.pending[i].tagPtr, 1);
		TkTextRedrawTag(textPtr, &index1, &index2,
			state.pending[i].tagPtr, 1);
	    }
	    MarkOp(textPtr, "unset", state.pending[i].mark, (char *) NULL);
	}
    }
    for (i = 0; i < state.numRight; i++) {
	MarkOp(textPtr, "gravity", state.rightMarks[i], "right");
	ckfree(state.rightMarks[i]);
    }
    MarkOp(textPtr, "unset", markName, (char *) NULL);
    MarkOp(textPtr, "unset", startMark, (char *) NULL);
    undoMarkCount -= 2;

    /*
     * Everything is in: the leaves re-created get their defects (a
     * refusal is an inconsistency: a panic under "debug").
     */

    for (i = 0; i < state.numDefects; i++) {
	if ((TkIBTreeSetDefect(textPtr, state.defectLines[i],
		state.defects[i]) != 0) && tkBTreeDebug) {
	    panic("InsertList: defect %d refused", state.defects[i]);
	}
    }
    if (state.defectLines != NULL) {
	ckfree((char *) state.defectLines);
	ckfree((char *) state.defects);
    }
    if (state.pending != NULL) {
	ckfree((char *) state.pending);
    }
    if (state.rightMarks != NULL) {
	ckfree((char *) state.rightMarks);
    }
    if (state.tags != NULL) {
	ckfree((char *) state.tags);
	ckfree(state.tagOn);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ScanListTags, ListTagName, InsertListText --
 *
 *	Text inserted inside a tagged range takes the tag (Tk's rule for
 *	insertion), but text re-created from a list must have the tags
 *	the list gives it, no more: the undo of a deletion that joined
 *	two ranges of a tag must bring back the untagged text between
 *	them.  ScanListTags finds the tags the list switches on or off
 *	somewhere and whether each is on at its start (its first toggle
 *	is an off-toggle); InsertListText inserts a piece of text and
 *	takes from it those of these tags that are off at that point of
 *	the list.  A tag the list does not mention was the same all over
 *	the range; the insertion rule gives it as it was.  ListTagName
 *	is the name in a TagOn or TagOff element (a TagOn of a run with
 *	a value is a list [name, value], see "tag data").
 *
 *----------------------------------------------------------------------
 */

static char *
ListTagName(inner)
    SV *inner;			/* The referent of the element. */
{
    if (SvTYPE(inner) == SVt_PVAV) {
	SV **svp = av_fetch((AV *) inner, 0, 0);

	return (svp != NULL) ? SvPV_nolen(*svp) : "";
    }
    return SvPV_nolen(inner);
}

static void
ScanListTags(textPtr, av, first, statePtr)
    TkText *textPtr;		/* Overall information about text widget. */
    AV *av;			/* The elements. */
    int first;			/* Index of the first element to use. */
    InsertState *statePtr;	/* Where the tags go. */
{
    int i, j, n = av_len(av) + 1, on;
    SV **svp, *elt;
    TkTextTag *tagPtr;

    for (i = first; i < n; i++) {
	svp = av_fetch(av, i, 0);
	if ((svp == NULL) || !SvROK(*svp) || !sv_isobject(*svp)) {
	    continue;
	}
	elt = *svp;
	if (sv_derived_from(elt, "Tk::Text::Block")
		&& (SvTYPE(SvRV(elt)) == SVt_PVAV)) {
	    ScanListTags(textPtr, (AV *) SvRV(elt), 1, statePtr);
	    continue;
	}
	if (sv_derived_from(elt, "Tk::Text::TagOn")) {
	    on = 1;
	} else if (sv_derived_from(elt, "Tk::Text::TagOff")) {
	    on = 0;
	} else {
	    continue;
	}
	tagPtr = TkTextCreateTag(textPtr, ListTagName(SvRV(elt)));
	for (j = 0; j < statePtr->numTags; j++) {
	    if (statePtr->tags[j] == tagPtr) {
		break;
	    }
	}
	if (j == statePtr->numTags) {
	    /*
	     * First seen: on at the start of the list if this is an
	     * off-toggle.
	     */

	    TkTextTag **tags = (TkTextTag **) ckalloc((unsigned)
		    ((j + 1) * sizeof(TkTextTag *)));
	    char *tagOn = ckalloc((unsigned) (j + 1));

	    if (j > 0) {
		memcpy(tags, statePtr->tags, j * sizeof(TkTextTag *));
		memcpy(tagOn, statePtr->tagOn, (size_t) j);
		ckfree((char *) statePtr->tags);
		ckfree(statePtr->tagOn);
	    }
	    statePtr->tags = tags;
	    statePtr->tagOn = tagOn;
	    statePtr->tags[j] = tagPtr;
	    statePtr->tagOn[j] = !on;
	    statePtr->numTags++;
	}
    }
}

/*
 * SeparatorPair --
 *	The depth and the defect a separator element of a list gives: a
 *	plain number (a blessed scalar) is the stored depth of the
 *	separator, the leaf after it having no padding (defect 0); a pair
 *	[depth, defect] (a blessed array) gives the defect of the leaf
 *	after it; [undef, defect] stands before a padded first leaf (no
 *	separator: *depthPtr is -1).
 *
 * CheckListDefects --
 *	Whether the leaf defects of a list (or of a block's contents in it,
 *	from element "first") follow the rule of the import (O7): at a
 *	separator of stored depth s, both adjacent leaves have defects of
 *	at most s; and no leaf has more padding than its block has levels
 *	below the root (depth: the header's, or -1 if unknown).  A leaf
 *	whose start is not in the list is not checked.
 */

static void
SeparatorPair(inner, depthPtr, defectPtr)
    SV *inner;			/* The referent of the element. */
    int *depthPtr, *defectPtr;	/* Filled in. */
{
    SV **svp;

    if (SvTYPE(inner) != SVt_PVAV) {
	*depthPtr = (int) SvIV(inner);
	*defectPtr = 0;
	return;
    }
    svp = av_fetch((AV *) inner, 0, 0);
    *depthPtr = ((svp != NULL) && SvOK(*svp)) ? (int) SvIV(*svp) : -1;
    svp = av_fetch((AV *) inner, 1, 0);
    *defectPtr = ((svp != NULL) && SvOK(*svp)) ? (int) SvIV(*svp) : 0;
}

static int
CheckListDefects(av, first, depth)
    AV *av;			/* The elements. */
    int first;			/* Index of the first element to use. */
    int depth;			/* The depth of the block's header, or -1. */
{
    int i, n = av_len(av) + 1, prev = -1, s, d;
    SV **svp, *elt;

    for (i = first; i < n; i++) {
	svp = av_fetch(av, i, 0);
	if ((svp == NULL) || !SvROK(*svp) || !sv_isobject(*svp)) {
	    continue;
	}
	elt = *svp;
	if (sv_derived_from(elt, "Tk::Text::BlockSeparator")) {
	    SeparatorPair(SvRV(elt), &s, &d);
	    if ((d < 0) || ((depth >= 0) && (d > depth))) {
		return 0;
	    }
	    if ((s >= 0) && ((d > s) || ((prev >= 0) && (prev > s)))) {
		return 0;
	    }
	    prev = d;
	} else if (sv_derived_from(elt, "Tk::Text::Block")
		&& (SvTYPE(SvRV(elt)) == SVt_PVAV)) {
	    AV *bav = (AV *) SvRV(elt);
	    int inner = -1;

	    svp = av_fetch(bav, 0, 0);
	    if ((svp != NULL) && SvROK(*svp)
		    && (SvTYPE(SvRV(*svp)) == SVt_PVAV)) {
		svp = av_fetch((AV *) SvRV(*svp), 1, 0);
		if ((svp != NULL) && SvOK(*svp)) {
		    inner = (int) SvIV(*svp);
		}
	    }
	    if (!CheckListDefects(bav, 1, inner)) {
		return 0;
	    }
	}
    }
    return 1;
}

static void
InsertListText(textPtr, markName, indexPtr, string, statePtr)
    TkText *textPtr;		/* Overall information about text widget. */
    char *markName;		/* The mark after the insertion point. */
    TkTextIndex *indexPtr;	/* Where to insert. */
    char *string;		/* What. */
    InsertState *statePtr;	/* The tags of the list and their state. */
{
    TkTextIndex start = *indexPtr, end;
    int j;

    InsertChars(textPtr, indexPtr, string);
    if (TkTextMarkNameToIndex(textPtr, markName, &end) != TCL_OK) {
	return;
    }
    for (j = 0; j < statePtr->numTags; j++) {
	if (!statePtr->tagOn[j] && (TkTextIndexCmp(&start, &end) < 0)) {
	    TkBTreeTag(&start, &end, statePtr->tags[j], 0);
	}
    }
}

/*
 * NoteLeafDefect --
 *	A leaf re-created from a list starts at an index: it is real all
 *	the way up until everything is in, then it gets its defect (see
 *	InsertState).
 */

static void
NoteLeafDefect(textPtr, indexPtr, defect, statePtr)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *indexPtr;	/* Where the leaf starts. */
    int defect;			/* Its defect. */
    InsertState *statePtr;	/* Where the defects go. */
{
    TkTextLine *linePtr = TkIBTreeLeafAt(indexPtr);
    int j;

    if (!statePtr->useDefects || (linePtr == NULL)) {
	return;
    }
    if (statePtr->numDefects >= statePtr->maxDefects) {
	TkTextLine **lines;
	int *defects;

	statePtr->maxDefects = 2 * statePtr->maxDefects + 8;
	lines = (TkTextLine **) ckalloc((unsigned)
		(statePtr->maxDefects * sizeof(TkTextLine *)));
	defects = (int *) ckalloc((unsigned)
		(statePtr->maxDefects * sizeof(int)));
	for (j = 0; j < statePtr->numDefects; j++) {
	    lines[j] = statePtr->defectLines[j];
	    defects[j] = statePtr->defects[j];
	}
	if (statePtr->defectLines != NULL) {
	    ckfree((char *) statePtr->defectLines);
	    ckfree((char *) statePtr->defects);
	}
	statePtr->defectLines = lines;
	statePtr->defects = defects;
    }
    statePtr->defectLines[statePtr->numDefects] = linePtr;
    statePtr->defects[statePtr->numDefects++] = defect;
    TkIBTreeSetDefect(textPtr, linePtr, 0);
}

static void
InsertListElements(textPtr, markName, startMark, av, first, statePtr)
    TkText *textPtr;		/* Overall information about text widget. */
    char *markName;		/* The mark to insert at. */
    char *startMark;		/* The mark at the start of everything. */
    AV *av;			/* The elements. */
    int first;			/* Index of the first element to use. */
    InsertState *statePtr;	/* The pending tags and the right-gravity
				 * marks so far. */
{
    int i, n, j, len;
    SV **svp, *elt, *inner;
    TkTextIndex index, index2;
    char *str;

    n = av_len(av) + 1;
    for (i = first; i < n; i++) {
	svp = av_fetch(av, i, 0);
	if ((svp == NULL) || !SvROK(*svp) || !sv_isobject(*svp)) {
	    continue;
	}
	elt = *svp;
	inner = SvRV(elt);
	if (TkTextMarkNameToIndex(textPtr, markName, &index) != TCL_OK) {
	    return;
	}
	if (sv_derived_from(elt, "Tk::Text::String")) {
	    str = SvPVutf8_nolen(inner);
	    len = (int) strlen(str);
	    if (len > 0) {
		InsertListText(textPtr, markName, &index, str, statePtr);
	    }
	} else if (sv_derived_from(elt, "Tk::Text::NewLine")) {
	    /* A marker only: the newline is part of the string before. */
	} else if (sv_derived_from(elt, "Tk::Text::TagOn")) {
	    TkTextTag *tagPtr = TkTextCreateTag(textPtr, ListTagName(inner));
	    PendingTag *pPtr;

	    for (j = 0; j < statePtr->numTags; j++) {
		if (statePtr->tags[j] == tagPtr) {
		    statePtr->tagOn[j] = 1;
		}
	    }
	    for (j = 0; j < statePtr->numPending; j++) {
		if (statePtr->pending[j].tagPtr == tagPtr) {
		    break;
		}
	    }
	    if (j < statePtr->numPending) {
		continue;
	    }
	    if (statePtr->numPending >= statePtr->maxPending) {
		PendingTag *grown;

		statePtr->maxPending = 2 * statePtr->maxPending + 8;
		grown = (PendingTag *) ckalloc((unsigned)
			(statePtr->maxPending * sizeof(PendingTag)));
		for (j = 0; j < statePtr->numPending; j++) {
		    grown[j] = statePtr->pending[j];
		}
		if (statePtr->pending != NULL) {
		    ckfree((char *) statePtr->pending);
		}
		statePtr->pending = grown;
	    }
	    pPtr = &statePtr->pending[statePtr->numPending++];
	    pPtr->tagPtr = tagPtr;
	    sprintf(pPtr->mark, "#undoT%d", undoMarkCount++);
	    TkTextSetMark(textPtr, pPtr->mark, &index);
	    MarkOp(textPtr, "gravity", pPtr->mark, "left");
	} else if (sv_derived_from(elt, "Tk::Text::TagOff")) {
	    TkTextTag *tagPtr = TkTextCreateTag(textPtr, ListTagName(inner));
	    char *from = startMark;

	    for (j = 0; j < statePtr->numTags; j++) {
		if (statePtr->tags[j] == tagPtr) {
		    statePtr->tagOn[j] = 0;
		}
	    }
	    for (j = 0; j < statePtr->numPending; j++) {
		if (statePtr->pending[j].tagPtr == tagPtr) {
		    from = statePtr->pending[j].mark;
		    break;
		}
	    }
	    if ((TkTextMarkNameToIndex(textPtr, from, &index2) == TCL_OK)
		    && (TkTextIndexCmp(&index2, &index) < 0)) {
		TkBTreeTag(&index2, &index, tagPtr, 1);
		TkTextRedrawTag(textPtr, &index2, &index, tagPtr, 1);
	    }
	    if (j < statePtr->numPending) {
		MarkOp(textPtr, "unset", from, (char *) NULL);
		statePtr->pending[j] = statePtr->pending[--statePtr->numPending];
	    }
	} else if (sv_derived_from(elt, "Tk::Text::MarkLeft")
		|| sv_derived_from(elt, "Tk::Text::MarkRight")) {
	    /*
	     * A reference to the name, or [name, value] for a mark with
	     * a value ("mark data"), which the mark gets as the Lang part
	     * of its data (the Lang part it had is freed when the widget
	     * command returns; the other slots stay).
	     */

	    str = ListTagName(inner);

	    /*
	     * A private mark (an ornament's, in a list of the undo) goes
	     * back where it was if it still exists; one whose ornament
	     * is gone is not re-created.
	     */

	    if (TkTextIsPrivateMarkName(str)
		    && (Tcl_FindHashEntry(&textPtr->markTable, str) == NULL)) {
		continue;
	    }
	    if ((strcmp(str, "insert") != 0) && (strcmp(str, "current") != 0)
		    && (str[0] != '#')) {
		TkTextSegment *markPtr = TkTextSetMark(textPtr, str, &index);

		if (SvTYPE(inner) == SVt_PVAV) {
		    SV **vp = av_fetch((AV *) inner, 1, 0);
		    Arg old = TkTextDataPutLang(&markPtr->body.mark.value,
			    ((vp != NULL) && SvOK(*vp)) ? LangCopyArg(*vp) : NULL);

		    TkTextFreeValueLater(textPtr, TkTextDataFromLang(old));
		}
		MarkOp(textPtr, "gravity", str, "left");
		if (sv_derived_from(elt, "Tk::Text::MarkRight")) {
		    /*
		     * Right gravity only once everything is in (see
		     * InsertState).
		     */

		    if (statePtr->numRight >= statePtr->maxRight) {
			char **grown;

			statePtr->maxRight = 2 * statePtr->maxRight + 8;
			grown = (char **) ckalloc((unsigned)
				(statePtr->maxRight * sizeof(char *)));
			for (j = 0; j < statePtr->numRight; j++) {
			    grown[j] = statePtr->rightMarks[j];
			}
			if (statePtr->rightMarks != NULL) {
			    ckfree((char *) statePtr->rightMarks);
			}
			statePtr->rightMarks = grown;
		    }
		    statePtr->rightMarks[statePtr->numRight] =
			    (char *) ckalloc((unsigned) (strlen(str) + 1));
		    strcpy(statePtr->rightMarks[statePtr->numRight++], str);
		}
	    }
	} else if (sv_derived_from(elt, "Tk::Text::BlockSeparator")) {
	    int level, defect;

	    SeparatorPair(inner, &level, &defect);
	    if (level < 0) {
		/*
		 * [undef, defect]: the first leaf of a block, which starts
		 * here.
		 */

		NoteLeafDefect(textPtr, &index, defect, statePtr);
		continue;
	    }
	    if (level > 0) {
		TkTextIndex start = index;

		TkTextChanged(textPtr, &index, &index);
		TkIBTreeSplit(&index, level);

		/*
		 * The separator takes the tags of the place by the
		 * insertion rule: those the list has off here come off
		 * it, as off text (InsertListText does it for level 0).
		 */

		if (TkTextMarkNameToIndex(textPtr, markName, &index2)
			== TCL_OK) {
		    for (j = 0; j < statePtr->numTags; j++) {
			if (!statePtr->tagOn[j]
				&& (TkTextIndexCmp(&start, &index2) < 0)) {
			    TkBTreeTag(&start, &index2, statePtr->tags[j], 0);
			}
		    }
		}
	    } else {
		InsertListText(textPtr, markName, &index, "\n", statePtr);
	    }

	    /*
	     * The leaf after the separator starts at the insertion point
	     * now: its defect (0 for a plain number).
	     */

	    if (TkTextMarkNameToIndex(textPtr, markName, &index) == TCL_OK) {
		NoteLeafDefect(textPtr, &index, defect, statePtr);
	    }
	} else if (sv_derived_from(elt, "Tk::Text::Block")
		|| sv_derived_from(elt, "Tk::Text::Empty")) {
	    int isEmpty = sv_derived_from(elt, "Tk::Text::Empty");
	    AV *bav = (AV *) inner;
	    AV *head = NULL;
	    SV **hp, *nameSv = NULL, *dataSv = NULL;
	    Tcl_HashEntry *hPtr;
	    TkTextBlock *blockPtr = NULL;
	    TkTextSegment *segPtr;
	    TkTextIndex tailEnd;
	    char innerMark[40];

	    if (SvTYPE((SV *) bav) != SVt_PVAV) {
		continue;
	    }
	    hp = av_fetch(bav, 0, 0);
	    if (hp == NULL) {
		continue;
	    }
	    if (isEmpty) {
		/* [type, ?data?] */
		nameSv = *hp;
		hp = av_fetch(bav, 1, 0);
		dataSv = (hp != NULL) ? *hp : NULL;
	    } else if (SvROK(*hp) && (SvTYPE(SvRV(*hp)) == SVt_PVAV)) {
		/* [[type, level, ?data?], contents...] */
		head = (AV *) SvRV(*hp);
		hp = av_fetch(head, 0, 0);
		nameSv = (hp != NULL) ? *hp : NULL;
		hp = av_fetch(head, 2, 0);
		dataSv = (hp != NULL) ? *hp : NULL;
	    }
	    if (nameSv != NULL) {
		hPtr = Tcl_FindHashEntry(&textPtr->blockTable, SvPV_nolen(nameSv));
		if (hPtr != NULL) {
		    blockPtr = (TkTextBlock *) Tcl_GetHashValue(hPtr);
		}
	    }
	    if (blockPtr == NULL) {
		/*
		 * The block type is gone: insert the contents as text.
		 */

		if (!isEmpty) {
		    InsertListElements(textPtr, markName, startMark, bav, 1,
			    statePtr);
		}
		continue;
	    }
	    if (TkBTreeLineIndex(index.linePtr)
		    == TkBTreeNumLines(textPtr->tree)) {
		/*
		 * Never on the last (dummy) line, which must stay empty:
		 * at the end of the line before it, as "insert" and
		 * "block insert" do.  (The undo of a change can come here
		 * at "end" when the indices it recorded are stale.)
		 */

		TkTextMakeByteIndex(textPtr->tree,
			TkBTreeLineIndex(index.linePtr) - 1, 1000000, &index);
	    }
	    TkTextChanged(textPtr, &index, &index);
	    if (TkBTreeMakeBlock(textPtr, &index, &index, blockPtr) != TCL_OK) {
		Tcl_ResetResult(textPtr->interp);
		continue;
	    }

	    /*
	     * The new block (its head and tail, and so what goes in it)
	     * has the tags of the place it was made in, by the insertion
	     * rule: the tags the list has off at this point come off it,
	     * as off text (InsertListText).  A deletion that joined two
	     * runs of a tag around a block gave the block the tag back.
	     */

	    TkTextIndexForwBytes(&index, isEmpty ? 1 : 2, &index2);
	    for (j = 0; j < statePtr->numTags; j++) {
		if (!statePtr->tagOn[j]) {
		    TkBTreeTag(&index, &index2, statePtr->tags[j], 0);
		}
	    }
	    segPtr = TkIBTreeAt(&index, 0);
	    if (!isEmpty && (segPtr != NULL)) {
		/*
		 * Fill the block through a mark just inside it.
		 */

		TkTextIndexForwBytes(&index, 1, &index2);
		sprintf(innerMark, "#undo%d", undoMarkCount++);
		TkTextSetMark(textPtr, innerMark, &index2);
		InsertListElements(textPtr, innerMark, startMark, bav, 1,
			statePtr);
		MarkOp(textPtr, "unset", innerMark, (char *) NULL);

		/*
		 * The count is not taken back: a pending tag's mark made
		 * inside the block has a later number, which the next
		 * mark would get again (and move, then unset).
		 */

		/*
		 * The separators make the tree only as deep as the level
		 * where all the leaves meet: a root with a single child
		 * that is not a leaf needs the depth of the header.
		 */

		if (head != NULL) {
		    hp = av_fetch(head, 1, 0);
		    if ((hp != NULL) && SvOK(*hp)) {
			TkIBTreeDeepen(segPtr, (int) SvIV(*hp));
		    }
		}

		/*
		 * The tail kept the tags the block was made with: those
		 * the list has switched off inside it come off the tail
		 * too (it belongs to the end of the contents).
		 */

		TkTextIndexForwBytes(&index, segPtr->size - 1, &index2);
		TkTextIndexForwBytes(&index2, 1, &tailEnd);
		for (j = 0; j < statePtr->numTags; j++) {
		    if (!statePtr->tagOn[j]) {
			TkBTreeTag(&index2, &tailEnd, statePtr->tags[j], 0);
		    }
		}
	    }
	    if ((segPtr != NULL) && (dataSv != NULL) && SvOK(dataSv)) {
		Arg arga[2];

		arga[0] = NULL;
		LangSetString(&arga[0], "-instancedata");
		arga[1] = dataSv;
		Tk_ConfigureWidget(textPtr->interp, textPtr->tkwin,
			blockInstanceConfigSpecs, 2, arga,
			(char *) &segPtr->body.itree, 0);
		LangFreeArg(arga[0], LANG_DYNAMIC);
		Tcl_ResetResult(textPtr->interp);
	    }
	} else if (sv_derived_from(elt, "Tk::Text::EmbImage")
		|| sv_derived_from(elt, "Tk::Text::EmbWin")) {
	    if (SvTYPE(inner) == SVt_PVAV) {
		InsertEmbedded(textPtr, markName, (AV *) inner,
			sv_derived_from(elt, "Tk::Text::EmbImage"));
	    }
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * InsertEmbedded --
 *
 *	Re-create an embedded image or window at a mark from its "block
 *	list" element: [name, option, value, ...] for an image (the
 *	name becomes its -name), [window, script, option, value, ...]
 *	for a window (see TkTextImageOptionList, TkTextWindowOptionList).
 *	If that fails, the -image or -window is left out: an image whose
 *	Tk image has been deleted comes back as an empty one ("image
 *	create -name" makes those), a window whose -window was destroyed
 *	with the segment (the widget destroys it, as in Tk) comes back
 *	without a window, with its -create script if it had one.  Either
 *	way the segment takes its unit of index space again, so that
 *	the recorded indices of the other changes stay right.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The text changes.
 *
 *----------------------------------------------------------------------
 */

static void
InsertEmbedded(textPtr, markName, av, isImage)
    TkText *textPtr;		/* Overall information about text widget. */
    char *markName;		/* The mark to insert at. */
    AV *av;			/* The element's contents. */
    int isImage;		/* Non-zero for an image, zero for a
				 * window. */
{
    Tcl_Interp *interp = textPtr->interp;
    int n = av_len(av) + 1;
    int first = isImage ? 1 : 2;	/* Where the option/value pairs
					 * start. */
    char *drop = isImage ? "-image" : "-window";
    int attempt, argc, i, code;
    Arg *args;
    SV **svp, **valp;

    args = (Arg *) ckalloc((unsigned) ((n + 6) * sizeof(Arg)));
    for (attempt = 0; attempt < 2; attempt++) {
	argc = 0;
	args[argc] = NULL;
	LangSetString(&args[argc++], Tk_PathName(textPtr->tkwin));
	args[argc] = NULL;
	LangSetString(&args[argc++], isImage ? "image" : "window");
	args[argc] = NULL;
	LangSetString(&args[argc++], "create");
	args[argc] = NULL;
	LangSetString(&args[argc++], markName);
	if (isImage) {
	    svp = av_fetch(av, 0, 0);
	    if ((svp != NULL) && SvOK(*svp) && (*SvPV_nolen(*svp) != '\0')) {
		args[argc] = NULL;
		LangSetString(&args[argc++], "-name");
		args[argc++] = newSVsv(*svp);
	    }
	}
	for (i = first; i + 1 < n; i += 2) {
	    svp = av_fetch(av, i, 0);
	    valp = av_fetch(av, i + 1, 0);
	    if ((svp == NULL) || (valp == NULL) || !SvOK(*svp)) {
		continue;
	    }
	    if ((attempt > 0) && (strcmp(SvPV_nolen(*svp), drop) == 0)) {
		continue;
	    }
	    args[argc++] = newSVsv(*svp);
	    args[argc++] = newSVsv(*valp);
	}
	code = isImage ? TkTextImageCmd(textPtr, interp, argc, args)
		: TkTextWindowCmd(textPtr, interp, argc, args);
	for (i = 0; i < argc; i++) {
	    LangFreeArg(args[i], LANG_DYNAMIC);
	}
	Tcl_ResetResult(interp);
	if (code == TCL_OK) {
	    break;
	}
    }
    ckfree((char *) args);
}
