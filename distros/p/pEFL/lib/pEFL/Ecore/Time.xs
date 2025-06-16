#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

MODULE = pEFL::Ecore::Time		PACKAGE = pEFL::Ecore::Time   PREFIX = ecore_time_

double
ecore_time_get()
	 
double
ecore_time_unix_get()
	 
double
ecore_loop_time_get()
	 
void
ecore_loop_time_set(t)
	double t
