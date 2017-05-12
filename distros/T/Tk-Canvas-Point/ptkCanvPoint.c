/*
 * ptkCanvPoint.c --
 *
 *	This file implements point items for canvas widgets.
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 * Copyright (c) 2002 Slaven Rezic.
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id: ptkCanvPoint.c,v 1.6 2004/08/08 16:37:06 eserte Exp $
 */

#include "tkPort.h"
#include "tkInt.h"
#include "tkCanvases.h"

#if TCL_MAJOR_VERSION == 8 && TCL_MINOR_VERSION == 0
# undef TkStateParseProc
# define TkStateParseProc Tk_StateParseProc
# undef TkStatePrintProc
# define TkStatePrintProc Tk_StatePrintProc
# define HAS_DASH_PATCH 1
# define CONST84
# undef CONST
# define CONST
#else
# undef HAS_DASH_PATCH
#endif

/*
 * The structure below defines the record for each point item.
 */

typedef struct PointItem  {
    Tk_Item header;		/* Generic stuff that's the same for all
				 * types.  MUST BE FIRST IN STRUCTURE. */
    Tk_Outline outline;		/* Outline structure */
    int capStyle;		/* Cap style for point. */
    double x, y;		/* X- and y-coord of point */
} PointItem;

/*
 * Prototypes for procedures defined in this file:
 */

static void		ComputePointBbox _ANSI_ARGS_((Tk_Canvas canvas,
			    PointItem *pointPtr));
static int		ConfigurePoint _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr, int argc,
			    CONST84 Tcl_Obj *CONST *objv, int flags));
static int		CreatePoint _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, struct Tk_Item *itemPtr,
			    int argc, CONST84 Tcl_Obj *CONST *objv));
static void		DeletePoint _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, Display *display));
static void		DisplayPoint _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, Display *display, Drawable dst,
			    int x, int y, int width, int height));
static int		GetPointIndex _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr,
			    Tcl_Obj *obj, int *indexPtr));
static int		PointCoords _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr,
			    int argc, CONST84 Tcl_Obj *CONST *objv));
static int		PointToArea _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double *rectPtr));
static double		PointToPoint _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double *coordPtr));
static int		PointToPostscript _ANSI_ARGS_((Tcl_Interp *interp,
			    Tk_Canvas canvas, Tk_Item *itemPtr, int prepass));
static void		ScalePoint _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double originX, double originY,
			    double scaleX, double scaleY));
static void		TranslatePoint _ANSI_ARGS_((Tk_Canvas canvas,
			    Tk_Item *itemPtr, double deltaX, double deltaY));

/*
 * Information used for parsing configuration specs.  If you change any
 * of the default strings, be sure to change the corresponding default
 * values in CreatePoint.
 */

static Tk_CustomOption stateOption = {
    TkStateParseProc,
    TkStatePrintProc, (ClientData) 2
};
static Tk_CustomOption tagsOption = {
    Tk_CanvasTagsParseProc,
    Tk_CanvasTagsPrintProc, (ClientData) NULL
};
static Tk_CustomOption tileOption = {
    Tk_TileParseProc,
    Tk_TilePrintProc, (ClientData) NULL
};
static Tk_CustomOption offsetOption = {
    Tk_OffsetParseProc,
    Tk_OffsetPrintProc,
    (ClientData) (TK_OFFSET_RELATIVE|TK_OFFSET_INDEX)
};
static Tk_CustomOption pixelOption = {
    Tk_PixelParseProc,
    Tk_PixelPrintProc, (ClientData) NULL
};

static Tk_ConfigSpec configSpecs[] = {
    {TK_CONFIG_COLOR, "-activefill",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.activeColor),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_BITMAP, "-activestipple",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.activeStipple),
	TK_CONFIG_NULL_OK},
#ifdef HAS_DASH_PATCH
    {TK_CONFIG_CUSTOM, "-activetile",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.activeTile),
	TK_CONFIG_NULL_OK, &tileOption},
#endif
    {TK_CONFIG_CUSTOM, "-activewidth",          NULL,          NULL,
	"0.0", Tk_Offset(PointItem, outline.activeWidth),
	TK_CONFIG_DONT_SET_DEFAULT, &pixelOption},
    {TK_CONFIG_CAP_STYLE, "-capstyle",          NULL,          NULL,
	"round", Tk_Offset(PointItem, capStyle), TK_CONFIG_DONT_SET_DEFAULT},
    {TK_CONFIG_COLOR, "-fill",          NULL,          NULL,
	"black", Tk_Offset(PointItem, outline.color), TK_CONFIG_NULL_OK},
    {TK_CONFIG_COLOR, "-disabledfill",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.disabledColor),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_BITMAP, "-disabledstipple",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.disabledStipple),
	TK_CONFIG_NULL_OK},
#ifdef HAS_DASH_PATCH
    {TK_CONFIG_CUSTOM, "-disabledtile",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.disabledTile),
	TK_CONFIG_NULL_OK, &tileOption},
#endif
    {TK_CONFIG_CUSTOM, "-disabledwidth",          NULL,          NULL,
	"0.0", Tk_Offset(PointItem, outline.disabledWidth),
	TK_CONFIG_DONT_SET_DEFAULT, &pixelOption},
    {TK_CONFIG_CUSTOM, "-offset",          NULL,          NULL,
	"0 0", Tk_Offset(PointItem, outline.tsoffset),
	TK_CONFIG_DONT_SET_DEFAULT, &offsetOption},
    {TK_CONFIG_CUSTOM, "-state",          NULL,          NULL,
	         NULL, Tk_Offset(Tk_Item, state), TK_CONFIG_NULL_OK,
	&stateOption},
    {TK_CONFIG_BITMAP, "-stipple",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.stipple),
	TK_CONFIG_NULL_OK},
    {TK_CONFIG_CUSTOM, "-tags",          NULL,          NULL,
	         NULL, 0, TK_CONFIG_NULL_OK, &tagsOption},
#ifdef HAS_DASH_PATCH
    {TK_CONFIG_CUSTOM, "-tile",          NULL,          NULL,
	         NULL, Tk_Offset(PointItem, outline.tile),
	TK_CONFIG_NULL_OK, &tileOption},
#endif
    {TK_CONFIG_CUSTOM, "-width",          NULL,          NULL,
	"1.0", Tk_Offset(PointItem, outline.width),
	TK_CONFIG_DONT_SET_DEFAULT, &pixelOption},
    {TK_CONFIG_CALLBACK, "-updatecommand",          NULL,          NULL,
	         NULL, Tk_Offset(Tk_Item, updateCmd), TK_CONFIG_NULL_OK},
    {TK_CONFIG_END,          NULL,          NULL,          NULL,
	         NULL, 0, 0}
};

/*
 * The structures below defines the line item type by means
 * of procedures that can be invoked by generic item code.
 */

Tk_ItemType ptkCanvPointType = {
    "point",				/* name */
    sizeof(PointItem),			/* itemSize */
    CreatePoint,			/* createProc */
    configSpecs,			/* configSpecs */
    ConfigurePoint,			/* configureProc */
    PointCoords,			/* coordProc */
    DeletePoint,			/* deleteProc */
    DisplayPoint,			/* displayProc */
    TK_CONFIG_OBJS,			/* flags, no TK_ITEM_VISITOR_SUPPORT */
    PointToPoint,			/* pointProc */
    PointToArea,			/* areaProc */
    PointToPostscript,			/* postscriptProc */
    ScalePoint,				/* scaleProc */
    TranslatePoint,			/* translateProc */
NULL,//    GetPointIndex,			/* indexProc */
    (Tk_ItemCursorProc *) NULL,		/* icursorProc */
    (Tk_ItemSelectionProc *) NULL,	/* selectionProc */
    (Tk_ItemInsertProc *) NULL,		/* insertProc */
    (Tk_ItemDCharsProc *) NULL,		/* dTextProc */
    (Tk_ItemType *) NULL,		/* nextPtr */
    (Tk_ItemBboxProc *) ComputePointBbox,/* bboxProc */
    (Tk_VisitorItemProc *) NULL,	/* acceptProc */
    (Tk_ItemGetCoordProc *) NULL,	/* getCoordProc */
    (Tk_ItemSetCoordProc *) NULL	/* setCoordProc */
};

/*
 *--------------------------------------------------------------
 *
 * CreatePoint --
 *
 *	This procedure is invoked to create a new point item in
 *	a canvas.
 *
 * Results:
 *	A standard Tcl return value.  If an error occurred in
 *	creating the item, then an error message is left in
 *	Tcl_GetResult(interp);  in this case itemPtr is left uninitialized,
 *	so it can be safely freed by the caller.
 *
 * Side effects:
 *	A new point item is created.
 *
 *--------------------------------------------------------------
 */

static int
CreatePoint(interp, canvas, itemPtr, argc, objv)
    Tcl_Interp *interp;			/* Interpreter for error reporting. */
    Tk_Canvas canvas;			/* Canvas to hold new item. */
    Tk_Item *itemPtr;			/* Record to hold new item;  header
					 * has been initialized by caller. */
    int argc;				/* Number of arguments in objv. */
    CONST84 Tcl_Obj *CONST *objv;	/* Arguments describing point. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;
    int i;

    /*
     * Carry out initialization that is needed to set defaults and to
     * allow proper cleanup after errors during the the remainder of
     * this procedure.
     */

    Tk_CreateOutline(&(pointPtr->outline));
    pointPtr->capStyle = CapRound;

    /*
     * Count the number of points and then parse them into a point
     * array.  Leading arguments are assumed to be points if they
     * start with a digit or a minus sign followed by a digit.
     */

    for (i = 0; i < argc; i++) {
	char *arg = Tcl_GetStringFromObj(objv[i], NULL);
	if ((arg[0] == '-') && (arg[1] >= 'a')
		&& (arg[1] <= 'z')) {
	    break;
	}
    }
    if (i && (PointCoords(interp, canvas, itemPtr, i, objv) != TCL_OK)) {
	goto error;
    }
    if (ConfigurePoint(interp, canvas, itemPtr, argc-i, objv+i, 0) == TCL_OK) {
	return TCL_OK;
    }

    error:
    DeletePoint(canvas, itemPtr, Tk_Display(Tk_CanvasTkwin(canvas)));
    return TCL_ERROR;
}

/*
 *--------------------------------------------------------------
 *
 * PointCoords --
 *
 *	This procedure is invoked to process the "coords" widget
 *	command on points.  See the user documentation for details
 *	on what it does.
 *
 * Results:
 *	Returns TCL_OK or TCL_ERROR, and sets Tcl_GetResult(interp).
 *
 * Side effects:
 *	The coordinates for the given item may be changed.
 *
 *--------------------------------------------------------------
 */

