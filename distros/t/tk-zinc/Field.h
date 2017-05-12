/*
 * Field.h -- Header for field item parts.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Field.h,v 1.7 2005/05/10 07:59:48 lecoanet Exp $
 */

/*
 *  Copyright (c) 2002 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Field_h
#define _Field_h

#include "Attrs.h"
#include "Types.h"
#include "List.h"
#include "Color.h"
#include "Image.h"


struct _ZnItemStruct;
struct _ZnAttrConfig;


/*
 * Field array management record.
 *
 *   This structure should be used only for internal
 * management by items with fields. The rest of the code
 * should use the methods in FIELD.
 *
 */
typedef struct _ZnFieldSetStruct {
  struct _ZnItemStruct  *item;
  ZnLabelFormat         label_format;
  unsigned int          num_fields;
  struct _FieldStruct   *fields;
  ZnDim                 label_width;    /* Describe the label size. Access these */
  ZnDim                 label_height;   /* 2 only with GetLabelBBox. -1 means
                                         * not up to date. */
  ZnPoint               label_pos;      /* Describe the label origin. */
} ZnFieldSetStruct, *ZnFieldSet;


extern struct _ZnFIELD {
  struct _ZnAttrConfig  *attr_desc;

  void (*InitFields)(ZnFieldSet fs);
  void (*CloneFields)(ZnFieldSet fs);
  void (*FreeFields)(ZnFieldSet fs);
  int (*ConfigureField)(ZnFieldSet fs, int field, int argc, Tcl_Obj *CONST argv[], int *flags);
  int (*QueryField)(ZnFieldSet fs, int field, int argc, Tcl_Obj *CONST argv[]);
  void (*DrawFields)(ZnFieldSet fs);
  void (*RenderFields)(ZnFieldSet fs);
  int (*PostScriptFields)(ZnFieldSet fs, ZnBool prepass, ZnBBox *area);
  int (*FieldsToArea)(ZnFieldSet fs, ZnBBox *area);
  ZnBool (*IsFieldSensitive)(ZnFieldSet fs, int part);
  double (*FieldsPick)(ZnFieldSet fs, ZnPoint *p, int *part);
  int (*FieldIndex)(ZnFieldSet fs, int field, Tcl_Obj *index_spec, int *index);
  ZnBool (*FieldInsertChars)(ZnFieldSet fs, int field, int *index, char *chars);
  ZnBool (*FieldDeleteChars)(ZnFieldSet fs, int field,
                             int *first, int *last);
  void (*FieldCursor)(ZnFieldSet fs, int field, int index);
  int (*FieldSelection)(ZnFieldSet fs, int field, int offset,
                        char *chars, int max_chars);
  void (*LeaderToLabel)(ZnFieldSet fs, ZnPoint *start, ZnPoint *end);
  void (*GetLabelBBox)(ZnFieldSet fs, ZnDim *w, ZnDim *h);
  void (*GetFieldBBox)(ZnFieldSet fs, unsigned int index,
                       ZnBBox *field_bbox);
  void (*SetFieldsAutoAlign)(ZnFieldSet fs, int alignment);
  void (*ClearFieldCache)(ZnFieldSet fs, int field);
  char *(*GetFieldStruct)(ZnFieldSet fs, int field);
  unsigned int (*NumFields)(ZnFieldSet fs);
} ZnFIELD;


#endif /* _Field_h */
