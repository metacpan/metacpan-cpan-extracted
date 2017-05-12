/*
 * Arc.c -- Implementation of Arc item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Wed Mar 30 16:24:09 1994
 *
 * $Id: Arc.c,v 1.62 2005/05/25 08:22:14 lecoanet Exp $
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


static const char rcsid[] = "$Id: Arc.c,v 1.62 2005/05/25 08:22:14 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 * Bit offset of flags.
 */
#define FILLED_BIT      1<<0    /* If the arc is filled with color/pattern */
#define CLOSED_BIT      1<<1    /* If the arc outline is closed */
#define PIE_SLICE_BIT   1<<2    /* If the arc is closed as a pie slice or a chord */

#define FIRST_END_OK    1<<3
#define LAST_END_OK     1<<4
#define USING_POLY_BIT  1<<5


static double Pick(ZnItem item, ZnPick ps);


/*
 **********************************************************************************
 *
 * Specific Arc item record.
 *
 **********************************************************************************
 */
typedef struct _ArcItemStruct {
  ZnItemStruct  header;
  
  /* Public data */
  ZnPoint       coords[2];
  int           start_angle;
  int           angle_extent;
  ZnImage       line_pattern;
  ZnGradient    *fill_color;
  ZnGradient    *line_color;
  ZnDim         line_width;
  ZnLineStyle   line_style;
  ZnLineEnd     first_end;
  ZnLineEnd     last_end;
  ZnImage       tile;
  unsigned short flags;

  /* Private data */
  ZnPoint       orig;
  ZnPoint       corner;
  ZnList        render_shape;
  ZnPoint       *grad_geo;
} ArcItemStruct, *ArcItem;


