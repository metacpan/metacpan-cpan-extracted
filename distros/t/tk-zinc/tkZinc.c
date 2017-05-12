/*
 * tkZinc.c -- Zinc widget for the Tk Toolkit. Main module.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Mon Feb  1 12:13:24 1999
 *
 * $Id: tkZinc.c,v 1.121 2005/11/25 15:23:07 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

/*
 * Some functions and code excerpts in this file are from tkCanvas.c
 * and thus copyrighted:
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994-1997 Sun Microsystems, Inc.
 * Copyright (c) 1998-1999 by Scriptics Corporation.
 *
 */

static const char rcs_id[]="$Id: tkZinc.c,v 1.121 2005/11/25 15:23:07 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";
static const char * const zinc_version = "zinc-version-" VERSION;


#include "Types.h"
#include "Geo.h"
#include "Item.h"
#include "Group.h"
#include "WidgetInfo.h"
#include "tkZinc.h"
#include "MapInfo.h"
#ifdef ATC
#include "OverlapMan.h"
#include "Track.h"
#endif
#include "Transfo.h"
#include "Image.h"
#include "Draw.h"
#include "Color.h"
#ifndef _WIN32
#include "perfos.h"
#endif

#include <GL/glu.h>
#include <ctype.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <X11/Xatom.h>
#if defined(_WIN32) && defined(PTK) && !defined(PTK_800)
#include <tkPlatDecls.m>
#endif


typedef struct _TagSearchExpr {
  struct _TagSearchExpr *next; /* for linked lists of expressions - used in bindings */
  Tk_Uid                uid;    /* the uid of the whole expression */
  Tk_Uid                *uids;  /* expresion compiled to an array of uids */
  int                   allocated; /* available space for array of uids */
  int                   length; /* length of expression */
  int                   index;  /* current position in expression evaluation */
  int                   match;  /* this expression matches event's item's tags*/
} TagSearchExpr;


#define SYMBOL_WIDTH 8
#define SYMBOL_HEIGHT 8
static unsigned char SYMBOLS_BITS[][SYMBOL_WIDTH*SYMBOL_HEIGHT/8] = {
  { 0x18, 0x18, 0x24, 0x24, 0x5a, 0x5a, 0x81, 0xff },
  { 0xff, 0x81, 0x99, 0xbd, 0xbd, 0x99, 0x81, 0xff },
  { 0x18, 0x24, 0x42, 0x99, 0x99, 0x42, 0x24, 0x18 },
  { 0x18, 0x3c, 0x5a, 0xff, 0xff, 0x5a, 0x3c, 0x18 },
  { 0x18, 0x24, 0x42, 0x81, 0x81, 0x42, 0x24, 0x18 },
  { 0x3c, 0x42, 0x81, 0x81, 0x81, 0x81, 0x42, 0x3c },
  { 0x18, 0x18, 0x24, 0x24, 0x42, 0x42, 0x81, 0xff },
  { 0xff, 0x81, 0x81, 0x81, 0x81, 0x81, 0x81, 0xff },
  { 0x18, 0x18, 0x3c, 0x3c, 0x66, 0x66, 0xff, 0xff },
  { 0xff, 0xff, 0xe7, 0xc3, 0xc3, 0xe7, 0xff, 0xff },
  { 0x18, 0x3c, 0x7e, 0xe7, 0xe7, 0x7e, 0x3c, 0x18 },
  { 0x18, 0x3c, 0x66, 0xc3, 0xc3, 0x66, 0x3c, 0x18 },
  { 0x18, 0x3c, 0x7e, 0xff, 0xff, 0x7e, 0x3c, 0x18 },
  { 0x3c, 0x7e, 0xff, 0xff, 0xff, 0xff, 0x7e, 0x3c },
  { 0x18, 0x18, 0x3c, 0x3c, 0x7e, 0x7e, 0xff, 0xff },
  { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff },
  { 0x18, 0x7e, 0x7e, 0xff, 0xff, 0x7e, 0x7e, 0x18 },
  { 0x18, 0x66, 0x42, 0x81, 0x81, 0x42, 0x66, 0x18 },
  { 0x00, 0x00, 0x18, 0x3c, 0x3c, 0x18, 0x00, 0x00 },
  { 0x00, 0x18, 0x3c, 0x7e, 0x7e, 0x3c, 0x18, 0x00 },
  { 0x18, 0x3c, 0x7e, 0xff, 0xff, 0x7e, 0x3c, 0x18 },
  { 0x81, 0x42, 0x24, 0x18, 0x18, 0x24, 0x42, 0x81 },
};

static unsigned char dither4x4[4][4] = {
  { 0, 8, 2, 10 },
  { 12, 4, 14, 6 },
  { 3, 11, 1, 9 },
  { 15, 7, 13, 5 }
};

static unsigned char bitmaps[ZN_NUM_ALPHA_STEPS][32][4];

static  Tk_Uid  all_uid;
static  Tk_Uid  current_uid;
static  Tk_Uid  and_uid;
static  Tk_Uid  or_uid;
static  Tk_Uid  xor_uid;
static  Tk_Uid  paren_uid;
static  Tk_Uid  end_paren_uid;
static  Tk_Uid  neg_paren_uid;
static  Tk_Uid  tag_val_uid;
static  Tk_Uid  neg_tag_val_uid;
static  Tk_Uid  dot_uid;
static  Tk_Uid  star_uid;

#ifdef GL
static  ZnGLContextEntry *gl_contexts = NULL;
#ifndef _WIN32
static  int             ZnMajorGlx, ZnMinorGlx;
static  int             ZnGLAttribs[] = {
  GLX_RGBA,
  GLX_DOUBLEBUFFER,
  GLX_RED_SIZE, 8,
  GLX_GREEN_SIZE, 8,
  GLX_BLUE_SIZE, 8,
  GLX_STENCIL_SIZE, 8,
  /*GLX_ALPHA_SIZE, 8,*/
  GLX_DEPTH_SIZE, 0,
  None
};
#endif
#endif
  
/*
 * Temporary object lists
 */
        ZnList          ZnWorkPoints;
        ZnList          ZnWorkXPoints;
        ZnList          ZnWorkStrings;
  
/*
 * Tesselator
 */
        ZnTess          ZnTesselator;


static  void PickCurrentItem _ANSI_ARGS_((ZnWInfo *wi, XEvent *event));
#ifdef PTK_800
static  int ZnReliefParse _ANSI_ARGS_((ClientData client_data, Tcl_Interp *interp,
                                       Tk_Window tkwin, Tcl_Obj *ovalue,
                                       char *widget_rec, int offset));
static  Tcl_Obj *ZnReliefPrint _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                            char *widget_rec, int offset,
                                            Tcl_FreeProc **free_proc));
static  int ZnGradientParse _ANSI_ARGS_((ClientData client_data, Tcl_Interp *interp,
                                         Tk_Window tkwin, Tcl_Obj *ovalue,
                                         char *widget_rec, int offset));
static  Tcl_Obj *ZnGradientPrint _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                              char *widget_rec, int offset,
                                              Tcl_FreeProc **free_proc));
static  int ZnImageParse _ANSI_ARGS_((ClientData client_data, Tcl_Interp *interp,
                                      Tk_Window tkwin, Tcl_Obj *ovalue,
                                      char *widget_rec, int offset));
static  int ZnBitmapParse _ANSI_ARGS_((ClientData client_data, Tcl_Interp *interp,
                                       Tk_Window tkwin, Tcl_Obj *ovalue,
                                       char *widget_rec, int offset));
static  Tcl_Obj *ZnImagePrint _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                           char *widget_rec, int offset,
                                           Tcl_FreeProc **free_proc));
static  Tk_CustomOption reliefOption = {
  (Tk_OptionParseProc *) ZnReliefParse,
  (Tk_OptionPrintProc *) ZnReliefPrint,
  NULL
};
static  Tk_CustomOption gradientOption = {
  (Tk_OptionParseProc *) ZnGradientParse,
  (Tk_OptionPrintProc *) ZnGradientPrint,
  NULL
};
static  Tk_CustomOption imageOption = {
  (Tk_OptionParseProc *) ZnImageParse,
  (Tk_OptionPrintProc *) ZnImagePrint,
  NULL
};
static  Tk_CustomOption bitmapOption = {
  (Tk_OptionParseProc *) ZnBitmapParse,
  (Tk_OptionPrintProc *) ZnImagePrint,
  NULL
};
#else
static  int ZnSetReliefOpt _ANSI_ARGS_((ClientData client_data, Tcl_Interp *interp,
                                        Tk_Window tkwin, Tcl_Obj **ovalue,
                                        char *widget_rec, int offset, char *old_val_ptr, int flags));
static  Tcl_Obj *ZnGetReliefOpt _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                             char *widget_rec, int offset));
static void ZnRestoreReliefOpt _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                            char *val_ptr, char *old_val_ptr));
static  int ZnSetGradientOpt _ANSI_ARGS_((ClientData client_data, Tcl_Interp *interp,
                                          Tk_Window tkwin, Tcl_Obj **ovalue,
                                          char *widget_rec, int offset, char *old_val_ptr, int flags));
static  Tcl_Obj *ZnGetGradientOpt _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                               char *widget_rec, int offset));
static  void ZnRestoreGradientOpt _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin,
                                               char *val_ptr, char *old_val_ptr));
static  void ZnFreeGradientOpt _ANSI_ARGS_((ClientData client_data, Tk_Window tkwin, char *val_ptr));

static  Tk_ObjCustomOption reliefOption = {
  "znrelief",
  ZnSetReliefOpt,
  ZnGetReliefOpt,
  ZnRestoreReliefOpt,
  NULL,
  0
};
static  Tk_ObjCustomOption gradientOption = {
  "zngradient",
  ZnSetGradientOpt,
  ZnGetGradientOpt,
  ZnRestoreGradientOpt,
  ZnFreeGradientOpt,
  NULL
};
#endif

#ifdef PTK_800
#define BORDER_WIDTH_SPEC               0
#define BACK_COLOR_SPEC                 1
#define CONFINE_SPEC                    2
#define CURSOR_SPEC                     3
#define FONT_SPEC                       4
#define FORE_COLOR_SPEC                 5
#define FULL_RESHAPE_SPEC               6
#define HEIGHT_SPEC                     7
#define HIGHLIGHT_BACK_COLOR_SPEC       8
#define HIGHLIGHT_COLOR_SPEC            9
#define HIGHLIGHT_THICKNESS_SPEC        10
#define INSERT_COLOR_SPEC               11
#define INSERT_OFF_TIME_SPEC            12
#define INSERT_ON_TIME_SPEC             13
#define INSERT_WIDTH_SPEC               14
#define MAP_DISTANCE_SYMBOL_SPEC        15
#define MAP_TEXT_FONT_SPEC              16
#define OVERLAP_MANAGER_SPEC            17
#define PICK_APERTURE_SPEC              18
#define RELIEF_SPEC                     19
#define RENDER_SPEC                     20
#define RESHAPE_SPEC                    21
#define SCROLL_REGION_SPEC              22
#define SELECT_COLOR_SPEC               23
#define SPEED_VECTOR_LENGTH_SPEC        24
#define TAKE_FOCUS_SPEC                 25
#define TILE_SPEC                       26
#define VISIBLE_HISTORY_SIZE_SPEC       27
#define MANAGED_HISTORY_SIZE_SPEC       28
#define TRACK_SYMBOL_SPEC               29
#define WIDTH_SPEC                      30
#define X_SCROLL_CMD_SPEC               31
#define X_SCROLL_INCREMENT_SPEC         32
#define Y_SCROLL_CMD_SPEC               33
#define Y_SCROLL_INCREMENT_SPEC         34
#define BBOXES_SPEC                     35
#define BBOXES_COLOR_SPEC               36
#define LIGHT_ANGLE_SPEC                37
#define FOLLOW_POINTER_SPEC             38
#else
#define CONFIG_FONT                     1<<0
#define CONFIG_MAP_FONT                 1<<1
#define CONFIG_BACK_COLOR               1<<2
#define CONFIG_REDISPLAY                1<<3
#define CONFIG_DAMAGE_ALL               1<<4
#define CONFIG_INVALIDATE_TRACKS        1<<5
#define CONFIG_INVALIDATE_WPS           1<<6
#define CONFIG_INVALIDATE_MAPS          1<<7
#define CONFIG_REQUEST_GEOM             1<<8
#define CONFIG_OM                       1<<9
#define CONFIG_FOCUS                    1<<10
#define CONFIG_FOCUS_ITEM               1<<11
#define CONFIG_SCROLL_REGION            1<<12
#define CONFIG_SET_ORIGIN               1<<13
#define CONFIG_FOLLOW_POINTER           1<<14
#define CONFIG_MAP_SYMBOL               1<<15
#define CONFIG_TRACK_SYMBOL             1<<16
#define CONFIG_TILE                     1<<17
#define CONFIG_DEBUG            1<<18
#endif

/*
 * Information used for argv parsing.
 */
#ifdef PTK_800
static Tk_ConfigSpec config_specs[] = {
  {TK_CONFIG_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
   "2", Tk_Offset(ZnWInfo, border_width), 0, NULL},
  {TK_CONFIG_CUSTOM, "-backcolor", "backColor", "BackColor",
   "#c3c3c3", Tk_Offset(ZnWInfo, back_color), 0, &gradientOption},
  {TK_CONFIG_BOOLEAN, "-confine", "confine", "Confine",
   "1", Tk_Offset(ZnWInfo, confine), 0, NULL},
  {TK_CONFIG_ACTIVE_CURSOR, "-cursor", "cursor", "Cursor",
   "", Tk_Offset(ZnWInfo, cursor), TK_CONFIG_NULL_OK, NULL},
  {TK_CONFIG_FONT, "-font", "font", "Font",
   "-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*",
   Tk_Offset(ZnWInfo, font), 0, NULL},
  {TK_CONFIG_CUSTOM, "-forecolor", "foreColor", "Foreground",
   "Black", Tk_Offset(ZnWInfo, fore_color), 0, &gradientOption},
  {TK_CONFIG_BOOLEAN, "-fullreshape", "fullReshape", "FullReshape",
   "1", Tk_Offset(ZnWInfo, full_reshape), 0, NULL},
  {TK_CONFIG_PIXELS, "-height", "height", "Height",
   "7c", Tk_Offset(ZnWInfo, opt_height), 0, NULL},
  {TK_CONFIG_CUSTOM, "-highlightbackground", "highlightBackground", "HighlightBackground",
   "#c3c3c3", Tk_Offset(ZnWInfo, highlight_bg_color), 0, &gradientOption},
  {TK_CONFIG_CUSTOM, "-highlightcolor", "highlightColor", "HighlightColor",
   "Black", Tk_Offset(ZnWInfo, highlight_color), 0, &gradientOption},
  {TK_CONFIG_PIXELS, "-highlightthickness", "highlightThickness", "HighlightThickness",
   "2", Tk_Offset(ZnWInfo, highlight_width), 0, NULL},
  {TK_CONFIG_CUSTOM, "-insertbackground", "insertBackground", "Foreground",
   "Black", Tk_Offset(ZnWInfo, text_info.insert_color), 0, &gradientOption},
  {TK_CONFIG_INT, "-insertofftime", "insertOffTime", "OffTime",
   "300", Tk_Offset(ZnWInfo, insert_off_time), 0, NULL},
  {TK_CONFIG_INT, "-insertontime", "insertOnTime", "OnTime",
   "600", Tk_Offset(ZnWInfo, insert_on_time), 0, NULL},
  {TK_CONFIG_PIXELS, "-insertwidth", "insertWidth", "InsertWidth",
   "2", Tk_Offset(ZnWInfo, text_info.insert_width), 0, NULL},
#ifdef ATC
  {TK_CONFIG_CUSTOM, "-mapdistancesymbol", "mapDistanceSymbol", "MapDistanceSymbol",
   "AtcSymbol19", Tk_Offset(ZnWInfo, map_distance_symbol),
   TK_CONFIG_NULL_OK, &bitmapOption},
  {TK_CONFIG_FONT, "-maptextfont", "mapTextFont", "MapTextFont",
   "-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*",
   Tk_Offset(ZnWInfo, map_text_font), 0, NULL},
  {TK_CONFIG_INT, "-overlapmanager", "overlapManager", "OverlapManager", "1",
   Tk_Offset(ZnWInfo, om_group_id), 0, NULL},
#endif
  {TK_CONFIG_INT, "-pickaperture", "pickAperture", "PickAperture",
   "1", Tk_Offset(ZnWInfo, pick_aperture), 0, NULL},
  {TK_CONFIG_CUSTOM, "-relief", "relief", "Relief",
   "flat", Tk_Offset(ZnWInfo, relief), 0, &reliefOption},
  {TK_CONFIG_INT, "-render", "render", "Render",
   "0", Tk_Offset(ZnWInfo, render), 0, NULL},
  {TK_CONFIG_BOOLEAN, "-reshape", "reshape", "Reshape",
   "1", Tk_Offset(ZnWInfo, reshape), 0, NULL},  
  {TK_CONFIG_LANGARG, "-scrollregion", "scrollRegion", "ScrollRegion",
   "", Tk_Offset(ZnWInfo, region), TK_CONFIG_NULL_OK, NULL},
  {TK_CONFIG_CUSTOM, "-selectbackground", "selectBackground", "Foreground",
   "#a0a0a0", Tk_Offset(ZnWInfo, text_info.sel_color), 0, &gradientOption},
#ifdef ATC
  {TK_CONFIG_DOUBLE, "-speedvectorlength", "speedVectorLength",
   "SpeedVectorLength", "3", Tk_Offset(ZnWInfo, speed_vector_length), 0, NULL},
#endif
  {TK_CONFIG_STRING, "-takefocus", "takeFocus", "TakeFocus",
   NULL, Tk_Offset(ZnWInfo, take_focus), TK_CONFIG_NULL_OK, NULL},
  {TK_CONFIG_CUSTOM, "-tile", "tile", "Tile",
   "", Tk_Offset(ZnWInfo, tile), 0, &imageOption},
#ifdef ATC
  {TK_CONFIG_INT, "-trackvisiblehistorysize", "trackVisibleHistorySize", "TrackVisibleHistorySize",
   "6", Tk_Offset(ZnWInfo, track_visible_history_size), 0, NULL},
  {TK_CONFIG_INT, "-trackmanagedhistorysize", "trackManagedHistorySize",
   "TrackManagedHistorySize", "6", Tk_Offset(ZnWInfo, track_managed_history_size), 0, NULL},
  {TK_CONFIG_CUSTOM, "-tracksymbol", "trackSymbol", "TrackSymbol",
   "AtcSymbol15", Tk_Offset(ZnWInfo, track_symbol), TK_CONFIG_NULL_OK, &bitmapOption},
#endif
  {TK_CONFIG_PIXELS, "-width", "width", "Width",
   "10c", Tk_Offset(ZnWInfo, opt_width), 0, NULL},
  {TK_CONFIG_CALLBACK, "-xscrollcommand", "xScrollCommand", "ScrollCommand",
   "", Tk_Offset(ZnWInfo, x_scroll_cmd), TK_CONFIG_NULL_OK, NULL},
  {TK_CONFIG_PIXELS, "-xscrollincrement", "xScrollIncrement", "ScrollIncrement",
   "0", Tk_Offset(ZnWInfo, x_scroll_incr), 0, NULL},
  {TK_CONFIG_CALLBACK, "-yscrollcommand", "yScrollCommand", "ScrollCommand",
   "", Tk_Offset(ZnWInfo, y_scroll_cmd), TK_CONFIG_NULL_OK, NULL},
  {TK_CONFIG_PIXELS, "-yscrollincrement", "yScrollIncrement",  "ScrollIncrement",
   "0", Tk_Offset(ZnWInfo, y_scroll_incr), 0, NULL},
  /*
   * Debug options.
   */
  {TK_CONFIG_BOOLEAN, "-drawbboxes", "drawBBoxes",
   "DrawBBoxes", "0", Tk_Offset(ZnWInfo, draw_bboxes), 0, NULL},
  {TK_CONFIG_CUSTOM, "-bboxcolor", "bboxColor", "BBoxColor",
   "Pink", Tk_Offset(ZnWInfo, bbox_color), 0, &gradientOption},
  {TK_CONFIG_INT, "-lightangle", "lightAngle", "LightAngle",
   "120", Tk_Offset(ZnWInfo, light_angle), 0, NULL},
  {TK_CONFIG_BOOLEAN, "-followpointer", "followPointer",
   "FollowPointer", "1", Tk_Offset(ZnWInfo, follow_pointer), 0, NULL},

  {TK_CONFIG_END, NULL, NULL, NULL, NULL, 0, 0, NULL}
};
#else
static Tk_OptionSpec option_specs[] = {
  {TK_OPTION_PIXELS, "-borderwidth", "borderWidth", "BorderWidth",
     "2", -1, Tk_Offset(ZnWInfo, border_width), 0, NULL, CONFIG_DAMAGE_ALL|CONFIG_REQUEST_GEOM},
  {TK_OPTION_CUSTOM, "-backcolor", "backColor", "BackColor",
     "#c3c3c3", -1, Tk_Offset(ZnWInfo, back_color), 0, &gradientOption,
     CONFIG_BACK_COLOR|CONFIG_DAMAGE_ALL},
  {TK_OPTION_BOOLEAN, "-confine", "confine", "Confine",
     "1", -1, Tk_Offset(ZnWInfo, confine), 0, NULL, CONFIG_SET_ORIGIN},
  {TK_OPTION_CURSOR, "-cursor", "cursor", "Cursor",
     "", -1, Tk_Offset(ZnWInfo, cursor), TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_INT, "-debug", "debug", "Debug",
     "0", -1, Tk_Offset(ZnWInfo, debug), 0, NULL, 0},
  {TK_OPTION_FONT, "-font", "font", "Font",
     "-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*",
     -1, Tk_Offset(ZnWInfo, font), 0, NULL, CONFIG_FONT},
  {TK_OPTION_CUSTOM, "-forecolor", "foreColor", "Foreground",
     "Black", -1, Tk_Offset(ZnWInfo, fore_color), 0, &gradientOption, 0},
  {TK_OPTION_BOOLEAN, "-fullreshape", "fullReshape", "FullReshape",
     "1", -1, Tk_Offset(ZnWInfo, full_reshape), 0, NULL, 0},
  {TK_OPTION_PIXELS, "-height", "height", "Height",
     "7c", -1, Tk_Offset(ZnWInfo, opt_height), 0, NULL, CONFIG_REQUEST_GEOM},
  {TK_OPTION_CUSTOM, "-highlightbackground", "highlightBackground", "HighlightBackground",
     "#c3c3c3", -1,  Tk_Offset(ZnWInfo, highlight_bg_color), 0, &gradientOption,
     CONFIG_REDISPLAY},
  {TK_OPTION_CUSTOM, "-highlightcolor", "highlightColor", "HighlightColor",
     "Black", -1, Tk_Offset(ZnWInfo, highlight_color), 0, &gradientOption, CONFIG_REDISPLAY},
  {TK_OPTION_PIXELS, "-highlightthickness", "highlightThickness", "HighlightThickness",
     "2", -1, Tk_Offset(ZnWInfo, highlight_width), 0, NULL, CONFIG_REQUEST_GEOM|CONFIG_DAMAGE_ALL},
  {TK_OPTION_CUSTOM, "-insertbackground", "insertBackground", "Foreground",
     "Black", -1, Tk_Offset(ZnWInfo, text_info.insert_color), 0, &gradientOption, 0},
  {TK_OPTION_INT, "-insertofftime", "insertOffTime", "OffTime",
     "300", -1, Tk_Offset(ZnWInfo, insert_off_time), 0, NULL, CONFIG_FOCUS},
  {TK_OPTION_INT, "-insertontime", "insertOnTime", "OnTime",
     "600", -1, Tk_Offset(ZnWInfo, insert_on_time), 0, NULL, CONFIG_FOCUS},
  {TK_OPTION_PIXELS, "-insertwidth", "insertWidth", "InsertWidth",
     "2", -1, Tk_Offset(ZnWInfo, text_info.insert_width), 0, NULL, CONFIG_FOCUS_ITEM},
#ifdef ATC
  {TK_OPTION_STRING, "-mapdistancesymbol", "mapDistanceSymbol", "MapDistanceSymbol",
     "AtcSymbol19", Tk_Offset(ZnWInfo, map_symbol_obj), -1,
     TK_OPTION_NULL_OK, NULL, CONFIG_MAP_SYMBOL|CONFIG_INVALIDATE_MAPS},
  {TK_OPTION_FONT, "-maptextfont", "mapTextFont", "MapTextFont",
     "-adobe-helvetica-bold-r-normal--*-120-*-*-*-*-*-*",
     -1, Tk_Offset(ZnWInfo, map_text_font), 0, NULL, CONFIG_MAP_FONT},
  {TK_OPTION_INT, "-overlapmanager", "overlapManager", "OverlapManager", "1",
     -1, Tk_Offset(ZnWInfo, om_group_id), 0, NULL, CONFIG_OM},
#endif
  {TK_OPTION_INT, "-pickaperture", "pickAperture", "PickAperture",
     "1", -1, Tk_Offset(ZnWInfo, pick_aperture), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-relief", "relief", "Relief",
     "flat", -1, Tk_Offset(ZnWInfo, relief), 0, &reliefOption, CONFIG_REDISPLAY},
  {TK_OPTION_INT, "-render", "render", "Render",
     "-1", -1, Tk_Offset(ZnWInfo, render), 0, NULL, 0},
  {TK_OPTION_BOOLEAN, "-reshape", "reshape", "Reshape",
     "1", -1, Tk_Offset(ZnWInfo, reshape), 0, NULL, 0},
  {TK_OPTION_STRING, "-scrollregion", "scrollRegion", "ScrollRegion",
     "", Tk_Offset(ZnWInfo, region), -1,
     TK_OPTION_NULL_OK, NULL, CONFIG_SET_ORIGIN|CONFIG_SCROLL_REGION},
  {TK_OPTION_CUSTOM, "-selectbackground", "selectBackground", "Foreground",
     "#a0a0a0", -1, Tk_Offset(ZnWInfo, text_info.sel_color), 0, &gradientOption, 0},
#ifdef ATC
  {TK_OPTION_DOUBLE, "-speedvectorlength", "speedVectorLength",
     "SpeedVectorLength", "3", -1, Tk_Offset(ZnWInfo, speed_vector_length),
     0, NULL, CONFIG_INVALIDATE_TRACKS},
#endif
  {TK_OPTION_STRING, "-takefocus", "takeFocus", "TakeFocus",
     NULL, Tk_Offset(ZnWInfo, take_focus), -1, TK_OPTION_NULL_OK, NULL, 0},
  {TK_OPTION_STRING, "-tile", "tile", "Tile",
     "", Tk_Offset(ZnWInfo, tile_obj), -1, TK_OPTION_NULL_OK, NULL, CONFIG_TILE|CONFIG_DAMAGE_ALL},
#ifdef ATC
  {TK_OPTION_INT, "-trackvisiblehistorysize", "trackVisibleHistorySize", "TrackVisibleHistorySize",
     "6", -1, Tk_Offset(ZnWInfo, track_visible_history_size), 0, NULL, CONFIG_INVALIDATE_TRACKS},
  {TK_OPTION_INT, "-trackmanagedhistorysize", "trackManagedHistorySize",
     "TrackManagedHistorySize", "6", -1, Tk_Offset(ZnWInfo, track_managed_history_size),
     0, NULL, CONFIG_INVALIDATE_TRACKS},
  {TK_OPTION_STRING, "-tracksymbol", "trackSymbol", "TrackSymbol",
     "AtcSymbol15", Tk_Offset(ZnWInfo, track_symbol_obj), -1,
     0, NULL, CONFIG_TRACK_SYMBOL|CONFIG_INVALIDATE_TRACKS|CONFIG_INVALIDATE_WPS},
#endif
  {TK_OPTION_PIXELS, "-width", "width", "Width",
     "10c", -1, Tk_Offset(ZnWInfo, opt_width), 0, NULL, CONFIG_DAMAGE_ALL|CONFIG_REQUEST_GEOM},
#ifdef PTK
  {TK_OPTION_CALLBACK, "-xscrollcommand", "xScrollCommand", "ScrollCommand",
     "", -1, Tk_Offset(ZnWInfo, x_scroll_cmd), TK_OPTION_NULL_OK, NULL, 0},
#else
  {TK_OPTION_STRING, "-xscrollcommand", "xScrollCommand", "ScrollCommand",
     "", Tk_Offset(ZnWInfo, x_scroll_cmd), -1, TK_OPTION_NULL_OK, NULL, 0},
#endif
  {TK_OPTION_PIXELS, "-xscrollincrement", "xScrollIncrement", "ScrollIncrement",
     "0", -1, Tk_Offset(ZnWInfo, x_scroll_incr), 0, NULL, 0},
#ifdef PTK
  {TK_OPTION_CALLBACK, "-yscrollcommand", "yScrollCommand", "ScrollCommand",
     "", -1, Tk_Offset(ZnWInfo, y_scroll_cmd), TK_OPTION_NULL_OK, NULL, 0},
#else
  {TK_OPTION_STRING, "-yscrollcommand", "yScrollCommand", "ScrollCommand",
     "", Tk_Offset(ZnWInfo, y_scroll_cmd), -1, TK_OPTION_NULL_OK, NULL, 0},
#endif
  {TK_OPTION_PIXELS, "-yscrollincrement", "yScrollIncrement",  "ScrollIncrement",
     "0", -1, Tk_Offset(ZnWInfo, y_scroll_incr), 0, NULL, 0},
  /*
   * Debug options.
   */
  {TK_OPTION_BOOLEAN, "-drawbboxes", "drawBBoxes",
     "DrawBBoxes", "0", -1, Tk_Offset(ZnWInfo, draw_bboxes), 0, NULL, 0},
  {TK_OPTION_CUSTOM, "-bboxcolor", "bboxColor", "BBoxColor",
     "Pink", -1, Tk_Offset(ZnWInfo, bbox_color), 0, &gradientOption, 0},
  {TK_OPTION_INT, "-lightangle", "lightAngle", "LightAngle",
     "120", -1, Tk_Offset(ZnWInfo, light_angle), 0, NULL, CONFIG_DAMAGE_ALL},
  {TK_OPTION_BOOLEAN, "-followpointer", "followPointer",
   "FollowPointer", "1", -1, Tk_Offset(ZnWInfo, follow_pointer), 0, NULL, CONFIG_FOLLOW_POINTER},

  {TK_OPTION_END, NULL, NULL, NULL, NULL, 0, 0, 0, NULL, 0}
};
#endif

static void     CmdDeleted _ANSI_ARGS_((ClientData client_data));
static void     Event _ANSI_ARGS_((ClientData client_data, XEvent *eventPtr));
static void     Bind _ANSI_ARGS_((ClientData client_data, XEvent *eventPtr));
static int      FetchSelection _ANSI_ARGS_((ClientData clientData, int offset,
                                            char *buffer, int maxBytes));
static void     SelectTo _ANSI_ARGS_((ZnItem item, int field, int index));
static int      WidgetObjCmd _ANSI_ARGS_((ClientData client_data,
                                          Tcl_Interp *, int argc, Tcl_Obj *CONST args[]));
#ifdef PTK_800
static int      Configure _ANSI_ARGS_((Tcl_Interp *interp, ZnWInfo *wi,
                                       int argc, Tcl_Obj *CONST args[], int flags));
#else
static int      Configure _ANSI_ARGS_((Tcl_Interp *interp, ZnWInfo *wi,
                                       int argc, Tcl_Obj *CONST args[]));
#endif
static void     Redisplay _ANSI_ARGS_((ClientData client_data));
static void     Destroy _ANSI_ARGS_((ZnWInfo *wi));
static void     InitZinc _ANSI_ARGS_((Tcl_Interp *interp));
static void     Focus _ANSI_ARGS_((ZnWInfo *wi, ZnBool got_focus));
static void     Update _ANSI_ARGS_((ZnWInfo     *wi));
static void     Repair _ANSI_ARGS_((ZnWInfo     *wi));


#ifdef PTK_800
/*
 *----------------------------------------------------------------------
 *
 * ZnReliefParse
 * ZnReliefPrint --
 *      Converter for the -relief option.
 *
 *----------------------------------------------------------------------
 */
static int
ZnReliefParse(ClientData        client_data,
              Tcl_Interp        *interp,
              Tk_Window         tkwin,
              Tcl_Obj           *ovalue,
              char              *widget_rec,
              int               offset)
{
  ZnReliefStyle *relief_ptr = (ZnReliefStyle *) (widget_rec + offset);
  ZnReliefStyle relief;
  char        *value = Tcl_GetString(ovalue);
  int         result = TCL_OK;

  if (value != NULL) {
    result = ZnGetRelief((ZnWInfo *) widget_rec, value, &relief);
    if (result == TCL_OK) {
      *relief_ptr = relief;
    }
  }
  return result;
}

static Tcl_Obj *
ZnReliefPrint(ClientData        client_data,
              Tk_Window         tkwin,
              char              *widget_rec,
              int               offset,
              Tcl_FreeProc      **free_proc)
{
  ZnReliefStyle relief = *(ZnReliefStyle *) (widget_rec + offset);
  return Tcl_NewStringObj(ZnNameOfRelief(relief), -1);
}


/*
 *----------------------------------------------------------------------
 *
 * ZnGradientParse
 * ZnGradientPrint --
 *      Converter for the -*color* options.
 *
 *----------------------------------------------------------------------
 */
static int
ZnGradientParse(ClientData      client_data,
                Tcl_Interp      *interp,
                Tk_Window       tkwin,
                Tcl_Obj         *ovalue,
                char            *widget_rec,
                int             offset)
{
  ZnGradient    **grad_ptr = (ZnGradient **) (widget_rec + offset);
  ZnGradient    *grad, *prev_grad;
  char          *value = Tcl_GetString(ovalue);

  prev_grad = *grad_ptr;
  if ((value != NULL) && (*value != '\0')) {
    grad = ZnGetGradient(interp, tkwin, value);
    if (grad == NULL) {
      return TCL_ERROR;
    }
    if (prev_grad != NULL) {
      ZnFreeGradient(prev_grad);
    }
    *grad_ptr = grad;
  }
  return TCL_OK;
}

static Tcl_Obj *
ZnGradientPrint(ClientData      client_data,
                Tk_Window       tkwin,
                char            *widget_rec,
                int             offset,
                Tcl_FreeProc    **free_proc)
{
  ZnGradient *gradient = *(ZnGradient **) (widget_rec + offset);
  return Tcl_NewStringObj(ZnNameOfGradient(gradient), -1);
}


/*
 *----------------------------------------------------------------------
 *
 * ZnBitmapParse
 * ZnImageParse
 * ZnImagePrint --
 *      Converter for the -*image* options.
 *
 *----------------------------------------------------------------------
 */
static int
ZnBitmapParse(ClientData        client_data,
              Tcl_Interp        *interp,
              Tk_Window         tkwin,
              Tcl_Obj           *ovalue,
              char              *widget_rec,
              int               offset)
{
  ZnImage       *image_ptr = (ZnImage *) (widget_rec + offset);
  ZnImage       image, prev_image;
  char          *value = Tcl_GetString(ovalue);
  ZnWInfo       *wi = (ZnWInfo*) widget_rec;
  ZnBool        is_bmap = True;

  prev_image = *image_ptr;
  if ((value != NULL) && (*value != '\0')) {
    image = ZnGetImage(wi, value, NULL, NULL);
    if ((image == ZnUnspecifiedImage) ||
        ! (is_bmap = ZnImageIsBitmap(image))) {
      if (!is_bmap) {
        ZnFreeImage(image, NULL, NULL);
      }
      return TCL_ERROR;
    }
    if (prev_image != NULL) {
      ZnFreeImage(prev_image, NULL, NULL);
    }
    *image_ptr = image;
  }
  else if (prev_image != NULL) {
    ZnFreeImage(prev_image, NULL, NULL);
    *image_ptr = NULL;
  }

  return TCL_OK;
}

static void
ZnImageUpdate(void *client_data)
{
  ZnWInfo *wi = (ZnWInfo*) client_data;

  ZnDamageAll(wi);
}

