#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Toolbar_Item ElmToolbarItem;
typedef Elm_Toolbar_Item_State ElmToolbarItemState;
typedef Evas_Object EvasObject;


MODULE = pEFL::Elm::ToolbarItem		PACKAGE = ElmToolbarItemPtr     PREFIX = elm_toolbar_item_


ElmToolbarItem *
elm_toolbar_item_prev_get(obj)
	const ElmToolbarItem *obj


ElmToolbarItem *
elm_toolbar_item_next_get(obj)
	const ElmToolbarItem *obj


void
elm_toolbar_item_selected_set(obj,selected)
	ElmToolbarItem *obj
	Eina_Bool selected


Eina_Bool
elm_toolbar_item_selected_get(obj)
	const ElmToolbarItem *obj


void
elm_toolbar_item_priority_set(obj,priority)
	ElmToolbarItem *obj
	int priority


int
elm_toolbar_item_priority_get(obj)
	const ElmToolbarItem *obj


void
elm_toolbar_item_icon_set(obj,icon)
	ElmToolbarItem *obj
	const char *icon


char *
elm_toolbar_item_icon_get(obj)
	const ElmToolbarItem *obj


EvasObject *
elm_toolbar_item_object_get(obj)
	const ElmToolbarItem *obj


EvasObject *
elm_toolbar_item_icon_object_get(obj)
	const ElmToolbarItem *obj


void
elm_toolbar_item_separator_set(obj,separator)
	ElmToolbarItem *obj
	Eina_Bool separator


Eina_Bool
elm_toolbar_item_separator_get(obj)
	const ElmToolbarItem *obj


EvasObject *
elm_toolbar_item_menu_get(obj)
	const ElmToolbarItem *obj


Eina_Bool
elm_toolbar_item_state_set(obj,state)
	ElmToolbarItem *obj
	ElmToolbarItemState *state


ElmToolbarItemState *
elm_toolbar_item_state_get(obj)
	const ElmToolbarItem *obj


# Eina_Bool
# elm_toolbar_item_icon_memfile_set(obj,img,size,format,key)
#	ElmToolbarItem *obj
#	void *img
#	size_t size
#	const char *format
#	const char *key


Eina_Bool
elm_toolbar_item_icon_file_set(obj,file,key)
	ElmToolbarItem *obj
	const char *file
	const char *key


ElmToolbarItemState *
_elm_toolbar_item_state_add(obj,icon,label,id)
	ElmToolbarItem *obj
	const char *icon
	const char *label
	int id
PREINIT:
    _perl_gendata *data;
    UV objaddr;
CODE:
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    RETVAL = elm_toolbar_item_state_add(obj,icon,label,call_perl_gen_item_selected,data);
OUTPUT:
    RETVAL


# Eina_Bool
# elm_toolbar_item_state_del(obj,state)
#	ElmToolbarItem *obj
#	ElmToolbarItem_State *state


ElmToolbarItemState *
elm_toolbar_item_state_next(obj)
	ElmToolbarItem *obj


ElmToolbarItemState *
elm_toolbar_item_state_prev(obj)
	ElmToolbarItem *obj


void
elm_toolbar_item_show(obj,scrollto)
	ElmToolbarItem *obj
	int scrollto


void
elm_toolbar_item_bring_in(obj,scrollto)
	ElmToolbarItem *obj
	int scrollto


void
elm_toolbar_item_menu_set(obj,menu)
	ElmToolbarItem *obj
	Eina_Bool menu

void
elm_toolbar_item_state_unset(it)
	ElmToolbarItem *it
