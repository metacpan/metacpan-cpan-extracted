#include "libregexp/regcomp.h" /* NSUBEXP */

#define SAVEPVN(p,n) ((p) ? savepvn(p,n) : NULL)

START_EXTERN_C
EXTERN_C const regexp_engine engine_plan9;
EXTERN_C REGEXP * Plan9_comp(pTHX_ const SV const *, const U32);
EXTERN_C I32      Plan9_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, I32, SV *, void *, U32);
EXTERN_C char *   Plan9_intuit(pTHX_ REGEXP * const, SV *, char *,
                                char *, U32, re_scream_pos_data *);
EXTERN_C SV *     Plan9_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     Plan9_free(pTHX_ REGEXP * const);
/* No numbered/named buff callbacks */
EXTERN_C SV *     Plan9_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   Plan9_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
END_EXTERN_C

const regexp_engine engine_plan9 = {
    Plan9_comp,
    Plan9_exec,
    Plan9_intuit,
    Plan9_checkstr,
    Plan9_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    Plan9_package,
#if defined(USE_ITHREADS)        
    Plan9_dupe,
#endif
};
