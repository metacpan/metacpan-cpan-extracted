/*
 * Track.h -- 
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : Tue Jan 19 16:03:53 1999
 *
 * $Id: Track.h,v 1.7 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Track_h
#define _Track_h


#include "Item.h"


/*
 **********************************************************************************
 *
 * Functions defined in Track.c for internal use.
 *
 **********************************************************************************
 */

void *ZnSendTrackToOm(void *ptr, void *item, int *x, int *y,
                      int *sv_dx, int *sv_dy,
                      /* Fri Oct 13 15:18:11 2000
                         int *label_x, int *label_y,
                         int *label_width, int *label_height,*/
                      int *rho, int *theta, int *visibility, int *locked,
                      int *preferred_angle, int *convergence_style);
void ZnSetLabelAngleFromOm(void *ptr, void *item, int rho, int theta);
void ZnQueryLabelPosition(void *ptr, void *item, int theta,
                          int *x, int *y, int *w, int *h);  
void ZnSetHistoryVisibility(ZnItem item, int index, ZnBool visibility);
void ZnTruncHistory(ZnItem item);


#endif /* _Track_h */
