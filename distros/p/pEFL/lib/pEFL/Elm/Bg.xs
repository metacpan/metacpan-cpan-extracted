#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmBg;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Bg		PACKAGE = pEFL::Elm::Bg

ElmBg * 
elm_bg_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Bg		PACKAGE = ElmBgPtr     PREFIX = elm_bg_

void
elm_bg_color_set(obj,r,g,b)
	EvasObject *obj
	int r
	int g
	int b


void
elm_bg_color_get(obj,OUTLIST r,OUTLIST g,OUTLIST b)
	const EvasObject *obj
	int r
	int g
	int b


# TODO: obj ist const Eo *obj
Eina_Bool
elm_bg_file_set(obj,file,group)
	EvasObject *obj
	const char *file
	const char *group


# TODO: obj ist const Eo *obj
void
elm_bg_file_get(obj,OUTLIST file,OUTLIST group)
	const EvasObject *obj
	const char *file
	const char *group


void
elm_bg_option_set(obj,option)
	EvasObject *obj
	int option


int
elm_bg_option_get(obj)
	const EvasObject *obj


void
elm_bg_load_size_set(obj,w,h)
	EvasObject *obj
	int w
	int h