static int
ZnImageParse(ClientData client_data,
             Tcl_Interp *interp,
             Tk_Window  tkwin,
             Tcl_Obj    *ovalue,
             char       *widget_rec,
             int        offset)
{
  ZnImage       *image_ptr = (ZnImage *) (widget_rec + offset);
  ZnImage       image, prev_image;
  char          *value = Tcl_GetString(ovalue);
  ZnWInfo       *wi = (ZnWInfo*) widget_rec;

  prev_image = *image_ptr;
  if ((value != NULL) && (*value != '\0')) {
    image = ZnGetImage(wi, value, ZnImageUpdate, wi);
    if (image == NULL) {
      return TCL_ERROR;
    }
    if (prev_image != NULL) {
      ZnFreeImage(prev_image, ZnImageUpdate, wi);
    }
    *image_ptr = image;
  }
  else if (prev_image != NULL) {
    ZnFreeImage(prev_image, ZnImageUpdate, wi);
    *image_ptr = NULL;
  }
  return TCL_OK;
}

static Tcl_Obj *
ZnImagePrint(ClientData         client_data,
             Tk_Window          tkwin,
             char               *widget_rec,
             int                offset,
             Tcl_FreeProc       **free_proc)
{
  ZnImage image = *(ZnImage *) (widget_rec + offset);
  return Tcl_NewStringObj(image?ZnNameOfImage(image):"", -1);
}
#else
/*
 *----------------------------------------------------------------------
 *
 * ZnSetReliefOpt
 * ZnGetReliefOpt
 * ZnRestoreReliefOpt --
 *      Converter for the -relief option.
 *
 *----------------------------------------------------------------------
 */
