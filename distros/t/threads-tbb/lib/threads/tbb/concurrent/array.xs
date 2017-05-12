#ifdef __cplusplus
extern "C" {
#define PERL_NO_GET_CONTEXT /* we want efficiency! */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
}
#endif

/* include your class headers here */
#include "tbb.h"
#include "interpreter_pool.h"

MODULE = threads::tbb::concurrent::array    PACKAGE = threads::tbb::concurrent::array

PROTOTYPES: DISABLE

perl_concurrent_vector *
perl_concurrent_vector::new()
  CODE:
	RETVAL = new perl_concurrent_vector();
  	RETVAL->refcnt++;
OUTPUT:
  	RETVAL

SV *
perl_concurrent_vector::FETCH(i)
	int i;
  PREINIT:
	SV* mysv;
	perl_concurrent_slot* slot;
  CODE:
	if (THIS->size() < i+1) {
		IF_DEBUG_VECTOR("FETCH(%d): not extended to [%d]", i, i+1);
		XSRETURN_EMPTY;
	}
	slot = &(*THIS)[i];
	mysv = slot->thingy;
	if (mysv) {
		RETVAL = slot->dup( my_perl );
		IF_DEBUG_VECTOR("FETCH(%d): returning %x: copied to %x (refcnt = %d)", i, mysv, RETVAL, SvREFCNT(RETVAL));
	}
	else {
		IF_DEBUG_VECTOR("FETCH(%d): returning undef", i);
		XSRETURN_UNDEF;
	}
  OUTPUT:
	RETVAL
    

void
perl_concurrent_vector::STORE(i, v)
	int i;
	SV* v;
  PREINIT:
       SV* nsv;
  PPCODE:
	IF_DEBUG_VECTOR("STORE (%d, %x) (refcnt = %d)", i, v, SvREFCNT(v));
	IF_DEBUG_VECTOR("%x->grow_to_at_least(%d)", THIS, i+1);
	THIS->grow_to_at_least( i+1 );
	perl_concurrent_slot* slot = &((*THIS)[i]);
	SV* o = slot->thingy;
	if (o != 0) {
		IF_DEBUG_VECTOR("old = %x", o);
		if (my_perl == slot->owner) {
			IF_DEBUG_VECTOR("SvREFCNT_dec(%x) (refcnt = %d)", o, SvREFCNT(o));
			SvREFCNT_dec(o);
		}
		else {
			IF_DEBUG_FREE("SV %x belongs to interpreter %x, queueing", slot->thingy, slot->owner);
			tbb_interpreter_freelist.free( *slot );
		}
	}
	if (v == &PL_sv_undef) {
		slot->thingy = 0;
	}
	else {
		nsv = newSV(0);
		SvSetSV_nosteal(nsv, v);
		//SvREFCNT_inc(nsv);
		IF_DEBUG_VECTOR("new = %x (refcnt = %d)", nsv, SvREFCNT(nsv));
		slot->owner = my_perl;
		slot->thingy = nsv;
	}

void
perl_concurrent_vector::STORESIZE( i )
	int i;
  PPCODE:
	IF_DEBUG_VECTOR("grow_to_at_least(%d)", i);
	THIS->grow_to_at_least( i );

int
perl_concurrent_vector::size()

int
perl_concurrent_vector::FETCHSIZE()
  CODE:
	int size = THIS->size();
	IF_DEBUG_VECTOR("returning size = %d", size);
        RETVAL = size;
  OUTPUT:
        RETVAL

void
perl_concurrent_vector::PUSH(...)
  PREINIT:
	int i;
	perl_concurrent_vector::iterator idx;
        SV* x;
  PPCODE:
	if (items == 2) {
		x = newSV(0);
		SvSetSV_nosteal(x, ST(1));
		THIS->push_back( perl_concurrent_slot(my_perl, x) );
		IF_DEBUG_VECTOR("PUSH (%x)", x);
	}
        else {
		idx = (THIS->grow_by( items-1 ));
		for (i = 1; i < items; i++) {
			x = newSV(0);
			SvSetSV_nosteal(x, ST(i));
			IF_DEBUG_VECTOR("PUSH/%d (%x)", i, x);
			idx->thingy = x;
			idx->owner = my_perl;
			idx++;
		}
	}

perl_concurrent_vector *
TIEARRAY(classname)
	char* classname;
  CODE:
	RETVAL = new perl_concurrent_vector();
	RETVAL->refcnt++;
        ST(0) = sv_newmortal();
        sv_setref_pv( ST(0), classname, (void*)RETVAL );
	
void
perl_concurrent_vector::DESTROY()
CODE:
	if (THIS != NULL) {
		if (--THIS->refcnt > 0) {
			IF_DEBUG_LEAK("perl_concurrent_vector::DESTROY; %x => refcnt=%d", THIS, THIS->refcnt);
		}
		else {
			IF_DEBUG_LEAK("perl_concurrent_vector::DESTROY; delete %x", THIS);
			delete THIS;
			// XXX - temporary workaround
			sv_setiv(SvRV(ST(0)), 0);
		}
	}

int
perl_concurrent_vector::CLONE_REFCNT_inc()
  CODE:
	THIS->refcnt++;
	IF_DEBUG_LEAK("perl_concurrent_item::CLONE_REFCNT_inc; %x => %d", THIS, THIS->refcnt);
	RETVAL = 42;
  OUTPUT:
	RETVAL

