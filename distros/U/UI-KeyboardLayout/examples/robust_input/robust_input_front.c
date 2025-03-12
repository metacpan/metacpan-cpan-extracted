// Compile as this:		gcc -Wall dumper-msg-show.c -lcomctl32  -lgdi32

#include <wchar.h>
#include <windows.h>
#include <string.h>
#include <stdio.h>
// #include <kbd.h>			// not in cygwin
#ifndef KBDBREAK			// from <kbd.h>; not in cygwin
#  define KBDEXT        (USHORT)0x0100
#  define KBDBREAK      (USHORT)0x8000
#  define FAKE_KEYSTROKE 0x02000000
#endif

#define hKF_ALTDOWN	(KF_ALTDOWN<<16)

#define ARRAY_LENGTH(x) (sizeof(x) / sizeof((x)[0]))

#define ID_EDIT_TOP	1
#define ID_EDIT_BOTTOM	2
#define ID_ACCEL_FAKE	0xeD94		// Random number; should not matter due to subclassing
#define LCTRL_DEBUG	1
#define CTRLs_DEBUG	0

// lCtrl_first is like lCtrl_dn_unknown, but with a correct timestamp stored
enum {lCtrl_unknown = -1, lCtrl_up = 0, lCtrl_dn_unknown, lCtrl_first, lCtrl_maybefake, lCtrl_real, lCtrl_noKLLFA_any};
	// First three down-states should be in this order, continuously:
enum {KEY_unknown = -1, KEY_up = 0, KEY_down = 1, KEY_down_aftertap, KEY_aftertap, KEY_intrr};	// KEY_down_aftertap etc. for tapAlt
enum {err_cSys1, err_cSys0, err_aSys, err_FA_lC, err_FA_rC, err_FA_rA, err_FA_rA0, err_accel, err_accel2};
enum {f_forceSpecKeys, f_noInferMods, f_forceKeyState, f_noSmartSkip, f_noLCtrlKLLFA,
	pTMf_ignore_lCtrl, pTMf_skip_altNum, pTMf_skip_altNumHex, pTMf_pass_keyup, pTMf_pass_std_mods, pTMf_pass_found_mods,
        pTMf_ignore_CtrlAlt, pTMf_only_lCtrllAlt, pTMf_deliverCtrlCh, pTMf_eatCtrlCh};	// , pTMf_pass_ctrlCh_UNINMPLEMENTED


unsigned int f_Flags = 0;	// the meaning of the bits as in the preceding enum

	// All globals are declared here
struct KbdState {DWORD prMsgTime; signed char is_KLLFA; signed char lCtrl; signed char rCtrl; signed char rAlt; signed char tapAlt;}
  kbdState = {0, -1};					// Make global temporarily 
#define KbdState_needs_reset(p)	((p)->prMsgTime = 0)	// prMsgTime == 0 is overloaded to mean “needs resetting”
struct Alt_NUMPAD_State {unsigned int input; signed char aNpState; BYTE active_modk_c; BYTE is_oem; BYTE factor; signed char last_digit; BYTE active_modks[8];}
  *p_aNpState;
unsigned long ModK_errors = 0;		// valued in err_* enums
HFONT hFont;		// Global variable to store the font handle
WNDPROC OldEditProc;	// Global variable
int ignore_accel = 0;		// Negative if our fake-accelerator code failed
struct {WNDPROC oWndProc; int cOK; int cAll; int cmd; int cmdR;} ck_KLLFA;

enum {
    npST_ERROR = -19,		// These would be reset to NONE soon
    npST_ERROR_PERIOD,	// For these two the caller may want to replay what was skipped before (Alt-Down NUMPADkey-down)
    npST_ERROR_PLUS,	// Likewise
    npST_NONE,
    npST_SUCCESS = -1,
    npST_ALT_DOWN = 0,
    npST_IN_DIGIT,
    npST_AFTER_DIGIT,
    npST_STARTED_WITH_PERIOD,
    npST_STARTED_WITH_PLUS,
    npST_STARTED_WITH_PERIOD_UP,
    npST_STARTED_WITH_PLUS_UP
};

  // Heuristically, KEY_unknown in the overwhelming proportion of cases means “up” (and always means “at most 1 down”)
int Alt_state(WPARAM wParam, LPARAM lParam, BOOL before)	// Are we interested in the state before the key-event,  or after?
{	// Works only for (SYS)KEYDOWN/UP (and (SYS|UNI)(DEAD)CHAR messages not delivering VK_MENU == 0x12 == ^R)
    if (before && VK_MENU == LOWORD(wParam)) {
        if ((lParam >> 16) & KF_UP)
            return KEY_down;
        else
            return ((lParam >> 16) & KF_REPEAT) ? KEY_down : KEY_unknown;	// “Before”: Depend on whether another Alt was down
    }
    return (lParam & hKF_ALTDOWN) ? KEY_down : KEY_up;	// No trickery: state after the keyevent
}

#define Ctrl_state(messg, wParam, lParam, before, force) Ctrl_state_withAlt(messg, wParam, lParam, before, Alt_state(wParam, lParam, !"before" /*the simple case*/), force)

int Ctrl_state_withAlt(int messg, WPARAM wParam, LPARAM lParam, BOOL before, int Alt_State_after, int force) // Get as much info as possible without calling into the kernel
{	// Works only for (SYS)KEYDOWN/UP messages (and (SYS|UNI)(DEAD)CHARs not on F10, Esc, Alt)
    switch (LOWORD(wParam)) {
      case VK_CONTROL:
        if (before)
            return ((lParam >> 16) & KF_REPEAT) ? KEY_down : KEY_up;	// Misnomer: actially means “KF_wasDown”
        else if (!((lParam >> 16) & KF_UP))
            return KEY_down;
        break;				// State after Control-up (depends on the other Ctrl key)
  // Skip the cases when one cannot rely on SYS depending on Ctrl
      case VK_MENU:	// On keyup of Menu-tap (but not if other key events intervene!), SYS is cheated
        if (!((lParam >> 16) & KF_UP))		// Treat key down normally
            break;
        else
            return KEY_unknown;			//   Also: SYS inverted when Ctrl-down (w.r.t. the other VK⸣s)???
      case VK_F10:  case VK_ESCAPE:		// kernel cheats SYS
      case VK_JUNJA:				// kernel cheats no-SYS
        if (!force)			// Allow debugging of these special-cases
            return KEY_unknown;
    }
    if (KEY_down == Alt_State_after) {	// Now when all quirks are worked around, the rest is easy
        switch (messg) {		// In the presence of Ctrl the key events are not marked as SYS even if Alt is down
          case WM_SYSKEYDOWN:   case WM_SYSKEYUP:
            return KEY_up;
          case WM_KEYDOWN:    case WM_KEYUP:
            return KEY_down;
        }			// Fall through
    }
    return KEY_unknown;
}

// Should be called on keyup/down event after the “stale state” flag is set — but only if needed: when KLLF_A is not 0
// Tries to deduce the state before the event, optimizing on the number of system calls
void reset_KBD_state(struct KbdState *stp, struct Alt_NUMPAD_State *astp, int msg, WPARAM wParam, LPARAM lParam,
		     BOOL noInfer, BOOL forceSpecKeys, BOOL noKeyState, BOOL noSmartSkip) {
    int altDn = KEY_unknown, ctrlDn = KEY_unknown, wasDown = ((lParam >> 16) & KF_REPEAT) ? KEY_down : KEY_up;	// Misnomer: actially means “KF_wasDOwn”

    if (stp->lCtrl != lCtrl_noKLLFA_any || LCTRL_DEBUG) {	// Sticky state, until reset; LCTRL_DEBUG: try to detect more failure modes (why 
        stp->lCtrl = lCtrl_unknown;
        stp->tapAlt = stp->rAlt = stp->rCtrl = KEY_unknown;
    } // else if (LCTRL_DEBUG)			// 
      //  stp->tapAlt = stp->rAlt = stp->rCtrl = KEY_unknown;
    astp->aNpState = npST_ERROR;
    switch (LOWORD(wParam)) {
      case VK_LCONTROL:    stp->lCtrl = (wasDown == KEY_down) ? lCtrl_dn_unknown : lCtrl_up;     break;
      case VK_RCONTROL:    stp->rCtrl = wasDown;        break;
      case VK_RMENU:       stp->rAlt  = wasDown;        break;                          
    }
    if (!noInfer) {						// Optimize: try to avoid calls into the kernel
        if (KEY_up == (altDn = Alt_state(wParam, lParam, !!"before"))) {	// “unknown” actually means: ≤1 down before this event
            stp->rAlt = KEY_up;
	    astp->aNpState = npST_NONE;
        }
        if (KEY_up == (ctrlDn = Ctrl_state(msg, wParam, lParam, !!"before", forceSpecKeys))) {	// Can’t use altDn: it is “before”
	    stp->rCtrl = KEY_up;
	    stp->lCtrl = lCtrl_up;
        }
    }
    if (!noKeyState) {	// We also check: is the state going to be overwritten anyway
        if (KEY_unknown == stp->rCtrl && (noSmartSkip || LOWORD(wParam) != VK_RCONTROL))
	    stp->rCtrl = (GetKeyState(VK_RCONTROL) & 0x8000) ? KEY_down  : KEY_up; // This fills the state AFTER the message, while we need BEFORE!  We redo (if needed below)
        if (KEY_unknown == stp->rAlt  && (noSmartSkip || LOWORD(wParam) != VK_RMENU))
	    stp->rAlt  = (GetKeyState(VK_RMENU)    & 0x8000) ? KEY_down  : KEY_up;
        if (stp->lCtrl != lCtrl_noKLLFA_any && (noSmartSkip || LOWORD(wParam) != VK_LCONTROL)) // Impossible if called as documented; the check may be omitted without is_KLLFA
            stp->lCtrl = (GetKeyState(VK_LCONTROL) & 0x8000) ? lCtrl_dn_unknown : lCtrl_up;
    }
}

// Subclass for KLLF_ALTGR detection
LRESULT CALLBACK KLLF_ALTGR_Proc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    ck_KLLFA.cAll++;
    ck_KLLFA.cmdR = LOWORD(wParam);
    if (WM_COMMAND == msg && LOWORD(wParam) == ck_KLLFA.cmd) {
        ck_KLLFA.cOK++;
        return 0;			// “It was processed.”
    }
    return CallWindowProc(ck_KLLFA.oWndProc, hwnd, msg, wParam, lParam);	// Should not be entered
}

	// Order is important
enum {update_lCtrl_normal, update_lCtrl_Flag0, update_lCtrl_Flag1, update_lCtrl_FlagRetry,
      update_lCtrl_errCreate, update_lCtrl_errDestruct,  update_lCtrl_messy_F0, update_lCtrl_messy_F1 };

// returns update_lCtrl_errCreate, update_lCtrl_errDestruct, on failure, update_lCtrl_FlagRetry on not-now-and-OK-to-retry;
//         update_lCtrl_Flag0 or 1: is KLLF_ALTGR found, update_lCtrl_messy_F0: KLLF_ALTGR=0, but unexpected messages nevertheless
int Check_KLLF_ALTGR(MSG *msg, BYTE vk, WORD acc) {   // msg should be directed to a window in question.  Assumes that lCtrl and rAlt are down
    // See https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#A-convenient-assignment-of-KBD*-bitmaps-to-modifier-keys
    if (!msg->hwnd || (GetKeyState(VK_RCONTROL) & 0x8000 && GetKeyState(VK_LMENU) & 0x8000))
        return update_lCtrl_FlagRetry;	// With all 4 modifiers the accelerator is triggered even with KLLF_ALTGR ⇒ testing is useless

    int have_Shift = ((GetKeyState(VK_SHIFT) & 0x8000) ? FSHIFT : 0);
    union {ACCEL acc; double d;} accel;	// force alignment (vs. error 998)
    HACCEL hAccel;

    accel.acc = (ACCEL){ have_Shift | FCONTROL | FALT | FVIRTKEY, vk, acc };
    if (!(hAccel = CreateAcceleratorTableW(&(accel.acc), 1)))
        return update_lCtrl_errCreate;		// Serious failure; do not retry

    WNDPROC oProc = (WNDPROC)SetWindowLongPtrW(msg->hwnd, GWLP_WNDPROC, (LONG_PTR)KLLF_ALTGR_Proc);	// Intercept the message
    ck_KLLFA.oWndProc = oProc;
    ck_KLLFA.cAll = ck_KLLFA.cOK = 0;
    ck_KLLFA.cmd = ck_KLLFA.cmdR = acc;

    MSG fakeMsg = *msg;
    fakeMsg.wParam = vk;	// With KLLF_ALTGR, a message with AltGr is considered a C-A-accelerator only if all 4 are down
    fakeMsg.message = WM_SYSKEYDOWN;	// Without, it is a C-A-accelerator if any-of-C and any-of-A are down

    int rc = TranslateAccelerator(msg->hwnd, hAccel, &fakeMsg);		// Hence this fails with KLLF_ALTGR, and succeeds without

    SetWindowLongPtrW(msg->hwnd, GWLP_WNDPROC, (LONG_PTR)oProc);		// Restore the status quo
    if (!DestroyAcceleratorTable(hAccel))
        return update_lCtrl_errDestruct;	// Serious failure; do not retry

    if (!rc)
        return (ck_KLLFA.cAll || ck_KLLFA.cOK || ck_KLLFA.cmd != ck_KLLFA.cmdR) ? update_lCtrl_messy_F1 : update_lCtrl_Flag1;
    if (ck_KLLFA.cOK != ck_KLLFA.cAll || ck_KLLFA.cOK > 1 || ck_KLLFA.cmd != ck_KLLFA.cmdR)
        return update_lCtrl_messy_F0;		// Should not happen: this handler has been called, but…
    return update_lCtrl_Flag0;
}

