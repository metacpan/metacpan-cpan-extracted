#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Ecore.h>
#include <Ecore_File.h>

#include "PLSide.h"

typedef Ecore_File_Monitor EcoreFileMonitor;

MODULE = pEFL::Ecore::FileMonitor		PACKAGE = pEFL::Ecore::FileMonitor   PREFIX = ecore_file_monitor_

EcoreFileMonitor * 
_ecore_file_monitor_add(path,func,id)
	char *path
	SV *func
	int id
CODE:
    RETVAL = ecore_file_monitor_add(path, call_perl_ecore_file_monitor_cb,(void *) (intptr_t) id);
OUTPUT:
	RETVAL
	

MODULE = pEFL::Ecore::FileMonitor		PACKAGE = EcoreFileMonitorPtr   PREFIX = ecore_file_monitor_

void
_ecore_file_monitor_del(monitor)
	EcoreFileMonitor *monitor
CODE:
	ecore_file_monitor_del(monitor);
	 
const char* 
ecore_file_monitor_path_get(monitor)
	EcoreFileMonitor *monitor
