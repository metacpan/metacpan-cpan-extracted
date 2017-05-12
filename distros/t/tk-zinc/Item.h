/*
 * Item.h -- Header to access items' common state and functions.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Item.h,v 1.51 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 1996 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Item_h
#define _Item_h


#include "PostScript.h"
#include "Attrs.h"
#include "Types.h"
#include "List.h"
#include "Field.h"

#include <X11/Xlib.h>
#include <tkInt.h>


/*
 * Types and constants for attribute processing.
 */
typedef struct _ZnAttrConfig {
  int   type;
  char  *name;
  Tk_Uid uid;
  int   offset;
  int   bool_bit;
  int   flags;
  ZnBool read_only;
} ZnAttrConfig;

/*
 * When adding new type in the following enum
 * do not forget to update attribute_type_strings
 * in Item.c.
 */
#define ZN_CONFIG_END           0
#define ZN_CONFIG_BOOL          1
#define ZN_CONFIG_BITMAP        2
#define ZN_CONFIG_BITMAP_LIST   3
#define ZN_CONFIG_STRING        4
#define ZN_CONFIG_FONT          5
#define ZN_CONFIG_EDGE_LIST     6
#define ZN_CONFIG_RELIEF        7
#define ZN_CONFIG_DIM           8
#define ZN_CONFIG_PRI           9
#define ZN_CONFIG_ALIGNMENT     10
#define ZN_CONFIG_AUTO_ALIGNMENT 11
#define ZN_CONFIG_LINE_END      12
#define ZN_CONFIG_LABEL_FORMAT  13
#define ZN_CONFIG_LINE_STYLE    14
#define ZN_CONFIG_LINE_SHAPE    15
#define ZN_CONFIG_ITEM          16
#define ZN_CONFIG_ANGLE         17
#define ZN_CONFIG_INT           18
#define ZN_CONFIG_UINT          19
#define ZN_CONFIG_POINT         20
#define ZN_CONFIG_ANCHOR        21
#define ZN_CONFIG_TAG_LIST      22
#define ZN_CONFIG_MAP_INFO      23
#define ZN_CONFIG_IMAGE         24
#define ZN_CONFIG_LEADER_ANCHORS 25
#define ZN_CONFIG_JOIN_STYLE    26
#define ZN_CONFIG_CAP_STYLE     27
#define ZN_CONFIG_GRADIENT      28
#define ZN_CONFIG_GRADIENT_LIST 29
#define ZN_CONFIG_WINDOW        30
#define ZN_CONFIG_ALPHA         31
#define ZN_CONFIG_FILL_RULE     32
#define ZN_CONFIG_SHORT         33
#define ZN_CONFIG_USHORT        34
#define ZN_CONFIG_CHAR          35
#define ZN_CONFIG_UCHAR         36

#define ZN_DRAW_FLAG    1 << 0
#define ZN_COORDS_FLAG  1 << 1
#define ZN_TRANSFO_FLAG 1 << 2
#define ZN_REPICK_FLAG  1 << 3
#define ZN_BORDER_FLAG  1 << 4
#define ZN_CLFC_FLAG    1 << 5  /* Clear Label Format Cache. */
#define ZN_IMAGE_FLAG   1 << 6  /* Update image pointer. */
#define ZN_VIS_FLAG     1 << 7  /* Visibility has changed. */
#define ZN_MOVED_FLAG   1 << 8  /* Item has moved. */
#define ZN_ITEM_FLAG    1 << 9  /* Signal a change in an item type attribute. */
#define ZN_MAP_INFO_FLAG 1 << 10/* Update mapinfo pointer. */
#define ZN_LAYOUT_FLAG  1 << 11 /* A layout need update. */
#define ZN_POLAR_FLAG   1 << 12 /* Signal a cartesian to polar change. */
#define ZN_CARTESIAN_FLAG 1 << 13       /* Signal a polar to cartesian change. */
#define ZN_TILE_FLAG    1 << 14 /* Update tile pointer. */
#define ZN_WINDOW_FLAG  1 << 15 /* Signal a change in a window type attribute. */


/*
 * This constant marks a non existant item
*/
#define ZN_NO_ITEM              NULL

/*
 * Constants for item parts. The item indexable parts (named fields) are coded
 * as positive or null integers. The item specific parts (not indexable) are
 * coded as negatives beginning at -2 up to -9 which is the current limit. The
 * -1 value is reserved to indicate no part.
 */
