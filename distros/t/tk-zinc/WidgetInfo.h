/*
 * WidgetInfo.h -- Zinc Widget record.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Mon Feb  1 12:13:24 1999
 *
 * $Id: WidgetInfo.h,v 1.38 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _WidgetInfo_h
#define _WidgetInfo_h


#include "Item.h"
#include "Transfo.h"
#include "Types.h"
#ifndef _WIN32
#include "perfos.h"
#endif
#include "Color.h"


#define ZN_NUM_ALPHA_STEPS      16

/*
 * Constants for flags
 */
#define ZN_REPICK_IN_PROGRESS   (1<<0)
#define ZN_GRABBED_ITEM         (1<<1)
#define ZN_GRABBED_PART         (1<<2)
#define ZN_REALIZED             (1<<3)
#define ZN_INTERNAL_NEED_REPICK (1<<4)
#define ZN_UPDATE_SCROLLBARS    (1<<5)  /* If set, the scrollbars must be updated. */
#define ZN_GOT_FOCUS            (1<<6)  /* Set means that the widget has the input focus. */
#define ZN_UPDATE_PENDING       (1<<7)  /* Set means there is a pending graphic update. */
#define ZN_HAS_GL               (1<<8)  /* Tell if openGL can be used. */
#define ZN_HAS_X_SHAPE          (1<<9)  /* Tell if the X shape extension is available. */
#define ZN_MONITORING           (1<<10) /* Set if performance monitoring is on. */
#define ZN_PRINT_CONFIG         (1<<11) /* If set the openGL hardware configuration
                                         * is printed on startup. */
#define ZN_CONFIGURE_EVENT      (1<<12)

