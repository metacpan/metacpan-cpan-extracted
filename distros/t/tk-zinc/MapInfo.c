/*
 * MapInfo.c -- MapInfo interface.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : 
 *
 * $Id: MapInfo.c,v 1.28 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _WIN32
#include <sys/param.h>
#include <netinet/in.h>
#else
#include <winsock2.h>
#endif

#include "MapInfo.h"
#include "tkZinc.h"

#include <memory.h>
#include <math.h>



static const char rcsid[] = "$Id: MapInfo.c,v 1.28 2005/04/27 07:32:03 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 *-----------------------------------------------------------------------
 *
 * New types
 *
 *-----------------------------------------------------------------------
 */
typedef struct {
  ZnPtr                 tag;
  ZnMapInfoLineStyle    style;
  int                   width;
  ZnPoint               center;
  unsigned int          radius;
  int                   start_angle;
  int                   extend;
} ZnMapInfoArcStruct, *ZnMapInfoArc;

typedef struct {
  ZnPtr                 tag;
  ZnMapInfoLineStyle    style;
  int                   width;
  ZnPoint               from;
  ZnPoint               to;
  unsigned int          num_marks;
  ZnPoint               *marks;
} ZnMapInfoLineStruct, *ZnMapInfoLine;

typedef struct {
  ZnPtr                 tag;
  ZnPoint               at;
  char                  symbol[2];
} ZnMapInfoSymbolStruct, *ZnMapInfoSymbol;

typedef struct {
  ZnPtr                 tag;
  ZnMapInfoTextStyle    text_style;
  ZnMapInfoLineStyle    line_style;
  ZnPoint               at;
  char                  *text;
} ZnMapInfoTextStruct, *ZnMapInfoText;

typedef struct {
  char          *name;
  ZnList        lines;
  ZnList        symbols;
  ZnList        texts;
  ZnList        arcs;
} ZnMapInfoStruct, *ZnMapInfo;


#define MARKERS_SPACING         80.0    /* 10 nautic miles in 1/8 of a mile */
#define BASE_ALLOC_SIZE         8


/*
 *-----------------------------------------------------------------------
 *
 * Macros.
 * 
 *-----------------------------------------------------------------------
 */
#define NOT_MARKED_STYLE(style)                                         \
((style) == ZnMapInfoLineMarked ? ZnMapInfoLineSimple : (style));


/*
 *-----------------------------------------------------------------------
 *
 * ComputeLineMarks --
 *      Add marks to a line in the marks substructure.
 *
 *-----------------------------------------------------------------------
 */

static void
ComputeLineMarks(ZnMapInfoLine  marked_line)
{
  ZnDim length;
  ZnPos x_from = marked_line->from.x;
  ZnPos y_from = marked_line->from.y;
  ZnPos x_to = marked_line->to.x;
  ZnPos y_to = marked_line->to.y;
  ZnPos delta_x = x_from - x_to;
  ZnPos delta_y = y_from - y_to;
  ZnPos step_x, step_y;
  unsigned int  j;

  length = sqrt(delta_x * delta_x + delta_y * delta_y);
  step_x = (x_to - x_from) * MARKERS_SPACING / length;
  step_y = (y_to - y_from) * MARKERS_SPACING / length;
  marked_line->num_marks = (int) (length / MARKERS_SPACING);

  /* We don't want markers at ends, so we get rid of the last one
     if it is at an end */
  if (fmod(length, MARKERS_SPACING) == 0.0) {
    (marked_line->num_marks)--;
  }

  if (marked_line->num_marks) {
    marked_line->marks = ZnMalloc(marked_line->num_marks * sizeof(ZnPoint));
  }
  
  for (j = 0; j < marked_line->num_marks; j++) {
    marked_line->marks[j].x = x_from + ((j + 1) * step_x);
    marked_line->marks[j].y = y_from + ((j + 1) * step_y);
  }
}


static ZnMapInfoId
ZnMapInfoCreate(char    *name)
{
  ZnMapInfo     new_map;

  new_map = ZnMalloc(sizeof(ZnMapInfoStruct));
  memset((char *) new_map, 0, sizeof(ZnMapInfoStruct));
  if (!name) {
    name = "";
  }
  new_map->name = (char *) ZnMalloc(strlen(name)+1);
  /*printf("Nouvelle MapInfo: %s\n", name);*/
  strcpy(new_map->name, name);
  
  return((ZnMapInfoId) new_map);
}


static char *
ZnMapInfoName(ZnMapInfoId       map_info)
{
  if (!map_info) {
    return "";
  }
  return ((ZnMapInfo) map_info)->name;
}


static ZnMapInfoId
ZnMapInfoDuplicate(ZnMapInfoId  map_info)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfo     new_map;
  unsigned int  i, num_lines, num_texts;
  ZnMapInfoText new_texts, cur_texts;
  ZnMapInfoLine new_lines, cur_lines;

  if (!cur_map) {
    return ((ZnMapInfoId) NULL);
  }
  
  new_map = ZnMapInfoCreate(cur_map->name);

  if (cur_map->lines) {
    new_map->lines = ZnListDuplicate(cur_map->lines);

    cur_lines = ZnListArray(cur_map->lines);
    new_lines = ZnListArray(new_map->lines);
    num_lines = ZnListSize(cur_map->lines);

    for (i = 0; i < num_lines; i++) {
      if (new_lines[i].style == ZnMapInfoLineMarked) {
        new_lines[i].marks = ZnMalloc(new_lines[i].num_marks * sizeof(ZnPoint));
        memcpy((char *) new_lines[i].marks,
               (char *) cur_lines[i].marks,
               new_lines[i].num_marks * sizeof(ZnPoint));
      }
    }
  }
  if (cur_map->symbols) {
    new_map->symbols = ZnListDuplicate(cur_map->symbols);
  }
  if (cur_map->texts) {
    new_map->texts = ZnListDuplicate(cur_map->texts);

    cur_texts = ZnListArray(cur_map->texts);
    new_texts = ZnListArray(new_map->texts);
    num_texts = ZnListSize(cur_map->texts);
    
    for (i = 0; i < num_texts; i++) {
      new_texts[i].text = ZnMalloc(strlen(cur_texts[i].text) + 1);
      strcpy(new_texts[i].text, cur_texts[i].text);
    }
  }
  if (cur_map->arcs) {
    new_map->arcs = ZnListDuplicate(cur_map->arcs);
  }

  return((ZnMapInfoId) new_map);
}


static void
ZnMapInfoDelete(ZnMapInfoId     map_info)
{
  ZnMapInfo     cur_map = map_info;
  unsigned int  i, num_texts, num_lines;
  ZnMapInfoText cur_texts;
  ZnMapInfoLine cur_lines;
  
  if (cur_map) {
    if (cur_map->texts) {
      num_texts = ZnListSize(cur_map->texts);
      cur_texts = ZnListArray(cur_map->texts);

      for (i = 0; i < num_texts; i++) {
        ZnFree(cur_texts[i].text);
      }
      
      ZnListFree(cur_map->texts);
    }

    if (cur_map->lines) {
      num_lines = ZnListSize(cur_map->lines);
      cur_lines = ZnListArray(cur_map->lines);

      for (i = 0; i < num_lines; i++) {
        if (cur_lines[i].style == ZnMapInfoLineMarked) {
          ZnFree(cur_lines[i].marks);
        }
      }

      ZnListFree(cur_map->lines);
    }

    if (cur_map->symbols) {
      ZnListFree(cur_map->symbols);
    }
    
    if (cur_map->arcs) {
      ZnListFree(cur_map->arcs);
    }
    
    ZnFree(cur_map->name);
    ZnFree(cur_map);
  }
}

