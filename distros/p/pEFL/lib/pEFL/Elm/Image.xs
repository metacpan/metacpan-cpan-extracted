#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmImage;
typedef Evas_Object EvasObject;
typedef Elm_Image_Progress ElmImageProgress;

MODULE = pEFL::Elm::Image		PACKAGE = pEFL::Elm::Image

ElmImage *
elm_image_add(EvasObject *parent)

MODULE = pEFL::Elm::Image		PACKAGE = ElmImagePtr     PREFIX = elm_image_

Eina_Bool
elm_image_file_set(obj,file,group)
    ElmImage *obj
    char *file
    char *group

void
elm_image_file_get(obj,OUTLIST file,OUTLIST group)
	ElmImage *obj
	const char *file
	const char *group


void
elm_image_prescale_set(obj,size)
	ElmImage *obj
	int size


int
elm_image_prescale_get(obj)
	ElmImage *obj


# Eina_Bool
# elm_image_mmap_set(obj,file,group)
# 	ElmImage *obj
#	const Eina_File *file
#	const char *group


void
elm_image_smooth_set(obj,smooth)
	ElmImage *obj
	Eina_Bool smooth


Eina_Bool
elm_image_smooth_get(obj)
	ElmImage *obj


void
elm_image_animated_play_set(obj,play)
	ElmImage *obj
	Eina_Bool play


Eina_Bool
elm_image_animated_play_get(obj)
	ElmImage *obj


void
elm_image_animated_set(obj,anim)
	ElmImage *obj
	Eina_Bool anim


Eina_Bool
elm_image_animated_get(obj)
	ElmImage *obj


Eina_Bool
elm_image_animated_available_get(obj)
	ElmImage *obj


void
elm_image_editable_set(obj,set)
	ElmImage *obj
	Eina_Bool set


Eina_Bool
elm_image_editable_get(obj)
	ElmImage *obj


# Eina_Bool
# elm_image_memfile_set(obj,img,size,format,key)
#	ElmImage *obj
#	const void *img
#	size_t size
#	const char *format
#	const char *key


void
elm_image_fill_outside_set(obj,fill_outside)
	ElmImage *obj
	Eina_Bool fill_outside


Eina_Bool
elm_image_fill_outside_get(obj)
	ElmImage *obj


void
elm_image_preload_disabled_set(obj,disabled)
	ElmImage *obj
	Eina_Bool disabled


void
elm_image_orient_set(obj,orient)
	ElmImage *obj
	int orient


int
elm_image_orient_get(obj)
	ElmImage *obj


ElmImage *
elm_image_object_get(obj)
	ElmImage *obj


void
elm_image_object_size_get(obj,OUTLIST w,OUTLIST h)
	ElmImage *obj
	int w
	int h


void
elm_image_resizable_set(obj,up,down)
	ElmImage *obj
	Eina_Bool up
	Eina_Bool down


void
elm_image_resizable_get(obj,OUTLIST up,OUTLIST down)
	ElmImage *obj
	Eina_Bool up
	Eina_Bool down


void
elm_image_no_scale_set(obj,no_scale)
	ElmImage *obj
	Eina_Bool no_scale


Eina_Bool
elm_image_no_scale_get(obj)
	ElmImage *obj


void
elm_image_aspect_fixed_set(obj,fixed)
	ElmImage *obj
	Eina_Bool fixed


Eina_Bool
elm_image_aspect_fixed_get(obj)
	ElmImage *obj


void
elm_image_async_open_set(obj,async)
	ElmImage *obj
	Eina_Bool async


MODULE = pEFL::Elm::Image		PACKAGE = ElmImageProgressPtr

double
now(progress_info)
    ElmImageProgress *progress_info
CODE:
    RETVAL = progress_info->now;
OUTPUT:
    RETVAL
    
double
total(progress_info)
    ElmImageProgress *progress_info
CODE:
    RETVAL = progress_info->total;
OUTPUT:
    RETVAL
