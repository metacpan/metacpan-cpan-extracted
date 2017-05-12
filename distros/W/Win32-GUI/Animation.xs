    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Animation
    #
    # $Id: Animation.xs,v 1.3 2004/03/28 15:02:22 lrocher Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Animation_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = ANIMATE_CLASS;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
}

BOOL
Animation_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if BitmaskOptionValue("-autoplay", perlcs->cs.style, ACS_AUTOPLAY)
    } else if BitmaskOptionValue("-center", perlcs->cs.style, ACS_CENTER)
    } else if BitmaskOptionValue("-transparent", perlcs->cs.style, ACS_TRANSPARENT)
    } else retval = FALSE;

    return retval;
}

void 
Animation_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Animation_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("Start",    PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Stop",     PERLWIN32GUI_NEM_CONTROL2)
    else retval = FALSE;

    return retval;
}

int
Animation_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_COMMAND ) {

        switch(HIWORD(wParam)) {
        case ACN_START:
            /*
             * (@)EVENT:Start()
             * Sent when the AVI clip has started playing.
             * (@)APPLIES_TO:Animation
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Start", -1 );
            break;
        case ACN_STOP:
            /*
             * (@)EVENT:Stop()
             * Sent when the AVI clip has stopped playing.
             * (@)APPLIES_TO:Animation
             */ 
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Stop", -1 );
            break;
        }
    }

    return PerlResult;
}

MODULE = Win32::GUI::Animation      PACKAGE = Win32::GUI::Animation

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Animation..." )

    ###########################################################################
    # (@)METHOD:Open(FILE)
    # Opens an AVI clip and displays its first frame in an animation control. 
BOOL
Open(handle,file)
    HWND handle
    char * file
CODE:
    RETVAL = Animate_Open(handle, (LPSTR) file);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:OpenEx(FILE,[INSTANCE=NULL])
    # Opens an AVI clip from a resource in a specified module and displays its first frame in an animation control.
BOOL
OpenEx(handle,file,instance=NULL)
    HWND handle
    SV * file
    HINSTANCE instance 
PREINIT:
    LPSTR name;
CODE:
    if (SvIOK(file))
      name = MAKEINTRESOURCE ((WORD ) SvIV(file));
    else if (SvPOK(file))
      name = SvPV_nolen(file);
    else
      name = NULL;

    if (name != NULL)
        RETVAL = Animate_OpenEx(handle, instance, (LPSTR) file);
    else
        RETVAL = FALSE;
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Close()
    # Closes an AVI clip and displays its first frame in an animation control
BOOL
Close(handle)
    HWND handle
CODE:
    RETVAL = Animate_Close(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Play([FROM], [TO], [REPEAT])
    # Plays an AVI clip in an animation control.     
BOOL
Play(handle,from=0,to=(UINT)-1,repeat=(UINT)-1)
    HWND handle
    UINT from
    UINT to
    UINT repeat
CODE:
    RETVAL = Animate_Play(handle, from, to, repeat);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Stop()
    # Stops playing an AVI clip in an animation control. 
BOOL
Stop(handle)
    HWND handle
CODE:
    RETVAL = Animate_Stop(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Seek(FRAME)
    # Directs an animation control to display a particular frame of an AVI clip.
BOOL
Seek(handle,frame)
    HWND handle
    UINT frame
CODE:
    RETVAL = Animate_Seek(handle, frame);
OUTPUT:
    RETVAL

