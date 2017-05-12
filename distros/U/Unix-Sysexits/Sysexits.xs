#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sysexits.h>

#include "const-c.inc"

MODULE = Unix::Sysexits		PACKAGE = Unix::Sysexits		

INCLUDE: const-xs.inc
