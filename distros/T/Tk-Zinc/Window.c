/*
 * Window.c -- Implementation of Window item.
 *
 * Authors              : Patrick LECOANET
 * Creation date        : Fri May 12 11:25:53 2000
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Item.h"
#include "Geo.h"
#include "Types.h"
#include "WidgetInfo.h"
#include "tkZinc.h"

#include <stdio.h>
#include "WindowUtils.h"

/* We need to include tkPlatDecls to use Tk_GetHWND */
#if defined(_WIN32) && defined(PTK) && !defined(PTK_800)
#include <tkPlatDecls.m>
#endif



/*
 **********************************************************************************
 *
 * Specific Window item record
 *
 **********************************************************************************
 */
typedef struct _WindowItemStruct {
  ZnItemStruct  header;

  /* Public data */
  ZnPoint       pos;
  Tk_Anchor     anchor;
  Tk_Anchor     connection_anchor;
  Tk_Window     win;
  int           width;
  int           height;
  char         *windowtitle;
  
  /* Private data */
  ZnPoint       pos_dev;
  int           real_width;
  int           real_height;
  
#ifdef _WIN32
   HWND        externalwindow;
   LONG        externalwindowstyle;
#else
   Window      externalwindow;
#endif /* ifdef _WIN32 */
  
} WindowItemStruct, *WindowItem;