#define ZnPartToBit(part)       (1 << (ABS(part)-2))
#define ZN_NO_PART              -1

/*
 * Some flags macros.
 */
#define ISSET(var, mask)        ((var) & (mask))
#define ISCLEAR(var, mask)      (((var) & (mask)) == 0)
#define SET(var,mask)           ((var) |= (mask))
#define CLEAR(var, mask)        ((var) &= ~(mask))
#define ASSIGN(var, mask, bool) ((bool) ? SET((var), (mask)) : CLEAR((var), (mask)))

/*
 * Item flags values.
 */
#define ZN_VISIBLE_BIT          (1<<0)
#define ZN_SENSITIVE_BIT        (1<<1)
#define ZN_UPDATE_DEPENDENT_BIT (1<<2)
#define ZN_COMPOSE_SCALE_BIT    (1<<3)
#define ZN_COMPOSE_ROTATION_BIT (1<<4)
#define ZN_COMPOSE_ALPHA_BIT    (1<<5)
/*
 * Must be kept one greater than the last flag shift count.
 */
#define ZN_PRIVATE_FLAGS_OFFSET 6


/*
 * Operator constants for the coord method.
 */
#define ZN_COORDS_READ          0
#define ZN_COORDS_READ_ALL      1
#define ZN_COORDS_REPLACE       2
#define ZN_COORDS_REPLACE_ALL   3
#define ZN_COORDS_ADD           4
#define ZN_COORDS_ADD_LAST      5
#define ZN_COORDS_REMOVE        6
  

struct _ZnWInfo;
struct _ZnTransfo;

/*
 * Item record header --
 */
typedef struct _ZnItemStruct {
  /* Private data */
  unsigned int          id;
  ZnList                tags;
  struct _ZnWInfo       *wi;                    /* The widget this item is on   */
  struct _ZnItemClassStruct *class;             /* item class                   */
  struct _ZnItemStruct  *previous;              /* previous item in group list  */
  struct _ZnItemStruct  *next;                  /* next item in group list      */
  struct _ZnItemStruct  *parent;
  ZnBBox                item_bounding_box;      /* device item bounding box     */

  /* Common attributes */
  unsigned short        flags;                  
  unsigned short        part_sensitive;         /* Currently limited to 16 parts per item */
  unsigned short        inv_flags;
  unsigned short        priority;
  struct _ZnTransfo     *transfo;
  struct _ZnItemStruct  *connected_item;        /* Item this item is connected to       */
#ifdef GL
#ifdef GL_LIST
  GLuint                gl_list;                /* Display list storing the item graphics */
#endif
#endif
} ZnItemStruct, *ZnItem;

typedef struct _ZnToAreaStruct {
  Tk_Uid        tag_uid;
  ZnBool        enclosed;
  ZnItem        in_group;
  ZnBool        report;
  ZnBool        recursive;
  ZnBool        override_atomic;
  ZnBBox        *area;
} ZnToAreaStruct, *ZnToArea;

typedef struct _ZnPickStruct {
  int           aperture;
  ZnItem        in_group;
  ZnItem        start_item;
  ZnBool        recursive;
  ZnBool        override_atomic;
  ZnPoint       *point;
  ZnItem        a_item;
  int           a_part;
} ZnPickStruct, *ZnPick;


/*
 * Item class record --
 */
typedef int (*ZnItemInitMethod)(ZnItem item, int *argc, Tcl_Obj *CONST *args[]);
typedef int (*ZnItemConfigureMethod)(ZnItem item, int argc, Tcl_Obj *CONST args[],
                                     int *flags);
typedef int (*ZnItemQueryMethod)(ZnItem item, int argc, Tcl_Obj *CONST args[]);
typedef void (*ZnItemCloneMethod)(ZnItem item);
typedef void (*ZnItemDestroyMethod)(ZnItem item);
typedef void (*ZnItemDrawMethod)(ZnItem item);
typedef void (*ZnItemRenderMethod)(ZnItem item);
typedef void (*ZnItemComputeCoordinatesMethod)(ZnItem item, ZnBool force);
typedef int (*ZnItemToAreaMethod)(ZnItem item, ZnToArea ta);
typedef ZnReal (*ZnItemPickMethod)(ZnItem item, ZnPick ps);
typedef ZnBool (*ZnItemIsSensitiveMethod)(ZnItem item, int part);
typedef struct _ZnFieldSetStruct* (*ZnItemGetFieldSetMethod)(ZnItem item);
typedef int (*ZnItemContourMethod)(ZnItem item, int cmd, int index, ZnPoly *poly);
typedef void (*ZnItemPickVertexMethod)(ZnItem item, ZnPoint *p, int *contour,
                                       int *vertex, int *o_vertex);
