#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>


typedef Evas_Object ElmTable;
typedef Evas_Object EvasObject;

MODULE = pEFL::Elm::Table		PACKAGE = pEFL::Elm::Table

ElmTable * 
elm_table_add(EvasObject *parent)

MODULE = pEFL::Elm::Table		PACKAGE = pEFL::Elm::Table     PREFIX = elm_table_

void
elm_table_pack_set(subobj,col,row,colspan,rowspan)
	EvasObject *subobj
	int col
	int row
	int colspan
	int rowspan


void
elm_table_pack_get(subobj,OUTLIST col,OUTLIST row,OUTLIST colspan,OUTLIST rowspan)
	EvasObject *subobj
	int col
	int row
	int colspan
	int rowspan

MODULE = pEFL::Elm::Table		PACKAGE = ElmTablePtr     PREFIX = elm_table_


void
elm_table_homogeneous_set(obj,homogeneous)
	ElmTable *obj
	Eina_Bool homogeneous


Eina_Bool
elm_table_homogeneous_get(obj)
	const ElmTable *obj


void
elm_table_padding_set(obj,horizontal,vertical)
	ElmTable *obj
	int horizontal
	int vertical


void
elm_table_padding_get(obj,OUTLIST horizontal,OUTLIST vertical)
	const ElmTable *obj
	int horizontal
	int vertical


void
elm_table_align_set(obj,horizontal,vertical)
	ElmTable *obj
	double horizontal
	double vertical


void
elm_table_align_get(obj,OUTLIST horizontal,OUTLIST vertical)
	const ElmTable *obj
	double horizontal
	double vertical


void
elm_table_clear(obj,clear)
	ElmTable *obj
	Eina_Bool clear


EvasObject *
elm_table_child_get(obj,col,row)
	const ElmTable *obj
	int col
	int row


void
elm_table_unpack(obj,subobj)
	ElmTable *obj
	EvasObject *subobj


void
elm_table_pack(obj,subobj,column,row,colspan,rowspan)
	ElmTable *obj
	EvasObject *subobj
	int column
	int row
	int colspan
	int rowspan


