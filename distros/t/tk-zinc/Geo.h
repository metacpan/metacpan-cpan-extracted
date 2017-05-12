/*
 * Geo.h -- Header for common geometric routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Geo.h,v 1.21 2005/10/19 10:58:11 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Geo_h
#define _Geo_h


#include "Attrs.h"
#include "List.h"

#include <math.h>
#include <limits.h>


#ifndef M_PI
#define M_PI            3.14159265358979323846264338327
#endif
#ifndef M_PI_2
#define M_PI_2          1.57079632679489661923
#endif
#ifndef M_PI_4
#define M_PI_4          0.78539816339744830962
#endif

#define PRECISION_LIMIT         1.0e-10
#define X_PRECISION_LIMIT       5.0e-2
#define ZN_LINE_END_POINTS      6

/*
 * Constants used to specify circle approximation quality.
 */
#define ZN_CIRCLE_COARSE 0
#define ZN_CIRCLE_MEDIUM ZN_CIRCLE_COARSE+1
#define ZN_CIRCLE_FINE ZN_CIRCLE_MEDIUM+1
#define ZN_CIRCLE_FINER ZN_CIRCLE_FINE+1
#define ZN_CIRCLE_FINEST ZN_CIRCLE_FINER+1
  

/*
 * I would like to make these be floats,
 * but have to investigate how. Structures
 * handed to GL or GLU tess _must_ have
 * points has doubles.
 */
typedef struct {
  double        x, y;
} ZnPoint;

typedef struct {
  double        x, y, w, h;
} ZnRect;

/*
 * ZnBBox: orig is into the area while corner is not.
 * Thus the test: ((bbox.orig.x == bbox.corner.x) ||
 *                 (bbox.orig.y == bbox.corner.y))
 * tells whether the bbox is empty or not.
 * When interpreting bboxes the X coordinate system is
 * the norm. x goes from left toward the right and y
 * goes from the top toward the bottom. Bboxes are
 * always axes aligned.
 */
typedef struct {
  ZnPoint       orig, corner;
} ZnBBox;

typedef struct {
  unsigned int  num_points;
  ZnPoint       *points;
  char          *controls;
  ZnBool        cw;
} ZnContour;

/*
 * contour1 can be used to store a single contour
 * without having to alloc the contours array.
 */
typedef struct {
  unsigned int  num_contours;
  ZnContour     *contours;
  ZnContour     contour1;
} ZnPoly;

/*
 * Keep this enum in sync with op_strings in Contour()
 * in tkZinc.c.
 */
typedef enum {
  ZN_CONTOUR_ADD, ZN_CONTOUR_REMOVE
} ZnContourCmd;

typedef struct {
  unsigned int  num_points;
  ZnPoint       *points;
  ZnBool        fan;    /* When using a fan, all contour vertices must be
                         * included to describe the contour as a polygon
                         * (clipping code use that to speed up region
                         * rendering) and the center must be the first
                         * vertex. */
} ZnStrip;
  
typedef struct {
  unsigned int  num_strips;
  ZnStrip       *strips;
  ZnStrip       strip1;
} ZnTriStrip;


#ifndef MIN
#define MIN(a, b)       ((a) <= (b) ? (a) : (b))
#endif
#ifndef MAX
#define MAX(a, b)       ((a) >= (b) ? (a) : (b))
#endif
#ifndef ABS
#define ABS(a)          ((a) < 0 ? -(a) : (a))
#endif

#define ZnDegRad(angle) \
  (M_PI * (double) (angle) / 180.0)
#define ZnRadDeg(angle) \
  (fmod((angle) * 180.0 / M_PI, 360.0))
#define ZnRadDeg360(angle) \
  (fmod(ZnRadDeg(angle)+360.0,360.0))

#define ZnNearestInt(d) \
  (((int) ((d) + (((d) > 0) ? 0.5 : -0.5))))

void
ZnPolyInit(ZnPoly       *poly);
void
ZnPolyContour1(ZnPoly           *poly,
               ZnPoint          *pts,
               unsigned int     num_pts,
               ZnBool           cw);
void
ZnPolySet(ZnPoly        *poly1,
          ZnPoly        *poly2);
void
ZnPolyFree(ZnPoly       *poly);
void
ZnTriStrip1(ZnTriStrip          *tristrip,
            ZnPoint             *pts,
            unsigned int        num_pts,
            ZnBool              fan);
void
ZnTriFree(ZnTriStrip    *tristrip);

void
ZnAnchor2Origin(ZnPoint         *position,
                ZnDim           width,
                ZnDim           height,
                Tk_Anchor       anchor,
                ZnPoint         *origin);
void
ZnOrigin2Anchor(ZnPoint         *origin,
                ZnDim           width,
                ZnDim           height,
                Tk_Anchor       anchor,
                ZnPoint         *position);
void ZnRectOrigin2Anchor(ZnPoint *rect, Tk_Anchor anchor, ZnPoint *position);
void
ZnBBox2XRect(ZnBBox     *bbox,
             XRectangle *rect);
void
ZnGetStringBBox(char    *str,
                Tk_Font font,
                ZnPos   x,
                ZnPos   y,
                ZnBBox  *str_bbox);
void
ZnResetBBox(ZnBBox *bbox);
void
ZnCopyBBox(ZnBBox *bbox_from,
           ZnBBox *bbox_to);
void
ZnIntersectBBox(ZnBBox *bbox1,
                ZnBBox *bbox2,
                ZnBBox *bbox_inter);
