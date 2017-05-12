/*
 * Color.c -- Color management module.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Thu Dec 16 15:41:53 1999
 *
 * $Id: Color.c,v 1.37 2005/12/02 13:35:39 lecoanet Exp $
 */

/*
 *  Copyright (c) 1999 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

/*
 * Most of this file is derived from Tk color code and thus
 * also copyrighted:
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 *
 */


#include <string.h>
#include <stdlib.h>

#include "Types.h"
#include "Image.h"
#include "Color.h"
#include "Geo.h"
#include "Transfo.h"


/*
 * Maximum size of a color name including the \0.
 */
#define COLOR_NAME_SIZE 32

/*
 * Maximum intensity for a color.
 */
#define MAX_INTENSITY 65535

/*
 * Hash table to map from a gradient's values (color, etc.) to a
 * gradient structure for those values.
 */
static Tcl_HashTable gradient_table;

static int initialized = 0;     /* 0 means static structures haven't been
                                 * initialized yet. */


/*
 *----------------------------------------------------------------------
 *
 * ColorInit --
 *
 *      Initialize the structure used for color management.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Read the code.
 *
 *----------------------------------------------------------------------
 */
static void
ColorInit()
{
  initialized = 1;
  Tcl_InitHashTable(&gradient_table, TCL_STRING_KEYS);
}


/*
 *----------------------------------------------------------------------
 *
 * ZnGetGradientColor
 * ZnInterpGradientColor --
 *
 *----------------------------------------------------------------------
 */
XColor *
ZnGetGradientColor(ZnGradient   *grad,
                   ZnReal       position,
                   unsigned short *alpha)
{
  int    index, min, max;
  XColor *shade=NULL;
  
  if ((grad->num_actual_colors == 1) || (position <= 0.0)) {
    if (alpha) {
      *alpha = grad->actual_colors[0].alpha;
    }
    return grad->actual_colors[0].rgb;
  }
  if (position >= 100.0) {
    if (alpha) {
      *alpha = grad->actual_colors[grad->num_actual_colors-1].alpha;
    }
    shade = grad->actual_colors[grad->num_actual_colors-1].rgb;
  }
  else {
    min = 0;
    max = grad->num_actual_colors-1;
    index = (max + min) / 2;
    while (max - min != 1) {
      /*printf("color index %d, min: %d, max: %d\n", index, min, max);*/
      if (grad->actual_colors[index].position < position) {
        min = index;
      }
      else {
        max = index;
      }
      index = (max + min) / 2;
    }
    shade = grad->actual_colors[index].rgb;
    if (alpha) {
      *alpha = grad->actual_colors[index].alpha;
    }
  }

  return shade;
}

void
ZnInterpGradientColor(ZnGradient     *grad,
                      ZnReal         position,
                      XColor         *color,
                      unsigned short *alpha)
{
  int index, min, max;
  ZnGradientColor *gc1, *gc2;
  ZnReal rel_pos;

  if ((grad->num_actual_colors == 1) || (position <= 0.0)) {
    *alpha = grad->actual_colors[0].alpha;
    *color = *grad->actual_colors[0].rgb;
  }
  else if (position >= 100.0) {
    *alpha = grad->actual_colors[grad->num_actual_colors-1].alpha;
    *color = *grad->actual_colors[grad->num_actual_colors-1].rgb;
  }
  else {
    min = 0;
    max = grad->num_actual_colors-1;
    index = (max + min) / 2;
    while (max - min != 1) {
      /*printf("color index %d, min: %d, max: %d\n", index, min, max);*/
      if (grad->actual_colors[index].position < position) {
        min = index;
      }
      else {
        max = index;
      }
      index = (max + min) / 2;
    }
    gc1 = &grad->actual_colors[index];
    gc2 = &grad->actual_colors[index+1];
    rel_pos = (position - gc1->position) * 100.0 / (gc2->position - gc1->position);
    
    if (rel_pos > gc1->control) {
      rel_pos = (rel_pos - gc1->control) * 100.0 / (100.0 - gc1->control);
      color->red = gc1->mid_rgb->red + 
        (unsigned short) ((gc2->rgb->red - gc1->mid_rgb->red) * rel_pos / 100.0);
      color->green = gc1->mid_rgb->green + 
        (unsigned short) ((gc2->rgb->green - gc1->mid_rgb->green) * rel_pos / 100.0);
      color->blue = gc1->mid_rgb->blue +
        (unsigned short) ((gc2->rgb->blue - gc1->mid_rgb->blue) * rel_pos / 100.0);
      *alpha = gc1->mid_alpha +
        (unsigned short) ((gc2->alpha - gc1->mid_alpha) * rel_pos / 100.0);
    }
    else {
      rel_pos = rel_pos * 100.0 / gc1->control;
      color->red = gc1->rgb->red +
        (unsigned short) ((gc1->mid_rgb->red - gc1->rgb->red) * rel_pos / 100.0);
      color->green = gc1->rgb->green +
        (unsigned short) ((gc1->mid_rgb->green - gc1->rgb->green) * rel_pos / 100.0);
      color->blue = gc1->rgb->blue +
        (unsigned short) ((gc1->mid_rgb->blue - gc1->rgb->blue) * rel_pos / 100.0);
      *alpha = gc1->alpha +
        (unsigned short) ((gc1->mid_alpha - gc1->alpha) * rel_pos / 100.0);
    }
  }
}


