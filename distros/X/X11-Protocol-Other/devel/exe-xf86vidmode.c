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
#include <X11/extensions/xf86vmproto.h>

typedef struct {
  CARD32	dotclock B32;
  CARD16	hdisplay B16;
  CARD16	hsyncstart B16;
  CARD16	hsyncend B16;
  CARD16	htotal B16;
  CARD32	hskew B16;
  CARD16	vdisplay B16;
  CARD16	vsyncstart B16;
  CARD16	vsyncend B16;
  CARD16	vtotal B16;
  CARD16	pad1 B16;
  CARD32	flags B32;
  CARD32	reserved1 B32;
  CARD32	reserved2 B32;
  CARD32	reserved3 B32;
  CARD32	privsize B32;
} quux;

int
main (void)
{
  Display *display;

  printf ("sizeof(xXF86VidModeGetAllModeLinesReply) %u\n",
          sizeof(xXF86VidModeGetAllModeLinesReply));
  printf ("\n");


  static xXF86VidModeModeInfo foo;
  static struct {
    unsigned short x : 16;
    unsigned long y;
  } bar;

  printf ("sizeof(xXF86VidModeModeInfo) %u\n",
          sizeof(xXF86VidModeModeInfo));

  printf ("offsetof(hskew) %u\n",
          offsetof(xXF86VidModeModeInfo,hskew));
  printf ("offsetof(vdisplay) %u\n",
          offsetof(xXF86VidModeModeInfo,vdisplay));

  printf ("offsetof(pad1) %u\n",
          offsetof(xXF86VidModeModeInfo,pad1));
  printf ("offsetof(flags) %u\n",
          offsetof(xXF86VidModeModeInfo,flags));
  printf ("\n");

  
  printf ("sizeof(xXF86OldVidModeModeInfo) %u\n",
          sizeof(xXF86OldVidModeModeInfo));

  return 0;
}


