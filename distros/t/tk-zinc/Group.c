/*
 * Group.c -- Implementation of Group item.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Wed Jun 23 10:09:20 1999
 *
 * $Id: Group.c,v 1.57 2005/10/05 14:28:05 lecoanet Exp $
 */

/*
 *  Copyright (c) 1999 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Types.h"
#include "WidgetInfo.h"
#include "Item.h"
#include "Group.h"
#include "Geo.h"
#include "tkZinc.h"

#ifndef _WIN32
#include <X11/extensions/shape.h>
#endif


static const char rcsid[] = "$Id: Group.c,v 1.57 2005/10/05 14:28:05 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 * Group item special record.
 */
typedef struct _GroupItemStruct {
  ZnItemStruct          header;

  /* Public data */
  ZnItem                clip;
  unsigned char         alpha;

  /* Private data */
  ZnItem                head;           /* Doubly linked list of all items.     */
  ZnItem                tail;
  ZnList                dependents;     /* List of dependent items.             */
#ifdef ATC
  /* Overlap manager variables.
   * These variables are valid *only* if the overlap
   * manager is active. */
  ZnBool                call_om;        /* Tell if there is a need to call the  */
                                        /* overlap manager.                     */
#endif
} GroupItemStruct, *GroupItem;


#define ATOMIC_BIT      (1<<ZN_PRIVATE_FLAGS_OFFSET)


/*
 **********************************************************************************
 *
 * Specific Group item record
 *
 **********************************************************************************
 */
