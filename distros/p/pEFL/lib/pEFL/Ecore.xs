#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>
#include <Ecore_Evas.h>
#include <Ecore_Input.h>

#include "const-ecore-c.inc"

MODULE = pEFL::Ecore		PACKAGE = pEFL::Ecore	PREFIX = ecore_

INCLUDE: const-ecore-xs.inc

void
ecore_init()

#Ecore_Memory_State
#ecore_memory_state_get()

#void
#ecore_memory_state_set(state)
#	Ecore_Memory_State state


#Ecore_Power_State
#ecore_power_state_get()
	 


#void
#ecore_power_state_set(state)
#	Ecore_Power_State state
