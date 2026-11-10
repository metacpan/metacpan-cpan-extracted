/*
 * tkText.h --
 *
 *	Declarations shared among the files that implement text
 *	widgets.
 *
 * Copyright (c) 1992-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 * Copyright (c) 1995 Ilya Zakharevich.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * SCCS: @(#) tkText.h 1.44 96/02/15 18:51:31
 *
 *
 *
 *
 *
 * 
 * $Id: tkText.h,v 1.27 1996/03/12 00:09:15 ilya Exp $
 *
 * 
 */

#ifndef _TKTEXT
#define _TKTEXT

#ifndef LangIsPerl
#  include "ptcl.h"
#  define TEXT_Class "Text"
#  define IdType(id,type) id
#else
#  include "pperl.h"
#  define TEXT_Class "eText"
#  define IdType(id,type) type
#endif 

#ifndef _TK
#include "tk.h"
#endif

#include "tkTextData.h"		/* The containers of values (TkTextData);
				 * their operations are at the end. */


/*
 * Opaque types for structures whose guts are only needed by a single
 * file:
 */

typedef struct TkTextBTree *TkTextBTree;

/*
 * The data structure below defines a single line of text (from newline
 * to newline, not necessarily what appears on one line of the screen).
 */

typedef struct TkTextLine {
    struct Node *parentPtr;		/* Pointer to parent node containing
					 * line. */
    struct TkTextLine *nextPtr;		/* Next in linked list of lines with
					 * same parent node in B-tree.  NULL
					 * means end of list. */
    struct TkTextSegment *segPtr;	/* First in ordered list of segments
					 * that make up the line. */
    TkTextData value;			/* The data of the line as a leaf of
					 * a block (its Lang part: "block
					 * nodedata"), owned by the line;
					 * empty if none.  Always empty
					 * outside blocks. */
} TkTextLine;

/*
 * -----------------------------------------------------------------------
 * Segments: each line is divided into one or more segments, where each
 * segment is one of several things, such as a group of characters, a
 * tag toggle, a mark, or an embedded widget.  Each segment starts with
 * a standard header followed by a body that varies from type to type.
 * -----------------------------------------------------------------------
 */

/*
 * The data structure below defines the body of a segment that represents
 * a tag toggle.  There is one of these structures at both the beginning
 * and end of each tagged range.
 */

typedef struct TkTextToggle {
    struct TkTextTag *tagPtr;		/* Tag that starts or ends here. */
    int inNodeCounts;			/* 1 means this toggle has been
					 * accounted for in node toggle
					 * counts; 0 means it hasn't, yet. */
    TkTextData value;			/* For a toggle-on: the data of the
					 * run of the tag it starts (its Lang
					 * part: "tag data"), owned by the
					 * segment; empty if none (always for
					 * a toggle-off). */
} TkTextToggle;

/*
 * The data structure below defines line segments that represent
 * marks.  There is one of these for each mark in the text.
 */

typedef struct TkTextMark {
    struct TkText *textPtr;		/* Overall information about text
					 * widget. */
    TkTextLine *linePtr;		/* Line structure that contains the
					 * segment. */
    Tcl_HashEntry *hPtr;		/* Pointer to hash table entry for mark
					 * (in textPtr->markTable). */
    TkTextData value;			/* The mark's data (its Lang part:
					 * "mark data"), owned by the mark;
					 * empty if none. */
} TkTextMark;

/*
 * A structure of the following type holds information for each window
 * embedded in a text widget.  This information is only used by the
 * file tkTextWind.c
 */

typedef struct TkTextEmbWindow {
    struct TkText *textPtr;		/* Information about the overall text
					 * widget. */
    TkTextLine *linePtr;		/* Line structure that contains this
					 * window. */
    Tk_Window tkwin;			/* Window for this segment.  NULL
					 * means that the window hasn't
					 * been created yet. */
    LangCallback *create;		/* Script to create window on-demand.
					 * NULL means no such script.
					 * Malloc-ed. */
    int align;				/* How to align window in vertical
					 * space.  See definitions in
					 * tkTextWind.c. */
    int padX, padY;			/* Padding to leave around each side
					 * of window, in pixels. */
    int stretch;			/* Should window stretch to fill
					 * vertical space of line (except for
					 * pady)?  0 or 1. */
    int chunkCount;			/* Number of display chunks that
					 * refer to this window. */
    int displayed;			/* Non-zero means that the window
					 * has been displayed on the screen
					 * recently. */
} TkTextEmbWindow;


/*
 * A structure of the following type holds information for each image
 * embedded in a text widget.  This information is only used by the
 * file tkTextImage.c
 */

typedef struct TkTextEmbImage {
    struct TkText *textPtr;		/* Information about the overall text
					 * widget. */
    TkTextLine *linePtr;		/* Line structure that contains this
					 * image. */
    char *imageString;			/* Name of the image for this segment */
    char *imageName;			/* Name used by text widget to identify
    					 * this image.  May be unique-ified */
    char *name;				/* Name used in the hash table.
    					 * used by "image names" to identify
    					 * this instance of the image */
    Tk_Image image;			/* Image for this segment.  NULL
					 * means that the image hasn't
					 * been created yet. */
    int align;				/* How to align image in vertical
					 * space.  See definitions in
					 * tkTextImage.c. */
    int padX, padY;			/* Padding to leave around each side
					 * of image, in pixels. */
    int chunkCount;			/* Number of display chunks that
					 * refer to this image. */
} TkTextEmbImage;

/*
 * The data structure below defines line segments that represent
 * internal BTrees.  There is one of these for each tree in the text.
 */

typedef struct TkTextITree {
    /*struct TkText *textPtr;*/		/* Overall information about text
					 * widget. */
    TkTextLine *linePtr;		/* Line structure that contains the
					 * segment. */
    TkTextBTree tree;			/* Pointer to root of the
					 * BTree. */
    struct TkTextBlock *blockPtr;	/* Description of the block. */
    int counted;			/* Whether the tags inside are
					 * counted in the ambient node. */
    struct TkTextSegment *next2delete;	/* Used during deletion. */
    TkTextData data;			/* Instance data (its Lang part:
					 * "block data"), owned by the
					 * segment; empty if none. */
} TkTextITree;

/*
 * The data structure below defines line segments.
 */

typedef struct TkTextSegment {
    struct Tk_SegType *typePtr;		/* Pointer to record describing
					 * segment's type. */
    struct TkTextSegment *nextPtr;	/* Next in list of segments for this
					 * line, or NULL for end of list. */
    int size;				/* Size of this segment (# of bytes
					 * of index space it occupies). */
    union {
	char chars[4];			/* Characters that make up character
					 * info.  Actual length varies to
					 * hold as many characters as needed.*/
	TkTextToggle toggle;		/* Information about tag toggle. */
	TkTextMark mark;		/* Information about mark. */
	TkTextEmbWindow ew;		/* Information about embedded
					 * window. */
	TkTextEmbImage ei;		/* Information about embedded
					 * image. */
	TkTextITree itree;		/* Information about internal tree. */
    } body;
} TkTextSegment;

/*
 * Data structures of the type defined below are used during the
 * execution of Tcl commands to keep track of various interesting
 * places in a text.  An index is only valid up until the next
 * modification to the character structure of the b-tree so they
 * can't be retained across Tcl commands.  However, mods to marks
 * or tags don't invalidate indices.
 */

typedef struct TkTextIndex {
    TkTextBTree tree;			/* Tree containing desired position. */
    TkTextLine *linePtr;		/* Pointer to line containing position
					 * of interest. */
    int byteIndex;			/* Byte offset within line of the desired
					 * character (0 means first one).  The
					 * index space of a block (IBTree segment)
					 * counts as segPtr->size bytes, as do
					 * windows and images.  User-visible
					 * "line.char" indices count UTF-8
					 * characters; see tkTextIndex.c. */
} TkTextIndex;

/*
 * Types for procedure pointers stored in TkTextDispChunk strutures:
 */

typedef struct TkTextDispChunk TkTextDispChunk;

typedef void 		Tk_ChunkDisplayProc _ANSI_ARGS_((
			    TkTextDispChunk *chunkPtr, int x, int y,
			    int height, int baseline, Display *display,
			    Drawable dst, int screenY));
