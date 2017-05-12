/* Copyright 2012 Kevin Ryde

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
#include <X11/extensions/Xvlib.h>

int
main (void)
{
  char *display_name = getenv("DISPLAY");
  if (! display_name) {
    display_name = ":0";
  }

  Display *display = XOpenDisplay (display_name);
  if (! display) {
    printf ("no DISPLAY\n");
    abort ();
  }

  Window window = DefaultRootWindow(display);

  unsigned nadap;
  XvAdaptorInfo *padap;
  {
    int status = XvQueryAdaptors (display, window, &nadap, &padap);
    if (status) {
      printf ("XvQueryAdaptors fail\n");
      abort ();
    }
  }
  printf ("nadap %u  padap %p\n", nadap, padap);

  unsigned a;
  for (a = 0; a < nadap; a++) {
    padap++;
    
    unsigned i;
    for (i = 0; i < padap[0].num_ports; i++) {
      XvPortID port = padap[0].base_id + i;
      printf ("port %u\n", port);

      unsigned nenc;
      XvEncodingInfo *penc;
      {
        int status = XvQueryEncodings (display, port, &nenc, &penc);
        if (status) {
          printf ("XvQueryEncodings fail\n");
          abort ();
        }
      }
      printf ("nenc %u  penc %p\n", nenc, penc);
    }
  }
  
  return 0;
}