int update_KBD_state(struct KbdState *stp, struct Alt_NUMPAD_State *astp, MSG *msg, unsigned int f) {
    int Rc = update_lCtrl_normal;

    // keyrepeat of AltGr leads to pairs  lCtrl + rAlt with the same timestamp; try to find lCtrl which do not look like this
    if (LCTRL_DEBUG || stp->is_KLLFA) {		// KLLF_ALTGR set, or unknown  The kernel removed the FAKE_KEYSTROKE flag; try to restore
        int vk, vk_orig, vk1, vk2;	// vk, vk_orig are defined only for up/down events

        if (!stp->prMsgTime)
            reset_KBD_state(stp, astp, msg->message, msg->wParam, msg->lParam, f & (1<<f_noInferMods), 
                            f & (1<<f_forceSpecKeys), f & (1<<f_forceKeyState), f & (1<<f_noSmartSkip));

        /* The kernel translated the handed codes to unhanded ones “for our convenience”.  Translate back */
        switch (msg->message) {	// https://stackoverflow.com/questions/5681284/how-do-i-distinguish-between-left-and-right-keys-ctrl-and-alt/77281559#77281559
          case WM_KEYUP: case WM_SYSKEYUP:
          case WM_KEYDOWN: case WM_SYSKEYDOWN:  
            switch ((vk = vk_orig = LOWORD(msg->wParam))) {			// Redo (see above)
              case VK_SHIFT:   // converts to VK_LSHIFT or VK_RSHIFT
              case VK_CONTROL: // converts to VK_LCONTROL or VK_RCONTROL
              case VK_MENU:    // converts to VK_LMENU or VK_RMENU
              {
                  WORD keyFlags = HIWORD(msg->lParam);
                  WORD scanCode = LOBYTE(keyFlags);
                  BOOL isExtendedKey = (keyFlags & KF_EXTENDED) == KF_EXTENDED;
    
                  if (isExtendedKey)
                      scanCode = MAKEWORD(scanCode, 0xE0);
                  switch (vk)	 // if we want to distinguish these keys:
                  {
                    case VK_SHIFT:   // converts to VK_LSHIFT or VK_RSHIFT
                      vk1 = VK_LSHIFT;  vk2 = VK_RSHIFT;
                      goto do_map;
                    case VK_CONTROL: // converts to VK_LCONTROL or VK_RCONTROL
                      vk1 = VK_LCONTROL;  vk2 = VK_RCONTROL;
                      goto do_map;
                    case VK_MENU:    // converts to VK_LMENU or VK_RMENU
                      vk1 = VK_LMENU;  vk2 = VK_RMENU;
                            do_map:
                      vk = LOWORD(MapVirtualKeyW(scanCode, MAPVK_VSC_TO_VK_EX));
                      if ((vk != vk1) && (vk != vk2))
                          vk = vk_orig;			// XXXX Should not happen!  (Same for the code below as -1)
                      break;
                  }
              }
            }
//            if (KEY_up == stp->tapAlt) // Focus may have been stolen (without getting any message); resync (needed if KLLFA)
//                reset_KBD_state(stp, astp, msg->message, msg->wParam, msg->lParam, f_Flags & (1<<f_noInferMods), 
//                                f_Flags & (1<<f_forceSpecKeys), f_Flags & (1<<f_forceKeyState), f_Flags & (1<<f_noSmartSkip));
            break;
          default:
            vk =  vk_orig = -1;
        }

        switch (msg->message) {	// Hack: work around silent stealing of focus in Rich Edit on tapping Alt (when Ctrl is up)
          case WM_KEYDOWN: case WM_SYSKEYDOWN:	// If focus was silently stolen, need to recheck the flags (if KLLFA)
            if (vk_orig == VK_MENU)			// XXXX If starting with KEY_down_aftertap, this does not trigger the second tap???
                stp->tapAlt = ((KEY_up == stp->tapAlt) ? KEY_down_aftertap : KEY_down);
            else
                stp->tapAlt = ((KEY_up == stp->tapAlt) ? KEY_aftertap : KEY_intrr);
            break;
          case WM_KEYUP: case WM_SYSKEYUP:
            if (KEY_up == stp->tapAlt)
                stp->tapAlt = KEY_aftertap;
            else if (VK_MENU == vk_orig && ((KEY_down == stp->tapAlt) || (KEY_down_aftertap == stp->tapAlt))
                     && KEY_down != stp->rCtrl && lCtrl_real != stp->lCtrl)	// wrong for nokllfa_any — but we don’t care
                stp->tapAlt = KEY_up;			// Focus may be silently stolen!!!
            else
                stp->tapAlt = KEY_intrr;
            break;
        }		// When stolen, the cursor stops blinking, no messages are received — since OldEditProc() returns only at end

        // With KLLF_ALTGR, a press (or keyrepeat) of rAlt is preceded by a fake press of lCtrl with the same timestamp — unless
        // any Ctrl is “really down”.  This finite automaton tries to detect when rAlt arrives differently (and then we know it
        // is not KLLF_ALTGR (without doing the accelerator-trick; we write this to stp->is_KLLFA); also, we detect when rCtrl
        // arrives differently (and then it is a real Ctrl-modifier for a keybinding).
        //     Additionally, if rAlt and lCtrl are down (and stp->is_KLLFA is “unknown”), we use the accelerator-trick
//            if (stp->lCtrl == lCtrl_first) {
//                stp->lCtrl = lCtrl_real;
//            } else
        if (vk == VK_LCONTROL) {
//                    msg_cnt++;
            if (msg->message == WM_KEYDOWN || msg->message == WM_SYSKEYDOWN) {
                if (stp->rCtrl == KEY_down)		// No “fakes” generated
                    stp->lCtrl = lCtrl_real;		// Sticky state, until up/reset
                else if (stp->lCtrl == lCtrl_unknown || stp->lCtrl == lCtrl_up
                         || stp->lCtrl == lCtrl_maybefake || stp->lCtrl == lCtrl_dn_unknown)
                    stp->lCtrl = lCtrl_first;		// Undecided: might be a fake generated by keypress/keyrepeat of rAlt
                else if (stp->lCtrl == lCtrl_first)
                    stp->lCtrl = lCtrl_real;		// dup of unrelated
                if (stp->rAlt == KEY_down && ignore_accel >= 0 && stp->is_KLLFA < 0)
                    goto check_KLLFA;			// ??? may be UNREACHED!!! How to order w.r.t. the top?
            } else if (msg->message == WM_KEYUP || msg->message == WM_SYSKEYUP) {
                if (stp->lCtrl != lCtrl_noKLLFA_any)	// Sticky state, until reset
                    stp->lCtrl = lCtrl_up;
            } else
                goto unrelated;
        } else if (vk == VK_RCONTROL) {
            if (msg->message == WM_KEYDOWN || msg->message == WM_SYSKEYDOWN) {
                stp->rCtrl = KEY_down;
            } else if (msg->message == WM_KEYUP || msg->message == WM_SYSKEYUP) {
                stp->rCtrl = KEY_up;
            }
            goto unrelated;
        } else if (vk == VK_RMENU) {
            if (msg->message == WM_KEYDOWN || msg->message == WM_SYSKEYDOWN) {
                stp->rAlt = KEY_down;
                if (stp->lCtrl == lCtrl_first) {		// The MOST IMPORTANT check (this is what all this is about…)
                    if (stp->prMsgTime == msg->time && stp->rCtrl != KEY_down) // See the second-next comment about rCtrl
                        stp->lCtrl = lCtrl_maybefake;	// very probable that lCtrl was fake
                    else
                        stp->lCtrl = lCtrl_real;
                } else if (stp->lCtrl == lCtrl_dn_unknown) {
                    if (stp->rCtrl == KEY_down) // If rCtrl pressed after AltGr ⇒ ¬AltGr-autorepeat; before ⇒ no fake lCtrl
                        stp->lCtrl = lCtrl_real;
                    else
                        stp->lCtrl = lCtrl_maybefake;
                } else if (stp->lCtrl == lCtrl_maybefake) { // Seems to be reachable only if maybefake was not!  Update flag???
                    if (stp->rCtrl == KEY_up) // Seems that the other case is unreachable (↓rCtrl would stop rAlt-autorepeat)
                        stp->lCtrl = lCtrl_real;
                } else if ((stp->lCtrl == lCtrl_up) && (stp->rCtrl == KEY_up)) { // Must have been faked if stp->is_KLLFA
                    stp->lCtrl = lCtrl_noKLLFA_any;	// Sticky state, until reset
                    stp->is_KLLFA = 0;
                }
                if (ignore_accel >= 0 && stp->is_KLLFA < 0 && ((stp->lCtrl == lCtrl_first) || (stp->lCtrl == lCtrl_maybefake) || (stp->lCtrl == lCtrl_real))) {
                  check_KLLFA:
//			MessageBoxW(hwnd, L"Before Check_KLLF_ALTGR()", L"Warning", MB_ICONEXCLAMATION | MB_OK);

                    ignore_accel = 1;		// Warn the message handler that we are faking it
                    Rc = Check_KLLF_ALTGR(msg, 0xE8 /* Unassigned VK_-code */, ID_ACCEL_FAKE);
                    ignore_accel = -1;		// preliminary; will give up unless reset to 0

                    switch (Rc) {
                      case update_lCtrl_Flag0:  case update_lCtrl_Flag1:
                        ignore_accel = 0;	// Success.  Switch processing of (SYS)COMMANDS back to normal
                        if (!(stp->is_KLLFA = (Rc == update_lCtrl_Flag1)))
                            stp->lCtrl = lCtrl_noKLLFA_any;		// sticky state — until reset
                        break;
                      case update_lCtrl_FlagRetry:
                        ignore_accel = 0;		// May retry later
                        Rc = update_lCtrl_normal;
                    }
                }
            } else if (msg->message == WM_KEYUP || msg->message == WM_SYSKEYUP) {
                    stp->rAlt = KEY_up;
                    if (stp->lCtrl == lCtrl_maybefake)		// If “fake”, lCtrl-up would be generated first
                        stp->lCtrl = lCtrl_real;
                    else
                        goto unrelated;
            } else
                    goto unrelated;
        } else {
          unrelated:
            if (stp->lCtrl == lCtrl_first)
                stp->lCtrl = lCtrl_real;
        }
    }
    stp->prMsgTime = msg->time;
    return Rc;				// OK
}

// Define the scancodes for the numpad keys
#define NUMPAD_0 0x52
#define NUMPAD_1 0x4f
#define NUMPAD_2 0x50
#define NUMPAD_3 0x51
#define NUMPAD_4 0x4b
#define NUMPAD_5 0x4c
#define NUMPAD_6 0x4d
#define NUMPAD_7 0x47
#define NUMPAD_8 0x48
#define NUMPAD_9 0x49
#define NUMPAD_PERIOD 0x53
#define NUMPAD_PLUS 0x4e
#define NUMPAD_st  NUMPAD_7
#define NUMPAD_end NUMPAD_PERIOD
#define NUMPAD_miss 0x4a
#define not_a_digit (-10)

int NUMPAD_scancode_to_i(int scancode) {	// We do not use details of the negative return
  if (NUMPAD_miss == scancode) return not_a_digit;
  int out = scancode-7*((scancode+2)>>2)+0x3e;  // 0 for Plus, -2 for period, -3 for 0

  if (out > 0)
    return out;
  return -3 - out;	// -3 for Plus, -1 for period  (4a sent to 3; otherwise handles 0x47 to 0x53)
}

// Return:  0 if this should not be tried to be processed as delivering characters, -1 for was-ignored, 1 on success
int process_Alt_NUMPAD(MSG *Msg, int cnt_down, int flags, struct Alt_NUMPAD_State *statep) // staccatto_NOTIMPLEMENTED,
{
    int scancode = (Msg->lParam & 0x00ff0000) >> 16;
    int extended = (Msg->lParam & 0x01000000) != 0;
    int wParam = Msg->wParam;
    int wasDn = (Msg->lParam >> 30) & 0x1;
    int msg = Msg->message;
    int maybe_digit;

    if (statep->factor == 16 && ((wParam >= '0' && wParam <= '9') || (wParam >= 'A' && wParam <= 'F'))) // Hex digit 0-9, A-F
        maybe_digit = (wParam >= 'A' ? wParam - 'A' + 10 : wParam - '0');
    else if ((scancode >= NUMPAD_st && scancode <= NUMPAD_end) && !extended)
        maybe_digit = NUMPAD_scancode_to_i(scancode);	// from -3 to 9 or not_a_digit<-3
    else
        maybe_digit = not_a_digit;			// less than -3

    switch (msg) {
      case WM_KEYDOWN:  case WM_SYSKEYDOWN:
        if (wasDn) {					// Do not process keyrepeat events (except those after stolen keys)
            switch (statep->aNpState) {
                case npST_ERROR:  case npST_SUCCESS: case npST_ERROR_PLUS: case npST_ERROR_PERIOD:
                    statep->aNpState = npST_NONE;
            }
            if (kbdState.tapAlt != KEY_down_aftertap)	// More intuitive: ignore repeat on the first non-stolen Alt-down
                goto do_really_ignore;
        }
        switch (statep->aNpState) {
          case npST_NONE:  case npST_ERROR:  case npST_SUCCESS:  case npST_ERROR_PLUS:  case npST_ERROR_PERIOD:	// Same as NONE
            if (wParam == VK_MENU && cnt_down == 1) {	// Keys-down == “Only Alt”; nothing else interesting is down
                statep->aNpState = npST_ALT_DOWN;
                statep->input = 0;
                statep->factor = 10;			// Disallow non-numpad input until later
            } else
                statep->aNpState = npST_NONE;
	    break;
          case npST_ALT_DOWN:
            if ( extended || maybe_digit == not_a_digit 	// Not a starter
                 || ((flags & (1<<pTMf_skip_altNumHex)) && (scancode == NUMPAD_PLUS || scancode == NUMPAD_PERIOD)) )
                statep->aNpState = npST_NONE;		// Safe to ignore key-down of Alt
            else {
                statep->is_oem = !(scancode == NUMPAD_PLUS || scancode == NUMPAD_0);
                statep->factor = ((scancode == NUMPAD_PLUS || scancode == NUMPAD_PERIOD) ? 16 : 10);
                if (maybe_digit < 0) {
                    statep->input = 0;
                    if (scancode == NUMPAD_PLUS)
                        statep->aNpState = npST_STARTED_WITH_PLUS;
                    else				// (scancode == NUMPAD_PERIOD)
                        statep->aNpState = npST_STARTED_WITH_PERIOD;
                    break;
                }
                statep->input = statep->last_digit = maybe_digit;
                statep->aNpState = npST_IN_DIGIT;
            }
            break;

          case npST_AFTER_DIGIT:   case npST_STARTED_WITH_PERIOD_UP:  case npST_STARTED_WITH_PLUS_UP:
          {
              if (maybe_digit >= 0) { // Hex digit 0-9, A-F
                  statep->input = statep->input * statep->factor + maybe_digit;
                  statep->aNpState = npST_IN_DIGIT;
                  statep->last_digit = maybe_digit;
              } else {					// Can one replay the aborted part of the input?
                do_error:
                  if (statep->aNpState == npST_STARTED_WITH_PERIOD || statep->aNpState == npST_STARTED_WITH_PERIOD_UP)
                      statep->aNpState = npST_ERROR_PERIOD;
                  else if (statep->aNpState == npST_STARTED_WITH_PLUS || statep->aNpState == npST_STARTED_WITH_PLUS_UP)
                      statep->aNpState = npST_ERROR_PLUS;
                  else
                      statep->aNpState = npST_ERROR;
              }
              break;
          }

          case npST_IN_DIGIT:   case npST_STARTED_WITH_PERIOD:  case npST_STARTED_WITH_PLUS:
            goto do_error;
            break;

          default:				// Unreachable???
            statep->aNpState = npST_ERROR;		// We ignored keyrepeat
            break;
        }
        break;

      case WM_KEYUP:  case WM_SYSKEYUP:
        if (wParam == VK_MENU) { // Alt key; did we get any digit?
            switch (statep->aNpState) {
              case npST_IN_DIGIT:  case npST_AFTER_DIGIT:
                statep->aNpState = npST_SUCCESS;
                return 1;
              default:
                goto do_error;
            }
        } else {		// maybe ignore non-digit keyups if started to enter digits
            switch (statep->aNpState) {
	      case npST_IN_DIGIT:
	        if (maybe_digit == statep->last_digit)
	            statep->aNpState = npST_AFTER_DIGIT;
	        else
	            statep->aNpState = npST_ERROR;
	        break;
	      case npST_STARTED_WITH_PERIOD:  case npST_STARTED_WITH_PLUS:
	        {
	           int is_plus = statep->aNpState == npST_STARTED_WITH_PLUS;

                   if (scancode == (is_plus ? NUMPAD_PLUS : NUMPAD_PERIOD))
                       statep->aNpState = (is_plus ? npST_STARTED_WITH_PLUS_UP : npST_STARTED_WITH_PERIOD_UP);
                   else
                       goto do_error;
                   break;
	        }
	      case npST_AFTER_DIGIT:   case npST_STARTED_WITH_PERIOD_UP:  case npST_STARTED_WITH_PLUS_UP:
                goto do_error;
              case npST_ERROR:  case npST_SUCCESS: case npST_ERROR_PERIOD: case npST_ERROR_PLUS: case npST_NONE:
                statep->aNpState = npST_NONE;
                break;
              default:				// Only one state: ALT_DOWN
                goto do_error;
            }
        }
        break;
      default:					// Other messages: fall through
    }
  do_really_ignore:
    if (statep->aNpState >= npST_ALT_DOWN)		// During processing
        return 0;
    return -1;				// Ignore non-key-up/down messages
}

