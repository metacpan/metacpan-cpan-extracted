#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Index_Item ElmIndexItem;
typedef Evas_Object EvasObject;


MODULE = pEFL::Elm::IndexItem		PACKAGE = ElmIndexItemPtr     PREFIX = elm_index_item_

void
elm_index_item_selected_set(obj,selected)
	ElmIndexItem *obj
	Eina_Bool selected


void
elm_index_item_priority_set(obj,priority)
	ElmIndexItem *obj
	int priority


char *
elm_index_item_letter_get(obj)
	ElmIndexItem *obj
