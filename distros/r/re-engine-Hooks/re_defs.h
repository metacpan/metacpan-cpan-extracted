#ifndef REH_HAS_PERL
# define REH_HAS_PERL(R, V, S) (PERL_REVISION > (R) || (PERL_REVISION == (R) && (PERL_VERSION > (V) || (PERL_VERSION == (V) && (PERL_SUBVERSION >= (S))))))
#endif

EXTERN_C void     reh_save_re_context(pTHX);
EXTERN_C regnode *reh_regnext(pTHX_ register regnode *);
#if REH_HAS_PERL(5, 11, 0)
EXTERN_C REGEXP  *reh_pregcomp(pTHX_ SV * const, const U32);
#else
EXTERN_C REGEXP  *reh_pregcomp(pTHX_ const SV * const, const U32);
#endif
#if REH_HAS_PERL(5, 11, 2)
EXTERN_C REGEXP  *reh_reg_temp_copy(pTHX_ REGEXP *, REGEXP *);
#else
EXTERN_C REGEXP  *reh_reg_temp_copy(pTHX_ REGEXP *);
#endif
#if REH_HAS_PERL(5, 15, 7)
EXTERN_C SV      *reh__invlist_contents(pTHX_ SV* const);
#endif

EXTERN_C const struct regexp_engine reh_regexp_engine;

EXTERN_C void reh_call_comp_begin_hook(pTHX_ regexp *);
EXTERN_C void reh_call_comp_node_hook(pTHX_ regexp *, regnode *);
EXTERN_C void reh_call_exec_node_hook(pTHX_ regexp *, regnode *, regmatch_info *, regmatch_state *);

#define REH_CALL_COMP_BEGIN_HOOK(a)         reh_call_comp_begin_hook(aTHX_ (a))
#define REH_CALL_COMP_NODE_HOOK(a, b)       reh_call_comp_node_hook(aTHX_ (a), (b))
#define REH_CALL_EXEC_NODE_HOOK(a, b, c, d) reh_call_exec_node_hook(aTHX_ (a), (b), (c), (d))