// Make input of characters by ordinal as simple as possible.  Start with Period/Plus for HEX; start with 0 or Plus for Unicode.

// For legacy 8-bit input (= “starting with period or 1–9”), allow 2-digit hex and 3-digit decimals. An extensions: precede by code
//  The last two digits (hex) or 3-digits (decimal, taken mod 256) are taken in an 8-bit encoding; with no extra digits as CP_OEMCP.
//  Extra preceding digits are taken as a decimal (in hex mode might be hex too — this leads in no conflict) codepage number (if >99).
//  Shorter extra prefixes (must be decimal) are taken as shortcuts to codepages, or font-encodings (now: 6/7/9=wingd⁺/webd⁺/symbol⁺).
//  (For compatibility with 0=OEM) 0 and 1 are swapped for “standard windows shortcuts” 0–3 (so 1=current-ANSI-cp, 2=current-Mac,
//     3=thread-OEM).
//  Extra shortcuts: 4⇝437, 5⇝1252⁺, 8⇝850. (With ⁺ meaning that 0x0–0x1f and 0x7f are mappend to the “visual” U+24xx range.)
//   By last digit: 5x ⇝ 125x⁺;  9x ⇝ ISO-8859-X⁺ (X=1–10);  8x ⇝ 86x or 857, 858;  7x ⇝ 5700x or 5701x; 6x ⇝ Latin no. x alphabet⁺
//                  1x ⇝ 1000x or 10029.

// Non-legacy extensions: too many digits:  de-surrogate, or de-UTF-8 (for 2-bytes UTF-8, follow by 00) — if makes sense.

unsigned int deHex(unsigned int i) // “out” printed in decimal is i printed in hex.  So converts 0x123 to 123.
{
    unsigned int factor = 1, out = 0;

    while (i) {
        out += factor * (i & 0x0f);
        factor *= 10;			// cannot wrap around
        i >>= 4;
    }
    return out;
}

#define toSURR1(n)	((((n) - 0x10000)>>10) + 0xd800)
#define toSURR2(n)	(((n) & 0x3ff)         + 0xdc00)
#define fromSURR(n1,n2)	(0x10000 + (((n1)-0xd800)<<10)  + ((n2)-0xdc00))

	// Need also to handle a control-char meaningfully (extra argument lenCtrl???)
void prtW_gotUniString(HWND hwnd, WCHAR *buf, int buflen, WCHAR *out, int len, int Len, char *prefx, void (*prtW)(HWND h, WCHAR *s)) {
    WCHAR oo[2] = {0, 0};

    if (len >= Len) {
        oo[0] = out[Len-1];
        out[Len-1] = 0;
    } else if (len < 0)
        out[-len] = 0;
    else
        out[len] = 0;

    if (len < 0)	// out[0] is junk for ≥second deadkey in a chain of deadkeys.  (However, we do not care here!)
        swprintf(buf, buflen, L"     %sToUnicode -> prefix char <%ls> 0x%04X (-len=%d)\r\n", prefx, out, out[0], len);
    else if (len == 1 && (out[0] >= 0x20 && out[0] != 0x7F))
        swprintf(buf, buflen, L"     %sToUnicode -> 1 char <%ls> U+%04x\r\n", prefx, out, out[0]);
    else if (len == 1)
        swprintf(buf, buflen, L"     %sToUnicode -> 1 char  ^%c U+%04x\r\n", prefx, (out[0] != 0x7F) ? 0x40 + out[0] : '?', out[0]);
    else 
        swprintf(buf, buflen, L"     %sToUnicode -> %d codepoints <%ls>\r\n", prefx, len, out);
    prtW(hwnd, buf);

    if (oo[0])
        out[Len-1] = oo[0];
}

//  Below, one should better document when we call (an analogue of) TranslateMessage inside the subroutine.  (We wrote: WM_CHARS.)

// Handling a key-down/up event should depend on whether we judge the user’s intent was to produces a character-to-insert.
//
// =======  Possible variants of the input ===========
// Involves only the standard modifier keys.  (Ignore!).
// Involves only the recognized modifier keys.  (Ignore!).
//        (To recognize an unusual modifier key, one may need to see whether it was “used as a modifier”.)
// Finished Alt-Numeric input.  (Controlled by pTMf_???)
// May be a part of Alt-Numeric input.  (Ignore!  Conditional on pTMf_altNum: INIMPLEMENTED???)
// Turned out to be mis-recognized Alt-Numeric input.  (A judgement call: One may want “to replay it” to trigger its action.)
//        (Replaying has a chance to confuse the user, since the action would not happen on the key press.  INIMPLEMENTED???)
// Alt-Numeric input aborted inside a number input.  (Unclear what to do: just beep?!)
//
//           *** Below, we do not focus on prefix keys; they are treated same as “characters”. ***  (But rc should be different?)
//
// Input not producing a character.  (Trigger the associated action.)
// Character(s)-to-insert are produced, which cannot be entered “in a simpler way”.  (WM_CHAR⸣s should be posted)
//      (It is during checking for «cannot be entered “in a simpler way”» that we can recognize “unusual modifiers”)
// Character(s)-to-insert are produced with AltGr and lCtrl, and only lCtrl “is excessive”, but KLLF_ALTGR is known to be set.
//      (Should do as above.  Does it make sense to make this configurable???)
// Same, but KLLF_ALTGR is not yet known to be set.  (What to do?  Is this even possible???  Unimplemented???)
// Character(s)-to-insert are produced with lCtrl-lAlt when they differ from what AltGr-' (= lCtrl-rAlt-') produces should insert.
// Character(s)-to-insert are produced with lCtrl-lAlt (with no other Ctrl or Alt), but KLLF_ALTGR is known to be set, and the
//   same output comes from AltGr.  (The result should be controlled by a flag???)
//         (If checking for KLLF_ALTGR should be startable also on rCtrl and on lAlt up [if lCtrl+rAlt are down], then one
//          can reliably detect KLLF_ALTGR in this situation!).
//      (If the application processes Double-Ctrl and/or Double-Alt (e.g., as Super- and Super-Meta- modifiers), then WHAT TO DO???)
//          [Check particular cases whether such “substitution” may be intended by the user to avoid conflicts with insert-chars.]
// Characters are produced on KLLF_ALTGR layout with user adding an explicit lCtrl modifier to AltGr (subject to pTMf_ignore_lCtrl).
// Character(s)-to-insert are produced, but some of the modifier keys may be omitted, and these modifier keys are known to be
//   used with accelerators in the application.
//      (The list of these modifiers together with the emitted string/prefix-key should be given to the application.  The application
//       should decide itself whether it wants to trigger the action associated with the full collection of key-downs + VK-code,
//       or with “known excessive keys” + fake-vk-code-associated-with-the-omitted string, such as Alt + ℂ-in or Win + Alt + `-pk.
//       Here ℂ-in and `-pk are “atoms” — e.g., “symbols” in the case of Emacs.  They correspond to the input of “ℂ” and the prefix
//       key `.)
// Should not one also treat Shift-bindings on NUMPADn keys (not accessible from strictly-follow-Window-API applications)?
// Should not one also treat “unhandled” deadkey-combinations like 'p to emit ṕ?

   // Write user-visible events (and intent) in these 18 cases.  (Order according to the programming logic, except for an
   // explicit lCtrl — which should come before checking for input.)     We use the symbol ⇅ to emphasize that Alt is not released…
	// ✘ ☒ for (yet?) unimplemented (for “actions” we implement only “gather-info”, not “trigger”;  “⇝” for controlling flags
   // Ctrl-Shift    should be ignored.
   // Shift-AppMenu (when AppMenu is a modifier changing the emitted characters) should be ignored (XXXX recognized only after AppMenu used as such a modifier!)
   // Alt-6⇅7       (after Alt going up) producing the character C≡U+0043.  Here 0x43 == 67.		⇝ pTMf_skip_altNum
   // Alt-+⇅4⇅3     (after Alt going up) producing the character C≡U+0043.  Here and below + is Gray+.	⇝ pTMf_skip_altNumHex
   // Alt-+⇅4⇅3     with Alt still down; should be ignored (Here ⇅ means release the previous key and press the next)
   // Alt-+       ☒ (after Alt going up and other “interruptions”) triggering the action assigned to A-Gray+
   // Alt-6       ☒ (after Alt going up; 6 is on numpad) Was the intent to enter U+0006, or “6 with modifier Alt”???  Need a flag…
   // Alt-+⇅4⇅m   ✘ What was the intent of this?!  (This looks like the hex input of U+4xx unexpectedly-interrupted by m.)
   //		                  XXXX It is unclear what to do — due to not seeing what may be the possible intent???
   // Ctrl-Alt-Backspace  triggering the action assigned to C-A-Backspace.
   // rightAlt-'    (with rightAlt being, say, VK_OEM_8) producing a character, say ∂.  (Or a prefix key.)
   // AltGr-'       on “AltGr-layouts” (with “a robust users’ experience”) producing a character, say ∂.  (Or a prefix key.)
   //               The applications see leftCtrl-rightAlt-'.  With the bitmaps for “a robust users’ experience” the application
   //               would see that the same character may be produced by “just rightAlt-'”.
   //		            (So a bright but not ultra-bright application may think the user’s intent was leftCtrl-∂!)
   //   〃	    Likewise, but the application had no data to deduce that this layout is an “AltGr-layouts”.
   // lCtrl-lAlt-'  producing ⎖ when AltGr-' (= lCtrl-rAlt-') produces ∂ should both insert the corresponding characters.
   // lCtrl-lAlt-'  when it produces the same character as AltGr-' should trigger the action assigned to C-A-'. ⇝ pTMf_ignore_CtrlAlt pTMf_only_lCtrllAlt
   // rAlt-lCtrl-'  on “AltGr-layouts” (so for “naive” applications this looks the same as AltGr-') triggering the action
   //		    assigned to C-A-'.  (When AltGr-' and lCtrl-lAlt-' produce different characters, this may be the only way to
   //		    trigger C-A-'.)  Likewise for lCtrl-rAlt-' (which the applications can tell apart from AltGr-' only
   //		    probabilistically, by inspecting the timing data).
   // Win-AltGr-'   (assuming it produces the same character ∂ as AltGr-') should trigger the action assigned to either Win-∂, or
   //                to Win-C-A-' (or should it be Win-A-'???  Win-Meta-'???).
   // Shift-AltGr-Numpad9 ☒ when NumLock is on (maybe should) deliver a character bound to Numpad9 with Shift-AltGr modifiers.
   //	(This binding is not accessible by applications doing the STD Windows keyboard processing: they see AltGr-PgUp
   //    Emacs was doing the translation to NUMPADx — but only for key bindings, not for insertion…)
   // AltGr-' p	  ☒ When “unhandled” by keyboard (emitting e.g. “´p”) emit the (normalized/combined?) form ṕ.

int ctrlLen(int len, WCHAR *out, int ctrlDown) {	// 0 if it is legacy-delivered-Ctrl-char
    if (1 == len && (out[0] < 0x20 || out[0] == 0x7f || (out[0] == 0x20 && ctrlDown)))
        return 0;
    return len;
}

int preTranslateMessage(MSG *msg, unsigned long flags, struct Alt_NUMPAD_State *pst, void (*prtW)(HWND h, WCHAR *s)) // For the rationale, see above.  Return 0 if this should not be tried to be processed as delivering characters
{
    BYTE ks[256];
    int cntHanded[4] = {0, 0, 0, 0}, cntBase[4], cntDups[4], cntStd = 0, vkStrt = 1, vkEnd = 0xFF, ckMatch = 1, ctrlCh[3] = {0, 0, 0}; // Shift, Ctrl, Alt, Win
    const BYTE chk[] = {VK_LSHIFT, VK_RSHIFT, VK_LCONTROL, VK_RCONTROL, VK_LMENU, VK_RMENU, VK_LWIN, VK_RWIN};
    WCHAR out[512];	// The legacy layout may return up to 255 codepoints; but be safe: https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#Keyboard-input-on-Windows,-Part-II:-The-semantic-of-ToUnicode()
    WCHAR buffer[256+ARRAY_LENGTH(out)];

    GetKeyboardState(ks);
    for (int i = 0; i < ARRAY_LENGTH(chk)/2; i++) {
        cntBase[i] = (0 != (ks[i+VK_SHIFT] & 0x80));
        for (int j = 0; j < 2; j++)
            if (ks[chk[2*i+j]] & 0x80)
                cntHanded[i]++;
        cntStd += (cntDups[i] = (cntHanded[i] ? cntHanded[i] : cntBase[i]));	// Somebody must have played-back unhanded keys
    }

    int oSt = pst->aNpState;
    switch ((flags & (1<<pTMf_skip_altNum)) ? -2 : process_Alt_NUMPAD(msg, cntStd, flags, pst)) {
      case 0:					// Eat Alt_NUMPAD input: do not call TranslateMessage
        if (oSt != pst->aNpState) {
            swprintf(buffer, ARRAY_LENGTH(buffer), L"     process_Alt_NUMPAD -> state=%d num=0x%04x (%u)\r\n", pst->aNpState, pst->input, pst->input);
            prtW(msg->hwnd, buffer);
        }
        return 0;
      case -1:  case -2:
        break;
      default:					// Got a character
        unsigned int k = pst->input;

        if (pst->is_oem) { // Legacy GALORE: Convert those in range 0..255 to OEM; extensions: extra digits → cp; with shortcuts
            int flag = ((10 == pst->factor) ? (k/1000) : (k>>8)), do_ctrl = 0, out = 0, if0 = 0, do_euro = 0, iflag = flag;
            char b = ((10 == pst->factor) ? (k%1000) : k) & 0xFF;
	    wchar_t unicodeChar = 0, patch_strt, *patch = NULL, patch_len;	// unicodeChar for cases it fits in 1 codepoint
	    const wchar_t smb[2][0x60] = {{	// Compare with https://unicode.org/Public/MAPPINGS/VENDORS/ADOBE/symbol.txt
	// perl -wane "next if /^#/; next if $s{$F[1]}++; $o[hex $F[1]] = uc $F[0]; END{my $c;($c++ % 16 or print qq(\n)), print qq(0x$o[$_], ) for 0x20..0x7f, 0xa0..0xff}" symbol.txt > symb-init
	//   Except 0x20AC and 0x220B, coincides with https://stackoverflow.com/questions/3346962/mapping-between-wingdings-symbol-characters-and-their-unicode-equivalents#
	// perl -C31 -wane "warn $_ unless /^\s*(\S+)\s*=\s*\S\s+U\+(\S+)/; @F = ($2,$1); next if $s{$F[1]}++; $o[hex $F[1]] = uc $F[0]; END{my $c;($c++ % 16 or print qq(\n)), print qq(0x$o[$_], ) for 0x20..0x7f, 0xa0..0xff}" symb-SE > symb-init-SE
  0x0020, 0x0021, 0x2200, 0x0023, 0x2203, 0x0025, 0x0026, 0x220B, 0x0028, 0x0029, 0x2217, 0x002B, 0x002C, 0x2212, 0x002E, 0x002F, 
  0x0030, 0x0031, 0x0032, 0x0033, 0x0034, 0x0035, 0x0036, 0x0037, 0x0038, 0x0039, 0x003A, 0x003B, 0x003C, 0x003D, 0x003E, 0x003F, 
  0x2245, 0x0391, 0x0392, 0x03A7, 0x0394, 0x0395, 0x03A6, 0x0393, 0x0397, 0x0399, 0x03D1, 0x039A, 0x039B, 0x039C, 0x039D, 0x039F, 
  0x03A0, 0x0398, 0x03A1, 0x03A3, 0x03A4, 0x03A5, 0x03C2, 0x03A9, 0x039E, 0x03A8, 0x0396, 0x005B, 0x2234, 0x005D, 0x22A5, 0x005F, 
  0xF8E5, 0x03B1, 0x03B2, 0x03C7, 0x03B4, 0x03B5, 0x03C6, 0x03B3, 0x03B7, 0x03B9, 0x03D5, 0x03BA, 0x03BB, 0x03BC, 0x03BD, 0x03BF, 
  0x03C0, 0x03B8, 0x03C1, 0x03C3, 0x03C4, 0x03C5, 0x03D6, 0x03C9, 0x03BE, 0x03C8, 0x03B6, 0x007B, 0x007C, 0x007D, 0x223C, 0x0}, {
  0x20AC, 0x03D2, 0x2032, 0x2264, 0x2044, 0x221E, 0x0192, 0x2663, 0x2666, 0x2665, 0x2660, 0x2194, 0x2190, 0x2191, 0x2192, 0x2193, 
  0x00B0, 0x00B1, 0x2033, 0x2265, 0x00D7, 0x221D, 0x2202, 0x2022, 0x00F7, 0x2260, 0x2261, 0x2248, 0x2026, 0x23D0, 0x23AF, 0x21B5, 
  0x2135, 0x2111, 0x211C, 0x2118, 0x2297, 0x2295, 0x2205, 0x2229, 0x222A, 0x2283, 0x2287, 0x2284, 0x2282, 0x2286, 0x2208, 0x2209, 
  0x2220, 0x2207, 0x00AE, 0x00A9, 0x2122, 0x220F, 0x221A, 0x22C5, 0x00AC, 0x2227, 0x2228, 0x21D4, 0x21D0, 0x21D1, 0x21D2, 0x21D3, 
  0x25CA, 0x27E8, 0x00AE, 0x00A9, 0x2122, 0x2211, 0x239B, 0x239C, 0x239D, 0x23A1, 0x23A2, 0x23A3, 0x23A7, 0x23A8, 0x23A9, 0x23AA, 
  0x20AC, 0x27E9, 0x222B, 0x2320, 0x23AE, 0x2321, 0x239E, 0x239F, 0x23A0, 0x23A4, 0x23A5, 0x23A6, 0x23AB, 0x23AC, 0x23AD, 0x0	}};
    //   Webdings (0): mismatches SE report above: scraped https://en.wikipedia.org/w/index.php?title=Webdings&action=edit&section=2
    // perl -wne "print qq(\n) if /chset-left1/; next unless /chset-(ctrl|cell)1\|(?:u=(\w+))?/; $p = 5>length($2||0) && 0; print q(0x), $p, $2||q(), q(, )" webdings-wiki >webdings-wiki-init
    //   wingdings: matches SE report above (except 7f,ff): scraped https://en.wikipedia.org/w/index.php?title=Wingdings&action=edit&section=2
    // perl -C31 -wle "my $P=shift; chomp (@in=<>); for my $i (0..@in-3) {$_=$in[$i]; $_ .= $in[++$i] if /^$P/ and not 4==length; next unless /^\s*$P(\d{3})$/; $a=$1; $_ = $in[$i+=2]; $_ .= $in[++$i] while 4>=length and (4>length or /1f../i); next unless /^[\da-f]{4,5}$/i; printf qq(\x2502x\t\x25s\n), $a, $_}" 1 n4384-nn1 | sort -u >n4384-with0-2col-b1-nn1
    // Mismatches N4384 (which is better): 231B vs 23F3 ⏳ HOURGLASS WITH FLOWING SAND;   261f vs 1F597 🖗 WHITE DOWN POINTING LEFT HAND INDEX
    // 2B29 BLACK SMALL DIAMOND vs 1F799 🞙 BLACK MEDIUM SMALL DIAMOND
	    const int wingdings[4][0xe0] = {{ // 0=webdings; 1–3 are wingdings N; as above; compare with https://www.unicode.org/wg2/docs/n4384.pdf (and Wikipedia pages)
      0x0, 0x1F577, 0x1F578, 0x1F572, 0x1F576, 0x1F3C6, 0x1F396, 0x1F587, 0x1F5E8, 0x1F5E9, 0x1F5F0, 0x1F5F1, 0x1F336, 0x1F397, 0x1F67E, 0x1F67C, 
  0x1F5D5, 0x1F5D6, 0x1F5D7, 0x023F4, 0x023F5, 0x023F6, 0x023F7, 0x023EA, 0x023E9, 0x023EE, 0x023ED, 0x023F8, 0x023F9, 0x023FA, 0x1F5DA, 0x1F5F3, 
  0x1F6E0, 0x1F3D7, 0x1F3D8, 0x1F3D9, 0x1F3DA, 0x1F3DC, 0x1F3ED, 0x1F3DB, 0x1F3E0, 0x1F3D6, 0x1F3DD, 0x1F6E3, 0x1F50D, 0x1F3D4, 0x1F441, 0x1F442, 
  0x1F3DE, 0x1F3D5, 0x1F6E4, 0x1F3DF, 0x1F6F3, 0x1F56C, 0x1F56B, 0x1F568, 0x1F508, 0x1F394, 0x1F395, 0x1F5EC, 0x1F67D, 0x1F5ED, 0x1F5EA, 0x1F5EB, 
  0x02B94, 0x02714, 0x1F6B2, 0x02B1C, 0x1F6E1, 0x1F4E6, 0x1F6F1, 0x02B1B, 0x1F691, 0x1F6C8, 0x1F6E9, 0x1F6F0, 0x1F7C8, 0x1F574, 0x02B24, 0x1F6E5, 
  0x1F694, 0x1F5D8, 0x1F5D9, 0x02753, 0x1F6F2, 0x1F687, 0x1F68D, 0x026F3, 0x029B8, 0x02296, 0x1F6AD, 0x1F5EE, 0x023D0, 0x1F5EF, 0x1F5F2, 0x0, 
  0x1F6B9, 0x1F6BA, 0x1F6C9, 0x1F6CA, 0x1F6BC, 0x1F47D, 0x1F3CB, 0x026F7, 0x1F3C2, 0x1F3CC, 0x1F3CA, 0x1F3C4, 0x1F3CD, 0x1F3CE, 0x1F698, 0x1F5E0, 
  0x1F6E2, 0x1F4B0, 0x1F3F7, 0x1F4B3, 0x1F46A, 0x1F5E1, 0x1F5E2, 0x1F5E3, 0x0272F, 0x1F584, 0x1F585, 0x1F583, 0x1F586, 0x1F5B9, 0x1F5BA, 0x1F5BB, 
  0x1F575, 0x1F570, 0x1F5BD, 0x1F5BE, 0x1F4CB, 0x1F5D2, 0x1F5D3, 0x1F56E, 0x1F4DA, 0x1F5DE, 0x1F5DF, 0x1F5C3, 0x1F5C2, 0x1F5BC, 0x1F3AD, 0x1F39C, 
  0x1F398, 0x1F399, 0x1F3A7, 0x1F4BF, 0x1F39E, 0x1F4F7, 0x1F39F, 0x1F3AC, 0x1F4FD, 0x1F4F9, 0x1F4FE, 0x1F4FB, 0x1F39A, 0x1F39B, 0x1F4FA, 0x1F4BB, 
  0x1F5A5, 0x1F5A6, 0x1F5A7, 0x1F579, 0x1F3AE, 0x1F57B, 0x1F57C, 0x1F4DF, 0x1F581, 0x1F580, 0x1F5A8, 0x1F5A9, 0x1F5BF, 0x1F5AA, 0x1F5DC, 0x1F512, 
  0x1F513, 0x1F5DD, 0x1F4E5, 0x1F4E4, 0x1F573, 0x1F323, 0x1F324, 0x1F325, 0x1F326, 0x02601, 0x1F328, 0x1F327, 0x1F329, 0x1F32A, 0x1F32C, 0x1F32B, 
  0x1F31C, 0x1F321, 0x1F6CB, 0x1F6CF, 0x1F37D, 0x1F378, 0x1F6CE, 0x1F6CD, 0x024C5, 0x0267F, 0x1F6C6, 0x1F588, 0x1F393, 0x1F5E4, 0x1F5E5, 0x1F5E6, 
  0x1F5E7, 0x1F6EA, 0x1F43F, 0x1F426, 0x1F41F, 0x1F415, 0x1F408, 0x1F66C, 0x1F66E, 0x1F66D, 0x1F66F, 0x1F5FA, 0x1F30D, 0x1F30F, 0x1F30E, 0x1F54A},
    { 0x0, 0x1F589, 0x02702, 0x02701, 0x1F453, 0x1F56D, 0x1F56E, 0x1F56F, 0x1F57F, 0x02706, 0x1F582, 0x1F583, 0x1F4EA, 0x1F4EB, 0x1F4EC, 0x1F4ED, 
  0x1F5C0, 0x1F5C1, 0x1F5CE, 0x1F5CF, 0x1F5D0, 0x1F5C4, 0x023F3, 0x1F5AE, 0x1F5B0, 0x1F5B2, 0x1F5B3, 0x1F5B4, 0x1F5AB, 0x1F5AC, 0x02707, 0x0270D, 
  0x1F58E, 0x0270C, 0x1F58F, 0x1F44D, 0x1F44E, 0x0261C, 0x0261E, 0x0261D, 0x1F597, 0x1F590, 0x0263A, 0x1F610, 0x02639, 0x1F4A3, 0x1F571, 0x1F3F3, 
  0x1F3F1, 0x02708, 0x0263C, 0x1F322, 0x02744, 0x1F546, 0x0271E, 0x1F548, 0x02720, 0x02721, 0x0262A, 0x0262F, 0x1F549, 0x02638, 0x02648, 0x02649, 
  0x0264A, 0x0264B, 0x0264C, 0x0264D, 0x0264E, 0x0264F, 0x02650, 0x02651, 0x02652, 0x02653, 0x1F670, 0x1F675, 0x026AB, 0x1F53E, 0x025FC, 0x1F78F, 
  0x1F790, 0x02751, 0x02752, 0x1F79F, 0x029EB, 0x025C6, 0x02756, 0x1F799, 0x02327, 0x02BB9, 0x02318, 0x1F3F5, 0x1F3F6, 0x1F676, 0x1F677, 0x0, 
  0x1F10B, 0x02780, 0x02781, 0x02782, 0x02783, 0x02784, 0x02785, 0x02786, 0x02787, 0x02788, 0x02789, 0x1F10C, 0x0278A, 0x0278B, 0x0278C, 0x0278D, 
  0x0278E, 0x0278F, 0x02790, 0x02791, 0x02792, 0x02793, 0x1F662, 0x1F660, 0x1F661, 0x1F663, 0x1F65E, 0x1F65C, 0x1F65D, 0x1F65F, 0x02219, 0x02022, 
  0x02B1D, 0x02B58, 0x1F786, 0x1F788, 0x1F78A, 0x1F78B, 0x1F53F, 0x025AA, 0x1F78E, 0x1F7C1, 0x1F7C5, 0x02605, 0x1F7CB, 0x1F7CF, 0x1F7D3, 0x1F7D1, 
  0x02BD0, 0x02316, 0x02BCE, 0x02BCF, 0x02BD1, 0x0272A, 0x02730, 0x1F550, 0x1F551, 0x1F552, 0x1F553, 0x1F554, 0x1F555, 0x1F556, 0x1F557, 0x1F558, 
  0x1F559, 0x1F55A, 0x1F55B, 0x02BB0, 0x02BB1, 0x02BB2, 0x02BB3, 0x02BB4, 0x02BB5, 0x02BB6, 0x02BB7, 0x1F66A, 0x1F66B, 0x1F655, 0x1F654, 0x1F657, 
  0x1F656, 0x1F650, 0x1F651, 0x1F652, 0x1F653, 0x0232B, 0x02326, 0x02B98, 0x02B9A, 0x02B99, 0x02B9B, 0x02B88, 0x02B8A, 0x02B89, 0x02B8B, 0x1F868, 
  0x1F86A, 0x1F869, 0x1F86B, 0x1F86C, 0x1F86D, 0x1F86F, 0x1F86E, 0x1F878, 0x1F87A, 0x1F879, 0x1F87B, 0x1F87C, 0x1F87D, 0x1F87F, 0x1F87E, 0x021E6, 
  0x021E8, 0x021E7, 0x021E9, 0x02B04, 0x021F3, 0x02B01, 0x02B00, 0x02B03, 0x02B02, 0x1F8AC, 0x1F8AD, 0x1F5F6, 0x02713, 0x1F5F7, 0x1F5F9, 0x0},
    { 0x0, 0x1F58A, 0x1F58B, 0x1F58C, 0x1F58D, 0x02704, 0x02700, 0x1F57E, 0x1F57D, 0x1F5C5, 0x1F5C6, 0x1F5C7, 0x1F5C8, 0x1F5C9, 0x1F5CA, 0x1F5CB, 
  0x1F5CC, 0x1F5CD, 0x1F4CB, 0x1F5D1, 0x1F5D4, 0x1F5B5, 0x1F5B6, 0x1F5B7, 0x1F5B8, 0x1F5AD, 0x1F5AF, 0x1F5B1, 0x1F592, 0x1F593, 0x1F598, 0x1F599, 
  0x1F59A, 0x1F59B, 0x1F448, 0x1F449, 0x1F59C, 0x1F59D, 0x1F59E, 0x1F59F, 0x1F5A0, 0x1F5A1, 0x1F446, 0x1F447, 0x1F5A2, 0x1F5A3, 0x1F591, 0x1F5F4, 
  0x1F5F8, 0x1F5F5, 0x02611, 0x02BBD, 0x02612, 0x02BBE, 0x02BBF, 0x1F6C7, 0x029B8, 0x1F671, 0x1F674, 0x1F672, 0x1F673, 0x0203D, 0x1F679, 0x1F67A, 
  0x1F67B, 0x1F666, 0x1F664, 0x1F665, 0x1F667, 0x1F65A, 0x1F658, 0x1F659, 0x1F65B, 0x024EA, 0x02460, 0x02461, 0x02462, 0x02463, 0x02464, 0x02465, 
  0x02466, 0x02467, 0x02468, 0x02469, 0x024FF, 0x02776, 0x02777, 0x02778, 0x02779, 0x0277A, 0x0277B, 0x0277C, 0x0277D, 0x0277E, 0x0277F, 0x0, 
  0x02609, 0x1F315, 0x0263D, 0x0263E, 0x02E3F, 0x0271D, 0x1F547, 0x1F55C, 0x1F55D, 0x1F55E, 0x1F55F, 0x1F560, 0x1F561, 0x1F562, 0x1F563, 0x1F564, 
  0x1F565, 0x1F566, 0x1F567, 0x1F668, 0x1F669, 0x022C5, 0x1F784, 0x02981, 0x025CF, 0x025CB, 0x1F785, 0x1F787, 0x1F789, 0x02299, 0x029BF, 0x1F78C, 
  0x1F78D, 0x025FE, 0x025A0, 0x025A1, 0x1F791, 0x1F792, 0x1F793, 0x1F794, 0x025A3, 0x1F795, 0x1F796, 0x1F797, 0x1F798, 0x02B29, 0x02B25, 0x025C7, 
  0x1F79A, 0x025C8, 0x1F79B, 0x1F79C, 0x1F79D, 0x1F79E, 0x02B2A, 0x02B27, 0x025CA, 0x1F7A0, 0x025D6, 0x025D7, 0x02BCA, 0x02BCB, 0x02BC0, 0x02BC1, 
  0x02B1F, 0x02BC2, 0x02B23, 0x02B22, 0x02BC3, 0x02BC4, 0x1F7A1, 0x1F7A2, 0x1F7A3, 0x1F7A4, 0x1F7A5, 0x1F7A6, 0x1F7A7, 0x1F7A8, 0x1F7A9, 0x1F7AA, 
  0x1F7AB, 0x1F7AC, 0x1F7AD, 0x1F7AE, 0x1F7AF, 0x1F7B0, 0x1F7B1, 0x1F7B2, 0x1F7B3, 0x1F7B4, 0x1F7B5, 0x1F7B6, 0x1F7B7, 0x1F7B8, 0x1F7B9, 0x1F7BA, 
  0x1F7BB, 0x1F7BC, 0x1F7BD, 0x1F7BE, 0x1F7BF, 0x1F7C0, 0x1F7C2, 0x1F7C4, 0x1F7C6, 0x1F7C9, 0x1F7CA, 0x02736, 0x1F7CC, 0x1F7CE, 0x1F7D0, 0x1F7D2, 
  0x02739, 0x1F7C3, 0x1F7C7, 0x0272F, 0x1F7CD, 0x1F7D4, 0x02BCC, 0x02BCD, 0x0203B, 0x02042, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0},
    { 0x0, 0x02B60, 0x02B62, 0x02B61, 0x02B63, 0x02B66, 0x02B67, 0x02B69, 0x02B68, 0x02B70, 0x02B72, 0x02B71, 0x02B73, 0x02B76, 0x02B78, 0x02B7B, 
  0x02B7D, 0x02B64, 0x02B65, 0x02B6A, 0x02B6C, 0x02B6B, 0x02B6D, 0x02B4D, 0x02BA0, 0x02BA1, 0x02BA2, 0x02BA3, 0x02BA4, 0x02BA5, 0x02BA6, 0x02BA7, 
  0x02B90, 0x02B91, 0x02B92, 0x02B93, 0x02B80, 0x02B83, 0x02B7E, 0x02B7F, 0x02B84, 0x02B86, 0x02B85, 0x02B87, 0x02B8F, 0x02B8D, 0x02B8E, 0x02B8C, 
  0x02B6E, 0x02B6F, 0x0238B, 0x02324, 0x02303, 0x02325, 0x02423, 0x0237D, 0x021EA, 0x02BB8, 0x1F8A0, 0x1F8A1, 0x1F8A2, 0x1F8A3, 0x1F8A4, 0x1F8A5, 
  0x1F8A6, 0x1F8A7, 0x1F8A8, 0x1F8A9, 0x1F8AA, 0x1F8AB, 0x1F850, 0x1F852, 0x1F851, 0x1F853, 0x1F854, 0x1F855, 0x1F857, 0x1F856, 0x1F858, 0x1F859, 
  0x025B2, 0x025BC, 0x025B3, 0x025BD, 0x025C0, 0x025B6, 0x025C1, 0x025B7, 0x025E3, 0x025E2, 0x025E4, 0x025E5, 0x1F780, 0x1F782, 0x1F781, 0x0, 
  0x1F783, 0x02BC5, 0x02BC6, 0x02BC7, 0x02BC8, 0x02B9C, 0x02B9E, 0x02B9D, 0x02B9F, 0x1F810, 0x1F812, 0x1F811, 0x1F813, 0x1F814, 0x1F816, 0x1F815, 
  0x1F817, 0x1F818, 0x1F81A, 0x1F819, 0x1F81B, 0x1F81C, 0x1F81E, 0x1F81D, 0x1F81F, 0x1F800, 0x1F802, 0x1F801, 0x1F803, 0x1F804, 0x1F806, 0x1F805, 
  0x1F807, 0x1F808, 0x1F80A, 0x1F809, 0x1F80B, 0x1F820, 0x1F822, 0x1F824, 0x1F826, 0x1F828, 0x1F82A, 0x1F82C, 0x1F89C, 0x1F89D, 0x1F89E, 0x1F89F, 
  0x1F82E, 0x1F830, 0x1F832, 0x1F834, 0x1F836, 0x1F838, 0x1F83A, 0x1F839, 0x1F83B, 0x1F898, 0x1F89A, 0x1F899, 0x1F89B, 0x1F83C, 0x1F83E, 0x1F83D, 
  0x1F83F, 0x1F840, 0x1F842, 0x1F841, 0x1F843, 0x1F844, 0x1F846, 0x1F845, 0x1F847, 0x02BA8, 0x02BA9, 0x02BAA, 0x02BAB, 0x02BAC, 0x02BAD, 0x02BAE, 
  0x02BAF, 0x1F860, 0x1F862, 0x1F861, 0x1F863, 0x1F864, 0x1F865, 0x1F867, 0x1F866, 0x1F870, 0x1F872, 0x1F871, 0x1F873, 0x1F874, 0x1F875, 0x1F877, 
  0x1F876, 0x1F880, 0x1F882, 0x1F881, 0x1F883, 0x1F884, 0x1F885, 0x1F887, 0x1F886, 0x1F890, 0x1F892, 0x1F891, 0x1F893, 0x1F894, 0x1F896, 0x1F895, 
  0x1F897, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0}};
// See WikiPedia, https://learn.microsoft.com/en-us/windows/win32/intl/code-page-identifiers and https://www.aivosto.com/articles/charsets-codepages.html
  // Variants of 866 (✔=with shortcut): Lithuanian 1119, Ukrainian 1125 (€→848✔), Belarusian 1131✔ (€→849) // https://en.wikipedia.org/wiki/Code_page_866
	    int cyrcps[10] = {20866/*878=KOI-8r*/, 10007/*MacCyrillic*/, 21866/*1168=KOI8-U*/, 1131, 848, /*5*/ 1251, 866, 872, /*8*/ 855, /*9 → iso8859-5*/ 28595 }; // 855+€=872✔  866+€=808 not under Windows???
	    WCHAR ukr_s = 0xf2, ukr[] = {0x0490, 0x0491, 0x0404, 0x0454, 0x0406, 0x0456, 0x0407, 0x0457, 0x00F7, 0x00B1},
	    	  bel_s = 0xf8, bel[] = {0x0406, 0x0456, 0x00B7, 0x00A4, 0x0490, 0x0491, 0x2219},
	    	  lit_s = 0xb5, lit[] = {0x0104, 0x010C, 0x0118, 0x0116, 0, 0, 0, 0, 0x012E, 0x0160, 0, 0, 0, 0, 0, 0, 0, 0x0172, 0x016A,
					 0, 0, 0, 0, 0, 0, 0, 0x017D, 0x0105, 0x010D, 0x0119, 0x0117, 0x012F, 0x0161, 0x0173, 0x016B, 0x017E},
		  lit2_s = 0xF4, lit2[] = {0x201E, 0x201C};

	    switch (flag) {	// Extra Cyrillic support (real work for auto-generation done later)
	      case 872:  case 878:  case 808:  case 848:  case 1125:  case 849:  case 1131:  case 1119:  case 1168:   // Autogenerated below
	      case 37:		// Honest small-ordinal codepage (it is 0x25, but we do not synthesize 25)
	        break;
	      default:
                if (16 == pst->factor) {
                    if (iflag >= 0x100 && !IsValidCodePage(flag))
                        flag = deHex(flag), prtW(msg->hwnd, L"       !IsValidCodePage (were trying in hex, would retry in decimal)\r\n");
                    if (flag <= 0x99)			// Shortcuts are only allowed in decimal
                        flag = deHex(flag);
                }
	    }
            switch (flag/10) {
              case 1:	flag += 10000 - 10;			   break;	// 10029 treated later
              case 4:	if (cyrcps[flag%10]) flag = cyrcps[flag%10];   do_ctrl = (flag==1251);   break;
              case 5:	flag +=  1250 - 50;  do_ctrl = 1;	   break;
              case 6:	if (flag >= 67)			// calculate the 8859-part of Latin no. x alphabet.
                            flag += 13 - 7;
                        else if (flag >= 65)
                            flag += 9 - 5;
                        flag += 28590 - 60;  do_ctrl = 1;	   break;
              case 7:	flag += 57000 - 70; if0 = 10;		   break;	// ISCII;  57011 treated later
              case 8:	flag +=   860 - 80;			   break;	// 857, 858 done later
              case 9:	flag += 28590 - 90;  do_ctrl = 1; if0=10;  break;	// ISO-8859-x with x=1–10
             }
             if (!(flag%10))
                 flag += if0;
	     switch (flag) {		// 2 and 3 are the current MAC cp and the current thread’s OEM cp (keep them)
	      case 0:		flag = CP_OEMCP;  break;	// 1 (exchange 1 and 0)
	      case 1:		flag = CP_ACP;    break;	// 0 (exchange 1 and 0)
	      case 4:		flag =  437;	  break;	// Shorten these 3
	      case 5:		flag = 1252;	  do_ctrl = 1;	break;	// at 5,6,7,9 the “control” 0x21 codepoints are undef
	      case 8:		flag =  850;	  break;
	      case 20: case 21: case 22: case 23:  case 6: case 7: case 9:
	      			do_ctrl = 1;  if (flag < 9) flag += 20-6;  break;	// “Font” encodings
	      case 857+10:  case 858+10:  flag -= 10; break;
	      case 10009:	flag += 20;	  break;	// 10029 = Mac Latin-2 
	      case 57011-10:	flag += 10;	  break;
// done above:	      case 25:		flag = 37;	  break;	// back-convert 037 entered in hex (undo deHex())
	      		// Extra Cyrillic support
	      case 808:		do_euro = 0xCF; flag = 866;  break;
	      case 872:		do_euro = 0xCF; flag = 855;  break;
	      case 878:		flag = 20866;     break;	// KOI-8r
	      case 1168:	flag = 21866;     break;	// KOI-8u
	      case 848:		do_euro = 0xFD; 	// Fall through
	      case 1125:	patch = ukr;  patch_strt = ukr_s;  patch_len = ARRAY_LENGTH(ukr);  flag = 866;  break;
	      case 849:		do_euro = 0xFB; 	// Fall through
	      case 1131:	patch = bel;  patch_strt = bel_s;  patch_len = ARRAY_LENGTH(bel);  flag = 866;  break;
	      case 1119:	if ((BYTE)b < lit2_s) {
				    patch = lit;  patch_strt = lit_s;  patch_len = ARRAY_LENGTH(lit);
				} else {
				    patch = lit2;  patch_strt = lit2_s;  patch_len = ARRAY_LENGTH(lit2);
				}
				flag = 866;       break;
	    }
	    if (b && (BYTE)b == do_euro)
	        unicodeChar = 0x20ac;		// Euro €
	    else if (patch && ((BYTE)b >= patch_strt) && ((BYTE)b < patch_strt + patch_len))
	        unicodeChar = patch[(BYTE)b - patch_strt];

	    if (unicodeChar)
	        (void)0;
	    else if (do_ctrl && (((BYTE)b) <= 0x20 || 0x7f == b)) // Alas: there does not seem to be symbols for 0x80..0x9f
	        unicodeChar = ((0x7f == b) ? 0x21 : (BYTE)b) + 0x2400;
            else if (9 == flag) {			// “Symbol-font” encoding
                int off = (((BYTE)b) & 0x7f) - 0x20;

                if (off < 0 || !(out = smb[((BYTE)b) >> 7][off]))
                    prtW(msg->hwnd, L"       ??? Not in symb\r\n");
            } else if (flag >= 20 && flag <= 23) {	// “Font” encodings 
                int off = ((BYTE)b) - 0x20;

                if (off < 0 || !(out = wingdings[flag-6][off]))
                    prtW(msg->hwnd, ((flag == 6) ? L"       ??? Not in webdings\r\n" : L"       ??? Not in wingdings\r\n"));
            } else if (!MultiByteToWideChar(flag, MB_USEGLYPHCHARS, &b, 1, &unicodeChar, 1))            // Convert the OEM character to Unicode
                prtW(msg->hwnd, L"       MultiByteToWideChar() failed\r\n");
            k = (out ? out : unicodeChar);		// How to recognize “real '\0'” ???
//                prtW(msg->hwnd, L"  MultiByteToWideChar\r\n");	//
        } else {
            if (16 == pst->factor) {			// Hex, non-legacy
                if (k >= 0xF0808080)			// UTF-8 4-byte
                    k = (((k>>24) - 0xF0)<<18) + (((k&0xFF0000)-0x800000)>>4) + (((k&0xFF00)-0x8000)>>2) + (k&0xff) - 0x80;
                else if (k >= 0xd800dc00)		// two UTF+16 surrogates
                    k = fromSURR(k>>16, k&0xffff);
                else if (k >= 0xE08080)			// UTF-8 3-byte
                    k = (((k>>16) - 0xE0)<<12) + (((k&0xFF00)-0x8000)>>2) + (k&0xff) - 0x80;	// ((((k>>8)&0xFF)-0x80)<<6)
                else if (k >= 0xC08000 && !(k&0xFF))	// UTF-8 2-byte followed by 00
                    k = (((k>>16) - 0xC0)<<6) + ((k>>8)&0xFF)-0x80;
            } else {	// Surrogate pairs are about 5.5–5.6 billions > 1<<32; wraps around to 1.2347–1.3371 billions
                unsigned int kk = k - 0xd800UL * 100000UL - 0xdc00;	// Offset w.r.t. start-of-surrogate-pairs, possibly with wraparound
                unsigned int k8 = k - (0xf0UL*1000000000UL+0x80*1001001);   // Offset w.r.t. start-of-4-UTF-8, possibly with wraparound
                //       “Saved by the bell” — with a very near miss:             Consider X = “4byte UTF-8” = kkk.lll.mmm.nnn.
              	// Then (X mod 2^32)/10^9 is in [3.9049, 3.96899] or [.6099, .6740] + ℕ, or [.31499, .3790] + ℕ
               	//   and [1.2347, 1.3371] intersects [1.314992256, 1.379056320].  This intersection mod 2^32 turns out to correspond
               	//   to an absolute difference of 56*2^32; so look at possible kkk.lll.mmm.nnn - 56*2^32 with kkk=0xf6 and
               	//   lll,mmm,nnn∈[0x80,0xBF].  Since 56*2^32 mod 10^6 = 168576, this means that the thousands in the difference are
               	//   in [959, 999] or in [0, 23].  So the last 5 digits are in [59000,999999] or in [0,23999] — which do not
               	//   intersect the 2nd-word-surrogates in [0xdc00,0xdfff] = [56320, 57343].  (Below: x mod 2b < 2c ⇔ x/2 mod b < c)
                if (kk < 0x400*100001 && (kk%100000) < 0x400)	 // Need the second check to avoi collisions: “this bell saves us”
                    k = ((kk/100000)<<10) + kk%100000 + 0x10000;	// detect k*10^9 + small 0≤k≤7, w/o small false positives:
                else if ((k8 % 1000000000) < 0x40*1001001)	 // UTF-8 4-byte; offset has no wraparound in unsigned int
                    k = ((k8/1000000000)<<18) + ((k8/1000000%1000)<<12) + ((k8/1000%1000)<<6) + k8%1000;
                else if (((k8/2 + 0x80000000) % 500000000) < 0x20*1001001) // Likewise + one wraparound; so add 2^32 mod 10^9
                    k = (((k8/2 + 0x80000000)/500000000)<<18) + (((k8/2 + 0x80000000)/500000%1000)<<12)
                        + (((k8/2 + 0x80000000)/500%1000)<<6) + (k8%1000 + 2*(0x80000000%1000))%1000;
                else if (k >= 224128128)			 // UTF-8 3-byte (now we are handling only “small” numbers!)
                    k = (((k/1000000) - 0xE0)<<12) + ((((k/1000)%1000)-0x80)<<6) + (k%1000)-0x80;
                else if (k >=  19212800 && !(k%100))		 // UTF-8 2-byte followed by 00
                    k = (((k/100000) - 0xC0)<<6) + ((k/100)%1000) - 0x80;
            }
            k %= 0x110000;				// Safety net
        }
        if (k >= 0x10000) {
            PostMessageW(msg->hwnd, WM_CHAR, toSURR1(k), msg->lParam | FAKE_KEYSTROKE);
            k =                              toSURR2(k);
        }
        PostMessageW(msg->hwnd, WM_CHAR, k, msg->lParam & ~FAKE_KEYSTROKE);
        return 0;
    }

    if (  (!(flags & (1<<pTMf_pass_keyup)) && (msg->message == WM_SYSKEYUP || msg->message == WM_KEYUP))	// No need to process key-ups after Alt-Numpad is processed
       || (!(flags & (1<<pTMf_pass_std_mods))   // We MUST not pass MENU keydown to TranslateMessage() — we either did all the
           && ((LOWORD(msg->wParam) >= VK_SHIFT && LOWORD(msg->wParam) <= VK_MENU) // related work already above
	       || LOWORD(msg->wParam) == VK_LWIN || LOWORD(msg->wParam) == VK_RWIN))  ) // or we cannot predict the results
        return 0;						// Win should be conditional???  See Emacs?

    // Detect extra-effort only on the keys with only lCtrl, rMenu out of all Ctrl/Menu/Win  (??? Should we fallback if ¬∃ binding?)
    if (!(flags & (1<<pTMf_ignore_lCtrl)) && kbdState.lCtrl == lCtrl_real
        && (ks[VK_RMENU] & 0x80) && cntDups[1] + cntDups[2] + cntDups[3] == 2) { // User put in special effort to force Ctrl with
        prtW(msg->hwnd, L"   Extra effort lCtrl on AltGr detected\r\n");
        return 0;						// When exactly do we misdiagnose this (in any direction)???
    }

//    if (LOWORD(msg->wParam) == 'A')
//        prtW(msg->hwnd, L"  I can see 'A' pre-modifiers\r\n");
    for (int off = 0; off < pst->active_modk_c; off++) {		// No action if it is a known active modifier key
        if (!(flags & (1<<pTMf_pass_found_mods)) && pst->active_modks[off] == LOWORD(msg->wParam))
            return 0;
    }
//    if (LOWORD(msg->wParam) == 'A')
//        prtW(msg->hwnd, L"  I can see 'A' post-modifiers\r\n");
                    
    // scancode is used for recognition of Alt-Numpad input; For non-destructive call; see (this and around): https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#The-bullet-proof-method
    //    Hence with Alt-NUMPAD input disabled below by 0x01 present, calculating the scancode is most probably an overkill ???
    UINT scancode = ((msg->lParam & 0xFF0000) >> 16) + ((msg->lParam & 0x1000000) ? (KBDEXT): 0) + KBDBREAK;	// Pretend it is KeyUp
    int len = ToUnicode(msg->wParam, scancode, ks, out, ARRAY_LENGTH(out), 0x01|0x02);	// Or use NULL for hkl in the “Ex” version

    if (1 == len && !(len = ctrlLen(len, out, /* ctrlDown */ cntDups[1])))	// 0 if it is legacy-delivered-Ctrl-char
        ctrlCh[0] = ctrlCh[1] = 0x40 + out[0];	// ctrlCh[0]: at start; ctrlCh[1]: the first seen during a chain of “downgrades”
    if (!len && !ctrlCh[0] && !cntStd) {		// ??? Should check application-special modifiers too
        prtW(msg->hwnd, L"     Bindable, but no standard modifiers (skipping report)\r\n");
        return 1;				// An optimization
    } else if (!len) {
        ckMatch = 0;		// Try to emultate KBDALT-stripping, switched off with 0x01 (and also try to find the base with other modifiers)
        vkStrt = VK_LWIN;	// Start by removing Win, Menu, then Ctrl, then Shift (, then Win) (the order not thought-out yet ???)
        vkEnd  = VK_RWIN;
    }

    if (len || ctrlCh[0])				// len == -1 is OK
        prtW_gotUniString(msg->hwnd, buffer, ARRAY_LENGTH(buffer), out, ctrlCh[0] ? 1 : len, ARRAY_LENGTH(out), "", prtW);

    WCHAR out1[512]; // The legacy layout may return up to 255 codepoints; but be safe: https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#Keyboard-input-on-Windows,-Part-II:-The-semantic-of-ToUnicode()
    BYTE strip[256], cntStrip = 0, k1, k2, try_more = 1;

    // When the state KLLF_ALTGR is unknown (==-1) it seems to be safer to insert a char than trigger an action.
    //    (??? Should we fallback if ¬∃ binding?)
    if (len && !(flags & ((1<<pTMf_ignore_lCtrl)|(1<<pTMf_ignore_CtrlAlt))) && (kbdState.is_KLLFA > 0) 	// Shift (not checked), Ctrl, Alt, Win:
        && 1 == cntDups[1] && 1 == cntDups[2] && !cntDups[3] && !((ks[VK_LCONTROL] & 0x80) && (ks[VK_RMENU] & 0x80))
        && (!(flags & (1<<pTMf_only_lCtrllAlt)) || ((ks[VK_LCONTROL] & 0x80) && (ks[VK_LMENU] & 0x80)))) {
    // See https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#Can-an-application-on-Windows-accept-keyboard-events?-Part-IV:-application-specific-modifiers
        int k[4];

        for (int i=0; i < 4; i++)	// All handed controls, all handed menus
            k[i] = ks[VK_LCONTROL+i],  ks[VK_LCONTROL+i] = 0;
        ks[VK_LCONTROL] = ks[VK_RMENU] = 0x80;		// Check what happens if we replace Ctrl+Alt by AltGr
        int len1 = ToUnicode(msg->wParam, scancode, ks, out1, ARRAY_LENGTH(out1), 0x01|0x02);	// Or use NULL for hkl in the “Ex” version

        // No need to check for the delivered ctrl-chars separately: the same ctrlDown
        if (len1 == len && 0 == memcmp(out, out1, len*sizeof(wchar_t))) {	// Identical results; simpler not used ⇒ intent = trigger binding
//            swprintf(buffer, ARRAY_LENGTH(buffer), L"     Ctrl-Alt (\xAC" L"AltGr) \x2261 AltGr detected: %d vs %d codepoints; <%ls> vs <%ls>\r\n", len, len1, out, out1);
            prtW(msg->hwnd, L"     Ctrl-Alt (\xAC" L"AltGr) \x2261 AltGr detected");
            return 0;
        }
        for (int i=0; i < 4; i++)
            ks[VK_LCONTROL+i] = k[i];
    }

#define VK_handed_min         0xA0	// LSHIFT
#define VK_handed_max         0xA5	// RMENU

    int len0 = len;	// If carries chars, try to find “passive modifiers” which do not change the chars; 
    			// otherwise try to find a combination which delivers ctrl or chars, removing mods to strp
    while (try_more) {		// https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#The-bullet-proof-method
        try_more = 0;
        for (int vk = vkStrt; vk <= vkEnd; vk++) {
            if (VK_SHIFT == vk || VK_MENU == vk || VK_CONTROL == vk)	// Skip synthetic VK's
                continue;				// In fact, they could have been fed by SendInput.  Need to treat! ???
            if (kbdState.is_KLLFA && ks[VK_RMENU] & 0x80 && VK_LCONTROL == vk)	// Same for RMENU???  Do on an extra pass???  Do not check lCtrl when rAlt is down (Allow kbdState.is_KLLFA to be unknown)
                continue;	// See the first special-case in https://metacpan.org/dist/UI-KeyboardLayout/view/lib/UI/KeyboardLayout.pm#The-bullet-proof-method
            if (ks[vk] & 0x80) {	// pressed; try to understand what happens without this key as a modifier
// swprintf(buffer, ARRAY_LENGTH(buffer), L"        checking VK=0x%02x\r\n", vk);
// prtW(msg->hwnd, buffer);
                k1 = ks[vk];
                ks[vk] &= 0x01;		// Keep the toggle state
                int vk2 = 0, handed = 0;
                if (  vk >= VK_handed_min && vk <= VK_handed_max && ((handed = 1))	// set!
                      && !(ks[1 - (vk&0x01) + (vk&~0x01)] & 0x80)  ) {  // Keep the synthesized VK's consistent
                    vk2 = ((vk - VK_handed_min) >> 1) + VK_SHIFT;	// Are in the same order as the pairs
                    k2 = ks[vk2];
                    ks[vk2] &= 0x01;	// Keep the toggle state, just in case
                }
                int len1 = ToUnicode(msg->wParam, scancode, ks,		// Or use NULL for hkl in the “Ex” version
                		     ckMatch ? out1 : out, ckMatch ? ARRAY_LENGTH(out1) : ARRAY_LENGTH(out), 0x01|0x02);
//                if (1 == len1 && !ckMatch && !(len1 = ctrlLen(len1, out, /* ctrlDown */ (ks[VK_CONTROL] & 0x80)))) { // 0 if it is legacy-delivered-Ctrl-char
//                    if (!ctrlCh[0])
//                        ctrlCh[0] = 0x40 + out[0];
//		}

		// If know which combination produces non-control output, look for matches, and mark them as “passive”
                if (ckMatch && len1 == len && 0 == memcmp(out, out1, abs(len)*sizeof(wchar_t))) {   // Identical results; found a passive modifier
                    strip[cntStrip++] = vk;
                    try_more = 1;
                    break;		// Do not restore ks
                } else if (!ckMatch && len1) {   // Has a ctrl/string binding, with fewer modifiers
                // If all known combinations produce nothing or ctrl, remove indiscriminantly.  Here found either control or “real” output.  Need to mark somehow???
                    if (1 == len1 && !(len = ctrlLen(len1, out, /* ctrlDown */ (ks[VK_CONTROL] & 0x80)))) { // 0 if it is legacy-delivered-Ctrl-char
		        ctrlCh[2] = 0x40 + out[0];	// The latest seen (e.g., going to be ^H for BackSpace)
                        if (!ctrlCh[1])
		            ctrlCh[1] = ctrlCh[2];	// The first seen (^? for BackSpace)
		    } else {
		        len = len1;
//                        ckMatch = 1;	// What for do we look for passive modifiers???
                        try_more = -1;	// Finish immediately
		    }
		    char bb[30];
		    snprintf(bb, sizeof(bb), vk2 ? "Reducing 0x%02X(0x%02X): " : "Reducing 0x%02X: ", vk, vk2);
		    prtW_gotUniString(msg->hwnd, buffer, ARRAY_LENGTH(buffer), out, len1, ARRAY_LENGTH(out), bb, prtW);	// len must be non-0; -1 is OK
		    strip[cntStrip++] = vk;
                    break;		// Do not restore ks
                } else if (!ckMatch) {  // Remove anyway
		    strip[cntStrip++] = vk;
                    break;		// Do not restore ks;  continue, trying to find passive modifiers
		} else if (len && !handed && vk != VK_LWIN && vk != VK_RWIN && pst->active_modk_c < sizeof(pst->active_modks)) {	// Store an active modifier for future unless known
		    int new = 1;
		    for (int off = 0; off < pst->active_modk_c; off++) {
                        if (pst->active_modks[off] == vk) {
                            new = 0;
                            break;
                        }
                    }
                    if (new) {
		        pst->active_modks[pst->active_modk_c++] = vk;
			swprintf(buffer, ARRAY_LENGTH(buffer), L"     New active mod-VK 0x%02x found: len=%d 1st=%04x; now %d\r\n", vk, len1, out1[0], pst->active_modk_c);
		        prtW(msg->hwnd, buffer);
		    }
		}
                ks[vk] = k1;
                if (vk2)
                    ks[vk2] = k2;
            }
        }
        if (!try_more && vkStrt > 1) {
            try_more = 1;
            switch (vkStrt) {
              case VK_LWIN:       vkStrt = VK_LMENU;    vkEnd = VK_RMENU;  break; // Either this one, or LSHIFT should be disabled
              case VK_LMENU:      vkStrt = VK_LCONTROL;                    break;
              case VK_LCONTROL:   vkStrt = VK_LSHIFT;                      break;
//              case VK_LSHIFT:     vkStrt = VK_LWIN;     vkEnd = VK_RWIN;   break;
              default:
                if (ckMatch) {
                    vkStrt = 1;           vkEnd = 0xFF;	// Now check all (the rest)
                } else
                    try_more = 0;
            }
        }
    }
    if (1 || cntStrip) {			// As a (temporary???) proxy for returning the info to the caller, emit the report
      char ss[256*3] = {0};
      int wr = 0, ctrl = 0;

      for (int off = 0; off < cntStrip; off++)		// No action if it is a known active modifier key
          snprintf(ss+3*wr, sizeof(ss) - 3*wr, "%02x ", strip[wr]), wr++;
      ss[3*wr - 1] = 0;
      if (!len0) {
         int l = len;
         if (len >= ARRAY_LENGTH(out))
             l--;
         out[l] = 0;
         if (!l && (ctrl = ctrlCh[1])) {
           out[0] = L'^';
           out[1] = (0x40 + 0x7f == ctrlCh[1]) ? L'?' : ctrlCh[1];
           out[2] = 0;
         }
      }
      swprintf(buffer, ARRAY_LENGTH(buffer), L"     %d %s modifiers found: %s%s%ls%ls%ls\r\n",
      	       cntStrip, len0 ? "passive" : "stripped", ss,
      	       len0 ? "" : " base=", (len0 || ctrl) ? L"" : L"\x27e8", len0 ? L"" : out, (len0 || ctrl) ? L"" : L"\x27e9"); // ⟨⟩
      prtW(msg->hwnd, buffer);
    }

    if (ctrlCh[0] && (flags & (1<<pTMf_deliverCtrlCh))) {
        PostMessageW(msg->hwnd, msg->message == WM_SYSKEYDOWN ? WM_SYSCHAR : WM_CHAR, ctrlCh[0] - 0x40, msg->lParam & ~FAKE_KEYSTROKE);
        return 0;
    }

    return len0 != 0 || (ctrlCh[0] && !(flags & (1<<pTMf_eatCtrlCh)));
}

DWORD ErrorShowW(HWND hwnd, wchar_t *Mess)	// hwnd = NULL allowed
{     // Show the system error message for the last-error code; based on https://learn.microsoft.com/en-us/windows/win32/Debug/retrieving-the-last-error-code
    wchar_t *lpMsgBuf;
    wchar_t *lpDisplayBuf;
    DWORD dw = GetLastError();
    int l;

    FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&lpMsgBuf,
        0, NULL );

    // Display the error message and exit the process

    lpDisplayBuf = (wchar_t *)LocalAlloc(LMEM_ZEROINIT, ((l = wcslen(lpMsgBuf) + wcslen(Mess) + 40)) * sizeof(wchar_t));
    swprintf(lpDisplayBuf, l, L"%lserror %d: %ls", Mess, dw, lpMsgBuf);
    MessageBoxW(hwnd, lpDisplayBuf, L"API call Error", MB_ICONEXCLAMATION | MB_OK); 

    LocalFree((LPVOID)lpMsgBuf);
    LocalFree((LPVOID)lpDisplayBuf);
    return dw;
}

void WM_chr_Dump(wchar_t* buffer, int length, int vk, LPARAM lParam, int isSYS, wchar_t *prefx)
{    // Extract the bitfields from lParam
//    unsigned repeatCount = lParam & 0xFFFF;
    unsigned scanCode = (lParam >> 16) & 0xFF;
    unsigned extended = (lParam >> 24) & 0x1;
    unsigned reserved = (lParam >> 25) & 0x0F;			// 27 is KF_DLGMODE, 28 KF_MENUMODE
    unsigned goUp = (lParam >> 31) & 0x1;
    unsigned altDown = (KEY_down == Alt_state(vk, lParam, !"before"));	// The simple case
    unsigned altDown_b = Alt_state(vk, lParam, !!"before");		// The harder case
    unsigned ctrlDown = Ctrl_state_withAlt(isSYS ? WM_SYSKEYUP : WM_KEYUP, // UP vs DOWN is not important for this parameter
    					   vk, lParam, !"before", altDown_b, f_Flags & (1<<f_forceSpecKeys));
    const char ctxt_ctrl = (KEY_unknown == ctrlDown ? '?' : (KEY_up == ctrlDown ? '-' : 'C'));  // (altDownMaybe && !(goUp && vk == VK_MENU)) ? (isSYS ? '-' : 'C') : '?');	// Alt going UP is always SYS
    unsigned wasDown = (lParam >> 30) & 0x1;
    const char *fk = (reserved & 0x01 ? " fake" : "");
    const char *oem = (reserved & 0x02 ? " oem(should not happen)" : "");	// should not happen: we are not a console handler
    wchar_t states[256*4+1] = L" [", *curStates = states+2;

    BYTE arr[256], kb_ctrl = 0, kb_lCtrl = 0, kb_rCtrl = 0, kb_alt = 0, kb_rAlt = 0;
    if (GetKeyboardState(arr)) {
	wchar_t id[4];
	wchar_t state[2] = L"\0";

        for(int pass=0; pass<2; pass++) {	// Do it in two steps, first for common modifiers (no spaces needed!), then the rest
          for(int i=0; i<256; i++) {
            int isdown = arr[i] & 0x80, ch = 0, isLong = 0, reportLock = 0;

            state[0] = 0;

            if (!arr[i]) continue;
            switch (i) {		// Start with characters typically used as modifiers
              case VK_SHIFT:
                ch = 0x2475+'S' /* Ⓢ */;
                break;
              case VK_LSHIFT:
                ch = 's';
                break;
              case VK_RSHIFT:
                ch = 'S';
                break;
              case VK_CONTROL:
                ch = 0x2475+'C' /* Ⓒ */;
                if (isdown)
                    kb_ctrl = 1;
                break;
              case VK_LCONTROL:
                ch = 'c';
                if (isdown)
                    kb_lCtrl = 1;
                break;
              case VK_RCONTROL:
                ch = 'C';
                if (isdown)
                    kb_rCtrl = 1;
                break;
              case VK_MENU:
                ch = 0x2475+'A' /* Ⓐ */;
                if (isdown)
                    kb_alt = 1;
                break;
              case VK_LMENU:
                ch = 'a';
                break;
              case VK_RMENU:
                ch = 'A';
                if (isdown)
                    kb_rAlt = 1;
                break;
              case VK_LWIN:
                ch = 'w';
                break;
              case VK_RWIN:
                ch = 'W';
                break;
              case VK_KANA:
                ch = 'K';
                break;
              case VK_CAPITAL:
                ch = 'L';
                reportLock = 1;
                break;
              case VK_SCROLL:
                ch = 0x2195;  // ↕;
                reportLock = 1;
                break;
              case VK_NUMLOCK:
                ch = 'N';
                reportLock = 1;
                break;
              case VK_OEM_8:
                swprintf(id, ARRAY_LENGTH(id), L"%s", "_8");
                break;
              case VK_OEM_AX:
                swprintf(id, ARRAY_LENGTH(id), L"%s", "ax");
                break;
              default:
                isLong = 1;
                if (('A' <= i && 'Z' >= i) || ('0' <= i && '9' >= i))
                    swprintf(id, ARRAY_LENGTH(id), L"=%lc", i);
                else
                    swprintf(id, ARRAY_LENGTH(id), L"%02x", i);
            }
            if (!(isdown || reportLock)) continue;
            if ((arr[i] & 0x1) && reportLock)	// toggled
                state[0] = (!isdown ? 0x2191 /* up↑ */ : 0x2193 /* down↓ */);
            if (ch)
                swprintf(id, ARRAY_LENGTH(id), L"%lc", ch);

            if (pass != isLong)
                continue;
	    swprintf(curStates, ARRAY_LENGTH(states)-(curStates-states),
	    	L"%s%ls%ls", ((isLong && curStates != states + 2) ? " " : ""), id, state);
	    curStates += wcslen(curStates);	// %n does not seem to work
          }
        }
    }
    curStates[0] = L']';
    if (curStates == states+2)
      curStates = L"";
    else
      curStates = states;

    if (LCTRL_DEBUG || kbdState.is_KLLFA) {
        if (ctxt_ctrl == (kb_ctrl ? '-' : 'C'))
            ModK_errors |= (1 << (kb_ctrl ? err_cSys1 : err_cSys0));
        if (!!altDown != !!kb_alt)
            ModK_errors |= (1 << err_aSys);
        if (kbdState.lCtrl > lCtrl_unknown && kbdState.lCtrl < lCtrl_noKLLFA_any
            && (kbdState.lCtrl == lCtrl_up) == kb_lCtrl)
            ModK_errors |= (1 << err_FA_lC);
        if (kbdState.rCtrl > KEY_unknown && (kbdState.rCtrl == KEY_up) == kb_rCtrl)
            ModK_errors |= (1 << err_FA_rC);
        if (kbdState.rAlt > KEY_unknown && (kbdState.rAlt == KEY_up) == kb_rAlt)
            ModK_errors |= (1 << (kb_rAlt ? err_FA_rA : err_FA_rA0));
    }
    if (ignore_accel < 0)			// Do we need to include this into the conditional before ???
        ModK_errors |= (1 << err_accel);
//     Write the bitfields to the buffer
//    swprintf(buffer, length, L"Repeat Count: %u\nScan Code: %u\nExtended: %u\n"
//                             L"Reserved: %u\nContext Code: %u\nPrevious State: %u\n"
//                             L"Transition State: %u\n",
//             repeatCount, scanCode, extended, reserved, altDown, wasDown, goUp);
    const char lC_st[] = "? d1FRs", rC_st[] = "? d", * const kF_st[] = {"?", "!fAGr", "fAGr"}, tA_st[] = "?tdDA-";	// s for “sticky”
    swprintf(buffer, length, L"%ls %sSc=%02x Rsrvd=%u CtrlAlt=%c/%c wasDn=%u goUp=%u%ls%s%s c=%c C=%c t=%c %s%ls%s%s%s%s%s%s%s%s%s%s",
             (prefx? prefx : L""), /*repeatCount,*/ (extended? "" : "  "), scanCode+0xe000*extended,reserved, ctxt_ctrl,
             (altDown? 'A' : '-'), wasDown, goUp, curStates, fk, oem,
             lC_st[!kbdState.prMsgTime ? 0 : 1+ kbdState.lCtrl ], rC_st[!kbdState.prMsgTime ? 0 : 1+kbdState.rCtrl],
             tA_st[!kbdState.prMsgTime ? 0 : 1+kbdState.tapAlt], kF_st[!kbdState.prMsgTime ? 0 : 1+kbdState.is_KLLFA],
             (ModK_errors ? L" \xA1" : L""),	            ((ModK_errors & (1<<err_cSys1)) ? "cS" : ""),
             ((ModK_errors & (1<<err_cSys0)) ? "cS0" : ""), ((ModK_errors & (1<<err_aSys)) ? "aS" : ""),
             ((ModK_errors & (1<<err_FA_lC)) ? "lC" : ""),  ((ModK_errors & (1<<err_FA_rC)) ? "rC" : ""),
             ((ModK_errors & (1<<err_FA_rA)) ? "rA" : ""),  ((ModK_errors & (1<<err_FA_rA0)) ? "rA0" : ""), ((ModK_errors & (1<<err_accel)) ? "aL" : ""),
             ((ModK_errors & (1<<err_accel2)) ? "aL2" : ""), (ModK_errors ? "!" : ""));
}

