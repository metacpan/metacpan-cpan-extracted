// --------------------------------------------------------------------
// $Id: GUI.h,v 1.33 2011/07/16 14:51:03 acalpini Exp $
// --------------------------------------------------------------------
// #### Uncomment the next two lines (in increasing verbose order)
// #### for debugging info
// #define PERLWIN32GUI_DEBUG
// #define PERLWIN32GUI_STRONGDEBUG

#define  WIN32_LEAN_AND_MEAN
#define _WIN32_IE 0x0501
// #define _WIN32_WINNT 0x0400
/* If WINVER is not defined, the latest MS headers define it as 0x501,
 * but MinGW headers don't, so set it here */
#define WINVER 0x501
#undef NOTRACKMOUSEEVENT
#include <stdarg.h>
#include <windows.h>
#include <commctrl.h>
#include <commdlg.h>
#include <wtypes.h>
#include <richedit.h>
#include <shellapi.h>
#include <shlwapi.h>
#include <shlobj.h>

#include "resource.h"

#define __TEMP_WORD  WORD   /* perl defines a WORD, yikes! */

#if defined(PERL_OBJECT)
	#define NO_XSLOCKS
#endif

#ifdef __CYGWIN__
  #ifdef __cplusplus
    extern "C"
  #endif
  /* This is no strict ANSI definition, and not in newlib */
  char* itoa (int, char*, int);
  /* fix for error: 'stricmp' was not declared in this scope */
  #ifndef stricmp
  #define stricmp strcasecmp
  #endif
#endif /* __CYGWIN__ */

/*
 * Perl includes
 */

/* we need to find out under what conditions we really need this
 * extern "C" declaration
 */
#if defined(__cplusplus) && (( !defined(PERL_OBJECT) && !defined(PERL_IMPLICIT_CONTEXT) ) || defined(__CYGWIN__) )
extern "C" {
#define GUI_H_EXTERN_END /* make sure we put a matching end brace */
#endif

/* we want manage context if possible, See perlguts */
#if defined(PERL_IMPLICIT_CONTEXT)
	#define PERL_NO_GET_CONTEXT
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef GUI_H_EXTERN_END
}
#endif

/* fix up warnings */
#if defined(W32G_NEWWARN) && defined(G_WARN_ON)
#  define W32G_WARN if(PL_dowarn & G_WARN_ON) warn
#  define W32G_WARN_DEPRECATED if(PL_dowarn & G_WARN_ON) warn
#  define W32G_WARN_UNSUPPORTED if(PL_dowarn & G_WARN_ON) warn
//#  define W32G_WARN W32G_lexwarn
//#  define W32G_WARN_DEPRECATED W32G_lexwarn_deprecated
#else
#  define W32G_WARN if(PL_dowarn) warn
#  define W32G_WARN_DEPRECATED if(PL_dowarn) warn
#  define W32G_WARN_UNSUPPORTED if(PL_dowarn) warn
#endif

//=====================================================================================

/*
 * Various definitions to accomodate the different Perl versions around
 */

#ifdef PERL_OBJECT
#   ifdef _INC_WIN32_PERL5
#       pragma message( "\n*** Using the 5.005 Perl Object CPerlObj class.\n" )
#       define CPerl CPerlObj
#   else // not _INC_WIN32_PERL5
#       pragma message( "\n*** Using the 5.004 Perl Object CPerl class.\n" )
#   endif  //  _INC_WIN32_PERL5
#   define NOTXSPROC   CPerl *pPerl,
#   define NOTXSCALL   pPerl,
#   define PERLUD_DECLARE CPerl *pPerl
#   define PERLUD_STORE   perlud->pPerl = pPerl
#   define PERLUD_FETCH   PERLUD_DECLARE = perlud->pPerl
#else
#   ifdef PERL_NO_GET_CONTEXT
/*#       pragma message( "\n*** Using Preserved Perl context.\n" )*/
#       define NOTXSPROC pTHX_
#       define NOTXSCALL aTHX_
#       ifdef USE_THREADS
#         define PERLUD_DECLARE struct perl_thread *aTHX
#       else
#         define PERLUD_DECLARE PerlInterpreter *aTHX
#       endif
#       define PERLUD_STORE   perlud->aTHX = aTHX;
#       define PERLUD_FETCH   PERLUD_DECLARE = perlud->aTHX;
#   else
/*#       pragma message( "\n*** Using an implicit Perl context.\n" )*/
#       define NOTXSPROC
#       define NOTXSCALL
#       define PERLUD_DECLARE
#       define PERLUD_STORE
#       define PERLUD_FETCH
#   endif
#endif

