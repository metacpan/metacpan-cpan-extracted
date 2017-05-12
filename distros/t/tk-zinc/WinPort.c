/*
 * WinPort.c -- Compatibility layer for Windows 2k
 *
 * Authors		: Patrick Lecoanet.
 * Creation date	:
 *
 * $Id: WinPort.c,v 1.7 2005/04/27 08:02:42 lecoanet Exp $
 */

/*
 *  Copyright (c) 2003 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifdef _WIN32

#include "Types.h"

#include <tkInt.h>
#include <tkWinInt.h>
#ifdef PTK
#include <tkIntPlatDecls.m>
#endif

static const char rcsid[] = "$Id";
static const char compile_id[]="$Compile$";

#ifndef MIN
#define MIN(a, b) 	((a) <= (b) ? (a) : (b))
#endif
#ifndef MAX
#define MAX(a, b) 	((a) >= (b) ? (a) : (b))
#endif


/*
 *----------------------------------------------------------------------
 *
 * ZnPointInRegion --
 *
 *	Test whether the specified point is inside a region.
 *
 * Results:
 *	Returns the boolean result of the test.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
int
ZnPointInRegion(TkRegion reg,
		int	 x,
		int	 y)
{
  return PtInRegion((HRGN) reg, x, y);
}

/*
 *----------------------------------------------------------------------
 *
 * ZnUnionRegion --
 *
 *	Compute the union of two regions.
 *
 * Results:
 *	Returns the result in the dr_return region.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
void
ZnUnionRegion(TkRegion	sra,
	      TkRegion	srb,
	      TkRegion	dr_return)
{
  CombineRgn((HRGN) dr_return, (HRGN) sra, (HRGN) srb, RGN_OR);
}

/*
 *----------------------------------------------------------------------
 *
 * ZnOffsetRegion --
 *
 *	Offset a region by the specified pixel offsets.
 *
 * Results:
 *	Returns the result in the dr_return region.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
void
ZnOffsetRegion(TkRegion	reg,
	       int	dx,
	       int	dy)
{
  OffsetRgn((HRGN) reg, dx, dy);
}

/*
 *----------------------------------------------------------------------
 *
 * ZnPolygonRegion --
 *
 *	Compute a region from a polygon.
 *
 * Results:
 *	Returns the result in the dr_return region.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */
TkRegion
ZnPolygonRegion(XPoint	*points,
		int	n,
		int	fill_rule)
{
  POINT	*pts;
  HRGN reg;
  int	i;

  pts = (POINT *) ckalloc(n*sizeof(POINT));
  for (i = 0; i < n; i++, points++) {
    pts[i].x = points->x;
    pts[i].y = points->y;
  }

  reg = CreatePolygonRgn(pts, n,
			 fill_rule==EvenOddRule?ALTERNATE:WINDING);
  if (!reg) {
    fprintf(stderr, "Polygon region failed: %ld, n: %d\n", GetLastError(), n);
  }
  ckfree((char *) pts);
  return (TkRegion) reg;
}

#define PI 3.14159265358979
#define XAngleToRadians(a) ((double)(a) / 64 * PI / 180);

/*
 * Translation table between X gc functions and Win32 raster op modes.
 */

int tkpWinRopModes[] = {
    R2_BLACK,			/* GXclear */
    R2_MASKPEN,			/* GXand */
    R2_MASKPENNOT,		/* GXandReverse */
    R2_COPYPEN,			/* GXcopy */
    R2_MASKNOTPEN,		/* GXandInverted */
    R2_NOT,			/* GXnoop */
    R2_XORPEN,			/* GXxor */
    R2_MERGEPEN,		/* GXor */
    R2_NOTMERGEPEN,		/* GXnor */
    R2_NOTXORPEN,		/* GXequiv */
    R2_NOT,			/* GXinvert */
    R2_MERGEPENNOT,		/* GXorReverse */
    R2_NOTCOPYPEN,		/* GXcopyInverted */
    R2_MERGENOTPEN,		/* GXorInverted */
    R2_NOTMASKPEN,		/* GXnand */
    R2_WHITE			/* GXset */
};

/*
 * The following two raster ops are used to copy the foreground and background
 * bits of a source pattern as defined by a stipple used as the pattern.
 */

