/*
 * Field.c -- Implementation of fields.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : 
 *
 * $Id: Field.c,v 1.33 2005/10/18 09:32:23 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Item.h"
#include "Types.h"
#include "WidgetInfo.h"
#include "Draw.h"
#include "Geo.h"
#include "tkZinc.h"

#include <string.h>
#include <stdlib.h>


static const char rcsid[] = "$Id: Field.c,v 1.33 2005/10/18 09:32:23 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


#define FIELD_SENSITIVE_BIT     1
#define FIELD_VISIBLE_BIT       2
#define FILLED_BIT              4
#define TEXT_ON_TOP_BIT         8
#define CACHE_OK                16


/*
 * Field record.
 */
typedef struct _FieldStruct {
  /* Public data */
  ZnGradient    *color;
  ZnGradient    *fill_color;
  ZnGradient    *border_color;
  char          *text;
  ZnImage       image;
  ZnImage       tile;
  Tk_Font       font;
  unsigned short flags;
  ZnBorder      border_edges;
  Tk_Justify    alignment;
  ZnReliefStyle relief;
  ZnDim         relief_thickness;
  ZnAutoAlign   auto_alignment;
  
  /* Private data */
  ZnGradient    *gradient;
  ZnPoint       *grad_geo;
  short         orig_x;
  short         orig_y;
  short         corner_x;
  short         corner_y;
  int           insert_index;
#ifdef GL
  ZnTexFontInfo *tfi;
#endif
} FieldStruct, *Field;


/*
 * The -text, -image, -border, -relief, -visible and
 * -filled attributes set the ZN_COORDS_FLAG to update
 * the leader that might protude if not clipped by the text.
 */
