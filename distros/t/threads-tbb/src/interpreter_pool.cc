
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
void boot_DynaLoader(pTHX_ CV* cv);
}

#include "tbb.h"
#include "interpreter_pool.h"

static void xs_init(pTHX) {
	dXSUB_SYS;
	newXS((char*)"DynaLoader::boot_DynaLoader", boot_DynaLoader, (char*)__FILE__);
}

static const char* argv[] = {"", "-e", "0"};
static int argc = sizeof argv / sizeof *argv;
perl_interpreter_pool tbb_interpreter_pool = perl_interpreter_pool();

// threads::tbb::init
static int perl_tbb_worker = 0;
static mutex_t perl_tbb_worker_mutex;

void perl_interpreter_pool::grab( perl_interpreter_pool::accessor& lock, perl_tbb_init* init ) {
	raw_thread_id thread_id = get_raw_thread_id();
	PerlInterpreter* my_perl;
	bool fresh = false;
	if (!tbb_interpreter_pool.find( lock, thread_id )) {
		tbb_interpreter_pool.insert( lock, thread_id );

		{
			// grab a number!
			mutex_t::scoped_lock x(perl_tbb_worker_mutex);
			lock->second = ++perl_tbb_worker;
		}

		// start an interpreter!  fixme: load some code :)
		my_perl = perl_alloc();
#ifdef DEBUG_PERLCALL
		IF_DEBUG(fprintf(stderr, "# --- thr %x: allocated an interpreter (%x) for worker %d\n", thread_id, my_perl, lock->second));
#endif

		{
			ptr_to_worker::accessor numlock;
			bool found = tbb_interpreter_numbers.find( numlock, my_perl );
			tbb_interpreter_numbers.insert( numlock, my_perl );
			(*numlock).second = lock->second;
			IF_DEBUG(fprintf(stderr, "thr %x: inserted %x => %d (worker) to tbb_interpreter_numbers\n", thread_id, my_perl, lock->second));
			numlock.release();
		}

		// probably unnecessary
		PERL_SET_CONTEXT(my_perl);
		perl_construct(my_perl);

		// execute END blocks in perl_destruct
		PL_exit_flags |= PERL_EXIT_DESTRUCT_END;
		perl_parse(my_perl, xs_init, argc, (char**)argv, NULL);

		// signal to the threads::tbb module that it's a child
		SV* worker_sv = get_sv("threads::tbb::worker", GV_ADD|GV_ADDMULTI);
		//SvUPGRADE(worker_sv, SVt_IV);
		sv_setiv(worker_sv, lock->second);

		// setup the @INC
		init->setup_worker_inc(aTHX);

		ENTER;
		load_module(PERL_LOADMOD_NOIMPORT, newSVpv("threads::tbb", 0), NULL, NULL);
		LEAVE;
		IF_DEBUG_INIT("loaded threads::tbb");
#if IF_DEBUG(1)+0
		ENTER;
		load_module(PERL_LOADMOD_NOIMPORT, newSVpv("Devel::Peek", 0), NULL, NULL);
		IF_DEBUG_INIT("loaded Devel::Peek");
		LEAVE;
#endif
		fresh = true;
	}
	else {
		my_perl = PERL_GET_THX;
		// anything to free?  If we're using a scalable
		// allocator, this should also help to re-use memory
		// we already had allocated.
		perl_concurrent_slot* gonner;
		while (gonner = tbb_interpreter_freelist.next(my_perl)) {
			IF_DEBUG_FREE("got a gonner: %x; thingy = %x, REFCNT=%d", gonner, gonner->thingy, (gonner->thingy?SvREFCNT(gonner->thingy):-1));
			SvREFCNT_dec(gonner->thingy);
			delete gonner;
		}
	}
	
	AV* worker_av = get_av("threads::tbb::worker", GV_ADD|GV_ADDMULTI);
	// maybe required...
	//av_extend(worker_av, init->seq);
	SV* flag = *av_fetch( worker_av, init->seq, 1 );
	if (!SvOK(flag)) {
		if ( lock->second != 0 ) {
			IF_DEBUG_INIT("setting up worker %d for work", lock->second);
			if (!fresh) {
				init->setup_worker_inc(aTHX);
			}
			init->load_modules(my_perl);
		}
		else {
			IF_DEBUG_INIT("not setting up worker %d for work, master thread", lock->second);
		}
		sv_setiv(flag, 1);
	}
}
