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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ECORE_CAPS ECORE_CTRL ECORE_LAST ECORE_MODE ECORE_NONE */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'D':
    if (memEQ(name, "ECORE_MODE", 10)) {
    /*                       ^        */
      *iv_return = ECORE_MODE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ECORE_NONE", 10)) {
    /*                       ^        */
      *iv_return = ECORE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "ECORE_CAPS", 10)) {
    /*                       ^        */
      *iv_return = ECORE_CAPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ECORE_CTRL", 10)) {
    /*                       ^        */
      *iv_return = ECORE_CTRL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ECORE_LAST", 10)) {
    /*                       ^        */
      *iv_return = ECORE_LAST;
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
     ECORE_CALLBACK_DONE ECORE_VERSION_MAJOR ECORE_VERSION_MINOR */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'J':
    if (memEQ(name, "ECORE_VERSION_MAJOR", 19)) {
    /*                               ^         */
      *iv_return = ECORE_VERSION_MAJOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ECORE_VERSION_MINOR", 19)) {
    /*                               ^         */
      *iv_return = ECORE_VERSION_MINOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ECORE_CALLBACK_DONE", 19)) {
    /*                               ^         */
      *iv_return = ECORE_CALLBACK_DONE;
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
     ECORE_CALLBACK_RENEW ECORE_EVENT_KEY_DOWN ECORE_EVENT_LOCK_NUM
     ECORE_EVENT_MOUSE_IN */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'C':
    if (memEQ(name, "ECORE_CALLBACK_RENEW", 20)) {
    /*                           ^              */
      *iv_return = ECORE_CALLBACK_RENEW;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "ECORE_EVENT_KEY_DOWN", 20)) {
    /*                           ^              */
      *iv_return = ECORE_EVENT_KEY_DOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ECORE_EVENT_LOCK_NUM", 20)) {
    /*                           ^              */
      *iv_return = ECORE_EVENT_LOCK_NUM;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "ECORE_EVENT_MOUSE_IN", 20)) {
    /*                           ^              */
      *iv_return = ECORE_EVENT_MOUSE_IN;
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
     ECORE_CALLBACK_CANCEL ECORE_EVAS_ENGINE_DRM ECORE_EVAS_ENGINE_EWS
     ECORE_EVENT_LOCK_CAPS ECORE_EVENT_MOUSE_OUT */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'A':
    if (memEQ(name, "ECORE_EVENT_LOCK_CAPS", 21)) {
    /*                                 ^         */
      *iv_return = ECORE_EVENT_LOCK_CAPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ECORE_CALLBACK_CANCEL", 21)) {
    /*                                 ^         */
      *iv_return = ECORE_CALLBACK_CANCEL;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "ECORE_EVAS_ENGINE_DRM", 21)) {
    /*                                 ^         */
      *iv_return = ECORE_EVAS_ENGINE_DRM;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ECORE_EVAS_ENGINE_EWS", 21)) {
    /*                                 ^         */
      *iv_return = ECORE_EVAS_ENGINE_EWS;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "ECORE_EVENT_MOUSE_OUT", 21)) {
    /*                                 ^         */
      *iv_return = ECORE_EVENT_MOUSE_OUT;
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
     ECORE_CALLBACK_PASS_ON ECORE_EVENT_LOCK_SHIFT ECORE_EVENT_MOUSE_MOVE
     ECORE_EVENT_SIGNAL_HUP */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'K':
    if (memEQ(name, "ECORE_EVENT_LOCK_SHIFT", 22)) {
    /*                              ^             */
      *iv_return = ECORE_EVENT_LOCK_SHIFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ECORE_EVENT_SIGNAL_HUP", 22)) {
    /*                              ^             */
#ifdef ECORE_EVENT_SIGNAL_HUP
      *iv_return = ECORE_EVENT_SIGNAL_HUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "ECORE_CALLBACK_PASS_ON", 22)) {
    /*                              ^             */
      *iv_return = ECORE_CALLBACK_PASS_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ECORE_EVENT_MOUSE_MOVE", 22)) {
    /*                              ^             */
      *iv_return = ECORE_EVENT_MOUSE_MOVE;
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
     ECORE_EVENT_LOCK_SCROLL ECORE_EVENT_MOUSE_WHEEL ECORE_EVENT_POWER_STATE
     ECORE_EVENT_SIGNAL_EXIT ECORE_EVENT_SIGNAL_USER */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'E':
    if (memEQ(name, "ECORE_EVENT_SIGNAL_EXIT", 23)) {
    /*                                  ^          */
#ifdef ECORE_EVENT_SIGNAL_EXIT
      *iv_return = ECORE_EVENT_SIGNAL_EXIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "ECORE_EVENT_MOUSE_WHEEL", 23)) {
    /*                                  ^          */
      *iv_return = ECORE_EVENT_MOUSE_WHEEL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ECORE_EVENT_LOCK_SCROLL", 23)) {
    /*                                  ^          */
      *iv_return = ECORE_EVENT_LOCK_SCROLL;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ECORE_EVENT_POWER_STATE", 23)) {
    /*                                  ^          */
#ifdef ECORE_EVENT_POWER_STATE
      *iv_return = ECORE_EVENT_POWER_STATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "ECORE_EVENT_SIGNAL_USER", 23)) {
    /*                                  ^          */
#ifdef ECORE_EVENT_SIGNAL_USER
      *iv_return = ECORE_EVENT_SIGNAL_USER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ECORE_EVENT_MEMORY_STATE ECORE_EVENT_MODIFIER_ALT ECORE_EVENT_MODIFIER_NUM
     ECORE_EVENT_MODIFIER_WIN ECORE_EVENT_SIGNAL_POWER */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'E':
    if (memEQ(name, "ECORE_EVENT_MEMORY_STAT", 23)) {
    /*                                      E      */
#ifdef ECORE_EVENT_MEMORY_STATE
      *iv_return = ECORE_EVENT_MEMORY_STATE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_NU", 23)) {
    /*                                      M      */
      *iv_return = ECORE_EVENT_MODIFIER_NUM;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_WI", 23)) {
    /*                                      N      */
      *iv_return = ECORE_EVENT_MODIFIER_WIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "ECORE_EVENT_SIGNAL_POWE", 23)) {
    /*                                      R      */
#ifdef ECORE_EVENT_SIGNAL_POWER
      *iv_return = ECORE_EVENT_SIGNAL_POWER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_AL", 23)) {
    /*                                      T      */
      *iv_return = ECORE_EVENT_MODIFIER_ALT;
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
     ECORE_EVAS_ENGINE_PSL1GHT ECORE_EVENT_MODIFIER_CAPS
     ECORE_EVENT_MODIFIER_CTRL */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case 'L':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_CTR", 24)) {
    /*                                       L      */
      *iv_return = ECORE_EVENT_MODIFIER_CTRL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_CAP", 24)) {
    /*                                       S      */
      *iv_return = ECORE_EVENT_MODIFIER_CAPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ECORE_EVAS_ENGINE_PSL1GH", 24)) {
    /*                                       T      */
      *iv_return = ECORE_EVAS_ENGINE_PSL1GHT;
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
     ECORE_EVAS_ENGINE_DIRECT3D ECORE_EVAS_ENGINE_DIRECTFB
     ECORE_EVENT_LOCALE_CHANGED ECORE_EVENT_MODIFIER_ALTGR */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case '3':
    if (memEQ(name, "ECORE_EVAS_ENGINE_DIRECT3D", 26)) {
    /*                                       ^        */
      *iv_return = ECORE_EVAS_ENGINE_DIRECT3D;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ECORE_EVENT_LOCALE_CHANGED", 26)) {
    /*                                       ^        */
#ifdef ECORE_EVENT_LOCALE_CHANGED
      *iv_return = ECORE_EVENT_LOCALE_CHANGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "ECORE_EVAS_ENGINE_DIRECTFB", 26)) {
    /*                                       ^        */
      *iv_return = ECORE_EVAS_ENGINE_DIRECTFB;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_ALTGR", 26)) {
    /*                                       ^        */
      *iv_return = ECORE_EVENT_MODIFIER_ALTGR;
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
     ECORE_EVENT_MODIFIER_SCROLL ECORE_EVENT_MOUSE_BUTTON_UP
     ECORE_EVENT_SIGNAL_REALTIME */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'A':
    if (memEQ(name, "ECORE_EVENT_SIGNAL_REALTIME", 27)) {
    /*                               ^                 */
#ifdef ECORE_EVENT_SIGNAL_REALTIME
      *iv_return = ECORE_EVENT_SIGNAL_REALTIME;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "ECORE_EVENT_MOUSE_BUTTON_UP", 27)) {
    /*                               ^                 */
      *iv_return = ECORE_EVENT_MOUSE_BUTTON_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ECORE_EVENT_MODIFIER_SCROLL", 27)) {
    /*                               ^                 */
      *iv_return = ECORE_EVENT_MODIFIER_SCROLL;
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
     ECORE_EVAS_AVOID_DAMAGE_NONE ECORE_EVAS_ENGINE_OPENGL_DRM
     ECORE_EVAS_ENGINE_OPENGL_SDL ECORE_EVAS_ENGINE_OPENGL_X11
     ECORE_EVENT_HOSTNAME_CHANGED */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'D':
    if (memEQ(name, "ECORE_EVAS_ENGINE_OPENGL_DRM", 28)) {
    /*                                        ^         */
      *iv_return = ECORE_EVAS_ENGINE_OPENGL_DRM;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ECORE_EVENT_HOSTNAME_CHANGED", 28)) {
    /*                                        ^         */
#ifdef ECORE_EVENT_HOSTNAME_CHANGED
      *iv_return = ECORE_EVENT_HOSTNAME_CHANGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "ECORE_EVAS_AVOID_DAMAGE_NONE", 28)) {
    /*                                        ^         */
      *iv_return = ECORE_EVAS_AVOID_DAMAGE_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ECORE_EVAS_ENGINE_OPENGL_SDL", 28)) {
    /*                                        ^         */
      *iv_return = ECORE_EVAS_ENGINE_OPENGL_SDL;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "ECORE_EVAS_ENGINE_OPENGL_X11", 28)) {
    /*                                        ^         */
      *iv_return = ECORE_EVAS_ENGINE_OPENGL_X11;
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
     ECORE_EVAS_ENGINE_OPENGL_GLEW ECORE_EVAS_ENGINE_SOFTWARE_FB
     ECORE_EVAS_ENGINE_WAYLAND_EGL ECORE_EVAS_ENGINE_WAYLAND_SHM
     ECORE_EVAS_ENGINE_XRENDER_X11 ECORE_EVAS_ENGINE_XRENDER_XCB
     ECORE_EVENT_MOUSE_BUTTON_DOWN */
  /* Offset 27 gives the best switch position.  */
  switch (name[27]) {
  case '1':
    if (memEQ(name, "ECORE_EVAS_ENGINE_XRENDER_X11", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVAS_ENGINE_XRENDER_X11;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ECORE_EVAS_ENGINE_XRENDER_XCB", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVAS_ENGINE_XRENDER_XCB;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ECORE_EVAS_ENGINE_OPENGL_GLEW", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVAS_ENGINE_OPENGL_GLEW;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_FB", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_FB;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "ECORE_EVAS_ENGINE_WAYLAND_EGL", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVAS_ENGINE_WAYLAND_EGL;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "ECORE_EVAS_ENGINE_WAYLAND_SHM", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVAS_ENGINE_WAYLAND_SHM;
      return PERL_constant_ISIV;
    }
    break;
  case 'W':
    if (memEQ(name, "ECORE_EVENT_MOUSE_BUTTON_DOWN", 29)) {
    /*                                          ^        */
      *iv_return = ECORE_EVENT_MOUSE_BUTTON_DOWN;
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
     ECORE_EVAS_AVOID_DAMAGE_EXPOSE ECORE_EVAS_ENGINE_OPENGL_COCOA
     ECORE_EVAS_ENGINE_SOFTWARE_GDI ECORE_EVAS_ENGINE_SOFTWARE_SDL
     ECORE_EVAS_ENGINE_SOFTWARE_XCB */
  /* Offset 29 gives the best switch position.  */
  switch (name[29]) {
  case 'A':
    if (memEQ(name, "ECORE_EVAS_ENGINE_OPENGL_COCO", 29)) {
    /*                                            A      */
      *iv_return = ECORE_EVAS_ENGINE_OPENGL_COCOA;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_XC", 29)) {
    /*                                            B      */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_XCB;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ECORE_EVAS_AVOID_DAMAGE_EXPOS", 29)) {
    /*                                            E      */
      *iv_return = ECORE_EVAS_AVOID_DAMAGE_EXPOSE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_GD", 29)) {
    /*                                            I      */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_GDI;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_SD", 29)) {
    /*                                            L      */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_SDL;
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
     ECORE_EVAS_AVOID_DAMAGE_BUILT_IN ECORE_EVAS_ENGINE_SOFTWARE_8_X11
     ECORE_EVAS_ENGINE_SOFTWARE_DDRAW ECORE_EVAS_OBJECT_ASSOCIATE_BASE */
  /* Offset 28 gives the best switch position.  */
  switch (name[28]) {
  case 'B':
    if (memEQ(name, "ECORE_EVAS_OBJECT_ASSOCIATE_BASE", 32)) {
    /*                                           ^          */
      *iv_return = ECORE_EVAS_OBJECT_ASSOCIATE_BASE;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_DDRAW", 32)) {
    /*                                           ^          */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_DDRAW;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ECORE_EVAS_AVOID_DAMAGE_BUILT_IN", 32)) {
    /*                                           ^          */
      *iv_return = ECORE_EVAS_AVOID_DAMAGE_BUILT_IN;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_8_X11", 32)) {
    /*                                           ^          */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_8_X11;
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
     ECORE_EVAS_ENGINE_SOFTWARE_16_X11 ECORE_EVAS_ENGINE_SOFTWARE_BUFFER
     ECORE_EVAS_OBJECT_ASSOCIATE_LAYER ECORE_EVAS_OBJECT_ASSOCIATE_STACK */
  /* Offset 30 gives the best switch position.  */
  switch (name[30]) {
  case 'A':
    if (memEQ(name, "ECORE_EVAS_OBJECT_ASSOCIATE_STACK", 33)) {
    /*                                             ^         */
      *iv_return = ECORE_EVAS_OBJECT_ASSOCIATE_STACK;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_BUFFER", 33)) {
    /*                                             ^         */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_BUFFER;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_16_X11", 33)) {
    /*                                             ^         */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_16_X11;
      return PERL_constant_ISIV;
    }
    break;
  case 'Y':
    if (memEQ(name, "ECORE_EVAS_OBJECT_ASSOCIATE_LAYER", 33)) {
    /*                                             ^         */
      *iv_return = ECORE_EVAS_OBJECT_ASSOCIATE_LAYER;
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
     ECORE_EVAS_ENGINE_SOFTWARE_16_DDRAW ECORE_EVAS_ENGINE_SOFTWARE_16_WINCE
     ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED */
  /* Offset 33 gives the best switch position.  */
  switch (name[33]) {
  case 'A':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_16_DDRAW", 35)) {
    /*                                                ^        */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_16_DDRAW;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_16_WINCE", 35)) {
    /*                                                ^        */
      *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_16_WINCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED", 35)) {
    /*                                                ^        */
#ifdef ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED
      *iv_return = ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
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
my @names = (qw(ECORE_EVENT_COUNT ECORE_EVENT_HOSTNAME_CHANGED
	       ECORE_EVENT_LOCALE_CHANGED ECORE_EVENT_MEMORY_STATE
	       ECORE_EVENT_NONE ECORE_EVENT_POWER_STATE ECORE_EVENT_SIGNAL_EXIT
	       ECORE_EVENT_SIGNAL_HUP ECORE_EVENT_SIGNAL_POWER
	       ECORE_EVENT_SIGNAL_REALTIME ECORE_EVENT_SIGNAL_USER
	       ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED),
            {name=>"ECORE_ALT", type=>"IV", macro=>"1"},
            {name=>"ECORE_CALLBACK_CANCEL", type=>"IV", macro=>"1"},
            {name=>"ECORE_CALLBACK_DONE", type=>"IV", macro=>"1"},
            {name=>"ECORE_CALLBACK_PASS_ON", type=>"IV", macro=>"1"},
            {name=>"ECORE_CALLBACK_RENEW", type=>"IV", macro=>"1"},
            {name=>"ECORE_CAPS", type=>"IV", macro=>"1"},
            {name=>"ECORE_CTRL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_AVOID_DAMAGE_BUILT_IN", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_AVOID_DAMAGE_EXPOSE", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_AVOID_DAMAGE_NONE", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_DIRECT3D", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_DIRECTFB", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_DRM", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_EWS", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_OPENGL_COCOA", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_OPENGL_DRM", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_OPENGL_GLEW", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_OPENGL_SDL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_OPENGL_X11", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_PSL1GHT", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_16_DDRAW", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_16_WINCE", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_16_X11", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_8_X11", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_BUFFER", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_DDRAW", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_FB", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_GDI", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_SDL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_XCB", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_SOFTWARE_XLIB", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_WAYLAND_EGL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_WAYLAND_SHM", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_XRENDER_X11", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_ENGINE_XRENDER_XCB", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_OBJECT_ASSOCIATE_BASE", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_OBJECT_ASSOCIATE_DEL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_OBJECT_ASSOCIATE_LAYER", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVAS_OBJECT_ASSOCIATE_STACK", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_KEY_DOWN", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_KEY_UP", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_LOCK_CAPS", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_LOCK_NUM", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_LOCK_SCROLL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_LOCK_SHIFT", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_ALT", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_ALTGR", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_CAPS", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_CTRL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_NUM", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_SCROLL", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MODIFIER_WIN", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MOUSE_BUTTON_DOWN", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MOUSE_BUTTON_UP", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MOUSE_IN", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MOUSE_MOVE", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MOUSE_OUT", type=>"IV", macro=>"1"},
            {name=>"ECORE_EVENT_MOUSE_WHEEL", type=>"IV", macro=>"1"},
            {name=>"ECORE_LAST", type=>"IV", macro=>"1"},
            {name=>"ECORE_MODE", type=>"IV", macro=>"1"},
            {name=>"ECORE_NONE", type=>"IV", macro=>"1"},
            {name=>"ECORE_POLLER_CORE", type=>"IV", macro=>"1"},
            {name=>"ECORE_SCROLL", type=>"IV", macro=>"1"},
            {name=>"ECORE_SHIFT", type=>"IV", macro=>"1"},
            {name=>"ECORE_VERSION_MAJOR", type=>"IV", macro=>"1"},
            {name=>"ECORE_VERSION_MINOR", type=>"IV", macro=>"1"},
            {name=>"ECORE_WIN", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("pEFL::Ecore", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("pEFL::Ecore", $types);
__END__
   */

  switch (len) {
  case 9:
    /* Names all of length 9.  */
    /* ECORE_ALT ECORE_WIN */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'I':
      if (memEQ(name, "ECORE_WIN", 9)) {
      /*                      ^       */
        *iv_return = ECORE_WIN;
        return PERL_constant_ISIV;
      }
      break;
    case 'L':
      if (memEQ(name, "ECORE_ALT", 9)) {
      /*                      ^       */
        *iv_return = ECORE_ALT;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    if (memEQ(name, "ECORE_SHIFT", 11)) {
      *iv_return = ECORE_SHIFT;
      return PERL_constant_ISIV;
    }
    break;
  case 12:
    if (memEQ(name, "ECORE_SCROLL", 12)) {
      *iv_return = ECORE_SCROLL;
      return PERL_constant_ISIV;
    }
    break;
  case 16:
    if (memEQ(name, "ECORE_EVENT_NONE", 16)) {
#ifdef ECORE_EVENT_NONE
      *iv_return = ECORE_EVENT_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* ECORE_EVENT_COUNT ECORE_POLLER_CORE */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'L':
      if (memEQ(name, "ECORE_POLLER_CORE", 17)) {
      /*                        ^              */
        *iv_return = ECORE_POLLER_CORE;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "ECORE_EVENT_COUNT", 17)) {
      /*                        ^              */
#ifdef ECORE_EVENT_COUNT
        *iv_return = ECORE_EVENT_COUNT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    if (memEQ(name, "ECORE_EVENT_KEY_UP", 18)) {
      *iv_return = ECORE_EVENT_KEY_UP;
      return PERL_constant_ISIV;
    }
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
    /* Names all of length 31.  */
    /* ECORE_EVAS_ENGINE_SOFTWARE_XLIB ECORE_EVAS_OBJECT_ASSOCIATE_DEL */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'G':
      if (memEQ(name, "ECORE_EVAS_ENGINE_SOFTWARE_XLIB", 31)) {
      /*                            ^                        */
        *iv_return = ECORE_EVAS_ENGINE_SOFTWARE_XLIB;
        return PERL_constant_ISIV;
      }
      break;
    case 'J':
      if (memEQ(name, "ECORE_EVAS_OBJECT_ASSOCIATE_DEL", 31)) {
      /*                            ^                        */
        *iv_return = ECORE_EVAS_OBJECT_ASSOCIATE_DEL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 33:
    return constant_33 (aTHX_ name, iv_return);
    break;
  case 35:
    return constant_35 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

