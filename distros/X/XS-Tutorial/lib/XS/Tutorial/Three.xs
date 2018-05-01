#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros

MODULE = XS::Tutorial::Three  PACKAGE = XS::Tutorial::Three
PROTOTYPES: ENABLE

BOOT:
printf("We're starting up!\n");

SV*
get_tied_value(SV *foo)
PPCODE:
  /* call FETCH() if it's a tied variable to populate the sv */
  SvGETMAGIC(foo);
  PUSHs(sv_2mortal(foo));

SV*
is_utf8(SV *foo)
PPCODE:
  /* if the UTF-8 flag is set return 1 "true" */
  if (SvUTF8(foo)) {
    PUSHs(sv_2mortal(newSViv(1)));
  }
  /* else return undef "false" */
  else {
    PUSHs(sv_newmortal());
  }

SV*
is_downgradeable(SV *foo)
PPCODE:
  /* if the UTF-8 flag is set and the scalar is not downgrade-able return "false" */
  if (SvUTF8(foo) && !sv_utf8_downgrade(foo, TRUE)) {
    PUSHs(sv_newmortal());
  }
  /* else return 1 "true" */
  else {
    PUSHs(sv_2mortal(newSViv(1)));
  }
