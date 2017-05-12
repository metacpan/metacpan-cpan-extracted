    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Font
    #
    # $Id: Font.xs,v 1.4 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"


MODULE = Win32::GUI::Font       PACKAGE = Win32::GUI::Font

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Font..." )

    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
    # Used by new Win32::GUI::Font.
void
Create(...)
PPCODE:
    int nHeight;
    int nWidth;
    int nEscapement;
    int nOrientation;
    int fnWeight;
    DWORD fdwItalic;
    DWORD fdwUnderline;
    DWORD fdwStrikeOut;
    DWORD fdwCharSet;
    DWORD fdwOutputPrecision;
    DWORD fdwClipPrecision;
    DWORD fdwQuality;
    DWORD fdwPitchAndFamily;
    char lpszFace[32];                        // pointer to typeface name string
    int i, next_i;
    char *option;

    nHeight = 0;                              // logical height of font
    nWidth = 0;                               // logical average character width
    nEscapement = 0;                          // angle of escapement
    nOrientation = 0;                         // base-line orientation angle
    fnWeight = 400;                           // font weight
    fdwItalic = 0;                            // italic attribute flag
    fdwUnderline = 0;                         // underline attribute flag
    fdwStrikeOut = 0;                         // strikeout attribute flag
    fdwCharSet = DEFAULT_CHARSET;             // character set identifier
    fdwOutputPrecision = OUT_DEFAULT_PRECIS;  // output precision
    fdwClipPrecision = CLIP_DEFAULT_PRECIS;   // clipping precision
    fdwQuality = DEFAULT_QUALITY;             // output quality
    fdwPitchAndFamily = DEFAULT_PITCH
                      | FF_DONTCARE;          // pitch and family

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-height") == 0 || strcmp(option, "-size") == 0) {
                HDC hDisplay;
                next_i = i + 1;
                hDisplay = CreateDC("DISPLAY", NULL, NULL, NULL);
                nHeight = (int) -MulDiv((int)SvIV(ST(next_i)), GetDeviceCaps(hDisplay, LOGPIXELSY), 72);
                DeleteDC(hDisplay);
            }
            else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                nWidth = (int) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-escapement") == 0) {
                next_i = i + 1;
                nEscapement = (int) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-orientation") == 0) {
                next_i = i + 1;
                nOrientation = (int) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-weight") == 0) {
                next_i = i + 1;
                fnWeight = (int) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) fnWeight = 700;
            }
            else if(strcmp(option, "-italic") == 0) {
                next_i = i + 1;
                fdwItalic = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-underline") == 0) {
                next_i = i + 1;
                fdwUnderline = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-strikeout") == 0) {
                next_i = i + 1;
                fdwStrikeOut = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-charset") == 0) {
                next_i = i + 1;
                fdwCharSet = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-outputprecision") == 0) {
                next_i = i + 1;
                fdwOutputPrecision = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-clipprecision") == 0) {
                next_i = i + 1;
                fdwClipPrecision = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-quality") == 0) {
                next_i = i + 1;
                fdwQuality = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-family") == 0) {
                next_i = i + 1;
                fdwPitchAndFamily = (DWORD) SvIV(ST(next_i));
            }
            else if(strcmp(option, "-name") == 0 || strcmp(option, "-face") == 0) {
                next_i = i + 1;
                strncpy(lpszFace, SvPV_nolen(ST(next_i)), 32);
            }
        } else {
            next_i = -1;
        }
    }
    XSRETURN_IV(PTR2IV(CreateFont(
        nHeight,
        nWidth,
        nEscapement,
        nOrientation,
        fnWeight,
        fdwItalic,
        fdwUnderline,
        fdwStrikeOut,
        fdwCharSet,
        fdwOutputPrecision,
        fdwClipPrecision,
        fdwQuality,
        fdwPitchAndFamily,
        (LPCTSTR) lpszFace)
    ));


    ###########################################################################
    # (@)METHOD:GetMetrics()
    # Returns an associative array of information about the Font:
    #  -height
    #  -ascent
    #  -descent
    #  -ileading
    #  -eleading
    #  -avgwidth
    #  -maxwidth
    #  -overhang
    #  -aspectx
    #  -aspecty
    #  -firstchar
    #  -lastchar
    #  -breakchar
    #  -italic
    #  -underline
    #  -strikeout
    #  -flags
    #  -charset
void
GetMetrics(handle)
    HFONT handle
PREINIT:
    HDC hdc;
    TEXTMETRIC metrics;
