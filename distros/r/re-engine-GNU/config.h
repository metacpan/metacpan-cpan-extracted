#ifndef NOTGENERATEDCONFIG_H
#define NOTGENERATEDCONFIG_H

#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif

#include "config_autoconf.h"

#ifndef HAVE_SIZE_T
/* Really ? Ok, standard say:
   size_t is an unsigned integer type of at least 16 bit */
/* Assume long is always enough */
typedef unsigned long size_t;
#define HAVE_SIZE_T 1
#define SIZEOF_SIZE_T SIZEOF_LONG
#endif

#ifndef HAVE_SSIZE_T
  #if SIZEOF_SIZE_T == SIZEOF_SHORT
    typedef short ssize_t;
  #else
    #if SIZEOF_SIZE_T == SIZEOF_INT
      typedef int ssize_t;
    #else
      #if SIZEOF_SIZE_T == SIZEOF_LONG
        typedef long ssize_t;
      #else
        #if SIZEOF_SIZE_T == SIZEOF_LONG_LONG
          typedef long long ssize_t;
        #else
         /* WHAT! */
          #error "Cannot determine type of ssize_t"
        #endif
      #endif
    #endif
  #endif
  #define HAVE_SSIZE_T 1
#endif

#endif /* NOTGENERATEDCONFIG_H */
