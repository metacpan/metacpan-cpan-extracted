/*
 * OverlapMan.c -- Track label overlap avoidance manager implementation.
 *
 * Authors              :
 * Creation date        :
 *
 * $Id: OverlapMan.c,v 1.26 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

/*
 * TODO:
 *
 *   The tracks should be identified by their ids not their
 *   structure pointer. This would enable an easy interface
 *   between the overlap manager and the applications when
 *   dealing with tracks.
 */

static const char rcsid[] = "$Id: OverlapMan.c,v 1.26 2005/04/27 07:32:03 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


#include "OverlapMan.h"
#if defined(__APPLE__)
#include <stdlib.h>
#else
#include "malloc.h"
#endif

#include <stdio.h>
#include <string.h>
#include <math.h>

#ifdef _WIN32
#  ifndef __GNUC__
#    pragma warning(disable : 4996)
#  endif
#endif

#define signe(a) ((a) < (0) ? (-1) : (1))
#define abs(a)   ((a) < (0) ? -(a) : (a))
#ifndef M_PI
#define M_PI            3.14159265358979323846264338327
#endif
#ifndef M_PI_2
#define M_PI_2          1.57079632679489661923
#endif
#ifndef M_PI_4
#define M_PI_4          0.78539816339744830962
#endif
#define DegreesToRadian(angle) \
  (M_PI * (double) (angle) / 180.0)
#define RadianToDegrees(angle) \
  (fmod((angle) * 180.0 / M_PI, 360.0))
#define RadianToDegrees360(angle) \
  (fmod(RadianToDegrees(angle)+360.0,360.0))


#define NB_ALLOC 20
#define COEF1  0.5      /* coef of second repulsion point */
#define COEF2  0.1      /* coef of second repulsion point */

#define DELTA_T 0.1     /* integration step for Euler method */
#define FALSE   0
#define TRUE    1


typedef int BOOLEAN;

typedef struct _INFOS {
  void*  id;
  int     x;
  int     y;
  int     vv_dx;
  int     vv_dy;
  /* Fri Oct 13 15:15:31 2000  int     label_x;
  int     label_y;
  int     label_width;
  int     label_height;*/
  int     rho;
  int     theta;
  int     visibility;
  BOOLEAN New_Track;
  int     dx;
  int     dy;
  double  alpha;
  double  alpha_point;
  BOOLEAN Refresh;
} INFOS;

typedef struct _ZINCS {
  void  *rw;
  void  *(*_next_track)();
  void  (*_set_label_angle)();
  INFOS *infos;
  int   NBinfos;
  int   NBalloc_infos;
} ZINCS;

/*
 * Definition of tunable parameters
 */


/*
 * real parameters adresse
 */
static  double K0 = 2100.0;     /* Repulsion factor */
static  double K0min = 500.0;
static  double K0max = 3000.0;

static  double n0 = 2.10;       /* Repulsion exponent */
static  double n0min = 2.0;
static  double n0max = 3.0;

static  double K1 = 6.0;         /* Friction factor */
static  double K1min = 1.0;
static  double K1max = 10.0;

static  double K2 = 6.0;         /* Drawback forces factor */
static  double K2min = 1.0;
static  double K2max = 10.0;

static  double K3 = 4.0;         /* Keep in view forces factor */
static  double K3min = 1.0;
static  double K3max = 10.0;

/*
 * accessor structure need for generic set/get method
 */
typedef struct _OMPARAM {
  int      type;
  int      size;
  char    *name;
  void    *data;
  BOOLEAN rw;           /* 1 means readwrite, 0 means read only */
} OMPARAM, *pOMPARAM;

/*
 * Global vars.
 *
 */
