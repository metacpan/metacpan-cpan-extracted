        /*
    ###########################################################################
    # event processing routines
    #
    # $Id: GUI_Events.cpp,v 1.16 2010/04/08 21:26:48 jwgui Exp $
    #
    ###########################################################################
        */

#include "GUI.h"

    /* IMPORTANT:
     * Whenever we make a callback into perl, we cannot know what evil things
     * the script writer will have done.  In particular, it is possible for
     * the called code to cause the window for which the event is being
     * handled to be destroyed before the callback returns.  If this happens
     * we will have a non-NULL perlud pointer, but the underlying memory
     * will have been freed.  Don't try to access perlud after a callback
     * without checking that the window still exists.  Currently the code
     * below gets the window handle BEFORE the callback (from perud->svSelf),
     * and checks it afterwards with IsWindow().  This is not infallable as the
     * hwnd could have been recycled - this is, however, unlikely
     */

    /*
     ##########################################################################
     # (@)INTERNAL:ProcessEventError(Name, *PerlResult)
     # Pops up a message box in case of error within an event;
     # returns TRUE if errors were, FALSE otherwise, and sets PerlResult
     # according to user's click (CANCEL == -1),
     */
BOOL ProcessEventError(NOTXSPROC char *Name, int* PerlResult) {
    if(SvTRUE(ERRSV)) {
		if(strncmp(Name, "main::", 6) == 0) Name += 6;
        MessageBeep(MB_ICONASTERISK);
        *PerlResult = MessageBox(NULL, SvPV_nolen(ERRSV), Name, MB_ICONERROR | MB_OKCANCEL);
        if(*PerlResult == IDCANCEL) {
            *PerlResult = -1;
        }
        return TRUE;
    } else {
        return FALSE;
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent(perlud, event_id, name, ...)
     */
int DoEvent(
        NOTXSPROC
        LPPERLWIN32GUI_USERDATA perlud,
        int iEventId,
        char *Name,
        ...
) {
    va_list args;
    int count;
    int argtype;

    int PerlResult = 1;
    HWND hwnd = handle_From(NOTXSCALL perlud->svSelf);
    perlud->dwPlStyle &= ~PERLWIN32GUI_EVENTHANDLING;

    // NEM event
    if((perlud->dwPlStyle & PERLWIN32GUI_NEM) && (perlud->dwEventMask & iEventId)) {

         SV** event;
         event = hv_fetch( (perlud->hvEvents), Name, strlen(Name), 0);
         if(event != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlud->svSelf);

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                case PERLWIN32GUI_ARGTYPE_SV:
                    XPUSHs(va_arg( args, SV *));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;
            
            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // OEM Event
    if (PerlResult == 1 && (perlud->dwPlStyle & PERLWIN32GUI_OEM) && perlud->szWindowName != NULL) {

        // OEM name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, perlud->szWindowName);
        strcat(EventName, "_");
        strcat(EventName, Name);

        // Check name event
        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                case PERLWIN32GUI_ARGTYPE_SV:
                    XPUSHs(va_arg( args, SV *));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_Menu(nID)
     */
int DoEvent_Menu(
        NOTXSPROC
        HWND hwnd,
        int nID,
        ...
) {
    int PerlResult = 1;
    int count;

    SV* event  = &PL_sv_undef;
    char* name = NULL;

    MENUITEMINFO mii;
    HMENU hmenu;
    LPPERLWIN32GUI_MENUITEMDATA perlmid = NULL;

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
            event = perlmid->svCode;
            name  = perlmid->szName;
        }
    }

    // NEM Event call
    if( SvOK(event) ) {

        LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA);
        PerlResult = 0;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        if( ValidUserData(perlud) )
            XPUSHs(perlud->svSelf);
        PUTBACK;
        count = call_sv(event, G_EVAL|G_ARRAY);
        SPAGAIN;
        if(!ProcessEventError(NOTXSCALL "", &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    // OEM Event call
    else if (name != NULL) {

         // OEM name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, name);
        strcat(EventName, "_Click");

        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_NOARGS);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
    }

    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_Accelerator(nID)
     */
int DoEvent_Accelerator(
        NOTXSPROC
        LPPERLWIN32GUI_USERDATA perlud,
        int nID
) {
    int count;
    char AcceleratorName[MAX_EVENT_NAME];
    LPPERLWIN32GUI_USERDATA perlchild = NULL;
    SV* acc_sub = NULL;
    int PerlResult = 1;
    HWND hwnd = handle_From(NOTXSCALL perlud->svSelf);
    perlud->dwPlStyle &= ~PERLWIN32GUI_EVENTHANDLING;

    // Search Accelerator information
    {
        // Convert accelerator id to string
        itoa(nID, AcceleratorName, 10);
        HV* hash = perl_get_hv("Win32::GUI::Accelerators", FALSE);
        // Get timer Hash
        SV** acc = hv_fetch_mg(NOTXSCALL hash, AcceleratorName, strlen(AcceleratorName), FALSE);
        if(acc == NULL) return PerlResult;
        // Sub ref ?
        if(SvROK (*acc))
            acc_sub = SvRV(*acc);
        // A name ?
        else if(SvPOK (*acc)) {
            strcpy(AcceleratorName, (char *) SvPV_nolen(*acc));

            // Find for a child with AcceleratorName name
            if (strcmp (perlud->szWindowName, AcceleratorName) != 0) {
                st_FindChildWindow st;
                st.perlchild = NULL;
                st.Name = AcceleratorName;

                EnumChildWindows(hwnd, (WNDENUMPROC) FindChildWindowsProc, (LPARAM) &st);
                perlchild = st.perlchild;
            }
        }
        else
            return PerlResult;
    }

    // Call accelerator sub
    if (acc_sub != NULL) {

        PerlResult = 0;

        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(perlud->svSelf);
        XPUSHs(sv_2mortal(newSVpv(AcceleratorName, 0)));

        PUTBACK;
        count = call_sv(acc_sub, G_EVAL|G_ARRAY);
        SPAGAIN;
        if(!ProcessEventError(NOTXSCALL "Click", &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;

        if(!IsWindow(hwnd)) return PerlResult;

        // Must set after event call because this event can generate more event.
        perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
    }
    // Try to call Click NEM on Child window
    else if (perlchild != NULL &&
        (perlchild->dwPlStyle & PERLWIN32GUI_NEM) && (perlchild->dwEventMask & PERLWIN32GUI_NEM_CLICK)) {

         SV** event;
         event = hv_fetch( (perlchild->hvEvents), "Click", 5, 0);
         if(event != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlchild->svSelf);

            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL "Click", &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // Try to call current window Click NEM event
    else if ((perlud->dwPlStyle & PERLWIN32GUI_NEM) && (perlud->dwEventMask & PERLWIN32GUI_NEM_CLICK)) {

         SV** event;
         event = hv_fetch( (perlud->hvEvents), "Click", 5, 0);
         if(event != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlud->svSelf);
            XPUSHs(sv_2mortal(newSVpv(AcceleratorName, 0)));

            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL "Click", &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // Or try OEM Event (Only if haven't find a named child or named child is OEM)
    else if (perlchild == NULL || perlchild->dwPlStyle & PERLWIN32GUI_OEM) {

        // OEM name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, AcceleratorName);
        strcat(EventName, "_Click");

        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_NOARGS);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_NeedText(perlud, event_id, name, ...)
     */
char*  DoEvent_NeedText(
        NOTXSPROC
        LPPERLWIN32GUI_USERDATA perlud,
        int iEventId,
        char *Name,
        ...) {

    va_list args;
    int count;
    int argtype;
    HWND hwnd = handle_From(NOTXSCALL perlud->svSelf);
    static char *textneeded = NULL;           /* XXX: Not Thread Safe */
    if(textneeded != NULL) {
        safefree(textneeded);
        textneeded = NULL;
    }

    int PerlResult = 1;
    perlud->dwPlStyle &=  ~PERLWIN32GUI_EVENTHANDLING;

    // NEM event
    if((perlud->dwPlStyle & PERLWIN32GUI_NEM) && (perlud->dwEventMask & iEventId)) {

        SV** event;
        event = hv_fetch( (perlud->hvEvents), Name, strlen(Name), 0);
        if(event != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlud->svSelf);

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
                if(count > 0) {
                    if(count > 1) {
                        PerlResult = POPi;
                    } else {
                        PerlResult = 0;
                    }
                    SV* svt = POPs;
                    textneeded = (char *) safemalloc(sv_len(svt) + 1);
                    strcpy(textneeded, SvPV_nolen(svt));
                }
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return textneeded;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // OEM Event
    if(PerlResult == 1 && (perlud->dwPlStyle & PERLWIN32GUI_OEM) && perlud->szWindowName != NULL) {

        // OEM name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, perlud->szWindowName);
        strcat(EventName, "_");
        strcat(EventName, Name);

        // Check name event
        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) {
                    if(count > 1) {
                        PerlResult = POPi;
                    } else {
                        PerlResult = 0;
                    }
                    SV* svt = POPs;
                    textneeded = (char *) safemalloc(sv_len(svt) + 1);
                    strcpy(textneeded, SvPV_nolen(svt));
                }
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return textneeded;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    return textneeded;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_Timer(perlud, timer_id, event_id, name, ...)
     */
int DoEvent_Timer (
        NOTXSPROC
        LPPERLWIN32GUI_USERDATA perlud,
        int iTimerId,
        int iEventId,
        char *Name,
        ...) {

    va_list args;
    int count;
    int argtype;
    char TimerName[MAX_EVENT_NAME];

    int PerlResult = 1;
    HWND hwnd = handle_From(NOTXSCALL perlud->svSelf);
    perlud->dwPlStyle &= ~PERLWIN32GUI_EVENTHANDLING;

    // SearchTimer information
    {
        // Convert TimerId to string
        itoa(iTimerId, TimerName, 10);
        // Get window timers Hash
        SV** timers = hv_fetch_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-timers", 7, FALSE);
        if(timers == NULL || !SvROK(*timers)) return PerlResult;
        // Get timer name with it's TimerID.
        SV** name = hv_fetch_mg(NOTXSCALL (HV*) SvRV(*timers), TimerName, strlen(TimerName), FALSE);
        if(name == NULL && !SvPOK(*name)) return PerlResult;
        strcpy(TimerName, (char *) SvPV_nolen(*name));
    }

    // NEM event
    if((perlud->dwPlStyle & PERLWIN32GUI_NEM) && (perlud->dwEventMask & iEventId)) {

        SV** event;
        event = hv_fetch( perlud->hvEvents, "Timer", 5, 0);
        if(event != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlud->svSelf);
            XPUSHs(sv_2mortal(newSVpv(TimerName, 0)));  // Add timer name

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // OEM Event
    if(PerlResult == 1 && (perlud->dwPlStyle & PERLWIN32GUI_OEM)) {

        // OEM timer name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, TimerName);
        strcat(EventName, "_");
        strcat(EventName, Name);

        // Check name event
        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_NotifyIcon (perlud, timer_id, event_id, name, ...)
     */
int DoEvent_NotifyIcon (
        NOTXSPROC
        LPPERLWIN32GUI_USERDATA perlud,
        int iNotifyId,
        char* Name,
        ...) {

    va_list args;
    int count;
    int argtype;
    char NotifyIconName[MAX_EVENT_NAME];
    SV** events  = NULL;
    int PerlResult = 1;
    HWND hwnd = handle_From(NOTXSCALL perlud->svSelf);
    perlud->dwPlStyle &=  ~PERLWIN32GUI_EVENTHANDLING;

    // NotifyIconName information
    {
        // Convert NotifyIcon id to string
        itoa(iNotifyId, NotifyIconName, 10);
        // Get window notifyicons Hash
        SV** notifyicons = hv_fetch_mg(NOTXSCALL (HV*)SvRV(perlud->svSelf), "-notifyicons", 12, FALSE);
        if(notifyicons == NULL || !SvROK(*notifyicons) ) return PerlResult;
        // Get notifyicon associed name
        SV** name = hv_fetch_mg(NOTXSCALL (HV*) SvRV(*notifyicons), NotifyIconName, strlen(NotifyIconName), FALSE);
        if(name == NULL) return PerlResult;
        strcpy(NotifyIconName, (char *) SvPV_nolen(*name));
        // Get notifyicon object from parent
        SV** notifyicon = hv_fetch_mg(NOTXSCALL (HV*) SvRV(perlud->svSelf), NotifyIconName, strlen(NotifyIconName), FALSE);
        if(notifyicon != NULL && SvROK(*notifyicon)) {
            // Get NEM Events Hash
            events = hv_fetch_mg(NOTXSCALL (HV*) SvRV(*notifyicon), "-events", 7, FALSE);
        }
    }

    // Try NEM event
    if (events != NULL) {

         SV** event = hv_fetch( (HV*)SvRV(*events), Name, strlen(Name), 0);

         if(event != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlud->svSelf);
            XPUSHs(sv_2mortal(newSVpv(NotifyIconName, 0)));  // NotifyIcon Name

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // OEM Event (if no NEM event found)
    if(PerlResult == 1 && events == NULL) {

        // OEM timer name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, NotifyIconName);
        strcat(EventName, "_");
        strcat(EventName, Name);

        // Check name event
        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);

            va_start( args, Name );
            argtype = va_arg( args, int );
            while(argtype != -1) {
                switch(argtype) {
                case PERLWIN32GUI_ARGTYPE_INT:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_LONG:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, long ))));
                    break;
                case PERLWIN32GUI_ARGTYPE_WORD:
                    XPUSHs(sv_2mortal(newSViv(va_arg( args, int))));
                    break;
                case PERLWIN32GUI_ARGTYPE_STRING:
                    XPUSHs(sv_2mortal(newSVpv(va_arg( args, char * ), 0)));
                    break;
                default:
                    warn("Win32::GUI: WARNING! unknown argument type (%d) to event '%s'", argtype, Name);
                    break;
                }
                argtype = va_arg( args, int );
            }
            va_end( args );

            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_Paint(perlud)
     */

int DoEvent_Paint(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud) {

    int count;
    SV* newdc;
    int PerlResult = 1;
    HWND hwnd = handle_From(NOTXSCALL perlud->svSelf);
    perlud->dwPlStyle &= ~PERLWIN32GUI_EVENTHANDLING;

    // NEM event
    if((perlud->dwPlStyle & PERLWIN32GUI_NEM) && (perlud->dwEventMask & PERLWIN32GUI_NEM_PAINT)) {

         SV** event;
         event = hv_fetch( (perlud->hvEvents), "Paint", 5, 0);
         if(event != NULL) {

            PerlResult = 0;

            dSP;

            // Create a DC object
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpv("Win32::GUI::DC", 0)));
            XPUSHs(perlud->svSelf);
            PUTBACK ;
            count = perl_call_pv("Win32::GUI::DC::new", 0);
            SPAGAIN ;
            newdc = newSVsv(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;

            // Call Paint event
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(perlud->svSelf);
            XPUSHs(sv_2mortal(newdc));
            PUTBACK;
            count = call_sv(*event, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL "Paint", &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    // OEM Event
    if(PerlResult == 1 && (perlud->dwPlStyle & PERLWIN32GUI_OEM) && perlud->szWindowName != NULL) {

        // OEM name event
        char EventName[MAX_EVENT_NAME];
        strcpy(EventName, "main::");
        strcat(EventName, perlud->szWindowName);
        strcat(EventName, "_Paint");

        // Check name event
        if(perl_get_cv(EventName, FALSE) != NULL) {

            PerlResult = 0;

            dSP;

            // Create a DC object
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpv("Win32::GUI::DC", 0)));
            XPUSHs(perlud->svSelf);
            PUTBACK ;
            count = perl_call_pv("Win32::GUI::DC::new", 0);
            SPAGAIN ;
            newdc = newSVsv(POPs);
            PUTBACK;
            FREETMPS;
            LEAVE;
            // Call paint event
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            XPUSHs(sv_2mortal(newdc));
            PUTBACK;
            count = perl_call_pv(EventName, G_EVAL|G_ARRAY);
            SPAGAIN;
            if(!ProcessEventError(NOTXSCALL EventName, &PerlResult)) {
                if(count > 0) PerlResult = POPi;
            }
            PUTBACK;
            FREETMPS;
            LEAVE;

            if(!IsWindow(hwnd)) return PerlResult;

            // Must set after event call because this event can generate more event.
            perlud->dwPlStyle |= PERLWIN32GUI_EVENTHANDLING;
        }
    }

    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoHook(perlud, uMsg, wParam, lParam, *PerlResult, notify)
     */
void DoHook(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud,
            UINT uMsg, WPARAM wParam, LPARAM lParam,
            int* PerlResult, int notify) {
    I32 count;
    SV** arrayval;
    SV*  perlsub;
    SV** arrayref;
    AV*  array;
    int i;
    I32 originalMsg;

    originalMsg = (I32) uMsg;
    if((I32) uMsg < 0) { uMsg = 0 - uMsg; }

    //printf("Doing hook for %d now...\n",uMsg);
    arrayref = av_fetch(perlud->avHooks, (I32) uMsg, 0);
    if(arrayref != NULL) {
        array = (AV*) SvRV(*arrayref);
        SvREFCNT_inc((SV*) array);
        for(i = 0; i <= (int) av_len(array); i++) {
            arrayval = av_fetch(array,(I32) i,0);
            if(arrayval != NULL) {
                perlsub = *arrayval;
                SvREFCNT_inc(perlsub); // Who knows what evil lurks in the heart of Perl.
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(perlud->svSelf);
                XPUSHs(sv_2mortal(newSViv(wParam)));
                XPUSHs(sv_2mortal(newSViv(lParam)));
                XPUSHs(sv_2mortal(newSViv(notify)));
                XPUSHs(sv_2mortal(newSViv(originalMsg)));
                PUTBACK;
                count = call_sv(perlsub, G_ARRAY|G_EVAL);
                SPAGAIN;
                //if we have an error report it to the user
                //we could call ProcessEventError in the form of if(!ProcessEventError(NOTXSCALL "Hook", PerlResult))
                //but this is slightly quicker:)
                if(SvTRUE(ERRSV)) {
				  ProcessEventError(NOTXSCALL "Hook", PerlResult);
				}
				else {
                  if(count > 0) { *PerlResult = POPi; }
			    }
                PUTBACK;
                FREETMPS;
                LEAVE;
                SvREFCNT_dec(perlsub);
            }
        }
        SvREFCNT_dec((SV*) array);
    }
}