/*
 *--------------------------------------------------------------
 *
 * ZnGradientFlat --
 *
 *      Returns true if the gradient is defined by a single
 *      color.
 *
 *--------------------------------------------------------------
 */
ZnBool
ZnGradientFlat(ZnGradient       *grad)
{
  return (grad->num_actual_colors == 1);
}


/*
 *--------------------------------------------------------------
 *
 * ZnGetReliefGradient --
 *
 *      Create a data structure containing a range of colors
 *      used to display a 3D border. Name contains the base
 *      color for the border. This is a slight variation on
 *      the syntax of a gradient that make life easier in this
 *      simple case.
 *
 * Results:
 *      The return value is a token for a data structure
 *      describing a gradient.  This token may be passed
 *      to the drawing routines.
 *      If an error prevented the gradient from being created
 *      then NULL is returned and an error message will be
 *      left in interp.
 *
 * Side effects:
 *      Data structures, etc. are allocated.
 *      It is the caller's responsibility to eventually call
 *      ZnFreeGradient to release the resources.
 *
 *--------------------------------------------------------------
 */
ZnGradient *
ZnGetReliefGradient(Tcl_Interp  *interp,
                    Tk_Window   tkwin,
                    Tk_Uid      name,
                    unsigned short alpha)
{
  XColor *base, light_color, dark_color, color;
  char   color_name[COLOR_NAME_SIZE];
  char   buffer[COLOR_NAME_SIZE*(3+2*ZN_RELIEF_STEPS)];
  int    j, tmp1, tmp2;
  int    red_range, green_range, blue_range;
  
  base = Tk_GetColor(interp, tkwin, name);
  /*
   * Compute the border gradient.
   *
   * Always consider that we are dealing with a color display with
   * enough colors available. If the colormap is full (stressed)
   * then just pray, the susbstitution algorithm may return something
   * adequate ;-).
   *
   * The extremum colors get computed using whichever formula results
   * in the greatest change in color:
   * 1. Lighter color is half-way to white, darker color is half
   *    way to dark.
   * 2. Lighter color is 40% brighter than base, darker color
   *    is 40% darker than base.
   * The first approach works better for unsaturated colors, the
   * second for saturated ones.
   *
   * NOTE: Colors are computed with integers not color shorts which
   * may lead to overflow errors.
   */
  tmp1 = (30 * (int) base->red)/100;
  tmp2 = ((int) base->red)/2;
  dark_color.red = MIN(tmp1, tmp2);
  tmp1 = (30 * (int) base->green)/100;
  tmp2 = ((int) base->green)/2;
  dark_color.green = MIN(tmp1, tmp2);
  tmp1 = (30 * (int) base->blue)/100;
  tmp2 = ((int) base->blue)/2;
  dark_color.blue = MIN(tmp1, tmp2);
  
  tmp1 = MAX_INTENSITY;/*(170 * (int) base->red)/10;*/
  if (tmp1 > MAX_INTENSITY) {
    tmp1 = MAX_INTENSITY;
  }
  tmp2 = (MAX_INTENSITY + (int) base->red)/2;
  light_color.red = MAX(tmp1, tmp2);
  tmp1 = MAX_INTENSITY;/*(170 * (int) base->green)/10;*/
  if (tmp1 > MAX_INTENSITY) {
    tmp1 = MAX_INTENSITY;
  }
  tmp2 = (MAX_INTENSITY + (int) base->green)/2;
  light_color.green = MAX(tmp1, tmp2);
  tmp1 = MAX_INTENSITY;/*(170 * (int) base->blue)/10;*/
  if (tmp1 > MAX_INTENSITY) {
    tmp1 = MAX_INTENSITY;
  }
  tmp2 = (MAX_INTENSITY + (int) base->blue)/2;
  light_color.blue = MAX(tmp1, tmp2);

  buffer[0] = 0;
  sprintf(color_name, "#%02x%02x%02x;%d|",
          dark_color.red/256, dark_color.green/256, dark_color.blue/256, alpha);
  red_range = (int) base->red - (int) dark_color.red;
  green_range = (int) base->green - (int) dark_color.green;
  blue_range = (int) base->blue - (int) dark_color.blue;
  strcat(buffer, color_name);
  for (j = 1; j < ZN_RELIEF_STEPS; j++) {
    color.red =(int) dark_color.red +  red_range * j/ZN_RELIEF_STEPS;
    color.green = (int) dark_color.green + green_range * j/ZN_RELIEF_STEPS;
    color.blue = (int) dark_color.blue + blue_range * j/ZN_RELIEF_STEPS;
    sprintf(color_name, "#%02x%02x%02x;%d %d|",
            color.red/256, color.green/256, color.blue/256, alpha, 50/ZN_RELIEF_STEPS*j);
    strcat(buffer, color_name);
  }
  sprintf(color_name, "#%02x%02x%02x;%d 50|",
          base->red/256, base->green/256, base->blue/256, alpha);
  strcat(buffer, color_name);
  red_range = (int) light_color.red - (int) base->red;
  green_range = (int) light_color.green - (int) base->green;
  blue_range = (int) light_color.blue - (int) base->blue;
  for (j = 1; j < ZN_RELIEF_STEPS; j++) {
    color.red = (int) base->red +  red_range * j/ZN_RELIEF_STEPS;
    color.green = (int) base->green + green_range * j/ZN_RELIEF_STEPS;
    color.blue = (int) base->blue + blue_range * j/ZN_RELIEF_STEPS;
    sprintf(color_name, "#%02x%02x%02x;%d %d|",
            color.red/256, color.green/256, color.blue/256, alpha, 50+50/ZN_RELIEF_STEPS*j);
    strcat(buffer, color_name);
  }
  sprintf(color_name, "#%02x%02x%02x;%d",
          light_color.red/256, light_color.green/256, light_color.blue/256, alpha);
  strcat(buffer, color_name);

  /*printf("gradient relief: %s \n", buffer);*/
  return ZnGetGradient(interp, tkwin, buffer);
}


