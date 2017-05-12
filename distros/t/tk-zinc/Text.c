/*
 * Text.c -- Implementation of Text item.
 *
 * Authors              : Patrick LECOANET
 * Creation date        : Sat Mar 25 13:58:39 1995
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

/*
 * Some functions in this file are derived from tkCanvText.c and thus
 * copyrighted:
 *
 * Copyright (c) 1991-1994 The Regents of the University of California.
 * Copyright (c) 1994-1995 Sun Microsystems, Inc.
 *
 */

#include <math.h>
#include <ctype.h>
#include <X11/Xatom.h>
#include <string.h>
#include <stdlib.h>

#include "Item.h"
#include "Geo.h"
#include "Draw.h"
#include "Types.h"
#include "WidgetInfo.h"
#include "tkZinc.h"
#include "Image.h"


static const char rcsid[] = "$Imagine: Text.c,v 1.13 1997/05/15 11:35:46 lecoanet Exp $";
static const char compile_id[] = "$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 * Bit offset of flags.
 */
#define UNDERLINED      1
#define OVERSTRIKED     2


/*
 **********************************************************************************
 *
 * Specific Text item record
 *
 **********************************************************************************
 */
typedef struct _TextLineInfo 
{
  char          *start;         /* Index of first char in line */
  unsigned short  num_bytes;    /* Number of displayed bytes in line (NOT chars)*/
  unsigned short width;         /* Line width in pixels */
  unsigned short origin_x;      /* X pos for drawing the line */
  unsigned short origin_y;
} TextLineInfoStruct, *TextLineInfo;

typedef struct _TextItemStruct {
  ZnItemStruct  header;

  /* Public data */
  ZnPoint       pos;            /* Position at anchor */
  ZnGradient    *color;
  char          *text;
  ZnImage       fill_pattern;
  Tk_Font       font;
  unsigned short width;
  short         spacing;
  unsigned short flags;
  Tk_Anchor     anchor;
  Tk_Anchor     connection_anchor;
  Tk_Justify    alignment;

  /* Private data */
  unsigned short num_chars;
  unsigned short insert_index;
  ZnList        text_info;
  unsigned short max_width;
  unsigned short height;
  ZnPoint       poly[4];
#ifdef GL
  ZnTexFontInfo *tfi;
#endif
} TextItemStruct, *TextItem;


