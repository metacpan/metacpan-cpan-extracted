#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)

#if PERL_VERSION < 12
#define SVt_REGEXP SVt_PVMG
#endif

START_EXTERN_C
EXTERN_C const regexp_engine pcre2_engine;
#if PERL_VERSION < 12
EXTERN_C REGEXP * PCRE2_comp(pTHX_ const SV * const, const U32);
#else
EXTERN_C REGEXP * PCRE2_comp(pTHX_ SV * const, U32);
#endif
#if PERL_VERSION < 20
EXTERN_C I32      PCRE2_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, I32, SV *, void *, U32);
EXTERN_C char *   PCRE2_intuit(pTHX_ REGEXP * const, SV *,
                               char *, char *, const U32, re_scream_pos_data *);
#else
EXTERN_C I32      PCRE2_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, SSize_t, SV *, void *, U32);
EXTERN_C char *   PCRE2_intuit(pTHX_ REGEXP * const, SV *, const char *,
                               char *, char *, U32, re_scream_pos_data *);
#endif
EXTERN_C SV *     PCRE2_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     PCRE2_free(pTHX_ REGEXP * const);
/* No numbered/named buff callbacks */
EXTERN_C SV *     PCRE2_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   PCRE2_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
#if PERL_VERSION >= 18
EXTERN_C REGEXP*  PCRE2_op_comp(pTHX_ SV ** const patternp, int pat_count,
                                OP *expr, const struct regexp_engine* eng,
                                REGEXP *old_re,
                                bool *is_bare_re, U32 orig_rx_flags, U32 pm_flags);
#endif
END_EXTERN_C

void PCRE2_make_nametable(regexp * const, pcre2_code * const, const I32);

const regexp_engine pcre2_engine = {
    PCRE2_comp,
    PCRE2_exec,
    PCRE2_intuit,
    PCRE2_checkstr,
    PCRE2_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    PCRE2_package,
#if defined(USE_ITHREADS)        
    PCRE2_dupe,
#endif
#if PERL_VERSION >= 18
    PCRE2_op_comp,
#endif
};

struct re_engine_pcre2_data {
    pcre2_code *ri;
    pcre2_match_data *match_data;
};
