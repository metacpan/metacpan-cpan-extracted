#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <blade.h>
#include "util.h"
#include "blade_page.h"
#include "blade_run.h"
#include "blade_obj_simple_init.h"
#include "blade_theme_simple_init.h"

typedef CORBA_char CORBA_char_nodup;

typedef blade_hash *	BLADEHASH;
typedef blade_env *	BLADEENV;

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = BLADE		PACKAGE = BLADE

PROTOTYPES: DISABLE

double
constant(name,arg)
	char *		name
	int		arg


void
blade_hr(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_hr = 1
		BLADEENV::hr = 2

void
blade_br(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_br = 1
		BLADEENV::br = 2

void
blade_b(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_b = 1
		BLADEENV::b = 2

void
blade_i(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_i = 1
		BLADEENV::i = 2

void
blade_u(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_u = 1
		BLADEENV::u = 2

void
blade_s(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_s = 1
		BLADEENV::s = 2

void
blade_h1(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_h1 = 1
		BLADEENV::h1 = 2

void
blade_h2(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_h2 = 1
		BLADEENV::h2 = 2

void
blade_h3(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_h3 = 1
		BLADEENV::h3 = 2

void
blade_h4(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_h4 = 1
		BLADEENV::h4 = 2

void
blade_h5(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_h5 = 1
		BLADEENV::h5 = 2

void
blade_h6(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_h6 = 1
		BLADEENV::h6 = 2

void
blade_ul(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_ul = 1
		BLADEENV::ul = 2

void
blade_ol(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_ol = 1
		BLADEENV::ol = 2

void
blade_li(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_li = 1
		BLADEENV::li = 2

void
blade_dir(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_dir = 1
		BLADEENV::dir = 2

void
blade_dd(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_dd = 1
		BLADEENV::dd = 2

void
blade_center(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_center = 1
		BLADEENV::center = 2

void
blade_p(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_p = 1
		BLADEENV::p = 2

void
blade_pre(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_pre = 1
		BLADEENV::pre = 2

void
blade_big(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_big = 1
		BLADEENV::big = 2

void
blade_em(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_em = 1
		BLADEENV::em = 2

void
blade_small(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_small = 1
		BLADEENV::small = 2

void
blade_sub(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_sub = 1
		BLADEENV::sub = 2

void
blade_sup(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_sup = 1
		BLADEENV::sup = 2

void
blade_titlebox(blade, mode)
	BLADEENV blade
	int mode
	ALIAS:
		BLADE::blade_titlebox = 1
		BLADEENV::titlebox = 2

void
blade_tt(blade, start)
	BLADEENV blade
	int start
	ALIAS:
		BLADE::blade_tt = 1
		BLADEENV::tt = 2

void
blade_table(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_table = 1
		BLADEENV::table = 2

void
blade_tr(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_tr = 1
		BLADEENV::tr = 2

void
blade_td(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_td = 1
		BLADEENV::td = 2

void
blade_form(blade, start, method, action, args)
	BLADEENV blade
	int start
	CORBA_char * method
	CORBA_char * action
	CORBA_char * args
	ALIAS:
		BLADE::blade_form = 1
		BLADEENV::form = 2

void
blade_input(blade, start, type, name, value, args)
	BLADEENV blade
	int start
	CORBA_char * type
	CORBA_char * name
	CORBA_char * value
	CORBA_char * args
	ALIAS:
		BLADE::blade_input = 1
		BLADEENV::input = 2

void
blade_select(blade, start, name, args)
	BLADEENV blade
	int start
	CORBA_char * name
	CORBA_char * args
	ALIAS:
		BLADE::blade_select = 1
		BLADEENV::select = 2

void
blade_option(blade, start, value, args)
	BLADEENV blade
	int start
	CORBA_char * value
	CORBA_char * args
	ALIAS:
		BLADE::blade_option = 1
		BLADEENV::option = 2

void
blade_textarea(blade, start, name, args)
	BLADEENV blade
	int start
	CORBA_char * name
	CORBA_char * args
	ALIAS:
		BLADE::blade_textarea = 1
		BLADEENV::textarea = 2

void
blade_div(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_div = 1
		BLADEENV::div = 2

void
blade_span(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_span = 1
		BLADEENV::span = 2

void
blade_font(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_font = 1
		BLADEENV::font = 2

void
blade_a(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_a = 1
		BLADEENV::a = 2

void
blade_img(blade, src, args)
	BLADEENV blade
	CORBA_char * src
	CORBA_char * args
	ALIAS:
		BLADE::blade_img = 1
		BLADEENV::img = 2

void
blade_link(blade, start, args)
	BLADEENV blade
	int start
	CORBA_char * args
	ALIAS:
		BLADE::blade_link = 1
		BLADEENV::link = 2

void
blade_tag(blade, start, name, def)
	BLADEENV blade
	int start
	CORBA_char * name
	CORBA_char * def
	ALIAS:
		BLADE::blade_tag = 1
		BLADEENV::tag = 2

void
blade_disp(blade, string)
	BLADEENV blade
	CORBA_char * string
	ALIAS:
		BLADE::blade_disp = 1
		BLADEENV::disp = 2

CORBA_char_nodup *
blade_color(blade, name, def)
	BLADEENV blade
	CORBA_char * name
	CORBA_char * def
	ALIAS:
		BLADE::blade_color = 1
		BLADEENV::color = 2

BLADEHASH
blade_hash_new()

void
blade_hash_free(hash)
	BLADEHASH hash
	ALIAS:
		BLADE::blade_hash_free = 1
		BLADEHASH::free = 2

long
blade_hash_count(hash)
	BLADEHASH hash

BLADEHASH
blade_hash_dup(hash)
	BLADEHASH hash
	ALIAS:
		BLADE::blade_hash_dup = 1
		BLADEHASH::dup = 2

CORBA_char *
blade_hash_get(hash, name)
	BLADEHASH hash
	CORBA_char * name
	ALIAS:
		BLADE::blade_hash_get = 1
		BLADEHASH::get = 2

CORBA_char_nodup *
blade_hash_get_nodup(hash, name)
	BLADEHASH hash
	CORBA_char * name

CORBA_char *
blade_hash_get_num(hash, number)
	BLADEHASH hash
	int number
	ALIAS:
		BLADE::blade_hash_get_num = 1
		BLADEHASH::get_num = 2

CORBA_char_nodup *
blade_hash_get_num_nodup(hash, number)
	BLADEHASH hash
	int number
	ALIAS:
		BLADE::blade_hash_get_num_nodup = 1
		BLADEHASH::get_num_nodup = 2

CORBA_char *
blade_hash_get_num_name(hash, number)
	BLADEHASH hash
	int number
	ALIAS:
		BLADE::blade_hash_get_num_name = 1
		BLADEHASH::get_num_name = 2

CORBA_char_nodup *
blade_hash_get_num_name_nodup(hash, number)
	BLADEHASH hash
	int number
	ALIAS:
		BLADE::blade_hash_get_num_name_nodup = 1
		BLADEHASH::get_num_name_nodup = 2

void
blade_hash_load_file(hash, name, overwrite)
	BLADEHASH hash
	CORBA_char * name
	int overwrite
	ALIAS:
		BLADE::blade_hash_load_file = 1
		BLADEHASH::load_file = 2

void
blade_hash_load_string(hash, string, overwrite)
	BLADEHASH hash
	CORBA_char * string
	int overwrite
	ALIAS:
		BLADE::blade_hash_load_string = 1
		BLADEHASH::load_string = 2

void
blade_hash_set(hash, name, value)
	BLADEHASH hash
	CORBA_char * name
	CORBA_char * value
	ALIAS:
		BLADE::blade_hash_set = 1
		BLADEHASH::set = 2

void
blade_hash_set_nodel(hash, name, value)
	BLADEHASH hash
	CORBA_char * name
	CORBA_char * value
	ALIAS:
		BLADE::blade_hash_set_nodel = 1
		BLADEHASH::set_nodel = 2

int
blade_hash_exists_in(hash, name)
	BLADEHASH hash
	CORBA_char * name
	ALIAS:
		BLADE::blade_hash_exists_in = 1
		BLADEHASH::exists_in = 2

int
blade_web_vars_count(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_web_vars_count = 1
		BLADEENV::web_vars_count = 2

CORBA_char * 
blade_web_vars_get(blade, name)
	BLADEENV blade
	CORBA_char * name
	ALIAS:
		BLADE::blade_web_vars_get = 1
		BLADEENV::web_vars_get = 2

CORBA_char_nodup *
blade_web_vars_get_nodup(blade, name)
	BLADEENV blade
	CORBA_char * name
	ALIAS:
		BLADE::blade_web_vars_get_nodup = 1
		BLADEENV::web_vars_get_nodup = 2

void
blade_web_vars_set(blade, name, value)
	BLADEENV blade
	CORBA_char * name
	CORBA_char * value
	ALIAS:
		BLADE::blade_web_vars_set = 1
		BLADEENV::web_vars_set = 2

BLADEHASH
blade_web_vars_get_all(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_web_vars_get_all = 1
		BLADEENV::web_vars_get_all = 2

CORBA_char *
blade_web_vars_get_num(blade, number)
	BLADEENV blade
	int number
	ALIAS:
		BLADE::blade_web_vars_get_num = 1
		BLADEENV::web_vars_get_num = 2

CORBA_char_nodup *
blade_web_vars_get_num_nodup(blade, number)
	BLADEENV blade
	int number
	ALIAS:
		BLADE::blade_web_vars_get_num_nodup = 1
		BLADEENV::web_vars_get_num_nodup = 2

CORBA_char *
blade_web_vars_get_num_name(blade, number)
	BLADEENV blade
	int number
	ALIAS:
		BLADE::blade_web_vars_get_num_name = 1
		BLADEENV::web_vars_get_num_name = 2

CORBA_char_nodup *
blade_web_vars_get_num_name_nodup(blade, number)
	BLADEENV blade
	int number
	ALIAS:
		BLADE::blade_web_vars_get_num_name_nodup = 1
		BLADEENV::web_vars_get_num_name_nodup = 2

int
blade_auth(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_auth = 1
		BLADEENV::auth = 2

CORBA_char *
blade_return_buffer(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_return_buffer = 1
		BLADEENV::return_buffer = 2

void
blade_destroy(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_destroy = 1
		BLADEENV::destroy = 2
	CODE:
		unregister_blade_run_callback(blade);
		blade_destroy(blade);

void
blade_destroy_no_env(blade)
	BLADEENV blade
	ALIAS:
		BLADE::blade_destroy_no_env = 1
		BLADEENV::destroy_no_env = 2
	CODE:
		unregister_blade_run_callback(blade);
		blade_destroy_no_env(blade);

void
blade_obj(blade, obj_name, name, args, activation_flags, start_args)
	BLADEENV blade
	CORBA_char * obj_name
	CORBA_char * name
	CORBA_char * args
	CORBA_short activation_flags
	CORBA_char * start_args
	ALIAS:
		BLADE::blade_obj = 1
		BLADEENV::obj = 2

void
blade_link_file(blade, name)
	BLADEENV blade
	CORBA_char * name
	ALIAS:
		BLADE::blade_link_file = 1
		BLADEENV::link_file = 2

void
blade_url_decode(string)
	CORBA_char * string

CORBA_char *
blade_url_encode(string)
	CORBA_char * string

void
blade_session_set_var(blade, name, value, temp)
	BLADEENV blade
	CORBA_char * name
	CORBA_char * value
	int temp
	ALIAS:
		BLADE::blade_session_set_var = 1
		BLADEENV::session_set_var = 2

CORBA_char *
blade_session_get_var(blade, name)
	BLADEENV blade
	CORBA_char * name
	ALIAS:
		BLADE::blade_session_get_var = 1
		BLADEENV::session_get_var = 2

CORBA_char *
blade_session_get_set(blade, name, temp)
	BLADEENV blade
	CORBA_char * name
	int temp
	ALIAS:
		BLADE::blade_session_get_set = 1
		BLADEENV::session_get_set = 2

void
blade_orb_run()

BLADEENV
blade_page_init(args_ref, context, lang)
	SV * args_ref
	CORBA_char * context
	CORBA_char * lang
	PREINIT:
		int argc;
		char **argv;
	CODE:

	if (args_ref != &PL_sv_undef && (!SvROK(args_ref) || SvTYPE(SvRV(args_ref)) != SVt_PVAV))
		croak("blade_page_init() - first argument must be undef or array ref");

	move_to_argv(args_ref, &argc, &argv);
	RETVAL = blade_page_init(&argc,argv,context,lang);
	move_to_array(args_ref, argc, argv);
	OUTPUT:
		RETVAL


int
blade_run(blade, code, bar_title, page_title, head, right_name, accept_unlisted, data)
	BLADEENV blade
	SV * code
	char * bar_title
	char * page_title
	char * head
	char * right_name
	int accept_unlisted
	SV * data
	ALIAS:
		BLADE::blade_run = 1
		BLADEENV::run = 2
	CODE:
	if (SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV) {
		register_blade_run_callback(blade, SvRV(code), data);
		RETVAL = blade_run(blade,blade_run_wrapper,bar_title,page_title,head,right_name,accept_unlisted, NULL);

	}
	else
		croak("blade_run() - second argument must be a code reference");
	OUTPUT:
		RETVAL

int
blade_obj_simple_init(args_ref, code, data)
	SV * args_ref
	SV * code
	SV * data
	PREINIT:
		int argc;
		char **argv;
	CODE:

	if (SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV) {
		if (args_ref != &PL_sv_undef && (!SvROK(args_ref) || SvTYPE(SvRV(args_ref)) != SVt_PVAV))
			croak("blade_obj_simple_init() - first argument must be undef or array ref");

		move_to_argv(args_ref, &argc, &argv);
		register_blade_obj_simple_init_callback(SvRV(code), data);
		RETVAL = blade_obj_simple_init(&argc,argv,blade_obj_simple_init_wrapper,NULL);
		move_to_array(args_ref, argc, argv);

	}
	else
		croak("blade_obj_simple_init() - second argument must be a code reference");
	OUTPUT:
		RETVAL

int
blade_theme_simple_init(args_ref, start_code, end_code, init_code, data)
	SV * args_ref
	SV * start_code
	SV * end_code
	SV * init_code
	SV * data
	PREINIT:
		int argc;
		char **argv;
	CODE:

	if ( SvROK(start_code) && SvTYPE(SvRV(start_code)) == SVt_PVCV &&
	     SvROK(end_code) && SvTYPE(SvRV(end_code)) == SVt_PVCV &&
	     SvROK(init_code) && SvTYPE(SvRV(init_code)) == SVt_PVCV) {
		if (args_ref != &PL_sv_undef && (!SvROK(args_ref) || SvTYPE(SvRV(args_ref)) != SVt_PVAV))
			croak("blade_theme_simple_init() - first argument must be undef or array ref");

		move_to_argv(args_ref, &argc, &argv);
		register_blade_theme_simple_init_callbacks(SvRV(start_code), SvRV(end_code), SvRV(init_code), data);
		RETVAL = blade_theme_simple_init(&argc,argv,
		   blade_theme_simple_init_start_wrapper,
		   blade_theme_simple_init_end_wrapper,
		   blade_theme_simple_init_init_wrapper,
		   NULL
		);
		move_to_array(args_ref, argc, argv);

	}
	else
		croak("blade_theme_simple_init() - second, third and fourth arguments must be code references");
	OUTPUT:
		RETVAL

void
blade_page(args_ref, body_code, init_code, halt_code, bar_title, page_title, head, right_name, accept_unlisted, context, lang, data)
	SV * args_ref
	SV * body_code
	SV * init_code
	SV * halt_code
	char * bar_title
	char * page_title
	char * head
	char * right_name
	int accept_unlisted
	char * context
	char * lang
	SV * data
	PREINIT:
		int argc;
		char **argv;
	CODE:

	if ( SvROK(body_code) && SvTYPE(SvRV(body_code)) == SVt_PVCV &&
	     SvROK(init_code) && SvTYPE(SvRV(init_code)) == SVt_PVCV &&
	     SvROK(halt_code) && SvTYPE(SvRV(halt_code)) == SVt_PVCV) {
		if (args_ref != &PL_sv_undef && (!SvROK(args_ref) || SvTYPE(SvRV(args_ref)) != SVt_PVAV))
			croak("blade_page() - first argument must be undef or array ref");

		move_to_argv(args_ref, &argc, &argv);
		register_blade_page_callbacks(SvRV(body_code), SvRV(init_code), SvRV(halt_code), data);
		blade_page(&argc,argv,
		   blade_page_body_wrapper,
		   blade_page_init_wrapper,
		   blade_page_halt_wrapper,
		   bar_title, page_title, head, right_name, accept_unlisted, context, lang,
		   NULL
		);
		move_to_array(args_ref, argc, argv);

	}
	else
		croak("blade_page() - second, third and fourth arguments must be code references");

int
blade_accept()


MODULE = BLADE  	PACKAGE = BLADEENV

BLADEHASH
links(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->links;
	OUTPUT:
		RETVAL

BLADEHASH
colors(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->colors;
	OUTPUT:
		RETVAL

BLADEHASH
tags(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->tags;
	OUTPUT:
		RETVAL

BLADEHASH
web_vars(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->web_vars;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
web_root(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->web_root;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
header(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->header;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
sysconfdir(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->sysconfdir;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
bladeconfdir(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->bladeconfdir;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
web_page_name(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->web_page_name;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
page_name(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->page_name;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
web_context(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->web_context;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
user(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->user;
	OUTPUT:
		RETVAL

CORBA_char_nodup *
passwd(blade)
	BLADEENV blade
	CODE:
		RETVAL = blade->passwd;
	OUTPUT:
		RETVAL
