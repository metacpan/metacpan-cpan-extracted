#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Genlist ElmGenlist;
typedef Elm_Genlist_Item ElmGenlistItem;
typedef Elm_Genlist_Item_Class ElmGenlistItemClass;
typedef Elm_Object_Item ElmObjectItem;
typedef Elm_Widget_Item ElmWidgetItem;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Genlist		PACKAGE = pEFL::Elm::Genlist

ElmGenlist *
elm_genlist_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Genlist		PACKAGE = ElmGenlistPtr     PREFIX = elm_genlist_


void
elm_genlist_homogeneous_set(obj,homogeneous)
	ElmGenlist *obj
	Eina_Bool homogeneous

Eina_Bool
elm_genlist_homogeneous_get(obj)
	const ElmGenlist *obj

void
elm_genlist_select_mode_set(obj,mode)
	ElmGenlist *obj
	int mode

int
elm_genlist_select_mode_get(obj)
	const ElmGenlist *obj


void
elm_genlist_focus_on_selection_set(obj,enabled)
	ElmGenlist *obj
	Eina_Bool enabled


Eina_Bool
elm_genlist_focus_on_selection_get(obj)
	const ElmGenlist *obj


void
elm_genlist_longpress_timeout_set(obj,timeout)
	ElmGenlist *obj
	double timeout


double
elm_genlist_longpress_timeout_get(obj)
	const ElmGenlist *obj


void
elm_genlist_multi_select_set(obj,multi)
	ElmGenlist *obj
	Eina_Bool multi


Eina_Bool
elm_genlist_multi_select_get(obj)
	const ElmGenlist *obj


void
elm_genlist_reorder_mode_set(obj,reorder_mode)
	ElmGenlist *obj
	Eina_Bool reorder_mode


Eina_Bool
elm_genlist_reorder_mode_get(obj)
	const ElmGenlist *obj


void
elm_genlist_decorate_mode_set(obj,decorated)
	ElmGenlist *obj
	Eina_Bool decorated


Eina_Bool
elm_genlist_decorate_mode_get(obj)
	const ElmGenlist *obj


void
elm_genlist_multi_select_mode_set(obj,mode)
	ElmGenlist *obj
	int mode


int
elm_genlist_multi_select_mode_get(obj)
	const ElmGenlist *obj


void
elm_genlist_block_count_set(obj,count)
	ElmGenlist *obj
	int count


int
elm_genlist_block_count_get(obj)
	const ElmGenlist *obj


void
elm_genlist_tree_effect_enabled_set(obj,enabled)
	ElmGenlist *obj
	Eina_Bool enabled


Eina_Bool
elm_genlist_tree_effect_enabled_get(obj)
	const ElmGenlist *obj


void
elm_genlist_highlight_mode_set(obj,highlight)
	ElmGenlist *obj
	Eina_Bool highlight


Eina_Bool
elm_genlist_highlight_mode_get(obj)
	const ElmGenlist *obj


void
elm_genlist_mode_set(obj,mode)
	ElmGenlist *obj
	int mode


int
elm_genlist_mode_get(obj)
	const ElmGenlist *obj


ElmGenlistItem *
elm_genlist_decorated_item_get(obj)
	const ElmGenlist *obj


#ElmGenlistItem *
ElmGenlistItem *
elm_genlist_selected_item_get(obj)
	const ElmGenlist *obj


ElmGenlistItem *
elm_genlist_first_item_get(obj)
	const ElmGenlist *obj


EinaList *
elm_genlist_selected_items_get(obj)
	const ElmGenlist *obj


ElmGenlistItem *
elm_genlist_last_item_get(obj)
	const ElmGenlist *obj


ElmGenlistItem *
_elm_genlist_item_insert_before(obj,itc,id,parent,before_it,type)
	ElmGenlist *obj
    const ElmGenlistItemClass *itc
	int id
	ElmWidgetItem *parent
	ElmWidgetItem *before_it
	int type
PREINIT:
    _perl_gendata *gen_data;
    UV objaddr;
    UV itcaddr;
