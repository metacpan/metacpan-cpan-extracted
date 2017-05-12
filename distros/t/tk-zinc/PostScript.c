/*
 * PostScript.c -- Implementation of PostScript driver.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Tue Jan 3 13:17:17 1995
 *
 * $Id: PostScript.c,v 1.22 2005/05/25 08:28:38 lecoanet Exp $
 */

/*
 *  Copyright (c) 1995 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

/*
 * This code is based on tkCanvPs.c which is copyright:
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 */

/*
 **********************************************************************************
 *
 * Included files
 *
 **********************************************************************************
 */

#ifndef _WIN32
#include <unistd.h>
#include <pwd.h>
#endif
#include <stdio.h>
#include <sys/types.h>
#include <time.h>
#include <string.h>

#include "Types.h"
#include "Item.h"
#include "Group.h"
#include "PostScript.h"
#include "WidgetInfo.h"
#include "Geo.h"


/*
 **********************************************************************************
 *
 * Constants.
 * 
 **********************************************************************************
 */

static  const char rcsid[] = "$Id: PostScript.c,v 1.22 2005/05/25 08:28:38 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 * One of the following structures is created to keep track of Postscript
 * output being generated.  It consists mostly of information provided on
 * the widget command line.
 * WATCH! This structure must be kept in sync with the structure in
 * tkCanvPs.c, we share most of the code for emitting postscript and
 * this rely on sharing the structure.
 */
typedef struct TkPostscriptInfo {
  int           x, y, width, height; /* Area to print, in canvas pixel
                                      * coordinates. */
  int           x2, y2;              /* x+width and y+height. */
  char          *pageXString;        /* String value of "-pagex" option or NULL. */
  char          *pageYString;        /* String value of "-pagey" option or NULL. */
  double        pageX, pageY;        /* Postscript coordinates (in points)
                                      * corresponding to pageXString and
                                      * pageYString. Don't forget that y-values
                                      * grow upwards for Postscript! */
  char          *pageWidthString;    /* Printed width of output. */
  char          *pageHeightString;   /* Printed height of output. */
  double        scale;               /* Scale factor for conversion: each pixel
                                      * maps into this many points. */
  Tk_Anchor     pageAnchor;          /* How to anchor bbox on Postscript page. */
  int           rotate;              /* Non-zero means output should be rotated
                                      * on page (landscape mode). */
  char          *fontVar;            /* If non-NULL, gives name of global variable
                                      * containing font mapping information.
                                      * Malloc'ed. */
  char          *colorVar;           /* If non-NULL, give name of global variable
                                      * containing color mapping information.
                                      * Malloc'ed. */
  char          *colorMode;          /* Mode for handling colors:  "monochrome",
                                      * "gray", or "color".  Malloc'ed. */
  int           colorLevel;          /* Numeric value corresponding to colorMode:
                                      * 0 for mono, 1 for gray, 2 for color. */
  char          *fileName;           /* Name of file in which to write Postscript;
                                      * NULL means return Postscript info as
                                      * result. Malloc'ed. */
  char          *channelName;        /* If -channel is specified, the name of
                                      * the channel to use. */
  Tcl_Channel   chan;                /* Open channel corresponding to fileName. */
  Tcl_HashTable fontTable;           /* Hash table containing names of all font
                                      * families used in output.  The hash table
                                      * values are not used. */
  int           prepass;             /* Non-zero means that we're currently in
                                      * the pre-pass that collects font information,
                                      * so the Postscript generated isn't
                                      * relevant. */
  int           prolog;              /* Non-zero means output should contain
                                      * the file prolog.ps in the header. */
  /*
   * Below are extensions for Tkzinc.
   */
   ZnBBox       bbox;
} TkPostscriptInfo;

/*
 * The table below provides a template that's used to process arguments
 * to the "postscript" command and fill in TkPostscriptInfo structures.
 */
static Tk_ConfigSpec config_specs[] = {
  {TK_CONFIG_STRING, "-colormap", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, colorVar), 0, NULL},
  {TK_CONFIG_STRING, "-colormode", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, colorMode), 0, NULL},
  {TK_CONFIG_STRING, "-file", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, fileName), 0, NULL},
  {TK_CONFIG_STRING, "-channel", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, channelName), 0, NULL},
  {TK_CONFIG_STRING, "-fontmap", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, fontVar), 0, NULL},
  {TK_CONFIG_PIXELS, "-height", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, height), 0, NULL},
  {TK_CONFIG_ANCHOR, "-pageanchor", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, pageAnchor), 0, NULL},
  {TK_CONFIG_STRING, "-pageheight", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, pageHeightString), 0, NULL},
  {TK_CONFIG_STRING, "-pagewidth", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, pageWidthString), 0, NULL},
  {TK_CONFIG_STRING, "-pagex", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, pageXString), 0, NULL},
  {TK_CONFIG_STRING, "-pagey", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, pageYString), 0, NULL},
  {TK_CONFIG_BOOLEAN, "-prolog", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, prolog), 0, NULL},
  {TK_CONFIG_BOOLEAN, "-rotate", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, rotate), 0, NULL},
  {TK_CONFIG_PIXELS, "-width", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, width), 0, NULL},
  {TK_CONFIG_PIXELS, "-x", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, x), 0, NULL},
  {TK_CONFIG_PIXELS, "-y", (char *) NULL, (char *) NULL,
   "", Tk_Offset(TkPostscriptInfo, y), 0, NULL},
  {TK_CONFIG_END, (char *) NULL, (char *) NULL, (char *) NULL,
   (char *) NULL, 0, 0, NULL}
};

/*
 *--------------------------------------------------------------
 *
 * GetPostscriptPoints --
 *
 *  Given a string, returns the number of Postscript points
 *  corresponding to that string.
 *
 * Results:
 *  The return value is a standard Tcl return result.  If
 *  TCL_OK is returned, then everything went well and the
 *  screen distance is stored at *doublePtr;  otherwise
 *  TCL_ERROR is returned and an error message is left in
 *  the interp's result.
 *
 * Side effects:
 *  None.
 *
 *--------------------------------------------------------------
 */