static void
ZnMapInfoEmpty(ZnMapInfoId      map_info)
{
  ZnMapInfo cur_map = map_info;

  if (cur_map) {
    if (cur_map->texts) {
      ZnListEmpty(cur_map->texts);
    }
    if (cur_map->lines) {
      ZnListEmpty(cur_map->lines);
    }
    if (cur_map->symbols) {
      ZnListEmpty(cur_map->symbols);
    }
    if (cur_map->arcs) {
      ZnListEmpty(cur_map->arcs);
    }
  }
}


static void
ZnMapInfoAddLine(ZnMapInfoId    map_info,
                 unsigned int   index,
                 ZnPtr          tag,
                 ZnMapInfoLineStyle line_style,
                 ZnDim          line_width,
                 ZnPos          x_from,
                 ZnPos          y_from,
                 ZnPos          x_to,
                 ZnPos          y_to)
{
  ZnMapInfo             cur_map = map_info;
  ZnMapInfoLineStruct   line_struct;

  if (cur_map) {
    if (!cur_map->lines) {
      cur_map->lines = ZnListNew(16, sizeof(ZnMapInfoLineStruct));
    }

    line_struct.style = line_style;
    if (line_width == 1.0) {
      line_struct.width = 0;
    }
    else {
      line_struct.width = (int) line_width;
    }
    line_struct.tag = tag;
    line_struct.from.x = x_from;
    line_struct.from.y = y_from;
    line_struct.to.x = x_to;
    line_struct.to.y = y_to;
    /*printf("Ajout de la ligne: %d %d %d %d\n", x_from, y_from, x_to, y_to);*/
    if (line_style == ZnMapInfoLineMarked) {
      ComputeLineMarks(&line_struct);
    }
    
    ZnListAdd(cur_map->lines, &line_struct, index);
  }
}


static void
ZnMapInfoReplaceLine(ZnMapInfoId        map_info,
                     unsigned int       index,
                     ZnPtr              tag,
                     ZnMapInfoLineStyle line_style,
                     ZnDim              line_width,
                     ZnPos              x_from,
                     ZnPos              y_from,
                     ZnPos              x_to,
                     ZnPos              y_to)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoLine line_ptr;

  if (cur_map && cur_map->lines) {
    line_ptr = ZnListAt(cur_map->lines, index);
    if (line_ptr) {
      if (line_ptr->style == ZnMapInfoLineMarked) {
        ZnFree(line_ptr->marks);
      }

      line_ptr->style = line_style;
      if (line_width == 1.0) {
        line_ptr->width = 0;
      }
      else {
        line_ptr->width = (int) line_width;
      }
      line_ptr->tag = tag;
      line_ptr->from.x = x_from;
      line_ptr->from.y = y_from;
      line_ptr->to.x = x_to;
      line_ptr->to.y = y_to;

      if (line_ptr->style == ZnMapInfoLineMarked) {
        ComputeLineMarks(line_ptr);
      }
    }
  }
}


static void
ZnMapInfoRemoveLine(ZnMapInfoId         map_info,
                    unsigned int        index)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoLine line_ptr;

  if (cur_map && cur_map->lines) {
    line_ptr = ZnListAt(cur_map->lines, index);
    if (line_ptr) {
      if (line_ptr->style == ZnMapInfoLineMarked) {
        ZnFree(line_ptr->marks);
      }

      ZnListDelete(cur_map->lines, index);
    }
  }
}


void
ZnMapInfoGetLine(ZnMapInfoId            map_info,
                 unsigned int           index,
                 ZnPtr                  *tag,
                 ZnMapInfoLineStyle     *line_style,
                 ZnDim                  *line_width,
                 ZnPos                  *x_from,
                 ZnPos                  *y_from,
                 ZnPos                  *x_to,
                 ZnPos                  *y_to)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoLine line_ptr;

  if (cur_map && cur_map->lines) {
    line_ptr = ZnListAt(cur_map->lines, index);
    if (line_ptr) {
      if (tag) {
        *tag = line_ptr->tag;
      }
      if (line_style) {
        *line_style = line_ptr->style;
      }
      if (line_width) {
        if (line_ptr->width == 1.0) {
          *line_width = 0;
        }
        else {
          *line_width = line_ptr->width;
        }
      }
      if (x_from) {
        *x_from = line_ptr->from.x;
      }
      if (y_from) {
        *y_from = line_ptr->from.y;
      }
      if (x_to) {
        *x_to = line_ptr->to.x;
      }
      if (y_to) {
        *y_to = line_ptr->to.y;
      }
    }
  }
}


void
ZnMapInfoGetMarks(ZnMapInfoId   map_info,
                  unsigned int  index,
                  ZnPoint       **marks,
                  unsigned int  *num_marks)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoLine line_ptr;

  if (cur_map && cur_map->lines) {
    line_ptr = ZnListAt(cur_map->lines, index);
    if (line_ptr && line_ptr->style == ZnMapInfoLineMarked) {
      if (marks) {
        *marks = line_ptr->marks;
      }
      if (num_marks) {
        *num_marks = line_ptr->num_marks;
      }
    }
  }
}


unsigned int
ZnMapInfoNumLines(ZnMapInfoId   map_info)
{
  ZnMapInfo     cur_map = map_info;

  if (cur_map && cur_map->lines) {
    return ZnListSize(cur_map->lines);
  }
  else {
    return 0;
  }
}
 
  
static void
ZnMapInfoAddSymbol(ZnMapInfoId  map_info,
                   unsigned int index,
                   ZnPtr        tag,
                   ZnPos        x,
                   ZnPos        y,
                   int          symbol)
{
  ZnMapInfo             cur_map = map_info;
  ZnMapInfoSymbolStruct symbol_struct;

  if (cur_map) {
    if (!cur_map->symbols) {
      cur_map->symbols = ZnListNew(16, sizeof(ZnMapInfoSymbolStruct));
    }
    
    symbol_struct.tag = tag;
    symbol_struct.at.x = x;
    symbol_struct.at.y = y;
    symbol_struct.symbol[0] = symbol;
    symbol_struct.symbol[1] = '\0';
    
    ZnListAdd(cur_map->symbols, &symbol_struct, index);
  }
}


static void
ZnMapInfoReplaceSymbol(ZnMapInfoId      map_info,
                       unsigned int     index,
                       ZnPtr            tag,
                       ZnPos            x,
                       ZnPos            y,
                       int              symbol)
{
  ZnMapInfo             cur_map = map_info;
  ZnMapInfoSymbolStruct symbol_struct;

  if (cur_map && cur_map->symbols) {
    symbol_struct.tag = tag;
    symbol_struct.at.x = x;
    symbol_struct.at.y = y;
    symbol_struct.symbol[0] = symbol;
    symbol_struct.symbol[1] = '\0';

    ZnListAtPut(cur_map->symbols, &symbol_struct, index);
  }
}


static void
ZnMapInfoRemoveSymbol(ZnMapInfoId       map_info,
                      unsigned int      index)
{
  ZnMapInfo     cur_map = map_info;

  if (cur_map && cur_map->symbols) {
    ZnListDelete(cur_map->symbols, index);
  }
}


void
ZnMapInfoGetSymbol(ZnMapInfoId  map_info,
                   unsigned int index,
                   ZnPtr        *tag,
                   ZnPos        *x,
                   ZnPos        *y,
                   char         *symbol)
{
  ZnMapInfo       cur_map = map_info;
  ZnMapInfoSymbol symbol_ptr;

  if (cur_map && cur_map->symbols) {
    symbol_ptr = ZnListAt(cur_map->symbols, index);
    if (symbol_ptr) {
      if (tag) {
        *tag = symbol_ptr->tag;
      }
      if (x) {
        *x = symbol_ptr->at.x;
      }
      if (y) {
        *y = symbol_ptr->at.y;
      }
      if (symbol) {
        *symbol = symbol_ptr->symbol[0];
      }
    }
  }
}


unsigned int
ZnMapInfoNumSymbols(ZnMapInfoId map_info)
{
  ZnMapInfo cur_map = map_info;

  if (cur_map && cur_map->symbols) {
    return ZnListSize(cur_map->symbols);
  }
  else {
    return 0;
  }
}
 
  
static void
ZnMapInfoAddText(ZnMapInfoId    map_info,
                 unsigned int   index,
                 ZnPtr          tag,
                 ZnMapInfoTextStyle text_style,
                 ZnMapInfoLineStyle line_style,
                 ZnPos          x,
                 ZnPos          y,
                 char           *text)
{
  ZnMapInfo             cur_map = map_info;
  ZnMapInfoTextStruct   text_struct;

  if (cur_map) {
    if (!cur_map->texts) {
      cur_map->texts = ZnListNew(16, sizeof(ZnMapInfoTextStruct));
    }

    text_struct.tag        = tag;
    text_struct.text_style = text_style;
    text_struct.line_style = NOT_MARKED_STYLE(line_style);
    text_struct.at.x       = x;
    text_struct.at.y       = y;
    text_struct.text       = ZnMalloc(strlen(text) + 1);
    strcpy(text_struct.text, text);
    
    ZnListAdd(cur_map->texts, &text_struct, index);
  }
}


static void
ZnMapInfoReplaceText(ZnMapInfoId        map_info,
                     unsigned int       index,
                     ZnPtr              tag,
                     ZnMapInfoTextStyle text_style,
                     ZnMapInfoLineStyle line_style,
                     ZnPos              x,
                     ZnPos              y,
                     char               *text)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoText text_ptr;

  if (cur_map && cur_map->texts) {
    text_ptr = ZnListAt(cur_map->texts, index);
    if (text_ptr) {
      ZnFree(text_ptr->text);

      text_ptr->tag        = tag;
      text_ptr->text_style = text_style;
      text_ptr->line_style = NOT_MARKED_STYLE(line_style);
      text_ptr->at.x       = x;
      text_ptr->at.y       = y;
      text_ptr->text       = ZnMalloc(strlen(text) + 1);
      strcpy(text_ptr->text, text);
    }
  }
}


static void
ZnMapInfoRemoveText(ZnMapInfoId         map_info,
                    unsigned int        index)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoText text_ptr;

  if (cur_map && cur_map->texts) {
    text_ptr = ZnListAt(cur_map->texts, index);
    if (text_ptr) {
      ZnFree(text_ptr->text);

      ZnListDelete(cur_map->texts, index);
    }
  }
}


void
ZnMapInfoGetText(ZnMapInfoId    map_info,
                 unsigned int   index,
                 ZnPtr          *tag,
                 ZnMapInfoTextStyle *text_style,
                 ZnMapInfoLineStyle *line_style,
                 ZnPos          *x,
                 ZnPos          *y,
                 char           **text)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoText text_ptr;

  if (cur_map && cur_map->texts) {
    text_ptr = ZnListAt(cur_map->texts, index);
    if (text_ptr) {
      if (tag) {
        *tag = text_ptr->tag;
      }
      if (text_style) {
        *text_style = text_ptr->text_style;
      }
      if (line_style) {
        *line_style = text_ptr->line_style;
      }
      if (x) {
        *x = text_ptr->at.x;
      }
      if (y) {
        *y = text_ptr->at.y;
      }
      if (text) {
        *text = text_ptr->text;
      }
    }
  }
}


unsigned int
ZnMapInfoNumTexts(ZnMapInfoId   map_info)
{
  ZnMapInfo cur_map = map_info;

  if (cur_map && cur_map->texts) {
    return ZnListSize(cur_map->texts);
  }
  else {
    return 0;
  }
}


static void
ZnMapInfoAddArc(ZnMapInfoId     map_info,
                unsigned int    index,
                ZnPtr           tag,
                ZnMapInfoLineStyle line_style,
                ZnDim           line_width,
                ZnPos           center_x,
                ZnPos           center_y,
                ZnDim           radius,
                ZnReal          start_angle,
                ZnReal          extend)
{
  ZnMapInfo             cur_map = map_info;
  ZnMapInfoArcStruct    arc_struct;
  
  if (cur_map) {
    if (!cur_map->arcs) {
      cur_map->arcs = ZnListNew(16, sizeof(ZnMapInfoArcStruct));
    }

    arc_struct.style = NOT_MARKED_STYLE(line_style);
    if (line_width == 1.0) {
      arc_struct.width = 0;
    }
    else {
      arc_struct.width = (int) line_width;
    }
    arc_struct.tag = tag;
    arc_struct.center.x = center_x;
    arc_struct.center.y = center_y;
    arc_struct.radius = (int) radius;
    arc_struct.start_angle = (int) start_angle;
    arc_struct.extend = (int) extend;
    
    ZnListAdd(cur_map->arcs, &arc_struct, index);
  }
}


static void
ZnMapInfoReplaceArc(ZnMapInfoId         map_info,
                    unsigned int        index,
                    ZnPtr               tag,
                    ZnMapInfoLineStyle  line_style,
                    ZnDim               line_width,
                    ZnPos               center_x,
                    ZnPos               center_y,
                    ZnDim               radius,
                    ZnReal              start_angle,
                    ZnReal              extend)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoArc  arc_ptr;
  
  if (cur_map && cur_map->arcs) {
    arc_ptr = ZnListAt(cur_map->arcs, index);
    if (arc_ptr) {
      arc_ptr->style = NOT_MARKED_STYLE(line_style);
      if (line_width == 1.0) {
        arc_ptr->width = 0;
      }
      else {
        arc_ptr->width = (int) line_width;
      }
      arc_ptr->tag = tag;
      arc_ptr->center.x = center_x;
      arc_ptr->center.y = center_y;
      arc_ptr->radius = (int) radius;
      arc_ptr->start_angle = (int) start_angle;
      arc_ptr->extend = (int) extend;
    }
  }
}


static void
ZnMapInfoRemoveArc(ZnMapInfoId  map_info,
                   unsigned int index)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoArc  arc_ptr;

  if (cur_map && cur_map->arcs) {
    arc_ptr = ZnListAt(cur_map->arcs, index);
    if (arc_ptr) {
      ZnListDelete(cur_map->arcs, index);
    }
  }
}


void
ZnMapInfoGetArc(ZnMapInfoId     map_info,
                unsigned int    index,
                ZnPtr           *tag,
                ZnMapInfoLineStyle *line_style,
                ZnDim           *line_width,
                ZnPos           *center_x,
                ZnPos           *center_y,
                ZnDim           *radius,
                ZnReal          *start_angle,
                ZnReal          *extend)
{
  ZnMapInfo     cur_map = map_info;
  ZnMapInfoArc  arc_ptr;

  if (cur_map && cur_map->arcs) {
    arc_ptr = ZnListAt(cur_map->arcs, index);
    if (arc_ptr) {
      if (tag) {
        *tag = arc_ptr->tag;
      }
      if (line_style) {
        *line_style = arc_ptr->style;
      }
      if (line_width) {
        if (arc_ptr->width == 1.0) {
          *line_width = 0;
        }
        else {
          *line_width = arc_ptr->width;
        }
      }
      if (center_x) {
        *center_x = arc_ptr->center.x;
      }
      if (center_y) {
        *center_y = arc_ptr->center.y;
      }
      if (radius) {
        *radius = arc_ptr->radius;
      }
      if (start_angle) {
        *start_angle = arc_ptr->start_angle;
      }
      if (extend) {
        *extend = arc_ptr->extend;
      }
    }
  }
}

unsigned int
ZnMapInfoNumArcs(ZnMapInfoId    map_info)
{
  ZnMapInfo cur_map = map_info;

  if (cur_map && cur_map->arcs) {
    return ZnListSize(cur_map->arcs);
  }
  else {
    return 0;
  }
}