static OMPARAM OmParamAccess[] = {
  { OM_PARAM_DOUBLE, sizeof(double), "repulsion",                    &K0,    1 },
  { OM_PARAM_DOUBLE, sizeof(double), "repulsion_bearing",            &n0,    1 },
  { OM_PARAM_DOUBLE, sizeof(double), "friction",                     &K1,    1 },
  { OM_PARAM_DOUBLE, sizeof(double), "best_position_attraction",     &K2,    1 },
  { OM_PARAM_DOUBLE, sizeof(double), "screen_edge_repulsion",        &K3,    1 },
  { OM_PARAM_DOUBLE, sizeof(double), "min_repulsion",                &K0min, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "min_repulsion_bearing",        &n0min, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "min_friction",                 &K1min, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "min_best_position_attraction", &K2min, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "min_screen_edge_repulsion",    &K3min, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "max_repulsion",                &K0max, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "max_repulsion_bearing",        &n0max, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "max_friction",                 &K1max, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "max_best_position_attraction", &K2max, 0 },
  { OM_PARAM_DOUBLE, sizeof(double), "max_screen_edge_repulsion",    &K3max, 0 },
  { OM_PARAM_END,  0, "", NULL, 0 }
};

static int NbParam = sizeof(OmParamAccess) / sizeof(OMPARAM) - 1;
static  ZINCS   *wr = NULL;
static  int     NBzincs=0;
static  int     NBalloc_zincs=0;
static  INFOS   info1;


/*
 * Square of the distance (between two label centers) below which
 * the repulsion is not computed.
 */
static  double limit_distance = 6.0; 

/*
 * Square of the minimum distance (between two label centers)
 * considered during initialisation of the leaders.
 */
static  double placing_min_dist = 11000.0;

/*
 * Angle step between two placement trials.
 */
static  double placing_step = M_PI/6.0;


/*
 ****************************************************************************
 *
 * FindPosW --
 *      Find the zinc position in the database,
 *      if not found, gets the positon to insert in.
 *
 ****************************************************************************
 */
static BOOLEAN
FindPosW(void   *w,
         int    *mid)
{ 
  int   left=0;
  int   right=NBzincs-1;
 
  if (w < wr[0].rw) {
    *mid = 0;
    return FALSE;
  }
  if (w > wr[right].rw) {
    *mid = right+1;
    return FALSE;
  }
  if (w == wr[right].rw) {
    *mid = right;
    return TRUE;
  }

  *mid = (right + left) / 2;
  while ((right > left+1) && (wr[*mid].rw != w)) {
    if (w > wr[*mid].rw) {
      left = *mid;
    }
    else {
      right = *mid;
    }
    *mid = (right + left) / 2;
  }
  if (wr[*mid].rw == w) {
    return TRUE;
  }
  else { 
    (*mid)++;
    return FALSE;
  }
}


/*
 ****************************************************************************
 *
 * AllocW --
 *      Allocate cells in database for the specified zinc.
 *
 ****************************************************************************
 */
static void
AllocW(void     *w,
       int      pos)
{
  int   i;
  
  if (NBzincs == NBalloc_zincs) {
    NBalloc_zincs += NB_ALLOC;
    wr = realloc(wr, sizeof(ZINCS) * NBalloc_zincs);
  }

  for (i = NBzincs-1; i >= pos; i--) {
    memcpy((char *) &wr[i+1], (char *) &wr[i], sizeof(ZINCS));
  }  
  /*memcpy((char *)&wr[pos+1], (char *)&wr[pos], (NBzincs-pos) * sizeof(ZINCS) );*/

  NBzincs++;
  wr[pos].rw = w;
  wr[pos].infos = NULL;
  wr[pos].NBinfos = 0;
  wr[pos].NBalloc_infos = 0;                             
}


/*
 ***************************************************************************
 *
 * ProjToAngle --
 *      Compute an angle from dx and dy projections.
 *
 ***************************************************************************
 */
static double
ProjToAngle(int dx,
            int dy)
{
  if (dx == 0) {     
    if (dy < 0) {
      return -M_PI_2;
    }
    else {
      if (dy > 0) {
        return M_PI_2;
      }
      else {
        return 0;
      }
    }
  }
  if (dx > 0) {
    return atan((double) (dy) / (double) (dx));
  }
  if (dx < 0) {
    return atan((double) (dy) / (double) (dx)) + M_PI;
  }

  return 0.0;
}


/*
 ****************************************************************************
 *
 * OmInit --
 *      Called only once to initialize some internal data.
 *
 ****************************************************************************
 */
void
OmInit()
{
  /*  printf("OmInit\n");*/
}        


/*
 ****************************************************************************
 *
 * OmRegister --
 *      Create a database entry for the specified zinc.
 *
 ****************************************************************************
 */
