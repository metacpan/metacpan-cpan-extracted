/*
 * Item.c -- Implementation of items.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : 
 *
 * $Id: Item.c,v 1.93 2005/11/25 15:40:28 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Types.h"
#include "Field.h"
#include "Item.h"
#include "Group.h"
#include "WidgetInfo.h"
#include "Geo.h"
#include "Draw.h"
#include "MapInfo.h"
#include "Image.h"
#include "Color.h"
#include "tkZinc.h"
#ifdef ATC
#include "OverlapMan.h"
#endif

#include <GL/glu.h>
#include <limits.h>             /* For INT_MAX */
#include <stdarg.h>
#include <stdio.h>
#include <string.h>


static const char rcsid[] = "$Id: Item.c,v 1.93 2005/11/25 15:40:28 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


static  ZnList  item_classes = NULL;
static  ZnList  item_stack = NULL;


/*
 * This array must be kept in sync with the
 * corresponding defines in Item.h.
 */
static char *attribute_type_strings[] = {
  "",
  "boolean",
  "bitmap",
  "bitmaplist",
  "string",
  "font",
  "edgelist",
  "relief",
  "dimension",
  "priority",
  "alignment",
  "autoalignment",
  "lineend",
  "labelformat",
  "linestyle",
  "lineshape",
  "item",
  "angle",
  "integer",
  "unsignedint",
  "point",
  "anchor",
  "taglist",
  "mapinfo",
  "image",
  "leaderanchors",
  "joinstyle",
  "capstyle",
  "gradient",
  "gradientlist",
  "window",
  "alpha",
  "fillrule",
  "short",
  "unsignedshort"
  "char"
  "unsignedchar"
};


#ifndef PTK
static int SetAttrFromAny _ANSI_ARGS_((Tcl_Interp *interp, Tcl_Obj *obj));

/*
 * The structure below defines an object type that is used to cache the
 * result of looking up an attribute name.  If an object has this type, then
 * its internalPtr1 field points to the attr_desc table in which it was looked up,
 * and the internalPtr2 field points to the entry that matched.
 */

Tcl_ObjType ZnAttrObjType = {
    "attribute",                        /* name */
    (Tcl_FreeInternalRepProc *) NULL,   /* freeIntRepProc */
    (Tcl_DupInternalRepProc *) NULL,    /* dupIntRepProc */
    (Tcl_UpdateStringProc *) NULL,      /* updateStringProc */
    SetAttrFromAny                      /* setFromAnyProc */
};
#endif


/*
 **********************************************************************************
 *
 * Forward functions
 * 
 **********************************************************************************
 */
static void Invalidate(ZnItem item, int reason);
static Tcl_Obj *AttributeToObj(Tcl_Interp *interp, void *record, ZnAttrConfig *desc);



/*
 **********************************************************************************
 *
 * ZnUpdateItemImage --
 *
 **********************************************************************************
 */
void
ZnUpdateItemImage(void *client_data)
{
  ZnItem item = (ZnItem) client_data;

  /*printf("Invalidation of item %ld\n", item->id);*/
  Invalidate(item, ZN_CLFC_FLAG | ZN_COORDS_FLAG);  
}


/*
 **********************************************************************************
 *
 * InitAttrDesc --
 *
 **********************************************************************************
 */
static void
InitAttrDesc(ZnAttrConfig       *attr_desc)
{
  if (!attr_desc) {
    return;
  }

  while (attr_desc->type != ZN_CONFIG_END) {
    attr_desc->uid = Tk_GetUid(attr_desc->name);
    attr_desc++;
  }
}

/*
 *----------------------------------------------------------------------
 *
 * SetAttrFromAny --
 *
 *      This procedure is called to convert a Tcl object to an attribute
 *      descriptor. This is only possible if given a attr_desc table, so
 *      this method always returns an error.
 *
 *----------------------------------------------------------------------
 */
#ifndef PTK
static int
SetAttrFromAny(Tcl_Interp       *interp,
               Tcl_Obj          *obj)
{
  Tcl_AppendToObj(Tcl_GetObjResult(interp),
                  "can't convert value to attribute except via GetAttrDesc",
                  -1);
  return TCL_ERROR;
}
#endif


/*
 **********************************************************************************
 *
 * GetAttrDesc --
 *
 **********************************************************************************
 */
static ZnAttrConfig *
GetAttrDesc(Tcl_Interp          *interp,
            Tcl_Obj             *arg,
            ZnAttrConfig        *desc_table)
{
  Tk_Uid        attr_uid;
  ZnAttrConfig  *desc;

#ifndef PTK
  if (arg->typePtr == &ZnAttrObjType) {
    if (arg->internalRep.twoPtrValue.ptr1 == (void *) desc_table) {
      return (ZnAttrConfig *) arg->internalRep.twoPtrValue.ptr2;
    }
  }
#endif

  /*
   * Answer not cached, look it up.
   */
  attr_uid = Tk_GetUid(Tcl_GetString(arg));
  desc = desc_table;

  while (True) {
    if (desc->type == ZN_CONFIG_END) {
      Tcl_AppendResult(interp, "unknown attribute \"", attr_uid, "\"", NULL);
      return NULL;
    }
    else if (attr_uid == desc->uid) {
#ifndef PTK
      if ((arg->typePtr != NULL) && (arg->typePtr->freeIntRepProc != NULL)) {
        arg->typePtr->freeIntRepProc(arg);
      }
      arg->internalRep.twoPtrValue.ptr1 = (void *) desc_table;
      arg->internalRep.twoPtrValue.ptr2 = (void *) desc;
      arg->typePtr = &ZnAttrObjType;
#endif
      return desc;
    }
    else {
      desc++;
    }
  }
}


/*
 **********************************************************************************
 *
 * AttributesInfo --
 *
 **********************************************************************************
 */
