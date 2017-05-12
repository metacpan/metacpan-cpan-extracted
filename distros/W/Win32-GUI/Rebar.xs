    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Rebar
    #
    # $Id: Rebar.xs,v 1.10 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Rebar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = REBARCLASSNAME;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | RBS_VARHEIGHT | CCS_NODIVIDER;
    perlcs->cs.dwExStyle = WS_EX_TOOLWINDOW;
}

BOOL
Rebar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    BOOL retval = TRUE;

    if(strcmp(option, "-imagelist") == 0) {
        perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL value);
    } else if(strcmp(option, "-tooltip") == 0) {
        perlcs->hTooltip = (HWND) handle_From(NOTXSCALL value);
    } else if BitmaskOptionValue("-bandborders", perlcs->cs.style, RBS_BANDBORDERS)
    } else if BitmaskOptionValue("-fixedorder",  perlcs->cs.style, RBS_FIXEDORDER)
    } else if BitmaskOptionValue("-varheight",   perlcs->cs.style, RBS_VARHEIGHT)
    } else if BitmaskOptionValue("-autosize",    perlcs->cs.style, RBS_AUTOSIZE)
    } else if BitmaskOptionValue("-vertical",    perlcs->cs.style, CCS_VERT)
    } else if BitmaskOptionValue("-nodivider",   perlcs->cs.style, CCS_NODIVIDER)    
    } else if BitmaskOptionValue("-doubleclick", perlcs->cs.style, RBS_DBLCLKTOGGLE)
    } else if BitmaskOptionValue("-vgripper",    perlcs->cs.style, RBS_VERTICALGRIPPER)
    } else retval = TRUE;

    return retval;
}

void
Rebar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    // initialize and send the REBARINFO structure.
    REBARINFO rbi;
    rbi.cbSize = sizeof(REBARINFO);
    if(perlcs->hImageList != NULL) {
        rbi.fMask = RBIM_IMAGELIST;
        rbi.himl = perlcs->hImageList;
    } else {
        rbi.fMask = 0;
        rbi.himl = NULL;
    }
    SendMessage(myhandle, RB_SETBARINFO, 0, (LPARAM) &rbi);

    if (perlcs->hTooltip != NULL) {
        SendMessage(myhandle, RB_SETTOOLTIPS, (WPARAM) perlcs->hTooltip, (LPARAM) 0);
    }

    if(perlcs->clrForeground != CLR_INVALID) {
        SendMessage(myhandle, RB_SETTEXTCOLOR, (WPARAM) 0, (LPARAM) perlcs->clrForeground);
        perlcs->clrForeground = CLR_INVALID;  // Don't Store
    }

    if(perlcs->clrBackground != CLR_INVALID) {
        SendMessage(myhandle, RB_SETBKCOLOR, (WPARAM) 0, (LPARAM) perlcs->clrBackground);
        perlcs->clrBackground = CLR_INVALID;  // Don't Store
    }

}

BOOL
Rebar_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("HeightChange",    PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("ChevronPushed",   PERLWIN32GUI_NEM_CONTROL2)
    else retval = FALSE;

    return retval;
}

int
Rebar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_NOTIFY ) {

        switch( ((LPNMHDR)lParam)->code ) {

        case RBN_HEIGHTCHANGE :
            /*
             * (@)EVENT:HeightChange()
             * Sent when the height of the Rebar control has changed.
             * (@)APPLIES_TO:Rebar
             */
            {
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "HeightChange", -1 );
            }
            break;
        case RBN_CHEVRONPUSHED :
            /*
             * (@)EVENT:ChevronPushed(bandindex, left, top, right, bottom)
             * Sent when a chevron on a rebar band is clicked
             * (@)APPLIES_TO:Rebar
             */
            {
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "ChevronPushed",
                    PERLWIN32GUI_ARGTYPE_INT,  (INT)  ((LPNMREBARCHEVRON)lParam)->uBand,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) ((LPNMREBARCHEVRON)lParam)->rc.left,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) ((LPNMREBARCHEVRON)lParam)->rc.top,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) ((LPNMREBARCHEVRON)lParam)->rc.right,
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) ((LPNMREBARCHEVRON)lParam)->rc.bottom,
                    -1 );
            }
            break;
        }

    }

    return PerlResult;
}


