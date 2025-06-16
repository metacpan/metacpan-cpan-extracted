#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmCheck;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Check		PACKAGE = pEFL::Elm::Check

ElmCheck * 
elm_check_add(EvasObject *parent)

MODULE = pEFL::Elm::Check		PACKAGE = ElmCheckPtr     PREFIX = elm_check_

void
elm_check_state_set(obj,state)
    EvasObject *obj
    Eina_Bool state
    
Eina_Bool
elm_check_state_get(obj)
    EvasObject *obj

void
elm_check_state_pointer_set(obj,statep)
    EvasObject *obj
    Eina_Bool *statep
    
