#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"

SV* S_io_fdopen(pTHX_ int fd, const char* packagename) {
    PerlIO* pio = PerlIO_fdopen(fd, "r");
    GV* gv = newGVgen(packagename);
    SV* ret = newRV_noinc((SV*)gv);
    IO* io = GvIOn(gv);
    IoTYPE(io) = '<';
    IoIFP(io) = pio;
    IoOFP(io) = pio;
    return ret;
}
