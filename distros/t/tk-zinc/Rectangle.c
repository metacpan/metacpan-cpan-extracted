/*
 * Rectangle.c -- Implementation of rectangle item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Fri Dec  2 14:47:42 1994
 *
 * $Id: Rectangle.c,v 1.71 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1994 - 2005 CENA, Patrick Lecoanet --
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
#include "Color.h"
#include "WidgetInfo.h"
#include "tkZinc.h"


static const char rcsid[] = "$Id: Rectangle.c,v 1.71 2005/05/10 07:59:48 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";

/*
 * Bit offset of flags.
 */
#define FILLED_BIT      1       /* If the rectangle is filled with color/pattern */
#define ALIGNED_BIT     2


/*
 **********************************************************************************
 *
 * Specific Rectangle item record
 *
 **********************************************************************************
 */

typedef struct _RectangleItemStruct {
  ZnItemStruct  header;

  /* Public data */
  ZnPoint       coords[2];
  unsigned short flags;
  ZnReliefStyle relief;
  ZnLineStyle   line_style;
  ZnDim         line_width;
  ZnGradient    *line_color;
  ZnImage       line_pattern;
  ZnGradient    *fill_color;
  ZnImage       tile;
  
  /* Private data */
  ZnPoint       dev[4];
  ZnGradient    *gradient;
  ZnPoint       *grad_geo;
} RectangleItemStruct, *RectangleItem;


