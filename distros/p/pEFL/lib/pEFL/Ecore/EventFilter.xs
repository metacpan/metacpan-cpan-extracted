#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>

typedef Ecore_Event_Filter EcoreEventFilter;

MODULE = pEFL::Ecore::EventFilter		PACKAGE = pEFL::Ecore::EventFilter   PREFIX = ecore_event_filter_

#EcoreEventFilter *
#ecore_event_filter_add(func_start,func_filter,func_end,data)
#	Ecore_Data_Cb func_start
#	Ecore_Filter_Cb func_filter
#	Ecore_End_Cb func_end
#	const void *data

MODULE = pEFL::Ecore::EventFilter		PACKAGE = EcoreEventFilterPtr   PREFIX = ecore_event_filter_

#void *
#ecore_event_filter_del(ef)
#	EcoreEventFilter *ef
