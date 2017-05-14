/*
#    XEvent.pm - An extension to PERL to access XEvent structures.
#    Copyright (C) 1996-1997  Martin Bartlett
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <X11/X.h>
#include <X11/Xlib.h>

/*
 * This is a very simple Xsub!! It provides an extension to perl that
 * allows Perl programs read-only access to the XEvent structure. So.
 * how do they get hold of an XEvent to read? Well, they use ANOTHER
 * Perl extension that blesses pointers to XEvents into the XEventPtr
 * class. Such an extension would do that by supplying a TYPEMAP as 
 * follows:
 *
 *		XEvent *	T_PTROBJ
 *
 * and then returning XEvent pointers as appropriate to the perl program.
 * 
 * An extension that does this is the XForms extension. So, using these
 * two extensions the perl programmer can do some pretty reasonable 
 * XWindows application programming.
 *
 * So whats in this package. Well, quite simply, every method in this
 * package is named after a field in the XEvent structure. Now, anyone
 * who has seen that structure knows that it is, in fact, a union of 
 * a bunch of other structures, the only common field of which is the
 * first field, the type field.
 *
 * However, this package is written so that you don't have to know the 
 * REAL structure of the event you are interested in, you just have to
 * know the name of the field you are after. ALL XEVent fields are
 * catered for, even the wierd vector ones. ALL are returned as perl
 * scalars of various intuitively obvious types.
 *
 * For info on how to use the XEventPtr extension, see XEventPtr.pm
 *
 */

/*
 * Structure defining the layout of the contants list
 */
#define NUMCONS 87
typedef struct _const_value {
        const char * constr;
        const double conval;
} const_value;

/*
 * The constants list
 */
static const_value  constants[NUMCONS] = {

	{ "AnyModifier", AnyModifier },
	{ "Button1", Button1 },
	{ "Button1Mask", Button1Mask },
	{ "Button1MotionMask", Button1MotionMask },
	{ "Button2", Button2 },
	{ "Button2Mask", Button2Mask },
	{ "Button2MotionMask", Button2MotionMask },
	{ "Button3", Button3 },
	{ "Button3Mask", Button3Mask },
	{ "Button3MotionMask", Button3MotionMask },
	{ "Button4", Button4 },
	{ "Button4Mask", Button4Mask },
	{ "Button4MotionMask", Button4MotionMask },
	{ "Button5", Button5 },
	{ "Button5Mask", Button5Mask },
	{ "Button5MotionMask", Button5MotionMask },
	{ "ButtonMotionMask", ButtonMotionMask },
	{ "ButtonPress", ButtonPress },
	{ "ButtonPressMask", ButtonPressMask },
	{ "ButtonRelease", ButtonRelease },
	{ "ButtonReleaseMask", ButtonReleaseMask },
	{ "CirculateNotify", CirculateNotify },
	{ "CirculateRequest", CirculateRequest },
	{ "ClientMessage", ClientMessage },
	{ "ColormapChangeMask", ColormapChangeMask },
	{ "ColormapNotify", ColormapNotify },
	{ "ConfigureNotify", ConfigureNotify },
	{ "ConfigureRequest", ConfigureRequest },
	{ "ControlMapIndex", ControlMapIndex },
	{ "ControlMask", ControlMask },
	{ "CreateNotify", CreateNotify },
	{ "DestroyNotify", DestroyNotify },
	{ "EnterNotify", EnterNotify },
	{ "EnterWindowMask", EnterWindowMask },
	{ "Expose", Expose },
	{ "ExposureMask", ExposureMask },
	{ "FocusChangeMask", FocusChangeMask },
	{ "FocusIn", FocusIn },
	{ "FocusOut", FocusOut },
	{ "GraphicsExpose", GraphicsExpose },
	{ "GravityNotify", GravityNotify },
	{ "KeyPress", KeyPress },
	{ "KeyPressMask", KeyPressMask },
	{ "KeyRelease", KeyRelease },
	{ "KeyReleaseMask", KeyReleaseMask },
	{ "KeymapNotify", KeymapNotify },
	{ "KeymapStateMask", KeymapStateMask },
	{ "LASTEvent", LASTEvent },
	{ "LeaveNotify", LeaveNotify },
	{ "LeaveWindowMask", LeaveWindowMask },
	{ "LockMapIndex", LockMapIndex },
	{ "LockMask", LockMask },
	{ "MapNotify", MapNotify },
	{ "MapRequest", MapRequest },
	{ "MappingNotify", MappingNotify },
	{ "Mod1MapIndex", Mod1MapIndex },
	{ "Mod1Mask", Mod1Mask },
	{ "Mod2MapIndex", Mod2MapIndex },
	{ "Mod2Mask", Mod2Mask },
	{ "Mod3MapIndex", Mod3MapIndex },
	{ "Mod3Mask", Mod3Mask },
	{ "Mod4MapIndex", Mod4MapIndex },
	{ "Mod4Mask", Mod4Mask },
	{ "Mod5MapIndex", Mod5MapIndex },
	{ "Mod5Mask", Mod5Mask },
	{ "MotionNotify", MotionNotify },
	{ "NoEventMask", NoEventMask },
	{ "NoExpose", NoExpose },
	{ "OwnerGrabButtonMask", OwnerGrabButtonMask },
	{ "PointerMotionHintMask", PointerMotionHintMask },
	{ "PointerMotionMask", PointerMotionMask },
	{ "PropertyChangeMask", PropertyChangeMask },
	{ "PropertyNotify", PropertyNotify },
	{ "ReparentNotify", ReparentNotify },
	{ "ResizeRedirectMask", ResizeRedirectMask },
	{ "ResizeRequest", ResizeRequest },
	{ "SelectionClear", SelectionClear },
	{ "SelectionNotify", SelectionNotify },
	{ "SelectionRequest", SelectionRequest },
	{ "ShiftMapIndex", ShiftMapIndex },
	{ "ShiftMask", ShiftMask },
	{ "StructureNotifyMask", StructureNotifyMask },
	{ "SubstructureNotifyMask", SubstructureNotifyMask },
	{ "SubstructureRedirectMask", SubstructureRedirectMask },
	{ "UnmapNotify", UnmapNotify },
	{ "VisibilityChangeMask", VisibilityChangeMask },
	{ "VisibilityNotify", VisibilityNotify }
};