ZnBool
ZnIsEmptyBBox(ZnBBox *bbox);
void
ZnAddBBoxToBBox(ZnBBox *bbox,
                ZnBBox *bbox2);
void
ZnAddPointToBBox(ZnBBox *bbox,
                 ZnPos  px,
                 ZnPos  py);
void
ZnAddPointsToBBox(ZnBBox     *bbox,
                  ZnPoint     *points,
                  unsigned int num_points);
void
ZnAddStringToBBox(ZnBBox        *bbox,
                  char          *str,
                  Tk_Font       font,
                  ZnPos         cx,
                  ZnPos         cy);
ZnBool
ZnPointInBBox(ZnBBox    *bbox,
              ZnPos     x,
              ZnPos     y);

int
ZnLineInBBox(ZnPoint    *p1,
             ZnPoint    *p2,
             ZnBBox     *bbox);

int
ZnBBoxInBBox(ZnBBox     *bbox1,
             ZnBBox     *bbox2);

int
ZnPolylineInBBox(ZnPoint        *points,
                 unsigned int   num_points,
                 ZnDim          width,
                 int            cap_style,
                 int            join_style,
                 ZnBBox         *bbox);

int
ZnPolygonInBBox(ZnPoint         *points,
                unsigned int    num_points,
                ZnBBox          *bbox,
                ZnBool          *area_enclosed);

int
ZnOvalInBBox(ZnPoint    *center,
             ZnDim      width,
             ZnDim      height,
             ZnBBox     *bbox);

ZnBool
ZnHorizLineToArc(ZnReal x1,
                 ZnReal x2,
                 ZnReal y,
                 ZnReal rx,
                 ZnReal ry,
                 int    start_angle,
                 int    angle_extent);

ZnBool
ZnVertLineToArc(ZnReal  x,
                ZnReal  y1,
                ZnReal  y2,
                ZnReal  rx,
                ZnReal  ry,
                int     start_angle,
                int     angle_extent);

ZnBool
ZnPointInAngle(int      start_angle,
               int      angle_extent,
               ZnPoint  *p);

void
ZnPointCartesianToPolar(ZnReal heading,
                        ZnReal *rho,
                        ZnReal *theta,
                        ZnReal delta_x,
                        ZnReal delta_y);

void
ZnPointPolarToCartesian(ZnReal  heading,
                        ZnReal  rho,
                        ZnReal  theta,
                        ZnReal  *delta_x,
                        ZnReal  *delta_y);

ZnReal
ZnProjectionToAngle(ZnReal      dx,
                    ZnReal      dy);

ZnDim
ZnRectangleToPointDist(ZnBBox   *bbox,
                       ZnPoint  *p);
ZnDim ZnLineToPointDist(ZnPoint *p1, ZnPoint *p2, ZnPoint *p, ZnPoint *closest);

ZnDim
ZnPolygonToPointDist(ZnPoint            *points,
                     unsigned int       num_points,
                     ZnPoint            *p);

ZnDim
ZnPolylineToPointDist(ZnPoint           *points,
                      unsigned int      num_points,
                      ZnDim             width,
                      int               cap_style,
                      int               join_style,                
                      ZnPoint           *p);

ZnDim
ZnOvalToPointDist(ZnPoint       *center,
                  ZnDim         width,
                  ZnDim         height,
                  ZnDim         line_width,
                  ZnPoint       *p);

void
ZnGetButtPoints(ZnPoint *p1,
                ZnPoint *p2,
                ZnDim   width,
                ZnBool  projecting,
                ZnPoint *c1,
                ZnPoint *c2);

ZnBool
ZnGetMiterPoints(ZnPoint        *p1,
                 ZnPoint        *p2,
                 ZnPoint        *p3,
                 ZnDim          width,
                 ZnPoint        *c1,
                 ZnPoint        *c2);

ZnBool
ZnIntersectLines(ZnPoint        *a1,
                 ZnPoint        *a2,
                 ZnPoint        *b1,
                 ZnPoint        *b2,
                 ZnPoint        *pi);

void
ZnShiftLine(ZnPoint     *p1,
            ZnPoint     *p2,
            ZnDim       dist,
            ZnPoint     *p3,
            ZnPoint     *p4);

void
ZnInsetPolygon(ZnPoint          *p,
               unsigned int     num_points,
               ZnDim            inset);

void
ZnSmoothPathWithBezier(ZnPoint          *from_points,
                       unsigned int     num_points,
                       ZnList           to_points);

void
ZnGetBezierPoints(ZnPoint       *p1,
                  ZnPoint       *c1,
                  ZnPoint       *c2,
                  ZnPoint       *p2,
                  ZnList        to_points,
                  double        eps);
void
ZnGetBezierPath(ZnList  from_points,
                ZnList  to_points);


ZnPoint *
ZnGetCirclePoints(int           type,
                  int           quality,
                  ZnReal        start_angle,
                  ZnReal        angle_extent,
                  unsigned int  *num_points,
                  ZnList        point_list);

void
ZnGetArcPath(ZnReal     start_angle,
             ZnReal     end_angle,
             int        type,
             ZnList     to_points);

void
ZnFitBezier(ZnPoint     *pts,
            unsigned int num_points,
            ZnReal      error,
            ZnList      controls);

ZnBool
ZnTestCCW(ZnPoint               *p,
          unsigned int  num_points);


#endif  /* _Geo_h */
