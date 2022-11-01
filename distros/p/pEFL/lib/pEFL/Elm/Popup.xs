#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Elm_Popup ElmPopup;
typedef Elm_Object_Item ElmObjectItem;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Popup		PACKAGE = pEFL::Elm::Popup

ElmPopup *
elm_popup_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Popup		PACKAGE = ElmPopupPtr     PREFIX = elm_popup_


void
elm_popup_align_set(obj,horizontal,vertical)
	ElmPopup *obj
	double horizontal
	double vertical


void
elm_popup_align_get(obj,OUTLIST horizontal,OUTLIST vertical)
	const ElmPopup *obj
	double horizontal
	double vertical


void
elm_popup_allow_events_set(obj,allow)
	ElmPopup *obj
	Eina_Bool allow


Eina_Bool
elm_popup_allow_events_get(obj)
	const ElmPopup *obj


void
elm_popup_content_text_wrap_type_set(obj,wrap)
	ElmPopup *obj
	int wrap


int
elm_popup_content_text_wrap_type_get(obj)
	const ElmPopup *obj


void
elm_popup_orient_set(obj,orient)
	ElmPopup *obj
	int orient


int
elm_popup_orient_get(obj)
	const ElmPopup *obj


void
elm_popup_timeout_set(obj,timeout)
	ElmPopup *obj
	double timeout


double
elm_popup_timeout_get(obj)
	const ElmPopup *obj


void
elm_popup_scrollable_set(obj,scroll)
	ElmPopup *obj
	Eina_Bool scroll


Eina_Bool
elm_popup_scrollable_get(obj)
	const ElmPopup *obj


ElmObjectItem *
_elm_popup_item_append(obj,label,icon,id)
	ElmPopup *obj
	char *label
	EvasObject *icon  
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
    item = elm_popup_item_append(obj,label,icon,call_perl_gen_item_selected, data);
    //elm_object_item_del_cb_set(item,call_perl_gen_del);
    RETVAL = item;
OUTPUT:
    RETVAL    
	

void
elm_popup_dismiss(obj)
	ElmPopup *obj
