    /*
    ###########################################################################
    #(@)PACKAGE:Win32::GUI::DC
    #
    # $Id: DC.xs,v 1.20 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

MODULE = Win32::GUI::DC     PACKAGE = Win32::GUI::DC

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::DC..." )

    ###########################################################################
    # Device Context
    ###########################################################################

    ###########################################################################
    # (@)METHOD:CancelDC()
    # Cancels any pending operation on the device context.
BOOL
CancelDC(handle)
    HDC handle
CODE:
    RETVAL = CancelDC(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CreateCompatibleDC()
    # Creates a memory device context (DC) compatible with the specified device.
void
CreateCompatibleDC(handle)
    HDC handle
PREINIT:
    HDC hnew;
PPCODE:
    hnew = CreateCompatibleDC(handle);
    if (hnew== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::DC", (HWND) hnew));
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:CreateCompatibleBitmap (WIDTH, HEIGHT)
    # Creates a bitmap compatible with the device that is associated with
    # the specified device context. 
void
CreateCompatibleBitmap(handle,width,height)
    HDC handle
    int width
    int height
PREINIT:
    HBITMAP hnew;
PPCODE:
    hnew = CreateCompatibleBitmap(handle,width,height);
    if (hnew== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Bitmap", (HWND) hnew));
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:CreateDC(DRIVER, DEVICE)
    # Used by new Win32::GUI::DC.
    # Creates a device context (DC) for a device by using the specified name. 
HDC
CreateDC(driver, device)
    LPCTSTR driver
    LPCTSTR device
CODE:
    RETVAL = CreateDC(driver, device, NULL, NULL);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteDC(HANDLE)
    # Deletes the specified device context
BOOL
DeleteDC(handle)
    HDC handle
CODE:
    RETVAL = DeleteDC(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteObject(OBJECT)
    # Deletes a logical pen, brush, font, bitmap, region, or palette, freeing
    # all system resources associated with the object. 
BOOL
DeleteObject(handle)
    HGDIOBJ handle
CODE:
    RETVAL = DeleteObject(handle);
OUTPUT:
    RETVAL

    # TODO : DrawEscape()

    ###########################################################################
    # (@)METHOD:GetCurrentObject(HANDLE,OBJECTTYPE)
    # Obtains a handle to a device context's currently selected object of a
    # specified type.
HGDIOBJ
GetCurrentObject(handle, Object)
    HDC  handle
    UINT Object
CODE:
    RETVAL = GetCurrentObject(handle, Object);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetDC(HANDLE)
    # Gets a handle to the DC associated with the given window
    # (eg. gets an HDC from an HWND).
    # Used by new Win32::GUI::DC
HDC
GetDC(handle)
    HWND handle
CODE:
    RETVAL = GetDC(handle);
OUTPUT:
    RETVAL

    # TODO : GetDCEx
    # TODO : GetDCOrgEx

    ###########################################################################
    # (@)METHOD:GetDeviceCaps(HANDLE,INDEX)
    # Retrieves device-specific information about a specified device. 
int
GetDeviceCaps(handle,index)
    HDC handle
    int index
CODE:
    RETVAL = GetDeviceCaps(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetObjectType(OBJECT)
    # Identifies the type of the specified object. 
DWORD 
GetObjectType(handle)
    HGDIOBJ handle
CODE:
    RETVAL = GetObjectType(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetStockObject(TYPEOBJECT)
    # Identifies the type of the specified object. 
HGDIOBJ 
GetStockObject(Object)
    int Object
CODE:
    RETVAL = GetStockObject(Object);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ReleaseDC(HWND, HDC)
    # Releases a device context (DC), freeing it for use by other applications. 
BOOL
ReleaseDC(hwnd, hdc)
    HWND hwnd
    HDC hdc
CODE:
    RETVAL = ReleaseDC(hwnd, hdc);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Restore([STATE])
    # (@)METHOD:RestoreDC([STATE])
    # Restores the state of the DC saved by Save(). STATE can identify a state
    # from the saved stack (use the identifier returned by the corresponding
    # Save() call) or a negative number that specifies how many steps backwards
    # in the stack to recall (eg. -1 recalls the last saved state).
    # The default if STATE is not specified is -1.
    # Note that the restored state is removed from the stack, and if you restore
    # an early one, all the subsequent states will be removed too.
    # Returns nonzero if succesful, zero on errors.
    # See also Save().
BOOL
RestoreDC(handle,state=-1)
    HDC handle
    int state
ALIAS:
    Win32::GUI::DC::Restore = 1
CODE:
    RETVAL = RestoreDC(handle, state);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Save()
    # (@)METHOD:SaveDC()
    # Saves the current state of the DC (this means the currently selected
    # colors, brushes, pens, drawing modes, etc.) to an internal stack.
    # The function returns a number identifying the saved state; this number
    # can then be passed to the Restore() function to load it back.
    # If the return value is zero, an error occurred.
    # See also Restore().
int
SaveDC(handle)
    HDC handle
ALIAS:
    Win32::GUI::DC::Save = 1
CODE:
    RETVAL = SaveDC(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectObject(OBJECT)
    # Selects an object into the specified device context. 
    # The new object replaces the previous object of the same type. 
HGDIOBJ
SelectObject(handle, object)
    HDC handle
    HGDIOBJ object
CODE:
    RETVAL = SelectObject(handle, object);
OUTPUT:
    RETVAL

    ###########################################################################
    # Filled Shapes
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Chord(LEFT, TOP, RIGHT, BOTTOM, XF, YF, XS, YS)
    # Draws a chord (a region bounded by the intersection of an ellipse and
    # a line segment, called a "secant"). The chord is outlined by using the
    # current pen and filled by using the current brush.
BOOL
Chord(handle, left, top, right, bottom, xf, yf, xs, ys)
    HDC handle
    int left
    int top
    int right
    int bottom
    int xf
    int yf
    int xs
    int ys
CODE:
    RETVAL = Chord(handle, left, top, right, bottom, xf, yf, xs, ys);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Ellipse(LEFT, TOP, RIGHT, BOTTOM)
    # Draws an ellipse. 
    # The center of the ellipse is the center of the specified bounding
    # rectangle. The ellipse is outlined by using the current pen and is
    # filled by using the current brush. 
BOOL
Ellipse(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
CODE:
    RETVAL = Ellipse(handle, left, top, right, bottom);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Circle(X, Y, (WIDTH, HEIGHT | RADIUS))
    # Draws a circle or an ellipse; X, Y, RADIUS specifies the center point
    # and the radius of the circle, while X, Y, WIDTH, HEIGHT specifies the
    # center point and the size of the ellipse.
    # Returns nonzero if succesful, zero on errors.
BOOL
Circle(handle, x, y, width, height=-1)
    HDC handle
    int x
    int y
    int width
    int height
CODE:
    if(height == -1) {
        width *= 2;
        height = width;
    }
    width /= 2; height /= 2;
    RETVAL = Ellipse(handle, x-width, y-height, x+width, y+height);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FillRect(LEFT, TOP, RIGHT, BOTTOM, BRUSH)
    # Fills a rectangle by using the specified brush. 
    # This includes the left and top borders, but excludes the right and
    # bottom borders of the rectangle. 
BOOL
FillRect(handle, left, top, right, bottom, hbr)
    HDC handle
    int left
    int top
    int right
    int bottom
    HBRUSH hbr
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = FillRect(handle, &rc, hbr);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FrameRect(LEFT, TOP, RIGHT, BOTTOM, BRUSH)
    # Draws a border around the specified rectangle by using the specified
    # brush. The width and height of the border are always one logical unit. 
BOOL
FrameRect(handle, left, top, right, bottom, hbr)
    HDC handle
    int left
    int top
    int right
    int bottom
    HBRUSH hbr
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = FrameRect(handle, &rc, hbr);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InvertRect(LEFT, TOP, RIGHT, BOTTOM)
    # Inverts a rectangle in a window by performing a logical NOT operation
    # on the color values for each pixel in the rectangle's interior. 
BOOL
InvertRect(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = InvertRect(handle, &rc);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Pie(LEFT, TOP, RIGHT, BOTTOM, XF, YF, XS, YS)
    # Draws a pie-shaped wedge bounded by the intersection of an ellipse
    # and two radials. The pie is outlined by using the current pen and
    # filled by using the current brush. 
BOOL
Pie(handle, left, top, right, bottom, xf, yf, xs, ys)
    HDC handle
    int left
    int top
    int right
    int bottom
    int xf
    int yf
    int xs
    int ys
CODE:
    RETVAL = Pie(handle, left, top, right, bottom, xf, yf, xs, ys);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Polygon(X1, Y1, X2, Y2, [ X, Y, ... ])
    # Draws a polygon consisting of two or more vertices connected by
    # straight lines.
BOOL
Polygon(handle, ...)
    HDC handle
PREINIT:
    POINT *lpPoints;
    int nCount, i, j;
CODE:
    if (items < 5 || (items - 5) % 2 != 0)
        croak("Usage: Polygon(X1, Y1, X2, Y2, [ X, Y, ... ]);\n");
    
    nCount   = (items - 1) / 2;
    lpPoints = (POINT *) safemalloc(nCount * sizeof(POINT));

    for (i = 1, j = 0; i < items; i += 2, j++) {
        lpPoints[j].x = (LONG)SvIV(ST(i));
        lpPoints[j].y = (LONG)SvIV(ST(i+1));
    }
        
    RETVAL = Polygon(handle, lpPoints, nCount);
    safefree(lpPoints);
OUTPUT:
    RETVAL

    # TODO : PolyPolygon

    ###########################################################################
    # (@)METHOD:Rectangle(LEFT, TOP, RIGHT, BOTTOM)
    # Draws a rectangle. 
    # The rectangle is outlined by using the current pen and filled by
    # using the current brush. 
BOOL
Rectangle(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
CODE:
    RETVAL = Rectangle(handle, left, top, right, bottom);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:RoundRect(LEFT, TOP, RIGHT, BOTTOM, WIDTH, HEIGHT)
    # Draws a rectangle with rounded corners. 
    # The rectangle is outlined by using the current pen and filled by using
    # the current brush. 
BOOL
RoundRect(handle, left, top, right, bottom, width, height)
    HDC handle
    int left
    int top
    int right
    int bottom
    int width
    int height
CODE:
    RETVAL = RoundRect(handle, left, top, right, bottom, width, height);
OUTPUT:
    RETVAL

    ###########################################################################
    # Font and Text
    ###########################################################################

    ###########################################################################
    # (@)METHOD:DrawText(STRING, LEFT, TOP, RIGHT, BOTTOM, [FORMAT=DT_LEFT|DT_SINGLELINE|DT_TOP])
    # Draws formatted text in the specified rectangle. It formats the text
    # according to the specified method.
int
DrawText(handle, string, left, top, right, bottom, format=DT_LEFT|DT_SINGLELINE|DT_TOP)
    HDC handle
    LPCTSTR string
    int left
    int top
    int right
    int bottom
    UINT format
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = DrawText(handle, string, -1, &rc, format);
OUTPUT:
    RETVAL

    # TODO : ExtTextOut

    ###########################################################################
    # (@)METHOD:TextAlign([ALIGN])
    # Set or Get text-alignment setting for the specified device context. 
UINT
TextAlign(handle, Align=(UINT) -1)
    HDC handle
    UINT Align
CODE:
    if(items == 1) {
        RETVAL = GetTextAlign(handle);
    } else {
        RETVAL = SetTextAlign(handle, Align);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextCharacterExtra([CHAREXTRA])
    # Set or Get the intercharacter spacing.
UINT
TextCharacterExtra(handle, extra= -1)
    HDC handle
    int extra
CODE:
    if(items == 1) {
        RETVAL = GetTextCharacterExtra(handle);
    } else {
        RETVAL = SetTextCharacterExtra(handle, extra);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the text color.
long
TextColor(handle, color=(COLORREF) -1)
    HDC handle
    COLORREF color
CODE:
    if(items == 1) {
        RETVAL = GetTextColor(handle);
    } else {
        RETVAL = SetTextColor(handle, color);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextExtentPoint(STRING)
    # Computes the width and height of the specified string of text. 
void
GetTextExtentPoint(handle, string)
    HDC handle
    LPCTSTR string
PREINIT:
    SIZE size;
PPCODE:
    if (GetTextExtentPoint32(handle, string, strlen(string), &size)) {
        EXTEND(SP, 2);
        XST_mIV(0, size.cx);
        XST_mIV(1, size.cy);
        XSRETURN(2);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetTextFace()
    # Retrieves the typeface name of the font that is selected into the
    # specified device context. 
void
GetTextFace(handle)
    HDC handle
PREINIT:
    char Text[1024];
PPCODE:
    GetTextFace(handle, 1024, Text);
    EXTEND(SP, 1);
    XST_mPV(0, Text);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:SetTextJustification(BREAKEXTRA, BREAKCOUNT)
    # Specifies the amount of space the system should add to the break
    # characters in a string of text
BOOL 
SetTextJustification(handle, nBreakExtra, nBreakCount)
    HDC handle
    int nBreakExtra
    int nBreakCount
CODE:
    RETVAL = SetTextJustification(handle, nBreakExtra, nBreakCount);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextOut(X, Y, TEXT)
    # Writes a character string at the specified location, using the
    # currently selected font, background color, and text color. 
BOOL
TextOut(handle, x, y, text)
    HDC handle
    int x
    int y
    LPCTSTR text
CODE:
    RETVAL = TextOut(handle, x, y, text, strlen(text));
OUTPUT:
    RETVAL

    ###########################################################################
    # Lines and curves
    ###########################################################################

    ###########################################################################
    # (@)METHOD:Arc(X, Y, RADIUS, START, SWEEP)
    # Draws a line segment and an arc. 
    # The line segment is drawn from the current position to the beginning
    # of the arc. The arc is drawn along the perimeter of a circle with the
    # given radius and center. The length of the arc is defined by the given
    # start and sweep angles.
BOOL
Arc(handle, x, y, radius, start, sweep)
    HDC handle
    int x
    int y
    DWORD radius
    FLOAT start
    FLOAT sweep
CODE:
    RETVAL = AngleArc(handle, x, y, radius, start, sweep);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ArcDirection([DIRECTION])
    # Gets or sets the drawing direction to be used for arc and rectangle
    # functions. 
int
ArcDirection(handle, direction = -1)
    HDC handle
    int direction
CODE:
    if(items == 1) {
        RETVAL = GetArcDirection(handle);
    } else {
        RETVAL = SetArcDirection(handle, direction);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ArcTo(LEFT, TOP, RIGHT, BOTTOM, XRADIALF, YRADIALF, XRADIALS, YRADIALS)
    # Draws an elliptical arc. 
BOOL
ArcTo(handle, left, top, right, bottom, xf, yf, xs, ys)
    HDC handle
    int left
    int top
    int right
    int bottom
    int xf
    int yf
    int xs
    int ys
CODE:
    RETVAL = ArcTo (handle, left, top, right, bottom, xf, yf, xs, ys);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Line(X,Y,X1,Y1)
    # A combination of MoveTo and LineTo
long
Line(handle,x,y,x1,y1)
    HDC handle
    int x
    int y
    int x1
    int y1
CODE:
    MoveToEx(handle, x, y, NULL);
    RETVAL = LineTo(handle, x1, y1);
OUTPUT:

    ###########################################################################
    # (@)METHOD:LineTo(X, Y)
    # Draws a line from the current drawing position up to, but not including,
    # the point specified by X, Y.
    # Returns nonzero if succesful, zero on errors.
long
LineTo(handle, x, y)
    HDC handle
    int x
    int y
CODE:
    RETVAL = LineTo(handle, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MoveTo(X, Y)
    # Moves the current drawing position to the point specified by X, Y.
    # Returns nonzero if succesful, zero on errors.
long
MoveTo(handle, x, y)
    HDC handle
    int x
    int y
CODE:
    RETVAL = MoveToEx(handle, x, y, NULL);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PolyBezier(X1, Y1, X2, Y2, X3, Y3, X4, Y4, [ X, Y, ... ])
    # Draws one or more Bezier curves. 
    # The first curve is drawn from the first point to the fourth point by
    # using the second and third points as control points. 
    # Each subsequent curve in the sequence needs exactly three more points: 
    # the ending point of the previous curve is used as the starting point, the
    # next two points in the sequence are control points, and the third is
    # the ending point. 
BOOL
PolyBezier(handle, ...)
    HDC handle
PREINIT:
    POINT *lpPoints;
    int nCount, i, j;
CODE:
    if (items < 9 || (items - 9) % 6 != 0)
        croak("Usage: PolyBezier(X1, Y1, X2, Y2, X3, Y3, X4, Y4, [ X, Y, ... ]);\n");
    
    nCount   = (items - 1) / 2;
    lpPoints = (POINT *) safemalloc(nCount * sizeof(POINT));

    for (i = 1, j = 0; i < items; i += 2, j++) {
        lpPoints[j].x = (LONG)SvIV(ST(i));
        lpPoints[j].y = (LONG)SvIV(ST(i+1));
    }
        
    RETVAL = PolyBezier(handle, lpPoints, nCount);
    safefree(lpPoints);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PolyBezierTo(X1, Y1, X2, Y2, X3, Y3, [ X, Y, ... ])
    # Draws cubic Bezier curves.
    # The first curve is drawn from the current position to the third point by
    # using the first two points as control points. For each subsequent curve, 
    # the function needs exactly three more points, and uses the ending point
    # of the previous curve as the starting point for the next.
BOOL
PolyBezierTo (handle, ...)
    HDC handle
PREINIT:
    POINT *lpPoints;
    int nCount, i, j;
CODE:
    if (items < 7 || (items - 7) % 6 != 0)
        croak("Usage: PolyBezier(X1, Y1, X2, Y2, X3, Y3, [ X, Y, ... ]);\n");
    
    nCount   = (items - 1) / 2;
    lpPoints = (POINT *) safemalloc(nCount * sizeof(POINT));

    for (i = 1, j = 0; i < items; i += 2, j++) {
        lpPoints[j].x = (LONG)SvIV(ST(i));
        lpPoints[j].y = (LONG)SvIV(ST(i+1));
    }
        
    RETVAL = PolyBezierTo (handle, lpPoints, nCount);
    safefree(lpPoints);
OUTPUT:
    RETVAL

    # TODO : PolyDraw

    ###########################################################################
    # (@)METHOD:Polyline (X1, Y1, X2, Y2, [ X, Y, ... ])
    # Draws one or more straight lines.
BOOL
Polyline(handle, ...)
    HDC handle
PREINIT:
    POINT *lpPoints;
    int nCount, i, j;
CODE:
    if (items < 5 || (items - 5) % 2 != 0)
        croak("Usage: Polyline(X1, Y1, X2, Y2, [ X, Y, ... ]);\n");
    
    nCount   = (items - 1) / 2;
    lpPoints = (POINT *) safemalloc(nCount * sizeof(POINT));

    for (i = 1, j = 0; i < items; i += 2, j++) {
        lpPoints[j].x = (LONG)SvIV(ST(i));
        lpPoints[j].y = (LONG)SvIV(ST(i+1));
    }
        
    RETVAL = Polyline (handle, lpPoints, nCount);
    safefree(lpPoints);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PolylineTo (X1, Y1, [ X, Y, ... ])
    # Draws one or more straight lines. 
BOOL
PolylineTo(handle, ...)
    HDC handle
PREINIT:
    POINT *lpPoints;
    int nCount, i, j;
CODE:
    if (items < 3 || (items - 3) % 2 != 0)
        croak("Usage: PolylineTo(X1, Y2, [ X, Y, ... ]);\n");
    
    nCount   = (items - 1) / 2;
    lpPoints = (POINT *) safemalloc(nCount * sizeof(POINT));

    for (i = 1, j = 0; i < items; i += 2, j++) {
        lpPoints[j].x = (LONG)SvIV(ST(i));
        lpPoints[j].y = (LONG)SvIV(ST(i+1));
    }
        
    RETVAL = PolylineTo(handle, lpPoints, nCount);
    safefree(lpPoints);
OUTPUT:
    RETVAL

    ###########################################################################
    # Painting and Drawing
    ###########################################################################

    # TODO : DrawAnimatedRects
    # TODO : DrawCaption

    ###########################################################################
    # (@)METHOD:DrawEdge(LEFT, TOP, RIGHT, BOTTOM, [EDGE=EDGE_RAISE, [FLAGS=BF_RECT]])
    # Draws one or more edges of rectangle
BOOL
DrawEdge(handle, left, top, right, bottom, edge=EDGE_RAISED, flags=BF_RECT)
    HDC handle
    int left
    int top
    int right
    int bottom
    UINT edge
    UINT flags
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = DrawEdge(handle, &rc, edge, flags);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DrawFocusRect(LEFT, TOP, RIGHT, BOTTOM)
    # Draws a rectangle in the style used to indicate that the rectangle has
    # the focus. 
BOOL
DrawFocusRect(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = DrawFocusRect(handle, &rc);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DrawFrameControl(LEFT, TOP, RIGHT, BOTTOM, TYPE, STATE)
    # Draws a frame control of the specified type and style.
    #
    # If STATE includes DFCS_ADJUSTRECT, then the input parameters
    # LEFT, TOP, RIGHT, BOTTOM are ajusted to exclude the surrounding edge
    # of the push button. If any of LEFT, TOP, RIGHT, BOTTOM are readonly,
    # then DFCS_ADJUSTRECT will be ignored for the readonly parameters.
BOOL
DrawFrameControl(handle, left, top, right, bottom, type, state)
    HDC  handle
    RECT rc = { (LONG)SvIV(ST(1)), (LONG)SvIV(ST(2)), (LONG)SvIV(ST(3)), (LONG)SvIV(ST(4)) };
    UINT type
    UINT state
C_ARGS:
    handle, &rc, type, state
POSTCALL:
    if (state & DFCS_ADJUSTRECT) {
        if(!SvREADONLY(ST(1))) { sv_setiv_mg(ST(1), (IV)rc.left);   }
        if(!SvREADONLY(ST(2))) { sv_setiv_mg(ST(2), (IV)rc.top);    }
        if(!SvREADONLY(ST(3))) { sv_setiv_mg(ST(3), (IV)rc.right);  }
        if(!SvREADONLY(ST(4))) { sv_setiv_mg(ST(4), (IV)rc.bottom); }
    }

    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color.
long
BackColor(handle, color=(COLORREF) -1)
    HDC handle
    COLORREF color
CODE:
    if(items == 1) {
        RETVAL = (long) GetBkColor(handle);
    } else {
        RETVAL = (long) SetBkColor(handle, color);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BkMode([MODE])
    # Gets or sets the current background mix mode for the DC;
    # possible values are:
    #  1 TRANSPARENT
    #  2 OPAQUE
long
BkMode(handle, mode=-1)
    HDC handle
    int mode
CODE:
    if(items == 1) {
        RETVAL = (long) GetBkMode(handle);
    } else {
        RETVAL = (long) SetBkMode(handle, mode);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ROP2([MODE])
    # Gets or sets the foreground mix mode of the specified device context. 
    # The mix mode specifies how the pen or interior color and the color
    # already on the screen are combined to yield a new color.     
long
ROP2(handle, mode=-1)
    HDC handle
    int mode
CODE:
    if(items == 1) {
        RETVAL = (long) GetROP2(handle);
    } else {
        RETVAL = (long) SetROP2(handle, mode);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUpdateRect([ERASE])
    # Returns the rectangle (as a four-element array containing left, top,
    # right, bottom coordinates) that needs to be updated.
    # If the update region is empty (eg. no need to update, the function
    # returns undef).
    # The optional ERASE parameter can be set to 1 to force an erase of
    # the update region, if there is any; by default, no erase action is
    # performed.
    # This function is intended to be used in a Paint event;
    # see Win32::GUI::Graphic::Paint().
void
GetUpdateRect(handle, erase=0)
    SV* handle
    BOOL erase
PREINIT:
    HWND hwnd;
    SV** window;
    HV* self;
    RECT myRect;
PPCODE:
    if(NULL != handle)  {
        if(SvROK(handle)) {
            self = (HV*) SvRV(handle);
            window = hv_fetch_mg(NOTXSCALL self, "-window", 7, 0);
            if(window != NULL) {
                hwnd = INT2PTR(HWND,SvIV(*window));
            } else {
                XSRETURN_UNDEF;
            }
        } else {
            XSRETURN_UNDEF;
        }
    } else {
        XSRETURN_UNDEF;
    }
    ZeroMemory(&myRect, sizeof(RECT));
    if(GetUpdateRect(hwnd, &myRect, erase)) {
        EXTEND(SP, 4);
        XST_mIV(0, myRect.left);
        XST_mIV(1, myRect.top);
        XST_mIV(2, myRect.right);
        XST_mIV(3, myRect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:PaintDesktop()
    # Fills the DC content with the desktop pattern or wallpaper.
    # Returns nonzero if succesful, zero on errors.
BOOL
PaintDesktop(handle)
    HDC handle
CODE:
    RETVAL = PaintDesktop(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Validate()
    # Validates (removes from the update region) the whole DC area.
    # This function is intended to be used in a Paint event;
    # see Win32::GUI::Graphic::Paint().
    # Returns nonzero if succesful, zero on errors.
BOOL
Validate(handle)
    SV* handle
CODE:
    HWND hwnd;
    SV** window;
    HV* self;
    char szKey[] = "-window";

    if(NULL != handle)  {
        if(SvROK(handle)) {
            self = (HV*) SvRV(handle);
            window = hv_fetch_mg(NOTXSCALL self, szKey, strlen(szKey), 0);
            if(window != NULL) {
                hwnd = INT2PTR(HWND,SvIV(*window));
            } else {
                XSRETURN_NO;
            }
        } else {
            XSRETURN_NO;
        }
    } else {
        XSRETURN_NO;
    }
    RETVAL = ValidateRect(hwnd, NULL);
OUTPUT:
    RETVAL

    ###########################################################################
    # Paths
    ###########################################################################

    ###########################################################################
    # (@)METHOD:AbortPath()
    # Closes and discards any paths.
BOOL
AbortPath(handle)
    HDC handle
CODE:
    RETVAL = AbortPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BeginPath()
    # Opens a path bracket.
BOOL
BeginPath(handle)
    HDC handle
CODE:
    RETVAL = BeginPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CloseFigure()
    # Closes an open figure in a path.
BOOL
CloseFigure(handle)
    HDC handle
CODE:
    RETVAL = CloseFigure(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EndPath()
    # Closes a path bracket and selects the path defined by the bracket.
BOOL
EndPath(handle)
    HDC handle
CODE:
    RETVAL = EndPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FillPath()
    # Closes any open figures in the current path and fills the path's interior by
    # using the current brush and polygon-filling mode.
BOOL
FillPath(handle)
    HDC handle
CODE:
    RETVAL = FillPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FlattenPath()
    # Transforms any curves in the path that is selected, turning each curve into a sequence of lines. 
BOOL
FlattenPath(handle)
    HDC handle
CODE:
    RETVAL = FlattenPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMiterLimit()
    # Returns the miter limit for the specified device context.
FLOAT
GetMiterLimit(handle)
    HDC handle
PREINIT:
    FLOAT limit;
CODE:
    GetMiterLimit(handle, &limit);
    RETVAL = limit;
OUTPUT:
    RETVAL

    # TODO : GetPath

    ###########################################################################
    # (@)METHOD:PathToRegion()
    # Creates a region from the path that is selected into the specified
    # device context. 
HRGN
PathToRegion(handle)
    HDC handle
CODE:
    RETVAL = PathToRegion(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMiterLimit(FLOAT)
    # Sets the limit for the length of miter joins 
BOOL
SetMiterLimit(handle, limit)
    HDC handle
    FLOAT limit
CODE:
    RETVAL = SetMiterLimit(handle, limit, NULL);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:StrokeAndFillPath()
    # Closes any open figures in a path, strokes the outline of the path by 
    # using the current pen, and fills its interior by using the current brush. 
BOOL
StrokeAndFillPath(handle)
    HDC handle
CODE:
    RETVAL = StrokeAndFillPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:StrokePath()
    # Renders the specified path by using the current pen. 
BOOL
StrokePath(handle)
    HDC handle
CODE:
    RETVAL = StrokePath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:WidenPath()
    # Redefines the current path as the area that would be painted if the path
    # were stroked using the pen currently selected into the given device
    # context. 
BOOL
WidenPath(handle)
    HDC handle
CODE:
    RETVAL = WidenPath(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # Bitmap
    ###########################################################################

    ###########################################################################
    # (@)METHOD:BitBlt(XD, YD, WD, HD, SOURCE, XS, YS, [ROP=SRCCOPY])
    # Performs a bit-block transfer of the color data corresponding to a
    # rectangle of pixels from the specified source device context into
    # a destination device context. 
BOOL
BitBlt(handle, xd, yd, w, h, source, xs, ys, dwRop=SRCCOPY)
    HDC handle
    int xd
    int yd
    int w
    int h
    HDC source
    int xs
    int ys
    DWORD dwRop
CODE:
    RETVAL = BitBlt (handle, xd, yd, w, h, source, xs, ys, dwRop);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:StretchBlt(XD, YD, WD, HD, SOURCE, XS, YS, WD, HD, [ROP=SRCCOPY])
    # Performs a bit-block transfer of the color data corresponding to a
    # rectangle of pixels from the specified source device context into
    # a rectangle of pixels in the destination device context, performing
    # stretching a necessary. 
BOOL
StretchBlt(handle, xd, yd, wd, hd, source, xs, ys, ws, hs, dwRop=SRCCOPY)
    HDC handle
    int xd
    int yd
    int wd
    int hd
    HDC source
    int xs
    int ys
    int ws
    int hs
    DWORD dwRop
CODE:
    RETVAL = StretchBlt (handle, xd, yd, wd, hd, source, xs, ys, ws, hs, dwRop);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ExtFloodFill(X, Y, COLOR, [TYPE=FLOODFILLSURFACE])
    # Fills an area of the display surface with the current brush. 
BOOL
ExtFloodFill (handle, xs, ys, color, type=FLOODFILLSURFACE)
    HDC handle
    int xs
    int ys
    COLORREF color
    UINT type
CODE:
    RETVAL = ExtFloodFill (handle, xs, ys, color, type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FloodFill(X, Y, COLOR)
    # Fills an area of the display surface with the current brush.
BOOL
FloodFill(handle, xs, ys, color)
    HDC handle
    int xs
    int ys
    COLORREF color
CODE:
    RETVAL = ExtFloodFill(handle, xs, ys, color, FLOODFILLBORDER);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GradientFillTriangle(X0, Y0, COLOR0, X1, Y1, COLOR1, X2, Y2, COLOR2)
    # Fills the area of the triangle using smooth shading from color0 at point
    # zero through to the other points.
    #

BOOL
GradientFillTriangle(handle, x0, y0, color0, x1, y1, color1, x2, y2, color2)
    HDC handle
    int x0
    int y0
    COLORREF color0
    int x1
    int y1
    COLORREF color1
    int x2
    int y2
    COLORREF color2
CODE:
    TRIVERTEX vertex[3];
    vertex[0].x     = x0;
    vertex[0].y     = y0;
    vertex[0].Red   = (COLOR16) (GetRValue(color0) << 8);;
    vertex[0].Green = (COLOR16) (GetGValue(color0) << 8);;
    vertex[0].Blue  = (COLOR16) (GetBValue(color0) << 8);;
    vertex[0].Alpha = 0x0000;

    vertex[1].x     = x1;
    vertex[1].y     = y1;
    vertex[1].Red   = (COLOR16) (GetRValue(color1) << 8);;
    vertex[1].Green = (COLOR16) (GetGValue(color1) << 8);;
    vertex[1].Blue  = (COLOR16) (GetBValue(color1) << 8);;
    vertex[1].Alpha = 0x0000;

    vertex[2].x     = x2;
    vertex[2].y     = y2; 
    vertex[2].Red   = (COLOR16) (GetRValue(color2) << 8);;
    vertex[2].Green = (COLOR16) (GetGValue(color2) << 8);;
    vertex[2].Blue  = (COLOR16) (GetBValue(color2) << 8);; 
    vertex[2].Alpha = 0x0000;

    GRADIENT_TRIANGLE gTriangle;
    gTriangle.Vertex1 = 0;
    gTriangle.Vertex2 = 1;
    gTriangle.Vertex3 = 2;

    RETVAL = GradientFill(handle, vertex, 3, &gTriangle, 1, GRADIENT_FILL_TRIANGLE);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GradientFillRectangle(X0, Y0, COLOR0, X1, Y1, COLOR1, X2, Y2, COLOR2,DIRECTION)
    # Fills the area of the Rectangle using smooth shading from color0 to color1.
    # As a default the smoothing will be horizontal, to specify vertical smoothing pass any
    # value as the final parameter.
    #

BOOL
GradientFillRectangle(handle, x0, y0, x1, y1, color0,color1,direction=GRADIENT_FILL_RECT_H)
    HDC handle
    int x0
    int y0
    int x1
    int y1
    COLORREF color0
    COLORREF color1
    int direction
CODE:
    if (direction!=GRADIENT_FILL_RECT_H) {
      direction = GRADIENT_FILL_RECT_V;
    }
    TRIVERTEX vertex[2] ;
    vertex[0].x     = x0;
    vertex[0].y     = y0;
    vertex[0].Red   = (COLOR16) (GetRValue(color0) << 8);
    vertex[0].Green = (COLOR16) (GetGValue(color0) << 8);
    vertex[0].Blue  = (COLOR16) (GetBValue(color0) << 8);
    vertex[0].Alpha = 0x0000;

    vertex[1].x     = x1;
    vertex[1].y     = x1; 
    vertex[1].Red   = (COLOR16) (GetRValue(color1) << 8);
    vertex[1].Green = (COLOR16) (GetGValue(color1) << 8);
    vertex[1].Blue  = (COLOR16) (GetBValue(color1) << 8);
    vertex[1].Alpha = 0x0000;

    GRADIENT_RECT gRect;
    gRect.UpperLeft  = 0;
    gRect.LowerRight = 1;

    RETVAL = GradientFill(handle, vertex, 2, &gRect, 1, direction);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetPixel(X, Y)
    # Returns the color of the pixel at X, Y.
COLORREF
GetPixel(handle, x, y)
    HDC handle
    int x
    int y
CODE:
    RETVAL = GetPixel(handle, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:StretchBltMode([MODE])
    # Get or Set bitmap stretching mode in the specified device context. 
int
StretchBltMode(handle, mode=-1)
    HDC handle
    int mode
CODE:
    if(items == 1)
        RETVAL = GetStretchBltMode(handle);
    else
        RETVAL = SetStretchBltMode(handle, mode);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DrawIcon(Icon,X, Y)
    # The DrawIcon method draws an icon or cursor into the specified
    # device context.
int
DrawIcon(handle, Icon, x, y)
    HDC handle
    HICON Icon
    int x
    int y
CODE:
    RETVAL = DrawIcon(handle, x, y,Icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBrushOrgEx(X, Y)
    # The SetBrushOrgEx method sets the brush origin that GDI assigns to
    # the next brush an application selects into the specified device context. 
    # Returns the (x,y) of the previous brush origin. 
void
SetBrushOrgEx(handle, x, y)
    HDC handle
    int x
    int y
PREINIT:
    POINT myPt;
CODE:
    SetBrushOrgEx(handle, x, y,&myPt);
    EXTEND(SP, 2);
    XST_mIV(0, myPt.x);
    XST_mIV(1, myPt.y);
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:GetBrushOrgEx
    # The GetBrushOrgEx method retrieves the current brush origin (x,y)
    # for the specified device context. 
void
GetBrushOrgEx(handle)
    HDC handle
PREINIT:
    POINT myPt;
CODE:
    GetBrushOrgEx(handle,&myPt);
    EXTEND(SP, 2);
    XST_mIV(0, myPt.x);
    XST_mIV(1, myPt.y);
    XSRETURN(2);
    
    ###########################################################################
    # (@)METHOD:SetPixel(X, Y, [COLOR])
    # Sets the pixel at X, Y to the specified COLOR
    # (or to the current TextColor() if COLOR is not specified).
COLORREF
SetPixel(handle, x, y, color=(COLORREF)-1)
    HDC handle
    int x
    int y
    COLORREF color
CODE:
    if(items == 3) {
        color = GetTextColor(handle);
    }
    RETVAL = SetPixel(handle, x, y, color);
OUTPUT:
    RETVAL

    ###########################################################################
    #
    ###########################################################################


    ###########################################################################
    # (@)METHOD:MapMode([MODE])
int
MapMode(handle, mode=-1)
    HDC handle
    int mode
CODE:
    if(items == 1) {
        RETVAL = GetMapMode(handle);
    } else {
        RETVAL = SetMapMode(handle, mode);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Fill(X, Y, [COLOR], [TYPE])
    # Fills an area of the display surface.
BOOL
Fill(handle, x, y, color=(COLORREF) -1, type=FLOODFILLSURFACE)
    HDC handle
    int x
    int y
    COLORREF color
    UINT type
CODE:
    if(items == 3) {
        color = GetPixel(handle, x, y);
    }
    RETVAL = ExtFloodFill(handle, x, y, color, type);
OUTPUT:
    RETVAL

    ###########################################################################
    # Region based methods
    ###########################################################################
    
    ###########################################################################
    # (@)METHOD:FillRgn (Region,Brush)
    # The FillRgn function fills a region by using the specified brush. 
BOOL
FillRgn(handle,hrgn,hbr)
    HDC handle
    HRGN hrgn
    HBRUSH hbr 
CODE:
    RETVAL = FillRgn(handle,hrgn,hbr);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InvertRgn (Region)
    # The InvertRgn function inverts the colors in the specified region. 
BOOL
InvertRgn(handle,hrgn)
    HDC handle
    HRGN hrgn
CODE:
    RETVAL = InvertRgn(handle,hrgn);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:PaintRgn (Region)
    # The PaintRgn function paints the specified region by using the brush
    # currently selected into the device context. 
BOOL
PaintRgn(handle,hrgn)
    HDC handle
    HRGN hrgn
CODE:
    RETVAL = PaintRgn(handle,hrgn);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:FrameRgn (Region,Brush,Width,Height)
    # The FrameRgn function draws a border around the specified region
    # by using the specified brush.  
    #
    # The Width Specifies the width of vertical brush strokes. 
    # The Height Specifies the height of horizontal brush strokes. 
BOOL
FrameRgn(handle,hrgn,hbr,width,height)
    HDC handle
    HRGN hrgn
    HBRUSH hbr 
    int width
    int height
CODE:
    RETVAL = FrameRgn(handle,hrgn,hbr,width,height);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:SelectClipRgn (Region)
    # This method selects a region as the current clipping region for
    # the specified device context.
    #
    # If no region is passed, then this method will remove a
    # device-context's clipping region. 
BOOL
SelectClipRgn(handle,hrgn=NULL)
    HDC handle
    HRGN hrgn
CODE:
    RETVAL = SelectClipRgn(handle,hrgn);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Brush
    ###########################################################################

MODULE = Win32::GUI::DC     PACKAGE = Win32::GUI::Brush

#pragma message( "*** PACKAGE Win32::GUI::Brush..." )


    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
void
Create(...)
PREINIT:
    LOGBRUSH lb;
    char *option;
    int i, next_i;
PPCODE:
    ZeroMemory(&lb, sizeof(LOGBRUSH));
    if(items == 1) {
        lb.lbStyle = BS_SOLID;
        lb.lbColor = SvCOLORREF(NOTXSCALL ST(0));
    } else {
        next_i = -1;
        for(i = 0; i < items; i++) {
            if(next_i == -1) {
                option = SvPV_nolen(ST(i));
                if(strcmp(option, "-pattern") == 0) {
                    next_i = i + 1;
                    lb.lbStyle = BS_PATTERN;
                    lb.lbHatch = (LONG_PTR) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-hatch") == 0) {
                    next_i = i + 1;
                    lb.lbStyle = BS_HATCHED;
                    lb.lbHatch = (LONG_PTR) SvIV(ST(next_i));
                } else if(strcmp(option, "-color") == 0) {
                    next_i = i + 1;
                    lb.lbColor = SvCOLORREF(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-system") == 0) {
                    next_i = i + 1;
                    XSRETURN_IV(PTR2IV(GetSysColorBrush((int)SvIV(ST(next_i)))));
                }
            } else {
                next_i = -1;
            }
        }
    }
    XSRETURN_IV(PTR2IV(CreateBrushIndirect(&lb)));

    ###########################################################################
    # (@)METHOD:Info()
    # Returns an associative array of information about the Brush object, with
    # the same options given when creating the Brush.
void
Info(handle)
    HBRUSH handle
PREINIT:
    LOGBRUSH brush;
PPCODE:
    ZeroMemory(&brush, sizeof(LOGBRUSH));
    if(GetObject((HGDIOBJ) handle, sizeof(LOGBRUSH), &brush)) {
        if(brush.lbStyle & BS_PATTERN) {
            EXTEND(SP, 4);
            XST_mPV( 0, "-pattern");
            XST_mIV( 1, brush.lbHatch);
            XST_mPV( 2, "-color");
            XST_mIV( 3, brush.lbColor);
            XSRETURN(4);
        } else if(brush.lbStyle & BS_HATCHED) {
            EXTEND(SP, 4);
            XST_mPV( 0, "-hatch");
            XST_mIV( 1, brush.lbHatch);
            XST_mPV( 2, "-color");
            XST_mIV( 3, brush.lbColor);
            XSRETURN(4);
        } else {
            EXTEND(SP, 6);
            XST_mPV( 0, "-style");
            XST_mIV( 1, brush.lbStyle);
            XST_mPV( 2, "-hatch");
            XST_mIV( 3, brush.lbHatch);
            XST_mPV( 4, "-color");
            XST_mIV( 5, brush.lbColor);
            XSRETURN(6);
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HBRUSH handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Pen
    ###########################################################################

MODULE = Win32::GUI::DC     PACKAGE = Win32::GUI::Pen

#pragma message( "*** PACKAGE Win32::GUI::Pen..." )

    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
void
Create(...)
PPCODE:
    int penstyle;
    int penwidth;
    COLORREF pencolor;
    char *option;
    int i, next_i;
    penstyle = PS_SOLID;
    penwidth = 0;
    pencolor = RGB(0, 0, 0);
    if(items == 1) {
        pencolor = SvCOLORREF(NOTXSCALL ST(0));
    } else {
        next_i = -1;
        for(i = 0; i < items; i++) {
            if(next_i == -1) {
                option = SvPV_nolen(ST(i));
                if(strcmp(option, "-style") == 0) {
                    next_i = i + 1;
                    penstyle = (int) SvIV(ST(next_i));
                }
                if(strcmp(option, "-width") == 0) {
                    next_i = i + 1;
                    penwidth = (int) SvIV(ST(next_i));
                }
                if(strcmp(option, "-color") == 0) {
                    next_i = i + 1;
                    pencolor = SvCOLORREF(NOTXSCALL ST(next_i));
                }
            } else {
                next_i = -1;
            }
        }
    }
    XSRETURN_IV(PTR2IV(CreatePen(penstyle, penwidth, pencolor)));

    ###########################################################################
    # (@)METHOD:Info()
    # Returns an associative array of information about the Pen object, with
    # the same options given when creating the Pen.
void
Info(handle)
    HPEN handle
PREINIT:
    LOGPEN pen;
PPCODE:
    ZeroMemory(&pen, sizeof(LOGPEN));
    if(GetObject((HGDIOBJ) handle, sizeof(LOGPEN), &pen)) {
        EXTEND(SP, 6);
        XST_mPV( 0, "-style");
        XST_mIV( 1, pen.lopnStyle);
        XST_mPV( 2, "-width");
        XST_mIV( 3, pen.lopnWidth.x);
        XST_mPV( 4, "-color");
        XST_mIV( 5, pen.lopnColor);
        XSRETURN(6);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HPEN handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Region
    #
    ###########################################################################

MODULE = Win32::GUI::DC     PACKAGE = Win32::GUI::Region

#pragma message( "*** PACKAGE Win32::GUI::Region..." )

    ###########################################################################
    # (@)METHOD:CreateRectRgn (LEFT, TOP, RIGHT, BOTTOM)
    # The CreateRectRgn function creates a rectangular region, returning a
    # region object.
void   
CreateRectRgn(Class="Win32::GUI::Region",left, top, right, bottom)
    char *Class
    int left
    int top
    int right
    int bottom
PREINIT:
    HRGN hrgn;
PPCODE:
    hrgn = CreateRectRgn(left, top, right, bottom);
    if (hrgn== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Region", (HWND) hrgn));
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:CreateEllipticRgn (LEFT, TOP, RIGHT, BOTTOM)
    # The CreateEllipticRgn function creates an elliptical region,
    # returning a region object. 
    #
    # The bounding rectangle defines the size, shape, and orientation of
    # the region: The long sides of the rectangle define the length of the
    # ellipse's major axis; the short sides define the length of the
    # ellipse's minor axis; and the center of the rectangle defines 
    # the intersection of the major and minor axes. 
void 
CreateEllipticRgn(Class="Win32::GUI::Region",left, top, right, bottom)
    char *Class
    int left
    int top
    int right
    int bottom
PREINIT:
    HRGN hrgn;
PPCODE:
    hrgn = CreateEllipticRgn(left, top, right, bottom);
    if (hrgn== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Region", (HWND) hrgn));

    ###########################################################################
    # (@)METHOD:CreateRoundRectRgn (LEFT, TOP, RIGHT, BOTTOM , WIDTH, HEIGHT)
    # The CreateRoundRectRgn function creates a rectangular region with
    # rounded corners, returning a region object.  
    #
    # The width and height is of the ellipse used to create the rounded
    # corners. 
void 
CreateRoundRectRgn(Class="Win32::GUI::Region",left, top, right, bottom, width, height)
    char *Class
    int left
    int top
    int right
    int bottom
    int width
    int height
PREINIT:
    HRGN hrgn;
PPCODE:
    hrgn = CreateRoundRectRgn(left, top, right, bottom,width,height);
    if (hrgn== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Region", (HWND) hrgn));

    ###########################################################################
    # (@)METHOD:ExtCreateRegion (RGNDATA)
    #
    # The ExtCreateRgn function creates a region from data held in memory.
    # The data is a win32 RGNDATA structure (See MSDN) that can be created by
    # packing the appropriate structure, or more easily by using the
    # L<GetRgnData()|Win32::GUI::Region/GetRegionData> method.
    #
    #   my $rgn = Win32::GUI::Region->CreateRoundRectRgn(0,0,100,100,50,50);
    #   my $rgndata = $rgn->GetRegionData();
    #   my $newrgn = Win32::GUI::Region->ExtCreateRegion($rgndata);
    #
    # Returns a Win32::GUI::Region object on success or undef on failure
void
ExtCreateRegion(Class="Win32::GUI::Region", svrgndata)
    char *Class
    SV *svrgndata
PREINIT:
    HRGN hrgn;
    LPRGNDATA rgndata;
    STRLEN len;
PPCODE:
    rgndata = (LPRGNDATA)SvPV(svrgndata, len);
    /* TODO: XFORM transformation as first param? */
    hrgn = ExtCreateRegion(NULL, (DWORD)len, rgndata);
    if (hrgn== NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Region", (HWND) hrgn));

    ###########################################################################
    # (@)METHOD:GetRegionData ()
    #
    # The GetRegionData functions returns a representation of the region as a
    # string of bytes that can be used to re-create an identical region using
    # the L<ExtCreateRgn()|Win32::GUI::Region/ExtCreateRegion> method.
    #
    # Returns a string of bytes on success or undef on failure
void
GetRegionData(handle)
    HRGN handle
PREINIT:
    SV *svrgndata;
    STRLEN len1, len2;
PPCODE:
    len1 = (STRLEN)GetRegionData(handle, 0, NULL);
    svrgndata = sv_2mortal(newSV(len1));
    SvPOK_on(svrgndata);
    SvCUR_set(svrgndata,len1);
    len2 = (STRLEN)GetRegionData(handle, (DWORD)len1, (LPRGNDATA)SvPV_nolen(svrgndata));

    if(len1 == len2) { /* success */
        XPUSHs(svrgndata);
        XSRETURN(1);
    }
    else {             /* failure */
        XSRETURN_UNDEF;
    }
    

    ###########################################################################
    # (@)METHOD:CombineRgn (source1,source2,CombineMode)
    # The CombineRgn method combines two regions. The two regions are
    # combined according to the specified mode. 
    #
    # CombineMode:
    #  RGN_AND  (1) Creates the intersection of the two combined regions. 
    #  RGN_COPY (5) Creates a copy of the region identified by source1. 
    #  RGN_DIFF (4) Combines the parts of source1 that are not part of source2. 
    #  RGN_OR   (2) Creates the union of two combined regions. 
    #  RGN_XOR  (3) Creates the union of two combined regions except for any
    #               overlapping areas. 
    #
    # Return Values:
    #  NULLREGION    (1) The region is empty. 
    #  SIMPLEREGION  (2) The region is a single rectangle. 
    #  COMPLEXREGION (3) The region is more than a single rectangle. 
    #  ERROR         (0) No region is created. 
int CombineRgn(destination,source1,source2,CombineMode)
  HRGN destination
  HRGN source1
  HRGN source2
  long CombineMode
CODE:
    RETVAL = CombineRgn(destination,source1,source2,CombineMode);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:PtInRegion (X,Y)
    # The PtInRegion method determines whether the specified point is inside
    # the specified region. 
    #
    # If the specified point is in the region, the return value is nonzero.
    # If the specified point is not in the region, the return value is zero. 
BOOL
PtInRegion(handle,x,y)
    HRGN handle
    int x
    int y
CODE:
    RETVAL = PtInRegion(handle,x,y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:RectInRegion (left, top, right, bottom)
    # The RectInRegion method determines whether any part of the specified
    # rectangle is within the boundaries of a region.  
    #
    # If any part of the specified rectangle lies within the boundaries of
    # the region, the return value is nonzero.
    #
    # If no part of the specified rectangle lies within the boundaries of
    # the region, the return value is zero.
BOOL
RectInRegion(handle,left, top, right, bottom)
    HRGN handle
    int left
    int top
    int right
    int bottom 
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = RectInRegion(handle,&rc);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRgnBox ()
    # The GetRgnBox function retrieves the bounding rectangle of the specified
    # region. 
    # Returns the rectangle (as a four-element array containing left, top,
    # right, bottom coordinates)
void
GetRgnBox (handle)
    HRGN handle
PREINIT:
    RECT rc;
PPCODE:    
  GetRgnBox(handle,&rc); 
  EXTEND(SP, 4);
  XST_mIV(0, rc.left);
  XST_mIV(1, rc.top);
  XST_mIV(2, rc.right);
  XST_mIV(3, rc.bottom);
  XSRETURN(4);

    ###########################################################################
    # (@)METHOD:EqualRgn (Region)
    # The EqualRgn function checks the two specified regions to determine
    # whether they are identical. The method considers two regions identical
    # if they are equal in size and shape.
BOOL
EqualRgn(handle,other)
    HRGN handle
    HRGN other
CODE:
    RETVAL = EqualRgn(handle,other);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:SetRectRgn (left, top, right, bottom)
    # The SetRectRgn function converts a region into a rectangular region
    # with the specified coordinates. 
    #
BOOL
SetRectRgn(handle,left, top, right, bottom)
    HRGN handle
    int left
    int top
    int right
    int bottom 
CODE:
    RETVAL = SetRectRgn(handle,left, top, right, bottom);
OUTPUT:
    RETVAL
    
    ###########################################################################
    # (@)METHOD:OffsetRgn (X,Y)
    # The OffsetRgn function moves a region by the specified offsets. 
    #
    # The return value specifies the new region's complexity. It can be
    # one of the following values. 
    #
    # 1 (NULLREGION)    Region is empty. 
    # 2 (SIMPLEREGION)  Region is a single rectangle. 
    # 3 (COMPLEXREGION) Region is more than one rectangle. 
    # 0 (ERROR)         An error occurred; region is unaffected. 

int
OffsetRgn(handle,x,y)
    HRGN handle
    int x
    int y
CODE:
    RETVAL = OffsetRgn (handle,x,y);
OUTPUT:
    RETVAL
       
    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HRGN handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL
