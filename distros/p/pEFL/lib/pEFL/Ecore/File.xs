#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"

MODULE = pEFL::Ecore::File		PACKAGE = pEFL::Ecore::File   PREFIX = ecore_file_
    
int
ecore_file_init()

int
ecore_file_shutdown()

MODULE = pEFL::Ecore::File		PACKAGE = EcoreFilePtr   PREFIX = ecore_file_