/* Oniguruma.xs */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "oniguruma.h"

#ifndef RX_WRAPPED
#define RX_WRAPPED(rx) (rx)->wrapped
#define RX_WRAPLEN(rx) (rx)->wraplen
#endif

#ifndef RXp_PAREN_NAMES
#define RXp_PAREN_NAMES(rx) (rx)->paren_names
#endif

#if PERL_VERSION > 10
#define RegSV(sv) ((regexp*)SvANY(sv))
#else
#define RegSV(sv) ((regexp*)sv)
#endif

#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)


STATIC REGEXP *onig_perl_comp( pTHX_ SV * pattern,
                               const U32 flags );
STATIC I32 onig_perl_exec( pTHX_ REGEXP * const rx, char *stringarg,
                           char *strend, char *strbeg, I32 minend, SV * sv,
                           void *data, U32 flags );
STATIC char *onig_perl_intuit( pTHX_ REGEXP * const rx, SV * sv,
                               char *strpos, char *strend, U32 flags,
                               re_scream_pos_data * data );
STATIC SV *onig_perl_checkstr( pTHX_ REGEXP * const rx );
STATIC void onig_perl_free( pTHX_ REGEXP * const rx );
STATIC void *onig_perl_dupe( pTHX_ REGEXP * const rx,
                             CLONE_PARAMS * param );
STATIC SV *onig_perl_package( pTHX_ REGEXP * const rx );

/* This structure describes the regex engine to Perl */

STATIC const regexp_engine onig_engine = {
    onig_perl_comp,
    onig_perl_exec,
    onig_perl_intuit,
    onig_perl_checkstr,
    onig_perl_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    onig_perl_package,
#if defined(USE_ITHREADS)
    onig_perl_dupe,
#endif
};

STATIC int
_build_callback( const UChar * name, const UChar * name_end, int ngroups,
                 int *groups, regex_t * onig, void *handle ) {
    regexp *const rx = (regexp*)handle;
    SV *sv_dat;
    assert(rx);

    sv_dat = *hv_fetch( RXp_PAREN_NAMES(rx),
                ( const char * ) name, name_end - name, TRUE );

    if ( !sv_dat ) {
        croak( "Oniguruma: Failed to allocate paren_names hash" );
    }

    ( void ) SvUPGRADE( sv_dat, SVt_PVNV );

    /* TODO: Assumes sizeof(int) == sizeof(I32) */
    sv_setpvn( sv_dat, ( char * ) groups, sizeof( I32 ) * ngroups );
    SvIOK_on( sv_dat );
    SvIVX( sv_dat ) = ngroups;

    return 0;
}

STATIC void
_build_name_map( regexp * const rx ) {
    regex_t *onig = (regex_t*)rx->pprivate;
    if ( onig_number_of_names( onig ) ) {
        RXp_PAREN_NAMES(rx) = newHV();
        ( void ) onig_foreach_name( onig, _build_callback, rx );
    }
    else {
        RXp_PAREN_NAMES(rx) = NULL;
    }

}

STATIC void
_make_options( const U32 flags, OnigOptionType * option, char *fl_on,
               char *fl_off ) {
    static struct flag_map_ent {
        I32 pflag;
        OnigOptionType oflag;
        int name;
    } flag_map[] = {
        /* *INDENT-OFF* */
        { RXf_PMf_EXTENDED,   ONIG_OPTION_EXTEND,     'x' },
        { RXf_PMf_FOLD,       ONIG_OPTION_IGNORECASE, 'i' },
        { RXf_PMf_SINGLELINE, ONIG_OPTION_SINGLELINE, 's' },
        /* Strange multiline + negate_singleline options have
         * been found empirically to work. Doesn't look right
         * though... */
        { RXf_PMf_MULTILINE,  ONIG_OPTION_MULTILINE
                    | ONIG_OPTION_NEGATE_SINGLELINE,  'm' }
        /* *INDENT-ON* */
    };
    int i;

    *option = ONIG_OPTION_NONE;

    for ( i = 0; i < sizeof( flag_map ) / sizeof( flag_map[0] ); i++ ) {
        if ( flags & flag_map[i].pflag ) {
            *option |= flag_map[i].oflag;
            *fl_on++ = flag_map[i].name;
        }
        else {
            *fl_off++ = flag_map[i].name;
        }
    }

    /* Terminate flags strings */
    *fl_on = '\0';
    *fl_off = '\0';
}