void
OmRegister(void *w,
           void *(*_fnext_track)(void *, void *,
                                 int *, int *,
                                 int *, int *,
                                 int *, int *,
                                 int *, int *,
                                 int *, int *),
           void (*_fset_label_angle)(void *, void *, int, int),
           void (*_fquery_label_pos)(void *, void *, int,
                                     int *, int *, int *, int *))
{
  int           iw=0;
  BOOLEAN       found=FALSE;

  if (NBzincs > 0) {
    found = FindPosW(w, &iw);
  }
  if (found == FALSE) {
    AllocW(w, iw);
  }
  wr[iw]._next_track= _fnext_track;
  wr[iw]._set_label_angle= _fset_label_angle;
}


/*
 ****************************************************************************
 *
 * OmUnregister --
 *      Cancel database information about the specified zinc.
 *
 ****************************************************************************
 */
void
OmUnregister(void       *w)
{ 
  int   i;

  if (FindPosW(w, &i) == TRUE) { 
    free(wr[i].infos);
    memcpy((char *) &wr[i], (char *) &wr[i+1], (NBzincs-i-1)*sizeof(ZINCS));
    NBzincs--;
  }
}


/*
 ***************************************************************************
 *
 * FindPosId --
 *      Find track position in the database,
 *      if not found gets the positon to insert in.
 *
 ***************************************************************************
 */
static BOOLEAN
FindPosId(int   iw,
          void  *id,
          int   *mid)
{ 
  int   left=0;
  int   right= wr[iw].NBinfos-1;

  if (id < wr[iw].infos[0].id) {
    *mid = 0;
    return FALSE;
  }
  if (id > wr[iw].infos[right].id) {
    *mid = right+1;
    return FALSE;
  }
  if (id == wr[iw].infos[right].id) {
    *mid = right;
    return TRUE;
  }
 
  *mid = (right + left) / 2;
  while ((right > left+1) && (wr[iw].infos[*mid].id != id)) { 
    if (id > wr[iw].infos[*mid].id) {
      left = *mid;
    }
    else {
      right = *mid;
    }
    *mid = (right + left) / 2;
  }
  if (wr[iw].infos[*mid].id == id) {
    return TRUE;
  }
  else { 
    (*mid)++;
    return FALSE;
  }
}


/*
 ***************************************************************************
 *
 * SetTrackInitValues --
 *      Set initial label values for a track.
 *
 ***************************************************************************
 */
static void
SetTrackInitValues()
{
  info1.alpha       = ProjToAngle(info1.vv_dx, info1.vv_dy) - 3.0 * M_PI_4;
  info1.dx          = (int) (info1.rho * cos(info1.alpha));
  info1.dy          = (int) (info1.rho * sin(info1.alpha));
  info1.alpha_point = 0.0;
}


/*
 ***************************************************************************
 * SetTrackCurrentValues --
 *      Update label values for a track.
 *
 ***************************************************************************
 */
static void
SetTrackCurrentValues(int       iw,
                      int       pos)
{
  info1.New_Track   = FALSE;
  info1.alpha_point = wr[iw].infos[pos].alpha_point;
}


/*
 ***************************************************************************
 *
 * PutTrackLoaded --
 *      Put track labels information into database.
 *
 ***************************************************************************
 */
static void
PutTrackLoaded(int      iw)
{
  int           pos = 0, i;
  BOOLEAN       found = FALSE;

  if (wr[iw].NBinfos > 0) {
    found = FindPosId(iw, info1.id, &pos);
  }
  if (found == FALSE) {
    /*
     * New track.
     */ 
    if (wr[iw].NBinfos == wr[iw].NBalloc_infos) {
      wr[iw].NBalloc_infos += NB_ALLOC;
      wr[iw].infos = realloc((void *) wr[iw].infos,
                             sizeof(INFOS)*wr[iw].NBalloc_infos);
    }
    
    if (pos < wr[iw].NBinfos) {
      for(i = wr[iw].NBinfos-1; i >= pos; i--) {
        memcpy((char *) &(wr[iw].infos[i+1]), (char *) &(wr[iw].infos[i]),
               sizeof(INFOS));
      }
      /* memcpy((char *) &(wr[iw].infos[pos+1]), (char *) &(wr[iw].infos[pos]),
                (wr[iw].NBinfos-pos)*sizeof(INFOS) );*/
    }
    
    info1.New_Track = TRUE;
    SetTrackInitValues(iw, pos);

    wr[iw].NBinfos++;
  }
  else {
    if (info1.visibility == FALSE) {  
      SetTrackInitValues( iw, pos);
    }
    else {
      SetTrackCurrentValues(iw, pos);
    }
  }

  memcpy((char *) &(wr[iw].infos[pos]), (char *) &info1, sizeof(INFOS)); 
}


