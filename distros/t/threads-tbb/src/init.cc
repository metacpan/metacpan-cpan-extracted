extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include "tbb.h"
#include "interpreter_pool.h"

using namespace std;
using namespace tbb;

void perl_tbb_init::mark_master_thread_ok() {
	if (tbb_interpreter_pool.size() == 0) {
		perl_interpreter_pool::accessor lock;
		raw_thread_id thread_id = get_raw_thread_id();
		IF_DEBUG_INIT( "I am the master thread");
		tbb_interpreter_pool.insert( lock, thread_id );
		lock->second = 0;

		PerlInterpreter* my_perl = PERL_GET_THX;
		SV* worker_sv = get_sv("threads::tbb::worker", GV_ADD|GV_ADDMULTI);
		sv_setiv(worker_sv, 0);
		ptr_to_worker::accessor numlock;
		tbb_interpreter_numbers.insert( numlock, my_perl );
		(*numlock).second = 0;
		IF_DEBUG_FREE("inserted %x => 0 (master) to tbb_interpreter_numbers", my_perl);
	}
}

void perl_tbb_init::setup_worker_inc( pTHX ) {
	// first, set up the boot_lib
	list<string>::const_reverse_iterator lrit;
	
	// grab @INC
	AV* INC_a = get_av("INC", GV_ADD|GV_ADDWARN);

	// add all the lib paths to our INC
	for ( lrit = boot_lib.rbegin(); lrit != boot_lib.rend(); lrit++ ) {
		bool found = false;
		//IF_DEBUG(fprintf(stderr, "thr %x: checking @INC for %s\n", get_raw_thread_id(),lrit->c_str() ));
		for ( int i = 0; i <= av_len(INC_a); i++ ) {
			SV** slot = av_fetch(INC_a, i, 0);
			if (!slot || !SvPOK(*slot))
				continue;
			if ( lrit->compare( SvPV_nolen(*slot) ) )
				continue;

			found = true;
			break;
		}
		if (found) {
			//IF_DEBUG(fprintf(stderr, "thr %x: %s in @INC already\n", get_raw_thread_id(),lrit->c_str() ));
		}
		else {
			av_unshift( INC_a, 1 );
			SV* new_path = newSVpv(lrit->c_str(), 0);
#ifdef DEBUG_INIT
			IF_DEBUG(fprintf(stderr, "thr %x: added %s to @INC\n", get_raw_thread_id(),lrit->c_str() ));
#endif
			SvREFCNT_inc(new_path);
			av_store( INC_a, 0, new_path );
		}
	}
}

void perl_tbb_init::load_modules( pTHX ) {
	// get %INC
	HV* INC_h = get_hv("INC", GV_ADD|GV_ADDWARN);

	std::list<std::string>::const_iterator mod;

	for ( mod = boot_use.begin(); mod != boot_use.end(); mod++ ) {
		// skip if already in INC
		const char* modfilename = (*mod).c_str();
		size_t modfilename_len = strlen(modfilename);
		SV** slot = hv_fetch( INC_h, modfilename, modfilename_len, 0 );
		if (slot) {
			IF_DEBUG_INIT("skipping %s; already loaded", modfilename);
		}
		else {
			IF_DEBUG_INIT("require '%s'", modfilename);
			ENTER;
			require_pv(modfilename);
			LEAVE;
			IF_DEBUG_INIT("require '%s' done", modfilename);
		}
	}
}

#ifdef PERL_IMPLICIT_CONTEXT
static int yar_implicit_context;
#else
static int no_implicit_context;
#endif


