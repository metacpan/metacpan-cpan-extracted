        /*
    ###########################################################################
    # helper routines
    #
    # $Id: GUI_Helpers.cpp,v 1.28 2011/07/16 14:51:03 acalpini Exp $
    #
    ###########################################################################
        */

#include "GUI.h"

/*
 * Create callback control table
 * Warning : Use some order than WIN32__GUI__* constant value
 */
#define CREATE_CONTROL_TABLE(n,T) \
 T = { \
    Window##n,      \
    DialogBox##n,   \
    Label##n,       \
    Button##n,      \
    Textfield##n,   \
    Listbox##n,     \
    Combobox##n,    \
    Checkbox##n,    \
    RadioButton##n, \
    Groupbox##n,    \
    Toolbar##n,     \
    ProgressBar##n, \
    StatusBar##n,   \
    TabStrip##n,    \
    RichEdit##n,    \
    ListView##n,    \
    TreeView##n,    \
    Trackbar##n,    \
    UpDown##n,      \
    Tooltip##n,     \
    Animation##n,   \
    Rebar##n,       \
    Header##n,      \
    ComboboxEx##n,  \
    DateTime##n,    \
    Graphic##n,     \
    Splitter##n,    \
    MDIFrame##n,    \
    MDIClient##n,   \
    MDIChild##n,    \
    MonthCal##n     \
    };

/*
 * Create callback table (Probably nicer to turn into plugin API)
 */
CREATE_CONTROL_TABLE(_onPreCreate,   void (*OnPreCreate[])(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT));
CREATE_CONTROL_TABLE(_onParseOption, BOOL (*OnParseOption[])(NOTXSPROC char *, SV*,LPPERLWIN32GUI_CREATESTRUCT));
CREATE_CONTROL_TABLE(_onPostCreate,  void (*OnPostCreate[])(NOTXSPROC HWND, LPPERLWIN32GUI_CREATESTRUCT));
CREATE_CONTROL_TABLE(_onParseEvent,  BOOL (*OnParseEvent[])(NOTXSPROC char*, int*));
CREATE_CONTROL_TABLE(_onEvent,       int  (*OnEvent[])(NOTXSPROC LPPERLWIN32GUI_USERDATA, UINT, WPARAM , LPARAM));


/*
 * Free perlud structure
 */
void Perlud_Free(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud) {

    // Check perlpud
    if (perlud != NULL) {
        HWND hwnd_self = SvOK(perlud->svSelf) ? handle_From(NOTXSCALL perlud->svSelf) : NULL;

        // Free event hash
        if (perlud->hvEvents != NULL) {
            // Test ref-count - warn if not one
            if(SvREFCNT(perlud->hvEvents) != 1)
                W32G_WARN("hvEvents ref count not 1 during destruction - please report this");

            SvREFCNT_dec(perlud->hvEvents);
            perlud->hvEvents = NULL;
        }
        // Free hook hash
        if (perlud->avHooks != NULL) {
            // Test ref-count - warn if not one
            if(SvREFCNT(perlud->avHooks) != 1)
                W32G_WARN("avHooks ref count not 1 during destruction - please report this");

            SvREFCNT_dec(perlud->avHooks);
            perlud->avHooks = NULL;
        }
        // Free self
        if (perlud->svSelf != NULL && SvREFCNT(perlud->svSelf) > 0) {
            /* Free into parent */
            if(SvOK(perlud->svSelf)) {
                HWND parent = GetParent(hwnd_self);
                if (parent != NULL && *perlud->szWindowName != '\0')  {
                    SV* SvParent = SV_SELF_FROM_WINDOW(parent);
                    if (SvParent != NULL && SvROK(SvParent)) {
                        /* During global destruction it is possible that the
                         * underlying object supporting our tied hash is
                         * destroyed before the object itself, this results in
                         * fatal errors "(during cleanup) Can't call method
                         * "DELETE" on an undefined value" - so we check that
                         * the tied magic is still there before we try to
                         * delete from the parent
                         */
                        MAGIC* mg;
                        if ( (mg = mg_find(SvRV(SvParent), PERL_MAGIC_tied)) && SvROK(mg->mg_obj) ) {
                            hv_delete((HV*) SvRV(SvParent), perlud->szWindowName,
                                        strlen(perlud->szWindowName), G_DISCARD);
                        }
                    }
                }
            }
            SvREFCNT_dec(perlud->svSelf);
            perlud->svSelf = NULL;
        }

        // If we stored a hash in userData, drop it's
        // ref count to free it (and it's members)
        if (perlud->userData != NULL) {
            // Test ref-count - warn if not one
            if(SvREFCNT(perlud->userData) != 1)
                W32G_WARN("userData ref count not 1 during destruction - please report this");

            SvREFCNT_dec(perlud->userData);
            perlud->userData = NULL;
        }

        // If we stored a brush, destroy it
        if (perlud->bDeleteBackgroundBrush && perlud->hBackgroundBrush != NULL) {
                DeleteObject((HGDIOBJ) perlud->hBackgroundBrush);
        }

        // If we stored an original wndproc, then restore it so that
        // WM_NCDESTORY messages get there.
        if (hwnd_self && perlud->WndProc) {
            SetWindowLongPtr(hwnd_self, GWLP_WNDPROC, (LONG_PTR)(perlud->WndProc));
        }
        
        // Free perlpud
        safefree (perlud);
    }
}

