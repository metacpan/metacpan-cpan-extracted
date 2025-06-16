#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Lock EvasLock;


MODULE = pEFL::Evas::Lock		PACKAGE = pEFL::Evas::Lock


MODULE = pEFL::Evas::Lock		PACKAGE = EvasLockPtr     PREFIX = evas_

Eina_Bool
evas_key_lock_is_set(m,keyname)
	const EvasLock *m
	const char *keyname
	

# Eina_Bool
# evas_seat_key_lock_is_set(m, keyname, seat)
#	const EvasLock *m
#	const char *keyname
#	const Evas_Device *seat
