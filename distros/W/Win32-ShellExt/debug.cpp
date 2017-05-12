// -*- c++ -*-
//
// (C) 2002 Jean-Baptiste Nivoit <jbnivoit@cpan.org>
//
#include <stdio.h>
#include <varargs.h>

#include "debug.h"

void shellext_debug(const char *fmt, ...) 
  // This needs to be in a .c file where the Perl stuff is not visible,
  // because they have a tendency to change everything with macros (most
  // notably they rewrite printf & friends, which is a problem since the
  // perl macros change mine!).
{
#ifdef EXTDEBUG_DEV
  FILE *f=fopen(EXTDEBUG_DEV,"a+");
  if(f!=0) {
    va_dcl;
    va_list ap;
    va_start(ap/*,fmt*/);
    fprintf(f,fmt, ap);
    va_end(ap);

    fclose(f);
  }
#endif
}