#define COPYFG		0x00CA0749 /* dest = (pat & src) | (!pat & dst) */
#define COPYBG		0x00AC0744 /* dest = (!pat & src) | (pat & dst) */

/*
 * The followng typedef is used to pass Windows GDI drawing functions.
 */

typedef BOOL (CALLBACK *WinDrawFunc) _ANSI_ARGS_((HDC dc,
			    CONST POINT* points, int npoints));

typedef struct ThreadSpecificData {
    POINT *winPoints;    /* Array of points that is reused. */
    int nWinPoints;	/* Current size of point array. */
} ThreadSpecificData;
static Tcl_ThreadDataKey dataKey;

/*
 *----------------------------------------------------------------------
 *
 * SetUpGraphicsPort --
 *
 *	Set up the graphics port from the given GC.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	The current port is adjusted.
 *
 *----------------------------------------------------------------------
 */

static HPEN
SetUpGraphicsPort(gc)
    GC gc;
{
    DWORD style;

    if (gc->line_style == LineOnOffDash) {
	unsigned char *p = (unsigned char *) &(gc->dashes);
				/* pointer to the dash-list */

	/*
	 * Below is a simple translation of serveral dash patterns
	 * to valid windows pen types. Far from complete,
	 * but I don't know how to do it better.
	 * Any ideas: <mailto:j.nijtmans@chello.nl>
	 */

	if (p[1] && p[2]) {
	    if (!p[3] || p[4]) {
		style = PS_DASHDOTDOT;		/*	-..	*/
	    } else {
		style = PS_DASHDOT;		/*	-.	*/
	    }
	} else {
	    if (p[0] > (4 * gc->line_width)) {
		style = PS_DASH;		/*	-	*/
	    } else {
		style = PS_DOT;			/*	.	*/
	    }
	}
    } else {
	style = PS_SOLID;
    }
    if (gc->line_width < 2) {
	return CreatePen(style, gc->line_width, gc->foreground);
    } else {
	LOGBRUSH lb;

	lb.lbStyle = BS_SOLID;
	lb.lbColor = gc->foreground;
	lb.lbHatch = 0;

	style |= PS_GEOMETRIC;
	switch (gc->cap_style) {
	    case CapNotLast:
	    case CapButt:
		style |= PS_ENDCAP_FLAT; 
		break;
	    case CapRound:
		style |= PS_ENDCAP_ROUND; 
		break;
	    default:
		style |= PS_ENDCAP_SQUARE; 
		break;
	}
	switch (gc->join_style) {
	    case JoinMiter: 
		style |= PS_JOIN_MITER; 
		break;
	    case JoinRound:
		style |= PS_JOIN_ROUND; 
		break;
	    default:
		style |= PS_JOIN_BEVEL; 
		break;
	}
	return ExtCreatePen(style, gc->line_width, &lb, 0, NULL);
    }
}

/*
 *----------------------------------------------------------------------
 *
 * ConvertPoints --
 *
 *	Convert an array of X points to an array of Win32 points.
 *
 * Results:
 *	Returns the converted array of POINTs.
 *
 * Side effects:
 *	Allocates a block of memory in thread local storage that 
 *      should not be freed.
 *
 *----------------------------------------------------------------------
 */