static int
PointCoords(interp, canvas, itemPtr, argc, objv)
    Tcl_Interp *interp;			/* Used for error reporting. */
    Tk_Canvas canvas;			/* Canvas containing item. */
    Tk_Item *itemPtr;			/* Item whose coordinates are to be
					 * read or modified. */
    int argc;				/* Number of coordinates supplied in
					 * objv. Should be 2. */
    CONST84 Tcl_Obj *CONST *objv;	/* Array of coordinates: x1, y1,
					 * x2, y2, ... */
{
    PointItem *pointPtr = (PointItem *) itemPtr;

    if (argc == 0) {
	Tcl_Obj *subobj, *obj = Tcl_NewObj();
	subobj = Tcl_NewDoubleObj(pointPtr->x);
	Tcl_ListObjAppendElement(interp, obj, subobj);
	subobj = Tcl_NewDoubleObj(pointPtr->y);
	Tcl_ListObjAppendElement(interp, obj, subobj);
	Tcl_SetObjResult(interp, obj);
	return TCL_OK;
    }
    //XXX kann weg?
/*      if (argc == 1) { */
/*  	if (Tcl_ListObjGetElements(interp, objv[0], &argc, &objv) != TCL_OK) { */
/*  	    return TCL_ERROR; */
/*  	} */
/*      } */
    if (argc != 2) {
	Tcl_AppendResult(interp,
		"not two coordinates specified for point",
		         NULL);
	return TCL_ERROR;
    } else {
	if (Tk_CanvasGetCoordFromObj(interp, canvas, objv[0],
				     &(pointPtr->x)) != TCL_OK) {
	    return TCL_ERROR;
	}
	if (Tk_CanvasGetCoordFromObj(interp, canvas, objv[1],
				     &(pointPtr->y)) != TCL_OK) {
	    return TCL_ERROR;
	}

	ComputePointBbox(canvas, pointPtr);
    }
    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * ConfigurePoint --
 *
 *	This procedure is invoked to configure various aspects
 *	of a point item such as its background color.
 *
 * Results:
 *	A standard Tcl result code.  If an error occurs, then
 *	an error message is left in Tcl_GetResult(interp).
 *
 * Side effects:
 *	Configuration information, such as colors and stipple
 *	patterns, may be set for itemPtr.
 *
 *--------------------------------------------------------------
 */

static int
ConfigurePoint(interp, canvas, itemPtr, argc, objv, flags)
    Tcl_Interp *interp;		/* Used for error reporting. */
    Tk_Canvas canvas;		/* Canvas containing itemPtr. */
    Tk_Item *itemPtr;		/* Point item to reconfigure. */
    int argc;			/* Number of elements in objv.  */
    CONST84 Tcl_Obj *CONST *objv;	/* Arguments describing things to configure. */
    int flags;			/* Flags to pass to Tk_ConfigureWidget. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;
    XGCValues gcValues;
    GC newGC;
    unsigned long mask;
    Tk_Window tkwin;
    Tk_State state;

    tkwin = Tk_CanvasTkwin(canvas);
    if (Tk_ConfigureWidget(interp, tkwin, configSpecs, argc, objv,
	    (char *) pointPtr, flags|TK_CONFIG_OBJS) != TCL_OK) {
	return TCL_ERROR;
    }

    /*
     * A few of the options require additional processing, such as
     * graphics contexts.
     */

    state = Tk_GetItemState(canvas, itemPtr);

    if (pointPtr->outline.activeWidth > pointPtr->outline.width ||
#ifdef HAS_DASH_PATCH
	    pointPtr->outline.activeTile != None ||
#endif
	    pointPtr->outline.activeColor != NULL ||
	    pointPtr->outline.activeStipple != None) {
	itemPtr->redraw_flags |= TK_ITEM_STATE_DEPENDANT;
    } else {
	itemPtr->redraw_flags &= ~TK_ITEM_STATE_DEPENDANT;
    }
    mask = Tk_ConfigOutlineGC(&gcValues, canvas, itemPtr,
	    &(pointPtr->outline));
    if (mask) {
	gcValues.cap_style = pointPtr->capStyle;
	mask |= GCCapStyle;
	newGC = Tk_GetGC(tkwin, mask, &gcValues);
	gcValues.line_width = 0;
    } else {
	newGC = None;
    }
    if (pointPtr->outline.gc != None) {
	Tk_FreeGC(Tk_Display(tkwin), pointPtr->outline.gc);
    }
    pointPtr->outline.gc = newGC;

    /*
     * Recompute bounding box for point.
     */

    ComputePointBbox(canvas, pointPtr);

    return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * DeletePoint --
 *
 *	This procedure is called to clean up the data structure
 *	associated with a point item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Resources associated with itemPtr are released.
 *
 *--------------------------------------------------------------
 */

static void
DeletePoint(canvas, itemPtr, display)
    Tk_Canvas canvas;			/* Info about overall canvas widget. */
    Tk_Item *itemPtr;			/* Item that is being deleted. */
    Display *display;			/* Display containing window for
					 * canvas. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;

    Tk_DeleteOutline(display, &(pointPtr->outline));
}

/*
 *--------------------------------------------------------------
 *
 * ComputePointBbox --
 *
 *	This procedure is invoked to compute the bounding box of
 *	all the pixels that may be drawn as part of a point.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The fields x1, y1, x2, and y2 are updated in the header
 *	for itemPtr.
 *
 *--------------------------------------------------------------
 */

static void
ComputePointBbox(canvas, pointPtr)
    Tk_Canvas canvas;			/* Canvas that contains item. */
    PointItem *pointPtr;		/* Item whose bbox is to be
					 * recomputed. */
{
    int intWidth;
    double width;
    Tk_State state = Tk_GetItemState(canvas, &pointPtr->header);
    Tk_TSOffset *tsoffset;

    if (state==TK_STATE_HIDDEN) {
	pointPtr->header.x1 = -1;
	pointPtr->header.x2 = -1;
	pointPtr->header.y1 = -1;
	pointPtr->header.y2 = -1;
	return;
    }

    width = pointPtr->outline.width;
    if (((TkCanvas *)canvas)->currentItemPtr == (Tk_Item *)pointPtr) {
	if (pointPtr->outline.activeWidth>width) {
	    width = pointPtr->outline.activeWidth;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (pointPtr->outline.disabledWidth>0) {
	    width = pointPtr->outline.disabledWidth;
	}
    }

    pointPtr->header.x1 = pointPtr->header.x2 = (int) pointPtr->x;
    pointPtr->header.y1 = pointPtr->header.y2 = (int) pointPtr->y;

    if (width < 1.0) {
	width = 1.0;
    }

    intWidth = (int) (width + 0.5);
    pointPtr->header.x1 -= intWidth - 1;
    pointPtr->header.x2 += intWidth + 1;
    pointPtr->header.y1 -= intWidth - 1;
    pointPtr->header.y2 += intWidth + 1;
}

/*
 *--------------------------------------------------------------
 *
 * DisplayPoint --
 *
 *	This procedure is invoked to draw a point item in a given
 *	drawable.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	ItemPtr is drawn in drawable using the transformation
 *	information in canvas.
 *
 *--------------------------------------------------------------
 */

static void
DisplayPoint(canvas, itemPtr, display, drawable, x, y, width, height)
    Tk_Canvas canvas;			/* Canvas that contains item. */
    Tk_Item *itemPtr;			/* Item to be displayed. */
    Display *display;			/* Display on which to draw item. */
    Drawable drawable;			/* Pixmap or window in which to draw
					 * item. */
    int x, y, width, height;		/* Describes region of canvas that
					 * must be redisplayed (not used). */
{
    PointItem *pointPtr = (PointItem *) itemPtr;
    XPoint staticPoint;
    double pointwidth;
    int intwidth;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);
#ifdef HAS_DASH_PATCH
    Tk_Tile tile = pointPtr->outline.tile;
#endif
    Pixmap stipple = pointPtr->outline.stipple;

    if (pointPtr->outline.gc==None) {
	return;
    }

    pointwidth = pointPtr->outline.width;
    if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (pointPtr->outline.activeWidth>pointwidth) {
	    pointwidth = pointPtr->outline.activeWidth;
	}
#ifdef HAS_DASH_PATCH
	if (pointPtr->outline.activeTile!=NULL) {
	    tile = pointPtr->outline.activeTile;
	}
#endif
	if (pointPtr->outline.activeStipple!=None) {
	    stipple = pointPtr->outline.activeStipple;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (pointPtr->outline.disabledWidth>pointwidth) {
	    pointwidth = pointPtr->outline.disabledWidth;
	}
#ifdef HAS_DASH_PATCH
	if (pointPtr->outline.disabledTile!=NULL) {
	    tile = pointPtr->outline.disabledTile;
	}
#endif
	if (pointPtr->outline.disabledStipple!=None) {
	    stipple = pointPtr->outline.disabledStipple;
	}
    }

    Tk_CanvasDrawableCoords(canvas, pointPtr->x, pointPtr->y,
			    &(staticPoint.x), &(staticPoint.y));

    /*
     * Display point.  If we're stippling, then modify the stipple offset
     * in the GC.  Be sure to reset the offset when done, since the
     * GC is supposed to be read-only.
     */

    //XXX heißt das, stipple etc. wird bei lines eh nur im arrow gemalt?
/*      if (Tk_ChangeOutlineGC(canvas, itemPtr, &(pointPtr->outline))) { */
/*  	Tk_CanvasSetOffset(canvas, pointPtr->arrowGC, &pointPtr->outline.tsoffset); */
/*      } */
    intwidth = (int) (pointwidth + 0.5);
    XFillArc(display, drawable, pointPtr->outline.gc, staticPoint.x - intwidth/2,
	     staticPoint.y - intwidth/2, intwidth+1, intwidth+1, 0, 64*360);
}

/*
 *--------------------------------------------------------------
 *
 * PointToPoint --
 *
 *	Computes the distance from a given point to another given
 *	point, in canvas units.
 *
 * Results:
 *	The return value is 0 if the point whose x and y coordinates
 *	are pointPtr[0] and pointPtr[1] is inside the point.  If the
 *	point isn't inside the point then the return value is the
 *	distance from the point to the other point.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static double
PointToPoint(canvas, itemPtr, otherPointPtr)
    Tk_Canvas canvas;		/* Canvas containing item. */
    Tk_Item *itemPtr;		/* Item to check against point. */
    double *otherPointPtr;	/* Pointer to x and y coordinates. */
{
    Tk_State state = Tk_GetItemState(canvas, itemPtr);
    PointItem *pointPtr = (PointItem *) itemPtr;
    double bestDist, width;

    bestDist = 1.0e36;

    width = pointPtr->outline.width;
    if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (pointPtr->outline.activeWidth>width) {
	    width = pointPtr->outline.activeWidth;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (pointPtr->outline.disabledWidth>0) {
	    width = pointPtr->outline.disabledWidth;
	}
    }

    if (width < 1.0) {
	width = 1.0;
    }

    if (itemPtr->state==TK_STATE_HIDDEN) {
	return bestDist;
    } else {
	bestDist = hypot(pointPtr->x - otherPointPtr[0], pointPtr->y - otherPointPtr[1])
	    - width/2.0;
	if (bestDist < 0) bestDist = 0;
	return bestDist;
    }
}

/*
 *--------------------------------------------------------------
 *
 * PointToArea --
 *
 *	This procedure is called to determine whether an item
 *	lies entirely inside, entirely outside, or overlapping
 *	a given rectangular area.
 *
 * Results:
 *	-1 is returned if the item is entirely outside the
 *	area, 0 if it overlaps, and 1 if it is entirely
 *	inside the given area.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

	/* ARGSUSED */
static int
PointToArea(canvas, itemPtr, rectPtr)
    Tk_Canvas canvas;		/* Canvas containing item. */
    Tk_Item *itemPtr;		/* Item to check against point. */
    double *rectPtr;
{
    PointItem *pointPtr = (PointItem *) itemPtr;
    double radius, width;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);

    width = pointPtr->outline.width;
    if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (pointPtr->outline.activeWidth>width) {
	    width = pointPtr->outline.activeWidth;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (pointPtr->outline.disabledWidth>0) {
	    width = pointPtr->outline.disabledWidth;
	}
    }

    radius = (width+1.0)/2.0;

    if (state==TK_STATE_HIDDEN) {
	return -1;
    } else {
	double oval[4];
	oval[0] = pointPtr->x-radius;
	oval[1] = pointPtr->y-radius;
	oval[2] = pointPtr->x+radius;
	oval[3] = pointPtr->y+radius;
	return TkOvalToArea(oval, rectPtr);
    }
}

