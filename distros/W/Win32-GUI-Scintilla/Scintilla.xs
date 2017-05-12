/**********************************************************************/
/*                    S c i n t i l l a . x s                         */
/**********************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <windows.h>
#include "./include/Scintilla.h"

/*====================================================================*/
/*                       W I N 3 2 : : G U I                          */
/*====================================================================*/

#define MAX_WINDOW_NAME 128

/*
 * Various definitions to accomodate the different Perl versions around
 */

#ifdef PERL_OBJECT
#   ifdef _INC_WIN32_PERL5
#       pragma message( "\n*** Using the 5.005 Perl Object CPerlObj class.\n" )
#       define NOTXSPROC   CPerlObj *pPerl,
#       define NOTXSCALL   pPerl,
#       define CPerl CPerlObj
#   else // not _INC_WIN32_PERL5
#       pragma message( "\n*** Using the 5.004 Perl Object CPerl class.\n" )
#       define NOTXSPROC   CPerl *pPerl,
#       define NOTXSCALL   pPerl,
#   endif  //  _INC_WIN32_PERL5
#else
#   pragma message( "\n*** Using a non-Object Core Perl.\n" )
#   define NOTXSPROC
#   define NOTXSCALL
#endif

/*
 * what we'll store in GWL_USERDATA
 */
typedef struct tagPERLWIN32GUI_USERDATA {
        DWORD           dwSize;                                                 // struct size (our signature)
#ifdef PERL_OBJECT
        CPerl           *pPerl;                                                 // a pointer to the Perl Object
#endif
        SV*             svSelf;                                                 // a pointer to ourself
        char            szWindowName[MAX_WINDOW_NAME];  // our -name
        BOOL            fDialogUI;                                              // are we to intercept dialog messages?
        int             iClass;                                                 // our (Perl) class
        HACCEL          hAcc;                                                   // our accelerator table
        HWND            hTooltip;
        HCURSOR         hCursor;
        DWORD           dwPlStyle;
        int             iMinWidth;
        int             iMaxWidth;
        int             iMinHeight;
        int             iMaxHeight;
        COLORREF        clrForeground;
        COLORREF        clrBackground;
        HBRUSH          hBackgroundBrush;
        WNDPROC         wndprocPreContainer;
        WNDPROC         wndprocPreNEM;
        int             iEventModel;
        HV*             hvEvents;
        DWORD           dwEventMask;
        HWND            Modal;
} PERLWIN32GUI_USERDATA, *LPPERLWIN32GUI_USERDATA;


BOOL ProcessEventError(NOTXSPROC char *Name, int* PerlResult) {
    if(strncmp(Name, "main::", 6) == 0) Name += 6;
    if(SvTRUE(ERRSV)) {
        MessageBeep(MB_ICONASTERISK);
        *PerlResult = MessageBox(
            NULL,
            SvPV_nolen(ERRSV),
            Name,
            MB_ICONERROR | MB_OKCANCEL
        );
        if(*PerlResult == IDCANCEL) {
            *PerlResult = -1;
        }
        return TRUE;
    } else {
        return FALSE;
    }
}


/*====================================================================*/
/*                   H O O K   F U N C T I O N                        */
/*====================================================================*/

typedef struct SCNotification * pSCNotification;

/*
struct SCNotification {
        struct NotifyHeader nmhdr;
        int position;   // SCN_STYLENEEDED, SCN_MODIFIED, SCN_DWELLSTART, SCN_DWELLEND
        int ch;         // SCN_CHARADDED, SCN_KEY
        int modifiers;  // SCN_KEY
        int modificationType;   // SCN_MODIFIED
        const char *text;       // SCN_MODIFIED
        int length;             // SCN_MODIFIED
        int linesAdded; // SCN_MODIFIED
        int message;    // SCN_MACRORECORD
        uptr_t wParam;  // SCN_MACRORECORD
        sptr_t lParam;  // SCN_MACRORECORD
        int line;               // SCN_MODIFIED
        int foldLevelNow;       // SCN_MODIFIED
        int foldLevelPrev;      // SCN_MODIFIED
        int margin;             // SCN_MARGINCLICK
        int listType;   // SCN_USERLISTSELECTION
        int x;                  // SCN_DWELLSTART, SCN_DWELLEND
        int y;          // SCN_DWELLSTART, SCN_DWELLEND
};
*/