static int
ZnSetReliefOpt(ClientData       client_data,
               Tcl_Interp       *interp,
               Tk_Window        tkwin,
               Tcl_Obj          **ovalue,
               char             *widget_rec,
               int              offset,
               char             *old_val_ptr,
               int              flags)
{
  ZnReliefStyle *relief_ptr;
  ZnReliefStyle relief;
  char          *value = Tcl_GetString(*ovalue);
  
  if (ZnGetRelief((ZnWInfo *) widget_rec, value, &relief) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (offset >= 0) {
    relief_ptr = (ZnReliefStyle *) (widget_rec + offset);
    *((ZnReliefStyle *) old_val_ptr) = *relief_ptr;
    *relief_ptr = relief;
  }
  return TCL_OK;
}

static Tcl_Obj *
ZnGetReliefOpt(ClientData       client_data,
               Tk_Window        tkwin,
               char             *widget_rec,
               int              offset)
{
  ZnReliefStyle relief = *(ZnReliefStyle *) (widget_rec + offset);
  return Tcl_NewStringObj(ZnNameOfRelief(relief), -1);
}

static void
ZnRestoreReliefOpt(ClientData   client_data,
                   Tk_Window    tkwin,
                   char         *val_ptr,
                   char         *old_val_ptr)
{
  *(ZnReliefStyle *) val_ptr = *(ZnReliefStyle *) old_val_ptr;
}

/*
 *----------------------------------------------------------------------
 *
 * ZnSetGradientOpt
 * ZnGetGradientOpt
 * ZnRestoreGradientOpt --
 *      Converter for the -*color* options.
 *
 *----------------------------------------------------------------------
 */
static int
ZnSetGradientOpt(ClientData     client_data,
                 Tcl_Interp     *interp,
                 Tk_Window      tkwin,
                 Tcl_Obj        **ovalue,
                 char           *widget_rec,
                 int            offset,
                 char           *old_val_ptr,
                 int            flags)
{
  ZnGradient    **grad_ptr;
  ZnGradient    *grad;
  char          *value = Tcl_GetString(*ovalue);

  if (offset >= 0) {
    if (*value == '\0') {
      grad = NULL;
    }
    else {
      grad = ZnGetGradient(interp, tkwin, value);
      if (grad == NULL) {
        return TCL_ERROR;
      }
    }
    grad_ptr = (ZnGradient **) (widget_rec + offset);
    *(ZnGradient **) old_val_ptr = *grad_ptr;
    *grad_ptr = grad;
  }
  return TCL_OK;
}

static Tcl_Obj *
ZnGetGradientOpt(ClientData     client_data,
                 Tk_Window      tkwin,
                 char           *widget_rec,
                 int            offset)
{
  ZnGradient *gradient = *(ZnGradient **) (widget_rec + offset);
  return Tcl_NewStringObj(ZnNameOfGradient(gradient), -1);
}

static void
ZnRestoreGradientOpt(ClientData client_data,
                     Tk_Window  tkwin,
                     char       *val_ptr,
                     char       *old_val_ptr)
{
  if (*(ZnGradient **) val_ptr != NULL) {
    ZnFreeGradient(*(ZnGradient **) val_ptr);
  }
  *(ZnGradient **) val_ptr = *(ZnGradient **) old_val_ptr;
}

static void
ZnFreeGradientOpt(ClientData    client_data,
                  Tk_Window     tkwin,
                  char          *val_ptr)
{
  if (*(ZnGradient **) val_ptr != NULL) {
    ZnFreeGradient(*(ZnGradient **) val_ptr);
  }
}
#endif


/*
 *----------------------------------------------------------------------
 *
 * ZnGetAlphaStipple --
 *      Need to be handled per screen/dpy toolkit wide, not on a
 *      widget basis.
 *
 *----------------------------------------------------------------------
 */
static Pixmap
ZnGetAlphaStipple(ZnWInfo       *wi,
                  unsigned int  val)
{
  if (val >= 255)
    return None;
  else
    return wi->alpha_stipples[(int) (val / 16)];
}

/*
 *----------------------------------------------------------------------
 *
 * ZnGetInactiveStipple --
 *
 *----------------------------------------------------------------------
 */
Pixmap
ZnGetInactiveStipple(ZnWInfo    *wi)
{
  return ZnGetAlphaStipple(wi, 128);
}


/*
 *----------------------------------------------------------------------
 *
 * ZnNeedRedisplay --
 *
 *----------------------------------------------------------------------
 */
void
ZnNeedRedisplay(ZnWInfo *wi)
{
  if (ISCLEAR(wi->flags, ZN_UPDATE_PENDING) && ISSET(wi->flags, ZN_REALIZED)) {
    /*printf("scheduling an update\n");*/
    Tcl_DoWhenIdle(Redisplay, (ClientData) wi);
    SET(wi->flags, ZN_UPDATE_PENDING);
  }
}

/*
 *----------------------------------------------------------------------
 *
 * ZnGetGlContext --
 *
 *----------------------------------------------------------------------
 */
#ifdef GL
ZnGLContextEntry *
ZnGetGLContext(Display *dpy)
{
  ZnGLContextEntry *context_entry;
  
  for (context_entry = gl_contexts;
       context_entry && context_entry->dpy != dpy;
       context_entry = context_entry->next);

  return context_entry;
}

ZnGLContextEntry *
ZnGLMakeCurrent(Display *dpy,
                ZnWInfo *wi)
{
  ZnGLContextEntry *ce;

  ce = ZnGetGLContext(dpy);

  if (!wi) {
    /* Get a zinc widget from the context struct
     * for this display. If no more are left,
     * returns, nothing can be done. This can
     * happen only when freeing images or fonts
     * after the last zinc on a given display has
     * been deleted. In this case the context should
     * be deleted, freeing all resources including
     * textures.
     */
    ZnWInfo **wip = ZnListArray(ce->widgets);
    int     i, num = ZnListSize(ce->widgets);

    for (i = 0; i <num; i++, wip++) {
      if ((*wip)->win != NULL) {
        wi = *wip;
        break;
      }
    }
    if (!wi) {
      return NULL;
    }
  }
#ifdef _WIN32
  ce->hwnd = Tk_GetHWND(Tk_WindowId(wi->win));
  ce->hdc = GetDC(ce->hwnd);
  SetPixelFormat(ce->hdc, ce->ipixel, &ce->pfd);

  if (!wglMakeCurrent(ce->hdc, ce->context)) {
    fprintf(stderr, "Can't make the GL context current: %d\n", GetLastError());
  }
#else
  glXMakeCurrent(dpy, Tk_WindowId(wi->win), ce->context);
#endif
  return ce;
}

void
ZnGLReleaseContext(ZnGLContextEntry *ce)
{
  if (ce) {
#ifdef _WIN32
    wglMakeCurrent(NULL, NULL);
    ReleaseDC(ce->hwnd, ce->hdc);
#else
    /*glXMakeCurrent(ce->dpy, None, NULL);*/
#endif
  }
}

static void
ZnGLSwapBuffers(ZnGLContextEntry *ce,
                ZnWInfo          *wi)
{
  if (ce) {
#ifdef _WIN32
    SwapBuffers(ce->hdc);
#else
    glXSwapBuffers(ce->dpy, Tk_WindowId(wi->win));
#endif
  }
}
#endif


#ifdef GL
static void
InitRendering1(ZnWInfo  *wi)
{

  if (wi->render) {
#  ifndef _WIN32
        ZnGLContextEntry *ce;
    ZnGLContext gl_context;
    XVisualInfo *gl_visual = NULL;
    Colormap    colormap = 0;

    ASSIGN(wi->flags, ZN_PRINT_CONFIG, (getenv("ZINC_GLX_INFO") != NULL));

    if (ISSET(wi->flags, ZN_PRINT_CONFIG)) {
      fprintf(stderr, "GLX version %d.%d\n", ZnMajorGlx, ZnMinorGlx);
    }
    
    /*
     * Look for a matching context already available.
     */
    ce = ZnGetGLContext(wi->dpy);
    if (ce) {
      gl_context = ce->context;
      gl_visual = ce->visual;
      colormap = ce->colormap;
      ZnListAdd(ce->widgets, &wi, ZnListTail);
    }
    else {
      int val;
      
      gl_visual = glXChooseVisual(wi->dpy,
                                  XScreenNumberOfScreen(wi->screen),
                                  ZnGLAttribs);
      if (!gl_visual) {
        fprintf(stderr, "No glx visual\n");
      }
      else {
        gl_context = glXCreateContext(wi->dpy, gl_visual,
                                      NULL, wi->render==1);
        if (!gl_context) {
          fprintf(stderr, "No glx context\n");
        }
        else {
          colormap = XCreateColormap(wi->dpy, RootWindowOfScreen(wi->screen),
                                     gl_visual->visual, AllocNone);
          ce = ZnMalloc(sizeof(ZnGLContextEntry));
          ce->context = gl_context;
          ce->visual = gl_visual;
          ce->colormap = colormap;
          ce->dpy = wi->dpy;
          ce->max_tex_size = 64; /* Minimum value is always valid */
          ce->max_line_width = 1;
          ce->max_point_width = 1;
          ce->next = gl_contexts;
          gl_contexts = ce;
          ce->widgets = ZnListNew(1, sizeof(ZnWInfo *));
          ZnListAdd(ce->widgets, &wi, ZnListTail);
          
          if (ISSET(wi->flags, ZN_PRINT_CONFIG)) {
            fprintf(stderr, "  Visual : 0x%x, ",
                    (int) gl_visual->visualid);
            glXGetConfig(wi->dpy, gl_visual, GLX_RGBA, &val);
            fprintf(stderr, "RGBA : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_DOUBLEBUFFER, &val);
            fprintf(stderr, "Double Buffer : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_STENCIL_SIZE, &val);
            fprintf(stderr, "Stencil : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_BUFFER_SIZE, &val);
            fprintf(stderr, "depth : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_RED_SIZE, &val);
            fprintf(stderr, "red : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_GREEN_SIZE, &val);
            fprintf(stderr, "green : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_BLUE_SIZE, &val);
            fprintf(stderr, "blue : %d, ", val);
            glXGetConfig(wi->dpy, gl_visual, GLX_ALPHA_SIZE, &val);
            fprintf(stderr, "alpha : %d\n", val);
            fprintf(stderr, "  Direct Rendering: %d\n",
                    glXIsDirect(wi->dpy, gl_context));
          }
        }
      }
    }
    if (gl_visual && colormap) {
      Tk_SetWindowVisual(wi->win, gl_visual->visual, 24, colormap);
    }
#  endif /* _WIN32 */
  }
}

static void
InitRendering2(ZnWInfo  *wi)
{
  ZnGLContextEntry      *ce;
  ZnGLContext           gl_context;
  GLfloat               r[2]; /* Min, Max */
  GLint                 i[1];

  if (wi->render) {
#  ifdef _WIN32
    /*
     * Look for a matching context already available.
     */
    ce = ZnGetGLContext(wi->dpy);
    if (ce) {
      gl_context = ce->context;
      ce->hwnd = Tk_GetHWND(Tk_WindowId(wi->win));
      ce->hdc = GetDC(ce->hwnd);
      ZnListAdd(ce->widgets, &wi, ZnListTail);
      SetPixelFormat(ce->hdc, ce->ipixel, &ce->pfd);
    }
    else {
      ce = ZnMalloc(sizeof(ZnGLContextEntry));
      ce->hwnd = Tk_GetHWND(Tk_WindowId(wi->win));
      ce->hdc = GetDC(ce->hwnd);
      ce->widgets = ZnListNew(1, sizeof(ZnWInfo *));
      ZnListAdd(ce->widgets, &wi, ZnListTail);

      memset(&ce->pfd, 0, sizeof(PIXELFORMATDESCRIPTOR));
      ce->pfd.nSize = sizeof(PIXELFORMATDESCRIPTOR);
      ce->pfd.nVersion = 1;
      ce->pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
      ce->pfd.iPixelType = PFD_TYPE_RGBA;
      ce->pfd.cRedBits = 8;
      ce->pfd.cGreenBits = 8;
      ce->pfd.cBlueBits = 8;
      ce->pfd.cAlphaBits = 8;
      ce->pfd.cStencilBits = 8;
      ce->pfd.iLayerType = PFD_MAIN_PLANE;
      ce->ipixel = ChoosePixelFormat(ce->hdc, &ce->pfd);
      /*printf("ipixel=%d dwFlags=0x%x req=0x%x iPixelType=%d hdc=%d\n",
        ce->ipixel,     ce->pfd.dwFlags,
        PFD_DRAW_TO_WINDOW|PFD_SUPPORT_OPENGL|PFD_DOUBLEBUFFER,       
        ce->pfd.iPixelType==PFD_TYPE_RGBA,
        ce->hdc);*/
      if (!ce->ipixel ||
          (ce->pfd.cRedBits != 8) || (ce->pfd.cGreenBits != 8) || (ce->pfd.cBlueBits != 8) ||
          (ce->pfd.cStencilBits != 8)) {
        fprintf(stderr, "ChoosePixelFormat failed\n");
      }
      
      if (SetPixelFormat(ce->hdc, ce->ipixel, &ce->pfd) == TRUE) {
        gl_context = wglCreateContext(ce->hdc);
        if (gl_context) {
          ce->context = gl_context;
          ce->dpy = wi->dpy;
          ce->max_tex_size = 64; /* Minimum value is always valid */
          ce->max_line_width = 1;
          ce->max_point_width = 1;
          ce->next = gl_contexts;
          gl_contexts = ce;
        }
        else {
          fprintf(stderr, "wglCreateContext failed\n");
          ZnFree(ce);
        }
      }
      else {
        ZnFree(ce);
      }
    }
    ReleaseDC(ce->hwnd, ce->hdc);
#endif

    ce = ZnGLMakeCurrent(wi->dpy, wi);
    glGetFloatv(ZN_GL_LINE_WIDTH_RANGE, r);
    ce->max_line_width = r[1];
    glGetFloatv(ZN_GL_POINT_SIZE_RANGE, r);
    ce->max_point_width = r[1];
    glGetIntegerv(GL_MAX_TEXTURE_SIZE, i);
    ce->max_tex_size = (unsigned int) i[0];
    
    if (ISSET(wi->flags, ZN_PRINT_CONFIG)) {
      fprintf(stderr, "OpenGL version %s\n",
              (char *) glGetString(GL_VERSION));
      fprintf(stderr, "  Rendering engine: %s, ",
              (char *) glGetString(GL_RENDERER));
      fprintf(stderr, "  Vendor: %s\n",
              (char *) glGetString(GL_VENDOR));
      fprintf(stderr, "  Available extensions: %s\n",
              (char *) glGetString(GL_EXTENSIONS));
      fprintf(stderr, "Max antialiased line width: %g\n",
              ce->max_line_width);
      fprintf(stderr, "Max antialiased point size: %g\n",
              ce->max_point_width);
      fprintf(stderr, "Max texture size: %d\n",
              ce->max_tex_size);
    }
    
    ZnGLReleaseContext(ce);
  }
}
#endif /* GL */


/*
 *----------------------------------------------------------------------
 *
 * ZincObjCmd --
 *
 *      This procedure is invoked to process the "zinc" Tcl
 *      command.  It creates a new "zinc" widget.
 *
 *----------------------------------------------------------------------
 */
EXTERN int
ZincObjCmd(ClientData           client_data,    /* Main window associated with
                                                 * interpreter. */
           Tcl_Interp           *interp,        /* Current interpreter. */
           int                  argc,           /* Number of arguments. */
           Tcl_Obj      *CONST  args[])         /* Argument strings. */
{
  Tk_Window     top_w = (Tk_Window) client_data;
  ZnWInfo       *wi;
  Tk_Window     tkwin;
#ifndef PTK_800
  Tk_OptionTable opt_table;
#endif
  unsigned int  num;
  ZnBool        has_gl = False;
#ifndef _WIN32
#  if defined(GL) || defined(SHAPE)
  int           major_op, first_err, first_evt;
#  endif
#  ifdef GL
  Display       *dpy = Tk_Display(top_w);
  Screen        *screen = Tk_Screen(top_w);
#  endif
#endif

  InitZinc(interp);

#ifdef GL
#  ifdef _WIN32
  has_gl = True;
#  else
  if (XQueryExtension(dpy, "GLX", &major_op, &first_evt, &first_err)) {
    if (glXQueryExtension(dpy, &first_err, &first_evt)) {
      if (glXQueryVersion(dpy, &ZnMajorGlx, &ZnMinorGlx)) {
        if ((ZnMajorGlx == 1) && (ZnMinorGlx >= 1)) {
          has_gl = True;
        }
      }
    }
  }
  if (has_gl) {
    XVisualInfo *visual = glXChooseVisual(dpy,
                                          XScreenNumberOfScreen(screen),
                                          ZnGLAttribs);
    if (visual) {
      XFree(visual);
    }
    else {
      has_gl = False;
    }
  }
#  endif
#endif

  if (argc == 1) {
    Tcl_AppendResult(interp, VERSION, NULL);
    Tcl_AppendResult(interp, " X11", NULL);
#ifdef GL
#  ifdef _WIN32
    Tcl_AppendResult(interp, " GL", NULL);
#  else
    if (has_gl) {
      Tcl_AppendResult(interp, " GL", NULL);
    }
#  endif
#endif
    return TCL_OK;
  }

  tkwin = Tk_CreateWindowFromPath(interp, top_w, Tcl_GetString(args[1]), NULL);
  if (tkwin == NULL) {
    return TCL_ERROR;
  }

#ifndef PTK_800
  opt_table = Tk_CreateOptionTable(interp, option_specs);
 #endif

  Tk_SetClass(tkwin, "Zinc");
  
  /*
   * Allocate and initialize the widget record.
   */  
  wi = (ZnWInfo *) ZnMalloc(sizeof(ZnWInfo));
  wi->win = tkwin;
  wi->interp = interp;
  wi->dpy = Tk_Display(tkwin);
  wi->screen = Tk_Screen(tkwin);
  wi->flags = 0;
  wi->render = -1;
  wi->real_top = None;

  ASSIGN(wi->flags, ZN_HAS_GL, has_gl);
#if defined(SHAPE) && !defined(_WIN32)
  ASSIGN(wi->flags, ZN_HAS_X_SHAPE,
         XQueryExtension(wi->dpy, "SHAPE", &major_op, &first_evt, &first_err));
  wi->reshape = wi->full_reshape = True;
#else
  CLEAR(wi->flags, ZN_HAS_X_SHAPE);
  wi->reshape = wi->full_reshape = False;
#endif

#ifdef PTK
#ifdef PTK_800
  wi->cmd = Lang_CreateWidget(interp, tkwin, (Tcl_CmdProc *) WidgetObjCmd,
                              (ClientData) wi, CmdDeleted);
#else
  wi->cmd = Lang_CreateWidget(interp, tkwin, WidgetObjCmd, (ClientData) wi, CmdDeleted);
#endif
#else
  wi->cmd = Tcl_CreateObjCommand(interp, Tk_PathName(tkwin), WidgetObjCmd,
                                 (ClientData) wi, CmdDeleted);
#endif
#ifndef PTK_800
  wi->opt_table = opt_table;
#endif
  wi->binding_table = 0;
  wi->fore_color = NULL;
  wi->back_color = NULL;
  wi->relief_grad = NULL;
  wi->bbox_color = NULL;
  wi->draw_bboxes = 0;
  wi->light_angle = 120;
  wi->follow_pointer = 0;
  wi->border_width = 0;
  wi->relief = ZN_RELIEF_FLAT;
  wi->opt_width = None;
  wi->opt_height = None;
#ifdef GL
  wi->font_tfi = NULL;
#endif
  wi->font = 0;
#ifdef ATC
  wi->track_visible_history_size = 0;
  wi->track_managed_history_size = 0;
  wi->speed_vector_length = 0;
  wi->map_text_font = 0;
#  ifdef GL
  wi->map_font_tfi = NULL;
#  endif
  wi->map_distance_symbol = ZnUnspecifiedImage;
  wi->track_symbol = ZnUnspecifiedImage;
#  ifndef PTK_800
  wi->map_symbol_obj = NULL;
  wi->track_symbol_obj = NULL;
#  endif
#endif
  wi->tile = ZnUnspecifiedImage;
#ifndef PTK_800
  wi->tile_obj = NULL;
#endif
  wi->cursor = None;
  wi->hot_item = ZN_NO_ITEM;
  wi->hot_prev = ZN_NO_ITEM;
  wi->confine = 0;
  wi->origin.x = wi->origin.y = 0;
  wi->scroll_xo = wi->scroll_yo = 0;
  wi->scroll_xc = wi->scroll_yc = 0;
  wi->x_scroll_incr = wi->y_scroll_incr = 0;
  wi->x_scroll_cmd = wi->y_scroll_cmd = NULL;
  wi->region = NULL;

  wi->id_table = (Tcl_HashTable *) ZnMalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(wi->id_table, TCL_ONE_WORD_KEYS);
  wi->t_table = (Tcl_HashTable *) ZnMalloc(sizeof(Tcl_HashTable));
  Tcl_InitHashTable(wi->t_table, TCL_STRING_KEYS);

  wi->obj_id = 1;
  wi->num_items = 0;

  wi->top_group = ZnCreateItem(wi, ZnGroup, 0, NULL);

#ifdef ATC
  wi->om_group_id = 0;
  wi->om_group = wi->top_group;
  OmRegister((void *) wi, ZnSendTrackToOm, ZnSetLabelAngleFromOm, ZnQueryLabelPosition);
#endif
  wi->gc = 0;
  wi->draw_buffer = 0;
  wi->pick_aperture = 0;
  wi->state = 0;
  memset(&wi->pick_event, 0, sizeof(XEvent));
  wi->new_item = wi->current_item = ZN_NO_ITEM;
  wi->new_part = wi->current_part = ZN_NO_PART;
  wi->focus_item = ZN_NO_ITEM;
  wi->focus_field = ZN_NO_PART;

  CLEAR(wi->flags, ZN_MONITORING);
#ifndef _WIN32
  wi->total_draw_chrono = ZnNewChrono("Total draw time");
  wi->this_draw_chrono = ZnNewChrono("Last draw time");
#endif
  wi->damaged_area_w = wi->damaged_area_h = 0;
  
  /*
   * Text management init.
   */
  wi->text_info.sel_color = NULL;
  wi->text_info.sel_item = ZN_NO_ITEM;
  wi->text_info.sel_field = ZN_NO_PART;
  wi->text_info.sel_first = -1;
  wi->text_info.sel_last = -1;
  wi->text_info.anchor_item = ZN_NO_ITEM;
  wi->text_info.anchor_field = ZN_NO_PART;
  wi->text_info.sel_anchor = 0;
  wi->text_info.insert_color = NULL;
  wi->text_info.insert_width = 0;
  wi->text_info.cursor_on = False;
  wi->insert_on_time = 0;
  wi->insert_off_time = 0;
  wi->blink_handler = NULL;
  wi->take_focus = NULL;
  wi->highlight_width = 0;
  wi->highlight_color = NULL;
  wi->highlight_bg_color = NULL;
  ZnResetBBox(&wi->exposed_area);
  ZnResetBBox(&wi->damaged_area);
  
  ZnInitClipStack(wi);  
  ZnInitTransformStack(wi);

  for (num = 0; num < ZN_NUM_ALPHA_STEPS; num++) {
    char        name[TCL_INTEGER_SPACE+12];

    sprintf(name, "AlphaStipple%d", num);
    wi->alpha_stipples[num] = Tk_GetBitmap(interp, tkwin, Tk_GetUid(name));
  }

  Tk_CreateEventHandler(tkwin,
                        ExposureMask|StructureNotifyMask|FocusChangeMask,
                        Event, (ClientData) wi);
  Tk_CreateEventHandler(tkwin, KeyPressMask|KeyReleaseMask|
                        ButtonPressMask|ButtonReleaseMask|EnterWindowMask|
                        LeaveWindowMask|PointerMotionMask|VirtualEventMask,
                        Bind, (ClientData) wi);
  Tk_CreateSelHandler(tkwin, XA_PRIMARY, XA_STRING,
                      FetchSelection, (ClientData) wi, XA_STRING);

#ifdef PTK_800
  if (Configure(interp, wi, argc-2, args+2, 0) != TCL_OK) {
    Tk_DestroyWindow(tkwin);
    return TCL_ERROR;
  }  
#else
  if (Tk_InitOptions(interp, (char *) wi, opt_table, tkwin) != TCL_OK) {
    Tk_DestroyWindow(tkwin);
    return TCL_ERROR;
  }

  if (Configure(interp, wi, argc-2, args+2) != TCL_OK) {
    Tk_DestroyWindow(tkwin);
    return TCL_ERROR;
  }  
#endif

  wi->damaged_area.orig.x = wi->damaged_area.orig.y = 0;
  wi->damaged_area.corner.x = wi->width = wi->opt_width;
  wi->damaged_area.corner.y = wi->height = wi->opt_height;

  if (!wi->render) {
  /*
   * Allocate double buffer pixmap/image.
   */
    wi->draw_buffer = Tk_GetPixmap(wi->dpy, RootWindowOfScreen(wi->screen),
                                   wi->width, wi->height, Tk_Depth(wi->win));
  }
#ifdef GL
  else {
    InitRendering1(wi);
  }
#endif

#ifdef PTK
  Tcl_SetObjResult(interp, LangWidgetObj(interp, tkwin));
#else
  Tcl_SetObjResult(interp, Tcl_NewStringObj(Tk_PathName(tkwin), -1));
#endif
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * EncodeItemPart --
 *
 *      Form a ClientData value from an item/part that is suitable
 *      as a key in a binding table.
 *
 *----------------------------------------------------------------------
 */
ClientData
EncodeItemPart(ZnItem   item,
               int      part)
{
  if (part >= 0) {
    ZnFieldSet fs;
    if (!item->class->GetFieldSet) {
      return item;
    }
    fs = item->class->GetFieldSet(item);
    return (ClientData) (ZnFIELD.GetFieldStruct(fs, part % (int) ZnFIELD.NumFields(fs)));
  }
  else if (part == ZN_NO_PART) {
    return item;
  }
  return (ClientData) (((char *) item)-part);
}


/*
 *--------------------------------------------------------------
 *
 * All tag search procs below are lifted from tkCanvas.c, then
 * modified to match our needs.
 *
 *--------------------------------------------------------------
 */

/*
 *--------------------------------------------------------------
 *
 * TagSearchExprInit --
 *
 *      This procedure allocates and initializes one
 *      TagSearchExpr struct.
 *
 *--------------------------------------------------------------
 */
static void
TagSearchExprInit(TagSearchExpr **expr_var)
{
  TagSearchExpr* expr = *expr_var;

  if (! expr) {
    expr = (TagSearchExpr *) ZnMalloc(sizeof(TagSearchExpr));
    expr->allocated = 0;
    expr->uids = NULL;
    expr->next = NULL;
  }
  expr->uid = NULL;
  expr->index = 0;
  expr->length = 0;
  *expr_var = expr;
}


/*
 *--------------------------------------------------------------
 *
 * TagSearchExprDestroy --
 *
 *      This procedure destroys one TagSearchExpr structure.
 *
 *--------------------------------------------------------------
 */
static void
TagSearchExprDestroy(TagSearchExpr      *expr)
{
  if (expr) {
    if (expr->uids) {
      ZnFree(expr->uids);
    }
    ZnFree(expr);
  }
}


/*
 *--------------------------------------------------------------
 *
 * TagSearchScanExpr --
 *
 *      This recursive procedure is called to scan a tag expression
 *      and compile it into an array of Tk_Uids.
 *
 * Results:
 *      The return value indicates if the tagOrId expression
 *      was successfully scanned (syntax).
 *      The information at *search is initialized
 *      such that a call to ZnTagSearchFirst, followed by
 *      successive calls to ZnTagSearchNext will return items
 *      that match tag.
 *
 * Side effects:
 *
 *--------------------------------------------------------------
 */
static int
TagSearchScanExpr(Tcl_Interp    *interp,        /* Current interpreter. */
                  ZnTagSearch   *search,        /* Search data */
                  TagSearchExpr *expr)          /* Compiled expression result */
{
  int   looking_for_tag; /* When true, scanner expects next char(s)
                          * to be a tag, else operand expected */
  int   found_tag;      /* One or more tags found */
  int   found_endquote; /* For quoted tag string parsing */
  int   negate_result;  /* Pending negation of next tag value */
  char  *tag;           /* tag from tag expression string */
  char  c;

  negate_result = 0;
  found_tag = 0;
  looking_for_tag = 1;
  while (search->tag_index < search->tag_len) {
    c = search->tag[search->tag_index++];
    
    if (expr->allocated == expr->index) {
      expr->allocated += 15;
      if (expr->uids) {
        expr->uids = (Tk_Uid *) ZnRealloc((char *) expr->uids,
                                          expr->allocated * sizeof(Tk_Uid));
      }
      else {
        expr->uids = (Tk_Uid *) ZnMalloc(expr->allocated * sizeof(Tk_Uid));
      }
    }
    
    if (looking_for_tag) {
      switch (c) {
      case ' ': /* ignore unquoted whitespace */
      case '\t':
      case '\n':
      case '\r':
        break;
      case '!': /* negate next tag or subexpr */
        if (looking_for_tag > 1) {
          Tcl_AppendResult(interp, "Too many '!' in tag search expression",
                           (char *) NULL);
          return TCL_ERROR;
        }
        looking_for_tag++;
        negate_result = 1;
        break;
      case '(': /* scan (negated) subexpr recursively */
        if (negate_result) {
          expr->uids[expr->index++] = neg_paren_uid;
          negate_result = 0;
        }
        else {
          expr->uids[expr->index++] = paren_uid;
        }
        if (TagSearchScanExpr(interp, search, expr) != TCL_OK) {
          /* Result string should be already set
           * by nested call to tag_expr_scan() */
          return TCL_ERROR;
        }
        looking_for_tag = 0;
        found_tag = 1;
        break;
      case '"': /* quoted tag string */
        if (negate_result) {
          expr->uids[expr->index++] = neg_tag_val_uid;
          negate_result = 0;
        }
        else {
          expr->uids[expr->index++] = tag_val_uid;
        }
        tag = search->rewrite_buf;
        found_endquote = 0;
        while (search->tag_index < search->tag_len) {
          c = search->tag[search->tag_index++];
          if (c == '\\') {
            c = search->tag[search->tag_index++];
          }
          if (c == '"') {
            found_endquote = 1;
            break;
          }
          *tag++ = c;
        }
        if (! found_endquote) {
          Tcl_AppendResult(interp, "Missing endquote in tag search expression",
                           (char *) NULL);
          return TCL_ERROR;
        }
        if (! (tag - search->rewrite_buf)) {
          Tcl_AppendResult(interp,
                           "Null quoted tag string in tag search expression",
                           (char *) NULL);
          return TCL_ERROR;
        }
        *tag++ = '\0';
        expr->uids[expr->index++] = Tk_GetUid(search->rewrite_buf);
        looking_for_tag = 0;
        found_tag = 1;
        break;
      case '&': /* illegal chars when looking for tag */
      case '|':
      case '^':
      case ')':
        Tcl_AppendResult(interp, "Unexpected operator in tag search expression",
                         (char *) NULL);
        return TCL_ERROR;
      default:  /* unquoted tag string */
        if (negate_result) {
          expr->uids[expr->index++] = neg_tag_val_uid;
          negate_result = 0;
        }
        else {
          expr->uids[expr->index++] = tag_val_uid;
        }
        tag = search->rewrite_buf;
        *tag++ = c;
        /* copy rest of tag, including any embedded whitespace */
        while (search->tag_index < search->tag_len) {
          c = search->tag[search->tag_index];
          if ((c == '!') || (c == '&') || (c == '|') || (c == '^') ||
              (c == '(') || (c == ')') || (c == '"')) {
            break;
          }
          *tag++ = c;
          search->tag_index++;
        }
        /* remove trailing whitespace */
        while (1) {
          c = *--tag;
          /* there must have been one non-whitespace char,
           *  so this will terminate */
          if ((c != ' ') && (c != '\t') && (c != '\n') && (c != '\r')) {
            break;
          }
        }
        *++tag = '\0';
        expr->uids[expr->index++] = Tk_GetUid(search->rewrite_buf);
        looking_for_tag = 0;
        found_tag = 1;
      }
      
    }
    else {    /* ! looking_for_tag */  
      switch (c) {
      case ' '  :       /* ignore whitespace */
      case '\t' :
      case '\n' :
      case '\r' :
        break;
      case '&'  :       /* AND operator */
        c = search->tag[search->tag_index++];
        if (c != '&') {
          Tcl_AppendResult(interp, "Singleton '&' in tag search expression",
                           (char *) NULL);
          return TCL_ERROR;
        }
        expr->uids[expr->index++] = and_uid;
        looking_for_tag = 1;
        break;
      case '|'  :       /* OR operator */
        c = search->tag[search->tag_index++];
        if (c != '|') {
          Tcl_AppendResult(interp, "Singleton '|' in tag search expression",
                           (char *) NULL);
          return TCL_ERROR;
        }
        expr->uids[expr->index++] = or_uid;
        looking_for_tag = 1;
        break;
      case '^'  :       /* XOR operator */
        expr->uids[expr->index++] = xor_uid;
        looking_for_tag = 1;
        break;
      case ')'  :       /* end subexpression */
        expr->uids[expr->index++] = end_paren_uid;
        goto breakwhile;
      default   :       /* syntax error */
        Tcl_AppendResult(interp,
                         "Invalid boolean operator in tag search expression",
                         (char *) NULL);
        return TCL_ERROR;
      }
    }
  }
 breakwhile:
  if (found_tag && ! looking_for_tag) {
    return TCL_OK;
  }
  Tcl_AppendResult(interp, "Missing tag in tag search expression",
                   (char *) NULL);
  return TCL_ERROR;
}


/*
 *--------------------------------------------------------------
 *
 * TagSearchEvalExpr --
 *
 *      This recursive procedure is called to eval a tag expression.
 *
 * Results:
 *      The return value indicates if the tagOrId expression
 *      successfully matched the tags of the current item.
 *
 * Side effects:
 *
 *--------------------------------------------------------------
 */
static int
TagSearchEvalExpr(TagSearchExpr *expr,  /* Search expression */
                  ZnItem        item)   /* Item being test for match */
{
  int           looking_for_tag; /* When true, scanner expects next char(s)
                                  * to be a tag, else operand expected */
  int           negate_result;  /* Pending negation of next tag value */
  Tk_Uid        uid;
  int           result=0;       /* Value of expr so far */
  int           paren_depth;
  
  negate_result = 0;
  looking_for_tag = 1;
  while (expr->index < expr->length) {
    uid = expr->uids[expr->index++];
    if (looking_for_tag) {
      if (uid == tag_val_uid) {
        /*
         * assert(expr->index < expr->length);
         */
        uid = expr->uids[expr->index++];
        /*
         * set result 1 if tag is found in item's tags
         */
        result = ZnITEM.HasTag(item, uid) ? 1 : 0;
      }
      else if (uid == neg_tag_val_uid) {
        negate_result = ! negate_result;
        /*
         * assert(expr->index < expr->length);
         */
        uid = expr->uids[expr->index++];
        /*
         * set result 1 if tag is found in item's tags
         */
        result = ZnITEM.HasTag(item, uid) ? 1 : 0;
      }
      else if (uid == paren_uid) {
        /*
         * evaluate subexpressions with recursion
         */
        result = TagSearchEvalExpr(expr, item);
      }
      else if (uid == neg_paren_uid) {
        negate_result = ! negate_result;
        /*
         * evaluate subexpressions with recursion
         */
        result = TagSearchEvalExpr(expr, item);
        /*
         * } else {
         *  assert(0);
         */
      }
      if (negate_result) {
        result = ! result;
        negate_result = 0;
      }
      looking_for_tag = 0;
    }
    else {    /* ! looking_for_tag */
      if (((uid == and_uid) && (!result)) || ((uid == or_uid) && result)) {
        /*
         * short circuit expression evaluation
         *
         * if result before && is 0, or result before || is 1, then
         * the expression is decided and no further evaluation is needed.
         */
        paren_depth = 0;
        while (expr->index < expr->length) {
          uid = expr->uids[expr->index++];
          if ((uid == tag_val_uid) || (uid == neg_tag_val_uid)) {
            expr->index++;
            continue;
          }
          if ((uid == paren_uid) || (uid == neg_paren_uid)) {
            paren_depth++;
            continue;
          } 
          if (uid == end_paren_uid) {
            paren_depth--;
            if (paren_depth < 0) {
              break;
            }
          }
        }
        return result;
        
      }
      else if (uid == xor_uid) {
        /*
         * if the previous result was 1 then negate the next result.
         */
        negate_result = result;
      }
      else if (uid == end_paren_uid) {
        return result;
        /*
         * } else {
         *  assert(0);
         */
      }
      looking_for_tag = 1;
    }
  }
  /*
   * assert(! looking_for_tag);
   */
  return result;
}


static ZnItem
LookupGroupFromPath(ZnItem       start,
                    Tk_Uid       *names,
                    unsigned int num_names)
{
  Tk_Uid        name, *tags;
  unsigned int  count;
  ZnBool        recursive;
  ZnItem        result, current = ZnGroupHead(start);

  if (num_names == 0) {
    return start;
  }

  name = names[1];
  recursive = (names[0] == star_uid);
  /*  printf("LookupGroupFromPath; group: %d, nom: %s, recursive: %s\n",
      start->id, name, names[0]);*/
  while (current != ZN_NO_ITEM) {
    if ((current->class == ZnGroup) && (current->tags)) {
      tags = ZnListArray(current->tags);
      count = ZnListSize(current->tags);
      for (; count > 0; tags++, count--) {
        if (name == *tags) {
          if (num_names > 2) {
            result = LookupGroupFromPath(current, names+2, num_names-2);
            return result;
          }
          else {
            return current;
          }
        }
      }
      /*
       * This group doesn't match try to search depth first.
       */
      if (recursive) {
        result = LookupGroupFromPath(current, names, num_names);
        if (result != ZN_NO_ITEM) {
          return result;
        }
      }
    }
    current = current->next;
  }

  return ZN_NO_ITEM;
}


/*
 *--------------------------------------------------------------
 *
 * ZnTagSearchScan --
 *
 *      This procedure is called to initiate an enumeration of
 *      all items in a given zinc that contain a tag that matches
 *      the tagOrId expression.
 *
 * Results:
 *      The return value indicates if the tagOrId expression
 *      was successfully scanned (syntax).
 *      The information at *search is initialized such that a
 *      call to ZnTagSearchFirst, followed by successive calls
 *      to ZnTagSearchNext will return items that match tag.
 *
 * Side effects:
 *      search is linked into a list of searches in progress
 *      in zinc, so that elements can safely be deleted while
 *      the search is in progress.
 *
 *--------------------------------------------------------------
 */
static int
ZnTagSearchScan(ZnWInfo   *wi,
                Tcl_Obj   *tag_obj,       /* Object giving tag value, NULL
                                           * is the same as 'all'. */
                ZnTagSearch **search_var) /* Record describing tag search;
                                           * will be initialized here. */
{
  Tk_Uid        tag;
  int           i;
  ZnTagSearch   *search;
  ZnItem        group = wi->top_group;
  ZnBool        recursive = True;

  if (tag_obj) {
    tag = Tcl_GetString(tag_obj);
  }
  else {
    tag = all_uid;
  }
  
  /*
   * Initialize the search.
   */
  if (*search_var) {
    search = *search_var;
  }
  else {
    /* Allocate primary search struct on first call */
    *search_var = search = (ZnTagSearch *) ZnMalloc(sizeof(ZnTagSearch));
    search->expr = NULL;
    
    /* Allocate buffer for rewritten tags (after de-escaping) */
    search->rewrite_buf_alloc = 100;
    search->rewrite_buf = ZnMalloc(search->rewrite_buf_alloc);
    search->item_stack = ZnListNew(16, sizeof(ZnItem));
  }
  TagSearchExprInit(&(search->expr));
  
  /* How long is the tagOrId ? */
  search->tag_len = strlen(tag);
  
  /*
   * Short-circuit impossible searches for null tags and
   * mark the search as 'over' for ZnTagSearchFirst and
   * ZnTagSearchNext. This test must not be migrated before
   * allocating search structures or special care must be
   * taken in ZnTagSearchDestroy to avoid deallocating unallocated
   * memory.
   */
  if (search->tag_len == 0) {
    search->over = True;
    return TCL_OK;
  }
  
  /*
   * If a path specification exists in the tag, strip it from the
   * tag and search for a matching group.
   */
  if (strpbrk(tag, ".*")) {
    Tk_Uid path;
    char         c, *next;
    unsigned int id;
    Tcl_HashEntry *entry;

    ZnListEmpty(ZnWorkStrings);
    recursive = False;
    if ((*tag == '.') || (*tag == '*')) {
      recursive = (*tag == '*');
      tag++;
    }
    path = tag;
    while ((next = strpbrk(path, ".*"))) {
      if (isdigit(*path)) {
        if (path == tag) { /* Group id is ok only in first section. */
          c = *next;
          *next = '\0';
          id = strtoul(path, NULL, 10);
          *next = c;
          group = wi->hot_item;
          if ((group == ZN_NO_ITEM) || (group->id != id)) {
            entry = Tcl_FindHashEntry(wi->id_table, (char *) id);
            if (entry != NULL) {
              group = (ZnItem) Tcl_GetHashValue(entry);
            }
            else {
              Tcl_AppendResult(wi->interp, "unknown group in path \"",
                               tag, "\"", NULL);
              return TCL_ERROR;
            }
          }
          if (group->class != ZnGroup) {
            Tcl_AppendResult(wi->interp, "item is not a group in path \"",
                             tag, "\"", NULL);
            return TCL_ERROR;
          }
        }
        else {
          Tcl_AppendResult(wi->interp, "misplaced group id in path \"",
                           tag, "\"", NULL);
          return TCL_ERROR;
        }
      }
      else {
        ZnListAdd(ZnWorkStrings,
                  (void *) (recursive ? &star_uid : &dot_uid),
                  ZnListTail);
        c = *next;
        *next = '\0';
        path = Tk_GetUid(path);
        *next = c;
        ZnListAdd(ZnWorkStrings, (void *) &path, ZnListTail);
      }
      recursive = (*next == '*');
      path = next+1;
    }

    group = LookupGroupFromPath(group,
                                ZnListArray(ZnWorkStrings),
                                ZnListSize(ZnWorkStrings));
    if (group == ZN_NO_ITEM) {
      Tcl_AppendResult(wi->interp, "path does not lead to a valid group\"",
                       tag, "\"", NULL);
      return TCL_ERROR;
    }

    /*
     * Adjust tag to strip the path.
     */
    tag = path;
    search->tag_len = strlen(tag);
    /*
     * If the tag consist only in a path description
     * assume that the tag all is implied.
     */
    if (search->tag_len == 0) {
      tag = all_uid;
      search->tag_len = strlen(tag);
    }
  }
  
  /*
   * Make sure there is enough buffer to hold rewritten tags (30%).
   */
  if ((unsigned int)(search->tag_len*1.3) >= search->rewrite_buf_alloc) {
    search->rewrite_buf_alloc = (unsigned int) (search->tag_len*1.3);
    search->rewrite_buf = ZnRealloc(search->rewrite_buf,
                                    search->rewrite_buf_alloc);
  }
  
  /* Initialize search */
  search->wi = wi;
  search->over = False;
  search->type = 0;
  search->group = group;
  search->recursive = recursive;
  ZnListEmpty(search->item_stack);
  
  /*
   * Find the first matching item in one of several ways. If the tag
   * is a number then it selects the single item with the matching
   * identifier.
   */
  if (isdigit(*tag)) {
    char *end;
    
    search->id = strtoul(tag, &end, 0);
    if (*end == 0) {
      search->type = 1;
      return TCL_OK;
    }
  }
  
  /*
   * Pre-scan tag for at least one unquoted "&&" "||" "^" "!"
   *   if not found then use string as simple tag
   */
  for (i = 0; i < search->tag_len; i++) {
    if (tag[i] == '"') {
      i++;
      for ( ; i < search->tag_len; i++) {
        if (tag[i] == '\\') {
          i++;
          continue;
        }
        if (tag[i] == '"') {
          break;
        }
      }
    }
    else {
      if (((tag[i] == '&') && (tag[i+1] == '&')) ||
          ((tag[i] == '|') && (tag[i+1] == '|')) ||
          (tag[i] == '^') || (tag[i] == '!')) {
        search->type = 4;
        break;
      }
    }
  }

  search->tag = tag;
  search->tag_index = 0;
  if (search->type == 4) {
    /*
     * an operator was found in the prescan, so
     * now compile the tag expression into array of Tk_Uid
     * flagging any syntax errors found
     */
    if (TagSearchScanExpr(wi->interp, search, search->expr) != TCL_OK) {
      /* Syntax error in tag expression */
      /* Result message set by TagSearchScanExpr */
      return TCL_ERROR;
    }
    search->expr->length = search->expr->index;
  }
  else {
    /*
     * For all other tags convert to a UID.
     */
    search->expr->uid = Tk_GetUid(tag);

    if (search->expr->uid == all_uid) {
      /*
       * All items match.
       */
      search->type = 2;
    }
    else {
      /*
       * Optimized single-tag search
       */
      search->type = 3;
    }
  }
  return TCL_OK;
}


/*
 *--------------------------------------------------------------
 *
 * ZnTagSearchFirst --
 *
 *      This procedure is called to get the first item
 *      item that matches a preestablished search predicate
 *      that was set by TagSearchScan.
 *
 * Results:
 *      The return value is a pointer to the first item, or NULL
 *      if there is no such item.  The information at *search
 *      is updated such that successive calls to ZnTagSearchNext
 *      will return successive items.
 *
 * Side effects:
 *      *search is linked into a list of searches in progress
 *      in zinc, so that elements can safely be deleted while
 *      the search is in progress.
 *
 *--------------------------------------------------------------
 */
static ZnItem
ZnTagSearchFirst(ZnTagSearch    *search)        /* Record describing tag search */
{
  ZnItem item, previous;

  /* short circuit impossible searches for null tags */
  if (search->over == True) {
    return ZN_NO_ITEM;
  }

  /*
   * Find the first matching item in one of several ways. If the tag
   * is a number then it selects the single item with the matching
   * identifier.  In this case see if the item being requested is the
   * hot item, in which case the search can be skipped.
   */
  if (search->type == 1) {
    Tcl_HashEntry *entry;
  
    item = search->wi->hot_item;
    previous = search->wi->hot_prev;
    if ((item == ZN_NO_ITEM) || (item->id != search->id) ||
        (previous == ZN_NO_ITEM) || (previous->next != item)) {
      entry = Tcl_FindHashEntry(search->wi->id_table, (char *) search->id);
      if (entry != NULL) {
        item = (ZnItem) Tcl_GetHashValue(entry);
        previous = item->previous;
      }
      else {
        previous = item = ZN_NO_ITEM;
      }
    }
    search->previous = previous;
    search->over = True;
    search->wi->hot_item = item;
    search->wi->hot_prev = previous;
    return item;
  }
  
  if (search->type == 2) {
    /*
     * All items match.
     */
    search->previous = ZN_NO_ITEM;
    search->current = ZnGroupHead(search->group);
    return search->current;
  }
  
  item = ZnGroupHead(search->group);
  previous = ZN_NO_ITEM;
  do {
    while (item != ZN_NO_ITEM) {
      if (search->type == 3) {
        /*
         * Optimized single-tag search
         */
        if (ZnITEM.HasTag(item, search->expr->uid)) {
          search->previous = previous;
          search->current = item;
          return item;
        }
      }
      else {
        /*
         * Type = 4.  Search for an item matching
         * the tag expression.
         */
        search->expr->index = 0;
        if (TagSearchEvalExpr(search->expr, item)) {
          search->previous = previous;
          search->current = item;
          return item;
        }
      }
      if ((item->class == ZnGroup) && (search->recursive)) {
        ZnItem prev_group = (ZnItem) search->group;
        /*
         * Explore the hierarchy depth first using the item stack
         * to save the current node.
         */
        /*printf("ZnTagSearchFirst diving for tag '%s', detph %d\n",
               search->tag, ZnListSize(search->item_stack)/2);*/
        search->group = item;
        previous = item;
        if (item == prev_group) {
          item = ZN_NO_ITEM;
        }
        else {
          item = item->next;
        }
        ZnListAdd(search->item_stack, &previous, ZnListTail);
        ZnListAdd(search->item_stack, &item, ZnListTail);
        previous = ZN_NO_ITEM;
        item = ZnGroupHead(search->group);
      }
      else {
        previous = item;
        item = item->next;
      }
    }
    /*
     * Continue search on higher group level.
     */
    /*printf("ZnTagSearchFirst backup for tag, detph %d\n",
      ZnListSize(search->item_stack)/2);*/    
    while ((item == ZN_NO_ITEM) && ZnListSize(search->item_stack)) {
      item = *(ZnItem *) ZnListAt(search->item_stack, ZnListTail);
      ZnListDelete(search->item_stack, ZnListTail);
      previous = *(ZnItem *) ZnListAt(search->item_stack, ZnListTail);
      ZnListDelete(search->item_stack, ZnListTail);
    }
    if (item != ZN_NO_ITEM) {
      search->group = item->parent;
    }
  } while (item != ZN_NO_ITEM);

  search->previous = previous;
  search->over = True;
  
  return ZN_NO_ITEM;
}


/*
 *--------------------------------------------------------------
 *
 * ZnTagSearchNext --
 *
 *      This procedure returns successive items that match a given
 *      tag;  it should be called only after ZnTagSearchFirst has
 *      been used to begin a search.
 *
 * Results:
 *      The return value is a pointer to the next item that matches
 *      the tag expr specified to TagSearchScan, or NULL if no such
 *      item exists.  *search is updated so that the next call
 *      to this procedure will return the next item.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
static ZnItem
ZnTagSearchNext(ZnTagSearch     *search) /* Record describing search in progress. */
{
  ZnItem item, previous;

  if (search->over) {
    return ZN_NO_ITEM;
  }
  /*
   * Find next item in list (this may not actually be a suitable
   * one to return), and return if there are no items left.
   */
  previous = search->previous;
  if (previous == ZN_NO_ITEM) {
    item = ZnGroupHead(search->group);
  }
  else {
    item = previous->next;
  }

  if (item != search->current) {
    /*
     * The structure of the list has changed.  Probably the
     * previously-returned item was removed from the list.
     * In this case, don't advance previous;  just return
     * its new successor (i.e. do nothing here).
     */
  }
  else if ((item->class == ZnGroup) && (search->recursive)) {
    /*
     * Explore the hierarchy depth first using the item stack
     * to save the current node.
     */
    search->group = item;
    previous = item;
    item = item->next;
    /*printf("ZnTagSearchNext diving for all, pushing %d\n",
      item?item->id:0);*/
    ZnListAdd(search->item_stack, &previous, ZnListTail);
    ZnListAdd(search->item_stack, &item, ZnListTail);
    previous = ZN_NO_ITEM;
    item = ZnGroupHead(search->group);
  }
  else {
    previous = item;
    item = previous->next;
  }
  
  if (item == ZN_NO_ITEM) {
    while ((item == ZN_NO_ITEM) && ZnListSize(search->item_stack)) {
      /*
       * End of list at this level, back up one level.
       */
      item = *(ZnItem *) ZnListAt(search->item_stack, ZnListTail);
      ZnListDelete(search->item_stack, ZnListTail);
      previous = *(ZnItem *) ZnListAt(search->item_stack, ZnListTail);
      ZnListDelete(search->item_stack, ZnListTail);
    }
    if (item != ZN_NO_ITEM) {
      search->group = item->parent;
      /*printf("ZnTagSearchNext popping %d, previous %d, next %d\n",
             item->id, (item->previous)?item->previous->id:0,
             (item->next)?item->next->id:0);*/
    }
    else {
      /*
       * Or finish the search if at top.
       */
      search->over = True;
      return ZN_NO_ITEM;
    }
  }

  if (search->type == 2) {
    /*
     * All items match.
     */
    search->previous = previous;
    search->current = item;
    return item;
  }
  
  do {
    while (item != ZN_NO_ITEM) {
      if (search->type == 3) { 
        /*
         * Optimized single-tag search
         */
        if (ZnITEM.HasTag(item, search->expr->uid)) {
          search->previous = previous;
          search->current = item;
          return item;
        }
      }
      else {
        /*
         * Else.... evaluate tag expression
         */
        search->expr->index = 0;
        if (TagSearchEvalExpr(search->expr, item)) {
          search->previous = previous;
          search->current = item;
          return item;
        }
      }
      if ((item->class == ZnGroup) && (search->recursive)) {
        /*
         * Explore the hierarchy depth first using the item stack
         * to save the current node.
         */
        /*printf("ZnTagSearchNext diving for tag, depth %d\n",
          ZnListSize(search->item_stack)/2);*/
        search->group = item;
        previous = item;
        item = item->next;
        ZnListAdd(search->item_stack, &previous, ZnListTail);
        ZnListAdd(search->item_stack, &item, ZnListTail);
        previous = ZN_NO_ITEM;
        item = ZnGroupHead(search->group);
      }
      else {
        previous = item;
        item = item->next;
      }
    }
    /*printf("ZnTagSearchNext backup for tag, depth %d\n",
      ZnListSize(search->item_stack)/2);*/
    while ((item == ZN_NO_ITEM) && ZnListSize(search->item_stack)) {
      item = *(ZnItem *) ZnListAt(search->item_stack, ZnListTail);
      ZnListDelete(search->item_stack, ZnListTail);
      previous = *(ZnItem *) ZnListAt(search->item_stack, ZnListTail);
      ZnListDelete(search->item_stack, ZnListTail);
    }
    if (item != ZN_NO_ITEM) {
      search->group = item->parent;
    }
  } while (item != ZN_NO_ITEM);

  /*
   * Out of fuel.
   */
  search->previous = previous;
  search->over = True;
  
  return ZN_NO_ITEM;
}


/*
 *--------------------------------------------------------------
 *
 * ZnTagSearchDestroy --
 *
 *      This procedure destroys any dynamic structures that
 *      may have been allocated by TagSearchScan.
 *
 *--------------------------------------------------------------
 */
void
ZnTagSearchDestroy(ZnTagSearch  *search) /* Record describing tag search */
{
  if (search) {
    TagSearchExprDestroy(search->expr);
    ZnListFree(search->item_stack);
    ZnFree(search->rewrite_buf);
    ZnFree(search);
  }
}


/*
 *----------------------------------------------------------------------
 *
 * ZnItemWithTagOrId --
 *
 *      Return the first item matching the given tag or id. The
 *      function returns the item in 'item' and the operation
 *      status as the function's value.
 *
 *----------------------------------------------------------------------
 */
int
ZnItemWithTagOrId(ZnWInfo       *wi,
                  Tcl_Obj       *tag_or_id,
                  ZnItem        *item,
                  ZnTagSearch   **search_var)
{
  if (ZnTagSearchScan(wi, tag_or_id, search_var) != TCL_OK) {
    return TCL_ERROR;
  }
  *item = ZnTagSearchFirst(*search_var);
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * LayoutItems --
 *
 *      Perform layouts on items. It can position items horizontally,
 *      vertically, along a path or with respect to a reference item.
 *      It can also align on a grid, evenly space items and resize
 *      items to a common reference.
 *
 *----------------------------------------------------------------------
 */
static int
LayoutItems(ZnWInfo     *wi,
            int         argc,
            Tcl_Obj     *CONST args[])
{
  int           index/*, result*/;
  /*ZnItem              item;*/
#ifdef PTK_800
  static char *layout_cmd_strings[] =
  #else
  static CONST char *layout_cmd_strings[] =
#endif
  {
    "align", "grid", "position", "scale", "space", NULL
  };
  enum          layout_cmds {
    ZN_L_ALIGN, ZN_L_GRID, ZN_L_POSITION, ZN_L_SCALE, ZN_L_SPACE
  };
  
  if (Tcl_GetIndexFromObj(wi->interp, args[0], layout_cmd_strings,
                          "layout command", 0, &index) != TCL_OK) {
    return TCL_ERROR;
  }
  switch((enum layout_cmds) index) {
    /*
     * align
     */
  case ZN_L_ALIGN:
    break;
    /*
     * grid
     */
  case ZN_L_GRID:
    break;
    /*
     * position
     */
  case ZN_L_POSITION:
    break;
    /*
     * scale
     */
  case ZN_L_SCALE:
    break;
    /*
     * space
     */
  case ZN_L_SPACE:
    break;
  }

  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * SetOrigin --
 *
 *      This procedure is invoked to translate the viewed area so
 *      that the given point is displayed in the top left corner.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Zinc will be redisplayed to reflect the change in ciew.
 *      The scrollbars will be updated if there are any.
 *      The top group transform is modified to achieve the effect,
 *      it is not a good idea to mix view control and application
 *      control of the top group transform.
 *
 *----------------------------------------------------------------------
 */
static void
SetOrigin(ZnWInfo       *wi,
          ZnReal        x_origin,
          ZnReal        y_origin)
{
  int   left, right, top, bottom, delta;

   /*
    * If scroll increments have been set, round the window origin
    * to the nearest multiple of the increments.
    */
  if (wi->x_scroll_incr > 0) {
    if (x_origin >= 0) {
      x_origin += wi->x_scroll_incr/2;
    }
    else {
      x_origin = (-x_origin) + wi->x_scroll_incr/2;
    }
  }
  if (wi->y_scroll_incr > 0) {
    if (y_origin >= 0) {
      y_origin += wi->y_scroll_incr/2;
    }
    else {
      y_origin = (-y_origin) + wi->y_scroll_incr/2;
    }
  }

  /*
   * Adjust the origin if necessary to keep as much as possible of the
   * canvas in the view.  The variables left, right, etc. keep track of
   * how much extra space there is on each side of the view before it
   * will stick out past the scroll region.  If one side sticks out past
   * the edge of the scroll region, adjust the view to bring that side
   * back to the edge of the scrollregion (but don't move it so much that
   * the other side sticks out now).  If scroll increments are in effect,
   * be sure to adjust only by full increments.
   */
  if (wi->confine && (wi->region != NULL)) {
    left = (int) (x_origin - wi->scroll_xo);
    right = (int) (wi->scroll_xc - (x_origin + Tk_Width(wi->win)));
    top = (int) (y_origin - wi->scroll_yo);
    bottom = (int) (wi->scroll_yc - (y_origin + Tk_Height(wi->win)));
    if ((left < 0) && (right > 0)) {
      delta = (right > -left) ? -left : right;
      if (wi->x_scroll_incr > 0) {
        delta -= delta % wi->x_scroll_incr;
      }
      x_origin += delta;
    }
    else if ((right < 0) && (left > 0)) {
      delta = (left > -right) ? -right : left;
      if (wi->x_scroll_incr > 0) {
        delta -= delta % wi->x_scroll_incr;
      }
      x_origin -= delta;
    }
    if ((top < 0) && (bottom > 0)) {
      delta = (bottom > -top) ? -top : bottom;
      if (wi->y_scroll_incr > 0) {
        delta -= delta % wi->y_scroll_incr;
      }
      y_origin += delta;
    }
    else if ((bottom < 0) && (top > 0)) {
      delta = (top > -bottom) ? -bottom : top;
      if (wi->y_scroll_incr > 0) {
        delta -= delta % wi->y_scroll_incr;
      }
      y_origin -= delta;
    }
  }

  /*
   * If the requested origin is not already set, translate the
   * top group and update the scrollbars.
   */
  if ((wi->origin.x != x_origin) || (wi->origin.y != y_origin)) {
    wi->origin.x = x_origin;
    wi->origin.y = y_origin;
    ZnITEM.ResetTransfo(wi->top_group);
    ZnITEM.TranslateItem(wi->top_group, -x_origin, -y_origin, False);
    SET(wi->flags, ZN_UPDATE_SCROLLBARS);
  }
}


/*
 *----------------------------------------------------------------------
 *
 * ScrollFractions --
 *
 *      Given the range that's visible in the window and the "100%
 *      range", return a list of two real representing the scroll
 *      fractions.  This procedure is used for both x and y scrolling.
 *
 * Results:
 *      Return a string as a Tcl_Obj holding two real numbers
 *      describing the scroll fraction (between 0 and 1) corresponding
 *      to the arguments.
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */
#ifdef PTK
static void
ScrollFractions(ZnReal  view1,  /* Lowest coordinate visible in the window. */
                ZnReal  view2,  /* Highest coordinate visible in the window. */
                ZnReal  region1,/* Lowest coordinate in the object. */
                ZnReal  region2,/* Highest coordinate in the object. */
                ZnReal  *first,
                ZnReal  *last)
#else
static Tcl_Obj *
ScrollFractions(ZnReal  view1,  /* Lowest coordinate visible in the window. */
                ZnReal  view2,  /* Highest coordinate visible in the window. */
                ZnReal  region1,/* Lowest coordinate in the object. */
                ZnReal  region2)/* Highest coordinate in the object. */
#endif
{
  ZnReal range, f1, f2;
  char   buffer[2*TCL_DOUBLE_SPACE+2];

  range = region2 - region1;
  if (range <= 0) {
    f1 = 0;
    f2 = 1.0;
  }
  else {
    f1 = (view1 - region1)/range;
    if (f1 < 0) {
      f1 = 0.0;
    }
    f2 = (view2 - region1)/range;
    if (f2 > 1.0) {
      f2 = 1.0;
    }
    if (f2 < f1) {
      f2 = f1;
    }
  }
#ifdef PTK
  *first = f1;
  *last = f2;
#else
  sprintf(buffer, "%g %g", f1, f2);
  return Tcl_NewStringObj(buffer, -1);
#endif
}


/*
 *--------------------------------------------------------------
 *
 * UpdateScrollbars --
 *
 *      This procedure is invoked whenever zinc has changed in
 *      a way that requires scrollbars to be redisplayed (e.g.
 *      the view has changed).
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      If there are scrollbars associated with zinc, then
 *      their scrolling commands are invoked to cause them to
 *      redisplay.  If errors occur, additional Tcl commands may
 *      be invoked to process the errors.
 *
 *--------------------------------------------------------------
 */
static void
UpdateScrollbars(ZnWInfo        *wi)
{
  int           result;
  Tcl_Interp    *interp;
  int           x_origin, y_origin, width, height;
  int           scroll_xo, scroll_xc, scroll_yo, scroll_yc;
#ifdef PTK
  LangCallback  *x_scroll_cmd, *y_scroll_cmd;
#else
  Tcl_Obj       *x_scroll_cmd, *y_scroll_cmd;
#endif
  Tcl_Obj       *fractions;

  /*
   * Save all the relevant values from wi, because it might be
   * deleted as part of either of the two calls to Tcl_VarEval below.
   */
  interp = wi->interp;
  Tcl_Preserve((ClientData) interp);
  x_scroll_cmd = wi->x_scroll_cmd;
  if (x_scroll_cmd != NULL) {
    Tcl_Preserve((ClientData) x_scroll_cmd);
  }
  y_scroll_cmd = wi->y_scroll_cmd;
  if (y_scroll_cmd != NULL) {
    Tcl_Preserve((ClientData) y_scroll_cmd);
  }
  x_origin = (int) wi->origin.x;
  y_origin = (int) wi->origin.y;
  width = Tk_Width(wi->win);
  height = Tk_Height(wi->win);
  scroll_xo = wi->scroll_xo;
  scroll_xc = wi->scroll_xc;
  scroll_yo = wi->scroll_yo;
  scroll_yc = wi->scroll_yc;
  CLEAR(wi->flags, ZN_UPDATE_SCROLLBARS);
  if (wi->x_scroll_cmd != NULL) {
#ifdef PTK
    ZnReal first, last;
    ScrollFractions(x_origin, x_origin + width, scroll_xo, scroll_xc, &first, &last);
    result = LangDoCallback(interp, x_scroll_cmd, 0, 2, " %g %g", first, last);
#else
    fractions = ScrollFractions(x_origin, x_origin + width, scroll_xo, scroll_xc);
    result = Tcl_VarEval(interp, Tcl_GetString(x_scroll_cmd), " ", Tcl_GetString(fractions), NULL);
    Tcl_DecrRefCount(fractions);
#endif
    if (result != TCL_OK) {
      Tcl_BackgroundError(interp);
    }
    Tcl_ResetResult(interp);
    Tcl_Release((ClientData) x_scroll_cmd);
  }
  
  if (y_scroll_cmd != NULL) {
#ifdef PTK
    ZnReal      first, last;
    ScrollFractions(y_origin, y_origin + height, scroll_yo, scroll_yc, &first, &last);
    result = LangDoCallback(interp, y_scroll_cmd, 0, 2, " %g %g", first, last);
#else
    fractions = ScrollFractions(y_origin, y_origin + height, scroll_yo, scroll_yc);
    result = Tcl_VarEval(interp, Tcl_GetString(y_scroll_cmd), " ", Tcl_GetString(fractions), NULL);
    Tcl_DecrRefCount(fractions);
#endif
    if (result != TCL_OK) {
      Tcl_BackgroundError(interp);
    }
    Tcl_ResetResult(interp);
    Tcl_Release((ClientData) y_scroll_cmd);
  }
  Tcl_Release((ClientData) interp);
}


/*
 *----------------------------------------------------------------------
 *
 * ZnDoItem --
 *
 *      Either add a tag to an item or add the item id/part to the
 *      interpreter result, depending on the value of tag. If tag
 *      is NULL, the item id/part is added to the result, otherwise
 *      the tag is added to the item.
 *
 *----------------------------------------------------------------------
 */
void
ZnDoItem(Tcl_Interp     *interp,
         ZnItem         item,
         int            part,
         Tk_Uid         tag_uid)
{
  if (tag_uid == NULL) {
    Tcl_Obj  *l;
    l = Tcl_GetObjResult(interp);
    Tcl_ListObjAppendElement(interp, l, Tcl_NewLongObj(item->id));
    if (part != ZN_NO_PART) {
      Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(part));
    }
  }
  else {
    /*printf("Adding tag %s to item %d\n", tag_uid, item->id);*/
    ZnITEM.AddTag(item, tag_uid);
  }
}


/*
 *----------------------------------------------------------------------
 *
 * FindArea --
 *      Search the items that are enclosed or overlapping a given
 *      area of the widget. It is used by FindItems.
 *      If tag_uid is not NULL, all the items found are tagged with
 *      tag_uid. If tag_uid is NULL, the items found are added to the
 *      interp result. If enclosed is 1, the search look for
 *      items enclosed in the area. If enclosed is 0, it looks
 *      for overlapping and enclosed items.
 *      If an error occurs, a message is left in the interp result
 *      and TCL_ERROR is returned.
 *
 *----------------------------------------------------------------------
 */
static int
FindArea(ZnWInfo        *wi,
         Tcl_Obj *CONST args[],
         Tk_Uid         tag_uid,
         ZnBool         enclosed,
         ZnBool         recursive,
         ZnBool         override_atomic,
         ZnItem         group)
{
  ZnPos         pos;
  ZnBBox        area;
  ZnToAreaStruct ta;
  double        d;

  if (Tcl_GetDoubleFromObj(wi->interp, args[0], &d) == TCL_ERROR) {
    return TCL_ERROR;
  }
  area.orig.x = d;
  if (Tcl_GetDoubleFromObj(wi->interp, args[1], &d) == TCL_ERROR) {
    return TCL_ERROR;
  }
  area.orig.y = d;
  if (Tcl_GetDoubleFromObj(wi->interp, args[2], &d) == TCL_ERROR) {
    return TCL_ERROR;
  }
  area.corner.x = d;
  if (Tcl_GetDoubleFromObj(wi->interp, args[3], &d) == TCL_ERROR) {
    return TCL_ERROR;
  }
  area.corner.y = d;
  if (area.corner.x < area.orig.x) {
    pos = area.orig.x;
    area.orig.x = area.corner.x;
    area.corner.x = pos;
  }
  if (area.corner.y < area.orig.y) {
    pos = area.orig.y;
    area.orig.y = area.corner.y;
    area.corner.y = pos;
  }
  area.corner.x += 1;
  area.corner.y += 1;

  ta.tag_uid = tag_uid;
  ta.enclosed = enclosed;
  ta.in_group = group;
  ta.recursive = recursive;
  ta.override_atomic = override_atomic;
  ta.report = False;
  ta.area = &area;
  wi->top_group->class->ToArea(wi->top_group, &ta);
  
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * FindItems --
 *
 *      This procedure interprets the small object query langage for
 *      commands like addtag and find.
 *      If new_tag is NULL, the procedure collects all the objects
 *      matching the request and return them in the interpreter result.
 *      If new_tag is non NULL, it is interpreted as the tag to add to
 *      all matching objects. In this case the interpreter result is
 *      left empty.
 *
 *----------------------------------------------------------------------
 */
static int
FindItems(ZnWInfo       *wi,
          int           argc,
          Tcl_Obj *CONST args[],
          Tcl_Obj       *tag,           /* NULL to search or tag to add tag. */
          int           first,          /* First arg to process in args */
          ZnTagSearch   **search_var)
{
  Tk_Uid        tag_uid = NULL;
  int           index, result;
  ZnItem        item;
  ZnPickStruct  ps;
  char          *str;
#ifdef PTK_800
  static char *search_cmd_strings[] =
#else
  static CONST char *search_cmd_strings[] =
#endif
  {
    "above", "ancestors", "atpriority", "below", "closest", "enclosed",
    "overlapping", "withtag", "withtype", NULL
  };
  enum          search_cmds {
    ZN_S_ABOVE, ZN_S_ANCESTORS, ZN_S_ATPRIORITY, ZN_S_BELOW, ZN_S_CLOSEST,
    ZN_S_ENCLOSED, ZN_S_OVERLAPPING, ZN_S_WITHTAG, ZN_S_WITHTYPE
  };
  
  if (Tcl_GetIndexFromObj(wi->interp, args[first], search_cmd_strings,
                          "search command", 0, &index) != TCL_OK) {
    return TCL_ERROR;
  }
  
  if (tag) {
    tag_uid = Tk_GetUid(Tcl_GetString(tag));
  }
  
  switch((enum search_cmds) index) {
    /*
     * above
     */
  case ZN_S_ABOVE:
    {
      if (argc != first+2) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "tagOrId");
        return TCL_ERROR;
      }
      result = ZnItemWithTagOrId(wi, args[first+1], &item, search_var);
      if (result == TCL_OK) {
        if ((item != ZN_NO_ITEM) && (item->previous != ZN_NO_ITEM)) {
          ZnDoItem(wi->interp, item->previous, ZN_NO_PART, tag_uid);
        }
      }
      else {
        return TCL_ERROR;
      }
    }
    break;
    /*
     * ancestors
     */
  case ZN_S_ANCESTORS:
    {
      Tk_Uid uid = NULL;
      if ((argc != first+2) && (argc != first+3)) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "tagOrId ?withTag?");
        return TCL_ERROR;
      }
      result = ZnItemWithTagOrId(wi, args[first+1], &item, search_var);
      if (result == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (item) {
        item = item->parent;
        if (argc == first+3) {
          uid = Tk_GetUid(Tcl_GetString(args[first+2]));
        }
        while (item != ZN_NO_ITEM) {
          if (!uid || ZnITEM.HasTag(item, uid)) {
            ZnDoItem(wi->interp, item, ZN_NO_PART, tag_uid);
          }
          item = item->parent;
        }
      }
    }
    break;
      /*
       * atpriority
       */
  case ZN_S_ATPRIORITY:
    {
      int pri;
      
      if ((argc != first+2) && (argc != first+3)) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "pri ?tagOrId?");
        return TCL_ERROR;
      }
      if ((Tcl_GetIntFromObj(wi->interp, args[first+1], &pri) == TCL_ERROR) ||
          (pri < 0)){
        return TCL_ERROR;
      }
      
      /*
       * Go through the item table and collect all items with
       * the given priority.
       */
      if (ZnTagSearchScan(wi, (argc == first+3) ? args[first+2] : NULL,
                          search_var) == TCL_ERROR) {
        return TCL_ERROR;
      }
      for (item = ZnTagSearchFirst(*search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(*search_var)) {
        if (item->priority == (unsigned int) pri) {
          ZnDoItem(wi->interp, item, ZN_NO_PART, tag_uid);
        }
      }
    }
    break;
    /*
     * below
     */
  case ZN_S_BELOW:
    {
      ZnItem    next;
      
      if (argc != first+2) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "tagOrId");
        return TCL_ERROR;
      }
      item = ZN_NO_ITEM;
      if (ZnTagSearchScan(wi, args[first+1], search_var) == TCL_ERROR) {
        return TCL_ERROR;
      }
      for (next = ZnTagSearchFirst(*search_var);
           next != ZN_NO_ITEM; next = ZnTagSearchNext(*search_var)) {
        item = next;
      }
      if ((item != ZN_NO_ITEM) && (item->next != ZN_NO_ITEM)) {
        ZnDoItem(wi->interp, item->next, ZN_NO_PART, tag_uid);
      }
    }
    break;
    /*
     * closest
     */
  case ZN_S_CLOSEST:
    {
      int       halo = 1;
      ZnPoint   p;
      double    d;

      if ((argc < first+3) || (argc > first+6)) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "x y ?halo? ?start?, ?recursive?");
        return TCL_ERROR;      
      }
      if (Tcl_GetDoubleFromObj(wi->interp, args[first+1], &d) == TCL_ERROR) {
        return TCL_ERROR;
      }
      p.x = d;
      if (Tcl_GetDoubleFromObj(wi->interp, args[first+2], &d) == TCL_ERROR) {
        return TCL_ERROR;
      }
      p.y = d;
      if (argc > first+3) {
        if (Tcl_GetIntFromObj(wi->interp, args[first+3], &halo) == TCL_ERROR) {
          return TCL_ERROR;
        }
        if (halo < 0) {
          halo = 0;
        }
      }

      ps.in_group = ZN_NO_ITEM;
      ps.start_item = ZN_NO_ITEM;
      item = ZN_NO_ITEM;      
      if (argc > (first+4)) {
        result = ZnItemWithTagOrId(wi, args[first+4], &item, search_var);
        if ((result == TCL_OK) && (item != ZN_NO_ITEM)) {
          if ((item->class == ZnGroup) && !ZnGroupAtomic(item)) {
            ps.in_group = item;
          }
          else {
            ps.in_group = item->parent;
            ps.start_item = item->next;
          }
        }
      }
      ps.recursive = True;
      ps.override_atomic = False;
      if (argc > first+5) {
        result = Tcl_GetBooleanFromObj(wi->interp, args[first+5], &ps.recursive);
        if (result != TCL_OK) {
          str = Tcl_GetString(args[first+5]);
          if (strcmp(str, "override") != 0) { 
            Tcl_AppendResult(wi->interp,
                             "recursive should be a boolean value or ",
                             "override \"", str, "\"", NULL);
            return TCL_ERROR;
          }
          ps.recursive = True;
          ps.override_atomic = True;
        }
      }
      /*
       * We always start the search at the top group to use the
       * transform and clip machinery of the group item. The items
       * are not required to cache the device coords, etc. So we need
       * to setup the correct context before calling the Pick method
       * for each item.
       */
      ps.aperture = halo;
      ps.point = &p;
      wi->top_group->class->Pick(wi->top_group, &ps);
      
      if (ps.a_item != ZN_NO_ITEM) {
        ZnDoItem(wi->interp, ps.a_item, ps.a_part, tag_uid);
        /*printf("first %d %d\n", ps.a_item->id, ps.a_part);*/
      }
    }
    break;
    /*
     * enclosed
     */
  case ZN_S_ENCLOSED:
    {
      if ((argc < first+5) || (argc > first+7)) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "x1 y1 x2 y2 ?inGroup? ?recursive?");
        return TCL_ERROR;
      }
      item = wi->top_group;
      if (argc > first+5) {
        result = ZnItemWithTagOrId(wi, args[first+5], &item, search_var);
        if ((result != TCL_OK) || (item == ZN_NO_ITEM) || (item->class != ZnGroup)) {
          return TCL_ERROR;
        }
      }
      ps.recursive = True;
      ps.override_atomic = False;
      if (argc > first+6) {
        result = Tcl_GetBooleanFromObj(wi->interp, args[first+6], &ps.recursive);
        if (result != TCL_OK) {
          str = Tcl_GetString(args[first+6]);
          if (strcmp(str, "override") != 0) { 
            Tcl_AppendResult(wi->interp,
                             "recursive should be a boolean value or ",
                             "override \"", str, "\"", NULL);
            return TCL_ERROR;
          }
          ps.recursive = True;
          ps.override_atomic = True;
        }
      }
      return FindArea(wi, args+first+1, tag_uid,
                      True, ps.recursive, ps.override_atomic,
                      item);
    }
    break;
    /*
     * overlapping
     */
  case ZN_S_OVERLAPPING:
    {
      if ((argc < first+5) || (argc > first+7)) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "x1 y1 x2 y2 ?inGroup? ?recursive?");
        return TCL_ERROR;
      }
      item = wi->top_group;
      if (argc > first+5) {
        result = ZnItemWithTagOrId(wi, args[first+5], &item, search_var);
        if ((result != TCL_OK) || (item == ZN_NO_ITEM) || (item->class != ZnGroup)) {
          return TCL_ERROR;
        }
      }
      ps.recursive = True;
      ps.override_atomic = False;
      if (argc > first+6) {
        result = Tcl_GetBooleanFromObj(wi->interp, args[first+6], &ps.recursive);
        if (result != TCL_OK) {
          str = Tcl_GetString(args[first+6]);
          if (strcmp(str, "override") != 0) { 
            Tcl_AppendResult(wi->interp,
                             "recursive should be a boolean value or ",
                             "override \"", str, "\"", NULL);
            return TCL_ERROR;
          }
          ps.recursive = True;
          ps.override_atomic = True;
        }
      }
      return FindArea(wi, args+first+1, tag_uid,
                      False, ps.recursive, ps.override_atomic,
                      item);
    }
    break;
    /*
     * withtag
     */
  case ZN_S_WITHTAG:
    {
      if (argc != first+2) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "tagOrId");
        return TCL_ERROR;
      }
      if (ZnTagSearchScan(wi, args[first+1], search_var) == TCL_ERROR) {
        return TCL_ERROR;
      }
      for (item = ZnTagSearchFirst(*search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(*search_var)) {
        ZnDoItem(wi->interp, item, ZN_NO_PART, tag_uid);
      }
    }
    break;
    /*
     * withtype
     */
  case ZN_S_WITHTYPE:
    {
      ZnItemClass       cls;
      
      if ((argc != first+2) && (argc != first+3)) {
        Tcl_WrongNumArgs(wi->interp, first+1, args, "itemType ?tagOrId?");
        return TCL_ERROR;
      }
      cls = ZnLookupItemClass(Tcl_GetString(args[first+1]));
      if (!cls) {
        Tcl_AppendResult(wi->interp, "unknown item type \"",
                         Tcl_GetString(args[first+1]), "\"", NULL);
        return TCL_ERROR;
      }
      
      /*
       * Go through the item table and collect all items with
       * the given item type.
       */
      if (ZnTagSearchScan(wi, (argc == first+3) ? args[first+2] : NULL,
                          search_var) == TCL_ERROR) {
        return TCL_ERROR;
      }
      for (item = ZnTagSearchFirst(*search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(*search_var)) {
        if (item->class == cls) {
          ZnDoItem(wi->interp, item, ZN_NO_PART, tag_uid);
        }
      }
    }
    break;
  }
  
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * ZnParseCoordList --
 *
 *----------------------------------------------------------------------
 */
