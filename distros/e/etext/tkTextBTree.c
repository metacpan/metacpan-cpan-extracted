/* 
 * tkTextBTree.c --
 *
 *	This file contains code that manages the B-tree representation
 *	of text for Tk's text widget and implements character and
 *	toggle segment types.
 *
 * Copyright (c) 1992-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 * Copyright (c) 1995 Ilya Zakharevich.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tkTextBTree.c 1.35 96/03/21 15:51:39
 */

#include "pperl.h"
#include "tkInt.h"
#include "tkPort.h"
#include "tkText.h"

/* @(#) $Id: tkTextBTree.c,v 1.43 1996/05/21 00:55:36 ilya Exp $ */

/*
 * The data structure below keeps summary information about one tag as part
 * of the tag information in a node.
 */

typedef struct Summary {
    TkTextTag *tagPtr;			/* Handle for tag. */
    int toggleCount;			/* Number of transitions into or
					 * out of this tag that occur in
					 * the subtree rooted at this
					 * node. Note that a tag may
					 * start in one internal tree,
					 * and end in another, so the
					 * count may be odd in internal
					 * trees.  */
    struct Summary *nextPtr;		/* Next in list of all tags for same
					 * node, or NULL if at end of list. */
} Summary;

/* Data structure below is used to return a pair of a segment and a
 * line that contains it. */

typedef struct SegLine {
  TkTextSegment *segPtr;		/* Pointer to segment */
  TkTextLine *linePtr;			/* Contains pointer to the
					 * line that contains the segment */
} SegLine;

/*
 * The data structure below defines a node in the B-tree.
 */

typedef struct Node {
    struct Node *parentPtr;		/* Pointer to parent node, or NULL if
					 * this is the root. */
    struct Node *nextPtr;		/* Next in list of siblings with the
					 * same parent node, or NULL for end
					 * of list. */
    Summary *summaryPtr;		/* First in malloc-ed list of info
					 * about tags in this subtree (NULL if
					 * no tag info in the subtree). */
    int level;				/* Level of this node in the B-tree.
					 * 0 refers to the bottom of the tree
					 * (children are lines, not nodes). */
    union {				/* First in linked list of children. */
	struct Node *nodePtr;		/* Used if level > 0. */
	TkTextLine *linePtr;		/* Used if level == 0. */
    } children;
    int numChildren;			/* Number of children of this node. */
    int numLines;			/* Total number of lines (leaves) in
					 * the subtree rooted here. */
    TkTextSegment *segPtr;		/* NULL if this node is in the
					 * outermost tree, otherwise
					 * the text segment of type IBTree that
					 * contains the tree. */
    TkTextData value;			/* The data of the node (its Lang
					 * part: "block nodedata"), owned by
					 * the node; empty if none.  Always
					 * empty in the outermost tree. */
} Node;

/*
 * The address of a node before a deletion that can be undone, as
 * TkBTreeSnapshotValues records it (see TkTextValue in tkText.h):
 */

typedef struct ValueAddress {
    int line;				/* Line number in the outermost tree. */
    int byteIndex;			/* Byte offset there of the start of
					 * the node's first leaf. */
    int level;				/* 0 for a leaf, 1 for its parent... */
} ValueAddress;

/*
 * Upper and lower bounds on how many children a node may have:
 * rebalance when either of these limits is exceeded.  MAX_CHILDREN
 * should be twice MIN_CHILDREN and MIN_CHILDREN must be >= 2.
 */

#define MAX_CHILDREN 12
#define MIN_CHILDREN 6

/*
 * The data structure below defines an entire B-tree.
 */

typedef struct BTree {
    Node *rootPtr;			/* Pointer to root of B-tree. */
    TkText *textPtr;			/* Used to find tagTable in consistency
					 * checking code */
} BTree;

/*
 * The structure below is used to pass information between
 * TkBTreeGetTags and IncCount:
 */

typedef struct TagInfo {
    int numTags;			/* Number of tags for which there
					 * is currently information in
					 * tags and counts. */
    int arraySize;			/* Number of entries allocated for
					 * tags and counts. */
    TkTextTag **tagPtrs;		/* Array of tags seen so far.
					 * Malloc-ed. */
    int *counts;			/* Toggle count (so far) for each
					 * entry in tags.  Malloc-ed. */
} TagInfo;

/*
 * Variable that indicates whether to enable consistency checks for
 * debugging.
 */

int tkBTreeDebug = 0;

/*
 * Macros that determine how much space to allocate for new segments:
 */

#define CSEG_SIZE(chars) ((unsigned) (Tk_Offset(TkTextSegment, body) \
	+ 1 + (chars)))
#define TSEG_SIZE ((unsigned) (Tk_Offset(TkTextSegment, body) \
	+ sizeof(TkTextToggle)))
#define BSEG_SIZE ((unsigned) (Tk_Offset(TkTextSegment, body) \
	+ sizeof(TkTextITree)))

/*
 * Forward declarations for procedures defined in this file:
 */

static void		ChangeNodeToggleCount _ANSI_ARGS_((Node *nodePtr,
			    TkTextTag *tagPtr, int delta));
static void		CharCheckProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static int		CharDeleteProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr, int treeGone));
static TkTextSegment *	CharCleanupProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static TkTextSegment *	CharSplitProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    int index));
static void		CheckNodeConsistency _ANSI_ARGS_((Node *nodePtr));
static void		CleanupLine _ANSI_ARGS_((TkTextLine *linePtr));
static void		DeleteSummaries _ANSI_ARGS_((Summary *tagPtr));
static void		DestroyNode _ANSI_ARGS_((Node *nodePtr));
static void		IncCount _ANSI_ARGS_((TkTextTag *tagPtr, int inc,
			    TagInfo *tagInfoPtr));
static void		Rebalance _ANSI_ARGS_((BTree *treePtr, Node *nodePtr));
static void		RecomputeNodeCounts _ANSI_ARGS_((Node *nodePtr));
static SegLine		SplitSeg _ANSI_ARGS_((TkTextIndex *indexPtr));
static void		IBtreeUpdateLength _ANSI_ARGS_((TkTextSegment *segPtr,
							int incr));
static void		ToggleCheckProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static TkTextSegment *	ToggleCleanupProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static int		ToggleDeleteProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr, int treeGone));
static void		ToggleLineChangeProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static void		iBTreeCheckProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static int		iBTreeDeleteProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr, int treeGone));
static TkTextSegment *	iBTreeCleanupProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
static void		iBTreeLineChangeProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
void			TkBTreeKillBlockProc _ANSI_ARGS_((
			    TkTextSegment *segPtr));
void			NodeReport _ANSI_ARGS_((
			    Node *nodePtr, ListFactory *listFactory, 
			    int linesLeft));
static TkTextSegment *	FindTagStart _ANSI_ARGS_((TkTextBTree tree,
			    TkTextTag *tagPtr, TkTextIndex *indexPtr, 
			    TkTextIndex *intIndexPtr));
static void		GlueLines(TkTextSegment *seg1Ptr,
				  TkTextSegment *seg2Ptr, TkTextLine
				  *linePtr, TkTextSegment *prevPtr);
static void		NodePrint(Node *nodePtr, 
				  ListFactory *listFactoryPtr, 
				  struct DLine **linePtrs, 
				  int linesLeft, int levels, int *widthsMin,
				  int *widthsMax, int widthsNum);
TkTextLine *		TkIBTreeLastLine(TkTextSegment *segPtr);
static TkText *		NodeText _ANSI_ARGS_((Node *nodePtr));
static void		DropValue _ANSI_ARGS_((TkText *textPtr, void *objPtr,
			    TkTextData *valuePtr));
static void		DropBlockData _ANSI_ARGS_((TkTextSegment *segPtr));
static void		DropTreeValues _ANSI_ARGS_((TkText *textPtr,
			    Node *nodePtr));
static void		MergeValues _ANSI_ARGS_((TkText *textPtr,
			    void *keepObjPtr, TkTextData *keepPtr,
			    void *loseObjPtr, TkTextData *losePtr));
static int		IsLastLine _ANSI_ARGS_((TkTextLine *linePtr));
static TkTextValue *	NewValueRecord _ANSI_ARGS_((int kind,
			    TkTextData value));
static void		UnlinkLine _ANSI_ARGS_((TkText *textPtr,
			    TkTextLine *linePtr, TkTextLine *prevHintPtr));
static int		NodeHasValues _ANSI_ARGS_((Node *nodePtr));
static void		TagRange _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextTag *tagPtr,
			    int add));
static void		DeleteRange _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, int rebalance,
			    int check4trees));
static void		DeleteKeepingRuns _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr));
static void		DropToggleValue _ANSI_ARGS_((TkTextSegment *segPtr));
static char *		CopyName _ANSI_ARGS_((char *name));
static TkTextSegment *	RunAtAddress _ANSI_ARGS_((TkText *textPtr,
			    TkTextTag *tagPtr, int line, int byteIndex,
			    TkTextIndex *startPtr));
static void		TagKeepingRuns _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextTag *tagPtr,
			    int add));
static void		NodeValuesList _ANSI_ARGS_((Node *nodePtr,
			    ListFactory *lfPtr));

/*
 * Type record for character segments:
 */

Tk_SegType tkTextCharType = {
    "character",				/* name */
    0,						/* leftGravity */
    CharSplitProc,				/* splitProc */
    CharDeleteProc,				/* deleteProc */
    CharCleanupProc,				/* cleanupProc */
    (Tk_SegLineChangeProc *) NULL,		/* lineChangeProc */
    TkTextCharLayoutProc,			/* layoutProc */
    CharCheckProc				/* checkProc */
};

/*
 * Type record for segments marking the beginning of a tagged
 * range:
 */

Tk_SegType tkTextToggleOnType = {
    "toggleOn",					/* name */
    0,						/* leftGravity */
    (Tk_SegSplitProc *) NULL,			/* splitProc */
    ToggleDeleteProc,				/* deleteProc */
    ToggleCleanupProc,				/* cleanupProc */
    ToggleLineChangeProc,			/* lineChangeProc */
    (Tk_SegLayoutProc *) NULL,			/* layoutProc */
    ToggleCheckProc				/* checkProc */
};

/*
 * Type record for segments marking the end of a tagged
 * range:
 */

Tk_SegType tkTextToggleOffType = {
    "toggleOff",				/* name */
    1,						/* leftGravity */
    (Tk_SegSplitProc *) NULL,			/* splitProc */
    ToggleDeleteProc,				/* deleteProc */
    ToggleCleanupProc,				/* cleanupProc */
    ToggleLineChangeProc,			/* lineChangeProc */
    (Tk_SegLayoutProc *) NULL,			/* layoutProc */
    ToggleCheckProc				/* checkProc */
};

/*
 * Type record for segments containing an internal BTree:
 */

Tk_SegType tkTextIBTreeType = {
    "iBTree",				        /* name */
    0,						/* leftGravity */
    (Tk_SegSplitProc *) NULL,			/* splitProc */
    iBTreeDeleteProc,				/* deleteProc */
    iBTreeCleanupProc,				/* cleanupProc */
    iBTreeLineChangeProc,			/* lineChangeProc */
    TkTextIBTreeLayoutProc,			/* layoutProc */
    iBTreeCheckProc				/* checkProc */
};

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeCreate --
 *
 *	This procedure is called to create a new text B-tree.
 *
 * Results:
 *	The return value is a pointer to a new B-tree containing
 *	one line with nothing but a newline character. The segPtr
 *      field is initially NULL.
 *
 * Side effects:
 *	Memory is allocated and initialized.
 *
 *----------------------------------------------------------------------
 */

TkTextBTree
TkBTreeCreate(textPtr)
    TkText *textPtr;
{
    register BTree *treePtr;
    register Node *rootPtr;
    register TkTextLine *linePtr, *linePtr2;
    register TkTextSegment *segPtr;

    /*
     * The tree will initially have two empty lines.  The second line
     * isn't actually part of the tree's contents, but its presence
     * makes several operations easier.  The tree will have one node,
     * which is also the root of the tree.
     */

    rootPtr = (Node *) ckalloc(sizeof(Node));
    linePtr = (TkTextLine *) ckalloc(sizeof(TkTextLine));
    linePtr2 = (TkTextLine *) ckalloc(sizeof(TkTextLine));
    rootPtr->parentPtr = NULL;
    rootPtr->nextPtr = NULL;
    rootPtr->summaryPtr = NULL;
    rootPtr->level = 0;
    rootPtr->children.linePtr = linePtr;
    rootPtr->numChildren = 2;
    rootPtr->numLines = 2;
    rootPtr->segPtr = NULL;
    TkTextDataInit(rootPtr->value);

    linePtr->parentPtr = rootPtr;
    linePtr->nextPtr = linePtr2;
    TkTextDataInit(linePtr->value);
    TkTextDataInit(linePtr2->value);
    segPtr = (TkTextSegment *) ckalloc(CSEG_SIZE(1));
    linePtr->segPtr = segPtr;
    segPtr->typePtr = &tkTextCharType;
    segPtr->nextPtr = NULL;
    segPtr->size = 1;
    segPtr->body.chars[0] = '\n';
    segPtr->body.chars[1] = 0;

    linePtr2->parentPtr = rootPtr;
    linePtr2->nextPtr = NULL;
    segPtr = (TkTextSegment *) ckalloc(CSEG_SIZE(1));
    linePtr2->segPtr = segPtr;
    segPtr->typePtr = &tkTextCharType;
    segPtr->nextPtr = NULL;
    segPtr->size = 1;
    segPtr->body.chars[0] = '\n';
    segPtr->body.chars[1] = 0;

    treePtr = (BTree *) ckalloc(sizeof(BTree));
    treePtr->rootPtr = rootPtr;
    treePtr->textPtr = textPtr;

    return (TkTextBTree) treePtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeDestroy --
 *
 *	Delete a B-tree, recycling all of the storage it contains.
 *
 * Results:
 *	The tree given by treePtr is deleted.  TreePtr should never
 *	again be used.
 *
 * Side effects:
 *	Memory is freed.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeDestroy(tree)
    TkTextBTree tree;			/* Pointer to tree to delete. */ 
{
    BTree *treePtr = (BTree *) tree;

    DestroyNode(treePtr->rootPtr);
    ckfree((char *) treePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * DestroyNode --
 *
 *	This is a recursive utility procedure used during the deletion
 *	of a B-tree.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	All the storage for nodePtr and its descendants is freed.
 *
 *----------------------------------------------------------------------
 */

static void
DestroyNode(nodePtr)
    register Node *nodePtr;
{
    if (!TkTextDataIsEmpty(nodePtr->value)) {
	DropValue(NodeText(nodePtr), (void *) nodePtr, &nodePtr->value);
    }
    if (nodePtr->level == 0) {
	TkTextLine *linePtr;
	TkTextSegment *segPtr;

	while (nodePtr->children.linePtr != NULL) {
	    linePtr = nodePtr->children.linePtr;
	    nodePtr->children.linePtr = linePtr->nextPtr;
	    if (!TkTextDataIsEmpty(linePtr->value)) {
		DropValue(NodeText(nodePtr), (void *) linePtr, &linePtr->value);
	    }
	    while (linePtr->segPtr != NULL) {
		segPtr = linePtr->segPtr;
		linePtr->segPtr = segPtr->nextPtr;
		(*segPtr->typePtr->deleteProc)(segPtr, linePtr, 1);
	    }
	    ckfree((char *) linePtr);
	}
    } else {
	register Node *childPtr;

	while (nodePtr->children.nodePtr != NULL) {
	    childPtr = nodePtr->children.nodePtr;
	    nodePtr->children.nodePtr = childPtr->nextPtr;
	    DestroyNode(childPtr);
	}
    }
    DeleteSummaries(nodePtr->summaryPtr);
    ckfree((char *) nodePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * DeleteSummaries --
 *
 *	Free up all of the memory in a list of tag summaries associated
 *	with a node.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Storage is released.
 *
 *----------------------------------------------------------------------
 */

static void
DeleteSummaries(summaryPtr)
    register Summary *summaryPtr;	/* First in list of node's tag
					 * summaries. */
{
    register Summary *nextPtr;
    while (summaryPtr != NULL) {
	nextPtr = summaryPtr->nextPtr;
	ckfree((char *) summaryPtr);
	summaryPtr = nextPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexToInternalSeg --
 *
 *	Given a position in the BTree finds the innermost Segment that
 *      contains the character. 
 *
 * Results:
 *	Returns segment pointer, fills variables pointed to by
 *      intIndexPtr and offsetPtr by the index inside the internal tree and
 *      offset inside segment.
 *
 * Side effects:
 *	*linePtrPtr is filled with the innermost line that contains
 *      it, *offsetPtr with offset inside segment if offsetPtr is
 *      non-NULL, *charIndexPtr with offset inside the Line.
 *
 *----------------------------------------------------------------------
 */

TkTextSegment *
TkTextIndexToInternalSeg(indexPtr, intIndexPtr, offsetPtr)
    register TkTextIndex *indexPtr;	/* Given position. */
    register TkTextIndex *intIndexPtr;	/* Filled with index inside
					 * the internal tree. */
    register int *offsetPtr;		/* Fill with offset. */
{
    TkTextSegment *segPtr;
    TkTextIndex index = *indexPtr;
    int offset, length;

    while (1) {
      segPtr = TkTextIndexToSeg(&index, &offset); /* offsetPtr can be null */
      if (segPtr->typePtr != &tkTextIBTreeType || offset == 0) {
	if (intIndexPtr) *intIndexPtr = index;
	if (offsetPtr) *offsetPtr = offset;
	return segPtr;
      }
      index.tree = segPtr->body.itree.tree;
      index.linePtr = TkBTreeFindLine(segPtr->body.itree.tree,0);
      index.byteIndex = offset - 1;	/* -1 since one index per
					 * block is dummy */
      while (1) {
	length = TkBTreeCharsInLine(index.linePtr);
	if (index.byteIndex < length) {
	  break;
	}
	index.byteIndex -= length;
	index.linePtr = TkBTreeNextLine(index.linePtr);
      }
    }
}

/*
 *------------------------------------------------------------------
 *
 * TkTextIndexToExternalIndex
 *
 * 	Converts an index to an external form
 *
 * Results:
 * 	Index pointed to by resIndexPtr is filled with the new data.
 *
 * Side effects.
 * 	None.
 *
 *----------------------------------------
 */

void		
TkTextIndexToExternalIndex(tree, indexPtr, resIndexPtr)
     TkTextBTree tree;			/* The tree to use. */
     TkTextIndex *indexPtr;		/* The internal index. */
     TkTextIndex *resIndexPtr;		/* The index to fill. Can
					 * coincide with indexPtr. */
{
  TkTextIndex index = *indexPtr;

  index.tree = tree;
  while (index.linePtr->parentPtr->segPtr) {
    TkTextLine *linePtr = index.linePtr->parentPtr->segPtr->body.itree.linePtr;
    TkTextLine *prevPtr;
    TkTextSegment *segPtr = linePtr->segPtr;

    /* Now the lines before the line index.linePtr. */
    tree = index.linePtr->parentPtr->segPtr->body.itree.tree;
    for (prevPtr = TkBTreeFindLine(tree, 0) ; 
	 prevPtr != index.linePtr; prevPtr = TkBTreeNextLine(prevPtr)) {
      index.byteIndex += TkBTreeCharsInLine(prevPtr);      
    }
    index.byteIndex++;			/* Dummy character. */
    /* Now the segments before the IBTree. */
    for (; segPtr != index.linePtr->parentPtr->segPtr; 
	 segPtr = segPtr->nextPtr) {
      index.byteIndex += segPtr->size;
    }
    index.linePtr = index.linePtr->parentPtr->segPtr->body.itree.linePtr;
  }
  *resIndexPtr = index;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeInsertChars --
 *
 *	Insert characters at a given position in a B-tree.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Characters are added to the B-tree at the given position.
 *	If the string contains newlines, new lines will be added,
 *	which could cause the structure of the B-tree to change.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeInsertChars(indexPtr, string)
    register TkTextIndex *indexPtr;	/* Indicates where to insert text.
					 * When the procedure returns, this
					 * index is no longer valid because
					 * of changes to the segment
					 * structure. */
    char *string;			/* Pointer to bytes to insert (may
					 * contain newlines, must be null-
					 * terminated). */
{
    register Node *nodePtr;
    register TkTextSegment *prevPtr;	/* The segment just before the first
					 * new segment (NULL means new segment
					 * is at beginning of line). */
    TkTextSegment *curPtr;		/* Current segment;  new characters
					 * are inserted just after this one. 
					 * NULL means insert at beginning of
					 * line. */
    TkTextLine *linePtr;		/* Current line (new segments are
					 * added to this line). */
    register TkTextSegment *segPtr;
    TkTextLine *newLinePtr;
    int chunkSize;			/* # characters in current chunk. */
    register char *eol;			/* Pointer to character just after last
					 * one in current chunk. */
    int changeToLineCount;		/* Counts change to total number of
					 * lines in file. */
    SegLine pSegment;			/* The segment and line of the
					 * previous segment */

    pSegment = SplitSeg(indexPtr);
    prevPtr = pSegment.segPtr;
    linePtr = pSegment.linePtr;
    curPtr = prevPtr;

    if (pSegment.linePtr->parentPtr->segPtr) {
      IBtreeUpdateLength(pSegment.linePtr->parentPtr->segPtr,
			 strlen(string));
    }

    /*
     * Chop the string up into lines and create a new segment for
     * each line, plus a new line for the leftovers from the
     * previous line.
     */

    changeToLineCount = 0;
    while (*string != 0) {
	for (eol = string; *eol != 0; eol++) {
	    if (*eol == '\n') {
		eol++;
		break;
	    }
	}
	chunkSize = eol-string;
	segPtr = (TkTextSegment *) ckalloc(CSEG_SIZE(chunkSize));
	segPtr->typePtr = &tkTextCharType;
	if (curPtr == NULL) {
	    segPtr->nextPtr = linePtr->segPtr;
	    linePtr->segPtr = segPtr;
	} else {
	    segPtr->nextPtr = curPtr->nextPtr;
	    curPtr->nextPtr = segPtr;
	}
	segPtr->size = chunkSize;
	strncpy(segPtr->body.chars, string, (size_t) chunkSize);
	segPtr->body.chars[chunkSize] = 0;
	curPtr = segPtr;

	if (eol[-1] != '\n') {
	    break;
	}

	/*
	 * The chunk ended with a newline, so create a new TkTextLine
	 * and move the remainder of the old line to it.
	 */

	newLinePtr = (TkTextLine *) ckalloc(sizeof(TkTextLine));
	TkTextDataInit(newLinePtr->value);	/* The part after the cut starts
					 * without a value. */
	newLinePtr->parentPtr = linePtr->parentPtr;
	newLinePtr->nextPtr = linePtr->nextPtr;
	linePtr->nextPtr = newLinePtr;
	newLinePtr->segPtr = segPtr->nextPtr;
	segPtr->nextPtr = NULL;
	linePtr = newLinePtr;
	curPtr = NULL;
	changeToLineCount++;

	string = eol;
    }

    /* If added new lines send the linechange signal to the rest of line. */

    if (changeToLineCount) {
      TkTextSegment *nextPtr;
      for (nextPtr = curPtr ? curPtr->nextPtr : linePtr->segPtr; 
	   nextPtr; nextPtr = nextPtr->nextPtr) {
	if (nextPtr->typePtr->lineChangeProc != NULL) {
	  (*nextPtr->typePtr->lineChangeProc)(nextPtr, pSegment.linePtr);
	}
      }
    }
    /*
     * Cleanup the starting line for the insertion, plus the ending
     * line if it's different.
     */

    CleanupLine(pSegment.linePtr);
    if (linePtr != indexPtr->linePtr) {
	CleanupLine(linePtr);
    }

    /*
     * Increment the line counts in all the parent nodes of the insertion
     * point, then rebalance the tree if necessary.
     */

    for (nodePtr = linePtr->parentPtr ; nodePtr != NULL;
	    nodePtr = nodePtr->parentPtr) {
	nodePtr->numLines += changeToLineCount;
    }
    nodePtr = linePtr->parentPtr;
    nodePtr->numChildren += changeToLineCount;
    if (nodePtr->numChildren > MAX_CHILDREN && !nodePtr->segPtr) {
	Rebalance((BTree *) indexPtr->tree, nodePtr);
    }

    if (tkBTreeDebug) {
	TkBTreeCheck(nodePtr->segPtr 
		     ? nodePtr->segPtr->body.itree.tree 
		     : indexPtr->tree);
    }
}

/*
 *--------------------------------------------------------------
 *
 * SegToIntSeg --
 *
 *	This procedure converts a pair of segment and offset to the
 * pair that describes the same position but the segment is the
 * innermost posible.
 *
 * Results:
 *      None.
 * 
 * Side effects:
 *      The 
 *
 *--------------------------------------------------------------
 */


/*
 *--------------------------------------------------------------
 *
 * IBtreeUpdateLength --
 *
 *	This procedure updates length of the segment of type IBTree
 * and of all its parents of the same type.
 *
 * Results:
 *      None.
 * 
 * Side effects:
 *      The size field is incremented on given amount (can be negative).
 *
 *--------------------------------------------------------------
 */

static void
IBtreeUpdateLength(segPtr,incr)
     TkTextSegment *segPtr;		/* Pointer to segment of type IBTree */
     int incr;				/* Amount to update */
{
    segPtr->size += incr;
    if (segPtr->size < 1) {
      panic("IBTree length updated to negative value");
    }
    if (segPtr->body.itree.linePtr->parentPtr->segPtr) {
      IBtreeUpdateLength(segPtr->body.itree.linePtr->parentPtr->segPtr,incr);
    }
}

/*
 *--------------------------------------------------------------
 *
 * SplitSeg --
 *
 *	This procedure is called before adding or deleting
 *	segments.  It does three things: (a) it finds the segment
 *	containing indexPtr;  (b) if there are several such
 *	segments (because some segments have zero length) then
 *	it picks the first segment that does not have left
 *	gravity;  (c) if the index refers to the middle of
 *	a segment then it splits the segment so that the
 *	index now refers to the beginning of a segment.
 *
 * Results:
 *	The return value is a "pointer to the segment just
 *	before the segment" corresponding to indexPtr (as
 *	described above).  
 *
 * Side effects:
 *	The segment referred to by indexPtr is split unless
 *	indexPtr refers to its first character.
 *
 *--------------------------------------------------------------
 */

static SegLine
SplitSeg(indexPtr)
    TkTextIndex *indexPtr;		/* Index identifying position
					 * at which to split a segment. */
{
    TkTextSegment *prevPtr, *segPtr;
    int count;
    SegLine pSegment;			/* The segment and line of the
					 * previous segment */

    for (count = indexPtr->byteIndex, prevPtr = NULL,
	    segPtr = indexPtr->linePtr->segPtr; segPtr != NULL;
	    count -= segPtr->size, prevPtr = segPtr, segPtr = segPtr->nextPtr) {
	if (segPtr->size > count) {
	    if (count == 0) {
	        goto found;
	    }
	    if (segPtr->typePtr == &tkTextIBTreeType) {
	      int countLine;
	      TkTextIndex newInd;
	      TkTextLine *linePtr;

	      count--;			/* Dummy character at beginning */
	      linePtr = TkBTreeFindLine(segPtr->body.itree.tree, 0);
	      while (count >= (countLine = TkBTreeCharsInLine(linePtr))) {
		count -= countLine;
		linePtr = TkBTreeNextLine(linePtr);
	      }
	      newInd.tree = segPtr->body.itree.tree;
	      newInd.linePtr = linePtr;
	      newInd.byteIndex = count;
	      return SplitSeg(&newInd);
	    }
	    segPtr = (*segPtr->typePtr->splitProc)(segPtr, count);
	    if (prevPtr == NULL) {
		indexPtr->linePtr->segPtr = segPtr;
	    } else {
		prevPtr->nextPtr = segPtr;
	    }
	    pSegment.segPtr = segPtr;
	    pSegment.linePtr = indexPtr->linePtr;
	    return pSegment;
	} else if ((segPtr->size == 0) && (count == 0)
		&& !segPtr->typePtr->leftGravity) {
	    goto found;
	}
    }
    panic("SplitSeg reached end of line!");

  found:
    pSegment.linePtr = indexPtr->linePtr;
    if (prevPtr == NULL) {
      /* Create empty character segment. */
      prevPtr = (TkTextSegment *) ckalloc(CSEG_SIZE(0));
      prevPtr->typePtr = &tkTextCharType;
      prevPtr->nextPtr = segPtr;
      prevPtr->size = 0;
      prevPtr->body.chars[0] = 0;
      indexPtr->linePtr->segPtr = prevPtr;
    }
    pSegment.segPtr = prevPtr;
    return pSegment;
}

/*
 *--------------------------------------------------------------
 *
 * CleanupLine --
 *
 *	This procedure is called after modifications have been
 *	made to a line.  It scans over all of the segments in
 *	the line, giving each a chance to clean itself up, e.g.
 *	by merging with the following segments, updating internal
 *	information, etc.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Depends on what the segment-specific cleanup procedures do.
 *
 *--------------------------------------------------------------
 */

static void
CleanupLine(linePtr)
    TkTextLine *linePtr;		/* Line to be cleaned up. */
{
    TkTextSegment *segPtr, **prevPtrPtr;
    int anyChanges;

    /*
     * Make a pass over all of the segments in the line, giving each
     * a chance to clean itself up.  This could potentially change
     * the structure of the line, e.g. by merging two segments
     * together or having two segments cancel themselves;  if so,
     * then repeat the whole process again, since the first structure
     * change might make other structure changes possible.  Repeat
     * until eventually there are no changes.
     */

    while (1) {
	anyChanges = 0;
	for (prevPtrPtr = &linePtr->segPtr, segPtr = *prevPtrPtr;
		segPtr != NULL;
		prevPtrPtr = &(*prevPtrPtr)->nextPtr, segPtr = *prevPtrPtr) {
	    if (segPtr->typePtr->cleanupProc != NULL) {
		*prevPtrPtr = (*segPtr->typePtr->cleanupProc)(segPtr, linePtr);
		if (segPtr != *prevPtrPtr) {
		    anyChanges = 1;
		}
	    }
	}
	if (!anyChanges) {
	    break;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeDeleteChars, DeleteRange --
 *
 *	Delete a range of characters from a B-tree.  The caller
 *	must make sure that the final newline of the B-tree is
 *	never deleted.  DeleteRange does the work; TkBTreeDeleteChars,
 *	called on the outermost tree, also keeps the values of the runs
 *	of tags with the runs the deletion leaves (DeleteKeepingRuns).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Information is deleted from the B-tree.  This can cause the
 *	internal structure of the B-tree to change.  Note: because
 *	of changes to the B-tree structure, the indices pointed
 *	to by index1Ptr and index2Ptr should not be used after this
 *	procedure returns.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeDeleteChars(index1Ptr, index2Ptr, rebalance, check4trees)
    TkTextIndex *index1Ptr;		/* First character to delete. */
    TkTextIndex *index2Ptr;		/* Character just after the last one
					 * to delete. */
    int rebalance;			/* As for DeleteRange. */
    int check4trees;			/* As for DeleteRange. */
{
    TkText *textPtr = NULL;

    if (rebalance && check4trees && (index1Ptr->tree != NULL)) {
	/* (Recursive calls may have no tree in their indices.) */
	textPtr = ((BTree *) index1Ptr->tree)->textPtr;
    }
    if ((textPtr != NULL) && textPtr->haveValues
	    && (index1Ptr->linePtr->parentPtr->segPtr == NULL)
	    && (textPtr->tree == index1Ptr->tree)) {
	DeleteKeepingRuns(textPtr, index1Ptr, index2Ptr);
	return;
    }
    DeleteRange(index1Ptr, index2Ptr, rebalance, check4trees);
}

static void
DeleteRange(index1Ptr, index2Ptr, rebalance, check4trees)
    register TkTextIndex *index1Ptr;	/* Indicates first character that is
					 * to be deleted. */
    register TkTextIndex *index2Ptr;	/* Indicates character just after the
					 * last one that is to be deleted. */
    int rebalance;			/* Whether to do cleanup, which is
					 * not needed in recursive calls. */
    int check4trees;			/* Whether to do IBTree
					 * lookup, which is 
					 * not needed in recursive calls. */
{
    TkTextSegment *prevPtr;		/* The segment just before the start
					 * of the deletion range. */
    TkTextSegment *lastPtr;		/* The segment just after the end
					 * of the deletion range. */
    TkTextSegment *segPtr, *nextPtr;
    TkTextLine *curLinePtr;
    Node *curNodePtr, *nodePtr;
    int count = 0;			/* Total size of deleted segments. */
    TkTextBTree tree = index1Ptr->tree;
    TkTextLine *startLinePtr;		/* Keeps the pointer to the
					 * line the start of deleted
					 * region is in. */
    TkTextLine *lastLinePtr;		/* Keeps the pointer to the
					 * line the end of deleted
					 * region is in. */
    SegLine pSegment1, pSegment2;	/* The segment and line of the
					 * previous segments for index?Ptr. */
    int distance = INT_MAX, code, size;
    int endGone;			/* Whether all of the last line but
					 * its final newline is in the range
					 * (with the separator before it). */
    TkTextIndex index1 = *index1Ptr, index2 = *index2Ptr, index3;
    TkTextSegment *startChain = NULL, *endChain = NULL;

    index2Ptr = &index2; index1Ptr = &index1; /* Now can modify it. */
    if (index1Ptr->tree != index2Ptr->tree) {
      panic("TkBTreeDeleteChars called with indices in different trees!");
    }

  lookatend:

    if (index1Ptr->linePtr == index2Ptr->linePtr) {
      distance = index2Ptr->byteIndex - index1Ptr->byteIndex;
    }

    /*
     * Tricky point:  split at index2Ptr first;  otherwise the split
     * at index2Ptr may invalidate segPtr and/or prevPtr.
     */

    pSegment2 = SplitSeg(index2Ptr);
    lastPtr = pSegment2.segPtr->nextPtr;
    lastLinePtr = pSegment2.linePtr;

    if (check4trees && lastLinePtr->parentPtr->segPtr) {
      /* Check whether the this segment contains index1. */
      TkTextSegment *prPtr;
      int off;				/* Will keep (negative) index of the
					 * start of parent segment
					 * relative to the index2Ptr. */
      
      for (prPtr = lastLinePtr->segPtr, off = 1; /* Dummy char. */
	   (off <= distance) && (prPtr != lastPtr); 
	   off += prPtr->size, prPtr = prPtr->nextPtr) { /* Empty. */
      }
      if (off <= distance) {
	TkTextLine *lnPtr;

	for (lnPtr = TkBTreeFindLine(lastLinePtr->parentPtr->segPtr
				     ->body.itree.tree, 0);
	     off <= distance && (lnPtr != lastLinePtr);
	     off += TkBTreeCharsInLine(lnPtr), lnPtr = TkBTreeNextLine(lnPtr)
	     ) {			/* Empty. */
	}
      }
      /* If off<=distance, then index1Ptr is outside of the parent segment, so
       * we should kill this parent. */
      if (off <= distance) {
	TkTextSegment *tmpPtr = lastLinePtr->parentPtr->segPtr;

	index3 = *index2Ptr;
	index3.byteIndex -= off - 1;
	if (index3.byteIndex < index2Ptr->byteIndex) {
	  TkBTreeDeleteChars(&index3, index2Ptr, 0, 0); /* No rebalance, no
							 * check for internal
							 * trees. */
	}
	TkBTreeKillBlockProc(tmpPtr);	/* Protect of free()ing. */
	index3.byteIndex --;
	*index2Ptr = index3;
	goto lookatend;
      }
    }

    /* At this moment the end is out of all IBTree we should have deleted. */

  lookatstart:

    pSegment1 = SplitSeg(index1Ptr);
    prevPtr = pSegment1.segPtr;
    segPtr = prevPtr->nextPtr;
    startLinePtr = curLinePtr = pSegment1.linePtr;
    if (curLinePtr->parentPtr->segPtr) {
      tree = curLinePtr->parentPtr->segPtr->body.itree.tree;
    } else {
      tree = index1Ptr->tree;
    }
    curNodePtr = curLinePtr->parentPtr;

    if (check4trees && curLinePtr->parentPtr->segPtr) {
      /* Check whether the this segment contains index2. */
      TkTextSegment *prPtr;
      int off;				/* Will keep index of index1
					 * relative to index of the
					 * first position after the
					 * end of the parent segment. */
      
      for (prPtr = segPtr, off = 0; /* Dummy char canceled by "\n". */
	   (off <= distance) && prPtr; 
	   off += prPtr->size, prPtr = prPtr->nextPtr) { /* Empty. */
      }
      if (off <= distance) {
	TkTextLine *lnPtr;

	for (lnPtr = TkBTreeNextLine(curLinePtr), off--; /* Dummy line. */
	     off <= distance && lnPtr;
	     off += TkBTreeCharsInLine(lnPtr), lnPtr = TkBTreeNextLine(lnPtr)
	     ) {			/* Empty. */
	}
      }
      /* If off<=distance, then index2 is outside of the parent segment, so
       * we should kill this parent. */
      if (off <= distance) {

	/* We cannot just delete the block now, since it will mess up
	 * the index of the end, as well as the lines. In fact we
	 * cannot delete the piece after the block too, since a deleted block 
	 * outside can have a deleted component before this one, that
	 * will also mess the lines and indices. So
	 * we delete the inside, and postpone killing of the blocks
	 * until all the characters are deleted. After killing the
	 * inside we should correct the index of the end. */

	index3 = *index1Ptr;
	index3.byteIndex += off - 1;
	if (off > 1) {
	  TkBTreeDeleteChars(index1Ptr, &index3, 0, 0); /* The
							 * internal part.*/
	} else {
	  /*
	   * Nothing inside is deleted (the range starts at the block's
	   * tail): undo what SplitSeg did to the line above (an empty
	   * segment, or a character segment split in two), as the
	   * deletion would have.  Until the block is killed, the line
	   * is checked as it is, with the enclosing tree, by the
	   * deletions that follow.
	   */

	  CleanupLine(curLinePtr);
	}
	/* Update the coordinate of the end. */
	if (index1Ptr->linePtr == index2Ptr->linePtr) {
	  index2Ptr->byteIndex -= off - 1;
	}
	/* And update coordinates of the start. */
	index1Ptr->byteIndex++;
	/* Cache the IBTree for future deletion. */
	if (startChain) {
	  endChain->body.itree.next2delete = curLinePtr->parentPtr->segPtr;
	} else {
	  startChain = curLinePtr->parentPtr->segPtr;
	}
	endChain = curLinePtr->parentPtr->segPtr;
	/* Check whether we need to delete anything else. */
	if ((index1Ptr->linePtr == index2Ptr->linePtr) 
	    && (index1Ptr->byteIndex == index2Ptr->byteIndex)) {
	  TkTextLine *lPtr = curLinePtr->parentPtr->segPtr->body.itree.linePtr;

	  if (lPtr->parentPtr->segPtr) {
	    tree = lPtr->parentPtr->segPtr->body.itree.tree;
	  } else {
	    tree = index1Ptr->tree;
	  }
	  /*
	   * The block, with its lines, is killed at cleanup: the
	   * rebalancing there must start from the line that holds it,
	   * not from the internal line the deletion started in.
	   */

	  startLinePtr = lPtr;
	  goto cleanup;
	}
	if (index1Ptr->linePtr == index2Ptr->linePtr) {
	  distance = index2Ptr->byteIndex - index1Ptr->byteIndex;
	}
	goto lookatstart;
      }
    }

    /* At this moment we finished with all the internal BTrees. What
     * follows is a plain delete in the same BTree. */

    /*
     * Values (N5): when the last line is joined to the starting line,
     * the starting line survives (whatever of its text is deleted: an
     * insertion splitting a leaf leaves the value on the first part,
     * and this is its inverse) and keeps its value if it has one, else
     * takes that of the last line; but if all of the last line except
     * its final newline is in the range, with the separator before it,
     * the last line is deleted as a whole, value and all.
     */

    size = 0;
    for (segPtr = lastPtr; segPtr != NULL; segPtr = segPtr->nextPtr) {
	size += segPtr->size;
    }
    endGone = (startLinePtr != lastLinePtr) && (size <= 1);
    segPtr = prevPtr->nextPtr;
    prevPtr->nextPtr = lastPtr;

    while (segPtr != lastPtr) {
	if (segPtr == NULL) {
	    TkTextLine *nextLinePtr;

	    /*
	     * We just ran off the end of a line.  First find the
	     * next line, then go back to the old line and delete it
	     * (unless it's the starting line for the range).
	     */

	    nextLinePtr = TkBTreeNextLine(curLinePtr);
	    if (curLinePtr != startLinePtr) {
		if (curNodePtr == startLinePtr->parentPtr) {
		    startLinePtr->nextPtr = curLinePtr->nextPtr;
		} else {
		    curNodePtr->children.linePtr = curLinePtr->nextPtr;
		}
		for (nodePtr = curNodePtr; nodePtr != NULL;
			nodePtr = nodePtr->parentPtr) {
		    nodePtr->numLines--;
		}
		curNodePtr->numChildren--;
		if (!TkTextDataIsEmpty(curLinePtr->value)) {
		    DropValue(NodeText(curNodePtr), (void *) curLinePtr,
			    &curLinePtr->value);
		}
		ckfree((char *) curLinePtr);
	    }
	    curLinePtr = nextLinePtr;
	    segPtr = curLinePtr->segPtr;

	    /*
	     * If the node is empty then delete it and its parents,
	     * recursively upwards until a non-empty node is found.
	     */

	    while (curNodePtr->numChildren == 0) {
		Node *parentPtr;

		parentPtr = curNodePtr->parentPtr;
		if (parentPtr->children.nodePtr == curNodePtr) {
		    parentPtr->children.nodePtr = curNodePtr->nextPtr;
		} else {
		    Node *prevNodePtr = parentPtr->children.nodePtr;
		    while (prevNodePtr->nextPtr != curNodePtr) {
			prevNodePtr = prevNodePtr->nextPtr;
		    }
		    prevNodePtr->nextPtr = curNodePtr->nextPtr;
		}
		parentPtr->numChildren--;
		if (!TkTextDataIsEmpty(curNodePtr->value)) {
		    DropValue(NodeText(curNodePtr), (void *) curNodePtr,
			    &curNodePtr->value);
		}
		DeleteSummaries(curNodePtr->summaryPtr);
		ckfree((char *) curNodePtr);
		curNodePtr = parentPtr;
	    }
	    curNodePtr = curLinePtr->parentPtr;
	    continue;
	}

	nextPtr = segPtr->nextPtr;
	size = segPtr->size;
	if ((code = (*segPtr->typePtr->deleteProc)(segPtr, curLinePtr, 0))
	    != 0) {
	  if (code == 1) {
	    /*
	     * This segment refuses to die.  Move it to prevPtr and
	     * advance prevPtr if the segment has left gravity.
	     */

	    if (prevPtr == NULL) {
		segPtr->nextPtr = startLinePtr->segPtr;
		startLinePtr->segPtr = segPtr;
	    } else {
		segPtr->nextPtr = prevPtr->nextPtr;
		prevPtr->nextPtr = segPtr;
	    }
	    if (segPtr->typePtr->leftGravity) {
		prevPtr = segPtr;
	    }
	  } else if (code == 2) {
	    TkTextSegment *oldPtr = segPtr, *newPtr;
	    /*
	     * This segment dies, but spits out childrens in
	     * segPtr->nextPtr.  Move them to prevPtr and 
	     * advance prevPtr if the segment has left gravity. After
	     * this it is safe to delete segPtr.
	     */

	    segPtr = segPtr->nextPtr;
	    while (segPtr) {
	      newPtr = segPtr->nextPtr;
	      if (prevPtr == NULL) {
		segPtr->nextPtr = startLinePtr->segPtr;
		startLinePtr->segPtr = segPtr;
	      } else {
		segPtr->nextPtr = prevPtr->nextPtr;
		prevPtr->nextPtr = segPtr;
	      }
	      if (segPtr->typePtr->leftGravity) {
		prevPtr = segPtr;
	      }
	      segPtr = newPtr;
	    }
	    ckfree((char*)oldPtr);
	  } else {
	    panic("Unknown code returned from deleteProc in TkBTreeDeleteChars.");
	  }
	}
	if (code != 2) {		/* Is accounted by inner code
					 * otherwise.  */
	  count += size;
	}
	segPtr = nextPtr;
    }

    if (count && startLinePtr->parentPtr->segPtr) {
      IBtreeUpdateLength(startLinePtr->parentPtr->segPtr, -count);
    }

    /*
     * If the beginning and end of the deletion range are in different
     * lines, join the two lines together and discard the ending line.
     */

    if (startLinePtr != lastLinePtr) {
	TkTextLine *prevLinePtr;

	for (segPtr = lastPtr; segPtr != NULL;
		segPtr = segPtr->nextPtr) {
	    if (segPtr->typePtr->lineChangeProc != NULL) {
		(*segPtr->typePtr->lineChangeProc)(segPtr, lastLinePtr);
	    }
	}
	curNodePtr = lastLinePtr->parentPtr;
	for (nodePtr = curNodePtr; nodePtr != NULL;
		nodePtr = nodePtr->parentPtr) {
	    nodePtr->numLines--;
	}
	curNodePtr->numChildren--;
	prevLinePtr = curNodePtr->children.linePtr;
	if (prevLinePtr == lastLinePtr) {
	    curNodePtr->children.linePtr = lastLinePtr->nextPtr;
	} else {
	    while (prevLinePtr->nextPtr != lastLinePtr) {
		prevLinePtr = prevLinePtr->nextPtr;
	    }
	    prevLinePtr->nextPtr = lastLinePtr->nextPtr;
	}

	/*
	 * The two lines are now one leaf: it keeps the value of the
	 * first if it has one, else takes that of the second, unless the
	 * second is deleted as a whole.
	 */

	if (endGone) {
	    DropValue(NodeText(curNodePtr), (void *) lastLinePtr,
		    &lastLinePtr->value);
	} else {
	    MergeValues(NodeText(curNodePtr), (void *) startLinePtr,
		    &startLinePtr->value, (void *) lastLinePtr,
		    &lastLinePtr->value);
	}
	ckfree((char *) lastLinePtr);

	/*
	 * Outside blocks, rebalance (unless the caller does).  Inside a
	 * block, if the two lines were in different nodes, glue the
	 * nodes whatever "rebalance" says: this is not balancing, the
	 * end side's node lost its line, and left alone it stays in the
	 * tree with no children (or fewer than it counts).  The
	 * recursive deletions that dissolve or empty a block (rebalance
	 * 0) left it so when the deletion joined leaves of different
	 * nodes, and the next walk over the lines crashed.
	 */

	if (!curNodePtr->segPtr) {
	  if (rebalance) {
	    Rebalance((BTree *) tree, curNodePtr);
	  }
	} else {
	  if (startLinePtr->parentPtr != curNodePtr) {
	    /* Now we need to glue the entire node stalks. */
	    Node *firstNodePtr = startLinePtr->parentPtr;
	    Node *parentPtr, *childPtr = firstNodePtr;
	    TkTextLine *linePtr = curNodePtr->children.linePtr;
	    /*
	     * Whether the end side's node is entirely in the range (with
	     * the separator before it): it is deleted as a whole, value
	     * and all, instead of being merged.  Its leaves before the
	     * last line are deleted already, so: the last line is gone
	     * and no leaf follows it in the node; and upwards, no node
	     * follows the end side's node in its parent.
	     */
	    int gone = endGone && (linePtr == NULL);

	    /* Move the following lines where they belong. */
	    startLinePtr->nextPtr = linePtr;
	    while (linePtr) {
	      linePtr->parentPtr = firstNodePtr;
	      linePtr = linePtr->nextPtr;
	    }
	    /* Glue the (grand)parents of the last line to the
	     * corresponding (grand)parents of the first line. */
	    while (firstNodePtr != curNodePtr) {
	      /* The merged node keeps the first value present. */
	      if (gone) {
		DropValue(NodeText(curNodePtr), (void *) curNodePtr,
			&curNodePtr->value);
	      } else {
		MergeValues(NodeText(curNodePtr), (void *) firstNodePtr,
			&firstNodePtr->value, (void *) curNodePtr,
			&curNodePtr->value);
	      }
	      firstNodePtr->numLines += curNodePtr->numLines;
	      firstNodePtr->numChildren += curNodePtr->numChildren;
	      firstNodePtr->nextPtr = curNodePtr->nextPtr;
	      if (curNodePtr->level) {
		/* Move the children nodes. */
		while ( (childPtr = childPtr->nextPtr) ) {
		  childPtr->parentPtr = firstNodePtr;
		}
		childPtr = firstNodePtr;
	      }
	      /* Now we can delete *curNodePtr. */
	      parentPtr = curNodePtr->parentPtr;
	      parentPtr->numChildren--;
	      gone = gone && (curNodePtr->nextPtr == NULL);
	      firstNodePtr = firstNodePtr->parentPtr;
	      if (firstNodePtr != parentPtr) {
		parentPtr->children.nodePtr = curNodePtr->nextPtr;
	      }
	      DeleteSummaries(curNodePtr->summaryPtr);
	      ckfree((char *) curNodePtr);
	      curNodePtr = parentPtr;
	    }
	    if (firstNodePtr->level > 1) {	/* Did some glueing. */
	      /* Need to correct structure one level below. */
	    }

	    /*
	     * The glued nodes have the children of the nodes they took
	     * in, but only their own tag summaries (those of the nodes
	     * taken in were freed): count again, from the leaves up to
	     * the node where the two sides met (whose total does not
	     * change).  Inside a block a summary keeps any non-zero
	     * count, so this never moves a tag's root.
	     */

	    for (nodePtr = startLinePtr->parentPtr; nodePtr != firstNodePtr;
		 nodePtr = nodePtr->parentPtr) {
	      RecomputeNodeCounts(nodePtr);
	    }
	  }
	}
    }

    /*
     * Cleanup the segments in the new line.
     */

    CleanupLine(startLinePtr);

  cleanup:

    /* Proceed with pending Block killings. */
    while (startChain) {
        TkTextSegment *tmp = startChain->body.itree.next2delete;
	TkBTreeKillBlockProc(startChain);
	startChain = tmp;			/* Protect of free()ing. */
    }

    /*
     * Lastly, rebalance the first node of the range.
     */

    if (rebalance && !startLinePtr->parentPtr->segPtr) {
      Rebalance((BTree *) tree, startLinePtr->parentPtr);
    }
    if (tkBTreeDebug) {
	TkBTreeCheck(tree);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeFindLine --
 *
 *	Find a particular line in a B-tree based on its line number.
 *
 * Results:
 *	The return value is a pointer to the line structure for the
 *	line whose index is "line", or NULL if no such line exists.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

TkTextLine *
TkBTreeFindLine(tree, line)
    TkTextBTree tree;			/* B-tree in which to find line. */
    int line;				/* Index of desired line. */
{
    BTree *treePtr = (BTree *) tree;
    register Node *nodePtr;
    register TkTextLine *linePtr;
    int linesLeft;

    nodePtr = treePtr->rootPtr;
    linesLeft = line;
    if ((line < 0) || (line >= nodePtr->numLines)) {
	return NULL;
    }

    /*
     * Work down through levels of the tree until a node is found at
     * level 0.
     */

    while (nodePtr->level != 0) {
	for (nodePtr = nodePtr->children.nodePtr;
		nodePtr->numLines <= linesLeft;
		nodePtr = nodePtr->nextPtr) {
	    if (nodePtr == NULL) {
		panic("TkBTreeFindLine ran out of nodes");
	    }
	    linesLeft -= nodePtr->numLines;
	}
    }

    /*
     * Work through the lines attached to the level-0 node.
     */

    for (linePtr = nodePtr->children.linePtr; linesLeft > 0;
	    linePtr = linePtr->nextPtr) {
	if (linePtr == NULL) {
	    panic("TkBTreeFindLine ran out of lines");
	}
	linesLeft -= 1;
    }
    return linePtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeNextLine --
 *
 *	Given an existing line in a B-tree, this procedure locates the
 *	next line in the B-tree.  This procedure is used for scanning
 *	through the B-tree.
 *
 * Results:
 *	The return value is a pointer to the line that immediately
 *	follows linePtr, or NULL if there is no such line.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

TkTextLine *
TkBTreeNextLine(linePtr)
    register TkTextLine *linePtr;	/* Pointer to existing line in
					 * B-tree. */
{
    register Node *nodePtr;

    if (linePtr->nextPtr != NULL) {
	return linePtr->nextPtr;
    }

    /*
     * This was the last line associated with the particular parent node.
     * Search up the tree for the next node, then search down from that
     * node to find the first line.
     */

    for (nodePtr = linePtr->parentPtr; ; nodePtr = nodePtr->parentPtr) {
	if (nodePtr->nextPtr != NULL) {
	    nodePtr = nodePtr->nextPtr;
	    break;
	}
	if (nodePtr->parentPtr == NULL) {
	    return (TkTextLine *) NULL;
	}
    }
    while (nodePtr->level > 0) {
	nodePtr = nodePtr->children.nodePtr;
    }
    return nodePtr->children.linePtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreePreviousLine --
 *
 *	Given an existing line in a B-tree, this procedure locates the
 *	previous line in the B-tree.  This procedure is used for scanning
 *	through the B-tree in the reverse direction.
 *
 * Results:
 *	The return value is a pointer to the line that immediately
 *	preceeds linePtr, or NULL if there is no such line.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

TkTextLine *
TkBTreePreviousLine(linePtr)
    register TkTextLine *linePtr;	/* Pointer to existing line in
					 * B-tree. */
{
    register Node *nodePtr;
    register Node *node2Ptr;
    register TkTextLine *prevPtr;

    /*
     * Find the line under this node just before the starting line.
     */
    prevPtr = linePtr->parentPtr->children.linePtr;	/* First line at leaf */
    while (prevPtr != linePtr) {
	if (prevPtr->nextPtr == linePtr) {
	    return prevPtr;
	}
	prevPtr = prevPtr->nextPtr;
	if (prevPtr == (TkTextLine *) NULL) {
	    panic("TkBTreePreviousLine ran out of lines");
	}
    }

    /*
     * This was the first line associated with the particular parent node.
     * Search up the tree for the previous node, then search down from that
     * node to find its last line.
     */
    for (nodePtr = linePtr->parentPtr; ; nodePtr = nodePtr->parentPtr) {
	if (nodePtr == (Node *) NULL || nodePtr->parentPtr == (Node *) NULL) {
	    return (TkTextLine *) NULL;
	}
	if (nodePtr != nodePtr->parentPtr->children.nodePtr) {
	    break;
	}
    }
    for (node2Ptr = nodePtr->parentPtr->children.nodePtr; ; 
	    node2Ptr = node2Ptr->children.nodePtr) {
	while (node2Ptr->nextPtr != nodePtr) {
	    node2Ptr = node2Ptr->nextPtr;
	}
	if (node2Ptr->level == 0) {
	    break;
	}
	nodePtr = (Node *)NULL;
    }
    for (prevPtr = node2Ptr->children.linePtr ; ; prevPtr = prevPtr->nextPtr) {
	if (prevPtr->nextPtr == (TkTextLine *) NULL) {
	    return prevPtr;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeLineIndex --
 *
 *	Given a pointer to a line in a B-tree, return the numerical
 *	index of that line.
 *
 * Results:
 *	The result is the index of linePtr within the tree, where 0
 *	corresponds to the first line in the tree.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeLineIndex(linePtr)
    TkTextLine *linePtr;		/* Pointer to existing line in
					 * B-tree. */
{
    register TkTextLine *linePtr2;
    register Node *nodePtr, *parentPtr, *nodePtr2;
    int index;

    /*
     * First count how many lines precede this one in its level-0
     * node.
     */

    nodePtr = linePtr->parentPtr;
    index = 0;
    for (linePtr2 = nodePtr->children.linePtr; linePtr2 != linePtr;
	    linePtr2 = linePtr2->nextPtr) {
	if (linePtr2 == NULL) {
	    panic("TkBTreeLineIndex couldn't find line");
	}
	index += 1;
    }

    /*
     * Now work up through the levels of the tree one at a time,
     * counting how many lines are in nodes preceding the current
     * node.
     */

    for (parentPtr = nodePtr->parentPtr ; parentPtr != NULL;
	    nodePtr = parentPtr, parentPtr = parentPtr->parentPtr) {
	for (nodePtr2 = parentPtr->children.nodePtr; nodePtr2 != nodePtr;
		nodePtr2 = nodePtr2->nextPtr) {
	    if (nodePtr2 == NULL) {
		panic("TkBTreeLineIndex couldn't find node");
	    }
	    index += nodePtr2->numLines;
	}
    }
    return index;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeLinkSegment --
 *
 *	This procedure adds a new segment to a B-tree at a given
 *	location.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	SegPtr will be linked into its tree.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
void
TkBTreeLinkSegment(segPtr, indexPtr)
    TkTextSegment *segPtr;	/* Pointer to new segment to be added to
				 * B-tree.  Should be completely initialized
				 * by caller except for nextPtr field. */
    TkTextIndex *indexPtr;	/* Where to add segment:  it gets linked
				 * in just before the segment indicated
				 * here. */
{
    SegLine pSegment;			/* The segment and line of the
					 * previous segment */

    pSegment = SplitSeg(indexPtr);
    segPtr->nextPtr = pSegment.segPtr->nextPtr;
    pSegment.segPtr->nextPtr = segPtr;
    if (pSegment.linePtr->parentPtr->segPtr) {
      IBtreeUpdateLength(pSegment.linePtr->parentPtr->segPtr,
			 segPtr->size);
    }
    CleanupLine(pSegment.linePtr);
    if (tkBTreeDebug) {
	TkBTreeCheck(indexPtr->tree);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeUnlinkSegment --
 *
 *	This procedure unlinks a segment from its line in a B-tree.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	SegPtr will be unlinked from linePtr.  The segment itself
 *	isn't modified by this procedure.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
void
TkBTreeUnlinkSegment(tree, segPtr, linePtr)
    TkTextBTree tree;			/* Tree containing segment. */
    TkTextSegment *segPtr;		/* Segment to be unlinked. */
    TkTextLine *linePtr;		/* Line that currently contains
					 * segment. */
{
    register TkTextSegment *prevPtr;

    if (linePtr->segPtr == segPtr) {
	linePtr->segPtr = segPtr->nextPtr;
    } else {
	for (prevPtr = linePtr->segPtr; prevPtr->nextPtr != segPtr;
		prevPtr = prevPtr->nextPtr) {
	    /* Empty loop body. */
	}
	prevPtr->nextPtr = segPtr->nextPtr;
    }
    if (linePtr->parentPtr->segPtr) {
      IBtreeUpdateLength(linePtr->parentPtr->segPtr,
			 - segPtr->size);
    }
    CleanupLine(linePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeTag, TagRange --
 *
 *	Turn a given tag on or off for a given range of characters in
 *	a B-tree of text.  TagRange does the work; TkBTreeTag also keeps
 *	the values of the runs of the tag with the runs that are left
 *	(TagKeepingRuns).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The given tag is added to the given range of characters
 *	in the tree or removed from all those characters, depending
 *	on the "add" argument.  The structure of the btree is modified
 *	enough that index1Ptr and index2Ptr are no longer valid after
 *	this procedure returns, and the indexes may be modified by
 *	this procedure.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeTag(index1Ptr, index2Ptr, tagPtr, add)
    TkTextIndex *index1Ptr;		/* First character of the range. */
    TkTextIndex *index2Ptr;		/* Character just after the last one
					 * in the range. */
    TkTextTag *tagPtr;			/* Tag to add or remove. */
    int add;				/* One means add tag to the given
					 * range of characters;  zero means
					 * remove the tag from the range. */
{
    if (tagPtr->hasRunValues) {
	TkText *textPtr = tagPtr->textPtr;

	if (textPtr->vcTagDone) {
	    textPtr->vcTagDone = 0;	/* Done before the redisplay. */
	} else {
	    TkBTreeVcPredictTag(textPtr, index1Ptr, index2Ptr, tagPtr, add);
	}
	TagKeepingRuns(index1Ptr, index2Ptr, tagPtr, add);
    } else {
	TagRange(index1Ptr, index2Ptr, tagPtr, add);
    }
}

static void
TagRange(index1Ptr, index2Ptr, tagPtr, add)
    register TkTextIndex *index1Ptr;	/* Indicates first character in
					 * range. */
    register TkTextIndex *index2Ptr;	/* Indicates character just after the
					 * last one in range. */
    TkTextTag *tagPtr;			/* Tag to add or remove. */
    int add;				/* One means add tag to the given
					 * range of characters;  zero means
					 * remove the tag from the range. */
{
    TkTextSegment *segPtr;
    TkTextSearch search;
    TkTextLine *cleanupLinePtr = NULL;
    int oldState;
    int changed;
    register TkTextSegment *prevPtr;
    SegLine pSegment;			/* The segment and line of the
					 * previous segment */

    if (index1Ptr->tree != index2Ptr->tree) {
      panic("TkBTreeTag called with indices in different trees!");
    }

    /*
     * See whether the tag is present at the start of the range.  If
     * the state doesn't already match what we want then add a toggle
     * there.
     */

    oldState = TkBTreeCharTagged(index1Ptr, tagPtr);
    if ((add != 0) ^ oldState) {
	segPtr = (TkTextSegment *) ckalloc(TSEG_SIZE);
	segPtr->typePtr = (add) ? &tkTextToggleOnType : &tkTextToggleOffType;
	pSegment = SplitSeg(index1Ptr);
	cleanupLinePtr = pSegment.linePtr;
	prevPtr = pSegment.segPtr;
	segPtr->nextPtr = prevPtr->nextPtr;
	prevPtr->nextPtr = segPtr;
	segPtr->size = 0;
	segPtr->body.toggle.tagPtr = tagPtr;
	segPtr->body.toggle.inNodeCounts = 0;
	TkTextDataInit(segPtr->body.toggle.value);
    } else {
      TkTextIndex index;
      pSegment.segPtr = TkTextIndexToInternalSeg(index1Ptr, &index, NULL);
      pSegment.linePtr = index.linePtr;
    }

    /*
     * Scan the range of characters and delete any internal tag
     * transitions.  Keep track of what the old state was at the end
     * of the range, and add a toggle there if it's needed.
     */

    TkBTreeStartSearch(index1Ptr, index2Ptr, tagPtr, &search);
    if (!cleanupLinePtr)
	cleanupLinePtr = search.curIndex.linePtr;
    while (TkBTreeNextTag(&search)) {
	oldState ^= 1;
	segPtr = search.segPtr;
	prevPtr = search.curIndex.linePtr->segPtr;
	if (prevPtr == segPtr) {
	    search.curIndex.linePtr->segPtr = segPtr->nextPtr;
	} else {
	    while (prevPtr->nextPtr != segPtr) {
		prevPtr = prevPtr->nextPtr;
	    }
	    prevPtr->nextPtr = segPtr->nextPtr;
	}
	if (segPtr->body.toggle.inNodeCounts) {
	    ChangeNodeToggleCount(search.curIndex.linePtr->parentPtr,
		    segPtr->body.toggle.tagPtr, -1);
	    segPtr->body.toggle.inNodeCounts = 0;
	    changed = 1;
	} else {
	    changed = 0;
	}
	DropToggleValue(segPtr);
	ckfree((char *) segPtr);

	/*
	 * The code below is a bit tricky.  After deleting a toggle
	 * we eventually have to call CleanupLine, in order to allow
	 * character segments to be merged together.  To do this, we
	 * remember in cleanupLinePtr a line that needs to be
	 * cleaned up, but we don't clean it up until we've moved
	 * on to a different line.  That way the cleanup process
	 * won't goof up segPtr.
	 */

	if (cleanupLinePtr != search.curIndex.linePtr) {
	    CleanupLine(cleanupLinePtr);
	    cleanupLinePtr = search.curIndex.linePtr;
	}
	/*
	 * Quick hack.  ChangeNodeToggleCount may move the tag's root
	 * location around and leave the search in the void.  This resets
	 * the search.
	 */
	if (changed) {
	    TkBTreeStartSearch(index1Ptr, index2Ptr, tagPtr, &search);
	}
    }
    if ((add != 0) ^ oldState) {
	segPtr = (TkTextSegment *) ckalloc(TSEG_SIZE);
	segPtr->typePtr = (add) ? &tkTextToggleOffType : &tkTextToggleOnType;
	pSegment = SplitSeg(index2Ptr);
	prevPtr = pSegment.segPtr;
	segPtr->nextPtr = prevPtr->nextPtr;
	prevPtr->nextPtr = segPtr;
	segPtr->size = 0;
	segPtr->body.toggle.tagPtr = tagPtr;
	segPtr->body.toggle.inNodeCounts = 0;
	TkTextDataInit(segPtr->body.toggle.value);
    }

    /*
     * Cleanup cleanupLinePtr and the last line of the range, if
     * these are different.
     */

    CleanupLine(cleanupLinePtr);
    if (cleanupLinePtr != pSegment.linePtr) {
	CleanupLine(pSegment.linePtr);
    }

    if (tkBTreeDebug) {
	TkBTreeCheck(index1Ptr->tree);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ChangeNodeToggleCount --
 *
 *	This procedure increments or decrements the toggle count for
 *	a particular tag in a particular node and all its ancestors
 *	up to the per-tag root node. Node may reside in internal tree.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The toggle count for tag is adjusted up or down by "delta" in
 *	nodePtr.  This routine maintains the tagRootPtr that identifies
 *	the root node for the tag, moving it up or down the tree as needed.
 *
 *----------------------------------------------------------------------
 */

static void
ChangeNodeToggleCount(nodePtr, tagPtr, delta)
    register Node *nodePtr;		/* Node whose toggle count for a tag
					 * must be changed. */
    TkTextTag *tagPtr;			/* Information about tag. */
    int delta;				/* Amount to add to current toggle
					 * count for tag (may be negative). */
{
    register Summary *summaryPtr, *prevPtr;
    register Node *node2Ptr;
    int rootLevel;			/* Level of original tag root */

    tagPtr->toggleCount += delta;
    if (tagPtr->tagRootPtr == (Node *) NULL) {
	node2Ptr = nodePtr;
	while (node2Ptr->segPtr) {
	    node2Ptr = node2Ptr->segPtr->body.itree.linePtr->parentPtr;
	}
	tagPtr->tagRootPtr = node2Ptr;
	if (!nodePtr->segPtr) return;
    }

    /*
     * Note the level of the existing root for the tag so we can detect
     * if it needs to be moved because of the toggle count change.
     */

    rootLevel = tagPtr->tagRootPtr->level;

    /*
     * Iterate over the node and its ancestors up to the tag root, adjusting
     * summary counts at each node and moving the tag's root upwards if
     * necessary.
     */

    for ( ; nodePtr != tagPtr->tagRootPtr; 
	 nodePtr = nodePtr->parentPtr 
	   ? nodePtr->parentPtr 
	   : (nodePtr->segPtr 
	      ? nodePtr->segPtr->body.itree.linePtr->parentPtr 
	      : NULL)) {
	/*
	 * See if there's already an entry for this tag for this node.  If so,
	 * perhaps all we have to do is adjust its count.
	 */
    
	for (prevPtr = NULL, summaryPtr = nodePtr->summaryPtr;
		summaryPtr != NULL;
		prevPtr = summaryPtr, summaryPtr = summaryPtr->nextPtr) {
	    if (summaryPtr->tagPtr == tagPtr) {
		break;
	    }
	}
	if (summaryPtr != NULL) {
	    summaryPtr->toggleCount += delta;
	    if (summaryPtr->toggleCount > 0 &&
		(summaryPtr->toggleCount < tagPtr->toggleCount
		 || (summaryPtr->toggleCount == tagPtr->toggleCount
		     && nodePtr->segPtr))) {
		continue;
	    }
	    if (summaryPtr->toggleCount != 0) {
		/*
		 * Should never find a node with max toggle count at this
		 * point (there shouldn't have been a summary entry in the
		 * first place).
		 */

		panic("ChangeNodeToggleCount: bad toggle count (%d) max (%d)",
		    summaryPtr->toggleCount, tagPtr->toggleCount);
	    }

	    /*
	     * Zero toggle count;  must remove this tag from the list.
	     */

	    if (prevPtr == NULL) {
		nodePtr->summaryPtr = summaryPtr->nextPtr;
	    } else {
		prevPtr->nextPtr = summaryPtr->nextPtr;
	    }
	    ckfree((char *) summaryPtr);
	} else {
	    /*
	     * This tag isn't currently in the summary information list.
	     */
    
	    if (!nodePtr->segPtr && rootLevel == nodePtr->level) {
    
		/*
		 * The old tag root is at the same level in the tree as this
		 * node, but it isn't at this node.  Move the tag root up
		 * a level, in the hopes that it will now cover this node
		 * as well as the old root (if not, we'll move it up again
		 * the next time through the loop).  To push it up one level
		 * we copy the original toggle count into the summary
		 * information at the old root and change the root to its
		 * parent node.
		 */
    
		Node *rootNodePtr = tagPtr->tagRootPtr;
		summaryPtr = (Summary *) ckalloc(sizeof(Summary));
		summaryPtr->tagPtr = tagPtr;
		summaryPtr->toggleCount = tagPtr->toggleCount - delta;
		summaryPtr->nextPtr = rootNodePtr->summaryPtr;
		rootNodePtr->summaryPtr = summaryPtr;
		rootNodePtr = rootNodePtr->parentPtr;
		rootLevel = rootNodePtr->level;
		tagPtr->tagRootPtr = rootNodePtr;
	    }
	    summaryPtr = (Summary *) ckalloc(sizeof(Summary));
	    summaryPtr->tagPtr = tagPtr;
	    summaryPtr->toggleCount = delta;
	    summaryPtr->nextPtr = nodePtr->summaryPtr;
	    nodePtr->summaryPtr = summaryPtr;
	}
    }

    /*
     * If we've decremented the toggle count, then it may be necessary
     * to push the tag root down one or more levels.
     */

    if (delta >= 0) {
	return;
    }
    if (tagPtr->toggleCount == 0) {
	tagPtr->tagRootPtr = (Node *) NULL;
	return;
    }
    nodePtr = tagPtr->tagRootPtr;
    while (nodePtr->level > 0) {
	/*
	 * See if a single child node accounts for all of the tag's
	 * toggles.  If so, push the root down one level.
	 */

	for (node2Ptr = nodePtr->children.nodePtr;
		node2Ptr != (Node *)NULL ;
		node2Ptr = node2Ptr->nextPtr) {
	    for (prevPtr = NULL, summaryPtr = node2Ptr->summaryPtr;
		    summaryPtr != NULL;
		    prevPtr = summaryPtr, summaryPtr = summaryPtr->nextPtr) {
		if (summaryPtr->tagPtr == tagPtr) {
		    break;
		}
	    }
	    if (summaryPtr == NULL) {
		continue;
	    }
	    if (summaryPtr->toggleCount != tagPtr->toggleCount) {
		/*
		 * No node has all toggles, so the root is still valid.
		 */

		return;
	    }

	    /*
	     * This node has all the toggles, so push down the root.
	     */

	    if (prevPtr == NULL) {
		node2Ptr->summaryPtr = summaryPtr->nextPtr;
	    } else {
		prevPtr->nextPtr = summaryPtr->nextPtr;
	    }
	    ckfree((char *) summaryPtr);
	    tagPtr->tagRootPtr = node2Ptr;
	    break;
	}
	nodePtr = tagPtr->tagRootPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * FindTagStart --
 *
 *	Find the start of the first range of a tag.
 *
 * Results:
 *	The return value is a pointer to the first tag toggle segment
 *	for the tag.  This can be either a tagon or tagoff segments because
 *	of the way TkBTreeAdd removes a tag.
 *	Sets *indexPtr to be the external index of the tag toggle.
 *	Sets *intIndexPtr to be the internal index of the tag toggle.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static TkTextSegment *
FindTagStart(tree, tagPtr, indexPtr, intIndexPtr)
    TkTextBTree tree;			/* Tree to search within */
    TkTextTag *tagPtr;			/* Tag to search for. */
    TkTextIndex *indexPtr;		/* Return - external index
					   information. */
    TkTextIndex *intIndexPtr;		/* Return - internal index
					   information. */
{
    register Node *nodePtr;
    register TkTextLine *linePtr;
    register TkTextSegment *segPtr;
    register Summary *summaryPtr;
    int offset = 0;
    TkTextBTree intTree = tree;

    nodePtr = tagPtr->tagRootPtr;
    if (nodePtr == (Node *) NULL) {
	return NULL;
    }

    /*
     * Search from the root of the subtree that contains the tag down
     * to the level 0 node.
     */
  haveNodeWithTag:
    while (nodePtr->level > 0) {
	for (nodePtr = nodePtr->children.nodePtr ; nodePtr != (Node *) NULL;
		nodePtr = nodePtr->nextPtr) {
	    for (summaryPtr = nodePtr->summaryPtr ; summaryPtr != NULL;
		    summaryPtr = summaryPtr->nextPtr) {
		if (summaryPtr->tagPtr == tagPtr) {
		    goto gotNodeWithTag;
		}
	    }
	}
	return NULL;			/* Not expected: no child has it. */

	gotNodeWithTag:
	continue;
    }

    /*
     * Work through the lines attached to the level-0 node.
     */

    for (linePtr = nodePtr->children.linePtr; linePtr != (TkTextLine *) NULL;
	    linePtr = linePtr->nextPtr) {
	for (offset = 0, segPtr = linePtr->segPtr ; segPtr != NULL;
		offset += segPtr->size, segPtr = segPtr->nextPtr) {
	    if (((segPtr->typePtr == &tkTextToggleOnType)
		    || (segPtr->typePtr == &tkTextToggleOffType))
		    && (segPtr->body.toggle.tagPtr == tagPtr)) {
		/*
		 * It is possible that this is a tagoff tag, but that
		 * gets cleaned up later.
		 */
		intIndexPtr->tree = intTree;
		intIndexPtr->linePtr = linePtr;
		intIndexPtr->byteIndex = offset;

		/*
		 * The external index from the internal one.  (Offsets
		 * added up on the way down left out the head of each
		 * block entered and the nodes of a block skipped: the
		 * toggle was reported too far left, and a search from
		 * before it did not stop where it should.)
		 */

		TkTextIndexToExternalIndex(tree, intIndexPtr, indexPtr);
		return segPtr;
	    } else if ((segPtr->typePtr == &tkTextIBTreeType)
		       && segPtr->body.itree.tree
		       && ((BTree *)segPtr->body.itree.tree)
		            ->rootPtr->summaryPtr) {
		for (summaryPtr = ((BTree *)segPtr->body.itree.tree)
			 ->rootPtr->summaryPtr;
		     summaryPtr; summaryPtr = summaryPtr->nextPtr) {
		    if (summaryPtr->tagPtr == tagPtr) {
			nodePtr = ((BTree *)segPtr->body.itree.tree)->rootPtr;
			intTree = segPtr->body.itree.tree;
			goto haveNodeWithTag;
		    }
		}
	    }
	}
    }
    return NULL;
}

/*
 *----------------------------------------------------------------------
 *
 * FindTagEnd --
 *
 *	Find the end of the last range of a tag.
 *
 * Results:
 *	The return value is a pointer to the last tag toggle segment
 *	for the tag.  This can be either a tagon or tagoff segments because
 *	of the way TkBTreeAdd removes a tag.
 *	Sets *indexPtr to be the external index of the tag toggle.
 *	Sets *intIndexPtr to be the internal index of the tag toggle.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static TkTextSegment *
FindTagEnd(tree, tagPtr, indexPtr, intIndexPtr)
    TkTextBTree tree;			/* Tree to search within */
    TkTextTag *tagPtr;			/* Tag to search for. */
    TkTextIndex *indexPtr;		/* Return - external index
					   information */
    TkTextIndex *intIndexPtr;		/* Return - internal index
					   information */
{
    register Node *nodePtr, *lastNodePtr;
    register TkTextLine *linePtr, *lastLinePtr;
    register TkTextSegment *segPtr, *lastSegPtr = NULL, *last2SegPtr;
    register Summary *summaryPtr;
    int lastoffset, lastoffset2, offset = 0;
    TkTextBTree intTree = tree;

    nodePtr = tagPtr->tagRootPtr;
    if (nodePtr == (Node *) NULL) {
	return NULL;
    }

    /*
     * Search from the root of the subtree that contains the tag down
     * to the level 0 node.
     */

  haveNodeWithTag:
    while (nodePtr->level > 0) {
	Node *parentPtr = nodePtr;

	for (lastNodePtr = NULL, nodePtr = parentPtr->children.nodePtr ;
		nodePtr != (Node *) NULL; nodePtr = nodePtr->nextPtr) {
	    for (summaryPtr = nodePtr->summaryPtr ; summaryPtr != NULL;
		    summaryPtr = summaryPtr->nextPtr) {
		if (summaryPtr->tagPtr == tagPtr) {
		    lastNodePtr = nodePtr;
		    break;
		}
	    }
	}
	if (lastNodePtr == NULL) {
	    return NULL;		/* Not expected: no child has it. */
	}
	nodePtr = lastNodePtr;
    }

    /*
     * Work through the lines attached to the level-0 node.
     */
    last2SegPtr = NULL;
    lastoffset2 = 0;
    lastoffset = 0;
    for (lastLinePtr = NULL, linePtr = nodePtr->children.linePtr;
	    linePtr != (TkTextLine *) NULL; linePtr = linePtr->nextPtr) {
	for (offset = 0, lastSegPtr = NULL, segPtr = linePtr->segPtr ;
		segPtr != NULL; 
		offset += segPtr->size, segPtr = segPtr->nextPtr) {
	    if (((segPtr->typePtr == &tkTextToggleOnType)
		    || (segPtr->typePtr == &tkTextToggleOffType))
		    && (segPtr->body.toggle.tagPtr == tagPtr)) {
		lastSegPtr = segPtr;
		lastoffset = offset;
	    } else if ((segPtr->typePtr == &tkTextIBTreeType)
		       && segPtr->body.itree.tree
		       && ((BTree *)segPtr->body.itree.tree) 
		       ->rootPtr->summaryPtr) {
		for (summaryPtr = ((BTree *)segPtr->body.itree.tree)
			 ->rootPtr->summaryPtr;
		     summaryPtr; summaryPtr = summaryPtr->nextPtr) {
		    if (summaryPtr->tagPtr == tagPtr) {
			lastSegPtr = segPtr;
			lastoffset = offset;
			break;
		    }
		}
	    }
	}
	if (lastSegPtr != NULL) {
	    lastLinePtr = linePtr;
	    last2SegPtr = lastSegPtr;
	    lastoffset2 = lastoffset;
	}
    }
    if (last2SegPtr == NULL) {
	return NULL;
    }
    if (last2SegPtr->typePtr == &tkTextIBTreeType) {
	nodePtr = ((BTree *)last2SegPtr->body.itree.tree)->rootPtr;
	intTree = last2SegPtr->body.itree.tree;
	goto haveNodeWithTag;
    } else {
	intIndexPtr->tree = intTree;
	intIndexPtr->linePtr = lastLinePtr;
	intIndexPtr->byteIndex = lastoffset2;

	/*
	 * The external index from the internal one (adding offsets up on
	 * the way down left out the heads of the blocks entered).
	 */

	TkTextIndexToExternalIndex(tree, intIndexPtr, indexPtr);
	return last2SegPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * NodeHoldsLine --
 *
 *	Whether a line is under a node, the trees of blocks counted: a
 *	line of a block's tree is under the nodes above the line that
 *	holds the block.
 *
 *----------------------------------------------------------------------
 */

static int
NodeHoldsLine(nodePtr, linePtr)
    Node *nodePtr;
    TkTextLine *linePtr;
{
    Node *n;

    if (linePtr == NULL) {
	return 0;
    }
    for (n = linePtr->parentPtr; n != NULL; ) {
	if (n == nodePtr) {
	    return 1;
	}
	if (n->parentPtr != NULL) {
	    n = n->parentPtr;
	} else if (n->segPtr != NULL) {
	    n = n->segPtr->body.itree.linePtr->parentPtr;
	} else {
	    break;
	}
    }
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeStartSearch --
 *
 *	This procedure sets up a search for tag transitions involving
 *	a given tag (or all tags) in a given range of the text.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The information at *searchPtr is set up so that subsequent calls
 *	to TkBTreeNextTag or TkBTreePrevTag will return information about the
 *	locations of tag transitions.  Note that TkBTreeNextTag or 
 *	TkBTreePrevTag must be called to get the first transition.
 *	Note: unlike TkBTreeNextTag and TkBTreePrevTag, this routine does not
 *	guarantee that searchPtr->curIndex is equal to *index1Ptr.  It may be
 *	greater than that if *index1Ptr is less than the first tag transition.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeStartSearch(index1Ptr, index2Ptr, tagPtr, searchPtr)
    TkTextIndex *index1Ptr;		/* Search starts here.  Tag toggles
					 * at this position will not be
					 * returned. */
    TkTextIndex *index2Ptr;		/* Search stops here.  Tag toggles
					 * at this position *will* be
					 * returned. */
    TkTextTag *tagPtr;			/* Tag to search for.  NULL means
					 * search for any tag. */
    register TkTextSearch *searchPtr;	/* Where to store information about
					 * search's progress. */
{
    int offset;
    TkTextIndex index0, intIndex0;	/* First index of the tag */
    TkTextSegment *seg0Ptr;		/* First segment of the tag */

    if (index1Ptr->tree != index2Ptr->tree) {
      panic("TkBTreeStartSearch got indices in different trees.");
    }
    if (index1Ptr->linePtr->parentPtr->segPtr) {
      panic("TkBTreeStartSearch got index in internal BTree.");
    }

    /*
     * Find the segment that contains the first toggle for the tag.  This
     * may become the starting point in the search.
     */

    seg0Ptr = FindTagStart(index1Ptr->tree, tagPtr, &index0, &intIndex0);
    if (seg0Ptr == (TkTextSegment *) NULL) {
	/*
	 * Even though there are no toggles, the display code still
	 * uses the search curIndex, so initialize that anyway.
	 */

	searchPtr->linesLeft = 0;
	searchPtr->extIndex = *index1Ptr;
	TkTextIndexToInternalSeg(index1Ptr,
			   &(searchPtr->curIndex),
			   &offset);
	searchPtr->segPtr = NULL;
	searchPtr->nextPtr = NULL;
	return;
    }
    if (TkTextIndexCmp(index1Ptr, &index0) < 0) {
	/*
	 * Adjust start of search up to the first range of the tag
	 */

	searchPtr->extIndex = index0;
	searchPtr->curIndex = intIndex0;
	searchPtr->segPtr = NULL;
	searchPtr->nextPtr = seg0Ptr;	/* Will be returned by NextTag */
	index1Ptr = &index0;
    } else {
	searchPtr->extIndex = *index1Ptr;
	searchPtr->segPtr = NULL;
	searchPtr->nextPtr = TkTextIndexToInternalSeg(index1Ptr,
						&(searchPtr->curIndex),
						&offset);
	searchPtr->curIndex.byteIndex -= offset;
    }
    {
	TkTextIndex lastIndex;

	searchPtr->lastPtr = TkTextIndexToInternalSeg(index2Ptr, &lastIndex,
		(int *) NULL);
	searchPtr->lastLinePtr = lastIndex.linePtr;
    }
    searchPtr->lastOffset = index2Ptr->byteIndex;
    searchPtr->tagPtr = tagPtr;
    searchPtr->tree = index1Ptr->tree;
    searchPtr->linesLeft = TkBTreeLineIndex(index2Ptr->linePtr) + 1
	    - TkBTreeLineIndex(index1Ptr->linePtr);
    searchPtr->allTags = (tagPtr == NULL);
    if (searchPtr->linesLeft == 1) {
	/*
	 * Starting and stopping segments are in the same line; mark the
	 * search as over immediately if the second segment is before the
	 * first.  A search does not return a toggle at the very start of
	 * the range, unless the range is artificially moved up to index0.
	 */
	if (((index1Ptr == &index0) && 
		(index1Ptr->byteIndex > index2Ptr->byteIndex)) ||
	    ((index1Ptr != &index0) && 
		(index1Ptr->byteIndex >= index2Ptr->byteIndex))) {
		searchPtr->linesLeft = 0;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeStartSearchBack --
 *
 *	This procedure sets up a search backwards for tag transitions involving
 *	a given tag (or all tags) in a given range of the text.  In the
 *	normal case the first index (*index1Ptr) is beyond the second
 *	index (*index2Ptr).
 *	
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The information at *searchPtr is set up so that subsequent calls
 *	to TkBTreePrevTag will return information about the
 *	locations of tag transitions.  Note that TkBTreePrevTag must be called
 *	to get the first transition.
 *	Note: unlike TkBTreeNextTag and TkBTreePrevTag, this routine does not
 *	guarantee that searchPtr->curIndex is equal to *index1Ptr.  It may be
 *	less than that if *index1Ptr is greater than the last tag transition.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeStartSearchBack(index1Ptr, index2Ptr, tagPtr, searchPtr)
    TkTextIndex *index1Ptr;		/* Search starts here.  Tag toggles
					 * at this position will not be
					 * returned. */
    TkTextIndex *index2Ptr;		/* Search stops here.  Tag toggles
					 * at this position *will* be
					 * returned. */
    TkTextTag *tagPtr;			/* Tag to search for.  NULL means
					 * search for any tag. */
    register TkTextSearch *searchPtr;	/* Where to store information about
					 * search's progress. */
{
    int offset, nothingBefore = 0;
    TkTextIndex index0, intIndex0;	/* Last index of the tag */
    TkTextIndex backOne;	/* One character before starting index */
    TkTextSegment *seg0Ptr;	/* Last segment of the tag */

    if (index1Ptr->tree != index2Ptr->tree) {
      panic("TkBTreeStartSearchBack got indices in different trees.");
    }
    if (index1Ptr->linePtr->parentPtr->segPtr) {
      panic("TkBTreeStartSearchBack got index in internal BTree.");
    }
    searchPtr->tree = index1Ptr->tree;
    searchPtr->extIndex = *index1Ptr;

    /*
     * Find the segment that contains the last toggle for the tag.  This
     * may become the starting point in the search.
     */

    seg0Ptr = FindTagEnd(index1Ptr->tree, tagPtr, &index0, &intIndex0);
    if (seg0Ptr == (TkTextSegment *) NULL) {
	/*
	 * Even though there are no toggles, the display code still
	 * uses the search curIndex, so initialize that anyway.
	 */

	searchPtr->linesLeft = 0;
	TkTextIndexToInternalSeg(index1Ptr,
			   &(searchPtr->curIndex),
			   &offset);
	searchPtr->segPtr = NULL;
	searchPtr->nextPtr = NULL;
	return;
    }

    /*
     * Adjust the start of the search so it doesn't find any tag toggles
     * that are right at the index specified by the user.
     */

    if (TkTextIndexCmp(index1Ptr, &index0) > 0) {
	searchPtr->curIndex = intIndex0;
    } else {
	TkTextIndexBackChars(index1Ptr, 1, &index0);
	if (TkTextIndexCmp(&index0, index1Ptr) == 0) {
	    /* index1 is the start of the text: nothing is before it. */
	    nothingBefore = 1;
	}
	TkTextIndexToInternalSeg(&index0,
			   &(searchPtr->curIndex),
			   &offset);
    }
    index1Ptr = &index0;		/* The (external) position where the
					 * scan really starts. */
    searchPtr->segPtr = NULL;
    /* Since curIndex is internal, we do not need TkTextIndexToInternalSeg: */
    searchPtr->nextPtr = TkTextIndexToSeg(&searchPtr->curIndex, &offset);
    searchPtr->curIndex.byteIndex -= offset;

    /*
     * Adjust the end of the search so it does find toggles that are right
     * at the second index specified by the user.
     */

    if ((TkBTreeLineIndex(index2Ptr->linePtr) == 0) &&
	    (index2Ptr->byteIndex == 0)) {
	backOne = *index2Ptr;
	searchPtr->lastPtr = NULL;	/* Signals special case for 1.0 */
	searchPtr->lastLinePtr = NULL;
	searchPtr->lastOffset = 0;
    } else {
	TkTextIndex lastIndex;

	TkTextIndexBackChars(index2Ptr, 1, &backOne);
	searchPtr->lastPtr = TkTextIndexToInternalSeg(&backOne, &lastIndex,
		(int *) NULL);
	searchPtr->lastLinePtr = lastIndex.linePtr;
	searchPtr->lastOffset = backOne.byteIndex;
    }
    searchPtr->tagPtr = tagPtr;
    searchPtr->linesLeft = TkBTreeLineIndex(index1Ptr->linePtr) + 1
	    - TkBTreeLineIndex(backOne.linePtr);
    searchPtr->allTags = (tagPtr == NULL);
    if (searchPtr->linesLeft == 1) {
	/*
	 * Starting and stopping segments are in the same line; mark the
	 * search as over immediately if the second segment is after the
	 * first.
	 */

	if ((searchPtr->lastPtr != NULL)
		&& (index1Ptr->byteIndex <= backOne.byteIndex)) {
	    searchPtr->linesLeft = 0;
	}
    }
    if (nothingBefore) {
	searchPtr->linesLeft = 0;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeNextTag --
 *
 *	Once a tag search has begun, successive calls to this procedure
 *	return successive tag toggles.  Note:  it is NOT SAFE to call this
 *	procedure if characters have been inserted into or deleted from
 *	the B-tree since the call to TkBTreeStartSearch.
 *
 * Results:
 *	The return value is 1 if another toggle was found that met the
 *	criteria specified in the call to TkBTreeStartSearch;  in this
 *	case searchPtr->curIndex gives the toggle's position and
 *	searchPtr->curTagPtr points to its segment.  0 is returned if
 *	no more matching tag transitions were found; in this case
 *	searchPtr->curIndex is the same as searchPtr->stopIndex.
 *
 * Side effects:
 *	Information in *searchPtr is modified to update the state of the
 *	search and indicate where the next tag toggle is located.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeNextTag(searchPtr)
    register TkTextSearch *searchPtr;	/* Information about search in
					 * progress;  must have been set up by
					 * call to TkBTreeStartSearch. */
{
    register TkTextSegment *segPtr;
    register Node *nodePtr;
    register Summary *summaryPtr;

    if (searchPtr->linesLeft <= 0) {
	goto searchOver;
    }

    /*
     * The outermost loop iterates over lines that may potentially contain
     * a relevant tag transition, starting from the current segment in
     * the current line.
     */

    segPtr = searchPtr->nextPtr;
    while (1) {
       	/*
	 * Check for more tags on the current line.
	 */

	for ( ; segPtr != NULL; segPtr = segPtr->nextPtr) {
	    if (segPtr == searchPtr->lastPtr) {
		goto searchOver;
	    }
	    if (((segPtr->typePtr == &tkTextToggleOnType)
		    || (segPtr->typePtr == &tkTextToggleOffType))
		    && (searchPtr->allTags
		    || (segPtr->body.toggle.tagPtr == searchPtr->tagPtr))) {
	        TkTextIndexToExternalIndex(searchPtr->tree,
			      &searchPtr->curIndex, &searchPtr->extIndex);
		searchPtr->segPtr = segPtr;
		searchPtr->nextPtr = segPtr->nextPtr;
		searchPtr->tagPtr = segPtr->body.toggle.tagPtr;
		return 1;
	    } else if ((segPtr->typePtr == &tkTextIBTreeType)
		       && segPtr->body.itree.tree) {
		if ( (summaryPtr =
		      ((BTree *)segPtr->body.itree.tree)->rootPtr->summaryPtr) ) {
		    for ( ; summaryPtr; summaryPtr = summaryPtr->nextPtr) {
			if (searchPtr->allTags 
			    || (summaryPtr->tagPtr == searchPtr->tagPtr)) {
			    nodePtr = ((BTree *)segPtr->body.itree.tree)->rootPtr;
			    goto gotNodeWithTag;
			}
		    }
		}
		if (searchPtr->linesLeft == 1) {
		    TkTextIndex ext;

		    /*
		     * On the last line: if the stop position is inside this
		     * block (which holds no relevant toggle) or before it, the
		     * search is over.  Compare external offsets: curIndex may
		     * be inside a block itself, lastOffset is external.
		     */

		    TkTextIndexToExternalIndex(searchPtr->tree, &searchPtr->curIndex,
			    &ext);
		    if (ext.byteIndex + segPtr->size > searchPtr->lastOffset) {
			goto searchOver;
		    }
		}
	    }
	    searchPtr->curIndex.byteIndex += segPtr->size;
	}
    
	/*
	 * See if there are more lines associated with the current parent
	 * node.  If so, go back to the top of the loop to search the next
	 * one.
	 */

	nodePtr = searchPtr->curIndex.linePtr->parentPtr;
	searchPtr->curIndex.linePtr = searchPtr->curIndex.linePtr->nextPtr;
	if (!nodePtr->segPtr) {
	  searchPtr->linesLeft--;
	  if (searchPtr->linesLeft <= 0) {
	    goto searchOver;
	  }
	}
	if (searchPtr->curIndex.linePtr != NULL) {
	    segPtr = searchPtr->curIndex.linePtr->segPtr;
	    searchPtr->curIndex.byteIndex = 0;
	    continue;
	}
	if (nodePtr == searchPtr->tagPtr->tagRootPtr) {
	    goto searchOver;
	}
    
	/*
	 * Search across and up through the B-tree's node hierarchy looking
	 * for the next node that has a relevant tag transition somewhere in
	 * its subtree.  Be sure to update linesLeft as we skip over large
	 * chunks of lines.
	 */
	
	while (1) {
	    while (nodePtr->nextPtr == NULL) {
		if (nodePtr->parentPtr == NULL ||
		    nodePtr->parentPtr == searchPtr->tagPtr->tagRootPtr) {
		    if (nodePtr->segPtr) {
			/* Cannot happen if nodePtr->parentPtr != NULL. */
		      TkTextSegment *segPtr1;

		      /* Get up one level. */
		      segPtr = nodePtr->segPtr;
		      searchPtr->curIndex.byteIndex = segPtr->size;
		      searchPtr->curIndex.linePtr = segPtr->body.itree.linePtr;
		      searchPtr->curIndex.tree =
			segPtr->body.itree.linePtr->parentPtr->segPtr 
			  ? segPtr->body.itree.linePtr->parentPtr->segPtr
			    ->body.itree.tree
			  : searchPtr->tree;
		      for (segPtr1 = searchPtr->curIndex.linePtr->segPtr;
			   segPtr1 != segPtr;
			   segPtr1 = segPtr1->nextPtr) {
			searchPtr->curIndex.byteIndex += segPtr1->size;
		      }
		      segPtr = segPtr->nextPtr;
/*
		      for (linePtr =
			   TkBTreeFindLine(searchPtr->curIndex.tree, 0);
			   linePtr != searchPtr->curIndex.linePtr;
			   linePtr = linePtr->nextPtr) {
			searchPtr->curIndex.byteIndex 
			  += TkBTreeCharsInLine(linePtr);
		      }
*/
		      goto nextSegment;
		    } else {
		      goto searchOver;
		    }
		}
		nodePtr = nodePtr->parentPtr;
	    }
	    nodePtr = nodePtr->nextPtr;
	    for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
		    summaryPtr = summaryPtr->nextPtr) {
		if ((searchPtr->allTags) ||
			(summaryPtr->tagPtr == searchPtr->tagPtr)) {
		    goto gotNodeWithTag;
		}
	    }
	    if (NodeHoldsLine(nodePtr, searchPtr->lastLinePtr)) {
		goto searchOver;	/* The stop is in the node skipped. */
	    }
	    if (!nodePtr->segPtr) {
	      searchPtr->linesLeft -= nodePtr->numLines;
	    }
	}
    
	/*
	 * At this point we've found a subtree that has a relevant tag
	 * transition.  Now search down (and across) through that subtree
	 * to find the first level-0 node that has a relevant tag transition.
	 */
    
	gotNodeWithTag:
	while (nodePtr->level > 0) {
	    for (nodePtr = nodePtr->children.nodePtr; ;
		    nodePtr = nodePtr->nextPtr) {
		for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
			summaryPtr = summaryPtr->nextPtr) {
		    if ((searchPtr->allTags)
			    || (summaryPtr->tagPtr == searchPtr->tagPtr)) {
			goto nextChild;
		    }
		}
		if (NodeHoldsLine(nodePtr, searchPtr->lastLinePtr)) {
		    goto searchOver;	/* The stop is in the node skipped. */
		}
		if (!nodePtr->segPtr) {
		  searchPtr->linesLeft -= nodePtr->numLines;
		}
		if (nodePtr->nextPtr == NULL) {
		    panic("TkBTreeNextTag found incorrect tag summary info.");
		}
	    }
	    nextChild:
	    continue;
	}
    
	/*
	 * Now we're down to a level-0 node that contains a line that contains
	 * a relevant tag transition.  Set up line information and go back to
	 * the beginning of the loop to search through lines.
	 */

	searchPtr->curIndex.linePtr = nodePtr->children.linePtr;
	searchPtr->curIndex.byteIndex = 0;
	segPtr = searchPtr->curIndex.linePtr->segPtr;
	if (searchPtr->linesLeft <= 0) {
	    goto searchOver;
	}
        nextSegment:
	continue;
    }

    searchOver:
    searchPtr->linesLeft = 0;
    searchPtr->segPtr = NULL;
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreePrevTag --
 *
 *	Once a tag search has begun, successive calls to this procedure
 *	return successive tag toggles in the reverse direction.
 *	Note:  it is NOT SAFE to call this
 *	procedure if characters have been inserted into or deleted from
 *	the B-tree since the call to TkBTreeStartSearch.
 *
 * Results:
 *	The return value is 1 if another toggle was found that met the
 *	criteria specified in the call to TkBTreeStartSearch;  in this
 *	case searchPtr->curIndex gives the toggle's position and
 *	searchPtr->curTagPtr points to its segment.  0 is returned if
 *	no more matching tag transitions were found; in this case
 *	searchPtr->curIndex is the same as searchPtr->stopIndex.
 *
 * Side effects:
 *	Information in *searchPtr is modified to update the state of the
 *	search and indicate where the next tag toggle is located.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreePrevTag(searchPtr)
    register TkTextSearch *searchPtr;	/* Information about search in
					 * progress;  must have been set up by
					 * call to TkBTreeStartSearchBack. */
{
    register TkTextSegment *segPtr, *prevPtr;
    register TkTextLine *linePtr, *prevLinePtr;
    register Node *nodePtr, *node2Ptr, *prevNodePtr;
    register Summary *summaryPtr;
    int charIndex, prevCharIndex;
    int extBase;			/* External offset of the start of the
					 * line being scanned (0 unless the
					 * line is inside a block). */
    int pastLast;			/* Saw last marker during scan */
    int linesSkipped, stopSkipped;

    if (searchPtr->linesLeft <= 0) {
	goto searchOver;
    }

    while (1) {
	/*
	 * Scan the current line from its start up to nextPtr, remembering
	 * the last toggle of the tag, or the last block that has the tag
	 * somewhere inside.  Lines inside blocks share the index space of
	 * the enclosing line, so the stop position (lastOffset, an external
	 * offset) is compared with external offsets.
	 */

      scanLine:
	extBase = 0;
	if (searchPtr->curIndex.linePtr->parentPtr->segPtr) {
	    TkTextIndex lineStart, extStart;

	    lineStart = searchPtr->curIndex;
	    lineStart.byteIndex = 0;
	    TkTextIndexToExternalIndex(searchPtr->tree, &lineStart, &extStart);
	    extBase = extStart.byteIndex;
	}
	pastLast = (searchPtr->lastPtr == NULL)
	    || (searchPtr->linesLeft == 1 && extBase > searchPtr->lastOffset);
	charIndex = 0;
	prevCharIndex = 0;
	for (prevPtr = NULL, segPtr = searchPtr->curIndex.linePtr->segPtr ;
		segPtr != NULL && segPtr != searchPtr->nextPtr;
		segPtr = segPtr->nextPtr) {
	    if (((segPtr->typePtr == &tkTextToggleOnType)
		    || (segPtr->typePtr == &tkTextToggleOffType))
		    && (searchPtr->allTags
		    || (segPtr->body.toggle.tagPtr == searchPtr->tagPtr))) {
		prevPtr = segPtr;
		prevCharIndex = charIndex;
	    } else if ((segPtr->typePtr == &tkTextIBTreeType)
		       && segPtr->body.itree.tree) {
		int blockStart = extBase + charIndex;
		int blockEnd = blockStart + segPtr->size;
		int stopOnLine = (searchPtr->linesLeft == 1
				  && searchPtr->lastPtr != NULL);

		if (stopOnLine && blockEnd <= searchPtr->lastOffset) {
		    /* The block lies entirely before the stop position. */
		} else {
		    for (summaryPtr =
			     ((BTree *)segPtr->body.itree.tree)->rootPtr->summaryPtr;
			 summaryPtr; summaryPtr = summaryPtr->nextPtr) {
			if (searchPtr->allTags 
			    || (summaryPtr->tagPtr == searchPtr->tagPtr)) {
			    prevPtr = segPtr;	/* The tag occurs in the block. */
			    prevCharIndex = charIndex;
			    break;
			}
		    }
		    if (stopOnLine && blockStart <= searchPtr->lastOffset) {
			/*
			 * The stop position is inside the block: what is
			 * before the block does not count, but the block
			 * itself may (its toggles after the stop).
			 */

			if (prevPtr != segPtr) {
			    prevPtr = NULL;
			}
			pastLast = 1;
		    }
		}
	    }
	    if ((segPtr == searchPtr->lastPtr)
		    && (segPtr->typePtr != &tkTextIBTreeType)) {
	        prevPtr = NULL;   /* Segments earlier than last don't count */
		pastLast = 1;
	    }
	    charIndex += segPtr->size;
	}
	if (prevPtr != NULL) {
	    if (prevPtr->typePtr == &tkTextIBTreeType) {
		/*
		 * Descend into the block: its last toggle is the one.
		 */

		nodePtr = ((BTree *)prevPtr->body.itree.tree)->rootPtr;
		goto gotNodeWithTag;
	    }
	    if (searchPtr->linesLeft == 1 && !pastLast) {
		/*
		 * The toggle is before the stop position on the last line.
		 */

		goto searchOver;
	    }
	    searchPtr->curIndex.byteIndex = prevCharIndex;
	    searchPtr->segPtr = prevPtr;
	    searchPtr->nextPtr = prevPtr;
	    searchPtr->tagPtr = prevPtr->body.toggle.tagPtr;
	    TkTextIndexToExternalIndex(searchPtr->tree, &searchPtr->curIndex,
				       &searchPtr->extIndex);
	    return 1;
	}

	/*
	 * Nothing on this line.  Go to the previous line of the same node;
	 * only lines of the outermost tree count against linesLeft.
	 */

	nodePtr = searchPtr->curIndex.linePtr->parentPtr;
	if (!nodePtr->segPtr) {
	    searchPtr->linesLeft--;
	    if (searchPtr->linesLeft <= 0) {
		goto searchOver;
	    }
	}
	for (prevLinePtr = NULL, linePtr = nodePtr->children.linePtr;
		linePtr != NULL && linePtr != searchPtr->curIndex.linePtr;
		prevLinePtr = linePtr, linePtr = linePtr->nextPtr) {
	    /* empty loop body */ ;
	}
	if (prevLinePtr != NULL) {
	    searchPtr->curIndex.linePtr = prevLinePtr;
	    searchPtr->nextPtr = NULL;
	    continue;
	}
	if (!searchPtr->allTags
		&& (nodePtr == searchPtr->tagPtr->tagRootPtr)) {
	    goto searchOver;
	}
    
	/*
	 * Search across and up through the tree to find a previous node
	 * with the tag.  The root of a block's tree is left for the
	 * enclosing line, where the search continues before the block.
	 */
    
	while (1) {
	    if (nodePtr->parentPtr == NULL) {
		if (nodePtr->segPtr) {
		    segPtr = nodePtr->segPtr;
		    searchPtr->curIndex.linePtr = segPtr->body.itree.linePtr;
		    searchPtr->curIndex.byteIndex = 0;
		    searchPtr->curIndex.tree =
			segPtr->body.itree.linePtr->parentPtr->segPtr
			  ? segPtr->body.itree.linePtr->parentPtr->segPtr
			    ->body.itree.tree
			  : searchPtr->tree;
		    searchPtr->nextPtr = segPtr;
		    goto scanLine;
		}
		goto searchOver;
	    }
	    for (prevNodePtr = NULL, linesSkipped = 0, stopSkipped = 0,
		    node2Ptr = nodePtr->parentPtr->children.nodePtr ;
		    node2Ptr != nodePtr;  node2Ptr = node2Ptr->nextPtr) {
		for (summaryPtr = node2Ptr->summaryPtr; summaryPtr != NULL;
			summaryPtr = summaryPtr->nextPtr) {
		    if ((searchPtr->allTags) ||
			    (summaryPtr->tagPtr == searchPtr->tagPtr)) {
			prevNodePtr = node2Ptr;
			linesSkipped = 0;
			stopSkipped = 0;
			goto keepLooking;
		    }
		}
		linesSkipped += node2Ptr->numLines;
		if (NodeHoldsLine(node2Ptr, searchPtr->lastLinePtr)) {
		    stopSkipped = 1;
		}

		keepLooking:
		continue;
	    }
	    if (stopSkipped) {
		goto searchOver;	/* The stop is in a node skipped. */
	    }
	    if (prevNodePtr != NULL) {
		nodePtr = prevNodePtr;
		if (!nodePtr->segPtr) {
		    searchPtr->linesLeft -= linesSkipped;
		}
		goto gotNodeWithTag;
	    }
	    nodePtr = nodePtr->parentPtr;
	    if (!searchPtr->allTags
		    && (nodePtr == searchPtr->tagPtr->tagRootPtr)) {
		goto searchOver;
	    }
	}
    
	/*
	 * At this point nodePtr refers to a node that contains the tag.
	 * Descend to its last line that has the tag, then scan that line.
	 */
    
	gotNodeWithTag:
	while (nodePtr->level > 0) {
	    for (linesSkipped = 0, prevNodePtr = NULL, stopSkipped = 0,
		    nodePtr = nodePtr->children.nodePtr; nodePtr != NULL ;
		    nodePtr = nodePtr->nextPtr) {
		for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
			summaryPtr = summaryPtr->nextPtr) {
		    if ((searchPtr->allTags)
			    || (summaryPtr->tagPtr == searchPtr->tagPtr)) {
			prevNodePtr = nodePtr;
			linesSkipped = 0;
			stopSkipped = 0;
			goto keepLooking2;
		    }
		}
		linesSkipped += nodePtr->numLines;
		if (NodeHoldsLine(nodePtr, searchPtr->lastLinePtr)) {
		    stopSkipped = 1;
		}

		keepLooking2:
		continue;
	    }
	    if (prevNodePtr == NULL) {
		panic("TkBTreePrevTag found incorrect tag summary info.");
	    }
	    if (stopSkipped) {
		goto searchOver;	/* The stop is in a node skipped. */
	    }
	    if (!prevNodePtr->segPtr) {
		searchPtr->linesLeft -= linesSkipped;
	    }
	    nodePtr = prevNodePtr;
	}
    
	for (prevLinePtr = NULL, linePtr = nodePtr->children.linePtr;
		linePtr != NULL ;
		prevLinePtr = linePtr, linePtr = linePtr->nextPtr) {
	    /* empty loop body */ ;
	}
	searchPtr->curIndex.linePtr = prevLinePtr;
	searchPtr->curIndex.byteIndex = 0;
	searchPtr->nextPtr = NULL;
	if (searchPtr->linesLeft <= 0) {
	    goto searchOver;
	}
	continue;
    }

    searchOver:
    searchPtr->linesLeft = 0;
    searchPtr->segPtr = NULL;
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeCharTagged --
 *
 *	Determine whether a particular character has a particular tag.
 *
 * Results:
 *	The return value is 1 if the given tag is in effect at the
 *	character given by linePtr and ch, and 0 otherwise.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeCharTagged(oldIndexPtr, tagPtr)
    TkTextIndex *oldIndexPtr;		/* Indicates a character position at
					 * which to check for a tag. */
    TkTextTag *tagPtr;			/* Tag of interest. */
{
    register Node *nodePtr;
    register TkTextLine *siblingLinePtr;
    register TkTextSegment *segPtr;
    TkTextIndex index;
    TkTextSegment *toggleSegPtr;
    int toggles, offset, countAfter = 0, countAfter1 = 0;
    register Summary *summaryPtr;

    (void) TkTextIndexToInternalSeg(oldIndexPtr, &index, NULL);

    /* 
     * Check for toggles for the tag in index's line but before
     * index.  If there is one, its type indicates whether or
     * not the character is tagged.
     */

    toggleSegPtr = NULL;
    for (offset = 0, segPtr = index.linePtr->segPtr;
	    (offset + segPtr->size) <= index.byteIndex;
	    offset += segPtr->size, segPtr = segPtr->nextPtr) {
	if (((segPtr->typePtr == &tkTextToggleOnType)
		|| (segPtr->typePtr == &tkTextToggleOffType))
		&& (segPtr->body.toggle.tagPtr == tagPtr)) {
	    toggleSegPtr = segPtr;
	    countAfter = 0;
	} else if (segPtr->typePtr == &tkTextIBTreeType 
		   && segPtr->body.itree.tree
		   && (summaryPtr = ((BTree *)segPtr->body.itree.tree)
		                      ->rootPtr->summaryPtr)) {
	  /* Look for tag transitions inside */
	  for ( ; summaryPtr; summaryPtr = summaryPtr->nextPtr ) {
	    if ( summaryPtr->tagPtr == tagPtr ) {
	      countAfter += summaryPtr->toggleCount; 
	      break;
	    }
	  }
	}
    }

    if (toggleSegPtr != NULL) {		/* We saw toplevel transition. */
	return ((toggleSegPtr->typePtr == &tkTextToggleOnType)
		^ (countAfter & 1));
    }

    /*
     * No toggle in this line.  Look for toggles for the tag in lines
     * that are predecessors of index.linePtr but under the same
     * level-0 node.
     */

    toggles = 0;
    for (siblingLinePtr = index.linePtr->parentPtr->children.linePtr;
	    siblingLinePtr != index.linePtr;
	    siblingLinePtr = siblingLinePtr->nextPtr) {
	for (segPtr = siblingLinePtr->segPtr; segPtr != NULL;
		segPtr = segPtr->nextPtr) {
	    if (((segPtr->typePtr == &tkTextToggleOnType)
		    || (segPtr->typePtr == &tkTextToggleOffType))
		    && (segPtr->body.toggle.tagPtr == tagPtr)) {
		toggleSegPtr = segPtr;
		countAfter1 = 0;
	    } else if ((segPtr->typePtr == &tkTextIBTreeType)
		       && segPtr->body.itree.tree
		       && (summaryPtr = 
			   ((BTree *)segPtr->body.itree.tree)
			     ->rootPtr->summaryPtr)) {
	      /* Look for tag transitions inside */
	      for ( ; summaryPtr; summaryPtr = summaryPtr->nextPtr ) {
		if ( summaryPtr->tagPtr == tagPtr ) {
		  countAfter1 += summaryPtr->toggleCount; 
		  break;
		}
	      }
	    } 
	}
    }
    if (toggleSegPtr != NULL) {
	return ((toggleSegPtr->typePtr == &tkTextToggleOnType)
		^ (countAfter & 1) ^ (countAfter1 & 1));
    }

    /*
     * No toggle in this node.  Scan upwards through the ancestors of
     * this node, counting the number of toggles of the given tag in
     * siblings that precede that node.
     */

    toggles = 0;
    for (nodePtr = index.linePtr->parentPtr; nodePtr->parentPtr != NULL;
	    nodePtr = nodePtr->parentPtr) {
	register Node *siblingPtr;

	for (siblingPtr = nodePtr->parentPtr->children.nodePtr; 
		siblingPtr != nodePtr; siblingPtr = siblingPtr->nextPtr) {
	    for (summaryPtr = siblingPtr->summaryPtr; summaryPtr != NULL;
		    summaryPtr = summaryPtr->nextPtr) {
		if (summaryPtr->tagPtr == tagPtr) {
		    toggles += summaryPtr->toggleCount;
		}
	    }
	}
	if (nodePtr == tagPtr->tagRootPtr) {
	    break;
	}
    }

    /* Look for tag situation outside of the tree */

    if (nodePtr->segPtr) {
      index.linePtr = nodePtr->segPtr->body.itree.linePtr;
      /* We do not use index.tree. */

      for (index.byteIndex = 0, segPtr = index.linePtr->segPtr;
	   segPtr != nodePtr->segPtr;
	   index.byteIndex += segPtr->size, segPtr = segPtr->nextPtr) 
	; /* empty */
      toggles ^= TkBTreeCharTagged(&index, tagPtr);
    }

    /*
     * An odd number of toggles means that the tag is present at the
     * given point.
     */

    return (toggles & 1) ^ (countAfter & 1) ^ (countAfter1 & 1);
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeGetTags, TkBTreeGetTagsInEffect --
 *
 *	Return information about all of the tags that are associated
 *	with a particular character in a B-tree of text.
 *
 *	They differ at the head of a block only.  TkBTreeGetTagsInEffect
 *	("tag names") gives the tags in effect there, as "tag ranges",
 *	"dump" and the searches count them.  TkBTreeGetTags (the
 *	display, the elide test, the mouse bindings) answers another
 *	question, which tags style the block as a whole: it leaves out
 *	a tag that switches off inside the block (TkIBTreeFixTags, the
 *	1997 design).
 *
 * Results:
 *	The return value is a malloc-ed array containing pointers to
 *	information for each of the tags that is associated with
 *	the character at the position given by linePtr and ch.  The
 *	word at *numTagsPtr is filled in with the number of pointers
 *	in the array.  It is up to the caller to free the array by
 *	passing it to free.  If there are no tags at the given character
 *	then a NULL pointer is returned and *numTagsPtr will be set to 0.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static TkTextTag **	GetTags _ANSI_ARGS_((TkTextIndex *oldIndexPtr,
			    int *numTagsPtr, int wholeBlock));

TkTextTag **
TkBTreeGetTags(oldIndexPtr, numTagsPtr)
    TkTextIndex *oldIndexPtr;	/* Indicates a particular position in
				 * the B-tree. */
    int *numTagsPtr;		/* Store number of tags found at this
				 * location. */
{
    return GetTags(oldIndexPtr, numTagsPtr, 1);
}

TkTextTag **
TkBTreeGetTagsInEffect(oldIndexPtr, numTagsPtr)
    TkTextIndex *oldIndexPtr;	/* Indicates a particular position in
				 * the B-tree. */
    int *numTagsPtr;		/* Store number of tags found at this
				 * location. */
{
    return GetTags(oldIndexPtr, numTagsPtr, 0);
}

	/* ARGSUSED */
static TkTextTag **
GetTags(oldIndexPtr, numTagsPtr, wholeBlock)
    TkTextIndex *oldIndexPtr;	/* Indicates a particular position in
				 * the B-tree. */
    int *numTagsPtr;		/* Store number of tags found at this
				 * location. */
    int wholeBlock;		/* At the head of a block: non-zero for
				 * the tags constant over the whole
				 * block only. */
{
    TkTextIndex tIndex;		/* Indicates a particular position in
				 * the B-tree. */
    TkTextIndex *indexPtr = &tIndex;	/* Indicates the internal description
					 * of position in the B-tree. */
    register Node *nodePtr;
    register TkTextLine *siblingLinePtr;
    register TkTextSegment *segPtr;
    int src, dst, index, restarted = 0;
    TagInfo tagInfo;
    TkTextSegment *iBTreeSegPtr = NULL;	/* If the index corresponds to
					 * the start of IBTree, this
					 * is the segment. */
#define NUM_TAG_INFOS 10

    tagInfo.numTags = 0;
    tagInfo.arraySize = NUM_TAG_INFOS;
    tagInfo.tagPtrs = (TkTextTag **) ckalloc((unsigned)
	    NUM_TAG_INFOS*sizeof(TkTextTag *));
    tagInfo.counts = (int *) ckalloc((unsigned)
	    NUM_TAG_INFOS*sizeof(int));

    (void) TkTextIndexToInternalSeg(oldIndexPtr, indexPtr, NULL);

  restart:

    /*
     * Record tag toggles within the line of indexPtr but preceding
     * indexPtr.
     */


    for (index = 0, segPtr = indexPtr->linePtr->segPtr;
	    (index + segPtr->size) <= indexPtr->byteIndex;
	    index += segPtr->size, segPtr = segPtr->nextPtr) {
	if ((segPtr->typePtr == &tkTextToggleOnType)
		|| (segPtr->typePtr == &tkTextToggleOffType)) {
	    IncCount(segPtr->body.toggle.tagPtr, 1, &tagInfo);
	} else if ((segPtr->typePtr == &tkTextIBTreeType) 
		   && segPtr->body.itree.tree) {
	  Summary *summaryPtr = ((BTree *)segPtr->body.itree.tree)->rootPtr->summaryPtr;

	  for ( ; summaryPtr; summaryPtr = summaryPtr->nextPtr) {
	    IncCount(summaryPtr->tagPtr,
		     summaryPtr->toggleCount, &tagInfo);	    
	  }
	}
    }

    /* Check for IBTree segment. */

    if (!restarted && (index == indexPtr->byteIndex) 
	&& (segPtr->typePtr == &tkTextIBTreeType)) {
        iBTreeSegPtr = segPtr;
    }
    
    /*
     * Record toggles for tags in lines that are predecessors of
     * indexPtr->linePtr but under the same level-0 node.
     */

    for (siblingLinePtr = indexPtr->linePtr->parentPtr->children.linePtr;
	    siblingLinePtr != indexPtr->linePtr;
	    siblingLinePtr = siblingLinePtr->nextPtr) {
	for (segPtr = siblingLinePtr->segPtr; segPtr != NULL;
		segPtr = segPtr->nextPtr) {
	    if ((segPtr->typePtr == &tkTextToggleOnType)
		    || (segPtr->typePtr == &tkTextToggleOffType)) {
		IncCount(segPtr->body.toggle.tagPtr, 1, &tagInfo);
	    } else if (segPtr->typePtr == &tkTextIBTreeType 
		       && segPtr->body.itree.tree) {
	      Summary *summaryPtr =
		((BTree *)segPtr->body.itree.tree)->rootPtr->summaryPtr; 

	      for ( ; summaryPtr; summaryPtr = summaryPtr->nextPtr) {
		IncCount(summaryPtr->tagPtr,
			 summaryPtr->toggleCount, &tagInfo);	    
	      }
	    }
	}
    }

    /*
     * For each node in the ancestry of this line, record tag toggles
     * for all siblings that precede that node.
     */

    for (nodePtr = indexPtr->linePtr->parentPtr; nodePtr->parentPtr != NULL;
	    nodePtr = nodePtr->parentPtr) {
	register Node *siblingPtr;
	register Summary *summaryPtr;

	for (siblingPtr = nodePtr->parentPtr->children.nodePtr; 
		siblingPtr != nodePtr; siblingPtr = siblingPtr->nextPtr) {
	    for (summaryPtr = siblingPtr->summaryPtr; summaryPtr != NULL;
		    summaryPtr = summaryPtr->nextPtr) {
		if (summaryPtr->toggleCount & 1) {
		    IncCount(summaryPtr->tagPtr, summaryPtr->toggleCount,
			    &tagInfo);
		}
	    }
	}
    }

    /* Now look in the ambient trees */

    if (nodePtr->segPtr) {
      indexPtr->linePtr = nodePtr->segPtr->body.itree.linePtr;

      /* Do not need to update indexPtr->tree, it is not used here. */

      for (indexPtr->byteIndex = 0, segPtr = indexPtr->linePtr->segPtr;
	   segPtr != nodePtr->segPtr;
	   indexPtr->byteIndex += segPtr->size, segPtr = segPtr->nextPtr) {
	/* empty */
      }
      restarted = 1;
      goto restart;
    }

    /*
     * Go through the tag information and squash out all of the tags
     * that have even toggle counts (these tags exist before the point
     * of interest, but not at the desired character itself).
     */

    for (src = 0, dst = 0; src < tagInfo.numTags; src++) {
	if (tagInfo.counts[src] & 1) {
	    tagInfo.tagPtrs[dst] = tagInfo.tagPtrs[src];
	    dst++;
	}
    }
    *numTagsPtr = dst;
    ckfree((char *) tagInfo.counts);
    if (iBTreeSegPtr && wholeBlock) {
      TkIBTreeFixTags(iBTreeSegPtr, tagInfo.tagPtrs, numTagsPtr);
    }
    if (*numTagsPtr == 0) {
	ckfree((char *) tagInfo.tagPtrs);
	return NULL;
    }
    return tagInfo.tagPtrs;
}

/*
 *----------------------------------------------------------------------
 *
 * IncCount --
 *
 *	This is a utility procedure used by GetTags.  It
 *	increments the count for a particular tag, adding a new
 *	entry for that tag if there wasn't one previously.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The information at *tagInfoPtr may be modified, and the arrays
 *	may be reallocated to make them larger.
 *
 *----------------------------------------------------------------------
 */

static void
IncCount(tagPtr, inc, tagInfoPtr)
    TkTextTag *tagPtr;		/* Handle for tag. */
    int inc;			/* Amount by which to increment tag count. */
    TagInfo *tagInfoPtr;	/* Holds cumulative information about tags;
				 * increment count here. */
{
    register TkTextTag **tagPtrPtr;
    int count;

    for (tagPtrPtr = tagInfoPtr->tagPtrs, count = tagInfoPtr->numTags;
	    count > 0; tagPtrPtr++, count--) {
	if (*tagPtrPtr == tagPtr) {
	    tagInfoPtr->counts[tagInfoPtr->numTags-count] += inc;
	    return;
	}
    }

    /*
     * There isn't currently an entry for this tag, so we have to
     * make a new one.  If the arrays are full, then enlarge the
     * arrays first.
     */

    if (tagInfoPtr->numTags == tagInfoPtr->arraySize) {
	TkTextTag **newTags;
	int *newCounts, newSize;

	newSize = 2*tagInfoPtr->arraySize;
	newTags = (TkTextTag **) ckalloc((unsigned)
		(newSize*sizeof(TkTextTag *)));
	memcpy((VOID *) newTags, (VOID *) tagInfoPtr->tagPtrs,
		tagInfoPtr->arraySize * sizeof(TkTextTag *));
	ckfree((char *) tagInfoPtr->tagPtrs);
	tagInfoPtr->tagPtrs = newTags;
	newCounts = (int *) ckalloc((unsigned) (newSize*sizeof(int)));
	memcpy((VOID *) newCounts, (VOID *) tagInfoPtr->counts,
		tagInfoPtr->arraySize * sizeof(int));
	ckfree((char *) tagInfoPtr->counts);
	tagInfoPtr->counts = newCounts;
	tagInfoPtr->arraySize = newSize;
    }

    tagInfoPtr->tagPtrs[tagInfoPtr->numTags] = tagPtr;
    tagInfoPtr->counts[tagInfoPtr->numTags] = inc;
    tagInfoPtr->numTags++;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeCheck --
 *
 *	This procedure runs a set of consistency checks over a B-tree
 *	and panics if any inconsistencies are found.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If a structural defect is found, the procedure panics with an
 *	error message.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeCheck(tree)
    TkTextBTree tree;		/* Tree to check. */
{
    BTree *treePtr = (BTree *) tree;
    register Summary *summaryPtr, *summaryPtr2;
    register Node *nodePtr, *childNodePtr;
    register TkTextLine *linePtr;
    register TkTextSegment *segPtr;
    register TkTextTag *tagPtr;
    Tcl_HashEntry *entryPtr;
    Tcl_HashSearch search;
    int count;


    if (!((BTree *)tree)->rootPtr->segPtr) { /* Outermost tree */
	for (summaryPtr = treePtr->rootPtr->summaryPtr; summaryPtr != NULL;
	     summaryPtr = summaryPtr->nextPtr) {
	    if (summaryPtr->toggleCount & 1) {
		panic("TkBTreeCheck found odd toggle count for \"%s\" (%d)",
		      summaryPtr->tagPtr->name, summaryPtr->toggleCount);
	    }
	}

	/*
	 * Make sure that the tag toggle counts and the tag root pointers are OK.
	 */
	for (entryPtr = Tcl_FirstHashEntry(&treePtr->textPtr->tagTable, &search);
	     entryPtr != NULL ; entryPtr = Tcl_NextHashEntry(&search)) {
	    tagPtr = (TkTextTag *) Tcl_GetHashValue(entryPtr);
	    nodePtr = tagPtr->tagRootPtr;
	    if (nodePtr == (Node *) NULL) {
		if (tagPtr->toggleCount != 0) {
		    panic("TkBTreeCheck found \"%s\" with toggles (%d) but no root",
			  tagPtr->name, tagPtr->toggleCount);
		}
		continue;		/* no ranges for the tag */
	    } else if (tagPtr->toggleCount == 0) {
		panic("TkBTreeCheck found root for \"%s\" with no toggles",
		      tagPtr->name);
	    } else if (tagPtr->toggleCount & 1) {
		panic("TkBTreeCheck found odd toggle count for \"%s\" (%d)",
		      tagPtr->name, tagPtr->toggleCount);
	    }
	    for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
		 summaryPtr = summaryPtr->nextPtr) {
		if (summaryPtr->tagPtr == tagPtr) {
		    panic("TkBTreeCheck found root node with summary info");
		}
	    }
	    count = 0;
	    if (nodePtr->level > 0) {
		for (nodePtr = nodePtr->children.nodePtr ; nodePtr != NULL ;
		     nodePtr = nodePtr->nextPtr) {
		    for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
			 summaryPtr = summaryPtr->nextPtr) {
			if (summaryPtr->tagPtr == tagPtr) {
			    count += summaryPtr->toggleCount;
			}
		    }
		}
	    } else {
		for (linePtr = nodePtr->children.linePtr ; linePtr != NULL ;
		     linePtr = linePtr->nextPtr) {
		    for (segPtr = linePtr->segPtr; segPtr != NULL;
			 segPtr = segPtr->nextPtr) {
			if ((segPtr->typePtr == &tkTextToggleOnType ||
			     segPtr->typePtr == &tkTextToggleOffType) &&
			    segPtr->body.toggle.tagPtr == tagPtr) {
			    count++;
			} else if (segPtr->typePtr == &tkTextIBTreeType 
				   && segPtr->body.itree.tree) {
			    childNodePtr = 
				((BTree*)segPtr->body.itree.tree)->rootPtr;
			    for (summaryPtr2 = childNodePtr->summaryPtr;
				 summaryPtr2 != NULL;
				 summaryPtr2 = summaryPtr2->nextPtr) {
				if (summaryPtr2->tagPtr == tagPtr) {
				    count += summaryPtr2->toggleCount;
				}
			    }
			}
		    }
		}
	    }
	    if (count != tagPtr->toggleCount) {
		panic("TkBTreeCheck toggleCount (%d) wrong for \"%s\" should be (%d)",
		      tagPtr->toggleCount, tagPtr->name, count);
	    }
	}
    }

    /*
     * Call a recursive procedure to do the main body of checks.
     */

    nodePtr = treePtr->rootPtr;
    CheckNodeConsistency(treePtr->rootPtr);

    /*
     * Make sure that there are at least two lines in the text and
     * that the last line has no characters except a newline.
     */

    if (nodePtr->numLines < 2) {
	panic("TkBTreeCheck: less than 2 lines in tree");
    }
    while (nodePtr->level > 0) {
	nodePtr = nodePtr->children.nodePtr;
	while (nodePtr->nextPtr != NULL) {
	    nodePtr = nodePtr->nextPtr;
	}
    }
    linePtr = nodePtr->children.linePtr;
    while (linePtr->nextPtr != NULL) {
	linePtr = linePtr->nextPtr;
    }
    segPtr = linePtr->segPtr;
    while ((segPtr->typePtr == &tkTextToggleOffType)
	    || (segPtr->typePtr == &tkTextRightMarkType)
	    || (segPtr->typePtr == &tkTextLeftMarkType)) {
	/*
	 * It's OK to toggle a tag off in the last line, but
	 * not to start a new range.  It's also OK to have marks
	 * in the last line.
	 */

	segPtr = segPtr->nextPtr;
    }
    if (segPtr->typePtr != &tkTextCharType) {
	panic("TkBTreeCheck: last line has bogus segment type");
    }
    if (segPtr->nextPtr != NULL) {
	panic("TkBTreeCheck: last line has too many segments");
    }
    if (segPtr->size != 1) {
	panic("TkBTreeCheck: last line has wrong # characters: %d",
		segPtr->size);
    }
    if ((segPtr->body.chars[0] != '\n') || (segPtr->body.chars[1] != 0)) {
	panic("TkBTreeCheck: last line had bad value: %s",
		segPtr->body.chars);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * CheckNodeConsistency --
 *
 *	This procedure is called as part of consistency checking for
 *	B-trees:  it checks several aspects of a node and also runs
 *	checks recursively on the node's children.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If anything suspicious is found in the tree structure, the
 *	procedure panics.
 *
 *----------------------------------------------------------------------
 */

static void
CheckNodeConsistency(nodePtr)
    register Node *nodePtr;		/* Node whose subtree should be
					 * checked. */
{
    register Node *childNodePtr;
    register Summary *summaryPtr, *summaryPtr2;
    register TkTextLine *linePtr;
    register TkTextSegment *segPtr;
    int numChildren, numLines, toggleCount, minChildren;

    if (nodePtr->parentPtr != NULL) {
	minChildren = MIN_CHILDREN;
    } else if (nodePtr->level > 0) {
	minChildren = 2;
    } else  {
	minChildren = 1;
    }
    if (!(nodePtr->segPtr)
	&& ((nodePtr->numChildren < minChildren)
	    || (nodePtr->numChildren > MAX_CHILDREN))) {
	panic("CheckNodeConsistency: bad child count (%d)",
		nodePtr->numChildren);
    }

    numChildren = 0;
    numLines = 0;
    if (nodePtr->level == 0) {
	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
		linePtr = linePtr->nextPtr) {
	    if (linePtr->parentPtr != nodePtr) {
		panic("CheckNodeConsistency: line doesn't point to parent");
	    }
	    if (linePtr->segPtr == NULL) {
		panic("CheckNodeConsistency: line has no segments");
	    }
	    for (segPtr = linePtr->segPtr; segPtr != NULL;
		    segPtr = segPtr->nextPtr) {
		if (segPtr->typePtr->checkProc != NULL) {
		    (*segPtr->typePtr->checkProc)(segPtr, linePtr);
		}
		if ((segPtr->size == 0) && (!segPtr->typePtr->leftGravity)
			&& (segPtr->nextPtr != NULL)
			&& (segPtr->nextPtr->size == 0)
			&& (segPtr->nextPtr->typePtr->leftGravity)) {
		    panic("CheckNodeConsistency: wrong segment order for gravity");
		}
		if ((segPtr->nextPtr == NULL)
			&& (segPtr->typePtr != &tkTextCharType)) {
		    panic("CheckNodeConsistency: line ended with wrong type");
		}
	    }
	    numChildren++;
	    numLines++;
	}
    } else {
	for (childNodePtr = nodePtr->children.nodePtr; childNodePtr != NULL;
		childNodePtr = childNodePtr->nextPtr) {
	    if (childNodePtr->parentPtr != nodePtr) {
		panic("CheckNodeConsistency: node doesn't point to parent");
	    }
	    if (childNodePtr->level != (nodePtr->level-1)) {
		panic("CheckNodeConsistency: level mismatch (%d %d)",
			nodePtr->level, childNodePtr->level);
	    }
	    CheckNodeConsistency(childNodePtr);
	    for (summaryPtr = childNodePtr->summaryPtr; summaryPtr != NULL;
			summaryPtr = summaryPtr->nextPtr) {
		for (summaryPtr2 = nodePtr->summaryPtr; ;
			summaryPtr2 = summaryPtr2->nextPtr) {
		    if (summaryPtr2 == NULL) {
			if (summaryPtr->tagPtr->tagRootPtr == nodePtr) {
			    break;
			}
			panic("CheckNodeConsistency: node tag \"%s\" not %s",
				summaryPtr->tagPtr->name,
				"present in parent summaries");
		    }
		    if (summaryPtr->tagPtr == summaryPtr2->tagPtr) {
			break;
		    }
		}
	    }
	    numChildren++;
	    numLines += childNodePtr->numLines;
	}
    }
    if (numChildren != nodePtr->numChildren) {
	panic("CheckNodeConsistency: mismatch in numChildren (%d %d)",
		numChildren, nodePtr->numChildren);
    }
    if (numLines != nodePtr->numLines) {
	panic("CheckNodeConsistency: mismatch in numLines (%d %d)",
		numLines, nodePtr->numLines);
    }

    for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
	    summaryPtr = summaryPtr->nextPtr) {
	if (summaryPtr->tagPtr->toggleCount == summaryPtr->toggleCount
	    && ! nodePtr->segPtr) {
	    panic("CheckNodeConsistency: found unpruned root for \"%s\"",
		summaryPtr->tagPtr->name);
	}
	toggleCount = 0;
	if (nodePtr->level == 0) {
	    for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
		    linePtr = linePtr->nextPtr) {
		for (segPtr = linePtr->segPtr; segPtr != NULL;
			segPtr = segPtr->nextPtr) {
		    if ((segPtr->typePtr != &tkTextToggleOnType)
			    && (segPtr->typePtr !=
				&tkTextToggleOffType)) {
		        if (segPtr->typePtr == &tkTextIBTreeType 
			    && segPtr->body.itree.tree) {
			  childNodePtr = 
			    ((BTree*)segPtr->body.itree.tree)->rootPtr;
			  for (summaryPtr2 = childNodePtr->summaryPtr;
			       summaryPtr2 != NULL;
			       summaryPtr2 = summaryPtr2->nextPtr) {
			    if (summaryPtr2->tagPtr == summaryPtr->tagPtr) {
			      toggleCount += summaryPtr2->toggleCount;
			    }
			  }
			}
			continue;
		    }
		    if (segPtr->body.toggle.tagPtr == summaryPtr->tagPtr) {
			toggleCount ++;
		    }
		}
	    }
	} else {
	    for (childNodePtr = nodePtr->children.nodePtr;
		    childNodePtr != NULL;
		    childNodePtr = childNodePtr->nextPtr) {
		for (summaryPtr2 = childNodePtr->summaryPtr;
			summaryPtr2 != NULL;
			summaryPtr2 = summaryPtr2->nextPtr) {
		    if (summaryPtr2->tagPtr == summaryPtr->tagPtr) {
			toggleCount += summaryPtr2->toggleCount;
		    }
		}
	    }
	}
	if (toggleCount != summaryPtr->toggleCount) {
	    panic("CheckNodeConsistency: mismatch in toggleCount (%d %d)",
		    toggleCount, summaryPtr->toggleCount);
	}
	if (!summaryPtr->toggleCount) {
	    panic("CheckNodeConsistency: zero toggleCount");
	}
	for (summaryPtr2 = summaryPtr->nextPtr; summaryPtr2 != NULL;
		summaryPtr2 = summaryPtr2->nextPtr) {
	    if (summaryPtr2->tagPtr == summaryPtr->tagPtr) {
		panic("CheckNodeConsistency: duplicated node tag: %s",
			summaryPtr->tagPtr->name);
	    }
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Rebalance --
 *
 *	This procedure is called when a node of a B-tree appears to be
 *	out of balance (too many children, or too few).  It rebalances
 *	that node and all of its ancestors in the tree.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The internal structure of treePtr may change.
 *
 *----------------------------------------------------------------------
 */

static void
Rebalance(treePtr, nodePtr)
    BTree *treePtr;			/* Tree that is being rebalanced. */
    register Node *nodePtr;		/* Node that may be out of balance. */
{
    /* Die if called on a recursive tree */

    if (nodePtr->segPtr) {
      panic("Rebalance called on an internal tree in Text.");
    }

    /*
     * Loop over the entire ancestral chain of the node, working up
     * through the tree one node at a time until the root node has
     * been processed.
     */

    for ( ; nodePtr != NULL; nodePtr = nodePtr->parentPtr) {
	register Node *newPtr, *childPtr;
	register TkTextLine *linePtr;
	int i;

	/*
	 * Check to see if the node has too many children.  If it does,
	 * then split off all but the first MIN_CHILDREN into a separate
	 * node following the original one.  Then repeat until the
	 * node has a decent size.
	 */

	if (nodePtr->numChildren > MAX_CHILDREN) {
	    while (1) {
		/*
		 * If the node being split is the root node, then make a
		 * new root node above it first.
		 */
    
		if (nodePtr->parentPtr == NULL) {
		    newPtr = (Node *) ckalloc(sizeof(Node));
		    newPtr->parentPtr = NULL;
		    newPtr->nextPtr = NULL;
		    newPtr->summaryPtr = NULL;
		    newPtr->level = nodePtr->level + 1;
		    newPtr->children.nodePtr = nodePtr;
		    newPtr->numChildren = 1;
		    newPtr->numLines = nodePtr->numLines;
		    newPtr->segPtr = NULL;
		    TkTextDataInit(newPtr->value);
		    RecomputeNodeCounts(newPtr);
		    treePtr->rootPtr = newPtr;
		}
		newPtr = (Node *) ckalloc(sizeof(Node));
		newPtr->parentPtr = nodePtr->parentPtr;
		newPtr->nextPtr = nodePtr->nextPtr;
		nodePtr->nextPtr = newPtr;
		newPtr->summaryPtr = NULL;
		newPtr->level = nodePtr->level;
		newPtr->numChildren = nodePtr->numChildren - MIN_CHILDREN;
		newPtr->segPtr = NULL;
		TkTextDataInit(newPtr->value);
		if (nodePtr->level == 0) {
		    for (i = MIN_CHILDREN-1,
			    linePtr = nodePtr->children.linePtr;
			    i > 0; i--, linePtr = linePtr->nextPtr) {
			/* Empty loop body. */
		    }
		    newPtr->children.linePtr = linePtr->nextPtr;
		    linePtr->nextPtr = NULL;
		} else {
		    for (i = MIN_CHILDREN-1,
			    childPtr = nodePtr->children.nodePtr;
			    i > 0; i--, childPtr = childPtr->nextPtr) {
			/* Empty loop body. */
		    }
		    newPtr->children.nodePtr = childPtr->nextPtr;
		    childPtr->nextPtr = NULL;
		}
		RecomputeNodeCounts(nodePtr);
		nodePtr->parentPtr->numChildren++;
		nodePtr = newPtr;
		if (nodePtr->numChildren <= MAX_CHILDREN) {
		    RecomputeNodeCounts(nodePtr);
		    break;
		}
	    }
	}

	while (nodePtr->numChildren < MIN_CHILDREN) {
	    register Node *otherPtr;
	    Node *halfwayNodePtr = NULL;	/* Initialization needed only */
	    TkTextLine *halfwayLinePtr = NULL;	/* to prevent cc warnings. */
	    int totalChildren, firstChildren, i;

	    /*
	     * Too few children for this node.  If this is the root then,
	     * it's OK for it to have less than MIN_CHILDREN children
	     * as long as it's got at least two.  If it has only one
	     * (and isn't at level 0), then chop the root node out of
	     * the tree and use its child as the new root.
	     */

	    if (nodePtr->parentPtr == NULL) {
		if ((nodePtr->numChildren == 1) && (nodePtr->level > 0)) {
		    treePtr->rootPtr = nodePtr->children.nodePtr;
		    treePtr->rootPtr->parentPtr = NULL;
		    DeleteSummaries(nodePtr->summaryPtr);
		    ckfree((char *) nodePtr);
		}
		return;
	    }

	    /*
	     * Not the root.  Make sure that there are siblings to
	     * balance with.
	     */

	    if (nodePtr->parentPtr->numChildren < 2) {
		Rebalance(treePtr, nodePtr->parentPtr);
		continue;
	    }

	    /*
	     * Find a sibling neighbor to borrow from, and arrange for
	     * nodePtr to be the earlier of the pair.
	     */

	    if (nodePtr->nextPtr == NULL) {
		for (otherPtr = nodePtr->parentPtr->children.nodePtr;
			otherPtr->nextPtr != nodePtr;
			otherPtr = otherPtr->nextPtr) {
		    /* Empty loop body. */
		}
		nodePtr = otherPtr;
	    }
	    otherPtr = nodePtr->nextPtr;

	    /*
	     * We're going to either merge the two siblings together
	     * into one node or redivide the children among them to
	     * balance their loads.  As preparation, join their two
	     * child lists into a single list and remember the half-way
	     * point in the list.
	     */

	    totalChildren = nodePtr->numChildren + otherPtr->numChildren;
	    firstChildren = totalChildren/2;
	    if (nodePtr->children.nodePtr == NULL) {
		nodePtr->children = otherPtr->children;
		otherPtr->children.nodePtr = NULL;
		otherPtr->children.linePtr = NULL;
	    }
	    if (nodePtr->level == 0) {
		register TkTextLine *linePtr;

		for (linePtr = nodePtr->children.linePtr, i = 1;
			linePtr->nextPtr != NULL;
			linePtr = linePtr->nextPtr, i++) {
		    if (i == firstChildren) {
			halfwayLinePtr = linePtr;
		    }
		}
		linePtr->nextPtr = otherPtr->children.linePtr;
		while (i <= firstChildren) {
		    halfwayLinePtr = linePtr;
		    linePtr = linePtr->nextPtr;
		    i++;
		}
	    } else {
		register Node *childPtr;

		for (childPtr = nodePtr->children.nodePtr, i = 1;
			childPtr->nextPtr != NULL;
			childPtr = childPtr->nextPtr, i++) {
		    if (i <= firstChildren) {
			if (i == firstChildren) {
			    halfwayNodePtr = childPtr;
			}
		    }
		}
		childPtr->nextPtr = otherPtr->children.nodePtr;
		while (i <= firstChildren) {
		    halfwayNodePtr = childPtr;
		    childPtr = childPtr->nextPtr;
		    i++;
		}
	    }

	    /*
	     * If the two siblings can simply be merged together, do it.
	     */

	    if (totalChildren <= MAX_CHILDREN) {
		RecomputeNodeCounts(nodePtr);
		nodePtr->nextPtr = otherPtr->nextPtr;
		nodePtr->parentPtr->numChildren--;
		DeleteSummaries(otherPtr->summaryPtr);
		ckfree((char *) otherPtr);
		continue;
	    }

	    /*
	     * The siblings can't be merged, so just divide their
	     * children evenly between them.
	     */

	    if (nodePtr->level == 0) {
		otherPtr->children.linePtr = halfwayLinePtr->nextPtr;
		halfwayLinePtr->nextPtr = NULL;
	    } else {
		otherPtr->children.nodePtr = halfwayNodePtr->nextPtr;
		halfwayNodePtr->nextPtr = NULL;
	    }
	    RecomputeNodeCounts(nodePtr);
	    RecomputeNodeCounts(otherPtr);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * RecomputeNodeCounts --
 *
 *	This procedure is called to recompute all the counts in a node
 *	(tags, child information, etc.) by scanning the information in
 *	its descendants.  This procedure is called during rebalancing
 *	when a node's child structure has changed.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The tag counts for nodePtr are modified to reflect its current
 *	child structure, as are its numChildren and numLines fields.
 *	Also, all of the childrens' parentPtr fields are made to point
 *	to nodePtr.
 *
 *----------------------------------------------------------------------
 */

static void
RecomputeNodeCounts(nodePtr)
    register Node *nodePtr;		/* Node whose tag summary information
					 * must be recomputed. */
{
    register Summary *summaryPtr, *summaryPtr2;
    register Node *childPtr, *childNodePtr;
    register TkTextLine *linePtr;
    register TkTextSegment *segPtr;
    TkTextTag *tagPtr;

    /*
     * Zero out all the existing counts for the node, but don't delete
     * the existing Summary records (most of them will probably be reused).
     */

    for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL;
	    summaryPtr = summaryPtr->nextPtr) {
	summaryPtr->toggleCount = 0;
    }
    nodePtr->numChildren = 0;
    nodePtr->numLines = 0;

    /*
     * Scan through the children, adding the childrens' tag counts into
     * the node's tag counts and adding new Summary structures if
     * necessary.
     */

    if (nodePtr->level == 0) {
	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
		linePtr = linePtr->nextPtr) {
	    nodePtr->numChildren++;
	    nodePtr->numLines++;
	    linePtr->parentPtr = nodePtr;
	    for (segPtr = linePtr->segPtr; segPtr != NULL;
		    segPtr = segPtr->nextPtr) {
		if ((segPtr->typePtr == &tkTextIBTreeType
		     && segPtr->body.itree.tree)) {
		    /*
		     * A block whose line changed is not counted until its
		     * new line is cleaned up (iBTreeLineChangeProc took
		     * its toggles off the old nodes and the tags' totals,
		     * iBTreeCleanupProc adds them back): leave it out here
		     * too.  Counting it made the node's count exceed the
		     * tag's total, so that a rebalance in between (a
		     * deletion joining the block's line to the line before
		     * rebalances before it cleans up) did not move the
		     * tag's root to the node that kept the toggles, and
		     * freed the node the root was on.
		     */

		    if (!segPtr->body.itree.counted) {
			continue;
		    }
		    childNodePtr = 
		      ((BTree*)segPtr->body.itree.tree)->rootPtr;
		    for (summaryPtr2 = childNodePtr->summaryPtr;
			 summaryPtr2 != NULL;
			 summaryPtr2 = summaryPtr2->nextPtr) {
		        for (summaryPtr = nodePtr->summaryPtr; ;
			     summaryPtr = summaryPtr->nextPtr) {
			    if (summaryPtr == NULL) {
			        summaryPtr = (Summary *) ckalloc(sizeof(Summary));
				summaryPtr->tagPtr = summaryPtr2->tagPtr;
				summaryPtr->toggleCount = summaryPtr2->toggleCount;
				summaryPtr->nextPtr = nodePtr->summaryPtr;
				nodePtr->summaryPtr = summaryPtr;
				break;
			    }
			    if (summaryPtr->tagPtr == summaryPtr2->tagPtr) {
			        summaryPtr->toggleCount += summaryPtr2->toggleCount;
				break;
			    }
			}
		    }
		    continue;
		}
		if (((segPtr->typePtr != &tkTextToggleOnType)
			&& (segPtr->typePtr != &tkTextToggleOffType))
			|| !(segPtr->body.toggle.inNodeCounts)) {
		    continue;
		}
		tagPtr = segPtr->body.toggle.tagPtr;
		for (summaryPtr = nodePtr->summaryPtr; ;
			summaryPtr = summaryPtr->nextPtr) {
		    if (summaryPtr == NULL) {
			summaryPtr = (Summary *) ckalloc(sizeof(Summary));
			summaryPtr->tagPtr = tagPtr;
			summaryPtr->toggleCount = 1;
			summaryPtr->nextPtr = nodePtr->summaryPtr;
			nodePtr->summaryPtr = summaryPtr;
			break;
		    }
		    if (summaryPtr->tagPtr == tagPtr) {
			summaryPtr->toggleCount++;
			break;
		    }
		}
	    }
	}
    } else {
	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
		childPtr = childPtr->nextPtr) {
	    nodePtr->numChildren++;
	    nodePtr->numLines += childPtr->numLines;
	    childPtr->parentPtr = nodePtr;
	    for (summaryPtr2 = childPtr->summaryPtr; summaryPtr2 != NULL;
		    summaryPtr2 = summaryPtr2->nextPtr) {
		for (summaryPtr = nodePtr->summaryPtr; ;
			summaryPtr = summaryPtr->nextPtr) {
		    if (summaryPtr == NULL) {
			summaryPtr = (Summary *) ckalloc(sizeof(Summary));
			summaryPtr->tagPtr = summaryPtr2->tagPtr;
			summaryPtr->toggleCount = summaryPtr2->toggleCount;
			summaryPtr->nextPtr = nodePtr->summaryPtr;
			nodePtr->summaryPtr = summaryPtr;
			break;
		    }
		    if (summaryPtr->tagPtr == summaryPtr2->tagPtr) {
			summaryPtr->toggleCount += summaryPtr2->toggleCount;
			break;
		    }
		}
	    }
	}
    }

    /*
     * Scan through the node's tag records again and delete any Summary
     * records that still have a zero count, or that have all the toggles.
     * The node with the children that account for all the tags toggles
     * have no summary information, and they become the tagRootPtr for the tag.
     */

    summaryPtr2 = NULL;
    for (summaryPtr = nodePtr->summaryPtr; summaryPtr != NULL; ) {
	if (summaryPtr->toggleCount > 0 && 
		summaryPtr->toggleCount < summaryPtr->tagPtr->toggleCount) {
	    if (!nodePtr->segPtr
		&& nodePtr->level == summaryPtr->tagPtr->tagRootPtr->level) {
		/*
		 * The tag's root node split and some toggles left.
		 * The tag root must move up a level.
		 */
		summaryPtr->tagPtr->tagRootPtr = nodePtr->parentPtr;
	    }
	    summaryPtr2 = summaryPtr;
	    summaryPtr = summaryPtr->nextPtr;
	    continue;
	}
	if (!nodePtr->segPtr) {
	    if (summaryPtr->toggleCount == summaryPtr->tagPtr->toggleCount) {
		/*
		 * A node merge has collected all the toggles under one node.
		 * Push the root down to this level.
		 */
		summaryPtr->tagPtr->tagRootPtr = nodePtr;
	    }
	} else if (summaryPtr->toggleCount) {
	    summaryPtr2 = summaryPtr;
	    summaryPtr = summaryPtr->nextPtr;
	    continue;
	}
	
	if (summaryPtr2 != NULL) {
	    summaryPtr2->nextPtr = summaryPtr->nextPtr;
	    ckfree((char *) summaryPtr);
	    summaryPtr = summaryPtr2->nextPtr;
	} else {
	    nodePtr->summaryPtr = summaryPtr->nextPtr;
	    ckfree((char *) summaryPtr);
	    summaryPtr = nodePtr->summaryPtr;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeNumLines --
 *
 *	This procedure returns a count of the number of lines of
 *	text present in a given B-tree.
 *
 * Results:
 *	The return value is a count of the number of usable lines
 *	in tree (i.e. it doesn't include the dummy line that is just
 * 	used to mark the end of the tree).
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeNumLines(tree)
    TkTextBTree tree;			/* Information about tree. */
{
    BTree *treePtr = (BTree *) tree;
    return treePtr->rootPtr->numLines - 1;
}

/*
 *--------------------------------------------------------------
 *
 * CharSplitProc --
 *
 *	This procedure implements splitting for character segments.
 *
 * Results:
 *	The return value is a pointer to a chain of two segments
 *	that have the same characters as segPtr except split
 *	among the two segments.
 *
 * Side effects:
 *	Storage for segPtr is freed.
 *
 *--------------------------------------------------------------
 */

static TkTextSegment *
CharSplitProc(segPtr, index)
    TkTextSegment *segPtr;		/* Pointer to segment to split. */
    int index;				/* Position within segment at which
					 * to split. */
{
    TkTextSegment *newPtr1, *newPtr2;

    newPtr1 = (TkTextSegment *) ckalloc(CSEG_SIZE(index));
    newPtr2 = (TkTextSegment *) ckalloc(
	    CSEG_SIZE(segPtr->size - index));
    newPtr1->typePtr = &tkTextCharType;
    newPtr1->nextPtr = newPtr2;
    newPtr1->size = index;
    strncpy(newPtr1->body.chars, segPtr->body.chars, (size_t) index);
    newPtr1->body.chars[index] = 0;
    newPtr2->typePtr = &tkTextCharType;
    newPtr2->nextPtr = segPtr->nextPtr;
    newPtr2->size = segPtr->size - index;
    strcpy(newPtr2->body.chars, segPtr->body.chars + index);
    ckfree((char*) segPtr);
    return newPtr1;
}

/*
 *--------------------------------------------------------------
 *
 * CharCleanupProc --
 *
 *	This procedure merges adjacent character segments into
 *	a single character segment, if possible. Also deletes empty
 * 	char segments.
 *
 * Results:
 *	The return value is a pointer to the first segment in
 *	the (new) list of segments that used to start with segPtr.
 *
 * Side effects:
 *	Storage for the segments may be allocated and freed.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static TkTextSegment *
CharCleanupProc(segPtr, linePtr)
    TkTextSegment *segPtr;		/* Pointer to first of two adjacent
					 * segments to join. */
    TkTextLine *linePtr;		/* Line containing segments (not
					 * used). */
{
    TkTextSegment *segPtr2, *newPtr;

    segPtr2 = segPtr->nextPtr;
    if (segPtr->size == 0) {
	if (segPtr2) {
	    segPtr2 = (*segPtr2->typePtr->cleanupProc)(segPtr2, linePtr);
	}
	ckfree((char*) segPtr);
	return segPtr2;
    }
    if ((segPtr2 == NULL) || (segPtr2->typePtr != &tkTextCharType)) {
	return segPtr;
    }
    newPtr = (TkTextSegment *) ckalloc(CSEG_SIZE(
	    segPtr->size + segPtr2->size));
    newPtr->typePtr = &tkTextCharType;
    newPtr->nextPtr = segPtr2->nextPtr;
    newPtr->size = segPtr->size + segPtr2->size;
    strcpy(newPtr->body.chars, segPtr->body.chars);
    strcpy(newPtr->body.chars + segPtr->size, segPtr2->body.chars);
    ckfree((char*) segPtr);
    ckfree((char*) segPtr2);
    return newPtr;
}

/*
 *--------------------------------------------------------------
 *
 * CharDeleteProc --
 *
 *	This procedure is invoked to delete a character segment.
 *
 * Results:
 *	Always returns 0 to indicate that the segment was deleted.
 *
 * Side effects:
 *	Storage for the segment is freed.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static int
CharDeleteProc(segPtr, linePtr, treeGone)
    TkTextSegment *segPtr;		/* Segment to delete. */
    TkTextLine *linePtr;		/* Line containing segment. */
    int treeGone;			/* Non-zero means the entire tree is
					 * being deleted, so everything must
					 * get cleaned up. */
{
    ckfree((char*) segPtr);
    return 0;
}

/*
 *--------------------------------------------------------------
 *
 * CharCheckProc --
 *
 *	This procedure is invoked to perform consistency checks
 *	on character segments.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If the segment isn't inconsistent then the procedure
 *	panics.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static void
CharCheckProc(segPtr, linePtr)
    TkTextSegment *segPtr;		/* Segment to check. */
    TkTextLine *linePtr;		/* Line containing segment. */
{
    /*
     * Make sure that the segment contains the number of
     * characters indicated by its header, and that the last
     * segment in a line ends in a newline.  Also make sure
     * that there aren't ever two character segments adjacent
     * to each other:  they should be merged together.
     */

    if (segPtr->size <= 0) {
	panic("CharCheckProc: segment has size <= 0");
    }
    if (strlen(segPtr->body.chars) != segPtr->size) {
	panic("CharCheckProc: segment has wrong size");
    }
    if (segPtr->nextPtr == NULL) {
	if (segPtr->body.chars[segPtr->size-1] != '\n') {
	    panic("CharCheckProc: line doesn't end with newline, segment: \"%s\"", segPtr->body.chars);
	}
    } else {
	if (segPtr->nextPtr->typePtr == &tkTextCharType) {
	    panic("CharCheckProc: adjacent character segments weren't merged, segments: \"%s\", \"%s\"", segPtr->body.chars, segPtr->nextPtr->body.chars);
	}
    }
}

/*
 *--------------------------------------------------------------
 *
 * ToggleDeleteProc --
 *
 *	This procedure is invoked to delete toggle segments.
 *
 * Results:
 *	Returns 1 to indicate that the segment may not be deleted,
 *	unless the entire B-tree is going away.
 *
 * Side effects:
 *	If the tree is going away then the toggle's memory is
 *	freed;  otherwise the toggle counts in nodes above the
 *	segment get updated.
 *
 *--------------------------------------------------------------
 */

static int
ToggleDeleteProc(segPtr, linePtr, treeGone)
    TkTextSegment *segPtr;		/* Segment to check. */
    TkTextLine *linePtr;		/* Line containing segment. */
    int treeGone;			/* Non-zero means the entire tree is
					 * being deleted, so everything must
					 * get cleaned up. */
{
    if (treeGone) {
	DropToggleValue(segPtr);	/* The widget is destroyed. */
	ckfree((char *) segPtr);
	return 0;
    }

    /*
     * This toggle is in the middle of a range of characters that's
     * being deleted.  Refuse to die.  We'll be moved to the end of
     * the deleted range and our cleanup procedure will be called
     * later.  Decrement node toggle counts here, and set a flag
     * so we'll re-increment them in the cleanup procedure.
     */

    if (segPtr->body.toggle.inNodeCounts) {
	ChangeNodeToggleCount(linePtr->parentPtr,
		segPtr->body.toggle.tagPtr, -1);
	segPtr->body.toggle.inNodeCounts = 0;
    }
    return 1;
}

/*
 *--------------------------------------------------------------
 *
 * ToggleCleanupProc --
 *
 *	This procedure is called when a toggle is part of a line that's
 *	been modified in some way.  It's invoked after the
 *	modifications are complete.
 *
 * Results:
 *	The return value is the head segment in a new list
 *	that is to replace the tail of the line that used to
 *	start at segPtr.  This allows the procedure to delete
 *	or modify segPtr.
 *
 * Side effects:
 *	Toggle counts in the nodes above the new line will be
 *	updated if they're not already.  Toggles may be collapsed
 *	if there are duplicate toggles at the same position.
 *
 *--------------------------------------------------------------
 */

static TkTextSegment *
ToggleCleanupProc(segPtr, linePtr)
    TkTextSegment *segPtr;	/* Segment to check. */
    TkTextLine *linePtr;	/* Line that now contains segment. */
{
    TkTextSegment *segPtr2, *prevPtr;
    int counts;

    /*
     * If this is a toggle-off segment, look ahead through the next
     * segments to see if there's a toggle-on segment for the same tag
     * before any segments with non-zero size.  If so then the two
     * toggles cancel each other;  remove them both.
     */

    if (segPtr->typePtr == &tkTextToggleOffType) {
	for (prevPtr = segPtr, segPtr2 = prevPtr->nextPtr;
		(segPtr2 != NULL) && (segPtr2->size == 0);
		prevPtr = segPtr2, segPtr2 = prevPtr->nextPtr) {
	    if (segPtr2->typePtr != &tkTextToggleOnType) {
		continue;
	    }
	    if (segPtr2->body.toggle.tagPtr != segPtr->body.toggle.tagPtr) {
		continue;
	    }
	    counts = segPtr->body.toggle.inNodeCounts
		    + segPtr2->body.toggle.inNodeCounts;
	    if (counts != 0) {
		ChangeNodeToggleCount(linePtr->parentPtr,
			segPtr->body.toggle.tagPtr, -counts);
	    }
	    prevPtr->nextPtr = segPtr2->nextPtr;
	    DropToggleValue(segPtr2);
	    ckfree((char *) segPtr2);
	    segPtr2 = segPtr->nextPtr;
	    ckfree((char *) segPtr);
	    return segPtr2;
	}
    }

    if (!segPtr->body.toggle.inNodeCounts) {
	ChangeNodeToggleCount(linePtr->parentPtr,
		segPtr->body.toggle.tagPtr, 1);
	segPtr->body.toggle.inNodeCounts = 1;
    }
    return segPtr;
}

/*
 *--------------------------------------------------------------
 *
 * ToggleLineChangeProc --
 *
 *	This procedure is invoked when a toggle segment is about
 *	to move from one line to another.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Toggle counts are decremented in the nodes above the line.
 *
 *--------------------------------------------------------------
 */

static void
ToggleLineChangeProc(segPtr, linePtr)
    TkTextSegment *segPtr;	/* Segment to check. */
    TkTextLine *linePtr;	/* Line that used to contain segment. */
{
    if (segPtr->body.toggle.inNodeCounts) {
	ChangeNodeToggleCount(linePtr->parentPtr,
		segPtr->body.toggle.tagPtr, -1);
	segPtr->body.toggle.inNodeCounts = 0;
    }
}

/*
 *--------------------------------------------------------------
 *
 * ToggleCheckProc --
 *
 *	This procedure is invoked to perform consistency checks
 *	on toggle segments.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If a consistency problem is found the procedure panics.
 *
 *--------------------------------------------------------------
 */

static void
ToggleCheckProc(segPtr, linePtr)
    TkTextSegment *segPtr;		/* Segment to check. */
    TkTextLine *linePtr;		/* Line containing segment. */
{
    register Summary *summaryPtr;
    int needSummary;

    if (segPtr->size != 0) {
	panic("ToggleCheckProc: segment had non-zero size");
    }
    if (!segPtr->body.toggle.inNodeCounts) {
	panic("ToggleCheckProc: toggle counts not updated in nodes");
    }
    needSummary = (segPtr->body.toggle.tagPtr->tagRootPtr != linePtr->parentPtr);
    for (summaryPtr = linePtr->parentPtr->summaryPtr; ;
	    summaryPtr = summaryPtr->nextPtr) {
	if (summaryPtr == NULL) {
	    if (needSummary) {
		panic("ToggleCheckProc: tag not present in node");
	    } else {
		break;
	    }
	}
	if (summaryPtr->tagPtr == segPtr->body.toggle.tagPtr) {
	    if (!needSummary) {
		panic("ToggleCheckProc: tag present in root node summary");
	    }
	    break;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeCharsInLine --
 *
 *	This procedure returns a count of the number of characters
 *	in a given line.
 *
 * Results:
 *	The return value is the character count for linePtr.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeCharsInLine(linePtr)
    TkTextLine *linePtr;		/* Line whose characters should be
					 * counted. */
{
    /* Note: counts bytes of index space, not characters. */
    TkTextSegment *segPtr;
    int count;

    count = 0;
    for (segPtr = linePtr->segPtr; segPtr != NULL; segPtr = segPtr->nextPtr) {
	count += segPtr->size;
    }
    return count;
}

/*
 *--------------------------------------------------------------
 *
 * iBTreeCleanupProc --
 *
 *	Does nothing so far
 *
 * Results:
 *	The return value is a pointer to the first segment in
 *	the (new) list of segments that used to start with segPtr.
 *
 * Side effects:
 * 	Updates count of tags in the ambient nodes if segment is
 *	marked as not counted.
 *
 *--------------------------------------------------------------
 */
	/* ARGSUSED */
static TkTextSegment *
iBTreeCleanupProc(segPtr, linePtr)
    TkTextSegment *segPtr;		/* Pointer to segment to cleanup. */
    TkTextLine *linePtr;		/* Line containing segments. */
{
    if (!segPtr->body.itree.counted) {
      /*
       * The block moved to this line (iBTreeLineChangeProc): an -empty
       * block too, which has no tree and no toggles to count, but whose
       * line has to be known (TkIBTreeStartIndex, "block at").
       */

      segPtr->body.itree.linePtr = linePtr;
    }
    if (!segPtr->body.itree.counted && segPtr->body.itree.tree) {
      Summary *summaryPtr 
	= ((BTree *)segPtr->body.itree.tree)->rootPtr->summaryPtr;

      while (summaryPtr) {
	ChangeNodeToggleCount(linePtr->parentPtr, 
			      summaryPtr->tagPtr, summaryPtr->toggleCount);
	summaryPtr = summaryPtr->nextPtr;
      }
    }
    segPtr->body.itree.counted = 1;
    return segPtr;
}

/*
 *--------------------------------------------------------------
 *
 * iBTreeDeleteProc --
 *
 *	This procedure is invoked to delete an IBTree segment.
 *
 * Results:
 *	Always returns 0 to indicate that the segment was deleted.
 *
 * Side effects:
 *	Storage for the segment is freed. Tagcounts in ambient nodes
 * 	are updated, unless the complete tree is deleted. The sizes of
 * 	ambient IBTrees are *not* updated. 
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static int
iBTreeDeleteProc(segPtr, linePtr, treeGone)
    TkTextSegment *segPtr;		/* Segment to delete. */
    TkTextLine *linePtr;		/* Line containing segment. */
    int treeGone;			/* Non-zero means the entire tree is
					 * being deleted, so everything must
					 * get cleaned up. */
{
    TkTextIndex index1, index2;
    TkTextLine *intLinePtr, line;
    TkTextSegment *intSegPtr, *prevPtr = NULL, *nextPtr;
    int result = 2;			/* Always return 2 on success
					 * to show that the length is
					 * updated. */
    int dummy = 2;

    /*
     * The block goes, with its nodes and leaves: their values are
     * dropped, before the leaves' contents move anywhere.
     */

    if (segPtr->body.itree.tree) {
      BTree *treePtr = (BTree *) segPtr->body.itree.tree;

      DropTreeValues(treePtr->textPtr, treePtr->rootPtr);
    }
    if (treeGone) {
      segPtr->body.itree.blockPtr->count--;
      if (segPtr->body.itree.tree) {
	TkBTreeDestroy(segPtr->body.itree.tree);
      }
      DropBlockData(segPtr);
      ckfree((char*)segPtr);
      return 0;
    }

    if (segPtr->body.itree.tree) {
      /* Cannot just delete the tree, since we need to keep the marks
       * and tags intact. Cannot just use DeleteChars procedure, since the
       * segment is discontinued from the start of line. So we make a
       * dummy line first. */
    
      line.segPtr = segPtr;
      line.nextPtr = NULL;
      TkTextDataInit(line.value);
      line.parentPtr = linePtr->parentPtr; /* For LineChange to work. */
      segPtr->nextPtr = NULL;
      index1.linePtr = &line;
      index1.tree = NULL;		/* Do not know correct value,
					 * but it is not used in
					 * recursive DeleteChars. */
      index1.byteIndex = 1;
      index2 = index1;
      index2.byteIndex = segPtr->size - 1;
      /* Ask the subroutine not to look into internal trees. */
      TkBTreeDeleteChars(&index1, &index2, 0, 0);
      /* Now move the survivors to the position after segPtr, where
       * caller can find them. */
      intLinePtr =  TkBTreeFindLine(segPtr->body.itree.tree, 0);
      nextPtr = intSegPtr = intLinePtr->segPtr;
      if (nextPtr->nextPtr) {
	/* There are survivors. */
	while (nextPtr->nextPtr) {
	  prevPtr = nextPtr;
	  if (nextPtr->typePtr->lineChangeProc != NULL) {
	    (*nextPtr->typePtr->lineChangeProc)(nextPtr, &line);
	  }
	  nextPtr = nextPtr->nextPtr;
	}
	if (nextPtr->size != 1) {
	  panic("Wrong structure of line in iBTreeDeleteProc.");
	}
	intLinePtr->segPtr = nextPtr;
	prevPtr->nextPtr = NULL;
	segPtr->nextPtr = intSegPtr;
      } else {
	segPtr->nextPtr = NULL;
      }
      TkBTreeDestroy(segPtr->body.itree.tree);
    } else {
      /*
       * An empty block is deleted like any segment (result 0): the
       * caller takes its size (1) off the enclosing blocks' lengths.
       * Doing it here as well counted it twice, and the enclosing
       * block lost a character of its length (its last character
       * disappeared from "get", and deleting it later panicked).
       */
      dummy = 0;
      result = 0;
    }

    segPtr->body.itree.blockPtr->count--;
    DropBlockData(segPtr);
    if (dummy && linePtr->parentPtr->segPtr) {
      IBtreeUpdateLength(linePtr->parentPtr->segPtr, -dummy);
    }
    if (result == 0) {
      /*
       * An empty block: the caller (TkBTreeDeleteChars) only unlinks
       * a segment deleted with result 0, as for the other segment
       * types, whose delete procedures free it themselves.
       */
      ckfree((char *) segPtr);
    }
    return result;
}

/*
 *--------------------------------------------------------------
 *
 * iBTreeCheckProc --
 *
 *	This procedure is invoked to perform consistency checks
 *	on IBTree segments.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	If the segment isn't inconsistent then the procedure
 *	panics.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static void
iBTreeCheckProc(segPtr, linePtr)
    TkTextSegment *segPtr;		/* Segment to check. */
    TkTextLine *linePtr;		/* Line containing segment. */
{
  int size = 0;
  Node *nodePtr;

  if (segPtr->nextPtr == NULL) {
    panic("IBTree segment is last in line.");
  }

  if (segPtr->body.itree.counted == 0) {
    panic("IBTree segment is not counted.");
  }
  if (segPtr->body.itree.linePtr != linePtr) {
    panic("IBTree segment does not know its line.");
  }

  if (segPtr->body.itree.tree) {
    nodePtr = ((BTree *)segPtr->body.itree.tree)->rootPtr;
    TkBTreeCheck(segPtr->body.itree.tree);
    while (nodePtr->level) {
      nodePtr = nodePtr->children.nodePtr;
    }
    linePtr = nodePtr->children.linePtr;

    do {
      size += TkBTreeCharsInLine(linePtr);
    } while ( (linePtr = TkBTreeNextLine(linePtr)) );
  } else {
    size = 1;
  }

  if (segPtr->size != size) {
    panic("Size %i of segment of type IBTree inconsistent\n\twith its contents length %i.", segPtr->size, size);
  }
}

/*
 *--------------------------------------------------------------
 *
 * iBTreeLineChangeProc --
 *
 *	This procedure is invoked when an iBTree segment is about
 *	to move from one line to another.
 *
 * Results:
 *	None.
 *
 * Side effects:
 * 	Should update the count of tags in the old containing nodes. ????
 *
 *--------------------------------------------------------------
 */

static void
iBTreeLineChangeProc(segPtr, linePtr)
    TkTextSegment *segPtr;	/* Segment to check. */
    TkTextLine *linePtr;	/* Line that used to contain segment. */
{
  Summary *summaryPtr;

  if (segPtr->body.itree.tree) {
    summaryPtr = ((BTree *)segPtr->body.itree.tree)->rootPtr->summaryPtr;
    while (summaryPtr) {
      ChangeNodeToggleCount(linePtr->parentPtr, 
			    summaryPtr->tagPtr,
			    -summaryPtr->toggleCount);
      summaryPtr = summaryPtr->nextPtr;
    }
  }
  segPtr->body.itree.counted = 0;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeMakeBlock --
 *
 *	Move a range of characters from a B-tree into a new BTree,
 * 	maka a chunk of type IBTree that contains this chunk.  The caller
 *	must make sure that the final newline of the B-tree is
 *	never included in the range, and that both start and the end
 * 	are in the same BTree.
 *
 * 	The newly created BTree is of depth 1. Should not be called
 *	with different indices for empty blocks
 *
 * Results:
 *	Usual TCL return codes.
 *
 * Side effects:
 *	Internal structure of the B-tree changes.  Note: because
 *	of changes to the B-tree structure, the indices pointed
 *	to by index1Ptr and index2Ptr should not be used after this
 *	procedure returns.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeMakeBlock(textPtr, index1Ptr, index2Ptr, blockPtr)
    TkText *textPtr;			/* Where to insert; */
    register TkTextIndex *index1Ptr;	/* Indicates first character that is
					 * to be deleted. */
    register TkTextIndex *index2Ptr;	/* Indicates character just after the
					 * last one that is to be deleted. */
    register TkTextBlock *blockPtr;	/* Indicates what kind of
					 * block to create */
{
    TkTextSegment *prevPtr;		/* The segment just before the start
					 * of the deletion range. */
    TkTextSegment *lastPtr;		/* The segment just after the end
					 * of the deletion range. */
    TkTextSegment *segPtr, *nextPtr, *newSegPtr;
    TkTextLine *curLinePtr;
    Node *curNodePtr, *nodePtr;
    Node *lastNodePtr = NULL;		/* The node of the last line, if
					 * not the first's, or its first
					 * ancestor left: to rebalance
					 * too. */
    SegLine pSegment1, pSegment2;	/* The segment and line of the
					 * previous segments for index?Ptr. */
    int count = 0;			/* Total size of internal tree. */
    int lines = 0;			/* 1 rr 0 depending on
					 * addition of new lines. */
    int dummy = 2;			/* Number of dummy chars
					 * inserted, 1 for empty block. */

    if (index1Ptr->tree != index2Ptr->tree) {
      panic("TkTextMakeBlock called with indices in different trees!");
    }

    /*
     * Tricky point:  split at index2Ptr first;  otherwise the split
     * at index2Ptr may invalidate segPtr and/or prevPtr. However,
     * pSegment2.segPtr can be wrong after next split if the index1 is
     * inside this segment.
     */

    if ((index1Ptr->linePtr == index2Ptr->linePtr)
	    && (index1Ptr->byteIndex == index2Ptr->byteIndex)) {
	/*
	 * An empty range (a block with nothing in it): one split will
	 * do.  Two would not, at the start of a line: each SplitSeg
	 * there puts a new empty segment in front of the line, so the
	 * second one would leave the first one between the two
	 * "previous" segments, as if it were the range, and that would
	 * be moved into the block's tree (which an -empty block does
	 * not have: a NULL dereference).
	 */

	pSegment1 = pSegment2 = SplitSeg(index1Ptr);
	lastPtr = pSegment1.segPtr->nextPtr;
    } else {
	pSegment2 = SplitSeg(index2Ptr);
	lastPtr = pSegment2.segPtr->nextPtr;
	pSegment1 = SplitSeg(index1Ptr);
    }

    if (pSegment1.linePtr->parentPtr->segPtr 
	!= pSegment2.linePtr->parentPtr->segPtr) {
      CleanupLine(pSegment1.linePtr);
      CleanupLine(pSegment2.linePtr);
	Tcl_AppendResult(textPtr->interp, 
			 "TkTextMakeBlock called with ends in different blocks.",
		         NULL);
	return TCL_ERROR;
    }

    
    prevPtr = pSegment1.segPtr;
    segPtr = prevPtr->nextPtr;

    /* Check whether the split at index1 invalidated
     * pSegment2.segPtr. */

    if (pSegment2.linePtr == pSegment1.linePtr 
	&& segPtr->nextPtr == lastPtr && segPtr != pSegment2.segPtr) {
      /* Need to recompute pSegment2.segPtr. */
      pSegment2.segPtr = segPtr;
    }

    curLinePtr = pSegment1.linePtr;
    curNodePtr = curLinePtr->parentPtr;

    /* Send LineChange signal to the segments in the first line up to
     * the end-of-line or up to the end of range. */

    for (nextPtr = segPtr; nextPtr != NULL && nextPtr != lastPtr;
	 nextPtr = nextPtr->nextPtr) {
      if (nextPtr->typePtr->lineChangeProc != NULL) {
	(*nextPtr->typePtr->lineChangeProc)(nextPtr, curLinePtr);
      }
    }

    /* Create new segment of type IBTree. */

    newSegPtr = (TkTextSegment *) ckalloc(BSEG_SIZE);
    if (!blockPtr->empty) {
      newSegPtr->body.itree.tree = TkBTreeCreate(textPtr);
      ((BTree *)newSegPtr->body.itree.tree)->rootPtr->segPtr = newSegPtr;
    } else {
      newSegPtr->body.itree.tree = NULL;      
    }
    newSegPtr->body.itree.blockPtr = blockPtr;
    newSegPtr->body.itree.linePtr = curLinePtr;
    newSegPtr->body.itree.counted = 1;
    newSegPtr->body.itree.next2delete = NULL;
    TkTextDataInit(newSegPtr->body.itree.data);
    newSegPtr->typePtr = &tkTextIBTreeType;
    blockPtr->count++;

    /* Unlink the segments region on the first line */

    if (prevPtr != NULL) {
	prevPtr->nextPtr = newSegPtr;
    } else {
	pSegment1.linePtr->segPtr = newSegPtr;
    }
    newSegPtr->nextPtr = lastPtr;	/* Now the new segment is
					 * linked on both sides. */

    if (pSegment1.segPtr != pSegment2.segPtr) {
      /* Joint the unlinked segments inside the IBTree, first tail, */
      if (pSegment2.segPtr) {
	pSegment2.segPtr->nextPtr =
	  ((BTree *)newSegPtr->body.itree.tree)
	    ->rootPtr->children.linePtr->segPtr; 
      } else {
	pSegment2.linePtr->segPtr =
	  ((BTree *)newSegPtr->body.itree.tree)
	    ->rootPtr->children.linePtr->segPtr;      
      } 
      /* Then head. */
      ((BTree *)newSegPtr->body.itree.tree)->rootPtr->children.linePtr->segPtr
	= segPtr;

      /* If beginning and end are on different lines, we should move the
       *      * lines *after* the starting line up to the last line to the
       *      * internal tree. Should not send the LineChange signal to the
       *      * segments only *after* deletion range, since others remain in
       *      * the same line, but this line changes nodes. */

      if ((curLinePtr != pSegment2.linePtr) && curNodePtr->segPtr) {
	/*
	 * Inside a block (whose tree is never rebalanced) the lines may
	 * belong to different nodes: move them one by one from their
	 * nodes to the new tree; a node left without children
	 * disappears, with its value (the nodes of the starting line
	 * keep it).  The part of the last line before index2 moves with
	 * the line, the rest joins the starting line: the moved part
	 * starts without a value, the joined leaf keeps the first value
	 * present (as for a deletion); but if nothing of the last line
	 * is after index2 except its newline, the whole leaf moves, with
	 * its value (as for the starting line, below).
	 */

	Node *newRootPtr = ((BTree *)newSegPtr->body.itree.tree)->rootPtr;
	TkTextLine *prevLinePtr = newRootPtr->children.linePtr;
	TkTextLine *endLinePtr = prevLinePtr->nextPtr;
	TkTextLine *nextLinePtr;
	int addLines = 0, last, lastWhole, rest = 0;

	lines = 1;
	for (nextPtr = lastPtr; nextPtr != NULL; nextPtr = nextPtr->nextPtr) {
	  rest += nextPtr->size;
	}
	lastWhole = (rest <= 1);
	for (nextPtr = lastPtr; nextPtr != NULL;
	     nextPtr = nextPtr->nextPtr) {
	  if (nextPtr->typePtr->lineChangeProc != NULL) {
	    (*nextPtr->typePtr->lineChangeProc)(nextPtr, pSegment2.linePtr);
	  }
	}

	/*
	 * If nothing of the starting line is before index1, the whole
	 * leaf moves: its value goes with it, to the first leaf of the
	 * new block.
	 */

	for (nextPtr = pSegment1.linePtr->segPtr;
	     (nextPtr != newSegPtr) && (nextPtr->size == 0);
	     nextPtr = nextPtr->nextPtr) {
	  /* Empty. */
	}
	if (nextPtr == newSegPtr) {
	  TkTextDataMove(&prevLinePtr->value, &pSegment1.linePtr->value);
	}
	curLinePtr = TkBTreeNextLine(pSegment1.linePtr);
	while (1) {
	  last = (curLinePtr == pSegment2.linePtr);
	  nextLinePtr = last ? NULL : TkBTreeNextLine(curLinePtr);
	  for (segPtr = curLinePtr->segPtr; segPtr != NULL && segPtr != lastPtr;
	       segPtr = segPtr->nextPtr) {
	    if (segPtr->typePtr->lineChangeProc != NULL) {
	      (*segPtr->typePtr->lineChangeProc)(segPtr, curLinePtr);
	    }
	  }
	  UnlinkLine(textPtr, curLinePtr, pSegment1.linePtr);
	  if (last && !lastWhole) {
	    MergeValues(textPtr, (void *) pSegment1.linePtr,
		    &pSegment1.linePtr->value, (void *) curLinePtr,
		    &curLinePtr->value);
	  }
	  prevLinePtr->nextPtr = curLinePtr;
	  curLinePtr->parentPtr = newRootPtr;
	  prevLinePtr = curLinePtr;
	  addLines++;
	  CleanupLine(curLinePtr);
	  if (last) {
	    break;
	  }
	  curLinePtr = nextLinePtr;
	}
	prevLinePtr->nextPtr = endLinePtr;
	newRootPtr->numLines += addLines;
	newRootPtr->numChildren += addLines;

	/*
	 * If the last line moved was the last leaf, the node of the
	 * dummy line may have no leaves left: the dummy line joins the
	 * node of the starting line, and that node disappears.
	 */

	nextLinePtr = TkBTreeNextLine(pSegment1.linePtr);
	if ((nextLinePtr != NULL) && IsLastLine(nextLinePtr)
		&& (nextLinePtr->parentPtr != pSegment1.linePtr->parentPtr)
		&& (nextLinePtr->parentPtr->numChildren == 1)
		&& (pSegment1.linePtr->nextPtr == NULL)) {
	  UnlinkLine(textPtr, nextLinePtr, NULL);
	  pSegment1.linePtr->nextPtr = nextLinePtr;
	  nextLinePtr->parentPtr = pSegment1.linePtr->parentPtr;
	  nextLinePtr->parentPtr->numChildren++;
	  for (nodePtr = nextLinePtr->parentPtr; nodePtr != NULL;
	       nodePtr = nodePtr->parentPtr) {
	    nodePtr->numLines++;
	  }
	}
      } else if (curLinePtr != pSegment2.linePtr) {
	TkTextLine *nextLinePtr = TkBTreeNextLine(curLinePtr);
	TkTextLine *prevLinePtr 
	  = ((BTree *)newSegPtr->body.itree.tree)->rootPtr->children.linePtr;
	TkTextLine *endLinePtr = prevLinePtr->nextPtr;
	Node *oldNodePtr = curNodePtr;
	int deletedInNode = 0, addLines = 1; /* One line is added even
					      * if no internal lines are met. */

	lines = 1;
	/* Send LineChange signal to the segments in the last line up to
	 * the end-of-line. */

	for (nextPtr = lastPtr; nextPtr != NULL;
	     nextPtr = nextPtr->nextPtr) {
	  if (nextPtr->typePtr->lineChangeProc != NULL) {
	    (*nextPtr->typePtr->lineChangeProc)(nextPtr, pSegment2.linePtr);
	  }
	}

	prevLinePtr->nextPtr = nextLinePtr;

	/* Should be careful, cannot rewrite curLinePtr->nextPtr until
	 *        * we cached the next line */

	curLinePtr = nextLinePtr;

	/*
	 * The lines moved are counted off their own nodes: the first one
	 * may already be in the node after the starting line's.  A node
	 * other than the starting line's that all its lines leave goes.
	 * The moved lines are chained in the new tree across the nodes
	 * they came from (the last line of a node had no next).
	 */

	if (curLinePtr != NULL) {
	  curNodePtr = curLinePtr->parentPtr;
	}
	while (curLinePtr) {
	  /* Even if it is the last line of range, we should send
	   * 	 * LineChange signal to the segments before the *lastPtr.  */
	
	  for (segPtr = curLinePtr->segPtr; segPtr != NULL && segPtr != lastPtr;
	       segPtr = segPtr->nextPtr) {
	    if (segPtr->typePtr->lineChangeProc != NULL) {
	      (*segPtr->typePtr->lineChangeProc)(segPtr, curLinePtr);
	    }
	  }

	  if (curLinePtr == pSegment2.linePtr) {
	    deletedInNode++;
	    /* Update count of lines in old node and parents. */
	    for (nodePtr = curNodePtr; nodePtr != NULL;
		 nodePtr = nodePtr->parentPtr) {
	      nodePtr->numLines -= deletedInNode;
	    }
	    curNodePtr->numChildren -= deletedInNode;
	    curLinePtr->parentPtr 
	      = ((BTree *)newSegPtr->body.itree.tree)->rootPtr;
	    CleanupLine(curLinePtr);
	    break;
	  }

	  addLines++;
	  deletedInNode++;
	  nextLinePtr = TkBTreeNextLine(curLinePtr);
	  if (curLinePtr->nextPtr != nextLinePtr) {
	    /* Are in different nodes */
	    /* Update count of lines in old node and parents. */
	    for (nodePtr = curNodePtr; nodePtr != NULL;
		 nodePtr = nodePtr->parentPtr) {
	      nodePtr->numLines -= deletedInNode;
	    }
	    curNodePtr->numChildren -= deletedInNode;
	    deletedInNode = 0;
	    curLinePtr->nextPtr = nextLinePtr;

	    if (curNodePtr != oldNodePtr) {
	      if (curNodePtr->numChildren) {
		panic("Not-empty internal node in TkBTreeMakeBlock.");
	      }
	      while (curNodePtr->numChildren == 0) {
		Node *parentPtr;

		parentPtr = curNodePtr->parentPtr;
		if (parentPtr->children.nodePtr == curNodePtr) {
		  parentPtr->children.nodePtr = curNodePtr->nextPtr;
		} else {
		  Node *prevNodePtr = parentPtr->children.nodePtr;
		  while (prevNodePtr->nextPtr != curNodePtr) {
		    prevNodePtr = prevNodePtr->nextPtr;
		  }
		  prevNodePtr->nextPtr = curNodePtr->nextPtr;
		}
		parentPtr->numChildren--;
		DeleteSummaries(curNodePtr->summaryPtr);
		ckfree((char *) curNodePtr);
		curNodePtr = parentPtr;
	      }
	    }
	    curNodePtr = nextLinePtr->parentPtr;
	  }
	  curLinePtr->parentPtr = ((BTree *)newSegPtr->body.itree.tree)->rootPtr;
	  CleanupLine(curLinePtr);
	  curLinePtr = nextLinePtr;
	}
	if (!curLinePtr) {
	  panic("Ran out of lines in TkBTreeMakeBlock.");
	}
	/*
	 * Now correct structure in the ambient tree.  If the last line
	 * was in another node than the first, the lines after it stay
	 * in their node (they were linked after the first line, in its
	 * node, with a child count that did not match), and that node
	 * goes if it has no lines left; the first line is the last of
	 * its node then (all after it moved).
	 */

	if (curNodePtr == oldNodePtr) {
	  pSegment1.linePtr->nextPtr = pSegment2.linePtr->nextPtr;
	} else {
	  pSegment1.linePtr->nextPtr = NULL;
	  curNodePtr->children.linePtr = pSegment2.linePtr->nextPtr;
	  while ((curNodePtr != NULL) && (curNodePtr->numChildren == 0)) {
	    Node *parentPtr = curNodePtr->parentPtr;

	    if (parentPtr->children.nodePtr == curNodePtr) {
	      parentPtr->children.nodePtr = curNodePtr->nextPtr;
	    } else {
	      Node *prevNodePtr = parentPtr->children.nodePtr;

	      while (prevNodePtr->nextPtr != curNodePtr) {
		prevNodePtr = prevNodePtr->nextPtr;
	      }
	      prevNodePtr->nextPtr = curNodePtr->nextPtr;
	    }
	    parentPtr->numChildren--;
	    DeleteSummaries(curNodePtr->summaryPtr);
	    ckfree((char *) curNodePtr);
	    curNodePtr = parentPtr;
	  }

	  /*
	   * The node of the last line, or the first of its ancestors left
	   * when it went: it may have too few children now.
	   */

	  lastNodePtr = curNodePtr;
	}
	pSegment2.linePtr->nextPtr = endLinePtr;
	((BTree *)newSegPtr->body.itree.tree)->rootPtr->numLines += addLines;
	((BTree *)newSegPtr->body.itree.tree)->rootPtr->numChildren += addLines;
      }

      /*
       * Cleanup the segments in the new line.
       */

      CleanupLine(((BTree *)newSegPtr->body.itree.tree)
		  ->rootPtr->children.linePtr);

      /* Now the segments are in correct lines, lines are in correct
       * nodes, length information in the nodes is correct, but the
       * length of the internal btree is not known. */

      curLinePtr 
	= ((BTree *)newSegPtr->body.itree.tree)->rootPtr->children.linePtr;
      count = 0;			/* Fake character at the
					 * beginning and at the end
					 * will be counted by extra
					 * newlines at the end */
      do {
	count += TkBTreeCharsInLine(curLinePtr);
      } while ( (curLinePtr = TkBTreeNextLine(curLinePtr)) );

      newSegPtr->size = count;
    } else if (blockPtr->empty) {
      newSegPtr->size = dummy = 1;
    }  else {
      newSegPtr->size = 2;
    }

    /*
     * Cleanup the segments in the ambient line.
     */

    CleanupLine(pSegment1.linePtr);

    /*
     * Lastly, rebalance the first node of the range.
     */

    if (!pSegment1.linePtr->parentPtr->segPtr) {
      if (lines) {
	/*
	 * The node of the last line first, if it is another one (it
	 * may lose all but a few lines); its merge with a neighbour
	 * may free it, but not the node of the first line, which is
	 * looked up again.
	 */

	if (lastNodePtr != NULL) {
	  Rebalance((BTree *) index1Ptr->tree, lastNodePtr);
	}
	Rebalance((BTree *) index1Ptr->tree, pSegment1.linePtr->parentPtr);
      }
    } else {
      /* Update the size of containing IBTree's, 1/2 dummy chars inserted. */
      IBtreeUpdateLength(pSegment1.linePtr->parentPtr->segPtr, dummy);

      /* If the range spans several nodes, need to glue them into
       * one. The internal nodes are already deleted, now need to call
       * some procedure ???? */
    }
    if (tkBTreeDebug) {
	TkBTreeCheck(pSegment1.linePtr->parentPtr->segPtr
	     ? pSegment1.linePtr->parentPtr->segPtr->body.itree.tree
	     : index1Ptr->tree);
	if (newSegPtr->body.itree.tree) {
	  TkBTreeCheck(newSegPtr->body.itree.tree);
	}
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * GlueLines --
 *
 *	Glue segments starting from a given one to a specified location.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Internal structure of the B-tree changes.  
 *
 *----------------------------------------------------------------------
 */

void
GlueLines(seg1Ptr, seg2Ptr, linePtr, prevPtr)
     TkTextSegment *seg1Ptr;		/* The position *after* the
					 * position we should glue to
					 * or NULL to denote end of line. */
     TkTextSegment *seg2Ptr;		/* The starting position of
					 * what to glue. */
     TkTextLine *linePtr;		/* The line of seg1Ptr. */
     TkTextSegment *prevPtr;		/* The position before seg1Ptr
					 * or NULL if unknown. */
{
    int safe = 0;			/* Is it save to just glue. */
    TkTextSegment *notRightPtr = NULL;	/* Last segment without right
					 * gravity. */

    if (seg2Ptr->size || !seg2Ptr->typePtr->leftGravity) {
      safe = 1;
    }

    /* Look for previous segment and possibly for last segment without
     * right gravity. */

    if (!safe || !prevPtr) {
      TkTextSegment *segPtr = NULL;

      if (linePtr->segPtr != seg1Ptr) {
	for (segPtr = linePtr->segPtr; ; 
	     segPtr = segPtr->nextPtr) {
	  if (segPtr->size != 0 || segPtr->typePtr->leftGravity) {
	    notRightPtr = segPtr;
	  }
	  if (segPtr->nextPtr == seg1Ptr) {
	    break;
	  }
	}
      }
      prevPtr = segPtr;
    }
    if (safe || (prevPtr == notRightPtr)) {
      if (prevPtr) {
	prevPtr->nextPtr = seg2Ptr;
      } else {
	linePtr->segPtr = seg2Ptr;
      }
    } else {
      /* Now we need to make sure that the segments with left
       * gravity go to the correct place. */

      TkTextSegment *leftPtr = seg2Ptr, *afterLeftPtr;

      /* Let leftPtr be the last with zero size and
       * 	 * left gravity, */

      while (leftPtr->nextPtr && (leftPtr->nextPtr->size == 0) 
	     && leftPtr->nextPtr->typePtr->leftGravity) {
	leftPtr = leftPtr->nextPtr;
      }
      afterLeftPtr = leftPtr->nextPtr;
      if (notRightPtr) {
	leftPtr->nextPtr = notRightPtr->nextPtr;
	notRightPtr->nextPtr = seg2Ptr;
      } else {
	leftPtr->nextPtr = linePtr->segPtr;
	linePtr->segPtr = seg2Ptr;
      }
      prevPtr->nextPtr = afterLeftPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeKillBlock --
 *
 *	Move characters from a IBTree back into ambient
 * 	B-tree. Remove the IBTree chunk. Does not rebalance the
 *	ambient block
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Internal structure of the B-tree changes.  
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeKillBlockProc(segPtr)
    register TkTextSegment *segPtr;	/* Segment to remove. */
{
    TkTextSegment *lastPtr = NULL;	/* The last surviving segment
					 * in the internal tree. Can
					 * be NULL to denote start of line. */
    TkTextSegment *nextPtr, *afterPtr, *headPtr;
    TkTextLine *outLinePtr, *intLinePtr, *nextLinePtr, *prevLinePtr = NULL;
    TkTextLine *firstLinePtr = NULL;
    int lines = -1;			/* Total lines added to outer
					 * tree. */
    int dummy = 2;			/* Number of dummy chars deleted. */

    if (segPtr->body.itree.tree == NULL) {
      /* Don't know how to find tree... ???? */
      TkBTreeUnlinkSegment(NULL,segPtr,segPtr->body.itree.linePtr);
      dummy = 1;
      outLinePtr = NULL;
    } else {
      BTree *treePtr = (BTree *) segPtr->body.itree.tree;

      /*
       * The block is dissolved: its contents join the enclosing
       * structure without its nodes and without the values of its
       * leaves, which are dropped before the lines move.
       */

      DropTreeValues(treePtr->textPtr, treePtr->rootPtr);
      intLinePtr = TkBTreeFindLine(segPtr->body.itree.tree,0);
      headPtr = intLinePtr->segPtr;
      afterPtr = segPtr->nextPtr;

      /* Find the previous segment. */
      outLinePtr = segPtr->body.itree.linePtr;
      intLinePtr->parentPtr->children.linePtr = NULL; /* Protect of deletion. */

      /* Cleanup the first internal line. */
      for (nextPtr = intLinePtr->segPtr; nextPtr; 
	   nextPtr = nextPtr->nextPtr) {
	if (nextPtr->typePtr->lineChangeProc != NULL) {
	  (*nextPtr->typePtr->lineChangeProc)(nextPtr, intLinePtr);
	}
      }

      /* Now it is safe to join the start. */

      GlueLines(segPtr, headPtr, outLinePtr, (TkTextSegment*) NULL);

      /* Iterate over internal lines moving contents to external
       *      * tree. */

      nextLinePtr = intLinePtr;		/* To pass the first check below. */
      firstLinePtr = prevLinePtr = intLinePtr;

      for (; nextLinePtr;
	   intLinePtr = nextLinePtr) {
	nextLinePtr = TkBTreeNextLine(intLinePtr);

	/* If last line in IBTree and end is not deleted, ignore it. */
	if (!nextLinePtr) {
	  if (intLinePtr->segPtr->nextPtr) {
	    panic("Dummy line in BTree not empty.");
	  }
	  break;
	}
	prevLinePtr = intLinePtr;

	/* Send lineChange signals. */
	if (lines >= 0) {		/* Not a first line. */
	  for (nextPtr = intLinePtr->segPtr; nextPtr; 
	       nextPtr = nextPtr->nextPtr) {
	    if (nextPtr->typePtr->lineChangeProc != NULL) {
	      (*nextPtr->typePtr->lineChangeProc)(nextPtr, intLinePtr);
	    }
	  }
	  intLinePtr->parentPtr->children.linePtr = NULL; /* Protect of
							   * deletion.  */
	  intLinePtr->parentPtr = outLinePtr->parentPtr;
	  CleanupLine(intLinePtr);
	}
	intLinePtr->nextPtr = nextLinePtr;
	lines++;
      }

      /* Now prevLinePtr contains last real line, intLinePtr contains
       * the dummy line, and it is not disconnected from its parent yet,
       * so later it will be deleted. */
    
      /* Find an appropriate place to insert segments with left
       * gravity. Since the line can be ended in a segment with "\n" only
       * we should consider the last segment separately. */

      for (nextPtr = prevLinePtr->segPtr; nextPtr->nextPtr; 
	   nextPtr = nextPtr->nextPtr) {	
	lastPtr = nextPtr;
      }
      /* Now nextPtr is the last segment in the line, so it is a character
       * segment the length of which will be cut by 1. */
      if (nextPtr->size > 1) {
	lastPtr = nextPtr;
	lastPtr->body.chars[ --lastPtr->size ] = 0;
      } else {
	if (!nextPtr->size) {
	  panic("Line finished in a segment of length 0 in TkBTreeKillBlockProc.");
	}
	if ((lines == 0) && (lastPtr == NULL)) {
	  /*
	   * The newline is all there is on the only internal line (the
	   * block is empty), and GlueLines above has linked it into the
	   * outer line after the segments before the block: unlink it
	   * from there before it is freed, so that the chain ends where
	   * it would end if there were text before the newline.
	   */

	  TkTextSegment *beforePtr;

	  if (outLinePtr->segPtr == nextPtr) {
	    outLinePtr->segPtr = NULL;
	  } else {
	    for (beforePtr = outLinePtr->segPtr; beforePtr->nextPtr != nextPtr;
		 beforePtr = beforePtr->nextPtr) {
	      /* Empty. */
	    }
	    beforePtr->nextPtr = NULL;
	  }
	}
	/* Delete the segment */
	if ((*nextPtr->typePtr->deleteProc)(nextPtr, prevLinePtr, 0)) {
	  panic("Could not delete a segment in TkBTreeKillBlockProc.");
	}
	if (lastPtr) {
	  lastPtr->nextPtr = NULL;
	} else {
	  prevLinePtr->segPtr = NULL;
	}
      }

      if (lines > 0) {
	Node *nodePtr;

	prevLinePtr->nextPtr = outLinePtr->nextPtr;
	outLinePtr->nextPtr = firstLinePtr->nextPtr;
	for (nodePtr = outLinePtr->parentPtr ; nodePtr != NULL;
	     nodePtr = nodePtr->parentPtr) {
	  nodePtr->numLines += lines;
	}
	outLinePtr->parentPtr->numChildren += lines;

	/* Send LineChange signal to segments at the end of the outer line. */
	for (nextPtr = afterPtr; nextPtr; 
	     nextPtr = nextPtr->nextPtr) {
	  if (nextPtr->typePtr->lineChangeProc != NULL) {
	    (*nextPtr->typePtr->lineChangeProc)(nextPtr, outLinePtr);
	  }
	}
      }

      /* Join the segments at the end of outer line to the last seen
       * segment. The tricky point is that we should move the segments with
       * left gravity to the correct point. */

      GlueLines((TkTextSegment*)NULL, afterPtr,
		(lines > 0) ? prevLinePtr: outLinePtr,
		lastPtr);

      /*
       * The dummy line is in no node's list of children any more (the
       * lines moved out cut those lists, see "Protect of deletion"),
       * so TkBTreeDestroy would not free it: free it here, with its
       * newline.  The first internal line, whose segments joined the
       * outer line, is freed at the end.
       */

      intLinePtr->parentPtr->children.linePtr = NULL;
      while ((nextPtr = intLinePtr->segPtr) != NULL) {
	intLinePtr->segPtr = nextPtr->nextPtr;
	(*nextPtr->typePtr->deleteProc)(nextPtr, intLinePtr, 1);
      }
      ckfree((char *) intLinePtr);
      
      TkBTreeDestroy(segPtr->body.itree.tree);
    }

    /* Now delete the segment itself. */

    segPtr->body.itree.blockPtr->count--;
    DropBlockData(segPtr);
    ckfree((char *)segPtr);

    /* Now all the segments got the signals, the lines are joined to the
     * ambient tree. Can do cleanup. */

    if (lines > 0) {
	CleanupLine(prevLinePtr);
    }
    if (outLinePtr) {
	CleanupLine(outLinePtr);
	if (outLinePtr->parentPtr->segPtr) {
	    IBtreeUpdateLength(outLinePtr->parentPtr->segPtr, -dummy);
	}
	ckfree((char *) firstLinePtr);	/* (See above.) */
    }
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeTextAppend
 *
 *	Extracts text of a part of an internal BTree. Actual action
 *	depends on flags.
 * 
 *	If TKT_GET_DSTRING is given, appends to the given DString.
 * 
 *	If TKT_GET_BUFFER is given, appends to the given character array.
 * 
 *	If TKT_GET_OFFSET is given, then reports the position which
 *	corresponds to the given offset in the output string only. No
 *	actual string appending is done.
 * 
 *	In the last two cases offsetPtr is read-write parameter. It
 *	gives the size of buffer or position in the output string to
 *	report. When function returns, it contains remaining size of the
 *	buffer. (This size may be non-0 even in the case of
 *	TKT_GET_OFFSET, since one character in text widget may take
 *	more than one character in the output string after some future
 *	extensions.)
 * 
 *	Text is lowercased if the flag TKT_GET_NOCASE is given.
 * 
 * Results:
 *	Offset inside BTree segment which corresponds to the
 *	position after the last output character.
 * 
 * Side effects:
 * 	DString or output buffer may be changed. *offsetPtr is
 *	changed.
 *------------------------------------------------------------------
 */
int
TkIBTreeTextAppend(textPtr, segPtr, start, end, targetPtr, flags, offsetPtr)
     TkText *textPtr;			/* Needed in TkBtreeLineTextAppend. */
     TkTextSegment *segPtr;		/* IBTree. */
     int start;				/* Index where to start
					 * inside IBTree. */
     int end;				/* Index before which to end, counted
					 * as above, or -1 to go
					 * to the end. */
     void *targetPtr;			/* Where to append. */
     int flags;				/* Whether to lowercase and friends. */
     int *offsetPtr;			/* If dstringPtr is NULL, this
					 * denotes the offset inside
					 * the would-be resulting string. */
{
    TkTextLine *linePtr = NULL;
    int endline = -1, doend = 0, doends = 0, length, res = start,
	dostart = 0;
    Tcl_DString *dstringPtr = (Tcl_DString *) targetPtr; /* Where to append. */
    ListFactory *lfPtr = (ListFactory *) targetPtr; /* Where to append. */
    char *buffer = (char *) targetPtr;	/* Where to append. */
    Arg arg = NULL;
    Arg instData = (flags & TKT_GET_NOVALUES) ? NULL
	    : TkTextDataGetLang(segPtr->body.itree.data);
					/* The Lang part of the instance
					 * data, or NULL (always for the
					 * undo, which records the whole
					 * container: TK_TEXT_VALUE_BLOCK). */

    if (!(flags & (TKT_GET_DSTRING | TKT_GET_LIST)) && *offsetPtr <= 0) {
      return res;
    }
    if (segPtr->body.itree.tree == NULL) {
        if (flags & TKT_GET_DSTRING) Tcl_DStringAppend(dstringPtr, ".", 1);
        else if (flags & TKT_GET_LIST) {
	    lfPtr = ListFactoryNewLevelWithType(lfPtr, IdType("E","Tk::Text::Empty"));
	    LangSetString(&arg, segPtr->body.itree.blockPtr->name);
	    ListFactoryAppendCopy(lfPtr,arg);
	    if (instData != NULL) {
	        ListFactoryAppendCopy(lfPtr, instData);
	    }
	    lfPtr = ListFactoryEndLevelWithType(lfPtr);
	    LangFreeArg(arg, LANG_DYNAMIC);
	} else {
	  res++;
	  (*offsetPtr) --;
	  if (flags & TKT_GET_BUFFER) *buffer++ = '.';
	}
	return res;
    }
    end--;
    if (end < -1) {
      end = segPtr->size - 1;
    }
    if (end == segPtr->size - 1) {
      doend = 1;
      end--;
    }
    if (start < 0) {
      start = 0;
    }
    if (flags & TKT_GET_LIST && (start == 0 || doend)) {
        /* The requested interval touches start or end of the
	 * chunk. */
        doends = 1;
	lfPtr = ListFactoryNewLevelWithType(lfPtr, IdType("B","Tk::Text::Block"));
	lfPtr = ListFactoryNewLevel(lfPtr);
	LangSetString(&arg, segPtr->body.itree.blockPtr->name);
	ListFactoryAppendCopy(lfPtr,arg);
	LangSetInt(&arg, ((BTree*)segPtr->body.itree.tree)->rootPtr->level);
	ListFactoryAppendCopy(lfPtr,arg);
	if (instData != NULL) {
	    ListFactoryAppendCopy(lfPtr, instData);
	}
	if (!(flags & TKT_GET_NOVALUES) && (start == 0) && doend
		&& NodeHasValues(((BTree*)segPtr->body.itree.tree)->rootPtr)) {
	    /*
	     * [name, level, data or undef, node values]: only when the
	     * whole block is listed (the values follow the whole tree,
	     * which a partial listing does not show).
	     */
	    if (instData == NULL) {
		ListFactoryAppendPure(lfPtr, newSV(0));
	    }
	    NodeValuesList(((BTree*)segPtr->body.itree.tree)->rootPtr, lfPtr);
	}
	lfPtr = ListFactoryEndLevel(lfPtr);
	targetPtr = (void *) lfPtr;
    }
    if (start == 0 && end >= 0) {
      if (flags & TKT_GET_DSTRING) Tcl_DStringAppend(dstringPtr, "{", 1);
      else if (!(flags & TKT_GET_LIST)) {
	(*offsetPtr)--;
	res++;
	if (flags & TKT_GET_BUFFER) *buffer++ = '{';
	if (*offsetPtr <= 0) return res;
      }
      dostart = 1;
    } else {
	start--;
    }
    linePtr = TkBTreeFindLine(segPtr->body.itree.tree, 0);
    length = TkBTreeCharsInLine(linePtr);
    endline = length - 1;
    while ((start < end) 
	   /* Conditions if end is at beginning of a line: */
	   || (dostart && start == end && end == endline + 1)
	   /* The whole block, and its only leaf is empty: the marks and
	    * toggles in that leaf are in the range too. */
	   || (dostart && doend && start == end
	       && end == endline - length + 1)) {
	int old, new;

	while (start > endline) {
	    linePtr = TkBTreeNextLine(linePtr);
	    length = TkBTreeCharsInLine(linePtr);
	    endline += length;
	}
	if (flags & TKT_GET_BUFFER) targetPtr = (void*) buffer;
	if (dostart) {
	    old = -1;
	} else {
	    old = start - (endline - length + 1);
	}
	new = TkBTreeLineTextAppend(textPtr, linePtr, old, 
				    (end > endline || (end == endline && doend))
				    ? -2 /* length - 1 */
				    : end - (endline - length + 1), 
				    targetPtr, flags, offsetPtr);
	/*
	 * new is the position reached inside the internal line; old is
	 * -1 when the line is reported from its start (so the position
	 * reached is new - 0 from there, not new + 1).
	 */
	res += new - ((old < 0) ? 0 : old);
	if (!(flags & (TKT_GET_DSTRING | TKT_GET_LIST)) && *offsetPtr <= 0) 
	    return res;
	if (flags & TKT_GET_BUFFER)
	    buffer += new - (start - (endline - length + 1));
	if (end > endline) {
	    if (flags & TKT_GET_DSTRING) Tcl_DStringAppend(dstringPtr, "|", 1);
	    else if (flags & TKT_GET_LIST) {
		int level = 0;
		register Node *nodePtr;

		if (linePtr->nextPtr == NULL) {
		    level = 1;
		    for (nodePtr = linePtr->parentPtr; 
			 nodePtr && nodePtr->nextPtr == NULL; 
			 nodePtr = nodePtr->parentPtr) {
			level++;
		    }
		}
		LangSetInt(&arg, level);
		ListFactoryAppendCopyWithType(lfPtr, arg, 
					      IdType("|",
						     "Tk::Text::BlockSeparator"));
	    } else {
		(*offsetPtr)--;
		res++;
		if (flags & TKT_GET_BUFFER) *buffer++ = '|';
		if (*offsetPtr <= 0) return res;
	    }
	}
	start = endline + 1;
	dostart = 1;
    }  
    if (doends) {
      lfPtr = ListFactoryEndLevelWithType(lfPtr);
    } else if (doend) {
      if (flags & TKT_GET_DSTRING) Tcl_DStringAppend(dstringPtr, "}", 1);
      else {
	(*offsetPtr)--;
	if (flags & TKT_GET_BUFFER) *buffer++ = '}';
	return ++res;
      }
    }
    if (arg) LangFreeArg(arg, LANG_DYNAMIC);
    return res;
}

/*
 *------------------------------------------------------------------
 *
 * TkBtreeLineTextAppend
 *
 *	Extracts text of a part of a line. Actual action depends on
 *	flags.
 * 
 *	If TKT_GET_DSTRING is given, appends to the given DString.
 * 
 *	If TKT_GET_BUFFER is given, appends to the given character array.
 * 
 *	If TKT_GET_OFFSET is given, then reports the position which
 *	corresponds to the given offset in the output string only. No
 *	actual string appending is done.
 * 
 *	In the last two cases offsetPtr is read-write parameter. It
 *	gives the size of buffer or position in the output string to
 *	report. When function returns, it contains remaining size of the
 *	buffer. (This size may be non-0 even in the case of
 *	TKT_GET_OFFSET, since one character in text widget may take
 *	more than one character in the output string after some future
 *	extensions.)
 * 
 *	Text is lowercased if the flag TKT_GET_NOCASE is given.
 * 
 * Results:
 *	Offset inside Text widget's line which corresponds to the
 *	position after the last output character.
 * 
 * Side effects:
 * 	DString or output buffer may be changed. *offsetPtr is changed.
 *
 *------------------------------------------------------------------
 */
int
TkBTreeLineTextAppend(textPtr, linePtr, start, end, targetPtr, flags, offsetPtr)
     TkText *textPtr;			/* Needed to get marks and
					 * widget extraction work. */
     TkTextLine *linePtr;		/* Line to report. */
     int start;				/* Index where to start
					 * inside the line. -1 denotes
					 * that the segments with left
					 * gravity at the start of line
					 * should be reported too. */
     int end;				/* Index before which to end, counted
					 * as above, or -1 to go
					 * to the end. -2 denotes a
					 * special case: all the line
					 * is reported except the final
					 * newline. */
     void *targetPtr;			/* Where to append, should be
					 * converted to DString or
					 * char*. Ignored for OFFSET
					 * processing. */
     int flags;				/* Whether to lowercase and friends. */
     int *offsetPtr;			/* Ignored if extracting to dstring.
					 * Otherwise is the offset inside
					 * the (possible) resulting string.
					 */
{
  TkTextSegment *segPtr = linePtr->segPtr;
  int size, last, res = start, dostart = 0, doend = 0;
  int segOffset = 0;			/* Offset of segPtr in the line. */
  Tcl_DString *dstringPtr = (Tcl_DString *) targetPtr; /* Where to append. */
  ListFactory *lfPtr = (ListFactory *) targetPtr; /* Where to append. */
  char *buffer = (char *) targetPtr;	/* Where to append. */
  Arg arg = NULL;

  if (start < 0) {
    res = start = 0;
    dostart = 1;
  }
  if (end == -1) end = INT_MAX;
  if (end == -2) {
      doend = 1;
      end = TkBTreeCharsInLine(linePtr) - 1;
  }
  end -= start;
  if (!dostart) {
      /* Skip leading segments. */
      while (segPtr && (start > segPtr->size || 
			(start == 0 && segPtr->size == 0
			 && segPtr->typePtr->leftGravity))) {
	  start -= segPtr->size;
	  segOffset += segPtr->size;
	  segPtr = segPtr->nextPtr;
      }
  }
  end += start;
  while (segPtr && (end >= 0)) {
      size = segPtr->size;
      /* We should stop when there is nothing left of non-0 length, or
       * zero-length, but left gravity. */
      if (end == 0 && size == 0 && !segPtr->typePtr->leftGravity && !doend) {
	goto finish;
      }
      last = end;
      if (last > size) {
	last = size;
      }
      if ((flags & TKT_GET_NOELIDE) && (size > 0)
	  && ((segPtr->typePtr == &tkTextCharType)
	      || (segPtr->typePtr == &tkTextIBTreeType))) {
	  TkTextIndex index;

	  /*
	   * Elided text is left out (search, the selection), as in Tk 8.4.
	   * Its index space is still accounted for.
	   */

	  index.tree = NULL;
	  index.linePtr = linePtr;
	  index.byteIndex = segOffset;
	  if (TkTextIsElided(textPtr, &index)) {
	      if (flags & (TKT_GET_OFFSET | TKT_GET_BUFFER)) {
		  res += last - start;
	      }
	      goto nextSegment;
	  }
      }
      if (segPtr->typePtr == &tkTextCharType) {
	char *p = NULL;			/* Avoid warnings. */

	if (flags & TKT_GET_DSTRING) {
	  int oldLength = Tcl_DStringLength(dstringPtr);

	  Tcl_DStringAppend(dstringPtr, segPtr->body.chars + start,
			    last - start);
	  if (flags & TKT_GET_NOCASE) {
	    /*
	     * The append may have moved the buffer (under Perl/Tk a
	     * Tcl_DString is an SV), so take the pointer only now.
	     */

	    p = Tcl_DStringValue(dstringPtr) + oldLength;
	    TkTextUtfToLowerSameLength(p, last - start);
	  }
	} else if (flags & TKT_GET_LIST) {
	  if (start != last) {		/* XXXXX Needed, otherwise
					 * empty at the end ???? */
	      char c = segPtr->body.chars[last];

	      segPtr->body.chars[last] = '\0';
	      LangSetString(&arg, segPtr->body.chars + start);
	      ListFactoryAppendCopyWithType(lfPtr, arg, IdType("S","Tk::Text::String"));
	      segPtr->body.chars[last] = c;
	  }
	} else {
	    int paste;
	    paste = *offsetPtr > last - start ? last - start : *offsetPtr;
	    res += paste;
	    (*offsetPtr) -= paste;
	    if (flags & TKT_GET_BUFFER) {
	        strncpy(buffer, segPtr->body.chars + start, paste);
	        buffer += paste;
	    }
	    if (*offsetPtr == 0) {
	        return res;
	    }
	}
      } else if (segPtr->typePtr == &tkTextIBTreeType) {
	  int new;

	  if (start >= last) {
	      /*
	       * Nothing of the block is in the range: the range starts
	       * where the block ends (the skipping above stops at a
	       * segment the start is at the end of) or is empty.  Asking
	       * for the block from its end on reported an empty block
	       * and its last newline, which "block list" returned and
	       * the undo of a deletion starting just after a block
	       * re-inserted (a stray block, and a broken tree).
	       */

	      goto nextSegment;
	  }
	  if (flags & TKT_GET_BUFFER) targetPtr = (void*) buffer;
	  new = TkIBTreeTextAppend(textPtr, segPtr, start, last, 
				   targetPtr, flags, offsetPtr);
	  res += new - start;
	  if (flags & TKT_GET_BUFFER) buffer += new - start;
      } else if (flags & TKT_GET_LIST) { /* Appending to a list,
					  * should process anyway. */
	  if ((segPtr->typePtr == &tkTextToggleOnType)
		  && (TkTextDataGetLang(segPtr->body.toggle.value) != NULL)
		  && !(flags & TKT_GET_NOVALUES)) {
	      /* A run with a value ("tag data"): [name, value]. */
	      lfPtr = ListFactoryNewLevelWithType(lfPtr,
				IdType("T","Tk::Text::TagOn"));
	      LangSetString(&arg, segPtr->body.toggle.tagPtr->name);
	      ListFactoryAppendCopy(lfPtr, arg);
	      ListFactoryAppendPure(lfPtr,
		      TkTextDataLangSV(segPtr->body.toggle.value));
	      lfPtr = ListFactoryEndLevelWithType(lfPtr);
	  } else if (segPtr->typePtr == &tkTextToggleOnType) {
	      LangSetString(&arg, segPtr->body.toggle.tagPtr->name);
	      ListFactoryAppendCopyWithType(lfPtr, arg,
					    IdType("T","Tk::Text::TagOn"));
	  } else if (segPtr->typePtr == &tkTextToggleOffType) {
	      LangSetString(&arg, segPtr->body.toggle.tagPtr->name);
	      ListFactoryAppendCopyWithType(lfPtr, arg,
					    IdType("t","Tk::Text::TagOff"));
	  } else if (((segPtr->typePtr == &tkTextLeftMarkType)
		      || (segPtr->typePtr == &tkTextRightMarkType))
		  && (TkTextDataGetLang(segPtr->body.mark.value) != NULL)
		  && !(flags & TKT_GET_NOVALUES)) {
	      /* A mark with a value ("mark data"): [name, value]. */
	      lfPtr = ListFactoryNewLevelWithType(lfPtr,
		      (segPtr->typePtr == &tkTextLeftMarkType)
		      ? IdType("L","Tk::Text::MarkLeft")
		      : IdType("R","Tk::Text::MarkRight"));
	      LangSetString(&arg, Tcl_GetHashKey(&textPtr->markTable,
						 segPtr->body.mark.hPtr));
	      ListFactoryAppendCopy(lfPtr, arg);
	      ListFactoryAppendPure(lfPtr,
		      TkTextDataLangSV(segPtr->body.mark.value));
	      lfPtr = ListFactoryEndLevelWithType(lfPtr);
	  } else if (segPtr->typePtr == &tkTextLeftMarkType) {
	      LangSetString(&arg, Tcl_GetHashKey(&textPtr->markTable,
						 segPtr->body.mark.hPtr));
	      ListFactoryAppendCopyWithType(lfPtr, arg,
					    IdType("L","Tk::Text::MarkLeft"));
	  } else if (segPtr->typePtr == &tkTextRightMarkType) {
	      LangSetString(&arg,  Tcl_GetHashKey(&textPtr->markTable,
						  segPtr->body.mark.hPtr));
	      ListFactoryAppendCopyWithType(lfPtr, arg,
					    IdType("R","Tk::Text::MarkRight"));
	  } else if (strcmp(segPtr->typePtr->name, "window") == 0) {	
	      /* XXXX Note that tkTextEmbWindowType is static :-(. */
	      lfPtr = ListFactoryNewLevelWithType(lfPtr,
						  IdType("W",
							 "Tk::Text::EmbWin"));
	      if (arg) {
		  LangFreeArg(arg, LANG_DYNAMIC);
	      }
	      arg = LangWidgetArg(textPtr->interp, segPtr->body.ew.tkwin);
	      ListFactoryAppendCopy(lfPtr, arg);
	      LangFreeArg(arg, LANG_DYNAMIC);
	      arg = LangCallbackArg(segPtr->body.ew.create);
	      ListFactoryAppendCopy(lfPtr, arg);
	      LangFreeArg(arg, LANG_DYNAMIC);
	      arg = NULL;
	      /* Then its options, for undo to re-create it. */
	      TkTextWindowOptionList(segPtr, lfPtr);
	      lfPtr = ListFactoryEndLevelWithType(lfPtr);
	  } else if (strcmp(segPtr->typePtr->name, "image") == 0) {
	      /*
	       * An embedded image: its name in the widget, then its
	       * options, for undo to re-create it.
	       */
	      lfPtr = ListFactoryNewLevelWithType(lfPtr,
						  IdType("I",
							 "Tk::Text::EmbImage"));
	      LangSetString(&arg, segPtr->body.ei.name ? segPtr->body.ei.name : "");
	      ListFactoryAppendCopy(lfPtr, arg);
	      TkTextImageOptionList(segPtr, lfPtr);
	      lfPtr = ListFactoryEndLevelWithType(lfPtr);
	  } else {
	      panic("Unknown type of text annotation!");
	  }
      } else if (flags & (TKT_GET_OFFSET | TKT_GET_BUFFER)) {	/* Unknown segment */
	int cnt = last - start;

	/* Report the start of the segment if it is too long */
	if (*offsetPtr < last - start && (flags & TKT_GET_STRICT)) return res;
	res += last - start;
	if (flags & TKT_GET_STRICT) (*offsetPtr) -= last - start;
	if ((flags & TKT_GET_BUFFER) && (flags & TKT_GET_STRICT)) {
	  while (cnt-- > 0) *buffer++ = '*';
	}
      } else if (flags & TKT_GET_STRICT) { /* Unknown segment */
	int cnt = last - start;

	while (cnt--) Tcl_DStringAppend(dstringPtr, "*", 1);
      }
    nextSegment:
      start = 0;
      end -= size;
      segOffset += size;
      segPtr = segPtr->nextPtr;
  }
 finish:
  LangFreeArg(arg, LANG_DYNAMIC);
  return res;
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeFixTags
 *
 * 	Given a list of tags, deletes some tags from the list. The
 *	deleted tags are the tags that change inside the given IBTree
 *	segment.
 *
 * Results:
 * 	None.
 *
 * Side effects:
 * 	Given list of tags and counter are modified.
 *
 *------------------------------------------------------------------
 */
void
TkIBTreeFixTags(segPtr, tagPtrPtr, nPtr)
     TkTextSegment *segPtr;	/* IBTree segment. */
     TkTextTag **tagPtrPtr;	/* Array of pointers to Tags to modify. */
     int *nPtr;			/* Pointer to Number of Tags to modify. */
{
  int done = 0;
  Node *nodePtr;

  if (!segPtr->body.itree.tree) {
    return;
  }
  nodePtr = ((BTree*)segPtr->body.itree.tree)->rootPtr;
  while (done < *nPtr) {
    TkTextTag *tagPtr = tagPtrPtr[done];
    Summary *sumPtr = nodePtr->summaryPtr;
    int survive = 1;

    while (sumPtr) {
      if (sumPtr->tagPtr == tagPtr) {
	tagPtrPtr[done] = tagPtrPtr[--(*nPtr)];
	survive = 0;
	break;
      }
      sumPtr = sumPtr->nextPtr;
    }
    if (survive) {
      done++;
    }
  }
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeTogglesElide
 * 	Whether a segment is a block inside which a tag with an -elide
 *	option switches on or off (a tag of the summary of its root,
 *	which TkIBTreeFixTags drops at the head).  The display does not
 *	skip such a block as elided text: whether it is drawn, and what
 *	of it, depends on what is inside.
 *
 * Returns:
 * 	1 if so, 0 otherwise (other segments, -empty blocks).
 *
 * Side effects:
 * 	None.
 *
 *------------------------------------------------------------------
 */
int
TkIBTreeTogglesElide(segPtr)
     TkTextSegment *segPtr;	/* Any segment. */
{
  Summary *sumPtr;

  if ((segPtr->typePtr != &tkTextIBTreeType) || !segPtr->body.itree.tree) {
    return 0;
  }
  for (sumPtr = ((BTree*)segPtr->body.itree.tree)->rootPtr->summaryPtr;
       sumPtr != NULL; sumPtr = sumPtr->nextPtr) {
    if (sumPtr->tagPtr->elideString != NULL) {
      return 1;
    }
  }
  return 0;
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeSeparatorLevels, TkIBTreeSetSeparatorLevels --
 *
 *	"block insert" inside a block moves the leaves of its range into
 *	the new block, whose separators are all of level 0, and the
 *	undo dissolves that block, which splices them back at level 0:
 *	the grouping of the leaves into the nodes of the enclosing
 *	block is lost (BUGS 18).  The first records, before the block
 *	insert, the level of the separator after each leaf from the one
 *	holding index1 to the one holding index2 (the separators in the
 *	range, and the one just after it, whose level the moves change
 *	too); the second, after the dissolution, sets each of them back
 *	to its level, from left to right.  No text moves: raising a
 *	level splits the ancestors of the separator's two leaves from
 *	the level where they meet up to the level asked for (as
 *	TkIBTreeSplit does, without inserting a newline), the nodes
 *	after the cut starting without values; lowering it joins them
 *	down to that level, the joined node keeping the data the merge
 *	policy gives it (TkTextDataMerge: here the nodes made by a raise
 *	have none, so a node the block insert left on the end side gives
 *	its value back to the node that starts at its old first leaf).
 *	The values of the nodes the block insert emptied then find
 *	their nodes again at their addresses (TkBTreeRestoreValues).
 *
 *	A separator's level is the level (Node.level) of the lowest
 *	common ancestor of the leaves on its two sides: 0 if they have
 *	the same parent.
 *
 * Returns:
 *	TkIBTreeSeparatorLevels: a malloc-ed array of *numPtr levels,
 *	or NULL if the range is not inside a block.
 *
 * Side effects:
 *	TkIBTreeSetSeparatorLevels changes the tree of the block holding
 *	indexPtr; a value that loses a join is freed at the end of the
 *	widget command.
 *
 *------------------------------------------------------------------
 */

static Node *
AncestorAt(linePtr, level)
    TkTextLine *linePtr;		/* A leaf of a block. */
    int level;				/* A Node.level. */
{
    Node *nodePtr = linePtr->parentPtr;

    while ((nodePtr != NULL) && (nodePtr->level < level)) {
	nodePtr = nodePtr->parentPtr;
    }
    return nodePtr;
}

/*
 * The level of the separator after a leaf, or -1 if the leaf is the
 * last one (the next line is the dummy line of the tree).
 */

static int
SeparatorLevel(linePtr, nextPtrPtr)
    TkTextLine *linePtr;		/* The leaf. */
    TkTextLine **nextPtrPtr;		/* Filled with the next leaf. */
{
    TkTextLine *nextPtr = TkBTreeNextLine(linePtr);
    Node *aPtr, *bPtr;

    *nextPtrPtr = nextPtr;
    if ((nextPtr == NULL) || IsLastLine(nextPtr)) {
	return -1;
    }
    for (aPtr = linePtr->parentPtr, bPtr = nextPtr->parentPtr;
	 (aPtr != bPtr) && (aPtr != NULL) && (bPtr != NULL);
	 aPtr = aPtr->parentPtr, bPtr = bPtr->parentPtr) {
	/* Empty: the leaves of a block are all at the same depth. */
    }
    return ((aPtr != NULL) && (aPtr == bPtr)) ? aPtr->level : -1;
}

int *
TkIBTreeSeparatorLevels(index1Ptr, index2Ptr, numPtr)
    TkTextIndex *index1Ptr;		/* Start of the range (outermost
					 * tree). */
    TkTextIndex *index2Ptr;		/* Its end. */
    int *numPtr;			/* Filled with the number of
					 * levels. */
{
    TkTextIndex i1, i2;
    TkTextLine *linePtr, *nextPtr;
    int *levels, n = 0, size = 1, level;

    *numPtr = 0;
    TkTextIndexToInternalSeg(index1Ptr, &i1, NULL);
    TkTextIndexToInternalSeg(index2Ptr, &i2, NULL);
    if ((i1.linePtr->parentPtr->segPtr == NULL)
	    || (i1.linePtr->parentPtr->segPtr
		    != i2.linePtr->parentPtr->segPtr)) {
	return NULL;
    }
    for (linePtr = i1.linePtr; ; linePtr = nextPtr) {
	if ((SeparatorLevel(linePtr, &nextPtr) < 0)
		|| (linePtr == i2.linePtr)) {
	    break;
	}
	size++;
    }
    levels = (int *) ckalloc((unsigned) (size * sizeof(int)));
    for (linePtr = i1.linePtr; n < size; linePtr = nextPtr) {
	level = SeparatorLevel(linePtr, &nextPtr);
	if (level < 0) {
	    break;			/* The last leaf. */
	}
	levels[n++] = level;
	if (linePtr == i2.linePtr) {
	    break;			/* The separator just after. */
	}
    }
    if (n == 0) {
	ckfree((char *) levels);
	return NULL;
    }
    *numPtr = n;
    return levels;
}

/*
 * Before two nodes of a block are joined (aPtr surviving): tell the
 * -valuecommand what the merge does to bPtr's value (the tree is
 * consistent here).
 */

static Tcl_Obj *
VcNodeAt(textPtr, nodePtr)
    TkText *textPtr;
    Node *nodePtr;
{
    TkTextIndex index, ext;
    Node *firstPtr = nodePtr;

    while (firstPtr->level > 0) {
	firstPtr = firstPtr->children.nodePtr;
    }
    index.tree = NULL;
    index.linePtr = firstPtr->children.linePtr;
    index.byteIndex = 0;
    TkTextIndexToExternalIndex(textPtr->tree, &index, &ext);
    return TkTextVcNodePlace(textPtr, TkBTreeLineIndex(ext.linePtr),
	    ext.byteIndex, nodePtr->level + 1);
}

static void
VcJoinNodes(textPtr, aPtr, bPtr)
    TkText *textPtr;
    Node *aPtr, *bPtr;			/* bPtr joins aPtr. */
{
    int event;

    if (TkTextDataGetLang(bPtr->value) == NULL) {
	return;
    }
    if (TkTextDataIsEmpty(aPtr->value)) {
	TkTextVcPredict(textPtr, bPtr->value, TK_TEXT_VC_MOVE,
		TK_TEXT_VC_NODE, VcNodeAt(textPtr, bPtr),
		VcNodeAt(textPtr, aPtr));
    } else {
	event = ((textPtr->valueCapture != NULL)
		&& (textPtr->valueAddresses != NULL)
		&& (Tcl_FindHashEntry(textPtr->valueAddresses, (char *) bPtr)
			!= NULL)) ? TK_TEXT_VC_STASH : TK_TEXT_VC_DROP;
	TkTextVcPredict(textPtr, bPtr->value, event, TK_TEXT_VC_NODE,
		VcNodeAt(textPtr, bPtr), NULL);
    }
    TkTextVcNotify(textPtr);
}

static void
SetSeparatorLevel(textPtr, linePtr, level)
    TkText *textPtr;			/* The widget. */
    TkTextLine *linePtr;		/* The leaf before the separator. */
    int level;				/* The level to give it. */
{
    TkTextLine *nextPtr;
    Node *xPtr, *newPtr, *aPtr, *bPtr, *parentPtr;
    int cur = SeparatorLevel(linePtr, &nextPtr), lev;

    if ((cur < 0) || (level < 0)) {
	return;
    }

    /*
     * Raise: split the node where the two leaves meet, between them,
     * and then its parent between the two halves, and so on.
     */

    for (lev = cur; lev < level; lev++) {
	xPtr = AncestorAt(linePtr, lev);
	if ((xPtr == NULL) || (xPtr->parentPtr == NULL)) {
	    break;			/* The root: no level above it. */
	}
	newPtr = (Node *) ckalloc(sizeof(Node));
	newPtr->parentPtr = xPtr->parentPtr;
	newPtr->nextPtr = xPtr->nextPtr;
	xPtr->nextPtr = newPtr;
	newPtr->summaryPtr = NULL;
	newPtr->level = xPtr->level;
	newPtr->segPtr = xPtr->segPtr;
	TkTextDataInit(newPtr->value);	/* The part after the cut starts
					 * without a value. */
	if (lev == 0) {
	    newPtr->children.linePtr = nextPtr;
	    linePtr->nextPtr = NULL;
	} else {
	    aPtr = AncestorAt(linePtr, lev - 1);
	    newPtr->children.nodePtr = aPtr->nextPtr;
	    aPtr->nextPtr = NULL;
	}
	RecomputeNodeCounts(xPtr);
	RecomputeNodeCounts(newPtr);
	xPtr->parentPtr->numChildren++;
    }

    /*
     * Lower: join the two children of the node where the leaves meet
     * that lead to them, then the two children of the joined node
     * that lead to them, and so on down to the level asked for.
     */

    for (lev = cur - 1; lev >= level; lev--) {
	aPtr = AncestorAt(linePtr, lev);
	bPtr = AncestorAt(nextPtr, lev);
	if ((aPtr == NULL) || (aPtr == bPtr) || (aPtr->nextPtr != bPtr)) {
	    break;
	}
	parentPtr = aPtr->parentPtr;
	if (TkTextVcOn(textPtr)) {
	    VcJoinNodes(textPtr, aPtr, bPtr);
	}
	if (lev == 0) {
	    TkTextLine *lastPtr = aPtr->children.linePtr;

	    while (lastPtr->nextPtr != NULL) {
		lastPtr = lastPtr->nextPtr;
	    }
	    lastPtr->nextPtr = bPtr->children.linePtr;
	} else {
	    Node *lastPtr = aPtr->children.nodePtr;

	    while (lastPtr->nextPtr != NULL) {
		lastPtr = lastPtr->nextPtr;
	    }
	    lastPtr->nextPtr = bPtr->children.nodePtr;
	}
	aPtr->nextPtr = bPtr->nextPtr;
	MergeValues(textPtr, (void *) aPtr, &aPtr->value, (void *) bPtr,
		&bPtr->value);
	DeleteSummaries(bPtr->summaryPtr);
	ckfree((char *) bPtr);
	RecomputeNodeCounts(aPtr);
	parentPtr->numChildren--;
    }
}

void
TkIBTreeSetSeparatorLevels(textPtr, indexPtr, levels, num)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *indexPtr;		/* In the first leaf (outermost
					 * tree). */
    int *levels;			/* As TkIBTreeSeparatorLevels gave
					 * them. */
    int num;				/* How many. */
{
    TkTextIndex index;
    TkTextLine *linePtr, *nextPtr;
    int k;

    TkTextIndexToInternalSeg(indexPtr, &index, NULL);
    linePtr = index.linePtr;
    if (linePtr->parentPtr->segPtr == NULL) {
	return;
    }
    for (k = 0; (k < num) && (linePtr != NULL); k++) {
	SetSeparatorLevel(textPtr, linePtr, levels[k]);
	if (SeparatorLevel(linePtr, &nextPtr) < 0) {
	    break;
	}
	linePtr = nextPtr;
    }
}

/*
 *------------------------------------------------------------------
 *
 * NodePrint
 * 	Given an node and an array of pointers, calls the
 * report procedure on the lines in the node, grouping the results
 * in sublists according to tree structure.
 *
 * Returns:
 * 	None
 * 
 * Side effects:
 * 	Dynamic string grows.
 * 
 *------------------------------------------------------------------
 */
void
NodePrint(nodePtr, listFactoryPtr, linePtrs, linesLeft, levels, widthsMin,
	  widthsMax, widthsNum)
     Node *nodePtr;			/* Node to describe. */
     ListFactory *listFactoryPtr;	/* DString to fill. */
     struct DLine **linePtrs;		/* Pointers to DLines. */
     int linesLeft;			/* How many lines to print yet. */
     int levels;			/* How many levels to print
					 * yet, <=0 means all. */
     int *widthsMin;			/* Array of minimal number of 
					 * leaves to report. */
     int *widthsMax;			/* Array of maximal number of 
					 * leaves to report. */
     int widthsNum;			/* Length of above arrays,
					 * nonpositive means above
					 * data is junk. */
{
  int n = 0, count = 0, min = -1, max = INT_MAX; /* count is the
						  * number of lines/nodes
						  * that are actually
						  * printed.  */
  int countTarget = nodePtr->numChildren;

  if (widthsNum > 0) {
    min = *widthsMin; max = *widthsMax;
  }
  if (levels != 0) {
    if (nodePtr->level) {
      Node *intPtr = nodePtr->children.nodePtr;

      while (intPtr) {
	if ((count < max - 1) 
	    || ((count == max - 1) && (count == nodePtr->numChildren - 1))) {
	  if (levels != 1) {
	    listFactoryPtr = ListFactoryNewLevel(listFactoryPtr);
	  }
	  NodePrint(intPtr, listFactoryPtr, linePtrs + n, linesLeft - n, 
		    levels - 1, widthsMin + 1, widthsMax + 1, widthsNum - 1);
	  if (levels != 1) {
	    listFactoryPtr = ListFactoryEndLevel(listFactoryPtr);
	  }
	  n += intPtr->numLines;
	  intPtr = intPtr->nextPtr;
	} else {
	  goto addPrint;
	}
	count++;
      }
    } else {
      for (; (n < nodePtr->numLines) 
	   && ((n < max - 1) || (n == nodePtr->numLines - 1)); 
	   n++, count++) { 
	/* One dummy line per IBTree! */
	if (n == linesLeft) {
	  countTarget = count;
	  break;
	}
	listFactoryPtr = ListFactoryNewLevel(listFactoryPtr);
	TkTextPrintDLines(listFactoryPtr, linePtrs + n, 1);
	listFactoryPtr = ListFactoryEndLevel(listFactoryPtr);
      }
    }
  }
  if ((count == countTarget) && (count >= min)) {
    return;
  }

 addPrint:

  if (n > linesLeft) {
    n = linesLeft;
  }
  do {
    /* Need to print additional (empty?) blocks, probably wrapped. */
    listFactoryPtr = ListFactoryNewLevel(listFactoryPtr);
    TkTextPrintDLines(listFactoryPtr, linePtrs + n,
		      (nodePtr->numLines > linesLeft) 
		      ? linesLeft - n
		      : nodePtr->numLines - n);
    listFactoryPtr = ListFactoryEndLevel(listFactoryPtr);
    n = (nodePtr->numLines > linesLeft) ? linesLeft : nodePtr->numLines;
  } while (count < --min);		/* Hack to cover both under-
					 * and overflow. */
}
/*
 *------------------------------------------------------------------
 *
 * NodeReport
 * 	Given an node and a DString, fills it with information on
 * length of lines in the node.
 *
 * Returns:
 * 	None
 * 
 * Side effects:
 * 	Dynamic string grows.
 *
 *------------------------------------------------------------------
 */
void
NodeReport(nodePtr, listFactoryPtr, linesLeft)
     Node *nodePtr;			/* Node to describe. */
     ListFactory *listFactoryPtr;	/* DString to fill. */
     int linesLeft;			/* How many lines to print yet. */
{
  int n = 0;
  Arg arg = NULL;

  listFactoryPtr = ListFactoryNewLevel(listFactoryPtr);
  if (nodePtr->level) {
    Node *intPtr = nodePtr->children.nodePtr;

    while (intPtr) {
      NodeReport(intPtr, listFactoryPtr, linesLeft - n);
      n += intPtr->numLines;
      intPtr = intPtr->nextPtr;
    }
  } else {
    TkTextLine *linePtr = nodePtr->children.linePtr;
    for (; n < nodePtr->numLines; n++, linePtr = linePtr->nextPtr) { 
      /* One dummy line per IBTree! */
      if (n == linesLeft) {
	break;
      }
      LangSetInt(&arg, TkTextLineNumChars(linePtr) - 1); /* Characters, not
							  * counting the newline. */
      ListFactoryAppendCopy(listFactoryPtr, arg);
    }
    LangFreeArg(arg, LANG_DYNAMIC);
  }
  listFactoryPtr = ListFactoryEndLevel(listFactoryPtr);
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreePrint
 * 	Given an IBTree segment and an array of pointers, calls the
 * report procedure on the lines in the segment, grouping the results
 * in sublists according to tree structure.
 *
 * Returns:
 * 	None
 * 
 * Side effects:
 * 	Dynamic string grows.
 *
 *------------------------------------------------------------------
 */
void
TkIBTreePrint(segPtr, listFactoryPtr, linePtrs)
     TkTextSegment *segPtr;		/* IBTree segment to describe. */
     ListFactory *listFactoryPtr;	/* DString to fill. */
     void **linePtrs;			/* Pointers to DLines. */
{
  Node *nodePtr;
  TkTextBlock *blockPtr = segPtr->body.itree.blockPtr;
  int level = 0, count;

  if (!segPtr->body.itree.tree) {
    return;
  }
  nodePtr = ((BTree*)segPtr->body.itree.tree)->rootPtr;
  if (blockPtr->depth && (blockPtr->depth > (level = nodePtr->level + 1))) {
    for (count = level; count < blockPtr->depth; count++) {
      listFactoryPtr = ListFactoryNewLevel(listFactoryPtr);
    }
  }
  NodePrint(nodePtr, listFactoryPtr, (struct DLine**)linePtrs, 
	    nodePtr->numLines - 1,
	    blockPtr->depth && (blockPtr->depth > level)
		      ? level
		      : blockPtr->depth, 
	    blockPtr->widthsMin, blockPtr->widthsMax, blockPtr->widthsNum);
  if (blockPtr->depth && (blockPtr->depth > level)) {
    for (count = level; count < blockPtr->depth; count++) {
      listFactoryPtr = ListFactoryEndLevel(listFactoryPtr);
    }
  }
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeAt
 * 	Given an index determines whether it corresponds to IBTree,
 * and the enclosing IBTree.
 *
 * Returns:
 * 	Pointer to IBTree segment that encloses the index or NULL if
 * 	there is no such segment. If inside is true, the segment
 *	should start before the specified location. Otherwise it
 *	should start at the location.
 * 
 * Side effects:
 * 	None.
 *
 *------------------------------------------------------------------
 */
TkTextSegment *
TkIBTreeAt(indexPtr, inside)
     TkTextIndex *indexPtr;		/* IBTree segment to describe. */
     int inside;			/* Whether we do not want to report
					 * only segments starting at
					 * exactly the location. */
{
  int offset;
  TkTextIndex index;
  TkTextSegment *segPtr = TkTextIndexToInternalSeg(indexPtr, &index, &offset);

  if (!inside) {
    if ((offset != 0) || segPtr->typePtr != &tkTextIBTreeType) {
      return NULL;
    } else {
      return segPtr;
    }
  } else {
    return index.linePtr->parentPtr->segPtr;
  }
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeStartIndex
 * 	Given an IBTree segment, compute the external index of its
 *	start (the position of its head).
 *
 * Returns:
 *	None.
 *
 * Side effects:
 *	*indexPtr is filled; its tree field is set to the given tree.
 *
 *------------------------------------------------------------------
 */
void
TkIBTreeStartIndex(tree, segPtr, indexPtr)
     TkTextBTree tree;			/* The outermost tree, for the
					 * result (may be NULL). */
     TkTextSegment *segPtr;		/* IBTree segment. */
     TkTextIndex *indexPtr;		/* Filled with the index of the
					 * start of the block. */
{
  TkTextLine *linePtr = segPtr->body.itree.linePtr;
  TkTextSegment *prevPtr;

  indexPtr->tree = tree;
  indexPtr->byteIndex = 0;
  indexPtr->linePtr = linePtr;
  for (prevPtr = linePtr->segPtr; segPtr != prevPtr;
       prevPtr = prevPtr->nextPtr) {
    indexPtr->byteIndex += prevPtr->size;
  }
  TkTextIndexToExternalIndex(tree, indexPtr, indexPtr);
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeCutRange
 * 	A deletion whose ends are not inside the same block (or both
 *	outside blocks) cuts every block that contains only one of
 *	them, and the widget dissolves a cut block: what is left of
 *	its contents merges into the enclosing environment, its head
 *	and its tail disappear (TkBTreeDeleteChars; "Deletion of text
 *	in blocks" in the documentation).  This procedure finds the
 *	cut blocks before such a deletion and describes what it will
 *	do to them, so that the deletion can be undone.
 *
 * Returns:
 *	The number of blocks the range cuts.  If it is not 0, *ext1Ptr
 *	and *ext2Ptr are filled with the smallest range containing the
 *	given one that cuts no block (from the head of the outermost
 *	block cut at index1 to just after the tail of the outermost
 *	block cut at index2), and *remainsPtr with the size, in index
 *	space, of what the deletion leaves of the cut blocks: their
 *	contents outside the range, less their heads and tails.  After
 *	the deletion these remains start at the position of *ext1Ptr.
 *
 * Side effects:
 *	None.
 *
 *------------------------------------------------------------------
 */
int
TkIBTreeCutRange(index1Ptr, index2Ptr, ext1Ptr, ext2Ptr, remainsPtr)
     TkTextIndex *index1Ptr;		/* Start of the deletion. */
     TkTextIndex *index2Ptr;		/* End of the deletion (not
					 * included). */
     TkTextIndex *ext1Ptr;		/* Filled with the start of the
					 * enclosing range that cuts no
					 * block. */
     TkTextIndex *ext2Ptr;		/* Filled with its end. */
     int *remainsPtr;			/* Filled with the size of the
					 * remains of the cut blocks. */
{
  TkTextSegment *segPtr, *otherPtr, *outer1Ptr = NULL, *outer2Ptr = NULL;
  int cut1 = 0, cut2 = 0;

  /*
   * Go outward from each end through the blocks containing it, up to
   * the innermost block that contains the other end as well (or to
   * the top): the blocks passed on the way are cut.
   */

  for (segPtr = TkIBTreeAt(index1Ptr, 1); segPtr != NULL;
       segPtr = segPtr->body.itree.linePtr->parentPtr->segPtr) {
    for (otherPtr = TkIBTreeAt(index2Ptr, 1); otherPtr != NULL;
	 otherPtr = otherPtr->body.itree.linePtr->parentPtr->segPtr) {
      if (otherPtr == segPtr) {
	break;
      }
    }
    if (otherPtr != NULL) {
      break;
    }
    outer1Ptr = segPtr;
    cut1++;
  }
  for (segPtr = TkIBTreeAt(index2Ptr, 1); segPtr != NULL;
       segPtr = segPtr->body.itree.linePtr->parentPtr->segPtr) {
    for (otherPtr = TkIBTreeAt(index1Ptr, 1); otherPtr != NULL;
	 otherPtr = otherPtr->body.itree.linePtr->parentPtr->segPtr) {
      if (otherPtr == segPtr) {
	break;
      }
    }
    if (otherPtr != NULL) {
      break;
    }
    outer2Ptr = segPtr;
    cut2++;
  }
  if (cut1 + cut2 == 0) {
    return 0;
  }

  /*
   * A cut block loses its head and its tail.  On the index1 side its
   * contents before index1 survive (less the heads of the cut blocks
   * nested there), on the index2 side its contents from index2 on
   * (less their tails).  The ends of the enclosing range are on the
   * same outer lines as the ends of the deletion.
   */

  if (outer1Ptr != NULL) {
    TkIBTreeStartIndex(index1Ptr->tree, outer1Ptr, ext1Ptr);
  } else {
    *ext1Ptr = *index1Ptr;
  }
  if (outer2Ptr != NULL) {
    TkIBTreeStartIndex(index2Ptr->tree, outer2Ptr, ext2Ptr);
    ext2Ptr->byteIndex += outer2Ptr->size;
  } else {
    *ext2Ptr = *index2Ptr;
  }
  *remainsPtr = (index1Ptr->byteIndex - ext1Ptr->byteIndex - cut1)
    + (ext2Ptr->byteIndex - index2Ptr->byteIndex - cut2);
  return cut1 + cut2;
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeInfo
 * 	Given an IBTree segment, print some useful information about it.
 *
 * Returns:
 *      None
 * 
 * Side effects:
 * 	Dynamic string grows.
 *
 *------------------------------------------------------------------
 */
void
TkIBTreeInfo(segPtr, listFactoryPtr)
     TkTextSegment *segPtr;		/* IBTree segment to describe. */
     ListFactory *listFactoryPtr;	/* String to fill with
					 * information. */
{
  TkTextIndex index;
  char buffer[32];
  Arg arg = NULL;

  TkIBTreeStartIndex(NULL, segPtr, &index);
  TkTextPrintIndex(&index, buffer);
  LangSetString(&arg, buffer);
  ListFactoryAppendCopy(listFactoryPtr, arg);
  LangSetInt(&arg, TkTextSegNumChars(segPtr, segPtr->size)); /* Length in
								  * characters. */
  ListFactoryAppendCopy(listFactoryPtr, arg);
  LangSetString(&arg, segPtr->body.itree.blockPtr->name);
  ListFactoryAppendCopy(listFactoryPtr, arg);
  if (TkTextDataGetLang(segPtr->body.itree.data) != NULL) {
    ListFactoryAppendCopy(listFactoryPtr,
	    TkTextDataGetLang(segPtr->body.itree.data));
  } else {
    LangSetDefault(&arg, "");
    ListFactoryAppendCopy(listFactoryPtr, arg);
  }
  LangFreeArg(arg, LANG_DYNAMIC);
  if (segPtr->body.itree.tree) {
    NodeReport(((BTree *) segPtr->body.itree.tree)->rootPtr, listFactoryPtr,
	       ((BTree *) segPtr->body.itree.tree)->rootPtr->numLines - 1);
  }
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeSplit
 * 	Given an IBTree segment, splits the tree on the given level,
 *	counting from leaves on level 0.
 *
 * Returns:
 *      0 on success, -1 if point not in IBTree, >0 if IBTree is too
 * 	shallow (the tree is split on the topmost level).
 * 
 * Side effects:
 * 	IBTree structure can change, internal line is split.
 * 
 *------------------------------------------------------------------
 */
int
TkIBTreeSplit(indexPtr, level)
     TkTextIndex *indexPtr;	/* IBTree segment to split. */
     int level;			/* Level to split. */
{
  TkTextSegment *segPtr = TkIBTreeAt(indexPtr,1);
  TkTextIndex index;
  register Node *newPtr, *childPtr = NULL;
  register TkTextLine *linePtr;
  Node *nodePtr;
  int depth = 0;

  TkBTreeInsertChars(indexPtr, "\n");
  if (!segPtr) {
    return -1;
  }
  if (level <= 0) {
    return 0;
  }
  TkTextIndexToInternalSeg(indexPtr, &index, NULL);
  linePtr = index.linePtr;
  nodePtr = linePtr->parentPtr;

  while (level--) {
    /*
     * 		 If the node being split is the root node, then make a
     * 		 new root node above it first.
     */
    
    if (nodePtr->parentPtr == NULL) {
      newPtr = (Node *) ckalloc(sizeof(Node));
      newPtr->parentPtr = NULL;
      newPtr->nextPtr = NULL;
      newPtr->summaryPtr = NULL;
      newPtr->level = nodePtr->level + 1;
      newPtr->children.nodePtr = nodePtr;
      newPtr->numChildren = 1;
      newPtr->numLines = nodePtr->numLines;
      newPtr->segPtr = nodePtr->segPtr;
      /*
       * The root's value moves to the new root, so that level -1
       * keeps naming it.
       */
      TkTextDataInit(newPtr->value);
      TkTextDataMove(&newPtr->value, &nodePtr->value);
      RecomputeNodeCounts(newPtr);
      ((BTree*)index.tree)->rootPtr = newPtr;
      depth++;
    }
    newPtr = (Node *) ckalloc(sizeof(Node));
    newPtr->parentPtr = nodePtr->parentPtr;
    newPtr->nextPtr = nodePtr->nextPtr;
    nodePtr->nextPtr = newPtr;
    newPtr->summaryPtr = NULL;
    newPtr->level = nodePtr->level;
    newPtr->segPtr = nodePtr->segPtr;
    TkTextDataInit(newPtr->value);	/* The part after the cut starts
					 * without a value. */
    if (nodePtr->level == 0) {
      newPtr->children.linePtr = linePtr->nextPtr;
      linePtr->nextPtr = NULL;
    } else {
      newPtr->children.nodePtr = childPtr->nextPtr;
      childPtr->nextPtr = NULL;
    }
    childPtr = nodePtr;
    RecomputeNodeCounts(nodePtr);
    nodePtr->parentPtr->numChildren++;
    RecomputeNodeCounts(newPtr);
    nodePtr = nodePtr->parentPtr;
  }
  return depth;
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeDeepen --
 *	Add nodes above the root of a block's tree, each with one child
 *	(the old root), until the root is at a given level.  Re-creating
 *	a block from its list needs this: the separators give the shape
 *	of the tree below the level where all the leaves meet, but not a
 *	root with a single child; the depth in the header does.
 *
 * Returns:
 * 	None.
 *
 * Side effects:
 * 	The tree changes; the root's value moves to the new root (as in
 *	TkIBTreeSplit), so that level -1 keeps naming it.
 *
 *------------------------------------------------------------------
 */

void
TkIBTreeDeepen(segPtr, depth)
     TkTextSegment *segPtr;		/* The block. */
     int depth;				/* The level its root should have. */
{
  BTree *treePtr = (BTree *) segPtr->body.itree.tree;
  Node *nodePtr, *newPtr;

  if (treePtr == NULL) {
    return;
  }
  while ((nodePtr = treePtr->rootPtr)->level < depth) {
    newPtr = (Node *) ckalloc(sizeof(Node));
    newPtr->parentPtr = NULL;
    newPtr->nextPtr = NULL;
    newPtr->summaryPtr = NULL;
    newPtr->level = nodePtr->level + 1;
    newPtr->children.nodePtr = nodePtr;
    newPtr->numChildren = 1;
    newPtr->numLines = nodePtr->numLines;
    newPtr->segPtr = nodePtr->segPtr;
    TkTextDataInit(newPtr->value);
    TkTextDataMove(&newPtr->value, &nodePtr->value);
    RecomputeNodeCounts(newPtr);
    treePtr->rootPtr = newPtr;
  }
}

/*
 * Whether the root of a block's tree has a value (block trim records
 * it for its undo).
 */

int
TkIBTreeRootHasValue(segPtr)
     TkTextSegment *segPtr;		/* The block. */
{
  BTree *treePtr = (BTree *) segPtr->body.itree.tree;

  return (treePtr != NULL) && !TkTextDataIsEmpty(treePtr->rootPtr->value);
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeAddRoot --
 *	Add a node above the root of a block's tree, with the old root
 *	as its only child: the inverse of TkIBTreeTrim, for its undo.
 *	The old root's value moves up to the new root if moveValue is
 *	set (the root had a value before the trim, which the trim gave
 *	to the node that became the root); else the new root starts
 *	without one.
 *
 * Returns:
 * 	None.
 *
 * Side effects:
 * 	The tree is one level deeper.
 *
 *------------------------------------------------------------------
 */

void
TkIBTreeAddRoot(segPtr, moveValue)
     TkTextSegment *segPtr;		/* The block. */
     int moveValue;			/* See above. */
{
  BTree *treePtr = (BTree *) segPtr->body.itree.tree;
  Node *nodePtr, *newPtr;

  if (treePtr == NULL) {
    return;
  }
  nodePtr = treePtr->rootPtr;
  newPtr = (Node *) ckalloc(sizeof(Node));
  newPtr->parentPtr = NULL;
  newPtr->nextPtr = NULL;
  newPtr->summaryPtr = NULL;
  newPtr->level = nodePtr->level + 1;
  newPtr->children.nodePtr = nodePtr;
  newPtr->numChildren = 1;
  newPtr->numLines = nodePtr->numLines;
  newPtr->segPtr = nodePtr->segPtr;
  TkTextDataInit(newPtr->value);
  if (moveValue) {
    TkTextDataMove(&newPtr->value, &nodePtr->value);
  }
  nodePtr->parentPtr = newPtr;
  RecomputeNodeCounts(newPtr);
  treePtr->rootPtr = newPtr;
}

/*
 *------------------------------------------------------------------
 *
 * TkBTreeTakeMovedLeafValues --
 *	Before the undo of "block insert" dissolves the block it made:
 *	take off the values of the leaves that block insert moved whole
 *	into the block from the enclosing block (the leaves between the
 *	first and the last; the first if nothing is before the block in
 *	its line, the last if nothing but the newline is after it), and
 *	return them as records (TK_TEXT_VALUE_NODE) with the addresses
 *	of the same leaves once the block is dissolved: their start less
 *	the head.  The dissolution would drop them as values of the
 *	block's leaves; they are values of the enclosing block's.
 *	Nothing is taken from a block outside blocks (lines there have
 *	no values) or with a single leaf (block insert moved part of one
 *	leaf).
 *
 * Returns:
 * 	The records (most recent first), or NULL.
 *
 * Side effects:
 * 	The values are taken off the leaves.
 *
 *------------------------------------------------------------------
 */

TkTextValue *
TkBTreeTakeMovedLeafValues(textPtr, segPtr, headPtr)
     TkText *textPtr;			/* The widget. */
     TkTextSegment *segPtr;		/* The block. */
     TkTextIndex *headPtr;		/* The (external) index of its head. */
{
  TkTextLine *outLinePtr = segPtr->body.itree.linePtr, *linePtr, *nextPtr;
  TkTextSegment *p;
  TkTextValue *listPtr = NULL, *recPtr;
  int before = 0, after = 0, k, line, pos;

  if ((segPtr->body.itree.tree == NULL)
      || (outLinePtr->parentPtr->segPtr == NULL)) {
    return NULL;
  }
  for (p = outLinePtr->segPtr; p != segPtr; p = p->nextPtr) {
    before += p->size;
  }
  for (p = segPtr->nextPtr; p != NULL; p = p->nextPtr) {
    after += p->size;
  }
  line = TkBTreeLineIndex(headPtr->linePtr);
  pos = headPtr->byteIndex + 1;		/* The first leaf, inside. */
  linePtr = TkBTreeFindLine(segPtr->body.itree.tree, 0);
  for (k = 0; (linePtr != NULL) && !IsLastLine(linePtr); k++) {
    nextPtr = TkBTreeNextLine(linePtr);
    if (!TkTextDataIsEmpty(linePtr->value)
	&& ((nextPtr == NULL) || !IsLastLine(nextPtr) || (k > 0))
	&& ((k > 0) || (before == 0))
	&& ((nextPtr == NULL) || !IsLastLine(nextPtr) || (after <= 1))) {
      recPtr = NewValueRecord(TK_TEXT_VALUE_NODE, linePtr->value);
      TkTextDataInit(linePtr->value);	/* The record took it. */
      recPtr->line = line;
      recPtr->byteIndex = pos - 1;
      recPtr->level = 0;
      recPtr->nextPtr = listPtr;
      listPtr = recPtr;
    }
    pos += TkBTreeCharsInLine(linePtr);
    linePtr = nextPtr;
  }
  return listPtr;
}

/*
 *----------------------------------------
 *
 * TkIBTreeTrim
 * 	Given an IBTree segment with root having one child, makes this
 *	child a root.
 *
 * Returns:
 *	None.
 * 
 * Side effects:
 * 	IBTree structure changes.
 *
 *----------------------------------------
 */

int
TkIBTreeTrim(textPtr, segPtr)
     TkText *textPtr;			/* Widget to use. */
     TkTextSegment *segPtr;		/* IBTree segment to split. */
{
  Node *rootPtr = ((BTree*)segPtr->body.itree.tree)->rootPtr;
  char *errString;

  if (segPtr->typePtr != &tkTextIBTreeType) {
    errString = "TkIBTreeTrim: not an IBTree.";
    goto error;
  }
  if (rootPtr->level < 1) {
    errString = "TkIBTreeTrim: IBTree is too shallow.";
    goto error;
  }
  if (rootPtr->numChildren > 1) {
    errString = "TkIBTreeTrim: too many children of root.";
    goto error;
  }

  /*
   * The root and its only child become one node (the merge policy,
   * TkTextDataMerge: the root's data, if any, wins, so that level -1
   * keeps naming it), which is the child.
   */

  {
    Node *childPtr = rootPtr->children.nodePtr;

    if (TkTextDataMerge(&rootPtr->value, &childPtr->value)
	    == TK_TEXT_DATA_MERGE_DROP) {
      DropValue(textPtr, (void *) childPtr, &childPtr->value);
    }
    TkTextDataMove(&childPtr->value, &rootPtr->value);
  }
  ((BTree*)segPtr->body.itree.tree)->rootPtr = rootPtr->children.nodePtr;
  rootPtr->children.nodePtr->parentPtr = NULL;
  DeleteSummaries(rootPtr->summaryPtr);
  ckfree((char*)rootPtr);
  return TCL_OK;

 error:
  Tcl_AppendResult(textPtr->interp, errString,          NULL);
  return TCL_ERROR;
}

TkTextSegment *		
TkIBTreeNode2seg(nodePtr, linePtrPtr)
    struct Node *nodePtr;
    TkTextLine **linePtrPtr;
{
    if (linePtrPtr && nodePtr->segPtr) {
	*linePtrPtr = nodePtr->segPtr->body.itree.linePtr;
    }
    return nodePtr->segPtr;
}

TkTextLine *		
TkIBTreeFirstLine(segPtr)
    TkTextSegment *segPtr;
{
    Node *nodePtr = ((BTree*)segPtr->body.itree.tree)->rootPtr;
    while (nodePtr->level > 0) {
	nodePtr = nodePtr->children.nodePtr;
    }
    return nodePtr->children.linePtr;
}

TkTextLine *		
TkIBTreeLastLine(segPtr)
    TkTextSegment *segPtr;
{
    Node *nodePtr = ((BTree*)segPtr->body.itree.tree)->rootPtr;
    while (nodePtr->level > 0) {
	nodePtr = nodePtr->children.nodePtr;
    }
    return nodePtr->children.linePtr;
}


/*
 *======================================================================
 *
 * Values of block nodes ("block nodedata").
 *
 *	Every node of a block's tree, the leaves (lines) included, can
 *	hold a value: a copy of a Perl scalar.  A value leaves its node
 *	when the node disappears, when two nodes are merged (the merged
 *	node keeps the first value present), when it is replaced, and
 *	when the widget goes.  Such a value is never freed here: it is
 *	handed to DropValue, which records it in the undo atom of the
 *	deletion going on (if the deletion can be undone) or puts it on
 *	the widget's list of values to free when the widget command is
 *	finished (see TkTextValue in tkText.h).
 *
 *======================================================================
 */

/*
 * The widget a node of a block belongs to (NULL in the outermost
 * tree, whose nodes and lines never have values).
 */

static TkText *
NodeText(nodePtr)
    Node *nodePtr;
{
    if ((nodePtr == NULL) || (nodePtr->segPtr == NULL)
	    || (nodePtr->segPtr->body.itree.tree == NULL)) {
	return NULL;
    }
    return ((BTree *) nodePtr->segPtr->body.itree.tree)->textPtr;
}

static TkTextValue *
NewValueRecord(kind, value)
    int kind;
    TkTextData value;			/* Consumed (may be empty). */
{
    TkTextValue *recPtr = (TkTextValue *) ckalloc(sizeof(TkTextValue));

    recPtr->kind = kind;
    recPtr->line = recPtr->byteIndex = recPtr->level = -1;
    recPtr->srcLine = recPtr->srcByteIndex = recPtr->srcLevel = -1;
    recPtr->name = NULL;
    recPtr->value = value;
    recPtr->nextPtr = NULL;
    return recPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextFreeValueLater, TkTextFreeValueList, TkTextReleaseValues --
 *
 *	Put a container, or the containers of a list of records (which
 *	are consumed), on the widget's list of values to free at the end
 *	of the widget command; free a list of records and their
 *	containers now (the caller has taken it from the widget): the
 *	only place, with the teardown of the widget, where values are
 *	freed (TkTextDataFree).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	TkTextReleaseValues may run Perl code (DESTROY methods).
 *
 *----------------------------------------------------------------------
 */

static void		FreeLater _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value));

void
TkTextFreeValueLater(textPtr, value)
    TkText *textPtr;			/* The widget, or NULL. */
    TkTextData value;			/* The container; owned by the list
					 * from now on (nothing if empty). */
{
    TkTextVcSeen(textPtr, value, TK_TEXT_VC_DROP);
    FreeLater(textPtr, value);
}

static void
FreeLater(textPtr, value)
    TkText *textPtr;			/* The widget, or NULL. */
    TkTextData value;			/* The container; owned by the list
					 * from now on (nothing if empty). */
{
    TkTextValue *recPtr;

    if (TkTextDataIsEmpty(value)) {
	return;
    }
    recPtr = NewValueRecord(0, value);
    if (textPtr == NULL) {
	TkTextReleaseValues(recPtr);
	return;
    }
    if (textPtr->freeValues == NULL) {
	textPtr->freeValues = recPtr;
    } else {
	textPtr->lastFreeValue->nextPtr = recPtr;
    }
    textPtr->lastFreeValue = recPtr;
}

void
TkTextFreeValueList(textPtr, listPtr)
    TkText *textPtr;			/* The widget, or NULL. */
    TkTextValue *listPtr;		/* The records. */
{
    TkTextValue *nextPtr;

    for ( ; listPtr != NULL; listPtr = nextPtr) {
	nextPtr = listPtr->nextPtr;
	TkTextFreeValueLater(textPtr, listPtr->value);
	if (listPtr->name != NULL) {
	    ckfree(listPtr->name);
	}
	ckfree((char *) listPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextDiscardValue, TkTextDiscardValueList --
 *
 *	TkTextFreeValueLater, TkTextFreeValueList for values that an undo
 *	step held and that leave it without going back into the text:
 *	the step is discarded (edit reset, -maxundo, a new change
 *	dropping the steps that could be redone), or the undo or the redo
 *	finds no place for them.  With a -valuecommand, each is reported
 *	("discard") at the end of the widget command, with the place
 *	recorded in the step.
 *
 *----------------------------------------------------------------------
 */

void
TkTextDiscardValue(textPtr, value, kind, line, byteIndex, level, name)
    TkText *textPtr;			/* The widget, or NULL. */
    TkTextData value;			/* The container (consumed). */
    int kind;				/* TK_TEXT_VALUE_NODE, _RUN or _BLOCK
					 * (the record's kind). */
    int line, byteIndex, level;		/* The recorded place. */
    char *name;				/* For a run: the tag's name. */
{
    if (TkTextVcOn(textPtr) && (TkTextDataGetLang(value) != NULL)) {
	Tcl_Obj *where = NULL;
	int vcKind = 0;

	if (kind == TK_TEXT_VALUE_NODE) {
	    vcKind = TK_TEXT_VC_NODE;
	    where = TkTextVcNodePlace(textPtr, line, byteIndex, level);
	} else if (kind == TK_TEXT_VALUE_BLOCK) {
	    vcKind = TK_TEXT_VC_BLOCK;
	    where = TkTextVcBlockPlace(textPtr, line, byteIndex);
	} else if (kind == TK_TEXT_VALUE_RUN) {
	    TkTextIndex start;

	    vcKind = TK_TEXT_VC_RUN;
	    if ((line >= 0) && (line < TkBTreeNumLines(textPtr->tree))) {
		TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &start);
		where = TkTextVcRunPlace(textPtr, name, &start,
			(TkTextIndex *) NULL);
	    }
	}
	TkTextVcDiscarded(textPtr, value, vcKind, where);
    }
    FreeLater(textPtr, value);
}

void
TkTextDiscardValueAt(textPtr, value, vcKind, where)
    TkText *textPtr;			/* The widget, or NULL. */
    TkTextData value;			/* The container (consumed). */
    int vcKind;				/* TK_TEXT_VC_NODE... */
    Tcl_Obj *where;			/* The place as the callback gets it
					 * (consumed), or NULL. */
{
    TkTextVcDiscarded(textPtr, value, vcKind, where);
    FreeLater(textPtr, value);
}

void
TkTextDiscardValueList(textPtr, listPtr)
    TkText *textPtr;			/* The widget, or NULL. */
    TkTextValue *listPtr;		/* The records (consumed). */
{
    TkTextValue *nextPtr;

    for ( ; listPtr != NULL; listPtr = nextPtr) {
	nextPtr = listPtr->nextPtr;
	TkTextDiscardValue(textPtr, listPtr->value, listPtr->kind,
		listPtr->line, listPtr->byteIndex, listPtr->level,
		listPtr->name);
	if (listPtr->name != NULL) {
	    ckfree(listPtr->name);
	}
	ckfree((char *) listPtr);
    }
}

void
TkTextReleaseValues(listPtr)
    TkTextValue *listPtr;		/* The records. */
{
    TkTextValue *nextPtr;

    for ( ; listPtr != NULL; listPtr = nextPtr) {
	nextPtr = listPtr->nextPtr;
	TkTextDataFree(listPtr->value);
	if (listPtr->name != NULL) {
	    ckfree(listPtr->name);
	}
	ckfree((char *) listPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DropValue --
 *
 *	A node (or a line) loses its value: record it in the undo atom
 *	of the deletion going on, with the node's address as the
 *	deletion found it, or else have it freed at the end of the
 *	widget command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	*valuePtr is set to NULL.
 *
 *----------------------------------------------------------------------
 */

static void
DropValue(textPtr, objPtr, valuePtr)
    TkText *textPtr;			/* The widget. */
    void *objPtr;			/* The Node or the TkTextLine. */
    TkTextData *valuePtr;		/* Where its data is. */
{
    TkTextData value;
    Tcl_HashEntry *hPtr;

    if (TkTextDataIsEmpty(*valuePtr)) {
	return;
    }
    TkTextDataInit(value);
    TkTextDataMove(&value, valuePtr);
    if ((textPtr != NULL) && (textPtr->valueCapture != NULL)
	    && (textPtr->valueAddresses != NULL)
	    && ((hPtr = Tcl_FindHashEntry(textPtr->valueAddresses,
		    (char *) objPtr)) != NULL)) {
	ValueAddress *addrPtr = (ValueAddress *) Tcl_GetHashValue(hPtr);
	TkTextValue *recPtr;

	TkTextVcSeen(textPtr, value, TK_TEXT_VC_STASH);
	recPtr = NewValueRecord(TK_TEXT_VALUE_NODE, value);
	recPtr->line = addrPtr->line;
	recPtr->byteIndex = addrPtr->byteIndex;
	recPtr->level = addrPtr->level;
	recPtr->nextPtr = *textPtr->valueCapture;
	*textPtr->valueCapture = recPtr;
	return;
    }
    TkTextFreeValueLater(textPtr, value);
}

/*
 *----------------------------------------------------------------------
 *
 * DropBlockData --
 *
 *	A block that a deletion deletes or dissolves loses its instance
 *	data: record the whole container in the undo atom of the
 *	deletion going on (TK_TEXT_VALUE_BLOCK), with the address of
 *	the block's head as the deletion found it, or else have it freed
 *	at the end of the widget command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The segment's data is emptied.
 *
 *----------------------------------------------------------------------
 */

static void
DropBlockData(segPtr)
    TkTextSegment *segPtr;		/* The block. */
{
    TkText *textPtr = segPtr->body.itree.blockPtr->textPtr;
    TkTextData value;
    Tcl_HashEntry *hPtr;

    if (TkTextDataIsEmpty(segPtr->body.itree.data)) {
	return;
    }
    TkTextDataInit(value);
    TkTextDataMove(&value, &segPtr->body.itree.data);
    if ((textPtr != NULL) && (textPtr->valueCapture != NULL)
	    && (textPtr->valueAddresses != NULL)
	    && ((hPtr = Tcl_FindHashEntry(textPtr->valueAddresses,
		    (char *) segPtr)) != NULL)) {
	ValueAddress *addrPtr = (ValueAddress *) Tcl_GetHashValue(hPtr);
	TkTextValue *recPtr;

	TkTextVcSeen(textPtr, value, TK_TEXT_VC_STASH);
	recPtr = NewValueRecord(TK_TEXT_VALUE_BLOCK, value);

	recPtr->line = addrPtr->line;
	recPtr->byteIndex = addrPtr->byteIndex;
	recPtr->nextPtr = *textPtr->valueCapture;
	*textPtr->valueCapture = recPtr;
	return;
    }
    TkTextFreeValueLater(textPtr, value);
}

/*
 *----------------------------------------------------------------------
 *
 * MergeValues --
 *
 *	Two nodes (or lines) become one, the first one surviving.  The
 *	merge policy (TkTextDataMerge) decides: today it keeps the data
 *	of the first if it has any, else it takes the data of the
 *	second; the other is dropped (N5).  Data that moves is recorded
 *	as moving in the undo atom of the deletion going on.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	*losePtr is set to NULL.
 *
 *----------------------------------------------------------------------
 */

static void
MergeValues(textPtr, keepObjPtr, keepPtr, loseObjPtr, losePtr)
    TkText *textPtr;			/* The widget. */
    void *keepObjPtr;			/* The surviving node. */
    TkTextData *keepPtr;		/* Where its data is. */
    void *loseObjPtr;			/* The node that disappears. */
    TkTextData *losePtr;		/* Where its data is. */
{
    Tcl_HashEntry *keepEntry, *loseEntry;

    switch (TkTextDataMerge(keepPtr, losePtr)) {
    case TK_TEXT_DATA_MERGE_NONE:
	return;
    case TK_TEXT_DATA_MERGE_DROP:
	DropValue(textPtr, loseObjPtr, losePtr);
	return;
    }
    TkTextVcSeen(textPtr, *keepPtr, TK_TEXT_VC_MOVE);
    if ((textPtr != NULL) && (textPtr->valueCapture != NULL)
	    && (textPtr->valueAddresses != NULL)
	    && ((keepEntry = Tcl_FindHashEntry(textPtr->valueAddresses,
		    (char *) keepObjPtr)) != NULL)
	    && ((loseEntry = Tcl_FindHashEntry(textPtr->valueAddresses,
		    (char *) loseObjPtr)) != NULL)) {
	ValueAddress *keepAddr = (ValueAddress *) Tcl_GetHashValue(keepEntry);
	ValueAddress *loseAddr = (ValueAddress *) Tcl_GetHashValue(loseEntry);
	TkTextData none;
	TkTextValue *recPtr;

	TkTextDataInit(none);
	recPtr = NewValueRecord(TK_TEXT_VALUE_MOVE, none);

	recPtr->line = loseAddr->line;
	recPtr->byteIndex = loseAddr->byteIndex;
	recPtr->level = loseAddr->level;
	recPtr->srcLine = keepAddr->line;
	recPtr->srcByteIndex = keepAddr->byteIndex;
	recPtr->srcLevel = keepAddr->level;
	recPtr->nextPtr = *textPtr->valueCapture;
	*textPtr->valueCapture = recPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DropTreeValues --
 *
 *	Drop the values of a node and of everything below it.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See DropValue.
 *
 *----------------------------------------------------------------------
 */

static void
DropTreeValues(textPtr, nodePtr)
    TkText *textPtr;			/* The widget. */
    Node *nodePtr;			/* The (sub)tree. */
{
    DropValue(textPtr, (void *) nodePtr, &nodePtr->value);
    if (nodePtr->level == 0) {
	TkTextLine *linePtr;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    DropValue(textPtr, (void *) linePtr, &linePtr->value);
	}
    } else {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    DropTreeValues(textPtr, childPtr);
	}
    }
}

/*
 * Whether a line is the last one of its tree (the dummy line of a
 * block's tree, which is not a leaf for the user).
 */

static int
IsLastLine(linePtr)
    TkTextLine *linePtr;
{
    Node *nodePtr;

    if (linePtr->nextPtr != NULL) {
	return 0;
    }
    for (nodePtr = linePtr->parentPtr; nodePtr != NULL;
	 nodePtr = nodePtr->parentPtr) {
	if (nodePtr->nextPtr != NULL) {
	    return 0;
	}
    }
    return 1;
}

/*
 *----------------------------------------------------------------------
 *
 * UnlinkLine --
 *
 *	Take a line out of its node in a block's tree (TkBTreeMakeBlock
 *	moves it elsewhere).  A node left without children disappears,
 *	with its value, and so on upwards.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Line and child counts change; nodes may be freed.
 *
 *----------------------------------------------------------------------
 */

static void
UnlinkLine(textPtr, linePtr, prevHintPtr)
    TkText *textPtr;			/* The widget. */
    TkTextLine *linePtr;		/* The line. */
    TkTextLine *prevHintPtr;		/* The line likely to be before it
					 * in its node (block insert moves
					 * the lines after one line, in
					 * order: then no scan is needed),
					 * or NULL. */
{
    Node *nodePtr = linePtr->parentPtr, *parentPtr, *prevNodePtr;

    if (nodePtr->children.linePtr == linePtr) {
	nodePtr->children.linePtr = linePtr->nextPtr;
    } else if ((prevHintPtr != NULL) && (prevHintPtr->nextPtr == linePtr)) {
	prevHintPtr->nextPtr = linePtr->nextPtr;
    } else {
	TkTextLine *prevPtr = nodePtr->children.linePtr;

	while (prevPtr->nextPtr != linePtr) {
	    prevPtr = prevPtr->nextPtr;
	}
	prevPtr->nextPtr = linePtr->nextPtr;
    }
    linePtr->nextPtr = NULL;
    nodePtr->numChildren--;
    for (parentPtr = nodePtr; parentPtr != NULL;
	 parentPtr = parentPtr->parentPtr) {
	parentPtr->numLines--;
    }
    while ((nodePtr->numChildren == 0) && (nodePtr->parentPtr != NULL)) {
	parentPtr = nodePtr->parentPtr;
	if (parentPtr->children.nodePtr == nodePtr) {
	    parentPtr->children.nodePtr = nodePtr->nextPtr;
	} else {
	    prevNodePtr = parentPtr->children.nodePtr;
	    while (prevNodePtr->nextPtr != nodePtr) {
		prevNodePtr = prevNodePtr->nextPtr;
	    }
	    prevNodePtr->nextPtr = nodePtr->nextPtr;
	}
	parentPtr->numChildren--;
	DropValue(textPtr, (void *) nodePtr, &nodePtr->value);
	DeleteSummaries(nodePtr->summaryPtr);
	ckfree((char *) nodePtr);
	nodePtr = parentPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeSnapshotValues --
 *
 *	Before a deletion that can be undone, record the addresses (see
 *	TkTextValue) of the nodes and leaves it may take values from:
 *	in every block the range overlaps (and the blocks nested in
 *	them that it overlaps), the nodes that have a value or whose
 *	text overlaps the range (the nodes a merge keeps); and the
 *	heads of those blocks (empty ones included) that have instance
 *	data, which the deletion drops if it deletes or dissolves them.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The table is initialized and filled (keys: the Node, the
 *	TkTextLine or, for a block's head, the TkTextSegment; values:
 *	malloc-ed ValueAddress records, of level -1 for a head), to be
 *	released with TkBTreeFreeSnapshot.
 *
 *----------------------------------------------------------------------
 */

#define OVERLAPS(start, end, lo, hi) (((end) > (lo)) && ((start) <= (hi)))

static void		SnapshotBlock _ANSI_ARGS_((Tcl_HashTable *tablePtr,
			    TkTextSegment *segPtr, int line, int start, int lo,
			    int hi));

static void
SnapshotRecord(tablePtr, objPtr, line, byteIndex, level)
    Tcl_HashTable *tablePtr;
    void *objPtr;
    int line, byteIndex, level;
{
    int new;
    Tcl_HashEntry *hPtr = Tcl_CreateHashEntry(tablePtr, (char *) objPtr, &new);
    ValueAddress *addrPtr;

    if (new) {
	addrPtr = (ValueAddress *) ckalloc(sizeof(ValueAddress));
	Tcl_SetHashValue(hPtr, addrPtr);
    } else {
	addrPtr = (ValueAddress *) Tcl_GetHashValue(hPtr);
    }
    addrPtr->line = line;
    addrPtr->byteIndex = byteIndex;
    addrPtr->level = level;
}

static int
SnapshotNode(tablePtr, nodePtr, line, pos, lo, hi)
    Tcl_HashTable *tablePtr;		/* The snapshot. */
    Node *nodePtr;			/* The node. */
    int line;				/* Its outer line. */
    int pos;				/* Where it starts in that line. */
    int lo, hi;				/* The deletion range in that line. */
{
    int start = pos, lineStart;

    if (nodePtr->level > 0) {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    pos = SnapshotNode(tablePtr, childPtr, line, pos, lo, hi);
	}
    } else {
	TkTextLine *linePtr;
	TkTextSegment *segPtr;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    lineStart = pos;
	    if (IsLastLine(linePtr)) {
		continue;		/* The dummy line, accounted for by
					 * the head of the block. */
	    }
	    for (segPtr = linePtr->segPtr; segPtr != NULL;
		 segPtr = segPtr->nextPtr) {
		if ((segPtr->typePtr == &tkTextIBTreeType)
			&& OVERLAPS(pos, pos + segPtr->size, lo, hi)) {
		    SnapshotBlock(tablePtr, segPtr, line, pos, lo, hi);
		}
		pos += segPtr->size;
	    }
	    if (!TkTextDataIsEmpty(linePtr->value)
		    || OVERLAPS(lineStart, pos, lo, hi)) {
		SnapshotRecord(tablePtr, (void *) linePtr, line, lineStart, 0);
	    }
	}
    }
    if (!TkTextDataIsEmpty(nodePtr->value) || OVERLAPS(start, pos, lo, hi)) {
	SnapshotRecord(tablePtr, (void *) nodePtr, line, start,
		nodePtr->level + 1);
    }
    return pos;
}

static void
SnapshotBlock(tablePtr, segPtr, line, start, lo, hi)
    Tcl_HashTable *tablePtr;		/* The snapshot. */
    TkTextSegment *segPtr;		/* The block (maybe an empty one). */
    int line;				/* Its outer line. */
    int start;				/* Its position (of its head). */
    int lo, hi;				/* The deletion range in that line. */
{
    if (!TkTextDataIsEmpty(segPtr->body.itree.data)) {
	SnapshotRecord(tablePtr, (void *) segPtr, line, start, -1);
    }
    if (segPtr->body.itree.tree != NULL) {
	SnapshotNode(tablePtr, ((BTree *) segPtr->body.itree.tree)->rootPtr,
		line, start + 1, lo, hi);
    }
}

void
TkBTreeSnapshotValues(textPtr, index1Ptr, index2Ptr, tablePtr)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *index1Ptr;		/* Start of the deletion (in the
					 * outermost tree). */
    TkTextIndex *index2Ptr;		/* Its end. */
    Tcl_HashTable *tablePtr;		/* The table to fill. */
{
    TkTextLine *linePtr;
    TkTextSegment *segPtr;
    int line, pos, lo, hi;

    Tcl_InitHashTable(tablePtr, TCL_ONE_WORD_KEYS);
    line = TkBTreeLineIndex(index1Ptr->linePtr);
    for (linePtr = index1Ptr->linePtr; linePtr != NULL;
	 linePtr = TkBTreeNextLine(linePtr), line++) {
	lo = (linePtr == index1Ptr->linePtr) ? index1Ptr->byteIndex : 0;
	hi = (linePtr == index2Ptr->linePtr) ? index2Ptr->byteIndex : INT_MAX;
	pos = 0;
	for (segPtr = linePtr->segPtr; segPtr != NULL;
	     segPtr = segPtr->nextPtr) {
	    if ((segPtr->typePtr == &tkTextIBTreeType)
		    && OVERLAPS(pos, pos + segPtr->size, lo, hi)) {
		SnapshotBlock(tablePtr, segPtr, line, pos, lo, hi);
	    }
	    pos += segPtr->size;
	}
	if (linePtr == index2Ptr->linePtr) {
	    break;
	}
    }
}

void
TkBTreeFreeSnapshot(tablePtr)
    Tcl_HashTable *tablePtr;		/* The table. */
{
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;

    for (hPtr = Tcl_FirstHashEntry(tablePtr, &search); hPtr != NULL;
	 hPtr = Tcl_NextHashEntry(&search)) {
	ckfree((char *) Tcl_GetHashValue(hPtr));
    }
    Tcl_DeleteHashTable(tablePtr);
}

/*
 *----------------------------------------------------------------------
 *
 * AddressValue --
 *
 *	Find the node at an address (see TkTextValue).
 *
 * Results:
 *	Where the node's data is kept, or NULL if there is no such
 *	node.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static TkTextData *
AddressValue(textPtr, line, byteIndex, level)
    TkText *textPtr;			/* The widget. */
    int line, byteIndex, level;		/* The address. */
{
    TkTextIndex index, intIndex;
    TkTextLine *linePtr;
    Node *nodePtr;

    if ((line < 0) || (byteIndex < 0) || (level < 0)
	    || (line >= TkBTreeNumLines(textPtr->tree))) {
	return NULL;
    }
    TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &index);
    if (index.byteIndex != byteIndex) {
	return NULL;
    }
    TkTextIndexToInternalSeg(&index, &intIndex, NULL);
    linePtr = intIndex.linePtr;
    if ((intIndex.byteIndex != 0) || (linePtr->parentPtr->segPtr == NULL)) {
	return NULL;
    }
    if (level == 0) {
	return &linePtr->value;
    }

    /*
     * The node must start with this leaf and be at this level: never
     * give a value to another node (a tree re-created differently).
     */

    nodePtr = linePtr->parentPtr;
    if (nodePtr->children.linePtr != linePtr) {
	return NULL;
    }
    for ( ; level > 1; level--) {
	Node *parentPtr = nodePtr->parentPtr;

	if ((parentPtr == NULL) || (parentPtr->children.nodePtr != nodePtr)) {
	    return NULL;
	}
	nodePtr = parentPtr;
    }
    return &nodePtr->value;
}

/*
 * The block whose head is at an address (TK_TEXT_VALUE_BLOCK), or
 * NULL if there is none.
 */

static TkTextSegment *
AddressBlock(textPtr, line, byteIndex)
    TkText *textPtr;			/* The widget. */
    int line, byteIndex;		/* The address. */
{
    TkTextIndex index;

    if ((line < 0) || (byteIndex < 0)
	    || (line >= TkBTreeNumLines(textPtr->tree))) {
	return NULL;
    }
    TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &index);
    if (index.byteIndex != byteIndex) {
	return NULL;
    }
    return TkIBTreeAt(&index, 0);
}

/*
 *----------------------------------------------------------------------
 *
 * MapRemains --
 *
 *	An address in the text as the deletion of an undo atom left it,
 *	around the remains of the blocks the deletion cut (see
 *	TkTextUndoAtom), becomes the address of the same place in the
 *	text as the undo restores it: the heads and tails of the cut
 *	blocks and the deleted range come back.  The remains may reach
 *	over several lines (the leaves of a dissolved block become
 *	lines); in the restored text they are on the line of listIndex
 *	(before index1) and on the line of index2 (after it).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	*linePtr and *bytePtr are changed.
 *
 *----------------------------------------------------------------------
 */

static void
MapRemains(textPtr, mapPtr, linePtr, bytePtr)
    TkText *textPtr;			/* The widget (in the restored
					 * state). */
    TkTextRemainsMap *mapPtr;		/* The atom being undone, and the
					 * lines of the remains. */
    int *linePtr, *bytePtr;		/* The address to map. */
{
    TkTextUndoAtom *atomPtr = mapPtr->atomPtr;
    TkTextIndex ext1, index1, index2;
    int a, b, r, s, pos, i;

    if ((*linePtr < mapPtr->line)
	    || (*linePtr > mapPtr->line + mapPtr->numLines)) {
	return;
    }
    if ((TkTextGetIndex(textPtr->interp, textPtr, atomPtr->listIndex, &ext1)
	    != TCL_OK)
	    || (TkTextGetIndex(textPtr->interp, textPtr, atomPtr->index1, &index1)
		    != TCL_OK)
	    || (TkTextGetIndex(textPtr->interp, textPtr, atomPtr->index2, &index2)
		    != TCL_OK)) {
	Tcl_ResetResult(textPtr->interp);
	return;
    }
    r = mapPtr->starts[*linePtr - mapPtr->line] + *bytePtr;
    if (r < 0) {
	return;				/* Before the remains. */
    }
    a = index1.byteIndex - ext1.byteIndex - atomPtr->numHeads;
    b = atomPtr->remains - a;
    if (r < a) {
	pos = r;
	for (i = 0; i < atomPtr->numHeads; i++) {
	    if (atomPtr->cuts[i] <= pos) {
		pos++;
	    }
	}
	*linePtr = TkBTreeLineIndex(ext1.linePtr);
	*bytePtr = ext1.byteIndex + pos;
	return;
    }
    s = r - a;
    if (s < b) {
	pos = s;
	for (i = 0; i < atomPtr->numTails; i++) {
	    if (atomPtr->cuts[atomPtr->numHeads + i] <= pos) {
		pos++;
	    }
	}
    } else {
	pos = s + atomPtr->numTails;	/* After the remains. */
    }
    *linePtr = TkBTreeLineIndex(index2.linePtr);
    *bytePtr = index2.byteIndex + pos;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeRestoreValues --
 *
 *	Give the values recorded by a change back to the nodes at their
 *	addresses, the most recent first, once the change is undone (or,
 *	for an insertion, redone).  A value whose node cannot be found
 *	is freed at the end of the widget command.  A value found at the
 *	address (set there after the change) is not freed: it goes, with
 *	the address, to *displacedPtr, which the atom keeps and gives
 *	back once the change is applied again (see TkTextEditAction);
 *	with displacedPtr NULL it is freed at the end of the command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The records are consumed.
 *
 *----------------------------------------------------------------------
 */

static void
Displace(textPtr, displacedPtr, kind, line, byteIndex, level, name, value)
    TkText *textPtr;
    TkTextValue **displacedPtr;		/* Where it goes, or NULL to free it
					 * at the end of the command. */
    int kind, line, byteIndex, level;	/* The record to make. */
    char *name;				/* The tag's name, or NULL. */
    TkTextData value;			/* The data moved aside; consumed. */
{
    TkTextValue *recPtr;

    if (TkTextDataIsEmpty(value)) {
	return;
    }

    /*
     * The value is still in place (and the text consistent): tell the
     * -valuecommand now.
     */

    if (TkTextVcOn(textPtr) && (TkTextDataGetLang(value) != NULL)) {
	Tcl_Obj *where = NULL;
	int vcKind = TK_TEXT_VC_NODE;

	if (kind == TK_TEXT_VALUE_NODE) {
	    where = TkTextVcNodePlace(textPtr, line, byteIndex, level);
	} else if (kind == TK_TEXT_VALUE_BLOCK) {
	    vcKind = TK_TEXT_VC_BLOCK;
	    where = TkTextVcBlockPlace(textPtr, line, byteIndex);
	} else {
	    Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&textPtr->tagTable, name);
	    TkTextIndex index;

	    vcKind = TK_TEXT_VC_RUN;
	    if (hPtr != NULL) {
		TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &index);
		where = TkBTreeVcRunPlace(textPtr,
			(TkTextTag *) Tcl_GetHashValue(hPtr), &index);
	    }
	}
	TkTextVcPredict(textPtr, value, (displacedPtr == NULL)
		? TK_TEXT_VC_DROP : TK_TEXT_VC_STASH, vcKind, where, NULL);
	TkTextVcNotify(textPtr);
    }
    if (displacedPtr == NULL) {
	TkTextFreeValueLater(textPtr, value);
	return;
    }
    TkTextVcSeen(textPtr, value, TK_TEXT_VC_STASH);
    recPtr = NewValueRecord(kind, value);
    recPtr->line = line;
    recPtr->byteIndex = byteIndex;
    recPtr->level = level;
    if (name != NULL) {
	recPtr->name = CopyName(name);
    }
    recPtr->nextPtr = *displacedPtr;
    *displacedPtr = recPtr;
}

/*
 * A value that the undo of a deletion took out with the remains of the
 * blocks the deletion had cut, and that finds no place in the text the
 * undo restores (it was set on the remains after the deletion): it
 * waits in the atom, with its address in the text without the deleted
 * range, for the redo to give it back (see TkTextEditAction).
 */

static void
KeepRecord(listPtr, kind, line, byteIndex, level, name, value)
    TkTextValue **listPtr;		/* Where it goes. */
    int kind, line, byteIndex, level;	/* The record to make. */
    char *name;				/* The tag's name, or NULL. */
    TkTextData value;			/* Consumed. */
{
    TkTextValue *recPtr;

    if (TkTextDataIsEmpty(value)) {
	return;
    }
    recPtr = NewValueRecord(kind, value);
    recPtr->line = line;
    recPtr->byteIndex = byteIndex;
    recPtr->level = level;
    if (name != NULL) {
	recPtr->name = CopyName(name);
    }
    recPtr->nextPtr = *listPtr;
    *listPtr = recPtr;
}

/*
 * A record of a run value (TK_TEXT_VALUE_RUN or _RUNMOVE), its address
 * mapped: the value goes back to the run at the address if that run
 * starts there or has no value (a value there is displaced, see
 * Displace); a move takes the value of the run at the source address
 * back to the run at the address.  The record's value is consumed.
 */

static void
RestoreRunValue(textPtr, recPtr, line, byteIndex, mapPtr, displacedPtr,
	fromAtom)
    TkText *textPtr;
    TkTextValue *recPtr;
    int line, byteIndex;		/* The address, mapped. */
    TkTextRemainsMap *mapPtr;		/* For the source address. */
    TkTextValue **displacedPtr;		/* See TkBTreeRestoreValues. */
    int fromAtom;			/* See TkBTreeRestoreValues. */
{
    int recLine = recPtr->line, recByteIndex = recPtr->byteIndex;

    Tcl_HashEntry *hPtr = Tcl_FindHashEntry(&textPtr->tagTable, recPtr->name);
    TkTextTag *tagPtr = (hPtr != NULL)
	    ? (TkTextTag *) Tcl_GetHashValue(hPtr) : NULL;
    TkTextSegment *onPtr, *srcPtr;
    TkTextIndex start, srcStart;
    TkTextData value;

    TkTextDataInit(value);
    TkTextDataMove(&value, &recPtr->value);
    onPtr = RunAtAddress(textPtr, tagPtr, line, byteIndex, &start);
    if (recPtr->kind == TK_TEXT_VALUE_RUNMOVE) {
	int srcLine = recPtr->srcLine, srcByteIndex = recPtr->srcByteIndex;

	if (mapPtr != NULL) {
	    MapRemains(textPtr, mapPtr, &srcLine, &srcByteIndex);
	}
	srcPtr = RunAtAddress(textPtr, tagPtr, srcLine, srcByteIndex,
		&srcStart);
	if ((onPtr != NULL) && (srcPtr != NULL) && (srcPtr != onPtr)
		&& !TkTextDataIsEmpty(srcPtr->body.toggle.value)) {
	    Displace(textPtr, displacedPtr, TK_TEXT_VALUE_RUN,
		    TkBTreeLineIndex(start.linePtr), start.byteIndex, -1,
		    recPtr->name, onPtr->body.toggle.value);
	    TkTextDataInit(onPtr->body.toggle.value);	/* Displaced. */
	    TkTextDataMove(&onPtr->body.toggle.value,
		    &srcPtr->body.toggle.value);
	    if (fromAtom) {
		TkTextVcRestored(textPtr, onPtr->body.toggle.value,
			TK_TEXT_VC_RUN, TkBTreeVcRunPlace(textPtr, tagPtr,
				&start));
	    }
	}
	return;
    }
    if (TkTextDataIsEmpty(value)) {
	return;
    }
    if ((onPtr != NULL) && (TkTextDataIsEmpty(onPtr->body.toggle.value)
	    || ((TkBTreeLineIndex(start.linePtr) == line)
		    && (start.byteIndex == byteIndex)))) {
	Displace(textPtr, displacedPtr, TK_TEXT_VALUE_RUN,
		TkBTreeLineIndex(start.linePtr), start.byteIndex, -1,
		recPtr->name, onPtr->body.toggle.value);
	TkTextDataInit(onPtr->body.toggle.value);	/* Displaced. */
	TkTextDataMove(&onPtr->body.toggle.value, &value);
	tagPtr->hasRunValues = 1;
	textPtr->haveValues = 1;
	if (fromAtom) {
	    TkTextVcRestored(textPtr, onPtr->body.toggle.value,
		    TK_TEXT_VC_RUN, TkBTreeVcRunPlace(textPtr, tagPtr, &start));
	}
    } else if ((fromAtom == 2) && (displacedPtr != NULL)) {
	KeepRecord(displacedPtr, TK_TEXT_VALUE_RUN, recLine, recByteIndex, -1,
		recPtr->name, value);
    } else if (fromAtom) {
	TkTextDiscardValue(textPtr, value, TK_TEXT_VALUE_RUN, line,
		byteIndex, -1, recPtr->name);
    } else {
	TkTextFreeValueLater(textPtr, value);
    }
}

void
TkBTreeRestoreValues(textPtr, listPtr, mapPtr, displacedPtr, fromAtom)
    TkText *textPtr;			/* The widget. */
    TkTextValue *listPtr;		/* The records, most recent first. */
    TkTextRemainsMap *mapPtr;		/* If not NULL: the addresses are in
					 * the text before the remains of
					 * the blocks an atom's deletion cut
					 * were taken out (MapRemains). */
    TkTextValue **displacedPtr;		/* Where values found at the
					 * addresses go, or NULL. */
    int fromAtom;			/* 1 if the records come from an undo
					 * atom: a value given back is reported
					 * to the -valuecommand ("restore"),
					 * one that finds no place is
					 * discarded; 2 for the values the
					 * undo of a deletion took out with
					 * the remains of the blocks it had
					 * cut: the same, but one that finds
					 * no place (set on the remains after
					 * the deletion) goes to *displacedPtr
					 * with its address before the undo,
					 * where the redo gives it back; 0 for
					 * values taken off and given back
					 * within the same change (not
					 * reported, freed if they find no
					 * place). */
{
    TkTextValue *nextPtr;
    TkTextData *slotPtr, *srcPtr;
    int line, byteIndex, addrLine, addrByteIndex;

    for ( ; listPtr != NULL; listPtr = nextPtr) {
	nextPtr = listPtr->nextPtr;
	line = listPtr->line;
	byteIndex = listPtr->byteIndex;
	if (mapPtr != NULL) {
	    MapRemains(textPtr, mapPtr, &line, &byteIndex);
	}
	if ((listPtr->kind == TK_TEXT_VALUE_RUN)
		|| (listPtr->kind == TK_TEXT_VALUE_RUNMOVE)) {
	    RestoreRunValue(textPtr, listPtr, line, byteIndex, mapPtr,
		    displacedPtr, fromAtom);
	    if (listPtr->name != NULL) {
		ckfree(listPtr->name);
	    }
	    ckfree((char *) listPtr);
	    continue;
	}
	if (listPtr->kind == TK_TEXT_VALUE_BLOCK) {
	    TkTextSegment *segPtr = AddressBlock(textPtr, line, byteIndex);

	    if (segPtr != NULL) {
		Displace(textPtr, displacedPtr, TK_TEXT_VALUE_BLOCK, line,
			byteIndex, -1, NULL, segPtr->body.itree.data);
		TkTextDataInit(segPtr->body.itree.data);	/* Displaced. */
		TkTextDataMove(&segPtr->body.itree.data, &listPtr->value);
		textPtr->haveValues = 1;
		if (fromAtom) {
		    TkTextVcRestored(textPtr, segPtr->body.itree.data,
			    TK_TEXT_VC_BLOCK, TkTextVcBlockPlace(textPtr, line,
				    byteIndex));
		}
	    } else if ((fromAtom == 2) && (displacedPtr != NULL)) {
		KeepRecord(displacedPtr, TK_TEXT_VALUE_BLOCK, listPtr->line,
			listPtr->byteIndex, -1, NULL, listPtr->value);
	    } else if (fromAtom) {
		TkTextDiscardValue(textPtr, listPtr->value,
			TK_TEXT_VALUE_BLOCK, line, byteIndex, -1, NULL);
	    } else {
		TkTextFreeValueLater(textPtr, listPtr->value);
	    }
	    ckfree((char *) listPtr);
	    continue;
	}
	slotPtr = AddressValue(textPtr, line, byteIndex, listPtr->level);
	addrLine = line;
	addrByteIndex = byteIndex;
	if (listPtr->kind == TK_TEXT_VALUE_MOVE) {
	    line = listPtr->srcLine;
	    byteIndex = listPtr->srcByteIndex;
	    if (mapPtr != NULL) {
		MapRemains(textPtr, mapPtr, &line, &byteIndex);
	    }
	    srcPtr = AddressValue(textPtr, line, byteIndex, listPtr->srcLevel);
	    if ((slotPtr != NULL) && (srcPtr != NULL) && (srcPtr != slotPtr)
		    && !TkTextDataIsEmpty(*srcPtr)) {
		Displace(textPtr, displacedPtr, TK_TEXT_VALUE_NODE,
			addrLine, addrByteIndex, listPtr->level, NULL,
			*slotPtr);
		TkTextDataInit(*slotPtr);	/* Displaced. */
		TkTextDataMove(slotPtr, srcPtr);
		if (fromAtom) {
		    TkTextVcRestored(textPtr, *slotPtr, TK_TEXT_VC_NODE,
			    TkTextVcNodePlace(textPtr, addrLine, addrByteIndex,
				    listPtr->level));
		}
	    }
	} else if (!TkTextDataIsEmpty(listPtr->value)) {
	    if (slotPtr != NULL) {
		Displace(textPtr, displacedPtr, TK_TEXT_VALUE_NODE, line,
			byteIndex, listPtr->level, NULL, *slotPtr);
		TkTextDataInit(*slotPtr);	/* Displaced. */
		TkTextDataMove(slotPtr, &listPtr->value);
		textPtr->haveValues = 1;
		if (fromAtom) {
		    TkTextVcRestored(textPtr, *slotPtr, TK_TEXT_VC_NODE,
			    TkTextVcNodePlace(textPtr, line, byteIndex,
				    listPtr->level));
		}
	    } else if ((fromAtom == 2) && (displacedPtr != NULL)) {
		KeepRecord(displacedPtr, TK_TEXT_VALUE_NODE, listPtr->line,
			listPtr->byteIndex, listPtr->level, NULL,
			listPtr->value);
	    } else if (fromAtom) {
		TkTextDiscardValue(textPtr, listPtr->value,
			TK_TEXT_VALUE_NODE, line, byteIndex, listPtr->level,
			NULL);
	    } else {
		TkTextFreeValueLater(textPtr, listPtr->value);
	    }
	}
	if (listPtr->name != NULL) {
	    ckfree(listPtr->name);
	}
	ckfree((char *) listPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeNodeValue --
 *
 *	Find the node of "block nodedata index level": the leaf the
 *	index is in (in the innermost block containing it) or one of
 *	its ancestors, level 0 being the leaf, 1 its parent..., -1 the
 *	root, -2 a child of the root...
 *
 * Results:
 *	A standard Tcl result; on success *dataPtrPtr is where the
 *	node's data is kept.
 *
 * Side effects:
 *	An error message is left in the interpreter.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeNodeValue(textPtr, indexPtr, indexString, levelArg, dataPtrPtr)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *indexPtr;		/* The position. */
    char *indexString;			/* As given, for error messages. */
    Arg levelArg;			/* The level. */
    TkTextData **dataPtrPtr;		/* Filled in. */
{
    TkTextIndex intIndex;
    TkTextLine *linePtr;
    Node *nodePtr;
    int level, above;
    char buffer[TCL_INTEGER_SPACE * 2];

    TkTextIndexToInternalSeg(indexPtr, &intIndex, NULL);
    linePtr = intIndex.linePtr;
    if (linePtr->parentPtr->segPtr == NULL) {
	Tcl_AppendResult(textPtr->interp, "bad index \"", indexString,
		"\": not inside a block", NULL);
	return TCL_ERROR;
    }
    if (Tcl_GetIntFromObj(textPtr->interp, levelArg, &level) != TCL_OK) {
	return TCL_ERROR;
    }
    above = ((BTree *) linePtr->parentPtr->segPtr->body.itree.tree)
	    ->rootPtr->level + 1;
    if (level < 0) {
	level += above + 1;
    }
    if ((level < 0) || (level > above)) {
	sprintf(buffer, "%d level%s", above, (above == 1) ? "" : "s");
	Tcl_AppendResult(textPtr->interp, "bad level \"",
		LangString(levelArg), "\": the block containing ", indexString,
		" has ", buffer, " above its leaves", NULL);
	return TCL_ERROR;
    }
    if (level == 0) {
	*dataPtrPtr = &linePtr->value;
	return TCL_OK;
    }
    for (nodePtr = linePtr->parentPtr; level > 1; level--) {
	nodePtr = nodePtr->parentPtr;
    }
    *dataPtrPtr = &nodePtr->value;
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeSetValue --
 *
 *	Set the Lang part of the data of a node or a run to a copy of a
 *	scalar (none if it is undefined: only the Lang part goes); the
 *	old Lang part is freed at the end of the widget command.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	See above.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeSetValue(textPtr, dataPtr, value)
    TkText *textPtr;			/* The widget. */
    TkTextData *dataPtr;		/* Where the node's data is. */
    Arg value;				/* The new value. */
{
    Arg old;

    if ((value == NULL) || !SvOK((SV *) value)) {
	old = TkTextDataTakeLang(dataPtr);
    } else {
	old = TkTextDataPutLang(dataPtr, LangCopyArg(value));
	textPtr->haveValues = 1;
    }
    TkTextFreeValueLater(textPtr, TkTextDataFromLang(old));
}

/*
 *----------------------------------------------------------------------
 *
 * NodeHasValues, NodeValuesList --
 *
 *	The node values of a block for its header in a "block list":
 *	[value, child, child...] for a node, [value] for a leaf, undef
 *	where there is no value.  Only the Lang parts are listed (and a
 *	node whose data has no Lang part counts as without a value).
 *
 *----------------------------------------------------------------------
 */

static int
NodeHasValues(nodePtr)
    Node *nodePtr;
{
    if (TkTextDataGetLang(nodePtr->value) != NULL) {
	return 1;
    }
    if (nodePtr->level == 0) {
	TkTextLine *linePtr;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    if (TkTextDataGetLang(linePtr->value) != NULL) {
		return 1;
	    }
	}
    } else {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    if (NodeHasValues(childPtr)) {
		return 1;
	    }
	}
    }
    return 0;
}

static void
NodeValuesList(nodePtr, lfPtr)
    Node *nodePtr;
    ListFactory *lfPtr;
{
    lfPtr = ListFactoryNewLevel(lfPtr);
    ListFactoryAppendPure(lfPtr, TkTextDataLangSV(nodePtr->value));
    if (nodePtr->level == 0) {
	TkTextLine *linePtr;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    if (IsLastLine(linePtr)) {
		break;
	    }
	    lfPtr = ListFactoryNewLevel(lfPtr);
	    ListFactoryAppendPure(lfPtr, TkTextDataLangSV(linePtr->value));
	    lfPtr = ListFactoryEndLevel(lfPtr);
	}
    } else {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    NodeValuesList(childPtr, lfPtr);
	}
    }
    lfPtr = ListFactoryEndLevel(lfPtr);
}

/*
 *------------------------------------------------------------------
 *
 * TkIBTreeCutPositions
 * 	For a deletion that cuts blocks (TkIBTreeCutRange), find the
 *	heads of the cut blocks before index1 and the tails of those
 *	after index2, which the dissolution of the blocks removes.
 *
 * Returns:
 *	A malloc-ed array (NULL if there are none): *numHeadsPtr byte
 *	offsets of heads from ext1, in increasing order, then
 *	*numTailsPtr byte offsets of tails from index2, increasing.
 *
 * Side effects:
 *	None.
 *
 *------------------------------------------------------------------
 */

int *
TkIBTreeCutPositions(index1Ptr, index2Ptr, ext1Ptr, numHeadsPtr, numTailsPtr)
     TkTextIndex *index1Ptr;		/* Start of the deletion. */
     TkTextIndex *index2Ptr;		/* Its end. */
     TkTextIndex *ext1Ptr;		/* The start of the uncut range. */
     int *numHeadsPtr, *numTailsPtr;	/* Filled in. */
{
  TkTextSegment *segPtr, *otherPtr;
  TkTextIndex start;
  int *heads, *tails, nh = 0, nt = 0, i, n1 = 0, n2 = 0, *cuts;

  /*
   * At most as many heads (tails) as blocks around index1 (index2).
   */

  for (segPtr = TkIBTreeAt(index1Ptr, 1); segPtr != NULL;
       segPtr = segPtr->body.itree.linePtr->parentPtr->segPtr) {
    n1++;
  }
  for (segPtr = TkIBTreeAt(index2Ptr, 1); segPtr != NULL;
       segPtr = segPtr->body.itree.linePtr->parentPtr->segPtr) {
    n2++;
  }
  if (n1 + n2 == 0) {
    *numHeadsPtr = *numTailsPtr = 0;
    return NULL;
  }
  heads = (int *) ckalloc((unsigned) ((n1 + n2) * sizeof(int)));
  tails = heads + n1;
  for (segPtr = TkIBTreeAt(index1Ptr, 1); segPtr != NULL;
       segPtr = segPtr->body.itree.linePtr->parentPtr->segPtr) {
    for (otherPtr = TkIBTreeAt(index2Ptr, 1); otherPtr != NULL;
	 otherPtr = otherPtr->body.itree.linePtr->parentPtr->segPtr) {
      if (otherPtr == segPtr) {
	break;
      }
    }
    if (otherPtr != NULL) {
      break;
    }
    TkIBTreeStartIndex(index1Ptr->tree, segPtr, &start);
    heads[nh++] = start.byteIndex - ext1Ptr->byteIndex;
  }
  for (segPtr = TkIBTreeAt(index2Ptr, 1); segPtr != NULL;
       segPtr = segPtr->body.itree.linePtr->parentPtr->segPtr) {
    for (otherPtr = TkIBTreeAt(index1Ptr, 1); otherPtr != NULL;
	 otherPtr = otherPtr->body.itree.linePtr->parentPtr->segPtr) {
      if (otherPtr == segPtr) {
	break;
      }
    }
    if (otherPtr != NULL) {
      break;
    }
    TkIBTreeStartIndex(index2Ptr->tree, segPtr, &start);
    tails[nt++] = start.byteIndex + segPtr->size - 1 - index2Ptr->byteIndex;
  }
  *numHeadsPtr = nh;
  *numTailsPtr = nt;
  if (nh + nt == 0) {
    ckfree((char *) heads);
    return NULL;
  }
  cuts = (int *) ckalloc((unsigned) ((nh + nt) * sizeof(int)));
  for (i = 0; i < nh; i++) {
    cuts[i] = heads[nh - 1 - i];	/* The outermost (first) first. */
  }
  for (i = 0; i < nt; i++) {
    cuts[nh + i] = tails[i];		/* The innermost (first) first. */
  }
  ckfree((char *) heads);
  return cuts;
}


/*
 *======================================================================
 *
 * Values of tag runs ("tag data").
 *
 *	A run of a tag is a maximal stretch of characters carrying the
 *	tag (it may cross line ends, leaf separators and block heads and
 *	tails, which take tags like characters).  Its value is kept in
 *	the toggle-on segment that starts it.  Toggle-ons are not
 *	identities a change keeps, though: a deletion moves the toggles
 *	of the range to its start (the off-toggles first, see
 *	DeleteRange), the cleanup of a line then cancels an off-toggle
 *	followed by an on-toggle (two runs merge), and the toggle-on
 *	left may be that of a run that is gone; adding or removing a tag
 *	removes the toggles inside the range.  So a change that can do
 *	such things (TkBTreeTag, TkBTreeDeleteChars on a widget with
 *	values) first takes the values off the runs it touches, noting
 *	where each run is (RunSave), makes the change, then gives each
 *	value to the run that is left of its run, if any
 *	(ReattachRuns): of the runs that are now one, the leftmost one
 *	with a value keeps it (a run whose text is all gone takes no
 *	part); the other values, and those of runs that are gone, are
 *	dropped (DropRunValue: into the undo atom of the deletion going
 *	on, else freed at the end of the widget command).
 *
 *======================================================================
 */

typedef struct RunSave {
    TkTextTag *tagPtr;			/* The tag. */
    TkTextData value;			/* The run's data, taken off its
					 * toggle-on; empty if none. */
    TkTextIndex start, end;		/* The run before the change. */
    int line, byteIndex;		/* Its start as an address (see
					 * TkTextValue). */
    TkTextSegment *startMark, *endMark;	/* For a deletion: marks at its start
					 * and end, which the deletion moves
					 * as it moves the text. */
    TkTextIndex dest;			/* After the change: a character of
					 * what is left of the run, */
    int gone;				/* or non-zero if nothing is. */
    TkTextSegment *onPtr;		/* The toggle-on of the run that
					 * character is in. */
} RunSave;

typedef struct RunList {
    RunSave *runs;			/* Malloc-ed; in the order of the
					 * text, tag by tag. */
    int num, max;
} RunList;

/*
 * The index of the end of the text (the dummy last line).
 */

static void
TextEnd(textPtr, indexPtr)
    TkText *textPtr;
    TkTextIndex *indexPtr;
{
    TkTextMakeByteIndex(textPtr->tree, TkBTreeNumLines(textPtr->tree), 0,
	    indexPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * RunStart --
 *
 *	Find the toggle-on of the run of a tag that contains a character
 *	(which the caller knows to carry the tag).
 *
 * Results:
 *	The toggle-on segment (NULL if there is none, which would be an
 *	inconsistency); *startPtr is set to its (external) index.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static TkTextSegment *
RunStart(textPtr, tagPtr, indexPtr, startPtr)
    TkText *textPtr;			/* The widget. */
    TkTextTag *tagPtr;			/* The tag. */
    TkTextIndex *indexPtr;		/* The character (external index). */
    TkTextIndex *startPtr;		/* Filled in. */
{
    TkTextSearch search;
    TkTextIndex after, first, last, index0, intIndex0;
    TkTextSegment *onPtr = NULL;

    /*
     * The last toggle before the character's end is its run's
     * toggle-on.
     */

    TkTextIndexForwBytes(indexPtr, 1, &after);
    TkTextMakeByteIndex(textPtr->tree, 0, 0, &first);
    TkBTreeStartSearchBack(&after, &first, tagPtr, &search);
    while (TkBTreePrevTag(&search)) {
	if (TkTextIndexCmp(&search.extIndex, indexPtr) > 0) {
	    continue;			/* At the character's end (the search
					 * may return toggles there). */
	}
	if (search.segPtr->typePtr == &tkTextToggleOnType) {
	    *startPtr = search.extIndex;
	    return search.segPtr;
	}
	break;
    }

    /*
     * Not expected: then scan forward from the first toggle.
     */

    onPtr = FindTagStart(textPtr->tree, tagPtr, &index0, &intIndex0);
    if ((onPtr == NULL) || (TkTextIndexCmp(&index0, indexPtr) > 0)) {
	return NULL;
    }
    if (onPtr->typePtr != &tkTextToggleOnType) {
	onPtr = NULL;
    }
    *startPtr = index0;
    TextEnd(textPtr, &last);
    TkBTreeStartSearch(&index0, &last, tagPtr, &search);
    while (TkBTreeNextTag(&search)
	    && (TkTextIndexCmp(&search.extIndex, indexPtr) <= 0)) {
	if (search.segPtr->typePtr == &tkTextToggleOnType) {
	    onPtr = search.segPtr;
	    *startPtr = search.extIndex;
	} else {
	    onPtr = NULL;
	}
    }
    return onPtr;
}

/*
 * The run of a tag containing a character, if the character has the
 * tag: its toggle-on, or NULL.
 */

static TkTextSegment *
RunAt(textPtr, tagPtr, indexPtr, startPtr)
    TkText *textPtr;
    TkTextTag *tagPtr;
    TkTextIndex *indexPtr;
    TkTextIndex *startPtr;		/* Filled in with its start. */
{
    if (!TkBTreeCharTagged(indexPtr, tagPtr)) {
	return NULL;
    }
    return RunStart(textPtr, tagPtr, indexPtr, startPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * CollectRuns --
 *
 *	Add to a list the runs of a tag that a change of the range
 *	between two indices may touch: those that have a character in
 *	it or right next to it (a run ending at index1 or starting at
 *	index2 may merge with another).
 *
 * Results:
 *	The number of these runs that have a value.
 *
 * Side effects:
 *	The list grows.  The values stay where they are.
 *
 *----------------------------------------------------------------------
 */

static void
AddRun(listPtr, tagPtr, onPtr, startPtr, endPtr)
    RunList *listPtr;
    TkTextTag *tagPtr;
    TkTextSegment *onPtr;
    TkTextIndex *startPtr, *endPtr;
{
    RunSave *runPtr;

    if (listPtr->num >= listPtr->max) {
	RunSave *grown;

	listPtr->max = 2 * listPtr->max + 8;
	grown = (RunSave *) ckalloc((unsigned)
		(listPtr->max * sizeof(RunSave)));
	if (listPtr->num > 0) {
	    memcpy(grown, listPtr->runs, listPtr->num * sizeof(RunSave));
	}
	if (listPtr->runs != NULL) {
	    ckfree((char *) listPtr->runs);
	}
	listPtr->runs = grown;
    }
    runPtr = &listPtr->runs[listPtr->num++];
    runPtr->tagPtr = tagPtr;
    TkTextDataInit(runPtr->value);
    runPtr->onPtr = onPtr;		/* Before the change. */
    runPtr->start = *startPtr;
    runPtr->end = *endPtr;
    runPtr->line = TkBTreeLineIndex(startPtr->linePtr);
    runPtr->byteIndex = startPtr->byteIndex;
    runPtr->startMark = runPtr->endMark = NULL;
    runPtr->dest = *startPtr;
    runPtr->gone = 0;
}

static int
CollectRuns(textPtr, tagPtr, index1Ptr, index2Ptr, listPtr)
    TkText *textPtr;			/* The widget. */
    TkTextTag *tagPtr;			/* The tag. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range (external indices). */
    RunList *listPtr;			/* The list to add to. */
{
    TkTextIndex before, from, start, last;
    TkTextSearch search;
    TkTextSegment *onPtr = NULL;
    int valued = 0;

    TextEnd(textPtr, &last);
    TkTextIndexBackBytes(index1Ptr, 1, &before);
    from = before;
    if (TkBTreeCharTagged(&before, tagPtr)) {
	onPtr = RunStart(textPtr, tagPtr, &before, &start);
	if (onPtr != NULL) {
	    from = start;
	}
    }
    TkBTreeStartSearch(&from, &last, tagPtr, &search);
    while (TkBTreeNextTag(&search)) {
	if (search.segPtr->typePtr == &tkTextToggleOnType) {
	    if (onPtr != NULL) {
		continue;
	    }
	    if (TkTextIndexCmp(&search.extIndex, index2Ptr) > 0) {
		break;
	    }
	    onPtr = search.segPtr;
	    start = search.extIndex;
	} else if (onPtr != NULL) {
	    AddRun(listPtr, tagPtr, onPtr, &start, &search.extIndex);
	    valued += !TkTextDataIsEmpty(onPtr->body.toggle.value);
	    onPtr = NULL;
	}
    }
    if (onPtr != NULL) {
	AddRun(listPtr, tagPtr, onPtr, &start, &last);
	valued += !TkTextDataIsEmpty(onPtr->body.toggle.value);
    }
    return valued;
}

/*
 * Take the values off the toggle-ons of the runs of a list.
 */

static void
DetachRuns(listPtr)
    RunList *listPtr;
{
    int i;

    for (i = 0; i < listPtr->num; i++) {
	RunSave *runPtr = &listPtr->runs[i];

	TkTextDataMove(&runPtr->value, &runPtr->onPtr->body.toggle.value);
	runPtr->onPtr = NULL;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * DropRunValue, DropToggleValue --
 *
 *	A run loses its value: record it in the undo atom of the
 *	deletion going on, with the run's address and tag, or else have
 *	it freed at the end of the widget command.  DropToggleValue is
 *	for a toggle-on that is freed with a value still on it (only
 *	when the widget is destroyed; the changes that free toggles take
 *	the values off first).
 *
 *----------------------------------------------------------------------
 */

static char *
CopyName(name)
    char *name;
{
    char *copy = ckalloc((unsigned) (strlen(name) + 1));

    strcpy(copy, name);
    return copy;
}

static void
DropRunValue(textPtr, runPtr)
    TkText *textPtr;			/* The widget. */
    RunSave *runPtr;			/* The run; its data is consumed. */
{
    TkTextData value;

    if (TkTextDataIsEmpty(runPtr->value)) {
	return;
    }
    TkTextDataInit(value);
    TkTextDataMove(&value, &runPtr->value);
    if (textPtr->valueCapture != NULL) {
	TkTextValue *recPtr;

	TkTextVcSeen(textPtr, value, TK_TEXT_VC_STASH);
	recPtr = NewValueRecord(TK_TEXT_VALUE_RUN, value);
	recPtr->line = runPtr->line;
	recPtr->byteIndex = runPtr->byteIndex;
	recPtr->name = CopyName(runPtr->tagPtr->name);
	recPtr->nextPtr = *textPtr->valueCapture;
	*textPtr->valueCapture = recPtr;
	return;
    }
    TkTextFreeValueLater(textPtr, value);
}

static void
DropToggleValue(segPtr)
    TkTextSegment *segPtr;		/* A toggle being freed. */
{
    if (!TkTextDataIsEmpty(segPtr->body.toggle.value)) {
	TkTextFreeValueLater(segPtr->body.toggle.tagPtr->textPtr,
		segPtr->body.toggle.value);
	TkTextDataInit(segPtr->body.toggle.value);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ReattachRuns --
 *
 *	After a change, give the values taken off the runs of a list
 *	(whose dest, gone and onPtr fields are set) to the runs left of
 *	them, merges following the merge policy (TkTextDataMerge, today
 *	the leftmost data present wins, each in turn merged into the
 *	run); drop the others.  A merge that gives the merged run the
 *	data of a run other than its first one is recorded in the undo
 *	atom of the deletion going on, so that the undo moves it back.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The list is freed.
 *
 *----------------------------------------------------------------------
 */

static void
ReattachRuns(textPtr, listPtr)
    TkText *textPtr;			/* The widget. */
    RunList *listPtr;			/* The runs, in order, tag by tag. */
{
    int i, k;
    RunSave *runs = listPtr->runs, *winnerPtr, *firstPtr;
    TkTextSegment *onPtr;

    for (i = 0; i < listPtr->num; ) {
	if (runs[i].gone) {
	    DropRunValue(textPtr, &runs[i]);
	    i++;
	    continue;
	}

	/*
	 * The runs that are now in the same run as runs[i] follow it
	 * (runs of the same tag merge only with their neighbours),
	 * possibly with runs that are gone among them.
	 */

	onPtr = runs[i].onPtr;
	firstPtr = &runs[i];
	winnerPtr = NULL;
	for (k = i; (k < listPtr->num) && (runs[k].tagPtr == firstPtr->tagPtr);
	     k++) {
	    if (runs[k].gone) {
		DropRunValue(textPtr, &runs[k]);
		continue;
	    }
	    if (runs[k].onPtr != onPtr) {
		break;
	    }
	    switch (TkTextDataMerge(&onPtr->body.toggle.value,
		    &runs[k].value)) {
	    case TK_TEXT_DATA_MERGE_DROP:
		DropRunValue(textPtr, &runs[k]);
		break;
	    case TK_TEXT_DATA_MERGE_MOVED:
		winnerPtr = &runs[k];
		break;
	    }
	}
	if ((winnerPtr != NULL) && (winnerPtr != firstPtr)) {
	    TkTextVcSeen(textPtr, onPtr->body.toggle.value, TK_TEXT_VC_MOVE);
	}
	if (winnerPtr != NULL) {
	    if ((winnerPtr != firstPtr) && (textPtr->valueCapture != NULL)) {
		TkTextData none;
		TkTextValue *recPtr;

		TkTextDataInit(none);
		recPtr = NewValueRecord(TK_TEXT_VALUE_RUNMOVE, none);

		recPtr->line = winnerPtr->line;
		recPtr->byteIndex = winnerPtr->byteIndex;
		recPtr->srcLine = firstPtr->line;
		recPtr->srcByteIndex = firstPtr->byteIndex;
		recPtr->name = CopyName(winnerPtr->tagPtr->name);
		recPtr->nextPtr = *textPtr->valueCapture;
		*textPtr->valueCapture = recPtr;
	    }
	}
	i = k;
    }
    if (listPtr->runs != NULL) {
	ckfree((char *) listPtr->runs);
    }
    listPtr->runs = NULL;
    listPtr->num = listPtr->max = 0;
}

/*
 *----------------------------------------------------------------------
 *
 * TagKeepingRuns --
 *
 *	TkBTreeTag for a tag whose runs may have values.  Adding the tag
 *	merges the runs it touches (each run is all there afterwards);
 *	removing it from a range leaves of a run the part before the
 *	range, which keeps the value, and the part after it, which
 *	keeps the value if there is no part before (a run shortened at
 *	its start) and else starts without one (a run cut in two).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	As TagRange; values may be dropped.
 *
 *----------------------------------------------------------------------
 */

static void
TagKeepingRuns(index1Ptr, index2Ptr, tagPtr, add)
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range. */
    TkTextTag *tagPtr;			/* The tag. */
    int add;				/* 1 to add the tag, 0 to remove it. */
{
    TkText *textPtr = tagPtr->textPtr;
    TkTextIndex index1 = *index1Ptr, index2 = *index2Ptr, start;
    RunList list;
    int i;

    list.runs = NULL;
    list.num = list.max = 0;
    if (CollectRuns(textPtr, tagPtr, &index1, &index2, &list) == 0) {
	if (list.runs != NULL) {
	    ckfree((char *) list.runs);
	}
	TagRange(index1Ptr, index2Ptr, tagPtr, add);
	return;
    }
    for (i = 0; i < list.num; i++) {
	RunSave *runPtr = &list.runs[i];

	if (add || (TkTextIndexCmp(&runPtr->start, &index1) < 0)) {
	    runPtr->dest = runPtr->start;
	} else if (TkTextIndexCmp(&runPtr->end, &index2) > 0) {
	    runPtr->dest = index2;
	} else {
	    runPtr->gone = 1;
	}
    }
    DetachRuns(&list);
    TagRange(index1Ptr, index2Ptr, tagPtr, add);
    for (i = 0; i < list.num; i++) {
	RunSave *runPtr = &list.runs[i];

	if (!runPtr->gone) {
	    runPtr->onPtr = RunAt(textPtr, tagPtr, &runPtr->dest, &start);
	    runPtr->gone = (runPtr->onPtr == NULL);
	}
    }
    ReattachRuns(textPtr, &list);
}

/*
 *----------------------------------------------------------------------
 *
 * DeleteKeepingRuns --
 *
 *	TkBTreeDeleteChars on a widget whose runs may have values.  The
 *	runs that the deletion may touch are those near the range, or
 *	near the heads and tails of the blocks the deletion cuts (which
 *	the widget dissolves): a mark at the start and one at the end of
 *	each move with the text, so that afterwards the first character
 *	between them that has the tag is in what is left of the run; if
 *	the marks meet, the run's text is all gone.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	As DeleteRange; values may be dropped.
 *
 *----------------------------------------------------------------------
 */

static int tempMarkCount = 0;

static TkTextSegment *
TempMark(textPtr, indexPtr)
    TkText *textPtr;
    TkTextIndex *indexPtr;
{
    char name[40];
    TkTextIndex index = *indexPtr;

    sprintf(name, "#run%d", tempMarkCount++);
    return TkTextSetMark(textPtr, name, &index);
}

static void
UnsetTempMark(textPtr, markPtr, indexPtr)
    TkText *textPtr;
    TkTextSegment *markPtr;
    TkTextIndex *indexPtr;		/* Filled in with its position. */
{
    TkTextMarkSegToIndex(textPtr, markPtr, indexPtr);
    TkBTreeUnlinkSegment(textPtr->tree, markPtr, markPtr->body.mark.linePtr);
    Tcl_DeleteHashEntry(markPtr->body.mark.hPtr);
    ckfree((char *) markPtr);
}

static void
DeleteKeepingRuns(textPtr, index1Ptr, index2Ptr)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range to delete. */
{
    TkTextIndex ext1, ext2, s, e;
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;
    TkTextSearch tSearch;
    RunList list;
    int i, remains, valued = 0;

    if (TkIBTreeCutRange(index1Ptr, index2Ptr, &ext1, &ext2, &remains) == 0) {
	ext1 = *index1Ptr;
	ext2 = *index2Ptr;
    }
    list.runs = NULL;
    list.num = list.max = 0;
    for (hPtr = Tcl_FirstHashEntry(&textPtr->tagTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	TkTextTag *tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);
	int num = list.num, n;

	if (!tagPtr->hasRunValues) {
	    continue;
	}
	n = CollectRuns(textPtr, tagPtr, &ext1, &ext2, &list);
	if (n == 0) {
	    list.num = num;		/* Nothing to keep for this tag. */
	}
	valued += n;
    }
    if (valued == 0) {
	if (list.runs != NULL) {
	    ckfree((char *) list.runs);
	}
	DeleteRange(index1Ptr, index2Ptr, 1, 1);
	return;
    }
    DetachRuns(&list);
    for (i = 0; i < list.num; i++) {
	list.runs[i].startMark = TempMark(textPtr, &list.runs[i].start);
	list.runs[i].endMark = TempMark(textPtr, &list.runs[i].end);
    }
    DeleteRange(index1Ptr, index2Ptr, 1, 1);
    for (i = 0; i < list.num; i++) {
	RunSave *runPtr = &list.runs[i];

	UnsetTempMark(textPtr, runPtr->startMark, &s);
	UnsetTempMark(textPtr, runPtr->endMark, &e);
	runPtr->gone = 1;
	if (TkTextIndexCmp(&s, &e) >= 0) {
	    continue;
	}
	if (!TkBTreeCharTagged(&s, runPtr->tagPtr)) {
	    TkBTreeStartSearch(&s, &e, runPtr->tagPtr, &tSearch);
	    while (TkBTreeNextTag(&tSearch)
		    && (tSearch.segPtr->typePtr != &tkTextToggleOnType)) {
		/* Empty. */
	    }
	    if ((tSearch.segPtr == NULL)
		    || (tSearch.segPtr->typePtr != &tkTextToggleOnType)
		    || (TkTextIndexCmp(&tSearch.extIndex, &e) >= 0)) {
		continue;
	    }
	    s = tSearch.extIndex;
	}
	runPtr->dest = s;
	runPtr->onPtr = RunAt(textPtr, runPtr->tagPtr, &s, &e);
	runPtr->gone = (runPtr->onPtr == NULL);
    }
    tempMarkCount -= 2 * list.num;
    ReattachRuns(textPtr, &list);
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeHoldRunValues, TkBTreeReleaseRunValues --
 *
 *	The undo of a deletion re-inserts the deleted text piece by piece
 *	(InsertList) at the place of the deletion.  A run of a tag that
 *	starts there, after the deletion, may meet a piece of the text
 *	that has the same tag: for a moment they are one run, whose
 *	value (the leftmost present) is then on the piece's toggle, and
 *	stays with the piece when the rest of the text cuts them apart.
 *	So the values of the runs starting at the place are taken off
 *	before (Hold), with a mark after which the run will be, and given
 *	back after (Release) to the run at the mark.
 *
 * Results:
 *	Hold returns what Release needs (or NULL).
 *
 * Side effects:
 *	Values move; temporary marks come and go.
 *
 *----------------------------------------------------------------------
 */

typedef struct HeldRun {
    TkTextTag *tagPtr;
    TkTextSegment *markPtr;
    TkTextData value;
    struct HeldRun *nextPtr;
} HeldRun;

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeTakeCrossingRunValues --
 *
 *	Before the undo of a deletion takes out the remains of the blocks
 *	the deletion dissolved: a run that starts in the remains and goes
 *	on after them (the deletion joined it to a later run) would lose
 *	its start, and its value would stay on the rest, the later run.
 *	The value is taken off it instead, as a record with the address
 *	of the run's start, to go back there once the text is re-created
 *	(through the map of the remains, see TkBTreeRestoreValues).
 *
 * Results:
 *	The records (TK_TEXT_VALUE_RUN), or NULL.
 *
 * Side effects:
 *	The values are taken off their runs.
 *
 *----------------------------------------------------------------------
 */

TkTextValue *
TkBTreeTakeCrossingRunValues(textPtr, index1Ptr, index2Ptr)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The remains (external). */
{
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;
    TkTextValue *listPtr = NULL, *recPtr;
    TkTextIndex start;
    TkTextSegment *onPtr;

    for (hPtr = Tcl_FirstHashEntry(&textPtr->tagTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	TkTextTag *tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);

	if (!tagPtr->hasRunValues) {
	    continue;
	}
	onPtr = RunAt(textPtr, tagPtr, index2Ptr, &start);
	if ((onPtr == NULL) || TkTextDataIsEmpty(onPtr->body.toggle.value)
		|| (TkTextIndexCmp(&start, index1Ptr) < 0)
		|| (TkTextIndexCmp(&start, index2Ptr) >= 0)) {
	    continue;
	}
	if (TkTextVcOn(textPtr)) {
	    TkTextVcPredict(textPtr, onPtr->body.toggle.value,
		    TK_TEXT_VC_STASH, TK_TEXT_VC_RUN,
		    TkBTreeVcRunPlace(textPtr, tagPtr, &start), NULL);
	    TkTextVcNotify(textPtr);
	    TkTextVcSeen(textPtr, onPtr->body.toggle.value, TK_TEXT_VC_STASH);
	}
	recPtr = NewValueRecord(TK_TEXT_VALUE_RUN, onPtr->body.toggle.value);
	TkTextDataInit(onPtr->body.toggle.value);	/* The record took it. */
	recPtr->line = TkBTreeLineIndex(start.linePtr);
	recPtr->byteIndex = start.byteIndex;
	recPtr->name = CopyName(tagPtr->name);
	recPtr->nextPtr = listPtr;
	listPtr = recPtr;
    }
    return listPtr;
}

void *
TkBTreeHoldRunValues(textPtr, indexPtr)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *indexPtr;		/* The place (external index). */
{
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;
    HeldRun *listPtr = NULL, *heldPtr;
    TkTextIndex start;
    TkTextSegment *onPtr;

    for (hPtr = Tcl_FirstHashEntry(&textPtr->tagTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	TkTextTag *tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);

	if (!tagPtr->hasRunValues) {
	    continue;
	}
	onPtr = RunAt(textPtr, tagPtr, indexPtr, &start);
	if ((onPtr == NULL) || TkTextDataIsEmpty(onPtr->body.toggle.value)
		|| (TkTextIndexCmp(&start, indexPtr) != 0)) {
	    continue;
	}
	heldPtr = (HeldRun *) ckalloc(sizeof(HeldRun));
	heldPtr->tagPtr = tagPtr;
	TkTextDataInit(heldPtr->value);
	TkTextDataMove(&heldPtr->value, &onPtr->body.toggle.value);
	heldPtr->markPtr = TempMark(textPtr, indexPtr);
	heldPtr->nextPtr = listPtr;
	listPtr = heldPtr;
    }
    return (void *) listPtr;
}

void
TkBTreeReleaseRunValues(textPtr, held)
    TkText *textPtr;			/* The widget. */
    void *held;				/* What Hold returned. */
{
    HeldRun *heldPtr = (HeldRun *) held, *nextPtr;
    TkTextIndex index, start;
    TkTextSegment *onPtr;

    for ( ; heldPtr != NULL; heldPtr = nextPtr) {
	nextPtr = heldPtr->nextPtr;
	UnsetTempMark(textPtr, heldPtr->markPtr, &index);
	tempMarkCount--;
	onPtr = RunAt(textPtr, heldPtr->tagPtr, &index, &start);
	if ((onPtr != NULL) && TkTextDataIsEmpty(onPtr->body.toggle.value)) {
	    TkTextDataMove(&onPtr->body.toggle.value, &heldPtr->value);
	} else {
	    TkTextFreeValueLater(textPtr, heldPtr->value);
	}
	ckfree((char *) heldPtr);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeRunValue --
 *
 *	Find the run of "tag data tagName index": the run of the tag
 *	containing the character at the index.
 *
 * Results:
 *	A standard Tcl result; on success *dataPtrPtr is where the
 *	run's data is kept (in its toggle-on).
 *
 * Side effects:
 *	An error message is left in the interpreter.
 *
 *----------------------------------------------------------------------
 */

int
TkBTreeRunValue(textPtr, tagPtr, indexPtr, indexString, dataPtrPtr)
    TkText *textPtr;			/* The widget. */
    TkTextTag *tagPtr;			/* The tag. */
    TkTextIndex *indexPtr;		/* The character. */
    char *indexString;			/* As given, for error messages. */
    TkTextData **dataPtrPtr;		/* Filled in. */
{
    TkTextIndex start;
    TkTextSegment *onPtr = RunAt(textPtr, tagPtr, indexPtr, &start);

    if (onPtr == NULL) {
	Tcl_AppendResult(textPtr->interp, "no run of tag \"", tagPtr->name,
		"\" at ", indexString, NULL);
	return TCL_ERROR;
    }
    *dataPtrPtr = &onPtr->body.toggle.value;
    return TCL_OK;
}

/*
 * The run of a tag at an address (see TkTextValue): its toggle-on,
 * or NULL if the character there does not have the tag; *startPtr is
 * set to its start.
 */

static TkTextSegment *
RunAtAddress(textPtr, tagPtr, line, byteIndex, startPtr)
    TkText *textPtr;
    TkTextTag *tagPtr;
    int line, byteIndex;
    TkTextIndex *startPtr;
{
    TkTextIndex index;

    if ((tagPtr == NULL) || (line < 0) || (byteIndex < 0)
	    || (line >= TkBTreeNumLines(textPtr->tree))) {
	return NULL;
    }
    TkTextMakeByteIndex(textPtr->tree, line, byteIndex, &index);
    if (index.byteIndex != byteIndex) {
	return NULL;
    }
    return RunAt(textPtr, tagPtr, &index, startPtr);
}


/*
 *======================================================================
 *
 * The look-ahead of -valuecommand (TkBTreeVcPredict...).
 *
 *	Before a change that may detach values, while the text is still
 *	as it was, these work out which values the change will detach
 *	and how (dropped, into the undo step, or moved to another owner
 *	by a merge), with the places they have now, and hand them to
 *	TkTextVcPredict (tkText.c), which tells the callback before the
 *	change is made.  They follow the rules of the code that makes
 *	the change (DeleteRange, TkBTreeKillBlockProc, iBTreeDeleteProc,
 *	TkBTreeMakeBlock, TkIBTreeTrim, TagKeepingRuns, DeleteKeepingRuns)
 *	without changing anything; the change itself reports what it
 *	actually detaches (TkTextVcSeen), and a detach not foreseen here
 *	is reported "late".  They do nothing unless the widget command
 *	runs with a -valuecommand (TkTextVcOn).
 *
 *	Places: a node or a leaf by the position where its first leaf
 *	starts and its level (0 for a leaf), as the undo records address
 *	it; a run by its tag and range; a block's instance data by the
 *	position of its head.
 *
 *======================================================================
 */

#define STRICTLY_OVERLAPS(start, end, lo, hi) (((end) > (lo)) && ((start) < (hi)))

static void
VcNode(textPtr, valuePtr, event, line, pos, level, to)
    TkText *textPtr;
    TkTextData *valuePtr;		/* The node's data. */
    int event;				/* 0: a candidate only. */
    int line, pos, level;		/* Its place. */
    Tcl_Obj *to;			/* For a move: the new place. */
{
    if (TkTextDataGetLang(*valuePtr) == NULL) {
	if (to != NULL) {
	    Tcl_DecrRefCount(to);
	}
	return;
    }
    if (event == 0) {
	TkTextVcCandidate(textPtr, *valuePtr, TK_TEXT_VC_NODE,
		TkTextVcNodePlace(textPtr, line, pos, level));
    } else {
	TkTextVcPredict(textPtr, *valuePtr, event, TK_TEXT_VC_NODE,
		TkTextVcNodePlace(textPtr, line, pos, level), to);
    }
}

/*
 * The leaves of a block (the dummy last line left out), with where
 * each starts and where its newline (its separator, or the block's
 * tail) is, in the outer line.
 */

typedef struct VcLeaf {
    TkTextLine *linePtr;
    int ls, nl;
} VcLeaf;

typedef struct VcState {
    TkText *textPtr;
    int line;				/* The outer line (from 0). */
    int lo, hi;				/* The range there, in bytes (hi may
					 * be INT_MAX: to the end of it). */
    int event;				/* TK_TEXT_VC_DROP or _STASH. */
    VcLeaf *leaves;			/* Of the block being looked at. */
    int num, max;
} VcState;

static int		VcDoomedNode _ANSI_ARGS_((VcState *sPtr,
			    Node *nodePtr, int pos));

/*
 * A block that the deletion deletes or dissolves (it holds its head or
 * its tail): all its values go, its instance data included, and those
 * of the blocks nested in it that the range overlaps; the blocks
 * nested in it outside the range keep theirs.
 */

static void
VcDoomedBlock(sPtr, segPtr, pos)
    VcState *sPtr;
    TkTextSegment *segPtr;		/* The block. */
    int pos;				/* Its head. */
{
    if (TkTextDataGetLang(segPtr->body.itree.data) != NULL) {
	TkTextVcPredict(sPtr->textPtr, segPtr->body.itree.data, sPtr->event,
		TK_TEXT_VC_BLOCK, TkTextVcBlockPlace(sPtr->textPtr, sPtr->line,
			pos), NULL);
    }
    if (segPtr->body.itree.tree != NULL) {
	VcDoomedNode(sPtr, ((BTree *) segPtr->body.itree.tree)->rootPtr,
		pos + 1);
    }
}

static int
VcDoomedNode(sPtr, nodePtr, pos)
    VcState *sPtr;
    Node *nodePtr;
    int pos;				/* Where the node starts. */
{
    int start = pos, ls;

    if (nodePtr->level > 0) {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    pos = VcDoomedNode(sPtr, childPtr, pos);
	}
    } else {
	TkTextLine *linePtr;
	TkTextSegment *segPtr;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    if (IsLastLine(linePtr)) {
		continue;
	    }
	    ls = pos;
	    for (segPtr = linePtr->segPtr; segPtr != NULL;
		 segPtr = segPtr->nextPtr) {
		if ((segPtr->typePtr == &tkTextIBTreeType)
			&& STRICTLY_OVERLAPS(pos, pos + segPtr->size,
				sPtr->lo, sPtr->hi)) {
		    VcDoomedBlock(sPtr, segPtr, pos);
		}
		pos += segPtr->size;
	    }
	    VcNode(sPtr->textPtr, &linePtr->value, sPtr->event, sPtr->line,
		    ls, 0, (Tcl_Obj *) NULL);
	}
    }
    VcNode(sPtr->textPtr, &nodePtr->value, sPtr->event, sPtr->line, start,
	    nodePtr->level + 1, (Tcl_Obj *) NULL);
    return pos;
}

/*
 * Collect the leaves of a block; the blocks nested in them that the
 * range overlaps are doomed, unless one holds the whole range inside
 * (then the change happens in there: *innerPtr).
 */

static int
VcLeaves(sPtr, nodePtr, pos, innerPtr, innerPosPtr)
    VcState *sPtr;
    Node *nodePtr;
    int pos;
    TkTextSegment **innerPtr;
    int *innerPosPtr;
{
    if (nodePtr->level > 0) {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    pos = VcLeaves(sPtr, childPtr, pos, innerPtr, innerPosPtr);
	}
    } else {
	TkTextLine *linePtr;
	TkTextSegment *segPtr;
	int ls;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    if (IsLastLine(linePtr)) {
		continue;
	    }
	    ls = pos;
	    for (segPtr = linePtr->segPtr; segPtr != NULL;
		 segPtr = segPtr->nextPtr) {
		if ((segPtr->typePtr == &tkTextIBTreeType)
			&& STRICTLY_OVERLAPS(pos, pos + segPtr->size,
				sPtr->lo, sPtr->hi)) {
		    if ((segPtr->body.itree.tree != NULL) && (pos < sPtr->lo)
			    && (sPtr->hi <= pos + segPtr->size - 1)) {
			*innerPtr = segPtr;
			*innerPosPtr = pos;
		    } else {
			VcDoomedBlock(sPtr, segPtr, pos);
		    }
		}
		pos += segPtr->size;
	    }
	    if (sPtr->num >= sPtr->max) {
		VcLeaf *grown;

		sPtr->max = 2 * sPtr->max + 16;
		grown = (VcLeaf *) ckalloc((unsigned)
			(sPtr->max * sizeof(VcLeaf)));
		if (sPtr->num > 0) {
		    memcpy(grown, sPtr->leaves, sPtr->num * sizeof(VcLeaf));
		}
		if (sPtr->leaves != NULL) {
		    ckfree((char *) sPtr->leaves);
		}
		sPtr->leaves = grown;
	    }
	    sPtr->leaves[sPtr->num].linePtr = linePtr;
	    sPtr->leaves[sPtr->num].ls = ls;
	    sPtr->leaves[sPtr->num].nl = pos - 1;
	    sPtr->num++;
	}
    }
    return pos;
}

static int
VcLeafNumber(sPtr, linePtr)
    VcState *sPtr;
    TkTextLine *linePtr;
{
    int k;

    for (k = 0; k < sPtr->num; k++) {
	if (sPtr->leaves[k].linePtr == linePtr) {
	    return k;
	}
    }
    return -1;
}

/*
 * Where a node starts (its first leaf), or -1.
 */

static int
VcNodeStart(sPtr, nodePtr)
    VcState *sPtr;
    Node *nodePtr;
{
    int k;

    while (nodePtr->level > 0) {
	nodePtr = nodePtr->children.nodePtr;
    }
    k = VcLeafNumber(sPtr, nodePtr->children.linePtr);
    return (k < 0) ? -1 : sPtr->leaves[k].ls;
}

/*
 * The nodes of a block (above the leaves) all of whose leaves are
 * after leaf number "after" and up to leaf number "upTo" (or before it
 * if "upTo" is negative: -(number + 1)): they disappear, with their
 * values.  Returns the number of the next leaf.  Values of the other
 * nodes are candidates (for the place of a late report).
 */

static int
VcDeadNodes(sPtr, nodePtr, k, after, upTo)
    VcState *sPtr;
    Node *nodePtr;
    int k;				/* Number of its first leaf. */
    int after, upTo;
{
    int first = k, last, start = (k < sPtr->num) ? sPtr->leaves[k].ls : 0;
    int dead;

    if (nodePtr->level > 0) {
	Node *childPtr;

	for (childPtr = nodePtr->children.nodePtr; childPtr != NULL;
	     childPtr = childPtr->nextPtr) {
	    k = VcDeadNodes(sPtr, childPtr, k, after, upTo);
	}
    } else {
	TkTextLine *linePtr;

	for (linePtr = nodePtr->children.linePtr; linePtr != NULL;
	     linePtr = linePtr->nextPtr) {
	    if (!IsLastLine(linePtr)) {
		k++;
	    }
	}
    }
    last = k - 1;
    if (last < first) {
	return k;
    }
    dead = (first > after) && ((upTo >= 0) ? (last <= upTo)
	    : (last < -(upTo + 1)));
    VcNode(sPtr->textPtr, &nodePtr->value, dead ? sPtr->event : 0,
	    sPtr->line, start, nodePtr->level + 1, (Tcl_Obj *) NULL);
    return k;
}

/*
 * What is left after the end of a deletion in its last leaf, once the
 * blocks it cuts there are dissolved (see VcContainer): content (the
 * leaf is not deleted whole), the leaf's own newline (it is, if the
 * deletion started in another leaf), or a separator of a dissolved
 * block (it is too, and new leaves follow it in its node); inside a
 * block, its tail, which the dissolution removes.
 */

#define VC_CONTENT	0
#define VC_NEWLINE	1
#define VC_SEPARATOR	2
#define VC_TAILGONE	3

static int		VcEndScanBlock _ANSI_ARGS_((TkTextSegment *segPtr,
			    int pos, int p));

static int
VcEndScanLine(linePtr, ls, p)
    TkTextLine *linePtr;		/* The leaf. */
    int ls;				/* Where it starts. */
    int p;				/* The end of the deletion. */
{
    TkTextSegment *segPtr;
    int pos = ls, r;

    for (segPtr = linePtr->segPtr; segPtr != NULL; segPtr = segPtr->nextPtr) {
	if ((segPtr->typePtr == &tkTextIBTreeType)
		&& (segPtr->body.itree.tree != NULL) && (pos < p)
		&& (p <= pos + segPtr->size - 1)) {
	    r = VcEndScanBlock(segPtr, pos, p);
	    if (r != VC_TAILGONE) {
		return r;
	    }
	    p = pos + segPtr->size;
	}
	pos += segPtr->size;
    }
    return (p == pos - 1) ? VC_NEWLINE : VC_CONTENT;
}

static int
VcEndScanBlock(segPtr, pos, p)
    TkTextSegment *segPtr;		/* A block cut by the end. */
    int pos;				/* Its head. */
    int p;				/* The end of the deletion. */
{
    TkTextLine *linePtr, *nextPtr;
    int ls = pos + 1, len, r;

    for (linePtr = TkBTreeFindLine(segPtr->body.itree.tree, 0);
	 (linePtr != NULL) && !IsLastLine(linePtr); linePtr = nextPtr) {
	len = TkBTreeCharsInLine(linePtr);
	nextPtr = TkBTreeNextLine(linePtr);
	if (p <= ls + len - 1) {
	    r = VcEndScanLine(linePtr, ls, p);
	    if (r == VC_NEWLINE) {
		return ((nextPtr == NULL) || IsLastLine(nextPtr))
			? VC_TAILGONE : VC_SEPARATOR;
	    }
	    return r;
	}
	ls += len;
    }
    return VC_CONTENT;
}

/*
 * The block holding the range inside (neither its head nor its tail
 * in it): look deeper, or else the deletion joins its leaves.
 */

static void
VcContainer(sPtr, segPtr, pos)
    VcState *sPtr;
    TkTextSegment *segPtr;		/* The block. */
    int pos;				/* Its head. */
{
    TkTextSegment *innerPtr = NULL;
    TkTextLine *sLinePtr, *eLinePtr;
    Node *nPtr, *mPtr;
    int innerPos = 0, k, s = -1, e = -1, r, endGone, spliced, gone;

    sPtr->num = 0;
    VcLeaves(sPtr, ((BTree *) segPtr->body.itree.tree)->rootPtr, pos + 1,
	    &innerPtr, &innerPos);
    if (innerPtr != NULL) {
	VcContainer(sPtr, innerPtr, innerPos);
	return;
    }
    for (k = 0; k < sPtr->num; k++) {
	if ((sPtr->leaves[k].ls <= sPtr->lo) && (sPtr->lo <= sPtr->leaves[k].nl)) {
	    s = k;
	}
	if ((sPtr->leaves[k].ls <= sPtr->hi) && (sPtr->hi <= sPtr->leaves[k].nl)) {
	    e = k;
	}
    }
    if ((s < 0) || (e < 0) || (s >= e)) {
	return;				/* Inside one leaf: nothing joins. */
    }
    sLinePtr = sPtr->leaves[s].linePtr;
    eLinePtr = sPtr->leaves[e].linePtr;

    /*
     * The end side's blocks are dissolved first; then, if all that is
     * left of the last leaf after the end is its newline, the last
     * leaf goes whole, else it is joined to the first.
     */

    r = VcEndScanLine(eLinePtr, sPtr->leaves[e].ls, sPtr->hi);
    endGone = (r != VC_CONTENT);
    spliced = (r == VC_SEPARATOR);
    for (k = s + 1; k < e; k++) {
	VcNode(sPtr->textPtr, &sPtr->leaves[k].linePtr->value, sPtr->event,
		sPtr->line, sPtr->leaves[k].ls, 0, (Tcl_Obj *) NULL);
    }
    VcNode(sPtr->textPtr, &sLinePtr->value, 0, sPtr->line,
	    sPtr->leaves[s].ls, 0, (Tcl_Obj *) NULL);
    if (endGone) {
	VcNode(sPtr->textPtr, &eLinePtr->value, sPtr->event, sPtr->line,
		sPtr->leaves[e].ls, 0, (Tcl_Obj *) NULL);
    } else if (!TkTextDataIsEmpty(eLinePtr->value)) {
	if (TkTextDataIsEmpty(sLinePtr->value)) {
	    VcNode(sPtr->textPtr, &eLinePtr->value, TK_TEXT_VC_MOVE,
		    sPtr->line, sPtr->leaves[e].ls, 0,
		    TkTextVcNodePlace(sPtr->textPtr, sPtr->line,
			    sPtr->leaves[s].ls, 0));
	} else {
	    VcNode(sPtr->textPtr, &eLinePtr->value, sPtr->event, sPtr->line,
		    sPtr->leaves[e].ls, 0, (Tcl_Obj *) NULL);
	}
    }

    /*
     * The nodes between the two leaves go; the ancestors of the last
     * leaf below the common ancestor are joined to those of the first
     * on each level, or go whole if all their leaves are in the range
     * (never those that hold the dummy last line: the block's tail).
     */

    VcDeadNodes(sPtr, ((BTree *) segPtr->body.itree.tree)->rootPtr, 0, s,
	    -(e + 1));
    gone = endGone && !spliced && (eLinePtr->nextPtr == NULL);
    for (nPtr = eLinePtr->parentPtr, mPtr = sLinePtr->parentPtr;
	 (nPtr != NULL) && (mPtr != NULL) && (nPtr != mPtr);
	 nPtr = nPtr->parentPtr, mPtr = mPtr->parentPtr) {
	int nStart = VcNodeStart(sPtr, nPtr), mStart = VcNodeStart(sPtr, mPtr);

	if (gone || (!TkTextDataIsEmpty(mPtr->value)
		&& !TkTextDataIsEmpty(nPtr->value))) {
	    VcNode(sPtr->textPtr, &nPtr->value, sPtr->event, sPtr->line,
		    nStart, nPtr->level + 1, (Tcl_Obj *) NULL);
	} else if (!TkTextDataIsEmpty(nPtr->value)) {
	    VcNode(sPtr->textPtr, &nPtr->value, TK_TEXT_VC_MOVE, sPtr->line,
		    nStart, nPtr->level + 1, TkTextVcNodePlace(sPtr->textPtr,
			    sPtr->line, mStart, mPtr->level + 1));
	}
	gone = gone && (nPtr->nextPtr == NULL);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeVcPredictDelete --
 *
 *	The look-ahead of a deletion (TkBTreeDeleteChars of the range in
 *	the outermost tree): node values, instance data of blocks, run
 *	values.
 *
 *----------------------------------------------------------------------
 */

static void		VcDeleteRuns _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    int event));

void
TkBTreeVcPredictDelete(textPtr, index1Ptr, index2Ptr, event)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range (external indices). */
    int event;				/* TK_TEXT_VC_DROP or _STASH. */
{
    VcState s;
    TkTextLine *linePtr;
    TkTextSegment *segPtr;
    int pos, tail;

    if (!TkTextVcOn(textPtr) || !textPtr->haveValues
	    || (TkTextIndexCmp(index1Ptr, index2Ptr) >= 0)) {
	return;
    }
    s.textPtr = textPtr;
    s.event = event;
    s.leaves = NULL;
    s.num = s.max = 0;
    s.line = TkBTreeLineIndex(index1Ptr->linePtr);
    for (linePtr = index1Ptr->linePtr; linePtr != NULL;
	 linePtr = TkBTreeNextLine(linePtr), s.line++) {
	s.lo = (linePtr == index1Ptr->linePtr) ? index1Ptr->byteIndex : 0;
	s.hi = (linePtr == index2Ptr->linePtr) ? index2Ptr->byteIndex : INT_MAX;
	pos = 0;
	for (segPtr = linePtr->segPtr; segPtr != NULL;
	     segPtr = segPtr->nextPtr) {
	    if ((segPtr->typePtr == &tkTextIBTreeType)
		    && STRICTLY_OVERLAPS(pos, pos + segPtr->size, s.lo, s.hi)) {
		tail = pos + segPtr->size - 1;
		if ((segPtr->body.itree.tree != NULL) && (pos < s.lo)
			&& (s.hi <= tail)) {
		    VcContainer(&s, segPtr, pos);
		} else {
		    VcDoomedBlock(&s, segPtr, pos);
		}
	    }
	    pos += segPtr->size;
	}
	if (linePtr == index2Ptr->linePtr) {
	    break;
	}
    }
    if (s.leaves != NULL) {
	ckfree((char *) s.leaves);
    }
    VcDeleteRuns(textPtr, index1Ptr, index2Ptr, event);
    TkTextVcNotify(textPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeVcPredictBlock --
 *
 *	The look-ahead of "block insert" (TkBTreeMakeBlock) inside a
 *	block over several leaves: the leaves between the first and the
 *	last move whole into the new block with their values; the part
 *	of the last leaf after index2 joins the first leaf (the merge
 *	policy, unless nothing but its newline is there: then all of it
 *	moves); the nodes all of whose leaves move go.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeVcPredictBlock(textPtr, index1Ptr, index2Ptr, event)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range (external indices). */
    int event;				/* TK_TEXT_VC_DROP or _STASH. */
{
    TkTextIndex int1, int2, head;
    TkTextLine *sLinePtr, *eLinePtr;
    TkTextSegment *segPtr;
    TkTextSegment *innerPtr = NULL;
    VcState s;
    int k1, k2, innerPos, wholeFirst, lastWhole;

    if (!TkTextVcOn(textPtr) || !textPtr->haveValues
	    || (TkTextIndexCmp(index1Ptr, index2Ptr) >= 0)) {
	return;
    }
    TkTextIndexToInternalSeg(index1Ptr, &int1, NULL);
    TkTextIndexToInternalSeg(index2Ptr, &int2, NULL);
    sLinePtr = int1.linePtr;
    eLinePtr = int2.linePtr;
    segPtr = sLinePtr->parentPtr->segPtr;
    if ((segPtr == NULL) || (segPtr != eLinePtr->parentPtr->segPtr)
	    || (sLinePtr == eLinePtr)) {
	return;				/* Outside blocks, an error, or
					 * inside one leaf: nothing goes. */
    }
    TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
    s.textPtr = textPtr;
    s.event = event;
    s.leaves = NULL;
    s.num = s.max = 0;
    s.line = TkBTreeLineIndex(head.linePtr);
    s.lo = s.hi = -1;			/* No nested block is touched. */
    VcLeaves(&s, ((BTree *) segPtr->body.itree.tree)->rootPtr,
	    head.byteIndex + 1, &innerPtr, &innerPos);
    k1 = VcLeafNumber(&s, sLinePtr);
    k2 = VcLeafNumber(&s, eLinePtr);
    if ((k1 >= 0) && (k2 > k1)) {
	wholeFirst = (int1.byteIndex == 0);
	lastWhole = (int2.byteIndex >= TkBTreeCharsInLine(eLinePtr) - 1);
	if (!lastWhole && !TkTextDataIsEmpty(eLinePtr->value)) {
	    if (wholeFirst || TkTextDataIsEmpty(sLinePtr->value)) {
		VcNode(textPtr, &eLinePtr->value, TK_TEXT_VC_MOVE, s.line,
			s.leaves[k2].ls, 0, TkTextVcNodePlace(textPtr, s.line,
				s.leaves[k1].ls, 0));
	    } else {
		VcNode(textPtr, &eLinePtr->value, event, s.line,
			s.leaves[k2].ls, 0, (Tcl_Obj *) NULL);
	    }
	}
	VcDeadNodes(&s, ((BTree *) segPtr->body.itree.tree)->rootPtr, 0, k1,
		k2);
    }
    if (s.leaves != NULL) {
	ckfree((char *) s.leaves);
    }
    TkTextVcNotify(textPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeVcPredictTrim --
 *
 *	The look-ahead of "block trim" (TkIBTreeTrim): the root and its
 *	only child become one node, which keeps the root's data if it
 *	has any; the child's is then dropped.
 *
 *----------------------------------------------------------------------
 */

void
TkBTreeVcPredictTrim(textPtr, segPtr, event)
    TkText *textPtr;			/* The widget. */
    TkTextSegment *segPtr;		/* The block. */
    int event;				/* TK_TEXT_VC_DROP or _STASH. */
{
    Node *rootPtr, *childPtr;
    TkTextIndex head;

    if (!TkTextVcOn(textPtr) || (segPtr->typePtr != &tkTextIBTreeType)
	    || (segPtr->body.itree.tree == NULL)) {
	return;
    }
    rootPtr = ((BTree *) segPtr->body.itree.tree)->rootPtr;
    if ((rootPtr->level < 1) || (rootPtr->numChildren > 1)) {
	return;				/* An error: nothing changes. */
    }
    childPtr = rootPtr->children.nodePtr;
    if (!TkTextDataIsEmpty(rootPtr->value)
	    && !TkTextDataIsEmpty(childPtr->value)) {
	TkIBTreeStartIndex(textPtr->tree, segPtr, &head);
	VcNode(textPtr, &childPtr->value, event,
		TkBTreeLineIndex(head.linePtr), head.byteIndex + 1,
		childPtr->level + 1, (Tcl_Obj *) NULL);
    }
    TkTextVcNotify(textPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * The runs: where a run ends; the place of the run of a tag at an
 * index; the look-ahead of "tag add" and "tag remove" (TagKeepingRuns)
 * and of a deletion (DeleteKeepingRuns).
 *
 *----------------------------------------------------------------------
 */

static void
VcRunEnd(textPtr, tagPtr, startPtr, endPtr)
    TkText *textPtr;
    TkTextTag *tagPtr;
    TkTextIndex *startPtr;		/* The toggle-on of the run. */
    TkTextIndex *endPtr;		/* Filled in. */
{
    TkTextIndex last;
    TkTextSearch search;

    TextEnd(textPtr, &last);
    *endPtr = last;
    TkBTreeStartSearch(startPtr, &last, tagPtr, &search);
    while (TkBTreeNextTag(&search)) {
	if ((search.segPtr->typePtr == &tkTextToggleOffType)
		&& (TkTextIndexCmp(&search.extIndex, startPtr) > 0)) {
	    *endPtr = search.extIndex;
	    return;
	}
    }
}

Tcl_Obj *
TkBTreeVcRunPlace(textPtr, tagPtr, indexPtr)
    TkText *textPtr;
    TkTextTag *tagPtr;
    TkTextIndex *indexPtr;		/* A character of the run. */
{
    TkTextIndex start, end;

    if (RunAt(textPtr, tagPtr, indexPtr, &start) == NULL) {
	return NULL;
    }
    VcRunEnd(textPtr, tagPtr, &start, &end);
    return TkTextVcRunPlace(textPtr, tagPtr->name, &start, &end);
}

static void
VcRun(textPtr, runPtr, event, toPtr)
    TkText *textPtr;
    RunSave *runPtr;			/* The run (before the change). */
    int event;				/* 0: a candidate. */
    RunSave *toPtr;			/* For a move: the run it joins. */
{
    TkTextData value = runPtr->onPtr->body.toggle.value;

    if (TkTextDataGetLang(value) == NULL) {
	return;
    }
    if (event == 0) {
	TkTextVcCandidate(textPtr, value, TK_TEXT_VC_RUN,
		TkTextVcRunPlace(textPtr, runPtr->tagPtr->name,
			&runPtr->start, &runPtr->end));
    } else {
	TkTextVcPredict(textPtr, value, event, TK_TEXT_VC_RUN,
		TkTextVcRunPlace(textPtr, runPtr->tagPtr->name,
			&runPtr->start, &runPtr->end),
		(toPtr == NULL) ? NULL : TkTextVcRunPlace(textPtr,
			toPtr->tagPtr->name, &toPtr->start, &toPtr->end));
    }
}

/*
 * Runs that become one (a list in order, survivors only): the first
 * keeps its value; else the first value present moves to it; the
 * values after that one are dropped.
 */

static void
VcRunGroup(textPtr, runs, num, event)
    TkText *textPtr;
    RunSave **runs;
    int num;
    int event;
{
    int k, winner = -1;

    for (k = 0; k < num; k++) {
	if (TkTextDataIsEmpty(runs[k]->onPtr->body.toggle.value)) {
	    continue;
	}
	if (winner >= 0) {
	    VcRun(textPtr, runs[k], event, (RunSave *) NULL);
	} else {
	    winner = k;
	    if (k > 0) {
		VcRun(textPtr, runs[k], TK_TEXT_VC_MOVE, runs[0]);
	    } else {
		VcRun(textPtr, runs[k], 0, (RunSave *) NULL);
	    }
	}
    }
}

void
TkBTreeVcPredictTag(textPtr, index1Ptr, index2Ptr, tagPtr, add)
    TkText *textPtr;			/* The widget. */
    TkTextIndex *index1Ptr, *index2Ptr;	/* The range. */
    TkTextTag *tagPtr;			/* The tag. */
    int add;				/* 1 for tag add, 0 for tag remove. */
{
    RunList list;
    RunSave **group;
    int i, event;

    if (!TkTextVcOn(textPtr) || !tagPtr->hasRunValues
	    || (TkTextIndexCmp(index1Ptr, index2Ptr) >= 0)) {
	return;
    }
    event = (textPtr->valueCapture != NULL) ? TK_TEXT_VC_STASH
	    : TK_TEXT_VC_DROP;
    list.runs = NULL;
    list.num = list.max = 0;
    CollectRuns(textPtr, tagPtr, index1Ptr, index2Ptr, &list);
    if (add) {
	/*
	 * Every run collected touches the range: all become one.
	 */

	group = (RunSave **) ckalloc((unsigned)
		((list.num + 1) * sizeof(RunSave *)));
	for (i = 0; i < list.num; i++) {
	    group[i] = &list.runs[i];
	}
	VcRunGroup(textPtr, group, list.num, event);
	ckfree((char *) group);
    } else {
	for (i = 0; i < list.num; i++) {
	    RunSave *runPtr = &list.runs[i];

	    VcRun(textPtr, runPtr,
		    ((TkTextIndexCmp(&runPtr->start, index1Ptr) >= 0)
			    && (TkTextIndexCmp(&runPtr->end, index2Ptr) <= 0))
		    ? event : 0, (RunSave *) NULL);
	}
    }
    if (list.runs != NULL) {
	ckfree((char *) list.runs);
    }
    TkTextVcNotify(textPtr);
}

/*
 * For a deletion: what disappears is the range and, of the blocks it
 * cuts, their heads before it and their tails after it.  A position
 * as (line, byte).
 */

typedef struct VcCut {
    int l1, b1, l2, b2;			/* The range. */
    int e1;				/* Byte of ext1 (on line l1). */
    int *cuts, numHeads, numTails;	/* TkIBTreeCutPositions. */
} VcCut;

#define VC_CMP(la, ba, lb, bb) \
	(((la) != (lb)) ? (((la) < (lb)) ? -1 : 1) \
	 : (((ba) < (bb)) ? -1 : (((ba) > (bb)) ? 1 : 0)))

static int
VcCutPoint(cPtr, line, byte)
    VcCut *cPtr;
    int line, byte;
{
    int i;

    if ((line == cPtr->l1) && (VC_CMP(line, byte, cPtr->l1, cPtr->b1) < 0)) {
	for (i = 0; i < cPtr->numHeads; i++) {
	    if (cPtr->e1 + cPtr->cuts[i] == byte) {
		return 1;
	    }
	}
    }
    if ((line == cPtr->l2) && (VC_CMP(line, byte, cPtr->l2, cPtr->b2) >= 0)) {
	for (i = 0; i < cPtr->numTails; i++) {
	    if (cPtr->b2 + cPtr->cuts[cPtr->numHeads + i] == byte) {
		return 1;
	    }
	}
    }
    return 0;
}

/*
 * Whether everything from a to b disappears.
 */

static int
VcAllGone(cPtr, aPtr, bPtr)
    VcCut *cPtr;
    TkTextIndex *aPtr, *bPtr;
{
    int line = TkBTreeLineIndex(aPtr->linePtr), byte = aPtr->byteIndex;
    int lb = TkBTreeLineIndex(bPtr->linePtr), bb = bPtr->byteIndex;

    while (VC_CMP(line, byte, lb, bb) < 0) {
	if ((VC_CMP(line, byte, cPtr->l1, cPtr->b1) >= 0)
		&& (VC_CMP(line, byte, cPtr->l2, cPtr->b2) < 0)) {
	    line = cPtr->l2;
	    byte = cPtr->b2;
	} else if (VcCutPoint(cPtr, line, byte)) {
	    byte++;
	} else {
	    return 0;
	}
    }
    return 1;
}

static void
VcDeleteRuns(textPtr, index1Ptr, index2Ptr, event)
    TkText *textPtr;
    TkTextIndex *index1Ptr, *index2Ptr;
    int event;
{
    TkTextIndex ext1, ext2;
    Tcl_HashEntry *hPtr;
    Tcl_HashSearch search;
    RunList list;
    RunSave **group;
    VcCut cut;
    int i, num, remains, prev;

    if (TkIBTreeCutRange(index1Ptr, index2Ptr, &ext1, &ext2, &remains) == 0) {
	ext1 = *index1Ptr;
	ext2 = *index2Ptr;
	cut.cuts = NULL;
	cut.numHeads = cut.numTails = 0;
    } else {
	cut.cuts = TkIBTreeCutPositions(index1Ptr, index2Ptr, &ext1,
		&cut.numHeads, &cut.numTails);
    }
    cut.l1 = TkBTreeLineIndex(index1Ptr->linePtr);
    cut.b1 = index1Ptr->byteIndex;
    cut.l2 = TkBTreeLineIndex(index2Ptr->linePtr);
    cut.b2 = index2Ptr->byteIndex;
    cut.e1 = ext1.byteIndex;
    list.runs = NULL;
    list.num = list.max = 0;
    for (hPtr = Tcl_FirstHashEntry(&textPtr->tagTable, &search);
	    hPtr != NULL; hPtr = Tcl_NextHashEntry(&search)) {
	TkTextTag *tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);

	if (!tagPtr->hasRunValues) {
	    continue;
	}
	list.num = 0;
	CollectRuns(textPtr, tagPtr, &ext1, &ext2, &list);
	group = (RunSave **) ckalloc((unsigned)
		((list.num + 1) * sizeof(RunSave *)));
	num = 0;
	prev = -1;
	for (i = 0; i < list.num; i++) {
	    RunSave *runPtr = &list.runs[i];

	    if (VcAllGone(&cut, &runPtr->start, &runPtr->end)) {
		VcRun(textPtr, runPtr, event, (RunSave *) NULL);
		continue;
	    }
	    if ((prev >= 0) && !VcAllGone(&cut, &list.runs[prev].end,
		    &runPtr->start)) {
		VcRunGroup(textPtr, group, num, event);
		num = 0;
	    }
	    group[num++] = runPtr;
	    prev = i;
	}
	VcRunGroup(textPtr, group, num, event);
	ckfree((char *) group);
    }
    if (list.runs != NULL) {
	ckfree((char *) list.runs);
    }
    if (cut.cuts != NULL) {
	ckfree((char *) cut.cuts);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkBTreeVcNodePlace --
 *
 *	The place of the node of "block nodedata index level" (as the
 *	notification gives it: where its first leaf starts, and its level
 *	counted from the leaves), or NULL on an error.
 *
 *----------------------------------------------------------------------
 */

Tcl_Obj *
TkBTreeVcNodePlace(textPtr, indexPtr, levelArg)
    TkText *textPtr;
    TkTextIndex *indexPtr;
    Arg levelArg;
{
    TkTextIndex intIndex, ext;
    TkTextLine *linePtr;
    Node *nodePtr;
    int level, above, i;

    TkTextIndexToInternalSeg(indexPtr, &intIndex, NULL);
    linePtr = intIndex.linePtr;
    if ((linePtr->parentPtr->segPtr == NULL)
	    || (Tcl_GetIntFromObj(NULL, levelArg, &level) != TCL_OK)) {
	return NULL;
    }
    above = ((BTree *) linePtr->parentPtr->segPtr->body.itree.tree)
	    ->rootPtr->level + 1;
    if (level < 0) {
	level += above + 1;
    }
    if ((level < 0) || (level > above)) {
	return NULL;
    }
    if (level > 0) {
	for (nodePtr = linePtr->parentPtr, i = level; i > 1; i--) {
	    nodePtr = nodePtr->parentPtr;
	}
	while (nodePtr->level > 0) {
	    nodePtr = nodePtr->children.nodePtr;
	}
	linePtr = nodePtr->children.linePtr;
    }
    intIndex.linePtr = linePtr;
    intIndex.byteIndex = 0;
    TkTextIndexToExternalIndex(textPtr->tree, &intIndex, &ext);
    return TkTextVcNodePlace(textPtr, TkBTreeLineIndex(ext.linePtr),
	    ext.byteIndex, level);
}


/* Dumping routines */
void DumpTree _ANSI_ARGS_((TkTextBTree tree));
void DumpSegment _ANSI_ARGS_((TkTextSegment *segPtr));
void DumpSegments _ANSI_ARGS_((TkTextSegment *segPtr));
void DumpLine _ANSI_ARGS_((TkTextLine *segPtr));
void DumpNode _ANSI_ARGS_((Node *segPtr));

void
DumpSegment(segPtr)
     TkTextSegment *segPtr;
{
  if (segPtr->typePtr == &tkTextCharType) {
    printf("chars = \"%s\"\n", segPtr->body.chars);
  } else if (segPtr->typePtr == &tkTextToggleOnType) {
    printf("tag on \"%s\"\n", segPtr->body.toggle.tagPtr->name);
  } else if (segPtr->typePtr == &tkTextToggleOffType) {
    printf("tag off \"%s\"\n", segPtr->body.toggle.tagPtr->name);
  } else if (segPtr->typePtr == &tkTextLeftMarkType) {
    printf("leftmark \"%s\"\n", 
	   Tcl_GetHashKey(&segPtr->body.mark.textPtr->markTable, 
			  segPtr->body.mark.hPtr)
	   );
  } else if (segPtr->typePtr == &tkTextRightMarkType) {
    printf("rightmark \"%s\"\n", 
	   Tcl_GetHashKey(&segPtr->body.mark.textPtr->markTable, 
			  segPtr->body.mark.hPtr)
	   );
  } else if (segPtr->typePtr == &tkTextIBTreeType) {
    printf("IBTree, length %i, name \"%s\"\n", 
	   segPtr->size, segPtr->body.itree.blockPtr->name);
    DumpTree(segPtr->body.itree.tree);
  } else {
    printf("Unknown type!\n");
  }
}
void
DumpSegments(segPtr)
     TkTextSegment *segPtr;
{
  while (segPtr) {
    DumpSegment(segPtr);
    segPtr = segPtr->nextPtr;
  }
}
void
DumpLine(linePtr)
     TkTextLine *linePtr;
{
  printf("Line start\n");
  DumpSegments(linePtr->segPtr);
  printf("Line end\n");
}
void
DumpNode(nodePtr)
     Node *nodePtr;
{
  int level = nodePtr->level;
  printf("Node start, level %i, %s\n", level, 
	 nodePtr->segPtr ? "internal" : "external");
  if (nodePtr->level) {
    nodePtr = nodePtr->children.nodePtr;
    while (nodePtr) {
      DumpNode(nodePtr);
      nodePtr = nodePtr->nextPtr;
    }
  } else {
    TkTextLine *linePtr = nodePtr->children.linePtr;
    while (linePtr) {
      DumpLine(linePtr);
      linePtr = linePtr->nextPtr;
    }
  }
  printf("Node end, level %i\n", level);
}
void
DumpTree(tree)
     TkTextBTree tree;
{
  if (tree) {
    DumpNode(((BTree*)tree)->rootPtr);
  }
}
