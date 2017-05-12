/*
 * Draw.c -- Implementation of common drawing routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Sat Dec 10 12:51:30 1994
 *
 * $Id: Draw.c,v 1.64 2005/09/12 13:19:13 Lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


/*
 **********************************************************************************
 *
 * The algorihms used to draw the arrows, to do the 3d effects and to
 * smooth the polygons are adapted from Tk.
 *
 **********************************************************************************
 */

#include "Types.h"
#include "Draw.h"
#include "Geo.h"
#include "List.h"
#include "WidgetInfo.h"
#include "Image.h"
#include "tkZinc.h"

#include <math.h>
#include <stdarg.h>


#define POLYGON_RELIEF_DRAW     0
#define POLYGON_RELIEF_RENDER   1
#define POLYGON_RELIEF_DIST     2
#define POLYGON_RELIEF_BBOX     3
#define POLYGON_RELIEF_IN_BBOX  4

#define TOP_CONTRAST            13
#define BOTTOM_CONTRAST         6
#define MAX_INTENSITY           65535

#define ARROW_SHAPE_B           10.0
#define ARROW_SHAPE_C           5.0
#define OPEN_ARROW_SHAPE_A      4.0
#define CLOSED_ARROW_SHAPE_A    ARROW_SHAPE_B

#define LIGHTNING_SHAPE_A_RATIO 10.0
#define LIGHTNING_SHAPE_B_RATIO 8.0

#define LIGHTNING_POINTS        4
#define CORNER_POINTS           3
#define DOUBLE_CORNER_POINTS    4
#define STRAIGHT_POINTS         2


/*
 **********************************************************************************
 *
 * ZnSetLineStyle -- 
 *
 **********************************************************************************
 */
void
ZnSetLineStyle(ZnWInfo     *wi,
               ZnLineStyle line_style)
{
  if (wi->render) {
#ifdef GL
    switch (line_style) {
    case ZN_LINE_DASHED :
      glLineStipple(1, 0xF0F0);      
      glEnable(GL_LINE_STIPPLE);
      break;
    case ZN_LINE_MIXED :
      glLineStipple(1, 0x27FF);      
      glEnable(GL_LINE_STIPPLE);
      break;
    case ZN_LINE_DOTTED :
      glLineStipple(1, 0x18C3);      
      glEnable(GL_LINE_STIPPLE);
      break;
    default:
      glDisable(GL_LINE_STIPPLE);
    }
#endif
  }
  else {
    XGCValues           values;
    static const char   dashed[] = { 8 };
    static const char   dotted[] = { 2, 5 };
    static const char   mixed[]  = { 8, 5, 2, 5 };
    
    values.line_style = LineOnOffDash;
    switch (line_style) {
    case ZN_LINE_DASHED :
      XSetDashes(wi->dpy, wi->gc, 0, dashed, 1);
      break;
    case ZN_LINE_MIXED :
      XSetDashes(wi->dpy, wi->gc, 0, mixed, 4);
      break;
    case ZN_LINE_DOTTED :
      XSetDashes(wi->dpy, wi->gc, 0, dotted, 2);
      break;
    default:
      values.line_style = LineSolid;
      break;
    }
    XChangeGC(wi->dpy, wi->gc, GCLineStyle, &values);
  }
}


/*
 **********************************************************************************
 *
 * ZnLineShapePoints --
 *      Compute the points describing the given line shape between point p1 and p2.
 *      If bbox is non null, it is filled with the bounding box of the shape.
 *
 * For the time being this procedure handles straight lines, right and left
 * lightnings, right and left corners, right and left double corners..
 *
 *
 * Here are the parameters for lightnings:
 *
 *                                        *******
 *                                 *******     *
 *                           ******           *
 *                     ******      ******+   *
 *               ******      ******     *   *|
 *         ******      ******          *   * | LIGHTNING_SHAPE_A
 *   ******      ******               *   *  |
 *         ******                    *   *   |
 * ..******.........................+.+.*........................******..
 *   |                             *   *                    ******
 *   |                            *   *               ******      ******
 *   |                           *   *          ******      ******
 *   |                          *   *     ******      ******
 *   |                         *   *******      ******
 *   |                        *          ******
 *   |                       *     ******
 *   |                      ********   
 *   |                         |    | |
 *   |                         |----| | LIGHTNING_SHAPE_B
 *   |                                |
 *   |--------------------------------| LENGTH / 2
 *
 **********************************************************************************
 */
void
ZnLineShapePoints(ZnPoint       *p1,
                  ZnPoint       *p2,
                  ZnDim         line_width,
                  ZnLineShape   shape,
                  ZnBBox        *bbox,
                  ZnList        to_points)
{
  ZnPoint       *points;
  unsigned int  num_points, i;

  /*
   * Compute all line points according to shape.
   */
  if ((shape == ZN_LINE_LEFT_LIGHTNING) ||
      (shape == ZN_LINE_RIGHT_LIGHTNING)) {
    double      alpha, theta;
    double      length, length2;
    double      shape_a, shape_b;
    double      dx, dy;
    double      temp;

    num_points = LIGHTNING_POINTS;
    ZnListAssertSize(to_points, num_points);
    points = (ZnPoint *) ZnListArray(to_points);

    points[0] = *p1;
    points[3] = *p2;

    dx = p2->x - p1->x;
    dy = p2->y - p1->y;
    length = hypot(dx, dy);
    shape_a = length/LIGHTNING_SHAPE_A_RATIO + line_width/2.0;
    shape_b = length/LIGHTNING_SHAPE_B_RATIO + line_width/2.0;

    if (shape == ZN_LINE_LEFT_LIGHTNING)
      alpha = atan2(shape_a, shape_b);
    else
      alpha = -atan2(shape_a, shape_b);
    length2 = hypot(shape_a, shape_b);
    theta = atan2(-dy, dx);

    dx = p1->x + dx/2;
    dy = p1->y + dy/2;
    temp = cos(theta + alpha) * length2;
    points[1].x = dx + temp;
    points[2].x = dx - temp;
    temp = sin(theta + alpha) * length2;
    points[1].y = dy - temp;
    points[2].y = dy + temp;
  }
  else if (shape == ZN_LINE_LEFT_CORNER ||
           shape == ZN_LINE_RIGHT_CORNER) {
    num_points = CORNER_POINTS;
    ZnListAssertSize(to_points, num_points);
    points = (ZnPoint *) ZnListArray(to_points);

    points[0] = *p1;
    points[2] = *p2;

    if (shape == ZN_LINE_LEFT_CORNER) {
      points[1].x = p1->x;
      points[1].y = p2->y;
    }
    else {
      points[1].x = p2->x;
      points[1].y = p1->y;
    }
  }
  else if (shape == ZN_LINE_DOUBLE_LEFT_CORNER ||
           shape == ZN_LINE_DOUBLE_RIGHT_CORNER) {
    int dx, dy;

    num_points = DOUBLE_CORNER_POINTS;
    ZnListAssertSize(to_points, num_points);
    points = (ZnPoint *) ZnListArray(to_points);

    points[0] = *p1;
    points[3] = *p2;

    if (shape == ZN_LINE_DOUBLE_LEFT_CORNER) {
      dy = (int) (p2->y - p1->y);
      points[1].x = p1->x;
      points[2].x = p2->x;
      points[1].y = points[2].y = p1->y + dy/2;
    }
    else {
      dx = (int) (p2->x - p1->x);
      points[1].x = points[2].x = p1->x + dx/2;
      points[1].y = p1->y;
      points[2].y = p2->y;
    }
  }
  else /* if (shape) == ZN_LINE_STRAIGHT) */ {
    num_points = STRAIGHT_POINTS;
    ZnListAssertSize(to_points, num_points);
    points = (ZnPoint *) ZnListArray(to_points);

    points[0] = *p1;
    points[1] = *p2;
  }

  /*
   * Fill in the bbox, if requested.
   */
  if (bbox) {
    ZnResetBBox(bbox);
    for (i = 0; i < num_points; i++) {
      ZnAddPointToBBox(bbox, points[i].x, points[i].y);
    }
    
    /* Enlarge to take line_width into account. */
    if (line_width > 1) {
      ZnDim lw_2 = (line_width+1)/2;
      
      bbox->orig.x -= lw_2;
      bbox->orig.y -= lw_2;
      bbox->corner.x += lw_2;
      bbox->corner.y += lw_2;
    }
  }
}


/*
 **********************************************************************************
 *
 * ZnDrawLineShape --
 *      Draw a line given the points describing its path. It is designed to work
 *      with GetLineShape albeit it does fairly trivial things. In the future some
 *      shapes might need cooperation between the two and the clients will be ready
 *      for that.
 *
 *
 **********************************************************************************
 */
void
ZnDrawLineShape(ZnWInfo         *wi,
                ZnPoint         *p,
                unsigned int    num_p,
                ZnLineStyle     line_style,
                int             foreground_pixel,
                ZnDim           line_width,
                ZnLineShape     shape)
{
  XPoint        *xpoints;
  unsigned int  i;
  XGCValues     values;

  /*
   * Setup GC.
   */
  ZnSetLineStyle(wi, line_style);
  values.foreground = foreground_pixel;
  values.line_width = (line_width == 1) ? 0 : (int) line_width;
  values.fill_style = FillSolid;
  values.join_style = JoinRound;
  values.cap_style = CapRound;
  XChangeGC(wi->dpy, wi->gc,
            GCFillStyle|GCLineWidth|GCJoinStyle|GCCapStyle|GCForeground, &values);
  ZnListAssertSize(ZnWorkXPoints, num_p);
  xpoints = (XPoint *) ZnListArray(ZnWorkXPoints);
  for (i = 0; i < num_p; i++) {
    xpoints[i].x = (short) p[i].x;
    xpoints[i].y = (short) p[i].y;
  }
  XDrawLines(wi->dpy, wi->draw_buffer, wi->gc, xpoints, (int) num_p, CoordModeOrigin);
}