typedef void		Tk_ChunkUndisplayProc _ANSI_ARGS_((
			    struct TkText *textPtr,
			    TkTextDispChunk *chunkPtr));
typedef int		Tk_ChunkMeasureProc _ANSI_ARGS_((
			    TkTextDispChunk *chunkPtr, int x, int y));
typedef void		Tk_ChunkBboxProc _ANSI_ARGS_((
			    TkTextDispChunk *chunkPtr, int index, int y,
			    int lineHeight, int baseline, int *xPtr,
			    int *yPtr, int *widthPtr, int *heightPtr));

/*
 * The structure below represents a chunk of stuff that is displayed
 * together on the screen.  This structure is allocated and freed by
 * generic display code but most of its fields are filled in by
 * segment-type-specific code.
 */

struct TkTextDispChunk {
    /*
     * The fields below are set by the type-independent code before
     * calling the segment-type-specific layoutProc.  They should not
     * be modified by segment-type-specific code.
     */

    int x;				/* X position of chunk, in pixels.
					 * This position is measured from the
					 * left edge of the logical line,
					 * not from the left edge of the
					 * window (i.e. it doesn't change
					 * under horizontal scrolling). */
    struct TkTextDispChunk *nextPtr;	/* Next chunk in the display line
					 * or NULL for the end of the list. */
    struct TextStyle *stylePtr;		/* Display information, known only
					 * to tkTextDisp.c. */

    /*
     * The fields below are set by the layoutProc that creates the
     * chunk.
     */

    Tk_ChunkDisplayProc *displayProc;	/* Procedure to invoke to draw this
					 * chunk on the display or an
					 * off-screen pixmap. */
    Tk_ChunkUndisplayProc *undisplayProc;
					/* Procedure to invoke when segment
					 * ceases to be displayed on screen
					 * anymore. */
    Tk_ChunkMeasureProc *measureProc;	/* Procedure to find character under
					 * a given x-location. */
    Tk_ChunkBboxProc *bboxProc;		/* Procedure to find bounding box
					 * of character in chunk. */
    int numChars;			/* Number of characters that will be
					 * displayed in the chunk. */
    int minAscent;			/* Minimum space above the baseline
					 * needed by this chunk. */
    int minDescent;			/* Minimum space below the baseline
					 * needed by this chunk. */
    int minHeight;			/* Minimum total line height needed
					 * by this chunk. */
    int width;				/* Width of this chunk, in pixels.
					 * Initially set by chunk-specific
					 * code, but may be increased to
					 * include tab or extra space at end
					 * of line. */
    int breakIndex;			/* Index within chunk of last
					 * acceptable position for a line
					 * (break just before this character).
					 * <= 0 means don't break during or
					 * immediately after this chunk. */
    ClientData clientData;		/* Additional information for use
					 * of displayProc and undisplayProc. */
};

/*
 * One data structure of the following type is used for each tag in a
 * text widget.  These structures are kept in textPtr->tagTable and
 * referred to in other structures.
 */

typedef struct TkTextTag {
    char *name;			/* Name of this tag.  This field is actually
				 * a pointer to the key from the entry in
				 * textPtr->tagTable, so it needn't be freed
				 * explicitly. */
    int priority;		/* Priority of this tag within widget.  0
				 * means lowest priority.  Exactly one tag
				 * has each integer value between 0 and
				 * numTags-1. */
    struct Node *tagRootPtr;	/* Pointer into the B-Tree at the lowest
				 * node that completely dominates the ranges
				 * of text occupied by the tag.  At this
				 * node there is no information about the
				 * tag.  One or more children of the node
				 * do contain information about the tag. */
    int toggleCount;		/* Total number of tag toggles */
    struct TkText *textPtr;	/* The widget the tag belongs to. */
    int hasRunValues;		/* Non-zero once a run of the tag has been
				 * given a value ("tag data"): only then do
				 * changes have to look after run values. */

    /*
     * Information for displaying text with this tag.  The information
     * belows acts as an override on information specified by lower-priority
     * tags.  If no value is specified, then the next-lower-priority tag
     * on the text determins the value.  The text widget itself provides
     * defaults if no tag specifies an override.
     */

    Tk_3DBorder border;		/* Used for drawing background.  NULL means
				 * no value specified here. */
    char *bdString;		/* -borderwidth option string (malloc-ed).
				 * NULL means option not specified. */
    int borderWidth;		/* Width of 3-D border for background. */
    char *reliefString;		/* -relief option string (malloc-ed).
				 * NULL means option not specified. */
    int relief;			/* 3-D relief for background. */
    Pixmap bgStipple;		/* Stipple bitmap for background.  None
				 * means no value specified here. */
    XColor *fgColor;		/* Foreground color for text.  NULL means
				 * no value specified here. */
    Tk_Font tkfont;	/* Font for displaying text.  NULL means
				 * no value specified here. */
    Pixmap fgStipple;		/* Stipple bitmap for text and other
				 * foreground stuff.   None means no value
				 * specified here.*/
    char *justifyString;	/* -justify option string (malloc-ed).
				 * NULL means option not specified. */
    Tk_Justify justify;		/* How to justify text: TK_JUSTIFY_LEFT,
				 * TK_JUSTIFY_RIGHT, or TK_JUSTIFY_CENTER.
				 * Only valid if justifyString is non-NULL. */
    char *lMargin1String;	/* -lmargin1 option string (malloc-ed).
				 * NULL means option not specified. */
    int lMargin1;		/* Left margin for first display line of
				 * each text line, in pixels.  Only valid
				 * if lMargin1String is non-NULL. */
    char *lMargin2String;	/* -lmargin2 option string (malloc-ed).
				 * NULL means option not specified. */
    int lMargin2;		/* Left margin for second and later display
				 * lines of each text line, in pixels.  Only
				 * valid if lMargin2String is non-NULL. */
    char *offsetString;		/* -offset option string (malloc-ed).
				 * NULL means option not specified. */
    int offset;			/* Vertical offset of text's baseline from
				 * baseline of line.  Used for superscripts
				 * and subscripts.  Only valid if
				 * offsetString is non-NULL. */
    Arg overstrikeString;	/* -overstrike option string (malloc-ed).
				 * NULL means option not specified. */
    int overstrike;		/* Non-zero means draw horizontal line through
				 * middle of text.  Only valid if
				 * overstrikeString is non-NULL. */
    char *rMarginString;	/* -rmargin option string (malloc-ed).
				 * NULL means option not specified. */
    int rMargin;		/* Right margin for text, in pixels.  Only
				 * valid if rMarginString is non-NULL. */
    char *spacing1String;	/* -spacing1 option string (malloc-ed).
				 * NULL means option not specified. */
    int spacing1;		/* Extra spacing above first display
				 * line for text line.  Only valid if
				 * spacing1String is non-NULL. */
    char *spacing2String;	/* -spacing2 option string (malloc-ed).
				 * NULL means option not specified. */
    int spacing2;		/* Extra spacing between display
				 * lines for the same text line.  Only valid
				 * if spacing2String is non-NULL. */
    char *spacing3String;	/* -spacing2 option string (malloc-ed).
				 * NULL means option not specified. */
    int spacing3;		/* Extra spacing below last display
				 * line for text line.  Only valid if
				 * spacing3String is non-NULL. */
    Arg tabString;		/* -tabs option string (malloc-ed).
				 * NULL means option not specified. */
    struct TkTextTabArray *tabArrayPtr;
				/* Info about tabs for tag (malloc-ed)
				 * or NULL.  Corresponds to tabString. */
    Arg underlineString;	/* -underline option string (malloc-ed).
				 * NULL means option not specified. */
    int underline;		/* Non-zero means draw underline underneath
				 * text.  Only valid if underlineString is
				 * non-NULL. */
    Arg elideString;		/* -elide option string (malloc-ed).
				 * NULL means option not specified. */
    int elide;			/* Non-zero means that text under this tag
				 * is not displayed.  Only valid if
				 * elideString is non-NULL. */
    Tk_Uid wrapMode;		/* How to handle wrap-around for this tag.
				 * Must be tkTextCharUid, tkTextNoneUid,
				 * tkTextWordUid, or NULL to use wrapMode
				 * for whole widget. */
    int affectsDisplay;		/* Non-zero means that this tag affects the
				 * way information is displayed on the screen
				 * (so need to redisplay if tag changes). */
    Arg userData;		/* arbitary user data */
} TkTextTag;

