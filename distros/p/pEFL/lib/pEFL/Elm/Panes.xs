#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmPanes;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Panes		PACKAGE = pEFL::Elm::Panes

ElmPanes * 
elm_panes_add(EvasObject *parent)

MODULE = pEFL::Elm::Panes		PACKAGE = ElmPanesPtr     PREFIX = elm_panes_

void
elm_panes_horizontal_set(obj,horizontal)
	ElmPanes *obj
	Eina_Bool horizontal
	
Eina_Bool
elm_panes_horizontal_get(obj)
	ElmPanes *obj
	
void
elm_panes_content_left_min_size_set(obj,size)
	ElmPanes *obj
	int size
	
int
elm_panes_content_left_min_size_get(obj)
	ElmPanes *obj
	
void
elm_panes_content_right_min_size_set(obj,size)
	ElmPanes *obj
	int size
	
int
elm_panes_content_right_min_size_get(obj)
	ElmPanes *obj

void
elm_panes_content_right_size_set(obj,size)
	ElmPanes *obj
	double size
	
double
elm_panes_content_right_size_get(obj)
	ElmPanes *obj
	
void
elm_panes_content_left_size_set(obj,size)
	ElmPanes *obj
	double size
	
double
elm_panes_content_left_size_get(obj)
	ElmPanes *obj
	
void
elm_panes_content_left_min_relative_size_set(obj,size)
	ElmPanes *obj
	double size
	
double
elm_panes_content_left_min_relative_size_get(obj)
	ElmPanes *obj
	
void
elm_panes_content_right_min_relative_size_set(obj,size)
	ElmPanes *obj
	double size
	
	
double
elm_panes_content_right_min_relative_size_get(obj)
	ElmPanes *obj
	
void 
elm_panes_fixed_set(obj,fixed)
    ElmPanes *obj
    Eina_Bool fixed
    
Eina_Bool
elm_panes_fixed_get(obj)
    ElmPanes *obj
