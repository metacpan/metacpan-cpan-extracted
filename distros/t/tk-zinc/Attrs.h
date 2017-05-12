/*
 * Attrs.h -- Header for the attribute manipulation routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Fri Dec 31 10:06:37 1999
 *
 * $Id: Attrs.h,v 1.9 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Attrs_h
#define _Attrs_h

#ifdef __CPLUSPLUS__
extern "C" {
#endif


#include <Types.h>
  

struct _ZnWInfo;

/*
 * Type and constant values for line styles.
 */
typedef unsigned char   ZnLineStyle;

#define ZN_LINE_SIMPLE  0
#define ZN_LINE_DASHED  1
#define ZN_LINE_MIXED   2
#define ZN_LINE_DOTTED  3

int ZnGetLineStyle(struct _ZnWInfo *wi, char *name, ZnLineStyle *line_style);
char *ZnNameOfLineStyle(ZnLineStyle line_style);


/*
 * Type and constant values for line shapes.
 */
typedef unsigned char   ZnLineShape;

#define ZN_LINE_STRAIGHT                0
#define ZN_LINE_LEFT_LIGHTNING          1
#define ZN_LINE_LEFT_CORNER             2
#define ZN_LINE_DOUBLE_LEFT_CORNER      3
#define ZN_LINE_RIGHT_LIGHTNING         4
#define ZN_LINE_RIGHT_CORNER            5
#define ZN_LINE_DOUBLE_RIGHT_CORNER     6

int ZnGetLineShape(struct _ZnWInfo *wi, char *name, ZnLineShape *line_shape);
char *ZnNameOfLineShape(ZnLineShape line_shape);


/*
 * Type and constant values for relief styles.
 */
typedef unsigned char   ZnReliefStyle;
#define ZN_RELIEF_FLAT          0
#define ZN_RELIEF_RAISED        1
#define ZN_RELIEF_SUNKEN        2
#define ZN_RELIEF_GROOVE        (ZN_RELIEF_TWO_FACES|ZN_RELIEF_SUNKEN)
#define ZN_RELIEF_RIDGE         (ZN_RELIEF_TWO_FACES|ZN_RELIEF_RAISED)
#define ZN_RELIEF_ROUND_SUNKEN  (ZN_RELIEF_ROUND|ZN_RELIEF_SUNKEN)
#define ZN_RELIEF_ROUND_RAISED  (ZN_RELIEF_ROUND|ZN_RELIEF_RAISED)
#define ZN_RELIEF_ROUND_GROOVE  (ZN_RELIEF_ROUND|ZN_RELIEF_TWO_FACES|ZN_RELIEF_SUNKEN)
#define ZN_RELIEF_ROUND_RIDGE   (ZN_RELIEF_ROUND|ZN_RELIEF_TWO_FACES|ZN_RELIEF_RAISED)
#define ZN_RELIEF_SUNKEN_RULE   (ZN_RELIEF_ROUND|ZN_RELIEF_TWO_FACES|ZN_RELIEF_SUNKEN|ZN_RELIEF_RULE)
#define ZN_RELIEF_RAISED_RULE   (ZN_RELIEF_ROUND|ZN_RELIEF_TWO_FACES|ZN_RELIEF_RAISED|ZN_RELIEF_RULE)
#define ZN_RELIEF_ROUND         0x80
#define ZN_RELIEF_TWO_FACES     0x40
#define ZN_RELIEF_RULE          0x20
#define ZN_RELIEF_MASK          0x3

/*
 * Number of steps for relief drawing. This translate in
 * RELIEF_STEPS*2+1 color shades in the color gradient.
 */
#define ZN_RELIEF_STEPS         6
  
int ZnGetRelief(struct _ZnWInfo *wi, char *name, ZnReliefStyle *relief);
char *ZnNameOfRelief(ZnReliefStyle relief);


/*
 * Type and constant values for borders.
 */
typedef unsigned char   ZnBorder;
#define ZN_NO_BORDER            0
#define ZN_LEFT_BORDER          1
#define ZN_RIGHT_BORDER         2
#define ZN_TOP_BORDER           4
#define ZN_BOTTOM_BORDER        8
#define ZN_CONTOUR_BORDER       (ZN_LEFT_BORDER|ZN_RIGHT_BORDER|ZN_TOP_BORDER|ZN_BOTTOM_BORDER)
#define ZN_COUNTER_OBLIQUE      16
#define ZN_OBLIQUE              32

