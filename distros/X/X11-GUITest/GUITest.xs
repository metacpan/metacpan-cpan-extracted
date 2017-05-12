/* X11::GUITest ($Id: GUITest.xs 239 2014-03-16 10:43:17Z ctrondlp $)
 *
 * Copyright (c) 2003-2014  Dennis K. Paulsen, All Rights Reserved.
 * Email: ctrondlp@cpan.org
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

/* Added for pre-v5.6.x Perl */
#ifndef newSVuv
#define newSVuv newSViv
#endif

#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/Xlocale.h>
#include <X11/Intrinsic.h>
#include <X11/StringDefs.h>
#include <X11/keysym.h>
#include <X11/extensions/XTest.h>
#include "Common.h"
#include "GUITest.h"
#include "KeyUtil.h"

/* File Level Variables */
static Display *TheXDisplay = NULL;
static int TheScreen = 0;
static WindowTable ChildWindows = {0};
static ULONG EventSendDelay = DEF_EVENT_SEND_DELAY;
static ULONG KeySendDelay = DEF_KEY_SEND_DELAY;
static int (*OldErrorHandler)(Display *, XErrorEvent *) = NULL;

/* Non Exported Utility Functions: */

/* Function: IgnoreBadWindow
 * Description: User defined error handler callback for X event errors.
 */
static int IgnoreBadWindow(Display *display, XErrorEvent *error)
{
	/* Ignore bad window errors here, handle elsewhere */
	if (error->error_code != BadWindow) {
		assert(NULL != OldErrorHandler);
		(*OldErrorHandler)(display, error);
	}
	/* Note: Return is ignored */
	return(0);
}

/* Function: SetupXDisplay
 * Description: Sets up our connection to the X server's display
 */
static void SetupXDisplay(void)
{
	int eventnum = 0, errornum = 0,
		majornum = 0, minornum = 0;

	/* Get Display Pointer */
	TheXDisplay = XOpenDisplay(NULL);
	if (TheXDisplay == NULL) {
		croak("X11::GUITest - This program is designed to run in X Windows!\n");
	}

	/* Ensure the XTest extension is available */
	if (!XTestQueryExtension(TheXDisplay, &eventnum, &errornum,
							 &majornum, &minornum)) {
		croak("X11::GUITest - XServer %s doesn't support the XTest extensions!\n",
			  DisplayString(TheXDisplay));
	}

	TheScreen = DefaultScreen(TheXDisplay);

	/* Discard current events in queue. */
	XSync(TheXDisplay, True);
}

/* Function: CloseXDisplay
 * Description: Closes our connection to the X server's display
 */
static void CloseXDisplay(void)
{
	if (TheXDisplay) {
		XSync(TheXDisplay, False);
		XCloseDisplay(TheXDisplay);
		TheXDisplay = NULL;
	}
}

/* Function: IsNumber
 * Description: Determines if the specified string represents a
 *              number.
 */
static BOOL IsNumber(const char *str)
{
	size_t x = 0, len = 0;

	assert(str != NULL);

	len = strlen(str);
	for (x = 0; x < len; x++) {
		if (!isdigit(str[x])) {
			return(FALSE);
		}
	}
	return(TRUE);
}

/* Function: GetRegKeySym
 * Description: Given a regular key name as a single character(i.e., a), this
 *				function obtains the appropriate keysym by calling GetKeySym().
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.  Also,
 *       on success, sym gets set to the appropriate keysym. On failure, sym
 * 		 will get set to NoSymbol.
 */
static BOOL GetRegKeySym(const char name, KeySym *sym)
{
	#define MAX_REG_KEY 2
	static char key[MAX_REG_KEY] = "";

	key[0] = name;
	key[1] = NUL;

	return( GetKeySym(key, sym) );
}

/* Function: GetKeycodeFromKeysym
 * Description: Wrapper around XKeysymToKeycode.  Supports compile-time
 *              workarounds, etc.
 */
static KeyCode GetKeycodeFromKeysym(Display *display, KeySym keysym)
{
 	KeyCode kc = XKeysymToKeycode(display, keysym);
#ifdef X11_GUITEST_ALT_L_FALLBACK_META_L
	/* Xvfb lacks XK_Alt_L; fall back to XK_Meta_L */
 	if (kc == 0 && keysym == XK_Alt_L) {
 		kc = XKeysymToKeycode(display, XK_Meta_L);
	}
#endif
	return(kc);
}

/* Function: PressKeyImp
 * Description: Presses the key for the specified keysym.  Lower-level
 * 				implementation.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 */
