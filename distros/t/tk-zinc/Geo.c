/*
 * Geo.c -- Implementation of common geometric routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Geo.c,v 1.52 2005/10/19 10:58:11 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

/*
 * Much of the code here is inspired by (or copied from) the Tk code.
 */


#include "Geo.h"
#include "WidgetInfo.h"

#include <memory.h>


static const char rcsid[] = "$Id: Geo.c,v 1.52 2005/10/19 10:58:11 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


void
ZnPolyInit(ZnPoly       *poly)
{
  poly->num_contours = 0;
  poly->contours = NULL;
}

void
ZnPolyContour1(ZnPoly           *poly,
               ZnPoint          *pts,
               unsigned int     num_pts,
               ZnBool           cw)
{
  poly->num_contours = 1;
  poly->contours = &poly->contour1;
  poly->contour1.num_points = num_pts;
  poly->contour1.points = pts;
  poly->contour1.cw = cw;
  poly->contour1.controls = NULL;
}

void
ZnPolySet(ZnPoly        *poly1,
          ZnPoly        *poly2)
{
  ZnPolyFree(poly1);
  if (poly2->num_contours == 1) {
    ZnPolyContour1(poly1, poly2->contours[0].points, poly2->contours[0].num_points,
                   poly2->contours[0].cw);
    if (poly2->contours != &poly2->contour1) {
      ZnFree(poly2->contours);
    }
  }
  else {
    poly1->num_contours = poly2->num_contours;
    poly1->contours = poly2->contours;
  }
}

void
ZnPolyFree(ZnPoly       *poly)
{
  if (poly->num_contours) {
    unsigned int i;
    for (i = 0; i < poly->num_contours; i++) {
      ZnFree(poly->contours[i].points);
/*      if (poly->contours[i].controls) {
          ZnFree(poly->contours[i].controls);
      }*/
    }
    if (poly->contours != &poly->contour1) {
      ZnFree(poly->contours);
    }
    poly->num_contours = 0;
    poly->contours = NULL;
  }
}

void
ZnTriStrip1(ZnTriStrip          *tristrip,
            ZnPoint             *pts,
            unsigned int        num_pts,
            ZnBool              fan)
{
  tristrip->num_strips = 1;
  tristrip->strips = &tristrip->strip1;
  tristrip->strip1.points = pts;
  tristrip->strip1.num_points = num_pts;
  tristrip->strip1.fan = fan;
}

void
ZnTriFree(ZnTriStrip    *tristrip)
{
  if (tristrip->num_strips) {
    unsigned int i;
    for (i = 0; i < tristrip->num_strips; i++) {
      ZnFree(tristrip->strips[i].points);
    }
    if (tristrip->strips != &tristrip->strip1) {
      ZnFree(tristrip->strips);
    }
    tristrip->num_strips = 0;
    tristrip->strips = NULL;
  }
}

/*
 * Compute the origin of the rectangle given
 * by position, anchor, width and height.
 */
void
ZnAnchor2Origin(ZnPoint         *position,
                ZnDim           width,
                ZnDim           height,
                Tk_Anchor       anchor,
                ZnPoint         *origin)
{
  switch (anchor) {
  case TK_ANCHOR_CENTER:
    origin->x = position->x - width/2;
    origin->y = position->y - height/2;
    break;
  case TK_ANCHOR_NW:
    *origin = *position;
    break;
  case TK_ANCHOR_N:
    origin->x = position->x - width/2;
    origin->y = position->y;
    break;
  case TK_ANCHOR_NE:
    origin->x = position->x - width;
    origin->y = position->y;
    break;
  case TK_ANCHOR_E:
    origin->x = position->x - width;
    origin->y = position->y - height/2;
    break;
  case TK_ANCHOR_SE:
    origin->x = position->x - width;
    origin->y = position->y - height;
    break;
  case TK_ANCHOR_S:
    origin->x = position->x - width/2;
    origin->y = position->y - height;
    break;
  case TK_ANCHOR_SW:
    origin->x = position->x;
    origin->y = position->y - height;
    break;
  case TK_ANCHOR_W:
    origin->x = position->x;
    origin->y = position->y - height/2;
    break;
  }
}


/*
 * Compute the anchor position given the bbox origin, width,
 * height and the anchor.
 */
void
ZnOrigin2Anchor(ZnPoint         *origin,
                ZnDim           width,
                ZnDim           height,
                Tk_Anchor       anchor,
                ZnPoint         *position)
{
  switch (anchor) {
  case TK_ANCHOR_CENTER:
    position->x = origin->x + width/2;
    position->y = origin->y + height/2;
    break;
  case TK_ANCHOR_NW:
    *position = *origin;
    break;
  case TK_ANCHOR_N:
    position->x = origin->x + width/2;
    position->y = origin->y;
    break;
  case TK_ANCHOR_NE:
    position->x = origin->x + width;
    position->y = origin->y;
    break;
  case TK_ANCHOR_E:
    position->x = origin->x + width;
    position->y = origin->y + height/2;
    break;
  case TK_ANCHOR_SE:
    position->x = origin->x + width;
    position->y = origin->y + height;
    break;
  case TK_ANCHOR_S:
    position->x = origin->x + width/2;
    position->y = origin->y + height;
    break;
  case TK_ANCHOR_SW:
    position->x = origin->x;
    position->y = origin->y + height;
    break;
  case TK_ANCHOR_W:
    position->x = origin->x;
    position->y = origin->y + height/2;
    break;
  }
}

/*
 * Compute the anchor position given a rectangle and
 * the anchor. The rectangle vertices must be ordered
 * as for a triangle strip: 
 *
 *    v0 ------------ v2
 *       |          |
 *       |          |
 *    v1 ------------ v3
 */
void
ZnRectOrigin2Anchor(ZnPoint     *rect,
                    Tk_Anchor   anchor,
                    ZnPoint     *position)
{
  switch (anchor) {
  case TK_ANCHOR_CENTER:
    position->x = (rect[0].x + rect[3].x) / 2.0;
    position->y = (rect[0].y + rect[3].y) / 2.0;
    break;
  case TK_ANCHOR_NW:
    *position = *rect;
    break;
  case TK_ANCHOR_N:
    position->x = (rect[0].x + rect[2].x) / 2.0;
    position->y = (rect[0].y + rect[2].y) / 2.0;
    break;
  case TK_ANCHOR_NE:
    *position = rect[2];
    break;
  case TK_ANCHOR_E:
    position->x = (rect[2].x + rect[3].x) / 2.0;
    position->y = (rect[2].y + rect[3].y) / 2.0;
    break;
  case TK_ANCHOR_SE:
    *position = rect[3];
    break;
  case TK_ANCHOR_S:
    position->x = (rect[1].x + rect[3].x) / 2.0;
    position->y = (rect[1].y + rect[3].y) / 2.0;
    break;
  case TK_ANCHOR_SW:
    *position = rect[1];
    break;
  case TK_ANCHOR_W:
    position->x = (rect[0].x + rect[1].x) / 2.0;
    position->y = (rect[0].y + rect[1].y) / 2.0;
    break;
  }
}

void
ZnBBox2XRect(ZnBBox     *bbox,
             XRectangle *r)
{
  r->x = ZnNearestInt(bbox->orig.x);
  r->y = ZnNearestInt(bbox->orig.y);
  r->width = ZnNearestInt(bbox->corner.x) - r->x;
  r->height = ZnNearestInt(bbox->corner.y) - r->y;
}


void
ZnGetStringBBox(char    *str,
                Tk_Font font,
                ZnPos   x,
                ZnPos   y,
                ZnBBox  *str_bbox)
{
  Tk_FontMetrics fm;

  str_bbox->orig.x = x;
  str_bbox->corner.x  = x + Tk_TextWidth(font, str, (int) strlen(str));
  Tk_GetFontMetrics(font, &fm);
  str_bbox->orig.y = y - fm.ascent;
  str_bbox->corner.y = str_bbox->orig.y + fm.ascent + fm.descent;
}


void
ZnResetBBox(ZnBBox *bbox)
{
  bbox->orig.x = bbox->orig.y = 0;
  bbox->corner = bbox->orig;
}


void
ZnCopyBBox(ZnBBox *bbox_from,
           ZnBBox *bbox_to)
{
  bbox_to->orig = bbox_from->orig;
  bbox_to->corner = bbox_from->corner;
}


void
ZnIntersectBBox(ZnBBox *bbox1,
                ZnBBox *bbox2,
                ZnBBox *bbox_inter)
{
  if ((bbox1->corner.x < bbox2->orig.x) ||
      (bbox1->corner.y < bbox2->orig.y) ||
      (bbox2->corner.x < bbox1->orig.x) ||
      (bbox2->corner.y < bbox1->orig.y)) {
    ZnResetBBox(bbox_inter);
  }
  else {
    bbox_inter->orig.x = MAX(bbox1->orig.x, bbox2->orig.x);
    bbox_inter->orig.y = MAX(bbox1->orig.y, bbox2->orig.y);
    bbox_inter->corner.x = MIN(bbox1->corner.x, bbox2->corner.x);
    bbox_inter->corner.y = MIN(bbox1->corner.y, bbox2->corner.y);
  }
}


ZnBool
ZnIsEmptyBBox(ZnBBox *bbox)
{
  return (bbox->orig.x >= bbox->corner.x) || (bbox->orig.y >= bbox->corner.y);
}


void
ZnAddBBoxToBBox(ZnBBox *bbox,
                ZnBBox *bbox2)
{
  if (ZnIsEmptyBBox(bbox2)) {
    return;
  }
  if (ZnIsEmptyBBox(bbox)) {
    ZnCopyBBox(bbox2, bbox);
  }
  else {
    bbox->orig.x = MIN(bbox->orig.x, bbox2->orig.x);
    bbox->orig.y = MIN(bbox->orig.y, bbox2->orig.y);
    bbox->corner.x = MAX(bbox->corner.x, bbox2->corner.x);
    bbox->corner.y = MAX(bbox->corner.y, bbox2->corner.y);
  }
}


void
ZnAddPointToBBox(ZnBBox *bbox,
                 ZnPos  px,
                 ZnPos  py)
{
  if (ZnIsEmptyBBox(bbox)) {
    bbox->orig.x = px;
    bbox->orig.y = py;
    bbox->corner.x = bbox->orig.x + 1;
    bbox->corner.y = bbox->orig.y + 1;
  }
  else {
    bbox->orig.x = MIN(bbox->orig.x, px);
    bbox->orig.y = MIN(bbox->orig.y, py);
    bbox->corner.x = MAX(bbox->corner.x, px + 1);
    bbox->corner.y = MAX(bbox->corner.y, py + 1);
  }
}


void
ZnAddPointsToBBox(ZnBBox        *bbox,
                  ZnPoint       *points,
                  unsigned int  num_points)
{
  ZnReal x1, y1, x2, y2, cur;

  if (points == NULL) {
    return;
  }
  
  if (num_points == 0) {
    return;
  }
  
  if (ZnIsEmptyBBox(bbox)) {
    x1 = points->x;
    y1 = points->y;
    x2 = x1 + 1;
    y2 = y1 + 1;
    num_points--;
    points++;
  }
  else {
    x1 = bbox->orig.x;
    y1 = bbox->orig.y;
    x2 = bbox->corner.x;
    y2 = bbox->corner.y;
  }

  for ( ; num_points > 0; num_points--, points++) {
    cur = points->x;
    if (cur < x1) {
      x1 = cur;
    }
    if (cur > x2) {
      x2 = cur;
    }
    cur = points->y;
    if (cur < y1) {
      y1 = cur;
    }
    if (cur > y2) {
      y2 = cur;
    }
  }
  bbox->orig.x = x1;
  bbox->orig.y = y1;
  if (x1 == x2) {
    x2++;
  }
  if (y1 == y2) {
    y2++;
  }
  bbox->corner.x = x2;
  bbox->corner.y = y2;
}


void
ZnAddStringToBBox(ZnBBox        *bbox,
                  char          *str,
                  Tk_Font       font,
                  ZnPos         cx,
                  ZnPos         cy)
{
  ZnBBox        str_bbox;
  
  ZnGetStringBBox(str, font, cx, cy, &str_bbox);
  ZnAddBBoxToBBox(bbox, &str_bbox);
}

ZnBool
ZnPointInBBox(ZnBBox    *bbox,
              ZnPos     x,
              ZnPos     y)
{
  return ((x >= bbox->orig.x) && (x < bbox->corner.x) &&
          (y >= bbox->orig.y) && (y < bbox->corner.y));
}


/*
 * Tell where aa area is with respect to another area.
 * Return -1 if the first is entirely outside the second,
 * 1 if it is entirely inside and 0 otherwise.
 */
