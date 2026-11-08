/* 
 * tkTextIndex.c --
 *
 *	This module provides procedures that manipulate indices for
 *	text widgets.
 *
 * Copyright (c) 1992-1994 The Regents of the University of California.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 * Copyright (c) 1995 Ilya Zakharevich.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * Indices.  Internally a TkTextIndex holds a byte offset within its
 * line (byteIndex); the text is UTF-8 (Perl/Tk 804 stores every string
 * that way), so a character may occupy several bytes.  The user-visible
 * "line.char" form counts characters, as in Tk 8.4: the conversion in
 * both directions happens here (TkTextMakeCharIndex, TkTextPrintIndex,
 * TkTextIndexForwChars/BackChars), everything else in the widget works
 * with bytes (TkTextMakeByteIndex, TkTextIndexForwBytes/BackBytes).
 *
 * A block (IBTree segment) occupies segPtr->size positions of index
 * space: one dummy position at its start, followed by the bytes of its
 * internal lines.  Counting characters therefore descends into blocks
 * (TkTextSegNumChars, TkTextSegCharToByte); the dummy position counts
 * as one character.  Embedded windows (and images) count as one
 * character, like in Tk.
 */

static char sccsid[] = "@(#) tkTextIndex.c 1.9 95/01/03 17:06:20";

#include "pperl.h"
#include "default.h"
#include "tkPort.h"
#include "tkInt.h"
#include "tkText.h"

static char rcsid[] = "$Id: tkTextIndex.c,v 1.4 1995/09/16 00:28:59 ilya Exp $";

/*
 * Index to use to select last character in line (very large integer):
 */

#define LAST_CHAR 1000000

/*
 * Forward declarations for procedures defined later in this file:
 */

static char *		ForwBack _ANSI_ARGS_((TkText *textPtr, char *string,
			    TkTextIndex *indexPtr));
static int		ParseModifier _ANSI_ARGS_((char **unitsPtr,
			    size_t *lengthPtr));
static void		ForwDisplayChars _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *srcPtr, int count, TkTextIndex *dstPtr));
static void		BackDisplayChars _ANSI_ARGS_((TkText *textPtr,
			    TkTextIndex *srcPtr, int count, TkTextIndex *dstPtr));
static int		IndexIsWordChar _ANSI_ARGS_((TkTextIndex *indexPtr));

/*
 * What may precede the units of an index modifier (ParseModifier):
 */

#define TKINDEX_NONE	0
#define TKINDEX_DISPLAY	1
#define TKINDEX_ANY	2
static char *		StartEnd _ANSI_ARGS_((TkText *textPtr, char *string,
			    TkTextIndex *indexPtr));
static int		IBTreeNumChars _ANSI_ARGS_((TkTextSegment *segPtr,
			    int byteCount));
static int		IBTreeCharToByte _ANSI_ARGS_((TkTextSegment *segPtr,
			    int charCount, int *restPtr));

/*
 *--------------------------------------------------------------
 *
 * TkTextSegNumChars --
 *
 *	Count the characters in the first byteCount positions of the
 *	index space of a segment.
 *
 * Results:
 *	The number of characters: UTF-8 characters for a character
 *	segment, one per position for windows and other segments, and
 *	the dummy position plus the characters of the internal lines
 *	for a block.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

int
TkTextSegNumChars(segPtr, byteCount)
    TkTextSegment *segPtr;	/* Segment to look at. */
    int byteCount;		/* How many positions of its index space
				 * to count (clamped to segPtr->size). */
{
    if (byteCount <= 0) {
	return 0;
    }
    if (byteCount > segPtr->size) {
	byteCount = segPtr->size;
    }
    if (segPtr->typePtr == &tkTextCharType) {
	return Tcl_NumUtfChars(segPtr->body.chars, byteCount);
    }
    if (segPtr->typePtr == &tkTextIBTreeType) {
	return IBTreeNumChars(segPtr, byteCount);
    }
    return byteCount;
}

/*
 *--------------------------------------------------------------
 *
 * TkTextSegCharToByte --
 *
 *	Find the position in the index space of a segment of its
 *	charCount-th character (counting from 0).
 *
 * Results:
 *	The byte offset within the segment, or -1 if the segment has
 *	no more than charCount characters; in that case *restPtr is
 *	set to the number of characters left over after the segment.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

int
TkTextSegCharToByte(segPtr, charCount, restPtr)
    TkTextSegment *segPtr;	/* Segment to look at. */
    int charCount;		/* Character to locate (0 means the
				 * first one). */
    int *restPtr;		/* Filled in with the characters left
				 * over when the result is -1. */
{
    if (segPtr->typePtr == &tkTextCharType) {
	char *p = segPtr->body.chars;
	char *end = p + segPtr->size;
	Tcl_UniChar ch;

	while (p < end) {
	    if (charCount == 0) {
		return p - segPtr->body.chars;
	    }
	    charCount--;
	    p += Tcl_UtfToUniChar(p, &ch);
	}
	*restPtr = charCount;
	return -1;
    }
    if (segPtr->typePtr == &tkTextIBTreeType) {
	return IBTreeCharToByte(segPtr, charCount, restPtr);
    }
    if (charCount < segPtr->size) {
	return charCount;
    }
    *restPtr = charCount - segPtr->size;
    return -1;
}

/*
 *--------------------------------------------------------------
 *
 * IBTreeNumChars, IBTreeCharToByte --
 *
 *	The block cases of the two procedures above: walk the
 *	internal lines of the block (recursively, blocks nest).
 *
 *--------------------------------------------------------------
 */

static int
IBTreeNumChars(segPtr, byteCount)
    TkTextSegment *segPtr;	/* IBTree segment. */
    int byteCount;		/* Positions to count, 0 < byteCount <=
				 * segPtr->size. */
{
    TkTextLine *linePtr;
    TkTextSegment *sPtr;
    int chars, n;

    chars = 1;				/* The dummy position. */
    byteCount--;
    if (segPtr->body.itree.tree == NULL) {
	return chars;
    }
    for (linePtr = TkIBTreeFirstLine(segPtr);
	    (linePtr != NULL) && (byteCount > 0);
	    linePtr = TkBTreeNextLine(linePtr)) {
	for (sPtr = linePtr->segPtr; (sPtr != NULL) && (byteCount > 0);
		sPtr = sPtr->nextPtr) {
	    n = (sPtr->size < byteCount) ? sPtr->size : byteCount;
	    chars += TkTextSegNumChars(sPtr, n);
	    byteCount -= n;
	}
    }
    return chars;
}

static int
IBTreeCharToByte(segPtr, charCount, restPtr)
    TkTextSegment *segPtr;	/* IBTree segment. */
    int charCount;		/* Character to locate. */
    int *restPtr;		/* Characters left over, if any. */
{
    TkTextLine *linePtr;
    TkTextSegment *sPtr;
    int bytes, offset, rest;

    if (charCount == 0) {
	return 0;			/* The dummy position. */
    }
    charCount--;
    bytes = 1;
    if (segPtr->body.itree.tree != NULL) {
	for (linePtr = TkIBTreeFirstLine(segPtr); linePtr != NULL;
		linePtr = TkBTreeNextLine(linePtr)) {
	    for (sPtr = linePtr->segPtr; sPtr != NULL; sPtr = sPtr->nextPtr) {
		if (bytes >= segPtr->size) {
		    /*
		     * The last internal line is a dummy that is not part
		     * of the index space of the block.
		     */

		    goto done;
		}
		offset = TkTextSegCharToByte(sPtr, charCount, &rest);
		if (offset >= 0) {
		    return bytes + offset;
		}
		charCount = rest;
		bytes += sPtr->size;
	    }
	}
    }
    done:
    *restPtr = charCount;
    return -1;
}

/*
 *--------------------------------------------------------------
 *
 * TkTextLineNumChars --
 *
 *	Count the characters of a line (including its newline).
 *
 * Results:
 *	The number of characters.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

int
TkTextLineNumChars(linePtr)
    TkTextLine *linePtr;	/* Line to count. */
{
    TkTextSegment *segPtr;
    int count = 0;

    for (segPtr = linePtr->segPtr; segPtr != NULL; segPtr = segPtr->nextPtr) {
	count += TkTextSegNumChars(segPtr, segPtr->size);
    }
    return count;
}

/*
 *--------------------------------------------------------------
 *
 * TkTextIndexAdjustToChar --
 *
 *	Make sure that an index does not point into the middle of a
 *	UTF-8 character; if it does, move it to the end of that
 *	character (as Tk 8.4 does).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	*indexPtr may be moved forward by a byte or two.
 *
 *--------------------------------------------------------------
 */

void
TkTextIndexAdjustToChar(indexPtr)
    TkTextIndex *indexPtr;	/* Index to adjust; must be within its
				 * line. */
{
    TkTextIndex intIndex;
    TkTextSegment *segPtr;
    int offset;
    CONST char *start, *p;
    Tcl_UniChar ch;

    if (indexPtr->byteIndex <= 0) {
	return;
    }
    segPtr = TkTextIndexToInternalSeg(indexPtr, &intIndex, &offset);
    if ((segPtr->typePtr == &tkTextCharType) && (offset > 0)
	    && (offset < segPtr->size)) {
	start = segPtr->body.chars + offset;
	p = Tcl_UtfPrev(start, segPtr->body.chars);
	p += Tcl_UtfToUniChar(p, &ch);
	if (p > start) {
	    indexPtr->byteIndex += p - start;
	}
    }
}

/*
 *--------------------------------------------------------------
 *
 * TkTextMakeByteIndex --
 *
 *	Given a line index and a byte offset, look things up
 *	in the B-tree and fill in a TkTextIndex structure.
 *
 * Results:
 *	The structure at *indexPtr is filled in with information
 *	about the character at lineIndex and byteIndex (or the
 *	closest existing character, if the specified one doesn't
 *	exist; a position inside a multi-byte character is moved
 *	to the end of that character), and indexPtr is returned as
 *	result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

TkTextIndex *
TkTextMakeByteIndex(tree, lineIndex, byteIndex, indexPtr)
    TkTextBTree tree;		/* Tree that lineIndex and byteIndex refer
				 * to. */
    int lineIndex;		/* Index of desired line (0 means first
				 * line of text). */
    int byteIndex;		/* Byte offset of desired character. */
    TkTextIndex *indexPtr;	/* Structure to fill in. */
{
    register TkTextSegment *segPtr;
    int index;

    indexPtr->tree = tree;
    if (lineIndex < 0) {
	lineIndex = 0;
	byteIndex = 0;
    }
    if (byteIndex < 0) {
	byteIndex = 0;
    }
    indexPtr->linePtr = TkBTreeFindLine(tree, lineIndex);
    if (indexPtr->linePtr == NULL) {
	indexPtr->linePtr = TkBTreeFindLine(tree, TkBTreeNumLines(tree));
	byteIndex = 0;
    }
    if (byteIndex == 0) {
	indexPtr->byteIndex = 0;
	return indexPtr;
    }

    /*
     * Verify that the index is within the range of the line.
     * If not, just use the index of the last character in the line.
     */

    for (index = 0, segPtr = indexPtr->linePtr->segPtr; ;
	    segPtr = segPtr->nextPtr) {
	if (segPtr == NULL) {
	    indexPtr->byteIndex = index-1;
	    break;
	}
	index += segPtr->size;
	if (index > byteIndex) {
	    indexPtr->byteIndex = byteIndex;
	    break;
	}
    }
    TkTextIndexAdjustToChar(indexPtr);
    return indexPtr;
}

/*
 *--------------------------------------------------------------
 *
 * TkTextMakeCharIndex --
 *
 *	Given a line index and a character index, look things up
 *	in the B-tree and fill in a TkTextIndex structure.
 *
 * Results:
 *	The structure at *indexPtr is filled in with information
 *	about the character at lineIndex and charIndex (or the
 *	closest existing character, if the specified one doesn't
 *	exist), and indexPtr is returned as result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

TkTextIndex *
TkTextMakeCharIndex(tree, lineIndex, charIndex, indexPtr)
    TkTextBTree tree;		/* Tree that lineIndex and charIndex refer
				 * to. */
    int lineIndex;		/* Index of desired line (0 means first
				 * line of text). */
    int charIndex;		/* Index of desired character. */
    TkTextIndex *indexPtr;	/* Structure to fill in. */
{
    register TkTextSegment *segPtr;
    int index, offset, rest;

    indexPtr->tree = tree;
    if (lineIndex < 0) {
	lineIndex = 0;
	charIndex = 0;
    }
    if (charIndex < 0) {
	charIndex = 0;
    }
    indexPtr->linePtr = TkBTreeFindLine(tree, lineIndex);
    if (indexPtr->linePtr == NULL) {
	indexPtr->linePtr = TkBTreeFindLine(tree, TkBTreeNumLines(tree));
	charIndex = 0;
    }

    /*
     * Turn the character offset into a byte offset.  If the line is
     * too short, use the index of its last character (the newline).
     */

    for (index = 0, segPtr = indexPtr->linePtr->segPtr; ;
	    segPtr = segPtr->nextPtr) {
	if (segPtr == NULL) {
	    indexPtr->byteIndex = index-1;
	    break;
	}
	offset = TkTextSegCharToByte(segPtr, charIndex, &rest);
	if (offset >= 0) {
	    indexPtr->byteIndex = index + offset;
	    break;
	}
	charIndex = rest;
	index += segPtr->size;
    }
    return indexPtr;
}