void
formatMessage(wchar_t *buffer, int buflen, UINT msg, WPARAM wParam, LPARAM lParam)
{
    const char *msg_s;
    const char * const sp17  = "                 ";
    const char * const sp17e = sp17 + 17;
    char msg_buf[20];
    wchar_t extra[256];
    int isSYS = 0;

    if (InSendMessage()) {		// TRUE only if called from ANOTHER thread (does not seem to normally happen)
        (buffer++)[0] = L'\x2192';	// →
        buflen--;
    }
    extra[0] = 0;
    switch(msg)
    {
        case WM_SETFOCUS:	 msg_s = "SETFOCUS";		goto fill_buff_short;
        case WM_KILLFOCUS:	 msg_s = "KILLFOCUS";		goto fill_buff_short;
        case WM_INPUTLANGCHANGE: msg_s = "INPUTLANGCHANGE";	goto fill_buff_short;	// WParam: something like ARABIC_CHARSET
        case WM_INITMENU:	 msg_s = "INITMENU";		goto fill_buff_short;
        case WM_INITMENUPOPUP:	 msg_s = "INITMENUPOPUP";	goto fill_buff_short;
        case WM_UNINITMENUPOPUP: msg_s = "UNINITMENUPOPUP";	goto fill_buff_short;
        case WM_ENTERMENULOOP:	 msg_s = "ENTERMENULOOP";	goto fill_buff_short;
        case WM_EXITMENULOOP:	 msg_s = "EXITMENULOOP";	goto fill_buff_short;
        case WM_EXITSIZEMOVE:	 msg_s = "EXITSIZEMOVE";	goto fill_buff_short;
        case WM_SYSCOMMAND:	 msg_s = "SYSCOMMAND";		goto fill_buff_short;
        case WM_COMMAND:	 msg_s = "COMMAND";		goto fill_buff_short;
        case WM_MENUCOMMAND:	 msg_s = "MENUCOMMAND";		goto fill_buff_short;
        case WM_MENUSELECT:	 msg_s = "MENUSELECT";		goto fill_buff_short;
        case WM_ACTIVATE:	 msg_s = "ACTIVATE";		goto fill_buff_short;
        case WM_ACTIVATEAPP:	 msg_s = "ACTIVATEAPP";		goto fill_buff_short;
        case WM_MENUCHAR:	 msg_s = "MENUCHAR";		goto fill_buff_short;
        case WM_ENTERIDLE:	 msg_s = "ENTERIDLE";		goto fill_buff_short;
        case WM_CANCELMODE:	 msg_s = "CANCELMODE";		goto fill_buff_short;
        case WM_ENABLE:		 msg_s = "ENABLE";		goto fill_buff_short;

        case WM_SYSCHAR:	msg_s = "SYSCHAR";	isSYS = 1; goto fill_buff_char;
        case WM_SYSDEADCHAR:	msg_s = "SYSDEADCHAR";	isSYS = 1; goto fill_buff_char;
        case WM_CHAR:		msg_s = "CHAR";		           goto fill_buff_char;
        case WM_DEADCHAR:	msg_s = "DEADCHAR";	           goto fill_buff_char;
	case WM_UNICHAR:	msg_s = "UNICHAR";	           goto fill_buff_char;
      fill_buff_char:
            WCHAR bb[2] = {LOWORD(wParam), 0};		// Allow for wParam == 0
	    WM_chr_Dump(extra, ARRAY_LENGTH(extra), LOWORD(wParam), lParam, isSYS, NULL);
	    swprintf(buffer, buflen, L"WM_%s:%s <%ls> 0x%04X  0x%08X%ls\r\n",
	    	msg_s, sp17e-(11-strlen(msg_s)), bb, wParam, lParam, extra);
            break;
        case WM_SYSKEYDOWN:	msg_s = "SYSKEYDOWN";	isSYS = 1; goto fill_buff_nonchar;
        case WM_SYSKEYUP:	msg_s = "SYSKEYUP";	isSYS = 1; goto fill_buff_nonchar;
        case WM_KEYDOWN:	msg_s = "KEYDOWN";	           goto fill_buff_nonchar;
        case WM_KEYUP:		msg_s = "KEYUP";	           goto fill_buff_nonchar;
      fill_buff_nonchar:
	    WM_chr_Dump(extra, ARRAY_LENGTH(extra), LOWORD(wParam), lParam, isSYS, NULL);
      fill_buff_short:
            int pad = (16-strlen(msg_s));

            if (pad < 0)
                pad = 0;
	    swprintf(buffer, buflen, L"WM_%s:%s0x%04X  0x%08X%ls\r\n",
	    	msg_s, sp17e - pad, wParam, lParam, extra);
            break;
        default:
            snprintf(msg_buf, sizeof(msg_buf), "0x%04x", msg);	msg_s = msg_buf;	goto fill_buff_short;
    }
}