#define TK_TAG_AFFECTS_DISPLAY	0x1
#define TK_TAG_UNDERLINE	0x2
#define TK_TAG_JUSTIFY		0x4
#define TK_TAG_OFFSET		0x10

/*
 * The data structure below is used for searching a B-tree for transitions
 * on a single tag (or for all tag transitions).  No code outside of
 * tkTextBTree.c should ever modify any of the fields in these structures,
 * but it's OK to use them for read-only information.
 */

typedef struct TkTextSearch {
    TkTextIndex curIndex;		/* Position of last tag transition
					 * returned by TkBTreeNextTag, or
					 * index of start of segment
					 * containing starting position for
					 * search if TkBTreeNextTag hasn't
					 * been called yet, or same as
					 * stopIndex if search is
					 * over. The index is wrt
					 * internal tree. */
    TkTextIndex extIndex;		/* In the case of successful
					 * search this contain the
					 * representation of the
					 * curIndex in the outermost BTree. */
    TkTextSegment *segPtr;		/* Actual tag segment returned by last
					 * call to TkBTreeNextTag, or NULL if
					 * TkBTreeNextTag hasn't returned
					 * anything yet. */
    TkTextSegment *nextPtr;		/* Where to resume search in next
					 * call to TkBTreeNextTag. */
    TkTextSegment *lastPtr;		/* Stop search before just before
					 * considering this segment. */
    int lastOffset;			/* Offset of lastPtr in the
					 * outermos line. */
    TkTextLine *lastLinePtr;		/* The (maybe internal) line of
					 * lastPtr, or NULL: a node of a
					 * block's tree skipped for having
					 * no relevant toggle ends the
					 * search if it holds this line
					 * (linesLeft only counts lines of
					 * the outermost tree). */
    TkTextTag *tagPtr;			/* Tag to search for (or tag found, if
					 * allTags is non-zero). */
    TkTextBTree tree;			/* The BTree to search in. */
    int linesLeft;			/* Lines left to search (including
					 * curIndex and stopIndex).  When
					 * this becomes <= 0 the search is
					 * over. */
    int allTags;			/* Non-zero means ignore tag check:
					 * search for transitions on all
					 * tags. */
} TkTextSearch;

/*
 * The following data structure describes a single tab stop.
 */

typedef enum {LEFT, RIGHT, CENTER, NUMERIC} TkTextTabAlign;

typedef struct TkTextTab {
    int location;			/* Offset in pixels of this tab stop
					 * from the left margin (lmargin2) of
					 * the text. */
    TkTextTabAlign alignment;		/* Where the tab stop appears relative
					 * to the text. */
} TkTextTab;

typedef struct TkTextTabArray {
    int numTabs;			/* Number of tab stops. */
    TkTextTab tabs[1];			/* Array of tabs.  The actual size
					 * will be numTabs.  THIS FIELD MUST
					 * BE THE LAST IN THE STRUCTURE. */
} TkTextTabArray;

/*
 * The following definition specifies the maximum number of characters
 * needed in a string to hold a position specifier.
 */

#define TK_POS_CHARS 30

/*
 * The undo/redo stack ("edit undo", "edit redo"; see tkTextUndo.c).
 * Each atom records one insertion or deletion, or separates two
 * compound actions.
 */

#define TK_TEXT_UNDO_SEPARATOR	0
#define TK_TEXT_UNDO_INSERT	1
#define TK_TEXT_UNDO_DELETE	2
#define TK_TEXT_UNDO_SPLIT	3	/* block split: the separator at
					 * index1 (level, added). */
#define TK_TEXT_UNDO_BLOCK	4	/* block insert of the block type
					 * "string" over index1-index2 (as
					 * given); undone by dissolving it. */
#define TK_TEXT_UNDO_TRIM	5	/* block trim of the block whose head
					 * is at index1 (added: whether its
					 * root had a value). */
#define TK_TEXT_UNDO_TAG	6	/* tag add (added 1) or tag remove
					 * (added 0) of the tag "string" over
					 * index1-index2; ranges: the ranges
					 * the tag had there. */

/*
 * Values ("block nodedata") that leave the text.  Freeing a value can
 * run Perl code (a DESTROY method), so a value is never freed in the
 * middle of a change to the B-tree: it goes, as a record of the type
 * below, either to the widget's list of values to free when the widget
 * command finishes (TkTextFreeValueLater, TkTextFlushValues), or, when
 * the change can be undone, to the undo atom of the change, with an
 * address that is valid in the text as the undo restores it.  Undoing
 * the change gives the values back to the nodes at their addresses
 * (TkBTreeRestoreValues); discarding the atom frees them.
 *
 * An address is a position in the outermost tree (a line number and a
 * byte offset in that line, which are the same in the restored text
 * as they were before the change) and a level: for a node of a block,
 * the position where its first leaf starts and its distance from the
 * leaves (0 for a leaf); for a run of a tag, the position of its first
 * character, with the tag's name; for the instance data of a block,
 * the position of the block's head.  (Marks need no records: edits
 * never remove a mark.)
 */

#define TK_TEXT_VALUE_NODE	1	/* A value dropped from the node at
					 * the address. */
#define TK_TEXT_VALUE_MOVE	2	/* A merge gave the value of the node
					 * at the address to the node at the
					 * source address, which had none:
					 * undoing it moves the value back.
					 * value is empty. */

#define TK_TEXT_VALUE_RUN	3	/* A value dropped from the run of the
					 * tag "name" that starts at the
					 * address (level unused). */
#define TK_TEXT_VALUE_RUNMOVE	4	/* A merge of runs of the tag "name"
					 * gave the value of the run starting
					 * at the address to the merged run,
					 * whose first part (the run that had
					 * no value) starts at the source
					 * address: undoing it moves the value
					 * back.  value is empty. */
#define TK_TEXT_VALUE_BLOCK	5	/* The instance data ("block data") of
					 * the block whose head is at the
					 * address (level unused), dropped when
					 * a deletion deleted or dissolved the
					 * block.  The block lists of the undo
					 * leave instance data out: the block
					 * they re-create gets the whole
					 * container back from this record. */

typedef struct TkTextValue {
    int kind;				/* TK_TEXT_VALUE_NODE, _MOVE, _RUN,
					 * _RUNMOVE or _BLOCK; 0 for a value
					 * that is only to be freed. */
    int line;				/* Address: line number (from 0) in the
					 * outermost tree, */
    int byteIndex;			/* byte offset in that line, */
    int level;				/* and level (0 for a leaf). */
    int srcLine, srcByteIndex, srcLevel;
					/* For _MOVE: where the value went. */
    char *name;				/* For _RUN and _RUNMOVE: the name of
					 * the tag, malloc-ed; else NULL. */
    TkTextData value;			/* The whole container (owned by the
					 * record: all its slots travel), or
					 * empty. */
    struct TkTextValue *nextPtr;	/* Next record in the list. */
} TkTextValue;