//=====================================================================================

#define MAX_WINDOW_NAME 128
#define MAX_EVENT_NAME 255

#define WM_EXITLOOP   (WM_APP+1)    /* custom message to exit from the Dialog() function */
#define WM_NOTIFYICON (WM_APP+2)    /* custom message to process NotifyIcon events */
#define WM_TRACKPOPUP_MSGHOOK  (WM_APP + 0x3FFF) /* otherwise unused message to push a callback into the hooks array */

// dwFlags & dwFlagsMask use for Parsing option purpose (Not save in control)
// Checkbox
#define PERLWIN32GUI_CHECKED                            0x0001

// dwPlStyle Common (Save in control structure)
#define PERLWIN32GUI_OEM                                0x0001
#define PERLWIN32GUI_NEM                                0x0002
#define PERLWIN32GUI_CUSTOMCLASS                        0x0004
#define PERLWIN32GUI_DIALOGUI                           0x0008
#define PERLWIN32GUI_EVENTHANDLING                      0x0010
#define PERLWIN32GUI_CONTAINER                          0x0020
#define PERLWIN32GUI_FLICKERFREE                        0x0040
#define PERLWIN32GUI_ISMODAL                            0x0080
#define PERLWIN32GUI_MDIFRAME                           0x0100
#define PERLWIN32GUI_MDICHILD                           0x0200

// dwPlStyle Control specific
// Splitter
#define PERLWIN32GUI_TRACKING                           0x8000
#define PERLWIN32GUI_HORIZONTAL                         0x4000
// Graphics
#define PERLWIN32GUI_INTERACTIVE                        0x8000
// Toolbar
#define PERLWIN32GUI_TB_HASBITMAPS                      0x8000
// MDIFrame
#define PERLWIN32GUI_HAVECHILDWINDOW                    0x8000

// dwEventMask
// Common Event (All control)
#define PERLWIN32GUI_NEM_MOUSEMOVE                      0x00000001
#define PERLWIN32GUI_NEM_MOUSEOUT                       0x00000002
#define PERLWIN32GUI_NEM_MOUSEOVER                      0x00000004
#define PERLWIN32GUI_NEM_LMOUSEUP                       0x00000008
#define PERLWIN32GUI_NEM_LMOUSEDOWN                     0x00000010
#define PERLWIN32GUI_NEM_LMOUSEDBLCLK                   0x00000020
#define PERLWIN32GUI_NEM_RMOUSEUP                       0x00000040
#define PERLWIN32GUI_NEM_RMOUSEDOWN                     0x00000080
#define PERLWIN32GUI_NEM_RMOUSEDBLCLK                   0x00000100
#define PERLWIN32GUI_NEM_MMOUSEUP                       0x00000200
#define PERLWIN32GUI_NEM_MMOUSEDOWN                     0x00000400
#define PERLWIN32GUI_NEM_MMOUSEDBLCLK                   0x00000800
#define PERLWIN32GUI_NEM_KEYDOWN                        0x00001000
#define PERLWIN32GUI_NEM_KEYUP                          0x00002000
#define PERLWIN32GUI_NEM_TIMER                          0x00004000
#define PERLWIN32GUI_NEM_PAINT                          0x00008000
#define PERLWIN32GUI_NEM_CLICK                          0x00010000
#define PERLWIN32GUI_NEM_DBLCLICK                       0x00020000
#define PERLWIN32GUI_NEM_GOTFOCUS                       0x00040000
#define PERLWIN32GUI_NEM_LOSTFOCUS                      0x00080000
#define PERLWIN32GUI_NEM_RIGHTCLICK                     0x00100000
#define PERLWIN32GUI_NEM_DBLRIGHTCLICK                  0x00200000
#define PERLWIN32GUI_NEM_DROPFILE                       0x00400000
#define PERLWIN32GUI_NEM_CHAR                           0x00800000

// Generic control Event constant
#define PERLWIN32GUI_NEM_CONTROL1                       0x80000000
#define PERLWIN32GUI_NEM_CONTROL2                       0x40000000
#define PERLWIN32GUI_NEM_CONTROL3                       0x20000000
#define PERLWIN32GUI_NEM_CONTROL4                       0x10000000
#define PERLWIN32GUI_NEM_CONTROL5                       0x08000000
#define PERLWIN32GUI_NEM_CONTROL6                       0x04000000
#define PERLWIN32GUI_NEM_CONTROL7                       0x02000000
#define PERLWIN32GUI_NEM_CONTROL8                       0x01000000

