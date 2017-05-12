/* Copyright 2008, 2009 Kevin Ryde

   This file is part of Tie-TZ.

   Tie-TZ is free software; you can redistribute it and/or modify it under
   the terms of the GNU General Public License as published by the Free
   Software Foundation; either version 3, or (at your option) any later
   version.

   Tie-TZ is distributed in the hope that it will be useful, but WITHOUT ANY
   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
   FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
   details.

   You should have received a copy of the GNU General Public License along
   with Tie-TZ.  If not, see <http://www.gnu.org/licenses/>. */

#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

int
main (void)
{
  time_t t;
  struct tm *tm;

  printf ("%ld\n", timezone);

  time (&t);
  tm = localtime (&t);
  printf ("%d\n", tm->tm_hour);

  {
    static char *e[] = { "TZ=GMT" };
    environ = e;
  }
  printf ("%ld\n", timezone);

  tm = localtime (&t);
  printf ("%d\n", tm->tm_hour);
  printf ("%ld\n", timezone);
  return 0;
}