typedef struct TkTextUndoAtom {
    int type;				/* TK_TEXT_UNDO_SEPARATOR, _INSERT or
					 * _DELETE. */
    char index1[TK_POS_CHARS];		/* Where the change starts. */
    char index2[TK_POS_CHARS];		/* Where the inserted or deleted text
					 * ends. */
    Tcl_Obj *string;			/* The text inserted or deleted (NULL
					 * for a separator). */
    Tcl_Obj *list;			/* For a deletion: the contents of the
					 * range as "block list" reports them,
					 * to re-create blocks, tags and marks
					 * on undo; for an insertion, the same,
					 * recorded when it is undone, for the
					 * redo; else NULL. */
    char listIndex[TK_POS_CHARS];	/* Where the list goes back: the start
					 * of the deletion or, if it cut
					 * blocks, the start of the smallest
					 * range around it that cuts none
					 * (which is what the list covers). */
    int remains;			/* Size, in bytes of index space, of
					 * what a deletion that cut blocks
					 * left of them at listIndex (the
					 * widget dissolves a cut block); undo
					 * takes that out before re-inserting
					 * the list.  0 otherwise. */
    int *cuts;				/* For a deletion that cut blocks: the
					 * positions of the heads and the tails
					 * of the cut blocks that were not in
					 * the range, which the dissolution
					 * removed (byte offsets: the heads from
					 * listIndex, the tails from index2;
					 * numHeads heads in increasing order,
					 * then the tails).  Lets the undo find
					 * where values in the remains belong.
					 * Malloc-ed; NULL if none. */
    int numHeads, numTails;		/* How many of each. */
    int *levels;			/* _BLOCK inside a block: the levels
					 * of the separators after the leaves
					 * from the one of index1 to the one
					 * of index2 (those in the range and
					 * the one just after it), as they
					 * were before the block insert, which
					 * flattens them; its undo sets them
					 * back (TkIBTreeSetSeparatorLevels).
					 * Malloc-ed; NULL otherwise. */
    int numLevels;			/* How many. */
    int level;				/* _SPLIT: the level asked for. */
    int added;				/* _SPLIT: the levels the split added
					 * above the root; _TRIM: non-zero if
					 * the root had a value; _TAG: 1 for
					 * add, 0 for remove. */
    int numRanges;			/* _TAG: the number of ranges, */
    char *ranges;			/* and their ends, 2 * numRanges index
					 * strings of TK_POS_CHARS each
					 * (malloc-ed, or NULL). */
    TkTextData data;			/* _BLOCK: the instance data of the
					 * block (the whole container), kept
					 * from the undo, which dissolves the
					 * block, for the redo; empty
					 * otherwise. */
    TkTextValue *values;		/* The values the change dropped when
					 * it was last done or undone, the most
					 * recent first (see TkTextValue). */
    TkTextValue *displaced;		/* Values that giving those back found
					 * at their addresses (set there after
					 * the change): given back when the
					 * change is applied again. */
    struct TkTextUndoAtom *nextPtr;	/* Next atom down the stack. */
} TkTextUndoAtom;

/*
 * While an undo puts back the text a deletion that cut blocks took out
 * (see TkTextUndoAtom), the values in the remains of those blocks are
 * taken out with the remains, at addresses in the text as it was then,
 * and given back at the same places in the restored text.  This is what
 * TkBTreeRestoreValues needs to find those places:
 */

typedef struct TkTextRemainsMap {
    struct TkTextUndoAtom *atomPtr;	/* The atom undone. */
    int line;				/* The line (from 0) of its listIndex. */
    int numLines;			/* How many lines the remains reached
					 * beyond it. */
    int *starts;			/* numLines + 1 offsets: where each of
					 * these lines started, in bytes from
					 * listIndex (the first is minus the
					 * byte offset of listIndex). */
} TkTextRemainsMap;

typedef struct TkTextUndoStack {
    TkTextUndoAtom *undoStack;		/* Actions that can be undone. */
    TkTextUndoAtom *redoStack;		/* Actions that can be redone. */
    int maxdepth;			/* -maxundo: compound actions kept;
					 * <= 0 means no limit. */
    int depth;				/* Compound actions on the undo stack. */
    struct TkText *textPtr;		/* The widget, which frees the values
					 * of the atoms discarded. */
} TkTextUndoStack;

/*
 * The notification of detached values (-valuecommand): before a change
 * detaches values, the look-ahead (TkBTreeVcPredict... in
 * tkTextBTree.c) tells the callback which values it will detach and
 * where they are; what the change then does is checked against it (a
 * detach that was not foreseen is reported "late").  The events and
 * the kinds of places:
 */

#define TK_TEXT_VC_DROP		1	/* Freed when the command ends. */
#define TK_TEXT_VC_STASH	2	/* Goes into an undo step. */
#define TK_TEXT_VC_MOVE		3	/* A merge gives it to another owner. */
#define TK_TEXT_VC_RESTORE	4	/* An undo or a redo gave it back. */
#define TK_TEXT_VC_DISCARD	5	/* A discarded undo step held it. */
#define TK_TEXT_VC_LATE		6	/* Detached, not foreseen. */

#define TK_TEXT_VC_NODE		1	/* [index, level] */
#define TK_TEXT_VC_RUN		2	/* [tag, start, end] */
#define TK_TEXT_VC_MARK		3	/* [name, index] */
#define TK_TEXT_VC_BLOCK	4	/* [head index] */

/*
 * How deep DESTROY methods may change the widget while values are being
 * freed, each change dropping values whose DESTROY methods change it
 * again (see FlushValues in tkText.c): the limit a freeing pass starts
 * with; the object whose DESTROY method makes a change at the limit is
 * asked whether to raise it (its method DESTROYmult, see
 * MoreFreeRounds in tkText.c).
 */

#define TK_TEXT_FREE_DEPTH	10

#define TkTextVcOn(textPtr) \
	(((textPtr) != NULL) && ((textPtr)->vcPtr != NULL))

/*
 * What the last recorded edit was, for -autoseparators:
 */

#define TK_TEXT_EDIT_INSERT	0
#define TK_TEXT_EDIT_DELETE	1
#define TK_TEXT_EDIT_OTHER	2
#define TK_TEXT_EDIT_SPLIT	3	/* Each recorded block or tag change */
#define TK_TEXT_EDIT_BLOCK	4	/* is a kind of edit of its own: */
#define TK_TEXT_EDIT_TRIM	5	/* with -autoseparators, a change of */
#define TK_TEXT_EDIT_TAGADD	6	/* kind starts a new undo step. */
#define TK_TEXT_EDIT_TAGREMOVE	7

/*
 * A data structure of the following type is kept for each text widget that
 * currently exists for this process:
 */

