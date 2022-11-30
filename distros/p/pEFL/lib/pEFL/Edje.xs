#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

#include "const-edje-c.inc"

typedef Eo EdjeObject;
typedef Evas_Object EvasObject;


MODULE = pEFL::Edje 	PACKAGE = pEFL::Edje PREFIX = edje_

INCLUDE: const-edje-xs.inc

int
edje_init()


int
edje_shutdown()


# Eina_List *
# edje_available_modules_get()


void
edje_file_cache_flush()


void
edje_file_cache_set(count)
	int count


int
edje_file_cache_get()


void
edje_collection_cache_flush()


void
edje_collection_cache_set(count)
	int count


int
edje_collection_cache_get()


# Eina_List *
# edje_file_collection_list(file)
#	const char *file


# void
# edje_file_collection_list_free(lst)
#	Eina_List *lst


char *
edje_file_data_get(file,key)
	const char *file
	const char *key


Eina_Bool
edje_file_group_exists(file,glob)
	const char *file
	const char *glob


char *
edje_fontset_append_get()
	 

void
edje_fontset_append_set(fonts)
	const char *fonts


void
edje_frametime_set(t)
	double t


double
edje_frametime_get()


void
edje_freeze()
	 

void
edje_thaw()


void
edje_message_signal_process()


Eina_Bool
edje_module_load(module)
	const char *module


void
edje_password_show_last_set(password_show_last)
	Eina_Bool password_show_last


void
edje_password_show_last_timeout_set(password_show_last_timeout)
	double password_show_last_timeout
	

void
edje_scale_set(scale)
	double scale


double
edje_scale_get()


# Edje_External_Param *
# edje_external_param_find(params,key)
#	const Eina_List *params
#	const char *key


# Eina_Bool
# edje_external_param_int_get(params,key,ret)
#	const Eina_List *params
#	const char *key
#	int *ret


# Eina_Bool
# edje_external_param_double_get(params,key,ret)
#	const Eina_List *params
#	const char *key
#	double *ret


# Eina_Bool
# edje_external_param_string_get(params,key,*ret)
#	const Eina_List *params
#	const char *key
#	const char **ret


# Eina_Bool
# edje_external_param_bool_get(params,key,ret)
#	const Eina_List *params
#	const char *key
#	Eina_Bool *ret


# Eina_Bool
# edje_external_param_choice_get(params,key,*ret)
#	const Eina_List *params
#	const char *key
#	const char **ret


# Edje_External_Param_Info *
# edje_external_param_info_get(type_name)
#	const char *type_name


#Edje_External_Type *
#edje_external_type_get(type_name)
#	const char *type_name


Eina_Bool
edje_color_class_set(color_class,r,g,b,a,r2,g2,b2,a2,r3,g3,b3,a3)
	const char *color_class
	int r
	int g
	int b
	int a
	int r2
	int g2
	int b2
	int a2
	int r3
	int g3
	int b3
	int a3


void
edje_color_class_apply()
	 


Eina_Bool
edje_color_class_get(color_class,OUTLIST r,OUTLIST g,OUTLIST b,OUTLIST a,OUTLIST r2,OUTLIST g2,OUTLIST b2,OUTLIST a2,OUTLIST r3,OUTLIST g3,OUTLIST b3,OUTLIST a3)
	const char *color_class
	int r
	int g
	int b
	int a
	int r2
	int g2
	int b2
	int a2
	int r3
	int g3
	int b3
	int a3


void
edje_color_class_del(color_class)
	const char *color_class


Eina_List *
edje_color_class_list()


# Eina_Iterator *
# edje_color_class_active_iterator_new()


# Eina_Iterator *
# edje_mmap_color_class_iterator_new(f)
#	Eina_File *f


Eina_Bool
edje_size_class_set(size_class,minw,minh,maxw,maxh)
	const char *size_class
	Evas_Coord minw
	Evas_Coord minh
	Evas_Coord maxw
	Evas_Coord maxh


Eina_Bool
edje_size_class_get(size_class,OUTLIST minw,OUTLIST minh,OUTLIST maxw,OUTLIST maxh)
	const char *size_class
	Evas_Coord minw
	Evas_Coord minh
	Evas_Coord maxw
	Evas_Coord maxh


void
edje_size_class_del(size_class)
	const char *size_class


Eina_List *
edje_size_class_list()


Eina_Bool
edje_text_class_set(text_class,font,size)
	const char *text_class
	const char *font
	int size


# *font (?) 
Eina_Bool
edje_text_class_get(text_class,OUTLIST font,OUTLIST size)
	const char *text_class
	const char *font
	int size


void
edje_text_class_del(text_class)
	const char *text_class


Eina_List *
edje_text_class_list()


void
edje_language_set(locale)
	const char *locale


void
edje_transition_duration_factor_set(scale)
	double scale


double
edje_transition_duration_factor_get()


###################
# Not implemented functions of Edje_Common.h
###################

# Eina_Iterator *
# edje_text_class_active_iterator_new()
	 

# Eina_Iterator *
# edje_mmap_text_class_iterator_new(f)
#	Eina_File *f 


# Eina_Iterator *
# edje_size_class_active_iterator_new()  


# Eina_Iterator *
# edje_mmap_size_class_iterator_new(f)
#	Eina_File *f 


# void *
# edje_object_signal_callback_extra_data_get()

# void *
# edje_object_signal_callback_seat_data_get()

# void
# edje_audio_channel_mute_set(channel,mute)
#	Edje_Channel channel
#	Eina_Bool mute


# Eina_Bool
# edje_audio_channel_mute_get(channel)
#	Edje_Channel channel


# char *
# edje_mmap_data_get(f,key)
#	const Eina_File *f
#	const char *key


# Eina_Bool
# edje_external_type_register(type_name,type_info)
#	const char *type_name
#	const Edje_External_Type *type_info


# Eina_Bool
# edje_external_type_unregister(type_name)
#	const char *type_name


# void
# edje_external_type_array_register(array)
#	const Edje_External_Type_Info *array


# void
# edje_external_type_array_unregister(array)
#	const Edje_External_Type_Info *array


# Eina_Iterator *
# edje_external_iterator_get()


#####################

# Eina_List *
# edje_mmap_collection_list(f)
#	Eina_File *f


# void
# edje_mmap_collection_list_free(lst)
#	Eina_List *lst


# Eina_List *
# edje_mmap_color_class_used_list(f)
#	Eina_File *f


# Eina_List *
# edje_file_color_class_used_list(file)
#	const char *file


# void
# edje_file_color_class_used_free(lst)
#	Eina_List *lst


# Eina_Bool
# edje_mmap_group_exists(f,glob)
#	Eina_File *f
#	const char *glob


# Eina_Iterator *
# edje_file_iterator_new()


##########
	 

# void
# edje_box_layout_register(name,func,),),),data)
#	const char *name
#	EvasObject_Box_Layout func
#	void *(*layout_data_get)(void *)
#	void (*layout_data_free)(void *)
#	void (*free_data)(void *)
#	void *data


############################
# From Edje_Legacy.h
###########################

Eina_Bool
edje_file_text_class_set(file,text_class,font,size)
	const char *file
	const char *text_class
	const char *font
	int size


Eina_Bool
edje_file_text_class_del(file,text_class)
	const char *file
	const char *text_class


Eina_Bool
edje_file_text_class_get(file,text_class,OUTLIST font,OUTLIST size)
	const char *file
	const char * text_class
	const char *font
	int size
	
char *
edje_load_error_str(error)
	int error