/*
 ***************************************************************************
 *
 * ReadTracks --
 *      Get track labels information from zinc.
 *
 ***************************************************************************
 */
static void
ReadTracks(int  iw)
{
  int   i=0;
  int   trash1; /* dummy variable : received unused data */

  for (i = 0; i < wr[iw].NBinfos; i++) { 
    wr[iw].infos[i].Refresh = FALSE;
  }
  
  info1.id = NULL; 
  while ((info1.id = (*wr[iw]._next_track)(wr[iw].rw, info1.id,   
                                           &info1.x, &info1.y,
                                           &info1.vv_dx, &info1.vv_dy,
                                           /* Fri Oct 13 15:15:48 2000
                                            * &info1.label_x, &info1.label_y,            
                                            * &info1.label_width, &info1.label_height,
                                            */
                                           &info1.rho, &info1.theta,
                                           &info1.visibility,
                                           &trash1,&trash1,&trash1))) {
    info1.alpha = (ProjToAngle(info1.vv_dx, info1.vv_dy ) - M_PI_2 -
                   DegreesToRadian(info1.theta));
    info1.dx = (int) (info1.rho * cos(info1.alpha));
    info1.dy = (int) (info1.rho * sin(info1.alpha));
    info1.Refresh = TRUE;
    /* printf("OverlapMan(Om): ReadTracks  id[%-10d], x[%4.4i], y[%4.4i], \
       vv_dx[%4.4i], vv_dy[%4.4i], rho[%-3.3d], theta[%-3.3d], visi[%d]\n",
       (int)info1.id,info1.x, info1.y, info1.vv_dx,info1.vv_dy,
       info1.rho,info1.theta,info1.visibility); */
    PutTrackLoaded(iw);
  }
  
  i = 0;
  while (i < wr[iw].NBinfos) {
    /*
     * Delete non refreshed tracks from database.
     */
    if (wr[iw].infos[i].Refresh == FALSE) {
      memcpy((char *) &(wr[iw].infos[i]), (char *) &(wr[iw].infos[i+1]),
             (wr[iw].NBinfos-i-1)*sizeof(INFOS));
      wr[iw].NBinfos--;
    }
    else {
      i++;
    }
  }
}

/*
 ***************************************************************************
 *
 * OmSetNParam --
 *      Return 1 if ok, anything else if nok (non existing parameters,
 * wrong type).
 *
 ***************************************************************************
 */
int
OmSetNParam(char *name, /* parameter's name */
                        void *value)
{
  int accessid = 0;
  int status = 0;
  
  while (OmParamAccess[accessid].type !=  OM_PARAM_END) {
        if (!strcmp(name, OmParamAccess[accessid].name)) {
          /* a parameter named name has been found */
          if (OmParamAccess[accessid].rw) {
                memcpy(OmParamAccess[accessid].data, value,
                       (unsigned int) OmParamAccess[accessid].size);
                status = 1;
                break;
          }
          else {
                status = -1 ; /* data is readonly */
          };
        };
        ++accessid;
  };
  return(status);
}

/*
 ***************************************************************************
 *
 * OmGetNParam --
 *      Return 1 if ok, anything else if nok (non existing parameters,
 * wrong type).
 *
 ***************************************************************************
 */
int
OmGetNParam(char *name, /* parameter's name */
                        void *ptvalue)
{
  int accessid = 0;
  int status = 0;
  
  while (OmParamAccess[accessid].type !=  OM_PARAM_END) {
        if (!strcmp(name, OmParamAccess[accessid].name)) {
          /* a parameter named "name" has been found */
                memcpy(ptvalue,  OmParamAccess[accessid].data, 
                       (unsigned int) OmParamAccess[accessid].size);
                status = 1;
                break;
          };
        ++accessid;
  };
  return(status);
}

