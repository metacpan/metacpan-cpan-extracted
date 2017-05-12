/*
 * Name:        Polygon.xs
 * Purpose:     Do calculations on Polygons fast
 * Author:      Hans Oesterholt-Dijkema
 * Modified by:
 * Created:     19-4-2004
 * RCS-ID:      $Id: Polygon.xs,v 1.2 2004/04/20 08:59:36 cvs Exp $
 * Copyright:   (c) 2004 Hans Oesterholt-Dijkema
 * Licence:     This program is free software; you can redistribute it and/or
 *              modify it under Artistic license
*/

/*
 * STRICT already there for MinGW
 */

#ifndef __MINGW32__
#define STRICT
#endif

#include <wx/defs.h>
#include "wx/window.h"

/* 
 * Work around a compatibility bug with Perl 5(.8.3) and MinGW.
 * uid_t and gid_t are C-Macros on MinGW platforms. We're undefining
 * them.
 */

#ifdef __MINGW32__
#undef uid_t
#undef gid_t
#define uid_t BUG_uid_t
#define gid_t BUG_gid_t
#endif

#include "cpp/wxapi.h"

MODULE=Wx__Polygon PACKAGE=Wx::Polygon

BOOT:
  INIT_PLI_HELPERS( wx_pli_helpers );

#define PI2_360 ((2.0*3.1459265)/360.0)

void C_RotateAndScale(N,scale_factor_x,scale_factor_y,degrees,f,t)
   int N
   float scale_factor_x
   float scale_factor_y
   float degrees
   AV  *f
   AV  *t
CODE:
  if (scale_factor_x!=1.0 ||
      scale_factor_y!=1.0 ||
      degrees!=0.0) {
   wxPoint *pf,*pt;
   register int    i;
   register double S=sin(PI2_360*degrees);
   register double C=cos(PI2_360*degrees);
   register double sfx=scale_factor_x;
   register double sfy=scale_factor_y;
     for(i=0;i<N;i++) {
       SV **af,**at;
       af=av_fetch(f,i,0);
       at=av_fetch(t,i,0);
       pf=(wxPoint *) wxPli_sv_2_object( aTHX_ af[0], "Wx::Point");
       pt=(wxPoint *) wxPli_sv_2_object( aTHX_ at[0], "Wx::Point");

       pt->x=(int) ((pf->x*C-pf->y*S)*sfx);
       pt->y=(int) ((pf->x*S+pf->y*C)*sfy);
    }
  }

#define MAXINT 1000000000
#define MININT -1000000000

void C_FindMid(N,P,offx,offy,M)
     int N
     AV  *P
     int  offx
     int  offy
     AV  *M
CODE:
     {wxPoint *p;
      register int i;
      int          minx=MAXINT;
      int          maxx=MININT;
      int          miny=MAXINT;
      int          maxy=MININT;
      int          MIDX,MIDY;
	  for(i=0;i<N;i++) {
	    SV **a=av_fetch(P,i,0);
	    p=(wxPoint *) wxPli_sv_2_object( aTHX_ a[0], "Wx::Point");
	    if (minx>p->x) { minx=p->x; }
	    if (maxx<p->x) { maxx=p->x; }
	    if (miny>p->y) { miny=p->y; }
	    if (maxy<p->y) { maxy=p->y; }
	  }
         MIDX=((maxx-minx)/2+minx)+offx;
         MIDY=((maxy-miny)/2+miny)+offy;
         av_push(M,newSViv(MIDX));
	 av_push(M,newSViv(MIDY));
      }


int C_In(N,P,x,y,offx,offy)
	int N
	AV *P
	int x
	int y
	int offx
	int offy
CODE:
      x-=offx;
      y-=offy;

      {int i,j;
       wxPoint *pi,*pj;
       int yes=0;
	  for(i=0,j=N-1;i<N;j=i++) {
	    SV **a=av_fetch(P,i,0);
	    pi=(wxPoint *) wxPli_sv_2_object( aTHX_ a[0], "Wx::Point");
	    a=av_fetch(P,j,0);
	    pj=(wxPoint *) wxPli_sv_2_object( aTHX_ a[0], "Wx::Point");
	    if ((((pi->y<=y) && (y<pj->y)) ||
		 ((pj->y<=y) && (y<pi->y))) &&
		(x<(pj->x-pi->x)*(y-pi->y)/(pj->y-pi->y)+pi->x)) {
	      yes=!yes;
	    }
	  }
	  if (yes) {
	    RETVAL=1;
	  }
	  else {
	    RETVAL=0;
	  }
      }
OUTPUT:      
      RETVAL

