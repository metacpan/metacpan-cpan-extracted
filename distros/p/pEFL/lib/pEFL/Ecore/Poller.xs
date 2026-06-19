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

int
ecore_poller_del(poller)
	EcorePoller *poller
CODE:
	void * data;
	int id;
	AV *Task_Cbs;
	data = ecore_poller_del(poller);
	id = (int)(intptr_t) data;
	Task_Cbs = get_av("pEFL::PLSide::EcoreTask_Cbs", 0);
	if (Task_Cbs) {
		// if data is an index > 0, always cleanup perl array element
		if (data != NULL) {
			id = (int)(intptr_t)data;
			// Important in av_store we should not use PL_sv_undef
			// see https://perldoc.perl.org/perlguts
			av_store(Task_Cbs, (I32)id, newSV(0));
			RETVAL = id;
		}
		// Shit, data == 0, that means NULL (= error) or 0 (= first element
		// in the callback array). How can we differ?
		else {
			// Let's look for the first element in the array
			SV** first_element = av_fetch(Task_Cbs, 0, 0);
			
			// Oh, it's a valid perl value, that means it isn't automatically
			// cleaned up in perl_call_task_cb or the similiar function
			// We have to clean up here
			if (first_element && SvOK(*first_element)) {
				av_store(Task_Cbs, 0, newSV(0));
				id = 0;
				RETVAL = id;
			}
			else {
				// The poller isn't valid any more and doesn't need to be deleted
				// in fact we cannot delete it anymore, return undef (so as C does with NULL)
				XSRETURN_UNDEF;
			}
		}
	}
	RETVAL=id;
OUTPUT:
	RETVAL


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
