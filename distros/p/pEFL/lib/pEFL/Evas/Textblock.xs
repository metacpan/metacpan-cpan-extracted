#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Object EvasObject;
typedef Evas_Textblock EvasTextblock;
typedef Evas_Textblock_Style EvasTextblockStyle;
typedef Evas_Textblock_Node_Format EvasTextblockNodeFormat;
typedef Evas_Textblock_Cursor EvasTextblockCursor;
typedef Eina_List EinaList;
typedef Evas_Textblock_Rectangle EvasTextblockRectangle;


MODULE = pEFL::Evas::Textblock		PACKAGE = pEFL::Evas::Textblock

EvasTextblock *
evas_object_textblock_add(e)
	EvasCanvas *e

MODULE = pEFL::Evas::Textblock		PACKAGE = pEFL::Evas::Textblock    PREFIX = evas_textblock_

char *
evas_textblock_escape_string_get(escape)
	const char *escape

char *
evas_textblock_string_escape_get(string,OUTLIST len_ret)
	const char *string
	int len_ret

char *
evas_textblock_escape_string_range_get(escape_start,escape_end)
	const char *escape_start
	const char *escape_end


MODULE = pEFL::Evas::Textblock		PACKAGE = pEFL::Evas::Textblock    PREFIX = evas_object_textblock_

void
evas_object_textblock_text_markup_prepend(cur,text)
	EvasTextblockCursor *cur
	const char *text

		
MODULE = pEFL::Evas::Textblock		PACKAGE = EvasTextblockPtr     PREFIX = evas_textblock_
	
	
EvasTextblockNodeFormat*
evas_textblock_node_format_first_get(obj)
	EvasTextblock *obj


EvasTextblockNodeFormat*
evas_textblock_node_format_last_get(obj)
	EvasTextblock *obj


EinaList *
evas_textblock_node_format_list_get(obj,anchor)
	const EvasTextblock *obj
	const char *anchor


void
evas_textblock_node_format_remove_pair(obj,n)
	EvasTextblock *obj
	EvasTextblockNodeFormat *n


int
evas_textblock_fit_options_get(obj,OUTLIST p_options)
	const EvasTextblock *obj
	 unsigned int p_options


int
evas_textblock_fit_options_set(obj,options)
	EvasTextblock *obj
	unsigned int options


int
evas_textblock_fit_size_range_get(obj,OUTLIST p_min_font_size,OUTLIST p_max_font_size)
	const EvasTextblock *obj
	unsigned int p_min_font_size
	unsigned int p_max_font_size


int
evas_textblock_fit_size_range_set(obj,min_font_size,max_font_size)
	EvasTextblock *obj
	unsigned int min_font_size
	unsigned int max_font_size


int
evas_textblock_fit_step_size_get(obj,OUTLIST p_step_size)
	const EvasTextblock *obj
	unsigned int p_step_size


int
evas_textblock_fit_step_size_set(obj,step_size)
	EvasTextblock *obj
	 unsigned int step_size


# int
# evas_textblock_fit_size_array_get(obj,OUTLIST p_size_array,OUTLIST p_size_array_len, request_size_array)
#	const EvasTextblock *obj
#	unsigned int p_size_array
#	size_t p_size_array_len
#	size_t request_size_array


# int
# evas_textblock_fit_size_array_set(obj,p_size_array,size_array_len)
# 	EvasTextblock *obj
# 	const unsigned int *p_size_array
#	size_t size_array_len
	
	
MODULE = pEFL::Evas::Textblock		PACKAGE = EvasTextblockPtr     PREFIX = evas_object_textblock_


void
evas_object_textblock_clear(obj)
	EvasTextblock *obj


void
evas_object_textblock_text_markup_set(obj,text)
	EvasTextblock *obj
	const char *text


char *
evas_object_textblock_text_markup_get(obj)
	EvasTextblock *obj
	
void
evas_object_textblock_style_set(obj,ts)
	EvasTextblock *obj
	const EvasTextblockStyle *ts


EvasTextblockStyle *
evas_object_textblock_style_get(obj)
	const EvasTextblock *obj


void
evas_object_textblock_style_user_push(obj,ts)
	EvasTextblock *obj
	EvasTextblockStyle *ts


EvasTextblockStyle *
evas_object_textblock_style_user_peek(obj)
	const EvasTextblock *obj


void
evas_object_textblock_style_user_pop(obj)
	EvasTextblock *obj
	

Eina_Bool
evas_object_textblock_line_number_geometry_get(obj,line,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasTextblock *obj
	int line
	Evas_Coord cx
	Evas_Coord cy
	Evas_Coord cw
	Evas_Coord ch


void
evas_object_textblock_replace_char_set(obj,ch)
	EvasTextblock *obj
	const char *ch


char *
evas_object_textblock_replace_char_get(obj)
	const EvasTextblock *obj


void
evas_object_textblock_valign_set(obj,align)
	EvasTextblock *obj
	double align


double
evas_object_textblock_valign_get(obj)
	const EvasTextblock *obj


EvasTextblockCursor *
evas_object_textblock_cursor_get(obj)
	const EvasTextblock *obj
	
# TODO: start / end act like out-variables here, as they
# are set to the positions of the start and the end of the visible range in
# the text, respectively. (How) does this work???	
#Eina_Bool
#evas_object_textblock_visible_range_get(obj,OUTLIST start,OUTLIST end)
#	EvasTextblock *obj
#	EvasTextblockCursor *start
#	EvasTextblockCursor *end


void
evas_object_textblock_style_insets_get(obj,OUTLIST left,OUTLIST right,OUTLIST top,OUTLIST bottom)
	const EvasTextblock *obj
	int left
	int right
	int top
	int bottom


void
evas_object_textblock_bidi_delimiters_set(obj,delim)
	EvasTextblock *obj
	const char *delim


char *
evas_object_textblock_bidi_delimiters_get(obj)
	const EvasTextblock *obj


void
evas_object_textblock_legacy_newline_set(obj,mode)
	EvasTextblock *obj
	Eina_Bool mode


Eina_Bool
evas_object_textblock_legacy_newline_get(obj)
	const EvasTextblock *obj


void
evas_object_textblock_size_formatted_get(obj,OUTLIST width,OUTLIST height)
	const EvasTextblock *obj
	int width
	int height


void
evas_object_textblock_size_native_get(obj,OUTLIST width,OUTLIST height)
	const EvasTextblock *obj
	int width
	int height

# eo_obs is Efl_Canvas_Object
Eina_Bool
evas_object_textblock_obstacle_add(obj,eo_obs)
	EvasTextblock *obj
	EvasObject *eo_obs


Eina_Bool
evas_object_textblock_obstacle_del(obj,eo_obs)
	EvasTextblock *obj
	EvasObject *eo_obs


void
evas_object_textblock_obstacles_update(obj)
	EvasTextblock *obj
	
MODULE = pEFL::Evas::Textblock		PACKAGE = EvasTextblockRectanglePtr

Evas_Coord
x(rect)
    EvasTextblockRectangle *rect
CODE:
    RETVAL = rect->x;
OUTPUT:
    RETVAL
  
  
Evas_Coord
y(rect)
    EvasTextblockRectangle *rect
CODE:
    RETVAL = rect->y;
OUTPUT:
    RETVAL
    

Evas_Coord
w(rect)
    EvasTextblockRectangle *rect
CODE:
    RETVAL = rect->w;
OUTPUT:
    RETVAL
    
    
Evas_Coord
h(rect)
    EvasTextblockRectangle *rect
CODE:
    RETVAL = rect->h;
OUTPUT:
    RETVAL