static POINT *
ConvertPoints(points, npoints, mode, bbox)
    XPoint *points;
    int npoints;
    int mode;			/* CoordModeOrigin or CoordModePrevious. */
    RECT *bbox;			/* Bounding box of points. */
{
    ThreadSpecificData *tsdPtr = (ThreadSpecificData *) 
            Tcl_GetThreadData(&dataKey, sizeof(ThreadSpecificData));
    int i;

    /*
     * To avoid paying the cost of a malloc on every drawing routine,
     * we reuse the last array if it is large enough.
     */

    if (npoints > tsdPtr->nWinPoints) {
	if (tsdPtr->winPoints != NULL) {
	    ckfree((char *) tsdPtr->winPoints);
	}
	tsdPtr->winPoints = (POINT *) ckalloc(sizeof(POINT) * npoints);
	if (tsdPtr->winPoints == NULL) {
	    tsdPtr->nWinPoints = -1;
	    return NULL;
	}
	tsdPtr->nWinPoints = npoints;
    }

    bbox->left = bbox->right = points[0].x;
    bbox->top = bbox->bottom = points[0].y;
    
    if (mode == CoordModeOrigin) {
	for (i = 0; i < npoints; i++) {
	    tsdPtr->winPoints[i].x = points[i].x;
	    tsdPtr->winPoints[i].y = points[i].y;
	    bbox->left = MIN(bbox->left, tsdPtr->winPoints[i].x);
	    bbox->right = MAX(bbox->right, tsdPtr->winPoints[i].x);
	    bbox->top = MIN(bbox->top, tsdPtr->winPoints[i].y);
	    bbox->bottom = MAX(bbox->bottom, tsdPtr->winPoints[i].y);
	}
    } else {
	tsdPtr->winPoints[0].x = points[0].x;
	tsdPtr->winPoints[0].y = points[0].y;
	for (i = 1; i < npoints; i++) {
	    tsdPtr->winPoints[i].x = tsdPtr->winPoints[i-1].x + points[i].x;
	    tsdPtr->winPoints[i].y = tsdPtr->winPoints[i-1].y + points[i].y;
	    bbox->left = MIN(bbox->left, tsdPtr->winPoints[i].x);
	    bbox->right = MAX(bbox->right, tsdPtr->winPoints[i].x);
	    bbox->top = MIN(bbox->top, tsdPtr->winPoints[i].y);
	    bbox->bottom = MAX(bbox->bottom, tsdPtr->winPoints[i].y);
	}
    }
    return tsdPtr->winPoints;
}

/*
 *----------------------------------------------------------------------
 *
 * XFillRectangles --
 *
 *	Fill multiple rectangular areas in the given drawable.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Draws onto the specified drawable.
 *
 *----------------------------------------------------------------------
 */
void
XFillRectangles(display, d, gc, rectangles, nrectangles)
    Display* display;
    Drawable d;
    GC gc;
    XRectangle* rectangles;
    int nrectangles;
{
    HDC dc;
    int i;
    RECT rect;
    TkWinDCState state;
    HBRUSH brush;
    TkpClipMask *clipPtr = (TkpClipMask*)gc->clip_mask;

    if (d == None) {
	return;
    }

    dc = TkWinGetDrawableDC(display, d, &state);
    SetROP2(dc, tkpWinRopModes[gc->function]);
    brush = CreateSolidBrush(gc->foreground);

    if (clipPtr && clipPtr->type == TKP_CLIP_REGION) {
	SelectClipRgn(dc, (HRGN) clipPtr->value.region);
	OffsetClipRgn(dc, gc->clip_x_origin, gc->clip_y_origin);
    }
    if ((gc->fill_style == FillStippled
	    || gc->fill_style == FillOpaqueStippled)
	    && gc->stipple != None) {
	TkWinDrawable *twdPtr = (TkWinDrawable *)gc->stipple;
	HBRUSH oldBrush, stipple;
	HBITMAP oldBitmap, bitmap;
	HDC dcMem;
	HBRUSH bgBrush = CreateSolidBrush(gc->background);

	if (twdPtr->type != TWD_BITMAP) {
	    Tcl_Panic("unexpected drawable type in stipple");
	}

	/*
	 * Select stipple pattern into destination dc.
	 */
	
	stipple = CreatePatternBrush(twdPtr->bitmap.handle);
	SetBrushOrgEx(dc, gc->ts_x_origin, gc->ts_y_origin, NULL);
	oldBrush = SelectObject(dc, stipple);
	dcMem = CreateCompatibleDC(dc);

	/*
	 * For each rectangle, create a drawing surface which is the size of
	 * the rectangle and fill it with the background color.  Then merge the
	 * result with the stipple pattern.
	 */
	for (i = 0; i < nrectangles; i++) {
	    bitmap = CreateCompatibleBitmap(dc, rectangles[i].width,
		    rectangles[i].height);
	    oldBitmap = SelectObject(dcMem, bitmap);
	    rect.left = 0;
	    rect.top = 0;
	    rect.right = rectangles[i].width;
	    rect.bottom = rectangles[i].height;
	    FillRect(dcMem, &rect, brush);
	    BitBlt(dc, rectangles[i].x, rectangles[i].y, rectangles[i].width,
		    rectangles[i].height, dcMem, 0, 0, COPYFG);
	    if (gc->fill_style == FillOpaqueStippled) {
		FillRect(dcMem, &rect, bgBrush);
		BitBlt(dc, rectangles[i].x, rectangles[i].y,
			rectangles[i].width, rectangles[i].height, dcMem,
			0, 0, COPYBG);
	    }
	    SelectObject(dcMem, oldBitmap);
	    DeleteObject(bitmap);
	}
	
	DeleteDC(dcMem);
	SelectObject(dc, oldBrush);
	DeleteObject(stipple);
	DeleteObject(bgBrush);
    } else {
	for (i = 0; i < nrectangles; i++) {
	    TkWinFillRect(dc, rectangles[i].x, rectangles[i].y,
		    rectangles[i].width, rectangles[i].height, gc->foreground);
	}
    }
    DeleteObject(brush);
    TkWinReleaseDrawableDC(d, dc, &state);
}


