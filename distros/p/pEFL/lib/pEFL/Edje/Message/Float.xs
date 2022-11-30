#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Edje.h>

typedef Edje_Message_Float EdjeMessageFloat;

MODULE = pEFL::Edje::Message::Float		PACKAGE = pEFL::Edje::Message::Float

EdjeMessageFloat *
new(class,val)
	char *class
	double val
PREINIT:
	EdjeMessageFloat *message;
CODE:
	if (items != 2) {
		Perl_croak(aTHX_ "Usage pEFL::Edje::Message::Float->new($val)\n");
	}
	message->val = val;
	RETVAL = message;
OUTPUT:
	RETVAL

MODULE = pEFL::Edje::Message::Float		PACKAGE = EdjeMessageFloatPtr

double
val(message)
    EdjeMessageFloat *message
CODE:
    RETVAL = message->val;
OUTPUT:
    RETVAL