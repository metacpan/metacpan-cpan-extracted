#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Menu ElmMenu;
typedef Evas_Object EvasObject;
typedef Elm_Menu_Item ElmMenuItem;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Menu		PACKAGE = pEFL::Elm::Menu

ElmMenu * 
elm_menu_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Menu		PACKAGE = ElmMenuPtr     PREFIX = elm_menu_

void
elm_menu_parent_set(obj,parent)
	ElmMenu *obj
	EvasObject *parent


EvasObject *
elm_menu_parent_get(obj)
	ElmMenu *obj

ElmMenuItem *
elm_menu_selected_item_get(obj)
	ElmMenu *obj


ElmMenuItem *
elm_menu_first_item_get(obj)
	ElmMenu *obj


ElmMenuItem *
elm_menu_last_item_get(obj)
	ElmMenu *obj


EinaList *
elm_menu_items_get(obj)
	ElmMenu *obj


void
elm_menu_move(obj,x,y)
	ElmMenu *obj
	int x
	int y


# func ist eigtl. Evas_Smart_Cb func
ElmMenuItem *
_elm_menu_item_add(obj,parent,icon,label,id)
	ElmMenu *obj
	ElmMenuItem *parent
	const char *icon
	const char *label
	int id;
PREINIT:
    _perl_gendata *data;
    UV objaddr;
    ElmMenuItem *item;
CODE:
    if (!parent) 
        parent = NULL;
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_menu_item_add(obj,parent,icon,label,call_perl_gen_item_selected,data);
    elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL

void
elm_menu_open(obj)
	ElmMenu *obj


void
elm_menu_close(obj)
	ElmMenu *obj


ElmMenuItem *
elm_menu_item_separator_add(obj,parent)
	ElmMenu *obj
	ElmMenuItem *parent