static ZnAttrConfig field_attrs[] = {
  { ZN_CONFIG_ALIGNMENT, "-alignment", NULL,
    Tk_Offset(FieldStruct, alignment), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_AUTO_ALIGNMENT, "-autoalignment", NULL,
    Tk_Offset(FieldStruct, auto_alignment), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-backcolor", NULL,
    Tk_Offset(FieldStruct, fill_color), 0,
    ZN_DRAW_FLAG|ZN_BORDER_FLAG, False },
  { ZN_CONFIG_EDGE_LIST, "-border", NULL,
    Tk_Offset(FieldStruct, border_edges), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-bordercolor", NULL,
    Tk_Offset(FieldStruct, border_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-color", NULL,
    Tk_Offset(FieldStruct, color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-filled", NULL,
    Tk_Offset(FieldStruct, flags), FILLED_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-fillpattern", NULL,
    Tk_Offset(FieldStruct, tile), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_FONT, "-font", NULL,
    Tk_Offset(FieldStruct, font), 0, ZN_COORDS_FLAG|ZN_CLFC_FLAG, False },
  { ZN_CONFIG_IMAGE, "-image", NULL,
    Tk_Offset(FieldStruct, image), 0,
    ZN_COORDS_FLAG|ZN_CLFC_FLAG, False },
  { ZN_CONFIG_RELIEF, "-relief", NULL,
    Tk_Offset(FieldStruct, relief), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-reliefthickness", NULL,
    Tk_Offset(FieldStruct, relief_thickness), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(FieldStruct, flags),
    FIELD_SENSITIVE_BIT, ZN_REPICK_FLAG, False },
  { ZN_CONFIG_STRING, "-text", NULL,
    Tk_Offset(FieldStruct, text), 0, ZN_COORDS_FLAG|ZN_CLFC_FLAG, False },
  { ZN_CONFIG_IMAGE, "-tile", NULL,
    Tk_Offset(FieldStruct, tile), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(FieldStruct, flags), FIELD_VISIBLE_BIT, 
    ZN_COORDS_FLAG|ZN_CLFC_FLAG, False }, /* Keep ZN_COORDS_FLAG here */

  { ZN_CONFIG_END, NULL, NULL, 0, 0, 0, False }
};

static  void GetLabelBBox(ZnFieldSet field_set, ZnDim *w, ZnDim *h);



/*
 **********************************************************************************
 *
 * ComputeFieldAttachment --
 *      Compute the location/size of the field, computing attachments if any.
 * 
 **********************************************************************************
 */
static void
ComputeFieldAttachment(ZnFieldSet       field_set,
                       unsigned int     field,
                       ZnBBox           *field_bbox)
{
  
  ZnBBox        ref_bbox;
  ZnDim         real_width, real_height;
  unsigned int  ref_field, num_fields;
  char          x_attach, y_attach, x_dim, y_dim;
  short         width_spec, height_spec;
  int           x_spec, y_spec, icon_width=0, icon_height=0;
  Field         fptr;
  Tk_FontMetrics fm;

  /*printf("ComputeFieldAttachment in\n");*/
  fptr = &field_set->fields[field];
  if (ISSET(fptr->flags, CACHE_OK)) {
    field_bbox->orig.x = (ZnPos) fptr->orig_x;
    field_bbox->orig.y = (ZnPos) fptr->orig_y;
    field_bbox->corner.x = fptr->corner_x;
    field_bbox->corner.y = fptr->corner_y;
    /*printf("ComputeFieldAttachment in cache\n");*/
    return;
  }

  /*
   * Preset this field to a default position/size and pretend
   * its cache is ok to break any deadlocks.
   */
  fptr->orig_x = fptr->orig_y = 0;
  fptr->corner_x = fptr->corner_y = 0;
  field_bbox->orig.x = field_bbox->orig.y = 0;
  field_bbox->corner.x = field_bbox->corner.y = 0;
  SET(fptr->flags, CACHE_OK);

  num_fields = ZnLFNumFields(field_set->label_format);
  ZnLFGetField(field_set->label_format, field,
               &x_attach, &y_attach, &x_dim, &y_dim,
               &x_spec, &y_spec, &width_spec, &height_spec);
  
  /*
   * First try to compute the field size which may be a factor
   * of the field content (but not a factor of other fields).
   */
  if ((fptr->image != ZnUnspecifiedImage) &&
      ((x_dim == ZN_LF_DIM_ICON) || (y_dim == ZN_LF_DIM_ICON) ||
       (x_dim == ZN_LF_DIM_AUTO) || (y_dim == ZN_LF_DIM_AUTO))) {
    ZnSizeOfImage(fptr->image, &icon_width, &icon_height);
  }

  switch (x_dim) {
  case ZN_LF_DIM_FONT:
    real_width = (ZnDim) (width_spec*Tk_TextWidth(fptr->font, "N", 1)/100);
    break;
  case ZN_LF_DIM_ICON:
    real_width = (ZnDim) (width_spec*icon_width/100);
    break;
  case ZN_LF_DIM_AUTO:
    {
      int       len = 0;
      ZnDim     text_width;

      if (fptr->text) {
        len = strlen(fptr->text);
      }
      real_width = 0.0;
      if (fptr->image != ZnUnspecifiedImage) {
        real_width = (ZnDim) icon_width;
      }
      if (len) {
        /*
         * The 4 extra pixels are needed for border and padding.
         */
        text_width = (ZnDim) Tk_TextWidth(fptr->font, fptr->text, len) + 4;
        real_width = text_width < real_width ? real_width : text_width;
      }
      real_width += (ZnDim) width_spec;
      if (real_width < 0) {
        real_width = 0;
      }
      break;
    }
  case ZN_LF_DIM_LABEL:
    {
      ZnDim     lh;

      GetLabelBBox(field_set, &real_width, &lh);
      break;
    }
  case ZN_LF_DIM_PIXEL:
  default:
    real_width = (ZnDim) width_spec;
    break;
  }
  /*printf("field %d, width = %g\n", field, real_width);*/

  switch (y_dim) {
  case ZN_LF_DIM_FONT:
    {
      Tk_GetFontMetrics(fptr->font, &fm);
      real_height = (ZnDim) (height_spec*(fm.ascent + fm.descent)/100);
      break;
    }
  case ZN_LF_DIM_ICON:
    real_height = (ZnDim) (height_spec*icon_height/100);
    break;
  case ZN_LF_DIM_AUTO:
    {
      ZnDim     text_height;
      
      real_height = 0.0;
      if (fptr->image != ZnUnspecifiedImage) {
        real_height = (ZnDim) icon_height;
      }
      if (fptr->text && strlen(fptr->text)) {
        Tk_GetFontMetrics(fptr->font, &fm);
        text_height = (ZnDim) (fm.ascent + fm.descent);
        real_height = text_height < real_height ? real_height : text_height;
      }
      real_height += (ZnDim) height_spec;
      if (real_height < 0) {
        real_height = 0;
      }
      break;
    }
  case ZN_LF_DIM_LABEL:
    {
      ZnDim     lw;
      
      GetLabelBBox(field_set, &lw, &real_height);
      break;
    }
  case ZN_LF_DIM_PIXEL:
  default:
    real_height = (ZnDim) height_spec;
    break;
  }
  /*printf("field %d, height = %g\n", field, real_height);*/

  /*
   * Update the cache with the newly computed infos
   * (breaking of deadlocks).
   */
  field_bbox->corner.x = real_width;
  field_bbox->corner.y = real_height;
  fptr->corner_x = (short) real_width;
  fptr->corner_y = (short) real_height;

  /*
   * Then try to deduce the position, resolving any attachments
   * if needed.
   */
  
  /*
   * Do the x axis.
   */
  if (x_dim != ZN_LF_DIM_LABEL) {
    if (x_attach == ZN_LF_ATTACH_PIXEL) {
      field_bbox->orig.x = (ZnPos) x_spec;
      field_bbox->corner.x = field_bbox->orig.x + real_width;
    }
    else {
      ref_field = x_spec;
      field_bbox->orig.x = field_bbox->corner.x = 0;
      if (ref_field >= num_fields) {
        ZnWarning ("Attached (x) to an inexistant field geometry\n");
      }
      else {
        ComputeFieldAttachment(field_set, ref_field, &ref_bbox);
        switch (x_attach) {
        case ZN_LF_ATTACH_FWD:
          if (ISSET(field_set->fields[ref_field].flags, FIELD_VISIBLE_BIT)) {
            field_bbox->orig.x = ref_bbox.corner.x;
          }
          else {
            field_bbox->orig.x = ref_bbox.orig.x;
          }
          field_bbox->corner.x = field_bbox->orig.x + real_width;
          break;
        case ZN_LF_ATTACH_BWD:
          if (ISSET(field_set->fields[ref_field].flags, FIELD_VISIBLE_BIT)) {
            field_bbox->corner.x = ref_bbox.orig.x;
          }
          else {
            field_bbox->corner.x = ref_bbox.corner.x;
          }
          field_bbox->orig.x = field_bbox->corner.x - real_width;
          break;
        case ZN_LF_ATTACH_LEFT:
          field_bbox->orig.x = ref_bbox.orig.x;
          field_bbox->corner.x = field_bbox->orig.x + real_width;
          break;
        case ZN_LF_ATTACH_RIGHT:
          if (ISSET(field_set->fields[ref_field].flags, FIELD_VISIBLE_BIT)) {
            field_bbox->corner.x = ref_bbox.corner.x;
          }
          else {
            field_bbox->corner.x = ref_bbox.orig.x;
          }
          field_bbox->orig.x = field_bbox->corner.x - real_width;       
          break;
        }
      }
    }
    /*printf("field %d, x = %g\n", field, field_bbox->orig.x);*/
  }
  
  /*
   * Then the y axis.
   */
  if (y_dim != ZN_LF_DIM_LABEL) {
    if (y_attach == ZN_LF_ATTACH_PIXEL) {
      field_bbox->orig.y = (ZnPos) y_spec;
      field_bbox->corner.y = field_bbox->orig.y + real_height;
    }
    else {
      ref_field = y_spec;
      field_bbox->orig.y = field_bbox->corner.y = 0;
      if (ref_field >= num_fields) {
        ZnWarning ("Attached (y) to an inexistant field geometry\n");
      }
      else {
        ComputeFieldAttachment(field_set, ref_field, &ref_bbox);
        switch (y_attach) {
        case ZN_LF_ATTACH_FWD:
          if (ISSET(field_set->fields[ref_field].flags, FIELD_VISIBLE_BIT)) {
            field_bbox->orig.y = ref_bbox.corner.y;
          }
          else {
            field_bbox->orig.y = ref_bbox.orig.y;
          }
          field_bbox->corner.y = field_bbox->orig.y + real_height;
          break;
        case ZN_LF_ATTACH_BWD:
          if (ISSET(field_set->fields[ref_field].flags, FIELD_VISIBLE_BIT)) {
            field_bbox->corner.y = ref_bbox.orig.y;
          }
          else {
            field_bbox->corner.y = ref_bbox.corner.y;
          }
          field_bbox->orig.y = field_bbox->corner.y - real_height;
          break;
        case ZN_LF_ATTACH_LEFT:
          field_bbox->orig.y = ref_bbox.orig.y;
          field_bbox->corner.y = field_bbox->orig.y + real_height;
          break;
        case ZN_LF_ATTACH_RIGHT:
          if (ISSET(field_set->fields[ref_field].flags, FIELD_VISIBLE_BIT)) {
            field_bbox->corner.y = ref_bbox.corner.y;
          }
          else {
            field_bbox->corner.y = ref_bbox.orig.y;
          }
          field_bbox->orig.y = field_bbox->corner.y - real_height;      
          break;
        }
      }
    }
    /*printf("field %d, y = %g\n", field, field_bbox->orig.y);*/
  }
  
  fptr->orig_x = (short) field_bbox->orig.x;
  fptr->orig_y = (short) field_bbox->orig.y;
  fptr->corner_x = (short) field_bbox->corner.x;
  fptr->corner_y = (short) field_bbox->corner.y;
  SET(fptr->flags, CACHE_OK);

  /*printf("ComputeFieldAttachment out\n");*/
}


/*
 **********************************************************************************
 *
 * ClearFieldCache --
 *      Reset the geometric cache of all fields depending on a given field (or
 *      of all fields if the field is < 0). Clear also the label bounding box
 *      cache if some action has been taken on a field.
 * 
 **********************************************************************************
 */
static void
ClearFieldCache(ZnFieldSet      field_set,
                int             field)
{
  unsigned int  i, num_fields; 
  ZnBool        clear_bbox;
  int           x_spec, y_spec;
  char          x_attach, y_attach, x_dim, y_dim;
  short         width_spec, height_spec;

  if (!field_set->num_fields) {
    return;
  }
  if (field < 0) {
    for (i = 0; i < field_set->num_fields; i++) {
      CLEAR(field_set->fields[i].flags, CACHE_OK);
    }
    field_set->label_width = field_set->label_height = -1.0;
    return;
  }

  clear_bbox = False;
  if (!field_set->label_format) {
    return;
  }
  num_fields = ZnLFNumFields(field_set->label_format);
  if ((unsigned int) field >= num_fields) {
    return;
  }
  ZnLFGetField(field_set->label_format, (unsigned int) field,
               &x_attach, &y_attach, &x_dim, &y_dim,                  
               &x_spec, &y_spec, &width_spec, &height_spec);
  if ((x_dim != ZN_LF_DIM_PIXEL) || (y_dim != ZN_LF_DIM_PIXEL)) {
    CLEAR(field_set->fields[field].flags, CACHE_OK);
    clear_bbox = True;
  }
  for (i = 0; i < num_fields; i++) {
    ZnLFGetField(field_set->label_format, i,
                 &x_attach, &y_attach, &x_dim, &y_dim,
                 &x_spec, &y_spec, &width_spec, &height_spec);
    if ((x_attach == ZN_LF_ATTACH_PIXEL) && (y_attach == ZN_LF_ATTACH_PIXEL)) {
      continue;
    }
    if (x_attach != ZN_LF_ATTACH_PIXEL) {
      if ((x_spec == field) && ISSET(field_set->fields[i].flags, CACHE_OK)) {
        CLEAR(field_set->fields[i].flags, CACHE_OK);
        ClearFieldCache(field_set, (int) i);
        clear_bbox = True;
      }
    }
    if (y_attach != ZN_LF_ATTACH_PIXEL) {
      if ((y_spec == field) && ISSET(field_set->fields[i].flags, CACHE_OK)) {
        CLEAR(field_set->fields[i].flags, CACHE_OK);
        ClearFieldCache(field_set, (int) i);
        clear_bbox = True;
      }
    }
  }

  if (clear_bbox) {
    field_set->label_width = field_set->label_height = -1.0;
  }
}


/*
 **********************************************************************************
 *
 * GetLabelBBox --
 * 
 **********************************************************************************
 */
static void
GetLabelBBox(ZnFieldSet field_set,
             ZnDim      *w,
             ZnDim      *h)
{
  ZnBBox        bbox, tmp_bbox;
  ZnLabelFormat lf;
  unsigned int  i, num_fields;
  ZnDim         clip_w, clip_h;
  
  /*printf("GetLabelBBox in\n");*/
  if ((field_set->label_width >= 0.0) && (field_set->label_height >= 0.0)) {
    *w = field_set->label_width;
    *h = field_set->label_height;
    /*printf("GetLabelBBox in cache\n");*/
    return;
  }

  lf = field_set->label_format;
  if (lf == NULL) {
    *w = *h = field_set->label_width = field_set->label_height = 0.0;
    /*printf("GetLabelBBox no labelformat\n");*/
    return;
  }

  ZnResetBBox(&bbox);
  num_fields = ZnLFNumFields(lf);
  for (i = 0; i < num_fields; i++) {
    ComputeFieldAttachment(field_set, i, &tmp_bbox);
    /*printf("field %d bbox %g %g %g %g\n", i, tmp_bbox.orig.x, tmp_bbox.orig.y,
      tmp_bbox.corner.x, tmp_bbox.corner.y);*/
    ZnAddBBoxToBBox(&bbox, &tmp_bbox);
  }
  field_set->label_width = bbox.corner.x;
  field_set->label_height = bbox.corner.y;

  /*printf("GetLabelBBox size before clipping; w = %g, h = %g\n",
         field_set->label_width, field_set->label_height);*/
  if (ZnLFGetClipBox(lf, &clip_w, &clip_h)) {
    if (clip_w < field_set->label_width) {
      field_set->label_width = clip_w;
    }
    if (clip_h < field_set->label_height) {
      field_set->label_height = clip_h;
    }
  }
  
  *w = field_set->label_width;
  *h = field_set->label_height;
  /*printf("GetLabelBBox returns computed size; w = %g, h = %g\n", *w, *h);*/
}


/*
 **********************************************************************************
 *
 * GetFieldBBox --
 *      Compute the location of the field described
 *      by the field entry index in the item current LabelFormat.
 * 
 **********************************************************************************
 */
static void
GetFieldBBox(ZnFieldSet         field_set,
             unsigned int       index,
             ZnBBox             *field_bbox)
{
  ZnReal        ox, oy;
  
  /*printf("GetFieldBBox in\n");*/
  if (field_set->label_format) {
    ox = ZnNearestInt(field_set->label_pos.x);
    oy = ZnNearestInt(field_set->label_pos.y);
    ComputeFieldAttachment(field_set, index, field_bbox);
    field_bbox->orig.x += ox;
    field_bbox->orig.y += oy;
    field_bbox->corner.x += ox;
    field_bbox->corner.y += oy;
  }
  else {
    ZnResetBBox(field_bbox);
  }
  /*printf("GetFieldBBox out\n");*/
}


/*
 **********************************************************************************
 *
 * ComputeFieldTextLocation -- 
 *      Compute the position of the text in a field. This is a position
 *      that we can give to XDrawText. The position is deduced from the
 *      field bounding box passed in bbox.
 *      Return also the text bounding box.
 *
 **********************************************************************************
 */
static void
ComputeFieldTextLocation(Field          fptr,
                         ZnBBox         *bbox,
                         ZnPoint        *pos,
                         ZnBBox         *text_bbox)
{
  ZnDim         w, h;
  Tk_FontMetrics fm;

  Tk_GetFontMetrics(fptr->font, &fm);
  w = 0;
  if (fptr->text) {
    int width;
    Tk_MeasureChars(fptr->font, fptr->text, strlen(fptr->text), -1, 0, &width);
    w = width;
  }
  h = fm.ascent + fm.descent;
  text_bbox->orig.y = (bbox->orig.y + bbox->corner.y - h) / 2.0;
  text_bbox->corner.y = text_bbox->orig.y + h;
  pos->y = text_bbox->orig.y + fm.ascent;
  
  switch (fptr->alignment) {
  case TK_JUSTIFY_LEFT:
    text_bbox->orig.x = bbox->orig.x + 2;
    break;
  case TK_JUSTIFY_RIGHT:
    text_bbox->orig.x = bbox->corner.x - w - 2;
    break;
  default:
    text_bbox->orig.x = ZnNearestInt((bbox->orig.x + bbox->corner.x - w) / 2.0);
    break;
  }
  text_bbox->corner.x = text_bbox->orig.x + w;
  pos->x = text_bbox->orig.x;
}


/*
 **********************************************************************************
 *
 * LeaderToLabel --
 *      Compute the segment part of segment <start, end> that lies
 *      outside the fields of item.
 *
 **********************************************************************************
 */
static void
LeaderToLabel(ZnFieldSet        field_set,
              ZnPoint   *start,
              ZnPoint   *end)
{
  int           b_num;
  ZnPoint       delta, inf, sup;
  ZnPos         xt=0, yu=0, yw=0, xv=0;
  Field         fptr;
  unsigned int  i;
  ZnBBox        field_bbox;

  /* Intersection points :                                              */
  /*   T |xt / delta_y  U |x1           V |y1           W |yw / delta_x */
  /*     |y2              |yu / delta_x   |xv / delta_y   |x2           */
  /*                                            */
  /* y = ax + b;                                */
  /* a = delta_y / delta_x                      */
  /* b = (y * delta_x - x * delta_y) / delta_x  */

  delta.x = start->x - end->x;
  delta.y = start->y - end->y;
  b_num   = (int) (start->y*delta.x - start->x*delta.y);
  
  for (i = 0; i < ZnLFNumFields(field_set->label_format); i++) {
    fptr = &field_set->fields[i];
    /*
     * If the field is made invisible or has no graphics of
     * its own, don't clip.
     */
    if (ISCLEAR(fptr->flags, FIELD_VISIBLE_BIT) ||
        (!fptr->text &&
         ISCLEAR(fptr->flags, FILLED_BIT) &&
         (fptr->border_edges == ZN_NO_BORDER) &&
         (fptr->relief == ZN_RELIEF_FLAT) &&
         (fptr->image == ZnUnspecifiedImage))) {
      continue;
    }

    /*
     * field_bbox is in absolute device coordinates.
     */
    GetFieldBBox(field_set, i, &field_bbox);

    /*
     * Adjust leader on real text, not on field boundaries. This is
     * important when there are leading and trailing spaces.
     */
    if (fptr->text &&
        ISCLEAR(fptr->flags, FILLED_BIT) &&
        (fptr->border_edges == ZN_NO_BORDER) &&
        (fptr->relief == ZN_RELIEF_FLAT) &&
        (fptr->image == ZnUnspecifiedImage)) {
      ZnBBox   text_bbox;
      ZnPoint  text_pos;        /* dummy */
      int      space_width;
      int      scan_forw, scan_back;
      space_width = Tk_TextWidth(fptr->font, " ", 1);

      ComputeFieldTextLocation(fptr, &field_bbox, &text_pos, &text_bbox);
      /*
       * Correct adjusments made by ComputeFieldTextLocation (Vincent Pomey).
       *
       * PLC: IMHO, this is to compensate for exotic fonts like 'symbolesATC'.
       *      I am not planning to port this to Tk for two reasons:
       *          1/ Current positions are no longer implemented as characters
       *      and 2/ Tk does not give access (easily) to lbearings and rbearings.
       * This patch has been contributed by Phidias team. I don't know the
       * problem it was meant to solve.
       * text_bbox.x -= fptr->font->per_char[fptr->text[0]].lbearing + 3;
       * text_bbox.width += fptr->font->per_char[fptr->text[0]].lbearing + 3;
       */
      /*
       * Change bbox according to leading and trailing spaces.
       */
      scan_forw = 0;
      while (fptr->text[scan_forw] == ' ') {
        /* leading spaces */
        text_bbox.orig.x += space_width;
        scan_forw++;
      }

      /*
       * Empty text.
       */
      if (!fptr->text || (fptr->text[scan_forw] == 0)) {
        continue;
      }
      
      scan_back = strlen(fptr->text)-1;
      while ((fptr->text[scan_back] == ' ') && (scan_back > scan_forw)) {
        /* trailing spaces */
        text_bbox.corner.x -= space_width;
        scan_back--;
      }

      field_bbox = text_bbox;
    }

    if (field_bbox.corner.x <= field_bbox.orig.x) {
      continue;
    }
    
    if ((start->x >= field_bbox.orig.x) && (start->x < field_bbox.corner.x) &&
        (start->y >= field_bbox.orig.y) && (start->y < field_bbox.corner.y)) {
      end->x = start->x;
      end->y = start->y;
    }
    if (delta.x) {
      yu = (field_bbox.orig.x*delta.y + b_num) / delta.x;
      yw = (field_bbox.corner.x*delta.y + b_num) / delta.x;
    }
    if (delta.y) {
      xt = (field_bbox.corner.y*delta.x - b_num) / delta.y;
      xv = (field_bbox.orig.y*delta.x - b_num) / delta.y;
    }
    
    inf.x = MIN(start->x, end->x);
    sup.x = MAX(start->x, end->x);
    inf.y = MIN(start->y, end->y);
    sup.y = MAX(start->y, end->y);
    
    if (delta.x) {
      if ((yu >= field_bbox.orig.y) && (yu <= field_bbox.corner.y) &&
          (field_bbox.orig.x >= inf.x) && (field_bbox.orig.x <= sup.x) &&
          (yu >= inf.y) && (yu <= sup.y)) {
        end->x = field_bbox.orig.x;
        end->y = yu;
        inf.x = MIN(start->x, end->x);
        sup.x = MAX(start->x, end->x);
        inf.y = MIN(start->y, end->y);
        sup.y = MAX(start->y, end->y);
      }
      if ((yw >= field_bbox.orig.y) && (yw <= field_bbox.corner.y) &&
          (field_bbox.corner.x >= inf.x) && (field_bbox.corner.x <= sup.x) &&
          (yw >= inf.y) && (yw <= sup.y)) {
        end->x = field_bbox.corner.x;
        end->y = yw;
        inf.x = MIN(start->x, end->x);
        sup.x = MAX(start->x, end->x);
        inf.y = MIN(start->y, end->y);
        sup.y = MAX(start->y, end->y);
      }
    }
    if (delta.y) {
      if ((xt >= field_bbox.orig.x) && (xt <= field_bbox.corner.x) &&
          (xt >= inf.x) && (xt <= sup.x) &&
          (field_bbox.corner.y >= inf.y) && (field_bbox.corner.y <= sup.y)) {
        end->x = xt;
        end->y = field_bbox.corner.y;
        inf.x = MIN(start->x, end->x);
        sup.x = MAX(start->x, end->x);
        inf.y = MIN(start->y, end->y);
        sup.y = MAX(start->y, end->y);
      }
      if ((xv >= field_bbox.orig.x) && (xv <= field_bbox.corner.x) &&
          (xv >= inf.x) && (xv <= sup.x) &&
          (field_bbox.orig.y >= inf.y) && (field_bbox.orig.y <= sup.y)) {
        end->x = xv;
        end->y = field_bbox.orig.y;
        inf.x = MIN(start->x, end->x);
        sup.x = MAX(start->x, end->x);
        inf.y = MIN(start->y, end->y);
        sup.y = MAX(start->y, end->y);
      }
    }
  }
}


/*
 **********************************************************************************
 *
 * InitFields --
 *
 *      Perform the init of each field in a ZnFieldSet. The number of such
 *      fields must have been inited before calling this fun.
 *
 **********************************************************************************
 */
static void
InitFields(ZnFieldSet   field_set)
{
  ZnWInfo               *wi = field_set->item->wi;
  Field                 field;
  unsigned int          i, num_fields;

  /*printf("size of a field = %d\n", sizeof(FieldStruct));*/
  
  if (!field_set->num_fields) {
    return;
  }
  num_fields = field_set->num_fields;
  field_set->fields = (Field) ZnMalloc(num_fields*sizeof(FieldStruct));

  for (i = 0; i < num_fields; i++){
    field = &field_set->fields[i];

    field->color = ZnGetGradientByValue(wi->fore_color);
    field->fill_color = ZnGetGradientByValue(wi->back_color);
    field->border_color = ZnGetGradientByValue(wi->fore_color);
    SET(field->flags, FIELD_VISIBLE_BIT);
    SET(field->flags, FIELD_SENSITIVE_BIT);
    CLEAR(field->flags, FILLED_BIT);
    CLEAR(field->flags, CACHE_OK);
    field->text = NULL;
    field->image = ZnUnspecifiedImage;
    field->tile = ZnUnspecifiedImage;
    field->font = Tk_GetFont(wi->interp, wi->win, Tk_NameOfFont(wi->font));
#ifdef GL
    field->tfi = ZnGetTexFont(wi, field->font);
#endif
    field->border_edges = ZN_NO_BORDER;
    field->alignment = TK_JUSTIFY_LEFT;
    field->auto_alignment.automatic = False;

    field->relief = ZN_RELIEF_FLAT;
    field->relief_thickness = 2;
    SET(field->flags, TEXT_ON_TOP_BIT);

    field->gradient = NULL;
    field->grad_geo = NULL;
  }
  field_set->label_pos.x = field_set->label_pos.y = 0.0;
  field_set->label_width = field_set->label_height = -1.0;
}


/*
 **********************************************************************************
 *
 * CloneFields --
 *
 **********************************************************************************
 */
static void
CloneFields(ZnFieldSet  field_set)
{
  ZnWInfo       *wi = field_set->item->wi;
  Field         field, fields_ret;
  unsigned int  i, num_fields;
  char          *text;

  num_fields = field_set->num_fields;
  if (!num_fields) {
    return;
  }
  if (field_set->label_format) {
    field_set->label_format = ZnLFDuplicate(field_set->label_format);
  }
  fields_ret = (Field) ZnMalloc(num_fields*sizeof(FieldStruct));
  memcpy(fields_ret, field_set->fields, num_fields*sizeof(FieldStruct));
  field_set->fields = fields_ret;
  
  for (i = 0; i < num_fields; i++) {
    field = &fields_ret[i];
    if (field->gradient) {
      field->gradient = ZnGetGradientByValue(field->gradient);
    }
    if (field->grad_geo) {
      ZnPoint *grad_geo = ZnMalloc(4*sizeof(ZnPoint));
      memcpy(grad_geo, field->grad_geo, 4*sizeof(ZnPoint));
      field->grad_geo = grad_geo;    
    }    
    if (field->image != ZnUnspecifiedImage) {
      field->image = ZnGetImageByValue(field->image, ZnUpdateItemImage, field_set->item);
    }
    if (field->tile != ZnUnspecifiedImage) {
      field->tile = ZnGetImageByValue(field->tile, ZnUpdateItemImage, field_set->item);
    }
    field->font = Tk_GetFont(wi->interp, wi->win, Tk_NameOfFont(field->font));
#ifdef GL
    field->tfi = ZnGetTexFont(wi, field->font);
#endif
    field->color = ZnGetGradientByValue(field->color);
    field->fill_color = ZnGetGradientByValue(field->fill_color);
    field->border_color = ZnGetGradientByValue(field->border_color);

    if (field->text) {
      text = (char *) ZnMalloc((strlen(field->text) + 1) * sizeof(char));
      strcpy(text, field->text);
      field->text = text;
    }
  }
}


/*
 **********************************************************************************
 *
 * ConfigureField -- 
 *
 **********************************************************************************
 */
static int
ConfigureField(ZnFieldSet       fs,
               int              field,
               int              argc,
               Tcl_Obj *CONST   argv[],
               int              *flags)
{
  unsigned int  i;
  Field         fptr;
  ZnBBox        bbox;
  ZnWInfo       *wi = fs->item->wi;
  XColor        *color;
  unsigned short alpha;
  int           old_num_chars, num_chars;
#ifdef GL
  Tk_Font       old_font;
#endif

  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    Tcl_AppendResult(wi->interp, "invalid field index", NULL);
    return TCL_ERROR;
  }
  
  fptr = &fs->fields[field];
#ifdef GL
  old_font = fptr->font;
#endif
  old_num_chars = 0;
  if (fptr->text) {
    old_num_chars = Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text));
  }

  if (ZnConfigureAttributes(wi, fs->item, fptr, field_attrs,
                            argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
  }

  num_chars = 0;
  if (fptr->text) {
    num_chars = Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text));
  }
  if (old_num_chars != num_chars) {
    ZnTextInfo *ti = &wi->text_info;
    /*
     * The text has changed, update the selection and
     * insertion pos to keep them valid.
     */
    if ((fs->item == ti->sel_item) && (field == ti->sel_field)) {
      if (ti->sel_last > num_chars) {
        ti->sel_last = num_chars;
      }
      if (ti->sel_first >= ti->sel_last) {
        ti->sel_item = ZN_NO_ITEM;
        ti->sel_field = ZN_NO_PART;
      }
      if ((ti->anchor_item == fs->item) && (ti->anchor_field == field) &&
          (ti->sel_anchor > num_chars)) {
        ti->sel_anchor = num_chars;
      }
    }
    if (fptr->insert_index > num_chars) {
      fptr->insert_index = num_chars;
    }
  }

