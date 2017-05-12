/*
 * Attrs.c -- Various attributes manipulation routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Fri Dec 31 10:03:34 1999
 *
 * $Id: Attrs.c,v 1.14 2005/10/18 09:32:23 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Attrs.h"
#include "Item.h"
#include "List.h"
#include "Geo.h"
#include "WidgetInfo.h"

#include <GL/glu.h>
#include <memory.h>
#include <stdlib.h>


static const char rcsid[] = "$Id: Attrs.c,v 1.14 2005/10/18 09:32:23 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


/*
 ****************************************************************
 *
 * Code for reliefs.
 *
 ****************************************************************
 */
#define RELIEF_FLAT_SPEC        "flat"
#define RELIEF_RAISED_SPEC      "raised"
#define RELIEF_SUNKEN_SPEC      "sunken"
#define RELIEF_GROOVE_SPEC      "groove"
#define RELIEF_RIDGE_SPEC       "ridge"
#define RELIEF_ROUND_RAISED_SPEC "roundraised"
#define RELIEF_ROUND_SUNKEN_SPEC "roundsunken"
#define RELIEF_ROUND_GROOVE_SPEC "roundgroove"
#define RELIEF_ROUND_RIDGE_SPEC "roundridge"
#define RELIEF_SUNKEN_RULE_SPEC "sunkenrule"
#define RELIEF_RAISED_RULE_SPEC "raisedrule"

int
ZnGetRelief(ZnWInfo             *wi,
            char                *name,
            ZnReliefStyle       *relief)
{
  size_t length;
  
  length = strlen(name);
  if (strncmp(name, RELIEF_FLAT_SPEC, length) == 0) {
    *relief = ZN_RELIEF_FLAT;
  }
  else if (strncmp(name, RELIEF_SUNKEN_SPEC, length) == 0) {
    *relief = ZN_RELIEF_SUNKEN;
  }
  else if ((strncmp(name, RELIEF_RAISED_SPEC, length) == 0) && (length >= 2)) {
    *relief = ZN_RELIEF_RAISED;
  }
  else if ((strncmp(name, RELIEF_RIDGE_SPEC, length) == 0) && (length >= 2)) {
    *relief = ZN_RELIEF_RIDGE;
  }
  else if (strncmp(name, RELIEF_GROOVE_SPEC, length) == 0) {
    *relief = ZN_RELIEF_GROOVE;
  }
  else if ((strncmp(name, RELIEF_ROUND_SUNKEN_SPEC, length) == 0) && (length >= 6)) {
    *relief = ZN_RELIEF_ROUND_SUNKEN;
  }
  else if ((strncmp(name, RELIEF_ROUND_RAISED_SPEC, length) == 0) && (length >= 7)) {
    *relief = ZN_RELIEF_ROUND_RAISED;
  }
  else if ((strncmp(name, RELIEF_ROUND_RIDGE_SPEC, length) == 0) && (length >= 7)) {
    *relief = ZN_RELIEF_ROUND_RIDGE;
  }
  else if ((strncmp(name, RELIEF_ROUND_GROOVE_SPEC, length) == 0) && (length >= 6)) {
    *relief = ZN_RELIEF_ROUND_GROOVE;
  }
  else if ((strncmp(name, RELIEF_SUNKEN_RULE_SPEC, length) == 0) && (length >= 7)) {
    *relief = ZN_RELIEF_SUNKEN_RULE;
  }
  else if ((strncmp(name, RELIEF_RAISED_RULE_SPEC, length) == 0) && (length >= 7)) {
    *relief = ZN_RELIEF_RAISED_RULE;
  }
  else {
    Tcl_AppendResult(wi->interp, "bad relief \"", name, "\": must be ",
                     RELIEF_FLAT_SPEC, ", ",
                     RELIEF_RAISED_SPEC, ", ",
                     RELIEF_SUNKEN_SPEC, ", ",
                     RELIEF_GROOVE_SPEC, ", ",
                     RELIEF_RIDGE_SPEC, ", ",
                     RELIEF_ROUND_RAISED_SPEC, ", ",
                     RELIEF_ROUND_SUNKEN_SPEC, ", ",
                     RELIEF_ROUND_GROOVE_SPEC, ", ",
                     RELIEF_ROUND_RIDGE_SPEC, ", ",
                     RELIEF_SUNKEN_RULE_SPEC, ", ",
                     RELIEF_RAISED_RULE_SPEC,
                     NULL);
    return TCL_ERROR;
  }
  if (!wi->render) {
    *relief = *relief & ~(ZN_RELIEF_ROUND|ZN_RELIEF_RULE);
  }

  return TCL_OK;
}

