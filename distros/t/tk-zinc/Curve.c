/*
 * Curve.c -- Implementation of curve item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Fri Mar 25 15:32:17 1994
 *
 * $Id: Curve.c,v 1.59 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#include "Draw.h"
#include "Item.h"
#include "Geo.h"
#include "Types.h"
#include "WidgetInfo.h"
#include "Image.h"
#include "Color.h"
#include "tkZinc.h"

#include <GL/glu.h>
#include <ctype.h>

static const char rcsid[] = "$Id: Curve.c,v 1.59 2005/05/10 07:59:48 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 * Bit offset of flags.
 */
#define FILLED_BIT      1<<0    /* If the item is filled with color/pattern */
#define MARKED_BIT      1<<1    /* If the vertices are marked by a symbol */
#define CLOSED_BIT      1<<2    /* If the outline should be closed automatically */
#define SMOOTH_RELIEF_BIT 1<<3  /* If the relief should be continuous (arc) or discrete (angle) */

#define FIRST_END_OK    1<<6
#define LAST_END_OK     1<<7
#define FILLED_OK       1<<8
#define RELIEF_OK       1<<10
#define MARKER_OK       1<<12


/*
 **********************************************************************************
 *
 * Specific Curve item record
 *
 **********************************************************************************
 */
typedef struct _CurveItemStruct {
  ZnItemStruct  header;

  /* Public data */
  ZnPoly        shape;
  unsigned short flags;
  ZnImage       marker;
  ZnLineEnd     first_end;      /* These two are considered only if relief is flat */
  ZnLineEnd     last_end;
  ZnLineStyle   line_style;     /* This is considered only if relief is flat */
  int           cap_style;
  int           join_style;
  ZnReliefStyle relief;
  ZnDim         line_width;     /* If 0 the path is not drawn, if <2 relief is flat */
  ZnGradient    *fill_color;
  ZnImage       line_pattern;
  ZnGradient    *line_color;
  ZnGradient    *marker_color;
  int           fill_rule;
  ZnImage       tile;
  
  /* Private data */
  ZnPoly        outlines;
  ZnGradient    *gradient;
  ZnTriStrip    tristrip;
  ZnPoint       *grad_geo;  
} CurveItemStruct, *CurveItem;

