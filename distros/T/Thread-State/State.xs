#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef USE_ITHREADS

#ifndef WIN32
    #include <pthread.h>
#endif

/* from threasd.xs  */

/* Values for 'state' member (CPAN threads) */
#define PERL_ITHR_JOINABLE      0
#define PERL_ITHR_DETACHED      1
#define PERL_ITHR_JOINED        2
#define PERL_ITHR_FINISHED      4


/* perl core threads <= 5.8.8 */
typedef struct ithread_s {
    struct ithread_s *next;	/* Next thread in the list */
    struct ithread_s *prev;	/* Prev thread in the list */
    PerlInterpreter *interp;	/* The threads interpreter */
    I32 tid;              	/* Threads module's thread id */
    perl_mutex mutex; 		/* Mutex for updating things in this struct */
    I32 count;			/* How many SVs have a reference to us */
    signed char state;		/* Are we detached ? */
    int gimme;			/* Context of create */
    SV* init_function;          /* Code to run */
    SV* params;                 /* Args to pass function */
#ifdef WIN32
	DWORD	thr;            /* OS's idea if thread id */
	HANDLE handle;          /* OS's waitable handle */
#else
  	pthread_t thr;          /* OS's handle for the thread */
#endif
} ithread;


/* From CPAN threads 1.11 >>>> this typedef was removed */

/* From CPAN threads 1.23 */
typedef struct _ithread {
    struct _ithread *next;      /* Next thread in the list */
    struct _ithread *prev;      /* Prev thread in the list */
    PerlInterpreter *interp;    /* The threads interpreter */
    UV tid;                     /* Threads module's thread id */
    perl_mutex mutex;           /* Mutex for updating things in this struct */
    int count;                  /* How many SVs have a reference to us */
    int state;                  /* Detached, joined, finished, etc. */
    int gimme;                  /* Context of create */
    SV *init_function;          /* Code to run */
    SV *params;                 /* Args to pass function */
#ifdef WIN32
    DWORD  thr;                 /* OS's idea if thread id */
    HANDLE handle;              /* OS's waitable handle */
#else
    pthread_t thr;              /* OS's handle for the thread */
#endif
    IV stack_size;
} ithread2;



NV threads_version;   /* current used threads version */
NV perl_version;      /* joined status for 5.8.0 Win32 */

#define state_is_joined(thread)     ithread_state_is_joined(aTHX_ thread)
#define state_is_finished(thread)   ithread_state_is_finished(aTHX_ thread)
#define state__is_detached(thread)  ithread_state_is_detached(aTHX_ thread)
#define state__is_running(thread)   ithread_state_is_running(aTHX_ thread)
#define state__is_joinable(thread)  ithread_state_is_joinable(aTHX_ thread)
#define state__wantarray(thread)    ithread_state_wantarray(aTHX_ thread)
#define state_coderef(thread)       ithread_state_coderef(aTHX_ thread)
#define state_is_not_joined_nor_detached(thread) \
	                                ithread_state_is_not_joined_nor_detached(aTHX_ thread)


#define THREADS_IS_NEW      (threads_version > 1.23)
#define JOIN_HAS_PROBLEM    (perl_version < 5.008001)

#define ITHREAD_OLD         ((ithread*)thread)
#define ITHREAD_NEW         ((ithread2*)thread)

#define ITHREAD_STATE_IS( state )               \
    (THREADS_IS_NEW ?                           \
          ithread2_state_is(aTHX_ sv, state)    \
        : ithread_state_is(aTHX_ sv, state)     \
    )                                           \

#define FIX_580_JOINED(sv)   state_is_joined_fiexd_580 (aTHX_ sv)



void* state_get_current_ithread (pTHX) {
    void*  thread;
    SV*    thr_sv;
    int    count;

    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSVpv("threads", 0)));
    PUTBACK;
    count = call_method("self", G_SCALAR);

    SPAGAIN;

    if (count != 1)
       croak("%s\n","Internal error, couldn't call thread->self");

    thr_sv = POPs;

    if (THREADS_IS_NEW) {
        thread = (void*)(INT2PTR(ithread2*, SvIV(SvRV(thr_sv))));
    }
    else {
        thread = (void*)(INT2PTR(ithread*, SvIV(SvRV(thr_sv))));
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return thread;
}


