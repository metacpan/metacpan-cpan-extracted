#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <STDIO.h>

int 
xs_fmode( FILE *stream ) {
    return stream->_flag;
}

MODULE = Win32::Fmode  PACKAGE = Win32::Fmode  

PROTOTYPES: DISABLE

int
xs_fmode (stream)
    FILE *  stream