#ifdef GL
  if (old_font != fptr->font) {
    if (fptr->tfi) {
      ZnFreeTexFont(fptr->tfi);
      fptr->tfi = ZnGetTexFont(wi, fptr->font);
    }
  }
#endif

  if (ISSET(*flags, ZN_REPICK_FLAG)) {
    SET(wi->flags, ZN_INTERNAL_NEED_REPICK);
  }
  if (ISSET(*flags, ZN_CLFC_FLAG)) {
    ClearFieldCache(fs, field);
  }
  
  if (fptr->gradient &&
      (ISSET(*flags, ZN_BORDER_FLAG) || (fptr->relief == ZN_RELIEF_FLAT))) {
    ZnFreeGradient(fptr->gradient);
    fptr->gradient = NULL;
  }
  if ((fptr->relief != ZN_RELIEF_FLAT) && !fptr->gradient) {
    color = ZnGetGradientColor(fptr->border_color, 51.0, &alpha);
    fptr->gradient = ZnGetReliefGradient(wi->interp, wi->win,
                                              Tk_NameOfColor(color), alpha);
    if (fptr->gradient == NULL) {
      return TCL_ERROR;      
    }
  }

  /*
   * This is done here to limit the redraw to the area of the
   * modified fields.
   */
  if (ISCLEAR(*flags, ZN_COORDS_FLAG) &&
      fs->label_format && ISSET(*flags, ZN_DRAW_FLAG)) {
    for (i = 0; i < ZnLFNumFields(fs->label_format); i++) {
      if (i == (unsigned int) field) {
        GetFieldBBox(fs, i, &bbox);
        ZnDamage(wi, &bbox);
        break;
      }
    }
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * QueryField --
 *
 **********************************************************************************
 */
static int
QueryField(ZnFieldSet           fs,
           int                  field,
           int                  argc,
           Tcl_Obj *CONST       argv[])
{
  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    Tcl_AppendResult(fs->item->wi->interp, "invalid field index \"", NULL);
    return TCL_ERROR;
  }
    
  if (ZnQueryAttribute(fs->item->wi->interp, &fs->fields[field], field_attrs,
                       argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }
  
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * FreeFields --
 *
 **********************************************************************************
 */
static void
FreeFields(ZnFieldSet   field_set)
{
  unsigned int  i, num_fields;
  Field         field;

  if (field_set->label_format) {
    ZnLFDelete(field_set->label_format);
  }
  
  num_fields = field_set->num_fields;
  for (i = 0; i < num_fields; i++) {
    field = &field_set->fields[i];
    
    if (field->text) {
      ZnFree(field->text);
    }
    if (field->gradient) {
      ZnFreeGradient(field->gradient);
    }
    if (field->grad_geo) {
      ZnFree(field->grad_geo);
    }
    if (field->image != ZnUnspecifiedImage) {
      ZnFreeImage(field->image, ZnUpdateItemImage, &field->image);
      field->image = ZnUnspecifiedImage;
    }
    if (field->tile != ZnUnspecifiedImage) {
      ZnFreeImage(field->tile, ZnUpdateItemImage, &field->tile);
      field->tile = ZnUnspecifiedImage;
    }
    Tk_FreeFont(field->font);
#ifdef GL
    if (field->tfi) {
      ZnFreeTexFont(field->tfi);
    }
#endif
    ZnFreeGradient(field->color);
    ZnFreeGradient(field->fill_color);
    ZnFreeGradient(field->border_color);
  }
  if (num_fields) {
    ZnFree(field_set->fields);
  }
}


/*
 **********************************************************************************
 *
 * FieldIndex,
 * FieldInsertChars,
 * FieldDeleteChars,
 * FieldCursor,
 * FieldSelection --
 *      These functions implement text edition in fields. The behavior
 * is the same as for Text items.
 *
 **********************************************************************************
 */
static int
FieldPointToChar(ZnFieldSet     fs,
                 unsigned int   field,
                 int            x,
                 int            y)
{
  Field         fptr;
  int           byte_index;
  ZnBBox        f_bbox, t_bbox;
  ZnPoint       t_orig;
  unsigned int  num_bytes, n, dummy;

  fptr = &fs->fields[field];
  num_bytes = 0;
  byte_index = 0;
  if (fptr->text) {
    num_bytes = strlen(fptr->text);
  }

  if (num_bytes == 0) {
    return 0;
  }
  
  GetFieldBBox(fs, field, &f_bbox);
  ComputeFieldTextLocation(fptr, &f_bbox, &t_orig, &t_bbox);

  /*
   * Point above text, returns index 0.
   */
  if (y < t_bbox.orig.y) {
    return 0;
  }
  
  if (y < t_bbox.corner.y) {
    if (x < t_bbox.orig.x) {
      /*
       * Point to the left of the current line, returns
       * index of first char.
       */
      return 0;
    }
    if (x >= t_bbox.corner.x) {
      /*
       * Point to the right of the current line, returns
       * index past the last char.
       */
      byte_index = num_bytes;
      goto convrt;
    }
    n = Tk_MeasureChars(fptr->font, fptr->text, num_bytes,
                        x + 2 - (int) t_bbox.orig.x, TK_PARTIAL_OK, &dummy);
    byte_index = n - 1;
    goto convrt;
  }
  /*
   * Point below all lines, return the index after
   * the last char.
   */ 
  byte_index = num_bytes;
 convrt:
  return Tcl_NumUtfChars(fptr->text, byte_index);
}

static int
WordMoveFromIndex(char  *text,
                  int   index,
                  int   fwd)
{
  char const *strp;

  if (!text) {
    return index;
  }

  strp = Tcl_UtfAtIndex(text, index);
  if (fwd) {
    while ((strp[1] == ' ') || (strp[1] == '\n')) {
      strp++;
    }
    while ((strp[1] != ' ') && (strp[1] != '\n') && strp[1]) {
      strp++;
    }
    return Tcl_NumUtfChars(text, strp + 1 - text);
  }
  else {
    while ((strp != text) && ((strp[-1] == ' ') || (strp[-1] == '\n'))) {
      strp--;
    }
    while ((strp != text) && (strp[-1] != ' ') && (strp[-1] != '\n')) {
      strp--;
    }
    return Tcl_NumUtfChars(text, strp - text);
  }
}

static int
FieldIndex(ZnFieldSet   fs,
           int          field,
           Tcl_Obj      *index_spec,
           int          *index)
{
  Field         fptr;
  ZnWInfo       *wi = fs->item->wi;
  ZnTextInfo    *ti = &wi->text_info;
  unsigned int  length;
  int           c, x, y;
  double        tmp;
  char          *end, *p;

  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    *index = 0;
    return TCL_OK;
  }

  fptr = &fs->fields[field];

  p = Tcl_GetString(index_spec);
  c = p[0];
  length = strlen(p);
  
  if ((c == 'e') && (strncmp(p, "end", length) == 0)) {
    *index = fptr->text ? Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text)) : 0;
  }
  else if ((c == 'e') && (length > 1) && (strncmp(p, "eol", length) == 0)) {
    *index = fptr->text ? Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text)) : 0;
  }
  else if ((c == 'b') && (length > 1) && (strncmp(p, "bol", length) == 0)) {
    *index = 0;
  }
  else if ((c == 'e') && (length > 1) && (strncmp(p, "eow", length) == 0)) {
    *index = WordMoveFromIndex(fptr->text, fptr->insert_index, 1);
  }
  else if ((c == 'b') && (length > 1) && (strncmp(p, "bow", length) == 0)) {
    *index = WordMoveFromIndex(fptr->text, fptr->insert_index, 0);
  }
  else if ((c == 'u') && (strncmp(p, "up", length) == 0)) {
    *index = fptr->insert_index;
  }
  else if ((c == 'd') && (strncmp(p, "down", length) == 0)) {
    *index = fptr->insert_index;
  }
  else if ((c == 'i') && (strncmp(p, "insert", length) == 0)) {
    *index = fptr->insert_index;
  }
  else if ((c == 's') && (strncmp(p, "sel.first", length) == 0) &&
           (length >= 5)) {
    if ((ti->sel_item != fs->item) || (ti->sel_field != field)) {
    sel_err:
      Tcl_AppendResult(wi->interp, "selection isn't in field", (char *) NULL);
      return TCL_ERROR;
    }
    *index = ti->sel_first;
  }
  else if ((c == 's') && (strncmp(p, "sel.last", length) == 0) &&
           (length >= 5)) {
    if ((ti->sel_item != fs->item) || (ti->sel_field != field)) {
      goto sel_err;
    }
    /*
     * We return a modified selection end so that it reflect
     * the text index of the last character _not_ the insertion
     * point between the last and the next.
     */
    *index = ti->sel_last-1;
  }
  else if (c == '@') {
    p++;
    tmp = strtod(p, &end);
    if ((end == p) || (*end != ',')) {
      goto badIndex;
    }
    x = (int) tmp;
    p = end+1;
    tmp = strtod(p, &end);
    if ((end == p) || (*end != 0)) {
      goto badIndex;
    }
    y = (int) tmp;
    
    *index = FieldPointToChar(fs, (unsigned int) field, x, y);
  }
  else if (Tcl_GetIntFromObj(wi->interp, index_spec, index) == TCL_OK) {
    int num_chars = fptr->text ? Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text)) : 0;
    if (*index < 0){
      *index = 0;
    }
    else if (*index > num_chars) {
      *index = num_chars;
    }
  }
  else {
  badIndex:
    Tcl_AppendResult(wi->interp, "bad index \"", p, "\"", (char *) NULL);
    return TCL_ERROR;
  }
  
  return TCL_OK;  
}