void* state_sv_to_ithread(pTHX_ SV *sv) {
    void* thread = !SvROK(sv) ? state_get_current_ithread(aTHX) :
                    THREADS_IS_NEW ?
                           (void*)INT2PTR(ithread2*, SvIV(SvRV(sv)))
                         : (void*)INT2PTR(ithread*, SvIV(SvRV(sv)))
    ;
    return thread;
}


int ithread_state_is (pTHX_ SV* sv, signed char state) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);
    return (ITHREAD_OLD->state & state) ? 1 : 0;
}


int ithread2_state_is (pTHX_ SV* sv, int state) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);
    return (ITHREAD_NEW->state & state) ? 1 : 0;
}


int state_is_joined_fiexd_580 (pTHX_ SV* sv) {
    if( !ITHREAD_STATE_IS( PERL_ITHR_JOINED ) ){
        void*  thread = state_sv_to_ithread(aTHX_ sv);
        return !((ithread*)thread)->interp;
    }
    else {
        return 1;
    }
}


int ithread_state_is_running (pTHX_ SV* sv) {
    return ! ITHREAD_STATE_IS(PERL_ITHR_FINISHED);
}


int ithread_state_is_finished (pTHX_ SV* sv) {
    return ITHREAD_STATE_IS( PERL_ITHR_FINISHED );
}


int ithread_state_is_detached (pTHX_ SV* sv) {
    return ITHREAD_STATE_IS( PERL_ITHR_DETACHED );
}


int ithread_state_is_joined (pTHX_ SV* sv) {
    if (JOIN_HAS_PROBLEM && !THREADS_IS_NEW) {
        return FIX_580_JOINED(sv);
    }
    return ITHREAD_STATE_IS( PERL_ITHR_JOINED );
}


int ithread_state_is_joinable (pTHX_ SV* sv) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);

    if (THREADS_IS_NEW) {
        return ( (ITHREAD_NEW->state & PERL_ITHR_FINISHED)
        			 && !(ITHREAD_NEW->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)) );
    }
    else if (JOIN_HAS_PROBLEM) {
        return ( (ITHREAD_OLD->state & PERL_ITHR_FINISHED)
        			&& !((ITHREAD_OLD->state & PERL_ITHR_DETACHED) || FIX_580_JOINED(sv)) );
    }
    else {
        return ( (ITHREAD_OLD->state & PERL_ITHR_FINISHED)
                     && !(ITHREAD_OLD->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED)) );
    }
}


int ithread_state_is_not_joined_nor_detached (pTHX_ SV* sv) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);

    if (THREADS_IS_NEW) {
        return !(ITHREAD_NEW->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED));
    }
    else if (JOIN_HAS_PROBLEM) {
        return !((ITHREAD_OLD->state & PERL_ITHR_DETACHED) || FIX_580_JOINED(sv));
    }
    else {
        return !(ITHREAD_OLD->state & (PERL_ITHR_DETACHED|PERL_ITHR_JOINED));
    }
}


SV* ithread_state_wantarray (pTHX_ SV* sv) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);
    int    gimme
              = THREADS_IS_NEW ? ITHREAD_NEW->gimme
                             : ITHREAD_OLD->gimme
    ;

    return   gimme & G_VOID  ? &PL_sv_undef
           : gimme & G_ARRAY ? &PL_sv_yes
           : &PL_sv_no  // but this isn't G_SCALAR?
    ;
}


SV* ithread_state_coderef (pTHX_ SV* sv) {
    void*  thread  = state_sv_to_ithread(aTHX_ sv);
    SV*    coderef = THREADS_IS_NEW
                   ? ITHREAD_NEW->init_function
                   : ITHREAD_OLD->init_function
    ;

    if (coderef && SvREFCNT(coderef)) {
        SvREFCNT_inc(coderef);
        return coderef;
    }
    else {
        return &PL_sv_undef;
    }
}


