    /*
    ###########################################################################
    # options parsing routines
    #
    # $Id: GUI_Options.cpp,v 1.18 2011/07/16 14:51:03 acalpini Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

    /*
    ###########################################################################
    # (@)INTERNAL:ParseNEMEvent(*perlcs, char *name, SV event)
    */
void ParseNEMEvent(
    NOTXSPROC
    LPPERLWIN32GUI_CREATESTRUCT perlcs,
    char *name,
    SV* event
) {

    SV* newval;
    int eventID = 0;

    // First call Class OnParse Event, Get a chance to replace default event
    if (OnParseEvent[perlcs->iClass](NOTXSCALL name, &eventID)) {
    // Window Standard Event
    } else if(strcmp(name, "MouseMove") == 0) {
        eventID = PERLWIN32GUI_NEM_MOUSEMOVE;
    } else if(strcmp(name, "MouseOver") == 0) {
        eventID = PERLWIN32GUI_NEM_MOUSEOVER;
    } else if(strcmp(name, "MouseOut") == 0) {
        eventID = PERLWIN32GUI_NEM_MOUSEOUT;
    } else if(strcmp(name, "MouseDown") == 0) {
        eventID = PERLWIN32GUI_NEM_LMOUSEDOWN;
    } else if(strcmp(name, "MouseUp") == 0) {
        eventID = PERLWIN32GUI_NEM_LMOUSEUP;
    } else if(strcmp(name, "MouseDblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_LMOUSEDBLCLK;
    } else if(strcmp(name, "MouseRightDown") == 0) {
        eventID = PERLWIN32GUI_NEM_RMOUSEDOWN;
    } else if(strcmp(name, "MouseRightUp") == 0) {
        eventID = PERLWIN32GUI_NEM_RMOUSEUP;
    } else if(strcmp(name, "MouseRightDblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_RMOUSEDBLCLK;
    } else if(strcmp(name, "MouseMiddleDown") == 0) {
        eventID = PERLWIN32GUI_NEM_MMOUSEDOWN;
    } else if(strcmp(name, "MouseMiddleUp") == 0) {
        eventID = PERLWIN32GUI_NEM_MMOUSEUP;
    } else if(strcmp(name, "MouseMiddleDblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_MMOUSEDBLCLK;
    } else if(strcmp(name, "KeyDown") == 0) {
        eventID = PERLWIN32GUI_NEM_KEYDOWN;
    } else if(strcmp(name, "KeyUp") == 0) {
        eventID = PERLWIN32GUI_NEM_KEYUP;
    } else if(strcmp(name, "Timer") == 0) {
        eventID = PERLWIN32GUI_NEM_TIMER;
    } else if(strcmp(name, "Paint") == 0) {
        eventID = PERLWIN32GUI_NEM_PAINT;    
    } else if(strcmp(name, "Click") == 0) {
        eventID = PERLWIN32GUI_NEM_CLICK;
    } else if(strcmp(name, "RightClick") == 0) {
        eventID = PERLWIN32GUI_NEM_RIGHTCLICK;
    } else if(strcmp(name, "DblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_DBLCLICK;
    } else if(strcmp(name, "DblRightClick") == 0) {
        eventID = PERLWIN32GUI_NEM_DBLRIGHTCLICK;
    } else if(strcmp(name, "GotFocus") == 0) {
        eventID = PERLWIN32GUI_NEM_GOTFOCUS;
    } else if(strcmp(name, "LostFocus") == 0) {
        eventID = PERLWIN32GUI_NEM_LOSTFOCUS;
    } else if(strcmp(name, "DropFiles") == 0) {
        eventID = PERLWIN32GUI_NEM_DROPFILE;        
    } else if(strcmp(name, "Char") == 0) {
        eventID = PERLWIN32GUI_NEM_CHAR;        
    } else {
    	W32G_WARN("Win32::GUI: Unrecognized event name '%s' in -names!", name);
    }

    if(eventID != 0) {
        // Clear current event if necessary
        if ( hv_exists(perlcs->hvEvents, name, strlen(name)) )         
            hv_delete(perlcs->hvEvents, name, strlen(name),G_DISCARD);
        // Store event
        if(SvOK(event)) {
            newval = newSVsv(event);
            hv_store(perlcs->hvEvents, name, strlen(name), newval, 0);
            SwitchBit(perlcs->dwEventMask, eventID, 1);
        } else {
            SwitchBit(perlcs->dwEventMask, eventID, 0);            
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseWindowOptions(sp, mark, ax ,items, from_i, *perlcs)
    */
void ParseWindowOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPPERLWIN32GUI_CREATESTRUCT perlcs
) {

    int i, next_i;
    char * option;
    SV** stored;
    SV* storing;
#ifdef PERLWIN32GUI_STRONGDEBUG
    // printf("!XS(ParseWindowOptions): from_i=%d, items=%d\n", from_i, items);
#endif
    next_i = -1;
    for(i=from_i; i<items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
#ifdef PERLWIN32GUI_STRONGDEBUG
            printf("!XS(ParseWindowOptions): got option '%s'\n", option);
#endif
            if(strcmp(option, "-class") == 0) {
                next_i = i + 1;
                perlcs->cs.lpszClass = (LPCTSTR) classname_From(NOTXSCALL ST(next_i));                
            } else if(strcmp(option, "-text") == 0
            ||        strcmp(option, "-caption") == 0
            ||        strcmp(option, "-title") == 0) {
                next_i = i + 1;
                perlcs->cs.lpszName = (LPCTSTR) SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                perlcs->cs.style = (DWORD) SvIV(ST(next_i));
                W32G_WARN_DEPRECATED("Win32::GUI: the -style option is deprecated!");
            } else if(strcmp(option, "-pushstyle") == 0
            ||        strcmp(option, "-addstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.style |= (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-popstyle") == 0
            ||        strcmp(option, "-remstyle") == 0
            ||        strcmp(option, "-notstyle") == 0
            ||        strcmp(option, "-negstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.style &= perlcs->cs.style ^ (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-exstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.dwExStyle = (DWORD) SvIV(ST(next_i));
                W32G_WARN_DEPRECATED("Win32::GUI: the -exstyle option is deprecated!");
            } else if(strcmp(option, "-pushexstyle") == 0
            ||        strcmp(option, "-addexstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.dwExStyle |= (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-popexstyle") == 0
            ||        strcmp(option, "-remexstyle") == 0
            ||        strcmp(option, "-notexstyle") == 0
            ||        strcmp(option, "-negexstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.dwExStyle &= perlcs->cs.dwExStyle ^ (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-left") == 0) {
                next_i = i + 1;
                perlcs->cs.x = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-top") == 0) {
                next_i = i + 1;
                perlcs->cs.y = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                perlcs->cs.cx = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                perlcs->cs.cy = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-parent") == 0) {
                next_i = i + 1;
                perlcs->cs.hwndParent = (HWND) handle_From(NOTXSCALL ST(next_i));
                if(SvROK(ST(next_i))) {
                    perlcs->hvParent = (HV*) SvRV(ST(next_i));
                }
            } else if(strcmp(option, "-menu") == 0) {
                next_i = i + 1;
                perlcs->cs.hMenu = (HMENU) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-instance") == 0) {
                next_i = i + 1;
                perlcs->cs.hInstance = INT2PTR(HINSTANCE,SvIV(ST(next_i)));
            } else if(strcmp(option, "-name") == 0) {
                next_i = i + 1;
                perlcs->szWindowName = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-font") == 0) {
                next_i = i + 1;
                perlcs->hFont = (HFONT) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-foreground") == 0) {
                next_i = i + 1;
                perlcs->clrForeground = SvCOLORREF(NOTXSCALL ST(next_i));
                storing = newSViv((long) perlcs->clrForeground);
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-foreground", 11, storing, 0);
            } else if(strcmp(option, "-background") == 0) {
                next_i = i + 1;
                perlcs->clrBackground = SvCOLORREF(NOTXSCALL ST(next_i));
                {
                    LOGBRUSH lb;
                    ZeroMemory(&lb, sizeof(LOGBRUSH));
                    lb.lbStyle = BS_SOLID;
                    lb.lbColor = perlcs->clrBackground;
                    if(perlcs->hBackgroundBrush != NULL && perlcs->bDeleteBackgroundBrush) {
                        DeleteObject((HGDIOBJ) perlcs->hBackgroundBrush);
                    }
                    perlcs->hBackgroundBrush = CreateBrushIndirect(&lb);
                    perlcs->bDeleteBackgroundBrush = TRUE;
                }
                storing = newSViv(PTR2IV(perlcs->clrBackground));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-background", 11, storing, 0);
                storing = newSViv(PTR2IV(perlcs->hBackgroundBrush));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-backgroundbrush", 16, storing, 0);
            } else if(strcmp(option, "-backgroundbrush") == 0) {
                next_i = i + 1;
				if(perlcs->hBackgroundBrush != NULL && perlcs->bDeleteBackgroundBrush) {
					DeleteObject((HGDIOBJ) perlcs->hBackgroundBrush);
				}
                perlcs->hBackgroundBrush = (HBRUSH) handle_From(NOTXSCALL ST(next_i));;
                perlcs->bDeleteBackgroundBrush = FALSE;
                storing = newSViv(PTR2IV(perlcs->hBackgroundBrush));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-backgroundbrush", 16, storing, 0);
            } else if(strcmp(option, "-size") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    SV** t;
                    t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
                    if(t != NULL) {
                        perlcs->cs.cx = (int) SvIV(*t);
                    }
                    t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
                    if(t != NULL) {
                        perlcs->cs.cy = (int) SvIV(*t);
                    }
                } else {
                    W32G_WARN("Win32::GUI: Argument to -size is not an array reference!");
                }
            } else if(strcmp(option, "-pos") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    SV** t;
                    t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
                    if(t != NULL) {
                        perlcs->cs.x = (int) SvIV(*t);
                    }
                    t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
                    if(t != NULL) {
                        perlcs->cs.y = (int) SvIV(*t);
                    }
                } else {
                    W32G_WARN("Win32::GUI: Argument to -pos is not an array reference!");
                }
            } else if(strcmp(option, "-tip") == 0) {
                next_i = i + 1;
                perlcs->szTip = SvPV_nolen(ST(next_i));

            } else if(strcmp(option, "-events") == 0) {
                next_i = i + 1;
                {
                    HV* hash;
                    SV* val;
                    char* key;
                    I32 keylen;
#ifdef PERLWIN32GUI_STRONGDEBUG
                    printf("!XS(ParseWindowOptions): initializing perlcs.hvEvents\n");
#endif
                    if((LPVOID) perlcs->hvEvents == NULL) {
                        perlcs->hvEvents = newHV();
                        perlcs->dwEventMask = 0;
                    }
                    hash = (HV*) SvRV(ST(next_i));
                    hv_iterinit( hash );
                    while ( val = hv_iternextsv( hash, &key, &keylen ) ) {
                        ParseNEMEvent( NOTXSCALL perlcs, key, val );
                    }
                }

                SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_NEM, (perlcs->dwEventMask != 0));

            } else if(strcmp(option, "-cursor") == 0) {
                next_i = i + 1;
                perlcs->hCursor = (HCURSOR) handle_From(NOTXSCALL ST(next_i));

            } else if(strncmp(option, "-on", 3) == 0
            && (char) option[3] >= 'A' && (char) option[3] <= 'Z') {
                next_i = i + 1;
                {
                    char *eventname;
#ifdef PERLWIN32GUI_STRONGDEBUG
                    printf("!XS(ParseWindowOptions): initializing perlcs.hvEvents\n");
#endif
                    if(perlcs->hvEvents == NULL) {
                        perlcs->hvEvents = newHV();
                        perlcs->dwEventMask = 0;
                    }
                    eventname = option+3;
#ifdef PERLWIN32GUI_STRONGDEBUG
                    printf("!XS(ParseWindowOptions): calling ParseNEMEvent('%s', '%s')\n", eventname, SvPV_nolen(ST(next_i)));
#endif
                    ParseNEMEvent( NOTXSCALL perlcs, eventname, ST(next_i) );
                }

                SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_NEM, (perlcs->dwEventMask != 0));

            } else if(strcmp(option, "-eventmodel") == 0) {
                next_i = i + 1;
                if(stricmp(SvPV_nolen(ST(next_i)), "byname") == 0) {
                    SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_NEM, 0);
                    SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_OEM, 1);
                } else if(stricmp(SvPV_nolen(ST(next_i)), "byref") == 0) {                    
                    SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_NEM, 1);
                    SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_OEM, 0);
                } else if(stricmp(SvPV_nolen(ST(next_i)), "both") == 0) {
                    SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_NEM, 1);
                    SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_OEM, 1);
                } else {
                    W32G_WARN("Win32::GUI: Invalid value for -eventmodel!");
                }
            } else BitmaskOption("-visible", perlcs->cs.style, WS_VISIBLE)
            } else BitmaskOption("-disabled", perlcs->cs.style, WS_DISABLED)
            } else BitmaskOption("-group", perlcs->cs.style, WS_GROUP)
            } else BitmaskOption("-tabstop", perlcs->cs.style, WS_TABSTOP)
            } else BitmaskOption("-hscroll", perlcs->cs.style, WS_HSCROLL)
            } else BitmaskOption("-vscroll", perlcs->cs.style, WS_VSCROLL)
            } else BitmaskOption("-acceptfiles", perlcs->cs.dwExStyle, WS_EX_ACCEPTFILES)
            } else BitmaskOption("-container", perlcs->dwPlStyle, PERLWIN32GUI_CONTAINER)
            }
            // ######################
            // class-specific parsing
            // ######################
            else if(OnParseOption[perlcs->iClass](NOTXSCALL option, ST(i+1), perlcs)) {
                next_i = i + 1;
            }
        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseMenuItemOptions(sp, mark, ax, items, from_i, mii, *item)
    */
void ParseMenuItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPMENUITEMINFO mii,
    LPPERLWIN32GUI_MENUITEMDATA perlmid,
    UINT* myItem
) {

    int i, next_i;
    char * option;
    STRLEN textlength;
    next_i = -1;
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(ParseMenuItemOptions) called with items=%d, from_i=%d\n", items, from_i);
#endif
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
#ifdef PERLWIN32GUI_STRONGDEBUG
            printf("!XS(ParseMenuItemOptions) got option '%s'\n", option);
#endif
            if(strcmp(option, "-mask") == 0) {
                next_i = i + 1;
                mii->fMask = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-flag") == 0) {
                next_i = i + 1;
                mii->fType = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-state") == 0) {
                SwitchBit(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                mii->fState = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-id") == 0) {
                SwitchBit(mii->fMask, MIIM_ID, 1);
                next_i = i + 1;
                mii->wID = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-submenu") == 0) {
                SwitchBit(mii->fMask, MIIM_SUBMENU, 1);
                next_i = i + 1;
                mii->hSubMenu = (HMENU) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-text") == 0) {
                SwitchBit(mii->fMask, MIIM_TYPE, 1);
                SwitchBit(mii->fType, MFT_STRING, 1);
                next_i = i + 1;
                mii->dwTypeData = SvPV(ST(next_i), textlength);
                mii->cch = textlength;
            } else if(strcmp(option, "-item") == 0) {
                next_i = i + 1;
                *myItem = SvIV(ST(next_i));
            } else if(strcmp(option, "-separator") == 0) {
                SwitchBit(mii->fMask, MIIM_TYPE, 1);
                next_i = i + 1;
                SwitchBit(mii->fType, MFT_SEPARATOR, SvIV(ST(next_i)));
            } else if(strcmp(option, "-menubarbreak") == 0) {
                SwitchBit(mii->fMask, MIIM_TYPE, 1);
                next_i = i + 1;
                SwitchBit(mii->fType, MFT_MENUBARBREAK, SvIV(ST(next_i)));
            } else if(strcmp(option, "-menubreak") == 0) {
                SwitchBit(mii->fMask, MIIM_TYPE, 1);
                next_i = i + 1;
                SwitchBit(mii->fType, MFT_MENUBREAK, SvIV(ST(next_i)));
            } else if(strcmp(option, "-radiocheck") == 0) {
                SwitchBit(mii->fMask, MIIM_TYPE, 1);
                next_i = i + 1;
                SwitchBit(mii->fType, MFT_RADIOCHECK, SvIV(ST(next_i)));
            } else if(strcmp(option, "-default") == 0) {
                SwitchBit(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                SwitchBit(mii->fState, MFS_DEFAULT, SvIV(ST(next_i)));
            } else if(strcmp(option, "-checked") == 0) {
                SwitchBit(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                SwitchBit(mii->fState, MFS_CHECKED, SvIV(ST(next_i)));
            } else if(strcmp(option, "-enabled") == 0) {
                SwitchBit(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                SwitchBit(mii->fState, MFS_DISABLED, !SvIV(ST(next_i)));
            } else if(strcmp(option, "-name") == 0) {
                next_i = i + 1;
#ifdef PERLWIN32GUI_STRONGDEBUG
                printf("!XS(ParseMenuItemOptions) got -name => '%s'\n", SvPV_nolen(ST(next_i)));
#endif
                strcpy( (perlmid->szName), SvPV_nolen(ST(next_i)) );
                SwitchBit(mii->fMask, MIIM_DATA, 1);
                mii->dwItemData = (ULONG_PTR) perlmid;
#ifdef PERLWIN32GUI_STRONGDEBUG
                printf("!XS(ParseMenuItemOptions) done -name ('%s')\n", perlmid->szName);
#endif
            } else if(strcmp(option, "-onClick") == 0) {
                next_i = i + 1;
#ifdef PERLWIN32GUI_STRONGDEBUG
                printf("!XS(ParseMenuItemOptions) got -onClick => '%s'\n", SvPV_nolen(ST(next_i)));
#endif
                SwitchBit(mii->fMask, MIIM_DATA, 1);
                /* perlmid->svCode = newSVsv(ST(next_i)); */
                sv_setsv(perlmid->svCode, ST(next_i));
                mii->dwItemData = (ULONG_PTR) perlmid;
#ifdef PERLWIN32GUI_STRONGDEBUG
                printf("!XS(ParseMenuItemOptions) done -onClick newSVsv\n");
#endif
            }
        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseHeaderItemOptions(sp, mark, ax ,items, from_i, *hditem, *index)
    */
void ParseHeaderItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPHDITEMA hditem,
    int * index
) {

    int i, next_i;
    char * option;
    STRLEN tlen;

    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                hditem->pszText = SvPV(ST(next_i), tlen);
                hditem->cchTextMax = tlen;
                SwitchBit(hditem->mask, HDI_TEXT, 1);
                SwitchBit(hditem->mask, HDI_FORMAT, 1);
                SwitchBit(hditem->fmt, HDF_STRING, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                hditem->iImage = SvIV(ST(next_i));
                SwitchBit(hditem->mask, HDI_IMAGE, 1);
                SwitchBit(hditem->mask, HDI_FORMAT, 1);
                SwitchBit(hditem->fmt, HDF_IMAGE, 1);
            } else if(strcmp(option, "-bitmap") == 0) {
                next_i = i + 1;
                hditem->hbm = (HBITMAP) handle_From(NOTXSCALL ST(next_i));
                SwitchBit(hditem->mask, HDI_BITMAP, 1);
                SwitchBit(hditem->mask, HDI_FORMAT, 1);
                SwitchBit(hditem->fmt, HDF_BITMAP, 1);
            } else if(strcmp(option, "-bitmaponright") == 0) {
                next_i = i + 1;
                SwitchBit(hditem->fmt, HDF_BITMAP_ON_RIGHT, SvIV(ST(next_i)));
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                hditem->cxy = SvIV(ST(next_i));
                SwitchBit(hditem->mask, HDI_WIDTH, 1);
                SwitchBit(hditem->mask, HDI_HEIGHT, 0);
            } else if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                hditem->cxy = SvIV(ST(next_i));
                SwitchBit(hditem->mask, HDI_WIDTH, 0);
                SwitchBit(hditem->mask, HDI_HEIGHT, 1);
            } else if(strcmp(option, "-order") == 0) {
                next_i = i + 1;
                hditem->iOrder = SvIV(ST(next_i));
                SwitchBit(hditem->mask, HDI_ORDER, 1);
            } else if(strcmp(option, "-align") == 0) {
                next_i = i + 1;
                SwitchBit(hditem->mask, HDI_FORMAT, 1);
                if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                    SwitchBit(hditem->fmt, HDF_LEFT, 1);
                    SwitchBit(hditem->fmt, HDF_CENTER, 0);
                    SwitchBit(hditem->fmt, HDF_RIGHT, 0);
                } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                    SwitchBit(hditem->fmt, HDF_LEFT, 0);
                    SwitchBit(hditem->fmt, HDF_CENTER, 1);
                    SwitchBit(hditem->fmt, HDF_RIGHT, 0);
                } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                    SwitchBit(hditem->fmt, HDF_LEFT, 0);
                    SwitchBit(hditem->fmt, HDF_CENTER, 0);
                    SwitchBit(hditem->fmt, HDF_RIGHT, 1);
                } else {
                    W32G_WARN("Win32::GUI: Invalid value for -align!");
                }
            } else if(strcmp(option, "-item") == 0 || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                *index = SvIV(ST(next_i));
            }

        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseListViewColumnItemOptions(sp, mark, ax ,items, from_i, *lvcolumn, *iCol)
    */
void ParseListViewColumnItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPLVCOLUMNA lvcolumn,
    int * iCol
) {

    int i, next_i;
    char * option;
    STRLEN tlen;

    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                lvcolumn->pszText = SvPV(ST(next_i), tlen);
                lvcolumn->cchTextMax = tlen;
                lvcolumn->mask |= LVCF_TEXT;
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                lvcolumn->iImage = SvIV(ST(next_i));
                lvcolumn->mask |= LVCF_IMAGE;
            } else if(strcmp(option, "-bitmaponright") == 0) {
                next_i = i + 1;
                SwitchBit(lvcolumn->fmt, LVCFMT_BITMAP_ON_RIGHT, SvIV(ST(next_i)));
                lvcolumn->mask |= LVCF_FMT;
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                lvcolumn->cx = SvIV(ST(next_i));
                lvcolumn->mask |= LVCF_WIDTH;
            } else if(strcmp(option, "-order") == 0) {
                next_i = i + 1;
                lvcolumn->iOrder = SvIV(ST(next_i));
                lvcolumn->mask |= LVCF_ORDER;
            } else if(strcmp(option, "-align") == 0) {
                next_i = i + 1;
                lvcolumn->mask |= LVCF_FMT;
                if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                    lvcolumn->fmt = LVCFMT_LEFT;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                    lvcolumn->fmt = LVCFMT_CENTER;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                    lvcolumn->fmt = LVCFMT_RIGHT;
                } else {
                    W32G_WARN("Win32::GUI: Invalid value for -align!");
                }
            } else if(strcmp(option, "-item") == 0 || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                *iCol = SvIV(ST(next_i));
            } else if(strcmp(option, "-subitem") == 0) {
                next_i = i + 1;
                lvcolumn->iSubItem = SvIV(ST(next_i));
                lvcolumn->mask |= LVCF_SUBITEM;
            }
        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseRebarBandOptions(sp, mark, ax ,items, from_i, *rbbi, *index)
    */
void ParseRebarBandOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPREBARBANDINFO rbbi,
    int * index) {
    
    int i, next_i;
    char * option;
    STRLEN tlen;

    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                rbbi->iImage = SvIV(ST(next_i));
                rbbi->fMask |= RBBIM_IMAGE;
            } else if(strcmp(option, "-index") == 0) {
                next_i = i + 1;
                *index = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-bitmap") == 0) {
                next_i = i + 1;
                rbbi->hbmBack = (HBITMAP) handle_From(NOTXSCALL ST(next_i));
                rbbi->fMask |= RBBIM_BACKGROUND;
            } else if(strcmp(option, "-child") == 0) {
                next_i = i + 1;
                rbbi->hwndChild = (HWND) handle_From(NOTXSCALL ST(next_i));
                rbbi->fMask |= RBBIM_CHILD;
            } else if(strcmp(option, "-foreground") == 0) {
                next_i = i + 1;
                rbbi->clrFore = SvCOLORREF(NOTXSCALL ST(next_i));
                rbbi->fMask |= RBBIM_COLORS;
            } else if(strcmp(option, "-background") == 0) {
                next_i = i + 1;
                rbbi->clrBack = SvCOLORREF(NOTXSCALL ST(next_i));
                rbbi->fMask |= RBBIM_COLORS;
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                rbbi->cx = SvIV(ST(next_i));
                rbbi->fMask |= RBBIM_SIZE;
            } else if(strcmp(option, "-minwidth") == 0) {
                next_i = i + 1;
                rbbi->cxMinChild = SvIV(ST(next_i));
                rbbi->fMask |= RBBIM_CHILDSIZE;
            } else if(strcmp(option, "-minheight") == 0) {
                next_i = i + 1;
                rbbi->cyMinChild = SvIV(ST(next_i));
                rbbi->fMask |= RBBIM_CHILDSIZE;
            } else if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                rbbi->lpText = SvPV(ST(next_i), tlen);
                rbbi->cch = tlen;
                rbbi->fMask |= RBBIM_TEXT;
            } else if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                rbbi->fStyle = SvIV(ST(next_i));
                rbbi->fMask |= RBBIM_STYLE;
            } else if(strcmp(option, "-idealwidth") == 0) {
                next_i = i + 1;
                rbbi->cxIdeal = SvIV(ST(next_i));
                rbbi->fMask |= RBBIM_IDEALSIZE;
            }
        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseComboboxExItemOptions(sp, mark, ax ,items, from_i, *item)
    */
void ParseComboboxExItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    COMBOBOXEXITEM *item
) {

    int i, next_i;
    char * option;
    STRLEN tlen;

    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                item->pszText = SvPV(ST(next_i), tlen);
                item->cchTextMax = tlen;
                SwitchBit(item->mask, CBEIF_TEXT, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                item->iImage = SvIV(ST(next_i));
                SwitchBit(item->mask, CBEIF_IMAGE, 1);
            } else if(strcmp(option, "-selectedimage") == 0) {
                next_i = i + 1;
                item->iSelectedImage = SvIV(ST(next_i));
                SwitchBit(item->mask, CBEIF_SELECTEDIMAGE, 1);
            } else
            if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                item->iItem = SvIV(ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseTooltipOptions(sp, mark, ax ,items, from_i, *item)
    */
void ParseTooltipOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    TOOLINFO  *ti) {

    int i, next_i;
    char * option;

	ti->uFlags |= TTF_IDISHWND;
	ti->uFlags |= TTF_SUBCLASS;
    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                if(SvPOK(ST(next_i))) 
                    ti->lpszText = SvPV_nolen(ST(next_i));
                else if (SvIOK(ST(next_i)))
                    ti->lpszText = MAKEINTRESOURCE((WORD)SvIV(ST(next_i)));
            } else if(strcmp(option, "-needtext") == 0) {
                next_i = i + 1;
                ti->lpszText = (SvIV(ST(next_i)) ? LPSTR_TEXTCALLBACK : NULL);
            } else if(strcmp(option, "-window") == 0) {
                next_i = i + 1;
                ti->hwnd  = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-id") == 0) {
                next_i = i + 1;
                ti->uId = SvIV(ST(next_i));
                ti->uFlags &= ~TTF_IDISHWND;
            } else if(strcmp(option, "-hinst") == 0) {
                next_i = i + 1;
                ti->hinst = INT2PTR(HINSTANCE,SvIV(ST(next_i)));
            } else if(strcmp(option, "-flags") == 0) {
                next_i = i + 1;
                ti->uFlags = SvIV(ST(next_i));
            } else if(strcmp(option, "-absolute") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_ABSOLUTE , SvIV(ST(next_i)));
            } else if(strcmp(option, "-centertip") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_CENTERTIP , SvIV(ST(next_i)));
            } else if(strcmp(option, "-idishwnd") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_IDISHWND , SvIV(ST(next_i)));
            } else if(strcmp(option, "-rtlreading") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_RTLREADING , SvIV(ST(next_i)));
            } else if(strcmp(option, "-subclass") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_SUBCLASS , SvIV(ST(next_i)));
            } else if(strcmp(option, "-track") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_TRACK , SvIV(ST(next_i)));
                ti->uFlags &= ~TTF_SUBCLASS;
            } else if(strcmp(option, "-transparent") == 0) {
                next_i = i + 1;
                SwitchBit(ti->uFlags, TTF_TRANSPARENT , SvIV(ST(next_i)));
            } else if(strcmp(option, "-rect") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    AV* av = (AV*)SvRV(ST(next_i));
                    SV**t = av_fetch(av, 0, 0);
                    if (t != NULL) ti->rect.left = SvIV(*t);
                    t = av_fetch(av, 1, 0);
                    if (t != NULL) ti->rect.top = SvIV(*t);
                    t = av_fetch(av, 2, 0);
                    if (t != NULL) ti->rect.right = SvIV(*t);
                    t = av_fetch(av, 3, 0);
                    if (t != NULL) ti->rect.bottom = SvIV(*t);
                }
            }
        } else {
            next_i = -1;
        }
    }

	if( ti->uFlags & TTF_IDISHWND) {
		ti->uId = (UINT_PTR)(ti->hwnd);  /* TODO: can hwnd be NULL? */
	} else {
		/* if rect not supplied, use hwnd co-ordinates */
		if(ti->rect.left == 0 && ti->rect.right == 0 && ti->rect.top == 0 && ti->rect.bottom == 0) {
			GetWindowRect(ti->hwnd, &(ti->rect));
		}
	}

    /* If we're not a top level window, then we
     * need our container flag set in order to process
     * WM_NOTIFY messages correctly (see CustomMsgLoop)
     * Needed for NeedText, Pop and Show events
     */
    HWND parent = GetAncestor(ti->hwnd, GA_PARENT);
    if(parent) {
        LPPERLWIN32GUI_USERDATA ud;
        ud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(ti->hwnd, GWLP_USERDATA);
        if( ValidUserData(ud) ) {
                ud->dwPlStyle |= PERLWIN32GUI_CONTAINER;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseNEMNotifyIconEvent(hvEvents, name, event)
    */

void ParseNEMNotifyIconEvent(
    NOTXSPROC
    HV* hvEvents,
    char *name,
    SV* event) {

    int eventID = 0;

    if(strcmp(name, "Click") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL1;
    } else if(strcmp(name, "DblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL2;
    } else if(strcmp(name, "RightClick") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL1;
    } else if(strcmp(name, "RightDblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL2;
    } else if(strcmp(name, "MiddleClick") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL1;
    } else if(strcmp(name, "MiddleDblClick") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL2;
    } else if(strcmp(name, "MouseEvent") == 0) {
        eventID = PERLWIN32GUI_NEM_CONTROL3;
    }

    if(eventID != 0) {
        // Clear current event if necessary
        if ( hv_exists(hvEvents, name, strlen(name)) )         
            hv_delete(hvEvents, name, strlen(name),G_DISCARD);
        // Store event
        if(SvOK(event)) {
            SV* newval = newSVsv(event);
            hv_store(hvEvents, name, strlen(name), newval, 0);
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseNotifyIconOptions(sp, mark, ax ,items, from_i, *nid)
    */
void ParseNotifyIconOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    NOTIFYICONDATA *nid) {

    int i, next_i;
    char * option;
    SV* shversion;
    UINT version = 0;

    HV* hvEvents = NULL;

    shversion = get_sv("Win32::GUI::NotifyIcon::SHELLDLL_VERSION",0);
    if(shversion != NULL) {
       version = (UINT)SvIV(shversion);
#if (_WIN32_IE >= 0x0500) && (_WIN32_IE < 0x0600)
       if (version >= 5) {
           nid->cbSize = sizeof(NOTIFYICONDATA);
       }
#endif
#if (_WIN32_IE >= 0x0600)
       if (version >= 5) {
           nid->cbSize = NOTIFYICONDATA_V2_SIZE;
       }
       if (version >= 6) {
           nid->cbSize = sizeof(NOTIFYICONDATA);
       }
#endif
    }
    
    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-id") == 0) {
                next_i = i + 1;
                nid->uID = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-icon") == 0) {
                next_i = i + 1;
                nid->hIcon = (HICON) handle_From(NOTXSCALL ST(next_i));
                SwitchBit(nid->uFlags, NIF_ICON, 1);
            } else if(strcmp(option, "-tip") == 0) {
                next_i = i + 1;
		if( version < 5 ) {
		    strncpy(nid->szTip, SvPV_nolen(ST(next_i)), 64);
		    nid->szTip[63] = '\0';
		} else {
		    strncpy(nid->szTip, SvPV_nolen(ST(next_i)), 128);
		    nid->szTip[127] = '\0';
		}
                SwitchBit(nid->uFlags, NIF_TIP, 1);
            } else if(strcmp(option, "-events") == 0) {
                next_i = i + 1;
                {
                    HV* hash;
                    SV* val;
                    char* key;
                    I32 keylen;
                    
                    if (hvEvents == NULL)
                        hvEvents = newHV();
                    
                    hash = (HV*) SvRV(ST(next_i));
                    hv_iterinit( hash );
                    while ( val = hv_iternextsv( hash, &key, &keylen ) ) {
                        ParseNEMNotifyIconEvent( NOTXSCALL hvEvents, key, val );
                    }
                }
            } else if(strncmp(option, "-on", 3) == 0 && (char) option[3] >= 'A' && (char) option[3] <= 'Z') {
                next_i = i + 1;
                
                if (hvEvents == NULL)
                    hvEvents = newHV();

                ParseNEMNotifyIconEvent( NOTXSCALL hvEvents, option+3, ST(next_i) );
            } else if(strcmp(option, "-behaviour") == 0) {
                next_i = i + 1;
		if (SvIV(ST(next_i))) {
			nid->uVersion = NOTIFYICON_VERSION;
		}
            } else if(strcmp(option, "-balloon") == 0) {
                next_i = i + 1;
                SwitchBit(nid->uFlags, NIF_INFO, SvIV(ST(next_i)));
            } else if(strcmp(option, "-balloon_tip") == 0) {
                next_i = i + 1;
		strncpy(nid->szInfo, SvPV_nolen(ST(next_i)), 256);
		nid->szInfo[255] = '\0';
            } else if(strcmp(option, "-balloon_title") == 0) {
                next_i = i + 1;
		strncpy(nid->szInfoTitle, SvPV_nolen(ST(next_i)), 64);
		nid->szInfoTitle[63] = '\0';
            } else if(strcmp(option, "-balloon_timeout") == 0) {
                next_i = i + 1;
                nid->uTimeout = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-balloon_icon") == 0) {
                next_i = i + 1;
                if(strcmp(SvPV_nolen(ST(next_i)), "error") == 0) {
                    nid->dwInfoFlags = NIIF_ERROR;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "info") == 0) {
                    nid->dwInfoFlags = NIIF_INFO;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "warning") == 0) {
                    nid->dwInfoFlags = NIIF_WARNING;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "none") == 0) {
                    nid->dwInfoFlags = NIIF_NONE;
                } else {
                    W32G_WARN("Win32::GUI: Invalid value for -balloon_icon!");
                }
            }
        } else {
            next_i = -1;
        }
    }
    
    // if we found events, store it into parent window.
    if (hvEvents != NULL) {
        
        SV* svParent = SV_SELF_FROM_WINDOW (nid->hWnd);
        if (svParent != NULL && nid->uID != 0) {

            char NotifyIconName[MAX_EVENT_NAME];

            // Convert NotifyIcon id to string
            itoa(nid->uID, NotifyIconName, 10);
            // Get window notifyicons Hash
            SV** notifyicons = hv_fetch_mg(NOTXSCALL (HV*)SvRV(svParent), "-notifyicons", 12, FALSE);
            if(notifyicons != NULL && SvROK(*notifyicons) ) {
                // Get notifyicon name
                SV** name = hv_fetch_mg(NOTXSCALL (HV*) SvRV(*notifyicons), NotifyIconName, strlen(NotifyIconName), FALSE);
                if(name != NULL) {
                    strcpy(NotifyIconName, (char *) SvPV_nolen(*name));
                    // Get notifyicon object from parent
                    SV** notifyicon = hv_fetch_mg(NOTXSCALL (HV*) SvRV(svParent), NotifyIconName, strlen(NotifyIconName), FALSE);
                    if(notifyicon != NULL && SvROK(*notifyicon)) { 
                        // Get NEM Events Hash
                        sv** events = hv_fetch_mg(NOTXSCALL (HV*) SvRV(*notifyicon), "-events", 7, FALSE);
                        // Already have an event hash, so merge 2 hash
                        if (events != NULL && SvROK(*events)) {
                            SV* val;
                            char* key;
                            I32 keylen;
                            hv_iterinit( hvEvents );
                            while ( val = hv_iternextsv( hvEvents, &key, &keylen ) ) {
                                if ( hv_exists((HV*) SvRV(*events), key, keylen) )
                                    hv_delete((HV*) SvRV(*events), key, keylen, G_DISCARD); 
                                hv_store_mg(NOTXSCALL (HV*) SvRV(*events), key, keylen, newSVsv(val), 0);
                            }
                        }
                        // Not exists so add it.
                        else {
                            hv_store_mg(NOTXSCALL (HV*) SvRV(*notifyicon), "-events", 7, newRV_noinc((SV*) hvEvents), 0);
                            hvEvents = NULL;  // don't free it.
                        }
                    }
                }
            }
        }
    }

    // Free if not use.
    if (hvEvents != NULL)
        SvREFCNT_dec(hvEvents);
}
