/*
 * Transfo.h -- Header for common geometric routines.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: Transfo.h,v 1.8 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _Transfo_h
#define _Transfo_h


#include "Types.h"

#include <math.h>
#include <limits.h>


/*
 * First subscript is matrix row, second is matrix column.
 * So a[0][1] is upper right corner of matrix a and a[2][0]
 * is lower left corner.
 */
typedef struct  _ZnTransfo {
  float _[3][2];
} ZnTransfo;


ZnTransfo *
ZnTransfoNew(void);
ZnTransfo *
ZnTransfoDuplicate(ZnTransfo *t);
void
ZnTransfoFree(ZnTransfo *t);
void
ZnPrintTransfo(ZnTransfo        *t);
void
ZnTransfoSetIdentity(ZnTransfo  *t);
ZnBool
ZnTransfoIsIdentity(ZnTransfo   *t);
ZnTransfo *
ZnTransfoCompose(ZnTransfo      *res,
                 ZnTransfo      *t1,
                 ZnTransfo      *t2);
ZnTransfo *
ZnTransfoInvert(ZnTransfo       *t,
                ZnTransfo       *inv);
void
ZnTransfoDecompose(ZnTransfo    *t,
                   ZnPoint      *scale,
                   ZnPoint      *trans,
                   ZnReal       *rotation,
                   ZnReal       *skewxy);
ZnBool
ZnTransfoEqual(ZnTransfo        *t1,
               ZnTransfo        *t2,
               ZnBool           include_translation);
ZnBool
ZnTransfoHasSkew(ZnTransfo      *t);
ZnBool
ZnTransfoIsTranslation(ZnTransfo        *t);
ZnPoint *
ZnTransformPoint(ZnTransfo      *t,
                 ZnPoint        *p,
                 ZnPoint        *xp);
void
ZnTransformPoints(ZnTransfo     *t,
                  ZnPoint       *p,
                  ZnPoint       *xp,
                  unsigned int  num);
ZnTransfo *
ZnTranslate(ZnTransfo   *t,
            ZnReal      delta_x,
            ZnReal      delta_y,
            ZnBool      abs);
ZnTransfo *
ZnScale(ZnTransfo       *t,
        ZnReal          scale_x,
        ZnReal          scale_y);
ZnTransfo *
ZnRotateRad(ZnTransfo   *t,
            ZnReal      angle);
ZnTransfo *
ZnRotateDeg(ZnTransfo   *t,
            ZnReal      angle);
ZnTransfo *
ZnSkewRad(ZnTransfo     *t,
          ZnReal        skew_x,
          ZnReal        skew_y);
ZnTransfo *
ZnSkewDeg(ZnTransfo     *t,
          ZnReal        skew_x,
          ZnReal        skew_y);

#endif  /* _Transfo_h */
