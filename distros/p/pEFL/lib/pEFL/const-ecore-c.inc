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
     ECORE_CALLBACK_CANCEL ECORE_EVENT_LOCK_CAPS ECORE_EVENT_MOUSE_OUT */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'L':
    if (memEQ(name, "ECORE_CALLBACK_CANCE", 20)) {
    /*                                   L      */
      *iv_return = ECORE_CALLBACK_CANCEL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "ECORE_EVENT_LOCK_CAP", 20)) {
    /*                                   S      */
      *iv_return = ECORE_EVENT_LOCK_CAPS;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "ECORE_EVENT_MOUSE_OU", 20)) {
    /*                                   T      */
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
    /* Names all of length 25.  */
    /* ECORE_EVENT_MODIFIER_CAPS ECORE_EVENT_MODIFIER_CTRL */
    /* Offset 23 gives the best switch position.  */
    switch (name[23]) {
    case 'P':
      if (memEQ(name, "ECORE_EVENT_MODIFIER_CAPS", 25)) {
      /*                                      ^        */
        *iv_return = ECORE_EVENT_MODIFIER_CAPS;
        return PERL_constant_ISIV;
      }
      break;
    case 'R':
      if (memEQ(name, "ECORE_EVENT_MODIFIER_CTRL", 25)) {
      /*                                      ^        */
        *iv_return = ECORE_EVENT_MODIFIER_CTRL;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 26:
    /* Names all of length 26.  */
    /* ECORE_EVENT_LOCALE_CHANGED ECORE_EVENT_MODIFIER_ALTGR */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'L':
      if (memEQ(name, "ECORE_EVENT_LOCALE_CHANGED", 26)) {
      /*                           ^                    */
#ifdef ECORE_EVENT_LOCALE_CHANGED
        *iv_return = ECORE_EVENT_LOCALE_CHANGED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'M':
      if (memEQ(name, "ECORE_EVENT_MODIFIER_ALTGR", 26)) {
      /*                           ^                    */
        *iv_return = ECORE_EVENT_MODIFIER_ALTGR;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    if (memEQ(name, "ECORE_EVENT_HOSTNAME_CHANGED", 28)) {
#ifdef ECORE_EVENT_HOSTNAME_CHANGED
      *iv_return = ECORE_EVENT_HOSTNAME_CHANGED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 29:
    if (memEQ(name, "ECORE_EVENT_MOUSE_BUTTON_DOWN", 29)) {
      *iv_return = ECORE_EVENT_MOUSE_BUTTON_DOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 35:
    if (memEQ(name, "ECORE_EVENT_SYSTEM_TIMEDATE_CHANGED", 35)) {
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

