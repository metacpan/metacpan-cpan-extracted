#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Evas_Object ElmSlider;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Slider		PACKAGE = pEFL::Elm::Slider

ElmSlider *
elm_slider_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Slider		PACKAGE = ElmSliderPtr     PREFIX = elm_slider_


void
elm_slider_horizontal_set(obj,horizontal)
	ElmSlider *obj
	Eina_Bool horizontal


Eina_Bool
elm_slider_horizontal_get(obj)
	const ElmSlider *obj


void
elm_slider_value_set(obj,val)
	ElmSlider *obj
	double val


double
elm_slider_value_get(obj)
	const ElmSlider *obj


void
elm_slider_inverted_set(obj,inverted)
	ElmSlider *obj
	Eina_Bool inverted


Eina_Bool
elm_slider_inverted_get(obj)
	const ElmSlider *obj


void
elm_slider_span_size_set(obj,size)
	ElmSlider *obj
	int size


int
elm_slider_span_size_get(obj)
	const ElmSlider *obj


void
elm_slider_unit_format_set(obj,units)
	ElmSlider *obj
	const char *units


char *
elm_slider_unit_format_get(obj)
	const ElmSlider *obj


void
_elm_slider_units_format_function_set(obj,func)
	ElmSlider *obj
	SV* func
PREINIT:
        _perl_callback *sc = NULL;
        UV objaddr;
CODE:
	objaddr = PTR2IV(obj);
	sc = perl_save_callback(aTHX_ func, objaddr, NULL, "pEFL::PLSide::Format_Cbs");
	elm_slider_units_format_function_set_full(obj,call_perl_format_cb,free_buf,(void *) sc);


void
elm_slider_min_max_set(obj,min,max)
	ElmSlider *obj
	double min
	double max


void
elm_slider_min_max_get(obj,OUTLIST min,OUTLIST max)
	const ElmSlider *obj
	double min
	double max


void
elm_slider_range_enabled_set(obj,enable)
	ElmSlider *obj
	Eina_Bool enable


Eina_Bool
elm_slider_range_enabled_get(obj)
	const ElmSlider *obj


void
elm_slider_range_set(obj,from,to)
	ElmSlider *obj
	double from
	double to


void
elm_slider_range_get(obj,OUTLIST from,OUTLIST to)
	const ElmSlider *obj
	double from
	double to


void
elm_slider_indicator_format_set(obj,indicator)
	ElmSlider *obj
	const char *indicator


char *
elm_slider_indicator_format_get(obj)
	const ElmSlider *obj


void
_elm_slider_indicator_format_function_set(obj,func)
	ElmSlider *obj
	SV* func
PREINIT:
	_perl_callback *sc = NULL;
	UV objaddr;
CODE:
   objaddr = PTR2IV(obj);
   sc = perl_save_callback(aTHX_ func, objaddr, NULL, "pEFL::PLSide::Format_Cbs");
   elm_slider_indicator_format_function_set_full(obj,call_perl_format_cb,free_buf,(void *) sc);


void
elm_slider_indicator_show_on_focus_set(obj,flag)
	ElmSlider *obj
	Eina_Bool flag


Eina_Bool
elm_slider_indicator_show_on_focus_get(obj)
	const ElmSlider *obj


void
elm_slider_indicator_show_set(obj,show)
	ElmSlider *obj
	Eina_Bool show


Eina_Bool
elm_slider_indicator_show_get(obj)
	const ElmSlider *obj


void
elm_slider_indicator_visible_mode_set(obj,indicator_visible_mode)
	ElmSlider *obj
	int indicator_visible_mode


int
elm_slider_indicator_visible_mode_get(obj)
	const ElmSlider *obj


double
elm_slider_step_get(obj)
	const ElmSlider *obj


void
elm_slider_step_set(obj,step)
	ElmSlider *obj
	double step