static ZnBool
FieldInsertChars(ZnFieldSet     fs,
                 int            field,
                 int            *index,
                 char           *chars)
{
  Field          fptr;
  ZnTextInfo    *ti = &fs->item->wi->text_info;
  int           num_chars, num_bytes, chars_added;
  unsigned int  byte_index, bytes_added = strlen(chars);
  char          *new;

  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    return False;
  }

  if (bytes_added == 0) {
    return False;
  }

  fptr = &fs->fields[field];
  num_chars = 0;
  num_bytes = 0;
  if (fptr->text) {
    num_bytes = strlen(fptr->text);
    num_chars = Tcl_NumUtfChars(fptr->text, num_bytes);
  }
  if (*index < 0) {
    *index = 0;
  }
  if (*index > num_chars) {
    *index = num_chars;
  }
  chars_added = Tcl_NumUtfChars(chars, (int) bytes_added);

  if (fptr->text) {
    byte_index = Tcl_UtfAtIndex(fptr->text, *index) - fptr->text;
    new = ZnMalloc(num_bytes + bytes_added + 1);
    /*
     * Copy the part before and the part after the new
     * text (if any).
     */
    memcpy(new, fptr->text, (size_t) byte_index);
    strcpy(new + byte_index + bytes_added, fptr->text + byte_index);
    ZnFree(fptr->text);
  }
  else {
    byte_index = 0;
    new = ZnMalloc(num_bytes + 1);
    new[num_bytes] = 0;
  }
  /*
   * Insert the new text.
   */
  memcpy(new + byte_index, chars, bytes_added);
  fptr->text = new;
  
  if (fptr->insert_index >= *index) {
    fptr->insert_index += chars_added;
  }
  if ((ti->sel_item == fs->item) && (ti->sel_field == field)) {
    if (ti->sel_first >= *index) {
      ti->sel_first += chars_added;
    }
    if (ti->sel_last >= *index) {
      ti->sel_last += chars_added;
    }
    if ((ti->anchor_item == fs->item) && (ti->anchor_field == field) &&
        (ti->sel_anchor >= *index)) {
      ti->sel_anchor += chars_added;
    }
  }

  /*
   * Need to redo the fields layout (maybe).
   */
  ClearFieldCache(fs, field);
  return True;
}

