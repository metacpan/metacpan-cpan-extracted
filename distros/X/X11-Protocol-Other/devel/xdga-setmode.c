#include <stdio.h>
#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/extensions/Xxf86dga.h>

int
error_handler (Display *display, XErrorEvent *error)
{
  printf ("ignore error\n");
}

int
main (void)
{
  int i;
  Display *display = XOpenDisplay(NULL);
  if (! display) abort();
  Window root = DefaultRootWindow(display);
  int screen = DefaultScreen(display);
  int mode = -1;

  XSetErrorHandler(&error_handler);
  
  for (i = 0; i < 1000; i++) {
    Pixmap pixmap = XCreatePixmap(display, root, 1,1,1);
    printf ("pixmap %X\n", pixmap);
    XFreePixmap(display,pixmap);
    
    /* XDGASetMode (display, screen, mode); */
  }
  return 0;
}
