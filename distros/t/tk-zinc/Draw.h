/*
 * Draw.h -- Header for common drawing routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Sat Dec 10 12:51:30 1994
 *
 * $Id: Draw.h,v 1.24 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Draw_h
#define _Draw_h

#include "List.h"
#include "Types.h"
#include "Color.h"
#include "Attrs.h"
#include "Image.h"


#define ZN_LINE_SHAPE_POINTS    4       /* Maximum of all *_SHAPE_POINTS */

struct _ZnWInfo;

#ifdef GL
#define ZnGlStartClip(num_clips, render) { \
  if (!num_clips) { \
    glEnable(GL_STENCIL_TEST); \
  } \
  glStencilFunc(GL_EQUAL, (GLint) num_clips, 0xFF); \
  glStencilOp(GL_KEEP, GL_INCR, GL_INCR); \
  if (!render) { \
    glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE); \
  } \
}
#define ZnGlRenderClipped() { \
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP); \
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE); \
  }
#define ZnGlRestoreStencil(num_clips, render) { \
  glStencilFunc(GL_EQUAL, (GLint) (num_clips+1), 0xFF); \
  glStencilOp(GL_KEEP, GL_DECR, GL_DECR); \
  if (render) { \
    glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE); \
  } \
  else { \
   glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE); \
  } \
}
#define ZnGlEndClip(num_clips) { \
  glStencilFunc(GL_EQUAL, (GLint) num_clips, 0xFF); \
  glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP); \
  glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE); \
  if (!num_clips) { \
    glDisable(GL_STENCIL_TEST); \
  } \
}
#endif


void ZnSetLineStyle(struct _ZnWInfo *wi, ZnLineStyle line_style);
void ZnLineShapePoints(ZnPoint *p1, ZnPoint *p2, ZnDim line_width,
                       ZnLineShape shape, ZnBBox *bbox, ZnList to_points);
void ZnDrawLineShape(struct _ZnWInfo *wi, ZnPoint *points, unsigned int num_points,
                     ZnLineStyle line_style, int foreground_pixel,
                     ZnDim line_width, ZnLineShape shape);
void
ZnGetLineEnd(ZnPoint *p1, ZnPoint *p2, ZnDim line_width,
             int cap_style, ZnLineEnd end_style, ZnPoint *points);

int ZnPolygonReliefInBBox(ZnPoint *points, unsigned int num_points,
                          ZnDim line_width, ZnBBox *bbox);
void ZnGetPolygonReliefBBox(ZnPoint *points, unsigned int num_points,
                            ZnDim line_width, ZnBBox *bbox);
double ZnPolygonReliefToPointDist(ZnPoint *points, unsigned int num_points,
                                  ZnDim line_width, ZnPoint *pp);
void ZnDrawRectangleRelief(struct _ZnWInfo *wi,
                           ZnReliefStyle relief, ZnGradient *gradient,
                           XRectangle *bbox, ZnDim line_width);
void ZnDrawPolygonRelief(struct _ZnWInfo *wi, ZnReliefStyle relief,
                         ZnGradient *gradient, ZnPoint *points,
                         unsigned int num_points, ZnDim line_width);
#ifdef GL
void ZnRenderPolygonRelief(struct _ZnWInfo *wi, ZnReliefStyle relief,
                           ZnGradient *gradient, ZnBool smooth,
                           ZnPoint *points, unsigned int num_points, ZnDim line_width);
void ZnRenderPolyline(struct _ZnWInfo *wi, ZnPoint *points, unsigned int num_points,
                      ZnDim line_width, ZnLineStyle line_style, int cap_style,
                      int join_style, ZnLineEnd first_end, ZnLineEnd last_end,
                      ZnGradient *gradient);
void ZnComputeGradient(ZnGradient *grad, struct _ZnWInfo *wi, ZnPoly *shape,
                       ZnPoint *grad_geo);
void ZnRenderGradient(struct _ZnWInfo *wi, ZnGradient *gradient,
                      void (*cb)(void *), void *closure, ZnPoint *quad,
                      ZnPoly *poly);
void ZnRenderTile(struct _ZnWInfo *wi, ZnImage tile, ZnGradient *gradient,
                  void (*cb)(void *), void *closure, ZnPoint *quad);
void ZnRenderIcon(struct _ZnWInfo *wi, ZnImage image, ZnGradient *gradient,
                  ZnPoint *origin, ZnBool modulate);
void ZnRenderImage(struct _ZnWInfo *wi, ZnImage image, ZnGradient *gradient,
                   ZnPoint *quad, ZnBool modulate);
void RenderHollowDot(struct _ZnWInfo *wi, ZnPoint *p, ZnReal size);

void ZnRenderGlyph(ZnTexFontInfo *tfi, int c);
void ZnRenderString(ZnTexFontInfo *tfi, unsigned char *str, unsigned int len);
#endif

void ZnMapImage(XImage *image, XImage *mapped_image, ZnPoint *poly);


#endif  /* _Draw_h */
