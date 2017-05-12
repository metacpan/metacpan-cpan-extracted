
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}

#include "tbb.h"
#include "interpreter_pool.h"

perl_interpreter_freelist tbb_interpreter_freelist = perl_interpreter_freelist();
ptr_to_worker tbb_interpreter_numbers = ptr_to_worker();

// freeing old (values of) slots.
void perl_interpreter_freelist::free( const perl_concurrent_slot item ) {
	IF_DEBUG_FREE("free, free as can be!  %x / %x", item.owner, item.thingy);
	dTHX;
	if (item.owner == my_perl) {
		IF_DEBUG_FREE("freeing immediately: %x", item.thingy);
		SvREFCNT_dec(item.thingy);
	}
	else {
		ptr_to_worker::const_accessor lock;
		bool found = tbb_interpreter_numbers.find( lock, item.owner );
		IF_DEBUG_FREE("found = %s  lock = %x", (found?"true":"false"), &lock );
		if (!found) {
			IF_DEBUG_FREE("What?  No entry in tbb_interpreter_numbers for %x?", item.owner);
			return;
		}
		int worker = (*lock).second;
		lock.release();
		this->grow_to_at_least(worker+1);

		IF_DEBUG_FREE("queueing to worker %d: %x", worker, item.thingy);
		(*this)[worker].push(item);
	}
}

void perl_interpreter_freelist::free( PerlInterpreter* owner, SV* item ) {
	this->free( perl_concurrent_slot( owner, item ) );
}

perl_concurrent_slot* perl_interpreter_freelist::next( pTHX ) {
	ptr_to_worker::const_accessor lock;
	bool found = tbb_interpreter_numbers.find( lock, my_perl );
	int worker = 0;
	if (!found) {
		IF_DEBUG_FREE("What?  No entry in tbb_interpreter_numbers for %x during next?", my_perl);
		SV* tbb_worker = get_sv("threads::tbb::worker", 0);
		if (tbb_worker)
			worker = SvIV(tbb_worker);
		IF_DEBUG_FREE("Fetched worker num = %d from Perl", worker);
	}
	else {
		worker = (*lock).second;
	}
	lock.release();
	this->grow_to_at_least(worker+1);

	perl_concurrent_slot x;
	if ((*this)[worker].try_pop(x)) {
		IF_DEBUG_FREE("next to free: %x", x.thingy);
		return new perl_concurrent_slot(x);
	}
	else {
		IF_DEBUG_FREE("returning 0");
		return 0;
	}
}

void perl_concurrent_slot::free() const {
	IF_DEBUG_FREE("freeing a slot: %x, %x", owner, thingy);
	tbb_interpreter_freelist.free( *this );
}