static ZnAttrConfig     wind_attrs[] = {
  { ZN_CONFIG_ANCHOR, "-anchor", NULL,
    Tk_Offset(WindowItemStruct, anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-catchevent", NULL,
    Tk_Offset(WindowItemStruct, header.flags), ZN_CATCH_EVENT_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(WindowItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(WindowItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(WindowItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ITEM, "-connecteditem", NULL,
    Tk_Offset(WindowItemStruct, header.connected_item), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-connectionanchor", NULL,
    Tk_Offset(WindowItemStruct, connection_anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_INT, "-height", NULL,
    Tk_Offset(WindowItemStruct, height), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_POINT, "-position", NULL, Tk_Offset(WindowItemStruct, pos), 0,
    ZN_COORDS_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(WindowItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(WindowItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(WindowItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(WindowItemStruct, header.flags), ZN_VISIBLE_BIT,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG|ZN_VIS_FLAG, False },
  { ZN_CONFIG_INT, "-width", NULL,
    Tk_Offset(WindowItemStruct, width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_WINDOW, "-window", NULL,
    Tk_Offset(WindowItemStruct, win), 0,
    ZN_COORDS_FLAG|ZN_WINDOW_FLAG, False },
  { ZN_CONFIG_STRING, "-windowtitle", NULL,
    Tk_Offset(WindowItemStruct, windowtitle), 0,
    ZN_COORDS_FLAG|ZN_WINDOW_FLAG, False },
  
  { ZN_CONFIG_END, NULL, NULL, 0, 0, 0, False }
};


/*
 **********************************************************************************
 *
 * WindowDeleted --
 *
 *      Do the bookeeping after a managed window deletion.
 *
 **********************************************************************************
 */
static void
WindowDeleted(ClientData        client_data,
              XEvent            *event)
{
  WindowItem wind = (WindowItem) client_data;

  if (event->type == DestroyNotify) {
    wind->win = NULL;
  }
}


/*
 **********************************************************************************
 *
 * Window item geometry manager --
 *
 **********************************************************************************
 */


/*
 * A managed window changes requested dimensions.
 */
static void
WindowItemRequest(ClientData    client_data,
                  Tk_Window     win)
{
  WindowItem wind = (WindowItem) client_data;

  ZnITEM.Invalidate((ZnItem) wind, ZN_COORDS_FLAG);
}

/*
 * A managed window turns control over
 * to another geometry manager.
 */
static void
WindowItemLostSlave(ClientData  client_data,
                    Tk_Window   win)
{
  WindowItem wind = (WindowItem) client_data;
  ZnWInfo *wi = ((ZnItem) wind)->wi;
  
  Tk_DeleteEventHandler(wi->win, StructureNotifyMask, WindowDeleted,
                        (ClientData) wind);
  if (wi->win != Tk_Parent(wind->win)) {
    Tk_UnmaintainGeometry(wind->win, wi->win);
  }
  Tk_UnmapWindow(wind->win);
  wind->win = NULL;
}

static Tk_GeomMgr wind_geom_type = {
    "zincwindow",               /* name */
    WindowItemRequest,          /* requestProc */
    WindowItemLostSlave,        /* lostSlaveProc */
};



/*
 **********************************************************************************
 *
 * Manage external Window -- Reparent, Unparent, Resize
 *
 **********************************************************************************
 */

/*
 * Create a Tk_Window
 */
 static int WINDOW_PRIVATE_TK_WINDOW_COUNTER = 0;
 
 static void
 WindowCreateTkWindow(ZnItem item)
 {
    ZnWInfo    *wi = item->wi;
    WindowItem wind = (WindowItem) item;
    char buffer[32];
     
    if (wind->win == 0) {
      /* create a unique name */
      sprintf(buffer, "_private_tkwindow_%d", WINDOW_PRIVATE_TK_WINDOW_COUNTER);
      WINDOW_PRIVATE_TK_WINDOW_COUNTER++;
     
      /* create a new Tk_Window */
      wind->win = Tk_CreateWindow(wi->interp, wi->win, buffer, NULL);
    }
 }

 
 /*
 * Resize an external window
 */
static void
WindowResizeExternalWindow(ZnItem item, int width, int height)
{
    ZnWInfo    *wi = item->wi;
    WindowItem wind = (WindowItem) item;
    
    /* Our window (wi->win) must exists before doing anything */
    Tk_MakeWindowExist(wi->win);
    Tk_MakeWindowExist(wind->win);
    
#ifdef _WIN32
    /* Resize our external window if needed */
    if (wind->externalwindow != 0) {
      MoveWindow(wind->externalwindow, 0, 0, width, height, TRUE);
    }

#else
    /* Resize our external window if needed */
    if (wind->externalwindow != 0) {
      XResizeWindow(wi->dpy, wind->externalwindow, width, height);
      XFlush(wi->dpy); 
    }

#endif /* ifdef _WIN32 */
}


/*
 * Reparent/capture an external window
 */
static void
WindowCaptureExternalWindow(ZnItem item)
{
    ZnWInfo    *wi = item->wi;
    WindowItem wind = (WindowItem) item;

#ifdef _WIN32
   /* Try to find a window matching windowtitle */
   HWND externalWindow = SearchWindowByTitle(wind->windowtitle, wi->dpy, NULL, 0);
   
   /* Test if we can reparent our window */
   if ((externalWindow != 0) && (wi->win != 0)) {
      /* Save external window */
      wind->externalwindow = externalWindow;
      
      /* Test if we must create a window */
      if (wind->win == NULL) {
         /* Create a new window */
         WindowCreateTkWindow(item);
      }
      
      /* Our window must exists before we try to reparent an external window */
      Tk_MakeWindowExist(wi->win);
      Tk_MakeWindowExist(wind->win);
      
      /* remove window decoration */
      wind->externalwindowstyle = removeWindowDecoration(externalWindow);
      ShowWindow(externalWindow, SW_SHOW);
            
      /* Reparent our external window */
      SetParent(externalWindow, Tk_GetHWND(Tk_WindowId(wind->win)));
      ShowWindow(externalWindow, SW_SHOW);
      
      /* Windows only: we must resize our external window */
      WindowResizeExternalWindow(item, wind->real_width, wind->real_height);
   }

#else
   /* Try to find a window matching windowtitle */
   Window externalWindow = SearchWindowByTitle(wind->windowtitle, wi->dpy, RootWindowOfScreen(wi->screen), 0);

   /* Test if we can reparent our window */
   if ((externalWindow != 0) && (wi->win != 0)) {
      /* Save external window */
      wind->externalwindow = externalWindow;
   
      /* Test if we must create a window */
      if (wind->win == NULL) {
         /* Create a new window */
         WindowCreateTkWindow(item);
      }
      
      /* Our window must exists before we try to reparent an external window */
      Tk_MakeWindowExist(wi->win);
      Tk_MakeWindowExist(wind->win);
   
      /* Withdraw our external window from desktop */
      withdrawWindowFromDesktop (wi->dpy, externalWindow, Tk_ScreenNumber(wi->win));
      
      /* Reparent our external window */
      XAddToSaveSet (wi->dpy, externalWindow);
      XReparentWindow(wi->dpy, externalWindow, Tk_WindowId(wind->win), 0, 0);
      XMapWindow(wi->dpy, externalWindow);
      XFlush(wi->dpy);
   }

#endif /* ifdef _WIN32 */
}


/*
 * Unparent/release an external window
 */
static void
WindowReleaseExternalWindow(ZnItem item)
{
    ZnWInfo    *wi = item->wi;
    WindowItem wind = (WindowItem) item;
    
#ifdef _WIN32
   /* Test if we must release an external window */
   if (wind->externalwindow != 0) {   
       /* restore window style */
       restoreWindowStyle(wind->externalwindow, wind->externalwindowstyle);	   
	   wind->externalwindowstyle = 0;
       
       /* Reparent our external window (new parent is the main root window) */
       SetParent(wind->externalwindow, NULL);
   }

#else
   /* Test if we must release an external window */
   if (wind->externalwindow != 0) {
       /* Reparent our external window (new parent is the main root window) */
       XReparentWindow(wi->dpy, wind->externalwindow, XRootWindow(wi->dpy, Tk_ScreenNumber(wi->win)), 0, 0);
       XMapWindow(wi->dpy, wind->externalwindow);
       XFlush(wi->dpy);
       XRemoveFromSaveSet(wi->dpy, wind->externalwindow);
   }
#endif /* ifdef _WIN32 */

   /* Reset externalwindow */
   wind->externalwindow = 0;
}



/*
 **********************************************************************************
 *
 * Init --
 *
 **********************************************************************************
 */
static int
Init(ZnItem             item,
     int                *argc,
     Tcl_Obj *const     *args[])
{
  WindowItem    wind = (WindowItem) item;

  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_CATCH_EVENT_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT); /* N.A */
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 0;

  wind->pos.x = wind->pos.y = 0.0;
  wind->width = wind->height = 0;
  wind->anchor = TK_ANCHOR_NW;
  wind->connection_anchor = TK_ANCHOR_SW;
  wind->win = NULL;
  wind->windowtitle = NULL;
  wind->externalwindow = 0;
  
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Clone --
 *
 **********************************************************************************
 */
static void
Clone(ZnItem    item)
{
  WindowItem    wind = (WindowItem) item;

  /*
   * The same Tk widget can't be shared by to Window items.
   */
  wind->win = NULL;
  wind->windowtitle = NULL;
  wind->externalwindow = 0;
}


/*
 **********************************************************************************
 *
 * Destroy --
 *
 **********************************************************************************
 */
static void
Destroy(ZnItem  item)
{
  ZnWInfo       *wi = item->wi;
  WindowItem    wind = (WindowItem) item;


  /*
   * Unmanage external window if needed
   */
  if (wind->externalwindow != 0) {
    WindowReleaseExternalWindow(item);
  }
  if (wind->windowtitle) {
    ZnFree(wind->windowtitle);
  }

  /*
   * Unmanage the widget.
   */
  if (wind->win) {
    Tk_DeleteEventHandler(wind->win, StructureNotifyMask, WindowDeleted,
                          (ClientData) item);
    Tk_ManageGeometry(wind->win, (Tk_GeomMgr *) NULL, (ClientData) NULL);
    if (wi->win != Tk_Parent(wind->win)) {
      Tk_UnmaintainGeometry(wind->win, wi->win);
    }
    Tk_UnmapWindow(wind->win);
  }
}


/*
 **********************************************************************************
 *
 * Configure --
 *
 **********************************************************************************
 */
static int
Configure(ZnItem        item,
          int           argc,
          Tcl_Obj *const argv[],
          int           *flags)
{
  WindowItem    wind = (WindowItem) item;
  ZnWInfo       *wi = item->wi;
  ZnItem        old_connected;
  Tk_Window     old_win;
  const char   *old_windowtitle = wind->windowtitle;
  
  old_connected = item->connected_item;
  old_win = wind->win;
  
  if (ZnConfigureAttributes(wi, item, item, wind_attrs, argc, argv, flags) == TCL_ERROR) {
    item->connected_item = old_connected;
    return TCL_ERROR;
  }  

  if (ISSET(*flags, ZN_ITEM_FLAG)) {
    /*
     * If the new connected item is not appropriate back up
     * to the old one.
     */
    if ((item->connected_item == ZN_NO_ITEM) ||
        (ISSET(item->connected_item->class->flags, ZN_CLASS_HAS_ANCHORS) &&
         (item->parent == item->connected_item->parent))) {
      ZnITEM.UpdateItemDependency(item, old_connected);
    }
    else {
      item->connected_item = old_connected;
    }
  }

  if (ISSET(*flags, ZN_WINDOW_FLAG)) {
    if (old_win != NULL) {
      Tk_DeleteEventHandler(old_win, StructureNotifyMask,
                            WindowDeleted, (ClientData) item);
      Tk_ManageGeometry(old_win, (Tk_GeomMgr *) NULL, (ClientData) NULL);
      Tk_UnmaintainGeometry(old_win, wi->win);
      Tk_UnmapWindow(old_win);
    }

    if (wind->windowtitle != NULL) {      
      if (old_windowtitle == 0) {
         /* It's a new capture */
         WindowCaptureExternalWindow(item);
      
      } else {
         /* Test if we must capture a new window */
         if (strcmp(old_windowtitle, (const char *)(wind->windowtitle)) != 0) {
            /* release previous external window */
            WindowReleaseExternalWindow(item);
            
            /* Capture a new window */
            WindowCaptureExternalWindow(item);
         }
      }
    }
    
    if (wind->win != NULL) {
      Tk_CreateEventHandler(wind->win, StructureNotifyMask,
                            WindowDeleted, (ClientData) item);
      Tk_ManageGeometry(wind->win, &wind_geom_type, (ClientData) item);
    }
  }
  
  if ((wind->win != NULL) &&
      ISSET(*flags, ZN_VIS_FLAG) &&
      ISCLEAR(item->flags, ZN_VISIBLE_BIT)) {
      Tk_UnmapWindow(wind->win);
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Query --
 *
 **********************************************************************************
 */
static int
Query(ZnItem            item,
      int               argc,
      Tcl_Obj *const    argv[])
{
  if (ZnQueryAttribute(item->wi->interp, item, wind_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }  

  return TCL_OK;
}

/*
 * Compute the transformation to be used and the origin
 * of the window (upper left point in item coordinates).
 */
static ZnTransfo *
ComputeTransfoAndOrigin(ZnItem    item,
                        ZnPoint   *origin)
{
  WindowItem wind = (WindowItem) item;
  ZnTransfo  *t;

  /*
   * The connected item support anchors, this is checked by configure.
   */
  if (item->connected_item != ZN_NO_ITEM) {
    ZnTransfo inv;

    item->connected_item->class->GetAnchor(item->connected_item,
                                           wind->connection_anchor,
                                           origin);

    /* GetAnchor return a position in device coordinates not in
     * the item coordinate space. To compute the icon origin
     * (upper left corner), we must apply the inverse transform
     * to the ref point before calling anchor2origin.
     */
    ZnTransfoInvert(item->transfo, &inv);
    ZnTransformPoint(&inv, origin, origin);
    /*
     * The relevant transform in case of an attachment is the item
     * transform alone. This is case of local coordinate space where
     * only the translation is a function of the whole transform
     * stack, scale and rotation are reset.
     */
    t = item->transfo;
  }
  else {
    origin->x = origin->y = 0;
    t = item->wi->current_transfo;
  }

  ZnAnchor2Origin(origin, (ZnReal) wind->real_width, (ZnReal) wind->real_height,
                  wind->anchor, origin);
  //origin->x = ZnNearestInt(origin->x);
  //origin->y = ZnNearestInt(origin->y);

  return t;
}

/*
 **********************************************************************************
 *
 * ComputeCoordinates --
 *
 **********************************************************************************
 */
static void
ComputeCoordinates(ZnItem       item,
                   ZnBool       force)
{
  ZnWInfo    *wi = item->wi;
  WindowItem wind = (WindowItem) item;
  ZnPoint    origin;
  ZnTransfo  *t;

  ZnResetBBox(&item->item_bounding_box);

  if (wind->win == NULL) {
    return;
  }

  wind->real_width = wind->width;
  if (wind->real_width <= 0) {
    wind->real_width = Tk_ReqWidth(wind->win);
    if (wind->real_width <= 0) {
      wind->real_width = 1;
    }
  }
  wind->real_height = wind->height;
  if (wind->real_height <= 0) {
    wind->real_height = Tk_ReqHeight(wind->win);
    if (wind->real_height <= 0) {
      wind->real_height = 1;
    }
  }

  t = ComputeTransfoAndOrigin(item, &origin);
  ZnTransformPoint(wi->current_transfo, &origin, &wind->pos_dev);
  wind->pos_dev.x = ZnNearestInt(wind->pos_dev.x);
  wind->pos_dev.y = ZnNearestInt(wind->pos_dev.y);

  /*
   * Compute the bounding box.
   */
  ZnAddPointToBBox(&item->item_bounding_box, wind->pos_dev.x, wind->pos_dev.y);
  ZnAddPointToBBox(&item->item_bounding_box, wind->pos_dev.x+wind->real_width,
                   wind->pos_dev.y+wind->real_height);
  item->item_bounding_box.orig.x -= 1.0;
  item->item_bounding_box.orig.y -= 1.0;
  item->item_bounding_box.corner.x += 1.0;
  item->item_bounding_box.corner.y += 1.0;

  /*
   * Update connected items.
   */
  SET(item->flags, ZN_UPDATE_DEPENDENT_BIT);
}


/*
 **********************************************************************************
 *
 * ToArea --
 *      Tell if the object is entirely outside (-1),
 *      entirely inside (1) or in between (0).
 *
 **********************************************************************************
 */
static int
ToArea(ZnItem   item,
       ZnToArea ta)
{
  WindowItem    wind = (WindowItem) item;
  ZnBBox        box;
  int           w=0, h=0;
  
  box.orig = wind->pos_dev;
  if (wind->win != NULL) {
    w = wind->real_width;
    h = wind->real_height;
  }
  box.corner.x = box.orig.x + w;
  box.corner.y = box.orig.y + h;
  
  return ZnBBoxInBBox(&box, ta->area);
}

/*
 **********************************************************************************
 *
 * Draw --
 *
 **********************************************************************************
 */
static void
Draw(ZnItem     item)
{
  ZnWInfo       *wi = item->wi;
  WindowItem    wind = (WindowItem) item;

  if (wind->win == NULL) {
    return;
  }

  /*
   * If the window is outside the visible area, unmap it.
   */
  if ((item->item_bounding_box.corner.x <= 0) ||
      (item->item_bounding_box.corner.y <= 0) ||
      (item->item_bounding_box.orig.x >= wi->width) ||
      (item->item_bounding_box.orig.y >= wi->height)) {
    if (wi->win == Tk_Parent(wind->win)) {
      Tk_UnmapWindow(wind->win);
    }
    else {
      Tk_UnmaintainGeometry(wind->win, wi->win);
    }
    return;
  }

  /*
   * Position and map the window.
   */
  if (wi->win == Tk_Parent(wind->win)) {
    if ((wind->pos_dev.x != Tk_X(wind->win)) ||
        (wind->pos_dev.y != Tk_Y(wind->win)) ||
        (wind->real_width != Tk_Width(wind->win)) ||
        (wind->real_height != Tk_Height(wind->win))) {
      Tk_MoveResizeWindow(wind->win,
                          (int) wind->pos_dev.x, (int) wind->pos_dev.y,
                          wind->real_width, wind->real_height);
    }
    Tk_MapWindow(wind->win);
  }
  else {
    Tk_MaintainGeometry(wind->win, wi->win,
                        (int) wind->pos_dev.x, (int) wind->pos_dev.y,
                        wind->real_width, wind->real_height);
  }
  
  WindowResizeExternalWindow(item, wind->real_width, wind->real_height);
}


/*
 **********************************************************************************
 *
 * IsSensitive --
 *
 **********************************************************************************
 */
static ZnBool
IsSensitive(ZnItem      item,
            int         item_part)
{
  /*
   * Sensitivity can't be controlled.
   */
  return True;
}


/*
 **********************************************************************************
 *
 * Pick --
 *
 **********************************************************************************
 */
static double
Pick(ZnItem     item,
     ZnPick     ps)
{
  WindowItem    wind = (WindowItem) item;
  ZnBBox        box;
  ZnReal        dist = 1e40;
  ZnPoint       *p = ps->point;

  box.orig = wind->pos_dev;
  if (wind->win != NULL) {
    box.corner.x = box.orig.x + wind->real_width;
    box.corner.y = box.orig.y + wind->real_height;
    dist = ZnRectangleToPointDist(&box, p);
    if (dist <= 0.0) {
      dist = 0.0;
    }
  }
  return dist;
}


/*
 **********************************************************************************
 *
 * PostScript --
 *
 **********************************************************************************
 */
#ifdef X_GetImage
static int
xerrorhandler(ClientData  client_data,
              XErrorEvent *e)
{
	return 0;
}
#endif

static int
PostScript(ZnItem item,
           ZnBool prepass,
           ZnBBox *area)
{
  ZnWInfo         *wi = item->wi;
  WindowItem      wind = (WindowItem) item;
  char            path[256];
  XImage          *ximage;
  int             result;
  ZnPoint         origin;
  Tcl_DString     buffer1, buffer2;
#ifdef X_GetImage
  Tk_ErrorHandler	handle;
#endif

  sprintf(path, "\n%%%% %s item (%s, %d x %d)\n%.15g %.15g translate\n",
          Tk_Class(wind->win), Tk_PathName(wind->win), wind->real_width, wind->real_height,
          wind->pos_dev.x, wind->pos_dev.y);
  Tcl_AppendResult(wi->interp, path, (char *) NULL);

  ComputeTransfoAndOrigin(item, &origin);
  
  sprintf(path, "/InitialTransform load setmatrix\n"
          "%.15g %.15g translate\n"
          "1 -1 scale\n",
          wind->pos_dev.x, wind->pos_dev.y + wind->real_height);
  Tcl_AppendResult(wi->interp, path, (char *) NULL);

  /* first try if the widget has its own "postscript" command. If it
   * exists, this will produce much better postscript than
   * when a pixmap is used.
   */
#ifndef PTK
  Tcl_DStringInit(&buffer1);
  Tcl_DStringInit(&buffer2);
  Tcl_DStringGetResult(wi->interp, &buffer2);
  sprintf(path, "%s postscript -prolog 0\n", Tk_PathName(wind->win));
  result = Tcl_Eval(wi->interp, path);
  Tcl_DStringGetResult(wi->interp, &buffer1);
  Tcl_DStringResult(wi->interp, &buffer2);
  Tcl_DStringFree(&buffer2);

  if (result == TCL_OK) {
    Tcl_AppendResult(wi->interp, "50 dict begin\nsave\ngsave\n", (char *) NULL);
    sprintf (path, "0 %d moveto %d 0 rlineto 0 -%d rlineto -%d",
             wind->real_height, wind->real_width, wind->real_height, wind->real_width);
    Tcl_AppendResult(wi->interp, path, (char *) NULL);
    Tcl_AppendResult(wi->interp, " 0 rlineto closepath\n",
                     "1.000 1.000 1.000 setrgbcolor AdjustColor\nfill\ngrestore\n",
                     Tcl_DStringValue(&buffer1), "\nrestore\nend\n\n\n", (char *) NULL);
    Tcl_DStringFree(&buffer1);

    return result;
  }
  Tcl_DStringFree(&buffer1);
#endif

  /*
   * If the window is off the screen it will generate an BadMatch/XError
   * We catch any BadMatch errors here
   */
#ifdef X_GetImage
  handle = Tk_CreateErrorHandler(wi->dpy, BadMatch, X_GetImage, -1,
                                 xerrorhandler, (ClientData) wind->win);
#endif

  /*
   * Generate an XImage from the window.  We can then read pixel 
   * values out of the XImage.
   */
  ximage = XGetImage(wi->dpy, Tk_WindowId(wind->win), 0, 0, (unsigned int) wind->real_width,
                     (unsigned int) wind->real_height, AllPlanes, ZPixmap);

#ifdef X_GetImage
  Tk_DeleteErrorHandler(handle);
#endif

  if (ximage == NULL) { 
    return TCL_OK;
  }

  result = ZnPostscriptXImage(wi->interp, wind->win, wi->ps_info, ximage,
                              0, 0, wind->real_width, wind->real_height);
  XDestroyImage(ximage);

  return result;
}


/*
 **********************************************************************************
 *
 * GetAnchor --
 *
 **********************************************************************************
 */
static void
GetAnchor(ZnItem        item,
          Tk_Anchor     anchor,
          ZnPoint       *p)
{
  WindowItem    wind = (WindowItem) item;
  
  if (wind->win != NULL) {
    ZnOrigin2Anchor(&wind->pos_dev, (ZnReal) wind->real_width,
                    (ZnReal) wind->real_height, anchor, p);
  }
  else {
    p->x = p->y = 0.0;
  }
}


/*
 **********************************************************************************
 *
 * GetClipVertices --
 *      Get the clipping shape.
 *
 **********************************************************************************
 */
static ZnBool
GetClipVertices(ZnItem          item,
                ZnTriStrip      *tristrip)
{
  WindowItem    wind = (WindowItem) item;
  int           w=0, h=0;
  ZnPoint       *points;
  
  ZnListAssertSize(ZnWorkPoints, 2);
  if (wind->win != NULL) {
    w = wind->real_width;
    h = wind->real_height;    
  }
  points = ZnListArray(ZnWorkPoints);
  ZnTriStrip1(tristrip, points, 2, False);
  points[0] = wind->pos_dev;
  points[1].x = points[0].x + w;
  points[1].y = points[0].y + h;

  return True;
}


/*
 **********************************************************************************
 *
 * Coords --
 *      Return or edit the item origin. This doesn't take care of
 *      the possible attachment. The change will be effective at the
 *      end of the attachment.
 *
 **********************************************************************************
 */
static int
Coords(ZnItem           item,
       int              contour,
       int              index,
       int              cmd,
       ZnPoint          **pts,
       char             **controls,
       unsigned int     *num_pts)
{
  WindowItem    wind = (WindowItem) item;
  
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " windows can't add or remove vertices", (char *) NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on windows", (char *) NULL);
      return TCL_ERROR;
    }
    wind->pos = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    *num_pts = 1;
    *pts = &wind->pos;
  }
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Exported functions struct --
 *
 **********************************************************************************
 */
static ZnItemClassStruct WINDOW_ITEM_CLASS = {
  "window",
  sizeof(WindowItemStruct),
  wind_attrs,
  0,                    /* num_parts */
  ZN_CLASS_HAS_ANCHORS|ZN_CLASS_ONE_COORD, /* flags */
  Tk_Offset(WindowItemStruct, pos),
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  NULL,                 /* GetFieldSet */
  GetAnchor,
  GetClipVertices,
  NULL,                 /* GetContours */
  Coords,
  NULL,                 /* InsertChars */
  NULL,                 /* DeleteChars */
  NULL,                 /* Cursor */
  NULL,                 /* Index */
  NULL,                 /* Part */
  NULL,                 /* Selection */
  NULL,                 /* Contour */
  ComputeCoordinates,
  ToArea,
  Draw,
  NULL,                 /* Pre-render */
  Draw,                 /* Render use the same code as Draw. */
  IsSensitive,
  Pick,
  NULL,                 /* PickVertex */
  PostScript
};

ZnItemClassId ZnWindow = (ZnItemClassId) &WINDOW_ITEM_CLASS;
