#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "proto.h"
#include "XSUB.h"
#include "ppport.h"
}
#endif

/* include your class headers here */
#include "tbb.h"
#include "interpreter_pool.h"

#define NEW_CPP_HEK_sv(sv)  ({					\
		STRLEN len;					\
		const char* sv_pv = SvPVutf8( key, len );	\
		U32 hash;					\
		PERL_HASH(hash, sv_pv, len);			\
		new cpp_hek( sv_pv, len, hash );		\
		})

MODULE = threads::tbb::concurrent::hash::writer    PACKAGE = threads::tbb::concurrent::hash::writer

SV*
perl_concurrent_hash_writer::get()
  CODE:
	IF_DEBUG_VECTOR("got here, thingy = %x", (*THIS)->second.thingy);
	if ((*THIS)->second.thingy)
		RETVAL = (*THIS)->second.dup( my_perl );
	else
		XSRETURN_UNDEF;
  OUTPUT: RETVAL

SV*
perl_concurrent_hash_writer::clone()
  CODE:
	IF_DEBUG_VECTOR("got here, thingy = %x", (*THIS)->second.thingy);
	if ((*THIS)->second.thingy)
		RETVAL = (*THIS)->second.clone( my_perl );
	else
		XSRETURN_UNDEF;
  OUTPUT: RETVAL

void
perl_concurrent_hash_writer::set( SV* val )
  PREINIT:
	SV* nsv;
	perl_concurrent_slot* slot;
  CODE:
	slot = &(*THIS)->second;
	if (slot->thingy) {
		if (slot->owner == my_perl) {
			if (slot->thingy && slot->thingy != &PL_sv_undef) {
				// just go ahead and REFCNT_dec it!
				IF_DEBUG_FREE("SV %x belongs to me, refcnt => %d", slot->thingy, SvREFCNT(slot->thingy)-1);
				SvREFCNT_dec(slot->thingy);
			}
		}
		else {
			// queue a message to release it on next grab()
			IF_DEBUG_FREE("SV %x belongs to interpreter %x, queueing", slot->thingy, slot->owner);
			tbb_interpreter_freelist.free( *slot );
		}
	}
        nsv = newSV(0);
	SvSetSV_nosteal(nsv, val);
	slot->thingy = nsv;
	slot->owner = my_perl;
	IF_DEBUG_FREE("SV %x now in item, refcnt => %d", slot->thingy, SvREFCNT(slot->thingy));

void
perl_concurrent_hash_writer::DESTROY()
CODE:
	if (THIS != NULL) {
		IF_DEBUG_VECTOR("freeing hash writer %x", THIS);
		delete THIS;
		sv_setiv(SvRV(ST(0)), 0);
	}
	else {
		IF_DEBUG_VECTOR("double free hash writer?");
	}

int
perl_concurrent_hash_writer::CLONE_SKIP()
  CODE:
	RETVAL = 1;
  OUTPUT:
	RETVAL

MODULE = threads::tbb::concurrent::hash::reader    PACKAGE = threads::tbb::concurrent::hash::reader

SV*
perl_concurrent_hash_reader::get()
  CODE:
	RETVAL = (*THIS)->second.dup( my_perl );
  OUTPUT: RETVAL

SV*
perl_concurrent_hash_reader::clone()
  CODE:
	IF_DEBUG_VECTOR("got here, thingy = %x", (*THIS)->second.thingy);
	if ((*THIS)->second.thingy)
		RETVAL = (*THIS)->second.clone( my_perl );
	else
		XSRETURN_UNDEF;
  OUTPUT: RETVAL

void
perl_concurrent_hash_reader::DESTROY()
CODE:
	if (THIS != NULL) {
		IF_DEBUG_VECTOR("freeing hash reader %x", THIS);
		delete THIS;
		sv_setiv(SvRV(ST(0)), 0);
	}
	else {
		IF_DEBUG_VECTOR("double free hash reader?");
	}

int
perl_concurrent_hash_reader::CLONE_SKIP()
  CODE:
	RETVAL = 1;
  OUTPUT:
	RETVAL

MODULE = threads::tbb::concurrent::hash    PACKAGE = threads::tbb::concurrent::hash

PROTOTYPES: DISABLE

perl_concurrent_hash *
perl_concurrent_hash::new()
  CODE:
	RETVAL = new perl_concurrent_hash();
  	RETVAL->refcnt++;
OUTPUT:
  	RETVAL

SV *
perl_concurrent_hash::FETCH(key)
	SV* key;
  PREINIT:
	SV* mysv;
	cpp_hek* hek;
	perl_concurrent_hash_reader lock;

  CODE:
	hek = NEW_CPP_HEK_sv(key);

	IF_DEBUG_VECTOR("%x:looking for %x:%d:%s", THIS, hek->hash, hek->len, hek->key_utf8.c_str());
	if ( THIS->find( lock, *hek ) ) {
		IF_DEBUG_VECTOR("%x:found : %x:%d:%s", THIS, hek->hash, hek->len, hek->key_utf8.c_str());
		IF_DEBUG_VECTOR("%x:&slot = %x", THIS, &(*lock).second);
		RETVAL = (*lock).second.clone( my_perl );
		IF_DEBUG_VECTOR("%x:FETCH{%s}: returning %x: copied to %x (refcnt = %d)", THIS, SvPV_nolen(key), (*lock).second.thingy, RETVAL, SvREFCNT(RETVAL));
		delete hek;
	}
	else {
		IF_DEBUG_VECTOR("%x:not found : %x:%d:%s", THIS, hek->hash, hek->len, hek->key_utf8.c_str());
		delete hek;
		IF_DEBUG_VECTOR("%x:FETCH{%s}: returning undef", THIS, SvPV_nolen(key));
		XSRETURN_UNDEF;
	}

  OUTPUT:
	RETVAL

