#define SAVEPVN(p,n) ((p) ? savepvn(p,n) : NULL)

START_EXTERN_C
EXTERN_C const regexp_engine lpeg_engine;
EXTERN_C REGEXP * LPEG_comp(pTHX_ const SV const *, const U32);
EXTERN_C I32      LPEG_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, I32, SV *, void *, U32);
EXTERN_C char *   LPEG_intuit(pTHX_ REGEXP * const, SV *, char *,
                                char *, U32, re_scream_pos_data *);
EXTERN_C SV *     LPEG_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     LPEG_free(pTHX_ REGEXP * const);
/* No numbered/named buff callbacks */
EXTERN_C SV *     LPEG_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   LPEG_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
END_EXTERN_C


const regexp_engine lpeg_engine = {
    LPEG_comp,
    LPEG_exec,
    LPEG_intuit,
    LPEG_checkstr,
    LPEG_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    LPEG_package,
#if defined(USE_ITHREADS)
    LPEG_dupe,
#endif
};