static void
ZnMapInfoScale(ZnMapInfoId      map_info,
               ZnReal           factor)
{
  ZnMapInfo     mp = map_info;
  int           i, num;
  ZnMapInfoLine line_ptr;
  ZnMapInfoSymbol sym_ptr;
  ZnMapInfoText text_ptr;
  ZnMapInfoArc  arc_ptr;

  if (mp && mp->lines) {
    num = ZnListSize(mp->lines);
    line_ptr = ZnListArray(mp->lines);
    for (i = 0; i < num; i++, line_ptr++) {
      line_ptr->from.x *= factor;
      line_ptr->from.y *= factor;
      line_ptr->to.x *= factor;
      line_ptr->to.y *= factor;
    }
  }
  if (mp && mp->symbols) {
    num = ZnListSize(mp->symbols);
    sym_ptr = ZnListArray(mp->symbols);
    for (i = 0; i < num; i++, sym_ptr++) {
      sym_ptr->at.x *= factor;
      sym_ptr->at.y *= factor;
    }
  }
  if (mp && mp->texts) {
    num = ZnListSize(mp->texts);
    text_ptr = ZnListArray(mp->texts);
    for (i = 0; i < num; i++, text_ptr++) {
      text_ptr->at.x *= factor;
      text_ptr->at.y *= factor;
    }
  }
  if (mp && mp->arcs) {
    num = ZnListSize(mp->arcs);
    arc_ptr = ZnListArray(mp->arcs);
    for (i = 0; i < num; i++, arc_ptr++) {
      arc_ptr->center.x *= factor;
      arc_ptr->center.y *= factor;
      arc_ptr->radius = (unsigned int) (arc_ptr->radius * factor);
    }
  }
}

static void
ZnMapInfoTranslate(ZnMapInfoId  map_info,
                   ZnPos        x,
                   ZnPos        y)
{
  ZnMapInfo     mp = map_info;
  int           i, num;
  ZnMapInfoLine line_ptr;
  ZnMapInfoSymbol sym_ptr;
  ZnMapInfoText text_ptr;
  ZnMapInfoArc  arc_ptr;

  if (mp && mp->lines) {
    num = ZnListSize(mp->lines);
    line_ptr = ZnListArray(mp->lines);
    for (i = 0; i < num; i++, line_ptr++) {
      line_ptr->from.x += x;
      line_ptr->from.y += y;
      line_ptr->to.x += x;
      line_ptr->to.y += y;
    }
  }
  if (mp && mp->symbols) {
    num = ZnListSize(mp->symbols);
    sym_ptr = ZnListArray(mp->symbols);
    for (i = 0; i < num; i++, sym_ptr++) {
      sym_ptr->at.x += x;
      sym_ptr->at.y += y;
    }
  }
  if (mp && mp->texts) {
    num = ZnListSize(mp->texts);
    text_ptr = ZnListArray(mp->texts);
    for (i = 0; i < num; i++, text_ptr++) {
      text_ptr->at.x += x;
      text_ptr->at.y += y;
    }
  }
  if (mp && mp->arcs) {
    num = ZnListSize(mp->arcs);
    arc_ptr = ZnListArray(mp->arcs);
    for (i = 0; i < num; i++, arc_ptr++) {
      arc_ptr->center.x += x;
      arc_ptr->center.y += y;
    }
  }
}



#define TEXT_SIZE               256
#define ntohi(n) ntohl((n))

/*
 *-----------------------------------------------------------------------
 *
 * Videomap record definition. Ints are assumed to be 4 bytes.
 *
 *-----------------------------------------------------------------------
 */

typedef struct {
  int   id;             /* Map id (internal) */
  int   dashed;         /* Tell if vectors are dashed (exclusive with marked) */
  int   expanded;       /* Device coordinates or world coordinates (ignored now) */
  int   marked;         /* Tell if vectors are marked (exclusive with dashed) */
  int   color;          /* drawing color (ignored now) */
  int   elements[50];   /* Element type ('P', 'V', 'T') */
  int   x[50];          /* Coordinates if 'P' or 'V' */
  int   y[50];
  int   symbol[50];     /* Filled if 'P' or 'V' */
  int   text[50];       /* Low order byte is ascii char if 'T' */
  int   num_elements;   /* Number of elements */
} VideoMap;

/*
 *-----------------------------------------------------------------------
 *
 * ReorderVidomap - reorder integers according to the endianess
 *
 *-----------------------------------------------------------------------
 */

static void
ReorderVidomap(VideoMap *vm)
{
  int   loop;
  
  vm->id = ntohi((unsigned int) vm->id);
  vm->dashed = ntohi((unsigned int) vm->dashed);
  vm->expanded = ntohi((unsigned int) vm->expanded);
  vm->marked = ntohi((unsigned int) vm->marked);
  vm->color = ntohi((unsigned int) vm->color);
  for (loop = 0; loop < 50; loop++) {
    vm->elements[loop] = ntohi((unsigned int) vm->elements[loop]);
    vm->x[loop] = ntohi((unsigned int) vm->x[loop]);
    vm->y[loop] = ntohi((unsigned int) vm->y[loop]);
    vm->symbol[loop] = ntohi((unsigned int) vm->symbol[loop]);
    vm->text[loop] = ntohi((unsigned int) vm->text[loop]);
  }
  vm->num_elements = ntohi((unsigned int) vm->num_elements);
}

/*
 *-----------------------------------------------------------------------
 *
 * FillMap - Fill map with data in Videomap record vm.
 *
 *-----------------------------------------------------------------------
 */

static void
FillMap(ZnMapInfoId     map,
        VideoMap        *vm)
{
  int           i;
  ZnBool        has_start_pos = False;
  ZnPos         x_cur=0, y_cur=0;
  char          ch;
  ZnPos         text_x=0, text_y=0;
  char          text[TEXT_SIZE];
  ZnBool        in_text = False;
  ZnBool        in_mod_text = False;
  unsigned int  text_size=0;

  for (i = 0; i < vm->num_elements; i++) {
    switch(vm->elements[i] & 0xFF) {
    case 'p':
    case 'P':
      if (in_text) {
        in_text = in_mod_text = False;
        while (text[text_size - 1] == ' ') {
          text_size--;
        }
        text[text_size] = (char) 0;
        ZnMapInfoAddText(map, ZnMapInfoNumTexts(map), NULL, ZnMapInfoNormalText,
                         ZnMapInfoLineSimple, text_x, text_y, text);
      }

      x_cur = (int) (short) vm->x[i];
      y_cur = (int) (short) vm->y[i];
      has_start_pos = True;
        
      if (vm->symbol[i]) {
        ZnMapInfoAddSymbol(map, ZnMapInfoNumSymbols(map), NULL, x_cur, y_cur,
                           (char) vm->symbol[i]);
      }
      break;

      /* We gather consecutive 'T' elements in a text. We skip
         leading and trailing spaces and mod texts (between '@'
         and now obsolete) */

    case 't':
    case 'T':
      if (!has_start_pos) {
        ZnWarning("Bogus map block, it has been discarded\n");
        return;
      }

      if (in_text == False) {
        ch = (char) vm->text[i] & 0xFF;
        if (ch == '@') {
          if (in_mod_text == True) {
            in_mod_text = False;
          }
          else {
            in_mod_text = True;
          }
        }
        else if (in_mod_text == False) {
          in_text = True;
          text_size = 0;
          text_x = x_cur;
          text_y = y_cur;
          text[0] = (char) 0;
        }
      }
      if (in_text) {
        text[text_size] = (char) vm->text[i] & 0xFF;
        text_size++;
      }
      break;

    case 'v':
    case 'V':
      if (!has_start_pos) {
        ZnWarning("Bogus map block, it has been discarded\n");
        return;
      }

      if (in_text) {
        in_text = in_mod_text = False;
        while (text[text_size - 1] == ' ') {
          text_size--;
        }
        text[text_size] = (char) 0;
        ZnMapInfoAddText(map, ZnMapInfoNumTexts(map), NULL, ZnMapInfoNormalText,
                         ZnMapInfoLineSimple, text_x, text_y, text);
      }

      if (vm->dashed)   {
        ZnMapInfoAddLine(map, ZnMapInfoNumLines(map), NULL, ZnMapInfoLineDashed,
                         0, x_cur, y_cur,
                         (int) (short) vm->x[i], (int) (short) vm->y[i]);
      }
      else if (vm->marked) {
        ZnMapInfoAddLine(map, ZnMapInfoNumLines(map), NULL, ZnMapInfoLineMarked,
                         0, x_cur, y_cur,
                         (int) (short) vm->x[i], (int) (short) vm->y[i]);
      }
      else {
        ZnMapInfoAddLine(map, ZnMapInfoNumLines(map), NULL, ZnMapInfoLineSimple,
                         0, x_cur, y_cur,
                         (int) (short) vm->x[i], (int) (short) vm->y[i]);
      }

      x_cur = (int) (short) vm->x[i];
      y_cur = (int) (short) vm->y[i];

      if (vm->symbol[i]) {
        ZnMapInfoAddSymbol(map, ZnMapInfoNumSymbols(map), NULL, x_cur, y_cur,
                           (char) vm->symbol[i]);
      }
      break;
    }
  }

  if (in_text) {
    in_text = in_mod_text = False;
    while (text[text_size - 1] == ' ') {
      text_size--;
    }
    text[text_size] = (char) 0;
    ZnMapInfoAddText(map, ZnMapInfoNumTexts(map), NULL, ZnMapInfoNormalText,
                     ZnMapInfoLineSimple, text_x, text_y, text);
  }
}

