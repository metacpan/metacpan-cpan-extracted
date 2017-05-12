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

MODULE = threads::tbb::concurrent::item    PACKAGE = threads::tbb::concurrent::item

PROTOTYPES: DISABLE

SV *
new( classname )
	char* classname;
  PREINIT:
	perl_concurrent_item* self;
  CODE:
	self = new perl_concurrent_item( my_perl, &PL_sv_undef );
	self->refcnt++;
	IF_DEBUG_LEAK("perl_concurrent_item::new; %x", self);
        RETVAL = newSV(0);
        sv_setref_pv( RETVAL, classname, (void*)self );
  OUTPUT:
	RETVAL

SV*
TIESCALAR(classname)
	char* classname;
  PREINIT:
        perl_concurrent_item* rv;
  CODE:
	rv = new perl_concurrent_item( my_perl, &PL_sv_undef );
	rv->refcnt++;
	IF_DEBUG_LEAK("perl_concurrent_item::TIESCALAR; %x", rv);
        ST(0) = sv_newmortal();
        sv_setref_pv( ST(0), classname, (void*)rv );

SV*
FETCH(self)
  perl_concurrent_item* self;
  CODE:
    RETVAL = self->dup(my_perl);
  OUTPUT:
    RETVAL

void
STORE(self, value)
  perl_concurrent_item* self;
  SV* value;
  PREINIT:
	SV* nsv;
  CODE:
	IF_DEBUG_FREE("Updating value to %x (rc=%d)", value, SvREFCNT(value));
	if (self->owner == my_perl) {
		if (self->thingy != &PL_sv_undef) {
			// just go ahead and REFCNT_dec it!
			IF_DEBUG_FREE("SV %x belongs to me, refcnt => %d", self->thingy, SvREFCNT(self->thingy)-1);
			SvREFCNT_dec(self->thingy);
		}
	}
	else {
		// queue a message to release it on next grab()
		IF_DEBUG_FREE("SV %x belongs to interpreter %x, queueing", self->thingy, self->owner);
		tbb_interpreter_freelist.free( *self );
	}
        nsv = newSV(0);
	SvSetSV_nosteal(nsv, value);
	self->thingy = nsv;
	self->owner = my_perl;
	IF_DEBUG_FREE("SV %x now in item, refcnt => %d", self->thingy, SvREFCNT(self->thingy));


int
perl_concurrent_item::CLONE_REFCNT_inc()
CODE:
	THIS->refcnt++;
	IF_DEBUG_LEAK("perl_concurrent_item::CLONE_REFCNT_inc; %x => %d", THIS, THIS->refcnt);
	RETVAL = 42;
OUTPUT:
	RETVAL

void
perl_concurrent_item::DESTROY()
CODE:
	if (THIS != NULL) {
		if (--THIS->refcnt > 0) {
			IF_DEBUG_LEAK("perl_concurrent_item::DESTROY; %x => refcnt=%d", THIS, THIS->refcnt);
		}
		else {
			IF_DEBUG_LEAK("perl_concurrent_item::DESTROY; delete %x", THIS);
			delete THIS;
			// XXX - temporary workaround
			sv_setiv(SvRV(ST(0)), 0);
		}
	}
	else {
		IF_DEBUG_LEAK("perl_concurrent_item::DESTROY; %x ?", THIS);
	}