static ZnAttrConfig     rect_attrs[] = {
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(RectangleItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(RectangleItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(RectangleItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-fillcolor", NULL,
    Tk_Offset(RectangleItemStruct, fill_color), 0,
    ZN_COORDS_FLAG|ZN_BORDER_FLAG, False },
  { ZN_CONFIG_BOOL, "-filled", NULL,
    Tk_Offset(RectangleItemStruct, flags), FILLED_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-fillpattern", NULL,
    Tk_Offset(RectangleItemStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-linecolor", NULL,
    Tk_Offset(RectangleItemStruct, line_color), 0,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BITMAP, "-linepattern", NULL,
    Tk_Offset(RectangleItemStruct, line_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-linestyle", NULL,
    Tk_Offset(RectangleItemStruct, line_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-linewidth", NULL,
    Tk_Offset(RectangleItemStruct, line_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(RectangleItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_RELIEF, "-relief", NULL, Tk_Offset(RectangleItemStruct, relief), 0,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(RectangleItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(RectangleItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_IMAGE, "-tile", NULL,
    Tk_Offset(RectangleItemStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(RectangleItemStruct, header.flags), ZN_VISIBLE_BIT,
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
  RectangleItem rect = (RectangleItem) item;
  unsigned int  num_points;
  ZnPoint       *points;

  rect->gradient = NULL;
  rect->grad_geo = NULL;

  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 1;
  
  if (*argc < 1) {
    Tcl_AppendResult(wi->interp, " rectangle coords expected", NULL);
    return TCL_ERROR;
  }
  if (ZnParseCoordList(wi, (*args)[0], &points,
                       NULL, &num_points, NULL) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (num_points != 2) {
    Tcl_AppendResult(wi->interp, " malformed rectangle coords", NULL);
    return TCL_ERROR;
  };
  rect->coords[0] = points[0];
  rect->coords[1] = points[1];
  (*args)++;
  (*argc)--;
  
  CLEAR(rect->flags, FILLED_BIT);
  rect->relief = ZN_RELIEF_FLAT;
  rect->line_style = ZN_LINE_SIMPLE;
  rect->line_width = 1;
  rect->line_pattern = ZnUnspecifiedImage;
  rect->tile = ZnUnspecifiedImage;
  rect->line_color = ZnGetGradientByValue(wi->fore_color);
  rect->fill_color = ZnGetGradientByValue(wi->fore_color);
  
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
  RectangleItem rect = (RectangleItem) item;

  if (rect->gradient) {
    rect->gradient = ZnGetGradientByValue(rect->gradient);
  }
  if (rect->tile != ZnUnspecifiedImage) {
    rect->tile = ZnGetImageByValue(rect->tile, ZnUpdateItemImage, item);
  }
  if (rect->line_pattern != ZnUnspecifiedImage) {
    rect->line_pattern = ZnGetImageByValue(rect->line_pattern, NULL, NULL);
  }
  rect->line_color = ZnGetGradientByValue(rect->line_color);
  rect->fill_color = ZnGetGradientByValue(rect->fill_color);
  rect->grad_geo = NULL;
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
  RectangleItem rect = (RectangleItem) item;

  if (rect->tile != ZnUnspecifiedImage) {
    ZnFreeImage(rect->tile, ZnUpdateItemImage, item);
    rect->tile = ZnUnspecifiedImage;
  }
  if (rect->gradient) {
    ZnFreeGradient(rect->gradient);
  }
  if (rect->line_pattern != ZnUnspecifiedImage) {
    ZnFreeImage(rect->line_pattern, NULL, NULL);
    rect->line_pattern = ZnUnspecifiedImage;
  }
  if (rect->grad_geo) {
    ZnFree(rect->grad_geo);
  }
  ZnFreeGradient(rect->fill_color);
  ZnFreeGradient(rect->line_color);
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
  ZnWInfo       *wi = item->wi;
  RectangleItem rect = (RectangleItem) item;
  int           status = TCL_OK;
  XColor        *color;
  unsigned short alpha;
  
  status = ZnConfigureAttributes(wi, item, item, rect_attrs, argc, argv, flags);
  
  if (rect->gradient &&
      (ISSET(*flags, ZN_BORDER_FLAG) || (rect->relief == ZN_RELIEF_FLAT))) {
    ZnFreeGradient(rect->gradient);
    rect->gradient = NULL;
  }
  if ((rect->relief != ZN_RELIEF_FLAT) && !rect->gradient) {
    color = ZnGetGradientColor(rect->line_color, 51.0, &alpha);
    rect->gradient = ZnGetReliefGradient(wi->interp, wi->win,
                                         Tk_NameOfColor(color), alpha);
    if (rect->gradient == NULL) {
      status = TCL_ERROR;
    }
  }

  return status;
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
  if (ZnQueryAttribute(item->wi->interp, item, rect_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }

  return TCL_OK;
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
  ZnWInfo       *wi = item->wi;
  RectangleItem rect = (RectangleItem) item;
  ZnPoint       p[4];
  int           i;
  ZnBool        aligned;
  ZnDim         delta, lw2;
  
  ZnResetBBox(&item->item_bounding_box);
  if (!rect->line_width && ISCLEAR(rect->flags, FILLED_BIT)) {
    return;
  }

  p[0] = rect->coords[0];
  p[2] = rect->coords[1];
  p[1].x = p[2].x;
  p[1].y = p[0].y;
  p[3].x = p[0].x;
  p[3].y = p[2].y;
  ZnTransformPoints(wi->current_transfo, p, rect->dev, 4);
  for (i = 0; i < 4; i++) {
    rect->dev[i].x = ZnNearestInt(rect->dev[i].x);
    rect->dev[i].y = ZnNearestInt(rect->dev[i].y);
  }

  /*
   * Add all points to the bounding box. Then expand by the line
   * width to account for mitered corners. This is an overestimate.
   */
  ZnAddPointsToBBox(&item->item_bounding_box, rect->dev, 4);
  if (rect->line_width > 0) {
    lw2 = rect->line_width/2.0;
    item->item_bounding_box.orig.x -= lw2;
    item->item_bounding_box.orig.y -= lw2;
    item->item_bounding_box.corner.x += lw2;
    item->item_bounding_box.corner.y += lw2;
  }
  item->item_bounding_box.orig.x -= 0.5;
  item->item_bounding_box.orig.y -= 0.5;
  item->item_bounding_box.corner.x += 0.5;
  item->item_bounding_box.corner.y += 0.5;
  
  delta = rect->dev[0].y - rect->dev[1].y;
  delta = ABS(delta);
  aligned = delta < X_PRECISION_LIMIT;
  delta = rect->dev[0].x - rect->dev[3].x;
  delta = ABS(delta);
  aligned &= delta < X_PRECISION_LIMIT;
  ASSIGN(rect->flags, ALIGNED_BIT, aligned);
  
#ifdef GL
  /*
   * Compute the gradient geometry
   */
  if (!ZnGradientFlat(rect->fill_color)) {
    ZnPoly      shape;
    
    if (rect->fill_color->type == ZN_AXIAL_GRADIENT) {
      int       angle = rect->fill_color->angle;
      
      if ((angle != 0) && (angle != 90) && (angle != 180) && (angle != 270)) {
        if (!rect->grad_geo) {
          rect->grad_geo = ZnMalloc(6*sizeof(ZnPoint));
        }
        ZnPolyContour1(&shape, p, 4, False);
        ZnComputeGradient(rect->fill_color, wi, &shape, rect->grad_geo);
      }
      else {
        goto free_ggeo;
      }
    }
    else {
      if (!rect->grad_geo) {
        rect->grad_geo = ZnMalloc(6*sizeof(ZnPoint));
      }
      if (rect->fill_color->type == ZN_PATH_GRADIENT) {
        ZnPolyContour1(&shape, rect->coords, 2, False);
      }
      else {
        ZnPolyContour1(&shape, p, 4, False);
      }
      ZnComputeGradient(rect->fill_color, wi, &shape, rect->grad_geo);
    }
  }
  else {
  free_ggeo:
    if (rect->grad_geo) {
      ZnFree(rect->grad_geo);
      rect->grad_geo = NULL;
    }
  }
#endif
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
  RectangleItem rect = (RectangleItem) item;
  int           result, result2;
  ZnBBox        *area = ta->area;

  result = -1;

  if (ISSET(rect->flags, FILLED_BIT)) {
    result = ZnPolygonInBBox(rect->dev, 4, area, NULL);
    if (result == 0) {
      return 0;
    }
  }
  if (rect->line_width > 0) {
    int         i;
    ZnPoint     pts[5];

    for (i = 0; i < 4; i++) {
      pts[i] = rect->dev[i];
    }
    pts[4] = pts[0];
    result2 = ZnPolylineInBBox(pts, 5, rect->line_width,
                               CapProjecting, JoinMiter, area);
    if (ISCLEAR(rect->flags, FILLED_BIT)) {
      if (result2 == 0) {
        return 0;
      }
      result = result2;
    }
    else if (result2 != result) {
      return 0;
    }
  }

  return result;
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
  ZnWInfo       *wi  = item->wi;
  RectangleItem rect = (RectangleItem) item;
  XGCValues     values;
  unsigned int  i, gc_mask;
  XRectangle    r;
  XPoint        xp[5];
  
  if (ISSET(rect->flags, ALIGNED_BIT)) {
    if (rect->dev[0].x < rect->dev[2].x) {
      r.x = (int) rect->dev[0].x;
      r.width = ((int) rect->dev[2].x) - r.x;
    }
    else {
      r.x = (int) rect->dev[2].x;
      r.width = ((int) rect->dev[0].x) - r.x;
    }
    if (rect->dev[0].y < rect->dev[2].y) {
      r.y = (int) rect->dev[0].y;
      r.height = ((int) rect->dev[2].y) - r.y;
    }
    else {
      r.y = (int) rect->dev[2].y;
      r.height = ((int) rect->dev[0].y) - r.y;
    }
  }
  else {
    for (i = 0; i < 4; i++) {
      xp[i].x = (int) rect->dev[i].x;
      xp[i].y = (int) rect->dev[i].y;
    }
    xp[i] = xp[0];
  }
  
  /*
   * Fill if requested.
   */
  if (ISSET(rect->flags, FILLED_BIT)) {
    values.foreground = ZnGetGradientPixel(rect->fill_color, 0.0);
    if (rect->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(rect->tile)) { /* Fill tiled */
        values.fill_style = FillTiled;
        values.tile = ZnImagePixmap(rect->tile, wi->win);
        if (ISSET(rect->flags, ALIGNED_BIT)) {
          values.ts_x_origin = (int) r.x;
          values.ts_y_origin = (int) r.y;
        }
        else {
          values.ts_x_origin = (int) item->item_bounding_box.orig.x;
          values.ts_y_origin = (int) item->item_bounding_box.orig.y;
        }
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCFillStyle|GCTile, &values);
      }
      else {
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(rect->tile, wi->win);
        if (ISSET(rect->flags, ALIGNED_BIT)) {
          values.ts_x_origin = (int) r.x;
          values.ts_y_origin = (int) r.y;
        }
        else {
          values.ts_x_origin = (int) item->item_bounding_box.orig.x;
          values.ts_y_origin = (int) item->item_bounding_box.orig.y;
        }
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCFillStyle|GCStipple|GCForeground,
                  &values);
      }
    }
    else { /* Fill solid */
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc, GCForeground | GCFillStyle, &values);
    }
    if (ISSET(rect->flags, ALIGNED_BIT)) {
      XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc, r.x, r.y,
                     r.width, r.height);
    }
    else {
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, 4, Convex, CoordModeOrigin);
    }
  }

  /* Draw the outline */
  if (rect->line_width) {
    if (rect->relief != ZN_RELIEF_FLAT) {
      if (ISSET(rect->flags, ALIGNED_BIT)) {
        ZnDrawRectangleRelief(wi, rect->relief, rect->gradient,
                              &r, rect->line_width);
      }
      else {
        ZnPoint p[5];
        for (i = 0; i < 4; i++) {
          p[4-i].x = rect->dev[i].x;
          p[4-i].y = rect->dev[i].y;
        }
        p[0] = p[4];
        ZnDrawPolygonRelief(wi, rect->relief, rect->gradient,
                            p, 5, rect->line_width);
      }
    }
    else {
      ZnSetLineStyle(wi, rect->line_style);
      gc_mask = GCFillStyle|GCLineWidth|GCForeground|GCJoinStyle;
      values.foreground = ZnGetGradientPixel(rect->line_color, 0.0);
      values.line_width = (rect->line_width == 1) ? 0 : (int) rect->line_width;
      values.join_style = JoinMiter;
      if (ISCLEAR(rect->flags, ALIGNED_BIT)) {
        gc_mask |= GCCapStyle;
        values.cap_style = CapProjecting;
      }
      if (rect->line_pattern == ZnUnspecifiedImage) {
        values.fill_style = FillSolid;
        XChangeGC(wi->dpy, wi->gc, gc_mask, &values);
      }
      else {
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(rect->line_pattern, wi->win);
        gc_mask |= GCStipple;
        XChangeGC(wi->dpy, wi->gc, gc_mask, &values);
      }
      if (ISSET(rect->flags, ALIGNED_BIT)) {
        XDrawRectangle(wi->dpy, wi->draw_buffer, wi->gc, r.x, r.y,
                       r.width, r.height);
      }
      else {
        XDrawLines(wi->dpy, wi->draw_buffer, wi->gc, xp, 5, CoordModeOrigin);
      }
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
RectRenderCB(void *closure)
{
  RectangleItem rect = (RectangleItem) closure;

  glBegin(GL_TRIANGLE_STRIP);
  glVertex2d(rect->dev[0].x, rect->dev[0].y);
  glVertex2d(rect->dev[3].x, rect->dev[3].y);
  glVertex2d(rect->dev[1].x, rect->dev[1].y);
  glVertex2d(rect->dev[2].x, rect->dev[2].y);
  glEnd();
}
#endif

#ifdef GL
static void
Render(ZnItem   item)
{
  ZnWInfo       *wi  = item->wi;
  RectangleItem rect = (RectangleItem) item;
  int           i;

#ifdef GL_LIST
  if (!item->gl_list) {
    item->gl_list = glGenLists(1);
    glNewList(item->gl_list, GL_COMPILE);
#endif
    if (ISSET(rect->flags, FILLED_BIT)) {
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      
      if (!ZnGradientFlat(rect->fill_color)) {
        ZnBool  fast = (rect->fill_color->type == ZN_AXIAL_GRADIENT) && !rect->grad_geo;
        ZnPoly  poly;
        
        ZnPolyContour1(&poly, rect->dev, 4, False);
        ZnRenderGradient(wi, rect->fill_color,
                         fast ? NULL: RectRenderCB, rect,
                         fast ? rect->dev : rect->grad_geo, &poly);
      }
      else if (rect->tile != ZnUnspecifiedImage) { /* Fill tiled/patterned */
        if (ISSET(rect->flags, ALIGNED_BIT)) {
          ZnBBox bbox;

          bbox.orig = rect->dev[0];
          bbox.corner = rect->dev[2];
          ZnRenderTile(wi, rect->tile, rect->fill_color, NULL, NULL, (ZnPoint *) &bbox);
        }
        else {
          ZnRenderTile(wi, rect->tile, rect->fill_color, RectRenderCB,
                       rect, (ZnPoint *) &item->item_bounding_box);
        }
      }
      else {
        unsigned short alpha;
        XColor *color = ZnGetGradientColor(rect->fill_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        RectRenderCB(rect);
      }
    }
    
    if (rect->line_width) {
      ZnPoint p[5];
      for (i = 0; i < 4; i++) {
        p[4-i].x = rect->dev[i].x;
        p[4-i].y = rect->dev[i].y;
      }
      p[0] = p[4];
      if (rect->relief != ZN_RELIEF_FLAT) {
        ZnRenderPolygonRelief(wi, rect->relief, rect->gradient, False,
                              p, 5, rect->line_width);
      }
      else {
        ZnRenderPolyline(wi, p, 5, rect->line_width,
                         rect->line_style, CapRound, JoinMiter,
                         NULL, NULL, rect->line_color);
      }
    }
#ifdef GL_LIST    
    glEndList();
  }
  
  glCallList(item->gl_list);
#endif
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
  RectangleItem rect = (RectangleItem) item;
  double        best_dist;
  ZnPoint       *p = ps->point;

  best_dist = ZnPolygonToPointDist(rect->dev, 4, p);

  if (ISSET(rect->flags, FILLED_BIT)) {
    if (best_dist <= 0.0) {
      return 0.0;
    }
  }
  best_dist = ABS(best_dist);
  
  if (rect->line_width > 1) {
    double      dist;
    int         i;
    ZnPoint     pts[5];

    for (i = 0; i < 4; i++) {
      pts[i] = rect->dev[i];
    }
    pts[4] = pts[0];
    dist = ZnPolylineToPointDist(pts, 5, rect->line_width,
                                 CapProjecting, JoinMiter, p);
    if (dist <= 0.0) {
      return 0.0;
    }
    best_dist = MIN(dist, best_dist);
  }

  return best_dist;
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
  RectangleItem rect = (RectangleItem) item;
  char          path[500];

  if (ISCLEAR(rect->flags, FILLED_BIT) && (rect->line_width == 0)) {
    return TCL_OK;
  }

  /*
   * Create the rectangle path.
   */
  sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto %.15g %.15g lineto %.15g %.15g lineto closepath\n",
          rect->dev[0].x, rect->dev[0].y, rect->dev[1].x, rect->dev[1].y,
          rect->dev[2].x, rect->dev[2].y, rect->dev[3].x, rect->dev[3].y);
  Tcl_AppendResult(wi->interp, path, NULL);

  /*
   * Emit code to draw the filled area.
   */
  if (ISSET(rect->flags, FILLED_BIT)) {
    if (rect->line_width) {
      Tcl_AppendResult(wi->interp, "gsave\n", NULL);
    }
    if (!ZnGradientFlat(rect->fill_color)) {
      if (ZnPostscriptGradient(wi->interp, wi->ps_info, rect->fill_color,
                               rect->grad_geo ? rect->grad_geo : rect->dev, NULL) != TCL_OK) {
        return TCL_ERROR;
      }
    }
    else if (rect->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(rect->tile)) { /* Fill tiled */
        if (ZnPostscriptTile(wi->interp, wi->win, wi->ps_info, rect->tile) != TCL_OK) {
          return TCL_ERROR;
        }
      }
      else { /* Fill stippled */
        if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                               ZnGetGradientColor(rect->fill_color, 0.0, NULL)) != TCL_OK) {
          return TCL_ERROR;
        }
        Tcl_AppendResult(wi->interp, "clip ", NULL);
        if (ZnPostscriptStipple(wi->interp, wi->win, wi->ps_info, rect->tile) != TCL_OK) {
          return TCL_ERROR;
        }
      }
    }
    else { /* Fill solid */
      if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                             ZnGetGradientColor(rect->fill_color, 0.0, NULL)) != TCL_OK) {
        return TCL_ERROR;
      }
      Tcl_AppendResult(wi->interp, "fill\n", NULL);
    }
    if (rect->line_width) {
      Tcl_AppendResult(wi->interp, "grestore\n", NULL);
    }
  }

  /*
   * Then emit code code to stroke the outline.
   */
  if (rect->line_width) {
    if (rect->relief != ZN_RELIEF_FLAT) {
      /* TODO No support yet */
    }
    else {
      Tcl_AppendResult(wi->interp, "0 setlinejoin 2 setlinecap\n", NULL);
      if (ZnPostscriptOutline(wi->interp, wi->ps_info, wi->win,
                              rect->line_width, rect->line_style,
                              rect->line_color, rect->line_pattern) != TCL_OK) {
        return TCL_ERROR;
      }
    }
  }

  return TCL_OK;
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
  RectangleItem rect = (RectangleItem) item;
  ZnPoint       *points;

  if (ISSET(rect->flags, ALIGNED_BIT)) {
    ZnListAssertSize(ZnWorkPoints, 2);
    points = ZnListArray(ZnWorkPoints);
    ZnTriStrip1(tristrip, points, 2, False);
    tristrip->strips[0].fan = False;
  
    if (rect->dev[0].x < rect->dev[2].x) {
      points[0].x = rect->dev[0].x;
      points[1].x = rect->dev[2].x+1.0;
    }
    else {
      points[0].x = rect->dev[2].x;
      points[1].x = rect->dev[0].x+1.0;
    }
    if (rect->dev[0].y < rect->dev[2].y) {
      points[0].y = rect->dev[0].y;
      points[1].y = rect->dev[2].y+1.0;
    }
    else {
      points[0].y = rect->dev[2].y;
      points[1].y = rect->dev[0].y+1.0;
    }
  }
  else {
    ZnListAssertSize(ZnWorkPoints, 4);
    points = ZnListArray(ZnWorkPoints);
    points[0] = rect->dev[1];
    points[1] = rect->dev[2];
    points[2] = rect->dev[0];
    points[3] = rect->dev[3];
    ZnTriStrip1(tristrip, points, 4, False);
  }

  return ISSET(rect->flags, ALIGNED_BIT);
}


/*
 **********************************************************************************
 *
 * Coords --
 *      Return or edit the item vertices.
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
  RectangleItem rect = (RectangleItem) item;

  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " rectangles can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if (cmd == ZN_COORDS_REPLACE_ALL) {
    if (*num_pts != 2) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 2 points on rectangles", NULL);
      return TCL_ERROR;
    }
    rect->coords[0] = (*pts)[0];
    rect->coords[1] = (*pts)[1];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if (cmd == ZN_COORDS_REPLACE) {
    if (*num_pts < 1) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need at least 1 point", NULL);
      return TCL_ERROR;
    }
    if (index < 0) {
      index += 2;
    }
    if ((index < 0) || (index > 1)) {
    range_err:
      Tcl_AppendResult(item->wi->interp,
                       " incorrect coord index, should be between -2 and 1", NULL);
      return TCL_ERROR;
    }
    rect->coords[index] = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if (cmd == ZN_COORDS_READ_ALL) {
    *num_pts = 2;
    *pts = rect->coords;
  }
  else if (cmd == ZN_COORDS_READ) {
    if (index < 0) {
      index += 2;
    }
    if ((index < 0) || (index > 1)) {
      goto range_err;
    }
    *num_pts = 1;
    *pts = &rect->coords[index];
  }

  return TCL_OK;
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
  ZnBBox *bbox = &item->item_bounding_box;

  ZnOrigin2Anchor(&bbox->orig,
                  bbox->corner.x - bbox->orig.x,
                  bbox->corner.y - bbox->orig.y,
                  anchor, p);
}


/*
 **********************************************************************************
 *
 * Exported functions struct --
 *
 **********************************************************************************
 */ 
static ZnItemClassStruct RECTANGLE_ITEM_CLASS = {
  "rectangle",
  sizeof(RectangleItemStruct),
  rect_attrs,
  0,                    /* num_parts */
  0,                    /* flags */
  -1,
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

ZnItemClassId ZnRectangle = (ZnItemClassId) &RECTANGLE_ITEM_CLASS;