/*
 *--------------------------------------------------------------
 *
 * ZnNameGradient
 * ZnDeleteGradientName --
 *
 *      Save a gradient under a name or suppress the gradient
 *      name binding. The save function returns false if the
 *      name is already in use.
 *
 *--------------------------------------------------------------
 */
ZnBool
ZnNameGradient(Tcl_Interp       *interp,
               Tk_Window        tkwin,
               char             *grad_descr,
               char             *name)
{
  Tcl_HashEntry *hash;
  int           new;
  ZnGradient    *grad;
  XColor        color;

  /*
   * First try to find if the name interfere with a color name,
   * this must be avoided. Gradients may be described by a single
   * color name and gradient descriptions / names share the same
   * name space.
   */
  if (XParseColor(Tk_Display(tkwin), Tk_Colormap(tkwin), name, &color)) {
    Tcl_AppendResult(interp, "gradient name \"", name,
                     "\", is a color name", NULL);
    return False;
  }
  grad = ZnGetGradient(interp, tkwin, grad_descr);
  if (!grad) {
    Tcl_AppendResult(interp, "gradient specification \"", grad_descr,
                     "\", is invalid", NULL);
    return False;
  }
  hash = Tcl_CreateHashEntry(&gradient_table, Tk_GetUid(name), &new);
  if (!new) {
    ZnFreeGradient(grad);
    Tcl_AppendResult(interp, "gradient name \"", name,
                     "\", is already in use", NULL);
    return False;
  }
  else {
    Tcl_SetHashValue(hash, grad);
  }
  
  return True;
}

ZnBool
ZnGradientNameExists(char       *name)
{
  if (!initialized) {
    return False;
  }
  return Tcl_FindHashEntry(&gradient_table, Tk_GetUid(name)) != NULL;
}

void
ZnDeleteGradientName(char       *name)
{
  Tcl_HashEntry *hash;

  if (!initialized) {
    return;
  }
  
  hash = Tcl_FindHashEntry(&gradient_table, Tk_GetUid(name));
  if (hash) {
    Tcl_DeleteHashEntry(hash);
    ZnFreeGradient((ZnGradient *) Tcl_GetHashValue(hash));
  }
}