/*
 *-----------------------------------------------------------------------
 *
 * ZnMapInfoGetVideomap - Load a mapinfo with the content of a videomap
 *      file named 'filename'. Only the sub map 'index' will be loaded.
 *      If successful a new mapinfo is returned, NULL otherwise. The
 *      index is zero based.
 *
 *-----------------------------------------------------------------------
 */
static int
ZnMapInfoGetVideomap(ZnMapInfoId        map,
                     char               *filename,
                     unsigned int       index)
{
  VideoMap      current_vm;
  Tcl_Channel   chan;
  unsigned int  cur_index, cur_id;

  /* Open the specified map file. */
  chan = Tcl_OpenFileChannel(NULL, filename, "r", 0);
  if (chan == NULL) {
    return TCL_ERROR;
  }
  if (Tcl_SetChannelOption(NULL, chan,
                           "-translation", "binary") == TCL_ERROR) {
    return TCL_ERROR;
  }

  /* Load the map */

  /* First skip the leading maps up to index. */
  cur_index = 0;
  if (Tcl_Read(chan, (char *) &current_vm,
               sizeof(VideoMap)) != sizeof(VideoMap)) {
    goto error;
  }
  cur_id = ntohi((unsigned int) current_vm.id);
  while (cur_index != index) {
    if (Tcl_Read(chan, (char *) &current_vm,
                 sizeof(VideoMap)) != sizeof(VideoMap)) {
      goto error;
    }
    if (cur_id != ntohi((unsigned int) current_vm.id)) {
      cur_index++;
      cur_id = ntohi((unsigned int) current_vm.id);
    }
  };

  /* Then load all the map modules. */
  do {
    ReorderVidomap(&current_vm);
    FillMap(map, &current_vm);
    if ((Tcl_Read(chan, (char *) &current_vm,
                  sizeof(VideoMap)) != sizeof(VideoMap)) &&
        !Tcl_Eof(chan)) {
      goto error;
    }
  }
  while ((cur_id == ntohi((unsigned int) current_vm.id)) &&
         !Tcl_Eof(chan));

  Tcl_Close(NULL, chan);
  return TCL_OK;

 error:
  Tcl_Close(NULL, chan);
  return TCL_ERROR;
}

/*
 *-----------------------------------------------------------------------
 *
 * ZnMapInfoVideomapIds - Return the list of sub map ids contained in a
 *      videomap file. This makes it possible to iterate through such
 *      a file without stumbling on an error, to know how much maps
 *      are there and to sort them according to their ids.
 *
 *-----------------------------------------------------------------------
 */ 

static ZnList
ZnMapInfoVideomapIds(char       *filename)
{
  Tcl_Channel   chan;
  VideoMap      current_vm;
  unsigned int  cur_id;
  ZnList        ids;
  
  /* Open the specified map file. */
  chan = Tcl_OpenFileChannel(NULL, filename, "r", 0);
  if (chan == NULL) {
    return NULL;
  }
  if (Tcl_SetChannelOption(NULL, chan,
                           "-translation", "binary") == TCL_ERROR) {
    return NULL;
  }

  if (Tcl_Read(chan, (char *) &current_vm,
               sizeof(VideoMap)) != sizeof(VideoMap)) {
  error:
    Tcl_Close(NULL, chan);
    return NULL;
  }
  cur_id = ntohi((unsigned int) current_vm.id);
  ids = ZnListNew(16, sizeof(int));
  /*printf("id %d\n", cur_id);*/
  ZnListAdd(ids, &cur_id, ZnListTail);
  
  do {
    if (Tcl_Read(chan, (char *) &current_vm,
                 sizeof(VideoMap)) != sizeof(VideoMap)) {
      ZnListFree(ids);
      goto error;
    }
    if (cur_id != ntohi((unsigned int) current_vm.id)) {
      cur_id = ntohi((unsigned int) current_vm.id);
      /*printf("id %d\n", cur_id);*/
      ZnListAdd(ids, &cur_id, ZnListTail);
    }
  }
  while (!Tcl_Eof(chan));

  Tcl_Close(NULL, chan);
  return ids;
}


/*
 *--------------------------------------------------------------------------
 *
 * ZnMapInfo and Videomapstuff that should go eventually in its own file.
 *
 *--------------------------------------------------------------------------
 */

static Tcl_HashTable    mapInfoTable;
static ZnBool           map_info_inited = False;

typedef struct {
  ClientData            client_data;
  ZnMapInfoChangeProc   proc;
} ZnMapInfoClient;

typedef struct {
  ZnMapInfoId   map_info;
  ZnBool        deleted;
  ZnList        clients;
} ZnMapInfoMaster;

static void
ZnMapInfoInit()
{
  Tcl_InitHashTable(&mapInfoTable, TCL_ONE_WORD_KEYS);

  map_info_inited = True;
}

static void
UpdateMapInfoClients(ZnMapInfoMaster    *master)
{
  int             i, num;
  ZnMapInfoClient *client;

  num = ZnListSize(master->clients);
  client = ZnListArray(master->clients);
  for (i = 0; i < num; i++, client++) {
    (*client->proc)(client->client_data, master->map_info);
  }
}

static int
ZnCreateMapInfo(Tcl_Interp      *interp,
                char            *name,
                ZnMapInfoId     *map_info)
{
  Tk_Uid          uid = Tk_GetUid(name);
  Tcl_HashEntry   *entry;
  int             new;
  ZnMapInfoMaster *master;
  
  if (!map_info_inited) {
    ZnMapInfoInit();
  }
  
  entry = Tcl_CreateHashEntry(&mapInfoTable, uid, &new);
  if (!new) {
    /*
     * Empty the map info if it is not.
     */
    master = (ZnMapInfoMaster *) Tcl_GetHashValue(entry);
    if (master->deleted) {
      master->deleted = False;
    }
    else {
      ZnMapInfoEmpty(master->map_info);
      UpdateMapInfoClients(master);
    }
  }
  else {
    master = (ZnMapInfoMaster *) ZnMalloc(sizeof(ZnMapInfoMaster));
    master->map_info = ZnMapInfoCreate(name);
    master->deleted = False;
    master->clients = ZnListNew(1, sizeof(ZnMapInfoClient));
    Tcl_SetHashValue(entry, master);
  }
  if (map_info) {
    *map_info = master->map_info;
  }
  return TCL_OK;
}

