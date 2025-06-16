#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Menu_Item ElmMenuItem;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::MenuItem		PACKAGE = ElmMenuItemPtr     PREFIX = elm_menu_item_

void
elm_menu_item_icon_name_set(obj,icon)
	ElmMenuItem *obj
	const char *icon


char *
elm_menu_item_icon_name_get(obj)
	ElmMenuItem *obj


ElmMenuItem *
elm_menu_item_prev_get(obj)
	ElmMenuItem *obj


ElmMenuItem *
elm_menu_item_next_get(obj)
	ElmMenuItem *obj


void
elm_menu_item_selected_set(obj,selected)
	ElmMenuItem *obj
	Eina_Bool selected


Eina_Bool
elm_menu_item_selected_get(obj)
	ElmMenuItem *obj


int
elm_menu_item_index_get(obj)
	ElmMenuItem *obj


void
elm_menu_item_subitems_clear(obj)
	ElmMenuItem *obj


EinaList *
elm_menu_item_subitems_get(obj)
	ElmMenuItem *obj


Eina_Bool
elm_menu_item_is_separator(obj)
	ElmMenuItem *obj


EvasObject *
elm_menu_item_object_get(obj)
	ElmMenuItem *obj


