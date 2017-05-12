/* Copyright 2000-2001 ActiveState
 */

#ifdef MULTI_PERL

typedef
struct {
    PerlInterpreter *my_perl;
    U32 refcnt;  /* number of SVRV objects that reference this interpreter */
    bool thread_done;
} refcounted_perl;

typedef
struct {
    refcounted_perl* perl;
    HV* root_stash;
    PyThreadState* last_py_state;
} thread_ctx;

extern void thrd_ctx_init(void);
extern thread_ctx* get_thread_ctx(void);

#define dCTX    thread_ctx* ctx = get_thread_ctx()
#define dCTXP   dCTX; PerlInterpreter *my_perl = ctx->perl->my_perl

#else /* MULTI_PERL */

#define dCTX    dNOOP
#define dCTXP   dTHX

#endif /* MULTI_PERL */
