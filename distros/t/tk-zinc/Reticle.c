/*
 * Reticle.c -- Implementation of Reticle item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Mon Feb  1 12:13:24 1999
 *
 * $Id: Reticle.c,v 1.45 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Types.h"
#include "WidgetInfo.h"
#include "Item.h"
#include "Geo.h"
#include "Draw.h"

#include <math.h>


static const char rcsid[] = "$Id: Reticle.c,v 1.45 2005/05/10 07:59:48 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 * Draw as many circles as visible.
 */
#define ANY_CIRCLES     -1

/*
 * Some default values.
 */
#define DEFAULT_RETICLE_STEP_SIZE       80
#define DEFAULT_RETICLE_PERIOD          5

/*
 **********************************************************************************
 *
 * Specific Reticle item record
 *
 **********************************************************************************
 */

typedef struct _ReticleItemStruct {
  ZnItemStruct  header;
 
  /* Public data */
  ZnPoint       pos;                    /* Origin world coordinates     */
  ZnGradient    *line_color;            /* circle color           */
  ZnGradient    *bright_line_color;     /* intermediate circle color */
  ZnDim         first_radius;           /* first world radius             */
  ZnDim         step_size;              /* step world size                */
  int           period;                 /* bright circle period           */
  int           num_circles;            /* num cercles max                */
  ZnLineStyle   line_style;             /* circles lines styles           */
  ZnLineStyle   bright_line_style;

  /* Private data */
  ZnPoint       dev;                    /* item device coordinate         */
  ZnDim         first_radius_dev;       /* first device radius            */
  ZnDim         step_size_dev;          /* steps device size              */
} ReticleItemStruct, *ReticleItem;


