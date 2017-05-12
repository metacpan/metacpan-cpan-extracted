/*
 * Howdy.xs xs-ified from:
 * hiworld.c (which was shortened and adapted from:
 * helloworld.c in "introduction to the X window system"
 * by Oliver Jones (c) Prentice Hall Englewood Cliffs NJ.)
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>


MODULE = Howdy          PACKAGE = Howdy

int 
hiworld(argc, argv)
	int argc
	char argv

	CODE:
	# {
	Display *mydisplay;
	Window mywindow;
	GC mygc;
	XEvent myevent;
	KeySym mykey;
	XSizeHints myhint;
	int myscreen;
	unsigned long myforeground;
	unsigned long mybackground;
	int done;
	char hello[] = {"Hello World!"};
	char hi[] = {"Hi."};

	mydisplay = XOpenDisplay("");
	myscreen = DefaultScreen(mydisplay);
	mybackground = WhitePixel(mydisplay, myscreen);
	myforeground = BlackPixel(mydisplay, myscreen);
	myhint.x = 200; 
	myhint.y = 300;
	myhint.width = 300; 
	myhint.height = 200;
	myhint.flags = PPosition | PSize;

	mywindow = XCreateSimpleWindow (mydisplay,
	    DefaultRootWindow (mydisplay),
	    myhint.x, myhint.y, myhint.width, myhint.height, 
	    5, myforeground, mybackground);
	XSetStandardProperties(mydisplay, mywindow, hello, hello, 
	    None, argv, argc, &myhint);

	mygc = XCreateGC(mydisplay, mywindow, 0, 0);

	XSelectInput(mydisplay,mywindow, ButtonPressMask | KeyPressMask | ExposureMask);

	XMapRaised(mydisplay,mywindow);

	done = 0;
	while (done == 0) {
	    XNextEvent(mydisplay, &myevent);
	    switch (myevent.type) {
	        case Expose:        /* repaint window on expose events */
	        if (myevent.xexpose.count == 0)
	            XDrawImageString(myevent.xexpose.display, 
	                myevent.xexpose.window, mygc,
                        40, 50, hello, strlen(hello));
	        break;
	        case ButtonPress:   /* mouse Buttons */
	        XDrawImageString(myevent.xbutton.display, 
	                 myevent.xbutton.window, mygc,
                         myevent.xbutton.x, myevent.xbutton.y, hi, strlen(hi));
	        break;
		case KeyPress:      /* keyboard input device */
	        done = 1;
	        break;
	    } /*  switch (myevent.type) */
	} /* while (done == 0) */

	/* exit cleanup */
	XFreeGC(mydisplay, mygc);
	XDestroyWindow(mydisplay, mywindow);
	XCloseDisplay(mydisplay);
	#  exit(0);

	OUTPUT:
	RETVAL