// Argument type for Event functions
#define PERLWIN32GUI_ARGTYPE_INT                        0x0001
#define PERLWIN32GUI_ARGTYPE_LONG                       0x0002
#define PERLWIN32GUI_ARGTYPE_WORD                       0x0004
#define PERLWIN32GUI_ARGTYPE_STRING                     0x0008
#define PERLWIN32GUI_ARGTYPE_SV                         0x0010

/*
 * object types (for switch()ing)
 */
#define WIN32__GUI__WINDOW       0
#define WIN32__GUI__DIALOG       1
#define WIN32__GUI__STATIC       2
#define WIN32__GUI__BUTTON       3
#define WIN32__GUI__EDIT         4
#define WIN32__GUI__LISTBOX      5
#define WIN32__GUI__COMBOBOX     6
#define WIN32__GUI__CHECKBOX     7
#define WIN32__GUI__RADIOBUTTON  8
#define WIN32__GUI__GROUPBOX     9
#define WIN32__GUI__TOOLBAR     10
#define WIN32__GUI__PROGRESS    11
#define WIN32__GUI__STATUS      12
#define WIN32__GUI__TAB         13
#define WIN32__GUI__RICHEDIT    14
#define WIN32__GUI__LISTVIEW    15
#define WIN32__GUI__TREEVIEW    16
#define WIN32__GUI__TRACKBAR    17
#define WIN32__GUI__UPDOWN      18
#define WIN32__GUI__TOOLTIP     19
#define WIN32__GUI__ANIMATION   20
#define WIN32__GUI__REBAR       21
#define WIN32__GUI__HEADER      22
#define WIN32__GUI__COMBOBOXEX  23
#define WIN32__GUI__DTPICK      24
#define WIN32__GUI__GRAPHIC     25
#define WIN32__GUI__SPLITTER    26
#define WIN32__GUI__MDIFRAME    27
#define WIN32__GUI__MDICLIENT   28
#define WIN32__GUI__MDICHILD    29
#define WIN32__GUI__MONTHCAL    30

/*
 * an extension to Window's CREATESTRUCT structure
 */
typedef struct tagPERLWIN32GUI_CREATESTRUCT {
    CREATESTRUCT cs;
    /*
    CREATESTRUCT has the following members:
    LPVOID      lpCreateParams;
    HINSTANCE   hInstance;
    HMENU       hMenu;
    HWND        hwndParent;
    int         cy;
    int         cx;
    int         y;
    int         x;
    LONG        style;
    LPCTSTR     lpszName;
    LPCTSTR     lpszClass;
    DWORD       dwExStyle;
    */
    HIMAGELIST  hImageList;
    HV*         hvParent;
    HV*         hvSelf;
    char *      szWindowName;
    HFONT       hFont;
    int         iClass;
    HACCEL      hAcc;
    HWND        hTooltip;
    HCURSOR     hCursor;
    char *      szTip;
    DWORD       dwPlStyle;
    int         iMinWidth;
    int         iMaxWidth;
    int         iMinHeight;
    int         iMaxHeight;
    COLORREF    clrForeground;
    COLORREF    clrBackground;
    HBRUSH      hBackgroundBrush;
    BOOL        bDeleteBackgroundBrush;
    HV*         hvEvents;
    DWORD       dwEventMask;
    DWORD       dwFlags;
    DWORD       dwFlagsMask;
} PERLWIN32GUI_CREATESTRUCT, *LPPERLWIN32GUI_CREATESTRUCT;

/*
 * what we'll store in GWL_USERDATA
 */
typedef struct tagPERLWIN32GUI_USERDATA {
    DWORD       dwSize;                                                 // struct size (our signature)
    PERLUD_DECLARE;                                                     // a pointer to the Perl Object
    SV*         svSelf;                                                 // a pointer to ourself
    char        szWindowName[MAX_WINDOW_NAME];                          // our -name
    int         iClass;                                                 // our (Perl) class
    HACCEL      hAcc;                                                   // our accelerator table
    HCURSOR     hCursor;
    DWORD       dwPlStyle;
    int         iMinWidth;
    int         iMaxWidth;
    int         iMinHeight;
    int         iMaxHeight;
    COLORREF    clrForeground;
    COLORREF    clrBackground;
    HBRUSH      hBackgroundBrush;
    BOOL        bDeleteBackgroundBrush;
    WNDPROC     WndProc;
    HV*         hvEvents;
    DWORD       dwEventMask;
    AV*         avHooks;
    LRESULT     forceResult;
    IV          dwData;                                                // Internal DATA usage
    SV*         userData;                                              // user data
} PERLWIN32GUI_USERDATA, *LPPERLWIN32GUI_USERDATA;

