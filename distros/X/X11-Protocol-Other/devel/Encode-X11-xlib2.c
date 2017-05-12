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
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

int
main (void)
{
  Display *display;
  static XTextProperty text_prop;
  FILE *fp;
  char buf[128];
  int good = 1;
  int count = 0;

  display = XOpenDisplay(NULL);
  if (! display) { printf ("cannot open DISPLAY\n"); abort(); }

  fp = fopen ("../tempfile.txt","r");
  if (! fp) { printf ("cannot open tempfile.utf8\n"); abort(); }

  while (fgets (buf, 128, fp)) {
    char *part;
    int blen = 0;
    int u;
    char bytes[128];
    int ret;
    char **tlist;
    int tcount;
    char utf8[128];
    int utf8len = 0;

    count++;
    part = strtok (buf, " ");
    u = strtol (part, NULL, 0);
    /* printf ("U+%04X\n", u); */

    while ((part = strtok (NULL, " "))) {
      bytes[blen++] = strtol (part, NULL, 16);
    }
    bytes[blen] = '\0';
    /* printf ("blen %d\n", blen); */


    fgets (buf, 128, fp);
    part = strtok (buf, " ");
    utf8[utf8len++] = strtol (part, NULL, 16);
    while ((part = strtok (NULL, " "))) {
      utf8[utf8len++] = strtol (part, NULL, 16);
    }
    utf8[utf8len] = '\0';


    
    text_prop.encoding = XInternAtom(display,"COMPOUND_TEXT",0);
    text_prop.format = 8;
    text_prop.nitems = blen;
    text_prop.value = (unsigned char *) bytes;

    ret = Xutf8TextPropertyToTextList (display,
                                       &text_prop,
                                       &tlist,
                                       &tcount);
    if (ret != Success) {
      int i;
      printf ("U+%04X\n", u);
      printf ("  Xutf8TextPropertyToTextList ret %d\n", ret);

      printf ("  bytes ");
      for (i = 0; i < blen; i++) {
        printf (" %02X", (int) (unsigned char) bytes[i]);
      }
      printf ("\n");
      continue;
    }

    if (strcmp (utf8, tlist[0]) != 0) {
      int i;
      printf ("U+%04X\n", u);
      printf ("  Xutf8TextPropertyToTextList different\n");

      printf ("  got utf8  ");
      for (i = 0; i < strlen(tlist[0]); i++) {
        printf (" %02X", (int) (unsigned char) tlist[0][i]);
      }
      printf ("\n");

      printf ("  want utf8 ");
      for (i = 0; i < utf8len; i++) {
        printf (" %02X", (int) (unsigned char) utf8[i]);
      }
      printf ("\n");
    }
  }

  printf ("total count %d\n", count);
  if (! good) {
    abort();
  }

  return 0;
}

  /*   printf ("text nitems %lu\n", text_prop.nitems); */
  /*   printf ("text value: "); */