PPCODE:
    ZeroMemory(&metrics, sizeof(TEXTMETRIC));
    hdc = CreateDC("DISPLAY", NULL, NULL, NULL);
    if(hdc != NULL) {
        SelectObject(hdc, (HGDIOBJ) handle);
        if(GetTextMetrics(hdc, &metrics)) {
            DeleteDC(hdc);
            EXTEND(SP, 38);
            XST_mPV( 0, "-height");
            XST_mIV( 1, metrics.tmHeight);
            XST_mPV( 2, "-ascent");
            XST_mIV( 3, metrics.tmAscent);
            XST_mPV( 4, "-descent");
            XST_mIV( 5, metrics.tmDescent);
            XST_mPV( 6, "-ileading");
            XST_mIV( 7, metrics.tmInternalLeading);
            XST_mPV( 8, "-eleading");
            XST_mIV( 9, metrics.tmExternalLeading);
            XST_mPV(10, "-avgwidth");
            XST_mIV(11, metrics.tmAveCharWidth);
            XST_mPV(12, "-maxwidth");
            XST_mIV(13, metrics.tmMaxCharWidth);
            XST_mPV(14, "-overhang");
            XST_mIV(15, metrics.tmOverhang);
            XST_mPV(16, "-aspectx");
            XST_mIV(17, metrics.tmDigitizedAspectX);
            XST_mPV(18, "-aspecty");
            XST_mIV(19, metrics.tmDigitizedAspectY);
            XST_mPV(20, "-firstchar");
            XST_mIV(21, metrics.tmFirstChar);
            XST_mPV(22, "-lastchar");
            XST_mIV(23, metrics.tmLastChar);
            XST_mPV(24, "-defchar");
            XST_mIV(25, metrics.tmDefaultChar);
            XST_mPV(26, "-breakchar");
            XST_mIV(27, metrics.tmBreakChar);
            XST_mPV(28, "-italic");
            XST_mIV(29, metrics.tmItalic);
            XST_mPV(30, "-underline");
            XST_mIV(31, metrics.tmUnderlined);
            XST_mPV(32, "-strikeout");
            XST_mIV(33, metrics.tmStruckOut);
            XST_mPV(34, "-flags");
            XST_mIV(35, metrics.tmPitchAndFamily);
            XST_mPV(36, "-charset");
            XST_mIV(37, metrics.tmCharSet);
            XSRETURN(38);
        } else {
            DeleteDC(hdc);
            XSRETURN_UNDEF;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Info()
    # Returns an associative array of information about the Font, with
    # the same options given when creating the font.
void
Info(handle)
    HFONT handle
PREINIT:
    LOGFONT logfont;
PPCODE:
    ZeroMemory(&logfont, sizeof(LOGFONT));
    if(GetObject((HGDIOBJ) handle, sizeof(LOGFONT), (LPVOID) &logfont)) {
        HDC hDisplay;
        hDisplay = CreateDC("DISPLAY", NULL, NULL, NULL);
        logfont.lfHeight = -MulDiv(logfont.lfHeight, 72, GetDeviceCaps(hDisplay, LOGPIXELSY));
        DeleteDC(hDisplay);

        EXTEND(SP, 28);
        XST_mPV( 0, "-height");
        XST_mIV( 1, logfont.lfHeight);
        XST_mPV( 2, "-width");
        XST_mIV( 3, logfont.lfWidth);
        XST_mPV( 4, "-escapement");
        XST_mIV( 5, logfont.lfEscapement);
        XST_mPV( 6, "-orientation");
        XST_mIV( 7, logfont.lfOrientation);
        XST_mPV( 8, "-weight");
        XST_mIV( 9, logfont.lfWeight);
        XST_mPV(10, "-italic");
        XST_mIV(11, logfont.lfItalic);
        XST_mPV(12, "-underline");
        XST_mIV(13, logfont.lfUnderline);
        XST_mPV(14, "-strikeout");
        XST_mIV(15, logfont.lfStrikeOut);
        XST_mPV(16, "-charset");
        XST_mIV(17, logfont.lfCharSet);
        XST_mPV(18, "-outputprecision");
        XST_mIV(19, logfont.lfOutPrecision);
        XST_mPV(20, "-clipprecision");
        XST_mIV(21, logfont.lfClipPrecision);
        XST_mPV(22, "-quality");
        XST_mIV(23, logfont.lfQuality);
        XST_mPV(24, "-family");
        XST_mIV(25, logfont.lfPitchAndFamily);
        XST_mPV(26, "-name");
        XST_mPV(27, logfont.lfFaceName);
        XSRETURN(28);
    } else {
        XSRETURN_UNDEF;
    }


    ###########################################################################
    # (@)INTERNAL:DESTROY(handle)
BOOL
DESTROY(handle)
    HFONT handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL

