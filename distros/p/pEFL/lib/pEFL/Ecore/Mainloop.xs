#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

#include "PLSide.h"


MODULE = pEFL::Ecore::Mainloop		PACKAGE = pEFL::Ecore::Mainloop   PREFIX = ecore_main_loop_


void
ecore_main_loop_iterate()	 


int
ecore_main_loop_iterate_may_block(may_block)
	int may_block

# void
# ecore_main_loop_select_func_set(func)
#	Ecore_Select_Function func


# Ecore_Select_Function
# ecore_main_loop_select_func_get()


Eina_Bool
ecore_main_loop_glib_integrate()


void
ecore_main_loop_glib_always_integrate_disable()


void
ecore_main_loop_begin()	 


void
ecore_main_loop_quit()


Eina_Bool
ecore_main_loop_animator_ticked_get()	 


int
ecore_main_loop_nested_get()


# Eina_Bool
# ecore_fork_reset_callback_add(func,data)
#	Ecore_Cb func
#	const void *data


# Eina_Bool
# ecore_fork_reset_callback_del(func,data)
#	Ecore_Cb func
#	const void *data


void
ecore_fork_reset()	 


# void
# ecore_main_loop_thread_safe_call_async(callback,data)
#	Ecore_Cb callback
#	void *data


# void *
# ecore_main_loop_thread_safe_call_sync(callback,data)
#	Ecore_Data_Cb callback
#	void *data


# void
# ecore_main_loop_thread_safe_call_wait(wait)
#	double wait


# int
# ecore_thread_main_loop_begin()


# int
# ecore_thread_main_loop_end()
