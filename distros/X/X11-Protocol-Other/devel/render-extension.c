#include <stdio.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xrender.h>

int main (int argc, char *argv[])
{
  Display *display;
  int event = 999999999, error = 9999999;

  putenv ("DISPLAY=:2");

  display = XOpenDisplay (NULL);
  printf ("dpy %p\n", display);

  XSynchronize (display, True);

  sleep (15);
  printf ("%d\n", XRenderQueryExtension (display, &event, &error));

  
/*   { */
/*     Window focus; */
/*     int revert; */
/*     XGetInputFocus (display, &focus, &revert); */
/*   } */

  XCloseDisplay (display);
  return 0;
}
