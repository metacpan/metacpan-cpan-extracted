/*
 * Icon.c -- Implementation of Icon item.
 *
 * Authors              : Patrick LECOANET
 * Creation date        : Sat Mar 25 13:53:39 1995
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
#include "Draw.h"
#include "Types.h"
#include "Image.h"
#include "WidgetInfo.h"
#include "tkZinc.h"


static const char rcsid[] = "$Id: Icon.c,v 1.45 2005/05/10 07:59:48 lecoanet Exp $";
static const char compile_id[] = "$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 **********************************************************************************
 *
 * Specific Icon item record
 *
 **********************************************************************************
 */
typedef struct _IconItemStruct {
  ZnItemStruct  header;

  /* Public data */
  ZnPoint       pos;
  ZnImage       image;
  Tk_Anchor     anchor;
  Tk_Anchor     connection_anchor;
  ZnGradient    *color; /* Used only if the image is a bitmap (in GL alpha part
                         * is always meaningful). */
  
  /* Private data */
  ZnPoint       dev[4];
} IconItemStruct, *IconItem;


static ZnAttrConfig     icon_attrs[] = {
  { ZN_CONFIG_ANCHOR, "-anchor", NULL,
    Tk_Offset(IconItemStruct, anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-color", NULL,
    Tk_Offset(IconItemStruct, color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(IconItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(IconItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(IconItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ITEM, "-connecteditem", NULL,
    Tk_Offset(IconItemStruct, header.connected_item), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-connectionanchor", NULL,
    Tk_Offset(IconItemStruct, connection_anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_IMAGE, "-image", NULL,
    Tk_Offset(IconItemStruct, image), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-mask", NULL,
    Tk_Offset(IconItemStruct, image), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_POINT, "-position", NULL, Tk_Offset(IconItemStruct, pos), 0,
    ZN_COORDS_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(IconItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(IconItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(IconItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(IconItemStruct, header.flags), ZN_VISIBLE_BIT,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG|ZN_VIS_FLAG, False },
  
  { ZN_CONFIG_END, NULL, NULL, 0, 0, 0, False }
};



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
     Tcl_Obj *CONST     *args[])
{
  ZnWInfo       *wi = item->wi;
  IconItem      icon = (IconItem) item;

  /*printf("size of an icon(header) = %d(%d)\n",
    sizeof(IconItemStruct), sizeof(ZnItemStruct));*/

  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 1;

  icon->pos.x = icon->pos.y = 0.0;
  icon->image = ZnUnspecifiedImage;
  icon->anchor = TK_ANCHOR_NW;
  icon->connection_anchor = TK_ANCHOR_SW;
  icon->color = ZnGetGradientByValue(wi->fore_color);
  
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
  IconItem      icon = (IconItem) item;
  
  if (icon->image != ZnUnspecifiedImage) {
    icon->image = ZnGetImageByValue(icon->image, ZnUpdateItemImage, item);
  }
  icon->color = ZnGetGradientByValue(icon->color);
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
  IconItem      icon = (IconItem) item;

  if (icon->image != ZnUnspecifiedImage) {
    ZnFreeImage(icon->image, ZnUpdateItemImage, item);
    icon->image = ZnUnspecifiedImage;
  }
  ZnFreeGradient(icon->color);
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
          Tcl_Obj *CONST argv[],
          int           *flags)
{
  ZnItem        old_connected;

  old_connected = item->connected_item;
  if (ZnConfigureAttributes(item->wi, item, item, icon_attrs,
                            argc, argv, flags) == TCL_ERROR) {
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
      Tcl_Obj *CONST    argv[])
{
  if (ZnQueryAttribute(item->wi->interp, item, icon_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }  

  return TCL_OK;
}


/*
 * Compute the transformation to be used and the origin
 * of the icon (upper left point in item coordinates).
 */
static ZnTransfo *
ComputeTransfoAndOrigin(ZnItem    item,
                        ZnPoint   *origin)
{
  IconItem icon = (IconItem) item;
  int       w, h;
  ZnTransfo *t;

  ZnSizeOfImage(icon->image, &w, &h);

  /*
   * The connected item support anchors, this is checked by configure.
   */
  if (item->connected_item != ZN_NO_ITEM) {
    ZnTransfo inv;

    item->connected_item->class->GetAnchor(item->connected_item,
                                           icon->connection_anchor,
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

  ZnAnchor2Origin(origin, (ZnReal) w, (ZnReal) h, icon->anchor, origin);
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
  //ZnWInfo   *wi = item->wi;
  IconItem  icon = (IconItem) item;
  int       width, height, i;
  ZnPoint   quad[4];
  ZnTransfo *t;
  
  ZnResetBBox(&item->item_bounding_box);

  /*
   * If there is no image then nothing to show.
   */
  if (icon->image == ZnUnspecifiedImage) {
    return;
  }
    
  ZnSizeOfImage(icon->image, &width, &height);
  t = ComputeTransfoAndOrigin(item, quad);

  quad[1].x = quad[0].x;
  quad[1].y = quad[0].y + height;
  quad[2].x = quad[0].x + width;
  quad[2].y = quad[1].y;
  quad[3].x = quad[2].x;
  quad[3].y = quad[0].y;
  ZnTransformPoints(t, quad, icon->dev, 4);
  
  for (i = 0; i < 4; i++) {
    icon->dev[i].x = ZnNearestInt(icon->dev[i].x);
    icon->dev[i].y = ZnNearestInt(icon->dev[i].y);
  }
  
  /*
   * Compute the bounding box.
   */
  ZnAddPointsToBBox(&item->item_bounding_box, icon->dev, 4);

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
  IconItem      icon = (IconItem) item;
  
  if (icon->image == ZnUnspecifiedImage) {
    return -1;
  }

  return ZnPolygonInBBox(icon->dev, 4, ta->area, NULL);
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
  IconItem      icon = (IconItem) item;
  XGCValues     values;
  unsigned int  gc_mask = 0;
  int           w, h;
  ZnBBox        box, inter, *clip_box;
  TkRegion      clip_region, photo_region, clip;
  ZnBool        simple;
  Pixmap        pixmap;
  
  if (icon->image == ZnUnspecifiedImage) {
    return;
  }

  ZnSizeOfImage(icon->image, &w, &h);
  box.orig = *icon->dev;
  box.corner.x = icon->dev->x + w;
  box.corner.y = icon->dev->y + h;
  if (!ZnImageIsBitmap(icon->image)) {
    if (ZnTransfoIsTranslation(item->wi->current_transfo)) {
      /*
       * The code below does not use of Tk_RedrawImage to be
       * able to clip with the current clip region.
       */
      ZnIntersectBBox(&box, &wi->damaged_area, &inter);
      box = inter;
      ZnCurrentClip(wi, &clip_region, NULL, NULL);
      pixmap = ZnImagePixmap(icon->image, wi->win);
      photo_region = ZnImageRegion(icon->image);
      clip = TkCreateRegion();
      /*
       * ZnImageRegion may fail: perl/Tk 800.24 doesn't support
       * some internal TkPhoto functions.
       * This is a workaround using a rectangular region based
       * on the image size.
       */
      if (photo_region == NULL) {
        XRectangle rect;
        rect.x = rect.y = 0;
        rect.width = w;
        rect.height = h;
        TkUnionRectWithRegion(&rect, clip, clip);
      }
      else {
        ZnUnionRegion(clip, photo_region, clip);
      }
      ZnOffsetRegion(clip, (int) icon->dev->x, (int) icon->dev->y);
      TkIntersectRegion(clip_region, clip, clip);
      TkSetRegion(wi->dpy, wi->gc, clip);
      XCopyArea(wi->dpy, pixmap, wi->draw_buffer, wi->gc,
                (int) (box.orig.x-icon->dev->x),
                (int) (box.orig.y-icon->dev->y),
                (unsigned int) (box.corner.x-box.orig.x),
                (unsigned int) (box.corner.y-box.orig.y),
                (int) box.orig.x,
                (int) box.orig.y);
      values.clip_x_origin = values.clip_y_origin = 0;
      XChangeGC(wi->dpy, wi->gc, GCClipXOrigin|GCClipYOrigin, &values);
      TkSetRegion(wi->dpy, wi->gc, clip_region);
      TkDestroyRegion(clip);
    }
    else {
      ZnPoint       box[4];
      int           i;
      XImage        *dest_im, *src_im;
      XImage        *dest_mask, *src_mask;
      Pixmap        drw, mask;
      unsigned int  dest_im_width, dest_im_height;
      unsigned int  max_width, max_height;
      GC            gc, mask_gc;
      TkRegion      current_clip;
      ZnBBox        *current_clip_box;

      dest_im_width = (unsigned int) (item->item_bounding_box.corner.x -
                                      item->item_bounding_box.orig.x);
      max_width = MAX(dest_im_width, (unsigned int) w);
      dest_im_height = (unsigned int) (item->item_bounding_box.corner.y -
                                       item->item_bounding_box.orig.y);
      max_height = MAX(dest_im_height, (unsigned int) h);

      mask = Tk_GetPixmap(wi->dpy, wi->draw_buffer, max_width, max_height, 1);

      drw = Tk_GetPixmap(wi->dpy, wi->draw_buffer, max_width, max_height,
                         Tk_Depth(wi->win));
      mask_gc = XCreateGC(wi->dpy, mask, 0, NULL);
      gc = XCreateGC(wi->dpy, drw, 0, NULL);
      dest_mask = XCreateImage(wi->dpy, Tk_Visual(wi->win), 1,
                             XYPixmap, 0, NULL, dest_im_width, dest_im_height,
                             8, 0);
      dest_mask->data = ZnMalloc(dest_mask->bytes_per_line * dest_mask->height);
      memset(dest_mask->data, 0, dest_mask->bytes_per_line * dest_mask->height);
      XSetForeground(wi->dpy, mask_gc, 0);
      XFillRectangle(wi->dpy, mask, mask_gc, 0, 0, max_width, max_height);
      dest_im = XCreateImage(wi->dpy, Tk_Visual(wi->win), Tk_Depth(wi->win),
                             ZPixmap, 0, NULL, dest_im_width, dest_im_height,
                             32, 0);
      dest_im->data = ZnMalloc(dest_im->bytes_per_line * dest_im->height);
      memset(dest_im->data, 0, dest_im->bytes_per_line * dest_im->height);

      pixmap = ZnImagePixmap(icon->image, wi->win);
      photo_region = ZnImageRegion(icon->image);
      clip = TkCreateRegion();
      /*
       * ZnImageRegion may fail: perl/Tk 800.24 doesn't support
       * some internal TkPhoto functions.
       * This is a workaround using a rectangular region based
       * on the image size.
       */
      if (photo_region == NULL) {
        XRectangle rect;
        rect.x = rect.y = 0;
        rect.width = w;
        rect.height = h;
        TkUnionRectWithRegion(&rect, clip, clip);
      }
      else {
        ZnUnionRegion(clip, photo_region, clip);
      }
      XSetForeground(wi->dpy, mask_gc, 1);
      TkSetRegion(wi->dpy, mask_gc, clip);
      XFillRectangle(wi->dpy, mask, mask_gc, 0, 0, w, h);
  
      src_mask = XGetImage(wi->dpy, mask, 0, 0, w, h, 1, XYPixmap);
      src_im = XGetImage(wi->dpy, pixmap, 0, 0, w, h, ~0L, ZPixmap);

      box[0] = icon->dev[0];
      box[1] = icon->dev[1];
      box[2] = icon->dev[3];
      box[3] = icon->dev[2];
      for (i = 0; i < 4; i++) {
        box[i].x -= item->item_bounding_box.orig.x;
        box[i].y -= item->item_bounding_box.orig.y;
        box[i].x = ZnNearestInt(box[i].x);
        box[i].y = ZnNearestInt(box[i].y);
      }

      ZnMapImage(src_mask, dest_mask, box);
      ZnMapImage(src_im, dest_im, box);

      ZnCurrentClip(wi, &current_clip, &current_clip_box, NULL);
      TkSetRegion(wi->dpy, mask_gc, current_clip);
      XSetClipOrigin(wi->dpy, mask_gc,
                     (int) -item->item_bounding_box.orig.x, (int) -item->item_bounding_box.orig.y);
      TkPutImage(NULL, 0,wi->dpy, mask, mask_gc, dest_mask,
                 0, 0, 0, 0, dest_im_width, dest_im_height);
      TkPutImage(NULL, 0, wi->dpy, drw, gc, dest_im,
                0, 0, 0, 0, dest_im_width, dest_im_height);

      XSetClipMask(wi->dpy, gc, mask);
      XSetClipOrigin(wi->dpy, gc,
                     (int) item->item_bounding_box.orig.x,
                     (int) item->item_bounding_box.orig.y);
      XCopyArea(wi->dpy, drw, wi->draw_buffer, gc,
                0, 0, dest_im_width, dest_im_height,
                (int) item->item_bounding_box.orig.x,
                (int) item->item_bounding_box.orig.y);

      XFreeGC(wi->dpy, gc);
      XFreeGC(wi->dpy, mask_gc);
      Tk_FreePixmap(wi->dpy, drw);
      Tk_FreePixmap(wi->dpy, mask);
      XDestroyImage(src_mask);
      XDestroyImage(dest_mask);
      XDestroyImage(src_im);
      XDestroyImage(dest_im);
    }
  }
  else {
    /*
     * If the current transform is a pure translation, it is
     * possible to optimize by directly drawing to the X back
     * buffer. Else, we draw in a temporary buffer, get
     * its content as an image, transform the image into another
     * one and use this last image as a mask to draw in the X
     * back buffer.
     */
    pixmap = ZnImagePixmap(icon->image, wi->win);
    if (ZnTransfoIsTranslation(item->wi->current_transfo)) {
      ZnCurrentClip(wi, NULL, &clip_box, &simple);
      if (simple) {
        ZnIntersectBBox(&box, clip_box, &inter);
        box = inter;
      }
      values.fill_style = FillStippled;
      values.stipple = pixmap;
      values.ts_x_origin = (int) icon->dev->x;
      values.ts_y_origin = (int) icon->dev->y;
      values.foreground = ZnGetGradientPixel(icon->color, 0.0);
      gc_mask |= GCFillStyle|GCStipple|GCTileStipXOrigin|GCTileStipYOrigin|GCForeground;
      XChangeGC(wi->dpy, wi->gc, gc_mask, &values);
      XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc,
                     (int) box.orig.x,
                     (int) box.orig.y,
                     (unsigned int) (box.corner.x-box.orig.x),
                     (unsigned int) (box.corner.y-box.orig.y));
    }
    else {
      ZnPoint       box[4];
      int           i;
      XImage        *dest_im, *src_im;
      Pixmap        drw;
      unsigned int  dest_im_width, dest_im_height;
      unsigned int  max_width, max_height;
      GC            gc;

      dest_im_width = (unsigned int) (item->item_bounding_box.corner.x -
                                      item->item_bounding_box.orig.x);
      max_width = MAX(dest_im_width, (unsigned int) w);
      dest_im_height = (unsigned int) (item->item_bounding_box.corner.y -
                                       item->item_bounding_box.orig.y);
      max_height = MAX(dest_im_height, (unsigned int) h);
      
      drw = Tk_GetPixmap(wi->dpy, wi->draw_buffer, max_width, max_height, 1);
      gc = XCreateGC(wi->dpy, drw, 0, NULL);
      XSetForeground(wi->dpy, gc, 0);
      XFillRectangle(wi->dpy, drw, gc, 0, 0, max_width, max_height);
      dest_im = XCreateImage(wi->dpy, Tk_Visual(wi->win), 1,
                             XYPixmap, 0, NULL, dest_im_width, dest_im_height,
                             8, 0);
      dest_im->data = ZnMalloc(dest_im->bytes_per_line * dest_im->height);
      memset(dest_im->data, 0, dest_im->bytes_per_line * dest_im->height);

      values.fill_style = FillStippled;
      values.stipple = pixmap;
      values.ts_x_origin = 0;
      values.ts_y_origin = 0;
      values.foreground = 1;
      gc_mask |= GCFillStyle|GCStipple|GCTileStipXOrigin|GCTileStipYOrigin|GCForeground;
      XChangeGC(wi->dpy, gc, gc_mask, &values);
      XFillRectangle(wi->dpy, drw, gc, 0, 0, w, h);

      src_im = XGetImage(wi->dpy, drw, 0, 0, w, h, 1, XYPixmap);

      box[0] = icon->dev[0];
      box[1] = icon->dev[1];
      box[2] = icon->dev[3];
      box[3] = icon->dev[2];
      for (i = 0; i < 4; i++) {
        box[i].x -= item->item_bounding_box.orig.x;
        box[i].y -= item->item_bounding_box.orig.y;
        box[i].x = ZnNearestInt(box[i].x);
        box[i].y = ZnNearestInt(box[i].y);
      }

      ZnMapImage(src_im, dest_im, box);

      TkPutImage(NULL, 0,wi->dpy, drw, gc, dest_im,
                 0, 0, 0, 0, dest_im_width, dest_im_height);

      values.foreground = ZnGetGradientPixel(icon->color, 0.0);
      values.stipple = drw;
      values.ts_x_origin = (int) item->item_bounding_box.orig.x;
      values.ts_y_origin = (int) item->item_bounding_box.orig.y;
      values.fill_style = FillStippled;
      XChangeGC(wi->dpy, wi->gc,
                GCFillStyle|GCStipple|GCTileStipXOrigin|GCTileStipYOrigin|GCForeground,
                &values);
      XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc,
                     (int) item->item_bounding_box.orig.x,
                     (int) item->item_bounding_box.orig.y,
                     (int) dest_im_width, (int) dest_im_height);

      XFreeGC(wi->dpy, gc);
      Tk_FreePixmap(wi->dpy, drw);
      XDestroyImage(src_im);
      XDestroyImage(dest_im);
    }
  }
}


/*
 **********************************************************************************
 *
 * Render --
 *
 **********************************************************************************
 */
#ifdef GL
static void
Render(ZnItem   item)
{
  ZnWInfo       *wi = item->wi;
  IconItem      icon = (IconItem) item;
  
  if (icon->image != ZnUnspecifiedImage) {
    ZnRenderImage(wi, icon->image, icon->color, icon->dev,
                  ZnImageIsBitmap(icon->image));
  }
}
#else
static void
Render(ZnItem   item)
{
}
#endif


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
  return (ISSET(item->flags, ZN_SENSITIVE_BIT) &&
          item->parent->class->IsSensitive(item->parent, ZN_NO_PART));
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
  IconItem      icon = (IconItem) item;
  ZnWInfo       *wi = item->wi;
  double        dist;
  double        off_dist = MAX(1, wi->pick_aperture+1);
  int           x, y, width, height;
  ZnPoint       p;
  ZnBBox        bbox;
  ZnTransfo     t;

  if (icon->image == ZnUnspecifiedImage) {
    return 1.0e40;
  }

  ZnTransfoInvert(wi->current_transfo, &t);
  ZnTransformPoint(&t, ps->point, &p);
  ZnTransformPoint(&t, &icon->dev[0], &bbox.orig);
  ZnSizeOfImage(icon->image, &width, &height);
  bbox.corner.x = bbox.orig.x + width;
  bbox.corner.y = bbox.orig.y + height;
  dist = ZnRectangleToPointDist(&bbox, &p);
  x = (int) (p.x - bbox.orig.x);
  y = (int) (p.y - bbox.orig.y);
  /*printf("dist: %g\n", dist);*/

  /*
   * If inside the icon rectangle, try to see if the point
   * is actually on the image or not. If it lies in an
   * area that is between pick_aperture+1 around the external
   * rectangle and the actual shape, the distance will be reported
   * as pick_aperture+1. Inside the actual shape it will be
   * reported as 0. This is a kludge, there is currently
   * no means to compute the real distance in the icon's
   * vicinity.
   */
  if (dist <= 0) {
    dist = 0.0;
    if (icon->image != ZnUnspecifiedImage) {
      if (ZnPointInImage(icon->image, x, y)) {
        /*
         * The point is actually on the image shape.
         */
        return dist;
      }
      else {
        /*
         * The point is not on the shape but still
         * inside the image's bounding box.
         */
        return off_dist;
      }
    }
    else {
      return dist;
    }
  }
  else if (dist < off_dist) {
    dist = off_dist;
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
static int
PostScript(ZnItem item,
           ZnBool prepass,
           ZnBBox *area)
{
  ZnWInfo       *wi = item->wi;
  IconItem      icon = (IconItem) item;
  int           w, h, result;
  ZnPoint       origin;
  char          path[500];

  if (prepass || (icon->image == ZnUnspecifiedImage)) {
    return TCL_OK;
  }
  
  ZnSizeOfImage(icon->image, &w, &h);

  ComputeTransfoAndOrigin(item, &origin);
  
  sprintf(path, "/InitialTransform load setmatrix\n"
          "[%.15g %.15g %.15g %.15g %.15g %.15g] concat\n"
          "1 -1 scale\n"
          "%.15g %.15g translate\n",
          wi->current_transfo->_[0][0], wi->current_transfo->_[0][1], 
          wi->current_transfo->_[1][0], wi->current_transfo->_[1][1], 
          wi->current_transfo->_[2][0], wi->current_transfo->_[2][1],
          origin.x, origin.y - h);
  Tcl_AppendResult(wi->interp, path, NULL);
  
  if (ZnImageIsBitmap(icon->image)) {
    if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                           ZnGetGradientColor(icon->color, 0.0, NULL)) != TCL_OK) {
      return TCL_ERROR;
    }
    result = ZnPostscriptBitmap(wi->interp, wi->win, wi->ps_info,
                                icon->image, 0, 0, w, h);
  }
  else {
    result = Tk_PostscriptImage(ZnImageTkImage(icon->image), wi->interp, wi->win,
                                wi->ps_info, 0, 0, w, h, prepass);
  }
  
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
  IconItem      icon = (IconItem) item;
  
  if (icon->image == ZnUnspecifiedImage) {
    *p = *icon->dev;
  }
  else {
    ZnPoint q[4];
    q[0] = icon->dev[0];
    q[1] = icon->dev[1];
    q[2] = icon->dev[3];
    q[3] = icon->dev[2];
    ZnRectOrigin2Anchor(q, anchor, p);
  }
}


/*
 **********************************************************************************
 *
 * GetClipVertices --
 *      Get the clipping shape.
 *      Never ever call ZnTriFree on the tristrip returned by GetClipVertices.
 *
 **********************************************************************************
 */
static ZnBool
GetClipVertices(ZnItem          item,
                ZnTriStrip      *tristrip)
{
  IconItem      icon = (IconItem) item;
  ZnPoint       *points;
  
  ZnListAssertSize(ZnWorkPoints, 4);
  points = ZnListArray(ZnWorkPoints);
  points[0] = icon->dev[0];
  points[1] = icon->dev[1];
  points[2] = icon->dev[3];
  points[3] = icon->dev[2];
  ZnTriStrip1(tristrip, points, 4, False);
  
  return False;
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
  IconItem      icon = (IconItem) item;
  
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " icons can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on icons", NULL);
      return TCL_ERROR;
    }
    icon->pos = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    *num_pts = 1;
    *pts = &icon->pos;
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
static ZnItemClassStruct ICON_ITEM_CLASS = {
  "icon",
  sizeof(IconItemStruct),
  icon_attrs,
  0,                    /* num_parts */
  ZN_CLASS_HAS_ANCHORS|ZN_CLASS_ONE_COORD, /* flags */
  Tk_Offset(IconItemStruct, pos),
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
  Render,
  IsSensitive,
  Pick,
  NULL,                 /* PickVertex */
  PostScript
};

ZnItemClassId ZnIcon = (ZnItemClassId) &ICON_ITEM_CLASS;
