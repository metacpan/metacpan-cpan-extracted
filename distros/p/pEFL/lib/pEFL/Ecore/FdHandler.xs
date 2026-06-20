#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"

typedef Ecore_Fd_Handler EcoreFdHandler;

MODULE = pEFL::Ecore::FdHandler		PACKAGE = pEFL::Ecore::FdHandler   PREFIX = ecore_main_fd_handler_


EcoreFdHandler *
_ecore_main_fd_handler_add(fd,func,flags,id)
    int fd
	SV *func
	int flags
	int id
CODE:
    RETVAL = ecore_main_fd_handler_add(fd,flags,call_perl_ecore_fd_cb,(void *) (intptr_t) id, NULL, NULL);
OUTPUT:
    RETVAL


MODULE = pEFL::Ecore::FdHandler		PACKAGE = EcoreFdHandlerPtr   PREFIX = ecore_main_fd_handler_

int
ecore_main_fd_handler_del(fdhandler)
	EcoreFdHandler *fdhandler
CODE:
	void * data;
	int id;
	AV *Task_Cbs;
	data = ecore_main_fd_handler_del(fdhandler);
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
				// The fdhandler isn't valid any more and doesn't need to be deleted
				// in fact we cannot delete it anymore, return undef (so as C does with NULL)
				XSRETURN_UNDEF;
			}
		}
	}
	RETVAL=id;
OUTPUT:
	RETVAL

int
ecore_main_fd_handler_fd_get(fdhandler)
	EcoreFdHandler *fdhandler

Eina_Bool
ecore_main_fd_handler_active_get(fdhandler, flags)
	EcoreFdHandler *fdhandler
	int flags
	
void
ecore_main_fd_handler_active_set(fdhandler, flags)
	EcoreFdHandler *fdhandler
	int flags