void logMessageW(HWND hwnd, wchar_t *s) {
    HWND hwndTop = GetAncestor(hwnd, GA_ROOTOWNER), h2 = GetDlgItem(hwndTop, ID_EDIT_BOTTOM);	// Walk up parent/owner chain

    SendMessageW(h2, EM_SETSEL, 0, (LPARAM)-1);			/* select all and place caret at end */
    SendMessageW(h2, EM_SETSEL, (WPARAM)-1, (LPARAM)-1);	/* (WPARAM)-1 means: unselect */
    SendMessageW(h2, EM_REPLACESEL, FALSE /* No undoing */, (LPARAM)s);
}

// Subclass procedure
LRESULT CALLBACK EditProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static wchar_t buffer[256];

    switch(msg) {
	case WM_UNICHAR:
	    if(wParam == UNICODE_NOCHAR)
	    {
	        return TRUE;			// Means: I know how to process this message
	    }
	    else
	    {
	        int ind = 0;
		wchar_t b[3];

	        if (wParam < 0x10000) {
	            b[ind++] = wParam;
	        } else {
	            b[ind++] = toSURR1(wParam);
	            b[ind++] = toSURR2(wParam);
	        }
	        b[ind++] = 0;
	        swprintf(buffer, ARRAY_LENGTH(buffer), L"WM_UNICHAR:     <%ls> 0x%04X  0x%08X\r\n", b, wParam, wParam, lParam);
//	        SendMessageW(hwndEdit2, EM_REPLACESEL, FALSE, (LPARAM)buffer);
	        logMessageW(hwnd, buffer);
// 	        return FALSE;
	    }
	    break;
        case WM_SYSCHAR:   case WM_CHAR:   case WM_SYSDEADCHAR:    case WM_DEADCHAR:
        case WM_SYSKEYDOWN:   case WM_KEYDOWN:    case WM_SYSKEYUP:    case WM_KEYUP:
            goto emit_msg;
        case WM_COMMAND:  case WM_SYSCOMMAND:		// wParam = 0 for dismissed menu started by WM_CONTEXTMENU???
            if (ignore_accel == 1) {	// This “case“ is not needed anymore, with extra temporary subclassing.  Fake accelerator may be triggered
                if (LOWORD(wParam) == ID_ACCEL_FAKE)
                    kbdState.is_KLLFA = 0;
                else
	            logMessageW(hwnd, L"     Unexpected ID of accelerator!!\r\n");
	        if (WM_SYSCOMMAND == msg)
		    logMessageW(hwnd, L"    Accelerator a SYSCOMMAND");
	        swprintf(buffer, ARRAY_LENGTH(buffer), L"   Accelerator received, hence no KLLF_ALTGR\r\n");
	        logMessageW(hwnd, buffer);
                return 0;			// “It was processed.”
            } else if (LOWORD(wParam) == ID_ACCEL_FAKE) {
	        logMessageW(hwnd, L"     Our fake accelerator arrived unexpectedly!!\r\n");
        	ModK_errors |= (1 << err_accel2);
	    }
            // https://learn.microsoft.com/en-us/windows/win32/menurc/wm-syscommand
            else if ((LOWORD(wParam) & 0xFFF0) == SC_KEYMENU && WM_SYSCOMMAND == msg)
                goto emit_msg;	// 0xF100; Seems to be send by (RichEdit???) on Alt-letters
            else {
                char *s = (((LOWORD(wParam) <= 0xf200) && (LOWORD(wParam) >= 0xf000)) ? "SC_-like-" : "");
                char *sys = ((msg == WM_SYSCOMMAND) ? "SYS-" : "");
	        swprintf(buffer, ARRAY_LENGTH(buffer), L"     Unexpected %s%saccelerator!! <%lc> 0x%04x\r\n", s, sys, LOWORD(wParam), LOWORD(wParam));
	        logMessageW(hwnd, buffer);
            }
            break;
          case WM_MENUSELECT:	// So far, the only indication that menu was shown (HIWORD(wParam)==0xFFFF && !lParam) for ignored
          case WM_INITMENU:     case WM_INITMENUPOPUP:   case WM_UNINITMENUPOPUP:   case WM_ENTERMENULOOP:   case WM_EXITMENULOOP:
          case WM_MENUCOMMAND:  case WM_ACTIVATE:        case WM_ACTIVATEAPP:	// Only MENUCOMMAND, MENUCHAR and ENTERIDLE received…
          case WM_MENUCHAR:     case WM_ENTERIDLE: // Should all of these menu-related commands be treated?
          case WM_CANCELMODE:   case WM_ENABLE:   case WM_EXITSIZEMOVE:	// Compare with https://referencesource.microsoft.com/#PresentationCore/Core/CSharp/System/Windows/Interop/HwndKeyboardInputProvider.cs,337
          case WM_KILLFOCUS:    case WM_SETFOCUS:
            KbdState_needs_reset(&kbdState);	// Compare with _partialActive in https://referencesource.microsoft.com/#PresentationCore/Core/CSharp/System/Windows/Interop/HwndKeyboardInputProvider.cs,509
            goto emit_msg;
        case WM_INPUTLANGCHANGE:
            kbdState.is_KLLFA = -1;			// unknown
	    ModK_errors = 0;				// allow to restart testing for other errors
            if (kbdState.lCtrl == lCtrl_noKLLFA_any)	// Sticky state, until reset
                kbdState.lCtrl = lCtrl_unknown;	// Fall through
            p_aNpState->active_modk_c = 0;
            p_aNpState->aNpState = npST_ERROR;
//      default:
	  emit_msg:
	    formatMessage(buffer, ARRAY_LENGTH(buffer), msg, wParam, lParam);
	    logMessageW(hwnd, buffer);
    }
    LRESULT rc = CallWindowProc(OldEditProc, hwnd, msg, wParam, lParam);
