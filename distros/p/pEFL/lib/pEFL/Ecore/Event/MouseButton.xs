#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>
#include <Ecore_Input.h>

typedef Ecore_Event_Mouse_Button EcoreEventMouseButton;


MODULE = pEFL::Ecore::Event::MouseButton		PACKAGE = EcoreEventMouseButtonPtr

void
window(event)
	EcoreEventMouseButton *event
CODE:
	printf("the window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

void
root_window(event)
	EcoreEventMouseButton *event
CODE:
	printf("the root_window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

void
event_window(event)
	EcoreEventMouseButton *event
CODE:
	printf("the event_window member of the event struct is at the moment not supported in Perl. Sorry :-( \n");


unsigned int
timestamp(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
int
modifiers(event)
	EcoreEventMouseButton *event
CODE:
    RETVAL = event->modifiers;
OUTPUT:
    RETVAL

unsigned int
buttons(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->buttons;
OUTPUT:
    RETVAL
    

unsigned int
double_click(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->double_click;
OUTPUT:
    RETVAL
    

unsigned int
triple_click(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->triple_click;
OUTPUT:
    RETVAL

int
same_screen(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->same_screen;
OUTPUT:
    RETVAL  


int
x(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->x;
OUTPUT:
    RETVAL

int
y(event)
    EcoreEventMouseButton *event
CODE:
    RETVAL = event->y;
OUTPUT:
    RETVAL
  
    
HV *
root(event)
    EcoreEventMouseButton *event
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
    
HV *
multi(event)
	EcoreEventMouseButton *event
PREINIT:
	HV *hash;
	int device;
	double radius;
	double radius_x;
	double radius_y;
	double pressure;
	double angle;
	double x;
	double y;
	HV *root;
CODE:
	device = event->multi.device;
	radius = event->multi.radius;
	radius_x = event->multi.radius_x;
	radius_y = event->multi.radius_y;
	pressure = event->multi.pressure;
	angle = event->multi.angle;
	x = event->multi.x;
	y = event->multi.y;
	
	hash = (HV*) sv_2mortal( (SV*) newHV() );
	
	hv_store(hash,"device",6,newSViv(device),0);
	hv_store(hash,"radius",6,newSVnv(radius),0);
	hv_store(hash,"radius_x",8,newSVnv(radius_x),0);
	hv_store(hash,"radius_y",8,newSVnv(radius_y),0);
	hv_store(hash,"pressure",8,newSVnv(pressure),0);
	hv_store(hash,"angle",5,newSVnv(angle),0);
	hv_store(hash,"x",1,newSVnv(x),0);
	hv_store(hash,"y",1,newSVnv(y),0);
    
    RETVAL = hash;
OUTPUT:
    RETVAL