static ZnBool
FieldDeleteChars(ZnFieldSet     fs,
                 int            field,
                 int            *first,
                 int            *last)
{
  Field          fptr;
  ZnTextInfo    *ti = &fs->item->wi->text_info;
  unsigned int  char_count, byte_count;
  unsigned int  num_bytes, num_chars, first_offset;
  char          *new;

  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    return False;
  }

  fptr = &fs->fields[field];
  num_chars = 0;
  num_bytes = 0;
  if (fptr->text) {
    num_bytes = strlen(fptr->text);
    num_chars = Tcl_NumUtfChars(fptr->text, (int) num_bytes);
  }
  if (num_chars == 0) {
    return False;
  }
  
  if (*first < 0) {
    *first = 0;
  }
  if (*last >= (int) num_chars) {
    *last = num_chars-1;
  }
  if (*first > *last) {
    return False;
  }
  char_count = *last + 1 - *first;
  first_offset = Tcl_UtfAtIndex(fptr->text, *first)-fptr->text;
  byte_count = Tcl_UtfAtIndex(fptr->text + first_offset, (int) char_count) -
    (fptr->text+first_offset);

  if (num_bytes - byte_count) {
    new = ZnMalloc(num_bytes + 1 - byte_count);
    memcpy(new, fptr->text, (size_t) first_offset);
    strcpy(new + first_offset, fptr->text + first_offset + byte_count);
    ZnFree(fptr->text);
    fptr->text = new;
  }
  else {
    ZnFree(fptr->text);
    fptr->text = NULL;
  }

  /*
   * Update the cursor to reflect the new string.
   */
  if (fptr->insert_index > *first) {
    fptr->insert_index -= char_count;
    if (fptr->insert_index < *first) {
      fptr->insert_index = *first;
    }
  }
  if ((ti->sel_item == fs->item) && (ti->sel_field == field)) {
    if (ti->sel_first > *first) {
      ti->sel_first -= char_count;
      if (ti->sel_first < *first) {
        ti->sel_first = *first;
      }
    }
    if (ti->sel_last >= *first) {
      ti->sel_last -= char_count;
      if (ti->sel_last < *first - 1) {
        ti->sel_last = *first - 1;
      }
    }
    if (ti->sel_first > ti->sel_last) {
      ti->sel_item = ZN_NO_ITEM;
    }
    if ((ti->anchor_item == fs->item) && (ti->anchor_field == field) &&
        (ti->sel_anchor > *first)) {
      ti->sel_anchor -= char_count;
      if (ti->sel_anchor < *first) {
        ti->sel_anchor = *first;
      }
    }
  }
  
  /*
   * Need to redo the fields layout (maybe).
   */
  ClearFieldCache(fs, field);
  return True;
}

static void
FieldCursor(ZnFieldSet  fs,
            int         field,
            int         index)
{
  Field fptr;
  int   num_chars;

  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    return;
  }

  fptr = &fs->fields[field];
  num_chars = 0;
  if (fptr->text) {
    num_chars = Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text));
  }

  if (index < 0) {
    fptr->insert_index = 0;
  }
  else if (index > num_chars) {
    fptr->insert_index = num_chars;
  }
  else {
    fptr->insert_index = index;
  }
}

static int
FieldSelection(ZnFieldSet       fs,
               int      field,
               int      offset,
               char     *chars,
               int      max_bytes)
{
  Field    fptr;
  int      count;
  char  const *sel_first, *sel_last;
  ZnTextInfo *ti;

  if ((field < 0) || ((unsigned int) field >= fs->num_fields)) {
    return 0;
  }
  ti = &fs->item->wi->text_info;
  if ((ti->sel_first < 0) ||
      (ti->sel_first > ti->sel_last)) {
    return 0;
  }
  
  fptr = &fs->fields[field];
  if (!fptr->text) {
    return 0;
  }

  sel_first = Tcl_UtfAtIndex(fptr->text, ti->sel_first);
  sel_last = Tcl_UtfAtIndex(sel_first, ti->sel_last + 1 - ti->sel_first);
  count = sel_last - sel_first - offset;
  if (count <= 0) {
    return 0;
  }
  if (count > max_bytes) {
    count = max_bytes;
  }

  memcpy(chars, sel_first + offset, (size_t) count);
  chars[count] = 0;
  
  return count;
}


/*
 **********************************************************************************
 *
 * ComputeFieldImageLocation -- 
 *      Compute the bounding box of the pixmap in a field. The position is
 *      deduced from the field bounding box passed in bbox.
 *
 **********************************************************************************
 */
static void
ComputeFieldImageLocation(Field         fptr,
                          ZnBBox        *bbox,
                          ZnBBox        *pm_bbox)
{
  int   width, height;

  ZnSizeOfImage(fptr->image, &width, &height);
  pm_bbox->orig.y = (bbox->orig.y + bbox->corner.y - height) / 2;
  pm_bbox->corner.y = pm_bbox->orig.y + height;
  
  switch (fptr->alignment) {
  case TK_JUSTIFY_LEFT:
    pm_bbox->orig.x = bbox->orig.x;
    break;
  case TK_JUSTIFY_RIGHT:
    pm_bbox->orig.x = bbox->corner.x - width - 1;
    break;
  default:
    pm_bbox->orig.x = (bbox->orig.x + bbox->corner.x - width) / 2;
    break;
  }
  pm_bbox->corner.x = pm_bbox->orig.x + width;
}


/*
 **********************************************************************************
 *
 * FieldsEngine -- 
 *
 **********************************************************************************
 */