static ZnAttrConfig     group_attrs[] = {
  { ZN_CONFIG_ALPHA, "-alpha", NULL,
    Tk_Offset(GroupItemStruct, alpha), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-atomic", NULL,
    Tk_Offset(GroupItemStruct, header.flags), ATOMIC_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_ITEM, "-clip", NULL,
    Tk_Offset(GroupItemStruct, clip), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(GroupItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(GroupItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_TRANSFO_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(GroupItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_TRANSFO_FLAG, False },
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(GroupItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(GroupItemStruct, header.flags), ZN_SENSITIVE_BIT,
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(GroupItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(GroupItemStruct, header.flags), ZN_VISIBLE_BIT,
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
  GroupItem     group = (GroupItem) item;
  
  group->head = ZN_NO_ITEM;
  group->tail = ZN_NO_ITEM;
  group->clip = ZN_NO_ITEM;
  group->alpha = 100;
  group->dependents = NULL;
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  CLEAR(item->flags, ATOMIC_BIT);
  item->priority = 1;
#ifdef ATC
  group->call_om = False;
#endif
  
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
  GroupItem     group = (GroupItem) item;  
  ZnList        dependents;
  ZnItem        connected, current_item, new_item;
  ZnItem        *items;
  Tcl_HashTable mapping;
  Tcl_HashEntry *entry;
  int           new, num_items, i;

  if (item == item->wi->top_group) {
    /* Do not try to clone the top group */
    return;
  }

  current_item = group->tail;
  group->head = group->tail = ZN_NO_ITEM;
#ifdef ATC
  group->call_om = False;
#endif
  dependents = group->dependents;
  if (dependents) {
    Tcl_InitHashTable(&mapping, TCL_ONE_WORD_KEYS);
  }

  /*
   * First clone all the children, and build a mapping
   * table if there is some attachments to relink.
   */
  while (current_item != ZN_NO_ITEM) {
    connected = current_item->connected_item;
    new_item = ZnITEM.CloneItem(current_item);
    new_item->connected_item = connected;
    ZnITEM.InsertItem(new_item, item, ZN_NO_ITEM, True);
    
    if (dependents) {
      entry = Tcl_CreateHashEntry(&mapping, (char *) current_item, &new);
      Tcl_SetHashValue(entry, (ClientData) new_item);
    }
    if (current_item == group->clip) {
      group->clip = new_item;
    }
    current_item = current_item->previous;
  }
  
  /*
   * Then rebuild the dependency list with
   * the new items.
   */
  if (dependents) {
    /*printf("rebuilding dependents\n");*/
    group->dependents = NULL;
    items = (ZnItem *) ZnListArray(dependents);
    num_items = ZnListSize(dependents);
    for (i = 0; i < num_items; i++, items++) {
      entry = Tcl_FindHashEntry(&mapping, (char *) *items);
      if (entry == NULL) {
        ZnWarning("Can't find item correspondance in Group Clone\n");
        abort();
      }
      else {
        current_item = (ZnItem) Tcl_GetHashValue(entry);
      }
      entry = Tcl_FindHashEntry(&mapping, (char *) current_item->connected_item);
      if (entry == NULL) {
        ZnWarning("Can't found item correspondance in Group Clone\n");
        abort();
      }
      else {
        /*printf("item %d correspond to ", current_item->connected_item->id);*/
        current_item->connected_item = (ZnItem) Tcl_GetHashValue(entry);
        /*printf("%d\n", current_item->connected_item->id);*/
        ZnInsertDependentItem(current_item);
      }
    }
    Tcl_DeleteHashTable(&mapping);
  }
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
  GroupItem     group = (GroupItem) item;
  ZnItem        current_item, next_item;

  current_item = group->head;
  while (current_item != ZN_NO_ITEM) {
    next_item = current_item->next;
    ZnITEM.DestroyItem(current_item);
    current_item = next_item;
  }
  if (group->dependents) {
    ZnListFree(group->dependents);
  }
}


/*
 **********************************************************************************
 *
 * SetXShape --
 *
 **********************************************************************************
 */
#if defined(SHAPE) && !defined(_WIN32)
static void
SetXShape(ZnItem        grp)
{
  ZnWInfo       *wi = grp->wi;
  ZnItem        clip = ((GroupItem) grp)->clip;
  unsigned int  i, j, num_pts, max_num_pts;
  ZnPos         min_x, min_y, max_x, max_y;
  ZnTriStrip    tristrip;
  ZnPoint       *p;
  ZnBool        simple;
  ZnDim         width, height;
  XPoint        xpts[3], *xp2, *xpts2;
  TkRegion      reg, reg_op, reg_to;
  
  if (ISCLEAR(wi->flags, ZN_HAS_X_SHAPE)) {
    return;
  }

  if ((clip == ZN_NO_ITEM) || !wi->reshape) {
    /*
     * Reset both clip just to be sure (the application can have
     * changed wi->full_reshape while resetting wi->reshape).
     */
    XShapeCombineMask(wi->dpy, Tk_WindowId(wi->win), ShapeBounding,
                      0, 0, None, ShapeSet);
    XShapeCombineMask(wi->dpy, wi->real_top, ShapeBounding,
                      0, 0, None, ShapeSet);
  }
  else {
    /*
     * Get the clip shape.
     */
    tristrip.num_strips = 0;
    simple = clip->class->GetClipVertices(clip, &tristrip);
    if (simple || (tristrip.num_strips == 0)) {
      /*
       * Nothing to do: after normalisation the rectangular shape will
       * fit exactly the window. We may test here if a shape is currently
       * active and reset the mask only in this case (need a flag in wi).
       */
      XShapeCombineMask(wi->dpy, Tk_WindowId(wi->win), ShapeBounding,
                        0, 0, None, ShapeSet);
      XShapeCombineMask(wi->dpy, wi->real_top, ShapeBounding,
                        0, 0, None, ShapeSet);
    }
    else {
      /*
       * First make the vertices start at zero.
       * In case of a fan we benefit from the fact that
       * ALL the contour vertices are included in
       * the tristrip, so we dont need to consider the
       * center (arc in pie slice mode).
       */
      max_x = min_x = tristrip.strips[0].points[0].x;
      max_y = min_y = tristrip.strips[0].points[0].y;
      max_num_pts = tristrip.strips[0].num_points;
      for (j = 0; j < tristrip.num_strips; j++) {
        p = tristrip.strips[j].points;
        num_pts = tristrip.strips[j].num_points;
        if (num_pts > max_num_pts) {
          max_num_pts = num_pts;
        }
        for (i = 0; i < num_pts; p++, i++) {
          if (p->x < min_x) {
            min_x = p->x;
          }
          if (p->y < min_y) {
            min_y = p->y;
          }
          if (p->x > max_x) {
            max_x = p->x;
          }
          if (p->y > max_y) {
            max_y = p->y;
          }
        }
      }
      max_x -= min_x;
      max_y -= min_y;
      XShapeCombineMask(wi->dpy, wi->full_reshape?Tk_WindowId(wi->win):wi->real_top,
                        ShapeBounding, 0, 0, None, ShapeSet);
      reg = TkCreateRegion();
      
      /*
       * Now normalize the shape and map it to the window size,
       * then Translate it in a region and apply this region to
       * the window.
       */
      width = wi->width;
      height = wi->height;
      for (j = 0; j < tristrip.num_strips; j++) {
        p = tristrip.strips[j].points;
        num_pts = tristrip.strips[j].num_points;

        /*
         * In case of a fan we benefit from the fact that
         * ALL the contour vertices are included in
         * the tristrip, so we can use the corresponding
         * polygon instead of going through all the triangles.
         */
        if (tristrip.strips[j].fan) {
          /* Skip the center */
          p++;
          num_pts--;
          xp2 = xpts2 = ZnMalloc(num_pts*sizeof(XPoint));
          for (i = 0 ; i < num_pts; i++, p++, xp2++) {
            xp2->x = (short) ((p->x - min_x) * width / max_x);
            xp2->y = (short) ((p->y - min_y) * height / max_y);
          }
          reg_op = ZnPolygonRegion(xpts2, num_pts, EvenOddRule);
          reg_to = TkCreateRegion();
          ZnUnionRegion(reg, reg_op, reg_to);
          TkDestroyRegion(reg);
          TkDestroyRegion(reg_op);
          reg = reg_to;
          ZnFree(xpts2);
        }
        else {
          xpts[0].x = (short) ((p->x - min_x) * width / max_x);
          xpts[0].y = (short) ((p->y - min_y) * height / max_y);
          p++;
          xpts[1].x = (short) ((p->x - min_x) * width / max_x);
          xpts[1].y = (short) ((p->y - min_y) * height / max_y);
          p++;
          for (i = 2 ; i < num_pts; i++, p++) {
            xpts[2].x = (short) ((p->x - min_x) * width / max_x);
            xpts[2].y = (short) ((p->y - min_y) * height / max_y);
            reg_op = ZnPolygonRegion(xpts, 3, EvenOddRule);
            reg_to = TkCreateRegion();
            ZnUnionRegion(reg, reg_op, reg_to);
            TkDestroyRegion(reg);
            TkDestroyRegion(reg_op);
            reg = reg_to;
            xpts[0] = xpts[1];
            xpts[1] = xpts[2];
          }
        }
      }
      XShapeCombineRegion(wi->dpy, wi->full_reshape?wi->real_top:Tk_WindowId(wi->win),
                          ShapeBounding, 0, 0, (Region) reg, ShapeSet);
      TkDestroyRegion(reg);
    }
  }
}
#else
static void
SetXShape(ZnItem        grp)
{
}
#endif


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
  GroupItem     group = (GroupItem) item;
  ZnWInfo       *wi = item->wi;
  
  if (ZnConfigureAttributes(wi, item, item, group_attrs, argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
  }

  /*
   * If the clip item changed, check if it is a legal
   * item type that is inside this group.
   */
  if (ISSET(*flags, ZN_ITEM_FLAG)) {
    if (group->clip &&
        (!group->clip->class->GetClipVertices || (group->clip->parent != item))) {
      group->clip = ZN_NO_ITEM;
      Tcl_AppendResult(wi->interp,
                       " clip item must be a child of the group", NULL);
      return TCL_ERROR;
    }
    if (!group->clip && (item == wi->top_group)) {
      SetXShape(item);
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
  if (ZnQueryAttribute(item->wi->interp, item, group_attrs, argv[0]) == TCL_ERROR) {
    return TCL_ERROR;
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * PushClip --
 *      Save the current clip shape and current clipbox if needed.
 *      Intersect the previous shape and the local to obtain the
 *      new current shape. Use this shape to compute the current
 *      clipbox and if set_gc is True compute the current region.
 *
 **********************************************************************************
 */
static void
PushClip(GroupItem      group,
         ZnBool         set_gc)
{
  ZnWInfo       *wi = ((ZnItem) group)->wi;
  ZnTriStrip    tristrip;
  ZnBool        simple;

  if ((group->clip != ZN_NO_ITEM) &&
      ((((ZnItem) group) != wi->top_group)
#if defined(SHAPE) && ! defined (_WIN32)
       || !wi->reshape
#endif
       )) {
    simple = group->clip->class->GetClipVertices(group->clip, &tristrip);
    /*printf("Group: PushClip group %d\n", ((ZnItem) group)->id);*/
    if (tristrip.num_strips) {
      ZnPushClip(wi, &tristrip, simple, set_gc);
    }
  }
}


/*
 **********************************************************************************
 *
 * PopClip --
 *      Re-install the previous clip shape if any (stack can be empty).
 *
 **********************************************************************************
 */
static void
PopClip(GroupItem       group,
        ZnBool          set_gc)
{
  ZnWInfo       *wi = ((ZnItem) group)->wi;

  if ((group->clip != ZN_NO_ITEM) &&
      ((((ZnItem) group) != wi->top_group)
#if defined(SHAPE) && !defined(_WIN32)
       || !wi->reshape
#endif
       )) {
    /*printf("Group: PopClip group %d\n", ((ZnItem) group)->id);*/
    ZnPopClip(wi, set_gc);
  }
}


/*
 **********************************************************************************
 *
 * PushTransform --
 *      Save the current transform then concatenate the item transform to
 *      form the new current transform.
 *
 **********************************************************************************
 */
static void
PushTransform(ZnItem    item)
{
  ZnPoint *pos;
  
  pos = NULL;
  if (item->class->pos_offset >= 0) {
    pos = (ZnPoint *) (((char *) item) + item->class->pos_offset);
    if (pos->x == 0 && pos->y == 0) {
      pos = NULL;
    }
  }
  if (!item->transfo &&
      !pos &&
      ISSET(item->flags, ZN_COMPOSE_SCALE_BIT) &&
      ISSET(item->flags, ZN_COMPOSE_ROTATION_BIT)) {
    return;
  }

  ZnPushTransform(item->wi, item->transfo, pos,
                  ISSET(item->flags, ZN_COMPOSE_SCALE_BIT),
                  ISSET(item->flags, ZN_COMPOSE_ROTATION_BIT));
  /*printf("Pushing transfo for item: %d\n;", item->id);
    ZnPrintTransfo(wi->current_transfo);*/
}


/*
 **********************************************************************************
 *
 * PopTransform --
 *      Restore the previously saved transform from the stack.
 *
 **********************************************************************************
 */
static void
PopTransform(ZnItem     item)
{
  ZnPoint *pos;
  
  pos = NULL;
  if (item->class->pos_offset >= 0) {
    pos = (ZnPoint *) (((char *) item) + item->class->pos_offset);
    if (pos->x == 0 && pos->y == 0) {
      pos = NULL;
    }
  }
  if (!item->transfo &&
      !pos &&
      ISSET(item->flags, ZN_COMPOSE_SCALE_BIT) &&
      ISSET(item->flags, ZN_COMPOSE_ROTATION_BIT)) {
    return;
  }

  ZnPopTransform(item->wi);
  /*printf("Popping transfo for item: %d\n", item->id);
  ZnPrintTransfo(wi->current_transfo);*/
}


/*
 **********************************************************************************
 *
 * ComputeCoordinates --
 *      Compute the geometrical elements of a group. First of all save the current
 *      transform and combine it with the item transform. Then call the item
 *      ComputeCoordinates method.
 *      For regular child items (not groups) some of the code of the item
 *      itself is factored out in CallRegularCC.
 *
 **********************************************************************************
 */
static void
CallRegularCC(ZnItem    item)
{
  ZnWInfo       *wi = item->wi;
  /*ZnBBox      *clip_box;*/
  
  /*
   * Do some generic pre-work in behalf of the (regular) children.
   */
  if (ISSET(item->flags, ZN_VISIBLE_BIT)) {
    ZnDamage(wi, &item->item_bounding_box);
  }
  PushTransform(item);
  
  /*printf("calling cc on regular item %d\n", item->id);*/
  /*ZnPrintTransfo(wi->current_transfo);*/
  item->class->ComputeCoordinates(item, False);
  /*
   * If a current clipbox exists adjust the item
   * bounding box accordingly. When computing coordinates
   * the damaged area is not pushed onto the clipstack,
   * the following predicate is thus valid for testing
   * a clipbox. 
   */
  /* Tue Nov 14 15:21:05 2000 Suppressed to have a real
     bbox to align tiles (i.e if an object is larger than
     its enclosing clipping, the bbox is equal to the clip
     area and the tiling will not move with the object until
     it partially uncovered the clip area.
     Have to watch any possible breakage.

    if (ZnCurrentClip(wi, NULL, &clip_box, NULL)) {
    ZnBBox inter;
    
    ZnIntersectBBox(&item->item_bounding_box, clip_box, &inter);
    item->item_bounding_box = inter;
  }*/
  /*
   * Do some generic post-work in behalf of the (regular) children.
   */
#ifdef GL
#ifdef GL_LIST
  /*
   * Remove the item display list so that it will be recreated
   * to reflect the changes.
   */
  if (item->gl_list) {
    glDeleteLists(item->gl_list, 1);
    item->gl_list = 0;
  }
#endif
#endif
  if (ISSET(item->inv_flags, ZN_REPICK_FLAG)) {
    SET(wi->flags, ZN_INTERNAL_NEED_REPICK);
  }
  if (ISSET(item->inv_flags, ZN_COORDS_FLAG) &&
      (ISSET(item->flags, ZN_SENSITIVE_BIT) ||
       ISSET(item->flags, ZN_VISIBLE_BIT))) {
    SET(wi->flags, ZN_INTERNAL_NEED_REPICK);
  }
  /*
   * Damage if the item is visible or if it is
   * a group clipper.
   */
  if (ISSET(item->flags, ZN_VISIBLE_BIT) ||
      (item == ((GroupItem) item->parent)->clip)) {
    ZnDamage(wi, &item->item_bounding_box);
  }
  PopTransform(item);
  item->inv_flags = 0;
  /*printf("Done cc on regular item %d\n", item->id);*/
}

static void
ComputeCoordinates(ZnItem       item,
                   ZnBool       force)
{
  GroupItem     group = (GroupItem) item;
  ZnItem        current_item;
  ZnItem        *deps;
  int           num_deps, i;
  ZnBBox        *clip_box;

  PushTransform(item);
  //printf("Entering Group: %d\n", item->id);
  //ZnPrintTransfo(item->wi->current_transfo);    
  //printf("\n");

  force |= ISSET(item->inv_flags, ZN_TRANSFO_FLAG);

  /*
   * If the clip item changed or there is no clip anymore
   * force an update.
   */
  force |= ISSET(item->inv_flags, ZN_ITEM_FLAG);

  /*
   * Clip shape is computed in the group's local
   * coordinates.
   */
  if (group->clip != ZN_NO_ITEM) {
    /*
     * Update the geometry of the clip item if needed.
     * Its bounding box will be clipped by the current
     * clipbox (i.e the clipbox of the group's parent).
     */
    if (force ||
        ISSET(group->clip->inv_flags, ZN_COORDS_FLAG) ||
        ISSET(group->clip->inv_flags, ZN_TRANSFO_FLAG)) {
      /*printf("calling cc on clip item %d for group %d\n",
        group->clip->id, item->id);*/
      CallRegularCC(group->clip);
      if (item == item->wi->top_group) {
        SetXShape(item);
      }
      /*
       * If the clip item has changed we need to compute
       * new clipped bounding boxes for all the children.
       */
      force = True;
    }
  }
  
  PushClip(group, False);
  
  for (current_item = group->head; current_item != ZN_NO_ITEM;
       current_item = current_item->next) {
    /*
     * Skip the clip item, it has been already updated.
     * Skip as well items with a dependency, they will
     * be updated later.
     */
    //printf("Trying to update: %d\n", current_item->id);
    if ((current_item == group->clip) ||
        (current_item->connected_item != ZN_NO_ITEM)) {
      continue;
    }
    if (force ||
        ISSET(current_item->inv_flags, ZN_COORDS_FLAG) ||
        ISSET(current_item->inv_flags, ZN_TRANSFO_FLAG)) {
      if (current_item->class != ZnGroup) {
        //printf("Updating item %d\n", current_item->id);
        CallRegularCC(current_item);
      }
      else {
        //printf("Updating group %d\n", current_item->id);
        current_item->class->ComputeCoordinates(current_item, force);
      }
    }
  }
  /*
   * Update coordinates and bounding boxes following
   * a possible change in connected items. Only regular
   * items can be concerned.
   */
  if (group->dependents) {
    num_deps = ZnListSize(group->dependents);
    deps = (ZnItem *) ZnListArray(group->dependents);
    for (i = 0; i < num_deps; i++) {
      current_item = deps[i];
      if (force ||
          ISSET(current_item->inv_flags, ZN_COORDS_FLAG) ||
          ISSET(current_item->inv_flags, ZN_TRANSFO_FLAG) ||
          ISSET(current_item->connected_item->flags, ZN_UPDATE_DEPENDENT_BIT)) {        
        //printf("Updating dependent: %d\n", current_item->id);       
        CallRegularCC(current_item);
      }
    }
    /*
     * Now, we must reset the update_dependent flag
     */
    for (i = 0; i < num_deps; i++) {
      CLEAR(deps[i]->connected_item->flags, ZN_UPDATE_DEPENDENT_BIT);
    }
    /*printf("... done\n");*/
  }
  /*
   * Compute the bounding box.
   */
  ZnResetBBox(&item->item_bounding_box);
  current_item = group->head;
  while (current_item != ZN_NO_ITEM) {
    ZnAddBBoxToBBox(&item->item_bounding_box, &current_item->item_bounding_box);
    current_item = current_item->next;    
  }
  /*
   * Limit the group actual bounding box to
   * the clip shape boundary.
   */
  if (group->clip) {
    clip_box = &group->clip->item_bounding_box;
    ZnIntersectBBox(&item->item_bounding_box, clip_box, &item->item_bounding_box);
  }
  item->inv_flags = 0;

  PopClip(group, False);
  PopTransform(item);

  //printf("Leaving Group: %d\n", item->id);
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
  GroupItem     group = (GroupItem) item;
  ZnItem        current_item;
  ZnBBox        enclosing, inter;
  int           result = -1;
  ZnBool        outside, inside;
  ZnBool        atomic, report, empty = True;
  

  PushTransform(item);
  report = ta->report;

  /*
   * Is this group the target group ?
   */
  if ((ta->in_group != ZN_NO_ITEM) && (ta->in_group != item)) {
    /* No, try the subgroups. */
    for (current_item = group->head;
         current_item != ZN_NO_ITEM;
         current_item = current_item->next) {
      if (current_item->class != ZnGroup) {
        continue;
      }
      result = current_item->class->ToArea(current_item, ta);
      if (ta->in_group == ZN_NO_ITEM) {
        /* The target group has been found, return its result. */
        goto out;
      }
    }
    /* No group found in this subtree. */
    goto out;
  }

  /*
   * At this point we are either in the target group
   * or one of its sub-groups. If in the target group,
   * erase the target in the call struct to remember
   * the fact.
   */
  if (ta->in_group == item) {
    /*
     * We are in the target group, mark the fact and bypass the group
     * atomicity.
     */
    ta->in_group = ZN_NO_ITEM;
    atomic = False;
  }
  else {
    /*
     * We are below the start group, If this group is ATOMIC,
     * ask the child groups to report instead of adding their
     * children to the result.
     */
    atomic = ISSET(item->flags, ATOMIC_BIT) && !ta->override_atomic;
    ta->report |= atomic;
  }

  enclosing.orig.x = ta->area->orig.x - 1;
  enclosing.orig.y = ta->area->orig.y - 1;
  enclosing.corner.x = ta->area->corner.x + 1;
  enclosing.corner.y = ta->area->corner.y + 1;
  outside = inside = True;
  /*
   * Process each item and proceed with subtrees if
   * asked for by the recursive flag.
   */
  /*  printf("searching in group %d\n", item?item->id:0);*/
  for (current_item = group->head;
       current_item != ZN_NO_ITEM;
       current_item = current_item->next) {
    if (ISCLEAR(current_item->flags, ZN_VISIBLE_BIT) &&
        ISCLEAR(current_item->flags, ZN_SENSITIVE_BIT)) {
      continue;
    }
    /*printf("visible&sensitive %d\n", current_item?current_item->id:0);*/
    ZnIntersectBBox(&enclosing, &current_item->item_bounding_box, &inter);
    if (ZnIsEmptyBBox(&inter)) {
      continue;
    }
    /*printf("bbox test passed %d\n", current_item?current_item->id:0);*/
    if ((current_item->class != ZnGroup) || atomic || ta->recursive || ISSET(current_item->flags, ATOMIC_BIT)) {
      if (current_item->class != ZnGroup) {
        /*printf("testing %d\n", current_item?current_item->id:0);*/
        PushTransform(current_item);
        result = current_item->class->ToArea(current_item, ta);
        PopTransform(current_item);
      }
      else {
        result = current_item->class->ToArea(current_item, ta);
      }
      outside &= (result == -1);
      inside &= (result == 1);
      empty = False;

      /*
       * If this group is ATOMIC, it must report itself as matching
       * if a/ the request is 'enclosed' and all the children are
       * enclosed or b/ the request is 'overlapping' and at least one
       * child overlaps (or is enclosed).
       * So here we can do early tests to shortcut the search when
       * the most stringent conditions are met.
       */
      if (atomic) {
        if (!ta->enclosed && (result >= 0)) {
          result = 0;
          goto out;
        } else if (ta->enclosed && (result == 0)) {
          goto out;
        }
      }
      if (!ta->report && (result >= ta->enclosed)) {
        /*printf("Doing %d\n", current_item?current_item->id:0);*/
        ZnDoItem(item->wi->interp, current_item, ZN_NO_PART, ta->tag_uid);
      }
    }
  }

  /*
   * If there are no items or only sub-groups in this group and
   * the search is not recursive we must report outside.
   */
  if (empty) {
    result = -1;    
  }
  else {
    if (atomic) {
      result = outside ? -1 : 1;
    }
    else if (ta->report) { /* Need to report matching children to ancestor */
      if (outside && inside) {
        result = 0;
      }
      else {
        result = outside ? -1 : 1;
      }
    }
    else {
      result = -1;
    }
  }

 out:
  ta->report = report;
  PopTransform(item);
  return result;
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
  GroupItem     group = (GroupItem) item;
  ZnWInfo       *wi = item->wi;
  ZnItem        current_item;
  ZnBBox        bbox, old_damaged_area, *clip_box;
  
  PushTransform(item);
  PushClip(group, True);
  if (group->clip != ZN_NO_ITEM) {
    old_damaged_area = wi->damaged_area;
    if (ZnCurrentClip(wi, NULL, &clip_box, NULL)) {
      ZnIntersectBBox(&wi->damaged_area, clip_box, &bbox);
      wi->damaged_area = bbox;
    }
  }
  
  current_item = group->tail;
  while (current_item != ZN_NO_ITEM) {
    if (ISSET(current_item->flags, ZN_VISIBLE_BIT)) {
      ZnIntersectBBox(&wi->damaged_area, &current_item->item_bounding_box, &bbox);
      if (!ZnIsEmptyBBox(&bbox)) {
        if (current_item->class != ZnGroup) {
          PushTransform(current_item);
        }
        current_item->class->Draw(current_item);
        if (wi->draw_bboxes) {
          XGCValues     values;
          values.foreground = ZnGetGradientPixel(wi->bbox_color, 0.0);
          values.fill_style = FillSolid;
          values.line_width = 1;
          values.line_style = (current_item->class==ZnGroup)?LineOnOffDash:LineSolid;
          XChangeGC(wi->dpy, wi->gc, GCForeground|GCLineStyle|GCLineWidth|GCFillStyle,
                    &values);
          XDrawRectangle(wi->dpy, wi->draw_buffer, wi->gc,
                         (int) current_item->item_bounding_box.orig.x,
                         (int) current_item->item_bounding_box.orig.y,
                         (unsigned int) (current_item->item_bounding_box.corner.x -
                                         current_item->item_bounding_box.orig.x),
                         (unsigned int) (current_item->item_bounding_box.corner.y -
                                         current_item->item_bounding_box.orig.y));
        }
        if (current_item->class != ZnGroup) {
          PopTransform(current_item);
        }
      }
    }
    current_item = current_item->previous;
  }

  if (group->clip != ZN_NO_ITEM) {
    wi->damaged_area = old_damaged_area;
  }
  PopClip(group, True);
  PopTransform(item);
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
  GroupItem     group = (GroupItem) item;
  ZnItem        current_item;
  ZnWInfo       *wi = item->wi;
#ifdef GL_DAMAGE
  ZnBBox        *clip_box;
  ZnBBox        bbox, old_damaged_area;
#endif
  unsigned char save_alpha = wi->alpha;
  unsigned char save_alpha2;

  if (ISSET(item->flags, ZN_COMPOSE_ALPHA_BIT)) {
    wi->alpha = wi->alpha * group->alpha / 100;
  }
  else {
    wi->alpha = group->alpha;
  }
  save_alpha2 = wi->alpha;

  PushTransform(item);
  PushClip(group, True);
#ifdef GL_DAMAGE
  if (ISCLEAR(wi->flags, ZN_CONFIGURE_EVENT) && (group->clip != ZN_NO_ITEM)) {
    old_damaged_area = wi->damaged_area;
    if (ZnCurrentClip(wi, NULL, &clip_box, NULL)) {
      ZnIntersectBBox(&wi->damaged_area, clip_box, &bbox);
      wi->damaged_area = bbox;
    }
  }
#endif
  
  current_item = group->tail;
  while (current_item != ZN_NO_ITEM) {
    if (ISSET(current_item->flags, ZN_VISIBLE_BIT)) {
#ifdef GL_DAMAGE
      ZnIntersectBBox(&wi->damaged_area, &current_item->item_bounding_box, &bbox);
      if (!ZnIsEmptyBBox(&bbox) || ISSET(wi->flags, ZN_CONFIGURE_EVENT)) {
#endif
        if (current_item->class != ZnGroup) {
          PushTransform(current_item);
          if (ISCLEAR(current_item->flags, ZN_COMPOSE_ALPHA_BIT)) {
            wi->alpha = 100;
          }
        }
        current_item->class->Render(current_item);
        if (current_item->class != ZnGroup) {
          PopTransform(current_item);
          wi->alpha = save_alpha2;
        }
#ifdef GL_DAMAGE
      }
#endif
    }
    current_item = current_item->previous;
  }

#ifdef GL_DAMAGE
  if (ISCLEAR(wi->flags, ZN_CONFIGURE_EVENT) && (group->clip != ZN_NO_ITEM)) {
    wi->damaged_area = old_damaged_area;
  }
#endif
  
  PopClip(group, True);
  PopTransform(item);

  wi->alpha = save_alpha;
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
  ZnBool        sensitive = ISSET(item->flags, ZN_SENSITIVE_BIT);
  ZnItem        parent = item->parent;
  
  while (sensitive && (parent != ZN_NO_ITEM)) {
    sensitive &= ISSET(parent->flags, ZN_SENSITIVE_BIT);
    parent = parent->parent;
  }
  return sensitive;
}


/*
 **********************************************************************************
 *
 * Pick --
 *      Given a point an an aperture, find the topmost group item/part
 *      that is (a) within the pick_aperture
 *              (b) the top most
 *              (c) has either its sensibility or its visibility set.
 *
 * Results:
 *      The return value is the distance of the picked item/part if one
 *      has been found or a really big distance if not. a_item and a_part
 *      are set to point the picked item/part or to ZN_NO_ITEM/ZN_NO_PART.
 *      If the group is ATOMIC, a_item points the group instead of the
 *      actual item.
 *
 * Side effects:
 *      None.
 *
 **********************************************************************************
 */
static double
Pick(ZnItem     item,
     ZnPick     ps)
{
  GroupItem     group = (GroupItem) item;
  ZnItem        p_item=ZN_NO_ITEM, current_item;
  ZnWInfo       *wi = item->wi;
  int           p_part=0, aperture = ps->aperture;
  double        dist, best = 1e10;
  ZnBBox        bbox, inter, *clip_box;
  ZnPoint       *p = ps->point;
  ZnBool        atomic;
  TkRegion      reg;

  ps->a_item= ZN_NO_ITEM;
  ps->a_part = ZN_NO_PART;

  if (group->head == ZN_NO_ITEM) {
    return best;
  }
  
  PushTransform(item);
  PushClip(group, False);
  
  /*
   * Is this group the target group ?
   */
  if ((ps->in_group != ZN_NO_ITEM) && (ps->in_group != item)) {
    /* No, try the subgroups. */
    for (current_item = group->head;
         current_item != ZN_NO_ITEM;
         current_item = current_item->next) {
      if (current_item->class != ZnGroup) {
        continue;
      }
      best = current_item->class->Pick(current_item, ps);
      if (ps->in_group == ZN_NO_ITEM) {
        /* The target group has been found, return its result. */
        goto out;
      }
    }
    /* No group found in this subtree. */
    goto out; 
  }

  /*
   * At this point we are either in the target group
   * or one of its sub-groups. If in the target group,
   * erase the target in the call struct to remember
   * the fact.
   */
  if (ps->in_group == item) {
    ps->in_group = ZN_NO_ITEM;
  }

  bbox.orig.x = p->x - aperture;
  bbox.orig.y = p->y - aperture;
  bbox.corner.x = p->x + (aperture?aperture:1);
  bbox.corner.y = p->y + (aperture?aperture:1);

  if (ZnCurrentClip(wi, &reg, &clip_box, NULL)) {
    ZnIntersectBBox(&bbox, clip_box, &inter);
    if (ZnIsEmptyBBox(&inter)) {
      goto out;
    }
    if (reg && !ZnPointInRegion(reg, (int) p->x, (int) p->y)) {
      goto out;
    }
  }

  current_item = (ps->start_item == ZN_NO_ITEM) ? group->head : ps->start_item;
  atomic = ISSET(item->flags, ATOMIC_BIT) && !ps->override_atomic;

  for ( ; current_item != ZN_NO_ITEM; current_item = current_item->next) {
    /*
     * Sensitive item must be reported even if they are invisible.
     * It is legal to fire bindings on invisible sensitive items.
     * This is _not_ a bug do _not_ modify the test below.
     */
    if (ISCLEAR(current_item->flags, ZN_SENSITIVE_BIT) &&
        ISCLEAR(current_item->flags, ZN_VISIBLE_BIT)) {
      continue;
    }
    ZnIntersectBBox(&bbox, &current_item->item_bounding_box, &inter);
    if (ZnIsEmptyBBox(&inter)) {
      continue;
    }
    if (current_item->class != ZnGroup) {
      PushTransform(current_item);
      p_item = ps->a_item;
      p_part = ps->a_part;
      ps->a_item = current_item;
      ps->a_part = ZN_NO_PART;
      dist = current_item->class->Pick(current_item, ps);
      dist -= aperture;
      PopTransform(current_item);
    }
    else if (!atomic && !ps->recursive) {
      continue;
    }
    else {
      dist = current_item->class->Pick(current_item, ps);
    }
    if (dist < 0.0) {
      dist = 0.0;
    }
    if (dist >= best) {
      /* Not a good one, restore the previous best and try again. */
      ps->a_item = p_item;
      ps->a_part = p_part;
      continue;
    }
    if (atomic) {
      /* If ATOMIC, this group is the item to be reported. */
      ps->a_item = item;
      ps->a_part = ZN_NO_PART;
    }

    best = dist;
    /*printf("found %d:%d, at %g\n", (ps->a_item)->id, ps->a_part, dist);*/
    if (dist == 0.0) {
      /* No need to look further, the item found is the topmost
       * closest. */
      break;
    }
  }

 out:
  PopClip(group, False);
  PopTransform(item);
  
  return best;
}


/*
 **********************************************************************************
 *
 * Coords --
 *      Return or edit the group translation (can be also interpreted as the
 *      position of the group origin in the group's parent).
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
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp,
                     " can't add or remove vertices in groups", NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on groups", NULL);
      return TCL_ERROR;
    }
    if (!item->transfo && ((*pts)[0].x == 0.0) && ((*pts)[0].y == 0.0)) {
      return TCL_OK;
    }
    if (!item->transfo) {
      item->transfo = ZnTransfoNew();
    }
    ZnTranslate(item->transfo, (*pts)[0].x, (*pts)[0].y, True);
    ZnITEM.Invalidate(item, ZN_TRANSFO_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    ZnPoint     *p;
    
    ZnListAssertSize(ZnWorkPoints, 1);
    p = (ZnPoint *) ZnListArray(ZnWorkPoints);
    ZnTransfoDecompose(item->transfo, NULL, p, NULL, NULL);
    *num_pts = 1;
    *pts = p;
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
  GroupItem group = (GroupItem) item;
  ZnWInfo   *wi = item->wi;
  ZnItem    current_item;
  ZnBBox    bbox;
  int       result = TCL_OK;
  char      msg[500];

  PushTransform(item);
  PushClip(group, True);

  for (current_item = group->tail; current_item != ZN_NO_ITEM;
       current_item = current_item->previous) {
    if (ISCLEAR(current_item->flags, ZN_VISIBLE_BIT)) {
      continue;
    }
    //printf("area %g %g %g %g\n", area->orig.x, area->orig.y,
    //       area->corner.x, area->corner.y);
    ZnIntersectBBox(area, &current_item->item_bounding_box, &bbox);
    if (ZnIsEmptyBBox(&bbox)) {
      continue;
    }
    if (current_item->class->PostScript == NULL) {
      continue;
    }

    if (current_item->class != ZnGroup) {
      PushTransform(current_item);
      if (!prepass) {
        Tcl_AppendResult(wi->interp, "gsave\n", NULL);
      }
      ZnPostscriptTrace(current_item, 1);
    }
    result = current_item->class->PostScript(current_item, prepass, area);
    if (current_item->class != ZnGroup) {
      ZnPostscriptTrace(current_item, 0);
      if (!prepass && (result == TCL_OK)) {
        Tcl_AppendResult(wi->interp, "grestore\n", NULL);
      }
      PopTransform(current_item);
    }
    if (result == TCL_ERROR) {
      if (!prepass) {
        /*
         * Add some trace to ease the error lookup.
         */
        sprintf(msg, "\n    (generating Postscript for item %d)", current_item->id);
        Tcl_AddErrorInfo(wi->interp, msg);
        break;
      }
    }
  }

  PopClip(group, True);
  PopTransform(item);

  if (!prepass && (result == TCL_OK)) {
    ZnFlushPsChan(wi->interp, wi->ps_info);
  }
  return result;
}



ZnItem
ZnGroupHead(ZnItem      group)
{
  if (group->class != ZnGroup) {
    return ZN_NO_ITEM;
  }
  return ((GroupItem) group)->head;
}

ZnItem
ZnGroupTail(ZnItem      group)
{
  if (group->class != ZnGroup) {
    return ZN_NO_ITEM;
  }
  return ((GroupItem) group)->tail;
}

#ifdef ATC
ZnBool
ZnGroupCallOm(ZnItem    group)
{
  if (group->class != ZnGroup) {
    return False;
  }
  return ((GroupItem) group)->call_om;
}

void
ZnGroupSetCallOm(ZnItem group,
                 ZnBool set)
{
  if (group->class != ZnGroup) {
    return;
  }
  ((GroupItem) group)->call_om = set;
}
#else
ZnBool
ZnGroupCallOm(ZnItem    group)
{
  return False;
}

void
ZnGroupSetCallOm(ZnItem group,
                 ZnBool set)
{
  return;
}
#endif

ZnBool
ZnGroupAtomic(ZnItem    group)
{
  if (group->class != ZnGroup) {
    return True;
  }
  return ISSET(group->flags, ATOMIC_BIT);
}

void
ZnGroupRemoveClip(ZnItem        group,
                  ZnItem        clip)
{
  GroupItem grp = (GroupItem) group;

  if (grp->clip == clip) {
    grp->clip = ZN_NO_ITEM;
    ZnITEM.Invalidate(group, ZN_COORDS_FLAG);
  }
}


/*
 **********************************************************************************
 *
 * ZnInsertDependentItem --
 *
 **********************************************************************************
 */
void
ZnInsertDependentItem(ZnItem item)
{
  GroupItem    group = (GroupItem) item->parent;
  ZnItem       *dep_list;
  unsigned int i, num_deps;

  if (!group) {
    return;
  }
  if (!group->dependents) {
    group->dependents = ZnListNew(2, sizeof(ZnItem));
  }
  dep_list = (ZnItem *) ZnListArray(group->dependents);
  num_deps = ZnListSize(group->dependents);
  //
  // Insert the farther possible but not past an item
  // dependent on this item.
  for (i = 0; i < num_deps; i++) {
    if (dep_list[i]->connected_item == item) {
      //printf("item %d depends on %d inserting before\n",
      //       dep_list[i]->id, item->id);
      break;
    }
  }
  //printf("adding %d at position %d\n", item->id, i);
  ZnListAdd(group->dependents, &item, i);
}


/*
 **********************************************************************************
 *
 * ZnExtractDependentItem --
 *
 **********************************************************************************
 */
void
ZnExtractDependentItem(ZnItem   item)
{
  GroupItem     group = (GroupItem) item->parent;
  unsigned int  index, num_items;
  ZnItem        *deps;
  
  if (!group || !group->dependents) {
    return;
  }
  num_items = ZnListSize(group->dependents);
  deps = (ZnItem *) ZnListArray(group->dependents);
  for (index = 0; index < num_items; index++) {
    if (deps[index]->id == item->id) {
      ZnListDelete(group->dependents, index);
      if (ZnListSize(group->dependents) == 0) {
        ZnListFree(group->dependents);
        group->dependents = NULL;
        break;
      }
    }
  }
}


/*
 **********************************************************************************
 *
 * ZnDisconnectDependentItems --
 *      
 *
 **********************************************************************************
 */
void
ZnDisconnectDependentItems(ZnItem       item)
{
  ZnItem        current_item;
  GroupItem     group = (GroupItem) item->parent;
  ZnItem        *deps;
  unsigned int  num_deps;
  int           i;
  
  if (!group || !group->dependents) {
    return;
  }
  deps = (ZnItem *) ZnListArray(group->dependents);
  num_deps = ZnListSize(group->dependents);
  
  for (i = num_deps-1; i >= 0; i--) {
    current_item = deps[i];
    if (current_item->connected_item == item) {
      current_item->connected_item = ZN_NO_ITEM;
      ZnListDelete(group->dependents, i);
      ZnITEM.Invalidate(current_item, ZN_COORDS_FLAG);
    }
  }
  if (ZnListSize(group->dependents) == 0) {
    ZnListFree(group->dependents);
    group->dependents = NULL;
  }
}


/*
 **********************************************************************************
 *
 * ZnGroupExtractItem --
 *
 **********************************************************************************
 */
void
ZnGroupExtractItem(ZnItem       item)
{
  GroupItem     group;
  
  if (!item->parent) {
    return;
  }
  group = (GroupItem) item->parent;
  
  if (item->previous != ZN_NO_ITEM) {
    item->previous->next = item->next;
  }
  else {
    group->head = item->next;
  }
  
  if (item->next != ZN_NO_ITEM) {
    item->next->previous = item->previous;
  }
  else {
    group->tail = item->previous;
  }
  
  ZnITEM.Invalidate((ZnItem) group, ZN_COORDS_FLAG);

  item->previous = ZN_NO_ITEM;
  item->next = ZN_NO_ITEM;
  item->parent = NULL;
}


/*
 **********************************************************************************
 *
 * ZnGroupInsertItem --
 *
 **********************************************************************************
 */
void
ZnGroupInsertItem(ZnItem        group,
                  ZnItem        item,
                  ZnItem        mark_item,
                  ZnBool        before)
{
  GroupItem     grp = (GroupItem) group;

  /*
   * Empty list, add the first item.
   */
  if (grp->head == ZN_NO_ITEM) {
    grp->head = grp->tail = item;
    item->previous = item->next = ZN_NO_ITEM;
    return;
  }

  if (mark_item != ZN_NO_ITEM) {
    /*
     * Better leave here, mark_item will not
     * have the links set right.
     */
    if (mark_item == item) {
      return;
    }
    /*
     * Force the priority to be the same as the reference
     * item;
     */
    item->priority = mark_item->priority;
  }
  else {
    mark_item = grp->head;
    while ((mark_item != ZN_NO_ITEM) &&
           (mark_item->priority > item->priority)) {
      mark_item = mark_item->next;
    }
    before = True;
  }
  
  if (before && (mark_item != ZN_NO_ITEM)) {
    /*
     * Insert before mark.
     */
    item->next = mark_item;
    item->previous = mark_item->previous;
    if (mark_item->previous == ZN_NO_ITEM) {
      grp->head = item;
    }
    else {
      mark_item->previous->next = item;
    }
    mark_item->previous = item;
  }
  else {
    /*
     * Insert after mark either because 'before' is False
     * and mark_item valid or because the right place is at
     * the end of the list and mark_item is ZN_NO_ITEM.
     */
    if (mark_item == ZN_NO_ITEM) {
      grp->tail->next = item;
      item->previous = grp->tail;
      grp->tail = item;
    }
    else {
      item->previous = mark_item;
      item->next = mark_item->next;
      if (item->next == ZN_NO_ITEM) {
        grp->tail = item;
      }
      else {
        item->next->previous = item;
      }
      mark_item->next = item;
    }
  }

  ZnITEM.Invalidate(group, ZN_COORDS_FLAG);
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
  ZnBBox *bbox = &item->item_bounding_box;

  ZnOrigin2Anchor(&bbox->orig,
                  bbox->corner.x - bbox->orig.x,
                  bbox->corner.y - bbox->orig.y,
                  anchor, p);
}


/*
 **********************************************************************************
 *
 * Exported functions struct --
 *
 **********************************************************************************
 */
static ZnItemClassStruct GROUP_ITEM_CLASS = {
  "group",
  sizeof(GroupItemStruct),
  group_attrs,
  0,                    /* num_parts */
  ZN_CLASS_ONE_COORD,   /* flags */
  -1,
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  NULL,                 /* GetFieldSet */
  GetAnchor,
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

ZnItemClassId ZnGroup = (ZnItemClassId) &GROUP_ITEM_CLASS;
