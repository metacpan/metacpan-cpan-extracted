#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Genlist_Item_Class ElmGenlistItemClass;


MODULE = pEFL::Elm::GenlistItemClass		PACKAGE = pEFL::Elm::GenlistItemClass

ElmGenlistItemClass *
elm_genlist_item_class_new()
PREINIT:
    ElmGenlistItemClass *itc;
CODE:
    itc = elm_genlist_item_class_new();
    itc->func.del = call_perl_genitc_del;
    RETVAL = itc;
OUTPUT:
    RETVAL

MODULE = pEFL::Elm::GenlistItemClass		PACKAGE = ElmGenlistItemClassPtr     PREFIX = elm_genlist_item_class_

void
elm_genlist_item_class_free(itc)
	ElmGenlistItemClass *itc


void
elm_genlist_item_class_ref(itc)
	ElmGenlistItemClass *itc


void
elm_genlist_item_class_unref(itc)
	ElmGenlistItemClass *itc

void
_elm_genlist_item_class_text_get(itc)
    ElmGenlistItemClass *itc
CODE:
    itc->func.text_get = call_perl_gen_text_get;
    
void
_elm_genlist_item_class_content_get(itc)
    ElmGenlistItemClass *itc
CODE:
    itc->func.content_get = call_perl_gen_content_get;

void
_elm_genlist_item_class_state_get(itc)
    ElmGenlistItemClass *itc
CODE:
    itc->func.state_get = call_perl_gen_state_get;
    
void
elm_genlist_item_class_item_style(itc, style)
    ElmGenlistItemClass *itc
    char *style
CODE:
    itc->item_style = style;
