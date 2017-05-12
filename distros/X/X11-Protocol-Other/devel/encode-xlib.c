/* Copyright 2011 Kevin Ryde

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
#include <string.h>
#include <locale.h>
#include <wchar.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

int
main (void)
{
  Display *display;

  display = XOpenDisplay(NULL);
  printf ("display %p\n", display);

  {
    FILE *fp = fopen ("encode-xlib.utf8","r");
    if (! fp) { printf ("cannot open\n"); abort(); }
    char buf[500000];
    size_t len = fread (buf, 1, 1000000, fp);
    fclose (fp);
    buf[len] = '\0';
    
    static char *ulist[2];
    static XTextProperty text_prop;
    int ret;

    ulist[0] = buf;
    ret = Xutf8TextListToTextProperty (display,
                                       ulist,
                                       1,
                                       XCompoundTextStyle,
                                       &text_prop);
    printf ("ret %d\n", ret);
    if (ret >= 0) {
      printf ("text encoding %lu\n", text_prop.encoding);
      printf ("text encoding %s\n", XGetAtomName(display,text_prop.encoding));
      printf ("text format %d\n", text_prop.format);
      printf ("text nitems %lu\n", text_prop.nitems);
      printf ("text value: ");
      /* for (i = 0; i < text_prop.nitems; i++) { */
      /*   printf (" %02X", text_prop.value[i]); */
      /* } */
      /* printf ("\n"); */

      FILE *fp = fopen ("encode-emacs23xc.ctext","w");
      if (! fp) { printf ("cannot open\n"); abort(); }
      fwrite (text_prop.value, text_prop.nitems, 1, fp);
      fclose(fp);
    }
    return 0;
  }

  return 0;
}