int
ZnBBoxInBBox(ZnBBox     *bbox1,
             ZnBBox     *bbox2)
{
  if ((bbox1->corner.x <= bbox2->orig.x) ||
      (bbox1->orig.x >= bbox2->corner.x) ||
      (bbox1->corner.y <= bbox2->orig.y) ||
      (bbox1->orig.y >= bbox2->corner.y)) {
    return -1;
  }
  if ((bbox2->orig.x <= bbox1->orig.x) &&
      (bbox1->corner.x <= bbox2->corner.x) &&
      (bbox2->orig.y <= bbox1->orig.y) &&
      (bbox1->corner.y <= bbox2->corner.y)) {
    return 1;
  }
  return 0;
}

/*
 * Tell where a line is with respect to an area.
 * Return -1 if the line is entirely outside the bbox, 1
 * if it is entirely inside and 0 otherwise.
 */
int
ZnLineInBBox(ZnPoint    *p1,
             ZnPoint    *p2,
             ZnBBox     *bbox)
{
  ZnBool p1_inside = ZnPointInBBox(bbox, p1->x, p1->y);
  ZnBool p2_inside = ZnPointInBBox(bbox, p2->x, p2->y);

  if (p1_inside != p2_inside) {
    return 0;
  }

  if (p1_inside && p2_inside) {
    return 1;
  }
  
  /*
   * Segment may intersect area, check it more thoroughly.
   */
  /* Vertical line */
  if (p1->x == p2->x) {
    if (((p1->y >= bbox->orig.y) ^ (p2->y >= bbox->orig.y)) &&
        (p1->x >= bbox->orig.x) &&
        (p1->x <= bbox->corner.x)) {
      return 0;
    }
  }
  /* Horizontal line */
  else if (p1->y == p2->y) {
    if (((p1->x >= bbox->orig.x) ^ (p2->x >= bbox->orig.x)) &&
        (p1->y >= bbox->orig.y) &&
        (p1->y <= bbox->corner.y)) {
      return 0;
    }
  }
  /* Diagonal, do it the hard way. */
  else {
    ZnReal      slope = (p2->y - p1->y) / (p2->x - p1->x);
    ZnDim       low, high, x, y;
    ZnDim       bbox_width = bbox->corner.x - bbox->orig.x;
    ZnDim       bbox_height = bbox->corner.y - bbox->orig.y;

    /* Check against left edge */
    if (p1->x < p2->x) {
      low = p1->x;
      high = p2->x;
    }
    else {
      low = p2->x;
      high = p1->x;
    }

    y = p1->y + (bbox->orig.x - p1->x) * slope;
    if ((bbox->orig.x >= low) && (bbox->orig.x <= high) &&
        (y >= bbox->orig.y) && (y <= bbox->corner.y))
      return 0;

    /* Check against right edge */
    y += bbox_width * slope;
    if ((y >= bbox->orig.y) && (y <= bbox->corner.y) &&
        (bbox->corner.x >= low) && (bbox->corner.x <= high))
      return 0;
        
    /* Check against bottom edge */
    if (p1->y < p2->y) {
      low = p1->y;
      high = p2->y;
    }
    else {
      low = p2->y;
      high = p1->y;
    }

    x = p1->x + (bbox->orig.y - p1->y) / slope;
    if ((x >= bbox->orig.x) && (x <= bbox->corner.x) &&
        (bbox->orig.y >= low) && (bbox->orig.y <= high))
      return 0;

    /* Check against top edge */
    x += bbox_height / slope;
    if ((x >= bbox->orig.x) && (x <= bbox->corner.x) &&
        (bbox->corner.y >= low) && (bbox->corner.y <= high))
      return 0;
  }

  return -1;
}


ZnBool
ZnTestCCW(ZnPoint               *points,
          unsigned int  num_points)
{
  ZnPoint       *p, *p_p=NULL, *p_n=NULL, min;
  ZnReal        xprod;
  unsigned int  i, min_index;
  
  if (num_points < 3) {
    return True;
  }

  /*
   * First find the lowest rightmost vertex. In X11 this is the
   * topmost one.
   */
  p = points;
  min = *p;
  min_index = 0;
  for (i = 1, p++; i < num_points; i++, p++) {
    if ((p->y < min.y) ||
        ((p->y == min.y) && (p->x > min.x))) {
      min_index = i;
      min = *p;
    }
  }
  /*
   * Then find the indices of the previous and next
   * vertices.
   */
  p = &points[min_index];
  /*printf("min index %d, prev %d, next %d\n", min_index,
    (min_index+(num_points-1))%num_points, (min_index+1)%num_points);*/
  /*printf("lower point index %d %d %d\n",
    (min_index+(num_points-1))%num_points, min_index, (min_index+1)%num_points);*/
  /*
   * Try to find preceding and following points that are not
   * the same as the base point.
   */
  for (i = 1; i < num_points; i++) {
    p_p = &points[(min_index+(num_points-i))%num_points]; /* min_index-1 */
    if ((p_p->x != p->x) || (p_p->y != p->y)) {
      break;
    }
  }
  for (i = 1; i < num_points; i++) {
    p_n = &points[(min_index+i)%num_points];
    if ((p_p->x != p->x) || (p_p->y != p->y)) {
      break;
    }
  }
  xprod = ((p->x - p_p->x) * (p_n->y - p->y)) - ((p->y - p_p->y) * (p_n->x - p->x));
  return (xprod < 0.0); /* Should be > 0 but X11 has Y axis reverted. */
}


/*
 * ZnShiftLine --
 *      Given two points describing a line and a distance, return
 *      to points describing a line parallel to it at the given distance.
 *      When looking the line from p1 to p2 the new line will be dist away
 *      on its left. Negative values are allowed for dist, resulting in a line
 *      on the right.
 */
void
ZnShiftLine(ZnPoint     *p1,
            ZnPoint     *p2,
            ZnReal      dist,
            ZnPoint     *p3,
            ZnPoint     *p4)
{
  static int    shift_table[129];
  ZnBool        dx_neg, dy_neg;
  int           dx, dy;

  /*
   * Initialize the conversion table.
   */
  if (shift_table[0] == 0) {
    int         i;
    ZnReal      tangent, cosine;
    
    for (i = 0; i <= 128; i++) {
      tangent = i/128.0;
      cosine = 128/cos(atan(tangent)) + 0.5;
      shift_table[i] = (int) cosine;
    }
  }

  *p3 = *p1;
  dx = (int) (p2->x - p1->x);
  dy = (int) (p2->y - p1->y);
  if (dx < 0) {
    dx = -dx;
    dx_neg = True;
  }
  else {
    dx_neg = False;
  }
  if (dy < 0) {
    dy = -dy;
    dy_neg = True;
  }
  else {
    dy_neg = False;
  }
  if ((dy < PRECISION_LIMIT) && (dx < PRECISION_LIMIT)) {
    fprintf(stderr, "ShiftLine: segment is a point\n");
    return;
  }

  if (dy <= dx) {
    dy = (((int) dist * shift_table[(dy*128)/dx]) + 64) / 128;
    if (!dx_neg) {
      dy = -dy;
    }
    p3->y += dy;
  }
  else {
    dx = (((int) dist * shift_table[(dx*128)/dy]) + 64) / 128;
    if (dy_neg) {
      dx = -dx;
    }
    p3->x += dx;
  }

  p4->x = p3->x + (p2->x - p1->x);
  p4->y = p3->y + (p2->y - p1->y);
}


/*
 * IntersectLines --
 *      Given two lines described by two points, compute their intersection.
 *      The function returns True if the lines are not parallel and False
 *      otherwise.
 */
ZnBool
ZnIntersectLines(ZnPoint        *a1,
                 ZnPoint        *a2,
                 ZnPoint        *b1,
                 ZnPoint        *b2,
                 ZnPoint        *pi)
{
  ZnReal dxadyb, dxbdya, dxadxb, dyadyb, p, q;

  dxadyb = (a2->x - a1->x)*(b2->y - b1->y);
  dxbdya = (b2->x - b1->x)*(a2->y - a1->y);
  dxadxb = (a2->x - a1->x)*(b2->x - b1->x);
  dyadyb = (a2->y - a1->y)*(b2->y - b1->y);
  
  if (dxadyb == dxbdya) {
    return False;
  }
  
  p = a1->x*dxbdya - b1->x*dxadyb + (b1->y - a1->y)*dxadxb;
  q = dxbdya - dxadyb;
  if (q < 0) {
    p = -p;
    q = -q;
  }
  if (p < 0) {
    pi->x = - ((-p + q/2)/q);
  }
  else {
    pi->x = (p + q/2)/q;
  }
  
  p = a1->y*dxadyb - b1->y*dxbdya + (b1->x - a1->x)*dyadyb;
  q = dxadyb - dxbdya;
  if (q < 0) {
    p = -p;
    q = -q;
  }
  if (p < 0) {
    pi->y = - ((-p + q/2)/q);
  }
  else {
    pi->y = (p + q/2)/q;
  }
  
  return True;
}


/*
 * InsetPolygon --
 *      Inset the given polygon by the given amount. The
 *     value can be negative, in this case the polygon will
 *     be outset.
 */
/**** A FINIR ****/
void
ZnInsetPolygon(ZnPoint          *p,
               unsigned int     num_points,
               ZnDim            inset)
{
  ZnPoint       *p1, *p2;
  ZnPoint       new_p1, new_p2;
  /*  ZnPoint   shift1, shift2;*/
  unsigned int  i, processed_points;

  processed_points = 0;
  
  if ((p->x == p[num_points-1].x) && (p->y == p[num_points-1].y)) {
    num_points--;
  }
  for (p1 = p, p2 = p1+1, i = 0; i < num_points; i++, p1 = p2, p2++) {
    /*
     * Wrap to the first point.
     */
    if (i == num_points-1) {
      p2 = p;
    }
    /*
     * Skip duplicate vertices.
     */
    if ((p2->x == p1->x) && (p2->y == p1->y)) {
      continue;
    }
    
    ZnShiftLine(p1, p2, inset, &new_p1, &new_p2);

    if (processed_points >= 1) {
    }
  }
}


/*
 * Compute the two corner points of a thick line end.
 * Two points describing the line segment and the width
 * are given as input. If projecting is true this function
 * mimics the X11 line projecting behaviour. The computed
 * end is located around p2.
 */
void
ZnGetButtPoints(ZnPoint *p1,
                ZnPoint *p2,
                ZnDim   width,
                ZnBool  projecting,
                ZnPoint *c1,
                ZnPoint *c2)
{
  ZnReal        w_2 = width/2.0;
  ZnDim         length = hypot(p2->x - p1->x, p2->y - p1->y);
  ZnReal        delta_x, delta_y;
  
  if (length == 0.0) {
    c1->x = c2->x = p2->x;
    c1->y = c2->y = p2->y;
  }
  else {
    delta_x = -w_2 * (p2->y - p1->y) / length;
    delta_y = w_2 * (p2->x - p1->x) / length;
    c1->x = p2->x + delta_x;
    c2->x = p2->x - delta_x;
    c1->y = p2->y + delta_y;
    c2->y = p2->y - delta_y;
    if (projecting) {
      c1->x += delta_y;
      c2->x += delta_y;
      c1->y -= delta_x;
      c2->y -= delta_x;
    }
  }
}

/*
 * Compute the inside and outside points of the mitered
 * corner formed by a thick line going through 3 points.
 * If the angle formed by the three points is less than
 * 11 degrees, False is returned an no points are computed.
 * Else True is returned and the points are in c1, c2.
 *
 * If someday the code is switched to REAL coordinates, we
 * must round each coordinate to the nearer integer to mimic
 * the way pixels are drawn. Sample code: floor(p->x+0.5);
 *
 * Hmmm, the switch has been done but not the rounding ;-)
 */
ZnBool
ZnGetMiterPoints(ZnPoint        *p1,
                 ZnPoint        *p2,
                 ZnPoint        *p3,
                 ZnDim          width,
                 ZnPoint        *c1,
                 ZnPoint        *c2)
{
  static ZnReal deg11 = (11.0*2.0*M_PI)/360.0;
  ZnReal        theta1;         /* angle of p2-p1 segment. */
  ZnReal        theta2;         /* angle of p2-p3 segment. */
  ZnReal        theta;          /* angle of the joint */
  ZnReal        theta3;         /* angle of bisector of the joint toward
                                 * the external point of the joint. */
  ZnReal        dist;           /* distance of the external points
                                 * of the corner from the mid point
                                 * p2. */
  ZnReal        delta_x, delta_y; /* projection of (dist,theta3) on x
                                   * and y. */
  
  if (p2->y == p1->y) {
    theta1 = (p2->x < p1->x) ? 0.0 : M_PI;
  }
  else if (p2->x == p1->x) {
    theta1 = (p2->y < p1->y) ? M_PI/2.0 : -M_PI/2.0;
  }
  else {
    theta1 = atan2(p1->y - p2->y, p1->x - p2->x);
  }
  if (p3->y == p2->y) {
    theta2 = (p3->x > p2->x) ? 0.0 : M_PI;
  }
  else if (p3->x == p2->x) {
    theta2 = (p3->y > p2->y) ? M_PI/2.0 : -M_PI/2.0;
  }
  else {
    theta2 = atan2(p3->y - p2->y, p3->x - p2->x);
  }
  theta = theta1 - theta2;
  if (theta > M_PI) {
    theta -= 2.0*M_PI;
  }
  else if (theta < -M_PI) {
    theta += 2*M_PI;
  }
  if ((theta < deg11) && (theta > -deg11)) {
    return False;
  }
  /*
   * Compute the distance of the internal and external
   * corner points from the intersection p2 (considered
   * at 0,0).
   */
  dist = 0.5*width / sin(0.5*theta);
  dist = ABS(dist);

  /*
   * Compute the angle of the bisector of the joint that
   * goes toward the outside of the joint (the left hand
   * when looking from p1-p2).
   */
  theta3 = (theta1 + theta2)/2.0;
  if (sin(theta3 - (theta1 + M_PI)) < 0.0) {
    theta3 += M_PI;
  }
  
  delta_x = dist * cos(theta3);
  c1->x = p2->x + delta_x;
  c2->x = p2->x - delta_x;
  delta_y = dist * sin(theta3);
  c1->y = p2->y + delta_y;
  c2->y = p2->y - delta_y;
  
  return True;
}

/*
 * Tell where a thick polyline is with respect to an area.
 * Return -1 if the polyline is entirely outside the bbox, 1
 * if it is entirely inside and 0 otherwise. The joints can
 * be specified as JoinMiter, JoinRound, JoinBevel. The ends
 * can be: CapRound, CapButt, CapProjecting.
 */
int
ZnPolylineInBBox(ZnPoint        *points,
                 unsigned int   num_points,
                 ZnDim          width,
                 int            cap_style,
                 int            join_style,
                 ZnBBox         *bbox)
{
  unsigned int  count;
  int           inside = -1;
  ZnBool        do_miter_as_bevel;
  ZnPoint       poly[4];
  
  /*
   * If the first point is inside the area, change inside
   * accordingly.
   */
  if ((points[0].x >= bbox->orig.x) && (points[0].x <= bbox->corner.x) &&
      (points[0].y >= bbox->orig.y) && (points[0].y <= bbox->corner.y)) {
    inside = 1;
  }

  /*
   * Now iterate through all the edges. Compute a polygon for
   * each and test it against the area. At each vertex an oval
   * of radius width/2 is also tested to account for round ends
   * and joints.
   */
  do_miter_as_bevel = False;
  for (count = num_points; count >= 2; count--, points++) {

    /*
     * Test a circle around the first point if CapRound or
     * around every joint if JoinRound.
     */
    if (((cap_style == CapRound) && (count == num_points)) ||
        ((join_style == JoinRound) && (count != num_points))) {
      if (ZnOvalInBBox(points, width, width, bbox) != inside) {
        return 0;
      }
    }
    /*
     * Build a polygon to represent an edge from the current
     * point to the next. Special cases for the first and
     * last edges to implement the line ends.
     */
    /*
     * First vertex of the edge
     */
    if (count == num_points) {
      ZnGetButtPoints(&points[1], points, width,
                      cap_style == CapProjecting, poly, &poly[1]);
    }
    /*
     * Here we are at a joint starting a new edge. If the
     * joint is mitered, start by carrying over the points
     * from the previous edge. Otherwise compute new points
     * for a butt end.
     */
    else if ((join_style == JoinMiter) && !do_miter_as_bevel) {
      poly[0] = poly[3];
      poly[1] = poly[2];
    }
    else {
      ZnGetButtPoints(&points[1], points, width, 0, poly, &poly[1]);
      /*
       * If the previous joint was beveled (or considered so),
       * check the polygon that fill the bevel. It has more or
       * less an X shape, i.e, it's self intersecting. If this
       * is not ok, it may be necessary to permutte poly[1] &
       * poly[2].
       */
      if ((join_style == JoinBevel) || do_miter_as_bevel) {
        if (ZnPolygonInBBox(poly, 4, bbox, NULL) != inside) {
          return 0;
        }
        do_miter_as_bevel = False;
      }
    }

    /*
     * Opposite vertex of the edge.
     */
    if (count == 2) {
      ZnGetButtPoints(points, &points[1], width, cap_style == CapProjecting,
                      &poly[2], &poly[3]);
    }
    else if (join_style == JoinMiter) {
      if (ZnGetMiterPoints(points, &points[1], &points[2], width,
                         &poly[2], &poly[3]) == False) {
        do_miter_as_bevel = True;
        ZnGetButtPoints(points, &points[1], width, 0, &poly[2], &poly[3]);
      }
    }
    else {
      ZnGetButtPoints(points, &points[1], width, 0, &poly[2], &poly[3]);
    }

    if (ZnPolygonInBBox(poly, 4, bbox, NULL) != inside) {
      return 0;
    }
  }

  /*
   * Test a circle around the last point if CapRound.
   */
  if (cap_style == CapRound) {
    if (ZnOvalInBBox(points, width, width, bbox) != inside) {
      return 0;
    }
  }

  return inside;
}


/*
 * Tell where a polygon is with respect to an area.
 * Return -1 if the polygon is entirely outside the bbox, 1
 * if it is entirely inside and 0 otherwise. If area_enclosed
 * is not NULL it tells whether the area is enclosed by the
 * polygon or not.
 */
int
ZnPolygonInBBox(ZnPoint         *points,
                unsigned int    num_points,
                ZnBBox          *bbox,
                ZnBool          *area_enclosed)
{
  int           inside, count;
  ZnPoint       *p, *head, *first, *second;
  ZnBool        closed;

  if (area_enclosed) {
    *area_enclosed = False;
  }
  p = head = points;
  closed = True;
  count = num_points-2;
  /*
   * Check to see if closed. If not adjust num_points and
   * record this.
   */
  if ((points[0].x != points[num_points-1].x) ||
      (points[0].y != points[num_points-1].y)) {
    closed = False;
    count = num_points-1;
  }

  /*
   * Get the status of the first edge.
   */
  inside = ZnLineInBBox(&p[0], &p[1], bbox);
  p++;
  if (inside == 0) {
    return 0;
  }
  for (; count > 0; p++, count--) {
    first = &p[0];
    /*
     * Pretend the polygon is closed if this is not the case.
     */
    if (!closed && (count == 1)) {
      second = head;
    }
    else {
      second = &p[1];
    }
    
    if (ZnLineInBBox(first, second, bbox) != inside) {
      return 0;
    }
  }

  /*
   * If all the edges are inside the area, the polygon is
   * inside the area. If all the edges are outside, the polygon
   * may completely enclose the area. Test if the origin of
   * the area is inside the polygon to decide this.
   */
  if (inside == 1) {
    return 1;
  }

  /*printf("PolygonInBBox, np = %d, x = %g, y = %g, dist = %g\n",
         num_points, bbox->orig.x, bbox->orig.y,
         PolygonToPointDist(points, num_points, &bbox->orig));*/
  if (ZnPolygonToPointDist(points, num_points, &bbox->orig) <= 0.0) {
    if (area_enclosed) {
      *area_enclosed = True;
    }
    return 0;
  }
  
  return -1;
}


/*
 * Tell where an oval is with respect to an area.
 * Return -1 if the oval is entirely outside the bbox, 1
 * if it is entirely inside and 0 otherwise.
 */
int
ZnOvalInBBox(ZnPoint    *center,
             ZnDim      width,
             ZnDim      height,
             ZnBBox     *bbox)
{
  ZnPoint       origin, corner;
  ZnDim         w_2, h_2;
  ZnReal        delta_x, delta_y;
  
  w_2 = (width+1)/2;
  h_2 = (height+1)/2;
  
  origin.x = center->x - w_2;
  origin.y = center->y - h_2;
  corner.x = center->x + w_2;
  corner.y = center->y + h_2;

  /*
   * This if the oval bbox is completely inside or outside
   * of the area. Trivial case first.
   */
  if ((bbox->orig.x <= origin.x) && (bbox->corner.x >= corner.x) &&
      (bbox->orig.y <= origin.y) && (bbox->corner.y >= corner.y)) {
    return 1;
  }
  if ((bbox->corner.x < origin.x) || (bbox->orig.x > corner.x) ||
      (bbox->corner.y < origin.y) || (bbox->orig.y > corner.y)) {
    return -1;
  }

  /*
   * Then test all sides of the area against the oval center.
   * If the point of a side closest to the center is inside
   * the oval, then the oval intersects the area.
   */

  /*
   * Compute the square of the Y axis distance, reducing
   * the oval to a unit circle to take into account the
   * shape factor.
   */
  delta_y = bbox->orig.y - center->y;
  if (delta_y < 0.0) {
    delta_y = center->y - bbox->corner.y;
    if (delta_y < 0.0) {
      delta_y = 0.0;
    }
  }
  delta_y /= h_2;
  delta_y *= delta_y;

  /*
   * Test left and then right edges.
   */
  delta_x = (bbox->orig.x - center->x) / w_2;
  delta_x *= delta_x;
  if ((delta_x + delta_y) <= 1.0) {
    return 0;
  }
  delta_x = (bbox->corner.x - center->x) / w_2;
  delta_x *= delta_x;
  if ((delta_x + delta_y) <= 1.0) {
    return 0;
  }
  
  /*
   * Compute the square of the X axis distance, reducing
   * the oval to a unit circle to take into account the
   * shape factor.
   */
  delta_x = bbox->orig.x - center->x;
  if (delta_x < 0.0) {
    delta_x = center->x - bbox->corner.x;
    if (delta_x < 0.0) {
      delta_x = 0.0;
    }
  }
  delta_x /= w_2;
  delta_x *= delta_x;
  
  /*
   * Test top and then bottom edges.
   */
  delta_y = (bbox->orig.y - center->y) / h_2;
  delta_y *= delta_y;
  if ((delta_x + delta_y) <= 1.0) {
    return 0;
  }
  delta_y = (bbox->corner.y - center->y) / h_2;
  delta_y *= delta_y;
  if ((delta_x + delta_y) <= 1.0) {
    return 0;
  }

  return -1;
}


/*
 * Tell if a point is in an angular range whose center is 0,0.
 * The range is specified by a starting angle and an angle extent.
 * The use of a double here is important, don't change it. In some
 * case we need to normalize a figure to take care of its shape and
 * the result needs precision.
 */
ZnBool
ZnPointInAngle(int      start_angle,
               int      angle_extent,
               ZnPoint  *p)
{
  ZnReal point_angle;
  int    angle_diff;

  if ((p->x == 0) && (p->y == 0)) {
    point_angle = 0.0;
  }
  else {
    point_angle = atan2(p->y, p->x) * 180.0 / M_PI;
  }
  angle_diff = (ZnNearestInt(point_angle) - start_angle) % 360;
  if (angle_diff < 0) {
    angle_diff += 360;
  }
  return ((angle_diff <= angle_extent) ||
          ((angle_extent < 0) && ((angle_diff - 360) >= angle_extent)));
}

/*
 * PointCartesianToPolar --
 *	Convert a point in cartesian coordinates (delta_x, delta_y)
 *  in polar coordinates (rho, theta)
 *	in a reference system described by angle heading
 *	(angles running clockwise) to a point .
 *
 */
void
ZnPointCartesianToPolar(ZnReal heading,
                        ZnReal *rho,
                        ZnReal *theta,  /* in degree -180 , + 180 */
                        ZnReal delta_x,
                        ZnReal delta_y)
{
  ZnReal theta_rad;
  theta_rad = heading - ZnProjectionToAngle(delta_x,delta_y) - M_PI_2;
  *theta = ZnRadDeg(theta_rad); 
  *rho = sqrt( delta_x * delta_x + delta_y * delta_y );
}

/*
 * PointPolarToCartesian --
 *      Convert a point in polar coordinates (rho, theta)
 *      in a reference system described by angle heading
 *      (angles running clockwise) to a point in cartesian
 *      coordinates (delta_x, delta_y).
 *
 */
void
ZnPointPolarToCartesian(ZnReal  heading,
                        ZnReal  rho,
                        ZnReal  theta,
                        ZnReal  *delta_x,
                        ZnReal  *delta_y)
{
  ZnReal        to_angle;

  /* Compute angle in trigonometric system */
  /*  to_angle = ZnDegRad(theta) + heading - M_PI_2;*/
  to_angle = heading - ZnDegRad(theta) - M_PI_2;
  /* Compute cartesian coordinates */
  *delta_x = rho * cos(to_angle);
  *delta_y = rho * sin(to_angle);
}

/*
 * Return a vector angle given its projections
 */
ZnReal
ZnProjectionToAngle(ZnReal      dx,
                    ZnReal      dy)
{
  if (dx == 0) {
    if (dy < 0) {
      return -M_PI_2;
    }
    else if (dy > 0) {
      return M_PI_2;
    }
    else {
      return 0.0;
    }
  }
  else if (dx < 0) {
    return atan(dy / dx) - M_PI;
  }
  else {
    return atan(dy / dx);
  }
  return 0.0;
}