char *
ZnNameOfRelief(ZnReliefStyle relief)
{
  switch (relief) {
  case ZN_RELIEF_FLAT:
    return RELIEF_FLAT_SPEC;
  case ZN_RELIEF_SUNKEN:
    return RELIEF_SUNKEN_SPEC;
  case ZN_RELIEF_RAISED:
    return RELIEF_RAISED_SPEC;
  case ZN_RELIEF_GROOVE:
    return RELIEF_GROOVE_SPEC;
  case ZN_RELIEF_RIDGE:
    return RELIEF_RIDGE_SPEC;
  case ZN_RELIEF_ROUND_SUNKEN:
    return RELIEF_ROUND_SUNKEN_SPEC;
  case ZN_RELIEF_ROUND_RAISED:
    return RELIEF_ROUND_RAISED_SPEC;
  case ZN_RELIEF_ROUND_GROOVE:
    return RELIEF_ROUND_GROOVE_SPEC;
  case ZN_RELIEF_ROUND_RIDGE:
    return RELIEF_ROUND_RIDGE_SPEC;
  case ZN_RELIEF_SUNKEN_RULE:
    return RELIEF_SUNKEN_RULE_SPEC;
  case ZN_RELIEF_RAISED_RULE:
    return RELIEF_RAISED_RULE_SPEC;
  default:
    return "unknown relief";
  }
}

/*
 ****************************************************************
 *
 * Code for borders.
 *
 ****************************************************************
 */
#define BORDER_LEFT_SPEC        "left"
#define BORDER_RIGHT_SPEC       "right"
#define BORDER_TOP_SPEC         "top"
#define BORDER_BOTTOM_SPEC      "bottom"
#define BORDER_CONTOUR_SPEC     "contour"
#define BORDER_COUNTER_OBLIQUE_SPEC     "counteroblique"
#define BORDER_OBLIQUE_SPEC     "oblique"
#define NO_BORDER_SPEC          "noborder"

int
ZnGetBorder(ZnWInfo     *wi,
            Tcl_Obj     *name,
            ZnBorder    *border)
{
  unsigned int j, len, largc;
  Tcl_Obj      **largv;
  char         *str;

  *border = ZN_NO_BORDER;
  if (Tcl_ListObjGetElements(wi->interp, name,
                             &largc, &largv) == TCL_ERROR) {
  border_error:
    Tcl_AppendResult(wi->interp, "bad line shape \"", Tcl_GetString(name),
                     "\": must be a list of ",
                     BORDER_LEFT_SPEC, ", ",
                     BORDER_RIGHT_SPEC, ", ",
                     BORDER_TOP_SPEC, ", ",
                     BORDER_BOTTOM_SPEC, ", ",
                     BORDER_COUNTER_OBLIQUE_SPEC, ", ",
                     BORDER_OBLIQUE_SPEC, " or ",
                     BORDER_CONTOUR_SPEC, ", ",
                     NO_BORDER_SPEC, " alone",
                     NULL);
    return TCL_ERROR;
  }
  for (j = 0; j < largc; j++) {
    str = Tcl_GetString(largv[j]);
    len = strlen(str);
    if (strncmp(str, BORDER_LEFT_SPEC, len) == 0) {
      *border |= ZN_LEFT_BORDER;
    }
    else if (strncmp(str, BORDER_RIGHT_SPEC, len) == 0) {
      *border |= ZN_RIGHT_BORDER;
    }
    else if (strncmp(str, BORDER_TOP_SPEC, len) == 0) {
      *border |= ZN_TOP_BORDER;
    }
    else if (strncmp(str, BORDER_BOTTOM_SPEC, len) == 0) {
      *border |= ZN_BOTTOM_BORDER;
    }
    else if (strncmp(str, BORDER_CONTOUR_SPEC, len) == 0) {
      *border |= ZN_CONTOUR_BORDER;
    }
    else if (strncmp(str, BORDER_OBLIQUE_SPEC, len) == 0) {
      *border |= ZN_OBLIQUE;
    }
    else if (strncmp(str, BORDER_COUNTER_OBLIQUE_SPEC, len) == 0) {
      *border |= ZN_COUNTER_OBLIQUE;
    }
    else if (strncmp(str, NO_BORDER_SPEC, len) == 0) {
      *border = ZN_NO_BORDER;
    }
    else {
      goto border_error;
    }
  }
  return TCL_OK;
}

/*
 * name must be large enough to hold the returned string.
 * 64 chars should be enough with the current values.
 */
