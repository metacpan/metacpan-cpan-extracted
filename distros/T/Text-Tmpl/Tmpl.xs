#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "template.h"
#include "perl_tags.h"

MODULE = Text::Tmpl PACKAGE = Text::Tmpl PREFIX = template_
PROTOTYPES: ENABLE

context_p
template_init()
	PREINIT:
		char *CLASS = NULL;
		MAGIC *mg   = NULL;
	CLEANUP:
		mg = mg_find(SvRV(ST(0)), '~');
		mg->mg_len = 1;

int
template_set_delimiters(ctx, opentag, closetag)
	context_p	ctx
	char *		opentag
	char *		closetag
	PREINIT:
		char *CLASS = NULL;

void
template_set_debug(ctx, debug_level)
	context_p	ctx
	int		debug_level
	PREINIT:
		char *CLASS = NULL;

void
template_set_strip(ctx, strip)
	context_p	ctx
	int		strip
	PREINIT:
		char *CLASS = NULL;

int
template_set_dir(ctx, directory)
	context_p	ctx
	char *		directory
	PREINIT:
		char *CLASS = NULL;

int
template_set_value(ctx, name, value)
	context_p	ctx
	char *		name
	char *		value
	PREINIT:
		char *CLASS = NULL;

char *
template_strerror()

int
template_errno()
	CODE:
		RETVAL = template_errno;
	OUTPUT:
		RETVAL

void
template_DESTROY(ctx)
	context_p	ctx
	PREINIT:
		char *CLASS      = NULL;
		MAGIC *mg        = mg_find(SvRV(ST(0)), '~');
		int  destroyme   = mg->mg_len;
	CODE:
		if (destroyme)
		{
		    template_destroy(ctx);
		    mg->mg_len = 0;
		}

context_p
template_loop_iteration(ctx, loop_name)
	context_p	ctx
	SV *	loop_name
	PREINIT:
		char *CLASS = NULL;
		char *r_loop_name = NULL;
	INIT:
		if (loop_name == &PL_sv_undef)
		{
		    XSRETURN_UNDEF;
		}
		r_loop_name = (char *)SvPV(loop_name, PL_na);
	CODE:
		RETVAL = template_loop_iteration(ctx, r_loop_name);
	OUTPUT:
		RETVAL

context_p
template_fetch_loop_iteration(ctx, loop_name, iteration)
	context_p	ctx
	SV *		loop_name
	SV *		iteration
	PREINIT:
		char *CLASS       = NULL;
		char *r_loop_name = NULL;
		int  r_iteration  = -1;
	INIT:
		if (loop_name == &PL_sv_undef)
		{
		    XSRETURN_UNDEF;
		}
		if (iteration == &PL_sv_undef)
		{
		    XSRETURN_UNDEF;
		}
		r_loop_name = (char *)SvPV(loop_name, PL_na);
		r_iteration = SvIV(iteration);
	CODE:
		RETVAL = template_fetch_loop_iteration(ctx, r_loop_name,
		                                       r_iteration);
	OUTPUT:
		RETVAL

SV *
template_parse_file(ctx, template_filename)
	context_p	ctx
	SV *		template_filename
        PREINIT:
		char *CLASS = NULL;
		char *output = NULL;
		char *r_template_filename = NULL;
	INIT:
		if (template_filename == &PL_sv_undef)
		{
		    XSRETURN_UNDEF;
		}
		r_template_filename = (char *)SvPV(template_filename, PL_na);
	CODE:
		template_parse_file(ctx, r_template_filename, &output);
                if (output != NULL)
		{
                    RETVAL = newSVpv(output, strlen(output));
                    template_free_output(output);
                }
		else
		{
                    XSRETURN_UNDEF;
                }
	OUTPUT:
		RETVAL

