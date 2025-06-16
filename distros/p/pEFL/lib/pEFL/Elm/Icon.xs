#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmIcon;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Icon		PACKAGE = pEFL::Elm::Icon

ElmIcon *
elm_icon_add(EvasObject *parent)

MODULE = pEFL::Elm::Icon		PACKAGE = ElmIconPtr     PREFIX = elm_icon_

char *
elm_config_icon_theme_get()

void
elm_config_icon_theme_set(theme)
    char *theme

void
elm_icon_thumb_set(obj, file, group)
    EvasObject *obj
    char *file
    char *group

# DEPRECATED
# void
# elm_icon_order_lookup_set(obj,order)
#    EvasObject *obj
#    int order

# DEPRECATED
#int
# elm_icon_order_lookup_get (obj)
#    EvasObject *obj

Eina_Bool
elm_icon_standard_set(obj,name)
    EvasObject *obj
    char *name

char *
elm_icon_standard_get(obj)
     EvasObject *obj
