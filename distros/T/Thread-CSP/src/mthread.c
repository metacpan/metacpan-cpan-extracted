#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#define NO_XSLOCKS
#include "XSUB.h"
#include "ppport.h"

#include "mthread.h"
#include "trycatch.h"
#include "refcount.h"
#include "values.h"

#ifdef WIN32
#  include <windows.h>
#  include <win32thread.h>
#else
#  include <pthread.h>
#  include <thread.h>
#endif

static Refcount thread_counter;

void global_init(pTHX) {
	if (!refcount_inited(&thread_counter)) {
		refcount_init(&thread_counter, 1);

		mark_clonable_pvs("Thread::CSP::Channel");
	}
	if (!PL_perl_destruct_level)
		PL_perl_destruct_level = 1;

	SV* threads = get_sv("threads::threads", GV_ADD);
	if (SvTRUE(threads))
		Perl_warn(aTHX_ "Mixing threads.pm and threads::csp is not advisable");
	else
		sv_setpvs(threads, "threads::csp");

	mark_clonable_pvs("threads::shared::tie");
}

static void thread_count_inc() {
	refcount_inc(&thread_counter);
}

static void thread_count_dec() {
	refcount_dec(&thread_counter);
}

void boot_DynaLoader(pTHX_ CV* cv);

static void xs_init(pTHX) {
	dXSUB_SYS;
	newXS((char*)"DynaLoader::boot_DynaLoader", boot_DynaLoader, (char*)__FILE__);
}

typedef struct mthread {
	struct promise* at_inc;
	struct promise* arguments;
	struct promise* output;
} mthread;


#ifdef _WIN32
static DWORD WINAPI
#else
static void*
#endif
run_thread(void* arg) {
	static const char* argv[] = { "perl", "-e", "0", NULL };
	static const int argc = sizeof argv / sizeof *argv - 1;

	thread_count_inc();

	mthread* thread = (mthread*)arg;
	struct promise* at_inc_promise = thread->at_inc;
	struct promise* arguments = thread->arguments;
	struct promise* output = thread->output;
	free(thread);

	PerlInterpreter* my_perl = perl_alloc();
	perl_construct(my_perl);
	PERL_SET_CONTEXT(my_perl);
	PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
	perl_parse(my_perl, xs_init, argc, (char**)argv, NULL);

	TRY {
		mark_clonable_pvs("Thread::CSP::Channel");

		AV* at_inc = (AV*)sv_2mortal(promise_get(at_inc_promise));
		promise_refcount_dec(at_inc_promise);

		SvREFCNT_dec(GvAV(PL_incgv));
		GvAV(PL_incgv) = at_inc;

		load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Thread::CSP"), NULL);

		AV* to_run = (AV*)sv_2mortal(promise_get(arguments));
		promise_refcount_dec(arguments);
		SV* module = *av_fetch(to_run, 0, FALSE);
		load_module(PERL_LOADMOD_NOIMPORT, SvREFCNT_inc(module), NULL);

		dSP;
		PUSHMARK(SP);
		IV len = av_len(to_run) + 1;
		int i;
		for(i = 2; i < len; i++) {
			SV** entry = av_fetch(to_run, i, FALSE);
			XPUSHs(*entry);
		}
		PUTBACK;

		SV** call_ptr = av_fetch(to_run, 1, FALSE);
		call_sv(*call_ptr, G_SCALAR);
		SPAGAIN;
		promise_set_value(output, POPs);
	}
	CATCH {
		promise_set_exception(output, ERRSV);
	}
	promise_refcount_dec(output);

	perl_destruct(my_perl);
	perl_free(my_perl);

	thread_count_dec();

	return NULL;
}

struct promise* S_thread_spawn(pTHX_ AV* to_run) {
	static const size_t stack_size = 512 * 1024;

	mthread* mthread = calloc(1, sizeof(*mthread));
	struct promise* at_inc = promise_alloc(2);
	mthread->at_inc = at_inc;
	struct promise* arguments = promise_alloc(2);
	mthread->arguments = arguments;
	struct promise* output = promise_alloc(2);
	mthread->output = output;

#ifdef WIN32
	CreateThread(NULL, (DWORD)stack_size, run_thread, (LPVOID)mthread, STACK_SIZE_PARAM_IS_A_RESERVATION, NULL);

#else
	pthread_attr_t attr;
	pthread_attr_init(&attr);

#ifdef PTHREAD_ATTR_SETDETACHSTATE
	PTHREAD_ATTR_SETDETACHSTATE(&attr, PTHREAD_CREATE_DETACHED);
#endif

#ifdef _POSIX_THREAD_ATTR_STACKSIZE
	pthread_attr_setstacksize(&attr, stack_size);
#endif

#if defined(HAS_PTHREAD_ATTR_SETSCOPE) && defined(PTHREAD_SCOPE_SYSTEM)
	pthread_attr_setscope(&attr, PTHREAD_SCOPE_SYSTEM);
#endif

	/* Create the thread */
	pthread_t thr;
#ifdef OLD_PTHREADS_API
	pthread_create(&thr, attr, run_thread, (void *)mthread);
#else
	pthread_create(&thr, &attr, run_thread, (void *)mthread);
#endif

#endif

	/* This blocks on the other thread, so must run last */
	promise_set_value(at_inc, (SV*)GvAVn(PL_incgv));
	promise_refcount_dec(at_inc);
	promise_set_value(arguments, (SV*)to_run);
	promise_refcount_dec(arguments);

	return output;
}