static ZnAttrConfig     reticle_attrs[] = {
  { ZN_CONFIG_GRADIENT, "-brightlinecolor", NULL,
    Tk_Offset(ReticleItemStruct, bright_line_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-brightlinestyle", NULL,
    Tk_Offset(ReticleItemStruct, bright_line_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(ReticleItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(ReticleItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(ReticleItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_DIM, "-stepsize", NULL,
    Tk_Offset(ReticleItemStruct, step_size), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_DIM, "-firstradius", NULL,
    Tk_Offset(ReticleItemStruct, first_radius), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-linecolor", NULL,
    Tk_Offset(ReticleItemStruct, line_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-linestyle", NULL,
    Tk_Offset(ReticleItemStruct, line_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_UINT, "-numcircles", NULL,
    Tk_Offset(ReticleItemStruct, num_circles), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_UINT, "-period", NULL,
    Tk_Offset(ReticleItemStruct, period), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_POINT, "-position", NULL,
    Tk_Offset(ReticleItemStruct, pos), 0,
    ZN_COORDS_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(ReticleItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(ReticleItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(ReticleItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(ReticleItemStruct, header.flags), ZN_VISIBLE_BIT,
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
  ReticleItem   reticle = (ReticleItem) item;
  ZnWInfo       *wi = item->wi;
  
  SET(item->flags, ZN_VISIBLE_BIT);
  CLEAR(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 0;
  item->part_sensitive = 0;
  reticle->line_color = ZnGetGradientByValue(wi->fore_color);
  reticle->bright_line_color = ZnGetGradientByValue(wi->fore_color);
  reticle->first_radius = DEFAULT_RETICLE_STEP_SIZE;
  reticle->step_size = DEFAULT_RETICLE_STEP_SIZE;
  reticle->period = DEFAULT_RETICLE_PERIOD;
  reticle->num_circles = ANY_CIRCLES;
  reticle->line_style = ZN_LINE_SIMPLE;
  reticle->bright_line_style = ZN_LINE_SIMPLE;
  reticle->pos.x = 0;
  reticle->pos.y = 0;
  reticle->dev.x = 0;
  reticle->dev.y = 0;
  reticle->first_radius_dev = 0;
  reticle->step_size_dev = 0;

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
  ReticleItem   reticle = (ReticleItem) item;
  
  reticle->line_color = ZnGetGradientByValue(reticle->line_color);
  reticle->bright_line_color = ZnGetGradientByValue(reticle->bright_line_color);  
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
  ReticleItem   reticle = (ReticleItem) item;
    
  ZnFreeGradient(reticle->line_color);
  ZnFreeGradient(reticle->bright_line_color);
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
  if (ZnConfigureAttributes(item->wi, item, item, reticle_attrs,
                            argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
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
  if (ZnQueryAttribute(item->wi->interp, item, reticle_attrs, argv[0]) == TCL_ERROR) {
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
  ReticleItem   reticle  = (ReticleItem) item;
  ZnDim         half_width;
  ZnPoint       p, xp;
  
  /* Compute center device coordinates */
  p.x = p.y = 0;
  ZnTransformPoint(wi->current_transfo, &p, &reticle->dev);
  p.x = reticle->step_size;
  ZnTransformPoint(wi->current_transfo, &p, &xp);
  reticle->step_size_dev = hypot(xp.x - reticle->dev.x, xp.y - reticle->dev.y);
  p.x = reticle->first_radius;
  ZnTransformPoint(wi->current_transfo, &p, &xp);
  reticle->first_radius_dev = hypot(xp.x - reticle->dev.x, xp.y - reticle->dev.y);
  if (reticle->first_radius_dev < 1.0) {
    reticle->first_radius_dev = 1.0;
  }
  if (reticle->step_size_dev < 1.0) {
    reticle->step_size_dev = 1.0;
  }
  
  /* Reticle bounding box is zn bounding box or depends on num_circles */
  if (reticle->num_circles == ANY_CIRCLES) {
    item->item_bounding_box.orig.x = 0;
    item->item_bounding_box.orig.y = 0;
    item->item_bounding_box.corner.x = wi->width;
    item->item_bounding_box.corner.y = wi->height;
  }
  else {
    half_width = reticle->first_radius_dev +
                 (reticle->num_circles - 1) * reticle->step_size_dev;
    item->item_bounding_box.orig.x = reticle->dev.x - half_width;
    item->item_bounding_box.orig.y = reticle->dev.y - half_width;
    item->item_bounding_box.corner.x = item->item_bounding_box.orig.y + (2 * half_width);
    item->item_bounding_box.corner.y = item->item_bounding_box.orig.y + (2 * half_width);
  }
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
  return -1;
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
  ReticleItem   reticle = (ReticleItem) item;
  ZnDim         radius  = reticle->first_radius_dev;
  ZnDim         radius_max_dev;
  XGCValues     values;
  int           i;
  ZnDim         l1, l2, l3, l4;
/*  int         count = 0;*/

  /* Compute radius max */
  l1 = (ZnDim) hypot(wi->damaged_area.orig.x - reticle->dev.x,
                     wi->damaged_area.orig.y - reticle->dev.y);
  l2 = (ZnDim) hypot(wi->damaged_area.corner.x - reticle->dev.x,
                     wi->damaged_area.orig.y - reticle->dev.y);
  l3 = (ZnDim) hypot(wi->damaged_area.orig.x - reticle->dev.x,
                     wi->damaged_area.corner.y - reticle->dev.y);
  l4 = (ZnDim) hypot(wi->damaged_area.corner.x - reticle->dev.x,
                     wi->damaged_area.corner.y - reticle->dev.y);
  radius_max_dev = MAX(MAX(l1,l2), MAX(l3, l4));

  if (reticle->num_circles > 0) {
    radius_max_dev = MIN(radius_max_dev, reticle->first_radius_dev +
                         (reticle->num_circles - 1) * reticle->step_size_dev);
  }
  
  while (radius <= radius_max_dev) {
    ZnSetLineStyle(wi, reticle->line_style);
    values.foreground = ZnGetGradientPixel(reticle->line_color, 0.0);
    values.line_width = 0;
    values.fill_style = FillSolid;
    XChangeGC(wi->dpy, wi->gc, GCForeground | GCLineWidth | GCFillStyle, &values);
    for (i = 1; ((radius <= radius_max_dev) && (i < reticle->period)); i++) {
      if ((reticle->dev.x >= wi->damaged_area.orig.x - radius) &&
          (reticle->dev.x <= wi->damaged_area.corner.x + radius) &&
          (reticle->dev.y >= wi->damaged_area.orig.y - radius) &&
          (reticle->dev.y <= wi->damaged_area.corner.y + radius)) {
        XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
                 (int) (reticle->dev.x - radius),
                 (int) (reticle->dev.y - radius),
                 (unsigned int) (radius * 2 - 1),
                 (unsigned int) (radius * 2 - 1),
                 0, 360 * 64);
/*      count++;*/
      }
      radius += (reticle->step_size_dev);
    }
    if ((radius <= radius_max_dev) &&
        (reticle->dev.x >= wi->damaged_area.orig.x - radius) &&
        (reticle->dev.x <= wi->damaged_area.corner.x + radius) &&
        (reticle->dev.y >= wi->damaged_area.orig.y - radius) &&
        (reticle->dev.y <= wi->damaged_area.corner.y + radius)) {
      ZnSetLineStyle(wi, reticle->bright_line_style);
      values.foreground = ZnGetGradientPixel(reticle->bright_line_color, 0.0);
      values.line_width = 0;
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc, GCForeground | GCLineWidth | GCFillStyle, &values);
      XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
               (int) (reticle->dev.x - radius),
               (int) (reticle->dev.y - radius),
               (unsigned int) (radius * 2 - 1),
               (unsigned int) (radius * 2 - 1),
               0, 360 * 64);
      /*count++;*/
    }
    radius += (reticle->step_size_dev);
  }
/*printf("# circles drawn: %d\n", count);*/
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
  ReticleItem   reticle = (ReticleItem) item;
  ZnDim         radius  = reticle->first_radius_dev;
  ZnDim         radius_max_dev, new, x, y, xo, yo;
  int           i, j;
  ZnPoint       *genarc;
  int           num_p;
  unsigned short alpha;
  XColor        *color;

  xo = reticle->dev.x;
  yo = reticle->dev.y;
  /* Compute radius max */
  radius_max_dev = 0;
  x = wi->damaged_area.orig.x - xo;
  y = wi->damaged_area.orig.y - yo;
  new = x*x + y*y;
  if (new > radius_max_dev) {
    radius_max_dev = new;
  }
  x = wi->damaged_area.corner.x - xo;
  y = wi->damaged_area.orig.y - yo;
  new = x*x + y*y;
  if (new > radius_max_dev) {
    radius_max_dev = new;
  }
  x = wi->damaged_area.orig.x - xo;
  y = wi->damaged_area.corner.y - yo;
  new = x*x + y*y;
  if (new > radius_max_dev) {
    radius_max_dev = new;
  }
  x = wi->damaged_area.corner.x - xo;
  y = wi->damaged_area.corner.y - yo;
  new = x*x + y*y;
  if (new > radius_max_dev) {
    radius_max_dev = new;
  }
  radius_max_dev = sqrt(radius_max_dev);

  if (reticle->num_circles > 0) {
    radius_max_dev = MIN(radius_max_dev, reticle->first_radius_dev +
                         (reticle->num_circles - 1) * reticle->step_size_dev);
  }

  genarc = ZnGetCirclePoints(3, ZN_CIRCLE_FINER, 0.0, 2*M_PI, &num_p, NULL);
  glLineWidth(1.0);
  while (radius <= radius_max_dev) {
    ZnSetLineStyle(wi, reticle->line_style);
    color = ZnGetGradientColor(reticle->line_color, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
    glColor4us(color->red, color->green, color->blue, alpha);
    for (i = 1; ((radius <= radius_max_dev) && (i < reticle->period)); i++) {
      if ((xo >= wi->damaged_area.orig.x - radius) &&
          (xo <= wi->damaged_area.corner.x + radius) &&
          (yo >= wi->damaged_area.orig.y - radius) &&
          (yo <= wi->damaged_area.corner.y + radius)) {
        glBegin(GL_LINE_LOOP);
        for (j = 0; j < num_p; j++) {
          x = xo + genarc[j].x * radius;
          y = yo + genarc[j].y * radius;
          glVertex2d(x, y);
        }
        glEnd();
      }
      radius += (reticle->step_size_dev);
    }
    if ((radius <= radius_max_dev) &&
        (xo >= wi->damaged_area.orig.x - radius) &&
        (xo <= wi->damaged_area.corner.x + radius) &&
        (yo >= wi->damaged_area.orig.y - radius) &&
        (yo <= wi->damaged_area.corner.y + radius)) {
      ZnSetLineStyle(wi, reticle->bright_line_style);
      color = ZnGetGradientColor(reticle->bright_line_color, 0.0, &alpha);
      alpha = ZnComposeAlpha(alpha, wi->alpha);
      glColor4us(color->red, color->green, color->blue, alpha);
      glBegin(GL_LINE_LOOP);
      for (j = 0; j < num_p; j++) {
        x = xo + genarc[j].x * radius;
        y = yo + genarc[j].y * radius;
        glVertex2d(x, y);
      }
      glEnd();
    }
    radius += (reticle->step_size_dev);
  }
  glDisable(GL_LINE_STIPPLE);
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
 *      Nothing to pick, we are almost transparent.
 *
 **********************************************************************************
 */
static double
Pick(ZnItem     item,
     ZnPick     ps)
{
  return 1e40;
}


/*
 **********************************************************************************
 *
 * Coords --
 *      Return or edit the item center.
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
  ReticleItem   reticle = (ReticleItem) item;
  
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " reticles can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on reticles", NULL);
      return TCL_ERROR;
    }
    reticle->pos = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    *num_pts = 1;
    *pts = &reticle->pos;
  }
  return TCL_OK;
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
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Exported functions struct --
 *
 **********************************************************************************
 */
static ZnItemClassStruct RETICLE_ITEM_CLASS = {
  "reticle",
  sizeof(ReticleItemStruct),
  reticle_attrs,
  0,                    /* num_parts */
  ZN_CLASS_ONE_COORD,   /* flags */
  Tk_Offset(ReticleItemStruct, pos),
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  NULL,                 /* GetFieldSet */
  NULL,                 /* GetAnchor */
  NULL,                 /* GetClipVertices */
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

ZnItemClassId ZnReticle = (ZnItemClassId) &RETICLE_ITEM_CLASS;
