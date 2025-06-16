#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Toolbar ElmToolbar;
typedef Elm_Toolbar_Item ElmToolbarItem;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Toolbar 	PACKAGE = pEFL::Elm::Toolbar

ElmToolbar * 
elm_toolbar_add(parent)
	EvasObject *parent

MODULE = pEFL::Elm::Toolbar 	PACKAGE = ElmToolbarPtr 	PREFIX = elm_toolbar_


void
elm_toolbar_reorder_mode_set(obj,reorder_mode)
	ElmToolbar *obj
	Eina_Bool reorder_mode


Eina_Bool
elm_toolbar_reorder_mode_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_transverse_expanded_set(obj,transverse_expanded)
	ElmToolbar *obj
	Eina_Bool transverse_expanded


Eina_Bool
elm_toolbar_transverse_expanded_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_icon_order_lookup_set(obj,order)
	ElmToolbar *obj
	int order


int
elm_toolbar_icon_order_lookup_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_horizontal_set(obj,horizontal)
	ElmToolbar *obj
	Eina_Bool horizontal


Eina_Bool
elm_toolbar_horizontal_get(obj)
	const ElmToolbar *obj

# TODO ab hier:

ElmToolbarItem *
elm_toolbar_selected_item_get(obj)
	const ElmToolbar *obj


ElmToolbarItem *
elm_toolbar_first_item_get(obj)
	const ElmToolbar *obj


ElmToolbarItem *
elm_toolbar_last_item_get(obj)
	const ElmToolbar *obj


# EinaIterator*
# elm_toolbar_items_get(obj)
#	const ElmToolbar *obj

void
elm_toolbar_homogeneous_set(obj,homogeneous)
	ElmToolbar *obj
	Eina_Bool homogeneous


Eina_Bool
elm_toolbar_homogeneous_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_align_set(obj,align)
	ElmToolbar *obj
	double align


double
elm_toolbar_align_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_select_mode_set(obj,mode)
	ElmToolbar *obj
	int mode


int
elm_toolbar_select_mode_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_icon_size_set(obj,icon_size)
	ElmToolbar *obj
	int icon_size


int
elm_toolbar_icon_size_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_shrink_mode_set(obj,shrink_mode)
	ElmToolbar *obj
	int shrink_mode


int
elm_toolbar_shrink_mode_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_menu_parent_set(obj,parent)
	ElmToolbar *obj
	EvasObject *parent


EvasObject *
elm_toolbar_menu_parent_get(obj)
	const ElmToolbar *obj


void
elm_toolbar_standard_priority_set(obj,priority)
	ElmToolbar *obj
	int priority


int
elm_toolbar_standard_priority_get(obj)
	const ElmToolbar *obj


ElmToolbarItem *
elm_toolbar_more_item_get(obj)
	const ElmToolbar *obj


ElmToolbarItem *
_elm_toolbar_item_insert_before(obj,before,icon,label,id)
	ElmToolbar *obj
	ElmToolbarItem *before
	const char *icon
	const char *label
	int id
PREINIT:
	_perl_gendata *data;
	UV objaddr;
	ElmToolbarItem *item;
CODE:
	// Get the adress of the object
	objaddr = PTR2IV(obj);
	
	// Save C struct with necessary infos to link to perl side
	data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
	item = elm_toolbar_item_insert_before(obj,before,icon,label,call_perl_gen_item_selected, data);
	elm_object_item_del_cb_set(item,call_perl_gen_del);
	RETVAL = item;
OUTPUT:
	RETVAL


ElmToolbarItem *
_elm_toolbar_item_insert_after(obj,after,icon,label,id)
	ElmToolbar *obj
	ElmToolbarItem *after
	const char *icon
	const char *label
	int id
PREINIT:
	_perl_gendata *data;
	UV objaddr;
	ElmToolbarItem *item;
CODE:
	// Get the adress of the object
	objaddr = PTR2IV(obj);
	
	// Save C struct with necessary infos to link to perl side
	data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
	item = elm_toolbar_item_insert_after(obj,after,icon,label,call_perl_gen_item_selected, data);
	elm_object_item_del_cb_set(item,call_perl_gen_del);
	RETVAL = item;
OUTPUT:
	RETVAL


ElmToolbarItem *
_elm_toolbar_item_append(obj,icon,label,id)
	ElmToolbar *obj
	const char *icon
	const char *label
	int id
PREINIT:
	_perl_gendata *data;
	UV objaddr;
	ElmToolbarItem *item;
CODE:
	// Get the adress of the object
	objaddr = PTR2IV(obj);
	
	// Save C struct with necessary infos to link to perl side
	data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
	item = elm_toolbar_item_append(obj,icon,label,call_perl_gen_item_selected, data);
	elm_object_item_del_cb_set(item,call_perl_gen_del);
	RETVAL = item;
OUTPUT:
	RETVAL

int
elm_toolbar_items_count(obj)
	const ElmToolbar *obj


ElmToolbarItem *
_elm_toolbar_item_prepend(obj,icon,label,id)
	ElmToolbar *obj
	const char *icon
	const char *label
	int id
PREINIT:
	_perl_gendata *data;
	UV objaddr;
	ElmToolbarItem *item;
CODE:
	// Get the adress of the object
	objaddr = PTR2IV(obj);
	
	// Save C struct with necessary infos to link to perl side
	data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
	item = elm_toolbar_item_prepend(obj,icon,label,call_perl_gen_item_selected, data);
	elm_object_item_del_cb_set(item,call_perl_gen_del);
	RETVAL = item;
OUTPUT:
	RETVAL

ElmToolbarItem *
elm_toolbar_item_find_by_label(obj,label)
	const ElmToolbar *obj
	const char *label