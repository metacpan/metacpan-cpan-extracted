#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Notify ElmNotify;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Notify		PACKAGE = pEFL::Elm::Notify

ElmNotify * 
elm_notify_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Notify		PACKAGE = ElmNotifyPtr     PREFIX = elm_notify_

void
elm_notify_parent_set(obj,parent)
	ElmNotify *obj
	EvasObject *parent


EvasObject *
elm_notify_parent_get(obj)
	ElmNotify *obj

void
elm_notify_align_set(obj,horizontal,vertical)
	ElmNotify *obj
	double horizontal
	double vertical


void
elm_notify_align_get(obj,OUTLIST horizontal,OUTLIST vertical)
	ElmNotify *obj
	double horizontal
	double vertical


void
elm_notify_allow_events_set(obj,allow)
	ElmNotify *obj
	Eina_Bool allow


Eina_Bool
elm_notify_allow_events_get(obj)
	ElmNotify *obj


void
elm_notify_timeout_set(obj,timeout)
	ElmNotify *obj
	double timeout


double
elm_notify_timeout_get(obj)
	ElmNotify *obj


void
elm_notify_dismiss(obj)
	ElmNotify *obj