/*
 ***************************************************************************
 *
 * OmGetNParamList --
 *      Return 1 and next index if remains to read, the current param
 * being written in current_param. Return 0 if end of list.
 *
 ***************************************************************************
 */
int 
OmGetNParamList(OmParam *current_param, int *idx_next)
{
  int status = 0 ;
  pOMPARAM cparam ; 
  if (*idx_next < NbParam) {
        cparam = &OmParamAccess[*idx_next];
        current_param->type = cparam->type ;
        strcpy(current_param->name, cparam->name);
        /* printf("value of parameter is %f \n", *((double *)(cparam->data)));
           printf("adresse de K0 %x \n", (int)&K0); */
        ++(*idx_next) ;
        status = 1;
  };
  return(status);
}  

void
OmSetParam(double OmKrepulsion, 
           double OmKrepulsionBearing, 
           double OmKfriction, 
           double OmKbestPositionAttraction, 
           double OmKscreenEdgeRepulsion)
{
  K0 = OmKrepulsion;
  n0 = OmKrepulsionBearing;
  K1 = OmKfriction;
  K2 = OmKbestPositionAttraction;
  K3 = OmKscreenEdgeRepulsion;
}

void
OmGetParam(double *OmKrepulsion, 
           double *OmKrepulsionBearing, 
           double *OmKfriction, 
           double *OmKbestPositionAttraction, 
           double *OmKscreenEdgeRepulsion)
{
  *OmKrepulsion = K0;
  *OmKrepulsionBearing = n0;
  *OmKfriction = K1;
  *OmKbestPositionAttraction = K2;
  *OmKscreenEdgeRepulsion = K3;
}

void
OmGetMinParam(double *OmKminRepulsion, 
              double *OmKminRepulsionBearing, 
              double *OmKminFriction, 
              double *OmKminBestPositionAttraction, 
              double *OmKminScreenEdgeRepulsion)
{
  *OmKminRepulsion = K0min;
  *OmKminRepulsionBearing = n0min;
  *OmKminFriction = K1min;
  *OmKminBestPositionAttraction = K2min;
  *OmKminScreenEdgeRepulsion = K3min;
}

void
OmGetMaxParam(double *OmKmaxRepulsion, 
              double *OmKmaxRepulsionBearing, 
              double *OmKmaxFriction, 
              double *OmKmaxBestPositionAttraction, 
              double *OmKmaxScreenEdgeRepulsion)
{
  *OmKmaxRepulsion = K0max;
  *OmKmaxRepulsionBearing = n0max;
  *OmKmaxFriction = K1max;
  *OmKmaxBestPositionAttraction = K2max;
  *OmKmaxScreenEdgeRepulsion = K3max;
}


/*
 ***************************************************************************
 *
 * SetupLeaderPosition --
 *      Setup leader position for new tracks.
 *
 ***************************************************************************
 */