typedef struct TkText {
    Tk_Window tkwin;		/* Window that embodies the text.  NULL
				 * means that the window has been destroyed
				 * but the data structures haven't yet been
				 * cleaned up.*/
    Display *display;		/* Display for widget.  Needed, among other
				 * things, to allow resources to be freed
				 * even after tkwin has gone away. */
    Tcl_Interp *interp;		/* Interpreter associated with widget.  Used
				 * to delete widget command.  */
    Tcl_Command widgetCmd;	/* Token for text's widget command. */
    TkTextBTree tree;		/* B-tree representation of text and tags for
				 * widget. */
    Tcl_HashTable tagTable;	/* Hash table that maps from tag names to
				 * pointers to TkTextTag structures. */
    int numTags;		/* Number of tags currently defined for
				 * widget;  needed to keep track of
				 * priorities. */
    Tcl_HashTable markTable;	/* Hash table that maps from mark names to
				 * pointers to mark segments. */
    Tcl_HashTable windowTable;	/* Hash table that maps from window names
				 * to pointers to window segments.  If a
				 * window segment doesn't yet have an
				 * associated window, there is no entry for
				 * it here. */
    Tcl_HashTable blockTable;	/* Hash table that maps from block names to
				 * pointers to block structures. */
    Tcl_HashTable imageTable;	/* Hash table that maps from image names
				 * to pointers to image segments.  If an
				 * image segment doesn't yet have an
				 * associated image, there is no entry for
				 * it here. */
    struct DLine **dlinePtrs;	/* Array of pointers to additional DLines. */
    int numDLines;		/* Number of DLines in that array. */
    Tk_Uid state;		/* Normal or disabled.  Text is read-only
				 * when disabled. */

    /*
     * Default information for displaying (may be overridden by tags
     * applied to ranges of characters).
     */

    Tk_3DBorder border;		/* Structure used to draw 3-D border and
				 * default background. */
    int borderWidth;		/* Width of 3-D border to draw around entire
				 * widget. */
    int padX, padY;		/* Padding between text and window border. */
    int relief;			/* 3-d effect for border around entire
				 * widget: TK_RELIEF_RAISED etc. */
    int highlightWidth;		/* Width in pixels of highlight to draw
				 * around widget when it has the focus.
				 * <= 0 means don't draw a highlight. */
    XColor *highlightBgColorPtr;
				/* Color for drawing traversal highlight
				 * area when highlight is off. */
    XColor *highlightColorPtr;	/* Color for drawing traversal highlight. */
    Tk_Cursor cursor;		/* Current cursor for window, or None. */
    XColor *fgColor;		/* Default foreground color for text. */
    Tk_Font tkfont;	/* Default font for displaying text. */
    int charWidth;		/* Width of average character in default
				 * font. */
    int spacing1;		/* Default extra spacing above first display
				 * line for each text line. */
    int spacing2;		/* Default extra spacing between display lines
				 * for the same text line. */
    int spacing3;		/* Default extra spacing below last display
				 * line for each text line. */
    Arg tabOptionString;	/* Value of -tabs option string (malloc'ed). */
    TkTextTabArray *tabArrayPtr;
				/* Information about tab stops (malloc'ed).
				 * NULL means perform default tabbing
				 * behavior. */

    /*
     * Additional information used for displaying:
     */

    Tk_Uid wrapMode;		/* How to handle wrap-around.  Must be
				 * tkTextCharUid, tkTextNoneUid, or
				 * tkTextWordUid. */
    int width, height;		/* Desired dimensions for window, measured
				 * in characters. */
    int setGrid;		/* Non-zero means pass gridding information
				 * to window manager. */
    int prevWidth, prevHeight;	/* Last known dimensions of window;  used to
				 * detect changes in size. */
    TkTextIndex topIndex;	/* Identifies first character in top display
				 * line of window. */
    struct TextDInfo *dInfoPtr;	/* Information maintained by tkTextDisp.c. */

    /*
     * Information related to selection.
     */

    TkTextTag *selTagPtr;	/* Pointer to "sel" tag.  Used to tell when
				 * a new selection has been made. */
    Tk_3DBorder selBorder;	/* Border and background for selected
				 * characters.  This is a copy of information
				 * in *cursorTagPtr, so it shouldn't be
				 * explicitly freed. */
    char *selBdString;		/* Value of -selectborderwidth option, or NULL
				 * if not specified (malloc'ed). */
    XColor *selFgColorPtr;	/* Foreground color for selected text.
				 * This is a copy of information in
				 * *cursorTagPtr, so it shouldn't be
				 * explicitly freed. */
    int exportSelection;	/* Non-zero means tie "sel" tag to X
				 * selection. */
    TkTextIndex selIndex;	/* Used during multi-pass selection retrievals.
				 * This index identifies the next character
				 * to be returned from the selection. */
    int selRest;		/* Used during multi-pass selection retrievals.
				 * The number of characters in string
				 * representation of the next text
				 * position after selIndex that are
				 * already written. */
    int abortSelections;	/* Set to 1 whenever the text is modified
				 * in a way that interferes with selection
				 * retrieval:  used to abort incremental
				 * selection retrievals. */
    int selOffset;		/* Offset in selection corresponding to
				 * selLine and selCh.  -1 means neither
				 * this information nor selIndex is of any
				 * use. */

    /*
     * Information related to insertion cursor:
     */

    TkTextSegment *insertMarkPtr;
				/* Points to segment for "insert" mark. */
    Tk_3DBorder insertBorder;	/* Used to draw vertical bar for insertion
				 * cursor. */
    int insertWidth;		/* Total width of insert cursor. */
    int insertBorderWidth;	/* Width of 3-D border around insert cursor. */
    int insertOnTime;		/* Number of milliseconds cursor should spend
				 * in "on" state for each blink. */
    int insertOffTime;		/* Number of milliseconds cursor should spend
				 * in "off" state for each blink. */
    Tcl_TimerToken insertBlinkHandler;
				/* Timer handler used to blink cursor on and
				 * off. */

    /*
     * Information used for event bindings associated with tags:
     */

    Tk_BindingTable bindingTable;
				/* Table of all bindings currently defined
				 * for this widget.  NULL means that no
				 * bindings exist, so the table hasn't been
				 * created.  Each "object" used for this
				 * table is the address of a tag. */
    TkTextSegment *currentMarkPtr;
				/* Pointer to segment for "current" mark,
				 * or NULL if none. */
    XEvent pickEvent;		/* The event from which the current character
				 * was chosen.  Must be saved so that we
				 * can repick after modifications to the
				 * text. */
    int numCurTags;		/* Number of tags associated with character
				 * at current mark. */
    TkTextTag **curTagArrayPtr;	/* Pointer to array of tags for current
				 * mark, or NULL if none. */

    /*
     * Miscellaneous additional information:
     */

    char *takeFocus;		/* Value of -takeFocus option;  not used in
				 * the C code, but used by keyboard traversal
				 * scripts.  Malloc'ed, but may be NULL. */
    LangCallback *xScrollCmd;	/* Prefix of command to issue to update
				 * horizontal scrollbar when view changes. */
    LangCallback *yScrollCmd;	/* Prefix of command to issue to update
				 * vertical scrollbar when view changes. */
    int getFlags;		/* Flags for text extraction;  see below for
				 * definitions. */

    /*
     * Undo/redo and the modified flag ("edit" subcommand):
     */

    TkTextUndoStack *undoStack;	/* The undo/redo stacks. */
    int undo;			/* Non-zero means changes are recorded for
				 * undo (-undo). */
    int maxUndo;		/* -maxundo: compound actions kept. */
    int autoSeparators;		/* -autoseparators: separate insertions
				 * from deletions automatically. */
    int modifiedSet;		/* Non-zero means "edit modified" was set
				 * explicitly, so changes do not alter it. */
    int isDirty;		/* Non-zero means unsaved modifications
				 * ("edit modified"). */
    int isDirtyIncrement;	/* +1, or -1 while undoing. */
    int lastEditMode;		/* TK_TEXT_EDIT_INSERT, _DELETE or _OTHER. */

    /*
     * Values of block nodes (see TkTextValue):
     */

    int cmdDepth;		/* Nesting depth of widget commands; the
				 * values dropped are freed when it comes
				 * back to 0. */
    int haveValues;		/* Non-zero once a value has been set: until
				 * then, no change needs to look for any. */
    TkTextValue *freeValues;	/* Values to free when the command ends, in
				 * the order they were dropped. */
    TkTextValue *lastFreeValue;	/* The last of them. */
    TkTextValue **valueCapture;	/* During a deletion that can be undone:
				 * where the values it drops go (the list
				 * of its undo atom); else NULL. */
    Tcl_HashTable *valueAddresses;
				/* With valueCapture: the addresses, before
				 * the deletion, of the nodes it may drop
				 * values from (TkBTreeSnapshotValues). */
    TkTextValue **editValues;	/* While an undo or a redo deletes text: the
				 * list of the atom it applies, for the
				 * values that deletion drops; else NULL. */
    int freeingValues;		/* Non-zero while FlushValues frees values
				 * (a DESTROY method may be running): the
				 * round (see FlushValues); a command that
				 * modifies the widget meanwhile is a change
				 * of its own for the undo, and is refused
				 * in round freeLimit unless DESTROYmult
				 * raises it. */
    int freeLimit;		/* The round in which changes are refused
				 * during this freeing pass: starts at
				 * TK_TEXT_FREE_DEPTH, raised by the answers
				 * of DESTROYmult (MoreFreeRounds). */
    int freeAsks;		/* How many times DESTROYmult was called
				 * during this freeing pass. */
    int freeAsking;		/* Non-zero while DESTROYmult runs: a change
				 * then is refused without asking again. */

    /*
     * The notification of detached values (-valuecommand, see
     * TkTextVcPredict in tkText.c):
     */

    LangCallback *valueCmd;	/* -valuecommand, or NULL. */
    struct TkTextVcState *vcPtr;
				/* While a widget command runs and valueCmd
				 * was set when it started: what it predicted
				 * and what happened; else NULL (then nothing
				 * of the notification runs). */
    int vcInCallback;		/* Non-zero while valueCmd runs: the
				 * commands that modify the widget are
				 * refused meanwhile. */
    int vcTagDone;		/* Set when the look-ahead of a tag change
				 * was done before its redisplay: the
				 * TkBTreeTag that follows does not do it
				 * again. */
    int flags;			/* Miscellaneous flags;  see below for
				 * definitions. */
} TkText;

/*
 * Flag values for TkText records:
 *
 * GOT_SELECTION:		Non-zero means we've already claimed the
 *				selection.
 * INSERT_ON:			Non-zero means insertion cursor should be
 *				displayed on screen.
 * GOT_FOCUS:			Non-zero means this window has the input
 *				focus.
 * BUTTON_DOWN:			1 means that a mouse button is currently
 *				down;  this is used to implement grabs
 *				for the duration of button presses.
 * UPDATE_SCROLLBARS:		Non-zero means scrollbar(s) should be updated
 *				during next redisplay operation.
 */