/*
 **********************************************************************************
 *
 * ZnGetLineEnd --
 *      Compute the points describing the given line end style at point p1 for
 *      the line p1,p2. Point p1 is adjusted to fit the line end.
 *      If bbox is non null, it is filled with the bounding box of the end.
 *
 * For the time being this procedure handles open/filled arrows.
 *
 * Here are the parameters describing arrows.
 *
 *              *  | ARROW_SHAPE_C
 *            **   |
 *          * ***************************
 *        *  *
 *      *   *  +p1                      +p2
 *      | * |*
 *      |   * ***************************
 *      |   | **
 *      |   |   *
 *      |   |   |
 *      |---|   | ARROW_SHAPE_A
 *      |       |
 *      |-------| ARROW_SHAPE_B
 *
 **********************************************************************************
 */
void
ZnGetLineEnd(ZnPoint    *p1,
             ZnPoint    *p2,
             ZnDim      line_width,
             int        cap_style,
             ZnLineEnd  end_style,
             ZnPoint    *points)
{
  ZnReal        dx, dy, length, temp, backup;
  ZnReal        frac_height, sin_theta, cos_theta;
  ZnReal        vert_x, vert_y;
  ZnReal        shape_a, shape_b, shape_c;
  
  if (end_style != NULL) {
    shape_a = end_style->shape_a + 0.001;
    shape_b = end_style->shape_b + 0.001;
    shape_c = end_style->shape_c + line_width/2.0 + 0.001;

    frac_height = (line_width/2.0) / shape_c;
    dx = p1->x - p2->x;
    dy = p1->y - p2->y;
    length = hypot(dx, dy);
    if (length == 0) {
      sin_theta = cos_theta = 0.0;
    }
    else {
      sin_theta = dy/length;
      cos_theta = dx/length;
    }

    if (cap_style != CapProjecting) {
      temp = frac_height;
    }
    else {
      temp = line_width / shape_c;
    }
    backup = temp * shape_b + shape_a * (1.0 - temp) / 2.0;
    points[0].x = points[5].x = p1->x + backup * cos_theta;
    points[0].y = points[5].y = p1->y + backup * sin_theta;
    
    vert_x = points[0].x - shape_a*cos_theta;
    vert_y = points[0].y - shape_a*sin_theta;
    temp = shape_c*sin_theta;
    points[1].x = ZnNearestInt(points[0].x - shape_b*cos_theta + temp);
    points[4].x = ZnNearestInt(points[1].x - 2*temp);
    temp = shape_c*cos_theta;
    points[1].y = ZnNearestInt(points[0].y - shape_b*sin_theta - temp);
    points[4].y = ZnNearestInt(points[1].y + 2*temp);
    points[2].x = ZnNearestInt(points[1].x*frac_height + vert_x*(1.0-frac_height));
    points[2].y = ZnNearestInt(points[1].y*frac_height + vert_y*(1.0-frac_height));
    points[3].x = ZnNearestInt(points[4].x*frac_height + vert_x*(1.0-frac_height));
    points[3].y = ZnNearestInt(points[4].y*frac_height + vert_y*(1.0-frac_height));
  }
}

static ZnReal
SegmentPosInRelief(ZnReal               x1,
                     ZnReal             y1,
                     ZnReal             x2,
                     ZnReal             y2,
                     ZnReliefStyle      relief,
                     int                light_angle)
{
  ZnReal        angle, angle_step, origin, position;
  int           num_colors, color_index;
  
  num_colors = ZN_RELIEF_STEPS*2+1;
  angle_step = M_PI / (num_colors-1);
  origin = -(ZnDegRad(light_angle))-(angle_step/2.0);
  if (relief == ZN_RELIEF_SUNKEN) {
    origin += M_PI;
  }

  angle = ZnProjectionToAngle(y1 - y2, x2 - x1) + M_PI - origin;
  while (angle < 0.0) {
    angle += 2*M_PI;
  }
  while (angle > 2*M_PI) {
    angle -= 2*M_PI;
  }     

  color_index = (int) (angle/angle_step);
  if (color_index > num_colors-1) {
    color_index = 2*(num_colors-1)-color_index;
  }
  if ((color_index < 0) || (color_index >= num_colors)) {
    fprintf(stderr, "Color index out of gradient (should not happen).\n");
    if (color_index < 0) {
      color_index = 0;
    }
    if (color_index >= num_colors) {
      color_index = num_colors-1;
    }
  }
  position = 100*color_index/num_colors;
  /*printf("position %g, angle %g(%g), origin %g\n",
         position,
         RadianToDegrees(angle),
         angle,
         RadianToDegrees(origin));*/
  return position;
}

/*
 * ReliefColorOfSegment --
 * ReliefPixelOfSegment --
 */
static XColor *
ReliefColorOfSegment(ZnReal             x1,
                     ZnReal             y1,
                     ZnReal             x2,
                     ZnReal             y2,
                     ZnReliefStyle      relief,
                     ZnGradient         *gradient,
                     int                light_angle)
{
  return ZnGetGradientColor(gradient,
                            SegmentPosInRelief(x1, y1, x2, y2, relief, light_angle),
                            NULL);
}

static int
ReliefPixelOfSegment(ZnReal             x1,
                     ZnReal             y1,
                     ZnReal             x2,
                     ZnReal             y2,
                     ZnReliefStyle      relief,
                     ZnGradient         *gradient,
                     int                light_angle)
{
  return ZnGetGradientPixel(gradient,
                            SegmentPosInRelief(x1, y1, x2, y2, relief, light_angle));
}


/*
 **********************************************************************************
 *
 * ZnDrawRectangleRelief --
 *      Draw the bevels inside bbox.
 *
 **********************************************************************************
 */
void
ZnDrawRectangleRelief(ZnWInfo           *wi,
                      ZnReliefStyle     relief,
                      ZnGradient        *gradient,
                      XRectangle        *bbox,
                      ZnDim             line_width)
{
  XPoint        bevel[4];
  
  /*
   * If we haven't enough space to draw, exit.
   */
  if ((bbox->width < 2*line_width) || (bbox->height < 2*line_width)) {
    return;
  }
  
  /*
   * Grooves and ridges are drawn with two recursives calls with
   * half the width of the original one.
   */
  if ((relief == ZN_RELIEF_RIDGE) || (relief == ZN_RELIEF_GROOVE)) {
    ZnDim        new_line_width;
    unsigned int offset;
    XRectangle   internal_bbox;
    
    new_line_width = line_width/2.0;
    offset = (unsigned) (line_width - new_line_width);
    ZnDrawRectangleRelief(wi,
                          (ZnReliefStyle) ((relief==ZN_RELIEF_GROOVE)?ZN_RELIEF_SUNKEN:ZN_RELIEF_RAISED),
                          gradient, bbox, new_line_width);
    internal_bbox = *bbox;
    internal_bbox.x += offset;
    internal_bbox.y += offset;
    internal_bbox.width -= offset*2;
    internal_bbox.height -= offset*2;
    ZnDrawRectangleRelief(wi,
                          (ZnReliefStyle) ((relief==ZN_RELIEF_GROOVE)?ZN_RELIEF_RAISED:ZN_RELIEF_SUNKEN),
                          gradient, &internal_bbox, new_line_width);
    return;
  }

  XSetFillStyle(wi->dpy, wi->gc, FillSolid);
  
  bevel[0].x = bbox->x;
  bevel[0].y = bevel[1].y = bbox->y;
  bevel[1].x = bbox->x + bbox->width;
  bevel[2].y = bevel[3].y = bbox->y + (short) line_width;
  bevel[2].x = bevel[1].x - (short) line_width;
  bevel[3].x = bevel[0].x + (short) line_width;  
  XSetForeground(wi->dpy, wi->gc,
                 ReliefPixelOfSegment((ZnReal) bevel[1].x, (ZnReal) bevel[1].y,
                                      (ZnReal) bevel[0].x, (ZnReal) bevel[0].y,
                                      relief, gradient, wi->light_angle));
  XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, bevel, 4, Convex, CoordModeOrigin);

  bevel[0] = bevel[1];
  bevel[3] = bevel[2];
  bevel[1].y += bbox->height;
  bevel[2].y = bevel[1].y - (short) line_width;
  XSetForeground(wi->dpy, wi->gc,
                 ReliefPixelOfSegment((ZnReal) bevel[1].x, (ZnReal) bevel[1].y,
                                      (ZnReal) bevel[0].x, (ZnReal) bevel[0].y,
                                      relief, gradient, wi->light_angle));
  XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, bevel, 4, Convex, CoordModeOrigin);

  bevel[0] = bevel[1];
  bevel[3] = bevel[2];
  bevel[1].x -= bbox->width;
  bevel[2].x = bevel[1].x + (short) line_width;
  XSetForeground(wi->dpy, wi->gc,
                 ReliefPixelOfSegment((ZnReal) bevel[1].x, (ZnReal) bevel[1].y,
                                      (ZnReal) bevel[0].x, (ZnReal) bevel[0].y,
                                      relief, gradient, wi->light_angle));
  XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, bevel, 4, Convex, CoordModeOrigin);

  bevel[0] = bevel[1];
  bevel[3] = bevel[2];
  bevel[1].x = bbox->x;
  bevel[1].y = bbox->y;
  bevel[2].x = bevel[3].x;
  bevel[2].y = bbox->y + (short) line_width;
  XSetForeground(wi->dpy, wi->gc,
                 ReliefPixelOfSegment((ZnReal) bevel[1].x, (ZnReal) bevel[1].y,
                                      (ZnReal) bevel[0].x, (ZnReal) bevel[0].y,
                                      relief, gradient, wi->light_angle));
  XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, bevel, 4, Convex, CoordModeOrigin);
}