static void
SetupLeaderPosition(int iw,
                    int ip)
{
  double        X10, Y10, X20, Y20;
  double        D, k, Fx0, Fy0;
  int           jp;
  double        alpha;
  BOOLEAN       ok = FALSE;
  double        dx = 0, dy = 0;
  
  Fx0 = 0.0;
  Fy0 = 0.0;
  
  for (jp = 0; jp < wr[iw].NBinfos; jp++) {
    if  (wr[iw].infos[jp].New_Track == FALSE) {
      X10 = (double) (wr[iw].infos[ip].x - wr[iw].infos[jp].x - wr[iw].infos[jp].dx);
      Y10 = (double) (wr[iw].infos[ip].y - wr[iw].infos[jp].y - wr[iw].infos[jp].dy);
      X20 = ((double) (wr[iw].infos[ip].x - wr[iw].infos[jp].x) -
             (double) (wr[iw].infos[jp].dx) * COEF1 +
             (double) (wr[iw].infos[jp].dy) * COEF2);
      Y20 = ((double) (wr[iw].infos[ip].y - wr[iw].infos[jp].y) -
             (double) (wr[iw].infos[jp].dy) * COEF1 -
             (double) (wr[iw].infos[jp].dx) * COEF2);
      
      D = X10 * X10 + Y10 * Y10;
      if (D > limit_distance) {
        k = K0 / (sqrt(D) * pow(D, n0 - 1.0));
        Fx0 += X10 * k;
        Fy0 += Y10 * k;
      }
      D = X20 * X20 + Y20 * Y20;
      if (D > limit_distance) {
        k = K0 / (sqrt(D) * pow(D, n0 - 1.0));
        Fx0 += X20 * k;
        Fy0 += Y20 * k;
      }
    }
  } 
  if ((Fx0 == 0) && (Fy0 == 0)) {
    Fx0 = 1;
  }
  
  k = (double) (wr[iw].infos[ip].rho) / sqrt(Fx0*Fx0 + Fy0*Fy0);
  
  wr[iw].infos[ip].dx = (int) (Fx0 * k);
  wr[iw].infos[ip].dy = (int) (Fy0 * k);
  wr[iw].infos[ip].alpha = ProjToAngle((int) (Fx0*k), (int) (Fy0*k));
  
  alpha = wr[iw].infos[ip].alpha;
  while ((alpha < wr[iw].infos[ip].alpha + 2.0*M_PI) && (ok == FALSE)) {
    dx = (double) (wr[iw].infos[ip].rho) * cos(alpha);
    dy = (double) (wr[iw].infos[ip].rho) * sin(alpha);
    ok = TRUE;
    
    for (jp = 0; jp < wr[iw].NBinfos; jp++) {
      if  (wr[iw].infos[jp].New_Track == FALSE) {
        X10 = (double) (wr[iw].infos[ip].x + (int) dx -
                        wr[iw].infos[jp].x - wr[iw].infos[jp].dx);
        Y10 = (double) (wr[iw].infos[ip].y + (int) dy -
                        wr[iw].infos[jp].y - wr[iw].infos[jp].dy);
        D = X10 * X10 + Y10 * Y10;
        if (D < placing_min_dist) {
          ok = FALSE;
        }
      }
    }
    alpha += placing_step;
  }
  if (ok) {
    wr[iw].infos[ip].dx = (int) dx;
    wr[iw].infos[ip].dy = (int) dy;
    wr[iw].infos[ip].alpha = ProjToAngle((int) dx, (int) dy);
  }
}


/*
 ***************************************************************************
 *
 * ComputeRepulsion --
 *      Compute the moment of the repulsion forces of all the other
 *      tracks.
 *
 ***************************************************************************
 */
static double
ComputeRepulsion(int    iw,
                 int    ip)
{
  double        X10, Y10, X00, Y00, X11, Y11, X01, Y01;
  double        D0, D1, k, Fx0, Fy0, Fx1, Fy1;
  int           jp;
  
  X00 = (double) (wr[iw].infos[ip].x + wr[iw].infos[ip].dx);
  Y00 = (double) (wr[iw].infos[ip].y + wr[iw].infos[ip].dy);
  X01 = ((double) (wr[iw].infos[ip].x) +
         (double) (wr[iw].infos[ip].dx) * COEF1 -
         (double) (wr[iw].infos[ip].dy) * COEF2);
  Y01 = ((double) (wr[iw].infos[ip].y) +
         (double) (wr[iw].infos[ip].dy) * COEF1 +
         (double) (wr[iw].infos[ip].dx) * COEF2);
  Fx0 = 0.0;
  Fy0 = 0.0;
  Fx1 = 0.0;
  Fy1 = 0.0;
  
  for (jp = 0; jp < wr[iw].NBinfos; jp++) {
    if  ( ip != jp ) {
      X10 = (double) (wr[iw].infos[jp].x + wr[iw].infos[jp].dx);
      Y10 = (double) (wr[iw].infos[jp].y + wr[iw].infos[jp].dy);
      X11 = ((double) (wr[iw].infos[jp].x) +
             (double) (wr[iw].infos[jp].dx) * COEF1 -
             (double) (wr[iw].infos[jp].dy) * COEF2);
      Y11 = ((double) (wr[iw].infos[jp].y) +
             (double) (wr[iw].infos[jp].dy) * COEF1 +
             (double) (wr[iw].infos[jp].dx) * COEF2);

      D0 = (X10 - X00) * (X10 - X00) + (Y10 - Y00) * (Y10 - Y00);
      if (D0 > limit_distance) {
        k = K0 / (sqrt(D0) * pow(D0, n0 - 1.0));
        Fx0 += (X10 - X00) * k;
        Fy0 += (Y10 - Y00) * k;
      }
      D1 = (X11 - X01) * (X11 - X01) + (Y11 - Y01) * (Y11 - Y01);
      if (D1 > limit_distance) {
        k = K0 / (sqrt(D1) * pow(D1, n0 - 1.0));
        Fx1 += (X11 - X01) * k;
        Fy1 += (Y11 - Y01) * k;
      }
    }
  }
  
  return  -((double) (wr[iw].infos[ip].dx) * Fy0 -
            (double) (wr[iw].infos[ip].dy) * Fx0 +
            (double) (wr[iw].infos[ip].dx) * COEF1 * Fy1 -
            (double) (wr[iw].infos[ip].dy) * COEF2 * Fy1 - 
            (double) (wr[iw].infos[ip].dy) * COEF1 * Fx1 -
            (double) (wr[iw].infos[ip].dx) * COEF2 * Fx1);
}


