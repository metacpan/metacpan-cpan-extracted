#ifdef HAS_X11

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <X11/Xlib.h>

bool x11_window(WGPUSurfaceSourceXlibWindow *result, int xw, int yh)
{
  Display *dis;
  Window   win;


  Zero((void*)result, 1, WGPUSurfaceSourceXlibWindow);
  xw = xw ? xw : 640;
  yh = yh ? yh : 360;

  dis = XOpenDisplay(NULL);

  if (!dis)
  {
    return false;
  }

  int scr = DefaultScreen( dis );
  Window root = RootWindow( dis, scr );

  if ( !root )
  {
    XCloseDisplay( dis );
    return false;
  }

  win = XCreateSimpleWindow(
        dis,
        root,
        10, 10,
        xw, yh,
        1, 0,
        0
  );

  XSelectInput(dis, win, ExposureMask);
  XMapWindow( dis, win);

  for (int i = 0; i < 10; i++)
  {
    XEvent e = {};
    XNextEvent(dis, &e);
    if (e.type == Expose) {
      break;
    }
  }

  XSelectInput(dis, win, 0);

  result->chain.sType = WGPUSType_SurfaceSourceXlibWindow;
  result->display = dis;
  result->window  = win;

  return true;
}

#endif
