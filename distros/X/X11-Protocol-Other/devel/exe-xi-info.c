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
#include <X11/extensions/XInput.h>

int
main (void)
{
  Display *display;
  int ndevices, i, j, k;
  XDeviceInfo *infos;

  char *display_name = getenv("DISPLAY");
  if (! display_name) {
    display_name = ":0";
  }

  display = XOpenDisplay (display_name);
  if (! display) {
    printf ("no DISPLAY\n");
    abort ();
  }

  infos = XListInputDevices (display, &ndevices);
  if (! infos) {
    printf ("XInputExtension not available\n");
    abort ();
  }
  printf ("%p\n", infos);

  for (i = 0; i < ndevices; i++) {
    XDeviceInfo *info = infos + i;
    printf ("id %ld type %lu use %d num_classes %d   %s\n",
            info->id,
            info->type,
            info->use,
            info->num_classes,
            info->name);
    XAnyClassPtr classinfo = info->inputclassinfo;
    for (j = 0; j < info->num_classes; j++) {
      printf ("  class %ld\n", classinfo->class);
      if (classinfo->class == KeyClass) {
        XKeyInfo *keyinfo = (XKeyInfo *) classinfo;
      } else if (classinfo->class == ButtonClass) {
        XButtonInfo *ptrinfo = (XButtonInfo *) classinfo;
      } else if (classinfo->class == ValuatorClass) {
        XValuatorInfo *valinfo = (XValuatorInfo *) classinfo;
        printf ("    num_axes %d mode %d motion_buffer %lu\n",
                valinfo->num_axes,
                valinfo->mode,
                valinfo->motion_buffer);
        XAxisInfoPtr axes = valinfo->axes;
        for (k = 0; k < valinfo->num_axes; k++) {
          printf ("    resolution %d min %d max %d\n",
                  axes[k].resolution,
                  axes[k].min_value,
                  axes[k].max_value);
        }
      }
      classinfo = (XAnyClassPtr) ((char *) classinfo + classinfo->length);
    }
  }

  return 0;
}


