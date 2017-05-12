/***************************************************************************
 *   X11::GUITest::record						   *
 *									   *
 *   Copyright (C) 2007 by Marc Koderer / ecos GmbH			   *
 *   mkoderer@cpan.org    						   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

/*
Code based on xneelib Version 2.06 is marked with [xneelib].
It is modified under terms of GPLv2
*/


#include <stdio.h>

#include <X11/Xproto.h>

#include <X11/Xlibint.h>  
#include <X11/Xmd.h>
#include <X11/keysym.h>
#include <X11/keysymdef.h>
#include <stdio.h>
#include <stdlib.h>
#include <X11/Xos.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xproto.h>
#include <X11/extensions/record.h>
#include <ctype.h>


#include "datastructure.h"



/*[xneelib]*/
struct data_description
{
  int   data_nr;
  char *data_name;
  char *data_descr;
};

/*[xneelib]*/
struct data_description event_field[]=
{
   {-1,NULL, ""},
   {-1,NULL, ""},
   {KeyPress,"KeyPress", "Pressing a key"}, 
   {KeyRelease,"KeyRelease", "Releasing a key"}, 
   {ButtonPress,"ButtonPress", "Pressing a button"}, 
   {ButtonRelease,"ButtonRelease", "Releasing a button"}, 
   {MotionNotify,"MotionNotify", "Moving the pointer"}, 
   {EnterNotify,"EnterNotify", ""}, 
   {LeaveNotify,"LeaveNotify", ""}, 
   {FocusIn,"FocusIn", ""}, 
   {FocusOut,"FocusOut", ""}, 
   {KeymapNotify,"KeymapNotify", ""}, 
   {Expose,"Expose", ""}, 
   {GraphicsExpose,"GraphicsExpose", ""}, 
   {NoExpose,"NoExpose", ""}, 
   {VisibilityNotify,"VisibilityNotify", ""}, 
   {CreateNotify,"CreateNotify", ""}, 
   {DestroyNotify,"DestroyNotify", ""}, 
   {UnmapNotify,"UnmapNotify", ""}, 
   {MapNotify,"MapNotify", ""}, 
   {MapRequest,"MapRequest", ""}, 
   {ReparentNotify,"ReparentNotify", ""}, 
   {ConfigureNotify,"ConfigureNotify", ""}, 
   {ConfigureRequest,"ConfigureRequest", ""}, 
   {GravityNotify,"GravityNotify", ""}, 
   {ResizeRequest,"ResizeRequest", ""}, 
   {CirculateNotify,"CirculateNotify", ""}, 
   {CirculateRequest,"CirculateRequest", ""}, 
   {PropertyNotify,"PropertyNotify", ""}, 
   {SelectionClear,"SelectionClear", ""}, 
   {SelectionRequest,"SelectionRequest", ""}, 
   {SelectionNotify,"SelectionNotify", ""}, 
   {ColormapNotify,"ColormapNotify", ""}, 
   {ClientMessage,"ClientMessage", ""}, 
   {MappingNotify,"MappingNotify", ""}, 
   {LASTEvent,"LASTEvent", ""},
   {-1,NULL, ""}
} ;

/*[xneelib]*/
struct data_description request_field[]=
{
   {-1,NULL, ""},
   {X_CreateWindow,"X_CreateWindow", "Test description"},
   {X_ChangeWindowAttributes,"X_ChangeWindowAttributes", ""},
   {X_GetWindowAttributes,"X_GetWindowAttributes", ""},
   {X_DestroyWindow,"X_DestroyWindow", ""},
   {X_DestroySubwindows,"X_DestroySubwindows", ""},
   {X_ChangeSaveSet,"X_ChangeSaveSet", ""},
   {X_ReparentWindow,"X_ReparentWindow", ""},
   {X_MapWindow,"X_MapWindow", ""},
   {X_MapSubwindows,"X_MapSubwindows", ""},
   {X_UnmapWindow,"X_UnmapWindow", ""},
   {X_UnmapSubwindows,"X_UnmapSubwindows", ""},
   {X_ConfigureWindow,"X_ConfigureWindow", ""},
   {X_CirculateWindow,"X_CirculateWindow", ""},
   {X_GetGeometry,"X_GetGeometry", ""},
   {X_QueryTree,"X_QueryTree", ""},
   {X_InternAtom,"X_InternAtom", ""},
   {X_GetAtomName,"X_GetAtomName", ""},
   {X_ChangeProperty,"X_ChangeProperty", ""},
   {X_DeleteProperty,"X_DeleteProperty", ""},
   {X_GetProperty,"X_GetProperty", ""},
   {X_ListProperties,"X_ListProperties", ""},
   {X_SetSelectionOwner,"X_SetSelectionOwner", ""},
   {X_GetSelectionOwner,"X_GetSelectionOwner", ""},
   {X_ConvertSelection,"X_ConvertSelection", ""},
   {X_SendEvent,"X_SendEvent", ""},
   {X_GrabPointer,"X_GrabPointer", ""},
   {X_UngrabPointer,"X_UngrabPointer", ""},
   {X_GrabButton,"X_GrabButton", ""},
   {X_UngrabButton,"X_UngrabButton", ""},
   {X_ChangeActivePointerGrab,"X_ChangeActivePointerGrab", ""},
   {X_GrabKeyboard,"X_GrabKeyboard", ""},
   {X_UngrabKeyboard,"X_UngrabKeyboard", ""},
   {X_GrabKey,"X_GrabKey", ""},
   {X_UngrabKey,"X_UngrabKey", ""},
   {X_AllowEvents,"X_AllowEvents", ""},
   {X_GrabServer,"X_GrabServer", ""},
   {X_UngrabServer,"X_UngrabServer", ""},
   {X_QueryPointer,"X_QueryPointer", ""},
   {X_GetMotionEvents,"X_GetMotionEvents", ""},
   {X_TranslateCoords,"X_TranslateCoords", ""},
   {X_WarpPointer,"X_WarpPointer", ""},
   {X_SetInputFocus,"X_SetInputFocus", ""},
   {X_GetInputFocus,"X_GetInputFocus", ""},
   {X_QueryKeymap,"X_QueryKeymap", ""},
   {X_OpenFont,"X_OpenFont", ""},
   {X_CloseFont,"X_CloseFont", ""},
   {X_QueryFont,"X_QueryFont", ""},
   {X_QueryTextExtents,"X_QueryTextExtents", ""},
   {X_ListFonts,"X_ListFonts", ""},
   {X_ListFontsWithInfo	,"X_ListFontsWithInfo", ""},
   {X_SetFontPath,"X_SetFontPath", ""},
   {X_GetFontPath,"X_GetFontPath", ""},
   {X_CreatePixmap,"X_CreatePixmap", ""},
   {X_FreePixmap,"X_FreePixmap", ""},
   {X_CreateGC,"X_CreateGC", ""},
   {X_ChangeGC,"X_ChangeGC", ""},
   {X_CopyGC,"X_CopyGC", ""},
   {X_SetDashes,"X_SetDashes", ""},
   {X_SetClipRectangles,"X_SetClipRectangles", ""},
   {X_FreeGC,"X_FreeGC", ""},
   {X_ClearArea,"X_ClearArea", ""},
   {X_CopyArea,"X_CopyArea", ""},
   {X_CopyPlane,"X_CopyPlane", ""},
   {X_PolyPoint,"X_PolyPoint", ""},
   {X_PolyLine,"X_PolyLine", ""},
   {X_PolySegment,"X_PolySegment", ""},
   {X_PolyRectangle,"X_PolyRectangle", ""},
   {X_PolyArc,"X_PolyArc", ""},
   {X_FillPoly,"X_FillPoly", ""},
   {X_PolyFillRectangle,"X_PolyFillRectangle", ""},
   {X_PolyFillArc,"X_PolyFillArc", ""},
   {X_PutImage,"X_PutImage", ""},
   {X_GetImage,"X_GetImage", ""},
   {X_PolyText8,"X_PolyText8", ""},
   {X_PolyText16,"X_PolyText16", ""},
   {X_ImageText8,"X_ImageText8", ""},
   {X_ImageText16,"X_ImageText16", ""},
   {X_CreateColormap,"X_CreateColormap", ""},
   {X_FreeColormap,"X_FreeColormap", ""},
   {X_CopyColormapAndFree,"X_CopyColormapAndFree", ""},
   {X_InstallColormap,"X_InstallColormap", ""},
   {X_UninstallColormap,"X_UninstallColormap", ""},
   {X_ListInstalledColormaps,"X_ListInstalledColormaps", ""},
   {X_AllocColor,"X_AllocColor", ""},
   {X_AllocNamedColor,"X_AllocNamedColor", ""},
   {X_AllocColorCells,"X_AllocColorCells", ""},
   {X_AllocColorPlanes,"X_AllocColorPlanes", ""},
   {X_FreeColors,"X_FreeColors", ""},
   {X_StoreColors,"X_StoreColors", ""},
   {X_StoreNamedColor,"X_StoreNamedColor", ""},
   {X_QueryColors,"X_QueryColors", ""},
   {X_LookupColor,"X_LookupColor", ""},
   {X_CreateCursor,"X_CreateCursor", ""},
   {X_CreateGlyphCursor,"X_CreateGlyphCursor", ""},
   {X_FreeCursor,"X_FreeCursor", ""},
   {X_RecolorCursor,"X_RecolorCursor", ""},
   {X_QueryBestSize,"X_QueryBestSize", ""},
   {X_QueryExtension,"X_QueryExtension", ""},
   {X_ListExtensions,"X_ListExtensions", ""},
   {X_ChangeKeyboardMapping,"X_ChangeKeyboardMapping", ""},
   {X_GetKeyboardMapping,"X_GetKeyboardMapping", ""},
   {X_ChangeKeyboardControl,"X_ChangeKeyboardControl", ""},
   {X_GetKeyboardControl,"X_GetKeyboardControl", ""},
   {X_Bell,"X_Bell", ""},
   {X_ChangePointerControl,"X_ChangePointerControl", ""},
   {X_GetPointerControl,"X_GetPointerControl", ""},
   {X_SetScreenSaver,"X_SetScreenSaver", ""},
   {X_GetScreenSaver,"X_GetScreenSaver", ""},
   {X_ChangeHosts,"X_ChangeHosts", ""},
   {X_ListHosts,"X_ListHosts", ""},
   {X_SetAccessControl,"X_SetAccessControl", ""},
   {X_SetCloseDownMode,"X_SetCloseDownMode", ""},
   {X_KillClient,"X_KillClient", ""},
   {X_RotateProperties	,"X_RotateProperties", ""},
   {X_ForceScreenSaver	,"X_ForceScreenSaver", ""},
   {X_SetPointerMapping,"X_SetPointerMapping", ""},
   {X_GetPointerMapping,"X_GetPointerMapping", ""},
   {X_SetModifierMapping	,"X_SetModifierMapping", ""},
   {X_GetModifierMapping	,"X_GetModifierMapping", ""},
   {X_NoOperation,"X_NoOperation", ""},
   {-1,NULL, NULL}
};


char * 
print_request (int req)
  {
  if (req > 119 )
    {
    return 0;  
    }
  return request_field[req].data_name;
  }


char * 
print_event (int evt)
  {
  if (evt > 35 )
    {
    return 0;  
    }
  return event_field[evt].data_name;
  }

