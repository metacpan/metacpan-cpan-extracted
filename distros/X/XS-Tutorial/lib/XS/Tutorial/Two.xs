#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include "stdint.h"         // portable integers

MODULE = XS::Tutorial::Two  PACKAGE = XS::Tutorial::Two
PROTOTYPES: ENABLE

SV *
add_ints (...)
  PPCODE:
    uint32_t i;
    int32_t total = 0;
    if (items > 0) {
      for (i = 0; i < items; i++) {
        if (!SvOK(ST(i)) || !SvIOK(ST(i)))
          croak("requires a list of integers");

        total += SvIVX(ST(i));
      }
      PUSHs(sv_2mortal(newSViv(total)));
    }
    else {
      PUSHs(sv_newmortal());
    }
