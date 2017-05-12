/*
 * the following defines concern themselves with managing Perl
 * interpreters:
 *    * getting an interpreter at the beginning of a task body.
 *    * passing variables between interpreters
 *    * freeing other interpreters' variables
 */

// for the concurrent_hash_map: necessary transformation and
// comparison functions.
struct raw_thread_hash_compare {
	static size_t hash( const raw_thread_id& x ) {
		size_t h = 0;
		if (sizeof(raw_thread_id) != sizeof(size_t) ) {
			int i = 0;
			for (const char* s = (char*)x; i<sizeof(raw_thread_id); ++s) {
				h = (h*17) ^ *s;
				i++;
			}
		}
		else {
			h = *( (size_t*)x );
		}
		return h;
	}
	static bool equal( const raw_thread_id& a, const raw_thread_id& b) {
		return (a == b);
	}
};

/*
 * getting an interpreter usage:
 *  perl_interpreter_pool::accessor interp;
 *  tbb_interpreter_pool->grab( interp, init );
 *
 * it has to:
 *    1. check that this real thread has an interpreter or not
 *       already, and
 *    2. start it, if it does.
 *    3. lock it, for the duration of the thread.
 *
 * A single tbb::concurrent_hash_map (tbb_interpreter_pool) is used
 * for all this.  It is a hash map from the thread ID (a pthread_t on
 * Unix, DWORD on Windows as in tbb itself) to a bool which indicates
 * whether or not the thread has been started.
 *
 * As the accessor 'class' represents an exclusive lock on the item,
 * we use it for an interpreter mutex as well.  The first time it is
 * read, if its value is false then a PerlInterpreter is created.
 *
 */
class perl_interpreter_pool : public tbb::concurrent_hash_map<raw_thread_id, int, raw_thread_hash_compare> {
public:
	void grab( perl_interpreter_pool::accessor& result, perl_tbb_init*init);
};

// the global pointer to the interpreter locks
extern perl_interpreter_pool tbb_interpreter_pool;

struct ptr_compare {
	static size_t hash( void* const& x ) {
		size_t h = 0;
		if (sizeof(void*) != sizeof(size_t) ) {
			int i = 0;
			for (const char* s = (char*)x; i<sizeof(void*); ++s) {
				h = (h*17) ^ *s;
				i++;
			}
		}
		else {
			h = 0+(size_t)x;
		}
		return h;
	}
	
	static bool equal( void* const& a, void* const& b) {
		return (a == b);
	}
};

typedef tbb::concurrent_hash_map<void*, int, ptr_compare> ptr_to_int;
typedef ptr_to_int ptr_to_worker;
extern ptr_to_worker tbb_interpreter_numbers;

// freelist; next time interpreter wakes, it will free the items in this
// list.
class perl_interpreter_freelist : public tbb::concurrent_vector<tbb::strict_ppl::concurrent_queue<perl_concurrent_slot> > {
public:
	void free( PerlInterpreter* owner, SV *sv );
	void free( const perl_concurrent_slot item );
	perl_concurrent_slot* next( pTHX );
};

// the global pointer to the interpreter locks
extern perl_interpreter_freelist tbb_interpreter_freelist;

//typedef perl_interpreter_pool::accessor tbb_interpreter_lock;


