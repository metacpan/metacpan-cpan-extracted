#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>
#include <Ecore_Input.h>

typedef Ecore_Event_Mouse_Wheel EcoreEventMouseWheel;


MODULE = pEFL::Ecore::Event::MouseWheel		PACKAGE = EcoreEventMouseWheelPtr

void
window(event)
	EcoreEventMouseWheel *event
CODE:
	printf("the window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

void
root_window(event)
	EcoreEventMouseWheel *event
CODE:
	printf("the root_window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

void
event_window(event)
	EcoreEventMouseWheel *event
CODE:
	printf("the event_window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");


unsigned int
timestamp(event)
    EcoreEventMouseWheel *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
int
modifiers(event)
	EcoreEventMouseWheel *event
CODE:
    RETVAL = event->modifiers;
OUTPUT:
    RETVAL

int
same_screen(event)
    EcoreEventMouseWheel *event
CODE:
    RETVAL = event->same_screen;
OUTPUT:
    RETVAL  


int
direction(event)
    EcoreEventMouseWheel *event
CODE:
    RETVAL = event->direction;
OUTPUT:
    RETVAL

int
z(event)
    EcoreEventMouseWheel *event
CODE:
    RETVAL = event->z;
OUTPUT:
    RETVAL
    
int
x(event)
    EcoreEventMouseWheel *event
CODE:
    RETVAL = event->x;
OUTPUT:
    RETVAL
  
int
y(event)
    EcoreEventMouseWheel *event
CODE:
    RETVAL = event->y;
OUTPUT:
    RETVAL
    
    
HV *
root(event)
    EcoreEventMouseWheel *event
PREINIT:
	HV *hash;
	int x;
	int y;
CODE:
	x = event->root.x;
	y = event->root.y;
	
	hash = (HV*) sv_2mortal( (SV*) newHV() );
	
	hv_store(hash,"x",1,newSViv(x),0);
	hv_store(hash,"y",1,newSViv(y),0);
    
    RETVAL = hash;
OUTPUT:
    RETVAL