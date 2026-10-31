/*
 * WindowUtils.h -- routines to manipulate windows
 *
 * Authors              : Christophe Berthuet, Alexandre Lemort
 * Creation date        : Fri oct 12 14:47:42 2007
 *
 */


#include "tkZinc.h"


#ifdef _WIN32
/* Windows */
#include <windows.h>

#else
/* Linux */
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#endif /* ifdef _WIN32 */







/*
*************************************
 *
 * Platform specific functions 
 *
 *************************************
 */ 
#ifdef _WIN32

/*
 *-----------------------------------
 *
 * Win32
 *
 *-----------------------------------
 */ 

/*
 * Retrieves the window handler of a window identified by its title
 */
HWND SearchWindowByTitle(char *title, Display *display, HWND root, int depth);


/*
 * Add/remove window decoration 
 */
void restoreWindowStyle(HWND window, LONG windowStyle);
LONG removeWindowDecoration(HWND window);



#else 


/*
 *-----------------------------------
 *
 * Linux
 *
 *-----------------------------------
 */ 


/*
 * Retrieves the window handler of a window identified by its title
 */
Window SearchWindowByTitle(char *title, Display *display, Window root, int depth);


/*
 * Withdraw a window from desktop
 */
void withdrawWindowFromDesktop (Display *display, Window window, int screenNum);


#endif /* ifdef _WIN32 */




/*
 ************************************
 *
 * Common functions
 *
 ************************************
 */