static BOOL PressKeyImp(KeySym sym)
{
	KeyCode kc = 0;
	BOOL retval = 0;

	kc = GetKeycodeFromKeysym(TheXDisplay, sym);
	if (kc == 0) {
		return(FALSE);
	}

	retval = (BOOL)XTestFakeKeyEvent(TheXDisplay, kc, True, EventSendDelay);

	XFlush(TheXDisplay);
	return(retval);
}

/* Function: ReleaseKeyImp
 * Description: Releases the key for the specified keysym.  Lower-level
 *			 	implementation.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 */
static BOOL ReleaseKeyImp(KeySym sym)
{
	KeyCode kc = 0;
	BOOL retval = 0;

	kc = GetKeycodeFromKeysym(TheXDisplay, sym);
	if (kc == 0) {
		return(FALSE);
	}

	retval = (BOOL)XTestFakeKeyEvent(TheXDisplay, kc, False, EventSendDelay);

	XFlush(TheXDisplay);
	return(retval);
}

/* Function: PressReleaseKeyImp
 * Description: Presses and releases the key for the specified keysym.
 * 				Also implements key send delay.  Lower-level implementation.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 */
static BOOL PressReleaseKeyImp(KeySym sym)
{
	if (!PressKeyImp(sym)) {
		return(FALSE);
	}
	if (!ReleaseKeyImp(sym)) {
		return(FALSE);
	}
	/* Possibly wait between(after) keystrokes */
	if (KeySendDelay > 0) {
		/* usleep(500 * 1000) = ~500ms */
		usleep(KeySendDelay * 1000);
	}
	return(TRUE);
}

/* Function: IsShiftNeeded
 * Description: Determines if the specified keysym needs the shift
 *				modifier.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 */
static BOOL IsShiftNeeded(KeySym sym)
{
	KeySym ksl = 0, ksu = 0, *kss = NULL;
	KeyCode kc = 0;
	int syms = 0;
	BOOL needed = FALSE;

	kc = GetKeycodeFromKeysym(TheXDisplay, sym);
	if (!kc) {
		return(FALSE);
	}

	/* kc(grave) = kss(grave, asciitilde, ) */
	kss = XGetKeyboardMapping(TheXDisplay, kc, 1, &syms);

	XConvertCase(sym, &ksl, &ksu);

	if (sym == kss[0] && (sym == ksl && sym == ksu)) {
		/* Not subject to case conversion */
		needed = FALSE;
	} else if (sym == ksl && sym != ksu) {
		/* Shift not needed */
		needed = FALSE;
	} else {
		/* Shift needed */
		needed = TRUE;
	}

	XFree(kss);
	return(needed);
}

/* Function: ProcessBraceSet
 * Description: Takes a brace set such as: {Tab}, {Tab 3},
 *				{Tab Tab a b c}, {PAUSE 500}, {PAUSE 500 Tab}, etc.
 *              and breaks it into components, then proceeds to press
 *				the appropriate keys or perform the	special functionality
 *				requested (i.e., PAUSE).  Numeric elements are used in the
 *				special functionality or simply to ensure the previous key
 *				element gets pressed the specified number of times.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 */
