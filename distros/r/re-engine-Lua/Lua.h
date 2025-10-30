#define SAVEPVN(p,n) ((p) ? savepvn(p,n) : NULL)

START_EXTERN_C
EXTERN_C const regexp_engine lua_engine;
EXTERN_C REGEXP * Lua_comp(pTHX_ SV * const, U32);
#if PERL_VERSION < 20
EXTERN_C I32      Lua_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, I32, SV *, void *, U32);
EXTERN_C char *   Lua_intuit(pTHX_ REGEXP * const, SV *, char *,
                                char *, U32, re_scream_pos_data *);
#else
EXTERN_C I32      Lua_exec(pTHX_ REGEXP * const, char *, char *,
                              char *, SSize_t, SV *, void *, U32);
EXTERN_C char *   Lua_intuit(pTHX_ REGEXP * const, SV *, const char * const, char *,
                                char *, const U32, re_scream_pos_data *);
#endif
EXTERN_C SV *     Lua_checkstr(pTHX_ REGEXP * const);
EXTERN_C void     Lua_free(pTHX_ REGEXP * const);
/* No numbered/named buff callbacks */
EXTERN_C SV *     Lua_package(pTHX_ REGEXP * const);
#ifdef USE_ITHREADS
EXTERN_C void *   Lua_dupe(pTHX_ REGEXP * const, CLONE_PARAMS *);
#endif
END_EXTERN_C


const regexp_engine lua_engine = {
    Lua_comp,
    Lua_exec,
    Lua_intuit,
    Lua_checkstr,
    Lua_free,
    Perl_reg_numbered_buff_fetch,
    Perl_reg_numbered_buff_store,
    Perl_reg_numbered_buff_length,
    Perl_reg_named_buff,
    Perl_reg_named_buff_iter,
    Lua_package,
#if defined(USE_ITHREADS)
    Lua_dupe,
#endif
};
