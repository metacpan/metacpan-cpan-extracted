/*
 * Map.c -- Implementation of Map item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Map.c,v 1.63 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Types.h"
#include "MapInfo.h"
#include "Item.h"
#include "Geo.h"
#include "Draw.h"
#include "WidgetInfo.h"
#include "tkZinc.h"
#include "Image.h"

#include <memory.h>
#include <stdio.h>


static const char rcsid[] = "$Id: Map.c,v 1.63 2005/05/10 07:59:48 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 **********************************************************************************
 *
 * Specific Map item record
 *
 **********************************************************************************
 */

typedef struct _MapItemStruct {
  ZnItemStruct  header;
 
  /* Public data */
  ZnBool        filled;
  ZnImage       fill_pattern;
  ZnGradient    *color;
  Tk_Font       text_font;      /* null value -> use zn_map_text_font */
  char          *map_info_name;
  ZnList        symbol_patterns;
  
  /* Private data */
  ZnMapInfoId   map_info;
  ZnList        vectors;
  ZnList        dashed_vectors;
  ZnList        dotted_vectors;
  ZnList        mixed_vectors;
  ZnList        arcs;
  ZnList        dashed_arcs;
  ZnList        dotted_arcs;
  ZnList        mixed_arcs;
  ZnList        marks;
  ZnList        symbols;
  ZnList        texts;
#ifdef GL
  ZnTexFontInfo *tfi;
#endif
} MapItemStruct, *MapItem;


