#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Elm_Object_Item ElmColorselectorPaletteItem;


MODULE = pEFL::Elm::ColorselectorPaletteItem		PACKAGE = ElmColorselectorPaletteItemPtr     PREFIX = elm_colorselector_palette_item_

void
elm_colorselector_palette_item_color_get(it,OUTLIST r, OUTLIST g, OUTLIST b, OUTLIST a)
    ElmColorselectorPaletteItem *it
    int r
    int g
    int b
    int a


void
elm_colorselector_palette_item_color_set(it, r, g, b, a)
    ElmColorselectorPaletteItem *it
    int r
    int g
    int b
    int a
    
Eina_Bool
elm_colorselector_palette_item_selected_get(it)
    ElmColorselectorPaletteItem *it

    
void
elm_colorselector_palette_item_selected_set(it, selected)
    ElmColorselectorPaletteItem *it
    Eina_Bool selected