/*
 *----------------------------------------------------------------------
 *
 * XFillRectangle --
 *
 *	Fills a rectangular area in the given drawable.  This procedure
 *	is implemented as a call to XFillRectangles.
 *
 * Results:
 *	None
 *
 * Side effects:
 *	Fills the specified rectangle.
 *
 *----------------------------------------------------------------------
 */

void
XFillRectangle(display, d, gc, x, y, width, height)
    Display* display;
    Drawable d;
    GC gc;
    int x;
    int y;
    unsigned int width;
    unsigned int height;
{
    XRectangle rectangle;
    rectangle.x = x;
    rectangle.y = y;
    rectangle.width = width;
    rectangle.height = height;
    XFillRectangles(display, d, gc, &rectangle, 1);
}

/*
 *----------------------------------------------------------------------
 *
 * RenderObject --
 *
 *	This function draws a shape using a list of points, a
 *	stipple pattern, and the specified drawing function.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	None.
 *
 *----------------------------------------------------------------------
 */

static void
RenderObject(dc, gc, points, npoints, mode, pen, func)
    HDC dc;
    GC gc;
    XPoint* points;
    int npoints;
    int mode;
    HPEN pen;
    WinDrawFunc func;
{
    RECT rect;
    HPEN oldPen;
    HBRUSH oldBrush;
    POINT *winPoints = ConvertPoints(points, npoints, mode, &rect);
    TkpClipMask *clipPtr = (TkpClipMask*)gc->clip_mask;
    
    if (clipPtr && clipPtr->type == TKP_CLIP_REGION) {
	SelectClipRgn(dc, (HRGN) clipPtr->value.region);
	OffsetClipRgn(dc, gc->clip_x_origin, gc->clip_y_origin);
    }
    if ((gc->fill_style == FillStippled
	    || gc->fill_style == FillOpaqueStippled)
	    && gc->stipple != None) {

	TkWinDrawable *twdPtr = (TkWinDrawable *)gc->stipple;
	HDC dcMem;
	LONG width, height;
	HBITMAP oldBitmap;
	int i;
	HBRUSH oldMemBrush;
	
	if (twdPtr->type != TWD_BITMAP) {
	    Tcl_Panic("unexpected drawable type in stipple");
	}

	/*
	 * Grow the bounding box enough to account for line width.
	 */

	rect.left -= gc->line_width;
	rect.top -= gc->line_width;
	rect.right += gc->line_width;
	rect.bottom += gc->line_width;

	width = rect.right - rect.left;
	height = rect.bottom - rect.top;

	/*
	 * Select stipple pattern into destination dc.
	 */
	
	SetBrushOrgEx(dc, gc->ts_x_origin, gc->ts_y_origin, NULL);
	oldBrush = SelectObject(dc, CreatePatternBrush(twdPtr->bitmap.handle));

	/*
	 * Create temporary drawing surface containing a copy of the
	 * destination equal in size to the bounding box of the object.
	 */
	
	dcMem = CreateCompatibleDC(dc);
	oldBitmap = SelectObject(dcMem, CreateCompatibleBitmap(dc, width,
		height));
	oldPen = SelectObject(dcMem, pen);
	BitBlt(dcMem, 0, 0, width, height, dc, rect.left, rect.top, SRCCOPY);

	/*
	 * Translate the object for rendering in the temporary drawing
	 * surface. 
	 */

	for (i = 0; i < npoints; i++) {
	    winPoints[i].x -= rect.left;
	    winPoints[i].y -= rect.top;
	}

	/*
	 * Draw the object in the foreground color and copy it to the
	 * destination wherever the pattern is set.
	 */

	SetPolyFillMode(dcMem, (gc->fill_rule == EvenOddRule) ? ALTERNATE
		: WINDING);
	oldMemBrush = SelectObject(dcMem, CreateSolidBrush(gc->foreground));
	(*func)(dcMem, winPoints, npoints);
	BitBlt(dc, rect.left, rect.top, width, height, dcMem, 0, 0, COPYFG);

	/*
	 * If we are rendering an opaque stipple, then draw the polygon in the
	 * background color and copy it to the destination wherever the pattern
	 * is clear.
	 */

	if (gc->fill_style == FillOpaqueStippled) {
	    DeleteObject(SelectObject(dcMem,
		    CreateSolidBrush(gc->background)));
	    (*func)(dcMem, winPoints, npoints);
	    BitBlt(dc, rect.left, rect.top, width, height, dcMem, 0, 0,
		    COPYBG);
	}

	SelectObject(dcMem, oldPen);
	DeleteObject(SelectObject(dcMem, oldMemBrush));
	DeleteObject(SelectObject(dcMem, oldBitmap));
	DeleteDC(dcMem);
    } else {
	oldPen = SelectObject(dc, pen);
	oldBrush = SelectObject(dc, CreateSolidBrush(gc->foreground));
	SetROP2(dc, tkpWinRopModes[gc->function]);

	SetPolyFillMode(dc, (gc->fill_rule == EvenOddRule) ? ALTERNATE
		: WINDING);

	(*func)(dc, winPoints, npoints);

	SelectObject(dc, oldPen);
    }
    DeleteObject(SelectObject(dc, oldBrush));
}