void
perl_concurrent_hash::STORE(key, v)
	SV* key;
	SV* v;
  PREINIT:
	cpp_hek* hek;
	perl_concurrent_hash_writer lock;
	perl_concurrent_slot* slot;
	SV* nsv;
	
  PPCODE:
	hek = NEW_CPP_HEK_sv(key);

	IF_DEBUG_VECTOR("%x:STORE storing key %x:%d:%s", THIS, hek->hash, hek->len, hek->key_utf8.c_str());
	
	if (THIS->find( lock, *hek )) {
		IF_DEBUG_VECTOR("%x:update %s", THIS, hek->key_utf8.c_str());
		delete hek;
		slot = &(*lock).second;
	 IF_DEBUG_VECTOR("%x:&slot = %x", THIS, slot);
		SV* o = slot->thingy;
		if (o) {
			IF_DEBUG_VECTOR("old = %x", o);
			if (my_perl == slot->owner && slot->thingy != &PL_sv_undef) {
				IF_DEBUG_VECTOR("SvREFCNT_dec(%x) (refcnt = %d)", o, SvREFCNT(o));
				SvREFCNT_dec(o);
			}
			else {
				IF_DEBUG_FREE("SV %x belongs to interpreter %x, queueing", slot->thingy, slot->owner);
				tbb_interpreter_freelist.free( *slot );
			}
		}
	}
	else {
		IF_DEBUG_VECTOR("%x:insert %s", THIS, hek->key_utf8.c_str());
		THIS->insert( lock, *hek );
		
		slot = &(*lock).second;
	 IF_DEBUG_VECTOR("%x:&slot = %x", THIS, slot);
	}

	nsv = newSV(0);
	SvSetSV_nosteal(nsv, v);
IF_DEBUG_VECTOR("%x:new = %x (refcnt = %d)", THIS, nsv, SvREFCNT(nsv));
IF_DEBUG_VECTOR("%x:&slot = %x", THIS, slot);
	slot->owner = my_perl;
	slot->thingy = nsv;
	

perl_concurrent_hash *
TIEHASH(classname)
	char* classname;
  CODE:
	RETVAL = new perl_concurrent_hash();
	RETVAL->refcnt++;
        ST(0) = sv_newmortal();
        sv_setref_pv( ST(0), classname, (void*)RETVAL );
	
void
perl_concurrent_hash::DESTROY()
CODE:
	if (THIS != NULL) {
		if (--THIS->refcnt > 0) {
			IF_DEBUG_LEAK("perl_concurrent_hash::DESTROY; %x => refcnt=%d", THIS, THIS->refcnt);
		}
		else {
			IF_DEBUG_LEAK("perl_concurrent_hash::DESTROY; delete %x", THIS);
			delete THIS;
			// XXX - temporary workaround
			sv_setiv(SvRV(ST(0)), 0);
		}
	}

int
perl_concurrent_hash::CLONE_REFCNT_inc()
  CODE:
	THIS->refcnt++;
	IF_DEBUG_LEAK("perl_concurrent_hash::CLONE_REFCNT_inc; %x => %d", THIS, THIS->refcnt);
	RETVAL = 42;
  OUTPUT:
	RETVAL

SV*
perl_concurrent_hash::reader(key)
	SV* key;
  PREINIT:
	cpp_hek* hek;
	perl_concurrent_hash_reader* lock;
	perl_concurrent_slot* slot;
	SV* nsv;
  CODE:
	hek = NEW_CPP_HEK_sv( key );

	IF_DEBUG_VECTOR("new reader for {%s} (HASH=%x)", SvPV_nolen(key), hek->hash);
	lock = new perl_concurrent_hash_reader();
	IF_DEBUG_VECTOR("find");
	if (THIS->find( *lock, *hek )) {
		IF_DEBUG_VECTOR("found");
		RETVAL = newSV(0);
		sv_setref_pv( RETVAL, "threads::tbb::concurrent::hash::reader", (void*) lock);
		delete hek;
	}
	else {
		IF_DEBUG_VECTOR("not found");
		delete lock;
		delete hek;
		XSRETURN_UNDEF;
	}
  OUTPUT:
	RETVAL

perl_concurrent_hash_writer*
perl_concurrent_hash::writer(key)
	SV* key;
  PREINIT:
	cpp_hek* hek;
	perl_concurrent_hash_writer* lock;
	perl_concurrent_slot* slot;
	SV* nsv;
  CODE:
	hek = NEW_CPP_HEK_sv( key );

	IF_DEBUG_VECTOR("new writer for {%s} (HASH=%x)", SvPV_nolen(key), hek->hash);
	lock = new perl_concurrent_hash_writer();
	THIS->insert( *lock, *hek );
	delete hek;
	RETVAL = lock;
  OUTPUT:
	RETVAL


