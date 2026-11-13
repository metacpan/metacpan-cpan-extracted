/*
 * tkTextOrn.c --
 *
 *	Ornaments: drawing primitives of the canvas kind (lines,
 *	polygons, rectangles, ovals, arcs, texts) whose coordinates are
 *	not numbers but "reference points": points computed from the
 *	places where positions of the text are drawn (the corners,
 *	sides and baseline of a character's box, or of the box of a
 *	range), and from other reference points (weighted means,
 *	offsets, the x of one point with the y of another, minima and
 *	maxima).
 *
 *	An ornament is drawn over (or under) the text, into the
 *	display lines it crosses; it is computed anew at every
 *	redisplay, so it follows the text it refers to.  A position
 *	that is not displayed gets a stand-in place ("proxy") above or
 *	below the window (see TkTextOrnCharBox in tkTextDisp.c); an
 *	ornament none of whose positions is displayed is not drawn.
 *
 *	The point specifications (a list per point):
 *
 *	    {at index ?anchor?}		the box of the character at index
 *	    {range index1 index2 ?anchor?}
 *					the union of the boxes of the
 *					characters in [index1, index2)
 *	    {mix w1 p1 w2 p2 ...}	(w1*p1 + w2*p2 + ...)/(w1 + w2 + ...)
 *	    {offset p dx dy}		p moved by dx, dy (screen distances)
 *	    {xy p1 p2}			the x of p1 with the y of p2
 *	    {yx p1 p2}			the y of p1 with the x of p2
 *	    {min p1 p2 ...}, {max p1 p2 ...}
 *					coordinate-wise minimum, maximum
 *	    {line index1 index2 n ?anchor?}
 *					the piece of the range on its n-th
 *					display line
 *	    {outline index1 index2}	(in a line or a polygon) all the
 *					corners of the range's outline
 *
 *	The distances of an offset may be in em or ex of the font of the
 *	point (emmin, emmid, emmax, exmin ...: of a range's smallest,
 *	middle or largest font).
 *
 *	Anchors: nw n ne w center e sw s se (as in Tk), bw b be: the
 *	left end, middle and right end of the baseline, mw m me: of the
 *	mid line, or {fx fy}: fractions of the box.  The default is bw.  An index that names no mark and no tag becomes
 *	a private mark of the ornament (see OrnIndex); the others are
 *	kept as strings and parsed at every redisplay, so marks
 *	("insert", names of marks, "tag.first") make the ornament follow
 *	the text.  {leftward index} and {rightward index} make a private
 *	mark of that gravity.
 */

#include "pperl.h"
#include "tkPort.h"
#include "tkInt.h"
#include "tkText.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/*
 * Kinds of point specifications.
 */

#define PT_AT		0
#define PT_RANGE	1
#define PT_MIX		2
#define PT_OFFSET	3
#define PT_XY		4
#define PT_MIN		5
#define PT_MAX		6
#define PT_LINE		7
#define PT_OUTLINE	8
#define PT_YX		9
#define PT_LEAF		10	/* Only in a block type's -ornaments: */
#define PT_BLOCK	11	/* the box of a leaf, of the block. */

static char *kindNames[] = {"at", "range", "mix", "offset", "xy", "min",
	"max", "line", "outline", "yx", "leaf", "block", NULL};

/*
 * Units of the distances of an offset: pixels (a screen distance), or
 * a number of em or ex of the font of the point (the smallest, the
 * mean of the smallest and the largest, or the largest font of a
 * range; by default the largest).
 */

#define U_PIXELS	0
static char *unitNames[] = {"", "em", "emmin", "emmid", "emmax",
	"ex", "exmin", "exmid", "exmax", NULL};

/*
 * Anchors: the horizontal part (0 west, 1 center, 2 east) plus 3 times
 * the vertical part (0 north, 1 center, 2 south, 3 baseline, 4 mid
 * line: half an x-height above the baseline); or ANCHOR_FRAC: the
 * fractions fx of the width from the left, fy of the height from the
 * top.
 */

#define ANCHOR(h, v)	((h) + 3*(v))
#define ANCHOR_H(a)	((a) % 3)
#define ANCHOR_V(a)	((a) / 3)
#define ANCHOR_FRAC	(-1)

/*
 * An index of a point.  One that names no mark and no tag (such as
 * "2.0" or "2.0 lineend") is resolved when the point is given, and
 * becomes a private mark of the ornament (see tkText.h), so that the
 * point stays on its character; so does an index given in a wrapper
 * ({leftward index} or {rightward index}: a mark of that gravity).
 * The others (marks, tags, "end", "@x,y", embedded images and windows)
 * are kept as strings and parsed at every redisplay.
 */

#define WRAP_NONE	0
#define WRAP_LEFT	1
#define WRAP_RIGHT	2

typedef struct OrnIndex {
    char *string;		/* The index as given, or NULL. */
    TkTextSegment *markPtr;	/* Or the private mark, or NULL. */
    int wrap;			/* WRAP_*: given in a wrapper. */
    int hasX;			/* The x of its position when it was last */
    double x;			/* displayed (display line coordinates,
				 * for a stand-in: TkTextOrnCharBox). */
} OrnIndex;

typedef struct OrnPoint {
    int kind;
    int numIndices;		/* PT_AT 1; PT_RANGE, PT_LINE, PT_OUTLINE
				 * 2. */
    OrnIndex index[2];
    int anchor;			/* PT_AT, PT_RANGE, PT_LINE. */
    double fx, fy;		/* For ANCHOR_FRAC. */
    int lineNum;		/* PT_LINE: which display line (from 0 at
				 * the top, from -1 at the bottom); PT_LEAF:
				 * which leaf (from 0). */
    int numKids;		/* PT_MIX, PT_OFFSET (1), PT_XY (2), PT_MIN,
				 * PT_MAX: the points it is made of. */
    struct OrnPoint **kids;
    double *weights;		/* PT_MIX: one per kid. */
    double dx, dy;		/* PT_OFFSET: the distances, ... */
    int dxUnit, dyUnit;		/* ... in these units (unitNames). */
} OrnPoint;

/*
 * Types of ornaments.
 */

#define ORN_LINE	0
#define ORN_POLYGON	1
#define ORN_RECTANGLE	2
#define ORN_OVAL	3
#define ORN_ARC		4
#define ORN_TEXT	5

static char *typeNames[] = {"line", "polygon", "rectangle", "oval", "arc",
	"text", NULL};

/*
 * Styles of arcs (as on a canvas).
 */

#define ARC_PIESLICE	0
#define ARC_CHORD	1
#define ARC_ARC		2

#define ARROW_FIRST	1
#define ARROW_LAST	2

/*
 * The geometry of an ornament, in window coordinates, as computed for
 * one redisplay.
 */

typedef struct OrnGeom {
    int valid;			/* 0: not drawn (no position displayed, or
				 * an index that does not parse). */
    int numCoords;		/* Points of the outline (pairs). */
    double *coords;		/* After smoothing and arrows. */
    int numHeads;		/* 0, 1 or 2 arrowheads ... */
    double heads[2][8];		/* ... of 4 points each. */
    int closed;			/* The outline is closed (not for a line,
				 * nor an arc of style arc). */
    double textX, textY;	/* ORN_TEXT: where the text starts, on its
				 * baseline (coords: its box). */
    int y0, y1;			/* Vertical extent, with the line width. */
    int x0, x1;			/* Horizontal extent. */
} OrnGeom;

typedef struct Ornament {
    int id;
    int type;
    int numPoints;
    OrnPoint **points;

    /*
     * Options (filled by Tk_ConfigureWidget).
     */

    XColor *fillColor;
    XColor *outlineColor;
    int width;
    char *dashString;
    int capStyle;
    int joinStyle;
    int smooth;
    char *arrowUid;
    char *arrowShapeString;
    char *layerUid;
    char *stateUid;
    int keep;			/* Not deleted with its text. */
    double start, extent;	/* ORN_ARC: angles, in degrees. */
    char *styleString;		/* ORN_ARC: pieslice, chord or arc. */
    char *text;			/* ORN_TEXT: the text, ... */
    Tk_Font tkfont;		/* ... its font (NULL: the widget's), ... */
    Tk_Anchor textAnchor;	/* ... the anchor of its box at its point. */

    /*
     * Derived from the options.
     */

    int arrow;			/* ARROW_FIRST | ARROW_LAST. */
    int style;			/* ARC_*. */
    double arrowShape[3];
    int under;			/* Drawn under the text. */
    int hidden;
    int numDashes;
    char dashes[16];
    GC fillGC, outlineGC;	/* Created when first drawn. */
    Font gcFont;		/* The font of fillGC (ORN_TEXT). */

    /*
     * Geometry.
     */

    OrnGeom geom;		/* As last drawn (or about to be). */
    int prevValid, prevY0, prevY1;
				/* The extent before the last update (for
				 * TkTextOrnTouches). */
    int dirty;			/* Options or points changed. */
    int doomed;			/* Deleted once the deletion under way
				 * is done (TkTextOrnBeforeDelete). */
    struct Ornament *nextPtr;
} Ornament;

typedef struct TkTextOrnInfo {
    Ornament *firstPtr;
    int nextId;
    struct TkTextOrnTemplates *strokesPtr;
				/* The strokes of the split lines and frames
				 * of blocks (GetStrokes), made when first
				 * needed, or NULL. */
} TkTextOrnInfo;

#define DEF_ORN_WIDTH	"1"

