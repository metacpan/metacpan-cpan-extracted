#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

typedef Ecore_Event_Signal_User EcoreEventSignalUser;



MODULE = pEFL::Ecore::Event::SignalUser		PACKAGE = EvasEventSignalUserPtr

int
number(event)
    EcoreEventSignalUser *event
CODE:
    RETVAL = event->number;
OUTPUT:
    RETVAL