int
ZnParseCoordList(ZnWInfo        *wi,
                 Tcl_Obj        *arg,
                 ZnPoint        **pts,
                 char           **controls,
                 unsigned int   *num_pts,
                 ZnBool         *old_format)
{
  Tcl_Obj       **elems, **selems;
  int           i, result, num_elems, num_selems;
  ZnPoint       *p;
  int           old_style, len;
  char          *str;
  double        d;

  if (controls) {
    *controls = NULL;
  }
  if (old_format) {
    *old_format = True;
  }
  result = Tcl_ListObjGetElements(wi->interp, arg, &num_elems, &elems);
  if (result == TCL_ERROR) {
  coord_error:
    Tcl_AppendResult(wi->interp, " malformed coord list", NULL);
    return TCL_ERROR;
  }
  if (num_elems == 0) {
    *num_pts = 0;
    *pts = NULL;
    return TCL_OK;
  }

  /*
   * If first element is not a sublist, consider the whole list
   * as a flat array of coordinates in the old style. It can still
   * be a single point with or without a control flag.
   * If not, the list consists in sublists describing each point
   * with its control flag.
   */
  result = Tcl_GetDoubleFromObj(wi->interp, elems[0], &d);
  old_style = (result == TCL_OK);

  if (old_style) {
    if ((num_elems%2) == 0) {
      *num_pts = num_elems/2;
      ZnListAssertSize(ZnWorkPoints, *num_pts);
      *pts = p = (ZnPoint *) ZnListArray(ZnWorkPoints);
      for (i = 0; i < num_elems; i += 2, p++) {
        if (Tcl_GetDoubleFromObj(wi->interp, elems[i], &d) == TCL_ERROR) {
          goto coord_error;
        }
        p->x = d;
        if (Tcl_GetDoubleFromObj(wi->interp, elems[i+1], &d) == TCL_ERROR) {
          goto coord_error;
        }
        p->y = d;
        /*printf("Parsed a point: %g@%g, ", p->x, p->y);*/
      }
      /*printf("\n");*/
    }
    else if (num_elems == 3) {
      *num_pts = 1;
      ZnListAssertSize(ZnWorkPoints, *num_pts);
      *pts = p = (ZnPoint *) ZnListArray(ZnWorkPoints);
      if (Tcl_GetDoubleFromObj(wi->interp, elems[0], &d) == TCL_ERROR) {
        goto coord_error;
      }
      p->x = d;
      if (Tcl_GetDoubleFromObj(wi->interp, elems[1], &d) == TCL_ERROR) {
        goto coord_error;
      }
      p->y = d;
      if (controls) {
        if (! *controls) {
          *controls = ZnMalloc(*num_pts * sizeof(char));
          memset(*controls, 0, *num_pts * sizeof(char));
        }
        str = Tcl_GetStringFromObj(elems[2], &len);
        if (len) {
          (*controls)[0] = str[0];
        }
      }
    }
    else {
      goto coord_error;
    }
  }
  else {
    Tcl_ResetResult(wi->interp);
    *num_pts = num_elems;
    ZnListAssertSize(ZnWorkPoints, *num_pts);
    *pts = p = (ZnPoint *) ZnListArray(ZnWorkPoints);
    for (i = 0; i < num_elems; i++, p++) {
      result = Tcl_ListObjGetElements(wi->interp, elems[i], &num_selems, &selems);
      if ((result == TCL_ERROR) || (num_selems < 2) || (num_selems > 3)) {
        goto coord_error;
      }
      if (Tcl_GetDoubleFromObj(wi->interp, selems[0], &d) == TCL_ERROR) {
        goto coord_error;
      }
      p->x = d;
      if (Tcl_GetDoubleFromObj(wi->interp, selems[1], &d) == TCL_ERROR) {
        goto coord_error;
      }
      p->y = d;
      if (controls) {
        if (num_selems == 3) {
          if (! *controls) {
            *controls = ZnMalloc(*num_pts * sizeof(char));
            memset(*controls, 0, *num_pts * sizeof(char));
          }
          str = Tcl_GetStringFromObj(selems[2], &len);
          if (len) {
            (*controls)[i] = str[0];
          }
        }
      }
    }
  }
  
  if (old_format) {
    *old_format = old_style;
  }
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * Contour --
 *
 *----------------------------------------------------------------------
 */
static int
Contour(ZnWInfo *wi,
        int             argc,
        Tcl_Obj *CONST  args[],
        ZnTagSearch     **search_var)
{
  ZnPoint       *points;
  ZnItem        item, shape;
  unsigned int  i, j, k,num_points;
  int           cmd, cw, result;
  int           winding_flag, revert = False;
  long          index;
  char          *controls;
  ZnBool        simple=False;
  ZnPoly        poly;
  ZnTransfo     t, inv;
  ZnContour     *contours;

  /* Keep this array in sync with ZnContourCmd in Types.h */
#ifdef PTK_800
  static char *op_strings[] =
#else
  static CONST char *op_strings[] =
#endif
  {
    "add", "remove", NULL
  };
  
  result = ZnItemWithTagOrId(wi, args[2], &item, search_var);
  if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)){
    Tcl_AppendResult(wi->interp, "unknown item \"", Tcl_GetString(args[2]),
                     "\"", NULL);
    return TCL_ERROR;
  }
  if (!item->class->Contour) {
    if (item->class->GetClipVertices ||
        item->class->GetContours) {
      Tcl_SetObjResult(wi->interp, Tcl_NewIntObj(1));
    }
    else {
      Tcl_SetObjResult(wi->interp, Tcl_NewIntObj(0));
    }
    return TCL_OK;
  }
  if (argc == 3) {
    /*
     * Requesting the number of contours.
     */
    Tcl_SetObjResult(wi->interp, Tcl_NewIntObj(item->class->Contour(item, -1, 0, NULL)));
    return TCL_OK;    
  }
  /*
   * Get the sub-command
   */
  if (Tcl_GetIndexFromObj(wi->interp, args[3], op_strings,
                          "contour operation", 0, &cmd) != TCL_OK) {
    return TCL_ERROR;
  }
  /*
   * Get the winding flag.
   */
  if ((Tcl_GetIntFromObj(wi->interp, args[4], &winding_flag) != TCL_OK) ||
      (winding_flag < -1) || (winding_flag > 1)) {
    Tcl_AppendResult(wi->interp, " incorrect winding flag, should be -1, 0, 1, \"",
                     Tcl_GetString(args[4]), "\"", NULL);
    return TCL_ERROR;
  }
  index = ZnListTail;
  if (((argc == 6) && (cmd == ZN_CONTOUR_REMOVE)) || (argc == 7)) {
    /* Look for an index value. */
    if (Tcl_GetLongFromObj(wi->interp, args[5], &index) != TCL_OK) {
      Tcl_AppendResult(wi->interp, " incorrect contour index \"",
                       Tcl_GetString(args[5]), "\"", NULL);
      return TCL_ERROR;
    }
    argc--;
    args++;
  }

  if (cmd == ZN_CONTOUR_REMOVE) {
    Tcl_SetObjResult(wi->interp, Tcl_NewIntObj(item->class->Contour(item, ZN_CONTOUR_REMOVE, index, NULL)));
  }
  else {
    result = ZnItemWithTagOrId(wi, args[5], &shape, search_var);
    if ((result == TCL_ERROR) || (shape == ZN_NO_ITEM)) {
      Tcl_ResetResult(wi->interp);
      if (ZnParseCoordList(wi, args[5], &points,
                           &controls, &num_points, NULL) == TCL_ERROR) {
        return TCL_ERROR;
      }
      /*
       * Processing contours from an explicit list.
       */
      ZnPolyContour1(&poly, NULL, num_points, False);
      /*
       * Allocate a fresh point array, ZnParseCoordList returns a shared
       * array. The control array is not shared and can be passed along.
       */
      poly.contours[0].points = ZnMalloc(num_points*sizeof(ZnPoint));
      cw = poly.contours[0].cw = !ZnTestCCW(points, num_points);
      if (winding_flag != 0) {
        revert = cw ^ (winding_flag == -1);
      }
      if (revert) {
        /* Revert the contour */
        for (i = 0; i < num_points; i++) {
          poly.contours[0].points[num_points-i-1] = points[i];
        }
        if (controls) {
          char ch;
          for (i = 0, j = num_points-1; i < j; i++, j--) {
            ch = controls[i];
            controls[i] = controls[j];
            controls[j] = ch;
          }
        }
      }
      else {
        memcpy(poly.contours[0].points, points, num_points*sizeof(ZnPoint));
      }
      poly.contours[0].controls = controls;
    }
    else {
      /*
       * Processing contours from an item
       */
      if (winding_flag == 0) {
        Tcl_AppendResult(wi->interp,
                         "Must supply an explicit winding direction (-1, 1)\nwhen adding a contour from an item",
                         NULL);
        return TCL_ERROR;
      }
      /*
       * If something has changed in the geometry we need to
       * update or the shape will be erroneous.
       */
      Update(wi);
      if (!shape->class->GetContours &&
          !shape->class->GetClipVertices) {
        Tcl_AppendResult(wi->interp, "class: \"", shape->class->name,
                         "\" can't give a polygonal shape", NULL);
        return TCL_ERROR;
      }
      if (!shape->class->GetContours) {
        ZnTriStrip      tristrip;
        /*
         * If there is no GetContours method try to use
         * the GetClipVertices. It works only for simple
         * shapes (i.e tose returning a bounding box).
         */
        tristrip.num_strips = 0;
        /*
         * GetClipVertices _may_ return a tristrip describing a fan
         * this would lead to strange results. For now, this case
         * should not appear, the items candidates to such a behavior
         * export a GetContours method which has higher precedence.
         */
        simple = shape->class->GetClipVertices(shape, &tristrip);
        ZnPolyContour1(&poly, tristrip.strip1.points, tristrip.strip1.num_points,
                       False);
        poly.contours[0].controls = NULL;
      }
      else {
        poly.num_contours = 0;
        simple = shape->class->GetContours(shape, &poly);
      }
      if (poly.num_contours == 0) {
        return TCL_OK;
      }
      /*
       * Compute the tranform to map the device points
       * into the coordinate space of item.
       */
      ZnITEM.GetItemTransform(item, &t);
      ZnTransfoInvert(&t, &inv);
      /*
       * Make a new transformed poly and unshare
       * the contour(s) returned by the item.
       */
      if (simple) {
        ZnPoint p[4];
        p[0] = poly.contours[0].points[0];
        p[2] = poly.contours[0].points[1];
        if (winding_flag == -1) {
          p[1].x = p[2].x;
          p[1].y = p[0].y;
          p[3].x = p[0].x;
          p[3].y = p[2].y;
        }
        else {
          p[1].x = p[0].x;
          p[1].y = p[2].y;
          p[3].x = p[2].x;
          p[3].y = p[0].y;
        }
        points = ZnMalloc(4*sizeof(ZnPoint));
        ZnTransformPoints(&inv, p, points, 4);
        poly.contours[0].points = points;
        poly.contours[0].num_points = 4;
        poly.contours[0].cw = (winding_flag == -1);
        poly.contours[0].controls = NULL;
      }
      else {
        /* Unshare the contour array or use the static storage */
        contours = poly.contours;
        if (poly.num_contours == 1) {
          poly.contours = &poly.contour1;
        }
        else {
          poly.contours = ZnMalloc(poly.num_contours*sizeof(ZnContour));
        }
        for (i = 0; i < poly.num_contours; i++) {
          points = contours[i].points;
          num_points = contours[i].num_points;
          cw = contours[i].cw;
          poly.contours[i].num_points = num_points;
          poly.contours[i].cw = cw;
          if (contours[i].controls) {
            /* 
             * The controls array returned by GetContour is shared.
             * Here we unshare it.
             */
            poly.contours[i].controls = ZnMalloc(num_points*sizeof(char));
          }
          /*
           * Unshare the point array.
           */
          poly.contours[i].points = ZnMalloc(num_points*sizeof(ZnPoint));
          ZnTransformPoints(&inv, points, poly.contours[i].points, num_points);
          
          if ((((poly.num_contours == 1) && ((winding_flag == -1) ^ cw)) ||
               ((poly.num_contours > 1) && (winding_flag == -1)))) {
            ZnPoint p;
            
            revert = True;
            /* Revert the points */
            poly.contours[i].cw = ! cw;
            for (j = 0, k = num_points-1; j < k; j++, k--) {
              p = poly.contours[i].points[j];
              poly.contours[i].points[j] = poly.contours[i].points[k];
              poly.contours[i].points[k] = p;
            }
            
            /* Revert the controls */
            if (contours[i].controls) {
              for (j = 0; j < num_points; j++) {
                poly.contours[i].controls[num_points-j-1] = contours[i].controls[j];
              }
            }
          }
          else {
            if (contours[i].controls) {
              memcpy(poly.contours[i].controls, contours[i].controls, num_points);
            }
          }
        }
      }
    }

    result = item->class->Contour(item, ZN_CONTOUR_ADD, index, &poly);
    if (revert) {
      result = -result;
    }
    Tcl_SetObjResult(wi->interp, Tcl_NewIntObj(result));
    
    if (poly.contours != &poly.contour1) {
      /*
       * Must not use ZnPolyFree: the point and controls arrays
       * are passed along to the item and no longer ours.
       */
      ZnFree(poly.contours);
    }
  }

  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * Coords --
 *
 *----------------------------------------------------------------------
 */
static int
Coords(ZnWInfo          *wi,
       int              argc,
       Tcl_Obj  *CONST  args[],
       ZnTagSearch      **search_var)
{
  ZnPoint       *points;
  ZnItem        item;
  unsigned int  num_points, i;
  int           result, cmd = ZN_COORDS_READ;
  long          index, contour = 0;
  char          *str, *controls = NULL;
  Tcl_Obj       *l, *entries[3];
  
  result = ZnItemWithTagOrId(wi, args[2], &item, search_var);
  if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
    Tcl_AppendResult(wi->interp, " unknown item \"",
                     Tcl_GetString(args[2]), "\"", NULL);
    return TCL_ERROR;
  }
  if (!item->class->Coords) {
    Tcl_AppendResult(wi->interp, " ", item->class->name,
                     " does not support the coords command", NULL);
    return TCL_ERROR;
  }
  num_points = 0;
  /*printf("  coords: argc=%d, item %d class: %s\n",
    argc, item->id, item->class->name);*/
  if (argc == 3) {
    /* Get all coords of default contour (0). */
    if (item->class->Coords(item, 0, 0, ZN_COORDS_READ_ALL,
                            &points, &controls, &num_points) == TCL_ERROR) {
      return TCL_ERROR;
    }
  coords_read:
    /*printf("  coords: read %d points, first is %g@%g\n",
      num_points, points->x, points->y);*/
    l = Tcl_GetObjResult(wi->interp);
    if (ISSET(item->class->flags, ZN_CLASS_ONE_COORD)) {
      Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewDoubleObj(points->x));
      Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewDoubleObj(points->y));      
      if (controls && *controls) {
        Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewStringObj(controls, 1));
      }
    }
    else {
      for (i = 0; i < num_points; i++, points++) {
        entries[0] = Tcl_NewDoubleObj(points->x);
        entries[1] = Tcl_NewDoubleObj(points->y);
        if (controls && controls[i]) {
          entries[2] = Tcl_NewStringObj(&controls[i], 1);
          Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewListObj(3, entries));
        }
        else {
          Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewListObj(2, entries));
        }
      }
    }
    return TCL_OK;
  }

  /*
   * See if it is an ADD or REMOVE op.
   */
  i = 3;
  str = Tcl_GetString(args[3]);
  if ((str[0] == 'a') && (strcmp(str, "add") == 0)) {
    if ((argc < 5) || (argc > 7)) {
      Tcl_WrongNumArgs(wi->interp, 1, args,
                       "coords tagOrId add ?contour? ?index? coordList");
      return TCL_ERROR;
    }
    cmd = ZN_COORDS_ADD;
    i++;
  }
  else if ((str[0] == 'r') && (strcmp(str, "remove") == 0)) {
    if ((argc != 5) && (argc != 6)) {
      Tcl_WrongNumArgs(wi->interp, 1, args,
                       "coords tagOrId remove ?contour? index");
      return TCL_ERROR;
    }
    cmd = ZN_COORDS_REMOVE;
    i++;
  }
  
  /*
   * Try to see if the next param is a vertex index,
   * a contour index or a coord list.
   */
  /* printf("  coords: arg %d is %s\n", i, Tcl_GetString(args[i])); */
  if (Tcl_GetLongFromObj(wi->interp, args[i], &index) != TCL_OK) {
    Tcl_ResetResult(wi->interp);
    if (((argc == 5) && (cmd != ZN_COORDS_ADD) && (cmd != ZN_COORDS_REMOVE)) ||
        (argc == 6) || (argc == 7)) {
      Tcl_AppendResult(wi->interp, " incorrect contour index \"",
                       Tcl_GetString(args[i]), "\"", NULL);
      return TCL_ERROR;
    }
    else if ((argc == 5) && (cmd != ZN_COORDS_ADD)) {
      Tcl_AppendResult(wi->interp, " incorrect coord index \"",
                       Tcl_GetString(args[i]), "\"", NULL);
      return TCL_ERROR;
    }
    else if (ZnParseCoordList(wi, args[argc-1], &points,
                              &controls, &num_points, NULL) == TCL_ERROR) {
      return TCL_ERROR;
    }
    if (cmd == ZN_COORDS_ADD) {
      /* Append coords at end of default contour (0). */
      if (item->class->Coords(item, 0, 0, ZN_COORDS_ADD_LAST,
                              &points, &controls, &num_points) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    else {
      /* Set all coords of default contour (0). */
      if (item->class->Coords(item, 0, 0, ZN_COORDS_REPLACE_ALL,
                              &points, &controls, &num_points) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    if (controls) {
      ZnFree(controls);
    }
    return TCL_OK;
  }

  contour = index;
  if (argc == 4) {
    /* Get all coords of contour. */
    if (item->class->Coords(item, contour, 0, ZN_COORDS_READ_ALL,
                            &points, &controls, &num_points) == TCL_ERROR) {
      return TCL_ERROR;
    }
    goto coords_read;
  }
  else if ((argc == 5) && (cmd == ZN_COORDS_REMOVE)) {
    /*  Remove coord at index in default contour (0). */
    if (item->class->Coords(item, 0, index, ZN_COORDS_REMOVE,
                            &points, &controls, &num_points) == TCL_ERROR) {
      return TCL_ERROR;
    }
    return TCL_OK;
  }
  /*
   * Try to see if the next param is a vertex index or a coord list.
   */
  i++;
  /*printf("  coords: arg %d is %s\n", i, Tcl_GetString(args[i]));*/
  if (Tcl_GetLongFromObj(wi->interp, args[i], &index) != TCL_OK) {
    Tcl_ResetResult(wi->interp);
    if ((argc == 7) || ((argc == 6) && (cmd != ZN_COORDS_ADD))) {
      Tcl_AppendResult(wi->interp, " incorrect coord index \"",
                       Tcl_GetString(args[i]), "\"", NULL);
      return TCL_ERROR;
    }
    else if (ZnParseCoordList(wi, args[argc-1], &points,
                              &controls, &num_points, NULL) == TCL_ERROR) {
      return TCL_ERROR;
    }
    if (cmd == ZN_COORDS_ADD) {
      /* Append coords at end of contour. */
      if (item->class->Coords(item, contour, 0, ZN_COORDS_ADD_LAST,
                              &points, &controls, &num_points) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    else {
      /* Set all coords of contour. */
      if (item->class->Coords(item, contour, 0, ZN_COORDS_REPLACE_ALL,
                              &points, &controls, &num_points) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    if (controls) {
      ZnFree(controls);
    }
    return TCL_OK;
  }
  if (argc == 5) {
    /* Get coord of contour at index. */
    if (item->class->Coords(item, contour, index, ZN_COORDS_READ,
                            &points, &controls, &num_points) == TCL_ERROR) {
      return TCL_ERROR;
    }
    if (num_points) {
      /*printf("  coords: read contour:%d, index:%d, point is %g@%g\n",
        contour, index, points->x, points->y);    */
      l = Tcl_GetObjResult(wi->interp);
      Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewDoubleObj(points->x));
      Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewDoubleObj(points->y));
      if (controls && *controls) {
        Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewStringObj(controls, 1));
      }
    }
    return TCL_OK;
  }
  else if ((argc == 6) && (cmd == ZN_COORDS_REMOVE)) {
    /*  Remove coord of contour at index. */
    if (item->class->Coords(item, contour, index, ZN_COORDS_REMOVE,
                            &points, &controls, &num_points) == TCL_ERROR) {
      return TCL_ERROR;
    }
    return TCL_OK;
  }
  
  /* Set a single coord or add coords at index in contour. */
  if (ZnParseCoordList(wi, args[argc-1], &points,
                       &controls, &num_points, NULL) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (argc == 6) {
    num_points = 1;
    cmd = ZN_COORDS_REPLACE;
  }
  if (item->class->Coords(item, contour, index, cmd,
                          &points, &controls, &num_points) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (controls) {
    ZnFree(controls);
  }
  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * WidgetObjCmd --
 *
 *      This procedure is invoked to process the Tcl command
 *      that corresponds to a widget managed by this module.
 *      See the user documentation for details on what it does.
 *
 * Results:
 *      A standard Tcl result.
 *
 * Side effects:
 *      See the user documentation.
 *
 *----------------------------------------------------------------------
 */
static int
WidgetObjCmd(ClientData         client_data,    /* Information about the widget. */
             Tcl_Interp         *interp,        /* Current interpreter. */
             int                argc,           /* Number of arguments. */
             Tcl_Obj *CONST     args[])         /* Arguments. */
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  int           length, result, cmd_index, index;
  ZnItem        item, item2;
  int           field = ZN_NO_PART;
  unsigned int  num = 0, i, j;
  char          *end, *str;
  ZnTransfo     *t = NULL;
  Tcl_Obj       *l;
  ZnTagSearch   *search_var = NULL;
  Tcl_HashEntry *entry;
  ZnPoint       *points;
  ZnPoint       p;
  unsigned int  num_points;
  ZnList        to_points;
  Tcl_Obj       *entries[3];
  char          c[] = "c";
  double        d;

#ifdef PTK_800
  static char *sub_cmd_strings[] =
#else
  static CONST char *sub_cmd_strings[] =
#endif
  {
    "add", "addtag", "anchorxy", "bbox", "becomes", "bind",
    "cget", "chggroup", "clone", "configure", "contour",
    "coords", "currentpart", "cursor", "dchars",
    "dtag", "find", "fit", "focus", "gdelete",
    "gettags", "gname", "group", "hasanchors", "hasfields",
    "hastag", "index", "insert", "itemcget", "itemconfigure",
    "layout", "lower", "monitor", "numparts", "postscript",
    "raise", "remove", "rotate", "scale", "select", "skew",
    "smooth", "tapply", "tcompose", "tdelete", "tget",
    "transform", "translate", "treset", "trestore", "tsave",
    "tset", "type", "vertexat", "xview", "yview", NULL
  };
  enum          sub_cmds {
    ZN_W_ADD, ZN_W_ADDTAG, ZN_W_ANCHORXY, ZN_W_BBOX, ZN_W_BECOMES, ZN_W_BIND,
    ZN_W_CGET, ZN_W_CHGGROUP, ZN_W_CLONE, ZN_W_CONFIGURE,
    ZN_W_CONTOUR, ZN_W_COORDS, ZN_W_CURRENTPART, ZN_W_CURSOR, ZN_W_DCHARS,
    ZN_W_DTAG, ZN_W_FIND, ZN_W_FIT, ZN_W_FOCUS, ZN_W_GDELETE,
    ZN_W_GETTAGS, ZN_W_GNAME, ZN_W_GROUP, ZN_W_HASANCHORS, ZN_W_HASFIELDS,
    ZN_W_HASTAG, ZN_W_INDEX, ZN_W_INSERT, ZN_W_ITEMCGET, ZN_W_ITEMCONFIGURE,
    ZN_W_LAYOUT, ZN_W_LOWER, ZN_W_MONITOR, ZN_W_NUMPARTS, ZN_W_POSTSCRIPT,
    ZN_W_RAISE, ZN_W_REMOVE, ZN_W_ROTATE, ZN_W_SCALE, ZN_W_SELECT, ZN_W_SKEW,
    ZN_W_SMOOTH, ZN_W_TAPPLY, ZN_W_TCOMPOSE, ZN_W_TDELETE, ZN_W_TGET,
    ZN_W_TRANSFORM, ZN_W_TRANSLATE, ZN_W_TRESET, ZN_W_TRESTORE, ZN_W_TSAVE,
    ZN_W_TSET, ZN_W_TYPE, ZN_W_VERTEX_AT, ZN_W_XVIEW, ZN_W_YVIEW
  };
#ifdef PTK_800
  static char *sel_cmd_strings[] =
#else
  static CONST char *sel_cmd_strings[] =
#endif
  {
    "adjust", "clear", "from", "item", "to", NULL
  };
  enum          sel_cmds {
    ZN_SEL_ADJUST, ZN_SEL_CLEAR, ZN_SEL_FROM, ZN_SEL_ITEM, ZN_SEL_TO
  };

  
  if (argc < 2) {
    Tcl_WrongNumArgs(interp, 1, args, "subcommand ?args?");
    return TCL_ERROR;
  }

  Tcl_Preserve((ClientData) wi);
  
  if (Tcl_GetIndexFromObj(interp, args[1], sub_cmd_strings,
                          "subcommand", 0, &cmd_index) != TCL_OK) {
    goto error;
  }
  result = TCL_OK;

  /*printf("executing command \"%s\", argc=%d\n",
    Tcl_GetString(args[1]), argc);*/
  switch((enum sub_cmds) cmd_index) {
    /*
     * add
     */
  case ZN_W_ADD:
    {
      ZnItem      group;
      ZnItemClass cls;
      
      if (argc == 2) { /* create subcommand alone, return the list of known
                        * object types. */
        ZnItemClass     *classes = ZnListArray(ZnItemClassList());
        
        num = ZnListSize(ZnItemClassList());
        l = Tcl_GetObjResult(interp);
        for (i = 0; i < num; i++) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(classes[i]->name, -1));
        }
        goto done;
      }
      if ((argc < 4)) {
      add_err:
        Tcl_WrongNumArgs(interp, 1, args, "add type group ?args?");
        goto error;
      }
      str = Tcl_GetString(args[2]);
      if (str[0] == '-') {
        goto add_err;
      }
      cls = ZnLookupItemClass(str);
      if (!cls) {
        Tcl_AppendResult(interp, "unknown item type \"", str, "\"", NULL);
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[3], &group, &search_var);
      if ((result == TCL_ERROR) || (group == ZN_NO_ITEM) ||
          (group->class != ZnGroup)) {
        Tcl_AppendResult(interp, ", group item expected, got \"",
                         Tcl_GetString(args[3]), "\"", NULL);
        goto error;
      }
      
      argc -= 4;
      args += 4;
      item = ZnCreateItem(wi, cls, &argc, &args);
      if (item == ZN_NO_ITEM) {
        goto error;
      }
      ZnITEM.InsertItem(item, group, ZN_NO_ITEM, True);
      if (ZnITEM.ConfigureItem(item, ZN_NO_PART, argc, args, True) == TCL_ERROR) {
        goto error;
      }
      wi->hot_item = item;
      wi->hot_prev = item->previous;
      l = Tcl_NewLongObj(item->id);
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * addtag
     */
  case ZN_W_ADDTAG:
    {
      if (argc < 4) {
        Tcl_WrongNumArgs(interp, 1, args, "addtag tag searchCommand ?arg arg ...?");
        goto error;
      }
      result = FindItems(wi, argc, args, args[2], 3, &search_var);
    }
    break;
    /*
     * anchorxy
     */
  case ZN_W_ANCHORXY:
    {
      Tk_Anchor anchor;
      
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "anchorxy tagOrId anchor");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM) ||
          ISCLEAR(item->class->flags, ZN_CLASS_HAS_ANCHORS)) {
        Tcl_AppendResult(interp, "unknown item or doesn't support anchors \"",
                         Tcl_GetString(args[2]), NULL);
        goto error;
      }
      if (Tk_GetAnchor(interp, Tcl_GetString(args[3]), &anchor)) {
        goto error;
      }
      /*
       * If something has changed in the geometry we need to
       * update or the anchor location will be erroneous.
       */
      Update(wi);
      item->class->GetAnchor(item, anchor, &p);
      l = Tcl_GetObjResult(wi->interp);
      Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewDoubleObj(p.x));
      Tcl_ListObjAppendElement(wi->interp, l, Tcl_NewDoubleObj(p.y));
    }
    break;
    /*
     * becomes
     */
  case ZN_W_BECOMES:
    {
      Tcl_AppendResult(interp, "Command not yet implemented", NULL);
      goto error;
    }
    break;
    /*
     * bbox
     */
  case ZN_W_BBOX:
    {
      ZnBBox    bbox;
      ZnDim     width, height;
      ZnFieldSet fs;

      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "bbox ?-field fieldNo? ?-label? tagOrId ?tagOrId ...?");
        goto error;
      }
      argc -= 2;
      args += 2;
      
      Update(wi);
      ZnResetBBox(&bbox);

      str = Tcl_GetString(args[0]);
      if (*str == '-') {
        if ((strcmp(str, "-field") == 0) && (argc > 2)) {
          if (Tcl_GetIntFromObj(wi->interp, args[1], &field) == TCL_ERROR) {
            goto error;
          }
          argc -= 2;
          args += 2;
        }
        else if ((strcmp(str, "-label") == 0) && (argc > 1)) {
          field = -1;
          argc--;
          args++;
        }
        else {
          Tcl_AppendResult(interp, "bbox option should be -field numField or -label",
                           NULL);
          goto error;
        }
        result = ZnItemWithTagOrId(wi, args[0], &item, &search_var);
        if ((result == TCL_ERROR) || (item == ZN_NO_ITEM) ||
            ! item->class->GetFieldSet) {
          Tcl_AppendResult(interp, "unknown item or doesn't support fields \"",
                           Tcl_GetString(args[0]), "\"", NULL);
          goto error;
        }
        fs = item->class->GetFieldSet(item);
        if (field >= 0) {
          if ((unsigned int) field >= fs->num_fields) {
            Tcl_AppendResult(interp, "field index is out of bounds", NULL);
            goto error;   
          }
          ZnFIELD.GetFieldBBox(fs, field, &bbox);
        }
        else {
          ZnFIELD.GetLabelBBox(fs, &width, &height);
          if (width && height) {
            p.x = ZnNearestInt(fs->label_pos.x);
            p.y = ZnNearestInt(fs->label_pos.y);
            ZnAddPointToBBox(&bbox, p.x, p.y);
            p.x += width;
            p.y += height;
            ZnAddPointToBBox(&bbox, p.x, p.y);
          }
        }       
      }
      else {
        for (i = 0; i < (unsigned int) argc; i++) {
          /*
           * Check for options in wrong place amidst tags.
           */
          str = Tcl_GetString(args[i]);
          if (*str == '-') {
            Tcl_AppendResult(interp, "bbox options should be specified before any tag", NULL);
            goto error;
          }
          if (ZnTagSearchScan(wi, args[i], &search_var) == TCL_ERROR) {
            goto error;
          }     
          for (item = ZnTagSearchFirst(search_var);
               item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
            ZnAddBBoxToBBox(&bbox, &item->item_bounding_box);
          }
        }
      }

      if (!ZnIsEmptyBBox(&bbox)) {
        l = Tcl_GetObjResult(interp);
        Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(bbox.orig.x));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(bbox.orig.y));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(bbox.corner.x));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(bbox.corner.y));
      }
    }
    break;
    /*
     * bind
     */
  case ZN_W_BIND:
    {
      ClientData        elem = 0;
      int               part = ZN_NO_PART;
      
      if ((argc < 3) || (argc > 6)) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "bind tagOrId ?part? ?sequence? ?command?");
        goto error;
      }
      /*
       * Test if (a) an itemid or (b) an itemid:part or
       * (c) an item part or (d) a tag is provided.
       */
      str = Tcl_GetString(args[2]);

      argc -= 3;
      args += 3;

      if (isdigit(str[0])) {
        int     id;
        
        id = strtoul(str, &end, 0);
        if ((*end != 0) && (*end != ':')) {
          goto bind_a_tag;
        }
        entry = Tcl_FindHashEntry(wi->id_table, (char *) id);
        if (entry == NULL) {
          Tcl_AppendResult(interp, "item \"", str, "\" doesn't exist", NULL);
          goto error;
        }
        item = elem = Tcl_GetHashValue(entry);
        if (!elem) {
          goto error;
        }

        if (*end == ':') {
          /*
           * The part is provided with the id (old method).
           */
          end++;
        part_encode:
          if (item->class->Part) {
            l = Tcl_NewStringObj(end, -1);
            if (item->class->Part(item, &l, &part) == TCL_ERROR) {
              goto error;
            }
            elem = EncodeItemPart(item, part);
          }
          else {
            Tcl_AppendResult(interp, "item \"", str, "\" doesn't have parts", NULL);
            goto error;
          }
        }
        else {
          /*
           * Check if a part is given in the next parameter
           * (alternative method for providing a part).
           */
          if (argc > 3) {
            str = Tcl_GetString(args[0]);
            if (str[0] != '<') {
              end = str;
              argc--;
              args++;
              goto part_encode;
            }
          }
        }
        /*printf("adding element 0x%X to the binding table of item 0x%X\n", elem, item);*/
      }
      else {
      bind_a_tag:
        elem = (ClientData) Tk_GetUid(str);
      }
      
      /*
       * Make a binding table if the widget doesn't already have one.
       */ 
      if (wi->binding_table == NULL) {
        wi->binding_table = Tk_CreateBindingTable(interp);
      }
      
      if (argc == 2) {
        int         append = 0;
        unsigned long mask;

        str = Tcl_GetString(args[1]);
        if (str[0] == 0) {
          result = Tk_DeleteBinding(interp, wi->binding_table, elem,
                                    Tcl_GetString(args[0]));
          goto done;
        }
#ifdef PTK
        mask = Tk_CreateBinding(interp, wi->binding_table,
                                elem, Tcl_GetString(args[0]), args[1], append);
#else
        if (str[0] == '+') {
          str++;
          append = 1;
        }
        mask = Tk_CreateBinding(interp, wi->binding_table,
                                elem, Tcl_GetString(args[0]), str, append);
#endif
        if (mask == 0) {
          goto error;
        }
        if (mask & (unsigned) ~(ButtonMotionMask | Button1MotionMask |
                                Button2MotionMask | Button3MotionMask |
                                Button4MotionMask | Button5MotionMask | 
                                ButtonPressMask | ButtonReleaseMask |
                                EnterWindowMask | LeaveWindowMask |
                                KeyPressMask | KeyReleaseMask |
                                PointerMotionMask | VirtualEventMask)) {
          Tk_DeleteBinding(interp, wi->binding_table, elem, Tcl_GetString(args[3]));
          Tcl_ResetResult(interp);
          Tcl_AppendResult(interp, "requested illegal events; ",
                           "only key, button, motion, enter, leave ",
                           "and virtual events may be used", NULL);
          goto error;
        }
      }
      else if (argc == 1) {
#ifdef PTK
        Tcl_Obj *command;
        command = Tk_GetBinding(interp, wi->binding_table, elem,
                                Tcl_GetString(args[0]));
        if (command == NULL) {
          char *string = Tcl_GetString(Tcl_GetObjResult(interp));
          /*
           * Ignore missing binding errors.  This is a special hack
           * that relies on the error message returned by FindSequence
           * in tkBind.c.
           */
          if (string[0] != '\0') {
            goto error;
          }
          else {
            Tcl_ResetResult(interp);
          }
        }
        else {
          Tcl_SetObjResult(interp, command);
        }
#else
        CONST char *command;
        command = Tk_GetBinding(interp, wi->binding_table, elem,
                                Tcl_GetString(args[0]));
        if (command == NULL) {
          goto error;
        }
        Tcl_SetObjResult(interp, Tcl_NewStringObj(command, -1));
#endif
      }
      else {
        Tk_GetAllBindings(interp, wi->binding_table, elem);
      }
    }
    break;
    /*
     * cget
     */
  case ZN_W_CGET:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "cget option");
        goto error;
      }