static BOOL ProcessBraceSet(const char *braceset, size_t *len)
{
	enum {NONE, PAUSE, KEY}; /* Various Functionalities */
	int cmd = NONE, count = 0, i = 0;
	BOOL needshift = FALSE;
	char *buffer = NULL, *endbrc = NULL, *token = NULL;
	KeySym sym = 0;

	assert(braceset != NULL);
	assert(len != NULL);

	/* Fail if there isn't a valid brace set */
	if (*braceset != '{' || !strchr(braceset, '}')) {
		return(FALSE);
	}

	/* Create backup buffer because we are using strtok */
	buffer = (char *)safemalloc(strlen(braceset));
	if (buffer == NULL) {
		return(FALSE);
	}
	/* Ignore beginning { char */
	strcpy(buffer, &braceset[1]);

	/* Get brace end in buffer */
	endbrc = strchr(buffer, '}');
	if (endbrc == NULL) {
		safefree(buffer);
		return(FALSE);
	}
	/* If we have a quoted }, move over one character */
	if (endbrc[1] == '}') {
		endbrc++;
	}
	/* Terminate brace set */
	*endbrc = NUL;

	/* Store brace set length for calling function.  Include
	 * 2 for {} we ignored */
	*len = strlen(buffer) + 2;

	/* Work on the space delimited items in the buffer. */
	if ( !(token = strtok(buffer, " ")) ) {
		safefree(buffer);
		return(FALSE);
	}

	do { /* } while ( (token = strtok(NULL, " ")) ); */
		count = 0;
		if (IsNumber(token)) {
			/* Yes, a number, so convert it for key depresses or for command specific use */
			if ( (count = atoi(token)) <= 0 ) {
				safefree(buffer);
				return(FALSE);
			}
		} else {
			cmd = NONE;
			/* Special functionality? */
			if (strcasecmp(token, "PAUSE") == 0) {
				/* Yes, PAUSE, so continue on to get the duration count */
				cmd = PAUSE;
				continue;
			} else {
				/* No, just a key, so get symbol */
				cmd = KEY;
				if (!GetKeySym(token, &sym)) {
					safefree(buffer);
					return(FALSE);
				}
				needshift = IsShiftNeeded(sym);
				if (needshift) {
					PressKeyImp(XK_Shift_L);
				}
				/* Press key */
				if (!PressReleaseKeyImp(sym)) {
					if (needshift) {
						ReleaseKeyImp(XK_Shift_L);
					}
					safefree(buffer);
					return(FALSE);
				}
				if (needshift) {
					ReleaseKeyImp(XK_Shift_L);
				}
			}
		}
		/* Handle commands that can use a specified count */
		if (count > 0) {
			switch (cmd) {
			case PAUSE:
				/* usleep(500 * 1000) = 500ms */
				usleep(count * 1000);
				break;
			case KEY:
				/* Repeat the last key if needed.  Start at iteration 2
				 * because we have already depressed key once up above */
				/* Use shift if needed */
				if (needshift) {
					PressKeyImp(XK_Shift_L);
				}
				for (i = 2; i <= count; i++) {
					/* Use sym that was already stored from above */
					if (!PressReleaseKeyImp(sym)) {
						if (needshift) {
							ReleaseKeyImp(XK_Shift_L);
						}
						safefree(buffer);
						return(FALSE);
					}
				}
				if (needshift) {
					ReleaseKeyImp(XK_Shift_L);
				}
				break;
			default:
				/* Fail, we have a count, but an unknown command! */
				safefree(buffer);
				return(FALSE);
			}; /* switch (cmd) { */
		} /* if (count > 0) { */
	} while ( (token = strtok(NULL, " ")) );

	safefree(buffer);
	return(TRUE);
}

/* Function: SendKeysImp
 * Description: Underlying implementation of the SendKeys routine.  Read
 * 				the SendKeys documentation below for some specifics.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 *       Also, if you add special character handling below, also ensure
 * 		 the QuoteStringForSendKeys function is accurate in GUITest.pm.
 */
static BOOL SendKeysImp(const char *keys)
{
	KeySym sym = 0;
	size_t keyslen = 0, bracelen = 0;
	size_t x = 0;
	BOOL retval = FALSE, shift = FALSE, ctrl = FALSE, altgr = FALSE,
		 alt = FALSE, meta = FALSE, modlock = FALSE, needshift = FALSE;

	assert(keys != NULL);

	keyslen = strlen(keys);
	for (x = 0; x < keyslen; x++) {
		switch (keys[x]) {
		/* Brace Set? of quoted/special characters (i.e. {{}, {TAB}, {F1 F2}, {PAUSE 200}) */
		case '{':
			if (!ProcessBraceSet(&keys[x], &bracelen)) {
				return(FALSE);
			}
			/* Skip past the brace set, Note: - 1 because we are at { already */
			x += (bracelen - 1);
			continue;
		/* Modifiers? */
		case '~': retval = PressReleaseKeyImp(XK_Return); break;
		case '+': /* Shift */
			retval = PressKeyImp(XK_Shift_L);
			shift = TRUE;
			break;
		case '^':  /* Control */
			retval = PressKeyImp(XK_Control_L);
			ctrl = TRUE;
			break;
		case '%': /* Alt */
			retval = PressKeyImp(XK_Alt_L);
			alt = TRUE;
			break;
		case '#': /* Meta */
			retval = PressKeyImp(XK_Meta_L);
			meta = TRUE;
			break;
		case '&': /* AltGr */
			retval = PressKeyImp(XK_ISO_Level3_Shift);
			altgr = TRUE;
			break;
		case '(': modlock = TRUE; break;
		case ')': modlock = FALSE; break;
		/* Regular Key? (a, b, c, 1, 2, 3, _, *, %), etc. */
		default:
			if (!GetRegKeySym(keys[x], &sym)) {
				return(FALSE);
			}
			/* Use shift if needed */
			needshift = IsShiftNeeded(sym);
			if (!shift && needshift) {
				PressKeyImp(XK_Shift_L);
			}
			retval = PressReleaseKeyImp(sym);
			/* Release shift if needed */
			if (!shift && needshift) {
				ReleaseKeyImp(XK_Shift_L);
			}
			break;
		}; /* switch (keys[x]) { */
		/* If modlock coming up next, go on to process it */
		if (keys[x + 1] == '(') {
			continue;
		}
		/* Ensure modifiers are clear when needed */
		if (!modlock) {
			if (shift) {
				ReleaseKeyImp(XK_Shift_L);
				shift = FALSE;
			}
			if (ctrl) {
				ReleaseKeyImp(XK_Control_L);
				ctrl = FALSE;
			}
			if (alt) {
				ReleaseKeyImp(XK_Alt_L);
				alt = FALSE;
			}
			if (meta) {
				ReleaseKeyImp(XK_Meta_L);
				meta = FALSE;
			}
			if (altgr) {
				ReleaseKeyImp(XK_ISO_Level3_Shift);
				altgr = FALSE;
			}
		}
		if (!retval) {
			return(FALSE);
		}
	} /* for (x =  0; x < keyslen; x++) { */

	return(TRUE);
}

