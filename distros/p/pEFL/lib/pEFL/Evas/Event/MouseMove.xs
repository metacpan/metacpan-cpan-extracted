#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Event_Mouse_Move EvasEventMouseMove;
typedef Evas_Modifier EvasModifier;
typedef Evas_Lock EvasLock;
typedef Evas_Object EvasObject;


MODULE = pEFL::Evas::Event::MouseMove		PACKAGE = EvasEventMouseMovePtr

int
buttons(event)
    EvasEventMouseMove *event
CODE:
    RETVAL = event->buttons;
OUTPUT:
    RETVAL
    
    
HV *
cur(event)
    EvasEventMouseMove *event
PREINIT:
	HV *hash;
	HV *output_hash;
	HV *canvas_hash;
	Evas_Position position;
	Evas_Point output;
	Evas_Coord_Point canvas;
	int x;
	int y;
CODE:
	position = event->cur;
	
	// Fill Output hash
	output = position.output;
	output_hash = newHV();
	x = output.x;
	y = output.y;
	hv_store(output_hash,"x",1,newSViv(x),0);
	hv_store(output_hash,"y",1,newSViv(y),0);
	
	// Fill Output hash
	canvas = position.canvas;
	canvas_hash = newHV();
	x = canvas.x;
	y = canvas.y;
	hv_store(canvas_hash,"x",1,newSViv(x),0);
	hv_store(canvas_hash,"y",1,newSViv(y),0);
	
	hash = (HV*) sv_2mortal( (SV*) newHV() );
	hv_store(hash,"output",6,newRV_noinc( (SV*) output_hash),0);
	hv_store(hash,"canvas",6,newRV_noinc( (SV*) canvas_hash),0);
    
    RETVAL = hash;
OUTPUT:
    RETVAL


HV *
prev(event)
    EvasEventMouseMove *event
PREINIT:
	HV *hash;
	HV *output_hash;
	HV *canvas_hash;
	Evas_Position position;
	Evas_Point output;
	Evas_Coord_Point canvas;
	int x;
	int y;
CODE:
	position = event->prev;
	
	// Fill Output hash
	output = position.output;
	output_hash = newHV();
	x = output.x;
	y = output.y;
	hv_store(output_hash,"x",1,newSViv(x),0);
	hv_store(output_hash,"y",1,newSViv(y),0);
	
	// Fill Output hash
	canvas = position.canvas;
	canvas_hash = newHV();
	x = canvas.x;
	y = canvas.y;
	hv_store(canvas_hash,"x",1,newSViv(x),0);
	hv_store(canvas_hash,"y",1,newSViv(y),0);
	
	hash = (HV*) sv_2mortal( (SV*) newHV() );
	hv_store(hash,"output",6,newRV_noinc( (SV*) output_hash),0);
	hv_store(hash,"canvas",6,newRV_noinc( (SV*) canvas_hash),0);
    
    RETVAL = hash;
OUTPUT:
    RETVAL
 
 
EvasModifier*
modifiers(event)
	EvasEventMouseMove *event
CODE:
    RETVAL = event->modifiers;
OUTPUT:
    RETVAL
    
    
EvasLock*
locks(event)
	EvasEventMouseMove *event
CODE:
    RETVAL = event->locks;
OUTPUT:
    RETVAL
    

unsigned int
timestamp(event)
    EvasEventMouseMove *event
CODE:
    RETVAL = event->timestamp;
OUTPUT:
    RETVAL
    
    
int
event_flags(event)
    EvasEventMouseMove *event
CODE:
    RETVAL = event->event_flags;
OUTPUT:
    RETVAL

    
void
dev(event)
	EvasEventMouseMove *event
CODE:
	printf("the dev member of the event struct is at the moment not supported in Perl. Sorry :-( \n");

	
EvasObject *
event_src(event)
    EvasEventMouseMove *event
CODE:
    RETVAL = event->event_src;
OUTPUT:
    RETVAL

