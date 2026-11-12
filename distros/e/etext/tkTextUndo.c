/*
 * tkTextUndo.c --
 *
 *	The undo/redo stack of the eText widget ("edit undo", "edit
 *	redo", -undo, -maxundo, -autoseparators), after the design of
 *	Tk 8.4's tkUndo.c.  Where Tk records Tcl scripts, the atoms here
 *	record the change itself (insertion or deletion, its position
 *	and its text); tkText.c applies or reverts them with the
 *	widget's own insertion and deletion procedures.
 *
 * Copyright (c) 2002 by Ludwig Callewaert (the Tk design).
 * Modernization for Tk 804 (c) 2026.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 */

#include "pperl.h"
#include "default.h"
#include "tkPort.h"
#include "tkInt.h"
#include "tkText.h"

static void		PushAtom _ANSI_ARGS_((TkTextUndoAtom **stackPtr,
			    TkTextUndoAtom *atomPtr));
static TkTextUndoAtom *	PopAtom _ANSI_ARGS_((TkTextUndoAtom **stackPtr));
static int		InsertSeparator _ANSI_ARGS_((TkTextUndoAtom **stackPtr));
static void		FreeAtom _ANSI_ARGS_((TkTextUndoStack *undoPtr,
			    TkTextUndoAtom *atomPtr));
static void		ClearStack _ANSI_ARGS_((TkTextUndoStack *undoPtr,
			    TkTextUndoAtom **stackPtr));

/*
 *----------------------------------------------------------------------
 *
 * PushAtom, PopAtom, InsertSeparator, FreeAtom, ClearStack --
 *
 *	The elementary operations on one stack (a linked list whose
 *	head is the top).  The values an atom holds (see TkTextValue)
 *	go to the widget's list of values to free when the widget
 *	command ends: an atom is discarded in the middle of a command.
 *
 *----------------------------------------------------------------------
 */

static void
PushAtom(stackPtr, atomPtr)
    TkTextUndoAtom **stackPtr;		/* The stack. */
    TkTextUndoAtom *atomPtr;		/* Becomes its top. */
{
    atomPtr->nextPtr = *stackPtr;
    *stackPtr = atomPtr;
}

static TkTextUndoAtom *
PopAtom(stackPtr)
    TkTextUndoAtom **stackPtr;		/* The stack. */
{
    TkTextUndoAtom *atomPtr = *stackPtr;

    if (atomPtr != NULL) {
	*stackPtr = atomPtr->nextPtr;
    }
    return atomPtr;
}

static int
InsertSeparator(stackPtr)
    TkTextUndoAtom **stackPtr;		/* The stack. */
{
    TkTextUndoAtom *atomPtr;

    if ((*stackPtr == NULL) || ((*stackPtr)->type == TK_TEXT_UNDO_SEPARATOR)) {
	return 0;
    }
    atomPtr = (TkTextUndoAtom *) ckalloc(sizeof(TkTextUndoAtom));
    atomPtr->type = TK_TEXT_UNDO_SEPARATOR;
    atomPtr->string = NULL;
    atomPtr->list = NULL;
    atomPtr->remains = 0;
    atomPtr->cuts = NULL;
    atomPtr->numHeads = atomPtr->numTails = 0;
    atomPtr->levels = NULL;
    atomPtr->numLevels = 0;
    atomPtr->defects = NULL;
    atomPtr->numDefects = 0;
    atomPtr->wraps = NULL;
    atomPtr->roots = NULL;
    atomPtr->level = atomPtr->added = atomPtr->numRanges = 0;
    atomPtr->ranges = NULL;
    TkTextDataInit(atomPtr->data);
    atomPtr->values = NULL;
    atomPtr->displaced = NULL;
    PushAtom(stackPtr, atomPtr);
    return 1;
}

static void
FreeAtom(undoPtr, atomPtr)
    TkTextUndoStack *undoPtr;		/* The stacks the atom was on. */
    TkTextUndoAtom *atomPtr;		/* Atom to release. */
{
    if (atomPtr->string != NULL) {
	Tcl_DecrRefCount(atomPtr->string);
    }
    if (atomPtr->list != NULL) {
	Tcl_DecrRefCount(atomPtr->list);
    }
    if (atomPtr->cuts != NULL) {
	ckfree((char *) atomPtr->cuts);
    }
    if (atomPtr->levels != NULL) {
	ckfree((char *) atomPtr->levels);
    }
    if (atomPtr->defects != NULL) {
	ckfree((char *) atomPtr->defects);
    }
    if (atomPtr->wraps != NULL) {
	ckfree((char *) atomPtr->wraps);
    }
    if (atomPtr->roots != NULL) {
	ckfree((char *) atomPtr->roots);
    }
    if (atomPtr->ranges != NULL) {
	ckfree(atomPtr->ranges);
    }
    if (!TkTextDataIsEmpty(atomPtr->data)) {
	/*
	 * The instance data of a block insert's block (its head is at
	 * index1), kept by the undo for the redo.
	 */

	Tcl_Obj *where = NULL;

	if (TkTextVcOn(undoPtr->textPtr)) {
	    where = Tcl_NewListObj(0, NULL);
	    Tcl_ListObjAppendElement(NULL, where,
		    Tcl_NewStringObj(atomPtr->index1, -1));
	}
	TkTextDiscardValueAt(undoPtr->textPtr, atomPtr->data,
		TK_TEXT_VC_BLOCK, where);
    }
    if (atomPtr->values != NULL) {
	TkTextDiscardValueList(undoPtr->textPtr, atomPtr->values);
    }
    if (atomPtr->displaced != NULL) {
	TkTextDiscardValueList(undoPtr->textPtr, atomPtr->displaced);
    }
    ckfree((char *) atomPtr);
}

