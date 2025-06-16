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
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EDJE_CHANNEL_ALL EDJE_CURSOR_MAIN EDJE_CURSOR_USER EDJE_DRAG_DIR_XY
     EDJE_MESSAGE_INT */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'L':
    if (memEQ(name, "EDJE_CHANNEL_AL", 15)) {
    /*                              L      */
      *iv_return = EDJE_CHANNEL_ALL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_CURSOR_MAI", 15)) {
    /*                              N      */
      *iv_return = EDJE_CURSOR_MAIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_CURSOR_USE", 15)) {
    /*                              R      */
      *iv_return = EDJE_CURSOR_USER;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_MESSAGE_IN", 15)) {
    /*                              T      */
      *iv_return = EDJE_MESSAGE_INT;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "EDJE_DRAG_DIR_X", 15)) {
    /*                              Y      */
      *iv_return = EDJE_DRAG_DIR_XY;
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
     EDJE_CHANNEL_ALERT EDJE_CHANNEL_INPUT EDJE_CHANNEL_MUSIC
     EDJE_DRAG_DIR_NONE EDJE_MESSAGE_FLOAT */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "EDJE_MESSAGE_FLOAT", 18)) {
    /*                               ^        */
      *iv_return = EDJE_MESSAGE_FLOAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_CHANNEL_MUSIC", 18)) {
    /*                               ^        */
      *iv_return = EDJE_CHANNEL_MUSIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_DRAG_DIR_NONE", 18)) {
    /*                               ^        */
      *iv_return = EDJE_DRAG_DIR_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_CHANNEL_ALERT", 18)) {
    /*                               ^        */
      *iv_return = EDJE_CHANNEL_ALERT;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EDJE_CHANNEL_INPUT", 18)) {
    /*                               ^        */
      *iv_return = EDJE_CHANNEL_INPUT;
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
     EDJE_ACTION_TYPE_MO EDJE_CHANNEL_EFFECT EDJE_MESSAGE_SIGNAL
     EDJE_MESSAGE_STRING */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'G':
    if (memEQ(name, "EDJE_MESSAGE_STRIN", 18)) {
    /*                                 G      */
      *iv_return = EDJE_MESSAGE_STRING;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_MESSAGE_SIGNA", 18)) {
    /*                                 L      */
      *iv_return = EDJE_MESSAGE_SIGNAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_ACTION_TYPE_M", 18)) {
    /*                                 O      */
      *iv_return = EDJE_ACTION_TYPE_MO;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_CHANNEL_EFFEC", 18)) {
    /*                                 T      */
      *iv_return = EDJE_CHANNEL_EFFECT;
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
     EDJE_INPUT_HINT_NONE EDJE_LOAD_ERROR_NONE EDJE_MESSAGE_INT_SET
     EDJE_TWEEN_MODE_LAST EDJE_TWEEN_MODE_MASK EDJE_TWEEN_MODE_NONE */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'I':
    if (memEQ(name, "EDJE_INPUT_HINT_NONE", 20)) {
    /*                    ^                     */
      *iv_return = EDJE_INPUT_HINT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_LOAD_ERROR_NONE", 20)) {
    /*                    ^                     */
      *iv_return = EDJE_LOAD_ERROR_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EDJE_MESSAGE_INT_SET", 20)) {
    /*                    ^                     */
      *iv_return = EDJE_MESSAGE_INT_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_TWEEN_MODE_LAST", 20)) {
    /*                    ^                     */
      *iv_return = EDJE_TWEEN_MODE_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TWEEN_MODE_MASK", 20)) {
    /*                    ^                     */
      *iv_return = EDJE_TWEEN_MODE_MASK;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TWEEN_MODE_NONE", 20)) {
    /*                    ^                     */
      *iv_return = EDJE_TWEEN_MODE_NONE;
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
     EDJE_ACTION_TYPE_LAST EDJE_ACTION_TYPE_NONE EDJE_TEXT_EFFECT_GLOW
     EDJE_TEXT_EFFECT_LAST EDJE_TEXT_EFFECT_NONE EDJE_TEXT_FILTER_TEXT */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'N':
    if (memEQ(name, "EDJE_ACTION_TYPE_NONE", 21)) {
    /*                                  ^        */
      *iv_return = EDJE_ACTION_TYPE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TEXT_EFFECT_NONE", 21)) {
    /*                                  ^        */
      *iv_return = EDJE_TEXT_EFFECT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_TEXT_EFFECT_GLOW", 21)) {
    /*                                  ^        */
      *iv_return = EDJE_TEXT_EFFECT_GLOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_ACTION_TYPE_LAST", 21)) {
    /*                                  ^        */
      *iv_return = EDJE_ACTION_TYPE_LAST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TEXT_EFFECT_LAST", 21)) {
    /*                                  ^        */
      *iv_return = EDJE_TEXT_EFFECT_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "EDJE_TEXT_FILTER_TEXT", 21)) {
    /*                                  ^        */
      *iv_return = EDJE_TEXT_FILTER_TEXT;
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
     EDJE_CHANNEL_INTERFACE EDJE_CURSOR_USER_EXTRA EDJE_MESSAGE_FLOAT_SET
     EDJE_TEXT_EFFECT_PLAIN EDJE_TWEEN_MODE_BOUNCE EDJE_TWEEN_MODE_LINEAR
     EDJE_TWEEN_MODE_SPRING */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'F':
    if (memEQ(name, "EDJE_CHANNEL_INTERFACE", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_CHANNEL_INTERFACE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_TEXT_EFFECT_PLAIN", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_TEXT_EFFECT_PLAIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_TWEEN_MODE_LINEAR", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_TWEEN_MODE_LINEAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_TWEEN_MODE_SPRING", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_TWEEN_MODE_SPRING;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EDJE_TWEEN_MODE_BOUNCE", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_TWEEN_MODE_BOUNCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "EDJE_CURSOR_USER_EXTRA", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_CURSOR_USER_EXTRA;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "EDJE_MESSAGE_FLOAT_SET", 22)) {
    /*                                 ^          */
      *iv_return = EDJE_MESSAGE_FLOAT_SET;
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
     EDJE_ACTION_TYPE_SCRIPT EDJE_CHANNEL_BACKGROUND EDJE_CHANNEL_FOREGROUND
     EDJE_CURSOR_PREEDIT_END EDJE_LOAD_ERROR_GENERIC EDJE_MESSAGE_STRING_INT
     EDJE_MESSAGE_STRING_SET EDJE_TEXT_EFFECT_SHADOW EDJE_TEXT_FILTER_FORMAT
     EDJE_TEXT_FILTER_MARKUP */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'D':
    if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_TEXT_EFFECT_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EDJE_CURSOR_PREEDIT_END", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_CURSOR_PREEDIT_END;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_ACTION_TYPE_SCRIPT", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_ACTION_TYPE_SCRIPT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_MESSAGE_STRING_INT", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_MESSAGE_STRING_INT;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "EDJE_TEXT_FILTER_MARKUP", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_TEXT_FILTER_MARKUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EDJE_TEXT_FILTER_FORMAT", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_TEXT_FILTER_FORMAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_LOAD_ERROR_GENERIC", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_LOAD_ERROR_GENERIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_MESSAGE_STRING_SET", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_MESSAGE_STRING_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EDJE_CHANNEL_BACKGROUND", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_CHANNEL_BACKGROUND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_CHANNEL_FOREGROUND", 23)) {
    /*                                   ^         */
      *iv_return = EDJE_CHANNEL_FOREGROUND;
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
     EDJE_ASPECT_CONTROL_BOTH EDJE_ASPECT_CONTROL_NONE EDJE_TEXT_EFFECT_OUTLINE
     */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'B':
    if (memEQ(name, "EDJE_ASPECT_CONTROL_BOTH", 24)) {
    /*                                   ^          */
      *iv_return = EDJE_ASPECT_CONTROL_BOTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_TEXT_EFFECT_OUTLINE", 24)) {
    /*                                   ^          */
      *iv_return = EDJE_TEXT_EFFECT_OUTLINE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_ASPECT_CONTROL_NONE", 24)) {
    /*                                   ^          */
      *iv_return = EDJE_ASPECT_CONTROL_NONE;
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
     EDJE_CURSOR_PREEDIT_START EDJE_CURSOR_SELECTION_END
     EDJE_MESSAGE_STRING_FLOAT */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'C':
    if (memEQ(name, "EDJE_CURSOR_SELECTION_END", 25)) {
    /*                               ^               */
      *iv_return = EDJE_CURSOR_SELECTION_END;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "EDJE_CURSOR_PREEDIT_START", 25)) {
    /*                               ^               */
      *iv_return = EDJE_CURSOR_PREEDIT_START;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_MESSAGE_STRING_FLOAT", 25)) {
    /*                               ^               */
      *iv_return = EDJE_MESSAGE_STRING_FLOAT;
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
     EDJE_ACTION_TYPE_FOCUS_SET EDJE_ACTION_TYPE_PARAM_SET
     EDJE_ACTION_TYPE_STATE_SET EDJE_INPUT_PANEL_LAYOUT_IP
     EDJE_TWEEN_MODE_ACCELERATE EDJE_TWEEN_MODE_DECELERATE
     EDJE_TWEEN_MODE_SINUSOIDAL */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'C':
    if (memEQ(name, "EDJE_TWEEN_MODE_ACCELERATE", 26)) {
    /*                                ^               */
      *iv_return = EDJE_TWEEN_MODE_ACCELERATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EDJE_TWEEN_MODE_DECELERATE", 26)) {
    /*                                ^               */
      *iv_return = EDJE_TWEEN_MODE_DECELERATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "EDJE_ACTION_TYPE_FOCUS_SET", 26)) {
    /*                                ^               */
      *iv_return = EDJE_ACTION_TYPE_FOCUS_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_TWEEN_MODE_SINUSOIDAL", 26)) {
    /*                                ^               */
      *iv_return = EDJE_TWEEN_MODE_SINUSOIDAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_IP", 26)) {
    /*                                ^               */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_IP;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EDJE_ACTION_TYPE_PARAM_SET", 26)) {
    /*                                ^               */
      *iv_return = EDJE_ACTION_TYPE_PARAM_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_ACTION_TYPE_STATE_SET", 26)) {
    /*                                ^               */
      *iv_return = EDJE_ACTION_TYPE_STATE_SET;
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
     EDJE_ACTION_TYPE_PARAM_COPY EDJE_ACTION_TYPE_RESERVED00
     EDJE_ACTION_TYPE_SOUND_TONE EDJE_ASPECT_CONTROL_NEITHER
     EDJE_CURSOR_SELECTION_BEGIN EDJE_INPUT_PANEL_LAYOUT_HEX
     EDJE_INPUT_PANEL_LAYOUT_URL EDJE_MESSAGE_STRING_INT_SET
     EDJE_TEXT_EFFECT_FAR_SHADOW */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case '0':
    if (memEQ(name, "EDJE_ACTION_TYPE_RESERVED0", 26)) {
    /*                                         0      */
      *iv_return = EDJE_ACTION_TYPE_RESERVED00;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EDJE_ACTION_TYPE_SOUND_TON", 26)) {
    /*                                         E      */
      *iv_return = EDJE_ACTION_TYPE_SOUND_TONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_UR", 26)) {
    /*                                         L      */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_URL;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_CURSOR_SELECTION_BEGI", 26)) {
    /*                                         N      */
      *iv_return = EDJE_CURSOR_SELECTION_BEGIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_ASPECT_CONTROL_NEITHE", 26)) {
    /*                                         R      */
      *iv_return = EDJE_ASPECT_CONTROL_NEITHER;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_MESSAGE_STRING_INT_SE", 26)) {
    /*                                         T      */
      *iv_return = EDJE_MESSAGE_STRING_INT_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "EDJE_TEXT_EFFECT_FAR_SHADO", 26)) {
    /*                                         W      */
      *iv_return = EDJE_TEXT_EFFECT_FAR_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_HE", 26)) {
    /*                                         X      */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_HEX;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "EDJE_ACTION_TYPE_PARAM_COP", 26)) {
    /*                                         Y      */
      *iv_return = EDJE_ACTION_TYPE_PARAM_COPY;
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
     EDJE_ACTION_TYPE_ACTION_STOP EDJE_ACTION_TYPE_SIGNAL_EMIT
     EDJE_ASPECT_CONTROL_VERTICAL EDJE_EXTERNAL_PARAM_TYPE_INT
     EDJE_EXTERNAL_PARAM_TYPE_MAX EDJE_LOAD_ERROR_CORRUPT_FILE
     EDJE_TEXT_EFFECT_SOFT_SHADOW EDJE_TWEEN_MODE_CUBIC_BEZIER */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'B':
    if (memEQ(name, "EDJE_TWEEN_MODE_CUBIC_BEZIER", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_TWEEN_MODE_CUBIC_BEZIER;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "EDJE_ACTION_TYPE_ACTION_STOP", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_ACTION_TYPE_ACTION_STOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_ACTION_TYPE_SIGNAL_EMIT", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_ACTION_TYPE_SIGNAL_EMIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_ASPECT_CONTROL_VERTICAL", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_ASPECT_CONTROL_VERTICAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EDJE_EXTERNAL_PARAM_TYPE_INT", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_EXTERNAL_PARAM_TYPE_INT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_EXTERNAL_PARAM_TYPE_MAX", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_EXTERNAL_PARAM_TYPE_MAX;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_TEXT_EFFECT_SOFT_SHADOW", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_TEXT_EFFECT_SOFT_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_LOAD_ERROR_CORRUPT_FILE", 28)) {
    /*                                 ^                */
      *iv_return = EDJE_LOAD_ERROR_CORRUPT_FILE;
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
     EDJE_ACTION_TYPE_DRAG_VAL_SET EDJE_ACTION_TYPE_FOCUS_OBJECT
     EDJE_ACTION_TYPE_PHYSICS_STOP EDJE_ACTION_TYPE_SOUND_SAMPLE
     EDJE_ACTION_TYPE_VG_ANIM_LOOP EDJE_ACTION_TYPE_VG_ANIM_PLAY
     EDJE_ACTION_TYPE_VG_ANIM_STOP EDJE_EXTERNAL_PARAM_TYPE_BOOL
     EDJE_INPUT_HINT_AUTO_COMPLETE EDJE_INPUT_PANEL_LAYOUT_EMAIL
     EDJE_INPUT_PANEL_LAYOUT_MONTH EDJE_INPUT_PANEL_LAYOUT_VOICE
     EDJE_MESSAGE_STRING_FLOAT_SET EDJE_TEXT_EFFECT_SOFT_OUTLINE */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'A':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_EMAIL", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_EMAIL;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EDJE_ACTION_TYPE_FOCUS_OBJECT", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_FOCUS_OBJECT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_INPUT_HINT_AUTO_COMPLETE", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_INPUT_HINT_AUTO_COMPLETE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_VOICE", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_VOICE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TEXT_EFFECT_SOFT_OUTLINE", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_TEXT_EFFECT_SOFT_OUTLINE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_ACTION_TYPE_VG_ANIM_PLAY", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_VG_ANIM_PLAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_MONTH", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_MONTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_ACTION_TYPE_VG_ANIM_LOOP", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_VG_ANIM_LOOP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_EXTERNAL_PARAM_TYPE_BOOL", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_EXTERNAL_PARAM_TYPE_BOOL;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EDJE_ACTION_TYPE_SOUND_SAMPLE", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_SOUND_SAMPLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_ACTION_TYPE_DRAG_VAL_SET", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_DRAG_VAL_SET;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_MESSAGE_STRING_FLOAT_SET", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_MESSAGE_STRING_FLOAT_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_STOP", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_STOP;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_ACTION_TYPE_VG_ANIM_STOP", 29)) {
    /*                                         ^         */
      *iv_return = EDJE_ACTION_TYPE_VG_ANIM_STOP;
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
     EDJE_ACTION_TYPE_DRAG_VAL_PAGE EDJE_ACTION_TYPE_DRAG_VAL_STEP
     EDJE_ACTION_TYPE_PHYSICS_FORCE EDJE_ACTION_TYPE_VG_ANIM_PAUSE
     EDJE_ASPECT_CONTROL_HORIZONTAL EDJE_INPUT_HINT_SENSITIVE_DATA
     EDJE_INPUT_PANEL_LANG_ALPHABET EDJE_INPUT_PANEL_LAYOUT_NORMAL
     EDJE_INPUT_PANEL_LAYOUT_NUMBER EDJE_LOAD_ERROR_DOES_NOT_EXIST
     EDJE_LOAD_ERROR_UNKNOWN_FORMAT EDJE_TWEEN_MODE_DIVISOR_INTERP */
  /* Offset 26 gives the best switch position.  */
  switch (name[26]) {
  case 'A':
    if (memEQ(name, "EDJE_ACTION_TYPE_VG_ANIM_PAUSE", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_ACTION_TYPE_VG_ANIM_PAUSE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_INPUT_PANEL_LANG_ALPHABET", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_INPUT_PANEL_LANG_ALPHABET;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "EDJE_INPUT_HINT_SENSITIVE_DATA", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_INPUT_HINT_SENSITIVE_DATA;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NUMBER", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_NUMBER;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_ASPECT_CONTROL_HORIZONTAL", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_ASPECT_CONTROL_HORIZONTAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_FORCE", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_FORCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EDJE_ACTION_TYPE_DRAG_VAL_PAGE", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_ACTION_TYPE_DRAG_VAL_PAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NORMAL", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_NORMAL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_LOAD_ERROR_UNKNOWN_FORMAT", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_LOAD_ERROR_UNKNOWN_FORMAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_ACTION_TYPE_DRAG_VAL_STEP", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_ACTION_TYPE_DRAG_VAL_STEP;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_TWEEN_MODE_DIVISOR_INTERP", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_TWEEN_MODE_DIVISOR_INTERP;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "EDJE_LOAD_ERROR_DOES_NOT_EXIST", 30)) {
    /*                                         ^          */
      *iv_return = EDJE_LOAD_ERROR_DOES_NOT_EXIST;
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
     EDJE_ACTION_TYPE_PHYSICS_TORQUE EDJE_ACTION_TYPE_VG_ANIM_RESUME
     EDJE_ACTION_TYPE_VG_ANIM_REWIND EDJE_EXTERNAL_PARAM_TYPE_CHOICE
     EDJE_EXTERNAL_PARAM_TYPE_DOUBLE EDJE_EXTERNAL_PARAM_TYPE_STRING
     EDJE_INPUT_PANEL_LANG_AUTOMATIC EDJE_INPUT_PANEL_LAYOUT_INVALID
     EDJE_TEXT_AUTOCAPITAL_TYPE_NONE EDJE_TEXT_AUTOCAPITAL_TYPE_WORD
     EDJE_TEXT_EFFECT_OUTLINE_SHADOW */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'C':
    if (memEQ(name, "EDJE_EXTERNAL_PARAM_TYPE_CHOICE", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_EXTERNAL_PARAM_TYPE_CHOICE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "EDJE_EXTERNAL_PARAM_TYPE_DOUBLE", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_EXTERNAL_PARAM_TYPE_DOUBLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EDJE_TEXT_AUTOCAPITAL_TYPE_NONE", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_TEXT_AUTOCAPITAL_TYPE_NONE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TEXT_AUTOCAPITAL_TYPE_WORD", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_TEXT_AUTOCAPITAL_TYPE_WORD;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_INVALID", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_INVALID;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_INPUT_PANEL_LANG_AUTOMATIC", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_INPUT_PANEL_LANG_AUTOMATIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_ACTION_TYPE_VG_ANIM_RESUME", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_ACTION_TYPE_VG_ANIM_RESUME;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_ACTION_TYPE_VG_ANIM_REWIND", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_ACTION_TYPE_VG_ANIM_REWIND;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_EXTERNAL_PARAM_TYPE_STRING", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_EXTERNAL_PARAM_TYPE_STRING;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_TEXT_EFFECT_OUTLINE_SHADOW", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_TEXT_EFFECT_OUTLINE_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_TORQUE", 31)) {
    /*                                        ^            */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_TORQUE;
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
     EDJE_ACTION_TYPE_PHYSICS_IMPULSE EDJE_ACTION_TYPE_PHYSICS_ROT_SET
     EDJE_ACTION_TYPE_PHYSICS_VEL_SET EDJE_INPUT_PANEL_LAYOUT_DATETIME
     EDJE_INPUT_PANEL_LAYOUT_EMOTICON EDJE_INPUT_PANEL_LAYOUT_PASSWORD
     EDJE_INPUT_PANEL_LAYOUT_TERMINAL EDJE_TEXT_EFFECT_FAR_SOFT_SHADOW
     EDJE_TWEEN_MODE_OPT_FROM_CURRENT */
  /* Offset 27 gives the best switch position.  */
  switch (name[27]) {
  case 'E':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_DATETIME", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_DATETIME;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "EDJE_TEXT_EFFECT_FAR_SOFT_SHADOW", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_TEXT_EFFECT_FAR_SOFT_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_VEL_SET", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_VEL_SET;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_TERMINAL", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_TERMINAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_IMPULSE", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_IMPULSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_TWEEN_MODE_OPT_FROM_CURRENT", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_TWEEN_MODE_OPT_FROM_CURRENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_PASSWORD", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_PASSWORD;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_ROT_SET", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_ROT_SET;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_EMOTICON", 32)) {
    /*                                          ^           */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_EMOTICON;
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
     EDJE_ACTION_TYPE_VIBRATION_SAMPLE EDJE_LOAD_ERROR_INCOMPATIBLE_FILE
     EDJE_LOAD_ERROR_PERMISSION_DENIED EDJE_TWEEN_MODE_ACCELERATE_FACTOR
     EDJE_TWEEN_MODE_DECELERATE_FACTOR EDJE_TWEEN_MODE_SINUSOIDAL_FACTOR */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "EDJE_TWEEN_MODE_ACCELERATE_FACTOR", 33)) {
    /*                               ^                       */
      *iv_return = EDJE_TWEEN_MODE_ACCELERATE_FACTOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "EDJE_TWEEN_MODE_DECELERATE_FACTOR", 33)) {
    /*                               ^                       */
      *iv_return = EDJE_TWEEN_MODE_DECELERATE_FACTOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EDJE_LOAD_ERROR_INCOMPATIBLE_FILE", 33)) {
    /*                               ^                       */
      *iv_return = EDJE_LOAD_ERROR_INCOMPATIBLE_FILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EDJE_LOAD_ERROR_PERMISSION_DENIED", 33)) {
    /*                               ^                       */
      *iv_return = EDJE_LOAD_ERROR_PERMISSION_DENIED;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EDJE_TWEEN_MODE_SINUSOIDAL_FACTOR", 33)) {
    /*                               ^                       */
      *iv_return = EDJE_TWEEN_MODE_SINUSOIDAL_FACTOR;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "EDJE_ACTION_TYPE_VIBRATION_SAMPLE", 33)) {
    /*                               ^                       */
      *iv_return = EDJE_ACTION_TYPE_VIBRATION_SAMPLE;
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
     EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY EDJE_LOAD_ERROR_UNKNOWN_COLLECTION
     EDJE_OBJECT_TABLE_HOMOGENEOUS_ITEM EDJE_OBJECT_TABLE_HOMOGENEOUS_NONE */
  /* Offset 32 gives the best switch position.  */
  switch (name[32]) {
  case 'E':
    if (memEQ(name, "EDJE_OBJECT_TABLE_HOMOGENEOUS_ITEM", 34)) {
    /*                                               ^        */
      *iv_return = EDJE_OBJECT_TABLE_HOMOGENEOUS_ITEM;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY", 34)) {
    /*                                               ^        */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_OBJECT_TABLE_HOMOGENEOUS_NONE", 34)) {
    /*                                               ^        */
      *iv_return = EDJE_OBJECT_TABLE_HOMOGENEOUS_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_LOAD_ERROR_UNKNOWN_COLLECTION", 34)) {
    /*                                               ^        */
      *iv_return = EDJE_LOAD_ERROR_UNKNOWN_COLLECTION;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_35 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EDJE_INPUT_PANEL_LAYOUT_PHONENUMBER EDJE_INPUT_PANEL_RETURN_KEY_TYPE_GO
     EDJE_LOAD_ERROR_RECURSIVE_REFERENCE EDJE_OBJECT_TABLE_HOMOGENEOUS_TABLE
     EDJE_TEXT_AUTOCAPITAL_TYPE_SENTENCE */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'L':
    if (memEQ(name, "EDJE_TEXT_AUTOCAPITAL_TYPE_SENTENCE", 35)) {
    /*                                   ^                     */
      *iv_return = EDJE_TEXT_AUTOCAPITAL_TYPE_SENTENCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EDJE_OBJECT_TABLE_HOMOGENEOUS_TABLE", 35)) {
    /*                                   ^                     */
      *iv_return = EDJE_OBJECT_TABLE_HOMOGENEOUS_TABLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_PHONENUMBER", 35)) {
    /*                                   ^                     */
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_PHONENUMBER;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_LOAD_ERROR_RECURSIVE_REFERENCE", 35)) {
    /*                                   ^                     */
      *iv_return = EDJE_LOAD_ERROR_RECURSIVE_REFERENCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_GO", 35)) {
    /*                                   ^                     */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_GO;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_37 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EDJE_ACTION_TYPE_PHYSICS_FORCES_CLEAR
     EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DONE
     EDJE_INPUT_PANEL_RETURN_KEY_TYPE_JOIN
     EDJE_INPUT_PANEL_RETURN_KEY_TYPE_NEXT
     EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEND
     EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP */
  /* Offset 36 gives the best switch position.  */
  switch (name[36]) {
  case 'D':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEN", 36)) {
    /*                                                   D      */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEND;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DON", 36)) {
    /*                                                   E      */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_JOI", 36)) {
    /*                                                   N      */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_JOIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TO", 36)) {
    /*                                                   P      */
      *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_FORCES_CLEA", 36)) {
    /*                                                   R      */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_FORCES_CLEAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_NEX", 36)) {
    /*                                                   T      */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_NEXT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_39 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EDJE_ACTION_TYPE_PHYSICS_TORQUE_IMPULSE
     EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEARCH
     EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SIGNIN
     EDJE_TEXT_AUTOCAPITAL_TYPE_ALLCHARACTER
     EDJE_TEXT_EFFECT_SHADOW_DIRECTION_RIGHT */
  /* Offset 36 gives the best switch position.  */
  switch (name[36]) {
  case 'G':
    if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_RIGHT", 39)) {
    /*                                                   ^         */
      *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_TORQUE_IMPULSE", 39)) {
    /*                                                   ^         */
      *iv_return = EDJE_ACTION_TYPE_PHYSICS_TORQUE_IMPULSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SIGNIN", 39)) {
    /*                                                   ^         */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SIGNIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEARCH", 39)) {
    /*                                                   ^         */
      *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEARCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EDJE_TEXT_AUTOCAPITAL_TYPE_ALLCHARACTER", 39)) {
    /*                                                   ^         */
      *iv_return = EDJE_TEXT_AUTOCAPITAL_TYPE_ALLCHARACTER;
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
            {name=>"EDJE_ACTION_TYPE_ACTION_STOP", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_DRAG_VAL_PAGE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_DRAG_VAL_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_DRAG_VAL_STEP", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_FOCUS_OBJECT", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_FOCUS_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_LAST", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_MO", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PARAM_COPY", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PARAM_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_ANG_VEL_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_FORCE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_FORCES_CLEAR", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_IMPULSE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_ROT_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_STOP", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_TORQUE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_TORQUE_IMPULSE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_PHYSICS_VEL_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_RESERVED00", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_SCRIPT", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_SIGNAL_EMIT", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_SOUND_SAMPLE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_SOUND_TONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_STATE_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VG_ANIM_LOOP", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VG_ANIM_PAUSE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VG_ANIM_PLAY", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VG_ANIM_RESUME", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VG_ANIM_REWIND", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VG_ANIM_STOP", type=>"IV", macro=>"1"},
            {name=>"EDJE_ACTION_TYPE_VIBRATION_SAMPLE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ASPECT_CONTROL_BOTH", type=>"IV", macro=>"1"},
            {name=>"EDJE_ASPECT_CONTROL_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_ASPECT_CONTROL_NEITHER", type=>"IV", macro=>"1"},
            {name=>"EDJE_ASPECT_CONTROL_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_ASPECT_CONTROL_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_ALERT", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_ALL", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_BACKGROUND", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_EFFECT", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_FOREGROUND", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_INPUT", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_INTERFACE", type=>"IV", macro=>"1"},
            {name=>"EDJE_CHANNEL_MUSIC", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_MAIN", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_PREEDIT_END", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_PREEDIT_START", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_SELECTION_BEGIN", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_SELECTION_END", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_USER", type=>"IV", macro=>"1"},
            {name=>"EDJE_CURSOR_USER_EXTRA", type=>"IV", macro=>"1"},
            {name=>"EDJE_DRAG_DIR_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_DRAG_DIR_X", type=>"IV", macro=>"1"},
            {name=>"EDJE_DRAG_DIR_XY", type=>"IV", macro=>"1"},
            {name=>"EDJE_DRAG_DIR_Y", type=>"IV", macro=>"1"},
            {name=>"EDJE_EXTERNAL_PARAM_TYPE_BOOL", type=>"IV", macro=>"1"},
            {name=>"EDJE_EXTERNAL_PARAM_TYPE_CHOICE", type=>"IV", macro=>"1"},
            {name=>"EDJE_EXTERNAL_PARAM_TYPE_DOUBLE", type=>"IV", macro=>"1"},
            {name=>"EDJE_EXTERNAL_PARAM_TYPE_INT", type=>"IV", macro=>"1"},
            {name=>"EDJE_EXTERNAL_PARAM_TYPE_MAX", type=>"IV", macro=>"1"},
            {name=>"EDJE_EXTERNAL_PARAM_TYPE_STRING", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_HINT_AUTO_COMPLETE", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_HINT_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_HINT_SENSITIVE_DATA", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LANG_ALPHABET", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LANG_AUTOMATIC", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_DATETIME", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_EMAIL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_EMOTICON", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_HEX", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_INVALID", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_IP", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_MONTH", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NORMAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_NORMAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NUMBER", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED_AND_DECIMAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_PASSWORD", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NUMBERONLY", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_PHONENUMBER", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_TERMINAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_URL", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_LAYOUT_VOICE", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_GO", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_JOIN", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_LOGIN", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_NEXT", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEARCH", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SEND", type=>"IV", macro=>"1"},
            {name=>"EDJE_INPUT_PANEL_RETURN_KEY_TYPE_SIGNIN", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_CORRUPT_FILE", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_DOES_NOT_EXIST", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_GENERIC", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_INCOMPATIBLE_FILE", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_PERMISSION_DENIED", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_RECURSIVE_REFERENCE", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_UNKNOWN_COLLECTION", type=>"IV", macro=>"1"},
            {name=>"EDJE_LOAD_ERROR_UNKNOWN_FORMAT", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_FLOAT", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_FLOAT_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_INT", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_INT_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_SIGNAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_STRING", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_STRING_FLOAT", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_STRING_FLOAT_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_STRING_INT", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_STRING_INT_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_MESSAGE_STRING_SET", type=>"IV", macro=>"1"},
            {name=>"EDJE_OBJECT_TABLE_HOMOGENEOUS_ITEM", type=>"IV", macro=>"1"},
            {name=>"EDJE_OBJECT_TABLE_HOMOGENEOUS_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_OBJECT_TABLE_HOMOGENEOUS_TABLE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_AUTOCAPITAL_TYPE_ALLCHARACTER", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_AUTOCAPITAL_TYPE_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_AUTOCAPITAL_TYPE_SENTENCE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_AUTOCAPITAL_TYPE_WORD", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_FAR_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_FAR_SOFT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_GLOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_LAST", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_OUTLINE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_OUTLINE_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_OUTLINE_SOFT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_PLAIN", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM_LEFT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_LEFT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_LEFT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SOFT_OUTLINE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_EFFECT_SOFT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_FILTER_FORMAT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_FILTER_MARKUP", type=>"IV", macro=>"1"},
            {name=>"EDJE_TEXT_FILTER_TEXT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_ACCELERATE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_ACCELERATE_FACTOR", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_BOUNCE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_CUBIC_BEZIER", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_DECELERATE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_DECELERATE_FACTOR", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_DIVISOR_INTERP", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_LAST", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_LINEAR", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_MASK", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_OPT_FROM_CURRENT", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_SINUSOIDAL", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_SINUSOIDAL_FACTOR", type=>"IV", macro=>"1"},
            {name=>"EDJE_TWEEN_MODE_SPRING", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("pEFL::Edje", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("pEFL::Edje", $types);
__END__
   */

  switch (len) {
  case 15:
    /* Names all of length 15.  */
    /* EDJE_DRAG_DIR_X EDJE_DRAG_DIR_Y */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'X':
      if (memEQ(name, "EDJE_DRAG_DIR_", 14)) {
      /*                             X      */
        *iv_return = EDJE_DRAG_DIR_X;
        return PERL_constant_ISIV;
      }
      break;
    case 'Y':
      if (memEQ(name, "EDJE_DRAG_DIR_", 14)) {
      /*                             Y      */
        *iv_return = EDJE_DRAG_DIR_Y;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    if (memEQ(name, "EDJE_MESSAGE_NONE", 17)) {
      *iv_return = EDJE_MESSAGE_NONE;
      return PERL_constant_ISIV;
    }
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
    return constant_35 (aTHX_ name, iv_return);
    break;
  case 36:
    /* Names all of length 36.  */
    /* EDJE_ACTION_TYPE_PHYSICS_ANG_VEL_SET
       EDJE_TEXT_EFFECT_OUTLINE_SOFT_SHADOW */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'O':
      if (memEQ(name, "EDJE_TEXT_EFFECT_OUTLINE_SOFT_SHADOW", 36)) {
      /*                                ^                         */
        *iv_return = EDJE_TEXT_EFFECT_OUTLINE_SOFT_SHADOW;
        return PERL_constant_ISIV;
      }
      break;
    case 'P':
      if (memEQ(name, "EDJE_ACTION_TYPE_PHYSICS_ANG_VEL_SET", 36)) {
      /*                                ^                         */
        *iv_return = EDJE_ACTION_TYPE_PHYSICS_ANG_VEL_SET;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 37:
    return constant_37 (aTHX_ name, iv_return);
    break;
  case 38:
    /* Names all of length 38.  */
    /* EDJE_INPUT_PANEL_RETURN_KEY_TYPE_LOGIN
       EDJE_TEXT_EFFECT_SHADOW_DIRECTION_LEFT */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'T':
      if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_LEFT", 38)) {
      /*                       ^                                    */
        *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_LEFT;
        return PERL_constant_ISIV;
      }
      break;
    case 'U':
      if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_LOGIN", 38)) {
      /*                       ^                                    */
        *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_LOGIN;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 39:
    return constant_39 (aTHX_ name, iv_return);
    break;
  case 40:
    /* Names all of length 40.  */
    /* EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DEFAULT
       EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'T':
      if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM", 40)) {
      /*                       ^                                      */
        *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM;
        return PERL_constant_ISIV;
      }
      break;
    case 'U':
      if (memEQ(name, "EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DEFAULT", 40)) {
      /*                       ^                                      */
        *iv_return = EDJE_INPUT_PANEL_RETURN_KEY_TYPE_DEFAULT;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 42:
    /* Names all of length 42.  */
    /* EDJE_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED
       EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_LEFT */
    /* Offset 40 gives the best switch position.  */
    switch (name[40]) {
    case 'E':
      if (memEQ(name, "EDJE_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED", 42)) {
      /*                                                       ^        */
        *iv_return = EDJE_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED;
        return PERL_constant_ISIV;
      }
      break;
    case 'F':
      if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_LEFT", 42)) {
      /*                                                       ^        */
        *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_LEFT;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 43:
    if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_RIGHT", 43)) {
      *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_TOP_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 45:
    if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM_LEFT", 45)) {
      *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 46:
    if (memEQ(name, "EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM_RIGHT", 46)) {
      *iv_return = EDJE_TEXT_EFFECT_SHADOW_DIRECTION_BOTTOM_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 47:
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_NORMAL", 47)) {
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_NORMAL;
      return PERL_constant_ISIV;
    }
    break;
  case 49:
    /* Names all of length 49.  */
    /* EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME
       EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL */
    /* Offset 26 gives the best switch position.  */
    switch (name[26]) {
    case 'R':
      if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME", 49)) {
      /*                                         ^                             */
        *iv_return = EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_FILENAME;
        return PERL_constant_ISIV;
      }
      break;
    case 'S':
      if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL", 49)) {
      /*                                         ^                             */
        *iv_return = EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NORMAL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 51:
    /* Names all of length 51.  */
    /* EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL
       EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED */
    /* Offset 48 gives the best switch position.  */
    switch (name[48]) {
    case 'M':
      if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL", 51)) {
      /*                                                               ^         */
        *iv_return = EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_NORMAL;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED", 51)) {
      /*                                                               ^         */
        *iv_return = EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 52:
    /* Names all of length 52.  */
    /* EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME
       EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL */
    /* Offset 28 gives the best switch position.  */
    switch (name[28]) {
    case 'A':
      if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME", 52)) {
      /*                                           ^                              */
        *iv_return = EDJE_INPUT_PANEL_LAYOUT_NORMAL_VARIATION_PERSON_NAME;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL", 52)) {
      /*                                           ^                              */
        *iv_return = EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_DECIMAL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 53:
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NUMBERONLY", 53)) {
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_PASSWORD_VARIATION_NUMBERONLY;
      return PERL_constant_ISIV;
    }
    break;
  case 63:
    if (memEQ(name, "EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED_AND_DECIMAL", 63)) {
      *iv_return = EDJE_INPUT_PANEL_LAYOUT_NUMBERONLY_VARIATION_SIGNED_AND_DECIMAL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