typedef struct tagPERLWIN32GUI_MENUITEMDATA {
    DWORD       dwSize;
    char        szName[MAX_WINDOW_NAME];
    SV*         svCode;
} PERLWIN32GUI_MENUITEMDATA, *LPPERLWIN32GUI_MENUITEMDATA;


#define ValidUserData(ptr) (ptr != NULL && ptr->dwSize == sizeof(PERLWIN32GUI_USERDATA))
#define PERLUD_FROM_WND(hwnd) \
    LPPERLWIN32GUI_USERDATA perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLongPtr(hwnd, GWLP_USERDATA); \
    if( !ValidUserData(perlud) ) return 0;
#define PERL_OBJECT_FROM_WINDOW(hwnd) \
        PERLUD_FROM_WND(hwnd) \
        PERLUD_FETCH
#define HV_SELF_FROM_WINDOW(x) (SV_SELF_FROM_WINDOW(x) ? (HV*)SvRV(SV_SELF_FROM_WINDOW(x)) : NULL)
#undef WORD
#define WORD __TEMP_WORD

#define PERLUD_FREE SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR) NULL); Perlud_Free(NOTXSCALL perlud);
/*
 * Section for the constant definitions.
 */
#define CROAK croak

/*
 * some Perl macros for backward compatibility
 */
#ifndef SvIV
#       define SvIV(sv) (SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv))
#endif

#ifndef SvPV
#       define SvPV(sv, lp) (SvPOK(sv) ? ((lp = SvCUR(sv)), SvPVX(sv)) : sv_2pv(sv, &lp))
#endif

#ifndef SvPV_nolen
#       define SvPV_nolen(sv) SvPV(sv, PL_na)
#endif

#define PERLPUSHMARK(p) if (++markstack_ptr == markstack_max)   \
    markstack_grow();           \
    *markstack_ptr = (p) - stack_base

#define PERLXPUSHs(s)   do {\
    if (stack_max - sp < 1) {\
        sp = stack_grow(sp, sp, 1);\
    }\
    (*++sp = (s)); } while (0)

#ifdef NT_BUILD_NUMBER
#   ifndef dowarn
#       define dowarn FALSE
#   endif
#endif

#ifndef call_sv
#       define call_sv  perl_call_sv
#endif

#ifndef av_delete
#	define av_delete(a,i,f)	av_store(a,i,&PL_sv_undef)
#endif

#ifndef PERL_MAGIC_tied
#   define PERL_MAGIC_tied 'P' /* Tied array or hash */
#endif

/*
 * other useful things
 */
#define SwitchBit(mask, bit, set) \
    if(set == 0) { \
        if(mask & bit) { \
            mask ^= bit; \
        } \
    } else { \
        if(!(mask & bit)) { \
            mask |= bit; \
        } \
    }