#define GOT_SELECTION		1
#define INSERT_ON		2
#define GOT_FOCUS		4
#define BUTTON_DOWN		8
#define UPDATE_SCROLLBARS	0x10
#define NEED_REPICK		0x20

#define TKT_GET_STRICT		1
#define TKT_GET_VERBOSE		2

#define TKT_GET_NOCASE		0x8000
#define TKT_GET_OFFSET		0x4000
#define TKT_GET_BUFFER		0x2000
#define TKT_GET_DSTRING		0x1000
#define TKT_GET_LIST		0x800
#define TKT_GET_NOELIDE		0x400	/* Skip elided text (search, the
					 * selection). */
#define TKT_GET_NOVALUES	0x200	/* Leave the node values and the
					 * instance data out of the block
					 * headers of a list (the undo
					 * records them on its own). */

/*
 * Records of the following type define segment types in terms of
 * a collection of procedures that may be called to manipulate
 * segments of that type.
 */

typedef TkTextSegment *	Tk_SegSplitProc _ANSI_ARGS_((
			    struct TkTextSegment *segPtr, int index));
typedef int		Tk_SegDeleteProc _ANSI_ARGS_((
			    struct TkTextSegment *segPtr,
			    TkTextLine *linePtr, int treeGone));
typedef TkTextSegment *	Tk_SegCleanupProc _ANSI_ARGS_((
			    struct TkTextSegment *segPtr, TkTextLine *linePtr));
typedef void		Tk_SegLineChangeProc _ANSI_ARGS_((
			    struct TkTextSegment *segPtr, /* TkTextLine
							   * * linePtr, ???? */
			    TkTextLine *internalLinePtr));
typedef int		Tk_SegLayoutProc _ANSI_ARGS_((struct TkText *textPtr,
			    struct TkTextIndex *indexPtr, TkTextSegment *segPtr,
			    int offset, int maxX, int maxChars,
			    int noCharsYet, Tk_Uid wrapMode,
			    struct TkTextDispChunk *chunkPtr));
typedef void		Tk_SegCheckProc _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));

typedef struct Tk_SegType {
    char *name;				/* Name of this kind of segment. */
    int leftGravity;			/* If a segment has zero size (e.g. a
					 * mark or tag toggle), does it
					 * attach to character to its left
					 * or right?  1 means left, 0 means
					 * right. */
    Tk_SegSplitProc *splitProc;		/* Procedure to split large segment
					 * into two smaller ones. */
    Tk_SegDeleteProc *deleteProc;	/* Procedure to call to delete
					 * segment. */
    Tk_SegCleanupProc *cleanupProc;	/* After any change to a line, this
					 * procedure is invoked for all
					 * segments left in the line to
					 * perform any cleanup they wish
					 * (e.g. joining neighboring
					 * segments). */
    Tk_SegLineChangeProc *lineChangeProc;
					/* Invoked when a segment is about
					 * to be moved from its current line
					 * to an earlier line because of
					 * a deletion.  The linePtr is that
					 * for the segment's old line.
					 * CleanupProc will be invoked after
					 * the deletion is finished. */
    Tk_SegLayoutProc *layoutProc;	/* Returns size information when
					 * figuring out what to display in
					 * window. */
    Tk_SegCheckProc *checkProc;		/* Called during consistency checks
					 * to check internal consistency of
					 * segment. */
} Tk_SegType;

typedef struct Tk_LinePosition {
    int justify;			/* How to justify line. */
    int lMargin1;		/* Left margin, in pixels, for first display
				 * line of each text line. */
    int lMargin2;		/* Left margin, in pixels, for second and
				 * later display lines of each text line. */
    int rMargin;		/* Right margin, in pixels. */
    int spacing1;		/* Spacing above first dline in text line. */
    int spacing2;		/* Spacing between lines of dline. */
    int spacing3;		/* Spacing below last dline in text line. */
} Tk_LinePosition;

typedef struct TkTextBlock {
    int count;				/* Number of blocks of that type. */
    int empty;				/* Non-zero if the block
					 * contains no tree. Should
					 * not be checked anywhere but
					 * during creation of the
					 * block, since can change on
					 * the fly. */
    int depth;				/* Number of levels the
					 * layoutCmd supports. */
    int *widthsMin;			/* Array of number of edges on
					 * each level the 
					 * layoutCmd supports. */
    int *widthsMax;			/* Array of number of edges on
					 * each level the 
					 * layoutCmd supports. */
    int widthsNum;			/* Size of array of number of edges on
					 * each level the 
					 * layoutCmd supports. */
    Arg widthsStr;			/* The string used to set up
					 * the array of number of edges on
					 * each level the 
					 * layoutCmd supports. */
    char *name;				/* Name of this kind of segment. */
    LangCallback *layoutCmd;		/* Command to Layout the
					 * display structure. */
    LangCallback *deleteCallBack;	/* Callback for deletion of block. */
    LangCallback *leafDeleteCallBack;	/* Callback for deletion of a
					 * leaf in a block. */
    LangCallback *leafAddCallBack;	/* Callback for addition of a
					 * leaf in a block. */
    LangCallback *leafEmptyCallBack;	/* Callback for emptying of a
					 * leaf in a block. */
    struct TkText *textPtr;		/* The widget (which frees the
					 * instance data of the blocks the
					 * B-tree code deletes, see
					 * TkTextFreeValueLater). */
} TkTextBlock;

/*
 * The constant below is used to specify a line when what is really
 * wanted is the entire text.  For now, just use a very big number.
 */

#define TK_END_OF_TEXT 1000000


/*
 * Declarations for variables shared among the text-related files:
 */

extern int		tkBTreeDebug;
extern int		tkTextDebug;
extern Tk_SegType	tkTextCharType;
extern Tk_Uid		tkTextCharUid;
extern Tk_Uid		tkTextDisabledUid;
extern Tk_SegType	tkTextLeftMarkType;
extern Tk_Uid		tkTextNoneUid;
extern Tk_Uid 		tkTextNormalUid;
extern Tk_SegType	tkTextRightMarkType;
extern Tk_SegType	tkTextToggleOnType;
extern Tk_SegType	tkTextToggleOffType;
extern Tk_SegType	tkTextIBTreeType;
extern Tk_Uid		tkTextWordUid;
extern Tk_LinePosition	defaultPosition;
/*
 * Declarations for procedures that are used by the text-related files
 * but shouldn't be used anywhere else in Tk (or by Tk clients):
 */

extern int		TkBTreeCharTagged _ANSI_ARGS_((TkTextIndex *indexPtr,
			    TkTextTag *tagPtr));
extern void		TkBTreeCheck _ANSI_ARGS_((TkTextBTree tree));
extern int		TkBTreeCharsInLine _ANSI_ARGS_((TkTextLine *linePtr));
extern TkTextBTree	TkBTreeCreate _ANSI_ARGS_((TkText *textPtr));
extern void		TkBTreeDestroy _ANSI_ARGS_((TkTextBTree tree));
extern void		TkBTreeDeleteChars _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, int rebalance, 
			    int look4trees));
extern TkTextLine *	TkBTreeFindLine _ANSI_ARGS_((TkTextBTree tree,
			    int line));
extern TkTextTag **	TkBTreeGetTags _ANSI_ARGS_((TkTextIndex *indexPtr,
			    int *numTagsPtr));
extern TkTextTag **	TkBTreeGetTagsInEffect _ANSI_ARGS_((
			    TkTextIndex *indexPtr, int *numTagsPtr));
extern void		TkBTreeInsertChars _ANSI_ARGS_((TkTextIndex *indexPtr,
			    char *string));
extern int		TkBTreeLineIndex _ANSI_ARGS_((TkTextLine *linePtr));
extern void		TkBTreeLinkSegment _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextIndex *indexPtr));
extern TkTextLine *	TkBTreeNextLine _ANSI_ARGS_((TkTextLine *linePtr));
extern int		TkBTreeNextTag _ANSI_ARGS_((TkTextSearch *searchPtr));
extern int		TkBTreeNumLines _ANSI_ARGS_((TkTextBTree tree));
extern TkTextLine *	TkBTreePreviousLine _ANSI_ARGS_((TkTextLine *linePtr));
extern int		TkBTreePrevTag _ANSI_ARGS_((TkTextSearch *searchPtr));
extern void		TkBTreeStartSearch _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextTag *tagPtr,
			    TkTextSearch *searchPtr));
extern void		TkBTreeStartSearchBack _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextTag *tagPtr,
			    TkTextSearch *searchPtr));
extern void		TkBTreeTag _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextTag *tagPtr,
			    int add));
extern void		TkBTreeUnlinkSegment _ANSI_ARGS_((TkTextBTree tree,
			    TkTextSegment *segPtr, TkTextLine *linePtr));
extern void		TkTextBindProc _ANSI_ARGS_((ClientData clientData,
			    XEvent *eventPtr));
extern void		TkTextChanged _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr));
extern int		TkTextCharBbox _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, int *xPtr, int *yPtr,
			    int *widthPtr, int *heightPtr));
extern int		TkTextCharLayoutProc _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, TkTextSegment *segPtr,
			    int offset, int maxX, int maxChars, int noBreakYet,
			    Tk_Uid wrapMode, TkTextDispChunk *chunkPtr));
extern int		TkTextIBTreeLayoutProc _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, TkTextSegment *segPtr,
			    int offset, int maxX, int maxChars, int noBreakYet,
			    Tk_Uid wrapMode, TkTextDispChunk *chunkPtr));
extern void		TkTextCreateDInfo _ANSI_ARGS_((TkText *textPtr));
extern void		TkTextFindDisplayLineEnd _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, int end, int *xOffsetPtr));
extern void		TkTextIndexOfX _ANSI_ARGS_((TkText *textPtr, int x,
			    TkTextIndex *indexPtr));
extern int		TkTextDLineInfo _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, int *xPtr, int *yPtr,
			    int *widthPtr, int *heightPtr, int *basePtr));
extern TkTextTag *	TkTextCreateTag _ANSI_ARGS_((TkText *textPtr,
			    char *tagName));
extern void		TkTextFreeDInfo _ANSI_ARGS_((TkText *textPtr));
extern void		TkTextFreeTag _ANSI_ARGS_((TkText *textPtr,
			    TkTextTag *tagPtr));
extern int		TkTextGetIndex _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, char *string,
			    TkTextIndex *indexPtr));
extern TkTextTabArray *	TkTextGetTabs _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Window tkwin, Arg arg));
extern void		TkTextIndexBackChars _ANSI_ARGS_((TkTextIndex *srcPtr,
			    int count, TkTextIndex *dstPtr));
extern int		TkTextIndexCmp _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr));
extern int		TkTextImageCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextImageIndex _ANSI_ARGS_((TkText *textPtr,
			    char *name, TkTextIndex *indexPtr));
extern void		TkTextEditAction _ANSI_ARGS_((TkText *textPtr,
			    TkTextUndoAtom *atomPtr, int revert));
extern TkTextUndoStack *TkTextUndoInitStack _ANSI_ARGS_((int maxdepth));
extern void		TkTextUndoFreeStack _ANSI_ARGS_((TkTextUndoStack *stackPtr));
extern void		TkTextUndoClearStacks _ANSI_ARGS_((
			    TkTextUndoStack *stackPtr));
extern void		TkTextUndoSetDepth _ANSI_ARGS_((TkTextUndoStack *stackPtr,
			    int maxdepth));
extern void		TkTextUndoInsertUndoSeparator _ANSI_ARGS_((
			    TkTextUndoStack *stackPtr));
extern TkTextUndoAtom *	TkTextUndoPushAction _ANSI_ARGS_((
			    TkTextUndoStack *stackPtr,
			    int type, char *index1, char *index2, Tcl_Obj *string,
			    Tcl_Obj *list, char *listIndex, int remains));
extern void		TkTextFreeValueLater _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value));
extern void		TkTextFreeValueList _ANSI_ARGS_((TkText *textPtr,
			    TkTextValue *listPtr));
extern void		TkTextReleaseValues _ANSI_ARGS_((TkTextValue *listPtr));
extern void		TkTextDiscardValue _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int kind, int line,
			    int byteIndex, int level, char *name));
extern void		TkTextDiscardValueList _ANSI_ARGS_((TkText *textPtr,
			    TkTextValue *listPtr));
extern void		TkTextDiscardValueAt _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int vcKind, Tcl_Obj *where));
extern Tcl_Obj *	TkTextVcNodePlace _ANSI_ARGS_((TkText *textPtr,
			    int line, int byteIndex, int level));
extern Tcl_Obj *	TkTextVcRunPlace _ANSI_ARGS_((TkText *textPtr,
			    char *tagName, TkTextIndex *startPtr,
			    TkTextIndex *endPtr));
extern Tcl_Obj *	TkTextVcMarkPlace _ANSI_ARGS_((TkText *textPtr,
			    char *markName, TkTextIndex *indexPtr));
extern Tcl_Obj *	TkTextVcBlockPlace _ANSI_ARGS_((TkText *textPtr,
			    int line, int byteIndex));
extern void		TkTextVcPredict _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int event, int kind,
			    Tcl_Obj *where, Tcl_Obj *to));
extern void		TkTextVcCandidate _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int kind, Tcl_Obj *where));
extern void		TkTextVcNotify _ANSI_ARGS_((TkText *textPtr));
extern void		TkTextVcSeen _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int event));
extern void		TkTextVcRestored _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int kind, Tcl_Obj *where));
extern void		TkTextVcDiscarded _ANSI_ARGS_((TkText *textPtr,
			    TkTextData value, int kind, Tcl_Obj *where));
extern void		TkBTreeVcPredictTag _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    TkTextTag *tagPtr, int add));
extern void		TkBTreeVcPredictDelete _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    int event));
extern void		TkBTreeVcPredictBlock _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    int event));
extern void		TkBTreeVcPredictTrim _ANSI_ARGS_((TkText *textPtr,
			    TkTextSegment *segPtr, int event));
extern Tcl_Obj *	TkBTreeVcNodePlace _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, Arg levelArg));
extern Tcl_Obj *	TkBTreeVcRunPlace _ANSI_ARGS_((TkText *textPtr,
			    TkTextTag *tagPtr, TkTextIndex *indexPtr));
extern void		TkBTreeSnapshotValues _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    Tcl_HashTable *tablePtr));
extern void		TkBTreeFreeSnapshot _ANSI_ARGS_((
			    Tcl_HashTable *tablePtr));
extern void		TkBTreeRestoreValues _ANSI_ARGS_((TkText *textPtr,
			    TkTextValue *listPtr, TkTextRemainsMap *mapPtr,
			    TkTextValue **displacedPtr, int fromAtom));
extern int		TkBTreeNodeValue _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, char *indexString,
			    Arg levelArg, TkTextData **dataPtrPtr));
extern void		TkBTreeSetValue _ANSI_ARGS_((TkText *textPtr,
			    TkTextData *dataPtr, Arg value));
extern int		TkBTreeRunValue _ANSI_ARGS_((TkText *textPtr,
			    TkTextTag *tagPtr, TkTextIndex *indexPtr,
			    char *indexString, TkTextData **dataPtrPtr));
extern int		TkTextUndoRevert _ANSI_ARGS_((TkText *textPtr));
extern int		TkTextUndoApply _ANSI_ARGS_((TkText *textPtr));
extern void		TkTextIndexForwChars _ANSI_ARGS_((TkTextIndex *srcPtr,
			    int count, TkTextIndex *dstPtr));
extern TkTextSegment *	TkTextIndexToSeg _ANSI_ARGS_((TkTextIndex *indexPtr,
			    int *offsetPtr));
extern int		TkTextIsElided _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr));
extern void		TkTextInsertDisplayProc _ANSI_ARGS_((
			    TkTextDispChunk *chunkPtr, int x, int y, int height,
			    int baseline, Display *display, Drawable dst,
			    int screenY));
extern void		TkTextLostSelection _ANSI_ARGS_((
			    ClientData clientData));
extern TkTextIndex *	TkTextMakeByteIndex _ANSI_ARGS_((TkTextBTree tree,
			    int lineIndex, int byteIndex,
			    TkTextIndex *indexPtr));
extern TkTextIndex *	TkTextMakeCharIndex _ANSI_ARGS_((TkTextBTree tree,
			    int lineIndex, int charIndex,
			    TkTextIndex *indexPtr));
extern void		TkTextIndexForwBytes _ANSI_ARGS_((TkTextIndex *srcPtr,
			    int count, TkTextIndex *dstPtr));
