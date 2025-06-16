#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

typedef Ecore_Event_Signal_Realtime EcoreEventSignalRealtime;



MODULE = pEFL::Ecore::Event::SignalRealtime		PACKAGE = EvasEventSignalRealtimePtr

int
num(event)
    EcoreEventSignalRealtime *event
CODE:
    RETVAL = event->num;
OUTPUT:
    RETVAL