typedef struct {
  ZnWInfo       *wi;
  ZnPoint       *pp;
  ZnPoint       *p0;
  ZnPoint       *p1;
  double        dist;
  ZnBBox        *bbox;
  ZnReliefStyle relief;
  ZnGradient    *gradient;
  unsigned short alpha;
  ZnBool        smooth;
  int           result;
  int           count;
  ZnBool        toggle;
} PolygonData;

static void
DoPolygon(ZnPoint       *p,
          unsigned int  num_points,
          ZnDim         line_width,
          ZnBool        (*cb)(ZnPoint *bevels, PolygonData *pd),
          PolygonData   *pd)
{
  int           i;
  unsigned int  processed_points;
  ZnPoint       *p1, *p11=NULL, *p2;
  ZnPoint       pp1, pp2, new_pp1, new_pp2;
  ZnPoint       perp, c, shift1, shift2;
  ZnPoint       bevel_points[4];
  ZnBool        folded, closed, colinear;
  ZnReal        dx, dy;

  if (num_points < 2) {
    return;
  }

  /*
   * If the polygon is closed (last point is the same as first) open it by
   * dropping the last point. The algorithm closes the path automatically.
   * We remember this to decide if we draw the last bevel or not and if we
   * need to generate ends perpendicular to the path..
   */
  closed = False;
  if ((p->x == p[num_points-1].x) && (p->y == p[num_points-1].y)) {
    closed = True;
    num_points--;
  }
  /*printf("num_points=%d(%s)\n", num_points, closed?"closed":"");*/
  
  /*
   * We loop on all vertices of the polygon.
   * At each step we try to compute the corresponding border
   * corner `corner'. Then we build a polygon for the bevel.
   * Things look like this:
   *
   *          bevel[1]     /
   *             *        /
   *             |       /
   *             |      /
   *         pp1 *    * p[i-1]
   *             |    | bevel[0]
   *             |    |
   *             |    |
   *             |    | bevel[3]
   *             |    | p[i]
   *             |    | p1                 p2
   *         pp2 *    *--------------------*
   *             |
   *             |
   *      corner *----*--------------------*
   *     bevel[2]   new_pp1             new_pp2
   *
   * pp1 and pp2 are the ends of a segment // to p1 p2 at line_width
   * from it. These points are *NOT* necessarily on the perpendicular
   * going through p1 or p2.
   * This loop needs a bootstrap phase of two iterations (i.e we need to
   * process two points). This is why we start at the point before the last
   * and then wrap to the first point.
   * The algorithm discards any duplicate contiguous points.
   * It makes a special case if two consecutives edges are folded:
   *
   *  bevel[1]      pp1            pp2        a bevel[2]
   *    *-----------*--------------*----------*
   *                                           \
   *                                            \
   *     p[i-1]                                  \  bevel[3]
   *       *--------*-------------------------*---* corner
   *    bevel[0]    p2                       p1  /
   *                                            /
   *                                           /
   *      ----------*-----------*-------------*
   *             new_pp1     new_pp2          c
   *
   * In such a case we need to compute a, c, corner from pp1, pp2, new_pp1
   * and new_pp2. We compute the perpendicular to p1,p2 through p1, intersect
   * it with pp1,pp2 to obtain a, intersect it with new_pp1, new_pp2 to
   * obtain c, shift a,c and intersect it with p1,p2 to obtain corner.
   *
   */

  processed_points = 0;
  if (!closed) {
    i = 0;
    p1 = p;
  }
  else {
    i = -2;
    p1 = &p[num_points-2];
  }

  for (p2 = p1+1; i < (int) num_points; i++, p2++) {
    /*
     * When it is time to wrap, do it
     */
    if ((i == -1) || (i == (int) num_points-1)) {
      p2 = p;
    }
    /*
     * Skip over close vertices.
     */
    dx = p2->x - p1->x;
    dy = p2->y - p1->y;
    if ((ABS(dx) < 1.0) && (ABS(dy) < 1.0)) {
      continue;
    }

    ZnShiftLine(p1, p2, line_width, &new_pp1, &new_pp2);
    bevel_points[3] = *p1;
    folded = False;
    colinear = False;
    /*
     * The first two cases are for `open' polygons. We compute
     * a bevel closure that is perpendicular to the path.
     */
    if ((processed_points == 0) && !closed) {
      perp.x = p1->x + (p2->y - p1->y);
      perp.y = p1->y - (p2->x - p1->x);
      ZnIntersectLines(p1, &perp, &new_pp1, &new_pp2, &bevel_points[2]);
    }
    else if ((processed_points == num_points-1) && !closed) {
      perp.x = p1->x + (p11->y - p1->y);
      perp.y = p1->y - (p11->x - p1->x);
      ZnIntersectLines(p1, &perp, &pp1, &pp2, &bevel_points[2]);      
    }
    else if (processed_points >= 1) {
      ZnReal    dotp, dist, odx, ody;
      
      /*
       * The dot product of the two faces tell if the are
       * folded or colinear. The
       */
      odx = p11->x - p1->x;
      ody = p11->y - p1->y;
      dotp = odx*dx + ody*dy;
      dist = ZnLineToPointDist(p11, p2, p1, NULL);
      if ((dist < 4.0) && (dotp <= 0)) {
        perp.x = p1->x + (p2->y - p1->y);
        perp.y = p1->y - (p2->x - p1->x);
        ZnIntersectLines(p1, &perp, &new_pp1, &new_pp2, &bevel_points[2]);
        colinear = True;
      }
      else {
        folded = !ZnIntersectLines(&new_pp1, &new_pp2, &pp1, &pp2, &bevel_points[2]);
        /*printf("new_pp1 %g@%g, new_pp2 %g@%g, pp1 %g@%g, pp2 %g@%g, inter %g@%g\n",
               new_pp1.x, new_pp1.y, new_pp2.x, new_pp2.y,
               pp1.x, pp1.y, pp2.x, pp2.y,
               bevel_points[2].x, bevel_points[2].y);*/
        folded = folded && (dotp < 0);
        if (folded) {
          /*printf("DoPolygonRelief: folded edges detected, %g@%g, %g@%g, %g@%g, %g@%g\n",
                 pp1.x, pp1.y, pp2.x, pp2.y, new_pp1.x, new_pp1.y,
                 new_pp2.x, new_pp2.y);*/
          perp.x = p1->x + (p2->y - p1->y);
          perp.y = p1->y - (p2->x - p1->x);
          ZnIntersectLines(p1, &perp, &pp1, &pp2, &bevel_points[2]);
          ZnIntersectLines(p1, &perp, &new_pp1, &new_pp2, &c);
          ZnShiftLine(p1, &perp, line_width, &shift1, &shift2);
          ZnIntersectLines(p1, p2, &shift1, &shift2, &bevel_points[3]);
        }
      }
    }

    if ((processed_points >= 2) || (!closed && (processed_points == 1))) {
      if ((processed_points == num_points-1) && !closed) {
        pd->p0 = pd->p1 = NULL;
      }
      else {
        pd->p0 = p1;
        pd->p1 = p2;
      }
      if ((*cb)(bevel_points, pd)) {
        return;
      }
    }
    
    p11 = p1;
    p1 = p2;
    pp1 = new_pp1;
    pp2 = new_pp2;
    bevel_points[0] = bevel_points[3];
    if (folded) {
      bevel_points[1] = c;
    }
    else if ((processed_points >= 1) || !closed) {
      bevel_points[1] = bevel_points[2];
    }

    processed_points++;
  }
}


/*
 **********************************************************************************
 *
 * ZnGetPolygonReliefBBox --
 *      Returns the bevelled polygon bounding box.
 *
 **********************************************************************************
 */
static ZnBool
PolygonBBoxCB(ZnPoint           *bevels,
              PolygonData       *pd)
{
  int    i;

  for (i = 0; i < 4; i++) {
    ZnAddPointToBBox(pd->bbox, bevels[i].x, bevels[i].y);
  }
  return 0;
}

void
ZnGetPolygonReliefBBox(ZnPoint          *points,
                       unsigned int     num_points,
                       ZnDim            line_width,
                       ZnBBox           *bbox)
{
  PolygonData   pd;

  pd.bbox = bbox;
  ZnResetBBox(bbox);
  DoPolygon(points, num_points, line_width, PolygonBBoxCB, &pd);
}


/*
 **********************************************************************************
 *
 * ZnPolygonReliefInBBox --
 *      Returns (-1) if the relief is entirely outside the bbox, (1) if it is
 *      entirely inside or (0) if in between
 *
 **********************************************************************************
 */
static ZnBool
PolygonInBBoxCB(ZnPoint         *bevels,
                PolygonData     *pd)
{
  if (pd->count == 0) {
    pd->count++;
    pd->result = ZnPolygonInBBox(bevels, 4, pd->bbox, NULL);
    if (pd->result == 0) {
      return 1;
    }
  }
  else {
    if (ZnPolygonInBBox(bevels, 4, pd->bbox, NULL) != pd->result) {
      pd->result = 0;
      return 1;
    }
  }
  return 0;
}

