#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

#include <string.h>
#include <stdlib.h>

int isEOL(char c) {
  if ((c == '\n') || (c == '\r') || (c == '\f') || (c == '\v') || (c == 0x85))
    return 1;
  return 0;
}

int isWhitespace(char c) {
  if ((c == ' ') || (c == '\t') || isEOL(c))
    return 1;
  return 0;
}


char* TextMinify(const char* inStr) {
  size_t len   = strlen(inStr);
  char* outStr;

  Newx(outStr, 1, char);

  if (!outStr) /* malloc failed */
    return outStr;

  char* ptr = outStr;
  char* leading = ptr;
  char* trailing = NULL;

  while (*inStr) {
    char c = *inStr;

    if (leading && !isWhitespace(c))
        leading = NULL;

    if (!leading) {
      *ptr = c;
      if (isEOL(c)) {
        if (trailing) {
          ptr = trailing;
        }
        *ptr = '\n';
        leading = ptr;
      }
      else if (isWhitespace(c)) {
        if (!trailing) trailing = ptr;
      }
      else {
        trailing = NULL;
      }
      ptr++;
    }

    inStr++;
  }

  if (trailing) {
    ptr = trailing;
    if (isEOL(*ptr)) ptr++;
  }

  *ptr = '\0';

  return outStr;
}

MODULE = Text::Minify::XS PACKAGE = Text::Minify::XS

PROTOTYPES: ENABLE

SV*
minify(inStr)
  SV* inStr
  INIT:
    char* outStr = NULL;
    RETVAL = &PL_sv_undef;
  CODE:
    outStr = TextMinify( SvPVX(inStr) );
    if (outStr != NULL) {
      RETVAL = newSVpv(outStr, 0);
      Safefree(outStr);
    }
  OUTPUT:
    RETVAL
