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
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <iconv.h>
#include <locale.h>
#include <wchar.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

int
main (void)
{
  Display *display;

  setlocale (LC_ALL, NULL);
  setlocale (LC_ALL, "ar_IN.UTF-8");
  setlocale (LC_ALL, "en_AU.ISO-8859-1");

  display = XOpenDisplay(NULL);
  printf ("display %p\n", display);

  {
    /* static char ustr[] = "\xCB\x9A"; */
    /* static char ustr[] = "\xE2\x80\xBE"; */ /* U+203E overline */
    /* static char ustr[] = "\xE4\xB8\x80";  *//* U+4E00 */

    iconv_t ic;
    uint32_t ucs = 0x9F9C;
    char *inbuf;
    static char ustr[16];
    char *outbuf;
    size_t inleft, outlen, iret, ulen;
    static char *ulist[2];
    static XTextProperty text_prop;
    int ret;
    int i;

    ic = iconv_open("utf-8","utf-32le");
    if (ic == (iconv_t) -1) { perror("iconv_open"); abort(); }

    for (ucs = 0x100; ucs <= 0x2F1AD; ucs++) {
      inbuf = (char *) &ucs;
      inleft = 4;
      outbuf = ustr;
      outlen = sizeof(ustr)-1;
      iret = iconv (ic, &inbuf, &inleft, &outbuf, &outlen);
      if (iret == -1) {
        continue;
        perror("iconv"); abort();
      }
      if (iret != 0) { printf("iret %u\n", iret); abort(); }

      ulen = outbuf - ustr;
      ustr[ulen] = '\0';

      ulist[0] = ustr;
      ret = Xutf8TextListToTextProperty (display,
                                         ulist,
                                         1,
                                         XCompoundTextStyle,
                                         &text_prop);
      if (ret != 0) {
        continue;
      }
      if (text_prop.value[1] != 0x24) {
        continue;
      }
      if (text_prop.value[3] < 0x46) {
        continue;
      }
      printf ("ret %d\n", ret);
      if (ret >= 0) {
        printf ("ucs 0x%04X ustr [len %u] ", ucs, ulen);
        for (i = 0; i < ulen; i++) {
          printf (" %02X", (unsigned) (unsigned char) ustr[i]);
        }
        printf ("\n");

        printf ("text encoding %lu\n", text_prop.encoding);
        printf ("text encoding %s\n", XGetAtomName(display,text_prop.encoding));
        printf ("text format %d\n", text_prop.format);
        printf ("text nitems %lu\n", text_prop.nitems);
        printf ("text value: ");
        for (i = 0; i < text_prop.nitems; i++) {
          printf (" %02X", text_prop.value[i]);
        }
        printf ("\n");
        break;
      }
    }
    return 0;
  }

  {
    static char ctext[] = "\x1B\x28\x4A\x7E";
    /* "\x1B\x28\x49\x7C\x7D"; */
    static XTextProperty text_prop;
    int ret;
    char **tlist;
    int tcount;
    int i;

    text_prop.encoding = XInternAtom(display,"COMPOUND_TEXT",0);
    text_prop.format = 8;
    text_prop.nitems = strlen(ctext);
    text_prop.value = (unsigned char *) ctext;

    ret = Xutf8TextPropertyToTextList (display,
                                       &text_prop,
                                       &tlist,
                                       &tcount);
    printf ("  Xutf8TextPropertyToTextList ret %d\n", ret);

    printf ("  got utf8  ");
    for (i = 0; i < strlen(tlist[0]); i++) {
      printf (" %02X", (int) (unsigned char) tlist[0][i]);
    }
    printf ("\n");
    return 0;
  }


  {
    const char *str = XDefaultString();
    int i;
    printf ("XDefaultString [len %d] ", strlen(str));
    for (i = 0; i < strlen(str); i++) {
      printf (" %02X", (int) (unsigned char) str[i]);
    }
    printf ("\n");
    printf ("\"Success\" is %d\n", Success);
  }
  

  {
    FILE *fp = fopen ("encode-emacs23.utf8","r");
    if (! fp) { printf ("cannot open\n"); abort(); }
    char buf[500000];
    size_t len = fread (buf, 1, 500000, fp);
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

  {
    static wchar_t wstr[2];
    static wchar_t *wlist[2];
    static XTextProperty text_prop;
    int ret;
    wchar_t c;
    int i;

    for (c = 32; c < 1000; c++) {
      wstr[0] = c;
      wlist[0] = wstr;
      ret = XwcTextListToTextProperty (display,
                                       wlist,
                                       1,
                                       XCompoundTextStyle,
                                       &text_prop);
      printf ("c=%d ret %d\n", c, ret);
      if (ret == 0) {
        printf ("text encoding %lu\n", text_prop.encoding);
        printf ("text encoding %s\n", XGetAtomName(display,text_prop.encoding));
        printf ("text format %d\n", text_prop.format);
        printf ("text nitems %lu\n", text_prop.nitems);
        printf ("text value: ");
        for (i = 0; i < text_prop.nitems; i++) {
          printf (" %02X", text_prop.value[i]);
        }
        printf ("\n");
      }
    }
    return 0;
  }
  


  return 0;
}
