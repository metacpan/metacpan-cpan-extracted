#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Hoversel ElmHoversel;
typedef Elm_Object_Item ElmObjectItem;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Hoversel		PACKAGE = pEFL::Elm::Hoversel

ElmHoversel * 
elm_hoversel_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Hoversel		PACKAGE = ElmHoverselPtr     PREFIX = elm_hoversel_

void
elm_hoversel_horizontal_set(obj,horizontal)
	ElmHoversel *obj
	Eina_Bool horizontal


Eina_Bool
elm_hoversel_horizontal_get(obj)
	ElmHoversel *obj


void
elm_hoversel_hover_parent_set(obj,parent)
	ElmHoversel *obj
	EvasObject *parent


EvasObject *
elm_hoversel_hover_parent_get(obj)
	ElmHoversel *obj


Eina_Bool
elm_hoversel_expanded_get(obj)
	ElmHoversel *obj


EinaList *
elm_hoversel_items_get(obj)
	ElmHoversel *obj


void
elm_hoversel_auto_update_set(obj,auto_update)
	ElmHoversel *obj
	Eina_Bool auto_update


Eina_Bool
elm_hoversel_auto_update_get(obj)
	ElmHoversel *obj


void
elm_hoversel_hover_begin(obj)
	ElmHoversel *obj


void
elm_hoversel_clear(obj)
	ElmHoversel *obj


void
elm_hoversel_hover_end(obj)
	ElmHoversel *obj


ElmObjectItem *
_elm_hoversel_item_add(obj,label,icon_file,icon_type,id)
	ElmHoversel *obj
	const char *label
	const char *icon_file
	int icon_type
	int id
PREINIT:
    _perl_gendata *data;
    UV objaddr;
    ElmObjectItem *item;
CODE:
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_hoversel_item_add(obj,label,icon_file,icon_type,call_perl_gen_item_selected,data);
    elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL


