#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>
#include <Elementary.h>
#include "const-evas-c.inc"

MODULE = pEFL::Evas		PACKAGE = pEFL::Evas		

INCLUDE: const-evas-xs.inc