SV *
SV_SELF_FROM_WINDOW(HWND hwnd) {
    LPPERLWIN32GUI_USERDATA perlud;

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        return perlud->svSelf;
    } else {
        return NULL;
    }
}

static void
hv_magic_check (NOTXSPROC HV *hv, bool *needs_copy, bool *needs_store)
{
    MAGIC *mg = SvMAGIC(hv);
    *needs_copy = FALSE;
    *needs_store = TRUE;
    while (mg) {
        if (isUPPER(mg->mg_type)) {
            *needs_copy = TRUE;
            switch (mg->mg_type) {
            case 'P':
            case 'S':
                *needs_store = FALSE;
            }
        }
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(hv_magic_check) magic='%c' needs_store='%d'\n", mg->mg_type, *needs_store);
#endif
        mg = mg->mg_moremagic;
    }
}

SV**
hv_fetch_mg(NOTXSPROC HV *hv, char *key, U32 klen, I32 lval) {
        SV** tempsv;
        tempsv = hv_fetch(hv, key, klen, lval);
        if(SvMAGICAL(hv)) mg_get(*tempsv);
        return tempsv;
}

SV**
hv_store_mg(NOTXSPROC HV *hv, char *key, U32 klen, SV* val, U32 hash) {
        SV** tempsv;
        tempsv = hv_store(hv, key, klen, val, hash);
        if(SvMAGICAL(hv)) mg_set(val);
        return tempsv;
}

    /*
     ##########################################################################
     # (@)INTERNAL:handle_From(SV*)
     # gets the handle from either the blessed object
     # or the SV passed
     */
HWND handle_From(NOTXSPROC SV *pSv) {
    HWND hReturn = 0;
     //printf("handle_From %p \n",pSv);

    if(NULL != pSv)  {
        if( SvROK(pSv)) {
            SV **pHv;
            //sv_dump(SvRV(pSv));
            pHv = hv_fetch_mg(NOTXSCALL (HV*) SvRV(pSv), "-handle", 7, 0);
            if(pHv != NULL) {

                hReturn = INT2PTR(HWND,SvIV(*pHv));
                //printf("hReturn(1) is %i \n",hReturn);
            }
        } else {
            hReturn = INT2PTR(HWND,SvIV(pSv));
            //printf("hReturn(2) is %i \n",hReturn);
        }
    }
    return(hReturn);
}

    /*
     ##########################################################################
     # (@)INTERNAL:classname_From(SV*)
     # gets the window class name from either the blessed object
     # or the SV passed
     */
char *classname_From(NOTXSPROC SV *pSv) {
    char *pszName = NULL;

    if(NULL != pSv) {
        if(SvROK(pSv)) {
            SV **pHv;
            pHv = hv_fetch_mg(NOTXSCALL (HV*) SvRV(pSv), "-name", 5, 0);
            if(pHv != NULL) {
                pszName = SvPV_nolen(*pHv);
            }
        } else {
            pszName = SvPV_nolen(pSv);
        }
    }
    return(pszName);
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetDefClassProc( *name)
     */
WNDPROC GetDefClassProc (NOTXSPROC const char *Name) {

    HV* hash;
    SV** wndproc;

    hash = perl_get_hv("Win32::GUI::DefClassProc", FALSE);
    wndproc = hv_fetch_mg(NOTXSCALL hash, (char*) Name, strlen(Name), FALSE);
    if(wndproc == NULL) return NULL;
    return INT2PTR(WNDPROC,SvIV(*wndproc));
}

    /*
     ##########################################################################
     # (@)INTERNAL:SetDefClassProc( *name, defproc )
     */
BOOL SetDefClassProc (NOTXSPROC const char *Name, WNDPROC DefClassProc) {

    HV* hash    = perl_get_hv("Win32::GUI::DefClassProc", FALSE);
    return (hv_store_mg(NOTXSCALL hash, (char*) Name, strlen(Name), newSViv(PTR2IV(DefClassProc)), 0) != NULL);
}

    /*
     ##########################################################################
     # (@)INTERNAL:SvCOLORREF(SV*)
     # returns a COLORREF from either a numerical value
     # or a color expressed as [RR, GG, BB]
     # or a color expressed in HTML notation (#RRGGBB)
     */
COLORREF SvCOLORREF(NOTXSPROC SV* c) {
    SV** t;
    int r;
    int g;
    int b;
    char html_color[8];
    char html_color_component[3];

    ZeroMemory(html_color, 8);
    ZeroMemory(html_color_component, 3);
    r = 0;
    g = 0;
    b = 0;
    if(SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVAV) {
        t = av_fetch((AV*)SvRV(c), 0, 0);
        if(t != NULL) {
            r = SvIV(*t);
        }
        t = av_fetch((AV*)SvRV(c), 1, 0);
        if(t!= NULL) {
            g = SvIV(*t);
        }
        t = av_fetch((AV*)SvRV(c), 2, 0);
        if(t != NULL) {
            b = SvIV(*t);
        }
        return RGB((BYTE) r, (BYTE) g, (BYTE) b);
    } else {
        if(SvPOK(c)) {
            strncpy(html_color, SvPV_nolen(c), 7);
            if(strncmp(html_color, "#", 1) == 0) {
                strncpy(html_color_component, html_color+1, 2);
                *(html_color_component+2) = 0;
                sscanf(html_color_component, "%x", &r);
                strncpy(html_color_component, html_color+3, 2);
                *(html_color_component+2) = 0;
                sscanf(html_color_component, "%x", &g);
                strncpy(html_color_component, html_color+5, 2);
                *(html_color_component+2) = 0;
                sscanf(html_color_component, "%x", &b);
                return RGB((BYTE) r, (BYTE) g, (BYTE) b);
            } else {
                return (COLORREF) SvIV(c);
            }
        } else {
            return (COLORREF) SvIV(c);
        }
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:CreateTooltip(parent)
     */
HWND CreateTooltip(
                   NOTXSPROC
                   HV* parent
                   ) {
    HWND hTooltip;
    HWND hParent;
    SV** t;

    t = hv_fetch_mg(NOTXSCALL parent, "-handle", 7, 0);
    if(t != NULL) {
        hParent = INT2PTR(HWND,SvIV(*t));
    } else {
        return NULL;
    }

    hTooltip = CreateWindowEx(
        0, TOOLTIPS_CLASS, NULL,
        WS_POPUP | TTS_NOPREFIX | TTS_ALWAYSTIP,
        CW_USEDEFAULT, CW_USEDEFAULT,
        CW_USEDEFAULT, CW_USEDEFAULT,
        hParent, NULL, NULL,
        NULL
        );
    if(hTooltip != NULL) {
        SetWindowPos(
            hTooltip, HWND_TOPMOST,0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE
            );
        hv_store_mg(NOTXSCALL parent, "-tooltip", 8, newSViv(PTR2IV(hTooltip)), 0);
    }
    return hTooltip;
}

    /*
     ##########################################################################
     # (@)INTERNAL:CalcControlSize(*perlcs, add_x, add_y)
     # Used by some control to automatically set width and height at creation
     # time.
     */
void CalcControlSize(
    NOTXSPROC
    LPPERLWIN32GUI_CREATESTRUCT perlcs,
    int add_x,
    int add_y) {

    SIZE mySize;
    HDC hdc;
    SV** font;
    HFONT hfont, oldhfont;
    if(perlcs->cs.lpszName != NULL) {
        if(perlcs->cs.cx == 0 || perlcs->cs.cy == 0) {
            hdc = GetDC(perlcs->cs.hwndParent);
            if(perlcs->hFont != NULL) {
                hfont = perlcs->hFont;
            } else {
                hfont = (HFONT) GetStockObject(DEFAULT_GUI_FONT);
                if(perlcs->hvParent != NULL) {
                    font = hv_fetch_mg(NOTXSCALL perlcs->hvParent, "-font", 5, FALSE);
                    if(font != NULL && SvOK(*font)) {
                        hfont = (HFONT) handle_From(NOTXSCALL *font);
                    }
                }
            }
            oldhfont = (HFONT)SelectObject(hdc, hfont);
            if(GetTextExtentPoint32(
                hdc, perlcs->cs.lpszName, strlen(perlcs->cs.lpszName), &mySize
                )) {
                if(perlcs->cs.cx == 0) perlcs->cs.cx = mySize.cx + add_x;
                if(perlcs->cs.cy == 0) perlcs->cs.cy = mySize.cy + add_y;
            }
            SelectObject(hdc, oldhfont);
            ReleaseDC(perlcs->cs.hwndParent, hdc);
        }
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetObjectName(hwnd, *name)
     # Gets the object's name;
     # returns FALSE if no name found.
     */
BOOL GetObjectName(NOTXSPROC HWND hwnd, char *Name) {

    LPPERLWIN32GUI_USERDATA perlud;

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        if(NULL != perlud->szWindowName) {
            strcat(Name, (char *) perlud->szWindowName);
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        return FALSE;
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetObjectNameAndClass(hwnd, *name, *class)
     # Gets the object's name AND class (integer);
     # returns FALSE if no name found.
     */
BOOL GetObjectNameAndClass(NOTXSPROC HWND hwnd, char *Name, int *obj_class) {
    LPPERLWIN32GUI_USERDATA perlud;
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( ValidUserData(perlud) ) {
        if(NULL != perlud->szWindowName) {
            strcat(Name, (char *) perlud->szWindowName);
            *obj_class = perlud->iClass;
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        return FALSE;
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:CreateObjectWithHandle(char* class_name, HWND handle)
     # Create a bless object in specified class with -handle property set.
     */
SV* CreateObjectWithHandle(NOTXSPROC char* class_name, HWND handle) {
    HV* hv = newHV();
    hv_store(hv, "-handle", 7, newSViv(PTR2IV(handle)), 0);
    SV* cv = sv_2mortal(newRV((SV*)hv));
    sv_bless(cv, gv_stashpv(class_name, 0));
    SvREFCNT_dec(hv);
    return cv;
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetMenuFromID(ID, *name)
     # Gets the menu handle (HMENU) from the ID, searching in Perl's global
         # %Win32::GUI::Menus hash; returns NULL if the handle is not found.
     */
HMENU GetMenuFromID(NOTXSPROC int nID) {
    HV* hash;
    SV** handle;
    char temp[80];
    hash = perl_get_hv("Win32::GUI::Menus", FALSE);
    itoa(nID, temp, 10);
    handle = hv_fetch(hash, temp, strlen(temp), FALSE);
    if(handle == NULL) return NULL;
    return INT2PTR(HMENU,SvIV(*handle));
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetMenuName(ID, *name)
     # Gets the menu name from the ID;
     # returns FALSE if no name found.
     */
BOOL GetMenuName(NOTXSPROC HWND hwnd, int nID, char *Name) {
    MENUITEMINFO mii;
    HMENU hmenu;
    LPPERLWIN32GUI_MENUITEMDATA perlmid;
    ZeroMemory(&mii, sizeof(MENUITEMINFO));
    mii.cbSize = sizeof(MENUITEMINFO);
    mii.fMask = MIIM_DATA;
    /* HEURISTIC: assume the message was from the window's own menu */
    hmenu = GetMenu(hwnd);
    /* HEURISTIC: no, it wasn't, search in Perl's global hash  */
    if(hmenu == NULL) hmenu = GetMenuFromID( NOTXSCALL nID );
    /* HEURISTIC: if we can get to the item, it's ok, otherwise search in Perl's global hash  */
    if(GetMenuItemInfo( hmenu, nID, 0, &mii ) == 0) {
        hmenu = GetMenuFromID( NOTXSCALL nID );
    }
    if(GetMenuItemInfo( hmenu, nID, 0, &mii )) {
        perlmid = (LPPERLWIN32GUI_MENUITEMDATA) mii.dwItemData;
        if(perlmid != NULL && perlmid->dwSize == sizeof(PERLWIN32GUI_MENUITEMDATA)) {
            strcpy(Name, perlmid->szName);
            return TRUE;
        } else {
            return FALSE;
        }
    } else {
        return FALSE;
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetAcceleratorName(ID, *name)
     # Gets the accelerator name from the ID;
     # returns FALSE if no name found.
     */
BOOL GetAcceleratorName(NOTXSPROC int nID, char *Name) {
    HV* hash;
    SV** name;
    char temp[80];
    hash = perl_get_hv("Win32::GUI::Accelerators", FALSE);
    itoa(nID, temp, 10);
    name = hv_fetch_mg(NOTXSCALL hash, temp, strlen(temp), FALSE);
    if(name == NULL) return FALSE;
    strcpy(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetTimerName(hwnd, id, *name)
     # Gets the timer name;
     # returns FALSE if no name found.
     */
BOOL GetTimerName(NOTXSPROC HWND hwnd, UINT nID, char *Name) {
    HV*  parent;
    SV** name;
    SV** robjarray;
    HV*  objarray;
    SV** robj;
    HV*  obj;
    char temp[80];
    parent = HV_SELF_FROM_WINDOW(hwnd);
    if(parent == NULL) return FALSE;
    itoa(nID, temp, 10);
    robjarray = hv_fetch_mg(NOTXSCALL parent, "-timers", 7, FALSE);
    if(robjarray == NULL) return FALSE;
    objarray = (HV*) SvRV(*robjarray);
    robj = hv_fetch_mg(NOTXSCALL objarray, temp, strlen(temp), FALSE);
    if(robj == NULL) return FALSE;
    obj = (HV*) SvRV(*robj);
    if(obj == NULL) return FALSE;
    name = hv_fetch_mg(NOTXSCALL obj, "-name", 5, FALSE);
    if(name == NULL) return FALSE;
    strcpy(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetNotifyIconName(hwnd, id, *name)
     # Gets the NotifyIcon name;
     # returns FALSE if no name found.
     */
BOOL GetNotifyIconName(NOTXSPROC HWND hwnd, UINT nID, char *Name) {
    HV*  parent;
    SV** name;
    SV** robjarray;
    HV*  objarray;
    SV** robj;
    HV*  obj;
    char temp[80];
    parent = HV_SELF_FROM_WINDOW(hwnd);
    if(parent == NULL) return FALSE;
    itoa(nID, temp, 10);
    robjarray = hv_fetch_mg(NOTXSCALL parent, "-notifyicons", 12, FALSE);
    if(robjarray == NULL) return FALSE;
    objarray = (HV*) SvRV(*robjarray);
    robj = hv_fetch_mg(NOTXSCALL objarray, temp, strlen(temp), FALSE);
    if(robj == NULL) return FALSE;
    obj = (HV*) SvRV(*robj);
    name = hv_fetch_mg(NOTXSCALL obj, "-name", 5, FALSE);
    if(name == NULL) return FALSE;
    strcpy(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}


DWORD CALLBACK RichEditSave(DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG FAR *pcb) {
    HANDLE hfile;
    hfile = (HANDLE) dwCookie;
    WriteFile(hfile, (LPCVOID) pbBuff, (DWORD) cb, (LPDWORD) pcb, NULL);
    return(0);
}

DWORD CALLBACK RichEditLoad(DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG FAR *pcb) {
    HANDLE hfile;
    hfile = (HANDLE) dwCookie;
    ReadFile(hfile, (LPVOID) pbBuff, (DWORD) cb, (LPDWORD) pcb, NULL);
    return(0);
}

int CALLBACK BrowseForFolderProc(HWND hWnd, UINT uMsg, LPARAM lParam, LPARAM lpData) {
        UNREFERENCED_PARAMETER(lParam);

    if (uMsg == BFFM_INITIALIZED && lpData != 0) {
           SendMessage(hWnd, BFFM_SETSELECTION, TRUE, lpData);
    }
    return(0);
}

    /*
     ##########################################################################
     # (@)INTERNAL:AdjustSplitterCoord(self, x)
     */
int AdjustSplitterCoord(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int x, int w, HWND phwnd) {
    int min, max;
    int adjusted;
    RECT rc;
    adjusted = x;
    min = -1;
    min = perlud->iMinWidth;
    if(min == -1) min = 0;
    GetClientRect(phwnd, &rc);
    max = -1;
    max = perlud->iMaxWidth;
    if(max == -1) max = rc.right - w;
    if(adjusted < min) adjusted = min;
    if(adjusted > max) adjusted = max;
    return(adjusted);
}

    /*
     ##########################################################################
     # (@)INTERNAL:DrawSplitter(hwnd)
     */
void DrawSplitter(NOTXSPROC HWND hwnd, int x, int y, int w, int h) {

    static WORD _dotPatternBmp[8] = { 0x00aa, 0x0055, 0x00aa, 0x0055, 
                                      0x00aa, 0x0055, 0x00aa, 0x0055};

    HDC hdc;
    HBITMAP hbm;
    HBRUSH  hbr, hbrushOld;

    /* create a monochrome checkered pattern */
    hbm = CreateBitmap(8, 8, 1, 1, _dotPatternBmp);
    hbr = CreatePatternBrush(hbm);

    /* get a DC on which we can draw, even if the
     * class has CS_CLIPCHILDREN or the window
     * has WS_CLIPCHILDREN
     */
    hdc = GetDCEx(hwnd, NULL, DCX_PARENTCLIP);

    SetBrushOrgEx(hdc, x, y, NULL);
    hbrushOld = (HBRUSH)SelectObject(hdc, hbr);

    /* draw the checkered rectangle to the screen */
    PatBlt(hdc, x, y, w, h, PATINVERT);

    SelectObject(hdc, hbrushOld);

    ReleaseDC(hwnd, hdc);

    DeleteObject(hbr);
    DeleteObject(hbm);
}

    /*
     ##########################################################################
     # (@)INTERNAL:EnumMyWindowsProc(hwnd, lparam)
     */
BOOL CALLBACK EnumMyWindowsProc(HWND hwnd, LPARAM lparam) {
    dTHX;       /* fetch context */
    AV* ary;
    DWORD pid;

    ary = (AV*) lparam;
    GetWindowThreadProcessId(hwnd, &pid);
    if(pid == GetCurrentProcessId()) {
			av_push(ary, newSViv(PTR2IV(hwnd)));
    }
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:CountMyWindowsProc(hwnd, lparam)
     # specialized version of EnumMyWindowsProc for DoModal
     */
BOOL CALLBACK CountMyWindowsProc(HWND hwnd, LPARAM lparam) {
    DWORD pid;
    DWORD style;
    int * i;
    i = (int *) lparam;
    GetWindowThreadProcessId(hwnd, &pid);
    if(pid == GetCurrentProcessId()) {
        style = (DWORD) GetWindowLongPtr(hwnd, GWL_STYLE);
        if(!(style & GW_CHILD)) {
            *i += 1;
        }
    }
    return TRUE;
}
    /*
     ##########################################################################
     # (@)INTERNAL:EnableWindowsProc(hwnd, lparam)
     # Activate or Deactivate current thread top window.
     */
BOOL CALLBACK EnableWindowsProc(HWND hwnd, LPARAM lParam) {

    EnableWindow (hwnd, (BOOL) lParam);
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:FindChildWindowsProc(hwnd, lparam)
     # Activate or Deactivate current thread top window.
     */
BOOL CALLBACK FindChildWindowsProc(HWND hwnd, LPARAM lParam) {

    st_FindChildWindow * st = (st_FindChildWindow*) lParam;

    LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
    if( !ValidUserData(perlud) )
        return TRUE;

    if (strcmp (perlud->szWindowName, st->Name) == 0) {
        st->perlchild = perlud;
        return FALSE;
    }

    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:WindowsHookMsgProc(code, wparam, lparam)
     # Callback set by SetWindowsHookEx in TrackPopupMenu()
     */
LRESULT CALLBACK WindowsHookMsgProc(int code, WPARAM wParam, LPARAM lParam) {

  SV* perlsub;
  SV** arrayref;
  SV** arrayval;
  AV* array;
  MSG* pmsg;
  LPPERLWIN32GUI_USERDATA perlud;
  I32 count;
  int PerlResult;
  int i;

  if(code == MSGF_MENU) {
    PerlResult = 1;
    pmsg = (MSG *)lParam;
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(pmsg->hwnd, GWLP_USERDATA);

    if(ValidUserData(perlud)) {
      PERLUD_FETCH;       /* fetch context */

      //Tracker 1941264: Check if perlud->avHooks contains NULL. This was causing
      //a crash although it should not be possible that this is zero. It's likely
      //a bug elsewhere...No harm in the null pointer check though.
      if (perlud->avHooks != NULL) {

      arrayref = av_fetch(perlud->avHooks, WM_TRACKPOPUP_MSGHOOK, 0);
      if(arrayref != NULL) {
        array = (AV*) SvRV(*arrayref);
        SvREFCNT_inc((SV*) array);
        for(i = 0; i <= (int) av_len(array); i++) {
          arrayval = av_fetch(array,(I32) i,0);

          if(arrayval != NULL) {
            perlsub = *arrayval;
            SvREFCNT_inc(perlsub);
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
              XPUSHs(perlud->svSelf);
              XPUSHs(sv_2mortal(newSViv(pmsg->message)));
              XPUSHs(sv_2mortal(newSViv(pmsg->wParam)));
              XPUSHs(sv_2mortal(newSViv(pmsg->lParam)));
            PUTBACK;

            count = call_sv(perlsub, G_ARRAY|G_EVAL);
            SPAGAIN;

            if(SvTRUE(ERRSV)) {
              ProcessEventError(NOTXSCALL "TrackPopupMenu(WindowsHookMsgProc)", &PerlResult);
            } else {
              if(count > 0) { PerlResult = POPi; }
            }

            PUTBACK;
            FREETMPS;
            LEAVE;
            SvREFCNT_dec(perlsub);
          }
        }
        SvREFCNT_dec((SV*) array);

        // PerlResult = 0: do not pass event to rest of chain or target windows procedure
        // PerlResult = -1: as 0, and terminate application
        // PerlResult = anything else, pass event on
        if(PerlResult == 0) {
          return 1;  // stops message being passed along hook chain and to target windows procedure
        } else if (PerlResult == -1) {
          //send a WM_CANCELMODE to get menu to close
          SendMessage(pmsg->hwnd, WM_CANCELMODE, 0, 0);
          //post a message to get the main loop to exit
          PostMessage(pmsg->hwnd, WM_EXITLOOP, (WPARAM) -1, 0);
          return 1;  // stops message being passed along hook chain and to target windows procedure
        }
      }
    }
  }
  }

  // pass message along hook chain
  return CallNextHookEx(0, code, wParam, lParam);
}
