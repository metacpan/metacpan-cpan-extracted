#define WIN32_LEAN_AND_MEAN
#define __SETUPSUP_H

#include <windows.h>
#include <winperf.h>
#include <winuser.h>
#include <stdio.h>

#include "setupsup.h"
#include "list.h"
#include "wstring.h"
#include "usererror.h"

#ifdef __MINGW32__
#define __try                             /* fake SEH */
#define __leave   goto finally_jump_here  /* fake SEH */
#define __finally finally_jump_here:      /* fake SEH */
#endif

///////////////////////////////////////////////////////////////////////////////
//
// defines and macros
//
///////////////////////////////////////////////////////////////////////////////

// Use non-deprecated names
#define stricmp  _stricmp
#define strnicmp _strnicmp

// defines key codes
#define VK_ALT_DN_STR           "ALT+"
#define VK_ALT_UP_STR           "ALT-"
#define VK_LALT_DN_STR          "ALTL+"
#define VK_LALT_UP_STR          "ALTL-"
#define VK_RALT_DN_STR          "ALTR+"
#define VK_RALT_UP_STR          "ALTR-"

#define VK_CTRL_DN_STR          "CTRL+"
#define VK_CTRL_UP_STR          "CTRL-"
#define VK_LCTRL_DN_STR         "CTRLL+"
#define VK_LCTRL_UP_STR         "CTRLL-"
#define VK_RCTRL_DN_STR         "CTRLR+"
#define VK_RCTRL_UP_STR         "CTRLR-"

#define VK_SHIFT_DN_STR         "SHIFT+"
#define VK_SHIFT_UP_STR         "SHIFT-"
#define VK_LSHIFT_DN_STR        "SHIFTL+"
#define VK_LSHIFT_UP_STR        "SHIFTL-"
#define VK_RSHIFT_DN_STR        "SHIFTR+"
#define VK_RSHIFT_UP_STR        "SHIFTR-"

#define VK_TAB_STR              "TAB"
#define VK_ENTER_STR            "RET"
#define VK_ESC_STR              "ESC"

#define VK_BACK_STR             "BACK"
#define VK_DEL_STR              "DEL"
#define VK_INSERT_STR           "INS"
#define VK_HELP_STR             "HELP"

#define VK_LEFT_STR             "LEFT"
#define VK_RIGHT_STR            "RIGHT"
#define VK_UP_STR               "UP"
#define VK_DOWN_STR             "DN"
#define VK_PGUP_STR             "PGUP"
#define VK_PGDOWN_STR           "PGDN"
#define VK_BEG_STR              "BEG"
#define VK_END_STR              "END"

#define VK_F1_STR               "F1"
#define VK_F2_STR               "F2"
#define VK_F3_STR               "F3"
#define VK_F4_STR               "F4"
#define VK_F5_STR               "F5"
#define VK_F6_STR               "F6"
#define VK_F7_STR               "F7"
#define VK_F8_STR               "F8"
#define VK_F9_STR               "F9"
#define VK_F10_STR              "F10"
#define VK_F11_STR              "F11"
#define VK_F12_STR              "F12"

#define VK_NUMPAD0_STR          "NUM0"
#define VK_NUMPAD1_STR          "NUM1"
#define VK_NUMPAD2_STR          "NUM2"
#define VK_NUMPAD3_STR          "NUM3"
#define VK_NUMPAD4_STR          "NUM4"
#define VK_NUMPAD5_STR          "NUM5"
#define VK_NUMPAD6_STR          "NUM6"
#define VK_NUMPAD7_STR          "NUM7"
#define VK_NUMPAD8_STR          "NUM8"
#define VK_NUMPAD9_STR          "NUM9"

#define VK_MULTIPLY_STR         "NUM*"
#define VK_ADD_STR              "NUM+"
#define VK_SUBTRACT_STR         "NUM-"
#define VK_DECIMAL_STR          "NUM,"
#define VK_DIVIDE_STR           "NUM/"


// defines window properties and indexes
#define PROP_CHECKED            "checked"
#define ID_CHECKED              1
#define PROP_CLASS              "class"
#define ID_CLASS                2
#define PROP_CLASSATOM          "classatom"
#define ID_CLASSATOM            3
#define PROP_CLASSBRUSH         "classbrush"
#define ID_CLASSBRUSH           4
#define PROP_CLASSCURSOR        "classcursor"
#define ID_CLASSCURSOR          5
#define PROP_CLASSICON          "classicon"
#define ID_CLASSICON            6
#define PROP_CLASSICONSMALL     "classiconsmall"
#define ID_CLASSICONSMALL       7
#define PROP_CLASSMENU          "classmenu"
#define ID_CLASSMENU            8
#define PROP_CLASSMODULE        "classmodule"
#define ID_CLASSMODULE          9
#define PROP_CLASSPROC          "classproc"
#define ID_CLASSPROC            10
#define PROP_CLASSSTYLE         "classstyle"
#define ID_CLASSSTYLE           11
#define PROP_CLIENT             "client"
#define ID_CLIENT               12
#define PROP_DESKTOP            "desktop"
#define ID_DESKTOP              13
#define PROP_DLGPROC            "dlgproc"
#define ID_DLGPROC              14
#define PROP_ENABLED            "enabled"
#define ID_ENABLED              15
#define PROP_EXTSTYLE           "extstyle"
#define ID_EXTSTYLE             16
#define PROP_FOCUSED            "focused"
#define ID_FOCUSED              17
#define PROP_FOREGROUND         "foreground"
#define ID_FOREGROUND           18
#define PROP_ICONIC             "iconic"
#define ID_ICONIC               19
#define PROP_ID                 "id"
#define ID_ID                   20
#define PROP_INSTANCE           "instance"
#define ID_INSTANCE             21
#define PROP_LASTACTIVEPOPUP    "lastactivepopup"
#define ID_LASTACTIVEPOPUP      22
#define PROP_MENU               "menu"
#define ID_MENU                 23
#define PROP_NEXT               "next"
#define ID_NEXT                 24
#define PROP_PARENT             "parent"
#define ID_PARENT               25
#define PROP_PREV               "prev"
#define ID_PREV                 26
#define PROP_PID                "pid"
#define ID_PID                  27
#define PROP_RECT               "rect"
#define ID_RECT                 28
#define PROP_STYLE              "style"
#define ID_STYLE                29
#define PROP_TEXT               "text"
#define ID_TEXT                 30
#define PROP_TID                "tid"
#define ID_TID                  31
#define PROP_TOP                "top"
#define ID_TOP                  32
#define PROP_UNICODE            "unicode"
#define ID_UNICODE              33
#define PROP_VALID              "valid"
#define ID_VALID                34
#define PROP_VISIBLE            "visible"
#define ID_VISIBLE              35
#define PROP_WNDPROC            "wndproc"
#define ID_WNDPROC              36
#define PROP_ZOOMED             "zoomed"
#define ID_ZOOMED               37

// identifiers for properties client or rect
#define PROP_RECT_LEFT          "left"
#define PROP_RECT_TOP           "top"
#define PROP_RECT_RIGHT         "right"
#define PROP_RECT_BOTTOM        "bottom"

// identifiers for processes and threads
#define PROCESS_NAME_STR        "name"
#define PID_STR                 "pid"
#define THREAD_PROCESS_STR      "process"
#define TID_STR                 "tid"

// max size for window class or caption
#define TEXT_BUF_SIZE           1024

// initial performance data size
#define PERF_DATA_SIZE          0x10000

// maximal allowed parts in a sid string
#define MAX_SID_TOKENS          11

// compares a string with a property identifier and returns a index
#define RETURN_IDX_IF_EQUAL(id, str) if(!stricmp(PROP_##id, str)) return ID_##id;

// compares a string with a name and returns a the value of the string
#define RET_VAL_IF_EQUAL(value, name) if(!strcmp(#value, name)) return value;

// sets result to false and lastError
#define SetErrorAndResult { result = FALSE; LastError(GetLastError()); }

// default refresh rate for mouse capturing
#define DEFAULT_MOUSE_CAPTURE_REFRESH 100

// hibyte macro
#ifndef HB
#define HB(value) ((BYTE) (((USHORT)(value) >> 8) & 0xFF))
#endif

// lobyte macro
#ifndef LB
#define LB(value) ((BYTE) (value))
#endif

// breaks if the property type is not an integer
#define BREAK_IF_NO_INT_PROP_TYPE(prop)         \
  {                                             \
    if(!SvIOKp(prop))                           \
      {                                         \
        LastError(INVALID_PROPERTY_TYPE_ERROR); \
        result = FALSE;                         \
        break;                                  \
      }                                         \
  }

// breaks if the property type is not a hash reference
#define BREAK_IF_NO_HREF_PROP_TYPE(prop)                        \
  {                                                             \
    if(!SvROK(prop) || SvTYPE(SvRV(prop)) != SVt_PVHV) {        \
      LastError(INVALID_PROPERTY_TYPE_ERROR);                   \
      result = FALSE;                                           \
      break;                                                    \
    }                                                           \
  }

// In case windows.h didn't define it:
#ifndef SECURITY_NT_NON_UNIQUE
#define SECURITY_NT_NON_UNIQUE          (0x00000015L)
#endif


///////////////////////////////////////////////////////////////////////////////
//
// structures
//
///////////////////////////////////////////////////////////////////////////////

// used to exchange parameters between EnumWaitForAnyWindowProc and
// XS_NT__Setupsup_WaitForAnyWindow
struct PerlEnumWindowStruct
{
#ifndef PERL_5_6_0
  CPerl *perl;
#endif //PERL_5_6_0
  SV *pattern;
  HWND hWnd;
};

typedef PerlEnumWindowStruct *PPerlEnumWindowStruct;


// used to establish a communication between threads and clean up on dll exit
struct PerlThreadInfoStruct
{
#ifndef PERL_5_6_0
  CPerl *perl;
#endif //PERL_5_6_0
  HANDLE hThread;
  BOOL threadExitFlag;
  DWORD lastError;
  DWORD timeout;
  DWORD refresh;
  AV *actions;
  SV *pattern;
};

typedef PerlThreadInfoStruct *PPerlThreadInfoStruct;


///////////////////////////////////////////////////////////////////////////////
//
// global variables
//
///////////////////////////////////////////////////////////////////////////////

// thread list to store threads created by WaitForWindowAsynch
static List AsynchThreadList;

// is mouse captured or not
static HANDLE MouseCaptureThread = NULL;
static DWORD MouseCaptureRefresh = 0;

///////////////////////////////////////////////////////////////////////////////
//
// functions
//
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// checks if the string between beg and end has a special key code
//
// param:  beg          - pointer to string begin
//         end          - pointer to string end
//         curKey       - pointer which contains the key if the function returns
//         altCtrlShift - contains the status of the alt-, ctrl- and shift keys
//
// return: success - TRUE
//         failure - FALSE
//
// note:   if there is no special key the return value is false; if there is a
//         special key, the key is in curKey and return value is true;
//         altCtrlShift contains the status if the special key is a alt-, ctrl-
//         or shift-key. if there is on the hibyte is 1; the lobyte
//         distinguishes between alt, ctrl and shift (alt = 4, ctrl = 2,
//         shift = 1)
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetSpecialKeyCode(PSTR beg, PSTR end, BYTE *curKey, PWORD altCtrlShift)
{
  *altCtrlShift = 0;

  if(!strnicmp(VK_ALT_DN_STR, beg, end - beg) ||
     !strnicmp(VK_LALT_DN_STR, beg, end - beg) ||
     !strnicmp(VK_RALT_DN_STR, beg, end - beg)) {
    *curKey = VK_MENU;
    *altCtrlShift = 0x104;
    return TRUE;
  }

  if(!strnicmp(VK_ALT_UP_STR, beg, end - beg) ||
     !strnicmp(VK_LALT_UP_STR, beg, end - beg) ||
     !strnicmp(VK_RALT_UP_STR, beg, end - beg)) {
    *curKey = VK_MENU;
    *altCtrlShift = 0x4;
    return TRUE;
  }

  if(!strnicmp(VK_CTRL_DN_STR, beg, end - beg) ||
     !strnicmp(VK_LCTRL_DN_STR, beg, end - beg) ||
     !strnicmp(VK_RCTRL_DN_STR, beg, end - beg)) {
    *curKey = VK_CONTROL;
    *altCtrlShift = 0x102;
    return TRUE;
  }

  if(!strnicmp(VK_CTRL_UP_STR, beg, end - beg) ||
     !strnicmp(VK_LCTRL_UP_STR, beg, end - beg) ||
     !strnicmp(VK_RCTRL_UP_STR, beg, end - beg)) {
    *curKey = VK_CONTROL;
    *altCtrlShift = 0x2;
    return TRUE;
  }

  if(!strnicmp(VK_SHIFT_DN_STR, beg, end - beg) ||
     !strnicmp(VK_LSHIFT_DN_STR, beg, end - beg) ||
     !strnicmp(VK_RSHIFT_DN_STR, beg, end - beg)) {
    *curKey = VK_SHIFT;
    *altCtrlShift = 0x101;
    return TRUE;
  }

  if(!strnicmp(VK_SHIFT_UP_STR, beg, end - beg) ||
     !strnicmp(VK_LSHIFT_UP_STR, beg, end - beg) ||
     !strnicmp(VK_RSHIFT_UP_STR, beg, end - beg)) {
    *curKey = VK_SHIFT;
    *altCtrlShift = 0x1;
    return TRUE;
  }

  if(!strnicmp(VK_TAB_STR, beg, end - beg)) {
    *curKey = VK_TAB;
    return TRUE;
  }

  if(!strnicmp(VK_ENTER_STR, beg, end - beg)) {
    *curKey = VK_RETURN;
    return TRUE;
  }

  if(!strnicmp(VK_ESC_STR, beg, end - beg)) {
    *curKey = VK_ESCAPE;
    return TRUE;
  }

  if(!strnicmp(VK_INSERT_STR, beg, end - beg)) {
    *curKey = VK_INSERT;
    return TRUE;
  }

  if(!strnicmp(VK_BACK_STR, beg, end - beg)) {
    *curKey = VK_BACK;
    return TRUE;
  }

  if(!strnicmp(VK_DEL_STR, beg, end - beg)) {
    *curKey = VK_DELETE;
    return TRUE;
  }

  if(!strnicmp(VK_HELP_STR, beg, end - beg)) {
    *curKey = VK_HELP;
    return TRUE;
  }

  if(!strnicmp(VK_LEFT_STR, beg, end - beg)) {
    *curKey = VK_LEFT;
    return TRUE;
  }

  if(!strnicmp(VK_RIGHT_STR, beg, end - beg)) {
    *curKey = VK_RIGHT;
    return TRUE;
  }

  if(!strnicmp(VK_UP_STR, beg, end - beg)) {
    *curKey = VK_UP;
    return TRUE;
  }

  if(!strnicmp(VK_DOWN_STR, beg, end - beg)) {
    *curKey = VK_DOWN;
    return TRUE;
  }

  if(!strnicmp(VK_PGUP_STR, beg, end - beg)) {
    *curKey = VK_PRIOR;
    return TRUE;
  }

  if(!strnicmp(VK_PGDOWN_STR, beg, end - beg)) {
    *curKey = VK_NEXT;
    return TRUE;
  }

  if(!strnicmp(VK_BEG_STR, beg, end - beg)) {
    *curKey = VK_HOME;
    return TRUE;
  }

  if(!strnicmp(VK_END_STR, beg, end - beg)) {
    *curKey = VK_END;
    return TRUE;
  }

  if(!strnicmp(VK_F1_STR, beg, end - beg)) {
    *curKey = VK_F1;
    return TRUE;
  }

  if(!strnicmp(VK_F2_STR, beg, end - beg)) {
    *curKey = VK_F2;
    return TRUE;
  }

  if(!strnicmp(VK_F3_STR, beg, end - beg)) {
    *curKey = VK_F3;
    return TRUE;
  }

  if(!strnicmp(VK_F4_STR, beg, end - beg)) {
    *curKey = VK_F4;
    return TRUE;
  }

  if(!strnicmp(VK_F5_STR, beg, end - beg)) {
    *curKey = VK_F5;
    return TRUE;
  }

  if(!strnicmp(VK_F6_STR, beg, end - beg)) {
    *curKey = VK_F6;
    return TRUE;
  }

  if(!strnicmp(VK_F7_STR, beg, end - beg)) {
    *curKey = VK_F7;
    return TRUE;
  }

  if(!strnicmp(VK_F8_STR, beg, end - beg)) {
    *curKey = VK_F8;
    return TRUE;
  }

  if(!strnicmp(VK_F9_STR, beg, end - beg)) {
    *curKey = VK_F9;
    return TRUE;
  }

  if(!strnicmp(VK_F10_STR, beg, end - beg)) {
    *curKey = VK_F10;
    return TRUE;
  }

  if(!strnicmp(VK_F11_STR, beg, end - beg)) {
    *curKey = VK_F11;
    return TRUE;
  }

  if(!strnicmp(VK_F12_STR, beg, end - beg)) {
    *curKey = VK_F12;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD0_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD0;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD1_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD1;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD2_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD2;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD3_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD3;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD4_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD4;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD5_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD5;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD6_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD6;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD7_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD7;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD8_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD8;
    return TRUE;
  }

  if(!strnicmp(VK_NUMPAD9_STR, beg, end - beg)) {
    *curKey = VK_NUMPAD9;
    return TRUE;
  }

  if(!strnicmp(VK_MULTIPLY_STR, beg, end - beg)) {
    *curKey = VK_MULTIPLY;
    return TRUE;
  }

  if(!strnicmp(VK_ADD_STR, beg, end - beg)) {
    *curKey = VK_ADD;
    return TRUE;
  }

  if(!strnicmp(VK_SUBTRACT_STR, beg, end - beg)) {
    *curKey = VK_SUBTRACT;
    return TRUE;
  }

  if(!strnicmp(VK_DECIMAL_STR, beg, end - beg)) {
    *curKey = VK_DECIMAL;
    return TRUE;
  }

  if(!strnicmp(VK_DIVIDE_STR, beg, end - beg)) {
    *curKey = VK_DIVIDE;
    return TRUE;
  }

  return FALSE;
}