static void
InterpolateGradientColor(Tk_Window      tkwin,
                         ZnGradientColor *gc1,      /* First color */ 
                         ZnGradientColor *gc2,      /* Next color */
                         ZnGradientColor *gc_interp,/* New interpolated color */
                         ZnGradientColor *gc_adjust,/* Adjusted first color.
                                                     * Needed if interested in
                                                     * the range color1 interp
                                                     * color. */
                         int             interp_pos,
                         int             min_pos,
                         int             span)
{
  ZnReal pos1, pos2, ipos, interp_rel_pos, tmp;
  XColor rgb;

  //printf("interp_pos: %d, min_pos: %d, span: %d\n ", interp_pos, min_pos, span);
  pos1 = ((ZnReal)gc1->position-(ZnReal)min_pos)/(ZnReal)span;
  pos2 = ((ZnReal)gc2->position-(ZnReal)min_pos)/(ZnReal)span;
  ipos = ((ZnReal)interp_pos-(ZnReal)min_pos)/(ZnReal)span;
  interp_rel_pos = (ipos-pos1)*100/(pos2-pos1);

  //printf("pos1: %g, pos2: %g, interp_rel_pos: %g\n", pos1, pos2, interp_rel_pos);
  if (interp_rel_pos < gc1->control) {
    tmp = interp_rel_pos * 100.0 / gc1->control;
  //printf("rgb : %d, mid rgb : %d\n\n", gc1->rgb, gc1->mid_rgb);
    rgb.red = (unsigned short) (gc1->rgb->red + (gc1->mid_rgb->red - gc1->rgb->red) * tmp / 100.0);
    rgb.green = (unsigned short) (gc1->rgb->green + (gc1->mid_rgb->green - gc1->rgb->green) * tmp / 100.0);
    rgb.blue = (unsigned short) (gc1->rgb->blue + (gc1->mid_rgb->blue - gc1->rgb->blue) * tmp / 100.0);
    gc_interp->alpha = (unsigned char) (gc1->alpha + (gc1->mid_alpha - gc1->alpha) * tmp / 100.0);
  }
  else if (interp_rel_pos > gc1->control) {
    tmp = (interp_rel_pos - gc1->control) * 100.0 / (100.0 - gc1->control);
    rgb.red = (unsigned short) (gc1->mid_rgb->red + (gc2->rgb->red - gc1->mid_rgb->red)*tmp / 100.0);
    rgb.green = (unsigned short) (gc1->mid_rgb->green + (gc2->rgb->green - gc1->mid_rgb->green)*tmp / 100.0);
    rgb.blue = (unsigned short) (gc1->mid_rgb->blue + (gc2->rgb->blue - gc1->mid_rgb->blue)*tmp / 100.0);
    gc_interp->alpha = (unsigned char) (gc1->mid_alpha + (gc2->alpha - gc1->mid_alpha)*tmp / 100.0);
  }
  else {
    rgb = *gc1->mid_rgb;
    gc_interp->alpha = gc1->mid_alpha;    
  }
  gc_interp->rgb = Tk_GetColorByValue(tkwin, &rgb);

  if (!gc_adjust) {
    /*
     * Interested in the segment from the interpolated color
     * to color 2.
     */
    gc_interp->position = 0;
    if (interp_rel_pos < gc1->control) {
      gc_interp->control = gc1->control - (int) interp_rel_pos;
      gc_interp->mid_rgb = Tk_GetColorByValue(tkwin, gc1->mid_rgb);
      gc_interp->mid_alpha = gc1->mid_alpha;
    }
    else {
      rgb.red = gc_interp->rgb->red+(gc2->rgb->red-gc_interp->rgb->red)/2;
      rgb.green = gc_interp->rgb->green+(gc2->rgb->green-gc_interp->rgb->green)/2;
      rgb.blue = gc_interp->rgb->blue+(gc2->rgb->blue-gc_interp->rgb->blue)/2;
      gc_interp->mid_rgb = Tk_GetColorByValue(tkwin, &rgb);
      gc_interp->mid_alpha = gc_interp->alpha + (gc2->alpha - gc_interp->alpha)/2;
      gc_interp->control = 50;
    }
  }
  else {
    /*
     * Interested in the segment from color 1 (color adjusted) to
     * the interpolated color.
     */
    gc_interp->position = 100;
    gc_interp->mid_rgb = NULL;
    gc_interp->mid_alpha = 100;
    if (interp_rel_pos <= gc1->control) {
      rgb.red = gc1->rgb->red+(gc_interp->rgb->red-gc1->rgb->red)/2;
      rgb.green = gc1->rgb->green+(gc_interp->rgb->green-gc1->rgb->green)/2;
      rgb.blue = gc1->rgb->blue+(gc_interp->rgb->blue-gc1->rgb->blue)/2;
      Tk_FreeColor(gc_adjust->mid_rgb);
      gc_adjust->mid_rgb = Tk_GetColorByValue(tkwin, &rgb);
      gc_adjust->mid_alpha = gc1->alpha + (gc_interp->alpha - gc1->alpha)/2;
      gc_adjust->control = 50;
    }
  }
  //printf("out of InterpolateGradientColor\n");
}


