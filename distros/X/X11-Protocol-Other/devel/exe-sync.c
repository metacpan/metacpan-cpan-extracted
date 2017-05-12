/* Copyright 2013 Kevin Ryde

   This file is part of X11-Protocol-Other.

   X11-Protocol-Other is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as published
   by the Free Software Foundation; either version 3, or (at your option)
   any later version.

   X11-Protocol-Other is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
   Public License for more details.

   You should have received a copy of the GNU General Public License along
   with X11-Protocol-Other.  If not, see <http://www.gnu.org/licenses/>.  */

#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xext.h>
#include <X11/extensions/sync.h>

int
main (void)
{
  {
    Display *display = XOpenDisplay(NULL);
    if (! display) { abort (); }
  
    int major = 3;
    int minor = 1;
    XSyncInitialize(display, &major, &minor);

    XSyncValue value;
    XSyncIntToValue(&value, 0);
    XSyncCounter counter = XSyncCreateCounter(display, value);

    static XSyncWaitCondition wait_list[1];
    XSyncIntToValue(&value, 123);
    wait_list[0].trigger.counter = counter;
    wait_list[0].trigger.value_type = XSyncAbsolute;
    wait_list[0].trigger.wait_value = value;
    wait_list[0].trigger.test_type = XSyncPositiveTransition;

    printf ("XSyncAwait call\n");
    XSyncAwait(display, wait_list, 1);
    printf ("XSyncAwait return\n");

    printf ("XSync call\n");
    XSync(display, 0);
    printf ("XSync return\n");

    return 0;
  }
  {
    Display *display = XOpenDisplay (NULL);
    if (! display) { abort (); }
  
    int major = 3;
    int minor = 1;
    XSyncInitialize(display, &major, &minor);

    XSyncValue value;
    XSyncIntToValue(&value, 0);
    XSyncCounter counter = XSyncCreateCounter(display, value);

    static XSyncWaitCondition wait_list[1];
    XSyncIntToValue(&value, 123);
    wait_list[0].trigger.counter = counter;
    wait_list[0].trigger.value_type = XSyncAbsolute;
    wait_list[0].trigger.wait_value = value;
    wait_list[0].trigger.test_type = XSyncPositiveTransition;

    printf ("XSyncAwait call\n");
    XSyncAwait(display, wait_list, 1);
    printf ("XSyncAwait return\n");

    printf ("XSync call\n");
    XSync(display, 0);
    printf ("XSync return\n");

    return 0;
  }
}
