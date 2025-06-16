#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "const-c.inc"

MODULE = pEFL::Elm		PACKAGE = pEFL::Elm     PREFIX = elm_

INCLUDE: const-xs.inc

int
elm_init(argc, argv)
    int argc
    AV *argv
CODE:
        RETVAL = elm_init(argc, (char **)argv);
OUTPUT:
    RETVAL
    
int
elm_quicklaunch_fallback(argc,argv);
    int argc
    AV *argv
CODE:
        RETVAL = elm_quicklaunch_fallback(argc, (char **)argv);
OUTPUT:
    RETVAL

void 
elm_shutdown()

void 
elm_run()

void 
elm_exit()

Eina_Bool
elm_policy_set(int policy, int value)
