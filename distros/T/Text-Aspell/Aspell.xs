#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <aspell.h>

#define MAX_ERRSTR_LEN 1000

typedef struct {
    AspellCanHaveError  *ret;
    AspellSpeller       *speller;
    AspellConfig        *config;
    char                lastError[MAX_ERRSTR_LEN+1];
    int                 errnum;  /* Deprecated  - only returns 0/1 */
} Aspell_object;


static int _create_speller(Aspell_object *self)
{
    AspellCanHaveError *ret;

    ret = new_aspell_speller(self->config);


    if ( (self->errnum = aspell_error_number(ret) ) )
    {
        strncpy(self->lastError, aspell_error_message(ret), MAX_ERRSTR_LEN);
        return 0;
    }


    /* The config is no longer needed (check for errors here?) */
    delete_aspell_config(self->config);
    self->config = NULL;


    self->speller = to_aspell_speller(ret);
    self->config  = aspell_speller_config(self->speller);
    return 1;
}




MODULE = Text::Aspell        PACKAGE = Text::Aspell


# Make sure that we have at least xsubpp version 1.922.
REQUIRE: 1.922

Aspell_object *
new(CLASS)
    char *CLASS
    CODE:
        RETVAL = (Aspell_object*)safemalloc( sizeof( Aspell_object ) );

        if( RETVAL == NULL ){
            warn("unable to malloc Aspell_object");
            XSRETURN_UNDEF;
        }
        memset( RETVAL, 0, sizeof( Aspell_object ) );

        /*  create the configuration */
        RETVAL->config = new_aspell_config();

        /* Set initial default */
        /* 
         * aspell_config_replace(RETVAL->config, "language-tag", "en");
         * default language is 'EN' */

    OUTPUT:
        RETVAL


void
DESTROY(self)
    Aspell_object *self
    CODE:
        if ( self->speller )
            delete_aspell_speller(self->speller);

        safefree( (char*)self );


int
create_speller(self)
    Aspell_object *self
    CODE:
        if ( !_create_speller(self) )
            XSRETURN_UNDEF;

        RETVAL = 1;

    OUTPUT:
        RETVAL

int
print_config(self)
    Aspell_object *self
    PREINIT:
        AspellKeyInfoEnumeration * key_list;
        const AspellKeyInfo * entry;
    CODE:
        key_list = aspell_config_possible_elements( self->config, 0 );

        while ( (entry = aspell_key_info_enumeration_next(key_list) ) )
            PerlIO_printf(PerlIO_stdout(),"%20s:  %s\n", entry->name, aspell_config_retrieve(self->config, entry->name) );

        delete_aspell_key_info_enumeration(key_list);


        RETVAL = 1;

    OUTPUT:
        RETVAL


int
set_option(self, tag, val )
    Aspell_object *self
    char *tag
    char *val
    CODE:
        self->lastError[0] = '\0';

        aspell_config_replace(self->config, tag, val );

        if ( (self->errnum = aspell_config_error_number( self->config) ) )
        {
            strcpy(self->lastError, aspell_config_error_message( self->config ) );
            XSRETURN_UNDEF;
        }

        RETVAL = 1;
    OUTPUT:
        RETVAL



int
remove_option(self, tag )
    Aspell_object *self
    char *tag
    CODE:
        self->lastError[0] = '\0';

        aspell_config_remove(self->config, tag );

        if ( (self->errnum = aspell_config_error_number( self->config) ) )
        {
            strcpy(self->lastError, aspell_config_error_message( self->config ) );
            XSRETURN_UNDEF;
        }

        RETVAL = 1;
    OUTPUT:
        RETVAL

char *
get_option(self, val)
    Aspell_object *self
    char *val
    CODE:
        self->lastError[0] = '\0';

        RETVAL = (char *)aspell_config_retrieve(self->config, val);

        if ( (self->errnum = aspell_config_error_number( self->config) ) )
        {
            strcpy(self->lastError, aspell_config_error_message( self->config ) );
            XSRETURN_UNDEF;
        }

    OUTPUT:
        RETVAL

void
get_option_as_list(self, val)
    Aspell_object *self
    char * val

    PREINIT:
        AspellStringList        * lst   = new_aspell_string_list();
        AspellMutableContainer  * lst0  = aspell_string_list_to_mutable_container(lst);
        AspellStringEnumeration * els;
        const char              *option_value;

    PPCODE:
        if (!self->config )
            XSRETURN_UNDEF;

        aspell_config_retrieve_list(self->config, val, lst0);

        if ( (self->errnum = aspell_config_error_number( self->config) ) )
        {
            strncpy(self->lastError, aspell_config_error_message( self->config ), MAX_ERRSTR_LEN);
            delete_aspell_string_list(lst);
            XSRETURN_UNDEF;
        }

        els = aspell_string_list_elements(lst);

        while ( (option_value = aspell_string_enumeration_next(els)) != 0)
            XPUSHs(sv_2mortal(newSVpv( option_value ,0 )));


        delete_aspell_string_enumeration(els);
        delete_aspell_string_list(lst);


char *
errstr(self)
    Aspell_object *self
    CODE:
        RETVAL = (char*) self->lastError;
    OUTPUT:
        RETVAL

int
errnum(self)
    Aspell_object *self
    CODE:
        RETVAL = self->errnum;
    OUTPUT:
        RETVAL


int
check(self,word)
    Aspell_object *self
    char * word
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;

        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;

        RETVAL = aspell_speller_check(self->speller, word, -1);

        if ( aspell_speller_error( self->speller ) )
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message( self->speller ), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