int
ZnPolygonReliefInBBox(ZnPoint           *points,
                      unsigned int      num_points,
                      ZnDim             line_width,
                      ZnBBox            *area)
{
  PolygonData   pd;

  pd.bbox = area;
  pd.count = 0;

  DoPolygon(points, num_points, line_width, PolygonInBBoxCB, &pd);

  return pd.result;
}


/*
 **********************************************************************************
 *
 * ZnPolygonReliefToPointDist --
 *      Returns the distance between the given point and
 *      the bevelled polygon.
 *
 **********************************************************************************
 */
static ZnBool
PolygonDistCB(ZnPoint           *bevels,
              PolygonData       *pd)
{
  double        new_dist;

  new_dist = ZnPolygonToPointDist(bevels, 4, pd->pp);
  if (new_dist < 0.0) {
    new_dist = 0.0;
  }
  if (new_dist < pd->dist) {
    pd->dist = new_dist;
  }
  return 0;
}

double
ZnPolygonReliefToPointDist(ZnPoint      *points,
                           unsigned int num_points,
                           ZnDim        line_width,
                           ZnPoint      *pp)
{
  PolygonData   pd;

  pd.dist = 1.0e40;
  pd.pp = pp;
  DoPolygon(points, num_points, line_width, PolygonDistCB, &pd);

  return pd.dist;
}


/*
 **********************************************************************************
 *
 * ZnDrawPolygonRelief --
 *      Draw the bevels around path.
 *
 **********************************************************************************
 */
static ZnBool
PolygonDrawCB(ZnPoint           *bevels,
              PolygonData       *pd)
{
  ZnWInfo       *wi = pd->wi;
  XPoint        bevel_xpoints[5];
  XGCValues     values;
  int           j;

  values.foreground = ReliefPixelOfSegment(bevels[0].x, bevels[0].y,
                                           bevels[3].x, bevels[3].y,
                                           pd->relief, pd->gradient,
                                           pd->wi->light_angle);

  values.fill_style = FillSolid;
  XChangeGC(wi->dpy, wi->gc, GCFillStyle|GCForeground, &values);
        
  for (j = 0; j < 4; j++) {
    bevel_xpoints[j].x = ZnNearestInt(bevels[j].x);
    bevel_xpoints[j].y = ZnNearestInt(bevels[j].y);
  }

  XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, bevel_xpoints, 4,
               Convex, CoordModeOrigin);

  return 0;
}

void
ZnDrawPolygonRelief(ZnWInfo             *wi,
                    ZnReliefStyle       relief,
                    ZnGradient          *gradient,
                    ZnPoint             *points,
                    unsigned int        num_points,
                    ZnDim               line_width)
{
  PolygonData   pd;

  pd.wi = wi;
  pd.gradient = gradient;

  /*
   * Grooves and ridges are drawn with two calls. The first
   * with the original width, the second with half the width.
   */
  if ((relief == ZN_RELIEF_RIDGE) || (relief == ZN_RELIEF_GROOVE)) {
    pd.relief = (relief==ZN_RELIEF_GROOVE)?ZN_RELIEF_RAISED:ZN_RELIEF_SUNKEN;
    DoPolygon(points, num_points, line_width, PolygonDrawCB, &pd);
    pd.relief = (relief==ZN_RELIEF_GROOVE)?ZN_RELIEF_SUNKEN:ZN_RELIEF_RAISED;
    DoPolygon(points, num_points, line_width/2, PolygonDrawCB, &pd);
  }
  else {
    pd.relief = relief;
    DoPolygon(points, num_points, line_width, PolygonDrawCB, &pd);
  }
}

/*
 **********************************************************************************
 *
 * ZnRenderPolygonRelief --
 *      Draw the bevels around path using alpha enabled rendering.
 *
 **********************************************************************************
 */
#ifdef GL
static ZnBool
PolygonRenderCB(ZnPoint         *bevels,
                PolygonData     *pd)
{
  int           i;
  ZnPoint       p[6];
  XColor        *c[8];
  XColor        *color = ZnGetGradientColor(pd->gradient, 51.0, NULL);
  ZnReliefStyle relief, int_relief;
  ZnBool        two_faces, round, rule;

  rule = pd->relief & ZN_RELIEF_RULE;
  round = pd->relief & ZN_RELIEF_ROUND;
  two_faces = pd->relief & ZN_RELIEF_TWO_FACES;
  relief = pd->relief & ZN_RELIEF_MASK;
  for (i = 0; i < 4; i++) {
    p[i].x = ZnNearestInt(bevels[i].x);
    p[i].y = ZnNearestInt(bevels[i].y);
  }

  if (two_faces) {
    p[4].x = (p[0].x+p[1].x)/2;
    p[4].y = (p[0].y+p[1].y)/2;
    p[5].x = (p[2].x+p[3].x)/2;
    p[5].y = (p[2].y+p[3].y)/2;

    if (relief == ZN_RELIEF_SUNKEN) {
      int_relief = ZN_RELIEF_RAISED;
    }
    else {
      int_relief = ZN_RELIEF_SUNKEN;
    }
    c[0]=c[1]=c[2]=c[3] = ReliefColorOfSegment(bevels[0].x, bevels[0].y,
                                               bevels[3].x, bevels[3].y,
                                               relief, pd->gradient,
                                               pd->wi->light_angle);
    c[4]=c[5]=c[6]=c[7] = ReliefColorOfSegment(bevels[0].x, bevels[0].y,
                                               bevels[3].x, bevels[3].y,
                                               int_relief, pd->gradient,
                                               pd->wi->light_angle);
    if (pd->smooth && pd->p0) {
      c[2]=c[3] = ReliefColorOfSegment(pd->p0->x, pd->p0->y,
                                       pd->p1->x, pd->p1->y,
                                       relief, pd->gradient,
                                       pd->wi->light_angle);
      c[6]=c[7] = ReliefColorOfSegment(pd->p0->x, pd->p0->y,
                                       pd->p1->x, pd->p1->y,
                                       int_relief, pd->gradient,
                                       pd->wi->light_angle);
    }
    if (round) {
      if (!rule) {
        c[0]=c[3]=c[5]=c[6]=color;
      }
      else {
        c[1]=c[2]=c[4]=c[7]=color;
      }
    }
    glBegin(GL_QUADS);
    glColor4us(c[0]->red, c[0]->green, c[0]->blue, pd->alpha);
    glVertex2d(p[0].x, p[0].y);

    glColor4us(c[1]->red, c[1]->green, c[1]->blue, pd->alpha);
    glVertex2d(p[4].x, p[4].y);

    glColor4us(c[2]->red, c[2]->green, c[2]->blue, pd->alpha);
    glVertex2d(p[5].x, p[5].y);

    glColor4us(c[3]->red, c[3]->green, c[3]->blue, pd->alpha);
    glVertex2d(p[3].x, p[3].y);

    glColor4us(c[4]->red, c[4]->green, c[4]->blue, pd->alpha);
    glVertex2d(p[4].x, p[4].y);

    glColor4us(c[5]->red, c[5]->green, c[5]->blue, pd->alpha);
    glVertex2d(p[1].x, p[1].y);

    glColor4us(c[6]->red, c[6]->green, c[6]->blue, pd->alpha);
    glVertex2d(p[2].x, p[2].y);

    glColor4us(c[7]->red, c[7]->green, c[7]->blue, pd->alpha);
    glVertex2d(p[5].x, p[5].y);
    glEnd();
  }
  else { /* Single face */
    c[0]=c[1]=c[2]=c[3] = ReliefColorOfSegment(bevels[0].x, bevels[0].y,
                                               bevels[3].x, bevels[3].y,
                                               relief, pd->gradient,
                                               pd->wi->light_angle);
    if (pd->smooth && pd->p0) {
      c[2]=c[3] = ReliefColorOfSegment(pd->p0->x, pd->p0->y,
                                       pd->p1->x, pd->p1->y,
                                       relief, pd->gradient,
                                       pd->wi->light_angle);
    }
    if (round) {
      c[1]=c[2] = color;
    }
    glBegin(GL_QUADS);
    glColor4us(c[0]->red, c[0]->green, c[0]->blue, pd->alpha);
    glVertex2d(p[0].x, p[0].y);
    glColor4us(c[1]->red, c[1]->green, c[1]->blue, pd->alpha);
    glVertex2d(p[1].x, p[1].y);
    glColor4us(c[2]->red, c[2]->green, c[2]->blue, pd->alpha);
    glVertex2d(p[2].x, p[2].y);
    glColor4us(c[3]->red, c[3]->green, c[3]->blue, pd->alpha);
    glVertex2d(p[3].x, p[3].y);
    glEnd();
  }

  return 0;
}

void
ZnRenderPolygonRelief(ZnWInfo           *wi,
                      ZnReliefStyle     relief,
                      ZnGradient        *gradient,
                      ZnBool            smooth,
                      ZnPoint           *points,
                      unsigned int      num_points,
                      ZnDim             line_width)
{
  PolygonData   pd;

  pd.wi = wi;
  pd.gradient = gradient;
  ZnGetGradientColor(gradient, 0.0, &pd.alpha);
  pd.alpha = ZnComposeAlpha(pd.alpha, wi->alpha);
  pd.smooth = smooth;
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);      
  pd.relief = relief;
  pd.count = 0;

  DoPolygon(points, num_points, line_width, PolygonRenderCB, &pd);
}

