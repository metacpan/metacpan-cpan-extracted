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

void *
ecore_timer_del(timer)
	EcoreTimer *timer


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