#define BitmaskOption(string, mask, bit) \
    if(strcmp(option, string) == 0) { \
        next_i = i + 1; \
        SwitchBit(mask, bit, SvIV(ST(next_i)));

#define BitmaskOptionValue(string, mask, bit) \
    (strcmp(option, string) == 0)  { SwitchBit(mask, bit, SvIV(value));

#define BitmaskOptionValueMask(string, mask, bit) \
    (strcmp(option, string) == 0)  { SwitchBit(mask, bit, SvIV(value)); mask##Mask |= bit;

#define Parse_Event(x,y) (strcmp(name, x) == 0) { *eventID = y; }

/* prototypes */

/* GUI_Constants.cpp */
DWORD constant(NOTXSPROC char *name, int arg);

/* GUI_Helpers.cpp */
void Perlud_Free(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud);
SV * SV_SELF_FROM_WINDOW(HWND hwnd);
static void hv_magic_check (NOTXSPROC HV *hv, bool *needs_copy, bool *needs_store);
SV** hv_fetch_mg(NOTXSPROC HV *hv, char *key, U32 klen, I32 lval);
SV** hv_store_mg(NOTXSPROC HV *hv, char *key, U32 klen, SV* val, U32 hash);
HWND handle_From(NOTXSPROC SV *pSv);
char *classname_From(NOTXSPROC SV *pSv);
WNDPROC GetDefClassProc (NOTXSPROC const char *Name);
BOOL SetDefClassProc (NOTXSPROC const char *Name, WNDPROC DefClassProc);
COLORREF SvCOLORREF(NOTXSPROC SV* c);
HWND CreateTooltip(NOTXSPROC HV* parent);
void CalcControlSize(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs, int add_x, int add_y);
//BOOL GetObjectName(NOTXSPROC HWND hwnd, char *Name);
//BOOL GetObjectNameAndClass(NOTXSPROC HWND hwnd, char *Name, int *obj_class);
SV* CreateObjectWithHandle(NOTXSPROC char* class_name, HWND handle);
HMENU GetMenuFromID(NOTXSPROC int nID);
BOOL GetMenuName(NOTXSPROC HWND hwnd, int nID, char *Name);
// BOOL GetAcceleratorName(NOTXSPROC int nID, char *Name);
// BOOL GetTimerName(NOTXSPROC HWND hwnd, UINT nID, char *Name);
// BOOL GetNotifyIconName(NOTXSPROC HWND hwnd, UINT nID, char *Name);
DWORD CALLBACK RichEditSave(DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG FAR *pcb);
DWORD CALLBACK RichEditLoad(DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG FAR *pcb);
int CALLBACK BrowseForFolderProc(HWND hWnd, UINT uMsg, LPARAM lParam, LPARAM lpData);
int AdjustSplitterCoord(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int x, int w, HWND phwnd);
void DrawSplitter(NOTXSPROC HWND hwnd, int x, int y, int w, int h);
BOOL CALLBACK EnumMyWindowsProc(HWND hwnd, LPARAM lparam);
BOOL CALLBACK CountMyWindowsProc(HWND hwnd, LPARAM lparam);
BOOL CALLBACK EnableWindowsProc(HWND hwnd, LPARAM lParam);
typedef struct { LPPERLWIN32GUI_USERDATA perlchild; char * Name; } st_FindChildWindow;
BOOL CALLBACK FindChildWindowsProc(HWND hwnd, LPARAM lParam);
LRESULT CALLBACK WindowsHookMsgProc(int code, WPARAM wParam, LPARAM lParam);

/* GUI_Events.cpp */
int DoEvent(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int iEventId, char *Name, ...);
int DoEvent_Menu(NOTXSPROC HWND hwnd, int nID, ...);
int DoEvent_Accelerator(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int nID);
char* DoEvent_NeedText(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int iEventId, char *Name, ...);
int DoEvent_Timer (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int iTimerId, int iEventId, char *Name, ...);
int DoEvent_NotifyIcon (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, int iNotifyId, char* Name, ...);
int DoEvent_Paint (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud);
void DoHook(NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam, int* PerlResult, int notify);
BOOL ProcessEventError(NOTXSPROC char *Name, int* PerlResult);

/* GUI_Options.cpp */
void ParseNEMEvent(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs, char *name, SV* event);
void ParseWindowOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void ParseMenuItemOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, LPMENUITEMINFO mii, LPPERLWIN32GUI_MENUITEMDATA perlmid, UINT* myItem);
void ParseHeaderItemOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, LPHDITEMA hditem, int * index);
void ParseListViewColumnItemOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, LPLVCOLUMNA lvcolumn, int * iCol);
void ParseComboboxExItemOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, COMBOBOXEXITEM *item);
void ParseTooltipOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, TOOLINFO  *ti);
void ParseNotifyIconOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, NOTIFYICONDATA *nid);
void ParseRebarBandOptions(NOTXSPROC register SV **sp, register SV **mark, I32 ax, I32 items, int from_i, LPREBARBANDINFO rbbi, int * index);