/*
 *--------------------------------------------------------------
 *
 * ScalePoint --
 *
 *	This procedure is invoked to rescale a point item.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The point referred to by itemPtr is rescaled so that the
 *	following transformation is applied to its coordinates:
 *		x' = originX + scaleX*(x-originX)
 *		y' = originY + scaleY*(y-originY)
 *
 *--------------------------------------------------------------
 */

static void
ScalePoint(canvas, itemPtr, originX, originY, scaleX, scaleY)
    Tk_Canvas canvas;			/* Canvas containing point. */
    Tk_Item *itemPtr;			/* Point to be scaled. */
    double originX, originY;		/* Origin about which to scale rect. */
    double scaleX;			/* Amount to scale in X direction. */
    double scaleY;			/* Amount to scale in Y direction. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;

    pointPtr->x = originX + scaleX*(pointPtr->x - originX);
    pointPtr->y = originY + scaleY*(pointPtr->y - originY);
    ComputePointBbox(canvas, pointPtr);
}

#if 0
/*
 *--------------------------------------------------------------
 *
 * GetLineIndex --
 *
 *	Parse an index into a line item and return either its value
 *	or an error.
 *
 * Results:
 *	A standard Tcl result.  If all went well, then *indexPtr is
 *	filled in with the index (into itemPtr) corresponding to
 *	string.  Otherwise an error message is left in
 *	Tcl_GetResult(interp).
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
GetLineIndex(interp, canvas, itemPtr, obj, indexPtr)
    Tcl_Interp *interp;		/* Used for error reporting. */
    Tk_Canvas canvas;		/* Canvas containing item. */
    Tk_Item *itemPtr;		/* Item for which the index is being
				 * specified. */
    Tcl_Obj *obj;		/* Specification of a particular coord
				 * in itemPtr's line. */
    int *indexPtr;		/* Where to store converted index. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;
    int length;
    char *string;
    int i;
    double x ,y, bestDist, dist, *coordPtr;
    char *end, *p;
    Tcl_Obj **objv;

    if (Tcl_ListObjGetElements(interp, obj, &i, &objv) == TCL_OK && i == 2
	&& Tcl_GetDoubleFromObj(interp, objv[0], &x) == TCL_OK
	&& Tcl_GetDoubleFromObj(interp, objv[1], &y) == TCL_OK) {
	goto doxy;
    }

    string = Tcl_GetStringFromObj(obj, &length);
    if (string[0] == 'e') {
	if (strncmp(string, "end", length) == 0) {
	    *indexPtr = 2*pointPtr->numPoints;
	} else {
	    badIndex:

	    /*
	     * Some of the paths here leave messages in Tcl_GetResult(interp),
	     * so we have to clear it out before storing our own message.
	     */

	    Tcl_SetResult(interp,          NULL, TCL_STATIC);
	    Tcl_AppendResult(interp, "bad index \"", string, "\"",
		             NULL);
	    return TCL_ERROR;
	}
    } else if (string[0] == '@') {
	p = string+1;
	x = strtod(p, &end);
	if ((end == p) || (*end != ',')) {
	    goto badIndex;
	}
	p = end+1;
	y = strtod(p, &end);
	if ((end == p) || (*end != 0)) {
	    goto badIndex;
	}
     doxy:
	bestDist = 1.0e36;
	coordPtr = pointPtr->coordPtr;
	*indexPtr = 0;
	for(i=0; i<pointPtr->numPoints; i++) {
	    dist = hypot(coordPtr[0] - x, coordPtr[1] - y);
	    if (dist<bestDist) {
		bestDist = dist;
		*indexPtr = 2*i;
	    }
	    coordPtr += 2;
	}
    } else {
	if (Tcl_GetIntFromObj(interp, obj, indexPtr) != TCL_OK) {
	    goto badIndex;
	}
	*indexPtr &= -2; /* if index is odd, make it even */
	if (*indexPtr < 0){
	    *indexPtr = 0;
	} else if (*indexPtr > (2*pointPtr->numPoints)) {
	    *indexPtr = (2*pointPtr->numPoints);
	}
    }
    return TCL_OK;
}
#endif

