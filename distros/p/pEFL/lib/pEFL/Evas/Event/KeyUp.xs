#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Event_Key_Up EvasEventKeyUp;
typedef Evas_Modifier EvasModifier;
typedef Evas_Lock EvasLock;
typedef Evas_Object EvasObject;


MODULE = pEFL::Evas::Event::KeyUp		PACKAGE = EvasEventKeyUpPtr

char*
keyname(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->keyname;
OUTPUT:
    RETVAL
 
 
EvasModifier*
modifiers(event)
	EvasEventKeyUp *event
CODE:
    RETVAL = event->modifiers;
OUTPUT:
    RETVAL
    
    
EvasLock*
locks(event)
	EvasEventKeyUp *event
CODE:
    RETVAL = event->locks;
OUTPUT:
    RETVAL

    
const char*
key(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->key;
OUTPUT:
    RETVAL
  
  
const char*
string(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->string;
OUTPUT:
    RETVAL
  
  
const char*
compose(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->compose;
OUTPUT:
    RETVAL


unsigned int
timestamp(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
int
event_flags(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->event_flags;
OUTPUT:
    RETVAL

    
void
dev(event)
	EvasEventKeyUp *event
CODE:
	printf("the dev member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

	
int
keycode(event)
    EvasEventKeyUp *event
CODE:
    RETVAL = event->keycode;
OUTPUT:
    RETVAL

