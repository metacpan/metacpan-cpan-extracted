#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <sys/time.h>
#include <utime.h>
#include <fcntl.h>

struct timespec d2t (double d)
{
  struct timespec ts;
  ts.tv_sec  = d;
  ts.tv_nsec = 1000000000 * (d - (unsigned long long)d);
  return ts;
}

MODULE = utime2		PACKAGE = utime2		

int 
utime2 (atime, mtime, path)
    double atime
    double mtime
    const char * path
  INIT:
    struct timespec ts[2];
    int fd;
    int rc;
  CODE:
    ts[0] = d2t (atime);
    ts[1] = d2t (mtime);

    rc = 0;

    if ((fd = open (path, O_RDONLY)) >= 0)
      {
        if (futimens (fd, ts) == 0)
          rc = 1;
        close (fd);
      }
   
    RETVAL = rc;

  OUTPUT:
    RETVAL