void
ZnNameOfBorder(ZnBorder border,
               char     *name)
{
  if (border == ZN_NO_BORDER) {
    strcpy(name, NO_BORDER_SPEC);
    return;
  }
  name[0] = 0;
  if ((border & ZN_CONTOUR_BORDER) == ZN_CONTOUR_BORDER) {
    strcat(name, BORDER_CONTOUR_SPEC);
  }
  else {
    if (border & ZN_LEFT_BORDER) {
      strcat(name, BORDER_LEFT_SPEC);
    }
    if (border & ZN_RIGHT_BORDER) {  
      if (name[0] != 0) {
        strcat(name, " ");
      }
      strcat(name, BORDER_RIGHT_SPEC);
    }
    if (border & ZN_TOP_BORDER) {
      if (name[0] != 0) {
        strcat(name, " ");
      }
      strcat(name, BORDER_TOP_SPEC);
    }
    if (border & ZN_BOTTOM_BORDER) {
      if (name[0] != 0) {
            strcat(name, " ");
      }
      strcat(name, BORDER_BOTTOM_SPEC);
    }
  }
  if (border & ZN_OBLIQUE) {
    if (name[0] != 0) {
      strcat(name, " ");
    }
    strcat(name, BORDER_OBLIQUE_SPEC);
  }
  if (border & ZN_COUNTER_OBLIQUE) {
    if (name[0] != 0) {
      strcat(name, " ");
    }
    strcat(name, BORDER_COUNTER_OBLIQUE_SPEC);
  }
}

/*
 ****************************************************************
 *
 * Code for line shapes.
 *
 ****************************************************************
 */
#define STRAIGHT_SPEC           "straight"
#define RIGHT_LIGHTNING_SPEC    "rightlightning"
#define LEFT_LIGHTNING_SPEC     "leftlightning"
#define RIGHT_CORNER_SPEC       "rightcorner"
#define LEFT_CORNER_SPEC        "leftcorner"
#define DOUBLE_RIGHT_CORNER_SPEC  "doublerightcorner"
#define DOUBLE_LEFT_CORNER_SPEC "doubleleftcorner"

int
ZnGetLineShape(ZnWInfo          *wi,
               char             *name,
               ZnLineShape      *line_shape)
{
  unsigned int  len;

  len = strlen(name);
  if (strncmp(name, STRAIGHT_SPEC, len) == 0) {
    *line_shape = ZN_LINE_STRAIGHT;
  }
  else if (strncmp(name, RIGHT_LIGHTNING_SPEC, len) == 0) {
    *line_shape = ZN_LINE_RIGHT_LIGHTNING;
  }
  else if (strncmp(name, LEFT_LIGHTNING_SPEC, len) == 0) {
    *line_shape = ZN_LINE_LEFT_LIGHTNING;
  }
  else if (strncmp(name, RIGHT_CORNER_SPEC, len) == 0) {
    *line_shape = ZN_LINE_RIGHT_CORNER;
  }
  else if (strncmp(name, LEFT_CORNER_SPEC, len) == 0) {
    *line_shape = ZN_LINE_LEFT_CORNER;
  }
  else if (strncmp(name, DOUBLE_RIGHT_CORNER_SPEC, len) == 0) {
    *line_shape = ZN_LINE_DOUBLE_RIGHT_CORNER;
  }
  else if (strncmp(name, DOUBLE_LEFT_CORNER_SPEC, len) == 0) {
    *line_shape = ZN_LINE_DOUBLE_LEFT_CORNER;
  }
  else  {
    Tcl_AppendResult(wi->interp, "bad line shape \"", name, "\": must be ",
                     STRAIGHT_SPEC, ", ",
                     RIGHT_LIGHTNING_SPEC, ", ",
                     LEFT_LIGHTNING_SPEC, ", ",
                     RIGHT_CORNER_SPEC, ", ",
                     LEFT_CORNER_SPEC, ", ",
                     DOUBLE_RIGHT_CORNER_SPEC, ", ",
                     DOUBLE_LEFT_CORNER_SPEC,
                     NULL);
    return TCL_ERROR;
  }
  return TCL_OK;
}

char *
ZnNameOfLineShape(ZnLineShape line_shape)
{
  switch (line_shape) {
  case ZN_LINE_STRAIGHT:
    return STRAIGHT_SPEC;
  case ZN_LINE_RIGHT_LIGHTNING:
    return RIGHT_LIGHTNING_SPEC;
  case ZN_LINE_LEFT_LIGHTNING:
    return LEFT_LIGHTNING_SPEC;
  case ZN_LINE_RIGHT_CORNER:
    return RIGHT_CORNER_SPEC;
  case ZN_LINE_LEFT_CORNER:
    return LEFT_CORNER_SPEC;
  case ZN_LINE_DOUBLE_RIGHT_CORNER:
    return DOUBLE_RIGHT_CORNER_SPEC;
  case ZN_LINE_DOUBLE_LEFT_CORNER:
    return DOUBLE_LEFT_CORNER_SPEC;
  default:
    return "unknown line shape";
  }
}