static void
FieldsEngine(ZnFieldSet field_set,
             void       (*cb)())
{
  ZnWInfo       *wi = field_set->item->wi;
  /*int         i;      This one *NEED* to be an int */
  unsigned int  i, num_fields, num_chars;
  Field         fptr;
  ZnTextInfo    *ti = &wi->text_info;
  ZnBBox        lclip_bbox, fclip_bbox, bbox, *global_clip_box;
  ZnBBox        tmp_bbox, text_bbox, pm_bbox;
  ZnPoint       pts[2];
  ZnTriStrip    tristrip;
  ZnPoint       text_pos;
  ZnBool        restore = False;
  ZnDim         lwidth, lheight;
  ZnReal        val;
  int           cursor;
  int           sel_start, sel_stop;

  if (!field_set->num_fields) {
    return;
  }

  if (field_set->label_format && ZnLFNumFields(field_set->label_format)) {
    bbox.orig.x = ZnNearestInt(field_set->label_pos.x);
    bbox.orig.y = ZnNearestInt(field_set->label_pos.y);
    GetLabelBBox(field_set, &lwidth, &lheight);
    bbox.corner.x = bbox.orig.x + lwidth;
    bbox.corner.y = bbox.orig.y + lheight;
    ZnCurrentClip(wi, NULL, &global_clip_box, NULL);

    if (!wi->render) {
      ZnIntersectBBox(global_clip_box, &bbox, &lclip_bbox);
      if (ZnIsEmptyBBox(&lclip_bbox)) {
        return;
      }
    }
    else {
      lclip_bbox = bbox;
    }

    num_fields = ZnLFNumFields(field_set->label_format);
    for (i = 0; i < num_fields; i++) {
      fptr = &field_set->fields[i];

      if (ISCLEAR(fptr->flags, FIELD_VISIBLE_BIT)) {
        continue;
      }
      
      GetFieldBBox(field_set, i, &bbox);
      ZnIntersectBBox(&lclip_bbox, &bbox, &fclip_bbox);
      if (ZnIsEmptyBBox(&fclip_bbox)) {
        continue;
      }
      
      /* we must call XSetClipRectangles only if it's required  */
      val = fclip_bbox.orig.x - bbox.orig.x;
      restore = val > 0;
      val = fclip_bbox.orig.y - bbox.orig.y;
      restore |= val > 0;
      val = fclip_bbox.corner.x - bbox.corner.x;
      restore |= val < 0;
      val = fclip_bbox.corner.y - bbox.corner.y;
      restore |= val < 0;

      cursor = ((field_set->item == wi->focus_item) &&
                ((unsigned int) wi->focus_field == i) &&
                ISSET(wi->flags, ZN_GOT_FOCUS) && ti->cursor_on) ? 0 : -1;
      sel_start = -1, sel_stop = -1;
      ComputeFieldTextLocation(fptr, &bbox, &text_pos, &text_bbox);

      if (fptr->text) {
        if (cursor != -1) {
          cursor = Tk_TextWidth(fptr->font, fptr->text,
                                Tcl_UtfAtIndex(fptr->text,
                                               fptr->insert_index)-fptr->text);
        }
        num_chars  = Tcl_NumUtfChars(fptr->text, (int) strlen(fptr->text));
        if (num_chars) {
          if ((field_set->item == ti->sel_item) && ((unsigned int) ti->sel_field == i) &&
              (ti->sel_last >= 0) && (ti->sel_first <= (int) num_chars)) {
            sel_start = Tk_TextWidth(fptr->font, fptr->text,
                                     Tcl_UtfAtIndex(fptr->text,
                                                    ti->sel_first)-fptr->text);
            sel_stop = Tk_TextWidth(fptr->font, fptr->text,
                                    Tcl_UtfAtIndex(fptr->text,
                                                   ti->sel_last)-fptr->text);
          }
          
          ZnIntersectBBox(&fclip_bbox, &text_bbox, &tmp_bbox);
          
          val = tmp_bbox.orig.x - text_bbox.orig.x;
          restore |= val > 0;
          val = tmp_bbox.orig.y - text_bbox.orig.y;
          restore |= val > 0;
          val = tmp_bbox.corner.x - text_bbox.corner.x;
          restore |= val < 0;
          val = tmp_bbox.corner.y - text_bbox.corner.y;
          restore |= val < 0;
        }
      }

      if (fptr->image != ZnUnspecifiedImage) {
        ComputeFieldImageLocation(fptr, &bbox, &pm_bbox);

        ZnIntersectBBox(&fclip_bbox, &pm_bbox, &tmp_bbox);
        
        val = tmp_bbox.orig.x - pm_bbox.orig.x;
        restore |= val > 0;
        val = tmp_bbox.orig.y - pm_bbox.orig.y;
        restore |= val > 0;
        val = tmp_bbox.corner.x - pm_bbox.corner.x;
        restore |= val < 0;
        val = tmp_bbox.corner.y - pm_bbox.corner.y;
        restore |= val < 0;
      }
      
      /*restore = True;*/
      if (restore) {
        /* we must clip. */
        /*printf("clip: %d\n", i);*/
        pts[0] = fclip_bbox.orig;
        pts[1] = fclip_bbox.corner;
        ZnTriStrip1(&tristrip, pts, 2, False);
        ZnPushClip(wi, &tristrip, True, True);
      }

      (*cb)(wi, fptr, &bbox, &pm_bbox,
            &text_pos, &text_bbox, cursor, sel_start, sel_stop);

      if (restore) {
        /* Restore the previous clip. */
        ZnPopClip(wi, True);
        restore = False;
      }
    }
  }
}


/*
 **********************************************************************************
 *
 * DrawFields -- 
 *
 **********************************************************************************
 */
static void
DrawField(ZnWInfo       *wi,
          Field         fptr,
          ZnBBox        *bbox,
          ZnBBox        *pm_bbox,
          ZnPoint       *text_pos,
          ZnBBox        *text_bbox,
          int           cursor,
          int           sel_start,
          int           sel_stop)
{
  ZnTextInfo    *ti = &wi->text_info;
  XGCValues     values;
  XRectangle    r;
  int           j, xs, num_bytes;
  int           pw, ph, fw, fh;
  TkRegion      clip_region;
  ZnBool        simple;
  Pixmap        pixmap;
  TkRegion      photo_region, clip;

  ZnBBox2XRect(bbox, &r);

  /*
   * Draw the background.
   */
  if (ISSET(fptr->flags, FILLED_BIT)) {
    values.foreground = ZnGetGradientPixel(fptr->fill_color, 0.0);
    
    if (fptr->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(fptr->tile)) { /* Fill tiled */
        values.fill_style = FillTiled;
        values.tile = ZnImagePixmap(fptr->tile, wi->win);
        values.ts_x_origin = (int) bbox->orig.x;
        values.ts_y_origin = (int) bbox->orig.y;
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCFillStyle|GCTile,
                  &values);
      }
      else { /* Fill stippled */
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(fptr->tile, wi->win);
        values.ts_x_origin = (int) bbox->orig.x;
        values.ts_y_origin = (int) bbox->orig.y;
        XChangeGC(wi->dpy, wi->gc,
                  GCTileStipXOrigin|GCTileStipYOrigin|GCFillStyle|GCStipple|GCForeground,
                  &values);
      }
    }
    else { /* Fill solid */
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc, GCForeground|GCFillStyle, &values);
    }
    XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc, r.x, r.y, r.width, r.height);
  }
  
  /*
   * Draw the image and the text, which is in back depends on
   * the value of text_on_top.
   */
  for (j = 0; j < 2; j++) {
    if ((j == 0 && ISSET(fptr->flags, TEXT_ON_TOP_BIT)) ||
        (j == 1 && ISCLEAR(fptr->flags, TEXT_ON_TOP_BIT))) {
      /*
       * Draw the image.
       */
      if (fptr->image != ZnUnspecifiedImage) {
        pw = ZnNearestInt(pm_bbox->corner.x - pm_bbox->orig.x);
        ph = ZnNearestInt(pm_bbox->corner.y - pm_bbox->orig.y);
        fw = ZnNearestInt(bbox->corner.x - bbox->orig.x);
        fh = ZnNearestInt(bbox->corner.y - bbox->orig.y);

        pixmap = ZnImagePixmap(fptr->image, wi->win);
        photo_region = ZnImageRegion(fptr->image);
        ZnCurrentClip(wi, &clip_region, NULL, &simple);
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
          rect.width = pw;
          rect.height = ph;
          TkUnionRectWithRegion(&rect, clip, clip);
        }
        else {
          ZnUnionRegion(clip, photo_region, clip);
        }
        ZnOffsetRegion(clip, (int) pm_bbox->orig.x, (int) pm_bbox->orig.y);
        TkIntersectRegion(clip_region, clip, clip);
        TkSetRegion(wi->dpy, wi->gc, clip);
        XCopyArea(wi->dpy, pixmap, wi->draw_buffer, wi->gc,
                  (int) ZnNearestInt(bbox->orig.x-pm_bbox->orig.x),
                  (int) ZnNearestInt(bbox->orig.y-pm_bbox->orig.y),
                  (unsigned int) MIN(pw, fw),
                  (unsigned int) MIN(ph, fh),
                  (int) MAX(bbox->orig.x, pm_bbox->orig.x),
                  (int) MAX(bbox->orig.y, pm_bbox->orig.y));

        TkSetRegion(wi->dpy, wi->gc, clip_region);
        TkDestroyRegion(clip);
      }
    }
    else if (fptr->text) {
      /*
       * Draw the text.
       */
      num_bytes = strlen(fptr->text);
      if (num_bytes) {
        if (sel_start >= 0) {
          values.foreground = ZnGetGradientPixel(ti->sel_color, 0.0);
          values.fill_style = FillSolid;
          XChangeGC(wi->dpy, wi->gc, GCForeground|GCFillStyle, &values);
          XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc,
                         (int) (text_bbox->orig.x+sel_start),
                         (int) text_bbox->orig.y,
                         (unsigned int) (sel_stop-sel_start),
                         (unsigned int) (text_bbox->corner.y-text_bbox->orig.y));
        }
        values.foreground = ZnGetGradientPixel(fptr->color, 0.0);
        values.fill_style = FillSolid;
        values.font = Tk_FontId(fptr->font);
        XChangeGC(wi->dpy, wi->gc, GCForeground | GCFillStyle | GCFont, &values);
        Tk_DrawChars(wi->dpy, wi->draw_buffer, wi->gc, fptr->font,
                     fptr->text, num_bytes, (int) text_pos->x, (int) text_pos->y);
      }
    }
  }
  if (cursor >= 0) {
    values.line_width = ti->insert_width;
    values.foreground = ZnGetGradientPixel(ti->insert_color, 0.0);
    values.fill_style = FillSolid;
    XChangeGC(wi->dpy, wi->gc, GCForeground|GCLineWidth|GCFillStyle, &values);
    xs = (int) text_bbox->orig.x + cursor;
    XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
              xs, (int) text_bbox->orig.y,
              xs, (int) text_bbox->corner.y);
  }
  
  /*
   * Draw the border relief.
   */
  if ((fptr->relief != ZN_RELIEF_FLAT) && (fptr->relief_thickness > 1)) {
    ZnDrawRectangleRelief(wi, fptr->relief, fptr->gradient,
                          &r, fptr->relief_thickness);
  }
  
  /*
   * Draw the border line.
   */
  if (fptr->border_edges != ZN_NO_BORDER) {
    values.foreground = ZnGetGradientPixel(fptr->border_color, 0.0);
    values.line_width = 0;
    values.line_style = LineSolid;
    values.fill_style = FillSolid;
    XChangeGC(wi->dpy, wi->gc,
              GCForeground | GCLineWidth | GCLineStyle | GCFillStyle, &values);
    if (fptr->border_edges & ZN_LEFT_BORDER) {
      XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, r.x, r.y,
                r.x, r.y + r.height - 1);
    }
    if (fptr->border_edges & ZN_RIGHT_BORDER) {
      XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, 
                r.x + r.width - 1, r.y,
                r.x + r.width - 1, r.y + r.height - 1);
    }
    if (fptr->border_edges & ZN_TOP_BORDER) {
      XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, 
                r.x, r.y, r.x + r.width - 1, r.y);
    }
    if (fptr->border_edges & ZN_BOTTOM_BORDER) {
      XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, 
                r.x, r.y + r.height - 1,
                r.x + r.width - 1, r.y + r.height - 1);
    }
    if (fptr->border_edges & ZN_OBLIQUE) {
      XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, 
                r.x, r.y, r.x + r.width - 1, r.y + r.height - 1);
    }
    if (fptr->border_edges & ZN_COUNTER_OBLIQUE) {
      XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, 
                r.x, r.y + r.height - 1,
                r.x + r.width - 1, r.y);
    }
  }
}