/*
 *----------------------------------------------------------------------
 *
 * XDrawLines --
 *
 *	Draw connected lines.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Renders a series of connected lines.
 *
 *----------------------------------------------------------------------
 */

void
XDrawLines(display, d, gc, points, npoints, mode)
    Display* display;
    Drawable d;
    GC gc;
    XPoint* points;
    int npoints;
    int mode;
{
    HPEN pen;
    TkWinDCState state;
    HDC dc;
    TkpClipMask *clipPtr = (TkpClipMask*)gc->clip_mask;
    
    if (d == None) {
	return;
    }

    dc = TkWinGetDrawableDC(display, d, &state);

    if (clipPtr && clipPtr->type == TKP_CLIP_REGION) {
	SelectClipRgn(dc, (HRGN) clipPtr->value.region);
	OffsetClipRgn(dc, gc->clip_x_origin, gc->clip_y_origin);
    }
    pen = SetUpGraphicsPort(gc);
    SetBkMode(dc, TRANSPARENT);
    RenderObject(dc, gc, points, npoints, mode, pen, Polyline);
    DeleteObject(pen);
    
    TkWinReleaseDrawableDC(d, dc, &state);
}

/*
 *----------------------------------------------------------------------
 *
 * XDrawLine --
 *
 *	Draw a single line between two points in a given drawable. 
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Draws a single line segment.
 *
 *----------------------------------------------------------------------
 */

void
XDrawLine(display, d, gc, x1, y1, x2, y2)
    Display* display;
    Drawable d;
    GC gc;
    int x1, y1, x2, y2;		/* Coordinates of line segment. */
{
    XPoint points[2];

    points[0].x = x1;
    points[0].y = y1;
    points[1].x = x2;
    points[1].y = y2;
    XDrawLines(display, d, gc, points, 2, CoordModeOrigin);
}

/*
 *----------------------------------------------------------------------
 *
 * XFillPolygon --
 *
 *	Draws a filled polygon.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Draws a filled polygon on the specified drawable.
 *
 *----------------------------------------------------------------------
 */

void
XFillPolygon(display, d, gc, points, npoints, shape, mode)
    Display* display;
    Drawable d;
    GC gc;
    XPoint* points;
    int npoints;
    int shape;
    int mode;
{
    HPEN pen;
    TkWinDCState state;
    HDC dc;

    if (d == None) {
	return;
    }

    dc = TkWinGetDrawableDC(display, d, &state);

    pen = GetStockObject(NULL_PEN);
    RenderObject(dc, gc, points, npoints, mode, pen, Polygon);

    TkWinReleaseDrawableDC(d, dc, &state);
}