/*
 * Tell if an horizontal line intersect an axis aligned
 * elliptical arc.
 *
 * Returns True if the line described by (x1, x2, y) intersects
 * the arc described by (r1, r2, start_angle and angle_extent).
 * This arc is origin centered.
 */
ZnBool
ZnHorizLineToArc(ZnReal x1,
                 ZnReal x2,
                 ZnReal y,
                 ZnReal rx,
                 ZnReal ry,
                 int    start_angle,
                 int    angle_extent)
{
  ZnReal        tmp, x;
  ZnPoint       t;
  
  /*
   * Compute the x-coordinate of one possible intersection point
   * between the arc and the line.  Use a transformed coordinate
   * system where the oval is a unit circle centered at the origin.
   * Then scale back to get actual x-coordinate.
   */
  t.y = y/ry;
  tmp = 1 - t.y*t.y;
  if (tmp < 0.0) {
    return False;
  }
  t.x = sqrt(tmp);
  x = t.x*rx;
  
  /*
   * Test both intersection points.
   */  
  if ((x >= x1) && (x <= x2) && ZnPointInAngle((int) start_angle, (int) angle_extent, &t)) {
    return True;
  }
  t.x = -t.x;
  if ((-x >= x1) && (-x <= x2) && ZnPointInAngle((int) start_angle, (int) angle_extent, &t)) {
    return True;
  }
  return False;
}


/*
 * Tell if an vertical line intersect an axis aligned
 * elliptical arc.
 *
 * Returns True if the line described by (x1, x2, y) intersects
 * the arc described by (r1, r2, start_angle and angle_extent).
 * This arc is origin centered.
 */
ZnBool
ZnVertLineToArc(ZnReal  x,
                ZnReal  y1,
                ZnReal  y2,
                ZnReal  rx,
                ZnReal  ry,
                int     start_angle,
                int     angle_extent)
{
  ZnReal        tmp, y;
  ZnPoint       t;
  
  /*
   * Compute the y-coordinate of one possible intersection point
   * between the arc and the line.  Use a transformed coordinate
   * system where the oval is a unit circle centered at the origin.
   * Then scale back to get actual y-coordinate.
   */
  t.x = x/rx;
  tmp = 1 - t.x*t.x;
  if (tmp < 0.0) {
    return False;
  }
  t.y = sqrt(tmp);
  y = t.y*ry;

  /*
   * Test both intersection points.
   */
  if ((y > y1) && (y < y2) && ZnPointInAngle((int) start_angle, (int) angle_extent, &t)) {
    return True;
  }
  t.y = -t.y;
  if ((-y > y1) && (-y < y2) && ZnPointInAngle((int) start_angle, (int) angle_extent, &t)) {
    return True;
  }
  return False;
}


/*
 * Return the distance of the given point to the rectangle
 * described by rect. Return negative values for points in
 * the rectangle.
 */
ZnDim
ZnRectangleToPointDist(ZnBBox   *bbox,
                       ZnPoint  *p)
{
  ZnDim         new_dist, dist;
  ZnPoint       p1, p2;

  p1.x = bbox->orig.x;
  p1.y = p2.y = bbox->orig.y;
  p2.x = bbox->corner.x;
  dist = ZnLineToPointDist(&p1, &p2, p, NULL);
  if (dist == 0.0) {
    return 0.0;
  }

  p1 = p2;
  p2.y = bbox->corner.y;
  new_dist = ZnLineToPointDist(&p1, &p2, p, NULL);
  dist = MIN(dist, new_dist);
  if (dist == 0.0) {
    return 0.0;
  }

  p1 = p2;
  p2.x = bbox->orig.x;
  new_dist = ZnLineToPointDist(&p1, &p2, p, NULL);
  dist = MIN(dist, new_dist);
  if (dist == 0.0) {
    return 0.0;
  }
  
  p1 = p2;
  p2.y = bbox->orig.y;
  new_dist = ZnLineToPointDist(&p1, &p2, p, NULL);
  dist = MIN(dist, new_dist);

  if (ZnPointInBBox(bbox, p->x, p->y)) {
    return -dist;
  }
  else {
    return dist;
  }
}


/*
 * Return the distance of the given point to the line
 * described by <xl1,yl1>, <xl2,yl2>..
 */
ZnDim
ZnLineToPointDist(ZnPoint       *p1,
                  ZnPoint       *p2,
                  ZnPoint       *p,
                  ZnPoint       *closest)
{
  ZnReal        x, y;
  ZnReal        x_int, y_int;

  /*
   * First compute the closest point on the line. This is done
   * separately for vertical, horizontal, other lines.
   */

  /* Vertical */
  if (p1->x == p2->x) {
    x = p1->x;
    if (p1->y >= p2->y) {
      y_int = MIN(p1->y, p->y);
      y_int = MAX(y_int, p2->y);
    }
    else {
      y_int = MIN(p2->y, p->y);
      y_int = MAX(y_int, p1->y);
    }
    y = y_int;
  }

  /* Horizontal */
  else if (p1->y == p2->y) {
    y = p1->y;
    if (p1->x >= p2->x) {
      x_int = MIN(p1->x, p->x);
      x_int = MAX(x_int, p2->x);
    }
    else {
      x_int = MIN(p2->x, p->x);
      x_int = MAX(x_int, p1->x);
    }
    x = x_int;
  }

  /*
   * Other. Compute its parameters of form y = a1*x + b1 and
   * then compute the parameters of the perpendicular passing
   * through the point y = a2*x + b2, last find the closest point
   * on the segment.
   */
  else {
    ZnReal      a1, a2, b1, b2;

    a1 = (p2->y - p1->y) / (p2->x - p1->x);
    b1 = p1->y - a1*p1->x;

    a2 = -1.0/a1;
    b2 = p->y - a2*p->x;

    x = (b2 - b1) / (a1 - a2);
    y = a1*x + b1;

    if (p1->x > p2->x) {
      if (x > p1->x) {
        x = p1->x;
        y = p1->y;
      }
      else if (x < p2->x) {
        x = p2->x;
        y = p2->y;
      }
    }
    else {
      if (x > p2->x) {
        x = p2->x;
        y = p2->y;
      }
      else if (x < p1->x) {
        x = p1->x;
        y = p1->y;
      }
    }
  }
  
  if (closest) {
    closest->x = x;
    closest->y = y;
  }

  /* Return the distance */
  return hypot(p->x - x, p->y - y);
}


/*
 * Return the distance of the polygon described by
 * points, to the given point. If the point is
 * inside return values are negative.
 */
ZnDim
ZnPolygonToPointDist(ZnPoint            *points,
                     unsigned int       num_points,
                     ZnPoint            *p)
{
  ZnDim         best_distance, dist;
  int           intersections;
  int           x_int, y_int;
  ZnPoint       *first_point;
  ZnReal        x, y;
  ZnPoint       p1, p2;

  /*
   * The algorithm iterates through all the edges of the polygon
   * computing for each the distance to the point and whether a vertical
   * ray starting at the point, intersects the edge. The smallest
   * distance of all edges is stored in best_distance while intersections
   * hold the count of edges to rays intersections. For more informations
   * on how the distance is computed see LineToPointDist.
   */
  best_distance = 1.0e40;
  intersections = 0;

  first_point = points;

  /*
   * Check to see if closed. Adjust num_points to open it (the
   * algorithm always consider a set of points as a closed polygon).
   */
  if ((points[0].x == points[num_points-1].x) &&
      (points[0].y == points[num_points-1].y)) {
    num_points--;
  }

  for ( ; num_points >= 1; num_points--, points++) {
    p1 = points[0];
    /*
     * Wrap over to the first point.
     */
    if (num_points == 1) {
      p2 = *first_point;
    }
    else {
      p2 = points[1];
    }
    
    /*
     * First try to find the closest point on this edge.
     */

    /* Vertical edge */
    if (p1.x == p2.x) {
      x = p1.x;
      if (p1.y >= p2.y) {
        y_int = (int) MIN(p1.y, p->y);
        y_int = (int) MAX(y_int, p2.y);
      }
      else {
        y_int = (int) MIN(p2.y, p->y);
        y_int = (int) MAX(y_int, p1.y);
      }
      y = y_int;
    }

    /* Horizontal edge */
    else if (p1.y == p2.y) {
      y = p1.y;
      if (p1.x >= p2.x) {
        x_int = (int) MIN(p1.x, p->x);
        x_int = (int) MAX(x_int, p2.x);
        if ((p->y < y) && (p->x < p1.x) && (p->x >= p2.x)) {
          intersections++;
        }
      }
      else {
        x_int = (int) MIN(p2.x, p->x);
        x_int = (int) MAX(x_int, p1.x);
        if ((p->y < y) && (p->x < p2.x) && (p->x >= p1.x)) {
          intersections++;
        }
      }
      x = x_int;
    }

    /* Other */
    else {
      ZnReal    a1, b1, a2, b2;

      a1 = (p2.y - p1.y) / (p2.x - p1.x);
      b1 = p1.y - a1 * p1.x;

      a2 = -1.0/a1;
      b2 = p->y - a2 * p->x;

      x = (b2 - b1)/(a1 - a2);
      y = a1 * x + b1; 

      if (p1.x > p2.x) {
        if (x > p1.x) {
          x = p1.x;
          y = p1.y;
        }
        else if (x < p2.x) {
          x = p2.x;
          y = p2.y;
        }
      }
      else {
        if (x > p2.x) {
          x = p2.x;
          y = p2.y;
        }
        else if (x < p1.x) {
          x = p1.x;
          y = p1.y;
        }
      }

      if (((a1 * p->x + b1) > p->y) &&  /* True if point is lower */
          (p->x >= MIN(p1.x, p2.x)) &&
          (p->x < MAX(p1.x, p2.x))) {
        intersections++;
      }
    }

    /*
     * Now compute the distance to the closest point and
     * keep it if it is the shortest.
     */
    dist = hypot(p->x - x, p->y - y);
    best_distance = MIN(best_distance, dist);
    /*
     * We can safely escape here if distance is zero.
     */
    if (best_distance == 0.0) {
      return 0.0;
    }
  }

  /*
   * Well, all the edges are processed, if the
   * intersection count is odd the point is inside.
   */
  if (intersections & 0x1) {
    return -best_distance;
  }
  else {
    return best_distance;
  }
}


/*
 * Return the distance of a thick polyline to the
 * given point. Cap and Join parameters are considered
 * in the process.
 */
ZnDim
ZnPolylineToPointDist(ZnPoint           *points,
                      unsigned int      num_points,
                      ZnDim             width,
                      int               cap_style,
                      int               join_style,                
                      ZnPoint           *p)
{
  ZnBool        miter2bevel = False;
  unsigned int  count;
  ZnPoint       *ptr;
  ZnPoint       outline[5];
  ZnDim         dist, best_dist, h_width;

  best_dist = 1.0e36;
  h_width = width/2.0;

  for (count = num_points, ptr = points; count >= 2; count--, ptr++) {
    if (((cap_style == CapRound) && (count == num_points)) ||
        ((join_style == JoinRound) && (count != num_points))) {
      dist = hypot(ptr->x - p->x, ptr->y - p->y) - h_width;
      if (dist <= 0.0) {
        best_dist = 0.0;
        goto done;
      }
      else if (dist < best_dist) {
        best_dist = dist;
      }
    }
    /*
     * Build the polygonal outline of the current edge.
     */
    if (count == num_points) {
      ZnGetButtPoints(&ptr[1], ptr, width, cap_style==CapProjecting, outline, &outline[1]);
    }
    else if ((join_style == JoinMiter) && !miter2bevel) {
      outline[0] = outline[3];
      outline[1] = outline[2];
    }
    else {
      ZnGetButtPoints(&ptr[1], ptr, width, 0, outline, &outline[1]);
      /*
       * If joints are beveled, check the distance to the polygon
       * that fills the joint.
       */
      if ((join_style == JoinBevel) || miter2bevel) {
        outline[4] = outline[0];
        dist = ZnPolygonToPointDist(outline, 5, p);
        if (dist <= 0.0) {
          best_dist = 0.0;
          goto done;
        }
        else if (dist < best_dist) {
          best_dist = dist;
        }
        miter2bevel = False;
      }
    }
    if (count == 2) {
      ZnGetButtPoints(ptr, &ptr[1], width, cap_style==CapProjecting,
                      &outline[2], &outline[3]);
    }
    else if (join_style == JoinMiter) {
      if (ZnGetMiterPoints(ptr, &ptr[1], &ptr[2], width,
                         &outline[2], &outline[3]) == False) {
        miter2bevel = True;
        ZnGetButtPoints(ptr, &ptr[1], width, 0, &outline[2], &outline[3]);
      }
      /*printf("2=%g+%g, 3=%g+%g\n",
        outline[2].x, outline[2].y, outline[3].x, outline[3].y);*/
    }
    else {
      ZnGetButtPoints(ptr, &ptr[1], width, 0, &outline[2], &outline[3]);
    }
    outline[4] = outline[0];
    /*printf("0=%g+%g, 1=%g+%g, 2=%g+%g, 3=%g+%g, 4=%g+%g\n",
           outline[0].x, outline[0].y, outline[1].x, outline[1].y,
           outline[2].x, outline[2].y, outline[3].x, outline[3].y,
           outline[4].x, outline[4].y);*/
    dist = ZnPolygonToPointDist(outline, 5, p);
    if (dist <= 0.0) {
      best_dist = 0.0;
      goto done;
    }
    else if (dist < best_dist) {
      best_dist = dist;
    }
  }

  /*
   * Test the final point if cap style is round. The code so far
   * has only handled the butt and projecting cases.
   */
  if (cap_style == CapRound) {
    dist = hypot(ptr->x - p->x, ptr->y - p->y) - h_width;
    if (dist <= 0.0) {
      best_dist = 0.0;
      goto done;
    }
    else if (dist < best_dist) {
      best_dist = dist;
    }
  }
  
 done:
  return best_dist;
}


