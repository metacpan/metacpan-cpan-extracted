#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

#include "PLSide.h"


typedef Evas_Object ElmLayout;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Layout		PACKAGE = pEFL::Elm::Layout

ElmLayout *
elm_layout_add(parent)
	EvasObject *parent

MODULE = pEFL::Elm::Layout		PACKAGE = ElmLayoutPtr     PREFIX = elm_layout_

Eina_Bool
elm_layout_theme_set(obj,klass,group,style)
	EvasObject *obj
	const char *klass
	const char *group
	const char *style


char *
elm_layout_data_get(obj,key)
	const EvasObject *obj
	const char *key


void
elm_layout_sizing_eval(obj)
	EvasObject *obj


void
elm_layout_sizing_restricted_eval(obj,width,height)
	EvasObject *obj
	Eina_Bool width
	Eina_Bool height


void
_elm_layout_signal_callback_add(obj,emission,source,func,id)
	ElmLayout *obj
	const char *emission
	const char *source
	SV* func
	int id
PREINIT:
    UV objaddr;
    _perl_signal_cb *data;
CODE:
    objaddr = PTR2IV(obj);
    data = perl_save_signal_cb(aTHX_ objaddr, id);
    elm_layout_signal_callback_add(obj,emission,source,call_perl_signal_cb,data);

    

void *
_elm_layout_signal_callback_del(obj,emission,source,cstructaddr)
	EvasObject *obj
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
    data = elm_layout_signal_callback_del(obj, emission, source, call_perl_signal_cb);
    while (data != NULL) {
        del_sc = (_perl_signal_cb *) data;
        data = elm_layout_signal_callback_del(obj, emission, source, call_perl_signal_cb);
        if (del_sc->signal_id == sc->signal_id) {
            Safefree(del_sc);
        }
        // If signal_ids are different reregister the signal callback
        else {
            elm_layout_signal_callback_add(obj,emission,source,call_perl_signal_cb,del_sc);
        }
        
    }



void
elm_layout_signal_emit(obj,emission,source)
	EvasObject *obj
	const char *emission
	const char *source


EvasObject *
elm_layout_edje_get(obj)
	const EvasObject *obj


EinaList *
elm_layout_content_swallow_list_get(obj)
	const EvasObject *obj


Eina_Bool
elm_layout_content_set(obj,swallow,content)
	EvasObject *obj
	const char *swallow
	EvasObject *content


EvasObject *
elm_layout_content_get(obj,swallow)
	const EvasObject *obj
	const char *swallow

	
EvasObject *
elm_layout_content_unset(obj,swallow)
	EvasObject *obj
	const char *swallow

# obj is of type Eo *obj
Eina_Bool
elm_layout_file_set(obj,file,group)
	ElmLayout *obj
	const char *file
	const char *group

# obj is of type Eo *obj
void
elm_layout_file_get(obj, OUTLIST file, OUTLIST group)
	ElmLayout *obj
	const char *file
	const char *group


# Eina_Bool
# elm_layout_mmap_set(obj,file,group)
#	Eo *obj
#	const Eina_File *file
#	const char *group


# void
# elm_layout_mmap_get(obj,*file,*group)
#	Eo *obj
#	const Eina_File **file
#	const char **group


int
elm_layout_freeze(obj)
	EvasObject *obj


int
elm_layout_thaw(obj)
	EvasObject *obj


Eina_Bool
elm_layout_box_append(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
elm_layout_box_prepend(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
elm_layout_box_insert_before(obj,part,child,reference)
	EvasObject *obj
	const char *part
	EvasObject *child
	const EvasObject *reference


Eina_Bool
elm_layout_box_insert_at(obj,part,child,pos)
	EvasObject *obj
	const char *part
	EvasObject *child
	unsigned int pos


EvasObject *
elm_layout_box_remove(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
elm_layout_box_remove_all(obj,part,clear)
	EvasObject *obj
	const char *part
	Eina_Bool clear


Eina_Bool
elm_layout_table_pack(obj,part,child,col,row,colspan,rowspan)
	EvasObject *obj
	const char *part
	EvasObject *child
	unsigned short col
	unsigned short row
	unsigned short colspan
	unsigned short rowspan


EvasObject *
elm_layout_table_unpack(obj,part,child)
	EvasObject *obj
	const char *part
	EvasObject *child


Eina_Bool
elm_layout_table_clear(obj,part,clear)
	EvasObject *obj
	const char *part
	Eina_Bool clear


Eina_Bool
elm_layout_text_set(obj,part,text)
	EvasObject *obj
	const char * part
	const char *text


char *
elm_layout_text_get(obj,part)
	const EvasObject *obj
	const char * part


Eina_Bool
elm_layout_edje_object_can_access_set(obj,can_access)
	EvasObject *obj
	Eina_Bool can_access


Eina_Bool
elm_layout_edje_object_can_access_get(obj)
	const EvasObject *obj


Eina_Bool
elm_layout_part_cursor_engine_only_set(obj,part_name,engine_only)
	EvasObject *obj
	const char *part_name
	Eina_Bool engine_only


Eina_Bool
elm_layout_part_cursor_engine_only_get(obj,part_name)
	const EvasObject *obj
	const char *part_name


Eina_Bool
elm_layout_part_cursor_set(obj,part_name,cursor)
	EvasObject *obj
	const char *part_name
	const char *cursor


char *
elm_layout_part_cursor_get(obj,part_name)
	const EvasObject *obj
	const char *part_name


Eina_Bool
elm_layout_part_cursor_style_set(obj,part_name,style)
	EvasObject *obj
	const char *part_name
	const char *style


char *
elm_layout_part_cursor_style_get(obj,part_name)
	const EvasObject *obj
	const char *part_name


Eina_Bool
elm_layout_part_cursor_unset(obj,part_name)
	EvasObject *obj
	const char *part_name