int DoEvent (NOTXSPROC char *Name, UINT code, pSCNotification evt) {
    int PerlResult;
    int count;
    PerlResult = 1;
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(sv_2mortal(newSVpv("-code", 0)));
        XPUSHs(sv_2mortal(newSViv(code)));
        if (code == SCN_STYLENEEDED || code == SCN_MODIFIED || code == SCN_DWELLSTART ||
            code == SCN_DWELLEND || code == SCN_MARGINCLICK ||
            code == SCN_HOTSPOTCLICK || code == SCN_HOTSPOTDOUBLECLICK ||
            code == SCN_CALLTIPCLICK)
        {
          XPUSHs(sv_2mortal(newSVpv("-position", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->position)));
        }
        if (code == SCN_CHARADDED || code == SCN_KEY)
        {
          XPUSHs(sv_2mortal(newSVpv("-ch", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->ch)));
        }
        if (code == SCN_KEY || code == SCN_MARGINCLICK ||
            code == SCN_HOTSPOTCLICK || code == SCN_HOTSPOTDOUBLECLICK)
        {
          XPUSHs(sv_2mortal(newSVpv("-modifiers", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->modifiers)));

          XPUSHs(sv_2mortal(newSVpv("-shift", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->modifiers & SCMOD_SHIFT)));

          XPUSHs(sv_2mortal(newSVpv("-control", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->modifiers & SCMOD_CTRL)));

          XPUSHs(sv_2mortal(newSVpv("-alt", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->modifiers & SCMOD_ALT)));
        }
        if (code == SCN_MODIFIED )
        {
          XPUSHs(sv_2mortal(newSVpv("-modificationType", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->modificationType)));
//          XPUSHs(sv_2mortal(newSVpv("-text", 0)));
//          XPUSHs(sv_2mortal(newSVpv(evt->text, 0)));
          XPUSHs(sv_2mortal(newSVpv("-length", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->length)));
          XPUSHs(sv_2mortal(newSVpv("-linesAdded", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->linesAdded)));
          XPUSHs(sv_2mortal(newSVpv("-line", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->line)));
          XPUSHs(sv_2mortal(newSVpv("-foldLevelNow", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->foldLevelNow)));
          XPUSHs(sv_2mortal(newSVpv("-foldLevelPrev", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->foldLevelPrev)));
        }
        if (code == SCN_MACRORECORD)
        {
          XPUSHs(sv_2mortal(newSVpv("-message", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->message)));
        }
        if (code == SCN_MARGINCLICK)
        {
          XPUSHs(sv_2mortal(newSVpv("-margin", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->margin)));
        }
        if (code == SCN_USERLISTSELECTION)
        {
          XPUSHs(sv_2mortal(newSVpv("-listType", 0)));
          XPUSHs(sv_2mortal(newSViv((int) evt->wParam))); // ???
//          XPUSHs(sv_2mortal(newSViv(evt->listType)));
//          XPUSHs(sv_2mortal(newSVpv("-text", 0)));
//          XPUSHs(sv_2mortal(newSVpv(evt->text, 0)));
        }
        if (code == SCN_DWELLSTART || code == SCN_DWELLEND)
        {
          XPUSHs(sv_2mortal(newSVpv("-x", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->x)));
          XPUSHs(sv_2mortal(newSVpv("-y", 0)));
          XPUSHs(sv_2mortal(newSViv(evt->y)));
        }
        PUTBACK;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return PerlResult;
}

int DoEvent_Generic(NOTXSPROC char *Name)
{
    int PerlResult;
    int count;
    PerlResult = 1;

    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = perl_call_pv(Name, G_EVAL|G_NOARGS);
        SPAGAIN;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult))
        {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return PerlResult;
}


HHOOK hhook;

LRESULT WINAPI CallWndProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    CWPSTRUCT * msg = (CWPSTRUCT *) lParam;

    if (nCode >= 0 && msg->message == WM_NOTIFY)
    {
      NMHDR *lpnmhdr = (LPNMHDR) msg->lParam;
      char Name [255];

      // Read Sender Class
      GetClassName (lpnmhdr->hwndFrom, Name, 255);

      if (memcmp (Name, "Scintilla", 9) == 0)
      {

         // Perl contexte
#ifdef PERL_OBJECT
         CPerl *pPerl;
#endif
        LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(lpnmhdr->hwndFrom, GWL_USERDATA);

        if (perlud != NULL)
        {

#ifdef PERL_OBJECT
         pPerl = perlud->pPerl;
#endif

          // Build name
          strcpy(Name, "main::");
          strcat(Name, (char *) perlud->szWindowName);
          strcat(Name, "_Notify");

          DoEvent(NOTXSCALL Name, lpnmhdr->code, (pSCNotification) msg->lParam);
        }
      }
    }
    else if (nCode >= 0 && msg->message == WM_COMMAND && msg->lParam != 0)
    {
      char Name [255];

      // Read Sender Class
      GetClassName ((HWND) msg->lParam, Name, 255);

      if (memcmp (Name, "Scintilla", 9) == 0)
      {
         // Perl contexte
#ifdef PERL_OBJECT
         CPerl *pPerl;
#endif
        LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong((HWND) msg->lParam, GWL_USERDATA);
        if (perlud != NULL)
        {

#ifdef PERL_OBJECT
          pPerl = perlud->pPerl;
#endif
          // Build name
          strcpy(Name, "main::");
          strcat(Name, (char *) perlud->szWindowName);

          switch (HIWORD(msg->wParam))
          {
          case SCEN_CHANGE :
            strcat(Name, "_Change");
            DoEvent_Generic (NOTXSCALL Name);
            break;
          case SCEN_SETFOCUS :
            strcat(Name, "_GotFocus");
            DoEvent_Generic (NOTXSCALL Name);
            break;
          case SCEN_KILLFOCUS :
            strcat(Name, "_LostFocus");
            DoEvent_Generic (NOTXSCALL Name);
            break;
          }
        }
      }
    }

    return CallNextHookEx(hhook, nCode, wParam, lParam);
}

/*====================================================================*/
/*                Win32::GUI::Scintilla    package                    */
/*====================================================================*/

MODULE = Win32::GUI::Scintilla          PACKAGE = Win32::GUI::Scintilla

    ###########################################################################
    # _Initialise() (internal)
    # Install Hook function

void
_Initialise()
PREINIT:
CODE:
  hhook = SetWindowsHookEx(WH_CALLWNDPROC, CallWndProc, (HINSTANCE) NULL, GetCurrentThreadId());

    ###########################################################################
    # _UnInitialise() (internal)
    # Release Hook function

void
_UnInitialise()
PREINIT:
CODE:
  UnhookWindowsHookEx (hhook);

    ###########################################################################
    # SendMessageNP : Posts a message to a window
    # Take WPARAM as int and LPARAM as a LPVOID

LRESULT
SendMessageNP(handle,msg,wparam,lparam)
    HWND handle
    UINT msg
    WPARAM wparam
    LPVOID lparam
CODE:
    RETVAL = SendMessage(handle, msg, (WPARAM) wparam, (LPARAM) lparam);
OUTPUT:
    RETVAL

    ###########################################################################
    # SendMessagePP : Posts a message to a window
    # Take WPARAM and LPARAM as a LPVOID

LRESULT
SendMessagePP(handle,msg,wparam,lparam)
    HWND handle
    UINT msg
    LPVOID wparam
    LPVOID lparam
CODE:
    RETVAL = SendMessage(handle, msg, (WPARAM) wparam, (LPARAM) lparam);
OUTPUT:
    RETVAL
