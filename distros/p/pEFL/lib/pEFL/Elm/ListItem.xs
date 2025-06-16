#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_List_Item ElmListItem;
typedef Evas_Object EvasObject;


MODULE = pEFL::Elm::ListItem		PACKAGE = ElmListItemPtr     PREFIX = elm_list_item_

void
elm_list_item_separator_set(obj,setting)
	ElmListItem *obj
	Eina_Bool setting
	
Eina_Bool
elm_list_item_separator_get(obj)
	ElmListItem *obj
	
void
elm_list_item_selected_set(obj,selected)
	ElmListItem *obj
	Eina_Bool selected
	
Eina_Bool
elm_list_item_selected_get(obj)
	ElmListItem *obj
	
EvasObject *
elm_list_item_object_get(obj)
	ElmListItem *obj

# eigtl. ElmWidgetItem; besser noch ElmListItem???
ElmListItem *
elm_list_item_prev(obj)
	ElmListItem *obj
	
ElmListItem *
elm_list_item_next(obj)
	ElmListItem *obj
	
void
elm_list_item_show(obj)
	ElmListItem *obj
	
void
elm_list_item_bring_in(obj)
	ElmListItem *obj