static void
ReduceGradient(Tk_Window        tkwin,
               ZnGradient       *grad)
{
  ZnReal     dx, dy, len, angle;
  ZnTransfo  t;
  ZnPoint    pbbox[4], pgrad[4];
  ZnReal     maxx, minx, span, start_in_new, end_in_new;
  int        minx100, maxx100, span100;
  int        i, j, first_color, last_color;
  ZnBool     interpolate_first, interpolate_last;

  //printf("In ReduceGradient %d\n", grad->num_colors_in);
  dx = grad->e.x - grad->p.x;
  dy = grad->e.y - grad->p.y;
  len = sqrt(dx*dx+dy*dy);
  angle = acos(dx/len);
  if (dy < 0) {
    angle = 2*M_PI - angle;
  }  
  grad->angle = (int) -ZnRadDeg(angle);

  if (grad->type == ZN_CONICAL_GRADIENT) {
  unchanged:
    grad->actual_colors = grad->colors_in;
    grad->num_actual_colors = grad->num_colors_in;
    return;
  }

  ZnTransfoSetIdentity(&t);
  ZnTranslate(&t, -grad->p.x, -grad->p.y, False);
  ZnRotateRad(&t, -angle);
  ZnScale(&t, 1/len, 1/len);
  pbbox[0].x = -50;
  pbbox[0].y = 50;
  pbbox[1].x = 50;
  pbbox[1].y = 50;
  pbbox[2].x = 50;
  pbbox[2].y = -50;
  pbbox[3].x = -50;
  pbbox[3].y = -50;
  ZnTransformPoints(&t, pbbox, pgrad, 4);
  maxx = minx = pgrad[0].x;
  for (i = 1; i < 4; i++) {
    if (pgrad[i].x > maxx) {
      maxx = pgrad[i].x;
    }
    if (pgrad[i].x < minx) {
      minx = pgrad[i].x;
    }
  }

  span = maxx-minx;
  if (grad->type == ZN_RADIAL_GRADIENT) {
    start_in_new = 0;
    end_in_new = 100/span;
  }
  else {
    start_in_new = -minx*100/span;
    end_in_new = (1-minx)*100/span;
  }

  //printf("minx: %g, maxx: %g, start%%: %g, end%%: %g\n",
    //     minx, maxx, start_in_new, end_in_new);
  
  /*
   * Gradient is unchanged
   */
  if ((ABS(start_in_new) < PRECISION_LIMIT) &&
      (ABS(end_in_new-100.0) < PRECISION_LIMIT)) {
    goto unchanged;
  }
  //printf("start_in_new: %g, end_in_new: %g\n", start_in_new, end_in_new);
  if ((start_in_new > 100.0) || (end_in_new < 0.0)) {
    grad->num_actual_colors = 1;
    grad->actual_colors = ZnMalloc(sizeof(ZnGradientColor));
    grad->actual_colors[0].position = 0;
    grad->actual_colors[0].mid_rgb = NULL;
    if (end_in_new < 0.0) {
      grad->actual_colors[0].alpha = grad->colors_in[grad->num_colors_in-1].alpha;
      grad->actual_colors[0].rgb = Tk_GetColorByValue(tkwin, grad->colors_in[grad->num_colors_in-1].rgb);
    }
    else {
      grad->actual_colors[0].alpha = grad->colors_in[0].alpha;
      grad->actual_colors[0].rgb = Tk_GetColorByValue(tkwin, grad->colors_in[0].rgb);
    }
    return;
  }

  grad->num_actual_colors = grad->num_colors_in;
  interpolate_first = False;
  minx100 = (int) (minx*100);
  maxx100 = (int) (maxx*100);
  span100 = (int) (span*100);

  if (start_in_new < 0.0) {
    /*
     * The gradient starts outside the bbox,
     * Find the color at the bbox edge. First
     * find the correct gradient segment and then
     * interpolate to get the color.
     */
    first_color = 1;
    while ((first_color < (int) grad->num_colors_in) &&
           (grad->colors_in[first_color].position < minx100)) {
      first_color++;
      grad->num_actual_colors--;
    }
    if (grad->colors_in[first_color].position == minx100) {
      grad->num_actual_colors--;
    }
    else {
      interpolate_first = True;
      /*printf("interpolate first color\n");*/
    }
  }
  else {
    first_color = 0;
    if (grad->type != ZN_RADIAL_GRADIENT) {
      grad->num_actual_colors++;
    }
  }
  interpolate_last = False;
  if (end_in_new > 100.0) {
    /*
     * The gradient ends outside the bbox,
     * Find the color at the bbox edge. First
     * find the correct gradient segment and then
     * interpolate to get the color.
     */
    last_color = grad->num_colors_in-2;
    while ((last_color >= 0) &&
           (grad->colors_in[last_color].position > maxx100)) {
      last_color--;
      grad->num_actual_colors--;
    }
    if (grad->colors_in[last_color].position == maxx100) {
      grad->num_actual_colors--;
    }
    else {
      interpolate_last = True;
      /*printf("interpolate last color\n");*/
    }
  }
  else {
    last_color = grad->num_colors_in-1;
    grad->num_actual_colors++;
  }

  grad->actual_colors = ZnMalloc(grad->num_actual_colors*sizeof(ZnGradientColor));
  //printf("allocating %d colors\n", grad->num_actual_colors);
  j = 0;
  if (interpolate_first) {
    //printf("Interpolate first color, index: %d\n", first_color);
    InterpolateGradientColor(tkwin,
                             &grad->colors_in[first_color-1],
                             &grad->colors_in[first_color],
                             &grad->actual_colors[0],
                             NULL,
                             minx100, minx100, span100);
    j++;
  }
  else if ((first_color == 0) && (grad->type != ZN_RADIAL_GRADIENT)) {
    grad->actual_colors[0] = grad->colors_in[0];
    grad->actual_colors[0].rgb = Tk_GetColorByValue(tkwin, grad->colors_in[0].rgb);
    if (grad->colors_in[0].mid_rgb) {
      grad->actual_colors[0].mid_rgb = Tk_GetColorByValue(tkwin, grad->colors_in[0].mid_rgb);
    }
    grad->actual_colors[0].position = 0;
    grad->actual_colors[0].control = 50;
    j++;
    /*printf("adding a color at start\n");*/
  }

  //printf("j: %d, first color: %d, last color: %d, num colors: %d\n",
    //     j, first_color, last_color, grad->num_actual_colors);
  for (i = first_color; i <= last_color; i++, j++) {
    grad->actual_colors[j] = grad->colors_in[i];
    grad->actual_colors[j].rgb = Tk_GetColorByValue(tkwin, grad->colors_in[i].rgb);
    if (grad->colors_in[i].mid_rgb) {
      grad->actual_colors[j].mid_rgb = Tk_GetColorByValue(tkwin, grad->colors_in[i].mid_rgb);
    }
    grad->actual_colors[j].position = (grad->colors_in[i].position-minx100)*100/span100;
    /*printf("i: %d, j: %d, minx: %d, span: %d, position av: %d position ap: %d\n",
      i, j, minx100, span100, grad->colors_in[i].position, grad->actual_colors[j].position);*/
  }

  if (interpolate_last) {
    //printf("Interpolate last color: %d, j :%d\n", last_color, j);
    InterpolateGradientColor(tkwin,
                             &grad->colors_in[last_color],
                             &grad->colors_in[last_color+1],
                             &grad->actual_colors[j],
                             &grad->actual_colors[j-1],
                             maxx100, minx100, span100);
  }
  else if (last_color == ((int) grad->num_colors_in)-1) {
    i = grad->num_colors_in-1;
    //printf("i: %d, j: %d\n", i, j);
    grad->actual_colors[j] = grad->colors_in[i];
    grad->actual_colors[j].rgb = Tk_GetColorByValue(tkwin, grad->colors_in[i].rgb);
    if (grad->colors_in[i].mid_rgb) {
      grad->actual_colors[j].mid_rgb = Tk_GetColorByValue(tkwin, grad->colors_in[i].mid_rgb);    
    }
    /*printf("adding a color at end\n");*/
  }
  grad->actual_colors[grad->num_actual_colors-1].position = 100;
  //printf("Out of ReduceGradient\n");
}


