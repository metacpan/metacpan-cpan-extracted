#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmInwin;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Inwin		PACKAGE = pEFL::Elm::Inwin

ElmInwin * 
elm_win_inwin_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Inwin		PACKAGE = ElmInwinPtr     PREFIX = elm_win_inwin_

void
elm_win_inwin_content_set(obj,content)
	ElmInwin *obj
	EvasObject *content


EvasObject *
elm_win_inwin_content_get(obj)
	ElmInwin *obj


EvasObject *
elm_win_inwin_content_unset(obj)
	ElmInwin *obj

void 
elm_win_inwin_activate(obj)
    ElmInwin *obj
