#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

typedef Elm_Theme ElmTheme;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Theme		PACKAGE = pEFL::Elm::Theme

ElmTheme * 
elm_theme_new()

MODULE = pEFL::Elm::Theme		PACKAGE = pEFL::Elm::Theme 	PREFIX = elm_theme_


ElmTheme *
elm_theme_default_get()


EinaList *
elm_theme_color_class_list()
CODE:
	RETVAL = elm_theme_color_class_list(NULL);
OUTPUT:
	RETVAL

void
elm_theme_color_class_list_free(list)
	Eina_List *list

	
void
elm_theme_copy(th,thdst)
	ElmTheme *th
	ElmTheme *thdst


void
elm_theme_ref_set(th,thref)
	ElmTheme *th
	ElmTheme *thref

void
elm_theme_overlay_add(item)
	const char *item
CODE:
	elm_theme_overlay_add(NULL,item);


void
elm_theme_overlay_del(item)
	const char *item
CODE:
	elm_theme_overlay_del(NULL,item);


void
elm_theme_extension_add(item)
	const char *item
CODE:
	elm_theme_extension_add(NULL,item);


void
elm_theme_extension_del(item)
	const char *item
CODE:
	elm_theme_extension_del(NULL,item);


void
elm_theme_set(theme)
	const char *theme
CODE:
	elm_theme_set(NULL,theme);


const char *
elm_theme_get()
CODE:
	RETVAL = elm_theme_get(NULL);
OUTPUT:
	RETVAL


char *
elm_theme_list_item_path_get(f,in_search_path)
	const char *f
	Eina_Bool *in_search_path


void
elm_theme_flush()
CODE:
	elm_theme_flush(NULL);


void
elm_theme_full_flush()
	 


EinaList *
elm_theme_name_available_list_new()
	 

void
elm_theme_name_available_list_free(list)
	Eina_List *list
	

const char *
elm_theme_data_get(key)
	const char *key
CODE:
	RETVAL = elm_theme_data_get(NULL,key);
OUTPUT:
	RETVAL


const char *
elm_theme_group_path_find(group)
	const char *group
CODE:
	RETVAL = elm_theme_group_path_find(NULL,group);
OUTPUT:
	RETVAL
	

# Eina_List *
# elm_theme_group_base_list(base)
#	const char *base
#CODE:
#	RETVAL = elm_theme_group_base_list(NULL,base);
#OUTPUT:
#	RETVAL


const char *
elm_theme_system_dir_get()
	 

const char *
elm_theme_user_dir_get()

MODULE = pEFL::Elm::Theme		PACKAGE = ElmThemePtr     PREFIX = elm_theme_

EinaList *
elm_theme_color_class_list(th)
	ElmTheme *th
	
void
elm_theme_free(th)
	ElmTheme *th


ElmTheme *
elm_theme_ref_get(th)
	const ElmTheme *th


void
elm_theme_overlay_add(th,item)
	ElmTheme *th
	const char *item


void
elm_theme_overlay_del(th,item)
	ElmTheme *th
	const char *item


#void
#elm_theme_overlay_mmap_add(th,f)
#	ElmTheme *th
#	const Eina_File *f


#void
#elm_theme_overlay_mmap_del(th,f)
#	ElmTheme *th
#	const Eina_File *f


EinaList *
elm_theme_overlay_list_get(th)
	const ElmTheme *th


void
elm_theme_extension_add(th,item)
	ElmTheme *th
	const char *item


void
elm_theme_extension_del(th,item)
	ElmTheme *th
	const char *item


#void
#elm_theme_extension_mmap_add(th,f)
#	ElmTheme *th
#	const Eina_File *f


#void
#elm_theme_extension_mmap_del(th,f)
#	ElmTheme *th
#	const Eina_File *f


EinaList *
elm_theme_extension_list_get(th)
	const ElmTheme *th


void
elm_theme_set(th,theme)
	ElmTheme *th
	const char *theme


const char *
elm_theme_get(th)
	ElmTheme *th


EinaList *
elm_theme_list_get(th)
	const ElmTheme *th


const char *
elm_theme_data_get(th,key)
	ElmTheme *th
	const char *key


const char *
elm_theme_group_path_find(th,group)
	ElmTheme *th
	const char *group


#Eina_List *
#elm_theme_group_base_list(th,base)
#	ElmTheme *th
#	const char *base