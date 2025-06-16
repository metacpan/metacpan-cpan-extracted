#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>
#include <Ecore_Input.h>

typedef Ecore_Event EcoreEvent;
typedef int intArray;

intArray * intArrayPtr (int num) {
	intArray *array;
	New(0,array,num,intArray);
	return array;
}

MODULE = pEFL::Ecore::Event		PACKAGE = pEFL::Ecore::Event   PREFIX = ecore_event_

int
ecore_event_init()

int
ecore_event_shutdown()

#EcoreEvent *
#ecore_event_add(type,ev,func_free,data)
#	int type
#	void *ev
#	SV *func_free
#	void *data

int
ecore_event_type_new()

void
ecore_event_type_flush_internal(type, array, ...)
	int type
	intArray * array
CODE:
	ecore_event_type_flush_internal(type, array);
CLEANUP:
	Safefree(array);


int
ecore_event_current_type_get()

#void *
#ecore_event_current_event_get()

MODULE = pEFL::Ecore::Event		PACKAGE = EcoreEventPtr   PREFIX = ecore_event_

void *
ecore_event_del(event)
	EcoreEvent *event