/*
 * Return the distance of the given oval to the point given.
 * The oval is described by its bounding box <xbb,ybb,wbb,hbb>,
 * the thickness of its outline <width>. Return values are negative
 * if the point is inside.
 */
ZnDim
ZnOvalToPointDist(ZnPoint       *center,
                  ZnDim         width,
                  ZnDim         height,
                  ZnDim         line_width,
                  ZnPoint       *p)
{
  ZnReal x_delta, y_delta;
  /*  ZnReal    x_diameter, y_diameter;*/
  ZnDim scaled_distance;
  ZnDim distance_to_outline;
  ZnDim distance_to_center;

  /*
   * Compute the distance from the point given to the center
   * of the oval. Then compute the same distance in a coordinate
   * system where the oval is a circle with unit radius.
   */

  x_delta = p->x - center->x;
  y_delta = p->y - center->y;
  distance_to_center = hypot(x_delta, y_delta);
  scaled_distance = hypot(x_delta / ((width + line_width) / 2.0),
                          y_delta / ((height + line_width) / 2.0));

  /*
   * If the scaled distance is greater than 1.0 the point is outside
   * the oval. Compute the distance to the edge and convert it back
   * to the original coordinate system. This distance is not much
   * accurate and can overestimate the real distance if the oval is
   * very eccentric.
   */
  if (scaled_distance > 1.0) {
    distance_to_outline = (distance_to_center / scaled_distance) * (scaled_distance - 1.0);
    return distance_to_outline;
  }

  /*
   * The point is inside the oval. Compute the distance as above and check
   * if the point is within the outline.
   */
  if (scaled_distance > 1.0e-10) {
    distance_to_outline = (distance_to_center / scaled_distance) * (1.0 - scaled_distance) - line_width;
  }
  else {
    /*
     * If the point is very close to the center avoid dividing by a
     * very small number, take another method.
     */
    if (width < height)
      distance_to_outline = (width - line_width) / 2;
    else
      distance_to_outline = (height - line_width) / 2;
  }

  if (distance_to_outline < 0.0)
    return 0.0;
  else
    return -distance_to_outline;
}


static int bezier_basis[][4] =
{
    {   -1,     3,     -3,      1},
    {    3,    -6,      3,      0},
    {   -3,     3,      0,      0},
    {    1,     0,      0,      0}
};

/*
 **********************************************************************************
 *
 * Arc2Param --
 *
 *      Given a Bezier curve describing an arc and an angle return the parameter
 *      value for the intersection point between the arc and the ray at angle.
 *
 **********************************************************************************
 */
#define EVAL(coeff, t) (((coeff[0]*t + coeff[1])*t + coeff[2]) * t + coeff[3])
static ZnReal
Arc2Param(ZnPoint       *controls,
          ZnReal        angle)
{
  ZnReal        coeff_x[4], coeff_y[4];
  ZnReal        min_angle, min_t, max_angle, max_t, cur_angle, cur_t;
  int           i, j, depth = 0;

  /* assume angle >= 0 */
  while (angle > M_PI) {
    angle -= 2 * M_PI;
  }

  for (i = 0; i < 4; i++) {
    coeff_x[i] = coeff_y[i] = 0.0;
    for (j = 0; j < 4; j++) {
      coeff_x[i] += bezier_basis[i][j] * controls[j].x;
      coeff_y[i] += bezier_basis[i][j] * controls[j].y;
    }
  }

  min_angle = atan2(controls[0].y, controls[0].x);
  max_angle = atan2(controls[3].y, controls[3].x);
  if (max_angle < min_angle) {
    min_angle -= M_PI+M_PI;
  }
  if (angle > max_angle) {
    angle -= M_PI+M_PI;
  }

  min_t = 0.0; max_t = 1.0;

  while (depth < 15) {
    cur_t = (max_t + min_t) / 2.0;
    cur_angle = atan2(EVAL(coeff_y, cur_t), EVAL(coeff_x, cur_t));
    if (angle > cur_angle) {
      min_t = cur_t;
      min_angle = cur_angle;
    }
    else {
      max_t = cur_t;
      max_angle = cur_angle;
    }
    depth += 1;
  }

  if ((max_angle-angle) < (angle-min_angle)) {
    return max_t;
  }

  return min_t;
}
#undef EVAL


/*
 **********************************************************************************
 *
 * BezierSubdivide --
 *
 *      Subdivide a Bezier curve given by controls at parameter t. Return
 *      in controls, the first or the last part depending on boolean first.
 *
 **********************************************************************************
 */
static void
BezierSubdivide(ZnPoint *controls,
                ZnReal  t,
                ZnBool  first)
{
  ZnReal        s = 1.0 - t;
  ZnPoint       r[7];
  ZnPoint       a;

  r[0] = controls[0];
  r[6] = controls[3];
  a.x = s*controls[1].x + t*controls[2].x;
  a.y = s*controls[1].y + t*controls[2].y;
  r[1].x = s*r[0].x + t*controls[1].x;
  r[1].y = s*r[0].y + t*controls[1].y;
  r[2].x = s*r[1].x + t*a.x;
  r[2].y = s*r[1].y + t*a.y;
  r[5].x = s*controls[2].x + t*r[6].x;
  r[5].y = s*controls[2].y + t*r[6].y;
  r[4].x = s*a.x + t*r[5].x;
  r[4].y = s*a.y + t*r[5].y;
  r[3].x = s*r[2].x + t*r[4].x;
  r[3].y = s*r[2].y + t*r[4].y;

  if (first) {
    memcpy(controls, r, 4*sizeof(ZnPoint));
  }
  else {
    memcpy(controls, &r[3], 4*sizeof(ZnPoint));
  }      
}


/*
 **********************************************************************************
 *
 * ZnGetBezierPoints --
 *      Use recursive subdivision to approximate the curve. The subdivision stops
 *      when the error is under eps.
 *      This algorithm is adaptive, meaning that it computes the minimum number
 *      of segments needed to render each curve part.
 *
 **********************************************************************************
 */
void
ZnGetBezierPoints(ZnPoint       *p1,
                  ZnPoint       *c1,
                  ZnPoint       *c2,
                  ZnPoint       *p2,
                  ZnList        to_points,
                  ZnReal        eps)
{
  ZnReal        dist;

  dist = ZnLineToPointDist(p1, p2, c1, NULL);
  if ((dist < eps) && ((c1->x != c2->x) || (c1->y != c2->y))) {
    dist = ZnLineToPointDist(p1, p2, c2, NULL);
  }

  if (dist > eps) {
    ZnPoint     mid_segm, new_c1, new_c2;
    /*
     * Subdivide the curve at t = 0.5
     * and compute each new curve.
     */
    mid_segm.x = (p1->x + 3*c1->x + 3*c2->x + p2->x) / 8.0;
    mid_segm.y = (p1->y + 3*c1->y + 3*c2->y + p2->y) / 8.0;
    new_c1.x = (p1->x + c1->x) / 2.0;
    new_c1.y = (p1->y + c1->y) / 2.0;
    new_c2.x = (p1->x + 2*c1->x + c2->x) / 4.0;
    new_c2.y = (p1->y + 2*c1->y + c2->y) / 4.0;
    ZnGetBezierPoints(p1, &new_c1, &new_c2, &mid_segm, to_points, eps);
    
    new_c1.x = (c1->x + 2*c2->x + p2->x) / 4.0;
    new_c1.y = (c1->y + 2*c2->y + p2->y) / 4.0;
    new_c2.x = (c2->x + (p2->x)) / 2.0;
    new_c2.y = (c2->y + (p2->y)) / 2.0;
    ZnGetBezierPoints(&mid_segm, &new_c1, &new_c2, p2, to_points, eps);
  }
  else {
    /*
     * Flat enough add the end to the current path.
     * The start should already be there.
     */
    ZnListAdd(to_points, p2, ZnListTail);
  }
}


/*
 **********************************************************************************
 *
 * ZnGetBezierPath --
 *      Compute in to_points a new set of points describing a Bezier path based
 *      on the control points given in from_points.
 *      If more than four points are given, the algorithm iterate over the
 *      set using the last point of a segment as the first point of the next.
 *      If 3 points are left, they are interpreted as a Bezier segment with
 *      coincident internal control points. If 2 points are left a straight
 *      is emitted.
 *
 **********************************************************************************
 */
void
ZnGetBezierPath(ZnList  from_points,
                ZnList  to_points)
{
  ZnPoint       *fp;
  int           num_fp, i;
  
  fp = ZnListArray(from_points);
  num_fp = ZnListSize(from_points);

  /*
   * make sure the output vector is empty, then add the first point.
   */
  ZnListEmpty(to_points);
  ZnListAdd(to_points, fp, ZnListTail);

  for (i = 0; i < num_fp; ) {
    if (i < (num_fp-3)) {
      ZnGetBezierPoints(fp, fp+1, fp+2, fp+3, to_points, 1.0);
      if (i < (num_fp-4)) {
        fp += 3;
        i += 3;
      }
      else {
        break;
      }
    }
    else if (i == (num_fp-3)) {
      ZnGetBezierPoints(fp, fp+1, fp+1, fp+2, to_points, 1.0);
      break;
    }
    else if (i == (num_fp-2)) {
      ZnListAdd(to_points, fp+1, ZnListTail);
      break;
    }
  }
}


/*
 **********************************************************************************
 *
 * ZnGetCirclePoints --
 *      Return a pointer to an array of points describing a
 *      circle arc of radius 1.0. The arc is described by start_angle,
 *      end_angle and the type: 0 for arc, 1 for chord, 2 for pie slice,
 *      3 for a full circle (in which case start_angle and end_angle are
 *      not used.
 *      The number of points is returned in num_points. If type is not 3,
 *      point_list must not be NULL. If not NULL, it is filled with the
 *      computed points.
 *
 **********************************************************************************
 */