STATIC void
_save_rep( pTHX_ REGEXP * rx, const SV * const pattern, const char *fl_on,
           const char *fl_off ) {
    const char *rep =
        form( "(?%s%s%s:%s)", fl_on, *fl_off ? "-" : "", fl_off,
              SvPV_nolen( ( SV * ) pattern ) );
    I32 const len = (I32)strlen( rep);

    RX_WRAPPED(rx) = savepvn( rep, len );
    RX_WRAPLEN(rx) = len;
}

STATIC REGEXP*
newREGEXP( pTHX ) {
#if PERL_VERSION > 10
    return (REGEXP*)newSV_type(SVt_REGEXP);
#else
    REGEXP* rx;
    Newxz( rx, 1, REGEXP );
    rx->refcnt = 1;
    return rx;
#endif
}

STATIC REGEXP *
onig_perl_comp( pTHX_ SV * const pattern, const U32 flags ) {
    REGEXP *rxsv;
    regexp *rx;
    regex_t *onig;
    STRLEN plen;
    UChar *exp = ( UChar * ) SvPV( ( SV * ) pattern, plen );
    UChar *exp_end = exp + plen;
    U32 extflags = flags;
    OnigOptionType option;
    OnigEncoding enc = ONIG_ENCODING_ASCII;
    OnigSyntaxType *syntax = ONIG_SYNTAX_PERL_NG;
    OnigErrorInfo err;
    int rc, nparens;
    char fl_on[5], fl_off[5];

    // ONIG_OPTION_NONE               no option
    // ONIG_OPTION_SINGLELINE         '^' -> '\A', '$' -> '\Z'
    // ONIG_OPTION_MULTILINE          '.' match with newline
    // ONIG_OPTION_IGNORECASE         ambiguity match on
    // ONIG_OPTION_EXTEND             extended exp form
    // ONIG_OPTION_FIND_LONGEST       find longest match
    // ONIG_OPTION_FIND_NOT_EMPTY     ignore empty match
    // ONIG_OPTION_NEGATE_SINGLELINE
    //       clear ONIG_OPTION_SINGLELINE which is enabled on
    //       ONIG_SYNTAX_POSIX_BASIC, ONIG_SYNTAX_POSIX_EXTENDED,
    //       ONIG_SYNTAX_PERL, ONIG_SYNTAX_PERL_NG, ONIG_SYNTAX_JAVA
    //
    // ONIG_OPTION_DONT_CAPTURE_GROUP only named group captured.
    // ONIG_OPTION_CAPTURE_GROUP      named and no-named group captured.

    if ( plen == 0 ) {
        extflags |= RXf_NULL;
    }
    else if ( flags & RXf_SPLIT && plen == 1 && exp[0] == ' ' ) {
        /* split " " */
        extflags |= ( RXf_SKIPWHITE | RXf_WHITE );
    }
    else if ( plen == 1 && exp[0] == '^' ) {
        /* split /^/ */
        extflags |= RXf_START_ONLY;
    }

    _make_options( flags, &option, fl_on, fl_off );

    /* The pattern is known to be UTF-8. Perl wouldn't turn this on unless it's
     * a valid UTF-8 sequence so tell Oniguruma not to check for that */
    /* if ( flags & RXf_UTF8 )
       option |= ( PCRE_UTF8 | PCRE_NO_UTF8_CHECK ); */

    if ( rc = onig_new( &onig, exp, exp_end,
                        option, enc, syntax, &err ), ONIG_NORMAL != rc ) {
        UChar erbuf[ONIG_MAX_ERROR_MESSAGE_LEN];
        onig_error_code_to_str( erbuf, rc, &err );
        croak( "Oniguruma: %s", erbuf );
    }

    rxsv = newREGEXP(aTHX);
    rx   = RegSV(rxsv);

    rx->extflags = extflags;
    rx->engine = &onig_engine;

    /* Preserve a copy of the original exp */
    _save_rep( aTHX_ rxsv, pattern, fl_on, fl_off );
#if PERL_VERSION >= 11
    rx->pre_prefix = RX_WRAPLEN(rxsv) - plen - 1;
#else
    rx->prelen = ( I32 ) plen;
    rx->precomp = SAVEPVN( ( char * ) exp, plen );
#endif


    /* Store our private object */
    rx->pprivate = onig;

    /* Allocate space for captures */
    nparens = onig_number_of_captures( onig );
    rx->nparens = rx->lastparen = rx->lastcloseparen = nparens;
    Newxz( rx->offs, nparens + 1, regexp_paren_pair );

    /* Build map: names => groups */
    _build_name_map( rx );

    /* return the regexp */
    return rxsv;
}