/* accessors to thread priority */

SV* ithread_state_get_priority (pTHX_ SV* sv) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);
#ifdef WIN32
    HANDLE thr = THREADS_IS_NEW ? ITHREAD_NEW->handle : ITHREAD_OLD->handle;

    if (thr) {
        int priority = GetThreadPriority(thr);
        if (priority == THREAD_PRIORITY_ERROR_RETURN){
            return &PL_sv_undef;
        }
        return newSViv(priority);
    }
    else {
        return &PL_sv_undef;
    }
#else
    struct sched_param param;
    int  policy;
    int  priority;

    pthread_t thr = THREADS_IS_NEW ? ITHREAD_NEW->thr : ITHREAD_OLD->thr;

    if ( pthread_getschedparam(thr, &policy, &param) ){
        return &PL_sv_undef;
    }
    return newSViv(param.sched_priority);
#endif
}


SV* ithread_state_set_priority (pTHX_ SV* sv, int priority) {
    void*  thread = state_sv_to_ithread(aTHX_ sv);
    int    old_p;
#ifdef WIN32
    HANDLE thr = THREADS_IS_NEW ? ITHREAD_NEW->handle : ITHREAD_OLD->handle;

    if (thr) {
        old_p = GetThreadPriority(thr);
        if ( SetThreadPriority(thr, priority) ){
            return newSViv(old_p);
        }
        else {
            return &PL_sv_undef;
        }
    }
    else {
        return &PL_sv_undef;
    }
#else
    struct sched_param param;
    int  policy;

    pthread_t thr = THREADS_IS_NEW ? ITHREAD_NEW->thr : ITHREAD_OLD->thr;

    if ( pthread_getschedparam(thr, &policy, &param) ) {
        return &PL_sv_undef;
    }

    old_p = param.sched_priority;

    param.sched_priority = priority;

    if (pthread_setschedparam(thr, policy, &param)) {
        return &PL_sv_undef;
    }
    return newSViv(old_p);
#endif
}


#endif /* USE_ITHREADS */



MODULE = Thread::State	PACKAGE = threads	PREFIX = state_	

PROTOTYPES: DISABLE

#ifdef USE_ITHREADS

int
state__is_running (obj)
	SV* obj

int
state_is_finished (obj)
	SV* obj

int
state__is_detached (obj)
	SV* obj

int
state_is_joined (obj)
	SV* obj

int
state__is_joinable (obj)
	SV* obj

int
state_is_not_joined_nor_detached (obj)
	SV* obj

SV*
state__wantarray (obj)
	SV* obj

SV*
state_coderef (obj)
	SV* obj

SV*
state_priority (obj, ...)
	SV* obj
PREINIT:
    int priority;
    SV* ret;
CODE:
    if (items > 1) {
        priority = SvIV(ST(1));
        ret      = ithread_state_set_priority(aTHX_ obj, priority);
    }
    else {
        ret = ithread_state_get_priority(aTHX_ obj);
    }
    RETVAL = ret;
OUTPUT:
    RETVAL


#endif /* USE_ITHREADS */

BOOT:
{
#ifdef USE_ITHREADS
    /* check threads VERSION for CPAN version */

    HV*  stash;
    HV*  mains;
    SV** svp;

    stash = gv_stashpv("threads", 0);
    mains = gv_stashpv("main", 0);

    svp   = hv_fetch(mains, "]", 1, 0);
    if ( svp && SvNOK(GvSV(*svp)) ){
        perl_version = SvNV(GvSV(*svp));
    }

    if (stash) {
        svp = hv_fetch(stash, "VERSION", 7, 0);
        if ( svp && SvOK(GvSV(*svp)) ){
            threads_version = SvNV(GvSV(*svp));
        }
    }

    if (!threads_version) {
        croak("You must use threads before using Thread::State.");
    }
    else if (threads_version > 1.07 && threads_version < 1.23) {
        croak("Thread::State requires CORE threads or CPAN threads version >= 1.23.");
    }
#endif /* USE_ITHREADS */
}