/* Function: IsWindowImp
 * Description: Underlying implementation of the IsWindow routine.  Read
 *				the IsWindow documentation below for some specifics.
 * Note: Returns non-zero for true, zero for false.
 */
static BOOL IsWindowImp(Window win)
{
	XWindowAttributes wattrs = {0};
	BOOL retval;

	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	retval = (BOOL)(XGetWindowAttributes(TheXDisplay, win, &wattrs) != 0);
	XSetErrorHandler(OldErrorHandler);
	return(retval);
}

/* Function: AddChildWindow
 * Description: Adds the specified window Id to the internally managed
 *				table of available window Ids.  Also handles the memory
 *				allocation for this table.
 * Note: Returns TRUE (non-zero) on success, FALSE (zero) on failure.
 */
static BOOL AddChildWindow(Window win)
{
	enum {INIT = 1, GROW = 2}; /* Memory Allocation */

	if (!win) {
		return(FALSE);
	}

	if (ChildWindows.Ids == NULL) {
		/* Initialize */
		ChildWindows.Ids = (Window *)safemalloc(INIT * sizeof(Window));
		if (ChildWindows.Ids == NULL) {
			return(FALSE);
		}
		ChildWindows.Max = INIT;
		ChildWindows.NVals = 0;
	} else if (ChildWindows.NVals >= ChildWindows.Max) {
		/* Grow */
		/* Note: Did not use [insert fancy algorythm name here] algorythm here on purpose */
		Window *TempIds = NULL;
		TempIds = (Window *)saferealloc(ChildWindows.Ids,
						(GROW * ChildWindows.Max) * sizeof(Window));
		if (TempIds == NULL) {
			return(FALSE);
		}
		ChildWindows.Max *= GROW;
		ChildWindows.Ids = TempIds;
	}
	/* Place the new window Id in */
	ChildWindows.Ids[ChildWindows.NVals] = win;
	ChildWindows.NVals++;

	return(TRUE);
}

/* Function: ClearChildWindows
 * Description: Clears the table of window Ids.  Memory allocated
 *				in AddChildWindow is not freed here, because
 *				we'll probably want to take advantage of it again.
 * Note: No return value.
 */
static void ClearChildWindows(void)
{
	if (ChildWindows.Ids) {
		memset(ChildWindows.Ids, 0, ChildWindows.Max * sizeof(Window));
	}
	ChildWindows.NVals = 0;
}

/* Function: FreeChildWindows
 * Description: Deallocates the memory of the window Id table
 * 				that was allocated through AddChildWindow.  This
 *				should be called on exit.
 * Note: No return value.
 */
static void FreeChildWindows(void)
{
	if (ChildWindows.Ids) {
		safefree(ChildWindows.Ids);
		ChildWindows.Ids = NULL;
	}
	ChildWindows.NVals = 0;
	ChildWindows.Max = 0;
}

/* Function: EnumChildWindowsAux
 * Description: Obtains the list of window Ids
 * Note: Returns value indicating success of obtaining
 *       windows.
 */
static BOOL EnumChildWindowsAux(Window win)
{
   	Window root = 0, parent = 0, *children = NULL;
   	UINT childcount = 0;
	UINT i = 0;

	/* get list of child windows */
	if (XQueryTree(TheXDisplay, win, &root, &parent, &children,
				   &childcount)) {
	   	for (i = 0; i < childcount; i++) {
			/* Add Child */
			AddChildWindow(children[i]);
			/* Look for its descendents */
	   		if (!EnumChildWindowsAux(children[i])) {
				XFree(children);
				return FALSE;
			}
   		}
   		if (children) {
       		XFree(children);
   		}
		return TRUE;
	} else {
		return FALSE;
	}
}

/* Function: EnumChildWindows
 * Description: Calls utility function to obtain list of window
 *              Ids.  Helps handle window transitions.
 * Note: Returns nothing.
 */
