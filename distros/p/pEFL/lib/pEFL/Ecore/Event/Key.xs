#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>
#include <Ecore_Input.h>

typedef Ecore_Event_Key EcoreEventKey;


MODULE = pEFL::Ecore::Event::Key		PACKAGE = EcoreEventKeyPtr

char*
keyname(event)
    EcoreEventKey *event
CODE:
    RETVAL = event->keyname;
OUTPUT:
    RETVAL
 
 
int
modifiers(event)
	EcoreEventKey *event
CODE:
    RETVAL = event->modifiers;
OUTPUT:
    RETVAL
    
    
const char*
key(event)
    EcoreEventKey *event
CODE:
    RETVAL = event->key;
OUTPUT:
    RETVAL
  
  
const char*
string(event)
    EcoreEventKey *event
CODE:
    RETVAL = event->string;
OUTPUT:
    RETVAL
  
  
const char*
compose(event)
    EcoreEventKey *event
CODE:
    RETVAL = event->compose;
OUTPUT:
    RETVAL


unsigned int
timestamp(event)
    EcoreEventKey *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
void
window(event)
	EcoreEventKey *event
CODE:
	printf("the window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

void
root_window(event)
	EcoreEventKey *event
CODE:
	printf("the root_window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

void
event_window(event)
	EcoreEventKey *event
CODE:
	printf("the event_window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

int
same_screen(event)
    EcoreEventKey *event
CODE:
    RETVAL = event->keycode;
OUTPUT:
    RETVAL

