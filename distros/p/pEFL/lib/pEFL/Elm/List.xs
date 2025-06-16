#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Evas_Object ElmList;
typedef Evas_Object EvasObject;
typedef Elm_Widget_Item ElmWidgetItem;
typedef Elm_List_Item ElmListItem;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::List		PACKAGE = pEFL::Elm::List

ElmList * 
elm_list_add(EvasObject *parent)

MODULE = pEFL::Elm::List		PACKAGE = ElmListPtr     PREFIX = elm_list_

void
elm_list_horizontal_set(obj,horizontal)
	ElmList *obj
	Eina_Bool horizontal
	
Eina_Bool
elm_list_horizontal_get(obj)
	ElmList *obj
	
void
elm_list_select_mode_set(obj,mode)
	ElmList *obj
	int mode
	
int
elm_list_select_mode_get(obj)
	ElmList *obj

void
elm_list_focus_on_selection_set(obj,enabled)
	ElmList *obj
	Eina_Bool enabled

Eina_Bool
elm_list_focus_on_selection_get(obj)
	ElmList *obj
	
void
elm_list_multi_select_set(obj,multi)
	ElmList *obj
	Eina_Bool multi
	
Eina_Bool
elm_list_multi_select_get(obj)
	ElmList *obj
	
void
elm_list_multi_select_mode_set(obj,mode)
	ElmList *obj
	int mode

int
elm_list_multi_select_mode_get(obj)
	ElmList *obj
	
void
elm_list_mode_set(obj,mode)
	ElmList *obj
	int mode
	
int
elm_list_mode_get(obj)
	ElmList *obj


ElmListItem *
elm_list_selected_item_get(obj)
	ElmList *obj
	
EinaList *
elm_list_items_get(obj)
	ElmList *obj
	
ElmListItem *
elm_list_first_item_get(obj)
	ElmList *obj

EinaList *
elm_list_selected_items_get(obj)
	ElmList *obj
	
ElmListItem *
elm_list_last_item_get(obj)
	ElmList *obj

	
ElmListItem *
_elm_list_item_insert_before(obj,before,label,icon,end,id)
	ElmList *obj
	ElmListItem *before
	char *label
	EvasObject *icon 
	EvasObject *end  
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmListItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_list_item_insert_before(obj,before,label,icon,end,call_perl_gen_item_selected, data);
    elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL
	
void
elm_list_go(obj)
	ElmList *obj
	
ElmListItem *
_elm_list_item_insert_after(obj,after,label,icon,end,id)
	ElmList *obj
	ElmListItem *after
	char *label
	EvasObject *icon 
	EvasObject *end  
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmListItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_list_item_insert_after(obj,after,label,icon,end,call_perl_gen_item_selected, data);
    elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL
    
	
ElmListItem *
elm_list_at_xy_item_get(obj,x,y,OUTLIST posret)
	ElmList *obj
	int x
	int y
	int posret
	
	
ElmListItem *
_elm_list_item_append(obj,label,icon,end,id)
	ElmList *obj
	char *label
	EvasObject *icon 
	EvasObject *end  
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmListItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_list_item_append(obj,label,icon,end,call_perl_gen_item_selected, data);
    elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL
    
	
ElmListItem *
_elm_list_item_prepend(obj,label,icon,end,id)
	ElmList *obj
	char *label
	EvasObject *icon 
	EvasObject *end  
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmListItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_list_item_prepend(obj,label,icon,end,call_perl_gen_item_selected, data);
    elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL
	
void
elm_list_clear(obj)
	ElmList *obj
	
# not needed. Use perl instead 
# ElmWidgetItem *
# elm_list_item_sorted_insert(obj,label,icon,end,func,data,cmp_func)
#   ElmList *obj
#	char *label
#	EvasObject *icon //Efl_Canvas_Object
#	EvasObject *end  //Efl_Canvas_Object
#	Evas_Smart_Cb func
#	void *data
#	Eina_Compare_Cb cmp_func
#
