#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#define NEED_utf8_to_uvchr_buf
#include "ppport.h"

#include <string.h>
#include <stdlib.h>

#define isEOL(c) ((c >= 0xa) && (c <= 0xd ) || (c == 0x85) || c == 0x2028 || c == 0x2029)

STATIC U8* TextMinify(pTHX_ U8* src, STRLEN len, STRLEN* packed) {
  U8* dest;

  Newx(dest, len + 1, U8);

  if (!dest) /* malloc failed */
    return dest;

  /* initialize to end-of-string in case string contains only spaces */
  *dest = 0;

  U8* end = src + len;
  U8* ptr = dest;
  U8* leading = ptr;
  U8* trailing = NULL;

  if (len == 0) {
    *packed = len;
    return dest;
  }

  while (len > 0) {

    UV c = *src;

    if (UTF8_IS_INVARIANT(c)) {
      src ++;
      len --;
    }
    else {
      STRLEN skip;
      c = utf8_to_uvchr_buf(src, end, &skip);
      if (c == 0) {
        c = *src;
      }
      if ((int) skip > 0) {
        src += skip;
        len -= skip;
      }
      else {
        src ++;
        len --;
      }
      if (len < 0) {
        croak("UTF-8 character overflow");
        src = end;
        len = 0;
        trailing = NULL;
      }
    }

    if (leading && !isSPACE(c))
      leading = NULL;

    if (!leading) {

      if (isEOL(c)) {
        if (trailing) ptr = trailing;
        if ( c == '\r' ) c = '\n'; /* Normalise EOL */
        leading = ptr;
      }
      else if (isSPACE(c)) {
        if (!trailing) trailing = ptr;
      }
      else {
        trailing = NULL;
      }

      if (UTF8_IS_INVARIANT(c))
        *ptr++ = c;
      else
        ptr = uvchr_to_utf8( ptr, c);

    }

  }

  if (trailing) {
    ptr = trailing;
    UV c = *ptr;
    STRLEN skip = UTF8SKIP(ptr);
    if (!UTF8_IS_INVARIANT(c)) {
      c = utf8_to_uvchr_buf(ptr, ptr + skip, &skip);
      if (c == 0) {
        c = *ptr;
      }
    }
    if (isEOL(c)) {
      if ((int) skip <= 0) {
        skip = 1;
      }
      ptr += skip;
    }
  }

  *packed = ptr - dest;

  return dest;
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
    char*  src = SvPVX(inStr);
    STRLEN len = SvCUR(inStr);
    STRLEN packed = 0;
    U32 is_utf8 = SvUTF8(inStr);
    outStr = TextMinify(aTHX_ src, len, &packed);
    if (outStr != NULL) {
      SV* result = newSVpvn(outStr, packed);
      if (is_utf8)
        SvUTF8_on(result);
      RETVAL = result;
      Safefree(outStr);
    }
    else {
      croak("TextMinify returned NULL");
    }
  OUTPUT:
    RETVAL
