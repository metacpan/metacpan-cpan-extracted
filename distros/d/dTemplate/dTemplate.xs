/*
 * dTemplate.xs
 * parse method
 *
 * $Id: dTemplate.xs 132 2006-10-21 15:52:44Z dlux $
 * 
 * $URL: http://svn.dlux.hu/public/dTemplate/trunk/dTemplate.xs $
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* consts */

#define INITIAL_CHUNK_SIZE 32
#define TABLE_SEP_CHAR ' '

/* method field constants */

#define FILENAME  0
#define TEXT      1
#define COMPILED  2
#define PARSEHASH 3

#define MALLOC_MAGIC_COOKIE 494

/* string chunk declaration */

typedef struct _StringChunk {
    I32 allocated;
    I32 endpos;
    char *data;
} StringChunk;

static StringChunk* new_StringChunk (I32 size) {
    StringChunk *self;
    Newz(MALLOC_MAGIC_COOKIE, self, 1, StringChunk);
    New(MALLOC_MAGIC_COOKIE, self->data, size+1, char);
    self->allocated = size+1;
    * (self->data) = 0;
    return self;
}

static void append_StringChunk (StringChunk* self, char *data, I32 size) {
    if (self->allocated <= self->endpos + size) {
        int new_alloc = 2 * (self->endpos + size);
        Renew(self->data, new_alloc, char);
	self->allocated = new_alloc;
    }
    Copy(data, self->data + self->endpos, size, char);
    self->endpos += size;
    * (self->data + self->endpos) = 0;
}

static void free_StringChunk (StringChunk* self) {
    Safefree(self->data);
    Safefree(self);
}

#define DO_IF_GET_MAGIC(sv)  if (SvGMAGICAL(sv)) mg_get(sv)

MODULE = dTemplate PACKAGE = dTemplate::Template

