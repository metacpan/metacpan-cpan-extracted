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
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EVAS_CALLBACK_FREE EVAS_CALLBACK_HIDE EVAS_CALLBACK_HOLD
     EVAS_CALLBACK_LAST EVAS_CALLBACK_MOVE EVAS_CALLBACK_SHOW */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'D':
    if (memEQ(name, "EVAS_CALLBACK_HIDE", 18)) {
    /*                               ^        */
      *iv_return = EVAS_CALLBACK_HIDE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_CALLBACK_FREE", 18)) {
    /*                               ^        */
      *iv_return = EVAS_CALLBACK_FREE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EVAS_CALLBACK_HOLD", 18)) {
    /*                               ^        */
      *iv_return = EVAS_CALLBACK_HOLD;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EVAS_CALLBACK_SHOW", 18)) {
    /*                               ^        */
      *iv_return = EVAS_CALLBACK_SHOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EVAS_CALLBACK_LAST", 18)) {
    /*                               ^        */
      *iv_return = EVAS_CALLBACK_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "EVAS_CALLBACK_MOVE", 18)) {
    /*                               ^        */
      *iv_return = EVAS_CALLBACK_MOVE;
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
     EVAS_CALLBACK_KEY_UP EVAS_CALLBACK_RESIZE EVAS_IMAGE_ORIENT_90
     EVAS_LOAD_ERROR_NONE EVAS_TEXT_STYLE_GLOW */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'G':
    if (memEQ(name, "EVAS_TEXT_STYLE_GLOW", 20)) {
    /*                               ^          */
      *iv_return = EVAS_TEXT_STYLE_GLOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_LOAD_ERROR_NONE", 20)) {
    /*                               ^          */
      *iv_return = EVAS_LOAD_ERROR_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EVAS_CALLBACK_RESIZE", 20)) {
    /*                               ^          */
      *iv_return = EVAS_CALLBACK_RESIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_IMAGE_ORIENT_90", 20)) {
    /*                               ^          */
      *iv_return = EVAS_IMAGE_ORIENT_90;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "EVAS_CALLBACK_KEY_UP", 20)) {
    /*                               ^          */
      *iv_return = EVAS_CALLBACK_KEY_UP;
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
     EVAS_BORDER_FILL_NONE EVAS_CALLBACK_RESTACK EVAS_IMAGE_ORIENT_180
     EVAS_IMAGE_ORIENT_270 EVAS_TEXT_STYLE_PLAIN */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case '7':
    if (memEQ(name, "EVAS_IMAGE_ORIENT_270", 21)) {
    /*                                  ^        */
      *iv_return = EVAS_IMAGE_ORIENT_270;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "EVAS_IMAGE_ORIENT_180", 21)) {
    /*                                  ^        */
      *iv_return = EVAS_IMAGE_ORIENT_180;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "EVAS_CALLBACK_RESTACK", 21)) {
    /*                                  ^        */
      *iv_return = EVAS_CALLBACK_RESTACK;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EVAS_TEXT_STYLE_PLAIN", 21)) {
    /*                                  ^        */
      *iv_return = EVAS_TEXT_STYLE_PLAIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_BORDER_FILL_NONE", 21)) {
    /*                                  ^        */
      *iv_return = EVAS_BORDER_FILL_NONE;
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
     EVAS_BORDER_FILL_SOLID EVAS_CALLBACK_FOCUS_IN EVAS_CALLBACK_KEY_DOWN
     EVAS_CALLBACK_MOUSE_IN EVAS_CALLBACK_MOUSE_UP EVAS_CALLBACK_MULTI_UP
     EVAS_DISPLAY_MODE_NONE EVAS_FONT_HINTING_AUTO EVAS_FONT_HINTING_NONE
     EVAS_IMAGE_ORIENT_NONE EVAS_NATIVE_SURFACE_WL EVAS_TEXT_STYLE_SHADOW */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_WL", 22)) {
    /*                               ^            */
      *iv_return = EVAS_NATIVE_SURFACE_WL;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "EVAS_CALLBACK_FOCUS_IN", 22)) {
    /*                               ^            */
      *iv_return = EVAS_CALLBACK_FOCUS_IN;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_DISPLAY_MODE_NONE", 22)) {
    /*                               ^            */
      *iv_return = EVAS_DISPLAY_MODE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "EVAS_FONT_HINTING_AUTO", 22)) {
    /*                               ^            */
      *iv_return = EVAS_FONT_HINTING_AUTO;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_FONT_HINTING_NONE", 22)) {
    /*                               ^            */
      *iv_return = EVAS_FONT_HINTING_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EVAS_CALLBACK_MULTI_UP", 22)) {
    /*                               ^            */
      *iv_return = EVAS_CALLBACK_MULTI_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW", 22)) {
    /*                               ^            */
      *iv_return = EVAS_TEXT_STYLE_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_IMAGE_ORIENT_NONE", 22)) {
    /*                               ^            */
      *iv_return = EVAS_IMAGE_ORIENT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EVAS_CALLBACK_MOUSE_IN", 22)) {
    /*                               ^            */
      *iv_return = EVAS_CALLBACK_MOUSE_IN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_CALLBACK_MOUSE_UP", 22)) {
    /*                               ^            */
      *iv_return = EVAS_CALLBACK_MOUSE_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "EVAS_CALLBACK_KEY_DOWN", 22)) {
    /*                               ^            */
      *iv_return = EVAS_CALLBACK_KEY_DOWN;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "EVAS_BORDER_FILL_SOLID", 22)) {
    /*                               ^            */
      *iv_return = EVAS_BORDER_FILL_SOLID;
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
     EVAS_BIDI_DIRECTION_LTR EVAS_BIDI_DIRECTION_RTL EVAS_CALLBACK_FOCUS_OUT
     EVAS_CALLBACK_MOUSE_OUT EVAS_LOAD_ERROR_GENERIC EVAS_NATIVE_SURFACE_TBM
     EVAS_NATIVE_SURFACE_X11 EVAS_TEXTBLOCK_TEXT_RAW EVAS_TEXT_STYLE_OUTLINE
     EVAS_VIDEO_SURFACE_CLIP EVAS_VIDEO_SURFACE_MOVE */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case '1':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_X1", 22)) {
    /*                                     1      */
      *iv_return = EVAS_NATIVE_SURFACE_X11;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "EVAS_LOAD_ERROR_GENERI", 22)) {
    /*                                     C      */
      *iv_return = EVAS_LOAD_ERROR_GENERIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_TEXT_STYLE_OUTLIN", 22)) {
    /*                                     E      */
      *iv_return = EVAS_TEXT_STYLE_OUTLINE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_VIDEO_SURFACE_MOV", 22)) {
    /*                                     E      */
      *iv_return = EVAS_VIDEO_SURFACE_MOVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EVAS_BIDI_DIRECTION_RT", 22)) {
    /*                                     L      */
      *iv_return = EVAS_BIDI_DIRECTION_RTL;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_TB", 22)) {
    /*                                     M      */
      *iv_return = EVAS_NATIVE_SURFACE_TBM;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EVAS_VIDEO_SURFACE_CLI", 22)) {
    /*                                     P      */
      *iv_return = EVAS_VIDEO_SURFACE_CLIP;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EVAS_BIDI_DIRECTION_LT", 22)) {
    /*                                     R      */
      *iv_return = EVAS_BIDI_DIRECTION_LTR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_CALLBACK_FOCUS_OU", 22)) {
    /*                                     T      */
      *iv_return = EVAS_CALLBACK_FOCUS_OUT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_CALLBACK_MOUSE_OU", 22)) {
    /*                                     T      */
      *iv_return = EVAS_CALLBACK_MOUSE_OUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "EVAS_TEXTBLOCK_TEXT_RA", 22)) {
    /*                                     W      */
      *iv_return = EVAS_TEXTBLOCK_TEXT_RAW;
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
     EVAS_ASPECT_CONTROL_BOTH EVAS_ASPECT_CONTROL_NONE EVAS_BORDER_FILL_DEFAULT
     EVAS_BUTTON_DOUBLE_CLICK EVAS_BUTTON_TRIPLE_CLICK EVAS_CALLBACK_MOUSE_DOWN
     EVAS_CALLBACK_MOUSE_MOVE EVAS_CALLBACK_MULTI_DOWN EVAS_CALLBACK_MULTI_MOVE
     EVAS_CALLBACK_RENDER_PRE EVAS_DISPLAY_MODE_EXPAND EVAS_IMAGE_FLIP_VERTICAL
     EVAS_NATIVE_SURFACE_NONE EVAS_VIDEO_SURFACE_BELOW */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'A':
    if (memEQ(name, "EVAS_VIDEO_SURFACE_BELOW", 24)) {
    /*                              ^               */
      *iv_return = EVAS_VIDEO_SURFACE_BELOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "EVAS_BUTTON_DOUBLE_CLICK", 24)) {
    /*                              ^               */
      *iv_return = EVAS_BUTTON_DOUBLE_CLICK;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "EVAS_DISPLAY_MODE_EXPAND", 24)) {
    /*                              ^               */
      *iv_return = EVAS_DISPLAY_MODE_EXPAND;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_CALLBACK_RENDER_PRE", 24)) {
    /*                              ^               */
      *iv_return = EVAS_CALLBACK_RENDER_PRE;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_NONE", 24)) {
    /*                              ^               */
      *iv_return = EVAS_NATIVE_SURFACE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EVAS_BORDER_FILL_DEFAULT", 24)) {
    /*                              ^               */
      *iv_return = EVAS_BORDER_FILL_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EVAS_CALLBACK_MOUSE_DOWN", 24)) {
    /*                              ^               */
      *iv_return = EVAS_CALLBACK_MOUSE_DOWN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_CALLBACK_MOUSE_MOVE", 24)) {
    /*                              ^               */
      *iv_return = EVAS_CALLBACK_MOUSE_MOVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EVAS_BUTTON_TRIPLE_CLICK", 24)) {
    /*                              ^               */
      *iv_return = EVAS_BUTTON_TRIPLE_CLICK;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_ASPECT_CONTROL_BOTH", 24)) {
    /*                              ^               */
      *iv_return = EVAS_ASPECT_CONTROL_BOTH;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_ASPECT_CONTROL_NONE", 24)) {
    /*                              ^               */
      *iv_return = EVAS_ASPECT_CONTROL_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EVAS_CALLBACK_MULTI_DOWN", 24)) {
    /*                              ^               */
      *iv_return = EVAS_CALLBACK_MULTI_DOWN;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_CALLBACK_MULTI_MOVE", 24)) {
    /*                              ^               */
      *iv_return = EVAS_CALLBACK_MULTI_MOVE;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "EVAS_IMAGE_FLIP_VERTICAL", 24)) {
    /*                              ^               */
      *iv_return = EVAS_IMAGE_FLIP_VERTICAL;
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
     EVAS_CALLBACK_AXIS_UPDATE EVAS_CALLBACK_MOUSE_WHEEL
     EVAS_CALLBACK_RENDER_POST EVAS_IMAGE_FLIP_TRANSPOSE
     EVAS_LOAD_ERROR_CANCELLED EVAS_TEXTBLOCK_TEXT_PLAIN
     EVAS_VIDEO_SURFACE_RESIZE */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'C':
    if (memEQ(name, "EVAS_LOAD_ERROR_CANCELLED", 25)) {
    /*                               ^               */
      *iv_return = EVAS_LOAD_ERROR_CANCELLED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_VIDEO_SURFACE_RESIZE", 25)) {
    /*                               ^               */
      *iv_return = EVAS_VIDEO_SURFACE_RESIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_TEXTBLOCK_TEXT_PLAIN", 25)) {
    /*                               ^               */
      *iv_return = EVAS_TEXTBLOCK_TEXT_PLAIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EVAS_CALLBACK_AXIS_UPDATE", 25)) {
    /*                               ^               */
      *iv_return = EVAS_CALLBACK_AXIS_UPDATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_CALLBACK_RENDER_POST", 25)) {
    /*                               ^               */
      *iv_return = EVAS_CALLBACK_RENDER_POST;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_IMAGE_FLIP_TRANSPOSE", 25)) {
    /*                               ^               */
      *iv_return = EVAS_IMAGE_FLIP_TRANSPOSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EVAS_CALLBACK_MOUSE_WHEEL", 25)) {
    /*                               ^               */
      *iv_return = EVAS_CALLBACK_MOUSE_WHEEL;
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
     EVAS_CALLBACK_IMAGE_RESIZE EVAS_DISPLAY_MODE_COMPRESS
     EVAS_FONT_HINTING_BYTECODE EVAS_IMAGE_FLIP_HORIZONTAL
     EVAS_IMAGE_FLIP_TRANSVERSE EVAS_NATIVE_SURFACE_EVASGL
     EVAS_NATIVE_SURFACE_OPENGL EVAS_TEXTBLOCK_TEXT_MARKUP
     EVAS_TEXT_STYLE_FAR_SHADOW */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'D':
    if (memEQ(name, "EVAS_TEXT_STYLE_FAR_SHADOW", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_TEXT_STYLE_FAR_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_DISPLAY_MODE_COMPRESS", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_DISPLAY_MODE_COMPRESS;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EVAS_CALLBACK_IMAGE_RESIZE", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_CALLBACK_IMAGE_RESIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "EVAS_TEXTBLOCK_TEXT_MARKUP", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_TEXTBLOCK_TEXT_MARKUP;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_OPENGL", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_NATIVE_SURFACE_OPENGL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EVAS_FONT_HINTING_BYTECODE", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_FONT_HINTING_BYTECODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EVAS_IMAGE_FLIP_TRANSVERSE", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_IMAGE_FLIP_TRANSVERSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_EVASGL", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_NATIVE_SURFACE_EVASGL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_IMAGE_FLIP_HORIZONTAL", 26)) {
    /*                                      ^         */
      *iv_return = EVAS_IMAGE_FLIP_HORIZONTAL;
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
     EVAS_ASPECT_CONTROL_NEITHER EVAS_BIDI_DIRECTION_INHERIT
     EVAS_BIDI_DIRECTION_NATURAL EVAS_BIDI_DIRECTION_NEUTRAL
     EVAS_TEXTBLOCK_CURSOR_UNDER EVAS_TEXT_STYLE_SOFT_SHADOW */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'A':
    if (memEQ(name, "EVAS_TEXT_STYLE_SOFT_SHADOW", 27)) {
    /*                                      ^          */
      *iv_return = EVAS_TEXT_STYLE_SOFT_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_BIDI_DIRECTION_INHERIT", 27)) {
    /*                                      ^          */
      *iv_return = EVAS_BIDI_DIRECTION_INHERIT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_TEXTBLOCK_CURSOR_UNDER", 27)) {
    /*                                      ^          */
      *iv_return = EVAS_TEXTBLOCK_CURSOR_UNDER;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_ASPECT_CONTROL_NEITHER", 27)) {
    /*                                      ^          */
      *iv_return = EVAS_ASPECT_CONTROL_NEITHER;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_BIDI_DIRECTION_NEUTRAL", 27)) {
    /*                                      ^          */
      *iv_return = EVAS_BIDI_DIRECTION_NEUTRAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EVAS_BIDI_DIRECTION_NATURAL", 27)) {
    /*                                      ^          */
      *iv_return = EVAS_BIDI_DIRECTION_NATURAL;
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
     EVAS_ASPECT_CONTROL_VERTICAL EVAS_CALLBACK_DEVICE_CHANGED
     EVAS_CALLBACK_IMAGE_UNLOADED EVAS_IMAGE_CONTENT_HINT_NONE
     EVAS_LOAD_ERROR_CORRUPT_FILE EVAS_TEXTBLOCK_CURSOR_BEFORE
     EVAS_TEXT_STYLE_SOFT_OUTLINE */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "EVAS_CALLBACK_IMAGE_UNLOADED", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_CALLBACK_IMAGE_UNLOADED;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "EVAS_LOAD_ERROR_CORRUPT_FILE", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_LOAD_ERROR_CORRUPT_FILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_IMAGE_CONTENT_HINT_NONE", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_IMAGE_CONTENT_HINT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EVAS_ASPECT_CONTROL_VERTICAL", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_ASPECT_CONTROL_VERTICAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EVAS_TEXT_STYLE_SOFT_OUTLINE", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_TEXT_STYLE_SOFT_OUTLINE;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EVAS_TEXTBLOCK_CURSOR_BEFORE", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_TEXTBLOCK_CURSOR_BEFORE;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "EVAS_CALLBACK_DEVICE_CHANGED", 28)) {
    /*                               ^                  */
      *iv_return = EVAS_CALLBACK_DEVICE_CHANGED;
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
     EVAS_CALLBACK_CANVAS_FOCUS_IN EVAS_CALLBACK_IMAGE_PRELOADED
     EVAS_DISPLAY_MODE_DONT_CHANGE EVAS_NATIVE_SURFACE_WL_DMABUF */
  /* Offset 28 gives the best switch position.  */
  switch (name[28]) {
  case 'D':
    if (memEQ(name, "EVAS_CALLBACK_IMAGE_PRELOADE", 28)) {
    /*                                           D      */
      *iv_return = EVAS_CALLBACK_IMAGE_PRELOADED;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_DISPLAY_MODE_DONT_CHANG", 28)) {
    /*                                           E      */
      *iv_return = EVAS_DISPLAY_MODE_DONT_CHANGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_WL_DMABU", 28)) {
    /*                                           F      */
      *iv_return = EVAS_NATIVE_SURFACE_WL_DMABUF;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_CALLBACK_CANVAS_FOCUS_I", 28)) {
    /*                                           N      */
      *iv_return = EVAS_CALLBACK_CANVAS_FOCUS_IN;
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
     EVAS_ASPECT_CONTROL_HORIZONTAL EVAS_CALLBACK_CANVAS_FOCUS_OUT
     EVAS_CALLBACK_RENDER_FLUSH_PRE EVAS_IMAGE_CONTENT_HINT_STATIC
     EVAS_LOAD_ERROR_DOES_NOT_EXIST EVAS_LOAD_ERROR_UNKNOWN_FORMAT
     EVAS_TEXT_STYLE_OUTLINE_SHADOW */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'E':
    if (memEQ(name, "EVAS_TEXT_STYLE_OUTLINE_SHADOW", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_TEXT_STYLE_OUTLINE_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EVAS_CALLBACK_RENDER_FLUSH_PRE", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_CALLBACK_RENDER_FLUSH_PRE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_LOAD_ERROR_UNKNOWN_FORMAT", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_LOAD_ERROR_UNKNOWN_FORMAT;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EVAS_CALLBACK_CANVAS_FOCUS_OUT", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_CALLBACK_CANVAS_FOCUS_OUT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EVAS_LOAD_ERROR_DOES_NOT_EXIST", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_LOAD_ERROR_DOES_NOT_EXIST;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "EVAS_ASPECT_CONTROL_HORIZONTAL", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_ASPECT_CONTROL_HORIZONTAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EVAS_IMAGE_CONTENT_HINT_STATIC", 30)) {
    /*                                     ^              */
      *iv_return = EVAS_IMAGE_CONTENT_HINT_STATIC;
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
     EVAS_CALLBACK_RENDER_FLUSH_POST EVAS_IMAGE_CONTENT_HINT_DYNAMIC
     EVAS_TEXT_STYLE_FAR_SOFT_SHADOW */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'F':
    if (memEQ(name, "EVAS_CALLBACK_RENDER_FLUSH_POST", 31)) {
    /*                                    ^                */
      *iv_return = EVAS_CALLBACK_RENDER_FLUSH_POST;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EVAS_IMAGE_CONTENT_HINT_DYNAMIC", 31)) {
    /*                                    ^                */
      *iv_return = EVAS_IMAGE_CONTENT_HINT_DYNAMIC;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EVAS_TEXT_STYLE_FAR_SOFT_SHADOW", 31)) {
    /*                                    ^                */
      *iv_return = EVAS_TEXT_STYLE_FAR_SOFT_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_36 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_IN EVAS_CALLBACK_CANVAS_VIEWPORT_RESIZE
     EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'D':
    if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP", 36)) {
    /*                                      ^                   */
      *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EVAS_CALLBACK_CANVAS_VIEWPORT_RESIZE", 36)) {
    /*                                      ^                   */
      *iv_return = EVAS_CALLBACK_CANVAS_VIEWPORT_RESIZE;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_IN", 36)) {
    /*                                      ^                   */
      *iv_return = EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_IN;
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
     EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_OUT
     EVAS_NATIVE_SURFACE_STATUS_SCANOUT_ON
     EVAS_TEXT_STYLE_SHADOW_DIRECTION_LEFT */
  /* Offset 31 gives the best switch position.  */
  switch (name[31]) {
  case 'N':
    if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_LEFT", 37)) {
    /*                                              ^            */
      *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "EVAS_NATIVE_SURFACE_STATUS_SCANOUT_ON", 37)) {
    /*                                              ^            */
      *iv_return = EVAS_NATIVE_SURFACE_STATUS_SCANOUT_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_OUT", 37)) {
    /*                                              ^            */
      *iv_return = EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_OUT;
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
            {name=>"EVAS_ASPECT_CONTROL_BOTH", type=>"IV", macro=>"1"},
            {name=>"EVAS_ASPECT_CONTROL_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"EVAS_ASPECT_CONTROL_NEITHER", type=>"IV", macro=>"1"},
            {name=>"EVAS_ASPECT_CONTROL_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_ASPECT_CONTROL_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"EVAS_BIDI_DIRECTION_INHERIT", type=>"IV", macro=>"1"},
            {name=>"EVAS_BIDI_DIRECTION_LTR", type=>"IV", macro=>"1"},
            {name=>"EVAS_BIDI_DIRECTION_NATURAL", type=>"IV", macro=>"1"},
            {name=>"EVAS_BIDI_DIRECTION_NEUTRAL", type=>"IV", macro=>"1"},
            {name=>"EVAS_BIDI_DIRECTION_RTL", type=>"IV", macro=>"1"},
            {name=>"EVAS_BORDER_FILL_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"EVAS_BORDER_FILL_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_BORDER_FILL_SOLID", type=>"IV", macro=>"1"},
            {name=>"EVAS_BUTTON_DOUBLE_CLICK", type=>"IV", macro=>"1"},
            {name=>"EVAS_BUTTON_TRIPLE_CLICK", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_AXIS_UPDATE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_CANVAS_FOCUS_IN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_CANVAS_FOCUS_OUT", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_IN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_CANVAS_OBJECT_FOCUS_OUT", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_CANVAS_VIEWPORT_RESIZE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_CHANGED_SIZE_HINTS", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_DEL", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_DEVICE_CHANGED", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_FOCUS_IN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_FOCUS_OUT", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_FREE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_HIDE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_HOLD", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_IMAGE_PRELOADED", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_IMAGE_RESIZE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_IMAGE_UNLOADED", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_KEY_DOWN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_KEY_UP", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_LAST", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOUSE_DOWN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOUSE_IN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOUSE_MOVE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOUSE_OUT", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOUSE_UP", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOUSE_WHEEL", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MOVE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MULTI_DOWN", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MULTI_MOVE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_MULTI_UP", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_RENDER_FLUSH_POST", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_RENDER_FLUSH_PRE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_RENDER_POST", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_RENDER_PRE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_RESIZE", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_RESTACK", type=>"IV", macro=>"1"},
            {name=>"EVAS_CALLBACK_SHOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_DISPLAY_MODE_COMPRESS", type=>"IV", macro=>"1"},
            {name=>"EVAS_DISPLAY_MODE_DONT_CHANGE", type=>"IV", macro=>"1"},
            {name=>"EVAS_DISPLAY_MODE_EXPAND", type=>"IV", macro=>"1"},
            {name=>"EVAS_DISPLAY_MODE_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_FONT_HINTING_AUTO", type=>"IV", macro=>"1"},
            {name=>"EVAS_FONT_HINTING_BYTECODE", type=>"IV", macro=>"1"},
            {name=>"EVAS_FONT_HINTING_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_HINT_EXPAND", type=>"IV", macro=>"1"},
            {name=>"EVAS_HINT_FILL", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_CONTENT_HINT_DYNAMIC", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_CONTENT_HINT_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_CONTENT_HINT_STATIC", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_FLIP_HORIZONTAL", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_FLIP_TRANSPOSE", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_FLIP_TRANSVERSE", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_FLIP_VERTICAL", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_ORIENT_0", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_ORIENT_180", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_ORIENT_270", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_ORIENT_90", type=>"IV", macro=>"1"},
            {name=>"EVAS_IMAGE_ORIENT_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_CANCELLED", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_CORRUPT_FILE", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_DOES_NOT_EXIST", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_GENERIC", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_PERMISSION_DENIED", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED", type=>"IV", macro=>"1"},
            {name=>"EVAS_LOAD_ERROR_UNKNOWN_FORMAT", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_EVASGL", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_NONE", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_OPENGL", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_STATUS_PLANE_ASSIGN", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_STATUS_PLANE_RELEASE", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_STATUS_SCANOUT_OFF", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_STATUS_SCANOUT_ON", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_TBM", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_WL", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_WL_DMABUF", type=>"IV", macro=>"1"},
            {name=>"EVAS_NATIVE_SURFACE_X11", type=>"IV", macro=>"1"},
            {name=>"EVAS_RENDER_BLEND", type=>"IV", macro=>"1"},
            {name=>"EVAS_RENDER_COPY", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXTBLOCK_CURSOR_BEFORE", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXTBLOCK_CURSOR_UNDER", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXTBLOCK_TEXT_MARKUP", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXTBLOCK_TEXT_PLAIN", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXTBLOCK_TEXT_RAW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_FAR_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_FAR_SOFT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_GLOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_OUTLINE", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_OUTLINE_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_OUTLINE_SOFT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_PLAIN", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM_LEFT", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_LEFT", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_LEFT", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SOFT_OUTLINE", type=>"IV", macro=>"1"},
            {name=>"EVAS_TEXT_STYLE_SOFT_SHADOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_VIDEO_SURFACE_BELOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_VIDEO_SURFACE_CLIP", type=>"IV", macro=>"1"},
            {name=>"EVAS_VIDEO_SURFACE_IGNORE_WINDOW", type=>"IV", macro=>"1"},
            {name=>"EVAS_VIDEO_SURFACE_MOVE", type=>"IV", macro=>"1"},
            {name=>"EVAS_VIDEO_SURFACE_RESIZE", type=>"IV", macro=>"1"},
            {name=>"EVAS_VIDEO_SURFACE_STACKING_CHECK", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("pEFL::Evas", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("pEFL::Evas", $types);
__END__
   */

  switch (len) {
  case 14:
    if (memEQ(name, "EVAS_HINT_FILL", 14)) {
      *iv_return = EVAS_HINT_FILL;
      return PERL_constant_ISIV;
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* EVAS_HINT_EXPAND EVAS_RENDER_COPY */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'N':
      if (memEQ(name, "EVAS_HINT_EXPAND", 16)) {
      /*                             ^        */
        *iv_return = EVAS_HINT_EXPAND;
        return PERL_constant_ISIV;
      }
      break;
    case 'P':
      if (memEQ(name, "EVAS_RENDER_COPY", 16)) {
      /*                             ^        */
        *iv_return = EVAS_RENDER_COPY;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* EVAS_CALLBACK_DEL EVAS_RENDER_BLEND */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'D':
      if (memEQ(name, "EVAS_CALLBACK_DEL", 17)) {
      /*                             ^         */
        *iv_return = EVAS_CALLBACK_DEL;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "EVAS_RENDER_BLEND", 17)) {
      /*                             ^         */
        *iv_return = EVAS_RENDER_BLEND;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    if (memEQ(name, "EVAS_IMAGE_ORIENT_0", 19)) {
      *iv_return = EVAS_IMAGE_ORIENT_0;
      return PERL_constant_ISIV;
    }
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
    /* Names all of length 32.  */
    /* EVAS_CALLBACK_CHANGED_SIZE_HINTS EVAS_VIDEO_SURFACE_IGNORE_WINDOW */
    /* Offset 27 gives the best switch position.  */
    switch (name[27]) {
    case 'H':
      if (memEQ(name, "EVAS_CALLBACK_CHANGED_SIZE_HINTS", 32)) {
      /*                                          ^           */
        *iv_return = EVAS_CALLBACK_CHANGED_SIZE_HINTS;
        return PERL_constant_ISIV;
      }
      break;
    case 'I':
      if (memEQ(name, "EVAS_VIDEO_SURFACE_IGNORE_WINDOW", 32)) {
      /*                                          ^           */
        *iv_return = EVAS_VIDEO_SURFACE_IGNORE_WINDOW;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 33:
    /* Names all of length 33.  */
    /* EVAS_LOAD_ERROR_PERMISSION_DENIED EVAS_VIDEO_SURFACE_STACKING_CHECK */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'D':
      if (memEQ(name, "EVAS_LOAD_ERROR_PERMISSION_DENIED", 33)) {
      /*                       ^                               */
        *iv_return = EVAS_LOAD_ERROR_PERMISSION_DENIED;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "EVAS_VIDEO_SURFACE_STACKING_CHECK", 33)) {
      /*                       ^                               */
        *iv_return = EVAS_VIDEO_SURFACE_STACKING_CHECK;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 35:
    if (memEQ(name, "EVAS_TEXT_STYLE_OUTLINE_SOFT_SHADOW", 35)) {
      *iv_return = EVAS_TEXT_STYLE_OUTLINE_SOFT_SHADOW;
      return PERL_constant_ISIV;
    }
    break;
  case 36:
    return constant_36 (aTHX_ name, iv_return);
    break;
  case 37:
    return constant_37 (aTHX_ name, iv_return);
    break;
  case 38:
    /* Names all of length 38.  */
    /* EVAS_NATIVE_SURFACE_STATUS_SCANOUT_OFF
       EVAS_TEXT_STYLE_SHADOW_DIRECTION_RIGHT */
    /* Offset 25 gives the best switch position.  */
    switch (name[25]) {
    case 'R':
      if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_RIGHT", 38)) {
      /*                                        ^                   */
        *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_RIGHT;
        return PERL_constant_ISIV;
      }
      break;
    case 'S':
      if (memEQ(name, "EVAS_NATIVE_SURFACE_STATUS_SCANOUT_OFF", 38)) {
      /*                                        ^                   */
        *iv_return = EVAS_NATIVE_SURFACE_STATUS_SCANOUT_OFF;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 39:
    /* Names all of length 39.  */
    /* EVAS_NATIVE_SURFACE_STATUS_PLANE_ASSIGN
       EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM */
    /* Offset 38 gives the best switch position.  */
    switch (name[38]) {
    case 'M':
      if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTO", 38)) {
      /*                                                     M      */
        *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "EVAS_NATIVE_SURFACE_STATUS_PLANE_ASSIG", 38)) {
      /*                                                     N      */
        *iv_return = EVAS_NATIVE_SURFACE_STATUS_PLANE_ASSIGN;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 40:
    if (memEQ(name, "EVAS_NATIVE_SURFACE_STATUS_PLANE_RELEASE", 40)) {
      *iv_return = EVAS_NATIVE_SURFACE_STATUS_PLANE_RELEASE;
      return PERL_constant_ISIV;
    }
    break;
  case 41:
    if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_LEFT", 41)) {
      *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 42:
    /* Names all of length 42.  */
    /* EVAS_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED
       EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_RIGHT */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'R':
      if (memEQ(name, "EVAS_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED", 42)) {
      /*                               ^                                */
        *iv_return = EVAS_LOAD_ERROR_RESOURCE_ALLOCATION_FAILED;
        return PERL_constant_ISIV;
      }
      break;
    case 'S':
      if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_RIGHT", 42)) {
      /*                               ^                                */
        *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_TOP_RIGHT;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 44:
    if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM_LEFT", 44)) {
      *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM_LEFT;
      return PERL_constant_ISIV;
    }
    break;
  case 45:
    if (memEQ(name, "EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM_RIGHT", 45)) {
      *iv_return = EVAS_TEXT_STYLE_SHADOW_DIRECTION_BOTTOM_RIGHT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

