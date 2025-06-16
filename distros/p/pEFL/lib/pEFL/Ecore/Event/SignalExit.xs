#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

typedef Ecore_Event_Signal_Exit EcoreEventSignalExit;

MODULE = pEFL::Ecore::Event::SignalExit		PACKAGE = EvasEventSignalExitPtr

int
interrupt(event)
    EcoreEventSignalExit *event
CODE:
    RETVAL = event->interrupt;
OUTPUT:
    RETVAL

int
quit(event)
    EcoreEventSignalExit *event
CODE:
    RETVAL = event->quit;
OUTPUT:
    RETVAL
    
int
terminate(event)
    EcoreEventSignalExit *event
CODE:
    RETVAL = event->terminate;
OUTPUT:
    RETVAL