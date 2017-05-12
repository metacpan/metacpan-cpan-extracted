#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)

START_EXTERN_C
EXTERN_C const regexp_engine pcre_engine;
EXTERN_C REGEXP * PCRE_comp(pTHX_ const SV const *, const U32);
EXTERN_C I32      PCRE_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, I32, SV *, void *, U32);
EXTERN_C char *   PCRE_intuit(pTHX_ REGEXP * const, SV *, char *,
                                char *, U32, re_scream_pos_data *);
EXTERN_C SV *     PCRE_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     PCRE_free(pTHX_ REGEXP * const);
/* No numbered/named buff callbacks */
EXTERN_C SV *     PCRE_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   PCRE_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
END_EXTERN_C

void PCRE_make_nametable(regexp * const, pcre * const, const int);

const regexp_engine pcre_engine = {
    PCRE_comp,
    PCRE_exec,
    PCRE_intuit,
    PCRE_checkstr,
    PCRE_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    PCRE_package,
#if defined(USE_ITHREADS)        
    PCRE_dupe,
#endif
};