/* GUI_MessageLoops.cpp */
LRESULT CommonMsgLoop(NOTXSPROC HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK WindowMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK MDIFrameMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK MDIClientMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK MDIChildMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK ControlMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK ContainerMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK CustomMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

/* Define callback control table
 * See GUI_Helpers.cpp
 */
extern void (*OnPreCreate[])(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT);
extern BOOL (*OnParseOption[])(NOTXSPROC char *, SV*,LPPERLWIN32GUI_CREATESTRUCT);
extern void (*OnPostCreate[])(NOTXSPROC HWND, LPPERLWIN32GUI_CREATESTRUCT);
extern BOOL (*OnParseEvent[])(NOTXSPROC char *, int*);
extern int  (*OnEvent[])(NOTXSPROC LPPERLWIN32GUI_USERDATA, UINT, WPARAM , LPARAM);

/*
 * class-specific routines for (options|create|etc)
 */

// Animation.xs
void Animation_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Animation_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Animation_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Animation_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Animation_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Button.xs
void Button_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Button_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Button_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Button_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Button_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void Checkbox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Checkbox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Checkbox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Checkbox_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Checkbox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void RadioButton_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL RadioButton_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void RadioButton_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL RadioButton_onParseEvent(NOTXSPROC char *name, int* eventID);
int  RadioButton_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void Groupbox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Groupbox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Groupbox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Groupbox_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Groupbox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Combobox.xs
void Combobox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Combobox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Combobox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Combobox_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Combobox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void ComboboxEx_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL ComboboxEx_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void ComboboxEx_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL ComboboxEx_onParseEvent(NOTXSPROC char *name, int* eventID);
int  ComboboxEx_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Header.xs
void Header_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Header_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Header_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Header_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Header_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// DateTime.xs
void DateTime_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL DateTime_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void DateTime_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL DateTime_onParseEvent(NOTXSPROC char *name, int* eventID);
int  DateTime_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Label.xs
void Label_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Label_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Label_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Label_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Label_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Listbox.xs
void Listbox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Listbox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Listbox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Listbox_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Listbox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// ListView.xs
void ListView_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL ListView_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void ListView_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL ListView_onParseEvent(NOTXSPROC char *name, int* eventID);
int  ListView_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// ProgressBar.xs
void ProgressBar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL ProgressBar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void ProgressBar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL ProgressBar_onParseEvent(NOTXSPROC char *name, int* eventID);
int  ProgressBar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Rebar.xs
void Rebar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Rebar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Rebar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Rebar_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Rebar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// RichEdit.xs
void RichEdit_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL RichEdit_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void RichEdit_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL RichEdit_onParseEvent(NOTXSPROC char *name, int* eventID);
int  RichEdit_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Splitter.xs
void Splitter_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Splitter_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Splitter_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Splitter_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Splitter_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// StatusBar.xs
void StatusBar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL StatusBar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void StatusBar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL StatusBar_onParseEvent(NOTXSPROC char *name, int* eventID);
int  StatusBar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// TabStrip.xs
void TabStrip_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL TabStrip_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void TabStrip_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL TabStrip_onParseEvent(NOTXSPROC char *name, int* eventID);
int  TabStrip_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Textfield.xs
void Textfield_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Textfield_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Textfield_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Textfield_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Textfield_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Toolbar.xs
void Toolbar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Toolbar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Toolbar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Toolbar_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Toolbar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Tooltip.xs
void Tooltip_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Tooltip_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Tooltip_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Tooltip_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Tooltip_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Trackbar.xs
void Trackbar_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Trackbar_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Trackbar_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Trackbar_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Trackbar_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// TreeView.xs
void TreeView_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL TreeView_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void TreeView_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL TreeView_onParseEvent(NOTXSPROC char *name, int* eventID);
int  TreeView_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// UpDown.xs
void UpDown_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL UpDown_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void UpDown_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL UpDown_onParseEvent(NOTXSPROC char *name, int* eventID);
int  UpDown_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Window.xs
void Window_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Window_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Window_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Window_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Window_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void DialogBox_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL DialogBox_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void DialogBox_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL DialogBox_onParseEvent(NOTXSPROC char *name, int* eventID);
int  DialogBox_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void Graphic_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Graphic_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void Graphic_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL Graphic_onParseEvent(NOTXSPROC char *name, int* eventID);
int  Graphic_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// MDI.xs
void MDIFrame_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MDIFrame_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void MDIFrame_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MDIFrame_onParseEvent(NOTXSPROC char *name, int* eventID);
int  MDIFrame_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void MDIClient_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MDIClient_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void MDIClient_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MDIClient_onParseEvent(NOTXSPROC char *name, int* eventID);
int  MDIClient_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

void MDIChild_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MDIChild_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void MDIChild_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MDIChild_onParseEvent(NOTXSPROC char *name, int* eventID);
int  MDIChild_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// MonthCal.xs
void MonthCal_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MonthCal_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs);
void MonthCal_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs);
BOOL MonthCal_onParseEvent(NOTXSPROC char *name, int* eventID);
int  MonthCal_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam);

// From windowsX.h (if we use any more from there, then probably better to
// include it, and remove these)
#define GET_X_LPARAM(lp)                        ((int)(short)LOWORD(lp))
#define GET_Y_LPARAM(lp)                        ((int)(short)HIWORD(lp))