#ifdef __CPLUSPLUS__
extern "C" {
#endif


/*
 * The following structure provides information about the selection and
 * the insertion cursor.  It is needed by only a few items, such as
 * those that display text.  It is shared by the generic canvas code
 * and the item-specific code, but most of the fields should be written
 * only by the canvas generic code.
 */
typedef struct _ZnTextInfo {
  ZnGradient    *sel_color;     /* Background color for selected text.
                                 * Read-only to items.*/
  ZnItem        sel_item;       /* Pointer to selected item. ZN_NO_ITEM
                                 * means that the widget doesn't own the
                                 * selection. Writable by items. */
  int           sel_field;
  int           sel_first;      /* Index of first selected character. 
                                 * Writable by items. */
  int           sel_last;       /* Index of last selected character. 
                                 * Writable by items. */
  ZnItem        anchor_item;    /* Item corresponding to sel_anchor: not
                                 * necessarily sel_item. Read-only to items. */
  int           anchor_field;
  int           sel_anchor;     /* Fixed end of selection (i.e. "select to"
                                 * operation will use this as one end of the
                                 * selection).  Writable by items. */
  ZnGradient    *insert_color;  /* Used to draw vertical bar for insertion
                                 * cursor.  Read-only to items. */
  unsigned int  insert_width;   /* Total width of insertion cursor.  Read-only
                                 * to items. */
  ZnBool        cursor_on;      /* True means that an insertion cursor should
                                 * be displayed in focus_item. Read-only to
                                 * items.*/
} ZnTextInfo;

typedef struct _ZnWInfo {
  Tcl_Interp            *interp;        /* Interpreter associated with widget.  */
  Tcl_Command           cmd;            /* Token for zinc widget command.       */
  Tcl_HashTable         *id_table;      /* Hash table for object ids.           */
  Tcl_HashTable         *t_table;       /* Hash table for transformations.      */
  unsigned long         obj_id;         /* Id for the next new object.          */
  int                   flags;
  Tk_BindingTable       binding_table;  /* Table of all bindings currently defined
                                         * for this widget.  NULL means that no
                                         * bindings exist, so the table hasn't been
                                         * created.  Each "object" used for this
                                         * table is either a Tk_Uid for a tag or
                                         * the address of an item named by id.  */
  int                   state;          /* Last known modifier state.  Used to
                                         * defer picking a new current object
                                         * while buttons are down. */
  ZnItem                current_item;   /* Item picked from previous pick sequence */
  ZnItem                new_item;       /* Item picked from current pick sequence */
  int                   current_part;
  int                   new_part;
  ZnItem                hot_item;
  ZnItem                hot_prev;
  ZnItem                focus_item;     /* Item that currently has the input focus,
                                         * or ZN_NO_ITEM if no such item.  Read-only to
                                         * items.  */
  int                   focus_field;
  XEvent                pick_event;     /* Event used to forge fake events and to do
                                         * repicks. */
  ZnBBox                exposed_area;   /* Window area that need to be rexposed.
                                         * It is distinct from redraw_area which
                                         * is updated when items are changed. */
  Pixmap                alpha_stipples[ZN_NUM_ALPHA_STEPS];
  int                   border_width;
  int                   opt_width;      /* Window size as stated/reported by the option. */
  int                   opt_height;     /* They are equal to the width/height fields after
                                         * the actual resize. They may to be equal if
                                         * the resize is not acknowledged by the geo
                                         * manager. */
  ZnGradient            *relief_grad;   /* The gradient describing the border relief
                                         * colors. */
  ZnReliefStyle         relief;         /* The border relief. */
  
  /* Tracks global resources    */
#ifdef ATC
  unsigned int          track_managed_history_size;     /* Size of history for tracks   */
  unsigned int          track_visible_history_size;     /* Size of displayed history    */
  ZnReal                speed_vector_length; /* How long (in time) are speedvectors*/
  int                   om_group_id;    /* Tell which group contains tracks to be       */
  ZnItem                om_group;       /* processed for anti label overlap.            */

  /* Maps global resources */
  Tk_Font               map_text_font;          /* Font for texts in Map items          */
#ifdef GL
  ZnTexFontInfo         map_font_tfi;           /* Used to preserve the default font from
                                                 * being freed again and again */
#endif
  Tcl_Obj               *map_symbol_obj;
  ZnImage               map_distance_symbol;    /* Distance marks displayed along Map   */
                                                /* lines.                               */
  Tcl_Obj               *track_symbol_obj;
  ZnImage               track_symbol;           /* Symbol displayed at track/wp current */
                                                /* position.                            */
#endif
  /* Transformer */
  ZnTransfo             *current_transfo;
  ZnList                transfo_stack;
  struct _ClipState     *current_clip;
  ZnList                clip_stack;
  
  /* Others */
  ZnGradient            *fore_color;            /* Default gradient used in new items   */
  ZnGradient            *back_color;            /* Color of the widget background.      */
  ZnGradient            *bbox_color;            /* Color used to draw bboxes (debug).   */
  Tk_Cursor             cursor;                 /* Cursor displayed in zinc window.     */
  ZnBool                draw_bboxes;            /* Draw item's bboxes (debug).          */
  ZnBool                follow_pointer;         /* Process pointer motion events to     */
                                                /* emit enter/leave events.             */
  int                   light_angle;
  
  int                   pick_aperture;          /* size of pick aperture in pixels      */
  Tk_Font               font;                   /* Default font used in new items */
#ifdef GL
  ZnTexFontInfo         font_tfi;               /* Used to preserve the default font from
                                                 * being freed again and again */
#endif
  Tcl_Obj               *tile_obj;
  ZnImage               tile;
  
  /* Zinc private resources */
  int                   width;                  /* Actual window dimension. */
  int                   height;
  int                   inset;                  /* Border and highlight width */
  
  /* Graphic variables */
  Display               *dpy;                   /* The display of the widget window.    */
  Screen                *screen;
  Tk_Window             win;                    /* The window of the widget. */
  Pixmap                draw_buffer;            /* Pixmap for double buffering          */
  ZnBBox                damaged_area;           /* The current damaged rectangle        */
  GC                    gc;
  ZnBool                reshape;                /* Use the Shape Extension on the window.*/
  ZnBool                full_reshape;           /* Use it on the top level window.      */
  Window                real_top;
  int                   render;
  unsigned char         alpha;                  /* Current composite group alpha. */
  ZnItem                top_group;
#ifndef PTK_800
  Tk_OptionTable        opt_table;
#endif

  /* Text management */
  ZnTextInfo            text_info;
  int                   insert_on_time;
  int                   insert_off_time;
  Tcl_TimerToken        blink_handler;
  char                  *take_focus;
  int                   highlight_width;        /* Width in pixels of highlight to draw
                                                 * around widget when it has the focus.
                                                 * = 0 means don't draw a highlight. */
  ZnGradient            *highlight_bg_color;    /* Color for drawing traversal highlight
                                                 * area when highlight is off. */
  ZnGradient            *highlight_color;       /* Color for drawing traversal highlight.*/
  
  /* Scrollbar management */
  ZnPoint               origin;                 /* Coordinate mapped to the upper left corner
                                                 * of the zinc window. */
#ifdef PTK
  LangCallback          *x_scroll_cmd;
  LangCallback          *y_scroll_cmd;
#else
  Tcl_Obj               *x_scroll_cmd;          /* Command prefixes for communicating with */
  Tcl_Obj               *y_scroll_cmd;          /* scrollbars.  NULL means no scrollbar.
                                                 * Malloc'ed */
#endif
  int                   x_scroll_incr;          /* If >0, defines a grid for horiz/vert */
  int                   y_scroll_incr;          /* scrolling.  This is the size of the "unit",
                                                 * and the left edge of the screen will always
                                                 * lie on an even unit boundary. */
  int                   scroll_xo;              /* This bbox define the region that is the */
  int                   scroll_yo;              /* 100% area for scrolling (i.e. it determines */
  int                   scroll_xc;              /* the size and location of the sliders on */
  int                   scroll_yc;              /* scrollbars). */
  ZnBool                confine;                /* When true, it is not possible to scroll the
                                                 * viewing area past the scroll region. */
  Tcl_Obj               *region;                /* Scroll region option string source of the
                                                 * scroll_region above. */
  Tk_PostscriptInfo     ps_info;

  /* Perf measurement variables. */
#ifndef _WIN32
  ZnChrono              this_draw_chrono;
  ZnChrono              total_draw_chrono;
#endif
  int                   num_items;
  int                   damaged_area_w;
  int                   damaged_area_h;
  int                   debug;
} ZnWInfo;

  
#ifdef __CPLUSPLUS__
}
#endif

#endif /* _WidgetInfo_h */