extern void		TkTextIndexBackBytes _ANSI_ARGS_((TkTextIndex *srcPtr,
			    int count, TkTextIndex *dstPtr));
extern int		TkTextIndexCharOffset _ANSI_ARGS_((TkTextIndex *indexPtr));
extern int		TkTextIndexCountChars _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr));
extern int		TkTextLineNumChars _ANSI_ARGS_((TkTextLine *linePtr));
extern void		TkTextIndexAdjustToChar _ANSI_ARGS_((TkTextIndex *indexPtr));
extern int		TkTextSegNumChars _ANSI_ARGS_((TkTextSegment *segPtr,
			    int byteCount));
extern int		TkTextSegCharToByte _ANSI_ARGS_((TkTextSegment *segPtr,
			    int charCount, int *restPtr));
extern int		TkTextUtfToLowerSameLength _ANSI_ARGS_((char *str, int len));
extern int		TkTextMarkCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextBlockCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextMarkNameToIndex _ANSI_ARGS_((TkText *textPtr,
			    char *name, TkTextIndex *indexPtr));
extern void		TkTextMarkSegToIndex _ANSI_ARGS_((TkText *textPtr,
			    TkTextSegment *markPtr, TkTextIndex *indexPtr));
extern void		TkTextEventuallyRepick _ANSI_ARGS_((TkText *textPtr));
extern void		TkTextPickCurrent _ANSI_ARGS_((TkText *textPtr,
			    XEvent *eventPtr));
extern void		TkTextPixelIndex _ANSI_ARGS_((TkText *textPtr,
			    int x, int y, TkTextIndex *indexPtr));
extern void		TkTextPrintIndex _ANSI_ARGS_((TkTextIndex *indexPtr,
			    char *string));
extern void		TkTextRedrawRegion _ANSI_ARGS_((TkText *textPtr,
			    int x, int y, int width, int height));
extern void		TkTextRedrawTag _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    TkTextTag *tagPtr, int withTag));
extern void		TkTextRelayoutWindow _ANSI_ARGS_((TkText *textPtr));
extern int		TkTextScanCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextSeeCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextSegToOffset _ANSI_ARGS_((TkTextSegment *segPtr,
			    TkTextLine *linePtr));
extern TkTextSegment *	TkTextSetMark _ANSI_ARGS_((TkText *textPtr, char *name,
			    TkTextIndex *indexPtr));
extern void		TkTextSetYView _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr, int pickPlace));
extern int		TkTextTagCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextWindowCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextWindowIndex _ANSI_ARGS_((TkText *textPtr,
			    char *name, TkTextIndex *indexPtr));
extern int		TkTextXviewCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkTextYviewCmd _ANSI_ARGS_((TkText *textPtr,
			    Tcl_Interp *interp, int argc, Arg *args));
extern int		TkBTreeMakeBlock _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextBlock *blockPtr));
extern int		TkBTreeBlockEndDeleteProc _ANSI_ARGS_((
			    TkTextBTree tree, TkTextSegment *segPtr, 
			    TkTextSegment *posSegPtr, 
			    TkTextLine *posLinePtr, TkTextLine **newLinePtr,
			    TkTextSegment **posSegPtrPtr));
extern int		TkBTreeBlockStartDeleteProc _ANSI_ARGS_((
			    TkTextBTree tree,
		            TkTextSegment *segPtr, TkTextLine *linePtr, 
			    int offset,
			    TkTextSegment **newHeadPtrPtr));
extern void		TkTextIndexToExternalIndex _ANSI_ARGS_((
			    TkTextBTree tree, TkTextIndex *indexPtr, 
			    TkTextIndex *resIndexPtr));
int			TkIBTreeTextAppend _ANSI_ARGS_((
			    TkText *textPtr,
			    TkTextSegment *segPtr, int start, int end,
			    void *targetPtr, int flags, int* offsetPtr));
int			TkBTreeLineTextAppend _ANSI_ARGS_((
			    TkText *textPtr,
			    TkTextLine *linePtr, int start, int end,
			    void *targetPtr, int flags, int* offsetPtr));
void			TkTextImageOptionList _ANSI_ARGS_((
			    TkTextSegment *eiPtr, ListFactory *lfPtr));
void			TkTextWindowOptionList _ANSI_ARGS_((
			    TkTextSegment *ewPtr, ListFactory *lfPtr));
void			TkIBTreeFixTags _ANSI_ARGS_((
			    TkTextSegment *segPtr, TkTextTag **tagPtrPtr,
		            int *nPtr));
int			TkIBTreeTogglesElide _ANSI_ARGS_((
			    TkTextSegment *segPtr));
int *			TkIBTreeSeparatorLevels _ANSI_ARGS_((
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    int *numPtr));
void			TkIBTreeSetSeparatorLevels _ANSI_ARGS_((
			    TkText *textPtr, TkTextIndex *indexPtr,
			    int *levels, int num));
void			TkIBTreePrint _ANSI_ARGS_((
			    TkTextSegment *segPtr, ListFactory *listFactoryPtr,
			    void **linePtrs));
void			TkTextPrintDLines _ANSI_ARGS_((ListFactory *listFactoryPtr,
			    struct DLine **dlPtr, int count));
TkTextSegment *		TkIBTreeAt _ANSI_ARGS_((TkTextIndex *indexPtr, 
			    int inside));
void			TkIBTreeInfo _ANSI_ARGS_((
			    TkTextSegment *segPtr, ListFactory *listFactoryPtr));
void			TkIBTreeStartIndex _ANSI_ARGS_((TkTextBTree tree,
			    TkTextSegment *segPtr, TkTextIndex *indexPtr));
int			TkIBTreeCutRange _ANSI_ARGS_((TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr, TkTextIndex *ext1Ptr,
			    TkTextIndex *ext2Ptr, int *remainsPtr));
int *			TkIBTreeCutPositions _ANSI_ARGS_((
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    TkTextIndex *ext1Ptr, int *numHeadsPtr,
			    int *numTailsPtr));
int			TkIBTreeSplit _ANSI_ARGS_((TkTextIndex *indexPtr, 
			    int level));
TkTextValue *		TkBTreeTakeCrossingRunValues _ANSI_ARGS_((
			    TkText *textPtr, TkTextIndex *index1Ptr,
			    TkTextIndex *index2Ptr));
void *			TkBTreeHoldRunValues _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr));
void			TkBTreeReleaseRunValues _ANSI_ARGS_((TkText *textPtr,
			    void *held));
int			TkIBTreeRootHasValue _ANSI_ARGS_((
			    TkTextSegment *segPtr));
void			TkIBTreeAddRoot _ANSI_ARGS_((TkTextSegment *segPtr,
			    int moveValue));
TkTextValue *		TkBTreeTakeMovedLeafValues _ANSI_ARGS_((
			    TkText *textPtr, TkTextSegment *segPtr,
			    TkTextIndex *headPtr));
extern void		TkTextTagChange _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *index1Ptr, TkTextIndex *index2Ptr,
			    TkTextTag *tagPtr, int add));
void			TkIBTreeDeepen _ANSI_ARGS_((TkTextSegment *segPtr,
			    int depth));
void			TkTextFreeDLine _ANSI_ARGS_((TkText *textPtr,
                            struct DLine *dlPtr));
struct DLine *		TkTextGetDLine _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *indexPtr));
int			TkIBTreeTrim _ANSI_ARGS_((TkText *textPtr,
			    TkTextSegment *segPtr));
TkTextSegment *		TkIBTreeNode2seg _ANSI_ARGS_((struct Node *nodePtr,
			    TkTextLine **linePtrPtr));
TkTextLine *		TkIBTreeFirstLine _ANSI_ARGS_((TkTextSegment *segPtr));
TkTextSegment *		TkTextIndexToInternalSeg _ANSI_ARGS_((TkTextIndex *indexPtr,
			    TkTextIndex *intIndexPtr, int *offsetPtr));


#ifdef LangIsPerl
#include "tkPort.h"
#include "tkVMacro.h"
#endif

/*
 * The operations on the containers of values, which call the language
 * through its function table (tkVMacro.h).
 */

#define TK_TEXT_DATA_FUNCTIONS
#include "tkTextData.h"

#endif /* _TKTEXT */
