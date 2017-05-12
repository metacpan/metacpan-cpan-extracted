/*
 * Types.h -- Some types and macros used by the Zinc widget.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Mon Feb  1 12:13:24 1999
 *
 * $Id: Types.h,v 1.47 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Types_h
#define _Types_h


#ifdef _WIN32
#  define WIN32_LEAN_AND_MEAN
#  include <windows.h>
#  undef WIN32_LEAN_AND_MEAN
#  if defined(_MSC_VER)
#    define DllEntryPoint DllMain
#  endif
// Suppress complaints about deprecated standard C functions
// like strcpy and strcat
#  ifndef __GNUC__
#    pragma warning(disable : 4996)
#  endif
#endif

#ifdef GL
#  ifdef _WIN32
#    include <GL/gl.h>
#  else
#    include <GL/glx.h>
#  endif
#endif

#define NEED_REAL_STDIO

#include <tk.h>
#include <tkInt.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#ifdef PTK
#  include <tkPort.h>
#  include <tkImgPhoto.h>
#  include <tkVMacro.h>
#  ifndef PTK_800
#    define Arg Tcl_Obj *
#  endif
#else
#  include <tkDecls.h>
#  include <tkIntDecls.h>
#endif
#include <stdio.h>


/* This EXTERN declaration is needed for Tcl < 8.0.3 */
#ifndef EXTERN
# ifdef __cplusplus
#  define EXTERN extern "C" TCL_STORAGE_CLASS
# else
#  define EXTERN extern TCL_STORAGE_CLASS
# endif
#endif


#ifdef __CPLUSPLUS__
extern "C" {
#endif


typedef double  ZnReal; /* Keep it a double for GL and Tcl. */
typedef int     ZnBool; /* Keep it an int to keep Tk happy */
typedef ZnReal  ZnPos;
typedef ZnReal  ZnDim;
typedef void    *ZnPtr;


#define ZnPixel(color)          ((color)->pixel)
#define ZnMalloc(size)          ((void *)ckalloc(size))
#define ZnFree(ptr)             (ckfree((char *)(ptr)))
#define ZnRealloc(ptr, size)    ((void *)ckrealloc((void *)(ptr), size))
#define ZnWarning(msg)          (fprintf(stderr, "%s", (msg)))
  
#define ZnUnspecifiedImage      None
#define ZnUnspecifiedColor      NULL

#ifndef TCL_INTEGER_SPACE
#  define TCL_INTEGER_SPACE     24
#endif

#ifdef PTK_800
/*
 * Macros for Tk8.4/perl/Tk utf compatibility
 */
#define Tcl_NumUtfChars(str, len) (((len)<0)?((int)strlen(str)):(len))
#define Tcl_UtfAtIndex(str, index) (&(str)[(index)])
#define Tcl_GetString(str) (Tcl_GetStringFromObj(str, NULL))

#define Tk_GetScrollInfoObj(interp, argc, args, fract, count) \
Tk_GetScrollInfo(interp, argc, (Tcl_Obj **) args, fract, count)
#endif

/*
 * Macros for Windows compatibility
 */
#ifdef _WIN32
#  include <tkWinInt.h>

#  ifndef _MSC_VER
#    undef EXTERN
#    define EXTERN
#  endif
#  ifdef TCL_STORAGE_CLASS
#    undef TCL_STORAGE_CLASS
#  endif
#  ifdef BUILD_Tkzinc
#    define TCL_STORAGE_CLASS DLLEXPORT
#  else
#    define TCL_STORAGE_CLASS DLLIMPORT
#  endif

#  ifndef __GNUC__
// Okay, Those Xlib functions will bring inconsistancy errors
// as they are already provided by Tk portability layer, shut them up.
#  pragma warning(disable : 4273)
#  endif
#undef XFillRectangle
void XFillRectangle(Display *display, Drawable d, GC gc, int x, int y,
                    unsigned int width, unsigned int height);
#  undef XFillRectangles
void XFillRectangles(Display *display, Drawable d, GC gc,
                     XRectangle* rectangles, int nrectangles);
#  undef XFillArc
void XFillArc(Display *display, Drawable d, GC gc, int x, int y, unsigned int width,
              unsigned int height, int start, int extent);
#  undef XFillPolygon
void XFillPolygon(Display *display, Drawable d, GC gc, XPoint *points, int npoints,
                  int shape, int mode);
#  undef XDrawRectangle
void XDrawRectangle(Display *display, Drawable d, GC gc, int x, int y,
                    unsigned int width, unsigned int height);
#  undef XDrawArc
void XDrawArc(Display *display, Drawable d, GC gc, int x, int y,
              unsigned int width, unsigned int height, int start, int extent);
#  undef XDrawLine
void XDrawLine(Display *display, Drawable d, GC gc, int x1, int y1, int x2, int y2);
#  undef XDrawLines
void XDrawLines(Display *display, Drawable d, GC gc, XPoint* points,
                int npoints, int mode);

ZnBool ZnPointInRegion(TkRegion reg, int x, int y);
void ZnUnionRegion(TkRegion sra, TkRegion srb, 
                   TkRegion dr_return);
void ZnOffsetRegion(TkRegion reg, int dx, int dy);
TkRegion ZnPolygonRegion(XPoint *points, int n,
                         int fill_rule);
#  ifdef GL
#    define ZnGLContext HGLRC
#    define ZnGLWaitX()
#    define ZnGLWaitGL()
#    define ZN_GL_LINE_WIDTH_RANGE GL_LINE_WIDTH_RANGE
#    define ZN_GL_POINT_SIZE_RANGE GL_POINT_SIZE_RANGE
#  endif
#else /* !_WIN32 */
#  define ZnPointInRegion(reg, x, y) \
  XPointInRegion((Region) reg, x, y)
#  define ZnPolygonRegion(points, npoints, fillrule) \
  ((TkRegion) XPolygonRegion(points, npoints, fillrule))
#  define ZnUnionRegion(sra, srb, rreturn) \
  XUnionRegion((Region) sra, (Region) srb, (Region) rreturn)
#  define ZnOffsetRegion(reg, dx, dy) \
  XOffsetRegion((Region) reg, dx, dy)
#  ifdef GL
#    define ZnGLContext GLXContext
#    define ZnGLWaitX() \
  glXWaitX()
#    define ZnGLWaitGL() \
  glXWaitGL()
#    define ZN_GL_LINE_WIDTH_RANGE GL_SMOOTH_LINE_WIDTH_RANGE
#    define ZN_GL_POINT_SIZE_RANGE GL_SMOOTH_POINT_SIZE_RANGE
#  endif
#endif

#ifdef __CPLUSPLUS__
}
#endif

#endif /* _Types_h */
