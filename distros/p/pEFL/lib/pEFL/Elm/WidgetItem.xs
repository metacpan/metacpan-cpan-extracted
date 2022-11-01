#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"

typedef Elm_Widget_Item ElmWidgetItem;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::WidgetItem		PACKAGE = ElmWidgetItemPtr     PREFIX = elm_object_item_

Eina_Bool
elm_object_item_tooltip_window_mode_set(obj,disable)
	ElmWidgetItem *obj
	Eina_Bool disable


Eina_Bool
elm_object_item_tooltip_window_mode_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_tooltip_style_set(obj,style)
	ElmWidgetItem *obj
	const char *style


char *
elm_object_item_tooltip_style_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_cursor_set(obj,cursor)
	ElmWidgetItem *obj
	const char *cursor


char *
elm_object_item_cursor_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_cursor_style_set(obj,style)
	ElmWidgetItem *obj
	const char *style


char *
elm_object_item_cursor_style_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_cursor_engine_only_set(obj,engine_only)
	ElmWidgetItem *obj
	Eina_Bool engine_only


Eina_Bool
elm_object_item_cursor_engine_only_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_part_content_set(obj,part,content)
	ElmWidgetItem *obj
	const char *part
	EvasObject *content


EvasObject *
elm_object_item_part_content_get(obj,part)
	ElmWidgetItem *obj
	const char *part


void
elm_object_item_part_text_set(obj,part,label)
	ElmWidgetItem *obj
	const char *part
	const char *label


char *
elm_object_item_part_text_get(obj,part)
	ElmWidgetItem *obj
	const char *part


void
elm_object_item_focus_set(obj,focused)
	ElmWidgetItem *obj
	Eina_Bool focused


Eina_Bool
elm_object_item_focus_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_style_set(obj,style)
	ElmWidgetItem *obj
	const char *style


char *
elm_object_item_style_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_disabled_set(obj,disable)
	ElmWidgetItem *obj
	Eina_Bool disable


Eina_Bool
elm_object_item_disabled_get(obj)
	ElmWidgetItem *obj


EinaList *
elm_object_item_access_order_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_access_order_set(obj,objs)
	ElmWidgetItem *obj
	EinaList *objs


EvasObject *
elm_object_item_widget_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_tooltip_text_set(obj,text)
	ElmWidgetItem *obj
	const char *text


void
elm_object_item_tooltip_unset(obj)
	ElmWidgetItem *obj


void
elm_object_item_cursor_unset(obj)
	ElmWidgetItem *obj


EvasObject *
elm_object_item_part_content_unset(obj,part)
	ElmWidgetItem *obj
	const char *part



void
_elm_object_item_signal_callback_add(obj,emission,source,func,id)
	ElmWidgetItem *obj
	const char *emission
	const char *source
	SV* func
	int id
PREINIT:
    UV objaddr;
    _perl_signal_cb *data;
CODE:
    objaddr = PTR2IV(obj);
    data = perl_save_item_signal_cb(aTHX_ objaddr, id);
    elm_object_item_signal_callback_add(obj,emission,source,call_perl_item_signal_cb,data);
    

void *
_elm_object_item_signal_callback_del(obj,emission,source,cstructaddr)
	ElmWidgetItem *obj
	const char *emission
	const char *source
	SV* cstructaddr
PREINIT:
    _perl_signal_cb *sc = NULL;
    _perl_signal_cb *del_sc = NULL;
    UV address;
    void *data;
CODE:
    address = SvUV(cstructaddr);
    sc = INT2PTR(_perl_signal_cb*,address);
    data = elm_object_item_signal_callback_del(obj, emission, source, call_perl_item_signal_cb);
    while (data != NULL) {
        del_sc = (_perl_signal_cb *) data;
        data = elm_object_signal_callback_del(obj, emission, source, call_perl_signal_cb);
        if (del_sc->signal_id == sc->signal_id) {
            Safefree(del_sc);
        }
        // If signal_ids are different reregister the signal callback
        else {
            elm_object_item_signal_callback_add(obj,emission,source,call_perl_signal_cb,del_sc);
        }
        
    }



void
elm_object_item_signal_emit(obj,emission,source)
	ElmWidgetItem *obj
	const char *emission
	const char *source


void
elm_object_item_access_info_set(obj,txt)
	ElmWidgetItem *obj
	const char *txt


EvasObject *
elm_object_item_access_object_get(obj)
	ElmWidgetItem *obj


void
elm_object_item_domain_translatable_part_text_set(obj,part,domain,label)
	ElmWidgetItem *obj
	const char *part
	const char *domain
	const char *label


char *
elm_object_item_translatable_part_text_get(obj,part)
	ElmWidgetItem *obj
	const char *part


void
elm_object_item_domain_part_text_translatable_set(obj,part,domain,translatable)
	ElmWidgetItem *obj
	const char *part
	const char *domain
	Eina_Bool translatable


EvasObject *
elm_object_item_track(obj)
	ElmWidgetItem *obj


void
elm_object_item_untrack(obj)
	ElmWidgetItem *obj


int
elm_object_item_track_get(obj)
	ElmWidgetItem *obj


# del_cb ist eigtl. Evas_Smart_Cb del_cb
#void
#elm_object_item_del_cb_set(obj,del_cb)
#	ElmWidgetItem *obj
#	SV* del_cb


# func ist eigtl. Elm_Tooltip_Item_Content_Cb!!
# void
#elm_object_item_tooltip_content_cb_set(obj,func,data,del_cb)
#	ElmWidgetItem *obj
#	SV* func
#	const void *data
#	SV* del_cb


EvasObject *
elm_object_item_access_register(obj)
	ElmWidgetItem *obj


void
elm_object_item_access_unregister(obj)
	ElmWidgetItem *obj


void
elm_object_item_access_order_unset(obj)
	ElmWidgetItem *obj


EvasObject *
elm_object_item_focus_next_object_get(obj,dir)
	ElmWidgetItem *obj
	int dir


void
elm_object_item_focus_next_object_set(obj,next,dir)
	ElmWidgetItem *obj
	EvasObject *next
	int dir


ElmWidgetItem *
elm_object_item_focus_next_item_get(obj,dir)
	ElmWidgetItem *obj
	int dir


void
elm_object_item_focus_next_item_set(obj,next_item,dir)
	ElmWidgetItem *obj
	ElmWidgetItem *next_item
	int dir