// MinGW patch
#if defined(__MINGW32__) || defined(__CYGWIN__)
  // There are some ImageList_* functions that we use that
  // are only correctly implemented in the MINGW w32api package
  // version 3.2 and higher:
  #include <w32api.h> // to get w32api package version
  #if (__W32API_MAJOR_VERSION < 3) || ((__W32API_MAJOR_VERSION == 3) && (__W32API_MINOR_VERSION < 2))
    #define W32G_BROKENW32API
  #endif

  #define WNDPROC_CAST WNDPROC
  #define LWNDPROC_CAST WNDPROC
  #ifndef HDHITTESTINFO
    #define HDHITTESTINFO HD_HITTESTINFO
  #endif
  #ifndef Animate_OpenEx
    #define Animate_OpenEx(w,h,s) (BOOL)SNDMSG(w,ACM_OPEN,(WPARAM)h,(LPARAM)(LPTSTR)(s))
  #endif
  #ifndef DateTime_GetSystemtime
    #define DateTime_GetSystemtime DateTime_GetSystemTime
  #endif
  #ifndef DateTime_SetSystemtime
    #define DateTime_SetSystemtime DateTime_SetSystemTime
  #endif
  #ifndef ListView_GetCheckState
    #define ListView_GetCheckState(w, i) (int)(((SNDMSG((w), LVM_GETITEMSTATE, (WPARAM)i, LVIS_STATEIMAGEMASK)) >> 12) -1)
  #endif
  #ifndef ListView_SetUnicodeFormat
    #define LVM_SETUNICODEFORMAT     CCM_SETUNICODEFORMAT
    #define ListView_SetUnicodeFormat(w, f) (BOOL)SNDMSG((w), LVM_SETUNICODEFORMAT, (WPARAM)(f), 0)
  #endif
  #ifndef ListView_GetUnicodeFormat
    #define LVM_GETUNICODEFORMAT     CCM_GETUNICODEFORMAT
    #define ListView_GetUnicodeFormat(w) (BOOL)SNDMSG((w), LVM_GETUNICODEFORMAT, 0, 0)
  #endif
  #ifndef ListView_SetItemCountEx
    #define ListView_SetItemCountEx(w, i, f) SNDMSG((w), LVM_SETITEMCOUNT, (WPARAM)(i), (LPARAM)(f))
  #endif
  #ifndef ListView_GetISearchString
    #define ListView_GetISearchString(w, lpsz) (BOOL)SNDMSG((w), LVM_GETISEARCHSTRING, 0, (LPARAM)(LPTSTR)(lpsz))
  #endif
  #undef ListView_GetNumberOfWorkAreas
  #define ListView_GetNumberOfWorkAreas(w,n) (BOOL)SNDMSG((w),LVM_GETNUMBEROFWORKAREAS,0,(LPARAM)(UINT *)(n))
  #ifndef TreeView_GetLastVisible
    #define TreeView_GetLastVisible(w) TreeView_GetNextItem(w,NULL,TVGN_LASTVISIBLE)
  #endif
  #ifndef TabCtrl_GetImageList
    #define TabCtrl_GetImageList(w) (HIMAGELIST)SNDMSG((w),TCM_GETIMAGELIST,0,0L)
  #endif
  #ifndef Header_CreateDragImage
    #define Header_CreateDragImage(w, i) (HIMAGELIST)SNDMSG((w), HDM_CREATEDRAGIMAGE, (WPARAM)i, 0)
  #endif
  #ifndef Header_SetImageList
    #define Header_SetImageList(w,l) (HIMAGELIST)SNDMSG((w), HDM_SETIMAGELIST, 0, (LPARAM)l)
  #endif
  #ifndef Header_GetImageList
    #define Header_GetImageList(w) (HIMAGELIST)SNDMSG((w),HDM_GETIMAGELIST,0,0)
  #endif
  #ifndef Header_GetUnicodeFormat
    #define Header_GetUnicodeFormat(w) (BOOL)SNDMSG((w),HDM_GETUNICODEFORMAT,0,0)
  #endif
  #ifndef Header_SetUnicodeFormat
    #define Header_SetUnicodeFormat(w,f) (BOOL)SNDMSG((w),HDM_SETUNICODEFORMAT,(WPARAM)(f),0)
  #endif
  #ifndef TB_MARKBUTTON
    #define TB_MARKBUTTON (WM_USER + 6)
  #endif
  #ifndef TBSTATE_ELLIPSES
    #define TBSTATE_ELLIPSES  0x40
  #endif
  /* HIMAGELIST  WINAPI ImageList_Duplicate(HIMAGELIST himl); //TODO: remove? */
  #ifndef MCM_GETUNICODEFORMAT
    #define MCM_GETUNICODEFORMAT     CCM_GETUNICODEFORMAT
  #endif
  #ifndef MCM_SETUNICODEFORMAT
    #define MCM_SETUNICODEFORMAT     CCM_SETUNICODEFORMAT
  #endif
  #undef MonthCal_SetRange
  #define MonthCal_SetRange(w,f,st) (BOOL)SNDMSG((w),MCM_SETRANGE,(WPARAM)(f),(LPARAM)(st))
  #ifndef RBN_CHEVRONPUSHED
    #define RBN_CHEVRONPUSHED (RBN_FIRST - 10)
  #endif
  #ifndef TB_GETSTRING
    #define TB_GETSTRINGW (WM_USER+91)
    #define TB_GETSTRINGA (WM_USER+92)

    #ifdef UNICODE
    # define TB_GETSTRING TB_GETSTRINGW
    #else
    # define TB_GETSTRING TB_GETSTRINGA
    #endif
  #endif

  #ifndef NOTIFYICONDATA_V1_SIZE
    # define NOTIFYICONDATA_V1_SIZE CCSIZEOF_STRUCT(NOTIFYICONDATA, szTip[63])
  #endif

  #ifndef TTM_SETTITLE
  # define TTM_SETTITLE TTM_SETTITLEA
  #endif

