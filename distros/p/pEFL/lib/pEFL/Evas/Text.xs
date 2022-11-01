#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Text EvasText;


MODULE = pEFL::Evas::Text		PACKAGE = pEFL::Evas::Text

EvasText *
evas_object_text_add(e)
	EvasCanvas *e

MODULE = pEFL::Evas::Text		PACKAGE = EvasTextPtr     PREFIX = evas_object_text_


void
evas_object_text_text_set(obj,text)
	EvasText *obj
	const char *text


char *
evas_object_text_text_get(obj)
	const EvasText *obj


void
evas_object_text_font_source_set(obj,font_source)
	EvasText *obj
	const char *font_source


char *
evas_object_text_font_source_get(obj)
	const EvasText *obj


void
evas_object_text_font_set(obj,font,size)
	EvasText *obj
	const char *font
	int size


void
evas_object_text_font_get(obj, OUTLIST font,OUTLIST size)
	const EvasText *obj
	const char *font
	int size


void
evas_object_text_shadow_color_set(obj,r,g,b,a)
	EvasText *obj
	int r
	int g
	int b
	int a


void
evas_object_text_shadow_color_get(obj,OUTLIST r,OUTLIST g,OUTLIST b,OUTLIST a)
	const EvasText *obj
	int r
	int g
	int b
	int a


void
evas_object_text_ellipsis_set(obj,ellipsis)
	EvasText *obj
	double ellipsis


double
evas_object_text_ellipsis_get(obj)
	const EvasText *obj


void
evas_object_text_bidi_delimiters_set(obj,delim)
	EvasText *obj
	const char *delim


char *
evas_object_text_bidi_delimiters_get(obj)
	const EvasText *obj


void
evas_object_text_outline_color_set(obj,r,g,b,a)
	EvasText *obj
	int r
	int g
	int b
	int a


void
evas_object_text_outline_color_get(obj,OUTLIST r,OUTLIST g,OUTLIST b,OUTLIST a)
	const EvasText *obj
	int r
	int g
	int b
	int a


void
evas_object_text_style_set(obj,style)
	EvasText *obj
	int style


int
evas_object_text_style_get(obj)
	const EvasText *obj


void
evas_object_text_glow_color_set(obj,r,g,b,a)
	EvasText *obj
	int r
	int g
	int b
	int a


void
evas_object_text_glow_color_get(obj,OUTLIST r,OUTLIST g,OUTLIST b,OUTLIST a)
	const EvasText *obj
	int r
	int g
	int b
	int a


int
evas_object_text_max_descent_get(obj)
	const EvasText *obj


void
evas_object_text_style_pad_get(obj,OUTLIST l,OUTLIST r,OUTLIST t,OUTLIST b)
	const EvasText *obj
	int l
	int r
	int t
	int b


# Efl_Text_Bidirectional_Type (???)
int
evas_object_text_direction_get(obj)
	const EvasText *obj


int
evas_object_text_ascent_get(obj)
	const EvasText *obj


int
evas_object_text_horiz_advance_get(obj)
	const EvasText *obj


int
evas_object_text_inset_get(obj)
	const EvasText *obj


int
evas_object_text_max_ascent_get(obj)
	const EvasText *obj


int
evas_object_text_vert_advance_get(obj)
	const EvasText *obj


int
evas_object_text_descent_get(obj)
	const EvasText *obj


int
evas_object_text_last_up_to_pos(obj,x,y)
	const EvasText *obj
	int x
	int y


int
evas_object_text_char_coords_get(obj,x,y,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasText *obj
	int x
	int y
	int cx
	int cy
	int cw
	int ch


Eina_Bool
evas_object_text_char_pos_get(obj,pos,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasText *obj
	int pos
	int cx
	int cy
	int cw
	int ch
