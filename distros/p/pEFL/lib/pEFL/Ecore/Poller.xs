#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"

typedef Ecore_Poller EcorePoller;

MODULE = pEFL::Ecore::Poller		PACKAGE = pEFL::Ecore::Poller   PREFIX = ecore_poller_


EcorePoller *
_ecore_poller_add(type, interval,func,id)
    int type
	double interval
	SV *func
	int id
CODE:
    RETVAL = ecore_poller_add(type,interval,call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL


MODULE = pEFL::Ecore::Poller		PACKAGE = EcorePollerPtr   PREFIX = ecore_poller_

void *
ecore_poller_del(poller)
	EcorePoller *poller


void
ecore_poller_poll_interval_set(type,poll_time)
	int type
	double poll_time


double
ecore_poller_poll_interval_get(type)
	int type


Eina_Bool
ecore_poller_poller_interval_set(obj,interval)
	EcorePoller *obj
	int interval


int
ecore_poller_poller_interval_get(obj)
	const EcorePoller *obj
