#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmSeparator;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Separator		PACKAGE = pEFL::Elm::Separator

ElmSeparator * 
elm_separator_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Separator		PACKAGE = ElmSeparatorPtr     PREFIX = elm_separator_

void
elm_separator_horizontal_set(obj,horizontal)
	ElmSeparator *obj
	Eina_Bool horizontal


Eina_Bool
elm_separator_horizontal_get(obj)
	const ElmSeparator *obj