/*
 ***************************************************************************
 *
 * ComputeFriction --
 *      Compute the moment of the friction force.
 *
 ***************************************************************************
 */
static double
ComputeFriction(int     iw,
                int     ip)
{
  return (double) (-K1 * wr[iw].infos[ip].alpha_point);      
}


/*
 ***************************************************************************
 *                                                                           
 * ComputeDrawback --
 *      Compute the moment of the best positions drawback forces.
 *
 ***************************************************************************
 */
static double
ComputeDrawback(int     iw,
                int     ip)
{
  int           vx, vy, dx, dy;
  double        m = 0;
  double        nd = 1.0, nv = 1.0;
  double        vi;
  
  vx = wr[iw].infos[ip].vv_dx;
  vy = wr[iw].infos[ip].vv_dy;
  dx = wr[iw].infos[ip].dx;
  dy = wr[iw].infos[ip].dy;
  
  if ((vx != 0) || (vy != 0)) {
    nv = sqrt((double)(vx * vx + vy * vy));
  }
  if ((dx != 0) || (dy != 0)) {
    nd = sqrt((double)(dx * dx + dy * dy));
  }
  
  vi = (double) (vx * dx + vy * dy)/(nd * nv);
  vi = vi <= -1.0 ? -1.0 : vi;
  vi = vi >=  1.0 ?  1.0 : vi;
  vi = 3 * M_PI_4 - acos(vi);
  
  if (vy * dx - vx * dy < 0) {
    m = -vi;
  }
  else {
    m = vi;
  }
  
  return (double) (-K2 * m);
}


/*
 ***************************************************************************
 *
 * ComputeDrawbackInView --
 *      Compute the moment of the keep in view forces.
 *
 ***************************************************************************
 */
static double
DrawbackDirection(int   vx,
                  int   vy,
                  int   dx,
                  int   dy)
{
  double        m=0;
  double        nd=1.0, nv=1.0;
  double        vi;
  
  if ((vx != 0) || (vy != 0)) {
    nv = sqrt((double)(vx * vx + vy * vy));
  }
  if ((dx != 0) || (dy != 0)) {
    nd = sqrt((double)(dx * dx + dy * dy));
  }
  
  vi = (double) (vx * dx + vy * dy)/(nd * nv);
  vi = vi <= -1.0 ? -1.0 : vi;
  vi = vi >=  1.0 ? 1.0 : vi;
  vi = acos(vi);
  
  if (vy * dx - vx * dy < 0) {
    m = vi;
  }
  else {
    m = - vi;
  }
  
  return (double) (-K3 * m);
}


static double
ComputeDrawbackInView(int       iw,
                      int       ip,
                      int       width,
                      int       height)
{
  int           r=50;
  int           dx, dy;
  double        Gamma=0;
  
  r = wr[iw].infos[ip].rho; 
  dx = wr[iw].infos[ip].dx;
  dy = wr[iw].infos[ip].dy;
  
  if (abs(wr[iw].infos[ip].x) < r) {
    Gamma += DrawbackDirection(53, 0, dx, dy);
  }
  if (abs(wr[iw].infos[ip].x - width) < r) {
    Gamma += DrawbackDirection(-53, 0, dx, dy);
  }
  if (abs(wr[iw].infos[ip].y ) < r) {
    Gamma += DrawbackDirection(0, 53, dx, dy);
  }
  if (abs(wr[iw].infos[ip].y - height) < r) {
    Gamma += DrawbackDirection(0,- 53, dx, dy);
  }

  return (double) Gamma; 
}