/*
 *--------------------------------------------------------------
 *
 * TkTextIndexToSeg --
 *
 *	Given an index, this procedure returns the segment and
 *	offset within segment for the index.
 *
 * Results:
 *	The return value is a pointer to the segment referred to
 *	by indexPtr;  this will always be a segment with non-zero
 *	size.  The variable at *offsetPtr is set to hold the
 *	integer offset within the segment of the character
 *	given by indexPtr.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

TkTextSegment *
TkTextIndexToSeg(indexPtr, offsetPtr)
    TkTextIndex *indexPtr;		/* Text index. */
    int *offsetPtr;			/* Where to store offset within
					 * segment, or NULL if offset isn't
					 * wanted. */
{
    register TkTextSegment *segPtr;
    int offset;

    for (offset = indexPtr->byteIndex, segPtr = indexPtr->linePtr->segPtr;
	    offset >= segPtr->size;
	    offset -= segPtr->size, segPtr = segPtr->nextPtr) {
	/* Empty loop body. */
    }
    if (offsetPtr != NULL) {
	*offsetPtr = offset;
    }
    return segPtr;
}

/*
 *--------------------------------------------------------------
 *
 * TkTextSegToOffset --
 *
 *	Given a segment pointer and the line containing it, this
 *	procedure returns the offset of the segment within its
 *	line.
 *
 * Results:
 *	The return value is the offset (within its line) of the
 *	first character in segPtr.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

int
TkTextSegToOffset(segPtr, linePtr)
    TkTextSegment *segPtr;		/* Segment whose offset is desired. */
    TkTextLine *linePtr;		/* Line containing segPtr. */
{
    TkTextSegment *segPtr2;
    int offset;

    offset = 0;
    for (segPtr2 = linePtr->segPtr; segPtr2 != segPtr;
	    segPtr2 = segPtr2->nextPtr) {
	offset += segPtr2->size;
    }
    return offset;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextGetIndex --
 *
 *	Given a string, return the line and character indices that
 *	it describes.
 *
 * Results:
 *	The return value is a standard Tcl return result.  If
 *	TCL_OK is returned, then everything went well and the index
 *	at *indexPtr is filled in;  otherwise TCL_ERROR is returned
 *	and an error message is left in Tcl_GetResult(interp).
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkTextGetIndex(interp, textPtr, string, indexPtr)
    Tcl_Interp *interp;		/* Use this for error reporting. */
    TkText *textPtr;		/* Information about text widget. */
    char *string;		/* Textual description of position. */
    TkTextIndex *indexPtr;	/* Index structure to fill in. */
{
    register char *p;
    char *end, *endOfBase;
    Tcl_HashEntry *hPtr;
    TkTextTag *tagPtr;
    TkTextSearch search;
    TkTextIndex first, last;
    int wantLast, result;
    char c;

    /*
     *------------------------------------------------
     * Stage 1: parse the base index.
     *------------------------------------------------
     */

    indexPtr->tree = textPtr->tree;

    /*
     * First look for the form "tag.first" or "tag.last" where "tag"
     * is the name of a valid tag.  Try to use up as much as possible
     * of the string in this check (strrchr instead of strchr below).
     * Doing the check now, and in this way, allows tag names to include
     * funny characters like "@" or "+1c".
     */

    p = strrchr(string, '.');
    if (p != NULL) {
	if ((p[1] == 'f') && (strncmp(p+1, "first", 5) == 0)) {
	    wantLast = 0;
	    endOfBase = p+6;
	} else if ((p[1] == 'l') && (strncmp(p+1, "last", 4) == 0)) {
	    wantLast = 1;
	    endOfBase = p+5;
	} else {
	    goto tryxy;
	}
	*p = 0;
	hPtr = Tcl_FindHashEntry(&textPtr->tagTable, string);
	*p = '.';
	if (hPtr == NULL) {
	    goto tryxy;
	}
	tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);
	TkTextMakeByteIndex(textPtr->tree, 0, 0, &first);
	TkTextMakeByteIndex(textPtr->tree, TkBTreeNumLines(textPtr->tree), 0,
		&last);
	TkBTreeStartSearch(&first, &last, tagPtr, &search);
	if (!TkBTreeCharTagged(&first, tagPtr) && !TkBTreeNextTag(&search)) {
	    Tcl_AppendResult(interp,
		    "text doesn't contain any characters tagged with \"",
		    Tcl_GetHashKey(&textPtr->tagTable, hPtr), "\"",
			             NULL);
	    return TCL_ERROR;
	}
	*indexPtr = search.extIndex;
	if (wantLast) {
	    while (TkBTreeNextTag(&search)) {
		*indexPtr = search.extIndex;
	    }
	}
	goto gotBase;
    }

    tryxy:
    if (string[0] == '@') {
	/*
	 * Find character at a given x,y location in the window.
	 */

	int x, y;

	p = string+1;
	x = strtol(p, &end, 0);
	if ((end == p) || (*end != ',')) {
	    goto error;
	}
	p = end+1;
	y = strtol(p, &end, 0);
	if (end == p) {
	    goto error;
	}
	TkTextPixelIndex(textPtr, x, y, indexPtr);
	endOfBase = end;
	goto gotBase; 
    }

    if (isdigit(UCHAR(string[0])) || (string[0] == '-')) {
	int lineIndex, charIndex;

	/*
	 * Base is identified with line and character indices.
	 */

	lineIndex = strtol(string, &end, 0) - 1;
	if ((end == string) || (*end != '.')) {
	    goto error;
	}
	p = end+1;
	if ((*p == 'e') && (strncmp(p, "end", 3) == 0)) {
	    charIndex = LAST_CHAR;
	    endOfBase = p+3;
	} else {
	    charIndex = strtol(p, &end, 0);
	    if (end == p) {
		goto error;
	    }
	    endOfBase = end;
	}
	TkTextMakeCharIndex(textPtr->tree, lineIndex, charIndex, indexPtr);
	goto gotBase;
    }

    for (p = string; *p != 0; p++) {
	if (isspace(UCHAR(*p)) || (*p == '+') || (*p == '-')) {
	    break;
	}
    }
    endOfBase = p;
    if (string[0] == '.') {
	/*
	 * See if the base position is the name of an embedded window.
	 */

	c = *endOfBase;
	*endOfBase = 0;
	result = TkTextWindowIndex(textPtr, string, indexPtr);
	*endOfBase = c;
	if (result != 0) {
	    goto gotBase;
	}
    }
    if ((string[0] == 'e')
	    && (strncmp(string, "end", (size_t) (endOfBase-string)) == 0)) {
	/*
	 * Base position is end of text.
	 */

	TkTextMakeByteIndex(textPtr->tree, TkBTreeNumLines(textPtr->tree),
		0, indexPtr);
	goto gotBase;
    } else {
	/*
	 * See if the base position is the name of a mark.
	 */

	c = *endOfBase;
	*endOfBase = 0;
	result = TkTextMarkNameToIndex(textPtr, string, indexPtr);
	*endOfBase = c;
	if (result == TCL_OK) {
	    goto gotBase;
	}

	/*
	 * See if the base position is the name of an embedded image.
	 */

	c = *endOfBase;
	*endOfBase = 0;
	result = TkTextImageIndex(textPtr, string, indexPtr);
	*endOfBase = c;
	if (result != 0) {
	    goto gotBase;
	}
    }

    /*
     * Nothing has worked so far.  See if the base has the form
     * "tag.first" or "tag.last" where "tag" is the name of a valid
     * tag.
     */

    p = strchr(string, '.');
    if (p == NULL) {
	goto error;
    }
    if ((p[1] == 'f') && (endOfBase == (p+6))
	    && (strncmp(p+1, "first", (size_t) (endOfBase - (p+1))) == 0)) {
	wantLast = 0;
    } else if ((p[1] == 'l') && (endOfBase == (p+5))
	    && (strncmp(p+1, "last", (size_t) (endOfBase - (p+1))) == 0)) {
	wantLast = 1;
    } else {
	goto error;
    }
    *p = 0;
    hPtr = Tcl_FindHashEntry(&textPtr->tagTable, string);
    *p = '.';
    if (hPtr == NULL) {
	goto error;
    }
    tagPtr = (TkTextTag *) Tcl_GetHashValue(hPtr);
    TkTextMakeByteIndex(textPtr->tree, 0, 0, &first);
    TkTextMakeByteIndex(textPtr->tree, TkBTreeNumLines(textPtr->tree), 0, &last);
    TkBTreeStartSearch(&first, &last, tagPtr, &search);
    if (!TkBTreeCharTagged(&first, tagPtr) && !TkBTreeNextTag(&search)) {
	Tcl_AppendResult(interp,
		"text doesn't contain any characters tagged with \"",
		Tcl_GetHashKey(&textPtr->tagTable, hPtr), "\"",          NULL);
	return TCL_ERROR;
    }
    *indexPtr = search.extIndex;
    if (wantLast) {
	while (TkBTreeNextTag(&search)) {
	    *indexPtr = search.extIndex;
	}
    }

    /*
     *-------------------------------------------------------------------
     * Stage 2: process zero or more modifiers.  Each modifier is either
     * a keyword like "wordend" or "linestart", or it has the form
     * "op count units" where op is + or -, count is a number, and units
     * is "chars", "indices" or "lines".  A keyword or the units may be
     * preceded by "display" (elided text is left out) or "any" (it is
     * not: the default), as in Tk 8.5.
     *-------------------------------------------------------------------
     */

    gotBase:
    p = endOfBase;
    while (1) {
	while (isspace(UCHAR(*p))) {
	    p++;
	}
	if (*p == 0) {
	    break;
	}
    
	if ((*p == '+') || (*p == '-')) {
	    p = ForwBack(textPtr, p, indexPtr);
	} else {
	    p = StartEnd(textPtr, p, indexPtr);
	}
	if (p == NULL) {
	    goto error;
	}
    }
    return TCL_OK;

    error:
    Tcl_AppendResult(interp, "bad text index \"", string, "\"",
	             NULL);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexCharOffset --
 *
 *	Compute the character offset (what "line.char" shows) of an
 *	index within its line.
 *
 * Results:
 *	The number of characters before the index in its line.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkTextIndexCharOffset(indexPtr)
    TkTextIndex *indexPtr;	/* Pointer to index. */
{
    TkTextSegment *segPtr;
    int numBytes, charIndex, n;

    numBytes = indexPtr->byteIndex;
    charIndex = 0;
    for (segPtr = indexPtr->linePtr->segPtr;
	    (segPtr != NULL) && (numBytes > 0); segPtr = segPtr->nextPtr) {
	n = (segPtr->size < numBytes) ? segPtr->size : numBytes;
	charIndex += TkTextSegNumChars(segPtr, n);
	numBytes -= n;
    }
    return charIndex;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexCountChars --
 *
 *	Count the characters between two indices.
 *
 * Results:
 *	The number of characters from index1Ptr up to (not including)
 *	index2Ptr; 0 if index2Ptr is not after index1Ptr.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

int
TkTextIndexCountChars(index1Ptr, index2Ptr)
    TkTextIndex *index1Ptr;	/* Start of the range. */
    TkTextIndex *index2Ptr;	/* End of the range. */
{
    TkTextLine *linePtr;
    int count;

    if (TkTextIndexCmp(index1Ptr, index2Ptr) >= 0) {
	return 0;
    }
    if (index1Ptr->linePtr == index2Ptr->linePtr) {
	return TkTextIndexCharOffset(index2Ptr)
		- TkTextIndexCharOffset(index1Ptr);
    }
    count = TkTextLineNumChars(index1Ptr->linePtr)
	    - TkTextIndexCharOffset(index1Ptr);
    for (linePtr = TkBTreeNextLine(index1Ptr->linePtr);
	    (linePtr != NULL) && (linePtr != index2Ptr->linePtr);
	    linePtr = TkBTreeNextLine(linePtr)) {
	count += TkTextLineNumChars(linePtr);
    }
    return count + TkTextIndexCharOffset(index2Ptr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextPrintIndex --
 *
 *	
 *	This procedure generates a string description of an index,
 *	suitable for reading in again later.
 *
 * Results:
 *	The characters pointed to by string are modified.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TkTextPrintIndex(indexPtr, string)
    TkTextIndex *indexPtr;	/* Pointer to index. */
    char *string;		/* Place to store the position.  Must have
				 * at least TK_POS_CHARS characters. */
{
    sprintf(string, "%d.%d", TkBTreeLineIndex(indexPtr->linePtr) + 1,
	    TkTextIndexCharOffset(indexPtr));
}

/*
 *--------------------------------------------------------------
 *
 * TkTextIndexCmp --
 *
 *	Compare two indices to see which one is earlier in
 *	the text.
 *
 * Results:
 *	The return value is 0 if index1Ptr and index2Ptr refer
 *	to the same position in the file, -1 if index1Ptr refers
 *	to an earlier position than index2Ptr, and 1 otherwise.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

int
TkTextIndexCmp(index1Ptr, index2Ptr)
    TkTextIndex *index1Ptr;		/* First index. */
    TkTextIndex *index2Ptr;		/* Second index. */
{
    int line1, line2;

    if (index1Ptr->linePtr == index2Ptr->linePtr) {
	if (index1Ptr->byteIndex < index2Ptr->byteIndex) {
	    return -1;
	} else if (index1Ptr->byteIndex > index2Ptr->byteIndex) {
	    return 1;
	} else {
	    return 0;
	}
    }
    line1 = TkBTreeLineIndex(index1Ptr->linePtr);
    line2 = TkBTreeLineIndex(index2Ptr->linePtr);
    if (line1 < line2) {
	return -1;
    }
    if (line1 > line2) {
	return 1;
    }
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * ForwBack --
 *
 *	This procedure handles +/- modifiers for indices to adjust
 *	the index forwards or backwards.
 *
 * Results:
 *	If the modifier in string is successfully parsed then the
 *	return value is the address of the first character after the
 *	modifier, and *indexPtr is updated to reflect the modifier.
 *	If there is a syntax error in the modifier then NULL is returned.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static char *
ForwBack(textPtr, string, indexPtr)
    TkText *textPtr;		/* Overall information about text widget. */
    char *string;		/* String to parse for additional info
				 * about modifier (count and units). 
				 * Points to "+" or "-" that starts
				 * modifier. */
    TkTextIndex *indexPtr;	/* Index to update as specified in string. */
{
    register char *p;
    char *end, *units;
    int count, lineIndex, modifier;
    size_t length;

    /*
     * Get the count (how many units forward or backward).
     */

    p = string+1;
    while (isspace(UCHAR(*p))) {
	p++;
    }
    count = strtol(p, &end, 0);
    if (end == p) {
	return NULL;
    }
    p = end;
    while (isspace(UCHAR(*p))) {
	p++;
    }

    /*
     * Find the end of this modifier (next space or + or - character),
     * after an optional "display" or "any", then parse the unit
     * specifier and update the position accordingly.  "chars" and
     * "indices" are the same here: every position of the index space
     * is a character (Tk 8.4), the dummy position of a block included.
     */

    units = p; 
    modifier = ParseModifier(&units, &length);
    p = units + length;
    if (((*units == 'c') && (strncmp(units, "chars", length) == 0))
	    || ((*units == 'i') && (strncmp(units, "indices", length) == 0))) {
	if (modifier == TKINDEX_DISPLAY) {
	    if (*string == '+') {
		ForwDisplayChars(textPtr, indexPtr, count, indexPtr);
	    } else {
		BackDisplayChars(textPtr, indexPtr, count, indexPtr);
	    }
	} else if (*string == '+') {
	    TkTextIndexForwChars(indexPtr, count, indexPtr);
	} else {
	    TkTextIndexBackChars(indexPtr, count, indexPtr);
	}
    } else if ((*units == 'l') && (strncmp(units, "lines", length) == 0)) {
	if (modifier == TKINDEX_DISPLAY) {
	    int xOffset, forward;

	    /*
	     * Display lines, keeping the x coordinate (Tk 8.5): from
	     * the end of the current display line one visible position
	     * on is the start of the next (an entirely elided line is
	     * passed over on the way), from the start one visible
	     * position back is the end of the previous one.  A base
	     * inside elided text stands for the first visible position
	     * after it.  The direction depends on the sign of the count
	     * too ("+ -3 display lines" goes back).
	     */

	    if (TkTextIsElided(textPtr, indexPtr)) {
		ForwDisplayChars(textPtr, indexPtr, 0, indexPtr);
	    }
	    forward = !((count < 0) ^ (*string == '-'));
	    if (count < 0) {
		count = -count;
	    }
	    if (count == 0) {
		return p;
	    }
	    if (forward) {
		TkTextIndex index2;

		if (TkBTreeLineIndex(indexPtr->linePtr)
			== TkBTreeNumLines(indexPtr->tree)) {
		    return p;			/* At "end" already. */
		}
		TkTextFindDisplayLineEnd(textPtr, indexPtr, 1, &xOffset);
		while (count-- > 0) {
		    TkTextFindDisplayLineEnd(textPtr, indexPtr, 1, (int *) NULL);
		    ForwDisplayChars(textPtr, indexPtr, 1, &index2);
		    if (TkBTreeLineIndex(index2.linePtr)
			    == TkBTreeNumLines(index2.tree)) {
			/*
			 * The dummy last line is no display line: the
			 * last one is as far as it goes (Tk 8.5).
			 */

			break;
		    }
		    *indexPtr = index2;
		}
	    } else {
		TkTextIndex index2;

		TkTextFindDisplayLineEnd(textPtr, indexPtr, 0, &xOffset);
		while (count-- > 0) {
		    TkTextFindDisplayLineEnd(textPtr, indexPtr, 0, (int *) NULL);
		    BackDisplayChars(textPtr, indexPtr, 1, &index2);
		    if (TkTextIndexCmp(indexPtr, &index2) == 0) {
			/*
			 * The start of the text: the first display line,
			 * from its start.
			 */

			xOffset = 0;
			break;
		    }
		    *indexPtr = index2;
		}
	    }
	    TkTextFindDisplayLineEnd(textPtr, indexPtr, 0, (int *) NULL);
	    TkTextIndexOfX(textPtr, xOffset, indexPtr);
	    return p;
	}
	lineIndex = TkBTreeLineIndex(indexPtr->linePtr);
	if (*string == '+') {
	    lineIndex += count;
	} else {
	    lineIndex -= count;

	    /*
	     * The check below retains the character position, even
	     * if the line runs off the start of the file.  Without
	     * it, the character position will get reset to 0 by
	     * TkTextMakeByteIndex.
	     */

	    if (lineIndex < 0) {
		lineIndex = 0;
	    }
	}

	/*
	 * Keep the character position (Tk 8.4 keeps the byte offset,
	 * adjusted to a character boundary, and admits in a comment that
	 * this is wrong with multi-byte characters: TK_BUGS.md A5).
	 */

	TkTextMakeCharIndex(indexPtr->tree, lineIndex,
		TkTextIndexCharOffset(indexPtr), indexPtr);
    } else {
	return NULL;
    }
    return p;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexForwBytes --
 *
 *	Given an index for a text widget, this procedure creates a
 *	new index that points "count" bytes (positions of index
 *	space) ahead of the source index.
 *
 * Results:
 *	*dstPtr is modified to refer to the position "count" bytes
 *	after srcPtr, or to the last character in the file if there
 *	aren't "count" bytes left in the file.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TkTextIndexForwBytes(srcPtr, count, dstPtr)
    TkTextIndex *srcPtr;		/* Source index. */
    int count;				/* How many bytes forward to
					 * move.  May be negative. */
    TkTextIndex *dstPtr;		/* Destination index: gets modified. */
{
    TkTextLine *linePtr;
    TkTextSegment *segPtr;
    int lineLength;

    if (count < 0) {
	TkTextIndexBackBytes(srcPtr, -count, dstPtr);
	return;
    }
    *dstPtr = *srcPtr;
    dstPtr->byteIndex += count;
    while (1) {
	/*
	 * Compute the length of the current line.
	 */

	lineLength = 0;
	for (segPtr = dstPtr->linePtr->segPtr; segPtr != NULL;
		segPtr = segPtr->nextPtr) {
	    lineLength += segPtr->size;
	}

	/*
	 * If the new index is in the same line then we're done.
	 * Otherwise go on to the next line.
	 */

	if (dstPtr->byteIndex < lineLength) {
	    return;
	}
	dstPtr->byteIndex -= lineLength;
	linePtr = TkBTreeNextLine(dstPtr->linePtr);
	if (linePtr == NULL) {
	    dstPtr->byteIndex = lineLength - 1;
	    return;
	}
	dstPtr->linePtr = linePtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexBackBytes --
 *
 *	Given an index for a text widget, this procedure creates a
 *	new index that points "count" bytes earlier than the source
 *	index.
 *
 * Results:
 *	*dstPtr is modified to refer to the position "count" bytes
 *	before srcPtr, or to the first character in the file if there
 *	aren't "count" bytes earlier than srcPtr.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TkTextIndexBackBytes(srcPtr, count, dstPtr)
    TkTextIndex *srcPtr;		/* Source index. */
    int count;				/* How many bytes backward to
					 * move.  May be negative. */
    TkTextIndex *dstPtr;		/* Destination index: gets modified. */
{
    TkTextSegment *segPtr;
    int lineIndex;

    if (count < 0) {
	TkTextIndexForwBytes(srcPtr, -count, dstPtr);
	return;
    }
    *dstPtr = *srcPtr;
    dstPtr->byteIndex -= count;
    lineIndex = -1;
    while (dstPtr->byteIndex < 0) {
	/*
	 * Move back one line in the text.  If we run off the beginning
	 * of the file then just return the first character in the text.
	 */

	if (lineIndex < 0) {
	    lineIndex = TkBTreeLineIndex(dstPtr->linePtr);
	}
	if (lineIndex == 0) {
	    dstPtr->byteIndex = 0;
	    return;
	}
	lineIndex--;
	dstPtr->linePtr = TkBTreeFindLine(dstPtr->tree, lineIndex);

	/*
	 * Compute the length of the line and add that to dstPtr->byteIndex.
	 */

	for (segPtr = dstPtr->linePtr->segPtr; segPtr != NULL;
		segPtr = segPtr->nextPtr) {
	    dstPtr->byteIndex += segPtr->size;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexForwChars --
 *
 *	Given an index for a text widget, this procedure creates a
 *	new index that points "count" characters ahead of the source
 *	index.
 *
 * Results:
 *	*dstPtr is modified to refer to the character "count" characters
 *	after srcPtr, or to the last character in the file if there aren't
 *	"count" characters left in the file.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

	/* ARGSUSED */
void
TkTextIndexForwChars(srcPtr, count, dstPtr)
    TkTextIndex *srcPtr;		/* Source index. */
    int count;				/* How many characters forward to
					 * move.  May be negative. */
    TkTextIndex *dstPtr;		/* Destination index: gets modified. */
{
    TkTextLine *linePtr;
    TkTextSegment *segPtr;
    int byteOffset, before, total, offset, rest;
    char *start, *end, *p;
    Tcl_UniChar ch;

    if (count < 0) {
	TkTextIndexBackChars(srcPtr, -count, dstPtr);
	return;
    }
    *dstPtr = *srcPtr;

    /*
     * Find the segment that contains the source position, then move
     * forward the specified number of characters.
     */

    segPtr = TkTextIndexToSeg(dstPtr, &byteOffset);
    while (1) {
	for ( ; segPtr != NULL; segPtr = segPtr->nextPtr) {
	    if (segPtr->typePtr == &tkTextCharType) {
		start = segPtr->body.chars + byteOffset;
		end = segPtr->body.chars + segPtr->size;
		for (p = start; p < end; p += Tcl_UtfToUniChar(p, &ch)) {
		    if (count == 0) {
			dstPtr->byteIndex += (p - start);
			return;
		    }
		    count--;
		}
	    } else if (segPtr->typePtr == &tkTextIBTreeType) {
		before = TkTextSegNumChars(segPtr, byteOffset);
		total = TkTextSegNumChars(segPtr, segPtr->size);
		if (count < total - before) {
		    offset = TkTextSegCharToByte(segPtr, before + count, &rest);
		    dstPtr->byteIndex += offset - byteOffset;
		    return;
		}
		count -= total - before;
	    } else {
		if (count < segPtr->size - byteOffset) {
		    dstPtr->byteIndex += count;
		    return;
		}
		count -= segPtr->size - byteOffset;
	    }
	    dstPtr->byteIndex += segPtr->size - byteOffset;
	    byteOffset = 0;
	}

	/*
	 * Go to the next line.  If we are at the end of the text, back
	 * up one byte (for the terminal '\n' character) and return that
	 * index.
	 */

	linePtr = TkBTreeNextLine(dstPtr->linePtr);
	if (linePtr == NULL) {
	    dstPtr->byteIndex -= 1;
	    return;
	}
	dstPtr->linePtr = linePtr;
	dstPtr->byteIndex = 0;
	segPtr = linePtr->segPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextIndexBackChars --
 *
 *	Given an index for a text widget, this procedure creates a
 *	new index that points "count" characters earlier than the
 *	source index.
 *
 * Results:
 *	*dstPtr is modified to refer to the character "count" characters
 *	before srcPtr, or to the first character in the file if there
 *	aren't "count" characters earlier than srcPtr.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

void
TkTextIndexBackChars(srcPtr, count, dstPtr)
    TkTextIndex *srcPtr;		/* Source index. */
    int count;				/* How many characters backward to
					 * move.  May be negative. */
    TkTextIndex *dstPtr;		/* Destination index: gets modified. */
{
    TkTextSegment *segPtr, *oldPtr;
    int lineIndex, segSize, before, offset, rest;
    CONST char *p, *start, *end;

    if (count <= 0) {
	TkTextIndexForwChars(srcPtr, -count, dstPtr);
	return;
    }
    *dstPtr = *srcPtr;

    /*
     * Find the offset within the segment that contains the source
     * position (a position at a segment boundary belongs to the
     * earlier segment here), then move backward the specified number
     * of characters.
     */

    lineIndex = -1;
    segSize = dstPtr->byteIndex;
    for (segPtr = dstPtr->linePtr->segPtr; ; segPtr = segPtr->nextPtr) {
	if (segSize <= segPtr->size) {
	    break;
	}
	segSize -= segPtr->size;
    }
    while (1) {
	if (segPtr->typePtr == &tkTextCharType) {
	    start = segPtr->body.chars;
	    end = segPtr->body.chars + segSize;
	    for (p = end; ; p = Tcl_UtfPrev(p, start)) {
		if (count == 0) {
		    dstPtr->byteIndex -= (end - p);
		    return;
		}
		if (p == start) {
		    break;
		}
		count--;
	    }
	} else if (segPtr->typePtr == &tkTextIBTreeType) {
	    before = TkTextSegNumChars(segPtr, segSize);
	    if (count <= before) {
		offset = TkTextSegCharToByte(segPtr, before - count, &rest);
		dstPtr->byteIndex -= segSize - offset;
		return;
	    }
	    count -= before;
	} else {
	    if (count <= segSize) {
		dstPtr->byteIndex -= count;
		return;
	    }
	    count -= segSize;
	}
	dstPtr->byteIndex -= segSize;

	/*
	 * Move back into the previous segment.
	 */

	oldPtr = segPtr;
	segPtr = dstPtr->linePtr->segPtr;
	if (segPtr != oldPtr) {
	    for ( ; segPtr->nextPtr != oldPtr; segPtr = segPtr->nextPtr) {
		/* Empty body. */
	    }
	    segSize = segPtr->size;
	    continue;
	}

	/*
	 * Move back to the previous line.
	 */

	if (lineIndex < 0) {
	    lineIndex = TkBTreeLineIndex(dstPtr->linePtr);
	}
	if (lineIndex == 0) {
	    dstPtr->byteIndex = 0;
	    return;
	}
	lineIndex--;
	dstPtr->linePtr = TkBTreeFindLine(dstPtr->tree, lineIndex);

	/*
	 * Compute the length of the line and add that to dstPtr->byteIndex.
	 */

	oldPtr = dstPtr->linePtr->segPtr;
	for (segPtr = oldPtr; segPtr != NULL; segPtr = segPtr->nextPtr) {
	    dstPtr->byteIndex += segPtr->size;
	    oldPtr = segPtr;
	}
	segPtr = oldPtr;
	segSize = segPtr->size;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ParseModifier --
 *
 *	Recognize an optional "display" or "any" in front of the units
 *	of an index modifier (Tk 8.5): on its own, where it may be
 *	abbreviated ("d chars"), or glued to the units, where it may not
 *	("displaychars").
 *
 * Results:
 *	TKINDEX_DISPLAY, TKINDEX_ANY or TKINDEX_NONE.  *unitsPtr is
 *	moved to the start of the units word and *lengthPtr set to its
 *	length (up to a space, "+" or "-").
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
ParseModifier(unitsPtr, lengthPtr)
    char **unitsPtr;		/* In: the start of the word; out: the
				 * start of the units. */
    size_t *lengthPtr;		/* Out: the length of the units. */
{
    char *units = *unitsPtr, *p;
    size_t length;
    int modifier = TKINDEX_NONE;

    for (p = units; (*p != 0) && !isspace(UCHAR(*p)) && (*p != '+')
	    && (*p != '-'); p++) {
	/* Empty loop body. */
    }
    length = p - units;
    if ((*units == 'd')
	    && (strncmp(units, "display", (length > 7) ? 7 : length) == 0)) {
	modifier = TKINDEX_DISPLAY;
	if (length > 7) {
	    p -= length - 7;
	}
    } else if ((*units == 'a')
	    && (strncmp(units, "any", (length > 3) ? 3 : length) == 0)) {
	modifier = TKINDEX_ANY;
	if (length > 3) {
	    p -= length - 3;
	}
    }
    if (modifier != TKINDEX_NONE) {
	while (isspace(UCHAR(*p))) {
	    p++;
	}
	units = p;
	while ((*p != 0) && !isspace(UCHAR(*p)) && (*p != '+')
		&& (*p != '-')) {
	    p++;
	}
	length = p - units;
    }
    *unitsPtr = units;
    *lengthPtr = length;
    return modifier;
}

/*
 *----------------------------------------------------------------------
 *
 * ForwDisplayChars, BackDisplayChars --
 *
 *	Move an index by "count" visible positions: elided ones (the
 *	character there is hidden by a tag's -elide) are left out, as
 *	in Tk 8.5's "display chars" and "display indices".  With a
 *	count of 0 the index moves to the first visible position at or
 *	after it (forward), or stays if visible and goes to the start
 *	of the elided stretch around it otherwise (backward): the
 *	semantics of Tk 8.5, where the position reached is the one the
 *	count reaches 0 at.  The elision is asked of the widget for
 *	every position on the way (TkTextIsElided looks into blocks).
 *
 * Results:
 *	*dstPtr is modified.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
ForwDisplayChars(textPtr, srcPtr, count, dstPtr)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *srcPtr;	/* Source index. */
    int count;			/* How many visible positions forward;
				 * may be negative. */
    TkTextIndex *dstPtr;	/* Destination index: gets modified. */
{
    TkTextIndex index = *srcPtr, next;

    if (count < 0) {
	BackDisplayChars(textPtr, srcPtr, -count, dstPtr);
	return;
    }
    while (1) {
	if (!TkTextIsElided(textPtr, &index)) {
	    if (count == 0) {
		break;
	    }
	    count--;
	}
	TkTextIndexForwChars(&index, 1, &next);
	if (TkTextIndexCmp(&next, &index) == 0) {
	    break;				/* The end of the text. */
	}
	index = next;
    }
    *dstPtr = index;
}

static void
BackDisplayChars(textPtr, srcPtr, count, dstPtr)
    TkText *textPtr;		/* Overall information about text widget. */
    TkTextIndex *srcPtr;	/* Source index. */
    int count;			/* How many visible positions backward;
				 * may be negative. */
    TkTextIndex *dstPtr;	/* Destination index: gets modified. */
{
    TkTextIndex index = *srcPtr, prev;

    if (count < 0) {
	ForwDisplayChars(textPtr, srcPtr, -count, dstPtr);
	return;
    }
    if ((count == 0) && !TkTextIsElided(textPtr, &index)) {
	*dstPtr = index;
	return;
    }
    while (1) {
	TkTextIndexBackChars(&index, 1, &prev);
	if (TkTextIndexCmp(&prev, &index) == 0) {
	    break;				/* The start of the text. */
	}
	if (!TkTextIsElided(textPtr, &prev)) {
	    if (count == 0) {
		break;				/* index starts the elided stretch. */
	    }
	    if (--count == 0) {
		index = prev;
		break;
	    }
	}
	index = prev;
    }
    *dstPtr = index;
}

/*
 *----------------------------------------------------------------------
 *
 * IndexIsWordChar --
 *
 *	Whether the character at an index (inside a block, if need be)
 *	is part of a word.  The head, the separators and the tail of a
 *	block, windows and images are not.
 *
 * Results:
 *	0 or 1.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static int
IndexIsWordChar(indexPtr)
    TkTextIndex *indexPtr;	/* The position. */
{
    TkTextIndex intIndex;
    TkTextSegment *segPtr;
    Tcl_UniChar ch;
    int offset;

    segPtr = TkTextIndexToInternalSeg(indexPtr, &intIndex, &offset);
    if (segPtr->typePtr != &tkTextCharType) {
	return 0;
    }
    Tcl_UtfToUniChar(segPtr->body.chars + offset, &ch);
    return Tcl_UniCharIsWordChar(ch);
}

/*
 *----------------------------------------------------------------------
 *
 * StartEnd --
 *
 *	This procedure handles modifiers like "wordstart" and "lineend"
 *	to adjust indices forwards or backwards.
 *
 * Results:
 *	If the modifier is successfully parsed then the return value
 *	is the address of the first character after the modifier, and
 *	*indexPtr is updated to reflect the modifier. If there is a
 *	syntax error in the modifier then NULL is returned.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static char *
StartEnd(textPtr, string, indexPtr)
    TkText *textPtr;		/* Overall information about text widget. */
    char *string;		/* String to parse for additional info
				 * about modifier (count and units). 
				 * Points to first character of modifer
				 * word. */
    TkTextIndex *indexPtr;	/* Index to mdoify based on string. */
{
    char *p;
    int offset, modifier;
    size_t length;
    register TkTextSegment *segPtr;

    /*
     * Find the end of the modifier word, after an optional "display"
     * or "any".
     */

    modifier = ParseModifier(&string, &length);
    p = string + length;
    if ((*string == 'l') && (strncmp(string, "lineend", length) == 0)
	    && (length >= 5) && (modifier == TKINDEX_DISPLAY)) {
	/*
	 * The last position of the display line containing the index
	 * (Tk 8.5), found by laying the logical line out.
	 */

	TkTextFindDisplayLineEnd(textPtr, indexPtr, 1, (int *) NULL);
    } else if ((*string == 'l') && (strncmp(string, "linestart", length) == 0)
	    && (length >= 5) && (modifier == TKINDEX_DISPLAY)) {
	TkTextFindDisplayLineEnd(textPtr, indexPtr, 0, (int *) NULL);
    } else if ((*string == 'l') && (strncmp(string, "lineend", length) == 0)
	    && (length >= 5)) {
	indexPtr->byteIndex = 0;
	for (segPtr = indexPtr->linePtr->segPtr; segPtr != NULL;
		segPtr = segPtr->nextPtr) {
	    indexPtr->byteIndex += segPtr->size;
	}
	indexPtr->byteIndex -= 1;
    } else if ((*string == 'l') && (strncmp(string, "linestart", length) == 0)
	    && (length >= 5)) {
	indexPtr->byteIndex = 0;
    } else if ((*string == 'w') && (strncmp(string, "wordend", length) == 0)
	    && (length >= 5) && (modifier == TKINDEX_DISPLAY)) {
	int firstChar = 1;
	TkTextIndex next;

	/*
	 * As below, over the visible characters only: elided ones are
	 * left out as if they were not there.  (Tk 8.6 leaves out only
	 * those at the start, so its "display wordend" can end inside
	 * elided text; TK_BUGS.md A6.)
	 */

	ForwDisplayChars(textPtr, indexPtr, 0, indexPtr);
	while (IndexIsWordChar(indexPtr)) {
	    firstChar = 0;
	    ForwDisplayChars(textPtr, indexPtr, 1, &next);
	    if (TkTextIndexCmp(&next, indexPtr) == 0) {
		break;				/* The end of the text. */
	    }
	    *indexPtr = next;
	}
	if (firstChar) {
	    ForwDisplayChars(textPtr, indexPtr, 1, indexPtr);
	}
    } else if ((*string == 'w') && (strncmp(string, "wordstart", length) == 0)
	    && (length >= 5) && (modifier == TKINDEX_DISPLAY)) {
	int firstChar = 1;
	TkTextIndex prev;

	/*
	 * As below, over the visible characters only.
	 */

	ForwDisplayChars(textPtr, indexPtr, 0, indexPtr);
	while (IndexIsWordChar(indexPtr)) {
	    firstChar = 0;
	    BackDisplayChars(textPtr, indexPtr, 1, &prev);
	    if (TkTextIndexCmp(&prev, indexPtr) == 0) {
		goto done;			/* The start of the text. */
	    }
	    *indexPtr = prev;
	}
	if (!firstChar) {
	    ForwDisplayChars(textPtr, indexPtr, 1, indexPtr);
	}
    } else if ((*string == 'w') && (strncmp(string, "wordend", length) == 0)
	    && (length >= 5)) {
	int firstChar = 1;

	/*
	 * If the current character isn't part of a word then just move
	 * forward one character.  Otherwise move forward until finding
	 * a character that isn't part of a word and stop there.
	 */

	segPtr = TkTextIndexToSeg(indexPtr, &offset);
	while (1) {
	    int chSize = 1;

	    if (segPtr->typePtr == &tkTextCharType) {
		Tcl_UniChar ch;

		chSize = Tcl_UtfToUniChar(segPtr->body.chars + offset, &ch);
		if (!Tcl_UniCharIsWordChar(ch)) {
		    break;
		}
		firstChar = 0;
	    }
	    offset += chSize;
	    indexPtr->byteIndex += chSize;
	    if (offset >= segPtr->size) {
		segPtr = TkTextIndexToSeg(indexPtr, &offset);
	    }
	}
	if (firstChar) {
	    TkTextIndexForwChars(indexPtr, 1, indexPtr);
	}
    } else if ((*string == 'w') && (strncmp(string, "wordstart", length) == 0)
	    && (length >= 5)) {
	int firstChar = 1;

	/*
	 * Starting with the current character, look for one that's not
	 * part of a word and keep moving backward until you find one.
	 * Then if the character found wasn't the first one, move forward
	 * again one position.
	 */

	segPtr = TkTextIndexToSeg(indexPtr, &offset);
	while (1) {
	    int chSize = 1;

	    if (segPtr->typePtr == &tkTextCharType) {
		Tcl_UniChar ch;

		Tcl_UtfToUniChar(segPtr->body.chars + offset, &ch);
		if (!Tcl_UniCharIsWordChar(ch)) {
		    break;
		}
		if (offset > 0) {
		    chSize = (segPtr->body.chars + offset
			    - Tcl_UtfPrev(segPtr->body.chars + offset,
			    segPtr->body.chars));
		}
		firstChar = 0;
	    }
	    offset -= chSize;
	    indexPtr->byteIndex -= chSize;
	    if (offset < 0) {
		if (indexPtr->byteIndex < 0) {
		    indexPtr->byteIndex = 0;
		    goto done;
		}
		segPtr = TkTextIndexToSeg(indexPtr, &offset);
	    }
	}
	if (!firstChar) {
	    TkTextIndexForwChars(indexPtr, 1, indexPtr);
	}
    } else {
	return NULL;
    }
    done:
    return p;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextUtfToLowerSameLength --
 *
 *	Convert a UTF-8 string to lower case in place, touching only
 *	the characters whose lower-case form has the same length in
 *	bytes (so that offsets into the string stay valid; used by
 *	"search -nocase", which maps offsets back to indices).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The string is modified.
 *
 *----------------------------------------------------------------------
 */

int
TkTextUtfToLowerSameLength(str, len)
    char *str;			/* String to convert (need not be
				 * NUL-terminated). */
    int len;			/* Its length in bytes. */
{
    char *p = str, *end = str + len;
    char buf[TCL_UTF_MAX + 1];
    Tcl_UniChar ch, lower;
    int n, m;

    while (p < end) {
	n = Tcl_UtfToUniChar(p, &ch);
	if (p + n > end) {
	    break;
	}
	lower = Tcl_UniCharToLower(ch);
	if (lower != ch) {
	    m = Tcl_UniCharToUtf(lower, buf);
	    if (m == n) {
		memcpy(p, buf, (size_t) n);
	    }
	}
	p += n;
    }
    return len;
}
