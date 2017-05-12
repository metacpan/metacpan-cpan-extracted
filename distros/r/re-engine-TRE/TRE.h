#define SAVEPVN(p,n) ((p) ? savepvn(p,n) : NULL)

START_EXTERN_C
EXTERN_C const regexp_engine engine_tre;

EXTERN_C
REGEXP *
TRE_comp(pTHX_
#if PERL_VERSION == 10
    const
#endif
    SV * const, const U32);

EXTERN_C I32      TRE_exec(pTHX_ REGEXP * const, char *, char *,
                           char *, I32, SV *, void *, U32);
EXTERN_C char *   TRE_intuit(pTHX_ REGEXP * const, SV *, char *,
                             char *, U32, re_scream_pos_data *);
EXTERN_C SV *     TRE_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     TRE_free(pTHX_ REGEXP * const);
/* No numbered/named buff callbacks */
EXTERN_C SV *     TRE_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   TRE_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
END_EXTERN_C

char *get_regerror(int, regex_t *);

const regexp_engine engine_tre = {
    TRE_comp,
    TRE_exec,
    TRE_intuit,
    TRE_checkstr,
    TRE_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    TRE_package,
#if defined(USE_ITHREADS)        
    TRE_dupe,
#endif
};