static int
ZnDuplicateZnMapInfo(Tcl_Interp *interp,
                     char               *name,
                     ZnMapInfoId        map_info)
{
  Tk_Uid          uid = Tk_GetUid(name);
  Tcl_HashEntry   *entry;
  int             new;
  ZnMapInfoMaster *master;
  
  if (!map_info_inited) {
    ZnMapInfoInit();
  }
  
  entry = Tcl_CreateHashEntry(&mapInfoTable, uid, &new);
  if (!new) {
    Tcl_AppendResult(interp, "duplicate mapinfo \"", name, "\" already exists", NULL);
    return TCL_ERROR;
  }
  master = (ZnMapInfoMaster *) ZnMalloc(sizeof(ZnMapInfoMaster));
  master->map_info = ZnMapInfoDuplicate(map_info);
  master->deleted = False;
  master->clients = ZnListNew(1, sizeof(ZnMapInfoClient));
  Tcl_SetHashValue(entry, master);

  return TCL_OK;
}

static ZnMapInfoMaster *
LookupMapInfoMaster(Tcl_Interp  *interp,
                    char        *name)
{
  Tk_Uid          uid = Tk_GetUid(name);
  Tcl_HashEntry   *entry;
  ZnMapInfoMaster *master;
  
  if (!map_info_inited) {
    ZnMapInfoInit();
  }
  
  entry = Tcl_FindHashEntry(&mapInfoTable, uid);
  if (entry == NULL) {
  mp_error:
    Tcl_AppendResult(interp, "mapinfo \"", name, "\" doesn't exist", NULL);
    return NULL;
  }
  master = (ZnMapInfoMaster *) Tcl_GetHashValue(entry);
  if (master->deleted) {
    goto mp_error;
  }
  return master;
}

static int
ZnDeleteMapInfo(Tcl_Interp      *interp,
                char            *name)
{
  ZnMapInfoMaster *master;
  Tk_Uid          uid = Tk_GetUid(name);
  Tcl_HashEntry   *entry;
  
  if (!map_info_inited) {
    ZnMapInfoInit();
  }
  
  entry = Tcl_FindHashEntry(&mapInfoTable, uid);
  if (entry == NULL) {
    return TCL_ERROR;
  }
  
  master = (ZnMapInfoMaster *) Tcl_GetHashValue(entry);
  if (ZnListSize(master->clients) != 0) {
    master->deleted = True;
    ZnMapInfoEmpty(master->map_info);
    UpdateMapInfoClients(master);
  }
  else {
    ZnMapInfoDelete(master->map_info);
    ZnListFree(master->clients);
    Tcl_DeleteHashEntry(entry);
    ZnFree(master);
  }

  return TCL_OK;
}

ZnMapInfoId
ZnGetMapInfo(Tcl_Interp         *interp,
             char               *name,
             ZnMapInfoChangeProc proc,
             ClientData         client_data)
{
  ZnMapInfoMaster       *master;
  ZnMapInfoClient       client;
  
  master = LookupMapInfoMaster(interp, name);
  if (master == NULL) {
    return NULL;
  }
  client.proc = proc;
  client.client_data = client_data;
  ZnListAdd(master->clients, &client, ZnListTail);

  return master->map_info;
}

void
ZnFreeMapInfo(ZnMapInfoId       map_info,
              ZnMapInfoChangeProc proc,
              ClientData        client_data)
{
  Tk_Uid        uid = Tk_GetUid(ZnMapInfoName(map_info));
  Tcl_HashEntry *entry;
  ZnMapInfoMaster *master;
  ZnMapInfoClient *client;
  unsigned int  num, i;
  
  if (!map_info_inited) {
    ZnMapInfoInit();
  }
  
  entry = Tcl_FindHashEntry(&mapInfoTable, uid);
  if (entry == NULL) {
    return;
  }
  master = (ZnMapInfoMaster *) Tcl_GetHashValue(entry);
  client = ZnListArray(master->clients);
  num = ZnListSize(master->clients);
  for (i = 0; i < num; i++, client++) {
    if ((client->client_data == client_data) &&
        (client->proc == proc)) {
      ZnListDelete(master->clients, i);
      return;
    }
  }
}

static void
ZnUpdateMapInfoClients(ZnMapInfoId      map_info)
{
  Tk_Uid          uid = Tk_GetUid(ZnMapInfoName(map_info));
  Tcl_HashEntry   *entry;
  ZnMapInfoMaster *master;

  if (!map_info_inited) {
    ZnMapInfoInit();
  }
  
  entry = Tcl_FindHashEntry(&mapInfoTable, uid);
  if (entry == NULL) {
    return;
  }
  master = (ZnMapInfoMaster *) Tcl_GetHashValue(entry);
  UpdateMapInfoClients(master);
}


/*
 * These arrays must be kept in sync with the ZnMapInfoLineStyle
 * and ZnMapInfoTextStyle enums.
 */
static char *line_style_strings[] = {
  "simple",
  "dashed",
  "dotted",
  "mixed",
  "marked",
};

static char *text_style_strings[] = {
  "normal",
  "underlined"
};

static char *
ZnMapInfoLineStyleToString(ZnMapInfoLineStyle   line_style)
{
  return line_style_strings[line_style];
}

static int
ZnMapInfoLineStyleFromString(Tcl_Interp         *interp,
                             char               *str,
                             ZnMapInfoLineStyle *line_style)
{
  int   i, num = sizeof(line_style_strings)/sizeof(char *);

  for (i = 0; i < num; i++) {
    if (strcmp(str, line_style_strings[i]) == 0) {
      *line_style = i;
      return TCL_OK;
    }
  }
  Tcl_AppendResult(interp, " incorrect mapinfo line style \"",
                   str,"\"", NULL);
  return TCL_ERROR;
}

static char *
ZnMapInfoTextStyleToString(ZnMapInfoTextStyle   text_style)
{
  return text_style_strings[text_style];
}

static int
ZnMapInfoTextStyleFromString(Tcl_Interp         *interp,
                             char                       *str,
                             ZnMapInfoTextStyle *text_style)
{
  int   i, num = sizeof(text_style_strings)/sizeof(char *);

  for (i = 0; i < num; i++) {
    if (strcmp(str, text_style_strings[i]) == 0) {
      *text_style = i;
      return TCL_OK;
    }
  }
  Tcl_AppendResult(interp, " incorrect mapinfo text style \"",
                   str,"\"", NULL);
  return TCL_ERROR;
}