#ifdef PTK_800
      result = Tk_ConfigureValue(interp, wi->win, config_specs,
                                 (char *) wi, Tcl_GetString(args[2]), 0);
#else
      l = Tk_GetOptionValue(interp, (char *) wi, wi->opt_table, args[2], wi->win);
      if (l == NULL) {
        goto error;
      }
      Tcl_SetObjResult(interp, l);
#endif
    }
    break;
    /*
     * chggroup
     */
  case ZN_W_CHGGROUP:
    {
      ZnItem    grp, scan;
      int       adjust=0;
      ZnTransfo inv, t, t2, *this_one=NULL;
      
      if ((argc != 4) && (argc != 5)) {
        Tcl_WrongNumArgs(interp, 1, args, "chggroup tagOrIg group ?adjustTransform?");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[3], &grp, &search_var);
      if ((result == TCL_ERROR) || (grp == ZN_NO_ITEM)|| (grp->class != ZnGroup)) {
        goto error;
      }
      if (item->parent == grp) {
        /*
         * Nothing to be done, the item is already in the
         * target group.
         */
        goto done;
      }
      /*
       * Check the ancestors to find if item is an
       * ancestor of grp, which would lead to a
       * forbidden move.
       */
      for (scan = grp; scan && (scan != item); scan = scan->parent);
      if (scan == item) {
        Tcl_AppendResult(interp, "\"", Tcl_GetString(args[3]),
                         "\" is a descendant of \"", Tcl_GetString(args[2]),
                         "\" and can't be used as its parent", NULL);
        goto error;
      }
      if (argc == 5) {
        if (Tcl_GetBooleanFromObj(interp, args[4], &adjust) != TCL_OK) {
          goto error;
        }
      }
      if ((item->parent == grp) || (item->parent == ZN_NO_ITEM)) {
        goto done;
      }
      if (adjust) {
        ZnITEM.GetItemTransform(grp, &t);
        ZnTransfoInvert(&t, &inv);
        ZnITEM.GetItemTransform(item->parent, &t);
        ZnTransfoCompose(&t2, &t, &inv);
        this_one = &t2;
        if (item->transfo) {
          ZnTransfoCompose(&t, item->transfo, &t2);
          this_one = &t;
        }
      }
      ZnITEM.ExtractItem(item);
      ZnITEM.InsertItem(item, grp, ZN_NO_ITEM, True);
      /*
       * The item can be a group in which case we must
       * use the ZN_TRANSFO_FLAG to force an update of
       * the children. In all other case ZN_COORDS_FLAG
       * is enough.
       */
      ZnITEM.Invalidate(item,
                      item->class==ZnGroup?ZN_TRANSFO_FLAG:ZN_COORDS_FLAG);
      if (adjust) {
        ZnITEM.SetTransfo(item, this_one);
      }
    }
    break;
    /*
     * clone
     */
  case ZN_W_CLONE:
    {
      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "clone tagOrId ?option value ...?");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) ||
          (item == ZN_NO_ITEM) || (item == wi->top_group)) {
        goto error;
      }
      argc -= 3;
      args += 3;
      item2 = ZnITEM.CloneItem(item);
      ZnITEM.InsertItem(item2, item->parent, ZN_NO_ITEM, True);
      if (ZnITEM.ConfigureItem(item2, ZN_NO_PART, argc, args, False) == TCL_ERROR) {
        goto error;
      }
      l = Tcl_NewLongObj(item2->id);
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * configure
     */
  case ZN_W_CONFIGURE:
    {
#ifdef PTK_800
      if (argc == 2) {
        result = Tk_ConfigureInfo(interp, wi->win, config_specs,
                                  (char *) wi, (char *) NULL, 0);
      }
      else if (argc == 3) {
        result = Tk_ConfigureInfo(interp, wi->win, config_specs,
                                  (char *) wi, Tcl_GetString(args[2]), 0);
      }
      else {
        result = Configure(interp, wi, argc-2, args+2, TK_CONFIG_ARGV_ONLY);
      }
#else
      if (argc == 2) {
        l = Tk_GetOptionInfo(interp, (char *) wi, wi->opt_table,
                             (argc == 3) ? args[2] : NULL, wi->win);
        if (l == NULL) {
          goto error;
        }
        else {
          Tcl_SetObjResult(interp, l);
        }
      }
      else {
        result = Configure(interp, wi, argc-2, args+2);
      }
#endif
    }
    break;
    /*
     * contour
     */
  case ZN_W_CONTOUR:
    {
      if ((argc < 3) || (argc > 7)) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "contour tagOrId ?operator windingFlag? ?index? ?coordListOrTagOrId?");
        goto error;
      }
      if (Contour(wi, argc, args, &search_var) == TCL_ERROR) {
        goto error;
      }
      break;
    }
    /*
     * coords
     */
  case ZN_W_COORDS:
    {
      if ((argc < 3) || (argc > 7)) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "coords tagOrId ?add/remove? ?contour? ?index? ?coordList?");
        goto error;
      }
      if (Coords(wi, argc, args, &search_var) == TCL_ERROR) {
        goto error;
      }
    }
    break;
    /*
     * currentpart
     */
  case ZN_W_CURRENTPART:
    {
      ZnBool    only_fields = False;
      if ((argc != 2) && (argc != 3)) {
        Tcl_WrongNumArgs(interp, 1, args, "currentpart ?onlyFields?");
        goto error;
      }
      if (argc == 3) {
        if (Tcl_GetBooleanFromObj(interp, args[2], &only_fields) != TCL_OK) {
          goto error;
        }
      }
      if ((wi->current_item != ZN_NO_ITEM) &&
          (wi->current_item->class->Part != NULL) &&
          ((wi->current_part >= 0) || !only_fields)) {
        l = NULL;
        wi->current_item->class->Part(wi->current_item, &l, &wi->current_part);
        Tcl_SetObjResult(interp, l);
      }
    }
    break;
    /*
     * cursor
     */
  case ZN_W_CURSOR:
    {
      if ((argc != 4) && (argc != 5)) {
        Tcl_WrongNumArgs(interp, 1, args, "cursor tagOrId ?field? index");
        goto error;
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      if (argc == 5) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) { 
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
        argc--;
        args++;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if ((item->class->Cursor == NULL) ||
            (item->class->Index == NULL)) {
          continue;
        }
        result = (*item->class->Index)(item, field, args[3], &index);
        if (result != TCL_OK) {
          goto error;
        }
        
        (*item->class->Cursor)(item, field, index);
        if ((item == wi->focus_item) && (field == wi->focus_field) &&
            wi->text_info.cursor_on) {
          ZnITEM.Invalidate(item, ZN_DRAW_FLAG);
        }
      }
    }
    break;
    /*
     * dchars
     */
  case ZN_W_DCHARS:
    {
      int        first, last;
      ZnTextInfo *ti = &wi->text_info;

      if ((argc < 4) || (argc > 6)) {
        Tcl_WrongNumArgs(interp, 1, args, "dchars tagOrId ?field? first ?last?");
        goto error;
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      if (argc == 6) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) { 
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
        argc--;
        args++;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if ((item->class->Index == NULL) ||
            (item->class->DeleteChars == NULL)) {
          continue;
        }
        result = (*item->class->Index)(item, field, args[3], &first);
        if (result != TCL_OK) {
          goto error;
        }
        if (argc == 5) {
          result = (*item->class->Index)(item, field, args[4], &last);
          if (result != TCL_OK) {
            goto error;
          }
        }
        else {
          last = first;
        }
        (*item->class->DeleteChars)(item, field, &first, &last);

        /*
         * Update indexes for the selection to reflect the
         * change.
         */
        if ((ti->sel_item == item) && (ti->sel_field == field)) {
          int count = last + 1 - first;
          if (ti->sel_first > first) {
            ti->sel_first -= count;
            if (ti->sel_first < first) {
              ti->sel_first = first;
            }
          }
          if (ti->sel_last >= first) {
            ti->sel_last -= count;
            if (ti->sel_last < (first-1)) {
              ti->sel_last = first-1;
            }
          }
          if (ti->sel_first >= ti->sel_last) {
            ti->sel_item = ZN_NO_ITEM;
            ti->sel_field = ZN_NO_PART;
          }
          if ((ti->anchor_item == item) && (ti->anchor_field == field) &&
              (ti->sel_anchor > first)) {
            ti->sel_anchor -= count;
            if (ti->sel_anchor < first) {
              ti->sel_anchor = first;
            }
          }
        }
      }
    }
    break;
    /*
     * dtag
     */
  case ZN_W_DTAG:
    {
      Tk_Uid            tag;
      
      if ((argc != 3) && (argc != 4)) {
        Tcl_WrongNumArgs(interp, 1, args, "dtag tagOrId ?tagToDelete?");
        goto error;
      }
      if (argc == 4) {
        tag = Tk_GetUid(Tcl_GetString(args[3]));
      }
      else {
        tag = Tk_GetUid(Tcl_GetString(args[2]));
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        ZnITEM.RemoveTag(item, (char *) tag);
      }
    }
    break;
    /*
     * find
     */
  case ZN_W_FIND:
    {
      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "find searchCommand ?arg arg ...?");
        goto error;
      }
      result = FindItems(wi, argc, args, NULL, 2, &search_var);
    }
    break;
    /*
     * fit
     */
  case ZN_W_FIT:
    {
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "fit coordList error");
        goto error;
      }
      if (ZnParseCoordList(wi, args[2], &points,
                           NULL, &num_points, NULL) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &d) == TCL_ERROR) {
        goto error;
      }
      to_points = ZnListNew(32, sizeof(ZnPoint));
      ZnFitBezier(points, num_points, d, to_points);
      points = (ZnPoint *) ZnListArray(to_points);
      num_points = ZnListSize(to_points);
      l = Tcl_GetObjResult(interp);
      for (i = 0; i < num_points; i++, points++) {
        entries[0] = Tcl_NewDoubleObj(points->x);
        entries[1] = Tcl_NewDoubleObj(points->y);
        if (i % 3) {
          entries[2] = Tcl_NewStringObj(c, -1);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewListObj(3, entries));
        }
        else {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewListObj(2, entries));
        }
      } 
      ZnListFree(to_points);
    }
    break;
    /*
     * focus
     */
  case ZN_W_FOCUS:
    {
      if (argc > 4) {
        Tcl_WrongNumArgs(interp, 1, args, "focus ?tagOrId? ?field?");
        goto error;
      }
      item = wi->focus_item;
      if (argc == 2) {
        field = wi->focus_field;
        if (item != ZN_NO_ITEM) {
          l = Tcl_GetObjResult(interp);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewLongObj(item->id));
          if (field != ZN_NO_PART) {
            Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(field));
          }
          else {
            Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj("", -1));
          }
        }
        break;
      }
      if ((item != ZN_NO_ITEM) && (item->class->Cursor != NULL) &&
          ISSET(wi->flags, ZN_GOT_FOCUS)) {
        ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
      }
      if (Tcl_GetString(args[2])[0] == 0) {
        wi->focus_item = ZN_NO_ITEM;
        wi->focus_field = ZN_NO_PART;
        break;
      }
      if (ZnItemWithTagOrId(wi, args[2], &item, &search_var) == TCL_ERROR) {
        goto error;
      }
      if (argc == 4) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) { 
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
      }
      wi->focus_item = item;
      wi->focus_field = field;
      if (ISSET(wi->flags, ZN_GOT_FOCUS) && (item->class->Cursor != NULL)) {
        ZnITEM.Invalidate(wi->focus_item, ZN_COORDS_FLAG);
      }
    }
    break;
    /*
     * gdelete
     */
  case ZN_W_GDELETE:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "gdelete gName");
        goto error;
      }
      ZnDeleteGradientName(Tcl_GetString(args[2]));
    }    
    break;
    /*
     * gettags
     */
  case ZN_W_GETTAGS:
    {
      Tk_Uid    *tags;
      
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "gettags tagOrId");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      if (!item->tags || !ZnListSize(item->tags)) {
        goto done;
      }
      else {
        num = ZnListSize(item->tags);
        tags = (Tk_Uid *) ZnListArray(item->tags);
        l = Tcl_GetObjResult(interp);
        for (i = 0; i < num; i++) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(tags[i], -1));
        }
      }
    }
    break;
    /*
     * gname
     */
  case ZN_W_GNAME:
    {
      ZnBool    ok;
      
      if ((argc != 3) && (argc != 4)) {
        Tcl_WrongNumArgs(interp, 1, args, "gname ?grad? gName");
        goto error;
      }
      if (argc == 3) {
        l = Tcl_NewBooleanObj(ZnGradientNameExists(Tcl_GetString(args[2])));
        Tcl_SetObjResult(interp, l);
      }
      else {
        ok = ZnNameGradient(interp, wi->win, Tcl_GetString(args[2]),
                            Tcl_GetString(args[3]));
        if (!ok) {
          goto error;
        }
      }
    }
    break;
    /*
     * group
     */
  case ZN_W_GROUP:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "group tagOrId");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      if (item->parent != ZN_NO_ITEM) {
        l = Tcl_NewLongObj(item->parent->id);
        Tcl_SetObjResult(interp, l);
      }
      else {
        /*
         * Top group is its own parent.
         */
        l = Tcl_NewLongObj(item->id);
        Tcl_SetObjResult(interp, l);
      }
    }
    break;
    /*
     * hasanchors
     */
  case ZN_W_HASANCHORS:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "hasanchors tagOrId");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      l = Tcl_NewBooleanObj(ISSET(item->class->flags, ZN_CLASS_HAS_ANCHORS) ? 1 : 0);
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * hasfields
     */
  case ZN_W_HASFIELDS:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "hasfields tagOrId");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      l =  Tcl_NewBooleanObj(item->class->GetFieldSet?1:0);
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * hastag
     */
  case ZN_W_HASTAG:
    {
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "hastag tagOrId tag");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      l = Tcl_NewBooleanObj(ZnITEM.HasTag(item,
                                          Tk_GetUid(Tcl_GetString(args[3]))));
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * index
     */
  case ZN_W_INDEX:
    {
      if ((argc != 4) && (argc != 5)) {
        Tcl_WrongNumArgs(interp, 1, args, "index tagOrId ?field? string");
        goto error;
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      if (argc == 5) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) {
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
        argc--;
        args++;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if (item->class->Index != NULL) {
          result = (*item->class->Index)(item, field, args[3], &index);
          if (result != TCL_OK) {
            goto error;
          }
          l = Tcl_NewIntObj(index);
          Tcl_SetObjResult(interp, l);
          goto done;
        }
      }
      Tcl_AppendResult(interp, "can't find an indexable item \"",
                       Tcl_GetString(args[2]), "\"", NULL);
      goto error;
    }
    break;
    /*
     * insert
     */
  case ZN_W_INSERT:
    {
      ZnTextInfo *ti = &wi->text_info;
      char       *chars;

      if ((argc != 5) && (argc != 6)) {
        Tcl_WrongNumArgs(interp, 1, args, "insert tagOrId ?field? before string");
        goto error;
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      if (argc == 6) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) { 
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
        argc--;
        args++;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if ((item->class->Index == NULL) ||
            (item->class->InsertChars == NULL)) {
          continue;
        }
        result = (*item->class->Index)(item, field, args[3], &index);
        if (result != TCL_OK) {
          goto error;
        }
        chars = Tcl_GetString(args[4]);
        (*item->class->InsertChars)(item, field, &index, chars);
        /*
         * Inserting characters invalidates selection indices.
         */
        if ((ti->sel_item == item) && (ti->sel_field == field)) {
          length = strlen(chars);
          if (ti->sel_first >= index) {
            ti->sel_first += length;
          }
          if (ti->sel_last >= index) {
            ti->sel_last += length;
          }
          if ((ti->anchor_item == item) && (ti->anchor_field == field) &&
              (ti->sel_anchor >= index)) {
            ti->sel_anchor += length;
          }
        }
      }
    }
    break;
    /*
     * itemcget
     */
  case ZN_W_ITEMCGET:
    {
      if (argc < 4) {
      itemcget_syntax:
        Tcl_WrongNumArgs(interp, 1, args, "itemcget tagOrId ?field? option");
        goto error;
      }    
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      if (argc == 5) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) {
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
        argc--;
        args++;
      }
      if (argc != 4) {
        goto itemcget_syntax;     
      }
      if (ZnITEM.QueryItem(item, field, 1, &args[3]) != TCL_OK) {
        goto error;
      }
    }
    break;
    /*
     * itemconfigure
     */
  case ZN_W_ITEMCONFIGURE:
    {
      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "itemconfigure tagOrId ?field? option value ?option value? ...");
        goto error;
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      if ((argc > 3) && (Tcl_GetString(args[3])[0] != '-')) {
        if (Tcl_GetIntFromObj(interp, args[3], &field) != TCL_OK) {
          field = ZN_NO_PART;
          if (Tcl_GetString(args[3])[0] != 0) { 
            Tcl_AppendResult(interp, "invalid field index \"",
                             Tcl_GetString(args[3]),
                             "\", should be a positive integer", NULL);
            goto error;
          }
        }
        argc--;
        args++;
      }
      argc -= 3;
      args += 3;
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if (argc < 2) {
          if (field == ZN_NO_PART) {
            result = ZnAttributesInfo(wi->interp, item, item->class->attr_desc, argc, args);
          }
          else if (item->class->GetFieldSet) {
            ZnFieldSet fs = item->class->GetFieldSet(item);
            if (field < (int) ZnFIELD.NumFields(fs)) {
              result = ZnAttributesInfo(wi->interp, ZnFIELD.GetFieldStruct(fs, field),
                                        ZnFIELD.attr_desc, argc, args);
            }
            else {
              Tcl_AppendResult(interp, "field index out of bound", NULL);
              goto error;
            }
          }
          else {
            Tcl_AppendResult(interp, "the item does not support fields", NULL);
            goto error;
          }
          goto done;
        }
        else {
          result = ZnITEM.ConfigureItem(item, field, argc, args, False);
        }
        if (result == TCL_ERROR) {
          goto error;
        }
      }
    }
    break;
    /*
     * layout
     */
  case ZN_W_LAYOUT:
    {
      if (argc < 4) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "layout operator ?args...? tagOrId ?tagOrId...?");
        goto error;
      }
      if (LayoutItems(wi, argc-2, args+2) == TCL_ERROR) {
        goto error;
      }
    }
    break;
    /*
     * lower
     */
  case ZN_W_LOWER:
    {
      ZnItem      first, group, mark = ZN_NO_ITEM;
      
      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "lower tagOrId ?belowThis?");
        goto error;
      }
      if (argc == 4) {
        if (ZnTagSearchScan(wi, args[3], &search_var) == TCL_ERROR) {
          goto error;
        }
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          mark = item;
        }
        if (mark == ZN_NO_ITEM) {
          Tcl_AppendResult(interp, "unknown tag or item \"",
                           Tcl_GetString(args[3]), "\"", NULL);
          goto error;
        }
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      item = ZnTagSearchFirst(search_var);
      if ((item == ZN_NO_ITEM) || (item == wi->top_group)) {
        goto done;
      }
      first = item;
      if (mark == ZN_NO_ITEM) {
        mark = ZnGroupTail(item->parent);
      }
      group = mark->parent;
      do {
        if ((item->parent == group) && (item != mark)) {
          ZnITEM.UpdateItemPriority(item, mark, False);
          mark = item;
        }
        item = ZnTagSearchNext(search_var);
      }
      while ((item != ZN_NO_ITEM) && (item != first));
    }
    break;
    /*
     * monitor
     */
  case ZN_W_MONITOR:
    {
#ifndef _WIN32
      ZnBool  on_off;
      
      if ((argc != 2) && (argc != 3)) {
        Tcl_WrongNumArgs(interp, 1, args, "monitor ?onOff?");
        goto error;
      }
      if (argc == 3) {
        if (Tcl_GetBooleanFromObj(interp, args[2], &on_off) != TCL_OK) {
          goto error;
        }
        ASSIGN(wi->flags, ZN_MONITORING, on_off);
        if (on_off == True) {
          ZnResetChronos(wi->total_draw_chrono);
          ZnResetChronos(wi->this_draw_chrono);
        }
      }
      if ((argc == 2) || (on_off == False)) {
        long ttime, ltime;
        int  num_actions;
        ZnGetChrono(wi->total_draw_chrono, &ttime, &num_actions);
        ZnGetChrono(wi->this_draw_chrono, &ltime, NULL);
        l = Tcl_GetObjResult(interp);
        Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(num_actions));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(ltime));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(ttime));
        /*Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(wi->damaged_area_w));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(wi->damaged_area_h));
        Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(ttime));*/
      }
