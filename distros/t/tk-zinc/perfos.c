/*
 * perfos.c -- Perfos modules.
 *
 * Authors              : Patrick Lecoanet.
 * Creation date        : 
 *
 * $Id: perfos.c,v 1.13 2005/04/27 07:32:03 lecoanet Exp $
 */

/*
 *  Copyright (c) 1993 - 2005 CENA, Patrick Lecoanet --
 *
 * See the file "Copyright" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 */

#ifndef _WIN32

#include "perfos.h"
#include "List.h"
#include "Types.h"

#include <X11/Xutil.h>


static const char rcsid[] = "$Id: perfos.c,v 1.13 2005/04/27 07:32:03 lecoanet Exp $";
static const char compile_id[]="$Compile: " __FILE__ " " __DATE__ " " __TIME__ " $";


static ZnList   Chronos = NULL;


/*
 **********************************************************************************
 *
 * HardwareSynchronize - Synchronise Xwindow.
 *
 **********************************************************************************
 */
static void
HardwareSynchronize(Display     *test_display,
                    Drawable    test_window)
{
  /*XImage   *image;*/

  /* Synchronize yourself with the drawing engine by sending a
     XGetImage one pixel square. */
  /*
  image = XGetImage(test_display, test_window, 0, 0, 1, 1, ~0, ZPixmap);
  XDestroyImage(image);
  */
}


/*
 **********************************************************************************
 *
 * GetUCTime - Return machine time. This is the sum of user and system
 *      times for the process so far.
 *
 **********************************************************************************
 */
static long
GetUCTime(void)
{
  struct tms    time;

  times(&time);
  return time.tms_utime + time.tms_stime;
}


/*
 **********************************************************************************
 *
 * GetCurrentTime - Return current time.
 *
 **********************************************************************************
 */
static long
GetCurrentTime(void)
{
  struct timeval start;

  gettimeofday(&start, NULL);
  return((start.tv_sec * 100) + (start.tv_usec / 10000));
}


/*
 **********************************************************************************
 *
 * XGetCurrentTime - return current time after Xwindow synchronize.
 *
 **********************************************************************************
 */
static long
XGetCurrentTime(Display *display, Drawable window)
{
  HardwareSynchronize(display, window);
  return(GetCurrentTime());
}


/*
 **********************************************************************************
 *
 * XCorrectionValue - Evaluate the correction value to apply
 *                    to counter the client-server round trip
 *                    time.
 *
 **********************************************************************************
 */
static long
XCorrectionValue(Display *display, Drawable window)
{ 
  int               i;
  long              start, stop;

  start = GetCurrentTime();
  for (i = 0; i < 5; i++) {
    HardwareSynchronize(display, window);
  }
  stop = GetCurrentTime();
  return((stop - start) / 5);
}

/*
 **********************************************************************************
 *
 * ZnXStartChrono - Start a perf chrono with X synchronize.
 *
 **********************************************************************************
 */
void
ZnXStartChrono(ZnChrono chrono, Display *display, Drawable window)
{
  chrono->current_correction = XCorrectionValue(display, window);
  chrono->current_delay = XGetCurrentTime(display, window);
}


/*
 **********************************************************************************
 *
 * ZnXStopChrono - Stop a perf chrono with X synchronize.
 *
 **********************************************************************************
 */
void
ZnXStopChrono(ZnChrono chrono, Display *display, Drawable window)
{
  chrono->total_delay = chrono->total_delay +
    (XGetCurrentTime(display, window) - 
     chrono->current_delay - chrono->current_correction);
  chrono->actions++;
}


/*
 **********************************************************************************
 *
 * ZnStartChrono - Start a perf chrono in user time.
 *
 **********************************************************************************
 */
void
ZnStartChrono(ZnChrono chrono)
{
  chrono->current_delay = GetCurrentTime();
}


/*
 **********************************************************************************
 *
 * ZnStopChrono - Stop a perf chrono in user time.
 *
 **********************************************************************************
 */
void
ZnStopChrono(ZnChrono chrono)
{
  chrono->total_delay = chrono->total_delay + (GetCurrentTime() - chrono->current_delay);
  chrono->actions++;
}


/*
 **********************************************************************************
 *
 * ZnStartUCChrono - Start a perf chrono in uc time.
 *
 **********************************************************************************
 */
void
ZnStartUCChrono(ZnChrono chrono)
{
  chrono->current_delay = GetUCTime();
}


/*
 **********************************************************************************
 *
 * ZnStopUCChrono - Stop a perf chrono in uc time.
 *
 **********************************************************************************
 */
void
ZnStopUCChrono(ZnChrono chrono)
{
  chrono->total_delay = chrono->total_delay + (GetUCTime() - chrono->current_delay);
  chrono->actions++;
}


/*
 **********************************************************************************
 *
 * ZnPrintChronos - Print the currently available stats on all
 *                chronos registered so far.
 *
 **********************************************************************************
 */
void
ZnPrintChronos(void)
{
  int           i, cnt;
  ZnChrono      *chrs;
  
  cnt = ZnListSize(Chronos);
  chrs = (ZnChrono *) ZnListArray(Chronos);
  for (i = 0; i < cnt; i++) {
    if (chrs[i]->actions != 0) {
      printf("%s : %ld ms on %d times\n",
             chrs[i]->message,
             chrs[i]->total_delay * 10 / chrs[i]->actions,
             chrs[i]->actions);
    }
  }
}


/*
 **********************************************************************************
 *
 * ZnGetChrono - Return the number of runs and the total time of the Chrono.
 *
 **********************************************************************************
 */
void
ZnGetChrono(ZnChrono    chrono,
            long        *time,
            int         *actions)
{
  if (time) {
    *time = chrono->total_delay*10;
  }
  if (actions) {
    *actions = chrono->actions;
  }
}


/*
 **********************************************************************************
 *
 * ZnResetChronos - Reset all chronos or only the specified.
 *
 **********************************************************************************
 */
void
ZnResetChronos(ZnChrono chrono)
{
  int           i, cnt;
  ZnChrono      *chrs;

  if (chrono) {
    chrono->actions = 0;
    chrono->total_delay = 0;    
  }
  else {
    cnt = ZnListSize(Chronos);
    chrs = (ZnChrono *) ZnListArray(Chronos);
    for (i = 0; i < cnt; i++) {
      chrs[i]->actions = 0;
      chrs[i]->total_delay = 0;
    }
  }
}


/*
 **********************************************************************************
 *
 * ZnNewChrono - Return a new initialized chrono associated with
 *             message.
 *
 **********************************************************************************
 */
ZnChrono
ZnNewChrono(char *message)
{
  ZnChrono      new;

  if (!Chronos) {
    Chronos = ZnListNew(8, sizeof(ZnChrono));
  }

  new = (ZnChrono) ZnMalloc(sizeof(ZnChronoRec));
  new->actions = 0;
  new->total_delay = 0;
  new->message = message;

  ZnListAdd(Chronos, &new, ZnListTail);

  return new;
}

/*
 **********************************************************************************
 *
 * ZnFreeChrono - Free the resources of a chrono.
 *
 **********************************************************************************
 */
void
ZnFreeChrono(ZnChrono   chrono)
{
  int      i;
  ZnChrono *chrs = ZnListArray(Chronos);
  
  ZnFree(chrono);

  for (i = ZnListSize(Chronos)-1; i >= 0; i--) {
    if (chrs[i] == chrono) {
      ZnListDelete(Chronos, i);
      break;
    }
  }
}

#endif /* _WIN32 */
