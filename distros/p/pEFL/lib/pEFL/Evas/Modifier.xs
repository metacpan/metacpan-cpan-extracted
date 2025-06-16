#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Evas.h>

typedef Evas_Modifier EvasModifier;


MODULE = pEFL::Evas::Modifier		PACKAGE = pEFL::Evas::Modifier


MODULE = pEFL::Evas::Modifier		PACKAGE = EvasModifierPtr     PREFIX = evas_

Eina_Bool
evas_key_modifier_is_set(m,keyname)
	const EvasModifier *m
	const char *keyname
	

# Eina_Bool
# evas_seat_key_modifier_is_set(m, keyname, seat)
#	const EvasModifier *m
#	const char *keyname
#	const Evas_Device *seat