static double
constant(name, arg)
char *name;
int arg;
{
        int wrktop, wrkbot, wrkmid, i;

        errno = 0;
        wrktop = 0;
        wrkbot = NUMCONS-1;
        wrkmid = (NUMCONS/2)-1;
        while (wrktop < wrkmid && wrkbot > wrkmid) {
                i = strcmp(constants[wrkmid].constr, name);
                if (i == 0)
                        return constants[wrkmid].conval;
                else if (i < 0)
                        wrktop = wrkmid;
                else 
                        wrkbot = wrkmid;
                wrkmid = wrktop + ((wrkbot - wrktop) / 2);
        }

        /*
         * If we get here then we check the rest sequentially
         */

        while (wrktop <=  wrkbot) {
                if (strEQ(constants[wrktop].constr, name))
                        return constants[wrktop].conval;
                wrktop++;
        }

        errno = EINVAL;
        return 0;
}

/*
 * The obligitary not_here
 */
static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}



MODULE = X11::XEvent		PACKAGE = X11::XEvent

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg

KeySym
XKeycodeToKeysym(display,keycode,index)
	Display *	display
	KeyCode		keycode
	int		index

XEvent *
new(class)
	char *		class
	CODE:
		{

			/*
			 * This is a test method that is NOT exported by the .pm
			 */

			XEvent *	newevent;

			printf("Creating a new event in %s!!\n", class);

			newevent = (XEvent *)malloc(sizeof(XEvent));

			newevent->xconfigure.type = ConfigureNotify;
			newevent->xconfigure.serial = 2;
			newevent->xconfigure.send_event = 3;
			newevent->xconfigure.display = (Display *)4;
			newevent->xconfigure.event = 5;
			newevent->xconfigure.window = 6;
			newevent->xconfigure.x = 7;
			newevent->xconfigure.y = 8;
			newevent->xconfigure.width = 9;
			newevent->xconfigure.height = 10;
			newevent->xconfigure.border_width = 11;
			newevent->xconfigure.above = 12;
			newevent->xconfigure.override_redirect = 13;

			RETVAL = newevent;
		}
		OUTPUT:
		RETVAL

Display *
display(event)
	XEvent *	event
	CODE:
		{
			switch(event->type) {
				case  0:
					RETVAL = event->xerror.display;
					break;
				default:
					RETVAL = event->xany.display;
					break;
			}
		}
	OUTPUT:
	RETVAL