int
ZnMapInfoObjCmd(ClientData      client_data,
                Tcl_Interp      *interp,        /* Current interpreter. */
                int             argc,           /* Number of arguments. */
                Tcl_Obj *CONST  args[])
{
  ZnPos           x, y;
  int             index, index2, result;
  ZnMapInfoMaster *master;
  Tcl_Obj         *l;
#ifdef PTK_800
  static char *sub_cmd_strings[] =
#else
  static CONST char *sub_cmd_strings[] =
#endif
  {
    "add", "count", "create", "delete", "duplicate",
    "get", "remove", "replace", "scale", "translate", NULL
  };
#ifdef PTK_800
  static char *e_type_strings[] =
#else
  static CONST char *e_type_strings[] =
#endif
  {
    "arc", "line", "symbol", "text", NULL
  };
  enum          sub_cmds {
    ZN_MI_ADD, ZN_MI_COUNT, ZN_MI_CREATE, ZN_MI_DELETE, ZN_MI_DUPLICATE,
    ZN_MI_GET, ZN_MI_REMOVE, ZN_MI_REPLACE, ZN_MI_SCALE, ZN_MI_TRANSLATE
  };
  enum          e_types {
    ZN_E_ARC, ZN_E_LINE, ZN_E_SYMBOL, ZN_E_TEXT
  };
  

  if (argc < 3) {
    Tcl_WrongNumArgs(interp, 1, args, "mapInfo/name subCmd ?args?");
    return TCL_ERROR;
  }

  if (Tcl_GetIndexFromObj(interp, args[2], sub_cmd_strings,
                          "subCmd", 0, &index) != TCL_OK) {
    return TCL_ERROR;
  }
  result = TCL_OK;
  /*printf("mapinfo command \"%s\", argc=%d\n",
    Tcl_GetString(args[2]), argc);*/

  switch((enum sub_cmds) index) {
    /*
     * create
     */
  case ZN_MI_CREATE:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "name create");
        return TCL_ERROR;
      }
      if (ZnCreateMapInfo(interp, Tcl_GetString(args[1]), NULL) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    break;
    /*
     * delete
     */
  case ZN_MI_DELETE:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo delete");
        return TCL_ERROR;
      }
      if (ZnDeleteMapInfo(interp, Tcl_GetString(args[1])) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    break;
    /*
     * duplicate
     */
  case ZN_MI_DUPLICATE:
    {
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo duplicate name");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (ZnDuplicateZnMapInfo(interp, Tcl_GetString(args[3]),
                               master->map_info) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    break;
    /*
     * add/replace
     */
  case ZN_MI_ADD:
  case ZN_MI_REPLACE:
    {
      ZnMapInfoLineStyle line_style;
      ZnMapInfoTextStyle text_style;
      int                i, insert, val;
      ZnPos              coords[6];
      ZnBool             add_cmd = (enum sub_cmds) index == ZN_MI_ADD;
      int                num_param = add_cmd ? 4 : 5;
      
      if (argc < num_param) {
        Tcl_WrongNumArgs(interp, 3, args,
                         add_cmd ? "elementType ?args?" : "elementType index ?args?");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (!add_cmd) {
        if (Tcl_GetIntFromObj(interp, args[4], &insert) == TCL_ERROR) {
          return TCL_ERROR;
        }
      }
      if (Tcl_GetIndexFromObj(interp, args[3], e_type_strings,
                              "elementType", 0, &index2) != TCL_OK) {
        return TCL_ERROR;
      }
      switch ((enum e_types) index2) {
      case ZN_E_LINE:
        {
          if (argc != (num_param+6)) {
            Tcl_WrongNumArgs(interp, 4, args,
                             add_cmd ? "style width x1 y1 x2 y2" : "index style width x1 y1 x2 y2");
            return TCL_ERROR;
          }
          if (ZnMapInfoLineStyleFromString(interp, Tcl_GetString(args[num_param]),
                                           &line_style) == TCL_ERROR) {
            return TCL_ERROR;
          }
          for (i = 0; i < 5; i++) {
            if (Tcl_GetDoubleFromObj(interp, args[num_param+i+1], &coords[i]) == TCL_ERROR) {
              return TCL_ERROR;
            }
          }
          if (coords[0] < 0) {
            coords[0] = 0;
          }
          if (add_cmd) {
            ZnMapInfoAddLine(master->map_info, ZnListTail, NULL, line_style,
                             coords[0], coords[1], coords[2], coords[3], coords[4]);
          }
          else {
            ZnMapInfoReplaceLine(master->map_info, insert, NULL, line_style,
                                 coords[0], coords[1], coords[2], coords[3], coords[4]);
          }
        }
        break;
      case ZN_E_SYMBOL:
        {
          if (argc != (num_param+3)) {
            Tcl_WrongNumArgs(interp, 4, args,
                             add_cmd ? "x y intVal" : "index x y intVal");
            return TCL_ERROR;
          }
          for (i = 0; i < 2; i++) {
            if (Tcl_GetDoubleFromObj(interp, args[num_param+i], &coords[i]) == TCL_ERROR) {
              return TCL_ERROR;
            }
          }
          if (Tcl_GetIntFromObj(interp, args[num_param+2], &val) == TCL_ERROR) {
            return TCL_ERROR;
          }
          if (val < 0) {
            val = 0;
          }
          if (add_cmd) {
            ZnMapInfoAddSymbol(master->map_info, ZnListTail, NULL, coords[0],
                               coords[1], (char) val);
          }
          else {
            ZnMapInfoReplaceSymbol(master->map_info, insert, NULL, coords[0],
                                   coords[1], (char) val);
          }
        }
        break;
      case ZN_E_TEXT:
        {
          if (argc != (num_param+5)) {
            Tcl_WrongNumArgs(interp, 4, args,
                             add_cmd ? "textStyle lineStyle x y string" : "index textStyle lineStyle x y string");
            return TCL_ERROR;
          }
          if (ZnMapInfoTextStyleFromString(interp, Tcl_GetString(args[num_param]),
                                           &text_style) == TCL_ERROR) {
            return TCL_ERROR;
          }
          if (ZnMapInfoLineStyleFromString(interp, Tcl_GetString(args[num_param+1]),
                                           &line_style) == TCL_ERROR) {
            return TCL_ERROR;
          }
          for (i = 0; i < 2; i++) {
            if (Tcl_GetDoubleFromObj(interp, args[num_param+i+2], &coords[i]) == TCL_ERROR) {
              return TCL_ERROR;
            }
          }
          if (add_cmd) {
            ZnMapInfoAddText(master->map_info, ZnListTail, NULL, text_style,
                             line_style, coords[0], coords[1],
                             Tcl_GetString(args[num_param+4]));
          }
          else {
            /*printf("replace text ts %d ls %d %g %g %s\n", text_style,
              line_style, coords[0], coords[1], Tcl_GetString(args[num_param+4]));*/
            ZnMapInfoReplaceText(master->map_info, insert, NULL, text_style,
                                 line_style, coords[0], coords[1],
                                 Tcl_GetString(args[num_param+4]));
          }
        }
        break;
      case ZN_E_ARC:
        {
          if (argc != (num_param+7)) {
            Tcl_WrongNumArgs(interp, 4, args,
                             add_cmd ? "style width cx cy radius start extent" : "index style width cx cy radius start extent");
            return TCL_ERROR;
          }
          if (ZnMapInfoLineStyleFromString(interp, Tcl_GetString(args[num_param]),
                                           &line_style) == TCL_ERROR) {
            return TCL_ERROR;
          }
          for (i = 0; i < 6; i++) {
            if (Tcl_GetDoubleFromObj(interp, args[num_param+i+1], &coords[i]) == TCL_ERROR) {
              return TCL_ERROR;
            }
          }
          if (coords[0] < 0) {
            coords[0] = 0;
          }
          if (coords[3] < 0) {
            coords[3] = 0;
          }
          if (add_cmd) {
            ZnMapInfoAddArc(master->map_info, ZnListTail, NULL, line_style, coords[0],
                            coords[1], coords[2], coords[3], coords[4], coords[5]);
          }
          else {
            ZnMapInfoReplaceArc(master->map_info, insert, NULL, line_style, coords[0],
                                coords[1], coords[2], coords[3], coords[4], coords[5]);
          }
        }
        break;
      }
      UpdateMapInfoClients(master);
    }
    break;
    /*
     * count
     */
  case ZN_MI_COUNT:
    {
      int       count = 0;
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo count type");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (Tcl_GetIndexFromObj(interp, args[3], e_type_strings,
                              "elementType", 0, &index2) != TCL_OK) {
        return TCL_ERROR;
      }
      switch ((enum e_types) index2) {
      case ZN_E_LINE:
        count = ZnMapInfoNumLines(master->map_info);
        break;
      case ZN_E_SYMBOL:
        count = ZnMapInfoNumSymbols(master->map_info);
        break;
      case ZN_E_TEXT:
        count = ZnMapInfoNumTexts(master->map_info);
        break;
      case ZN_E_ARC:
        count = ZnMapInfoNumArcs(master->map_info);
        break;
      }
      l = Tcl_NewIntObj(count);
      Tcl_SetObjResult(interp, l);
    }
    break;
    /*
     * get
     */
  case ZN_MI_GET:
    {
      int   insert;

      if (argc != 5) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo get type index");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (Tcl_GetIntFromObj(interp, args[4], &insert) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (insert < 0) {
        insert = 0;
      }
      if (Tcl_GetIndexFromObj(interp, args[3], e_type_strings,
                              "elementType", 0, &index2) != TCL_OK) {
        return TCL_ERROR;
      }
      switch ((enum e_types) index2) {
      case ZN_E_LINE:
        {
          ZnMapInfoLineStyle line_style;
          ZnDim line_width;
          ZnPos x_to, y_to;
          ZnMapInfoGetLine(master->map_info, insert, NULL, &line_style,
                           &line_width, &x, &y, &x_to, &y_to);
          l = Tcl_GetObjResult(interp);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(ZnMapInfoLineStyleToString(line_style), -1));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(line_width));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(y));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(x_to));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(y_to));
        }
        break;
      case ZN_E_SYMBOL:
        {
          char  symbol;
          ZnMapInfoGetSymbol(master->map_info, insert, NULL, &x, &y, &symbol);
          l = Tcl_GetObjResult(interp);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(y));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(symbol));
        }
        break;
      case ZN_E_TEXT:
        {
          char *text;
          ZnMapInfoTextStyle text_style;
          ZnMapInfoLineStyle line_style;
          ZnMapInfoGetText(master->map_info, insert, NULL, &text_style, &line_style,
                           &x, &y, &text);
          l = Tcl_GetObjResult(interp);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(y));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(ZnMapInfoTextStyleToString(text_style), -1));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(ZnMapInfoLineStyleToString(line_style), -1));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(text, -1));
        }
        break;
      case ZN_E_ARC:
        {
          ZnMapInfoLineStyle    line_style;
          ZnDim line_width, radius;
          ZnPos start, extent;
          ZnMapInfoGetArc(master->map_info, insert, NULL, &line_style, &line_width,
                          &x, &y, &radius, &start, &extent);
          l = Tcl_GetObjResult(interp);
          Tcl_ListObjAppendElement(interp, l, Tcl_NewStringObj(ZnMapInfoLineStyleToString(line_style), -1));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(line_width));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(x));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(y));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(radius));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(start));
          Tcl_ListObjAppendElement(interp, l, Tcl_NewDoubleObj(extent));
        }
        break;
      }
    }
    break;
    /*
     * remove
     */
  case ZN_MI_REMOVE:
    {
      int insert;
      if (argc != 5) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo remove type index");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (Tcl_GetIntFromObj(interp, args[4], &insert) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (insert < 0) {
        insert = 0;
      }
      if (Tcl_GetIndexFromObj(interp, args[3], e_type_strings,
                              "elementType", 0, &index2) != TCL_OK) {
        return TCL_ERROR;
      }
      switch ((enum e_types) index2) {
      case ZN_E_LINE:
        ZnMapInfoRemoveLine(master->map_info, insert);
        break;
      case ZN_E_SYMBOL:
        ZnMapInfoRemoveSymbol(master->map_info, insert);
        break;
      case ZN_E_TEXT:
        ZnMapInfoRemoveText(master->map_info, insert);
        break;
      case ZN_E_ARC:
        ZnMapInfoRemoveArc(master->map_info, insert);
        break;
      }
      UpdateMapInfoClients(master);
    }
    break;
    /*
     * scale
     */
  case ZN_MI_SCALE:
    {
      double factor;
      
      if (argc != 4) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo scale factor");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &factor) == TCL_ERROR) {
        return TCL_ERROR;
      }
      ZnMapInfoScale(master->map_info, factor);
      UpdateMapInfoClients(master);
    }
    break;
    /*
     * translate
     */
  case ZN_MI_TRANSLATE:
    {
      if (argc != 5) {
        Tcl_WrongNumArgs(interp, 1, args, "mapInfo translate xAmount yAmount");
        return TCL_ERROR;
      }
      master = LookupMapInfoMaster(interp, Tcl_GetString(args[1]));
      if (master == NULL) {
        return TCL_ERROR;
      }
      if (Tcl_GetDoubleFromObj(interp, args[3], &x) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (Tcl_GetDoubleFromObj(interp, args[4], &y) == TCL_ERROR) {
        return TCL_ERROR;
      }
      ZnMapInfoTranslate(master->map_info, x, y);
      UpdateMapInfoClients(master);
    }
    break;
  }

  return TCL_OK;
}


/*
 *----------------------------------------------------------------------
 *
 * VideomapObjCmd --
 *
 *
 *----------------------------------------------------------------------
 */
int
ZnVideomapObjCmd(ClientData     client_data,
                 Tcl_Interp     *interp,        /* Current interpreter. */
                 int            argc,           /* Number of arguments. */
                 Tcl_Obj        *CONST  args[])
{
  ZnList        ids;
  int           index;
  int           *id_array, id_num, i;
  Tcl_Obj       *l;
#ifdef PTK_800
  static char *sub_cmd_strings[] =
#else
  static CONST char *sub_cmd_strings[] =
#endif
  {
    "ids", "load", NULL
  };
  enum          sub_cmds {
    ZN_V_IDS, ZN_V_LOAD
  };
  

  if (argc < 2) {
    Tcl_WrongNumArgs(interp, 1, args, "?subCmd? filename $args?");
    return TCL_ERROR;
  }

  if (Tcl_GetIndexFromObj(interp, args[1], sub_cmd_strings,
                          "subCmd", 0, &index) != TCL_OK) {
    return TCL_ERROR;
  }

  switch((enum sub_cmds) index) {
    /*
     * ids
     */
  case ZN_V_IDS:
    {
      if (argc != 3) {
        Tcl_WrongNumArgs(interp, 1, args,"ids filename");
        return TCL_ERROR;
      }
      ids = ZnMapInfoVideomapIds(Tcl_GetString(args[2]));
      if (ids == NULL) {
        Tcl_AppendResult(interp, "unable to look at videomap file \"",
                         Tcl_GetString(args[2]), "\"", NULL);
        return TCL_ERROR;
      }
      id_array = ZnListArray(ids);
      id_num = ZnListSize(ids);
      l = Tcl_GetObjResult(interp);
      for (i = 0; i < id_num; i++) {
        Tcl_ListObjAppendElement(interp, l, Tcl_NewIntObj(id_array[i]));
      }
      ZnListFree(ids);
    }
    break;
    /*
     * load
     */
  case ZN_V_LOAD:
    {
      ZnMapInfoId          map_info;
      int insert;
      
      if (argc != 5) {
        Tcl_WrongNumArgs(interp, 1, args, "load filename index mapInfo");
        return TCL_ERROR;
      }
      if (Tcl_GetIntFromObj(interp, args[3], &insert) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (insert < 0) {
        insert = 0;
      }
      if (ZnCreateMapInfo(interp, Tcl_GetString(args[4]), &map_info) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (ZnMapInfoGetVideomap(map_info, Tcl_GetString(args[2]), insert) == TCL_ERROR) {
        Tcl_AppendResult(interp, "unable to load videomap file \"",
                         Tcl_GetString(args[2]), ":",
                         Tcl_GetString(args[3]), "\"", NULL);
        return TCL_ERROR;
      }
      ZnUpdateMapInfoClients(map_info);
    }
    break;
  }
  
  return TCL_OK;
}
