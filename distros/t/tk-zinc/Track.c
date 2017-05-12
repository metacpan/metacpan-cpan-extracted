/*
 * Track.c -- Implementation of Track and WayPoint items.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Track.c,v 1.88 2006/02/14 09:01:07 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#include "Types.h"
#include "Track.h"
#include "Draw.h"
#include "Geo.h"
#include "Item.h"
#include "Group.h"
#include "WidgetInfo.h"
#include "Image.h"
#include "tkZinc.h"

#include <ctype.h>
#include <stdlib.h>


static const char rcsid[] = "$Id: Track.c,v 1.88 2006/02/14 09:01:07 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";

/*
 * Define this to enable overlap manager setting
 * the label distance rho.
 */
#undef DP

/*
 * Some default values
*/
#define DEFAULT_MARKER_SIZE             0
#define DEFAULT_LABEL_ANGLE             20
#define DEFAULT_LABEL_DISTANCE          50
#define DEFAULT_LINE_WIDTH              1
#define DEFAULT_LABEL_PREFERRED_ANGLE   0
#define DEFAULT_CONVERGENCE_STYLE       0

#define SPEED_VECTOR_PICKING_THRESHOLD  5       /* In pixels    */

/*
 * Sets a threshold for calculating distance from label_dx, label_dy.
 * Above this threshold value, the module is discarded, label_distance
 * is preferred.
 */
#define LABEL_DISTANCE_THRESHOLD 5 

#define MARKER_FILLED_BIT               1 << 0
#define FILLED_HISTORY_BIT              1 << 1
#define DOT_MIXED_HISTORY_BIT           1 << 2
#define CIRCLE_HISTORY_BIT              1 << 3
#define SV_MARK_BIT                     1 << 4
#define SV_TICKS_BIT                    1 << 5
#define POLAR_BIT                       1 << 6
#define FROZEN_LABEL_BIT                1 << 7
#define LAST_AS_FIRST_BIT               1 << 8
#define HISTORY_VISIBLE_BIT             1 << 9

#define CURRENT_POSITION        -2
#define LEADER                  -3
#define CONNECTION              -4
#define SPEED_VECTOR            -5


/*
**********************************************************************************
*
* Specific Track item record
*
**********************************************************************************
*/
typedef struct {
  ZnPoint       world;  /* world coord of pos    */
  ZnPoint       dev;    /* dev coord of pos      */
  ZnBool        visible;
} HistoryStruct, *History;
  
typedef struct _TrackItemStruct {
  ZnItemStruct  header;
  
  /* Public data */
  unsigned short flags;
  ZnImage       symbol;                 /* item symbol                  */
  ZnGradient    *symbol_color;
  int           label_angle;            /* Label angle from track (degree). */
  ZnDim         label_distance;         /* Label distance from track. */
  ZnDim         label_dx;               /* Label dx/dy from track.      */
  ZnDim         label_dy;
  int           label_preferred_angle;
  int           label_convergence_style;
  Tk_Anchor     label_anchor;
  ZnLeaderAnchors leader_anchors;       /* Spec of the leader attachment */
  ZnGradient    *leader_color;          /* leader color                 */
  ZnLineStyle   leader_style;
  ZnLineShape   leader_shape;
  ZnLineEnd     leader_first_end;
  ZnLineEnd     leader_last_end;
  ZnDim         leader_width;
  ZnDim         marker_size;            /* world size of error circle   */
  ZnGradient    *marker_color;          /* error circle color           */
  ZnLineStyle   marker_style;           /* error circle style           */
  ZnImage       marker_fill_pattern;    /* error circle fill pattern    */
  ZnGradient    *connection_color;      /* connection color             */
  ZnLineStyle   connection_style;
  ZnDim         connection_width;
  ZnGradient    *speed_vector_color;    /* s. v. color                  */
  ZnPoint       pos;                    /* item world coordinates       */
  ZnPoint       speed_vector;           /* s. v. slope in world coord   */
  ZnDim         speed_vector_width;
  ZnGradient    *history_color;
  ZnDim         history_width;

  /* Private data */
  ZnFieldSetStruct field_set;
  ZnPoint       dev;                    /* device coords of current pos */
  ZnPoint       speed_vector_dev;       /* s. v. end in device coord    */
  ZnDim         marker_size_dev;        /* dev size of error circle     */
  ZnList        history;                /* pos list                     */
  ZnList        leader_points;
} TrackItemStruct, *TrackItem;


