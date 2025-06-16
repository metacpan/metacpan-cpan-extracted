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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EMOTION_EVENT_0 EMOTION_EVENT_1 EMOTION_EVENT_2 EMOTION_EVENT_3
     EMOTION_EVENT_4 EMOTION_EVENT_5 EMOTION_EVENT_6 EMOTION_EVENT_7
     EMOTION_EVENT_8 EMOTION_EVENT_9 */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '0':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             0      */
      *iv_return = EMOTION_EVENT_0;
      return PERL_constant_ISIV;
    }
    break;
  case '1':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             1      */
      *iv_return = EMOTION_EVENT_1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             2      */
      *iv_return = EMOTION_EVENT_2;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             3      */
      *iv_return = EMOTION_EVENT_3;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             4      */
      *iv_return = EMOTION_EVENT_4;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             5      */
      *iv_return = EMOTION_EVENT_5;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             6      */
      *iv_return = EMOTION_EVENT_6;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             7      */
      *iv_return = EMOTION_EVENT_7;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             8      */
      *iv_return = EMOTION_EVENT_8;
      return PERL_constant_ISIV;
    }
    break;
  case '9':
    if (memEQ(name, "EMOTION_EVENT_", 14)) {
    /*                             9      */
      *iv_return = EMOTION_EVENT_9;
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
     EMOTION_EVENT_10 EMOTION_EVENT_UP EMOTION_VIS_GOOM EMOTION_VIS_LAST
     EMOTION_VIS_NONE */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case '0':
    if (memEQ(name, "EMOTION_EVENT_1", 15)) {
    /*                              0      */
      *iv_return = EMOTION_EVENT_10;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EMOTION_VIS_NON", 15)) {
    /*                              E      */
      *iv_return = EMOTION_VIS_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "EMOTION_VIS_GOO", 15)) {
    /*                              M      */
      *iv_return = EMOTION_VIS_GOOM;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EMOTION_EVENT_U", 15)) {
    /*                              P      */
      *iv_return = EMOTION_EVENT_UP;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EMOTION_VIS_LAS", 15)) {
    /*                              T      */
      *iv_return = EMOTION_VIS_LAST;
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
     EMOTION_DEEP_SLEEP EMOTION_EVENT_DOWN EMOTION_EVENT_LEFT
     EMOTION_EVENT_NEXT EMOTION_EVENT_PREV */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'N':
    if (memEQ(name, "EMOTION_EVENT_DOW", 17)) {
    /*                                N      */
      *iv_return = EMOTION_EVENT_DOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EMOTION_DEEP_SLEE", 17)) {
    /*                                P      */
      *iv_return = EMOTION_DEEP_SLEEP;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EMOTION_EVENT_LEF", 17)) {
    /*                                T      */
      *iv_return = EMOTION_EVENT_LEFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "EMOTION_EVENT_NEX", 17)) {
    /*                                T      */
      *iv_return = EMOTION_EVENT_NEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "EMOTION_EVENT_PRE", 17)) {
    /*                                V      */
      *iv_return = EMOTION_EVENT_PREV;
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
     EMOTION_ASPECT_CROP EMOTION_EVENT_FORCE EMOTION_EVENT_MENU1
     EMOTION_EVENT_MENU2 EMOTION_EVENT_MENU3 EMOTION_EVENT_MENU4
     EMOTION_EVENT_MENU5 EMOTION_EVENT_MENU6 EMOTION_EVENT_MENU7
     EMOTION_EVENT_RIGHT */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case '1':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 1      */
      *iv_return = EMOTION_EVENT_MENU1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 2      */
      *iv_return = EMOTION_EVENT_MENU2;
      return PERL_constant_ISIV;
    }
    break;
  case '3':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 3      */
      *iv_return = EMOTION_EVENT_MENU3;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 4      */
      *iv_return = EMOTION_EVENT_MENU4;
      return PERL_constant_ISIV;
    }
    break;
  case '5':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 5      */
      *iv_return = EMOTION_EVENT_MENU5;
      return PERL_constant_ISIV;
    }
    break;
  case '6':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 6      */
      *iv_return = EMOTION_EVENT_MENU6;
      return PERL_constant_ISIV;
    }
    break;
  case '7':
    if (memEQ(name, "EMOTION_EVENT_MENU", 18)) {
    /*                                 7      */
      *iv_return = EMOTION_EVENT_MENU7;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "EMOTION_EVENT_FORC", 18)) {
    /*                                 E      */
      *iv_return = EMOTION_EVENT_FORCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EMOTION_ASPECT_CRO", 18)) {
    /*                                 P      */
      *iv_return = EMOTION_ASPECT_CROP;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EMOTION_EVENT_RIGH", 18)) {
    /*                                 T      */
      *iv_return = EMOTION_EVENT_RIGHT;
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
     EMOTION_ASPECT_KEEP_BOTH EMOTION_ASPECT_KEEP_NONE EMOTION_EVENT_ANGLE_NEXT
     EMOTION_EVENT_ANGLE_PREV */
  /* Offset 23 gives the best switch position.  */
  switch (name[23]) {
  case 'E':
    if (memEQ(name, "EMOTION_ASPECT_KEEP_NON", 23)) {
    /*                                      E      */
      *iv_return = EMOTION_ASPECT_KEEP_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "EMOTION_ASPECT_KEEP_BOT", 23)) {
    /*                                      H      */
      *iv_return = EMOTION_ASPECT_KEEP_BOTH;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EMOTION_EVENT_ANGLE_NEX", 23)) {
    /*                                      T      */
      *iv_return = EMOTION_EVENT_ANGLE_NEXT;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "EMOTION_EVENT_ANGLE_PRE", 23)) {
    /*                                      V      */
      *iv_return = EMOTION_EVENT_ANGLE_PREV;
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
     EMOTION_ASPECT_KEEP_HEIGHT EMOTION_VIS_LIBVISUAL_GOOM
     EMOTION_VIS_LIBVISUAL_JESS */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'G':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_GOOM", 26)) {
    /*                                     ^          */
      *iv_return = EMOTION_VIS_LIBVISUAL_GOOM;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EMOTION_ASPECT_KEEP_HEIGHT", 26)) {
    /*                                     ^          */
      *iv_return = EMOTION_ASPECT_KEEP_HEIGHT;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_JESS", 26)) {
    /*                                     ^          */
      *iv_return = EMOTION_VIS_LIBVISUAL_JESS;
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
     EMOTION_META_INFO_TRACK_YEAR EMOTION_VIS_LIBVISUAL_CORONA
     EMOTION_VIS_LIBVISUAL_JAKDAW EMOTION_VIS_LIBVISUAL_PLASMA */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'C':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_CORONA", 28)) {
    /*                                     ^            */
      *iv_return = EMOTION_VIS_LIBVISUAL_CORONA;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_JAKDAW", 28)) {
    /*                                     ^            */
      *iv_return = EMOTION_VIS_LIBVISUAL_JAKDAW;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_YEAR", 28)) {
    /*                                     ^            */
      *iv_return = EMOTION_META_INFO_TRACK_YEAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_PLASMA", 28)) {
    /*                                     ^            */
      *iv_return = EMOTION_VIS_LIBVISUAL_PLASMA;
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
     EMOTION_ARTWORK_PREVIEW_IMAGE EMOTION_META_INFO_TRACK_ALBUM
     EMOTION_META_INFO_TRACK_COUNT EMOTION_META_INFO_TRACK_GENRE
     EMOTION_META_INFO_TRACK_TITLE EMOTION_VIS_LIBVISUAL_G_FORCE
     EMOTION_VIS_LIBVISUAL_MADSPIN EMOTION_VIS_LIBVISUAL_NEBULUS
     EMOTION_VIS_LIBVISUAL_OINKSIE */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case 'A':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_ALBUM", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_META_INFO_TRACK_ALBUM;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_NEBULUS", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_VIS_LIBVISUAL_NEBULUS;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_COUNT", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_META_INFO_TRACK_COUNT;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_MADSPIN", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_VIS_LIBVISUAL_MADSPIN;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_G_FORCE", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_VIS_LIBVISUAL_G_FORCE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_GENRE", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_META_INFO_TRACK_GENRE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EMOTION_ARTWORK_PREVIEW_IMAGE", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_ARTWORK_PREVIEW_IMAGE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_OINKSIE", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_VIS_LIBVISUAL_OINKSIE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_TITLE", 29)) {
    /*                                       ^           */
      *iv_return = EMOTION_META_INFO_TRACK_TITLE;
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
     EMOTION_META_INFO_TRACK_ARTIST EMOTION_VIS_LIBVISUAL_INFINITE
     EMOTION_VIS_LIBVISUAL_LV_SCOPE */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'I':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_INFINITE", 30)) {
    /*                                     ^              */
      *iv_return = EMOTION_VIS_LIBVISUAL_INFINITE;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_ARTIST", 30)) {
    /*                                     ^              */
      *iv_return = EMOTION_META_INFO_TRACK_ARTIST;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_LV_SCOPE", 30)) {
    /*                                     ^              */
      *iv_return = EMOTION_VIS_LIBVISUAL_LV_SCOPE;
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
     EMOTION_META_INFO_TRACK_COMMENT EMOTION_META_INFO_TRACK_DISC_ID
     EMOTION_VIS_LIBVISUAL_BUMPSCOPE EMOTION_VIS_LIBVISUAL_GDKPIXBUF
     EMOTION_VIS_LIBVISUAL_LV_FLOWER EMOTION_VIS_LIBVISUAL_LV_GLTEST */
  /* Offset 29 gives the best switch position.  */
  switch (name[29]) {
  case 'E':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_LV_FLOWER", 31)) {
    /*                                            ^        */
      *iv_return = EMOTION_VIS_LIBVISUAL_LV_FLOWER;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_DISC_ID", 31)) {
    /*                                            ^        */
      *iv_return = EMOTION_META_INFO_TRACK_DISC_ID;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "EMOTION_META_INFO_TRACK_COMMENT", 31)) {
    /*                                            ^        */
      *iv_return = EMOTION_META_INFO_TRACK_COMMENT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_BUMPSCOPE", 31)) {
    /*                                            ^        */
      *iv_return = EMOTION_VIS_LIBVISUAL_BUMPSCOPE;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_LV_GLTEST", 31)) {
    /*                                            ^        */
      *iv_return = EMOTION_VIS_LIBVISUAL_LV_GLTEST;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_GDKPIXBUF", 31)) {
    /*                                            ^        */
      *iv_return = EMOTION_VIS_LIBVISUAL_GDKPIXBUF;
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
            {name=>"EMOTION_ARTWORK_IMAGE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ARTWORK_PREVIEW_IMAGE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ASPECT_CROP", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ASPECT_CUSTOM", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ASPECT_KEEP_BOTH", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ASPECT_KEEP_HEIGHT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ASPECT_KEEP_NONE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_ASPECT_KEEP_WIDTH", type=>"IV", macro=>"1"},
            {name=>"EMOTION_DEEP_SLEEP", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_0", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_1", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_10", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_2", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_3", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_4", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_5", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_6", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_7", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_8", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_9", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_ANGLE_NEXT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_ANGLE_PREV", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_DOWN", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_FORCE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_LEFT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU1", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU2", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU3", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU4", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU5", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU6", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_MENU7", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_NEXT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_PREV", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_RIGHT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_SELECT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_EVENT_UP", type=>"IV", macro=>"1"},
            {name=>"EMOTION_HIBERNATE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_ALBUM", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_ARTIST", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_COMMENT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_COUNT", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_DISC_ID", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_GENRE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_TITLE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_META_INFO_TRACK_YEAR", type=>"IV", macro=>"1"},
            {name=>"EMOTION_SLEEP", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_GOOM", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LAST", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_BUMPSCOPE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_CORONA", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_DANCING_PARTICLES", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_GDKPIXBUF", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_GOOM", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_G_FORCE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_INFINITE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_JAKDAW", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_JESS", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_LV_ANALYSER", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_LV_FLOWER", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_LV_GLTEST", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_LV_SCOPE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_MADSPIN", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_NEBULUS", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_OINKSIE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_LIBVISUAL_PLASMA", type=>"IV", macro=>"1"},
            {name=>"EMOTION_VIS_NONE", type=>"IV", macro=>"1"},
            {name=>"EMOTION_WAKEUP", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("pEFL::Emotion", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("pEFL::Emotion", $types);
__END__
   */

  switch (len) {
  case 13:
    if (memEQ(name, "EMOTION_SLEEP", 13)) {
      *iv_return = EMOTION_SLEEP;
      return PERL_constant_ISIV;
    }
    break;
  case 14:
    if (memEQ(name, "EMOTION_WAKEUP", 14)) {
      *iv_return = EMOTION_WAKEUP;
      return PERL_constant_ISIV;
    }
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    if (memEQ(name, "EMOTION_HIBERNATE", 17)) {
      *iv_return = EMOTION_HIBERNATE;
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
    if (memEQ(name, "EMOTION_EVENT_SELECT", 20)) {
      *iv_return = EMOTION_EVENT_SELECT;
      return PERL_constant_ISIV;
    }
    break;
  case 21:
    /* Names all of length 21.  */
    /* EMOTION_ARTWORK_IMAGE EMOTION_ASPECT_CUSTOM */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'R':
      if (memEQ(name, "EMOTION_ARTWORK_IMAGE", 21)) {
      /*                        ^                  */
        *iv_return = EMOTION_ARTWORK_IMAGE;
        return PERL_constant_ISIV;
      }
      break;
    case 'S':
      if (memEQ(name, "EMOTION_ASPECT_CUSTOM", 21)) {
      /*                        ^                  */
        *iv_return = EMOTION_ASPECT_CUSTOM;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    if (memEQ(name, "EMOTION_ASPECT_KEEP_WIDTH", 25)) {
      *iv_return = EMOTION_ASPECT_KEEP_WIDTH;
      return PERL_constant_ISIV;
    }
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
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
  case 33:
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_LV_ANALYSER", 33)) {
      *iv_return = EMOTION_VIS_LIBVISUAL_LV_ANALYSER;
      return PERL_constant_ISIV;
    }
    break;
  case 39:
    if (memEQ(name, "EMOTION_VIS_LIBVISUAL_DANCING_PARTICLES", 39)) {
      *iv_return = EMOTION_VIS_LIBVISUAL_DANCING_PARTICLES;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