static ZnAttrConfig     cv_attrs[] = {
  { ZN_CONFIG_CAP_STYLE, "-capstyle", NULL,
    Tk_Offset(CurveItemStruct, cap_style), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-closed", NULL,
    Tk_Offset(CurveItemStruct, flags), CLOSED_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(CurveItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(CurveItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(CurveItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-fillcolor", NULL,
    Tk_Offset(CurveItemStruct, fill_color), 0,
    ZN_COORDS_FLAG|ZN_BORDER_FLAG, False },
  { ZN_CONFIG_BOOL, "-filled", NULL,
    Tk_Offset(CurveItemStruct, flags), FILLED_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-fillpattern", NULL,
    Tk_Offset(CurveItemStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_FILL_RULE, "-fillrule", NULL,
    Tk_Offset(CurveItemStruct, fill_rule), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_END, "-firstend", NULL,
    Tk_Offset(CurveItemStruct, first_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_JOIN_STYLE, "-joinstyle", NULL,
    Tk_Offset(CurveItemStruct, join_style), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_END, "-lastend", NULL,
    Tk_Offset(CurveItemStruct, last_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-linecolor", NULL,
    Tk_Offset(CurveItemStruct, line_color), 0,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BITMAP, "-linepattern", NULL,
    Tk_Offset(CurveItemStruct, line_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-linestyle", NULL,
    Tk_Offset(CurveItemStruct, line_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-linewidth", NULL,
    Tk_Offset(CurveItemStruct, line_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(CurveItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BITMAP, "-marker", NULL,
    Tk_Offset(CurveItemStruct, marker), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-markercolor", NULL,
    Tk_Offset(CurveItemStruct, marker_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_RELIEF, "-relief", NULL, Tk_Offset(CurveItemStruct, relief), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(CurveItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-smoothrelief", NULL,
    Tk_Offset(CurveItemStruct, flags), SMOOTH_RELIEF_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(CurveItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_IMAGE, "-tile", NULL,
    Tk_Offset(CurveItemStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(CurveItemStruct, header.flags), ZN_VISIBLE_BIT,
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
  CurveItem     cv = (CurveItem) item;
  unsigned int  i, num_points, count;
  ZnPoint       *p, *points;
  char          *controls;

  cv->outlines.num_contours = 0;
  cv->outlines.contours = NULL;
  cv->tristrip.num_strips = 0;
  cv->tristrip.strips = NULL;
  cv->gradient = NULL;
  cv->grad_geo = NULL;
  
  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  CLEAR(cv->flags, CLOSED_BIT);
  CLEAR(cv->flags, SMOOTH_RELIEF_BIT);
  cv->fill_rule = GLU_TESS_WINDING_ODD;
  item->priority = 1;

  if (*argc < 1) {
    Tcl_AppendResult(wi->interp, " curve coords expected", NULL);
    return TCL_ERROR;
  }
  if (ZnParseCoordList(wi, (*args)[0], &points,
                       &controls, &num_points, NULL) == TCL_ERROR) {
    return TCL_ERROR;
  }

  if (num_points == 0) {
    ZnPolyInit(&cv->shape);
  }
  else {
    /*
     * Scan the control array (if any) to detect malformed
     * curves (more than 2 consecutive control points).
     */
    if (controls) {
      count = 0;
      if ((controls[0]) || (controls[num_points-1])) {
        goto contr_err;
      }
      for (i = 1; i < num_points-1; i++) {
        switch (controls[i]) {
        case 'c':
          count++;
          if (count > 2) {
            goto contr_err;
          }
          break;
        case 0:
          count = 0;
          break;
        default:
        contr_err:
          ZnFree(controls);
          Tcl_AppendResult(wi->interp, " curve coords expected", NULL);
          return TCL_ERROR;
        }
      }
    }
    /*
     * Make a local copy of the points. This is not necessary
     * for the optional control list.
     */
    p = ZnMalloc(num_points * sizeof(ZnPoint));
    /*printf("plain contour, numpoints: %d %g@%g\n",
      num_points, points[0].x, points[0].y);*/
    memcpy(p, points, num_points * sizeof(ZnPoint));
    ZnPolyContour1(&cv->shape, p, num_points, !ZnTestCCW(p, num_points));
    cv->shape.contours[0].controls = controls;
  }
  (*args)++;
  (*argc)--;
 
  CLEAR(cv->flags, FILLED_BIT);
  cv->first_end = NULL;
  cv->last_end = NULL;
  cv->line_style = ZN_LINE_SIMPLE;
  cv->relief = ZN_RELIEF_FLAT;
  cv->line_width = 1;
  cv->tile = ZnUnspecifiedImage;
  cv->line_pattern = ZnUnspecifiedImage;
  cv->cap_style = CapRound;
  cv->join_style = JoinRound;
  
  /*
   * In Tk marker visibility is controlled by the bitmap
   * being unspecified.
   */
  SET(cv->flags, MARKED_BIT);
  cv->marker = ZnUnspecifiedImage;
  cv->fill_color = ZnGetGradientByValue(wi->fore_color);
  cv->line_color = ZnGetGradientByValue(wi->fore_color);
  cv->marker_color = ZnGetGradientByValue(wi->fore_color);

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
  CurveItem     cv = (CurveItem) item;
  unsigned int  i;
  ZnContour     *conts;

  
  if (cv->shape.num_contours) {
    conts = cv->shape.contours;
    if (cv->shape.contours != &cv->shape.contour1) {
      cv->shape.contours = (ZnContour *) ZnMalloc(cv->shape.num_contours*sizeof(ZnContour));
    }
    for (i = 0; i < cv->shape.num_contours; i++) {
      cv->shape.contours[i].num_points = conts[i].num_points;
      cv->shape.contours[i].cw = conts[i].cw;
      cv->shape.contours[i].points = ZnMalloc(conts[i].num_points*sizeof(ZnPoint));
      memcpy(cv->shape.contours[i].points, conts[i].points,
             conts[i].num_points*sizeof(ZnPoint));
      cv->shape.contours[i].controls = NULL;
      if (conts[i].controls) {
         cv->shape.contours[i].controls = ZnMalloc(conts[i].num_points*sizeof(char));
         memcpy(cv->shape.contours[i].controls, conts[i].controls,
                conts[i].num_points*sizeof(char));
      }
    }
  }
  
  if (cv->gradient) {
    cv->gradient = ZnGetGradientByValue(cv->gradient);
  }
  if (cv->first_end) {
    ZnLineEndDuplicate(cv->first_end);
  }
  if (cv->last_end) {
    ZnLineEndDuplicate(cv->last_end);
  }
  if (cv->tile != ZnUnspecifiedImage) {
    cv->tile = ZnGetImageByValue(cv->tile, ZnUpdateItemImage, item);
  }
  if (cv->line_pattern != ZnUnspecifiedImage) {
    cv->line_pattern = ZnGetImageByValue(cv->line_pattern, NULL, NULL);
  }
  if (cv->marker != ZnUnspecifiedImage) {
    cv->marker = ZnGetImageByValue(cv->marker, NULL, NULL);
  }
  cv->line_color = ZnGetGradientByValue(cv->line_color);
  cv->fill_color = ZnGetGradientByValue(cv->fill_color);
  cv->grad_geo = NULL;
  cv->marker_color = ZnGetGradientByValue(cv->marker_color);
  cv->tristrip.num_strips = 0;
  cv->tristrip.strips = NULL;
  cv->outlines.num_contours = 0;
  cv->outlines.contours = NULL;
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
  CurveItem     cv = (CurveItem) item;
  unsigned int  i;

  /*
   * Need to free the control array here, it is only known
   * by the Curve code.
   */
  for (i = 0; i < cv->shape.num_contours; i++) {
    if (cv->shape.contours[i].controls) {
      ZnFree(cv->shape.contours[i].controls);
    }
  }
  ZnPolyFree(&cv->shape);

  if (cv->grad_geo) {
    ZnFree(cv->grad_geo);
  }
  if (cv->first_end) {
    ZnLineEndDelete(cv->first_end);
  }
  if (cv->last_end) {
    ZnLineEndDelete(cv->last_end);
  }
  if (cv->gradient) {
    ZnFreeGradient(cv->gradient);
  }
  if (cv->tile != ZnUnspecifiedImage) {
    ZnFreeImage(cv->tile, ZnUpdateItemImage, item);
    cv->tile = ZnUnspecifiedImage;
  }
  if (cv->line_pattern != ZnUnspecifiedImage) {
    ZnFreeImage(cv->line_pattern, NULL, NULL);
    cv->line_pattern = ZnUnspecifiedImage;
  }
  if (cv->marker != ZnUnspecifiedImage) {
    ZnFreeImage(cv->marker, NULL, NULL);
    cv->marker = ZnUnspecifiedImage;
  }
  ZnFreeGradient(cv->fill_color);
  ZnFreeGradient(cv->line_color);
  ZnFreeGradient(cv->marker_color);

  if (cv->tristrip.num_strips) {
    ZnTriFree(&cv->tristrip);
  }  
  if (cv->outlines.num_contours) {
    ZnPolyFree(&cv->outlines);
  }
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
SetRenderFlags(CurveItem        cv)
{
  ASSIGN(cv->flags, FILLED_OK,
         ISSET(cv->flags, FILLED_BIT) && (cv->shape.num_contours >= 1));

  ASSIGN(cv->flags, RELIEF_OK,
         (cv->relief != ZN_RELIEF_FLAT) &&
         (cv->shape.num_contours >= 1) &&
         (cv->line_width > 1));

  ASSIGN(cv->flags, MARKER_OK,
         (cv->marker != ZnUnspecifiedImage) &&
         ISCLEAR(cv->flags, RELIEF_OK));
  
  ASSIGN(cv->flags, FIRST_END_OK,
         (cv->first_end != NULL) &&
         (cv->shape.num_contours == 1) && (cv->shape.contours[0].num_points > 1) &&
         ISCLEAR(cv->flags, FILLED_BIT) && cv->line_width &&
         ISCLEAR(cv->flags, RELIEF_OK) &&
         ISCLEAR(cv->flags, CLOSED_BIT));
  ASSIGN(cv->flags, LAST_END_OK,
         (cv->last_end != NULL) &&
         (cv->shape.num_contours == 1) && (cv->shape.contours[0].num_points > 1) &&
         ISCLEAR(cv->flags, FILLED_BIT) && cv->line_width &&
         ISCLEAR(cv->flags, RELIEF_OK) &&
         ISCLEAR(cv->flags, CLOSED_BIT));
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
  CurveItem     cv = (CurveItem) item;
  int           status = TCL_OK;
  XColor        *color;
  unsigned short alpha;
  
  status = ZnConfigureAttributes(wi, item, item, cv_attrs, argc, argv, flags);

  if (cv->gradient &&
      (ISSET(*flags, ZN_BORDER_FLAG) || (cv->relief == ZN_RELIEF_FLAT))) {
    ZnFreeGradient(cv->gradient);
    cv->gradient = NULL;
  }
  if ((cv->relief != ZN_RELIEF_FLAT) && !cv->gradient) {
    color = ZnGetGradientColor(cv->line_color, 51.0, &alpha);
    cv->gradient = ZnGetReliefGradient(wi->interp, wi->win,
                                       Tk_NameOfColor(color), alpha);
    if (cv->gradient == NULL) {
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
  if (ZnQueryAttribute(item->wi->interp, item, cv_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }

  return TCL_OK;
}

static void
UpdateTristrip(CurveItem        cv,
               ZnPoly           *poly,
               ZnBool           revert)
{
  ZnCombineData *cdata, *cnext;
  GLdouble      v[3];
  unsigned int  j, k;
  int           i;

  //printf("UpdateTristrips sur %d\n", ((ZnItem) cv)->id);
  gluTessProperty(ZnTesselator.tess, GLU_TESS_WINDING_RULE, (GLdouble) cv->fill_rule);

  if (cv->tristrip.num_strips == 0) {
    gluTessProperty(ZnTesselator.tess, GLU_TESS_BOUNDARY_ONLY, (GLdouble) GL_FALSE);
    gluTessBeginPolygon(ZnTesselator.tess, &cv->tristrip);
    /*
     * We need to take care of the final (after transformation) winding
     * direction of the polygon in order to have the right tesselation
     * taking place.
     */
    if (!revert) {
      for (j = 0; j < poly->num_contours; j++){
        gluTessBeginContour(ZnTesselator.tess);
        //printf("Début contour %d num_points %d\n", j, poly->contours[j].num_points);
        for (k = 0; k < poly->contours[j].num_points; k++) {
          /*printf("%g@%g ", poly->contours[j].points[k].x, poly->contours[j].points[k].y);*/
          v[0] = poly->contours[j].points[k].x;
          v[1] = poly->contours[j].points[k].y;
          v[2] = 0;
          gluTessVertex(ZnTesselator.tess, v, &poly->contours[j].points[k]);
        }
        //printf("\n");
        gluTessEndContour(ZnTesselator.tess);
      }
    }
    else {
      for (j = 0; j < poly->num_contours; j++){
        gluTessBeginContour(ZnTesselator.tess);
        //printf("revert Début contour %d num_points %d\n", j, poly->contours[j].num_points);
        for (i = (int) (poly->contours[j].num_points-1); i >= 0; i--) {
          /*printf("%g@%g ", poly->contours[j].points[i].x, poly->contours[j].points[i].y);*/
          v[0] = poly->contours[j].points[i].x;
          v[1] = poly->contours[j].points[i].y;
          v[2] = 0;
          gluTessVertex(ZnTesselator.tess, v, &poly->contours[j].points[i]);
        }
        //printf("\n");
        gluTessEndContour(ZnTesselator.tess);
      }
    }
    gluTessEndPolygon(ZnTesselator.tess);
    cdata = ZnTesselator.combine_list;
                //printf("Combine length: %d\n", ZnTesselator.combine_length);
    while (cdata) {
                        ZnTesselator.combine_length--;
      cnext = cdata->next;
      ZnFree(cdata);
      cdata = cnext;
    }
    ZnTesselator.combine_list = NULL;
  }
  //printf("Fin UpdateTristrips sur %d\n", ((ZnItem) cv)->id);
}

static void
UpdateOutlines(CurveItem        cv,
               ZnPoly           *poly,
               ZnBool           revert)
{
  ZnCombineData *cdata, *cnext;
  GLdouble      v[3];
  unsigned int  j, k;
  int           i;

  //printf("UpdateOutlines sur %d\n", ((ZnItem) cv)->id);
  gluTessProperty(ZnTesselator.tess, GLU_TESS_WINDING_RULE, (GLdouble) cv->fill_rule);

  if (cv->outlines.num_contours == 0) {
    gluTessProperty(ZnTesselator.tess, GLU_TESS_BOUNDARY_ONLY, (GLdouble) GL_TRUE);
    gluTessBeginPolygon(ZnTesselator.tess, &cv->outlines);

    /*
     * We need to take care of the final (after transformation) winding
     * direction of the polygon in order to have the right tesselation
     * taking place.
     */
    if (!revert) {
      for (j = 0; j < poly->num_contours; j++){
        gluTessBeginContour(ZnTesselator.tess);
        for (k = 0; k < poly->contours[j].num_points; k++) {
          v[0] = poly->contours[j].points[k].x;
          v[1] = poly->contours[j].points[k].y;
          v[2] = 0;
          gluTessVertex(ZnTesselator.tess, v, &poly->contours[j].points[k]);
        }
        gluTessEndContour(ZnTesselator.tess);
      }
    }
    else {
      for (j = 0; j < poly->num_contours; j++){
        gluTessBeginContour(ZnTesselator.tess);
        for (i = (int) (poly->contours[j].num_points-1); i >= 0; i--) {
          v[0] = poly->contours[j].points[i].x;
          v[1] = poly->contours[j].points[i].y;
          v[2] = 0;
          gluTessVertex(ZnTesselator.tess, v, &poly->contours[j].points[i]);
        }
        gluTessEndContour(ZnTesselator.tess);
      }
    }
    gluTessEndPolygon(ZnTesselator.tess);
    cdata = ZnTesselator.combine_list;
    while (cdata) {
                        ZnTesselator.combine_length--;
      cnext = cdata->next;
      ZnFree(cdata);
      cdata = cnext;
    }
    ZnTesselator.combine_list = NULL;
  }
  //printf("Fin UpdateOutlines sur %d\n", ((ZnItem) cv)->id);
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
  CurveItem     cv = (CurveItem) item;
  unsigned int  i, j;
  ZnPoint       end_points[ZN_LINE_END_POINTS];
  ZnPoint       *points;
  unsigned int  num_points, num_contours, segment_start;
  ZnBBox        bbox;
  ZnDim         lw;
  ZnContour     *c1, *c2;
  ZnPoly        dev;
  ZnBool        revert;

  ZnResetBBox(&item->item_bounding_box);

  /*printf("Curve CC: flags %x\n", cv->flags);*/
  SetRenderFlags(cv);

  num_contours = cv->shape.num_contours;
  if (num_contours == 0) {
    return;
  }

  if (cv->tristrip.num_strips) {
    ZnTriFree(&cv->tristrip);
  }
  if (cv->outlines.num_contours) {
    ZnPolyFree(&cv->outlines);
  };

  ZnPolyInit(&dev);
  if (num_contours != 1) {
    dev.contours = ZnMalloc(num_contours * sizeof(ZnContour));
    dev.num_contours = num_contours;
  }
  else {
    dev.contours = &dev.contour1;
    dev.num_contours = 1;
  }

  for (c1 = cv->shape.contours, c2 = dev.contours, i = 0;
       i < cv->shape.num_contours; i++, c1++, c2++) {
    c2->num_points = c1->num_points;
    /*
     * Add a point at the end of the contour to close it
     * if needed. Works only if a single contour is given, in
     * this case it can be used as a path. In the case of
     * multiple contours, the outline is automatically
     * closed by the tesselator.
     */
    if ((num_contours == 1) &&
        (c1->num_points > 2) &&
        ISSET(cv->flags, CLOSED_BIT) &&
        ((c1->points[0].x != c1->points[c1->num_points-1].x) ||
         (c1->points[0].y != c1->points[c1->num_points-1].y)) &&
        (c1->num_points > 2)) {
      c2->num_points++;
    }
    c2->points = ZnMalloc((c2->num_points)*sizeof(ZnPoint));
    /*printf("CC: \"%d\" num_points %d\n", item->id, c1->num_points);*/
    ZnTransformPoints(wi->current_transfo, c1->points, c2->points, c1->num_points); 
    if (c1->num_points != c2->num_points) {
      c2->points[c2->num_points-1] = c2->points[0];
    }
    /*
     * Now expand the bezier segments into polylines.
     */
    if (c1->controls) {
      segment_start = 0;
      ZnListEmpty(ZnWorkPoints);
      ZnListAdd(ZnWorkPoints, &c2->points[0], ZnListTail);
      /*printf("moveto %g@%g\n", c2->points[0].x, c2->points[0].y);*/
      for (j = 1; j < c1->num_points; j++) {
        if (!c1->controls[j]) {
          if (segment_start != j-1) {
            /* traitement bezier */
            /*printf("arcto  %g@%g %g@%g %g@%g\n",
                   c2->points[segment_start+1].x, c2->points[segment_start+1].y,
                   c2->points[j-1].x, c2->points[j-1].y,
                   c2->points[j].x, c2->points[j].y);*/
            ZnGetBezierPoints(&c2->points[segment_start],
                              &c2->points[segment_start+1], &c2->points[j-1],
                              &c2->points[j], ZnWorkPoints, 0.5);
          }
          else {
            /*printf("lineto %g@%g\n", c2->points[j].x, c2->points[j].y);*/
            ZnListAdd(ZnWorkPoints, &c2->points[j], ZnListTail);
          }
          segment_start = j;
        }
      }
      /*
       * Must test if the last point is a control and the contour
       * is closed (either a mono contour with -closed or 
       * multiple contours).
       */
      if (c1->controls[c1->num_points-1]) {
        ZnGetBezierPoints(&c2->points[segment_start],
                          &c2->points[segment_start+1], &c2->points[c1->num_points-1],
                          &c2->points[0], ZnWorkPoints, 0.5);
      }

      /*
       * Replace the original path by the expanded, closing it as
       * needed (one open contour).
       */
      num_points =ZnListSize(ZnWorkPoints);
      if (c2->num_points != c1->num_points) {
        num_points++;
      }
      c2->points = ZnRealloc(c2->points, num_points*sizeof(ZnPoint));
      memcpy(c2->points, ZnListArray(ZnWorkPoints), num_points*sizeof(ZnPoint));
      if (c2->num_points != c1->num_points) {
        c2->points[num_points-1] = c2->points[0];
      }
      c2->num_points = num_points;
    }
  }

  /*
   * Test the scale factors to see if we need to reverse the
   * polygons winding.
   */
  revert = (wi->current_transfo->_[0][0]*wi->current_transfo->_[1][1]) < 0;
  if (num_contours == 1) {
    if (cv->shape.contours[0].num_points > 2) {
      UpdateTristrip(cv, &dev, revert);
      /*if (!cv->tristrip.num_strips) {
        int kk;
        ZnPrintTransfo(wi->current_transfo);
          printf("id: %d, NumCont: %d, NumPoints: %d, Original: %d, Resultat: %d, NumTri: %d\n",
                 item->id, num_contours,cv->shape.contours[0].num_points,
                 cv->shape.contours[0].cw, cw_dev_contour1, cv->tristrip.num_strips);
          for (kk = 0; kk < cv->shape.contours[0].num_points; kk++) {
            printf("%g@%g ", cv->shape.contours[0].points[kk].x,
                   cv->shape.contours[0].points[kk].y);
          }
          printf("\n");
          }*/
    }
    ZnPolyContour1(&cv->outlines, dev.contours[0].points, dev.contours[0].num_points,
                   cv->shape.contours[0].cw);
  }
  else {
    UpdateTristrip(cv, &dev, revert);
    /*if (!cv->tristrip.num_strips) {
      ZnPrintTransfo(wi->current_transfo);
      printf("id: %d, NumCont: %d, NumPoints: %d, Original: %d, Resultat: %d, NumTri: %d\n",
             item->id, num_contours,cv->shape.contours[0].num_points,
             cv->shape.contours[0].cw, cw_dev_contour1, cv->tristrip.num_strips);
             }*/
    UpdateOutlines(cv, &dev, revert);
    ZnPolyFree(&dev);
  }

  lw = cv->line_width;
  num_contours = cv->outlines.num_contours;
  if (ISSET(cv->flags, RELIEF_OK)) {
    c2 = cv->outlines.contours;
    for (i = 0; i < num_contours; i++, c2++) {
      /*
       * Add to bounding box. 
       */
      ZnGetPolygonReliefBBox(c2->points, c2->num_points, lw, &bbox);
      ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
    }
  }
  else {
    c2 = cv->outlines.contours;
    for (i = 0; i < num_contours; i++, c2++) {
      ZnAddPointsToBBox(&item->item_bounding_box, c2->points, c2->num_points);
    }
    
    /*
     * Take care of miters, markers and arrows.
     */
    c2 = cv->outlines.contours;
    for (j = 0; j < num_contours; j++, c2++) {
      if (c2->cw) {
        continue;
      }
      if (cv->join_style == JoinMiter) {
        ZnPoint miter_i, miter_o;
        for (i = c2->num_points-1, points = c2->points; i >= 3; i--, points++) {
          ZnGetMiterPoints(points, points+1, points+2, lw, &miter_i, &miter_o);
          ZnAddPointToBBox(&item->item_bounding_box, miter_i.x, miter_i.y);
          ZnAddPointToBBox(&item->item_bounding_box, miter_o.x, miter_o.y);
        }
      }
      /*
       * Add the markers.
       */
      if (ISSET(cv->flags, MARKER_OK)) {
        int     w, h;
        ZnBBox  bbox;

        ZnSizeOfImage(cv->marker, &w, &h);
        w = w/2 + 2;
        h = h/2 + 2;
        num_points = c2->num_points;
        for (i = 0, points = c2->points; i < num_points; i++, points++) {
          bbox.orig.x = points->x - w;
          bbox.orig.y = points->y - h;
          bbox.corner.x = points->x + w;
          bbox.corner.y = points->y + h;
          ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
        }
      }
      /*
       * Process arrows.
       */
      num_points = c2->num_points;
      points = c2->points;
      if (ISSET(cv->flags, FIRST_END_OK)) {
        ZnGetLineEnd(&points[0], &points[1], lw, cv->cap_style,
                     cv->first_end, end_points);
        ZnAddPointsToBBox(&item->item_bounding_box, end_points, ZN_LINE_END_POINTS);
      }
      if (ISSET(cv->flags, LAST_END_OK)) {
        ZnGetLineEnd(&points[num_points-1], &points[num_points-2],
                     lw, cv->cap_style, cv->last_end, end_points);
        ZnAddPointsToBBox(&item->item_bounding_box, end_points, ZN_LINE_END_POINTS);
      }
    }
    
    /*
     * Add the line width in all directions.
     * This overestimates the space needed to draw the polyline
     * but is simple.
     */
    item->item_bounding_box.orig.x -= lw;
    item->item_bounding_box.orig.y -= lw;
    item->item_bounding_box.corner.x += lw;
    item->item_bounding_box.corner.y += lw;
  
    /*
     * Expand again the bounding box by one pixel in all
     * directions to take care of rounding errors.
     */
    item->item_bounding_box.orig.x -= 1;
    item->item_bounding_box.orig.y -= 1;
    item->item_bounding_box.corner.x += 1;
    item->item_bounding_box.corner.y += 1;
  }

#ifdef GL  
  if (!ZnGradientFlat(cv->fill_color)) {
    if (!cv->grad_geo) {
      cv->grad_geo = ZnMalloc(6*sizeof(ZnPoint));
    }
    ZnComputeGradient(cv->fill_color, wi, &cv->shape, cv->grad_geo);
  }
  else {
    if (cv->grad_geo) {
      ZnFree(cv->grad_geo);
      cv->grad_geo = NULL;
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
  CurveItem     cv = (CurveItem) item;
  ZnBBox        bbox, *area = ta->area;
  ZnPoint       *points;
  ZnPoint       triangle[3];
  ZnPoint       end_points[ZN_LINE_END_POINTS];
  unsigned int  i, j, num_points, stop;
  int           width, height, result=-1, result2;
  ZnBool        first_done = False;

  if (cv->outlines.num_contours == 0) {
    return -1;
  }
  /*printf("============== poly %d ==============\n", item->id);*/

  if (ISSET(cv->flags, FILLED_OK)) {
    /*printf("testing surfaces\n");*/
    for (i = 0; i < cv->tristrip.num_strips; i++) {
      num_points = cv->tristrip.strips[i].num_points;
      points = cv->tristrip.strips[i].points;
      j = 0;
      stop = num_points-2;
      if (cv->tristrip.strips[i].fan) {
        triangle[0] = points[0];
        j++;
        points++;
        stop++;
      }
      for (; j < stop; j++, points++) {
        if (cv->tristrip.strips[i].fan) {
          triangle[1] = points[0];
          triangle[2] = points[1];
        }
        else {
          triangle[0] = points[0];
          triangle[1] = points[1];
          triangle[2] = points[2];
        }
        if (!first_done) {
          first_done = True;
          result = ZnPolygonInBBox(triangle, 3, area, NULL);
        }
        else {
          result2 = ZnPolygonInBBox(triangle, 3, area, NULL);
          if (result2 != result) {
            return 0;
          }
        }
      }
    }
  }

  if (cv->line_width > 0) {
    /*printf("testing lines\n");*/
    for (i = 0; i < cv->outlines.num_contours; i++) {
      num_points = cv->outlines.contours[i].num_points;
      points = cv->outlines.contours[i].points;
      if (!first_done) {
        first_done = True;
        if (ISCLEAR(cv->flags, RELIEF_OK)) {
          result = ZnPolylineInBBox(points, num_points,
                                    cv->line_width, cv->cap_style, cv->join_style, area);
        }
        else {
          result = ZnPolygonReliefInBBox(points, num_points, cv->line_width, area);
        }
        if (result == 0) {
          return 0;
        }
      }
      else {
        if (ISCLEAR(cv->flags, RELIEF_OK)) {
          result2 = ZnPolylineInBBox(points, num_points,
                                     cv->line_width, cv->cap_style, cv->join_style, area);
        }
        else {
          result2 = ZnPolygonReliefInBBox(points, num_points, cv->line_width, area);
        }
        if (result2 != result) {
          return 0;
        }
      }
    }
  
    /*
     * Check line ends (only on first contour).
     */
    points = cv->outlines.contours[0].points;
    num_points = cv->outlines.contours[0].num_points;
    if (ISSET(cv->flags, FIRST_END_OK)) {
      ZnGetLineEnd(&points[0], &points[1], cv->line_width, cv->cap_style,
                   cv->first_end, end_points);
      if (ZnPolygonInBBox(end_points, ZN_LINE_END_POINTS, area, NULL) != result) {
        return 0;
      }
    }
    if (ISSET(cv->flags, LAST_END_OK)) {
      ZnGetLineEnd(&points[num_points-1], &points[num_points-2], cv->line_width,
                   cv->cap_style, cv->last_end, end_points);
      if (ZnPolygonInBBox(end_points, ZN_LINE_END_POINTS, area, NULL) != result) {
        return 0;
      }
    }    
  }
  
  /*
   * Last, check markers
   */
  if (ISSET(cv->flags, MARKER_OK)) {
    for (i = 0; i < cv->outlines.num_contours; i++) {
      points = cv->outlines.contours[i].points;
      num_points = cv->outlines.contours[i].num_points;
      
      if (ISSET(cv->flags, FIRST_END_OK)) {
        num_points--;
        points++;
      }
      if (ISSET(cv->flags, LAST_END_OK)) {
        num_points--;
      }
      
      ZnSizeOfImage(cv->marker, &width, &height);
      for (; num_points > 0; num_points--, points++) {
        bbox.orig.x = points->x - (width+1)/2;
        bbox.orig.y = points->y - (height+1)/2;
        bbox.corner.x = bbox.orig.x + width;
        bbox.corner.y = bbox.orig.y + height;
        if (ZnBBoxInBBox(&bbox, area) != result) {
          return 0;
        }
      }
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
  CurveItem     cv = (CurveItem) item;
  XGCValues     values;
  unsigned int  i, j, num_points=0;
  unsigned int  gc_mask;
  ZnPoint       *points=NULL;
  XPoint        *xpoints=NULL;
  
  if ((cv->outlines.num_contours == 0) ||
      (ISCLEAR(cv->flags, FILLED_OK) &&
       !cv->line_width &&
       ISCLEAR(cv->flags, MARKER_OK))) {
    return;
  }

  /*
   * Fill if requested.
   */
  if (ISSET(cv->flags, FILLED_OK)) {
    values.foreground = ZnGetGradientPixel(cv->fill_color, 0.0);
    gc_mask = GCFillStyle;
    if (cv->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(cv->tile)) { /* Fill tiled */
        values.fill_style = FillTiled;
        values.tile = ZnImagePixmap(cv->tile, wi->win);
        values.ts_x_origin = ZnNearestInt(item->item_bounding_box.orig.x);
        values.ts_y_origin = ZnNearestInt(item->item_bounding_box.orig.y);
        gc_mask |= GCTileStipXOrigin|GCTileStipYOrigin|GCTile;
      }
      else { /* Fill stippled */
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(cv->tile, wi->win);
        values.ts_x_origin = ZnNearestInt(item->item_bounding_box.orig.x);
        values.ts_y_origin = ZnNearestInt(item->item_bounding_box.orig.y);
        gc_mask |= GCTileStipXOrigin|GCTileStipYOrigin|GCStipple|GCForeground;
      }
    }
    else { /* Fill solid */
      values.fill_style = FillSolid;
      gc_mask |= GCForeground;
    }
    XChangeGC(wi->dpy, wi->gc, gc_mask, &values);
    

    for (i = 0; i < cv->tristrip.num_strips; i++) {
      num_points = cv->tristrip.strips[i].num_points;
      points = cv->tristrip.strips[i].points;
      if (cv->tristrip.strips[i].fan) {
        XPoint  xpoints[3];
        xpoints[0].x = ZnNearestInt(points[0].x);
        xpoints[0].y = ZnNearestInt(points[0].y);
        xpoints[1].x = ZnNearestInt(points[1].x);
        xpoints[1].y = ZnNearestInt(points[1].y);
        for (j = 2; j < num_points; j++) {
          xpoints[2].x = ZnNearestInt(points[j].x);
          xpoints[2].y = ZnNearestInt(points[j].y);
          XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc,
                       xpoints, 3, Convex, CoordModeOrigin);
          xpoints[1] = xpoints[2];
        }
      }
      else {
        ZnListAssertSize(ZnWorkXPoints, num_points);
        xpoints = ZnListArray(ZnWorkXPoints);
        for (j = 0; j < num_points; j++) {
          xpoints[j].x = ZnNearestInt(points[j].x);
          xpoints[j].y = ZnNearestInt(points[j].y);
        }
        for (j = 0; j < num_points-2; j++) {
          XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc,
                       &xpoints[j], 3, Convex, CoordModeOrigin);
        }
      }
    }
  }

  /*
   * Draw the lines between points
   */
  if (cv->line_width) {
    ZnPoint     end_points[ZN_LINE_END_POINTS];
    XPoint      xp[ZN_LINE_END_POINTS];

    /*
     * Drawing with relief disables: ends, line style and line pattern.
     */
    if (ISSET(cv->flags, RELIEF_OK)) {
      for (j = 0; j < cv->outlines.num_contours; j++) {
        num_points = cv->outlines.contours[j].num_points;
        points = cv->outlines.contours[j].points;
        /*printf("Draw: item %d, num_points %d %g@%g %g@%g, cw %d i/o %d\n",
               item->id,
               num_points, points[0].x, points[0].y,
               points[num_points-1].x, points[num_points-1].y,
               cv->outlines.contours[j].cw);*/
        ZnDrawPolygonRelief(wi, cv->relief, cv->gradient, points, num_points, cv->line_width);
      }
    }
    else {
      ZnSetLineStyle(wi, cv->line_style);
      values.foreground = ZnGetGradientPixel(cv->line_color, 0.0);
      values.line_width = (cv->line_width == 1) ? 0 : (int) cv->line_width;
      values.join_style = cv->join_style;
      values.cap_style = cv->cap_style;
      if (cv->line_pattern == ZnUnspecifiedImage) {
        values.fill_style = FillSolid;
        XChangeGC(wi->dpy, wi->gc,
                  GCFillStyle|GCLineWidth|GCJoinStyle|GCCapStyle|GCForeground, &values);
      }
      else {
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(cv->line_pattern, wi->win);
        XChangeGC(wi->dpy, wi->gc,
                  GCFillStyle|GCStipple|GCLineWidth|GCJoinStyle|GCCapStyle|GCForeground,
                  &values);
      }
      for (j = 0; j < cv->outlines.num_contours; j++) {
        num_points = cv->outlines.contours[j].num_points;
        points = cv->outlines.contours[j].points;
        ZnListAssertSize(ZnWorkXPoints, num_points);
        xpoints = ZnListArray(ZnWorkXPoints);
        for (i = 0; i < num_points; i++) {
          xpoints[i].x = ZnNearestInt(points[i].x);
          xpoints[i].y = ZnNearestInt(points[i].y);
        }
        XDrawLines(wi->dpy, wi->draw_buffer, wi->gc,
                   xpoints, (int) num_points, CoordModeOrigin);
      }
      if (ISSET(cv->flags, FIRST_END_OK)) {
        ZnGetLineEnd(&points[0], &points[1], cv->line_width, cv->cap_style,
                     cv->first_end, end_points);
        for (i = 0; i < ZN_LINE_END_POINTS; i++) {
          xp[i].x = (short) end_points[i].x;
          xp[i].y = (short) end_points[i].y;
        }
        XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, ZN_LINE_END_POINTS,
                     Nonconvex, CoordModeOrigin);
      }
      if (ISSET(cv->flags, LAST_END_OK)) {
        ZnGetLineEnd(&points[num_points-1], &points[num_points-2], cv->line_width,
                     cv->cap_style, cv->last_end, end_points);
        for (i = 0; i < ZN_LINE_END_POINTS; i++) {
          xp[i].x = (short) end_points[i].x;
          xp[i].y = (short) end_points[i].y;
        }
        XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, ZN_LINE_END_POINTS,
                     Nonconvex, CoordModeOrigin);
      }
    }
  }
  
  /*
   * Draw the marks at each point. If arrows are specified or
   * if last point join first point suppress markers at end points.
   */
  if (ISSET(cv->flags, MARKER_OK)) {
    unsigned int h_width, h_height, width, height;
    int          tmp_x, tmp_y;

    ZnSizeOfImage(cv->marker, &width, &height);
    h_width = (width+1)/2;
    h_height = (height+1)/2;
    values.fill_style = FillStippled;
    values.stipple = ZnImagePixmap(cv->marker, wi->win);
    values.foreground = ZnGetGradientPixel(cv->marker_color, 0.0);
    XChangeGC(wi->dpy, wi->gc, GCFillStyle|GCStipple|GCForeground, &values);
    for (j = 0; j < cv->outlines.num_contours; j++) {
      num_points = cv->outlines.contours[j].num_points;
      points = cv->outlines.contours[j].points;
      ZnListAssertSize(ZnWorkXPoints, num_points);
      xpoints = (XPoint *) ZnListArray(ZnWorkXPoints);
      for (i = 0; i < num_points; i++) {
        xpoints[i].x = (short) ZnNearestInt(points[i].x);
        xpoints[i].y = (short) ZnNearestInt(points[i].y);
      }
      if (ISSET(cv->flags, FIRST_END_OK)) {
        num_points--;
        points++;
      }
      if (ISSET(cv->flags, LAST_END_OK)) {
        num_points--;
      }
      for (; num_points > 0; num_points--, points++) {
        tmp_x = ((int) points->x) - h_width;
        tmp_y = ((int) points->y) - h_height;
        values.ts_x_origin = tmp_x;
        values.ts_y_origin = tmp_y;
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCForeground, &values);
        XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc,
                       tmp_x, tmp_y, width, height);
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
CurveRenderCB(void      *closure)
{
  CurveItem     cv = (CurveItem) closure;
  unsigned int  i, j, num_points;
  ZnPoint       *points;

  for (i = 0; i < cv->tristrip.num_strips; i++) {
    num_points = cv->tristrip.strips[i].num_points;
    points = cv->tristrip.strips[i].points;
    if (cv->tristrip.strips[i].fan) {
      glBegin(GL_TRIANGLE_FAN);
    }
    else {
      glBegin(GL_TRIANGLE_STRIP);
    }
    for (j = 0; j < num_points; j++, points++) {
      glVertex2d(points->x, points->y);
    }
    glEnd();
  }
}
#endif

#ifdef GL
static void
Render(ZnItem   item)
{
  ZnWInfo       *wi  = item->wi;
  CurveItem     cv = (CurveItem) item;
  unsigned int  j, num_points;
  ZnPoint       *points;

  if ((cv->outlines.num_contours == 0) ||
      (ISCLEAR(cv->flags, FILLED_OK) &&
       !cv->line_width &&
       ISCLEAR(cv->flags, MARKER_OK))) {
    return;
  }

#ifdef GL_LIST
  if (!item->gl_list) {
    item->gl_list = glGenLists(1);
    glNewList(item->gl_list, GL_COMPILE);
#endif
    /*
     * Fill if requested.
     */
    if (ISSET(cv->flags, FILLED_OK)) {
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      if (!ZnGradientFlat(cv->fill_color)) {
        ZnRenderGradient(wi, cv->fill_color, CurveRenderCB, cv, cv->grad_geo,
                         &cv->outlines);
      }
      else if (cv->tile != ZnUnspecifiedImage) { /* Fill tiled/stippled */
        ZnRenderTile(wi, cv->tile, cv->fill_color, CurveRenderCB, cv,
                     (ZnPoint *) &item->item_bounding_box);
      }
      else {
        unsigned short alpha;
        XColor *color = ZnGetGradientColor(cv->fill_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        CurveRenderCB(cv);
      }
    }
    
    /*
     * Draw the lines between points
     */
    if (cv->line_width) {
      /*
       * Drawing with relief disables: ends, line style and line pattern.
       */
      if (ISSET(cv->flags, RELIEF_OK)) {
        for (j = 0; j < cv->outlines.num_contours; j++) {
          num_points = cv->outlines.contours[j].num_points;
          points = cv->outlines.contours[j].points;
          /*printf("Render: item %d, num_points %d %g@%g %g@%g, cw %d i/o %d\n",
            item->id,
            num_points, points[0].x, points[0].y,
            points[num_points-1].x, points[num_points-1].y,
            cv->outlines.contours[j].cw);*/
          ZnRenderPolygonRelief(wi, cv->relief, cv->gradient,
                                ISSET(cv->flags, SMOOTH_RELIEF_BIT),
                                points, num_points, cv->line_width);
        }
      }
      else {
        ZnLineEnd first = ISSET(cv->flags, FIRST_END_OK) ? cv->first_end : NULL;
        ZnLineEnd last = ISSET(cv->flags, LAST_END_OK) ? cv->last_end : NULL;
        
        for (j = 0; j < cv->outlines.num_contours; j++) {
          ZnRenderPolyline(wi,
                           cv->outlines.contours[j].points,
                           cv->outlines.contours[j].num_points,
                           cv->line_width, cv->line_style, cv->cap_style,
                           cv->join_style, first, last, cv->line_color);
        }
      }
    }
    
    /*
     * Draw the marks at each point. If arrows are specified or
     * if last point join first point suppress markers at end points.
     */
    if (ISSET(cv->flags, MARKER_OK)) {
      int       i_width, i_height;
      ZnReal    r_width, r_height;
      ZnPoint   ptmp;
      
      ZnSizeOfImage(cv->marker, &i_width, &i_height);
      r_width = (i_width+1.0)/2.0;
      r_height = (i_height+1.0)/2.0;
      for (j = 0; j < cv->outlines.num_contours; j++) {
        num_points = cv->outlines.contours[j].num_points;
        points = cv->outlines.contours[j].points;
        if (ISSET(cv->flags, FIRST_END_OK)) {
          num_points--;
          points++;
        }
        if (ISSET(cv->flags, LAST_END_OK)) {
          num_points--;
        }
        for (; num_points > 0; num_points--, points++) {
          ptmp.x = points->x - r_width;
          ptmp.y = points->y - r_height;
          ZnRenderIcon(wi, cv->marker, cv->marker_color, &ptmp, True);
        }
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
  CurveItem     cv = (CurveItem) item;
  ZnBBox        bbox;
  double        dist=1.0e40, new_dist;
  ZnPoint       *points, *p = ps->point;
  ZnPoint       end_points[ZN_LINE_END_POINTS];
  ZnPoint       triangle[3];
  unsigned int  num_points, i, j, stop;
  int           width, height;
  
  if (cv->outlines.num_contours == 0) {
    return dist;
  }
  
/*printf("Pick in curve\n");*/
  if (ISSET(cv->flags, FILLED_OK)) {
    for (i = 0; i < cv->tristrip.num_strips; i++) {
      num_points = cv->tristrip.strips[i].num_points;
      points = cv->tristrip.strips[i].points;
      j = 0;
      stop = num_points-2;
      if (cv->tristrip.strips[i].fan) {
        triangle[0] = points[0];
        j++;
        points++;
        stop++;
      }
      for (; j < stop; j++, points++) {
        if (cv->tristrip.strips[i].fan) {
          triangle[1] = points[0];
          triangle[2] = points[1];
        }
        else {
          triangle[0] = points[0];
          triangle[1] = points[1];
          triangle[2] = points[2];
        }
        new_dist = ZnPolygonToPointDist(triangle, 3, p);
        if (new_dist < dist) {
          dist = new_dist;
        }
        if (dist <= 0.0) {
          return 0.0;
        }
      }
    }
  }

  if (cv->line_width > 0) {
    /*
     * Check all contours.
     */
    for (i = 0; i < cv->outlines.num_contours; i++) {
      points = cv->outlines.contours[i].points;
      num_points = cv->outlines.contours[i].num_points;
      if (ISCLEAR(cv->flags, RELIEF_OK)) {
        new_dist = ZnPolylineToPointDist(points, num_points,
                                         cv->line_width, cv->cap_style, cv->join_style, p);
        if (new_dist < dist) {
          dist = new_dist;
        }
        if (dist <= 0.0) {
          /*printf("dist %g\n", dist);*/
          return 0.0;
        }
      }
      else {
        new_dist = ZnPolygonReliefToPointDist(points, num_points, cv->line_width, p);
        if (new_dist < dist) {
          dist = new_dist;
        }
        if (dist <= 0.0) {
          /*printf("dist %g\n", dist);*/
          return 0.0;
        }
      }
    }
  }
  
  /*
   * Line ends are checked only on the first contour.
   */
  points = cv->outlines.contours[0].points;
  num_points = cv->outlines.contours[0].num_points;
  /*
   * Check line ends.
   */
  if (ISSET(cv->flags, FIRST_END_OK)) {
    ZnGetLineEnd(&points[0], &points[1], cv->line_width, cv->cap_style,
                 cv->first_end, end_points);
    new_dist = ZnPolygonToPointDist(end_points, ZN_LINE_END_POINTS, p);
    if (new_dist < dist) {
      dist = new_dist;
    }
    if (dist <= 0.0) {
      /*printf("dist %g\n", dist);*/
      return 0.0;
    }
  }
  if (ISSET(cv->flags, LAST_END_OK)) {
    ZnGetLineEnd(&points[num_points-1], &points[num_points-2], cv->line_width,
                 cv->cap_style, cv->last_end, end_points);
    new_dist = ZnPolygonToPointDist(end_points, ZN_LINE_END_POINTS, p);
    if (new_dist < dist) {
      dist = new_dist;
    }
    if (dist <= 0.0) {
      /*printf("dist %g\n", dist);*/
      return 0.0;
    }
  }
  
  /*
   * Last, check markers on all contours.
   */
  if (ISSET(cv->flags, MARKER_OK)) {
    for (i = 0; i < cv->outlines.num_contours; i++) {
      points = cv->outlines.contours[i].points;
      num_points = cv->outlines.contours[i].num_points;
      
      if (ISSET(cv->flags, FIRST_END_OK)) {
        num_points--;
        points++;
      }
      if (ISSET(cv->flags, LAST_END_OK)) {
        num_points--;
      }
      
      ZnSizeOfImage(cv->marker, &width, &height);
      for (; num_points > 0; num_points--, points++) {
        bbox.orig.x = points->x - (width+1)/2;
        bbox.orig.y = points->y - (height+1)/2;
        bbox.corner.x = bbox.orig.x + width;
        bbox.corner.y = bbox.orig.y + height;
        new_dist = ZnRectangleToPointDist(&bbox, p);
        if (new_dist < dist) {
          dist = new_dist;
        }
        if (dist <= 0.0) {
          /*printf("dist %g\n", dist);*/
          return 0.0;
        }
      }
    }
  }

  /*printf("dist %g\n", dist);*/
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
  ZnWInfo   *wi = item->wi;
  CurveItem cv = (CurveItem) item;
  char      path[500];
  ZnContour *contours;
  ZnPoint   *points;
  int       num_contours, num_points;
  int       i, j;

  num_contours = cv->outlines.num_contours;
  contours = cv->outlines.contours;

  /*
   * Put all contours in an array on the stack
   */
  if (ISSET(cv->flags, FILLED_BIT) || cv->line_width) {
    Tcl_AppendResult(wi->interp, "newpath ", NULL);
    for (i = 0; i < num_contours; i++, contours++) {
      num_points = contours->num_points;
      points = contours->points;
      sprintf(path, "%.15g %.15g moveto\n", points[0].x, points[0].y);
      Tcl_AppendResult(wi->interp, path, NULL);
      for (j = 1; j < num_points; j++) {
        sprintf(path, "%.15g %.15g lineto ", points[j].x, points[j].y);
        Tcl_AppendResult(wi->interp, path, NULL);
        if (((j+1) % 5) == 0) {
          Tcl_AppendResult(wi->interp, "\n", NULL);
        }
      }
    }
  }

  /*
   * Emit code to draw the filled area.
   */
  if (ISSET(cv->flags, FILLED_BIT)) {
    if (cv->line_width) {
      Tcl_AppendResult(wi->interp, "gsave\n", NULL);
    }
    if (!ZnGradientFlat(cv->fill_color)) {
      if (ZnPostscriptGradient(wi->interp, wi->ps_info, cv->fill_color,
                               cv->grad_geo, NULL) != TCL_OK) {
        return TCL_ERROR;
      }
    }
    else if (cv->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(cv->tile)) { /* Fill tiled */
        /* TODO No support yet */
      }
      else { /* Fill stippled */
        if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                               ZnGetGradientColor(cv->fill_color, 0.0, NULL)) != TCL_OK) {
          return TCL_ERROR;
        }
        Tcl_AppendResult(wi->interp, "clip ", NULL);
        if (Tk_PostscriptStipple(wi->interp, wi->win, wi->ps_info,
                                 ZnImagePixmap(cv->tile, wi->win)) != TCL_OK) {
          return TCL_ERROR;
        }
      }
    }
    else { /* Fill solid */
      if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                             ZnGetGradientColor(cv->fill_color, 0.0, NULL)) != TCL_OK) {
        return TCL_ERROR;
      }
      Tcl_AppendResult(wi->interp, "fill\n", NULL);
    }
    if (cv->line_width) {
      Tcl_AppendResult(wi->interp, "grestore\n", NULL);
    }
  }

  /*
   * Then emit code code to stroke the outline.
   */
  if (cv->line_width) {
    if (cv->relief != ZN_RELIEF_FLAT) {
      /* TODO No support yet */
    }
    else {
      Tcl_AppendResult(wi->interp, "0 setlinejoin 2 setlinecap\n", NULL);
      if (ZnPostscriptOutline(wi->interp, wi->ps_info, wi->win,
                              cv->line_width, cv->line_style,
                              cv->line_color, cv->line_pattern) != TCL_OK) {
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
  CurveItem     cv = (CurveItem) item;

  tristrip->num_strips = 0;

  if (cv->tristrip.num_strips == 1) {
    ZnTriStrip1(tristrip,
                cv->tristrip.strips[0].points,
                cv->tristrip.strips[0].num_points,
                cv->tristrip.strips[0].fan);
  }
  else if (cv->tristrip.num_strips > 1) {
    tristrip->num_strips = cv->tristrip.num_strips;
    tristrip->strips = cv->tristrip.strips;
  }

  return False;
}


/*
 **********************************************************************************
 *
 * GetContours --
 *      Get the external contour(s).
 *      Never ever call ZnPolyFree on the poly returned by GetContours.
 *
 **********************************************************************************
 */
static ZnBool
GetContours(ZnItem      item,
            ZnPoly      *poly)
{
  CurveItem     cv = (CurveItem) item;

  if (cv->outlines.num_contours == 1) {
    ZnPolyContour1(poly, cv->outlines.contours[0].points,
                   cv->outlines.contours[0].num_points,
                   cv->outlines.contours[0].cw);
  }
  else if (cv->outlines.num_contours > 1) {
    poly->num_contours = cv->outlines.num_contours;
    poly->contours = cv->outlines.contours;
  }
  
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
  CurveItem     cv = (CurveItem) item;
  unsigned int  j, num_controls;
  int           i;
  ZnContour     *c=NULL;

  /*printf("contour %d, num_pts %d, index %d, cmd %d\n",
    contour, *num_pts, index, cmd);*/
  /*printf("nb contours: %d\n", cv->shape.num_contours);*/
  /*
   * Special case for reading an empty curve.
   */
  if (((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) &&
      (cv->shape.num_contours == 0)) {
    *num_pts = 0;
    return TCL_OK;
  }

  if (contour < 0) {
    contour += cv->shape.num_contours;
  }
  if ((contour < 0) || ((unsigned int) contour >= cv->shape.num_contours)) {
    Tcl_AppendResult(item->wi->interp,
                     " curve contour index out of range", NULL);
    return TCL_ERROR;
  }
  if (cv->shape.num_contours != 0) {
    c = &cv->shape.contours[contour];
  }

  /* REPLACE */
  
  if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (cmd == ZN_COORDS_REPLACE_ALL) {
      /*
       * Replacing all the coordinates of a contour by no coordinates
       * is also legal, resulting in the contour being removed.
       */
      if (*num_pts) {
        if (c->points) {
          ZnFree(c->points); 
        }
        c->points = ZnMalloc(*num_pts*sizeof(ZnPoint));
        c->num_points = *num_pts;
        memcpy(c->points, *pts, *num_pts*sizeof(ZnPoint));
        if (c->controls) {
          ZnFree(c->controls);
          c->controls = NULL;
        }
        if (*controls) {
          c->controls = ZnMalloc(*num_pts*sizeof(char));
          memcpy(c->controls, *controls, *num_pts*sizeof(char));
        }
      }
    }
    else {
      if (*num_pts == 0) {
        Tcl_AppendResult(item->wi->interp,
                         " coords replace command need at least 1 point on curves", NULL);
        return TCL_ERROR;
      }
      if (index < 0) {
        index += c->num_points;
      }
      if ((index < 0) || ((unsigned int) index >= c->num_points)) {
      range_err:
        Tcl_AppendResult(item->wi->interp, " coord index out of range", NULL);
        return TCL_ERROR;
      }
      /*printf("--->%g@%g\n", (*pts)[0].x, (*pts)[0].y);*/
      c->points[index] = (*pts)[0];
      if (!c->controls && *controls && (*controls)[0]) {
        c->controls = ZnMalloc(c->num_points*sizeof(char));
        memset(c->controls, 0, c->num_points*sizeof(char));
      }
      if (c->controls) {
        if (!*controls) {
          c->controls[index] = 0;
        }
        else {
          if ((*controls)[0]) {
            /* Check if the edit is allowable, there should be
             * no more than 2 consecutive control points. The first
             * point must not be a control and the last one can
             * be one only if the curve is closed.
             */
            num_controls = 0;
            if (!index) {
            control_first:
              Tcl_AppendResult(item->wi->interp, " the first point must not be a control", NULL);
              return TCL_ERROR;       
            }
            else if ((unsigned int) index == c->num_points-1) {
              if (ISCLEAR(cv->flags, CLOSED_BIT) &&
                  (cv->shape.num_contours == 1)) {
              control_last:
                Tcl_AppendResult(item->wi->interp, " the last point must not be a control", NULL);
                return TCL_ERROR;             
              }
            }
            else {
              for (i = index-1; c->controls[i] && (i >= 0); i--, num_controls++);
            }
            for (j = index+1; c->controls[j] && (j < c->num_points); j++, num_controls++);
            if (num_controls > 1) {
            control_err:
              Tcl_AppendResult(item->wi->interp, " too many consecutive control points in a curve", NULL);
              return TCL_ERROR;
            }
          }
          c->controls[index] = (*controls)[0];
        }
      }
    }
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  
  /* READ */
  
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    if (cmd == ZN_COORDS_READ_ALL) {
      *num_pts = c->num_points;
      *pts = c->points;
      if (c->controls) {
        *controls = c->controls;
      }
    }
    else {
      /* Special case for an empty contour. */
      if (c->num_points == 0) {
        *num_pts = 0;
        return TCL_OK;
      }
      if (index < 0) {
        index += c->num_points;
      }
      if ((index < 0) || ((unsigned int) index >= c->num_points)) {
        goto range_err;
      }
      *num_pts = 1;
      *pts = &c->points[index];
      if (c->controls) {
        *controls = &c->controls[index];
      }
    }
  }

  /* ADD */
  
  else if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST)) {
    if (*num_pts == 0) {
      return TCL_OK;
    }
    if (cmd == ZN_COORDS_ADD_LAST) {
      index = c->num_points;
    }
    if (index < 0) {
      index += c->num_points;
    }
    if ((index < 0) || ((unsigned int) index > c->num_points)) {
      goto range_err;
    }
    if (*controls) {
      /* Check if the edit is allowable, there should be
       * no more than 2 consecutive control points. The first
       * point must not be a control and the last one can
       * be one only if the curve is closed.
       */
      if ((index == 0) && (*controls)[0]) {
        goto control_first;
      }
      else if (((unsigned int) index == (c->num_points-1)) &&
               (*controls)[*num_pts-1] &&
               ISCLEAR(cv->flags, CLOSED_BIT) &&
               (cv->shape.num_contours == 1)) {
        goto control_last;
      }

      num_controls = 0;
      if (c->controls) {
        if (index) {
          for (i = index-1; c->controls[i] && (i >= 0); i--, num_controls++);
        }
      }
      /*printf("******* num controls: %d\n", num_controls);*/
      for (j = 0; j < *num_pts; j++) {
        if (!(*controls)[j]) {
          num_controls = 0;
        }
        else {
          num_controls++;
          if (num_controls > 2) {
            goto control_err;
          }
        }
      }
      /*printf("******* num controls(2): %d\n", num_controls);*/
      if (c->controls) {
        for (j = index; c->controls[j] && (j < c->num_points); j++, num_controls++);
      }
      /*printf("******* num controls(3): %d\n", num_controls);*/
      if (num_controls > 2) {
        goto control_err;
      }
    }
    c->points = ZnRealloc(c->points, (c->num_points+*num_pts)*sizeof(ZnPoint));
    if (*controls || c->controls) {
      if (c->controls) {
        c->controls = ZnRealloc(c->controls, (c->num_points+*num_pts)*sizeof(char));
      }
      else {
        c->controls = ZnMalloc((c->num_points+*num_pts)*sizeof(char));
        memset(c->controls, 0, (c->num_points+*num_pts)*sizeof(char));
      }
    }
    /*
     * Make a hole if needed.
     */
    for (i = c->num_points-1; i >= index; i--) {
      c->points[i+*num_pts] = c->points[i];
      if (c->controls) {
        c->controls[i+*num_pts] = c->controls[i];
      }
    }
    for (j = 0; j < *num_pts; j++, index++) {
      c->points[index] = (*pts)[j];
      if (c->controls) {
        c->controls[index] = (*controls)?(*controls)[j]:0;
      }
    }
    c->num_points += *num_pts;
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }

  /* REMOVE */
  
  else if (cmd == ZN_COORDS_REMOVE) {
    if (index < 0) {
      index += c->num_points;
    }
    if ((index < 0) || ((unsigned int) index >= c->num_points)) {
      goto range_err;
    }

    if (c->controls) {
      /* Check if the edit is allowable, there should be
       * no more than 2 consecutive control points .
       */
      for (num_controls = 0, i = index-1; !c->controls[i]; i--, num_controls++);
      for (i = index+1; !c->controls[i]; i++, num_controls++);
      if (num_controls > 2) {
        goto control_err;
      }
    }

    c->num_points--;
    if ((c->num_points != 0) && ((unsigned int) index != c->num_points)) {
      for (j = index; j < c->num_points; j++) {
        c->points[j] = c->points[j+1];
        if (c->controls) {
          c->controls[j] = c->controls[j+1];
        }
      }
    }
    c->points = ZnRealloc(c->points, (c->num_points)*sizeof(ZnPoint));
    if (c->controls) {
      c->controls = ZnRealloc(c->controls, (c->num_points)*sizeof(char));
    }
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Contour --
 *      Perform geometric operations on curve contours.
 *
 **********************************************************************************
 */
static int
Contour(ZnItem  item,
        int     cmd,
        int     index,
        ZnPoly  *poly)
{
  CurveItem     cv = (CurveItem) item;
  unsigned int  j, num_contours;
  int           i;

  switch (cmd) {
  case ZN_CONTOUR_ADD:
    if (index < 0) {
      index += cv->shape.num_contours;
    }
    if ((unsigned int) index > cv->shape.num_contours) {
      index = cv->shape.num_contours;
    }
    if (index < 0) {
    contour_err:
      Tcl_AppendResult(item->wi->interp, " contour index out of range", NULL);
      return TCL_ERROR;
    }
    num_contours = cv->shape.num_contours + poly->num_contours;
    if (cv->shape.contours == &cv->shape.contour1) {
      cv->shape.contours = ZnMalloc(num_contours*sizeof(ZnContour));
      cv->shape.contours[0].num_points = cv->shape.contour1.num_points;
      cv->shape.contours[0].cw = cv->shape.contour1.cw;
      cv->shape.contours[0].points = cv->shape.contour1.points;
      cv->shape.contours[0].controls = cv->shape.contour1.controls;
    }
    else {
      cv->shape.contours = ZnRealloc(cv->shape.contours, num_contours*sizeof(ZnContour));
      /*printf("Reallocating shape contours (%d) 0x%X\n", num_contours, cv->shape.contours);*/
    }
    /*
     * Make a hole if needed.
     */
    /*printf("index : %d, i : %d\n", index, cv->shape.num_contours-1);*/
    for (i = cv->shape.num_contours-1; i >= index; i--) {
      cv->shape.contours[i+poly->num_contours] = cv->shape.contours[i];
    }
    for (j = 0; j < poly->num_contours; j++, index++) {
      cv->shape.contours[index].num_points = poly->contours[j].num_points;
      cv->shape.contours[index].cw = poly->contours[j].cw;
      cv->shape.contours[index].points = poly->contours[j].points;
      cv->shape.contours[index].controls = NULL;
      if (poly->contours[j].controls) {
        /*
         * The controls array in poly is shared, duplicate it
         * to keep a locally owned copy.
         */
        cv->shape.contours[index].controls = poly->contours[j].controls;
      }
    }
    cv->shape.num_contours = num_contours;
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);  
    break;
  case ZN_CONTOUR_REMOVE:
    if (index < 0) {
      index += cv->shape.num_contours;
    }
    if ((unsigned int) index >= cv->shape.num_contours) {
      index = cv->shape.num_contours - 1;
    }
    if (index < 0) {
      goto contour_err;
    }
    cv->shape.num_contours--;
    if (cv->shape.num_contours == 0) {
      ZnPolyFree(&cv->shape);
    }
    else {
      ZnFree(cv->shape.contours[index].points);
      if (cv->shape.contours[index].controls) {
        ZnFree(cv->shape.contours[index].controls);
      }
      for (j = index; j < cv->shape.num_contours; j++) {
        cv->shape.contours[j] = cv->shape.contours[j+1];
      }
    }
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);  
    break;
  }

  return cv->shape.num_contours;
}


/*
 **********************************************************************************
 *
 * PickVertex --
 *      Return in 'vertex' the vertex closest to p and in 'o_vertex' the
 *      opposite vertex on the closest edge, if such an edge exists or -1
 *      in the other case.
 *
 **********************************************************************************
 */
static void
PickVertex(ZnItem       item,
           ZnPoint      *p,
           int          *contour,
           int          *vertex,
           int          *o_vertex)
{
  CurveItem     cv = (CurveItem) item;
  unsigned int  i, j, k, num_points;
  ZnPoint       *points, po;
  ZnReal        dist=1.0e40, new_dist, dist2;
  ZnTransfo     t, inv;
  
  *contour = *vertex = *o_vertex = -1;
  
  if ((cv->line_width > 0) ||
      ISSET(cv->flags, FILLED_OK) ||
      ISSET(cv->flags, MARKER_OK)) {

    /*
     * Get the point in the item coordinate space.
     */
    ZnITEM.GetItemTransform(item, &t);
    ZnTransfoInvert(&t, &inv);
    ZnTransformPoint(&inv, p, &po);

    /*
     * Check all contours.
     */
    for (i = 0; i < cv->shape.num_contours; i++) {
      points = cv->shape.contours[i].points;
      num_points = cv->shape.contours[i].num_points;
      for (j = 0; j < num_points; j++) {
        new_dist = hypot(points[j].x - po.x, points[j].y - po.y);
        if (new_dist < dist) {
          dist = new_dist;
          *contour = i;
          *vertex = j;
        }
      }
      /*
       * If the closest vertex is in the current contour update
       * the opposite vertex.
       */
      if (i == (unsigned int) *contour) {
        j = (*vertex+1) % num_points;
        new_dist = ZnLineToPointDist(&points[*vertex], &points[j], &po, NULL);
        k = ((unsigned int)(*vertex-1)) % num_points;
        dist2 = ZnLineToPointDist(&points[*vertex], &points[k], &po, NULL);
        if (dist2 < new_dist) {
          *o_vertex = k;
        }
        else {
          *o_vertex = j;
        }
      }
    }
  }
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
static ZnItemClassStruct CURVE_ITEM_CLASS = {
  "curve",
  sizeof(CurveItemStruct),
  cv_attrs,
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
  Contour,
  ComputeCoordinates,
  ToArea,
  Draw,
  Render,
  IsSensitive,
  Pick,
  PickVertex,           /* PickVertex */
  PostScript
};

ZnItemClassId ZnCurve = (ZnItemClassId) &CURVE_ITEM_CLASS;