static void EnumChildWindows(Window win)
{
	BOOL success = 0;

	for (;;) {
		if (!IsWindowImp(win)) {
			return;
		}

		OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
		success = EnumChildWindowsAux(win);
		XSetErrorHandler(OldErrorHandler);
		if (success) {
			return;
		}
		/* Failure: try again, in 1/2 second. */
		ClearChildWindows();
		usleep(500000); /* 500000 = 1/2 second */
	}
}


MODULE = X11::GUITest			PACKAGE = X11::GUITest
PROTOTYPES: DISABLE

void
InitGUITest()
PPCODE:
	/* Things to do on initialization */
	SetupXDisplay();
	XTestGrabControl(TheXDisplay, True);
	XSRETURN(0);

void
DeInitGUITest()
PPCODE:
	/* Things to do on deinitialization */
	CloseXDisplay();
	FreeChildWindows();
	XSRETURN(0);


int
DefaultScreen()
CODE:
	RETVAL = TheScreen;
OUTPUT:
	RETVAL


int
ScreenCount()
CODE:
	RETVAL = ScreenCount(TheXDisplay);
OUTPUT:
	RETVAL


ULONG
SetEventSendDelay(delay)
	ULONG delay
CODE:
	/* Returning old delay amount */
	RETVAL = EventSendDelay;
	EventSendDelay = delay;
OUTPUT:
	RETVAL


ULONG
GetEventSendDelay()
CODE:
	RETVAL = EventSendDelay;
OUTPUT:
	RETVAL


ULONG
SetKeySendDelay(delay)
	ULONG delay
CODE:
	/* Returning old delay amount */
	RETVAL = KeySendDelay;
	KeySendDelay = delay;
OUTPUT:
	RETVAL


ULONG
GetKeySendDelay()
CODE:
	RETVAL = KeySendDelay;
OUTPUT:
	RETVAL


SV *
GetWindowName(win)
	Window win
PREINIT:
	char *name = NULL;
	XTextProperty wm_name = {0};
	Atom wm_name_prop = None;
CODE:
	RETVAL = &PL_sv_undef;
	if (IsWindowImp(win)) {
		if (XFetchName(TheXDisplay, win, &name)) {
			RETVAL = newSVpv(name, strlen(name));
			XFree(name);
		} else {
			wm_name_prop = XInternAtom(TheXDisplay, "_NET_WM_NAME", False);
			if (wm_name_prop != None) {
				if (XGetTextProperty(TheXDisplay, win, &wm_name, wm_name_prop)) {
					RETVAL = newSVpv((char *)wm_name.value, strlen((char *)wm_name.value));
					XFree(wm_name.value);
				}
			}
		}
	}
OUTPUT:
	RETVAL


BOOL
SetWindowName(win, name)
	Window win
	char *name
PREINIT:
	XTextProperty textprop = {0};
	size_t namelen = 0;
	Atom utf8_string = 0;
	Atom net_wm_name = 0;
	Atom net_wm_icon_name = 0;
CODE:
	RETVAL = FALSE;
	if (IsWindowImp(win)) {
		if (XStringListToTextProperty(&name, 1, &textprop)) {
			XSetWMName(TheXDisplay, win, &textprop);
			XSetWMIconName(TheXDisplay, win, &textprop);
			XFree(textprop.value);
			RETVAL = TRUE;
		}
		/* These UTF8 window name properties can be the properties
		 * that get displayed, so we set them too. */
		utf8_string = XInternAtom(TheXDisplay, "UTF8_STRING", True);
		if (utf8_string != None) {
			net_wm_name = XInternAtom(TheXDisplay, "_NET_WM_NAME", True);
			net_wm_icon_name = XInternAtom(TheXDisplay, "_NET_WM_ICON_NAME", True);
			if (net_wm_name != None && net_wm_icon_name != None) {
				namelen = strlen(name);
				XChangeProperty(TheXDisplay, win, net_wm_name, utf8_string, 8,
								PropModeReplace, (unsigned char *)name, namelen);
				XChangeProperty(TheXDisplay, win, net_wm_icon_name, utf8_string, 8,
								PropModeReplace, (unsigned char *)name, namelen);
			}
		}
	}
OUTPUT:
	RETVAL


Window
GetRootWindow(scr_num = NO_INIT)
	int scr_num
CODE:
	if (0 == items)
		scr_num = TheScreen;
	if (scr_num >= 0 && scr_num < ScreenCount(TheXDisplay))
		RETVAL = RootWindow(TheXDisplay, scr_num);
	else
		RETVAL = None;
OUTPUT:
	RETVAL


void
GetChildWindows(win)
	Window win
PREINIT:
	UINT i = 0;
PPCODE:
	EnumChildWindows(win);
	EXTEND(SP, (int)ChildWindows.NVals);
	for (i = 0; i < ChildWindows.NVals; i++) {
		PUSHs(sv_2mortal(newSVuv((UV)ChildWindows.Ids[i])));
	}
	ClearChildWindows();
	XSRETURN(i);