/*
 *----------------------------------------------------------------------
 *
 * XDrawRectangle --
 *
 *	Draws a rectangle.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Draws a rectangle on the specified drawable.
 *
 *----------------------------------------------------------------------
 */

void
XDrawRectangle(display, d, gc, x, y, width, height)
    Display* display;
    Drawable d;
    GC gc;
    int x;
    int y;
    unsigned int width;
    unsigned int height;
{
    HPEN pen, oldPen;
    TkWinDCState state;
    HBRUSH oldBrush;
    HDC dc;
    TkpClipMask *clipPtr = (TkpClipMask*)gc->clip_mask;

    if (d == None) {
	return;
    }

    dc = TkWinGetDrawableDC(display, d, &state);

    if (clipPtr && clipPtr->type == TKP_CLIP_REGION) {
	SelectClipRgn(dc, (HRGN) clipPtr->value.region);
	OffsetClipRgn(dc, gc->clip_x_origin, gc->clip_y_origin);
    }
    pen = SetUpGraphicsPort(gc);
    SetBkMode(dc, TRANSPARENT);
    oldPen = SelectObject(dc, pen);
    oldBrush = SelectObject(dc, GetStockObject(NULL_BRUSH));
    SetROP2(dc, tkpWinRopModes[gc->function]);

    Rectangle(dc, x, y, x+width+1, y+height+1);

    DeleteObject(SelectObject(dc, oldPen));
    SelectObject(dc, oldBrush);
    TkWinReleaseDrawableDC(d, dc, &state);
}

/*
 *----------------------------------------------------------------------
 *
 * DrawOrFillArc --
 *
 *	This procedure handles the rendering of drawn or filled
 *	arcs and chords.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Renders the requested arc.
 *
 *----------------------------------------------------------------------
 */

