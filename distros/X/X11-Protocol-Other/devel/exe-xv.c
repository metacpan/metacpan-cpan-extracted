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
#include <X11/extensions/Xvproto.h>

int
main (void)
{
  printf ("sizeof(xvEncodingInfo) %u\n",
          sizeof(xvEncodingInfo));
  printf ("sz_xvEncodingInfo %u\n",
          sz_xvEncodingInfo);
  printf ("\n");

  return 0;
}


