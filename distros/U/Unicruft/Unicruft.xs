/*-*- Mode: C -*- */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/*#include "ppport.h"*/

#include <unicruft.h>
#include <string.h>

/*==============================================================================
 * Utils
 */

void ux_sv2buf_bytes(SV *sv, uxBuffer *buf)
{
  STRLEN len;
  buf->str = SvPV(sv, len);
  buf->len = len;
}

/*==============================================================================
 * XS Guts
 */

MODULE = Unicruft    PACKAGE = Unicruft

PROTOTYPES: ENABLE

##=====================================================================
## Information
##=====================================================================

const char *
library_version()
CODE:
  RETVAL = PACKAGE_VERSION;
OUTPUT:
  RETVAL

##=====================================================================
## Conversions
##=====================================================================

##--------------------------------------------------------------
SV *
ux_latin1_to_utf8(SV *l1bytes)
PREINIT:
 uxBuffer ibuf = {NULL,0,0};
 uxBuffer obuf = {NULL,0,0};
CODE:
  ux_sv2buf_bytes(l1bytes, &ibuf);
  ux_buffer_latin1_to_utf8(&ibuf, &obuf);
  RETVAL = newSVpvn(obuf.str, obuf.len);
  SvUTF8_on(RETVAL);
OUTPUT:
  RETVAL
CLEANUP:
  if (obuf.str) free(obuf.str);

##--------------------------------------------------------------
SV *
ux_utf8_to_ascii(SV *u8bytes)
PREINIT:
 uxBuffer ibuf = {NULL,0,0};
 uxBuffer obuf = {NULL,0,0};
CODE:
  ux_sv2buf_bytes(u8bytes, &ibuf);
  ux_unidecode_us(NULL, &ibuf, &obuf);
  RETVAL = newSVpvn(obuf.str, obuf.len);
  SvUTF8_off(RETVAL);
OUTPUT:
  RETVAL
CLEANUP:
  if (obuf.str) free(obuf.str);

##--------------------------------------------------------------
SV *
ux_utf8_to_latin1(SV *u8bytes)
PREINIT:
 uxBuffer ibuf = {NULL,0,0};
 uxBuffer obuf = {NULL,0,0};
CODE:
  ux_sv2buf_bytes(u8bytes, &ibuf);
  ux_unidecode_us(&UNIDECODE_LATIN1, &ibuf, &obuf);
  RETVAL = newSVpvn(obuf.str, obuf.len);
  SvUTF8_off(RETVAL);
OUTPUT:
  RETVAL
CLEANUP:
  if (obuf.str) free(obuf.str);

##--------------------------------------------------------------
SV *
ux_utf8_to_latin1_de(SV *u8bytes)
PREINIT:
 uxBuffer ibuf = {NULL,0,0};
 uxBuffer pbuf = {NULL,0,0};
 uxBuffer obuf = {NULL,0,0};
 uxDEpp   depp;
CODE:
  ux_sv2buf_bytes(u8bytes, &ibuf);
  ux_depp_init(&depp);
  ibuf.len++; //-- make uxDEyy scanner treat terminating NUL as a "normal" character
  ux_depp_scan_const_buffer(&depp, &ibuf, &pbuf);
  if (pbuf.len>0) pbuf.len--; //-- terminating NUL is not really a "normal" character
  ux_unidecode_us(&UNIDECODE_LATIN1, &pbuf, &obuf);
  RETVAL = newSVpvn(obuf.str, obuf.len);
  SvUTF8_off(RETVAL);
OUTPUT:
  RETVAL
CLEANUP:
  if (pbuf.str) free(pbuf.str);
  if (obuf.str) free(obuf.str);
  ux_depp_free_data(&depp);