#endif
    }
    break;
    /*
     * numparts
     */
  case ZN_W_NUMPARTS:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "numparts tagOrId");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
        goto error;
      }
      l = Tcl_NewIntObj((int) item->class->num_parts);
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * postscript
     */
  case ZN_W_POSTSCRIPT:
    {
      if (ZnPostScriptCmd(wi, argc, args) != TCL_OK) {
        goto error;
      }
    }
    break;
    /*
     * raise
     */
  case ZN_W_RAISE:
    {
      ZnItem      group, mark = ZN_NO_ITEM;
      
      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "raise tagOrId ?aboveThis?");
        goto error;
      }
      if (argc == 4) {
        /*
         * Find the topmost item with the tag.
         */
        if (ZnTagSearchScan(wi, args[3], &search_var) == TCL_ERROR) {
          goto error;
        }
        mark = ZnTagSearchFirst(search_var);
        if (mark == ZN_NO_ITEM) {
          Tcl_AppendResult(interp, "unknown tag or item \"",
                           Tcl_GetString(args[3]), "\"", NULL);
          goto error;
        }
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      item = ZnTagSearchFirst(search_var);
      if ((item == ZN_NO_ITEM) || (item == wi->top_group)) {
        goto done;
      }
      if (mark == ZN_NO_ITEM) {
        mark = ZnGroupHead(item->parent);
      }
      group = mark->parent;
      for (; item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if (item->parent != group) {
          continue;
        }
        if (item != mark) {
          ZnITEM.UpdateItemPriority(item, mark, True);
        }
      }
    }
    break;
    /*
     * remove
     */
  case ZN_W_REMOVE:
    {
      unsigned int num_fields;
      
      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "remove tagOrId ?tagOrId ...?");
        goto error;
      }
      argc -= 2;
      args += 2;
      for (i = 0; i < (unsigned int) argc; i++) {
        if (ZnTagSearchScan(wi, args[i], &search_var) == TCL_ERROR) {
          goto error;
        }
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          if (item == wi->top_group) {
            continue;
          }
          if (wi->binding_table != NULL) {
            Tk_DeleteAllBindings(wi->binding_table, (ClientData) item);
            if (item->class->GetFieldSet) {
              num_fields = ZnFIELD.NumFields(item->class->GetFieldSet(item));
              for (j = 0; j < num_fields; j++) {
                Tk_DeleteAllBindings(wi->binding_table,
                                     (ClientData) EncodeItemPart(item, j));
              }
            }
            for (j = 0; j < item->class->num_parts; j++) {
              Tk_DeleteAllBindings(wi->binding_table,
                                   (ClientData) EncodeItemPart(item, -(int)(j+2)));
            }
          }
          ZnITEM.DestroyItem(item);
        }
      }
    }
    break;
    /*
     * rotate
     */
  case ZN_W_ROTATE:
    {
      ZnBool    deg=False;

      if ((argc < 4) && (argc > 7)) {
        Tcl_WrongNumArgs(interp, 1, args, "rotate tagOrIdOrTransform angle ?degree? ?centerX centerY?");
        goto error;
      }
      
      if (argc > 5) {
        if (Tcl_GetDoubleFromObj(interp, args[argc-2], &d) == TCL_ERROR) {
          goto error;
        }
        p.x = d;
        if (Tcl_GetDoubleFromObj(interp, args[argc-1], &d) == TCL_ERROR) {
          goto error;
        }
        p.y = d;
      }
      if ((argc == 5) || (argc == 7)) {
        if (Tcl_GetBooleanFromObj(interp, args[4], &deg) != TCL_OK) {
          goto error;
        }
        
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
          goto error;
        }
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &d) == TCL_ERROR) {
        goto error;
      }

      if (t) {
        if (argc > 5) {
          ZnTranslate(t, -p.x, -p.y, False);
        }
        if (deg) {
          ZnRotateDeg(t, d);
        }
        else {
          ZnRotateRad(t, d);
        }
        if (argc > 5) {
          ZnTranslate(t, p.x, p.y, False);
        }
      }
      else {
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          ZnITEM.RotateItem(item, d, deg, (argc > 5) ? &p : NULL);
        }
      }
    }
    break;
    /*
     * scale
     */
  case ZN_W_SCALE:
    {
      ZnPoint   scale;
      
      if ((argc != 5) && (argc != 7)) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "scale tagOrIdOrTransform xFactor yFactor ?centerX centerY?");
        goto error;
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
          goto error;
        }
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &d) == TCL_ERROR) {
        goto error;
      }
      scale.x = d;
      if (Tcl_GetDoubleFromObj(interp, args[4], &d) == TCL_ERROR) {
        goto error;
      }
      scale.y = d;
      if (argc == 7) {
        if (Tcl_GetDoubleFromObj(interp, args[5], &d) == TCL_ERROR) {
          goto error;
        }
        p.x = d;
        if (Tcl_GetDoubleFromObj(interp, args[6], &d) == TCL_ERROR) {
          goto error;
        }
        p.y = d;
      }

      if (t) {
        if (argc == 7) {
          ZnTranslate(t, -p.x, -p.y, False);
        }
        ZnScale(t, scale.x, scale.y);
        if (argc == 7) {
          ZnTranslate(t, p.x, p.y, False);
        }
      }
      else {
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          ZnITEM.ScaleItem(item, scale.x, scale.y, (argc == 7) ? &p : NULL);
        }
      }
    }
    break;
    /*
     * select
     */
  case ZN_W_SELECT:
    {
      ZnTextInfo *ti = &wi->text_info;

      if (argc < 3) {
        Tcl_WrongNumArgs(interp, 1, args, "select option ?tagOrId? ?arg?");
        goto error;
      }
      if (argc >= 4) {
        if (ZnTagSearchScan(wi, args[3], &search_var) == TCL_ERROR) {
          goto error;
        }
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          if ((item->class->Index != NULL) &&
              (item->class->Selection != NULL)) {
            break;
          }
        }
        if (item == ZN_NO_ITEM) {
          Tcl_AppendResult(interp, "can't find an indexable item \"",
                           Tcl_GetString(args[3]), "\"", NULL);
          goto error;
        }
      }
      if (Tcl_GetIndexFromObj(interp, args[2], sel_cmd_strings,
                              "selection option", 0, &cmd_index) != TCL_OK) {
        goto error;
      }
      if ((argc == 5) || (argc == 6)) {
        if (argc == 6) {
          if (Tcl_GetIntFromObj(interp, args[4], &field) != TCL_OK) {
            field = ZN_NO_PART;
            if (Tcl_GetString(args[4])[0] != 0) {
              Tcl_AppendResult(interp, "invalid field index \"",
                               Tcl_GetString(args[4]),
                               "\", should be a positive integer", NULL);
              goto error;
            }
          }
          argc--;
          args++;
        }
        result = item->class->Index(item, field, args[4], &index);
        if (result != TCL_OK) {
          goto error;
        }
      }
      switch ((enum sel_cmds) cmd_index) {
      case ZN_SEL_ADJUST:
        if (argc != 5) {
          Tcl_WrongNumArgs(interp, 1, args, "select adjust tagOrId ?field? index");
          goto error;
        }
        if ((ti->sel_item == item) && (ti->sel_field == field)) {
          if (index < (ti->sel_first + ti->sel_last)/2) {
            ti->sel_anchor = ti->sel_last+1;
          }
          else {
            ti->sel_anchor = ti->sel_first;
          }
        }
        SelectTo(item, field, index);
        break;
      case ZN_SEL_CLEAR:
        if (argc != 3) {
          Tcl_WrongNumArgs(interp, 1, args, "select clear");
          goto error;
        }
        if (ti->sel_item != ZN_NO_ITEM) {
          ZnITEM.Invalidate(ti->sel_item, ZN_DRAW_FLAG);
          ti->sel_item = ZN_NO_ITEM;
          ti->sel_field = ZN_NO_PART;
        }
        break;
      case ZN_SEL_FROM:
        if (argc != 5) {
          Tcl_WrongNumArgs(interp, 1, args, "select from tagOrId ?field? index");
          goto error;
        }
        ti->anchor_item = item;
        ti->anchor_field = field;
        ti->sel_anchor = index;
        break;
      case ZN_SEL_ITEM:
        if (argc != 3) {
          Tcl_WrongNumArgs(interp, 1, args, "select item");
          goto error;
        }
        if (ti->sel_item != ZN_NO_ITEM) {
          l = Tcl_GetObjResult(interp);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewLongObj(ti->sel_item->id));
          if (ti->sel_field != ZN_NO_PART) {
            Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(ti->sel_field));
          }
          else {
            Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj("", -1));
          }
        }
        break;
      case ZN_SEL_TO:
        if (argc != 5) {
          Tcl_WrongNumArgs(interp, 1, args, "select to tagOrId ?field? index");
          goto error;
        }
        SelectTo(item, field, index);
        break;
      }
    }
    break;
    /*
     * Skew
     */
  case ZN_W_SKEW:
    {
      double   x_skew, y_skew;
      
      if (argc != 5) {
        Tcl_WrongNumArgs(interp, 1, args, "skew tagOrIdOrTransform xSkewAngle ySkewAngle");
        goto error;
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
          goto error;
        }
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &x_skew) == TCL_ERROR) {
        goto error;
      }
      if (Tcl_GetDoubleFromObj(interp, args[4], &y_skew) == TCL_ERROR) {
        goto error;
      }
      
      if (t) {
        ZnSkewRad(t, x_skew, y_skew);
      }
      else {
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          ZnITEM.SkewItem(item, x_skew, y_skew);
        }
      }
    }
    break;
    /*
     * smooth
     */
  case ZN_W_SMOOTH:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "smooth coordList");
        goto error;
      }
      if (ZnParseCoordList(wi, args[2], &points,
                           NULL, &num_points, NULL) == TCL_ERROR) {
        return TCL_ERROR;
      }
      to_points = ZnListNew(32, sizeof(ZnPoint));
      ZnSmoothPathWithBezier(points, num_points, to_points);
      points = (ZnPoint *) ZnListArray(to_points);
      num_points = ZnListSize(to_points);
      l = Tcl_GetObjResult(interp);
      for (i = 0; i < num_points; i++, points++) {
        entries[0] = Tcl_NewDoubleObj(points->x);
        entries[1] = Tcl_NewDoubleObj(points->y);
        Tcl_ListObjAppendElement(interp, l, Tcl_NewListObj(2, entries));
      }
      ZnListFree(to_points);
    }
    break;
    /*
     * tapply
     */
  case ZN_W_TAPPLY:
    {
      Tcl_AppendResult(interp, "Command not yet implemented", NULL);
      goto error;
    }
    break;
    /*
     * tcompose
     */
  case ZN_W_TCOMPOSE:
    {
      ZnTransfo         *to;
      ZnBool            invert=False;
      ZnTransfo         res_t, inv_t;

      if ((argc != 4) && (argc != 5)) {
        Tcl_WrongNumArgs(interp, 1, args, "tcompose transformTo aTransform ?invert?");
        goto error;
      }
      if (argc == 5) {
        if (Tcl_GetBooleanFromObj(interp, args[4], &invert) != TCL_OK) {
          goto error;
        }
        argc--;
      }
      
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        result = ZnItemWithTagOrId(wi, args[3], &item, &search_var);
        if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
          Tcl_ResetResult(interp);
          Tcl_AppendResult(interp, "\"", Tcl_GetString(args[3]),
                           "\" must be either a tag, ",
                           "an id or a transform name", (char *) NULL);
          goto error;
        }
        t = item->transfo;
      }

      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        to = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
        if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
          Tcl_ResetResult(interp);
          Tcl_AppendResult(interp, "\"", Tcl_GetString(args[2]),
                           "\" must be either a tag, ",
                           "an id or a transform name", (char *) NULL);
          goto error;
        }
        to = item->transfo;
      }

      if (invert) {
        ZnTransfoInvert(t, &inv_t);
        ZnTransfoCompose(&res_t, to, &inv_t);
      }
      else {
        ZnTransfoCompose(&res_t, to, t);
      }

      if (item != ZN_NO_ITEM) {
        /* Set back the transform in the item */
        ZnITEM.SetTransfo(item, &res_t);
      }
      else {
        ZnTransfoFree(to);
        Tcl_SetHashValue(entry, ZnTransfoDuplicate(&res_t));
      }

      break;
    }
    /*
     * tdelete
     */
  case ZN_W_TDELETE:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "tdelete tName");
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, Tcl_GetString(args[2]));
      if (entry == NULL) {
        Tcl_AppendResult(interp, "\"", Tcl_GetString(args[2]),
                         "\" must be a transform name", (char *) NULL);
        goto error;
      }
      t = (ZnTransfo *) Tcl_GetHashValue(entry);
      ZnTransfoFree(t);
      Tcl_DeleteHashEntry(entry);
    }
    break;
    /*
     * tget
     */
  case ZN_W_TGET:
    {
      ZnPoint   scale, trans;
      ZnReal    rotation, skewxy;
      ZnBool    raw=1, get_trans=0, get_rot=0;
      ZnBool    get_scale=0, get_skew=0;
      ZnTransfo tid;

      if ((argc != 3) && (argc != 4)) {
      err_tget:
        Tcl_WrongNumArgs(interp, 1, args, "tget transform ?all|translation|scale|rotation|skew?");
        goto error;
      }
      if (argc == 4) {
        raw = 0;
        str = Tcl_GetString(args[3]);
        length = strlen(str);
        if (strncmp(str, "all", length) == 0) {
          get_scale = get_rot = get_trans = get_skew = 1;
        }
        else if (strncmp(str, "translation", length) == 0) {
          get_trans = 1;
        }
        else if (strncmp(str, "scale", length) == 0) {
          get_scale = 1;
        }
        else if (strncmp(str, "rotation", length) == 0) {
          get_rot = 1;
        }
        else if (strncmp(str, "skew", length) == 0) {
          get_skew = 1;
        }
        else {
          goto err_tget;
        }
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
        if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
          Tcl_ResetResult(interp);
          Tcl_AppendResult(interp, "\"", Tcl_GetString(args[3]),
                           "\" must be either a tag, ",
                           "an id or a transform name", (char *) NULL);
          goto error;
        }
        t = item->transfo;
      }
      l = Tcl_GetObjResult(interp);
      if (raw) {
        if (!t) {
          ZnTransfoSetIdentity(&tid);
          t = &tid;
        }
        for (i = 0; i < 6; i++) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(t->_[i/2][i%2]));
        }
      }
      else {
        ZnTransfoDecompose(t, get_scale?&scale:NULL, get_trans?&trans:NULL,
                           get_rot?&rotation:NULL, get_skew?&skewxy:NULL);
        if (get_trans) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(trans.x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(trans.y));
        }
        if (get_scale) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(scale.x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(scale.y));
        }
        if (get_rot) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(rotation));
        }
        if (get_skew) {
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(skewxy));
        }
      }
      break;
    }
    /*
     * transform
     */
  case ZN_W_TRANSFORM:
    {
      char      *controls, *tag;
      ZnPoint   *p, xp;
      ZnTransfo *from_t=NULL, *to_t=NULL, *result_t;
      ZnTransfo t1, t2, t3;
      ZnBool    old_format;

      if ((argc != 4) && (argc != 5)) {
        Tcl_WrongNumArgs(interp, 1, args, "transform ?tagOrIdFrom? tagOrIdTo coordlist");
        goto error;
      }
      
      if (argc == 5) {
        /*
         * Setup the source transform.
         */
        tag = Tcl_GetString(args[2]);
        if (strlen(tag) == 0) {
          Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
          goto error;
        }
        if (strcmp(tag, "device") == 0) {
          from_t = &t1;
          ZnTransfoSetIdentity(from_t);
        }
        else {
          entry = Tcl_FindHashEntry(wi->t_table, tag);
          if (entry != NULL) {
            /* from is a named transform */
            from_t = (ZnTransfo *) Tcl_GetHashValue(entry);
          }
          else {
            result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
            if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
              Tcl_ResetResult(interp);
              Tcl_AppendResult(interp, "\"", Tcl_GetString(args[argc-2]),
                               "\" must be either identity or a tag or ",
                               "an id or a transform name", (char *) NULL);
              goto error;
            }
            ZnITEM.GetItemTransform(item, &t1);
            from_t = &t1;
          }
        }
      }
      /*
       * Setup the destination transform
       */
      tag = Tcl_GetString(args[argc-2]);
      if (strlen(tag) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      if (strcmp(tag, "device") == 0) {
        to_t = &t2;
        ZnTransfoSetIdentity(to_t);
      }
      else {
        entry = Tcl_FindHashEntry(wi->t_table, tag);
        if (entry != NULL) {
          /* to is a named transform */
          to_t = (ZnTransfo *) Tcl_GetHashValue(entry);
        }
        else {
          result = ZnItemWithTagOrId(wi, args[argc-2], &item, &search_var);
          if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
            Tcl_ResetResult(interp);
            Tcl_AppendResult(interp, "\"", Tcl_GetString(args[argc-2]),
                             "\" must be either identity a tag or ",
                             "an id or a transform name", (char *) NULL);
            goto error;
          }
          ZnITEM.GetItemTransform(item, &t2);
          to_t = &t2;
        }
      }
      ZnTransfoInvert(to_t, &t3);
      to_t = &t3;
      result_t = to_t;

      if (argc == 5) {
        ZnTransfoCompose(&t2, from_t, to_t);
        result_t = &t2;
      }
      /*ZnPrintTransfo(&t);
        ZnPrintTransfo(&inv);*/
      
      if (ZnParseCoordList(wi, args[argc-1], &p,
                           &controls, &num_points, &old_format) == TCL_ERROR) {
        Tcl_AppendResult(interp, " invalid coord list \"",
                         Tcl_GetString(args[argc-1]), "\"", NULL);
        goto error;
      }
      l = Tcl_GetObjResult(interp);
      if (old_format) {
        for (i = 0; i < num_points; i++, p++) {
          ZnTransformPoint(result_t, p, &xp);
          /*printf("p->x=%g, p->y=%g, xp.x=%g, xp.y=%g\n", p->x, p->y, xp.x, xp.y);*/
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(xp.x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(xp.y));
          /* The next case only applies for a one point
           * list with a control flag.
           */
          if (controls && controls[i]) {
            c[0] = controls[i];
            Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(c, -1));
          }
        }
      }
      else {
        for (i = 0; i < num_points; i++, p++) {
          ZnTransformPoint(result_t, p, &xp);
          /*printf("p->x=%g, p->y=%g, xp.x=%g, xp.y=%g\n", p->x, p->y, xp.x, xp.y);*/
          entries[0] = Tcl_NewDoubleObj(xp.x);
          entries[1] = Tcl_NewDoubleObj(xp.y);
          if (controls && controls[i]) {
            c[0] = controls[i];
            entries[2] = Tcl_NewStringObj(c, -1);
            Tcl_ListObjAppendElement(interp, l, Tcl_NewListObj(3, entries));
          }
          else {
            Tcl_ListObjAppendElement(interp, l, Tcl_NewListObj(2, entries));
          }
        }
      }
    }
    break;
    /*
     * translate
     */
  case ZN_W_TRANSLATE:
    {
      ZnBool abs = False;

      if ((argc != 5) && (argc != 6)) {
        Tcl_WrongNumArgs(interp, 1, args, "translate tagOrIdOrTransform xAmount yAmount ?abs?");
        goto error;
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
          goto error;
        }
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &d) == TCL_ERROR) {
        goto error;
      }
      p.x = d;
      if (Tcl_GetDoubleFromObj(interp, args[4], &d) == TCL_ERROR) {
        goto error;
      }
      p.y = d;
      if (argc == 6) {
        if (Tcl_GetBooleanFromObj(interp, args[5], &abs) == TCL_ERROR) {
          goto error;
        }
      }

      if (t) {
        ZnTranslate(t, p.x, p.y, abs);
      }
      else {
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item =ZnTagSearchNext(search_var)) {
          ZnITEM.TranslateItem(item, p.x, p.y, abs);
        }
      }
    }
    break;
    /*
     * treset
     */
  case ZN_W_TRESET:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "treset tagOrIdOrTransform");
        goto error;
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
      }
      else {
        if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
          goto error;
        }
      }

      if (t) {
        ZnTransfoSetIdentity(t);
      }
      else {
        for (item = ZnTagSearchFirst(search_var);
             item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
          ZnITEM.ResetTransfo(item);
        }
      }
    }
    break;
    /*
     * trestore
     */
  case ZN_W_TRESTORE:
    {
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "trestore tagOrId tName");
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, Tcl_GetString(args[argc-1]));
      if (entry == NULL) {
        Tcl_AppendResult(interp, "\"", Tcl_GetString(args[argc-1]),
                         "\" must be a transform name", (char *) NULL);
        goto error;
      }
      t = (ZnTransfo *) Tcl_GetHashValue(entry);
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        ZnITEM.SetTransfo(item, t);
      }
    }
    break;
    /*
     * tsave
     */
  case ZN_W_TSAVE:
    {
      int       is_ident, new, invert=0;
      ZnTransfo *inv, ident;
      char      *from;

      if ((argc != 3) && (argc != 4) && (argc != 5)) {
        Tcl_WrongNumArgs(interp, 1, args, "tsave ?tagOrIdOrTransform? tName ?invert?");
        goto error;
      }
      if (argc == 3) {
        entry = Tcl_FindHashEntry(wi->t_table, Tcl_GetString(args[2]));
        l = Tcl_NewBooleanObj(entry != NULL);
        Tcl_SetObjResult(interp, l);
        goto done;
      }
      from = Tcl_GetString(args[2]);
      is_ident = strcmp(from, "identity") == 0;
      if (is_ident) {
        t = &ident;
        ZnTransfoSetIdentity(t);
      }
      else {
        entry = Tcl_FindHashEntry(wi->t_table, from);
        if (entry != NULL) {
          t = (ZnTransfo *) Tcl_GetHashValue(entry);
        }
        else {
          result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
          if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
            goto error;
          }
          t = item->transfo;
        }
      }
      if (argc == 5) {
        if (Tcl_GetBooleanFromObj(interp, args[4], &invert) != TCL_OK) {
          goto error;
        }
        argc--;
      }
      entry = Tcl_CreateHashEntry(wi->t_table, Tcl_GetString(args[argc-1]), &new);
      if (!new) {
        ZnTransfoFree((ZnTransfo *) Tcl_GetHashValue(entry));
      }
      if (invert && !is_ident) {
        inv = ZnTransfoNew();
        ZnTransfoInvert(t, inv);
        Tcl_SetHashValue(entry, inv);
      }
      else {
        Tcl_SetHashValue(entry, ZnTransfoDuplicate(t));
      }
    }
    break;
    /*
     * tset
     */
  case ZN_W_TSET:
    {
      ZnTransfo     new;

      if (argc != 9) {
        Tcl_WrongNumArgs(interp, 1, args,
                         "tset tagOrIdorTransform m00 m01 m10 m11 m20 m21");
        goto error;
      }
      
      for (i = 0; i < 6; i++) {
        if (Tcl_GetDoubleFromObj(interp, args[3+i], &d) == TCL_ERROR) {
          goto error;
        }
        new._[i/2][i%2] = (float) d;
      }
      str = Tcl_GetString(args[2]);
      if (strlen(str) == 0) {
        Tcl_AppendResult(interp, " must provide a valid tagOrIdOrTransform", NULL);
        goto error;
      }
      entry = Tcl_FindHashEntry(wi->t_table, str);
      if (entry != NULL) {
        t = (ZnTransfo *) Tcl_GetHashValue(entry);
        *t = new;
      }
      else {
        result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
        if ((result == TCL_ERROR) || (item == ZN_NO_ITEM)) {
          Tcl_ResetResult(interp);
          Tcl_AppendResult(interp, "\"", Tcl_GetString(args[2]),
                           "\" must be either a tag, ",
                           "an id or a transform name", (char *) NULL);
          goto error;
        }
        ZnITEM.SetTransfo(item, &new);
      }
      break;
    }
    /*
     * type
     */
  case ZN_W_TYPE:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "type tagOrId");
        goto error;
      }
      result = ZnItemWithTagOrId(wi, args[2], &item, &search_var);
      if (result == TCL_ERROR) {
        goto error;
      }
      if (item != ZN_NO_ITEM) {
        l = Tcl_NewStringObj(item->class->name, -1);
        Tcl_SetObjResult(interp, l);      
      }
    }
    break;
    /*
     * vertexat
     */
  case ZN_W_VERTEX_AT:
    {
      int contour, vertex, o_vertex;
      
      if (argc != 5) {
        Tcl_WrongNumArgs(interp, 1, args, " vertexat tagOrId x y");
        goto error;
      }
      if (ZnTagSearchScan(wi, args[2], &search_var) == TCL_ERROR) {
        goto error;
      }
      for (item = ZnTagSearchFirst(search_var);
           item != ZN_NO_ITEM; item = ZnTagSearchNext(search_var)) {
        if (item->class->PickVertex != NULL) {
          break;
        }
      }
      if (item == ZN_NO_ITEM) {
        Tcl_AppendResult(interp, "can't find a suitable item \"",
                         Tcl_GetString(args[2]), "\"", NULL);
        goto error;
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &d) == TCL_ERROR) {
        goto error;
      }
      p.x = d;
      if (Tcl_GetDoubleFromObj(interp, args[4], &d) == TCL_ERROR) {
        goto error;
      }
      p.y = d;
      item->class->PickVertex(item, &p, &contour, &vertex, &o_vertex);
      l = Tcl_GetObjResult(interp);
      Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(contour));
      Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(vertex));
      Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(o_vertex));
      break;
    }

    /* xview */
  case ZN_W_XVIEW:
    {
      int       count, type;
      ZnReal    new_x=0.0, fraction;
      
      if (argc == 2) {
#ifdef PTK
        ZnReal  first, last;
        ScrollFractions(wi->origin.x, wi->origin.x + Tk_Width(wi->win),
                        wi->scroll_xo, wi->scroll_xc, &first, &last);
        Tcl_DoubleResults(interp, 2, 0, first, last);
#else
        Tcl_SetObjResult(interp,
                         ScrollFractions(wi->origin.x, wi->origin.x + Tk_Width(wi->win),
                                         wi->scroll_xo, wi->scroll_xc));
#endif
      }
      else {
        type = Tk_GetScrollInfoObj(interp, argc, args, &fraction, &count);
        switch (type) {
        case TK_SCROLL_ERROR:
          result = TCL_ERROR;
          goto done;
        case TK_SCROLL_MOVETO:
          new_x = (wi->scroll_xo + (int) (fraction * (wi->scroll_xc - wi->scroll_xo) + 0.5));
          break;
        case TK_SCROLL_PAGES:
          new_x = (int) (wi->origin.x + count * 0.9 * Tk_Width(wi->win));
          break;
        case TK_SCROLL_UNITS:
          if (wi->x_scroll_incr > 0) {
            new_x = wi->origin.x + count * wi->x_scroll_incr;
          }
          else {
            new_x = (int) (wi->origin.x + count * 0.1 * Tk_Width(wi->win));
          }
          break;
        }
        SetOrigin(wi, new_x, wi->origin.y);
      }
      break;
    }
    
    /*yview */
  case ZN_W_YVIEW:
    {
      int       count, type;
      ZnReal    new_y = 0.0, fraction;

      if (argc == 2) {
#ifdef PTK
        ZnReal  first, last;
        ScrollFractions(wi->origin.y, wi->origin.y + Tk_Height(wi->win),
                        wi->scroll_yo, wi->scroll_yc, &first, &last);
        Tcl_DoubleResults(interp, 2, 0, first, last);
#else
        Tcl_SetObjResult(interp,
                         ScrollFractions(wi->origin.y, wi->origin.y + Tk_Height(wi->win),
                                         wi->scroll_yo, wi->scroll_yc));
#endif
      }
      else {
        type = Tk_GetScrollInfoObj(interp, argc, args, &fraction, &count);
        switch (type) {
        case TK_SCROLL_ERROR:
          result = TCL_ERROR;
          goto done;
        case TK_SCROLL_MOVETO:
          new_y = (wi->scroll_yo + (int) (fraction * (wi->scroll_yc - wi->scroll_yo) + 0.5));
          break;
        case TK_SCROLL_PAGES:
          new_y = (int) (wi->origin.y + count * 0.9 * Tk_Height(wi->win));
          break;
        case TK_SCROLL_UNITS:
          if (wi->y_scroll_incr > 0) {
            new_y = wi->origin.y + count * wi->y_scroll_incr;
          }
          else {
            new_y = (int) (wi->origin.y + count * 0.1 * Tk_Height(wi->win));
          }
          break;
        }
        SetOrigin(wi, wi->origin.x, new_y);
      }
      break;
    }
  }
  
 done:
  ZnTagSearchDestroy(search_var);
  Tcl_Release((ClientData) wi);
  return result;
  
 error:
  result = TCL_ERROR;
  goto done;
}


/*
 *----------------------------------------------------------------------
 *
 * Configure --
 *
 *      This procedure is called to process an args/argc list in
 *      conjunction with the Tk option database to configure (or
 *      reconfigure) a Zinc widget.
 *
 * Results:
 *      The return value is a standard Tcl result.  If TCL_ERROR is
 *      returned, then interp->result contains an error message.
 *
 * Side effects:
 *      Configuration information, such as colors, border width,
 *      etc. get set for the widget;  old resources get freed,
 *      if there were any.
 *
 *----------------------------------------------------------------------
 */
#ifdef PTK_800
static int
Configure(Tcl_Interp            *interp,/* Used for error reporting. */
          ZnWInfo               *wi,    /* Information about widget. */
          int                   argc,   /* Number of valid entries in args. */
          Tcl_Obj       *CONST  args[], /* Arguments. */
          int                   flags)  /* Flags to pass to Tk_ConfigureWidget. */
{
#define CONFIG_PROBE(offset) (ISSET(config_specs[offset].specFlags, \
                                    TK_CONFIG_OPTION_SPECIFIED))
  ZnBool  init;
  int     render;

  init = wi->fore_color == NULL;
  render = wi->render;
  if (Tk_ConfigureWidget(interp, wi->win, config_specs, argc,
#ifdef PTK
                         (Tcl_Obj **) args, (char *) wi, flags) != TCL_OK)
#else
                         (CONST char **) args, (char *) wi, flags|TK_CONFIG_OBJS) != TCL_OK)
#endif
  {
    return TCL_ERROR;
  }
  if (!init) {
    if (wi->render != render) {
      ZnWarning("It is not possible to change the -render option after widget creation.\n");
    }
    wi->render = render;
  }
  /*
   * Reset the render mode if GL is not available. It'll be too late
   * to do this after images or fonts have been allocated.
   */
  if ((wi->render != 0) && ISCLEAR(wi->flags, ZN_HAS_GL)) {
    fprintf(stderr, "GLX not available (need at least a 24 bits buffer with stencil)\n");
    wi->render = 0;
  }

#ifdef GL
  if (CONFIG_PROBE(FONT_SPEC) || !wi->font_tfi) {
    if (wi->font_tfi) {
      ZnFreeTexFont(wi->font_tfi);
    }
    wi->font_tfi = ZnGetTexFont(wi, wi->font);
  }
#ifdef ATC
  if (CONFIG_PROBE(MAP_TEXT_FONT_SPEC) || !wi->map_font_tfi) {
    if (wi->map_font_tfi) {
      ZnFreeTexFont(wi->map_font_tfi);
    }
    wi->map_font_tfi = ZnGetTexFont(wi, wi->map_text_font);
  }
#endif
#endif

  /*
   * Maintain the pick aperture within meaningful bounds.
   */
  if (wi->pick_aperture < 0) {
    wi->pick_aperture = 0;
  }
  if (CONFIG_PROBE(BACK_COLOR_SPEC) || !wi->relief_grad) {
    XColor         *color;
    unsigned short alpha;

    Tk_SetWindowBackground(wi->win, ZnGetGradientPixel(wi->back_color, 0.0));
    if (wi->relief_grad) {
      ZnFreeGradient(wi->relief_grad);
      wi->relief_grad = NULL;
    }
    if (wi->relief != ZN_RELIEF_FLAT) {
      color = ZnGetGradientColor(wi->back_color, 0.0, &alpha);
      wi->relief_grad = ZnGetReliefGradient(interp, wi->win,
                                            Tk_NameOfColor(color), alpha);
    }
  }
  if (CONFIG_PROBE(BACK_COLOR_SPEC) || CONFIG_PROBE(LIGHT_ANGLE_SPEC)) {
    ZnDamageAll(wi);
  }
  if (CONFIG_PROBE(RELIEF_SPEC)) {
    ZnNeedRedisplay(wi);
  }
  
  wi->inset = wi->border_width + wi->highlight_width;
  if (CONFIG_PROBE(BORDER_WIDTH_SPEC) ||
      CONFIG_PROBE(HIGHLIGHT_THICKNESS_SPEC)) {
    ZnDamageAll(wi);
  }
#ifdef ATC
  if (CONFIG_PROBE(SPEED_VECTOR_LENGTH_SPEC) ||
      CONFIG_PROBE(VISIBLE_HISTORY_SIZE_SPEC) ||
      CONFIG_PROBE(MANAGED_HISTORY_SIZE_SPEC)) {
    ZnITEM.InvalidateItems(wi->top_group, ZnTrack);
  }
  if (CONFIG_PROBE(MAP_DISTANCE_SYMBOL_SPEC)) {
    ZnITEM.InvalidateItems(wi->top_group, ZnMap);
  }
  if (CONFIG_PROBE(TRACK_SYMBOL_SPEC)) {
    ZnITEM.InvalidateItems(wi->top_group, ZnTrack);
    ZnITEM.InvalidateItems(wi->top_group, ZnWayPoint);
  }
#endif
        
  /*
   * Request the new geometry.
   */
  if (CONFIG_PROBE(WIDTH_SPEC) || CONFIG_PROBE(HEIGHT_SPEC) ||
      CONFIG_PROBE(BORDER_WIDTH_SPEC) ||
      CONFIG_PROBE(HIGHLIGHT_THICKNESS_SPEC) || ISCLEAR(wi->flags, ZN_REALIZED)) {
    Tk_GeometryRequest(wi->win, wi->opt_width, wi->opt_height);
  }

  if (CONFIG_PROBE(TILE_SPEC)) {
    ZnDamageAll(wi);
  }
  
  /*
   * Update the registration with the overlap manager.
   */
#ifdef ATC
  if (CONFIG_PROBE(OVERLAP_MANAGER_SPEC)) {
    Tcl_HashEntry       *entry;
    ZnItem              grp;

    if (wi->om_group != ZN_NO_ITEM) {
      OmUnregister((void *) wi);
      wi->om_group = ZN_NO_ITEM;
    }
    if (wi->om_group_id != 0) {
      entry = Tcl_FindHashEntry(wi->id_table, (char *) wi->om_group_id);
      if (entry != NULL) {
        grp = (ZnItem) Tcl_GetHashValue(entry);
        if (grp->class == ZnGroup) {
          OmRegister((void *) wi, ZnSendTrackToOm,
                     ZnSetLabelAngleFromOm, ZnQueryLabelPosition);
          wi->om_group = grp;
        }
      }
    }
  }
#endif

  if (CONFIG_PROBE(INSERT_WIDTH_SPEC) && wi->focus_item) {
    ZnITEM.Invalidate(wi->focus_item, ZN_COORDS_FLAG);
  }
  /*
   * Update the blinking cursor timing if on/off time has changed.
   */
  if (ISSET(wi->flags, ZN_GOT_FOCUS) &&
      (CONFIG_PROBE(INSERT_ON_TIME_SPEC) ||
       CONFIG_PROBE(INSERT_OFF_TIME_SPEC))) {
    Focus(wi, True);
  }

  if (CONFIG_PROBE(SCROLL_REGION_SPEC)) {
    /*
     * Compute the scroll region
     */
    wi->scroll_xo = wi->scroll_yo = 0;
    wi->scroll_xc = wi->scroll_yc = 0;
    if (wi->region != NULL) {
      int        argc2;
#ifdef PTK
      Arg       *args2;
#else
      CONST char **args2;
#endif

#ifdef PTK
      if (Tcl_ListObjGetElements(interp, wi->region, &argc2, &args2) != TCL_OK)
#else
      if (Tcl_SplitList(interp, wi->region, &argc2, &args2) != TCL_OK)
#endif
      {
        return TCL_ERROR;
      }
      if (argc2 != 4) {
        Tcl_AppendResult(interp, "bad scrollRegion \"", wi->region, "\"", (char *) NULL);
      badRegion:
#ifndef PTK
        ZnFree(wi->region);
        ZnFree(args2);
#endif
        wi->region = NULL;
        return TCL_ERROR;
      }
#ifdef PTK
#ifdef PTK_800
      if ((Tk_GetPixels(interp, wi->win, LangString(args2[0]), &wi->scroll_xo) != TCL_OK) ||
          (Tk_GetPixels(interp, wi->win, LangString(args2[1]), &wi->scroll_yo) != TCL_OK) ||
          (Tk_GetPixels(interp, wi->win, LangString(args2[2]), &wi->scroll_xc) != TCL_OK) ||
          (Tk_GetPixels(interp, wi->win, LangString(args2[3]), &wi->scroll_yc) != TCL_OK))
#else
      if ((Tk_GetPixelsFromObj(interp, wi->win, args2[0], &wi->scroll_xo) != TCL_OK) ||
          (Tk_GetPixelsFromObj(interp, wi->win, args2[1], &wi->scroll_yo) != TCL_OK) ||
          (Tk_GetPixelsFromObj(interp, wi->win, args2[2], &wi->scroll_xc) != TCL_OK) ||
          (Tk_GetPixelsFromObj(interp, wi->win, args2[3], &wi->scroll_yc) != TCL_OK))
#endif
#else
      if ((Tk_GetPixels(interp, wi->win, args2[0], &wi->scroll_xo) != TCL_OK) ||
          (Tk_GetPixels(interp, wi->win, args2[1], &wi->scroll_yo) != TCL_OK) ||
          (Tk_GetPixels(interp, wi->win, args2[2], &wi->scroll_xc) != TCL_OK) ||
          (Tk_GetPixels(interp, wi->win, args2[3], &wi->scroll_yc) != TCL_OK))
#endif
      {
        goto badRegion;
      }
    }
  }

  if (CONFIG_PROBE(SCROLL_REGION_SPEC) ||
      CONFIG_PROBE(CONFINE_SPEC)) {
    SetOrigin(wi, wi->origin.x, wi->origin.y);
    SET(wi->flags, ZN_UPDATE_SCROLLBARS);
  }
  
  if (CONFIG_PROBE(FOLLOW_POINTER_SPEC)) {
    if (wi->follow_pointer) {
      /* Flag has just been turned on, process
       * the last known positional event to update
       * the item under pointer.
       */
      if (wi->pick_event.type == ButtonPress ||
          wi->pick_event.type == ButtonRelease ||
          wi->pick_event.type == MotionNotify ||
          wi->pick_event.type == EnterNotify ||
          wi->pick_event.type == LeaveNotify) {
        Tcl_Preserve((ClientData) wi);
        CLEAR(wi->flags, ZN_INTERNAL_NEED_REPICK);
        PickCurrentItem(wi, &wi->pick_event);
        Tcl_Release((ClientData) wi);
      }
    }
  }
  
  return TCL_OK;
}
#else
static void
TileUpdate(void *client_data)
{
  ZnWInfo *wi = (ZnWInfo*) client_data;

  ZnDamageAll(wi);
}

static int
Configure(Tcl_Interp            *interp,/* Used for error reporting. */
          ZnWInfo               *wi,    /* Information about widget. */
          int                   argc,   /* Number of valid entries in args. */
          Tcl_Obj       *CONST  args[]) /* Arguments. */
{
  ZnBool                init;
  int                   render, mask, error;
  Tk_SavedOptions       saved_options;
  Tcl_Obj               *error_result = NULL;

  render = wi->render;
  init = render < 0;

  for (error = 0; error <= 1; error++) {
    if (!error) {
      if (Tk_SetOptions(interp, (char *) wi, wi->opt_table, argc, args,
                        wi->win, &saved_options, &mask) != TCL_OK) {
        continue;
      }
    }
    else {
      /* Save the error value for later report */
      error_result = Tcl_GetObjResult(interp);
      Tcl_IncrRefCount(error_result);
      Tk_RestoreSavedOptions(&saved_options);
    }

    if (!init) {
      if (render != wi->render) {
        ZnWarning("It is not possible to change the -render option after widget creation.\n");
        wi->render = render;
      }
    }
    else if (wi->render < 0) {
      wi->render = 0;
    }
    /*
     * Reset the render mode if GL is not available. It'll be too late
     * to do this after images or fonts have been allocated.
     */
    else if ((wi->render != 0) && ISCLEAR(wi->flags, ZN_HAS_GL)) {
      fprintf(stderr, "GLX not available (need at least a 24 bits buffer with stencil)\n");
      wi->render = 0;
    }

    if ((mask & CONFIG_SCROLL_REGION) || init) {
      /*
       * Compute the scroll region
       */
      wi->scroll_xo = wi->scroll_yo = 0;
      wi->scroll_xc = wi->scroll_yc = 0;
      if (wi->region != NULL) {
        int      argc2;
        Tcl_Obj **args2;
        
        if (Tcl_ListObjGetElements(interp, wi->region, &argc2, &args2) != TCL_OK) {
        badRegion:
          Tcl_AppendResult(interp, "bad scrollRegion \"",
                           Tcl_GetString(wi->region), "\"", (char *) NULL);
          continue;
        }
        if (argc2 != 4) {
          goto badRegion;
        }
#ifdef PTK_800
        if ((Tk_GetPixels(interp, wi->win, LangString(args2[0]), &wi->scroll_xo) != TCL_OK) ||
            (Tk_GetPixels(interp, wi->win, LangString(args2[1]), &wi->scroll_yo) != TCL_OK) ||
            (Tk_GetPixels(interp, wi->win, LangString(args2[2]), &wi->scroll_xc) != TCL_OK) ||
            (Tk_GetPixels(interp, wi->win, LangString(args2[3]), &wi->scroll_yc) != TCL_OK))
#else
        if ((Tk_GetPixelsFromObj(interp, wi->win, args2[0], &wi->scroll_xo) != TCL_OK) ||
            (Tk_GetPixelsFromObj(interp, wi->win, args2[1], &wi->scroll_yo) != TCL_OK) ||
            (Tk_GetPixelsFromObj(interp, wi->win, args2[2], &wi->scroll_xc) != TCL_OK) ||
            (Tk_GetPixelsFromObj(interp, wi->win, args2[3], &wi->scroll_yc) != TCL_OK))
#endif
        {
          goto badRegion;
        }
      }
    }
    
    if ((mask & CONFIG_SET_ORIGIN) || init) {
      SetOrigin(wi, wi->origin.x, wi->origin.y);
      SET(wi->flags, ZN_UPDATE_SCROLLBARS);
    }
    
#ifdef GL
    if ((mask & CONFIG_FONT) || !wi->font_tfi) {
      if (wi->font_tfi) {
        ZnFreeTexFont(wi->font_tfi);
      }
      wi->font_tfi = ZnGetTexFont(wi, wi->font);
    }
#ifdef ATC
    if ((mask & CONFIG_MAP_FONT) || !wi->map_font_tfi) {
      if (wi->map_font_tfi) {
        ZnFreeTexFont(wi->map_font_tfi);
      }
      wi->map_font_tfi = ZnGetTexFont(wi, wi->map_text_font);
    }
#endif
#endif

    if ((mask & CONFIG_TILE) || init) {
      char *tile_name;
      if (wi->tile) {
        ZnFreeImage(wi->tile, TileUpdate, wi);
      }
      if (!wi->tile_obj || !*(tile_name = Tcl_GetString(wi->tile_obj))) {
        wi->tile = ZnUnspecifiedImage;
      }
      else {
        wi->tile = ZnGetImage(wi, tile_name, TileUpdate, wi);
        if (wi->tile == ZnUnspecifiedImage) {
          Tcl_AppendResult(interp, "Incorrect tile \"", tile_name, "\"", (char *) NULL);
          continue;
        }
      }
    }

#ifdef ATC
    if ((mask & CONFIG_MAP_SYMBOL) || init) {
      if (wi->map_distance_symbol) {
        ZnFreeImage(wi->map_distance_symbol, NULL, NULL);
      }
      wi->map_distance_symbol = ZnGetImage(wi, Tcl_GetString(wi->map_symbol_obj), NULL, NULL);
      if ((wi->map_distance_symbol == ZnUnspecifiedImage) ||
          ! ZnImageIsBitmap(wi->map_distance_symbol)) {
        Tcl_AppendResult(interp, "Incorrect bitmap \"",
                         Tcl_GetString(wi->map_symbol_obj), "\"", (char *) NULL);
        continue;
      }
    }
    
    if ((mask & CONFIG_TRACK_SYMBOL) || init) {
      if (wi->track_symbol) {
        ZnFreeImage(wi->track_symbol, NULL, NULL);
      }
      wi->track_symbol = ZnGetImage(wi, Tcl_GetString(wi->track_symbol_obj), NULL, NULL);
      if ((wi->track_symbol == ZnUnspecifiedImage) ||
          ! ZnImageIsBitmap(wi->track_symbol)) {
        Tcl_AppendResult(interp, "Incorrect bitmap \"",
                         Tcl_GetString(wi->track_symbol_obj), "\"", (char *) NULL);
        continue;
 
      }
    }
#endif

    /*
     * Maintain the pick aperture within meaningful bounds.
     */
    if (wi->pick_aperture < 0) {
      wi->pick_aperture = 0;
    }

    if ((mask & CONFIG_BACK_COLOR) || !wi->relief_grad) {
      XColor       *color;
      unsigned short alpha;
      
      Tk_SetWindowBackground(wi->win, ZnGetGradientPixel(wi->back_color, 0.0));
      if (wi->relief_grad) {
        ZnFreeGradient(wi->relief_grad);
        wi->relief_grad = NULL;
      }
      if (wi->relief != ZN_RELIEF_FLAT) {
        color = ZnGetGradientColor(wi->back_color, 0.0, &alpha);
        wi->relief_grad = ZnGetReliefGradient(interp, wi->win,
                                              Tk_NameOfColor(color), alpha);
      }
    }
    if (mask & CONFIG_DAMAGE_ALL) {
      ZnDamageAll(wi);
    }
    if ((mask & CONFIG_REDISPLAY) || init) {
      ZnNeedRedisplay(wi);
    }
    
    wi->inset = wi->border_width + wi->highlight_width;
    
#ifdef ATC
    if (mask & CONFIG_INVALIDATE_TRACKS) {
      ZnITEM.InvalidateItems(wi->top_group, ZnTrack);
    }
    if (mask & CONFIG_INVALIDATE_MAPS) {
      ZnITEM.InvalidateItems(wi->top_group, ZnMap);
    }
    if (mask & CONFIG_INVALIDATE_WPS) {
      ZnITEM.InvalidateItems(wi->top_group, ZnWayPoint);
    }
#endif
                
    /*
     * Request the new geometry.
     */
    if ((mask & CONFIG_REQUEST_GEOM) || init) {
      Tk_GeometryRequest(wi->win, wi->opt_width, wi->opt_height);
    }
    
    /*
     * Update the registration with the overlap manager.
     */
#ifdef ATC
    if (mask & CONFIG_OM) {
      Tcl_HashEntry     *entry;
      ZnItem            grp;
      
      if (wi->om_group != ZN_NO_ITEM) {
        OmUnregister((void *) wi);
        wi->om_group = ZN_NO_ITEM;
      }
      if (wi->om_group_id != 0) {
        entry = Tcl_FindHashEntry(wi->id_table, (char *) wi->om_group_id);
        if (entry != NULL) {
          grp = (ZnItem) Tcl_GetHashValue(entry);
          if (grp->class == ZnGroup) {
            OmRegister((void *) wi, ZnSendTrackToOm,
                       ZnSetLabelAngleFromOm, ZnQueryLabelPosition);
            wi->om_group = grp;
          }
        }
      }
    }
#endif
    
    if ((mask & CONFIG_FOCUS_ITEM) && wi->focus_item) {
      ZnITEM.Invalidate(wi->focus_item, ZN_COORDS_FLAG);
    }
    /*
     * Update the blinking cursor timing if on/off time has changed.
     */
    if (ISSET(wi->flags, ZN_GOT_FOCUS) && (mask & CONFIG_FOCUS)) {
      Focus(wi, True);
    }
    
    if (mask & CONFIG_FOLLOW_POINTER) {
      if (wi->follow_pointer) {
        /* Flag has just been turned on, process
         * the last known positional event to update
         * the item under pointer.
         */
        if (wi->pick_event.type == ButtonPress ||
            wi->pick_event.type == ButtonRelease ||
            wi->pick_event.type == MotionNotify ||
            wi->pick_event.type == EnterNotify ||
            wi->pick_event.type == LeaveNotify) {
          Tcl_Preserve((ClientData) wi);
          CLEAR(wi->flags, ZN_INTERNAL_NEED_REPICK);
          PickCurrentItem(wi, &wi->pick_event);
          Tcl_Release((ClientData) wi);
        }
      }
    }
    break;
  }

  if (error) {
    Tcl_SetObjResult(interp, error_result);
    Tcl_DecrRefCount(error_result);
    return TCL_ERROR;
  }
  else {
    Tk_FreeSavedOptions(&saved_options);
    return TCL_OK;
  }
}
#endif

/*
 *----------------------------------------------------------------------
 *
 * Focus --
 *
 *      This procedure is called whenever a zinc gets or loses the
 *      input focus.  It's also called whenever the window is
 *      reconfigured while it has the focus.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The cursor gets turned on or off.
 *
 *----------------------------------------------------------------------
 */
static void
Blink(ClientData        client_data)
{
  ZnWInfo *wi = (ZnWInfo *) client_data;

  if (ISCLEAR(wi->flags, ZN_GOT_FOCUS) || (wi->insert_off_time == 0)) {
    return;
  }
  if (wi->text_info.cursor_on) {
    wi->text_info.cursor_on = 0;
    wi->blink_handler = Tcl_CreateTimerHandler(wi->insert_off_time,
                                               Blink, client_data);
  }
  else {
    wi->text_info.cursor_on = 1;
    wi->blink_handler = Tcl_CreateTimerHandler(wi->insert_on_time,
                                               Blink, client_data);
  }
  if ((wi->focus_item != ZN_NO_ITEM) &&
      (wi->focus_item->class->Cursor != NULL)) {
    ZnITEM.Invalidate(wi->focus_item, ZN_DRAW_FLAG);
  }
}

static void
Focus(ZnWInfo   *wi,
      ZnBool            got_focus)
{
  Tcl_DeleteTimerHandler(wi->blink_handler);
  if (got_focus) {
    SET(wi->flags, ZN_GOT_FOCUS);
    wi->text_info.cursor_on = 1;
    if (wi->insert_off_time != 0) {
      wi->blink_handler = Tcl_CreateTimerHandler(wi->insert_off_time,
                                                 Blink, (ClientData) wi);
    }
  }
  else {
    CLEAR(wi->flags, ZN_GOT_FOCUS);
    wi->text_info.cursor_on = 0;
    wi->blink_handler = (Tcl_TimerToken) NULL;
  }
  if ((wi->focus_item != ZN_NO_ITEM) &&
      (wi->focus_item->class->Cursor != NULL)){
    ZnITEM.Invalidate(wi->focus_item, ZN_COORDS_FLAG);
  }
  /*printf("focus %s\n", got_focus ? "in" : "out");*/
  if (wi->highlight_width > 0) {
    ZnNeedRedisplay(wi);
  }
}


/*
 *----------------------------------------------------------------------
 *
 * Event --
 *
 *      This procedure is invoked by the Tk dispatcher for various
 *      events on Zincs.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      When the window gets deleted, internal structures get
 *      cleaned up.  When it gets exposed, it is redisplayed.
 *
 *----------------------------------------------------------------------
 */
static void
TopEvent(ClientData     client_data,    /* Information about widget. */
         XEvent         *event)
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  if (event->type == ConfigureNotify) {
    /*printf("Window moved\n");*/
    SET(wi->flags, ZN_CONFIGURE_EVENT);
  }  
}

static void
Event(ClientData client_data,   /* Information about widget. */
      XEvent    *event) /* Information about event. */
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  XGCValues     values;
  ZnBBox        bbox;

  /*printf("=============== DEBUT %s %d EVENT ==================\n",
         event->type == MapNotify ? "MAP":
         event->type == Expose? "EXPOSE" :
         event->type == ConfigureNotify ? "CONFIGURE" :
         event->type == VisibilityNotify ? "VISIBILITY" :
         event->type == DestroyNotify ? "DESTROY" :
         "??", event->type);*/
  if (event->type == MapNotify) {
    SET(wi->flags, ZN_CONFIGURE_EVENT);
    if (!wi->gc) {
      SET(wi->flags, ZN_REALIZED);
#ifdef GL
      InitRendering2(wi);
#endif

      /*
       * Get the work GC and suppress GraphicExpose
       * and NoExpose events reception.
       */
      wi->gc = XCreateGC(wi->dpy, Tk_WindowId(wi->win), 0, NULL);
      values.graphics_exposures = False;
      XChangeGC(wi->dpy, wi->gc, GCGraphicsExposures, &values);

      /*
       * Set the real top window above us.
       */
      {
        Window    parent, root, *children=NULL;
        Tk_Window top_level;
        int       num_children, success;
        
        top_level = wi->win;
        while (!Tk_IsTopLevel(top_level)) {
          top_level = Tk_Parent(top_level);
        }
        success = XQueryTree(wi->dpy, Tk_WindowId(top_level), &root, &parent,
                             &children, &num_children);
        if (!success || (root == parent)) {
          wi->real_top = Tk_WindowId(top_level);
        }
        else {
          wi->real_top = parent;
        }
        /*
         * Needed under glx to suspend update with scissors after
         * a move to synchronise the two buffers. Fix a refresh
         * bug when the window is partially clipped by the display
         * border. Can be usefull under Windows too.
         */
        Tk_CreateEventHandler(top_level, StructureNotifyMask, TopEvent, (ClientData) wi);
        if (children && success) {
          XFree(children);
        }
      }
    }
    ZnNeedRedisplay(wi);
  }
  else if (event->type == Expose) {
    ZnDim       width, height;

    SET(wi->flags, ZN_CONFIGURE_EVENT);

    bbox.orig.x = (((XExposeEvent*) event)->x);
    bbox.orig.y = (((XExposeEvent*) event)->y);
    width = ((XExposeEvent*) event)->width;
    height = ((XExposeEvent*) event)->height;
    if (bbox.orig.x < 0) {
      width += bbox.orig.x;
      bbox.orig.x = 0;
    }
    if (bbox.orig.y < 0) {
      height += bbox.orig.y;
      bbox.orig.y = 0;
    }
    bbox.corner.x = MIN(wi->width, bbox.orig.x + width);
    bbox.corner.y = MIN(wi->height, bbox.orig.y + height);
    
    /*printf("expose %d %d %d %d\n",
           ((XExposeEvent*) event)->x, ((XExposeEvent*) event)->y,
           ((XExposeEvent*) event)->width, ((XExposeEvent*) event)->height);*/
    /*
     * Add the exposed area to the expose region and
     * schedule an asynchronous redisplay of the window
     * if we are done adding exposed parts.
     */
    ZnAddBBoxToBBox(&wi->exposed_area, &bbox);
    if (/*(((XExposeEvent*) event)->count == 0) &&*/
        !ZnIsEmptyBBox(&wi->exposed_area)) {
      ZnNeedRedisplay(wi);
    }
  }
  /*
   * Resize the double buffer pixmap and prepare to redisplay
   * the whole scene. The transform parameters are not
   * modified as a result of the resize. If the application
   * need such change, it can bind a handler on <Configure>.
   */
  else if (event->type == ConfigureNotify) {
    int    int_width, int_height;

    SET(wi->flags, ZN_CONFIGURE_EVENT);

    int_width = Tk_Width(wi->win);
    int_height = Tk_Height(wi->win);
    
    if ((wi->width != int_width) || (wi->height != int_height)) {
      bbox.orig.x = bbox.orig.y = 0;
      bbox.corner.x = MAX(wi->width, int_width);
      bbox.corner.y = MAX(wi->height, int_height);
      wi->opt_width = wi->width = int_width;
      wi->opt_height = wi->height = int_height;

      ZnResetTransformStack(wi);

      SET(wi->flags, ZN_UPDATE_SCROLLBARS);
      /*
       * The call below is needed in order to recenter the view if
       * it's confined and the scroll region is smaller than the
       * window.
       */
      SetOrigin(wi, wi->origin.x, wi->origin.y);

      ZnDamage(wi, &bbox);
      ZnITEM.Invalidate(wi->top_group, ZN_TRANSFO_FLAG);
      
      /*
       * Reallocate the double buffer pixmap/image.
       */
      if (!wi->render) {
        /*printf("reallocating double buffer\n");*/
        if (wi->draw_buffer) {
          Tk_FreePixmap(wi->dpy, wi->draw_buffer);
        }
        wi->draw_buffer = Tk_GetPixmap(wi->dpy, RootWindowOfScreen(wi->screen),
                                       int_width, int_height,
                                       DefaultDepthOfScreen(wi->screen));
      }
    }
    else {
      /*
       * In case of a window reconfiguration following a change
       * of border size, set the exposed area to force a copy
       * of the back buffer to the screen.
       */
      bbox.orig.x = bbox.orig.y = 0;
      bbox.corner.x = Tk_Width(wi->win);
      bbox.corner.y = Tk_Height(wi->win);
      ZnAddBBoxToBBox(&wi->exposed_area, &bbox);      
    }
    ZnNeedRedisplay(wi);
  }
  /*
   * Take into account that the window has been actually cancelled.
   * Remove the corresponding widget command, unregister any
   * pending Redisplay and eventually free the widget's memory.
   */
  else if (event->type == DestroyNotify) {
    Destroy(wi);
  }
  else if (event->type == FocusIn) {
    if (event->xfocus.detail != NotifyInferior) {
      Focus(wi, True);
    }
  }
  else if (event->type == FocusOut) {
    if (event->xfocus.detail != NotifyInferior) {
      Focus(wi, False);
    }
  }
  
  /*printf("=============== FIN %s EVENT ==================\n",
         event->type == MapNotify ? "MAP":
         event->type == Expose? "EXPOSE" :
         event->type == ConfigureNotify ? "CONFIGURE" :
         event->type == VisibilityNotify ? "VISIBILITY" :
         event->type == DestroyNotify ? "DESTROY" :
         "??");*/
}


/*
 *----------------------------------------------------------------------
 *
 * DoEvent --
 *
 *      Trigger the bindings associated with an event.
 *
 *----------------------------------------------------------------------
 */
static void
DoEvent(ZnWInfo *wi,
        XEvent  *event,
        ZnBool  bind_item, /* Controls whether item bindings will trigger.
                            * Useful for Enter/Leaves between fields */
        ZnBool  bind_part) /* Controls whether part bindings will trigger.
                            * Useful for precise control of Enter/Leaves
                            * during grabs. */
{
#define NUM_STATIC 4
  ClientData            items[NUM_STATIC], *its;
  static unsigned int   worksize = 128, len, num, num_tags;
  static char           *workspace = NULL;
  unsigned int          i, ptr;
  ClientData            *tag_list = NULL;
  ZnItem                item;
  int                   part;

#define BIND_ITEM(test)                 \
  if (bind_item && (test)) {            \
    its[ptr] = (ClientData) all_uid;    \
    ptr++;                              \
    for (i = 0; i < num_tags; i++) {    \
      its[ptr] = tag_list[i];           \
      ptr++;                            \
    }                                   \
    its[ptr] = (ClientData) item;       \
    ptr++;                              \
  }

  if (wi->binding_table == NULL) {
    //printf("no bindings\n");
    return;
  }

  item = wi->current_item;
  part = wi->current_part;
  if ((event->type == KeyPress) || (event->type == KeyRelease)) {
    item = wi->focus_item;
    part = wi->focus_field;
  }
  
  if ((item == ZN_NO_ITEM) || !item->class->IsSensitive(item, ZN_NO_PART)) {
    return;
  }
  
  /*
   * Set up an array with all the relevant elements for processing
   * this event.  The relevant elements are (a) the event's item/part
   * tag (i.e item:part), (b) the event's item, (c) the tags
   * associated with the event's item, and (d) the tag 'all'.
   */
  num = 0;
  num_tags = 0;
  its = items;
  bind_part = (bind_part &&
               (part != ZN_NO_PART) &&
               item->class->IsSensitive(item, part) &&
               ((wi->current_item != ZN_NO_ITEM) &&
                (wi->current_item->class->num_parts ||
                 wi->current_item->class->GetFieldSet)));

  //printf("type=%s, current=%d, new=%d --> %s, currentp %d, newp %d\n",
    //     event->type==EnterNotify?"<Enter>":
    //     event->type==LeaveNotify?"<Leave>":
    //     event->type==MotionNotify?"<Motion>":"other",
    //     wi->current_item?wi->current_item->id:0,
    //     wi->new_item?wi->new_item->id:0,
    //     bind_item?"bind":"nobind",
    //     wi->current_part, wi->new_part);
  if (bind_item) {
    num += 2;
  }
  if (bind_part) {
    num++;
    if (!workspace) {
      workspace = ZnMalloc(worksize);
    }
  }
  if (item->tags) {
    num_tags = ZnListSize(item->tags);
    if (bind_item) {
      num += num_tags;
    }
    if (bind_part) {
      num += num_tags;
    }
    tag_list = (ClientData *) ZnListArray(item->tags);
    if (num > NUM_STATIC) {
      its = (ClientData *) ZnMalloc(num*sizeof(ClientData));
    }
  }

  ptr = 0;

  BIND_ITEM(event->type != LeaveNotify);
  
  if (bind_part) {
    /*
     * Add here a binding for each tag suffixed by :part
     */
    for (i = 0; i < num_tags; i++) {
      len = strlen(tag_list[i])+ TCL_INTEGER_SPACE;
      if (worksize < len) {
        worksize = len + 10;
        workspace = ZnRealloc(workspace, len);
      }
      sprintf(workspace, "%s:%d", (char *) tag_list[i], part);
      its[ptr] = (ClientData) Tk_GetUid(workspace);
      ptr++;
    }
    /*
     * Add here a binding for id:part
     */
    its[ptr] = EncodeItemPart(item, part);
    ptr++;
  }
  
  BIND_ITEM(event->type == LeaveNotify);

  /*
   * Invoke the binding system.
   */
  Tk_BindEvent(wi->binding_table, event, wi->win, (int) num, its);
  if (its != items) {
    ZnFree(its);
  }

#undef BIND_ITEM
}


/*
 *----------------------------------------------------------------------
 *
 * PickCurrentItem --
 *
 *      Finds the topmost item/field that contains the pointer and mark
 *      it has the current item. Generates Enter/leave events on the
 *      old and new current items/fields has necessary.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The current item/field may change.  If it does,
 *      then the commands associated with item entry and exit
 *      could do just about anything.  A binding script could
 *      delete the widget, so callers should protect themselves
 *      with Tcl_Preserve and Tcl_Release.
 *
 * Note:
 *      See the Bind function's note.
 *
 *----------------------------------------------------------------------
 */
static void
PickCurrentItem(ZnWInfo *wi,
                XEvent  *event)
{
  int    button_down;
  ZnBool enter_item;
  ZnBool grab_release = False;

  /*printf("PickCurrent current=%d, new=%d\n",
         wi->current_item?wi->current_item->id:0,
         wi->new_item?wi->new_item->id:0);*/
  /*
   * Check whether or not a button is down.  If so, we'll log entry
   * and exit into and out of the current item, but not entry into
   * any other item.  This implements a form of grabbing equivalent
   * to what the X server does for windows.
   */
  button_down = wi->state
    & (Button1Mask|Button2Mask|Button3Mask|Button4Mask|Button5Mask);
  if (!button_down) {
    grab_release = ISSET(wi->flags, ZN_GRABBED_ITEM);
    CLEAR(wi->flags, ZN_GRABBED_ITEM);
    CLEAR(wi->flags, ZN_GRABBED_PART);
  }
  
  /*
   * Save information about this event in the widget.  The saved event
   * is used for two purposes:
   *
   * 1. Event bindings: if the current item changes, fake events are
   *    generated to allow item-enter and item-leave bindings to trigger.
   * 2. Reselection: if the current item gets deleted, can use the
   *    saved event to find a new current item.
   * Translate MotionNotify events into EnterNotify events, since that's
   * what gets reported to item handlers.
   */
  if (event != &wi->pick_event) {
    if ((event->type == MotionNotify) || (event->type == ButtonRelease)) {
      wi->pick_event.xcrossing.type = EnterNotify;
      wi->pick_event.xcrossing.serial = event->xmotion.serial;
      wi->pick_event.xcrossing.send_event = event->xmotion.send_event;
      wi->pick_event.xcrossing.display = event->xmotion.display;
      wi->pick_event.xcrossing.window = event->xmotion.window;
      wi->pick_event.xcrossing.root = event->xmotion.root;
      wi->pick_event.xcrossing.subwindow = None;
      wi->pick_event.xcrossing.time = event->xmotion.time;
      wi->pick_event.xcrossing.x = event->xmotion.x;
      wi->pick_event.xcrossing.y = event->xmotion.y;
      wi->pick_event.xcrossing.x_root = event->xmotion.x_root;
      wi->pick_event.xcrossing.y_root = event->xmotion.y_root;
      wi->pick_event.xcrossing.mode = NotifyNormal;
      wi->pick_event.xcrossing.detail = NotifyNonlinear;
      wi->pick_event.xcrossing.same_screen = event->xmotion.same_screen;
      wi->pick_event.xcrossing.focus = False;
      wi->pick_event.xcrossing.state = event->xmotion.state;
    }
    else {
      wi->pick_event = *event;
    }
  }

  /*
   * If this is a recursive call (there's already a partially completed
   * call pending on the stack;  it's in the middle of processing a
   * Leave event handler for the old current item) then just return;
   * the pending call will do everything that's needed.
   */
  if (ISSET(wi->flags, ZN_REPICK_IN_PROGRESS)) {
    fprintf(stderr, "PickCurrentItem recursive\n");
    return;
  }

  /*
   * A LeaveNotify event automatically means that there's no current
   * object, so the check for closest item can be skipped.
   */
  if (wi->pick_event.type != LeaveNotify) {
    ZnPickStruct ps;
    ZnReal       dist;
    ZnPoint      p;
    
    p.x = wi->pick_event.xcrossing.x;
    p.y = wi->pick_event.xcrossing.y;
    ps.point = &p;
    ps.in_group = ZN_NO_ITEM;
    ps.start_item = ZN_NO_ITEM;
    ps.aperture = wi->pick_aperture;
    ps.recursive = True;
    ps.override_atomic = False;
    dist = wi->top_group->class->Pick(wi->top_group, &ps);
    if (dist == 0.0) {
      wi->new_item = ps.a_item;
      wi->new_part = ps.a_part;
    }
    else {
      wi->new_item = ZN_NO_ITEM;
      wi->new_part = ZN_NO_PART;
    }
  }
  else {
    wi->new_item = ZN_NO_ITEM;
    wi->new_part = ZN_NO_PART;
  }
  /*
   * This state is needed to do a valid detection
   * of Enter during a grab.
   */
  enter_item = ((wi->new_item != wi->current_item) || ISSET(wi->flags, ZN_GRABBED_ITEM));

  /*printf("------ PickCurrentItem current: %d %d, new %d %d\n",
         wi->current_item==ZN_NO_ITEM?0:wi->current_item->id, wi->current_part,
         wi->new_item==ZN_NO_ITEM?0:wi->new_item->id, wi->new_part);*/

  if ((wi->new_item == wi->current_item) &&
      (wi->new_part == wi->current_part) &&
      ISCLEAR(wi->flags, ZN_GRABBED_ITEM) &&
      ISCLEAR(wi->flags, ZN_GRABBED_PART)) {
    /*
     * Nothing to do: the current item/part hasn't changed.
     */
    return;
  }

  /*
   * Simulate a LeaveNotify event on the previous current item.
   * Remove the "current" tag from the previous current item.
   */
  if ((wi->current_item != ZN_NO_ITEM) &&
      (((wi->new_item != wi->current_item) || (wi->new_part != wi->current_part)) &&
       ISCLEAR(wi->flags, ZN_GRABBED_ITEM))) {
      ZnItem item = wi->current_item;
    /*
     * Actually emit the event only if not releasing a grab
     * on button up.
     */
    if (!grab_release) {
      XEvent event;
      event = wi->pick_event;
      event.type = LeaveNotify;
      
      /*printf("== LEAVE %d %d ==\n", wi->current_item->id, wi->current_part);*/
      /*
       * If the event's detail happens to be NotifyInferior the
       * binding mechanism will discard the event.  To be consistent,
       * always use NotifyAncestor.
       */
      event.xcrossing.detail = NotifyAncestor;
      SET(wi->flags, ZN_REPICK_IN_PROGRESS);
      DoEvent(wi, &event,
              wi->new_item != wi->current_item, ISCLEAR(wi->flags, ZN_GRABBED_PART));
      CLEAR(wi->flags, ZN_REPICK_IN_PROGRESS);
    }
    
    /*
     * In all cases, if a grab is not current, remove the current tag.
     *
     * The check on item below is needed because there could be an
     * event handler for <LeaveNotify> that deletes the current item.
     */
    if ((item == wi->current_item) && !button_down) {
      /*printf("^^^ Removing 'current' from %d\n", wi->current_item->id);*/
      ZnITEM.RemoveTag(item, current_uid);
    }    
    /*
     * Note:  during DoEvent above, it's possible that
     * wi->new_item got reset to NULL because the
     * item was deleted.
     */
  }

  /*
   * Special note:  it's possible that wi->new_item == wi->current_item
   * here. This can happen, for example, if a grab was set or
   * if there is only a change in the part number.
   */
  if ((wi->new_item != wi->current_item) && button_down) {
    SET(wi->flags, ZN_GRABBED_ITEM);
  }
  else {
    if (button_down) {
      grab_release = ISSET(wi->flags, ZN_GRABBED_ITEM);
    }
    CLEAR(wi->flags, ZN_GRABBED_ITEM);
    wi->current_item = wi->new_item;
  }
  if ((wi->new_part != wi->current_part) && button_down) {
    SET(wi->flags, ZN_GRABBED_PART);
  }
  else {
    CLEAR(wi->flags, ZN_GRABBED_PART);
    wi->current_part = wi->new_part;
  }
  
  if (!grab_release &&
      (ISSET(wi->flags, ZN_GRABBED_PART) || ISSET(wi->flags, ZN_GRABBED_ITEM))) {
    return;
  }
  
  if (wi->current_item != ZN_NO_ITEM) {
    XEvent event;
    /*
     * Add the tag 'current' to the current item under the pointer.
     */
    /*printf("Adding 'current' to %d\n", wi->current_item->id);*/
    ZnDoItem((Tcl_Interp *) NULL, wi->current_item, ZN_NO_PART, current_uid);
    /*
     * Then emit a fake Enter event on it.
     */
    /*printf("== ENTER %d %d ==\n",wi->current_item->id, wi->current_part);*/
    event = wi->pick_event;
    event.type = EnterNotify;
    event.xcrossing.detail = NotifyAncestor;
    DoEvent(wi, &event,
            enter_item, !(grab_release && ISSET(wi->flags, ZN_GRABBED_PART)));
  }
}


/*
 *----------------------------------------------------------------------
 *
 * Bind --
 *
 *      This procedure is invoked by the Tk dispatcher to handle
 *      events associated with bindings on items.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Depends on the command invoked as part of the binding
 *      (if there was any).
 *
 * Note:
 *      This has been taken as is from the Tk canvas. It might not
 *      not be fully adequate for the purpose. But at least this
 *      provides two benefits: a/ It is believe to be correct and
 *      b/ users are accustomed to its behavior.
 *
 *----------------------------------------------------------------------
 */
static void
Bind(ClientData client_data,    /* Information about widget. */
     XEvent     *event)         /* Information about event. */
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  
  Tcl_Preserve((ClientData) wi);

  /*
   * This code below keeps track of the current modifier state in
   * wi->state.  This information is used to defer repicks of
   * the current item while buttons are down.
   */
  if ((event->type == ButtonPress) || (event->type == ButtonRelease)) {
    int mask;
    
    switch (event->xbutton.button) {
    case Button1:
      mask = Button1Mask;
      break;
    case Button2:
      mask = Button2Mask;
      break;
    case Button3:
      mask = Button3Mask;
      break;
    case Button4:
      mask = Button4Mask;
      break;
    case Button5:
      mask = Button5Mask;
      break;
    default:
      mask = 0;
      break;
    }    
    /*
     * For button press events, repick the current item using the
     * button state before the event, then process the event.  For
     * button release events, first process the event, then repick
     * the current item using the button state *after* the event
     * (the button has logically gone up before we change the
     * current item).
     */
    
    if (event->type == ButtonPress) {
      /*
       * On a button press, first repick the current item using
       * the button state before the event, then process the event.
       */      
      wi->state = event->xbutton.state;
      PickCurrentItem(wi, event);
      wi->state ^= mask;
      if (wi->current_item != ZN_NO_ITEM) {
        DoEvent(wi, event, True, True);
      }
    }
    else {
      /*
       * Button release: first process the event, with the button
       * still considered to be down.  Then repick the current
       * item under the assumption that the button is no longer down.
       */
      wi->state = event->xbutton.state;
      DoEvent(wi, event, True, True);
      event->xbutton.state ^= mask;
      wi->state = event->xbutton.state;
      PickCurrentItem(wi, event);
      event->xbutton.state ^= mask;
    }
    goto done;
  }
  
  else if ((event->type == EnterNotify) || (event->type == LeaveNotify)) {
    wi->state = event->xcrossing.state;
    PickCurrentItem(wi, event);
    goto done;
  }
  
  else if (event->type == MotionNotify) {
    wi->state = event->xmotion.state;
    if (wi->follow_pointer) {
      PickCurrentItem(wi, event);
    }
    else {
      /* Copy the event for later processing
       * and skip the picking phase.
       */
      wi->pick_event = *event;
    }
  }

  DoEvent(wi, event, True, True);
  
done:
  Tcl_Release((ClientData) wi);
}


/*
 *----------------------------------------------------------------------
 *
 * LostSelection --
 *
 *      This procedure is called back by Tk when the selection is
 *      grabbed away from a zinc widget.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The existing selection is unhighlighted, and the window is
 *      marked as not containing a selection.
 *
 *----------------------------------------------------------------------
 */
static void
LostSelection(ClientData        client_data)
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  ZnTextInfo    *ti = &wi->text_info;
  
  if (ti->sel_item != ZN_NO_ITEM) {
    ZnITEM.Invalidate(ti->sel_item, ZN_DRAW_FLAG);
  }
  ti->sel_item = ZN_NO_ITEM;
  ti->sel_field = ZN_NO_PART;
}


/*
 *----------------------------------------------------------------------
 *
 * SelectTo --
 *
 *      Modify the selection by moving its un-anchored end.  This could
 *      make the selection either larger or smaller.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The selection changes.
 *
 *----------------------------------------------------------------------
 */
static void
SelectTo(ZnItem item,
         int    field,
         int    index)
{
  ZnWInfo       *wi = item->wi;
  ZnTextInfo    *ti = &wi->text_info;
  int           old_first, old_last, old_field;
  ZnItem        old_sel_item;

  old_first = ti->sel_first;
  old_last = ti->sel_last;
  old_sel_item = ti->sel_item;
  old_field = ti->sel_field;
  
  /*
   * Grab the selection if we don't own it already.
   */
  if (ti->sel_item == ZN_NO_ITEM) {
    Tk_OwnSelection(wi->win, XA_PRIMARY, LostSelection, (ClientData) wi);
  }
  else if ((ti->sel_item != item) || (ti->sel_field != field)) {
    ZnITEM.Invalidate(ti->sel_item, ZN_DRAW_FLAG);
  }
  ti->sel_item = item;
  ti->sel_field = field;
  
  if ((ti->anchor_item != item) || (ti->anchor_field) != field) {
    ti->anchor_item = item;
    ti->anchor_field = field;
    ti->sel_anchor = index;
  }
  if (ti->sel_anchor <= index) {
    ti->sel_first = ti->sel_anchor;
    ti->sel_last = index;
  }
  else {
    ti->sel_first = index;
    ti->sel_last = ti->sel_anchor;
  }
  if ((ti->sel_first != old_first) ||
      (ti->sel_last != old_last) ||
      (item != old_sel_item)) {
    ZnITEM.Invalidate(item, ZN_DRAW_FLAG);
  }
}


/*
 *--------------------------------------------------------------
 *
 * FetchSelection --
 *
 *      This procedure is invoked by Tk to return part or all of
 *      the selection, when the selection is in a zinc widget.
 *      This procedure always returns the selection as a STRING.
 *
 * Results:
 *      The return value is the number of non-NULL bytes stored
 *      at buffer.  Buffer is filled (or partially filled) with a
 *      NULL-terminated string containing part or all of the selection,
 *      as given by offset and maxBytes.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
static int
FetchSelection( ClientData      client_data,
                int             offset,         /* Offset within selection of first
                                                 * character to be returned. */
                char            *buffer,        /* Location in which to place
                                                 * selection. */
                int             max_bytes)      /* Maximum number of bytes to place
                                                 * at buffer, not including terminating
                                                 * NULL character. */
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  ZnTextInfo    *ti = &wi->text_info;
  
  if (ti->sel_item == ZN_NO_ITEM) {
    return -1;
  }
  if (ti->sel_item->class->Selection == NULL) {
    return -1;
  }
  return (*ti->sel_item->class->Selection)(ti->sel_item, ti->sel_field,
                                           offset, buffer, max_bytes);
}


/*
 *----------------------------------------------------------------------
 *
 * CmdDeleted --
 *
 *      This procedure is invoked when a widget command is deleted. If
 *      the widget isn't already in the process of being destroyed,
 *      this command destroys it.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      The widget is destroyed.
 *
 *----------------------------------------------------------------------
 */
static void
CmdDeleted(ClientData client_data) /* Pointer to widget record for widget. */
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;

  if (wi->win != NULL) {
    Tk_DestroyWindow(wi->win);
  }
}


/*
 *----------------------------------------------------------------------
 *
 * Destroy --
 *
 *      This procedure is invoked by Tk_EventuallyFree or Tk_Release
 *      to clean up the internal structure of the widget at a safe time
 *      (when no-one is using it anymore).
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Everything associated with the widget is freed up.
 *
 *----------------------------------------------------------------------
 */
