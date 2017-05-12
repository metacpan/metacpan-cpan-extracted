% /* $Id: dict.x,v 1.3 1997/04/30 04:30:16 jake Exp $ */

%/*  Copyright 1997 Jake Donham <jake@organic.com>
%
%    You may distribute under the terms of either the GNU General
%    Public License or the Artistic License, as specified in the README
%    file.
%*/

enum dictstat {
  DICT_OK = 0,
  DICTERR_NOKEY = 50,
  DICTERR_NODICT = 51
};

typedef string dictname<>;

struct storeargs {
  dictname dict;
  opaque key<>;
  opaque value<>;
};

struct lookupargs {
  dictname dict;
  opaque key<>;
};

union dictres switch (dictstat status) {
case DICT_OK:
  opaque value<>;
default:
  string msg<>;
};

struct deleteargs {
  dictname dict;
  opaque key<>;
};

program DICT_PROGRAM {
  version DICT_VERSION {

    void
    DICTPROC_NULL(void) = 0;

    dictres
    DICTPROC_OPEN(dictname) = 1;

    dictres
    DICTPROC_CLOSE(dictname) = 2;

    dictres
    DICTPROC_STORE(storeargs) = 3;

    dictres
    DICTPROC_LOOKUP(lookupargs) = 4;

    dictres
    DICTPROC_DELETE(deleteargs) = 5;

  } = 1;
} = 90909;
