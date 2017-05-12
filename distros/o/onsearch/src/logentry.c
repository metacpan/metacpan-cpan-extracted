/* "$Id: logentry.c,v 1.2 2005/08/06 12:13:22 kiesling Exp $" */

#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <stdlib.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <time.h>
#include <syslog.h>
#include <sys/utsname.h>
#include "onindex.h"

static int logging = 0;
static char appname[64];
/* static char logname[255]; */

extern char log_path[MAXPATH];

extern int errno;

extern char *tzname[2];
extern int daylight;

/* Prototypes */
void currenttimestring (char *);
void clftimestring (char *);
char *hostname (void);
int clf (char *, char *,...);
int logentry (char *,...);

char *hostname (void) {
  
  static struct utsname u;
  int r;

  if ((r = uname (&u)) < 0) {
    fprintf (stderr, "hostname: %s\n", strerror(errno));
  }

  return u.nodename;
}

int clf (char *priority, char *fmt, ...) {

  char fbuf[MAXREC];
  char buf[MAXREC];
  char logname[MAXPATH];
  FILE *log;
  va_list ap;
  int d;
  char t, c, *s;
  double fl;

  *buf = 0;

  sprintf (logname, "%s/%s", log_path, "onsearch.log");

  if ((log = fopen (logname, "a")) == NULL) {
    fprintf (stderr, "onindex clf (%s): %s\n",
	     logname, strerror (errno));
    _exit (1);
  }

  clftimestring (buf);

  sprintf (buf, "%s [%s] [%s %s] ", buf, priority, 
	   (getenv ("HTTP_REFERER") ? getenv("HTTP_REFERER") : 
	    getenv("SHELL")),
	   (getenv ("REMOTE_ADDR") ? getenv ("REMOTE_ADDR") : 
	    getenv ("LOGNAME")));

  va_start (ap, fmt);

  while (*fmt) {
    switch (t = *fmt++)
      {
      case '%':
	switch (*fmt++)        /* type conversion specifier */
	  { 
	  case 's':           /* string */
	    s = va_arg(ap, char *);
	    sprintf( fbuf, "%s", s);
	    break;
	  case 'd':
	  case 'i':
	    d = va_arg(ap, int);
	    sprintf(fbuf, "%d", d);
	    break;
	  case 'o':      /*octal */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%o", d);
	    break;
	  case 'u':   /* unsigned int */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%u", d);
	    break;
	  case 'x':    /* hexadecimal lowercase */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%x", d);
	    break;
	  case 'X':    /* hexadecimal lowercase */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%X", d);
	    break;
	  case 'e':           /* double exponential lowercase */
	    fl = (double) va_arg (ap, double);
	    sprintf (fbuf, "%e", fl);
	    break;
	  case 'E':           /* double exponential uppercase */
	    fl = (double) va_arg (ap, double);
	    sprintf (fbuf, "%E", fl);
	    break;
	  case 'f':           /* float */
	    fl = (double) va_arg (ap, double);
	    sprintf (fbuf, "%f", fl);
	    break;
	  case 'F':           /* float */
	    fl = (double) va_arg (ap, double); 
	    sprintf (fbuf, "%f", fl);
	    break; 
	  case 'c':           /* char */
	    c = (char) va_arg(ap, int);
	    sprintf(fbuf, "%c", c);
	    break;
	  case 'p':   /* unsigned pointer */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf(fbuf, "%p", (void *) d);
	    break;
	  }
	break;
      default:
	sprintf (fbuf, "%c", t); 
	break;
      }
    strcat (buf, fbuf);
  }

  va_end(ap);

  fprintf (log, "%s\n", buf);

  fclose (log);

  return FALSE;
}