void
type(event)
	XEvent *	event
	ALIAS:
		serial = 1
		send_event = 2
		window = 3
		root = 4
		subwindow = 5
		time = 6
		x = 7
		y = 8
		x_root = 9
		y_root = 10
		state = 11
		keycode = 12
		button = 13
		is_hint = 14
		same_screen = 15
		mode = 16
		detail = 17
		focus = 18
		key_vector = 19
		width = 20
		height = 21
		count = 22
		drawable = 23
		major_code = 24
		minor_code = 25
		parent = 26
		event = 27
		border_width = 28
		override_redirect = 29
		from_configure = 30
		above = 31
		value_mask = 32
		place = 33
		atom = 34
		selection = 35
		owner = 36
		target = 37
		property = 38
		colormap = 39
		c_new = 40
		message_type = 41
		format = 42
		data = 43
		request = 44
		first_keycode = 45
		resourceid = 46
		error_code = 47
		request_code = 48
	CODE:
	{	
		ST(0) = sv_newmortal(); 
		switch (ix) {
		case 0:
			sv_setiv(ST(0), event->type);
			break;
		case 1:
			switch(event->type) {
				case  0:
					sv_setiv(ST(0), event->xerror.serial);
					break;
				default:
					sv_setiv(ST(0), event->xany.serial);
					break;
			}
			break;
		case 2:
			switch(event->type) {
				case  0:
					break;
				default:
					sv_setiv(ST(0), event->xany.send_event);
					break;
			}
			break;
		case 3:
			switch(event->type) {
				case  0:
					break;
				case  CreateNotify:
				case  DestroyNotify:
				case  UnmapNotify:
				case  MapNotify:
				case  MapRequest:
				case  ReparentNotify:
				case  ConfigureNotify:
				case  ConfigureRequest:
				case  GravityNotify:
				case  CirculateNotify:
				case  CirculateRequest:
					sv_setiv(ST(0), event->xcreatewindow.window);
					break;
				default:
					sv_setiv(ST(0), event->xany.window);
					break;
			}
			break;
		case 4:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.root);
					break;
				default:
					break;
			}
			break;
		case 5:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.subwindow);
					break;
				default:
					break;
			}
			break;
		case 6:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.time);
					break;
				case  PropertyNotify:
					sv_setiv(ST(0), event->xproperty.time);
					break;
				case  SelectionClear:
					sv_setiv(ST(0), event->xselectionclear.time);
					break;
				case  SelectionRequest:
					sv_setiv(ST(0), event->xselectionrequest.time);
					break;
				case  SelectionNotify:
					sv_setiv(ST(0), event->xselection.time);
					break;
				default:
					break;
			}
			break;
		case 7:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.x);
					break;
				case  Expose:
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xexpose.x);
					break;
				case  CreateNotify:
				case  ConfigureNotify:
				case  ConfigureRequest:
				case  GravityNotify:
					sv_setiv(ST(0), event->xcreatewindow.x);
					break;
				case  ReparentNotify:
					sv_setiv(ST(0), event->xreparent.x);
					break;
				default:
					break;
			}
			break;
		case 8:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.y);
					break;
				case  Expose:
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xexpose.y);
					break;
				case  CreateNotify:
				case  ConfigureNotify:
				case  ConfigureRequest:
				case  GravityNotify:
					sv_setiv(ST(0), event->xcreatewindow.y);
					break;
				case  ReparentNotify:
					sv_setiv(ST(0), event->xreparent.y);
					break;
				default:
					break;
			}
			break;
		case 9:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.x_root);
					break;
				default:
					break;
			}
			break;
		case 10:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xkey.y_root);
					break;
				default:
					break;
			}
			break;
		case 11:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
				case  MotionNotify:
					sv_setiv(ST(0), event->xkey.state);
					break;
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xcrossing.state);
					break;
				case  VisibilityNotify:
					sv_setiv(ST(0), event->xvisibility.state);
					break;
				case  PropertyNotify:
					sv_setiv(ST(0), event->xproperty.state);
					break;
				case  ColormapNotify:
					sv_setiv(ST(0), event->xcolormap.state);
					break;
				default:
					break;
			}
			break;
		case 12:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
					sv_setiv(ST(0), event->xkey.keycode);
					break;
				default:
					break;
			}
			break;
		case 13:
			switch(event->type) {
				case  ButtonPress:
				case  ButtonRelease:
					sv_setiv(ST(0), event->xbutton.button);
					break;
				default:
					break;
			}
			break;
		case 14:
			switch(event->type) {
				case  MotionNotify:
					sv_setpvn(ST(0), &event->xmotion.is_hint, 1);
					break;
				default:
					break;
			}
			break;
		case 15:
			switch(event->type) {
				case  KeyPress:
				case  KeyRelease:
				case  ButtonPress:
				case  ButtonRelease:
					sv_setiv(ST(0), event->xkey.same_screen);
					break;
				case  MotionNotify:
					sv_setiv(ST(0), event->xmotion.same_screen);
					break;
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xcrossing.same_screen);
					break;
				default:
					break;
			}
			break;
		case 16:
			switch(event->type) {
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xcrossing.mode);
					break;
				case  FocusIn:
				case  FocusOut:
					sv_setiv(ST(0), event->xfocus.mode);
					break;
				default:
					break;
			}
			break;
		case 17:
			switch(event->type) {
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xcrossing.detail);
					break;
				case  FocusIn:
				case  FocusOut:
					sv_setiv(ST(0), event->xfocus.detail);
					break;
				case  ConfigureRequest:
					sv_setiv(ST(0), event->xconfigurerequest.detail);
					break;
				default:
					break;
			}
			break;
		case 18:
			switch(event->type) {
				case  EnterNotify:
				case  LeaveNotify:
					sv_setiv(ST(0), event->xcrossing.focus);
					break;
				default:
					break;
			}
			break;
		case 19:
			switch(event->type) {
				case  KeymapNotify:
					sv_setpvn(ST(0), event->xkeymap.key_vector, 32);
					break;
				default:
					break;
			}
			break;
		case 20:
			switch(event->type) {
				case  Expose:
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xexpose.width);
					break;
				case  CreateNotify:
					sv_setiv(ST(0), event->xcreatewindow.width);
					break;
				case  ConfigureNotify:
				case  ConfigureRequest:
					sv_setiv(ST(0), event->xconfigure.width);
					break;
				case  ResizeRequest:
					sv_setiv(ST(0), event->xresizerequest.width);
					break;
				default:
					break;
			}
			break;
		case 21:
			switch(event->type) {
				case  Expose:
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xexpose.height);
					break;
				case  CreateNotify:
					sv_setiv(ST(0), event->xcreatewindow.height);
					break;
				case  ConfigureNotify:
				case  ConfigureRequest:
					sv_setiv(ST(0), event->xconfigure.height);
					break;
				case  ResizeRequest:
					sv_setiv(ST(0), event->xresizerequest.height);
					break;
				default:
					break;
			}
			break;
		case 22:
			switch(event->type) {
				case  Expose :
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xexpose.count);
					break;
				case  MappingNotify:
					sv_setiv(ST(0), event->xmapping.count);
					break;
				default:
					break;
			}
			break;
		case 23:
			switch(event->type) {
				case  GraphicsExpose:
				case  NoExpose:
					sv_setiv(ST(0), event->xgraphicsexpose.drawable);
					break;
				default:
					break;
			}
			break;
		case 24:
			switch(event->type) {
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xgraphicsexpose.major_code);
					break;
				case  NoExpose:
					sv_setiv(ST(0), event->xnoexpose.major_code);
					break;
				default:
					break;
			}
			break;
		case 25:
			switch(event->type) {
				case  0:
					sv_setpvn(ST(0), (char *)&event->xerror.minor_code, 1);
					break;
				case  GraphicsExpose:
					sv_setiv(ST(0), event->xgraphicsexpose.minor_code);
					break;
				case  NoExpose:
					sv_setiv(ST(0), event->xnoexpose.minor_code);
					break;
				default:
					break;
			}
			break;
		case 26:
			switch(event->type) {
				case  CreateNotify:
				case  ConfigureRequest:
				case  CirculateRequest:
					sv_setiv(ST(0), event->xcreatewindow.parent);
					break;
				case  MapRequest:
					sv_setiv(ST(0), event->xmaprequest.parent);
					break;
				case  ReparentNotify:
					sv_setiv(ST(0), event->xreparent.parent);
					break;
				default:
					break;
			}
			break;
		case 27:
			switch(event->type) {
				case  DestroyNotify:
				case  UnmapNotify:
				case  MapNotify:
				case  ReparentNotify:
				case  ConfigureNotify:
				case  GravityNotify:
				case  CirculateNotify:
					sv_setiv(ST(0), event->xdestroywindow.event);
					break;
				default:
					break;
			}
			break;
		case 28:
			switch(event->type) {
				case  CreateNotify:
				case  ConfigureNotify:
				case  ConfigureRequest:
					sv_setiv(ST(0), event->xcreatewindow.border_width);
					break;
				default:
					break;
			}
			break;
		case 29:
			switch(event->type) {
				case  CreateNotify:
					sv_setiv(ST(0), event->xcreatewindow.override_redirect);
					break;
				case  ConfigureNotify:
					sv_setiv(ST(0), event->xconfigure.override_redirect);
					break;
				case  MapNotify:
					sv_setiv(ST(0), event->xmap.override_redirect);
					break;
				case  ReparentNotify:
					sv_setiv(ST(0), event->xreparent.override_redirect);
					break;
				default:
					break;
			}
			break;
		case 30:
			switch(event->type) {
				case  UnmapNotify:
					sv_setiv(ST(0), event->xunmap.from_configure);
					break;
				default:
					break;
			}
			break;
		case 31:
			switch(event->type) {
				case  ConfigureNotify:
				case  ConfigureRequest:
					sv_setiv(ST(0), event->xconfigure.above);
					break;
				default:
					break;
			}
			break;
		case 32:
			switch(event->type) {
				case  ConfigureRequest:
					sv_setiv(ST(0), event->xconfigurerequest.value_mask);
					break;
				default:
					break;
			}
			break;
		case 33:
			switch(event->type) {
				case  CirculateNotify:
				case  CirculateRequest:
					sv_setiv(ST(0), event->xcirculate.place);
					break;
				default:
					break;
			}
			break;
		case 34:
			switch(event->type) {
				case  PropertyNotify:
					sv_setiv(ST(0), event->xproperty.atom);
					break;
				default:
					break;
			}
			break;
		case 35:
			switch(event->type) {
				case  SelectionClear:
					sv_setiv(ST(0), event->xselectionclear.selection);
					break;
				case  SelectionRequest:
					sv_setiv(ST(0), event->xselectionrequest.selection);
					break;
				case  SelectionNotify:
					sv_setiv(ST(0), event->xselection.selection);
					break;
				default:
					break;
			}
			break;
		case 36:
			switch(event->type) {
				case  SelectionRequest:
					sv_setiv(ST(0), event->xselectionrequest.owner);
					break;
				default:
					break;
			}
			break;
		case 37:
			switch(event->type) {
				case  SelectionRequest:
					sv_setiv(ST(0), event->xselectionrequest.target);
					break;
				case  SelectionNotify:
					sv_setiv(ST(0), event->xselection.target);
					break;
				default:
					break;
			}
			break;
		case 38:
			switch(event->type) {
				case  SelectionRequest:
					sv_setiv(ST(0), event->xselectionrequest.property);
					break;
				case  SelectionNotify:
					sv_setiv(ST(0), event->xselection.property);
					break;
				default:
					break;
			}
			break;
		case 39:
			switch(event->type) {
				case  ColormapNotify:
					sv_setiv(ST(0), event->xcolormap.colormap);
					break;
				default:
					break;
			}
			break;
		case 40:
			switch(event->type) {
				case  ColormapNotify:
					sv_setiv(ST(0), event->xcolormap.new);
					break;
				default:
					break;
			}
			break;
		case 41:
			switch(event->type) {
				case  ClientMessage:
					sv_setiv(ST(0), event->xclient.message_type);
					break;
				default:
					break;
			}
			break;
		case 42:
			switch(event->type) {
				case  ClientMessage:
					sv_setiv(ST(0), event->xclient.format);
					break;
				default:
					break;
			}
			break;
		case 43:
			switch(event->type) {
				case  ClientMessage:
					sv_setpvn(ST(0), event->xclient.data.b, 20);
					break;
				default:
					break;
			}
			break;
		case 44:
			switch(event->type) {
				case  ClientMessage:
					sv_setiv(ST(0), event->xmapping.request);
					break;
				default:
					break;
			}
			break;
		case 45:
			switch(event->type) {
				case  ClientMessage:
					sv_setiv(ST(0), event->xmapping.first_keycode);
					break;
				default:
					break;
			}
			break;
		case 46:
			switch(event->type) {
				case  0:
					sv_setiv(ST(0), event->xerror.resourceid);
					break;
				default:
					break;
			}
			break;
		case 47:
			switch(event->type) {
				case  0:
					sv_setpvn(ST(0), (char *)&event->xerror.error_code, 1);
					break;
				default:
					break;
			}
			break;
		case 48:
			switch(event->type) {
				case  0:
					sv_setpvn(ST(0), (char *)&event->xerror.request_code, 1);
					break;
				default:
					break;
			}
			break;
		}
	}

