#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Event_Key_Down EvasEventKeyDown;
typedef Evas_Modifier EvasModifier;
typedef Evas_Lock EvasLock;
typedef Evas_Object EvasObject;


MODULE = pEFL::Evas::Event::KeyDown		PACKAGE = EvasEventKeyDownPtr

char*
keyname(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->keyname;
OUTPUT:
    RETVAL
 
 
EvasModifier*
modifiers(event)
	EvasEventKeyDown *event
CODE:
    RETVAL = event->modifiers;
OUTPUT:
    RETVAL
    
    
EvasLock*
locks(event)
	EvasEventKeyDown *event
CODE:
    RETVAL = event->locks;
OUTPUT:
    RETVAL

    
const char*
key(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->key;
OUTPUT:
    RETVAL
  
  
const char*
string(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->string;
OUTPUT:
    RETVAL
  
  
const char*
compose(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->compose;
OUTPUT:
    RETVAL


unsigned int
timestamp(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
int
event_flags(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->event_flags;
OUTPUT:
    RETVAL

    
void
dev(event)
	EvasEventKeyDown *event
CODE:
	printf("the dev member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

	
int
keycode(event)
    EvasEventKeyDown *event
CODE:
    RETVAL = event->keycode;
OUTPUT:
    RETVAL

