#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Glview ElmGlview;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Glview		PACKAGE = pEFL::Elm::Glview

ElmGlview *
elm_glview_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Glview		PACKAGE = ElmGlviewPtr     PREFIX = elm_glview_

ElmGlview *
elm_glview_version_add(parent,version)
	EvasObject *parent
	int version


void
elm_glview_changed_set(obj)
	ElmGlview *obj


void
elm_glview_size_get(obj,OUTLIST w, OUTLIST h)
	ElmGlview *obj
	int w
	int h


void
elm_glview_size_set(obj,w,h)
	ElmGlview *obj
	int w
	int h


# void
# elm_glview_init_func_set(obj,func)
#	ElmGlview *obj
#	Elm_Glview_Func_Cb func


# void
# elm_glview_del_func_set(obj,func)
#	ElmGlview *obj
# 	Elm_Glview_Func_Cb func


# void
# elm_glview_resize_func_set(obj,func)
#	ElmGlview *obj
#	Elm_Glview_Func_Cb func


# void
# elm_glview_render_func_set(obj,func)
#	ElmGlview *obj
#	Elm_Glview_Func_Cb func

Eina_Bool
elm_glview_resize_policy_set(obj,policy)
	ElmGlview *obj
	int policy


Eina_Bool
elm_glview_render_policy_set(obj,policy)
	ElmGlview *obj
	int policy


Eina_Bool
elm_glview_mode_set(obj,mode)
	ElmGlview *obj
	int mode


# Evas_GL_API *
# elm_glview_gl_api_get(obj)
#	ElmGlview *obj


# Evas_GL *
# elm_glview_evas_gl_get(obj)
#	ElmGlview *obj


int
elm_glview_rotation_get(obj)
	ElmGlview *obj
