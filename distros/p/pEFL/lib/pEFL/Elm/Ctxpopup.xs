#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Ctxpopup ElmCtxpopup;
typedef Evas_Object EvasObject;
typedef Elm_Widget_Item ElmWidgetItem;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Ctxpopup		PACKAGE = pEFL::Elm::Ctxpopup

ElmCtxpopup *
elm_ctxpopup_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Ctxpopup		PACKAGE = ElmCtxpopupPtr     PREFIX = elm_ctxpopup_

ElmWidgetItem *
elm_ctxpopup_selected_item_get(obj)
	ElmCtxpopup *obj


ElmWidgetItem *
elm_ctxpopup_first_item_get(obj)
	ElmCtxpopup *obj


ElmWidgetItem *
elm_ctxpopup_last_item_get(obj)
	ElmCtxpopup *obj


EinaList *
elm_ctxpopup_items_get(obj)
	ElmCtxpopup *obj


void
elm_ctxpopup_horizontal_set(obj,horizontal)
	ElmCtxpopup *obj
	Eina_Bool horizontal


Eina_Bool
elm_ctxpopup_horizontal_get(obj)
	ElmCtxpopup *obj


void
elm_ctxpopup_auto_hide_disabled_set(obj,disabled)
	ElmCtxpopup *obj
	Eina_Bool disabled


Eina_Bool
elm_ctxpopup_auto_hide_disabled_get(obj)
	ElmCtxpopup *obj


void
elm_ctxpopup_hover_parent_set(obj,parent)
	ElmCtxpopup *obj
	EvasObject *parent


EvasObject *
elm_ctxpopup_hover_parent_get(obj)
	ElmCtxpopup *obj


void
elm_ctxpopup_direction_priority_set(obj,first,second,third,fourth)
	ElmCtxpopup *obj
	Elm_Ctxpopup_Direction first
	Elm_Ctxpopup_Direction second
	Elm_Ctxpopup_Direction third
	Elm_Ctxpopup_Direction fourth


void
elm_ctxpopup_direction_priority_get(obj,OUTLIST first,OUTLIST second,OUTLIST third,OUTLIST fourth)
	ElmCtxpopup *obj
	Elm_Ctxpopup_Direction first
	Elm_Ctxpopup_Direction second
	Elm_Ctxpopup_Direction third
	Elm_Ctxpopup_Direction fourth


int
elm_ctxpopup_direction_get(obj)
	ElmCtxpopup *obj


void
elm_ctxpopup_dismiss(obj)
	ElmCtxpopup *obj


void
elm_ctxpopup_clear(obj)
	ElmCtxpopup *obj


ElmWidgetItem *
_elm_ctxpopup_item_insert_before(obj,before,label,icon,id)
	ElmCtxpopup *obj
	ElmWidgetItem *before
	char *label
	EvasObject *icon 
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmWidgetItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_ctxpopup_item_insert_before(obj,before,label,icon,call_perl_gen_item_selected, data);
    // del_cb seems not to work with Ctxpopup
    //elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL


ElmWidgetItem *
_elm_ctxpopup_item_insert_after(obj,after,label,icon,id)
	ElmCtxpopup *obj
	ElmWidgetItem *after
	char *label
	EvasObject *icon 
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmWidgetItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_ctxpopup_item_insert_after(obj,after,label,icon,call_perl_gen_item_selected, data);
    // del_cb seems not to work with Ctxpopup
    //elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL


ElmWidgetItem *
_elm_ctxpopup_item_append(obj,label,icon,id)
	ElmCtxpopup *obj
	char *label
	EvasObject *icon 
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmWidgetItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    
    item = elm_ctxpopup_item_append(obj,label,icon,call_perl_gen_item_selected, data);
    // del_cb seems not to work with Ctxpopup
    // elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL


ElmWidgetItem *
_elm_ctxpopup_item_prepend(obj,label,icon,id)
	ElmCtxpopup *obj
	char *label
	EvasObject *icon 
	int id
PREINIT:
	_perl_gendata *data;
    UV objaddr;
	ElmWidgetItem *item;
CODE:
	// Get the adress of the object
    objaddr = PTR2IV(obj);
    
    // Save C struct with necessary infos to link to perl side
    data = perl_save_gen_cb(aTHX_ objaddr, 0, id);
    item = elm_ctxpopup_item_prepend(obj,label,icon,call_perl_gen_item_selected, data);
    // del_cb seems not to work with Ctxpopup
    //elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL
