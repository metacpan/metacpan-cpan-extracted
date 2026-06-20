#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Elementary.h>

MODULE = pEFL::Elm::App		PACKAGE = pEFL::Elm::App	PREFIX = elm_app_

# TODO or not TODO? I think this func is not important
#void elm_app_info_set 	( 	void *  	mainfunc,
#		const char *  	dom,
#		const char *  	checkfile 
#	) 	

void 
elm_app_name_set(name)
	const char *name

void 
elm_app_desktop_entry_set(path)
	const char *path

void 
elm_app_compile_bin_dir_set(dir)
	const char *dir

void
elm_app_compile_lib_dir_set(dir)
	const char *dir	 	 	 	

void
elm_app_compile_data_dir_set(dir)
	const char *dir

void
elm_app_compile_locale_set(dir)
	const char *dir

const char*
elm_app_name_get()

const char*
elm_app_desktop_entry_get()

const char*
elm_app_prefix_dir_get()

const char*
elm_app_bin_dir_get()

const char*
elm_app_lib_dir_get()

const char*
elm_app_data_dir_get()

const char*
elm_app_locale_dir_get()

void 
elm_app_base_scale_set(base_scale) 	
	double base_scale

double
elm_app_base_scale_get()

MODULE = pEFL::Elm::App		PACKAGE = ElmAppPtr     PREFIX = elm_app_

