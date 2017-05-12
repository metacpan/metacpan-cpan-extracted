/*
 * MapInfo.h -- Public include file for MapInfo interface.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : 
 *
 * $Id: MapInfo.h,v 1.15 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _MapInfo_h
#define _MapInfo_h

#ifdef __CPLUSPLUS__
extern "C" {
#endif


#include "Types.h"
#include "List.h"
#include "Geo.h"
  

/*
 *-----------------------------------------------------------------------
 *
 * New types
 *
 *-----------------------------------------------------------------------
 */

typedef void    *ZnMapInfoId;

typedef enum {
  ZnMapInfoLineSimple,
  ZnMapInfoLineDashed,
  ZnMapInfoLineDotted,
  ZnMapInfoLineMixed,
  ZnMapInfoLineMarked
} ZnMapInfoLineStyle;

typedef enum {
  ZnMapInfoNormalText,
  ZnMapInfoUnderlinedText
} ZnMapInfoTextStyle;

  
void ZnMapInfoGetLine(ZnMapInfoId map_info, unsigned int index, ZnPtr *tag,
                      ZnMapInfoLineStyle *line_style, ZnDim *line_width,
                      ZnPos *x_from, ZnPos *y_from,
                      ZnPos *x_to, ZnPos *y_to);
unsigned int ZnMapInfoNumLines(ZnMapInfoId map_info);
void ZnMapInfoGetMarks(ZnMapInfoId map_info, unsigned int index,
                       ZnPoint **marks, unsigned int *num_marks);
void ZnMapInfoGetSymbol(ZnMapInfoId map_info, unsigned int index, ZnPtr *tag,
                        ZnPos *x, ZnPos *y, char *symbol);
unsigned int ZnMapInfoNumSymbols(ZnMapInfoId map_info);
void ZnMapInfoGetText(ZnMapInfoId map_info, unsigned int index, ZnPtr *tag,
                      ZnMapInfoTextStyle *text_style,
                      ZnMapInfoLineStyle *line_style,
                      ZnPos *x, ZnPos *y, char **text);
unsigned int ZnMapInfoNumTexts(ZnMapInfoId map_info);
void ZnMapInfoGetArc(ZnMapInfoId map_info, unsigned int index, ZnPtr *tag,
                     ZnMapInfoLineStyle *line_style, ZnDim *line_width,
                     ZnPos *center_x, ZnPos *center_y, ZnDim *radius,
                     ZnReal *start_angle, ZnReal *extend);
unsigned int ZnMapInfoNumArcs(ZnMapInfoId map_info);


typedef void (*ZnMapInfoChangeProc)(ClientData client_data, ZnMapInfoId map_info);

ZnMapInfoId ZnGetMapInfo(Tcl_Interp *interp, char *name,
                         ZnMapInfoChangeProc proc, ClientData client_data);
void ZnFreeMapInfo(ZnMapInfoId map_info, ZnMapInfoChangeProc proc,
                   ClientData client_data);

int ZnMapInfoObjCmd(ClientData client_data, Tcl_Interp *interp,
                    int argc, Tcl_Obj *CONST args[]);
int ZnVideomapObjCmd(ClientData client_data, Tcl_Interp *interp,
                     int argc, Tcl_Obj *CONST args[]);
  

#ifdef __CPLUSPLUS__
}
#endif

#endif  /* _MapInfo_h */