typedef void (*ZnItemGetAnchorMethod)(ZnItem item, Tk_Anchor anchor, ZnPoint *p);
typedef ZnBool (*ZnItemGetClipVerticesMethod)(ZnItem item, ZnTriStrip *tristrip);
typedef ZnBool (*ZnItemGetContoursMethod)(ZnItem item, ZnPoly *poly);
typedef int (*ZnItemCoordsMethod)(ZnItem item, int contour, int index, int cmd,
                                  ZnPoint **points, char **controls, unsigned int *num_points);
typedef void (*ZnItemInsertCharsMethod)(ZnItem item, int field, int *index,
                                        char *chars);
typedef void (*ZnItemDeleteCharsMethod)(ZnItem item, int field, int *first,
                                        int *last);
typedef void (*ZnItemCursorMethod)(ZnItem item, int field, int index);
typedef int (*ZnItemIndexMethod)(ZnItem item, int field, Tcl_Obj *index_spec,
                                 int *index);
typedef int (*ZnItemPartMethod)(ZnItem item, Tcl_Obj **part_spec, int *part);
typedef int (*ZnItemSelectionMethod)(ZnItem item, int field, int offset,
                                     char *chars, int max_chars);
typedef int (*ZnItemPostScriptMethod)(ZnItem item, ZnBool prepass, ZnBBox *area);


typedef void    *ZnItemClassId;

#define ZN_CLASS_HAS_ANCHORS    (1<<0)
#define ZN_CLASS_ONE_COORD      (1<<1)

typedef struct _ZnItemClassStruct {
  char                          *name;
  unsigned int                  size;
  ZnAttrConfig                  *attr_desc;
  unsigned int                  num_parts;      /* 0 if no special parts, else
                                                 * gives how many parts exist. */
  int                           flags;          /* HAS_ANCHORS, ONE_COORD */
  int                           pos_offset;     /* Offset of -position attrib, */
                                                /* if any, -1 otherwise. */
  ZnItemInitMethod              Init;
  ZnItemCloneMethod             Clone;
  ZnItemDestroyMethod           Destroy;
  ZnItemConfigureMethod         Configure;
  ZnItemQueryMethod             Query;
  ZnItemGetFieldSetMethod       GetFieldSet;
  ZnItemGetAnchorMethod         GetAnchor;
  ZnItemGetClipVerticesMethod   GetClipVertices;
  ZnItemGetContoursMethod       GetContours;
  ZnItemCoordsMethod            Coords;
  ZnItemInsertCharsMethod       InsertChars;
  ZnItemDeleteCharsMethod       DeleteChars;
  ZnItemCursorMethod            Cursor;
  ZnItemIndexMethod             Index;
  ZnItemPartMethod              Part;
  ZnItemSelectionMethod         Selection;
  ZnItemContourMethod           Contour;
  ZnItemComputeCoordinatesMethod ComputeCoordinates;
  ZnItemToAreaMethod            ToArea;
  ZnItemDrawMethod              Draw;
  ZnItemRenderMethod            Render;
  ZnItemIsSensitiveMethod       IsSensitive;
  ZnItemPickMethod              Pick;
  ZnItemPickVertexMethod        PickVertex;
  ZnItemPostScriptMethod        PostScript;
} ZnItemClassStruct, *ZnItemClass;


/*
 **********************************************************************************
 *
 * Generic methods for all items.
 *
 **********************************************************************************
 */