/*
 *--------------------------------------------------------------
 *
 * ZnGetGradient --
 *
 *      Create a data structure containing a range of colors
 *      used to display a gradient. 
 *
 *      The gradient should have the following syntax:
 *
 *      gradient := [graddesc|]color[|....|color]
 *        where the | are real characters not meta-syntax.
 *
 *      graddesc := =type args
 *        where type := axial | radial | path
 *
 *        If type = axial
 *              args := angle (0..360) | xs ys xe ye (reals)
 *
 *        The first form define the axial gradiant by its slope.
 *        With this syntax the gradient fits the whole shape.
 *        This is a backward compatible syntax.
 *        The second form specifies a vector which will be used
 *        to draw the gradient. The vector defines both the angle
 *        and the gradient area. Parts of the shape that lie before
 *        the vector origin are filled with the first color and
 *        parts that lie after the vector end are filled with the
 *        last color.
 *
 *        If type = radial or path
 *              args := xs ys [xe ye] (reals)
 *
 *        The vector specified by the 4 coordinates defines the
 *        gradient area.  Parts of the shape that lie before
 *        the vector origin are filled with the first color and
 *        parts that lie after the vector end are filled with the
 *        last color. The vector end may be omitted, in such case
 *        the gradient fits exactly the whole shape to be filled,
 *        this is backward compatible with older gradients.
 *        
 *      color := colorvalue | colorvalue position |
 *               colorvalue control position
 *        where position and control are in (0..100)
 *
 *      colorvalue := (colorname | #rgb | cievalue)[;alpha]
 *        where alpha is in (0..100)
 *
 * Results:
 *      The return value is a token for a data structure
 *      describing a gradient. This token may be passed
 *      to the drawing routines.
 *      If an error prevented the gradient from being created
 *      then NULL is returned and an error message will be
 *      left in interp.
 *
 * Side effects:
 *      Data structures, etc. are allocated.
 *      It is the caller's responsibility to eventually call
 *      ZnFreeGradient to release the resources.
 *
 *--------------------------------------------------------------
 */
ZnGradient *
ZnGetGradientByValue(ZnGradient *grad)
{
  grad->ref_count++;
  return grad;
}


static int
ParseRealList(const char *str,
              const char *stop,
              ZnReal     *list,
              int        max)
{
  int    num;
  char   *end;

  num = 0;
  while ((num < max) && (str != stop)) {
    list[num] = strtod(str, &end);
    if (end == str) {
      /* A syntax error occured, return a 0 count
       * as a hint for the caller.
       */
      return 0;
    }
    num++;
    str = end+strspn(end, " \t");
  }
  return num;
}

ZnGradient *
ZnGetGradient(Tcl_Interp        *interp,
              Tk_Window         tkwin,
              Tk_Uid            desc)
{
  #define SEGMENT_SIZE 64
  Tcl_HashEntry *hash;
  ZnGradient    *grad;
  unsigned int  i, j, nspace, num_colors;
  unsigned int  size, num_coords=0;
  char          type;
  char const    *scan_ptr, *next_ptr, *str_ptr;
  ZnReal        angle, position, control;
  ZnReal        coords[4];
  char          *color_ptr, *end, segment[SEGMENT_SIZE];
  ZnGradientColor *first, *last;
  XColor        color;
  int           new, red_range, green_range, blue_range;
  ZnBool        simple;

  //printf("ZnGetGradient : %s\n", desc);
  if (!desc || !*desc) {
    return NULL;
  }
  if (!initialized) {
    ColorInit();
  }
  
  /*
   * First, check to see if there's already a gradient that will work
   * for this request.
   */  
  desc = Tk_GetUid(desc);

  /*printf("get gradient: %s\n", desc);*/
  hash = Tcl_CreateHashEntry(&gradient_table, desc, &new);
  if (!new) {
    grad = (ZnGradient *) Tcl_GetHashValue(hash);
    grad->ref_count++;
    return grad;
  }

  /*
   * No satisfactory gradient exists yet.  Initialize a new one.
   */
  type = ZN_AXIAL_GRADIENT;
  angle = 0.0;
  /*
   * Skip the trailing spaces.
   */
  while (*desc == ' ') {
    desc++;
  }
  /*
   * Count the sections in the description. It should give
   * the number of colors plus may be the gradient description.
   */
  scan_ptr = desc;
  /*
   * If the first section is the gradient description, start color
   * counts up from zero.
   */
  num_colors = (*scan_ptr == '=') ? 0 : 1;
  while ((scan_ptr = strchr(scan_ptr, '|'))) {
    num_colors++;
    scan_ptr++;
  }
  if (num_colors == 0) {
    Tcl_AppendResult(interp, "gradient should have at least one color \"",
                     desc, "\",", NULL);
  grad_err1:
    Tcl_DeleteHashEntry(hash);
    /*printf("ZnGetGradient error : %s\n", desc);*/
    return NULL;
  }
  /*
   * Then look at the gradient type.
   */
  scan_ptr = desc;
  /*
   * next_ptr can't be NULL in the following code,
   * we checked that at least one color was specified
   * after the gradient description.
   */
  next_ptr = strchr(scan_ptr, '|');
  if (*scan_ptr == '=') {
    scan_ptr++;
    if ((*scan_ptr == 'a') && (strncmp(scan_ptr, "axial", 5) == 0)) {
      scan_ptr += 5;
      num_coords = ParseRealList(scan_ptr, next_ptr, coords, 4);
      if ((num_coords != 1) && (num_coords != 4)) {
      grad_err3:
        Tcl_AppendResult(interp, "invalid gradient parameter \"",
                         desc, "\",", NULL);
        goto grad_err1;
      }
      angle = (int) coords[0];
    }
    else if ((*scan_ptr == 'c') && (strncmp(scan_ptr, "conical", 7) == 0)) {
      scan_ptr += 7;
      type = ZN_CONICAL_GRADIENT;
      num_coords = ParseRealList(scan_ptr, next_ptr, coords, 4);
      if ((num_coords < 1) && (num_coords > 4)) {
        goto grad_err3;
      }
      angle = (int) coords[0];
    }
    else if (((*scan_ptr == 'r') && (strncmp(scan_ptr, "radial", 6) == 0)) ||
             ((*scan_ptr == 'p') && (strncmp(scan_ptr, "path", 4) == 0))) {
      if (*scan_ptr == 'r') {
        type = ZN_RADIAL_GRADIENT;
        scan_ptr += 6;
      }
      else {
        type = ZN_PATH_GRADIENT;
        scan_ptr += 4;
      }
      num_coords = ParseRealList(scan_ptr, next_ptr, coords, 4);
      if ((num_coords != 2) && (num_coords != 4)) {
        goto grad_err3;
      }
    }
    else {
      Tcl_AppendResult(interp, "invalid gradient type \"",
                       desc, "\"", NULL);
      goto grad_err1;
    }
    scan_ptr = next_ptr + 1;
    next_ptr = strchr(scan_ptr, '|');
  }
  
  /*
   * Create the gradient structure.
   */
  grad = (ZnGradient *) ZnMalloc(sizeof(ZnGradient) +
                                 sizeof(ZnGradientColor)*(num_colors-1));
  grad->ref_count = 1;
  simple = True;
  grad->num_colors_in = num_colors;
  grad->type = type;
  grad->p.x = grad->p.y = grad->e.x = grad->e.y = 0.0;
  grad->angle = 0;

  switch (type) {
  case ZN_AXIAL_GRADIENT:
    if ((num_coords == 4) &&
        ((coords[0] != coords[2]) || (coords[1] != coords[3]))) {
      grad->p.x = coords[0];
      grad->p.y = coords[1];
      simple = False;
      grad->e.x = coords[2];
      grad->e.y = coords[3];
    }
    else {
      grad->angle = (int) angle;
    }
    break;
  case ZN_CONICAL_GRADIENT:
    if ((num_coords == 4) &&
        ((coords[0] != coords[2]) || (coords[1] != coords[3]))) {
      grad->p.x = coords[0];
      grad->p.y = coords[1];
      simple = False;
      grad->e.x = coords[2];
      grad->e.y = coords[3];
    }
    else if (num_coords == 2) {
      grad->p.x = coords[0];
      grad->p.y = coords[1];
    }
    else if (num_coords == 3) {
      grad->p.x = coords[0];
      grad->p.y = coords[1];
      grad->angle = (int) coords[2];
    }
    else {
      grad->angle = (int) angle;
    }
    break;
  case ZN_RADIAL_GRADIENT:
    grad->p.x = coords[0];
    grad->p.y = coords[1];
    if ((num_coords == 4) &&
        ((coords[0] != coords[2]) || (coords[1] != coords[3])))  {
      simple = False;
      grad->e.x = coords[2];
      grad->e.y = coords[3];
    }
    break;
  case ZN_PATH_GRADIENT:
    grad->p.x = coords[0];
    grad->p.y = coords[1];
    break;
  }
  grad->hash = hash;
  Tcl_SetHashValue(hash, grad);
  
  for (i = 0; i < num_colors; i++) {
    grad->colors_in[i].alpha = 100;
    /*
     * Try to parse the color name.
     */
    nspace = strspn(scan_ptr, " \t");   
    scan_ptr += nspace;
    str_ptr = strpbrk(scan_ptr, " \t|");
    if (str_ptr) {
      size = str_ptr - scan_ptr;
    }
    else {
      size = strlen(scan_ptr);
    }
    if (size > (SEGMENT_SIZE-1)) {
      Tcl_AppendResult(interp, "color name too long in gradient \"",
                       desc, "\",", NULL);
    grad_err2:
      for (j = 0; j < i; j++) {
        Tk_FreeColor(grad->colors_in[j].rgb);
      }
      ZnFree(grad);
      goto grad_err1;
    }
    strncpy(segment, scan_ptr, size);
    segment[size] = 0;
    scan_ptr += size;
    /*
     * Try to parse the color position.
     */
    grad->colors_in[i].position = 0;
    grad->colors_in[i].control = 50;
    position = strtod(scan_ptr, &end);
    if (end != scan_ptr) {
      grad->colors_in[i].position = (int) position;
      scan_ptr = end;
      /*
       * Try to parse the control point
       */
      control = strtod(scan_ptr, &end);
      if (end != scan_ptr) {
        grad->colors_in[i].control = (int) control;
        scan_ptr = end;
      }
    }
    nspace = strspn(scan_ptr, " \t");
    if ((scan_ptr[nspace] != 0) && (scan_ptr+nspace != next_ptr)) {
      Tcl_AppendResult(interp, "incorrect color description in gradient \"",
                       desc, "\",", NULL);
      goto grad_err2;
    }
    
    color_ptr = strchr(segment, ';');
    if (color_ptr) {
      *color_ptr = 0;
    }
    grad->colors_in[i].rgb = Tk_GetColor(interp, tkwin, Tk_GetUid(segment));
    if (grad->colors_in[i].rgb == NULL) {
      Tcl_AppendResult(interp, "incorrect color value in gradient \"",
                       desc, "\",", NULL);
      goto grad_err2;
    }
    if (color_ptr) {
      color_ptr++;
      grad->colors_in[i].alpha = atoi(color_ptr);
    }
    if (i == 0) {
      grad->colors_in[i].position = 0;
    }
    else if (i == num_colors - 1) {
      grad->colors_in[i].position = 100;
    }
    if ((i > 0) &&
        ((grad->colors_in[i].position > 100) ||
         (grad->colors_in[i].position < grad->colors_in[i-1].position))) {
      Tcl_AppendResult(interp, "incorrect color position in gradient \"",
                       desc, "\",", NULL);
      goto grad_err2;
    }
    if (grad->colors_in[i].control > 100) {
      grad->colors_in[i].control = 100;
    }
    if (grad->colors_in[i].alpha > 100) {
      grad->colors_in[i].alpha = 100;
    }
    if (next_ptr) {
      scan_ptr = next_ptr + 1;
      next_ptr = strchr(scan_ptr, '|');
    }
  }

  /*
   * Compute the mid alpha and mid color values. These will be
   * used by the gradient rendering primitives when a control
   * is not at mid range. The last color has no mid_* values.
   */
  for (i = 0; i < grad->num_colors_in-1; i++) {
    first = &grad->colors_in[i];
    last = &grad->colors_in[i+1];
    red_range = (int) last->rgb->red - (int) first->rgb->red;
    green_range = (int) last->rgb->green - (int) first->rgb->green;
    blue_range = (int) last->rgb->blue - (int) first->rgb->blue;
    color.red =(int) first->rgb->red +  red_range/2;
    color.green = (int) first->rgb->green + green_range/2;
    color.blue = (int) first->rgb->blue + blue_range/2;
    first->mid_rgb = Tk_GetColorByValue(tkwin, &color);
    first->mid_alpha = first->alpha + (last->alpha-first->alpha)/2;
  }
  grad->colors_in[grad->num_colors_in-1].mid_rgb = NULL;

  /*
   * If the gradient is 'simple' ie. described by a single point
   * or an angle for axial gradients, the processing is finished.
   * If not, we have to reduce the gradient to a simple one by adding
   * or suppressing colors and adjusting the relative position of
   * each remaining color.
   */
  if (simple) {
    grad->num_actual_colors = grad->num_colors_in;
    grad->actual_colors = grad->colors_in;
  }
  else if (type != ZN_PATH_GRADIENT) {
    ReduceGradient(tkwin, grad);
  }

  //printf("num in: %d, num actual: %d\n", grad->num_colors_in,grad->num_actual_colors);
  //printf("ZnGetGradient end : %s\n", desc);
  return grad;
}


/*
 *--------------------------------------------------------------
 *
 * ZnNameOfGradient --
 *
 *      Given a gradient, return a textual string identifying
 *      the gradient.
 *
 * Results:
 *      The return value is the string that was used to create
 *      the gradient.
 *
 * Side effects:
 *      None.
 *
 *--------------------------------------------------------------
 */
char *
ZnNameOfGradient(ZnGradient     *grad)
{
  return (char *) grad->hash->key.words;
}


/*
 *--------------------------------------------------------------
 *
 * ZnFreeGradient --
 *
 *      This procedure is called when a gradient is no longer
 *      needed.  It frees the resources associated with the
 *      gradient.  After this call, the caller should never
 *      again use the gradient.
 *
 * Results:
 *      None.
 *
 * Side effects:
 *      Resources are freed.
 *
 *--------------------------------------------------------------
 */
void
ZnFreeGradient(ZnGradient       *grad)
{
  unsigned int  i;
  
  grad->ref_count--;
  if (grad->ref_count == 0) {
    Tcl_DeleteHashEntry(grad->hash);
    for (i = 0; i < grad->num_colors_in; i++) {
      Tk_FreeColor(grad->colors_in[i].rgb);
      if (grad->colors_in[i].mid_rgb) {
        Tk_FreeColor(grad->colors_in[i].mid_rgb);
      }
    }
    if (grad->actual_colors != grad->colors_in) {
      for (i = 0; i < grad->num_actual_colors; i++) {
        Tk_FreeColor(grad->actual_colors[i].rgb);
        if (grad->actual_colors[i].mid_rgb) {
          Tk_FreeColor(grad->actual_colors[i].mid_rgb);
        }
      }
      ZnFree(grad->actual_colors);
    }
    ZnFree(grad);
  }
}


/*
 *--------------------------------------------------------------
 *
 * ZnComposeAlpha --
 *
 *      This procedure takes two alpha values in percent and
 *      returns the composite value between 0 and 65535.
 *
 *--------------------------------------------------------------
 */
int
ZnComposeAlpha(unsigned short   alpha1,
               unsigned short   alpha2)
{
  return (alpha1*alpha2/100)*65535/100;
}
