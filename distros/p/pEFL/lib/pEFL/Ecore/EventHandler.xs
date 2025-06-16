#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"

typedef Ecore_Event_Handler EcoreEventHandler;

MODULE = pEFL::Ecore::EventHandler		PACKAGE = pEFL::Ecore::EventHandler   PREFIX = ecore_event_handler_

EcoreEventHandler *
_ecore_event_handler_add(type,func,id)
	int type
	SV *func
	int id
CODE:
    RETVAL = ecore_event_handler_add(type,call_perl_ecore_event_handler_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL

EcoreEventHandler *
_ecore_event_handler_prepend(type,func,id)
	int type
	SV *func
	int id
CODE:
    RETVAL = ecore_event_handler_prepend(type,call_perl_ecore_event_handler_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL

MODULE = pEFL::Ecore::EventHandler		PACKAGE = EcoreEventHandlerPtr   PREFIX = ecore_event_handler_

void
ecore_event_handler_del(event_handler)
	EcoreEventHandler *event_handler
PREINIT:
	void *data;
	int id;
CODE:
	data = ecore_event_handler_del(event_handler);
	id = (intptr_t) data;
	AV *Cbs_data = get_av("pEFL::PLSide::EcoreEventHandler_Cbs", 0);
	av_store(Cbs_data, (I32) id,&PL_sv_undef);
	free( (void*) data);
	
	
#void *
#ecore_event_handler_data_get(eh)
#	EcoreEventHandler *eh


#void *
#ecore_event_handler_data_set(eh,data)
#	EcoreEventHandler *eh
#	const void *data
