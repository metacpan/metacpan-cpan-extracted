/*
 * Tabular.c -- Implementation of Tabular item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Tabular.c,v 1.30 2005/05/10 07:59:48 lecoanet Exp $
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
#include "tkZinc.h"

#include <ctype.h>
#include <stdlib.h>


static const char rcsid[] = "$Id: Tabular.c,v 1.30 2005/05/10 07:59:48 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 **********************************************************************************
 *
 * Specific Tabular item record
 *
 **********************************************************************************
 */
typedef struct _TabularItemStruct {
  ZnItemStruct          header;

  /* Public data */
  ZnPoint               pos;
  Tk_Anchor             anchor;
  Tk_Anchor             connection_anchor;

  /* Private data */
  ZnFieldSetStruct      field_set;
} TabularItemStruct, *TabularItem;


static ZnAttrConfig     tabular_attrs[] = {
  { ZN_CONFIG_ANCHOR, "-anchor", NULL,
    Tk_Offset(TabularItemStruct, anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(TabularItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(TabularItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(TabularItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ITEM, "-connecteditem", NULL,
    Tk_Offset(TabularItemStruct, header.connected_item), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-connectionanchor", NULL,
    Tk_Offset(TabularItemStruct, connection_anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LABEL_FORMAT, "-labelformat", NULL,
    Tk_Offset(TabularItemStruct, field_set.label_format), 0,
    ZN_COORDS_FLAG|ZN_CLFC_FLAG, False },
  { ZN_CONFIG_UINT, "-numfields", NULL,
    Tk_Offset(TabularItemStruct, field_set.num_fields), 0, 0, True },
  { ZN_CONFIG_POINT, "-position", NULL,
    Tk_Offset(TabularItemStruct, pos), 0, ZN_COORDS_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(TabularItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(TabularItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(TabularItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(TabularItemStruct, header.flags), ZN_VISIBLE_BIT,
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
  ZnWInfo       *wi = item->wi;
  TabularItem   tab = (TabularItem) item;
  ZnFieldSet    field_set = &tab->field_set;
  int           num_fields;

  item->priority = 1;

  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);

  tab->anchor = TK_ANCHOR_NW;
  tab->connection_anchor = TK_ANCHOR_SW;
  tab->pos.x = tab->pos.y = 0.0;

  field_set->item = item;
  field_set->label_format = NULL;
  
  /*
   * Then try to see if some fields are needed.
   */
  if ((*argc > 0) && (Tcl_GetString((*args)[0])[0] != '-') &&
      (Tcl_GetIntFromObj(wi->interp, (*args)[0], &num_fields) != TCL_ERROR)) {
    field_set->num_fields = num_fields;
    *args += 1;
    *argc -= 1;
    ZnFIELD.InitFields(field_set);
  }
  else {
    Tcl_AppendResult(wi->interp, " number of fields expected", NULL);
    return TCL_ERROR;
  }    
  
  item->part_sensitive = 0;

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
  ZnFieldSet    fs = &((TabularItem) item)->field_set;

  ZnFIELD.CloneFields(fs);
  fs->item = item;
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
  ZnFIELD.FreeFields(&((TabularItem) item)->field_set);
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
  ZnItem        old_connected;

  old_connected = item->connected_item;
  if (ZnConfigureAttributes(item->wi, item, item, tabular_attrs,
                            argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
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
  if (ZnQueryAttribute(item->wi->interp, item, tabular_attrs, argv[0]) == TCL_ERROR) {
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
  TabularItem   tab = (TabularItem) item;
  ZnWInfo       *wi = item->wi;
  ZnFieldSet    field_set = &tab->field_set;
  ZnDim         width, height;
  
  ZnResetBBox(&item->item_bounding_box);
  if (field_set->label_format && field_set->num_fields) {
    ZnFIELD.GetLabelBBox(field_set, &width, &height);

    /*
     * The connected item support anchors, this is checked by
     * configure.
     */
    if (item->connected_item != ZN_NO_ITEM) {
      item->connected_item->class->GetAnchor(item->connected_item,
                                             tab->connection_anchor,
                                             &field_set->label_pos);
    }
    else {
      ZnPoint pos;
      pos.x = pos.y = 0;
      ZnTransformPoint(wi->current_transfo, &pos,
                          &field_set->label_pos);
    }

    ZnAnchor2Origin(&field_set->label_pos, width, height, tab->anchor,
                    &field_set->label_pos);

    /*
     * Setup the item bounding box.
     */
    item->item_bounding_box.orig = field_set->label_pos;
    item->item_bounding_box.corner.x = field_set->label_pos.x + width;
    item->item_bounding_box.corner.y = field_set->label_pos.y + height;
    /*
     * Need to slightly increase the bbox for GL thick lines
     */
#ifdef GL
    item->item_bounding_box.orig.x -= 1;
    item->item_bounding_box.orig.y -= 1;
    item->item_bounding_box.corner.x += 1;
    item->item_bounding_box.corner.y += 1;
#endif

    /*
     * Update connected items.
     */
    SET(item->flags, ZN_UPDATE_DEPENDENT_BIT);
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
  return ZnFIELD.FieldsToArea(&((TabularItem) item)->field_set, ta->area);
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
  ZnFIELD.DrawFields(&((TabularItem) item)->field_set);
}


/*
 **********************************************************************************
 *
 * Render --
 *
 **********************************************************************************
 */
static void
Render(ZnItem   item)
{
  ZnFIELD.RenderFields(&((TabularItem) item)->field_set);
}


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
  if (ISCLEAR(item->flags, ZN_SENSITIVE_BIT) ||
      !item->parent->class->IsSensitive(item->parent, ZN_NO_PART)) {
    return False;
  }
  if (item_part == ZN_NO_PART) {
    return ISSET(item->flags, ZN_SENSITIVE_BIT);
  }
  else {    
    return ZnFIELD.IsFieldSensitive(&((TabularItem) item)->field_set, item_part);
  }
}


/*
 **********************************************************************************
 *
 * Pick --
 *      We tell what our label tells.
 *
 **********************************************************************************
 */
static double
Pick(ZnItem     item,
     ZnPick     ps)
{
  int best_part;
  double dist;
  
  dist = ZnFIELD.FieldsPick(&((TabularItem) item)->field_set, ps->point, &best_part);
  /*printf("tabular %d reporting part %d, distance %lf\n",
    item->id, best_part, dist);*/
  if (dist <= 0.0) {
    dist = 0.0;
  }
  
  ps->a_part = best_part;
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
  return ZnFIELD.PostScriptFields(&((TabularItem) item)->field_set, prepass, area);
}


/*
 **********************************************************************************
 *
 * GetFieldSet --
 *
 **********************************************************************************
 */
static ZnFieldSet
GetFieldSet(ZnItem      item)
{
  return &((TabularItem) item)->field_set;
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
  ZnFieldSet    field_set = &((TabularItem) item)->field_set;
  ZnDim width, height;
  
  if (field_set->label_format) {
    ZnFIELD.GetLabelBBox(field_set, &width, &height);
    ZnOrigin2Anchor(&field_set->label_pos, width, height, anchor, p);
  }
  else {
    p->x = p->y = 0.0;
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
  ZnFieldSet    field_set = &((TabularItem) item)->field_set;
  ZnDim         width, height;
  ZnPoint       *points;
  
  if (field_set->label_format) {
    ZnFIELD.GetLabelBBox(field_set, &width, &height);
    ZnListAssertSize(ZnWorkPoints, 2);
    points = (ZnPoint *) ZnListArray(ZnWorkPoints);
    ZnTriStrip1(tristrip, points, 2, False);
    points[0] = field_set->label_pos;
    points[1].x = points[0].x + width;
    points[1].y = points[0].y + height;
  }

  return True;
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
  TabularItem   tabular = (TabularItem) item;
  
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " tabulars can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on tabulars", NULL);
      return TCL_ERROR;
    }
    tabular->pos = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    *num_pts = 1;
    *pts = &tabular->pos;
  }
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * Part --
 *      Convert a private part from/to symbolic representation.
 *
 **********************************************************************************
 */
static int
Part(ZnItem     item,
     Tcl_Obj    **part_spec,
     int        *part)
{
  char  *part_str;
  char  *end;
  
  if (*part_spec) {
    part_str = Tcl_GetString(*part_spec);
    if (strlen(part_str) == 0) {
      *part = ZN_NO_PART;
    }
    else if (isdigit(part_str[0])) {
      *part = strtol(part_str, &end, 0);
      if ((*end != 0) || (*part < 0) ||
          ((unsigned int) *part >= ((TabularItem) item)->field_set.num_fields)) {
        goto part_error;
      }
    }
    else {
    part_error:
      Tcl_AppendResult(item->wi->interp, " invalid item part specification", NULL);
      return TCL_ERROR; 
    }
  }
  else {
    if (*part >= 0) {
      *part_spec = Tcl_NewIntObj(*part);
    }
    else {
      *part_spec = Tcl_NewStringObj("", -1);
    }
  }
  return TCL_OK;  
}


/*
 **********************************************************************************
 *
 * Index --
 *      Parse a text index and return its value and aa
 *      error status (standard Tcl result).
 *
 **********************************************************************************
 */
static int
Index(ZnItem    item,
      int       field,
      Tcl_Obj   *index_spec,
      int       *index)
{
  return ZnFIELD.FieldIndex(&((TabularItem) item)->field_set, field,
                          index_spec, index);
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
  if (ZnFIELD.FieldInsertChars(&((TabularItem) item)->field_set,
                             field, index, chars)) {
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
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
  if (ZnFIELD.FieldDeleteChars(&((TabularItem) item)->field_set,
                             field, first, last)) {
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
}


/*
 **********************************************************************************
 *
 * Cursor --
 *
 **********************************************************************************
 */
static void
TabularCursor(ZnItem    item,
              int       field,
              int       index)
{
  ZnFIELD.FieldCursor(&((TabularItem) item)->field_set, field, index);
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
          int           max_chars)
{
  return ZnFIELD.FieldSelection(&((TabularItem) item)->field_set, field,
                              offset, chars, max_chars);
}


/*
 **********************************************************************************
 *
 * Exported functions structs --
 *
 **********************************************************************************
 */
static ZnItemClassStruct TABULAR_ITEM_CLASS = {
  "tabular",
  sizeof(TabularItemStruct),
  tabular_attrs,
  0,
  ZN_CLASS_HAS_ANCHORS|ZN_CLASS_ONE_COORD, /* flags */
  Tk_Offset(TabularItemStruct, pos),
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  GetFieldSet,
  GetAnchor,
  GetClipVertices,
  NULL,                 /* GetContours */
  Coords,
  InsertChars,
  DeleteChars,
  TabularCursor,
  Index,
  Part,
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

ZnItemClassId ZnTabular = (ZnItemClassId) &TABULAR_ITEM_CLASS;
