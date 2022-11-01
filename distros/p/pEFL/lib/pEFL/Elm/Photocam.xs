#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmPhotocam;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Photocam		PACKAGE = pEFL::Elm::Photocam

ElmPhotocam *
elm_photocam_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Photocam		PACKAGE = ElmPhotocamPtr     PREFIX = elm_photocam_


void
elm_photocam_image_region_bring_in(obj,x,y,w,h)
	ElmPhotocam *obj
	int x
	int y
	int w
	int h


# Evas_Load_Error (= enum!)
int
elm_photocam_file_set(obj,file)
	ElmPhotocam *obj
	const char *file


char *
elm_photocam_file_get(obj)
	const ElmPhotocam *obj

# EVAS_IMAGE_ORIENT (=enum!)
void
elm_photocam_image_orient_set(obj,orient)
	ElmPhotocam *obj
	int orient


int
elm_photocam_image_orient_get(obj)
	const ElmPhotocam *obj


EvasObject*
elm_photocam_internal_image_get(obj)
	const ElmPhotocam *obj


void
elm_photocam_image_region_show(obj,x,y,w,h)
	ElmPhotocam *obj
	int x
	int y
	int w
	int h


void
elm_photocam_image_size_get(obj,OUTLIST w, OUTLIST h)
	const ElmPhotocam *obj
	int w
	int h


Eina_Bool
elm_photocam_paused_get(obj)
	const ElmPhotocam *obj


void
elm_photocam_paused_set(obj,paused)
	ElmPhotocam *obj
	Eina_Bool paused


void
elm_photocam_zoom_set(obj,zoom)
	ElmPhotocam *obj
	double zoom


double
elm_photocam_zoom_get(obj)
	const ElmPhotocam *obj


void
elm_photocam_zoom_mode_set(obj,mode)
	ElmPhotocam *obj
	int mode


int
elm_photocam_zoom_mode_get(obj)
	const ElmPhotocam *obj


void
elm_photocam_image_region_get(obj,OUTLIST x,OUTLIST y,OUTLIST w,OUTLIST h)
	const ElmPhotocam *obj
	int x
	int y
	int w
	int h

void
elm_photocam_gesture_enabled_set(obj, gesture)
    ElmPhotocam *obj
    Eina_Bool gesture

Eina_Bool
elm_photocam_gesture_enabled_get(obj)
    ElmPhotocam *obj