void
ZnRenderPolyline(ZnWInfo        *wi,
                 ZnPoint        *points,
                 unsigned int   num_points,
                 ZnDim          line_width,
                 ZnLineStyle    line_style,
                 int            cap_style,
                 int            join_style,
                 ZnLineEnd      first_end,
                 ZnLineEnd      last_end,
                 ZnGradient     *gradient)
{
  int           num_clips = ZnListSize(wi->clip_stack);
  ZnPoint       end_points[ZN_LINE_END_POINTS];
  ZnBool        need_rcaps, thin, closed, transparent;
  int           pass, num_passes, i, k, m;
  ZnPoint       c1, c2;    
  XColor        *color;
  unsigned short alpha;
  ZnGLContextEntry *ce = ZnGetGLContext(wi->dpy);

  /*
   * The code below draws curves thiner than the min
   * of GL_SMOOTH_LINE_WIDTH_RANGE and GL_SMOOTH_POINT_SIZE_RANGE
   * with a mix of anti-aliased lines and points. The curves that
   * are thicker are drawn using regular polygons.
   * TODO: The joints are drawn only rounded.
   * The caps can be either round or butt (but not projecting).
   */
  thin = ((line_width <= ce->max_line_width) &&
          (line_width <= ce->max_point_width));
  closed = (points->x == points[num_points-1].x) && (points->y == points[num_points-1].y);
  color = ZnGetGradientColor(gradient, 0.0, &alpha);
  alpha = ZnComposeAlpha(alpha, wi->alpha);
  glColor4us(color->red, color->green, color->blue, alpha);
  ZnSetLineStyle(wi, line_style);
  glLineWidth((GLfloat) line_width);
  /*
   * Do not use AA under this transparency value.
   */
  transparent = alpha < (65535 * 0.8);
  if (thin && transparent) {
    /*
     * This makes a special case for transparent lines.
     * In this case we need to avoid drawing twice a
     * single pixel. To achieve this we use the stencil
     * buffer to protect already drawn pixels, unfortunately
     * using antialiasing write in the stencil even if
     * the pixel area is not fully covered resulting in
     * a crack that can't be covered by points later on.
     * To handle this case we need to disable the stencil
     * which in turn result in erroneous alpha coverage.
     *
     * We have chosen to drawn transparent lines with a
     * correct coverage but NOT antialiased.
     */
    glPointSize((GLfloat)(line_width>1.0?line_width-1:line_width));
    glDisable(GL_LINE_SMOOTH);
  }
  else {
    glPointSize((GLfloat)(line_width>1.0?line_width-1:line_width));
  }

  num_passes = 1;
  if (transparent) {
    num_passes = 2;
  }
    
  for (pass = 0; pass < num_passes; pass++) {
    if (transparent) {
      if (pass == 0) {
        ZnGlStartClip(num_clips, True);
      }
      else {
        ZnGlRestoreStencil(num_clips, False);
      }
    }
    if (first_end) {
      ZnGetLineEnd(&points[0], &points[1], line_width, cap_style,
                   first_end, end_points);
      glBegin(GL_TRIANGLE_FAN);
      for (m = 0; m < ZN_LINE_END_POINTS; m++) {
        glVertex2d(end_points[m].x, end_points[m].y);
      }
      glEnd();
    }
    if (last_end) {
      ZnGetLineEnd(&points[num_points-1], &points[num_points-2],
                   line_width, cap_style, last_end, end_points);
      glBegin(GL_TRIANGLE_FAN);
      for (m = 0; m < ZN_LINE_END_POINTS; m++) {
        glVertex2d(end_points[m].x, end_points[m].y);
      }
      glEnd();
    }
    if (thin) {
      glBegin(GL_LINE_STRIP);
      for (i = 0; i < (int) num_points; i++) {
        glVertex2d(points[i].x, points[i].y);
      }
      glEnd();
    }
    else {
      glBegin(GL_QUADS);
      for (i = 0; i < (int) num_points-1; i++) {
        ZnGetButtPoints(&points[i+1], &points[i], line_width, False, &c1, &c2);
        glVertex2d(c1.x, c1.y);
        glVertex2d(c2.x, c2.y);
        ZnGetButtPoints(&points[i], &points[i+1], line_width, False, &c1, &c2);
        glVertex2d(c1.x, c1.y);
        glVertex2d(c2.x, c2.y);
      }
      glEnd();
    }

    /* if (pass == 0) {
      ZnGlRenderClipped();
    }
    else {
      ZnGlEndClip(num_clips);
      break;
    }*/
    need_rcaps = ((line_width > 1) && (cap_style == CapRound));
    i = 0;
    k = num_points;
    if (closed) {
      k--;
    }
    if (!need_rcaps || first_end) {
      i++;
    }
    if ((!need_rcaps && !closed) || last_end) {
      k--;
    }

    if (thin) {
      glBegin(GL_POINTS);
      for ( ; i < k; i++) {
        glVertex2d(points[i].x, points[i].y);
      }
      glEnd();
    }
    else {
      int       num_cpoints;
      ZnReal    lw_2 = line_width / 2.0;
      ZnPoint   *cpoints = ZnGetCirclePoints(3, ZN_CIRCLE_COARSE,
                                             0.0, 2*M_PI, &num_cpoints, NULL);
      
      for ( ; i < k; i++) {
        glBegin(GL_TRIANGLE_FAN);
        glVertex2d(points[i].x, points[i].y);
        for (m = 0; m < num_cpoints; m++) {
          glVertex2d(points[i].x + cpoints[m].x*lw_2,
                     points[i].y + cpoints[m].y*lw_2);
        }
        glEnd();
      }
    }
  }
  
  ZnGlEndClip(num_clips);
  if (thin) {
    glEnable(GL_LINE_SMOOTH);
  }
}


void
ZnRenderIcon(ZnWInfo    *wi,
             ZnImage    image,
             ZnGradient *gradient,
             ZnPoint    *origin,
             ZnBool     modulate)
{
  ZnPoint       p[4];
  int           width, height;

  ZnSizeOfImage(image, &width, &height);
  p[0] = *origin;
  p[1].x = origin->x;
  p[1].y = origin->y + height;
  p[2].x = origin->x + width;
  p[2].y = p[1].y;
  p[3].x = p[2].x;
  p[3].y = origin->y;
  ZnRenderImage(wi, image, gradient, p, modulate);
}


void
ZnRenderImage(ZnWInfo    *wi,
              ZnImage    image,
              ZnGradient *gradient,
              ZnPoint    *quad,
              ZnBool     modulate)
{
  XColor        *color;
  unsigned short alpha;
  ZnReal        t, s;
  GLuint        texobj;
  
  color = ZnGetGradientColor(gradient, 0.0, &alpha);
  alpha = ZnComposeAlpha(alpha, wi->alpha);
  texobj = ZnImageTex(image, &t, &s);
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, texobj);
  if (modulate) {
    glColor4us(color->red, color->green, color->blue, alpha);
  }
  else {
    glColor4us(65535, 65535, 65535, alpha);
  }
  glBegin(GL_QUADS);
  glTexCoord2d(0.0, 0.0);
  glVertex2d(quad[0].x, quad[0].y);
  glTexCoord2d(0.0, t);
  glVertex2d(quad[1].x, quad[1].y);
  glTexCoord2d(s, t);
  glVertex2d(quad[2].x, quad[2].y);
  glTexCoord2d(s, 0.0);
  glVertex2d(quad[3].x, quad[3].y);
  glEnd();
  glDisable(GL_TEXTURE_2D);
}

