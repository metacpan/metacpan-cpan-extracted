#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Combobox ElmCombobox;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Combobox		PACKAGE = pEFL::Elm::Combobox

ElmCombobox * 
elm_combobox_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Combobox		PACKAGE = ElmComboboxPtr     PREFIX = elm_combobox_

Eina_Bool 
elm_combobox_expanded_get(const ElmCombobox *obj);

void 
elm_combobox_hover_begin(ElmCombobox *obj);

void 
elm_combobox_hover_end(ElmCombobox *obj);