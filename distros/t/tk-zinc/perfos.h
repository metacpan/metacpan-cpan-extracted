/*
 * perfos.h -- Header for perf module.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        :
 *
 * $Id: perfos.h,v 1.6 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1996 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */


#ifndef _perfos_h
#define _perfos_h

#ifdef __CPLUSPLUS__
extern "C" {
#endif

#ifndef _WIN32

#include <stdio.h>
#include <math.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/times.h>
#include <X11/Xlib.h>

  typedef struct
  {
    long   current_correction;
    long   current_delay;
    long   total_delay;
    int    actions;
    char   *message;
  } ZnChronoRec, *ZnChrono;
  
  
  void ZnXStartChrono(ZnChrono /*chrono*/, Display */*dpy*/, Drawable /*win*/);
  void ZnXStopChrono(ZnChrono /*chrono*/, Display */*dpy*/, Drawable /*win*/);
  void ZnStartChrono(ZnChrono /*chrono*/);
  void ZnStopChrono(ZnChrono /*chrono*/);
  void ZnStartUCChrono(ZnChrono /*chrono*/);
  void ZnStopUCChrono(ZnChrono /*chrono*/);
  ZnChrono ZnNewChrono(char */*message*/);
  void ZnFreeChrono(ZnChrono /*chrono*/);
  void ZnPrintChronos(void);
  void ZnGetChrono(ZnChrono /*chrono*/, long */*time*/, int */*actions*/);
  void ZnResetChronos(ZnChrono /*chrono*/);

#endif /* _WIN32 */

#ifdef __CPLUSPLUS__
}
#endif

#endif  /* _perfos_h */