SV *
template_parse_string(ctx, template)
	context_p	ctx
	SV *		template
	PREINIT:
		char *CLASS = NULL;
		char *output = NULL;
		char *r_template = NULL;
	INIT:
		if (template == &PL_sv_undef)
		{
		    XSRETURN_UNDEF;
		}
		r_template = (char *)SvPV(template, PL_na);
	CODE:
		template_parse_string(ctx, r_template, &output);
                if (output != NULL)
		{
                    RETVAL = newSVpv(output, strlen(output));
                    template_free_output(output);
                }
		else
		{
                    XSRETURN_UNDEF;
                }
	OUTPUT:
		RETVAL

int
template_register_simple(ctx, name, code)
	context_p	ctx
	char *		name
	CV *		code
	PREINIT:
		char *CLASS = NULL;
		HV *stags;
		HV *perl_simple_tags = perl_get_hv(PERL_TAGS_SIMPLE_TAG_HASH,
                                                   TRUE);
		char key[20];
	INIT:
		snprintf(key, 20, "%p", context_root(ctx));

		if (hv_exists(perl_simple_tags, key, strlen(key)))
		{
			stags = (HV *)SvRV(*(hv_fetch(perl_simple_tags, key,
			                              strlen(key), FALSE)));
		}
		else
		{
			stags = newHV();
			hv_store(perl_simple_tags, key, strlen(key),
			         newRV((SV *)stags), 0);
		}
	CODE:
                hv_store(stags, name, strlen(name), newRV((SV*)code), 0);
		RETVAL = template_register_simple(ctx, name, perl_simple_tag);
	OUTPUT:
		RETVAL

int
template_alias_simple(ctx, old_name, new_name)
	context_p	ctx
	char *		old_name
	char *		new_name
	PREINIT:
		char *CLASS = NULL;
		HV *perl_simple_tags = perl_get_hv(PERL_TAGS_SIMPLE_TAG_HASH,
		                                   TRUE);
		SV *cref             = &PL_sv_undef;
		HV *stags            = NULL;
		char key[20];
	INIT:
		snprintf(key, 20, "%p", context_root(ctx));

		if (hv_exists(perl_simple_tags, key, strlen(key)))
		{
			stags = (HV *)SvRV(*(hv_fetch(perl_simple_tags, key,
			                              strlen(key), FALSE)));
			if (hv_exists(stags, old_name, strlen(old_name)))
			{
				cref = *(hv_fetch(stags, old_name,
				                  strlen(old_name), FALSE));
			}
		}
	CODE:
		if ((cref != &PL_sv_undef) && (SvTYPE(SvRV(cref)) == SVt_PVCV))
		{
			CV *code = (CV *)SvRV(cref);
			hv_store(stags, new_name, strlen(new_name),
                                 newRV((SV *)code), 0);
		}
		RETVAL = template_alias_simple(ctx, old_name, new_name);
	OUTPUT:
		RETVAL


void
template_remove_simple(ctx, name)
	context_p	ctx
	char *		name
	PREINIT:
		char *CLASS = NULL;
		HV *perl_simple_tags = perl_get_hv(PERL_TAGS_SIMPLE_TAG_HASH,
		                                   TRUE);
                HV *stags            = NULL;
		char key[20];
	INIT:
		snprintf(key, 20, "%p", context_root(ctx));

		if (hv_exists(perl_simple_tags, key, strlen(key)))
		{
			stags = (HV *)SvRV(*hv_fetch(perl_simple_tags, key,
			                             strlen(key), FALSE));
		}
	CODE:
		if ((stags != NULL)
                 && (hv_exists(stags, name, strlen(name))))
		{
			hv_delete(stags, name, strlen(name), G_DISCARD);
		}
		template_remove_simple(ctx, name);

		