static void
DrawOrFillArc(display, d, gc, x, y, width, height, start, extent, fill)
    Display *display;
    Drawable d;
    GC gc;
    int x, y;			/* left top */
    unsigned int width, height;
    int start;			/* start: three-o'clock (deg*64) */
    int extent;			/* extent: relative (deg*64) */
    int fill;			/* ==0 draw, !=0 fill */
{
    HDC dc;
    HBRUSH brush, oldBrush;
    HPEN pen, oldPen;
    TkWinDCState state;
    int clockwise = (extent < 0); /* non-zero if clockwise */
    int xstart, ystart, xend, yend;
    double radian_start, radian_end, xr, yr;
    TkpClipMask *clipPtr = (TkpClipMask*)gc->clip_mask;

    if (d == None) {
	return;
    }

    dc = TkWinGetDrawableDC(display, d, &state);

    if (clipPtr && clipPtr->type == TKP_CLIP_REGION) {
	SelectClipRgn(dc, (HRGN) clipPtr->value.region);
	OffsetClipRgn(dc, gc->clip_x_origin, gc->clip_y_origin);
    }
    SetROP2(dc, tkpWinRopModes[gc->function]);

    /*
     * Compute the absolute starting and ending angles in normalized radians.
     * Swap the start and end if drawing clockwise.
     */

    start = start % (64*360);
    if (start < 0) {
	start += (64*360);
    }
    extent = (start+extent) % (64*360);
    if (extent < 0) {
	extent += (64*360);
    }
    if (clockwise) {
	int tmp = start;
	start = extent;
	extent = tmp;
    }
    radian_start = XAngleToRadians(start);
    radian_end = XAngleToRadians(extent);

    /*
     * Now compute points on the radial lines that define the starting and
     * ending angles.  Be sure to take into account that the y-coordinate
     * system is inverted.
     */

    if (gc->fill_style == FillStippled && gc->stipple != None) {
      xr = width / 2.0;
      yr = height / 2.0;
    }
    else {
      xr = x + width / 2.0;
      yr = y + height / 2.0;
    }
    xstart = (int)((xr + cos(radian_start)*width/2.0) + 0.5);
    ystart = (int)((yr + sin(-radian_start)*height/2.0) + 0.5);
    xend = (int)((xr + cos(radian_end)*width/2.0) + 0.5);
    yend = (int)((yr + sin(-radian_end)*height/2.0) + 0.5);

    /*
     * Now draw a filled or open figure.  Note that we have to
     * increase the size of the bounding box by one to account for the
     * difference in pixel definitions between X and Windows.
     */

    pen = SetUpGraphicsPort(gc);
    oldPen = SelectObject(dc, pen);
    if (!fill) {
	/*
	 * Note that this call will leave a gap of one pixel at the
	 * end of the arc for thin arcs.  We can't use ArcTo because
	 * it's only supported under Windows NT.
	 */

	SetBkMode(dc, TRANSPARENT);
	Arc(dc, x, y, x+width+1, y+height+1, xstart, ystart, xend, yend);
    } else {
      brush = CreateSolidBrush(gc->foreground);

      if (gc->fill_style == FillStippled && gc->stipple != None) {
	TkWinDrawable *twdPtr = (TkWinDrawable *)gc->stipple;
	HBITMAP oldBitmap;
	HDC dcMem;
	HBRUSH oldMemBrush;
	
	if (twdPtr->type != TWD_BITMAP) {
	  Tcl_Panic("unexpected drawable type in stipple");
	}
	
	/*
	 * Select stipple pattern into destination dc.
	 */
	SetBrushOrgEx(dc, gc->ts_x_origin, gc->ts_y_origin, NULL);
	oldBrush = SelectObject(dc,
				CreatePatternBrush(twdPtr->bitmap.handle));
	
	/*
	 * Create temporary drawing surface containing a copy of the
	 * destination equal in size to the bounding box of the object.
	 */
	dcMem = CreateCompatibleDC(dc);
	oldBitmap = SelectObject(dcMem,
				 CreateCompatibleBitmap(dc, width, height));
	BitBlt(dcMem, 0, 0, width, height, dc, x, y, SRCCOPY);
	oldMemBrush = SelectObject(dcMem, brush);
	if (gc->arc_mode == ArcChord) {
	  Chord(dcMem, 0, 0, width+1, height+1, xstart, ystart, xend, yend);
	} else if ( gc->arc_mode == ArcPieSlice ) {
	  Pie(dcMem, 0, 0, width+1, height+1, xstart, ystart, xend, yend);
	}
	
	BitBlt(dc, x, y, width, height, dcMem, 0, 0, COPYFG);
	DeleteObject(SelectObject(dcMem, oldBitmap));
	DeleteObject(SelectObject(dcMem, oldMemBrush));
	DeleteObject(SelectObject(dc, oldBrush));
	DeleteDC(dcMem);
      } else {
	oldBrush = SelectObject(dc, brush);
	if (gc->arc_mode == ArcChord) {
	  Chord(dc, x, y, x+width+1, y+height+1, xstart, ystart, xend, yend);
	} else if ( gc->arc_mode == ArcPieSlice ) {
	  Pie(dc, x, y, x+width+1, y+height+1, xstart, ystart, xend, yend);
	}
	DeleteObject(SelectObject(dc, oldBrush));
      }
    }
    DeleteObject(SelectObject(dc, oldPen));
    TkWinReleaseDrawableDC(d, dc, &state);
}

/*
 *----------------------------------------------------------------------
 *
 * XDrawArc --
 *
 *	Draw an arc.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Draws an arc on the specified drawable.
 *
 *----------------------------------------------------------------------
 */

void
XDrawArc(display, d, gc, x, y, width, height, start, extent)
    Display* display;
    Drawable d;
    GC gc;
    int x;
    int y;
    unsigned int width;
    unsigned int height;
    int start;
    int extent;
{
    display->request++;

    DrawOrFillArc(display, d, gc, x, y, width, height, start, extent, 0);
}

/*
 *----------------------------------------------------------------------
 *
 * XFillArc --
 *
 *	Draw a filled arc.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Draws a filled arc on the specified drawable.
 *
 *----------------------------------------------------------------------
 */

void
XFillArc(display, d, gc, x, y, width, height, start, extent)
    Display* display;
    Drawable d;
    GC gc;
    int x;
    int y;
    unsigned int width;
    unsigned int height;
    int start;
    int extent;
{
    display->request++;

    DrawOrFillArc(display, d, gc, x, y, width, height, start, extent, 1);
}

#endif /* _WIN32 */
