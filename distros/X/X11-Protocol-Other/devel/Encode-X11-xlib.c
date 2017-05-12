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
#include <locale.h>
#include <wchar.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

int
main (void)
{
  Display *display;
  static char ubuf[500000];
  size_t ulen;
  static char cbuf[500000];
  size_t clen;
  static XTextProperty text_prop;
  int ret;
  char **tlist;
  int tcount;

  display = XOpenDisplay(NULL);
  if (! display) { printf ("cannot open DISPLAY\n"); abort(); }

  {
    FILE *fp = fopen ("../tempfile.utf8","r");
    if (! fp) { printf ("cannot open tempfile.utf8\n"); abort(); }
    ulen = fread (ubuf, 1, sizeof(ubuf)-1, fp);
    if (fclose(fp) != 0) { abort(); }
    ubuf[ulen] = '\0';
  }
  {
    FILE *fp = fopen ("../tempfile.ctext","r");
    if (! fp) { printf ("cannot open tempfile.ctext\n"); abort(); }
    clen = fread (cbuf, 1, sizeof(cbuf)-1, fp);
    if (fclose(fp) != 0) { abort(); }
    cbuf[clen] = '\0';
  }

  printf ("ulen %d\n", ulen);
  printf ("clen %d\n", clen);

  text_prop.encoding = XInternAtom(display,"COMPOUND_TEXT",0);
  text_prop.format = 8;
  text_prop.nitems = clen;
  text_prop.value = (unsigned char *) cbuf;

  ret = Xutf8TextPropertyToTextList (display,
                                     &text_prop,
                                     &tlist,
                                     &tcount);
  printf ("tcount %d\n", tcount);

  if (ret != Success) {
    printf ("Xutf8TextPropertyToTextList ret %d\n", ret);

    {
      FILE *fp = fopen ("../tempfile-xlib.utf8","w");
      if (! fp) { printf ("cannot create ../tempfile-xlib.utf8\n"); abort(); }
      if (fputs (tlist[0], fp) == EOF) { abort (); }
      if (fclose(fp) != 0) { abort(); }
    }

    abort();
  }


  /*   printf ("text nitems %lu\n", text_prop.nitems); */
  /*   printf ("text value: "); */
  /*   /\* for (i = 0; i < text_prop.nitems; i++) { *\/ */
  /*   /\*   printf (" %02X", text_prop.value[i]); *\/ */
  /*   /\* } *\/ */
  /*   /\* printf ("\n"); *\/ */
  /*  */
  return 0;

}
