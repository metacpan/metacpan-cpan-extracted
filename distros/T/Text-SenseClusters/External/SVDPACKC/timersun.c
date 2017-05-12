/*************************************************************************
                           (c) Copyright 1993
                        University of Tennessee
                          All Rights Reserved                          
 *************************************************************************/
#include <sys/time.h>
#include <sys/resource.h>
/***********************************************************************
 *								       *
 *			  timer()				       *
 *       User-supplied function returns elapsed cpu time (float)       *
 *								       *
 ***********************************************************************/

float timer(void) 

{
   long elapsed_time;
   struct rusage mytime;
   getrusage(RUSAGE_SELF,&mytime);

   /* convert elapsed time to milliseconds */
   elapsed_time = (mytime.ru_utime.tv_sec * 1000 + 
		   mytime.ru_utime.tv_usec / 1000);

   /* return elapsed time in seconds */
   return((float)elapsed_time/1000.);
}
