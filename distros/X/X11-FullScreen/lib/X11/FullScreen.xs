#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include <X11/X.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#include <X11/extensions/XShm.h>

#include <Imlib2.h>

#define MWM_HINTS_DECORATIONS   (1L << 1)
#define PROP_MWM_HINTS_ELEMENTS 5
typedef struct {
  uint32_t  flags;
  uint32_t  functions;
  uint32_t  decorations;
  int32_t   input_mode;
  uint32_t  status;
} MWMHints;


/* Bitmap data for invisible pointer */
static unsigned char bm_no_data[] = { 0,0,0,0, 0,0,0,0 };

/* Color for invisible pointer */
static XColor black = { 0L, 0, 0, 0, 0, 0 };

struct x11_fullscreen_s {
	SV* display_str;
	Display * display;
	Window window;
};

typedef struct x11_fullscreen_s* X11_FullScreen;

typedef XEvent* X11_FullScreen_Event;

MODULE = X11::FullScreen	PACKAGE = X11::FullScreen PREFIX=x11_fullscreen_

PROTOTYPES: DISABLE

X11_FullScreen
x11_fullscreen_new(pkg, display_str)
	char *pkg
	SV *display_str
	PREINIT:
		X11_FullScreen xefs;
	CODE:
		Newxz(xefs, 1, struct x11_fullscreen_s);
		xefs->display_str = newSVsv(display_str);
		RETVAL = xefs;
	OUTPUT:
		RETVAL

Display *
x11_fullscreen_display(self)
	X11_FullScreen self
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		RETVAL = self->display;
	OUTPUT:
		RETVAL

Window
x11_fullscreen_window(self)
	X11_FullScreen self
	CODE:
		if ( self->window == 0 ) {
			croak("Window not initialized");
		}
		RETVAL = self->window;
	OUTPUT:
		RETVAL

int
x11_fullscreen_screen(self)
	X11_FullScreen self
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		RETVAL = XDefaultScreen(self->display);
	OUTPUT:
		RETVAL
		
void
x11_fullscreen_show(self)
	X11_FullScreen self
	PREINIT:
		int screen;
		int width;
		int height;
		char* display_str;
		Pixmap bm_no;
		Cursor cursor;
		Atom XA_NO_BORDER;
		MWMHints mwmhints;
		XEvent xev;
		Atom wm_state;
		Atom fullscreen;
		Window window;
	CODE:
		if(! XInitThreads() ) {
			croak("Unable to init threads");
		}
		display_str = SvPV_nolen(self->display_str);
		self->display = XOpenDisplay(display_str);
		if ( self->display == NULL ) {
			croak("Unable to open display");
		}
 		XLockDisplay(self->display);
		screen = XDefaultScreen(self->display);
		width = DisplayWidth(self->display, screen);
		height = DisplayWidth(self->display, screen);
 		window = XCreateSimpleWindow(self->display, XDefaultRootWindow(self->display), 0, 0, width, height, 0, 0, 0);
		XSelectInput(self->display, window, (ExposureMask | ButtonPressMask | KeyPressMask | ButtonMotionMask | StructureNotifyMask | PropertyChangeMask | PointerMotionMask));
  XA_NO_BORDER         = XInternAtom(self->display, "_MOTIF_WM_HINTS", False);
  mwmhints.flags       = MWM_HINTS_DECORATIONS;
  mwmhints.decorations = 0;
  XChangeProperty(self->display, window,
		  XA_NO_BORDER, XA_NO_BORDER, 32, PropModeReplace, (unsigned char *) &mwmhints,
		  PROP_MWM_HINTS_ELEMENTS);
		bm_no = XCreateBitmapFromData(self->display,
				XDefaultRootWindow(self->display),
				bm_no_data,
				8,
				8);
  		cursor = XCreatePixmapCursor(self->display, bm_no, bm_no, &black, &black, 0, 0);
  		XDefineCursor(self->display, window, cursor);
		wm_state = XInternAtom(self->display, "_NET_WM_STATE", False);
		fullscreen = XInternAtom(self->display, "_NET_WM_STATE_FULLSCREEN", False);
		memset(&xev, 0, sizeof(xev));
		xev.type = ClientMessage;
		xev.xclient.window = window;
		xev.xclient.message_type = wm_state;
		xev.xclient.format = 32;
		xev.xclient.data.l[0] = 1;
		xev.xclient.data.l[1] = fullscreen;
		xev.xclient.data.l[2] = 0;
		XSendEvent(self->display, DefaultRootWindow(self->display), False, SubstructureNotifyMask, &xev);	
		XMapRaised(self->display, window);
  		XUnlockDisplay(self->display);
  		self->window = window;		