extern struct _ZnITEM {
  ZnItem (*CloneItem)(ZnItem model);
  void (*DestroyItem)(ZnItem item);
  int (*ConfigureItem)(ZnItem item, int field, int argc, Tcl_Obj *CONST args[],
                       ZnBool init);
  int (*QueryItem)(ZnItem item, int field, int argc, Tcl_Obj *CONST args[]);
  void (*InsertItem)(ZnItem item, ZnItem group, ZnItem mark_item, ZnBool before);
  void (*UpdateItemPriority)(ZnItem item, ZnItem mark_item, ZnBool before);
  void (*UpdateItemDependency)(ZnItem item, ZnItem old_connection);
  void (*ExtractItem)(ZnItem item);
  void (*SetId)(ZnItem item);
  void (*FreeId)(ZnItem item);
  void (*AddTag)(ZnItem item, Tk_Uid tag);
  void (*RemoveTag)(ZnItem item, Tk_Uid tag);
  void (*FreeTags)(ZnItem item);
  ZnBool (*HasTag)(ZnItem item, Tk_Uid tag);
  void (*ResetTransfo)(ZnItem item);
  void (*SetTransfo)(ZnItem item, struct _ZnTransfo *t);
  void (*TranslateItem)(ZnItem item, ZnReal tx, ZnReal ty, ZnBool abs);
  void (*ScaleItem)(ZnItem item, ZnReal sx, ZnReal sy, ZnPoint *p);
  void (*SkewItem)(ZnItem item, ZnReal x_skew, ZnReal y_skew);
  void (*RotateItem)(ZnItem item, ZnReal angle, ZnBool deg, ZnPoint *p);
  void (*Invalidate)(ZnItem item, int reason);
  void (*InvalidateItems)(ZnItem group, ZnItemClass item_class);
  void (*GetItemTransform)(ZnItem item, struct _ZnTransfo *t);
} ZnITEM;


/*
 **********************************************************************************
 *
 * Methods defined in Item.c useful for writing items.
 *
 **********************************************************************************
 */
void ZnItemInit();
ZnItem ZnCreateItem(struct _ZnWInfo *wi, ZnItemClass item_class,
                  int *argc, Tcl_Obj *CONST *args[]);
void ZnAddItemClass(ZnItemClass class);
ZnItemClass ZnLookupItemClass(char *class_name);
ZnList ZnItemClassList();
int ZnConfigureAttributes(struct _ZnWInfo *wi, ZnItem item, void *record,
                          ZnAttrConfig *attr_desc, int argc, Tcl_Obj *CONST args[],
                          int *flags);
int ZnAttributesInfo(Tcl_Interp *interp, void *record,
                     ZnAttrConfig *attr_desc, int argc, Tcl_Obj *CONST args[]);
int ZnQueryAttribute(Tcl_Interp *interp, void *record, ZnAttrConfig *attr_desc,
                     Tcl_Obj *attr_name);
void ZnInitTransformStack(struct _ZnWInfo *wi);
void ZnFreeTransformStack(struct _ZnWInfo *wi);
void ZnResetTransformStack(struct _ZnWInfo *wi);
void ZnPushTransform(struct _ZnWInfo *wi, struct _ZnTransfo *transfo,
                     ZnPoint *pos, ZnBool compose_scale, ZnBool compose_rot);
void ZnPopTransform(struct _ZnWInfo *wi);
void ZnInitClipStack(struct _ZnWInfo *wi);
void ZnFreeClipStack(struct _ZnWInfo *wi);
void ZnResetClipStack(struct _ZnWInfo *wi);
void ZnPushClip(struct _ZnWInfo *wi, ZnTriStrip *tristrip, ZnBool simple,
                ZnBool set_gc);
void ZnPopClip(struct _ZnWInfo *wi, ZnBool set_gc);
ZnBool ZnCurrentClip(struct _ZnWInfo *wi, TkRegion *reg, ZnBBox **clip_box,
                     ZnBool *simple);
void ZnUpdateItemImage(void *client_data);


extern ZnItemClassId    ZnArc;
extern ZnItemClassId    ZnMap;
extern ZnItemClassId    ZnTabular;
extern ZnItemClassId    ZnCurve;
extern ZnItemClassId    ZnBezier;
extern ZnItemClassId    ZnTriangles;
extern ZnItemClassId    ZnRectangle;
extern ZnItemClassId    ZnReticle;
extern ZnItemClassId    ZnTrack;
extern ZnItemClassId    ZnWayPoint;
extern ZnItemClassId    ZnGroup;
extern ZnItemClassId    ZnIcon;
extern ZnItemClassId    ZnText;
extern ZnItemClassId    ZnWindow;


#endif  /* _Item_h */