/*
 *--------------------------------------------------------------
 *
 * TranslatePoint --
 *
 *	This procedure is called to move a point by a given amount.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The position of the point is offset by (xDelta, yDelta), and
 *	the bounding box is updated in the generic part of the item
 *	structure.
 *
 *--------------------------------------------------------------
 */

static void
TranslatePoint(canvas, itemPtr, deltaX, deltaY)
    Tk_Canvas canvas;			/* Canvas containing item. */
    Tk_Item *itemPtr;			/* Item that is being moved. */
    double deltaX, deltaY;		/* Amount by which item is to be
					 * moved. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;

    pointPtr->x += deltaX;
    pointPtr->y += deltaY;

    ComputePointBbox(canvas, pointPtr);
}

/*
 *--------------------------------------------------------------
 *
 * PointToPostscript --
 *
 *	This procedure is called to generate Postscript for
 *	point items.
 *
 * Results:
 *	The return value is a standard Tcl result.  If an error
 *	occurs in generating Postscript then an error message is
 *	left in Tcl_GetResult(interp), replacing whatever used
 *	to be there.  If no error occurs, then Postscript for the
 *	item is appended to the result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */

static int
PointToPostscript(interp, canvas, itemPtr, prepass)
    Tcl_Interp *interp;			/* Leave Postscript or error message
					 * here. */
    Tk_Canvas canvas;			/* Information about overall canvas. */
    Tk_Item *itemPtr;			/* Item for which Postscript is
					 * wanted. */
    int prepass;			/* 1 means this is a prepass to
					 * collect font information;  0 means
					 * final Postscript is being created. */
{
    PointItem *pointPtr = (PointItem *) itemPtr;
    char buffer[200];
    char *style;

    double width;
    XColor *color;
    Pixmap stipple;
    Tk_State state = Tk_GetItemState(canvas, itemPtr);

    width = pointPtr->outline.width;
    color = pointPtr->outline.color;
    stipple = pointPtr->outline.stipple;
    if (((TkCanvas *)canvas)->currentItemPtr == itemPtr) {
	if (pointPtr->outline.activeWidth>width) {
	    width = pointPtr->outline.activeWidth;
	}
	if (pointPtr->outline.activeColor!=NULL) {
	    color = pointPtr->outline.activeColor;
	}
	if (pointPtr->outline.activeStipple!=None) {
	    stipple = pointPtr->outline.activeStipple;
	}
    } else if (state==TK_STATE_DISABLED) {
	if (pointPtr->outline.disabledWidth>0) {
	    width = pointPtr->outline.disabledWidth;
	}
	if (pointPtr->outline.disabledColor!=NULL) {
	    color = pointPtr->outline.disabledColor;
	}
	if (pointPtr->outline.disabledStipple!=None) {
	    stipple = pointPtr->outline.disabledStipple;
	}
    }

    if (color == NULL) {
	return TCL_OK;
    }

    sprintf(buffer, "%.15g %.15g translate %.15g %.15g",
	    pointPtr->x, Tk_CanvasPsY(canvas, pointPtr->y),
	    width/2.0, width/2.0);
    Tcl_AppendResult(interp, "matrix currentmatrix\n",buffer,
		     " scale 1 0 moveto 0 0 1 0 360 arc\nsetmatrix\n",
		     NULL);
    if (Tk_CanvasPsColor(interp, canvas, color) != TCL_OK) {
	return TCL_ERROR;
    }
    if (stipple != None) {
	Tcl_AppendResult(interp, "clip ",          NULL);
	if (Tk_CanvasPsStipple(interp, canvas, stipple) != TCL_OK) {
	    return TCL_ERROR;
	}
    } else {
	Tcl_AppendResult(interp, "fill\n",          NULL);
    }
    return TCL_OK;
}

/* Local variables: */
/* c-basic-offset: 4 */
/* End. */