/*
 ***************************************************************************
 *
 * RefineSetup --
 *      Refine setup for far spaced tracks.
 *
 ***************************************************************************
 */
static void
RefineSetup(int iw,
            int ip)
{
  double        acceleration;
  int           i;

  for (i = 0; i <= 10; i++) {
    acceleration = ComputeRepulsion(iw, ip) + ComputeDrawback(iw, ip);
          
    if (acceleration > 100) {
      acceleration = 100;
    }
    if (acceleration < -100) {
      acceleration = -100;
    }
    
    wr[iw].infos[ip].alpha_point = acceleration * DELTA_T + wr[iw].infos[ip].alpha_point;
    wr[iw].infos[ip].alpha_point += ComputeFriction(iw, ip) * DELTA_T; 
    
    if (wr[iw].infos[ip].alpha_point >  30) {
      wr[iw].infos[ip].alpha_point =  30;
    }
    if (wr[iw].infos[ip].alpha_point < -30) {
      wr[iw].infos[ip].alpha_point = -30;
    }
    
    wr[iw].infos[ip].alpha = wr[iw].infos[ip].alpha_point * DELTA_T + wr[iw].infos[ip].alpha;
  }
}


/*
 ***************************************************************************
 *
 * OmProcessOverlap --
 *      Overlap Manager main function.
 *
 ***************************************************************************
 */
void
OmProcessOverlap(void   *zinc,
                 int    width,
                 int    height,
                 double scale)
{
  double        acceleration = 0.0;
  int           ip, iw;

  if (NBzincs != 0 && FindPosW(zinc, &iw) == TRUE) {
    ReadTracks(iw);

    for (ip = 0; ip < wr[iw].NBinfos; ip++) { 
      if  (wr[iw].infos[ip].New_Track == TRUE) {
        SetupLeaderPosition(iw, ip); 
        RefineSetup(iw, ip); 
        wr[iw].infos[ip].New_Track = FALSE;
      }
    }
    
    for (ip = 0; ip < wr[iw].NBinfos; ip++) {
      acceleration = (ComputeRepulsion(iw, ip) + ComputeDrawback(iw, ip) +
                      ComputeDrawbackInView(iw, ip, width, height));
      
      if (acceleration > 100) {
        acceleration = 100;
      }
      if (acceleration < -100) {
        acceleration = -100;
      }
        
      wr[iw].infos[ip].alpha_point += acceleration * DELTA_T ;
      wr[iw].infos[ip].alpha_point += ComputeFriction(iw, ip) * DELTA_T ; 
      
      if (wr[iw].infos[ip].alpha_point > 30) {
        wr[iw].infos[ip].alpha_point =  30;
      }
      if (wr[iw].infos[ip].alpha_point < -30) {
        wr[iw].infos[ip].alpha_point = -30;
      }
      
      wr[iw].infos[ip].alpha += wr[iw].infos[ip].alpha_point * DELTA_T ;
      wr[iw].infos[ip].theta = (int) RadianToDegrees360(-wr[iw].infos[ip].alpha +   
                                                        ProjToAngle(wr[iw].infos[ip].vv_dx,
                                                                    wr[iw].infos[ip].vv_dy)
                                                        - M_PI_2);
      
      /*
      if (wr[iw].infos[ip].theta > 75 && wr[iw].infos[ip].theta < 105) {
        if (wr[iw].infos[ip].alpha_point > 0) {
          wr[iw].infos[ip].theta = 105;
        }
        else {
          wr[iw].infos[ip].theta = 75;
        }
      }
      
      if (wr[iw].infos[ip].theta > 255 && wr[iw].infos[ip].theta < 285) { 
        if (wr[iw].infos[ip].alpha_point > 0) {
          wr[iw].infos[ip].theta = 285;
        }
        else {
          wr[iw].infos[ip].theta = 255;
        }
      }
      */

      (*wr[iw]._set_label_angle) (wr[iw].rw, wr[iw].infos[ip].id,
                                  120, wr[iw].infos[ip].theta);
      /* wr[iw].infos[ip].rho*/      
    }
  }
}