ZnPoint *
ZnGetCirclePoints(int           type,
                  int           quality,
                  ZnReal        start_angle,
                  ZnReal        angle_extent,
                  unsigned int  *num_points,
                  ZnList        point_list)
{
  static ZnPoint genarc_finest[] = { /* 128 */
    {1.0, 0.0},
    {0.99879545617, 0.0490676750517},
    {0.99518472653, 0.0980171417729},
    {0.989176509646, 0.146730476607},
    {0.980785279837, 0.195090324861},
    {0.970031252314, 0.24298018342},
    {0.956940334469, 0.290284681418},
    {0.941544063473, 0.336889858172},
    {0.923879530291, 0.382683437725},
    {0.903989290333, 0.42755509933},
    {0.88192126093, 0.471396743221},
    {0.857728605899, 0.514102751035},
    {0.831469607468, 0.555570240255},
    {0.803207525865, 0.595699312064},
    {0.773010446922, 0.634393292011},
    {0.74095111805, 0.671558962907},
    {0.707106772982, 0.707106789391},
    {0.671558945713, 0.740951133634},
    {0.634393274074, 0.773010461643},
    {0.595699293426, 0.803207539688},
    {0.555570220961, 0.83146962036},
    {0.514102731131, 0.857728617829},
    {0.471396722756, 0.881921271869},
    {0.427555078353, 0.903989300254},
    {0.382683416286, 0.923879539171},
    {0.336889836323, 0.94154407129},
    {0.290284659212, 0.956940341205},
    {0.242980160911, 0.970031257952},
    {0.195090302102, 0.980785284364},
    {0.146730453653, 0.98917651305},
    {0.0980171186795, 0.995184728805},
    {0.0490676518746, 0.998795457308},
    {-2.32051033331e-08, 1.0},
    {-0.0490676982289, 0.998795455031},
    {-0.0980171648663, 0.995184724256},
    {-0.146730499561, 0.989176506241},
    {-0.19509034762, 0.98078527531},
    {-0.24298020593, 0.970031246675},
    {-0.290284703624, 0.956940327733},
    {-0.33688988002, 0.941544055655},
    {-0.382683459163, 0.923879521411},
    {-0.427555120307, 0.903989280412},
    {-0.471396763686, 0.881921249991},
    {-0.514102770939, 0.85772859397},
    {-0.555570259549, 0.831469594576},
    {-0.595699330703, 0.803207512042},
    {-0.634393309949, 0.773010432201},
    {-0.6715589801, 0.740951102467},
    {-0.707106805799, 0.707106756574},
    {-0.740951149217, 0.671558928519},
    {-0.773010476365, 0.634393256136},
    {-0.803207553511, 0.595699274787},
    {-0.831469633252, 0.555570201666},
    {-0.857728629759, 0.514102711228},
    {-0.881921282808, 0.471396702291},
    {-0.903989310176, 0.427555057376},
    {-0.923879548052, 0.382683394847},
    {-0.941544079108, 0.336889814474},
    {-0.956940347941, 0.290284637006},
    {-0.97003126359, 0.242980138401},
    {-0.980785288892, 0.195090279343},
    {-0.989176516455, 0.146730430699},
    {-0.995184731079, 0.0980170955862},
    {-0.998795458447, 0.0490676286974},
    {-1.0, -4.64102066663e-08},
    {-0.998795453892, -0.049067721406},
    {-0.995184721981, -0.0980171879596},
    {-0.989176502836, -0.146730522515},
    {-0.980785270783, -0.195090370379},
    {-0.970031241037, -0.24298022844},
    {-0.956940320997, -0.29028472583},
    {-0.941544047838, -0.336889901869},
    {-0.923879512531, -0.382683480602},
    {-0.90398927049, -0.427555141284},
    {-0.881921239052, -0.471396784151},
    {-0.85772858204, -0.514102790842},
    {-0.831469581684, -0.555570278844},
    {-0.803207498218, -0.595699349341},
    {-0.77301041748, -0.634393327887},
    {-0.740951086883, -0.671558997294},
    {-0.707106740165, -0.707106822208},
    {-0.671558911325, -0.740951164801},
    {-0.634393238198, -0.773010491086},
    {-0.595699256149, -0.803207567335},
    {-0.555570182372, -0.831469646144},
    {-0.514102691324, -0.857728641689},
    {-0.471396681826, -0.881921293746},
    {-0.427555036399, -0.903989320097},
    {-0.382683373409, -0.923879556932},
    {-0.336889792626, -0.941544086926},
    {-0.2902846148, -0.956940354677},
    {-0.242980115891, -0.970031269229},
    {-0.195090256583, -0.980785293419},
    {-0.146730407745, -0.98917651986},
    {-0.0980170724928, -0.995184733354},
    {-0.0490676055202, -0.998795459585},
    {6.96153097774e-08, -1.0},
    {0.0490677445832, -0.998795452754},
    {0.098017211053, -0.995184719707},
    {0.146730545469, -0.989176499431},
    {0.195090393139, -0.980785266256},
    {0.242980250949, -0.970031235398},
    {0.290284748036, -0.956940314261},
    {0.336889923717, -0.94154404002},
    {0.382683502041, -0.923879503651},
    {0.427555162262, -0.903989260569},
    {0.471396804617, -0.881921228114},
    {0.514102810746, -0.85772857011},
    {0.555570298138, -0.831469568792},
    {0.59569936798, -0.803207484395},
    {0.634393345825, -0.773010402759},
    {0.671559014488, -0.740951071299},
    {0.707106838616, -0.707106723757},
    {0.740951180385, -0.671558894131},
    {0.773010505807, -0.63439322026},
    {0.803207581158, -0.59569923751},
    {0.831469659036, -0.555570163078},
    {0.857728653619, -0.51410267142},
    {0.881921304685, -0.471396661361},
    {0.903989330019, -0.427555015421},
    {0.923879565812, -0.38268335197},
    {0.941544094743, -0.336889770777},
    {0.956940361414, -0.290284592594},
    {0.970031274867, -0.242980093382},
    {0.980785297946, -0.195090233824},
    {0.989176523265, -0.146730384792},
    {0.995184735628, -0.0980170493994},
    {0.998795460724, -0.0490675823431},
    {1.0, 0.0}
  };
  static ZnPoint genarc_finer[] = { /* 64 */
    {1.0, 0.0},
    {0.99518472653, 0.0980171417729},
    {0.980785279837, 0.195090324861},
    {0.956940334469, 0.290284681418},
    {0.923879530291, 0.382683437725},
    {0.88192126093, 0.471396743221},
    {0.831469607468, 0.555570240255},
    {0.773010446922, 0.634393292011},
    {0.707106772982, 0.707106789391},
    {0.634393274074, 0.773010461643},
    {0.555570220961, 0.83146962036},
    {0.471396722756, 0.881921271869},
    {0.382683416286, 0.923879539171},
    {0.290284659212, 0.956940341205},
    {0.195090302102, 0.980785284364},
    {0.0980171186795, 0.995184728805},
    {-2.32051033331e-08, 1.0},
    {-0.0980171648663, 0.995184724256},
    {-0.19509034762, 0.98078527531},
    {-0.290284703624, 0.956940327733},
    {-0.382683459163, 0.923879521411},
    {-0.471396763686, 0.881921249991},
    {-0.555570259549, 0.831469594576},
    {-0.634393309949, 0.773010432201},
    {-0.707106805799, 0.707106756574},
    {-0.773010476365, 0.634393256136},
    {-0.831469633252, 0.555570201666},
    {-0.881921282808, 0.471396702291},
    {-0.923879548052, 0.382683394847},
    {-0.956940347941, 0.290284637006},
    {-0.980785288892, 0.195090279343},
    {-0.995184731079, 0.0980170955862},
    {-1.0, -4.64102066663e-08},
    {-0.995184721981, -0.0980171879596},
    {-0.980785270783, -0.195090370379},
    {-0.956940320997, -0.29028472583},
    {-0.923879512531, -0.382683480602},
    {-0.881921239052, -0.471396784151},
    {-0.831469581684, -0.555570278844},
    {-0.77301041748, -0.634393327887},
    {-0.707106740165, -0.707106822208},
    {-0.634393238198, -0.773010491086},
    {-0.555570182372, -0.831469646144},
    {-0.471396681826, -0.881921293746},
    {-0.382683373409, -0.923879556932},
    {-0.2902846148, -0.956940354677},
    {-0.195090256583, -0.980785293419},
    {-0.0980170724928, -0.995184733354},
    {6.96153097774e-08, -1.0},
    {0.098017211053, -0.995184719707},
    {0.195090393139, -0.980785266256},
    {0.290284748036, -0.956940314261},
    {0.382683502041, -0.923879503651},
    {0.471396804617, -0.881921228114},
    {0.555570298138, -0.831469568792},
    {0.634393345825, -0.773010402759},
    {0.707106838616, -0.707106723757},
    {0.773010505807, -0.63439322026},
    {0.831469659036, -0.555570163078},
    {0.881921304685, -0.471396661361},
    {0.923879565812, -0.38268335197},
    {0.956940361414, -0.290284592594},
    {0.980785297946, -0.195090233824},
    {0.995184735628, -0.0980170493994},
    {1.0, 0.0}
  };
  static ZnPoint genarc_fine[] = { /* 40 */
    {1.0, 0.0},
    {0.987688340232, 0.156434467332},
    {0.951056514861, 0.309016998789},
    {0.891006521028, 0.453990505942},
    {0.809016988919, 0.587785259802},
    {0.707106772982, 0.707106789391},
    {0.587785241028, 0.809017002559},
    {0.453990485266, 0.891006531563},
    {0.309016976719, 0.951056522032},
    {0.156434444413, 0.987688343862},
    {-2.32051033331e-08, 1.0},
    {-0.156434490252, 0.987688336602},
    {-0.309017020858, 0.95105650769},
    {-0.453990526618, 0.891006510493},
    {-0.587785278575, 0.809016975279},
    {-0.707106805799, 0.707106756574},
    {-0.809017016198, 0.587785222255},
    {-0.891006542098, 0.453990464591},
    {-0.951056529203, 0.30901695465},
    {-0.987688347492, 0.156434421493},
    {-1.0, -4.64102066663e-08},
    {-0.987688332972, -0.156434513171},
    {-0.951056500519, -0.309017042928},
    {-0.891006499958, -0.453990547294},
    {-0.80901696164, -0.587785297348},
    {-0.707106740165, -0.707106822208},
    {-0.587785203482, -0.809017029838},
    {-0.453990443915, -0.891006552633},
    {-0.309016932581, -0.951056536373},
    {-0.156434398574, -0.987688351122},
    {6.96153097774e-08, -1.0},
    {0.15643453609, -0.987688329342},
    {0.309017064997, -0.951056493349},
    {0.45399056797, -0.891006489423},
    {0.587785316122, -0.809016948},
    {0.707106838616, -0.707106723757},
    {0.809017043478, -0.587785184709},
    {0.891006563167, -0.453990423239},
    {0.951056543544, -0.309016910511},
    {0.987688354752, -0.156434375655},
    {1.0, 0.0}
  };  
  static ZnPoint genarc_medium[] = { /* 20 */
    {1.0, 0.0},
    {0.951056514861, 0.309016998789},
    {0.809016988919, 0.587785259802},
    {0.587785241028, 0.809017002559},
    {0.309016976719, 0.951056522032},
    {-2.32051033331e-08, 1.0},
    {-0.309017020858, 0.95105650769},
    {-0.587785278575, 0.809016975279},
    {-0.809017016198, 0.587785222255},
    {-0.951056529203, 0.30901695465},
    {-1.0, -4.64102066663e-08},
    {-0.951056500519, -0.309017042928},
    {-0.80901696164, -0.587785297348},
    {-0.587785203482, -0.809017029838},
    {-0.309016932581, -0.951056536373},
    {6.96153097774e-08, -1.0},
    {0.309017064997, -0.951056493349},
    {0.587785316122, -0.809016948},
    {0.809017043478, -0.587785184709},
    {0.951056543544, -0.309016910511},
    {1.0, 0.0}
  };
  static ZnPoint genarc_coarse[] = { /* 10 */
    {1.0, 0.0},
    {0.809016988919, 0.587785259802},
    {0.309016976719, 0.951056522032},
    {-0.309017020858, 0.95105650769},
    {-0.809017016198, 0.587785222255},
    {-1.0, -4.64102066663e-08},
    {-0.80901696164, -0.587785297348},
    {-0.309016932581, -0.951056536373},
    {0.309017064997, -0.951056493349},
    {0.809017043478, -0.587785184709},
    {1.0, 0.0}
  };
  unsigned int  num_p, i;
  ZnPoint       *p, *p_from;
  ZnPoint       center_p = { 0.0, 0.0 };
  ZnPoint       start_p, wp;
  ZnReal        iangle, end_angle=0;

  switch (quality) {
  case ZN_CIRCLE_COARSE:
    num_p = sizeof(genarc_coarse)/sizeof(ZnPoint);
    p = p_from = genarc_coarse;
    break;
  case ZN_CIRCLE_MEDIUM:
    num_p = sizeof(genarc_medium)/sizeof(ZnPoint);
    p = p_from = genarc_medium;
    break;
  case ZN_CIRCLE_FINER:
    num_p = sizeof(genarc_finer)/sizeof(ZnPoint);
    p = p_from = genarc_finer;
    break;
  case ZN_CIRCLE_FINEST:
    num_p = sizeof(genarc_finest)/sizeof(ZnPoint);
    p = p_from = genarc_finest;
    break;
  default:
  case ZN_CIRCLE_FINE:
    num_p = sizeof(genarc_fine)/sizeof(ZnPoint);
    p = p_from = genarc_fine;
  }
  
  /*printf("start: %g, extent: %g\n", start_angle, angle_extent);*/
  if (angle_extent == 2*M_PI) {
    type = 3;
  }
  if (type != 3) {
    end_angle = start_angle+angle_extent;
    if (angle_extent < 0) {
      iangle = start_angle;
      start_angle = end_angle;
      end_angle = iangle;
    }
    /*
     * normalize start_angle and end_angle.
     */
    if (start_angle < 0.0) {
      start_angle += 2.0*M_PI;
    }
    if (end_angle < 0.0) {
      end_angle += 2.0*M_PI;
    }
    if (end_angle < start_angle) {
      end_angle += 2.0*M_PI;
    }
    /*printf("---start: %g, end: %g\n", start_angle, end_angle);*/
  }
  
  /*
   * Now 0 <= start_angle < 2 * M_PI and start_angle <= end_angle.
   */
  if ((type != 3) || (point_list != NULL)) {
    if (type == 3) {
      ZnListAssertSize(point_list, num_p);
      p = ZnListArray(point_list);
      for (i = 0; i < num_p; i++, p++, p_from++) {
        *p = *p_from;
      }
    }
    else {
      ZnListEmpty(point_list);
      iangle = 2*M_PI / (num_p-1);
      start_p.x = cos(start_angle);
      start_p.y = sin(start_angle);
      ZnListAdd(point_list, &start_p, ZnListTail);
      i = (unsigned int) (start_angle / iangle);
      if ((i * iangle) < start_angle) {
        i++;
      }
      while (1) {
        if (start_angle + iangle <= end_angle) {
          if (i == num_p-1) {
            i = 0;
          }
          ZnListAdd(point_list, &p_from[i], ZnListTail);
          start_angle += iangle;
          i++;
        }
        else {
          wp.x = cos(end_angle);
          wp.y = sin(end_angle);
          ZnListAdd(point_list, &wp, ZnListTail);
          break;
        }
      }
      if (type == 1) {
        ZnListAdd(point_list, &start_p, ZnListTail);
      }
      else if (type == 2) {
        ZnListAdd(point_list, &center_p, ZnListTail);
        ZnListAdd(point_list, &start_p, ZnListTail);
      }
    }
    p = ZnListArray(point_list);
    num_p = ZnListSize(point_list);
  }
  
  *num_points = num_p;
  return p;
}