BOOL
MoveMouseAbs(x, y, scr_num = NO_INIT)
	int x
	int y
	int scr_num
CODE:
	if (items < 3)
		scr_num = TheScreen;
	if (scr_num >= 0 && scr_num < ScreenCount(TheXDisplay)) {
#ifndef X11_GUITEST_USING_XINERAMA
		RETVAL = (BOOL)XTestFakeMotionEvent(TheXDisplay, scr_num, x, y,
						    EventSendDelay);
		XFlush(TheXDisplay);
#else
		ULONG tmp;

		    /* I decided not to set our error handler, since the
		       window must exist. */
		XWarpPointer(TheXDisplay, None,
			     RootWindow(TheXDisplay, scr_num),
			     0, 0, 0, 0,
			     x, y);
		XSync(TheXDisplay, False);
		tmp = EventSendDelay / (ULONG) 1000;
		while ((ULONG) 0 != tmp)
			tmp = (ULONG) sleep((int) tmp);
		tmp = EventSendDelay % (ULONG) 1000;
		usleep(1000 * tmp);
#endif
		RETVAL = (BOOL) 1;
	} else {
		RETVAL = (BOOL) 0;
	}
OUTPUT:
	RETVAL


void
GetMousePos()
PREINIT:
	Window root = 0, child = 0;
	int root_x = 0, root_y = 0;
	int win_x = 0, win_y = 0, scr_num = 0;
	UINT mask = 0;
PPCODE:
		/* We do not bother to set our error handler because the
		   window given has to exist. */
	XQueryPointer(TheXDisplay, RootWindow(TheXDisplay, TheScreen),
		      &root, &child, &root_x, &root_y, &win_x, &win_y, &mask);
	EXTEND(SP, 3);
	PUSHs( sv_2mortal(newSViv((IV)root_x)) );
	PUSHs( sv_2mortal(newSViv((IV)root_y)) );
	for (scr_num = ScreenCount(TheXDisplay) - 1; scr_num >= 0 ; --scr_num)
	{
		if (root == RootWindow(TheXDisplay, scr_num)) {
			break;
		}
		assert(0 != scr_num);
		/* There is something really wrong with the Xlib data
		   if this "assert" fails. */
	}
	PUSHs( sv_2mortal(newSViv((IV)scr_num)) );
	XSRETURN(3);


BOOL
PressMouseButton(button)
	int button
CODE:
	RETVAL = (BOOL)XTestFakeButtonEvent(TheXDisplay, button, True, EventSendDelay);
	XFlush(TheXDisplay);
OUTPUT:
	RETVAL


BOOL
ReleaseMouseButton(button)
	int button
CODE:
	RETVAL = (BOOL)XTestFakeButtonEvent(TheXDisplay, button, False, EventSendDelay);
	XFlush(TheXDisplay);
OUTPUT:
	RETVAL


BOOL
SendKeys(keys)
	char *keys
CODE:
	RETVAL = SendKeysImp(keys);
OUTPUT:
	RETVAL


BOOL
PressKey(key)
	char *key
PREINIT:
	KeySym sym = 0;
CODE:
	RETVAL = GetKeySym(key, &sym);
	if (RETVAL) {
		RETVAL = PressKeyImp(sym);
	}
OUTPUT:
	RETVAL


BOOL
ReleaseKey(key)
	char *key
PREINIT:
	KeySym sym = 0;
CODE:
	RETVAL = GetKeySym(key, &sym);
	if (RETVAL) {
		RETVAL = ReleaseKeyImp(sym);
	}
OUTPUT:
	RETVAL


BOOL
PressReleaseKey(key)
	char *key
PREINIT:
	KeySym sym = 0;
CODE:
	RETVAL = GetKeySym(key, &sym);
	if (RETVAL) {
		RETVAL = PressReleaseKeyImp(sym);
	}
OUTPUT:
	RETVAL


BOOL
IsKeyPressed(key)
	char *key
PREINIT:
	int pos = 0;
	KeySym sym = 0;
	KeyCode kc = 0, skc = 0;
	BOOL keyon = FALSE, shifton = FALSE;
	char keys_return[KEYMAP_VECTOR_SIZE] = "";