MODULE = Win32::GUI::Rebar      PACKAGE = Win32::GUI::Rebar

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Rebar..." )

    ###########################################################################
    # (@)METHOD:BeginDrag(INDEX,[POSITION=-1])
    # Puts the rebar control in drag-and-drop mode.
LRESULT
BeginDrag(handle,index,position=(DWORD)-1)
    HWND handle
    UINT index
    DWORD position
CODE:
    RETVAL = SendMessage(handle, RB_BEGINDRAG, (WPARAM) index, (LPARAM) position);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteBand(INDEX)
    #
    # Delete a band. Index is Zero-based
LRESULT
DeleteBand(handle,index)
    HWND handle
    UINT index
CODE:
    RETVAL = SendMessage(handle, RB_DELETEBAND, (WPARAM) index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DragMove([POSITION=-1])
    # Updates the drag position in the rebar control after a previous BeginDrag(). 
LRESULT
DragMove(handle,position=(DWORD)-1)
    HWND handle
    DWORD position
CODE:
    RETVAL = SendMessage(handle, RB_DRAGMOVE, (WPARAM) 0, (LPARAM) position);
OUTPUT:
    RETVAL
 
    ###########################################################################
    # (@)METHOD:EndDrag()
    # Terminates the rebar control's drag-and-drop operation.
LRESULT
EndDrag(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, RB_ENDDRAG, (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBandBorder()
    # Retrieves the borders of a band. 
    # Returns a four elements array defining the rebar rectangle (left, top,
    # right, bottom) or undef on errors.
    # If the rebar control does not have -bandborders option set, only the left
    # value have valid information. 
void
GetBandBorder(handle,index)
    HWND handle
    UINT index
PREINIT:
    RECT myRect;
PPCODE:
    if(SendMessage(handle, RB_GETBANDBORDERS, (WPARAM) index, (LPARAM) &myRect)) {
        EXTEND(SP, 4);
        XST_mIV(0, myRect.left);
        XST_mIV(1, myRect.top);
        XST_mIV(2, myRect.right);
        XST_mIV(3, myRect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetBandCount()
    # (@)METHOD:BandCount()
    #
    # Returns the number of bands in the rebar.
LRESULT
GetBandCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Rebar::BandCount = 1
CODE:
    RETVAL = SendMessage(handle, RB_GETBANDCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBandInfo(INDEX)
    # (@)METHOD:BandInfo(INDEX)
    #
    # Returns information on the band as a hash.
    #   -text       => Contains the display text for the band.
    #   -foreground => Band foreground colors.
    #   -background => Band background colors.
    #   -image      => Image index in imagelist.
    #   -child      => Handle to the child window contained in the band, if any.
    #   -bitmap     => Bitmap background handle.
    #   -width      => Length of the band, in pixels.
    #   -minwidth   => Minimum width of the child window, in pixels. The band can't be sized smaller than this value. 
    #   -minheight  => Minimum height of the child window, in pixels. The band can't be sized smaller than this value.
    #   -style      => Flags that specify the band style.
    #   -idealwidth => Ideal band width. The band maximises to this size, and if chevrons are enabled
    #                  they are shown when the band is smaller than this value.
      
void
GetBandInfo(handle,index)
    HWND handle
    UINT index
ALIAS:
    Win32::GUI::Rebar::BandInfo = 1
PREINIT:
    REBARBANDINFO rbbi;
    char Buffer [256];
CODE:
    ZeroMemory(&rbbi, sizeof(REBARBANDINFO));
    rbbi.cbSize = sizeof(REBARBANDINFO);
    rbbi.fMask =
        RBBIM_BACKGROUND | RBBIM_CHILD | RBBIM_CHILDSIZE | RBBIM_COLORS |
        RBBIM_HEADERSIZE | RBBIM_IDEALSIZE | RBBIM_ID | RBBIM_IMAGE |
        RBBIM_LPARAM | RBBIM_SIZE | RBBIM_STYLE | RBBIM_TEXT;
    rbbi.lpText = Buffer;
    rbbi.cch = 255;
    if(SendMessage(handle, RB_GETBANDINFO, (WPARAM) index, (LPARAM) &rbbi)) {
        EXTEND(SP, 22);
        XST_mPV( 0, "-text");
        XST_mPV( 1, rbbi.lpText);
        XST_mPV( 2, "-foreground");
        XST_mIV( 3, rbbi.clrFore);
        XST_mPV( 4, "-background");
        XST_mIV( 5, rbbi.clrBack);
        XST_mPV( 6, "-image");
        XST_mIV( 7, rbbi.iImage);
        XST_mPV( 8, "-child");
        XST_mIV( 9, PTR2IV(rbbi.hwndChild));
        XST_mPV(10, "-bitmap");
        XST_mIV(11, PTR2IV(rbbi.hbmBack));
        XST_mPV(12, "-width");
        XST_mIV(13, rbbi.cx);
        XST_mPV(14, "-minwidth");
        XST_mIV(15, rbbi.cxMinChild);
        XST_mPV(16, "-minheight");
        XST_mIV(17, rbbi.cyMinChild);
        XST_mPV(18, "-style");
        XST_mIV(19, rbbi.fStyle);
        XST_mPV(20, "-idealwidth");
        XST_mIV(21, rbbi.cxIdeal);
        XSRETURN(22);
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetBarHeight(INDEX)
    # Retrieves the height of the rebar control. 
UINT 
GetBarHeight(handle,index,flag=1)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, RB_GETBARHEIGHT , (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetBarInfo()
    # Retrieves ReBar hash information.
    #  -imagelist => HANDLE
    #    Handle to an image list
void
GetBarInfo(handle)
    HWND handle
PREINIT:
    REBARINFO rbinfo;
PPCODE:
    ZeroMemory(&rbinfo, sizeof(REBARINFO));
    rbinfo.cbSize =  sizeof(REBARINFO);
    rbinfo.fMask = RBIM_IMAGELIST;
    if (SendMessage(handle, RB_GETBARINFO , (WPARAM) 0, (LPARAM) &rbinfo) ) {
        EXTEND(SP, 2);
        XST_mPV( 0, "-imagelist");
        XST_mIV( 1, PTR2IV(rbinfo.himl));
        XSRETURN(2);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetBkColor()
    #
    # Retrieves a rebar control's default background color.  
COLORREF
GetBkColor(handle)
    HWND handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, RB_GETBKCOLOR , (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    # TODO : RB_GETDROPTARGET

    ###########################################################################
    # (@)METHOD:GetColorScheme()
    # Retrieves Rebar color scheme hash information.
    #  -clrBtnHighlight => COLOR
    #    the highlight color of the buttons.
    #  -clrBtnShadow => COLOR
    #    the shadow color of the buttons. 
void
GetColorScheme(handle)
    HWND handle
PREINIT:
    COLORSCHEME colorscheme;
PPCODE:
    ZeroMemory(&colorscheme, sizeof(COLORSCHEME));
    colorscheme.dwSize = sizeof(COLORSCHEME);
    if (SendMessage(handle, RB_GETCOLORSCHEME , (WPARAM) 0, (LPARAM) &colorscheme) ) {
        EXTEND(SP, 4);
        XST_mPV( 0, "-clrBtnHighlight");
        XST_mIV( 1, (LONG) colorscheme.clrBtnHighlight);
        XST_mPV( 2, "-clrBtnShadow");
        XST_mIV( 3, (LONG) colorscheme.clrBtnShadow );
        XSRETURN(4);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetPallette()
    #
    # Retrieves a rebar control's default background color.  
LRESULT
GetPallette(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, RB_GETPALETTE , (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRect(index)
    # Retrieves the bounding rectangle for a given band in a rebar control. 
void
GetRect(handle,index)
    HWND handle
    int index
PREINIT:
    RECT Rect;
PPCODE:
    if(SendMessage(handle, RB_GETRECT, (WPARAM) index, (LPARAM) &Rect) == TRUE) {
        EXTEND(SP, 4);
        XST_mIV(0,Rect.left);
        XST_mIV(1,Rect.top);
        XST_mIV(2,Rect.right);
        XST_mIV(3,Rect.bottom);
        XSRETURN(4);
    }
    else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:GetRowCount()
    # (@)METHOD:RowCount()
    #
    # Returns the number of rows that the rebars are arranged in.
LRESULT
GetRowCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Rebar::RowCount = 1
CODE:
    RETVAL = SendMessage(handle, RB_GETROWCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetRowHeight(ROW)
    #
    # Retrieves the height of a specified row in a rebar control. 
LRESULT
GetRowHeight(handle, row)
    HWND handle
    UINT row
CODE:
    RETVAL = SendMessage(handle, RB_GETROWHEIGHT, (WPARAM) row, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextColor()
    #
    # Retrieves a rebar control's default text color.  
COLORREF
GetTextColor(handle)
    HWND handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, RB_GETTEXTCOLOR , (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTooltips()
    #
    # Retrieves the handle to any tooltip control associated with the rebar control. 
HWND
GetTooltips(handle)
    HWND handle
CODE:
    RETVAL = (HWND) SendMessage(handle, RB_GETTOOLTIPS , (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUnicodeFormat()
    #
    # Retrieves the UNICODE character format flag for the control. 
BOOL
GetUnicodeFormat(handle)
    HWND handle
CODE:
    RETVAL = (BOOL) SendMessage(handle, RB_GETUNICODEFORMAT , (WPARAM) 0, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X,Y)
    #
    # Determines which portion of a rebar band is at a given point on the screen, if a rebar band exists at that point. 
LRESULT
HitTest(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    RBHITTESTINFO rb;
CODE:
    rb.pt.x = x; rb.pt.y = y;
    RETVAL = SendMessage(handle, RB_HITTEST, (WPARAM) 0, (LPARAM) &rb);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:IdToIndex(ID)
    #
    # Converts a band identifier to a band index in a rebar control. 
LRESULT
IdToIndex(handle, id)
    HWND handle
    UINT id
CODE:
    RETVAL = SendMessage(handle, RB_IDTOINDEX , (WPARAM) id, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:InsertBand(%OPTIONS)
    #
    # Insert a new band into the rebar control.
    #
    # Allowed %OPTIONS are:
    #  -image      => Zero based index of the imagelist.
    #  -index      => Zero based index where the band is inserted.
    #  -bitmap     => The background bitmap for the band.
    #  -child      => Child control. See Below.
    #  -foreground => Band foreground colors.
    #  -background => Band background colors.
    #  -width      => The width of the band.
    #  -minwidth   => The minimum width of the band.
    #  -minheight  => The minimum height of the band.
    #  -text       => The text for the band.
    #  -style      => The style of the band. See Below
    #  -idealwidth => Ideal band width. The band maximises to this size, and if chevrons are enabled they are shown when the band is smaller than this value.
    #
    # Each band can only contain one child control. However, you can add a child window that contains many controls:
    #
    #  $mainwindow = <main window code>
    #
    #  my $band = new Win32::GUI::Window (
    #      -parent   => $mainwindow,
    #      -name     => "RebarBand1",
    #      -popstyle => WS_CAPTION | WS_SIZEBOX,
    #      -pushstyle => WS_CHILD,
    #  );
    #
    #  # create Date time control for band 1
    #  my $DateTime = $band->AddDateTime (
    #      -name     => "DateTime",
    #      -pos      => [0, 0],
    #      -size     => [130, 20],
    #      -tip      => 'A date and time',
    #  );
    #  #set the format for the datetime control
    #  $DateTime->Format('dd-MMM-yyyy HH:mm:ss');
    #
    #  #Add a button to band 1
    #  $band->AddButton (
    #           -name     => 'Button',
    #           -pos      => [135, 0],
    #           -size     => [50, 20],
    #           -text     => 'Button',
    #           -tip      => 'A Button',
    #           -onClick => sub {print 'button clicked' },
    #  );
    #
    #  my $rebar = $mainwindow->AddRebar(
    #      -name   => "Rebar",
    #      -bandborders => 1,
    #  );
    #
    #  #Insert band
    #  $rebar->InsertBand (  
    #    -child     => $band,
    #    -width     => 210,
    #    -minwidth  => 210,
    #    -minheight => 20,
    #  );
    #
    # Styles : Each band can have it's own style. As a default, each band has RBBS_CHILDEDGE | RBBS_FIXEDBMP
    #  RBBS_BREAK = 1           The band is on a new line.
    #  RBBS_FIXEDSIZE = 2       The band can't be sized. With this style, the sizing grip is not displayed on the band.
    #  RBBS_CHILDEDGE = 4       The band has an edge at the top and bottom of the child window.
    #  RBBS_HIDDEN = 8          The band will not be visible.
    #  RBBS_FIXEDBMP = 32       The background bitmap does not move when the band is resized.
    #  RBBS_VARIABLEHEIGHT = 64 The band can be resized by the rebar control.
    #  RBBS_GRIPPERALWAYS = 128 The band will always have a sizing grip, even if it is the only band in the rebar.
    #  RBBS_NOGRIPPER = 256     The band will never have a sizing grip, even if there is more than one band in the rebar.
    #  RBBS_USECHEVRON = 512    The band will display chevrons if its width is less than the ideal width
    #
LRESULT
InsertBand(handle,...)
    HWND handle
PREINIT:
    REBARBANDINFO rbbi;
    int index = -1;
CODE:
    ZeroMemory(&rbbi, sizeof(REBARBANDINFO));
    rbbi.cbSize = sizeof(REBARBANDINFO);
    rbbi.fStyle = RBBS_CHILDEDGE | RBBS_FIXEDBMP;
    rbbi.fMask |= RBBIM_STYLE;
    ParseRebarBandOptions(NOTXSCALL sp, mark, ax, items, 1, &rbbi, &index);
    RETVAL = SendMessage(handle, RB_INSERTBAND, (WPARAM) index, (LPARAM) &rbbi);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MaximizeBand(INDEX, [FLAG])
    # 
    # Maximize the band. Index is Zero-based. The flag indicates if the ideal width of the band should be used.
LRESULT
MaximizeBand(handle,index,flag=0)
    HWND handle
    UINT index
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, RB_MAXIMIZEBAND, (WPARAM) index, (LPARAM) flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MinimizeBand(INDEX)
    #
    # Minimize the band. Index is Zero-based.
LRESULT
MinimizeBand(handle,index)
    HWND handle
    UINT index
CODE:
    RETVAL = SendMessage(handle, RB_MINIMIZEBAND, (WPARAM) index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MoveBand(iFrom, iTo)
    #
    # Moves a band from one index to another. 
LRESULT
MoveBand(handle, iFrom, iTo)
    HWND handle
    UINT iFrom
    UINT iTo
CODE:
    RETVAL = SendMessage(handle, RB_MOVEBAND, (WPARAM) iFrom, (LPARAM) iTo);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBandInfo(INDEX, %OPTIONS)
    # Sets characteristics of an existing band in a rebar control.
    # B<%OPTIONS> : See InserBand().
LRESULT
SetBandInfo(handle, index, ...)
    HWND handle
    int  index
PREINIT:
    REBARBANDINFO rbbi;    
CODE:
    ZeroMemory(&rbbi, sizeof(REBARBANDINFO));
    rbbi.cbSize = sizeof(REBARBANDINFO);
    ParseRebarBandOptions(NOTXSCALL sp, mark, ax, items, 2, &rbbi, &index);
    RETVAL = SendMessage(handle, RB_SETBANDINFO, (WPARAM) index, (LPARAM) &rbbi);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBarInfo(%OPTIONS)
    #
    # Sets a Rebar informations.
    #
    # B<%OPTIONS> :
    #  -imagelist => Imagelist.
LRESULT
SetBarInfo(handle,...)
    HWND handle
PREINIT:
    REBARINFO rbi;
    int i, next_i;
CODE:
    ZeroMemory(&rbi, sizeof(REBARINFO));
    rbi.cbSize = sizeof(REBARINFO);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-imagelist") == 0) {
                next_i = i + 1;
                rbi.himl = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                rbi.fMask |= RBIM_IMAGELIST;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = SendMessage(handle, RB_SETBARINFO, (WPARAM) 0, (LPARAM) &rbi);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkColor(COLOR)
    #
    # Sets a rebar control's default background color. 
LRESULT
SetBkColor(handle, color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, RB_SETBKCOLOR, (WPARAM) 0, (LPARAM) color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetColorScheme(%OPTIONS)
    #
    # Sets Rebar color scheme.
    #
    # B<%OPTIONS> :
    #  -clrBtnHighlight => COLOR.
    #     the highlight color of the buttons. 
    #  -clrBtnShadow => COLOR.
    #     the shadow color of the buttons. 
LRESULT
SetColorScheme(handle,...)
    HWND handle
PREINIT:
    COLORSCHEME colorscheme;
    int i, next_i;
CODE:
    ZeroMemory(&colorscheme, sizeof(COLORSCHEME));
    colorscheme.dwSize = sizeof(COLORSCHEME);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-clrBtnHighlight") == 0) {
                next_i = i + 1;
                colorscheme.clrBtnHighlight = SvCOLORREF(NOTXSCALL ST(next_i));
            }
            else if(strcmp(SvPV_nolen(ST(i)), "-clrBtnShadow") == 0) {
                next_i = i + 1;
                colorscheme.clrBtnShadow = SvCOLORREF(NOTXSCALL ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = SendMessage(handle, RB_SETCOLORSCHEME, (WPARAM) 0, (LPARAM) &colorscheme);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetPalette(PALETTE)
    #
    # Sets the rebar control's current palette. 
LRESULT
SetPalette(handle, palette)
    HWND handle
    WPARAM palette
CODE:
    RETVAL = SendMessage(handle, RB_SETPALETTE, (WPARAM) 0, (LPARAM) palette);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetParent(PARENT)
    #
    # Sets a rebar control's parent window.  
LRESULT
SetParent(handle, parent)
    HWND handle
    HWND parent
CODE:
    RETVAL = SendMessage(handle, RB_SETPARENT, (WPARAM) parent, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTextColor(COLOR)
    #
    # Sets a rebar control's default text color. 
LRESULT
SetTextColor(handle, color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, RB_SETTEXTCOLOR, (WPARAM) 0, (LPARAM) color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToolTips(TOOLTIP)
    #
    # Associates a tooltip control with the rebar control.   
LRESULT
SetToolTips(handle, tooltip)
    HWND handle
    HWND tooltip
CODE:
    RETVAL = SendMessage(handle, RB_SETTOOLTIPS, (WPARAM) tooltip, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUnicodeFormat(FLAG)
    #
    # Sets the UNICODE character format flag for the control.  
LRESULT
SetUnicodeFormat(handle, flag)
    HWND handle
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, RB_SETUNICODEFORMAT, (WPARAM) flag, (LPARAM) 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ShowBand(INDEX, [FLAG])
    #
    # Show the band. Index is Zero-based. If flag is 1, the band is hidden.
LRESULT
ShowBand(handle,index,flag=1)
    HWND handle
    UINT index
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, RB_SHOWBAND, (WPARAM) index, (LPARAM) flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SizeToRect(LEFT, TOP, RIGHT, BOTTOM)
    # Attempts to find the best layout of the bands for the given rectangle. 
LRESULT
SizeToRect(handle,left,top,right,bottom)
    HWND handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT myRect;
CODE:
    myRect.left   = left;
    myRect.top    = top;
    myRect.right  = right;
    myRect.bottom = bottom;
    RETVAL = SendMessage(handle, RB_SIZETORECT, (WPARAM) 0, (LPARAM) &myRect);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################

    ###########################################################################
    # (@)METHOD:HideBand(INDEX, [FLAG])
    #
    # Hide the band. Index is Zero-based. If flag is 1, the band is shown.
LRESULT
HideBand(handle,index,flag=0)
    HWND handle
    UINT index
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, RB_SHOWBAND, (WPARAM) index, (LPARAM) flag);
OUTPUT:
    RETVAL