/* no precisions or field widths yet */
int logentry ( char *fmt, ...) {

  char fbuf[MAXREC];
  char buf[MAXREC];
  char lbuf[MAXREC];
  char timestr[64];

  va_list ap;
  int d;
  char t, c, *s;
  double fl;

  /***/
/*   FILE *f; */
/*   char appendmode[] = "a"; */
  int result;

  if (!logging) return -1;

  *buf = 0;

  va_start (ap, fmt);
  while (*fmt) {
    switch (t = *fmt++)
      {
      case '%':
	switch (*fmt++)        /* type conversion specifier */
	  { 
	  case 's':           /* string */
	    s = va_arg(ap, char *);
	    sprintf( fbuf, "%s", s);
	    break;
	  case 'd':
	  case 'i':
	    d = va_arg(ap, int);
	    sprintf(fbuf, "%d", d);
	    break;
	  case 'o':      /*octal */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%o", d);
	    break;
	  case 'u':   /* unsigned int */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%u", d);
	    break;
	  case 'x':    /* hexadecimal lowercase */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%x", d);
	    break;
	  case 'X':    /* hexadecimal lowercase */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf (fbuf, "%X", d);
	    break;
	  case 'e':           /* double exponential lowercase */
	    fl = (double) va_arg (ap, double);
	    sprintf (fbuf, "%e", fl);
	    break;
	  case 'E':           /* double exponential uppercase */
	    fl = (double) va_arg (ap, double);
	    sprintf (fbuf, "%E", fl);
	    break;
	  case 'f':           /* float */
	    fl = (double) va_arg (ap, double);
	    sprintf (fbuf, "%f", fl);
	    break;
	  case 'F':           /* float */
	    fl = (double) va_arg (ap, double); 
	    sprintf (fbuf, "%f", fl);
	    break; 
	  case 'c':           /* char */
	    c = (char) va_arg(ap, int);
	    sprintf(fbuf, "%c", c);
	    break;
	  case 'p':   /* unsigned pointer */
	    d = (unsigned int) va_arg(ap, int);
	    sprintf(fbuf, "%p", (void *) d);
	    break;
	  }
	break;
      default:
	sprintf (fbuf, "%c", t); 
	break;
      }
    strcat (buf, fbuf);
  }

  va_end(ap);

  currenttimestring (timestr);

  sprintf (lbuf, "%s %s %s[%d] %s\n", timestr, hostname (), appname, 
	   getpid(), buf);

  return result;

}

void currenttimestring (char *buf) {

  struct timeval tv;
  struct timezone tz;
  struct tm *t;
  static char *mnames[12] = {"Jan", "Feb", "Mar", 
			 "Apr", "May", "Jun",
			 "Jul", "Aug", "Sep",
			  "Oct", "Nov", "Dec"};


  tz.tz_minuteswest = 0; /* gmt? */
  tz.tz_dsttime = 0;

  gettimeofday (&tv, &tz);
  t = localtime (&(tv.tv_sec));

  sprintf (buf, "%s %02d %02d:%02d:%02d", mnames[t -> tm_mon], 
	   t -> tm_mday, t -> tm_hour, t -> tm_min, t -> tm_sec);
}

void clftimestring (char *buf) {

  struct timeval tv;
  struct timezone tz;
  struct tm *t;
  static char *mnames[12] = {"Jan", "Feb", "Mar", 
			 "Apr", "May", "Jun",
			 "Jul", "Aug", "Sep",
			  "Oct", "Nov", "Dec"};
  static char *dnames[7] = {"Sun", "Mon", "Tue",
			    "Wed", "Thu", "Fri",
			    "Sat"};

  tz.tz_minuteswest = 0; /* gmt? */
  tz.tz_dsttime = 0;

  gettimeofday (&tv, &tz);
  t = localtime (&(tv.tv_sec));

  sprintf (buf, "[%s %s %2d %02d:%02d:%02d %4d]", 
	   dnames[t -> tm_wday],
	   mnames[t -> tm_mon],
	   t -> tm_mday,
	   t -> tm_hour,
	   t -> tm_min,
	   t -> tm_sec,
	   t -> tm_year + 1900);
}