CODE:
	if (key && GetKeySym(key, &sym)) {
		kc = GetKeycodeFromKeysym(TheXDisplay, sym);
		skc = GetKeycodeFromKeysym(TheXDisplay, XK_Shift_L);
		XQueryKeymap(TheXDisplay, keys_return);
		for (pos = 0; pos < (KEYMAP_VECTOR_SIZE * KEYMAP_BIT_COUNT); pos++) {
			/* For the derived keycode, are we at the correct bit position for it? */
			if (kc == pos) {
				/* Check the bit at this position to determine the state of the key */
				if ( keys_return[pos / KEYMAP_BIT_COUNT] & (1 << (pos % KEYMAP_BIT_COUNT)) ) {
					/* Bit On, so key is pressed */
					keyon = TRUE;
				}
			}
			/* For the shift keycode, ... */
			if (skc == pos) {
				/* Check the bit at this position to determine the state of the shift key */
				if ( keys_return[pos / KEYMAP_BIT_COUNT] & (1 << (pos % KEYMAP_BIT_COUNT)) ) {
					/* Bit On, so shift is pressed */
					shifton = TRUE;
				}
			}
		} /* for (pos = 0; pos < (KEYMAP_VECTOR_SIZE * KEYMAP_BIT_COUNT); pos++) { */
	} /* if (key && GetKeySym(key, &sym)) { */

	/* Determine result */
	if (keyon) {
		/* Key is on, so use its keysym to determine if shift modifier needs to be verified also */
		if (IsShiftNeeded(sym)) {
			RETVAL = (shifton);
		} else {
			RETVAL = (!shifton);
		}
	} else {
		/* Key not on, so it is not pressed */
		RETVAL = FALSE;
	}
OUTPUT:
	RETVAL


BOOL
IsMouseButtonPressed(button)
	int button
PREINIT:
	Window root = 0, child = 0;
	int root_x = 0, root_y = 0;
	int win_x = 0, win_y = 0;
	UINT mask = 0;
CODE:
	XQueryPointer(TheXDisplay, RootWindow(TheXDisplay, TheScreen),
				  &root, &child, &root_x, &root_y,
				  &win_x, &win_y, &mask);
	switch (button) {
	case Button1:
		RETVAL = (mask & Button1Mask);
		break;
	case Button2:
		RETVAL = (mask & Button2Mask);
		break;
	case Button3:
		RETVAL = (mask & Button3Mask);
		break;
	case Button4:
		RETVAL = (mask & Button4Mask);
		break;
	case Button5:
		RETVAL = (mask & Button5Mask);
		break;
	default:
		RETVAL = FALSE;
		break;
	};
OUTPUT:
	RETVAL

BOOL
IsWindowCursor(win, cursor)
	Window win
	Cursor cursor
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	RETVAL = XTestCompareCursorWithWindow(TheXDisplay, win, cursor);
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL

BOOL
IsWindow(win)
	Window win
CODE:
	RETVAL = IsWindowImp(win);
OUTPUT:
	RETVAL


BOOL
IsWindowViewable(win)
	Window win
PREINIT:
	XWindowAttributes wattrs = {0};
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	if (!XGetWindowAttributes(TheXDisplay, win, &wattrs)) {
		RETVAL = FALSE;
	} else {
		RETVAL = (wattrs.map_state == IsViewable);
	}
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


BOOL
MoveWindow(win, x, y)
	Window win
	int x
	int y
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	RETVAL = XMoveWindow(TheXDisplay, win, x, y);
	XSync(TheXDisplay, False);
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


BOOL
ResizeWindow(win, w, h)
	Window win
	int w
	int h
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	RETVAL = XResizeWindow(TheXDisplay, win, w, h);
	XSync(TheXDisplay, False);
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


BOOL
IconifyWindow(win)
	Window win
PREINIT:
	XWindowAttributes wattrs = {0};
	int scr_num;
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	if (XGetWindowAttributes(TheXDisplay, win, &wattrs)) {
		for (scr_num = ScreenCount(TheXDisplay) - 1;
		     scr_num >= 0 ; --scr_num)
		{
			if ( wattrs.screen
			  == ScreenOfDisplay(TheXDisplay, scr_num))
			{
				break;
			}
			/* There is something really wrong with the Xlib data
			   if this "assert" fails. */
			assert(0 != scr_num);
		}
		RETVAL = XIconifyWindow(TheXDisplay, win, scr_num);
		XSync(TheXDisplay, False);
	} else {
		RETVAL = (BOOL) 0;
	}
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


BOOL
UnIconifyWindow(win)
	Window win
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	RETVAL = XMapWindow(TheXDisplay, win);
	XSync(TheXDisplay, False);
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


BOOL
RaiseWindow(win)
	Window win
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	RETVAL = XRaiseWindow(TheXDisplay, win);
	XSync(TheXDisplay, False);
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


BOOL
LowerWindow(win)
	Window win
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	RETVAL = XLowerWindow(TheXDisplay, win);
	XSync(TheXDisplay, False);
	XSetErrorHandler(OldErrorHandler);
OUTPUT:
	RETVAL


Window
GetInputFocus()
PREINIT:
	Window focus = 0;
	int revert = 0;