/*
 **********************************************************************************
 *
 * ZnGetArcPath --
 *      Compute in to_points a set of Bezier control points describing an arc
 *      path given the start angle, the stop angle and the type: 0 for arc,
 *      1 for chord, 2 for pie slice.
 *      To obtain the actual polygonal shape, the client should use GetBezierPath
 *      on the returned controls (after applying transform). The returned arc
 *      is circular and centered on 0,0.
 *
 **********************************************************************************
 */
static ZnReal arc_nodes_x[4] = { 1.0, 0.0, -1.0, 0.0 };
static ZnReal arc_nodes_y[4] = { 0.0, 1.0,  0.0, -1.0 };
static ZnReal arc_controls_x[8] = { 1.0, 0.55197, -0.55197, -1.0, -1.0, -0.55197, 0.55197, 1.0 };
static ZnReal arc_controls_y[8] = { 0.55197, 1.0, 1.0, 0.55197, -0.55197, -1.0, -1.0, -0.55197 };
void
ZnGetArcPath(ZnReal     start_angle,
             ZnReal     end_angle,
             int        type,
             ZnList     to_points)
{
  int           start_quad, end_quad, quadrant;
  ZnPoint       center_p = { 0.0, 0.0 };
  ZnPoint       start_p = center_p;
  
  /*
   * make sure the output vector is empty.
   */
  ZnListEmpty(to_points);
  
  /*
   * normalize start_angle and end_angle.
   */
  start_angle = fmod(start_angle, 2.0*M_PI);
  if (start_angle < 0.0) {
    start_angle += 2.0*M_PI;
  }
  end_angle = fmod(end_angle, 2.0*M_PI);
  if (end_angle < 0.0) {
    end_angle += 2.0*M_PI;
  }
  if (start_angle >= end_angle) {
    if (start_angle == end_angle) {
      type = 3;
    }
    end_angle += 2.0*M_PI;
  }
  
  /*
   * Now 0 <= start_angle < 2 * M_PI and start_angle <= end_angle.
   */

  start_quad = (int) (start_angle / (M_PI / 2.0));
  end_quad = (int) (end_angle / (M_PI / 2.0));

  for (quadrant = start_quad; quadrant <= end_quad; quadrant++) {
    ZnPoint controls[4];
    ZnReal  t;
    
    controls[0].x = arc_nodes_x[quadrant % 4];
    controls[0].y = arc_nodes_y[quadrant % 4];
    controls[1].x = arc_controls_x[2 * (quadrant % 4)];
    controls[1].y = arc_controls_y[2 * (quadrant % 4)];
    controls[2].x = arc_controls_x[2 * (quadrant % 4) + 1];
    controls[2].y = arc_controls_y[2 * (quadrant % 4) + 1];
    controls[3].x = arc_nodes_x[(quadrant + 1) % 4];
    controls[3].y = arc_nodes_y[(quadrant + 1) % 4];
    
    if (quadrant == start_quad) {
      t = Arc2Param(controls, start_angle);
      BezierSubdivide(controls, t, False);
      /*
       * The path is still empty and we have to create the first
       * vertex.
       */
      start_p = controls[0];
      ZnListAdd(to_points, &controls[0], ZnListTail);
    }
    if (quadrant == end_quad) {
      t = Arc2Param(controls, end_angle);
      if (!t) {
        break;
      }
      BezierSubdivide(controls, t, True);
    }
    ZnListAdd(to_points, &controls[1], ZnListTail);
    ZnListAdd(to_points, &controls[2], ZnListTail);
    ZnListAdd(to_points, &controls[3], ZnListTail);
  }

  if (type == 2) {
    ZnListAdd(to_points, &center_p, ZnListTail);
    /*
     * Can't add this one, it would be interpreted by GetBezierPath
     * as an off-curve control. The path should be closed by the client
     * after expansion by GetBezierPath.
     *
      ZnListAdd(to_points, &start_p, ZnListTail); 
     */
  }
  else if (type == 1) {
    ZnListAdd(to_points, &start_p, ZnListTail); 
  }
}


/*
 **********************************************************************************
 *
 * SmoothPathWithBezier --
 *      Compute in to_points a new set of points describing a smoothed path based
 *      on the path given in from_points. The algorithm use Bezier cubic curves.
 *
 **********************************************************************************
 */
void
ZnSmoothPathWithBezier(ZnPoint          *fp,
                       unsigned int     num_fp,
                       ZnList           to_points)
{
  ZnBool        closed;
  ZnPoint       s[4];
  unsigned int  i;

  /*
   * make sure the output vector is empty
   */
  ZnListEmpty(to_points);

  /*
   * If the curve is closed, generates a Bezier curve that
   * spans the closure. Else simply add the first point to
   * the path.
   */
  if ((fp[0].x == fp[num_fp-1].x) && (fp[0].y == fp[num_fp-1].y)) {
    closed = True;
    s[0].x = 0.5*fp[num_fp-2].x + 0.5*fp[0].x;
    s[0].y = 0.5*fp[num_fp-2].y + 0.5*fp[0].y;
    s[1].x = 0.167*fp[num_fp-2].x + 0.833*fp[0].x;
    s[1].y = 0.167*fp[num_fp-2].y + 0.833*fp[0].y;
    s[2].x = 0.833*fp[0].x + 0.167*fp[1].x;
    s[2].y = 0.833*fp[0].y + 0.167*fp[1].y;
    s[3].x = 0.5*fp[0].x + 0.5*fp[1].x;
    s[3].y = 0.5*fp[0].y + 0.5*fp[1].y;
    ZnListAdd(to_points, s, ZnListTail);
    ZnGetBezierPoints(s, s+1, s+2, s+3, to_points, 1.0);
  }
  else {
    closed = False;
    ZnListAdd(to_points, &fp[0], ZnListTail);
  }

  for (i = 2; i < num_fp; i++, fp++) {
    /*
     * Setup the first two control points. This differ
     * for first segment of open curves.
     */
    if ((i == 2) && !closed) {
      s[0] = fp[0];
      s[1].x = 0.333*fp[0].x + 0.667*fp[1].x;
      s[1].y = 0.333*fp[0].y + 0.667*fp[1].y;
    }
    else {
      s[0].x = 0.5*fp[0].x + 0.5*fp[1].x;
      s[0].y = 0.5*fp[0].y + 0.5*fp[1].y;
      s[1].x = 0.167*fp[0].x + 0.833*fp[1].x;
      s[1].y = 0.167*fp[0].y + 0.833*fp[1].y;
    }

    /*
     * Setup the last two control points. This also differ
     * for last segment of open curves.
     */
    if ((i == num_fp-1) && !closed) {
      s[2].x = 0.667*fp[1].x + 0.333*fp[2].x;
      s[2].y = 0.667*fp[1].y + 0.333*fp[2].y;
      s[3] = fp[2];
    }
    else {
      s[2].x = 0.833*fp[1].x + 0.167*fp[2].x;
      s[2].y = 0.833*fp[1].y + 0.167*fp[2].y;
      s[3].x = 0.5*fp[1].x + 0.5*fp[2].x;
      s[3].y = 0.5*fp[1].y + 0.5*fp[2].y;
    }

    /*
     * If the first two points or the last two are equal
     * output the last control point. Else generate the
     * Bezier curve.
     */
    if (((fp[0].x == fp[1].x) && (fp[0].y == fp[1].y)) ||
        ((fp[1].x == fp[2].x) && (fp[1].y == fp[2].y))) {
      ZnListAdd(to_points, &s[3], ZnListTail);
    }
    else {
      ZnGetBezierPoints(s, s+1, s+2, s+3, to_points, 1.0);
    }
  }
}


/*
 **********************************************************************************
 *
 * FitBezier --
 *      Fit a Bezier curve to a (sub)set of digitized points.
 *
 *      From: An Algorithm for Automatically Fitting Digitized Curves
 *            by Philip J. Schneider in "Graphics Gems", Academic Press, 1990
 *
 **********************************************************************************
 */

static ZnReal
V2DistanceBetween2Points(ZnPoint        *a,
                         ZnPoint        *b)
{
  ZnReal dx = a->x - b->x;
  ZnReal dy = a->y - b->y;
  return sqrt((dx*dx)+(dy*dy));
}

static ZnReal
V2SquaredLength(ZnPoint *a)
{       
  return (a->x * a->x)+(a->y * a->y);
}

static ZnReal
V2Length(ZnPoint        *a)
{
  return sqrt(V2SquaredLength(a));
}
        
static ZnPoint *
V2Scale(ZnPoint *v,
        ZnReal  newlen)
{
  ZnReal len = V2Length(v);
  if (len != 0.0) {
    v->x *= newlen/len;
    v->y *= newlen/len;
  }
  return v;
}

static ZnPoint *
V2Negate(ZnPoint *v)
{
  v->x = -v->x;  v->y = -v->y;
  return v;
}

static ZnPoint *
V2Normalize(ZnPoint *v)
{
  ZnReal len = sqrt(V2Length(v));
  if (len != 0.0) {
    v->x /= len;
    v->y /= len;
  }
  return v;
}
static ZnPoint *
V2Add(ZnPoint   *a,
      ZnPoint   *b,
      ZnPoint   *c)
{
  c->x = a->x + b->x;
  c->y = a->y + b->y;
  return c;
}
        
static ZnReal
V2Dot(ZnPoint   *a,
      ZnPoint   *b) 
{
  return (a->x*b->x) + (a->y*b->y);
}

static ZnPoint
V2AddII(ZnPoint a,
        ZnPoint b)
{
  ZnPoint c;
  c.x = a.x + b.x;
  c.y = a.y + b.y;
  return c;
}

static ZnPoint
V2ScaleIII(ZnPoint      v,
           ZnReal       s)
{
  ZnPoint result;
  result.x = v.x * s;
  result.y = v.y * s;
  return result;
}

static ZnPoint
V2SubII(ZnPoint a,
        ZnPoint b)
{
  ZnPoint c;
  c.x = a.x - b.x;
  c.y = a.y - b.y;
  return c;
}

/*
 * B0, B1, B2, B3, Bezier multipliers.
 */
static ZnReal
B0(ZnReal       u)
{
  ZnReal tmp = 1.0 - u;
  return tmp * tmp * tmp;
}

static ZnReal
B1(ZnReal       u)
{
  ZnReal tmp = 1.0 - u;
  return 3 * u * (tmp * tmp);
}

static ZnReal
B2(ZnReal       u)
{
  ZnReal tmp = 1.0 - u;
  return 3 * u * u * tmp;
}

static ZnReal
B3(ZnReal       u)
{
  return u * u * u;
}

/*
 * ChordLengthParameterize  --
 *      Assign parameter values to digitized points 
 *      using relative distances between points.
 */
static ZnReal *
ChordLengthParameterize(ZnPoint         *d,
                        unsigned int    first,
                        unsigned int    last)
{
  unsigned int  i;
  ZnReal        *u;

  u = (ZnReal *) ZnMalloc((unsigned) (last-first+1) * sizeof(ZnReal));
  
  u[0] = 0.0;
  for (i = first+1; i <= last; i++) {
    u[i-first] = u[i-first-1] + V2DistanceBetween2Points(&d[i], &d[i-1]);
  }
  
  for (i = first + 1; i <= last; i++) {
    u[i-first] = u[i-first] / u[last-first];
  }
  
  return u;
}

/*
 * Bezier --
 *      Evaluate a Bezier curve at a particular parameter value
 * 
 */