void
ZnRenderTile(ZnWInfo    *wi,
             ZnImage    tile,
             ZnGradient *gradient,
             void       (*cb)(void *),
             void       *closure,
             ZnPoint    *quad) /* Right now it's a ZnBBox */
{
  ZnReal        x, y, nx, ny, lx, ly, s, t, tiles, tilet;
  int           width, height, num_clips = ZnListSize(wi->clip_stack);
  unsigned short alpha;
  GLuint        texobj;
  XColor        *color;

  if (gradient) {
    color = ZnGetGradientColor(gradient, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
  }
  else {
    color = NULL;
    alpha = ZnComposeAlpha(100, wi->alpha);
  }
  
  if (cb) {
    /*
     * Setup the stencil buffer with the shape to be drawn.
     */
    ZnGlStartClip(num_clips, False);

    (*cb)(closure);  
    ZnGlRestoreStencil(num_clips, True);
  }
  
  /*
   * Then texture map the quad through the shape.
   * The rectangle is drawn using quads, each
   * quad matching the size of the texture tile.
   */
  ZnSizeOfImage(tile, &width, &height);
  texobj = ZnImageTex(tile, &tilet, &tiles);
  glEnable(GL_TEXTURE_2D);
  if (color && ZnImageIsBitmap(tile)) {
    glColor4us(color->red, color->green, color->blue, alpha);
  }
  else {
    glColor4us(65535, 65535, 65535, alpha);
  }
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glBindTexture(GL_TEXTURE_2D, texobj);
  
  y = quad[0].y;
  lx = quad[1].x;
  ly = quad[1].y;
  glBegin(GL_QUADS);
  do {
    x = quad[0].x;
    t = 1.0;
    ny = y + height;
    if (ny > ly) {
      ny = ly;
      t = (ly - y) / (ZnReal) height;
    }
    t *= tilet;
    do {
      s = 1.0;
      nx = x + width;
      if (nx > lx) {
        nx = lx;
        s = (lx - x) / (ZnReal) width;
      }
      s *= tiles;
      glTexCoord2d(0.0, 0.0);
      glVertex2d(x, y);
      glTexCoord2d(0.0, t);
      glVertex2d(x, ny);
      glTexCoord2d(s, t);
      glVertex2d(nx, ny);
      glTexCoord2d(s, 0.0);
      glVertex2d(nx, y);
      x = nx;
    }
    while (x != lx);
    y = ny;
  }
  while (y != ly);
  glEnd();

  if (cb) {
    ZnGlEndClip(num_clips);
  }
  glDisable(GL_TEXTURE_2D);
}


static void
ComputeAxialGradient(ZnWInfo    *wi,
                     ZnPoly     *shape,
                     ZnReal     angle,
                     ZnPoint    *grad_geo)
{
  ZnTransfo     *transfo1, *transfo2;
  ZnContour     *c;
  ZnBBox        bbox;
  ZnPoint       *points, p[4];
  unsigned int  i;
  
  transfo1 = ZnTransfoNew();
  transfo2 = ZnTransfoNew();
  ZnRotateDeg(transfo1, angle);
  ZnRotateDeg(transfo2, -angle);
  c = shape->contours;
  ZnResetBBox(&bbox);
  for (i = 0; i < shape->num_contours; i++, c++) {
    ZnListAssertSize(ZnWorkPoints, c->num_points);
    points = ZnListArray(ZnWorkPoints);
    ZnTransformPoints(transfo1, c->points, points, c->num_points);
    ZnAddPointsToBBox(&bbox, points, c->num_points);
  }
  bbox.orig.x--;
  bbox.orig.y--;
  bbox.corner.x++;
  bbox.corner.y++;
  p[0] = bbox.orig;
  p[2] = bbox.corner;
  p[1].x = p[2].x;
  p[1].y = p[0].y;
  p[3].x = p[0].x;
  p[3].y = p[2].y;
  ZnTransfoSetIdentity(transfo1);
  ZnTransfoCompose(transfo1, transfo2, wi->current_transfo);
  ZnTransformPoints(transfo1, p, grad_geo, 4);
  ZnTransfoFree(transfo1);
  ZnTransfoFree(transfo2);
}

static void
ComputeCircularGradient(ZnWInfo         *wi,
                        ZnPoly          *shape,
                        ZnBool          oval,
                        ZnPoint         *focal_pp, /* in percent of bbox */
                        ZnReal          angle,
                        ZnPoint         *grad_geo)
{
  ZnReal        dist, new, x, y, ff;
  ZnBBox        bbox;
  ZnContour     *c;
  ZnPoint       offset, radius, focal_point;
  ZnPoint       *points;
  ZnTransfo     t1;
  unsigned int  i, j;

  /*
   * Compute the shape bbox (which should be in the item space).
   */
  ZnResetBBox(&bbox);
  c = shape->contours;
  dist = 0.0;
  for (j = 0; j < shape->num_contours; j++, c++) {
    ZnAddPointsToBBox(&bbox, c->points, c->num_points); 
  }

  /*
   * Find the gradient focal point in the item space.
   * The excursion of the focal point outside the item
   * bbox is clamped to avoid distorsions that take
   * place due to the rather simple algorithm used to
   * compute the maximum radius of the gradient.
   */
  focal_pp->x = fmod(focal_pp->x, 500.0);
  focal_pp->y = fmod(focal_pp->y, 500.0);
  offset.x = focal_pp->x * (bbox.corner.x-bbox.orig.x)/100.0;
  offset.y = focal_pp->y * (bbox.corner.y-bbox.orig.y)/100.0;
  focal_point.x = (bbox.corner.x+bbox.orig.x)/2 + offset.x; 
  focal_point.y = (bbox.corner.y+bbox.orig.y)/2 + offset.y; 

  /*
   * Find the max distance from the focal point.
   */
  if (oval) {
    /*
     * radius.x and radius.y are the shape radiuses.
     * ff is the distance from the bbox center to
     * the focal point.
     */
    radius.x = (bbox.corner.x-bbox.orig.x)/2;
    radius.y = (bbox.corner.y-bbox.orig.y)/2;
    ff = sqrt(offset.x*offset.x + offset.y*offset.y);
    /*
     * Compute the farthest point from the focal point 
     * on a unit circle, then map it to the oval and
     * compute the distance between the two points.
     */
    if (ff > PRECISION_LIMIT) {
      x = offset.x/ff;
      y = offset.y/ff;
      x *= radius.x;
      y *= radius.y;
      x = x + offset.x;
      y = y + offset.y;
    }
    else {
      x = 0;
      y = MAX(radius.x, radius.y);
    }
    dist = x*x + y*y;
  }
  else {
    /*
     * Use the given shape
     */
    c = shape->contours;
    for (j = 0; j < shape->num_contours; j++, c++) {
      for (i = 0, points = c->points; i < c->num_points; i++, points++) {
        x = points->x - focal_point.x;
        y = points->y - focal_point.y;
        new = x*x+y*y;
        if (new > dist) {
          dist = new;
        }
      }
    }
  }
  
  /*
   * Create a transform to map a unit circle to another one that
   * could fill the item when centered at the focal point.
   */
  dist = sqrt(dist); /* Max radius plus a fuzz factor */
  ZnTransfoSetIdentity(&t1);
  ZnScale(&t1, dist, dist);
  ZnRotateDeg(&t1, -angle);

  /*
   * Then, center the oval on the focal point.
   */
  ZnTranslate(&t1, focal_point.x, focal_point.y, False);
  /*
   * Last, compose with the current transform.
   */
  ZnTransfoCompose((ZnTransfo *) grad_geo, &t1, wi->current_transfo);
}

static void
ComputePathGradient(ZnWInfo     *wi,
                    ZnPoly      *shape,
                    ZnPoint     *focal_pp, /* in percent of the bbox */
                    ZnPoint     *grad_geo)
{
  ZnBBox        bbox;
  ZnContour     *c;
  ZnPoint       focal_point;
  unsigned int  j;

  /*
   * Compute the shape bbox (which should be in the item space).
   */
  ZnResetBBox(&bbox);
  c = shape->contours;
  for (j = 0; j < shape->num_contours; j++, c++) {
    ZnAddPointsToBBox(&bbox, c->points, c->num_points); 
  }

  /*
   * Find the gradient center in the item space.
   */
  focal_point.x = (bbox.corner.x+bbox.orig.x)/2 + focal_pp->x * (bbox.corner.x-bbox.orig.x)/100.0;
  focal_point.y = (bbox.corner.y+bbox.orig.y)/2 + focal_pp->y * (bbox.corner.y-bbox.orig.y)/100.0;
  /*
   * Then convert it to device space.
   */
  ZnTransformPoint(wi->current_transfo, &focal_point, &grad_geo[0]);
}

void
ZnComputeGradient(ZnGradient    *grad,
                  ZnWInfo       *wi,
                  ZnPoly        *shape,
                  ZnPoint       *grad_geo)
{
  switch (grad->type) {
  case ZN_AXIAL_GRADIENT:
    ComputeAxialGradient(wi, shape, grad->angle, grad_geo);
    break;
  case ZN_RADIAL_GRADIENT:
  case ZN_CONICAL_GRADIENT:
    ComputeCircularGradient(wi, shape, False, &grad->p, grad->angle, grad_geo);
    break;
  case ZN_PATH_GRADIENT:
    ComputePathGradient(wi, shape, &grad->p, grad_geo);
    break;
  }
}

void
ZnRenderGradient(ZnWInfo        *wi,
                 ZnGradient     *gradient,      /* The gradient to be drawn (static
                                                 * parameters). */
                 void           (*cb)(void *),  /* A callback called to clip the shape
                                                 * containing the gradient. */
                 void           *closure,       /* The callback parameter. */
                 ZnPoint        *quad,          /* The gradient geometric parameters
                                                 * (dynamic). */
                 ZnPoly         *poly           /* Used only by ZN_PATH_GRADIENT */
                 )
{
  unsigned short alpha, alpha2;
  int           angle;
  unsigned int  i, j;
  int           type = gradient->type;
  XColor        *color;
  ZnPoint       dposa, dposb, dposc, dposd;
  ZnPoint       p, dcontrol;
  ZnReal        npos, pos, control;
  unsigned int  num_clips = ZnListSize(wi->clip_stack);
  ZnPoint       iquad[4];
  
  if (!cb && (type == ZN_AXIAL_GRADIENT)) { /* Render an aligned
                                             * axial gradient in the quad */
    angle = gradient->angle;
    /*
     * Adjust the quad for 90 180 and 270 degrees axial
     * gradients. Other angles not supported.
     */
    switch (angle) {
    case 90:
      iquad[0] = quad[3];
      iquad[3] = quad[2];
      iquad[2] = quad[1];
      iquad[1] = quad[0];
      quad = iquad;
      break;
    case 180:
      iquad[0] = quad[2];
      iquad[3] = quad[1];
      iquad[2] = quad[0];
      iquad[1] = quad[3];
      quad = iquad;
      break;
    case 270:
      iquad[0] = quad[1];
      iquad[3] = quad[0];
      iquad[2] = quad[3];
      iquad[1] = quad[2];      
      quad = iquad;
      break;
    }
  }

  if (cb) {
    /*
     * Draw the gradient shape in the stencil using the provided
     * callback (clipping).
     */
    ZnGlStartClip(num_clips, False);
    (*cb)(closure);
    ZnGlRestoreStencil(num_clips, True);
  }

  if (type == ZN_AXIAL_GRADIENT) {
    /*
     * Then fill the axial gradient using the provided
     * quad and colors. The stencil will be restored
     * to its previous state in the process.
     */
    glBegin(GL_QUAD_STRIP);
    for (i = 0; i < gradient->num_actual_colors; i++) {
      color = gradient->actual_colors[i].rgb;
      alpha = ZnComposeAlpha(gradient->actual_colors[i].alpha, wi->alpha);
      glColor4us(color->red, color->green, color->blue, alpha);

      pos = gradient->actual_colors[i].position;
      control = gradient->actual_colors[i].control;
      dposa.x = (quad[1].x - quad[0].x)*pos/100.0;
      dposa.y = (quad[1].y - quad[0].y)*pos/100.0;
      p.x = quad[0].x + dposa.x;
      p.y = quad[0].y + dposa.y;
      glVertex2d(p.x, p.y);
      
      dposb.x = (quad[2].x - quad[3].x)*pos/100.0;
      dposb.y = (quad[2].y - quad[3].y)*pos/100.0;      
      p.x = quad[3].x + dposb.x;
      p.y = quad[3].y + dposb.y;
      glVertex2d(p.x, p.y);
      
      if ((control != 50.0) && (i != gradient->num_actual_colors-1)) {
        color = gradient->actual_colors[i].mid_rgb;
        alpha = ZnComposeAlpha(gradient->actual_colors[i].mid_alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        
        npos = gradient->actual_colors[i+1].position;
        dposc.x = (quad[1].x - quad[0].x)*npos/100.0;
        dposc.y = (quad[1].y - quad[0].y)*npos/100.0;
        dcontrol.x = (dposc.x - dposa.x)*control/100.0;
        dcontrol.y = (dposc.y - dposa.y)*control/100.0;
        p.x = quad[0].x + dposa.x + dcontrol.x;
        p.y = quad[0].y + dposa.y + dcontrol.y;
        glVertex2d(p.x, p.y);
        
        dposd.x = (quad[2].x - quad[3].x)*npos/100.0;
        dposd.y = (quad[2].y - quad[3].y)*npos/100.0;
        dcontrol.x = (dposd.x - dposb.x)*control/100.0;
        dcontrol.y = (dposd.y - dposb.y)*control/100.0;      
        p.x = quad[3].x + dposb.x + dcontrol.x;
        p.y = quad[3].y + dposb.y + dcontrol.y;
        glVertex2d(p.x, p.y);
      }
      
    }
    glEnd();
  }
  else if (type == ZN_RADIAL_GRADIENT) {
    ZnReal       x, y, position, position2, position3;
    unsigned int num_p;
    ZnPoint      *genarc, *tarc, p, focalp;
    XColor       *color2;

    genarc = ZnGetCirclePoints(3, ZN_CIRCLE_FINE, 0.0, 2*M_PI, &num_p, NULL);
    ZnListAssertSize(ZnWorkPoints, num_p);
    tarc = ZnListArray(ZnWorkPoints);
    ZnTransformPoints((ZnTransfo *) quad, genarc, tarc, num_p);
    p.x = p.y = 0;
    ZnTransformPoint((ZnTransfo *) quad, &p, &focalp);
    
    position = 0.0;
    color = gradient->actual_colors[0].rgb;
    alpha = ZnComposeAlpha(gradient->actual_colors[0].alpha, wi->alpha);
    control = gradient->actual_colors[0].control;
    for (j = 1; j < gradient->num_actual_colors; j++) {
      position2 = gradient->actual_colors[j].position/100.0;
      if ((control != 50) && (j != gradient->num_actual_colors-1)) {
        glBegin(GL_QUAD_STRIP);
        color2 = gradient->actual_colors[j-1].mid_rgb;
        alpha2 = ZnComposeAlpha(gradient->actual_colors[j-1].mid_alpha, wi->alpha);
        position3 = position + (position2-position)*control/100.0;
        for (i = 0; i < num_p; i++) {
          x = focalp.x + (tarc[i].x-focalp.x) * position;
          y = focalp.y + (tarc[i].y-focalp.y) * position;
          glColor4us(color->red, color->green, color->blue, alpha);
          glVertex2d(x, y);
          x = focalp.x + (tarc[i].x-focalp.x) * position3;
          y = focalp.y + (tarc[i].y-focalp.y) * position3;
          glColor4us(color2->red, color2->green, color2->blue, alpha);
          glVertex2d(x, y);
        }
        position = position3;
        color = color2;
        alpha = alpha2;
        glEnd();
      }
      glBegin(GL_QUAD_STRIP);
      color2 = gradient->actual_colors[j].rgb;
      alpha2 = ZnComposeAlpha(gradient->actual_colors[j].alpha, wi->alpha);
      for (i = 0; i < num_p; i++) {
        x = focalp.x + (tarc[i].x-focalp.x) * position;
        y = focalp.y + (tarc[i].y-focalp.y) * position;
        glColor4us(color->red, color->green, color->blue, alpha);
        glVertex2d(x, y);
        x = focalp.x + (tarc[i].x-focalp.x) * position2;
        y = focalp.y + (tarc[i].y-focalp.y) * position2;
        glColor4us(color2->red, color2->green, color2->blue, alpha2);
        glVertex2d(x, y);
      }
      glEnd();
      position = position2;
      color = color2;
      alpha = alpha2;
      control = gradient->actual_colors[j].control;
    }
  }
  else if (type == ZN_PATH_GRADIENT) {
    ZnPoint      p, pp, p2, pp2, p3, pp3;
    unsigned int num_p, k, ii;
    ZnPoint      *points;
    ZnReal       position;
    
    for (k = 0; k < poly->num_contours; k++) {
      /*if (poly->contours[k].cw) {
        continue;
        }*/
      points = poly->contours[k].points;
      num_p = poly->contours[k].num_points;
      
      for (i = 0; i < num_p; i++) {
        if (i == num_p-1) {
          ii = 0;
        }
        else {
          ii = i+1;
        }
        
        glBegin(GL_QUAD_STRIP);
        p.x = p.y = pp.x = pp.y = 0;
        control = gradient->actual_colors[0].control;
        position = gradient->actual_colors[0].position;
        alpha = ZnComposeAlpha(gradient->actual_colors[0].alpha, wi->alpha);
        color = gradient->actual_colors[0].rgb;
        glColor4us(color->red, color->green, color->blue, alpha);
        glVertex2d(quad[0].x+p.x, quad[0].y+p.y);
        glVertex2d(quad[0].x+pp.x, quad[0].y+pp.y);
        for (j = 0; j < gradient->num_actual_colors-1; j++) {
          position = gradient->actual_colors[j+1].position;
          p2.x = (points[i].x-quad[0].x)*position/100.0;
          p2.y = (points[i].y-quad[0].y)*position/100.0;
          pp2.x = (points[ii].x-quad[0].x)*position/100.0;
          pp2.y = (points[ii].y-quad[0].y)*position/100.0;
          if (control != 50) {
            color = gradient->actual_colors[j].mid_rgb;
            alpha = ZnComposeAlpha(gradient->actual_colors[j].mid_alpha, wi->alpha);
            p3.x = p.x+(p2.x-p.x)*control/100.0;
            p3.y = p.y+(p2.y-p.y)*control/100.0;
            pp3.x = pp.x+(pp2.x-pp.x)*control/100.0;
            pp3.y = pp.y+(pp2.y-pp.y)*control/100.0;
            glColor4us(color->red, color->green, color->blue, alpha);
            glVertex2d(quad[0].x+p3.x, quad[0].y+p3.y);
            glVertex2d(quad[0].x+pp3.x, quad[0].y+pp3.y);
          }
          control = gradient->actual_colors[j+1].control;
          alpha = ZnComposeAlpha(gradient->actual_colors[j+1].alpha, wi->alpha);
          color = gradient->actual_colors[j+1].rgb;
          p = p2;
          pp = pp2;
          glColor4us(color->red, color->green, color->blue, alpha);
          glVertex2d(quad[0].x+p.x, quad[0].y+p.y);
          glVertex2d(quad[0].x+pp.x, quad[0].y+pp.y);
        }
        glEnd();
      }
    }
  }
  else if (type == ZN_CONICAL_GRADIENT) {
    ZnReal       position;
    unsigned int num_p;
    ZnPoint      *genarc, *tarc, p, focalp;
    XColor       col;

    genarc = ZnGetCirclePoints(3, ZN_CIRCLE_FINEST, 0.0, 2*M_PI, &num_p, NULL);
    ZnListAssertSize(ZnWorkPoints, num_p);
    tarc = ZnListArray(ZnWorkPoints);
    ZnTransformPoints((ZnTransfo *) quad, genarc, tarc, num_p);
    p.x = p.y = 0;
    ZnTransformPoint((ZnTransfo *) quad, &p, &focalp);
    
    glBegin(GL_TRIANGLE_STRIP);
    for (i = 0; i < num_p; i++) {
      position = i*100.0/(num_p-1);
      ZnInterpGradientColor(gradient, position, &col, &alpha);
      alpha = ZnComposeAlpha(alpha, wi->alpha);

      /*printf("position: %g --> color: %d %d %d, alpha: %d\n",
        position, col.red, col.green, col.blue, alpha);*/

      glColor4us(col.red, col.green, col.blue, alpha);
      glVertex2d(tarc[i].x, tarc[i].y);
      glVertex2d(focalp.x, focalp.y);
    }
    glEnd();
  }
  
  if (cb) {
    /*
     * Restore the previous GL state.
     */
    ZnGlEndClip(num_clips);
  }
}


void
ZnRenderHollowDot(ZnWInfo       *wi,
                  ZnPoint       *p,
                  ZnReal        size)
{
  int   num_clips = ZnListSize(wi->clip_stack);
  
  ZnGlStartClip(num_clips, False);
  
  glPointSize((GLfloat) (size-2));
  glBegin(GL_POINTS);
  glVertex2d(p->x, p->y);
  glEnd();

  ZnGlRenderClipped();

  glPointSize((GLfloat) size);
  glBegin(GL_POINTS);
  glVertex2d(p->x, p->y);
  glEnd();

  ZnGlRestoreStencil(num_clips, False);

  glBegin(GL_POINTS);
  glVertex2d(p->x, p->y);
  glEnd();

  ZnGlEndClip(num_clips);
}
#endif


#ifdef GL
void
ZnRenderGlyph(ZnTexFontInfo     *tfi,
              int               c)
{
  ZnTexGVI *tgvi;

  tgvi = ZnTexFontGVI(tfi, c);
  if (!tgvi) {
    return;
  }
  //printf("%c --> x0,y0: %d %d, tx0,ty0: %g %g, x1,y1: %d %d, tx1,ty1: %g %g, advance: %g\n",
    //     c, tgvi->v0x, tgvi->v0y, tgvi->t0x, tgvi->t0y,
    //     tgvi->v1x, tgvi->v1y, tgvi->t1x, tgvi->t1y,
    //     tgvi->advance);
  glBegin(GL_QUADS);
  glTexCoord2f(tgvi->t0x, tgvi->t0y); glVertex2s(tgvi->v0x, tgvi->v0y);
  glTexCoord2f(tgvi->t0x, tgvi->t1y); glVertex2s(tgvi->v0x, tgvi->v1y);
  glTexCoord2f(tgvi->t1x, tgvi->t1y); glVertex2s(tgvi->v1x, tgvi->v1y);
  glTexCoord2f(tgvi->t1x, tgvi->t0y); glVertex2s(tgvi->v1x, tgvi->v0y);
  glEnd();
  glTranslatef(tgvi->advance, 0.0, 0.0);
}

#ifdef PTK_800
void
ZnRenderString(ZnTexFontInfo    *tfi,
               unsigned char    *string,
               unsigned int     len)
{
  while (len) {
    ZnRenderGlyph(tfi, *string);
    string++;
    len--;
  }
}
#else
void
ZnRenderString(ZnTexFontInfo    *tfi,
               unsigned char    *string,
               unsigned int     len)
{
  unsigned int  clen;
  Tcl_UniChar   c;

  while (len) {
    clen = Tcl_UtfToUniChar(string, &c);

    ZnRenderGlyph(tfi, c);

    string += clen;
    len -= clen;
  }
}
#endif
#endif

/*
 **********************************************************************************
 *
 * RenderTriangle --
 *      This routine maps an image onto a triangle.
 *      Image coordinates are chosen for  each vertex of the triangle.
 *      A simple affine tex mapping is used as in Zinc there is no way
 *      to specify perspective deformation. No filtering is attempted
 *      on the output pixels. 
 *
 *      In the comments below u and v are image coordinates and x and
 *      y are triangle coordinates.
 *      RenderAffineScanline is an helper function that draws a whole
 *      scan line to the image with linear interpolation.
 *
 **********************************************************************************
 */
static void
RenderAffineScanline(XImage     *image,
                     XImage     *mapped_image,
                     ZnReal     x1,
                     ZnReal     x2,
                     ZnReal     u1,
                     ZnReal     u2,
                     ZnReal     v1,
                     ZnReal     v2,
                     int        y)
{
  ZnReal        du, dv, width;
  int           intx1, intx2, intu, intv;
  int           i;
  
  /* Revert span ends if needed */
  if (x2 < x1) {
    ZnReal      tmp;
    tmp = x1; x1 = x2; x2 = tmp;
    tmp = u1; u1 = u2; u2 = tmp;
    tmp = v1; v1 = v2; v2 = tmp;
  }
  
  /* Compute the interpolation factors */
  width = x2 - x1;
  if (width) {
    du = (u2 - u1) / width;
    dv = (v2 - v1) / width;
  }
  else {
    du = dv = 0;
  }
  intx1 = (int) floor(x1);
  intx2 = (int) floor(x2);
  
  /* Draw the line */
  for (i = intx1; i < intx2; i++) {
    intu = (int) floor(u1);
    intv = (int) floor(v1);
    XPutPixel(mapped_image, i, y, XGetPixel(image, intu, intv));
    u1 += du;
    v1 += dv;
  }
}

static void
RenderTriangle(XImage   *image,
               XImage   *mapped_image,
               ZnPoint  *tri,
               ZnPoint  *im_coords)
{
  ZnReal        dx_A, dx_B;     /* Interpolation factor in x / y */
  ZnReal        du_A, du_B;     /* in u / y */
  ZnReal        dv_A, dv_B;     /* in v / y */
  ZnReal        x1, x2;         /* Span in x */
  ZnReal        u1, u2;         /* Span in u */
  ZnReal        v1, v2;         /* Span in v */
  int           height_A;       /* Scan line # from top top vertex A */
  int           height_B;       /* Scan line # from top top vertex B */
  int           y;              /* Current scan line */
  int           top, a, b;      /* Top triangle vertex and other two */
  int           i;

  /* Find top vertex and deduce the others. */
  top = 0;
  for (i = 1; i < 3; i++) {
    if (tri[i].y <= tri[top].y)
      top = i;
  }
  a = (top+1)%3;
  b = top-1;
  if (b < 0)
    b = 2;
  
  /* Initialize conversion parameters. */
  y = ZnNearestInt(tri[top].y);
  height_A = ZnNearestInt(tri[a].y - tri[top].y);
  height_B = ZnNearestInt(tri[b].y - tri[top].y);
  x1 = x2 = tri[top].x;
  u1 = u2 = im_coords[top].x;
  v1 = v2 = im_coords[top].y;
  if (height_A) {
    dx_A = (tri[a].x - tri[top].x) / height_A;
    du_A = (im_coords[a].x - im_coords[top].x) / height_A;
    dv_A = (im_coords[a].y - im_coords[top].y) / height_A;
  }
  else {
    dx_A = du_A = dv_A = 0;
  }
  if (height_B) {
    dx_B = (tri[b].x - tri[top].x) / height_B;
    du_B = (im_coords[b].x - im_coords[top].x) / height_B;
    dv_B = (im_coords[b].y - im_coords[top].y) / height_B;
  }
  else {
    dx_B = du_B = dv_B = 0;
  }
  
  /* Convert from top to bottom */
  for (i = 2; i > 0; ) {
    while (height_A && height_B) {

      /* Draw a scanline */
      RenderAffineScanline(image, mapped_image, x1, x2, u1, u2, v1, v2, y);

      /* Step the parameters*/
      y++;
      height_A--;
      height_B--;
      x1 += dx_A;
      x2 += dx_B;
      u1 += du_A;
      u2 += du_B;
      v1 += dv_A;
      v2 += dv_B;
    }
    
    /* If either height_A or height_B steps to zero, we have
     * encountered a vertex (A or B) and we are starting conversion
     * along a new edge. Update the parameters before proceeding. */
    if (!height_A) {
      int       na = (a+1)%3;
      
      height_A = ZnNearestInt(tri[na].y - tri[a].y);
      if (height_A) {
        dx_A = (tri[na].x - tri[a].x) / height_A;
        du_A = (im_coords[na].x - im_coords[a].x) / height_A;
        dv_A = (im_coords[na].y - im_coords[a].y) / height_A;
      }
      else {
        dx_A = du_A = dv_A = 0;
      }
      x1 = tri[a].x;
      u1 = im_coords[a].x;
      v1 = im_coords[a].y;
      a = na;
      /* One less vertex to do */
      i--;
    }
    
    if (!height_B) {
      int       nb = b - 1;
      
      if (nb < 0)
        nb = 2;
      height_B = ZnNearestInt(tri[nb].y - tri[b].y);
      if (height_B) {
        dx_B = (tri[nb].x - tri[b].x) / height_B;
        du_B = (im_coords[nb].x - im_coords[b].x) / height_B;
        dv_B = (im_coords[nb].y - im_coords[b].y) / height_B;
      }
      else {
        dx_B = du_B = dv_B = 0;
      }
      x2 = tri[b].x;
      u2 = im_coords[b].x;
      v2 = im_coords[b].y;
      b = nb;
      /* One less vertex to do */
      i--;
    }
  }
}


/*
 **********************************************************************************
 *
 * MapImage --
 *      This procedure maps an image on a parallelogram given in poly.
 *      The given parallelogram should fit in the destination image.
 *      The parallelogram vertices must be ordered as for a triangle
 *       strip: 
 *
 *    v0 ------------ v2
 *       |          |
 *       |          |
 *    v1 ------------ v3
 *
 *      The mapping is done by a simple affine mapping of the image on the
 *      two triangles obtained by cutting the parallelogram along the diogonal
 *      from the second vertex to the third vertex.
 *
 **********************************************************************************
 */
void
ZnMapImage(XImage       *image,
           XImage       *mapped_image,
           ZnPoint      *poly)
{
  ZnPoint       triangle[3];
  ZnPoint       im_coords[3];
  
  triangle[0] = poly[0];
  triangle[1] = poly[1];
  triangle[2] = poly[2];
  im_coords[0].x = 0.0;
  im_coords[0].y = 0.0;
  im_coords[1].x = 0.0;
  im_coords[1].y = image->height-1;
  im_coords[2].x = image->width-1;
  im_coords[2].y = 0.0;
  RenderTriangle(image, mapped_image, triangle, im_coords);

  triangle[0] = poly[1];
  triangle[1] = poly[2];
  triangle[2] = poly[3];
  im_coords[0].x = 0.0;
  im_coords[0].y = image->height-1;
  im_coords[1].x = image->width-1;
  im_coords[1].y = 0.0;
  im_coords[2].x = image->width-1;
  im_coords[2].y = image->height-1;
  RenderTriangle(image, mapped_image, triangle, im_coords);
}
