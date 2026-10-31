/*
 * WindowUtils.c -- Implementation of routines to manipulate windows
 *
 * Authors              : Christophe Berthuet, Alexandre Lemort
 * Creation date        : Fri oct 12 14:47:42 2007
 *
 */


#include "WindowUtils.h"



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
 * Enumwindows callback struct
 */
typedef struct {
   HWND window;
   char *windowtitle;
} EnumWindowsCallbackStruct;


/*
 * EnumWindows Callback
 */
BOOL CALLBACK SearchWindowCallback(HWND window, LPARAM userData)
{
   char windowTitle[1024];
   EnumWindowsCallbackStruct *myStruct = (EnumWindowsCallbackStruct *)userData;

   /* Get title of our window */
   GetWindowText(window, (LPSTR)windowTitle, 1024);
   
   /* Test if we have found our window */
   if (Tcl_StringMatch((const char*)windowTitle, myStruct->windowtitle)) {
      /* we have found our window */
      myStruct->window = window;
      
      /* Exit EnumWindows */
      return FALSE;
   }

   return TRUE;
}


/*
 * Retrieves the window handler of a window identified by its title
 */
HWND SearchWindowByTitle_simple(char *title, Display *display, HWND root, int depth)
{
   return FindWindow(NULL, (LPCTSTR)title);
}

HWND SearchWindowByTitle(char *title, Display *display, HWND root, int depth)
{
   EnumWindowsCallbackStruct myStruct;
   myStruct.window = NULL;
   myStruct.windowtitle = title;

   /* Try to find our window */
   EnumWindows(SearchWindowCallback, (LPARAM)&myStruct);

   /* Return result */
   return myStruct.window;
}


/*
 * Remove window decoration
 */
LONG removeWindowDecoration(HWND window)
{
   /* Get style of our window */
   LONG previousWindowStyle = GetWindowLong(window, GWL_STYLE);
   LONG windowStyle = previousWindowStyle;
  
   /* Change style */
   windowStyle &= WS_DLGFRAME;
   windowStyle &= WS_CAPTION;
   windowStyle &= WS_POPUP;
   windowStyle |= WS_CHILD;
   
   SetWindowLong(window, GWL_STYLE, windowStyle);//windowStyle);
   
   /* Apply change */
   /* NB: SetWindowPos parameters (HWND_BOTTOM, 0, 0, 100, 100) will not be applied */
   /* SWP_NOZORDER inhibits HWND_BOTTOM */
   /* SWP_NOMOVE inhibits 0, 0 */
   /* SWP_NOSIZE inhibits 100, 100 */
   /* SWP_FRAMECHANGED applies our new style */
   SetWindowPos(window, HWND_BOTTOM, 0, 0, 100, 100, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED);
   
   /* return previous style */
   return previousWindowStyle;
}


/*
 * Restore window style
 */
void restoreWindowStyle(HWND window, LONG windowStyle) 
{
   /* Restore style */
   SetWindowLong(window, GWL_STYLE, windowStyle);
   
   /* Apply change */
   /* NB: SetWindowPos parameters (HWND_BOTTOM, 0, 0, 100, 100) will not be applied */
   /* SWP_NOZORDER inhibits HWND_BOTTOM */
   /* SWP_NOMOVE inhibits 0, 0 */
   /* SWP_NOSIZE inhibits 100, 100 */
   /* SWP_FRAMECHANGED applies our new style */
   SetWindowPos(window, HWND_BOTTOM, 0, 0, 100, 100, SWP_NOMOVE|SWP_NOSIZE|SWP_NOZORDER|SWP_FRAMECHANGED);
}




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
Window SearchWindowByTitle(char* wndTitle, Display *dpy, Window wndRoot, int depth)
{
   Window wndFound = 0;

   // Variables used in the search
   Window root_return; 
   Window parent_return; 
   Window *children_return = 0 ;
   unsigned int nchildren_return = 0;
   
   char msg[255]; 
   int j = 0;

   if( XQueryTree( dpy, wndRoot, &root_return, &parent_return, &children_return, &nchildren_return) != 0 )
   {
      XTextProperty text_prop_return;
      for( j = 0; j < nchildren_return; j++ )
      {
         if( XGetWMName(dpy, children_return[j], &text_prop_return) != 0 )
         {
            if (Tcl_StringMatch(((const char *)(text_prop_return.value)), wndTitle)) 
            { 
               // Window found !!
               wndFound = children_return[j];
               break;
            }
            else
            {
               wndFound = SearchWindowByTitle(wndTitle, dpy, children_return[j], depth +  1 );
               if( wndFound != 0) 
               {
                  break;
               }
            }
         }
         else
         {
            wndFound = SearchWindowByTitle(wndTitle, dpy, children_return[j], depth +  1);
            if( wndFound != 0) 
            {
               break;
            }
         }
      }  
      XFree( children_return );
   }

   return wndFound;
}


/*
 * Get WM_STATE value of a window
 */
static int 
getWM_STATE (Display *display, Window window)
{
 int status = 0;
 long state = 0;
 static Atom aWM_STATE = 0;
 Atom actual_type = 0;
 int actual_format = 0;
 unsigned long num_ret = 0, num_left = 0;
 unsigned char *data = NULL;

 if (!aWM_STATE) {
  aWM_STATE = XInternAtom(display, "WM_STATE", False);
 }

 status = XGetWindowProperty (display, window, aWM_STATE, 0L, sizeof (long), False, aWM_STATE, &actual_type, &actual_format, &num_ret, &num_left, &data);

 /*I should point out that Success is defined as 0 in X11*/
 if ((status == Success) && (NULL != data)) {
   state = *(long *)data;
 } else {
   state = -1;
 }

 if (data) {
   XFree (data);
 }
 return state;
}


/*
 * Withdraw a window from desktop
 */
void withdrawWindowFromDesktop (Display *display, Window window, int screenNum) {
 int wm_state;

 /* Try to withdraw window */
 XWithdrawWindow (display, window, screenNum);
 XSync (display, 0);
 
 /* Test if we succeed. Otherwise, try until it works */
 while ((wm_state = getWM_STATE (display, window)) != 0 && wm_state != -1) {
  XSync (display, 0);
  XWithdrawWindow (display, window, screenNum);
 }
}




#endif /* ifdef _WIN32 */




/*
 ************************************
 *
 * Common functions
 *
 ************************************
 */