//    logMessageW(hwnd, L"++");
    return rc;
}



LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    static wchar_t buffer[256];
    HWND hwndEdit2;

    switch(msg)
    {
        case WM_CREATE:
	    // Create the first edit control
	    HWND hwndEdit1 = CreateWindowExW(0, L"EDIT", NULL,
	        WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_BORDER | ES_MULTILINE | ES_AUTOVSCROLL,
	        0, 0, 0, 0, hwnd, (HMENU)ID_EDIT_TOP, NULL, NULL);

            if(hwndEdit1) {
                // Create the second edit control
                hwndEdit2 = CreateWindowExW(0, L"EDIT", NULL,
                    WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_BORDER | ES_MULTILINE | ES_AUTOVSCROLL,
                    0, 0, 0, 0, hwnd, (HMENU)ID_EDIT_BOTTOM, NULL, NULL);
                if(!hwndEdit2) {
                    ErrorShowW(hwnd, L"Could not create 2nd edit box: ");
                    DestroyWindow(hwndEdit1);
                    goto do_destroy;
                }
	    } else {
	        ErrorShowW(hwnd, L"Could not create 1st edit box: ");
	      do_destroy:
	        PostQuitMessage(100);
		return -1;			// Signal destroying the Window
 	    }

	    // Create a LOGFONT structure and set the font name and size
	    LOGFONTW lf;
	    memset(&lf, 0, sizeof(LOGFONTW));
	    lf.lfHeight = 20;  // height of font
//	    wcscpy(lf.lfFaceName, L"Arial Unicode MS");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, Arial Unicode MS, Symbola, DejaVu Sans Mono Unifont");  // name of font
			// With Symbola exits silently
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, Arial Unicode MS, Symbola");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, Arial Unicode MS, DejaVu Sans Mono Unifont");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Symbol, DejaVu Sans Mono Unifont");  // name of font
	    wcscpy(lf.lfFaceName, L"DejaVu Sans Mono Unifont");  // name of font
//	    wcscpy(lf.lfFaceName, L"Unifont Smooth");  // name of font
//	    wcscpy(lf.lfFaceName, L"Segoe UI Emoji");  // name of font

	    // Create the font and send the WM_SETFONT message
	    hFont = CreateFontIndirectW(&lf);
	    SendMessageW(hwndEdit1, WM_SETFONT, (WPARAM)hFont, MAKELPARAM(TRUE, 0));
	    SendMessageW(hwndEdit2, WM_SETFONT, (WPARAM)hFont, MAKELPARAM(TRUE, 0));
	    SendMessageW(hwndEdit2, EM_SETLIMITTEXT, 20*1000*1000, 0);
	    OldEditProc = (WNDPROC)SetWindowLongPtrW(hwndEdit1, GWLP_WNDPROC, (LONG_PTR)EditProc);
            break;
        case WM_SIZE:
	{
	    // Get the new size of the client area
	    int width = LOWORD(lParam);
	    int height = HIWORD(lParam);

	    // Resize the first edit control to take up the top 1/4 of the client area
	    SetWindowPos(GetDlgItem(hwnd, ID_EDIT_TOP), NULL, 0, 0, width, height / 4, SWP_NOZORDER);

	    // Resize the second edit control to take up the rest of the client area
	    SetWindowPos(GetDlgItem(hwnd, ID_EDIT_BOTTOM), NULL, 0, height / 4, width, 3 * height / 4, SWP_NOZORDER);
	}
            break;
        case WM_DESTROY:
	    // Delete the font
	    if(hFont)
	        DeleteObject(hFont);
            PostQuitMessage(0);
            break;
        case WM_SETFOCUS:
            SetFocus(GetDlgItem(hwnd, ID_EDIT_TOP));	// Fall through
            	// It is the toplevel window to which dialogues are attached https://devblogs.microsoft.com/oldnewthing/20050401-00/?p=35993
        case WM_KILLFOCUS:  // case WM_SETFOCUS:
        case WM_MENUSELECT:	// So far, the only indication that menu was shown (HIWORD(wParam)==0xFFFF && !lParam) for ignored
        case WM_INITMENU:     case WM_INITMENUPOPUP:   case WM_UNINITMENUPOPUP:   case WM_ENTERMENULOOP:   case WM_EXITMENULOOP:
        case WM_MENUCOMMAND:  case WM_ACTIVATE:        case WM_ACTIVATEAPP: // Terminated by MENUCOMMAND + EXITMENULOOP
        case WM_MENUCHAR:     case WM_ENTERIDLE:       case WM_CANCELMODE:   case WM_ENABLE:   case WM_EXITSIZEMOVE:
          KbdState_needs_reset(&kbdState);
          buffer[0] = buffer[1] = L'+';
          formatMessage(buffer+2, ARRAY_LENGTH(buffer)-2, msg, wParam, lParam);
          logMessageW(hwnd, buffer);
          break;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
    LPSTR lpCmdLine, int nCmdShow)
// int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
//    PWSTR pCmdLine, int nCmdShow)
{
    const wchar_t g_szClassName[] = L"Test_keyboard_input_WindowClass";
    WNDCLASSEXW wc;
    HWND hwnd;
    MSG Msg;
//    DWORD prMsgTime = 0;			// Wraps around in 47 days
//    lCtrl_STATE lCtrl_state = lCtrl_unknown;
    struct Alt_NUMPAD_State st = {0, npST_NONE, 0};		// ??? Temporarily: per-thread

    p_aNpState = &st;

    wc.cbSize        = sizeof(WNDCLASSEXW);
    wc.style         = 0;
    wc.lpfnWndProc   = WndProc;
    wc.cbClsExtra    = 0;
    wc.cbWndExtra    = 0;
    wc.hInstance     = hInstance;
    wc.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
    wc.hCursor       = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW+1);
    wc.lpszMenuName  = NULL;
    wc.lpszClassName = g_szClassName;
    wc.hIconSm       = LoadIcon(NULL, IDI_APPLICATION);

    if(!RegisterClassExW(&wc))
    {
        ErrorShowW(NULL, L"Window Registration Failed! ");
        return 0;			// 0: Did not enter message pipe
    }

    hwnd = CreateWindowExW(
        WS_EX_CLIENTEDGE,
        g_szClassName,
        L"Test keyboard input",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, // 720, 450, (is too small)
        NULL, NULL, hInstance, NULL);

    if(hwnd == NULL)
    {
        ErrorShowW(NULL, L"Window Creation Failed! ");
        return 0;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    kbdState.lCtrl = lCtrl_unknown;
    kbdState.tapAlt = kbdState.rAlt = kbdState.rCtrl = KEY_unknown;	//     Do we need to set a hook to go over sent messages?
      // inurl:learn.microsoft.com/en-us/windows/win32/api/winuser nonqueued
    while(GetMessageW(&Msg, NULL, 0, 0) > 0)	// This call, PeekMessage and SendMessage flavors (except SendMessageTimeout with SMTO_BLOCK)
    {						//   would process messages sent from other threads  (Probably default window procedures too.)
        wchar_t b[256];
        int do_MB = 0;

        int do_translate = 1;
        switch (Msg.message) {		// Indicate it was pumped
          case WM_KEYDOWN:      case WM_SYSKEYDOWN:      case WM_KEYUP:        case WM_SYSKEYUP:
          case WM_KILLFOCUS:    case WM_SETFOCUS:
          case WM_MENUSELECT:	// So far, the only indication that menu was shown (HIWORD(wParam)==0xFFFF && !lParam) for ignored
          case WM_INITMENU:     case WM_INITMENUPOPUP:   case WM_UNINITMENUPOPUP:   case WM_ENTERMENULOOP:   case WM_EXITMENULOOP:
          case WM_MENUCOMMAND:  case WM_ACTIVATE:        case WM_ACTIVATEAPP: // Terminated by MENUCOMMAND + EXITMENULOOP
          case WM_MENUCHAR:     case WM_ENTERIDLE:       case WM_CANCELMODE:   case WM_ENABLE:        
	    logMessageW(Msg.hwnd, L"\x2191");	// ↑
        }
	// keyrepeat of AltGr leads to pairs  lCtrl + rAlt with the same timestamp; try to find lCtrl which do not look like this
        if (!(f_Flags & (1<<f_noLCtrlKLLFA)) && (LCTRL_DEBUG || !kbdState.prMsgTime || kbdState.is_KLLFA)) {
            switch (Msg.message) {	// KLLF_ALTGR set, or unknown  The kernel removed the FAKE_KEYSTROKE flag; try to restore
              case WM_KEYDOWN:   case WM_SYSKEYDOWN:   case WM_KEYUP:   case WM_SYSKEYUP:
                char *call_ok = "succeeded";

                switch (update_KBD_state(&kbdState, &st, &Msg, f_Flags)) {
                  case update_lCtrl_messy_F1:
                    call_ok = "failed";			// Fall through
                  case update_lCtrl_messy_F0:
                    WCHAR bb[128];
                    swprintf(bb, ARRAY_LENGTH(bb),
                    	     L"Bug in detection of KLLF_ALTGR: accelerator %s, counts (OK=%d, All=%d) commands exp=%d vs %d!",
                    	     call_ok, ck_KLLFA.cOK, ck_KLLFA.cAll, ck_KLLFA.cmd, ck_KLLFA.cmdR);
                    WM_chr_Dump(b, ARRAY_LENGTH(b), LOWORD(Msg.wParam), Msg.lParam, (Msg.message == WM_SYSKEYDOWN), bb);
                    do_MB = -1;
                    break;
//                  case update_lCtrl_messy_F1:
//                    WM_chr_Dump(b, ARRAY_LENGTH(b), LOWORD(Msg.wParam), Msg.lParam, (Msg.message == WM_SYSKEYDOWN),
//                                L"Bug in detection of KLLF_ALTGR!");
//                    do_MB = -1;
//                    break;
                  case update_lCtrl_Flag1:
                    WM_chr_Dump(b, ARRAY_LENGTH(b), LOWORD(Msg.wParam), Msg.lParam, (Msg.message == WM_SYSKEYDOWN),
                                L"KLLF_ALTGR detected!");
                    do_MB = 1;	// Showing MB now will deliver the processed message too late, confusing our error-checks
		    break;
                  case update_lCtrl_errCreate:		// These two should not happen
                    (void)ErrorShowW(Msg.hwnd, L"Acceleration Table creation Failed: ");
                    break;
                  case update_lCtrl_errDestruct:
                    (void)ErrorShowW(Msg.hwnd, L"Acceleration Table destruction Failed: ");
                }
            }
	}
        switch (Msg.message) {		// May omit these; These are sent, so should be processed in the window procedure anyway
          case WM_KEYDOWN: case WM_SYSKEYDOWN:
            do_translate = preTranslateMessage(&Msg, f_Flags, &st, logMessageW);
            break;
          case WM_KEYUP: case WM_SYSKEYUP:	// Currently preTranslateMessage() does not support key-ups, so ignore them
            preTranslateMessage(&Msg, f_Flags, &st, logMessageW);
            do_translate = 0;
            break;
          case WM_KILLFOCUS:  case WM_SETFOCUS:  	// Usually unreachable: these three are usually sent, not posted
            if (lCtrl_noKLLFA_any == kbdState.lCtrl)	// Sticky state, until reset
                break;
          case WM_INPUTLANGCHANGE:
	        if (kbdState.lCtrl == lCtrl_noKLLFA_any)	// Sticky state, until reset
                    kbdState.lCtrl = lCtrl_unknown;	// Fall through
                kbdState.is_KLLFA = -1;
	        p_aNpState->active_modk_c = 0;
	        p_aNpState->aNpState = npST_ERROR;
        }

//        if (Msg.message == WM_KEYDOWN || Msg.message == WM_SYSKEYDOWN)
//            msg_cnt++;
	if (do_translate)
            TranslateMessage(&Msg);
        DispatchMessageW(&Msg);
        if (do_MB)
            MessageBoxW(NULL, b, do_MB > 0 ? L"Success" : L"npST_ERROR", (do_MB > 0 ? 0 : MB_ICONEXCLAMATION) | MB_OK);
    }
    return Msg.wParam;
}