static void
Destroy(ZnWInfo *wi)
{
  unsigned int  num;
  Tcl_HashSearch search;
  Tcl_HashEntry *entry;
#ifdef GL
  unsigned int  i;
  ZnGLContextEntry *ce;
  ZnWInfo       **wip;
#endif

  //printf("Destroy begining\n");
  /*
   * This procedure could be invoked either because the window was
   * destroyed and the command was then deleted (in which case win
   * is NULL) or because the command was deleted, and then this procedure
   * destroys the widget.
   */
  CLEAR(wi->flags, ZN_REALIZED);
#ifdef PTK
  Lang_DeleteWidget(wi->interp, wi->cmd);
#else 
  Tcl_DeleteCommandFromToken(wi->interp, wi->cmd);
#endif
  /*
   * Remove the redisplay scheduled by the cleanup.
   * It will fire when the widget will be gone and
   * will corrupt memory.
   */
  if (ISSET(wi->flags, ZN_UPDATE_PENDING)) {
    Tcl_CancelIdleCall(Redisplay, (ClientData) wi);
  }
  /*
   * Unregister form the overlap manager.
   */
#ifdef ATC
  if (wi->om_group != ZN_NO_ITEM) {
    OmUnregister((void *) wi);
  }
#endif

  /*
   * Print remaining items.
   */
  
  /* Free all items. */
  /*fprintf(stderr, "Item count before cleanup: %d\n", wi->num_items);*/
  ZnITEM.DestroyItem(wi->top_group);
  /*fprintf(stderr, "Remaining item count: %d\n", wi->num_items);*/

  for (num = 0; num < ZN_NUM_ALPHA_STEPS; num++) {
    if (wi->alpha_stipples[num] != None) {
      Tk_FreeBitmap(wi->dpy, wi->alpha_stipples[num]);
      wi->alpha_stipples[num] = None;
    }
  }

  Tcl_DeleteHashTable(wi->id_table);
  ZnFree(wi->id_table);

  /*
   * Free the transform table contents.
   */
  entry = Tcl_FirstHashEntry(wi->t_table, &search);
  while (entry != NULL) {
    ZnTransfoFree((ZnTransfo *) Tcl_GetHashValue(entry));
    entry = Tcl_NextHashEntry(&search);
  }
  Tcl_DeleteHashTable(wi->t_table);
  ZnFree(wi->t_table);

  if (wi->binding_table != NULL) {
    Tk_DeleteBindingTable(wi->binding_table);
  }

  /* Free the tile */
  if (wi->tile != ZnUnspecifiedImage) {
#ifdef PTK_800
    ZnFreeImage(wi->tile, ZnImageUpdate, wi);
#else
    ZnFreeImage(wi->tile, TileUpdate, wi);
#endif
    wi->tile = ZnUnspecifiedImage;
  }

#ifdef ATC
  /* Free the symbols */
  if (wi->map_distance_symbol != ZnUnspecifiedImage) {
    ZnFreeImage(wi->map_distance_symbol, NULL, NULL);
    wi->map_distance_symbol = ZnUnspecifiedImage;
  }
  if (wi->track_symbol != ZnUnspecifiedImage) {
    ZnFreeImage(wi->track_symbol, NULL, NULL);
    wi->track_symbol = ZnUnspecifiedImage;
  }
#endif

  /* Free the double buffer pixmap/image */
  if (wi->draw_buffer) {
    Tk_FreePixmap(wi->dpy, wi->draw_buffer);
    wi->draw_buffer = 0;
  }

#ifdef PTK_800
  if (wi->fore_color) {
    ZnFreeGradient(wi->fore_color);
    wi->fore_color = NULL;
  }
  if (wi->back_color) {
    ZnFreeGradient(wi->back_color);
    wi->back_color = NULL;
  }
#endif
  if (wi->relief_grad) {
    ZnFreeGradient(wi->relief_grad);
    wi->relief_grad = NULL;
  }
  if (wi->gc) {
    XFreeGC(wi->dpy, wi->gc);
    wi->gc = 0;
  }

  Tcl_DeleteTimerHandler(wi->blink_handler);

#ifdef PTK_800
  Tk_FreeOptions(config_specs, (char *) wi, wi->dpy, 0);
#else
  Tk_FreeConfigOptions((char *) wi, wi->opt_table, wi->win);
#endif

#ifdef GL
  if (wi->font_tfi) {
    ZnFreeTexFont(wi->font_tfi);
    wi->font_tfi = NULL;
  }
#ifdef ATC
  if (wi->map_font_tfi) {
    ZnFreeTexFont(wi->map_font_tfi);
    wi->map_font_tfi = NULL;
  }
#endif
  /*
   * Remove the widget from the context list and
   * free the context if no more widgets are active.
   */
  ce = ZnGetGLContext(wi->dpy);
  if (ce) {
    wip = ZnListArray(ce->widgets);
    num = ZnListSize(ce->widgets);
    for (i = 0; i < num; i++, wip++) {
      if (*wip == wi) {
        ZnListDelete(ce->widgets, i);
      }
    }
    /*
     * This code cause spurious X11 server reboots
     * with nvidia drivers (not tested with others
     * though). Thus it has been limited to WIN for
     * the time being.
     */
#if 1 /*def _WIN32*/
    if (ZnListSize(ce->widgets) == 0) {
      ZnGLContextEntry *prev, *next;
      /*printf("Freeing a GL context\n");*/
      if (ce == gl_contexts) {
        gl_contexts = ce->next;
      }
      else {
        for (prev = gl_contexts, next = gl_contexts->next; next;
             prev = next, next = next->next) {
          if (next == ce) {
            prev->next = next->next;
            break;
          }
        }
      }
#ifdef _WIN32
      ZnGLReleaseContext(ce);
      wglDeleteContext(ce->context);
#else
      glXDestroyContext(ce->dpy, ce->context);
      /*
       * This call seems to be a problem for X11/Mesa
       */
      /*XFreeColormap(ce->dpy, ce->colormap);*/
      XFree(ce->visual);
#endif
      ZnListFree(ce->widgets);
      ZnFree(ce);
    }
#endif
  }
#endif
  /*
  if (wi->font) {
    Tk_FreeFont(wi->font);
  }
  if (wi->map_text_font) {
    Tk_FreeFont(wi->map_text_font);
  }*/
  
  /*
   * Should be empty by now.
   */
  ZnFreeTransformStack(wi);
  ZnFreeClipStack(wi);

#ifndef _WIN32
  ZnFreeChrono(wi->total_draw_chrono);
  ZnFreeChrono(wi->this_draw_chrono);
#endif

  wi->win = NULL;
  Tcl_EventuallyFree((ClientData) wi, TCL_DYNAMIC);
  /*printf("Destroy ending\n");*/
}


/*
 **********************************************************************************
 *
 * ZnDamage --
 *
 **********************************************************************************
 */
void
ZnDamage(ZnWInfo        *wi,
         ZnBBox         *damage)
{
  if ((damage == NULL) || ZnIsEmptyBBox(damage)) {
    return;
  }
  
  /*printf("damaging area: %g %g %g %g\n", damage->orig.x,
    damage->orig.y, damage->corner.x, damage->corner.y);*/

  if (ZnIsEmptyBBox(&wi->damaged_area)) {
    wi->damaged_area.orig.x = damage->orig.x;
    wi->damaged_area.orig.y = damage->orig.y;
    wi->damaged_area.corner.x = damage->corner.x;
    wi->damaged_area.corner.y = damage->corner.y;
    ZnNeedRedisplay(wi);
  }
  else {
    wi->damaged_area.orig.x = MIN(wi->damaged_area.orig.x, damage->orig.x);
    wi->damaged_area.orig.y = MIN(wi->damaged_area.orig.y, damage->orig.y);
    wi->damaged_area.corner.x = MAX(wi->damaged_area.corner.x, damage->corner.x);
    wi->damaged_area.corner.y = MAX(wi->damaged_area.corner.y, damage->corner.y);
  }
  /*printf("damaged area: %g %g %g %g\n", wi->damaged_area.orig.x,
         wi->damaged_area.orig.y, wi->damaged_area.corner.x,
         wi->damaged_area.corner.y);*/
}

void
ZnDamageAll(ZnWInfo *wi)
{
  ZnBBox bbox;

  bbox.orig.x = bbox.orig.y = 0;
  bbox.corner.x = Tk_Width(wi->win);
  bbox.corner.y = Tk_Height(wi->win);
  ZnDamage(wi, &bbox);
}

static void
ClampDamageArea(ZnWInfo *wi)
{
  int   width, height;

  if (wi->damaged_area.orig.x < wi->inset) {
    wi->damaged_area.orig.x = wi->inset;
  }
  if (wi->damaged_area.orig.y < wi->inset) {
    wi->damaged_area.orig.y = wi->inset;
  }
  if (wi->damaged_area.corner.x < wi->inset) {
    wi->damaged_area.corner.x = wi->inset;
  }
  if (wi->damaged_area.corner.y < wi->inset) {
    wi->damaged_area.corner.y = wi->inset;
  }
  width = wi->width - wi->inset;
  height = wi->height - wi->inset;
  if (wi->damaged_area.orig.x > width) {
    wi->damaged_area.orig.x = width;
  }
  if (wi->damaged_area.orig.y > height) {
    wi->damaged_area.orig.y = height;
  }
  if (wi->damaged_area.corner.x > width) {
    wi->damaged_area.corner.x = width;
  }
  if (wi->damaged_area.corner.y > height) {
    wi->damaged_area.corner.y = height;
  }
}


/*
 **********************************************************************************
 *
 * Update --
 *
 **********************************************************************************
 */
static void
Update(ZnWInfo  *wi)
{
  /*
   * Give the overlap manager a chance to do its work.
   */
#ifdef ATC
  if ((wi->om_group != ZN_NO_ITEM) && ZnGroupCallOm(wi->om_group)) {  
    ZnPoint scale={1.0,1.0};
    if (wi->om_group->transfo) {
      ZnTransfoDecompose(wi->om_group->transfo, &scale,
                            NULL, NULL, NULL);
    }
    OmProcessOverlap((void *) wi, wi->width, wi->height, scale.x);
    ZnGroupSetCallOm(wi->om_group, False);
  }
#endif
  if (ISSET(wi->top_group->inv_flags, ZN_COORDS_FLAG) ||
      ISSET(wi->top_group->inv_flags, ZN_TRANSFO_FLAG)) {
    wi->top_group->class->ComputeCoordinates(wi->top_group, False);
  }
}


/*
 **********************************************************************************
 *
 * Repair --
 *
 **********************************************************************************
 */
#if defined (_WIN32)
#define START \
  QueryPerformanceCounter(&start)

#define STOP_PRINT(text) \
    QueryPerformanceCounter(&stop); \
    printf(text##" : %g ms\n", \
           ((double) (stop.QuadPart - start.QuadPart)) * 1000.0 / ((double) sw_freq.QuadPart))
#endif

static void
Repair(ZnWInfo  *wi)
{
  XGCValues     values;
  ZnPoint       p[5];
  ZnTriStrip    tristrip;
#ifdef GL
  XColor        *color;
  int           darea_x1, darea_x2, darea_y1, darea_y2;
  ZnGLContextEntry *ce;
#endif
  int           int_width = Tk_Width(wi->win);
  int           int_height = Tk_Height(wi->win);
  //LARGE_INTEGER start, stop, sw_freq;
  
  //QueryPerformanceFrequency(&sw_freq);
  //START;
  /*SET(wi->flags, ZN_CONFIGURE_EVENT);*/
  if (wi->render) {
#ifdef GL
    /* Load deferred font glyphs just before making the context
     * current. Mandatory under Windows (probably due to hdc use conflict).
     */
    ZnGetDeferredGLGlyphs();

    ZnGLWaitX();
#ifdef GL_DAMAGE
    if (ISCLEAR(wi->flags, ZN_CONFIGURE_EVENT)) {
      ClampDamageArea(wi);
      /*
       * Merge the exposed area.
       */
      ZnAddBBoxToBBox(&wi->damaged_area, &wi->exposed_area);
      if (ZnIsEmptyBBox(&wi->damaged_area)) {
        return;
      }
    }
#endif

    /*printf("Repair, scissors: %d\n", ISCLEAR(wi->flags, ZN_CONFIGURE_EVENT));*/
    ce = ZnGLMakeCurrent(wi->dpy, wi);
    glEnable(GL_POINT_SMOOTH);
    glEnable(GL_LINE_SMOOTH);
#if 0
    glEnable(GL_POLYGON_SMOOTH);   /*  expensive ? */
#endif

    glEnable(GL_BLEND);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glClearStencil(0);    
    color = ZnGetGradientColor(wi->back_color, 0.0, NULL);
    glClearColor((GLfloat) color->red/65536, (GLfloat) color->green/65536,
                 (GLfloat) color->blue/65536, 0.0);
    glDrawBuffer(GL_BACK);

    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

    /*
     * Init the composite group alpha.
     */
    wi->alpha = 100;
    
#ifdef GL_DAMAGE
    if (ISCLEAR(wi->flags, ZN_CONFIGURE_EVENT)) {
      /*
       * Set the damaged area as the viewport area.
       */
      darea_x1 = (int) ZnNearestInt(wi->damaged_area.orig.x);
      darea_y1 = (int) ZnNearestInt(wi->damaged_area.orig.y);
      darea_x2 = (int) ZnNearestInt(wi->damaged_area.corner.x);
      darea_y2 = (int) ZnNearestInt(wi->damaged_area.corner.y);
    }
    else {
      darea_x1 = darea_y1 = wi->damaged_area.orig.x = wi->damaged_area.orig.y = 0;
      darea_x2 = wi->damaged_area.corner.x = int_width;
      darea_y2 = wi->damaged_area.corner.y = int_height;
    }
#else
    /*
     * We do not use the damaged area set it to the whole area.
     */
    darea_x1 = darea_y1 = wi->damaged_area.orig.x = wi->damaged_area.orig.y = 0;
    darea_x2 = wi->damaged_area.corner.x = int_width;
    darea_y2 = wi->damaged_area.corner.y = int_height;
#endif
    //
    // glViewport and glOrtho must always be used together with
    // matching parameters to keep the mapping straight (no distorsion).
    glViewport(darea_x1, int_height - darea_y2, darea_x2 - darea_x1, darea_y2 - darea_y1);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(darea_x1, darea_x2, darea_y2, darea_y1, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);

    /*
     * Clear the GL buffers.
     */
    glClear(GL_STENCIL_BUFFER_BIT);

    /*
     * Setup the background tile or the background color.
     */
    if (wi->tile != ZnUnspecifiedImage) {
      ZnBBox bbox;
      
      bbox.orig.x = bbox.orig.y = 0.0;
      bbox.corner.x = int_width;
      bbox.corner.y = int_height;
      ZnRenderTile(wi, wi->tile, NULL, NULL, NULL, (ZnPoint *) &bbox);
    }
    else {
      color = ZnGetGradientColor(wi->back_color, 0.0, NULL);
      glColor4us(color->red, color->green, color->blue, 65535);
      glBegin(GL_QUAD_STRIP);
      glVertex2d(wi->damaged_area.orig.x, wi->damaged_area.orig.y);
      glVertex2d(wi->damaged_area.orig.x, wi->damaged_area.corner.y);
      glVertex2d(wi->damaged_area.corner.x, wi->damaged_area.orig.y);
      glVertex2d(wi->damaged_area.corner.x, wi->damaged_area.corner.y);
      glEnd();
    }

    wi->top_group->class->Render(wi->top_group);

    if ((wi->border_width > 0) || (wi->highlight_width > 0)) {
      unsigned short alpha;

#ifdef GL_DAMAGE
      glViewport(0, 0, int_width, int_height);
      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
      glOrtho(0.0, int_width, int_height, 0.0, -1.0, 1.0);
      glMatrixMode(GL_MODELVIEW);
#endif
      if (wi->highlight_width > 0) {
        color = ZnGetGradientColor(ISSET(wi->flags, ZN_GOT_FOCUS)?wi->highlight_color:
                                   wi->highlight_bg_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, 100);
        glColor4us(color->red, color->green, color->blue, alpha);
        
        glBegin(GL_QUAD_STRIP);
        glVertex2d(0.0, 0.0);
        glVertex2i(wi->highlight_width, wi->highlight_width);
        glVertex2i(int_width, 0);
        glVertex2i(int_width - wi->highlight_width, wi->highlight_width);
        glVertex2i(int_width, int_height);
        glVertex2i(int_width - wi->highlight_width, int_height - wi->highlight_width);
        glVertex2i(0, int_height);
        glVertex2i(wi->highlight_width, int_height - wi->highlight_width);
        glVertex2i(0, 0);
        glVertex2i(wi->highlight_width, wi->highlight_width);
        glEnd();
      }
      if (wi->border_width > 0) {
        if (wi->relief != ZN_RELIEF_FLAT) {
          p[4].x = p[4].y = p[3].y = p[1].x = wi->highlight_width;
          p[0] = p[4];
          p[3].x = p[2].x = int_width - wi->highlight_width;
          p[2].y = p[1].y = int_height - wi->highlight_width;
          ZnRenderPolygonRelief(wi, wi->relief, wi->relief_grad,
                                False, p, 5, (ZnReal) wi->border_width);
        }
        else {
          color = ZnGetGradientColor(wi->back_color, 0.0, &alpha);
          alpha = ZnComposeAlpha(alpha, 100);
          glColor4us(color->red, color->green, color->blue, alpha);
          
          glBegin(GL_QUAD_STRIP);
          glVertex2d(0.0, 0.0);
          glVertex2i(wi->highlight_width, wi->highlight_width);
          glVertex2i(int_width, 0);
          glVertex2i(int_width - wi->highlight_width, wi->highlight_width);
          glVertex2i(int_width, int_height);
          glVertex2i(int_width - wi->highlight_width, int_height - wi->highlight_width);
          glVertex2i(0, int_height);
          glVertex2i(wi->highlight_width, int_height - wi->highlight_width);
          glVertex2i(0, 0);
          glVertex2i(wi->highlight_width, wi->highlight_width);
          glEnd();
        }
      }
    }
    CLEAR(wi->flags, ZN_CONFIGURE_EVENT);

    /* Switch the GL buffers. */
#if 0
    glDisable(GL_BLEND);
    glDisable(GL_STENCIL_TEST);
    glDrawBuffer(GL_FRONT);
    glReadBuffer(GL_BACK);
    glRasterPos2i(darea_x1, darea_y2);
    glCopyPixels(darea_x1, int_height-darea_y2, darea_x2 - darea_x1, darea_y2 - darea_y1,
                 GL_COLOR);
    glFlush();
#else
    ZnGLSwapBuffers(ce, wi);
#endif

    /*
     * Wait the end of GL update if we need to synchronize
     * to monitor perfs.
     */
    if (ISSET(wi->flags, ZN_MONITORING)) {
      ZnGLWaitGL();
    }

    ZnGLReleaseContext(ce);
    //STOP_PRINT("Total GL");
#endif
  }
  else {
    XRectangle  r, rs[4];
    ZnBBox      merge;

    //START;
    ClampDamageArea(wi);
    /*
m     * Merge the damaged area with the exposed area.
     */
    ZnResetBBox(&merge);
    ZnCopyBBox(&wi->damaged_area, &merge);
    ZnAddBBoxToBBox(&merge, &wi->exposed_area);
    if (!ZnIsEmptyBBox(&merge)) {
      
      /* Set the whole damaged area as clip rect. */
      wi->damaged_area.orig.x = r.x = ZnNearestInt(wi->damaged_area.orig.x);
      wi->damaged_area.orig.y = r.y = ZnNearestInt(wi->damaged_area.orig.y);
      wi->damaged_area.corner.x = ZnNearestInt(wi->damaged_area.corner.x);
      wi->damaged_area.corner.y = ZnNearestInt(wi->damaged_area.corner.y);
      r.width = (unsigned short) (wi->damaged_area.corner.x - wi->damaged_area.orig.x);
      r.height = (unsigned short) (wi->damaged_area.corner.y - wi->damaged_area.orig.y);
      p[0] = wi->damaged_area.orig;
      p[1] = wi->damaged_area.corner;
      ZnTriStrip1(&tristrip, p, 2, False);
      ZnPushClip(wi, &tristrip, True, True);
      
      /* Fill the background of the double buffer pixmap. */
      if (wi->tile == ZnUnspecifiedImage) {
        values.foreground = ZnGetGradientPixel(wi->back_color, 0.0);
        values.fill_style = FillSolid;
        XChangeGC(wi->dpy, wi->gc, GCFillStyle|GCForeground, &values);
      }
      else {
        values.fill_style = FillTiled;
        values.tile = ZnImagePixmap(wi->tile, wi->win);
        values.ts_x_origin = values.ts_y_origin = 0;
        XChangeGC(wi->dpy, wi->gc,
                  GCFillStyle|GCTile|GCTileStipXOrigin|GCTileStipYOrigin,
                  &values);
      }
      XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc, r.x, r.y, r.width, r.height);
      
      /* Draw the items */
      wi->top_group->class->Draw(wi->top_group);
      
      ZnPopClip(wi, True);
      
      /*
       * Send the merged area back to screen.
       */
      merge.orig.x = MAX(merge.orig.x, wi->inset);
      merge.orig.y = MAX(merge.orig.y, wi->inset);
      merge.corner.x = MIN(merge.corner.x, int_width-wi->inset);
      merge.corner.y = MIN(merge.corner.y, int_height-wi->inset);
      ZnBBox2XRect(&merge, &r);
      XCopyArea(wi->dpy,
                wi->draw_buffer, Tk_WindowId(wi->win), wi->gc,
                r.x, r.y, r.width, r.height, r.x, r.y);
    }
    
    /*
     * Redraw the borders.
     */
    if (wi->border_width > 0) {
      Pixmap      save;
      
      save = wi->draw_buffer;
      wi->draw_buffer = Tk_WindowId(wi->win);
      if (wi->relief_grad != ZN_RELIEF_FLAT) {
        r.x = r.y = wi->highlight_width;
        r.width = int_width - 2*wi->highlight_width;
        r.height = int_height - 2*wi->highlight_width;
        ZnDrawRectangleRelief(wi, wi->relief, wi->relief_grad, &r,
                              (ZnDim) wi->border_width);
      }
      else {
        XSetForeground(wi->dpy, wi->gc, ZnGetGradientPixel(wi->back_color, 0.0));
        XSetFillStyle(wi->dpy, wi->gc, FillSolid);
        rs[0].x = rs[0].y = wi->highlight_width;
        rs[0].width = int_width - 2*wi->highlight_width;
        rs[0].height = wi->border_width;
        rs[1].x = int_width - wi->highlight_width - wi->border_width;
        rs[1].y = 0;
        rs[1].width = wi->border_width;
        rs[1].height = int_height - 2*wi->highlight_width;
        rs[2].x = 0;
        rs[2].y = int_height - wi->highlight_width - wi->border_width;
        rs[2].width = rs[0].width;
        rs[2].height = wi->border_width;
        rs[3].x = rs[3].y = wi->highlight_width;
        rs[3].width = wi->border_width;
        rs[3].height = rs[1].height;
        XFillRectangles(wi->dpy, Tk_WindowId(wi->win), wi->gc, rs, 4);
      }
      wi->draw_buffer = save;
    }
    if (wi->highlight_width > 0) {
      XSetForeground(wi->dpy, wi->gc,
                     ZnGetGradientPixel(ISSET(wi->flags, ZN_GOT_FOCUS)?wi->highlight_color:
                                        wi->highlight_bg_color, 0.0));
      XSetFillStyle(wi->dpy, wi->gc, FillSolid);
      rs[0].x = rs[0].y = 0;
      rs[0].width = int_width;
      rs[0].height = wi->highlight_width;
      rs[1].x = int_width - wi->highlight_width;
      rs[1].y = 0;
      rs[1].width = wi->highlight_width;
      rs[1].height = int_height;
      rs[2].x = 0;
      rs[2].y = int_height - wi->highlight_width;
      rs[2].width = int_width;
      rs[2].height = wi->highlight_width;
      rs[3].x = rs[3].y = 0;
      rs[3].width = wi->highlight_width;
      rs[3].height = int_height;
      XFillRectangles(wi->dpy, Tk_WindowId(wi->win), wi->gc, rs, 4);
    }
    //STOP_PRINT("Total GDI");
  }
}


/*
 *----------------------------------------------------------------------
 *
 * Redisplay --
 *
 *      This procedure redraws the contents of a Zinc window.
 *      It is invoked as a do-when-idle handler, so it only runs
 *      when there's nothing else for the application to do.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Information appears on the screen.
 *
 *----------------------------------------------------------------------
 */

static void
Redisplay(ClientData client_data)       /* Information about the widget. */
{
  ZnWInfo       *wi = (ZnWInfo *) client_data;
  
  CLEAR(wi->flags, ZN_UPDATE_PENDING);
  if (ISCLEAR(wi->flags, ZN_REALIZED) || !Tk_IsMapped(wi->win)) {
    return;
  }

  if (ISSET(wi->flags, ZN_MONITORING)) {
#ifndef _WIN32
    ZnXStartChrono(wi->total_draw_chrono, wi->dpy, Tk_WindowId(wi->win));
    ZnResetChronos(wi->this_draw_chrono);
    ZnXStartChrono(wi->this_draw_chrono, wi->dpy, Tk_WindowId(wi->win));
#endif
  }
  
  do {
    /*
     * Update the items.
     */
    Update(wi);
    
    /*
     * Do enter/leave processing after the overlap manager
     * has finished with the items. Do it has many times
     * as needed, each round may trigger callbacks that
     * result in moved items and so forth. It can even
     * lead to the widget destruction, this is the reason
     * for Tcl_Preserve/Tcl_Release.
     */
    if (ISSET(wi->flags, ZN_INTERNAL_NEED_REPICK)) {
      Tk_Window tkwin;

      if (wi->follow_pointer) {
        Tcl_Preserve((ClientData) wi);
        CLEAR(wi->flags, ZN_INTERNAL_NEED_REPICK);
        PickCurrentItem(wi, &wi->pick_event);
        tkwin = wi->win;
        Tcl_Release((ClientData) wi);
        if (tkwin == NULL) {
          return;
        }
      }
      else if (ISCLEAR(wi->top_group->inv_flags, ZN_COORDS_FLAG) &&
               ISCLEAR(wi->top_group->inv_flags, ZN_TRANSFO_FLAG)) {
        /* Don't repick now but escape the loop if
         * the geometry is updated. */
        break;
      }
    }
  }
  while (ISSET(wi->top_group->inv_flags, ZN_COORDS_FLAG) ||
         ISSET(wi->top_group->inv_flags, ZN_TRANSFO_FLAG) ||
         ISSET(wi->flags, ZN_INTERNAL_NEED_REPICK));
  
  /*
   * Repair the scene where it is no longer up to date,
   * then send the merged area back to the screen.
   */
  Repair(wi);
  
  /*
   * Reset the exposed & damaged areas.
   */
  ZnResetBBox(&wi->exposed_area);
  ZnResetBBox(&wi->damaged_area);

  if (ISSET(wi->flags, ZN_MONITORING)) {
#ifndef _WIN32
    ZnXStopChrono(wi->total_draw_chrono, wi->dpy, Tk_WindowId(wi->win));
    ZnXStopChrono(wi->this_draw_chrono, wi->dpy, Tk_WindowId(wi->win));
#endif
  }

  if (ISSET(wi->flags, ZN_UPDATE_SCROLLBARS)) {
    UpdateScrollbars(wi);
  }
}

#ifndef _WIN32
#define CALLBACK
#endif

static void CALLBACK
ZnTessBegin(GLenum      type,
            void        *data)
{
  ZnPoly        *outlines = data;
  ZnTriStrip    *tristrips = data;

  ZnListEmpty(ZnWorkPoints);
  ZnTesselator.type = type;
  if (type == GL_LINE_LOOP) {
    outlines->num_contours++;
    outlines->contours = ZnRealloc(outlines->contours,
                                   outlines->num_contours * sizeof(ZnContour));
  }
  else {
    tristrips->num_strips++;
    tristrips->strips = ZnRealloc(tristrips->strips,
                                  tristrips->num_strips * sizeof(ZnStrip));
    tristrips->strips[tristrips->num_strips-1].fan = (type==GL_TRIANGLE_FAN);
  }
  //printf("Début de fragment de type: %s\n",
         //(type == GL_TRIANGLE_FAN) ? "FAN" : 
         //(type == GL_TRIANGLE_STRIP) ? "STRIP" :
         //(type == GL_TRIANGLES) ? "TRIANGLES" :
         //(type == GL_LINE_LOOP) ? "LINE LOOP" : "");
}

static void CALLBACK
ZnTessVertex(void       *vertex_data,
             void       *data)
{
  ZnTriStrip    *tristrips = data;
  ZnPoint       p;
  int           size;

  p.x = ((GLdouble *) vertex_data)[0];
  p.y = ((GLdouble *) vertex_data)[1];
  //printf("Sommet en %g %g\n", p.x, p.y);
  size = ZnListSize(ZnWorkPoints);
  if ((ZnTesselator.type == GL_TRIANGLES) && (size == 3)) {
    tristrips->strips[tristrips->num_strips-1].num_points = size;
    tristrips->strips[tristrips->num_strips-1].points = ZnMalloc(size * sizeof(ZnPoint));
    memcpy(tristrips->strips[tristrips->num_strips-1].points,
           ZnListArray(ZnWorkPoints), size * sizeof(ZnPoint));
    //printf("Fin de fragment intermediaire %d, num points: %d\n", tristrips->num_strips-1, size);
    /* Allocate a new fragment */
    ZnListEmpty(ZnWorkPoints);
    tristrips->num_strips++;
    tristrips->strips = ZnRealloc(tristrips->strips,
                                    tristrips->num_strips * sizeof(ZnStrip));
    tristrips->strips[tristrips->num_strips-1].fan = False;
  }
  ZnListAdd(ZnWorkPoints, &p, ZnListTail);
}

static void CALLBACK
ZnTessEnd(void  *data)
{
  ZnPoly        *outlines = data;
  ZnTriStrip    *tristrips = data;
  unsigned int  size = ZnListSize(ZnWorkPoints);
  unsigned int  num;

  if (ZnTesselator.type == GL_LINE_LOOP) {
    /* Add the last point to close the outline */
    size++;
    num = outlines->num_contours;
    outlines->contours[num-1].num_points = size;
    outlines->contours[num-1].points = ZnMalloc(size * sizeof(ZnPoint));
    memcpy(outlines->contours[num-1].points,
           ZnListArray(ZnWorkPoints), size * sizeof(ZnPoint));
    outlines->contours[num-1].points[size-1] = outlines->contours[num-1].points[0];
    outlines->contours[num-1].cw = !ZnTestCCW(outlines->contours[num-1].points, size);
  }
  else {
    num = tristrips->num_strips;
    tristrips->strips[num-1].num_points = size;
    tristrips->strips[num-1].points = ZnMalloc(size * sizeof(ZnPoint));
    memcpy(tristrips->strips[num-1].points,
           ZnListArray(ZnWorkPoints), size * sizeof(ZnPoint));
  }
  //printf("Fin de fragment %d, num points: %d\n", num, size);
}

static void CALLBACK
ZnTessCombine(GLdouble  coords[3],
              void      *vertex_data[4],
              GLfloat   weight[4],
              void      **out_data,
              void      *data)
{
  ZnCombineData *cdata;
  
  cdata = ZnMalloc(sizeof(ZnCombineData));
  cdata->v[0] = coords[0];
  cdata->v[1] = coords[1];
  cdata->next = ZnTesselator.combine_list;
  ZnTesselator.combine_list = cdata;
  *out_data = &cdata->v;
        ZnTesselator.combine_length++;
  //printf("Création d'un nouveau sommet en %g %g\n",
    //cdata->v[0], cdata->v[1]);
}

static void CALLBACK
ZnTessError(GLenum      errno,
            void        *data)
{
  fprintf(stderr, "Tesselation error in curve item: %d\n", errno);
}


static void
InitZinc(Tcl_Interp *interp) {
  static ZnBool inited = False;
  unsigned int  i, x, y, bit;
  char          name[TCL_INTEGER_SPACE + 20];
  
  if (inited) {
    return;
  }
  
  /*
   * Add the specific bitmaps.
   */
  for (i = 0; i < sizeof(SYMBOLS_BITS)/(SYMBOL_WIDTH*SYMBOL_HEIGHT/8); i++) {
    sprintf(name, "AtcSymbol%d", i+1);
    Tk_DefineBitmap(interp, Tk_GetUid(name),
                    SYMBOLS_BITS[i], SYMBOL_WIDTH, SYMBOL_HEIGHT);
  }
  
  for (i = 0; i < ZN_NUM_ALPHA_STEPS; i++) {
    for (y = 0; y < 4; y++) {
      bitmaps[i][y][0] = 0;
      for (x = 0; x < 4; x++) {
        /*
         * Use the dither4x4 matrix to determine if this bit is on
         */
        bit = (i >= dither4x4[y][x]) ? 1 : 0;
        /*
         * set the bit in the array used to make the X Bitmap
         * mirror the pattern in x & y to make an 8x8 bitmap.
         */
        if (bit) {
          bitmaps[i][y][0] |= (1 << x);
          bitmaps[i][y][0] |= (1 << (4 + x));
        } 
      }
      bitmaps[i][y][1] = bitmaps[i][y][2] = bitmaps[i][y][3] = bitmaps[i][y][0];
      bitmaps[i][y+4][0] = bitmaps[i][y+4][1] = bitmaps[i][y][0];
      bitmaps[i][y+4][2] = bitmaps[i][y+4][3] = bitmaps[i][y][0];
      bitmaps[i][y+8][0] = bitmaps[i][y+8][1] = bitmaps[i][y][0];
      bitmaps[i][y+8][2] = bitmaps[i][y+8][3] = bitmaps[i][y][0];
      bitmaps[i][y+12][0] = bitmaps[i][y+12][1] = bitmaps[i][y][0];
      bitmaps[i][y+12][2] = bitmaps[i][y+12][3] = bitmaps[i][y][0];
      bitmaps[i][y+16][0] = bitmaps[i][y+16][1] = bitmaps[i][y][0];
      bitmaps[i][y+16][2] = bitmaps[i][y+16][3] = bitmaps[i][y][0];
      bitmaps[i][y+20][0] = bitmaps[i][y+20][1] = bitmaps[i][y][0];
      bitmaps[i][y+20][2] = bitmaps[i][y+20][3] = bitmaps[i][y][0];
      bitmaps[i][y+24][0] = bitmaps[i][y+24][1] = bitmaps[i][y][0];
      bitmaps[i][y+24][2] = bitmaps[i][y+24][3] = bitmaps[i][y][0];
      bitmaps[i][y+28][0] = bitmaps[i][y+28][1] = bitmaps[i][y][0];
      bitmaps[i][y+28][2] = bitmaps[i][y+28][3] = bitmaps[i][y][0];
    }
    sprintf(name, "AlphaStipple%d", i);
    Tk_DefineBitmap(interp, Tk_GetUid(name), (char *) bitmaps[i], 32, 32);
  }

  /*
   * Initialize the temporary lists.
   */
  ZnWorkPoints = ZnListNew(8, sizeof(ZnPoint));
  ZnWorkXPoints = ZnListNew(8, sizeof(XPoint));
  ZnWorkStrings = ZnListNew(8, sizeof(char *));
  
  /*
   * Allocate a GLU tesselator.
   */
  ZnTesselator.tess = gluNewTess();
  ZnTesselator.combine_list = NULL;
        ZnTesselator.combine_length = 0;
  gluTessCallback(ZnTesselator.tess, GLU_TESS_BEGIN_DATA, ZnTessBegin);
  gluTessCallback(ZnTesselator.tess, GLU_TESS_VERTEX_DATA, ZnTessVertex);
  gluTessCallback(ZnTesselator.tess, GLU_TESS_END_DATA, ZnTessEnd);
  gluTessCallback(ZnTesselator.tess, GLU_TESS_COMBINE_DATA, ZnTessCombine);
  gluTessCallback(ZnTesselator.tess, GLU_TESS_ERROR_DATA, ZnTessError);
  gluTessNormal(ZnTesselator.tess, 0.0, 0.0, -1.0);

  /*
   * Initialize the item module.
   */
  ZnItemInit();
  
  all_uid = Tk_GetUid("all");
  current_uid = Tk_GetUid("current");  
  and_uid = Tk_GetUid("&&");
  or_uid = Tk_GetUid("||");
  xor_uid = Tk_GetUid("^");
  paren_uid = Tk_GetUid("(");
  end_paren_uid = Tk_GetUid(")");
  neg_paren_uid = Tk_GetUid("!(");
  tag_val_uid = Tk_GetUid("!!");
  neg_tag_val_uid = Tk_GetUid("!");
  dot_uid = Tk_GetUid(".");
  star_uid = Tk_GetUid("*");

  /*
   * Initialise Overlap manager library.
   */
#ifdef ATC
  OmInit();
#endif

  inited = True;
}

#ifdef BUILD_Tkzinc
#   undef TCL_STORAGE_CLASS
#   define TCL_STORAGE_CLASS DLLEXPORT
#endif

/*
 *----------------------------------------------------------------------
 *
 * Tkzinc_Init --
 *
 *      This procedure is invoked by Tcl_AppInit in tkAppInit.c to
 *      initialize the widget.
 *
 *----------------------------------------------------------------------
 */
EXTERN int
Tkzinc_Init(Tcl_Interp *interp) /* Used for error reporting. */
{
#ifndef PTK
  if (
# ifdef USE_TCL_STUBS
      Tcl_InitStubs(interp, "8.4", 0)
# else
      Tcl_PkgRequire(interp, "Tcl", "8.4", 0)
# endif
      == NULL) {
    return TCL_ERROR;
  }

  if (
# ifdef USE_TK_STUBS
      Tk_InitStubs(interp, "8.4", 0)
# else
      Tcl_PkgRequire(interp, "Tk", "8.4", 0)
# endif
      == NULL) {
    return TCL_ERROR;
  }
#endif
  /*
   * Create additional commands
   */
  Tcl_CreateObjCommand(interp, "zinc", ZincObjCmd,
                       (ClientData) Tk_MainWindow(interp),
                       (Tcl_CmdDeleteProc *) NULL);
#ifdef ATC
  Tcl_CreateObjCommand(interp, "mapinfo", ZnMapInfoObjCmd,
                       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);
  Tcl_CreateObjCommand(interp, "videomap", ZnVideomapObjCmd,
                       (ClientData) NULL, (Tcl_CmdDeleteProc *) NULL);
#endif
    
#ifndef PTK
  if (Tcl_PkgProvide(interp, "Tkzinc", VERSION) == TCL_ERROR) {
    return TCL_ERROR;
  }
#endif

  return TCL_OK;
}

EXTERN int
Tkzinc_debug_Init(Tcl_Interp *interp)   /* Used for error reporting. */
{
  return Tkzinc_Init(interp);
}

#ifdef _WIN32
/*
 *----------------------------------------------------------------------
 *
 * DllEntryPoint --
 *
 *      This wrapper function is used by Windows to invoke the
 *      initialization code for the DLL.  If we are compiling
 *      with Visual C++, this routine will be renamed to DllMain.
 *      routine.
 *
 * Results:
 *      Returns TRUE;
 *
 * Side effects:
 *      None.
 *
 *----------------------------------------------------------------------
 */
BOOL APIENTRY
DllEntryPoint(HINSTANCE hInst,     /* Library instance handle. */
              DWORD     reason,   /* Reason this function is being called. */
              LPVOID    reserved) /* Not used. */
{
    return TRUE;
}
#endif
