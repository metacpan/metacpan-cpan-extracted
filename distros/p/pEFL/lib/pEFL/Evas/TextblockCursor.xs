#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Canvas EvasCanvas;
typedef Evas_Textblock EvasTextblock;
typedef Evas_Textblock_Cursor EvasTextblockCursor;
typedef Evas_Object_Textblock_Node_Format EvasTextblockNodeFormat;
typedef Eina_List EinaList;


MODULE = pEFL::Evas::TextblockCursor		PACKAGE = pEFL::Evas::TextblockCursor

EvasTextblockCursor *
evas_object_textblock_cursor_new(obj)
	const EvasTextblock *obj

MODULE = pEFL::Evas::TextblockCursor		PACKAGE = pEFL::Evas::TextblockCursor PREFIX = evas_textblock_cursor_

void
evas_textblock_cursor_copy(cur,cur_dest)
	const EvasTextblockCursor *cur
	EvasTextblockCursor *cur_dest

int
evas_textblock_cursor_compare(cur1,cur2)
	const EvasTextblockCursor *cur1
	const EvasTextblockCursor *cur2


Eina_Bool
evas_textblock_cursor_equal(obj,cur)
	const EvasTextblockCursor *obj
	const EvasTextblockCursor *cur
	

MODULE = pEFL::Evas::TextblockCursor		PACKAGE = EvasTextblockCursorPtr     PREFIX = evas_textblock_cursor_

void
evas_textblock_cursor_set_at_format(cur,n)
	EvasTextblockCursor *cur
	const EvasTextblockNodeFormat *n


EvasTextblockNodeFormat *
evas_textblock_cursor_format_get(cur)
	const EvasTextblockCursor *cur


void
evas_textblock_cursor_at_format_set(cur,fmt)
	EvasTextblockCursor *cur
	const EvasTextblockNodeFormat *fmt


Eina_Bool
evas_textblock_cursor_format_is_visible_get(cur)
	const EvasTextblockCursor *cur


Eina_Bool
evas_textblock_cursor_format_next(cur)
	EvasTextblockCursor *cur


Eina_Bool
evas_textblock_cursor_format_prev(cur)
	EvasTextblockCursor *cur


Eina_Bool
evas_textblock_cursor_is_format(cur)
	const EvasTextblockCursor *cur


int
evas_textblock_cursor_pos_get(cur)
	const EvasTextblockCursor *cur


Eina_Bool
evas_textblock_cursor_line_set(cur,line)
	EvasTextblockCursor *cur
	int line


Eina_Bool
evas_textblock_cursor_format_append(cur,format)
	EvasTextblockCursor *cur
	const char *format


Eina_Bool
evas_textblock_cursor_format_prepend(cur,format)
	EvasTextblockCursor *cur
	const char *format


void
evas_textblock_cursor_range_delete(cur1,cur2)
	EvasTextblockCursor *cur1
	EvasTextblockCursor *cur2


char *
evas_textblock_cursor_paragraph_text_get(cur)
	const EvasTextblockCursor *cur


int
evas_textblock_cursor_paragraph_text_length_get(cur)
	const EvasTextblockCursor *cur


Eina_Bool
evas_textblock_cursor_visible_range_get(start,end)
	EvasTextblockCursor *start
	EvasTextblockCursor *end


EinaList *
evas_textblock_cursor_range_formats_get(cur1,cur2)
	const EvasTextblockCursor *cur1
	const EvasTextblockCursor *cur2


char *
evas_textblock_cursor_range_text_get(cur1,cur2,format)
	const EvasTextblockCursor *cur1
	const EvasTextblockCursor *cur2
	int format


char *
evas_textblock_cursor_content_get(cur)
	const EvasTextblockCursor *cur


#Eina_Bool
#evas_textblock_cursor_geometry_bidi_get(const Evas_Textblock_Cursor *cur, Evas_Coord *cx, Evas_Coord *cy, Evas_Coord *cw, Evas_Coord *ch, Evas_Coord *cx2, Evas_Coord *cy2, Evas_Coord *cw2, Evas_Coord *ch2, Evas_Textblock_Cursor_Type ctype);