int
ZnAttributesInfo(Tcl_Interp     *interp,
                 void           *record,
                 ZnAttrConfig   *desc_table,
                 int            argc,
                 Tcl_Obj *CONST args[])
{
  Tcl_Obj       *l, *entries[5];
  
  if (argc == 1) {
    ZnAttrConfig *desc = GetAttrDesc(interp, args[0], desc_table);
    if (!desc) {
      return TCL_ERROR;
    }
    entries[0] = Tcl_NewStringObj(desc->name, -1);
    entries[1] = Tcl_NewStringObj(attribute_type_strings[desc->type], -1);
    entries[2] = Tcl_NewBooleanObj(desc->read_only ? 1 : 0);
    entries[3] = Tcl_NewStringObj("", -1);
    entries[4] = AttributeToObj(interp, record, desc);
    l = Tcl_NewListObj(5, entries);
    Tcl_SetObjResult(interp, l);
  }
  else {
    l = Tcl_NewObj();
    while (desc_table->type != ZN_CONFIG_END) {
      entries[0] = Tcl_NewStringObj(desc_table->name, -1);
      entries[1] = Tcl_NewStringObj(attribute_type_strings[desc_table->type], -1);
      entries[2] = Tcl_NewBooleanObj(desc_table->read_only ? 1 : 0);
      entries[3] = Tcl_NewStringObj("", -1);
      entries[4] = AttributeToObj(interp, record, desc_table);
      Tcl_ListObjAppendElement(interp, l, Tcl_NewListObj(5, entries));
      desc_table++;
    }
    Tcl_SetObjResult(interp, l);
  }
  
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * ZnConfigureAttributes --
 *
 **********************************************************************************
 */
int
ZnConfigureAttributes(ZnWInfo           *wi,
                      ZnItem            item,
                      void              *record,
                      ZnAttrConfig      *desc_table,
                      int               argc,
                      Tcl_Obj *CONST    args[],
                      int               *flags)
{
  int           i;
  ZnAttrConfig  *desc;
  ZnPtr         valp;
  char          *str;
  
  for (i = 0; i < argc; i += 2) {
    desc = GetAttrDesc(wi->interp, args[i], desc_table);
    if (!desc) {
      return TCL_ERROR;
    }
    else if (desc->read_only) {
      Tcl_AppendResult(wi->interp, "attribute \"",
                       Tcl_GetString(args[i]), "\" can only be read", NULL);
      return TCL_ERROR;
    }

    valp = ((char *) record) + desc->offset;
    /*printf("record <0x%X>, valp <0x%X>, offset %d\n", record, valp, desc->offset);*/
    switch (desc->type) {
    case ZN_CONFIG_GRADIENT:
      {
        ZnGradient *g;
        Tk_Uid new_name = Tk_GetUid(Tcl_GetString(args[i+1]));
        char   *name = NULL;
        if (*((ZnGradient **) valp)) {
          name = ZnNameOfGradient(*((ZnGradient **) valp));
        }
        if (name != new_name) {
          g = ZnGetGradient(wi->interp, wi->win, new_name);
          if (!g) {
            Tcl_AppendResult(wi->interp,
                             " gradient expected for attribute \"",
                             Tcl_GetString(args[i]), "\"", NULL);
            return TCL_ERROR;
          }
          if (*((ZnGradient **) valp)) {
            ZnFreeGradient(*((ZnGradient **) valp));
          }
          *((ZnGradient **) valp) = g;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_GRADIENT_LIST:
      {
        ZnList   new_grad_list = NULL;
        ZnGradient       **grads;
        unsigned int num_grads, j, k;
        Tcl_Obj  **elems;
            
        if (Tcl_ListObjGetElements(wi->interp, args[i+1],
                                   &num_grads, &elems) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp,
                           " gradient list expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (num_grads) {
          new_grad_list = ZnListNew(num_grads, sizeof(ZnGradient *));
          ZnListAssertSize(new_grad_list, num_grads);
          grads = ZnListArray(new_grad_list);
          for (j = 0; j < num_grads; j++) {
            str = Tcl_GetString(elems[j]);
            if (!*str) {
              if (j == 0) {
                goto grads_err;
              }
              grads[j] = grads[j-1];
            }
            else {
              grads[j] = ZnGetGradient(wi->interp, wi->win, str);
            }
            if (!grads[j]) {
            grads_err:
              Tcl_AppendResult(wi->interp, " invalid gradient \"", str,
                               "\" in gradient list", NULL);
              for (k = 0; k < j; k++) {
                ZnFreeGradient(grads[k]);
              }
              ZnListFree(new_grad_list);
              return TCL_ERROR;
            }
          }
        }
        if (*((ZnList *) valp)) {
          num_grads = ZnListSize(*((ZnList *) valp));
          grads = ZnListArray(*((ZnList *) valp));
          for (j = 0; j < num_grads; j++) {
            if (grads[j]) {
              ZnFreeGradient(grads[j]);
            }
          }
          ZnListFree(*((ZnList *) valp));
          *((ZnList *) valp) = new_grad_list;
          *flags |= desc->flags;
        }
        else {
          if (new_grad_list) {
            *((ZnList *) valp) = new_grad_list;
            *flags |= desc->flags;
          }
        }
        break;
      }
    case ZN_CONFIG_BOOL:
      {
        int     b;
        if (Tcl_GetBooleanFromObj(wi->interp, args[i+1], &b) != TCL_OK) {
          Tcl_AppendResult(wi->interp, " boolean expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (b ^ (ISSET(*((unsigned short *) valp), desc->bool_bit) != 0)) {
          ASSIGN(*((unsigned short *) valp), desc->bool_bit, b);
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_IMAGE:
    case ZN_CONFIG_BITMAP:
      {
        ZnImage image = ZnUnspecifiedImage;
        ZnBool  is_bmap = True;
        char    *name = "";
        
        if (*((ZnImage *) valp) != ZnUnspecifiedImage) {
          name = ZnNameOfImage(*((ZnImage *) valp));
        }
        str = Tcl_GetString(args[i+1]);
        if (strcmp(name, str) != 0) {
          if (strlen(str) != 0) {
            if (desc->type == ZN_CONFIG_IMAGE) {
              image = ZnGetImage(wi, str, ZnUpdateItemImage, record);
              if (image == ZnUnspecifiedImage) {
                Tcl_AppendResult(wi->interp, " image expected for attribute \"",
                                 Tcl_GetString(args[i]), "\"", NULL);
                return TCL_ERROR;
              }
            }
            else {
              image = ZnGetImage(wi, str, NULL, NULL);
              if ((image == ZnUnspecifiedImage) ||
                  (!(is_bmap = ZnImageIsBitmap(image)))) {
                if (!is_bmap) {
                  ZnFreeImage(image, NULL, NULL);
                }
                Tcl_AppendResult(wi->interp, " bitmap expected for attribute \"",
                                 Tcl_GetString(args[i]), "\"", NULL);
                return TCL_ERROR;
              }
            }
          }
          if (*((ZnImage *) valp) != ZnUnspecifiedImage) {
            ZnFreeImage(*((ZnImage *) valp), ZnUpdateItemImage, record);
          }
          *((ZnImage *) valp) = image;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_BITMAP_LIST:
      {
        ZnList   new_pat_list = NULL;
        ZnImage  *pats;
        unsigned int num_pats, j, k;
        Tcl_Obj  **elems;
        ZnBool   is_bmap = True;
        
        if (Tcl_ListObjGetElements(wi->interp, args[i+1],
                                   &num_pats, &elems) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp,
                           " pattern list expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (num_pats) {
          new_pat_list = ZnListNew(num_pats, sizeof(Pixmap));
          ZnListAssertSize(new_pat_list, num_pats);
          pats = ZnListArray(new_pat_list);
          for (j = 0; j < num_pats; j++) {
            str = Tcl_GetString(elems[j]);
            if (strlen(str) != 0) {
              pats[j] = ZnGetImage(wi, str, NULL, NULL);
              if ((pats[j] == ZnUnspecifiedImage) ||
                      !(is_bmap = ZnImageIsBitmap(pats[j]))) {
                if (!is_bmap) {
                  ZnFreeImage(pats[j], NULL, NULL);
                }
                for (k = 0; k < j; k++) {
                  ZnFreeImage(pats[k], NULL, NULL);
                }
                ZnListFree(new_pat_list);
                Tcl_AppendResult(wi->interp, " unknown pattern \"", str,
                                 "\" in pattern list", NULL);
                return TCL_ERROR;
              }
            }
            else {
              pats[j] = ZnUnspecifiedImage;
            }
          }
        }
        if (*((ZnList *) valp)) {
          num_pats = ZnListSize(*((ZnList *) valp));
          pats = ZnListArray(*((ZnList *) valp));
          for (j = 0; j < num_pats; j++) {
            if (pats[j] != ZnUnspecifiedImage) {
              ZnFreeImage(pats[j], NULL, NULL);
            }
          }
          ZnListFree(*((ZnList *) valp));
          *((ZnList *) valp) = new_pat_list;
          *flags |= desc->flags;
        }
        else {
          if (new_pat_list) {
            *((ZnList *) valp) = new_pat_list;
            *flags |= desc->flags;
          }
        }
        break;
      }
    case ZN_CONFIG_TAG_LIST:
      {
        int             num_tags, j;
        Tcl_Obj **elems;
        
        if (Tcl_ListObjGetElements(wi->interp, args[i+1],
                                   &num_tags, &elems) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp,
                           " tag list expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (*((ZnList *) valp)) {
          ZnITEM.FreeTags(item);
          *flags |= desc->flags;
        }
        if (num_tags) {
          for (j = 0; j < num_tags; j++) {
            ZnITEM.AddTag(item, Tk_GetUid(Tcl_GetString(elems[j])));
          }
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_STRING:
    case ZN_CONFIG_MAP_INFO:
      {
        char *text = NULL;
        str = Tcl_GetString(args[i+1]);
        if (!*((char **) valp) || strcmp(str, *((char **) valp)) != 0) {
          if (strlen(str)) {
            text = (char *) ZnMalloc(strlen(str)+1);
            strcpy(text, str);
          }
          if (*((char **) valp)) {
            ZnFree(*((char **) valp));
          }
          *((char **) valp) = text;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_FONT:
      {
        Tk_Font font;
        Tk_Uid  name = "";
        if (*((Tk_Font *) valp)) {
          name = Tk_NameOfFont(*((Tk_Font *) valp));
        }
        str = Tcl_GetString(args[i+1]);
        if (strcmp(name, str) != 0) {
          font = Tk_GetFont(wi->interp, wi->win, str);
          if (!font) {
            Tcl_AppendResult(wi->interp, " font expected for attribute \"",
                             Tcl_GetString(args[i]), "\"", NULL);
            return TCL_ERROR;
          }
          if (*((Tk_Font *) valp)) {
            Tk_FreeFont(*((Tk_Font *) valp));
          }
          *((Tk_Font *) valp) = font;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_EDGE_LIST:
      {
        ZnBorder border;

        if (ZnGetBorder(wi, args[i+1], &border) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " edge list expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (border != *((ZnBorder *) valp)) {
          *((ZnBorder *) valp) = border;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_LINE_SHAPE:
      {
        ZnLineShape line_shape;

        if (ZnGetLineShape(wi, Tcl_GetString(args[i+1]), &line_shape) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " line shape expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (line_shape != *((ZnLineShape *) valp)) {
          *((ZnLineShape *) valp) = line_shape;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_LINE_STYLE:
      {
        ZnLineStyle    line_style;

        if (ZnGetLineStyle(wi, Tcl_GetString(args[i+1]), &line_style) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " line style expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (line_style != *((ZnLineStyle *) valp)) {
          *((ZnLineStyle *) valp) = line_style;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_LINE_END:
      {
        ZnLineEnd line_end = NULL;
        str = Tcl_GetString(args[i+1]);
        if (strlen(str) != 0) {
          line_end = ZnLineEndCreate(wi->interp, str);
          if (line_end == NULL) {
            return TCL_ERROR;
          }
        }
        if (*((ZnLineEnd *) valp) != NULL) {
          ZnLineEndDelete(*((ZnLineEnd *) valp));
          *((ZnLineEnd *) valp) = line_end;
          *flags |= desc->flags;
        }
        else {
          if (line_end != NULL) {
            *((ZnLineEnd *) valp) = line_end;
            *flags |= desc->flags;
          }
        }
        break;
      }
    case ZN_CONFIG_RELIEF:
      {
        ZnReliefStyle relief;
        if (ZnGetRelief(wi, Tcl_GetString(args[i+1]), &relief) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " relief expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (relief != *((ZnReliefStyle *) valp)) {
          /*printf("valp <0x%X>, flags <0x%X>, relief %d\n", valp, flags, relief);*/
          *((ZnReliefStyle *) valp) = relief;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_JOIN_STYLE:
      {
        int     join;
        if (Tk_GetJoinStyle(wi->interp, Tcl_GetString(args[i+1]), &join) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " join expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (join != *((int *) valp)) {
          *((int *) valp) = join;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_CAP_STYLE:
      {
        int     cap;
        if (Tk_GetCapStyle(wi->interp, Tcl_GetString(args[i+1]), &cap) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " cap expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (cap != *((int *) valp)) {
          *((int *) valp) = cap;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_POINT:
      {
        ZnPoint point;
        int             largc;
        Tcl_Obj **largv;
        double  d;

        if ((Tcl_ListObjGetElements(wi->interp, args[i+1],
                                    &largc, &largv) == TCL_ERROR) ||
            (largc != 2)) {
        point_error:
          Tcl_AppendResult(wi->interp, " position expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (Tcl_GetDoubleFromObj(wi->interp, largv[0], &d) == TCL_ERROR) {
          goto point_error;
        }
        point.x = d;
        if (Tcl_GetDoubleFromObj(wi->interp, largv[1], &d) == TCL_ERROR) {
          goto point_error;
        }
        point.y = d;
        if ((point.x != ((ZnPoint *) valp)->x) ||
            (point.y != ((ZnPoint *) valp)->y)) {
          *((ZnPoint *) valp) = point;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_ANGLE:
      {
        double angle;
        int    int_angle;
        if (Tcl_GetDoubleFromObj(wi->interp, args[i+1], &angle) == TCL_ERROR) {
          return TCL_ERROR;
        }
        int_angle = (int) angle;
        int_angle = int_angle % 360;
        if (int_angle != *((int *) valp)) {
          *((int *) valp) = int_angle;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_DIM:
      {
        double dim;
        if (Tcl_GetDoubleFromObj(wi->interp, args[i+1], &dim) == TCL_ERROR) {
          return TCL_ERROR;
        }
        if (dim != *((ZnDim *) valp)) {
          *((ZnDim *) valp) = dim;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_PRI:
      {
        int     pri;
        if (Tcl_GetIntFromObj(wi->interp, args[i+1], &pri) == TCL_ERROR) {
          return TCL_ERROR;
        }
        if (pri < 0) {
          Tcl_AppendResult(wi->interp, " priority must be a positive integer \"",
                           Tcl_GetString(args[i+1]), "\"", NULL);
          return TCL_ERROR;
        }
        if (pri != *((unsigned short *) valp)) {
          *((unsigned short *) valp) = pri;
          ZnITEM.UpdateItemPriority(item, ZN_NO_ITEM, True);
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_ITEM:
      /*
       * Can be an item id or a tag. In this last case
       * consider only the first item (unspecified order)
       * associated with the tag.
       */
      {
        ZnItem  item2;
        int             result;
        ZnTagSearch     *search_var = NULL;

        if (strlen(Tcl_GetString(args[i+1])) == 0) {
          item2 = ZN_NO_ITEM;
        }
        else {
          result = ZnItemWithTagOrId(wi, args[i+1], &item2, &search_var);
          ZnTagSearchDestroy(search_var);
          if ((result == TCL_ERROR) || (item2 == ZN_NO_ITEM)) {
            Tcl_AppendResult(wi->interp, " unknown item \"",
                             Tcl_GetString(args[i+1]), "\"", NULL);
            return TCL_ERROR;
          }
        }
        if (item2 != *((ZnItem *) valp)) {
          *((ZnItem *) valp) = item2;
          *flags |= desc->flags;
        }
      }
      break;
    case ZN_CONFIG_WINDOW:
      {
        Tk_Window       win, ancestor, parent;
        str = Tcl_GetString(args[i+1]);
        if (strlen(str) == 0) {
          win = NULL;
        }
        else {
          win = Tk_NameToWindow(wi->interp, str, wi->win);
          if (win == NULL) {
            return TCL_ERROR;
          }
          else {
            /*
             * Make sure that the zinc widget is either the parent of the
             * window associated with the item or a descendant of that
             * parent.  Also, don't allow a toplevel window or the widget
             * itself to be managed.
             */
            parent = Tk_Parent(win);
            for (ancestor = wi->win; ; ancestor = Tk_Parent(ancestor)) {
              if (ancestor == parent) {
                break;
              }
              if (((Tk_FakeWin *) (ancestor))->flags & TK_TOP_LEVEL) {
              badWindow:
                Tcl_AppendResult(wi->interp, "can't use ",
                                 Tk_PathName(win),
                                 " in a window item of this zinc widget",
                                 (char *) NULL);
                win = NULL;
                return TCL_ERROR;
              }
            }
            if (((Tk_FakeWin *) (win))->flags & TK_TOP_LEVEL) {
              goto badWindow;
            }
            if (win == wi->win) {
              goto badWindow;
            }
            if (win != *((Tk_Window *) valp)) {
              *((Tk_Window *) valp) = win;
              *flags |= desc->flags;
            }
          }
        }
      }
      break;
    case ZN_CONFIG_CHAR:
    case ZN_CONFIG_UCHAR:
    case ZN_CONFIG_ALPHA:
      {
        int integer;
        if (Tcl_GetIntFromObj(wi->interp, args[i+1], &integer) == TCL_ERROR) {
          return TCL_ERROR;
        }
        switch (desc->type) {
        case ZN_CONFIG_UCHAR:
          if (integer < 0) {
            integer = 0;
          }
        case ZN_CONFIG_ALPHA:
          if (integer < 0) {
            integer = 0;
          }
          if (integer > 100) {
            integer = 100;
          }
          break;
        }
        if (integer != *((char *) valp)) {
          *((char *) valp) = integer;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_SHORT:
    case ZN_CONFIG_USHORT:
      {
        int integer;
        if (Tcl_GetIntFromObj(wi->interp, args[i+1], &integer) == TCL_ERROR) {
          return TCL_ERROR;
        }
        if (desc->type == ZN_CONFIG_SHORT) {
          if (integer < SHRT_MIN) {
            integer = SHRT_MIN;
          }
          else if (integer > SHRT_MAX) {
            integer = SHRT_MAX;
          }
          if (integer != *((short *) valp)) {
            *((short *) valp) = integer;
            *flags |= desc->flags;
          }
        }
        else {
          if (integer < 0) {
            integer = 0;
          }
          else if (integer > USHRT_MAX) {
            integer = USHRT_MAX;
          }
          if (integer != *((unsigned short *) valp)) {
            *((unsigned short *) valp) = integer;
            *flags |= desc->flags;
          }
        }
        break;
      }
    case ZN_CONFIG_INT:
    case ZN_CONFIG_UINT:
      {
        int integer;
        if (Tcl_GetIntFromObj(wi->interp, args[i+1], &integer) == TCL_ERROR) {
          return TCL_ERROR;
        }
        if ((desc->type == ZN_CONFIG_UINT) &&  (integer < 0)) {
            integer = 0;
        }
        if (integer != *((int *) valp)) {
          *((int *) valp) = integer;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_FILL_RULE:
      {
        ZnFillRule fill_rule;

        if (ZnGetFillRule(wi, Tcl_GetString(args[i+1]), &fill_rule) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " fill rule expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (fill_rule != *((ZnFillRule *) valp)) {
          *((ZnFillRule *) valp) = fill_rule;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_ALIGNMENT:
      {
        Tk_Justify justify;
        if (Tk_GetJustify(wi->interp, Tcl_GetString(args[i+1]), &justify) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " justify expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (justify != *((Tk_Justify *) valp)) {
          *((Tk_Justify *) valp) = justify;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_ANCHOR:
      {
        Tk_Anchor       anchor;
        if (Tk_GetAnchor(wi->interp, Tcl_GetString(args[i+1]), &anchor) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " anchor expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (anchor != *((Tk_Anchor *) valp)) {
          *((Tk_Anchor *) valp) = anchor;
          *flags |= desc->flags;
        }
        break;
      }
    case ZN_CONFIG_LABEL_FORMAT:
      {
        ZnLabelFormat frmt = NULL;

        str = Tcl_GetString(args[i+1]);
        while (*str && (*str == ' ')) {
          str++;
        }
        if (strlen(str) != 0) {
          frmt = ZnLFCreate(wi->interp, str,
                            ZnFIELD.NumFields(item->class->GetFieldSet(item)));
          if (frmt == NULL) {
            return TCL_ERROR;
          }
        }

        if (*((ZnLabelFormat *) valp) != NULL) {
          ZnLFDelete(*((ZnLabelFormat *) valp));
          *((ZnLabelFormat *) valp) = frmt;
          *flags |= desc->flags;
        }
        else {
          if (frmt != NULL) {
            *((ZnLabelFormat *) valp) = frmt;
            *flags |= desc->flags;
          }
        }
        break;
      }

    case ZN_CONFIG_AUTO_ALIGNMENT:
      {
        ZnAutoAlign aa;

        if (ZnGetAutoAlign(wi, Tcl_GetString(args[i+1]), &aa) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " auto alignment expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if ((aa.automatic != ((ZnAutoAlign *) valp)->automatic) ||
            (aa.align[0] != ((ZnAutoAlign *) valp)->align[0]) ||
            (aa.align[1] != ((ZnAutoAlign *) valp)->align[1]) ||
            (aa.align[2] != ((ZnAutoAlign *) valp)->align[2])) {
          *((ZnAutoAlign *) valp) = aa;
          *flags |= desc->flags;
        }
        break;
      }

    case ZN_CONFIG_LEADER_ANCHORS:
      {
        ZnLeaderAnchors lanch = NULL;
        if (ZnGetLeaderAnchors(wi, Tcl_GetString(args[i+1]), &lanch) == TCL_ERROR) {
          Tcl_AppendResult(wi->interp, " leader anchors expected for attribute \"",
                           Tcl_GetString(args[i]), "\"", NULL);
          return TCL_ERROR;
        }
        if (*((ZnLeaderAnchors *) valp) != NULL) {
          ZnFree(*((ZnLeaderAnchors *) valp));
          *((ZnLeaderAnchors *) valp) = lanch;
          *flags |= desc->flags;
        }
        else {
          if (lanch != NULL) {
            *((ZnLeaderAnchors *) valp) = lanch;
            *flags |= desc->flags;
          }
        }
        break;
      }
    }
  }

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * AttributeToObj --
 *
 *      Returns the obj representation of the attribute pointed
 *      by 'valp'. The attribute type is given by 'type'. The function
 *      never fail.
 *
 **********************************************************************************
 */
static Tcl_Obj *
AttributeToObj(Tcl_Interp       *interp,
               void             *record,
               ZnAttrConfig     *desc)
{
  char          *valp = ((char *) record) + desc->offset;
  char          *str = "";
  Tcl_Obj       *o, *obj;
  unsigned int  i;
  char          buffer[256];

  switch (desc->type) {
  case ZN_CONFIG_GRADIENT:
    if (*((ZnGradient **) valp)) {
      str = ZnNameOfGradient(*((ZnGradient **) valp));
    }
    break;
  case ZN_CONFIG_GRADIENT_LIST:
    {
      unsigned int num_grads;
      ZnGradient   **grads;

      if (*((ZnList *) valp)) {
        grads = ZnListArray(*((ZnList *) valp));
        num_grads = ZnListSize(*((ZnList *) valp));
        
        obj = Tcl_NewObj();
        for (i = 0; i < num_grads; i++) {
          o = Tcl_NewStringObj(ZnNameOfGradient(grads[i]), -1);
          Tcl_ListObjAppendElement(interp, obj, o);
        }
        return obj;
      }
    }
    break;
  case ZN_CONFIG_BOOL:
    return Tcl_NewBooleanObj(ISSET(*((unsigned short *) valp), desc->bool_bit)?1:0);
  case ZN_CONFIG_IMAGE:
    if (*((ZnImage *) valp)) {
      str = ZnNameOfImage(*((ZnImage *) valp));
#if PTK
      // Just return the perl image object, it is far more
      // useful than the mere string name.
      return LangObjectObj(interp, str);
#endif
    }
    break;
  case ZN_CONFIG_BITMAP:
    if (*((ZnImage *) valp)) {
      str = ZnNameOfImage(*((ZnImage *) valp));
    }
    break;
  case ZN_CONFIG_BITMAP_LIST:
    {
      unsigned int num_pats=0;
      ZnImage      *pats;

      if (*((ZnList *) valp)) {
        pats = (ZnImage *) ZnListArray(*((ZnList *) valp));
        num_pats = ZnListSize(*((ZnList *) valp));

        obj = Tcl_NewObj();
        for (i = 0; i < num_pats; i++) {
          if (pats[i] != ZnUnspecifiedImage) {
            o = Tcl_NewStringObj(ZnNameOfImage(pats[i]), -1);
          }
          else {
            o = Tcl_NewStringObj("", -1);
          }
          Tcl_ListObjAppendElement(interp, obj, o);
        }
        return obj;
      }
      break;
    }
  case ZN_CONFIG_TAG_LIST:
    {
      unsigned int num_tags=0;
      Tk_Uid       *tags;

      if (*((ZnList *) valp)) {
        tags = (Tk_Uid *) ZnListArray(*((ZnList *) valp));
        num_tags = ZnListSize(*((ZnList *) valp));
        obj = Tcl_NewObj();
        for (i = 0; i < num_tags; i++) {
          Tcl_ListObjAppendElement(interp, obj,
                                   Tcl_NewStringObj(tags[i], -1));
        }
        return obj;
      }
      break;
    }
  case ZN_CONFIG_STRING:
  case ZN_CONFIG_MAP_INFO:
    if (*((char **) valp)) {
      str = *((char **) valp);
    }
    break;
  case ZN_CONFIG_FONT:
    if (*((Tk_Font *) valp)) {
      str = (char *) Tk_NameOfFont(*((Tk_Font *) valp));
    }
    break;
  case ZN_CONFIG_EDGE_LIST:
    str = buffer;
    ZnNameOfBorder(*((ZnBorder *) valp), buffer);
    break;
  case ZN_CONFIG_LINE_SHAPE:
    str = ZnNameOfLineShape(*((ZnLineShape *) valp));
    break;
  case ZN_CONFIG_FILL_RULE:
    str = ZnNameOfFillRule(*((ZnFillRule *) valp));
    break;
  case ZN_CONFIG_LINE_STYLE:
    str = ZnNameOfLineStyle(*((ZnLineStyle *) valp));
    break;
  case ZN_CONFIG_LINE_END:
    if (*((ZnLineEnd *) valp)) {
      str = ZnLineEndGetString(*((ZnLineEnd *) valp));
    }
    break;
  case ZN_CONFIG_RELIEF:
    str = ZnNameOfRelief(*((ZnReliefStyle *) valp));
    break;
  case ZN_CONFIG_JOIN_STYLE:
    str = (char *) Tk_NameOfJoinStyle(*((int *) valp));
    break;
  case ZN_CONFIG_CAP_STYLE:
    str = (char *) Tk_NameOfCapStyle(*((int *) valp));
    break;
  case ZN_CONFIG_POINT:
    obj = Tcl_NewObj();
    Tcl_ListObjAppendElement(interp, obj, Tcl_NewDoubleObj(((ZnPoint *) valp)->x));
    Tcl_ListObjAppendElement(interp, obj, Tcl_NewDoubleObj(((ZnPoint *) valp)->y));
    return obj;
  case ZN_CONFIG_ITEM:
    if (*((ZnItem *) valp) != ZN_NO_ITEM) {
      return Tcl_NewLongObj((int) (*((ZnItem *) valp))->id);
    }
    break;
  case ZN_CONFIG_WINDOW:
    if (*((Tk_Window *) valp) != NULL) {
      str = Tk_PathName(*((Tk_Window *) valp));
    }
    break;
  case ZN_CONFIG_CHAR:
    return Tcl_NewIntObj(*((char *) valp));
  case ZN_CONFIG_UCHAR:
  case ZN_CONFIG_ALPHA:
    return Tcl_NewIntObj(*((unsigned char *) valp));
  case ZN_CONFIG_USHORT:
  case ZN_CONFIG_PRI:
    return Tcl_NewIntObj(*((unsigned short *) valp));
  case ZN_CONFIG_SHORT:
     return Tcl_NewIntObj(*((short *) valp));
  case ZN_CONFIG_UINT:
    return Tcl_NewIntObj(*((unsigned int *) valp));
  case ZN_CONFIG_INT:
    return Tcl_NewIntObj(*((int *) valp));
  case ZN_CONFIG_ANGLE:
    return Tcl_NewDoubleObj(*((int *) valp));
  case ZN_CONFIG_DIM:
    return Tcl_NewDoubleObj(*((ZnDim *) valp));
  case ZN_CONFIG_ALIGNMENT:
    str = (char *) Tk_NameOfJustify(*((Tk_Justify *) valp));
    break;
  case ZN_CONFIG_ANCHOR:
    str = (char *) Tk_NameOfAnchor(*((Tk_Anchor *) valp));
    break;
  case ZN_CONFIG_LABEL_FORMAT:
    if (*((ZnLabelFormat *) valp)) {
      str = ZnLFGetString(*((ZnLabelFormat *) valp));
    }
    break;
  case ZN_CONFIG_AUTO_ALIGNMENT:
    str = buffer;
    ZnNameOfAutoAlign((ZnAutoAlign *) valp, buffer);
    break;
  case ZN_CONFIG_LEADER_ANCHORS:
    str = buffer;
    ZnNameOfLeaderAnchors(*((ZnLeaderAnchors *) valp), buffer);
    break;
  }
  return Tcl_NewStringObj(str, -1);
}


/*
 **********************************************************************************
 *
 * ZnQueryAttribute --
 *
 **********************************************************************************
 */
int
ZnQueryAttribute(Tcl_Interp     *interp,
                 void           *record,
                 ZnAttrConfig   *desc_table,
                 Tcl_Obj        *attr_name)
{
  ZnAttrConfig  *desc = GetAttrDesc(interp, attr_name, desc_table);
  
  if (!desc) {
    return TCL_ERROR;
  }
  Tcl_SetObjResult(interp, AttributeToObj(interp, record, desc));

  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * ZnItemClassList --
 *
 **********************************************************************************
 */
ZnList
ZnItemClassList()
{
  return item_classes;
}

/*
 **********************************************************************************
 *
 * ZnLookupItemClass --
 *
 **********************************************************************************
 */
ZnItemClass
ZnLookupItemClass(char  *class_name)
{
  ZnItemClass   *class;
  int           i, num_classes;

  class = (ZnItemClass *) ZnListArray(item_classes);
  num_classes = ZnListSize(item_classes);
  for (i = 0; i < num_classes; i++) {
    if (strcmp((class[i])->name, class_name) == 0) {
      return class[i];
    }
  }
  
  return NULL;
}

/*
 **********************************************************************************
 *
 * ZnAddItemClass --
 *
 **********************************************************************************
 */
void
ZnAddItemClass(ZnItemClass      class)
{
  if (!ZnLookupItemClass(class->name)) {
    ZnListAdd(item_classes, &class, ZnListTail);
    InitAttrDesc(class->attr_desc);
  }
}

/*
 **********************************************************************************
 *
 * ZnItemInit --
 *      Initialize classes static state.
 *
 **********************************************************************************
 */
void
ZnItemInit()
{
  /* First check if static part already inited */
  if (item_classes == NULL) {
    item_classes = ZnListNew(16, sizeof(ZnItemClass));
#ifdef ATC
    ZnAddItemClass(ZnTrack);
    ZnAddItemClass(ZnWayPoint);
    ZnAddItemClass(ZnMap);
    ZnAddItemClass(ZnReticle);
#endif
    ZnAddItemClass(ZnTabular);
    ZnAddItemClass(ZnRectangle);
    ZnAddItemClass(ZnArc);
    ZnAddItemClass(ZnCurve);
    ZnAddItemClass(ZnTriangles);
    ZnAddItemClass(ZnGroup);
    ZnAddItemClass(ZnIcon);
    ZnAddItemClass(ZnText);
    ZnAddItemClass(ZnWindow);
    InitAttrDesc(ZnFIELD.attr_desc);
  }
}


/*
 **********************************************************************************
 *
 * UpdateItemDependency -- Method
 *      Update the group dependency list following a change in the
 *      connection of an item.
 *
 **********************************************************************************
 */
static void
UpdateItemDependency(ZnItem     item,
                     ZnItem     old_connection)
{
  if (old_connection == ZN_NO_ITEM) {
    /* Add a connection */
    ZnInsertDependentItem(item);
  }
  else if (item->connected_item == ZN_NO_ITEM) {
    /* Remove a connection */
    ZnExtractDependentItem(item);
  }
  else {
    /* Move at end to ensure that it will be updated after
     * the (new) item it depends upon.
     */
    ZnExtractDependentItem(item);
    ZnInsertDependentItem(item);
  }
}


/*
 **********************************************************************************
 *
 * ExtractItem --
 *      Extract an item from its context, includes updating graphic
 *      state flags.
 *
 **********************************************************************************
 */
static void
ExtractItem(ZnItem      item)
{
  ZnWInfo       *wi = item->wi;
  ZnItem        group = item->parent;

  /* damage bounding boxes */
  if (ISSET(item->flags, ZN_VISIBLE_BIT)) {
    ZnDamage(wi, &item->item_bounding_box);
  }
  
  /*
   * Tell that we need to repick
   */
  if (item->class != ZnGroup) {
    SET(wi->flags, ZN_INTERNAL_NEED_REPICK);
  }

  if (group != ZN_NO_ITEM) {
    /* Remove me from dependency list. */
    ZnExtractDependentItem(item);
    
    /* Disconnect all dependents on me. */
    ZnDisconnectDependentItems(item);
    /*
     * Remove me as a clip item.
     */
    ZnGroupRemoveClip(group, item);
    /*
     * Remove me from item list.
     */
    ZnGroupExtractItem(item);
  }
}


/*
 **********************************************************************************
 *
 * InsertItem -- Method
 *
 *      Insert an item in the display list according to its priority.
 *      It is inserted in front of items of lower or same priority. If
 *      mark_item is not ZN_NO_ITEM the insertion is done relative
 *      to this item, before it if 'before' is True, after it otherwise.
 *      mark_item must be in the group 'group'.
 *
 **********************************************************************************
 */
static void
InsertItem(ZnItem       item,
           ZnItem       grp,
           ZnItem       mark_item,
           ZnBool       before)
{
  if (!grp) {
    grp = item->wi->top_group;
  }
  item->parent = grp;
  
  if (mark_item && (mark_item->parent != grp)) {
    mark_item = ZN_NO_ITEM;
  }
  
  ZnGroupInsertItem(grp, item, mark_item, before);
}


/*
 **********************************************************************************
 *
 * UpdateItemPriority -- Method
 *      Reorder a group's item list following a change in an
 *      item priority or a call to lower/raise.
 *
 **********************************************************************************
 */
static void
UpdateItemPriority(ZnItem       item,
                   ZnItem       mark_item,
                   ZnBool       before)
{
  ZnItem        parent = item->parent;
  
  ZnGroupExtractItem(item);
  InsertItem(item, parent, mark_item, before);
  Invalidate(item, ZN_DRAW_FLAG);
  SET(item->wi->flags, ZN_INTERNAL_NEED_REPICK);
}


/*
 **********************************************************************************
 *
 * SetId,
 * FreeId -- Method
 *      Get a fresh object id from the widget and enter the new
 *      object with this id in the object hash table. The id is
 *      incremented. FreeId on the other hand suppress the item
 *      from the hash table and set its object id to zero.
 *
 **********************************************************************************
 */
static void
SetId(ZnItem    item)
{
  ZnWInfo       *wi = item->wi;
  Tcl_HashEntry *entry;
  int           dummy;

  item->id = wi->obj_id;
  wi->obj_id++;
  entry = Tcl_CreateHashEntry(wi->id_table, (char *) item->id, &dummy);
  Tcl_SetHashValue(entry, item);  
}

static void
FreeId(ZnItem   item)
{
  Tcl_HashEntry *entry;
  
  if (item->id) {
    entry = Tcl_FindHashEntry(item->wi->id_table, (char *) item->id);
    if (entry) {
      Tcl_DeleteHashEntry(entry);
      item->id = 0;
    }
  }
}

/*
 **********************************************************************************
 *
 * AddTag -- Method
 *      Add a tag to the item. If the tag is already on the list it
 *      is not added. As a side effect the tag/item pair is added to
 *      the tag table of the widget.
 *      'tag' must be a Tk_Uid.
 *
 **********************************************************************************
 */
static void
AddTag(ZnItem   item,
       Tk_Uid   tag)
{
  int   num, i;
  char  **ptr;
  
  /*
   * No tags yet.
   */
  if (!item->tags) {
    item->tags = ZnListNew(1, sizeof(char *));
  }
  else {
    /*
     * If the tag is already there, that's done.
     */
    ptr = (char **) ZnListArray(item->tags);
    num = ZnListSize(item->tags);
    for (i = 0; i < num; i++) {
      if (ptr[i] == tag) {
        return;
      }
    }
  }
  /*
   * Add it.
   */
  ZnListAdd(item->tags, (void *) &tag, ZnListTail);
}

/*
 **********************************************************************************
 *
 * RemoveTag -- Method
 *
 **********************************************************************************
 */
static void
RemoveTag(ZnItem        item,
          Tk_Uid        tag)
{
  unsigned int  indx, num;
  char          **ptr;
  
  if (!item->tags) {
    return;
  }
  /*
   * look up the tag in the list.
   */
  ptr = (char **) ZnListArray(item->tags);
  num = ZnListSize(item->tags);
  for (indx = 0; indx < num; indx++) {
    if (ptr[indx] == tag) {
      /* The tag list is not freed when empty to avoid
       * overhead when using tags intensively. */
      ZnListDelete(item->tags, indx);
      return;
    }
  }
}

/*
 **********************************************************************************
 *
 * FreeTags -- Method
 *
 **********************************************************************************
 */
static void
FreeTags(ZnItem item)
{
  if (!item->tags) {
    return;
  }
  ZnListFree(item->tags);
  item->tags = NULL;
}


/*
 **********************************************************************************
 *
 * HasTag -- Method
 *
 **********************************************************************************
 */
static ZnBool
HasTag(ZnItem   item,
       Tk_Uid   tag)
{
  int           num;
  Tk_Uid        *tags;

  if (!item->tags || !ZnListSize(item->tags)) {
    return False;
  }
  else {
    num = ZnListSize(item->tags);
    tags = ZnListArray(item->tags);
    for (tags = ZnListArray(item->tags); num > 0; tags++, num--) {
      if (*tags == tag) {
        return True;
      }
    }
  }
  return False;
}


/*
 **********************************************************************************
 *
 * ZnCreateItem --
 *
 *      InsertItem and ConfigureItem must be called after CreateItem
 *      to finalize the setup of a new item. This is so even if
 *      there are no attributes to be changed after creation.
 *      ConfigureItem must be called in this case with the 'init'
 *      parameter set to True.
 *
 **********************************************************************************
 */
ZnItem
ZnCreateItem(ZnWInfo        *wi,
             ZnItemClass   item_class,
             int            *argc,
             Tcl_Obj *CONST *args[])
{
  ZnItem        item;

  item = ZnMalloc(item_class->size);
  
  /* Initialize common state */
  item->class = item_class;
  item->wi = wi;
  item->parent = NULL;
  item->previous = ZN_NO_ITEM;
  item->next = ZN_NO_ITEM;
  CLEAR(item->flags, ZN_UPDATE_DEPENDENT_BIT);
  item->inv_flags = 0;
  item->transfo = NULL;
  item->parent = NULL;
  item->connected_item = ZN_NO_ITEM;
#ifdef GL
#ifdef GL_LIST
  item->gl_list = 0;
#endif
#endif
  ZnResetBBox(&item->item_bounding_box);

  /* Init item specific attributes */
  if (item_class->Init(item, argc, args) == TCL_ERROR) {
    ZnFree(item);
    return ZN_NO_ITEM;
  }

  SetId(item);
  item->tags = NULL;
  
  SET(wi->flags, ZN_INTERNAL_NEED_REPICK);
  wi->num_items++;

  return (item);
}


/*
 **********************************************************************************
 *
 * CloneItem -- Method
 *      Can't clone the top level group.
 *
 **********************************************************************************
 */
static ZnItem
CloneItem(ZnItem        model)
{
  ZnWInfo       *wi = model->wi;
  ZnItem        item;
  Tk_Uid        *tags;
  unsigned int  num_tags;
  int           i;
  
  if (!model->parent) {
    return ZN_NO_ITEM;
  }
  
  item = ZnMalloc(model->class->size);
  memcpy(item, model, model->class->size);

  item->previous = ZN_NO_ITEM;
  item->next = ZN_NO_ITEM;
  item->connected_item = ZN_NO_ITEM;
  CLEAR(item->flags, ZN_UPDATE_DEPENDENT_BIT);
  item->inv_flags = 0;
  SetId(item);

  if (model->tags) {
    item->tags = NULL;
    tags = (Tk_Uid *) ZnListArray(model->tags);
    num_tags = ZnListSize(model->tags);
    for (i = num_tags-1; i >= 0; i--, tags++) {
      AddTag(item, *tags);
    }
  }

  if (item->transfo) {
    item->transfo = ZnTransfoDuplicate(item->transfo);
  }
  
  /* Call item's clone to duplicate non shared resources */
  item->class->Clone(item);

  SET(wi->flags, ZN_INTERNAL_NEED_REPICK);
  wi->num_items++;

  Invalidate(item, ZN_COORDS_FLAG);

  return item;
}


/*
 **********************************************************************************
 *
 * ConfigureItem -- Method
 *
 **********************************************************************************
 */
static int
ConfigureItem(ZnItem            item,
              int               field,
              int               argc,
              Tcl_Obj   *CONST  argv[],
              ZnBool            init)
{
  ZnWInfo       *wi = item->wi;
  int           flags;
  ZnBool        previous_visible = init ? False : ISSET(item->flags, ZN_VISIBLE_BIT);

  flags = 0;
  ASSIGN(flags, ZN_COORDS_FLAG, init);
  if (argv) {
    if (field < 0){
      if (item->class->Configure(item, argc, argv, &flags) == TCL_ERROR) {
        return TCL_ERROR;
      }
      if (item->class->GetFieldSet && ISSET(flags, ZN_CLFC_FLAG)) {
        ZnFIELD.ClearFieldCache(item->class->GetFieldSet(item), -1);
      }
    }
    else if (item->class->GetFieldSet) {
      if (ZnFIELD.ConfigureField(item->class->GetFieldSet(item),
                                 field, argc, argv, &flags) == TCL_ERROR) {
        return TCL_ERROR;
      }
    }
    else {
      return TCL_ERROR;
    }
  }

  if (previous_visible && ISCLEAR(item->flags, ZN_VISIBLE_BIT)) {
    /*
     * Special case when the item has its visibility
     * just turned out.
     */
    ZnDamage(wi, &item->item_bounding_box);
  }
  
  Invalidate(item, flags);
  
  return TCL_OK;
}


/*
 **********************************************************************************
 *
 * QueryItem -- Method
 *
 **********************************************************************************
 */
static int
QueryItem(ZnItem                item,
          int                   field,
          int                   argc,
          Tcl_Obj *CONST        argv[])
{
  if (field < 0) {
    return item->class->Query(item, argc, argv);
  }
  else if (item->class->GetFieldSet) {
    return ZnFIELD.QueryField(item->class->GetFieldSet(item),
                              field, argc, argv);
  }
  
  return TCL_ERROR;
}


/*
 **********************************************************************************
 *
 * ComposeTransform --
 *      Compose a transform transfo with current_t to new_t.
 *
 **********************************************************************************
 */
static void
ComposeTransform(ZnTransfo      *transfo,
                 ZnPoint        *pos,
                 ZnTransfo      *current_t,
                 ZnTransfo      *new_t,
                 ZnBool         compose_scale,
                 ZnBool         compose_rot)
{
  ZnBool        full;
  ZnTransfo     t, t2;

  full = compose_scale && compose_rot;
  
  if (!transfo && !pos && full) {
    *new_t = *current_t;
    return;
  }
  if (full) {
    /*
     * Full concatenation.
     */
    /*ZnPrintTransfo(transfo);*/
    if (pos) {
      if (!transfo) {
        ZnTransfoSetIdentity(&t);
      }
      else {
        t = *transfo;
      }
      ZnTranslate(&t, pos->x, pos->y, False);
      ZnTransfoCompose(new_t, &t, current_t);
    }
    else {
      ZnTransfoCompose(new_t, transfo, current_t);
    }
  }
  else {
    ZnPoint     scale, trans, local_scale, local_trans, p;
    ZnReal      local_rot, rot;
    
    ZnTransfoSetIdentity(new_t);
    ZnTransfoDecompose(transfo, &local_scale, &local_trans, &local_rot, NULL);
    ZnScale(new_t, local_scale.x, local_scale.y);
    ZnRotateRad(new_t, local_rot);

    ZnTransfoDecompose(current_t, &scale, &trans, &rot, NULL);

    if (pos) {
      ZnTransfoSetIdentity(&t);
      ZnTranslate(&t, pos->x, pos->y, False);
      ZnTransfoCompose(&t2, &t, current_t);
      ZnTransformPoint(&t2, &local_trans, &p);
    }
    else {
      ZnTransformPoint(current_t, &local_trans, &p);
    }

    if (compose_scale) {
      ZnScale(new_t, scale.x, scale.y);
    }
    if (compose_rot) {
      ZnRotateRad(new_t, rot);
    }
    ZnTranslate(new_t, p.x, p.y, False);
  }
}


/*
 **********************************************************************************
 *
 * GetItemTransform -- Method
 *      Compute the current transform for an item.
 *
 **********************************************************************************
 */
static void
GetItemTransform(ZnItem         item,
                 ZnTransfo      *t)
{
  ZnItem        *items;
  int           i;
  ZnTransfo     t_tmp, *t1, *t2, *swap;
  ZnPoint       *pos;

  if (item_stack == NULL) {
    item_stack = ZnListNew(16, sizeof(ZnItem));
  }
  else {
    ZnListEmpty(item_stack);
  }
  
  while (item != ZN_NO_ITEM) {
    ZnListAdd(item_stack, &item, ZnListTail);
    item = item->parent;
  }
  
  ZnTransfoSetIdentity(t);
  t1 = t;
  t2 = &t_tmp;
  items = (ZnItem *) ZnListArray(item_stack);
  for (i = ZnListSize(item_stack)-1; i >= 0; i--) {
    pos = NULL;
    if (items[i]->class->pos_offset >= 0) {
      pos = (ZnPoint *) (((char *) items[i]) + items[i]->class->pos_offset);
      if (pos->x == 0 && pos->y == 0) {
        pos = NULL;
      }
    }
    ComposeTransform(items[i]->transfo, pos, t1, t2,
                     ISSET(items[i]->flags, ZN_COMPOSE_SCALE_BIT),
                     ISSET(items[i]->flags, ZN_COMPOSE_ROTATION_BIT));
    swap = t2;
    t2 = t1;
    t1 = swap;
  }
  if (t1 != t) {
    *t = *t1;
  }
}



/*
 **********************************************************************************
 *
 * ZnResetTransformStack
 * ZnInitTransformStack
 * ZnFreeTransformStack
 * ZnCurrentTransform
 * ZnPushTransform
 * ZnPopTransform --
 *
 **********************************************************************************
 */
void
ZnResetTransformStack(ZnWInfo   *wi)
{
  ZnListAssertSize(wi->transfo_stack, 1);
  wi->current_transfo = (ZnTransfo *) ZnListAt(wi->transfo_stack, 0);
  ZnTransfoSetIdentity(wi->current_transfo);
}

void
ZnInitTransformStack(ZnWInfo    *wi)
{
  wi->transfo_stack = ZnListNew(8, sizeof(ZnTransfo));
  ZnResetTransformStack(wi);
}

void
ZnFreeTransformStack(ZnWInfo    *wi)
{
  ZnListFree(wi->transfo_stack);
}

void
ZnPushTransform(ZnWInfo         *wi,
                ZnTransfo       *transfo,
                ZnPoint         *pos,
                ZnBool          compose_scale,
                ZnBool          compose_rot)
{
  ZnTransfo     *next_t;
  unsigned int  num_t;

  /*
   * Push the current transform and concatenate
   * the new transform taking into account the
   * combination flags.
   */
  num_t = ZnListSize(wi->transfo_stack);
  ZnListAssertSize(wi->transfo_stack, num_t+1);
  next_t = (ZnTransfo *) ZnListAt(wi->transfo_stack, num_t);
  ComposeTransform(transfo, pos, wi->current_transfo, next_t,
                   compose_scale, compose_rot);
  wi->current_transfo = next_t;
}

void
ZnPopTransform(ZnWInfo  *wi)
{
  /*
   * Restore the previous transform.
   */
  ZnListDelete(wi->transfo_stack, ZnListTail);
  wi->current_transfo = (ZnTransfo *) ZnListAt(wi->transfo_stack, ZnListTail);
}


/*
 **********************************************************************************
 *
 * ZnResetClipStack
 * ZnInitClipStack
 * ZnFreeClipStack
 * ZnCurrentClip
 * ZnPushClip
 * ZnPopClip --
 *
 **********************************************************************************
 */
/*
 * Describe the clipping at a given node
 * of the item hierarchy.
 */
typedef struct _ClipState {
  ZnBool        simple;         /* The clip is an aligned rectangle.    */
  TkRegion      region;         /* The region used to draw and to       */
                                /* probe for picking.                   */
  ZnBBox        clip_box;       /* The bounding box of the clip area.   */
} ClipState;

void
ZnResetClipStack(ZnWInfo        *wi)
{
  int           i;
  ClipState     *clips = (ClipState *) ZnListArray(wi->clip_stack);
  
  /*
   * Should not happen, clip stack should be
   * empty when this function is called.
   */
  for (i = ZnListSize(wi->clip_stack)-1; i >= 0; i--) {
    TkDestroyRegion(clips[i].region);
  }
  ZnListEmpty(wi->clip_stack);
  wi->current_clip = NULL;
}

void
ZnInitClipStack(ZnWInfo *wi)
{
  wi->clip_stack = ZnListNew(8, sizeof(ClipState));
  ZnResetClipStack(wi);  
}

void
ZnFreeClipStack(ZnWInfo *wi)
{
  ZnListFree(wi->clip_stack);
}

ZnBool
ZnCurrentClip(ZnWInfo   *wi,
              TkRegion  *reg,
              ZnBBox    **clip_box,
              ZnBool    *simple)
{
  if (wi->current_clip) {
    if (reg) {
      *reg = wi->current_clip->region;
    }
    if (clip_box) {
      *clip_box = &wi->current_clip->clip_box;
    }
    if (simple) {
      *simple = wi->current_clip->simple;
    }
    return True;
  }
  
  return False;
}

/*
 * If simple is True poly is a pointer to an
 * array of two points. In the other case it
 * is a regular pointer to a multi contour poly.
 */
void
ZnPushClip(ZnWInfo      *wi,
           ZnTriStrip   *tristrip,
           ZnBool       simple,
           ZnBool       set_gc)
{
  unsigned int  i, j, num_clips;
  unsigned int  num_pts, max_num_pts;
  ZnPoint       *p;
  ClipState     *previous_clip=NULL;
  TkRegion      reg, reg_op, reg_to;
  XRectangle    rect;
  XPoint        xpts[3];
  
  if (tristrip->num_strips == 0) {
    return;
  }
  max_num_pts = tristrip->strips[0].num_points;
  for (j = 0; j < tristrip->num_strips; j++) {
    num_pts = tristrip->strips[j].num_points;
    if (num_pts > max_num_pts) {
      num_pts = max_num_pts;
    }
  }
  if ((simple && (max_num_pts < 2)) ||
      (!simple && (max_num_pts < 3))) {
    return;
  }
  
  num_clips = ZnListSize(wi->clip_stack);
  /*  printf("PushClip: num clips %d\n", num_clips);fflush(stdout);*/
  if (num_clips != 0) {
    previous_clip = (ClipState *) ZnListAt(wi->clip_stack, ZnListTail);
  }
  ZnListAssertSize(wi->clip_stack, num_clips+1);
  wi->current_clip = (ClipState *) ZnListAt(wi->clip_stack, ZnListTail);
  wi->current_clip->simple = simple;

  /*
   * Compute the local region.
   */
  if (simple) {
    rect.x = (short) tristrip->strips[0].points[0].x;
    rect.y = (short) tristrip->strips[0].points[0].y;
    rect.width = ((unsigned short) (tristrip->strips[0].points[1].x -
                                    tristrip->strips[0].points[0].x));
    rect.height = ((unsigned short) (tristrip->strips[0].points[1].y -
                                     tristrip->strips[0].points[0].y));
    reg = TkCreateRegion();
    TkUnionRectWithRegion(&rect, reg, reg);
    /*printf("Adding a simple clip: %d, %d, %d, %d\n",
      rect.x, rect.y, rect.width, rect.height);*/
  }
  else {
    reg = TkCreateRegion();
    for (j = 0; j < tristrip->num_strips; j++) {
      num_pts = tristrip->strips[j].num_points;
      p = tristrip->strips[j].points;
      if (tristrip->strips[j].fan) {
        xpts[0].x = ZnNearestInt(p->x);
        xpts[0].y = ZnNearestInt(p->y);
        p++;
        xpts[1].x = ZnNearestInt(p->x);
        xpts[1].y = ZnNearestInt(p->y);
        p++;
        for (i = 2; i < num_pts; i++, p++) {
          xpts[2].x = ZnNearestInt(p->x);
          xpts[2].y = ZnNearestInt(p->y);
          reg_op = (TkRegion) ZnPolygonRegion(xpts, 3, EvenOddRule);
          reg_to = TkCreateRegion();
          ZnUnionRegion(reg, reg_op, reg_to);
          TkDestroyRegion(reg);
          TkDestroyRegion(reg_op);
          reg = reg_to;
          xpts[1] = xpts[2];
        }
      }
      else {
        xpts[0].x = (short) p->x;
        xpts[0].y = (short) p->y;
        p++;
        xpts[1].x = (short) p->x;
        xpts[1].y = (short) p->y;
        p++;
        for (i = 2 ; i < num_pts; i++, p++) {
          xpts[2].x = (short) p->x;
          xpts[2].y = (short) p->y;     
          reg_op = (TkRegion) ZnPolygonRegion(xpts, 3, EvenOddRule);
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
  }
  
  /*
   * Combine with previous region if any.
   */
  if (previous_clip) {
    wi->current_clip->region = TkCreateRegion();
    TkIntersectRegion(reg, previous_clip->region, wi->current_clip->region);
    TkDestroyRegion(reg);
    /*printf("Merging with previous clip\n");*/
  }
  else {
    wi->current_clip->region = reg;
  }
  TkClipBox(wi->current_clip->region, &rect);
  wi->current_clip->clip_box.orig.x = rect.x;
  wi->current_clip->clip_box.orig.y = rect.y;
  wi->current_clip->clip_box.corner.x = rect.x + rect.width;
  wi->current_clip->clip_box.corner.y = rect.y + rect.height;

  /*
   * Set the clipping in the GC. 
   */
  if (set_gc) {
    if (wi->render) {
#ifdef GL
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      glEnable(GL_STENCIL_TEST);
      glStencilFunc(GL_EQUAL, (GLint) num_clips, 0xFF);      
      glStencilOp(GL_KEEP, GL_INCR, GL_INCR);
      glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
      if (simple) {
        /*      printf("Clip box is : %d, %d, %d, %d, num_clips : %d\n",
                rect.x, rect.y, rect.width, rect.height, num_clips);*/
        glBegin(GL_QUADS);
        glVertex2d(wi->current_clip->clip_box.orig.x, wi->current_clip->clip_box.orig.y);
        glVertex2d(wi->current_clip->clip_box.orig.x, wi->current_clip->clip_box.corner.y);
        glVertex2d(wi->current_clip->clip_box.corner.x, wi->current_clip->clip_box.corner.y);
        glVertex2d(wi->current_clip->clip_box.corner.x, wi->current_clip->clip_box.orig.y);
        glEnd();
      }
      else {
        for (j = 0; j < tristrip->num_strips; j++) {
          num_pts = tristrip->strips[j].num_points;
          p = tristrip->strips[j].points;
          if (tristrip->strips[j].fan) {
            glBegin(GL_TRIANGLE_FAN);
          }
          else {
            glBegin(GL_TRIANGLE_STRIP);
          }
          for (i = 0; i < num_pts; i++, p++) {
            glVertex2d(p->x, p->y);
          }
          glEnd();
        }
      }
      glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
      glStencilFunc(GL_EQUAL, (GLint) (num_clips+1), 0xFF);
      glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);   
#endif
    }
    else {
      TkSetRegion(wi->dpy, wi->gc, wi->current_clip->region);
    }
  }
}

void
ZnPopClip(ZnWInfo       *wi,
          ZnBool        set_gc)
{
  int   num_clips;
  
  if (wi->current_clip == NULL) {
    return;
  }
  
  TkDestroyRegion(wi->current_clip->region);
  ZnListDelete(wi->clip_stack, ZnListTail);
  num_clips = ZnListSize(wi->clip_stack);
  
  if (num_clips != 0) {
    wi->current_clip = (ClipState *) ZnListAt(wi->clip_stack, ZnListTail);
  }
  else {
    wi->current_clip = NULL;
  }

  /*
   * Set the clipping in the GC.
   */
  if (set_gc) {
    if (num_clips != 0) {
      if (wi->render) {
#ifdef GL
        glStencilFunc(GL_EQUAL, (GLint) (num_clips+1), 0xFF);
        glStencilOp(GL_KEEP, GL_DECR, GL_DECR);
        glColorMask(GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE);
#if 0
        if (wi->current_clip->simple) {
#endif
          glBegin(GL_QUADS);
          glVertex2d(wi->current_clip->clip_box.orig.x, wi->current_clip->clip_box.orig.y);
          glVertex2d(wi->current_clip->clip_box.orig.x, wi->current_clip->clip_box.corner.y);
          glVertex2d(wi->current_clip->clip_box.corner.x, wi->current_clip->clip_box.corner.y);
          glVertex2d(wi->current_clip->clip_box.corner.x, wi->current_clip->clip_box.orig.y);
          glEnd();
#if 0
        }
        else {
        }
#endif
        glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
        glStencilFunc(GL_EQUAL, (GLint) num_clips, 0xFF);    
        glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP); 
#endif
      }
      else {
        TkSetRegion(wi->dpy, wi->gc, wi->current_clip->region);
      }
    }
    else {
      /*printf("resetting clip mask\n");*/
      if (wi->render) {
#ifdef GL
        glClear(GL_STENCIL_BUFFER_BIT);
        glDisable(GL_STENCIL_TEST);
#endif
      }
      else {
        XSetClipMask(wi->dpy, wi->gc, None);
      }
    }
  }
  /*printf("PopClip: num clips %d\n", ZnListSize(wi->clip_stack));fflush(stdout);*/
}


/*
 **********************************************************************************
 *
 * Invalidate -- Method
 *
 **********************************************************************************
 */
static void
Invalidate(ZnItem       item,
           int          reason)
{
  /* 
   * Why this test has to be so an abrupt shortcut ?
   * It precludes addition of meaningful reasons
   * by subsequent invalidations .
   *
     if (ISSET(item->inv_flags, ZN_TRANSFO_FLAG)) {
    return;
    }*/

  if (ISSET(reason, ZN_COORDS_FLAG) ||
      ISSET(reason, ZN_TRANSFO_FLAG)) {
    ZnItem parent = item->parent;
    while ((parent != NULL) &&
           ISCLEAR(parent->inv_flags, ZN_COORDS_FLAG) &&
           ISCLEAR(parent->inv_flags, ZN_TRANSFO_FLAG)) {
      SET(parent->inv_flags, ZN_COORDS_FLAG);
      /*printf("invalidate coords for parent %d\n", parent->id);*/
      parent = parent->parent;
    }
    /*
     * There is no need to set the DRAW flag to force the invalidation
     * of the current bounding box. This will be done by ComputeCoordinates
     * in Group.
     */
    item->inv_flags |= reason;
    /*printf("invalidate %s for item %d, flags %s\n",
           ISSET(reason, ZN_TRANSFO_FLAG)?"TRANSFO":"COORDS", item->id,
           ISSET(item->inv_flags, ZN_TRANSFO_FLAG)?"TRANSFO":"COORDS");*/
    ZnNeedRedisplay(item->wi);
  }
  else if (ISSET(reason, ZN_DRAW_FLAG)) {
    if (ISSET(item->flags, ZN_VISIBLE_BIT)) {
      /*printf("invalidate graphics for item %d\n", item->id);*/
      ZnDamage(item->wi, &item->item_bounding_box);
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
    }
  }
}

           
/*
 **********************************************************************************
 *
 * InvalidateItems -- Method
 *      Invalidate the geometric state of all items belonging
 *      to a given class. The search for items starts at group
 *      and proceed depth first.
 *
 **********************************************************************************
 */
static void
InvalidateItems(ZnItem          group,
                ZnItemClass     item_class)
{
  ZnItem        item;

  if (group->class != ZnGroup) {
    return;
  }
  item = ZnGroupHead(group);
  while (item != ZN_NO_ITEM) {
    if (item->class == item_class) {
      Invalidate(item, ZN_COORDS_FLAG);
    }
    else if (item->class == ZnGroup) {
      InvalidateItems(item, item_class);
    }
    item = item->next;
  }
}


/*
 **********************************************************************************
 *
 * ResetTransfo
 * SetTransfo
 * TranslateItem
 * ScaleItem
 * SkewItem
 * RotateItem -- Methods
 *      Set of functions that deal with item transform. They take care
 *      of all details including managing NULL transforms and invalidating
 *      the item hierarchy.
 *
 **********************************************************************************
 */
static void
ResetTransfo(ZnItem     item)
{
  if (item->transfo) {
    ZnFree(item->transfo);
    item->transfo = NULL;
  }
  Invalidate(item, ZN_TRANSFO_FLAG);
}


static void
SetTransfo(ZnItem       item,
           ZnTransfo    *t)
{
  if (item->transfo) {
    ZnFree(item->transfo);
  }
  if (!t || ZnTransfoIsIdentity(t)) {
    item->transfo = NULL;
  }
  else {
    item->transfo = ZnTransfoDuplicate(t);
  }
  Invalidate(item, ZN_TRANSFO_FLAG);
}


static void
TranslateItem(ZnItem    item,
              ZnReal    dx,
              ZnReal    dy,
              ZnBool    abs)
{
  if (!item->transfo) {
    item->transfo = ZnTransfoNew();
  }
  ZnTranslate(item->transfo, dx, dy, abs);
  Invalidate(item, ZN_TRANSFO_FLAG);
}


static void
ScaleItem(ZnItem        item,
          ZnReal        sx,
          ZnReal        sy,
          ZnPoint       *p)
{
  if (!item->transfo) {
    item->transfo = ZnTransfoNew();
  }
  if (p) {
    ZnTranslate(item->transfo, -p->x, -p->y, False);
  }
  ZnScale(item->transfo, sx, sy);
  if (p) {
    ZnTranslate(item->transfo, p->x, p->y, False);
  }
  Invalidate(item, ZN_TRANSFO_FLAG);
}


static void
SkewItem(ZnItem item,
         ZnReal x_skew,
         ZnReal y_skew)
{
  if (!item->transfo) {
    item->transfo = ZnTransfoNew();
  }
  ZnSkewRad(item->transfo, x_skew, y_skew);
  Invalidate(item, ZN_TRANSFO_FLAG);
}


static void
RotateItem(ZnItem       item,
           ZnReal       angle,
           ZnBool       deg,
           ZnPoint      *p)
{
  if (!item->transfo) {
    item->transfo = ZnTransfoNew();
  }
  if (p) {
    ZnTranslate(item->transfo, -p->x, -p->y, False);
  }
  if (deg) {
    ZnRotateDeg(item->transfo, angle);
  }
  else {
    ZnRotateRad(item->transfo, angle);
  }
  if (p) {
    ZnTranslate(item->transfo, p->x, p->y, False);
  }

  Invalidate(item, ZN_TRANSFO_FLAG);
}


/*
 **********************************************************************************
 *
 * DestroyItem -- Method
 *
 **********************************************************************************
 */
static void
DestroyItem(ZnItem      item)
{
  ZnWInfo       *wi = item->wi;
  ZnTextInfo    *ti = &wi->text_info;

  /*
   * Extract it from its group.
   */
  ExtractItem(item);
  
  /*
   * Update state variables to prevent dangling pointers.
   */
  if (wi->current_item == item) {
    wi->current_item = ZN_NO_ITEM;
    wi->current_part = ZN_NO_PART;
  }
  if (wi->new_item == item) {
    wi->new_item = ZN_NO_ITEM;
    wi->new_part = ZN_NO_PART;
  }
  if ((wi->hot_item == item) || (wi->hot_prev) == item) {
    wi->hot_item = ZN_NO_ITEM;
  }
  if (ti->sel_item == item) {
    ti->sel_item = ZN_NO_ITEM;
    ti->sel_field = ZN_NO_PART;
  }
  if (ti->anchor_item == item) {
    ti->anchor_item = ZN_NO_ITEM;
    ti->anchor_field = ZN_NO_PART;
  }
  if (wi->focus_item == item) {
    wi->focus_item = ZN_NO_ITEM;
    wi->focus_field = ZN_NO_PART;
  }

  /*
   * Call per class removal code.
   */
  (item->class->Destroy)(item);
  /*
   * Free the transform if any.
   */
  if (item->transfo) {
    ZnFree(item->transfo);
  }
  /*
   * Remove the item from the item table and free
   * all its tags.
   */
  FreeId(item);
  FreeTags(item);
  /*
   * Free the item own memory
   */
  ZnFree(item);
  wi->num_items--;
}


/*
 **********************************************************************************
 *
 * Generic methods on items --
 *
 **********************************************************************************
 */

struct _ZnITEM ZnITEM = {
  CloneItem,
  DestroyItem,
  ConfigureItem,
  QueryItem,
  InsertItem,
  UpdateItemPriority,
  UpdateItemDependency,
  ExtractItem,
  SetId,
  FreeId,
  AddTag,
  RemoveTag,
  FreeTags,
  HasTag,
  ResetTransfo,
  SetTransfo,
  TranslateItem,
  ScaleItem,
  SkewItem,
  RotateItem,
  Invalidate,
  InvalidateItems,
  GetItemTransform
};