void
parse(...)
    PPCODE:
{
    SV* self = ST(0);
    SV** compiledSV;
    AV* array;
    void *variable_invert;
    char *compiled, *walk, *variable_table;
    STRLEN  compiled_len;
    I32 i, number_of_variables, vars_left;
    SV **variable;
    HV *global_parse_hash   = perl_get_hv("dTemplate::parse", TRUE);
    HV *encoder_hash        = perl_get_hv("dTemplate::ENCODERS", TRUE);
    SV *notassigned_mode    = perl_get_sv("dTemplate::NOTASSIGNED_MODE", FALSE);
    SV **local_parse_href;
    HV *local_parse_hash;
    StringChunk *result;
    
    if (!SvROK(self)) XSRETURN_UNDEF; 
    array = (AV*) SvRV(self);

    compiledSV = av_fetch(array, COMPILED, FALSE);
    if (!compiledSV || *compiledSV == &PL_sv_undef) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(self);
        PUTBACK;

        perl_call_method("compile", G_VOID | G_DISCARD );

        FREETMPS;
        LEAVE;
    }

    // Local parse hash
    local_parse_href = av_fetch(array, PARSEHASH, FALSE);
    if (local_parse_href && *local_parse_href != &PL_sv_undef)
        local_parse_hash = (HV*) SvRV(*local_parse_href);
    else
        local_parse_hash = NULL;

    compiledSV = av_fetch(array, COMPILED, 0);
    if (!compiledSV || *compiledSV == &PL_sv_undef) XSRETURN_UNDEF;
    /* silently returns with undef if the retrieve is failed */

    /* get the compiled string */
    walk = compiled = SvPV(*compiledSV, compiled_len);

    /* get the number of variables in this template */
    vars_left = number_of_variables = * ( (I32*) walk );
    walk += sizeof(I32)/sizeof(char);

    /* initializing the parser parameters */
    Newz(1, variable, number_of_variables, SV *);
    variable_table = walk;
    variable_invert = (void *) variable_table + 
        strlen(variable_table) + 1;
    result = new_StringChunk(INITIAL_CHUNK_SIZE);
    walk = (char *) variable_invert + strlen(variable_table) - 1;

    /* parameter processing */

    if (!vars_left) goto param_proc_end;
    for (i=1; i<items; i++) {
        SV *varn;
        char *var, *pos, *prepared_var;
	STRLEN varlen;
        int p;

        varn = ST(i);
        if (SvROK(varn) && (SvTYPE(SvRV(varn)) == SVt_PVHV)) {
            /* hash reference or derived */
            HV *hash = (HV *) SvRV(varn);
            SV **val;
            char *walktable = variable_table + 1;
            int vari;

            for (vari = 0; vari<number_of_variables; vari++) {
                char *nextspace = index(walktable,TABLE_SEP_CHAR);
                if (!variable[vari]) {
                    val = hv_fetch(hash, walktable, 
                        nextspace - walktable, 0);
                    if (val) { /* got one parameter */
                        variable[vari] = *val;
                        DO_IF_GET_MAGIC(variable[vari]);
                        if (! --vars_left) goto param_proc_end;
                    }
                }
                walktable = nextspace + 1;
                /* handling short (1 or 2 char) variables */
                while (*walktable && *walktable == ' ') walktable++;
            }
            continue;
        }

        var = SvPV(varn, varlen);
        New(MALLOC_MAGIC_COOKIE, prepared_var, varlen + 3, char);

        *prepared_var = ' ';
        strncpy(prepared_var + 1, var, varlen);
        *(prepared_var + varlen + 1) = ' ';
        *(prepared_var + varlen + 2) = '\0';

        pos = strstr(variable_table, prepared_var);
        p = pos - variable_table;
        Safefree(prepared_var);

        i++;

        if (pos) {
            int index = * (I32 *) ( ( (char *) variable_invert ) + p );

            if (index>=0 && index <number_of_variables && 
                !variable[index] ) {
                variable[index] = ST(i);
                DO_IF_GET_MAGIC(variable[index]);
                if (! --vars_left) goto param_proc_end;
            }
        }
    }

    {
        SV **val;
        char *walktable = variable_table + 1;
        int vari;

        for (vari = 0; vari<number_of_variables; vari++) {
            char *nextspace = index(walktable,TABLE_SEP_CHAR);
            if (!variable[vari]) {
                val = 0;

                if (local_parse_hash)
                    val = hv_fetch(local_parse_hash, walktable, nextspace - walktable, 0);

                if (!val)
                    val = hv_fetch(global_parse_hash, walktable, nextspace - walktable, 0);

                if (val) { /* got one parameter */
                    variable[vari] = *val;
                    DO_IF_GET_MAGIC(variable[vari]);
                    if (! --vars_left) goto param_proc_end;
                }
            }
            walktable = nextspace + 1;
            /* handling short (1 or 2 char) variables */
            while (*walktable && *walktable == ' ') walktable++;
        }
    }

    
    param_proc_end:

    /* parsing */

    while (1) {
        I32 chunk_text_size = * ((I32 *) walk);
        I32 var_id, full_matched_len;
        SV *parsevar;
        char *full_matched, *variable_path;
        int assigned = 1;

	walk+= sizeof(I32)/sizeof(char);

        append_StringChunk(result, walk, chunk_text_size);

        walk += chunk_text_size;

        if (! *walk) break;  /* last chunk */

        full_matched = walk;
        full_matched_len = strlen(full_matched);
        walk += full_matched_len + 1;

        var_id = * ( (I32 *) walk) ;
	walk+=sizeof(I32)/sizeof(char);

        parsevar = variable[var_id];

        /* Setting a pointer to the variable path */   
        variable_path = walk;
        walk += strlen(variable_path) +1;

        /* walk through the "."-s */
        while (*walk) {
            char *varpart = walk;
            int varlen = strlen(varpart);

            walk += varlen + 1;

            if (parsevar && SvROK(parsevar)) {
                svtype t = SvTYPE(SvRV(parsevar));
                if (t == SVt_PVCV)
                    continue;

                if (t == SVt_PVHV) {
                    HV *hash = (HV *) SvRV(parsevar);
                    SV **newvar = hv_fetch(hash, varpart, varlen, 0);

                    if (newvar) {
                        parsevar = *newvar;
                        DO_IF_GET_MAGIC(parsevar);
                        continue;
                    }
                }
            }
            parsevar = NULL;
        }

        if (!parsevar) { /* variable is not assigned */
            SV **empty_val = hv_fetch(local_parse_hash, "", 0, 0);
            assigned = 0;
            if (empty_val) {
                if (notassigned_mode && SvTRUE(notassigned_mode))
                    assigned = 1;
                parsevar = *empty_val;
                DO_IF_GET_MAGIC(parsevar);
            }
        }

        if (!parsevar) { /* variable is still not assigned */
            SV **empty_val = hv_fetch(global_parse_hash, "", 0, 0);
            assigned = 0;
            if (empty_val) {
                if (notassigned_mode && SvTRUE(notassigned_mode))
                    assigned = 1;
                parsevar = *empty_val;
                DO_IF_GET_MAGIC(parsevar);
            }
        }

        /* processing the returned variable */

        if (parsevar) {
            if (SvROK(parsevar) && SvTYPE(SvRV(parsevar)) == SVt_PVCV) {
                int retvals;
                SV* full_m = sv_2mortal(newSVpv(full_matched, 
                    full_matched_len));
                AV* var_path = newAV();
                SV* var_path_ref = sv_2mortal(newRV_noinc((SV *) var_path));

                while (*variable_path) {
                    int len = strlen(variable_path);
                    av_push(var_path, newSVpv(variable_path, len));
                    variable_path += len + 1;
                }

                {

                    dSP;
                    ENTER;
                    SAVETMPS;
                    PUSHMARK(SP);
                    XPUSHs(full_m);
                    XPUSHs(var_path_ref);
                    XPUSHs(self);
                    PUTBACK;
                    
                    retvals = perl_call_sv( parsevar, G_SCALAR );

                    SPAGAIN;

                    if (retvals == 1) {
                        parsevar = SvREFCNT_inc(POPs);
                        DO_IF_GET_MAGIC(parsevar);
                    }

                    PUTBACK;
                    FREETMPS;
                    LEAVE;

                    if (retvals == 1)
                        sv_2mortal(parsevar);

                }
            }
        }

        walk++; /* start with the encoders */

        while (*walk) {
            char *encoder_name = walk, *encoder_param;
            int encoder_len = strlen(encoder_name), encoder_param_len;
            SV **encoder = hv_fetch(encoder_hash, encoder_name, 
                encoder_len, 0);

            // if (parsevar)
            //    printf("Parsevar: %s\n", SvPV_nolen(parsevar));
            // fprintf(stderr, "Encoder name: %s\n", encoder_name);
            walk += encoder_len + 1;
            encoder_param = walk;
            encoder_param_len = strlen(encoder_param);
            walk += encoder_param_len + 1;
            if (assigned && parsevar && (encoder != NULL) && 
                (SvTYPE(SvRV(*encoder)) == SVt_PVCV)
            ) {
                int retvals;
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(parsevar);
		        XPUSHs(sv_2mortal(newSVpvn(encoder_param, encoder_param_len)));
                XPUSHs(self);
                PUTBACK;

                retvals = perl_call_sv(*encoder, G_SCALAR);

                SPAGAIN;

                if (retvals == 1) {
                    parsevar = SvREFCNT_inc(POPs);
                    DO_IF_GET_MAGIC(parsevar);
                }

                PUTBACK;
                FREETMPS;
                LEAVE;

                if (retvals == 1)
                    sv_2mortal(parsevar);
            }
        }

        walk++; /* end of encoders */

        if (*walk) { /* printf format string exists */
            char *formatstr = walk;
            int  retvals, formatstr_len = strlen(formatstr);
            SV *printformat = sv_2mortal(
                newSVpv(formatstr, formatstr_len));

            walk += formatstr_len;

            if (parsevar) {
                dSP;
                ENTER;
                SAVETMPS;
                PUSHMARK(SP);
                XPUSHs(printformat);
                XPUSHs(parsevar);
                PUTBACK;

                retvals = perl_call_pv("dTemplate::Template::spf", G_SCALAR );

                SPAGAIN;

                if (retvals == 1)
                    parsevar = SvREFCNT_inc(POPs);

                PUTBACK;
                FREETMPS;
                LEAVE;

                if (retvals == 1)
                    sv_2mortal(parsevar);
            }

        }

        walk++; /* end of printf format string */

        if (parsevar) {
            char *var_string;
            STRLEN var_length;

            var_string = SvPV(parsevar, var_length);
            append_StringChunk(result, var_string, var_length);
        }
    }

    {
        SV *res = sv_2mortal(newSVpvn(result->data, result->endpos));
        free_StringChunk(result);
        ST(0) = res;
        XSRETURN(1);
    }
}