int
x11_fullscreen_display_width(self)
	X11_FullScreen self
	PREINIT:
		int screen;
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		screen = XDefaultScreen(self->display);
		RETVAL = DisplayWidth(self->display, screen);
	OUTPUT:
		RETVAL


int
x11_fullscreen_display_height(self)
	X11_FullScreen self
	PREINIT:
		int screen;
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		screen = XDefaultScreen(self->display);
		RETVAL = DisplayHeight(self->display, screen);
	OUTPUT:
		RETVAL

double
x11_fullscreen_pixel_aspect(self)
	X11_FullScreen self
	PREINIT:
		double res_h;
		double res_v;
		int screen;
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		screen = XDefaultScreen(self->display);
		res_h = (DisplayWidth(self->display,screen) * 1000 / DisplayWidthMM(self->display, screen));
 		res_v = (DisplayHeight(self->display,screen) * 1000 / DisplayHeightMM(self->display, screen));
		RETVAL = res_v / res_h;
	OUTPUT:
		RETVAL

void
x11_fullscreen_close(self)
	X11_FullScreen self
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
  		XLockDisplay(self->display);
  		XUnmapWindow(self->display, self->window);
  		XDestroyWindow(self->display, self->window);
 		XUnlockDisplay(self->display);
 		self->window = 0;


void
x11_fullscreen_sync(self)
	X11_FullScreen self
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		XSync(self->display, False);

void
x11_fullscreen_display_still(self,a_mrl)
	X11_FullScreen self
	char * a_mrl
	INIT:
	  int screen_width = 0;
	  int screen_height = 0;
	  XWindowAttributes windowattr;
	  Imlib_Image image;
	  int image_width = 0;
	  int image_height = 0;
	  int x = 0;
	  int y = 0;
	  float width_ratio = 0.0f;
	  float height_ratio = 0.0f;
	  int width;
	  int height;
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
  	  XLockDisplay(self->display);
	  if ( XGetWindowAttributes(self->display, self->window, &windowattr) == 0) { 
	  	croak("Failed to get window attributes"); 
	  } 
	  screen_width = windowattr.width; 
	  screen_height = windowattr.height;
	  imlib_context_set_display(self->display);
	  imlib_context_set_visual(DefaultVisual(self->display,DefaultScreen(self->display)));
	  imlib_context_set_colormap(DefaultColormap(self->display,DefaultScreen(self->display)));
	  imlib_context_set_drawable(self->window);
	  image = imlib_load_image_immediately(a_mrl);
	  if (image == NULL) {
 	   croak("Unable to load image '%s'", a_mrl);
	  }
	  imlib_context_set_image(image);
	  image_width = imlib_image_get_width();
	  image_height = imlib_image_get_height();
	  width_ratio =  (float) screen_width / (float) image_width;
	  height_ratio =  (float) screen_height / (float) image_height;
	  if ( width_ratio < height_ratio ) {
	  	height = round( image_height * width_ratio );
	  	width = screen_width;
	  	y = ( screen_height - height ) / 2;
	  }
	  else {
	  	width = round( image_width * height_ratio );
	  	height = screen_height;
	  	x = ( screen_width - width ) / 2;
	  }
	  imlib_render_image_on_drawable_at_size(x,y,width,height);
	  imlib_free_image();
 	  XUnlockDisplay(self->display);

	

void
x11_fullscreen_clear(self)
	X11_FullScreen self
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		XClearWindow(self->display, self->window);

X11_FullScreen_Event
x11_fullscreen_check_event(self, event_mask=( ExposureMask | VisibilityChangeMask ))
	X11_FullScreen self
	long event_mask
	PREINIT:
		XEvent* event;
	CODE:
		if (self->display == NULL) {
			croak("Display not initialized");
		}
		Newx( event, 1, XEvent );
		if ( ! XCheckWindowEvent(
					self->display,
					self->window,
					event_mask,
					event) ) {
                        Safefree(event);
			XSRETURN_UNDEF;
		}
		else {
			RETVAL = event;
		}
	OUTPUT:
		RETVAL


void
x11_fullscreen_DESTROY(self)
	X11_FullScreen self
	CODE:
		SvREFCNT_dec(self->display_str);
		if (self->display != NULL) {
  			XCloseDisplay(self->display);
  		}
  		Safefree(self);
		

MODULE = X11::FullScreen	PACKAGE = X11::FullScreen::Event	PREFIX=x11_fullscreen_event_

int
x11_fullscreen_event_get_type(event)
	X11_FullScreen_Event event
	CODE:
		RETVAL = event->type;
	OUTPUT:
		RETVAL

void
x11_fullscreen_event_DESTROY(event)
	X11_FullScreen_Event event
	CODE:
		Safefree(event);