/*
 ****************************************************************
 *
 * Code for line styles.
 *
 ****************************************************************
 */
#define SIMPLE_SPEC             "simple"
#define DASHED_SPEC             "dashed"
#define DOTTED_SPEC             "dotted"
#define MIXED_SPEC              "mixed"

int
ZnGetLineStyle(ZnWInfo          *wi,
               char             *name,
               ZnLineStyle      *line_style)
{
  unsigned int len;

  len = strlen(name);
  if (strncmp(name, SIMPLE_SPEC, len) == 0)
    *line_style = ZN_LINE_SIMPLE;
  else if (strncmp(name, DASHED_SPEC, len) == 0)
    *line_style = ZN_LINE_DASHED;
  else if (strncmp(name, MIXED_SPEC, len) == 0)
    *line_style = ZN_LINE_MIXED;
  else if (strncmp(name, DOTTED_SPEC, len) == 0)
    *line_style = ZN_LINE_DOTTED;
  else  {
    Tcl_AppendResult(wi->interp, "bad line style \"", name, "\": must be ",
                     SIMPLE_SPEC, ", ",
                     DASHED_SPEC, ", ",
                     DOTTED_SPEC, ", ",
                     MIXED_SPEC,
                     NULL);
    return TCL_ERROR;         
  }
  return TCL_OK;
}

char *
ZnNameOfLineStyle(ZnLineStyle line_style)
{
  switch (line_style) {
  case ZN_LINE_SIMPLE:
    return SIMPLE_SPEC;
  case ZN_LINE_DASHED:
    return DASHED_SPEC;
  case ZN_LINE_MIXED:
    return MIXED_SPEC;
  case ZN_LINE_DOTTED:
    return DOTTED_SPEC;
  default:
    return "unknown line style";
  }
}

/*
 ****************************************************************
 *
 * Code for leader anchors.
 *
 * Format is: lChar leftLeaderAnchor [ lChar rightLeaderAnchor]
 *
 * If lChar is a '|', leftLeaderAnchor and rightLeaderAnchor are the indices
 * of the fields that serve to anchor the label's leader. More specifically
 * the bottom left corner of the left field and the bottom right corner of
 * the right field are used as the anchors.
 * If lChar is '%', leftLeaderAnchor and rightLeaderAnchor should be
 * specified as 'valxval', 'val' being a percentage (max 100) of the
 * width/height of the label bounding box.
 * If rightLeaderAnchor is not specified it defaults to leftLeaderAnchor.
 * If neither of them are specified, the center of the label is used as an
 * anchor.
 *
 ****************************************************************
 */
int
ZnGetLeaderAnchors(ZnWInfo              *wi,
                   char                 *name,
                   ZnLeaderAnchors      *leader_anchors)
{
  int   anchors[4];
  int   index, num_tok, anchor_index=0;

  *leader_anchors = NULL;
  while (*name && (*name == ' ')) {
    name++;
  }
  while (*name && (anchor_index < 4)) {
    switch (*name) {
    case '|':
      num_tok = sscanf(name, "|%d%n", &anchors[anchor_index], &index);
      if (num_tok != 1) {
      la_error:
        Tcl_AppendResult(wi->interp, " incorrect leader anchors \"",
                         name, "\"", NULL);
        return TCL_ERROR;
      }
      anchors[anchor_index+1] = -1;
      break;
    case '%':
      num_tok = sscanf(name, "%%%dx%d%n", &anchors[anchor_index],
                       &anchors[anchor_index+1], &index);
      if (num_tok != 2) {
        goto la_error;
      }
      if (anchors[anchor_index] < 0) {
        anchors[anchor_index] = 0;
      }
      if (anchors[anchor_index] > 100) {
        anchors[anchor_index] = 100;
      }
      if (anchors[anchor_index+1] < 0) {
        anchors[anchor_index+1] = 0;
      }
      if (anchors[anchor_index+1] > 100) {
        anchors[anchor_index+1] = 100;
      }
      break;
    default:
      goto la_error;
    }
    anchor_index += 2;
    name += index;
  }
  /*
   * If empty, pick the default (center of the bounding box).
   */
  if (anchor_index != 0) {
    *leader_anchors = ZnMalloc(sizeof(ZnLeaderAnchorsStruct));
    (*leader_anchors)->left_x = anchors[0];
    (*leader_anchors)->left_y = anchors[1];
    if (anchor_index == 2) {
      (*leader_anchors)->right_x = (*leader_anchors)->left_x;
      (*leader_anchors)->right_y = (*leader_anchors)->left_y;
    }
    else {
      (*leader_anchors)->right_x = anchors[2];
      (*leader_anchors)->right_y = anchors[3];
    }
  }
  return TCL_OK;
}

