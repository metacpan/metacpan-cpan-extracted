/* Copyright 2011, 2012 Kevin Ryde

   This file is part of X11-Protocol-Other.

   X11-Protocol-Other is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option) any
   later version.

   X11-Protocol-Other is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/scrnsaver.h>

/* cf. ProcScreenSaverQueryInfo()
   http://cgit.freedesktop.org/xorg/xserver/tree/Xext/saver.c#n719
 */

int
main (void)
{
  Display *display;
  Window rootwin;
  int event_base, error_base;
  XScreenSaverInfo info;

  char *display_name = getenv("DISPLAY");
  if (! display_name) {
    display_name = ":0";
  }

  display = XOpenDisplay (display_name);
  if (! display) {
    printf ("no DISPLAY\n");
    abort ();
  }
  rootwin = DefaultRootWindow (display);

  if (! XScreenSaverQueryExtension (display, &event_base, &error_base)) {
    printf ("screensaver not available\n");
    abort ();
  }

  /* if (! XForceScreenSaver (display, ScreenSaverActive)) { */
  /*   printf ("cannot force screensaver on\n"); */
  /*   abort (); */
  /* } */
  /* XFlush (display); */
  /* sleep(1); */

  if (! XScreenSaverQueryInfo (display, rootwin, &info)) {
    printf ("cannot QueryInfo\n");
    abort();
  }

  printf ("state %d\n", info.state);
  printf ("til_or_since %lu\n", info.til_or_since);
  printf ("til_or_since as signed %ld\n", info.til_or_since);

  if (! XForceScreenSaver (display, ScreenSaverReset)) {
    printf ("cannot force screensaver off again\n");
    abort ();
  }
  XFlush (display);

  return 0;
}