static ZnAttrConfig     arc_attrs[] = {
  { ZN_CONFIG_BOOL, "-closed", NULL,
    Tk_Offset(ArcItemStruct, flags), CLOSED_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(ArcItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(ArcItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(ArcItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ANGLE, "-extent", NULL,
    Tk_Offset(ArcItemStruct, angle_extent), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-fillcolor", NULL,
    Tk_Offset(ArcItemStruct, fill_color), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-filled", NULL,
    Tk_Offset(ArcItemStruct, flags), FILLED_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-fillpattern", NULL,
    Tk_Offset(ArcItemStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_END, "-firstend", NULL,
    Tk_Offset(ArcItemStruct, first_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_END, "-lastend", NULL,
    Tk_Offset(ArcItemStruct, last_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-linecolor", NULL,
    Tk_Offset(ArcItemStruct, line_color), 0,
    ZN_DRAW_FLAG|ZN_BORDER_FLAG, False },
  { ZN_CONFIG_BITMAP, "-linepattern", NULL,
    Tk_Offset(ArcItemStruct, line_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-linestyle", NULL,
    Tk_Offset(ArcItemStruct, line_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-linewidth", NULL,
    Tk_Offset(ArcItemStruct, line_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-pieslice", NULL,
    Tk_Offset(ArcItemStruct, flags), PIE_SLICE_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(ArcItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(ArcItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_ANGLE, "-startangle", NULL,
    Tk_Offset(ArcItemStruct, start_angle), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(ArcItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_IMAGE, "-tile", NULL,
    Tk_Offset(ArcItemStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(ArcItemStruct, header.flags), ZN_VISIBLE_BIT,
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
      Tcl_Obj *CONST    *args[])
{
  ZnWInfo       *wi = item->wi;
  ArcItem       arc = (ArcItem) item;
  unsigned int  num_points;
  ZnPoint       *points;

  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 1;

  arc->start_angle = 0;
  arc->angle_extent = 360;
  CLEAR(arc->flags, FILLED_BIT);
  CLEAR(arc->flags, CLOSED_BIT);
  CLEAR(arc->flags, PIE_SLICE_BIT);
  CLEAR(arc->flags, USING_POLY_BIT);
  arc->line_pattern = ZnUnspecifiedImage;
  arc->tile = ZnUnspecifiedImage;
  arc->line_style = ZN_LINE_SIMPLE;
  arc->line_width = 1;
  arc->first_end = arc->last_end = NULL;
  arc->render_shape = NULL;
  arc->grad_geo = NULL;
  
  if (*argc < 1) {
    Tcl_AppendResult(wi->interp, " arc coords expected", NULL);
    return TCL_ERROR;
  }
  if (ZnParseCoordList(wi, (*args)[0], &points,
                       NULL, &num_points, NULL) == TCL_ERROR) {
    return TCL_ERROR;
  }
  if (num_points != 2) {
    Tcl_AppendResult(wi->interp, " malformed arc coords", NULL);
    return TCL_ERROR;
  };
  arc->coords[0] = points[0];
  arc->coords[1] = points[1];
  (*args)++;
  (*argc)--;

  arc->fill_color = ZnGetGradientByValue(wi->fore_color);
  arc->line_color = ZnGetGradientByValue(wi->fore_color);
  
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
  ArcItem       arc = (ArcItem) item;

  if (arc->tile != ZnUnspecifiedImage) {
    arc->tile = ZnGetImageByValue(arc->tile, ZnUpdateItemImage, item);
  }
  if (arc->first_end) {
    ZnLineEndDuplicate(arc->first_end);
  }
  if (arc->last_end) {
    ZnLineEndDuplicate(arc->last_end);
  }
  if (arc->line_pattern != ZnUnspecifiedImage) {
    arc->line_pattern = ZnGetImageByValue(arc->line_pattern, NULL, NULL);
  }
  arc->line_color = ZnGetGradientByValue(arc->line_color);
  arc->fill_color = ZnGetGradientByValue(arc->fill_color);
  arc->grad_geo = NULL;
  if (arc->render_shape) {
    arc->render_shape = ZnListDuplicate(arc->render_shape);
  }
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
  ArcItem       arc = (ArcItem) item;

  if (arc->render_shape) {
    ZnListFree(arc->render_shape);
  }
  if (arc->first_end) {
    ZnLineEndDelete(arc->first_end);
  }
  if (arc->last_end) {
    ZnLineEndDelete(arc->last_end);
  }
  if (arc->tile != ZnUnspecifiedImage) {
    ZnFreeImage(arc->tile, ZnUpdateItemImage, item);
    arc->tile = ZnUnspecifiedImage;
  }
  if (arc->line_pattern != ZnUnspecifiedImage) {
    ZnFreeImage(arc->line_pattern, NULL, NULL);
    arc->line_pattern = ZnUnspecifiedImage;
  }
  if (arc->grad_geo) {
    ZnFree(arc->grad_geo);
  }
  ZnFreeGradient(arc->fill_color);
  ZnFreeGradient(arc->line_color);
}


/*
 **********************************************************************************
 *
 * Setup flags to control the precedence between the
 * graphical attributes.
 *
 **********************************************************************************
 */
static void
SetRenderFlags(ArcItem  arc)
{
  ASSIGN(arc->flags, FIRST_END_OK,
         (arc->first_end != NULL) && ISCLEAR(arc->flags, CLOSED_BIT) &&
         ISCLEAR(arc->flags, FILLED_BIT) && arc->line_width
         /*&& ISCLEAR(arc->flags, RELIEF_OK)*/);

  ASSIGN(arc->flags, LAST_END_OK,
         (arc->last_end != NULL) && ISCLEAR(arc->flags, CLOSED_BIT) &&
         ISCLEAR(arc->flags, FILLED_BIT) && arc->line_width
         /*&& ISCLEAR(arc->flags, RELIEF_OK)*/);
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
  ArcItem       arc = (ArcItem) item;
  int           status = TCL_OK;

  status = ZnConfigureAttributes(item->wi, item, item, arc_attrs, argc, argv, flags);
  if (arc->start_angle < 0) {
    arc->start_angle = 360 + arc->start_angle;
  }

  SetRenderFlags(arc);
  
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
      int                   argc,
      Tcl_Obj *CONST    argv[])
{
  if (ZnQueryAttribute(item->wi->interp, item, arc_attrs, argv[0]) == TCL_ERROR) {
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
UpdateRenderShape(ArcItem       arc)
{
  ZnPoint       *p_list, p, p2, o, o2;
  ZnReal        width, height, d;
  int           num_p, i, quality;
  ZnTransfo     *t = ((ZnItem) arc)->wi->current_transfo;
  
  if (!arc->render_shape) {
    arc->render_shape = ZnListNew(8, sizeof(ZnPoint));
  }
  o.x = (arc->coords[1].x + arc->coords[0].x)/2.0;
  o.y = (arc->coords[1].y + arc->coords[0].y)/2.0;
  width = (arc->coords[1].x - arc->coords[0].x)/2.0;
  height = (arc->coords[1].y - arc->coords[0].y)/2.0;
  d = MAX(width, height);
  quality = ZN_CIRCLE_COARSE;
  p_list = ZnGetCirclePoints(ISCLEAR(arc->flags, PIE_SLICE_BIT) ? 1 : 2,
                             quality,
                             ZnDegRad(arc->start_angle),
                             ZnDegRad(arc->angle_extent),
                             &num_p,
                             arc->render_shape);

  /*
   * Adapt the number of arc points to the radius of the arc.
   */
  p.x = o.x + p_list->x*d;
  p.y = o.y + p_list->y*d;
  ZnTransformPoint(t, &o, &o2);
  ZnTransformPoint(t, &p, &p2);
  d = hypot(o2.x-p2.x, o2.y-p2.y);
  if (d > 100.0) {
    quality = ZN_CIRCLE_FINER;
  }
  else if (d > 30.0) {
    quality = ZN_CIRCLE_FINE;
  }
  else if (d > 9.0) {
    quality = ZN_CIRCLE_MEDIUM;
  }

  if (quality != ZN_CIRCLE_COARSE) {
    p_list = ZnGetCirclePoints(ISCLEAR(arc->flags, PIE_SLICE_BIT) ? 1 : 2,
                               quality,
                               ZnDegRad(arc->start_angle),
                               ZnDegRad(arc->angle_extent),
                               &num_p,
                               arc->render_shape);
  }
    
  for (i = 0; i < num_p; i++, p_list++) {
    p.x = o.x + p_list->x*width;
    p.y = o.y + p_list->y*height;
    ZnTransformPoint(t, &p, p_list);
  }
}

static void
ComputeCoordinates(ZnItem       item,
                   ZnBool       force)
{
  ZnWInfo       *wi = item->wi;
  ArcItem       arc = (ArcItem) item;
  ZnReal        angle, tmp;
  unsigned int  num_p;
  ZnPoint       *p_list;
  ZnPoint       end_points[ZN_LINE_END_POINTS];
  
  ZnResetBBox(&item->item_bounding_box);
  /*
   * If it is neither filled nor outlined, then nothing to show.
   */
  if (!arc->line_width && ISCLEAR(arc->flags, FILLED_BIT)) {
    return;
  }

  /*
   * Special case for ellipse rotation and gradient.
   */
  if (!wi->render) {
    ZnTransfoDecompose(wi->current_transfo, NULL, NULL, &angle, NULL);
  }
  if (wi->render || (angle >= PRECISION_LIMIT) || (ABS(arc->angle_extent) != 360) ||
      ISSET(arc->flags, FIRST_END_OK) || ISSET(arc->flags, LAST_END_OK)) {
    SET(arc->flags, USING_POLY_BIT);
    UpdateRenderShape(arc);
    p_list = ZnListArray(arc->render_shape);
    num_p = ZnListSize(arc->render_shape);
    ZnAddPointsToBBox(&item->item_bounding_box, p_list, num_p);

    tmp = (arc->line_width + 1.0) / 2.0 + 1.0;
    item->item_bounding_box.orig.x -= tmp;
    item->item_bounding_box.orig.y -= tmp;
    item->item_bounding_box.corner.x += tmp;
    item->item_bounding_box.corner.y += tmp;
    
    /*
     * Add the arrows if any.
     */
    if (ISSET(arc->flags, FIRST_END_OK)) {
      ZnGetLineEnd(p_list, p_list+1, arc->line_width, CapRound,
                   arc->first_end, end_points);
      ZnAddPointsToBBox(&item->item_bounding_box, end_points, ZN_LINE_END_POINTS);
    }
    if (ISSET(arc->flags, LAST_END_OK)) {
      ZnGetLineEnd(&p_list[num_p-1], &p_list[num_p-2], arc->line_width, CapRound,
                   arc->last_end, end_points);
      ZnAddPointsToBBox(&item->item_bounding_box, end_points, ZN_LINE_END_POINTS);
    }

#ifdef GL
    if (!ZnGradientFlat(arc->fill_color)) {
      ZnPoly  shape;
      ZnPoint p[4];
      
      if (!arc->grad_geo) {
        arc->grad_geo = ZnMalloc(6*sizeof(ZnPoint));
      }
      if (arc->fill_color->type == ZN_AXIAL_GRADIENT) {
        p[0] = arc->coords[0];
        p[2] = arc->coords[1];
        p[1].x = p[2].x;
        p[1].y = p[0].y;
        p[3].x = p[0].x;
        p[3].y = p[2].y;
        ZnPolyContour1(&shape, p, 4, False);
      }
      else {
        ZnPolyContour1(&shape, arc->coords, 2, False);
      }
      ZnComputeGradient(arc->fill_color, wi, &shape, arc->grad_geo);
    }
    else {
      if (arc->grad_geo) {
        ZnFree(arc->grad_geo);
        arc->grad_geo = NULL;
      }
    }
#endif 
    return;
  }

  /*
   *******              ********                        **********
   * This part is for X drawn arcs: full extent, not rotated.
   *******              ********                        **********
   */
  CLEAR(arc->flags, USING_POLY_BIT);
  ZnTransformPoint(wi->current_transfo, &arc->coords[0], &arc->orig);
  ZnTransformPoint(wi->current_transfo, &arc->coords[1], &arc->corner);

  ZnAddPointToBBox(&item->item_bounding_box, arc->orig.x, arc->orig.y);
  ZnAddPointToBBox(&item->item_bounding_box, arc->corner.x, arc->corner.y);

  tmp = (arc->line_width + 1.0) / 2.0 + 1.0;
  item->item_bounding_box.orig.x -= tmp;
  item->item_bounding_box.orig.y -= tmp;
  item->item_bounding_box.corner.x += tmp;
  item->item_bounding_box.corner.y += tmp;
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
  ArcItem       arc = (ArcItem) item;
  ZnPoint       *points;
  ZnPoint       pts[20]; /* Should be at least ZN_LINE_END_POINTS large */
  ZnPoint       center;
  ZnBBox        *area = ta->area;
  unsigned int  num_points;
  int           result=-1, result2;
  ZnReal        lw = arc->line_width;
  ZnReal        width, height;

  if (ISSET(arc->flags, USING_POLY_BIT)) {
    if (ISSET(arc->flags, FILLED_BIT) || (arc->line_width)) {
      points = ZnListArray(arc->render_shape);
      num_points = ZnListSize(arc->render_shape);
      
      if (ISSET(arc->flags, FILLED_BIT)) {
        result = ZnPolygonInBBox(points, num_points, area, NULL);
        if (result == 0) {
          return 0;
        }
      }
      if (arc->line_width > 0) {
        result2 = ZnPolylineInBBox(points, num_points, arc->line_width,
                                   CapRound, JoinRound, area);
        if (ISCLEAR(arc->flags, FILLED_BIT)) {
          if (result2 == 0) {
            return 0;
          }
          result = result2;
        }
        else if (result2 != result) {
          return 0;
        }
        if (ISSET(arc->flags, CLOSED_BIT) && ISSET(arc->flags, PIE_SLICE_BIT)) {
          pts[0] = points[num_points-1];
          pts[1] = points[0];
          if (ZnPolylineInBBox(pts, 2, arc->line_width,
                               CapRound, JoinRound, area) != result) {
            return 0;
          }
        }
        /*
         * Check line ends.
         */
        if (ISSET(arc->flags, FIRST_END_OK)) {
          ZnGetLineEnd(&points[0], &points[1], arc->line_width, CapRound,
                       arc->first_end, pts);
          if (ZnPolygonInBBox(pts, ZN_LINE_END_POINTS, area, NULL) != result) {
            return 0;
          }
        }
        if (ISSET(arc->flags, LAST_END_OK)) {
          ZnGetLineEnd(&points[num_points-1], &points[num_points-2], arc->line_width,
                       CapRound, arc->last_end, pts);
          if (ZnPolygonInBBox(pts, ZN_LINE_END_POINTS, area, NULL) != result) {
            return 0;
          }
        }
      }
      return result;
    }
    else {
      return -1;
    }
  }

  /*
   *******              ********                        **********
   * The rest of this code deal with non rotated, full extent    *
   * arcs. It has been stolen from tkRectOval.c                  *
   *******              ********                        **********
   */
  /*
   * Transform both the arc and the rectangle so that the arc's oval
   * is centered on the origin.
   */
  center.x = (arc->orig.x + arc->corner.x)/2.0;
  center.y = (arc->orig.y + arc->corner.y)/2.0;
  width = (arc->corner.x - arc->orig.x) +  lw;
  height = (arc->corner.y - arc->orig.y) + lw;

  result = ZnOvalInBBox(&center, width, height, area);
 
   /*
    * If the area appears to overlap the oval and the oval
    * isn't filled, do one more check to see if perhaps all four
    * of the area's corners are totally inside the oval's
    * unfilled center, in which case we should return "outside".
    */
  if ((result == 0) && lw && ISCLEAR(arc->flags, FILLED_BIT)) {
    ZnReal x_delta1, x_delta2, y_delta1, y_delta2;

    width /= 2.0;
    height /= 2.0;
    x_delta1 = (area->orig.x - center.x) / width;
    x_delta1 *= x_delta1;
    y_delta1 = (area->orig.y - center.y) / height;
    y_delta1 *= y_delta1;
    x_delta2 = (area->corner.x - center.x) / width;
    x_delta2 *= x_delta2;
    y_delta2 = (area->corner.y - center.y) / height;
    y_delta2 *= y_delta2;
    if (((x_delta1 + y_delta1) < 1.0) && ((x_delta1 + y_delta2) < 1.0) &&
        ((x_delta2 + y_delta1) < 1.0) && ((x_delta2 + y_delta2) < 1.0)) {
      return -1;
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
  ZnWInfo       *wi = item->wi;
  ArcItem       arc = (ArcItem) item;
  XGCValues     values;
  int           x=0, y=0, width=0, height=0;
  ZnPoint       *p=NULL;
  XPoint        *xp=NULL;
  unsigned int  num_points=0, i;

  if (ISCLEAR(arc->flags, FILLED_BIT) && !arc->line_width) {
    return;
  }
  if (ISSET(arc->flags, USING_POLY_BIT)) {
    p = ZnListArray(arc->render_shape);
    num_points = ZnListSize(arc->render_shape);
    ZnListAssertSize(ZnWorkXPoints, num_points);
    xp = ZnListArray(ZnWorkXPoints);
    for (i = 0; i < num_points; i++, p++) {
      xp[i].x = (short) p->x;
      xp[i].y = (short) p->y;
    }
    p = ZnListArray(arc->render_shape);
  }
  else {
    if (arc->corner.x > arc->orig.x) {
      x = ((int) arc->orig.x);
      width = ((int) (arc->corner.x - arc->orig.x));
    }
    else {
      x = ((int) arc->corner.x);
      width = ((int) (arc->orig.x - arc->corner.x));
    }
    if (arc->corner.y > arc->orig.y) {
      y = ((int) arc->orig.y);
      height = ((int) (arc->corner.y - arc->orig.y));
    }
    else {
      y = ((int) arc->corner.y);
      height = ((int) (arc->orig.y - arc->corner.y));
    }
  }
  
  /* Fill if requested */
  if (ISSET(arc->flags, FILLED_BIT)) {
    values.foreground = ZnGetGradientPixel(arc->fill_color, 0.0);
    values.arc_mode = ISSET(arc->flags, PIE_SLICE_BIT) ? ArcPieSlice : ArcChord;
    if (arc->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(arc->tile)) { /* Fill tiled */
        values.fill_style = FillTiled;
        values.tile = ZnImagePixmap(arc->tile, wi->win);
        values.ts_x_origin = (int) item->item_bounding_box.orig.x;
        values.ts_y_origin = (int) item->item_bounding_box.orig.y;
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCFillStyle|GCTile|GCArcMode,
                  &values);
      }
      else { /* Fill stippled */
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(arc->tile, wi->win);
        values.ts_x_origin = (int) item->item_bounding_box.orig.x;
        values.ts_y_origin = (int) item->item_bounding_box.orig.y;
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCFillStyle|GCStipple|GCForeground|GCArcMode,
                  &values);
      }
    }
    else { /* Fill solid */
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc, GCForeground|GCFillStyle|GCArcMode, &values);
    }

    if (ISSET(arc->flags, USING_POLY_BIT)) {
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc,
                   xp, (int) num_points, Nonconvex, CoordModeOrigin);
    }
    else {
      XFillArc(wi->dpy, wi->draw_buffer, wi->gc,
               x, y, (unsigned int) width, (unsigned int) height,
               -arc->start_angle*64, -arc->angle_extent*64);
    }
  }

  /*
   * Draw the arc.
   */
  if (arc->line_width) {
    ZnPoint  end_points[ZN_LINE_END_POINTS];
    XPoint      xap[ZN_LINE_END_POINTS];
      
    ZnSetLineStyle(wi, arc->line_style);
    values.foreground = ZnGetGradientPixel(arc->line_color, 0.0);
    values.line_width = (arc->line_width == 1) ? 0 : (int) arc->line_width;
    values.cap_style = CapRound;
    values.join_style = JoinRound;
    if (arc->line_pattern == ZnUnspecifiedImage) {
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc,
                GCFillStyle|GCLineWidth|GCCapStyle|GCJoinStyle|GCForeground, &values);
    }
    else {
      values.fill_style = FillStippled;
      values.stipple = ZnImagePixmap(arc->line_pattern, wi->win);
      XChangeGC(wi->dpy, wi->gc,
                GCFillStyle|GCStipple|GCLineWidth|GCCapStyle|GCJoinStyle|GCForeground,
                &values);
    }
    if (ISSET(arc->flags, USING_POLY_BIT)) {
      if (ISCLEAR(arc->flags, CLOSED_BIT) && arc->angle_extent != 360) {
        num_points--;
        if (ISSET(arc->flags, PIE_SLICE_BIT)) {
          num_points--;
        }
      }
      XDrawLines(wi->dpy, wi->draw_buffer, wi->gc,
                 xp, (int) num_points, CoordModeOrigin);
      if (ISSET(arc->flags, FIRST_END_OK)) {
        p = (ZnPoint *) ZnListArray(arc->render_shape);
        ZnGetLineEnd(p, p+1, arc->line_width, CapRound,
                     arc->first_end, end_points);
        for (i = 0; i < ZN_LINE_END_POINTS; i++) {
          xap[i].x = (short) end_points[i].x;
          xap[i].y = (short) end_points[i].y;
        }
        XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xap, ZN_LINE_END_POINTS,
                     Nonconvex, CoordModeOrigin);
      }
      if (ISSET(arc->flags, LAST_END_OK)) {
        p = (ZnPoint *) ZnListArray(arc->render_shape);
        num_points = ZnListSize(arc->render_shape);
        ZnGetLineEnd(&p[num_points-1], &p[num_points-2], arc->line_width,
                     CapRound, arc->last_end, end_points);
        for (i = 0; i < ZN_LINE_END_POINTS; i++) {
          xap[i].x = (short) end_points[i].x;
          xap[i].y = (short) end_points[i].y;
        }
        XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xap, ZN_LINE_END_POINTS,
                     Nonconvex, CoordModeOrigin);
      }
    }
    else {
      XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
               x, y, (unsigned int) width, (unsigned int) height,
               -arc->start_angle*64, -arc->angle_extent*64);
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
ArcRenderCB(void *closure)
{
  ZnItem        item = (ZnItem) closure;
  ArcItem       arc = (ArcItem) item;
  int           num_points=0, i;
  ZnPoint       *p=NULL;
  ZnPoint       center;

  center.x = (item->item_bounding_box.corner.x + item->item_bounding_box.orig.x) / 2.0;
  center.y = (item->item_bounding_box.corner.y + item->item_bounding_box.orig.y) / 2.0;
  p = ZnListArray(arc->render_shape);
  num_points = ZnListSize(arc->render_shape);
  glBegin(GL_TRIANGLE_FAN);
  glVertex2d(center.x, center.y);
  for (i = 0; i < num_points; i++) {
    glVertex2d(p[i].x, p[i].y);
  }
  glEnd();
}
#endif

#ifdef GL
static void
Render(ZnItem   item)
{
  ZnWInfo       *wi = item->wi;
  ArcItem       arc = (ArcItem) item;
  unsigned int  num_points=0;
  ZnPoint       *p=NULL;
  
  if (ISCLEAR(arc->flags, FILLED_BIT) && !arc->line_width) {
    return;
  }
  
#ifdef GL_LIST
  if (!item->gl_list) {
    item->gl_list = glGenLists(1);
    glNewList(item->gl_list, GL_COMPILE);
#endif
    /* Fill if requested */
    if (ISSET(arc->flags, FILLED_BIT)) {
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      
      if (!ZnGradientFlat(arc->fill_color)) {
        ZnPoly poly;
        
        ZnPolyContour1(&poly, ZnListArray(arc->render_shape),
                       ZnListSize(arc->render_shape), False);
        ZnRenderGradient(wi, arc->fill_color, ArcRenderCB, arc,
                         arc->grad_geo, &poly);
      }
      else if (arc->tile != ZnUnspecifiedImage) { /* Fill tiled/stippled */
        ZnRenderTile(wi, arc->tile, arc->fill_color, ArcRenderCB, arc,
                     (ZnPoint *) &item->item_bounding_box);
      }
      else {
        unsigned short alpha;
        XColor *color = ZnGetGradientColor(arc->fill_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        ArcRenderCB(arc);
      }
    }
    
    /*
     * Draw the arc.
     */
    if (arc->line_width) {
      ZnLineEnd first = ISSET(arc->flags, FIRST_END_OK) ? arc->first_end : NULL;
      ZnLineEnd last = ISSET(arc->flags, LAST_END_OK) ? arc->last_end : NULL;
      ZnBool    closed = ISSET(arc->flags, CLOSED_BIT);
      
      p = ZnListArray(arc->render_shape);
      num_points = ZnListSize(arc->render_shape);
      if (!closed) {
        if (arc->angle_extent != 360) {
          num_points--;
          if (ISSET(arc->flags, PIE_SLICE_BIT)) {
            num_points--;
          }
        }
      }
      ZnRenderPolyline(wi, p, num_points, arc->line_width,
                       arc->line_style, CapRound, JoinRound, first, last,
                       arc->line_color);
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
static ZnReal
Pick(ZnItem     item,
     ZnPick     ps)
{
  ArcItem       arc = (ArcItem) item;
  double        dist = 1e40, new_dist;
  ZnPoint       center;
  ZnPoint       *points, *p = ps->point;
  ZnPoint       end_points[ZN_LINE_END_POINTS];
  unsigned int  num_points;
  ZnDim         lw = arc->line_width;
  
  if (ISCLEAR(arc->flags, FILLED_BIT) && ! arc->line_width) {
    return dist;
  }
  if (ISSET(arc->flags, USING_POLY_BIT)) {
    points = ZnListArray(arc->render_shape);
    num_points = ZnListSize(arc->render_shape);

    if (ISSET(arc->flags, FILLED_BIT)) {
      dist = ZnPolygonToPointDist(points, num_points, p);
      if (dist <= 0.0) {
        return 0.0;
      }
    }
    if (arc->line_width > 0) {
      if (ISCLEAR(arc->flags, CLOSED_BIT) && arc->angle_extent != 360) {
        num_points--;
        if (ISSET(arc->flags, PIE_SLICE_BIT)) {
          num_points--;
        }
      }
      new_dist = ZnPolylineToPointDist(points, num_points, arc->line_width,
                                       CapRound, JoinRound, p);
      if (new_dist < dist) {
        dist = new_dist;
      }
      if (dist <= 0.0) {
        return 0.0;
      }

      /*
       * Check line ends.
       */
      if (ISSET(arc->flags, FIRST_END_OK)) {
        ZnGetLineEnd(&points[0], &points[1], arc->line_width, CapRound,
                     arc->first_end, end_points);
        new_dist = ZnPolygonToPointDist(end_points, ZN_LINE_END_POINTS, p);
        if (new_dist < dist) {
          dist = new_dist;
        }
        if (dist <= 0.0) {
          return 0.0;
        }
      }
      if (ISSET(arc->flags, LAST_END_OK)) {
        ZnGetLineEnd(&points[num_points-1], &points[num_points-2], arc->line_width,
                     CapRound, arc->last_end, end_points);
        new_dist = ZnPolygonToPointDist(end_points, ZN_LINE_END_POINTS, p);
        if (new_dist < dist) {
          dist = new_dist;
        }
        if (dist <= 0.0) {
          return 0.0;
        }
      }
    }
    return dist;
  }

  /*
   *******              ********                          **********
   * The rest of this code deal with non rotated full extent arcs. *
   *******              ********                          **********
   */
  center.x = (arc->orig.x + arc->corner.x) / 2.0;
  center.y = (arc->orig.y + arc->corner.y) / 2.0;
  dist = ZnOvalToPointDist(&center, arc->corner.x - arc->orig.x,
                           arc->corner.y - arc->orig.y, lw, p);
  if (dist < 0.0) {
    if (ISSET(arc->flags, FILLED_BIT)) {
      dist = 0.0;
    }
    else {
      dist = -dist;
    }
  }
  return dist;
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
static void
UpdateRenderShapeX(ArcItem      arc)
{
  ZnReal        ox, oy, width_2, height_2;
  int           i, num_p;
  ZnPoint       *p_list;
  
  if (!arc->render_shape) {
    arc->render_shape = ZnListNew(8, sizeof(ZnPoint));
  }
  p_list = ZnGetCirclePoints(ISCLEAR(arc->flags, PIE_SLICE_BIT) ? 1 : 2,
                             ZN_CIRCLE_FINE,
                             ZnDegRad(arc->start_angle),
                             ZnDegRad(arc->angle_extent),
                             &num_p, arc->render_shape);
  ox = (arc->corner.x + arc->orig.x) / 2.0;
  oy = (arc->corner.y + arc->orig.y) / 2.0;
  width_2 = (arc->corner.x - arc->orig.x) / 2.0;
  height_2 = (arc->corner.y - arc->orig.y) / 2.0;
  for (i = 0; i < num_p; i++, p_list++) {
    p_list->x = ox + p_list->x*width_2;
    p_list->y = oy + p_list->y*height_2;
  }
}

static ZnBool
GetClipVertices(ZnItem          item,
                ZnTriStrip      *tristrip)
{
  ArcItem       arc = (ArcItem) item;
  ZnPoint       center;

  if (ISCLEAR(arc->flags, USING_POLY_BIT) || !arc->render_shape) {
    UpdateRenderShapeX(arc);
    SET(arc->flags, USING_POLY_BIT);
  }

  
  center.x = (item->item_bounding_box.corner.x + item->item_bounding_box.orig.x) / 2.0;
  center.y = (item->item_bounding_box.corner.y + item->item_bounding_box.orig.y) / 2.0;
  ZnListEmpty(ZnWorkPoints);
  ZnListAdd(ZnWorkPoints, &center, ZnListTail);
  ZnListAppend(ZnWorkPoints, arc->render_shape);
  ZnTriStrip1(tristrip, ZnListArray(ZnWorkPoints),
              ZnListSize(ZnWorkPoints), True);
  
  return False;
}


/*
 **********************************************************************************
 *
 * GetContours --
 *      Get the external contour(s).
 *      Never ever call ZnPolyFree on the tristrip returned by GetContours.
 *
 **********************************************************************************
 */
static ZnBool
GetContours(ZnItem      item,
            ZnPoly      *poly)
{
  ArcItem       arc = (ArcItem) item;
  
  if (ISCLEAR(arc->flags, USING_POLY_BIT) || !arc->render_shape) {
    UpdateRenderShapeX(arc);
  }

  ZnPolyContour1(poly, ZnListArray(arc->render_shape),
                 ZnListSize(arc->render_shape), True);
  poly->contour1.controls = NULL;

  return False;
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
  ArcItem       arc = (ArcItem) item;

  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " arcs can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if (cmd == ZN_COORDS_REPLACE_ALL) {
    if (*num_pts != 2) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 2 points on arcs", NULL);
      return TCL_ERROR;
    }
    arc->coords[0] = (*pts)[0];
    arc->coords[1] = (*pts)[1];
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
    arc->coords[index] = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if (cmd == ZN_COORDS_READ_ALL) {
    *num_pts = 2;
    *pts = arc->coords;
  }
  else if (cmd == ZN_COORDS_READ) {
    if (index < 0) {
      index += 2;
    }
    if ((index < 0) || (index > 1)) {
      goto range_err;
    }
    *num_pts = 1;
    *pts = &arc->coords[index];
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
 * PostScript --
 *
 **********************************************************************************
 */
static int
PostScript(ZnItem item,
           ZnBool prepass,
           ZnBBox *area)
{
  ArcItem arc = (ArcItem) item;
  ZnWInfo *wi = item->wi;
  ZnPoint *p;
  int     i, num_points;
  char    path[500];

  if (ISCLEAR(arc->flags, FILLED_BIT) && !arc->line_width) {
    return TCL_OK;
  }

  /*
   * Create the arc path.
   */
  if (ISSET(arc->flags, USING_POLY_BIT)) {
    p = ZnListArray(arc->render_shape);
    num_points = ZnListSize(arc->render_shape);
    sprintf(path, "%.15g %.15g moveto ", p[0].x, p[0].y);
    Tcl_AppendResult(wi->interp, path, NULL);
    for (i = 0; i < num_points; i++) {
      sprintf(path, "%.15g %.15g lineto ", p[i].x, p[i].y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
    Tcl_AppendResult(wi->interp, "closepath\n", NULL);
  }
  else {
    sprintf(path,
            "matrix currentmatrix\n%.15g %.15g translate %.15g %.15g scale 1 0 moveto 0 0 1 0 360 arc\nsetmatrix\n",
            (arc->corner.x + arc->orig.x) / 2.0, (arc->corner.y + arc->orig.y) / 2.0,
            (arc->corner.x - arc->orig.x) / 2.0, (arc->corner.y - arc->orig.y) / 2.0);
    Tcl_AppendResult(wi->interp, path, NULL);
  }
  
  /*
   * Emit code to draw the filled area.
   */
  if (ISSET(arc->flags, FILLED_BIT)) {
    if (arc->line_width) {
      Tcl_AppendResult(wi->interp, "gsave\n", NULL);
    }
    if (!ZnGradientFlat(arc->fill_color)) {
      if (ZnPostscriptGradient(wi->interp, wi->ps_info, arc->fill_color,
                               arc->grad_geo, NULL) != TCL_OK) {
        return TCL_ERROR;
      }
    }
    else if (arc->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(arc->tile)) { /* Fill tiled */
        /* TODO No support yet */
      }
      else { /* Fill stippled */
        if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                               ZnGetGradientColor(arc->fill_color, 0.0, NULL)) != TCL_OK) {
          return TCL_ERROR;
        }
        Tcl_AppendResult(wi->interp, "clip ", NULL);
        if (Tk_PostscriptStipple(wi->interp, wi->win, wi->ps_info,
                                 ZnImagePixmap(arc->tile, wi->win)) != TCL_OK) {
          return TCL_ERROR;
        }
      }
    }
    else { /* Fill solid */
      if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                             ZnGetGradientColor(arc->fill_color, 0.0, NULL)) != TCL_OK) {
        return TCL_ERROR;
      }
      Tcl_AppendResult(wi->interp, "fill\n", NULL);
    }
    if (arc->line_width) {
      Tcl_AppendResult(wi->interp, "grestore\n", NULL);
    }
  }

  /*
   * Then emit code code to stroke the outline.
   */
  if (arc->line_width) {
    Tcl_AppendResult(wi->interp, "0 setlinejoin 2 setlinecap\n", NULL);
    if (ZnPostscriptOutline(wi->interp, wi->ps_info, wi->win,
                            arc->line_width, arc->line_style,
                            arc->line_color, arc->line_pattern) != TCL_OK) {
      return TCL_ERROR;
    }
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
static ZnItemClassStruct ARC_ITEM_CLASS = {
  "arc",
  sizeof(ArcItemStruct),
  arc_attrs,
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
  GetContours,
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

ZnItemClassId ZnArc = (ZnItemClassId) &ARC_ITEM_CLASS;