///////////////////////////////////////////////////////////////////////////////
//
// sends keystrokes to a window
//
// param:  hWnd                                                  - handle to the window to send keys
//         str                                                   - string whith keys
//         activateEverytime - if true each time the window will be set to
//                                                                                                               foreground before a key is send
//         timeout                                       - time between sending two keystrokes
//                               lastError                               - gets the error value if an error occurres
//
// return: success - TRUE
//         failure - FALSE
//
///////////////////////////////////////////////////////////////////////////////

BOOL SendKeys(HWND hWnd, PSTR str, BOOL activateEverytime, DWORD timeout, PDWORD lastError)
{
  ErrorAndResult;
  USHORT altCtrlShiftState = 0;

  __try {
    // activate foreign window
    if(hWnd)
      SetForegroundWindow(hWnd);

    // walk through the string
    for(BYTE curKey; str && *str; str++) {
      // activate foreign windows if wished
      if(activateEverytime && hWnd)
        SetForegroundWindow(hWnd);

      // is this a delimiter char and the next is no delimiter
      if(*str == '\\' && *++str != '\\') {
        PSTR nextDelim = strchr(str, '\\');
        USHORT altCtrlShift = 0;

        // we could not find the next delimiter, so there is an error
        if(!nextDelim || !GetSpecialKeyCode(str, nextDelim, &curKey, &altCtrlShift)) {
          LeaveFalseError(BAD_STR_FORMAT_ERROR);
          break;
        }

        // set string to the next char
        str = nextDelim;

        // did we got an alt-, ctrl- or shift key, send it and continue
        if(altCtrlShift) {
          altCtrlShiftState = altCtrlShift;

          if(HB(altCtrlShift))
            keybd_event(curKey, 0, KEYEVENTF_EXTENDEDKEY, 0);
          else
            keybd_event(curKey, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
        }
        else {
          // it's not an alt-, ctrl- or shift key, but it's a special key
          keybd_event(curKey, 0, 0, 0);
          keybd_event(curKey, 0, KEYEVENTF_KEYUP, 0);
        }
      }
      else { // if(*str == '\\' && *++str != '\\')

        // we have a normal char or the next char is a delimiter (well then we treat
        // it as a normal char); get scan code now
        short scanCode = VkKeyScan(*str);

        // if the char needs a special keystroke do a key down now
        if(HB(scanCode) & 4)
          keybd_event(VK_MENU, 0, KEYEVENTF_EXTENDEDKEY, 0);

        if(HB(scanCode) & 2)
          keybd_event(VK_CONTROL, 0, KEYEVENTF_EXTENDEDKEY, 0);

        if(HB(scanCode) & 1)
          keybd_event(VK_SHIFT, 0, KEYEVENTF_EXTENDEDKEY, 0);

        // send the key
        keybd_event(LB(scanCode), HB(scanCode), 0, 0);
        keybd_event(LB(scanCode), HB(scanCode), KEYEVENTF_KEYUP, 0);

        // if the char needs a special keystroke do a key up now
        if(HB(scanCode) & 1)
          keybd_event(VK_SHIFT, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);

        if(HB(scanCode) & 2)
          keybd_event(VK_CONTROL, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);

        if(HB(scanCode) & 4)
          keybd_event(VK_MENU, 0, KEYEVENTF_EXTENDEDKEY | KEYEVENTF_KEYUP, 0);
      }

      // wait a while
      if(timeout)
        Sleep(timeout);
    } // for(BYTE curKey; str && *str; str++)
  } // __try
  __finally {
    SetErrorVar();
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// sends keystrokes to a window
//
// param:  window   - handle to the window to send keys
//         keystr   - string whith keys
//         activate - if true each time the window will be set to foreground
//                    before a key is send
//         timeout  - time between sending two keystrokes
//
// return: success - TRUE
//         failure - FALSE
//
// note:   if there is an error, lastError will be set; call GetLastError()
//         to get the error code; be carefully with alt-, ctrl- and shift-
//         modifiers; if you send an alt+ you have to send and alt- too; there
//         is no checking if you do that; some keys needs an implicit alt-,
//         ctrl- or shift-modifier; f.e. the backslash key on an german key-
//         board needs to send an alt+, ctrl+, ß, ctrl-, alt-; do not enclose
//         this such keys in your own modifiers; results would be inpredictable
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_SendKeys)
{
  dXSARGS;

  ErrorAndResult;

  // reset last error
  LastError(0);
  HWND hWnd = NULL;

  // check arguments
  if(items == 3 || items == 4 && SvIOKp(ST(0)) && SvPOK(ST(1)) && SvIOKp(ST(2)) &&
     (items != 4 || SvIOKp(ST(3)))) {
    HWND hWnd = (HWND)SvIV(ST(0));
    PSTR str = SvPV(ST(1), PL_na);
    BOOL activateEverytime = (BOOL)SvIV(ST(2));
    DWORD timeout = items == 4 ? (DWORD)SvIV(ST(3)) : 0;

    SendKeys(hWnd, str, activateEverytime, timeout, &error);
    LastError(error);
  }
  else
    croak("Usage: Win32::Setupsup::SendKeys($window, $keystr, $activate, [$timeout])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// enum procedure to store all window handles; will be called by win32
//
// param:  hWnd   - contains the window handle
//         lParam - pointer to a list to store all handles
//
// return: success - TRUE
//         failure - FALSE
//
///////////////////////////////////////////////////////////////////////////////

BOOL CALLBACK EnumWindowProc(HWND hWnd, LPARAM lParam)
{
  // lParam contains a pointer to a list
  PList windows = (PList)lParam;

  // alloc memory for the new handle
  HWND *hWindow = new HWND(hWnd);

  if(!hWindow)
    return FALSE;

  // store the handle
  if(!windows->AddTail(hWindow, TRUE))
    return FALSE;

  return TRUE;
}


///////////////////////////////////////////////////////////////////////////////
//
// stores all window handles in an array
//
// param:  @windows - array reference to store all window handles
//
// return: success - 1
//         failure - 0
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_EnumWindows)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  AV *windows = NULL;

  // check arguments
  if(items == 1 && SvROK(windows = (AV*)ST(0)) &&
     SvTYPE(windows = (AV*)SvRV(windows)) == SVt_PVAV) {
    // clear array
    av_clear(windows);

    // temprary used list
    List windowList;

    // enumerate all windows
    if(EnumWindows((WNDENUMPROC)EnumWindowProc, (long)&windowList))
      for(PNode node = windowList.HeadPos(); node; node = windowList.NextPos(node))
        // store all window handles
        av_push(windows, newSViv(*(PDWORD)windowList.This(node)));
    else
      LastError(NOT_ENOUGTH_MEMORY_ERROR);

    // clear allocated memory
    windowList.RemoveAll();
  }
  else
    croak("Usage: Win32::Setupsup::EnumWindows(\\@windows)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// stores all child window handles in an array
//
// param:  window  - parent window handle
//         @childs - array reference to store all child windows handles
//
// return: success - 1
//         failure - 0
//
// note:   call GetLastError() to get the error code on failure
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_EnumChildWindows)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // parameters
  SV *window = NULL;
  AV *childs = NULL;

  // check arguments
  if(items == 2 && SvIOKp(window = ST(0)) && SvROK(childs = (AV*)ST(1)) &&
     SvTYPE(childs = (AV*)SvRV(childs)) == SVt_PVAV) {
    // clear array
    av_clear(childs);

    // temprary used list
    List childList;

    // enumerate all child windows
    if(EnumChildWindows((HWND)SvIV(window), (WNDENUMPROC)EnumWindowProc,
                        (long)&childList))
      for(PNode node = childList.HeadPos(); node; node = childList.NextPos(node))
        // store all child window handles
        av_push(childs, newSViv(*(PDWORD)childList.This(node)));
    else
      LastError(NOT_ENOUGTH_MEMORY_ERROR);

    // clear allocated memory
    childList.RemoveAll();
  }
  else
    croak("Usage: Win32::Setupsup::EnumChildWindows($window, \\@childs)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// waits for a window title and returns the app. window handle
//
// param:  title   - window title
//         window  - returned window handle
//         timeout - timeout value in ms (until the function returns if no
//                   window was found)
//         refresh - refresh cycle to look for the window in ms
//
// return: success - true
//         failure - false
//
// note:   you should specify a refresh value (f.e. 50 ms); otherwise the
//         function loops and consumes about 70% of cpu power
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_WaitForWindow)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // parameters
  SV *title = NULL, *window = NULL;

  // check arguments
  if((items == 3 || items == 4) && SvPOK(title = ST(0)) && SvROK(window = ST(1)) &&
     SvIOKp(ST(2)) && (items != 4 || SvIOKp(ST(3)))) {
    window = (SV*)SvRV(window);

    DWORD timeout = SvIV(ST(2));
    DWORD refresh = items == 4 ? SvIV(ST(3)) : 0;

    for(DWORD startTime = GetTickCount(), curTime = startTime; TRUE;
        curTime = GetTickCount()) {
      // look for window
      HWND hWnd = FindWindow(NULL, SvPV(title, PL_na));

      // did we found it
      if(hWnd) {
        // store window handle
        sv_setiv(window, (long)hWnd);
        break;
      }

      // ckeck for overflow
      if(timeout && curTime < startTime)
        timeout -= 0xffffffff - startTime + curTime;

      // check for timeout
      if(timeout && curTime - startTime >= timeout) {
        LastError(ERROR_TIMEOUT_ELAPSED);
        break;
      }

      // wait a while
      Sleep(refresh);
    }
  }
  else
    croak("Usage: Win32::Setupsup::WaitForWindow($title, \\$window, $timeout, "
          "[$refresh])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// enum procedure compare window captions with a pattern
//
// param:  hWnd   - contains the window handle
//         lParam - pointer to a PerlEnumWindowStruct
//
// return: pattern match found           - FALSE
//         pattern match not found - TRUE
//
///////////////////////////////////////////////////////////////////////////////

BOOL CALLBACK EnumWaitForAnyWindowProc(HWND hWnd, LPARAM lParam)
{
  BOOL result = TRUE;

  // lParam contains a pointer to a PerlEnumWindowStruct
  PPerlEnumWindowStruct perlEnumWindow = (PPerlEnumWindowStruct)lParam;

#ifndef PERL_5_6_0
  CPerl *pPerl = perlEnumWindow->perl;
#endif // PERL_5_6_0

  SV *pattern = perlEnumWindow->pattern;

  char textBuf[TEXT_BUF_SIZE] = "";

  // we need the window text
  GetWindowText(hWnd, textBuf, TEXT_BUF_SIZE);

  // create new perl variables
  SV *textWaitForAnyWindowSV = perl_get_sv("textWaitForAnyWindowSV", TRUE);
  sv_setpv(textWaitForAnyWindowSV, textBuf);

  SV *patternWaitForAnyWindowSV = perl_get_sv("patternWaitForAnyWindowSV", TRUE);
  sv_setsv(patternWaitForAnyWindowSV, pattern);

  SV *resultWaitForAnyWindowSV = perl_get_sv("resultWaitForAnyWindowSV", TRUE);

  // this is our perl string
  PSTR evalStr =
    "$resultWaitForAnyWindowSV = ($textWaitForAnyWindowSV =~ "
    "m/$patternWaitForAnyWindowSV/i) ? 1 : 0";

  SV *evalWaitForAnyWindowSV = newSVpv(evalStr, strlen(evalStr));

  // now eval the string
  perl_eval_sv(evalWaitForAnyWindowSV, G_DISCARD);

  // check window text matches
  if(SvIV(resultWaitForAnyWindowSV)) {
    perlEnumWindow->hWnd = hWnd;

    result = FALSE;
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// waits for a window title and returns the app. window handle
//
// param:  title   - window title (grep like expressions are allowed; search is
//                   case insensitive)
//         window  - returned window handle
//         timeout - timeout value in ms (until the function returns if no
//                   window was found)
//         refresh - refresh cycle to look for the window in ms
//
// return: success - true
//         failure - false
//
// note:   you should specify a refresh value (f.e. 50 ms); otherwise the
//         function loops and consumes about 70% of cpu power;
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_WaitForAnyWindow)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // parameters
  SV *pattern = NULL, *window = NULL;

  // check arguments
  if((items == 3 || items == 4) && SvPOK(pattern = ST(0)) && SvROK(window = ST(1)) &&
     SvIOKp(ST(2)) && (items != 4 || SvIOKp(ST(3)))) {
    window = (SV*)SvRV(window);

    DWORD timeout = SvIV(ST(2));
    DWORD refresh = items == 4 ? SvIV(ST(3)) : 0;

    // parameter struct to
    PerlEnumWindowStruct perlEnumWindow;

#ifndef PERL_5_6_0
    perlEnumWindow.perl = pPerl;
#endif // PERL_5_6_0
    perlEnumWindow.pattern = pattern;
    perlEnumWindow.hWnd = NULL;

    for(DWORD startTime = GetTickCount(), curTime = startTime; TRUE;
        curTime = GetTickCount()) {
      // enumerate all windows
      EnumWindows((WNDENUMPROC)EnumWaitForAnyWindowProc, (long)&perlEnumWindow);

      // did we found a window
      if(perlEnumWindow.hWnd) {
        sv_setiv(window, (long)perlEnumWindow.hWnd);
        break;
      }

      // ckeck for overflow
      if(timeout && curTime < startTime)
        timeout -= 0xffffffff - startTime + curTime;

      // check for timeout
      if(timeout && curTime - startTime >= timeout) {
        LastError(ERROR_TIMEOUT_ELAPSED);
        break;
      }

      // wait a while
      Sleep(refresh);
    }
  }
  else
    croak("Usage: Win32::Setupsup::WaitForAnyWindow($title, \\$window, $timeout, "
          "[$refresh])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// thread func to wait for a window asynch
//
// param:  param - pointer to a parameter struct
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

DWORD WINAPI WaitForAnyWindowAsynchThreadFunc(PVOID param)
{
  PPerlThreadInfoStruct threadInfo = (PPerlThreadInfoStruct) param;

#ifndef PERL_5_6_0
  CPerl *pPerl = threadInfo->perl;
#endif // PERL_5_6_0

  // parameter struct to
  PerlEnumWindowStruct perlEnumWindow;

#ifndef PERL_5_6_0
  perlEnumWindow.perl = threadInfo->perl;
#endif // PERL_5_6_0

  perlEnumWindow.pattern = threadInfo->pattern;
  perlEnumWindow.hWnd = NULL;

  for(DWORD startTime = GetTickCount(), curTime = startTime; TRUE;
      curTime = GetTickCount()) {
    // enumerate all windows
    EnumWindows((WNDENUMPROC)EnumWaitForAnyWindowProc, (long)&perlEnumWindow);

    // did we found a window
    if(perlEnumWindow.hWnd)
      break;

    // ckeck for overflow
    if(threadInfo->timeout && curTime < startTime)
      threadInfo->timeout -= 0xffffffff - startTime + curTime;

    // check for timeout
    if(threadInfo->timeout && curTime - startTime >= threadInfo->timeout) {
      // set thread error
      threadInfo->lastError = ERROR_TIMEOUT_ELAPSED;

      // set thread end marker
      threadInfo->threadExitFlag = TRUE;

      // free memory
      sv_free(threadInfo->pattern);

      return 0;
    }

    // wait a while
    Sleep(threadInfo->refresh);
  }

  // free memory
  sv_free(threadInfo->pattern);

  // do all defined actions now
  for(int count = 0; count <= av_len(threadInfo->actions); count++) {
    SV **action = av_fetch(threadInfo->actions, count, 0);

    if(!action)
      continue;

    // shall we send keys
    if(!stricmp(SvPV(*action, PL_na), "keys")) {
      // keys are defined in the next array item
      if(action = av_fetch(threadInfo->actions, ++count, 0))
        SendKeys(perlEnumWindow.hWnd, SvPV(*action, PL_na), TRUE, 0,
                 &threadInfo->lastError);
      continue;
    }

    // close that window
    if(!stricmp(SvPV(*action, PL_na), "close")) {
      SendMessage(perlEnumWindow.hWnd, WM_CLOSE, 0, 0);
      continue;
    }

    // posts a close to that window
    if(!stricmp(SvPV(*action, PL_na), "postclose")) {
      PostMessage(perlEnumWindow.hWnd, WM_CLOSE, 0, 0);
      continue;
    }

    // wait now
    if(!stricmp(SvPV(*action, PL_na), "wait")) {
      // wait time is defined in the next array item
      if(action = av_fetch(threadInfo->actions, ++count, 0))
        Sleep(SvIV(*action));

      continue;
    }

    // kill process hWnd belongs
    if(!stricmp(SvPV(*action, PL_na), "kill")) {
      DWORD processId = 0;

      if(GetWindowThreadProcessId(perlEnumWindow.hWnd, &processId)) {
        HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, FALSE, processId);

        if(hProcess && !TerminateProcess(hProcess, 0))
          threadInfo->lastError = GetLastError();
      }

      continue;
    }
  }

  av_undef(threadInfo->actions);

  // set thread end marker
  threadInfo->threadExitFlag = TRUE;

  // return success
  return 1;
}

///////////////////////////////////////////////////////////////////////////////
//
// creates a thread that waits for a window title; if window is found, all
// defined actions will be applied
//
// param:  title   - window title (grep like expressions are allowed; search is
//                   case insensitive)
//         action  - actions to apply
//         timeout - timeout value in ms (until the function returns if no
//                   window was found)
//         refresh - refresh cycle to look for the window in ms
//
// return: success - true
//         failure - false
//
// note:   you should specify a refresh value (f.e. 50 ms); otherwise the
//         function loops and consumes about 70% of cpu power;
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_WaitForAnyWindowAsynch)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // parameters
  SV *title = NULL;
  SV *thread = NULL;
  AV *actions = NULL;

  // check arguments
  if((items == 4 || items == 5) && SvPOK(title = ST(0)) && SvROK(thread = ST(1)) &&
     SvROK(actions = (AV*)ST(2)) && SvTYPE(actions = (AV*)SvRV(actions)) == SVt_PVAV &&
     SvIOKp(ST(3)) && (items != 5 || SvIOKp(ST(4)))) {
    DWORD timeout = SvIV(ST(3));
    DWORD refresh = items == 5 ? SvIV(ST(4)) : 0;

    thread = (SV*)SvRV(thread);

    // create thread info struct
    PPerlThreadInfoStruct threadInfo = new PerlThreadInfoStruct;

    if(threadInfo) {
      memset(threadInfo, 0, sizeof(PerlThreadInfoStruct));

      // store members
#ifndef PERL_5_6_0
      threadInfo->perl = pPerl;
#endif // PERL_5_6_0

      threadInfo->timeout = timeout;
      threadInfo->refresh = refresh;
      threadInfo->pattern = newSVsv(title);

      threadInfo->actions = newAV();
      for(int count = 0; count <= av_len(actions); count++) {
        SV **action = av_fetch(actions, count, 0);

        if(action)
          av_push(threadInfo->actions, newSVsv(*action));
      }

      // create thread
      DWORD threadId = 0;
      threadInfo->hThread =
        CreateThread(NULL, 0, WaitForAnyWindowAsynchThreadFunc, (PVOID)threadInfo, 0,
                     &threadId);

      // add thread to list
      AsynchThreadList.AddTail(threadInfo);

      // store thread handle
      sv_setiv(thread, (long)threadInfo->hThread);
    }
    else
      LastError(NOT_ENOUGTH_MEMORY_ERROR);
  }
  else
    croak("Usage: Win32::Setupsup::WaitForAnyWindowAsynch($title, \\$hTread, \\@actions,"
          " $timeout, [$refresh])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// waits for a window close
//
// param:  window  - window handle
//         timeout - timeout value in ms (until the function returns if the
//                   window was not closed)
//         refresh - refresh cycle to look for the window in ms
//
// return: success - true (window was closed)
//         failure - false (timeout expired)
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_WaitForWindowClose)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // check arguments
  if((items == 2 || items == 3) && SvIOKp(ST(0)) && SvIOKp(ST(1)) &&
     (items == 2 || SvIOKp(ST(2)))) {
    HWND hWnd = (HWND)SvIV(ST(0));
    DWORD timeout = SvIV(ST(1));
    DWORD refresh = items == 3 ? SvIV(ST(2)) : 0;

    for(DWORD startTime = GetTickCount(), curTime = startTime; TRUE;
        curTime = GetTickCount()) {
      // look for the window; if handle is invalid, break
      if(!IsWindow(hWnd))
        break;

      // ckeck for overflow
      if(timeout && curTime < startTime)
        timeout -= 0xffffffff - startTime + curTime;

      // check for timeout
      if(timeout && curTime - startTime >= timeout) {
        LastError(ERROR_TIMEOUT_ELAPSED);
        break;
      }

      // wait a while
      Sleep(refresh);
    }
  }
  else
    croak("Usage: Win32::Setupsup::WaitForWindowClose($window, $timeout, [$refresh])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// get the text of a window
//
// param:  window     - window handle
//         windowtext - returned window text
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetWindowText)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *window = NULL, *windowText = NULL;

  // check arguments
  if(items == 2 && SvIOKp(window = ST(0)) && SvROK(windowText = ST(1))) {
    // make a reference
    windowText = SvRV(windowText);

    // calculate and allocate memory for window text
    HWND hWnd = (HWND)SvIV(window);
    DWORD windowLen = GetWindowTextLength(hWnd);
    PSTR windowBuf = new char[++windowLen];

    if(windowBuf) {
      // get window text
      *windowBuf = 0;
      GetWindowText(hWnd, windowBuf, windowLen);

      // copy the text to windowBuf
      sv_setpv(windowText, windowBuf);

      // clear allocated memory
      delete windowBuf;
    }
    else
      LastError(NOT_ENOUGTH_MEMORY_ERROR);
  }
  else
    croak("Usage: Win32::Setupsup::GetWindowText($window, \\$windowtext)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the window text
//
// param:  window     - window handle
//         windowtext - window text to set
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_SetWindowText)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *window = NULL, *windowText = NULL;

  // check arguments
  if(items == 2 && SvIOKp(window = ST(0)) && SvOK(windowText = ST(1)))
    // set window text
    SetWindowText((HWND)SvIV(window), SvPV(windowText, PL_na));
  else
    croak("Usage: Win32::Setupsup::SetWindowText($window, $windowtext)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the handle of an dialog item
//
// param:  window     - window handle
//         windowtext - returned window text
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetDlgItem)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *window = NULL, *id = NULL, *item = NULL;

  // check arguments
  if(items == 3 && SvIOKp(window = ST(0)) && SvIOKp(id = ST(1)) &&
     SvROK(item = ST(2))) {
    // make a reference
    item = SvRV(item);

    // get handle now
    HWND hDlgItem = GetDlgItem((HWND)SvIV(window), SvIV(id));

    // copy the dialog item handle
    sv_setiv(item, (long)hDlgItem);
  }
  else
    croak("Usage: Win32::Setupsup::GetDlgItem($window, $id, \\$item)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the focus to window
//
// param:  window     - window handle
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_SetFocus)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *window = NULL;

  // check arguments
  if(items == 1 && SvIOKp(window = ST(0))) {
    HWND hWnd = (HWND)SvIV(window);

    // must attach to the thread of the window and ...
    if(AttachThreadInput(GetCurrentThreadId(),
                         GetWindowThreadProcessId(hWnd, NULL), TRUE)) {
      SetFocus(hWnd);

      // ... now detach
      AttachThreadInput(GetCurrentThreadId(),
                        GetWindowThreadProcessId(hWnd, NULL), FALSE);
    }
  }
  else
    croak("Usage: Win32::Setupsup::SetFocus($window)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// get the index of a property string
//
// param:  str - property string
//
// return: success - app. index
//         failure - 0
//
///////////////////////////////////////////////////////////////////////////////

int GetPropertyIndex(PSTR str)
{
  // do a switch on the first char for speed ...
  switch(tolower(*str)) {
   case 'c':
    // ... and return app. index if string found
    RETURN_IDX_IF_EQUAL(CHECKED, str);
    RETURN_IDX_IF_EQUAL(CLASS, str);
    RETURN_IDX_IF_EQUAL(CLASSATOM, str);
    RETURN_IDX_IF_EQUAL(CLASSBRUSH, str);
    RETURN_IDX_IF_EQUAL(CLASSCURSOR, str);
    RETURN_IDX_IF_EQUAL(CLASSICON, str);
    RETURN_IDX_IF_EQUAL(CLASSICONSMALL, str);
    RETURN_IDX_IF_EQUAL(CLASSMENU, str);
    RETURN_IDX_IF_EQUAL(CLASSMODULE, str);
    RETURN_IDX_IF_EQUAL(CLASSPROC, str);
    RETURN_IDX_IF_EQUAL(CLASSSTYLE, str);
    RETURN_IDX_IF_EQUAL(CLIENT, str);
    break;

   case 'd':
    RETURN_IDX_IF_EQUAL(DESKTOP, str);
    RETURN_IDX_IF_EQUAL(DLGPROC, str);
    break;

   case 'e':
    RETURN_IDX_IF_EQUAL(ENABLED, str);
    RETURN_IDX_IF_EQUAL(EXTSTYLE, str);
    break;

   case 'f':
    RETURN_IDX_IF_EQUAL(FOCUSED, str);
    RETURN_IDX_IF_EQUAL(FOREGROUND, str);
    break;

   case 'i':
    RETURN_IDX_IF_EQUAL(ICONIC, str);
    RETURN_IDX_IF_EQUAL(ID, str);
    RETURN_IDX_IF_EQUAL(INSTANCE, str);
    break;

   case 'l':
    RETURN_IDX_IF_EQUAL(LASTACTIVEPOPUP, str);
    break;

   case 'm':
    RETURN_IDX_IF_EQUAL(MENU, str);
    break;

   case 'n':
    RETURN_IDX_IF_EQUAL(NEXT, str);
    break;

   case 'p':
    RETURN_IDX_IF_EQUAL(PARENT, str);
    RETURN_IDX_IF_EQUAL(PREV, str);
    RETURN_IDX_IF_EQUAL(PID, str);
    break;

   case 'r':
    RETURN_IDX_IF_EQUAL(RECT, str);
    break;

   case 's':
    RETURN_IDX_IF_EQUAL(STYLE, str);
    break;

   case 't':
    RETURN_IDX_IF_EQUAL(TEXT, str);
    RETURN_IDX_IF_EQUAL(TID, str);
    RETURN_IDX_IF_EQUAL(TOP, str);
    break;

   case 'u':
    RETURN_IDX_IF_EQUAL(UNICODE, str);
    break;

   case 'v':
    RETURN_IDX_IF_EQUAL(VALID, str);
    RETURN_IDX_IF_EQUAL(VISIBLE, str);
    break;

   case 'w':
    RETURN_IDX_IF_EQUAL(WNDPROC, str);
    break;

   case 'z':
    RETURN_IDX_IF_EQUAL(ZOOMED, str);
    break;
  }

  // index not found
  return 0;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets a window property and stores it to the prop hash
//
// param:  hWnd  - handle to window
//         index - property index
//         pPerl - pointer to the perl object
//         prop  - hash pointer to store the property
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetAndStoreWindowProp(HWND hWnd, int index, PERL_CALL HV *prop)
{
  BOOL result = TRUE;

  // look for the index and get the property
  switch(index) {
   case ID_CHECKED:
   {
     int checkState = SendMessage(hWnd, BM_GETCHECK, 0, 0);
     if(checkState == BST_CHECKED)
       hv_store(prop, PROP_CHECKED, strlen(PROP_CHECKED), newSViv(1), 0);
     else
       if(checkState == BST_INDETERMINATE)
         hv_store(prop, PROP_CHECKED, strlen(PROP_CHECKED), newSViv(2), 0);
       else
         hv_store(prop, PROP_CHECKED, strlen(PROP_CHECKED), newSViv(0), 0);
   }
   break;

   case ID_CLASS:
   {
     char classBuf[TEXT_BUF_SIZE] = "";

     GetClassName(hWnd, classBuf, TEXT_BUF_SIZE);
     hv_store(prop, PROP_CLASS, strlen(PROP_CLASS), newSVpv(classBuf,
                                                            strlen(classBuf)), 0);
   }
   break;

   case ID_CLASSATOM:
    hv_store(prop, PROP_CLASSATOM, strlen(PROP_CLASSATOM),
             newSViv(GetClassLong(hWnd, GCW_ATOM)), 0);
    break;

   case ID_CLASSBRUSH:
    hv_store(prop, PROP_CLASSBRUSH, strlen(PROP_CLASSBRUSH),
             newSViv(GetClassLong(hWnd, GCL_HBRBACKGROUND)), 0);
    break;

   case ID_CLASSCURSOR:
    hv_store(prop, PROP_CLASSCURSOR, strlen(PROP_CLASSCURSOR),
             newSViv(GetClassLong(hWnd, GCL_HCURSOR)), 0);
    break;

   case ID_CLASSICON:
    hv_store(prop, PROP_CLASSICON, strlen(PROP_CLASSICON),
             newSViv(GetClassLong(hWnd, GCL_HICON)), 0);
    break;

   case ID_CLASSICONSMALL:
    hv_store(prop, PROP_CLASSICONSMALL, strlen(PROP_CLASSICONSMALL),
             newSViv(GetClassLong(hWnd, GCL_HICONSM)), 0);
    break;

   case ID_CLASSMENU:
    hv_store(prop, PROP_CLASSMENU, strlen(PROP_CLASSMENU),
             newSViv(GetClassLong(hWnd, GCL_MENUNAME)), 0);
    break;

   case ID_CLASSMODULE:
    hv_store(prop, PROP_CLASSMODULE, strlen(PROP_CLASSMODULE),
             newSViv(GetClassLong(hWnd, GCL_HMODULE)), 0);
    break;

   case ID_CLASSPROC:
    hv_store(prop, PROP_CLASSPROC, strlen(PROP_CLASSPROC),
             newSViv(GetClassLong(hWnd, GCL_WNDPROC)), 0);
    break;

   case ID_CLASSSTYLE:
    hv_store(prop, PROP_CLASSSTYLE, strlen(PROP_CLASSSTYLE),
             newSViv(GetClassLong(hWnd, GCL_STYLE)), 0);
    break;

   case ID_CLIENT:
   {
     RECT rect = {0, 0, 0, 0};

     if(GetClientRect(hWnd, &rect)) {
       // store a hash pointer as result
       HV *hvRect = newHV();

       hv_store(hvRect, PROP_RECT_LEFT, strlen(PROP_RECT_LEFT),
                newSViv(rect.left), 0);
       hv_store(hvRect, PROP_RECT_TOP, strlen(PROP_RECT_TOP),
                newSViv(rect.top), 0);
       hv_store(hvRect, PROP_RECT_RIGHT, strlen(PROP_RECT_RIGHT),
                newSViv(rect.right), 0);
       hv_store(hvRect, PROP_RECT_BOTTOM, strlen(PROP_RECT_BOTTOM),
                newSViv(rect.bottom), 0);

       hv_store(prop, PROP_CLIENT, strlen(PROP_CLIENT),
                newSVsv(newRV((SV*)hvRect)), 0);
     }
     else
       SetErrorAndResult;
   }
   break;

   case ID_DESKTOP:
    hv_store(prop, PROP_DESKTOP, strlen(PROP_DESKTOP),
             newSViv((DWORD)GetDesktopWindow()), 0);
    break;

   case ID_DLGPROC:
    hv_store(prop, PROP_DLGPROC, strlen(PROP_DLGPROC),
             newSViv(GetWindowLong(hWnd, DWL_DLGPROC)), 0);
    break;

   case ID_ENABLED:
    hv_store(prop, PROP_ENABLED, strlen(PROP_ENABLED),
             newSViv(IsWindowEnabled(hWnd)), 0);
    break;

   case ID_EXTSTYLE:
    hv_store(prop, PROP_EXTSTYLE, strlen(PROP_EXTSTYLE),
             newSViv(GetWindowLong(hWnd, GWL_EXSTYLE)), 0);
    break;

   case ID_FOCUSED: {
     DWORD focused = 0;

     // must attach to the thread of the window and ...
     if(AttachThreadInput(GetCurrentThreadId(),
                          GetWindowThreadProcessId(hWnd, NULL), TRUE)) {
       focused = GetFocus() == hWnd ? 1 : 0;

       // ... now detach
       AttachThreadInput(GetCurrentThreadId(),
                         GetWindowThreadProcessId(hWnd, NULL), FALSE);
     }

     hv_store(prop, PROP_FOCUSED, strlen(PROP_FOCUSED), newSViv(focused), 0);
   }
    break;

   case ID_FOREGROUND:
    hv_store(prop, PROP_FOREGROUND, strlen(PROP_FOREGROUND),
             newSViv((ULONG)GetForegroundWindow()), 0);
    break;

   case ID_ICONIC:
    hv_store(prop, PROP_ICONIC, strlen(PROP_ICONIC), newSViv(IsIconic(hWnd)), 0);
    break;

   case ID_ID:
    hv_store(prop, PROP_ID, strlen(PROP_ID),
             newSViv(GetWindowLong(hWnd, GWL_ID)), 0);
    break;

   case ID_INSTANCE:
    hv_store(prop, PROP_INSTANCE, strlen(PROP_INSTANCE),
             newSViv(GetWindowLong(hWnd, GWL_HINSTANCE)), 0);
    break;

   case ID_LASTACTIVEPOPUP:
    hv_store(prop, PROP_LASTACTIVEPOPUP, strlen(PROP_LASTACTIVEPOPUP),
             newSViv((ULONG)GetLastActivePopup(hWnd)), 0);
    break;

   case ID_MENU:
    hv_store(prop, PROP_MENU, strlen(PROP_MENU), newSViv((ULONG)GetMenu(hWnd)), 0);
    break;

   case ID_NEXT:
    hv_store(prop, PROP_NEXT, strlen(PROP_NEXT),
             newSViv((ULONG)GetNextWindow(hWnd, GW_HWNDNEXT)), 0);
    break;

   case ID_PARENT:
    hv_store(prop, PROP_PARENT, strlen(PROP_PARENT),
             newSViv((ULONG)GetParent(hWnd)), 0);
    break;

   case ID_PREV:
    hv_store(prop, PROP_PREV, strlen(PROP_PREV),
             newSViv((ULONG)GetNextWindow(hWnd, GW_HWNDPREV)), 0);
    break;

   case ID_PID:
   {
     DWORD processId = 0;

     GetWindowThreadProcessId(hWnd, &processId);
     hv_store(prop, PROP_PID, strlen(PROP_PID), newSViv(processId), 0);
   }
   break;

   case ID_RECT:
   {
     RECT rect = {0, 0, 0, 0};

     if(GetWindowRect(hWnd, &rect)) {
       // store a hash pointer as result
       HV *hvRect = newHV();

       hv_store(hvRect, PROP_RECT_LEFT, strlen(PROP_RECT_LEFT),
                newSViv(rect.left), 0);
       hv_store(hvRect, PROP_RECT_TOP, strlen(PROP_RECT_TOP),
                newSViv(rect.top), 0);
       hv_store(hvRect, PROP_RECT_RIGHT, strlen(PROP_RECT_RIGHT),
                newSViv(rect.right), 0);
       hv_store(hvRect, PROP_RECT_BOTTOM, strlen(PROP_RECT_BOTTOM),
                newSViv(rect.bottom), 0);

       hv_store(prop, PROP_RECT, strlen(PROP_RECT),
                newSVsv(newRV((SV*)hvRect)), 0);
     }
     else
       SetErrorAndResult;
   }
   break;

   case ID_STYLE:
    hv_store(prop, PROP_STYLE, strlen(PROP_STYLE),
             newSViv((ULONG)GetWindowLong(hWnd, GWL_STYLE)), 0);
    break;

   case ID_TEXT:
   {
     char textBuf[TEXT_BUF_SIZE] = "";

     GetWindowText(hWnd, textBuf, TEXT_BUF_SIZE);
     hv_store(prop, PROP_TEXT, strlen(PROP_TEXT), newSVpv(textBuf, strlen(textBuf)), 0);
   }
   break;

   case ID_TID:
    hv_store(prop, PROP_TID, strlen(PROP_TID),
             newSViv(GetWindowThreadProcessId(hWnd, NULL)), 0);
    break;

   case ID_TOP:
    hv_store(prop, PROP_TOP, strlen(PROP_TOP),
             newSViv((ULONG)GetTopWindow(hWnd)), 0);
    break;

   case ID_UNICODE:
    hv_store(prop, PROP_UNICODE, strlen(PROP_UNICODE),
             newSViv(IsWindowUnicode(hWnd)), 0);
    break;

   case ID_VALID:
    hv_store(prop, PROP_VALID, strlen(PROP_VALID), newSViv(IsWindow(hWnd)), 0);
    break;

   case ID_VISIBLE:
    hv_store(prop, PROP_VISIBLE, strlen(PROP_VISIBLE),
             newSViv(IsWindowVisible(hWnd)), 0);
    break;

   case ID_WNDPROC:
    hv_store(prop, PROP_WNDPROC, strlen(PROP_WNDPROC),
             newSViv(GetWindowLong(hWnd, GWL_WNDPROC)), 0);
    break;

   case ID_ZOOMED:
    hv_store(prop, PROP_ZOOMED, strlen(PROP_ZOOMED), newSViv(IsZoomed(hWnd)), 0);
    break;
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the properties of a window
//
// param:  window     - window handle
//         proptoget  - defines all property names to get
//         windowprop - returned window properties
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetWindowProperties)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *window = NULL;
  AV *propToGet = NULL;
  HV *windowProp = NULL;
  HV **clearRect = NULL;

  // check arguments
  if(items == 3 && SvIOKp(window = ST(0)) && SvROK(propToGet = (AV*)ST(1)) &&
     SvTYPE(propToGet = (AV*)SvRV(propToGet)) == SVt_PVAV &&
     SvROK(windowProp = (HV*)ST(2)) &&
     SvTYPE(windowProp = (HV*)SvRV(windowProp)) == SVt_PVHV) {
    // get window handle
    HWND hWnd = (HWND)SvIV(window);

    // clear reference
    clearRect = (HV**)hv_fetch(windowProp, PROP_RECT, strlen(PROP_RECT), 0);
    if(clearRect && *clearRect)
      hv_clear(*clearRect);

    clearRect = (HV**)hv_fetch(windowProp, PROP_CLIENT, strlen(PROP_CLIENT), 0);
    if(clearRect && *clearRect)
      hv_clear(*clearRect);

    hv_clear(windowProp);

    for(int count = 0; count <= av_len(propToGet); count++) {
      SV **curPropToGet = NULL;
      PSTR curPropToGetName = NULL;
      int curPropToGetIdx = 0;

      // look for app. property index
      if(!(curPropToGet = av_fetch(propToGet, count, 0)) ||
         !(curPropToGetName = SvPV(*curPropToGet, PL_na)) ||
         !(curPropToGetIdx = GetPropertyIndex(curPropToGetName))) {
        LastError(UNKNOWN_PROPERTY_ERROR);

        clearRect = (HV**)hv_fetch(windowProp, PROP_RECT, strlen(PROP_RECT), 0);
        if(clearRect && *clearRect)
          hv_clear(*clearRect);

        clearRect = (HV**)hv_fetch(windowProp, PROP_CLIENT, strlen(PROP_CLIENT), 0);
        if(clearRect && *clearRect)
          hv_clear(*clearRect);

        hv_clear(windowProp);
        break;
      }

      // now get and store the property
      if(!GetAndStoreWindowProp(hWnd, curPropToGetIdx, P_PERL windowProp)) {
        clearRect = (HV**)hv_fetch(windowProp, PROP_RECT, strlen(PROP_RECT), 0);
        if(clearRect && *clearRect)
          hv_clear(*clearRect);

        clearRect = (HV**)hv_fetch(windowProp, PROP_CLIENT, strlen(PROP_CLIENT), 0);
        if(clearRect && *clearRect)
          hv_clear(*clearRect);

        hv_clear(windowProp);
        break;
      }
    }
  }
  else
    croak("Usage: Win32::Setupsup::GetWindowProperties($window, @proptoget, "
          "\\%%windowprop)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// sets a window property
//
// param:  hWnd  - handle to window
//         index - property index
//         pPerl - pointer to the perl object
//         prop  - scalar pointer to store the property
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

BOOL SetWindowProp(HWND hWnd, int index, PERL_CALL SV *prop)
{
  BOOL result = TRUE;

  // look for the index and get the property
  switch(index) {
   case ID_CHECKED:
    SendMessage(hWnd, BM_SETCHECK, SvIV(prop), 0);
    break;

   case ID_CLASSBRUSH:
    SetClassLong(hWnd, GCL_HBRBACKGROUND, SvIV(prop));
    break;

   case ID_CLASSCURSOR:
    SetClassLong(hWnd, GCL_HCURSOR, SvIV(prop));
    break;

   case ID_CLASSICON:
    SetClassLong(hWnd, GCL_HICON, SvIV(prop));
    break;

   case ID_CLASSICONSMALL:
    SetClassLong(hWnd, GCL_HICONSM, SvIV(prop));
    break;

   case ID_CLASSMENU:
    SetClassLong(hWnd, GCL_MENUNAME, SvIV(prop));
    break;

   case ID_CLASSMODULE:
    SetClassLong(hWnd, GCL_HMODULE, SvIV(prop));
    break;

   case ID_CLASSSTYLE:
    SetClassLong(hWnd, GCL_STYLE, SvIV(prop));
    break;

   case ID_DLGPROC:
    SetWindowLong(hWnd, DWL_DLGPROC, SvIV(prop));
    break;

   case ID_ENABLED:
    EnableWindow(hWnd, SvIV(prop));
    break;

   case ID_EXTSTYLE:
    SetWindowLong(hWnd, GWL_EXSTYLE, SvIV(prop));
    break;

   case ID_FOREGROUND:
    if(SvIV(prop))
      SetForegroundWindow(hWnd);
    break;

   case ID_ICONIC:
    ShowWindow(hWnd, SvIV(prop) ? SW_MINIMIZE : SW_SHOW);
    break;

   case ID_ID:
    SetWindowLong(hWnd, GWL_ID, SvIV(prop));
    break;

   case ID_INSTANCE:
    SetWindowLong(hWnd, GWL_HINSTANCE, SvIV(prop));
    break;

   case ID_MENU:
    SetMenu(hWnd, (HMENU)SvIV(prop));
    break;

   case ID_NEXT:
   {
     HWND hPrevWnd = GetNextWindow(hWnd, GW_HWNDPREV);

     SetWindowPos(hWnd, hPrevWnd, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
   }
   break;

   case ID_PARENT:
    SetParent(hWnd, (HWND)SvIV(prop));
    break;

   case ID_PREV:
    SetWindowPos(hWnd, (HWND)SvIV(prop), 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    break;

   case ID_RECT:
    BREAK_IF_NO_HREF_PROP_TYPE(prop);
    {
      RECT rect = {0, 0, 0, 0}, parent = {0, 0, 0, 0};
      HV *hRect = (HV*)SvRV(prop);
      SV **rectCoord;

      // if hWnd is a child window ...
      if(GetParent(hWnd) != GetDesktopWindow())
        // ... we need parent's rect
        GetWindowRect(GetParent(hWnd), &parent);

      rect.left =
        (rectCoord = hv_fetch(hRect, PROP_RECT_LEFT, strlen(PROP_RECT_LEFT), 0)) ?
        SvIV(*rectCoord) : 0;

      rect.top =
        (rectCoord = hv_fetch(hRect, PROP_RECT_TOP, strlen(PROP_RECT_TOP), 0)) ?
        SvIV(*rectCoord) : 0;

      rect.right =
        (rectCoord = hv_fetch(hRect, PROP_RECT_RIGHT, strlen(PROP_RECT_RIGHT), 0)) ?
        SvIV(*rectCoord) : 0;
      rect.right -= rect.left;
      rect.left -= parent.left;

      rect.bottom =
        (rectCoord = hv_fetch(hRect, PROP_RECT_BOTTOM, strlen(PROP_RECT_BOTTOM), 0)) ?
        SvIV(*rectCoord) : 0;
      rect.bottom -= rect.top;
      rect.top -= parent.top;

      MoveWindow(hWnd, rect.left, rect.top, rect.right, rect.bottom, TRUE);
    }
    break;

   case ID_STYLE:
    SetWindowLong(hWnd, GWL_STYLE, SvIV(prop));
    break;

   case ID_TEXT:
    SetWindowText(hWnd, SvPV(prop, PL_na));
    break;

   case ID_TOP:
    SetWindowPos(hWnd, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE);
    break;

   case ID_VISIBLE:
    ShowWindow(hWnd, SvIV(prop) ? SW_SHOW : SW_HIDE);
    break;

   case ID_WNDPROC:
    SetWindowLong(hWnd, GWL_WNDPROC, SvIV(prop));
    break;

   case ID_ZOOMED:
    ShowWindow(hWnd, SvIV(prop) ? SW_MAXIMIZE : SW_SHOW);
    break;
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// sets window properties
//
// param:  window           - window handle
//         windowproperties - window properties to set
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_SetWindowProperties)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *window = NULL;
  HV *windowProp = NULL;

  // check arguments
  if(items == 2 && SvIOKp(window = ST(0)) && SvROK(windowProp = (HV*)ST(1)) &&
     SvTYPE(windowProp = (HV*)SvRV(windowProp)) == SVt_PVHV) {
    // get window handle
    HWND hWnd = (HWND)SvIV(window);

    PSTR keyName = NULL;
    long keyNameLen = 0;
    SV *property = NULL;

    for(hv_iterinit(windowProp);
        property = hv_iternextsv(windowProp, &keyName, &keyNameLen); ) {
      // get the property index
      int propIdx = GetPropertyIndex(keyName);

      if(!propIdx) {
        LastError(UNKNOWN_PROPERTY_ERROR);
        break;
      }

      // now set the property
      if(!SetWindowProp(hWnd, propIdx, P_PERL property))
        break;
    }
  }
  else
    croak("Usage: Win32::Setupsup::SetWindowProperties($window, \\%windowprop)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the sid from an account name and converts it in an text string
//
// param:  pPerl     - pointer to perl object
//         server    - server to execute the command
//         account   - account name
//         sid       - pointer to sid (will receive the result)
//         lastError - pointer to an error var
//
// return: success - true
//         failure - false (error in lastError)
//
///////////////////////////////////////////////////////////////////////////////

BOOL ConvertSidToStr(PERL_CALL SV *server, SV *account, SV *sid, DWORD *lastError)
{
  ErrorAndResult;

  // sid pointer and size
  PSID sidPtr = NULL;
  DWORD sidSize = 0;
  // domain pointer and size
  PSTR domain = NULL;
  DWORD domainSize = 0;
  SID_NAME_USE sidNameUse;
  // sid string
  PSTR sidStr = NULL;

  __try {
    // get the size for the sid buffer
    LookupAccountName(SvPV(server, PL_na), SvPV(account, PL_na), sidPtr, &sidSize,
                      domain, &domainSize, &sidNameUse);

    // normally we have to allocate memory; otherwise there is an error
    if(GetLastError() != ERROR_INSUFFICIENT_BUFFER)
      LeaveFalse();

    // alloc memory
    if(!(sidPtr = (PSID) new char[sidSize]) || !(domain = new char[domainSize]))
      LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

    memset(sidPtr, 0, sidSize);
    memset(domain, 0, domainSize);

    // get the sid and return it if successfully
    if(!LookupAccountName(SvPV(server, PL_na), SvPV(account, PL_na), sidPtr, &sidSize,
                          domain, &domainSize, &sidNameUse))
      LeaveFalse();

    // sid revision level
    DWORD SidRevision = SID_REVISION;

    // obtain SidIdentifierAuthority and sidsubauthority count
    PSID_IDENTIFIER_AUTHORITY sidAuthority = GetSidIdentifierAuthority(sidPtr);
    DWORD subAuthorities = *GetSidSubAuthorityCount(sidPtr);

    // compute buffer length: S-SID_REVISION- + identifierauth. + subauth. + NULL
    // and alloc memory
    if(!(sidStr = new char[15 + 12 * (subAuthorities + 1) + 1]))
      LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

    memset(sidStr, 0, 15 + 12 * (subAuthorities + 1) + 1);

    // prepare S-SID_REVISION - currently always S-1-
    wsprintf(sidStr, "S-%lu-", SidRevision);

    // prepare SidIdentifierAuthority
    if(sidAuthority->Value[0] || sidAuthority->Value[1])
      wsprintf(sidStr + strlen(sidStr), "0x%02hx%02hx%02hx%02hx%02hx%02hx",
               (USHORT)sidAuthority->Value[0],
               (USHORT)sidAuthority->Value[1],
               (USHORT)sidAuthority->Value[2],
               (USHORT)sidAuthority->Value[3],
               (USHORT)sidAuthority->Value[4],
               (USHORT)sidAuthority->Value[5]);
    else
      wsprintf(sidStr + strlen(sidStr), "%lu",
               (ULONG)(sidAuthority->Value[5]) +
               (ULONG)(sidAuthority->Value[4] << 8) +
               (ULONG)(sidAuthority->Value[3] << 16) +
               (ULONG)(sidAuthority->Value[2] << 24));

    // get SidSubAuthorities
    for(DWORD count = 0 ; count < subAuthorities ; count++)
      wsprintf(sidStr + strlen(sidStr), "-%lu", *GetSidSubAuthority(sidPtr, count));

    // store value
    sv_setpv(sid, sidStr);
  }
  __finally {
    // free pointers
    CleanPtr(sidPtr);
    CleanPtr(domain);
    CleanPtr(sidStr);

    SetErrorVar();
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// converts the sid from an account to an string
//
// param:  server    - server to execute the command
//         account   - account name
//         sid       - returned sid string
//
// return: success - true
//         failure - false
//
// note:   if you need an account from a specific domain or server, you should
//         specify domain\account or server\account. Otherwise the account will
//         be resolved from trusted domains too. The first try will be made on
//         $server (if $server is empty the local machine is choosen). If it
//         could not be resolved the next try is in the domain. After that all
//         trusted domains will be tried. If you need a well known account
//         (like system or everyone) don't specify a server or domain name.
//         Otherwise the function will fail.
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_AccountToSid)
{
  dXSARGS;

  ErrorAndResult;

  // reset last error
  LastError(0);

  // parameter
  SV *server = NULL;
  SV *account = NULL;
  SV *sid = NULL;

  // check arguments
  if(items == 3 && SvPOKp(server = ST(0)) && SvPOKp(account = ST(1)) &&
     SvROK(sid = ST(2))) {
    // make a reference
    sid = (SV*)SvRV(sid);

    // converts account to sid and then sid to string
    ConvertSidToStr(P_PERL server, account, sid, &error);
    LastError(error);
  }
  else
    croak("Usage: Win32::Setupsup::AccountToSid($server, $account, \\$sid)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// converts a string to a sid and resolves this sid to an account name
//
// param:  pPerl     - pointer to perl object
//         server    - server to execute the command
//         sid       - pointer to sid string
//         account   - account name (will receive the result)
//         lastError - pointer to an error var
//
// return: success - true
//         failure - false (error in lastError)
//
///////////////////////////////////////////////////////////////////////////////

BOOL ConvertStrToSid(PERL_CALL SV *server, SV *sid, SV *account, DWORD *lastError)
{
  ErrorAndResult;

  // sid pointer and size
  PSID sidPtr = NULL;
  //DWORD sidSize = 0;
  // account pointer and size
  PSTR accountPtr = NULL;
  DWORD accountSize = 0;
  // domain pointer and size
  PSTR domain = NULL;
  DWORD domainSize = 0;
  SID_NAME_USE sidNameUse;
  // sid string
  PSTR sidStr = NULL;

  __try {
    // alloc memory for sid string ...
    if(!(sidStr = new char[SvLEN(sid)]))
      LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

    // ... and copy it
    strcpy(sidStr, SvPV(sid, PL_na));

    PSTR sidTokens[MAX_SID_TOKENS];
    DWORD sidRevision = 0;

    memset(sidTokens, 0, sizeof(sidTokens));

    // set string begin
    sidTokens[0] = sidStr;

    // tokenize sid string
    int count = 1;
    while (TRUE) {
      PSTR token = strchr(sidTokens[count - 1], '-');

      if(!token || count >= MAX_SID_TOKENS)
        break;

      *token++ = 0;
      sidTokens[count++] = token;
    }

    // check sid string syntax
    if(count < 3 || count >= MAX_SID_TOKENS || stricmp(sidTokens[0], "s") ||
       sscanf(sidTokens[1], "%lu", &sidRevision) != 1 || sidRevision != SID_REVISION)
      LeaveFalseError(INVALID_SID_ERROR);

    // get authority and sub authorities
    SID_IDENTIFIER_AUTHORITY sidAuthority;

    memset(&sidAuthority, 0, sizeof(sidAuthority));

    if(!strnicmp(sidTokens[2], "0x", 2)) {
      if(sscanf(sidTokens[2], "02hx%02hx%02hx%02hx%02hx%02hx",
                &sidAuthority.Value[0], &sidAuthority.Value[1],
                &sidAuthority.Value[2], &sidAuthority.Value[3],
                &sidAuthority.Value[4], &sidAuthority.Value[5]) != 6)
        LeaveFalseError(INVALID_SID_ERROR);
    }
    else {
      DWORD sidAuthorityValue = 0;

      if(sscanf(sidTokens[2], "%lu", &sidAuthorityValue) != 1)
        LeaveFalseError(INVALID_SID_ERROR);

      sidAuthority.Value[0] = sidAuthority.Value[1] = 0;
      sidAuthority.Value[2] = (BYTE)((sidAuthorityValue & 0xff000000) >> 24);
      sidAuthority.Value[3] = (BYTE)((sidAuthorityValue & 0x00ff0000) >> 16);
      sidAuthority.Value[4] = (BYTE)((sidAuthorityValue & 0x0000ff00) >> 8);
      sidAuthority.Value[5] = (BYTE)(sidAuthorityValue & 0x000000ff);
    }

    DWORD subAuthorities[8];

    memset(&subAuthorities, 0, sizeof(subAuthorities));

    count = 3;
    for(; count < MAX_SID_TOKENS && sidTokens[count]; count++)
      if(sscanf(sidTokens[count], "%lu", &subAuthorities[count - 3]) != 1)
        LeaveFalseError(INVALID_SID_ERROR);

    // assemble sid
    if(!AllocateAndInitializeSid(&sidAuthority, count - 3,
                                 subAuthorities[0], subAuthorities[1],
                                 subAuthorities[2], subAuthorities[3],
                                 subAuthorities[4], subAuthorities[5],
                                 subAuthorities[6], subAuthorities[7],
                                 &sidPtr))
      LeaveFalseError(INVALID_SID_ERROR);

    if(!IsValidSid(sidPtr)) {
      FreeSid(sidPtr);
      LeaveFalseError(INVALID_SID_ERROR);
    }

    // get the size for the account buffer
    LookupAccountSid(SvPV(server, PL_na), sidPtr, accountPtr, &accountSize,
                     domain, &domainSize, &sidNameUse);

    // normally we have to allocate memory; otherwise there is an error
    if(GetLastError() != ERROR_INSUFFICIENT_BUFFER)
      LeaveFalse();

    // alloc memory
    if(!(accountPtr = new char[accountSize]) || !(domain = new char[domainSize]))
      LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

    memset(accountPtr, 0, accountSize);
    memset(domain, 0, domainSize);

    if(!LookupAccountSid(SvPV(server, PL_na), sidPtr, accountPtr, &accountSize,
                         domain, &domainSize, &sidNameUse))
      LeaveFalse();

    // we store a domain name if there is one and if the account is not a system account
    // (authority == SECURITY_NT_AUTHORITY && subauthority[0] == SECURITY_NT_NON_UNIQUE)
    BYTE securityNtAuthority[] = SECURITY_NT_AUTHORITY;

    if(*domain && !memcmp(sidAuthority.Value, securityNtAuthority,
                          sizeof(securityNtAuthority)) &&
       subAuthorities[0] == SECURITY_NT_NON_UNIQUE) {
      sv_setpv(account, domain);
      sv_catpv(account, "\\");
      sv_catpv(account, accountPtr);
    }
    else
      sv_setpv(account, accountPtr);
  }
  __finally {
    // free pointers
    CleanPtr(sidPtr);
    CleanPtr(accountPtr);
    CleanPtr(domain);
    CleanPtr(sidStr);

    SetErrorVar();
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// converts a sid string to an account name
//
// param:  server    - server to execute the command
//         sid       - sid string
//         account   - returned account name
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_SidToAccount)
{
  dXSARGS;

  ErrorAndResult;

  // reset last error
  LastError(0);

  // parameter
  SV *server = NULL;
  SV *sid = NULL;
  SV *account = NULL;

  // check arguments
  if(items == 3 && SvPOKp(server = ST(0)) && SvPOKp(sid = ST(1)) &&
     SvROK(account = ST(2))) {
    // make a reference
    account = (SV*)SvRV(account);

    // converts string to sid and sid to account
    ConvertStrToSid(P_PERL server, sid, account, &error);
    LastError(error);
  }
  else
    croak("Usage: Win32::Setupsup::SidToAccount($server, $sid, \\$account)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// get the version information stored in a file
//
// param:  pPerl     - pointer to perl object
//         filename  - file name to get information about
//         fileinfo  - hash reference to get the file information
//         lastError - pointer to error var
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetVersionInfo(PERL_CALL SV *fileName, HV *fileInfo, DWORD *lastError)
{
  ErrorAndResult;

  // defined version keys
  PSTR versionKeys[] =
    {"Comments", "CompanyName", "FileDescription", "FileVersion", "InternalName",
     "LegalCopyright", "LegalTrademarks", "OriginalFilename", "PrivateBuild",
     "ProductName", "ProductVersion", "SpecialBuild"
    };

  // pointer to version data
  PSTR data = NULL;
  DWORD dummy = 0, size = 0;

  __try {
    // calculate size needed
    if(!(size = GetFileVersionInfoSize(SvPV(fileName, PL_na), &dummy)))
      LeaveFalse();

    // alloc memory
    if(!(data = new char[size]))
      LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

    memset(data, 0, size);

    // get version info
    if(!GetFileVersionInfo(SvPV(fileName, PL_na), dummy, size, data))
      LeaveFalse();

    VS_FIXEDFILEINFO *fixFileInfo = NULL;
    UINT fixFileInfoLen = 0;

    // get VS_FIXEDFILEINFO info
    if(!VerQueryValue(data, "\\", (PVOID*)&fixFileInfo, &fixFileInfoLen))
      LeaveFalse();

    // store values
    hv_store(fileInfo, "FileVersionMS", strlen("FileVersionMS"),
             newSViv(fixFileInfo->dwFileVersionMS), 0);
    hv_store(fileInfo, "FileVersionLS", strlen("FileVersionLS"),
             newSViv(fixFileInfo->dwFileVersionLS), 0);
    hv_store(fileInfo, "ProductVersionMS", strlen("ProductVersionMS"),
             newSViv(fixFileInfo->dwProductVersionMS), 0);
    hv_store(fileInfo, "ProductVersionLS", strlen("ProductVersionLS"),
             newSViv(fixFileInfo->dwProductVersionLS), 0);
    hv_store(fileInfo, "FileFlagsMask", strlen("FileFlagsMask"),
             newSViv(fixFileInfo->dwFileFlagsMask), 0);
    hv_store(fileInfo, "FileFlags", strlen("FileFlags"),
             newSViv(fixFileInfo->dwFileFlags), 0);
    hv_store(fileInfo, "FileOS", strlen("FileOS"),
             newSViv(fixFileInfo->dwFileOS), 0);
    hv_store(fileInfo, "FileType", strlen("FileType"),
             newSViv(fixFileInfo->dwFileType), 0);
    hv_store(fileInfo, "FileSubtype", strlen("FileSubtype"),
             newSViv(fixFileInfo->dwFileSubtype), 0);
    hv_store(fileInfo, "FileDateMS", strlen("FileDateMS"),
             newSViv(fixFileInfo->dwFileDateMS), 0);
    hv_store(fileInfo, "FileDateLS", strlen("FileDateLS"),
             newSViv(fixFileInfo->dwFileDateLS), 0);

    // we have to get the version info language
    char langBlock[32] = "\\StringFileInfo\\";
    PSTR langInfo = NULL, langBlockEnd = langBlock + strlen(langBlock);
    UINT langInfoSize = 0, langId = 0;

    // get the language now
    if(!VerQueryValue(data, langBlock, (PVOID*)&langInfo, &langInfoSize))
      LeaveFalse();

    // convert version language to numeric value
    sprintf(langBlock + strlen(langBlock), "%8S\\", langInfo + 6);
    if(sscanf(langBlockEnd, "%x", &langId) == 1) {
      langId >>= 16;

      char langName[64] = "";

      // get the language name now
      if(VerLanguageName(langId, langName, sizeof(langName)))
        hv_store(fileInfo, "Language", strlen("Language"),
                 newSVpv(langName, strlen(langName)), 0);
    }

    // try to get version info for each defined key
    for(int count = 0; count < sizeof(versionKeys) / sizeof(versionKeys[0]); count++) {
      char subBlock[64] = "";

      strcpy(subBlock, langBlock);
      strcat(subBlock, versionKeys[count]);

      PSTR verInfo = NULL;
      UINT verInfoSize = 0;

      // get it now
      if(VerQueryValue(data, subBlock, (PVOID*)&verInfo, &verInfoSize))
        hv_store(fileInfo, versionKeys[count], strlen(versionKeys[count]),
                 newSVpv(verInfo, strlen(verInfo)), 0);
    }
  }
  __finally {
    // clear allocated memory
    CleanPtr(data);

    SetErrorVar();
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// get the file information stored in a file
//
// param:  filename - file name to get information about
//         fileinfo - hash reference to get the file information
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetVersionInfo)
{
  dXSARGS;

  ErrorAndResult;

  // reset last error
  LastError(0);

  // file name and version info pointer
  SV *fileName = NULL;
  HV *fileInfo = NULL;

  // check arguments
  if(items == 2 && SvOK(fileName = ST(0)) && SvROK(fileInfo = (HV*)ST(1)) &&
     SvTYPE(fileInfo = (HV*)SvRV(fileInfo)) == SVt_PVHV) {
    // clear reference
    hv_clear(fileInfo);

    // get version info
    GetVersionInfo(P_PERL fileName, fileInfo, &error);
    LastError(error);
  }
  else
    croak("Usage: Win32::Setupsup::GetVersionInfo($filename, \\%fileinfo)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// gets a list of all running processes ans threads
//
// param:  pPerl       - pointer to perl object
//                               processList - process list array
//                               threadList  - thread list array
//         lastError - pointer to an error var
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

BOOL GetProcessAndThreadList(PERL_CALL SV *server, AV *processList, AV *threadList,
                             PDWORD lastError)
{
  ErrorAndResult;

  PSTR serverName = server ? SvPV(server, PL_na) : NULL;
  HKEY hKeyLocalMachine = NULL, hKeyPerfData = NULL;
  HKEY hKey = NULL;
  PSTR counter = NULL;
  DWORD counterSize = 0;
  PPERF_DATA_BLOCK perfData = NULL;

  __try {
    if(!*serverName)
      serverName =  NULL;

    if(serverName) {
      if(error = RegConnectRegistry(serverName, HKEY_LOCAL_MACHINE, &hKeyLocalMachine))
        LeaveFalseError(error);
    }
    else
      hKeyLocalMachine = HKEY_LOCAL_MACHINE;

    // read the performance counter names
    if(error = RegOpenKeyEx(hKeyLocalMachine, "Software\\Microsoft\\Windows NT\\"
                            "CurrentVersion\\Perflib\\009", 0,
                            KEY_QUERY_VALUE, &hKey))
      LeaveFalseError(error);

    // get memory size needed
    if(error = RegQueryValueEx(hKey, "Counter", NULL, NULL, (LPBYTE)counter,
                               &counterSize))
      LeaveFalseError(error);

    // alloc memory
    if(!(counter = new char[counterSize]))
      LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

    // get counter data
    if(error = RegQueryValueEx(hKey, "Counter", NULL, NULL, (LPBYTE)counter,
                               &counterSize))
      LeaveFalseError(error);

    DWORD processId = 0, idProcessId = 0, threadId = 0, idThreadId = 0;

    // look for id's (Process and Thread)
    for(PSTR counterPtr = counter; TRUE; ) {
      PSTR counterIdPtr = counterPtr;

      if(!counterIdPtr || !*counterIdPtr ||
         !(counterPtr += strlen(counterPtr) + 1) || !*counterPtr)
        LeaveFalseError(PERF_COUNTER_NOT_FOUND_ERROR);

      if(!stricmp(counterPtr, "ID Process"))
        sscanf(counterIdPtr, "%d", &idProcessId);

      if(!stricmp(counterPtr, "Process"))
        sscanf(counterIdPtr, "%d", &processId);

      if(!stricmp(counterPtr, "ID Thread"))
        sscanf(counterIdPtr, "%d", &idThreadId);

      if(!stricmp(counterPtr, "Thread"))
        sscanf(counterIdPtr, "%d", &threadId);

      if(processId && idProcessId && threadId && idThreadId)
        break;
    }

    // read performance data from registry
    if(serverName) {
      if(error = RegConnectRegistry(serverName, HKEY_PERFORMANCE_DATA, &hKeyPerfData))
        LeaveFalseError(error);
    }
    else
      hKeyPerfData = HKEY_PERFORMANCE_DATA;

    DWORD count = 1;
    for(DWORD perfDataSize = PERF_DATA_SIZE; TRUE;
        perfDataSize = ++count * PERF_DATA_SIZE) {
      if(!(perfData = (PPERF_DATA_BLOCK) new char[perfDataSize]))
        LeaveFalseError(NOT_ENOUGTH_MEMORY_ERROR);

      if((error = RegQueryValueEx(hKeyPerfData, "", NULL, NULL,
                                  (LPBYTE)perfData, &perfDataSize)) == ERROR_MORE_DATA) {
        CleanPtr(perfData);
        continue;
      }

      if(!error && perfDataSize > 4 * sizeof(WCHAR) &&
         perfData->Signature[0] == L'P' && perfData->Signature[1] == L'E' &&
         perfData->Signature[2] == L'R' && perfData->Signature[3] == L'F')
        break;

      LeaveFalseError(PERF_COUNTER_NOT_FOUND_ERROR);
    }

    PPERF_OBJECT_TYPE perfObj =
      (PPERF_OBJECT_TYPE)((PSTR)perfData + perfData->HeaderLength),
      processPerfObj = NULL, threadPerfObj = NULL;

    // get performance objects for processes and threads
    count = 0;
    for(; count < perfData->NumObjectTypes; count++) {
      if(perfObj->ObjectNameTitleIndex == processId)
        processPerfObj = perfObj;

      if(perfObj->ObjectNameTitleIndex == threadId)
        threadPerfObj = perfObj;

      if(processPerfObj && threadPerfObj)
        break;

      perfObj = (PPERF_OBJECT_TYPE)((PSTR)perfObj + perfObj->TotalByteLength);
    } // for(count = 0; count < perfData->NumObjectTypes; count++)

    if(!processPerfObj || !threadPerfObj)
      LeaveFalseError(PERF_COUNTER_NOT_FOUND_ERROR);

    PPERF_COUNTER_DEFINITION processPerfDef =
      (PPERF_COUNTER_DEFINITION)((PSTR)processPerfObj + processPerfObj->HeaderLength);

    int processIdCounter = 0;

    // get process id offset
    count = 0;
    for(; count < processPerfObj->NumCounters; count++) {
      if(processPerfDef->CounterNameTitleIndex == idProcessId) {
        processIdCounter = processPerfDef->CounterOffset;
        break;
      }

      processPerfDef = (PPERF_COUNTER_DEFINITION)
        ((PSTR)processPerfDef + processPerfDef->ByteLength);
    }

    if(!processIdCounter)
      LeaveFalseError(PERF_COUNTER_NOT_FOUND_ERROR);

    PPERF_INSTANCE_DEFINITION processPerfInst = (PPERF_INSTANCE_DEFINITION)
      ((PSTR)processPerfObj + processPerfObj->DefinitionLength);

    // get process names and id's
    count = 0;
    for(; count < (DWORD)processPerfObj->NumInstances; count++) {
      PPERF_COUNTER_BLOCK perfCntBlk =
        (PPERF_COUNTER_BLOCK)((PSTR)processPerfInst + processPerfInst->ByteLength);

      DWORD processId = *((LPDWORD)((PSTR)perfCntBlk + processIdCounter));

      // craete new hash
      HV *processHash = newHV();

      // change process name fom unicode to ascii
      PSTR processName =
        W2S((PWSTR)((PSTR)processPerfInst + processPerfInst->NameOffset));

      // store process name
      hv_store(processHash, PROCESS_NAME_STR, strlen(PROCESS_NAME_STR),
               newSVpv(processName, strlen(processName)), 0);

      CleanPtr(processName);

      // store pid
      hv_store(processHash, PID_STR, strlen(PID_STR), newSViv(processId), 0);

      // store hash to the array
      av_push(processList, (SV*)newRV((SV*)processHash));

      processPerfInst = (PPERF_INSTANCE_DEFINITION)
        ((PSTR)perfCntBlk + perfCntBlk->ByteLength);
    }

    PPERF_COUNTER_DEFINITION threadPerfDef =
      (PPERF_COUNTER_DEFINITION)((PSTR)threadPerfObj + threadPerfObj->HeaderLength);

    int threadIdCounter = 0;

    // get thread id offset
    count = 0;
    for(; count < threadPerfObj->NumCounters; count++) {
      if(threadPerfDef->CounterNameTitleIndex == idThreadId) {
        threadIdCounter = threadPerfDef->CounterOffset;
        break;
      }

      threadPerfDef = (PPERF_COUNTER_DEFINITION)
        ((PSTR)threadPerfDef + threadPerfDef->ByteLength);
    }

    if(!threadIdCounter)
      LeaveFalseError(PERF_COUNTER_NOT_FOUND_ERROR);

    PPERF_INSTANCE_DEFINITION threadPerfInst = (PPERF_INSTANCE_DEFINITION)
      ((PSTR)threadPerfObj + threadPerfObj->DefinitionLength);

    // get thread names and id's
    count = 0;
    for(; count < (DWORD)threadPerfObj->NumInstances; count++) {
      PPERF_COUNTER_BLOCK perfCntBlk =
        (PPERF_COUNTER_BLOCK)((PSTR)threadPerfInst + threadPerfInst->ByteLength);

      DWORD threadId = *((LPDWORD)((PSTR)perfCntBlk + threadIdCounter));

      // craete new hash
      HV *threadHash = newHV();

      // store threads process index
      hv_store(threadHash, TID_STR, strlen(TID_STR), newSViv(threadId), 0);

      // store thread tid
      hv_store(threadHash, THREAD_PROCESS_STR, strlen(THREAD_PROCESS_STR),
               newSViv(threadPerfInst->ParentObjectInstance), 0);

      // store hash to the array
      av_push(threadList, (SV*)newRV((SV*)threadHash));

      threadPerfInst = (PPERF_INSTANCE_DEFINITION)
        ((PSTR)perfCntBlk + perfCntBlk->ByteLength);
    }
  }
  __finally {
    CleanKey(hKeyLocalMachine);
    CleanKey(hKeyPerfData);
    CleanKey(hKey);
    CleanPtr(counter);
    CleanPtr(perfData);

    SetErrorVar();
  }

  return result;
}


///////////////////////////////////////////////////////////////////////////////
//
// gets a list of all running processes ans threads
//
// param:  proc   - reference to the process list
//         thread - reference to the thread list
//
// return: success - true
//         failure - false
//
// note:   proc is an array of hash references; the hashs will contain two
//         keys - names (process name) and pid (process pid); thread is also
//         an array of references. it will contain the key names tid (thread
//         id) and process (index to the proc array; the thread belongs to
//         this processs)
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetProcessList)
{
  dXSARGS;

  ErrorAndResult;

  // reset last error
  LastError(0);

  // pointer for server, processes and threads
  SV *server = NULL;
  AV *processes = NULL;
  AV *threads = NULL;

  // check arguments
  if(items == 3 && SvPOK(server = ST(0)) && SvROK(processes = (AV*)ST(1)) &&
     SvTYPE(processes = (AV*)SvRV(processes)) == SVt_PVAV &&
     SvROK(threads = (AV*)ST(2)) && SvTYPE(threads = (AV*)SvRV(threads)) == SVt_PVAV) {
    // clear reference
    av_clear(processes);
    av_clear(threads);

    // get version info
    GetProcessAndThreadList(P_PERL server, processes, threads,  &error);
    LastError(error);
  }
  else
    croak("Usage: Win32::Setupsup::GetProcessList($server, \\@proc, \\@thread)\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// grants or revokes the debug privilege to the current process
//
// param:        grantPrivilege - grants the privilege if true or revokes it (false)
//                               lastError      - pointer to an error
//
// return: success - true
//         failure - false
//
// note:         you need the rigth to grant this privilege to your process; normally
//         you have to be a member of the administrators group
//
///////////////////////////////////////////////////////////////////////////////

BOOL SetDebugPrivilege(BOOL grantPrivilege, PDWORD lastError)
{
  ErrorAndResult;

  HANDLE hToken;
  LUID luid;
  TOKEN_PRIVILEGES privileges;

  __try {
    // retrieve a handle of the access token
    if(!OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY,
                         &hToken))
      LeaveFalse();

    // enable the SE_DEBUG_NAME privilege
    if(!LookupPrivilegeValue(NULL, SE_DEBUG_NAME,   &luid))
      LeaveFalse();

    privileges.PrivilegeCount = 1;
    privileges.Privileges[0].Luid = luid;
    privileges.Privileges[0].Attributes = grantPrivilege ? SE_PRIVILEGE_ENABLED : 0;

    // adjust the privilege
    if(!AdjustTokenPrivileges(hToken, 0, &privileges, sizeof(TOKEN_PRIVILEGES),
                              (PTOKEN_PRIVILEGES) NULL, NULL))
      LeaveFalse();
  }
  __finally {
    SetErrorVar();
  }

  return result;
}



///////////////////////////////////////////////////////////////////////////////
//
// kills a process
//
// param:  proc       - process id to kill
//         exitval    - optional exit value (default 0)
//         systemproc - if set you can kill system processes too
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_KillProcess)
{
  dXSARGS;

  ErrorAndResult;

  // reset last error
  LastError(0);

  // pointer for processes and threads
  SV *pid = NULL;
  SV *exitValue = NULL;
  SV *systemProcess = NULL;

  // check arguments
  if((items >= 1 && items <= 3) && SvIOK(pid = ST(0)) &&
     (items < 2 || SvIOK(exitValue = ST(1))) &&
     (items < 3 || SvIOK(systemProcess = ST(2)))) {
    UINT exitCode = exitValue ? SvIV(exitValue) : 0;
    BOOL killSystemProcess =
      systemProcess && SvIV(systemProcess) ? TRUE : FALSE;

    // if you want to kill system processes, you have to grant debug privilege
    if(killSystemProcess) {
      SetDebugPrivilege(TRUE, &error);
      LastError(error);
    }

    if(!LastError()) {
      // we need the process handle
      HANDLE hProcess = OpenProcess(PROCESS_TERMINATE, TRUE, SvIV(pid));

      // kill process now
      if(!TerminateProcess(hProcess, exitCode)) {
        LastError(GetLastError());
        printf("Error: %d\n", LastError());
      }

      // revoke debug privilege if needed
      if(killSystemProcess) {
        SetDebugPrivilege(FALSE, &error);
        LastError(error);
      }
    }
  }
  else
    croak("Usage: Win32::Setupsup::KillProcess($proc, [$exitval, [$systemproc]])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// sleeps a while
//
// param:  time - time to sleep in ms (default: infinite)
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_Sleep)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // pointer for processes and threads
  SV *time = NULL;

  // check arguments
  if((items == 0 || items == 1) && (items == 0 || SvOK(time = ST(0)))) {
    //DWORD waitTime = time ? SvIV(time) : INFINITE;

    // we need the process handle ???
    Sleep(time ? SvIV(time) : INFINITE);
  }
  else
    croak("Usage: Win32::Setupsup::Sleep([$time])\n");

  XSRETURN(1);
}


DWORD WINAPI CaptureMouseThreadFunc(PVOID param)
{
  while(TRUE) {
    mouse_event(MOUSEEVENTF_ABSOLUTE | MOUSEEVENTF_MOVE, 0, 0, 0, 0);
    Sleep(MouseCaptureRefresh);
  }

  return 1;
}

///////////////////////////////////////////////////////////////////////////////
//
//
//
// param:  window           - window handle
//         windowproperties - window properties to set
//
// return: success - true
//         failure - false
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_CaptureMouse)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *refresh = NULL;

  // check arguments
  if(items == 0 || (items == 1 && SvIOK(refresh = ST(0)))) {
    if(refresh && MouseCaptureThread)
      MouseCaptureRefresh = SvIV(refresh);

    if(!MouseCaptureThread) {
      DWORD threadId = 0;

      MouseCaptureRefresh = refresh ? SvIV(refresh) : DEFAULT_MOUSE_CAPTURE_REFRESH;

      MouseCaptureThread =
        CreateThread(NULL, 0, CaptureMouseThreadFunc, NULL, 0, &threadId);
    }
  }
  else
    croak("Usage: Win32::Setupsup::CaptureMouse([$refresh])\n");

  RETURNRESULT(!LastError());
}


XS(XS_NT__Setupsup_UnCaptureMouse)
{
  dXSARGS;

  // reset last error
  LastError(0);

  // window parameter
  SV *refresh = NULL;

  // check arguments
  if(items == 0) {
    if(MouseCaptureThread) {
      TerminateThread(MouseCaptureThread, 0);
      MouseCaptureThread = NULL;
      MouseCaptureRefresh = 0;
    }
  }
  else
    croak("Usage: Win32::Setupsup::UnCaptureMouse()\n");

  RETURNRESULT(!LastError());
}


XS(XS_NT__Setupsup_Beep)
{
  dXSARGS;

  // reset last error
  LastError(0);

  DWORD freq = 1000, duration = 1000;

  // check arguments
  if(items <= 2) {
    freq = items > 0 ? SvIV(ST(0)) : 1000;
    duration = items > 1 ? SvIV(ST(1)) : 1000;

    Beep(freq, duration);
  }
  else
    croak("Usage: Win32::Setupsup::Beep([$freq [, $refresh]])\n");

  RETURNRESULT(!LastError());
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the last error code
//
// param:  nothing
//
// return: last error code
//
// note:   you can call this function to get an specific error code from the
//         last failure; if a function from this module returns 0, you should
//         call GetLastError() to get the error code; the error code will be
//         reset to null on each function entry
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetLastError)
{
  dXSARGS;

  ST(0) = sv_newmortal();
  sv_setiv(ST(0), LastError());

  XSRETURN(1);
}


///////////////////////////////////////////////////////////////////////////////
//
// gets the last error code
//
// param:  nothing
//
// return: last error code
//
// note:   you can call this function to get an specific error code from the
//         last failure; if a function from this module returns 0, you should
//         call GetLastError() to get the error code; the error code will be
//         reset to null on each function entry
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_GetThreadLastError)
{
  dXSARGS;

  SV *thread = NULL;
  SV *error = NULL;

  if(items == 1 && SvIOK(thread = ST(0))) {
    HANDLE hThread = thread ? (HANDLE)SvIV(thread) : 0;
    DWORD threadError = INVALID_THREAD_HANDLE_ERROR;

    PUSHMARK(sp);

    for(PNode node = AsynchThreadList.HeadPos(); node;
        node = AsynchThreadList.NextPos(node)) {
      // get pointer to thread info struct
      PPerlThreadInfoStruct perlThreadInfo =
        (PPerlThreadInfoStruct) AsynchThreadList.This(node);

      if(hThread == perlThreadInfo->hThread) {
        threadError = perlThreadInfo->lastError;
        break;
      }
    }

    XPUSHs(newSViv(threadError));

    PUTBACK;
  }
  else
    croak("Usage: Win32::Setupsup::GetThreadLastError($thread)\n");

  XSRETURN(1);
}


///////////////////////////////////////////////////////////////////////////////
//
// sets the last error code
//
// param:  error code to set
//
// return: always true
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_SetLastError)
{
  dXSARGS;

  LastError(SvIV(ST(0)));

  XSRETURN(1);
}


///////////////////////////////////////////////////////////////////////////////
//
// constant function for exported definitions (section @EXPORT in *.pm)
//
// param:  name - constant name
//
// return: success - constant name as integer
//         failure - 0
//
///////////////////////////////////////////////////////////////////////////////

static long constant(PERL_CALL PSTR name)
{
  // do a switch on the first char for speed ...
  switch(*name) {
   case 'E':
    RET_VAL_IF_EQUAL(ERROR_TIMEOUT_ELAPSED, name);
    break;

   case 'I':
    RET_VAL_IF_EQUAL(INVALID_SID_ERROR, name);
    RET_VAL_IF_EQUAL(INVALID_PROPERTY_TYPE_ERROR, name);
    break;

   case 'N':
    RET_VAL_IF_EQUAL(NOT_ENOUGTH_MEMORY_ERROR, name);
    break;

   case 'U':
    RET_VAL_IF_EQUAL(UNKNOWN_PROPERTY_ERROR, name);
    break;

   case 'V':
    switch(*(name + 1)) {
     case 'F':
      RET_VAL_IF_EQUAL(VFF_BUFFTOOSMALL, name);
      RET_VAL_IF_EQUAL(VFF_CURNEDEST, name);
      RET_VAL_IF_EQUAL(VFF_FILEINUSE, name);
      RET_VAL_IF_EQUAL(VFFF_ISSHAREDFILE, name);
      RET_VAL_IF_EQUAL(VFT_UNKNOWN, name);
      RET_VAL_IF_EQUAL(VFT_APP, name);
      RET_VAL_IF_EQUAL(VFT_DLL, name);
      RET_VAL_IF_EQUAL(VFT_DRV, name);
      RET_VAL_IF_EQUAL(VFT_FONT, name);
      RET_VAL_IF_EQUAL(VFT_VXD, name);
      RET_VAL_IF_EQUAL(VFT_STATIC_LIB, name);
      RET_VAL_IF_EQUAL(VFT2_UNKNOWN, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_PRINTER, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_KEYBOARD, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_LANGUAGE, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_DISPLAY, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_MOUSE, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_NETWORK, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_SYSTEM, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_INSTALLABLE, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_SOUND, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_COMM, name);
      RET_VAL_IF_EQUAL(VFT2_DRV_INPUTMETHOD, name);
      RET_VAL_IF_EQUAL(VFT2_FONT_RASTER, name);
      RET_VAL_IF_EQUAL(VFT2_FONT_VECTOR, name);
      RET_VAL_IF_EQUAL(VFT2_FONT_TRUETYPE, name);
      break;

     case 'I':
      RET_VAL_IF_EQUAL(VIF_DIFFCODEPG, name);
      RET_VAL_IF_EQUAL(VIF_DIFFLANG, name);
      RET_VAL_IF_EQUAL(VIF_DIFFTYPE, name);
      RET_VAL_IF_EQUAL(VIF_MISMATCH, name);
      RET_VAL_IF_EQUAL(VIF_SRCOLD, name);
      RET_VAL_IF_EQUAL(VIF_TEMPFILE, name);
      RET_VAL_IF_EQUAL(VIF_ACCESSVIOLATION, name);
      RET_VAL_IF_EQUAL(VIF_CANNOTCREATE, name);
      RET_VAL_IF_EQUAL(VIF_CANNOTDELETE, name);
      RET_VAL_IF_EQUAL(VIF_CANNOTRENAME, name);
      RET_VAL_IF_EQUAL(VIF_CANNOTDELETECUR, name);
      RET_VAL_IF_EQUAL(VIF_FILEINUSE, name);
      RET_VAL_IF_EQUAL(VIF_OUTOFMEMORY, name);
      RET_VAL_IF_EQUAL(VIF_OUTOFSPACE, name);
      RET_VAL_IF_EQUAL(VIF_SHARINGVIOLATION, name);
      RET_VAL_IF_EQUAL(VIF_WRITEPROT, name);
      RET_VAL_IF_EQUAL(VIF_CANNOTREADSRC, name);
      RET_VAL_IF_EQUAL(VIF_CANNOTREADDST, name);
      RET_VAL_IF_EQUAL(VIF_BUFFTOOSMALL, name);
      RET_VAL_IF_EQUAL(VIFF_FORCEINSTALL, name);
      RET_VAL_IF_EQUAL(VIFF_DONTDELETEOLD, name);
      break;

     case 'O':
      RET_VAL_IF_EQUAL(VOS_UNKNOWN, name);
      RET_VAL_IF_EQUAL(VOS_DOS, name);
      RET_VAL_IF_EQUAL(VOS_OS216, name);
      RET_VAL_IF_EQUAL(VOS_OS232, name);
      RET_VAL_IF_EQUAL(VOS_NT, name);
      RET_VAL_IF_EQUAL(VOS__BASE, name);
      RET_VAL_IF_EQUAL(VOS__WINDOWS16, name);
      RET_VAL_IF_EQUAL(VOS__PM16, name);
      RET_VAL_IF_EQUAL(VOS__PM32, name);
      RET_VAL_IF_EQUAL(VOS__WINDOWS32, name);
      RET_VAL_IF_EQUAL(VOS_DOS_WINDOWS16, name);
      RET_VAL_IF_EQUAL(VOS_DOS_WINDOWS32, name);
      RET_VAL_IF_EQUAL(VOS_OS216_PM16, name);
      RET_VAL_IF_EQUAL(VOS_OS232_PM32, name);
      RET_VAL_IF_EQUAL(VOS_NT_WINDOWS32, name);
      break;

     case 'S':
      RET_VAL_IF_EQUAL(VS_FF_DEBUG, name);
      RET_VAL_IF_EQUAL(VS_FF_PRERELEASE, name);
      RET_VAL_IF_EQUAL(VS_FF_PATCHED, name);
      RET_VAL_IF_EQUAL(VS_FF_PRIVATEBUILD, name);
      RET_VAL_IF_EQUAL(VS_FF_INFOINFERRED, name);
      RET_VAL_IF_EQUAL(VS_FF_SPECIALBUILD, name);
      break;
    } // switch(*(name + 1))

    break; // case 'V':

   default:
    break;
  }

  // name not found
  return 0;
}


///////////////////////////////////////////////////////////////////////////////
//
// maps an string value to an integer; will be called automatically, if you
// access a value form section @EXPORT in *.pm
//
// param:  name - constant name
//         arg  - argument
//
// return: success - constant name as integer
//         failure - 0
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_constant)
{
  dXSARGS;

  // reset last error
  LastError(0);

  if(items == 2) {
    PSTR name = (PSTR)SvPV(ST(0), PL_na);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), constant(P_PERL name));
  }
  else
    croak("Usage: Win32::Setupsup::constant(name, arg)\n");

  XSRETURN(1);
}





///////////////////////////////////////////////////////////////////////////////
//
//      here are some test functions; don't call it !!!
//
///////////////////////////////////////////////////////////////////////////////


/*
  BOOL __stdcall ConsoleHandler(DWORD crtlType) {
  switch(crtlType) {
  case CTRL_C_EVENT:
  Beep(100, 100);
  return TRUE;

  case CTRL_BREAK_EVENT:
  Beep(300, 300);
  return TRUE;

  case CTRL_CLOSE_EVENT:
  Beep(1000, 1000);
  Sleep(10000);
  return TRUE;
  }

  return FALSE;
  }
*/

///////////////////////////////////////////////////////////////////////////////
//
// test function
//
///////////////////////////////////////////////////////////////////////////////
/*
  XS(XS_NT__Setupsup_Test1) {
  dXSARGS;

  PUSHMARK(sp);

  SetConsoleCtrlHandler(ConsoleHandler, TRUE);

  PUTBACK;
  }


///////////////////////////////////////////////////////////////////////////////
//
// test function
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_Test2)
{
dXSARGS;

PUSHMARK(sp);

printf("Test function2 called\n");

SetConsoleCtrlHandler(ConsoleHandler, FALSE);

PUTBACK;
}
*/

///////////////////////////////////////////////////////////////////////////////
//
// test function
//
///////////////////////////////////////////////////////////////////////////////

  XS(XS_NT__Setupsup_Test3)
{
  dXSARGS;

  PUSHMARK(sp);

  printf("Test function3 called\n");
/*
  char Caption[128] = "";

  GetConsoleTitle(Caption, 128);
  HWND hWnd = FindWindow(NULL, Caption);

  DWORD style = GetWindowLong(hWnd, GWL_STYLE);
  printf("Style: %x\n", style);
  style &= ~WS_DLGFRAME;
  HWND hDesktop = GetDesktopWindow();
  printf("Desktop: %x\n", hDesktop);
  SetWindowLong(hWnd, GWL_STYLE, style);
  printf("Style: %x\n", GetWindowLong(hWnd, GWL_STYLE));
  InvalidateRect(hDesktop, NULL, TRUE);
  UpdateWindow(hDesktop);
//      ShowWindow(hWnd, SW_NORMAL);

HMENU hMenu = GetSystemMenu(hWnd, FALSE);
EnableMenuItem(hMenu, SC_CLOSE, MF_GRAYED | MF_DISABLED);
//      for(int i = 0; i< 9; i++)
//      EnableMenuItem(hMenu, i, MF_BYPOSITION | MF_GRAYED | MF_DISABLED);

//WS_SYSMENU
printf("HWND: %x\n", hWnd);
*/
  PUTBACK;
}


///////////////////////////////////////////////////////////////////////////////
//
// test function
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_Test4)
{
  dXSARGS;

  LastError(0);


  RETURNRESULT(!LastError());
}



long WINAPI AllocDesktopThreadWndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
  switch(msg) {
   case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
  }

  return DefWindowProc(hWnd, msg, wParam, lParam);
}


BOOL AllocDesktopThreadFunc(PVOID param)
{
  MSG msg;
  WNDCLASS wndClass;

  memset(&wndClass, 0, sizeof(wndClass));

  wndClass.style = CS_HREDRAW | CS_VREDRAW;
  wndClass.lpfnWndProc = AllocDesktopThreadWndProc;
  wndClass.lpszClassName = "setupsup";
  wndClass.hbrBackground = (HBRUSH)GetStockObject(GRAY_BRUSH);

  if(!RegisterClass(&wndClass)) {
    printf("RegisterClass failed\n");
    return 0;
  }


  HWND hWnd =
    CreateWindowEx(/*WS_EX_TRANSPARENT*/0, "setupsup", "testfenster", WS_POPUP | WS_BORDER | WS_SIZEBOX,
                   0, 0, 2048, 2048,
                   NULL, NULL, 0, NULL);

  if(!hWnd) {
    printf("CreateWindow failed\n");
    return 0;
  }

  ShowWindow(hWnd, SW_SHOW);
  UpdateWindow(hWnd);

  while(GetMessage(&msg, NULL, 0, 0)) {
    if(msg.message == WM_KEYUP) {
      int state = GetKeyState(msg.wParam);
      printf("char: %c (%x); State: %d\n", msg.wParam, msg.wParam, state);
    }


    if(msg.message == WM_CHAR)
      printf("char: %c (%x)\n", msg.wParam, msg.wParam);

    TranslateMessage(&msg);



    DispatchMessage(&msg);
  }

  return TRUE;
}

///////////////////////////////////////////////////////////////////////////////
//
// test function
//
///////////////////////////////////////////////////////////////////////////////

XS(XS_NT__Setupsup_Test)
{
  dXSARGS;

  PUSHMARK(sp);

  printf("Test function called\n");


  AllocDesktopThreadFunc(NULL);

  PUTBACK;
}



///////////////////////////////////////////////////////////////////////////////
//
// only really exported function; handles calls to XS-funtions in the module
//
// param:  nothing
//
// return: 1
//
///////////////////////////////////////////////////////////////////////////////

XS(boot_Win32__Setupsup)
{
  dXSARGS;

  char *file = __FILE__;

  newXS("Win32::Setupsup::SendKeys",
        XS_NT__Setupsup_SendKeys, file);
  newXS("Win32::Setupsup::EnumWindows",
        XS_NT__Setupsup_EnumWindows, file);
  newXS("Win32::Setupsup::EnumChildWindows",
        XS_NT__Setupsup_EnumChildWindows, file);
  newXS("Win32::Setupsup::WaitForWindow",
        XS_NT__Setupsup_WaitForWindow, file);
  newXS("Win32::Setupsup::WaitForAnyWindow",
        XS_NT__Setupsup_WaitForAnyWindow, file);
  newXS("Win32::Setupsup::WaitForAnyWindowAsynch",
        XS_NT__Setupsup_WaitForAnyWindowAsynch, file);
  newXS("Win32::Setupsup::WaitForWindowClose",
        XS_NT__Setupsup_WaitForWindowClose, file);
  newXS("Win32::Setupsup::GetWindowText",
        XS_NT__Setupsup_GetWindowText, file);
  newXS("Win32::Setupsup::SetWindowText",
        XS_NT__Setupsup_SetWindowText, file);
  newXS("Win32::Setupsup::GetDlgItem",
        XS_NT__Setupsup_GetDlgItem, file);
  newXS("Win32::Setupsup::SetFocus",
        XS_NT__Setupsup_SetFocus, file);
  newXS("Win32::Setupsup::GetWindowProperties",
        XS_NT__Setupsup_GetWindowProperties, file);
  newXS("Win32::Setupsup::SetWindowProperties",
        XS_NT__Setupsup_SetWindowProperties, file);
  newXS("Win32::Setupsup::CaptureMouse",
        XS_NT__Setupsup_CaptureMouse, file);
  newXS("Win32::Setupsup::UnCaptureMouse",
        XS_NT__Setupsup_UnCaptureMouse, file);
  newXS("Win32::Setupsup::AccountToSid",
        XS_NT__Setupsup_AccountToSid, file);
  newXS("Win32::Setupsup::SidToAccount",
        XS_NT__Setupsup_SidToAccount, file);
  newXS("Win32::Setupsup::GetVersionInfo",
        XS_NT__Setupsup_GetVersionInfo, file);
  newXS("Win32::Setupsup::GetProcessList",
        XS_NT__Setupsup_GetProcessList, file);
  newXS("Win32::Setupsup::KillProcess",
        XS_NT__Setupsup_KillProcess, file);
  newXS("Win32::Setupsup::Sleep",
        XS_NT__Setupsup_Sleep, file);
  newXS("Win32::Setupsup::Beep",
        XS_NT__Setupsup_Beep, file);

  newXS("Win32::Setupsup::GetLastError", XS_NT__Setupsup_GetLastError, file);
  newXS("Win32::Setupsup::SetLastError", XS_NT__Setupsup_SetLastError, file);
  newXS("Win32::Setupsup::GetThreadLastError", XS_NT__Setupsup_GetThreadLastError, file);
  newXS("Win32::Setupsup::constant", XS_NT__Setupsup_constant, file);

  //newXS("Win32::Setupsup::Test", XS_NT__Setupsup_Test, file);
  //newXS("Win32::Setupsup::Test4", XS_NT__Setupsup_Test4, file);

  ST(0) = &PL_sv_yes;

  XSRETURN(1);
}


///////////////////////////////////////////////////////////////////////////////
//
// dll entry point
//
// param:  hInstance - instance handle
//         reason    - reason why function was called
//         reserved  - reserved value
//
// return: TRUE (must be true, otherwise loading dll would fail)
//
///////////////////////////////////////////////////////////////////////////////

extern "C"
BOOL WINAPI DllMain(HINSTANCE hInstance, DWORD reason, LPVOID reserved)
{
  BOOL result = TRUE;

  switch(reason) {
   case DLL_PROCESS_ATTACH:
    if((TlsIndex = TlsAlloc()) == -1)
      return 0;
    break;

   case DLL_THREAD_ATTACH:
    break;

   case DLL_THREAD_DETACH:
    break;

   case DLL_PROCESS_DETACH:
    // close all threads in AsynchThreadList

    for(PNode node = AsynchThreadList.HeadPos(); node;
        node = AsynchThreadList.NextPos(node)) {
      // get pointer to thread info struct
      PPerlThreadInfoStruct perlThreadInfo =
        (PPerlThreadInfoStruct) AsynchThreadList.This(node);

      TerminateThread(perlThreadInfo->hThread, 0);
    }

    // free list memory
    AsynchThreadList.RemoveAll();
    TlsFree(TlsIndex);
    break;
  }

  return result;
}
