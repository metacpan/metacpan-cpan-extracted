#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"

typedef Ecore_Timer EcoreTimer;

MODULE = pEFL::Ecore::Timer		PACKAGE = pEFL::Ecore::Timer   PREFIX = ecore_timer_


double
ecore_timer_precision_get()


void
ecore_timer_precision_set(precision)
	double precision


char *
ecore_timer_dump()


EcoreTimer *
_ecore_timer_add(in,func,id)
	double in
	SV *func
	int id
CODE:
    RETVAL = ecore_timer_add(in,call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL

EcoreTimer *
_ecore_timer_loop_add(in,func,id)
	double in
	SV *func
	int id
CODE:
    RETVAL = ecore_timer_loop_add(in,call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL


MODULE = pEFL::Ecore::Timer		PACKAGE = EcoreTimerPtr   PREFIX = ecore_timer_

int
ecore_timer_del(timer)
	EcoreTimer *timer
CODE:
	void * data;
	int id;
	AV *Task_Cbs;
	data = ecore_timer_del(timer);
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
				// The timer isn't valid any more and doesn't need to be deleted
				// in fact we cannot delete it anymore, return undef (so as C does with NULL)
				XSRETURN_UNDEF;
			}
		}
	}
	RETVAL=id;
OUTPUT:
	RETVAL

void
ecore_timer_freeze(timer)
	EcoreTimer *timer


Eina_Bool
ecore_timer_freeze_get(timer)
	EcoreTimer *timer


void
ecore_timer_thaw(timer)
	EcoreTimer *timer


void
ecore_timer_interval_set(obj,in)
	EcoreTimer *obj
	double in


double
ecore_timer_interval_get(obj)
	const EcoreTimer *obj


double
ecore_timer_pending_get(obj)
	const EcoreTimer *obj


void
ecore_timer_reset(obj)
	EcoreTimer *obj


void
ecore_timer_loop_reset(obj)
	EcoreTimer *obj


void
ecore_timer_delay(obj,add)
	EcoreTimer *obj
	double add
