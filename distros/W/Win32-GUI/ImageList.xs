    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::ImageList
    #
    # $Id: ImageList.xs,v 1.10 2006/03/16 23:14:31 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

    // TODO : Some methods is missing for MinGW

MODULE = Win32::GUI::ImageList      PACKAGE = Win32::GUI::ImageList

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::ImageList..." )

    ###########################################################################
    # (@)METHOD:AddBitmap(BITMAP, [BITMAPMASK])
    # Adds a Win32::GUI::Bitmap object to the ImageList. BITMAPMASK is
    # optional. See also Add().
int
AddBitmap(handle, bitmap, bitmapMask=NULL)
    HIMAGELIST handle
    HBITMAP bitmap
    HBITMAP bitmapMask
CODE:
    RETVAL = ImageList_Add(handle, bitmap, bitmapMask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AddBitmapMasked(BITMAP, COLORMASK)
    # Adds a Win32::GUI::Bitmap object to the ImageList. COLORMASK is
    # color used to generate the mask. See also AddMasked().
int
AddBitmapMasked(handle, bitmap, color)
    HIMAGELIST handle
    HBITMAP bitmap
    COLORREF  color
CODE:
    RETVAL = ImageList_AddMasked(handle, bitmap, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BeginDrag(INDEX, X, Y)
    # Creates a temporary image list that is used for dragging. 
BOOL
BeginDrag(handle, index, x, y)
    HIMAGELIST handle
    int index
    int x
    int y
CODE:
    RETVAL = ImageList_BeginDrag(handle, index, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:Copy(IDEST, ISRC, [FLAG=ILCF_MOVE])
    # Copies images within a image list.
BOOL
Copy(handle, iDest, iSrc, flag=ILCF_MOVE)
    HIMAGELIST handle
    int iDest
    int iSrc
    UINT flag
CODE:
    // Not supported in MinGW w32api package prior to v3.2
#ifdef W32G_BROKENW32API
    W32G_WARN_UNSUPPORTED("ImageList_Copy missing from build");
    RETVAL = FALSE;
#else
    RETVAL = ImageList_Copy(handle, iDest, handle, iSrc, flag);
#endif
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Create(X, Y, FLAGS, INITAL, GROW)
    # Creates a new image list.
    # See new()
HIMAGELIST
Create(cx,cy,flags,cInitial,cGrow)
    int cx
    int cy
    UINT flags
    int cInitial
    int cGrow
CODE:
    RETVAL = ImageList_Create(cx, cy, flags, cInitial, cGrow);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Destroy()
    # Destroys an image list.
BOOL
Destroy(handle)
    HIMAGELIST handle
CODE:
    RETVAL = ImageList_Destroy(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Draw(INDEX, DC, X, Y, [STYLE=ILD_NORMAL])
    # Draws an image list item in the specified device context.
BOOL
Draw(handle, index, dc, x, y, flag=ILD_NORMAL)
    HIMAGELIST handle
    int index
    HDC dc
    int x
    int y
    UINT flag
CODE:
    RETVAL = ImageList_Draw(handle, index, dc, x, y, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DrawEx(INDEX, DC, X, Y, DX, DY, BKCOLOR, FGCOLOR, [STYLE=ILD_NORMAL])
    # Draws an image list item in the specified device context.
    # The function uses the specified drawing style and blends the image with the specified color.
BOOL
DrawEx(handle, index, dc, x, y, dx, dy, color1, color2, flag=ILD_NORMAL)
    HIMAGELIST handle
    int index
    HDC dc
    int x
    int y
    int dx
    int dy
    COLORREF color1
    COLORREF color2
    UINT flag
CODE:
    RETVAL = ImageList_DrawEx(handle, index, dc, x, y, dx, dy, color1, color2, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DrawIndirect(INDEX, DC, X, Y, CX, CY, XBITMAP, YBITMAP, BKCOLOR, FGCOLOR, [STYLE=ILD_NORMAL], [ROP=SRCCOPY])
    # Draws an image list item in the specified device context.
BOOL
DrawIndirect(handle, index, dc, x, y, cx, cy, xBitmap, yBitmap, color1, color2, flag=ILD_NORMAL, rop=SRCCOPY)
    HIMAGELIST handle
    int index
    HDC dc
    int x
    int y
    int cx
    int cy
    int xBitmap
    int yBitmap
    COLORREF color1
    COLORREF color2
    UINT flag
    DWORD rop
PREINIT:
    IMAGELISTDRAWPARAMS param;
CODE:
    param.cbSize  = sizeof(IMAGELISTDRAWPARAMS);
    param.himl    = handle;
    param.i       = index;
    param.hdcDst  = dc;
    param.x       = x;
    param.y       = y;
    param.cx      = cx;
    param.cy      = cy;
    param.xBitmap = xBitmap;
    param.yBitmap = yBitmap;
    param.rgbBk   = color1;
    param.rgbFg   = color2;
    param.fStyle  = flag;
    param.dwRop   = rop;

    // Not supported in MinGW w32api package prior to v3.2
#ifdef W32G_BROKENW32API
    W32G_WARN_UNSUPPORTED("ImageList_DrawIndirect missing from build");
    RETVAL = FALSE;
#else
    RETVAL = ImageList_DrawIndirect(&param);
#endif
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Duplicate()
    # Creates a duplicate of an existing image list. Return a new Win32::GUI::ImageList object.
void
Duplicate(handle)
    HIMAGELIST handle
PREINIT:
    HIMAGELIST  hdup;
PPCODE:
    // Not supported in MinGW w32api package prior to v3.2
#ifdef W32G_BROKENW32API
    W32G_WARN_UNSUPPORTED("ImageList_Duplicate missing from build");
    XSRETURN_UNDEF;
#else
    hdup = ImageList_Duplicate(handle);
    if (hdup == NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::ImageList", (HWND) hdup));
    XSRETURN(1);
#endif

    ###########################################################################
    # (@)METHOD:GetBkColor()
    # Retrieves the current background color for an image list. 
COLORREF
GetBkColor(handle)
    HIMAGELIST handle
CODE:
    RETVAL = ImageList_GetBkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetIcon(index, [flags=ILD_NORMAL])
    # Creates an Win32::GUI::Icon object from an image and mask in an image list.
void
GetIcon(handle, index, flags=ILD_NORMAL)
    HIMAGELIST handle
    int index
    UINT flags
PREINIT:
    HICON hicon;
PPCODE:    
    hicon = ImageList_GetIcon(handle, index, flags);
    if (hicon == NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::Icon", (HWND) hicon));
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:GetIconSize()
    # Retrieves the dimensions of images in an image list. All images in an image list have the same dimensions.
void
GetIconSize(handle)
    HIMAGELIST handle
PREINIT:
    int cx;
    int cy;
PPCODE:
    if(ImageList_GetIconSize(handle, &cx, &cy)) {
        EXTEND(SP, 2);
        XST_mIV(0, cx);
        XST_mIV(1, cy);
        XSRETURN(2);
    } else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:Count()
    # (@)METHOD:GetImageCount()
    # Returns the number of images in the ImageList.
int
GetImageCount(handle)
    HIMAGELIST handle
ALIAS:
    Win32::GUI::ImageList::Count = 1
CODE:
    RETVAL = ImageList_GetImageCount(handle);
OUTPUT:
    RETVAL

    # TODO : ImageList_GetImageInfo

    ###########################################################################
    # (@)METHOD:LoadImage(IMAGE,CX,[FLAG=LR_LOADFROMFILE],[TYPE=IMAGE_BITMAP],[COLORMASK=CLR_DEFAULT],[HINSTANCE=NULL],[GROW=1])
    # (@)METHOD:newFromImage(IMAGE,CX,[FLAG=LR_LOADFROMFILE],[TYPE=IMAGE_BITMAP],[COLORMASK=CLR_DEFAULT],[HINSTANCE=NULL],[GROW=1])
    # Return a new Win32::GUI::ImageList object.
void
LoadImage (pbmp, cx, uFlags=LR_LOADFROMFILE, uType=IMAGE_BITMAP, crMask=CLR_DEFAULT, hi=NULL, cGrow=1)
    SV*       pbmp
    int       cx
    UINT      uFlags
    UINT      uType    
    COLORREF  crMask
    HINSTANCE hi
    int       cGrow
ALIAS:
    Win32::GUI::ImageList::newFromImage = 1
PREINIT:
    HIMAGELIST  handle;
    LPCTSTR lpbmp;
PPCODE:
    if (SvPOK(pbmp))
        lpbmp = SvPV_nolen(pbmp);
    else
        lpbmp = MAKEINTRESOURCE(SvIV(pbmp));
    handle = ImageList_LoadImage(hi, lpbmp, cx, cGrow, crMask, uType, uFlags);
    if (handle == NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::ImageList", (HWND) handle));
    XSRETURN(1);
        
    ###########################################################################
    # (@)METHOD:Merge(INDEX1,INDEX2, DX,DY,[IMAGELIST=SELF])
    # Creates a new image by combining two existing images. The function also creates a new image list in which to store the image. 
    # Return a new Win32::GUI::ImageList object.
void
Merge(handle,i1,i2,dx,dy,handle2=handle)
    HIMAGELIST handle
    int i1
    int i2
    int dx
    int dy
    HIMAGELIST handle2
PREINIT:
    HIMAGELIST  hnew;
PPCODE:
    hnew = ImageList_Merge(handle,i1,handle2,i2,dx,dy);
    if (hnew == NULL) XSRETURN_UNDEF;
    XPUSHs(CreateObjectWithHandle(NOTXSCALL "Win32::GUI::ImageList", (HWND) hnew));
    XSRETURN(1);       

    # TODO : ImageList_Read

    ###########################################################################
    # (@)METHOD:Remove(INDEX)
    # Removes the specified zero-based INDEX image from the ImageList.
int
Remove(handle,index)
    HIMAGELIST handle
    int index
CODE:
    RETVAL = ImageList_Remove(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Replace(INDEX, BITMAP, [BITMAPMASK])
    # Replaces the specified zero-based INDEX image with the image specified
    # by BITMAP (must be a Win32::GUI::Bitmap object). BITMAPMASK is optional.
int
Replace(handle, index, bitmap, bitmapMask=NULL)
    HIMAGELIST handle
    int index
    HBITMAP bitmap
    HBITMAP bitmapMask
CODE:
    RETVAL = ImageList_Replace(handle, index, bitmap, bitmapMask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ReplaceIcon(INDEX, ICON)
    # Replaces the specified zero-based INDEX image with the icon specified
    # by ICON (must be a Win32::GUI::Icon object).
int
ReplaceIcon(handle, index, icon)
    HIMAGELIST handle
    int index
    HICON icon
CODE:
    RETVAL = ImageList_ReplaceIcon(handle, index, icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkColor(COLOR)
    # Sets the background color for an image list.  
COLORREF
SetBkColor(handle, color)
    HIMAGELIST handle
    COLORREF   color
CODE:
    RETVAL = ImageList_SetBkColor(handle, color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetDragCursorImage(INDEX, X, Y)
    # Creates a new drag image by combining the specified image (typically a
    # mouse cursor image) with the current drag image.
BOOL 
SetDragCursorImage(handle, index, x, y)
    HIMAGELIST handle
    int        index
    int        x
    int        y
CODE:
    RETVAL = ImageList_SetDragCursorImage(handle, index, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetIconSize(CX, CY)
    # Sets the dimensions of images in an image list and removes all images from the list. 
BOOL 
SetIconSize(handle, x, y)
    HIMAGELIST handle
    int        x
    int        y
CODE:
    RETVAL = ImageList_SetIconSize(handle, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageCount(COUNT)
    # Resizes an existing image list.
BOOL 
SetImageCount(handle, count)
    HIMAGELIST handle
    UINT       count
CODE:
    RETVAL = ImageList_SetImageCount(handle, count);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetOverlayImage(INDEX, OVERLAY)
    # Adds a specified image to the list of images to be used as overlay masks.
BOOL 
SetOverlayImage(handle, index, overlay)
    HIMAGELIST handle
    int        index
    int        overlay
CODE:
    RETVAL = ImageList_SetOverlayImage(handle, index, overlay);
OUTPUT:
    RETVAL

    # TODO : ImageList_Write
 
    ###########################################################################
    # (@)METHOD:AddIcon(ICON)
    # Add a icon specified by ICON (must be a Win32::GUI::Icon object).
int
AddIcon(handle, icon)
    HIMAGELIST handle
    HICON      icon
CODE:
    RETVAL = ImageList_AddIcon(handle, icon);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Clear()
    # (@)METHOD:RemoveAll()
    # Removes all the images from the ImageList.
int
RemoveAll(handle)
    HIMAGELIST handle
ALIAS:
    Win32::GUI::ImageList::Clear = 1
CODE:
    RETVAL = ImageList_RemoveAll(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color for the ImageList.
int
BackColor(handle,color=(COLORREF) -1)
    HIMAGELIST handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = ImageList_SetBkColor(handle, color);
    } else
        RETVAL = ImageList_GetBkColor(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Size([X, Y])
    # Gets or sets the size of the images in the ImageList;
    # if no parameter is given, returns a 2 element array (X, Y),
    # otherwise sets the size to the given parameters.
    # If X and Y is given, also removes all images from the list.
void
Size(handle,...)
    HIMAGELIST handle
PREINIT:
    int cx, cy;
    BOOL result;
PPCODE:
    if(items != 1 && items != 3)
        croak("Usage: Size(handle);\n   or: Size(handle, x, y);\n");
    if(items == 1) {
        if(ImageList_GetIconSize(handle, &cx, &cy)) {
            EXTEND(SP, 2);
            XST_mIV(0, cx);
            XST_mIV(1, cy);
            XSRETURN(2);
        } else
            XSRETURN_UNDEF;
    } else {
        result = ImageList_SetIconSize(handle, (int) SvIV(ST(1)), (int) SvIV(ST(2)));
        EXTEND(SP, 1);
        XST_mIV(0, result);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HIMAGELIST handle
CODE:
    RETVAL = ImageList_Destroy(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:DragEnter(WINDOW, X, Y)
    # Locks updates to the specified window during a drag operation and displays
    # the drag image at the specified position within the window. 
    # 
    # Class method : Win32::GUI::ImageList::DragEnter($window, $x, $y)
BOOL
DragEnter(handle, x, y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = ImageList_DragEnter(handle, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DragLeave(WINDOW)
    # Unlocks the specified window and hides the drag image, allowing the window
    # to be updated. 
    # 
    # Class method : Win32::GUI::ImageList::DragLeave($window)
BOOL
DragLeave(handle)
    HWND handle
CODE:
    RETVAL = ImageList_DragLeave(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DragMove(X, Y)
    # Locks updates to the specified window during a drag operation and displays
    # the drag image at the specified position within the window. 
    #
    # Class method : Win32::GUI::ImageList::DragMove($x, $y)
BOOL
DragMove(x, y)
    int x
    int y
CODE:
    RETVAL = ImageList_DragMove(x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DragShowNolock(FLAG)
    # Shows or hides the image being dragged.
    #
    # Class method : Win32::GUI::ImageList::DragShowNolock($flag)
BOOL
DragShowNolock(flag)
    BOOL flag
CODE:
    RETVAL = ImageList_DragShowNolock(flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EndDrag()
    # Ends a drag operation.
    #
    # Class method : Win32::GUI::ImageList::EndDrag()
void
EndDrag()
CODE:
    ImageList_EndDrag();

    ###########################################################################
    # (@)METHOD:GetDragImage()
    # Retrieves the temporary image list that is used for the drag image.
    #
    # Class method : Win32::GUI::ImageList::GetDragImage()
HIMAGELIST
GetDragImage()
CODE:
    RETVAL = ImageList_GetDragImage(NULL,NULL);
OUTPUT:
    RETVAL
