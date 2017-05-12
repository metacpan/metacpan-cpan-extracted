#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Charset.h"

MODULE = Text::Convert::PETSCII  PACKAGE = Text::Convert::PETSCII
PROTOTYPES: ENABLE

int
_is_integer(var)
        SV* var
    CODE:
        if (SvIOKp(var)) {
            RETVAL = 1;
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

int
_is_string(var)
        SV* var
    CODE:
        if (SvPOKp(var)) {
            RETVAL = 1;
        }
        else {
            RETVAL = 0;
        }
    OUTPUT:
        RETVAL

void
_get_font_data(idx, shift)
        int idx
        int shift
    INIT:
        int c, i, s;
    PPCODE:
        if (shift) {
            s = 0x0800;
        }
        else {
            s = 0x0000;
        }
        for (i = 0; i < 8; i++) {
            c = (int)rom_charset[s + idx * 8 + i];
            XPUSHs(sv_2mortal(newSViv(c)));
        }