static Tk_ConfigSpec lineConfigSpecs[] = {
    {TK_CONFIG_STRING, "-arrow", NULL, NULL,
	"none", Tk_Offset(Ornament, arrowUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-arrowshape", NULL, NULL,
	"8 10 3", Tk_Offset(Ornament, arrowShapeString), TK_CONFIG_NULL_OK},
    {TK_CONFIG_CAP_STYLE, "-capstyle", NULL, NULL,
	"butt", Tk_Offset(Ornament, capStyle), 0},
    {TK_CONFIG_STRING, "-dash", NULL, NULL,
	NULL, Tk_Offset(Ornament, dashString), TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-fill", NULL, NULL,
	"black", Tk_Offset(Ornament, fillColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_JOIN_STYLE, "-joinstyle", NULL, NULL,
	"round", Tk_Offset(Ornament, joinStyle), 0},
    {TK_CONFIG_BOOLEAN, "-keep", NULL, NULL,
	"0", Tk_Offset(Ornament, keep), 0},
    {TK_CONFIG_STRING, "-layer", NULL, NULL,
	"over", Tk_Offset(Ornament, layerUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-outline", NULL, NULL,
	NULL, Tk_Offset(Ornament, outlineColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-smooth", NULL, NULL,
	"0", Tk_Offset(Ornament, smooth), 0},
    {TK_CONFIG_STRING, "-state", NULL, NULL,
	"normal", Tk_Offset(Ornament, stateUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_PIXELS, "-width", NULL, NULL,
	DEF_ORN_WIDTH, Tk_Offset(Ornament, width), 0},
    {TK_CONFIG_END, NULL, NULL, NULL, NULL, 0, 0}
};

static Tk_ConfigSpec shapeConfigSpecs[] = {
    {TK_CONFIG_STRING, "-dash", NULL, NULL,
	NULL, Tk_Offset(Ornament, dashString), TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-fill", NULL, NULL,
	NULL, Tk_Offset(Ornament, fillColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-keep", NULL, NULL,
	"0", Tk_Offset(Ornament, keep), 0},
    {TK_CONFIG_STRING, "-layer", NULL, NULL,
	"over", Tk_Offset(Ornament, layerUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-outline", NULL, NULL,
	"black", Tk_Offset(Ornament, outlineColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-state", NULL, NULL,
	"normal", Tk_Offset(Ornament, stateUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_PIXELS, "-width", NULL, NULL,
	DEF_ORN_WIDTH, Tk_Offset(Ornament, width), 0},
    {TK_CONFIG_END, NULL, NULL, NULL, NULL, 0, 0}
};

static Tk_ConfigSpec arcConfigSpecs[] = {
    {TK_CONFIG_STRING, "-dash", NULL, NULL,
	NULL, Tk_Offset(Ornament, dashString), TK_CONFIG_NULL_OK},
    {TK_CONFIG_DOUBLE, "-extent", NULL, NULL,
	"90", Tk_Offset(Ornament, extent), 0},
    {TK_CONFIG_COLOR, "-fill", NULL, NULL,
	NULL, Tk_Offset(Ornament, fillColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-keep", NULL, NULL,
	"0", Tk_Offset(Ornament, keep), 0},
    {TK_CONFIG_STRING, "-layer", NULL, NULL,
	"over", Tk_Offset(Ornament, layerUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-outline", NULL, NULL,
	"black", Tk_Offset(Ornament, outlineColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_DOUBLE, "-start", NULL, NULL,
	"0", Tk_Offset(Ornament, start), 0},
    {TK_CONFIG_STRING, "-state", NULL, NULL,
	"normal", Tk_Offset(Ornament, stateUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-style", NULL, NULL,
	"pieslice", Tk_Offset(Ornament, styleString), TK_CONFIG_NULL_OK},
    {TK_CONFIG_PIXELS, "-width", NULL, NULL,
	DEF_ORN_WIDTH, Tk_Offset(Ornament, width), 0},
    {TK_CONFIG_END, NULL, NULL, NULL, NULL, 0, 0}
};

static Tk_ConfigSpec textConfigSpecs[] = {
    {TK_CONFIG_ANCHOR, "-anchor", NULL, NULL,
	"center", Tk_Offset(Ornament, textAnchor), 0},
    {TK_CONFIG_COLOR, "-fill", NULL, NULL,
	"black", Tk_Offset(Ornament, fillColor), TK_CONFIG_NULL_OK},
    {TK_CONFIG_FONT, "-font", NULL, NULL,
	NULL, Tk_Offset(Ornament, tkfont), TK_CONFIG_NULL_OK},
    {TK_CONFIG_BOOLEAN, "-keep", NULL, NULL,
	"0", Tk_Offset(Ornament, keep), 0},
    {TK_CONFIG_STRING, "-layer", NULL, NULL,
	"over", Tk_Offset(Ornament, layerUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-state", NULL, NULL,
	"normal", Tk_Offset(Ornament, stateUid), TK_CONFIG_NULL_OK},
    {TK_CONFIG_STRING, "-text", NULL, NULL,
	"", Tk_Offset(Ornament, text), TK_CONFIG_NULL_OK},
    {TK_CONFIG_END, NULL, NULL, NULL, NULL, 0, 0}
};

#define SPECS(ornPtr) \
	(((ornPtr)->type <= ORN_POLYGON) ? lineConfigSpecs \
	: ((ornPtr)->type == ORN_ARC) ? arcConfigSpecs \
	: ((ornPtr)->type == ORN_TEXT) ? textConfigSpecs : shapeConfigSpecs)

/*
 * The font of a text ornament.
 */

#define ORN_FONT(textPtr, ornPtr) \
	(((ornPtr)->tkfont != NULL) ? (ornPtr)->tkfont : (textPtr)->tkfont)

/*
 * Points of a smoothed segment, of an oval drawn as a polygon.
 */

#define SMOOTH_STEPS	12
#define OVAL_STEPS	72

/*
 * Coordinates are clipped to the area drawn into, extended by this
 * much (and by the line width), before they are given to X (whose
 * coordinates are shorts).
 */

#define CLIP_MARGIN	64

static void		FreePoint _ANSI_ARGS_((TkText *textPtr,
			    OrnPoint *ptPtr));
static OrnPoint *	ParsePoint _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, Arg arg, int flags));
struct OrnFont;
static int		EvalPoint _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, OrnPoint *ptPtr,
			    int *shownPtr, double *xPtr, double *yPtr,
			    struct OrnFont *fontPtr,
			    TkTextOrnBlockBoxes *boxesPtr));
static int		ComputeGeom _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, Ornament *ornPtr,
			    OrnGeom *geomPtr, TkTextOrnBlockBoxes *boxesPtr));
static void		FreeGeom _ANSI_ARGS_((OrnGeom *geomPtr));
static void		FreeOrnament _ANSI_ARGS_((TkText *textPtr,
			    Ornament *ornPtr));
static int		ConfigureOrnament _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, Ornament *ornPtr, int argc,
			    Arg *args, int flags));
static Ornament *	FindOrnament _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, Arg arg));
static void		RedrawOld _ANSI_ARGS_((TkText *textPtr,
			    Ornament *ornPtr));
static int		SetPoints _ANSI_ARGS_((Tcl_Interp *interp,
			    TkText *textPtr, Ornament *ornPtr, int argc,
			    Arg *args, int template));
static Arg		PrintPoint _ANSI_ARGS_((TkText *textPtr,
			    OrnPoint *ptPtr));
static TkTextOrnInfo *	GetOrnInfo _ANSI_ARGS_((TkText *textPtr));
static int		SplitsList _ANSI_ARGS_((Tcl_Interp *interp,
			    struct TkTextBlockOrns *listPtr));

/*
 *----------------------------------------------------------------------
 *
 * SplitMaybe --
 *
 *	Splits an argument that may be a list: an array reference is
 *	split as it is; a string only if it may hold several elements
 *	(it has white space), and as a copy, since splitting a string
 *	turns it into a list in place (the program's own string).
 *	*listPtr is set to the copy to free with FreeSplit, or NULL.
 *
 * Results:
 *	The number of elements (0 if it is not a list).
 *
 *----------------------------------------------------------------------
 */

typedef struct Split {
    int argc;
    Arg *args;
    LangFreeProc *freeProc;
    Arg copy;
} Split;

static int
SplitMaybe(interp, arg, splitPtr)
    Tcl_Interp *interp;
    Arg arg;
    Split *splitPtr;
{
    Arg list = NULL;
    char *s;

    splitPtr->argc = 0;
    splitPtr->args = NULL;
    splitPtr->freeProc = NULL;
    splitPtr->copy = NULL;
    if (SvROK((SV *) arg) && (SvTYPE(SvRV((SV *) arg)) == SVt_PVAV)) {
	list = arg;
    } else {
	for (s = LangString(arg); *s != '\0'; s++) {
	    if (isspace(UCHAR(*s))) {
		break;
	    }
	}
	if (*s != '\0') {
	    list = splitPtr->copy = Tcl_NewStringObj(LangString(arg), -1);
	}
    }
    if ((list != NULL) && (Lang_SplitList(interp, list, &splitPtr->argc,
	    &splitPtr->args, &splitPtr->freeProc) != TCL_OK)) {
	Tcl_ResetResult(interp);
	splitPtr->argc = 0;
    }
    return splitPtr->argc;
}

static void
FreeSplit(splitPtr)
    Split *splitPtr;
{
    if (splitPtr->freeProc) {
	(*splitPtr->freeProc)(splitPtr->argc, splitPtr->args);
    }
    if (splitPtr->copy != NULL) {
	Tcl_DecrRefCount(splitPtr->copy);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ParseAnchor --
 *
 *	An anchor: a name, or a list of two fractions {fx fy}.
 *
 *----------------------------------------------------------------------
 */

static char *anchorNames[] = {
    "nw", "n", "ne", "w", "center", "e", "sw", "s", "se", "bw", "b", "be",
    "mw", "m", "me", NULL
};

static int
ParseAnchor(interp, arg, ptPtr)
    Tcl_Interp *interp;
    Arg arg;
    OrnPoint *ptPtr;
{
    char *string = LangString(arg);
    Split split;
    int i, ok = 0;

    if (strcmp(string, "c") == 0) {
	ptPtr->anchor = ANCHOR(1, 1);
	return TCL_OK;
    }
    for (i = 0; anchorNames[i] != NULL; i++) {
	if (strcmp(string, anchorNames[i]) == 0) {
	    ptPtr->anchor = i;
	    return TCL_OK;
	}
    }
    if ((SplitMaybe(interp, arg, &split) == 2)
	    && (Tcl_GetDouble(interp, LangString(split.args[0]), &ptPtr->fx)
		    == TCL_OK)
	    && (Tcl_GetDouble(interp, LangString(split.args[1]), &ptPtr->fy)
		    == TCL_OK)) {
	ptPtr->anchor = ANCHOR_FRAC;
	ok = 1;
    }
    FreeSplit(&split);
    if (ok) {
	return TCL_OK;
    }
    Tcl_ResetResult(interp);
    Tcl_AppendResult(interp, "bad anchor \"", string,
	    "\": must be nw, n, ne, w, center, e, sw, s, se, bw, b, be, ",
	    "mw, m, me, or a list of two fractions", NULL);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * ParseIndex, EvalIndex, PrintIndex, FreeIndex --
 *
 *	An index of a point (see OrnIndex).  ParseIndex checks that it
 *	parses now; with marks set, an index that names no mark and no
 *	tag, or one in a wrapper, becomes a private mark (left gravity
 *	for the end of a range, unless a wrapper says otherwise);
 *	without (a point computed once), the index is kept as a string
 *	(a wrapped one as the index it gives now).
 *
 *----------------------------------------------------------------------
 */

static int
NamesNothing(textPtr, string)
    TkText *textPtr;
    char *string;
{
    char *p, *copy;
    Tcl_HashEntry *hPtr = NULL;

    /*
     * "tag.first" and "tag.last" come first, as in TkTextGetIndex;
     * then a base that starts with a digit or a minus sign is
     * "line.char" (never a mark).
     */

    p = strrchr(string, '.');
    if ((p != NULL) && ((strncmp(p + 1, "first", 5) == 0)
	    || (strncmp(p + 1, "last", 4) == 0))) {
	copy = ckalloc(p - string + 1);
	memcpy(copy, string, p - string);
	copy[p - string] = '\0';
	hPtr = Tcl_FindHashEntry(&textPtr->tagTable, copy);
	ckfree(copy);
	if (hPtr != NULL) {
	    return 0;
	}
    }
    return isdigit(UCHAR(string[0])) || (string[0] == '-');
}

static int
ParseIndex(interp, textPtr, arg, left, marks, ipPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    Arg arg;
    int left;			/* The default gravity of a mark. */
    int marks;			/* Make private marks. */
    OrnIndex *ipPtr;		/* Filled in. */
{
    int wrap = WRAP_NONE, code = TCL_OK;
    Split split;
    char *s = LangString(arg), buf[TK_POS_CHARS];
    TkTextIndex index;

    ipPtr->string = NULL;
    ipPtr->markPtr = NULL;
    ipPtr->wrap = WRAP_NONE;
    ipPtr->hasX = 0;
    ipPtr->x = 0;
    if ((SplitMaybe(interp, arg, &split) == 2)
	    && ((strcmp(LangString(split.args[0]), "leftward") == 0)
	    || (strcmp(LangString(split.args[0]), "rightward") == 0))) {
	wrap = (LangString(split.args[0])[0] == 'l') ? WRAP_LEFT : WRAP_RIGHT;
	left = (wrap == WRAP_LEFT);
	s = LangString(split.args[1]);
    }
    if (TkTextGetIndex(interp, textPtr, s, &index) != TCL_OK) {
	code = TCL_ERROR;
    } else if ((wrap != WRAP_NONE) || NamesNothing(textPtr, s)) {
	if (marks) {
	    ipPtr->markPtr = TkTextSetPrivateMark(textPtr, &index, left);
	} else {
	    TkTextPrintIndex(&index, buf);
	    ipPtr->string = ckalloc(strlen(buf) + 1);
	    strcpy(ipPtr->string, buf);
	}
	ipPtr->wrap = wrap;
    } else {
	ipPtr->string = ckalloc(strlen(s) + 1);
	strcpy(ipPtr->string, s);
    }
    FreeSplit(&split);
    return code;
}

static int
EvalIndex(interp, textPtr, ipPtr, indexPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    OrnIndex *ipPtr;
    TkTextIndex *indexPtr;
{
    if (ipPtr->markPtr != NULL) {
	TkTextMarkSegToIndex(textPtr, ipPtr->markPtr, indexPtr);
	return TCL_OK;
    }
    return TkTextGetIndex(interp, textPtr, ipPtr->string, indexPtr);
}

static Arg
PrintIndex(textPtr, ipPtr)
    TkText *textPtr;
    OrnIndex *ipPtr;
{
    char buf[TK_POS_CHARS];
    TkTextIndex index;
    Tcl_Obj *listPtr, *objPtr;

    if (ipPtr->markPtr != NULL) {
	TkTextMarkSegToIndex(textPtr, ipPtr->markPtr, &index);
	TkTextPrintIndex(&index, buf);
	objPtr = Tcl_NewStringObj(buf, -1);
    } else {
	objPtr = Tcl_NewStringObj(ipPtr->string, -1);
    }
    if (ipPtr->wrap == WRAP_NONE) {
	return objPtr;
    }
    listPtr = Tcl_NewListObj(0, NULL);
    Tcl_ListObjAppendElement(NULL, listPtr, Tcl_NewStringObj(
	    (ipPtr->wrap == WRAP_LEFT) ? "leftward" : "rightward", -1));
    Tcl_ListObjAppendElement(NULL, listPtr, objPtr);
    return listPtr;
}

static void
FreeIndex(textPtr, ipPtr)
    TkText *textPtr;
    OrnIndex *ipPtr;
{
    if (ipPtr->string != NULL) {
	ckfree(ipPtr->string);
	ipPtr->string = NULL;
    }
    if (ipPtr->markPtr != NULL) {
	TkTextUnsetPrivateMark(textPtr, ipPtr->markPtr);
	ipPtr->markPtr = NULL;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ParseDist, PrintDist --
 *
 *	A distance of an offset: a number with one of the units of
 *	unitNames (such as 0.5em or -1ex), or a screen distance (such as
 *	3 or 2p, kept in pixels).
 *
 *----------------------------------------------------------------------
 */

static int
ParseDist(interp, textPtr, string, valuePtr, unitPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    char *string;
    double *valuePtr;
    int *unitPtr;
{
    size_t len = strlen(string), ulen;
    int u, pixels;
    char *end;

    for (u = 8; u > 0; u--) {		/* The longest names first. */
	ulen = strlen(unitNames[u]);
	if ((len > ulen) && (strcmp(string + len - ulen, unitNames[u]) == 0)) {
	    *valuePtr = strtod(string, &end);
	    if ((end == string + len - ulen) && !isspace(UCHAR(*string))) {
		*unitPtr = u;
		return TCL_OK;
	    }
	}
    }
    if (Tk_GetPixels(interp, textPtr->tkwin, string, &pixels) != TCL_OK) {
	return TCL_ERROR;
    }
    *valuePtr = pixels;
    *unitPtr = U_PIXELS;
    return TCL_OK;
}

static Arg
PrintDist(value, unit)
    double value;
    int unit;
{
    char buf[TCL_DOUBLE_SPACE + 10];

    if (unit == U_PIXELS) {
	return Tcl_NewIntObj((int) value);
    }
    sprintf(buf, "%g%s", value, unitNames[unit]);
    return Tcl_NewStringObj(buf, -1);
}

/*
 *----------------------------------------------------------------------
 *
 * ParsePoint --
 *
 *	Parses a point specification (see the head of this file).  The
 *	indices are checked to parse now (see ParseIndex).
 *
 * Results:
 *	A new OrnPoint, or NULL with an error message in interp.
 *
 *----------------------------------------------------------------------
 */

#define PARSE_MARKS	1	/* Indices may become private marks. */
#define PARSE_OUTLINE	2	/* An outline is allowed here. */
#define PARSE_TEMPLATE	4	/* In a block type's -ornaments: leaf and
				 * block points, no indices. */

static OrnPoint *
ParsePoint(interp, textPtr, arg, flags)
    Tcl_Interp *interp;
    TkText *textPtr;
    Arg arg;
    int flags;			/* PARSE_*. */
{
    int argc, i, nKids, step, kind;
    Arg *args;
    LangFreeProc *freeProc = NULL;
    OrnPoint *ptPtr = NULL;
    char *kindName;
    int marks = flags & PARSE_MARKS;

    if (Lang_SplitList(interp, arg, &argc, &args, &freeProc) != TCL_OK) {
	return NULL;
    }
    if (argc < 1) {
	Tcl_AppendResult(interp, "empty point specification", NULL);
	goto error;
    }
    kindName = LangString(args[0]);
    for (kind = 0; kindNames[kind] != NULL; kind++) {
	if (strcmp(kindName, kindNames[kind]) == 0) {
	    break;
	}
    }
    if (kindNames[kind] == NULL) {
	Tcl_AppendResult(interp, "bad point kind \"", kindName,
		"\": must be at, range, line, outline, mix, offset, xy, ",
		"yx, min, max, leaf, or block", NULL);
	goto error;
    }
    if ((flags & PARSE_TEMPLATE) && ((kind == PT_AT) || (kind == PT_RANGE)
	    || (kind == PT_LINE) || (kind == PT_OUTLINE))) {
	Tcl_AppendResult(interp, "the point \"", kindName, "\" is not ",
		"allowed in a block type's -ornaments: no indices there",
		NULL);
	goto error;
    }
    if (!(flags & PARSE_TEMPLATE)
	    && ((kind == PT_LEAF) || (kind == PT_BLOCK))) {
	Tcl_AppendResult(interp, "the point \"", kindName, "\" is allowed ",
		"only in a block type's -ornaments", NULL);
	goto error;
    }
    ptPtr = (OrnPoint *) ckalloc(sizeof(OrnPoint));
    memset(ptPtr, 0, sizeof(OrnPoint));
    ptPtr->kind = kind;
    ptPtr->anchor = ANCHOR(0, 3);

    switch (kind) {
    case PT_LEAF:
    case PT_BLOCK: {
	int numArgs = (kind == PT_LEAF) ? 2 : 1;

	if ((argc != numArgs) && (argc != numArgs + 1)) {
	    Tcl_AppendResult(interp, "wrong # elements: should be \"",
		    kindName, (kind == PT_LEAF) ? " k" : "", " ?anchor?\"",
		    NULL);
	    goto error;
	}
	if (kind == PT_LEAF) {
	    if (Tcl_GetInt(interp, LangString(args[1]), &ptPtr->lineNum)
		    != TCL_OK) {
		goto error;
	    }
	    if (ptPtr->lineNum < 0) {
		Tcl_AppendResult(interp, "bad leaf number \"",
			LangString(args[1]), "\": must not be negative", NULL);
		goto error;
	    }
	}
	if ((argc == numArgs + 1)
		&& (ParseAnchor(interp, args[numArgs], ptPtr) != TCL_OK)) {
	    goto error;
	}
	break;
    }
    case PT_AT:
    case PT_RANGE:
    case PT_LINE:
    case PT_OUTLINE: {
	int numIndices = (kind == PT_AT) ? 1 : 2;
	int numArgs = 1 + numIndices + (kind == PT_LINE);

	if ((kind == PT_OUTLINE) && !(flags & PARSE_OUTLINE)) {
	    Tcl_AppendResult(interp, "an outline is allowed only as a ",
		    "point of a line or a polygon", NULL);
	    goto error;
	}
	if ((argc != numArgs)
		&& ((kind == PT_OUTLINE) || (argc != numArgs + 1))) {
	    Tcl_AppendResult(interp, "wrong # elements: should be \"",
		    kindName, (numIndices == 1) ? " index" : " index1 index2",
		    (kind == PT_LINE) ? " n" : "",
		    (kind == PT_OUTLINE) ? "\"" : " ?anchor?\"", NULL);
	    goto error;
	}
	for (i = 0; i < numIndices; i++) {
	    /*
	     * The end of a range has left gravity: text inserted there
	     * stays outside the range.
	     */

	    if (ParseIndex(interp, textPtr, args[1 + i], i == 1, marks,
		    &ptPtr->index[i]) != TCL_OK) {
		goto error;
	    }
	    ptPtr->numIndices++;
	}
	if ((kind == PT_LINE) && (Tcl_GetInt(interp,
		LangString(args[numArgs - 1]), &ptPtr->lineNum) != TCL_OK)) {
	    goto error;
	}
	if ((argc == numArgs + 1)
		&& (ParseAnchor(interp, args[numArgs], ptPtr) != TCL_OK)) {
	    goto error;
	}
	break;
    }
    case PT_OFFSET:
	if (argc != 4) {
	    Tcl_AppendResult(interp,
		    "wrong # elements: should be \"offset point dx dy\"", NULL);
	    goto error;
	}
	if ((ParseDist(interp, textPtr, LangString(args[2]), &ptPtr->dx,
		&ptPtr->dxUnit) != TCL_OK)
		|| (ParseDist(interp, textPtr, LangString(args[3]),
		&ptPtr->dy, &ptPtr->dyUnit) != TCL_OK)) {
	    goto error;
	}
	ptPtr->numKids = 1;
	ptPtr->kids = (OrnPoint **) ckalloc(sizeof(OrnPoint *));
	ptPtr->kids[0] = ParsePoint(interp, textPtr, args[1],
		flags & ~PARSE_OUTLINE);
	if (ptPtr->kids[0] == NULL) {
	    ptPtr->numKids = 0;
	    goto error;
	}
	break;
    default:			/* PT_MIX, PT_XY, PT_YX, PT_MIN, PT_MAX */
	if ((kind == PT_XY) || (kind == PT_YX)) {
	    if (argc != 3) {
		Tcl_AppendResult(interp, "wrong # elements: should be \"",
			kindName, " point1 point2\"", NULL);
		goto error;
	    }
	} else if (kind == PT_MIX) {
	    if ((argc < 3) || ((argc - 1) % 2)) {
		Tcl_AppendResult(interp, "wrong # elements: should be ",
			"\"mix weight point ?weight point ...?\"", NULL);
		goto error;
	    }
	} else if (argc < 2) {
	    Tcl_AppendResult(interp, "wrong # elements: should be \"",
		    kindName, " point ?point ...?\"", NULL);
	    goto error;
	}
	step = (kind == PT_MIX) ? 2 : 1;
	nKids = (argc - 1) / step;
	ptPtr->kids = (OrnPoint **) ckalloc(nKids * sizeof(OrnPoint *));
	if (kind == PT_MIX) {
	    ptPtr->weights = (double *) ckalloc(nKids * sizeof(double));
	}
	for (i = 0; i < nKids; i++) {
	    if (kind == PT_MIX) {
		if (Tcl_GetDouble(interp, LangString(args[1 + 2*i]),
			&ptPtr->weights[i]) != TCL_OK) {
		    goto error;
		}
	    }
	    ptPtr->kids[i] = ParsePoint(interp, textPtr,
		    args[1 + step*i + step - 1], flags & ~PARSE_OUTLINE);
	    if (ptPtr->kids[i] == NULL) {
		goto error;
	    }
	    ptPtr->numKids++;
	}
	if (kind == PT_MIX) {
	    double sum = 0;

	    for (i = 0; i < nKids; i++) {
		sum += ptPtr->weights[i];
	    }
	    if (sum == 0) {
		Tcl_AppendResult(interp, "the weights of mix add up to 0",
			NULL);
		goto error;
	    }
	}
	break;
    }
    if (freeProc) {
	(*freeProc)(argc, args);
    }
    return ptPtr;

    error:
    if (ptPtr != NULL) {
	FreePoint(textPtr, ptPtr);
    }
    if (freeProc) {
	(*freeProc)(argc, args);
    }
    return NULL;
}

static void
FreePoint(textPtr, ptPtr)
    TkText *textPtr;
    OrnPoint *ptPtr;
{
    int i;

    for (i = 0; i < ptPtr->numIndices; i++) {
	FreeIndex(textPtr, &ptPtr->index[i]);
    }
    for (i = 0; i < ptPtr->numKids; i++) {
	FreePoint(textPtr, ptPtr->kids[i]);
    }
    if (ptPtr->kids != NULL) {
	ckfree((char *) ptPtr->kids);
    }
    if (ptPtr->weights != NULL) {
	ckfree((char *) ptPtr->weights);
    }
    ckfree((char *) ptPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * PrintPoint --
 *
 *	The specification of a point, as a list (as it was given, with
 *	the indices of private marks as they are now, and the anchor
 *	and the numbers normalized).
 *
 *----------------------------------------------------------------------
 */

static Arg
PrintPoint(textPtr, ptPtr)
    TkText *textPtr;
    OrnPoint *ptPtr;
{
    Tcl_Obj *listPtr = Tcl_NewListObj(0, NULL), *anchorPtr;
    int i;

    Tcl_ListObjAppendElement(NULL, listPtr,
	    Tcl_NewStringObj(kindNames[ptPtr->kind], -1));
    switch (ptPtr->kind) {
    case PT_LEAF:
    case PT_BLOCK:
    case PT_AT:
    case PT_RANGE:
    case PT_LINE:
    case PT_OUTLINE:
	if (ptPtr->kind == PT_LEAF) {
	    Tcl_ListObjAppendElement(NULL, listPtr,
		    Tcl_NewIntObj(ptPtr->lineNum));
	}
	for (i = 0; i < ptPtr->numIndices; i++) {
	    Tcl_ListObjAppendElement(NULL, listPtr,
		    PrintIndex(textPtr, &ptPtr->index[i]));
	}
	if (ptPtr->kind == PT_LINE) {
	    Tcl_ListObjAppendElement(NULL, listPtr,
		    Tcl_NewIntObj(ptPtr->lineNum));
	}
	if (ptPtr->kind == PT_OUTLINE) {
	    break;
	}
	if (ptPtr->anchor == ANCHOR_FRAC) {
	    anchorPtr = Tcl_NewListObj(0, NULL);
	    Tcl_ListObjAppendElement(NULL, anchorPtr,
		    Tcl_NewDoubleObj(ptPtr->fx));
	    Tcl_ListObjAppendElement(NULL, anchorPtr,
		    Tcl_NewDoubleObj(ptPtr->fy));
	} else {
	    anchorPtr = Tcl_NewStringObj(anchorNames[ptPtr->anchor], -1);
	}
	Tcl_ListObjAppendElement(NULL, listPtr, anchorPtr);
	break;
    case PT_OFFSET:
	Tcl_ListObjAppendElement(NULL, listPtr,
		PrintPoint(textPtr, ptPtr->kids[0]));
	Tcl_ListObjAppendElement(NULL, listPtr,
		PrintDist(ptPtr->dx, ptPtr->dxUnit));
	Tcl_ListObjAppendElement(NULL, listPtr,
		PrintDist(ptPtr->dy, ptPtr->dyUnit));
	break;
    default:
	for (i = 0; i < ptPtr->numKids; i++) {
	    if (ptPtr->kind == PT_MIX) {
		Tcl_ListObjAppendElement(NULL, listPtr,
			Tcl_NewDoubleObj(ptPtr->weights[i]));
	    }
	    Tcl_ListObjAppendElement(NULL, listPtr,
		    PrintPoint(textPtr, ptPtr->kids[i]));
	}
    }
    return listPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * Buffers of points.
 *
 *----------------------------------------------------------------------
 */

typedef struct PtBuf {
    int num, size;
    double *xy;
} PtBuf;

static void
PtAdd(bufPtr, x, y)
    PtBuf *bufPtr;
    double x, y;
{
    if (bufPtr->num == bufPtr->size) {
	bufPtr->size = bufPtr->size ? 2*bufPtr->size : 16;
	bufPtr->xy = (double *) ckrealloc((char *) bufPtr->xy,
		2 * bufPtr->size * sizeof(double));
    }
    bufPtr->xy[2*bufPtr->num] = x;
    bufPtr->xy[2*bufPtr->num + 1] = y;
    bufPtr->num++;
}

/*
 *----------------------------------------------------------------------
 *
 * Fonts of points.
 *
 *	The em of a font is the width of "M", its ex (the x-height)
 *	half its ascent.  A point has the fonts of the characters it
 *	is computed from: the smallest (by em) and the largest.
 *
 *----------------------------------------------------------------------
 */

typedef struct OrnFont {
    int has;
    double emMin, exMin;	/* The font with the smallest em. */
    double emMax, exMax;	/* The font with the largest em. */
} OrnFont;

static void
FontMetrics(tkfont, emPtr, exPtr)
    Tk_Font tkfont;
    double *emPtr, *exPtr;
{
    Tk_FontMetrics fm;

    Tk_GetFontMetrics(tkfont, &fm);
    *emPtr = Tk_TextWidth(tkfont, "M", 1);
    *exPtr = fm.ascent / 2.0;
}

static void
AddFont(fontPtr, tkfont)
    OrnFont *fontPtr;
    Tk_Font tkfont;
{
    double em, ex;

    FontMetrics(tkfont, &em, &ex);
    if (!fontPtr->has || (em < fontPtr->emMin)) {
	fontPtr->emMin = em;
	fontPtr->exMin = ex;
    }
    if (!fontPtr->has || (em > fontPtr->emMax)) {
	fontPtr->emMax = em;
	fontPtr->exMax = ex;
    }
    fontPtr->has = 1;
}

/*
 * A distance in pixels, with the fonts of the point.
 */

static double
DistValue(value, unit, fontPtr)
    double value;
    int unit;
    OrnFont *fontPtr;
{
    switch (unit) {
    case 1: case 4: return value * fontPtr->emMax;	/* em, emmax */
    case 2: return value * fontPtr->emMin;
    case 3: return value * (fontPtr->emMin + fontPtr->emMax) / 2;
    case 5: case 8: return value * fontPtr->exMax;	/* ex, exmax */
    case 6: return value * fontPtr->exMin;
    case 7: return value * (fontPtr->exMin + fontPtr->exMax) / 2;
    default: return value;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * EvalPoint --
 *
 *	Computes a point, in window coordinates, and its fonts.
 *
 * Results:
 *	TCL_OK, or TCL_ERROR if an index does not parse (or the widget
 *	shows no line), with a message in interp.  *shownPtr is set to
 *	1 if a position the point uses is displayed.  Each index
 *	displayed remembers its x, for its stand-in when it is not
 *	(TkTextOrnCharBox).
 *
 *----------------------------------------------------------------------
 */

static void
AnchorOfBox(boxPtr, ptPtr, ex, xPtr, yPtr)
    TkTextOrnBox *boxPtr;
    OrnPoint *ptPtr;
    double ex;			/* The x-height, for the mid line. */
    double *xPtr, *yPtr;
{
    int anchor = ptPtr->anchor;

    if (anchor == ANCHOR_FRAC) {
	*xPtr = boxPtr->x + boxPtr->width * ptPtr->fx;
	*yPtr = boxPtr->y + boxPtr->height * ptPtr->fy;
	return;
    }
    *xPtr = boxPtr->x + boxPtr->width * ANCHOR_H(anchor) / 2.0;
    if (ANCHOR_V(anchor) == 4) {
	*yPtr = boxPtr->base - ex / 2.0;
    } else if (ANCHOR_V(anchor) == 3) {
	*yPtr = boxPtr->base;
    } else {
	*yPtr = boxPtr->y + boxPtr->height * ANCHOR_V(anchor) / 2.0;
    }
}

/*
 * The position of an index of a point, and the box of its character
 * (or its stand-in).
 */

static int
IndexBox(interp, textPtr, ipPtr, indexPtr, boxPtr, shownPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    OrnIndex *ipPtr;
    TkTextIndex *indexPtr;
    TkTextOrnBox *boxPtr;
    int *shownPtr;
{
    int code;

    if (EvalIndex(interp, textPtr, ipPtr, indexPtr) != TCL_OK) {
	return TCL_ERROR;
    }
    code = TkTextOrnCharBox(textPtr, indexPtr, &ipPtr->hasX, &ipPtr->x,
	    boxPtr);
    if (code < 0) {
	Tcl_AppendResult(interp, "nothing is displayed", NULL);
	return TCL_ERROR;
    }
    if (code > 0) {
	*shownPtr = 1;
    }
    return TCL_OK;
}

/*
 * The pieces of a range: with byLine set, one per display line it is
 * displayed on (inside a block, the leaf's), in the order of the text,
 * with one for its part above the window and one for its part below
 * (the stand-ins of its ends); else a single one.  A piece is the
 * union of the boxes of its characters, its baseline that of its
 * first, its fonts those of the characters displayed (the widget's
 * if there are none).
 */

typedef struct Piece {
    TkTextOrnBox box;
    OrnFont font;
    Tk_Font lastFont;		/* The font added last (not again). */
} Piece;

static void
AddToPiece(piecesPtr, numPtr, sizePtr, boxPtr, byLine, displayed)
    Piece **piecesPtr;
    int *numPtr, *sizePtr;
    TkTextOrnBox *boxPtr;
    int byLine;
    int displayed;		/* A displayed character (its font
				 * counts). */
{
    Piece *pcPtr = NULL;
    int i;

    if (!byLine && (*numPtr > 0)) {
	pcPtr = &(*piecesPtr)[0];
    } else if (byLine && (boxPtr->line != NULL)) {
	for (i = 0; i < *numPtr; i++) {
	    if ((*piecesPtr)[i].box.line == boxPtr->line) {
		pcPtr = &(*piecesPtr)[i];
		break;
	    }
	}
    }
    if (pcPtr == NULL) {
	if (*numPtr == *sizePtr) {
	    *sizePtr = *sizePtr ? 2 * *sizePtr : 8;
	    *piecesPtr = (Piece *) ckrealloc((char *) *piecesPtr,
		    *sizePtr * sizeof(Piece));
	}
	pcPtr = &(*piecesPtr)[(*numPtr)++];
	pcPtr->box = *boxPtr;
	pcPtr->font.has = 0;
	pcPtr->lastFont = NULL;
    } else {
	TkTextOrnUnionBox(&pcPtr->box, boxPtr);
    }
    if (displayed && (boxPtr->tkfont != pcPtr->lastFont)) {
	AddFont(&pcPtr->font, boxPtr->tkfont);
	pcPtr->lastFont = boxPtr->tkfont;
    }
}

static int
RangePieces(interp, textPtr, ptPtr, byLine, shownPtr, piecesPtr, numPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    OrnPoint *ptPtr;
    int byLine;
    int *shownPtr;
    Piece **piecesPtr;		/* Filled with an array to free. */
    int *numPtr;
{
    TkTextIndex index1, index2, first, last;
    TkTextOrnBox box, box1, box2;
    int i, code, size = 0, shown1 = 0, shown2 = 0, tail = 0;

    *piecesPtr = NULL;
    *numPtr = 0;
    if ((IndexBox(interp, textPtr, &ptPtr->index[0], &index1, &box1,
	    &shown1) != TCL_OK) || (IndexBox(interp, textPtr,
	    &ptPtr->index[1], &index2, &box2, &shown2) != TCL_OK)) {
	return TCL_ERROR;
    }
    if (TkTextIndexCmp(&index1, &index2) >= 0) {
	/*
	 * An empty range: the place of its start, with no width.
	 */

	if (shown1) {
	    *shownPtr = 1;
	}
	box1.width = 0;
	AddToPiece(piecesPtr, numPtr, &size, &box1, byLine, shown1);
    } else {
	/*
	 * The boxes of the displayed characters of the range (only the
	 * displayed part of the range is walked), with the places of
	 * the ends if parts of the range are not displayed.
	 */

	if (TkTextOrnDisplayedRange(textPtr, &first, &last) != TCL_OK) {
	    Tcl_AppendResult(interp, "nothing is displayed", NULL);
	    return TCL_ERROR;
	}
	if (TkTextIndexCmp(&index1, &first) < 0) {
	    box1.line = NULL;
	    AddToPiece(piecesPtr, numPtr, &size, &box1, byLine, 0);
	    index1 = first;
	}
	if (TkTextIndexCmp(&index2, &last) > 0) {
	    box2.width = 0;
	    box2.line = NULL;
	    tail = 1;
	    index2 = last;
	}
	while (TkTextIndexCmp(&index1, &index2) < 0) {
	    code = TkTextOrnCharBox(textPtr, &index1, NULL, NULL, &box);
	    if (code > 0) {
		*shownPtr = 1;
		AddToPiece(piecesPtr, numPtr, &size, &box, byLine, 1);
	    }
	    TkTextIndexForwChars(&index1, 1, &index1);
	}
	if (tail) {
	    AddToPiece(piecesPtr, numPtr, &size, &box2, byLine, 0);
	}
    }
    if (*numPtr == 0) {
	Tcl_AppendResult(interp, "nothing is displayed", NULL);
	return TCL_ERROR;
    }
    for (i = 0; i < *numPtr; i++) {
	if (!(*piecesPtr)[i].font.has) {
	    AddFont(&(*piecesPtr)[i].font, textPtr->tkfont);
	}
    }
    return TCL_OK;
}

/*
 * The outline of a range: the corners of the union of its pieces,
 * clockwise from the top left corner of the first.  The pieces are
 * taken as horizontal bands, from the top down: pieces whose heights
 * overlap (leaves side by side in a block) make one band (their
 * bounding box), and a band reaches down to the next one (the gaps
 * between lines are inside).
 */

static int
EvalOutline(interp, textPtr, ptPtr, shownPtr, bufPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    OrnPoint *ptPtr;
    int *shownPtr;
    PtBuf *bufPtr;		/* The corners are added to it. */
{
    Piece *pieces;
    int i, j, n, num;
    PtBuf corners;
    double *c;

    if (RangePieces(interp, textPtr, ptPtr, 1, shownPtr, &pieces, &num)
	    != TCL_OK) {
	return TCL_ERROR;
    }

    /*
     * Sort by top (insertion sort: few pieces), then merge.
     */

    for (i = 1; i < num; i++) {
	Piece tmp = pieces[i];

	for (j = i; (j > 0) && (pieces[j - 1].box.y > tmp.box.y); j--) {
	    pieces[j] = pieces[j - 1];
	}
	pieces[j] = tmp;
    }
    n = 0;
    for (i = 0; i < num; i++) {
	if ((n > 0) && (pieces[i].box.y < pieces[n - 1].box.y
		+ pieces[n - 1].box.height)) {
	    TkTextOrnUnionBox(&pieces[n - 1].box, &pieces[i].box);
	} else {
	    pieces[n++] = pieces[i];
	}
    }
    for (i = 0; i + 1 < n; i++) {
	pieces[i].box.height = pieces[i + 1].box.y - pieces[i].box.y;
    }

    /*
     * Down the right sides, up the left sides.
     */

    corners.num = corners.size = 0;
    corners.xy = NULL;
    for (i = 0; i < n; i++) {
	TkTextOrnBox *b = &pieces[i].box;

	if (i == 0) {
	    PtAdd(&corners, b->x, b->y);
	}
	PtAdd(&corners, b->x + b->width, b->y);
	PtAdd(&corners, b->x + b->width, b->y + b->height);
    }
    for (i = n - 1; i >= 0; i--) {
	TkTextOrnBox *b = &pieces[i].box;

	PtAdd(&corners, b->x, b->y + b->height);
	if (i > 0) {
	    PtAdd(&corners, b->x, b->y);
	}
    }
    ckfree((char *) pieces);

    /*
     * Without repeated points, nor points in the middle of a side.
     */

    c = corners.xy;
    num = corners.num;
    for (i = 0; (num > 1) && (i < num); ) {
	int k = (i + 1) % num, h = (i + num - 1) % num;

	if (((c[2*i] == c[2*k]) && (c[2*i + 1] == c[2*k + 1]))
		|| ((num > 2) && (((c[2*h] == c[2*i]) && (c[2*i] == c[2*k]))
		|| ((c[2*h + 1] == c[2*i + 1])
		    && (c[2*i + 1] == c[2*k + 1]))))) {
	    for (j = i; j + 1 < num; j++) {
		c[2*j] = c[2*j + 2];
		c[2*j + 1] = c[2*j + 3];
	    }
	    num--;
	    if (i > 0) {
		i--;
	    }
	} else {
	    i++;
	}
    }
    for (i = 0; i < num; i++) {
	PtAdd(bufPtr, c[2*i], c[2*i + 1]);
    }
    if (c != NULL) {
	ckfree((char *) c);
    }
    return TCL_OK;
}

static int
EvalPoint(interp, textPtr, ptPtr, shownPtr, xPtr, yPtr, fontPtr, boxesPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    OrnPoint *ptPtr;
    int *shownPtr;
    double *xPtr, *yPtr;
    OrnFont *fontPtr;		/* Filled with the fonts of the point. */
    TkTextOrnBlockBoxes *boxesPtr;
				/* For a block type's ornament: the boxes of
				 * the block and its leaves (block
				 * coordinates); else NULL. */
{
    TkTextIndex index1;
    TkTextOrnBox box;
    Piece *pieces;
    double x, y, sumW;
    int i, num;
    OrnFont font;

    fontPtr->has = 0;
    switch (ptPtr->kind) {
    case PT_LEAF:
    case PT_BLOCK: {
	TkTextOrnBox *bPtr;

	if (boxesPtr == NULL) {
	    Tcl_AppendResult(interp, "the point \"", kindNames[ptPtr->kind],
		    "\" is allowed only in a block type's -ornaments", NULL);
	    return TCL_ERROR;
	}
	if (ptPtr->kind == PT_BLOCK) {
	    bPtr = &boxesPtr->block;
	} else if ((ptPtr->lineNum >= boxesPtr->numLeaves)
		|| !boxesPtr->shown[ptPtr->lineNum]) {
	    /*
	     * No such leaf, or it is not shown: the ornament is not
	     * drawn for this block.
	     */

	    Tcl_AppendResult(interp, "no leaf shown", NULL);
	    return TCL_ERROR;
	} else {
	    bPtr = &boxesPtr->leaves[ptPtr->lineNum];
	}
	*shownPtr = 1;
	AddFont(fontPtr, bPtr->tkfont);
	AnchorOfBox(bPtr, ptPtr, fontPtr->exMax, xPtr, yPtr);
	return TCL_OK;
    }
    case PT_AT:
	if (IndexBox(interp, textPtr, &ptPtr->index[0], &index1, &box,
		shownPtr) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (ptPtr->index[0].wrap == WRAP_LEFT) {
	    /*
	     * The font of the character before the position (that of a
	     * stand-in, the widget's, if it is not displayed).
	     */

	    TkTextIndex prev;
	    TkTextOrnBox pbox;

	    TkTextIndexBackChars(&index1, 1, &prev);
	    if ((TkTextIndexCmp(&prev, &index1) < 0)
		    && (TkTextOrnCharBox(textPtr, &prev, NULL, NULL, &pbox)
			> 0)) {
		AddFont(fontPtr, pbox.tkfont);
	    } else {
		AddFont(fontPtr, textPtr->tkfont);
	    }
	} else {
	    AddFont(fontPtr, box.tkfont);
	}
	AnchorOfBox(&box, ptPtr, fontPtr->exMax, xPtr, yPtr);
	return TCL_OK;

    case PT_RANGE:
    case PT_LINE:
	if (RangePieces(interp, textPtr, ptPtr, ptPtr->kind == PT_LINE,
		shownPtr, &pieces, &num) != TCL_OK) {
	    return TCL_ERROR;
	}

	/*
	 * A line number out of range is the nearest piece.
	 */

	i = ptPtr->lineNum;
	if (i < 0) {
	    i += num;
	}
	if (i < 0) {
	    i = 0;
	} else if (i >= num) {
	    i = num - 1;
	}
	*fontPtr = pieces[i].font;
	AnchorOfBox(&pieces[i].box, ptPtr, fontPtr->exMax, xPtr, yPtr);
	ckfree((char *) pieces);
	return TCL_OK;

    case PT_OUTLINE:
	Tcl_AppendResult(interp, "an outline is allowed only as a ",
		"point of a line or a polygon", NULL);
	return TCL_ERROR;

    case PT_OFFSET:
	if (EvalPoint(interp, textPtr, ptPtr->kids[0], shownPtr,
		xPtr, yPtr, fontPtr, boxesPtr) != TCL_OK) {
	    return TCL_ERROR;
	}
	*xPtr += DistValue(ptPtr->dx, ptPtr->dxUnit, fontPtr);
	*yPtr += DistValue(ptPtr->dy, ptPtr->dyUnit, fontPtr);
	return TCL_OK;

    case PT_XY:
    case PT_YX:
	if ((EvalPoint(interp, textPtr, ptPtr->kids[0], shownPtr,
		&x, &y, fontPtr, boxesPtr) != TCL_OK)
		|| (EvalPoint(interp, textPtr, ptPtr->kids[1], shownPtr,
		xPtr, yPtr, &font, boxesPtr) != TCL_OK)) {
	    return TCL_ERROR;
	}
	if (ptPtr->kind == PT_XY) {
	    *xPtr = x;		/* The x of the first, the y of the second. */
	} else {
	    *yPtr = y;		/* The y of the first, the x of the second. */
	}
	return TCL_OK;

    default:			/* PT_MIX, PT_MIN, PT_MAX */
	sumW = 0;
	for (i = 0; i < ptPtr->numKids; i++) {
	    if (EvalPoint(interp, textPtr, ptPtr->kids[i], shownPtr,
		    &x, &y, (i == 0) ? fontPtr : &font, boxesPtr) != TCL_OK) {
		return TCL_ERROR;
	    }
	    if (ptPtr->kind == PT_MIX) {
		if (i == 0) {
		    *xPtr = *yPtr = 0;
		}
		*xPtr += ptPtr->weights[i] * x;
		*yPtr += ptPtr->weights[i] * y;
		sumW += ptPtr->weights[i];
	    } else if (i == 0) {
		*xPtr = x;
		*yPtr = y;
	    } else if (ptPtr->kind == PT_MIN) {
		if (x < *xPtr) *xPtr = x;
		if (y < *yPtr) *yPtr = y;
	    } else {
		if (x > *xPtr) *xPtr = x;
		if (y > *yPtr) *yPtr = y;
	    }
	}
	if (ptPtr->kind == PT_MIX) {
	    *xPtr /= sumW;
	    *yPtr /= sumW;
	}
	return TCL_OK;
    }
}

/*
 * The points of an ornament, an outline giving all its corners.
 */

static int
EvalPoints(interp, textPtr, ornPtr, shownPtr, bufPtr, boxesPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    Ornament *ornPtr;
    int *shownPtr;
    PtBuf *bufPtr;		/* Filled (free its xy). */
    TkTextOrnBlockBoxes *boxesPtr;
				/* For a block type's ornament (EvalPoint),
				 * else NULL. */
{
    int i;
    double x, y;
    OrnFont font;

    bufPtr->num = bufPtr->size = 0;
    bufPtr->xy = NULL;
    for (i = 0; i < ornPtr->numPoints; i++) {
	if (ornPtr->points[i]->kind == PT_OUTLINE) {
	    if (EvalOutline(interp, textPtr, ornPtr->points[i], shownPtr,
		    bufPtr) != TCL_OK) {
		return TCL_ERROR;
	    }
	} else if (EvalPoint(interp, textPtr, ornPtr->points[i], shownPtr,
		&x, &y, &font, boxesPtr) != TCL_OK) {
	    return TCL_ERROR;
	} else {
	    PtAdd(bufPtr, x, y);
	}
    }
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * Smoothing, arrows, ovals: the outline of an ornament.
 *
 *----------------------------------------------------------------------
 */

/*
 * Smoothing as Tk's canvas does it (quadratic Bezier splines through
 * the midpoints of the segments, the points being the control points;
 * an open line starts and ends at its end points).
 */

static void
Smooth(in, n, closed, bufPtr)
    double *in;
    int n, closed;
    PtBuf *bufPtr;
{
    int i, k, segs;
    double ax, ay, bx, by, cx, cy, t;

    segs = closed ? n : n - 2;
    for (i = 0; i < segs; i++) {
	int i0 = i % n, i1 = (i + 1) % n, i2 = (i + 2) % n;

	ax = (in[2*i0] + in[2*i1]) / 2;
	ay = (in[2*i0 + 1] + in[2*i1 + 1]) / 2;
	bx = in[2*i1];
	by = in[2*i1 + 1];
	cx = (in[2*i1] + in[2*i2]) / 2;
	cy = (in[2*i1 + 1] + in[2*i2 + 1]) / 2;
	if (!closed && (i == 0)) {
	    ax = in[0];
	    ay = in[1];
	}
	if (!closed && (i == segs - 1)) {
	    cx = in[2*i2];
	    cy = in[2*i2 + 1];
	}
	for (k = (i == 0) ? 0 : 1; k <= SMOOTH_STEPS; k++) {
	    t = (double) k / SMOOTH_STEPS;
	    PtAdd(bufPtr, (1-t)*(1-t)*ax + 2*t*(1-t)*bx + t*t*cx,
		    (1-t)*(1-t)*ay + 2*t*(1-t)*by + t*t*cy);
	}
    }
}

/*
 * An arrowhead at the end (px, py) of a segment coming from (qx, qy),
 * with the shape {a b c} of Tk's canvas: a from the tip to the neck along
 * the line, b from the tip to the trailing points, c the distance of the
 * trailing points from the line.  The end point moves back to the neck.
 */

static void
ArrowHead(shape, width, px, py, qx, qy, head)
    double *shape;
    int width;
    double *px, *py;
    double qx, qy;
    double *head;
{
    double dx = *px - qx, dy = *py - qy, len = sqrt(dx*dx + dy*dy);
    double a = shape[0], b = shape[1], c = shape[2] + width / 2.0;
    double ux, uy, backB, sideB;

    if (len == 0) {
	ux = 1;
	uy = 0;
    } else {
	ux = dx / len;
	uy = dy / len;
    }
    backB = (b > c) ? sqrt(b*b - c*c) : 0;
    sideB = c;
    head[0] = *px;
    head[1] = *py;
    head[2] = *px - ux*backB - uy*sideB;
    head[3] = *py - uy*backB + ux*sideB;
    head[4] = *px - ux*a;
    head[5] = *py - uy*a;
    head[6] = *px - ux*backB + uy*sideB;
    head[7] = *py - uy*backB - ux*sideB;
    *px = *px - ux*a;
    *py = *py - uy*a;
}

static void
FreeGeom(geomPtr)
    OrnGeom *geomPtr;
{
    if (geomPtr->coords != NULL) {
	ckfree((char *) geomPtr->coords);
	geomPtr->coords = NULL;
    }
    geomPtr->numCoords = 0;
    geomPtr->numHeads = 0;
    geomPtr->valid = 0;
}

/*
 *----------------------------------------------------------------------
 *
 * ComputeGeom --
 *
 *	Computes where an ornament is drawn now.
 *
 * Results:
 *	TCL_OK, with geomPtr filled (valid 0 if the ornament is not
 *	drawn: none of its positions is displayed); TCL_ERROR with a
 *	message in interp if a point cannot be computed (geomPtr not
 *	valid).
 *
 *----------------------------------------------------------------------
 */

static void		ShapeGeom _ANSI_ARGS_((TkText *textPtr,
			    Ornament *ornPtr, double *pts, int n,
			    OrnGeom *geomPtr));

static int
ComputeGeom(interp, textPtr, ornPtr, geomPtr, boxesPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    Ornament *ornPtr;
    OrnGeom *geomPtr;
    TkTextOrnBlockBoxes *boxesPtr;
				/* For a block type's ornament (EvalPoint),
				 * else NULL. */
{
    int shown = 0;
    PtBuf given;

    memset(geomPtr, 0, sizeof(OrnGeom));

    /*
     * If none of the positions is displayed, the ornament is not
     * drawn.
     */

    if (EvalPoints(interp, textPtr, ornPtr, &shown, &given, boxesPtr)
	    != TCL_OK) {
	if (given.xy != NULL) {
	    ckfree((char *) given.xy);
	}
	return TCL_ERROR;
    }
    if (!shown || (given.num < 1)) {
	if (given.xy != NULL) {
	    ckfree((char *) given.xy);
	}
	return TCL_OK;
    }
    ShapeGeom(textPtr, ornPtr, given.xy, given.num, geomPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * ShapeGeom --
 *
 *	The outline of an ornament from its points (n pairs in pts, freed
 *	here): smoothing, arrowheads, the corners of a rectangle, the
 *	points of an oval or an arc, the box of a text; and its extent.
 *
 *----------------------------------------------------------------------
 */

static void
ShapeGeom(textPtr, ornPtr, pts, n, geomPtr)
    TkText *textPtr;
    Ornament *ornPtr;
    double *pts;
    int n;
    OrnGeom *geomPtr;
{
    int i;
    PtBuf buf;
    double x0, y0, x1, y1, ext;

    buf.num = buf.size = 0;
    buf.xy = NULL;
    switch (ornPtr->type) {
    case ORN_LINE:
	if (ornPtr->smooth && (n > 2)) {
	    Smooth(pts, n, 0, &buf);
	} else {
	    for (i = 0; i < n; i++) {
		PtAdd(&buf, pts[2*i], pts[2*i + 1]);
	    }
	}
	if ((ornPtr->arrow & ARROW_FIRST) && (buf.num >= 2)) {
	    ArrowHead(ornPtr->arrowShape, ornPtr->width, &buf.xy[0],
		    &buf.xy[1], buf.xy[2], buf.xy[3],
		    geomPtr->heads[geomPtr->numHeads++]);
	}
	if ((ornPtr->arrow & ARROW_LAST) && (buf.num >= 2)) {
	    int k = buf.num - 1;

	    ArrowHead(ornPtr->arrowShape, ornPtr->width, &buf.xy[2*k],
		    &buf.xy[2*k + 1], buf.xy[2*k - 2], buf.xy[2*k - 1],
		    geomPtr->heads[geomPtr->numHeads++]);
	}
	break;
    case ORN_POLYGON:
	if (ornPtr->smooth && (n > 2)) {
	    Smooth(pts, n, 1, &buf);
	} else {
	    for (i = 0; i < n; i++) {
		PtAdd(&buf, pts[2*i], pts[2*i + 1]);
	    }
	}
	break;
    case ORN_RECTANGLE:
    case ORN_OVAL:
	x0 = (pts[0] < pts[2]) ? pts[0] : pts[2];
	x1 = (pts[0] < pts[2]) ? pts[2] : pts[0];
	y0 = (pts[1] < pts[3]) ? pts[1] : pts[3];
	y1 = (pts[1] < pts[3]) ? pts[3] : pts[1];
	if (ornPtr->type == ORN_RECTANGLE) {
	    PtAdd(&buf, x0, y0);
	    PtAdd(&buf, x1, y0);
	    PtAdd(&buf, x1, y1);
	    PtAdd(&buf, x0, y1);
	} else {
	    for (i = 0; i < OVAL_STEPS; i++) {
		double t = 2 * M_PI * i / OVAL_STEPS;

		PtAdd(&buf, (x0 + x1)/2 + (x1 - x0)/2 * cos(t),
			(y0 + y1)/2 - (y1 - y0)/2 * sin(t));
	    }
	}
	break;
    case ORN_ARC: {
	/*
	 * As a canvas arc: angles in degrees, counterclockwise from
	 * the right, on the oval in the box; sampled as an oval is.
	 */

	double extent = ornPtr->extent, a0 = ornPtr->start * M_PI / 180;
	int k, steps;

	if (extent > 360) {
	    extent = 360;
	} else if (extent < -360) {
	    extent = -360;
	}
	steps = (int) ceil(fabs(extent) * OVAL_STEPS / 360);
	if (steps < 1) {
	    steps = 1;
	}
	x0 = (pts[0] < pts[2]) ? pts[0] : pts[2];
	x1 = (pts[0] < pts[2]) ? pts[2] : pts[0];
	y0 = (pts[1] < pts[3]) ? pts[1] : pts[3];
	y1 = (pts[1] < pts[3]) ? pts[3] : pts[1];
	if (ornPtr->style == ARC_PIESLICE) {
	    PtAdd(&buf, (x0 + x1)/2, (y0 + y1)/2);
	}
	for (k = 0; k <= steps; k++) {
	    double t = a0 + extent * M_PI / 180 * k / steps;

	    PtAdd(&buf, (x0 + x1)/2 + (x1 - x0)/2 * cos(t),
		    (y0 + y1)/2 - (y1 - y0)/2 * sin(t));
	}
	break;
    }
    case ORN_TEXT: {
	/*
	 * The box of the text, placed by its anchor at the point.
	 */

	Tk_Font tkfont = ORN_FONT(textPtr, ornPtr);
	Tk_FontMetrics fm;
	char *text = (ornPtr->text != NULL) ? ornPtr->text : "";
	double w, h;

	Tk_GetFontMetrics(tkfont, &fm);
	w = Tk_TextWidth(tkfont, text, (int) strlen(text));
	h = fm.ascent + fm.descent;
	x0 = pts[0];
	y0 = pts[1];
	switch (ornPtr->textAnchor) {
	case TK_ANCHOR_NW: case TK_ANCHOR_W: case TK_ANCHOR_SW:
	    break;
	case TK_ANCHOR_N: case TK_ANCHOR_CENTER: case TK_ANCHOR_S:
	    x0 -= w / 2;
	    break;
	default:
	    x0 -= w;
	    break;
	}
	switch (ornPtr->textAnchor) {
	case TK_ANCHOR_NW: case TK_ANCHOR_N: case TK_ANCHOR_NE:
	    break;
	case TK_ANCHOR_W: case TK_ANCHOR_CENTER: case TK_ANCHOR_E:
	    y0 -= h / 2;
	    break;
	default:
	    y0 -= h;
	    break;
	}
	geomPtr->textX = floor(x0 + 0.5);
	geomPtr->textY = floor(y0 + 0.5) + fm.ascent;
	PtAdd(&buf, geomPtr->textX, geomPtr->textY - fm.ascent);
	PtAdd(&buf, geomPtr->textX + w, geomPtr->textY - fm.ascent);
	PtAdd(&buf, geomPtr->textX + w, geomPtr->textY + fm.descent);
	PtAdd(&buf, geomPtr->textX, geomPtr->textY + fm.descent);
	break;
    }
    }
    ckfree((char *) pts);

    geomPtr->valid = 1;
    geomPtr->closed = (ornPtr->type != ORN_LINE)
	    && !((ornPtr->type == ORN_ARC) && (ornPtr->style == ARC_ARC));
    geomPtr->numCoords = buf.num;
    geomPtr->coords = buf.xy;

    /*
     * The extent: the points, the arrowheads, half the line width
     * (more for mitred joins).
     */

    x0 = y0 = 1e30;
    x1 = y1 = -1e30;
    for (i = 0; i < buf.num; i++) {
	if (buf.xy[2*i] < x0) x0 = buf.xy[2*i];
	if (buf.xy[2*i] > x1) x1 = buf.xy[2*i];
	if (buf.xy[2*i + 1] < y0) y0 = buf.xy[2*i + 1];
	if (buf.xy[2*i + 1] > y1) y1 = buf.xy[2*i + 1];
    }
    for (i = 0; i < 4*geomPtr->numHeads; i++) {
	double hx = geomPtr->heads[i/4][2*(i%4)];
	double hy = geomPtr->heads[i/4][2*(i%4) + 1];

	if (hx < x0) x0 = hx;
	if (hx > x1) x1 = hx;
	if (hy < y0) y0 = hy;
	if (hy > y1) y1 = hy;
    }
    ext = ornPtr->width / 2.0 + 2;
    if (ornPtr->type == ORN_TEXT) {
	ext = 2;
    } else if (ornPtr->joinStyle == JoinMiter) {
	ext = 5.0 * ornPtr->width + 2;
    }
    if (ornPtr->capStyle == CapProjecting) {
	ext += ornPtr->width;
    }
#define CLAMP(v) ((v) < -1e9 ? -1e9 : ((v) > 1e9 ? 1e9 : (v)))
    geomPtr->x0 = (int) floor(CLAMP(x0 - ext));
    geomPtr->x1 = (int) ceil(CLAMP(x1 + ext));
    geomPtr->y0 = (int) floor(CLAMP(y0 - ext));
    geomPtr->y1 = (int) ceil(CLAMP(y1 + ext));
}

static int
SameGeom(g1, g2)
    OrnGeom *g1, *g2;
{
    int i;

    if (g1->valid != g2->valid) {
	return 0;
    }
    if (!g1->valid) {
	return 1;
    }
    if ((g1->numCoords != g2->numCoords) || (g1->numHeads != g2->numHeads)) {
	return 0;
    }
    for (i = 0; i < 2*g1->numCoords; i++) {
	if (g1->coords[i] != g2->coords[i]) {
	    return 0;
	}
    }
    for (i = 0; i < g1->numHeads; i++) {
	if (memcmp(g1->heads[i], g2->heads[i], 8*sizeof(double))) {
	    return 0;
	}
    }
    return 1;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnUpdate --
 *
 *	Called by DisplayText once the display lines are laid out:
 *	computes where every ornament is drawn now and, for each one
 *	that moved or changed, tells (*invalProc) the vertical ranges
 *	of the window where it was and where it is (the display lines
 *	there must be redrawn).
 *
 *----------------------------------------------------------------------
 */

void
TkTextOrnUpdate(textPtr, invalProc)
    TkText *textPtr;
    void (*invalProc) _ANSI_ARGS_((TkText *textPtr, int y0, int y1));
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr;
    OrnGeom geom;

    if (infoPtr == NULL) {
	return;
    }
    for (ornPtr = infoPtr->firstPtr; ornPtr != NULL;
	    ornPtr = ornPtr->nextPtr) {
	if (ComputeGeom(textPtr->interp, textPtr, ornPtr, &geom, NULL)
		!= TCL_OK) {
	    /*
	     * An index that does not parse any more (a mark deleted):
	     * the ornament is not drawn.
	     */

	    Tcl_ResetResult(textPtr->interp);
	    memset(&geom, 0, sizeof(geom));
	}
	if (ornPtr->hidden) {
	    FreeGeom(&geom);
	}
	ornPtr->prevValid = ornPtr->geom.valid;
	ornPtr->prevY0 = ornPtr->geom.y0;
	ornPtr->prevY1 = ornPtr->geom.y1;
	if (ornPtr->dirty || !SameGeom(&ornPtr->geom, &geom)) {
	    if (ornPtr->geom.valid) {
		(*invalProc)(textPtr, ornPtr->geom.y0, ornPtr->geom.y1);
	    }
	    if (geom.valid) {
		(*invalProc)(textPtr, geom.y0, geom.y1);
	    }
	}
	FreeGeom(&ornPtr->geom);
	ornPtr->geom = geom;
	ornPtr->dirty = 0;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnTouches --
 *
 *	Whether an ornament is drawn, or was drawn before the last
 *	update, in the vertical range [y0, y1) of the window (a display
 *	line there cannot be moved by copying its pixels).
 *
 *----------------------------------------------------------------------
 */

int
TkTextOrnTouches(textPtr, y0, y1)
    TkText *textPtr;
    int y0, y1;
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr;

    if (infoPtr == NULL) {
	return 0;
    }
    for (ornPtr = infoPtr->firstPtr; ornPtr != NULL;
	    ornPtr = ornPtr->nextPtr) {
	if (ornPtr->geom.valid && (ornPtr->geom.y0 < y1)
		&& (ornPtr->geom.y1 > y0)) {
	    return 1;
	}
	if (ornPtr->prevValid && (ornPtr->prevY0 < y1)
		&& (ornPtr->prevY1 > y0)) {
	    return 1;
	}
    }
    return 0;
}

/*
 *----------------------------------------------------------------------
 *
 * Drawing.
 *
 *	Coordinates are clipped to the area drawn into (extended by a
 *	margin) before they become X's short integers: a position far
 *	above the window has a stand-in place far above it.
 *
 *----------------------------------------------------------------------
 */

typedef struct ClipRect {
    double x0, y0, x1, y1;
} ClipRect;

/*
 * Sutherland-Hodgman, one edge at a time.  edge: 0 left, 1 right,
 * 2 top, 3 bottom.
 */

static int
Inside(x, y, edge, r)
    double x, y;
    int edge;
    ClipRect *r;
{
    switch (edge) {
    case 0: return x >= r->x0;
    case 1: return x <= r->x1;
    case 2: return y >= r->y0;
    default: return y <= r->y1;
    }
}

static void
Cross(ax, ay, bx, by, edge, r, xPtr, yPtr)
    double ax, ay, bx, by;
    int edge;
    ClipRect *r;
    double *xPtr, *yPtr;
{
    double t;

    switch (edge) {
    case 0: t = (r->x0 - ax) / (bx - ax); break;
    case 1: t = (r->x1 - ax) / (bx - ax); break;
    case 2: t = (r->y0 - ay) / (by - ay); break;
    default: t = (r->y1 - ay) / (by - ay); break;
    }
    *xPtr = ax + t * (bx - ax);
    *yPtr = ay + t * (by - ay);
    if (edge < 2) {
	*xPtr = (edge == 0) ? r->x0 : r->x1;
    } else {
	*yPtr = (edge == 2) ? r->y0 : r->y1;
    }
}

static void
ClipPolygon(in, n, r, outPtr)
    double *in;
    int n;
    ClipRect *r;
    PtBuf *outPtr;
{
    PtBuf a, b;
    int edge, i;

    a.num = a.size = 0;
    a.xy = NULL;
    for (i = 0; i < n; i++) {
	PtAdd(&a, in[2*i], in[2*i + 1]);
    }
    for (edge = 0; edge < 4; edge++) {
	b.num = b.size = 0;
	b.xy = NULL;
	for (i = 0; i < a.num; i++) {
	    double cx = a.xy[2*i], cy = a.xy[2*i + 1];
	    int j = (i + a.num - 1) % a.num;
	    double px = a.xy[2*j], py = a.xy[2*j + 1], x, y;
	    int cin = Inside(cx, cy, edge, r), pin = Inside(px, py, edge, r);

	    if (cin) {
		if (!pin) {
		    Cross(px, py, cx, cy, edge, r, &x, &y);
		    PtAdd(&b, x, y);
		}
		PtAdd(&b, cx, cy);
	    } else if (pin) {
		Cross(px, py, cx, cy, edge, r, &x, &y);
		PtAdd(&b, x, y);
	    }
	}
	if (a.xy != NULL) {
	    ckfree((char *) a.xy);
	}
	a = b;
	if (a.num == 0) {
	    break;
	}
    }
    *outPtr = a;
}

/*
 * Liang-Barsky: clips the segment to r; returns 0 if nothing is left.
 */

static int
ClipSegment(x0, y0, x1, y1, r)
    double *x0, *y0, *x1, *y1;
    ClipRect *r;
{
    double t0 = 0, t1 = 1, dx = *x1 - *x0, dy = *y1 - *y0;
    double p[4], q[4];
    int i;

    p[0] = -dx; q[0] = *x0 - r->x0;
    p[1] = dx;  q[1] = r->x1 - *x0;
    p[2] = -dy; q[2] = *y0 - r->y0;
    p[3] = dy;  q[3] = r->y1 - *y0;
    for (i = 0; i < 4; i++) {
	if (p[i] == 0) {
	    if (q[i] < 0) {
		return 0;
	    }
	} else {
	    double t = q[i] / p[i];

	    if (p[i] < 0) {
		if (t > t1) return 0;
		if (t > t0) t0 = t;
	    } else {
		if (t < t0) return 0;
		if (t < t1) t1 = t;
	    }
	}
    }
    *x1 = *x0 + t1 * dx;
    *y1 = *y0 + t1 * dy;
    *x0 = *x0 + t0 * dx;
    *y0 = *y0 + t0 * dy;
    return 1;
}

/*
 * Coordinates are rounded to the nearest pixel, halves up.  The points
 * of a smoothed line that is straight (all its y equal) differ from
 * that y by an ulp or so: without the epsilon, a y on a half pixel
 * went to one row or the next from point to point, and a straight
 * stretch of a smoothed line got steps.
 */

#define ROUND_EPS	1e-6

static XPoint *
ToXPoints(xy, n, dx, dy, bufPtr, sizePtr)
    double *xy;
    int n;
    double dx, dy;		/* Added to the coordinates. */
    XPoint *bufPtr;
    int *sizePtr;
{
    int i;

    if (n > *sizePtr) {
	*sizePtr = n;
	bufPtr = (XPoint *) ckrealloc((char *) bufPtr, n * sizeof(XPoint));
    }
    for (i = 0; i < n; i++) {
	bufPtr[i].x = (short) floor(xy[2*i] + dx + 0.5 + ROUND_EPS);
	bufPtr[i].y = (short) floor(xy[2*i + 1] + dy + 0.5 + ROUND_EPS);
    }
    return bufPtr;
}

static void
FillPolygon(display, d, gc, xy, n, r, dx, dy)
    Display *display;
    Drawable d;
    GC gc;
    double *xy;
    int n;
    ClipRect *r;
    double dx, dy;		/* From the ornament's coordinates to the
				 * drawable's. */
{
    PtBuf clipped;
    XPoint *xp = NULL;
    int size = 0;

    ClipPolygon(xy, n, r, &clipped);
    if (clipped.num >= 3) {
	xp = ToXPoints(clipped.xy, clipped.num, dx, dy, xp, &size);
	XFillPolygon(display, d, gc, xp, clipped.num, Complex,
		CoordModeOrigin);
    }
    if (clipped.xy != NULL) {
	ckfree((char *) clipped.xy);
    }
    if (xp != NULL) {
	ckfree((char *) xp);
    }
}

/*
 * A polyline (closed: back to its first point), in runs of segments
 * that are inside r after clipping.
 */

static void
DrawPolyline(display, d, gc, xy, n, closed, r, dx, dy)
    Display *display;
    Drawable d;
    GC gc;
    double *xy;
    int n, closed;
    ClipRect *r;
    double dx, dy;		/* As for FillPolygon. */
{
    PtBuf run;
    XPoint *xp = NULL;
    int size = 0, i, segs = closed ? n : n - 1;

    run.num = run.size = 0;
    run.xy = NULL;
    for (i = 0; i < segs; i++) {
	double x0 = xy[2*i], y0 = xy[2*i + 1];
	double x1 = xy[2*((i + 1) % n)], y1 = xy[2*((i + 1) % n) + 1];
	double cx0 = x0, cy0 = y0, cx1 = x1, cy1 = y1;
	int in = ClipSegment(&cx0, &cy0, &cx1, &cy1, r);

	if (in && (run.num == 0)) {
	    PtAdd(&run, cx0, cy0);
	}
	if (in) {
	    PtAdd(&run, cx1, cy1);
	}
	if ((!in || (cx1 != x1) || (cy1 != y1) || (i == segs - 1))
		&& (run.num >= 2)) {
	    xp = ToXPoints(run.xy, run.num, dx, dy, xp, &size);
	    XDrawLines(display, d, gc, xp, run.num, CoordModeOrigin);
	    run.num = 0;
	} else if (!in || (cx1 != x1) || (cy1 != y1)) {
	    run.num = 0;
	}
    }
    if (run.xy != NULL) {
	ckfree((char *) run.xy);
    }
    if (xp != NULL) {
	ckfree((char *) xp);
    }
}

static GC
MakeGC(textPtr, ornPtr, colorPtr, line)
    TkText *textPtr;
    Ornament *ornPtr;
    XColor *colorPtr;
    int line;
{
    XGCValues values;
    unsigned long mask = GCForeground;
    GC gc;

    values.foreground = colorPtr->pixel;
    if (line) {
	values.line_width = ornPtr->width;
	values.cap_style = ornPtr->capStyle;
	values.join_style = ornPtr->joinStyle;
	values.line_style = (ornPtr->numDashes > 0) ? LineOnOffDash
		: LineSolid;
	mask |= GCLineWidth | GCCapStyle | GCJoinStyle | GCLineStyle;
    }
    Tk_MakeWindowExist(textPtr->tkwin);
    gc = XCreateGC(Tk_Display(textPtr->tkwin), Tk_WindowId(textPtr->tkwin),
	    mask, &values);
    if (line && (ornPtr->numDashes > 0)) {
	XSetDashes(Tk_Display(textPtr->tkwin), gc, 0, ornPtr->dashes,
		ornPtr->numDashes);
    }
    return gc;
}

/*
 *----------------------------------------------------------------------
 *
 * DrawOrnament --
 *
 *	Draws an ornament whose outline is geomPtr into a drawable,
 *	(dx, dy) being added to the coordinates of the outline; only
 *	the part inside r (in the coordinates of the outline) is given
 *	to X.
 *
 *----------------------------------------------------------------------
 */

static void
DrawOrnament(textPtr, d, ornPtr, g, r, dx, dy)
    TkText *textPtr;
    Drawable d;
    Ornament *ornPtr;
    OrnGeom *g;
    ClipRect *r;
    double dx, dy;
{
    Display *display = Tk_Display(textPtr->tkwin);
    XColor *fill, *outline;
    int i;

    if (ornPtr->type == ORN_TEXT) {
	/*
	 * Text, drawn with -fill (a GC with the font, for Tk's fonts
	 * that use it).
	 */

	Tk_Font tkfont = ORN_FONT(textPtr, ornPtr);
	char *text = (ornPtr->text != NULL) ? ornPtr->text : "";
	double x = g->textX + dx, y = g->textY + dy;

	if ((ornPtr->fillColor == NULL) || (*text == '\0')
		|| (x < -30000) || (x > 30000) || (y < -30000)
		|| (y > 30000)) {
	    return;
	}
	if ((ornPtr->fillGC != None)
		&& (ornPtr->gcFont != Tk_FontId(tkfont))) {
	    XFreeGC(textPtr->display, ornPtr->fillGC);
	    ornPtr->fillGC = None;
	}
	if (ornPtr->fillGC == None) {
	    XGCValues values;

	    values.foreground = ornPtr->fillColor->pixel;
	    values.font = Tk_FontId(tkfont);
	    Tk_MakeWindowExist(textPtr->tkwin);
	    ornPtr->fillGC = XCreateGC(display,
		    Tk_WindowId(textPtr->tkwin), GCForeground | GCFont,
		    &values);
	    ornPtr->gcFont = values.font;
	}
	Tk_DrawChars(display, d, ornPtr->fillGC, tkfont, text,
		(int) strlen(text), (int) x, (int) y);
	return;
    }
    fill = ornPtr->fillColor;
    outline = ornPtr->outlineColor;
    if ((ornPtr->type == ORN_ARC) && (ornPtr->style == ARC_ARC)) {
	fill = NULL;		/* An open arc is not filled. */
    }
    if (ornPtr->type == ORN_LINE) {
	/*
	 * A line is drawn with -fill.
	 */

	outline = fill;
	fill = NULL;
    }
    if ((fill != NULL) && (ornPtr->fillGC == None)) {
	ornPtr->fillGC = MakeGC(textPtr, ornPtr, fill, 0);
    }
    if ((outline != NULL) && (ornPtr->outlineGC == None)) {
	ornPtr->outlineGC = MakeGC(textPtr, ornPtr, outline, 1);
    }
    if (fill != NULL && (g->numCoords >= 3)) {
	FillPolygon(display, d, ornPtr->fillGC, g->coords, g->numCoords,
		r, dx, dy);
    }
    if (outline != NULL && (g->numCoords >= 2)) {
	DrawPolyline(display, d, ornPtr->outlineGC, g->coords,
		g->numCoords, g->closed, r, dx, dy);
    }
    for (i = 0; i < g->numHeads; i++) {
	if (ornPtr->type == ORN_LINE && ornPtr->fillColor != NULL) {
	    if (ornPtr->fillGC == None) {
		ornPtr->fillGC = MakeGC(textPtr, ornPtr,
			ornPtr->fillColor, 0);
	    }
	    FillPolygon(display, d, ornPtr->fillGC, g->heads[i], 4, r,
		    dx, dy);
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnDraw --
 *
 *	Draws the ornaments of a layer (under or over the text) that
 *	cross the vertical range [yTop, yTop + height) of the window
 *	into a drawable whose top is at yTop (the pixmap of a display
 *	line; its x coordinates are those of the window).
 *
 *----------------------------------------------------------------------
 */

void
TkTextOrnDraw(textPtr, d, under, yTop, height)
    TkText *textPtr;
    Drawable d;
    int under;
    int yTop, height;
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr;
    ClipRect r;
    int m;

    if (infoPtr == NULL) {
	return;
    }
    for (ornPtr = infoPtr->firstPtr; ornPtr != NULL;
	    ornPtr = ornPtr->nextPtr) {
	OrnGeom *g = &ornPtr->geom;

	if (!g->valid || (ornPtr->under != under) || (g->y0 >= yTop + height)
		|| (g->y1 <= yTop)) {
	    continue;
	}
	m = CLIP_MARGIN + ornPtr->width;
	r.x0 = -m;
	r.x1 = Tk_Width(textPtr->tkwin) + m;
	r.y0 = yTop - m;
	r.y1 = yTop + height + m;
	DrawOrnament(textPtr, d, ornPtr, g, &r, 0.0, (double) -yTop);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Commands.
 *
 *----------------------------------------------------------------------
 */

static Ornament *
FindOrnament(interp, textPtr, arg)
    Tcl_Interp *interp;
    TkText *textPtr;
    Arg arg;
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr;
    int id;

    if (Tcl_GetInt(interp, LangString(arg), &id) != TCL_OK) {
	return NULL;
    }
    if (infoPtr != NULL) {
	for (ornPtr = infoPtr->firstPtr; ornPtr != NULL;
		ornPtr = ornPtr->nextPtr) {
	    if (ornPtr->id == id) {
		return ornPtr;
	    }
	}
    }
    Tcl_AppendResult(interp, "ornament \"", LangString(arg),
	    "\" doesn't exist", NULL);
    return NULL;
}

/*
 * Schedules a redisplay that erases the ornament where it was drawn
 * (the new place is found by TkTextOrnUpdate).
 */

static void
RedrawOld(textPtr, ornPtr)
    TkText *textPtr;
    Ornament *ornPtr;
{
    OrnGeom *g = &ornPtr->geom;
    int y0 = 0, y1 = 0;

    ornPtr->dirty = 1;
    if (g->valid) {
	y0 = (g->y0 < 0) ? 0 : g->y0;
	y1 = (g->y1 > Tk_Height(textPtr->tkwin)) ? Tk_Height(textPtr->tkwin)
		: g->y1;
	if (y1 < y0) {
	    y1 = y0;
	}
    }
    TkTextRedrawRegion(textPtr, 0, y0, Tk_Width(textPtr->tkwin), y1 - y0);
}

static void
FreeGCs(textPtr, ornPtr)
    TkText *textPtr;
    Ornament *ornPtr;
{
    if (ornPtr->fillGC != None) {
	XFreeGC(textPtr->display, ornPtr->fillGC);
	ornPtr->fillGC = None;
    }
    if (ornPtr->outlineGC != None) {
	XFreeGC(textPtr->display, ornPtr->outlineGC);
	ornPtr->outlineGC = None;
    }
}

static int
ConfigureOrnament(interp, textPtr, ornPtr, argc, args, flags)
    Tcl_Interp *interp;
    TkText *textPtr;
    Ornament *ornPtr;
    int argc;
    Arg *args;
    int flags;
{
    char *s;
    int code = TCL_OK;

    if (Tk_ConfigureWidget(interp, textPtr->tkwin, SPECS(ornPtr), argc,
	    args, (char *) ornPtr, flags) != TCL_OK) {
	code = TCL_ERROR;
    }

    /*
     * Translate the options (a bad value is reported, and the option
     * then works as its default).
     */

    ornPtr->arrow = 0;
    s = (ornPtr->type == ORN_LINE) ? (char *) ornPtr->arrowUid : NULL;
    if ((s == NULL) || (strcmp(s, "none") == 0) || (*s == '\0')) {
	ornPtr->arrow = 0;
    } else if (strcmp(s, "first") == 0) {
	ornPtr->arrow = ARROW_FIRST;
    } else if (strcmp(s, "last") == 0) {
	ornPtr->arrow = ARROW_LAST;
    } else if (strcmp(s, "both") == 0) {
	ornPtr->arrow = ARROW_FIRST | ARROW_LAST;
    } else if (code == TCL_OK) {
	Tcl_AppendResult(interp, "bad arrow spec \"", s,
		"\": must be none, first, last, or both", NULL);
	code = TCL_ERROR;
    }
    ornPtr->arrowShape[0] = 8;
    ornPtr->arrowShape[1] = 10;
    ornPtr->arrowShape[2] = 3;
    s = (ornPtr->type == ORN_LINE) ? ornPtr->arrowShapeString : NULL;
    if ((s != NULL) && (*s != '\0')) {
	double a, b, c;
	char extra;

	if (sscanf(s, "%lf %lf %lf %c", &a, &b, &c, &extra) == 3) {
	    ornPtr->arrowShape[0] = a;
	    ornPtr->arrowShape[1] = b;
	    ornPtr->arrowShape[2] = c;
	} else if (code == TCL_OK) {
	    Tcl_AppendResult(interp, "bad arrow shape \"", s,
		    "\": must be a list of 3 numbers", NULL);
	    code = TCL_ERROR;
	}
    }
    ornPtr->style = ARC_PIESLICE;
    s = (ornPtr->type == ORN_ARC) ? ornPtr->styleString : NULL;
    if ((s == NULL) || (*s == '\0') || (strcmp(s, "pieslice") == 0)) {
	ornPtr->style = ARC_PIESLICE;
    } else if (strcmp(s, "chord") == 0) {
	ornPtr->style = ARC_CHORD;
    } else if (strcmp(s, "arc") == 0) {
	ornPtr->style = ARC_ARC;
    } else if (code == TCL_OK) {
	Tcl_AppendResult(interp, "bad arc style \"", s,
		"\": must be pieslice, chord, or arc", NULL);
	code = TCL_ERROR;
    }
    s = (char *) ornPtr->layerUid;
    ornPtr->under = 0;
    if ((s != NULL) && (strcmp(s, "under") == 0)) {
	ornPtr->under = 1;
    } else if ((s != NULL) && (*s != '\0') && (strcmp(s, "over") != 0)
	    && (code == TCL_OK)) {
	Tcl_AppendResult(interp, "bad layer \"", s,
		"\": must be over or under", NULL);
	code = TCL_ERROR;
    }
    s = (char *) ornPtr->stateUid;
    ornPtr->hidden = 0;
    if ((s != NULL) && (strcmp(s, "hidden") == 0)) {
	ornPtr->hidden = 1;
    } else if ((s != NULL) && (*s != '\0') && (strcmp(s, "normal") != 0)
	    && (code == TCL_OK)) {
	Tcl_AppendResult(interp, "bad state \"", s,
		"\": must be normal or hidden", NULL);
	code = TCL_ERROR;
    }
    ornPtr->numDashes = 0;
    s = ornPtr->dashString;
    if ((s != NULL) && (*s != '\0')) {
	int dargc, i, v;
	Arg *dargs;
	LangFreeProc *freeProc = NULL;
	Arg list = Tcl_NewStringObj(s, -1);

	if (Lang_SplitList(interp, list, &dargc, &dargs, &freeProc)
		== TCL_OK) {
	    for (i = 0; (i < dargc) && (i < 16); i++) {
		char *end, *ds = LangString(dargs[i]);

		v = (int) strtol(ds, &end, 10);
		if ((end == ds) || (*end != '\0') || (v < 1) || (v > 255)) {
		    break;
		}
		ornPtr->dashes[i] = (char) v;
	    }
	    if ((i == dargc) && (dargc > 0) && (dargc <= 16)) {
		ornPtr->numDashes = dargc;
	    } else if (code == TCL_OK) {
		Tcl_AppendResult(interp, "bad dash list \"", s,
			"\": must be a list of 1 to 16 integers from 1 to 255",
			NULL);
		code = TCL_ERROR;
	    }
	    if (freeProc) {
		(*freeProc)(dargc, dargs);
	    }
	}
	Tcl_DecrRefCount(list);
    }
    if (ornPtr->width < 0) {
	ornPtr->width = 0;
    }
    FreeGCs(textPtr, ornPtr);
    return code;
}

/*
 * Checks the number of points of an ornament of a type: count points,
 * given as num items (an outline is one item, 4 points).
 */

static int
CheckCount(interp, type, count, num)
    Tcl_Interp *interp;
    int type, count, num;
{
    int need = (type == ORN_POLYGON) ? 3 : (type == ORN_TEXT) ? 1 : 2;

    if ((count < need) || ((type >= ORN_RECTANGLE) && (num != need))) {
	Tcl_AppendResult(interp, "wrong # points for a",
		((type == ORN_ARC) || (type == ORN_OVAL)) ? "n " : " ",
		typeNames[type], ": must be ",
		(type >= ORN_RECTANGLE) ? ((need == 1) ? "1" : "2")
		: (type == ORN_LINE) ? "at least 2" : "at least 3",
		NULL);
	return TCL_ERROR;
    }
    return TCL_OK;
}

static int
SetPoints(interp, textPtr, ornPtr, argc, args, template)
    Tcl_Interp *interp;
    TkText *textPtr;
    Ornament *ornPtr;
    int argc;
    Arg *args;
    int template;		/* A block type's ornament: the points of
				 * PARSE_TEMPLATE. */
{
    OrnPoint **points;
    int i, count, flags = PARSE_MARKS;

    if (template) {
	flags = PARSE_TEMPLATE;
    } else if (ornPtr->type <= ORN_POLYGON) {
	flags |= PARSE_OUTLINE;
    }
    points = (OrnPoint **) ckalloc((argc + 1) * sizeof(OrnPoint *));
    for (i = 0; i < argc; i++) {
	points[i] = ParsePoint(interp, textPtr, args[i], flags);
	if (points[i] == NULL) {
	    goto error;
	}
    }

    /*
     * An outline counts as 4 points (the corners of a box).
     */

    for (count = i = 0; i < argc; i++) {
	count += (points[i]->kind == PT_OUTLINE) ? 4 : 1;
    }
    if (CheckCount(interp, ornPtr->type, count, argc) != TCL_OK) {
	goto error;
    }
    for (i = 0; i < ornPtr->numPoints; i++) {
	FreePoint(textPtr, ornPtr->points[i]);
    }
    if (ornPtr->points != NULL) {
	ckfree((char *) ornPtr->points);
    }
    ornPtr->points = points;
    ornPtr->numPoints = argc;
    return TCL_OK;

    error:
    while (--i >= 0) {
	FreePoint(textPtr, points[i]);
    }
    ckfree((char *) points);
    return TCL_ERROR;
}

static void
FreeOrnament(textPtr, ornPtr)
    TkText *textPtr;
    Ornament *ornPtr;
{
    int i;

    for (i = 0; i < ornPtr->numPoints; i++) {
	FreePoint(textPtr, ornPtr->points[i]);
    }
    if (ornPtr->points != NULL) {
	ckfree((char *) ornPtr->points);
    }
    FreeGCs(textPtr, ornPtr);
    Tk_FreeOptions(SPECS(ornPtr), (char *) ornPtr, textPtr->display, 0);
    FreeGeom(&ornPtr->geom);
    ckfree((char *) ornPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnBeforeDelete, TkTextOrnAfterDelete --
 *
 *	Called by DeleteChars before and after the B-tree deletes the
 *	range [index1, index2): an ornament whose text is all deleted
 *	is deleted with it, unless -keep is set.  Only an ornament all
 *	of whose indices are private marks qualifies (one that uses a
 *	mark of the program, a tag, "end" or "@x,y" is never deleted
 *	this way); it is deleted if the character of each "at" point
 *	(the one after its mark, or before it for left gravity) is in
 *	the range, and the range of each range point is inside it.  The
 *	undo does not bring it back: ornaments are not part of the text.
 *
 *----------------------------------------------------------------------
 */

static int
AllDeleted(textPtr, ptPtr, index1Ptr, index2Ptr)
    TkText *textPtr;
    OrnPoint *ptPtr;
    TkTextIndex *index1Ptr, *index2Ptr;
{
    TkTextIndex a, b;
    int i;

    for (i = 0; i < ptPtr->numIndices; i++) {
	if (ptPtr->index[i].markPtr == NULL) {
	    return 0;
	}
    }
    for (i = 0; i < ptPtr->numKids; i++) {
	if (!AllDeleted(textPtr, ptPtr->kids[i], index1Ptr, index2Ptr)) {
	    return 0;
	}
    }
    if (ptPtr->numIndices == 0) {
	return 1;
    }
    TkTextMarkSegToIndex(textPtr, ptPtr->index[0].markPtr, &a);
    if (ptPtr->kind == PT_AT) {
	if (ptPtr->index[0].markPtr->typePtr == &tkTextLeftMarkType) {
	    b = a;
	    TkTextIndexBackChars(&b, 1, &a);
	    if (TkTextIndexCmp(&a, &b) == 0) {
		return 0;		/* No character before it. */
	    }
	} else {
	    TkTextIndexForwChars(&a, 1, &b);
	}
    } else {
	TkTextMarkSegToIndex(textPtr, ptPtr->index[1].markPtr, &b);
	if (TkTextIndexCmp(&b, &a) < 0) {
	    TkTextIndex tmp = a;

	    a = b;
	    b = tmp;
	}
    }
    return (TkTextIndexCmp(index1Ptr, &a) <= 0)
	    && (TkTextIndexCmp(&b, index2Ptr) <= 0);
}

void
TkTextOrnBeforeDelete(textPtr, index1Ptr, index2Ptr)
    TkText *textPtr;
    TkTextIndex *index1Ptr, *index2Ptr;
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr;
    int i;

    if (infoPtr == NULL) {
	return;
    }
    for (ornPtr = infoPtr->firstPtr; ornPtr != NULL;
	    ornPtr = ornPtr->nextPtr) {
	ornPtr->doomed = !ornPtr->keep;
	for (i = 0; ornPtr->doomed && (i < ornPtr->numPoints); i++) {
	    ornPtr->doomed = AllDeleted(textPtr, ornPtr->points[i],
		    index1Ptr, index2Ptr);
	}
    }
}

void
TkTextOrnAfterDelete(textPtr)
    TkText *textPtr;
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr, **prevPtrPtr;

    if (infoPtr == NULL) {
	return;
    }
    for (prevPtrPtr = &infoPtr->firstPtr; *prevPtrPtr != NULL; ) {
	ornPtr = *prevPtrPtr;
	if (ornPtr->doomed) {
	    *prevPtrPtr = ornPtr->nextPtr;
	    RedrawOld(textPtr, ornPtr);
	    FreeOrnament(textPtr, ornPtr);
	} else {
	    prevPtrPtr = &ornPtr->nextPtr;
	}
    }
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnFreeAll --
 *
 *	Frees the ornaments of a widget that is being destroyed.
 *
 *----------------------------------------------------------------------
 */

void
TkTextOrnFreeAll(textPtr)
    TkText *textPtr;
{
    TkTextOrnInfo *infoPtr = textPtr->ornInfoPtr;
    Ornament *ornPtr, *nextPtr;

    if (infoPtr == NULL) {
	return;
    }
    for (ornPtr = infoPtr->firstPtr; ornPtr != NULL; ornPtr = nextPtr) {
	nextPtr = ornPtr->nextPtr;
	FreeOrnament(textPtr, ornPtr);
    }

    /*
     * The strokes of split lines: the layouts of the blocks still
     * displayed hold references of their own (TkTextOrnFreeBlock).
     */

    TkTextOrnTemplatesRelease(textPtr, infoPtr->strokesPtr);
    ckfree((char *) infoPtr);
    textPtr->ornInfoPtr = NULL;
}

/*
 * The ornaments of a widget, made when first needed.
 */

static TkTextOrnInfo *
GetOrnInfo(textPtr)
    TkText *textPtr;
{
    if (textPtr->ornInfoPtr == NULL) {
	textPtr->ornInfoPtr = (TkTextOrnInfo *) ckalloc(sizeof(TkTextOrnInfo));
	textPtr->ornInfoPtr->firstPtr = NULL;
	textPtr->ornInfoPtr->nextId = 1;
	textPtr->ornInfoPtr->strokesPtr = NULL;
    }
    return textPtr->ornInfoPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnamentCmd --
 *
 *	The "ornament" widget subcommand:
 *
 *	ornament create type point point ... ?-option value ...?
 *	ornament delete id ?id ...?
 *	ornament names
 *	ornament configure id ?-option? ?value -option value ...?
 *	ornament cget id -option
 *	ornament points id ?point point ...?
 *	ornament coords id
 *	ornament point point
 *
 *----------------------------------------------------------------------
 */

int
TkTextOrnamentCmd(textPtr, interp, argc, args)
    TkText *textPtr;
    Tcl_Interp *interp;
    int argc;
    Arg *args;
{
    TkTextOrnInfo *infoPtr;
    Ornament *ornPtr, **prevPtrPtr;
    char *cmd;
    size_t length;
    int i;

    if (argc < 3) {
	Tcl_AppendResult(interp, "wrong # args: should be \"",
		LangString(args[0]), " ornament option ?arg arg ...?\"", NULL);
	return TCL_ERROR;
    }
    cmd = LangString(args[2]);
    length = strlen(cmd);
    infoPtr = GetOrnInfo(textPtr);

    if (strcmp(cmd, "_splitlines") == 0) {
	/*
	 * A hook for the tests (t/splitlines.t), not an interface, and
	 * not documented in the manual: the split lines and frames
	 * generated for the block that starts at an index, as it is
	 * displayed now (see SplitsList).
	 */

	TkTextIndex index;
	TkTextSegment *segPtr;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " ornament _splitlines index\"", NULL);
	    return TCL_ERROR;
	}
	if (TkTextGetIndex(interp, textPtr, LangString(args[3]), &index)
		!= TCL_OK) {
	    return TCL_ERROR;
	}
	segPtr = TkIBTreeAt(&index, 0);
	if (segPtr == NULL) {
	    Tcl_AppendResult(interp, "no block starts at \"",
		    LangString(args[3]), "\"", NULL);
	    return TCL_ERROR;
	}
	return SplitsList(interp, TkTextBlockOrnsAt(textPtr, segPtr));
    }
    if ((length >= 2) && (strncmp(cmd, "create", length) == 0)) {
	int type, numPoints;

	if (argc < 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]),
		    " ornament create type point ?point ...? ?option value ...?\"",
		    NULL);
	    return TCL_ERROR;
	}
	for (type = 0; typeNames[type] != NULL; type++) {
	    if (strcmp(LangString(args[3]), typeNames[type]) == 0) {
		break;
	    }
	}
	if (typeNames[type] == NULL) {
	    Tcl_AppendResult(interp, "bad ornament type \"",
		    LangString(args[3]),
		    "\": must be line, polygon, rectangle, oval, arc, or text",
		    NULL);
	    return TCL_ERROR;
	}
	for (numPoints = 0; 4 + numPoints < argc; numPoints++) {
	    char *s = LangString(args[4 + numPoints]);

	    if ((s[0] == '-') && ((s[1] < '0') || (s[1] > '9'))) {
		break;
	    }
	}
	ornPtr = (Ornament *) ckalloc(sizeof(Ornament));
	memset(ornPtr, 0, sizeof(Ornament));
	ornPtr->type = type;
	ornPtr->fillGC = ornPtr->outlineGC = None;
	if (SetPoints(interp, textPtr, ornPtr, numPoints, args + 4, 0)
		!= TCL_OK) {
	    ckfree((char *) ornPtr);
	    return TCL_ERROR;
	}
	if (ConfigureOrnament(interp, textPtr, ornPtr, argc - 4 - numPoints,
		args + 4 + numPoints, 0) != TCL_OK) {
	    FreeOrnament(textPtr, ornPtr);
	    return TCL_ERROR;
	}
	ornPtr->id = infoPtr->nextId++;
	for (prevPtrPtr = &infoPtr->firstPtr; *prevPtrPtr != NULL;
		prevPtrPtr = &(*prevPtrPtr)->nextPtr) {
	    /* Empty: appended, so that it is drawn last. */
	}
	*prevPtrPtr = ornPtr;
	RedrawOld(textPtr, ornPtr);
	Tcl_SetObjResult(interp, Tcl_NewIntObj(ornPtr->id));
	return TCL_OK;
    } else if ((length >= 2) && (strncmp(cmd, "delete", length) == 0)) {
	for (i = 3; i < argc; i++) {
	    Ornament *delPtr = FindOrnament(interp, textPtr, args[i]);

	    if (delPtr == NULL) {
		return TCL_ERROR;
	    }
	    for (prevPtrPtr = &infoPtr->firstPtr; *prevPtrPtr != delPtr;
		    prevPtrPtr = &(*prevPtrPtr)->nextPtr) {
		/* Empty. */
	    }
	    *prevPtrPtr = delPtr->nextPtr;
	    RedrawOld(textPtr, delPtr);
	    FreeOrnament(textPtr, delPtr);
	}
	return TCL_OK;
    } else if ((length >= 1) && (strncmp(cmd, "names", length) == 0)) {
	if (argc != 3) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " ornament names\"", NULL);
	    return TCL_ERROR;
	}
	for (ornPtr = infoPtr->firstPtr; ornPtr != NULL;
		ornPtr = ornPtr->nextPtr) {
	    Tcl_IntResults(interp, 1, 1, ornPtr->id);
	}
	return TCL_OK;
    } else if ((length >= 3) && (strncmp(cmd, "configure", length) == 0)) {
	if (argc < 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]),
		    " ornament configure id ?option? ?value option value ...?\"",
		    NULL);
	    return TCL_ERROR;
	}
	ornPtr = FindOrnament(interp, textPtr, args[3]);
	if (ornPtr == NULL) {
	    return TCL_ERROR;
	}
	if (argc == 4) {
	    return Tk_ConfigureInfo(interp, textPtr->tkwin, SPECS(ornPtr),
		    (char *) ornPtr, NULL, 0);
	} else if (argc == 5) {
	    return Tk_ConfigureInfo(interp, textPtr->tkwin, SPECS(ornPtr),
		    (char *) ornPtr, LangString(args[4]), 0);
	}
	RedrawOld(textPtr, ornPtr);
	return ConfigureOrnament(interp, textPtr, ornPtr, argc - 4, args + 4,
		TK_CONFIG_ARGV_ONLY);
    } else if ((length >= 2) && (strncmp(cmd, "cget", length) == 0)) {
	if (argc != 5) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " ornament cget id option\"", NULL);
	    return TCL_ERROR;
	}
	ornPtr = FindOrnament(interp, textPtr, args[3]);
	if (ornPtr == NULL) {
	    return TCL_ERROR;
	}
	return Tk_ConfigureValue(interp, textPtr->tkwin, SPECS(ornPtr),
		(char *) ornPtr, LangString(args[4]), 0);
    } else if ((length >= 3) && (strncmp(cmd, "coords", length) == 0)) {
	Tcl_Obj *listPtr;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " ornament coords id\"", NULL);
	    return TCL_ERROR;
	}
	ornPtr = FindOrnament(interp, textPtr, args[3]);
	if (ornPtr == NULL) {
	    return TCL_ERROR;
	}

	/*
	 * The points (before smoothing and arrows) as they are now; an
	 * empty list if the ornament is not drawn (none of its positions
	 * displayed, or an index that does not parse).
	 */

	listPtr = Tcl_NewListObj(0, NULL);
	{
	    PtBuf pts;
	    int shown = 0;

	    if ((EvalPoints(interp, textPtr, ornPtr, &shown, &pts, NULL)
		    == TCL_OK)
		    && shown) {
		for (i = 0; i < 2*pts.num; i++) {
		    Tcl_ListObjAppendElement(NULL, listPtr,
			    Tcl_NewDoubleObj(pts.xy[i]));
		}
	    }
	    if (pts.xy != NULL) {
		ckfree((char *) pts.xy);
	    }
	    Tcl_ResetResult(interp);
	}
	Tcl_SetObjResult(interp, listPtr);
	return TCL_OK;
    } else if ((length >= 6) && (strncmp(cmd, "points", length) == 0)) {
	Tcl_Obj *listPtr;

	if (argc < 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " ornament points id ?point ...?\"",
		    NULL);
	    return TCL_ERROR;
	}
	ornPtr = FindOrnament(interp, textPtr, args[3]);
	if (ornPtr == NULL) {
	    return TCL_ERROR;
	}
	if (argc > 4) {
	    if (SetPoints(interp, textPtr, ornPtr, argc - 4, args + 4, 0)
		    != TCL_OK) {
		return TCL_ERROR;
	    }
	    RedrawOld(textPtr, ornPtr);
	    return TCL_OK;
	}
	listPtr = Tcl_NewListObj(0, NULL);
	for (i = 0; i < ornPtr->numPoints; i++) {
	    Tcl_ListObjAppendElement(NULL, listPtr,
		    PrintPoint(textPtr, ornPtr->points[i]));
	}
	Tcl_SetObjResult(interp, listPtr);
	return TCL_OK;
    } else if (strcmp(cmd, "point") == 0) {
	OrnPoint *ptPtr;
	double x, y;
	int shown = 0;
	OrnFont font;

	if (argc != 4) {
	    Tcl_AppendResult(interp, "wrong # args: should be \"",
		    LangString(args[0]), " ornament point point\"", NULL);
	    return TCL_ERROR;
	}
	ptPtr = ParsePoint(interp, textPtr, args[3], 0);
	if (ptPtr == NULL) {
	    return TCL_ERROR;
	}
	if (EvalPoint(interp, textPtr, ptPtr, &shown, &x, &y, &font, NULL)
		!= TCL_OK) {
	    FreePoint(textPtr, ptPtr);
	    return TCL_ERROR;
	}
	FreePoint(textPtr, ptPtr);
	Tcl_DoubleResults(interp, 2, 0, x, y);
	Tcl_IntResults(interp, 1, 1, shown);
	return TCL_OK;
    }
    Tcl_AppendResult(interp, "bad ornament option \"", cmd,
	    "\": must be cget, configure, coords, create, delete, names, ",
	    "point, or points", NULL);
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * Ornaments of blocks.
 *
 *	A layout callback may return, among its lists, ornaments of the
 *	block: {type x1 y1 x2 y2 ... ?-option value ...?}, in pixels from
 *	the top left corner of the block (TkTextOrnLayoutItem); and a
 *	block type may have templates, ornaments whose points are
 *	computed from the boxes of the block and of its leaves
 *	(-ornaments of "block configure", TkTextOrnTemplatesParse and
 *	TkTextOrnLayoutTemplates).  Both are laid out with the block: the
 *	list of them (TkTextBlockOrns) is kept with the block's layout
 *	(IBTreeInfo in tkTextDisp.c), freed with it, and drawn by
 *	IBTreeDisplayProc (TkTextOrnDrawBlock) every time the block is
 *	drawn.
 *
 *----------------------------------------------------------------------
 */

typedef struct BlockOrnItem {
    Ornament *ornPtr;		/* Options (and GCs). */
    int owned;			/* ornPtr is the item's own (from the layout
				 * callback), not a template's. */
    int addIndex;		/* The number of additional lines (stolen
				 * lines) before it in the callback's list:
				 * under the text, it is drawn after them. */
    OrnGeom geom;		/* In block coordinates. */
    int split;			/* SPLIT_LINE or SPLIT_FRAME for a stroke of
				 * a split line or frame (ornPtr is a stroke
				 * of the widget: GetStrokes), else 0; ... */
    int value, bit;		/* ... the number its picture shows, and the
				 * bit of it that this stroke stands for. */
} BlockOrnItem;

#define SPLIT_LINE	1
#define SPLIT_FRAME	2

typedef struct TkTextBlockOrns {
    int num, size;
    BlockOrnItem *items;	/* In the order they are drawn. */
    struct TkTextOrnTemplates *templPtr;
				/* The templates used (a reference held), or
				 * NULL. */
    struct TkTextOrnTemplates *strokesPtr;
				/* The strokes of split lines used (a
				 * reference held), or NULL. */
} TkTextBlockOrns;

typedef struct TkTextOrnTemplates {
    int refCount;		/* The block type and the layouts using
				 * them. */
    int num;
    Ornament **orns;
} TkTextOrnTemplates;

/*
 * Whether an element of an ornament specification is an option: "-"
 * and a letter (a negative number is not one).
 */

#define IS_OPTION(s)	(((s)[0] == '-') && isalpha(UCHAR((s)[1])))

/*
 * Whether a string names a type of ornament (the first element of an
 * ornament in the result of a layout callback).
 */

int
TkTextOrnIsType(string)
    char *string;
{
    int type;

    for (type = 0; typeNames[type] != NULL; type++) {
	if (strcmp(string, typeNames[type]) == 0) {
	    return 1;
	}
    }
    return 0;
}

static int
ParseType(interp, string, typePtr)
    Tcl_Interp *interp;
    char *string;
    int *typePtr;
{
    int type;

    for (type = 0; typeNames[type] != NULL; type++) {
	if (strcmp(string, typeNames[type]) == 0) {
	    *typePtr = type;
	    return TCL_OK;
	}
    }
    Tcl_AppendResult(interp, "bad ornament type \"", string,
	    "\": must be line, polygon, rectangle, oval, arc, or text", NULL);
    return TCL_ERROR;
}

static Ornament *
NewOrnament(type)
    int type;
{
    Ornament *ornPtr = (Ornament *) ckalloc(sizeof(Ornament));

    memset(ornPtr, 0, sizeof(Ornament));
    ornPtr->type = type;
    ornPtr->fillGC = ornPtr->outlineGC = None;
    return ornPtr;
}

/*
 * Makes room for count more items in a block's list (made if NULL),
 * before the others or after them; returns the first of them.
 */

static BlockOrnItem *
AddItems(listPtrPtr, count, front)
    TkTextBlockOrns **listPtrPtr;
    int count;
    int front;			/* Before the others. */
{
    TkTextBlockOrns *listPtr = *listPtrPtr;
    BlockOrnItem *itemPtr;

    if (listPtr == NULL) {
	listPtr = *listPtrPtr = (TkTextBlockOrns *)
		ckalloc(sizeof(TkTextBlockOrns));
	listPtr->num = listPtr->size = 0;
	listPtr->items = NULL;
	listPtr->templPtr = NULL;
	listPtr->strokesPtr = NULL;
    }
    if (listPtr->num + count > listPtr->size) {
	listPtr->size = listPtr->size ? 2 * listPtr->size : 4;
	if (listPtr->size < listPtr->num + count) {
	    listPtr->size = listPtr->num + count;
	}
	listPtr->items = (BlockOrnItem *) ckrealloc((char *) listPtr->items,
		listPtr->size * sizeof(BlockOrnItem));
    }
    if (front) {
	memmove(listPtr->items + count, listPtr->items,
		listPtr->num * sizeof(BlockOrnItem));
	itemPtr = listPtr->items;
    } else {
	itemPtr = listPtr->items + listPtr->num;
    }
    listPtr->num += count;
    memset(itemPtr, 0, count * sizeof(BlockOrnItem));
    return itemPtr;
}

#define AddItem(listPtrPtr, front)	AddItems(listPtrPtr, 1, front)

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnLayoutItem --
 *
 *	Parses an ornament returned by a layout callback, {type x1 y1
 *	... ?-option value ...?} (argc elements in args), computes its
 *	outline and appends it to the block's list (*listPtrPtr, made if
 *	NULL).
 *
 * Results:
 *	TCL_OK, or TCL_ERROR with a message in interp.
 *
 *----------------------------------------------------------------------
 */

int
TkTextOrnLayoutItem(textPtr, interp, argc, args, addIndex, listPtrPtr)
    TkText *textPtr;
    Tcl_Interp *interp;
    int argc;
    Arg *args;
    int addIndex;		/* Stolen lines before it. */
    TkTextBlockOrns **listPtrPtr;
{
    int type, i;
    double x, y;
    PtBuf pts;
    Ornament *ornPtr;
    BlockOrnItem *itemPtr;

    if (ParseType(interp, LangString(args[0]), &type) != TCL_OK) {
	return TCL_ERROR;
    }
    pts.num = pts.size = 0;
    pts.xy = NULL;
    for (i = 1; (i < argc) && !IS_OPTION(LangString(args[i])); i += 2) {
	if (i + 1 >= argc || IS_OPTION(LangString(args[i + 1]))) {
	    Tcl_AppendResult(interp, "odd number of coordinates", NULL);
	    goto error;
	}
	if ((Tcl_GetDouble(interp, LangString(args[i]), &x) != TCL_OK)
		|| (Tcl_GetDouble(interp, LangString(args[i + 1]), &y)
			!= TCL_OK)) {
	    goto error;
	}
	PtAdd(&pts, x, y);
    }
    if (CheckCount(interp, type, pts.num, pts.num) != TCL_OK) {
	goto error;
    }
    ornPtr = NewOrnament(type);
    if (ConfigureOrnament(interp, textPtr, ornPtr, argc - i, args + i, 0)
	    != TCL_OK) {
	FreeOrnament(textPtr, ornPtr);
	goto error;
    }
    itemPtr = AddItem(listPtrPtr, 0);
    itemPtr->ornPtr = ornPtr;
    itemPtr->owned = 1;
    itemPtr->addIndex = addIndex;
    if (ornPtr->hidden) {
	ckfree((char *) pts.xy);
    } else {
	ShapeGeom(textPtr, ornPtr, pts.xy, pts.num, &itemPtr->geom);
	itemPtr->geom.valid = 1;
    }
    return TCL_OK;

    error:
    if (pts.xy != NULL) {
	ckfree((char *) pts.xy);
    }
    return TCL_ERROR;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnTemplatesParse --
 *
 *	Parses the value of -ornaments of a block type: a list of
 *	ornament specifications {type point point ... ?-option value
 *	...?} whose points are those of PARSE_TEMPLATE.  An empty list
 *	gives NULL.
 *
 * Results:
 *	TCL_OK with *templPtrPtr set (a reference held by the caller), or
 *	TCL_ERROR with a message in interp.
 *
 *----------------------------------------------------------------------
 */

int
TkTextOrnTemplatesParse(interp, textPtr, arg, templPtrPtr)
    Tcl_Interp *interp;
    TkText *textPtr;
    Arg arg;
    TkTextOrnTemplates **templPtrPtr;
{
    int argc, argc1, i, j, type, code = TCL_OK;
    Arg *args, *args1;
    LangFreeProc *freeProc = NULL, *freeProc1;
    TkTextOrnTemplates *templPtr = NULL;
    Ornament *ornPtr;
    char buf[40];

    *templPtrPtr = NULL;
    if ((arg == NULL) || (*LangString(arg) == '\0')) {
	return TCL_OK;
    }
    if (Lang_SplitList(interp, arg, &argc, &args, &freeProc) != TCL_OK) {
	return TCL_ERROR;
    }
    if (argc == 0) {
	goto done;
    }
    templPtr = (TkTextOrnTemplates *) ckalloc(sizeof(TkTextOrnTemplates));
    templPtr->refCount = 1;
    templPtr->num = 0;
    templPtr->orns = (Ornament **) ckalloc(argc * sizeof(Ornament *));
    for (i = 0; i < argc; i++) {
	freeProc1 = NULL;
	if (Lang_SplitList(interp, args[i], &argc1, &args1, &freeProc1)
		!= TCL_OK) {
	    code = TCL_ERROR;
	} else if (argc1 < 1) {
	    Tcl_AppendResult(interp, "empty ornament specification", NULL);
	    code = TCL_ERROR;
	} else if (ParseType(interp, LangString(args1[0]), &type) != TCL_OK) {
	    code = TCL_ERROR;
	} else {
	    for (j = 1; (j < argc1) && !IS_OPTION(LangString(args1[j]));
		    j++) {
		/* Empty: the points. */
	    }
	    ornPtr = NewOrnament(type);
	    if ((SetPoints(interp, textPtr, ornPtr, j - 1, args1 + 1, 1)
		    != TCL_OK) || (ConfigureOrnament(interp, textPtr, ornPtr,
		    argc1 - j, args1 + j, 0) != TCL_OK)) {
		FreeOrnament(textPtr, ornPtr);
		code = TCL_ERROR;
	    } else {
		templPtr->orns[templPtr->num++] = ornPtr;
	    }
	}
	if (freeProc1) {
	    (*freeProc1)(argc1, args1);
	}
	if (code != TCL_OK) {
	    sprintf(buf, "%d", i);
	    Tcl_AppendResult(interp, " (ornament ", buf, " of -ornaments)",
		    NULL);
	    TkTextOrnTemplatesRelease(textPtr, templPtr);
	    templPtr = NULL;
	    break;
	}
    }

    done:
    if (freeProc) {
	(*freeProc)(argc, args);
    }
    *templPtrPtr = templPtr;
    return code;
}

void
TkTextOrnTemplatesRelease(textPtr, templPtr)
    TkText *textPtr;
    TkTextOrnTemplates *templPtr;
{
    int i;

    if ((templPtr == NULL) || (--templPtr->refCount > 0)) {
	return;
    }
    for (i = 0; i < templPtr->num; i++) {
	FreeOrnament(textPtr, templPtr->orns[i]);
    }
    ckfree((char *) templPtr->orns);
    ckfree((char *) templPtr);
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnLayoutTemplates --
 *
 *	Computes the outlines of the templates of a block type for a
 *	block laid out with the given boxes (block coordinates), and puts
 *	them before the other ornaments of the block's list (made if
 *	NULL).  A template whose point cannot be computed (a leaf that
 *	does not exist or is not shown) is not drawn for this block.
 *
 *----------------------------------------------------------------------
 */

void
TkTextOrnLayoutTemplates(textPtr, templPtr, boxesPtr, listPtrPtr)
    TkText *textPtr;
    TkTextOrnTemplates *templPtr;
    TkTextOrnBlockBoxes *boxesPtr;
    TkTextBlockOrns **listPtrPtr;
{
    int i;
    BlockOrnItem *itemPtr;
    OrnGeom geom;

    if ((templPtr == NULL) || (templPtr->num == 0)) {
	return;
    }
    for (i = templPtr->num - 1; i >= 0; i--) {
	Ornament *ornPtr = templPtr->orns[i];

	if (ornPtr->hidden) {
	    continue;
	}
	if (ComputeGeom(textPtr->interp, textPtr, ornPtr, &geom, boxesPtr)
		!= TCL_OK) {
	    Tcl_ResetResult(textPtr->interp);
	    continue;
	}
	if (!geom.valid) {
	    continue;
	}
	itemPtr = AddItem(listPtrPtr, 1);
	itemPtr->ornPtr = ornPtr;
	itemPtr->owned = 0;
	itemPtr->addIndex = 0;
	itemPtr->geom = geom;
    }
    if ((*listPtrPtr != NULL) && ((*listPtrPtr)->templPtr == NULL)) {
	templPtr->refCount++;
	(*listPtrPtr)->templPtr = templPtr;
    }
}

/*
 *----------------------------------------------------------------------
 *
 * Split lines and frames.
 *
 *	Where the core lays leaves of a block out one under another (a
 *	"stack": TkTextIBTreeLayoutProc), it shows the structure of the
 *	tree hidden in the stack: between two leaves, the depth of the
 *	separator; around the stack, the number of nodes with a single
 *	child above it.  Each number is shown in binary, a stroke per bit
 *	set: bit 0 a dotted line, bit 1 a dashed line, bit 2 a solid line
 *	(all one pixel wide), bit 3 and every bit above it a solid line
 *	three pixels wide.  The strokes of a number do not touch: one row
 *	of pixels is left between two of them (so the one-pixel strokes
 *	are 2 pixels apart), the lowest bit first: on top for the lines
 *	between leaves, innermost for the frames.
 *
 *	The strokes are ornaments (lines and rectangles) of the layer
 *	under the text, which the widget makes once and all its blocks
 *	share; a stroke drawn for a block is an item of the block's list,
 *	before all the others.
 *
 *----------------------------------------------------------------------
 */

#define NUM_STROKES	4
#define SPLIT_COLOR	"gray50"

static struct {
    char *name;			/* For "ornament _splitlines". */
    int width;			/* Pixels. */
    char *widthString;
    char *dash;			/* The value of -dash, or NULL: solid. */
} strokes[NUM_STROKES] = {
    {"dotted", 1, "1", "1 2"},
    {"dashed", 1, "1", "4 3"},
    {"solid", 1, "1", NULL},
    {"thick", 3, "3", NULL},
};

/*
 * The strokes of a widget: NUM_STROKES lines, then as many rectangles;
 * NULL if they cannot be made.
 */

static TkTextOrnTemplates *
GetStrokes(textPtr)
    TkText *textPtr;
{
    TkTextOrnInfo *infoPtr = GetOrnInfo(textPtr);
    TkTextOrnTemplates *strokesPtr;
    Ornament *ornPtr;
    Arg args[8];
    int frame, bit, argc, i, code = TCL_OK;

    if (infoPtr->strokesPtr != NULL) {
	return infoPtr->strokesPtr;
    }
    strokesPtr = (TkTextOrnTemplates *) ckalloc(sizeof(TkTextOrnTemplates));
    strokesPtr->refCount = 1;
    strokesPtr->num = 0;
    strokesPtr->orns = (Ornament **)
	    ckalloc(2 * NUM_STROKES * sizeof(Ornament *));
    for (frame = 0; frame < 2; frame++) {
	for (bit = 0; bit < NUM_STROKES; bit++) {
	    argc = 0;
	    args[argc++] = Tcl_NewStringObj(frame ? "-outline" : "-fill", -1);
	    args[argc++] = Tcl_NewStringObj(SPLIT_COLOR, -1);
	    args[argc++] = Tcl_NewStringObj("-layer", -1);
	    args[argc++] = Tcl_NewStringObj("under", -1);
	    args[argc++] = Tcl_NewStringObj("-width", -1);
	    args[argc++] = Tcl_NewStringObj(strokes[bit].widthString, -1);
	    if (strokes[bit].dash != NULL) {
		args[argc++] = Tcl_NewStringObj("-dash", -1);
		args[argc++] = Tcl_NewStringObj(strokes[bit].dash, -1);
	    }
	    ornPtr = NewOrnament(frame ? ORN_RECTANGLE : ORN_LINE);
	    if (ConfigureOrnament(textPtr->interp, textPtr, ornPtr, argc, args,
		    0) != TCL_OK) {
		code = TCL_ERROR;
	    }
	    for (i = 0; i < argc; i++) {
		Tcl_DecrRefCount(args[i]);
	    }
	    strokesPtr->orns[strokesPtr->num++] = ornPtr;
	}
    }
    if (code != TCL_OK) {
	Tcl_ResetResult(textPtr->interp);
	TkTextOrnTemplatesRelease(textPtr, strokesPtr);
	return NULL;
    }
    infoPtr->strokesPtr = strokesPtr;
    return strokesPtr;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnLayoutSplits --
 *
 *	Puts the strokes of the given pictures (see TkTextOrnSplit in
 *	tkText.h) before the other ornaments of a block's list (made if
 *	NULL), in the order of the pictures, and in each the lowest bit
 *	first.  A picture whose value is not positive has no strokes.
 *
 *	The lines of a picture go down from the row y: a stroke takes
 *	as many rows as it is wide, and one row is left before the next
 *	stroke.  The first frame is around the pixels of the box, next
 *	to them; one pixel is left before the next frame, further out.
 *
 *----------------------------------------------------------------------
 */

void
TkTextOrnLayoutSplits(textPtr, splits, num, listPtrPtr)
    TkText *textPtr;
    TkTextOrnSplit *splits;
    int num;
    TkTextBlockOrns **listPtrPtr;
{
    TkTextOrnTemplates *strokesPtr;
    BlockOrnItem *itemPtr;
    int i, bit, count = 0, stroke, width, pos, mid;
    double *pts;

    for (i = 0; i < num; i++) {
	for (bit = 0; (splits[i].value >> bit) > 0; bit++) {
	    if ((splits[i].value >> bit) & 1) {
		count++;
	    }
	}
    }
    if (count == 0) {
	return;
    }
    strokesPtr = GetStrokes(textPtr);
    if (strokesPtr == NULL) {
	return;
    }
    itemPtr = AddItems(listPtrPtr, count, 1);
    if ((*listPtrPtr)->strokesPtr == NULL) {
	strokesPtr->refCount++;
	(*listPtrPtr)->strokesPtr = strokesPtr;
    }
    for (i = 0; i < num; i++) {
	TkTextOrnSplit *sPtr = &splits[i];

	/*
	 * pos: the first row of the next line; for a frame, how far
	 * outside the box its inner edge is.  mid: the middle of the
	 * stroke, where the coordinates of the ornament are.
	 */

	pos = sPtr->frame ? 1 : sPtr->y;
	for (bit = 0; (sPtr->value >> bit) > 0; bit++) {
	    if (!((sPtr->value >> bit) & 1)) {
		continue;
	    }
	    stroke = (bit < NUM_STROKES) ? bit : NUM_STROKES - 1;
	    width = strokes[stroke].width;
	    mid = pos + (width - 1) / 2;
	    pts = (double *) ckalloc(4 * sizeof(double));
	    if (sPtr->frame) {
		pts[0] = sPtr->x - mid;
		pts[1] = sPtr->y - mid;
		pts[2] = sPtr->x + sPtr->width - 1 + mid;
		pts[3] = sPtr->y + sPtr->height - 1 + mid;
	    } else {
		/*
		 * A line with butt caps ends before the pixel of its end
		 * point.
		 */

		pts[0] = sPtr->x;
		pts[1] = mid;
		pts[2] = sPtr->x + sPtr->width;
		pts[3] = mid;
	    }
	    itemPtr->ornPtr = strokesPtr->orns[(sPtr->frame ? NUM_STROKES : 0)
		    + stroke];
	    itemPtr->owned = 0;
	    itemPtr->addIndex = 0;
	    itemPtr->split = sPtr->frame ? SPLIT_FRAME : SPLIT_LINE;
	    itemPtr->value = sPtr->value;
	    itemPtr->bit = bit;
	    ShapeGeom(textPtr, itemPtr->ornPtr, pts, 2, &itemPtr->geom);
	    itemPtr++;
	    pos += width + 1;
	}
    }
}

/*
 * The result of "ornament _splitlines index" (a hook for the tests):
 * for each stroke of the split lines and frames in a block's list, in
 * the order they are drawn, a list
 *
 *	kind value stroke x0 y0 x1 y1
 *
 * kind is "line" or "frame"; value, the number its picture shows;
 * stroke, "dotted", "dashed", "solid" or "thick"; and the pixels it
 * covers, from the top left corner of the block: for a line, the
 * columns x0 to x1 of the rows y0 to y1; for a frame, the border (one
 * pixel wide, three for "thick") of the box of the columns x0 to x1 and
 * the rows y0 to y1.  Dots and dashes start at x0 (a frame's at its top
 * left corner, clockwise).
 */

static int
SplitsList(interp, listPtr)
    Tcl_Interp *interp;
    TkTextBlockOrns *listPtr;
{
    Tcl_Obj *resultPtr = Tcl_NewListObj(0, NULL), *elPtr;
    int i, k, half, box[4];

    for (i = 0; (listPtr != NULL) && (i < listPtr->num); i++) {
	BlockOrnItem *itemPtr = &listPtr->items[i];
	double *xy = itemPtr->geom.coords;

	if (!itemPtr->split || !itemPtr->geom.valid) {
	    continue;
	}
	half = (itemPtr->ornPtr->width - 1) / 2;
	if (itemPtr->split == SPLIT_FRAME) {
	    /* The corners of a rectangle, clockwise from the top left. */
	    box[0] = (int) xy[0] - half;
	    box[1] = (int) xy[1] - half;
	    box[2] = (int) xy[4] + half;
	    box[3] = (int) xy[5] + half;
	} else {
	    box[0] = (int) xy[0];
	    box[1] = (int) xy[1] - half;
	    box[2] = (int) xy[2] - 1;
	    box[3] = (int) xy[3] + half;
	}
	elPtr = Tcl_NewListObj(0, NULL);
	Tcl_ListObjAppendElement(NULL, elPtr, Tcl_NewStringObj(
		(itemPtr->split == SPLIT_FRAME) ? "frame" : "line", -1));
	Tcl_ListObjAppendElement(NULL, elPtr, Tcl_NewIntObj(itemPtr->value));
	Tcl_ListObjAppendElement(NULL, elPtr, Tcl_NewStringObj(
		strokes[(itemPtr->bit < NUM_STROKES) ? itemPtr->bit
			: NUM_STROKES - 1].name, -1));
	for (k = 0; k < 4; k++) {
	    Tcl_ListObjAppendElement(NULL, elPtr, Tcl_NewIntObj(box[k]));
	}
	Tcl_ListObjAppendElement(NULL, resultPtr, elPtr);
    }
    Tcl_SetObjResult(interp, resultPtr);
    return TCL_OK;
}

/*
 *----------------------------------------------------------------------
 *
 * TkTextOrnDrawBlock --
 *
 *	Draws the ornaments of a block's list of a layer (under or over
 *	the text) into a drawable where the top left corner of the block
 *	is at (x, y); under the text, only those with the given number
 *	of stolen lines before them (all if addIndex is -1).
 *
 *----------------------------------------------------------------------
 */

void
TkTextOrnDrawBlock(textPtr, listPtr, d, under, addIndex, x, y)
    TkText *textPtr;
    TkTextBlockOrns *listPtr;
    Drawable d;
    int under, addIndex;
    int x, y;
{
    int i, m;
    ClipRect r;

    if (listPtr == NULL) {
	return;
    }
    for (i = 0; i < listPtr->num; i++) {
	BlockOrnItem *itemPtr = &listPtr->items[i];
	Ornament *ornPtr = itemPtr->ornPtr;

	if (!itemPtr->geom.valid || (ornPtr->under != under)
		|| ((addIndex >= 0) && (itemPtr->addIndex != addIndex))) {
	    continue;
	}

	/*
	 * X takes short coordinates: what is given to it is clipped to
	 * the width of the window and to a height that a pixmap of a
	 * display line does not exceed (with a margin).
	 */

	m = CLIP_MARGIN + ornPtr->width;
	r.x0 = -m - x;
	r.x1 = Tk_Width(textPtr->tkwin) + m - x;
	r.y0 = -m - y;
	r.y1 = 16384 - y;
	DrawOrnament(textPtr, d, ornPtr, &itemPtr->geom, &r, (double) x,
		(double) y);
    }
}

void
TkTextOrnFreeBlock(textPtr, listPtr)
    TkText *textPtr;
    TkTextBlockOrns *listPtr;
{
    int i;

    if (listPtr == NULL) {
	return;
    }
    for (i = 0; i < listPtr->num; i++) {
	if (listPtr->items[i].owned) {
	    FreeOrnament(textPtr, listPtr->items[i].ornPtr);
	}
	FreeGeom(&listPtr->items[i].geom);
    }
    if (listPtr->items != NULL) {
	ckfree((char *) listPtr->items);
    }
    TkTextOrnTemplatesRelease(textPtr, listPtr->templPtr);
    TkTextOrnTemplatesRelease(textPtr, listPtr->strokesPtr);
    ckfree((char *) listPtr);
}
