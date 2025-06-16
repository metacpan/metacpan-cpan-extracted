#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_Float_Set EdjeMessageFloatSet;

MODULE = pEFL::Edje::Message::FloatSet		PACKAGE = pEFL::Edje::Message::FloatSet

EdjeMessageFloatSet *
_new(class,count, val_arr)
	char *class
	int count
	AV *val_arr
PREINIT:
	EdjeMessageFloatSet *message;
	double *val;
	int index;
CODE:
	Newx(message,1,EdjeMessageFloatSet);
	Renewc(message,count+2,double,EdjeMessageFloatSet);
	if (message == NULL) 
		croak("Failed to allocate memory in _new function\n");
	message->count = count+1;
	for (index = 0; index <= count; index++) {
		message->val[index] = SvNV( *av_fetch(val_arr,index,0) );
	}
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::FloatSet		PACKAGE = EdjeMessageFloatSetPtr

int
count(message)
    EdjeMessageFloatSet *message
CODE:
    RETVAL = message->count;
OUTPUT:
    RETVAL
    
void
val(message)
    EdjeMessageFloatSet *message
PREINIT:
	int count;
	double *vals;
	int index;
PPCODE:
    count = message->count;
    vals = message->val;
    
    EXTEND(SP,count);
    for (index = 0; index <count; index++) {
    	PUSHs( sv_2mortal( newSVnv( vals[index] ) ));
	}
	
void
DESTROY(message) 
    EdjeMessageFloatSet *message
CODE:
	//printf("Freeing Message_Float_Set\n");
	Safefree(message);