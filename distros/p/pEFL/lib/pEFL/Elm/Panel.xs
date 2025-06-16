#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmPanel;
typedef Evas_Object EvasObject;
typedef Elm_Panel_Scroll_Info ElmPanelScrollInfo;

MODULE = pEFL::Elm::Panel		PACKAGE = pEFL::Elm::Panel

ElmPanel *
elm_panel_add(parent)
    EvasObject *parent

MODULE = pEFL::Elm::Panel		PACKAGE = ElmPanelPtr     PREFIX = elm_panel_

void
elm_panel_orient_set(obj,orient)
	ElmPanel *obj
	int orient


int
elm_panel_orient_get(obj)
	const ElmPanel *obj


void
elm_panel_hidden_set(obj,hidden)
	ElmPanel *obj
	Eina_Bool hidden


Eina_Bool
elm_panel_hidden_get(obj)
	const ElmPanel *obj


void
elm_panel_scrollable_set(obj,scrollable)
	ElmPanel *obj
	Eina_Bool scrollable


Eina_Bool
elm_panel_scrollable_get(obj)
	const ElmPanel *obj


void
elm_panel_scrollable_content_size_set(obj,ratio)
	ElmPanel *obj
	double ratio


double
elm_panel_scrollable_content_size_get(obj)
	const ElmPanel *obj


void
elm_panel_toggle(obj)
	ElmPanel *obj


MODULE = pEFL::Elm::Panel		PACKAGE = ElmPanelScrollInfoPtr

double
rel_x(scroll_info)
    ElmPanelScrollInfo *scroll_info
CODE:
    RETVAL = scroll_info->rel_x;
OUTPUT:
    RETVAL
    
double
rel_y(scroll_info)
    ElmPanelScrollInfo *scroll_info
CODE:
    RETVAL = scroll_info->rel_y;
OUTPUT:
    RETVAL
