#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Fileselector ElmFileselector;
typedef Evas_Object EvasObject;
typedef Eina_List EinaList;

MODULE = pEFL::Elm::Fileselector		PACKAGE = pEFL::Elm::Fileselector

ElmFileselector *
elm_fileselector_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Fileselector		PACKAGE = ElmFileselectorPtr     PREFIX = elm_fileselector_

void
elm_fileselector_is_save_set(obj,is_save)
	EvasObject *obj
	Eina_Bool is_save


Eina_Bool
elm_fileselector_is_save_get(obj)
	EvasObject *obj


void
elm_fileselector_folder_only_set(obj,only)
	EvasObject *obj
	Eina_Bool only


Eina_Bool
elm_fileselector_folder_only_get(obj)
	EvasObject *obj


void
elm_fileselector_expandable_set(obj,expand)
	EvasObject *obj
	Eina_Bool expand


Eina_Bool
elm_fileselector_expandable_get(obj)
	EvasObject *obj


void
elm_fileselector_path_set(obj,path)
	EvasObject *obj
	const char *path


char *
elm_fileselector_path_get(obj)
	EvasObject *obj


void
elm_fileselector_mode_set(obj,mode)
	EvasObject *obj
	int mode


int
elm_fileselector_mode_get(obj)
	EvasObject *obj


void
elm_fileselector_multi_select_set(obj,multi)
	EvasObject *obj
	Eina_Bool multi


Eina_Bool
elm_fileselector_multi_select_get(obj)
	EvasObject *obj


Eina_Bool
elm_fileselector_selected_set(obj,path)
	EvasObject *obj
	const char *path


char *
elm_fileselector_selected_get(obj)
	EvasObject *obj


void
elm_fileselector_current_name_set(obj,name)
	EvasObject *obj
	const char *name


char *
elm_fileselector_current_name_get(obj)
	EvasObject *obj


EinaList *
elm_fileselector_selected_paths_get(obj)
	EvasObject *obj


Eina_Bool
elm_fileselector_mime_types_filter_append(obj,mime_types,filter_name)
	EvasObject *obj
	const char *mime_types
	const char *filter_name


# func ist eigtl. Elm_Fileselector_Filter_Func
# Eina_Bool
# elm_fileselector_custom_filter_append(obj,func,data,filter_name)
#	EvasObject *obj
#	SV* func
#	void *data
#	const char *filter_name


void
elm_fileselector_filters_clear(obj)
	EvasObject *obj


void
elm_fileselector_hidden_visible_set(obj,visible)
	EvasObject *obj
	Eina_Bool visible


Eina_Bool
elm_fileselector_hidden_visible_get(obj)
	EvasObject *obj


void
elm_fileselector_thumbnail_size_set(obj,w,h)
	EvasObject *obj
	Evas_Coord w
	Evas_Coord h


void
elm_fileselector_thumbnail_size_get(obj,OUTLIST w, OUTLIST h)
	EvasObject *obj
	Evas_Coord w
	Evas_Coord h


int
elm_fileselector_sort_method_get(obj)
	EvasObject *obj


void
elm_fileselector_sort_method_set(obj,sort)
	EvasObject *obj
	int sort


void
elm_fileselector_buttons_ok_cancel_set(obj, visible)
    ElmFileselector *obj
    Eina_Bool visible


Eina_Bool
elm_fileselector_buttons_ok_cancel_get(obj)
    ElmFileselector *obj