void
suggest(self, word)
    Aspell_object *self
    char * word
    PREINIT:
        const AspellWordList *wl;
        AspellStringEnumeration *els;
        const char *suggestion;
    PPCODE:
        self->lastError[0] = '\0';
        self->errnum = 0;


        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;

        wl = aspell_speller_suggest(self->speller, word, -1);

        if (!wl)
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }



        els = aspell_word_list_elements(wl);


        while ( (suggestion = aspell_string_enumeration_next(els)) )
            XPUSHs(sv_2mortal(newSVpv( suggestion ,0 )));

        delete_aspell_string_enumeration(els);


int
add_to_personal(self,word)
    Aspell_object *self
    char * word
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;

        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_add_to_personal(self->speller, word, -1);

        if ( aspell_speller_error( self->speller ) )
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
add_to_session(self,word)
    Aspell_object *self
    char * word
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;

        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_add_to_session(self->speller, word, -1);

        if ( aspell_speller_error( self->speller ) )
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL



int
store_replacement(self,word,replacement)
    Aspell_object *self
    char * word
    char * replacement
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;

        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_store_replacement(self->speller, word, -1, replacement, -1);

        if ( aspell_speller_error( self->speller ) )
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
save_all_word_lists(self)
    Aspell_object *self
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;

        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_save_all_word_lists(self->speller);

        if ( aspell_speller_error( self->speller ) )
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

int
clear_session(self)
    Aspell_object *self
    CODE:
        self->lastError[0] = '\0';
        self->errnum = 0;

        if (!self->speller && !_create_speller(self) )
            XSRETURN_UNDEF;


        RETVAL = aspell_speller_clear_session(self->speller);

        if ( aspell_speller_error( self->speller ) )
        {
            self->errnum = aspell_speller_error_number( self->speller );
            strncpy(self->lastError, aspell_speller_error_message(self->speller), MAX_ERRSTR_LEN);
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL


void
list_dictionaries(self)
    Aspell_object *self
    PREINIT:
        AspellDictInfoList * dlist;
        AspellDictInfoEnumeration * dels;
        const AspellDictInfo * entry;
    PPCODE:
        if (!self->config )
            XSRETURN_UNDEF;


        dlist = get_aspell_dict_info_list(self->config);
        dels = aspell_dict_info_list_elements(dlist);

        while ( (entry = aspell_dict_info_enumeration_next(dels)) != 0)
        {
            int  len;
            char *dictname;

            len = strlen( entry->name ) +
                  strlen( entry->jargon ) +
                  strlen( entry->code ) +
                  strlen( entry->size_str ) +
                  strlen( entry->module->name ) + 4;


            dictname = (char *)safemalloc( len + 1 );
            sprintf( dictname, "%s:%s:%s:%s:%s", entry->name, entry->code, entry->jargon, entry->size_str, entry->module->name );

            PUSHs(sv_2mortal(newSVpv( dictname ,0 )));
            safefree( dictname );
        }

        delete_aspell_dict_info_enumeration(dels);


void
dictionary_info(self)
        Aspell_object *self;
    PREINIT:
        AspellDictInfoList *dlist;
        AspellDictInfoEnumeration *dels;
        const AspellDictInfo *entry;
    PPCODE:

        if (!self->config )  /* type map should catch this error, I'd think */
            XSRETURN_UNDEF;


        dlist = get_aspell_dict_info_list(self->config);
        dels = aspell_dict_info_list_elements(dlist);

        while ( (entry = aspell_dict_info_enumeration_next(dels)) != 0)
        {
            HV * dict_entry = newHV();

            if ( entry->name[0] )
                hv_store(dict_entry, "name",  4, newSVpv(entry->name,0),0);

            if ( entry->jargon[0] )
                hv_store(dict_entry, "jargon",6, newSVpv(entry->jargon,0),0);

            if ( entry->code[0] )
                hv_store(dict_entry, "code",  4, newSVpv(entry->code,0),0);

            if ( entry->code )
                hv_store(dict_entry, "size",  4, newSViv(entry->size),0);

            if ( entry->module->name[0] )
                hv_store(dict_entry, "module",6, newSVpv(entry->module->name,0),0);

            XPUSHs(sv_2mortal(newRV_noinc((SV*)dict_entry)));

        }

        delete_aspell_dict_info_enumeration(dels);


SV *
fetch_option_keys(self)
        Aspell_object *self;

    PREINIT:
        AspellKeyInfoEnumeration * key_list;
        const AspellKeyInfo * entry;
        HV * option_hash;

    CODE:
        key_list = aspell_config_possible_elements( self->config, 0 );

        option_hash = newHV();

        while ( (entry = aspell_key_info_enumeration_next(key_list) ) )
        {
            HV * KeyInfo = newHV();

            hv_store(KeyInfo, "type",  4, newSViv((int)entry->type),0);

            if ( entry->def && entry->def[0] )
                hv_store(KeyInfo, "default", 7, newSVpv(entry->def,0),0);

            if ( entry->desc && entry->desc[0] )
                hv_store(KeyInfo, "desc",4, newSVpv(entry->desc,0),0);

            hv_store(option_hash, entry->name, strlen(entry->name), newRV_noinc((SV *)KeyInfo),0);
        }

        delete_aspell_key_info_enumeration(key_list);

        RETVAL = newRV_noinc((SV *)option_hash);

    OUTPUT:
        RETVAL