static ZnAttrConfig     track_attrs[] = {
  { ZN_CONFIG_BOOL, "-circlehistory", NULL,
    Tk_Offset(TrackItemStruct, flags), CIRCLE_HISTORY_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ITEM, "-connecteditem", NULL,
    Tk_Offset(TrackItemStruct, header.connected_item), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-connectioncolor", NULL,
    Tk_Offset(TrackItemStruct, connection_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-connectionsensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(CONNECTION),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-connectionstyle", NULL,
    Tk_Offset(TrackItemStruct, connection_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-connectionwidth", NULL,
    Tk_Offset(TrackItemStruct, connection_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-filledhistory", NULL,
    Tk_Offset(TrackItemStruct, flags), FILLED_HISTORY_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-filledmarker", NULL,
    Tk_Offset(TrackItemStruct, flags), MARKER_FILLED_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-frozenlabel", NULL,
    Tk_Offset(TrackItemStruct, flags), FROZEN_LABEL_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-historycolor", NULL,
    Tk_Offset(TrackItemStruct, history_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-historywidth", NULL,
    Tk_Offset(TrackItemStruct, history_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-labelanchor", NULL,
    Tk_Offset(TrackItemStruct, label_anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ANGLE, "-labelangle", NULL,
    Tk_Offset(TrackItemStruct, label_angle), 0,
    ZN_COORDS_FLAG|ZN_POLAR_FLAG, False },
  { ZN_CONFIG_UINT, "-labelconvergencestyle", NULL,
    Tk_Offset(TrackItemStruct, label_convergence_style), 0, 0, False },
  { ZN_CONFIG_DIM, "-labeldistance", NULL,
    Tk_Offset(TrackItemStruct, label_distance), 0,
    ZN_COORDS_FLAG|ZN_POLAR_FLAG, False },
  { ZN_CONFIG_DIM, "-labeldx", NULL,
    Tk_Offset(TrackItemStruct, label_dx), 0,
    ZN_COORDS_FLAG|ZN_CARTESIAN_FLAG, False },
  { ZN_CONFIG_DIM, "-labeldy", NULL,
    Tk_Offset(TrackItemStruct, label_dy), 0,
    ZN_COORDS_FLAG|ZN_CARTESIAN_FLAG, False },
  { ZN_CONFIG_LABEL_FORMAT, "-labelformat", NULL,
    Tk_Offset(TrackItemStruct, field_set.label_format), 0,
    ZN_COORDS_FLAG|ZN_CLFC_FLAG, False },
  { ZN_CONFIG_ANGLE, "-labelpreferredangle", NULL,
    Tk_Offset(TrackItemStruct, label_preferred_angle), 0, 0, False },
  { ZN_CONFIG_BOOL, "-lastasfirst", NULL,
    Tk_Offset(TrackItemStruct, flags), LAST_AS_FIRST_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LEADER_ANCHORS, "-leaderanchors", NULL,
    Tk_Offset(TrackItemStruct, leader_anchors), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-leadercolor", NULL,
    Tk_Offset(TrackItemStruct, leader_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_END, "-leaderfirstend", NULL,
    Tk_Offset(TrackItemStruct, leader_first_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_END, "-leaderlastend", NULL,
    Tk_Offset(TrackItemStruct, leader_last_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-leadersensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(LEADER),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-leaderstyle", NULL,
    Tk_Offset(TrackItemStruct, leader_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_SHAPE, "-leadershape", NULL,
    Tk_Offset(TrackItemStruct, leader_shape), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_DIM, "-leaderwidth", NULL,
    Tk_Offset(TrackItemStruct, leader_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-markercolor", NULL,
    Tk_Offset(TrackItemStruct, marker_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BITMAP, "-markerfillpattern", NULL,
    Tk_Offset(TrackItemStruct, marker_fill_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-markersize", NULL,
    Tk_Offset(TrackItemStruct, marker_size), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-markerstyle", NULL,
    Tk_Offset(TrackItemStruct, marker_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-mixedhistory", NULL,
    Tk_Offset(TrackItemStruct, flags), DOT_MIXED_HISTORY_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_UINT, "-numfields", NULL,
    Tk_Offset(TrackItemStruct, field_set.num_fields), 0, 0, True },
  { ZN_CONFIG_POINT, "-position", NULL, Tk_Offset(TrackItemStruct, pos), 0,
    ZN_COORDS_FLAG|ZN_MOVED_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(TrackItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_SENSITIVE_BIT, ZN_REPICK_FLAG, False },
  { ZN_CONFIG_POINT, "-speedvector", NULL, Tk_Offset(TrackItemStruct, speed_vector), 0,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-speedvectorcolor", NULL,
    Tk_Offset(TrackItemStruct, speed_vector_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-speedvectormark", NULL,
    Tk_Offset(TrackItemStruct, flags), SV_MARK_BIT, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-speedvectorsensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(SPEED_VECTOR),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-speedvectorticks", NULL,
    Tk_Offset(TrackItemStruct, flags), SV_TICKS_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-speedvectorwidth", NULL,
    Tk_Offset(TrackItemStruct, speed_vector_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BITMAP, "-symbol", NULL,
    Tk_Offset(TrackItemStruct, symbol), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-symbolcolor", NULL,
    Tk_Offset(TrackItemStruct, symbol_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-symbolsensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(CURRENT_POSITION),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(TrackItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_VISIBLE_BIT,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG|ZN_VIS_FLAG, False },
  { ZN_CONFIG_BOOL, "-historyvisible", NULL,
    Tk_Offset(TrackItemStruct, flags), HISTORY_VISIBLE_BIT, ZN_COORDS_FLAG, False },
  
  { ZN_CONFIG_END, NULL, NULL, 0, 0, 0, False }
};

static ZnAttrConfig     wp_attrs[] = {
  { ZN_CONFIG_BOOL, "-composealpha", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_COMPOSE_ALPHA_BIT,
    ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-composerotation", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_COMPOSE_ROTATION_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-composescale", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_COMPOSE_SCALE_BIT,
    ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ITEM, "-connecteditem", NULL,
    Tk_Offset(TrackItemStruct, header.connected_item), 0,
    ZN_COORDS_FLAG|ZN_ITEM_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-connectioncolor", NULL,
    Tk_Offset(TrackItemStruct, connection_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-connectionsensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(CONNECTION),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-connectionstyle", NULL,
    Tk_Offset(TrackItemStruct, connection_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-connectionwidth", NULL,
    Tk_Offset(TrackItemStruct, connection_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-filledmarker", NULL,
    Tk_Offset(TrackItemStruct, flags), MARKER_FILLED_BIT, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_ANCHOR, "-labelanchor", NULL,
    Tk_Offset(TrackItemStruct, label_anchor), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_ANGLE, "-labelangle", NULL,
    Tk_Offset(TrackItemStruct, label_angle), 0,
    ZN_COORDS_FLAG|ZN_POLAR_FLAG, False },
  { ZN_CONFIG_DIM, "-labeldistance", NULL,
    Tk_Offset(TrackItemStruct, label_distance), 0,
    ZN_COORDS_FLAG|ZN_POLAR_FLAG, False },
  { ZN_CONFIG_DIM, "-labeldx", NULL,
    Tk_Offset(TrackItemStruct, label_dx), 0,
    ZN_COORDS_FLAG|ZN_CARTESIAN_FLAG, False },
  { ZN_CONFIG_DIM, "-labeldy", NULL,
    Tk_Offset(TrackItemStruct, label_dy), 0,
    ZN_COORDS_FLAG|ZN_CARTESIAN_FLAG, False },
  { ZN_CONFIG_LABEL_FORMAT, "-labelformat", NULL,
    Tk_Offset(TrackItemStruct, field_set.label_format), 0,
    ZN_COORDS_FLAG|ZN_CLFC_FLAG, False },
  { ZN_CONFIG_LEADER_ANCHORS, "-leaderanchors", NULL,
    Tk_Offset(TrackItemStruct, leader_anchors), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-leadercolor", NULL,
    Tk_Offset(TrackItemStruct, leader_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_LINE_END, "-leaderfirstend", NULL,
    Tk_Offset(TrackItemStruct, leader_first_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_END, "-leaderlastend", NULL,
    Tk_Offset(TrackItemStruct, leader_last_end), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_BOOL, "-leadersensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(LEADER),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_LINE_SHAPE, "-leadershape", NULL,
    Tk_Offset(TrackItemStruct, leader_shape), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-leaderstyle", NULL,
    Tk_Offset(TrackItemStruct, leader_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-leaderwidth", NULL,
    Tk_Offset(TrackItemStruct, leader_width), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-markercolor", NULL,
    Tk_Offset(TrackItemStruct, marker_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BITMAP, "-markerfillpattern", NULL,
    Tk_Offset(TrackItemStruct, marker_fill_pattern), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_DIM, "-markersize", NULL,
    Tk_Offset(TrackItemStruct, marker_size), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_LINE_STYLE, "-markerstyle", NULL,
    Tk_Offset(TrackItemStruct, marker_style), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_UINT, "-numfields", NULL,
    Tk_Offset(TrackItemStruct, field_set.num_fields), 0, 0, True },
  { ZN_CONFIG_POINT, "-position", NULL, Tk_Offset(TrackItemStruct, pos), 0,
    ZN_COORDS_FLAG, False},
  { ZN_CONFIG_PRI, "-priority", NULL,
    Tk_Offset(TrackItemStruct, header.priority), 0,
    ZN_DRAW_FLAG|ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BOOL, "-sensitive", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_SENSITIVE_BIT, ZN_REPICK_FLAG, False },
  { ZN_CONFIG_BITMAP, "-symbol", NULL,
    Tk_Offset(TrackItemStruct, symbol), 0, ZN_COORDS_FLAG, False },
  { ZN_CONFIG_GRADIENT, "-symbolcolor", NULL,
    Tk_Offset(TrackItemStruct, symbol_color), 0, ZN_DRAW_FLAG, False },
  { ZN_CONFIG_BOOL, "-symbolsensitive", NULL,
    Tk_Offset(TrackItemStruct, header.part_sensitive), ZnPartToBit(CURRENT_POSITION),
    ZN_REPICK_FLAG, False },
  { ZN_CONFIG_TAG_LIST, "-tags", NULL,
    Tk_Offset(TrackItemStruct, header.tags), 0, 0, False },
  { ZN_CONFIG_BOOL, "-visible", NULL,
    Tk_Offset(TrackItemStruct, header.flags), ZN_VISIBLE_BIT,
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
  TrackItem     track = (TrackItem) item;
  ZnFieldSet    field_set = &track->field_set;
  ZnWInfo       *wi = item->wi;
  int           num_fields;

  /*printf("size of a track = %d\n", sizeof(TrackItemStruct));*/
   
  SET(item->flags, ZN_VISIBLE_BIT);
  SET(item->flags, ZN_SENSITIVE_BIT);
  SET(item->flags, ZN_COMPOSE_ALPHA_BIT);
  SET(item->flags, ZN_COMPOSE_ROTATION_BIT);
  SET(item->flags, ZN_COMPOSE_SCALE_BIT);
  SET(item->part_sensitive, ZnPartToBit(CURRENT_POSITION));
  SET(item->part_sensitive, ZnPartToBit(LEADER));
  SET(item->part_sensitive, ZnPartToBit(CONNECTION));
  SET(item->part_sensitive, ZnPartToBit(SPEED_VECTOR));
  track->symbol_color = ZnGetGradientByValue(wi->fore_color);
  track->symbol = ZnGetImageByValue(wi->track_symbol, NULL, NULL);
  track->label_anchor = TK_ANCHOR_CENTER;
  track->label_angle = DEFAULT_LABEL_ANGLE;
  track->label_distance = DEFAULT_LABEL_DISTANCE;
  SET(track->flags, POLAR_BIT);
  CLEAR(track->flags, FROZEN_LABEL_BIT);

  track->label_preferred_angle   = DEFAULT_LABEL_PREFERRED_ANGLE;
  track->label_convergence_style = DEFAULT_CONVERGENCE_STYLE ;
 
  track->leader_anchors = NULL;
  track->leader_color = ZnGetGradientByValue(wi->fore_color);
  track->leader_style = ZN_LINE_SIMPLE;
  track->leader_shape = ZN_LINE_STRAIGHT;
  track->leader_width = DEFAULT_LINE_WIDTH;
  track->connection_color = ZnGetGradientByValue(wi->fore_color);
  track->connection_style = ZN_LINE_SIMPLE;
  track->connection_width = DEFAULT_LINE_WIDTH;
  track->marker_color = ZnGetGradientByValue(wi->fore_color);
  track->marker_style = ZN_LINE_SIMPLE;
  track->marker_fill_pattern = ZnUnspecifiedImage;
  track->speed_vector_color = ZnGetGradientByValue(wi->fore_color);
  track->history_color = ZnGetGradientByValue(wi->fore_color);
        track->history_width = 8;
  CLEAR(track->flags, MARKER_FILLED_BIT);
  SET(track->flags, FILLED_HISTORY_BIT);
  CLEAR(track->flags, DOT_MIXED_HISTORY_BIT);
  CLEAR(track->flags, CIRCLE_HISTORY_BIT);
  CLEAR(track->flags, LAST_AS_FIRST_BIT);
  CLEAR(track->flags, SV_MARK_BIT);
  CLEAR(track->flags, SV_TICKS_BIT);
  
  if (item->class == ZnTrack) {
    item->priority = 1;
    SET(track->flags, HISTORY_VISIBLE_BIT);
    track->marker_size = DEFAULT_MARKER_SIZE;
    track->speed_vector.x = 0;
    track->speed_vector.y = 0;
    track->speed_vector_width = DEFAULT_LINE_WIDTH;
  }
  else {
    item->priority = 1;
    CLEAR(track->flags, HISTORY_VISIBLE_BIT);
    track->marker_size = 0;
    track->speed_vector.x = 0.0;
    track->speed_vector.y = 10.0;
  }
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
  
  track->pos.x = 0;
  track->pos.y = 0;
  track->field_set.label_pos.x = 0;
  track->field_set.label_pos.y = 0;
  track->leader_first_end = NULL;
  track->leader_last_end = NULL;

  track->history = NULL;
  track->dev.x = 0;
  track->dev.y = 0;
  track->speed_vector_dev.x = 0;
  track->speed_vector_dev.y = 0;
  track->marker_size_dev = 0;
  track->leader_points = NULL;

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
  TrackItem     track = (TrackItem) item;

  if (track->history) {
    track->history = ZnListDuplicate(track->history);
  }
  track->dev.x = 0;
  track->dev.y = 0;
  track->speed_vector_dev.x = 0;
  track->speed_vector_dev.y = 0;
  track->marker_size_dev = 0;
  if (track->leader_points) {
    track->leader_points = ZnListDuplicate(track->leader_points);
  }
  if (track->leader_first_end) {
    ZnLineEndDuplicate(track->leader_first_end);
  }
  if (track->leader_last_end) {
    ZnLineEndDuplicate(track->leader_last_end);
  }
  
  ZnFIELD.CloneFields(&track->field_set);
  track->field_set.item = item;

  /*
   * We get all shared resources, colors bitmaps.
   */
  track->symbol_color = ZnGetGradientByValue(track->symbol_color);
  track->leader_color = ZnGetGradientByValue(track->leader_color);
  track->connection_color = ZnGetGradientByValue(track->connection_color);
  track->marker_color = ZnGetGradientByValue(track->marker_color);
  track->speed_vector_color = ZnGetGradientByValue(track->speed_vector_color);
  track->history_color = ZnGetGradientByValue(track->history_color);
  if (track->symbol != ZnUnspecifiedImage) {
    track->symbol = ZnGetImageByValue(track->symbol, NULL, NULL);
  }
  if (track->marker_fill_pattern != ZnUnspecifiedImage) {
    track->marker_fill_pattern = ZnGetImageByValue(track->marker_fill_pattern, NULL, NULL);
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
  TrackItem     track   = (TrackItem) item;

  if (track->leader_points) {
    ZnListFree(track->leader_points);
  }
  if (track->leader_first_end) {
    ZnLineEndDelete(track->leader_first_end);
  }
  if (track->leader_last_end) {
    ZnLineEndDelete(track->leader_last_end);
  }

  if (track->history) {
    ZnListFree(track->history);
  }
  
  /*
   * Release shared resources.
   */
  ZnFreeGradient(track->symbol_color);
  ZnFreeGradient(track->leader_color);
  ZnFreeGradient(track->connection_color);
  ZnFreeGradient(track->marker_color);
  ZnFreeGradient(track->speed_vector_color);
  ZnFreeGradient(track->history_color);
  if (track->symbol != ZnUnspecifiedImage) {
    ZnFreeImage(track->symbol, NULL, NULL);
    track->symbol = ZnUnspecifiedImage;
  }
  if (track->marker_fill_pattern != ZnUnspecifiedImage) {
    ZnFreeImage(track->marker_fill_pattern, NULL, NULL);
    track->marker_fill_pattern = ZnUnspecifiedImage;
  }

  ZnFIELD.FreeFields(&track->field_set);
}


/*
**********************************************************************************
*
* Configure --
*
**********************************************************************************
*/
static void
AddToHistory(TrackItem  track,
             ZnPoint    old_pos)
{
  ZnWInfo       *wi = ((ZnItem) track)->wi;
  
  if (track->history) {
    HistoryStruct       hist;
    
    hist.world = old_pos;
    hist.dev = track->dev;
    hist.visible = True;
    ZnListAdd(track->history, &hist, ZnListHead);
    ZnListTruncate(track->history, wi->track_managed_history_size);
  }
  else {
    /* We do not shift the first time we move as the preceding position
     * is not valid. */
    /*printf("creating history\n");*/
    track->history = ZnListNew(wi->track_managed_history_size+1,
                               sizeof(HistoryStruct));
  }
}

static int
Configure(ZnItem        item,
          int           argc,
          Tcl_Obj *CONST argv[],
          int           *flags)
{
  TrackItem     track = (TrackItem) item;
  ZnWInfo       *wi = item->wi;
  ZnItem        old_connected;
  ZnPoint       old_pos;
  
  old_pos = track->pos;
  old_connected = item->connected_item;
  
  if (ZnConfigureAttributes(wi, item, item, track_attrs, argc, argv, flags) == TCL_ERROR) {
    return TCL_ERROR;
  }
  
  if (track->label_angle < 0) {
    track->label_angle = 360 + track->label_angle;
  }

  /*
   * Adapt to the new label locating system.
   */
  if (ISSET(*flags, ZN_POLAR_FLAG)) {
    SET(track->flags, POLAR_BIT);
    ZnGroupSetCallOm(item->parent, True);
  }
  else if (ISSET(*flags, ZN_CARTESIAN_FLAG)) {
    CLEAR(track->flags, POLAR_BIT);
    ZnGroupSetCallOm(item->parent, True);
  }
  
  if (ISSET(*flags, ZN_ITEM_FLAG)) {
    /*
     * If the new connected item is not appropriate back up
     * to the old one.
     */
    if ((item->connected_item == ZN_NO_ITEM) ||
        (((item->connected_item->class == ZnTrack) ||
          (item->connected_item->class == ZnWayPoint)) &&
         (item->parent == item->connected_item->parent))) {
      ZnITEM.UpdateItemDependency(item, old_connected);
    }
    else {
      item->connected_item = old_connected;
    }
  }
  
  if (ISSET(*flags, ZN_VIS_FLAG)) {
    /* Record the change to trigger the overlap manager latter */
    if ((item->class == ZnTrack) && ISSET(item->flags, ZN_VISIBLE_BIT)) {
      ZnGroupSetCallOm(item->parent, True);
    }
  }
  
  /* If the current position has changed, shift the past pos. */
  if (ISSET(*flags, ZN_MOVED_FLAG)) {
    if (item->class == ZnTrack) {
      AddToHistory(track, old_pos);
      ZnGroupSetCallOm(item->parent, True);
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
  if (ZnQueryAttribute(item->wi->interp, item, track_attrs, argv[0]) == TCL_ERROR) {
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
  ZnWInfo       *wi = item->wi;
  TrackItem     track = (TrackItem) item;
  ZnFieldSet    field_set = &track->field_set;
  ZnItem        c_item;
  History       hist;
  ZnPoint       old_label_pos, old_pos, p, xp;
  ZnDim         old_label_width, old_label_height;
  ZnReal        rotation;
  ZnBBox        bbox;
  ZnPoint       *points;
  unsigned int  num_points, num_acc_pos, i;
  int           alignment, w_int, h_int;
  ZnReal        w2=0.0, h2=0.0, w=0.0, h=0.0;
  
  ZnResetBBox(&item->item_bounding_box);
  old_label_pos = field_set->label_pos;
  old_label_width = field_set->label_width;
  old_label_height = field_set->label_height;

  old_pos = track->dev;

  ZnTransformPoint(wi->current_transfo, &track->pos, &track->dev);
  track->dev.x = ZnNearestInt(track->dev.x);
  track->dev.y = ZnNearestInt(track->dev.y);
  /*printf("track pos %g %g --> %g %g\n", track->pos.x, track->pos.y, track->dev.x, track->dev.y);*/
  if (track->symbol != ZnUnspecifiedImage) {
    ZnSizeOfImage(track->symbol, &w_int, &h_int);
    /*printf("taille symbole %d %d\n", w, h);*/
    w2 = (w_int+1.0)/2.0;
    h2 = (h_int+1.0)/2.0;
    bbox.orig.x = track->dev.x - w2;
    bbox.orig.y = track->dev.y - h2;
    bbox.corner.x = track->dev.x + w2;
    bbox.corner.y = track->dev.y + h2;
    
    ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
  }
  
  /* Here we approximate the past position sizes to the size
     of the current position. They are actually smaller but who
     care :-). In fact it is even worse as we use the overall
     information from the symbol font.
  */
  if ((item->class == ZnTrack) && track->history) {
    unsigned int visible_history_size;
    /*
     * Trunc the visible history to the managed size.
     */
    ZnListTruncate(track->history, wi->track_managed_history_size);
    visible_history_size = (ISSET(track->flags, HISTORY_VISIBLE_BIT) ?
                            wi->track_visible_history_size : 0);

    ZnResetBBox(&bbox);
    w2 = (track->history_width+1.0)/2.0;
    num_acc_pos = ZnListSize(track->history);
    hist = ZnListArray(track->history);
    for (i = 0; i < num_acc_pos; i++) {
      ZnTransformPoint(wi->current_transfo, &hist[i].world, &hist[i].dev);
      if ((i < visible_history_size) && (hist[i].visible)) {
        bbox.orig.x = hist[i].dev.x - w2;
        bbox.orig.y = hist[i].dev.y - w2;
        bbox.corner.x = hist[i].dev.x + w2;
        bbox.corner.y = hist[i].dev.y + w2;
        ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
      }
    }
  }

  /*
   * Compute the speed vector end.
   */
  if (item->class == ZnTrack) {
    p.x = track->pos.x + track->speed_vector.x * wi->speed_vector_length;
    p.y = track->pos.y + track->speed_vector.y * wi->speed_vector_length;
    ZnTransformPoint(wi->current_transfo, &p, &track->speed_vector_dev);
    track->speed_vector_dev.x = ZnNearestInt(track->speed_vector_dev.x);
    track->speed_vector_dev.y = ZnNearestInt(track->speed_vector_dev.y);
    if (ISSET(track->flags, SV_MARK_BIT)) {
      w = track->speed_vector_width + 1.0;
      ZnAddPointToBBox(&item->item_bounding_box,
                       track->speed_vector_dev.x - w,
                       track->speed_vector_dev.y - w);
      ZnAddPointToBBox(&item->item_bounding_box,
                       track->speed_vector_dev.x + w,
                       track->speed_vector_dev.y + w);      
    }
    else {
      ZnAddPointToBBox(&item->item_bounding_box, track->speed_vector_dev.x,
                       track->speed_vector_dev.y);
    }
  }
  
  /*
   * Take care of the connection between items.
   */
  c_item = item->connected_item;
  if ((c_item != ZN_NO_ITEM) && (track->connection_width > 0.0)) {
    w2 = track->connection_width/2.0;
    //printf("%d connected to %d, %g %g and %g %g\n", c_item->id, item->id,
    //       ((TrackItem)c_item)->dev.x, ((TrackItem)c_item)->dev.y,
    //       track->dev.x, track->dev.y);
    ZnAddPointToBBox(&item->item_bounding_box, track->dev.x-w2, track->dev.y-w2);
    ZnAddPointToBBox(&item->item_bounding_box, ((TrackItem)c_item)->dev.x+w2,
                     ((TrackItem)c_item)->dev.y+w2);
  }

  /*
   * Compute the size of the circular marker.
   */
  p.x = track->pos.x + track->marker_size;
  p.y = track->pos.y;
  ZnTransformPoint(wi->current_transfo, &p, &xp);
  xp.x = xp.x - track->dev.x;
  xp.y = xp.y - track->dev.y;
  track->marker_size_dev = sqrt(xp.x*xp.x + xp.y*xp.y);
  track->marker_size_dev = ZnNearestInt(track->marker_size_dev);
  if (track->marker_size_dev > PRECISION_LIMIT) {
    ZnAddPointToBBox(&item->item_bounding_box,
                     track->dev.x - (ZnPos) track->marker_size_dev,
                     track->dev.y - (ZnPos) track->marker_size_dev);
    ZnAddPointToBBox(&item->item_bounding_box,
                     track->dev.x + (ZnPos) track->marker_size_dev,
                     track->dev.y + (ZnPos) track->marker_size_dev);
  } 
  
  /* Compute the new label bounding box. */
  if (field_set->label_format && field_set->num_fields) {
    ZnDim       bb_width, bb_height;
    ZnReal      rho, theta, dist;
    ZnPoint     leader_end;
    int it;

    ZnFIELD.GetLabelBBox(field_set, &bb_width, &bb_height);
    /*
     * Compute the label position.
     */
    if (ISSET(track->flags, POLAR_BIT)) {
      /*
       * Update label_dx, label_dy from label_distance, label_angle
       */
      rho = track->label_distance;
      /*
       * Compute heading after applying the transform.
       */
      ZnTransfoDecompose(wi->current_transfo, NULL, NULL, &rotation, NULL);
      /*printf("rotation=%g, heading=%g, angle=%d\n", rotation,
        ZnProjectionToAngle(track->speed_vector.x, track->speed_vector.y),
        track->label_angle);*/
      rotation = ZnProjectionToAngle(track->speed_vector.x, track->speed_vector.y)-rotation;
      /*
       * Adjust the distance to match the requested label_distance
       * whatever the label_angle.
       */
      it = 0;
      while (1) {
        ZnPointPolarToCartesian(rotation, rho, (ZnReal) track->label_angle,
                                &track->label_dx, &track->label_dy);
        field_set->label_pos.x = track->dev.x + track->label_dx;
        field_set->label_pos.y = track->dev.y - track->label_dy;
        ZnAnchor2Origin(&field_set->label_pos, bb_width, bb_height,
                        track->label_anchor, &field_set->label_pos);
        ZnResetBBox(&bbox);
        ZnAddPointToBBox(&bbox, field_set->label_pos.x, field_set->label_pos.y);
        ZnAddPointToBBox(&bbox, field_set->label_pos.x + bb_width, field_set->label_pos.y + bb_height);
        dist = ZnRectangleToPointDist(&bbox, &track->dev);
        dist = track->label_distance - dist;
        if (ABS(dist) < 1.0 || it > 5) {
          break;
        }
        it++;
        rho += dist;
      }
    }
    else {
      /*
       * Update label_angle following the change in label_dx, label_dy.
       * label_distance is not updated.
       */
      ZnTransfoDecompose(wi->current_transfo, NULL, NULL, &rotation, NULL);
      rotation = ZnProjectionToAngle(track->speed_vector.x, track->speed_vector.y) - rotation;
      ZnPointCartesianToPolar(rotation, &dist, &theta, track->label_dx, track->label_dy); 
      track->label_angle = (int) theta;  
    
      field_set->label_pos.x = track->dev.x + track->label_dx;
      field_set->label_pos.y = track->dev.y - track->label_dy;
      ZnAnchor2Origin(&field_set->label_pos, bb_width, bb_height,
                      track->label_anchor, &field_set->label_pos);
    }
    field_set->label_pos.x = ZnNearestInt(field_set->label_pos.x);
    field_set->label_pos.y = ZnNearestInt(field_set->label_pos.y);

    /*
     * Need to compensate for GL thick lines
     */
#ifdef GL
#define CORR 1
#else
#define CORR 0
#endif
    ZnAddPointToBBox(&item->item_bounding_box, field_set->label_pos.x - CORR, field_set->label_pos.y - CORR);
    ZnAddPointToBBox(&item->item_bounding_box,
                     field_set->label_pos.x + (ZnPos) bb_width + CORR,
                     field_set->label_pos.y + (ZnPos) bb_height + CORR);
#undef CORR

    /*
     * Process the leader.
     */
    if (track->leader_width > 0) {
      int       left_x, left_y, right_x, right_y;
      ZnPoint   end_points[ZN_LINE_END_POINTS];
      
      /*
       * Compute the actual leader end in the label.
       */
      if (track->leader_anchors) {
        left_x = track->leader_anchors->left_x;
        right_x = track->leader_anchors->right_x;
        left_y = track->leader_anchors->left_y;
        right_y = track->leader_anchors->right_y;
      }
      else {
        left_x = right_x = left_y = right_y = 50;
      }
      if (track->label_angle >= 270 || track->label_angle < 90) {
        if (track->leader_anchors && (left_y < 0)) {
          ZnFIELD.GetFieldBBox(field_set, (unsigned int) left_x, &bbox);
          leader_end.x = bbox.orig.x;
          leader_end.y = bbox.corner.y;
        }
        else {
          leader_end.x = field_set->label_pos.x + left_x*bb_width/100;
          leader_end.y = field_set->label_pos.y + left_y*bb_height/100;
        }
        alignment = ZN_AA_LEFT;
      }
      else {
        if (track->leader_anchors && (right_y < 0)) {
          ZnFIELD.GetFieldBBox(field_set, (unsigned int) right_x, &bbox);
          leader_end.x = bbox.corner.x;
          leader_end.y = bbox.corner.y;
        }
        else {
          leader_end.x = field_set->label_pos.x + right_x*bb_width/100;
          leader_end.y = field_set->label_pos.y + right_y*bb_height/100;
        }
        alignment = ZN_AA_RIGHT;
      }
      
      ZnFIELD.SetFieldsAutoAlign(field_set, alignment);
      
      /* Clip the leader on the label's fields */
      ZnFIELD.LeaderToLabel(field_set, &track->dev, &leader_end);
      
      /* Setup leader shape points */
      if (!track->leader_points) {
        track->leader_points = ZnListNew(ZN_LINE_SHAPE_POINTS, sizeof(ZnPoint));
      }
      ZnLineShapePoints(&track->dev, &leader_end, track->leader_width,
                        track->leader_shape, &bbox, track->leader_points);
      ZnAddBBoxToBBox(&item->item_bounding_box, &bbox);
      points = (ZnPoint *) ZnListArray(track->leader_points);
      num_points = ZnListSize(track->leader_points);
      
      /* Setup leader ends */
      if (track->leader_first_end != NULL) {
        ZnGetLineEnd(&points[0], &points[1], track->leader_width,
                     CapRound, track->leader_first_end, end_points);
        ZnAddPointsToBBox(&item->item_bounding_box, end_points, ZN_LINE_END_POINTS);
      }
      if (track->leader_last_end != NULL) {
        ZnGetLineEnd(&points[num_points-1], &points[num_points-2], track->leader_width,
                     CapRound, track->leader_last_end, end_points);
        ZnAddPointsToBBox(&item->item_bounding_box, end_points, ZN_LINE_END_POINTS);
      }
    }
  }
  
  /* Update connected items. */
  if ((old_label_pos.x != field_set->label_pos.x) ||
      (old_label_pos.y != field_set->label_pos.y) ||
      (old_label_width != field_set->label_width) ||
      (old_label_height != field_set->label_height) ||
      (old_pos.x != track->dev.x) ||
      (old_pos.y != track->dev.y)) {
    /* Update connected items */
    SET(item->flags, ZN_UPDATE_DEPENDENT_BIT);
  }
}


/*
**********************************************************************************
*
* ToArea --
*       Tell if the object is entirely outside (-1),
*       entirely inside (1) or in between (0).
*
**********************************************************************************
*/
static int
ToArea(ZnItem   item,
       ZnToArea ta)
{
  TrackItem     track = (TrackItem) item;
  int           inside;
  int           width, height;
  ZnDim         lwidth, lheight;
  ZnBBox        bbox, *area = ta->area;
  ZnPoint       pts[2];

  /*
   * Try the current position.
   */
  ZnResetBBox(&bbox);
  if (track->symbol != ZnUnspecifiedImage) {
    ZnSizeOfImage(track->symbol, &width, &height);
    bbox.orig.x = track->dev.x-(width+1)/2;
    bbox.orig.y = track->dev.y-(height+1)/2;
    bbox.corner.x = bbox.orig.x + width;
    bbox.corner.y = bbox.orig.y + height;
  }
  inside = ZnBBoxInBBox(&bbox, area);
  if (inside == 0) {
    /*printf("track pos\n");*/    
    return 0;
  }
  
  /*
   * Try the fields.
   */
  ZnFIELD.GetLabelBBox(&track->field_set, &lwidth, &lheight);
  if ((lwidth > 0.0) && (lheight > 0.0)) {
    if (ZnFIELD.FieldsToArea(&track->field_set, area) != inside) {
      return 0;
    }
  }
  
  /*
   * Try the leader.
   */
  if (track->field_set.label_format && (track->leader_width > 0)) {
    ZnPoint       end_points[ZN_LINE_END_POINTS];
    ZnPoint       *points;
    unsigned int  num_points;

    points = (ZnPoint *) ZnListArray(track->leader_points);
    num_points = ZnListSize(track->leader_points);
    lwidth = track->leader_width > 1 ? track->leader_width : 0;
    if (ZnPolylineInBBox(points, num_points, lwidth,
                         CapRound, JoinRound, area) != inside) {
      /*printf("track leader\n");*/
      return 0;
    }
    if (track->leader_first_end != NULL) {
      ZnGetLineEnd(&points[0], &points[1], track->leader_width,
                   CapRound, track->leader_first_end, end_points);
      if (ZnPolygonInBBox(end_points, ZN_LINE_END_POINTS, area, NULL) != inside) {
        /*printf("track leader\n");*/
        return 0;
      }
    }
    if (track->leader_last_end != NULL) {
      ZnGetLineEnd(&points[num_points-1], &points[num_points-2], track->leader_width,
                   CapRound, track->leader_last_end, end_points);
      if (ZnPolygonInBBox(end_points, ZN_LINE_END_POINTS, area, NULL) != inside) {
        /*printf("track leader\n");*/
        return 0;
      }
    }
  }

  /*
   * Try the speed vector.
   */
  if ((item->class == ZnTrack) && (track->speed_vector_width > 0)) {
    pts[0] = track->dev;
    pts[1] = track->speed_vector_dev;
    lwidth = track->speed_vector_width > 1 ? track->speed_vector_width : 0;
    if (ZnPolylineInBBox(pts, 2, lwidth, CapRound, JoinRound, area) != inside) {
      /*printf("track speed vector\n");*/
      return 0;
    }
  }

  /*
   * Try the connection.
   */
  if ((item->connected_item != ZN_NO_ITEM) && (track->connection_width > 0)) {
    pts[0] = track->dev;
    pts[1] = ((TrackItem) item->connected_item)->dev;
    lwidth = track->connection_width > 1 ? track->connection_width : 0;
    if (ZnPolylineInBBox(pts, 2, lwidth, CapRound, JoinRound, area) != inside) {
      /*printf("track connection\n");*/
      return 0;
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
  TrackItem     track = (TrackItem) item;
  ZnItem        c_item;
  XGCValues     values;
  History       hist;
  unsigned int  h_side_size, side_size, width=0, height=0;
  unsigned int  i, nb_hist, num_acc_pos;
  int           x, y;

  /* Draw the marker */
  if (track->marker_size_dev != 0) {
    ZnSetLineStyle(wi, track->marker_style);
    values.foreground = ZnGetGradientPixel(track->marker_color, 0.0);
    values.line_width = 0;
    if (ISSET(track->flags, MARKER_FILLED_BIT)) {
      if (track->marker_fill_pattern == ZnUnspecifiedImage) {
        /* Fill solid */
        values.fill_style = FillSolid;
        XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      }
      else {
        /* Fill stippled */
        values.fill_style = FillStippled;
        values.stipple = ZnImagePixmap(track->marker_fill_pattern, wi->win);
        XChangeGC(wi->dpy, wi->gc,
                  GCFillStyle | GCStipple | GCLineWidth | GCForeground, &values);
      }
      XFillArc(wi->dpy, wi->draw_buffer, wi->gc,
               (int) (track->dev.x - (ZnPos) track->marker_size_dev),
               (int) (track->dev.y - (ZnPos) track->marker_size_dev),
               (unsigned int) track->marker_size_dev * 2,
               (unsigned int) track->marker_size_dev * 2,
               0, 360 * 64);
    }
    else {
      values.fill_style = FillSolid;
      XChangeGC(wi->dpy, wi->gc, GCFillStyle | GCLineWidth | GCForeground, &values);
      XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,
               (int) (track->dev.x - (ZnPos) track->marker_size_dev),
               (int) (track->dev.y - (ZnPos) track->marker_size_dev),
               (unsigned int) (track->marker_size_dev * 2),
               (unsigned int) (track->marker_size_dev * 2),
               0, 360 * 64);
    }
  }
  
  /*
   * Draw the connection.
   */
  c_item = item->connected_item;
  if ((c_item != ZN_NO_ITEM) && (track->connection_width > 0)) {
    ZnPoint     pts[2];
    
    pts[0] = track->dev;
    pts[1] = ((TrackItem) item->connected_item)->dev;
    ZnDrawLineShape(wi, pts, 2, track->connection_style,
                    ZnGetGradientPixel(track->connection_color, 0.0),
                    track->connection_width, ZN_LINE_STRAIGHT);
  }

  /*
   * Draw the speed vector.
   */
  if ((item->class == ZnTrack) && (track->speed_vector_width > 0)) {
    values.foreground = ZnGetGradientPixel(track->speed_vector_color, 0.0);
    values.line_width = (int) (track->speed_vector_width > 1 ? track->speed_vector_width : 0);
    values.line_style = LineSolid;
    values.fill_style = FillSolid;
    XChangeGC(wi->dpy, wi->gc,
              GCForeground | GCLineWidth | GCLineStyle | GCFillStyle, &values);
    XDrawLine(wi->dpy, wi->draw_buffer, wi->gc,
              (int) track->dev.x,
              (int) track->dev.y,
              (int) track->speed_vector_dev.x,
              (int) track->speed_vector_dev.y);
  }
  
  /*
   * Draw the leader.
   */
  if (track->field_set.label_format && (track->leader_width > 0)) {
    ZnPoint      end_points[ZN_LINE_END_POINTS];
    XPoint       xpoints[ZN_LINE_END_POINTS];
    ZnPoint      *points;
    unsigned int num_points;

    points = (ZnPoint *) ZnListArray(track->leader_points);
    num_points = ZnListSize(track->leader_points);
    ZnDrawLineShape(wi, points, num_points, track->leader_style,
                    ZnGetGradientPixel(track->leader_color, 0.0),
                    track->leader_width, track->leader_shape);
    if (track->leader_first_end != NULL) {
      ZnGetLineEnd(&points[0], &points[1], track->leader_width,
                   CapRound, track->leader_first_end, end_points);
      for (i = 0; i < ZN_LINE_END_POINTS; i++) {
        xpoints[i].x = (short) end_points[i].x;
        xpoints[i].y = (short) end_points[i].y;
      }
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xpoints, ZN_LINE_END_POINTS,
                   Nonconvex, CoordModeOrigin);
    }
    if (track->leader_last_end != NULL) {
      ZnGetLineEnd(&points[num_points-1], &points[num_points-2], track->leader_width,
                   CapRound, track->leader_last_end, end_points);
      for (i = 0; i < ZN_LINE_END_POINTS; i++) {
        xpoints[i].x = (short) end_points[i].x;
        xpoints[i].y = (short) end_points[i].y;
      }
      XFillPolygon(wi->dpy, wi->draw_buffer, wi->gc, xpoints, ZN_LINE_END_POINTS,
                   Nonconvex, CoordModeOrigin);
    }
  }
  
  if (track->symbol != ZnUnspecifiedImage) {
    ZnSizeOfImage(track->symbol, &width, &height);
  }
  
  /*
   * Draw the history, current pos excepted.
   */
  if ((item->class == ZnTrack) && track->history) {
    unsigned int visible_history_size;

    visible_history_size = (ISSET(track->flags, HISTORY_VISIBLE_BIT) ?
                            wi->track_visible_history_size : 0);

    values.foreground = ZnGetGradientPixel(track->history_color, 0.0);
    values.fill_style = FillSolid;
    XChangeGC(wi->dpy, wi->gc, GCForeground|GCFillStyle, &values);  
    if (ISCLEAR(track->flags, FILLED_HISTORY_BIT)) {
      values.line_width = 0;
      values.line_style = LineSolid;
      XChangeGC(wi->dpy, wi->gc, GCLineWidth | GCLineStyle, &values);
    }
    num_acc_pos = MIN(visible_history_size, ZnListSize(track->history));
    hist = ZnListArray(track->history);
    side_size = (int) track->history_width;

    for (i = 0, nb_hist = 0; i < num_acc_pos; i++) {
      if (ISSET(track->flags, LAST_AS_FIRST_BIT) &&
          (i == visible_history_size-1)) {
        values.foreground = ZnGetGradientPixel(track->symbol_color, 0.0);
        XChangeGC(wi->dpy, wi->gc, GCForeground, &values);
      }
      side_size--;
      side_size = MAX(1, side_size);
      h_side_size = (side_size+1)/2;
      if (hist[i].visible) {
        if (ISSET(track->flags, DOT_MIXED_HISTORY_BIT) && !(nb_hist++ % 2)) {
          x = (int) hist[i].dev.x;
          y = (int) hist[i].dev.y;
          /* Draw a point (portability layer doesn't define a XDrawPoint) */
          XDrawLine(wi->dpy, wi->draw_buffer, wi->gc, x, y, x, y);
        }
        else {
          x = ((int) hist[i].dev.x) - h_side_size;
          y = ((int) hist[i].dev.y) - h_side_size;
          if (ISSET(track->flags, CIRCLE_HISTORY_BIT)) {
            if (ISSET(track->flags, FILLED_HISTORY_BIT)) {
              XFillArc(wi->dpy, wi->draw_buffer, wi->gc,  
                       x, y, side_size, side_size, 0, 360*64);
            }
            else {
              XDrawArc(wi->dpy, wi->draw_buffer, wi->gc,  
                       x, y, side_size - 1, side_size - 1, 0, 360*64);
            }
          }
          else {
            if (ISSET(track->flags, FILLED_HISTORY_BIT)) {
              XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc,  
                             x, y, side_size, side_size);
            }
            else {
              XDrawRectangle(wi->dpy, wi->draw_buffer, wi->gc,  
                             x, y, side_size - 1, side_size - 1);
            }
          }
        }
      }
    }
  }

  /*
   * Draw the current position using a pattern for Tk.
   */
  if (track->symbol != ZnUnspecifiedImage) {
    x = ((int) track->dev.x) - (width+1)/2;
    y = ((int) track->dev.y) - (height+1)/2;
    values.foreground = ZnGetGradientPixel(track->symbol_color, 0.0);
    values.fill_style = FillStippled;
    values.stipple = ZnImagePixmap(track->symbol, wi->win);
    values.ts_x_origin = x;
    values.ts_y_origin = y;
    XChangeGC(wi->dpy, wi->gc,
              GCForeground|GCFillStyle|GCStipple|GCTileStipXOrigin|GCTileStipYOrigin,
              &values);
    XFillRectangle(wi->dpy, wi->draw_buffer, wi->gc, x, y, width, height);
  }

  /*
   * Draw the label.
   */
  ZnFIELD.DrawFields(&track->field_set);
}


/*
**********************************************************************************
*
* Render --
*
**********************************************************************************
*/
#ifdef GL
struct MarkerCBData {
  ZnPoint *p;
  int     num;
  ZnReal  size;
  ZnPoint center;
};

static void
MarkerRenderCB(void *closure)
{
  struct MarkerCBData *cbd = (struct MarkerCBData *) closure;
  int                 i;

  glBegin(GL_TRIANGLE_FAN);
  glVertex2d(cbd->center.x, cbd->center.y);  
  for (i = 0; i < cbd->num; i++) {
    glVertex2d(cbd->center.x + cbd->p[i].x*cbd->size,
               cbd->center.y + cbd->p[i].y*cbd->size);
  }
  glEnd();
}

static void
Render(ZnItem   item)
{
  ZnWInfo       *wi = item->wi;
  TrackItem     track = (TrackItem) item;
  TrackItem     c_item;
  History       hist;
  unsigned int  h_side_size, side_size, width=0, height=0;
  unsigned int  i, j, nb_hist, num_acc_pos;
  unsigned short alpha;
  XColor        *color;
  ZnPoint       *points;
  unsigned int  num_points;
  ZnReal        x0, y0, size;

  /* Draw the marker */
  if (track->marker_size_dev != 0) {
    points = ZnGetCirclePoints(3, ZN_CIRCLE_MEDIUM, 0.0, 2*M_PI, &num_points, NULL);
    x0 = track->dev.x;
    y0 = track->dev.y;
    size = track->marker_size_dev;
    if (ISSET(track->flags, MARKER_FILLED_BIT)) {
      ZnBBox              bbox;
      struct MarkerCBData cbd;

      cbd.center.x = x0;
      cbd.center.y = y0;
      cbd.num = num_points;
      cbd.size = size;
      cbd.p = points;
      glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
      if (track->marker_fill_pattern != ZnUnspecifiedImage) { /* Fill stippled */
        ZnResetBBox(&bbox);
        ZnAddPointToBBox(&bbox, track->dev.x-size, track->dev.y-size);
        ZnAddPointToBBox(&bbox, track->dev.x+size, track->dev.y+size);
        ZnRenderTile(wi, track->marker_fill_pattern, track->marker_color,
                     MarkerRenderCB, &cbd, (ZnPoint *) &bbox);
      }
      else {
        color = ZnGetGradientColor(track->marker_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
        MarkerRenderCB(&cbd);
      }
    }
    else {
      glLineWidth(1.0);
      ZnSetLineStyle(wi, track->marker_style);
      glBegin(GL_LINE_LOOP);
      for (i = 0; i < num_points; i++) {
        glVertex2d(x0 + points[i].x*size, y0 + points[i].y*size);
      }
      glEnd();
    }
  }

  /*
   * Draw the connection.
   */
  c_item = (TrackItem) item->connected_item;
  if ((c_item != ZN_NO_ITEM) && (track->connection_width > 0)) {
    color = ZnGetGradientColor(track->connection_color, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
    glColor4us(color->red, color->green, color->blue, alpha);
    glLineWidth((GLfloat)track->connection_width);
    glBegin(GL_LINES);
    glVertex2d(track->dev.x, track->dev.y);
    glVertex2d(c_item->dev.x, c_item->dev.y);
    glEnd();
  }

  /*
   * Draw the speed vector.
   */
  if ((item->class == ZnTrack) && (track->speed_vector_width > 0)) {
    unsigned int num_clips=0, svlength=0;
    ZnReal       svxstep=0, svystep=0;
    GLfloat      ticksize=0;

    color = ZnGetGradientColor(track->speed_vector_color, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
    glColor4us(color->red, color->green, color->blue, alpha);
    glLineWidth((GLfloat)track->speed_vector_width);

    /*
     * Turn off AA to obtain a square point precisely defined
     */
    if (ISSET(track->flags, SV_TICKS_BIT) ||
        ISSET(track->flags, SV_MARK_BIT)) {
      glDisable(GL_POINT_SMOOTH);
      
      if (ISSET(track->flags, SV_TICKS_BIT)) {
        num_clips = ZnListSize(wi->clip_stack);
        ticksize = 3;
        svlength = (int) wi->speed_vector_length;
        svxstep = (track->speed_vector_dev.x-track->dev.x)/svlength;    
        svystep = (track->speed_vector_dev.y-track->dev.y)/svlength;    
        glPointSize(ticksize);
        ZnGlStartClip(num_clips, False);
        glBegin(GL_POINTS);
        for (i = 1; i < svlength; i++) {
          glVertex2d(track->dev.x + i*svxstep, track->dev.y + i*svystep);
        }
        glEnd();
        ZnGlRenderClipped();
      }
    }

    glBegin(GL_LINES);
    glVertex2d(track->dev.x, track->dev.y);
    glVertex2d(track->speed_vector_dev.x, track->speed_vector_dev.y);
    glEnd();

    if (ISSET(track->flags, SV_MARK_BIT)) {
      glPointSize((GLfloat) (track->speed_vector_width + 2.0));
      glBegin(GL_POINTS);
      glVertex2d(track->speed_vector_dev.x, track->speed_vector_dev.y);
      glEnd();
    }

    if (ISSET(track->flags, SV_TICKS_BIT) ||
        ISSET(track->flags, SV_MARK_BIT)) {
      glEnable(GL_POINT_SMOOTH);

      if (ISSET(track->flags, SV_TICKS_BIT)) {
        glPointSize(ticksize);
        ZnGlRestoreStencil(num_clips, False);
        glBegin(GL_POINTS);
        for (i = 1; i < svlength; i++) {
          glVertex2d(track->dev.x + i*svxstep, track->dev.y + i*svystep);
        }
        glEnd();
        ZnGlEndClip(num_clips);
      }
    }
  }

  /*
   * Draw the leader.
   */
  if (track->field_set.label_format && (track->leader_width > 0)) {
    points = ZnListArray(track->leader_points);
    num_points = ZnListSize(track->leader_points);
    ZnRenderPolyline(wi,
                     points, num_points, track->leader_width,
                     track->leader_style, CapRound, JoinRound,
                     track->leader_first_end, track->leader_last_end,
                     track->leader_color);
  }
  
  if (track->symbol != ZnUnspecifiedImage) {
    ZnSizeOfImage(track->symbol, &width, &height);
  }
  
  /*
   * Draw the history, current pos excepted.
   */
  if ((item->class == ZnTrack) && track->history) {
    unsigned int visible_history_size;

    visible_history_size = (ISSET(track->flags, HISTORY_VISIBLE_BIT) ?
                            wi->track_visible_history_size : 0);

    points = ZnGetCirclePoints(3, ZN_CIRCLE_COARSE, 0.0, 2*M_PI, &num_points, NULL);
    color = ZnGetGradientColor(track->history_color, 0.0, &alpha);
    alpha = ZnComposeAlpha(alpha, wi->alpha);
    glColor4us(color->red, color->green, color->blue, alpha);
    glLineWidth(1.0);    
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
    num_acc_pos = MIN(visible_history_size, ZnListSize(track->history));
    hist = ZnListArray(track->history);
    side_size = (int) track->history_width;
    /*
     * Turning off line and point smoothing
     * to enhance ;-) history drawing.
     */
    glDisable(GL_LINE_SMOOTH);
    glDisable(GL_POINT_SMOOTH);
    for (i = 0, nb_hist = 0; i < num_acc_pos; i++) {
      if (ISSET(track->flags, LAST_AS_FIRST_BIT) &&
          (i == visible_history_size-1)) {
        color = ZnGetGradientColor(track->symbol_color, 0.0, &alpha);
        alpha = ZnComposeAlpha(alpha, wi->alpha);
        glColor4us(color->red, color->green, color->blue, alpha);
      }
      side_size--;
      side_size = MAX(1, side_size);
      h_side_size = (side_size+1)/2;
      if (hist[i].visible) {
        x0 = hist[i].dev.x;
        y0 = hist[i].dev.y;
        if ((ISSET(track->flags, DOT_MIXED_HISTORY_BIT) && !(nb_hist++ % 2)) ||
            (side_size == 1)) {
          glPointSize(1.0);    
          glBegin(GL_POINTS);
          glVertex2d(x0, y0);
          glEnd();
        }
        else {
          if (ISSET(track->flags, CIRCLE_HISTORY_BIT)) {
            if (ISSET(track->flags, FILLED_HISTORY_BIT)) {
              glPointSize((GLfloat) side_size);
              glBegin(GL_POINTS);
              glVertex2d(x0, y0);
              glEnd();
            }
            else {
#if 1
              glBegin(GL_LINE_LOOP);
              for (j = 0; j < num_points; j++) {
                glVertex2d(x0 + points[j].x*h_side_size,
                           y0 + points[j].y*h_side_size);
              }
              glEnd();
#else
              RenderHollowDot(wi, &hist[i].dev, side_size+1);
#endif
            }
          }
          else {
            if (ISSET(track->flags, FILLED_HISTORY_BIT)) {
              glBegin(GL_QUADS);
              glVertex2d(x0 - h_side_size, y0 - h_side_size);
              glVertex2d(x0 - h_side_size, y0 + h_side_size);
              glVertex2d(x0 + h_side_size, y0 + h_side_size);
              glVertex2d(x0 + h_side_size, y0 - h_side_size);
              glEnd();
            }
            else {
              glBegin(GL_LINE_LOOP);
              glVertex2d(x0 - h_side_size, y0 - h_side_size);
              glVertex2d(x0 - h_side_size, y0 + h_side_size);
              glVertex2d(x0 + h_side_size, y0 + h_side_size);
              glVertex2d(x0 + h_side_size, y0 - h_side_size);
              glEnd();
            }
          }
        }
      }
    }
    glEnable(GL_LINE_SMOOTH);
    glEnable(GL_POINT_SMOOTH);
  }

  /*
   * Draw the current position using a pattern.
   */
  if (track->symbol != ZnUnspecifiedImage) {
    ZnPoint p;

    p.x = track->dev.x - (width+1)/2;
    p.y = track->dev.y - (height+1)/2;
    ZnRenderIcon(wi, track->symbol, track->symbol_color, &p, True);
  }

  /*
   * Render the label.
   */
  ZnFIELD.RenderFields(&track->field_set);
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
  if (ISCLEAR(item->flags, ZN_SENSITIVE_BIT) ||
      !item->parent->class->IsSensitive(item->parent, ZN_NO_PART)) {
    return False;
  }
  
  if (item_part < ZN_NO_PART) {
    return ISSET(item->part_sensitive, ZnPartToBit(item_part));
  }
  else if (item_part >= 0) {
    return ZnFIELD.IsFieldSensitive(&((TrackItem) item)->field_set, item_part);
  }
  else if (item_part == ZN_NO_PART) {
    return ISSET(item->flags, ZN_SENSITIVE_BIT);
  }
  return True;
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
  TrackItem     track = (TrackItem) item;
  ZnItem        c_item;
  ZnBBox        bbox;
  double        dist=0, new_dist;
  ZnPoint       *points, *p = ps->point;
  int           num_points, i;
  int           width=0, height=0;
  double        width_2;
  int           best_part;
  ZnPoint       pts[2];
                     
  /*
   * Try one of the fields.
   */
  dist = ZnFIELD.FieldsPick(&track->field_set, p, &best_part);
  if (dist <= 0.0) {
    goto report0;
  }

  /*
   * Try the current position symbol.
   */
  ZnResetBBox(&bbox);
  if (track->symbol != ZnUnspecifiedImage) {
    ZnSizeOfImage(track->symbol, &width, &height);
    bbox.orig.x = track->dev.x-(width+1)/2;
    bbox.orig.y = track->dev.y-(height+1)/2;
    bbox.corner.x = bbox.orig.x + width;
    bbox.corner.y = bbox.orig.y + height;
  }

  new_dist = ZnRectangleToPointDist(&bbox, p);
  if (new_dist < dist) {
    best_part = CURRENT_POSITION;
    dist = new_dist;
  }
  if (dist <= 0.0) {
    goto report0;
  }
  
  /*
   * Try the leader.
   */
  if (track->field_set.label_format && (track->leader_width > 0) &&
      track->leader_points) {
    ZnPoint end_points[ZN_LINE_END_POINTS];

    width_2 = (track->leader_width>1) ? ((double) track->leader_width)/2.0 : 0;
    points = (ZnPoint *) ZnListArray(track->leader_points);
    num_points = ZnListSize(track->leader_points)-1;
    for (i = 0; i < num_points; i++) {
      new_dist = ZnLineToPointDist(&points[i], &points[i+1], p, NULL);
      new_dist -= width_2;
      if (new_dist < dist) {
        best_part = LEADER;
        dist = new_dist;
      }
      if (dist <= 0.0) {
        goto report0;
      }
    }
    if (track->leader_first_end != NULL) {
      ZnGetLineEnd(&points[0], &points[1], track->leader_width,
                   CapRound, track->leader_first_end, end_points);
      new_dist = ZnPolygonToPointDist(end_points, ZN_LINE_END_POINTS, p);
      if (new_dist < dist) {
        best_part = LEADER;
        dist = new_dist;        
      }
      if (dist <= 0.0) {
        goto report0;
      }
    }
    if (track->leader_last_end != NULL) {
      ZnGetLineEnd(&points[num_points-1], &points[num_points-2], track->leader_width,
                   CapRound, track->leader_last_end, end_points);
      new_dist = ZnPolygonToPointDist(end_points, ZN_LINE_END_POINTS, p);
      if (new_dist < dist) {
        best_part = LEADER;
        dist = new_dist;        
      }
      if (dist <= 0.0) {
        goto report0;
      }
    }
  }

  /*
   * Try the speed vector.
   */
  if ((item->class == ZnTrack) && (track->speed_vector_width > 0)) {
    pts[0] = track->dev;
    pts[1] = track->speed_vector_dev;
    new_dist = ZnPolylineToPointDist(pts, 2, track->speed_vector_width,
                                     CapRound, JoinRound, p);
    if (new_dist < dist) {
      best_part = SPEED_VECTOR;
      dist = new_dist;
    }
    if (dist <= 0.0) {
      goto report0;
    }
  }

  /*
   * Try the connection.
   */
  c_item = item->connected_item;
  if ((c_item != ZN_NO_ITEM) && (track->connection_width > 0)) {
    pts[0] = track->dev;
    pts[1] = ((TrackItem) item->connected_item)->dev;
    new_dist = ZnPolylineToPointDist(pts, 2, track->connection_width,
                                     CapRound, JoinRound, p);
    if (new_dist < dist) {
      dist = new_dist;
      best_part = CONNECTION;
    }
    if (dist <= 0.0) {
    report0:
      dist = 0.0;
    }
  }

  //printf("track %d reporting part %d, distance %lf\n", item->id, best_part, dist);
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
	return TCL_OK;
}


#ifdef ATC
/*
**********************************************************************************
*
* ZnSendTrackToOm --
*
**********************************************************************************
*/
/*
 * TODO:
 *
 *   The tracks should be identified by their ids not their
 *   structure pointer. This would enable an easy interface
 *   between the overlap manager and the applications when
 *   dealing with tracks.
 */
void *
ZnSendTrackToOm(void    *ptr,
                void    *item,
                int     *x,
                int     *y,
                int     *sv_dx,
                int     *sv_dy,
                /*int   *label_x,
                  int   *label_y,
                  int   *label_width,
                  int   *label_height,*/
                int     *rho,
                int     *theta,
                int     *visibility,
                int     *locked,
                int     *preferred_angle,
                int     *convergence_style)
{
  ZnWInfo       *wi = (ZnWInfo *) ptr;
  ZnItem        current_item = (ZnItem) item;
  TrackItem     track;
  ZnBBox        zn_bbox, bbox;
  ZnBool        to_be_sent;

  int rho_derived ;

  zn_bbox.orig.x = zn_bbox.orig.y = 0;
  zn_bbox.corner.x = wi->width;
  zn_bbox.corner.y = wi->height;

  if (current_item == ZN_NO_ITEM) {
    current_item = ZnGroupHead(wi->om_group);
  }
  else {
    current_item = current_item->next;
  }

  while (current_item != ZN_NO_ITEM) {
    to_be_sent = current_item->class == ZnTrack;

    /* We send invisibles items because the current algorithm
       take care of the age of the tracks.
       to_be_sent &= ISSET(current_item->flags, ZN_VISIBLE_BIT);*/

    ZnIntersectBBox(&zn_bbox, &current_item->item_bounding_box, &bbox);
    to_be_sent &= !ZnIsEmptyBBox(&bbox);
    
    if (to_be_sent) {
      track = (TrackItem) current_item;
      
      *x = (int) track->dev.x;
      *y = wi->height - ((int) track->dev.y);

      /*
       * We must send world values for speed vector deltas as device
       * equivalents can be null. But then if the image is rotated this
       * is nonsense.
       */
      *sv_dx = (int) track->speed_vector.x;
      *sv_dy = (int) track->speed_vector.y;

      /* Fri Oct 13 15:16:38 2000
       *label_x = track->field_set.label_pos.x;
       *label_y = wi->height - track->field_set.label_pos.y;
       if (track->field_set.label_format) {
       ZnDim    bb_width, bb_height;

       ZnFIELD.GetLabelBBox(&track->field_set, &bb_width, &bb_height);
       *label_width = bb_width;
       *label_height = bb_height;
       }
       else {
       *label_width = 0;
       *label_height = 0;
       }
      */

      /*
       * Trial to fix rho drift due to ZnPointPolarToCartesian
       * roundoff error.
       */
      rho_derived = (int) sqrt(track->label_dx*track->label_dx +
                               track->label_dy*track->label_dy);
#ifdef DP
      if (ABS(rho_derived - track->label_distance) < LABEL_DISTANCE_THRESHOLD) {
        /* The error is narrow so value discarded */
        *rho =  track->label_distance ;
      }
      else {
        /* Means a user change has been performed on label_dx label_dy */
        *rho = rho_derived ;
      }
#else
      *rho = rho_derived;
#endif
      *theta = track->label_angle;
      *visibility = (ISSET(current_item->flags, ZN_VISIBLE_BIT) ? 1 : 0 );
      *locked = (ISSET(track->flags, FROZEN_LABEL_BIT) ? 1 : 0);
      *preferred_angle = track->label_preferred_angle;
      *convergence_style = track->label_convergence_style;
      break;
    }
    
    current_item = current_item->next;
  }
  
  return (void *) current_item;
}


/*
**********************************************************************************
*
* ZnSetLabelAngleFromOm --
*
**********************************************************************************
*/
void
ZnSetLabelAngleFromOm(void      *ptr,   /* No longer in use. */
                      void      *item,
                      int       rho,
                      int       theta)
{
  TrackItem     track = (TrackItem) item;

  theta %= 360;
  if (theta < 0) {
    theta += 360;
  }
  if (ISCLEAR(track->flags, FROZEN_LABEL_BIT) && (track->label_angle != theta)) {
    track->label_angle = theta;
#ifdef DP
    track->label_distance = rho;
#endif
    SET(track->flags, POLAR_BIT);
    ZnITEM.Invalidate((ZnItem) item, ZN_COORDS_FLAG);
    /*    ZnGroupSetCallOm(((ZnItem)item)->parent, True);*/
  }
}


/*
**********************************************************************************
*
* ZnQueryLabelPosition -- OverlapMan query the widget about what would be the
*                         label position if label_angle is theta
*
**********************************************************************************
*/
void
ZnQueryLabelPosition(void       *ptr,   /* No longer in use. */
                     void       *item,
                     int        theta,
                     int        *x,
                     int        *y,
                     int        *w,
                     int        *h)
{
  ZnItem        it = (ZnItem) item;
  ZnWInfo       *wi = it->wi;
  TrackItem     track = (TrackItem) it;
  
  if (track->field_set.label_format) {
    ZnDim       bb_width, bb_height;
    ZnDim       delta_x, delta_y;
    ZnReal      heading;
    
    /*
     * !! BUG !! This doesn't work if the current transform has some rotation.
     */
    heading = ZnProjectionToAngle(track->speed_vector.x, track->speed_vector.y);
    ZnPointPolarToCartesian(heading, track->label_distance, (ZnReal) theta, &delta_x, &delta_y);
    ZnFIELD.GetLabelBBox(&track->field_set, &bb_width, &bb_height);
    /*
     * !! BUG !! This assume a label placing relative to the center anchor.
     * We must fix this by taking into account the label anchor.
     */
    *x = (int) track->dev.x + (int) (delta_x - bb_width/2);
    *y = (int) track->dev.y - (int) (delta_y + bb_height/2);
    *y = ((int) wi->height) - *y;
    *w = (int) bb_width;
    *h = (int) bb_height;
  }
  else {
    *x = *y = *w = *h = 0;
  }
}
#endif


/*
**********************************************************************************
*
* ZnSetHistoryVisibility -- PLC - not yet implemented
*
**********************************************************************************
*/
void
ZnSetHistoryVisibility(ZnItem   item,
                       int      index,
                       ZnBool   visible)
{
}


/*
**********************************************************************************
*
* ZnTruncHistory -- PLC - not yet interfaced
*
**********************************************************************************
*/
void
ZnTruncHistory(ZnItem   item)
{
  TrackItem     track = (TrackItem) item;

  if (track->history) {
    int size = ZnListSize (track->history);
    History hist_tbl = ZnListArray (track->history);
    while (size--) {
      hist_tbl[size].visible = False;
    }
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
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
  return &((TrackItem) item)->field_set;
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
  ZnFieldSet    field_set = &((TrackItem) item)->field_set;
  ZnDim         width, height;
  
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
* Coords --
*       Return or edit the item position.
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
  TrackItem     track = (TrackItem) item;
  
  if ((cmd == ZN_COORDS_ADD) || (cmd == ZN_COORDS_ADD_LAST) || (cmd == ZN_COORDS_REMOVE)) {
    Tcl_AppendResult(item->wi->interp, " ",
                     item->class->name, "s can't add or remove vertices", NULL);
    return TCL_ERROR;
  }
  else if ((cmd == ZN_COORDS_REPLACE) || (cmd == ZN_COORDS_REPLACE_ALL)) {
    if (*num_pts == 0) {
      Tcl_AppendResult(item->wi->interp,
                       " coords command need 1 point on ",
                       item->class->name, "s", NULL);
      return TCL_ERROR;
    }
    if (item->class == ZnTrack) {
      AddToHistory(track, track->pos);
    }
    track->pos = (*pts)[0];
    ZnITEM.Invalidate(item, ZN_COORDS_FLAG);
  }
  else if ((cmd == ZN_COORDS_READ) || (cmd == ZN_COORDS_READ_ALL)) {
    *num_pts = 1;
    *pts = &track->pos;
  }
  return TCL_OK;
}


/*
**********************************************************************************
*
* Part --
*       Convert a private part from/to symbolic representation.
*
**********************************************************************************
*/
static int
Part(ZnItem     item,
     Tcl_Obj    **part_spec,
     int        *part)
{
  char  *part_str="";
  int   c;
  char  *end;
  
  if (*part_spec) {
    part_str = Tcl_GetString(*part_spec);
    if (strlen(part_str) == 0) {
      *part = ZN_NO_PART;
    }
    else if (isdigit(part_str[0])) {
      *part = strtol(part_str, &end, 0);
      if ((*end != 0) || (*part < 0) ||
          ((unsigned int) *part >= ((TrackItem) item)->field_set.num_fields)) {
        goto part_error;
      }
    }
    else {
      c = part_str[0];
      if ((c == 'c') && (strcmp(part_str, "connection") == 0)) {
        *part = CONNECTION;
      }
      else if ((c == 'l') && (strcmp(part_str, "leader") == 0)) {
        *part = LEADER;
      }
      else if ((c == 'p') && (strcmp(part_str, "position") == 0)) {
        *part = CURRENT_POSITION;
      }
      else if ((c == 's') && (strcmp(part_str, "speedvector") == 0)) {
        if (item->class != ZnTrack) {
          goto part_error;
        }
        *part = SPEED_VECTOR;
      }
      else {
      part_error:
        Tcl_AppendResult(item->wi->interp, " invalid item part specification", NULL);
        return TCL_ERROR;       
      }
    }
  }
  else {
    if (*part >= 0) {
      *part_spec = Tcl_NewIntObj(*part);
    }
    else {
      part_str = "";
      switch (*part) {
      default:
      case ZN_NO_PART:
        break;
      case CURRENT_POSITION:
        part_str = "position";
        break;
      case LEADER:
        part_str = "leader";
        break;
      case CONNECTION:
        part_str = "connection";
        break;
      case SPEED_VECTOR:
        if (item->class == ZnTrack) {
          part_str = "speedvector";
          break;
        }
      }
      if (part_str[0]) {
        *part_spec = Tcl_NewStringObj(part_str, -1);
      }
    }
  }
  return TCL_OK;  
}


/*
**********************************************************************************
*
* Index --
*       Parse a text index and return its value and aa
*       error status (standard Tcl result).
*
**********************************************************************************
*/
static int
Index(ZnItem    item,
      int       field,
      Tcl_Obj   *index_spec,
      int       *index)
{
  return ZnFIELD.FieldIndex(&((TrackItem) item)->field_set, field,
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
  if (ZnFIELD.FieldInsertChars(&((TrackItem) item)->field_set,
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
  if (ZnFIELD.FieldDeleteChars(&((TrackItem) item)->field_set,
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
TrackCursor(ZnItem      item,
            int         field,
            int         index)
{
  ZnFIELD.FieldCursor(&((TrackItem) item)->field_set, field, index);
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
  return ZnFIELD.FieldSelection(&((TrackItem) item)->field_set, field,
                                offset, chars, max_chars);
}


/*
**********************************************************************************
*
* Exported functions struct --
*
**********************************************************************************
*/
/*
 * Track -position attribute is not handled the same way as other
 * interface items like texts, icons and such, as it make little sense
 * to change the local transform of a track. It is always processed as
 * a point in the coordinate system of the track's parent. It is the same
 * for the points in the history and the speed vector end.
 */
static ZnItemClassStruct TRACK_ITEM_CLASS = {
  "track",
  sizeof(TrackItemStruct),
  track_attrs,
  4,                    /* num_parts */
  ZN_CLASS_HAS_ANCHORS|ZN_CLASS_ONE_COORD, /* flags */
  -1,
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  GetFieldSet,
  GetAnchor,
  NULL,                 /* GetClipVertices */
  NULL,                 /* GetContours */
  Coords,
  InsertChars,
  DeleteChars,
  TrackCursor,
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

static ZnItemClassStruct WAY_POINT_ITEM_CLASS = {
  "waypoint",
  sizeof(TrackItemStruct),
  wp_attrs,
  3,                    /* num_parts */
  ZN_CLASS_HAS_ANCHORS|ZN_CLASS_ONE_COORD, /* flags */
  -1,
  Init,
  Clone,
  Destroy,
  Configure,
  Query,
  GetFieldSet,
  GetAnchor,
  NULL,                 /* GetClipVertices */
  NULL,                 /* GetContours */
  Coords,
  InsertChars,
  DeleteChars,
  TrackCursor,
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

ZnItemClassId ZnTrack = (ZnItemClassId) &TRACK_ITEM_CLASS;
ZnItemClassId ZnWayPoint = (ZnItemClassId) &WAY_POINT_ITEM_CLASS;
