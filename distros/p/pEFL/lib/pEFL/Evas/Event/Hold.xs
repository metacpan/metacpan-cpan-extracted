#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Event_Hold EvasEventHold;
typedef Evas_Modifier EvasModifier;
typedef Evas_Lock EvasLock;
typedef Evas_Object EvasObject;


MODULE = pEFL::Evas::Event::Hold		PACKAGE = EvasEventHoldPtr

int
hold(event)
    EvasEventHold *event
CODE:
    RETVAL = event->hold;
OUTPUT:
    RETVAL


unsigned int
timestamp(event)
    EvasEventHold *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
int
event_flags(event)
    EvasEventHold *event
CODE:
    RETVAL = event->event_flags;
OUTPUT:
    RETVAL

    
void
dev(event)
	EvasEventHold *event
CODE:
	printf("the dev member of the event struct is at the moment not supported in Perl. Sorry :-( \n");