static ZnAttrConfig     text_attrs[] = {
  { ZN_CONFIG_ALIGNMENT, "-alignment", NULL,
    Tk_Offset(TextItemStruct, alignment), 0,
    ZN_COORDS_FLAG|ZN_LAYOUT_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-anchor", NULL,
    Tk_Offset(TextItemStruct, anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-color", NULL,
    Tk_Offset(TextItemStruct, color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(TextItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(TextItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(TextItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ITEM, "-connecteditem", NULL,
    Tk_Offset(TextItemStruct, header.connected_item), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-connectionanchor", NULL,
    Tk_Offset(TextItemStruct, connection_anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-fillpattern", NULL,
    Tk_Offset(TextItemStruct, fill_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_FONT, "-font", NULL,
    Tk_Offset(TextItemStruct, font), 0,
    ZN_COORDS_FLAG|ZN_LAYOUT_FLAG, False },
  { ZN_CONFIG_BOOL, "-overstriked", NULL,
    Tk_Offset(TextItemStruct, flags), OVERSTRIKED, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_POINT, "-position", NULL, Tk_Offset(TextItemStruct, pos), 0,
    ZN_COORDS_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(TextItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(TextItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_SHORT, "-spacing", NULL,
    Tk_Offset(TextItemStruct, spacing), 0,
    ZN_COORDS_FLAG|ZN_LAYOUT_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(TextItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_STRING, "-text", NULL,
    Tk_Offset(TextItemStruct, text), 0,
    ZN_COORDS_FLAG|ZN_LAYOUT_FLAG, False },
  { ZN_CONFIG_BOOL, "-underlined", NULL,
    Tk_Offset(TextItemStruct, flags), UNDERLINED, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(TextItemStruct, header.flags), ZN_VISIBLE_BIT,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG|ZN_VIS_FLAG, False },
  { ZN_CONFIG_USHORT, "-width", NULL,
    Tk_Offset(TextItemStruct, width), 0,
    ZN_COORDS_FLAG|ZN_LAYOUT_FLAG, False },
  
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
  TextItem      text = (TextItem) item;

  /*printf("size of a text(header) = %d(%d) %d\n",
    sizeof(TextItemStruct), sizeof(ZnItemStruct), sizeof(TextLineInfoStruct));*/
 
  text->text_info = NULL;
  
  /* Init attributes */
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  CLEAR(item->flags, ZN_COMPOSE_ROTATION_BIT);
  CLEAR(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->priority = 1;

  text->pos.x = text->pos.y = 0.0;
  text->text = NULL;
  text->num_chars = 0;
  text->fill_pattern = ZnUnspecifiedImage;
  text->anchor = TK_ANCHOR_NW;
  text->connection_anchor = TK_ANCHOR_SW;
  text->color = ZnGetGradientByValue(wi->fore_color);
  text->alignment = TK_JUSTIFY_LEFT;
  text->font = Tk_GetFont(wi->interp, wi->win, Tk_NameOfFont(wi->font));
#ifdef GL
  text->tfi = ZnGetTexFont(wi, text->font);
#endif
  text->width = 0;
  text->spacing = 0;
  text->insert_index = 0;
  CLEAR(text->flags, UNDERLINED);
  CLEAR(text->flags, OVERSTRIKED);

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
  TextItem      text = (TextItem) item;
  ZnWInfo       *wi = item->wi;
  char          *str;

  if (text->text) {
    str = ZnMalloc((strlen(text->text) + 1) * sizeof(char));
    strcpy(str, text->text);
    text->text = str;
  }
  if (text->fill_pattern != ZnUnspecifiedImage) {
    text->fill_pattern = ZnGetImageByValue(text->fill_pattern, NULL, NULL);
  }
  text->color = ZnGetGradientByValue(text->color);
  text->font = Tk_GetFont(wi->interp, wi->win, Tk_NameOfFont(text->font));
#ifdef GL
  text->tfi = ZnGetTexFont(wi, text->font);
#endif

  /*
   * We always need to invalidate, either because the model
   * has not done its layout (text_info == NULL) or because
   * we must unshare the pointers to the text that are in
   * text_info.
   */
  text->text_info = NULL;
  ZnITEM.Invalidate(item, ZN_COORDS_FLAG|ZN_LAYOUT_FLAG);
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
  TextItem      text = (TextItem) item;

  if (text->text) {
    ZnFree(text->text);
  }
  if (text->fill_pattern != ZnUnspecifiedImage) {
    ZnFreeImage(text->fill_pattern, NULL, NULL);
    text->fill_pattern = ZnUnspecifiedImage;
  }
  ZnFreeGradient(text->color);
  Tk_FreeFont(text->font);
#ifdef GL
  if (text->tfi) {
    ZnFreeTexFont(text->tfi);
  }
#endif
  
  if (text->text_info) {
    ZnListFree(text->text_info);
  }
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
  TextItem      text = (TextItem) item;
  ZnItem        old_connected = item->connected_item;
  unsigned int  num_chars;
#ifdef GL
  Tk_Font       old_font = text->font;
#endif

  if (ZnConfigureAttributes(item->wi, item, item, text_attrs,
                            argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
  }

#ifdef GL
  if (old_font != text->font) {
    if (text->tfi) {
      ZnFreeTexFont(text->tfi);
      text->tfi = ZnGetTexFont(item->wi, text->font);
    }
  }
#endif
  num_chars = 0;
  if (text->text) {
    num_chars = Tcl_NumUtfChars(text->text, (int) strlen(text->text));
  }
  if (text->num_chars != num_chars) {
    ZnTextInfo *ti = &item->wi->text_info;
    /*
     * The text has changed, update the selection and
     * insertion pos to keep them valid.
     */
    if (item == ti->sel_item) {
      if (ti->sel_last > (int) num_chars) {
        ti->sel_last = num_chars;
      }
      if (ti->sel_first >= ti->sel_last) {
        ti->sel_item = ZN_NO_ITEM;
        ti->sel_field = ZN_NO_PART;
      }
      if ((ti->anchor_item == item) && (ti->sel_anchor > (int) num_chars)) {
        ti->sel_anchor = num_chars;
      }
    }
    if (text->insert_index > num_chars) {
      text->insert_index = num_chars;
    }
    text->num_chars = num_chars;
  }

  if (ISSET(*flags, ZN_ITEM_FLAG)) {
    /*
     * If the new connected item is not appropriate back up
     * to the old one.
     */
    if ((item->connected_item == ZN_NO_ITEM) ||
        (ISSET(item->connected_item->class->flags, ZN_CLASS_HAS_ANCHORS) &&
         (item->parent == item->connected_item->parent))) {
      ZnITEM.UpdateItemDependency(item, old_connected);
    }
    else {
      item->connected_item = old_connected;
    }
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
  if (ZnQueryAttribute(item->wi->interp, item, text_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }  

  return TCL_OK;
}


/*
 * Compute the transformation to be used and the origin
 * of the text (upper left point in item coordinates).
 */
static ZnTransfo *
ComputeTransfoAndOrigin(ZnItem    item,
                        ZnPoint   *origin)
{
  TextItem text = (TextItem) item;

  /*
   * The connected item support anchors, this is checked by configure.
   */
  if (item->connected_item != ZN_NO_ITEM) {
    ZnTransfo inv;

    item->connected_item->class->GetAnchor(item->connected_item,
                                           text->connection_anchor,
                                           origin);

    /* GetAnchor return a position in device coordinates not in
     * the item coordinate space. To compute the text origin
     * (upper left corner), we must apply the inverse transform
     * to the ref point before calling anchor2origin.
     */
    ZnTransfoInvert(item->transfo, &inv);
    ZnTransformPoint(&inv, origin, origin);
    ZnAnchor2Origin(origin, (ZnReal) text->max_width,
                    (ZnReal) text->height, text->anchor, origin);
    origin->x = ZnNearestInt(origin->x);
    origin->y = ZnNearestInt(origin->y);
    /*
     * The relevant transform in case of an attachment is the item
     * transform alone. This is case of local coordinate space where
     * only the translation is a function of the whole transform
     * stack, scale and rotation are reset.
     */
    return item->transfo;
  }
  else {
    ZnPoint p;
    p.x = p.y = 0;
    ZnAnchor2Origin(&p, (ZnReal) text->max_width,
                    (ZnReal) text->height, text->anchor, origin);
    origin->x = ZnNearestInt(origin->x);
    origin->y = ZnNearestInt(origin->y);

    return item->wi->current_transfo;
  }
}


/*
 * Compute the selection and the cursor geometry.
 */
void
ComputeCursor(ZnItem       item,
              int          *cursor_line,
              unsigned int *cursor_offset)
{
  TextItem      text = (TextItem) item;
  ZnWInfo       *wi = item->wi;
  ZnTextInfo    *ti = &wi->text_info;
  TextLineInfo  lines, lines_ptr;
  unsigned int  i, line_index, insert_index, num_lines;

  num_lines = ZnListSize(text->text_info);
  if (num_lines == 0) {
    *cursor_line = 0;
  }

  lines = ZnListArray(text->text_info);
  if ((wi->focus_item == item) && ISSET(wi->flags, ZN_GOT_FOCUS) && ti->cursor_on) {
    insert_index = Tcl_UtfAtIndex(text->text, (int) text->insert_index)-text->text;
    for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
      /*
       * Mark the line with the cursor and compute its
       * position along the X axis.
       */
      line_index = lines_ptr->start - text->text;
      if ((insert_index >= line_index) &&
          (insert_index <= line_index + lines_ptr->num_bytes)) {
        *cursor_line = i;
        *cursor_offset = Tk_TextWidth(text->font, (char *) lines_ptr->start,
                                      insert_index - line_index);
      }
    }
  }
  
}

static void
ComputeSelection(ZnItem         item,
                 int            *sel_first_line,
                 int            *sel_last_line,
                 unsigned int   *sel_start_offset,
                 unsigned int   *sel_stop_offset)
{  
  TextItem      text = (TextItem) item;
  ZnWInfo       *wi = item->wi;
  ZnTextInfo    *ti = &wi->text_info;
  TextLineInfo  lines_ptr, lines;
  int           i, num_lines, byte_index;
  unsigned int  line_index;
  unsigned int  sel_first, sel_last;

  num_lines = ZnListSize(text->text_info);

  if ((ti->sel_item != item) || !num_lines) {
    return;
  }

  lines = ZnListArray(text->text_info);

  sel_first = Tcl_UtfAtIndex(text->text, ti->sel_first)-text->text;
  sel_last = Tcl_UtfAtIndex(text->text, ti->sel_last+1)-text->text;
  for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
    /*
     * Compute the selection first and last line as well as
     * the positions along the X axis.
     */
    line_index = lines_ptr->start - text->text;
    if ((sel_last >= line_index) &&
        (sel_first <= (line_index + lines_ptr->num_bytes))) {
      if (*sel_first_line < 0) {
        byte_index = sel_first - line_index;
        if (byte_index <= 0) {
          *sel_first_line = i;
          *sel_start_offset = 0;
          /*printf("sel_start_offset 1 : %d\n", *sel_start_offset);*/
        }
        else if (byte_index <= lines_ptr->num_bytes) {
          *sel_first_line = i;
          *sel_start_offset = Tk_TextWidth(text->font, (char *) lines_ptr->start,
                                           byte_index);
          /*printf("sel_start_offset 2 : %d\n", *sel_start_offset);*/
        }
      }
      byte_index = ti->sel_last+1 - line_index;
      *sel_last_line = i;
      if (byte_index == lines_ptr->num_bytes+1)
        *sel_stop_offset = lines_ptr->width;
      else if (byte_index <= lines_ptr->num_bytes)
        *sel_stop_offset = Tk_TextWidth(text->font, (char *) lines_ptr->start,
                                        byte_index);
    }
  }
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
  TextItem      text = (TextItem) item;
  TextLineInfo  infos;
  Tk_FontMetrics fm;
  ZnTransfo     *transfo;
  int           i, num_lines, cur_dy, font_height;
  
  ZnResetBBox(&item->item_bounding_box);
  
  Tk_GetFontMetrics(text->font, &fm);
  font_height = fm.ascent+fm.descent;
  
  /*
   * The layout need not be done each time the item is moved, scaled
   * or rotated.
   */
  if (ISSET(item->inv_flags, ZN_LAYOUT_FLAG)) {
    char *scan;
    int  wrap, prev_num_lines;

    text->max_width = 0;
    if (text->text_info != NULL) {
      prev_num_lines = ZnListSize(text->text_info);
      ZnListEmpty(text->text_info);
    }
    else {
      prev_num_lines = 0;
      text->text_info = ZnListNew(1, sizeof(TextLineInfoStruct));
    }
    
    if (text->width > 0) {
      wrap = text->width;
    }
    else {
      wrap = 100000;
    }
    
    if ((scan = text->text) != NULL) {
      TextLineInfoStruct info;

      while (*scan) {
        char    *special;
        int     num, w;

        /*
         * Limit the excursion of Tk_MeasureChars to the end
         * of the line. Do not include \n in the measure done.
         */
        num = strcspn(scan, "\r\n");
        special = scan + num;
        info.num_bytes = Tk_MeasureChars(text->font, scan, num, wrap,
                                         TK_WHOLE_WORDS|TK_AT_LEAST_ONE, &w);
        
        info.width = w;
        info.start = scan;
        text->max_width = MAX(info.width, text->max_width);
        
        scan += info.num_bytes;

        /*
         * Skip the newline line character.
         */
        if ((*scan == '\r') || (*scan == '\n')) {
          scan++;
        }
        else {
          /*
           * Skip white spaces occuring after an
           * automatic line break.
           */
          while (*scan == ' ') {
            scan++;
          }
        }
        
        ZnListAdd(text->text_info, &info, ZnListTail);
        /*printf("adding a text info : %s, num_bytes :  %d, width : %d\n",
          info.start, info.num_bytes, info.width);*/
      }
      if (*text->text && ((scan[-1] == '\r') || (scan[-1] == '\n'))) {
        /* Build a text info even for an empty line
         * at the end of text or for an empty text.
         * It is needed to enable selection and cursor
         * insertion to behave correctly.
         */
        info.num_bytes = 0;
        info.width = 0;
        info.start = scan;
        ZnListAdd(text->text_info, &info, ZnListTail);
      }
    }
  
    /*
     * Compute x & y positions for all lines in text_info. The coordinates are
     * in text natural units NOT transformed units.
     */
    cur_dy = fm.ascent;
    num_lines = ZnListSize(text->text_info);
    infos = (TextLineInfo) ZnListArray(text->text_info);
    
    for (i = 0; i < num_lines; i++) {
      switch (text->alignment) {
      case TK_JUSTIFY_LEFT:
        infos[i].origin_x = 0;
        break;
      case TK_JUSTIFY_CENTER:
        infos[i].origin_x = (text->max_width + 1 - infos[i].width)/2;
        break;
      case TK_JUSTIFY_RIGHT:
        infos[i].origin_x = text->max_width + 1 - infos[i].width;
        break;
      }
      infos[i].origin_y = cur_dy;
      cur_dy += font_height + text->spacing;
      /*printf("fixing line %d x : %d, y : %d\n", i, infos[i].origin_x,
        infos[i].origin_y);*/
    }
  } /* ISSET(item->inv_flags, INV_TEXT_LAYOUT) */
    
  text->height = font_height;
  if (text->text_info && text->max_width) {
    unsigned int h, cursor_offset;
    int          cursor_line;
    ZnPoint      origin, box[4];

    num_lines = ZnListSize(text->text_info);
    infos = ZnListArray(text->text_info);
    h = num_lines * font_height + (num_lines-1) * text->spacing;
    text->height = MAX(text->height, h);

    transfo = ComputeTransfoAndOrigin(item, &origin);
    
    text->poly[0].x = origin.x;
    text->poly[0].y = origin.y;
    text->poly[3].x = text->poly[0].x + text->max_width;
    text->poly[3].y = text->poly[0].y + text->height;
    text->poly[1].x = text->poly[0].x;
    text->poly[1].y = text->poly[3].y;
    text->poly[2].x = text->poly[3].x;
    text->poly[2].y = text->poly[0].y;
    ZnTransformPoints(transfo, text->poly, text->poly, 4);       

    /*
     * Add to the bounding box.
     */
    ZnAddPointsToBBox(&item->item_bounding_box, text->poly, 4);

    /*
     * Add the cursor shape to the bbox.
     */
    cursor_line = -1;
    ComputeCursor(item, &cursor_line, &cursor_offset);
    if (cursor_line >= 0) {
      if (num_lines) {
        box[0].x = origin.x + infos[cursor_line].origin_x + cursor_offset -
          wi->text_info.insert_width/2;
        box[0].y = origin.y + infos[cursor_line].origin_y - fm.ascent + 1;
      }
      else {
        box[0].x = origin.x;
        box[0].y = origin.y;
      }
      box[2].x = box[0].x + wi->text_info.insert_width;
      box[2].y = box[0].y + font_height - 1;
      box[1].x = box[2].x;
      box[1].y = box[0].y;
      box[3].x = box[0].x;
      box[3].y = box[2].y;
      ZnTransformPoints(transfo, box, box, 4);
      ZnAddPointsToBBox(&item->item_bounding_box, box, 4);
    }
  }

  /*printf("bbox origin: %g %g corner %g %g\n",
         item->item_bounding_box.orig.x, item->item_bounding_box.orig.y,
         item->item_bounding_box.corner.x, item->item_bounding_box.corner.y);*/
  /*
   * Update connected items.
   */
  SET(item->flags, ZN_UPDATE_DEPENDENT_BIT);
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
  TextItem      text = (TextItem) item;
  int           inside = -1;
  ZnBool        first_done = False;
  int           num_lines, i;
  TextLineInfo  lines, lines_ptr;
  Tk_FontMetrics fm;
  int           font_height;
  ZnBBox        line_bbox, *area = ta->area;
  ZnPoint       box[4], p, origin;
  ZnTransfo     inv, *transfo;

  if (!text->text_info || !text->text) {
    return -1;
  }
  
  transfo = ComputeTransfoAndOrigin(item, &origin);
  box[0] = area->orig;
  box[2] = area->corner;
  box[1].x = box[2].x;
  box[1].y = box[0].y;
  box[3].x = box[0].x;
  box[3].y = box[2].y;
  ZnTransfoInvert(transfo, &inv);
  ZnTransformPoints(&inv, box, box, 4);

  lines = (TextLineInfo) ZnListArray(text->text_info);
  num_lines = ZnListSize(text->text_info);
  Tk_GetFontMetrics(text->font, &fm);
  font_height = fm.descent + fm.ascent;
  if (text->spacing > 0) {
    font_height += text->spacing;
  }

  /*printf("text %d, num lines=%d\n", item->id, num_lines);*/
  for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
    ZnResetBBox(&line_bbox);
    p.x = origin.x + lines_ptr->origin_x;
    p.y = origin.y + lines_ptr->origin_y - fm.ascent;
    ZnAddPointToBBox(&line_bbox, p.x, p.y);
    ZnAddPointToBBox(&line_bbox, p.x + lines_ptr->width, p.y + font_height);
    if (!first_done) {
      first_done = True;
      inside = ZnPolygonInBBox(box, 4, &line_bbox, NULL);
      if (inside == 0) {
        return 0;
      }
    }
    else {
      if (ZnPolygonInBBox(box, 4, &line_bbox, NULL) == 0) {
        return 0;
      }
    }
  }

  return inside;
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
  TextItem      text = (TextItem) item;
  XGCValues     values;
  ZnPoint       pos, box[4], origin;
  ZnTransfo     *transfo;
  Drawable      drw;
  GC            gc;
  XImage        *src_im, *dest_im=NULL;
  unsigned int  dest_im_width=0, dest_im_height=0;
  unsigned int  gc_mask = 0;
  Tk_FontMetrics fm;
  unsigned int  font_height;  
  int           num_lines, i;
  TextLineInfo  lines, lines_ptr;
  ZnTextInfo    *ti = &wi->text_info;
  unsigned int  underline_thickness, underline_pos=0, overstrike_pos=0;
  int           sel_first_line=-1, sel_last_line=-1, cursor_line=-1;
  unsigned int  sel_start_offset=0, sel_stop_offset=0, cursor_offset=0;

  if (!text->text_info/* || !text->text*/) {
    return;
  }

  lines = (TextLineInfo) ZnListArray(text->text_info);
  num_lines = ZnListSize(text->text_info);
  Tk_GetFontMetrics(text->font, &fm);
  font_height = fm.ascent+fm.descent;

  transfo = ComputeTransfoAndOrigin(item, &origin);

  /*
   * Compute the selection and the cursor geometry.
   */
  ComputeCursor(item, &cursor_line, &cursor_offset);
  ComputeSelection(item, &sel_first_line, &sel_last_line,
                   &sel_start_offset, &sel_stop_offset);


  ZnTransformPoint(transfo, &origin, &pos);

  /*printf("sel 1st : %d offset : %d, sel last : %d offset : %d\n",
    sel_first_line, sel_start_offset, sel_last_line, sel_stop_offset);*/
  /*
   * Setup the gc for the selection and fill the selection.
   */
  if ((ti->sel_item == item) && (sel_first_line >= 0)) {
    XPoint xp[4];

    values.foreground = ZnGetGradientPixel(ti->sel_color, 0.0);
    values.fill_style = FillSolid;
    XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCForeground, &values);
    
    if (sel_first_line == sel_last_line) {
      box[0].x = origin.x + 
        lines[sel_first_line].origin_x + sel_start_offset;
      box[0].y = origin.y +
        lines[sel_first_line].origin_y - fm.ascent;
      box[2].x = box[0].x + sel_stop_offset - sel_start_offset;
      box[2].y = box[0].y + font_height;
      box[1].x = box[2].x;
      box[1].y = box[0].y;
      box[3].x = box[0].x;
      box[3].y = box[2].y;
      ZnTransformPoints(transfo, box, box, 4);
      for (i = 0; i < 4; i++) {
        xp[i].x = (short) box[i].x;
        xp[i].y = (short) box[i].y;
      }
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, 4, Convex, CoordModeOrigin);
    }
    else {
      box[0].x = origin.x + 
        lines[sel_first_line].origin_x + sel_start_offset;
      box[0].y = origin.y +
        lines[sel_first_line].origin_y - fm.ascent;
      box[2].x = box[0].x +
        text->max_width-lines[sel_first_line].origin_x-sel_start_offset;
      box[2].y = box[0].y + font_height;
      box[1].x = box[2].x;
      box[1].y = box[0].y;
      box[3].x = box[0].x;
      box[3].y = box[2].y;
      ZnTransformPoints(transfo, box, box, 4);
      for (i = 0; i < 4; i++) {
        xp[i].x = (short) box[i].x;
        xp[i].y = (short) box[i].y;
      }
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, 4, Convex, CoordModeOrigin);
      for (i = sel_first_line+1, lines_ptr = &lines[sel_first_line+1];
           i < sel_last_line; i++, lines_ptr++) {
        box[0].x = origin.x;
        box[0].y = origin.y + lines_ptr->origin_y - fm.ascent;
        box[2].x = box[0].x + text->max_width;
        box[2].y = box[0].y + font_height;
        box[1].x = box[2].x;
        box[1].y = box[0].y;
        box[3].x = box[0].x;
        box[3].y = box[2].y;
        ZnTransformPoints(transfo, box, box, 4);
        for (i = 0; i < 4; i++) {
          xp[i].x = (short) box[i].x;
          xp[i].y = (short) box[i].y;
        }
        XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, 4, Convex, CoordModeOrigin);
      }
      box[0].x = origin.x;
      box[0].y = origin.y + lines[sel_last_line].origin_y - fm.ascent;
      box[2].x = box[0].x + lines[sel_last_line].origin_x + sel_stop_offset;
      box[2].y = box[0].y + font_height;
      box[1].x = box[2].x;
      box[1].y = box[0].y;
      box[3].x = box[0].x;
      box[3].y = box[2].y;
      ZnTransformPoints(transfo, box, box, 4);
      for (i = 0; i < 4; i++) {
        xp[i].x = (short) box[i].x;
        xp[i].y = (short) box[i].y;
      }
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xp, 4, Convex, CoordModeOrigin);
    }
  }

  /*printf("cursor line : %d, cursor offset : %d\n", cursor_line, cursor_offset);*/
  /*
   * Setup the gc for the cursor and draw it.
   */
  if (cursor_line >= 0 &&
      (wi->focus_item == item) && ti->cursor_on) {
    values.fill_style = FillSolid;
    values.line_width = ti->insert_width;
    values.foreground = ZnGetGradientPixel(ti->insert_color, 0.0);
    XChangeGC(wi->dpy, wi->gc, GCForeground|GCFillStyle|GCLineWidth, &values);

    box[0].x = origin.x + lines[cursor_line].origin_x + cursor_offset;
    box[0].y = origin.y + lines[cursor_line].origin_y - fm.ascent + 1;
    box[1].x = box[0].x;
    box[1].y = box[0].y + font_height - 1;
    ZnTransformPoints(transfo, box, box, 2);
    XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
              (int) box[0].x, (int) box[0].y, (int) box[1].x, (int) box[1].y);
  }


  /*
   * If the current transform is a pure translation, it is
   * possible to optimize by directly drawing to the X back
   * buffer. Else, we draw in a temporary buffer, get
   * its content as an image, transform the image into another
   * one and use this last image as a mask to draw in the X
   * back buffer.
   */
  if (ZnTransfoIsTranslation(transfo)) {
    drw = wi->draw_buffer;

    gc = wi->gc;
    values.foreground = ZnGetGradientPixel(text->color, 0.0);    
  }
  else {
    dest_im_width = (unsigned int) (item->item_bounding_box.corner.x -
                                    item->item_bounding_box.orig.x);
    dest_im_height = (unsigned int) (item->item_bounding_box.corner.y -
                                     item->item_bounding_box.orig.y);

    drw = Tk_GetPixmap(wi->dpy, wi->draw_buffer,
                       MAX(dest_im_width, text->max_width),
                       MAX(dest_im_height, text->height), 1);
    gc = XCreateGC(wi->dpy, drw, 0, NULL);
    XSetForeground(wi->dpy, gc, 0);
    XFillRectangle(wi->dpy, drw, gc, 0, 0,
                   MAX(dest_im_width, text->max_width),
                   MAX(dest_im_height, text->height));
    dest_im = XCreateImage(wi->dpy, Tk_Visual(wi->win), 1,
                           XYPixmap, 0, NULL, dest_im_width, dest_im_height,
                           8, 0);
    dest_im->data = ZnMalloc(dest_im->bytes_per_line * dest_im->height);
    memset(dest_im->data, 0, dest_im->bytes_per_line * dest_im->height);

    values.foreground = 1;
 
    pos.x = 0;
    pos.y = 0;
  }

  /*
   * Setup the gc to render the text and draw it.
   */
  values.font = Tk_FontId(text->font);
  gc_mask = GCFont | GCForeground;
  if (text->fill_pattern != ZnUnspecifiedImage) {
    values.fill_style = FillStippled;
    values.stipple = ZnImagePixmap(text->fill_pattern, wi->win);
    gc_mask |= GCFillStyle | GCStipple;
  }
  else {
    values.fill_style = FillSolid;
    gc_mask |= GCFillStyle;
  }
  if (ISSET(text->flags, UNDERLINED) || ISSET(text->flags, OVERSTRIKED)) {
    /*
     * These 3 values should be fetched from the font.
     * Currently I don't know how without diving into
     * Tk internals.
     */
    underline_thickness = 2;
    underline_pos = fm.descent/2;
    overstrike_pos = fm.ascent*3/10;
    values.line_style = LineSolid;
    values.line_width = underline_thickness;
    gc_mask |= GCLineStyle | GCLineWidth;
  }
  XChangeGC(wi->dpy, gc, gc_mask, &values);
  for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
    int tmp_x, tmp_y;
    
    tmp_x = (int)(pos.x + lines_ptr->origin_x);
    tmp_y = (int)(pos.y + lines_ptr->origin_y);
    Tk_DrawChars(wi->dpy, drw, gc,
                 text->font, (char *) lines_ptr->start,
                 (int) lines_ptr->num_bytes, tmp_x, tmp_y);
    if (ISSET(text->flags, UNDERLINED)) {
      int y_under = tmp_y + underline_pos;
      
      XDrawLine(wi->dpy, drw, gc,
                tmp_x, y_under, tmp_x + (int) lines_ptr->width, y_under);
    }
    if (ISSET(text->flags, OVERSTRIKED)) {
      int y_over = tmp_y-overstrike_pos;
      
      XDrawLine(wi->dpy, drw, gc,
                tmp_x, y_over, tmp_x + (int) lines_ptr->width, y_over);
    }
  }

  if (dest_im != NULL) {
    src_im = XGetImage(wi->dpy, drw, 0, 0, text->max_width, text->height,
                       1, XYPixmap);

    box[0].x = origin.x;
    box[0].y = origin.y;
    box[3].x = box[0].x + text->max_width;
    box[3].y = box[0].y + text->height;
    box[1].x = box[0].x;
    box[1].y = box[3].y;
    box[2].x = box[3].x;
    box[2].y = box[0].y;
    ZnTransformPoints(transfo, box, box, 4);
    for (i = 0; i < 4; i++) {
      box[i].x -= item->item_bounding_box.orig.x;
      box[i].y -= item->item_bounding_box.orig.y;
      box[i].x = ZnNearestInt(box[i].x);
      box[i].y = ZnNearestInt(box[i].y);
    }

    ZnMapImage(src_im, dest_im, box);

    TkPutImage(NULL, 0,wi->dpy, drw, gc, dest_im,
               0, 0, 0, 0, dest_im_width, dest_im_height);

    values.foreground = ZnGetGradientPixel(text->color, 0.0);
    values.stipple = drw;
    values.ts_x_origin = (int) item->item_bounding_box.orig.x;
    values.ts_y_origin = (int) item->item_bounding_box.orig.y;
    values.fill_style = FillStippled;
    XChangeGC(wi->dpy, wi->gc,
              GCFillStyle|GCStipple|GCTileStipXOrigin|GCTileStipYOrigin|GCForeground,
              &values);
    XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc,
                   (int) item->item_bounding_box.orig.x,
                   (int) item->item_bounding_box.orig.y,
                   dest_im_width, dest_im_height);

    XFreeGC(wi->dpy, gc);
    Tk_FreePixmap(wi->dpy, drw);
    XDestroyImage(src_im);
    XDestroyImage(dest_im);
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
Render(ZnItem   item)
{
  ZnWInfo       *wi = item->wi;
  TextItem      text = (TextItem) item;
  TextLineInfo  lines, lines_ptr;
  ZnTextInfo    *ti = &wi->text_info;
  ZnPoint       o, c, origin;
  ZnTransfo     *transfo;
  GLdouble      m[16];
  int           i, num_lines;
  XColor        *color;
  unsigned short alpha;
  Tk_FontMetrics fm;
  int           font_height;  
  int           underline_thickness, underline_pos=0, overstrike_pos=0;
  int           sel_first_line=-1, sel_last_line=-1, cursor_line=-1;
  int           sel_start_offset=0, sel_stop_offset=0, cursor_offset=0;

  if (!text->text_info) {
    return;
  }
  
#ifdef GL_LIST
  if (!item->gl_list) {
    item->gl_list = glGenLists(1);
    glNewList(item->gl_list, GL_COMPILE);
#endif
    lines = (TextLineInfo) ZnListArray(text->text_info);
    num_lines = ZnListSize(text->text_info);
    Tk_GetFontMetrics(text->font, &fm);
    font_height = fm.ascent+fm.descent;
    
    /*
     * These 3 values should be fetched from the font.
     * Currently I don't know how without diving into
     * Tk internals.
     */
    underline_thickness = 2;
    underline_pos = fm.descent/2;
    overstrike_pos = fm.ascent*3/10;
    
    transfo = ComputeTransfoAndOrigin(item, &origin);
  
    /*
     * Compute the selection and the cursor geometry.
     */
    ComputeCursor(item, &cursor_line, &cursor_offset);
    ComputeSelection(item, &sel_first_line, &sel_last_line,
                     &sel_start_offset, &sel_stop_offset);
  
    ZnGLMakeCurrent(wi->dpy, wi);

    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    glPushMatrix();
    memset(m, 0, sizeof(m));
    m[0] = m[5] = m[15] = 1.0;
    if (transfo) {
      m[0] = transfo->_[0][0]; m[1] = transfo->_[0][1];
      m[4] = transfo->_[1][0]; m[5] = transfo->_[1][1];
      m[12] = ZnNearestInt(transfo->_[2][0]);
      m[13] = ZnNearestInt(transfo->_[2][1]);
    }
    glLoadMatrixd(m);
    glTranslated(origin.x, origin.y, 0.0);
    glPushMatrix();    

    /*
     * Render the selection.
     */
    if ((ti->sel_item == item) && (sel_first_line >= 0)) {
      color = ZnGetGradientColor(ti->sel_color, 0.0, &alpha);
      alpha = ZnComposeAlpha(alpha, wi->alpha);
      glColor4us(color->red, color->green, color->blue, alpha);
      o.x = lines[sel_first_line].origin_x + sel_start_offset;
      o.y = lines[sel_first_line].origin_y - fm.ascent;
      glBegin(GL_QUADS);
      if (sel_first_line == sel_last_line) {
        c.x = o.x + sel_stop_offset - sel_start_offset;
        c.y = o.y + font_height;
        glVertex2d(o.x, o.y);
        glVertex2d(o.x, c.y);
        glVertex2d(c.x, c.y);
        glVertex2d(c.x, o.y);
      }
      else {
        c.x = o.x + (text->max_width - 
                     lines[sel_first_line].origin_x - sel_start_offset);
        c.y = o.y + font_height;
        glVertex2d(o.x, o.y);
        glVertex2d(o.x, c.y);
        glVertex2d(c.x, c.y);
        glVertex2d(c.x, o.y);
        for (i = sel_first_line+1, lines_ptr = &lines[sel_first_line+1];
             i < sel_last_line; i++, lines_ptr++) {
          o.x = 0;
          o.y = lines_ptr->origin_y - fm.ascent;
          c.x = o.x + text->max_width;
          c.y = o.y + font_height;
          glVertex2d(o.x, o.y);
          glVertex2d(o.x, c.y);
          glVertex2d(c.x, c.y);
          glVertex2d(c.x, o.y);
        }
        o.x = 0;
        o.y = lines[sel_last_line].origin_y - fm.ascent;
        c.x = o.x + lines[sel_last_line].origin_x + sel_stop_offset;
        c.y = o.y + font_height;
        glVertex2d(o.x, o.y);
        glVertex2d(o.x, c.y);
        glVertex2d(c.x, c.y);
        glVertex2d(c.x, o.y);
      }
      glEnd();
    }

    /*
     * Render the cursor.
     */
    if ((cursor_line >= 0) &&
        (wi->focus_item == item) && ti->cursor_on) {
      color = ZnGetGradientColor(ti->insert_color, 0.0, &alpha);
      alpha = ZnComposeAlpha(alpha, wi->alpha);
      glColor4us(color->red, color->green, color->blue, alpha);
      glLineWidth((GLfloat) ti->insert_width);
      
      o.x = lines[cursor_line].origin_x + cursor_offset;
      o.y = lines[cursor_line].origin_y - fm.ascent + 1;
      c.x = o.x;
      c.y = o.y + font_height - 1;

      glBegin(GL_LINES);
      glVertex2d(o.x, o.y);
      glVertex2d(c.x, c.y);
      glEnd();
    }

    /*
     * Render the text.
     */
    glEnable(GL_TEXTURE_2D);
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glBindTexture(GL_TEXTURE_2D, ZnTexFontTex(text->tfi));
    color = ZnGetGradientColor(text->color, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
    glColor4us(color->red, color->green, color->blue, alpha);
    
    for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
      glTranslated(lines_ptr->origin_x, lines_ptr->origin_y, 0.0);

      if (ISSET(text->flags, UNDERLINED) || ISSET(text->flags, OVERSTRIKED)) {
        glLineWidth((GLfloat) underline_thickness);
        glDisable(GL_TEXTURE_2D);
        if (ISSET(text->flags, UNDERLINED)) {
          glBegin(GL_LINES);
          glVertex2d(0, underline_pos);
          glVertex2d(lines_ptr->width, underline_pos);
          glEnd();
        }
        if (ISSET(text->flags, OVERSTRIKED)) {
          glBegin(GL_LINES);
          glVertex2d(0, -overstrike_pos);
          glVertex2d(lines_ptr->width, -overstrike_pos);
          glEnd();
        }
        glEnable(GL_TEXTURE_2D);
      }

      ZnRenderString(text->tfi, lines_ptr->start, lines_ptr->num_bytes);
      glPopMatrix();
      glPushMatrix();
    }

    glPopMatrix();
    glPopMatrix();
      
    glDisable(GL_TEXTURE_2D);
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
  TextItem      text = (TextItem) item;
  double        dist = 1.0e40, new_dist;
  int           num_lines, i;
  TextLineInfo  lines, lines_ptr;
  Tk_FontMetrics fm;
  int           font_height;
  ZnPoint       box[4], origin, *p = ps->point;
  ZnTransfo     *transfo;

  if (!text->text_info || !text->text) {
    return dist;
  }
  
  transfo = ComputeTransfoAndOrigin(item, &origin);
  
  lines = ZnListArray(text->text_info);
  num_lines = ZnListSize(text->text_info);
  Tk_GetFontMetrics(text->font, &fm);
  font_height = fm.descent + fm.ascent;
  if (text->spacing > 0) {
    font_height += text->spacing;
  }  

  for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
    box[0].x = origin.x + lines_ptr->origin_x;
    box[0].y = origin.y + lines_ptr->origin_y - fm.ascent;
    box[2].x = box[0].x + lines_ptr->width;
    box[2].y = box[0].y + font_height;
    box[1].x = box[2].x;
    box[1].y = box[0].y;
    box[3].x = box[0].x;
    box[3].y = box[2].y;
    ZnTransformPoints(transfo, box, box, 4);
    new_dist = ZnPolygonToPointDist(box, 4, p);
    dist = MIN(dist, new_dist);
    if (dist <= 0.0) {
      dist = 0.0;
      break;
    }
  }

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
  ZnWInfo        *wi = item->wi;
  TextItem       text = (TextItem) item;
  Tk_FontMetrics fm;
  TextLineInfo   lines, lines_ptr;
  ZnPoint        origin;
  ZnReal         alignment;
  int            i, num_lines;
  char           path[150];

  lines = (TextLineInfo) ZnListArray(text->text_info);
  num_lines = ZnListSize(text->text_info);

  if (Tk_PostscriptFont(wi->interp, wi->ps_info, text->font) != TCL_OK) {
    return TCL_ERROR;
  }
  if (Tk_PostscriptColor(wi->interp, wi->ps_info,
                         ZnGetGradientColor(text->color, 0.0, NULL)) != TCL_OK) {
    return TCL_ERROR;
  }
  if (text->fill_pattern != ZnUnspecifiedImage) {
    Tcl_AppendResult(wi->interp, "/StippleText {\n    ", NULL);
    Tk_PostscriptStipple(wi->interp, wi->win, wi->ps_info,
                         ZnImagePixmap(text->fill_pattern, wi->win));
    Tcl_AppendResult(wi->interp, "} bind def\n", NULL);
  }

  ComputeTransfoAndOrigin(item, &origin);

  sprintf(path, "/InitialTransform load setmatrix\n"
          "[%.15g %.15g %.15g %.15g %.15g %.15g] concat\n"
          "1 -1 scale\n",
          wi->current_transfo->_[0][0], wi->current_transfo->_[0][1], 
          wi->current_transfo->_[1][0], wi->current_transfo->_[1][1], 
          wi->current_transfo->_[2][0], wi->current_transfo->_[2][1]);
  Tcl_AppendResult(wi->interp, path, NULL);

  sprintf(path, "%.15g %.15g [\n", origin.x, origin.y);
  Tcl_AppendResult(wi->interp, path, NULL);

  /*
   * Emit code to draw the lines.
   */
  for (i = 0, lines_ptr = lines; i < num_lines; i++, lines_ptr++) {
    ZnPostscriptString(wi->interp, lines_ptr->start, lines_ptr->num_bytes);
  }

  switch (text->alignment) {
    default:
    case TK_JUSTIFY_LEFT:
      alignment = 0;
      break;
    case TK_JUSTIFY_CENTER:
      alignment = 0.5;
      break;
    case TK_JUSTIFY_RIGHT:
      alignment = 1;
      break;
  }
  Tk_GetFontMetrics(text->font, &fm);
  /* DrawText should not mess with anchors, they are already accounted for */
  sprintf(path, "] %d %g %g %g %s DrawText\n", fm.linespace, 0.0, 0.0, 
          alignment, (text->fill_pattern == ZnUnspecifiedImage) ? "false" : "true");
  Tcl_AppendResult(wi->interp, path, NULL);

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
  TextItem      text = (TextItem) item;

  if (text->num_chars != 0) {
    ZnRectOrigin2Anchor(text->poly, anchor, p);
  }
  else {
    *p = *text->poly;
  }
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
  TextItem      text = (TextItem) item;

  ZnTriStrip1(tristrip, text->poly, 4, False);

  return False;
}


/*
 **********************************************************************************
 *
 * Coords --
 *      Return or edit the item origin. This doesn't take care of
 *      the possible attachment. The change will be effective at the
 *      end of the attachment.
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
  TextItem      text = (TextItem) item;
  
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " texts can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on texts", NULL);
      return TCL_ERROR;
    }
    text->pos = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    *num_pts = 1;
    *pts = &text->pos;
  }
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Index --
 *      Parse a text index and return its value and a
 *      error status (standard Tcl result).
 *
 **********************************************************************************
 */
static int
PointToChar(TextItem    text,
            int         x,
            int         y)
{
  int           i, n, num_lines, dummy, byte_index;
  ZnPoint       p;
  TextLineInfo  ti;
  Tk_FontMetrics fm;
  ZnReal        a, b;

  byte_index = 0;
  if (!text->text_info) {
    return 0;
  }
  
  p.x = x;
  p.y = y;
  a = ZnLineToPointDist(&text->poly[0], &text->poly[2], &p, NULL);
  b = ZnLineToPointDist(&text->poly[0], &text->poly[1], &p, NULL);
  p.x = (text->max_width * b /
         hypot(text->poly[2].x - text->poly[0].x, text->poly[2].y - text->poly[0].y));
  p.y = (text->height * a /
         hypot(text->poly[1].x - text->poly[0].x, text->poly[1].y - text->poly[0].y));
  p.x = ZnNearestInt(p.x);
  p.y = ZnNearestInt(p.y);

  /*
   * Point above text, returns index 0.
   */
  if (p.y < 0) {
    return 0;
  }
  
  /*
   * Find the text line under point.
   */
  num_lines = ZnListSize(text->text_info);
  ti = ZnListArray(text->text_info);
  Tk_GetFontMetrics(text->font, &fm);
  for (i = 0; i < num_lines; i++, ti++) {
    if (p.y < ti->origin_y + fm.descent) {
      if (p.x < ti->origin_x) {
        /*
         * Point to the left of the current line, returns
         * index of first char.
         */
        byte_index = ti->start - text->text;
        break;
      }
      if (p.x >= (ti->origin_x + ti->width)) {
        /*
         * Point to the right of the current line, returns
         * index past the last char.
         */
        byte_index = ti->start + ti->num_bytes - text->text;
        break;
      }
      n = Tk_MeasureChars(text->font, ti->start, (int) ti->num_bytes,
                          (int) (p.x + 2 - ti->origin_x), TK_PARTIAL_OK,
                          &dummy);
#ifdef PTK_800
      byte_index = (ti->start + n - 1) - text->text;
#else
      byte_index = Tcl_UtfPrev(ti->start + n, ti->start) - text->text;
#endif
      break;
    }
  }
  if (i == num_lines) {
    /*
     * Point below all lines, return the index after
     * the last char in text.
     */
    ti--;
    byte_index = ti->start + ti->num_bytes - text->text;
  }

  return Tcl_NumUtfChars(text->text, byte_index);
}

/*
 * Return a new index from a current index and a
 * move command.
 *
 * 0 end of index line
 * 1 beginning of index line
 * 2 next word or end of word from index
 * 3 previous word or beginning of word from index
 * 4 previous line from index line
 * 5 next line from index line
 *
 */
static int
MoveFromIndex(TextItem     text,
              unsigned int char_index,
              int          move)
{
  unsigned int  num_lines, byte_index, num_bytes=0;
  unsigned int  line_index, line_start=0;
  TextLineInfo  lines, p;
  char          *strp;

  if (!text->text_info || !text->text) {
    return char_index;
  }
  byte_index = Tcl_UtfAtIndex(text->text, (int) char_index)-text->text;
  num_lines = ZnListSize(text->text_info);
  lines = p = ZnListArray(text->text_info);
  for (line_index = 0; line_index < num_lines; line_index++, p++) {
    line_start = p->start - text->text;
    num_bytes = p->num_bytes;
    if (line_start + num_bytes >= byte_index) {
      break;
    }
  }
  if (line_index == num_lines) {
    line_index--;
    p--;
  }

  switch (move) {
  case 0:
    byte_index = line_start + num_bytes;
    goto convert_it;
  case 1:
    byte_index = line_start;
    goto convert_it;
  case 2:
    strp = &text->text[byte_index];
    while ((strp[1] == ' ') || (strp[1] == '\n')) {
      strp++;
    }
    while ((strp[1] != ' ') && (strp[1] != '\n') && strp[1]) {
      strp++;
    }
    byte_index = strp + 1 - text->text;
    goto convert_it;
  case 3:
    strp = &text->text[byte_index];
    while ((strp != text->text) && ((strp[-1] == ' ') || (strp[-1] == '\n'))) {
      strp--;
    }
    while ((strp != text->text) && (strp[-1] != ' ') && (strp[-1] != '\n')) {
      strp--;
    }
    byte_index = strp - text->text;
    goto convert_it;
  case 4:
    if (line_index > 0) {
      byte_index -= line_start;
      p = &lines[line_index-1];
      byte_index = MIN(byte_index, p->num_bytes);
      line_start = p->start - text->text;
      byte_index += line_start;
    }
    goto convert_it;
  case 5:
    if (line_index < num_lines-1) {
      byte_index -= line_start;
      p = &lines[line_index+1];
      byte_index = MIN(byte_index, p->num_bytes);
      line_start = p->start - text->text;
      byte_index += line_start;
    }
  convert_it:
    char_index = Tcl_NumUtfChars(text->text, (int) byte_index);
  default:
    return char_index;
  }
}

static int
Index(ZnItem    item,
      int       field,
      Tcl_Obj   *index_spec,
      int       *index)
{
  TextItem      text = (TextItem) item;
  ZnWInfo       *wi = item->wi;
  ZnTextInfo    *ti = &wi->text_info;
  unsigned int  length;
  int           c, x, y;
  double        tmp;
  char          *end, *p;

  p = Tcl_GetString(index_spec);
  c = p[0];
  length = strlen(p);
  
  if ((c == 'e') && (length > 1) && (strncmp(p, "end", length) == 0)) {
    *index = text->num_chars;
  }
  else if ((c == 'e') && (length > 1) && (strncmp(p, "eol", length) == 0)) {
    *index = MoveFromIndex(text, text->insert_index, 0);
  }
  else if ((c == 'b') && (length > 1) && (strncmp(p, "bol", length) == 0)) {
    *index = MoveFromIndex(text, text->insert_index, 1);
  }
  else if ((c == 'e') && (length > 1) && (strncmp(p, "eow", length) == 0)) {
    *index = MoveFromIndex(text, text->insert_index, 2);
  }
  else if ((c == 'b') && (length > 1) && (strncmp(p, "bow", length) == 0)) {
    *index = MoveFromIndex(text, text->insert_index, 3);
  }
  else if ((c == 'u') && (strncmp(p, "up", length) == 0)) {
    *index = MoveFromIndex(text, text->insert_index, 4);
  }
  else if ((c == 'd') && (strncmp(p, "down", length) == 0)) {
    *index = MoveFromIndex(text, text->insert_index, 5);
  }
  else if ((c == 'i') && (strncmp(p, "insert", length) == 0)) {
    *index = text->insert_index;
  }
  else if ((c == 's') && (strncmp(p, "sel.first", length) == 0) &&
           (length >= 5)) {
    if (ti->sel_item != item) {
      Tcl_AppendResult(wi->interp, "selection isn't in item", (char *) NULL);
      return TCL_ERROR;
    }
    *index = ti->sel_first;
  }
  else if ((c == 's') && (strncmp(p, "sel.last", length) == 0) &&
           (length >= 5)) {
    if (ti->sel_item != item) {
      Tcl_AppendResult(wi->interp, "selection isn't in item", (char *) NULL);
      return TCL_ERROR;
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
    /*x = (int) ((tmp < 0) ? tmp - 0.5 : tmp + 0.5);*/
    x = (int) tmp;
    p = end+1;
    tmp = strtod(p, &end);
    if ((end == p) || (*end != 0)) {
      goto badIndex;
    }
    /*y = (int) ((tmp < 0) ? tmp - 0.5 : tmp + 0.5);*/
    y = (int) tmp;
    
    *index = PointToChar(text, x, y);
  }
  else if (Tcl_GetIntFromObj(wi->interp, index_spec, index) == TCL_OK) {
    if (*index < 0){
      *index = 0;
    }
    else if ((unsigned int) *index > text->num_chars) {
      *index = text->num_chars;
    }
  }
  else {
  badIndex:
    Tcl_AppendResult(wi->interp, "bad index \"", p, "\"", (char *) NULL);
    return TCL_ERROR;
  }

  return TCL_OK;  
}


/*
 **********************************************************************************
 *
 * InsertChars --
 *
 **********************************************************************************
 */
static void
InsertChars(ZnItem      item,
            int         field,
            int         *index,
            char        *chars)
{
  TextItem      text = (TextItem) item;
  ZnTextInfo    *ti = &item->wi->text_info;
  unsigned int  num_chars, byte_index, num_bytes = strlen(chars);
  char          *new;

  if (num_bytes == 0) {
    return;
  }
  if (*index < 0) {
    *index = 0;
  }
  if ((unsigned int) *index > text->num_chars) {
    *index = text->num_chars;
  }
  num_chars = Tcl_NumUtfChars(chars, (int) num_bytes);

  if (text->text) {
    byte_index = Tcl_UtfAtIndex(text->text, *index)-text->text;
    new = ZnMalloc(strlen(text->text) + num_bytes + 1);
    memcpy(new, text->text, (size_t) byte_index);
    strcpy(new + byte_index + num_bytes, text->text + byte_index);
    ZnFree(text->text);
  }
  else {
    byte_index = 0;
    new = ZnMalloc(num_bytes + 1);
    new[num_bytes] = 0;
  }
  memcpy(new + byte_index, chars, num_bytes);
  text->text = new;
  text->num_chars += num_chars;
  
  if (text->insert_index >= (unsigned int) *index) {
    text->insert_index += num_chars;
  }
  if (ti->sel_item == item) {
    if (ti->sel_first >= *index) {
      ti->sel_first += num_chars;
    }
    if (ti->sel_last >= *index) {
      ti->sel_last += num_chars;
    }
    if ((ti->anchor_item == item) && (ti->sel_anchor >= *index)) {
      ti->sel_anchor += num_chars;
    }
  }
  
  ZnITEM.Invalidate(item, ZN_COORDS_FLAG|ZN_LAYOUT_FLAG);
}


/*
 **********************************************************************************
 *
 * DeleteChars --
 *
 **********************************************************************************
 */
static void
DeleteChars(ZnItem      item,
            int         field,
            int         *first,
            int         *last)
{
  TextItem      text = (TextItem) item;
  int           byte_count, first_offset;
  int           char_count, num_bytes;
  ZnTextInfo    *ti = &item->wi->text_info;
  char          *new;
  
  if (!text->text) {
    return;
  }
  if (*first < 0) {
    *first = 0;
  }
  if (*last >= (int) text->num_chars) {
    *last = text->num_chars-1;
  }
  if (*first > *last) {
    return;
  }
  char_count = *last + 1 - *first;
  first_offset = Tcl_UtfAtIndex(text->text, *first)-text->text;
  byte_count = Tcl_UtfAtIndex(text->text + first_offset, char_count)-
    (text->text+first_offset);
  num_bytes = strlen(text->text);

  if (num_bytes - byte_count) {
    new = (char *) ZnMalloc((unsigned) (num_bytes + 1 - byte_count));
    memcpy(new, text->text, (size_t) first_offset);
    strcpy(new + first_offset, text->text + first_offset + byte_count);
    ZnFree(text->text);
    text->text = new;
    text->num_chars -= char_count;
  }
  else {
    ZnFree(text->text);
    text->text = NULL;
    text->num_chars = 0;
  }

  if (text->insert_index > (unsigned int) *first) {
    text->insert_index -= char_count;
    if (text->insert_index < (unsigned int) *first) {
      text->insert_index = *first;
    }
    else if (*first == 0) {
      text->insert_index = 0;
    }
  }
  if (ti->sel_item == item) {
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
    if ((ti->anchor_item == item) && (ti->sel_anchor > *first)) {
      ti->sel_anchor -= char_count;
      if (ti->sel_anchor < *first) {
        ti->sel_anchor = *first;
      }
    }
  }

  ZnITEM.Invalidate(item, ZN_COORDS_FLAG|ZN_LAYOUT_FLAG);
}


/*
 **********************************************************************************
 *
 * Cursor --
 *
 **********************************************************************************
 */
static void
TextCursor(ZnItem       item,
           int          field,
           int          index)
{
  TextItem      text = (TextItem) item;

  if (index < 0) {
    text->insert_index = 0;
  }
  else if ((unsigned int) index > text->num_chars) {
    text->insert_index = text->num_chars;
  }
  else {
    text->insert_index = index;
  }
}


/*
 **********************************************************************************
 *
 * Selection --
 *
 **********************************************************************************
 */
static int
Selection(ZnItem        item,
          int           field,
          int           offset,
          char          *chars,
          int           max_bytes)
{
  TextItem      text = (TextItem) item;
  ZnWInfo       *wi = item->wi;
  ZnTextInfo    *ti = &wi->text_info;
  int           count;
  char  const   *sel_first, *sel_last;

  if (!text->text) {
    return 0;
  }
  if ((ti->sel_first < 0) ||
      (ti->sel_first > ti->sel_last)) {
    return 0;
  }
  sel_first = Tcl_UtfAtIndex(text->text, ti->sel_first);
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
 * Exported functions struct
 *
 **********************************************************************************
 */
static ZnItemClassStruct TEXT_ITEM_CLASS = {
  "text",
  sizeof(TextItemStruct),
  text_attrs,
  0,                    /* num_parts */
  ZN_CLASS_HAS_ANCHORS|ZN_CLASS_ONE_COORD, /* flags */
  Tk_Offset(TextItemStruct, pos),
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
  InsertChars,
  DeleteChars,
  TextCursor,
  Index,
  NULL,                 /* Part */
  Selection,
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

ZnItemClassId ZnText = (ZnItemClassId) &TEXT_ITEM_CLASS;
