#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_DAY_LAST ELM_WIN_DOCK ELM_WIN_MENU */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'D':
    if (memEQ(name, "ELM_WIN_DOCK", 12)) {
    /*                       ^          */
      *iv_return = ELM_WIN_DOCK;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_DAY_LAST", 12)) {
    /*                       ^          */
      *iv_return = ELM_DAY_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "ELM_WIN_MENU", 12)) {
    /*                       ^          */
      *iv_return = ELM_WIN_MENU;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_ICON_FILE ELM_ICON_NONE ELM_LIST_LAST ELM_WIN_BASIC ELM_WIN_COMBO
     ELM_WRAP_CHAR ELM_WRAP_LAST ELM_WRAP_NONE ELM_WRAP_WORD */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "ELM_WRAP_CHAR", 13)) {
    /*                          ^        */
      *iv_return = ELM_WRAP_CHAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "ELM_WIN_COMBO", 13)) {
    /*                          ^        */
      *iv_return = ELM_WIN_COMBO;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_WIN_BASIC", 13)) {
    /*                          ^        */
      *iv_return = ELM_WIN_BASIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_ICON_FILE", 13)) {
    /*                          ^        */
      *iv_return = ELM_ICON_FILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_ICON_NONE", 13)) {
    /*                          ^        */
      *iv_return = ELM_ICON_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WRAP_NONE", 13)) {
    /*                          ^        */
      *iv_return = ELM_WRAP_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_WRAP_WORD", 13)) {
    /*                          ^        */
      *iv_return = ELM_WRAP_WORD;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_LIST_LAST", 13)) {
    /*                          ^        */
      *iv_return = ELM_LIST_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WRAP_LAST", 13)) {
    /*                          ^        */
      *iv_return = ELM_WRAP_LAST;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_DAY_FRIDAY ELM_DAY_MONDAY ELM_DAY_SUNDAY ELM_LIST_LIMIT ELM_WIN_SPLASH
     ELM_WRAP_MIXED */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'L':
    if (memEQ(name, "ELM_LIST_LIMIT", 14)) {
    /*                        ^           */
      *iv_return = ELM_LIST_LIMIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "ELM_WRAP_MIXED", 14)) {
    /*                        ^           */
      *iv_return = ELM_WRAP_MIXED;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_DAY_MONDAY", 14)) {
    /*                        ^           */
      *iv_return = ELM_DAY_MONDAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_WIN_SPLASH", 14)) {
    /*                        ^           */
      *iv_return = ELM_WIN_SPLASH;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_DAY_FRIDAY", 14)) {
    /*                        ^           */
      *iv_return = ELM_DAY_FRIDAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_DAY_SUNDAY", 14)) {
    /*                        ^           */
      *iv_return = ELM_DAY_SUNDAY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_DAY_TUESDAY ELM_GLVIEW_NONE ELM_LIST_EXPAND ELM_LIST_SCROLL
     ELM_POLICY_EXIT ELM_POLICY_LAST ELM_POLICY_QUIT ELM_WIN_DESKTOP
     ELM_WIN_TOOLBAR ELM_WIN_TOOLTIP ELM_WIN_UNKNOWN ELM_WIN_UTILITY */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'E':
    if (memEQ(name, "ELM_LIST_EXPAND", 15)) {
    /*                        ^            */
      *iv_return = ELM_LIST_EXPAND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_DESKTOP", 15)) {
    /*                        ^            */
      *iv_return = ELM_WIN_DESKTOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_WIN_UNKNOWN", 15)) {
    /*                        ^            */
      *iv_return = ELM_WIN_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_WIN_TOOLBAR", 15)) {
    /*                        ^            */
      *iv_return = ELM_WIN_TOOLBAR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_TOOLTIP", 15)) {
    /*                        ^            */
      *iv_return = ELM_WIN_TOOLTIP;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_LIST_SCROLL", 15)) {
    /*                        ^            */
      *iv_return = ELM_LIST_SCROLL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_WIN_UTILITY", 15)) {
    /*                        ^            */
      *iv_return = ELM_WIN_UTILITY;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_DAY_TUESDAY", 15)) {
    /*                        ^            */
      *iv_return = ELM_DAY_TUESDAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "ELM_GLVIEW_NONE", 15)) {
    /*                        ^            */
      *iv_return = ELM_GLVIEW_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "ELM_POLICY_EXIT", 15)) {
    /*                        ^            */
      *iv_return = ELM_POLICY_EXIT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POLICY_LAST", 15)) {
    /*                        ^            */
      *iv_return = ELM_POLICY_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POLICY_QUIT", 15)) {
    /*                        ^            */
      *iv_return = ELM_POLICY_QUIT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_DAY_SATURDAY ELM_DAY_THURSDAY ELM_FLIP_CUBE_UP ELM_FLIP_PAGE_UP
     ELM_GLVIEW_ALPHA ELM_GLVIEW_DEPTH */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "ELM_GLVIEW_ALPHA", 16)) {
    /*                          ^           */
      *iv_return = ELM_GLVIEW_ALPHA;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "ELM_FLIP_CUBE_UP", 16)) {
    /*                          ^           */
      *iv_return = ELM_FLIP_CUBE_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "ELM_GLVIEW_DEPTH", 16)) {
    /*                          ^           */
      *iv_return = ELM_GLVIEW_DEPTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_FLIP_PAGE_UP", 16)) {
    /*                          ^           */
      *iv_return = ELM_FLIP_PAGE_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_DAY_THURSDAY", 16)) {
    /*                          ^           */
      *iv_return = ELM_DAY_THURSDAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_DAY_SATURDAY", 16)) {
    /*                          ^           */
      *iv_return = ELM_DAY_SATURDAY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_DAY_WEDNESDAY ELM_GLVIEW_DIRECT ELM_ICON_STANDARD ELM_LIST_COMPRESS */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'D':
    if (memEQ(name, "ELM_DAY_WEDNESDAY", 17)) {
    /*                   ^                   */
      *iv_return = ELM_DAY_WEDNESDAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_GLVIEW_DIRECT", 17)) {
    /*                   ^                   */
      *iv_return = ELM_GLVIEW_DIRECT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_ICON_STANDARD", 17)) {
    /*                   ^                   */
      *iv_return = ELM_ICON_STANDARD;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_LIST_COMPRESS", 17)) {
    /*                   ^                   */
      *iv_return = ELM_LIST_COMPRESS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_BG_OPTION_LAST ELM_BG_OPTION_TILE ELM_CALENDAR_DAILY
     ELM_FLIP_CUBE_DOWN ELM_FLIP_CUBE_LEFT ELM_FLIP_PAGE_DOWN
     ELM_FLIP_PAGE_LEFT ELM_GLVIEW_DEPTH_8 ELM_GLVIEW_STENCIL
     ELM_IMAGE_ORIENT_0 ELM_WIN_POPUP_MENU */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case '0':
    if (memEQ(name, "ELM_IMAGE_ORIENT_", 17)) {
    /*                                0      */
      *iv_return = ELM_IMAGE_ORIENT_0;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "ELM_GLVIEW_DEPTH_", 17)) {
    /*                                8      */
      *iv_return = ELM_GLVIEW_DEPTH_8;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_BG_OPTION_TIL", 17)) {
    /*                                E      */
      *iv_return = ELM_BG_OPTION_TILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_GLVIEW_STENCI", 17)) {
    /*                                L      */
      *iv_return = ELM_GLVIEW_STENCIL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_FLIP_CUBE_DOW", 17)) {
    /*                                N      */
      *iv_return = ELM_FLIP_CUBE_DOWN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_PAGE_DOW", 17)) {
    /*                                N      */
      *iv_return = ELM_FLIP_PAGE_DOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_BG_OPTION_LAS", 17)) {
    /*                                T      */
      *iv_return = ELM_BG_OPTION_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_CUBE_LEF", 17)) {
    /*                                T      */
      *iv_return = ELM_FLIP_CUBE_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_PAGE_LEF", 17)) {
    /*                                T      */
      *iv_return = ELM_FLIP_PAGE_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_WIN_POPUP_MEN", 17)) {
    /*                                U      */
      *iv_return = ELM_WIN_POPUP_MENU;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "ELM_CALENDAR_DAIL", 17)) {
    /*                                Y      */
      *iv_return = ELM_CALENDAR_DAILY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_BG_OPTION_SCALE ELM_CALENDAR_UNIQUE ELM_CALENDAR_WEEKLY
     ELM_CNP_MODE_MARKUP ELM_FLIP_CROSS_FADE ELM_FLIP_CUBE_RIGHT
     ELM_FLIP_PAGE_RIGHT ELM_GLVIEW_DEPTH_16 ELM_GLVIEW_DEPTH_24
     ELM_GLVIEW_DEPTH_32 ELM_HOVER_AXIS_BOTH ELM_HOVER_AXIS_NONE
     ELM_ICON_LOOKUP_FDO ELM_IMAGE_ORIENT_90 ELM_IMAGE_ROTATE_90
     ELM_POLICY_THROTTLE ELM_WIN_KEYBOARD_IP ELM_WIN_KEYBOARD_ON */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case '1':
    if (memEQ(name, "ELM_GLVIEW_DEPTH_16", 19)) {
    /*                                ^        */
      *iv_return = ELM_GLVIEW_DEPTH_16;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "ELM_GLVIEW_DEPTH_24", 19)) {
    /*                                ^        */
      *iv_return = ELM_GLVIEW_DEPTH_24;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "ELM_GLVIEW_DEPTH_32", 19)) {
    /*                                ^        */
      *iv_return = ELM_GLVIEW_DEPTH_32;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "ELM_IMAGE_ORIENT_90", 19)) {
    /*                                ^        */
      *iv_return = ELM_IMAGE_ORIENT_90;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_IMAGE_ROTATE_90", 19)) {
    /*                                ^        */
      *iv_return = ELM_IMAGE_ROTATE_90;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "ELM_FLIP_CROSS_FADE", 19)) {
    /*                                ^        */
      *iv_return = ELM_FLIP_CROSS_FADE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_ICON_LOOKUP_FDO", 19)) {
    /*                                ^        */
      *iv_return = ELM_ICON_LOOKUP_FDO;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "ELM_FLIP_CUBE_RIGHT", 19)) {
    /*                                ^        */
      *iv_return = ELM_FLIP_CUBE_RIGHT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_PAGE_RIGHT", 19)) {
    /*                                ^        */
      *iv_return = ELM_FLIP_PAGE_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_WIN_KEYBOARD_IP", 19)) {
    /*                                ^        */
      *iv_return = ELM_WIN_KEYBOARD_IP;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_BG_OPTION_SCALE", 19)) {
    /*                                ^        */
      *iv_return = ELM_BG_OPTION_SCALE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_CALENDAR_WEEKLY", 19)) {
    /*                                ^        */
      *iv_return = ELM_CALENDAR_WEEKLY;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POLICY_THROTTLE", 19)) {
    /*                                ^        */
      *iv_return = ELM_POLICY_THROTTLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_HOVER_AXIS_NONE", 19)) {
    /*                                ^        */
      *iv_return = ELM_HOVER_AXIS_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_WIN_KEYBOARD_ON", 19)) {
    /*                                ^        */
      *iv_return = ELM_WIN_KEYBOARD_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_HOVER_AXIS_BOTH", 19)) {
    /*                                ^        */
      *iv_return = ELM_HOVER_AXIS_BOTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_CALENDAR_UNIQUE", 19)) {
    /*                                ^        */
      *iv_return = ELM_CALENDAR_UNIQUE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_CNP_MODE_MARKUP", 19)) {
    /*                                ^        */
      *iv_return = ELM_CNP_MODE_MARKUP;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_ACTIONSLIDER_ALL ELM_BG_OPTION_CENTER ELM_CALENDAR_MONTHLY
     ELM_GENLIST_ITEM_MAX ELM_GLVIEW_STENCIL_1 ELM_GLVIEW_STENCIL_2
     ELM_GLVIEW_STENCIL_4 ELM_GLVIEW_STENCIL_8 ELM_IMAGE_ORIENT_180
     ELM_IMAGE_ORIENT_270 ELM_IMAGE_ROTATE_180 ELM_IMAGE_ROTATE_270
     ELM_PANEL_ORIENT_TOP ELM_POLICY_EXIT_NONE ELM_POLICY_QUIT_NONE
     ELM_POPUP_ORIENT_TOP ELM_WIN_DIALOG_BASIC ELM_WIN_KEYBOARD_HEX
     ELM_WIN_KEYBOARD_OFF ELM_WIN_KEYBOARD_PIN ELM_WIN_KEYBOARD_URL
     ELM_WIN_NOTIFICATION ELM_WIN_SOCKET_IMAGE */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case '0':
    if (memEQ(name, "ELM_IMAGE_ORIENT_18", 19)) {
    /*                                  0      */
      *iv_return = ELM_IMAGE_ORIENT_180;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_IMAGE_ORIENT_27", 19)) {
    /*                                  0      */
      *iv_return = ELM_IMAGE_ORIENT_270;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_IMAGE_ROTATE_18", 19)) {
    /*                                  0      */
      *iv_return = ELM_IMAGE_ROTATE_180;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_IMAGE_ROTATE_27", 19)) {
    /*                                  0      */
      *iv_return = ELM_IMAGE_ROTATE_270;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "ELM_GLVIEW_STENCIL_", 19)) {
    /*                                  1      */
      *iv_return = ELM_GLVIEW_STENCIL_1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "ELM_GLVIEW_STENCIL_", 19)) {
    /*                                  2      */
      *iv_return = ELM_GLVIEW_STENCIL_2;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "ELM_GLVIEW_STENCIL_", 19)) {
    /*                                  4      */
      *iv_return = ELM_GLVIEW_STENCIL_4;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "ELM_GLVIEW_STENCIL_", 19)) {
    /*                                  8      */
      *iv_return = ELM_GLVIEW_STENCIL_8;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ELM_WIN_DIALOG_BASI", 19)) {
    /*                                  C      */
      *iv_return = ELM_WIN_DIALOG_BASIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_POLICY_EXIT_NON", 19)) {
    /*                                  E      */
      *iv_return = ELM_POLICY_EXIT_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POLICY_QUIT_NON", 19)) {
    /*                                  E      */
      *iv_return = ELM_POLICY_QUIT_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_SOCKET_IMAG", 19)) {
    /*                                  E      */
      *iv_return = ELM_WIN_SOCKET_IMAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ELM_WIN_KEYBOARD_OF", 19)) {
    /*                                  F      */
      *iv_return = ELM_WIN_KEYBOARD_OFF;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_ACTIONSLIDER_AL", 19)) {
    /*                                  L      */
      *iv_return = ELM_ACTIONSLIDER_ALL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYBOARD_UR", 19)) {
    /*                                  L      */
      *iv_return = ELM_WIN_KEYBOARD_URL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_WIN_KEYBOARD_PI", 19)) {
    /*                                  N      */
      *iv_return = ELM_WIN_KEYBOARD_PIN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_NOTIFICATIO", 19)) {
    /*                                  N      */
      *iv_return = ELM_WIN_NOTIFICATION;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_PANEL_ORIENT_TO", 19)) {
    /*                                  P      */
      *iv_return = ELM_PANEL_ORIENT_TOP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POPUP_ORIENT_TO", 19)) {
    /*                                  P      */
      *iv_return = ELM_POPUP_ORIENT_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_BG_OPTION_CENTE", 19)) {
    /*                                  R      */
      *iv_return = ELM_BG_OPTION_CENTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "ELM_GENLIST_ITEM_MA", 19)) {
    /*                                  X      */
      *iv_return = ELM_GENLIST_ITEM_MAX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYBOARD_HE", 19)) {
    /*                                  X      */
      *iv_return = ELM_WIN_KEYBOARD_HEX;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "ELM_CALENDAR_MONTHL", 19)) {
    /*                                  Y      */
      *iv_return = ELM_CALENDAR_MONTHLY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_ACTIONSLIDER_LEFT ELM_ACTIONSLIDER_NONE ELM_BG_OPTION_STRETCH
     ELM_CALENDAR_ANNUALLY ELM_CNP_MODE_NO_IMAGE ELM_COLORSELECTOR_ALL
     ELM_FILESELECTOR_GRID ELM_FILESELECTOR_LAST ELM_FILESELECTOR_LIST
     ELM_FLIP_DIRECTION_UP ELM_GENLIST_ITEM_NONE ELM_GENLIST_ITEM_TREE
     ELM_GLVIEW_STENCIL_16 ELM_ICON_LOOKUP_THEME ELM_IMAGE_ORIENT_NONE
     ELM_PANEL_ORIENT_LEFT ELM_POPUP_ORIENT_LAST ELM_POPUP_ORIENT_LEFT
     ELM_WIN_DROPDOWN_MENU ELM_WIN_INLINED_IMAGE ELM_WIN_KEYBOARD_FILE
     ELM_WIN_KEYBOARD_HOST ELM_WIN_KEYBOARD_J2ME */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'D':
    if (memEQ(name, "ELM_WIN_DROPDOWN_MENU", 21)) {
    /*                       ^                   */
      *iv_return = ELM_WIN_DROPDOWN_MENU;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_GLVIEW_STENCIL_16", 21)) {
    /*                       ^                   */
      *iv_return = ELM_GLVIEW_STENCIL_16;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_IMAGE_ORIENT_NONE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_IMAGE_ORIENT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_GENLIST_ITEM_NONE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_GENLIST_ITEM_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_GENLIST_ITEM_TREE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_GENLIST_ITEM_TREE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_INLINED_IMAGE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_WIN_INLINED_IMAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "ELM_WIN_KEYBOARD_FILE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_WIN_KEYBOARD_FILE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYBOARD_HOST", 21)) {
    /*                       ^                   */
      *iv_return = ELM_WIN_KEYBOARD_HOST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYBOARD_J2ME", 21)) {
    /*                       ^                   */
      *iv_return = ELM_WIN_KEYBOARD_J2ME;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_PANEL_ORIENT_LEFT", 21)) {
    /*                       ^                   */
      *iv_return = ELM_PANEL_ORIENT_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "ELM_CNP_MODE_NO_IMAGE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_CNP_MODE_NO_IMAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_CALENDAR_ANNUALLY", 21)) {
    /*                       ^                   */
      *iv_return = ELM_CALENDAR_ANNUALLY;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_ACTIONSLIDER_LEFT", 21)) {
    /*                       ^                   */
      *iv_return = ELM_ACTIONSLIDER_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_ACTIONSLIDER_NONE", 21)) {
    /*                       ^                   */
      *iv_return = ELM_ACTIONSLIDER_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_BG_OPTION_STRETCH", 21)) {
    /*                       ^                   */
      *iv_return = ELM_BG_OPTION_STRETCH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POPUP_ORIENT_LAST", 21)) {
    /*                       ^                   */
      *iv_return = ELM_POPUP_ORIENT_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POPUP_ORIENT_LEFT", 21)) {
    /*                       ^                   */
      *iv_return = ELM_POPUP_ORIENT_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_COLORSELECTOR_ALL", 21)) {
    /*                       ^                   */
      *iv_return = ELM_COLORSELECTOR_ALL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_FILESELECTOR_GRID", 21)) {
    /*                       ^                   */
      *iv_return = ELM_FILESELECTOR_GRID;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FILESELECTOR_LAST", 21)) {
    /*                       ^                   */
      *iv_return = ELM_FILESELECTOR_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FILESELECTOR_LIST", 21)) {
    /*                       ^                   */
      *iv_return = ELM_FILESELECTOR_LIST;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_FLIP_DIRECTION_UP", 21)) {
    /*                       ^                   */
      *iv_return = ELM_FLIP_DIRECTION_UP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_ICON_LOOKUP_THEME", 21)) {
    /*                       ^                   */
      *iv_return = ELM_ICON_LOOKUP_THEME;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_ACTIONSLIDER_RIGHT ELM_BUBBLE_POS_INVALID ELM_CNP_MODE_PLAINTEXT
     ELM_COLORSELECTOR_BOTH ELM_GENLIST_ITEM_GROUP ELM_PANEL_ORIENT_RIGHT
     ELM_POPUP_ORIENT_RIGHT ELM_SCROLLER_POLICY_ON ELM_TOOLTIP_ORIENT_TOP
     ELM_WIN_INDICATOR_HIDE ELM_WIN_INDICATOR_SHOW ELM_WIN_KEYBOARD_ALPHA
     ELM_WIN_KEYGRAB_SHARED */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'E':
    if (memEQ(name, "ELM_CNP_MODE_PLAINTEXT", 22)) {
    /*                                  ^         */
      *iv_return = ELM_CNP_MODE_PLAINTEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_ACTIONSLIDER_RIGHT", 22)) {
    /*                                  ^         */
      *iv_return = ELM_ACTIONSLIDER_RIGHT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_PANEL_ORIENT_RIGHT", 22)) {
    /*                                  ^         */
      *iv_return = ELM_PANEL_ORIENT_RIGHT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POPUP_ORIENT_RIGHT", 22)) {
    /*                                  ^         */
      *iv_return = ELM_POPUP_ORIENT_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "ELM_WIN_INDICATOR_SHOW", 22)) {
    /*                                  ^         */
      *iv_return = ELM_WIN_INDICATOR_SHOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_WIN_INDICATOR_HIDE", 22)) {
    /*                                  ^         */
      *iv_return = ELM_WIN_INDICATOR_HIDE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_BUBBLE_POS_INVALID", 22)) {
    /*                                  ^         */
      *iv_return = ELM_BUBBLE_POS_INVALID;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_COLORSELECTOR_BOTH", 22)) {
    /*                                  ^         */
      *iv_return = ELM_COLORSELECTOR_BOTH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_GENLIST_ITEM_GROUP", 22)) {
    /*                                  ^         */
      *iv_return = ELM_GENLIST_ITEM_GROUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_WIN_KEYBOARD_ALPHA", 22)) {
    /*                                  ^         */
      *iv_return = ELM_WIN_KEYBOARD_ALPHA;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_WIN_KEYGRAB_SHARED", 22)) {
    /*                                  ^         */
      *iv_return = ELM_WIN_KEYGRAB_SHARED;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_TOP", 22)) {
    /*                                  ^         */
      *iv_return = ELM_TOOLTIP_ORIENT_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_SCROLLER_POLICY_ON", 22)) {
    /*                                  ^         */
      *iv_return = ELM_SCROLLER_POLICY_ON;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_ACTIONSLIDER_CENTER ELM_BUBBLE_POS_TOP_LEFT ELM_FLIP_DIRECTION_DOWN
     ELM_FLIP_DIRECTION_LEFT ELM_HOVER_AXIS_VERTICAL ELM_IMAGE_FLIP_VERTICAL
     ELM_PANEL_ORIENT_BOTTOM ELM_POPUP_ORIENT_BOTTOM ELM_POPUP_ORIENT_CENTER
     ELM_SCROLLER_POLICY_OFF ELM_TOOLBAR_SHRINK_HIDE ELM_TOOLBAR_SHRINK_MENU
     ELM_TOOLBAR_SHRINK_NONE ELM_TOOLTIP_ORIENT_LAST ELM_TOOLTIP_ORIENT_LEFT
     ELM_TOOLTIP_ORIENT_NONE ELM_WIN_KEYBOARD_KEYPAD ELM_WIN_KEYGRAB_TOPMOST
     ELM_WIN_KEYGRAB_UNKNOWN ELM_WIN_MOVE_RESIZE_TOP ELM_WIN_NAVIFRAME_BASIC */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'B':
    if (memEQ(name, "ELM_TOOLBAR_SHRINK_HIDE", 23)) {
    /*                       ^                     */
      *iv_return = ELM_TOOLBAR_SHRINK_HIDE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLBAR_SHRINK_MENU", 23)) {
    /*                       ^                     */
      *iv_return = ELM_TOOLBAR_SHRINK_MENU;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLBAR_SHRINK_NONE", 23)) {
    /*                       ^                     */
      *iv_return = ELM_TOOLBAR_SHRINK_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_IMAGE_FLIP_VERTICAL", 23)) {
    /*                       ^                     */
      *iv_return = ELM_IMAGE_FLIP_VERTICAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "ELM_WIN_KEYBOARD_KEYPAD", 23)) {
    /*                       ^                     */
      *iv_return = ELM_WIN_KEYBOARD_KEYPAD;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYGRAB_TOPMOST", 23)) {
    /*                       ^                     */
      *iv_return = ELM_WIN_KEYGRAB_TOPMOST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYGRAB_UNKNOWN", 23)) {
    /*                       ^                     */
      *iv_return = ELM_WIN_KEYGRAB_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_BUBBLE_POS_TOP_LEFT", 23)) {
    /*                       ^                     */
      *iv_return = ELM_BUBBLE_POS_TOP_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_PANEL_ORIENT_BOTTOM", 23)) {
    /*                       ^                     */
      *iv_return = ELM_PANEL_ORIENT_BOTTOM;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_SCROLLER_POLICY_OFF", 23)) {
    /*                       ^                     */
      *iv_return = ELM_SCROLLER_POLICY_OFF;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "ELM_WIN_MOVE_RESIZE_TOP", 23)) {
    /*                       ^                     */
      *iv_return = ELM_WIN_MOVE_RESIZE_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_WIN_NAVIFRAME_BASIC", 23)) {
    /*                       ^                     */
      *iv_return = ELM_WIN_NAVIFRAME_BASIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_ACTIONSLIDER_CENTER", 23)) {
    /*                       ^                     */
      *iv_return = ELM_ACTIONSLIDER_CENTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_POPUP_ORIENT_BOTTOM", 23)) {
    /*                       ^                     */
      *iv_return = ELM_POPUP_ORIENT_BOTTOM;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POPUP_ORIENT_CENTER", 23)) {
    /*                       ^                     */
      *iv_return = ELM_POPUP_ORIENT_CENTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_HOVER_AXIS_VERTICAL", 23)) {
    /*                       ^                     */
      *iv_return = ELM_HOVER_AXIS_VERTICAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_LAST", 23)) {
    /*                       ^                     */
      *iv_return = ELM_TOOLTIP_ORIENT_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_LEFT", 23)) {
    /*                       ^                     */
      *iv_return = ELM_TOOLTIP_ORIENT_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_NONE", 23)) {
    /*                       ^                     */
      *iv_return = ELM_TOOLTIP_ORIENT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_FLIP_DIRECTION_DOWN", 23)) {
    /*                       ^                     */
      *iv_return = ELM_FLIP_DIRECTION_DOWN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_DIRECTION_LEFT", 23)) {
    /*                       ^                     */
      *iv_return = ELM_FLIP_DIRECTION_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_BUBBLE_POS_TOP_RIGHT ELM_COLORSELECTOR_PICKER ELM_FLIP_DIRECTION_RIGHT
     ELM_FOCUS_MOVE_POLICY_IN ELM_IMAGE_FLIP_TRANSPOSE ELM_SCROLLER_POLICY_AUTO
     ELM_SCROLLER_POLICY_LAST ELM_TOOLTIP_ORIENT_RIGHT ELM_WIN_INDICATOR_OPAQUE
     ELM_WIN_KEYBOARD_NUMERIC ELM_WIN_KEYBOARD_UNKNOWN ELM_WIN_MOVE_RESIZE_LEFT
     ELM_WIN_MOVE_RESIZE_MOVE */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'A':
    if (memEQ(name, "ELM_IMAGE_FLIP_TRANSPOSE", 24)) {
    /*                                ^             */
      *iv_return = ELM_IMAGE_FLIP_TRANSPOSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ELM_SCROLLER_POLICY_AUTO", 24)) {
    /*                                ^             */
      *iv_return = ELM_SCROLLER_POLICY_AUTO;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_SCROLLER_POLICY_LAST", 24)) {
    /*                                ^             */
      *iv_return = ELM_SCROLLER_POLICY_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_FOCUS_MOVE_POLICY_IN", 24)) {
    /*                                ^             */
      *iv_return = ELM_FOCUS_MOVE_POLICY_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_FLIP_DIRECTION_RIGHT", 24)) {
    /*                                ^             */
      *iv_return = ELM_FLIP_DIRECTION_RIGHT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYBOARD_NUMERIC", 24)) {
    /*                                ^             */
      *iv_return = ELM_WIN_KEYBOARD_NUMERIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_BUBBLE_POS_TOP_RIGHT", 24)) {
    /*                                ^             */
      *iv_return = ELM_BUBBLE_POS_TOP_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_RIGHT", 24)) {
    /*                                ^             */
      *iv_return = ELM_TOOLTIP_ORIENT_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_WIN_KEYBOARD_UNKNOWN", 24)) {
    /*                                ^             */
      *iv_return = ELM_WIN_KEYBOARD_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'Z':
    if (memEQ(name, "ELM_WIN_MOVE_RESIZE_LEFT", 24)) {
    /*                                ^             */
      *iv_return = ELM_WIN_MOVE_RESIZE_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_MOVE_RESIZE_MOVE", 24)) {
    /*                                ^             */
      *iv_return = ELM_WIN_MOVE_RESIZE_MOVE;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_COLORSELECTOR_PICKER", 24)) {
    /*                                ^             */
      *iv_return = ELM_COLORSELECTOR_PICKER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_INDICATOR_OPAQUE", 24)) {
    /*                                ^             */
      *iv_return = ELM_WIN_INDICATOR_OPAQUE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_COLORSELECTOR_PALETTE ELM_CTXPOPUP_DIRECTION_UP
     ELM_FLIP_INTERACTION_CUBE ELM_FLIP_INTERACTION_NONE
     ELM_FLIP_INTERACTION_PAGE ELM_HOVER_AXIS_HORIZONTAL
     ELM_ICON_LOOKUP_THEME_FDO ELM_IMAGE_FLIP_HORIZONTAL
     ELM_IMAGE_FLIP_TRANSVERSE ELM_LABEL_SLIDE_MODE_AUTO
     ELM_LABEL_SLIDE_MODE_NONE ELM_POLICY_THROTTLE_NEVER
     ELM_POPUP_ORIENT_TOP_LEFT ELM_TOOLBAR_SHRINK_EXPAND
     ELM_TOOLBAR_SHRINK_SCROLL ELM_TOOLTIP_ORIENT_BOTTOM
     ELM_TOOLTIP_ORIENT_CENTER ELM_WIN_INDICATOR_UNKNOWN
     ELM_WIN_KEYBOARD_PASSWORD ELM_WIN_KEYBOARD_TERMINAL
     ELM_WIN_KEYGRAB_EXCLUSIVE ELM_WIN_MOVE_RESIZE_RIGHT */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'A':
    if (memEQ(name, "ELM_HOVER_AXIS_HORIZONTAL", 25)) {
    /*                                      ^        */
      *iv_return = ELM_HOVER_AXIS_HORIZONTAL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_IMAGE_FLIP_HORIZONTAL", 25)) {
    /*                                      ^        */
      *iv_return = ELM_IMAGE_FLIP_HORIZONTAL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYBOARD_TERMINAL", 25)) {
    /*                                      ^        */
      *iv_return = ELM_WIN_KEYBOARD_TERMINAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "ELM_FLIP_INTERACTION_CUBE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_FLIP_INTERACTION_CUBE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "ELM_ICON_LOOKUP_THEME_FDO", 25)) {
    /*                                      ^        */
      *iv_return = ELM_ICON_LOOKUP_THEME_FDO;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_POLICY_THROTTLE_NEVER", 25)) {
    /*                                      ^        */
      *iv_return = ELM_POLICY_THROTTLE_NEVER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_CENTER", 25)) {
    /*                                      ^        */
      *iv_return = ELM_TOOLTIP_ORIENT_CENTER;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ELM_POPUP_ORIENT_TOP_LEFT", 25)) {
    /*                                      ^        */
      *iv_return = ELM_POPUP_ORIENT_TOP_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_FLIP_INTERACTION_PAGE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_FLIP_INTERACTION_PAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "ELM_WIN_MOVE_RESIZE_RIGHT", 25)) {
    /*                                      ^        */
      *iv_return = ELM_WIN_MOVE_RESIZE_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_TOOLBAR_SHRINK_SCROLL", 25)) {
    /*                                      ^        */
      *iv_return = ELM_TOOLBAR_SHRINK_SCROLL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_FLIP_INTERACTION_NONE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_FLIP_INTERACTION_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_LABEL_SLIDE_MODE_NONE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_LABEL_SLIDE_MODE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLBAR_SHRINK_EXPAND", 25)) {
    /*                                      ^        */
      *iv_return = ELM_TOOLBAR_SHRINK_EXPAND;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_BOTTOM", 25)) {
    /*                                      ^        */
      *iv_return = ELM_TOOLTIP_ORIENT_BOTTOM;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_WIN_KEYBOARD_PASSWORD", 25)) {
    /*                                      ^        */
      *iv_return = ELM_WIN_KEYBOARD_PASSWORD;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_IMAGE_FLIP_TRANSVERSE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_IMAGE_FLIP_TRANSVERSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_COLORSELECTOR_PALETTE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_COLORSELECTOR_PALETTE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_LABEL_SLIDE_MODE_AUTO", 25)) {
    /*                                      ^        */
      *iv_return = ELM_LABEL_SLIDE_MODE_AUTO;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_CTXPOPUP_DIRECTION_UP", 25)) {
    /*                                      ^        */
      *iv_return = ELM_CTXPOPUP_DIRECTION_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "ELM_WIN_KEYGRAB_EXCLUSIVE", 25)) {
    /*                                      ^        */
      *iv_return = ELM_WIN_KEYGRAB_EXCLUSIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "ELM_WIN_INDICATOR_UNKNOWN", 25)) {
    /*                                      ^        */
      *iv_return = ELM_WIN_INDICATOR_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_BUBBLE_POS_BOTTOM_LEFT ELM_CALENDAR_REVERSE_DAILY
     ELM_FILESELECTOR_SORT_LAST ELM_GENLIST_ITEM_FIELD_ALL
     ELM_GLVIEW_MULTISAMPLE_LOW ELM_GLVIEW_MULTISAMPLE_MED
     ELM_OBJECT_SELECT_MODE_MAX ELM_POLICY_THROTTLE_CONFIG
     ELM_POPUP_ORIENT_TOP_RIGHT ELM_TEXT_FORMAT_PLAIN_UTF8
     ELM_WIN_MOVE_RESIZE_BOTTOM */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'D':
    if (memEQ(name, "ELM_CALENDAR_REVERSE_DAILY", 26)) {
    /*                        ^                       */
      *iv_return = ELM_CALENDAR_REVERSE_DAILY;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_BUBBLE_POS_BOTTOM_LEFT", 26)) {
    /*                        ^                       */
      *iv_return = ELM_BUBBLE_POS_BOTTOM_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FILESELECTOR_SORT_LAST", 26)) {
    /*                        ^                       */
      *iv_return = ELM_FILESELECTOR_SORT_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ELM_TEXT_FORMAT_PLAIN_UTF8", 26)) {
    /*                        ^                       */
      *iv_return = ELM_TEXT_FORMAT_PLAIN_UTF8;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_WIN_MOVE_RESIZE_BOTTOM", 26)) {
    /*                        ^                       */
      *iv_return = ELM_WIN_MOVE_RESIZE_BOTTOM;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_GENLIST_ITEM_FIELD_ALL", 26)) {
    /*                        ^                       */
      *iv_return = ELM_GENLIST_ITEM_FIELD_ALL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_OBJECT_SELECT_MODE_MAX", 26)) {
    /*                        ^                       */
      *iv_return = ELM_OBJECT_SELECT_MODE_MAX;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "ELM_GLVIEW_MULTISAMPLE_LOW", 26)) {
    /*                        ^                       */
      *iv_return = ELM_GLVIEW_MULTISAMPLE_LOW;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_GLVIEW_MULTISAMPLE_MED", 26)) {
    /*                        ^                       */
      *iv_return = ELM_GLVIEW_MULTISAMPLE_MED;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "ELM_POLICY_THROTTLE_CONFIG", 26)) {
    /*                        ^                       */
      *iv_return = ELM_POLICY_THROTTLE_CONFIG;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_POPUP_ORIENT_TOP_RIGHT", 26)) {
    /*                        ^                       */
      *iv_return = ELM_POPUP_ORIENT_TOP_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_BUBBLE_POS_BOTTOM_RIGHT ELM_CALENDAR_SELECTABLE_DAY
     ELM_CTXPOPUP_DIRECTION_DOWN ELM_CTXPOPUP_DIRECTION_LEFT
     ELM_FLIP_INTERACTION_ROTATE ELM_FOCUS_MOVE_POLICY_CLICK
     ELM_GENLIST_ITEM_FIELD_TEXT ELM_GLVIEW_MULTISAMPLE_HIGH
     ELM_LABEL_SLIDE_MODE_ALWAYS ELM_OBJECT_SELECT_MODE_NONE
     ELM_PHOTOCAM_ZOOM_MODE_LAST ELM_POLICY_EXIT_WINDOWS_DEL
     ELM_TEXT_FORMAT_MARKUP_UTF8 ELM_TOOLTIP_ORIENT_TOP_LEFT */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'A':
    if (memEQ(name, "ELM_CALENDAR_SELECTABLE_DAY", 27)) {
    /*                                        ^        */
      *iv_return = ELM_CALENDAR_SELECTABLE_DAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ELM_FOCUS_MOVE_POLICY_CLICK", 27)) {
    /*                                        ^        */
      *iv_return = ELM_FOCUS_MOVE_POLICY_CLICK;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_POLICY_EXIT_WINDOWS_DEL", 27)) {
    /*                                        ^        */
      *iv_return = ELM_POLICY_EXIT_WINDOWS_DEL;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ELM_CTXPOPUP_DIRECTION_LEFT", 27)) {
    /*                                        ^        */
      *iv_return = ELM_CTXPOPUP_DIRECTION_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TEXT_FORMAT_MARKUP_UTF8", 27)) {
    /*                                        ^        */
      *iv_return = ELM_TEXT_FORMAT_MARKUP_UTF8;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_TOP_LEFT", 27)) {
    /*                                        ^        */
      *iv_return = ELM_TOOLTIP_ORIENT_TOP_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_GLVIEW_MULTISAMPLE_HIGH", 27)) {
    /*                                        ^        */
      *iv_return = ELM_GLVIEW_MULTISAMPLE_HIGH;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "ELM_BUBBLE_POS_BOTTOM_RIGHT", 27)) {
    /*                                        ^        */
      *iv_return = ELM_BUBBLE_POS_BOTTOM_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_OBJECT_SELECT_MODE_NONE", 27)) {
    /*                                        ^        */
      *iv_return = ELM_OBJECT_SELECT_MODE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_PHOTOCAM_ZOOM_MODE_LAST", 27)) {
    /*                                        ^        */
      *iv_return = ELM_PHOTOCAM_ZOOM_MODE_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_FLIP_INTERACTION_ROTATE", 27)) {
    /*                                        ^        */
      *iv_return = ELM_FLIP_INTERACTION_ROTATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "ELM_CTXPOPUP_DIRECTION_DOWN", 27)) {
    /*                                        ^        */
      *iv_return = ELM_CTXPOPUP_DIRECTION_DOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "ELM_GENLIST_ITEM_FIELD_TEXT", 27)) {
    /*                                        ^        */
      *iv_return = ELM_GENLIST_ITEM_FIELD_TEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "ELM_LABEL_SLIDE_MODE_ALWAYS", 27)) {
    /*                                        ^        */
      *iv_return = ELM_LABEL_SLIDE_MODE_ALWAYS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_28 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_CALENDAR_SELECTABLE_NONE ELM_CALENDAR_SELECTABLE_YEAR
     ELM_COLORSELECTOR_COMPONENTS ELM_CTXPOPUP_DIRECTION_RIGHT
     ELM_GENLIST_ITEM_FIELD_STATE ELM_GENLIST_ITEM_SCROLLTO_IN
     ELM_POPUP_ORIENT_BOTTOM_LEFT ELM_TOOLBAR_ITEM_SCROLLTO_IN
     ELM_TOOLTIP_ORIENT_TOP_RIGHT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'B':
    if (memEQ(name, "ELM_TOOLBAR_ITEM_SCROLLTO_IN", 28)) {
    /*                       ^                          */
      *iv_return = ELM_TOOLBAR_ITEM_SCROLLTO_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_GENLIST_ITEM_FIELD_STATE", 28)) {
    /*                       ^                          */
      *iv_return = ELM_GENLIST_ITEM_FIELD_STATE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_GENLIST_ITEM_SCROLLTO_IN", 28)) {
    /*                       ^                          */
      *iv_return = ELM_GENLIST_ITEM_SCROLLTO_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_CALENDAR_SELECTABLE_NONE", 28)) {
    /*                       ^                          */
      *iv_return = ELM_CALENDAR_SELECTABLE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_CALENDAR_SELECTABLE_YEAR", 28)) {
    /*                       ^                          */
      *iv_return = ELM_CALENDAR_SELECTABLE_YEAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_CTXPOPUP_DIRECTION_RIGHT", 28)) {
    /*                       ^                          */
      *iv_return = ELM_CTXPOPUP_DIRECTION_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ELM_POPUP_ORIENT_BOTTOM_LEFT", 28)) {
    /*                       ^                          */
      *iv_return = ELM_POPUP_ORIENT_BOTTOM_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_COLORSELECTOR_COMPONENTS", 28)) {
    /*                       ^                          */
      *iv_return = ELM_COLORSELECTOR_COMPONENTS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_TOP_RIGHT", 28)) {
    /*                       ^                          */
      *iv_return = ELM_TOOLTIP_ORIENT_TOP_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_CALENDAR_SELECTABLE_MONTH ELM_CALENDAR_SELECT_MODE_NONE
     ELM_FLIP_ROTATE_X_CENTER_AXIS ELM_FLIP_ROTATE_Y_CENTER_AXIS
     ELM_GENLIST_ITEM_SCROLLTO_TOP ELM_OBJECT_SELECT_MODE_ALWAYS
     ELM_PHOTOCAM_ZOOM_MODE_MANUAL ELM_POPUP_ORIENT_BOTTOM_RIGHT
     ELM_WIN_INDICATOR_TRANSLUCENT ELM_WIN_INDICATOR_TRANSPARENT
     ELM_WIN_KEYBOARD_PHONE_NUMBER */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'A':
    if (memEQ(name, "ELM_OBJECT_SELECT_MODE_ALWAYS", 29)) {
    /*                                         ^         */
      *iv_return = ELM_OBJECT_SELECT_MODE_ALWAYS;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "ELM_WIN_KEYBOARD_PHONE_NUMBER", 29)) {
    /*                                         ^         */
      *iv_return = ELM_WIN_KEYBOARD_PHONE_NUMBER;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_WIN_INDICATOR_TRANSLUCENT", 29)) {
    /*                                         ^         */
      *iv_return = ELM_WIN_INDICATOR_TRANSLUCENT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_INDICATOR_TRANSPARENT", 29)) {
    /*                                         ^         */
      *iv_return = ELM_WIN_INDICATOR_TRANSPARENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_POPUP_ORIENT_BOTTOM_RIGHT", 29)) {
    /*                                         ^         */
      *iv_return = ELM_POPUP_ORIENT_BOTTOM_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_CALENDAR_SELECTABLE_MONTH", 29)) {
    /*                                         ^         */
      *iv_return = ELM_CALENDAR_SELECTABLE_MONTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_CALENDAR_SELECT_MODE_NONE", 29)) {
    /*                                         ^         */
      *iv_return = ELM_CALENDAR_SELECT_MODE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_GENLIST_ITEM_SCROLLTO_TOP", 29)) {
    /*                                         ^         */
      *iv_return = ELM_GENLIST_ITEM_SCROLLTO_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "ELM_PHOTOCAM_ZOOM_MODE_MANUAL", 29)) {
    /*                                         ^         */
      *iv_return = ELM_PHOTOCAM_ZOOM_MODE_MANUAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "ELM_FLIP_ROTATE_X_CENTER_AXIS", 29)) {
    /*                                         ^         */
      *iv_return = ELM_FLIP_ROTATE_X_CENTER_AXIS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_ROTATE_Y_CENTER_AXIS", 29)) {
    /*                                         ^         */
      *iv_return = ELM_FLIP_ROTATE_Y_CENTER_AXIS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_30 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_CALENDAR_LAST_DAY_OF_MONTH ELM_CTXPOPUP_DIRECTION_UNKNOWN
     ELM_FLIP_ROTATE_XZ_CENTER_AXIS ELM_FLIP_ROTATE_YZ_CENTER_AXIS
     ELM_FOCUS_AUTOSCROLL_MODE_NONE ELM_FOCUS_AUTOSCROLL_MODE_SHOW
     ELM_FOCUS_MOVE_POLICY_KEY_ONLY ELM_GENLIST_ITEM_FIELD_CONTENT
     ELM_GENLIST_ITEM_SCROLLTO_NONE ELM_GLVIEW_RESIZE_POLICY_SCALE
     ELM_OBJECT_SELECT_MODE_DEFAULT ELM_SCROLLER_MOVEMENT_NO_BLOCK
     ELM_TOOLBAR_ITEM_SCROLLTO_LAST ELM_TOOLBAR_ITEM_SCROLLTO_NONE
     ELM_TOOLTIP_ORIENT_BOTTOM_LEFT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'B':
    if (memEQ(name, "ELM_TOOLBAR_ITEM_SCROLLTO_LAST", 30)) {
    /*                       ^                            */
      *iv_return = ELM_TOOLBAR_ITEM_SCROLLTO_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_TOOLBAR_ITEM_SCROLLTO_NONE", 30)) {
    /*                       ^                            */
      *iv_return = ELM_TOOLBAR_ITEM_SCROLLTO_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ELM_OBJECT_SELECT_MODE_DEFAULT", 30)) {
    /*                       ^                            */
      *iv_return = ELM_OBJECT_SELECT_MODE_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ELM_GLVIEW_RESIZE_POLICY_SCALE", 30)) {
    /*                       ^                            */
      *iv_return = ELM_GLVIEW_RESIZE_POLICY_SCALE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_GENLIST_ITEM_FIELD_CONTENT", 30)) {
    /*                       ^                            */
      *iv_return = ELM_GENLIST_ITEM_FIELD_CONTENT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_GENLIST_ITEM_SCROLLTO_NONE", 30)) {
    /*                       ^                            */
      *iv_return = ELM_GENLIST_ITEM_SCROLLTO_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_SCROLLER_MOVEMENT_NO_BLOCK", 30)) {
    /*                       ^                            */
      *iv_return = ELM_SCROLLER_MOVEMENT_NO_BLOCK;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_CALENDAR_LAST_DAY_OF_MONTH", 30)) {
    /*                       ^                            */
      *iv_return = ELM_CALENDAR_LAST_DAY_OF_MONTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_CTXPOPUP_DIRECTION_UNKNOWN", 30)) {
    /*                       ^                            */
      *iv_return = ELM_CTXPOPUP_DIRECTION_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_FOCUS_AUTOSCROLL_MODE_NONE", 30)) {
    /*                       ^                            */
      *iv_return = ELM_FOCUS_AUTOSCROLL_MODE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FOCUS_AUTOSCROLL_MODE_SHOW", 30)) {
    /*                       ^                            */
      *iv_return = ELM_FOCUS_AUTOSCROLL_MODE_SHOW;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FOCUS_MOVE_POLICY_KEY_ONLY", 30)) {
    /*                       ^                            */
      *iv_return = ELM_FOCUS_MOVE_POLICY_KEY_ONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_BOTTOM_LEFT", 30)) {
    /*                       ^                            */
      *iv_return = ELM_TOOLTIP_ORIENT_BOTTOM_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_FLIP_ROTATE_XZ_CENTER_AXIS", 30)) {
    /*                       ^                            */
      *iv_return = ELM_FLIP_ROTATE_XZ_CENTER_AXIS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FLIP_ROTATE_YZ_CENTER_AXIS", 30)) {
    /*                       ^                            */
      *iv_return = ELM_FLIP_ROTATE_YZ_CENTER_AXIS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_CALENDAR_SELECT_MODE_ALWAYS ELM_GLVIEW_CLIENT_SIDE_ROTATION
     ELM_GLVIEW_RENDER_POLICY_ALWAYS ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT
     ELM_TOOLBAR_ITEM_SCROLLTO_FIRST ELM_TOOLTIP_ORIENT_BOTTOM_RIGHT */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'I':
    if (memEQ(name, "ELM_GLVIEW_CLIENT_SIDE_ROTATION", 31)) {
    /*                            ^                        */
      *iv_return = ELM_GLVIEW_CLIENT_SIDE_ROTATION;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_GLVIEW_RENDER_POLICY_ALWAYS", 31)) {
    /*                            ^                        */
      *iv_return = ELM_GLVIEW_RENDER_POLICY_ALWAYS;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_TOOLTIP_ORIENT_BOTTOM_RIGHT", 31)) {
    /*                            ^                        */
      *iv_return = ELM_TOOLTIP_ORIENT_BOTTOM_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_CALENDAR_SELECT_MODE_ALWAYS", 31)) {
    /*                            ^                        */
      *iv_return = ELM_CALENDAR_SELECT_MODE_ALWAYS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_TOOLBAR_ITEM_SCROLLTO_FIRST", 31)) {
    /*                            ^                        */
      *iv_return = ELM_TOOLBAR_ITEM_SCROLLTO_FIRST;
      return PERL_constant_ISIV;
    }
    break;
  case 'Z':
    if (memEQ(name, "ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT", 31)) {
    /*                            ^                        */
      *iv_return = ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_CALENDAR_SELECT_MODE_DEFAULT ELM_GENLIST_ITEM_SCROLLTO_BOTTOM
     ELM_GENLIST_ITEM_SCROLLTO_MIDDLE ELM_OBJECT_MULTI_SELECT_MODE_MAX
     ELM_PHOTOCAM_ZOOM_MODE_AUTO_FILL ELM_TOOLBAR_ITEM_SCROLLTO_MIDDLE */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'B':
    if (memEQ(name, "ELM_TOOLBAR_ITEM_SCROLLTO_MIDDLE", 32)) {
    /*                       ^                              */
      *iv_return = ELM_TOOLBAR_ITEM_SCROLLTO_MIDDLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ELM_OBJECT_MULTI_SELECT_MODE_MAX", 32)) {
    /*                       ^                              */
      *iv_return = ELM_OBJECT_MULTI_SELECT_MODE_MAX;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ELM_GENLIST_ITEM_SCROLLTO_BOTTOM", 32)) {
    /*                       ^                              */
      *iv_return = ELM_GENLIST_ITEM_SCROLLTO_BOTTOM;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_GENLIST_ITEM_SCROLLTO_MIDDLE", 32)) {
    /*                       ^                              */
      *iv_return = ELM_GENLIST_ITEM_SCROLLTO_MIDDLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_CALENDAR_SELECT_MODE_DEFAULT", 32)) {
    /*                       ^                              */
      *iv_return = ELM_CALENDAR_SELECT_MODE_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_PHOTOCAM_ZOOM_MODE_AUTO_FILL", 32)) {
    /*                       ^                              */
      *iv_return = ELM_PHOTOCAM_ZOOM_MODE_AUTO_FILL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_33 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_CALENDAR_SELECT_MODE_ONDEMAND ELM_FILESELECTOR_SORT_BY_SIZE_ASC
     ELM_FILESELECTOR_SORT_BY_TYPE_ASC ELM_GLVIEW_RESIZE_POLICY_RECREATE
     ELM_POLICY_THROTTLE_HIDDEN_ALWAYS ELM_WIN_INDICATOR_OPACITY_UNKNOWN */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'N':
    if (memEQ(name, "ELM_POLICY_THROTTLE_HIDDEN_ALWAYS", 33)) {
    /*                                        ^              */
      *iv_return = ELM_POLICY_THROTTLE_HIDDEN_ALWAYS;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_CALENDAR_SELECT_MODE_ONDEMAND", 33)) {
    /*                                        ^              */
      *iv_return = ELM_CALENDAR_SELECT_MODE_ONDEMAND;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ELM_GLVIEW_RESIZE_POLICY_RECREATE", 33)) {
    /*                                        ^              */
      *iv_return = ELM_GLVIEW_RESIZE_POLICY_RECREATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_SIZE_ASC", 33)) {
    /*                                        ^              */
      *iv_return = ELM_FILESELECTOR_SORT_BY_SIZE_ASC;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_TYPE_ASC", 33)) {
    /*                                        ^              */
      *iv_return = ELM_FILESELECTOR_SORT_BY_TYPE_ASC;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ELM_WIN_INDICATOR_OPACITY_UNKNOWN", 33)) {
    /*                                        ^              */
      *iv_return = ELM_WIN_INDICATOR_OPACITY_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_34 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_FILESELECTOR_SORT_BY_SIZE_DESC ELM_FILESELECTOR_SORT_BY_TYPE_DESC
     ELM_FOCUS_AUTOSCROLL_MODE_BRING_IN ELM_GLVIEW_RENDER_POLICY_ON_DEMAND
     ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT_IN ELM_POLICY_QUIT_LAST_WINDOW_CLOSED
     ELM_POLICY_QUIT_LAST_WINDOW_HIDDEN ELM_SCROLLER_SINGLE_DIRECTION_HARD
     ELM_SCROLLER_SINGLE_DIRECTION_LAST ELM_SCROLLER_SINGLE_DIRECTION_NONE
     ELM_SCROLLER_SINGLE_DIRECTION_SOFT ELM_WIN_KEYGRAB_OVERRIDE_EXCLUSIVE */
  /* Offset 30 gives the best switch position.  */
  switch (name[30]) {
  case 'D':
    if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_SIZE_DESC", 34)) {
    /*                                             ^          */
      *iv_return = ELM_FILESELECTOR_SORT_BY_SIZE_DESC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_TYPE_DESC", 34)) {
    /*                                             ^          */
      *iv_return = ELM_FILESELECTOR_SORT_BY_TYPE_DESC;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_POLICY_QUIT_LAST_WINDOW_HIDDEN", 34)) {
    /*                                             ^          */
      *iv_return = ELM_POLICY_QUIT_LAST_WINDOW_HIDDEN;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ELM_FOCUS_AUTOSCROLL_MODE_BRING_IN", 34)) {
    /*                                             ^          */
      *iv_return = ELM_FOCUS_AUTOSCROLL_MODE_BRING_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "ELM_SCROLLER_SINGLE_DIRECTION_HARD", 34)) {
    /*                                             ^          */
      *iv_return = ELM_SCROLLER_SINGLE_DIRECTION_HARD;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_SCROLLER_SINGLE_DIRECTION_LAST", 34)) {
    /*                                             ^          */
      *iv_return = ELM_SCROLLER_SINGLE_DIRECTION_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "ELM_GLVIEW_RENDER_POLICY_ON_DEMAND", 34)) {
    /*                                             ^          */
      *iv_return = ELM_GLVIEW_RENDER_POLICY_ON_DEMAND;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ELM_SCROLLER_SINGLE_DIRECTION_NONE", 34)) {
    /*                                             ^          */
      *iv_return = ELM_SCROLLER_SINGLE_DIRECTION_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_POLICY_QUIT_LAST_WINDOW_CLOSED", 34)) {
    /*                                             ^          */
      *iv_return = ELM_POLICY_QUIT_LAST_WINDOW_CLOSED;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ELM_SCROLLER_SINGLE_DIRECTION_SOFT", 34)) {
    /*                                             ^          */
      *iv_return = ELM_SCROLLER_SINGLE_DIRECTION_SOFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "ELM_WIN_KEYGRAB_OVERRIDE_EXCLUSIVE", 34)) {
    /*                                             ^          */
      *iv_return = ELM_WIN_KEYGRAB_OVERRIDE_EXCLUSIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT_IN", 34)) {
    /*                                             ^          */
      *iv_return = ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT_IN;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_38 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ELM_FILESELECTOR_SORT_BY_FILENAME_DESC
     ELM_FILESELECTOR_SORT_BY_MODIFIED_DESC
     ELM_SCROLLER_MOVEMENT_BLOCK_HORIZONTAL
     ELM_SLIDER_INDICATOR_VISIBLE_MODE_NONE */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'I':
    if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_FILENAME_DESC", 38)) {
    /*                                         ^                  */
      *iv_return = ELM_FILESELECTOR_SORT_BY_FILENAME_DESC;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "ELM_SCROLLER_MOVEMENT_BLOCK_HORIZONTAL", 38)) {
    /*                                         ^                  */
      *iv_return = ELM_SCROLLER_MOVEMENT_BLOCK_HORIZONTAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ELM_SLIDER_INDICATOR_VISIBLE_MODE_NONE", 38)) {
    /*                                         ^                  */
      *iv_return = ELM_SLIDER_INDICATOR_VISIBLE_MODE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_MODIFIED_DESC", 38)) {
    /*                                         ^                  */
      *iv_return = ELM_FILESELECTOR_SORT_BY_MODIFIED_DESC;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"ELM_ACTIONSLIDER_ALL", type=>"IV", macro=>"1"},
            {name=>"ELM_ACTIONSLIDER_CENTER", type=>"IV", macro=>"1"},
            {name=>"ELM_ACTIONSLIDER_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_ACTIONSLIDER_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_ACTIONSLIDER_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_BG_OPTION_CENTER", type=>"IV", macro=>"1"},
            {name=>"ELM_BG_OPTION_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_BG_OPTION_SCALE", type=>"IV", macro=>"1"},
            {name=>"ELM_BG_OPTION_STRETCH", type=>"IV", macro=>"1"},
            {name=>"ELM_BG_OPTION_TILE", type=>"IV", macro=>"1"},
            {name=>"ELM_BUBBLE_POS_BOTTOM_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_BUBBLE_POS_BOTTOM_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_BUBBLE_POS_INVALID", type=>"IV", macro=>"1"},
            {name=>"ELM_BUBBLE_POS_TOP_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_BUBBLE_POS_TOP_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_ANNUALLY", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_DAILY", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_LAST_DAY_OF_MONTH", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_MONTHLY", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_REVERSE_DAILY", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECTABLE_DAY", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECTABLE_MONTH", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECTABLE_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECTABLE_YEAR", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECT_MODE_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECT_MODE_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECT_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_SELECT_MODE_ONDEMAND", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_UNIQUE", type=>"IV", macro=>"1"},
            {name=>"ELM_CALENDAR_WEEKLY", type=>"IV", macro=>"1"},
            {name=>"ELM_CNP_MODE_MARKUP", type=>"IV", macro=>"1"},
            {name=>"ELM_CNP_MODE_NO_IMAGE", type=>"IV", macro=>"1"},
            {name=>"ELM_CNP_MODE_PLAINTEXT", type=>"IV", macro=>"1"},
            {name=>"ELM_COLORSELECTOR_ALL", type=>"IV", macro=>"1"},
            {name=>"ELM_COLORSELECTOR_BOTH", type=>"IV", macro=>"1"},
            {name=>"ELM_COLORSELECTOR_COMPONENTS", type=>"IV", macro=>"1"},
            {name=>"ELM_COLORSELECTOR_PALETTE", type=>"IV", macro=>"1"},
            {name=>"ELM_COLORSELECTOR_PICKER", type=>"IV", macro=>"1"},
            {name=>"ELM_CTXPOPUP_DIRECTION_DOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_CTXPOPUP_DIRECTION_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_CTXPOPUP_DIRECTION_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_CTXPOPUP_DIRECTION_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_CTXPOPUP_DIRECTION_UP", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_FRIDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_MONDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_SATURDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_SUNDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_THURSDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_TUESDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_DAY_WEDNESDAY", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_GRID", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_LIST", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_FILENAME_ASC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_FILENAME_DESC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_MODIFIED_ASC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_MODIFIED_DESC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_SIZE_ASC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_SIZE_DESC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_TYPE_ASC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_BY_TYPE_DESC", type=>"IV", macro=>"1"},
            {name=>"ELM_FILESELECTOR_SORT_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_CROSS_FADE", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_CUBE_DOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_CUBE_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_CUBE_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_CUBE_UP", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_DIRECTION_DOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_DIRECTION_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_DIRECTION_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_DIRECTION_UP", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_INTERACTION_CUBE", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_INTERACTION_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_INTERACTION_PAGE", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_INTERACTION_ROTATE", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_PAGE_DOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_PAGE_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_PAGE_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_PAGE_UP", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_ROTATE_XZ_CENTER_AXIS", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_ROTATE_X_CENTER_AXIS", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_ROTATE_YZ_CENTER_AXIS", type=>"IV", macro=>"1"},
            {name=>"ELM_FLIP_ROTATE_Y_CENTER_AXIS", type=>"IV", macro=>"1"},
            {name=>"ELM_FOCUS_AUTOSCROLL_MODE_BRING_IN", type=>"IV", macro=>"1"},
            {name=>"ELM_FOCUS_AUTOSCROLL_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_FOCUS_AUTOSCROLL_MODE_SHOW", type=>"IV", macro=>"1"},
            {name=>"ELM_FOCUS_MOVE_POLICY_CLICK", type=>"IV", macro=>"1"},
            {name=>"ELM_FOCUS_MOVE_POLICY_IN", type=>"IV", macro=>"1"},
            {name=>"ELM_FOCUS_MOVE_POLICY_KEY_ONLY", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_FIELD_ALL", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_FIELD_CONTENT", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_FIELD_STATE", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_FIELD_TEXT", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_GROUP", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_MAX", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_SCROLLTO_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_SCROLLTO_IN", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_SCROLLTO_MIDDLE", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_SCROLLTO_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_SCROLLTO_TOP", type=>"IV", macro=>"1"},
            {name=>"ELM_GENLIST_ITEM_TREE", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_ALPHA", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_CLIENT_SIDE_ROTATION", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_DEPTH", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_DEPTH_16", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_DEPTH_24", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_DEPTH_32", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_DEPTH_8", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_DIRECT", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_MULTISAMPLE_HIGH", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_MULTISAMPLE_LOW", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_MULTISAMPLE_MED", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_RENDER_POLICY_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_RENDER_POLICY_ON_DEMAND", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_RESIZE_POLICY_RECREATE", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_RESIZE_POLICY_SCALE", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_STENCIL", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_STENCIL_1", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_STENCIL_16", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_STENCIL_2", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_STENCIL_4", type=>"IV", macro=>"1"},
            {name=>"ELM_GLVIEW_STENCIL_8", type=>"IV", macro=>"1"},
            {name=>"ELM_HOVER_AXIS_BOTH", type=>"IV", macro=>"1"},
            {name=>"ELM_HOVER_AXIS_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"ELM_HOVER_AXIS_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_HOVER_AXIS_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"ELM_ICON_FILE", type=>"IV", macro=>"1"},
            {name=>"ELM_ICON_LOOKUP_FDO", type=>"IV", macro=>"1"},
            {name=>"ELM_ICON_LOOKUP_THEME", type=>"IV", macro=>"1"},
            {name=>"ELM_ICON_LOOKUP_THEME_FDO", type=>"IV", macro=>"1"},
            {name=>"ELM_ICON_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_ICON_STANDARD", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_FLIP_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_FLIP_TRANSPOSE", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_FLIP_TRANSVERSE", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_FLIP_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ORIENT_0", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ORIENT_180", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ORIENT_270", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ORIENT_90", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ORIENT_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ROTATE_180", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ROTATE_270", type=>"IV", macro=>"1"},
            {name=>"ELM_IMAGE_ROTATE_90", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_NORMAL", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED_AND_DECIMAL", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL", type=>"IV", macro=>"1"},
            {name=>"ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NUMBERONLY", type=>"IV", macro=>"1"},
            {name=>"ELM_LABEL_SLIDE_MODE_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"ELM_LABEL_SLIDE_MODE_AUTO", type=>"IV", macro=>"1"},
            {name=>"ELM_LABEL_SLIDE_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_LIST_COMPRESS", type=>"IV", macro=>"1"},
            {name=>"ELM_LIST_EXPAND", type=>"IV", macro=>"1"},
            {name=>"ELM_LIST_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_LIST_LIMIT", type=>"IV", macro=>"1"},
            {name=>"ELM_LIST_SCROLL", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_MULTI_SELECT_MODE_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_MULTI_SELECT_MODE_MAX", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_MULTI_SELECT_MODE_WITH_CONTROL", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_SELECT_MODE_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_SELECT_MODE_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_SELECT_MODE_DISPLAY_ONLY", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_SELECT_MODE_MAX", type=>"IV", macro=>"1"},
            {name=>"ELM_OBJECT_SELECT_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_PANEL_ORIENT_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"ELM_PANEL_ORIENT_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_PANEL_ORIENT_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_PANEL_ORIENT_TOP", type=>"IV", macro=>"1"},
            {name=>"ELM_PHOTOCAM_ZOOM_MODE_AUTO_FILL", type=>"IV", macro=>"1"},
            {name=>"ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT", type=>"IV", macro=>"1"},
            {name=>"ELM_PHOTOCAM_ZOOM_MODE_AUTO_FIT_IN", type=>"IV", macro=>"1"},
            {name=>"ELM_PHOTOCAM_ZOOM_MODE_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_PHOTOCAM_ZOOM_MODE_MANUAL", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_EXIT", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_EXIT_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_EXIT_WINDOWS_DEL", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_QUIT", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_QUIT_LAST_WINDOW_CLOSED", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_QUIT_LAST_WINDOW_HIDDEN", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_QUIT_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_THROTTLE", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_THROTTLE_CONFIG", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_THROTTLE_HIDDEN_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"ELM_POLICY_THROTTLE_NEVER", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_BOTTOM_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_BOTTOM_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_CENTER", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_TOP", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_TOP_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_POPUP_ORIENT_TOP_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_MOVEMENT_BLOCK_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_MOVEMENT_BLOCK_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_MOVEMENT_NO_BLOCK", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_POLICY_AUTO", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_POLICY_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_POLICY_OFF", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_POLICY_ON", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_SINGLE_DIRECTION_HARD", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_SINGLE_DIRECTION_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_SINGLE_DIRECTION_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_SCROLLER_SINGLE_DIRECTION_SOFT", type=>"IV", macro=>"1"},
            {name=>"ELM_SLIDER_INDICATOR_VISIBLE_MODE_ALWAYS", type=>"IV", macro=>"1"},
            {name=>"ELM_SLIDER_INDICATOR_VISIBLE_MODE_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"ELM_SLIDER_INDICATOR_VISIBLE_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_SLIDER_INDICATOR_VISIBLE_MODE_ON_FOCUS", type=>"IV", macro=>"1"},
            {name=>"ELM_TEXT_FORMAT_MARKUP_UTF8", type=>"IV", macro=>"1"},
            {name=>"ELM_TEXT_FORMAT_PLAIN_UTF8", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_ITEM_SCROLLTO_FIRST", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_ITEM_SCROLLTO_IN", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_ITEM_SCROLLTO_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_ITEM_SCROLLTO_MIDDLE", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_ITEM_SCROLLTO_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_SHRINK_EXPAND", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_SHRINK_HIDE", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_SHRINK_MENU", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_SHRINK_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLBAR_SHRINK_SCROLL", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_BOTTOM_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_BOTTOM_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_CENTER", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_TOP", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_TOP_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_TOOLTIP_ORIENT_TOP_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_BASIC", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_COMBO", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_DESKTOP", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_DIALOG_BASIC", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_DND", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_DOCK", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_DROPDOWN_MENU", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_HIDE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_OPACITY_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_OPAQUE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_SHOW", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_TRANSLUCENT", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_TRANSPARENT", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INDICATOR_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_INLINED_IMAGE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_ALPHA", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_FILE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_HEX", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_HOST", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_IP", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_J2ME", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_KEYPAD", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_NUMERIC", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_OFF", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_ON", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_PASSWORD", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_PHONE_NUMBER", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_PIN", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_TERMINAL", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYBOARD_URL", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYGRAB_EXCLUSIVE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYGRAB_OVERRIDE_EXCLUSIVE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYGRAB_SHARED", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYGRAB_TOPMOST", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_KEYGRAB_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_MENU", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_MOVE_RESIZE_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_MOVE_RESIZE_LEFT", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_MOVE_RESIZE_MOVE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_MOVE_RESIZE_RIGHT", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_MOVE_RESIZE_TOP", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_NAVIFRAME_BASIC", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_NOTIFICATION", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_POPUP_MENU", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_SOCKET_IMAGE", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_SPLASH", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_TOOLBAR", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_TOOLTIP", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"ELM_WIN_UTILITY", type=>"IV", macro=>"1"},
            {name=>"ELM_WRAP_CHAR", type=>"IV", macro=>"1"},
            {name=>"ELM_WRAP_LAST", type=>"IV", macro=>"1"},
            {name=>"ELM_WRAP_MIXED", type=>"IV", macro=>"1"},
            {name=>"ELM_WRAP_NONE", type=>"IV", macro=>"1"},
            {name=>"ELM_WRAP_WORD", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("pEFL::Elm", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("pEFL::Elm", $types);
__END__
   */

  switch (len) {
  case 11:
    if (memEQ(name, "ELM_WIN_DND", 11)) {
      *iv_return = ELM_WIN_DND;
      return PERL_constant_ISIV;
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    return constant_28 (aTHX_ name, iv_return);
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 30:
    return constant_30 (aTHX_ name, iv_return);
    break;
  case 31:
    return constant_31 (aTHX_ name, iv_return);
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 34:
    return constant_34 (aTHX_ name, iv_return);
    break;
  case 35:
    if (memEQ(name, "ELM_OBJECT_SELECT_MODE_DISPLAY_ONLY", 35)) {
      *iv_return = ELM_OBJECT_SELECT_MODE_DISPLAY_ONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 36:
    /* Names all of length 36.  */
    /* ELM_OBJECT_MULTI_SELECT_MODE_DEFAULT
       ELM_SCROLLER_MOVEMENT_BLOCK_VERTICAL */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'B':
      if (memEQ(name, "ELM_OBJECT_MULTI_SELECT_MODE_DEFAULT", 36)) {
      /*                    ^                                     */
        *iv_return = ELM_OBJECT_MULTI_SELECT_MODE_DEFAULT;
        return PERL_constant_ISIV;
      }
      break;
    case 'C':
      if (memEQ(name, "ELM_SCROLLER_MOVEMENT_BLOCK_VERTICAL", 36)) {
      /*                    ^                                     */
        *iv_return = ELM_SCROLLER_MOVEMENT_BLOCK_VERTICAL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 37:
    /* Names all of length 37.  */
    /* ELM_FILESELECTOR_SORT_BY_FILENAME_ASC
       ELM_FILESELECTOR_SORT_BY_MODIFIED_ASC */
    /* Offset 32 gives the best switch position.  */
    switch (name[32]) {
    case 'D':
      if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_MODIFIED_ASC", 37)) {
      /*                                               ^           */
        *iv_return = ELM_FILESELECTOR_SORT_BY_MODIFIED_ASC;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "ELM_FILESELECTOR_SORT_BY_FILENAME_ASC", 37)) {
      /*                                               ^           */
        *iv_return = ELM_FILESELECTOR_SORT_BY_FILENAME_ASC;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 38:
    return constant_38 (aTHX_ name, iv_return);
    break;
  case 40:
    if (memEQ(name, "ELM_SLIDER_INDICATOR_VISIBLE_MODE_ALWAYS", 40)) {
      *iv_return = ELM_SLIDER_INDICATOR_VISIBLE_MODE_ALWAYS;
      return PERL_constant_ISIV;
    }
    break;
  case 41:
    /* Names all of length 41.  */
    /* ELM_OBJECT_MULTI_SELECT_MODE_WITH_CONTROL
       ELM_SLIDER_INDICATOR_VISIBLE_MODE_DEFAULT */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'I':
      if (memEQ(name, "ELM_SLIDER_INDICATOR_VISIBLE_MODE_DEFAULT", 41)) {
      /*                     ^                                         */
        *iv_return = ELM_SLIDER_INDICATOR_VISIBLE_MODE_DEFAULT;
        return PERL_constant_ISIV;
      }
      break;
    case 'J':
      if (memEQ(name, "ELM_OBJECT_MULTI_SELECT_MODE_WITH_CONTROL", 41)) {
      /*                     ^                                         */
        *iv_return = ELM_OBJECT_MULTI_SELECT_MODE_WITH_CONTROL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 42:
    if (memEQ(name, "ELM_SLIDER_INDICATOR_VISIBLE_MODE_ON_FOCUS", 42)) {
      *iv_return = ELM_SLIDER_INDICATOR_VISIBLE_MODE_ON_FOCUS;
      return PERL_constant_ISIV;
    }
    break;
  case 46:
    if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_NORMAL", 46)) {
      *iv_return = ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 48:
    /* Names all of length 48.  */
    /* ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME
       ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL */
    /* Offset 25 gives the best switch position.  */
    switch (name[25]) {
    case 'R':
      if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME", 48)) {
      /*                                        ^                             */
        *iv_return = ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME;
        return PERL_constant_ISIV;
      }
      break;
    case 'S':
      if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL", 48)) {
      /*                                        ^                             */
        *iv_return = ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 50:
    /* Names all of length 50.  */
    /* ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL
       ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED */
    /* Offset 47 gives the best switch position.  */
    switch (name[47]) {
    case 'M':
      if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL", 50)) {
      /*                                                              ^         */
        *iv_return = ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED", 50)) {
      /*                                                              ^         */
        *iv_return = ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 51:
    /* Names all of length 51.  */
    /* ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME
       ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL */
    /* Offset 27 gives the best switch position.  */
    switch (name[27]) {
    case 'A':
      if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME", 51)) {
      /*                                          ^                              */
        *iv_return = ELM_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL", 51)) {
      /*                                          ^                              */
        *iv_return = ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 52:
    if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NUMBERONLY", 52)) {
      *iv_return = ELM_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NUMBERONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 62:
    if (memEQ(name, "ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED_AND_DECIMAL", 62)) {
      *iv_return = ELM_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED_AND_DECIMAL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