int
evas_textblock_cursor_geometry_get(cur,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch,OUTLIST dir,ctype)
	const EvasTextblockCursor *cur
	Evas_Coord cx
	Evas_Coord cy
	Evas_Coord cw
	Evas_Coord ch
	Evas_BiDi_Direction dir
	int ctype


int
evas_textblock_cursor_char_geometry_get(cur,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasTextblockCursor *cur
	Evas_Coord cx
	Evas_Coord cy
	Evas_Coord cw
	Evas_Coord ch


int
evas_textblock_cursor_pen_geometry_get(cur,OUTLIST cpen_x,OUTLIST cy,OUTLIST cadv,OUTLIST ch)
	const EvasTextblockCursor *cur
	Evas_Coord cpen_x
	Evas_Coord cy
	Evas_Coord cadv
	Evas_Coord ch


int
evas_textblock_cursor_line_geometry_get(cur,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasTextblockCursor *cur
	Evas_Coord cx
	Evas_Coord cy
	Evas_Coord cw
	Evas_Coord ch


int
evas_textblock_cursor_line_coord_set(cur,y)
	EvasTextblockCursor *cur
	Evas_Coord y


EinaList *
evas_textblock_cursor_range_geometry_get(cur1,cur2)
	const EvasTextblockCursor *cur1
	const EvasTextblockCursor *cur2


# EinaIterator *
# evas_textblock_cursor_range_simple_geometry_get(cur1,cur2)
#	const EvasTextblockCursor *cur1
#	const EvasTextblockCursor *cur2


Eina_Bool
evas_textblock_cursor_format_item_geometry_get(cur,OUTLIST cx,OUTLIST cy,OUTLIST cw,OUTLIST ch)
	const EvasTextblockCursor *cur
	Evas_Coord cx
	Evas_Coord cy
	Evas_Coord cw
	Evas_Coord ch


Eina_Bool
evas_textblock_cursor_eol_get(cur)
	const EvasTextblockCursor *cur


Eina_Bool
evas_textblock_cursor_char_prev(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_char_next(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_cluster_prev(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_cluster_next(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_paragraph_next(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_paragraph_prev(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_word_start(obj)
	EvasTextblockCursor *obj


Eina_Bool
evas_textblock_cursor_word_end(obj)
	EvasTextblockCursor *obj
	
	
void
evas_textblock_cursor_copy(cur,cur_dest)
	const EvasTextblockCursor *cur
	EvasTextblockCursor *cur_dest



Eina_Bool
evas_textblock_cursor_char_coord_set(obj,x,y)
	EvasTextblockCursor *obj
	Evas_Coord x
	Evas_Coord y


Eina_Bool
evas_textblock_cursor_cluster_coord_set(obj,x,y)
	EvasTextblockCursor *obj
	Evas_Coord x
	Evas_Coord y


void
evas_textblock_cursor_free(cur)
	EvasTextblockCursor *cur


int
evas_textblock_cursor_text_append(cur,text)
	EvasTextblockCursor *cur
	const char *text


int
evas_textblock_cursor_text_prepend(cur,text)
	EvasTextblockCursor *cur
	const char *text
	

void
evas_object_textblock_text_markup_prepend(cur,text)
	EvasTextblockCursor *cur
	const char *text
	
	
void
evas_textblock_cursor_paragraph_first(cur)
	EvasTextblockCursor *cur


void
evas_textblock_cursor_paragraph_last(cur)
	EvasTextblockCursor *cur


int
evas_textblock_cursor_compare(cur1,cur2)
	const EvasTextblockCursor *cur1
	const EvasTextblockCursor *cur2


Eina_Bool
evas_textblock_cursor_equal(obj,cur)
	const EvasTextblockCursor *obj
	const EvasTextblockCursor *cur


void
evas_textblock_cursor_line_char_first(cur)
	EvasTextblockCursor *cur


void
evas_textblock_cursor_line_char_last(cur)
	EvasTextblockCursor *cur


void
evas_textblock_cursor_pos_set(cur,_pos)
	EvasTextblockCursor *cur
	int _pos


void
evas_textblock_cursor_paragraph_char_first(cur)
	EvasTextblockCursor *cur


void
evas_textblock_cursor_paragraph_char_last(cur)
	EvasTextblockCursor *cur


void
evas_textblock_cursor_char_delete(cur)
	EvasTextblockCursor *cur