static void
DrawFields(ZnFieldSet   field_set)
{
  FieldsEngine(field_set, DrawField);
}


/*
 **********************************************************************************
 *
 * RenderFields -- 
 *
 **********************************************************************************
 */
#ifdef GL
static void
FieldRenderCB(void *closure)
{
  ZnBBox *bbox = (ZnBBox *) closure;
  
  glBegin(GL_QUADS);
  glVertex2d(bbox->orig.x, bbox->orig.y);
  glVertex2d(bbox->orig.x, bbox->corner.y);
  glVertex2d(bbox->corner.x, bbox->corner.y);
  glVertex2d(bbox->corner.x, bbox->orig.y);
  glEnd();
}

static void
RenderField(ZnWInfo     *wi,
            Field       fptr,
            ZnBBox      *bbox,
            ZnBBox      *pm_bbox,
            ZnPoint     *text_pos,
            ZnBBox      *text_bbox,
            int         cursor,
            int         sel_start,
            int         sel_stop)
{
  unsigned short alpha;
  unsigned int  j, num_bytes;
  XColor        *color;
  ZnReal        xs;
  ZnTextInfo    *ti = &wi->text_info;

  ZnGLMakeCurrent(wi->dpy, wi);
  /*
   * Draw the background.
   */
  if (ISSET(fptr->flags, FILLED_BIT)) {
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    if (!ZnGradientFlat(fptr->fill_color)) {
#if 0 /* TODO_GL Faire le dégradé dans le fond des champs. */
      int       type = fptr->fill_color->type;
      ZnBool    fast = (type == ZN_AXIAL_GRADIENT) && !fptr->grad_geo;

      RenderGradient(wi, fptr->fill_color,
                     fast ? NULL : FieldRenderCB,
                     bbox, fast ? (ZnPoint *) bbox : fptr->grad_geo);
#endif
    }
    else {
      if (fptr->tile != ZnUnspecifiedImage) { /* Fill tiled/stippled */
        ZnRenderTile(wi, fptr->tile, fptr->fill_color, FieldRenderCB, bbox,
                     (ZnPoint *) bbox);
      }
      else { /* Fill solid */
        color = ZnGetGradientColor(fptr->fill_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        FieldRenderCB(bbox);
      }
    }
  }

  /*
   * Draw the image and the text, which one is back depends on
   * the value of text_on_top.
   */
  for (j = 0; j < 2; j++) {
    if ((j == 0 && ISSET(fptr->flags, TEXT_ON_TOP_BIT)) ||
        (j == 1 && ISCLEAR(fptr->flags, TEXT_ON_TOP_BIT))) {
      /*
       * Draw the image.
       */
      if (fptr->image != ZnUnspecifiedImage) {
        ZnRenderIcon(wi, fptr->image, fptr->fill_color,
                     &pm_bbox->orig, False);
      }
    }
    else if (fptr->text) {
      /*
       * Draw the text.
       */
      num_bytes = strlen(fptr->text);
      if (num_bytes) {
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        if (sel_start >= 0) {
          color = ZnGetGradientColor(ti->sel_color, 0.0, &alpha);
          alpha = ZnComposeAlpha(alpha, wi->alpha);
          glColor4us(color->red, color->green, color->blue, alpha);
          glBegin(GL_QUADS);
          glVertex2d(text_bbox->orig.x+sel_start, text_bbox->orig.y);
          glVertex2d(text_bbox->orig.x+sel_stop, text_bbox->orig.y);
          glVertex2d(text_bbox->orig.x+sel_stop, text_bbox->corner.y);
          glVertex2d(text_bbox->orig.x+sel_start, text_bbox->corner.y);
          glEnd();
        }
        glEnable(GL_TEXTURE_2D);
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        color = ZnGetGradientColor(fptr->color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        glBindTexture(GL_TEXTURE_2D, ZnTexFontTex(fptr->tfi));
        glPushMatrix();
        glTranslated(text_pos->x, text_pos->y, 0.0);
        ZnRenderString(fptr->tfi, fptr->text, num_bytes);
        glPopMatrix();
        glDisable(GL_TEXTURE_2D);
      }
    }
    if (cursor >= 0) {
      glLineWidth((GLfloat) ti->insert_width);
      color = ZnGetGradientColor(ti->insert_color, 0.0, &alpha);
      alpha = ZnComposeAlpha(alpha, wi->alpha);
      glColor4us(color->red, color->green, color->blue, alpha);
      xs = text_bbox->orig.x + cursor;
      glBegin(GL_LINES);
      glVertex2d(xs, text_bbox->orig.y);
      glVertex2d(xs, text_bbox->corner.y);
      glEnd();
    }
  }
  
  /*
   * Draw the border relief.
   */  
  if ((fptr->relief != ZN_RELIEF_FLAT) && (fptr->relief_thickness > 1)) {
    ZnPoint p[5];

    p[0].x = bbox->orig.x;
    p[0].y = bbox->orig.y;
    p[2].x = bbox->corner.x;
    p[2].y = bbox->corner.y;
    p[1].x = p[0].x;
    p[1].y = p[2].y;
    p[3].x = p[2].x;
    p[3].y = p[0].y;
    p[4] = p[0];
    ZnRenderPolygonRelief(wi, fptr->relief, fptr->gradient,
                          False, p, 5, fptr->relief_thickness);
  }

  /*
   * Draw the border line.
   */
  if (fptr->border_edges != ZN_NO_BORDER) {
    color = ZnGetGradientColor(fptr->border_color, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
    glColor4us(color->red, color->green, color->blue, alpha);
    glLineWidth(1.5);
    ZnSetLineStyle(wi, ZN_LINE_SIMPLE);
    glBegin(GL_LINES);
    if (fptr->border_edges & ZN_LEFT_BORDER) {
      glVertex2d(bbox->orig.x, bbox->orig.y);
      glVertex2d(bbox->orig.x, bbox->corner.y);
    }
    if (fptr->border_edges & ZN_RIGHT_BORDER) {
      glVertex2d(bbox->corner.x, bbox->orig.y);
      glVertex2d(bbox->corner.x, bbox->corner.y);
    }
    if (fptr->border_edges & ZN_TOP_BORDER) {
      glVertex2d(bbox->orig.x, bbox->orig.y);
      glVertex2d(bbox->corner.x, bbox->orig.y);
    }
    if (fptr->border_edges & ZN_BOTTOM_BORDER) {
      glVertex2d(bbox->orig.x, bbox->corner.y);
      glVertex2d(bbox->corner.x, bbox->corner.y);
    }
    if (fptr->border_edges & ZN_OBLIQUE) {
      glVertex2d(bbox->orig.x, bbox->orig.y);
      glVertex2d(bbox->corner.x, bbox->corner.y);
    }
    if (fptr->border_edges & ZN_COUNTER_OBLIQUE) {
      glVertex2d(bbox->orig.x, bbox->corner.y);
      glVertex2d(bbox->corner.x, bbox->orig.y);
    }
    glEnd();
  }
}
#endif

#ifdef GL
static void
RenderFields(ZnFieldSet field_set)
{
  /*  glDisable(GL_LINE_SMOOTH);*/
  FieldsEngine(field_set, RenderField);
  /*  glEnable(GL_LINE_SMOOTH);*/
}
#else
static void
RenderFields(ZnFieldSet field_set)
{
}
#endif


/*
 **********************************************************************************
 *
 * PostScriptFields --
 *
 **********************************************************************************
 */
static int
PsField(ZnWInfo *wi,
        ZnBool  prepass,
        Field   fptr,
        ZnBBox  *bbox,
        ZnBBox  *pm_bbox,
        ZnPoint *text_pos,
        ZnBBox  *text_bbox)
{
  int j;
  char path[250];

  /*
   * Must set the clip rect for the whole field, not only for stipple fill.
   */
  if (ISSET(fptr->flags, FILLED_BIT)) {
    if (fptr->tile != ZnUnspecifiedImage) {
      if (!ZnImageIsBitmap(fptr->tile)) { /* Fill tiled */
        /* TODO No support yet */
      }
      else { /* Fill stippled */
        Tcl_AppendResult(wi->interp, "gsave\n", NULL);
        if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                               ZnGetGradientColor(fptr->fill_color, 0.0, NULL)) != TCL_OK) {
          return TCL_ERROR;
        }
        if (Tk_PostscriptStipple(wi->interp, wi->win, wi->ps_info,
                                 ZnImagePixmap(fptr->tile, wi->win)) != TCL_OK) {
          return TCL_ERROR;
        }
        Tcl_AppendResult(wi->interp, "grestore\n", NULL);
      }
    }
    else { /* Fill solid */
      if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                             ZnGetGradientColor(fptr->fill_color, 0.0, NULL)) != TCL_OK) {
        return TCL_ERROR;
      }
      Tcl_AppendResult(wi->interp, "fill\n", NULL);
    }
  }

  /*
   * Draw the image and the text, which is in back depends on
   * the value of text_on_top.
   */
  for (j = 0; j < 2; j++) {
    if ((j == 0 && ISSET(fptr->flags, TEXT_ON_TOP_BIT)) ||
        (j == 1 && ISCLEAR(fptr->flags, TEXT_ON_TOP_BIT))) {
      /*
       * Draw the image.
       */
      if (fptr->image != ZnUnspecifiedImage) {
	int w, h;

        Tcl_AppendResult(wi->interp, "gsave\n", NULL);
        sprintf(path, "%.15g %.15g translate 1 -1 scale\n",
                pm_bbox->orig.x, pm_bbox->corner.y);
        Tcl_AppendResult(wi->interp, path, NULL);
        w = ZnNearestInt(pm_bbox->corner.x - pm_bbox->orig.x);
        h = ZnNearestInt(pm_bbox->corner.y - pm_bbox->orig.y);
        if (Tk_PostscriptImage(ZnImageTkImage(fptr->image), wi->interp, wi->win,
                               wi->ps_info, 0, 0, w, h, prepass) != TCL_OK) {
          return TCL_ERROR;
        }
        Tcl_AppendResult(wi->interp, "grestore\n", NULL);
      }
    }
    else if (fptr->text) {
      Tcl_AppendResult(wi->interp, "gsave\n", NULL);
      if (Tk_PostscriptFont(wi->interp, wi->ps_info, fptr->font) != TCL_OK) {
        return TCL_ERROR;
      }
      if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                             ZnGetGradientColor(fptr->color, 0.0, NULL)) != TCL_OK) {
        return TCL_ERROR;
      }
      /*
       * TODO pourquoi la text_bbox ne donne pas un texte centré verticalement ?
       * Apparement la fonte PostScript n'est pas centrée comme la fonte X.
       * Il faut donc opérer le calcul dans le code PostScript de DrawText.
       */
      sprintf(path, "%.15g %.15g translate 1 -1 scale 0 0 [\n",
              text_bbox->orig.x, text_bbox->orig.y);
      Tcl_AppendResult(wi->interp, path, NULL);
      /*
       * strlen should do the work of counting _bytes_ in the utf8 string.
       */
      ZnPostscriptString(wi->interp, fptr->text, strlen(fptr->text));
      Tcl_AppendResult(wi->interp, "] 0 0.0 0.0 0.0 false DrawText\n", NULL);
      Tcl_AppendResult(wi->interp, "grestore\n", NULL);
    }
  }

  /*
   * Draw the border relief.
   */
  if ((fptr->relief != ZN_RELIEF_FLAT) && (fptr->relief_thickness > 1)) {
  }

  /*
   * Draw the border line.
   */
  if (fptr->border_edges != ZN_NO_BORDER) {
    if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                           ZnGetGradientColor(fptr->border_color, 0.0, NULL)) != TCL_OK) {
      return TCL_ERROR;
    }
    Tcl_AppendResult(wi->interp, "1 setlinewidth 0 setlinejoin 2 setlinecap\n", NULL);
    if (fptr->border_edges & ZN_LEFT_BORDER) {
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto stroke\n",
              bbox->orig.x, bbox->orig.y, bbox->orig.x, bbox->corner.y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
    if (fptr->border_edges & ZN_RIGHT_BORDER) {
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto stroke\n",
              bbox->corner.x, bbox->orig.y, bbox->corner.x, bbox->corner.y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
    if (fptr->border_edges & ZN_TOP_BORDER) {
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto stroke\n",
              bbox->orig.x, bbox->orig.y, bbox->corner.x, bbox->orig.y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
    if (fptr->border_edges & ZN_BOTTOM_BORDER) {
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto stroke\n",
              bbox->orig.x, bbox->corner.y, bbox->corner.x, bbox->corner.y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
    if (fptr->border_edges & ZN_OBLIQUE) {
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto stroke\n",
              bbox->orig.x, bbox->orig.y, bbox->corner.x, bbox->corner.y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
    if (fptr->border_edges & ZN_COUNTER_OBLIQUE) {
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto stroke\n",
              bbox->corner.x, bbox->orig.y, bbox->orig.x, bbox->corner.y);
      Tcl_AppendResult(wi->interp, path, NULL);
    }
  }

  return TCL_OK;
}

static int
PostScriptFields(ZnFieldSet field_set,
                 ZnBool     prepass,
                 ZnBBox     *area)
{
  ZnWInfo *wi = field_set->item->wi;
  ZnBBox  lclip_bbox, fclip_bbox;
  ZnBBox  bbox, text_bbox, pm_bbox;
  ZnPoint text_pos;
  int     i, num_fields;
  ZnDim   lwidth, lheight;
  Field   fptr;
  char    path[250];
  
  if (!field_set->num_fields) {
    return TCL_OK;
  }


  if (field_set->label_format && ZnLFNumFields(field_set->label_format)) {
    /*
     * Fields are drawn with respect to a point already converted
     * to device space, so we need to reinstate the initial transform.
     */
    Tcl_AppendResult(wi->interp, "/InitialTransform load setmatrix\n", NULL);

    lclip_bbox.orig.x = ZnNearestInt(field_set->label_pos.x);
    lclip_bbox.orig.y = ZnNearestInt(field_set->label_pos.y);
    GetLabelBBox(field_set, &lwidth, &lheight);
    lclip_bbox.corner.x = lclip_bbox.orig.x + lwidth;
    lclip_bbox.corner.y = lclip_bbox.orig.y + lheight;
    
    num_fields = ZnLFNumFields(field_set->label_format);
    for (i = 0; i < num_fields; i++) {
      fptr = &field_set->fields[i];

      if (ISCLEAR(fptr->flags, FIELD_VISIBLE_BIT)) {
        continue;
      }
      
      GetFieldBBox(field_set, i, &bbox);
      ZnIntersectBBox(&lclip_bbox, &bbox, &fclip_bbox);
      if (ZnIsEmptyBBox(&fclip_bbox)) {
        /* The field is outside the label bbox */
        continue;
      }
      
      /*
       * Setup a clip area around the field
       */
      Tcl_AppendResult(wi->interp, "gsave\n", NULL);
      sprintf(path, "%.15g %.15g moveto %.15g %.15g lineto %.15g %.15g lineto %.15g %.15g",
              fclip_bbox.orig.x, fclip_bbox.orig.y, fclip_bbox.corner.x+1, fclip_bbox.orig.y,
              fclip_bbox.corner.x+1, fclip_bbox.corner.y+1, fclip_bbox.orig.x,
              fclip_bbox.corner.y+1);
      Tcl_AppendResult(wi->interp, path, " lineto closepath clip\n", NULL);

      if (fptr->text) {
        ComputeFieldTextLocation(fptr, &bbox, &text_pos, &text_bbox);
      }
      if (fptr->image != ZnUnspecifiedImage) {
        ComputeFieldImageLocation(fptr, &bbox, &pm_bbox);
      }

      if (PsField(wi, prepass, fptr, &bbox, &pm_bbox, &text_pos, &text_bbox) != TCL_OK) {
        return TCL_ERROR;
      }

      Tcl_AppendResult(wi->interp, "grestore\n", NULL);
    }
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * IsFieldsSensitive --
 *
 **********************************************************************************
 */
static ZnBool
IsFieldSensitive(ZnFieldSet     field_set,
                 int            part)
{
  if ((part >= 0) && ((unsigned int) part < field_set->num_fields)) {
    return ISSET(field_set->fields[part].flags, FIELD_SENSITIVE_BIT);
  }
  else {
    return False;
  }
}


/*
 **********************************************************************************
 *
 * FieldsPick --
 *      Return the first field that contains <x, y>.
 *      A field is selected if <x, y> is over a non transparent area.
 *      Such areas are : a solid filled background, a text, an icon.
 *      This does *NOT* do with *GLOBAL* visible and sensitive.
 *      But we need to take into account local field visible and
 *      sensitive as they modifiy local transparency. Local means
 *      within a single item.
 *
 **********************************************************************************
 */
static double
FieldsPick(ZnFieldSet   field_set,
           ZnPoint      *p,
           int          *part)
{
  Field         fptr;
  ZnBBox        bbox;
  unsigned int  best_field = 0;
  int           i;
  ZnReal        new_dist, dist = 1e40;

  if (!field_set->num_fields) {
    return dist;
  }

  if (field_set->label_format) {
    for (i = ZnLFNumFields(field_set->label_format)-1; i >= 0; i--) {    
      fptr = &field_set->fields[i];
      
      if (ISCLEAR(fptr->flags, FIELD_VISIBLE_BIT) &&
          ISCLEAR(fptr->flags, FIELD_SENSITIVE_BIT)) {
        continue;
      }
      
      GetFieldBBox(field_set, (unsigned int) i, &bbox);

      new_dist = ZnRectangleToPointDist(&bbox, p);
      if (new_dist < dist) {
        dist = new_dist;
        best_field = i;
      }
      if (dist <= 0.0) {
        dist = 0.0;
        break;
      }
    }
  }
  
  *part = best_field;
  return dist;
}


/*
 **********************************************************************************
 *
 * FieldsToArea --
 *      Return -1 if no field is in the given area, 1 if they are
 *      all in it or 0 if there is some overlap. The function consider
 *      only fields that are either sensible or visible.
 *
 **********************************************************************************
 */
static int
FieldsToArea(ZnFieldSet field_set,
             ZnBBox     *area)
{
  Field         fptr;
  ZnBBox        bbox;
  int           i, inside = -1;
  ZnBool        first_done = False;
  
  if (!field_set->num_fields) {
    return inside;
  }

  for (i = ZnLFNumFields(field_set->label_format)-1; i >= 0; i--) {
    fptr = &field_set->fields[i];

    if (ISCLEAR(fptr->flags, FIELD_VISIBLE_BIT) &&
        ISCLEAR(fptr->flags, FIELD_SENSITIVE_BIT)) {
      continue;
    }

    GetFieldBBox(field_set, (unsigned int) i, &bbox);
    if (!first_done) {
      first_done = True;
      inside = ZnBBoxInBBox(&bbox, area);
      if (inside == 0) {
        return 0;
      }
    }
    else {
      if (ZnBBoxInBBox(&bbox, area) != inside) {
        return 0;
      }
    }
  }

  return inside;
}


/*
 **********************************************************************************
 *
 * SetFieldsAutoAlign --
 *
 **********************************************************************************
 */
static void
SetFieldsAutoAlign(ZnFieldSet   fs,
                   int          alignment)
{
  unsigned int  i;
  Field         field;

  if (!fs->num_fields) {
    return;
  }
  if ((alignment >= ZN_AA_LEFT) && (alignment <= ZN_AA_RIGHT)) {
    for (i = 0; i < fs->num_fields; i++) {
      field = &fs->fields[i];
      if (field->auto_alignment.automatic) {
        field->alignment = field->auto_alignment.align[alignment];
      }
    }
  }
}

static char *
GetFieldStruct(ZnFieldSet       fs,
               int              field)
{
  if ((unsigned int) field >= fs->num_fields) {
    return NULL;
  }
  return (char *) &fs->fields[field];
}


static unsigned int
NumFields(ZnFieldSet    fs)
{
  return fs->num_fields;
}


struct _ZnFIELD ZnFIELD = {
  field_attrs,

  InitFields,
  CloneFields,
  FreeFields,
  ConfigureField,
  QueryField,
  DrawFields,
  RenderFields,
  PostScriptFields,
  FieldsToArea,
  IsFieldSensitive,
  FieldsPick,
  FieldIndex,
  FieldInsertChars,
  FieldDeleteChars,
  FieldCursor,
  FieldSelection,
  LeaderToLabel,
  GetLabelBBox,
  GetFieldBBox,
  SetFieldsAutoAlign,
  ClearFieldCache,
  GetFieldStruct,
  NumFields
};