CODE:
    if (!itc)
        itc = NULL;
    if (!parent) 
        parent = NULL;
    
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    // Get the Adress of the itc struct
    itcaddr = PTR2IV(itc);
    
    // Save GenItc
    gen_data = perl_save_gen_cb(aTHX_ objaddr, itcaddr, id);
    RETVAL = elm_genlist_item_insert_before( obj,itc,gen_data, parent, before_it, type,call_perl_gen_item_selected,gen_data);
OUTPUT:
    RETVAL
    

void
elm_genlist_realized_items_update(obj)
	ElmGenlist *obj


ElmGenlistItem *
_elm_genlist_item_insert_after(obj,itc,id,parent,after_it,type)
	ElmGenlist *obj
	const ElmGenlistItemClass *itc
	int id
	ElmWidgetItem *parent
	ElmWidgetItem *after_it
	int type
PREINIT:
    _perl_gendata *gen_data;
    UV itcaddr;
    UV objaddr;
CODE:
    if (!itc)
        itc = NULL;
    if (!parent) 
        parent = NULL;
        
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    // Get the Adress of the itc struct
    itcaddr = PTR2IV(itc);
    
    // Save GenItc
    gen_data = perl_save_gen_cb(aTHX_ objaddr, itcaddr, id);
    RETVAL = elm_genlist_item_insert_after( obj,itc,gen_data, parent, after_it, type,call_perl_gen_item_selected,gen_data);
OUTPUT:
    RETVAL

ElmGenlistItem *
elm_genlist_at_xy_item_get(obj,x,y,OUTLIST posret)
	const ElmGenlist *obj
	int x
	int y
	int posret


void
elm_genlist_filter_set(obj,key)
	ElmGenlist *obj
	void *key


# Eina_Iterator *
# elm_genlist_filter_iterator_new(obj)
#	ElmGenlist *obj


int
elm_genlist_filtered_items_count(obj)
	const ElmGenlist *obj


int
elm_genlist_items_count(obj)
	const ElmGenlist *obj


ElmGenlistItem *
_elm_genlist_item_prepend(obj,itc,id,parent,type)
    ElmGenlist *obj
	const ElmGenlistItemClass *itc
	int id
	ElmWidgetItem *parent
	int type
PREINIT:
    _perl_gendata *gen_data;
    UV itcaddr;
    UV objaddr;
CODE:
    if (!itc)
        itc = NULL;
    if (!parent) 
        parent = NULL;
        
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    // Get the Adress of the itc struct
    itcaddr = PTR2IV(itc);
    
    // Save GenItc
    gen_data = perl_save_gen_cb(aTHX_ objaddr, itcaddr, id);
    RETVAL = elm_genlist_item_prepend( obj,itc,gen_data, parent,type,call_perl_gen_item_selected,gen_data);
OUTPUT:
    RETVAL
	

void
elm_genlist_clear(obj)
	ElmGenlist *obj


ElmGenlistItem *
_elm_genlist_item_append(obj,itc,id,parent,type)
	ElmGenlist *obj
	const ElmGenlistItemClass *itc;
	int id
	ElmWidgetItem *parent
	int type
PREINIT:
    _perl_gendata *gen_data;
    UV itcaddr;
    UV objaddr;
CODE:
    if (!itc)
        itc = NULL;
    if (!parent) 
        parent = NULL;
    
    // Get the adress of the object
    objaddr = PTR2IV(obj);
    // Get the Adress of the itc struct
    itcaddr = PTR2IV(itc);
    
    // Save GenItc
    gen_data = perl_save_gen_cb(aTHX_ objaddr, itcaddr, id);
    RETVAL = elm_genlist_item_append( obj,itc,gen_data, parent,type,call_perl_gen_item_selected,gen_data);
OUTPUT:
    RETVAL


# ElmGenlistItem *
# elm_genlist_item_sorted_insert(obj,itc,data,parent,type,comp,func,func_data)
#	ElmGenlist *obj
#	const ElmGenlistItemClass *itc
#	void *data
#	ElmWidgetItem *parent
#	int type
#	SV* comp
#	SV* func
#	void *func_data


ElmGenlistItem *
elm_genlist_search_by_text_item_get(obj,item_to_search_from,part_name,pattern,flags)
	ElmGenlist *obj
	ElmWidgetItem *item_to_search_from
	const char *part_name
	const char *pattern
	int flags
