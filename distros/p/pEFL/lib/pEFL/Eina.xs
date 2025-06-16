#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Eina.h>

#include "const-eina-c.inc"

MODULE = pEFL::Eina		PACKAGE = pEFL::Eina		

INCLUDE: const-eina-xs.inc