#else
  #define WNDPROC_CAST FARPROC
  #define LWNDPROC_CAST LRESULT (__stdcall *)(HWND, UINT, WPARAM, LPARAM)
#endif


// MSVC6 patches
#if defined(_MSC_VER) && (_MSC_VER <= 1200) && (WINVER < 0x0500)
/*
 * MSVC6 falsely misses these definitions.
 */
typedef struct tagWINDOWINFO
{
    DWORD cbSize;
    RECT  rcWindow;
    RECT  rcClient;
    DWORD dwStyle;
    DWORD dwExStyle;
    DWORD dwOtherStuff;
    UINT  cxWindowBorders;
    UINT  cyWindowBorders;
    ATOM  atomWindowType;
    WORD  wCreatorVersion;
} WINDOWINFO, *PWINDOWINFO, *LPWINDOWINFO;

#define WS_ACTIVECAPTION    0x0001

#ifdef __cplusplus
  extern "C"
#endif
BOOL WINAPI
GetWindowInfo(
    HWND hwnd,
    PWINDOWINFO pwi
);

// These require at least comctl32.dll Version 5.80
#ifndef LVS_EX_LABELTIP
	#define LVS_EX_LABELTIP 0x00004000
#endif /* ndef LVS_EX_LABELTIP */

#ifndef RBN_CHEVRONPUSHED
	#define RBN_CHEVRONPUSHED (RBN_FIRST - 10)
#endif

typedef struct tagNMREBARCHEVRON {
    NMHDR hdr;
    UINT uBand;
    UINT wID;
    LPARAM lParam;
    RECT rc;
    LPARAM lParamNM;
} NMREBARCHEVRON, *LPNMREBARCHEVRON;

/* needed RichEdit 2.0 messages */
#ifndef EM_GETEDITSTYLE
	#define EM_SHOWSCROLLBAR	(WM_USER+96)
	#define EM_SETTYPOGRAPHYOPTIONS	(WM_USER+202)
	#define EM_GETTYPOGRAPHYOPTIONS	(WM_USER+203)
	#define EM_SETEDITSTYLE	(WM_USER + 204)
	#define EM_GETEDITSTYLE	(WM_USER + 205)
	#define EM_GETSCROLLPOS	(WM_USER+221)
	#define EM_SETSCROLLPOS	(WM_USER+222)
	#define EM_SETFONTSIZE	(WM_USER+223)
	#define EM_GETZOOM	(WM_USER+224)
	#define EM_SETZOOM	(WM_USER+225)
#endif

#ifndef TB_GETSTRING
	#define TB_GETSTRING		(WM_USER+91)
#endif

#ifndef TTS_BALLOON
	#define TTS_BALLOON	0x40
#endif

#endif /* defined(_MSC_VER) && (_MSC_VER <= 1200) && (WINVER < 0x0500) */
