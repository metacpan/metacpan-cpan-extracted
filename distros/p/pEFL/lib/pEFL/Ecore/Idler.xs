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

void *
ecore_idler_del(idler)
	EcoreIdler *idler
	
	
MODULE = pEFL::Ecore::Idler		PACKAGE = EcoreIdleEntererPtr   PREFIX = ecore_idle_enterer_

void *
ecore_idle_enterer_del(idler)
	EcoreIdleEnterer *idler
	
	
MODULE = pEFL::Ecore::Idler		PACKAGE = EcoreIdleExiterPtr   PREFIX = ecore_idle_exiter_

void *
ecore_idle_exiter_del(idler)
	EcoreIdleExiter *idler
