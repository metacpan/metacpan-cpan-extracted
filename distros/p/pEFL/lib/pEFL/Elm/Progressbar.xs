#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Evas_Object ElmProgressbar;
typedef Evas_Object EvasObject;


MODULE = pEFL::Elm::Progressbar		PACKAGE = pEFL::Elm::Progressbar

ElmProgressbar *
elm_progressbar_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Progressbar		PACKAGE = ElmProgressbarPtr     PREFIX = elm_progressbar_


void
elm_progressbar_span_size_set(obj,size)
	ElmProgressbar *obj
	int size


int
elm_progressbar_span_size_get(obj)
	const ElmProgressbar *obj


void
elm_progressbar_value_set(obj,val)
	ElmProgressbar *obj
	double val


double
elm_progressbar_value_get(obj)
	const ElmProgressbar *obj


void
elm_progressbar_inverted_set(obj,inverted)
	ElmProgressbar *obj
	Eina_Bool inverted


Eina_Bool
elm_progressbar_inverted_get(obj)
	const ElmProgressbar *obj


void
elm_progressbar_horizontal_set(obj,horizontal)
	ElmProgressbar *obj
	Eina_Bool horizontal


Eina_Bool
elm_progressbar_horizontal_get(obj)
	const ElmProgressbar *obj


void
elm_progressbar_unit_format_set(obj,units)
	ElmProgressbar *obj
	const char *units


char *
elm_progressbar_unit_format_get(obj)
	const ElmProgressbar *obj


void
_elm_progressbar_unit_format_function_set(obj,func)
	ElmProgressbar *obj
	SV* func
PREINIT:
	_perl_callback *sc = NULL;
	UV objaddr;
CODE:
   objaddr = PTR2IV(obj);
   sc = perl_save_callback(aTHX_ func, objaddr, NULL, "pEFL::PLSide::Format_Cbs");
   elm_progressbar_unit_format_function_set_full(obj,call_perl_format_cb,free_buf,(void *) sc);


void
elm_progressbar_pulse_set(obj,pulse)
	ElmProgressbar *obj
	Eina_Bool pulse


Eina_Bool
elm_progressbar_pulse_get(obj)
	const ElmProgressbar *obj


void
elm_progressbar_pulse(obj,state)
	ElmProgressbar *obj
	Eina_Bool state


Eina_Bool
elm_progressbar_is_pulsing_get(obj)
	const ElmProgressbar *obj


void
elm_progressbar_part_value_set(obj,part,val)
	ElmProgressbar *obj
	const char *part
	double val


double
elm_progressbar_part_value_get(obj,part)
	const ElmProgressbar *obj
	const char *part