static int
GetPostscriptPoints(Tcl_Interp *interp,
                    char       *string,
                    double     *double_ptr)
{
  char *end;
  double d;

  d = strtod(string, &end);
  if (end == string) {
  error:
    Tcl_AppendResult(interp, "bad distance \"", string, "\"", (char *) NULL);
    return TCL_ERROR;
  }
  while ((*end != '\0') && isspace(UCHAR(*end))) {
    end++;
  }
  switch (*end) {
  case 'c':
    d *= 72.0/2.54;
    end++;
    break;
  case 'i':
    d *= 72.0;
    end++;
    break;
  case 'm':
    d *= 72.0/25.4;
    end++;
    break;
  case 0:
    break;
  case 'p':
    end++;
    break;
  default:
    goto error;
  }
  while ((*end != '\0') && isspace(UCHAR(*end))) {
    end++;
  }
  if (*end != 0) {
    goto error;
  }
  *double_ptr = d;
  return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * ZnPostScriptCmd --
 *
 *  This procedure is invoked to process the "postscript" options
 *  of the widget command for zinc widgets. See the user
 *  documentation for details on what it does.
 *
 * Results:
 *  A standard Tcl result.
 *
 * Side effects:
 *  See the user documentation.
 *
 *--------------------------------------------------------------
 */
int
ZnPostScriptCmd(ZnWInfo        *wi,
                int            argc,
                Tcl_Obj *CONST argv[])
{
  TkPostscriptInfo  ps_info;
  Tk_PostscriptInfo old_info;
  int               result;
#define STRING_LENGTH 400
  char              string[STRING_LENGTH+1];
  CONST char        *p;
  time_t            now;
  size_t            length;
  Tk_Window         tkwin = wi->win;
  /*
   *  Offset of lower-left corner of area to be marked up, measured
   * in canvas units from the positioning point on the page (reflects
   * anchor position).  Initial values needed only to stop compiler
   * warnings. 
   */
  int               delta_x = 0, delta_y = 0;
  Tcl_HashSearch    search;
  Tcl_HashEntry     *entry;
  Tcl_DString       buffer;
  char              psenccmd[] = "::tk::ensure_psenc_is_loaded";

  /*
   *----------------------------------------------------------------
   * Initialize the data structure describing Postscript generation,
   * then process all the arguments to fill the data structure in.
   *----------------------------------------------------------------
   */
#ifndef PTK
  result = Tcl_EvalEx(wi->interp, psenccmd, -1, TCL_EVAL_GLOBAL);
#endif
  if (result != TCL_OK) {
    return result;
  }
  old_info = wi->ps_info;
  wi->ps_info = (Tk_PostscriptInfo) &ps_info;
  ps_info.x = (int) wi->origin.x;
  ps_info.y = (int) wi->origin.y;
  ps_info.width = -1;
  ps_info.height = -1;
  ps_info.pageXString = NULL;
  ps_info.pageYString = NULL;
  ps_info.pageX = 72*4.25;
  ps_info.pageY = 72*5.5;
  ps_info.pageWidthString = NULL;
  ps_info.pageHeightString = NULL;
  ps_info.scale = 1.0;
  ps_info.pageAnchor = TK_ANCHOR_CENTER;
  ps_info.rotate = 0;
  ps_info.fontVar = NULL;
  ps_info.colorVar = NULL;
  ps_info.colorMode = NULL;
  ps_info.colorLevel = 0;
  ps_info.fileName = NULL;
  ps_info.channelName = NULL;
  ps_info.chan = NULL;
  ps_info.prepass = 0;
  ps_info.prolog = 1;
  Tcl_InitHashTable(&ps_info.fontTable, TCL_STRING_KEYS);
  result = Tk_ConfigureWidget(wi->interp, wi->win, config_specs,
                              argc-2, (CONST char **) argv+2,
                              (char *) &ps_info,
                              TK_CONFIG_ARGV_ONLY|TK_CONFIG_OBJS);
  if (result != TCL_OK) {
    goto cleanup;
  }

  if (ps_info.width == -1) {
    ps_info.width = Tk_Width(tkwin);
  }
  if (ps_info.height == -1) {
    ps_info.height = Tk_Height(tkwin);
  }
  ps_info.x2 = ps_info.x + ps_info.width;
  ps_info.y2 = ps_info.y + ps_info.height;
  ps_info.bbox.orig.x = ps_info.x;
  ps_info.bbox.orig.y = ps_info.y;
  ps_info.bbox.corner.x = ps_info.x2;
  ps_info.bbox.corner.y = ps_info.y2;

  if (ps_info.pageXString != NULL) {
    if (GetPostscriptPoints(wi->interp, ps_info.pageXString, &ps_info.pageX) != TCL_OK) {
      goto cleanup;
    }
  }
  if (ps_info.pageYString != NULL) {
    if (GetPostscriptPoints(wi->interp, ps_info.pageYString, &ps_info.pageY) != TCL_OK) {
      goto cleanup;
    }
  }
  if (ps_info.pageWidthString != NULL) {
    if (GetPostscriptPoints(wi->interp, ps_info.pageWidthString, &ps_info.scale) != TCL_OK) {
      goto cleanup;
    }
    ps_info.scale /= ps_info.width;
  }
  else if (ps_info.pageHeightString != NULL) {
    if (GetPostscriptPoints(wi->interp, ps_info.pageHeightString, &ps_info.scale) != TCL_OK) {
      goto cleanup;
    }
    ps_info.scale /= ps_info.height;
  }
  else {
    ps_info.scale = (72.0/25.4)*WidthMMOfScreen(Tk_Screen(tkwin));
    ps_info.scale /= WidthOfScreen(Tk_Screen(tkwin));
  }
  switch (ps_info.pageAnchor) {
  case TK_ANCHOR_NW:
  case TK_ANCHOR_W:
  case TK_ANCHOR_SW:
    delta_x = 0;
    break;
  case TK_ANCHOR_N:
  case TK_ANCHOR_CENTER:
  case TK_ANCHOR_S:
    delta_x = -ps_info.width/2;
    break;
  case TK_ANCHOR_NE:
  case TK_ANCHOR_E:
  case TK_ANCHOR_SE:
    delta_x = -ps_info.width;
    break;
  }
  switch (ps_info.pageAnchor) {
  case TK_ANCHOR_NW:
  case TK_ANCHOR_N:
  case TK_ANCHOR_NE:
    delta_y = - ps_info.height;
    break;
  case TK_ANCHOR_W:
  case TK_ANCHOR_CENTER:
  case TK_ANCHOR_E:
    delta_y = -ps_info.height/2;
    break;
  case TK_ANCHOR_SW:
  case TK_ANCHOR_S:
  case TK_ANCHOR_SE:
    delta_y = 0;
    break;
  }

  if (ps_info.colorMode == NULL) {
    ps_info.colorLevel = 2;
  }
  else {
    length = strlen(ps_info.colorMode);
    if (strncmp(ps_info.colorMode, "monochrome", length) == 0) {
      ps_info.colorLevel = 0;
    }
    else if (strncmp(ps_info.colorMode, "gray", length) == 0) {
      ps_info.colorLevel = 1;
    }
    else if (strncmp(ps_info.colorMode, "color", length) == 0) {
      ps_info.colorLevel = 2;
    }
    else {
      Tcl_AppendResult(wi->interp, "bad color mode \"", ps_info.colorMode,
                       "\": must be monochrome, ", "gray, or color",
                       (char *) NULL);
      goto cleanup;
    }
  }

  if (ps_info.fileName != NULL) {
    /*
     * Check that -file and -channel are not both specified.
     */
    if (ps_info.channelName != NULL) {
      Tcl_AppendResult(wi->interp, "can't specify both -file", " and -channel",
                       (char *) NULL);
      result = TCL_ERROR;
      goto cleanup;
    }
    /*
     * Check that we are not in a safe interpreter. If we are, disallow
     * the -file specification.
     */
    if (Tcl_IsSafe(wi->interp)) {
      Tcl_AppendResult(wi->interp, "can't specify -file in a", " safe interpreter",
                       (char *) NULL);
      result = TCL_ERROR;
      goto cleanup;
    }
        
    p = Tcl_TranslateFileName(wi->interp, ps_info.fileName, &buffer);
    if (p == NULL) {
      goto cleanup;
    }
    ps_info.chan = Tcl_OpenFileChannel(wi->interp, p, "w", 0666);
    Tcl_DStringFree(&buffer);
    if (ps_info.chan == NULL) {
      goto cleanup;
    }
  }

  if (ps_info.channelName != NULL) {
    int mode;
        
    /*
     * Check that the channel is found in this interpreter and that it
     * is open for writing.
     */
    ps_info.chan = Tcl_GetChannel(wi->interp, ps_info.channelName, &mode);
    if (ps_info.chan == (Tcl_Channel) NULL) {
      result = TCL_ERROR;
      goto cleanup;
    }
    if ((mode & TCL_WRITABLE) == 0) {
      Tcl_AppendResult(wi->interp, "channel \"", ps_info.channelName,
                       "\" wasn't opened for writing", (char *) NULL);
      result = TCL_ERROR;
      goto cleanup;
    }
  }

  /*
   *--------------------------------------------------------
   * Make a pre-pass over all of the items, generating Postscript
   * and then throwing it away.  The purpose of this pass is just
   * to collect information about all the fonts in use, so that
   * we can output font information in the proper form required
   * by the Document Structuring Conventions.
   *--------------------------------------------------------
   */
  ps_info.prepass = 1;
  result = wi->top_group->class->PostScript(wi->top_group, True, &ps_info.bbox);
  Tcl_ResetResult(wi->interp);
  /*
   * If an error occurred, just proceed with the main pass.
   * There's no need to report the error now;  it can be
   * reported later (errors can happen later that don't
   * happen now, so we still have to check for errors later
   * anyway).
   */
  ps_info.prepass = 0;

  /*
   *--------------------------------------------------------
   * Generate the header and prolog for the Postscript.
   *--------------------------------------------------------
   */
  if (ps_info.prolog) {
    Tcl_AppendResult(wi->interp, "%!PS-Adobe-3.0 EPSF-3.0\n",
                     "%%Creator: Tk Zinc Widget\n", (char *) NULL);
#ifdef HAVE_PW_GECOS
    if (!Tcl_IsSafe(wi->interp)) {
      struct passwd *pwPtr = getpwuid(getuid());  /* INTL: Native. */
      Tcl_AppendResult(wi->interp, "%%For: ",
                       (pwPtr != NULL) ? pwPtr->pw_gecos : "Unknown", "\n",
                       (char *) NULL);
      endpwent();
    }
#endif /* HAVE_PW_GECOS */
    Tcl_AppendResult(wi->interp, "%%Title: Window ", Tk_PathName(tkwin), "\n",
                     (char *) NULL);
    time(&now);
    /* INTL: Native. */
    Tcl_AppendResult(wi->interp, "%%CreationDate: ", ctime(&now), (char *) NULL);
    if (!ps_info.rotate) {
      sprintf(string, "%d %d %d %d", (int) (ps_info.pageX + ps_info.scale*delta_x),
              (int) (ps_info.pageY + ps_info.scale*delta_y),
              (int) (ps_info.pageX + ps_info.scale*(delta_x + ps_info.width) + 1.0),
              (int) (ps_info.pageY + ps_info.scale*(delta_y + ps_info.height) + 1.0));
    }
    else {
      sprintf(string, "%d %d %d %d",
              (int) (ps_info.pageX - ps_info.scale*(delta_y + ps_info.height)),
              (int) (ps_info.pageY + ps_info.scale*delta_x),
              (int) (ps_info.pageX - ps_info.scale*delta_y + 1.0),
              (int) (ps_info.pageY + ps_info.scale*(delta_x + ps_info.width) + 1.0));
    }
    Tcl_AppendResult(wi->interp, "%%BoundingBox: ", string, "\n", (char *) NULL);
    Tcl_AppendResult(wi->interp, "%%Pages: 1\n", "%%DocumentData: Clean7Bit\n",
                     (char *) NULL);
    Tcl_AppendResult(wi->interp, "%%Orientation: ",
                     ps_info.rotate ? "Landscape\n" : "Portrait\n", (char *) NULL);
    p = "%%DocumentNeededResources: font ";
    for (entry = Tcl_FirstHashEntry(&ps_info.fontTable, &search); entry != NULL;
         entry = Tcl_NextHashEntry(&search)) {
      Tcl_AppendResult(wi->interp, p, Tcl_GetHashKey(&ps_info.fontTable, entry),
                       "\n", (char *) NULL);
      p = "%%+ font ";
    }
    Tcl_AppendResult(wi->interp, "%%EndComments\n\n", (char *) NULL);

    /*
     * Insert the prolog
     */
    Tcl_AppendResult(wi->interp, Tcl_GetVar(wi->interp,"::tk::ps_preamable",
                     TCL_GLOBAL_ONLY), (char *) NULL);

    if (ps_info.chan != NULL) {
      Tcl_Write(ps_info.chan, Tcl_GetStringResult(wi->interp), -1);
      Tcl_ResetResult(wi->interp);
    }

    /*
     *-----------------------------------------------------------
     * Document setup:  set the color level and include fonts.
     *-----------------------------------------------------------
     */
    sprintf(string, "/CL %d def\n", ps_info.colorLevel);
    Tcl_AppendResult(wi->interp, "%%BeginSetup\n", string, (char *) NULL);
    for (entry = Tcl_FirstHashEntry(&ps_info.fontTable, &search); entry != NULL;
         entry = Tcl_NextHashEntry(&search)) {
      Tcl_AppendResult(wi->interp, "%%IncludeResource: font ",
      Tcl_GetHashKey(&ps_info.fontTable, entry), "\n", (char *) NULL);
    }
    Tcl_AppendResult(wi->interp, "%%EndSetup\n\n", (char *) NULL);

    /*
     *-----------------------------------------------------------
     * Page setup:  move to page positioning point, rotate if
     * needed, set scale factor, offset for proper anchor position,
     * and set clip region.
     *-----------------------------------------------------------
     */
    Tcl_AppendResult(wi->interp, "%%Page: 1 1\n", "save\n", (char *) NULL);
    sprintf(string, "%.1f %.1f translate\n", ps_info.pageX, ps_info.pageY);
    Tcl_AppendResult(wi->interp, string, (char *) NULL);
    if (ps_info.rotate) {
      Tcl_AppendResult(wi->interp, "90 rotate\n", (char *) NULL);
    }
    sprintf(string, "%.4g %.4g scale\n", ps_info.scale, -ps_info.scale);
    Tcl_AppendResult(wi->interp, string, (char *) NULL);
    sprintf(string, "%d %d translate\n", delta_x - ps_info.x, delta_y);
    Tcl_AppendResult(wi->interp, string, (char *) NULL);
    /*
     * Save the base matrix for further reference.
     */
    Tcl_AppendResult(wi->interp, "/InitialTransform matrix currentmatrix def\n", NULL);

    sprintf(string, "%d %.15g moveto %d %.15g lineto %d %.15g lineto %d %.15g",
            ps_info.x, Tk_PostscriptY((double) ps_info.y, (Tk_PostscriptInfo) &ps_info),
            ps_info.x2, Tk_PostscriptY((double) ps_info.y, (Tk_PostscriptInfo) &ps_info),
            ps_info.x2, Tk_PostscriptY((double) ps_info.y2, (Tk_PostscriptInfo) &ps_info),
            ps_info.x, Tk_PostscriptY((double) ps_info.y2, (Tk_PostscriptInfo) &ps_info));
    Tcl_AppendResult(wi->interp, string, " lineto closepath clip newpath\n", (char *) NULL);
  }
  if (ps_info.chan != NULL) {
    Tcl_Write(ps_info.chan, Tcl_GetStringResult(wi->interp), -1);
    Tcl_ResetResult(wi->interp);
  }

  /*
   *---------------------------------------------------------------------
   * Iterate through all the items, having each relevant one draw itself.
   * Quit if any of the items returns an error.
   *---------------------------------------------------------------------
   */
  result = wi->top_group->class->PostScript(wi->top_group, False, &ps_info.bbox);
  if (result == TCL_ERROR) {
    goto cleanup;
  }

  /*
   *---------------------------------------------------------------------
   * Output page-end information, such as commands to print the page
   * and document trailer stuff.
   *---------------------------------------------------------------------
   */
  if (ps_info.prolog) {
    Tcl_AppendResult(wi->interp, "restore showpage\n\n", "%%Trailer\nend\n%%EOF\n",
                     (char *) NULL);
  }
  if (ps_info.chan != NULL) {
    Tcl_Write(ps_info.chan, Tcl_GetStringResult(wi->interp), -1);
    Tcl_ResetResult(wi->interp);
  }

  /*
   * Clean up ps_info to release malloc'ed stuff.
   */
  cleanup:
  if (ps_info.pageXString != NULL) {
    ckfree(ps_info.pageXString);
  }
  if (ps_info.pageYString != NULL) {
    ckfree(ps_info.pageYString);
  }
  if (ps_info.pageWidthString != NULL) {
    ckfree(ps_info.pageWidthString);
  }
  if (ps_info.pageHeightString != NULL) {
    ckfree(ps_info.pageHeightString);
  }
  if (ps_info.fontVar != NULL) {
    ckfree(ps_info.fontVar);
  }
  if (ps_info.colorVar != NULL) {
    ckfree(ps_info.colorVar);
  }
  if (ps_info.colorMode != NULL) {
    ckfree(ps_info.colorMode);
  }
  if (ps_info.fileName != NULL) {
    ckfree(ps_info.fileName);
  }
  if ((ps_info.chan != NULL) && (ps_info.channelName == NULL)) {
  Tcl_Close(wi->interp, ps_info.chan);
  }
  if (ps_info.channelName != NULL) {
    ckfree(ps_info.channelName);
  }
  Tcl_DeleteHashTable(&ps_info.fontTable);
  wi->ps_info = (Tk_PostscriptInfo) old_info;
  return result;
}

void
ZnFlushPsChan(Tcl_Interp        *interp,
              Tk_PostscriptInfo ps_info) {
  TkPostscriptInfo  *psi = (TkPostscriptInfo *) ps_info;
  if (psi->chan != NULL) {
    Tcl_Write(psi->chan, Tcl_GetStringResult(interp), -1);
    Tcl_ResetResult(interp);
  }
}

int
ZnPostscriptOutline(Tcl_Interp        *interp,
                    Tk_PostscriptInfo ps_info,
                    Tk_Window         tkwin,
                    ZnDim             line_width,
                    ZnLineStyle       line_style,
                    ZnGradient        *line_color,
                    ZnImage           line_pattern)
{
  char string[41];
  char dashed[] = { 8 };
  char dotted[] = { 2, 5 };
  char mixed[] = { 8, 5, 2, 5 };
  char *pattern = NULL;
  int patlen = 0;

  sprintf(string, "%.15g setlinewidth\n", (double) line_width);
  Tcl_AppendResult(interp, string, NULL);
  /*
   * Setup the line style. It is dependent on the line
   * width.
   */
  switch (line_style) {
    case ZN_LINE_DOTTED:
      pattern = dotted;
      patlen = sizeof(dotted)/sizeof(char);
      break;
    case ZN_LINE_DASHED:
      pattern = dashed;
      patlen = sizeof(dashed)/sizeof(char);
      break;
    case ZN_LINE_MIXED:
      pattern = mixed;
      patlen = sizeof(mixed)/sizeof(char);
      break;
  }
  if (pattern) {
    sprintf(string, "[%d", ((*pattern++) * (int) line_width) & 0xff);
    while (--patlen) {
      sprintf(string+strlen(string), " %d", ((*pattern++) * (int) line_width) & 0xff);
    }
    Tcl_AppendResult(interp, string, NULL);
    sprintf(string, "] %d setdash\n", 0 /* dash offset */);
    Tcl_AppendResult(interp, string, NULL);
  }
  if (Tk_PostscriptColor(interp, ps_info,
                         ZnGetGradientColor(line_color, 0.0, NULL)) != TCL_OK) {
    return TCL_ERROR;
  }
  if (line_pattern != ZnUnspecifiedImage) {
    Tcl_AppendResult(interp, "StrokeClip ", NULL);
    if (Tk_PostscriptStipple(interp, tkwin, ps_info,
                             ZnImagePixmap(line_pattern, tkwin)) != TCL_OK) {
      return TCL_ERROR;
    }
  }
  else {
    Tcl_AppendResult(interp, "stroke\n", NULL);
  }
  
  return TCL_OK;
}

/*
 * Emit PostScript to describe a bitmap as a string possibly
 * spliting it in parts due to the limited length of PostScript
 * strings.
 * This function emit the common code for ZnPostscriptBitmap and
 * ZnPostscriptStipple.
 */
static int
EmitPSBitmap()
{
}

int
ZnPostscriptStipple(Tcl_Interp          *interp,
                    Tk_Window           tkwin,
                    Tk_PostscriptInfo   ps_info,
                    ZnImage             bitmap)
{
  return TCL_OK;
}

int
ZnPostscriptBitmap(Tcl_Interp        *interp,
                   Tk_Window         tkwin,
                   Tk_PostscriptInfo ps_info,
                   ZnImage           bitmap,
                   ZnReal            x,
                   ZnReal            y,
                   int               width,
                   int               height)
{
  char buffer[100 + TCL_DOUBLE_SPACE * 2 + TCL_INTEGER_SPACE * 4];
  int rows_at_once, rows_this_time, cur_row;

  if (width > 60000) {
    Tcl_ResetResult(interp);
    Tcl_AppendResult(interp, "can't generate Postscript",
                     " for bitmaps more than 60000 pixels wide", NULL);
    return TCL_ERROR;
  }
  rows_at_once = 60000/width;
  if (rows_at_once < 1) {
    rows_at_once = 1;
  }
  sprintf(buffer, "%.15g %.15g translate\n", x, y + height);
  Tcl_AppendResult(interp, buffer, NULL);
  for (cur_row = 0; cur_row < height; cur_row += rows_at_once) {
    rows_this_time = rows_at_once;
    if (rows_this_time > (height - cur_row)) {
      rows_this_time = height - cur_row;
    }
    sprintf(buffer, "0 -%.15g translate\n%d %d true matrix {\n",
            (double) rows_this_time, width, rows_this_time);
    Tcl_AppendResult(interp, buffer, NULL);
    if (Tk_PostscriptBitmap(interp, tkwin, ps_info,  ZnImagePixmap(bitmap, tkwin),
                            0, cur_row, width, rows_this_time) != TCL_OK) {
      return TCL_ERROR;
    }
    Tcl_AppendResult(interp, "\n} imagemask\n", (char *) NULL);
  }

  return TCL_OK;
}

void
ZnPostscriptString(Tcl_Interp   *interp,
                   char         *str,
                   int          num_bytes)
{
#ifndef PTK_800

  int         used, len, clen;
  int         c, bytecount = 0;
  CONST char  *p, *last_p, *glyphname;
  Tcl_UniChar ch;
  char        charbuf[5];
#define MAXUSE 500
  char        buf[MAXUSE+30];

	used = 0;
	buf[used++] = '[';
	buf[used++] = '(';
  len = num_bytes;
  p = str;
  while (len) {
    clen = Tcl_UtfToUniChar(p, &ch);
    last_p = p;
    p += clen;
    len -= clen;
    /*
     * INTL: For now we just treat the characters as binary
     * data and display the lower byte.  Eventually this should
     * be revised to handle international postscript fonts.
     */
    Tcl_UtfToExternal(interp, NULL, last_p, clen, 0, NULL,
                      charbuf, 4, NULL, &bytecount, NULL);
    if (bytecount == 1) {
      c = UCHAR(charbuf[0]);
      if ((c == '(') || (c == ')') || (c == '\\') ||
          (c < 0x20) || (c >= UCHAR(0x7f))) {
        /*
         * Tricky point:  the "03" is necessary in the sprintf
         * below, so that a full three digits of octal are
         * always generated.  Without the "03", a number
         * following this sequence could be interpreted by
         * Postscript as part of this sequence.
         */
        sprintf(buf + used, "\\%03o", c);
        used += 4;
      }
      else {
        buf[used++] = c;
      }
    }
    else {
      /* This character doesn't belong to system character set.
       * So, we must use full glyph name */
      sprintf(charbuf, "%04X", ch); /* endianness? */
      if ((glyphname = Tcl_GetVar2(interp, "::tk::psglyphs", charbuf, 0))) {
        if ((used > 0) && (buf[used-1] == '(')) {
          --used;
        }
        else {
          buf[used++] = ')';
        }
        if ((used + strlen(glyphname)) >= MAXUSE) {
          buf[used] = '\0';
          Tcl_AppendResult(interp, buf, NULL);
          used = 0;
        }
        buf[used++] = '/';
        while(*glyphname) {
          buf[used++] = *glyphname++ ;
        }
        buf[used++] = '(';
      }
    }
    if (used >= MAXUSE) {
      buf[used] = '\0';
      Tcl_AppendResult(interp, buf, NULL);
      used = 0;
    }
  }
  buf[used++] = ')';
  buf[used++] = ']';
  buf[used++] = '\n';
  buf[used] = '\0';
  Tcl_AppendResult(interp, buf, NULL);

#endif
}

int
ZnPostscriptTile(Tcl_Interp        *interp,
                 Tk_Window         win,
                 Tk_PostscriptInfo ps_info,
                 ZnImage           image)
{
  char path[150];
  int  w, h;

  ZnSizeOfImage(image, &w, &h);
  Tcl_AppendResult(interp, "<< /PatternType 1 /PaintType 1 /TilingType 1\n", NULL);
  sprintf(path, "  /BBox [%.15g %.15g %.15g %.15g] /XStep %.15g /YStep %.15g\n",
          0.0, (double) h, (double) w, 0.0, (double) w, (double) h);
  Tcl_AppendResult(interp, path, "  /PaintProc { begin\n", NULL);

  /*
   * On ne peut pas reprendre le code de Tk_PostscriptImage,
   * il génère une image inline impropre à l'inclusion dans
   * une procedure de tuilage. C'est d'ailleurs un problème :
   * Une string postscript ne doit pas dépasser 65K.
   */
  if (Tk_PostscriptImage(ZnImageTkImage(image), interp, win, ps_info, 0, 0, w, h, 0) != TCL_OK) {
    return TCL_ERROR;
  }

  Tcl_AppendResult(interp, "end } bind >> matrix makepattern setpattern fill\n", NULL);

  return TCL_OK;
}

void
ZnPostscriptTrace(ZnItem item,
                  ZnBool enter)
{
  ZnWInfo *wi = item->wi;
  char    buf[100];

  if (wi->debug) {
    sprintf(buf, "%%%%%%%% %s for %s %d %%%%%%%%\n",
            enter ? "Code" : "End of code", item->class->name, item->id);
    Tcl_AppendResult(wi->interp, buf, NULL);
  }
}

int
ZnPostscriptGradient(Tcl_Interp        *interp,
                     Tk_PostscriptInfo ps_info,
                     ZnGradient        *gradient,
                     ZnPoint           *quad,
                     ZnPoly            *poly)
{
  unsigned int    i;
  char            path[150];
  ZnPoint         p, center, extent;
  ZnGradientColor *gc1, *gc2;

  if (gradient->type == ZN_CONICAL_GRADIENT || gradient->type == ZN_PATH_GRADIENT) {
    return TCL_OK;
  }

  Tcl_AppendResult(interp, "<< /PatternType 2 /Shading\n", NULL);

  switch (gradient->type) {
    case ZN_AXIAL_GRADIENT:
      /*
       * Fill the rectangle defined by quad with
       * the axial gradient.
       */
      switch (gradient->angle) {
        case 0:
          center = quad[0];
          extent = quad[1];
        case 90:
          center = quad[0];
          extent = quad[3];
          break;
        case 180:
          center = quad[1];
          extent = quad[0];
          break;
        case 270:
          center = quad[3];
          extent = quad[0];
          break;
      }
      Tcl_AppendResult(interp,
                       "  << /ShadingType 2 /ColorSpace /DeviceRGB /Extend [true true] ",
                       NULL); 
      sprintf(path, "/Coords [%.15g %.15g %.15g %.15g]\n",
              quad[0].x, quad[0].y, quad[1].x, quad[1].y);
      Tcl_AppendResult(interp, path, NULL);
      break;
    case ZN_RADIAL_GRADIENT:
      /*
       * On ne peut pas représenter un dégradé radial ou conique
       * anamorphique si on n'inclu pas la transformation dans le
       * PostScript résultant. PostScript ne peut décrire que des
       * dégradés circulaires. La seule solution rapide est d'utiliser
       * comme dans l'item Triangles une trame de triangles (Shading
       * type 4).
       */
      p.x = p.y = 0;
      ZnTransformPoint((ZnTransfo *) quad, &p, &center);
      p.x = 1.0;
      ZnTransformPoint((ZnTransfo *) quad, &p, &extent);
      Tcl_AppendResult(interp,
                       "  << /ShadingType 3 /ColorSpace /DeviceRGB /Extend [true true] ",
                       NULL); 
      sprintf(path, "/Coords [%.15g %.15g %.15g %.15g %.15g %.15g]\n",
              center.x, center.y, 0.0, center.x, center.y, ABS(center.x-extent.x));
      printf("center %g %g, radius %g\n", center.x, center.y, ABS(center.x-extent.x));
      Tcl_AppendResult(interp, path, NULL);
      break;
    case ZN_CONICAL_GRADIENT:
      break;
    case ZN_PATH_GRADIENT:
      break;
  }

  Tcl_AppendResult(interp, "    /Function << ", NULL);
  Tcl_AppendResult(interp, "/FunctionType 3\n", NULL);
  Tcl_AppendResult(interp, "      /Domain [0 1] /Bounds [", NULL);
  for (i = 1; i < gradient->num_actual_colors-1; i++) {
    sprintf(path, "%.4g ", gradient->actual_colors[i].position/100.0);
    Tcl_AppendResult(interp, path, NULL);
  }
  Tcl_AppendResult(interp, "] /Encode [", NULL);
  for (i = 0; i < gradient->num_actual_colors-1; i++) {
    Tcl_AppendResult(interp, "0 1 ", NULL);
  }
  Tcl_AppendResult(interp, "]\n      /Functions [\n", NULL);
  for (i = 0, gc1 = gradient->actual_colors; i < gradient->num_actual_colors-1; i++) {
    gc2 = gc1 + 1;
    Tcl_AppendResult(interp, "      << /FunctionType 2 /Domain [0 1] /N 1 ", NULL);
    sprintf(path, "/C0 [%.8g %.8g %.8g] /C1 [%.8g %.8g %.8g] >>\n",
            gc1->rgb->red/65535.0, gc1->rgb->green/65535.0, gc1->rgb->blue/65535.0,
            gc2->rgb->red/65535.0, gc2->rgb->green/65535.0, gc2->rgb->blue/65535.0);
    Tcl_AppendResult(interp, path, NULL);
    gc1 = gc2;
  }
  Tcl_AppendResult(interp, "      ] >>\n", NULL);
  Tcl_AppendResult(interp, "  >> >>\n", NULL);
  Tcl_AppendResult(interp, "matrix makepattern setpattern fill\n", NULL);

  return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * TkImageGetColor --
 *
 *	This procedure converts a pixel value to three floating
 *      point numbers, representing the amount of red, green, and 
 *      blue in that pixel on the screen.  It makes use of colormap
 *      data passed as an argument, and should work for all Visual
 *      types.
 *
 *	This implementation is bogus on Windows because the colormap
 *	data is never filled in.  Instead all postscript generated
 *	data coming through here is expected to be RGB color data.
 *	To handle lower bit-depth images properly, XQueryColors
 *	must be implemented for Windows.
 *
 * Results:
 *	Returns red, green, and blue color values in the range 
 *      0 to 1.  There are no error returns.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
/*
 * The following definition is used in generating postscript for images
 * and windows.
 */
typedef struct TkColormapData {	/* Hold color information for a window */
    int separated;		/* Whether to use separate color bands */
    int color;			/* Whether window is color or black/white */
    int ncolors;		/* Number of color values stored */
    XColor *colors;		/* Pixel value -> RGB mappings */
    int red_mask, green_mask, blue_mask;	/* Masks and shifts for each */
    int red_shift, green_shift, blue_shift;	/* color band */
} TkColormapData;

#ifdef WIN32
#include <windows.h>

/*
 * We could just define these instead of pulling in windows.h.
 #define GetRValue(rgb)	((BYTE)(rgb))
 #define GetGValue(rgb)	((BYTE)(((WORD)(rgb)) >> 8))
 #define GetBValue(rgb)	((BYTE)((rgb)>>16))
*/
#else
#define GetRValue(rgb)	((rgb & cdata->red_mask) >> cdata->red_shift)
#define GetGValue(rgb)	((rgb & cdata->green_mask) >> cdata->green_shift)
#define GetBValue(rgb)	((rgb & cdata->blue_mask) >> cdata->blue_shift)
#endif

#if defined(WIN32) || defined(MAC_OSX_TK)
static void
TkImageGetColor(cdata, pixel, red, green, blue)
    TkColormapData *cdata;              /* Colormap data */
    unsigned long pixel;                /* Pixel value to look up */
    double *red, *green, *blue;         /* Color data to return */
{
    *red   = (double) GetRValue(pixel) / 255.0;
    *green = (double) GetGValue(pixel) / 255.0;
    *blue  = (double) GetBValue(pixel) / 255.0;
}
#else
static void
TkImageGetColor(cdata, pixel, red, green, blue)
    TkColormapData *cdata;              /* Colormap data */
    unsigned long pixel;                /* Pixel value to look up */
    double *red, *green, *blue;         /* Color data to return */
{
    if (cdata->separated) {
	int r = GetRValue(pixel);
	int g = GetGValue(pixel);
	int b = GetBValue(pixel);
	*red   = cdata->colors[r].red / 65535.0;
	*green = cdata->colors[g].green / 65535.0;
	*blue  = cdata->colors[b].blue / 65535.0;
    } else {
	*red   = cdata->colors[pixel].red / 65535.0;
	*green = cdata->colors[pixel].green / 65535.0;
	*blue  = cdata->colors[pixel].blue / 65535.0;
    }
}
#endif

/*
 *--------------------------------------------------------------
 *
 * ZnPostscriptXImage --
 *
 *	This procedure is called to output the contents of an
 *	XImage in Postscript, using a format appropriate for the 
 *      current color mode (i.e. one bit per pixel in monochrome, 
 *      one byte per pixel in gray, and three bytes per pixel in
 *      color).
 *
 * Results:
 *	Returns a standard Tcl return value.  If an error occurs
 *	then an error message will be left in interp->result.
 *	If no error occurs, then additional Postscript will be
 *	appended to interp->result.
 *
 * Side effects:
 *	None.
 *
 *--------------------------------------------------------------
 */
/* TODO beaucoup de code à partager avec photo ci dessous
 * sans compter qu'il faut une autre fonction pour emettre
 * du code pour les tiling patterns.
 * Il faudrait un operateur central qui emette dans une
 * string postscript des bandes d'image afin de respecter
 * la taille max des strings (on peut aussi mettre les
 * bandes dans un tableau au préalable). Cet opérateur
 * gére le niveau de couleur (0, 1, ...) et sait gérer les
 * bits de transparence Postscript 3 en option.
 */
int
ZnPostscriptXImage(Tcl_Interp        *interp,
                   Tk_Window         tkwin,
                   Tk_PostscriptInfo psInfo,
                   XImage            *ximage,
                   int               x,
                   int               y,
                   int               width,
                   int               height)
{
  TkPostscriptInfo *psi = (TkPostscriptInfo *) psInfo;
  char             buffer[256];
  int              xx, yy, band, maxRows;
  double           red, green, blue;
  int              bytesPerLine=0, maxWidth=0;
  int              level = psi->colorLevel;
  Colormap         cmap;
  int              i, ncolors;
  Visual           *visual;
  TkColormapData   cdata;

  if (psi->prepass) {
    return TCL_OK;
  }

  Tcl_AppendResult(interp, "%%%%%% Start of ZnPostscriptXImage\n", NULL);

  cmap = Tk_Colormap(tkwin);
  visual = Tk_Visual(tkwin);

  /*
   * Obtain information about the colormap, ie the mapping between
   * pixel values and RGB values.  The code below should work
   * for all Visual types.
   */
  ncolors = visual->map_entries;
  cdata.colors = (XColor *) ckalloc(sizeof(XColor) * ncolors);
  cdata.ncolors = ncolors;

  if ((visual->class == DirectColor) || (visual->class == TrueColor)) {
    cdata.separated = 1;
    cdata.red_mask = visual->red_mask;
    cdata.green_mask = visual->green_mask;
    cdata.blue_mask = visual->blue_mask;
    cdata.red_shift = 0;
    cdata.green_shift = 0;
    cdata.blue_shift = 0;
    while ((0x0001 & (cdata.red_mask >> cdata.red_shift)) == 0) {
      cdata.red_shift ++;
    }
    while ((0x0001 & (cdata.green_mask >> cdata.green_shift)) == 0) {
      cdata.green_shift ++;
    }
    while ((0x0001 & (cdata.blue_mask >> cdata.blue_shift)) == 0) {
      cdata.blue_shift ++;
    }
    for (i = 0; i < ncolors; i ++) {
      cdata.colors[i].pixel = ((i << cdata.red_shift) & cdata.red_mask) |
        ((i << cdata.green_shift) & cdata.green_mask) |
        ((i << cdata.blue_shift) & cdata.blue_mask);
    }
  }
  else {
    cdata.separated=0;
    for (i = 0; i < ncolors; i ++) {
      cdata.colors[i].pixel = i;
    }
  }
  if ((visual->class == StaticGray) || (visual->class == GrayScale)) {
    cdata.color = 0;
  }
  else {
    cdata.color = 1;
  }

  XQueryColors(Tk_Display(tkwin), cmap, cdata.colors, ncolors);

  /*
   * Figure out which color level to use (possibly lower than the 
   * one specified by the user).  For example, if the user specifies
   * color with monochrome screen, use gray or monochrome mode instead. 
   */

  if (!cdata.color && level == 2) {
    level = 1;
  }
  if (!cdata.color && cdata.ncolors == 2) {
    level = 0;
  }

  /*
   * Check that at least one row of the image can be represented
   * with a string less than 64 KB long (this is a limit in the 
   * Postscript interpreter).
   */
  switch (level) {
    case 0: bytesPerLine = (width + 7) / 8;  maxWidth = 240000;  break;
    case 1: bytesPerLine = width;  maxWidth = 60000;  break;
    case 2: bytesPerLine = 3 * width;  maxWidth = 20000;  break;
  }

  if (bytesPerLine > 60000) {
    Tcl_ResetResult(interp);
    sprintf(buffer, "Can't generate Postscript for images more than %d pixels wide", maxWidth);
    Tcl_AppendResult(interp, buffer, (char *) NULL);
    ckfree((char *) cdata.colors);
    return TCL_ERROR;
  }

  maxRows = 60000 / bytesPerLine;

  for (band = height-1; band >= 0; band -= maxRows) {
    int rows = (band >= maxRows) ? maxRows : band + 1;
    int lineLen = 0;
    switch (level) {
      case 0:
        sprintf(buffer, "%d %d 1 matrix {\n<", width, rows);
        Tcl_AppendResult(interp, buffer, (char *) NULL);
        break;
      case 1:
        sprintf(buffer, "%d %d 8 matrix {\n<", width, rows);
        Tcl_AppendResult(interp, buffer, (char *) NULL);
        break;
      case 2:
        sprintf(buffer, "%d %d 8 matrix {\n<", width, rows);
        Tcl_AppendResult(interp, buffer, (char *) NULL);
        break;
    }
    for (yy = band; yy > band - rows; yy--) {
      switch (level) {
        case 0:
          {
            /*
             * Generate data for image in monochrome mode.
             * No attempt at dithering is made--instead, just
             * set a threshold.
             */
            unsigned char mask=0x80;
            unsigned char data=0x00;
            for (xx = x; xx< x+width; xx++) {
              TkImageGetColor(&cdata, XGetPixel(ximage, xx, yy),
                              &red, &green, &blue);
              if (0.30 * red + 0.59 * green + 0.11 * blue > 0.5)
                data |= mask;
              mask >>= 1;
              if (mask == 0) {
                sprintf(buffer, "%02X", data);
                Tcl_AppendResult(interp, buffer, (char *) NULL);
                lineLen += 2;
                if (lineLen > 60) {
                  lineLen = 0;
                  Tcl_AppendResult(interp, "\n", (char *) NULL);
                }
                mask=0x80;
                data=0x00;
              }
            }
            if ((width % 8) != 0) {
              sprintf(buffer, "%02X", data);
              Tcl_AppendResult(interp, buffer, (char *) NULL);
              mask=0x80;
              data=0x00;
            }
            break;
          }
        case 1:
          {
            /*
             * Generate data in gray mode--in this case, take a 
             * weighted sum of the red, green, and blue values.
             */
            for (xx = x; xx < x+width; xx ++) {
              TkImageGetColor(&cdata, XGetPixel(ximage, xx, yy),
                              &red, &green, &blue);
              sprintf(buffer, "%02X", (int) floor(0.5 + 255.0 *
                                                  (0.30 * red + 0.59 * green + 0.11 * blue)));
              Tcl_AppendResult(interp, buffer, (char *) NULL);
              lineLen += 2;
              if (lineLen > 60) {
                lineLen = 0;
                Tcl_AppendResult(interp, "\n", (char *) NULL);
              }
            }
            break;
          }
        case 2:
          {
            /*
             * Finally, color mode.  Here, just output the red, green,
             * and blue values directly.
             */
            for (xx = x; xx < x+width; xx++) {
              TkImageGetColor(&cdata, XGetPixel(ximage, xx, yy),
                              &red, &green, &blue);
              sprintf(buffer, "%02X%02X%02X",
                      (int) floor(0.5 + 255.0 * red),
                      (int) floor(0.5 + 255.0 * green),
                      (int) floor(0.5 + 255.0 * blue));
              Tcl_AppendResult(interp, buffer, (char *) NULL);
              lineLen += 6;
              if (lineLen > 60) {
                lineLen = 0;
                Tcl_AppendResult(interp, "\n", (char *) NULL);
              }
            }
            break;
          }
      }
    }
    switch (level) {
      case 0: sprintf(buffer, ">\n} image\n"); break;
      case 1: sprintf(buffer, ">\n} image\n"); break;
      case 2: sprintf(buffer, ">\n} false 3 colorimage\n"); break;
    }
    Tcl_AppendResult(interp, buffer, (char *) NULL);
    sprintf(buffer, "0 %d translate\n", rows);
    Tcl_AppendResult(interp, buffer, (char *) NULL);
  }
  ckfree((char *) cdata.colors);

  Tcl_AppendResult(interp, "%%%%%% End of ZnPostscriptXImage\n", NULL);

  return TCL_OK;
}

/*
 *--------------------------------------------------------------
 *
 * ZnPostscriptPhoto --
 *
 *  This procedure is called to output the contents of a
 *  photo image in Postscript, using a format appropriate for
 *  the requested postscript color mode (i.e. one byte per pixel
 *  in gray, and three bytes per pixel in color).
 *
 * Results:
 *  Returns a standard Tcl return value.  If an error occurs
 *  then an error message will be left in interp->result.
 *  If no error occurs, then additional Postscript will be
 *  appended to the interpreter's result.
 *
 * Side effects:
 *  None.
 *
 *--------------------------------------------------------------
 */
int
ZnPostscriptPhoto(Tcl_Interp         *interp,
                  Tk_PhotoImageBlock *blockPtr,
                  Tk_PostscriptInfo  ps_info,
                  int                width,
                  int                height)
{
  TkPostscriptInfo *psi = (TkPostscriptInfo *) ps_info;
  static int       codeIncluded = 0;
  unsigned char    *pixelPtr;
  char             buffer[256], cspace[40], decode[40];
  int              bpc;
  int              xx, yy, lineLen;
  float            red, green, blue;
  int              alpha;
  int              bytesPerLine=0, maxWidth=0;
  unsigned char    opaque = 255;
  unsigned char    *alphaPtr;
  int              alphaOffset, alphaPitch, alphaIncr;

  if (psi->prepass) {
    codeIncluded = 0;
    return TCL_OK;
  }

  /*
   * Define the "TkPhoto" function, which is a modified version
   * of the original "transparentimage" function posted
   * by ian@five-d.com (Ian Kemmish) to comp.lang.postscript.
   * For a monochrome colorLevel this is a slightly different
   * version that uses the imagemask command instead of image.
   */
  if( !codeIncluded && (psi->colorLevel != 0) ) {
    /*
     * Color and gray-scale code.
     */
    codeIncluded = !0;
    Tcl_AppendResult(interp,
                     "/TkPhoto { \n",
                     "  gsave \n",
                     "  32 dict begin \n",
                     "  /tinteger exch def \n",
                     "  /transparent 1 string def \n",
                     "  transparent 0 tinteger put \n",
                     "  /olddict exch def \n",
                     "  olddict /DataSource get dup type /filetype ne { \n",
                     "    olddict /DataSource 3 -1 roll \n",
                     "    0 () /SubFileDecode filter put \n",
                     "  } { \n",
                     "    pop \n",
                     "  } ifelse \n",
                     "  /newdict olddict maxlength dict def \n",
                     "  olddict newdict copy pop \n",
                     "  /w newdict /Width get def \n",
                     "  /crpp newdict /Decode get length 2 idiv def \n",
                     "  /str w string def \n",
                     "  /pix w crpp mul string def \n",
                     "  /substrlen 2 w log 2 log div floor exp cvi def \n",
                     "  /substrs [ \n",
                     "  { \n",
                     "     substrlen string \n",
                     "     0 1 substrlen 1 sub { \n",
                     "       1 index exch tinteger put \n",
                     "     } for \n",
                     "     /substrlen substrlen 2 idiv def \n",
                     "     substrlen 0 eq {exit} if \n",
                     "  } loop \n",
                     "  ] def \n",
                     "  /h newdict /Height get def \n",
                     "  1 w div 1 h div matrix scale \n",
                     "  olddict /ImageMatrix get exch matrix concatmatrix \n",
                     "  matrix invertmatrix concat \n",
                     "  newdict /Height 1 put \n",
                     "  newdict /DataSource pix put \n",
                     "  /mat [w 0 0 h 0 0] def \n",
                     "  newdict /ImageMatrix mat put \n",
                     "  0 1 h 1 sub { \n",
                     "    mat 5 3 -1 roll neg put \n",
                     "    olddict /DataSource get str readstring pop pop \n",
                     "    /tail str def \n",
                     "    /x 0 def \n",
                     "    olddict /DataSource get pix readstring pop pop \n",
                     "    { \n",
                     "      tail transparent search dup /done exch not def \n",
                     "      {exch pop exch pop} if \n",
                     "      /w1 exch length def \n",
                     "      w1 0 ne { \n",
                     "        newdict /DataSource ",
                     " pix x crpp mul w1 crpp mul getinterval put \n",
                     "        newdict /Width w1 put \n",
                     "        mat 4 x neg put \n",
                     "        /x x w1 add def \n",
                     "        newdict image \n",
                     "        /tail tail w1 tail length w1 sub getinterval def \n",
                     "      } if \n",
                     "      done {exit} if \n",
                     "      tail substrs { \n",
                     "        anchorsearch {pop} if \n",
                     "      } forall \n",
                     "      /tail exch def \n",
                     "      tail length 0 eq {exit} if \n",
                     "      /x w tail length sub def \n",
                     "    } loop \n",
                     "  } for \n",
                     "  end \n",
                     "  grestore \n",
                     "} bind def \n\n\n", (char *) NULL);
  }
  else if (!codeIncluded && (psi->colorLevel == 0)) {
    /*
     * Monochrome-only code
     */
    codeIncluded = !0;
    Tcl_AppendResult(interp,
                     "/TkPhoto { \n",
                     "  gsave \n",
                     "  32 dict begin \n",
                     "  /dummyInteger exch def \n",
                     "  /olddict exch def \n",
                     "  olddict /DataSource get dup type /filetype ne { \n",
                     "    olddict /DataSource 3 -1 roll \n",
                     "    0 () /SubFileDecode filter put \n",
                     "  } { \n",
                     "    pop \n",
                     "  } ifelse \n",
                     "  /newdict olddict maxlength dict def \n",
                     "  olddict newdict copy pop \n",
                     "  /w newdict /Width get def \n",
                     "  /pix w 7 add 8 idiv string def \n",
                     "  /h newdict /Height get def \n",
                     "  1 w div 1 h div matrix scale \n",
                     "  olddict /ImageMatrix get exch matrix concatmatrix \n",
                     "  matrix invertmatrix concat \n",
                     "  newdict /Height 1 put \n",
                     "  newdict /DataSource pix put \n",
                     "  /mat [w 0 0 h 0 0] def \n",
                     "  newdict /ImageMatrix mat put \n",
                     "  0 1 h 1 sub { \n",
                     "    mat 5 3 -1 roll neg put \n",
                     "    0.000 0.000 0.000 setrgbcolor \n",
                     "    olddict /DataSource get pix readstring pop pop \n",
                     "    newdict /DataSource pix put \n",
                     "    newdict imagemask \n",
                     "    1.000 1.000 1.000 setrgbcolor \n",
                     "    olddict /DataSource get pix readstring pop pop \n",
                     "    newdict /DataSource pix put \n",
                     "    newdict imagemask \n",
                     "  } for \n",
                     "  end \n",
                     "  grestore \n",
                     "} bind def \n\n\n", (char *) NULL);
  }

  /*
   * Check that at least one row of the image can be represented
   * with a string less than 64 KB long (this is a limit in the
   * Postscript interpreter).
   */
  switch (psi->colorLevel)
  {
    case 0: bytesPerLine = (width + 7) / 8;  maxWidth = 240000;  break;
    case 1: bytesPerLine = width;  maxWidth = 60000;  break;
    case 2: bytesPerLine = 3 * width;  maxWidth = 20000;  break;
  }
  if (bytesPerLine > 60000) {
    Tcl_ResetResult(interp);
    sprintf(buffer, "Can't generate Postscript for images more than %d pixels wide",
            maxWidth);
    Tcl_AppendResult(interp, buffer, (char *) NULL);
    return TCL_ERROR;
  }

  /*
   * Set up the postscript code except for the image-data stream.
   */
  switch (psi->colorLevel) {
    case 0: 
      strcpy( cspace, "/DeviceGray");
      strcpy( decode, "[1 0]");
      bpc = 1;
      break;
    case 1: 
      strcpy( cspace, "/DeviceGray");
      strcpy( decode, "[0 1]");
      bpc = 8;
      break;
    default:
      strcpy( cspace, "/DeviceRGB");
      strcpy( decode, "[0 1 0 1 0 1]");
      bpc = 8;
      break;
  }

  Tcl_AppendResult(interp, cspace, " setcolorspace\n\n", (char *) NULL);
  sprintf(buffer, "  /Width %d\n  /Height %d\n  /BitsPerComponent %d\n",
          width, height, bpc);
  Tcl_AppendResult(interp,
                   "<<\n  /ImageType 1\n", buffer,
                   "  /DataSource currentfile /ASCIIHexDecode filter\n", (char *) NULL);
  sprintf(buffer, "  /ImageMatrix [1 0 0 -1 0 %d]\n", height);
  Tcl_AppendResult(interp, buffer, "  /Decode ", decode, "\n>>\n1 TkPhoto\n", (char *) NULL);

  /*
   * Check the PhotoImageBlock information.
   * We assume that:
   *     if pixelSize is 1,2 or 4, the image is R,G,B,A;
   *     if pixelSize is 3, the image is R,G,B and offset[3] is bogus.
   */
  if (blockPtr->pixelSize == 3) {
    /*
     * No alpha information: the whole image is opaque.
     */
    alphaPtr = &opaque;
    alphaPitch = alphaIncr = alphaOffset = 0;
  }
  else {
    /*
     * Set up alpha handling.
     */
    alphaPtr = blockPtr->pixelPtr;
    alphaPitch = blockPtr->pitch;
    alphaIncr = blockPtr->pixelSize;
    alphaOffset = blockPtr->offset[3];
  }

  for (yy = 0, lineLen=0; yy < height; yy++) {
    switch (psi->colorLevel) {
      case 0:
        {
          /*
           * Generate data for image in monochrome mode.
           * No attempt at dithering is made--instead, just
           * set a threshold.
           * To handle transparencies we need to output two lines:
           * one for the black pixels, one for the white ones.
           */
          unsigned char mask=0x80;
          unsigned char data=0x00;
          for (xx = 0; xx< width; xx ++) {
            pixelPtr = blockPtr->pixelPtr + (yy * blockPtr->pitch) + (xx *blockPtr->pixelSize);

            red = pixelPtr[blockPtr->offset[0]];
            green = pixelPtr[blockPtr->offset[1]];
            blue = pixelPtr[blockPtr->offset[2]];

            alpha = *(alphaPtr + (yy * alphaPitch) + (xx * alphaIncr) + alphaOffset);

            /*
             * If pixel is less than threshold, then it is black.
             */
            if ((alpha != 0) && (0.3086 * red + 0.6094 * green + 0.082 * blue < 128)) {
              data |= mask;
            }
            mask >>= 1;
            if (mask == 0) {
              sprintf(buffer, "%02X", data);
              Tcl_AppendResult(interp, buffer, (char *) NULL);
              lineLen += 2;
              if (lineLen >= 60) {
                lineLen = 0;
                Tcl_AppendResult(interp, "\n", (char *) NULL);
              }
              mask=0x80;
              data=0x00;
            }
          }
          if ((width % 8) != 0) {
            sprintf(buffer, "%02X", data);
            Tcl_AppendResult(interp, buffer, (char *) NULL);
            mask=0x80;
            data=0x00;
          }

          mask=0x80;
          data=0x00;
          for (xx = 0; xx< width; xx ++) {
            pixelPtr = blockPtr->pixelPtr + (yy * blockPtr->pitch) + (xx *blockPtr->pixelSize);

            red = pixelPtr[blockPtr->offset[0]];
            green = pixelPtr[blockPtr->offset[1]];
            blue = pixelPtr[blockPtr->offset[2]];

            alpha = *(alphaPtr + (yy * alphaPitch) + (xx * alphaIncr) + alphaOffset);

            /*
             * If pixel is greater than threshold, then it is white.
             */
            if ((alpha != 0) && (0.3086 * red + 0.6094 * green + 0.082 * blue >= 128)) {
              data |= mask;
            }
            mask >>= 1;
            if (mask == 0) {
              sprintf(buffer, "%02X", data);
              Tcl_AppendResult(interp, buffer, (char *) NULL);
              lineLen += 2;
              if (lineLen >= 60) {
                lineLen = 0;
                Tcl_AppendResult(interp, "\n", (char *) NULL);
              }
              mask=0x80;
              data=0x00;
            }
          }
          if ((width % 8) != 0) {
            sprintf(buffer, "%02X", data);
            Tcl_AppendResult(interp, buffer, (char *) NULL);
            mask=0x80;
            data=0x00;
          }
          break;
        }
      case 1:
        {
          /*
           * Generate transparency data.
           * We must prevent a transparent value of 0
           * because of a bug in some HP printers.
           */
          for (xx = 0; xx < width; xx ++) {
            alpha = *(alphaPtr + (yy * alphaPitch) + (xx * alphaIncr) + alphaOffset);
            sprintf(buffer, "%02X", alpha | 0x01);
            Tcl_AppendResult(interp, buffer, (char *) NULL);
            lineLen += 2;
            if (lineLen >= 60) {
              lineLen = 0;
              Tcl_AppendResult(interp, "\n", (char *) NULL);
            }
          }

          /*
           * Generate data in gray mode--in this case, take a 
           * weighted sum of the red, green, and blue values.
           */
          for (xx = 0; xx < width; xx ++) {
            pixelPtr = blockPtr->pixelPtr + (yy * blockPtr->pitch) + (xx *blockPtr->pixelSize);

            red = pixelPtr[blockPtr->offset[0]];
            green = pixelPtr[blockPtr->offset[1]];
            blue = pixelPtr[blockPtr->offset[2]];

            sprintf(buffer, "%02X",
                    (int) floor(0.5 + ( 0.3086 * red + 0.6094 * green + 0.0820 * blue)));
            Tcl_AppendResult(interp, buffer, (char *) NULL);
            lineLen += 2;
            if (lineLen >= 60) {
              lineLen = 0;
              Tcl_AppendResult(interp, "\n", (char *) NULL);
            }
          }
          break;
        }
      default:
        {
          /*
           * Generate transparency data.
           * We must prevent a transparent value of 0
           * because of a bug in some HP printers.
           */
          for (xx = 0; xx < width; xx ++) {
            alpha = *(alphaPtr + (yy * alphaPitch) + (xx * alphaIncr) + alphaOffset);
            sprintf(buffer, "%02X", alpha | 0x01);
            Tcl_AppendResult(interp, buffer, (char *) NULL);
            lineLen += 2;
            if (lineLen >= 60) {
              lineLen = 0;
              Tcl_AppendResult(interp, "\n", (char *) NULL);
            }
          }

          /*
           * Finally, color mode.  Here, just output the red, green,
           * and blue values directly.
           */
          for (xx = 0; xx < width; xx ++) {
            pixelPtr = blockPtr->pixelPtr + (yy * blockPtr->pitch) + (xx *blockPtr->pixelSize);

            sprintf(buffer, "%02X%02X%02X", pixelPtr[blockPtr->offset[0]],
                    pixelPtr[blockPtr->offset[1]], pixelPtr[blockPtr->offset[2]]);
            Tcl_AppendResult(interp, buffer, (char *) NULL);
            lineLen += 6;
            if (lineLen >= 60) {
              lineLen = 0;
              Tcl_AppendResult(interp, "\n", (char *) NULL);
            }
          }
          break;
        }
    }
  }

  Tcl_AppendResult(interp, ">\n", (char *) NULL);
  return TCL_OK;
}

int
ZnPostscriptImage(Tcl_Interp        *interp,
                  Tk_Window         tkwin,
                  Tk_PostscriptInfo ps_info,
                  ZnImage           image,
                  int               x,
                  int               y,
                  int               w,
                  int               h)
{
  int              result;
  XImage           *ximage;
  Tk_PhotoHandle   tkphoto;
  
  if (((TkPostscriptInfo *) ps_info)->prepass) {
    return TCL_OK;
  }

  tkphoto = ZnImageTkPhoto(image);
  if (tkphoto != NULL) {
    Tk_PhotoImageBlock block;

    Tk_PhotoGetImage(tkphoto, &block);
    block.pixelPtr += y * block.pitch + x * block.pixelSize;

    return ZnPostscriptPhoto(interp, &block, ps_info, w, h);
  }
  else {
    Pixmap    pix = ZnImagePixmap(image, tkwin);
    XGCValues values;
    GC        gc;

    if (pix == None) {
      /*
       * Pixmap not cached (probably working under GL).
       * Create a temporary pixmap.
       */
      pix = Tk_GetPixmap(Tk_Display(tkwin), Tk_WindowId(tkwin), w, h, Tk_Depth(tkwin));
      values.foreground = WhitePixelOfScreen(Tk_Screen(tkwin));
      gc = Tk_GetGC(tkwin, GCForeground, &values);
      if (gc != None) {
        XFillRectangle(Tk_Display(tkwin), pix, gc, 0, 0, (unsigned int) w, (unsigned int) h);
        Tk_FreeGC(Tk_Display(tkwin), gc);
      }
      Tk_RedrawImage(image, x, y, w, h, pix, 0, 0);
      Tk_FreePixmap(Tk_Display(tkwin), pix);
    }
    else {
      ximage = XGetImage(Tk_Display(tkwin), pix, 0, 0,
                         (unsigned int) w, (unsigned int) h, AllPlanes, ZPixmap);
    }
    if (ximage == NULL) {
      /* The XGetImage() function is apparently not
       * implemented on this system. Just ignore it.
       */
      return TCL_OK;
    }
    result = ZnPostscriptXImage(interp, tkwin, ps_info, ximage, x, y, w, h);
    XDestroyImage(ximage);
  }

  return result;
}

void
EmitPhotoImageData()
{
}


/*
 * TODO gradients, tuiles, reliefs, flêches, clipping.
 * TODO la fonction DrawText est buggée dans un environnement rotation
 *      l'erreur passe par un max autour de modulo 45°
 * TODO Bugs de placement sur le texte et les bordures des fields
 * TODO Problème : Si on utilise les transformations PostScript on
 *      génère un code plus concis et le rendu est potentiellement
 *      plus beau (on utilise les arcs et les beziers natifs) et on
 *      peut générer des dégradés identiques à ceux de zinc mais le
 *      tuilage/stencil, les flêches, l'épaisseur des lignes suivent
 *      la transformation.
 * TODO Le code gérant les images ne sait pas traiter le canal alpha.
 * TODO Inclure ici le code de gestion des stipples.
 * TODO Pour images et stipples le code doit prendre en compte le contexte
 *      X et/ou OpenGL.
 */ 