static ZnAttrConfig     map_attrs[] = {
  { ZN_CONFIG_GRADIENT, "-color", NULL,
    Tk_Offset(MapItemStruct, color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(MapItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(MapItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(MapItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-filled", NULL,
    Tk_Offset(MapItemStruct, filled), 1, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-fillpattern", NULL,
    Tk_Offset(MapItemStruct, fill_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_FONT, "-font", NULL,
    Tk_Offset(MapItemStruct, text_font), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_MAP_INFO, "-mapinfo", NULL,
    Tk_Offset(MapItemStruct, map_info_name), 0,
    ZN_COORDS_FLAG|ZN_MAP_INFO_FLAG, False },
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(MapItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(MapItemStruct, header.flags), ZN_SENSITIVE_BIT, ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BITMAP_LIST, "-symbols", NULL,
    Tk_Offset(MapItemStruct, symbol_patterns), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(MapItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(MapItemStruct, header.flags), ZN_VISIBLE_BIT,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG|ZN_VIS_FLAG, False },
    
  { ZN_CONFIG_END, NULL, NULL, 0, 0, 0, False }
};


void
UpdateMapInfo(ClientData        client_data,
              ZnMapInfoId       map_info)
{
  ZnItem        item = (ZnItem) client_data;

  /*printf("updating a map 'cause of a change in mapinfo\n");*/
  ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
}


static void
FreeLists(MapItem       map)
{
  if (map->vectors) {
    ZnListFree(map->vectors);
  }
  map->vectors = NULL;
  if (map->dashed_vectors) {
    ZnListFree(map->dashed_vectors);
  }
  map->dashed_vectors = NULL;
  if (map->dotted_vectors) {
    ZnListFree(map->dotted_vectors);
  }
  map->dotted_vectors = NULL;
  if (map->mixed_vectors) {
    ZnListFree(map->mixed_vectors);
  }
  map->mixed_vectors = NULL;
  
  if (map->arcs) {
    ZnListFree(map->arcs);
  }
  map->arcs = NULL;
  if (map->dashed_arcs) {
    ZnListFree(map->dashed_arcs);
  }
  map->dashed_arcs = NULL;
  if (map->dotted_arcs) {
    ZnListFree(map->dotted_arcs);
  }
  map->dotted_arcs = NULL;
  if (map->mixed_arcs) {
    ZnListFree(map->mixed_arcs);
  }
  map->mixed_arcs = NULL;
  
  if (map->marks) {
    ZnListFree(map->marks);
  }
  map->marks = NULL;
  
  if (map->symbols) {
    ZnListFree(map->symbols);
  }
  map->symbols = NULL;
  
  if (map->texts) {
    ZnListFree(map->texts);
  }
  map->texts = NULL;
}


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
  MapItem       map  = (MapItem) item;
  ZnWInfo       *wi = item->wi;

  SET(item->flags, ZN_VISIBLE_BIT);
  CLEAR(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  item->part_sensitive = 0;
  item->priority = 0;
  map->filled = False;
  map->fill_pattern = ZnUnspecifiedImage; 
  map->symbol_patterns = NULL;
  map->color = ZnGetGradientByValue(wi->fore_color);
  map->text_font = Tk_GetFont(wi->interp, wi->win,
                              Tk_NameOfFont(wi->map_text_font));
#ifdef GL
  map->tfi = NULL;
#endif

  map->map_info_name = NULL;
  map->map_info = NULL;

  map->vectors = NULL;
  map->dashed_vectors = NULL;
  map->dotted_vectors = NULL;
  map->mixed_vectors = NULL;
  map->arcs = NULL;
  map->dashed_arcs = NULL;
  map->dotted_arcs = NULL;
  map->mixed_arcs = NULL;
  map->marks = NULL;
  map->symbols = NULL;
  map->texts = NULL;
  
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
  MapItem       map  = (MapItem) item;
  ZnWInfo       *wi = item->wi;
  
  if (map->vectors) {
    map->vectors = ZnListDuplicate(map->vectors);
  }
  if (map->dashed_vectors) {
    map->dashed_vectors = ZnListDuplicate(map->dashed_vectors);
  }
  if (map->dotted_vectors) {
    map->dotted_vectors = ZnListDuplicate(map->dotted_vectors);
  }
  if (map->mixed_vectors) {
    map->mixed_vectors = ZnListDuplicate(map->mixed_vectors);
  }
  
  if (map->arcs) {
    map->arcs = ZnListDuplicate(map->arcs);
  }
  if (map->dashed_arcs) {
    map->dashed_arcs = ZnListDuplicate(map->dashed_arcs);
  }
  if (map->dotted_arcs) {
    map->dotted_arcs = ZnListDuplicate(map->dotted_arcs);
  }
  if (map->mixed_arcs) {
    map->mixed_arcs = ZnListDuplicate(map->mixed_arcs);
  }
  
  if (map->marks) {
    map->marks = ZnListDuplicate(map->marks);
  }
  
  if (map->symbols) {
    map->symbols = ZnListDuplicate(map->symbols);
  }
  
  if (map->texts) {
    map->texts = ZnListDuplicate(map->texts);
  }

  if (map->map_info_name) {
    char *text;
    text = ZnMalloc((strlen(map->map_info_name) + 1) * sizeof(char));
    strcpy(text, map->map_info_name);
    map->map_info_name = text;
    map->map_info = ZnGetMapInfo(wi->interp, map->map_info_name,
                                 UpdateMapInfo, (ClientData) map);
  }
  
  map->color = ZnGetGradientByValue(map->color);
  map->text_font = Tk_GetFont(wi->interp, wi->win, Tk_NameOfFont(map->text_font));
#ifdef GL
  map->tfi = NULL;
#endif
  if (map->fill_pattern != ZnUnspecifiedImage) {
    map->fill_pattern = ZnGetImageByValue(map->fill_pattern, NULL, NULL);
  }
  if (map->symbol_patterns) {
    ZnImage *pats, *new_pats;
    unsigned int i, num_pats;
    
    pats = ZnListArray(map->symbol_patterns);
    num_pats = ZnListSize(map->symbol_patterns);
    map->symbol_patterns = ZnListNew(num_pats, sizeof(ZnImage));
    new_pats = ZnListArray(map->symbol_patterns);
    for (i = 0; i < num_pats; i++) {
      new_pats[i] = ZnGetImageByValue(pats[i], NULL, NULL);
    }
  }
}


/*
 **********************************************************************************
 *
 * Destroy --
 *      Free the Map storage.
 *
 **********************************************************************************
 */
static void
Destroy(ZnItem  item)
{
  MapItem       map = (MapItem) item;

  FreeLists(map);
  ZnFreeGradient(map->color);
  Tk_FreeFont(map->text_font);
#ifdef GL
  if (map->tfi) {
    ZnFreeTexFont(map->tfi);
  }
#endif
  if (map->fill_pattern != ZnUnspecifiedImage) {
    ZnFreeImage(map->fill_pattern, NULL, NULL);
    map->fill_pattern = ZnUnspecifiedImage;
  }
  if (map->symbol_patterns) {
    ZnImage *pats;
    int     i, num_pats;

    pats = ZnListArray(map->symbol_patterns);
    num_pats = ZnListSize(map->symbol_patterns);
    for (i = 0; i < num_pats; i++) {
      if (pats[i] != ZnUnspecifiedImage) {
        ZnFreeImage(pats[i], NULL, NULL);
      }
    }
    ZnListFree(map->symbol_patterns);
  }
  if (map->map_info_name) {
    ZnFree(map->map_info_name);
  }
  if (map->map_info != NULL) {
    ZnFreeMapInfo(map->map_info, UpdateMapInfo, (ClientData) map);
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
  ZnWInfo       *wi = item->wi;
  MapItem       map = (MapItem) item;
#ifdef GL
  Tk_Font       old_font = map->text_font;
#endif

  if (ZnConfigureAttributes(wi, item, item, map_attrs, argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
  }

#ifdef GL
  if (old_font != map->text_font) {
    if (map->tfi) {
      ZnFreeTexFont(map->tfi);
      map->tfi = NULL;
    }
  }
#endif
  if (ISSET(*flags, ZN_MAP_INFO_FLAG)) {
    ZnMapInfoId map_info;
    ZnBool      error = False;
    
    if (map->map_info_name) {
      map_info = ZnGetMapInfo(wi->interp, map->map_info_name,
                              UpdateMapInfo, (ClientData) map);
      if (!map_info) {
        error = True;
      }
    }
    else {
      map_info = NULL;
    }
    if (!error) {
      if (map->map_info != NULL) {
        ZnFreeMapInfo(map->map_info, UpdateMapInfo, (ClientData) map);
      }
      map->map_info = map_info;
    }
    else {
      return TCL_ERROR;
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
  if (ZnQueryAttribute(item->wi->interp, item, map_attrs, argv[0]) == TCL_ERROR) {
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
  ZnWInfo               *wi = item->wi;
  MapItem               map = (MapItem) item;
  ZnMapInfoId           map_info;
  ZnMapInfoLineStyle    line_style;
  ZnMapInfoTextStyle    text_style;
  char                  symbol;
  char                  *text;
  unsigned int          i, j, cnt;
  unsigned int          num_points;
  unsigned int          num_dashed_points;
  unsigned int          num_dotted_points;
  unsigned int          num_mixed_points;
  unsigned int          num_arcs;
  unsigned int          num_dashed_arcs;
  unsigned int          num_dotted_arcs;
  unsigned int          num_mixed_arcs;
  unsigned int          num_marks;
  ZnPoint               *vectors, *dashed_vectors, *dotted_vectors;
  ZnPoint               *mixed_vectors, *marks;
  XArc                  *arcs, *dashed_arcs, *dotted_arcs, *mixed_arcs;
  ZnPoint               *symbols, *texts;
  ZnPoint               from, to, center;
  ZnPoint               tmp_from, tmp_to;
  XArc                  arc;
  ZnBBox                bbox, bbox_inter, zn_bbox;
  ZnPos                 x_from_w, y_from_w, x_to_w, y_to_w;
  ZnPos                 start_angle, extend;
  ZnDim                 radius_w, line_width;
  int                   radius;
  ZnPoint               *new_marks;
  unsigned int          n_new_marks;
  Tk_Font               text_font;
  int                   sym_w2=0, sym_h2=0;
  
  ZnResetBBox(&item->item_bounding_box);

  if (map->map_info == NULL) {
    return;
  }

  zn_bbox.orig.x = zn_bbox.orig.y = 0;
  zn_bbox.corner.x = wi->width;
  zn_bbox.corner.y = wi->height;

  map_info = map->map_info;

  num_points            = 0;
  num_dashed_points     = 0;
  num_dotted_points     = 0;
  num_mixed_points      = 0;
  num_marks             = 0;
  num_arcs              = 0;
  num_dashed_arcs       = 0;
  num_dotted_arcs       = 0;
  num_mixed_arcs        = 0;  
  
  /*
   * Experimental code to help trap out of bounds
   * errors occuring as the result of improper use
   * of MapInfo/Map (i.e not doing a configure on
   * the MapInfo attribute after a reconfiguration
   * of the MapInfo. This version is more secure
   * but slower than the previous one.
   */
  /*
   * First discover how many component of each kind
   * there is in the MapInfo.
   */
  cnt = ZnMapInfoNumLines(map_info);
  for (i = 0; i < cnt; i++) {
    ZnMapInfoGetLine(map_info, i, NULL, &line_style, NULL, NULL, NULL, NULL, NULL);
    switch (line_style) {
    case ZnMapInfoLineSimple:
      num_points += 2;
      break;
    case ZnMapInfoLineDashed:
      num_dashed_points += 2;  
      break;
    case ZnMapInfoLineDotted:
      num_dotted_points += 2;  
      break;
    case ZnMapInfoLineMixed:
      num_mixed_points += 2;
      break;
    case ZnMapInfoLineMarked:
      num_points += 2;
      ZnMapInfoGetMarks(map_info, i, NULL, &n_new_marks);
      num_marks += n_new_marks;
      break;
    }
  }

  cnt = ZnMapInfoNumTexts(map_info);
  for (i = 0; i < cnt; i++) {
    ZnMapInfoGetText(map_info, i, NULL, &text_style, &line_style, NULL, NULL, NULL);
    if (text_style == ZnMapInfoUnderlinedText) {
      switch (line_style) {
      case ZnMapInfoLineSimple:
      case ZnMapInfoLineMarked:
        num_points += 2;
        break;
      case ZnMapInfoLineDotted:
        num_dotted_points += 2;
        break;
      case ZnMapInfoLineMixed:
        num_mixed_points += 2;
        break;
      case ZnMapInfoLineDashed:
        num_dashed_points += 2;  
        break;
      }
    }
  }

  cnt = ZnMapInfoNumArcs(map_info);
  for (i = 0; i < cnt; i++) {
    ZnMapInfoGetArc(map_info, i, NULL, &line_style, NULL, NULL, NULL, NULL, NULL, NULL);
    switch (line_style) {
    case ZnMapInfoLineSimple:
    case ZnMapInfoLineMarked:
      num_arcs += 2;
      break;
    case ZnMapInfoLineDotted:
      num_dotted_arcs += 2;
      break;
    case ZnMapInfoLineMixed:
      num_mixed_arcs += 2;
      break;
    case ZnMapInfoLineDashed:
      num_dashed_arcs += 2;
      break;
    }
  }
  
  /*
   * Make sure the various lists are large enough
   * to contain the computed amount of points.
   * Later we will cut them to take into account the
   * clipping and the filled attribute.
   */
  if (!map->vectors) {
    map->vectors = ZnListNew(num_points, sizeof(ZnPoint));
  }
  ZnListAssertSize(map->vectors, num_points);
  if (!map->dashed_vectors) {
    map->dashed_vectors = ZnListNew(num_dashed_points, sizeof(ZnPoint));
  }
  ZnListAssertSize(map->dashed_vectors, num_dashed_points);
  if (!map->dotted_vectors) {
    map->dotted_vectors = ZnListNew(num_dotted_points, sizeof(ZnPoint));
  }
  ZnListAssertSize(map->dotted_vectors, num_dotted_points);
  if (!map->mixed_vectors) {
    map->mixed_vectors = ZnListNew(num_mixed_points, sizeof(ZnPoint));
  }
  ZnListAssertSize(map->mixed_vectors, num_mixed_points);
  if (!map->arcs) {
    map->arcs = ZnListNew(num_arcs, sizeof(XArc));
  }
  ZnListAssertSize(map->arcs, num_arcs);
  if (!map->dashed_arcs) {
    map->dashed_arcs = ZnListNew(num_dashed_arcs, sizeof(XArc));
  }
  ZnListAssertSize(map->dashed_arcs, num_dashed_arcs);
  if (!map->dotted_arcs) {
    map->dotted_arcs = ZnListNew(num_dotted_arcs, sizeof(XArc));
  }
  ZnListAssertSize(map->dotted_arcs, num_dotted_arcs);
  if (!map->mixed_arcs) {
    map->mixed_arcs = ZnListNew(num_mixed_arcs, sizeof(XArc));
  }
  ZnListAssertSize(map->mixed_arcs, num_mixed_arcs);
  if (!map->marks) {
    map->marks = ZnListNew(num_marks, sizeof(ZnPoint));
  }
  ZnListAssertSize(map->marks, num_marks);
  if (!map->symbols) {
    map->symbols = ZnListNew(ZnMapInfoNumSymbols(map_info), sizeof(ZnPoint));
  }
  ZnListAssertSize(map->symbols, ZnMapInfoNumSymbols(map_info));
  if (!map->texts) {
    map->texts = ZnListNew(ZnMapInfoNumTexts(map_info), sizeof(ZnPoint));
  }
  ZnListAssertSize(map->texts, ZnMapInfoNumTexts(map_info));

  /*
   * Ask the pointers to the actual arrays.
   */
  vectors        = (ZnPoint *) ZnListArray(map->vectors);
  dashed_vectors = (ZnPoint *) ZnListArray(map->dashed_vectors);
  dotted_vectors = (ZnPoint *) ZnListArray(map->dotted_vectors);
  mixed_vectors  = (ZnPoint *) ZnListArray(map->mixed_vectors);
  arcs           = (XArc *) ZnListArray(map->arcs);
  dashed_arcs    = (XArc *) ZnListArray(map->dashed_arcs);
  dotted_arcs    = (XArc *) ZnListArray(map->dotted_arcs);
  mixed_arcs     = (XArc *) ZnListArray(map->mixed_arcs);
  marks          = (ZnPoint *) ZnListArray(map->marks);
  symbols        = (ZnPoint *) ZnListArray(map->symbols);
  texts          = (ZnPoint *) ZnListArray(map->texts);

  if (num_marks && (wi->map_distance_symbol != ZnUnspecifiedImage)) {
    ZnSizeOfImage(wi->map_distance_symbol, &sym_w2, &sym_h2);
    sym_w2 = (sym_w2+1)/2;
    sym_h2 = (sym_h2+1)/2;
  }
  /*printf("Map: %d %d %d %d %d, texts: %d, symbols: %d\n", num_points, num_dashed_points, num_dotted_points,
         num_mixed_points, num_marks, ZnMapInfoNumTexts(map_info), ZnMapInfoNumSymbols(map_info));*/
  /*
   * Reset the counts of points to compute the actual
   * counts taking into account the clipping and the
   * filled attribute.
   */
  num_points            = 0;
  num_dashed_points     = 0;
  num_dotted_points     = 0;
  num_mixed_points      = 0;
  num_marks             = 0;
  num_arcs              = 0;
  num_dashed_arcs       = 0;
  num_dotted_arcs       = 0;
  num_mixed_arcs        = 0;  

  cnt = ZnMapInfoNumLines(map_info);
  for (i = 0; i < cnt; i++) {
    ZnMapInfoGetLine(map_info, i, NULL, &line_style, &line_width,
                   &x_from_w, &y_from_w, &x_to_w, &y_to_w);

    tmp_from.x = x_from_w;
    tmp_from.y = y_from_w;
    tmp_to.x = x_to_w;
    tmp_to.y = y_to_w;
    ZnTransformPoint(wi->current_transfo, &tmp_from, &from);
    ZnTransformPoint(wi->current_transfo, &tmp_to, &to);

    /*
     * Skip zero length and outside segments.
     */
    if ((from.x == to.x) && (from.y == to.y)) {
      continue;
    }
    
    if (!map->filled) {
      if (ZnLineInBBox(&from, &to, &zn_bbox) < 0) {
        continue;
      }
    }

    switch (line_style) {
    case ZnMapInfoLineSimple:
      vectors[num_points] = from;
      num_points++;
      vectors[num_points] = to;
      num_points++;
      break;
    case ZnMapInfoLineDashed:
      if (!map->filled) {
        dashed_vectors[num_dashed_points] = from;
        num_dashed_points++;
        dashed_vectors[num_dashed_points] = to;
        num_dashed_points++;
      }
      break;
    case ZnMapInfoLineDotted:
      if (!map->filled) {
        dotted_vectors[num_dotted_points] = from;
        num_dotted_points++;
        dotted_vectors[num_dotted_points] = to;
        num_dotted_points++;
      }
      break;
    case ZnMapInfoLineMixed:
      if (!map->filled) {
        mixed_vectors[num_mixed_points] = from;
        num_mixed_points++;
        mixed_vectors[num_mixed_points] = to;
        num_mixed_points++;
      }
      break;
    case ZnMapInfoLineMarked:
      if (!map->filled) {
        vectors[num_points] = from;
        num_points++;
        vectors[num_points] = to;
        num_points++;
        if (wi->map_distance_symbol != ZnUnspecifiedImage) {
          ZnMapInfoGetMarks(map_info, i, &new_marks, &n_new_marks);
          for (j = 0; j < n_new_marks; j++) {
            /*
             * The transform can be put outside the loop when
             * MapInfo point type is modified to ZnPoint.
             * Will use then ZnTransformPoints.
             */
            tmp_from.x = new_marks[j].x;
            tmp_from.y = new_marks[j].y;
            ZnTransformPoint(wi->current_transfo, &tmp_from, &marks[num_marks]);
            ZnAddPointToBBox(&item->item_bounding_box,
                             marks[num_marks].x-sym_w2, marks[num_marks].y-sym_h2);
            ZnAddPointToBBox(&item->item_bounding_box,
                             marks[num_marks].x+sym_w2, marks[num_marks].x+sym_h2);  
            num_marks++;
          }
        }
      }
      break;
    }
  }
  
  cnt = ZnMapInfoNumArcs(map_info);
  for (i = 0; i < cnt; i++) {
    ZnPoint xp;
    
    ZnMapInfoGetArc(map_info, i, NULL, &line_style, &line_width, 
                  &x_from_w, &y_from_w, &radius_w, &start_angle, &extend);

    tmp_from.x = x_from_w;
    tmp_from.y = y_from_w;
    ZnTransformPoint(wi->current_transfo, &tmp_from, &center);
    tmp_from.x += radius_w;
    tmp_from.y = 0;
    ZnTransformPoint(wi->current_transfo, &tmp_from, &xp);
    radius = ((int) (xp.x - center.x));

    bbox.orig.x = center.x - radius;
    bbox.orig.y = center.y - radius;
    bbox.corner.x = bbox.orig.x + (2 * radius);
    bbox.corner.y = bbox.orig.y + (2 * radius);
    
    /*
     * Skip zero length and outside arcs.
     */
    if (!radius || !extend) {
      continue;
    }
    
    ZnIntersectBBox(&zn_bbox, &bbox, &bbox_inter);
    if (ZnIsEmptyBBox(&bbox_inter)) {
      continue;
    }
    
    arc.x       = (int) (center.x - radius);
    arc.y       = (int) (center.y - radius);
    arc.width   = 2 * radius;
    arc.height  = arc.width;
    arc.angle1  = ((unsigned short) start_angle) * 64;
    arc.angle2  = ((unsigned short) extend) * 64;
    
    switch (line_style) {
    case ZnMapInfoLineSimple:
    case ZnMapInfoLineMarked:
      arcs[num_arcs] = arc;
      num_arcs++;
      
      bbox.orig.x = arc.x;
      bbox.orig.y = arc.y;
      bbox.corner.x = bbox.orig.x + arc.width + 1;
      bbox.corner.y = bbox.orig.y + arc.height + 1;
      ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
      break;
    case ZnMapInfoLineDashed:
      if (!map->filled) {
        dashed_arcs[num_dashed_arcs] = arc;
        num_dashed_arcs++;
        
        bbox.orig.x = arc.x;
        bbox.orig.y = arc.y;
        bbox.corner.x = bbox.orig.x + arc.width + 1;
        bbox.corner.y = bbox.orig.y + arc.height + 1;
        ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
      }
      break;
    case ZnMapInfoLineDotted:
      if (!map->filled) {
        dotted_arcs[num_dotted_arcs] = arc;
        num_dotted_arcs++;
        
        bbox.orig.x = arc.x;
        bbox.orig.y = arc.y;
        bbox.corner.x = bbox.orig.x + arc.width + 1;
        bbox.corner.y = bbox.orig.y + arc.height + 1;
        ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
      }
      break;
    case ZnMapInfoLineMixed:
      if (!map->filled) {
        mixed_arcs[num_mixed_arcs] = arc;
        num_mixed_arcs++;
        
        bbox.orig.x = arc.x;
        bbox.orig.y = arc.y;
        bbox.corner.x = bbox.orig.x + arc.width + 1;
        bbox.corner.y = bbox.orig.y + arc.height + 1;
        ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
      }
      break;
    }
  }
  
  /*
   * Truncate arc lists to the real size.
   */
  ZnListAssertSize(map->arcs, num_arcs);
  ZnListAssertSize(map->dashed_arcs, num_dashed_arcs);
  ZnListAssertSize(map->dotted_arcs, num_dotted_arcs);
  ZnListAssertSize(map->mixed_arcs, num_mixed_arcs);
  
  /* If map is filled, only the vectors description is valid. */
  if (!map->filled) {
    if (map->symbol_patterns) {
      ZnImage sym, *syms = ZnListArray(map->symbol_patterns);
      int     num_syms = ZnListSize(map->symbol_patterns);    

      cnt = ZnMapInfoNumSymbols(map_info);
      for (i = 0; i < cnt; i++) {
        ZnMapInfoGetSymbol(map_info, i, NULL, &x_from_w, &y_from_w, &symbol);
        tmp_from.x = x_from_w;
        tmp_from.y = y_from_w;
        ZnTransformPoint(wi->current_transfo, &tmp_from, &symbols[i]);
        sym = syms[symbol%num_syms];
        if (sym != ZnUnspecifiedImage) {
          ZnSizeOfImage(sym, &sym_w2, &sym_h2);
          sym_w2 = (sym_w2+1)/2;
          sym_h2 = (sym_h2+1)/2;
          ZnAddPointToBBox(&item->item_bounding_box,
                           symbols[i].x-sym_w2, symbols[i].y-sym_h2);
          ZnAddPointToBBox(&item->item_bounding_box,
                           symbols[i].x+sym_w2, symbols[i].y+sym_h2);     
        }
      }
      ZnListAssertSize(map->symbols, cnt);
    }

    cnt = ZnMapInfoNumTexts(map_info);
    text_font = map->text_font ? map->text_font : wi->map_text_font;
    for (i = 0; i < cnt; i++) {
      ZnMapInfoGetText(map_info, i, NULL,
                     &text_style, &line_style, &x_from_w, &y_from_w, &text);
      tmp_from.x = x_from_w;
      tmp_from.y = y_from_w;
      ZnTransformPoint(wi->current_transfo, &tmp_from, &texts[i]);
      ZnAddStringToBBox(&item->item_bounding_box, text, text_font,
                        texts[i].x, texts[i].y);
      
      if (text_style == ZnMapInfoUnderlinedText) {
        ZnGetStringBBox(text, text_font, texts[i].x, texts[i].y, &bbox);
        
        from.x = bbox.orig.x;
        from.y = bbox.corner.y;
        to.x   = bbox.corner.x;
        to.y   = bbox.corner.y;
        
        switch (line_style) {
        case ZnMapInfoLineSimple:
        case ZnMapInfoLineMarked:
          vectors[num_points] = from;
          num_points++;
          vectors[num_points] = to;
          num_points++;
          break;
        case ZnMapInfoLineDashed:
          dashed_vectors[num_dashed_points] = from;
          num_dashed_points++;
          dashed_vectors[num_dashed_points] = to;
          num_dashed_points++;
          break;
        case ZnMapInfoLineDotted:
          dotted_vectors[num_dotted_points] = from;
          num_dotted_points++;
          dotted_vectors[num_dotted_points] = to;
          num_dotted_points++;
          break;
        case ZnMapInfoLineMixed:
          mixed_vectors[num_mixed_points] = from;
          num_mixed_points++;
          mixed_vectors[num_mixed_points] = to;
          num_mixed_points++;
          break;
        }
      }
    }
    ZnListAssertSize(map->texts, cnt);
  }
    
  /*
   * Truncate line lists to the real size.
   */
  ZnListAssertSize(map->vectors, num_points);
  ZnListAssertSize(map->dashed_vectors, num_dashed_points);
  ZnListAssertSize(map->dotted_vectors, num_dotted_points);
  ZnListAssertSize(map->mixed_vectors, num_mixed_points);
  ZnListAssertSize(map->marks, num_marks);
  
  ZnAddPointsToBBox(&item->item_bounding_box,
                    ZnListArray(map->vectors), ZnListSize(map->vectors));
  ZnAddPointsToBBox(&item->item_bounding_box,
                    ZnListArray(map->dashed_vectors), ZnListSize(map->dashed_vectors));
  ZnAddPointsToBBox(&item->item_bounding_box,
                    ZnListArray(map->dotted_vectors), ZnListSize(map->dotted_vectors));
  ZnAddPointsToBBox(&item->item_bounding_box,
                    ZnListArray(map->mixed_vectors), ZnListSize(map->mixed_vectors));
  item->item_bounding_box.orig.x -= 0.5;
  item->item_bounding_box.orig.y -= 0.5;
  item->item_bounding_box.corner.x += 0.5;
  item->item_bounding_box.corner.y += 0.5;
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
  MapItem       map = (MapItem) item;
  ZnMapInfoId   map_info;
  ZnPoint       *points;
  XPoint        *xpoints;
  XArc          *arcs;
  char          *text;
  char          tmp_str[] = ".";
  XGCValues     values;
  unsigned int  i, cnt;
  ZnDim         line_width_w;
  int           line_width;

  if (map->map_info == NULL) {
    return;
  }

  map_info = map->map_info;

  values.foreground = ZnGetGradientPixel(map->color, 0.0);

  if (map->filled) {
    if (ZnListSize(map->vectors) || ZnListSize(map->arcs)) {
      if (map->fill_pattern == ZnUnspecifiedImage) { /* Fill solid */
        values.fill_style = FillSolid;
        XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCForeground, &values);
      }
      else { /* Fill stippled */
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(map->fill_pattern, wi->win);
        XChangeGC(wi->dpy, wi->gc,
                  GCFillStyle | GCStipple | GCForeground, &values);
      }
      
      cnt = ZnListSize(map->vectors);
      if (cnt) {
        ZnListAssertSize(ZnWorkXPoints, cnt);
        xpoints = (XPoint *) ZnListArray(ZnWorkXPoints);
        points = (ZnPoint *) ZnListArray(map->vectors);
        for (i = 0; i < cnt; i++) {
          xpoints[i].x = (int) points[i].x;
          xpoints[i].y = (int) points[i].y;
        }
        XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xpoints, (int) cnt,
                     Nonconvex, CoordModeOrigin);
      }
      
      if (ZnListSize(map->arcs)) {
        arcs = ZnListArray(map->arcs);
        cnt = ZnListSize(map->arcs);
        for (i = 0; i < cnt; i++, arcs++) {
          XFillArc(wi->dpy, wi->draw_buffer, wi->gc,
                   arcs->x, arcs->y, arcs->width, arcs->height,
                   arcs->angle1, arcs->angle2);
        }
      }
    }
  }
  else { /* Not filled */
    
    if (ZnListSize(map->vectors)) {
      ZnSetLineStyle(wi, ZN_LINE_SIMPLE);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc,
                GCFillStyle | GCLineWidth | GCForeground, &values);

      /* !! WARNING !! XDrawSegments can't handle an unlimited number of segments
         in releases R4 and older */
      /*      XDrawSegments(wi->dpy, wi->draw_buffer, wi->gc,
                    (XSegment *) ZnListArray(map->vectors),
                    ZnListSize(map->vectors)/2);*/
      cnt = ZnListSize(map->vectors);
      points = (ZnPoint *) ZnListArray(map->vectors);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &line_width_w, NULL,
                         NULL, NULL, NULL);
          line_width = (int) line_width_w;
          if (line_width != values.line_width) {
            values.line_width = line_width;
            XChangeGC(wi->dpy, wi->gc, GCLineWidth, &values);
          }
          /*printf("Dessin d'une ligne de %d %d à %d %d\n",
                 (int)points[i].x, (int)points[i].y,
                 (int)points[i+1].x, (int)points[i+1].y);*/
          XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
                    (int) points[i].x,
                    (int) points[i].y,
                    (int) points[i+1].x,
                    (int) points[i+1].y);
        }
      }
    }

    if (ZnListSize(map->dashed_vectors)) {
      ZnSetLineStyle(wi, ZN_LINE_DASHED);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      
      /* !! WARNING !! XDrawSegments can't handle an unlimited number of segments
         in releases R4 and older */
/*      XDrawSegments(wi->dpy, wi->draw_buffer, wi->gc,
                    (XSegment *) ZnListArray(map->dashed_vectors), ZnListSize(map->dashed_vectors)/2);*/
      cnt = ZnListSize(map->dashed_vectors);
      points = (ZnPoint *) ZnListArray(map->dashed_vectors);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &line_width_w, NULL, NULL, NULL, NULL);
          line_width = (int) line_width_w;        
          if (line_width != values.line_width) {
            values.line_width = line_width;
            XChangeGC(wi->dpy, wi->gc, GCLineWidth, &values);
          }
          XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
                    (int) points[i].x,
                    (int) points[i].y,
                    (int) points[i+1].x,
                    (int) points[i+1].y);
        }
      }
    }
    
    if (ZnListSize(map->dotted_vectors)) {
      ZnSetLineStyle(wi, ZN_LINE_DOTTED);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc,
                GCFillStyle | GCLineWidth | GCForeground, &values);
      
      /* !! WARNING !! XDrawSegments can't handle an unlimited number of segments
         in releases R4 and older */
/*      XDrawSegments(wi->dpy, wi->draw_buffer, wi->gc,
                    (XSegment *) ZnListArray(map->dotted_vectors), ZnListSize(map->dotted_vectors)/2);*/
      cnt = ZnListSize(map->dotted_vectors);
      points = (ZnPoint *) ZnListArray(map->dotted_vectors);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &line_width_w, NULL, NULL, NULL, NULL);
          line_width = (int) line_width_w;
          if (line_width != values.line_width) {
            values.line_width = line_width;
            XChangeGC(wi->dpy, wi->gc, GCLineWidth, &values);
          }
          XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
                    (int) points[i].x,
                    (int) points[i].y,
                    (int) points[i+1].x,
                    (int) points[i+1].y);
        }
      }
    }
    
    if (ZnListSize(map->mixed_vectors)) {
      ZnSetLineStyle(wi, ZN_LINE_MIXED);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      
      /* !! WARNING !! XDrawSegments can't handle an unlimited number of segments
         in releases R4 and older */
      /*XDrawSegments(wi->dpy, wi->draw_buffer, wi->gc,
                    (XSegment *) ZnListArray(map->mixed_vectors), ZnListSize(map->mixed_vectors)/2);*/
      cnt = ZnListSize(map->mixed_vectors);
      points = (ZnPoint *) ZnListArray(map->mixed_vectors);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &line_width_w, NULL, NULL, NULL, NULL);
          line_width = (int) line_width_w;
          if (line_width != values.line_width) {
            values.line_width = line_width;
            XChangeGC(wi->dpy, wi->gc, GCLineWidth, &values);
          }
          XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
                    (int) points[i].x,
                    (int) points[i].y,
                    (int) points[i+1].x,
                    (int) points[i+1].y);
        }
      }
    }
    
    if (ZnListSize(map->arcs)) {
      
      ZnSetLineStyle(wi, ZN_LINE_SIMPLE);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      arcs = ZnListArray(map->arcs);
      cnt = ZnListSize(map->arcs);
      for (i = 0; i < cnt; i++, arcs++) {
        XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
                 arcs->x, arcs->y, arcs->width, arcs->height,
                 arcs->angle1, arcs->angle2);
      }
    }
    
    if (ZnListSize(map->dashed_arcs)) {
      
      ZnSetLineStyle(wi, ZN_LINE_DASHED);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      arcs = ZnListArray(map->arcs);
      cnt = ZnListSize(map->arcs);
      for (i = 0; i < cnt; i++, arcs++) {
        XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
                 arcs->x, arcs->y, arcs->width, arcs->height,
                 arcs->angle1, arcs->angle2);
      }
    }
    
    if (ZnListSize(map->dotted_arcs)) {
      
      ZnSetLineStyle(wi, ZN_LINE_DOTTED);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      arcs = ZnListArray(map->arcs);
      cnt = ZnListSize(map->arcs);
      for (i = 0; i < cnt; i++, arcs++) {
        XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
                 arcs->x, arcs->y, arcs->width, arcs->height,
                 arcs->angle1, arcs->angle2);
      }
    }
    
    if (ZnListSize(map->mixed_arcs)) {
      
      ZnSetLineStyle(wi, ZN_LINE_MIXED);
      values.fill_style = FillSolid;
      values.line_width = 0;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      arcs = ZnListArray(map->arcs);
      cnt = ZnListSize(map->arcs);
      for (i = 0; i < cnt; i++, arcs++) {
        XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
                 arcs->x, arcs->y, arcs->width, arcs->height,
                 arcs->angle1, arcs->angle2);
      }
    }
    
    if (ZnListSize(map->texts)) {
      /* For the Tk widget we don't have to bother with old
       * compatibility issues.
       */
      values.font = Tk_FontId(map->text_font);
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc,
                GCFillStyle | GCFont | GCForeground, &values);
      
      cnt = ZnListSize(map->texts);
      points = (ZnPoint *) ZnListArray(map->texts);
      for (i = 0; i < cnt; i++) {
        ZnMapInfoGetText(map_info, i, NULL, NULL, NULL, NULL, NULL, &text);
        Tk_DrawChars(wi->dpy, wi->draw_buffer, wi->gc,
                     map->text_font, text, (int) strlen(text),
                     (int) points[i].x, (int) points[i].y); 
      }
    }
      
    if (ZnListSize(map->symbols) || ZnListSize(map->marks)) {
      int          ox, oy;
      unsigned int w, h;
      ZnImage sym;
      
      values.fill_style = FillStippled;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle, &values);
      
      if (map->symbol_patterns) {
        ZnImage *syms = ZnListArray(map->symbol_patterns);
        int     num_syms = ZnListSize(map->symbol_patterns);
        
        cnt = ZnListSize(map->symbols);
        points = ZnListArray(map->symbols);
        for (i = 0; i < cnt; i++) {
          ZnMapInfoGetSymbol(map_info, i, NULL, NULL, NULL, &(tmp_str[0]));
          sym = syms[tmp_str[0]%num_syms];
          if (sym != ZnUnspecifiedImage) {
            ZnSizeOfImage(sym, &w ,&h);
            ox = ((int) points[i].x) - w/2;
            oy = ((int) points[i].y) - h/2;
            values.stipple = ZnImagePixmap(sym, wi->win);
            values.ts_x_origin = ox;
            values.ts_y_origin = oy;
            XChangeGC(wi->dpy, wi->gc,
                      GCStipple|GCTileStipXOrigin|GCTileStipYOrigin, &values);
            XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc, ox, oy, w, h);
          }
        }
      }

      if (wi->map_distance_symbol != ZnUnspecifiedImage) {
        ZnSizeOfImage(wi->map_distance_symbol, &w, &h);
        cnt = ZnListSize(map->marks);
        points = ZnListArray(map->marks);
        values.stipple = ZnImagePixmap(wi->map_distance_symbol, wi->win);
        XChangeGC(wi->dpy, wi->gc, GCStipple, &values);
        for (i = 0; i < cnt; i++) {
          ox = ((int) points[i].x) - w/2;
          oy = ((int) points[i].y) - h/2;
          values.ts_x_origin = ox;
          values.ts_y_origin = oy;
          XChangeGC(wi->dpy, wi->gc, GCTileStipXOrigin|GCTileStipYOrigin, &values);
          XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc, ox, oy, w, h);
        }
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
Render(ZnItem   item)
{
  ZnWInfo       *wi = item->wi;
  MapItem       map = (MapItem) item;
  ZnMapInfoId   map_info;
  ZnPoint       *points, p;
  char          *text;
  char          tmp_str[] = ".";
  unsigned int  i, cnt;
  int           w, h;
  XColor        *color;
  GLfloat       line_width;
  ZnDim         new_width;
  unsigned short alpha;

  if (!map->map_info) {
    return;
  }

  map_info = map->map_info;
  color = ZnGetGradientColor(map->color, 0.0, &alpha);
  alpha = ZnComposeAlpha(alpha, wi->alpha);
  glColor4us(color->red, color->green, color->blue, alpha);
  if (map->filled) {
    if (ZnListSize(map->vectors) || ZnListSize(map->arcs)) {
        /* TODO_GL: Need to have a tesselated polygon then
         * fill it either using ZnRenderTile or solid.
         */
      if (map->fill_pattern != ZnUnspecifiedImage) {
        /* Fill stippled */
      }
      else {
      }
    }
  }
  else { /* Not filled */
    if (ZnListSize(map->vectors)) {
      line_width = 1.0;
      glLineWidth(line_width);
      ZnSetLineStyle(wi, ZN_LINE_SIMPLE);
      cnt = ZnListSize(map->vectors);
      points = ZnListArray(map->vectors);
      glBegin(GL_LINES);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &new_width, NULL,
                         NULL, NULL, NULL);
          if (new_width != line_width) {
            line_width = (GLfloat)new_width;
            glLineWidth(line_width);
          }
          glVertex2d(points[i].x, points[i].y);
          glVertex2d(points[i+1].x, points[i+1].y);
        }
      }
      glEnd();
    }
    if (ZnListSize(map->dashed_vectors)) {
      line_width = 1.0;
      glLineWidth(line_width);
      ZnSetLineStyle(wi, ZN_LINE_DASHED);
      cnt = ZnListSize(map->dashed_vectors);
      points = ZnListArray(map->dashed_vectors);
      glBegin(GL_LINES);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &new_width, NULL,
                         NULL, NULL, NULL);
          if (new_width != line_width) {
            line_width = (GLfloat)new_width;
            glLineWidth(line_width);
          }
          glVertex2d(points[i].x, points[i].y);
          glVertex2d(points[i+1].x, points[i+1].y);
        }
      }
      glEnd();
      glDisable(GL_LINE_STIPPLE);
    }
    if (ZnListSize(map->dotted_vectors)) {
      line_width = 1.0;
      glLineWidth(line_width);
      ZnSetLineStyle(wi, ZN_LINE_DOTTED);
      cnt = ZnListSize(map->dotted_vectors);
      points = ZnListArray(map->dotted_vectors);
      glBegin(GL_LINES);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &new_width, NULL,
                         NULL, NULL, NULL);
          if (new_width != line_width) {
            line_width = (GLfloat)new_width;
            glLineWidth(line_width);
          }
          glVertex2d(points[i].x, points[i].y);
          glVertex2d(points[i+1].x, points[i+1].y);
        }
      }
      glEnd();
      glDisable(GL_LINE_STIPPLE);
    }
    if (ZnListSize(map->mixed_vectors)) {
      line_width = 1.0;
      glLineWidth(line_width);
      ZnSetLineStyle(wi, ZN_LINE_MIXED);
      cnt = ZnListSize(map->mixed_vectors);
      points = ZnListArray(map->mixed_vectors);
      glBegin(GL_LINES);
      for (i = 0; i < cnt; i += 2) {
        if (ZnLineInBBox(&points[i], &points[i+1], &wi->damaged_area) >= 0) {
          ZnMapInfoGetLine(map_info, i/2, NULL, NULL, &new_width, NULL,
                         NULL, NULL, NULL);
          if (new_width != line_width) {
            line_width = (GLfloat)new_width;
            glLineWidth(line_width);
          }
          glVertex2d(points[i].x, points[i].y);
          glVertex2d(points[i+1].x, points[i+1].y);
        }
      }
      glEnd();
      glDisable(GL_LINE_STIPPLE);
    }

    if (ZnListSize(map->arcs)) {
      line_width = 1.0;
      glLineWidth(line_width);
    }
    if (ZnListSize(map->dashed_arcs)) {
      line_width = 1.0;
      glLineWidth(line_width);
      glLineStipple(1, 0xF0F0);
      glEnable(GL_LINE_STIPPLE);
      glDisable(GL_LINE_STIPPLE);
    }
    if (ZnListSize(map->dotted_arcs)) {
      line_width = 1.0;
      glLineWidth(line_width);
      glLineStipple(1, 0x18C3);
      glEnable(GL_LINE_STIPPLE);
      glDisable(GL_LINE_STIPPLE);
    }
    if (ZnListSize(map->mixed_arcs)) {
      line_width = 1.0;
      glLineWidth(line_width);
      glLineStipple(1, 0x27FF);
      glEnable(GL_LINE_STIPPLE);
      glDisable(GL_LINE_STIPPLE);
    }

    if (! map->tfi) {
      map->tfi = ZnGetTexFont(wi, map->text_font);
    }
    if (ZnListSize(map->texts) && map->tfi) {
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      glEnable(GL_TEXTURE_2D);
      glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
      glBindTexture(GL_TEXTURE_2D, ZnTexFontTex(map->tfi));
      cnt = ZnListSize(map->texts);
      points = ZnListArray(map->texts);
      for (i = 0; i < cnt; i++, points++) {
        glPushMatrix();
        ZnMapInfoGetText(map_info, i, NULL, NULL, NULL, NULL, NULL, &text);
        glTranslated(points->x, points->y, 0.0);
        ZnRenderString(map->tfi, text, strlen(text));
        glPopMatrix();
      }
      glDisable(GL_TEXTURE_2D);
    }

    if (map->symbol_patterns) {
      ZnImage sym, *syms = ZnListArray(map->symbol_patterns);
      int     num_syms = ZnListSize(map->symbol_patterns);
      
      cnt = ZnListSize(map->symbols);
      points = ZnListArray(map->symbols);
      for (i = 0; i < cnt; i++) {
        ZnMapInfoGetSymbol(map_info, i, NULL, NULL, NULL, &(tmp_str[0]));
        sym = syms[tmp_str[0]%num_syms];
        if (sym != ZnUnspecifiedImage) {
          ZnSizeOfImage(sym, &w, &h);
          p.x = points[i].x-(w+1.0)/2.0;
          p.y = points[i].y-(h+1.0)/2.0;
          ZnRenderIcon(wi, sym, map->color, &p, True);
        }
      }
    }
    
    if (wi->map_distance_symbol != ZnUnspecifiedImage) {
      ZnSizeOfImage(wi->map_distance_symbol, &w, &h);
      cnt = ZnListSize(map->marks);
      points = ZnListArray(map->marks);
      for (i = 0; i < cnt; i++, points++) {
        p.x = points->x-(w+1)/2;
        p.y = points->y-(h+1)/2;
        ZnRenderIcon(wi, wi->map_distance_symbol, map->color, &p, True);
      }
    }
  }
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
 *      This is *NOT* correct but for now we will tell that we are
 *      transparent even if we are solid filled.
 *
 *      !!!! We need to say we are opaque at least if we are solid
 *      filled. !!!!
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

static ZnItemClassStruct MAP_ITEM_CLASS = {
  "map",
  sizeof(MapItemStruct),
  map_attrs,
  0,                    /* num_parts */
  0,                    /* flags */
  -1,
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  NULL,                 /* GetFieldSet */
  NULL,                 /* GetAnchor */
  NULL,                 /* GetClipVertices */
  NULL,                 /* GetContours */
  NULL,
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

ZnItemClassId ZnMap = (ZnItemClassId) &MAP_ITEM_CLASS;
