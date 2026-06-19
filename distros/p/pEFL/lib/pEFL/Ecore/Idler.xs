#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"

typedef Ecore_Idler EcoreIdler;
typedef Ecore_Idle_Enterer EcoreIdleEnterer;
typedef Ecore_Idle_Exiter EcoreIdleExiter;

MODULE = pEFL::Ecore::Idler		PACKAGE = pEFL::Ecore::Idler   PREFIX = ecore_idler_

EcoreIdler *
_ecore_idler_add(func,id)
	SV *func
	int id
CODE:
    RETVAL = ecore_idler_add(call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL
    
    
EcoreIdleEnterer *
_ecore_idle_enterer_add(func,id)
	SV *func
	int id
CODE:
    RETVAL = ecore_idle_enterer_add(call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL


EcoreIdleEnterer *
_ecore_idle_enterer_before_add(func,id)
	SV *func
	int id
CODE:
    RETVAL = ecore_idle_enterer_before_add(call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL
    

EcoreIdleExiter *
_ecore_idle_exiter_add(func,id)
	SV *func
	int id
CODE:
    RETVAL = ecore_idle_exiter_add(call_perl_task_cb,(void *) (intptr_t) id);
OUTPUT:
    RETVAL


MODULE = pEFL::Ecore::Idler		PACKAGE = EcoreIdlerPtr   PREFIX = ecore_idler_

int
ecore_idler_del(idler)
	EcoreIdler *idler
CODE:
	void * data;
	int id;
	AV *Task_Cbs;
	data = ecore_idler_del(idler);
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
				// The idler isn't valid any more and doesn't need to be deleted
				// in fact we cannot delete it anymore, return undef (so as C does with NULL)
				XSRETURN_UNDEF;
			}
		}
	}
	RETVAL=id;
OUTPUT:
	RETVAL
	
	
MODULE = pEFL::Ecore::Idler		PACKAGE = EcoreIdleEntererPtr   PREFIX = ecore_idle_enterer_

int
ecore_idle_enterer_del(idler)
	EcoreIdleEnterer *idler
CODE:
	void * data;
	int id;
	AV *Task_Cbs;
	data = ecore_idle_enterer_del(idler);
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
				// The idler isn't valid any more and doesn't need to be deleted
				// in fact we cannot delete it anymore, return undef (so as C does with NULL)
				XSRETURN_UNDEF;
			}
		}
	}
	RETVAL=id;
OUTPUT:
	RETVAL
	
	
MODULE = pEFL::Ecore::Idler		PACKAGE = EcoreIdleExiterPtr   PREFIX = ecore_idle_exiter_

int
ecore_idle_exiter_del(idler)
	EcoreIdleExiter *idler
CODE:
	void * data;
	int id;
	AV *Task_Cbs;
	data = ecore_idle_exiter_del(idler);
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
				// The idler isn't valid any more and doesn't need to be deleted
				// in fact we cannot delete it anymore, return undef (so as C does with NULL)
				XSRETURN_UNDEF;
			}
		}
	}
	RETVAL=id;
OUTPUT:
	RETVAL
