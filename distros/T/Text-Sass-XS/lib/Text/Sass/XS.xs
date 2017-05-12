#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newCONSTSUB
#define NEED_sv_2pv_flags
#define NEED_newSVpvn_flags
#include "ppport.h"
#include "sass_interface.h"

#define _CONST(name) \
    newCONSTSUB(stash, #name, newSViv(name))

#define hv_store_text_string(hv, key, val) \
    hv_store((hv), (key), strlen((key)), \
          (val) \
        ? newSVpvn_utf8((val), strlen((val)), 1) \
        : &PL_sv_undef, \
        0 );

static int hv_fetch_iv(pTHX_ HV* dict, const char* key) {
    if (!hv_exists(dict, key, strlen(key))) {
        return 0;
    }

    SV** svv = hv_fetch(dict, key, strlen(key), 0);
    if (!SvIOKp(*svv)) {
        Perl_croak(aTHX_ "Error %s is not integer.", key);
    }
    return SvIV(*svv);
}

static char* hv_fetch_pv(pTHX_ HV* dict, const char* key) {
    if (!hv_exists(dict, key, strlen(key))) {
        return NULL;
    }

    SV** svv = hv_fetch(dict, key, strlen(key), 0);
    if (!SvOK(*svv)) {
        return NULL;
    }
    if (!SvPOK(*svv)) {
        Perl_croak(aTHX_ "Error %s is not string.", key);
    }
    return SvPV_nolen(*svv);
}

static void set_options(pTHX_ void* context, HV* options) {
    struct sass_context* ctx = (struct sass_context*) context;
    if ( options == NULL ) {
        const char* empty_string = "";
        struct sass_options default_options = {
            SASS_STYLE_COMPRESSED,
            SASS_SOURCE_COMMENTS_NONE,
            (char*) empty_string,
            (char*) empty_string,
        };
        ctx->options = default_options;
    }
    else {
        ctx->options.output_style    = hv_fetch_iv(aTHX_ options, "output_style");
        ctx->options.source_comments = hv_fetch_iv(aTHX_ options, "source_comments");
        ctx->options.include_paths   = hv_fetch_pv(aTHX_ options, "include_paths");
        ctx->options.image_path      = hv_fetch_pv(aTHX_ options, "image_path");
    }
}

MODULE = Text::Sass::XS    PACKAGE = Text::Sass::XS

PROTOTYPES: DISABLE

BOOT:
{
    HV* stash = gv_stashpv("Text::Sass::XS", 1);

    _CONST(SASS_STYLE_NESTED);
    _CONST(SASS_STYLE_EXPANDED);
//  _CONST(SASS_STYLE_COMPACT);           Not implemented yet.
    _CONST(SASS_STYLE_COMPRESSED);
    _CONST(SASS_SOURCE_COMMENTS_NONE);
    _CONST(SASS_SOURCE_COMMENTS_DEFAULT);
    _CONST(SASS_SOURCE_COMMENTS_MAP);
}

HV*
_compile(source_string, options=NULL)
    const char* source_string;
    HV* options;
PREINIT:
    char* output_string;
    char* error_message;
    struct sass_context* context = sass_new_context();
INIT:
    context->source_string = source_string;
    context->output_string = output_string;
    set_options(aTHX_ context, options);
CODE:
    RETVAL = (HV*)sv_2mortal((SV*)newHV());
    sass_compile(context);
    hv_store_text_string(RETVAL, "output_string", context->output_string);
    hv_store_text_string(RETVAL, "error_message", context->error_message);
    hv_store(RETVAL, "error_status", strlen("error_status"), newSViv(context->error_status), 0);
OUTPUT:
    RETVAL
CLEANUP:
    sass_free_context(context);


HV*
_compile_file(input_path, options=NULL)
    char* input_path;
    HV* options;
PREINIT:
    char* output_string;
    char* error_message;
    struct sass_file_context* context = sass_new_file_context();
INIT:
    context->input_path    = input_path;
    context->output_string = output_string;
    set_options(aTHX_ context, options);
CODE:
    RETVAL = (HV*)sv_2mortal((SV*)newHV());
    sass_compile_file(context);
    hv_store_text_string(RETVAL, "output_string", context->output_string);
    hv_store_text_string(RETVAL, "error_message", context->error_message);
    hv_store(RETVAL, "error_status", strlen("error_status"), newSViv(context->error_status), 0);
OUTPUT:
    RETVAL
CLEANUP:
    sass_free_file_context(context);
