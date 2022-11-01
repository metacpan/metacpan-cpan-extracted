#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

typedef Elm_Object_Item ElmObjectItem;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::ObjectItem		PACKAGE = ElmObjectItemPtr     PREFIX = elm_object_item_


void
elm_object_item_text_set(obj,label)
	ElmObjectItem *obj
	const char *label
	

char *
elm_object_item_text_get(it)
    ElmObjectItem *it

    
# void *
# elm_object_item_data_get(it)
#	ElmObjectItem *it
	

# void
# elm_object_item_data_set(it,data)
#	ElmObjectItem *it
#	void *data
	
	
void
elm_object_item_del(obj)
	ElmObjectItem *obj


# TODO: Perhaps connect data on Perl side?
# void
# elm_object_item_data_set(it,data)
#    ElmObjectItem *it 
#    HV *data
# CODE:
#    _saved_object_data *sd = NULL;
#    sd = (_saved_object_data *)malloc(sizeof(_saved_object_data));
#    memset(sd, '\0', sizeof(_saved_object_data));
#    sd->perldata = newRV_inc((SV*)data);
#    elm_object_item_data_set(it,sd);
    

# HV*
# elm_object_item_data_get(it)
#    ElmObjectItem *it
# CODE:
#    _saved_object_data *sd  = NULL;
#    sd = elm_object_item_data_get(it);
#    RETVAL = SvRV(sd->perldata);
# OUTPUT:
#    RETVAL

# elm_object_item_part_content_set|get is already implemented
# in ElmWidgetPtr
#void
#elm_object_item_part_content_set(obj,part,content)
#	ElmObjectItem *obj
#	const char *part
#	EvasObject *content
#
#
#EvasObject *
#elm_object_item_part_content_get(obj,part)
#	ElmObjectItem *obj
#	const char *part


void
elm_object_item_content_set(obj,content)
	ElmObjectItem *obj
	EvasObject *content


EvasObject *
elm_object_item_content_get(obj)
	ElmObjectItem *obj
	
	
EvasObject *
elm_object_item_content_unset(obj)
	ElmObjectItem *obj
	
	
void
elm_object_item_domain_translatable_text_set(obj,domain,label)
	ElmObjectItem *obj
	const char *domain
	const char *label

void
elm_object_item_translatable_text_set(obj,label)
	ElmObjectItem *obj
	const char *label


void
elm_object_item_translatable_part_text_set(obj,part,label)
	ElmObjectItem *obj
	const char *part
	const char *label


char *
elm_object_item_translatable_text_get(obj)
	ElmObjectItem *obj


void
elm_object_item_part_text_translatable_set(obj,part,translatable)
	ElmObjectItem *obj
	const char *part
	Eina_Bool translatable
	
	
void
elm_object_item_domain_text_translatable_set(obj,domain,translatable)
	ElmObjectItem *obj
	const char *domain
	Eina_Bool translatable
	
	
void
elm_object_item_text_translatable_set(obj,translatable)
	ElmObjectItem *obj
	Eina_Bool translatable