static void
ClearStack(undoPtr, stackPtr)
    TkTextUndoStack *undoPtr;		/* The stacks. */
    TkTextUndoAtom **stackPtr;		/* The stack to empty. */
{
    TkTextUndoAtom *atomPtr;

    while ((atomPtr = PopAtom(stackPtr)) != NULL) {
	FreeAtom(undoPtr, atomPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextUndoInitStack, TkTextUndoFreeStack, TkTextUndoClearStacks --
 *
 *	Create, destroy and empty the pair of stacks of a widget.
 *
 *----------------------------------------------------------------------
 */

TkTextUndoStack *
TkTextUndoInitStack(maxdepth)
    int maxdepth;			/* Maximum number of compound actions
					 * to keep; <= 0 means no limit. */
{
    TkTextUndoStack *stackPtr;

    stackPtr = (TkTextUndoStack *) ckalloc(sizeof(TkTextUndoStack));
    stackPtr->undoStack = NULL;
    stackPtr->redoStack = NULL;
    stackPtr->maxdepth = maxdepth;
    stackPtr->depth = 0;
    stackPtr->textPtr = NULL;
    return stackPtr;
}

void
TkTextUndoClearStacks(stackPtr)
    TkTextUndoStack *stackPtr;		/* The stacks. */
{
    ClearStack(stackPtr, &stackPtr->undoStack);
    ClearStack(stackPtr, &stackPtr->redoStack);
    stackPtr->depth = 0;
}

void
TkTextUndoFreeStack(stackPtr)
    TkTextUndoStack *stackPtr;		/* The stacks. */
{
    TkTextUndoClearStacks(stackPtr);
    ckfree((char *) stackPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextUndoSetDepth --
 *
 *	Set the maximum number of compound actions kept on the undo
 *	stack, dropping the oldest ones if there are too many.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Atoms may be freed.
 *
 *----------------------------------------------------------------------
 */

void
TkTextUndoSetDepth(stackPtr, maxdepth)
    TkTextUndoStack *stackPtr;		/* The stacks. */
    int maxdepth;			/* The new limit; <= 0 means none. */
{
    TkTextUndoAtom *atomPtr, *prevPtr;
    int separators = 0;

    stackPtr->maxdepth = maxdepth;
    if ((maxdepth <= 0) || (stackPtr->depth <= maxdepth)) {
	return;
    }

    /*
     * Keep everything up to and including the maxdepth-th separator
     * (counting from the top), i.e. maxdepth compound actions, and
     * free the rest.
     */

    prevPtr = NULL;
    for (atomPtr = stackPtr->undoStack; atomPtr != NULL;
	    prevPtr = atomPtr, atomPtr = atomPtr->nextPtr) {
	if (atomPtr->type == TK_TEXT_UNDO_SEPARATOR) {
	    separators++;
	    if (separators > maxdepth) {
		break;
	    }
	}
    }
    if (atomPtr == NULL) {
	return;
    }
    if (prevPtr == NULL) {
	stackPtr->undoStack = NULL;
    } else {
	prevPtr->nextPtr = NULL;
    }
    ClearStack(stackPtr, &atomPtr);
    stackPtr->depth = maxdepth;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextUndoInsertUndoSeparator --
 *
 *	Mark the boundary of a compound action on the undo stack ("edit
 *	separator", or -autoseparators between insertions and deletions).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The depth may grow, and the oldest actions may be dropped.
 *
 *----------------------------------------------------------------------
 */

void
TkTextUndoInsertUndoSeparator(stackPtr)
    TkTextUndoStack *stackPtr;		/* The stacks. */
{
    if (InsertSeparator(&stackPtr->undoStack)) {
	stackPtr->depth++;
	TkTextUndoSetDepth(stackPtr, stackPtr->maxdepth);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextUndoPushAction --
 *
 *	Record an insertion or a deletion on the undo stack.  The redo
 *	stack is emptied: there is nothing to redo after a new change.
 *
 * Results:
 *	The new atom (where the caller records the values the change
 *	drops, see TkTextValue).
 *
 * Side effects:
 *	Memory is allocated; the atom owns the string from now on.
 *
 *----------------------------------------------------------------------
 */

TkTextUndoAtom *
TkTextUndoPushAction(stackPtr, type, index1, index2, string, list, listIndex,
	remains)
    TkTextUndoStack *stackPtr;		/* The stacks. */
    int type;				/* TK_TEXT_UNDO_INSERT or
					 * TK_TEXT_UNDO_DELETE. */
    char *index1;			/* Where the change starts. */
    char *index2;			/* Where the changed text ends. */
    Tcl_Obj *string;			/* The text inserted or deleted; the
					 * stack takes over the reference. */
    Tcl_Obj *list;			/* The deleted contents as a list (see
					 * TkTextUndoAtom), or NULL; owned by
					 * the stack from now on. */
    char *listIndex;			/* Where the list goes back on undo,
					 * or NULL for index1. */
    int remains;			/* What the deletion left of the blocks
					 * it cut, in bytes of index space (see
					 * TkTextUndoAtom); 0 if none. */
{
    TkTextUndoAtom *atomPtr;

    atomPtr = (TkTextUndoAtom *) ckalloc(sizeof(TkTextUndoAtom));
    atomPtr->type = type;
    strncpy(atomPtr->index1, index1, TK_POS_CHARS - 1);
    atomPtr->index1[TK_POS_CHARS - 1] = 0;
    strncpy(atomPtr->index2, index2, TK_POS_CHARS - 1);
    atomPtr->index2[TK_POS_CHARS - 1] = 0;
    strncpy(atomPtr->listIndex, (listIndex != NULL) ? listIndex : index1,
	    TK_POS_CHARS - 1);
    atomPtr->listIndex[TK_POS_CHARS - 1] = 0;
    atomPtr->string = string;
    atomPtr->list = list;
    atomPtr->remains = remains;
    atomPtr->cuts = NULL;
    atomPtr->numHeads = atomPtr->numTails = 0;
    atomPtr->levels = NULL;
    atomPtr->numLevels = 0;
    atomPtr->defects = NULL;
    atomPtr->numDefects = 0;
    atomPtr->wraps = NULL;
    atomPtr->roots = NULL;
    atomPtr->level = atomPtr->added = atomPtr->numRanges = 0;
    atomPtr->ranges = NULL;
    TkTextDataInit(atomPtr->data);
    atomPtr->values = NULL;
    atomPtr->displaced = NULL;
    PushAtom(&stackPtr->undoStack, atomPtr);
    ClearStack(stackPtr, &stackPtr->redoStack);
    return atomPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextUndoRevert, TkTextUndoApply --
 *
 *	Undo (revert) or redo (apply) one compound action: every atom
 *	down to the next separator, moving them to the other stack.
 *
 * Results:
 *	TCL_OK, or TCL_ERROR if there was nothing to do.
 *
 * Side effects:
 *	The text changes (through TkTextEditAction).
 *
 *----------------------------------------------------------------------
 */

int
TkTextUndoRevert(textPtr)
    TkText *textPtr;			/* The widget, with its stacks. */
{
    TkTextUndoStack *stackPtr = textPtr->undoStack;
    TkTextUndoAtom *atomPtr;

    TkTextUndoInsertUndoSeparator(stackPtr);
    InsertSeparator(&stackPtr->redoStack);
    atomPtr = PopAtom(&stackPtr->undoStack);
    if (atomPtr == NULL) {
	return TCL_ERROR;
    }
    if (atomPtr->type == TK_TEXT_UNDO_SEPARATOR) {
	FreeAtom(stackPtr, atomPtr);
	atomPtr = PopAtom(&stackPtr->undoStack);
    }
    while ((atomPtr != NULL) && (atomPtr->type != TK_TEXT_UNDO_SEPARATOR)) {
	TkTextEditAction(textPtr, atomPtr, 1);
	PushAtom(&stackPtr->redoStack, atomPtr);
	atomPtr = PopAtom(&stackPtr->undoStack);
    }
    if (atomPtr != NULL) {
	FreeAtom(stackPtr, atomPtr);		/* The separator just passed. */
    }
    InsertSeparator(&stackPtr->redoStack);
    stackPtr->depth--;
    return TCL_OK;
}

int
TkTextUndoApply(textPtr)
    TkText *textPtr;			/* The widget, with its stacks. */
{
    TkTextUndoStack *stackPtr = textPtr->undoStack;
    TkTextUndoAtom *atomPtr;

    InsertSeparator(&stackPtr->undoStack);
    atomPtr = PopAtom(&stackPtr->redoStack);
    if (atomPtr == NULL) {
	return TCL_ERROR;
    }
    if (atomPtr->type == TK_TEXT_UNDO_SEPARATOR) {
	FreeAtom(stackPtr, atomPtr);
	atomPtr = PopAtom(&stackPtr->redoStack);
    }
    while ((atomPtr != NULL) && (atomPtr->type != TK_TEXT_UNDO_SEPARATOR)) {
	TkTextEditAction(textPtr, atomPtr, 0);
	PushAtom(&stackPtr->undoStack, atomPtr);
	atomPtr = PopAtom(&stackPtr->redoStack);
    }
    if (atomPtr != NULL) {
	FreeAtom(stackPtr, atomPtr);
    }
    InsertSeparator(&stackPtr->undoStack);
    stackPtr->depth++;
    return TCL_OK;
}
