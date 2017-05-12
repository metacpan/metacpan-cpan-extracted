/*
 * PostScript.h -- Header to access PostScript driver.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Wed Jan  4 11:30:00 1995
 *
 * $Id: PostScript.h,v 1.7 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1995 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _PostScript_h
#define _PostScript_h


#include "List.h"
#include "Types.h"
#include "Geo.h"
#include "Color.h"
#include "Image.h"

#include <stdio.h>
#include <X11/Xlib.h>


struct _ZnWInfo;
struct _ZnItemStruct;


int ZnPostScriptCmd(struct _ZnWInfo *wi, int argc, Tcl_Obj *CONST *args);
void ZnFlushPsChan(Tcl_Interp *interp, Tk_PostscriptInfo ps_info);
int ZnPostscriptOutline(Tcl_Interp *interp, Tk_PostscriptInfo ps_info,
                        Tk_Window tkwin, ZnDim line_width, ZnLineStyle line_style,
                        ZnGradient *line_color, ZnImage line_pattern);
int ZnPostscriptBitmap(Tcl_Interp *interp, Tk_Window tkwin, Tk_PostscriptInfo ps_info,
                       ZnImage bitmap, ZnReal x, ZnReal y, int width, int height);
void ZnPostscriptString(Tcl_Interp *interp, char *str, int num_bytes);
void ZnPostscriptTrace(struct _ZnItemStruct *item, ZnBool enter);
int ZnPostscriptGradient(Tcl_Interp *interp, Tk_PostscriptInfo ps_info,
                         ZnGradient *gradient, ZnPoint *quad, ZnPoly *poly);
int ZnPostscriptXImage(Tcl_Interp *interp, Tk_Window tkwin, Tk_PostscriptInfo psInfo,
                       XImage *ximage, int x, int y, int width, int height);
int ZnPostscriptStipple(Tcl_Interp *interp, Tk_Window tkwin, Tk_PostscriptInfo ps_info,
                        ZnImage bitmap);
int ZnPostscriptTile(Tcl_Interp *interp, Tk_Window win, Tk_PostscriptInfo ps_info,
                     ZnImage image);
int ZnPostscriptImage(Tcl_Interp *interp, Tk_Window tkwin, Tk_PostscriptInfo ps_info,
                      ZnImage image, int x, int y, int width, int height);

#endif	/* _PostScript_h */