void ZnNameOfBorder(ZnBorder border, char *str);
int ZnGetBorder(struct _ZnWInfo *wi, Tcl_Obj *name, ZnBorder *border);


/*
 * Type for leader anchors.
 */
typedef struct {
  int           left_x;         /* left leader anchor field or percent of bbox */
  int           right_x;        /* right leader anchor field or percent of bbox */
  short         left_y;         /* left leader percent of bbox or < 0 if field */
  short         right_y;        /* right leader percent of bbox or < 0 if field */
} ZnLeaderAnchorsStruct, *ZnLeaderAnchors;

int ZnGetLeaderAnchors(struct _ZnWInfo *wi, char *name, ZnLeaderAnchors *leader_anchors);
void ZnNameOfLeaderAnchors(ZnLeaderAnchors leader_anchors, char *name);


/*
 * Type and constant values for automatic alignments.
 */
typedef struct {
  ZnBool        automatic;
  Tk_Justify    align[3];
} ZnAutoAlign;
#define ZN_AA_LEFT              0
#define ZN_AA_CENTER            1
#define ZN_AA_RIGHT             2

int ZnGetAutoAlign(struct _ZnWInfo *wi, char *name, ZnAutoAlign *aa);
void ZnNameOfAutoAlign(ZnAutoAlign *aa, char *name);


/*
 * Label Formats.
 */
  
/*
 * field flags.
 */
#define ZN_LF_ATTACH_PIXEL      0
#define ZN_LF_ATTACH_FWD        1
#define ZN_LF_ATTACH_BWD        2
#define ZN_LF_ATTACH_LEFT       3       /* Align left on left or top on top */
#define ZN_LF_ATTACH_RIGHT      4       /* Align right on right or bottom on bottom */

#define ZN_LF_DIM_PIXEL 0
#define ZN_LF_DIM_FONT  1
#define ZN_LF_DIM_ICON  2
#define ZN_LF_DIM_AUTO  3
#define ZN_LF_DIM_LABEL 4
  
typedef struct {
  int   x_spec;
  int   y_spec;
  short width_spec;
  short height_spec;
  char  x_attach;
  char  y_attach;
  char  x_dim;
  char  y_dim;
} ZnFieldFormatStruct, *ZnFieldFormat;

typedef struct {
  short         clip_width;
  short         clip_height;
  unsigned int  num_fields;
  Tcl_HashEntry *entry;
  unsigned int  ref_count;
  ZnFieldFormatStruct fields[1];
} ZnLabelFormatStruct, *ZnLabelFormat;
  

ZnLabelFormat
ZnLFCreate(Tcl_Interp   * /* interp */,
           char         * /* format_str */,
           unsigned int /* num_fields */);
ZnLabelFormat
ZnLFDuplicate(ZnLabelFormat     /* label_format */);
void
ZnLFDelete(ZnLabelFormat        /* label_format */);
char *
ZnLFGetString(ZnLabelFormat     /* label_format */);
ZnBool
ZnLFGetClipBox(ZnLabelFormat    /* label_format */,
               ZnDim            * /* width */,
               ZnDim            * /* height */);
#define ZnLFNumFields(lf)       ((lf)->num_fields)
void
ZnLFGetField(ZnLabelFormat      /* label_format */,
             unsigned int       /* field */,
             char               * /* x_attach */,
             char               * /* y_attach */,
             char               * /* x_dim */,
             char               * /* y_dim */,
             int                * /* x_spec */,
             int                * /* y_spec */,
             short              * /* width_spec */,
             short              * /* height_spec */);

/*
 * Line Ends.
 */
typedef struct {
  ZnReal        shape_a;
  ZnReal        shape_b;
  ZnReal        shape_c;
  Tcl_HashEntry *entry;
  unsigned int  ref_count;
} ZnLineEndStruct, *ZnLineEnd;

ZnLineEnd
ZnLineEndCreate(Tcl_Interp      *interp,
                char            *line_end_str);
ZnLineEnd
ZnLineEndDuplicate(ZnLineEnd    le);
void
ZnLineEndDelete(ZnLineEnd       le);
char *
ZnLineEndGetString(ZnLineEnd    le);


/*
 * Type and protypes for fill rules.
 */
typedef unsigned int    ZnFillRule;

char *ZnNameOfFillRule(ZnFillRule fill_rule);
int ZnGetFillRule(struct _ZnWInfo *wi, char *name, ZnFillRule *fill_rule);


#ifdef __CPLUSPLUS__
}
#endif

#endif  /* _Attrs_h */