int
template_register_pair(ctx, named_context, open_name, close_name, code)
	context_p	ctx
	int		named_context
	char *		open_name
	char *		close_name
	CV *		code
	PREINIT:
		char *CLASS = NULL;
		HV *tagps;
		HV *perl_tag_pairs = perl_get_hv(PERL_TAGS_TAG_PAIR_HASH, TRUE);
		char key[20];
	INIT:
		snprintf(key, 20, "%p", context_root(ctx));

		if (hv_exists(perl_tag_pairs, key, strlen(key)))
		{
			tagps = (HV *)SvRV(*(hv_fetch(perl_tag_pairs, key,
			                              strlen(key), FALSE)));
		}
		else
		{
			tagps = newHV();
			hv_store(perl_tag_pairs, key, strlen(key),
			         newRV((SV *)tagps), 0);
		}
	CODE:
                hv_store(tagps, open_name, strlen(open_name),
		         newRV((SV*)code), 0);
		RETVAL = template_register_pair(ctx, (char)named_context,
                                                open_name, close_name,
		                                perl_tag_pair);
	OUTPUT:
		RETVAL

int
template_alias_pair(ctx,old_open_name,old_close_name,new_open_name,new_close_name)
	context_p	ctx
	char *		old_open_name
	char *		old_close_name
	char *		new_open_name
	char *		new_close_name
	PREINIT:
		char *CLASS = NULL;
		HV *perl_tag_pairs = perl_get_hv(PERL_TAGS_TAG_PAIR_HASH,
		                                 TRUE);
		SV *cref = &PL_sv_undef;
		HV *tagps = NULL;
		char key[20];
	INIT:
		snprintf(key, 20, "%p", context_root(ctx));

		if (hv_exists(perl_tag_pairs, key, strlen(key)))
		{
			tagps = (HV *)SvRV(*(hv_fetch(perl_tag_pairs, key,
			                              strlen(key), FALSE)));
			if (hv_exists(tagps, old_open_name,
			              strlen(old_open_name)))
			{
				cref = *(hv_fetch(tagps, old_open_name,
				                  strlen(old_open_name), 0));
			}
		}
	CODE:
		if ((cref != &PL_sv_undef) && (SvTYPE(SvRV(cref)) == SVt_PVCV))
		{
			CV *code = (CV *)SvRV(cref);
			hv_store(tagps, new_open_name, strlen(new_open_name),
			         newRV((SV *)code), 0);
		}
		RETVAL = template_alias_pair(ctx, old_open_name,
		                             old_close_name, new_open_name,
		                             new_close_name);
	OUTPUT:
		RETVAL

void
template_remove_pair(ctx, open_name)
        context_p       ctx
        char *          open_name
        PREINIT:
                char *CLASS = NULL;
                HV *perl_tag_pairs = perl_get_hv(PERL_TAGS_TAG_PAIR_HASH, TRUE);
                HV *tagps          = NULL;
                char key[20];
        INIT:
                snprintf(key, 20, "%p", context_root(ctx));

		if (hv_exists(perl_tag_pairs, key, strlen(key)))
		{
			tagps = (HV *)SvRV(*hv_fetch(perl_tag_pairs, key,
			                             strlen(key), FALSE));
		}
        CODE:
                if ((tagps != NULL)
                 && (hv_exists(tagps, open_name, strlen(open_name))))
                {
                        hv_delete(tagps, open_name, strlen(open_name),
                                  G_DISCARD);
                }
                template_remove_pair(ctx, open_name);

char *
context_get_value(ctx, name)
	context_p	ctx
	char *		name
	PREINIT:
		char *CLASS = NULL;

context_p
context_get_anonymous_child(ctx)
	context_p	ctx
	PREINIT:
		char *CLASS = NULL;

context_p
context_get_named_child(ctx, name)
	context_p	ctx
	char *		name
	PREINIT:
		char *CLASS = NULL;

int
context_set_named_child(ctx, name)
	context_p	ctx
	char *		name
	PREINIT:
		char *CLASS = NULL;

context_p
context_add_peer(ctx)
	context_p	ctx
	PREINIT:
		char *CLASS = NULL;

void
context_output_contents(ctx, output_contents)
	context_p	ctx
	int		output_contents
	PREINIT:
		char *CLASS = NULL;
	CODE:
		context_output_contents(ctx, (char)output_contents);
