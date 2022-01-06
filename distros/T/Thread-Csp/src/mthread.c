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

static int (*old_hook)(pTHX);

static int S_threadhook(pTHX) {
	int result = thread_counter > 1 ? 1 : old_hook(aTHX);
	refcount_destroy(&result);
	return result;
}

void global_init(pTHX) {
	if (!refcount_inited(&thread_counter)) {
		refcount_init(&thread_counter, 1);

		old_hook = PL_threadhook;
		PL_threadhook = S_threadhook;

		mark_clonable_pvs("Thread::Csp::Channel");
	}
	if (!PL_perl_destruct_level)
		PL_perl_destruct_level = 1;
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
	Promise* input;
	Promise* output;
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
	Promise* input = thread->input;
	Promise* output = thread->output;
	free(thread);

	PerlInterpreter* my_perl = perl_alloc();
	perl_construct(my_perl);
	PERL_SET_CONTEXT(my_perl);
	PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
	perl_parse(my_perl, xs_init, argc, (char**)argv, NULL);

	TRY {
		mark_clonable_pvs("Thread::Csp::Channel");

		AV* to_run = (AV*)sv_2mortal(promise_get(input));
		promise_refcount_dec(input);

		SvREFCNT_dec(GvAV(PL_incgv));
		GvAV(PL_incgv) = (AV*)*av_fetch(to_run, 0, FALSE);

		load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("Thread::Csp"), NULL);

		SV* module = *av_fetch(to_run, 1, FALSE);
		load_module(PERL_LOADMOD_NOIMPORT, SvREFCNT_inc(module), NULL);

		dSP;
		PUSHMARK(SP);
		IV len = av_len(to_run) + 1;
		int i;
		for(i = 3; i < len; i++) {
			SV** entry = av_fetch(to_run, i, FALSE);
			XPUSHs(*entry);
		}
		PUTBACK;

		SV** call_ptr = av_fetch(to_run, 2, FALSE);
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

AV* S_clone_INC(pTHX) {
	AV* inc = GvAVn(PL_incgv);
	IV len = av_len(inc) + 1;
	AV* copy = newAV();
	int i;
	for (i = 0; i < len; ++i) {
		SV** entry = av_fetch(inc, i, FALSE);
		if (entry && *entry && !SvROK(*entry))
			av_push(copy, SvREFCNT_inc(*entry));
	}
	return copy;
}
#define clone_INC() S_clone_INC(aTHX)

Promise* S_thread_spawn(pTHX_ AV* to_run) {
	static const size_t stack_size = 512 * 1024;

	av_unshift(to_run, 1);
	av_store(to_run, 0, (SV*)clone_INC());

	mthread* mthread = calloc(1, sizeof(*mthread));
	Promise* input = promise_alloc(2);
	mthread->input = input;
	Promise* output = promise_alloc(2);
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
	promise_set_value(input, (SV*)to_run);
	promise_refcount_dec(input);

	return output;
}