static ZnPoint
BezierII(int            degree,
         ZnPoint        *V,
         ZnReal         t)
{
  int           i, j;           
  ZnPoint       Q;              /* Point on curve at parameter t        */
  ZnPoint       *Vtemp;         /* Local copy of control points         */
  
  /* Copy array */
  Vtemp = (ZnPoint *) ZnMalloc((unsigned)((degree+1) * sizeof (ZnPoint)));
  for (i = 0; i <= degree; i++) {
    Vtemp[i] = V[i];
  }
  
  /* Triangle computation */
  for (i = 1; i <= degree; i++) {       
    for (j = 0; j <= degree-i; j++) {
      Vtemp[j].x = (1.0 - t) * Vtemp[j].x + t * Vtemp[j+1].x;
      Vtemp[j].y = (1.0 - t) * Vtemp[j].y + t * Vtemp[j+1].y;
    }
  }
  
  Q = Vtemp[0];
  ZnFree(Vtemp);
  return Q;
}

/*
 * NewtonRaphsonRootFind --
 *      Use Newton-Raphson iteration to find better root.
 */
static ZnReal
NewtonRaphsonRootFind(ZnPoint   *Q,
                      ZnPoint   P,
                      ZnReal    u)
{
  ZnReal        numerator, denominator;
  ZnPoint       Q1[3], Q2[2];           /*  Q' and Q''                  */
  ZnPoint       Q_u, Q1_u, Q2_u;        /*u evaluated at Q, Q', & Q''   */
  ZnReal        uPrime;                 /*  Improved u                  */
  unsigned int  i;
    
  /* Compute Q(u)       */
  Q_u = BezierII(3, Q, u);
    
  /* Generate control vertices for Q'   */
  for (i = 0; i <= 2; i++) {
    Q1[i].x = (Q[i+1].x - Q[i].x) * 3.0;
    Q1[i].y = (Q[i+1].y - Q[i].y) * 3.0;
  }
    
  /* Generate control vertices for Q'' */
  for (i = 0; i <= 1; i++) {
    Q2[i].x = (Q1[i+1].x - Q1[i].x) * 2.0;
    Q2[i].y = (Q1[i+1].y - Q1[i].y) * 2.0;
  }
  
  /* Compute Q'(u) and Q''(u)   */
  Q1_u = BezierII(2, Q1, u);
  Q2_u = BezierII(1, Q2, u);
    
  /* Compute f(u)/f'(u) */
  numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y);
  denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) +
                (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y);
    
  /* u = u - f(u)/f'(u) */
  uPrime = u - (numerator/denominator);
  return (uPrime);
}

/*
 * Reparameterize --
 *      Given set of points and their parameterization, try to find
 *      a better parameterization.
 */
static ZnReal *
Reparameterize(ZnPoint          *d,
               unsigned int     first,
               unsigned int     last, 
               ZnReal           *u,
               ZnPoint          *bezCurve)
{
  unsigned int  nPts = last-first+1;    
  unsigned int  i;
  ZnReal        *uPrime;        /*  New parameter values        */

  uPrime = (ZnReal *) ZnMalloc(nPts * sizeof(ZnReal));
  for (i = first; i <= last; i++) {
    uPrime[i-first] = NewtonRaphsonRootFind(bezCurve, d[i], u[i-first]);
  }
  return (uPrime);
}

/*
 * GenerateBezier --
 *      Use least-squares method to find Bezier control
 *      points for region.
 */
static void
GenerateBezier(ZnPoint          *d,
               unsigned int     first,
               unsigned int     last, 
               ZnReal           *uPrime, 
               ZnPoint          tHat1,
               ZnPoint          tHat2,
               ZnPoint          *bez_curve)
{
  unsigned int  i;
  ZnPoint       *A0, *A1;       /* Precomputed rhs for eqn      */
  unsigned int  num_points;     /* Number of pts in sub-curve */
  ZnReal        C[2][2];        /* Matrix C             */
  ZnReal        X[2];           /* Matrix X                     */
  ZnReal        det_C0_C1;      /* Determinants of matrices     */
  ZnReal        det_C0_X, det_X_C1;
  ZnReal        alpha_l;        /* Alpha values, left and right */
  ZnReal        alpha_r;
  ZnPoint       tmp;            /* Utility variable             */
  
  num_points = last - first + 1;
  A0 = (ZnPoint *) ZnMalloc(num_points * sizeof(ZnPoint));
  A1 = (ZnPoint *) ZnMalloc(num_points * sizeof(ZnPoint));
  
  /* Compute the A's    */
  for (i = 0; i < num_points; i++) {
    ZnPoint     v1, v2;
    v1 = tHat1;
    v2 = tHat2;
    V2Scale(&v1, B1(uPrime[i]));
    V2Scale(&v2, B2(uPrime[i]));
    A0[i] = v1;
    A1[i] = v2;
  }

  /* Create the C and X matrices        */
  C[0][0] = 0.0;
  C[0][1] = 0.0;
  C[1][0] = 0.0;
  C[1][1] = 0.0;
  X[0]    = 0.0;
  X[1]    = 0.0;

  for (i = 0; i < num_points; i++) {
    C[0][0] += V2Dot(&A0[i], &A0[i]);
    C[0][1] += V2Dot(&A0[i], &A1[i]);
    C[1][0] = C[0][1];
    C[1][1] += V2Dot(&A1[i], &A1[i]);

    tmp = V2SubII(d[first + i],
                  V2AddII(V2ScaleIII(d[first], B0(uPrime[i])),
                          V2AddII(V2ScaleIII(d[first], B1(uPrime[i])),
                                  V2AddII(V2ScaleIII(d[last], B2(uPrime[i])),
                                          V2ScaleIII(d[last], B3(uPrime[i]))))));

    X[0] += V2Dot(&A0[i], &tmp);
    X[1] += V2Dot(&A1[i], &tmp);
  }

  /* Compute the determinants of C and X        */
  det_C0_C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1];
  det_C0_X  = C[0][0] * X[1]    - C[0][1] * X[0];
  det_X_C1  = X[0]    * C[1][1] - X[1]    * C[0][1];

  /* Finally, derive alpha values       */
  if (det_C0_C1 == 0.0) {
    det_C0_C1 = (C[0][0] * C[1][1]) * 10e-12;
  }
  alpha_l = det_X_C1 / det_C0_C1;
  alpha_r = det_C0_X / det_C0_C1;

  /*  If alpha negative, use the Wu/Barsky heuristic (see text) */
  if (alpha_l < 0.0 || alpha_r < 0.0) {
    ZnReal dist = V2DistanceBetween2Points(&d[last], &d[first]) / 3.0;
    
    bez_curve[0] = d[first];
    bez_curve[3] = d[last];
    V2Add(&bez_curve[0], V2Scale(&tHat1, dist), &bez_curve[1]);
    V2Add(&bez_curve[3], V2Scale(&tHat2, dist), &bez_curve[2]);
  }
  else {
    /*  First and last control points of the Bezier curve are */
    /*  positioned exactly at the first and last data points */
    /*  Control points 1 and 2 are positioned an alpha distance out */
    /*  on the tangent vectors, left and right, respectively */
    bez_curve[0] = d[first];
    bez_curve[3] = d[last];
    V2Add(&bez_curve[0], V2Scale(&tHat1, alpha_l), &bez_curve[1]);
    V2Add(&bez_curve[3], V2Scale(&tHat2, alpha_r), &bez_curve[2]);
  }
  ZnFree(A0);
  ZnFree(A1);
}

/*
 * ComputeMaxError --
 *      Find the maximum squared distance of digitized points
 *      to fitted curve.
*/
static ZnReal
ComputeMaxError(ZnPoint         *d,
                unsigned int    first,
                unsigned int    last, 
                ZnPoint         *bez_curve,
                ZnReal          *u, 
                unsigned int    *splitPoint)
{
  unsigned int  i;
  ZnReal        maxDist;        /*  Maximum error               */
  ZnReal        dist;           /*  Current error               */
  ZnPoint       P;              /*  Point on curve              */
  ZnPoint       v;              /*  Vector from point to curve  */
  
  *splitPoint = (last - first + 1)/2;
  maxDist = 0.0;
  for (i = first + 1; i < last; i++) {
    P = BezierII(3, bez_curve, u[i-first]);
    v = V2SubII(P, d[i]);
    dist = V2SquaredLength(&v);
    if (dist >= maxDist) {
      maxDist = dist;
      *splitPoint = i;
    }
  }
  return (maxDist);
}

/*
 * ComputeLeftTangent,
 * ComputeRightTangent,
 * ComputeCenterTangent --
 *      Approximate unit tangents at endpoints and
 *      center of digitized curve.
 */
static ZnPoint
ComputeLeftTangent(ZnPoint      *d,
                   unsigned int end)
{
  ZnPoint tHat1;
  tHat1 = V2SubII(d[end+1], d[end]);
  tHat1 = *V2Normalize(&tHat1);
  return tHat1;
}

static ZnPoint
ComputeRightTangent(ZnPoint      *d,
                    unsigned int end)
{
  ZnPoint tHat2;
  tHat2 = V2SubII(d[end-1], d[end]);
  tHat2 = *V2Normalize(&tHat2);
  return tHat2;
}


static ZnPoint
ComputeCenterTangent(ZnPoint      *d,
                     unsigned int center)
{
  ZnPoint       V1, V2, tHatCenter;

  V1 = V2SubII(d[center-1], d[center]);
  V2 = V2SubII(d[center], d[center+1]);
  tHatCenter.x = (V1.x + V2.x)/2.0;
  tHatCenter.y = (V1.y + V2.y)/2.0;
  tHatCenter = *V2Normalize(&tHatCenter);
  return tHatCenter;
}

static void
FitCubic(ZnPoint        *d,
         unsigned int   first,
         unsigned int   last,
         ZnPoint        tHat1, 
         ZnPoint        tHat2,
         ZnReal         error,
         ZnList         controls)
{
  ZnPoint       *bez_curve;     /* Control points of fitted Bezier curve*/
  ZnReal        *u;             /* Parameter values for point  */
  ZnReal        *uPrime;        /* Improved parameter values */
  ZnReal        max_err;        /* Maximum fitting error         */
  unsigned int  splitPoint;     /* Point to split point set at   */
  unsigned int  num_points;     /* Number of points in subset  */
  ZnReal        iteration_err;  /* Error below which you try iterating  */
  unsigned int  max_iter = 4;   /* Max times to try iterating  */
  ZnPoint       tHatCenter;     /* Unit tangent vector at splitPoint */
  unsigned int  i;              

  iteration_err = error * error;
  num_points = last - first + 1;
  ZnListAssertSize(controls, ZnListSize(controls)+4);
  bez_curve = ZnListAt(controls, ZnListSize(controls)-4);
  
  /*  Use heuristic if region only has two points in it */
  if (num_points == 2) {
    ZnReal dist = V2DistanceBetween2Points(&d[last], &d[first]) / 3.0;

    bez_curve[0] = d[first];
    bez_curve[3] = d[last];
    V2Add(&bez_curve[0], V2Scale(&tHat1, dist), &bez_curve[1]);
    V2Add(&bez_curve[3], V2Scale(&tHat2, dist), &bez_curve[2]);
    return;
  }

  /*  Parameterize points, and attempt to fit curve */
  u = ChordLengthParameterize(d, first, last);
  GenerateBezier(d, first, last, u, tHat1, tHat2, bez_curve);
  
  /*  Find max deviation of points to fitted curve */
  max_err = ComputeMaxError(d, first, last, bez_curve, u, &splitPoint);
  if (max_err < error) {
    ZnFree(u);
    return;
  }
  
  /*
   * If error not too large, try some reparameterization
   *  and iteration.
   */
  if (max_err < iteration_err) {
    for (i = 0; i < max_iter; i++) {
      uPrime = Reparameterize(d, first, last, u, bez_curve);
      GenerateBezier(d, first, last, uPrime, tHat1, tHat2, bez_curve);
      max_err = ComputeMaxError(d, first, last,
                                bez_curve, uPrime, &splitPoint);
      if (max_err < error) {
        ZnFree(u);
        return;
      }
      ZnFree(u);
      u = uPrime;
    }
  }
  
  /* Fitting failed -- split at max error point and fit recursively */
  ZnFree(u);
  ZnListAssertSize(controls, ZnListSize(controls)-4);
  tHatCenter = ComputeCenterTangent(d, splitPoint);
  FitCubic(d, first, splitPoint, tHat1, tHatCenter, error, controls);
  V2Negate(&tHatCenter);
  FitCubic(d, splitPoint, last, tHatCenter, tHat2, error, controls);
}

void
ZnFitBezier(ZnPoint             *pts,
            unsigned int        num_points,
            ZnReal              error,
            ZnList              controls)
{
  ZnPoint       tHat1, tHat2;   /*  Unit tangent vectors at endpoints */

  tHat1 = ComputeLeftTangent(pts, 0);
  tHat2 = ComputeRightTangent(pts, num_points-1);
  FitCubic(pts, 0, num_points-1, tHat1, tHat2, error, controls);
}

