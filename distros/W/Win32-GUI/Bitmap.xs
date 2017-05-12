    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Bitmap
    #
    # $Id: Bitmap.xs,v 1.2 2004/03/25 22:46:49 lrocher Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

MODULE = Win32::GUI::Bitmap     PACKAGE = Win32::GUI::Bitmap

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Bitmap..." )

    ###########################################################################
    # (@)METHOD:Info()
    # returns a four elements array containing the following information
    # about the bitmap: width, height, color planes, bits per pixel
    # or undef on errors
void
Info(handle)
    HBITMAP handle
PREINIT:
    BITMAP bitmap;
PPCODE:
    ZeroMemory(&bitmap, sizeof(BITMAP));
    if(GetObject((HGDIOBJ) handle, sizeof(BITMAP), &bitmap)) {
        EXTEND(SP, 4);
        XST_mIV(0, bitmap.bmWidth);
        XST_mIV(1, bitmap.bmHeight);
        XST_mIV(2, bitmap.bmPlanes);
        XST_mIV(3, bitmap.bmBitsPixel);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetDIBits()
    # The GetDIBits function retrieves the bits of the specified bitmap and copies them into a buffer using the specified format. 
void
GetDIBits(handle, hdc)
    HBITMAP handle
    HDC hdc
PREINIT:
    BITMAP bitmap;
    BITMAPINFO bInfo;
    long bufferlen;
    LPVOID buffer;
PPCODE:
    ZeroMemory(&bInfo, sizeof(BITMAPINFO));
    bInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    ZeroMemory(&bitmap, sizeof(BITMAP));
    if(GetObject((HGDIOBJ) handle, sizeof(BITMAP), &bitmap)) {
        bufferlen = bitmap.bmHeight * bitmap.bmWidthBytes;
        buffer = (LPVOID) safemalloc(bufferlen);
        bInfo.bmiHeader.biWidth       = bitmap.bmWidth;
        bInfo.bmiHeader.biHeight      = bitmap.bmHeight;
        bInfo.bmiHeader.biPlanes      = bitmap.bmPlanes;
        bInfo.bmiHeader.biBitCount    = bitmap.bmBitsPixel;
        bInfo.bmiHeader.biCompression = BI_RGB;
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::GetDIBits): getting %ld bytes...\n", bufferlen);
#endif
        if(GetDIBits(
            hdc,                        // handle of device context
            handle,                     // handle of bitmap
            0,                          // first scan line to set in destination bitmap
            bitmap.bmHeight,            // number of scan lines to copy
            buffer,                     // address of array for bitmap bits
            &bInfo,                     // address of structure with bitmap data
            DIB_RGB_COLORS              // RGB or palette index
        )) {
            EXTEND(SP, 5);
            XST_mIV(0, bitmap.bmWidth);
            XST_mIV(1, bitmap.bmHeight);
            XST_mIV(2, bitmap.bmPlanes);
            XST_mIV(3, bitmap.bmBitsPixel);
            sv_setpvn(ST(4), (char*) buffer, bufferlen);
            safefree(buffer);
            XSRETURN(5);
        } else {
#ifdef PERLWIN32GUI_DEBUG
            printf("XS(Bitmap::GetDIBits): GetDIBits failed (%d)\n", GetLastError());
#endif
            safefree(buffer);
            XSRETURN_UNDEF;
        }
    } else {
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::GetDIBits): GetObject failed (%d)\n", GetLastError());
#endif
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Create(WIDTH, HEIGHT, PLANES, BPP, DATA)
HBITMAP
Create(width, height, planes, bpp, data)
    int width
    int height
    UINT planes
    UINT bpp
    LPVOID data
CODE:
    RETVAL = CreateBitmap(width, height, planes, bpp, data);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:OldInfo()
void
OldInfo(handle)
    HBITMAP handle
PREINIT:
    BITMAPINFO bInfo;
PPCODE:
    ZeroMemory(&bInfo, sizeof(BITMAPINFO));
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::OldInfo): handle=0x%x\n", handle);
#endif
    bInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bInfo.bmiHeader.biBitCount = 0; // don't care about colors, just general infos
    if(GetDIBits(NULL,          // handle of device context
                 handle,        // handle of bitmap
                 0,             // first scan line to set in destination bitmap
                 0,             // number of scan lines to copy
                 NULL,          // address of array for bitmap bits
                 &bInfo,        // address of structure with bitmap data
                 DIB_RGB_COLORS // RGB or palette index
                )) {
        EXTEND(SP, 9);
        XST_mIV(0, bInfo.bmiHeader.biWidth);
        XST_mIV(1, bInfo.bmiHeader.biHeight);
        XST_mIV(2, bInfo.bmiHeader.biBitCount);
        XST_mIV(3, bInfo.bmiHeader.biCompression);
        XST_mIV(4, bInfo.bmiHeader.biSizeImage);
        XST_mIV(5, bInfo.bmiHeader.biXPelsPerMeter);
        XST_mIV(6, bInfo.bmiHeader.biYPelsPerMeter);
        XST_mIV(7, bInfo.bmiHeader.biClrUsed);
        XST_mIV(8, bInfo.bmiHeader.biClrImportant);
        XSRETURN(9);
    } else {
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::OldInfo): GetDIBits failed...\n");
        printf("XS(Bitmap::OldInfo): LastError is %d\n", GetLastError());
        printf("XS(Bitmap::OldInfo): bInfo.bmiHeader.biWidth=%d\n", bInfo.bmiHeader.biWidth);
#endif
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)INTERNAL:OldInfoC()
void
OldInfoC(handle)
    HBITMAP handle
PREINIT:
    BITMAPCOREINFO bInfo;
PPCODE:
    ZeroMemory(&bInfo, sizeof(BITMAPCOREINFO));
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::OldInfoC): handle=0x%x\n", handle);
#endif
    bInfo.bmciHeader.bcSize = sizeof(BITMAPCOREHEADER);
    bInfo.bmciHeader.bcBitCount = 0; // don't care about colors, just general infos
    if(GetDIBits(NULL,          // handle of device context
                 handle,        // handle of bitmap
                 0,             // first scan line to set in destination bitmap
                 0,             // number of scan lines to copy
                 NULL,          // address of array for bitmap bits
                 (LPBITMAPINFO) &bInfo,        // address of structure with bitmap data
                 DIB_RGB_COLORS // RGB or palette index
                )) {
        EXTEND(SP, 3);
        XST_mIV(0, bInfo.bmciHeader.bcWidth);
        XST_mIV(1, bInfo.bmciHeader.bcHeight);
        XST_mIV(2, bInfo.bmciHeader.bcBitCount);
        XSRETURN(3);
    } else {
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::OldInfoC): GetDIBits failed...\n");
        printf("XS(Bitmap::OldInfoC): LastError is %d\n", GetLastError());
        printf("XS(Bitmap::OldInfoC): bInfo.bmciHeader.bcWidth=%d\n", bInfo.bmciHeader.bcWidth);
#endif
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HBITMAP handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL

