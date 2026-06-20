#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

typedef int intArray;

intArray * intArrayPtr (int num) {
	intArray *array;
	New(0,array,num,intArray);
	return array;
}


MODULE = pEFL::Ecore::EventType		PACKAGE = pEFL::Ecore::EventType   PREFIX = ecore_event_type

int
_ecore_event_type_new()
CODE:
	RETVAL = ecore_event_type_new();
OUTPUT:
	RETVAL


void
_ecore_event_type_flush_internal(type, array, ...)
	int type
	intArray * array
CODE:
	ecore_event_type_flush_internal(type, array);
CLEANUP:
	Safefree(array);