STATIC I32
onig_perl_exec( pTHX_ REGEXP * const rxsv,
                char *stringarg, char *strend,
                char *strbeg, I32 minend, SV * sv, void *data, U32 flags ) {
    regexp* const rx = RegSV(rxsv);
    regex_t *onig = rx->pprivate;
    OnigOptionType option = ONIG_OPTION_NONE;
    OnigRegion *region = onig_region_new(  );
    int rc, i;
    // fprintf( stderr, "# %p %p %p\n", stringarg, strbeg, strend );
    rc = onig_search( onig, ( const UChar * ) strbeg,
                      ( const UChar * ) strend,
                      ( const UChar * ) stringarg,
                      ( const UChar * ) strend, region, option );
    if ( rc == ONIG_MISMATCH ) {
        onig_region_free( region, 1 );
        return 0;
    }
    else if ( rc < 0 ) {
        UChar erbuf[ONIG_MAX_ERROR_MESSAGE_LEN];
        onig_region_free( region, 1 );
        onig_error_code_to_str( erbuf, rc, NULL );
        croak( "Oniguruma: %s", erbuf );
    }

    rx->subbeg = strbeg;
    rx->sublen = strend - strbeg;
    for ( i = 0; i < region->num_regs; i++ ) {
        /* Copy matches */
        rx->offs[i].start = region->beg[i];
        rx->offs[i].end = region->end[i];
        // fprintf( stderr, "# %3d %p - %p\n", i, region->beg[i],
        //          region->end[i] );
    }

    for ( ; i <= rx->nparens; i++ ) {
        /* Blank remainder */
        rx->offs[i].start = -1;
        rx->offs[i].end = -1;
    }

    onig_region_free( region, 1 );
    return 1;
}

STATIC char *
onig_perl_intuit( pTHX_ REGEXP *
                  const rx, SV * sv,
                  char *strpos,
                  char *strend, U32 flags, re_scream_pos_data * data ) {
    PERL_UNUSED_ARG( rx );
    PERL_UNUSED_ARG( sv );
    PERL_UNUSED_ARG( strpos );
    PERL_UNUSED_ARG( strend );
    PERL_UNUSED_ARG( flags );
    PERL_UNUSED_ARG( data );
    return NULL;
}

STATIC SV *
onig_perl_checkstr( pTHX_ REGEXP * const rx ) {
    PERL_UNUSED_ARG( rx );
    return NULL;
}

STATIC void
onig_perl_free( pTHX_ REGEXP * const rxsv ) {
    /* Safefree( rx->wrapped ); */
    onig_free( RegSV(rxsv)->pprivate );
}

STATIC void *
onig_perl_dupe( pTHX_ REGEXP * const rxsv, CLONE_PARAMS * param ) {
    PERL_UNUSED_ARG( param );
    return RegSV(rxsv)->pprivate;
}

STATIC SV *
onig_perl_package( pTHX_ REGEXP * const rx ) {
    PERL_UNUSED_ARG( rx );
    return newSVpvs( "re::engine::Oniguruma" );
}

/* *INDENT-OFF* */

MODULE = re::engine::Oniguruma  PACKAGE = re::engine::Oniguruma
PROTOTYPES:ENABLE

void
ENGINE( ... )
PROTOTYPE:
PPCODE:
    XPUSHs( sv_2mortal( newSViv( PTR2IV( &onig_engine ) ) ) );