CODE:
	XGetInputFocus(TheXDisplay, &focus, &revert);
	RETVAL = focus;
OUTPUT:
	RETVAL


BOOL
SetInputFocus(win)
	Window win
PREINIT:
	Window focus = 0;
	int revert = 0;
CODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	/* Note: Per function man page, there is no effect if the time parameter
	 *  	 of this call isn't accurate.  Will use CurrentTime.  Also, it
	 *		 appears that we can't trust its return value. */
	XSetInputFocus(TheXDisplay, win, RevertToParent, CurrentTime);
	XSync(TheXDisplay, False);
	XSetErrorHandler(OldErrorHandler);
	/* Verify that the window now has focus.  Used to determine return value */
	XGetInputFocus(TheXDisplay, &focus, &revert);
	RETVAL = (focus == win);
OUTPUT:
	RETVAL


void
GetWindowPos(win)
	Window win
PREINIT:
	XWindowAttributes wattrs = {0};
	Window child = 0;
	int num_ret = 0, x = 0, y = 0, scr_num;
PPCODE:
	OldErrorHandler = XSetErrorHandler(IgnoreBadWindow);
	if (XGetWindowAttributes(TheXDisplay, win, &wattrs)) {
		XTranslateCoordinates(TheXDisplay, win, wattrs.root,
			0 - wattrs.border_width, 0 - wattrs.border_width,
			&x, &y, &child);
		EXTEND(SP, 6);
		PUSHs( sv_2mortal(newSViv((IV)x)) );
		PUSHs( sv_2mortal(newSViv((IV)y)) );
		PUSHs( sv_2mortal(newSViv((IV)wattrs.width)) );
		PUSHs( sv_2mortal(newSViv((IV)wattrs.height)) );
		PUSHs( sv_2mortal(newSViv((IV)wattrs.border_width)) );
		for (scr_num = ScreenCount(TheXDisplay) - 1;
		     scr_num >= 0 ; --scr_num)
		{
			if ( wattrs.screen
			  == ScreenOfDisplay(TheXDisplay, scr_num))
			{
				break;
			}
			/* There is something really wrong with the Xlib data
			   if this "assert" fails. */
			assert(0 != scr_num);
		}
		PUSHs( sv_2mortal(newSViv((IV)scr_num)) );
		num_ret = 6;
	}
	XSetErrorHandler(OldErrorHandler);
	XSRETURN(num_ret);

Window
GetParentWindow(win)
	Window win
PREINIT:
	Window parent = 0, *children = NULL, root = 0;
	UINT childcount = 0;
CODE:
	RETVAL = 0;
	if (XQueryTree(TheXDisplay, win, &root, &parent, &children, &childcount)) {
		XFree(children);
		RETVAL = parent;
	}
OUTPUT:
	RETVAL


void
GetScreenRes(scr_num = NO_INIT)
	int scr_num
PREINIT:
	int x = 0, y = 0, num_ret = 0;
PPCODE:
	if (0 == items)
		scr_num = TheScreen;
	if (scr_num >= 0 && scr_num < ScreenCount(TheXDisplay)) {
		x = DisplayWidth(TheXDisplay, scr_num);
		y = DisplayHeight(TheXDisplay, scr_num);
		EXTEND(SP, 2);
		PUSHs( sv_2mortal(newSViv((IV)x)) );
		PUSHs( sv_2mortal(newSViv((IV)y)) );
		num_ret = 2;
	}
	XSRETURN(num_ret);

int
GetScreenDepth(scr_num = NO_INIT)
	int scr_num
CODE:
	if (0 == items)
		scr_num = TheScreen;
	if (scr_num >= 0 && scr_num < ScreenCount(TheXDisplay)) {
		RETVAL = DefaultDepth(TheXDisplay, scr_num);
	} else {
		RETVAL = -1;
	}
OUTPUT:
	RETVAL

unsigned long
GetWindowPid(win)
	Window win
PREINIT:
	Atom wm_pid_prop = None;
	Atom actual_type = None;
	int actual_format = 0;
	int status = 0;
	unsigned long nitems = 0;
	unsigned long bytes_after = 0;
	unsigned long *prop = NULL;
CODE:
	RETVAL = 0;
	wm_pid_prop = XInternAtom(TheXDisplay, "_NET_WM_PID", False);

	if (wm_pid_prop != None) {
		status = XGetWindowProperty(TheXDisplay, win, wm_pid_prop, 0,
			1, False, XA_CARDINAL, &actual_type, &actual_format,
			&nitems, &bytes_after, (unsigned char **)&prop);
		if (status == Success && actual_type != None) {
			RETVAL = *prop;
			XFree(prop);
		}
	}
OUTPUT:
	RETVAL
