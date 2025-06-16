#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Eina.h>

// We need this typedef to bless the created object into the class EinaListPtr
// This class is a child class of pEFL::Eina::List
// By this trick we get a wonderful perlish oo-interface :-)
typedef Eina_List EinaList;

MODULE = pEFL::Eina::List		PACKAGE = pEFL::Eina::List

EinaList * 
eina_list_add()
PREINIT:
    EinaList *list;
CODE:
    list = NULL;
    RETVAL = list;
OUTPUT:
    RETVAL

MODULE = pEFL::Eina::List		PACKAGE = EinaListPtr     PREFIX = eina_list_

EinaList *
eina_list_prepend(list,data)
    EinaList *list
    void *data

EinaList *
eina_list_append_relative(list,data, relative)
    EinaList *list
    void *data
    void *relative

EinaList *
eina_list_append_relative_list(list,data,relative)
    EinaList *list
    void *data
    void *relative
    
EinaList *
eina_list_prepend_relative(list,data, relative)
    EinaList *list
    void *data
    void *relative

EinaList *
eina_list_prepend_relative_list(list,data,relative)
    EinaList *list
    void *data
    void *relative

# TODO eina_list_sorted_insert

EinaList *
eina_list_remove(list,data)
    EinaList *list
    void *data
    
EinaList *
eina_list_remove_list(list,remove_list)
    EinaList *list
    EinaList *remove_list
    
EinaList *
eina_list_promote_list(list,move_list)
    EinaList *list
    EinaList *move_list

EinaList *
eina_list_demote_list(list,move_list)
	EinaList *list
	EinaList *move_list

void *
eina_list_data_find(list,data)
    EinaList *list
    void *data

EinaList *
eina_list_data_find_list(list,data)
    EinaList *list
    void *data
    
# Eina_Bool
# eina_list_move(*to,*from,data)
#	EinaList **to
#	EinaList **from
#	void *data


# Eina_Bool
# eina_list_move_list(*to,*from,data)
#	EinaList **to
#	EinaList **from
#	EinaList *data


EinaList *
eina_list_free(list)
	EinaList *list
	

void*                 
eina_list_nth(list, n)
    EinaList *list
    unsigned int n


void*                 
eina_list_nth_list(list, n)
    EinaList *list
    unsigned int n


EinaList *
eina_list_reverse(list)
    EinaList *list

EinaList *
eina_list_reverse_clone(list)
    EinaList *list

EinaList *
eina_list_clone(list)
    EinaList *list
    
# TODO: eina_list_sort, eina_list_shuffle

EinaList *
eina_list_merge(left,right)
    EinaList *left
    EinaList *right
    
# TODO: eina_list_sorted_merge, eina_list_split_list

# EinaList *
# eina_list_search_sorted_near_list(list,func,data,result_cmp)
#	const EinaList *list
#	Eina_Compare_Cb func
#	const void *data
#	int *result_cmp


# EinaList *
# eina_list_search_sorted_list(list,func,data)
#	const EinaList *list
#	Eina_Compare_Cb func
#	const void *data


# void *
# eina_list_search_sorted(list,func,data)
#	const EinaList *list
#	Eina_Compare_Cb func
#	const void *data


# EinaList *
# eina_list_search_unsorted_list(list,func,data)
#	const EinaList *list
#	Eina_Compare_Cb func
#	const void *data


# void *
# eina_list_search_unsorted(list,func,data)
#	const EinaList *list
#	Eina_Compare_Cb func
#	const void *data


EinaList *
eina_list_last(list)
	EinaList *list
	

EinaList *
eina_list_next(list)
	EinaList *list
	
	
EinaList *
eina_list_prev(list)
	EinaList *list
	

void *
eina_list_data_get(list)
	EinaList *list
	
	
void *
eina_list_data_set(list,data)
	EinaList *list
	void *data

unsigned int
eina_list_count(list)
	EinaList *list

void *
eina_list_last_data_get(list)
	const EinaList *list

# TODO: iterator and accessor stuff


int
eina_list_data_idx(list,data)
	const EinaList *list
	void *data