/*
 * name must be large enough to hold the returned string.
 */
void
ZnNameOfLeaderAnchors(ZnLeaderAnchors leader_anchors,
                      char            *name)
{
  unsigned int  count;
  
  if (!leader_anchors) {
    strcpy(name, "%50x50");
  }
  else {
    if (leader_anchors->left_y < 0) {
      count = sprintf(name, "|%d", leader_anchors->left_x);
    }
    else {
      count = sprintf(name, "%%%dx%d", leader_anchors->left_x,
                      leader_anchors->left_y);
    }
    name += count;
    if (leader_anchors->right_y < 0) {
      sprintf(name, "|%d", leader_anchors->right_x);
    }
    else {
      sprintf(name, "%%%dx%d", leader_anchors->right_x, leader_anchors->right_y);
    }
  }
}

/*
 ******************************************************************
 *
 * Code for label formats.
 *
 ******************************************************************
 */
static Tcl_HashTable    format_cache;
static ZnBool           format_inited = False;


static char
CharToAttach(int attach)
{
  switch (attach) {
  case '>':
    return ZN_LF_ATTACH_FWD;
  case '<':
    return ZN_LF_ATTACH_BWD;
  case '^':
    return ZN_LF_ATTACH_LEFT;
  case '$':
    return ZN_LF_ATTACH_RIGHT;
  case '+':
  default:
    return ZN_LF_ATTACH_PIXEL;
  }
}

static char
CharToDim(int   dim)
{
  switch (dim) {
  case 'f':
    return ZN_LF_DIM_FONT;
  case 'i':
    return ZN_LF_DIM_ICON;
  case 'a':
    return ZN_LF_DIM_AUTO;
  case 'l':
    return ZN_LF_DIM_LABEL;
  case 'x':
  default:
    return ZN_LF_DIM_PIXEL;
  }
}

/*
 * The new format is as follow. Parameters between [] are
 * optional and take default values when omitted. The spaces can appear
 * between blocks but not inside.
 *
 *      [ WidthxHeight ] [ field0Spec ][ field1Spec ]...[ fieldnSpec ]
 *
 * Width and Height set the size of the clipping box surrounding
 * the label. If it is not specified, there will be no clipping.
 * It it is specified alone it is the size of the only displayed
 * field (0).
 *
 * fieldSpec is:
 *      sChar fieldWidth sChar fieldHeight [pChar fieldX pChar fieldY].
 *
 * Each field description refers to the field of same index in the field
 * array.
 * If sChar is 'x', the dimension is in pixel. If sChar is 'f', the
 * dimension is in percentage of the mean width/height of a character (in the
 * field font). If sChar is 'i', the dimension is in percentage of the size
 * of the image in the field. If sChar is 'a', the dimension is automatically
 * adjusted to match the field's content plus the given value in pixels.
 * If pChar is '+' the position is in pixel (possibly negative). If it is
 * '<' the position is the index of the field at the left/top of which the
 * current field should be  attached. If it is '>' the position is the index
 * of the field at the right/bottom of which the current field should be
 * attached. If pChar is '^' the position is the index of the field used to
 * align the left/top border (left on left or top on top). If pChar is '$' the
 * position is the index of the field used to align the right/bottom border
 * (right on right or bottom on bottom). 
 * The positional parameters can be omitted if there is only one field.
 *
 */
ZnLabelFormat
ZnLFCreate(Tcl_Interp   *interp,
           char         *format_str,
           unsigned int num_fields)
{
  ZnList        fields;
  Tcl_HashEntry *entry;
  ZnFieldFormatStruct field_struct;
  ZnFieldFormat field_array;
  ZnLabelFormat format;
  int           width, height;
  ZnDim         c_width=0.0, c_height=0.0;
  int           index, num_tok, num_ffs, new;
  unsigned int  field_index=0;
  char          *ptr = format_str, *next_ptr;
  char          x_char, y_char;

  if (!format_inited) {
    Tcl_InitHashTable(&format_cache, TCL_STRING_KEYS);
    format_inited = True;
  }
  entry = Tcl_CreateHashEntry(&format_cache, format_str, &new);
  if (!new) {
    format = (ZnLabelFormat) Tcl_GetHashValue(entry);
    if (format->num_fields <= num_fields) {
      format->ref_count++;
      return format;
    }
    else {
      Tcl_AppendResult(interp, "too many fields in label format: \"",
                       format_str, "\"", NULL);
      return NULL;
    }
  }
  
  fields = ZnListNew(1, sizeof(ZnFieldFormatStruct));
  
  /*
   * Try to see if it starts with a number or a leader spec.
   */
  while (*ptr && (*ptr == ' ')) {
    ptr++;
  }
  if (!*ptr) {
    goto lf_error_syn;
  }
  if ((*ptr != 'x') && (*ptr != 'f') && (*ptr != 'i') &&
      (*ptr != 'a') && (*ptr != 'l')) {
    c_width = (ZnDim) strtod(ptr, &next_ptr);
    if ((ptr == next_ptr) || (*next_ptr != 'x')) {
    lf_error_syn:
      Tcl_AppendResult(interp, "invalid label format specification \"",
                       ptr, "\"", NULL);
    lf_error:
      Tcl_DeleteHashEntry(entry);
      ZnListFree(fields);
      return NULL;
    }
    ptr = next_ptr+1;
    c_height = (ZnDim) strtod(ptr, &next_ptr);
    if (ptr == next_ptr) {
      goto lf_error_syn;
    }
    ptr = next_ptr;
  }
  if (!*ptr) {
    /* It is a simple spec, one field. */
    field_struct.x_attach = field_struct.y_attach = ZN_LF_ATTACH_PIXEL;
    field_struct.x_dim = field_struct.y_dim = ZN_LF_DIM_PIXEL;
    field_struct.x_spec = field_struct.y_spec = 0;
    field_struct.width_spec = (short) c_width;
    field_struct.height_spec = (short) c_height;
    c_width = c_height = 0.0;
    ZnListAdd(fields, &field_struct, ZnListTail);
    goto lf_end_parse;
  }
  
  /*
   * Parse the field specs.
   */
 lf_parse2:
  while (*ptr && (*ptr == ' ')) {
    ptr++;
  }
  if (!*ptr) {
    goto lf_end_parse;
  }
  /* Preset the default field values. */
  field_struct.x_spec = field_struct.y_spec = 0;
  field_struct.x_attach = field_struct.y_attach = ZN_LF_ATTACH_PIXEL;
  field_struct.x_dim = field_struct.y_dim = ZN_LF_DIM_PIXEL;
  if ((*ptr == 'x') || (*ptr == 'f') || (*ptr == 'i') ||
      (*ptr == 'a') || (*ptr == 'l')) {
    num_tok = sscanf(ptr, "%c%d%c%d%n", &x_char, &width,
                     &y_char, &height, &index);
    if (num_tok != 4) {
      goto lf_error_syn;
    }
    //if (width < 0) {
    //  width = 0;
    //}
    //if (height < 0) {
    //  height = 0;
    //}
    field_struct.x_dim = CharToDim(x_char);
    field_struct.y_dim = CharToDim(y_char);

    ptr += index;
    if ((*ptr == '>') || (*ptr == '<') || (*ptr == '+') ||
        (*ptr == '^') || (*ptr == '$')) {
      num_tok = sscanf(ptr, "%c%d%c%d%n", &x_char, &field_struct.x_spec,
                       &y_char, &field_struct.y_spec, &index);
      if (num_tok != 4) {
        goto lf_error_syn;
      }
      field_struct.x_attach = CharToAttach(x_char);
      field_struct.y_attach = CharToAttach(y_char);

      ptr += index;
    }
    else if (!*ptr || (field_index != 0)) {
      /* An incomplete field spec is an error if there are several fields. */
      Tcl_AppendResult(interp, "incomplete field in label format: \"",
                       ptr-index, "\"", NULL);
      goto lf_error;            
    }
    if (field_index >= num_fields) {
      Tcl_AppendResult(interp, "too many fields in label format: \"",
                       format_str, "\"", NULL);
      goto lf_error;
    }
    field_struct.width_spec = (short) width;
    field_struct.height_spec = (short) height;
    ZnListAdd(fields, &field_struct, ZnListTail);
    field_index++;
    goto lf_parse2;
  }
  else {
    goto lf_error_syn;
  }
  
 lf_end_parse:
  field_array = (ZnFieldFormat) ZnListArray(fields);
  num_ffs = ZnListSize(fields);
  
  format = (ZnLabelFormat) ZnMalloc(sizeof(ZnLabelFormatStruct) +
                                    (num_ffs-1) * sizeof(ZnFieldFormatStruct));
  format->clip_width = (short) c_width;
  format->clip_height = (short) c_height;
  format->num_fields = num_ffs;
  memcpy(&format->fields, field_array, num_ffs * sizeof(ZnFieldFormatStruct));
  ZnListFree(fields);

  format->ref_count = 1;
  format->entry = entry;
  Tcl_SetHashValue(entry, (ClientData) format);
  
  return format;
}


ZnLabelFormat
ZnLFDuplicate(ZnLabelFormat     lf)
{
  lf->ref_count++;
  return lf;
}


void
ZnLFDelete(ZnLabelFormat        lf)
{
  lf->ref_count--;
  if (lf->ref_count == 0) {
    Tcl_DeleteHashEntry(lf->entry);
    ZnFree(lf);
  }
}


char *
ZnLFGetString(ZnLabelFormat     lf)
{
  return Tcl_GetHashKey(&format_cache, lf->entry);

#if 0
  ZnFieldFormat ff;
  char          *ptr;
  char          x_char, y_char, w_char, h_char;
  unsigned int  i, count;
  
  ptr = str;
  if ((lf->clip_width != 0) || (lf->clip_height != 0)) {
    count = sprintf(ptr, "%dx%d", lf->clip_width, lf->clip_height);
    ptr += count;
  }
  if (lf->left_y < 0) {
    count = sprintf(ptr, "|%d", lf->left_x);
  }
  else {
    count = sprintf(ptr, "%%%dx%d", lf->left_x, lf->left_y);
  }
  ptr += count;
  if (lf->right_y < 0) {
    count = sprintf(ptr, "|%d", lf->right_x);
  }
  else {
    count = sprintf(ptr, "%%%dx%d", lf->right_x, lf->right_y);
  }
  ptr += count;
  for (i = 0; i < lf->num_fields; i++) {
    ff = &lf->fields[i];
    x_char = AttachToChar(ff->x_attach);
    y_char = AttachToChar(ff->y_attach);
    w_char = DimToChar(ff->x_dim);
    h_char = DimToChar(ff->y_dim);
    count = sprintf(ptr, "%c%d%c%d%c%d%c%d",
                    w_char, ff->width_spec, h_char, ff->height_spec,
                    x_char, ff->x_spec, y_char, ff->y_spec);
    ptr += count;
  }
  *ptr = 0;
#endif
}


/*
 * If the clip box has both its width and its height
 * set to zero, it means that there is no clipbox.
 */
ZnBool
ZnLFGetClipBox(ZnLabelFormat    lf,
               ZnDim            *w,
               ZnDim            *h)
{
  if ((lf->clip_width == 0) && (lf->clip_height == 0)) {
    return False;
  }

  *w = (ZnDim) lf->clip_width;
  *h = (ZnDim) lf->clip_height;
  
  return True;
}


void
ZnLFGetField(ZnLabelFormat      lf,
             unsigned int       field,
             char               *x_attach,
             char               *y_attach,
             char               *x_dim,
             char               *y_dim,
             int                *x_spec,
             int                *y_spec,
             short              *width_spec,
             short              *height_spec)
{
  ZnFieldFormat fptr;

  fptr = &lf->fields[field];
  *x_attach = fptr->x_attach;
  *y_attach = fptr->y_attach;
  *x_dim = fptr->x_dim;
  *y_dim = fptr->y_dim;
  *x_spec = fptr->x_spec;
  *y_spec = fptr->y_spec;
  *width_spec = fptr->width_spec;
  *height_spec = fptr->height_spec;
}


/*
 ****************************************************************
 *
 * Code for line ends.
 *
 ****************************************************************
 */
static Tcl_HashTable    line_end_cache;
static ZnBool           line_end_inited = False;


ZnLineEnd
ZnLineEndCreate(Tcl_Interp      *interp,
                char            *line_end_str)
{
  Tcl_HashEntry *entry;
  ZnLineEnd     le;
  int           new, argc;
  ZnReal        a, b, c;
  
  if (!line_end_inited) {
    Tcl_InitHashTable(&line_end_cache, TCL_STRING_KEYS);
    line_end_inited = True;
  }

  entry = Tcl_CreateHashEntry(&line_end_cache, line_end_str, &new);
  if (!new) {
    le = (ZnLineEnd) Tcl_GetHashValue(entry);
    le->ref_count++;
    return le;
  }

  argc = sscanf(line_end_str, "%lf %lf %lf", &a, &b, &c);
  if (argc == 3) {
    le = (ZnLineEnd) ZnMalloc(sizeof(ZnLineEndStruct));
    le->shape_a = a;
    le->shape_b = b;
    le->shape_c = c;
    le->entry = entry;
    le->ref_count = 1;
    Tcl_SetHashValue(entry, (ClientData) le);
    return le;
  }
  else {
    Tcl_AppendResult(interp, "incorrect line end spec: \"",
                     line_end_str, "\", should be: shapeA shapeB shapeC", NULL);
    return NULL;
  }
}


char *
ZnLineEndGetString(ZnLineEnd    le)
{
  return Tcl_GetHashKey(&line_end_cache, le->entry);
}


void
ZnLineEndDelete(ZnLineEnd       le)
{
  le->ref_count--;
  if (le->ref_count == 0) {
    Tcl_DeleteHashEntry(le->entry);
    ZnFree(le);
  }
}


ZnLineEnd
ZnLineEndDuplicate(ZnLineEnd    le)
{
  le->ref_count++;
  return le;
}


/*
 ******************************************************************
 *
 * Code for fill rules. They are directly inhereted from the
 * GLU tesselator constants.
 *
 ******************************************************************
 */
#define FILL_RULE_ODD_SPEC       "odd"
#define FILL_RULE_NON_ZERO_SPEC  "nonzero"
#define FILL_RULE_POSITIVE_SPEC  "positive"
#define FILL_RULE_NEGATIVE_SPEC  "negative"
#define FILL_RULE_ABS_GEQ_2_SPEC "abs_geq_2"

int
ZnGetFillRule(ZnWInfo    *wi,
              char       *name,
              ZnFillRule *fill_rule)
{
  unsigned int len;

  len = strlen(name);
  if (strncmp(name, FILL_RULE_ODD_SPEC, len) == 0) {
    *fill_rule = GLU_TESS_WINDING_ODD;
  }
  else if (strncmp(name, FILL_RULE_NON_ZERO_SPEC, len) == 0) {
    *fill_rule = GLU_TESS_WINDING_NONZERO;
  }
  else if (strncmp(name, FILL_RULE_POSITIVE_SPEC, len) == 0) {
    *fill_rule = GLU_TESS_WINDING_POSITIVE;
  }
  else if (strncmp(name, FILL_RULE_NEGATIVE_SPEC, len) == 0) {
    *fill_rule = GLU_TESS_WINDING_NEGATIVE;
  }
  else if (strncmp(name, FILL_RULE_ABS_GEQ_2_SPEC, len) == 0) {
    *fill_rule = GLU_TESS_WINDING_ABS_GEQ_TWO;
  }
  else  {
    Tcl_AppendResult(wi->interp, "bad fill rule \"", name, "\": must be ",
                     FILL_RULE_ODD_SPEC, ", ",
                     FILL_RULE_NON_ZERO_SPEC, ", ",
                     FILL_RULE_POSITIVE_SPEC, ", ",
                     FILL_RULE_NEGATIVE_SPEC, ", ",
                     FILL_RULE_ABS_GEQ_2_SPEC,
                     NULL);
    return TCL_ERROR;
  }
  return TCL_OK;
}

char *
ZnNameOfFillRule(ZnFillRule fill_rule)
{
  switch (fill_rule) {
  case GLU_TESS_WINDING_ODD:
    return FILL_RULE_ODD_SPEC;
  case GLU_TESS_WINDING_NONZERO:
    return FILL_RULE_NON_ZERO_SPEC;
  case GLU_TESS_WINDING_POSITIVE:
    return FILL_RULE_POSITIVE_SPEC;
  case GLU_TESS_WINDING_NEGATIVE:
    return FILL_RULE_NEGATIVE_SPEC;
  case GLU_TESS_WINDING_ABS_GEQ_TWO:
    return FILL_RULE_ABS_GEQ_2_SPEC;
  default:
    return "unknown fill rule";
  }
}


/*
 ******************************************************************
 *
 * Code for auto alignments in fields.
 *
 ******************************************************************
 */
int
ZnGetAutoAlign(ZnWInfo          *wi,
               char             *name,
               ZnAutoAlign      *aa)
{
  int       j;
  
  if (strcmp(name, "-") == 0) {
    aa->automatic = False;
  }
  else if (strlen(name) == 3) {
    aa->automatic = True;
    for (j = 0; j < 3; j++) {
      switch(name[j]) {
      case 'l':
      case 'L':
        aa->align[j] = TK_JUSTIFY_LEFT;
        break;
      case 'c':
      case 'C':
        aa->align[j] = TK_JUSTIFY_CENTER;
        break;
      case 'r':
      case 'R':
        aa->align[j] = TK_JUSTIFY_RIGHT;
        break;
      default:
        goto aa_error;
      }
    }
  }
  else {
  aa_error:
    Tcl_AppendResult(wi->interp, "invalid auto alignment specification \"", name,
                     "\" should be - or a triple of lcr", NULL);
    return TCL_ERROR;
  }
  return TCL_OK;
}

/*
 * name must be large enough to hold the returned string.
 * 64 chars should be enough with the current values.
 */
void
ZnNameOfAutoAlign(ZnAutoAlign *aa,
                  char        *name)
{
  unsigned int i;
  
  if (aa->automatic == False) {
    strcpy(name, "-");
  }
  else {
    name[0] = 0;
    for (i = 0; i < 3; i++) {
      switch (aa->align[i]) {
      case TK_JUSTIFY_LEFT:
        strcat(name, "l");
        break;
      case TK_JUSTIFY_CENTER:
        strcat(name, "c");
        break;
      case TK_JUSTIFY_RIGHT:
        strcat(name, "r");
        break;
      }
    }
  }
}
